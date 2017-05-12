use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::SRCDS::Queries',
    AUTHOR              => 'Masanori Hara <massa.hara at gmail.com>',
    VERSION_FROM        => 'lib/Net/SRCDS/Queries.pm',
    ABSTRACT_FROM       => 'lib/Net/SRCDS/Queries.pm',
    PL_FILES            => {},
    LICENSE             => 'perl',
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-SRCDS-Queries-*' },
);
