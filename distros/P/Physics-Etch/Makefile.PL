use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Physics::Etch',
    ABSTRACT_FROM    => 'lib/Physics/Etch.pm',
    VERSION_FROM     => 'lib/Physics/Etch.pm',
    AUTHOR           => 'Jovan Trujillo <jtrujil43@users.noreply.github.com>',
    LICENSE          => 'gpl_3',
    MIN_PERL_VERSION => '5.010001',

    PREREQ_PM => {
        'Carp'            => 0,
        'FindBin'         => 0,
        'Test::More'      => 0,
        'parent'          => 0,
        'strict'          => 0,
        'warnings'        => 0,
        'ExtUtils::MakeMaker' => 0,
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/jtrujil43/Physics-Etch.git',
                web  => 'https://github.com/jtrujil43/Physics-Etch',
            },
            bugtracker => {
                web => 'https://github.com/jtrujil43/Physics-Etch/issues',
            },
        },
    },

    test => { TESTS => 't/*.t' },
);
