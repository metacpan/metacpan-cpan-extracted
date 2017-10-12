use Mojo::Base -strict;
use Mojo::Redis2;
use Test::More;
use List::Util 'shuffle';
use lib '.';
use t::Util;

plan skip_all => 'Cannot test on Win32' if $^O eq 'MSWin32';

my %ops = t::Util->get_documented_redis_methods;
my @categories = $ENV{TEST_CATEGORY} || qw( Hashes Keys Lists PubSub Sets SortedSets Strings Connection );
my $redis = Mojo::Redis2::RECORDER->new;
my $key;

plan skip_all => $@ unless eval { Mojo::Redis2::Server->start };
add_recorder();

for my $category (shuffle @categories) {
  local $@ = '';
  $key = "redis2:test:$category";
  eval { main->$category };
  is $@, '', "$category did not fail";
}

is_deeply [keys %ops], [], 'all redis methods has been tested' or diag join ', ', keys %ops unless $ENV{TEST_CATEGORY};
done_testing;

sub Connection {
  is $redis->ping, 'PONG', 'ping';
  is $redis->echo('yikes'), 'yikes', 'echo';
}

sub Hashes {
  is $redis->hmset($key, foo => 39, bar => 'fourty_two'), 'OK', 'hmset';
  is $redis->hincrby($key, foo => 3), 42, 'hincrby return new value';
  is $redis->hincrbyfloat($key, foo => 5.75), 47.75, 'hincrbyfloat return new value';
  is $redis->hincrbyfloat($key, foo => -2.75), 45, 'negative hincrbyfloat return new value';
  is_deeply [sort @{ $redis->hkeys($key) }], [qw( bar foo )], 'hkeys';

  my $warning = '';
  {
  local $TODO = 'Should this return a hash?';
  local $SIG{__WARN__} = sub { $warning = $_[0] };
  is_deeply $redis->hmget($key, qw( baz bar foo )), [undef, 'fourty_two', 45], 'hmget';
  }
  is $warning, '', 'no warning github#17';

  is $redis->hset($key => baz => 'yikes'), 1, 'hset';
  is $redis->hlen($key), 3, 'hlen get number of keys in hash';
  is $redis->hsetnx($key => baz => 'yikes'), 0, 'hsetnx on existing key';
  is $redis->hsetnx($key => works => 'aaa'), 1, 'hsetnx on new key';
  is $redis->hexists($key, "foo"), 1, 'hexists';
  is $redis->hget($key, "foo"), '45', 'hget';

  {
  local $TODO = 'Need to return a hash';
  is_deeply $redis->hgetall($key), { foo => 45, bar => 'fourty_two', baz => 'yikes' }, 'hgetall';
  }

  is $redis->hexists($key, "foo"), 1, 'hexists';
  is $redis->hdel($key, "foo"), 1, 'hdel';
  is_deeply [sort @{ $redis->hvals($key) }], [qw( aaa fourty_two yikes )], 'hvals';
  is $redis->hexists($key, "foo"), 0, 'hexists';
}

sub Keys {
  is $redis->set($key, 42), 'OK', 'set';
  is $redis->type($key), 'string', 'type';
  is $redis->exists($key), 1, 'exists';
  is $redis->pexpire($key, 10000), 1, 'expire in milliseconds';
  is $redis->pexpireat($key, (time + 2) * 1000), 1, 'pexpireat a timestamp in milliseconds';
  is $redis->expire($key, 10), 1, 'expire in seconds';
  is $redis->expireat($key, time + 2), 1, 'expireat a timestamp';
  ok +($_ = $redis->pttl($key)) < 4000, 'pttl' or diag "pttl=$_";
  ok +($_ = $redis->ttl($key)) < 4, 'ttl' or diag "ttl=$_";
  is $redis->persist($key), 1, 'persist';
  is_deeply $redis->keys('does:not:exist*'), [], 'keys';
  is_deeply $redis->keys($key), [qw( redis2:test:Keys )], 'keys';
  is_deeply $redis->keys("$key*"), [qw( redis2:test:Keys )], 'keys';
  is $redis->rename($key => "$key:b"), 'OK', 'rename';
  is $redis->exists($key), 0, 'exists';
  is $redis->exists("$key:b"), 1, 'exists';
  is $redis->set($key, 123123123), 'OK', 'set';
  is $redis->renamenx("$key:b", $key), 0, 'renamenx to existing key';
  is $redis->move("$key:b", 2), 1, 'move to other database';
  like $redis->randomkey, qr{^redis2:test:[\w:]+$}, 'randomkey in database';
}

