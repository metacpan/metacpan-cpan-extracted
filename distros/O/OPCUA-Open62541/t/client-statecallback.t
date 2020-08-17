use strict;
use warnings;
use OPCUA::Open62541 qw(STATUSCODE_GOOD :CLIENTSTATE);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More;
BEGIN {
    my @statearray = OPCUA::Open62541::Client->new()->getState();
    my $calltests = @statearray == 3 ? 10 * 4 : 4 * 2;
    plan tests =>
	OPCUA::Open62541::Test::Server::planning() +
	OPCUA::Open62541::Test::Client::planning() + 16 + $calltests;
}
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
    qr/Context 'foo' is not a CODE reference /, "state callback array";
no_leaks_ok { eval { $config->setStateCallback("foo") } }
    "state callback array leak";
throws_ok { $config->setStateCallback([]) }
    qr/Context 'ARRAY.*' is not a CODE reference /, "state callback array";
no_leaks_ok { eval { $config->setStateCallback([]) } }
    "state callback array leak";
undef $config;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
$client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$server->run();

ok(my @statearray = $client->{client}->getState(), "state array");

my @states;
# 1.1 API
sub callback3 {
    my ($c, $channel, $session, $connect) = @_;
    is($c, $client->{client}, "callback client");
    my $state = shift @states;
    is($channel, $state->[0], "callback channel");
    is($session, $state->[1], "callback session");
    is($connect, $state->[2], "callback connect");
}
# 1.0 API
sub callback {
    my ($c, $state) = @_;
    is($c, $client->{client}, "callback client");
    is($state, shift @states, "callback state");
}
my $callback = @statearray == 3 ? \&callback3 : \&callback;
lives_ok { $client->{config}->setStateCallback($callback); }
    "set state callback";

@states = @statearray == 3 ? (
    [ 1, 0, 0 ],
    [ 4, 0, 0 ],
    [ 5, 0, 0 ],
    [ 6, 0, 0 ],
    [ 6, 1, 0 ],
    [ 6, 2, 0 ],
    [ 6, 3, 0 ],
    [ 6, 4, 0 ],
) : (
    CLIENTSTATE_CONNECTED,
    CLIENTSTATE_SECURECHANNEL,
    CLIENTSTATE_SESSION,
);
$client->run();
is(scalar @states, 0, "states connected");

@states = @statearray == 3 ? (
    [ 6, 5, 0 ],
    [ 0, 0, 0 ],
) : (
    CLIENTSTATE_DISCONNECTED,
);
$client->stop();
is(scalar @states, 0, "states disconnected");

$server->stop();
