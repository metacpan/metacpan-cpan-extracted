use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PowerDNS::Backend::MySQL',
    AUTHOR              => 'Augie Schwer <Augie@Schwer.us>',
    VERSION_FROM        => 'lib/PowerDNS/Backend/MySQL.pm',
    ABSTRACT_FROM       => 'lib/PowerDNS/Backend/MySQL.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' 	=> 0,
	'DBI'		=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PowerDNS-Backend-MySQL-*' },
);
