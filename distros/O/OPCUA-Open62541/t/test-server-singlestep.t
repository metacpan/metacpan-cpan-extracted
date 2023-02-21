use strict;
use warnings;
use OPCUA::Open62541 qw(:STATUSCODE :SESSIONSTATE);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests => OPCUA::Open62541::Test::Server::planning() + 20;
use Test::LeakTrace;
use Test::NoWarnings;
use Time::HiRes qw(sleep);
use POSIX qw(SIGUSR1);

my $server = OPCUA::Open62541::Test::Server->new(singlestep => 1);
$server->start();

my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();

$server->run();

is($client->{client}->connectAsync($client->url()), STATUSCODE_GOOD,
    "connect async");
# wait an initial 100ms for open62541 to start the timer that creates the socket
sleep .1;

my $i;
for ($i = 50; $i > 0; $i--) {
    my $sc = $client->{client}->run_iterate(0);
    $server->step();

    if (($client->{client}->getState())[1] == SESSIONSTATE_ACTIVATED) {
	pass "client session activated";
	last;
    }
    note "server iteration: $i";
    sleep(.1);
}

if ($i == 0) {
    fail "client session established" or diag("loop timeout");
}

ok($server->{log}->loggrep(qr/New connection over TCP/),
    "client connected");
ok($server->{log}->loggrep(qr/SecureChannel .* Session activated/),
    "new secure channel created");

ok($server->{log}->loggrep(qr/server: singlestep/),
    "singlestep found in log");

$client->stop();
$server->stop();
