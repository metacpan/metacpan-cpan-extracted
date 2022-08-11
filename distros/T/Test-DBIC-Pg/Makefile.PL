#! /usr/bin/perl -w
use v5.10.1;
use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Test::DBIC::Pg',
    VERSION_FROM  => 'lib/Test/DBIC/Pg.pm',
    ABSTRACT_FROM => 'lib/Test/DBIC/Pg.pm',
    AUTHOR        => 'Abe Timmerman <abeltje@cpan.org>',

    PREREQ_PM => {
        'Test::DBIC::SQLite' => '1.01',
        'DBD::Pg'            => '3.7.0',
    },
    BUILD_REQUIRES => {
        'Test::Simple'   => 0.88,
        'Test::Tester'   => 0,
        'Test::Warnings' => 0,
        'Test::Fatal'    => 0,
        'YAML'           => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.55_03',
    },

    MIN_PERL_VERSION => '5.010001',
    LICENSE  => 'perl_5',
    META_ADD => {
        'meta-spec' => {version => 2},
        'resources' => {
            homepage   => '',
            repository => {
                type => 'git',
                url  => 'https://github.com/abeltje/Test-DBIC-Pg.git',
            },
        },
        'x_IRC' => 'irc://irc.perl.org/#amsterdam.pm',
    },
);
