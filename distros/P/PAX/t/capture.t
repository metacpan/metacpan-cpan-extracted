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
use PAX::Runtime::Value;
use PAX::Tier1;
use PAX::NativeRunner;

my $fixture = "$FindBin::Bin/fixtures/simple.pl";
my $capture = PAX::Capture->new(mode => 'live')->capture($fixture);

is($capture->{status}, 'ok', 'capture succeeds');
is($capture->{mode}, 'live', 'capture mode recorded');
ok($capture->{runtime}{perl_version}, 'runtime version captured');
ok(@{ $capture->{capture}{sub_optrees} } >= 1, 'sub optree summaries captured');

my $manifest = PAX::Manifest->new(capture => $capture)->to_hash;
is($manifest->{schema_version}, 1, 'manifest schema version recorded');
is($manifest->{runtime}{perl_family_target}, '5.42.x', 'target baseline recorded');
ok($manifest->{runtime}{pax_abi_stamp}, 'ABI stamp recorded');
ok($manifest->{compatibility}{level}, 'compatibility level recorded');

my $regions = PAX::RegionSelector->new(manifest => $manifest)->select;
ok(@{ $regions->{selected} } >= 1, 'candidate region selected');
ok($regions->{selected}[0]{id}, 'candidate region has id');

my $hir = PAX::HIR->new(
    manifest => $manifest,
    regions => $regions->{selected},
)->lower_all;
ok(@$hir >= 1, 'HIR units produced');
ok($hir->[0]{graph}{blocks}[0]{ops}[0]{op}, 'HIR unit has operations');

my $ssa = PAX::GuardedSSA->new(hir_units => $hir)->build_all;
ok(@$ssa >= 1, 'SSA units produced');
ok(exists $ssa->[0]{deopt}, 'SSA unit has deopt metadata');

my $guard_manager = PAX::GuardManager->new(epochs => $manifest->{runtime_epochs});
ok($guard_manager->validate_region($ssa->[0]), 'guard manager validates known epochs');
ok(@{ $guard_manager->telemetry } >= 1, 'guard telemetry recorded');

$guard_manager->invalidate_epoch('package_symbols');
my $deopt = $guard_manager->validate_or_deopt($ssa->[0], interpreter_result => undef);
is($deopt->{status}, 'deopt', 'guard manager can produce deopt decision');

my $fast = PAX::Runtime::Value->fast_int(42);
is($fast->materialise->as_hash->{kind}, 'PerlValue', 'FastValue materialises to PerlValue');

my $artifact = PAX::Tier1->new->compile($ssa->[0]);
ok($artifact->{status}, 'Tier 1 compiler returns artifact status');
if ($artifact->{status} eq 'native_artifact') {
    ok(-f $artifact->{library_path}, 'native artifact library exists when toolchain is available');
    if ($artifact->{native_test}) {
        ok($artifact->{native_test}{passed}, 'native artifact smoke test passes when semantic emitter matches');
        my $run = PAX::NativeRunner->new->run_i64_binary(
            path => $artifact->{executable_path},
            left => 10,
            right => 32,
        );
        is($run->{value}, 42, 'native runner calls emitted i64 artifact');
    }
}

done_testing;

=pod

=head1 NAME

t/capture.t - regression coverage for capture engine behavior across supported execution modes

=head1 DESCRIPTION

This test exercises capture engine behavior across supported execution modes. It exists so PAX changes can be checked against a
repeatable behavioral contract instead of informal manual runs.

=head1 TEST PLAN

The assertions in this file cover the specific success, failure, and edge-case
paths needed for capture engine behavior across supported execution modes. Extend this file when behavior changes in that area.

=head1 HOW TO RUN

  prove -lv t/capture.t

=head1 WHY IT EXISTS

PAX uses this test to keep capture engine behavior across supported execution modes from regressing while the compiler,
standalone runtime, and packaging logic continue to evolve.

=cut
