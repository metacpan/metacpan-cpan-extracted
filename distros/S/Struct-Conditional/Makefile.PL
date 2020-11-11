use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

my %WriteMakefileArgs = (
    NAME             => 'Struct::Conditional',
    AUTHOR           => q{LNATION <email@lnation.org>},
    VERSION_FROM     => 'lib/Struct/Conditional.pm',
    ABSTRACT_FROM    => 'lib/Struct/Conditional.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'Module::Metadata' => '0'
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
	'Clone' => '0.45',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Struct-Conditional-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 0,
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ThisUsedToBeAnEmail/Struct-Conditional.git',
                web  => 'https://github.com/ThisUsedToBeAnEmail/Struct-Conditional',
            },
        },
    },
    META_ADD => {
        provides => Module::Metadata->provides(version => '2', dir => 'lib'),
    }
);

delete $WriteMakefileArgs{META_MERGE} && delete $WriteMakefileArgs{META_ADD}
    unless eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 };

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
