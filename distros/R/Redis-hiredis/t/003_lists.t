use Test::More tests => 25;
require_ok ( 'Redis::hiredis' );
my $h = Redis::hiredis->new();
isa_ok($h, 'Redis::hiredis');

SKIP: {
    skip "No REDISHOST defined", 23 if ( ! defined $ENV{'REDISHOST'} );

    my $host = $ENV{'REDISHOST'};
    my $port = $ENV{'REDISPORT'} || 6379;

    my $r;
    my $c = $h->connect($host, $port);
    is($c, undef, 'connect success');

    my $prefix = "Redis-hiredis-$$-";

    $r = $h->command("rpush ".$prefix."foo bar");
    is($r, 1, 'rpush');
    $r = $h->command("rpush ".$prefix."foo baz");
    is($r, 2, 'rpush');
    $r = $h->command("rpush ".$prefix."foo boo");
    is($r, 3, 'rpush');
    $r = $h->command("lpush ".$prefix."foo foo");
    is($r, 4, 'lpush');

    $r = $h->command("llen ".$prefix."foo");
    is($r, 4, 'llen');

    $r = $h->command("lrange ".$prefix."foo 0 1");
    ok(ref $r eq 'ARRAY', 'lrange returns array');
    ok(scalar(@{$r}) == 2, 'lrange correct size');
    is($r->[0], 'foo', 'lrange');
    is($r->[1], 'bar', 'lrange');

    $r = $h->command("ltrim ".$prefix."foo 0 2");
    is($r, 'OK', 'ltrim');

    $r = $h->command("lindex ".$prefix."foo 0");
    is($r, 'foo', 'lindex');

    $r = $h->command("lset ".$prefix."foo 1 boo");
    is($r, 'OK', 'lset');
    $r = $h->command("lrem ".$prefix."foo 1 boo");
    is($r, 1, 'lrem');

    $r = $h->command("lpop ".$prefix."foo");
    is($r, 'foo', 'lpop');
    $r = $h->command("rpop ".$prefix."foo");
    is($r, 'baz', 'rpop');

    $h->command('del '.$prefix.'foo');
    $r = $h->command("rpush ".$prefix."foo bar");
    $r = $h->command("rpush ".$prefix."foo baz");
    $r = $h->command("rpush ".$prefix."foo boo");
    $r = $h->command("lpush ".$prefix."foo foo");


    $r = $h->command("blpop ".$prefix."foo 10");
    ok(ref $r eq 'ARRAY', 'blpop returns array');
    is($r->[0], $prefix.'foo', 'blpop');
    is($r->[1], 'foo', 'blpop');
    $r = $h->command("brpop ".$prefix."foo 10");
    ok(ref $r eq 'ARRAY', 'brpop returns array');
    is($r->[0], $prefix.'foo', 'brpop');
    is($r->[1], 'boo', 'brpop');

    $r = $h->command("rpoplpush ".$prefix."foo ".$prefix."bar");
    is($r, 'baz', 'rpoplpush');
    $h->command('del '.$prefix.'foo');
    $h->command('del '.$prefix.'bar');
};
