#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

isa_ok $r = $es->cluster_state, 'HASH', 'Cluster state';
isa_ok $r->{allocations}, 'ARRAY', ' - allocations';

is $r->{cluster_name}, 'es_test', ' - cluster name';
ok $r->{master_node} && !ref $r->{master_node}, ' - master node';

for (qw(blocks routing_table routing_nodes nodes metadata)) {
    isa_ok $r->{$_}, 'HASH', " - $_";
}

ok 2 == keys %{ $r->{metadata}{indices} }, ' - metadata has 2 indices';
ok 1 == keys %{
    $es->cluster_state(
        filter_nodes         => 1,
        filter_metadata      => 1,
        filter_routing_table => 1,
        filter_blocks        => 1
    )
    },
    'Filtered cluster state';

ok 1 == keys %{
    $es->cluster_state(
        filter_nodes         => 1,
        filter_routing_table => 1,
        filter_blocks        => 1,
        filter_indices       => 'es_test_1'
    )->{metadata}{indices}
    },
    ' - filtered metadata has 1 index';

1;
