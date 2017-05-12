use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'String::String',
    AUTHOR              => 'YAMASHINA Hio <hio@hio.jp>',
    VERSION_FROM        => 'lib/String/String.pm',
    ABSTRACT_FROM       => 'lib/String/String.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'String-String-*' },
);
