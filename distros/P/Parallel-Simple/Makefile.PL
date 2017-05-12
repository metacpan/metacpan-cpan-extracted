use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Parallel::Simple',
    AUTHOR              => 'Ofer Nave <ofer@netapt.com>',
    VERSION_FROM        => 'lib/Parallel/Simple.pm',
    ABSTRACT_FROM       => 'lib/Parallel/Simple.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Parallel-Simple-*' },
);
