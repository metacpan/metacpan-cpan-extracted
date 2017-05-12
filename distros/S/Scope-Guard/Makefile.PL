use 5.006001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval($ExtUtils::MakeMaker::VERSION);

WriteMakefile(
    MIN_PERL_VERSION => '5.006001',
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    NAME          => 'Scope::Guard',
    VERSION_FROM  => 'lib/Scope/Guard.pm',
    ABSTRACT_FROM => 'lib/Scope/Guard.pm',
    AUTHOR        => 'chocolateboy <chocolate@cpan.org>',
    LICENSE       => 'perl',
    ($EUMM_VERSION >= 6.48 ? (MIN_PERL_VERSION => '5.6.1') : ()),
    ($EUMM_VERSION >= 6.31 ? (LICENSE => 'perl') : ()),
    ($EUMM_VERSION >= 6.46 ?
        (META_MERGE => {
            test_requires => {
                'Test::More' => 0,
            },
            resources => {
                repository => 'https://github.com/chocolateboy/Scope-Guard',
                bugtracker => 'https://github.com/chocolateboy/Scope-Guard/issues',
            },
        })
        : ()
    ),
);
