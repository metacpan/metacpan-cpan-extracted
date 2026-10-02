use strict;
use version 0.77;
use Test::More;
use Redis;
use Test::RedisServer;

use Redis::Namespace;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

# DEBUG is disabled by default since Redis 7.0. Older versions don't know the option and fail to start with it.
my $redis_server = eval { Test::RedisServer->new(conf => { 'enable-debug-command' => 'local' }) } || Test::RedisServer->new;
my $redis = Redis->new( $redis_server->connect_info );
eval { $redis->command_count } or plan skip_all => 'redis-server does not support the COMMAND command';

my $ns = Redis::Namespace->new(redis => $redis, namespace => 'ns');

subtest 'COMMAND COUNT' => sub {
    is scalar($ns->command_count), scalar($redis->command_count);
    is scalar($ns->command("count")), scalar($redis->command_count);
    $redis->flushall;
};

subtest 'DEBUG OBJECT' => sub {
    $redis->set("ns:key", "test");
    unless (eval { $redis->debug_object("ns:key") }) {
        my $error = $@ || 'DEBUG OBJECT returned a false value';
        die $error unless $error =~ /unknown command|DEBUG command not allowed/i;
        plan skip_all => "DEBUG command is not allowed: $error";
    }
    ok $redis->debug_object("ns:key");
    ok $ns->debug_object("key");
    ok $ns->debug(object => "key");
};

done_testing;

