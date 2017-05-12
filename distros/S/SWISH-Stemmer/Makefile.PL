use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'SWISH::Stemmer',
    'VERSION_FROM'  => 'Stemmer.pm', # finds $VERSION
    'LIBS'          => [''],   # e.g., '-lm' 
    'DEFINE'        => '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'           => '',     # e.g., '-I/usr/include/other' 
    'MYEXTLIB'      => 'lib/libmylib$(LIB_EXT)',
    'dist' => { COMPRESS=>"gzip",
                SUFFIX=>"gz",
                PREOP=> 'pod2text -80 < Stemmer.pm > README',
              },

);

sub MY::postamble {
'
$(MYEXTLIB): lib/Makefile
	cd lib && $(MAKE) $(PASSTHRU)
';
}
