use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	   => 'Number::Spice',
    'VERSION_FROM' => 'Spice.pm', # finds $VERSION
    ($] > 5.004) ? (
       ABSTRACT => 'Conversion of numbers in Spice syntax',
       AUTHOR   => 'Wim Verhaegen <wim.verhaegen@ieee.org>',
    ) : (),
    'dist'         => { 
	CI        => 'cvs ci',
	RCS_LABEL => 'cvs tag Number-Spice-$(VERSION_SYM)' 
    }, # support Concurrent source Versioning System
);
