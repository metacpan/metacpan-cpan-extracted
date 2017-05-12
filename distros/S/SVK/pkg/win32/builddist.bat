REM This script builds a SVK installation package
REM The environment (IE:system path) must be configured properly before
REM    running this script! (see setenv.bat)
REM After this script finishes, compile the NSIS script (svk.nsi) 
REM    located in the build\win32\ folder.
REM 
REM This script requires:
REM    That SVK be built
REM    That pp is installed
REM    That a zip/unzip program is available (Info-Zip)
REM
REM If mtee is available, a logfile can be created with a command line like:
REM builddist 2>&1 | mtee /d/t log.txt
REM
REM Adjust the following to your needs!
SET SVNHOME=C:/strawberry-perl/svn-win32-1.4.4
SET SVKSOURCE=c:/strawberry-perl/src/SVK-v2.0.1
SET PERLHOME=C:/strawberry-perl/perl
SET PPSOURCESCRIPT=c:/strawberry-perl/src/SVK-v2.0.1/blib/script/SVK
SET FIXZIP=c:\utils\zip -d build\SVK.par lib\SVK.
SET UNZIPPER=c:\utils\unzip -o -d build build\SVK.par
REM SET UNZIPPER="c:\program files\7-Zip\7z" x -y -obuild
REM
SET PAR_VERBATIM=1
REM
REM Remove and remnants of the previous build
rd /s /q build

REM create the working folders
mkdir build

REM Create a new set of path specific PAR (pp) options
REM Copy the original parameter file to make run-time appends
copy paroptions.txt parsvkfixups.txt
REM This is done here because we cannot do variable subs in the parmater file
REM do this to bring in the help pod's
echo -a "%SVKSOURCE%/blib/lib/SVK/Help;lib/SVK/Help" >> parsvkfixups.txt
REM # do this to bring in the I18N
echo -a "%SVKSOURCE%/blib/lib/SVK/I18N;lib/SVK/I18N" >> parsvkfixups.txt
REM # do this to fix the missing POSIX files
echo -a "%PERLHOME%/lib/auto/POSIX;lib/auto/POSIX" >> parsvkfixups.txt
REM Add the SVK source path to the build
echo -I %SVKSOURCE%/blib/lib >> parsvkfixups.txt

REM Move the built and Win32 specific files into the par
echo -a "%PERLHOME%/bin/perl.exe;bin/perl.exe" >> parsvkfixups.txt
echo -a "%PERLHOME%/bin/perl58.dll;bin/perl58.dll" >> parsvkfixups.txt
echo -a "%PERLHOME%/bin/prove.bat;bin/prove.bat" >> parsvkfixups.txt
echo -a "%SVNHOME%/bin/intl3_svn.dll;bin/intl3_svn.dll" >> parsvkfixups.txt
echo -a "%SVNHOME%/bin/libapr.dll;bin/libapr.dll" >> parsvkfixups.txt
echo -a "%SVNHOME%/bin/libapriconv.dll;bin/libapriconv.dll" >> parsvkfixups.txt
echo -a "%SVNHOME%/bin/libaprutil.dll;bin/libaprutil.dll" >> parsvkfixups.txt
echo -a "%SVNHOME%/bin/libdb44.dll;bin/libdb44.dll" >> parsvkfixups.txt
echo -a "%SVNHOME%/bin/libeay32.dll;bin/libeay32.dll" >> parsvkfixups.txt
echo -a "%SVNHOME%/bin/ssleay32.dll;bin/ssleay32.dll" >> parsvkfixups.txt
echo -a "%SVKSOURCE%/blib/script/svk;bin/svk" >> parsvkfixups.txt
echo -a "%SVKSOURCE%/blib/script/svk.bat;bin/svk.bat" >> parsvkfixups.txt
echo -a "%SVKSOURCE%/pkg/win32/maketest.bat;win32/maketest.bat" >> parsvkfixups.txt
echo -a "%SVKSOURCE%/pkg/win32/svk.ico;win32/svk.ico" >> parsvkfixups.txt
echo -a "%SVKSOURCE%/pkg/win32/svk-uninstall.ico;win32/svk-uninstall.ico" >> parsvkfixups.txt
echo -a "%SVKSOURCE%/pkg/win32/svk.nsi;win32/svk.nsi" >> parsvkfixups.txt
echo -a "%SVKSOURCE%/pkg/win32/Path.nsh;win32/Path.nsh" >> parsvkfixups.txt
echo -a "%SVKSOURCE%/contrib;site/contrib" >> parsvkfixups.txt
echo -a "%SVKSOURCE%/utils;site/utils" >> parsvkfixups.txt
echo -a "%SVKSOURCE%/t;site/t" >> parsvkfixups.txt
echo -a "%SVKSOURCE%/README;README" >> parsvkfixups.txt
echo -a "%SVKSOURCE%/CHANGES;CHANGES" >> parsvkfixups.txt
echo -a "%SVKSOURCE%/ARTISTIC;ARTISTIC" >> parsvkfixups.txt
echo -a "%SVKSOURCE%/COPYING;COPYING" >> parsvkfixups.txt

REM using par, build the compressed output
call pp @parsvkfixups.txt %PPSOURCESCRIPT%

REM Must do a fixup before the .par can be un-packed
REM Remove the lib\SVK. file as it conflicts with the lib\SVK folder on CIFS
call %FIXZIP%
REM extract the par THIS USES Info-Zip unzip but could use 7z.exe
call %UNZIPPER% 

REM remove the dynamicically created par options
del /F/Q parsvkfixups.txt

REM remove the .par after it is built
del /F/Q build\SVK.par

REM remove the script folder because we do not need it
rd /S/Q build\script

:exit
