use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Rose::DBx::TestDB',
    AUTHOR              => 'Peter Karman <perl@peknet.com>',
    VERSION_FROM        => 'lib/Rose/DBx/TestDB.pm',
    ABSTRACT_FROM       => 'lib/Rose/DBx/TestDB.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'DBD::SQLite'   => '1.08',
        'File::Temp'    => 0,
        'Rose::DB'      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Rose-DBx-TestDB-*' },
);
