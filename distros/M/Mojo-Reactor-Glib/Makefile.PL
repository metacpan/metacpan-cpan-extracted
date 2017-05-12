use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojo::Reactor::Glib',
    AUTHOR           => q{Ralesk <ralesk@cpan.org>},
    VERSION_FROM     => 'lib/Mojo/Reactor/Glib.pm',
    ABSTRACT_FROM    => 'lib/Mojo/Reactor/Glib.pm',
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
        'Glib'              => 0,
        'Mojolicious'       => 0,
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'hg',
                web => 'https://bitbucket.org/ralesk/mojo-reactor-glib',
                url => 'https://bitbucket.org/ralesk/mojo-reactor-glib',
            },
            bugtracker => {
                web => 'https://bitbucket.org/ralesk/mojo-reactor-glib/issues',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojo-Reactor-Glib-*' },
);
