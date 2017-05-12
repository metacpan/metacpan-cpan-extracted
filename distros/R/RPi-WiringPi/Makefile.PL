use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'RPi::WiringPi',
    VERSION_FROM      => 'lib/RPi/WiringPi.pm',
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/RPi/WiringPi.pm',
       AUTHOR         => 'Steve Bertrand <steveb@cpan.org>') : ()),
    LIBS              => [],
    DEFINE            => '',
    INC               => '-I.',
    EXE_FILES         => [ map "bin/$_", qw(pinmap) ],
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/rpi-wiringpi/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/rpi-wiringpi.git',
                web => 'https://github.com/stevieb9/rpi-wiringpi',
            },
        },
    },
    MIN_PERL_VERSION   => 5.006,
    LICENSE => 'perl_5',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.72,
    },
    PREREQ_PM         => {
        parent                      => 0,
        'RPi::ADC::ADS'             => 1.01,
        'RPi::ADC::MCP3008'         => 2.3603,
        'RPi::BMP180'               => 2.3603,
        'RPi::DAC::MCP4922'         => 2.3604,
        'RPi::DigiPot::MCP4XXXX'    => 2.3603,
        'RPi::DHT11'                => 1.02,
        'RPi::LCD'                  => 2.3601,
        'RPi::SPI'                  => 2.3606,
        'RPi::WiringPi::Constant'   => 0.02,
        'WiringPi::API'             => 2.3609,
    },
);
