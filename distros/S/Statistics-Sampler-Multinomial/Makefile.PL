use strict;
use warnings;
use ExtUtils::MakeMaker 6.48;

WriteMakefile(
    NAME                => 'Statistics::Sampler::Multinomial',
    AUTHOR              => 'Shawn Laffan <shawnlaffan@gmail.com>',
    VERSION_FROM        => 'lib/Statistics/Sampler/Multinomial.pm',
    ABSTRACT_FROM       => 'lib/Statistics/Sampler/Multinomial.pm',
    MIN_PERL_VERSION    => '5.014',
    LICENSE             => 'perl_5',
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp'         => 0,
        'parent'       => 0,
        'Ref::Util'    => 0,
        'List::Util'   => 0,
        'Scalar::Util' => 0,
        'List::MoreUtils' => 0,
        'Math::Random::MT::Auto' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'Test::Most' => 0,
        'rlib'       => 0,
        'Devel::Symdump' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/shawnlaffan/perl-statistics-sampler-multinomial.git',
                web  => 'https://github.com/shawnlaffan/perl-statistics-sampler-multinomial',
            },
            bugtracker => {
                web => 'https://github.com/shawnlaffan/perl-statistics-sampler-multinomial/issues/',
            },
        },
    },
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean  => { FILES => 'Statistics-Sampler-Multinomial-*' },
);
