#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Term::Screen::Lite',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Term/Screen/Lite.pm',
    ABSTRACT_FROM      => 'lib/Term/Screen/Lite.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moo'              => '2.000000',
        'namespace::clean' => '0.24',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Term-Screen-Lite-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Term::Screen::Lite'          => { file => 'lib/Term/Screen/Lite.pm'         , version => '0.06' },
            'Term::Screen::Lite::Generic' => { file => 'lib/Term/Screen/Lite/Generic.pm' , version => '0.06' },
            'Term::Screen::Lite::Win32'   => { file => 'lib/Term/Screen/Lite/Win32.pm'   , version => '0.06' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/Manwar/Term-Screen-Lite.git',
                web  => 'https://github.com/Manwar/Term-Screen-Lite',
            },
        }})
     : ()
    ),
);
