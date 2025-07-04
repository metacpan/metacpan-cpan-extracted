use strict;
use warnings;
use OPCUA::Open62541 ':all';
use OPCUA::Open62541::Client;
use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 14;
use Test::Deep;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();

my %nodes = $server->setup_complex_objects();
$server->run();
$client->run();

my @namespaces = $client->{client}->get_namespaces();
cmp_deeply \@namespaces, [
    'http://opcfoundation.org/UA/', 'urn:open62541.server.application'
], 'get_namespaces';

my @attributes = $client->{client}->get_attributes({
    NodeId_namespaceIndex => 1,
    NodeId_identifierType => NODEIDTYPE_STRING,
    NodeId_identifier     => "SOME_VARIABLE_0",
}, 'value', ATTRIBUTEID_VALUERANK);
is scalar(@attributes), 2, 'get_attributes count';
is $attributes[0]{DataValue_value}{Variant_scalar}, 42, 'get_attributes value';
is $attributes[1]{DataValue_value}{Variant_scalar}, VALUERANK_SCALAR,
    'get_attributes valuerank';

my @references = $client->{client}->get_references({
    NodeId_namespaceIndex => 1,
    NodeId_identifierType => NODEIDTYPE_STRING,
    NodeId_identifier     => "SOME_VARIABLE_0",
});
is scalar(@references), 2, 'get_references count';
is $references[0]{ReferenceDescription_nodeId}{ExpandedNodeId_nodeId}{NodeId_print},
    'ns=1;s=SOME_OBJECT_TYPE', 'get_references first node';
is $references[1]{ReferenceDescription_nodeId}{ExpandedNodeId_nodeId}{NodeId_print},
    'ns=1;s=SOME_VARIABLE_TYPE', 'get_references second node';

is $references[0]{ReferenceDescription_nodeClass}, NODECLASS_UNSPECIFIED,
    'get_references no nodeclass';

# get references with more other browseresultmask
@references = $client->{client}->get_references({
    NodeId_namespaceIndex => 1,
    NodeId_identifierType => NODEIDTYPE_STRING,
    NodeId_identifier     => "SOME_VARIABLE_0",
}, result_mask => BROWSERESULTMASK_NODECLASS);

is $references[0]{ReferenceDescription_nodeClass}, NODECLASS_OBJECTTYPE,
    'get_references with nodeclass';

$client->stop();
$server->stop();
