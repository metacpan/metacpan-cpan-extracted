use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Template::Plugin::Calendar::Simple',
    AUTHOR           => q{jeffa <info+cpan@unlocalhost.com>},
    VERSION_FROM     => 'lib/Template/Plugin/Calendar/Simple.pm',
    ABSTRACT_FROM    => 'lib/Template/Plugin/Calendar/Simple.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Template'         => '2.00',
        'Calendar::Simple' => '1.04',
    },
    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
        (META_ADD => {
            resources => {
                homepage   => 'https://github.com/jeffa/Template-Plugin-Calendar-Simple',
                repository => 'https://github.com/jeffa/Template-Plugin-Calendar-Simple.git',
            },
        })
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Template-Plugin-Calendar-Simple-*' },
);
