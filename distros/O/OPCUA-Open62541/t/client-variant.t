use strict;
use warnings;
use OPCUA::Open62541 ':all';

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 3;
use Test::Exception;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$server->run();
$client->run();

my %request = (
    NodeId_namespaceIndex       => 0,
    NodeId_identifierType       => 0,
    NodeId_identifier           => 2255,
);

my $variant;
is($client->{client}->readValueAttribute(\%request, \$variant),
    STATUSCODE_GOOD, "read value");

my %result = (
    Variant_type => TYPES_STRING,
    Variant_array => [
      'http://opcfoundation.org/UA/',
      'urn:open62541.server.application'
    ],
);

is_deeply($variant, \%result, "array variant result")
    or diag explain $variant;

$client->stop();
$server->stop();
