use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Optional except for cpancover, cpantesters etc.
my $extra_test =
  ( $ENV{EXTENDED_TESTING} || $ENV{AUTOMATED_TESTING} )
  ? 'requires'
  : 'recommends';

my %WriteMakefileArgs = (
    NAME             => 'System::CPU',
    AUTHOR           => q{Dimitrios Kechagias <dkechag@cpan.org>},
    VERSION_FROM     => 'lib/System/CPU.pm',
    ABSTRACT_FROM    => 'lib/System/CPU.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test2::V0' => '0',
    },
    PREREQ_PM => {
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'System-CPU-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => {
            test => {
                $extra_test => {
                    'Test::MockFile' => '0',
                }
            },
        },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git://github.com/dkechag/System-CPU.git',
                web  => 'https://github.com/dkechag/System-CPU',
            },
        },
    },
);

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
