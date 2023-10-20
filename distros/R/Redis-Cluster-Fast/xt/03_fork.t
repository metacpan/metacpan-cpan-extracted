use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './xt/lib';
use Test::Docker::RedisCluster qw/get_startup_nodes/;

use Redis::Cluster::Fast;
use Test::SharedFork;

my $redis = Redis::Cluster::Fast->new(
    startup_nodes => get_startup_nodes,
);
$redis->mset('{my}hoge', 'test1', '{my}fuga', 'test2');
$redis->mset('{my}foo', 'FOO', '{my}bar', 'BAR');
$redis->del('test-fork');

my $pid = fork;
if ($pid == 0) {
    # child
    my $res = $redis->mget('{my}hoge', '{my}fuga');
    is_deeply $res, [ 'test1', 'test2' ];
    $redis->incr('test-fork');
    exit 0;
}
else {
    # parent
    my $res = $redis->mget('{my}foo', '{my}bar');
    is_deeply $res, [ 'FOO', 'BAR' ];
    $redis->incr('test-fork');
    waitpid($pid, 0);
}

is $redis->get('test-fork'), 2;

done_testing;
