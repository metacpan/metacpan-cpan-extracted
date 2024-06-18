@echo off
REM PODNAME: balabolkamp3.bat
REM ABSTRACT: script converting textfile named $1
REM                               into mp3file $2
REM                          with engine:voice $3
REM                  using balabolka

REM Check if the correct number of arguments are provided
if "%~3"=="" (
    echo Usage: %0 ^<input_text_file^> ^<output_ogg_file^> ^<voice^>
    exit /b 1
)

REM Set variables from the arguments
set "TEXT_FILE=%~1"
set "OUTPUT_FILE=%~2"
set "VOICE=%~3"

REM Call Balabolka to synthesize speech
balabolka.exe -mqs "%TEXT_FILE%" "%OUTPUT_FILE%" "%VOICE%"
