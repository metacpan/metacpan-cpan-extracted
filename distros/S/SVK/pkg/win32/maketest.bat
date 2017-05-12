@echo off
if "%OS%" == "Windows_NT" goto WinNT
cd "C:\Program Files\svk\bin"
goto endofperl
:WinNT
cd "%~d0%~p0..\bin"
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
:endofperl
.\perl.exe -I..\site prove.bat ..\site\t
