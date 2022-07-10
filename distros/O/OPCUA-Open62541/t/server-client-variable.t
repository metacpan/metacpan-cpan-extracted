# create a variable node with value
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
    OPCUA::Open62541::Test::Client::planning() + 29;
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
	Variant_type                    => TYPES_INT32,
	Variant_scalar                  => 42,
    },
    VariableAttributes_valueRank        => VALUERANK_SCALAR,
    VariableAttributes_dataType         => TYPES_INT32,
    VariableAttributes_accessLevel      =>
	ACCESSLEVELMASK_READ | ACCESSLEVELMASK_WRITE,
);
is($server->{server}->addVariableNode(\%requestedNewNodeId, \%parentNodeId,
    \%referenceTypeId, \%browseName, \%typeDefinition, \%attr, 0, undef),
    STATUSCODE_GOOD, "server add variable node");

$attr{VariableAttributes_value}{Variant_scalar} = 23;
is($server->{server}->writeValue(\%requestedNewNodeId,
    $attr{VariableAttributes_value}),
    STATUSCODE_GOOD, "server write value");

my $out;
is($server->{server}->readValue(\%requestedNewNodeId, \$out),
    STATUSCODE_GOOD, "server read value");
is_deeply($out, $attr{VariableAttributes_value}, "value");

$server->start();
my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$server->run();
$client->run();

$client->{client}->readDisplayNameAttribute(\%requestedNewNodeId, \$out);
is_deeply($out, $attr{VariableAttributes_displayName}, "display name");

$client->{client}->readDescriptionAttribute(\%requestedNewNodeId, \$out);
is_deeply($out, $attr{VariableAttributes_description}, "display name");

$client->{client}->readDataTypeAttribute(\%requestedNewNodeId, \$out);
is_deeply($out, $attr{VariableAttributes_dataType}, "data type");

$client->{client}->readValueAttribute(\%requestedNewNodeId, \$out);
is_deeply($out, $attr{VariableAttributes_value}, "value");

# async

my $data = "foo",
my $reqid;
my $read = 0;
$out = undef;
is($client->{client}->readValueAttribute_async(
    \%requestedNewNodeId,
    sub {
	my ($c, $d, $i, $v) = @_;

	is($c, $client->{client}, "readValueAttribute_async client");
	is($$d, "foo", "readValueAttribute_async data in");
	$$d = "bar";
	is($i, $reqid, "readValueAttribute_async reqid");
	my $value = $v->{DataValue_value} // $v;
	is_deeply($value, $attr{VariableAttributes_value},
	    "readValueAttribute_async value");

	$read = 1;
    },
    \$data,
    \$reqid,
), STATUSCODE_GOOD, "readValueAttribute_async status");
is($data, "foo", "readValueAttribute_async data unchanged");
like($reqid, qr/^\d+$/, "readValueAttribute_async reqid number");
$client->iterate(\$read, "readValueAttribute_async read deep");
is($data, 'bar', "readValueAttribute_async data out");

no_leaks_ok {
    $read = 0;
    $client->{client}->readValueAttribute_async(
	\%requestedNewNodeId,
	sub {
	    my ($c, $d, $i, $v) = @_;
	    $read = 1;
	},
	$data,
	\$reqid,
    );
    $client->iterate(\$read);
} "readValueAttribute_async leak";

$data = "foo",
$reqid = undef;
$read = 0;
$out = undef;
is($client->{client}->readDataTypeAttribute_async(
    \%requestedNewNodeId,
    sub {
	my ($c, $d, $i, $v) = @_;

	is($c, $client->{client}, "readDataTypeAttribute_async client");
	is($$d, "foo", "readDataTypeAttribute_async data in");
	$$d = "bar";
	is($i, $reqid, "readDataTypeAttribute_async reqid");
	is_deeply($v, $attr{VariableAttributes_dataType},
	    "readDataTypeAttribute_async data type");

	$read = 1;
    },
    \$data,
    \$reqid,
), STATUSCODE_GOOD, "readDataTypeAttribute_async status");
is($data, "foo", "readDataTypeAttribute_async data unchanged");
like($reqid, qr/^\d+$/, "readDataTypeAttribute_async reqid number");
$client->iterate(\$read, "readDataTypeAttribute_async read deep");
is($data, 'bar', "readDataTypeAttribute_async data out");

no_leaks_ok {
    $read = 0;
    $client->{client}->readDataTypeAttribute_async(
	\%requestedNewNodeId,
	sub {
	    my ($c, $d, $i, $v) = @_;
	    $read = 1;
	},
	$data,
	\$reqid,
    );
    $client->iterate(\$read);
} "readDataTypeAttribute_async leak";

$client->stop();
$server->stop();
