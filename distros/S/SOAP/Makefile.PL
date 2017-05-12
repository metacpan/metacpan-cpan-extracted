use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'SOAP',
    'VERSION_FROM' => 'lib/SOAP/Defs.pm', # finds $VERSION
    PREREQ_PM => {
		  Apache => 1.26,
		  LWP => 5.47,
		  HTTP::Request => 1.26,
		  XML::Parser::Expat => 2.27,
    }
);
