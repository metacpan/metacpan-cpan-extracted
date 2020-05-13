# the typemap must find invalid SV objects passed to the functions

use strict;
use warnings;
use OPCUA::Open62541 qw(:STATUSCODE :TYPES);

use OPCUA::Open62541::Test::Server;
use Test::More tests => OPCUA::Open62541::Test::Server::planning_nofork() + 105;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;
use Test::Warn;

### create some objects upfront

# server uses variant parameter, output parameter, and optional parameter

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
my %nodes = $server->setup_complex_objects();
my %nodeid = %{$nodes{some_variable_0}{nodeId}};
my @addargs = (
    $nodes{some_variable_0}{nodeId},
    $nodes{some_variable_0}{parentNodeId},
    $nodes{some_variable_0}{referenceTypeId},
    $nodes{some_variable_0}{browseName},
    $nodes{some_variable_0}{typeDefinition},
    $nodes{some_variable_0}{attributes},
    0
);

# client needed to tests wrong type

ok(my $client = OPCUA::Open62541::Client->new(), "client");
is(ref($client), "OPCUA::Open62541::Client", "client ref");

### variant has simple constructor, so it is easy to test

my $package = 'OPCUA::Open62541';

# variant constructor new

ok(my $variant = OPCUA::Open62541::Variant->new(), "new");
is(ref($variant), "OPCUA::Open62541::Variant", "new ref");
no_leaks_ok { OPCUA::Open62541::Variant->new() } "new leak";

throws_ok { OPCUA::Open62541::Variant::new() }
    (qr/Usage: ${package}::Variant::new\(class\) /,
    "new usage class");
no_leaks_ok { eval { OPCUA::Open62541::Variant::new() } }
    "new usage class leak";

throws_ok { OPCUA::Open62541::Variant->new("") }
    (qr/Usage: ${package}::Variant::new\(class\) /,
    "new usage parameter");
no_leaks_ok { eval { OPCUA::Open62541::Variant->new("") } }
    "new usage parameter leak";

throws_ok {
    no warnings;
    OPCUA::Open62541::Variant::new(undef);
} (qr/new: Class '' is not ${package}::Variant /,
    "new undef");
warning_like { eval { OPCUA::Open62541::Variant::new(undef) } }
    (qr/Use of uninitialized value in subroutine entry at /,
    "new undef warn");
no_leaks_ok { eval {
    no warnings;
    OPCUA::Open62541::Variant::new(undef);
} } "new undef leak";

throws_ok { OPCUA::Open62541::Variant::new("OPCUA::Open62541::Client") }
    (qr/new: Class 'OPCUA::Open62541::Client' is not ${package}::Variant /,
    "new class type");
no_leaks_ok { eval {
    OPCUA::Open62541::Variant::new("OPCUA::Open62541::Client");
} } "new class type leak";

# variant destructor destroy

# XXX
# cannot call the correct form as it would cause a double free
# it is always called automatically
SKIP: {
    skip "test would crash: explicit destroy causes double free", 2;
lives_ok { OPCUA::Open62541::Variant::DESTROY($variant) }
    "destroy explicit";
no_leaks_ok { OPCUA::Open62541::Variant::DESTROY($variant) }
    "destroy explicit leak";
}

throws_ok { OPCUA::Open62541::Variant::DESTROY() }
    (qr/Usage: ${package}::Variant::DESTROY\(variant\) /,
    "destroy usage class");
no_leaks_ok { eval { OPCUA::Open62541::Variant::DESTROY() } }
    "destroy usage class leak";

throws_ok { OPCUA::Open62541::Variant::DESTROY($variant, "") }
    (qr/Usage: ${package}::Variant::DESTROY\(variant\) /,
    "destroy usage parameter");
no_leaks_ok { eval { OPCUA::Open62541::Variant::DESTROY($variant, "") } }
    "destroy usage parameter leak";

