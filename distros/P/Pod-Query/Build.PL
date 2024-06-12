#!/bin/env perl

use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION( '0.4004' );

sub readme {
    print "Building README\n";
    system "pod2markdown lib/Pod/Query.pm > README.md";
}
readme();

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
        'perl'            => '5.018',
        'Pod::LOL'        => '0.08',
        'Term::Size::Any' => '0.002',
        'Role::Tiny'      => '2.002004',
    },
    add_to_cleanup => ['Pod-Query-*'],
    meta_merge     => {
        resources => {
            bugtracker => 'https://github.com/poti1/pod-query/issues',
            repository => 'https://github.com/poti1/pod-query',
        },
    },
);

$builder->create_build_script();
