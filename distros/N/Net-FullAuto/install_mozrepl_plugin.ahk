;### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
;#
;#    Net::FullAuto - Distributed Workload Automation Software
;#    Copyright © 2000-2017  Brian M. Kelly
;#
;#    This program is free software: you can redistribute it and/or
;#    modify it under the terms of the GNU Affero General Public License
;#    as published by the Free Software Foundation, either version 3 of
;#    the License, or any later version.
;#
;#    This program is distributed in the hope that it will be useful,
;#    but **WITHOUT ANY WARRANTY**; without even the implied warranty
;#    of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
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
Run %1% %2%
WinWaitActive, Import Wizard,,2
Loop, 20 {
   Sleep, 3000
   IfWinExist, Default Browser
   {
      Winactivate
      Send, !n
   }
   IfWinExist, Software Installation
   {
      MsgBox,4,FullAuto Installer Message,Wait for FireFox to ReStart,2
      Winactivate
      Sleep, 4000
      Send, {Enter}
   } else IfWinActive, Mozilla Firefox
   {
      Break
   } else IfWinActive, Import Wizard
   {
      Send !d
      Sleep,10
      Send !n
   } else IfWinActive, Add-ons
   {
      ControlSend, MozillaWindowClass2, {Tab}!R, Add-ons
      Break
   }

}
WinWaitActive, Add-ons,,2
Loop, 3
{
   ifWinExist, Add-ons
   {
       WinClose, Add-ons
       Break
   }
   Sleep, 1000
}
WinWaitActive, Mozilla Firefox,,10
WinClose, Mozilla Firefox
Sleep, 1000
IfWinExist, Mozilla Firefox and IfWinNotActive, Mozilla Firefox
{
   Send, {Enter}
}
ExitApp
