use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'SAP::WAS::SOAP',
    'VERSION_FROM' => 'lib/SAP/WAS/SOAP.pm', # finds $VERSION
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'PREREQ_PM'	=> {'SOAP::Lite' => 0.50,
                    },
    clean	=> { 'FILES' },
    dist	=> { 'TARFLAGS' => 'cvf',
		     'COMPRESS' => 'gzip -9f',
		     'SUFFIX'   => '.tar.gz' },
);
