use strict;
use warnings;
use OPCUA::Open62541 qw(:STATUSCODE :CLIENTSTATE :SESSIONSTATE
    :SECURECHANNELSTATE);
use IO::Socket::INET;
use Scalar::Util qw(looks_like_number);
use Time::HiRes qw(sleep);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() * 4 + 9;
use Test::Deep;
use Test::Exception;
use Test::NoWarnings;
use Test::LeakTrace;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();

# There is a bug in open62541 1.0.1 that crashes the client with a
# segmentation fault.  It happens when the client delete() tries to
# free an uninitialized addrinfo.  It is triggered by destroying a
# client that never did a name lookup.  The OpenBSD port has a patch
# that fixes the bug.  Use the buildinfo from the library to figure
# out if we are affected.  Then skip the tests that trigger it.
# https://github.com/open62541/open62541/commit/
#   f9ceec7be7940495cf2ee091bed1bb5acec74551

my $skip_freeaddrinfo;
ok(my $buildinfo = $server->{config}->getBuildInfo());
note explain $buildinfo;
if ($^O ne 'openbsd' && $buildinfo->{BuildInfo_softwareVersion} =~ /^1\.0\./) {
    $skip_freeaddrinfo = "freeaddrinfo bug in ".
	"library '$buildinfo->{BuildInfo_manufacturerName}' ".
	"version '$buildinfo->{BuildInfo_softwareVersion}' ".
	"operating system '$^O'";
}

my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$server->run();

my $async = OPCUA::Open62541::Client->can('connect_async');

my $data = ['foo'];
my $connected = 0;
if ($async) {
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
} else {
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
    is($client->{client}->connectAsync(
	$client->url(),
    ), STATUSCODE_GOOD, "connect async");
}
# wait an initial 100ms for open62541 to start the timer that creates the socket
sleep .1;
$client->iterate(\$connected, "connect");
$client->{config}->setStateCallback(undef);
$client->{config}->setClientContext(undef);
if ($async) {
    is($client->{client}->getState(), CLIENTSTATE_SESSION,
	"client state");
} else {
    is_deeply([$client->{client}->getState()],
	[SECURECHANNELSTATE_OPEN, SESSIONSTATE_ACTIVATED, STATUSCODE_GOOD],
	"client state");
}
is($data->[1], "bar", "callback data out");

$client->stop();

$client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();

# Run the test again, check for leaks, no check within leak detection.
# Although no_leaks_ok runs the code block multiple times, the callback
# is only called once.
$connected = 0;
no_leaks_ok {
    if ($async) {
	$client->{client}->connect_async(
	    $client->url(),
	    sub {
		my ($c, $d, $i, $r) = @_;
		$connected = 1;
	    },
	    $data
	);
    } else {
	$client->{config}->setStateCallback(
	    sub {
		my ($c, $scs, $ss, $cs) = @_;
		return unless $ss == SESSIONSTATE_ACTIVATED;
		$connected = 1;
	    }
	);
	$client->{config}->setClientContext($data);
	$client->{client}->connectAsync($client->url());
    }
    sleep .1;
    $client->iterate(\$connected);
    $client->{config}->setStateCallback(undef);
    $client->{config}->setClientContext(undef);
} "connect async leak";

$client->stop();

# run test without connect callback
$client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();

if ($async) {
    is($client->{client}->connect_async($client->url(), undef, undef),
	STATUSCODE_GOOD, "connect async undef callback");
} else {
    $client->{config}->setStateCallback(undef);
    is($client->{client}->connectAsync($client->url()),
	STATUSCODE_GOOD, "connect async undef callback");
}
sleep .1;
$client->iterate_connect("connect undef callback");
if ($async) {
    is($client->{client}->getState(), CLIENTSTATE_SESSION,
	"state undef callback");
} else {
    is_deeply([$client->{client}->getState()],
	[SECURECHANNELSTATE_OPEN, SESSIONSTATE_ACTIVATED, STATUSCODE_GOOD],
	"state undef callback");
}

$client->stop();

# the connection itself gets established in run_iterate. so this call should
# also succeed if no server is running
no_leaks_ok {
    if ($async) {
	$client->{client}->connect_async($client->url(), undef, undef);
    } else {
	$client->{client}->connectAsync($client->url());
    }
} "connect async no callback leak";

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

