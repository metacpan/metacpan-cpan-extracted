use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Rex::Test::Spec',
    AUTHOR           => q{Rao Chenlin(chenryn) <rao.chenlin@gmail.com>},
    VERSION_FROM     => 'lib/Rex/Test/Spec.pm',
    ABSTRACT_FROM    => 'lib/Rex/Test/Spec.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'          => 0,
        'Test::Pod'           => 0,
        'Test::Pod::Coverage' => 0,
    },
    PREREQ_PM => {
        'Rex' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Rex-Test-Spec-*' },
);
