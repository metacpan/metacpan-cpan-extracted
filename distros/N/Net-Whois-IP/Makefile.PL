use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Net::Whois::IP',
    'VERSION_FROM' => 'IP.pm', # finds $VERSION
    'BUILD_REQUIRES'	 => {
		'Regexp::IPv6' => '.02',
    },
);
