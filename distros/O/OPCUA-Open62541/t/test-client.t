# test server listens
# test client connects
# check that both test modules work

use strict;
use warnings;
use OPCUA::Open62541;

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 2;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$server->run();

my $config1 = $client->{client}->getConfig();
$client->run();
my $config2 = $client->{client}->getConfig();
is_deeply($config2, $config1, "get config");

$client->stop();
$server->stop();
