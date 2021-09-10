#!/usr/bin/env perl

use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Passwd::Keyring::Secret',
    LICENSE            => 'artistic_2',

    MIN_PERL_VERSION   => '5.006',

    BUILD_REQUIRES => {
        'vars' => 0,
        'Module::Build' => '0.19',
        'Test::More' => '0.88',
        'File::Slurp' => 0,
    },

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.6303',
        'Pod::Readme' => '1.001002',
        'Pod::Markdown' => '2.000',
    },

    PREREQ_PM => {
        'strict' => 0,
        'warnings' => 0,
        'Carp' => 0,
        'Glib::Object::Introspection' => 0,
    },

    TEST_REQUIRES => {
        'Test::More' => '0.96',
    },

    INSTALLDIRS        => 'site',
    EXE_FILES          => [],
    PL_FILES           => {},

    AUTHOR             => 'Thomas Uhle <uhle@cpan.org>',
    ABSTRACT_FROM      => 'Secret.pm',
    DISTNAME           => 'Passwd-Keyring-Secret',
    VERSION_FROM       => 'Secret.pm',

    META_MERGE => {
        'meta-spec' => { version => 2 },
        keywords  => [ qw( passwords security secure-storage keyring secret seahorse gnome-keyring ) ],
        resources => {
            homepage   => 'https://search.cpan.org/~uhle/Passwd-Keyring-Secret/',
            repository => {
                type   => 'git',
                url    => 'https://gitlab.com/uhle/Passwd-Keyring-Secret.git',
                web    => 'https://gitlab.com/uhle/Passwd-Keyring-Secret',
            },
            bugtracker => {
                web    => 'https://gitlab.com/uhle/Passwd-Keyring-Secret/-/issues',
            },
            license    => 'https://www.perlfoundation.org/artistic-license-20.html',
        }
    }
);
