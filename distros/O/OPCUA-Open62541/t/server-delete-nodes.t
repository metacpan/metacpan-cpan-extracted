use strict;
use warnings;
use OPCUA::Open62541 qw(:all);

use OPCUA::Open62541::Test::Server;
use Test::More tests => OPCUA::Open62541::Test::Server::planning() + 16;
use Test::Deep;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();

is($server->{server}->run_startup(), STATUSCODE_GOOD, "startup");
cmp_ok($server->{server}->run_iterate(0), ">", 0, "iterate");

# add some nodes
my %nodes = $server->setup_complex_objects();

# verify the variable node can be found
my $br = $server->{server}->browse(
    0,
    {
	BrowseDescription_nodeId => $nodes{some_variable_0}{nodeId},
	BrowseDescription_resultMask => BROWSERESULTMASK_ALL,
    },
);

is($br->{BrowseResult_statusCode}, STATUSCODE_GOOD, "browseresult node found");

# verify the variable node is referenced from some_object_type
$br = $server->{server}->browse(
    0,
    {
	BrowseDescription_nodeId => $nodes{some_object_type}{nodeId},
	BrowseDescription_resultMask => BROWSERESULTMASK_ALL,
	BrowseDescription_browseDirection => 0,
    },
);

is($br->{BrowseResult_statusCode}, STATUSCODE_GOOD,
    "browseresult object type found");

my $references = $br->{BrowseResult_references};
is(ref($references), "ARRAY", "browseresult object type references");

my ($objectref) = grep {
    $_->{ReferenceDescription_nodeId}{ExpandedNodeId_nodeId}{NodeId_identifier}
	eq $nodes{some_variable_0}{nodeId}{NodeId_identifier}
} @$references;

is(ref($objectref), "HASH", "object reference hash");

# delete the node with the reference to it
is($server->{server}->deleteNode($nodes{some_variable_0}{nodeId}, 1),
   STATUSCODE_GOOD, "delete with references");

# verify the node is deleted
$br = $server->{server}->browse(
    0,
    {
	BrowseDescription_nodeId => $nodes{some_variable_0}{nodeId},
	BrowseDescription_resultMask => BROWSERESULTMASK_ALL,
    },
);

is($br->{BrowseResult_statusCode},
   STATUSCODE_BADNODEIDUNKNOWN, "browseresult node not found");

# verify the reference to the node was deleted
$br = $server->{server}->browse(
    0,
    {
	BrowseDescription_nodeId => $nodes{some_object_type}{nodeId},
	BrowseDescription_resultMask => BROWSERESULTMASK_ALL,
	BrowseDescription_browseDirection => 0,
    },
);

is($br->{BrowseResult_statusCode}, STATUSCODE_GOOD,
    "browseresult object type found");

$references = $br->{BrowseResult_references};
is(ref($references), "ARRAY", "browseresult object type references");

($objectref) = grep {
    $_->{ReferenceDescription_nodeId}{ExpandedNodeId_nodeId}{NodeId_identifier}
    eq $nodes{some_variable_0}{nodeId}{NodeId_identifier}
} @$references;

is(ref($objectref), "", "object reference hash");

$server->run();
$server->stop();
