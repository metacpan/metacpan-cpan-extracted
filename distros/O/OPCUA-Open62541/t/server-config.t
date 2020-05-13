use strict;
use warnings;
use OPCUA::Open62541;

use Test::More tests => 25;
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

ok(my $server2 = OPCUA::Open62541::Server->newWithConfig($config),
    "server2 new");
is(ref($server2), "OPCUA::Open62541::Server", "server2 class");
no_leaks_ok { OPCUA::Open62541::Server->newWithConfig($config) }
    "server2 leak";

throws_ok { OPCUA::Open62541::Server::newWithConfig() }
    (qr/OPCUA::Open62541::Server::newWithConfig\(class, config\) /,
    "class missing");
no_leaks_ok { eval { OPCUA::Open62541::Server::newWithConfig() } }
    "class missing leak";

throws_ok { OPCUA::Open62541::Server->newWithConfig() }
    (qr/OPCUA::Open62541::Server::newWithConfig\(class, config\) /,
    "config missing");
no_leaks_ok { eval { OPCUA::Open62541::Server->newWithConfig() } }
    "config missing leak";

warning_like {
    throws_ok { OPCUA::Open62541::Server::newWithConfig(undef, $config) }
	(qr/Class '' is not OPCUA::Open62541::Server /, "class undef");
} (qr/uninitialized value in subroutine entry /, "class undef warning");
no_leaks_ok {
    no warnings 'uninitialized';
    eval { OPCUA::Open62541::Server::newWithConfig(undef, $config) }
} "class undef leak";

throws_ok { OPCUA::Open62541::Server->newWithConfig(undef) }
    (qr/Parameter config is undefined /,
    "config undef");
no_leaks_ok { eval { OPCUA::Open62541::Server->newWithConfig(undef) } }
    "config undef leak";

throws_ok { OPCUA::Open62541::Server->newWithConfig($server) }
    (qr/Parameter config is not a OPCUA::Open62541::ServerConfig /,
    "config type");
no_leaks_ok { eval { OPCUA::Open62541::Server->newWithConfig($server) } }
    "config type leak";

throws_ok { OPCUA::Open62541::Server::newWithConfig("subclass", $config) }
    (qr/Class 'subclass' is not OPCUA::Open62541::Server /, "subclass");
no_leaks_ok {
    eval { OPCUA::Open62541::Server::newWithConfig("subclass", $config) }
} "subclass leak";