if ($async) {
    is($client->{client}->connect_async(
	$client->url(),
	sub {
	    my ($c, $d, $i, $r) = @_;
	},
	undef,
    ), STATUSCODE_GOOD, "connect async bad url");
} else {
    $client->{config}->setStateCallback(
	sub {
	    my ($c, $scs, $ss, $cs) = @_;
	}
    );
    is($client->{client}->connectAsync(
	$client->url(),
    ), STATUSCODE_GOOD, "connect async bad url");
}
undef $tcp_server;
sleep .1;
$client->iterate_disconnect("connect bad url");
$client->{config}->setStateCallback(undef);
$client->{config}->setClientContext(undef);
if ($async) {
    is($client->{client}->getState(), CLIENTSTATE_DISCONNECTED,
	"client bad connection");
} else {
    # API 1.2 disambiguates fresh from closed.
    my $channel = defined &SECURECHANNELSTATE_FRESH ?
	SECURECHANNELSTATE_FRESH : SECURECHANNELSTATE_CLOSED;
    cmp_deeply([$client->{client}->getState()],
	[$channel, SESSIONSTATE_CLOSED, any(STATUSCODE_GOOD,
	STATUSCODE_BADDISCONNECT, STATUSCODE_BADCONNECTIONCLOSED)],
	"client bad connection");
}

no_leaks_ok {
    $tcp_server = IO::Socket::INET->new(
	LocalAddr	=> "localhost",
	LocalPort	=> $tcp_port,
	Proto		=> "tcp",
	Listen		=> 1,
    );
    if ($async) {
	$client->{client}->connect_async(
	    $client->url(),
	    sub {
		my ($c, $d, $i, $r) = @_;
	    },
	    undef,
	);
    } else {
	$client->{config}->setStateCallback(
	    sub {
		my ($c, $scs, $ss, $cs) = @_;
		note "$c, $scs, $ss, $cs";
	    }
	);
	$client->{client}->connectAsync(
	    $client->url(),
	);
    }
    undef $tcp_server;
    sleep .1;
    $client->iterate_disconnect();
    $client->{config}->setStateCallback(undef);
    $client->{config}->setClientContext(undef);
} "connect async bad url leak";

# clean up connection state, dangling connection may affect next test
$client->iterate_disconnect();

SKIP: {
    skip $skip_freeaddrinfo, 3 if $skip_freeaddrinfo;

# connect to invalid url fails, check that it does not leak
$data = "foo";
if ($async) {
    is($client->{client}->connect_async(
	"opc.tcp://localhost:",
	sub {
	    my ($c, $d, $i, $r) = @_;
	    fail "callback called";
	},
	\$data,
    ), STATUSCODE_BADCONNECTIONCLOSED, "connect async fail");
} else {
    $client->{config}->setStateCallback(
	sub {
	    my ($c, $d, $i, $r) = @_;
	    fail "callback called";
	}
    );
    $client->{config}->setClientContext(\$data);
    is($client->{client}->connectAsync(
	"opc.tcp://localhost:",
    ), STATUSCODE_BADCONNECTIONCLOSED, "connect async fail");
}
is($data, "foo", "data fail");
no_leaks_ok {
    if ($async) {
	$client->{client}->connect_async(
	    "opc.tcp://localhost:",
	    sub {
		my ($c, $d, $i, $r) = @_;
	    },
	    \$data,
	);
    } else {
	$client->{config}->setStateCallback(
	    sub {
		my ($c, $d, $i, $r) = @_;
	    }
	);
	$client->{config}->setClientContext(\$data);
	$client->{client}->connectAsync(
	    "opc.tcp://localhost:",
	);
    }
} "connect async fail leak";

}  # SKIP

throws_ok {
    if ($async) {
	$client->{client}->connect_async($client->url(), "foo", undef);
    } else {
	$client->{config}->setStateCallback("foo");
    }
} (qr/Callback 'foo' is not a CODE reference /,
    "callback not reference");
no_leaks_ok { eval {
    if ($async) {
	$client->{client}->connect_async($client->url(), "foo", undef);
    } else {
	$client->{config}->setStateCallback("foo");
    }
} } "callback not reference leak";

throws_ok {
    if ($async) {
	$client->{client}->connect_async($client->url(), [], undef)
    } else {
	$client->{config}->setStateCallback([]);
    }
} (qr/Callback 'ARRAY.*' is not a CODE reference /,
    "callback not code reference");
no_leaks_ok { eval {
    if ($async) {
	$client->{client}->connect_async($client->url(), [], undef);
    } else {
	$client->{config}->setStateCallback([]);
    }
} } "callback not code reference leak";
