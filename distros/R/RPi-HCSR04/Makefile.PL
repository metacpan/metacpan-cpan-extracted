use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'RPi::HCSR04',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/RPi/HCSR04.pm',
    ABSTRACT_FROM    => 'lib/RPi/HCSR04.pm',
    LICENSE          => 'perl_5',
    LIBS             => ['-lwiringPi -lrt'],
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/rpi-hcsr04/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/rpi-hcsr04.git',
                web => 'https://github.com/stevieb9/rpi-hcsr04',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'RPi-HCSR04-*' },
);
