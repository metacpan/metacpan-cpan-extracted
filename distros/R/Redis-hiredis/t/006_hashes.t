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

    $r = $h->command('hset '.$prefix.'foo name foo');
    is($r, 1, 'hset');
    $r = $h->command('hset '.$prefix.'foo value bar');
    is($r, 1, 'hset');
    $r = $h->command('hset '.$prefix.'foo desc description');
    is($r, 1, 'hset');

    $r = $h->command('hget '.$prefix.'foo name');
    is($r, 'foo', 'hget');

    $r = $h->command('hmget '.$prefix.'foo name value');
    is($r->[0], 'foo', 'hmget');
    is($r->[1], 'bar', 'hmget');

    $r = $h->command('hmset '.$prefix.'foo name baz value 1');
    is($r, 'OK', 'hmset');

    $r = $h->command('hincrby '.$prefix.'foo value 1');
    is($r, 2, 'hincrby');

    $r = $h->command('hexists '.$prefix.'foo value');
    is($r, 1, 'hexists');
    $r = $h->command('hexists '.$prefix.'foo foobar');
    is($r, 0, '! hexists');

    $r = $h->command('hdel '.$prefix.'foo value');
    is($r, 1, 'hdel');

    $r = $h->command('hlen '.$prefix.'foo');
    is($r, 2, 'hlen');

    $r = $h->command('hkeys '.$prefix.'foo');
    ok(ref $r eq 'ARRAY', 'hkeys returns array');
    cmp_ok(scalar(@{$r}), '==', 2, 'hkeys returns correct # of keys');

    $r = $h->command('hvals '.$prefix.'foo');
    ok(ref $r eq 'ARRAY', 'hvals returns array');
    cmp_ok(scalar(@{$r}), '==', 2, 'hvals returns correct # of keys');

    $r = $h->command('hgetall '.$prefix.'foo');
    ok(ref $r eq 'ARRAY', 'hgetall returns array');
    cmp_ok(scalar(@{$r}), '==', 4, 'hgetall returns correct # of keys');

    $h->command('del '.$prefix.'foo');
};
