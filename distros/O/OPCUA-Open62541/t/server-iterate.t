use strict;
use warnings;
use OPCUA::Open62541 ':all';
use POSIX qw(sigaction SIGALRM);

use Test::More tests => 17;
use Test::NoWarnings;

my $s = OPCUA::Open62541::Server->new();
ok($s, "server");

my $c = $s->getConfig();
ok($s, "config");

my $d = $c->setDefault();
is($d, STATUSCODE_GOOD, "default");

my $r = $s->run_startup();
is($r, STATUSCODE_GOOD, "startup");

$r = $s->run_iterate(0);
cmp_ok($r, '>', 0, "iterate");
foreach (1..10) {
    $r = $s->run_iterate(1);
    is($r, 0, "iterate");
}

$r = $s->run_shutdown();
is($r, STATUSCODE_GOOD, "shutdown");
