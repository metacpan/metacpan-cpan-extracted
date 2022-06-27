#!/bin/env perl

use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION( '0.4004' );

my $builder = Module::Build->new(
    module_name        => 'Pod::Query',
    license            => 'artistic_2',
    dist_author        => q{Tim Potapov <tim.potapov[AT]gmail.com>},
    dist_version_from  => 'lib/Pod/Query.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        'Pod::LOL'        => '0.08',
        'Mojolicious'     => '9.19',
        'Term::ReadKey'   => '2.38',
        'Role::Tiny'      => '2.000001',
        'Term::Size::Any' => '0.002',
    },
    add_to_cleanup => ['Pod-Query-*'],
);

$builder->create_build_script();
