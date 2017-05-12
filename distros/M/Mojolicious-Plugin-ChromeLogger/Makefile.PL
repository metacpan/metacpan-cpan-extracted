use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::ChromeLogger',
    AUTHOR           => q{Viktor Turskyi <koorchik@cpan.org>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/ChromeLogger.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/ChromeLogger.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Mojolicious' => '4.0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojolicious-Plugin-ChromeLogger-*' },
);
