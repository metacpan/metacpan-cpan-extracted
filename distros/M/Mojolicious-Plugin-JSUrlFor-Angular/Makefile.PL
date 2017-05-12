#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Mojolicious::Plugin::JSUrlFor::Angular',
    VERSION_FROM  => 'lib/Mojolicious/Plugin/JSUrlFor/Angular.pm',
    ABSTRACT_FROM => 'lib/Mojolicious/Plugin/JSUrlFor/Angular.pm',
    AUTHOR        => 'Viktor Turskyi <koorchik@cpan.org>',
    PREREQ_PM     => { 'Mojolicious' => '7.00' },
    META_MERGE    => {
        resources => {
            repository => 'https://github.com/mche/Mojolicious-Plugin-JSUrlFor-Angular',
        },
    },
    test      => { TESTS => 't/*.t' },
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    #~ clean => { FILES => 'Mojolicious-Plugin-JSUrlFor-*' },
);
