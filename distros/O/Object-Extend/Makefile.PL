use 5.008;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval($ExtUtils::MakeMaker::VERSION);

WriteMakefile(
    NAME           => 'Object::Extend',
    VERSION_FROM   => 'lib/Object/Extend.pm',
    PREREQ_PM      => {
        'Scalar::Util' => '1.09', # refaddr (used in t/recycled.t)
        'Storable'     => '2.05', # coderef deparsing
    },
    ABSTRACT_FROM  => 'lib/Object/Extend.pm',
    AUTHOR         => 'chocolateboy <chocolate@cpan.org>',
    ($EUMM_VERSION >= 6.48 ? (MIN_PERL_VERSION => '5.8.0') : ()),
    ($EUMM_VERSION >= 6.31 ? (LICENSE => 'perl') : ()),
    ($EUMM_VERSION >= 6.46 ?
        (META_MERGE => {
            test_requires => {
                'Test::More' => 0,
            },
            resources => {
                repository => 'https://github.com/chocolateboy/Object-Extend',
                bugtracker => 'https://github.com/chocolateboy/Object-Extend/issues',
            },
        }) : ()
    ),
);
