use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Nginx::Log::Statistics',
    AUTHOR           => q{David Farrell <davidnmfarrell@gmail.com>},
    VERSION_FROM     => 'lib/Nginx/Log/Statistics.pm',
    ABSTRACT_FROM    => 'lib/Nginx/Log/Statistics.pm',
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
        'Nginx::Log::Entry' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Nginx-Log-Statistics-*' },
);
