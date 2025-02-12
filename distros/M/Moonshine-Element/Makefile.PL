use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME             => 'Moonshine::Element',
    AUTHOR           => q{Robert Acock <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/Moonshine/Element.pm',
    ABSTRACT_FROM    => 'lib/Moonshine/Element.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Moonshine::Test' => 0.14,
    },
    PREREQ_PM => {
        'UNIVERSAL::Object' => '0.06',
        'Ref::Util' => '0.113',
        'Data::GUID' => '0.048',
        'Autoload::AUTOCAN' =>  '0.004',
        'feature' => 0,
        'strict' => 0,
        'warnings' => 0,
	'Switch::Again' => '1.01'
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Moonshine-Element-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ThisUsedToBeAnEmail/Moonshine-Element.git',
                web  => 'https://github.com/ThisUsedToBeAnEmail/Moonshine-Element',
            },
        },
    },
    META_ADD => {
        provides => Module::Metadata->provides(version => '2', dir => 'lib'),
    }, 
);

