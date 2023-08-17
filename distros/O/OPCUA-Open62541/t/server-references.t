use strict;
use warnings;
use OPCUA::Open62541 qw(:all);

use OPCUA::Open62541::Test::Server;
use Test::More tests => OPCUA::Open62541::Test::Server::planning() + 20;
use Test::Deep;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();

is($server->{server}->run_startup(), STATUSCODE_GOOD, "startup");
cmp_ok($server->{server}->run_iterate(0), ">", 0, "iterate");

# add some nodes
my %nodes = $server->setup_complex_objects();

my $node_objecttypes = {
    NodeId_namespaceIndex	=> 0,
    NodeId_identifierType	=> NODEIDTYPE_NUMERIC,
    NodeId_identifier		=> NS0ID_OBJECTTYPESFOLDER,
};
my $node_organizes = {
    NodeId_namespaceIndex	=> 0,
    NodeId_identifierType	=> NODEIDTYPE_NUMERIC,
    NodeId_identifier		=> NS0ID_ORGANIZES,
    NodeId_print		=> "i=".NS0ID_ORGANIZES,
};

sub get_objecttypes_reference {
    my @browse_args = (
	0,
	{
	    BrowseDescription_nodeId		=> $node_objecttypes,
	    BrowseDescription_resultMask	=> BROWSERESULTMASK_ALL,
	},
    );

    my $br = $server->{server}->browse(@browse_args);

    is($br->{BrowseResult_statusCode}, STATUSCODE_GOOD, "object types found");

    my $references = $br->{BrowseResult_references};
    is(ref($references), "ARRAY", "browseresult object types references");

    my ($objectref) = grep {
	$_->{ReferenceDescription_nodeId}{ExpandedNodeId_nodeId}->
	    {NodeId_identifier} eq
	    $nodes{some_object_type}{nodeId}{NodeId_identifier}
    } @$references;

    return $objectref;
}

is(ref(get_objecttypes_reference()), "", "object type reference hash");

is(
    $server->{server}->addReference(
	$node_objecttypes,
	$node_organizes,
	{
	    ExpandedNodeId_namespaceUri => undef,
	    ExpandedNodeId_nodeId => $nodes{some_object_type}{nodeId}
	},
	1,
    ),
    STATUSCODE_GOOD, "add reference");

my $objectref = get_objecttypes_reference();
is(ref($objectref), "HASH", "object type reference hash");
cmp_deeply($objectref->{ReferenceDescription_nodeId}{ExpandedNodeId_nodeId},
    $nodes{some_object_type}{nodeId}, "reference nodeId");
cmp_deeply($objectref->{ReferenceDescription_referenceTypeId},
    $node_organizes, "reference referenceTypeId");

is(
    $server->{server}->deleteReference(
	$node_objecttypes,
	$node_organizes,
	1,
	{ ExpandedNodeId_nodeId => $nodes{some_object_type}{nodeId} },
	1,
    ),
    STATUSCODE_GOOD, "delete reference");

is(ref(get_objecttypes_reference()), "", "object type reference hash");

$server->run();
$server->stop();
