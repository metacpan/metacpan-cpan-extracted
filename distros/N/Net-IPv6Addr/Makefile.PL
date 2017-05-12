use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Net::IPv6Addr',
    'VERSION_FROM' => 'IPv6Addr.pm', # finds $VERSION
    'PREREQ_PM' => { 
	'Net::IPv4Addr' => 0, 
	'Math::Base85' => 0 
    },
);
