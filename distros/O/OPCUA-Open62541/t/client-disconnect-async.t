use strict;
use warnings;
use OPCUA::Open62541 qw(:STATUSCODE :CLIENTSTATE :SESSIONSTATE
    :SECURECHANNELSTATE );
use Scalar::Util qw(looks_like_number);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() * 3 + 8;
use Test::Exception;
use Test::NoWarnings;
use Test::LeakTrace;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$server->run();
$client->run();

# There is a bug in open62541 1.0.6 that crashes the client with a
# segmentation fault.  It happens during connect after disconnect
# as the async service callback sets securityPolicy to NULL.

my $skip_reconnect;
ok(my $buildinfo = $server->{config}->getBuildInfo());
note explain $buildinfo;
if ($buildinfo->{BuildInfo_softwareVersion} =~ /^1\.0\./) {
    $skip_reconnect = "reconnect bug in ".
	"library '$buildinfo->{BuildInfo_manufacturerName}' ".
	"version '$buildinfo->{BuildInfo_softwareVersion}' ".
	"operating system '$^O'";
}

my $async = OPCUA::Open62541::Client->can('disconnect_async');

my $requestId;
if ($async) {
    is($client->{client}->disconnect_async(\$requestId),
	STATUSCODE_GOOD, "disconnect async");
} else {
    is($client->{client}->disconnectAsync(),
	STATUSCODE_GOOD, "disconnect async");
}
SKIP: {
    skip "API 1.1 disconnect does not have request id", 1 unless $async;

    ok(looks_like_number $requestId, "disconnect request id")
	or diag "request id not a number: $requestId";
}  # SKIP

$client->iterate_disconnect("disconnect");
if ($async) {
    is($client->{client}->getState(), CLIENTSTATE_DISCONNECTED, "state");
} else {
    is_deeply([$client->{client}->getState()], [SECURECHANNELSTATE_CLOSED,
	SESSIONSTATE_CLOSED, STATUSCODE_GOOD], "state");
}

# try to connect again after disconnect
SKIP: {
    skip $skip_reconnect, 2 if $skip_reconnect;
    if ($async) {
	is($client->{client}->connect_async($client->url(), undef, undef),
	    STATUSCODE_GOOD, "connect async again");
    } else {
	$client->{config}->setStateCallback(undef);
	is($client->{client}->connectAsync($client->url()),
	    STATUSCODE_GOOD, "connect async again");
    }
    $client->iterate_connect("connect again");
}  # SKIP

$client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$client->run();

# Run the test again, check for leaks, no check within leak detection.
no_leaks_ok {
    if ($async) {
	$client->{client}->disconnect_async(\$requestId);
    } else {
	$client->{client}->disconnectAsync();
    }
    $client->iterate_disconnect();
} "disconnect async leak";

SKIP: {
    skip "API 1.1 disconnect does not have request id",
	OPCUA::Open62541::Test::Client::planning() + 1
	unless $async;

    $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
    $client->start();
    $client->run();

    is($client->{client}->disconnect_async(undef), STATUSCODE_GOOD,
	"disconnect async undef requestid");
    no_leaks_ok {
	$client->{client}->disconnect_async(undef);
    } "disconnect async undef requestid leak";

    $client->iterate_disconnect("disconnect undef requestid");
}  # SKIP

$server->stop();

SKIP: {
    skip "API 1.1 disconnect does not have request id", 2 unless $async;

    # The following tests do not need a connection.
    throws_ok {
	$client->{client}->disconnect_async("foo");
    } (qr/Output parameter outoptReqId is not a scalar reference /,
	"disconnect noref requestid");
    no_leaks_ok { eval {
	$client->{client}->disconnect_async("foo");
    } } "disconnect noref requestid leak";
}  # SKIP
