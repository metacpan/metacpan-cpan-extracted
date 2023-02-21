use strict;
use warnings;
use OPCUA::Open62541;

use Test::More tests => 6;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;

ok(my $server = OPCUA::Open62541::Server->new(), "server new");
lives_ok { $server->setAdminSessionContext(undef) } "server context";
no_leaks_ok {
    my $server = OPCUA::Open62541::Server->new();
    $server->setAdminSessionContext(undef);
} "server context leak";

lives_ok { $server->setAdminSessionContext("foobar") } "server context twice";
no_leaks_ok {
    my $server = OPCUA::Open62541::Server->new();
    $server->setAdminSessionContext("foo");
    $server->setAdminSessionContext("bar");
} "server context twice leak";
