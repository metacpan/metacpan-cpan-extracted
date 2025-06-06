use v5.26;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME               => 'REFECO::Blockchain::Contract::Solidity::ABI::Encoder',
    AUTHOR             => q{Reginaldo Costa <refeco@cpan.org>},
    VERSION_FROM       => 'lib/REFECO/Blockchain/Contract/Solidity/ABI/Encoder.pm',
    ABSTRACT_FROM      => 'lib/REFECO/Blockchain/Contract/Solidity/ABI/Encoder.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 'v5.26',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More'          => '0.98',
        'Test::Fatal'         => '0.016',
        'Test::Perl::Critic'  => '1.04',
        'Test::Code::TidyAll' => '0.82',
    },
    PREREQ_PM => {
        'Digest::Keccak' => '0.05',
        'Math::BigInt'   => '1.999837',
        'Carp'           => '1.50',
        'Module::Load'   => '0.36',
        'indirect'       => '0.39',
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    clean => {FILES => 'REFECO-Blockchain-Contract-Solidity-ABI-Encoder-*'},
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
