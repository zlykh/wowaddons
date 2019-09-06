local addon_name = "KillTimer"
local addon_data = {}
local default_text = "last: 0s, avg: 0s, kills: 0"
addon_data.core = {}
addon_data.core.combat_dict = {}
addon_data.core.text = default_text


addon_data.core.core_frame = CreateFrame("Frame", addon_name .. "CoreFrame", UIParent)
addon_data.core.core_frame:RegisterEvent("ADDON_LOADED")

local f = CreateFrame("Frame", addon_name .. "PlayerFrame", UIParent)
f:SetFrameStrata("BACKGROUND")
f:SetWidth(160)
f:SetHeight(50) 
f:SetPoint("CENTER",0,0)
f:SetBackdrop({
	bgFile="Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile="Interface\\ChatFrame\\ChatFrameBackground",
	tile=true,
	tileSize=5,
	edgeSize= 2,
})
f:SetBackdropColor(0,0,0,0.5)
f:SetBackdropBorderColor(0,0,0,1)
--f.texture = f:CreateTexture(nil, "BACKGROUND")
--f.texture:SetAllPoints(true)
--f.texture:SetColorTexture(0.0, 0.0, 0.0, 0.5)

local title = f:CreateFontString(nil,"ARTWORK")
title:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
title:SetPoint("TOP",f)
title:SetText("Kill Timer")

f.text = f:CreateFontString(nil,"ARTWORK")
f.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
f.text:SetPoint("BOTTOM",f)
f.text:SetText(addon_data.core.text)
addon_data.core.text = f.text

f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Show()

local function safeDiv(a, b)
	if a == 0 and b==0 then
		return 0
	end
	
	if b == 0 or b == nil then
		return 0
	else
		return a/b
	end
end

local function initWeapon()
	local slotId = GetInventorySlotInfo("MainHandSlot")
	local weaponId = GetInventoryItemID("player", slotId);
	local name = GetItemInfo(weaponId);
	addon_data.core.curr_weap = weaponId
	addon_data.core.curr_weap_name = name
	
	local slotIdOffhand = GetInventorySlotInfo("SecondaryHandSlot")
	local weaponIdOffhand = GetInventoryItemID("player", slotIdOffhand);

	if weaponIdOffhand ~=nil then
		local nameOffhand = GetItemInfo(weaponIdOffhand);
		addon_data.core.curr_weap_offhand = weaponIdOffhand
		addon_data.core.curr_weap_name_offhand = nameOffhand
	end

	local uid = tostring(weaponId) .. tostring(weaponIdOffhand or "")
	addon_data.core.combat_dict[uid] = {}
	addon_data.core.combat_dict[uid].last = 0
	addon_data.core.combat_dict[uid].counter = 0
	addon_data.core.combat_dict[uid].sum = 0
end


local function changeText(textFrame, default)
	local uidCurr = tostring(addon_data.core.curr_weap) .. tostring(addon_data.core.curr_weap_offhand or "")
	local last = addon_data.core.combat_dict[uidCurr].last
	local sum = addon_data.core.combat_dict[uidCurr].sum
	local cnt = addon_data.core.combat_dict[uidCurr].counter
	local mh_name = addon_data.core.curr_weap_name
	local oh_name = addon_data.core.curr_weap_name_offhand
	if default == 1 then
		textFrame:SetText(mh_name .. "/" .. (oh_name or "empty") .. "\n" .. default_text)
	else
		textFrame:SetText(mh_name .. "/" .. (oh_name or "empty") .. "\n" .. "last: " .. last .. "s, avg: " .. safeDiv(sum, cnt) .. "s, kills: " .. cnt)
	end
end

local function newWeapon(textFrame)
	local slotId = GetInventorySlotInfo("MainHandSlot")
	local weaponId = GetInventoryItemID("player", slotId);
	local name = GetItemInfo(weaponId);

	local slotIdOffhand = GetInventorySlotInfo("SecondaryHandSlot")
	local weaponIdOffhand = GetInventoryItemID("player", slotIdOffhand);
	local nameOffhand = nil
	if weaponIdOffhand ~=nil then
		nameOffhand = GetItemInfo(weaponIdOffhand);
	end

	local uid = tostring(weaponId) .. tostring(weaponIdOffhand or "")
	local uidCurr = tostring(addon_data.core.curr_weap) .. tostring(addon_data.core.curr_weap_offhand or "")
	if uidCurr ~= uid then
		addon_data.core.curr_weap = weaponId
		addon_data.core.curr_weap_name = name
		addon_data.core.curr_weap_offhand = weaponIdOffhand
		addon_data.core.curr_weap_name_offhand = nameOffhand
		if addon_data.core.combat_dict[uid] == nil then
			addon_data.core.combat_dict[uid] = {}
			addon_data.core.combat_dict[uid].last = 0
			addon_data.core.combat_dict[uid].counter = 0
			addon_data.core.combat_dict[uid].sum = 0
			changeText(textFrame, 1)
		end
	end

	changeText(textFrame)
end

local function OnAddonLoaded(self)
    addon_data.core.core_frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    addon_data.core.core_frame:RegisterEvent("PLAYER_REGEN_DISABLED")
	addon_data.core.core_frame:RegisterEvent("PLAYER_TARGET_CHANGED")
	addon_data.core.core_frame:RegisterEvent("UNIT_INVENTORY_CHANGED")

	initWeapon()
	newWeapon(addon_data.core.text)
	
	print('Kill Timer loaded!')
end

local function CoreFrame_OnEvent(self, event, ...)
    local args = {...}
    if event == "ADDON_LOADED" then
        if args[1] == "KillTimer" then
            OnAddonLoaded()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
		addon_data.core.finish = GetServerTime()
		local uidCurr = tostring(addon_data.core.curr_weap) .. tostring(addon_data.core.curr_weap_offhand or "")
		local last = (addon_data.core.finish - addon_data.core.start)
		local sum = addon_data.core.combat_dict[uidCurr].sum
		local cnt = addon_data.core.combat_dict[uidCurr].counter
		sum = sum + last
		cnt = cnt + 1
		addon_data.core.combat_dict[uidCurr].last = last
		addon_data.core.combat_dict[uidCurr].sum = sum
		addon_data.core.combat_dict[uidCurr].counter = cnt
		changeText(textFrame)
    elseif event == "PLAYER_REGEN_DISABLED" then
		addon_data.core.start = GetServerTime()
	 elseif event == "UNIT_INVENTORY_CHANGED" then
		newWeapon(addon_data.core.text)
    end
end

addon_data.core.core_frame:SetScript("OnEvent", CoreFrame_OnEvent)