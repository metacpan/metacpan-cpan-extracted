#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Task::Map::Tube::Bundle',
    AUTHOR             => q{Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Task/Map/Tube/Bundle.pm',
    ABSTRACT_FROM      => 'lib/Task/Map/Tube/Bundle.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Map::Tube::Athens'          => '0',
        'Map::Tube::Barcelona'       => '0',
        'Map::Tube::Beijing'         => '0',
        'Map::Tube::Berlin'          => '0',
        'Map::Tube::Bielefeld'       => '0',
        'Map::Tube::Bucharest'       => '0',
        'Map::Tube::Budapest'        => '0',
        'Map::Tube::Copenhagen'      => '0',
        'Map::Tube::Delhi'           => '0',
        'Map::Tube::Dnipropetrovsk'  => '0',
        'Map::Tube::Frankfurt'       => '0',
        'Map::Tube::Glasgow'         => '0',
        'Map::Tube::Hamburg'         => '0',
        'Map::Tube::Hongkong'        => '0',
        'Map::Tube::Kazan'           => '0',
        'Map::Tube::Kharkiv'         => '0',
        'Map::Tube::Kiev'            => '0',
        'Map::Tube::KoelnBonn'       => '0',
        'Map::Tube::Kolkatta'        => '0',
        'Map::Tube::KualaLumpur'     => '0',
        'Map::Tube::London'          => '0',
        'Map::Tube::Lyon'            => '0',
        'Map::Tube::Madrid'          => '0',
        'Map::Tube::Malaga'          => '0',
        'Map::Tube::Milan'           => '0',
        'Map::Tube::Minsk'           => '0',
        'Map::Tube::Moscow'          => '0',
        'Map::Tube::Nuremberg'       => '0',
        'Map::Tube::NYC'             => '0',
        'Map::Tube::Nanjing'         => '0',
        'Map::Tube::NizhnyNovgorod'  => '0',
        'Map::Tube::Novosibirsk'     => '0',
        'Map::Tube::Prague'          => '0',
        'Map::Tube::Rome'            => '0',
        'Map::Tube::SaintPetersburg' => '0',
        'Map::Tube::Samara'          => '0',
        'Map::Tube::Singapore'       => '0',
        'Map::Tube::Sofia'           => '0',
        'Map::Tube::Tbilisi'         => '0',
        'Map::Tube::Toulouse'        => '0',
        'Map::Tube::Tokyo'           => '0',
        'Map::Tube::Vienna'          => '0',
        'Map::Tube::Warsaw'          => '0',
        'Map::Tube::Yekaterinburg'   => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Task-Map-Tube-Bundle-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Task-Map-Tube-Bundle.git',
                web  => 'https://github.com/manwar/Task-Map-Tube-Bundle',
            },
        }})
     : ()
    ),
);