throws_ok { OPCUA::Open62541::Variant::DESTROY($client) }
    (qr/DESTROY: Self variant is not a ${package}::Variant /,
    "destroy self type");
no_leaks_ok { eval {
    OPCUA::Open62541::Variant::DESTROY($client);
} } "destroy self type leak";

# variant method isEmpty()

ok(OPCUA::Open62541::Variant::isEmpty($variant), "isempty");

throws_ok { OPCUA::Open62541::Variant::isEmpty() }
    (qr/Usage: ${package}::Variant::isEmpty\(variant\) /,
    "isempty usage class");
no_leaks_ok { eval { OPCUA::Open62541::Variant::isEmpty() } }
    "isempty usage class leak";

throws_ok { OPCUA::Open62541::Variant::isEmpty($variant, "") }
    (qr/Usage: ${package}::Variant::isEmpty\(variant\) /,
    "isempty usage parameter");
no_leaks_ok { eval { OPCUA::Open62541::Variant::isEmpty($variant, "") } }
    "isempty usage parameter leak";

throws_ok { OPCUA::Open62541::Variant::isEmpty($client) }
    (qr/isEmpty: Self variant is not a ${package}::Variant /,
    "isempty self type");
no_leaks_ok { eval {
    OPCUA::Open62541::Variant::isEmpty($client);
} } "isempty self type leak";

### server uses variant as parameter

my %value = (
    Variant_type	=> TYPES_INT32,
    Variant_scalar	=> 23,
);

my $outvalue;

# server method writeValue with input variant

is($server->{server}->writeValue(\%nodeid, {}), STATUSCODE_GOOD,
    "write empty value");
no_leaks_ok { $server->{server}->writeValue(\%nodeid, {}) }
    "write empty value leak";

is($server->{server}->writeValue(\%nodeid, \%value), STATUSCODE_GOOD,
    "write value");
no_leaks_ok { $server->{server}->writeValue(\%nodeid, \%value) }
    "write value leak";

throws_ok { $server->{server}->writeValue(\%nodeid) }
    (qr/Usage: ${package}::Server::writeValue\(server, nodeId, value\) /,
    "write value usage");
no_leaks_ok { eval { $server->{server}->writeValue(\%nodeid) } }
    "write value usage leak";

throws_ok { $server->{server}->writeValue(\%nodeid, undef) }
    (qr/writeValue: Parameter value is undefined /,
    "write value undef");
no_leaks_ok { eval { $server->{server}->writeValue(\%nodeid, undef) } }
    "write value undef leak";

throws_ok { $server->{server}->writeValue(\%nodeid, 77) }
    (qr/Variant: Not a HASH reference /,
    "write value number");
no_leaks_ok { eval { $server->{server}->writeValue(\%nodeid, 77) } }
    "write value number leak";

$outvalue = 5;
throws_ok { $server->{server}->writeValue(\%nodeid, $outvalue) }
    (qr/Variant: Not a HASH reference /,
    "write value variable");
$outvalue = 5;
no_leaks_ok { eval { $server->{server}->writeValue(\%nodeid, $outvalue) } }
    "write value variable leak";

throws_ok { $server->{server}->writeValue(\%nodeid, []) }
    (qr/Variant: Not a HASH reference /,
    "write value array");
no_leaks_ok { eval { $server->{server}->writeValue(\%nodeid, []) } }
    "write value array leak";

throws_ok { $server->{server}->writeValue(\%nodeid, {foo=>"bar"}) }
    (qr/Variant: No Variant_type in HASH /,
    "write value hash");
no_leaks_ok { eval { $server->{server}->writeValue(\%nodeid, {foo=>"bar"}) } }
    "write value hash leak";

$outvalue = {};
throws_ok { $server->{server}->writeValue(\%nodeid, \$outvalue) }
    (qr/writeValue: Parameter value is not scalar or array or hash /,
    "write value hashref");
