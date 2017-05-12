PERLSRV.dll: src/perlglue.cpp src/STAFPerlService.cpp src/synchelper.cpp
	C:\Perl\bin\perl.exe -MExtUtils::Embed -e xsinit
	cl  -nologo -GF -W3 -MD -Zi -DNDEBUG -O1 -DWIN32 -D_CONSOLE -DNO_STRICT -DHAVE_DES_FCRYPT -DUSE_SITECUSTOMIZE -DPRIVLIB_LAST_IN_INC -DPERL_IMPLICIT_CONTEXT -DPERL_IMPLICIT_SYS -DUSE_PERLIO -DPERL_MSVCRT_READFIX   -I"C:\Perl\lib\CORE"   -I"./src"  -c src/STAFPerlService.cpp src/perlglue.cpp src/synchelper.cpp perlxsi.c
	link -dll -nologo -nodefaultlib -debug -opt:ref,icf  -libpath:"C:\Perl\lib\CORE"  -machine:x86 STAFPerlService.obj perlglue.obj synchelper.obj perlxsi.obj  STAF.lib perl510.lib   oldnames.lib kernel32.lib user32.lib gdi32.lib winspool.lib  comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib  netapi32.lib uuid.lib ws2_32.lib mpr.lib winmm.lib  version.lib odbc32.lib odbccp32.lib msvcrt.lib -def:"src/STAFPerlService.def" -out:"PERLSRV.dll" -libpath:"C:\Perl\STAF/lib"

install:
	copy PERLSRV.dll C:\Perl\STAF/bin/PERLSRV.dll

clean:
	del *.obj *.lib *.dll *.pdb *.exp perlxsi.c

test:
	C:\Perl\bin\perl.exe t/01.pl
	C:\Perl\bin\perl.exe t/02.pl
	C:\Perl\bin\perl.exe t/03.pl
	C:\Perl\bin\perl.exe t/04.pl
	C:\Perl\bin\perl.exe t/05.pl
	C:\Perl\bin\perl.exe t/06.pl
	C:\Perl\bin\perl.exe t/07.pl
	C:\Perl\bin\perl.exe t/08.pl
	C:\Perl\bin\perl.exe t/09.pl

