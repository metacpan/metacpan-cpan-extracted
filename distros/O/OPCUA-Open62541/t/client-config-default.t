use strict;
use warnings;
use OPCUA::Open62541;

use Test::More tests => 9;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;

ok(my $client = OPCUA::Open62541::Client->new(), "client new");
ok(my $config = $client->getConfig(), "config get");
is($config->setDefault(), "Good", "default set");
no_leaks_ok { $config->setDefault() } "default set leak";

throws_ok { OPCUA::Open62541::ClientConfig::setDefault() }
    (qr/OPCUA::Open62541::ClientConfig::setDefault\(config\) /,
    "config missing");
no_leaks_ok { eval { OPCUA::Open62541::ClientConfig::setDefault() } }
    "config missing leak";

throws_ok { OPCUA::Open62541::ClientConfig::setDefault(1) }
    (qr/config is not of type OPCUA::Open62541::ClientConfig /,
    "config type");
no_leaks_ok { eval { OPCUA::Open62541::ClientConfig::setDefault(1) } }
    "config type leak";
