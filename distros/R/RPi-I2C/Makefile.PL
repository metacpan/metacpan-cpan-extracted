use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'RPi::I2C',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/RPi/I2C.pm',
    ABSTRACT_FROM    => 'lib/RPi/I2C.pm',
    LICENSE          => 'GPL_2',
    PL_FILES         => {},
    INC              => "-I.",
    MIN_PERL_VERSION => 5.006,
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/rpi-i2c/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/rpi-i2c.git',
                web => 'https://github.com/stevieb9/rpi-i2c',
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
    clean => { FILES => 'RPi-I2C-*' },
);
