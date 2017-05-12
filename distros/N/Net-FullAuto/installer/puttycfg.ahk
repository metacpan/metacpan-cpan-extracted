;### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
;#
;#    Net::FullAuto - Powerful Network Process Automation Software
;#    Copyright (C) 2000-2017  Brian M. Kelly
;#
;#    This program is free software: you can redistribute it and/or modify
;#    it under the terms of the GNU Affero General Public License as
;#    published by the Free Software Foundation, either version 3 of the
;#    License, or any later version.
;#
;#    This program is distributed in the hope that it will be useful,
;#    but **WITHOUT ANY WARRANTY**; without even the implied warranty of
;#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;#    GNU Affero General Public License for more details.
;#
;#    You should have received a copy of the GNU Affero General Public
;#    License along with this program.  If not, see:
;#    <http://www.gnu.org/licenses/agpl.html>.
;#
;#######################################################################

#NoTrayIcon
#NoEnv
SetWorkingDir, %A_ScriptDir%
DetectHiddenWindows, On
Run putty.exe
WinWait, PuTTY Configuration
WinActivate, PuTTY Configuration
SendInput !N{Del 15}
SendInput !g{Down}!P!e{Up 2}!d!gc!u{Space}!R0!n255!e64!gH!U{Up}
SendInput !gab{Down}!tFullAuto Build UNDER WAY{!}!gL{Down}!w!gL{Up}
SendInput !N%1%!eFullAuto_%1%!v!C