sub Lists {
  is $redis->lpushx($key => 'no_such_list'), 0, 'lpushx';
  is $redis->rpushx($key => 'no_such_list'), 0, 'rpushx';
  is $redis->lpush($key => 123), 1, 'lpushx';
  is $redis->rpush($key => 'foo'), 2, 'lpushx';
  is $redis->lpushx($key => 42), 3, 'lpushx';
  is $redis->rpushx($key => 'bar'), 4, 'rpushx';
  is $redis->lindex($key, 2), 'foo', 'lindex';
  is $redis->linsert($key, AFTER => 'foo', 'after'), 5, 'linsert AFTER foo';
  is $redis->linsert($key, BEFORE => 'foo', 'before'), 6, 'linsert BEFORE foo';
  is $redis->lpop($key), 42, 'lpop';
  is $redis->rpop($key), 'bar', 'rpop';
  is $redis->llen($key), 4, 'llen';
  is $redis->lpush($key => $_), $_ + 4, "lpush $_" for 1..6;
  is_deeply $redis->lrange($key => 0, -1), [6,5,4,3,2,1, 123, 'before', 'foo', 'after'], 'lrange' or diag join ',', @{ $redis->lrange($key => 0, -1) };
  is $redis->lrem($key => 0, 'foo'), 1, 'lrem';
  is $redis->lset($key => 4 => 'set'), 'OK', 'lset';
  is $redis->ltrim($key => 3, 6), 'OK', 'ltrim';
  is_deeply $redis->lrange($key => 0, -1), [3, 'set', 1, 123], 'lrange' or diag join ',', @{ $redis->lrange($key => 0, -1) };
  is $redis->rpoplpush($key => "$key:other"), 123, 'rpoplpush';
  is_deeply $redis->lrange($key => 0, -1), [qw( 3 set 1 )], 'lrange';
  is_deeply $redis->lrange("$key:other" => 0, -1), [qw( 123 )], 'lrange';
}

sub PubSub {
  is $redis->publish("$key:channel" => 42), 0, 'publish';
}

sub Sets {
  is $redis->sadd($key => qw( a b )), 2, 'sadd';
  is $redis->sadd("$key:b" => qw( d c b )), 3, 'sadd';
  is_deeply $redis->sort("$key:b", 'ALPHA'), [qw( b c d )], 'sort';
  is $redis->scard($key), 2, 'scard';
  is_deeply [sort @{ $redis->sdiff("$key:b", $key) }], [qw( c d )], 'sdiff' or diag join ',', sort @{ $redis->sdiff($key => "$key:b") };
  is $redis->sdiffstore("$key:x" => "$key:b", $key), 2, 'sdiffstore';
  is_deeply $redis->sinter($key, "$key:b"), ['b'], 'sinter';
  is $redis->sismember($key => 'b'), '1', 'sismember';
  is_deeply [sort @{ $redis->smembers($key) }], [qw( a b )], 'smembers';
  is $redis->smove($key => "$key:b" => 'a'), 1, 'smove';
  is $redis->srandmember($key), 'b', 'srandmember';
  is $redis->spop($key), 'b', 'spop';
  is $redis->srem("$key:b" => 'd'), 1, 'srem';
  is $redis->sadd($key, qw( a b c d )), 4, 'sadd';
  is_deeply [sort @{ $redis->sunion("$key:x" => "$key:b" => $key) }], [qw( a b c d )], 'sunion' or diag join ',', sort @{ $redis->sunion("$key:x" => "$key:b" => $key) };
  is $redis->sunionstore("$key:all" => "$key:x" => "$key:b" => $key), 4, 'sunionstore';
  is $redis->sinterstore("$key:all" => "$key:x" => "$key:b" => $key), 1, 'sinterstore';
}

