#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    configure_requires => {
        'Module::Build' => 0,
    },
    dist_author => 'Rob Hoelz <rob@hoelz.ro>',
    build_requires => {
        'Test::More'  => 0,
        'Plack::Test' => 0,
    },
    module_name    => 'Plack::Middleware::Options',
    license        => 'perl',
    requires       => {
        'Plack::Middleware' => 0,
    },
);
$build->create_build_script;
