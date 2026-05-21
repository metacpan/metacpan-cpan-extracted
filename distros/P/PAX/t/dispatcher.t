use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use PAX::RuntimeDispatcher;

my $fixture = "$FindBin::Bin/fixtures/simple.pl";
my $result = PAX::RuntimeDispatcher->new->dispatch_i64(
    entrypoint => $fixture,
    left => 10,
    right => 32,
);

ok($result->{status}, 'dispatcher returns status');
if ($result->{status} eq 'native') {
    is($result->{result}{value}, 42, 'dispatcher native result');
} else {
    is($result->{status}, 'fallback', 'dispatcher falls back when native unavailable');
    ok($result->{reason} || @{ $result->{attempts} }, 'dispatcher reports fallback reason or attempts');
}

my $multi = "$FindBin::Bin/fixtures/native_leafs.pl";
my $selected = PAX::RuntimeDispatcher->new->dispatch_i64(
    entrypoint => $multi,
    region_name => 'multiply',
    left => 6,
    right => 7,
);
if ($selected->{status} eq 'native') {
    is($selected->{region_name}, 'main::multiply', 'dispatcher selects requested region');
    is($selected->{result}{value}, 42, 'dispatcher executes selected region');
} else {
    is($selected->{status}, 'fallback', 'selected region falls back when native unavailable');
}

my $missing = PAX::RuntimeDispatcher->new->dispatch_i64(
    entrypoint => $multi,
    region_name => 'missing_region',
    left => 1,
    right => 2,
);
is($missing->{status}, 'fallback', 'missing region falls back');
like($missing->{reason}, qr/requested region not found/, 'missing region reason reported');

done_testing;

=pod

=head1 NAME

t/dispatcher.t - regression coverage for runtime dispatch behavior between native and fallback paths

=head1 DESCRIPTION

This test exercises runtime dispatch behavior between native and fallback paths. It exists so PAX changes can be checked against a
repeatable behavioral contract instead of informal manual runs.

=head1 TEST PLAN

The assertions in this file cover the specific success, failure, and edge-case
paths needed for runtime dispatch behavior between native and fallback paths. Extend this file when behavior changes in that area.

=head1 HOW TO RUN

  prove -lv t/dispatcher.t

=head1 WHY IT EXISTS

PAX uses this test to keep runtime dispatch behavior between native and fallback paths from regressing while the compiler,
standalone runtime, and packaging logic continue to evolve.

=cut
