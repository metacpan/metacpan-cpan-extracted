use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'SAP::BC::XMLRFC',
    'VERSION_FROM' => 'lib/SAP/BC/XMLRFC.pm', # finds $VERSION
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'PREREQ_PM'	=> {'LWP::UserAgent' => 1.68,
                    'LWP::Simple' => 1.32,
                    'HTTP::Request' => 1.26,
                    'XML::Parser' => 2.27},
    clean	=> { 'FILES' },
    dist	=> { 'TARFLAGS' => 'cvf',
		     'COMPRESS' => 'gzip -9f',
		     'SUFFIX'   => '.tar.gz' },
);
