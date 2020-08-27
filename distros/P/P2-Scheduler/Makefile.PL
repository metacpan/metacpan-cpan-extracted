use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'P2::Scheduler',
    AUTHOR           => q{Marco Masetti <marco.masetti@sky.uk>},
    VERSION_FROM     => 'lib/P2/Scheduler.pm',
    ABSTRACT_FROM    => 'lib/P2/Scheduler.pm',
    LICENSE          => 'BSD',
    EXE_FILES        => ['scripts/p2-scheduler.pl'],
    MIN_PERL_VERSION => 'v5.18',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Data::Printer' => 0,
        'Date::Calc'    => 0,
        'Getopt::Long'  => 0,
        'Moose'         => 0,
        'POSIX'         => 0,
        'YAML::Syck'    => 0,
        'UUID'          => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'P2-Scheduler-*' },
);
