use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'TUXEDO',
    'VERSION_FROM' => 'TUXEDO.pm', # finds $VERSION
    'LIBS'	=> ['-LC:/bea/tuxedo8.0/lib -ltux -lbuft -lfml -lfml32 -lengine  -lwsock32 -lkernel32 -ladvapi32 -luser32 -lgdi32 -lcomdlg32 -lwinspool'],   # e.g., '-lm' 
    'DEFINE'	=> '-D__TURBOC__',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '-IC:/bea/tuxedo8.0/include',     # e.g., '-I/usr/include/other' 
);
