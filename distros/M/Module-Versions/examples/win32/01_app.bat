@echo off
echo ===========================================================================
echo $Id: 01_app.bat 26 2006-09-19 09:57:57Z HVRTWall $
echo Copyright (c) 2006 Thomas Walloschke (thw@cpan.org). All rights reserved.
echo ===========================================================================

set script=perl ..\01_app.pl 
set help=-h
set version=-ver
set try1=-v
set try2="-v -o foo -o bar -o 007 -o Hi, Mr. Bond"
set nl=---------------------------------------------------------------- 

rem ----------------------------------------------------------------
for %%o in (%version% %try1% %help% %try2%) do (%script% "%%o" ) & echo %nl%

rem ----------------------------------------------------------------
echo Ready - Thank You for Testing
echo %nl%

rem ----------------------------------------------------------------
@pause
echo ============================================================================