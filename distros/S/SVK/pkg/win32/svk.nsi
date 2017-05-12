SetCompressor bzip2

!define MUI_COMPANY "Best Practical Solutions, LLC"
!define MUI_PRODUCT "SVK"
!ifndef MUI_VERSION
!define MUI_VERSION "unknown"
!endif
!define MUI_NAME    "svk"
!define MUI_ICON "${MUI_NAME}.ico"
!define MUI_UNICON "${MUI_NAME}-uninstall.ico"

!include "MUI.nsh"
!include "Path.nsh"

!include "Library.nsh"

XPStyle On
Name "${MUI_PRODUCT}"
OutFile "..\${MUI_NAME}-${MUI_VERSION}.exe"
InstallDir "$PROGRAMFILES\${MUI_NAME}"
ShowInstDetails hide
InstProgressFlags smooth

  !define MUI_ABORTWARNING

;--------------------------------
;Pages

  !insertmacro MUI_PAGE_LICENSE "..\ARTISTIC"
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  !insertmacro MUI_LANGUAGE "English"

Section "modern.exe" SecCopyUI
    WriteRegStr HKLM \
		"SOFTWARE\${MUI_COMPANY}\${MUI_PRODUCT}" "" "$INSTDIR"
    SetOverwrite on
    SetOutPath $INSTDIR
    File /r ..\bin
    File /r ..\lib
    File /r ..\iconv
    File /r /x t\checkout ..\site
    File /r ..\win32
 
    ; in case of old installation
    Delete "$INSTDIR\bin\svk.bat"
    Delete "$INSTDIR\svk.bat"

    ; Generate bootstrap batch file on the fly using $INSTDIR
    FileOpen $1 "$INSTDIR\svk.bat" w
    FileWrite $1 "@echo off$\n"
    FileWrite $1 "set APR_ICONV_PATH=$INSTDIR\iconv$\n"
    FileWrite $1 "set OLDPATH=%PATH%$\n"
    FileWrite $1 "set PATH=$INSTDIR\bin;%PATH%$\n"
    FileWrite $1 "if $\"%OS%$\" == $\"Windows_NT$\" goto WinNT$\n"
    FileWrite $1 "$\"$INSTDIR\bin\perl$\" $\"$INSTDIR\bin\svk$\" %1 %2 %3 %4 %5 %6 %7 %8 %9$\n"
    FileWrite $1 "goto endofperl$\n"
    FileWrite $1 ":WinNT$\n"
    FileWrite $1 "$\"$INSTDIR\bin\perl$\" $\"$INSTDIR\bin\svk$\" %*$\n"
    FileWrite $1 "if NOT $\"%COMSPEC%$\" == $\"%SystemRoot%\system32\cmd.exe$\" goto endofperl$\n"
    FileWrite $1 "if %errorlevel% == 9009 echo You do not have SVK installed correctly.$\n"
    FileWrite $1 "if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul$\n"
    FileWrite $1 "set PATH=%OLDPATH%$\n"
    FileWrite $1 "set APR_ICONV_PATH=$\n"
    FileClose $1

    ; Generate bootstrap batch file on the fly using $INSTDIR
    FileOpen $1 "$INSTDIR\site\maketest.bat" w
    FileWrite $1 "@echo off$\n"
    FileWrite $1 "set APR_ICONV_PATH=$INSTDIR\iconv$\n"
    FileWrite $1 "cd $\"$INSTDIR\bin$\"$\n"
    FileWrite $1 "if $\"%OS%$\" == $\"Windows_NT$\" goto WinNT$\n"
    FileWrite $1 "goto endofperl$\n"
    FileWrite $1 ":WinNT$\n"
    FileWrite $1 "if NOT $\"%COMSPEC%$\" == $\"%SystemRoot%\system32\cmd.exe$\" goto endofperl$\n"
    FileWrite $1 "if %errorlevel% == 9009 echo You do not have SVK installed correctly.$\n"
    FileWrite $1 "if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul$\n"
    FileWrite $1 ".\perl -I..\site prove.bat -r ..\site\t$\n"
    FileWrite $1 "set APR_ICONV_PATH=$\n"
    FileClose $1
    ; XXX: try to cd back to where we are please


    WriteUninstaller "$INSTDIR\Uninstall.exe"

Libeay32:
    IfFileExists "$SYSDIR\libeay32.dll" RenameLibeay32 SSLeay32
RenameLibeay32:
    Rename "$SYSDIR\libeay32.dll" "$SYSDIR\libeay32.dll.old"

SSLeay32:
    IfFileExists "$SYSDIR\ssleay32.dll" RenameSSLeay32 Done
RenameSSLeay32:
    Rename "$SYSDIR\ssleay32.dll" "$SYSDIR\ssleay32.dll.old"


Done:
    ; Add  directory to the PATH for svk.bat and DLLs
    Push $INSTDIR
    Call AddToPath
SectionEnd
 
Section "Uninstall"
  Push $INSTDIR
  Call un.RemoveFromPath
  RMDir /r $INSTDIR
  DeleteRegKey HKLM "SOFTWARE\${MUI_COMPANY}\${MUI_PRODUCT}"
SectionEnd
