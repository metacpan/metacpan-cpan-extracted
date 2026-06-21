use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Syntax::Infix::OptionalChain registers the `?->` safe-navigation operator via
# Infix::Custom; the per-step navigator is a small XSUB (OptionalChain.xs). The
# operator needs the core PL_infix_plugin hook, added in perl 5.38, which is
# therefore the minimum -- the module does nothing useful below it.

my %WriteMakefileArgs = (
    NAME             => 'Syntax::Infix::OptionalChain',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Syntax/Infix/OptionalChain.pm',
    ABSTRACT_FROM    => 'lib/Syntax/Infix/OptionalChain.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.038',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Infix::Custom' => '0.01',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Syntax-Infix-OptionalChain-*' },
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
