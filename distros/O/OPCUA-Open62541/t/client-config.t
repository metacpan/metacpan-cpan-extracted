use strict;
use warnings;
use OPCUA::Open62541;

use Test::More tests => 4;
use Test::NoWarnings;

my $s = OPCUA::Open62541::Client->new();
ok($s, "client new");

my $c = $s->getConfig();
ok($c, "config get");
is(ref($c), "OPCUA::Open62541::ClientConfig", "class");
