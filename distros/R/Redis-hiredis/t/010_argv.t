use Test::More tests => 5;
require_ok ( 'Redis::hiredis' );
my $h = Redis::hiredis->new();
isa_ok($h, 'Redis::hiredis');

SKIP: {
    skip "No REDISHOST defined", 3 if ( ! defined $ENV{'REDISHOST'} );

    my $host = $ENV{'REDISHOST'};
    my $port = $ENV{'REDISPORT'} || 6379;

    my $r;
    my $c = $h->connect($host, $port);
    is($c, undef, 'connect success');

    my $prefix = "Redis-hiredis-$$-";

    $r = $h->command(["set", $prefix."foo", "this is a test"]);
    is($r, 'OK', 'set arr ref');
    $r = $h->command("set", $prefix."foo", "this is a test");
    is($r, 'OK', 'set va_list');
};
