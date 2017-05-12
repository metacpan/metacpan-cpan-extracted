use strict;
use Test::More;
use Redis;
use Test::RedisServer;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

use Redis::Namespace;
%Redis::Namespace::COMMANDS = ();

my $redis_server = Test::RedisServer->new;
my $redis = Redis->new( $redis_server->connect_info );

my $version = $redis->info->{redis_version};
my ($major, $minor, $rev) = split /\./, $version;
unless ( $major >= 3 || $major == 2 && $minor >= 8 && $rev >= 13 ) {
    plan skip_all => "guess option requires 2.8.13 or later. your redis version is $version";
}

my $ns = Redis::Namespace->new(redis => $redis, namespace => 'ns', guess => 1);

subtest 'get and set' => sub {
    ok($ns->set(foo => 'bar'), 'set foo => bar');
    ok(!$ns->setnx(foo => 'bar'), 'setnx foo => bar fails');
    cmp_ok($ns->get('foo'), 'eq', 'bar', 'get foo = bar');
    cmp_ok($redis->get('ns:foo'), 'eq', 'bar', 'foo in namespace');
    $redis->flushall;
};

subtest 'mget and mset' => sub {
    ok($ns->mset(foo => 'bar', hoge => 'fuga'), 'mset foo => bar, hoge => fuga');
    is_deeply([$ns->mget('foo', 'hoge')], ['bar', 'fuga'], 'mget foo hoge = hoge, fuga');
    is_deeply([$redis->mget('ns:foo', 'ns:hoge')], ['bar', 'fuga'], 'foo, hoge in namespace');
    $redis->flushall;
};

done_testing;
