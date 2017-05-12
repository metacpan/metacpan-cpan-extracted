use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'RPi::LCD',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/RPi/LCD.pm',
    ABSTRACT_FROM    => 'lib/RPi/LCD.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/rpi-lcd/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/rpi-lcd.git',
                web => 'https://github.com/stevieb9/rpi-lcd',
            },
        },
    },

    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.72,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'WiringPi::API' => 2.3609,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'RPi-LCD-*' },
);
