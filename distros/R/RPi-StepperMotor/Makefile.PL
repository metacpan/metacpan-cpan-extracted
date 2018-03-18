use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'RPi::StepperMotor',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/RPi/StepperMotor.pm',
    ABSTRACT_FROM    => 'lib/RPi/StepperMotor.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    EXE_FILES        => [qw(bin/stepper)],
    MIN_PERL_VERSION => '5.006',
    MIN_PERL_VERSION => 5.010,
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/rpi-steppermotor/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/rpi-steppermotor.git',
                web => 'https://github.com/stevieb9/rpi-steppermotor',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'RPi::Const'    => 0,
        'WiringPi::API' => 2.3614,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'RPi-StepperMotor-*' },
);
