use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Pvm',
    'VERSION_FROM' => 'Pvm.pm', # finds $VERSION
#    'LIBS'	=> ["-L$PVM_ROOT/lib/$PVM_ARCH -lpvm3"],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '-I$(PVM_ROOT)/include',     # e.g., '-I/usr/include/other' 
#    'LDLOADLIBS' => '-L$(PVM_ROOT)/lib/$(PVM_ARCH) -lpvm3',
#    'DL_VARS' => 'PVM_ROOT',
    'MYEXTLIB' => '$(PVM_ROOT)/lib/$(PVM_ARCH)/libpvm3.a',
    'dist' => {COMPRESS => "gzip", SUFFIX => "gz"},
);
