use Test::More tests => 24;
require_ok ( 'Redis::hiredis' );
my $h = Redis::hiredis->new();
isa_ok($h, 'Redis::hiredis');

SKIP: {
    skip "No REDISHOST defined", 22 if ( ! defined $ENV{'REDISHOST'} );

    my $host = $ENV{'REDISHOST'};
    my $port = $ENV{'REDISPORT'} || 6379;

    my $r;
    my $c = $h->connect($host, $port);
    is($c, undef, 'connect success');

    my $prefix = "Redis-hiredis-$$-";

    $r = $h->command('sadd '.$prefix.'foo foo');
    is($r, 1, 'sadd');
    $r = $h->command('sadd '.$prefix.'foo bar');
    is($r, 1, 'sadd');
    $r = $h->command('sadd '.$prefix.'foo baz');
    is($r, 1, 'sadd');

    $r = $h->command('srem '.$prefix.'foo baz');
    is($r, 1, 'srem');

    $r = $h->command('spop '.$prefix.'foo');
    like($r, qr/(foo|bar)/, 'spop');

    $r = $h->command('sadd '.$prefix.'foo foo');
    $r = $h->command('sadd '.$prefix.'foo bar');
    $r = $h->command('sadd '.$prefix.'foo baz');

    $r = $h->command('smove '.$prefix.'foo '.$prefix.'bar foo');
    is($r, 1, 'smove');

    $r = $h->command('scard '.$prefix.'foo');
    is($r, 2, 'scard');

    $r = $h->command('sismember '.$prefix.'foo bar');
    is($r, 1, 'sismember');
    $r = $h->command('sismember '.$prefix.'foo foo');
    is($r, 0, '! sismember');


    $h->command('del '.$prefix.'foo');
    $h->command('del '.$prefix.'bar');
    $r = $h->command('sadd '.$prefix.'foo foo');
    $r = $h->command('sadd '.$prefix.'foo bar');
    $r = $h->command('sadd '.$prefix.'bar bar');
    $r = $h->command('sadd '.$prefix.'bar baz');

    $r = $h->command('sinter '.$prefix.'foo '.$prefix.'bar');
    ok(ref $r eq 'ARRAY', 'sinter returns array');
    is($r->[0], 'bar', 'sinter');

    $r = $h->command('sinterstore '.$prefix.'baz '.$prefix.'foo '.$prefix.'bar');
    is($r, 1, 'sinterstore');

    $r = $h->command('sunion '.$prefix.'foo '.$prefix.'bar');
    ok(ref $r eq 'ARRAY', 'sunion returns array');
    cmp_ok(scalar(@{$r}), '==', 3, 'sunion 3 members');

    $h->command('del '.$prefix.'baz');
    $r = $h->command('sunionstore '.$prefix.'baz '.$prefix.'foo '.$prefix.'bar');
    is($r, 3, 'sunionstore');

    $r = $h->command('sdiff '.$prefix.'foo '.$prefix.'bar');
    ok(ref $r eq 'ARRAY', 'sdiff returns array');
    is($r->[0], 'foo', 'sdiff');

    $h->command('del '.$prefix.'baz');
    $r = $h->command('sdiffstore '.$prefix.'baz '.$prefix.'foo '.$prefix.'bar');
    is($r, 1, 'sdiffstore');

    $r = $h->command('smembers '.$prefix.'foo');
    ok(ref $r eq 'ARRAY', 'smembers returns array');
    cmp_ok(scalar(@{$r}), '==', 2, 'smembers');

    $r = $h->command('srandmember '.$prefix.'foo');
    like($r, qr/(foo|bar)/, 'srandmember');

    $h->command('del '.$prefix.'foo');
    $h->command('del '.$prefix.'bar');
    $h->command('del '.$prefix.'baz');
};
