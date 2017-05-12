use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME             => 'MooX::VariantAttribute',
    AUTHOR           => q{Robert Acock <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/MooX/VariantAttribute.pm',
    ABSTRACT_FROM    => 'lib/MooX/VariantAttribute.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Moonshine::Test' => 0.13,
    },
    PREREQ_PM => {
        'Carp' => 0,
        'Scalar::Util' => 0,
        'Combine::Keys' => 0.04,
        'Moo' => 0,
        'MooX::ReturnModifiers' => 0.03,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MooX-VariantAttribute-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ThisUsedToBeAnEmail/MooX-VariantAttribute.git',
                web  => 'https://github.com/ThisUsedToBeAnEmail/MooX-VariantAttribute',
            },
        },
    },
    META_ADD => {
        provides => Module::Metadata->provides(version => '2', dir => 'lib'),
	}, 
);
