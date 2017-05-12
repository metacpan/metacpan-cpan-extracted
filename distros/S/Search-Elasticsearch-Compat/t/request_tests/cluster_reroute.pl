#!perl

use Test::More;
use Test::Exception;
use strict;
use warnings;
our ( $es, $instances );
my ( $r, $shards, %nodes, $node1, $node2, $node3 );

ok $r = $es->cluster_reroute->{state}, 'Reroute, no commands';

ok %nodes = %{ $r->{nodes} }, ' - has nodes';
ok keys %nodes == $instances, ' - nodes has all instances';
ok $shards = $r->{routing_table}{indices}{es_test_1}{shards}{0},
    ' - routing table';

ok $node1 = $shards->[0]{node}, ' - node 1';
delete $nodes{$node1};
ok $node2 = $shards->[1]{node}, ' - node 2';
delete $nodes{$node2};
ok $node3 = ( keys %nodes )[0], ' - node 3';

throws_ok {
    $es->cluster_reroute(
        commands => {
            move => {
                index     => 'es_test_1',
                shard     => 0,
                from_node => $node1,
                to_node   => $node2
            }
        }
    );
}
qr/not allowed/, ' - bad move';

ok $shards= $es->cluster_reroute(
    dry_run  => 1,
    commands => {
        move => {
            index     => 'es_test_1',
            shard     => 0,
            from_node => $node1,
            to_node   => $node3
        }
    }
    )->{state}{routing_table}{indices}{es_test_1}{shards}{0},
    ' - dry run';

is $shards->[0]{state}, 'RELOCATING', ' - dry run node relocating';
is $shards->[0]{relocating_node}, $node3, ' - dry run new node';

ok $shards
    = $es->cluster_reroute()
    ->{state}{routing_table}{indices}{es_test_1}{shards}{0},
    ' - post dry run';

is $shards->[0]{state}, 'STARTED', ' - node started';
is $shards->[0]{node}, $node1, ' - node not moved';

ok $shards= $es->cluster_reroute(
    commands => {
        move => {
            index     => 'es_test_1',
            shard     => 0,
            from_node => $node1,
            to_node   => $node3
        }
    }
    )->{state}{routing_table}{indices}{es_test_1}{shards}{0},
    ' - real reroute';

is $shards->[0]{state}, 'RELOCATING', ' - real run node relocating';
is $shards->[0]{relocating_node}, $node3, ' - real run new node';

wait_for_es(3);

ok $shards
    = $es->cluster_reroute()
    ->{state}{routing_table}{indices}{es_test_1}{shards}{0},
    ' - post real run';

TODO: {
    local $TODO = "Shards don't move predictably";
    is $shards->[0]{state}, 'STARTED', ' - node started';
    is $shards->[0]{node}, $node3, ' - node moved';

}

1;
