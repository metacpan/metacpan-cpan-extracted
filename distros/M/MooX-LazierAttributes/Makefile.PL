use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME             => 'MooX::LazierAttributes',
    AUTHOR           => q{Robert Acock <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/MooX/LazierAttributes.pm',
    ABSTRACT_FROM    => 'lib/MooX/LazierAttributes.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Module::Metadata' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Requires' => 0,
    },
    PREREQ_PM => {
        'MooX::ReturnModifiers' => '0.03',
        'Scalar::Util' => 0,
        'constant' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MooX-LazierAttributes-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ThisUsedToBeAnEmail/MooX-LazierAttributes.git',
                web  => 'https://github.com/ThisUsedToBeAnEmail/MooX-LazierAttributes',
            },
        },
    },
    META_ADD => {
        provides => Module::Metadata->provides(version => '2', dir => 'lib'),
	}, 
);
