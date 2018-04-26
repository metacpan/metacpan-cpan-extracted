use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Oracle::ZFSSA::Client',
    AUTHOR           => q{Wesley Hinds <wesley.hinds@gmail.com>},
    VERSION_FROM     => 'lib/Oracle/ZFSSA/Client.pm',
    ABSTRACT_FROM    => 'lib/Oracle/ZFSSA/Client.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'LWP::UserAgent' => 6.05,
        'JSON' => 2.90,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Oracle-*' },
);
