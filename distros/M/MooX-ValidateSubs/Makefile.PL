use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME             => 'MooX::ValidateSubs',
    AUTHOR           => q{Robert Acock <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/MooX/ValidateSubs.pm',
    ABSTRACT_FROM    => 'lib/MooX/ValidateSubs.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'MooX::ReturnModifiers' => '0.09',
		'Type::Tiny' => '1.002000', 
		'Moo' => 0,
        'Carp' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MooX-ValidateSubs-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        x_contributors => [
			"Toby Inkster (TOBYINK) <tobyink\@cpan.org>"
		],
		resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ThisUsedToBeAnEmail/MooX-ValidateSubs.git',
                web  => 'https://github.com/ThisUsedToBeAnEmail/MooX-ValidateSubs',
            },
        },
    },
    META_ADD => {
        provides => Module::Metadata->provides(version => '2', dir => 'lib'),
	}, 
);
