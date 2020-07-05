use strict;
use warnings;
use OPCUA::Open62541;

use Test::More tests => 9;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;
use Test::Warn;

ok(my $server = OPCUA::Open62541::Server->new(), "server new");
ok(my $config = $server->getConfig(), "config get");
is(ref($config), "OPCUA::Open62541::ServerConfig", "config class");
no_leaks_ok { $server->getConfig() } "config leak";

throws_ok { OPCUA::Open62541::Server::getConfig() }
    (qr/Usage: OPCUA::Open62541::Server::getConfig\(server\) /,
    "server missing");
no_leaks_ok { eval { OPCUA::Open62541::Server::getConfig() } }
    "server missing leak";
throws_ok { OPCUA::Open62541::Server::getConfig(undef) }
    (qr/Self server is not a OPCUA::Open62541::Server /, "server undef");
no_leaks_ok { eval { OPCUA::Open62541::Server::getConfig(undef) } }
    "server undef leak";
