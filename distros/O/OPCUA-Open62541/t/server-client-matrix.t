# create a variable node with a multi dimensional array value
# add node to server tree
# start server
# start client
# read the node from the client
# check that the value is the same

use strict;
use warnings;
use OPCUA::Open62541 ':all';

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 7;
use Test::LeakTrace;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();

my %requestedNewNodeId = (
    NodeId_namespaceIndex       => 1,
    NodeId_identifierType       => NODEIDTYPE_STRING,
    NodeId_identifier           => "the.answer",
);
my %parentNodeId = (
    NodeId_namespaceIndex       => 0,
    NodeId_identifierType       => NODEIDTYPE_NUMERIC,
    NodeId_identifier           => NS0ID_OBJECTSFOLDER,
);
my %referenceTypeId = (
    NodeId_namespaceIndex       => 0,
    NodeId_identifierType       => NODEIDTYPE_NUMERIC,
    NodeId_identifier           => NS0ID_ORGANIZES,
);
my %browseName = (
    QualifiedName_namespaceIndex        => 1,
    QualifiedName_name                  => "the answer",
);
my %typeDefinition = (
    NodeId_namespaceIndex       => 0,
    NodeId_identifierType       => NODEIDTYPE_NUMERIC,
    NodeId_identifier           => NS0ID_BASEDATAVARIABLETYPE,
);

my %attr = (
    VariableAttributes_displayName      => {
	LocalizedText_text              => "the answer",
    },
    VariableAttributes_description      => {
	LocalizedText_text              => "the answer",
    },
    VariableAttributes_value            => {
	Variant_type                    => TYPES_DOUBLE,
	Variant_array                   => [0, 0, 0, 0],
	Variant_arrayDimensions         => [2, 2],
    },
    VariableAttributes_valueRank        => VALUERANK_TWO_DIMENSIONS,
    VariableAttributes_arrayDimensions  => [0, 0],
    VariableAttributes_dataType         => TYPES_DOUBLE,
    VariableAttributes_accessLevel      =>
	ACCESSLEVELMASK_READ | ACCESSLEVELMASK_WRITE,
);

no_leaks_ok {
    $server->{server}->addVariableNode(\%requestedNewNodeId, \%parentNodeId,
	\%referenceTypeId, \%browseName, \%typeDefinition, \%attr, 0,
	undef);
    $server->{server}->deleteNode(\%requestedNewNodeId, 1);
} "add variable node leak";

is($server->{server}->addVariableNode(\%requestedNewNodeId, \%parentNodeId,
    \%referenceTypeId, \%browseName, \%typeDefinition, \%attr, 0, undef),
    STATUSCODE_GOOD, "server add variable node");

my $out;
is($server->{server}->readValue(\%requestedNewNodeId, \$out),
    STATUSCODE_GOOD, "server read value");
is_deeply($out, $attr{VariableAttributes_value}, "value");

$server->start();
my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$server->run();
$client->run();

$client->{client}->readValueAttribute(\%requestedNewNodeId, \$out);
is_deeply($out, $attr{VariableAttributes_value}, "value");

no_leaks_ok {
    $client->{client}->readValueAttribute(\%requestedNewNodeId, \$out);
} "read matrix value leak";

$client->stop();
$server->stop();
