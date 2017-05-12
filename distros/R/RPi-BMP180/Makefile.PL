use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'RPi::BMP180',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/RPi/BMP180.pm',
    ABSTRACT_FROM    => 'lib/RPi/BMP180.pm',
    LICENSE          => 'perl_5',
    LIBS             => ['-lwiringPi', '-lwiringPiDev'],
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'WiringPi::API'           => 2.3608,
        'RPi::WiringPi::Constant' => 0.02,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'RPi-BMP180-*' },
);
