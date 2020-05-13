use strict;
use warnings;
use OPCUA::Open62541;

use Test::More tests => 9;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;

ok(my $client = OPCUA::Open62541::Client->new(), "client new");

ok(my $config = $client->getConfig(), "config get");
is(ref($config), "OPCUA::Open62541::ClientConfig", "config class");
no_leaks_ok { $client->getConfig() } "config leak";

throws_ok { OPCUA::Open62541::Client::getConfig() }
    (qr/Usage: OPCUA::Open62541::Client::getConfig\(client\) /,
    "config missing");
no_leaks_ok { eval { OPCUA::Open62541::Client::getConfig() } }
    "config missing leak";
throws_ok { OPCUA::Open62541::Client::getConfig(undef) }
    (qr/Self client is not a OPCUA::Open62541::Client /,
    "config undef");
no_leaks_ok { eval { OPCUA::Open62541::Client::getConfig(undef) } }
    "config undef leak";
