use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PowerDNS::Control::Client',
    AUTHOR              => 'Augie Schwer <augie@cpan.org>',
    VERSION_FROM        => 'lib/PowerDNS/Control/Client.pm',
    ABSTRACT_FROM       => 'lib/PowerDNS/Control/Client.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' 	=> 0,
	'Carp'		=> 0,
	'English'	=> 0,
	'IO::Socket'	=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PowerDNS-Control-Client-*' },
);
