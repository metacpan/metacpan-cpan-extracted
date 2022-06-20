use strict;
use warnings;
use OPCUA::Open62541 qw(:STATUSCODE :CLIENTSTATE);

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

if (OPCUA::Open62541::Client->can('connect_async')) {
    is($client->{client}->connect_async(
	$client->url(),
	undef,
	undef
    ), STATUSCODE_GOOD, "connect async");
} else {
    is($client->{client}->connectAsync($client->url()), STATUSCODE_GOOD,
	"connect async");
}
# wait an initial 100ms for open62541 to start the timer that creates the socket
sleep .1;

my $i;
for ($i = 50; $i > 0; $i--) {
    my $sc = $client->{client}->run_iterate(0);
    $server->step();

    # backwards compatibility hack
    my $clientstat_session = defined &CLIENTSTATE_SESSION ?
	CLIENTSTATE_SESSION : 4;
    if ($client->{client}->getState() == $clientstat_session) {
	pass "client session established";
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
ok($server->{log}->loggrep(
    qr/(Creating a new SecureChannel|SecureChannel .* Session activated)/),
    "new secure channel created");

ok($server->{log}->loggrep(qr/server: singlestep/),
    "singlestep found in log");

$client->stop();
$server->stop();
