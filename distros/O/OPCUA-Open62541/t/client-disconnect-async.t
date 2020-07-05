use strict;
use warnings;
use OPCUA::Open62541 qw(:STATUSCODE :CLIENTSTATE);
use Scalar::Util qw(looks_like_number);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More;
BEGIN {
    if (OPCUA::Open62541::Client->can('disconnect_async')) {
	plan tests =>
	    OPCUA::Open62541::Test::Server::planning() +
	    OPCUA::Open62541::Test::Client::planning() * 3 + 5;
    } else {
	plan skip_all => "No UA_Client_disconnect_async in open62541";
    }
}
use Test::Exception;
use Test::NoWarnings;
use Test::LeakTrace;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$server->run();
$client->run();

my $requestId;
is($client->{client}->disconnect_async(\$requestId),
    STATUSCODE_GOOD, "disconnect async");
ok(looks_like_number $requestId, "disconnect request id")
    or diag "request id not a number: $requestId";

$client->iterate(undef, "disconnect");
is($client->{client}->getState(), CLIENTSTATE_DISCONNECTED, "state");

$client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$client->run();

# Run the test again, check for leaks, no check within leak detection.
no_leaks_ok {
    $client->{client}->disconnect_async(\$requestId);
    $client->iterate(undef);
} "disconnect async leak";

$client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$client->run();

is($client->{client}->disconnect_async(undef), STATUSCODE_GOOD,
    "disconnect async undef requestid");
no_leaks_ok {
    $client->{client}->disconnect_async(undef);
} "disconnect async undef requestid leak";

$client->iterate(undef, "disconnect undef requestid");

$server->stop();

# The following tests do not need a connection.

throws_ok {
    $client->{client}->disconnect_async("foo");
} (qr/Output parameter outoptReqId is not a scalar reference /,
    "disconnect noref requestid");
no_leaks_ok { eval {
    $client->{client}->disconnect_async("foo");
} } "disconnect noref requestid leak";
