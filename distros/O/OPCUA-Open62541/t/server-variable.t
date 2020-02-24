use strict;
use warnings;
use OPCUA::Open62541 ':all';

use Test::More tests => 12;
use Test::NoWarnings;
use Test::Exception;

ok(my $server = OPCUA::Open62541::Server->new(), "server");
ok(my $config = $server->getConfig(), "config");
is($config->setDefault(), STATUSCODE_GOOD, "default");
is($server->run_startup(), STATUSCODE_GOOD, "startup");
cmp_ok($server->run_iterate(0), '>', 0, "iterate");

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

is($server->addVariableNode(\%requestedNewNodeId, \%parentNodeId,
    \%referenceTypeId, \%browseName, \%typeDefinition, \%attr, 0,
    undef), STATUSCODE_GOOD, "add variable node");

$requestedNewNodeId{NodeId_identifier} = "enigma";
$attr{VariableAttributes_value}{Variant_scalar} = 23;

my $outNewNodeId;
is($server->addVariableNode(\%requestedNewNodeId, \%parentNodeId,
    \%referenceTypeId, \%browseName, \%typeDefinition, \%attr, 0,
    \$outNewNodeId), STATUSCODE_GOOD, "add variable out");
is(ref($outNewNodeId), 'OPCUA::Open62541::NodeId', "out node");
undef $outNewNodeId;

my %outNewNodeId;
throws_ok {
    $server->addVariableNode(\%requestedNewNodeId, \%parentNodeId,
    \%referenceTypeId, \%browseName, \%typeDefinition, \%attr, 0,
    \%outNewNodeId)
} (qr/outNewNodeId is not a scalar reference/, "empty out node");

cmp_ok($server->run_iterate(0), '>', 0, "iterate");
is($server->run_shutdown(), STATUSCODE_GOOD, "shutdown");
