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
SetTitleMatchMode, RegEx
Run putty.exe -t -m exit.txt -i `"%1%`" %2%@%3%
WinWait, Alert|Fatal, , 45
IfWinExist, Alert
{
   if ErrorLevel {
   } else {
      WinActivate
      SendInput, !y
      exit 0
   }
}
IfWinExist, Fatal
{
   WinActivate
   SendInput, {ENTER}
   MsgBox,,FullAuto Cannot Connect to %3%, FullAuto cannot connect to %3%. The most likely reason is that this server is still initializing, and is not yet accepting ssh connections. Another reason is perhaps the wrong IP address was typed in or copied. Please allow time for the Amazon instance to fully initialize, and double check that the IP address entered is accurate before trying again.`n`nThe FullAuto AWS Installer Dashboard will now EXIT.
}
IfWinExist, inactive
{
   WinActivate
   SendInput !{f4}
   exit 2
}
;MsgBox,,FullAuto Cannot Connect to %3%, REALLY 
