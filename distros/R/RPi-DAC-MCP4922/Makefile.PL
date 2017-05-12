use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'RPi::DAC::MCP4922',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/RPi/DAC/MCP4922.pm',
    ABSTRACT_FROM    => 'lib/RPi/DAC/MCP4922.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    LIBS             => ['-lwiringPi'],
    MIN_PERL_VERSION => 5.006,
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/rpi-dac-mcp4922/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/rpi-dac-mcp4922.git',
                web => 'https://github.com/stevieb9/rpi-dac-mcp4922',
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
        'RPi::WiringPi::Constant'   => 0.02,
        'WiringPi::API'             => 2.3608,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'RPi-DAC-MCP4922-*' },
);
