
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

use Test::More;

eval 'use Test::Pod::Coverage 1.04; use Pod::Coverage::Moose;';
plan skip_all =>
    'Test::Pod::Coverage 1.04 and Pod::Coverage::Moose required for testing POD coverage'
    if $@;

my @mods = Test::Pod::Coverage::all_modules();

plan tests => scalar @mods;

for my $mod (@mods) {
    my @trustme = qr/^BUILD(?:ARGS)?$/;

    pod_coverage_ok(
        $mod, {
            coverage_class => 'Pod::Coverage::Moose',
            trustme        => \@trustme,
        },
        "pod coverage for $mod"
    );
}
