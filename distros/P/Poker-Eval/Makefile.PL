use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Poker::Eval',
    AUTHOR           => q{Nathaniel Graham <ngraham@cpan.org>},
    VERSION_FROM     => 'lib/Poker/Eval.pm',
    ABSTRACT_FROM    => 'lib/Poker/Eval.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Moo' => 0,
        'Tie::IxHash' => 0,
        'List::Util' => 0,
        'Storable' => 0,
        'Algorithm::Combinatorics' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Poker-Eval-*' },
);
