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
var0=%3%
Run puttygen.exe "%1%.pem"
WinWait, PuTTYgen Notice, , 3
if ErrorLevel {
   return
} else {
   SendInput, {ENTER}
}
WinWait, PuTTY Key Generator, , 3
if ErrorLevel {
   return
} else {
   SendInput, !s
}
WinWait, PuTTYgen Warning, , 3
if ErrorLevel {
   return
} else {
   SendInput, {ENTER}
}
WinWait, Save private key as:, , 3
if ErrorLevel {
   return
} else {
   sleep 1000
   SendInput, {Del 20}%2%\%1%!S
}
WinWait, PuTTYgen Warning, , 1
if ErrorLevel {
} else {
   SendInput, {ENTER}
}
WinActivate, PuTTY Key Generator
SendInput, !fx
