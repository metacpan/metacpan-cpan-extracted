use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::JIPConf',
    AUTHOR           => q{Vladimir Zhavoronkov <flyweight@yandex.ru>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/JIPConf.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/JIPConf.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'     => 0,
        'English'        => 0,
    },
    PREREQ_PM => {
        'Mojolicious'         => 0,
        'Mojolicious::Plugin' => 0,
        'Mojo::Base'          => 0,
        'JIP::Conf'           => 0.02,
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    clean => {FILES => 'Mojolicious-Plugin-JIPConf-*'},
);