sub SortedSets {
  is $redis->zadd("$key:b" => qw( 1 x 2 two )), 2, 'zadd';
  is $redis->zadd("$key:c" => qw( 0 a 0 b 0 c 0 d 0 e 0 f 0 g 0 h 0 i)), 9, 'zadd';
  is $redis->zadd($key => 2 => 'two', 3 => 'three', 4 => 'four'), 3, 'zadd';
  is $redis->zcard($key), 3, 'zcard';
  is $redis->zcount($key => 1, 3), 2, 'zcount';
  is $redis->zincrby($key => 3, 'two'), 5, 'zincrby';
  is $redis->zscore($key => 'two'), 5, 'zscore';
  is $redis->zrank($key => 'two'), 2, 'zrank';
  is $redis->zrevrank($key => 'two'), 0, 'zrevrank';

  {
  local $TODO = 'Should WITHSCORES result in hash?';
  is_deeply $redis->zrange($key => 0, -1, 'WITHSCORES'), [qw( three 3 four 4 two 5 )], 'zrange WITHSCORES';
  is_deeply $redis->zrevrange($key => 1, 2, 'WITHSCORES'), [qw( four 4 three 3 )], 'zrevrange WITHSCORES';
  is_deeply $redis->zrangebyscore($key => 4, 5, 'WITHSCORES'), [qw( four 4 two 5 )], 'zrangebyscore WITHSCORES';
  is_deeply $redis->zrevrangebyscore($key => '+inf', 4, 'WITHSCORES'), [qw( two 5 four 4 )], 'zrevrangebyscore WITHSCORES';
  }

  is $redis->zinterstore("$key:x" => 2 => $key, "$key:b"), 1, 'zinterstore';
  is_deeply $redis->zrange("$key:x" => 0, -1), [qw( two )], 'zrange';
  is_deeply $redis->zrevrangebyscore("$key:x" => '+inf', '-inf'), [qw( two )], 'zrevrangebyscore';

  is $redis->zunionstore("$key:x" => 2 => $key, "$key:b"), 4, 'zunionstore';
  is_deeply $redis->zrevrange("$key:x" => 0, -1), [qw( two four three x )], 'zrevrange';
  is_deeply $redis->zrangebyscore("$key:x" => 4, 5), [qw( four )], 'zrangebyscore';
  is_deeply $redis->zrevrangebyscore("$key:x" => 4, 0), [qw( four three x )], 'zrevrangebyscore';

  is $redis->zrem($key => 'two'), 1, 'zrem';
  is $redis->zremrangebyscore($key => 3, 3), 1, 'zremrangebyscore';
  is $redis->zremrangebyrank($key => 0, 0), 1, 'zremrangebyrank';
  is $redis->zcard($key), 0, 'zcard';

  is $redis->zlexcount("$key:c" => qw( - + )), 9, 'zlexcount all range';
  is $redis->zlexcount("$key:c" => qw( [b [f )), 5, 'zlexcount specific range';

  is_deeply $redis->zrangebylex("$key:c" => qw( - [c )), [qw( a b c )], 'zrangebylex';
  is $redis->zremrangebylex("$key:c" => qw( [b [f )), 5, 'zremrangebylex';
  is_deeply $redis->zrevrangebylex("$key:c" => qw| [h (a |), [qw( h g )], 'zrevrangebylex';

}

sub Strings {
  is $redis->set($key => 'foo'), 'OK', 'set';
  is $redis->append($key => '_append'), length('foo_append'), 'append';
  is $redis->getbit($key, 11), 0, 'getbit';
  is $redis->getbit($key, 10), 1, 'getbit';
  is $redis->bitcount($key => qw( 1 5 )), 24, 'bitcount';
  is $redis->bitop('NOT', "$key:inv", $key), 10, 'bitop';
  is $redis->bitpos("$key:inv" => qw( 0 2 )), 17, 'bitpos';
  is $redis->getrange($key, 3, 7), '_appe', 'getrange';
  is $redis->getset($key, 42), 'foo_append', 'getset';
  is $redis->setrange($key, 3, 'foobarbaz'), 12, 'setrange';
  is $redis->del($key), 1, 'del';

  is $redis->set($key => 10), 'OK', 'set';
  is $redis->decr($key), '9', 'decr';
  is $redis->decrby($key, 3), '6', 'decrby';

  is $redis->set($key => 10), 'OK', 'set';
  is $redis->incr($key), 11, 'incr';
  is $redis->incrby($key, 6), 17, 'incrby';

  is $redis->incrbyfloat($key, 3.895421), 20.895421, 'positive incrbyfloat';
  is $redis->incrbyfloat($key, -6.895421), 14, 'negative incrbyfloat';

  is $redis->mset($key => 123, "$key:ex" => 321), 'OK', 'mset';
  is_deeply $redis->mget($key, "$key:nope", "$key:ex"), [123, undef, 321], 'mget';
  is $redis->strlen($key), 3, 'strlen';

  is $redis->setbit("$key:b" => 2 => 1), 0, 'setbit';
  is $redis->setbit("$key:b" => 2 => 0), 1, 'setbit';

  is $redis->msetnx($key => 42, "$key:bar" => 34), 0, 'msetnx';
  is $redis->get("$key:bar"), undef, 'get';
  is $redis->msetnx("$key:bar" => 34, "$key:foo" => 35), 1, 'msetnx';
  is $redis->get("$key:bar"), 34, 'get';
  is $redis->setnx("$key:x", 42), 1, 'setnx';
  is $redis->setex("$key:x", 10, 42), 'OK', 'setex';
  is $redis->setnx("$key:x", 42), 0, 'setnx';
  is $redis->psetex("$key:x", 1000, 'bar'), 'OK', 'psetex';

}

sub add_recorder {
  package Mojo::Redis2::RECORDER;
  use Mojo::Base 'Mojo::Redis2';
  for my $m (keys %ops) {
    my $code = "*Mojo::Redis2::RECORDER::$m = sub { delete \$ops{$m}; shift->SUPER::$m(\@_); }";
    eval $code or die "$code ===> $@";
  }
  package main;
}
