use strict;
use warnings;
use OPCUA::Open62541 qw(:STATUSCODE);

use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 11;
use Test::Deep;
use Test::Exception;
use Test::NoWarnings;
use Test::LeakTrace;


my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$server->run();
$client->run();

my $request = OPCUA::Open62541::Client->CreateSubscriptionRequest_default();
my $response = {
    CreateSubscriptionResponse_subscriptionId => 1,
    CreateSubscriptionResponse_revisedPublishingInterval => '500',
    CreateSubscriptionResponse_revisedMaxKeepAliveCount => 10,
    CreateSubscriptionResponse_revisedLifetimeCount => 10000,
    CreateSubscriptionResponse_responseHeader => ignore(),
};

### deep

my ($deleted, $context, $reqid);
my $data = "foo",
my $subscribed = 0;
is($client->{client}->Subscriptions_create_async(
    $request,
    \$context,
    sub {$context++},
    sub {
	my ($client, $id, $ctx) = @_;
	$deleted = 1;
	$$ctx = $id;
    },
    sub {
	my ($c, $d, $i, $r) = @_;

	is($c, $client->{client}, "client");
	is($$d, "foo", "data in");
	$$d = "bar";
	is($i, $reqid, "reqid");
	cmp_deeply($r, $response, "response");

	$subscribed = 1;
    },
    \$data,
    \$reqid,
), STATUSCODE_GOOD, "Subscriptions_create_async");
is($data, "foo", "data unchanged");
like($reqid, qr/^\d+$/, "reqid number");
$client->iterate(\$subscribed, "subscribe deep");
is($data, 'bar', "data out");

my $subid;
no_leaks_ok {
    $subscribed = 0;
    $client->{client}->Subscriptions_create_async(
	$request,
	\$context,
	sub {$context++},
	sub {
	    my ($client, $id, $ctx) = @_;
	    $deleted = 1;
	    $$ctx = $id;
	},
	sub {
	    my ($c, $d, $i, $r) = @_;
	    $subscribed = 1;
	    $subid = $r->{CreateSubscriptionResponse_subscriptionId};
	},
	$data,
	\$reqid,
    );
    $client->iterate(\$subscribed);
    $client->{client}->Subscriptions_delete({
	DeleteSubscriptionsRequest_subscriptionIds => [$subid],
    })
} "Subscriptions_create_async leak";

$client->stop();
$server->stop();
