@echo off
REM PODNAME: awspollyogg
REM ABSTRACT: script converting textfile named $1
REM                               into mp3file $2
REM                          with engine:voice $3
REm           using aws polly

REM Check if the correct number of arguments are provided
if "%~3"=="" (
    echo Usage: %0 ^<input_text_file^> ^<output_mp3_file^> ^<voice^>
    exit /b 1
)

REM Set variables from the arguments
set "TEXT_FILE=%~1"
set "OUTPUT_FILE=%~2"
set "ENGINE_VOICE=%~3"

REM Split the ENGINE_VOICE into ENGINE and VOICE
for /f "tokens=1,2 delims=:" %%A in ("%ENGINE_VOICE%") do (
    set "ENGINE=%%A"
    set "VOICE=%%B"
)

REM Call AWS Polly to synthesize speech
aws polly synthesize-speech --text file://%TEXT_FILE% --output-format mp3 --voice-id %VOICE% --engine %ENGINE% "%OUTPUT_FILE%"
