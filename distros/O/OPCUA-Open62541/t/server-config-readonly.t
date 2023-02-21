use strict;
use warnings;

use OPCUA::Open62541 qw(:all);
use OPCUA::Open62541::Test::Client;
use OPCUA::Open62541::Test::Server;

use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 12;
use Test::Exception;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
my $config = $server->{server}->getConfig();
my $status = $config->setDefault();
is($status, STATUSCODE_GOOD, "config defautl status");
$server->start();
$config->setUserAccessLevelReadonly(1);
$config->setUserRightsMaskReadonly(1);
my %nodes = $server->setup_complex_objects();
$server->run();

my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$client->run();

$status = $client->{client}->writeValueAttribute(
    {
	NodeId_namespaceIndex	=> 1,
	NodeId_identifierType	=> NODEIDTYPE_STRING,
	NodeId_identifier	=> "SOME_VARIABLE_0",
    },
    {
	Variant_type => TYPES_INT32,
	Variant_scalar => 23,
    },

);

is($status, STATUSCODE_BADUSERACCESSDENIED, "write value status");

my $out;
$status = $client->{client}->readValueAttribute(
    {
	NodeId_namespaceIndex	=> 1,
	NodeId_identifierType	=> NODEIDTYPE_STRING,
	NodeId_identifier	=> "SOME_VARIABLE_0",
    },
    \$out,

);

is($status, STATUSCODE_GOOD, "read value status");
is($out->{Variant_scalar}, 42, "read value");

$status = $client->{client}->writeDescriptionAttribute(
    {
	NodeId_namespaceIndex	=> 1,
	NodeId_identifierType	=> NODEIDTYPE_STRING,
	NodeId_identifier	=> "SOME_OBJECT_0",
    },
    {
	Variant_type => TYPES_LOCALIZEDTEXT,
	Variant_scalar => {
	    LocalizedText_text	=> 'overwritten description'
	},
    },

);

is($status, STATUSCODE_BADUSERACCESSDENIED, "write description status");

$status = $client->{client}->readDescriptionAttribute(
    {
	NodeId_namespaceIndex	=> 1,
	NodeId_identifierType	=> NODEIDTYPE_STRING,
	NodeId_identifier	=> "SOME_OBJECT_0",
    },
    \$out,
);

is($status, STATUSCODE_GOOD, "read description status");
is($out->{LocalizedText_text}, $nodes{some_object_0}{attributes}
    {ObjectAttributes_description}{LocalizedText_text}, "read description");

$client->stop();
$server->stop();
