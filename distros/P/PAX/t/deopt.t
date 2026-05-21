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
use PAX::GuardManager;

my $fixture = "$FindBin::Bin/fixtures/mutation.pl";
my $capture = PAX::Capture->new(mode => 'live')->capture($fixture);
my $manifest = PAX::Manifest->new(capture => $capture)->to_hash;
my $regions = PAX::RegionSelector->new(manifest => $manifest)->select;
my $hir = PAX::HIR->new(manifest => $manifest, regions => $regions->{selected})->lower_all;
my $ssa = PAX::GuardedSSA->new(hir_units => $hir)->build_all;
my ($unit) = grep { $_->{region_name} eq 'main::add' } @$ssa;
ok($unit, 'selected add region for deopt test');

my $guard_manager = PAX::GuardManager->new(epochs => { %{ $manifest->{runtime_epochs} } });
ok($guard_manager->validate_region($unit), 'guard validates before mutation');

$guard_manager->invalidate_epoch('package_symbols');
my $deopt = $guard_manager->validate_or_deopt(
    $unit,
    interpreter_result => 5,
    args => [2, 3],
    context => 'scalar',
);

is($deopt->{status}, 'deopt', 'guard failure routes to deopt');
is($deopt->{fallback}{invalidation_key}, 'package_symbols', 'deopt records invalidation key');
is($deopt->{fallback}{interpreter_result}, 5, 'deopt carries interpreter fallback result');
like($deopt->{fallback}{continuation}, qr/region-\d+:entry/, 'deopt records continuation');
is($deopt->{fallback}{reconstructed_frame}{status}, 'reconstructed', 'deopt reconstructs interpreter frame payload');
is_deeply($deopt->{fallback}{reconstructed_frame}{frame}{argv}, [2, 3], 'deopt frame preserves arguments');

done_testing;

=pod

=head1 NAME

t/deopt.t - regression coverage for deoptimization planning and invalidation behavior

=head1 DESCRIPTION

This test exercises deoptimization planning and invalidation behavior. It exists so PAX changes can be checked against a
repeatable behavioral contract instead of informal manual runs.

=head1 TEST PLAN

The assertions in this file cover the specific success, failure, and edge-case
paths needed for deoptimization planning and invalidation behavior. Extend this file when behavior changes in that area.

=head1 HOW TO RUN

  prove -lv t/deopt.t

=head1 WHY IT EXISTS

PAX uses this test to keep deoptimization planning and invalidation behavior from regressing while the compiler,
standalone runtime, and packaging logic continue to evolve.

=cut
