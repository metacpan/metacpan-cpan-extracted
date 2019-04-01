#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Task::Calendar',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Task/Calendar.pm',
    ABSTRACT_FROM      => 'lib/Task/Calendar.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Calendar::Bahai'     => '0.49',
        'Calendar::Gregorian' => '0.18',
        'Calendar::Hebrew'    => '0.08',
        'Calendar::Hijri'     => '0.36',
        'Calendar::Julian'    => '0.09',
        'Calendar::Persian'   => '0.38',
        'Calendar::Saka'      => '1.37',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Task-Calendar-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Task-Calendar.git',
                web  => 'https://github.com/manwar/Task-Calendar',
            },
        }})
     : ()
    ),
);