$outvalue = {};
no_leaks_ok { eval { $server->{server}->writeValue(\%nodeid, \$outvalue) } }
    "write value hashref leak";

throws_ok { $server->{server}->writeValue(\%nodeid, $client) }
    (qr/writeValue: Parameter value is not scalar or array or hash /,
    "write client type");
is(ref($client), 'OPCUA::Open62541::Client', "write client ref");
no_leaks_ok { eval { $server->{server}->writeValue(\%nodeid, $client) } }
    "write client type leak";

throws_ok { $server->{server}->writeValue(\%nodeid, $variant) }
    (qr/writeValue: Parameter value is not scalar or array or hash /,
    "write variant type");
is(ref($variant), 'OPCUA::Open62541::Variant', "write variant ref");
no_leaks_ok { eval { $server->{server}->writeValue(\%nodeid, $variant) } }
    "write variant type leak";

# server method readValue with output variant

undef $outvalue;
is($server->{server}->readValue(\%nodeid, \$outvalue), STATUSCODE_GOOD,
    "read value");
is(ref($outvalue), 'HASH', "read value ref");
is_deeply($outvalue, \%value, "read value content");
undef $outvalue;
no_leaks_ok { $server->{server}->readValue(\%nodeid, \$outvalue) }
    "read value leak";

throws_ok { $server->{server}->readValue(\%nodeid) }
    (qr/Usage: ${package}::Server::readValue\(server, nodeId, outValue\) /,
    "read outvalue usage");
no_leaks_ok { eval { $server->{server}->readValue(\%nodeid) } }
    "read outvalue usage leak";

throws_ok { $server->{server}->readValue(\%nodeid, undef) }
    (qr/readValue: Output parameter outValue is undefined /,
    "read outvalue undef");
no_leaks_ok { eval { $server->{server}->readValue(\%nodeid, undef) } }
    "read outvalue undef leak";

throws_ok { $server->{server}->readValue(\%nodeid, 77) }
    (qr/readValue: Output parameter outValue is not a scalar reference /,
    "read outvalue number");
no_leaks_ok { eval { $server->{server}->readValue(\%nodeid, 77) } }
    "read outvalue number leak";

$outvalue = 5;
throws_ok { $server->{server}->readValue(\%nodeid, $outvalue) }
    (qr/readValue: Output parameter outValue is not a scalar reference /,
    "read outvalue variable");
$outvalue = 5;
no_leaks_ok { eval { $server->{server}->readValue(\%nodeid, $outvalue) } }
    "read outvalue variable leak";

throws_ok { $server->{server}->readValue(\%nodeid, []) }
    (qr/readValue: Output parameter outValue is not a scalar reference /,
    "read outvalue array");
no_leaks_ok { eval { $server->{server}->readValue(\%nodeid, []) } }
    "read outvalue array leak";

throws_ok { $server->{server}->readValue(\%nodeid, {}) }
    (qr/readValue: Output parameter outValue is not a scalar reference /,
    "read outvalue hash");
no_leaks_ok { eval { $server->{server}->readValue(\%nodeid, {}) } }
    "read outvalue hash leak";

$outvalue = [];
is($server->{server}->readValue(\%nodeid, \$outvalue), STATUSCODE_GOOD,
    "read outvalue arrayref");
$outvalue = [];
no_leaks_ok { $server->{server}->readValue(\%nodeid, \$outvalue) }
    "read outvalue arrayref leak";

$outvalue = {};
is($server->{server}->readValue(\%nodeid, \$outvalue), STATUSCODE_GOOD,
    "read outvalue hashref");
is(ref($outvalue), 'HASH', "read outvalue ref");
$outvalue = {};
no_leaks_ok { $server->{server}->readValue(\%nodeid, \$outvalue) }
    "read outvalue hashref leak";

throws_ok { $server->{server}->readValue(\%nodeid, $client) }
    (qr/readValue: Output parameter outValue is not a scalar reference /,
    "read client type");
