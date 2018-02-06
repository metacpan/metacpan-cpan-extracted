use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME             => 'Moonshine::Test',
    AUTHOR           => q{Robert Acock <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/Moonshine/Test.pm',
    ABSTRACT_FROM    => 'lib/Moonshine/Test.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Tester' => 0,
        'Test::MockObject' => 0,
        'strict' => 0,
        'warnings' => 0,
    },
    PREREQ_PM => {
        'Acme::AsciiEmoji' => 0.11,
        'Test::More' => 0,
        'Scalar::Util' => 0,
        'Params::Validate' => 0,
        'B' => 0,
        'Exporter' => 0,
        'strict' => 0,
        'warnings' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Moonshine-Test-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ThisUsedToBeAnEmail/Moonshine-Test.git',
                web  => 'https://github.com/ThisUsedToBeAnEmail/Moonshine-Test',
            },
        },
    },
    META_ADD => {
        provides => Module::Metadata->provides(version => '2', dir => 'lib'),
    }, 
);
