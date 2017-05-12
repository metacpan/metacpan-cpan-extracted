use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME             => 'Moonshine::Component',
    AUTHOR           => q{Robert Acock <thisusedtobeanemail>},
    VERSION_FROM     => 'lib/Moonshine/Component.pm',
    ABSTRACT_FROM    => 'lib/Moonshine/Component.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Moonshine::Test' => 0.14,
        'Moonshine::Util' => 0.06,
        'Moonshine::Element' => 0.11,
        'Moonshine::Magic' => 0.07,
    },
    PREREQ_PM => {
        'Moonshine::Element' => 0.11,
        'Moonshine::Magic'   => 0.07,
        'Params::Validate'   => 1.26,
        'Ref::Util'          => 0.113,
        'UNIVERSAL::Object'  => 0.04, 
        'strict'             => 0,
        'warnings'           => 0,
        'feature'            => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Moonshine-Component-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ThisUsedToBeAnEmail/Moonshine-Component.git',
                web  => 'https://github.com/ThisUsedToBeAnEmail/Moonshine-Component',
            },
        },
    },
    META_ADD => {
        provides => Module::Metadata->provides(version => '2', dir => 'lib'),
    }, 
);
