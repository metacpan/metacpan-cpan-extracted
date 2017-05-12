use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	   => 'Net::Plesk',
    'VERSION_FROM' => 'lib/Net/Plesk.pm', # finds $VERSION
    'PREREQ_PM'    => { 'XML::Simple'            => 0,
                        'XML::XPath'             => 0,
                        'XML::XPath::XMLParser'  => 0,
                        'LWP'                    => 0,
                      },
);