no_leaks_ok { eval { $server->{server}->readValue(\%nodeid, $client) } }
    "read client type leak";
is(ref($client), 'OPCUA::Open62541::Client', "read client ref");

throws_ok { $server->{server}->readValue(\%nodeid, $variant) }
    (qr/readValue: Output parameter outValue is not a scalar reference /,
    "read outvalue variant");
no_leaks_ok { eval { $server->{server}->readValue(\%nodeid, $variant) } }
    "read outvalue variant leak";
is(ref($variant), 'OPCUA::Open62541::Variant', "read variant ref");

### server uses nodeid as optional parameter

# delete node to call add node afterwards

is($server->{server}->deleteNode(\%nodeid, 0), STATUSCODE_GOOD,
    "delete node");
is($server->{server}->addVariableNode(@addargs, undef), STATUSCODE_GOOD,
    "add node");
no_leaks_ok {
    $server->{server}->deleteNode(\%nodeid, 0);
    $server->{server}->addVariableNode(@addargs, undef)
} "add node leak";
is($server->{server}->addVariableNode(@addargs, undef),
    STATUSCODE_BADNODEIDEXISTS,
    "add node exists");

# server method addVariableNode with output nodeid

my $addparams = "server, requestedNewNodeId, parentNodeId, referenceTypeId, ".
    "browseName, typeDefinition, attr, nodeContext, outoptNewNodeId";
my $outnode = "Output parameter outoptNewNodeId";

throws_ok { $server->{server}->addVariableNode(@addargs) }
    (qr/Usage: ${package}::Server::addVariableNode\($addparams\) /,
    "add node usage");
no_leaks_ok { eval { $server->{server}->addVariableNode(@addargs) } }
    "add node usage leak";

throws_ok { $server->{server}->addVariableNode(@addargs, 77) }
    (qr/addVariableNode: ${outnode} is not a scalar reference /,
    "add node out number");
no_leaks_ok { eval { $server->{server}->addVariableNode(@addargs, 77) } }
    "add node out number leak";

my $outnodeid = 5;
throws_ok { $server->{server}->addVariableNode(@addargs, $outnodeid) }
    (qr/addVariableNode: ${outnode} is not a scalar reference /,
    "add node out variable");
$outnodeid = 5;
no_leaks_ok { eval {
    $server->{server}->addVariableNode(@addargs, $outnodeid)
} } "add node out variable leak";

throws_ok { $server->{server}->addVariableNode(@addargs, []) }
    (qr/addVariableNode: ${outnode} is not a scalar reference /,
    "add node out array");
no_leaks_ok { eval {
    $server->{server}->addVariableNode(@addargs, [])
} } "add node out array leak";

throws_ok { $server->{server}->addVariableNode(@addargs, {}) }
    (qr/addVariableNode: ${outnode} is not a scalar reference /,
    "add node out hash");
no_leaks_ok { eval {
    $server->{server}->addVariableNode(@addargs, {})
} } "add node out hash leak";

$outnodeid = {};
is($server->{server}->deleteNode(\%nodeid, 0), STATUSCODE_GOOD,
    "delete node out hashref");
is($server->{server}->addVariableNode(@addargs, \$outnodeid), STATUSCODE_GOOD,
    "add node out hashref");
is(ref($outnodeid), 'HASH', "read outvalue ref");
$outnodeid = {};
no_leaks_ok {
    $server->{server}->deleteNode(\%nodeid, 0);
    $server->{server}->addVariableNode(@addargs, \$outnodeid);
} "add node out hashref leak";

throws_ok { $server->{server}->addVariableNode(@addargs, $client) }
    (qr/addVariableNode: ${outnode} is not a scalar reference /,
    "add node client type");
no_leaks_ok { eval { $server->{server}->addVariableNode(@addargs, $client) } }
    "add node client type leak";
is(ref($client), 'OPCUA::Open62541::Client', "read client ref");
