#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    'NAME'         => 'Template::Plugin::JSON',
    'VERSION_FROM' => 'lib/Template/Plugin/JSON.pm',
    'PREREQ_PM' => {
        'Moose'             => '0',
        'Template'          => '2.20',
        'JSON'              => '2.12',
        'Carp'              => 0,
    },

    'CONFIGURE_REQUIRES' => {
        'ExtUtils::MakeMaker' => '6.64',
    },

    'TEST_REQUIRES' => {
        'Test::More'    => '0',
    },

    'LICENSE' => 'MIT',
    'MIN_PERL_VERSION' => '5.006',

    'META_MERGE' => {
        'meta-spec' => { version => 2 },
        resources => {
            repository  => {
                type => 'git',
                web  => 'https://github.com/neilb/Template-Plugin-JSON',
                url  => 'https://github.com/neilb/Template-Plugin-JSON.git',
            },
        },
    },

    'INSTALLDIRS' => 'site',
    'EXE_FILES'   => [],
    'PL_FILES'    => {}
);

unless ( eval { require JSON::XS } ) {
warn <<WARN
JSON::XS is reccomended, you should probably install it for better performance.
WARN
}
