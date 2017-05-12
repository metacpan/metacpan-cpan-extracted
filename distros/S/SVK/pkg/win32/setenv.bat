REM Change the path to only include what is needed to build SVK
REM Set the path to all of the Strawberry-Perl places
set path=c:\strawberry-perl\perl\bin;c:\strawberry-perl\dmake\bin;c:\strawberry-perl\mingw\bin;c:\strawberry-perl\mingw\mingw32\bin
REM Set the path to the location of cmd.exe (OS SPECIFIC!)
set path=%path%;%WINDIR%\system32
REM Set the location of the SVN binaries and dll's
set path=%path%;C:\strawberry-perl\svn-win32-1.4.4\bin
REM Finally set the mingw compiler include and lib locations
set include=c:\strawberry-perl\mingw\include;
set lib=c:\strawberry-perl\mingw\lib;