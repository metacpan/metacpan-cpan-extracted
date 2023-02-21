use strict;
use warnings;
use OPCUA::Open62541 qw(:STATUSCODE :SESSIONSTATE :SECURECHANNELSTATE);
use IO::Socket::INET;
use Scalar::Util qw(looks_like_number);
use Time::HiRes qw(sleep);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() * 4 + 8;
use Test::Deep;
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
$client->{config}->setStateCallback(
    sub {
	my ($c, $scs, $ss, $cs) = @_;

	# callback is called at state changes
	return unless $ss == SESSIONSTATE_ACTIVATED;

	is_deeply([$c->getState()], [$scs, $ss, $cs],
	    "callback client state");
	my $d = $c->getConfig()->getClientContext();
	is($d->[0], "foo", "callback data in");
	push @$d, 'bar';
	is($ss, SESSIONSTATE_ACTIVATED, "callback session state");
	is($cs, STATUSCODE_GOOD, "callback status code");

	$connected = 1;
    }
);
$client->{config}->setClientContext($data);
is($client->{client}->connectAsync($client->url()), STATUSCODE_GOOD,
    "connect async");
# wait an initial 100ms for open62541 to start the timer that creates the socket
sleep .1;
$client->iterate(\$connected, "connect");
$client->{config}->setStateCallback(undef);
$client->{config}->setClientContext(undef);
is_deeply([$client->{client}->getState()],
    [SECURECHANNELSTATE_OPEN, SESSIONSTATE_ACTIVATED, STATUSCODE_GOOD],
    "client state");
is($data->[1], "bar", "callback data out");

$client->stop();

$client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();

# Run the test again, check for leaks, no check within leak detection.
# Although no_leaks_ok runs the code block multiple times, the callback
# is only called once.
$connected = 0;
no_leaks_ok {
    $client->{config}->setStateCallback(
	sub {
	    my ($c, $scs, $ss, $cs) = @_;
	    return unless $ss == SESSIONSTATE_ACTIVATED;
	    $connected = 1;
	}
    );
    $client->{config}->setClientContext($data);
    $client->{client}->connectAsync($client->url());
    sleep .1;
    $client->iterate(\$connected);
    $client->{config}->setStateCallback(undef);
    $client->{config}->setClientContext(undef);
} "connect async leak";

$client->stop();

# run test without connect callback
$client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();

$client->{config}->setStateCallback(undef);
is($client->{client}->connectAsync($client->url()), STATUSCODE_GOOD,
    "connect async undef callback");
sleep .1;
$client->iterate_connect("connect undef callback");
is_deeply([$client->{client}->getState()],
    [SECURECHANNELSTATE_OPEN, SESSIONSTATE_ACTIVATED, STATUSCODE_GOOD],
    "state undef callback");

$client->stop();

# the connection itself gets established in run_iterate. so this call should
# also succeed if no server is running
no_leaks_ok { $client->{client}->connectAsync($client->url()); }
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

$client->{config}->setStateCallback(
    sub {
	my ($c, $scs, $ss, $cs) = @_;
    }
);
is($client->{client}->connectAsync($client->url()), STATUSCODE_GOOD,
    "connect async bad url");
undef $tcp_server;
sleep .1;
$client->iterate_disconnect("connect bad url");
$client->{config}->setStateCallback(undef);
$client->{config}->setClientContext(undef);
my $channel = defined &SECURECHANNELSTATE_FRESH ?
    SECURECHANNELSTATE_FRESH : SECURECHANNELSTATE_CLOSED;
cmp_deeply([$client->{client}->getState()],
    [$channel, SESSIONSTATE_CLOSED, any(STATUSCODE_GOOD,
    STATUSCODE_BADDISCONNECT, STATUSCODE_BADCONNECTIONCLOSED)],
    "client bad connection");

no_leaks_ok {
    $tcp_server = IO::Socket::INET->new(
	LocalAddr	=> "localhost",
	LocalPort	=> $tcp_port,
	Proto		=> "tcp",
	Listen		=> 1,
    );
    $client->{config}->setStateCallback(
	sub {
	    my ($c, $scs, $ss, $cs) = @_;
	    note "$c, $scs, $ss, $cs";
	}
    );
    $client->{client}->connectAsync($client->url());
    undef $tcp_server;
    sleep .1;
    $client->iterate_disconnect();
    $client->{config}->setStateCallback(undef);
    $client->{config}->setClientContext(undef);
} "connect async bad url leak";

# clean up connection state, dangling connection may affect next test
$client->iterate_disconnect();

# connect to invalid url fails, check that it does not leak
$data = "foo";
$client->{config}->setStateCallback(
    sub {
	my ($c, $d, $i, $r) = @_;
	fail "callback called";
    }
);
$client->{config}->setClientContext(\$data);
is($client->{client}->connectAsync("opc.tcp://localhost:"),
    STATUSCODE_BADCONNECTIONCLOSED, "connect async fail");
is($data, "foo", "data fail");
no_leaks_ok {
    $client->{config}->setStateCallback(
	sub {
	    my ($c, $d, $i, $r) = @_;
	}
    );
    $client->{config}->setClientContext(\$data);
    $client->{client}->connectAsync("opc.tcp://localhost:");
} "connect async fail leak";

throws_ok { $client->{config}->setStateCallback("foo") }
    (qr/Callback 'foo' is not a CODE reference /,
    "callback not reference");
no_leaks_ok { eval { $client->{config}->setStateCallback("foo") } }
    "callback not reference leak";

throws_ok { $client->{config}->setStateCallback([]) }
    (qr/Callback 'ARRAY.*' is not a CODE reference /,
    "callback not code reference");
no_leaks_ok { eval { $client->{config}->setStateCallback([]) } }
    "callback not code reference leak";
