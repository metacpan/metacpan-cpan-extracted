use strict;
use warnings;
use OPCUA::Open62541 qw(:all);

use OPCUA::Open62541::Test::Server;
use Test::More tests => OPCUA::Open62541::Test::Server::planning() + 23;
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
	ExpandedNodeId_nodeId		=> $nodes{some_object_0}{nodeId},
	ExpandedNodeId_serverIndex	=> 0,
	ExpandedNodeId_namespaceUri	=> undef,
    },
    ReferenceDescription_nodeClass	=> NODECLASS_OBJECT,
    ReferenceDescription_isForward	=> 1,
    ReferenceDescription_browseName	=> $nodes{some_object_0}{browseName},
    ReferenceDescription_displayName	=>
	$nodes{some_object_0}{attributes}{ObjectAttributes_displayName},
    ReferenceDescription_typeDefinition => {
	ExpandedNodeId_namespaceUri	=> undef,
	ExpandedNodeId_nodeId		=>
	    $nodes{some_object_0}{typeDefinition},
	ExpandedNodeId_serverIndex	=> 0
    },
    ReferenceDescription_referenceTypeId	=>
	$nodes{some_object_0}{referenceTypeId},
};

is_deeply($objectref, $expected_object, "browseresult some_object_0");

my $variant;
is($server->{server}->readValue($nodes{some_variable_0}{nodeId},\$variant),
    STATUSCODE_GOOD, "readValue statuscode");

is_deeply(
    $variant,
    $nodes{some_variable_0}{attributes}{VariableAttributes_value},
    "readValue some_variable_0");

# make another browse request that generates continuation points
$br = $server->{server}->browse(
    1,
    {
	BrowseDescription_nodeId => {
	    NodeId_namespaceIndex => 0,
	    NodeId_identifierType => NODEIDTYPE_NUMERIC,
	    NodeId_identifier     => NS0ID_ROOTFOLDER,
	},
	BrowseDescription_referenceTypeId => {
	    NodeId_namespaceIndex => 0,
	    NodeId_identifierType => NODEIDTYPE_NUMERIC,
	    NodeId_identifier     => NS0ID_ORGANIZES,
	},
	BrowseDescription_resultMask => BROWSERESULTMASK_BROWSENAME,
    },
);

is($br->{BrowseResult_statusCode}, STATUSCODE_GOOD, "browseresult statuscode");

$references = $br->{BrowseResult_references};
is(ref($references), "ARRAY", "reference array");

my $expected_reference = [{
    ReferenceDescription_isForward => '',
    ReferenceDescription_displayName => {
	LocalizedText_text => undef,
    },
    ReferenceDescription_browseName => {
	QualifiedName_namespaceIndex => 0,
	QualifiedName_name => 'Objects',
    },
    ReferenceDescription_typeDefinition => {
	ExpandedNodeId_nodeId => {
	    NodeId_identifier => 0,
	    NodeId_namespaceIndex => 0,
	    NodeId_identifierType => 0,
	},
	ExpandedNodeId_namespaceUri => undef,
	ExpandedNodeId_serverIndex => 0,
    },
    ReferenceDescription_nodeClass => 0,
    ReferenceDescription_referenceTypeId => {
	NodeId_identifier => 0,
	NodeId_namespaceIndex => 0,
	NodeId_identifierType => 0
    },
    ReferenceDescription_nodeId => {
	ExpandedNodeId_nodeId => {
	    NodeId_namespaceIndex => 0,
	    NodeId_identifierType => 0,
	    NodeId_identifier => 85
	},
	ExpandedNodeId_serverIndex => 0,
	ExpandedNodeId_namespaceUri => undef
    }
}];

is_deeply($references, $expected_reference, "reference");

my $cp;
for (['Types', 86], ['Views', 87]) {
    $cp = $br->{BrowseResult_continuationPoint};

    $br = $server->{server}->browseNext(0, $cp);
    is($br->{BrowseResult_statusCode}, STATUSCODE_GOOD,
	"browseresult statuscode");

    use Data::Dumper;
    #print Dumper $br;

    $references = $br->{BrowseResult_references};
    is(ref($references), "ARRAY", "reference array");

    $expected_reference->[0]{ReferenceDescription_browseName}
	{QualifiedName_name} = $_->[0];
    $expected_reference->[0]{ReferenceDescription_nodeId}
	{ExpandedNodeId_nodeId}{NodeId_identifier} = $_->[1];

    is_deeply($references, $expected_reference, "reference");
}

$cp = $br->{BrowseResult_continuationPoint};

is ($cp, undef, "last continuation point");

$server->run();
$server->stop();
