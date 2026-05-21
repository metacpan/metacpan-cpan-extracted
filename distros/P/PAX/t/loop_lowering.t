use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use PAX::Capture;
use PAX::Manifest;
use PAX::RegionSelector;
use PAX::HIR;
use PAX::GuardedSSA;
use PAX::Tier1;
use PAX::NativeRunner;
use PAX::RuntimeDispatcher;

sub ssa_for_fixture {
    my ($fixture) = @_;
    my $capture = PAX::Capture->new(mode => 'live')->capture($fixture);
    my $manifest = PAX::Manifest->new(capture => $capture)->to_hash;
    my $regions = PAX::RegionSelector->new(manifest => $manifest)->select;
    my $hir = PAX::HIR->new(manifest => $manifest, regions => $regions->{selected})->lower_all;
    return PAX::GuardedSSA->new(hir_units => $hir)->build_all;
}

my $loop_fixture = "$FindBin::Bin/fixtures/loop_sum.pl";
my ($sum_unit) = grep { ($_->{region_name} // '') eq 'main::sum_to_n' } @{ ssa_for_fixture($loop_fixture) };
ok($sum_unit, 'sum_to_n region selected');
is(($sum_unit->{native_shape}{kind} // ''), 'i64_sum_loop', 'sum_to_n HIR native shape carried into SSA')
    if ($sum_unit->{status} // '') eq 'ssa';

my $artifact = PAX::Tier1->new->compile($sum_unit);
ok($artifact->{status}, 'sum_to_n artifact returns status');
if ($artifact->{status} eq 'native_artifact') {
    is($artifact->{entry_kind}, 'native_i64_loop', 'sum_to_n emits native loop artifact');
    my $run = PAX::NativeRunner->new->run_i64_binary(
        path => $artifact->{executable_path},
        left => 10,
        right => 0,
    );
    is($run->{value}, 55, 'sum_to_n native result matches reference');
}

my $dispatch = PAX::RuntimeDispatcher->new->dispatch_i64(
    entrypoint => $loop_fixture,
    region_name => 'sum_to_n',
    left => 10,
    right => 0,
);
if ($dispatch->{status} eq 'native') {
    is($dispatch->{result}{value}, 55, 'dispatcher executes native loop result');
} else {
    is($dispatch->{status}, 'fallback', 'dispatcher falls back when native unavailable');
}

my $unsupported_fixture = "$FindBin::Bin/fixtures/unsupported_loop.pl";
my ($unsupported_unit) = grep { ($_->{region_name} // '') eq 'main::sum_even_to_n' } @{ ssa_for_fixture($unsupported_fixture) };
ok($unsupported_unit, 'unsupported loop region selected');
ok(!defined $unsupported_unit->{native_shape}, 'unsupported loop has no native HIR shape');

my $unsupported = PAX::Tier1->new->compile($unsupported_unit);
isnt(($unsupported->{entry_kind} // ''), 'native_i64_loop', 'unsupported loop does not use loop emitter');

my $unsupported_dispatch = PAX::RuntimeDispatcher->new->dispatch_i64(
    entrypoint => $unsupported_fixture,
    region_name => 'sum_even_to_n',
    left => 10,
    right => 0,
);
is($unsupported_dispatch->{status}, 'fallback', 'unsupported loop falls back at dispatch');

done_testing;

=pod

=head1 NAME

t/loop_lowering.t - regression coverage for loop lowering and guard-aware SSA behavior

=head1 DESCRIPTION

This test exercises loop lowering and guard-aware SSA behavior. It exists so PAX changes can be checked against a
repeatable behavioral contract instead of informal manual runs.

=head1 TEST PLAN

The assertions in this file cover the specific success, failure, and edge-case
paths needed for loop lowering and guard-aware SSA behavior. Extend this file when behavior changes in that area.

=head1 HOW TO RUN

  prove -lv t/loop_lowering.t

=head1 WHY IT EXISTS

PAX uses this test to keep loop lowering and guard-aware SSA behavior from regressing while the compiler,
standalone runtime, and packaging logic continue to evolve.

=cut
