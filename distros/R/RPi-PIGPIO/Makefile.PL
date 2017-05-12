use 5.008005;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'RPi::PIGPIO',
    VERSION_FROM => 'lib/RPi/PIGPIO.pm',
    PREREQ_PM    => {
        'Carp'               => 0,
        'Exporter'           => '5.57',
        'Test::More'         => 0,
        'Time::HiRes'        => 0,
        'Package::Constants' => 0,
        'Module::Find'       => 0,
    },
    MIN_PERL_VERSION => '5.10.0',
    ABSTRACT_FROM => 'lib/RPi/PIGPIO.pm',
    AUTHOR        => 'Horea Gligan',
    LIBS          => [],
    DEFINE        => '',
    INC           => '-I.',
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'RPi-PIGPIO-*' },
);
