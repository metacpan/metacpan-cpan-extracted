use strict;
use version 0.77;
use Test::More;
use Redis;
use Test::RedisServer;

use Redis::Namespace;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

my $redis_server = Test::RedisServer->new;
my $redis = Redis->new( $redis_server->connect_info );

my $ns1 = Redis::Namespace->new(redis => $redis, namespace => 'h?llo');
my $ns2 = Redis::Namespace->new(redis => $redis, namespace => 'h*llo');
my $ns3 = Redis::Namespace->new(redis => $redis, namespace => 'h[ae]llo');
my $ns4 = Redis::Namespace->new(redis => $redis, namespace => 'h[^e]llo');
my $ns5 = Redis::Namespace->new(redis => $redis, namespace => 'h[a-b]llo');

$redis->mset('hello:foo' => 'a', 'hallo:bar' => 'a', 'hxllo:foobar' => 'a', 'hllo:hoge' => 'a', 'heeeello:fuga' => 'a');

$ns1->mset(foo => 'a', bar => 'b');
$ns2->mset(foo => 'a', bar => 'b');
$ns3->mset(foo => 'a', bar => 'b');
$ns4->mset(foo => 'a', bar => 'b');
$ns5->mset(foo => 'a', bar => 'b');

is_deeply [sort $ns1->keys('*')], ['bar', 'foo'], 'keys h?llo:';
is_deeply [sort $ns2->keys('*')], ['bar', 'foo'], 'keys h*llo:';
is_deeply [sort $ns3->keys('*')], ['bar', 'foo'], 'keys h[ae]llo:';
is_deeply [sort $ns4->keys('*')], ['bar', 'foo'], 'keys h[^e]llo:';
is_deeply [sort $ns5->keys('*')], ['bar', 'foo'], 'keys h[a-b]llo:';

done_testing;
