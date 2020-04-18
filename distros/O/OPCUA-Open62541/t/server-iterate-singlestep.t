use strict;
use warnings;
use OPCUA::Open62541 qw(:STATUSCODE :CLIENTSTATE);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests => OPCUA::Open62541::Test::Server::planning() + 16;
use Test::LeakTrace;
use Test::NoWarnings;
use POSIX qw(SIGUSR1);

my $server = OPCUA::Open62541::Test::Server->new(signaldriven => 1);
$server->start();

my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();

$server->run();

my $data = ['foo'];
is($client->{client}->connect_async(
    $client->url(),
    undef,
    $data
), STATUSCODE_GOOD, "connect async");

while ($client->{client}->getState() != CLIENTSTATE_SESSION) {
    $client->{client}->run_iterate(0);
    $server->step();
}

ok($server->{log}->loggrep(qr/New connection over TCP/),
    "server: client connected");
ok($server->{log}->loggrep(qr/Creating a new SecureChannel/),
    "server: new secure channel created");

$client->stop();
$server->stop();
