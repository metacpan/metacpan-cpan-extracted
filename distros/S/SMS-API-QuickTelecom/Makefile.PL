use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'SMS::API::QuickTelecom',
    AUTHOR           => q{Pasichnichenko Konstantin <pasichnichenko.k@gmail.com>},
    VERSION_FROM     => 'lib/SMS/API/QuickTelecom.pm',
    ABSTRACT_FROM    => 'lib/SMS/API/QuickTelecom.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Pod' => 0,
        'Test::CheckManifest' => 0,
    },
    PREREQ_PM => {
        'Carp'                   => 0,
        'LWP::Protocol::https'   => 0,
        'LWP::UserAgent'         => 0,
        'POSIX'                  => 0,
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'SMS-API-QuickTelecom-*' },
);
