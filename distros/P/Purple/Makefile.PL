use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Purple',
    AUTHOR              => 'BlueOxen Associates <purple@blueoxen.net>',
    VERSION_FROM        => 'lib/Purple.pm',
    ABSTRACT_FROM       => 'lib/Purple.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'HTTP::Server::Simple' => 0.18,
        'DBD::SQLite' => 0,
        'DB_File' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Purple-*' },
);
