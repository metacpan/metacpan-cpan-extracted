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
        'parent'                      => 0,
        'GPSD::Parse'               => 1.02,
        'JSON'                      => 0,
        'RPi::ADC::ADS'             => 1.02,
        'RPi::ADC::MCP3008'         => 2.3604,
        'RPi::Const'                => 1.02,
        'RPi::BMP180'               => 2.3604,
        'RPi::DAC::MCP4922'         => 2.3605,
        'RPi::DigiPot::MCP4XXXX'    => 2.3604,
        'RPi::DHT11'                => 1.03,
        'RPi::HCSR04'               => 2.3604,
        'RPi::I2C'                  => 2.3605,
        'RPi::LCD'                  => 2.3603,
        'RPi::Pin'                  => 2.3604,
        'RPi::Serial'               => 2.3603,
        'RPi::SPI'                  => 2.3608,
        'RPi::StepperMotor'         => 2.3604,
        'WiringPi::API'             => 2.3616,
    },
);
