use strict;
use warnings;
use OPCUA::Open62541 qw(:all);

use OPCUA::Open62541::Test::Server;
use Test::More tests => OPCUA::Open62541::Test::Server::planning() + 11;
use Test::Deep;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();

is($server->{server}->run_startup(), STATUSCODE_GOOD, "startup");
cmp_ok($server->{server}->run_iterate(0), ">", 0, "iterate");

my %nodes = $server->setup_complex_objects();

my $br = $server->{server}->browse(
    0,
    {
	BrowseDescription_nodeId => {
	    NodeId_namespaceIndex => 0,
	    NodeId_identifierType => NODEIDTYPE_NUMERIC,
	    NodeId_identifier     => NS0ID_OBJECTSFOLDER,
	},
	BrowseDescription_resultMask => BROWSERESULTMASK_ALL,
    },
);

is($br->{BrowseResult_statusCode}, STATUSCODE_GOOD, "browseresult statuscode");

my $references = $br->{BrowseResult_references};
is(ref($references), "ARRAY", "reference array");

my ($objectref) = grep {
    $_->{ReferenceDescription_nodeId}{ExpandedNodeId_nodeId}
      ->{NodeId_namespaceIndex} == 1
  } @$references;

is (ref($objectref), "HASH", "object reference hash");

my $expected_object = {
    ReferenceDescription_nodeId => {
	ExpandedNodeId_nodeId => $nodes{some_object_0}{nodeId},
	ExpandedNodeId_serverIndex => 0,
	ExpandedNodeId_namespaceUri => undef,
    },
    ReferenceDescription_nodeClass => NODECLASS_OBJECT,
    ReferenceDescription_isForward => 1,
    ReferenceDescription_browseName => $nodes{some_object_0}{browseName},
    ReferenceDescription_displayName =>
	$nodes{some_object_0}{attributes}{ObjectAttributes_displayName},
    ReferenceDescription_typeDefinition => {
	ExpandedNodeId_namespaceUri => undef,
	ExpandedNodeId_nodeId => $nodes{some_object_0}{typeDefinition},
	ExpandedNodeId_serverIndex => 0
    },
    ReferenceDescription_referenceTypeId => $nodes{some_object_0}{referenceTypeId},
};

is_deeply($objectref, $expected_object, "browseresult some_object_0");

$server->run();
$server->stop();
