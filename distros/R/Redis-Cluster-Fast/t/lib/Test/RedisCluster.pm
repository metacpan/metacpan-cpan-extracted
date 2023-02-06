package Test::RedisCluster;
use strict;
use warnings FATAL => 'all';

use Exporter 'import';
use Redis::Cluster::Fast;
use Sub::Retry;
use Test::RedisClusterImage;

our @EXPORT_OK = qw/get_startup_nodes REDIS_CLUSTER_INITIAL_PORT/;

use constant {
    REDIS_CLUSTER_INITIAL_PORT => 9000,
    REDIS_CLUSTER_PORTS => [ 9000, 9001, 9002, 9003, 9004, 9005 ],
    REDIS_VERSION => '6.0.5',
};

sub get_startup_nodes {
    if (my $nodes = $ENV{TEST_REDIS_CLUSTER_STARTUP_NODES}) {
        return [ split(/,/, $nodes) ];
    } else {
        my $ports = REDIS_CLUSTER_PORTS;
        return [ map {"localhost:$_"} @$ports ];
    }
}

sub _get_container_ports {
    my $ports = REDIS_CLUSTER_PORTS;
    [ map {"$_:$_"} @$ports ];
}

my $redis_cluster_guard;
unless ($ENV{TEST_REDIS_CLUSTER_STARTUP_NODES}) {
    $redis_cluster_guard = Test::RedisClusterImage->new(
        boot => 'Test::RedisClusterBoot',
        container_ports => _get_container_ports,
        tag => 'grokzen/redis-cluster:' . REDIS_VERSION,
    );

    my $redis;
    retry(100, 0.2, sub {
        $redis = Redis::Cluster::Fast->new(
            startup_nodes => get_startup_nodes,
        );
    }, sub {
        my $err = $@;
        return 1 if $err;

        eval {
            my $info = $redis->cluster_info();
            return 0 if $info =~ /^cluster_state:ok/;
        };
        1;
    });

    # avoid CLUSTERDOWN
    sleep 2;
}

END {undef $redis_cluster_guard}
1;
