@echo off
if not "%1"=="clean" goto BUILD
if exist glversion.txt del glversion.txt&echo deleted glversion.txt
if exist glversion.exe del glversion.exe&echo deleted glversion.exe
if exist glversion.o del glversion.o&echo deleted glversion.o
goto END


:BUILD
echo.
echo compiling glversion.c
gcc -DHAVE_FREEGLUT -c glversion.c
if errorlevel 1 goto ERROR

echo linking glversion.o
gcc -o glversion.exe glversion.o -lopengl32 -L../FreeGLUT -lfreeglut 
if errorlevel 1 goto ERROR

echo generating glversion.txt
glversion > glversion.txt
if errorlevel 1 goto ERROR
goto END


:ERROR
echo build error!
echo.


:END
