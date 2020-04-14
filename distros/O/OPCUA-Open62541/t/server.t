use strict;
use warnings;
use OPCUA::Open62541;

use Test::More tests => 11;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;
use Test::Warn;

ok(my $server = OPCUA::Open62541::Server->new(), "server new");
is(ref($server), "OPCUA::Open62541::Server", "server new class");
no_leaks_ok { OPCUA::Open62541::Server->new()} "server new leak";

throws_ok { OPCUA::Open62541::Server::new() }
    (qr/OPCUA::Open62541::Server::new\(class\) /, "class missing");
no_leaks_ok { eval { OPCUA::Open62541::Server::new() } } "class missing leak";

warning_like {
    throws_ok { OPCUA::Open62541::Server::new(undef) }
	(qr/Class '' is not OPCUA::Open62541::Server /, "class undef");
} (qr/uninitialized value in subroutine entry /, "class undef warning");
no_leaks_ok {
    no warnings 'uninitialized';
    eval { OPCUA::Open62541::Server::new(undef) }
} "class undef leak";

throws_ok { OPCUA::Open62541::Server::new("subclass") }
    (qr/Class 'subclass' is not OPCUA::Open62541::Server /, "subclass");
no_leaks_ok { eval { OPCUA::Open62541::Server::new("subclass") } }
    "subclass leak";
