@ECHO OFF
REM This script finds the full path to a Perl modulino and executes it.

SET MODULINO=Module::ScanDeps::FindRequires

FOR /F "usebackq" %%i IN (`perl -M%MODULINO% -e "print $INC{'%MODULINO%'}"`) DO (
    SET MODULINO_PATH=%%i
)

REM Execute the Perl script, passing all command-line arguments.
perl "%MODULINO_PATH%" %*
