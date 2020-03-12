use strict;
use warnings;
use OPCUA::Open62541 ':all';

use OPCUA::Open62541::Test::Server;
use Test::More tests => OPCUA::Open62541::Test::Server::planning() + 5;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();

is($server->{server}->run_startup(), STATUSCODE_GOOD, "startup");
cmp_ok($server->{server}->run_iterate(0), '>', 0, "iterate");

my %requestedNewNodeId = (
    NodeId_namespaceIndex	=> 1,
    NodeId_identifierType	=> NODEIDTYPE_STRING,
    NodeId_identifier		=> "the.answer",
);
my %parentNodeId = (
    NodeId_namespaceIndex	=> 0,
    NodeId_identifierType	=> NODEIDTYPE_NUMERIC,
    NodeId_identifier		=> 85, # UA_NS0ID_OBJECTSFOLDER
);
my %referenceTypeId = (
    NodeId_namespaceIndex	=> 0,
    NodeId_identifierType	=> NODEIDTYPE_NUMERIC,
    NodeId_identifier		=> 35, # UA_NS0ID_ORGANIZES
);
my %browseName = (
    QualifiedName_namespaceIndex	=> 1,
    QualifiedName_name			=> "the answer",
);
my %typeDefinition = (
    NodeId_namespaceIndex	=> 0,
    NodeId_identifierType	=> NODEIDTYPE_NUMERIC,
    NodeId_identifier		=> 63, # UA_NS0ID_BASEDATAVARIABLETYPE
);
my %attr = (
    VariableAttributes_displayName	=> {
	LocalizedText_text		=> "the answer",
    },
    VariableAttributes_description	=> {
	LocalizedText_text		=> "the answer",
    },
    VariableAttributes_value		=> {
	Variant_type			=> TYPES_INT32,
	Variant_scalar			=> 42,
    },
    VariableAttributes_dataType		=> TYPES_INT32,
    VariableAttributes_accessLevel	=>
	ACCESSLEVELMASK_READ | ACCESSLEVELMASK_WRITE,
);

is($server->{server}->addVariableNode(\%requestedNewNodeId, \%parentNodeId,
    \%referenceTypeId, \%browseName, \%typeDefinition, \%attr, 0,
    undef), STATUSCODE_GOOD, "add variable node");
no_leaks_ok {
    $server->{server}->addVariableNode(\%requestedNewNodeId, \%parentNodeId,
	\%referenceTypeId, \%browseName, \%typeDefinition, \%attr, 0,
	undef);
} "add variable node leak";

$requestedNewNodeId{NodeId_identifier} = "enigma";
$attr{VariableAttributes_value}{Variant_scalar} = 23;

my $outNewNodeId;
is($server->{server}->addVariableNode(\%requestedNewNodeId, \%parentNodeId,
    \%referenceTypeId, \%browseName, \%typeDefinition, \%attr, 0,
    \$outNewNodeId), STATUSCODE_GOOD, "add variable out");
is(ref($outNewNodeId), 'OPCUA::Open62541::NodeId', "class out node");
no_leaks_ok {
    $server->{server}->addVariableNode(\%requestedNewNodeId, \%parentNodeId,
	\%referenceTypeId, \%browseName, \%typeDefinition, \%attr, 0,
	\$outNewNodeId);
} "out node leak";
undef $outNewNodeId;

my %outNewNodeId;
throws_ok {
    $server->{server}->addVariableNode(\%requestedNewNodeId, \%parentNodeId,
	\%referenceTypeId, \%browseName, \%typeDefinition, \%attr, 0,
	\%outNewNodeId);
} (qr/outNewNodeId is not a scalar reference/, "empty out node");
no_leaks_ok { eval {
    $server->{server}->addVariableNode(\%requestedNewNodeId, \%parentNodeId,
	\%referenceTypeId, \%browseName, \%typeDefinition, \%attr, 0,
	\%outNewNodeId);
} } "empty out node leak";

cmp_ok($server->{server}->run_iterate(0), '>', 0, "iterate");
is($server->{server}->run_shutdown(), STATUSCODE_GOOD, "shutdown");
