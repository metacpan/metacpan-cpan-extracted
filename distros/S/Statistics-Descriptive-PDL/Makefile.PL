use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Statistics::Descriptive::PDL',
    AUTHOR           => q{Shawn Laffan <shawnlaffan@gmail.com>},
    VERSION_FROM     => 'lib/Statistics/Descriptive/PDL.pm',
    ABSTRACT_FROM    => 'lib/Statistics/Descriptive/PDL.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Statistics::Descriptive' => "3.06",
        'rlib' => "0",
        'Scalar::Util' => "0",
        "Devel::Symdump" => "0",
    },
    PREREQ_PM => {
        #  PDL:: versions should be able to go lower, but need to start somewhere
        "PDL"        => "2.012",
        "PDL::Stats" => "0.7",  #  0.6.5 had install issues
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Statistics-Descriptive-PDL-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/shawnlaffan/Statistics-Descriptive-PDL',
            },
            bugtracker => {
                web => 'https://github.com/shawnlaffan/Statistics-Descriptive-PDL/issues/',
            },
        },
    },
);
