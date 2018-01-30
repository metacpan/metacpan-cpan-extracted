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

is $ns->ping, 'PONG', 'ping pong ok';

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

subtest 'incr and decr' => sub {
    is($ns->incr('counter'), 1, 'incr');
    is($ns->get('counter'), 1, 'count = 1');
    is($redis->get('ns:counter'), 1, 'count in namespace');

    is($ns->incrby('counter', 3), 4, 'incrby');
    is($ns->get('counter'), 4, 'count = 4');
    is($redis->get('ns:counter'), 4, 'count in namespace');

    is($ns->decr('counter'), 3, 'decr');
    is($ns->get('counter'), 3, 'count = 3');
    is($redis->get('ns:counter'), 3, 'count in namespace');

    is($ns->decrby('counter', 3), 0, 'decrby');
    is($ns->get('counter'), 0, 'count = 0');
    is($redis->get('ns:counter'), 0, 'count in namespace');

    $redis->flushall;
};

subtest 'exists and del' => sub {
    ok(!$ns->exists('key'), 'not exists');
    $redis->set('ns:key', 'foo');
    ok($ns->exists('key'), 'exists');

    ok($ns->del('key'), 'del');
    ok(!$ns->del('key'), 'not del');
    ok(!$redis->exists('ns:key'), 'key in namespace');
    $redis->flushall;
};

subtest 'type' => sub {
    $redis->set('ns:string', 'foo');
    $redis->lpush('ns:list', 'hoge');
    $redis->sadd('ns:set', 'piyo');
    $redis->zadd('ns:zset', 0, 'piyo');
    $redis->hset('ns:hash', 'homu', 'fuga');

    cmp_ok($ns->type('string'), 'eq', 'string', 'string type');
    cmp_ok($ns->type('list'), 'eq', 'list', 'list type');
    cmp_ok($ns->type('set'), 'eq', 'set', 'set type');
    cmp_ok($ns->type('zset'), 'eq', 'zset', 'zset type');
    cmp_ok($ns->type('hash'), 'eq', 'hash', 'hash type');
    cmp_ok($ns->type('none'), 'eq', 'none', 'none type');
    $redis->flushall;
};

subtest 'keys' => sub {
    my @keys;
    for (1..10) {
        ok($ns->set("key-$_" => $_), "set key-$_ => $_");
        $redis->set("another-ns:key-$_" => $_);
        push @keys, "key-$_";
    }
    is_deeply [sort $ns->keys('*')], [sort @keys], "keys *";
    is scalar $ns->keys('*'), 10, "count keys *";
    $redis->flushall;
};

subtest 'list' => sub {
    my $list = 'test-list';
    ok($ns->rpush($list => "r$_"), 'rpush') foreach (1 .. 3);
    ok($ns->lpush($list => "l$_"), 'lpush') foreach (1 .. 2);

    cmp_ok($ns->type($list), 'eq', 'list', 'type');
    cmp_ok($redis->type("ns:$list"), 'eq', 'list', 'type');
    cmp_ok($ns->llen($list), '==', 5, 'llen');
    cmp_ok($redis->llen("ns:$list"), '==', 5, 'llen');

    is_deeply([$ns->lrange($list, 0, 1)], ['l2', 'l1'], 'lrange');

    ok($ns->ltrim($list, 1, 2), 'ltrim');
    cmp_ok($ns->llen($list), '==', 2, 'llen after ltrim');

    cmp_ok($ns->lindex($list, 0), 'eq', 'l1', 'lindex');
    cmp_ok($ns->lindex($list, 1), 'eq', 'r1', 'lindex');

    ok($ns->lset($list, 0, 'foo'), 'lset');
    cmp_ok($ns->lindex($list, 0), 'eq', 'foo', 'verified');

    ok($ns->lrem($list, 1, 'foo'), 'lrem');
    cmp_ok($ns->llen($list), '==', 1, 'llen after lrem');

    cmp_ok($ns->lpop($list), 'eq', 'r1', 'lpop');

    ok(!$ns->rpop($list), 'rpop');

    $redis->flushall;
};

