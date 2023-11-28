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
        'Module::Metadata' => '1.000033',
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Requires' => 0,
    },
    PREREQ_PM => {
        'MooX::ReturnModifiers' => '1.000001',
        'namespace::clean' => '0.27',
	'Clone' => '0.39',
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
