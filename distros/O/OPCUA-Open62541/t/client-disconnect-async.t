use strict;
use warnings;
use OPCUA::Open62541 qw(:STATUSCODE :SESSIONSTATE :SECURECHANNELSTATE);
use Scalar::Util qw(looks_like_number);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() * 2 + 3;
use Test::Exception;
use Test::NoWarnings;
use Test::LeakTrace;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$server->run();
$client->run();

is($client->{client}->disconnectAsync(), STATUSCODE_GOOD, "disconnect async");

$client->iterate_disconnect("disconnect");
is_deeply([$client->{client}->getState()],
    [SECURECHANNELSTATE_CLOSED, SESSIONSTATE_CLOSED, STATUSCODE_GOOD],
    "state");

# try to connect again after disconnect
$client->{config}->setStateCallback(undef);
is($client->{client}->connectAsync($client->url()), STATUSCODE_GOOD,
    "connect async again");
$client->iterate_connect("connect again");

$client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$client->run();

# Run the test again, check for leaks, no check within leak detection.
no_leaks_ok {
    $client->{client}->disconnectAsync();
    $client->iterate_disconnect();
} "disconnect async leak";

$server->stop();
