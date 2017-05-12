use Test::More tests => 21;
require_ok ( 'Redis::hiredis' );
my $h = Redis::hiredis->new();
isa_ok($h, 'Redis::hiredis');

SKIP: {
    skip "No REDISHOST defined", 19 if ( ! defined $ENV{'REDISHOST'} );

    my $host = $ENV{'REDISHOST'};
    my $port = $ENV{'REDISPORT'} || 6379;

    my $r;
    my $c = $h->connect($host, $port);
    is($c, undef, 'connect success');

    my $prefix = "Redis-hiredis-$$-";

    $r = $h->command('zadd '.$prefix.'foo 1 foo');
    is($r, 1, 'zadd');
    $r = $h->command('zadd '.$prefix.'foo 2 bar');
    is($r, 1, 'zadd');
    $r = $h->command('zadd '.$prefix.'foo 4 baz');
    is($r, 1, 'zadd');
    $r = $h->command('zadd '.$prefix.'foo 5 boo');
    is($r, 1, 'zadd');

    $r = $h->command('zrem '.$prefix.'foo boo');
    is($r, 1, 'zrem');

    $r = $h->command('zincrby '.$prefix.'foo 1 bar');
    is($r, 3, 'zincrby');

    $r = $h->command('zrank '.$prefix.'foo bar');
    is($r, 1, 'zrank');

    $r = $h->command('zrevrank '.$prefix.'foo bar');
    is($r, 1, 'zrevrank');

    $r = $h->command('zrange '.$prefix.'foo 1 1');
    is($r->[0], 'bar', 'zrange');

    $r = $h->command('zrevrange '.$prefix.'foo 1 1');
    is($r->[0], 'bar', 'zrevrange');

    $r = $h->command('zrangebyscore '.$prefix.'foo 3 3');
    is($r->[0], 'bar', 'zrangebyscore');

    $r = $h->command('zcount '.$prefix.'foo 3 4');
    is($r, 2, 'zcount');

    $r = $h->command('zcard '.$prefix.'foo');
    is($r, 3, 'zcard');

    $r = $h->command('zscore '.$prefix.'foo bar');
    is($r, 3, 'zscore');

    $r = $h->command('zremrangebyrank '.$prefix.'foo 0 0');
    is($r, 1, 'zremrangebyrank');

    $r = $h->command('zremrangebyscore '.$prefix.'foo 3 4');
    is($r, 2, 'zremrangebyscore');

    $h->command('del foo');
    $h->command('zadd '.$prefix.'foo 1 foo');
    $h->command('zadd '.$prefix.'foo 1 bar');
    $h->command('zadd '.$prefix.'bar 1 bar');
    $h->command('zadd '.$prefix.'bar 1 baz');

    $r = $h->command('zunionstore '.$prefix.'baz 2 '.$prefix.'foo '.$prefix.'bar');
    is($r, 3, 'zunionstore');

    $r = $h->command('zinterstore '.$prefix.'baz 2 '.$prefix.'foo '.$prefix.'bar');
    is($r, 1, 'zinterstore');

    $h->command('del '.$prefix.'foo');
    $h->command('del '.$prefix.'bar');
    $h->command('del '.$prefix.'baz');
};
