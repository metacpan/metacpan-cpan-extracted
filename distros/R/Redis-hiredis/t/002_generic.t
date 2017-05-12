use Test::More tests => 18;
use Data::Dumper;
require_ok ( 'Redis::hiredis' );
my $h = Redis::hiredis->new();
isa_ok($h, 'Redis::hiredis');

SKIP: {
    skip "No REDISHOST defined", 16 if ( ! defined $ENV{'REDISHOST'} );

    my $host = $ENV{'REDISHOST'};
    my $port = $ENV{'REDISPORT'} || 6379;

    my $r;
    my $c = $h->connect($host, $port);
    is($c, undef, 'connect success');

    my $prefix = "Redis-hiredis-$$-";

    $h->command("set ".$prefix."foo bar");
    $h->command("set ".$prefix."baz foo");
    $r = $h->command('exists '.$prefix.'foo');
    is($r, 1, 'exists');

    $r = $h->command('type '.$prefix.'foo');
    is($r, 'string', 'type');

    $r = $h->command('keys '.$prefix.'fo*');
    is($r->[0], $prefix.'foo', 'keys');

    $r = $h->command('randomkey');
    isnt($r, undef, 'randomkey');

    $r = $h->command('rename '.$prefix.'foo '.$prefix.'bar');
    is($r, 'OK', 'rename');

    $r = $h->command('renamenx '.$prefix.'bar '.$prefix.'awesomesauce');
    is($r, 1, 'renamenx');

    $r = $h->command('renamenx '.$prefix.'baz '.$prefix.'awesomesauce');
    is($r, 0, 'renamenx to existing key');

    $r = $h->command('dbsize');
    cmp_ok($r, '>=', 1, 'dbsize');
     
    $r = $h->command('move '.$prefix.'baz 1');
    is($r, 1, 'move');

    $r = $h->command('select 1');
    is($r, 'OK', 'select');

    $r = $h->command('del '.$prefix.'baz');
    is($r, 1, 'del');
    $r = $h->command('select 0');

    $h->command('set '.$prefix.'baz bar');
    $r = $h->command('expire '.$prefix.'baz 86400');
    is($r, 1, 'expire');

    $r = $h->command('ttl '.$prefix.'baz');
    cmp_ok($r, '>', 86300, 'ttl');

    $h->command("del ".$prefix."awesomesauce");
    $h->command("del ".$prefix."baz");

    SKIP: {
        skip "not destroying data", 2 unless $ENV{'REDIS_TEST_DESTRUCTIVE'};
        $r = $h->command('flushdb');
        is($r, 'OK', 'flushdb');
        $r = $h->command('flushall');
        is($r, 'OK', 'flushall');
    };
};
