#!/bin/env perl

use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION( '0.4004' );

sub readme {
    print "Building README\n";
    system "pod2markdown lib/Subs/Trace.pm > README.md";
}
readme();

my $builder = Module::Build->new(
    module_name        => 'Subs::Trace',
    license            => 'artistic_2',
    dist_author        => q{Tim Potapov <tim.potapov@gmail.com>},
    dist_version_from  => 'lib/Subs/Trace.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        'perl' => '5.006',
    },
    add_to_cleanup => ['Subs-Trace-*'],
    meta_merge     => {
        resources => {
            bugtracker => 'https://github.com/poti1/subs-trace/issues',
            repository => 'https://github.com/poti1/subs-trace',
        },
    },
);

$builder->create_build_script();
