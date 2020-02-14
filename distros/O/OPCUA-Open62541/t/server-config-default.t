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

# FIXME: Leads to double free in v1.0/1.0.1. Fixed in master, see
# https://github.com/open62541/open62541/commit/f05bafc25d332d4571b2e42fb42221c2ec3cc98c
# just call it, no way to test easily
#$c->clean();
$c->setCustomHostname("foo\0bar");
