#!perl

use Test::More;
use strict;
use warnings;
our ( $es, $instances );
my $r;

### NODES ###
isa_ok $r = $es->nodes, 'HASH', 'All nodes';

is $r->{cluster_name}, 'es_test', ' - has cluster_name';
isa_ok $r->{nodes},    'HASH',    ' - has nodes';

my @nodes = sort ( keys %{ $r->{nodes} } );
is @nodes, $instances, " - $instances nodes";

my $first = shift @nodes;
ok $r= $es->nodes( node => $first ), ' - request single node';
is keys %{ $r->{nodes} }, 1, ' - got one node';
ok $r->{nodes}{$first}, ' - got same node';

isa_ok $r = $es->nodes( node => \@nodes ), 'HASH', ' - nodes by name';
is keys %{ $r->{nodes} }, @nodes, ' - retrieved same number of nodes';
is_deeply [ sort keys %{ $r->{nodes} } ], \@nodes,
    ' - retrieved the same nodes';

ok !$es->nodes()->{nodes}{$first}{settings}, ' - without settings';

ok $r= $es->nodes(
    settings    => 1,
    http        => 1,
    jvm         => 1,
    network     => 1,
    os          => 1,
    process     => 1,
    thread_pool => 1,
    transport   => 1
    )->{nodes}{$first},
    ' - with flags';

ok $r->{settings}
    && $r->{http}
    && $r->{jvm}
    && $r->{network}
    && $r->{os}
    && $r->{process}
    && $r->{thread_pool}
    && $r->{transport}, ' - all info';

ok $r= $es->nodes_stats->{nodes}{$first}, ' - nodes_stats';

ok $r->{indices}, ' - has indices';
ok !$r->{jvm}, ' - no jvm';

ok $r = $es->nodes_stats( clear => 1, jvm => 1 )->{nodes}{$first},
    ' - nodes_stats jvm';
ok !$r->{indices}, ' - no indices';
ok $r->{jvm}, ' - has jvm';

ok $r= $es->nodes_stats(
    indices     => 1,
    clear       => 1,
    fs          => 1,
    http        => 1,
    indices     => 1,
    jvm         => 1,
    network     => 1,
    os          => 1,
    process     => 1,
    thread_pool => 1,
    transport   => 1,
)->{nodes}{$first}, ' - nodes_stats all flags';

ok $r->{fs}
    && $r->{http}
    && $r->{indices}
    && $r->{jvm}
    && $r->{network}
    && $r->{os}
    && $r->{process}
    && $r->{thread_pool}
    && $r->{transport}, ' - all stats';

ok $r= $es->nodes_stats( all => 1 )->{nodes}{$first},
    ' - nodes_stats all flag';

ok $r->{fs}
    && $r->{http}
    && $r->{indices}
    && $r->{jvm}
    && $r->{network}
    && $r->{os}
    && $r->{process}
    && $r->{thread_pool}
    && $r->{transport}, ' - all stats';

1
