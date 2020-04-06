use strict;
use warnings;
use OPCUA::Open62541 qw(:STATUSCODE :CLIENTSTATE);
use IO::Socket::INET;
use Scalar::Util qw(looks_like_number);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() * 4 + 7;
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
), STATUSCODE_GOOD, "connect async");
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
} "connect async leak";

$client->stop();

# run test without connect callback
$client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();

is($client->{client}->connect_async($client->url(), undef, undef),
    STATUSCODE_GOOD, "connect async undef callback");
$client->iterate(sub {
    return $client->{client}->getState() == CLIENTSTATE_SESSION;
}, "connect undef callback");

$client->stop();

# the connection itself gets established in run_iterate. so this call should
# also succeed if no server is running
no_leaks_ok { $client->{client}->connect_async($client->url(), undef, undef) }
    "connect async no callback leak";

$server->stop();

# Run test without callback being called due to nonexisting target.
# The connect_async() call must succeed, but iterate() must fail.
# A non OPC UA server accepting TCP will do the job.

my $tcp_server = IO::Socket::INET->new(
    LocalAddr	=> "localhost",
    Proto	=> "tcp",
    Listen	=> 1,
);
ok($tcp_server, "tcp server") or diag "tcp server new and listen failed: $!";
my $tcp_port = $tcp_server->sockport();

$client = OPCUA::Open62541::Test::Client->new(port => $tcp_port);
$client->start();

is($client->{client}->connect_async(
    $client->url(),
    sub {
	my ($c, $d, $i, $r) = @_;
    },
    undef,
), STATUSCODE_GOOD, "connect async bad url");
undef $tcp_server;
$client->iterate(undef, "connect bad url");
is($client->{client}->getState(), CLIENTSTATE_DISCONNECTED,
    "client bad connection");

no_leaks_ok {
    $tcp_server = IO::Socket::INET->new(
	LocalAddr	=> "localhost",
	LocalPort	=> $tcp_port,
	Proto		=> "tcp",
	Listen		=> 1,
    );
    $client->{client}->connect_async(
	$client->url(),
	sub {
	    my ($c, $d, $i, $r) = @_;
	},
	undef,
    );
    undef $tcp_server;
    $client->iterate(undef);
} "connect async bad url leak";

# connect to invalid url fails, check that it does not leak
$data = "foo";
is($client->{client}->connect_async(
    "opc.tcp://localhost:",
    sub {
	my ($c, $d, $i, $r) = @_;
	fail "callback called";
    },
    \$data,
), STATUSCODE_BADCONNECTIONCLOSED, "connect async fail");
is($data, "foo", "data fail");
no_leaks_ok {
    $client->{client}->connect_async(
	"opc.tcp://localhost:",
	sub {
	    my ($c, $d, $i, $r) = @_;
	},
	\$data,
    );
} "connect async fail leak";

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
