use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'TRD::DebugLog',
    AUTHOR              => 'Takuya Ichikawa <trd.ichi@gmail.com>',
    VERSION_FROM        => 'lib/TRD/DebugLog.pm',
    ABSTRACT_FROM       => 'lib/TRD/DebugLog.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'TRD-DebugLog-*' },
);
