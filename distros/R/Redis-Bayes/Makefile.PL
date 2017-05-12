use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Redis::Bayes',
    AUTHOR           => q{Andrew Shapiro <trski@cpan.org>},
    VERSION_FROM     => 'lib/Redis/Bayes.pm',
    ABSTRACT_FROM    => 'lib/Redis/Bayes.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Redis' => 1.961,
        'Lingua::StopWords' => 0.09,
        'Moo' => 1.000002,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Redis-Bayes-*' },
);
