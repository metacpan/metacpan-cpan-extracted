use strict;
use warnings;
use Test::More;
use File::Path qw(remove_tree);
use FindBin;
use lib "$FindBin::Bin/../lib";

use PAX::Capture;
use PAX::Manifest;
use PAX::RegionSelector;
use PAX::HIR;
use PAX::GuardedSSA;
use PAX::Tier1;
use PAX::ArtifactCache;
use PAX::Mode;

my $fixture = "$FindBin::Bin/fixtures/simple.pl";
my $cache_root = "$FindBin::Bin/tmp-cache";
remove_tree($cache_root) if -d $cache_root;

my $capture = PAX::Capture->new(mode => 'live')->capture($fixture);
my $manifest = PAX::Manifest->new(capture => $capture)->to_hash;
my $regions = PAX::RegionSelector->new(manifest => $manifest)->select;
my $hir = PAX::HIR->new(manifest => $manifest, regions => $regions->{selected})->lower_all;
my $ssa = PAX::GuardedSSA->new(hir_units => $hir)->build_all;
my $artifact = PAX::Tier1->new->compile($ssa->[0]);

my $cache = PAX::ArtifactCache->new(root => $cache_root);
my $written = $cache->write_artifact(manifest => $manifest, artifact => $artifact);
ok(-f $written->{path}, 'artifact written to cache');

my $stored = $cache->read_artifact($written->{path});
is($stored->{metadata}{artifact_id}, $written->{id}, 'stored artifact id matches');

my $validation = $cache->validate_metadata(
    manifest => $manifest,
    metadata => $stored->{metadata},
);
ok($validation->{valid}, 'artifact metadata validates against manifest');

is(PAX::Mode->policy('ci')->{undeclared_inputs}, 'fail', 'CI mode fails undeclared inputs');
is(PAX::Mode->policy('prod')->{telemetry}, 'low_overhead', 'prod mode uses low overhead telemetry');

remove_tree($cache_root) if -d $cache_root;
done_testing;

=pod

=head1 NAME

t/artifact_cache.t - regression coverage for artifact cache metadata reads, writes, and validation decisions

=head1 DESCRIPTION

This test exercises artifact cache metadata reads, writes, and validation decisions. It exists so PAX changes can be checked against a
repeatable behavioral contract instead of informal manual runs.

=head1 TEST PLAN

The assertions in this file cover the specific success, failure, and edge-case
paths needed for artifact cache metadata reads, writes, and validation decisions. Extend this file when behavior changes in that area.

=head1 HOW TO RUN

  prove -lv t/artifact_cache.t

=head1 WHY IT EXISTS

PAX uses this test to keep artifact cache metadata reads, writes, and validation decisions from regressing while the compiler,
standalone runtime, and packaging logic continue to evolve.

=cut
