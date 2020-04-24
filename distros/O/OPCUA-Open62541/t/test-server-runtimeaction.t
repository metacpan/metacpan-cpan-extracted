use strict;
use warnings;
use OPCUA::Open62541 qw(:all);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::Deep;
use Test::More tests => OPCUA::Open62541::Test::Server::planning() + 19;
use Test::NoWarnings;

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
	Variant_type                    => TYPES_INT32,
	Variant_scalar                  => 42,
    },
    VariableAttributes_dataType         => TYPES_INT32,
    VariableAttributes_accessLevel      =>
	ACCESSLEVELMASK_READ | ACCESSLEVELMASK_WRITE,
);

my $server = OPCUA::Open62541::Test::Server->new(
    actions => [
	sub {
	    my $self = shift;
	    my $status = $self->{server}->addVariableNode(
		\%requestedNewNodeId, \%parentNodeId, \%referenceTypeId,
		\%browseName, \%typeDefinition, \%attr, 0, undef);
	    die("add node failed: $status") if $status != STATUSCODE_GOOD;
	},
    ],
);
$server->start();

my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();

$server->run();
$client->run();

my $out;
is($client->{client}->readValueAttribute(\%requestedNewNodeId, \$out),
   STATUSCODE_BADNODEIDUNKNOWN, "readValue first unknown");

$server->next_action();

is($client->{client}->readValueAttribute(\%requestedNewNodeId, \$out),
   STATUSCODE_GOOD, "readValue second good");
cmp_deeply($out, $attr{VariableAttributes_value}, "value");

$client->stop();
$server->stop();
