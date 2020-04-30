#!/usr/bin/perl

use 5.008004;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME             => 'Test::Class::Simple',
    VERSION_FROM     => 'lib/Test/Class/Simple.pm',
    ABSTRACT_FROM    => 'lib/Test/Class/Simple.pm',
    AUTHOR           => 'Oleksii Kysil',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.008004',
    PREREQ_PM        => {
        'strict'                    => 0,
        'warnings'                  => 0,
        'parent'                    => 0,
        'Carp'                      => 0,
        'Test::Class'               => '0.50',
        'Test::MockObject::Extends' => '1.20161202',
        'Test::MockModule'          => '0.13',
        'Test::Deep'                => '1.127',
    },
    META_ADD => {
        provides => Module::Metadata->provides(version => '1.4', dir => 'lib'),
    },
    (
        eval { ExtUtils::MakeMaker->VERSION(6.46) }
        ? (
            META_MERGE => {
                'meta-spec' => { version => 2 },
                resources   => {
                    repository => {
                        type => 'git',
                        url =>
                           'https://gitlab.com/oleksii.kysil/test-class-simple.git',
                        web =>
                          'https://gitlab.com/oleksii.kysil/test-class-simple',
                    },
                }
            }
          )
        : ()
    ),
);
