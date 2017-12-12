use Mojo::Base -strict;
use Mojo::Redis2;
use Mojo::Util qw(sha1_sum encode);
use Mojo::Collection ();
use Test::More;
use List::Util 'shuffle';
use Sort::Versions 'versioncmp';
use lib '.';
use t::Util;

plan skip_all => 'Cannot test on Win32' if $^O eq 'MSWin32';

my %ops = t::Util->get_documented_redis_methods;
my @categories
  = $ENV{TEST_CATEGORY} || qw( Hashes Keys Lists PubSub Sets SortedSets Strings Connection Geo HyperLogLog Scripting );
my $redis  = Mojo::Redis2::RECORDER->new;
my $server = Mojo::Redis2::Server->new;
my $key;

plan skip_all => $@ unless eval { $server->start };
add_recorder();

my $redis_version = $redis->backend->info('server')->{redis_version};

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
  is $redis->hincrbyfloat($key, foo => 5.75),  47.75, 'hincrbyfloat return new value';
  is $redis->hincrbyfloat($key, foo => -2.75), 45,    'negative hincrbyfloat return new value';
  is_deeply [sort @{$redis->hkeys($key)}], [qw( bar foo )], 'hkeys';

  my $warning = '';
  {
    local $TODO = 'Should this return a hash?';
    local $SIG{__WARN__} = sub { $warning = $_[0] };
    is_deeply $redis->hmget($key, qw( baz bar foo )), [undef, 'fourty_two', 45], 'hmget';
  }
  is $warning, '', 'no warning github#17';

  is $redis->hset($key => baz => 'yikes'), 1, 'hset';
  is $redis->hlen($key), 3, 'hlen get number of keys in hash';
  is $redis->hsetnx($key => baz   => 'yikes'), 0, 'hsetnx on existing key';
  is $redis->hsetnx($key => works => 'aaa'),   1, 'hsetnx on new key';
  is $redis->hexists($key, "foo"), 1, 'hexists';
  is $redis->hget($key, "foo"), '45', 'hget';

  {
    local $TODO = 'Need to return a hash';
    is_deeply $redis->hgetall($key), {foo => 45, bar => 'fourty_two', baz => 'yikes'}, 'hgetall';
  }

  is $redis->hexists($key, "foo"), 1, 'hexists';
  is $redis->hdel($key, "foo"), 1, 'hdel';
  is_deeply [sort @{$redis->hvals($key)}], [qw( aaa fourty_two yikes )], 'hvals';
  is $redis->hexists($key, "foo"), 0, 'hexists';

SKIP: {
    skip 'hstrlen requires Redis 3.2.0', 1 if versioncmp($redis_version, '3.2.0') == -1;
    is $redis->hstrlen($key, 'bar'), 10, 'hstrlen';
  }

}

sub Keys {
  is $redis->set($key, 42), 'OK', 'set';
  is $redis->type($key),   'string', 'type';
  is $redis->exists($key), 1,        'exists';
  is $redis->pexpire($key, 10000), 1, 'expire in milliseconds';
  is $redis->pexpireat($key, (time + 2) * 1000), 1, 'pexpireat a timestamp in milliseconds';
  is $redis->expire($key, 10), 1, 'expire in seconds';
  is $redis->expireat($key, time + 2), 1, 'expireat a timestamp';
  ok + ($_ = $redis->pttl($key)) < 4000, 'pttl' or diag "pttl=$_";
  ok + ($_ = $redis->ttl($key)) < 4,     'ttl'  or diag "ttl=$_";
  is $redis->persist($key), 1, 'persist';
  is_deeply $redis->keys('does:not:exist*'), [], 'keys';
  is_deeply $redis->keys($key),    [qw( redis2:test:Keys )], 'keys';
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
  is $redis->linsert($key, AFTER  => 'foo', 'after'),  5, 'linsert AFTER foo';
  is $redis->linsert($key, BEFORE => 'foo', 'before'), 6, 'linsert BEFORE foo';
  is $redis->lpop($key), 42,    'lpop';
  is $redis->rpop($key), 'bar', 'rpop';
  is $redis->llen($key), 4,     'llen';
  is $redis->lpush($key => $_), $_ + 4, "lpush $_" for 1 .. 6;
  is_deeply $redis->lrange($key => 0, -1), [6, 5, 4, 3, 2, 1, 123, 'before', 'foo', 'after'], 'lrange'
    or diag join ',', @{$redis->lrange($key => 0, -1)};
  is $redis->lrem($key => 0, 'foo'), 1, 'lrem';
  is $redis->lset($key => 4 => 'set'), 'OK', 'lset';
  is $redis->ltrim($key => 3, 6), 'OK', 'ltrim';
  is_deeply $redis->lrange($key => 0, -1), [3, 'set', 1, 123], 'lrange'
    or diag join ',', @{$redis->lrange($key => 0, -1)};
  is $redis->rpoplpush($key => "$key:other"), 123, 'rpoplpush';
  is_deeply $redis->lrange($key         => 0, -1), [qw( 3 set 1 )], 'lrange';
  is_deeply $redis->lrange("$key:other" => 0, -1), [qw( 123 )],     'lrange';
}

