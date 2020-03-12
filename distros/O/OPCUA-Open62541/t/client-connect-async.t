use strict;
use warnings;
use OPCUA::Open62541 ':all';
use Scalar::Util qw(looks_like_number);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() * 2 + 11;
use Test::Exception;
use Test::NoWarnings;
use Test::LeakTrace;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$server->run();

my $data = ['foo'];
my $connected = 0;
is($client->{client}->connect_async(
    $client->url(),
    sub {
	my ($c, $d, $i, $r) = @_;

	is($c->getState(), CLIENTSTATE_SESSION, "callback client state");
	is($d->[0], "foo", "callback data in");
	push @$d, 'bar';
	ok(looks_like_number $i, "callback request id")
	    or diag "request id not a number: $i";
	is($r, STATUSCODE_GOOD, "callback response");

	$connected = 1;
    },
    $data
), STATUSCODE_GOOD, "client connect_async");
$client->iterate(\$connected, "connect");
is($client->{client}->getState(), CLIENTSTATE_SESSION, "client state");
is($data->[1], "bar", "callback data out");

$client->stop();

$client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();

# Run the test again, check for leaks, no check within leak detection.
# Although no_leaks_ok runs the code block multiple times, the callback
# is only called once.
$connected = 0;
no_leaks_ok {
    $client->{client}->connect_async(
	$client->url(),
	sub {
	    my ($c, $d, $i, $r) = @_;
	    $connected = 1;
	},
	$data
    );
    $client->iterate(\$connected);
} "client connect_async leak";

$client->stop();

$server->stop();

# connect to invalid url fails, check that it does not leak
$data = "foo";
is($client->{client}->connect_async(
    "opc.tcp://localhost:",
    sub {
	my ($c, $d, $i, $r) = @_;
	fail "callback called";
    },
    \$data,
), STATUSCODE_BADCONNECTIONCLOSED, "connect_async fail");
is($data, "foo", "data fail");
no_leaks_ok {
    $client->{client}->connect_async(
	"opc.tcp://localhost:",
	sub {
	    my ($c, $d, $i, $r) = @_;
	},
	\$data,
    );
} "connect_async fail leak";

throws_ok { $client->{client}->connect_async($client->url(), "foo", undef) }
    (qr/Callback 'foo' is not a CODE reference /,
    "callback not reference");
no_leaks_ok {
    eval { $client->{client}->connect_async($client->url(), "foo", undef) }
} "callback not reference leak";

throws_ok { $client->{client}->connect_async($client->url(), [], undef) }
    (qr/Callback 'ARRAY.*' is not a CODE reference /,
    "callback not code reference");
no_leaks_ok {
    eval { $client->{client}->connect_async($client->url(), [], undef) }
} "callback not code reference leak";

# the connection itself gets established in run_iterate. so this call should
# also succeed if no server is running
is($client->{client}->connect_async($client->url(), undef, undef),
    STATUSCODE_GOOD, "connect_async no callback");
no_leaks_ok { $client->{client}->connect_async($client->url(), undef, undef) }
    "connect_async no callback leak";
