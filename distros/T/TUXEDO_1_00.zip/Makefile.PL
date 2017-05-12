use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'TUXEDO',
    'VERSION_FROM' => 'TUXEDO.pm', # finds $VERSION
    'LIBS'	=> ['-L/usr/local/bea/tuxedo8.0/lib -ltux -lbuft -lfml -lfml32 -lengine -R/usr/lib/lwp -ltmib -lpthread -lposix4 -lnsl -lsocket'],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '-I/usr/local/bea/tuxedo8.0/include',     # e.g., '-I/usr/include/other' 
);
