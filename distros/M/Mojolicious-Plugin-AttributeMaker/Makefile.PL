use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::AttributeMaker',
    AUTHOR           => q{"Evgeniy Vansevich" <"hammer@cpan.org">},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/AttributeMaker.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/AttributeMaker.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010001,
    META_MERGE       => {
        requires  => { perl => '5.010001' },
        resources => {
            license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
            repository => {
                type => 'git',
                url  => 'git://github.com/Perlovod/Mojolicious-Plugin-AttributeMaker.git',
                web  => 'https://github.com/Perlovod/Mojolicious-Plugin-AttributeMaker',
            },
        },
        no_index => { directory => ['t'] }
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'   => 0,
        'Mojolicious'  => 3,
        'Module::Find' => 0
    },
    PREREQ_PM => {

    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Mojolicious-Plugin-AttributeMaker-*' },
);
