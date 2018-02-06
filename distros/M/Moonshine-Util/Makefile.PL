use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME             => 'Moonshine::Util',
    AUTHOR           => q{Robert Acock <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/Moonshine/Util.pm',
    ABSTRACT_FROM    => 'lib/Moonshine/Util.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Moonshine::Test' => 0.16,
    },
    PREREQ_PM => {
        'strict' => 0,
        'warnings' => 0,
        'String::Trim::More' => 0.03,
        'String::Elide::Parts' => 0.07, 
        'Exporter::Tiny' => 0.044,
        'HTML::Valid' => 0.07,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Moonshine-Util-*' },
	META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ThisUsedToBeAnEmail/Moonshine-Util.git',
                web  => 'https://github.com/ThisUsedToBeAnEmail/Moonshine-Util',
            },
        },
    },
    META_ADD => {
        provides => Module::Metadata->provides(version => '2', dir => 'lib'),
	},
);
