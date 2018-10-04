use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Mojolicious::Plugin::ContextResources',
    VERSION_FROM    => 'lib/Mojolicious/Plugin/ContextResources.pm',
    ABSTRACT_FROM   => 'lib/Mojolicious/Plugin/ContextResources.pm',
    MAKEFILE        => 'Makefile',
    LICENSE         => 'artistic_2',
    AUTHOR          => 'Roman V. Nikolaev <rshadow@rambler.ru>',
    MIN_PERL_VERSION => '5.10.0',
    
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'   => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'            => 0,
    },
    PREREQ_PM => {
        'Mojolicious'           => '5.54',
    },
    test         => {TESTS => 't/*.t'},
    META_MERGE   => {
        resources      => {
            bugtracker => 
                'https://github.com/dr-co/mojolicious-plugin-contex_resources/issues',
            homepage   => 
                'https://github.com/dr-co/mojolicious-plugin-contex_resources',
            repository => {
                type => 'git',
                url  => 'https://github.com:dr-co/mojolicious-plugin-contex_resources.git',
                web  => 'https://github.com/dr-co/mojolicious-plugin-contex_resources',
            },
        },
    },
);
