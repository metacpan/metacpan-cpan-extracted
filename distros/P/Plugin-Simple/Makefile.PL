use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Plugin::Simple',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/Plugin/Simple.pm',
    ABSTRACT_FROM    => 'lib/Plugin/Simple.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
    },
    PREREQ_PM => {
        'Module::Load' => 0,
        'Module::List' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Plugin-Simple-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/stevieb9/p5-plugin-simple/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/stevieb9/p5-plugin-simple.git',
                web  => 'https://github.com/stevieb9/p5-plugin-simple',
            },
        }})
     : ()
    ),
);
