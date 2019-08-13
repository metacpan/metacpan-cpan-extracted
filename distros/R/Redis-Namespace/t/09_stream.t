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

# check the redis server supports stream commands
eval { $redis->command_count } or plan skip_all => 'redis-server does not support the COMMAND command';
$redis->command_info('xgroup')->[0] or plan skip_all => 'redis-server does not support the stream commands';


ok my $id1 = $ns->xadd('mystream', '*', name => 'Sara', surname => 'OConnor');
ok my $id2 = $ns->xadd('mystream', '*', field1 => 'value1', field2 => 'value2', field3 => 'value3');
is $ns->xlen('mystream'), 2, 'mysteam is created';
is $redis->xlen('ns:mystream'), 2, 'key name has the namespace';

is_deeply [$ns->xrange('mystream', '-', '+')], [
    [
        $id1,
        [ name => 'Sara', surname => 'OConnor' ],
    ],
    [
        $id2,
        [ field1 => 'value1', field2 => 'value2', field3 => 'value3' ],
    ],
], 'xrange';

subtest 'xgroup and xinfo' => sub {
    ok $ns->xgroup('create', 'mystream', 'consumer-group-name', '$'), 'xgroup create';

    my ($group) = $ns->xinfo('groups', 'mystream');
    is_deeply {@$group}, {
        'name' => 'consumer-group-name',
        'consumers' => 0,
        'pending' => 0,
        'last-delivered-id' => $id2,
    }, 'xinfo groups';

    is_deeply {$ns->xinfo('stream', 'mystream')}, {
        'length' => 2,
        'radix-tree-keys' => 1,
        'radix-tree-nodes' => 2,
        'groups' => 1,
        'last-generated-id' => $id2,
        'first-entry' => [
            $id1,
            [ name => 'Sara', surname => 'OConnor' ],
        ],
        'last-entry' => [
            $id2,
            [ field1 => 'value1', field2 => 'value2', field3 => 'value3' ],
        ],
    }, 'xinfo stream';

    ok $ns->xgroup('destroy', 'mystream', 'consumer-group-name'), 'xgroup destroy';
};

subtest 'shorthands for xgroup and xinfo' => sub {
    ok $ns->xgroup_create('mystream', 'consumer-group-name', '$'), 'xgroup_create';

    my ($group) = $ns->xinfo_groups('mystream');
    is_deeply {@$group}, {
        'name' => 'consumer-group-name',
        'consumers' => 0,
        'pending' => 0,
        'last-delivered-id' => $id2,
    }, 'xinfo_groups';

    is_deeply {$ns->xinfo_stream('mystream')}, {
        'length' => 2,
        'radix-tree-keys' => 1,
        'radix-tree-nodes' => 2,
        'groups' => 1,
        'last-generated-id' => $id2,
        'first-entry' => [
            $id1,
            [ name => 'Sara', surname => 'OConnor' ],
        ],
        'last-entry' => [
            $id2,
            [ field1 => 'value1', field2 => 'value2', field3 => 'value3' ],
        ],
    }, 'xinfo_stream';

    ok $ns->xgroup_destroy('mystream', 'consumer-group-name'), 'xgroup_destroy';
};

subtest 'xread' => sub {
    ok $id1 = $ns->xadd('stream-a', '*', name => 'a');
    ok $id2 = $ns->xadd('stream-b', '*', name => 'b');
    is_deeply [$ns->xread(COUNT => 2, STREAMS => 'stream-a', 'stream-b', '0', '0')], [
        [
            'stream-a',
            [
                [ $id1, [ name => 'a' ] ],
            ],
        ],
        [
            'stream-b',
            [
                [ $id2, [ name => 'b' ] ],
            ],
        ],
    ];
    $ns->del('stream-a', 'stream-b');
};

subtest 'xreadgroup' => sub {
    ok $ns->xgroup_create('stream-a', 'consumer-group-name', '0', 'MKSTREAM'), 'xgroup create';
    ok $ns->xgroup_create('stream-b', 'consumer-group-name', '0', 'MKSTREAM'), 'xgroup create';
    ok $id1 = $ns->xadd('stream-a', '*', name => 'a');
    ok $id2 = $ns->xadd('stream-b', '*', name => 'b');
    is_deeply [$ns->xreadgroup(GROUP => 'consumer-group-name', 'foobar', COUNT => 2, 'NOACK', STREAMS => 'stream-a', 'stream-b', '>', '>')], [
        [
            'stream-a',
            [
                [ $id1, [ name => 'a' ] ],
            ],
        ],
        [
            'stream-b',
            [
                [ $id2, [ name => 'b' ] ],
            ],
        ],
    ];
    $ns->del('stream-a', 'stream-b');
};

done_testing;
