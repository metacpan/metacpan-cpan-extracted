use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mojolicious::Plugin::KossyValidator',
    AUTHOR              => '扶凯 <iakuf@163.com>',
    EXE_FILES           => [],
    PL_FILES            => {},
    LICENSE             => "perl",
    DISTNAME            => 'Mojolicious-Plugin-KossyValidator',
    VERSION_FROM        => 'lib/Mojolicious/Plugin/KossyValidator.pm',
    PREREQ_PM => {
        'Test::More' => 0,
        'Mojolicious'     => '3.0',
        'Hash::MultiValue' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-KossyValidator-*' },
);
