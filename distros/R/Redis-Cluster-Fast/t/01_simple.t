use strict;
use warnings FATAL => 'all';
use Test::More;
use lib './t/lib';
use Test::Docker::RedisCluster qw/get_startup_nodes/;

use Redis::Cluster::Fast;

my $redis = Redis::Cluster::Fast->new(
    startup_nodes => get_startup_nodes,
);
is $redis->ping, 'PONG';

like $redis->CLUSTER_INFO(), qr/^cluster_state:ok/;

my $res = $redis->eval(
    "return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}",
    2, '{key}1', '{key}2', 'first', 'second');
is_deeply $res, [ '{key}1', '{key}2', 'first', 'second' ];

is $redis->mset('{my}hoge', 'test', '{my}fuga', 'test2'), 'OK';

my @res = $redis->mget('{my}hoge', '{my}fuga');
is_deeply \@res, [ 'test', 'test2' ];

$redis->hset('myhash', 'field1', 'Hello');
$redis->hset('myhash', 'field2', 'ByeBye');
is_deeply scalar $redis->hgetall('myhash'), { field1 => 'Hello', field2 => 'ByeBye' };

my $euro = "\x{20ac}";
ok ord($euro) > 255, 'is a wide character';
eval {
    $redis->set('euro', $euro);
};
like $@, qr/^command sent is not an octet sequence in the native encoding \(Latin-1\)\./, 'can not convert to Latin-1';

my $to_utf8 = my $to_latin1 = "test\x{80}";
utf8::upgrade($to_utf8);
utf8::downgrade($to_latin1);
is $to_utf8, $to_latin1, 'in Perl, equal';
$redis->del($to_latin1);
$redis->set($to_utf8, 'unicode');
is $redis->get($to_latin1), 'unicode', 'got value will be equal';

eval {
    Redis::Cluster::Fast->new(
        startup_nodes => [
            'localhost:1111corrupted'
        ],
    );
};
like $@, qr/^failed to add nodes: server port is incorrect/;

done_testing;