subtest 'Commands operating on sets' => sub {
    my $set = 'test-set';

    ok($ns->sadd($set, 'foo'), 'sadd');
    ok(!$ns->sadd($set, 'foo'), 'sadd');
    cmp_ok($ns->scard($set), '==', 1, 'scard');
    ok($ns->sismember($set, 'foo'), 'sismember');

    cmp_ok($ns->type($set), 'eq', 'set', 'type is set');
    cmp_ok($redis->type("ns:$set"), 'eq', 'set', 'type is set');

    ok($ns->srem($set, 'foo'), 'srem');
    ok(!$ns->srem($set, 'foo'), 'srem again');
    cmp_ok($ns->scard($set), '==', 0, 'scard');

    $ns->sadd('test-set1', $_) foreach ('foo', 'bar', 'baz');
    $ns->sadd('test-set2', $_) foreach ('foo', 'baz', 'xxx');

    my $inter = [sort('foo', 'baz')];

    is_deeply([sort $ns->sinter('test-set1', 'test-set2')], $inter, 'sinter');

    ok($ns->sinterstore('test-set-inter', 'test-set1', 'test-set2'), 'sinterstore');

    cmp_ok($ns->scard('test-set-inter'), '==', $#$inter + 1, 'cardinality of intersection');

    is_deeply([$ns->sdiff('test-set1', 'test-set2')], ['bar'], 'sdiff');
    ok($ns->sdiffstore(qw( test-set-diff test-set1 test-set2 )), 'sdiffstore');
    is($ns->scard('test-set-diff'), 1, 'cardinality of diff');

    my @union = sort qw( foo bar baz xxx );
    is_deeply([sort $ns->sunion(qw( test-set1 test-set2 ))], \@union, 'sunion');
    ok($ns->sunionstore(qw( test-set-union test-set1 test-set2 )), 'sunionstore');
    is($ns->scard('test-set-union'), scalar(@union), 'cardinality of union');

    my $first_rand = $ns->srandmember('test-set-union');
    ok(defined $first_rand, 'srandmember result is defined');
    ok(scalar grep { $_ eq $first_rand } @union, 'srandmember');
    my $second_rand = $ns->spop('test-set-union');
    ok(defined $first_rand, 'spop result is defined');
    ok(scalar grep { $_ eq $second_rand } @union, 'spop');
    is($ns->scard('test-set-union'), scalar(@union) - 1, 'new cardinality of union');

    my @test_set3 = sort qw( foo bar baz );
    $ns->sadd('test-set3', $_) foreach @test_set3;
    is_deeply([sort $ns->smembers('test-set3')], \@test_set3, 'smembers');

    $ns->smove(qw( test-set3 test-set4 ), $_) foreach @test_set3;
    is($ns->scard('test-set3'), 0, 'repeated smove depleted source');
    is($ns->scard('test-set4'), scalar(@test_set3), 'repeated smove populated destination');
    is_deeply([sort $ns->smembers('test-set4')], \@test_set3, 'smembers');
};


subtest 'Commands operating on zsets (sorted sets)' => sub {
    my $zset = 'test-zset';

    ok($ns->zadd($zset, 0, 'foo'));
    ok(!$ns->zadd($zset, 1, 'foo'));    # 0 returned because foo is already in the set

    cmp_ok($ns->type($zset), 'eq', 'zset', 'type is zset');
    cmp_ok($redis->type("ns:$zset"), 'eq', 'zset', 'type is zset');

    is($ns->zscore($zset, 'foo'), 1);

    ok($ns->zincrby($zset, 1, 'foo'));
    is($ns->zscore($zset, 'foo'), 2);

    ok($ns->zincrby($zset, 1, 'bar'));
    is($ns->zscore($zset, 'bar'), 1);    # bar was new, so its score got set to the increment

    is($ns->zrank($zset, 'bar'), 0);
    is($ns->zrank($zset, 'foo'), 1);

    is($ns->zrevrank($zset, 'bar'), 1);
    is($ns->zrevrank($zset, 'foo'), 0);

    ok($ns->zadd($zset, 2.1, 'baz'));    # we now have bar foo baz

    is_deeply([$ns->zrange($zset, 0, 1)], [qw/bar foo/]);
    is_deeply([$ns->zrevrange($zset, 0, 1)], [qw/baz foo/]);


    my $withscores = { $ns->zrevrange($zset, 0, 1, 'WITHSCORES') };

    # this uglyness gets around floating point weirdness in the return (I.E. 2.1000000000000001);
    my $rounded_withscores = {
        map { $_ => 0 + sprintf("%0.5f", $withscores->{$_}) }
            keys %$withscores
    };

    is_deeply($rounded_withscores, { baz => 2.1, foo => 2 });

    is_deeply([$ns->zrangebyscore($zset, 2, 3)], [qw/foo baz/]);

    is($ns->zcount($zset, 2, 3), 2);

    is($ns->zcard($zset), 3);

    $redis->flushall;


    my $score = 0.1;
    my @zkeys = (qw/foo bar baz qux quux quuux quuuux quuuuux/);

    ok($ns->zadd($zset, $score++, $_)) for @zkeys;
    is_deeply([$ns->zrangebyscore($zset, 0, 8)], \@zkeys);

    is($ns->zremrangebyrank($zset, 5, 8), 3);    # remove quux and up
    is_deeply([$ns->zrangebyscore($zset, 0, 8)], [@zkeys[0 .. 4]]);

    is($ns->zremrangebyscore($zset, 0, 2), 2);    # remove foo and bar
    is_deeply([$ns->zrangebyscore($zset, 0, 8)], [@zkeys[2 .. 4]]);

    # only left with 3
    is($ns->zcard($zset), 3);

    $redis->flushall;
};

subtest 'Commands operating on hashes' => sub {
    my $hash = 'test-hash';

    ok($ns->hset($hash, foo => 'bar'));
    is($ns->hget($hash, 'foo'), 'bar');
    is($redis->hget("ns:$hash", 'foo'), 'bar');
    ok($ns->hexists($hash, 'foo'));
    ok($ns->hdel($hash, 'foo'));
    ok(!$ns->hexists($hash, 'foo'));

    ok($ns->hincrby($hash, incrtest => 1));
    is($ns->hget($hash, 'incrtest'), 1);

    is($ns->hincrby($hash, incrtest => -1), 0);
    is($ns->hget($hash, 'incrtest'), 0);

    ok($ns->hdel($hash, 'incrtest'));    #cleanup

    ok($ns->hsetnx($hash, setnxtest => 'baz'));
    ok(!$ns->hsetnx($hash, setnxtest => 'baz'));    # already exists, 0 returned

    ok($ns->hdel($hash, 'setnxtest'));              #cleanup

    ok($ns->hmset($hash, foo => 1, bar => 2, baz => 3, qux => 4));

    is_deeply([$ns->hmget($hash, qw/foo bar baz/)], [1, 2, 3]);

    is($ns->hlen($hash), 4);

    is_deeply([$ns->hkeys($hash)], [qw/foo bar baz qux/]);
    is_deeply([$ns->hvals($hash)], [qw/1 2 3 4/]);
    is_deeply({ $ns->hgetall($hash) }, { foo => 1, bar => 2, baz => 3, qux => 4 });

    ok($ns->del($hash));                            # remove entire hash

    $redis->flushall;
};


subtest 'Multiple databases handling commands' => sub {
    ok($ns->select(1), 'select');
    ok($ns->select(0), 'select');

    ok($ns->set('foo', 'bar'), 'set');

    ok($ns->move('foo', 1), 'move');
    ok(!$ns->exists('foo'), 'gone');
    ok(!$redis->exists('ns:foo'), 'gone');

    ok($ns->select(1),     'select');
    ok($ns->exists('foo'), 'exists');
    ok($redis->exists('ns:foo'), 'exists');

    ok($ns->flushdb, 'flushdb');
    cmp_ok($ns->dbsize, '==', 0, 'empty');

    $redis->flushall;
};

subtest 'Number Sorting' => sub {
    $redis->lpush('ns:test-sort', $_) foreach (1 .. 4);

    is_deeply([$ns->sort('test-sort')], [1, 2, 3, 4], 'sort');
    is_deeply([$ns->sort('test-sort', 'DESC')], [4, 3, 2, 1], 'sort DESC');
    is_deeply([$ns->sort('test-sort', 'LIMIT', 1, 2)], [2, 3], 'sort LIMIT 1 2');
    is_deeply([$ns->sort('test-sort', 'LIMIT', 1, 2, 'DESC')], [3, 2], 'sort LIMIT 1 2 DESC');
    ok([$ns->sort('test-sort', 'STORE', 'sort-result')], 'sort STORE');
    is_deeply([$redis->lrange('ns:sort-result', 0, 3)], [1, 2, 3, 4], 'sort result');

    $redis->flushall;
};

subtest 'Alphabet Sorting' => sub {
    $redis->lpush('ns:test-sort', $_) foreach ('a'..'d');

    is_deeply([$ns->sort('test-sort', 'ALPHA')], ['a', 'b', 'c', 'd'], 'sort ALPHA');
    is_deeply([$ns->sort('test-sort', 'ALPHA', 'DESC')], ['d', 'c', 'b', 'a'], 'sort ALPHA DESC');
    is_deeply([$ns->sort('test-sort', 'LIMIT', 1, 2, 'ALPHA')], ['b', 'c'], 'sort LIMIT 1 2 ALPHA');
    is_deeply([$ns->sort('test-sort', 'limit', 1, 2, 'alpha', 'desc')], ['c', 'b'], 'sort LIMIT 1 2 ALPHA DESC');
    ok([$ns->sort('test-sort', 'store', 'sort-result', 'alpha')], 'sort STORE ALPHA');
    is_deeply([$redis->lrange('ns:sort-result', 0, 3)], ['a', 'b', 'c', 'd'], 'sort result');

    $redis->flushall;
};

subtest 'External Key Sorting' => sub {
    $redis->lpush('ns:test-sort', $_) foreach ('a'..'d');
    $redis->set('ns:foo_a', 2);
    $redis->set('ns:foo_b', 1);
    $redis->set('ns:foo_c', 4);
    $redis->set('ns:foo_d', 3);

    is_deeply([$ns->sort('test-sort', 'BY', 'foo_*')], ['b', 'a', 'd', 'c'], 'sort BY');

    $redis->flushall;
};

subtest 'External Key and Get Object Sorting' => sub {
    $redis->lpush('ns:test-sort', $_) foreach ('a'..'d');
    $redis->set('ns:weight_a', 2);
    $redis->set('ns:weight_b', 1);
    $redis->set('ns:weight_c', 4);
    $redis->set('ns:weight_d', 3);
    $redis->set('ns:object_a', 'A');
    $redis->set('ns:object_b', 'B');
    $redis->set('ns:object_c', 'C');
    $redis->set('ns:object_d', 'D');

    is_deeply([$ns->sort('test-sort', 'BY', 'weight_*', 'GET', 'object_*')], ['B', 'A', 'D', 'C'], 'sort BY GET');
    is_deeply([$ns->sort('test-sort', 'BY', 'weight_*', 'GET', 'object_*', 'GET', '#')],
              ['B', 'b', 'A', 'a', 'D', 'd', 'C', 'c'], 'sort BY GET GET');

    $redis->flushall;
};

subtest 'External Hash and Get Hash Sorting' => sub {
    $redis->lpush('ns:test-sort', $_) foreach ('a'..'d');
    $redis->hset('ns:weight_a', 'foo', 2);
    $redis->hset('ns:weight_b', 'foo', 1);
    $redis->hset('ns:weight_c', 'foo', 4);
    $redis->hset('ns:weight_d', 'foo', 3);
    $redis->hset('ns:object_a', 'bar', 'A');
    $redis->hset('ns:object_b', 'bar', 'B');
    $redis->hset('ns:object_c', 'bar', 'C');
    $redis->hset('ns:object_d', 'bar', 'D');

    is_deeply([$ns->sort('test-sort', 'BY', 'weight_*->foo', 'GET', 'object_*->bar')],
              ['B', 'A', 'D', 'C'], 'sort BY GET');
    is_deeply([$ns->sort('test-sort', 'BY', 'weight_*->foo', 'GET', 'object_*->bar', 'GET', '#')],
              ['B', 'b', 'A', 'a', 'D', 'd', 'C', 'c'], 'sort BY GET GET');

    $redis->flushall;
};

subtest 'No Sorting' => sub {
    $redis->lpush('ns:test-sort', 3);
    $redis->lpush('ns:test-sort', 4);
    $redis->lpush('ns:test-sort', 1);
    $redis->lpush('ns:test-sort', 2);

    is_deeply([$ns->sort('test-sort', 'BY', 'nosort')], [2, 1, 4, 3], 'nosort');

    $redis->flushall;
};

subtest 'Eval' => sub {
    my $redis_version = version->parse($redis->info->{redis_version});
    plan skip_all => 'your redis does not support EVAL command'
        unless $redis_version >= '2.6.0';

    $redis->set('ns:hogehoge', 'foobar');
    is($ns->eval("return redis.call('get',KEYS[1])", 1, 'hogehoge'), 'foobar', 'eval');

    ok($ns->eval("return redis.call('set',KEYS[1],ARGV[1])", 1, 'hogehoge', 'FOOBAR'), 'eval');
    is($redis->get('ns:hogehoge'), 'FOOBAR', 'set ok');


    my $get_script = $redis->script('LOAD', "return redis.call('get',KEYS[1])");
    my $set_script = $redis->script('LOAD', "return redis.call('set',KEYS[1],ARGV[1])");

    $redis->set('ns:hogehoge', 'foobar');
    is($ns->evalsha($get_script, 1, 'hogehoge'), 'foobar', 'evalsha');

    ok($ns->evalsha($set_script, 1, 'hogehoge', 'FOOBAR'), 'evalsha');
    is($redis->get('ns:hogehoge'), 'FOOBAR', 'set ok');


    $redis->flushall;
    $redis->script('FLUSH');
};

subtest 'ZINTERSTORE/ZUNIONSTORE' => sub {
    $redis->zadd('ns:zset1', 1, 'one');
    $redis->zadd('ns:zset1', 2, 'two');
    $redis->zadd('ns:zset2', 1, 'one');
    $redis->zadd('ns:zset2', 2, 'two');
    $redis->zadd('ns:zset2', 3, 'three');

    ok($ns->zinterstore('out', 2, 'zset1', 'zset2', 'WEIGHTS', 2, 3), 'ZINTERSTORE');
    is_deeply([$redis->zrange('ns:out', 0, -1, 'WITHSCORES')], ['one', 5, 'two', 10], 'ZINTERSTORE result');

    ok($ns->zunionstore('out', 2, 'zset1', 'zset2', 'WEIGHTS', 2, 3), 'ZUNIONSTORE');
    is_deeply([$redis->zrange('ns:out', 0, -1, 'WITHSCORES')], ['one', 5, 'three', 9, 'two', 10], 'ZUNIONSTORE result');

    $redis->flushall;
};

subtest 'GEORADIUS' => sub {
    my $redis_version = version->parse($redis->info->{redis_version});
    plan skip_all => 'your redis does not support GEO commands'
        unless $redis_version >= '3.2.10';

    $redis->geoadd('ns:Sicily', 13.361389, 38.115556, "Palermo", 15.087269, 37.502669, "Catania");

    is_deeply([$ns->georadius(Sicily => 15, 37, 200, "km", "ASC")], ["Catania", "Palermo"], "GEORADIUS");

    # STORE key
    $ns->georadius(Sicily => 15, 37, 200, "km", STORE => "result");
    is_deeply([$redis->zrange('ns:result', 0, -1)], ["Palermo", "Catania"]);

    # STOREDIST key
    $ns->georadius(Sicily => 15, 37, 200, "km", STOREDIST => "result");
    is_deeply([$redis->zrange('ns:result', 0, -1)], ["Catania", "Palermo"]);

    $redis->flushall;
};

subtest 'GEORADIUSBYMEMBER' => sub {
    my $redis_version = version->parse($redis->info->{redis_version});
    plan skip_all => 'your redis does not support GEO commands'
        unless $redis_version >= '3.2.10';

    $redis->geoadd('ns:Sicily', 13.361389, 38.115556, "Palermo", 15.087269, 37.502669, "Catania");

    is_deeply([$ns->georadiusbymember(Sicily => "Catania", 200, "km", "ASC")], ["Catania", "Palermo"], "GEORADIUS");

    # STORE key
    $ns->georadiusbymember(Sicily => "Catania", 200, "km", STORE => "result");
    is_deeply([$redis->zrange('ns:result', 0, -1)], ["Palermo", "Catania"]);

    # STOREDIST key
    $ns->georadiusbymember(Sicily => "Catania", 200, "km", STOREDIST => "result");
    is_deeply([$redis->zrange('ns:result', 0, -1)], ["Catania", "Palermo"]);

    $redis->flushall;
};

done_testing;

