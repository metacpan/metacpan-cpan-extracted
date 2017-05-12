use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Queue::Priority',
    AUTHOR              => q{"Jeff Ober" <"jeffober@gmail.com">},
    VERSION_FROM        => 'lib/Queue/Priority.pm',
    ABSTRACT            => 'priority queue implemented as an array heap',
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Queue-Priority-*' },
    PREREQ_PM => {
        'Const::Fast' => 0,
        'POSIX'       => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'  => 0,
    },
);
