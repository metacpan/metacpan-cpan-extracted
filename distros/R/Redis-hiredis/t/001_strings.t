use Test::More tests => 22;
require_ok ( 'Redis::hiredis' );
my $h = Redis::hiredis->new();
isa_ok($h, 'Redis::hiredis');

SKIP: {
    skip "No REDISHOST defined", 20 if ( ! defined $ENV{'REDISHOST'} );

    my $host = $ENV{'REDISHOST'};
    my $port = $ENV{'REDISPORT'} || 6379;

    my $r;
    my $c = $h->connect($host, $port);
    is($c, undef, 'connect success');

    my $prefix = "Redis-hiredis-$$-";

    $r = $h->command("set ".$prefix."foo bar");
    is($r, 'OK', 'set');
    $r = $h->command("set ".$prefix."bar baz");
    is($r, 'OK', 'set');

    $r = $h->command("get ".$prefix."foo");
    is($r, 'bar', 'get');
    $r = $h->command("get ".$prefix."bar");
    is($r, 'baz', 'get');

    $r = $h->command("getset ".$prefix."foo baz");
    is($r, 'bar', 'getset');

    $r = $h->command("mget ".$prefix."foo ".$prefix."bar");
    ok(ref $r eq 'ARRAY', 'mget returns array');
    ok(scalar(@{$r}) == 2, 'mget correct size');

    $r = $h->command("setnx ".$prefix."boo berry");
    is($r, 1, 'setnx');
    $r = $h->command("setnx ".$prefix."foo berry");
    is($r, 0, 'setnx failure');

    $r = $h->command("setex ".$prefix."bum 86400 boo");
    is($r, 'OK', 'setex');

    $r = $h->command("mset ".$prefix."a 1 ".$prefix."b 2");
    is($r, 'OK', 'mset');
    $r = $h->command("msetnx ".$prefix."c 3 ".$prefix."d 4");
    is($r, 1, 'msetnx');
    $r = $h->command("msetnx ".$prefix."d 4 ".$prefix."e 5");
    is($r, 0, 'msetnx failure');

    $r = $h->command('incr '.$prefix.'baz');
    is($r, 1, 'incr');
    $r = $h->command('decr '.$prefix.'baz');
    is($r, 0, 'decr');

    $r = $h->command('incrby '.$prefix.'baz 3');
    is($r, 3, 'incrby');
    $r = $h->command('decrby '.$prefix.'baz 2');
    is($r, 1, 'decr');

    $r = $h->command('append '.$prefix.'foo bar');
    is($r, 6, 'append');

    $r = $h->command('substr '.$prefix.'foo 3 6');
    is($r, 'bar', 'substr');

    $h->command('del '.$prefix.'foo');
    $h->command('del '.$prefix.'bar');
    $h->command('del '.$prefix.'boo');
    $h->command('del '.$prefix.'baz');
    $h->command('del '.$prefix.'a');
    $h->command('del '.$prefix.'b');
    $h->command('del '.$prefix.'c');
    $h->command('del '.$prefix.'d');
};
