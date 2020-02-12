use strict;
use warnings;
use OPCUA::Open62541;

use Test::More tests => 8;
use Test::NoWarnings;

my $s = OPCUA::Open62541::Server->new();
ok($s, "server new");

my $c = $s->getConfig();
ok($c, "config get");

is($c->setDefault(), 0, "default status");

eval { OPCUA::Open62541::ServerConfig::setDefault() };
ok($@, "config missing");
like($@, qr/OPCUA::Open62541::ServerConfig::setDefault\(config\) /,
    "config missing error");

eval { OPCUA::Open62541::ServerConfig::setDefault(1) };
ok($@, "config type");
like($@, qr/config is not of type OPCUA::Open62541::ServerConfig /,
    "config type error");
