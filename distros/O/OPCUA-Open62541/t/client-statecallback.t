use strict;
use warnings;
use OPCUA::Open62541 qw(STATUSCODE_GOOD :SECURECHANNELSTATE :SESSIONSTATE);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 15 + 10 * 4;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;
use Test::Warn;

ok(my $client = OPCUA::Open62541::Client->new(), "client");
ok(my $config = $client->getConfig(), "config");
lives_ok { $config->setStateCallback(sub {}) }
    "state callback";
no_leaks_ok { $config->setStateCallback(sub {}) }
    "state callback leak";
lives_ok { $config->setStateCallback(undef) }
    "state callback undef";
no_leaks_ok { $config->setStateCallback(undef) }
    "state callback undef leak";
no_leaks_ok {
    $config->setStateCallback(sub {});
    $config->setStateCallback(undef);
} "state callback set unset";
throws_ok { $config->setStateCallback("foo") }
    qr/Callback 'foo' is not a CODE reference /, "state callback code";
no_leaks_ok { eval { $config->setStateCallback("foo") } }
    "state callback code leak";
throws_ok { $config->setStateCallback([]) }
    qr/Callback 'ARRAY.*' is not a CODE reference /, "state callback array";
no_leaks_ok { eval { $config->setStateCallback([]) } }
    "state callback array leak";
undef $config;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
$client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$server->run();

my @states;
my $callback = sub {
    my ($c, $channel, $session, $connect) = @_;
    is($c, $client->{client}, "callback client");
    my $count = @states;
    my $state = shift @states;
    is($channel, $state->[0], "callback channel $count");
    is($session, $state->[1], "callback session $count");
    is($connect, $state->[2], "callback connect $count");
};
lives_ok { $client->{config}->setStateCallback($callback); }
    "set state callback";

@states = (
    [ SECURECHANNELSTATE_HEL_SENT,	SESSIONSTATE_CLOSED,
	STATUSCODE_GOOD ],
    [ SECURECHANNELSTATE_ACK_RECEIVED,	SESSIONSTATE_CLOSED,
	STATUSCODE_GOOD],
    [ SECURECHANNELSTATE_OPN_SENT,	SESSIONSTATE_CLOSED,
	STATUSCODE_GOOD],
    [ SECURECHANNELSTATE_OPEN,		SESSIONSTATE_CLOSED,
	STATUSCODE_GOOD],
    [ SECURECHANNELSTATE_OPEN,		SESSIONSTATE_CREATE_REQUESTED,
	STATUSCODE_GOOD],
    [ SECURECHANNELSTATE_OPEN,		SESSIONSTATE_CREATED,
	STATUSCODE_GOOD],
    [ SECURECHANNELSTATE_OPEN,		SESSIONSTATE_ACTIVATE_REQUESTED,
	STATUSCODE_GOOD],
    [ SECURECHANNELSTATE_OPEN,		SESSIONSTATE_ACTIVATED,
	STATUSCODE_GOOD],
);
$client->run();
is(scalar @states, 0, "states connected");

@states = (
    [ SECURECHANNELSTATE_OPEN,		SESSIONSTATE_CLOSING,
	STATUSCODE_GOOD ],
    [ SECURECHANNELSTATE_CLOSED,	SESSIONSTATE_CLOSED,
	STATUSCODE_GOOD ],
);
$client->stop();
is(scalar @states, 0, "states disconnected");

$server->stop();
