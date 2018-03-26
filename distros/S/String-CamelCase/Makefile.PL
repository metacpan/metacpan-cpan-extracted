use strict;
use warnings;
use ExtUtils::MakeMaker;


WriteMakefile(
    NAME                => 'String::CamelCase',
    AUTHOR              => 'YAMASHINA Hio <hio@cpan.org>',
    VERSION_FROM        => 'lib/String/CamelCase.pm',
    ABSTRACT_FROM       => 'lib/String/CamelCase.pm',
    PL_FILES            => {},
    LICENSE             => 'perl_5',
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'String-CamelCase-*' },
);
