use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PowerDNS::Control::Server',
    AUTHOR              => 'Augie Schwer <augie@cpan.org>',
    VERSION_FROM        => 'lib/PowerDNS/Control/Server.pm',
    ABSTRACT_FROM       => 'lib/PowerDNS/Control/Server.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' 	=> 0,
	'IO::Socket'	=> 0,
	'POSIX'		=> 0,
	'Unix::Syslog'	=> 0,
	'Carp'		=> 0,
	'English'	=> 0,
	'Unix::PID'	=> 0,
	'Net::CIDR'	=> 0,
	'File::Temp'	=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PowerDNS-Control-Server-*' },
);
