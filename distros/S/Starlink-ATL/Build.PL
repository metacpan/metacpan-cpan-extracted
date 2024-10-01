#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name => 'Starlink::ATL',
    dist_abstract => 'Perl tools for Starlink\'s AST library',
    script_files => [qw{
        bin/astmoctool
    }],
    license => 'gpl3',
    requires => {
        'Starlink::AST' => 1.02,
        'Pod::Usage' => 0,
        'Astro::FITS::CFITSIO' => 0,
    },
    build_requires => {
        'Astro::Coords' => 0.18,
    },
    dist_author => [
        'Graham Bell <g.bell@jach.hawaii.edu>',
    ],
);

$build->create_build_script();