sub PubSub {
  is $redis->publish("$key:channel" => 42), 0, 'publish';
}

sub Sets {
  is $redis->sadd($key     => qw( a b )),   2, 'sadd';
  is $redis->sadd("$key:b" => qw( d c b )), 3, 'sadd';
  is_deeply $redis->sort("$key:b", 'ALPHA'), [qw( b c d )], 'sort';
  is $redis->scard($key), 2, 'scard';
  is_deeply [sort @{$redis->sdiff("$key:b", $key)}], [qw( c d )], 'sdiff'
    or diag join ',', sort @{$redis->sdiff($key => "$key:b")};
  is $redis->sdiffstore("$key:x" => "$key:b", $key), 2, 'sdiffstore';
  is_deeply $redis->sinter($key, "$key:b"), ['b'], 'sinter';
  is $redis->sismember($key => 'b'), '1', 'sismember';
  is_deeply [sort @{$redis->smembers($key)}], [qw( a b )], 'smembers';
  is $redis->smove($key => "$key:b" => 'a'), 1, 'smove';
  is $redis->srandmember($key), 'b', 'srandmember';
  is $redis->spop($key),        'b', 'spop';
  is $redis->srem("$key:b" => 'd'), 1, 'srem';
  is $redis->sadd($key, qw( a b c d )), 4, 'sadd';
  is_deeply [sort @{$redis->sunion("$key:x" => "$key:b" => $key)}], [qw( a b c d )], 'sunion'
    or diag join ',', sort @{$redis->sunion("$key:x" => "$key:b" => $key)};
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
    is_deeply $redis->zrevrangebyscore($key => '+inf', 4, 'WITHSCORES'), [qw( two 5 four 4 )],
      'zrevrangebyscore WITHSCORES';
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

  is $redis->zlexcount("$key:c" => qw( - + )),   9, 'zlexcount all range';
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

  is $redis->incrbyfloat($key, 3.895421),  20.895421, 'positive incrbyfloat';
  is $redis->incrbyfloat($key, -6.895421), 14,        'negative incrbyfloat';

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

sub Geo {

SKIP: {

    skip 'geo commands require Redis 3.2.0', 12 if versioncmp($redis_version, '3.2.0') == -1;

    my @testlocs = qw(
      -3.055344 53.815931 Blackpool
      -2.700635 53.759607 Preston
      -3.006270 53.647920 Southport
      -3.014240 53.919310 Fleetwood
      -2.799996 54.045655 Lancaster
      -0.798977 51.214957 Farnham
    );

    is $redis->geoadd($key => @testlocs), scalar(@testlocs) / 3, 'geoadd';
    is $redis->geodist($key => qw( Blackpool Farnham km )),  327.0952,     'geodist in km';
    is $redis->geodist($key => qw( Blackpool NonExisting )), undef,        'geoexist missing location';
    is $redis->geodist($key => qw( Farnham Fleetwood ft )),  1102286.9318, 'geodist in feet';
    is_deeply $redis->geohash($key => qw( Lancaster Southport Blackpool )),
      ['gcw52q9ng20', 'gctc5w6cuc0', 'gctf4kzht20'], 'geohash';

    {
      # Return values will be slightly different due to redis converting locations into 52 bit geohashes
      # So we round and then compare

      my $res = $redis->geopos($key => qw( Preston NonExisting Blackpool ));

      is sprintf("%.4f", $res->[0][0]), sprintf("%.4f", $testlocs[3]), 'getpos element 1.0';    ## Preston Longtitude
      is sprintf("%.4f", $res->[0][1]), sprintf("%.4f", $testlocs[4]), 'getpos element 1.1';    ## Preston Latitude
      is $res->[1][0], undef, 'getpos element 2 - nonlocation';                                 ## NonExistent Location
      is sprintf("%.4f", $res->[2][0]), sprintf("%.4f", $testlocs[0]), 'getpos element 2.0';    ## Blackpool Longtitude
      is sprintf("%.4f", $res->[2][1]), sprintf("%.4f", $testlocs[1]), 'getpos element 2.1';    ## Blackpool Latitude
    }

    is_deeply $redis->georadius($key => qw( -3.0 53.8 20 km WITHDIST ASC)),
      [['Blackpool', '4.0438'], ['Fleetwood', '13.3032'], ['Southport', '16.9204']], 'georadius';
    is_deeply $redis->georadiusbymember($key => qw( Preston 30 km DESC)),
      ['Fleetwood', 'Blackpool', 'Southport', 'Preston'], 'georadiusbymember';
  }

}

sub HyperLogLog {

SKIP: {

    skip 'hyperloglog commands require Redis 2.8.9', 5 if versioncmp($redis_version, '2.8.9') == -1;

    my @dt1 = shuffle qw( a a a a a a a a b b b b b b c c c c d e f g h i j k l m );
    my @dt2 = shuffle qw( z z z z z z z z y y y y y y x x x x w v u t s r q p o n );

    is $redis->pfadd("$key:a" => @dt1), 1, 'pfadd';
    is $redis->pfadd("$key:b" => @dt2), 1, 'pfadd';
    is $redis->pfcount("$key:a"), 13, 'pfcount';
    is $redis->pfmerge($key => ("$key:a", "$key:b")), 'OK', 'pfmerge';
    is $redis->pfcount($key), 25, 'pfcount merged';    ## 26 uniques but probabilistic data structure

  }

}

sub Scripting {

  # Change database, add 3 numbers and change back to default database

  my $script_val = <<'  EOF';
    redis.call("SELECT", 1)
    redis.call("SET", KEYS[1], ARGV[1])
    redis.call("INCRBY", KEYS[1], ARGV[2])
    local myid = redis.call("INCRBY", KEYS[1], ARGV[3])
    redis.call("DEL", KEYS[1])
    redis.call("SELECT", 0)
    return myid
  EOF

  # Pull out from a redis list, generate sha1hex for each element and return the array

  my $script_ary = <<'  EOF';
    local intable = redis.call('LRANGE', KEYS[1], 0, -1);
    local outtable = {}
    for _,val in ipairs(intable) do
      table.insert(outtable, redis.sha1hex(val))
    end
    redis.call('DEL', KEYS[1])
    return outtable
  EOF

  my $script_val_sha = sha1_sum(encode 'UTF-8', $script_val);
  my $script_ary_sha = sha1_sum(encode 'UTF-8', $script_ary);

  my $input     = Mojo::Collection->new(1 .. 3)->map(sub   { int(rand(999999)) });
  my $input_ary = Mojo::Collection->new(1 .. 100)->map(sub { int(rand(999999)) });

  $redis->rpush("$key:a", @$input_ary);    # Set up a redis list
  $redis->rpush("$key:b", @$input_ary);    #

  is $redis->eval($script_val, 1, $key, @$input), $input->reduce(sub { $a + $b }), 'eval - single response';
  is_deeply $redis->eval($script_ary, 1, "$key:a"), $input_ary->map(sub { sha1_sum($_[0]) }), 'eval - list response';

  like $redis->eval('return redis.call("INFO", ARGV[1])', 0, 'PERSISTENCE'), qr{^aof_enabled}m,
    'eval - return multiline string';
  is $redis->eval('redis.pcall("INCRBY", KEYS[1], ARGV[1])', 1, $key, 'NOT_A_NUMBER'), undef,
    'eval - redis.pcall failure';

  eval { $redis->eval('redis.call("INCRBY", KEYS[1], ARGV[1])', 1, $key, 'NOT_A_NUMBER') };
  like $@, qr{not an integer}, 'eval - redis.call failure';

  eval { $redis->eval($script_val) };
  like $@, qr{wrong number of arguments}, 'eval - missing arguments';

  eval { $redis->eval('INVALID**LUA', 0) };
  like $@, qr{Error compiling script}, 'eval - compile error';

  is $redis->evalsha($script_val_sha, 1, $key, @$input), $input->reduce(sub { $a + $b }), 'evalsha';
  is_deeply $redis->evalsha($script_ary_sha, 1, "$key:b"), $input_ary->map(sub { sha1_sum($_[0]) }),
    'evalsha - list response';

  eval { $redis->evalsha(sha1_sum('Does not exist'), 1, $key, @$input) };
  like $@, qr{NOSCRIPT}i, 'evalsha - missing script';
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
