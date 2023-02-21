use strict;
use warnings;
use OPCUA::Open62541 qw(STATUSCODE_GOOD :SESSIONSTATE);

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
my ($channel, $session, $connect) = $client->{client}->getState();
is($session, SESSIONSTATE_ACTIVATED, "client state session activated");
ok($client->{log}->loggrep(qr/SessionState: Activated/, 5),
    "client loggrep connected");

is($client->{client}->disconnect(), STATUSCODE_GOOD, "client disconnect");
($channel, $session, $connect) = $client->{client}->getState();
is($session, SESSIONSTATE_CLOSED, "client state session closed");

$server->stop();
