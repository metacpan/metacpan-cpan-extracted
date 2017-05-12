use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'IO::DB',
    AUTHOR              => 'David Bialac <dbialac@yahoo.com>',
    VERSION_FROM        => 'lib/IO/DB.pm',
    ABSTRACT_FROM       => 'lib/IO/DB.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DBD'        => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IO-DB-*' },
);
