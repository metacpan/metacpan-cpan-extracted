use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Elexol::EtherIO24',
    AUTHOR              => 'Chris Luke <chrisy@flirble.org>',
    VERSION_FROM        => 'lib/Net/Elexol/EtherIO24.pm',
    ABSTRACT_FROM       => 'lib/Net/Elexol/EtherIO24.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'threads' => 0,
	'threads::shared' => 0,
	'Socket' => 0,
	'IO::Socket::INET' => 0,
	'IO::Select' => 0,
	'Time::HiRes' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Elexol-EtherIO24-*' },
);
