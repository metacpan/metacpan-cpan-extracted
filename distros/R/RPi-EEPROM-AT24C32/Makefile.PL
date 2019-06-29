use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'RPi::EEPROM::AT24C32',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/RPi/EEPROM/AT24C32.pm',
    ABSTRACT_FROM    => 'lib/RPi/EEPROM/AT24C32.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.010',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/rpi-eeprom-at24c32/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/rpi-eeprom-at24c32.git',
                web => 'https://github.com/stevieb9/rpi-eeprom-at24c32',
            },
        },
    },
    MIN_PERL_VERSION   => 5.010,

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'RPi-EEPROM-AT24C32-*' },
);
