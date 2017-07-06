use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'RPi::DigiPot::MCP4XXXX',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/RPi/DigiPot/MCP4XXXX.pm',
    ABSTRACT_FROM    => 'lib/RPi/DigiPot/MCP4XXXX.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    LIBS             => ['-lwiringPi'],
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => 5.006,
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/rpi-digipot-mcp4xxxx/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/rpi-digipot-mcp4xxxx.git',
                web => 'https://github.com/stevieb9/rpi-digipot-mcp4xxxx',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.72,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    TEST_REQUIRES => {
        'Mock::Sub' => 1.07,
    },
    PREREQ_PM => {
        'WiringPi::API'             => 2.3612,
        'RPi::WiringPi::Constant'   => '1.00',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'RPi-DigiPot-MCP4XXXX-*' },
);
