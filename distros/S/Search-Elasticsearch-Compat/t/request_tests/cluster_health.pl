#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

isa_ok $r = $es->cluster_health(), 'HASH', 'Cluster health';

ok $es->cluster_health( wait_for_status => 'green' )->{timed_out} == 0,
    ' - wait_for_status';
ok $es->cluster_health( wait_for_relocating_shards => 1 )->{timed_out} == 0,
    ' - wait_for_relocating_shards';
ok $es->cluster_health( wait_for_nodes => '>1' )->{timed_out} == 0,
    ' - wait_for_nodes';

ok $es->cluster_health( wait_for_nodes => 1, timeout => '1ms' )->{timed_out},
    ' - timeout';

$r = $es->cluster_health( level => 'cluster' );
ok $r && !$r->{indices}, ' - level cluster';

$r = $es->cluster_health( level => 'indices' )->{indices};
ok $r && !$r->{shards}, ' - level indices';

$r = $es->cluster_health( level => 'shards' )->{indices};
ok $r->{es_test_1}{shards}, ' - level shards';

1;
