use strict;
use warnings;
use OPCUA::Open62541 ':all';

use Test::More tests => 15;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;
use Test::Warn;

ok(my $server = OPCUA::Open62541::Server->new(), "server new");
ok(my $config = $server->getConfig(), "config get");
is($config->setMinimal(8404, ""), STATUSCODE_GOOD, "minimal status");
no_leaks_ok { $config->setMinimal(8404, "") } "minimal status leak";

throws_ok { OPCUA::Open62541::ServerConfig::setMinimal() }
    (qr/Usage:\ OPCUA::Open62541::ServerConfig::setMinimal
    \(config,\ portNumber,\ certificate\)\ /x,
    "config missing");
no_leaks_ok { eval { OPCUA::Open62541::ServerConfig::setMinimal() } }
    "config missing leak";

throws_ok { OPCUA::Open62541::ServerConfig::setMinimal(undef, 8404, "") }
    (qr/config is not of type OPCUA::Open62541::ServerConfig /,
    "config undef");
no_leaks_ok {
    eval { OPCUA::Open62541::ServerConfig::setMinimal(undef, 8404, "") }
} "config undef leak";

throws_ok { OPCUA::Open62541::ServerConfig::setMinimal(1, 8404, "") }
    (qr/config is not of type OPCUA::Open62541::ServerConfig /,
    "config type");
no_leaks_ok {
    eval { OPCUA::Open62541::ServerConfig::setMinimal(1, 8404, "") }
} "config type leak";

warnings_like {
    OPCUA::Open62541::ServerConfig::setMinimal($config, undef, "")
} (qr/Use of uninitialized value in subroutine entry /,
    "port undef warning");
no_leaks_ok {
    no warnings 'uninitialized';
    OPCUA::Open62541::ServerConfig::setMinimal($config, undef, "");
} "port undef leak";

warnings_like {
    OPCUA::Open62541::ServerConfig::setMinimal($config, 8404, undef)
} (qr/Use of uninitialized value in subroutine entry /,
    "certificate undef warning");
no_leaks_ok {
    no warnings 'uninitialized';
    OPCUA::Open62541::ServerConfig::setMinimal($config, 8404, undef);
} "certificate undef leak";
