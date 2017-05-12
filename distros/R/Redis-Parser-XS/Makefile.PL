
use 5.008002;
use ExtUtils::MakeMaker;

WriteMakefile(
    dist => {
        PREOP    => 'pod2text lib/Redis/Parser/XS.pm '.
                      '| tee README >$(DISTVNAME)/README; '.
                    'chmod -R u=rwX,go=rX . ;',
        COMPRESS => 'gzip -9v',
        SUFFIX   => '.gz',
    },

    NAME          => 'Redis::Parser::XS',
    VERSION_FROM  => 'lib/Redis/Parser/XS.pm',
    ABSTRACT_FROM => 'lib/Redis/Parser/XS.pm',
    AUTHOR        => 'Alexandr Gomoliako <zzz@zzz.org.ua>',
    PREREQ_PM     => {
        'Test::More' => 0,
    },
#     EXE_FILES     => [""],

    INC          => '-I.', # e.g., '-I. -I/usr/include/other'
    DEFINE       => '', # e.g., '-DHAVE_SOMETHING'
    OBJECT       => '$(O_FILES)', # link all the C files too
);

