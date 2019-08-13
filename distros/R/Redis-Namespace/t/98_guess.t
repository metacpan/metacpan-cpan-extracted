use strict;
use Test::More;
use Redis;
use Test::RedisServer;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

use Redis::Namespace;
%Redis::Namespace::COMMANDS = (); # clear commands list for test.

my $redis_server = Test::RedisServer->new;
my $redis = Redis->new( $redis_server->connect_info );

my $version = $redis->info->{redis_version};
eval { $redis->command_count } or plan skip_all => "guess option requires the COMMAND command, but your redis server seems not to support it. your redis version is $version";

my $ns = Redis::Namespace->new(redis => $redis, namespace => 'ns', guess => 1, warning => 1);

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

subtest 'GEORADIUS' => sub {
    my $version = version->parse($redis->info->{redis_version});
    eval {
        $redis->geoadd('ns:Sicily', 13.361389, 38.115556, "Palermo", 15.087269, 37.502669, "Catania");
    } or plan skip_all => "your redis server seems not to support GEO commands, your redis version is $version";

    is_deeply([$ns->georadius(Sicily => 15, 37, 200, "km", "ASC")], ["Catania", "Palermo"], "GEORADIUS");

    # STORE key
    $ns->georadius(Sicily => 15, 37, 200, "km", STORE => "result");
    is_deeply([$redis->zrange('ns:result', 0, -1)], ["Palermo", "Catania"]);

    # STOREDIST key
    $ns->georadius(Sicily => 15, 37, 200, "km", STOREDIST => "result");
    is_deeply([$redis->zrange('ns:result', 0, -1)], ["Catania", "Palermo"]);

    $redis->flushall;
};

subtest 'ambiguous' => sub {
    # check the redis server supports stream commands
    eval { $redis->command_count } or plan skip_all => 'redis-server does not support the COMMAND command';
    $redis->command_info('xgroup')->[0] or plan skip_all => 'redis-server does not support the stream commands';

    ok my $id1 = $ns->xadd('count', '*', name => 'a');
    ok my $id2 = $ns->xadd('block', '*', name => 'b');
    ok my $id3 = $ns->xadd('streams', '*', name => 'c');
    is_deeply [$ns->xread(count => 2, block => 1000, streams => 'count', 'block', 'streams', '0', '0', '0')], [
        [
            # XXX: we can't remove the prefix, because the COMMAND command does not provide the key positions of the output.
            'ns:count',
            [
                [ $id1, [ name => 'a' ] ],
            ],
        ],
        [
            'ns:block',
            [
                [ $id2, [ name => 'b' ] ],
            ],
        ],
        [
            'ns:streams',
            [
                [ $id3, [ name => 'c' ] ],
            ],
        ],
    ];
};

done_testing;
