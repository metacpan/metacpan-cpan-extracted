@echo off
rem do not put this file in manifest.txt

if "%1"=="send" goto send
if "%1"=="receive" goto receive
goto help

:send
set _ret=send1
goto setup

:send1
set _ret=
zipdiff -m manifest.txt repository\%proj%%cv%.zip . > %proj%%cv%_%uid%.patch
goto end

:receive
set _ret=rx1
goto setup

:rx1
set _ret=
if not exist %proj%%cv%_%nv%.patch goto patches
zippatch -o repository\%proj%%nv%.zip repository\%proj%%cv%.zip %proj%%cv%_%nv%.patch
goto zip

:patches
if not exist patches\%proj%%cv%_%nv%.patch goto zip
zippatch -o repository\%proj%%nv%.zip repository\%proj%%cv%.zip patches\%proj%%cv%_%nv%.patch

:zip
if not exist repository\%proj%%nv%.zip goto nopatch
zipmerge -m manifest repository\%proj%%cv%.zip repository\%proj%%nv%.zip . .
goto end

:nopatch
echo"No patch %proj%%cv%_%nv%.patch or zip repository\%proj%%nv%.zip exists"
goto end

:setup
call user.bat
call version.bat
goto %_ret%

:help
echo"zvs send or zvs receive"

:end
set cv=
set nv=
set proj=