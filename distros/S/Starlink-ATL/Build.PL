#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $build = new Module::Build(
    module_name   => 'Starlink::ATL',
    dist_abstract => 'Perl tools for Starlink\'s AST library',
    dist_version  => 0.04,
    license       => 'gpl3',
    requires      => {
                      'Starlink::AST' => 1.02,
                     },
    build_requires => {
                       'Astro::Coords' => 0.18,
                      },
    dist_author   => [
                      'Graham Bell <g.bell@jach.hawaii.edu>',
                     ],
);

$build->create_build_script();
