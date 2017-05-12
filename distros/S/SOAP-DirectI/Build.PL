#!/usr/bin/perl -w

use strict;
use Module::Build;

my $build = Module::Build->new(
    license             => 'perl',
    module_name         => 'SOAP::DirectI',
    requires            => {
        'perl'              => 5.006,
        'Smart::Comments'   => 0,
    },
    build_requires      => {
        'Test::More'        => 0,
    },
    create_makefile_pl  => 'traditional',
    dist_abstract       => 'SOAP::DirectI -- extra-lite SOAP module for DirectI-like webservices',
);

$build->create_build_script;
