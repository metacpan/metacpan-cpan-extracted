#!/bin/env perl

use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION( '0.4004' );

sub readme {
    print "Building README\n";
    system "pod2markdown lib/Pod/LOL.pm > README.md";
}
readme();

my $builder = Module::Build->new(
    module_name        => 'Pod::LOL',
    license            => 'artistic_2',
    dist_author        => q{Tim Potapov <tim.potapov[AT]gmail.com>},
    dist_version_from  => 'lib/Pod/LOL.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        'perl' => '5.012',
    },
    add_to_cleanup => ['Pod-LOL-*'],
    meta_merge     => {
        resources => {
            bugtracker => 'https://github.com/poti1/pod-lol/issues',
            repository => 'https://github.com/poti1/pod-lol',
        },
    },
);

$builder->create_build_script();
