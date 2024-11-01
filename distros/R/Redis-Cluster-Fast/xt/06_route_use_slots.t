use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './xt/lib';
use Test::Docker::RedisCluster qw/get_startup_nodes/;

use Redis::Cluster::Fast;

my $nodes = get_startup_nodes;
my $redis = Redis::Cluster::Fast->new(
    startup_nodes => $nodes,
    route_use_slots => 1,
);
my $prefix = '{06_route_use_slots}';

{
    my @res = $redis->mget("${prefix}foo", "${prefix}bar");
    is_deeply \@res, [ undef, undef ];
}
{
    is $redis->mset("${prefix}foo", 'test', "${prefix}bar", 'test2'), 'OK';

    my @res = $redis->mget("${prefix}foo", "${prefix}bar");
    is_deeply \@res, [ 'test', 'test2' ];
}

done_testing;
