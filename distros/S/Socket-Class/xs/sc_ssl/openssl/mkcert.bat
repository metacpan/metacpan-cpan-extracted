@echo off

rem # Generates self-signed certificate
rem # Edit openssl.conf before running this

set KEYFILE=server.key
set CERTFILE=server.crt

openssl.exe req -new -x509 -nodes -config openssl.conf -out %CERTFILE% -keyout %KEYFILE% -days 36500
if errorlevel 1 goto error
echo 

openssl.exe x509 -subject -fingerprint -noout -in %CERTFILE%
if errorlevel 1 goto error

goto exit;

:error
echo !!! something went wrong !!!

:exit
pause
