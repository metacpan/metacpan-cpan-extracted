use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Statistics::Reproducibility',
    AUTHOR           => q{Jimi Wills <jimi@webu.co.uk>},
    VERSION_FROM     => 'lib/Statistics/Reproducibility.pm',
    ABSTRACT_FROM    => 'lib/Statistics/Reproducibility.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Statistics::Distributions' => 1.02,
        'Statistics::QuickMedian' => 0.03,
        'Statistics::TheilSenEstimator' => 0.04,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Statistics-Reproducibility-*' },
);
