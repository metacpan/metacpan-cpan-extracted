use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Passwd::Linux',
    'VERSION_FROM' => 'Linux.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '-I.',     # e.g., '-I/usr/include/other'
    'OBJECT'    => q[Linux$(OBJ_EXT)],
);
