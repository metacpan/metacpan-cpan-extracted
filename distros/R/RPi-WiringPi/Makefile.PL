use strict;
use warnings;
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
    EXE_FILES         => [ map "bin/$_", qw(
            pinmap 
            pidentify
            pimeta
            pimetaerase
        )
    ],
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
    MIN_PERL_VERSION   => 5.010,
    LICENSE => 'perl_5',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'   => 6.72,
    },
    PREREQ_PM         => {
        'parent'                    => 0,
        'File::Touch'               => 0,
        'GPSD::Parse'               => 1.03,
        'IPC::Shareable'            => 1.17,
        'JSON::XS'                  => 0,
        'String::CRC32'             => 0,
        'RPi::ADC::ADS'             => 1.02,
        'RPi::ADC::MCP3008'         => 3.1801,
        'RPi::Const'                => 1.04,
        'RPi::BMP180'               => 3.1801,
        'RPi::DAC::MCP4922'         => 3.1801,
        'RPi::DigiPot::MCP4XXXX'    => 3.1801,
        'RPi::DHT11'                => 1.05,
        'RPi::EEPROM::AT24C32'      => 0.01,
        'RPi::GPIOExpander::MCP23017' => 1.03,
        'RPi::HCSR04'               => 3.1801,
        'RPi::I2C'                  => 3.1801,
        'RPi::LCD'                  => 3.1801,
        'RPi::OLED::SSD1306::128_64'=> 3.1801,
        'RPi::Pin'                  => 3.1801,
        'RPi::RTC::DS3231'          => 0.01,
        'RPi::Serial'               => 3.02,
        'RPi::SPI'                  => 3.1801,
        'RPi::StepperMotor'         => 3.1801,
        'RPi::SysInfo'              => 1.02,
        'WiringPi::API'             => 3.1803,
    },
);

# Regenerate derived docs before packaging so every distribution ships current
# copies: POD -> markdown (docs/pod/*.md, README.md) and the test-platform
# pinout/schematic artifacts. Hooked as a prerequisite of create_distdir so the
# freshly generated files are in place before manicopy assembles the tarball.

sub MY::postamble {
    return <<"MAKE_FRAG";
regen_docs :
\t\$(NOECHO) \$(ECHO) "Regenerating derived docs before packaging"
\t\$(PERLRUN) scripts/gen-pod-md.pl
\t\$(PERLRUN) scripts/gen-test-platform.pl

create_distdir : regen_docs
MAKE_FRAG
}
