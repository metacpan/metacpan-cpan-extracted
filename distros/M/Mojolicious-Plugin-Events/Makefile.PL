use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::Events',
    AUTHOR           => q{Adrian Crisan <adrian.crisan88@gmail.com>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/Events.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/Events.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Mojo::Base'          => 0,
        'Mojolicious::Plugin' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojolicious-Plugin-Events-*' },
);
