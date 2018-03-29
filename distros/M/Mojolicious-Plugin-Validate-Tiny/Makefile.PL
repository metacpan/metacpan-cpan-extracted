#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Mojolicious::Plugin::Validate::Tiny',
    VERSION_FROM => 'lib/Mojolicious/Plugin/Validate/Tiny.pm',
    AUTHOR       => 'Adrian Crisan <adrian.crisan88@gmail.com>',
    MIN_PERL_VERSION => 5.010,
    PREREQ_PM    => {
        'Mojolicious'    => 6.00,
        'Validate::Tiny' => 0.984
    },
    META_MERGE   => {
        resources => {
            repository  =>  'https://github.com/crlcu/Mojolicious-Plugin-Validate-Tiny',
        },
    },
    PREREQ_PRINT => 1,
    test => { TESTS => 't/*.t' },
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojolicious-Plugin-Validate-Tiny-*' },

);
