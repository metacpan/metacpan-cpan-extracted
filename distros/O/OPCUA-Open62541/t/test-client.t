# test server listens
# test client connects
# check that both test modules work

use strict;
use warnings;
use OPCUA::Open62541 ':all';

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 1;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$server->run();
$client->run();

$client->stop();
$server->stop();
