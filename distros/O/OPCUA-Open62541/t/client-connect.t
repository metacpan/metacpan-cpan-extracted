use strict;
use warnings;
use OPCUA::Open62541 qw(STATUSCODE_GOOD :CLIENTSTATE);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 1;
use Test::NoWarnings;
use Test::Warn;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$server->run();

is($client->{client}->connect($client->url()), STATUSCODE_GOOD,
    "client connect");
is($client->{client}->getState, CLIENTSTATE_SESSION,
    "client state connected");
# check client did connect(2) in 1.0 API or activated session in 1.1 API
ok($client->{log}->loggrep(
    qr/TCP connection established|SessionState: Activated/, 5),
    "client loggrep connected");

is($client->{client}->disconnect(), STATUSCODE_GOOD, "client disconnect");
is($client->{client}->getState, CLIENTSTATE_DISCONNECTED,
    "client state disconnected");

$server->stop();
