use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './xt/lib';
use Test::Docker::RedisCluster qw/get_startup_nodes/;

use Redis::Cluster::Fast;
use Test::LeakTrace;
use Test::SharedFork;

no_leaks_ok {
    my $redis = Redis::Cluster::Fast->new(
        startup_nodes => get_startup_nodes,
    );

    eval {
        # wide character
        $redis->set('euro', "\x{20ac}");
    };

    $redis->ping;
    $redis->CLUSTER_INFO();
    $redis->eval(
        "return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}",
        2, '{key}1', '{key}2', 'first', 'second');
    $redis->mset('{my}hoge', 'test', '{my}fuga', 'test2');
    $redis->mget('{my}hoge', '{my}fuga');

    eval {
        Redis::Cluster::Fast->new(
            startup_nodes => [
                'localhost:1111corrupted'
            ],
        );
    };
} "No Memory leak";

no_leaks_ok {
    my $redis = Redis::Cluster::Fast->new(
        startup_nodes => get_startup_nodes,
    );
    $redis->del('test-leak');
    my $pid = fork;
    if ($pid == 0) {
        # child
        $redis->incr('test-leak');
        exit 0;
    } else {
        # parent
        $redis->incr('test-leak');
        waitpid($pid, 0);
    }

    $redis->get('test-leak');
} "No Memory leak - fork";

done_testing;
