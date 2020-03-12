use strict;
use warnings;
use OPCUA::Open62541;

use Test::More tests => 11;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;

ok(my $server = OPCUA::Open62541::Server->new(), "server new");
ok(my $config = $server->getConfig(), "config get");
is($config->setDefault(), "Good", "default set");
no_leaks_ok { $config->setDefault() } "default set leak";

throws_ok { OPCUA::Open62541::ServerConfig::setDefault() }
    (qr/OPCUA::Open62541::ServerConfig::setDefault\(config\) /,
    "config missing");
no_leaks_ok { eval { OPCUA::Open62541::ServerConfig::setDefault() } }
    "config missing leak";

throws_ok { OPCUA::Open62541::ServerConfig::setDefault(1) }
    (qr/config is not of type OPCUA::Open62541::ServerConfig /,
    "config type");
no_leaks_ok { eval { OPCUA::Open62541::ServerConfig::setDefault(1) } }
    "config type leak";

# FIXME: Leads to double free in v1.0/1.0.1. Fixed in master, see
# https://github.com/open62541/open62541/commit/f05bafc25d332d4571b2e42fb42221c2ec3cc98c
# just call it, no way to test easily
#$config->clean();

lives_ok { $config->setCustomHostname("foo\0bar") }
    "custom hostname";
no_leaks_ok { $config->setCustomHostname("foo\0bar") }
    "custom hostname leak";
