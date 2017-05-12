use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME             => 'Pod::Simpler::Aoh',
    AUTHOR           => q{Robert Acock <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/Pod/Simpler/Aoh.pm',
    ABSTRACT_FROM    => 'lib/Pod/Simpler/Aoh.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Module::Metadata' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moo' => '1.0010001',
        'Pod::Simple' => '3.29',
        'Type::Tiny' => '1.000006',
        'MooX::LazierAttributes' => '0.11',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Pod-Simpler-Aoh-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ThisUsedToBeAnEmail/Pod-Simpler-Aoh.git',
                web  => 'https://github.com/ThisUsedToBeAnEmail/Pod-Simpler-Aoh',
            },
        },
    },
    META_ADD => {
        provides => Module::Metadata->provides(version => '2', dir => 'lib'),
}, 
);
