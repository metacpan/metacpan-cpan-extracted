use strict;
use version 0.77;
use Test::More;
use Redis;
use Test::RedisServer;

use Redis::Namespace;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

my $redis_server = Test::RedisServer->new;
my $redis = Redis->new( $redis_server->connect_info );
my $ns = Redis::Namespace->new(redis => $redis, namespace => 'ns');

subtest 'COMMAND COUNT' => sub {
    is scalar($ns->command_count), scalar($redis->command_count);
    is scalar($ns->command("count")), scalar($redis->command_count);
    $redis->flushall;
};

subtest 'DEBUG OBJECT' => sub {
    $redis->set("ns:key", "test");
    ok $redis->debug_object("ns:key");
    ok $ns->debug_object("key");
    ok $ns->debug(object => "key");
};

done_testing;

