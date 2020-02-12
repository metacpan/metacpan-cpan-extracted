use strict;
use warnings;
use OPCUA::Open62541;

use Test::More tests => 20;
use Test::NoWarnings;
use Test::Warn;

my $s = OPCUA::Open62541::Server->new();
ok($s, "server new");

my $c = $s->getConfig();
ok($c, "config get");
is(ref($c), "OPCUA::Open62541::ServerConfig", "class");

my $t = OPCUA::Open62541::Server->newWithConfig($c);
ok(defined($t), "server defined");
ok($t, "server new");
is(ref($t), "OPCUA::Open62541::Server", "class");

eval { OPCUA::Open62541::Server::newWithConfig() };
ok($@, "class missing");
like($@, qr/OPCUA::Open62541::Server::newWithConfig\(class, config\) /,
    "class missing error");

eval { OPCUA::Open62541::Server->newWithConfig() };
ok($@, "config missing");
like($@, qr/OPCUA::Open62541::Server::newWithConfig\(class, config\) /,
    "config missing error");

warnings_like { eval { OPCUA::Open62541::Server::newWithConfig(undef, $c) } }
    (qr/uninitialized value in subroutine entry /, "class undef warning");

eval {
    no warnings 'uninitialized';
    OPCUA::Open62541::Server::newWithConfig(undef, $c)
};
ok($@, "class undef");
like($@, qr/class '' is not OPCUA::Open62541::Server /, "class undef error");

eval { OPCUA::Open62541::Server->newWithConfig(undef) };
ok($@, "config undef");
like($@, qr/config is not of type OPCUA::Open62541::ServerConfig /,
    "config undef error");

eval { OPCUA::Open62541::Server->newWithConfig($s) };
ok($@, "config type");
like($@, qr/config is not of type OPCUA::Open62541::ServerConfig /,
    "config type error");

eval { OPCUA::Open62541::Server::newWithConfig("subclass", $c) };
ok($@, "class subclass");
like($@, qr/class 'subclass' is not OPCUA::Open62541::Server /,
    "class subclass error");
