use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker;
WriteMakefile
(
    NAME             => 'MySQL::Hi',
    VERSION_FROM     => 'lib/MySQL/Hi.pm',
    ABSTRACT_FROM    => 'lib/MySQL/Hi.pm',
    AUTHOR           => 'Andrei Pratasavitski <andrei.protasovitski@gmail.com>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010000',
    EXE_FILES        => [
        'bin/mysqlhi',
        'bin/myhi',
    ],
    PREREQ_PM        => {
        'strict'         => 0,
        'warnings'       => 0,
        'Carp'           => '1.0',
        'Config::Simple' => '4.0',
        'File::HomeDir'  => '1.0',
        'Getopt::Long'   => '2.0',
        'Test::More'     => 0,
        'Test::Deep'     => 0,
        'Test::Warn'     => 0,

    },
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://gitlab.com/as_pushkin/mysqlhi.git',
                web  => 'https://gitlab.com/as_pushkin/mysqlhi',
            },
        },
    },
    dist => {
        DIST_CP          => 'ln',
    },
);

1;
