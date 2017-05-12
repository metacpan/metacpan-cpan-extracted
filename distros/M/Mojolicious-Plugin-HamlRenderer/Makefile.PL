#!/usr/bin/env perl

use 5.008001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my $mm = $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME         => 'Mojolicious::Plugin::HamlRenderer',

    # NOTE: Please update the $VERSION in both modules!
    VERSION_FROM => 'lib/Mojolicious/Plugin/HamlRenderer.pm',

    ABSTRACT     => 'Haml renderer for Mojolicious',
    AUTHOR       => 'Viacheslav Tykhanovskyi <vti@cpan.org>',

    ($mm < 6.3002 ? () : ('LICENSE' => 'artistic_2')),

    (   $mm < 6.46
        ? ()
        : ( META_MERGE => {
                requires  => {perl => '5.008001'},
                resources => {
                    license => 'http://dev.perl.org/licenses/',
                    repository =>
                      'http://github.com/vti/mojox-renderer-haml/tree/master'
                },
                no_index => {directory => [qw/t/]}
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {}
            },
        )
    ),

    PREREQ_PM => {
        'Text::Haml'  => '0.990103',
        'Mojolicious' => '1.3'
    },

    test => {TESTS => 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t'}
);
