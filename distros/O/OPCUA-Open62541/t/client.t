use strict;
use warnings;
use OPCUA::Open62541;

use Test::More tests => 11;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;
use Test::Warn;

ok(my $client = OPCUA::Open62541::Client->new(), "client new");
is(ref($client), "OPCUA::Open62541::Client", "client new class");
no_leaks_ok { OPCUA::Open62541::Client->new() } "client new leak";

throws_ok { OPCUA::Open62541::Client::new() }
    (qr/OPCUA::Open62541::Client::new\(class\) /, "class missing");
no_leaks_ok { eval { OPCUA::Open62541::Client::new() } } "class missing leak";

warning_like {
    throws_ok { OPCUA::Open62541::Client::new(undef) }
	(qr/Class '' is not OPCUA::Open62541::Client /, "class undef");
} (qr/uninitialized value in subroutine entry /, "class undef warn");
no_leaks_ok {
    no warnings 'uninitialized';
    eval { OPCUA::Open62541::Client::new(undef) };
} "class undef leak";

throws_ok { OPCUA::Open62541::Client::new("subclass") }
    (qr/Class 'subclass' is not OPCUA::Open62541::Client /, "subclass");
no_leaks_ok { eval { OPCUA::Open62541::Client::new("subclass") } }
    "subclass leak";
