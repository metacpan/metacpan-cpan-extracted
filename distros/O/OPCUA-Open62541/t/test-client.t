use strict;
use warnings;
use OPCUA::Open62541 ':all';
use POSIX qw(sigaction SIGALRM);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 1;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
my $port = $server->port();

my $client = OPCUA::Open62541::Test::Client->new(port => $port);
$client->start();

$client->stop();
$server->stop();
