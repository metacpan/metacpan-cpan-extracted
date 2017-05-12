#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Mojolicious::Plugin::ValidateTiny',
    VERSION_FROM => 'lib/Mojolicious/Plugin/ValidateTiny.pm',
    AUTHOR       => 'Viktor Turskyi <koorchik@cpan.org>',
    MIN_PERL_VERSION => 5.010,
    PREREQ_PM    => {
        'Mojolicious'    => 6.00,
        'Validate::Tiny' => 0.984
    },
    META_MERGE   => {
        resources => {
            repository  =>  'https://github.com/koorchik/Mojolicious-Plugin-ValidateTiny',
        },
    },
    PREREQ_PRINT => 1,
    test => { TESTS => 't/*.t' },
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojolicious-Plugin-ValidateTiny-*' },

);
