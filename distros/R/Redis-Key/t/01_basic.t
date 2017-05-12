use strict;
use Test::More;
use Redis;
use Test::RedisServer;
use Test::Exception;

use Redis::Key;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

my $redis_server = Test::RedisServer->new;
my $redis = Redis->new( $redis_server->connect_info );

my $redis_version = version->parse($redis->info->{redis_version});


subtest 'get/set' => sub {
    my $key = Redis::Key->new(redis => $redis, key => 'hoge');

    ok($key->set('piyo'), 'set');
    is($key->get, 'piyo', 'get');
    is($redis->get('hoge'), 'piyo', 'set result');

    $redis->flushall;
};

subtest 'list' => sub {
    my $key = Redis::Key->new(redis => $redis, key => 'hoge');

    ok($key->rpush('one'), 'rpush one');
    ok($key->rpush('two'), 'rpush two');
    ok($key->rpush('three'), 'rpush three');

    my $s = $key->lrange(-3, 2);
    is_deeply($s, ['one', 'two', 'three'], 'scalar context');

    my @l = $key->lrange(-3, 2);
    is_deeply([@l], ['one', 'two', 'three'], 'list context');

    $redis->flushall;
};

subtest 'wait_all_responses' => sub {
    my $key = Redis::Key->new(redis => $redis, key => 'hoge');

    my $cnt = 0;
    my $s;
    my $cb = sub {
        my ($res, $err) = @_;
        if($res && !$err) {
            $cnt++;
        }
    };
    $key->rpush('one', $cb);
    $key->rpush('two', $cb);
    $key->rpush('three', $cb);
    $key->lrange(
        0, -1,
        sub {
            $s = shift;
        }
    );
    $key->wait_all_responses;

    is $cnt, 3, 'call all callback';
    is_deeply $s, ['one', 'two', 'three'], 'result of lrange';

    $redis->flushall;
};

subtest 'bind' => sub {
    my $key = Redis::Key->new(redis => $redis, key => 'hoge:{fugu}:piyo', need_bind => 1);
    $redis->set('hoge:FUGU:piyo', 'foobar');

    throws_ok {
        $key->get;
    } qr/needs bind/, 'needs bind';

    throws_ok {
        $key->bind;
    } qr/not passed/, 'not passed';

    my $key_bound = $key->bind(fugu => 'FUGU');
    ok($key_bound, 'bind');
    is($key_bound->get, 'foobar', 'get');

    $redis->flushall;
};

subtest 'keys' => sub {
    $redis->set("hoge:$_:piyo", 'foobar') for (1..10);
    $redis->set("Hoge:$_:piyo", 'foobar') for (1..10);
    my $key = Redis::Key->new(redis => $redis, key => 'hoge:{fugu}:piyo', need_bind => 1);
    my @keys = $key->keys;
    is_deeply([sort $key->keys], [sort map {"hoge:$_:piyo"} (1..10)], 'keys');
    is(scalar $key->keys, 10, 'keys count');

    $redis->flushall;
};


subtest 'keys for normal key' => sub {
    my $key = Redis::Key->new(redis => $redis, key => 'hoge:{fugu}:piyo');
    my @keys = $key->keys;
    is_deeply([sort $key->keys], [ "hoge:{fugu}:piyo" ], 'keys');
    is(scalar $key->keys, 1, 'keys count');

    $redis->flushall;
};


subtest 'scan' => sub {
    plan skip_all => 'your redis does not support SCAN command'
        unless $redis_version >= '2.8.0';

    $redis->set("hoge:$_:piyo", 'foobar') for (1..10);
    $redis->set("Hoge:$_:piyo", 'foobar') for (1..10);
    my $key = Redis::Key->new(redis => $redis, key => 'hoge:{fugu}:piyo', need_bind => 1);

    my @keys;
    my ($iter, $list) = (0, []);
    while(1) {
        ($iter, $list) = $key->scan($iter);
        push @keys, @$list;
        last if $iter == 0;
    }

    is_deeply([sort @keys], [sort map {"hoge:$_:piyo"} (1..10)], 'keys');

    $redis->flushall;
};


subtest 'scan for normal key' => sub {
    my $key = Redis::Key->new(redis => $redis, key => 'hoge:{fugu}:piyo');
    is_deeply([$key->scan], [0, ['hoge:{fugu}:piyo']], 'returns only one key');
    $redis->flushall;
};


subtest 'invalid commands' => sub {
    # these commands are invalid because they maybe change another key
    my $key = Redis::Key->new(redis => $redis, key => 'hoge');
    throws_ok { $key->flushall; }    qr/flushall/;
    throws_ok { $key->flushdb; }     qr/flushdb/;
    throws_ok { $key->quit; }        qr/quit/;
    throws_ok { $key->select; }      qr/select/;
    throws_ok { $key->shutdown; }    qr/shutdown/;
    throws_ok { $key->slaveof; }     qr/slaveof/;
    $redis->flushall;
};

subtest 'DEL command' => sub {
    my $key = Redis::Key->new(redis => $redis, key => 'hoge');
    ok $key->set('value'), 'set value';
    ok $key->exists, 'the key exists';
    ok $key->del, 'can delete the key';
    ok !$key->exists, 'the key does not exist after delete';

    throws_ok { $key->del('aother:key'); } qr/del/, 'cannot delete another key';
    $redis->flushall;
};

done_testing;

