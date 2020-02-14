use strict;
use warnings;
use OPCUA::Open62541 ':all';

use Test::More tests => 8;
use Test::NoWarnings;

my $s = OPCUA::Open62541::Server->new();
ok($s, "server new");

my $c = $s->getConfig();
ok($c, "config get");

is($c->setMinimal(8404, ""), STATUSCODE_GOOD, "set minimal config status");

eval { OPCUA::Open62541::ServerConfig::setMinimal() };
ok($@, "config missing");
like($@, qr/Usage: OPCUA::Open62541::ServerConfig::setMinimal\(config, portNumber, certificate\) /,
    "usage error");

eval { OPCUA::Open62541::ServerConfig::setMinimal(1, 1, undef) };
ok($@, "config type");
like($@, qr/config is not of type OPCUA::Open62541::ServerConfig /,
    "config type error");
