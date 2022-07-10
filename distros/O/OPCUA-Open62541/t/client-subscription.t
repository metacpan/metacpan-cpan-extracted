use strict;
use warnings;

use OPCUA::Open62541 qw(:all);
use OPCUA::Open62541::Test::Server;
use OPCUA::Open62541::Test::Client;
use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 42;
use Test::Deep;
use Test::NoWarnings;
use Test::LeakTrace;

my $server = OPCUA::Open62541::Test::Server->new();

$server->start();
$server->{config}->setMaxSubscriptions(2);
$server->run();

my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$client->run();

# CreateSubscriptionRequest_default

my $expected_request = {
    CreateSubscriptionRequest_requestedPublishingInterval => 500,
    CreateSubscriptionRequest_requestedLifetimeCount => 10000,
    CreateSubscriptionRequest_requestedMaxKeepAliveCount => 10,
    CreateSubscriptionRequest_maxNotificationsPerPublish => 0,
    CreateSubscriptionRequest_publishingEnabled => 1,
    CreateSubscriptionRequest_priority => 0,
    CreateSubscriptionRequest_requestHeader => ignore(),
};
my $request = OPCUA::Open62541::Client->CreateSubscriptionRequest_default();

cmp_deeply($request,
	   $expected_request,
	   "default subscription request");

# Subscriptions_create

my $expected_response = {
    CreateSubscriptionResponse_subscriptionId => 1,
    CreateSubscriptionResponse_revisedPublishingInterval => '500',
    CreateSubscriptionResponse_revisedMaxKeepAliveCount => 10,
    CreateSubscriptionResponse_revisedLifetimeCount => 10000,
    CreateSubscriptionResponse_responseHeader => ignore(),
};

my ($deleted, $context);

my $response = $client->{client}->Subscriptions_create(
    $request,
    \$context,
    sub {$context++},
    sub {
	my ($client, $id, $ctx) = @_;
	$deleted = 1;
	$$ctx = $id;
    },
);

cmp_deeply($response,
	   $expected_response,
	   "subscription create response");

is($response->{CreateSubscriptionResponse_responseHeader}{ResponseHeader_serviceResult},
   "Good",
   "subscription create response statuscode");

is($deleted,
   undef,
   "subscription not deleted callback");
is($context,
   undef,
   "subscription context callback");

# Subscriptions_modify

my $subid = $response->{CreateSubscriptionResponse_subscriptionId};
$response = $client->{client}->Subscriptions_modify({
    ModifySubscriptionRequest_subscriptionId => $subid,
    ModifySubscriptionRequest_requestedPublishingInterval => 1000,
});

is($response->{ModifySubscriptionResponse_responseHeader}{ResponseHeader_serviceResult},
   "Good",
   "subscription modify response statuscode");

is($response->{ModifySubscriptionResponse_revisedPublishingInterval},
   1000,
   "subscription modified");

# Subscriptions_setPublishingMode

$response = $client->{client}->Subscriptions_setPublishingMode({
    SetPublishingModeRequest_subscriptionIds => [$subid],
    SetPublishingModeRequest_publishingEnabled => 0,
});

is($response->{SetPublishingModeResponse_responseHeader}{ResponseHeader_serviceResult},
   "Good",
   "subscription SetPublishingMode response statuscode");

is($response->{SetPublishingModeResponse_results}[0],
   "Good",
   "subscription SetPublishingMode result statuscode");

# Subscriptions_delete

$response = $client->{client}->Subscriptions_delete({
    DeleteSubscriptionsRequest_subscriptionIds => [$subid],
});

is($response->{DeleteSubscriptionsResponse_responseHeader}{ResponseHeader_serviceResult},
   "Good",
   "subscription delete response statuscode");

is($response->{DeleteSubscriptionsResponse_results}[0],
   "Good",
   "subscription delete result statuscode");

is($deleted,
   1,
   "subscription deleted callback");
is($context,
   $subid,
   "subscription context callback");

# try again and expect failure
$response = $client->{client}->Subscriptions_delete({
    DeleteSubscriptionsRequest_subscriptionIds => [$subid],
});

is($response->{DeleteSubscriptionsResponse_responseHeader}{ResponseHeader_serviceResult},
   "Good",
   "subscription delete failure response statuscode");

is($response->{DeleteSubscriptionsResponse_results}[0],
   "BadSubscriptionIdInvalid",
   "subscription delete failure result statuscode");

# Subscriptions_deleteSingle

# create another subscription
$response = $client->{client}->Subscriptions_create($request, undef, undef, undef);
is($response->{CreateSubscriptionResponse_responseHeader}{ResponseHeader_serviceResult},
   "Good",
   "subscription create response statuscode");
$subid = $response->{CreateSubscriptionResponse_subscriptionId};

$response = $client->{client}->Subscriptions_deleteSingle($subid);

is($response,
   "Good",
   "subscription deleteSingle response statuscode");

# try again and expect failure
$response = $client->{client}->Subscriptions_deleteSingle($subid);

is($response,
   "BadSubscriptionIdInvalid",
   "subscription deleteSingle failure response statuscode");

################################################################################

# no_leaks

no_leaks_ok {
    $request = OPCUA::Open62541::Client->CreateSubscriptionRequest_default();
} "CreateSubscriptionRequest_default leak";

no_leaks_ok {
    $response = $client->{client}->Subscriptions_create($request, undef, undef, undef);
} "Subscriptions create leak";

is($response->{CreateSubscriptionResponse_responseHeader}{ResponseHeader_serviceResult},
   "Good",
   "subscription create response statuscode");

$subid = $response->{CreateSubscriptionResponse_subscriptionId};
no_leaks_ok {
    $response = $client->{client}->Subscriptions_modify({
	ModifySubscriptionRequest_subscriptionId => $subid,
	ModifySubscriptionRequest_requestedPublishingInterval => 1000,
    });
} "Subscriptions_modify leak";

is($response->{ModifySubscriptionResponse_responseHeader}{ResponseHeader_serviceResult},
   "Good",
   "subscription modify response statuscode");

no_leaks_ok {
    $response = $client->{client}->Subscriptions_setPublishingMode({
	SetPublishingModeRequest_subscriptionIds => [$subid],
	SetPublishingModeRequest_publishingEnabled => 0,
    });
} "Subscriptions_setPublishingMode leak";

is($response->{SetPublishingModeResponse_results}[0],
   "Good",
   "subscription setPublishingMode result statuscode");

# the requests are actually made twice in no_leaks_ok. so we have to save the
# first result/statuscode to check it later (or the delete will have a bad statuscode)
my $status;
no_leaks_ok {
    $response = $client->{client}->Subscriptions_delete({
	DeleteSubscriptionsRequest_subscriptionIds => [$subid],
    });
    $status //= $response->{DeleteSubscriptionsResponse_results}[0];
} "Subscriptions_delete leak";

is($status,
   "Good",
   "subscription delete result statuscode");

$status = undef;
no_leaks_ok {
    $response = $client->{client}->Subscriptions_delete({
	DeleteSubscriptionsRequest_subscriptionIds => [$subid],
    });
    $status //= $response->{DeleteSubscriptionsResponse_results}[0];
} "Subscriptions_delete failure leak";

is($status,
   "BadSubscriptionIdInvalid",
   "subscription delete failure result statuscode");

# create another subscription
$response = $client->{client}->Subscriptions_create($request, undef, undef, undef);
is($response->{CreateSubscriptionResponse_responseHeader}{ResponseHeader_serviceResult},
   "Good",
   "subscription create response statuscode");
$subid = $response->{CreateSubscriptionResponse_subscriptionId};

$status = undef;
no_leaks_ok {
    $status //= $client->{client}->Subscriptions_deleteSingle($subid);
} "Subscriptions_deleteSingle leak";

is($status,
   "Good",
   "subscription deleteSingle response statuscode");

$status = undef;
no_leaks_ok {
    $status = $client->{client}->Subscriptions_deleteSingle($subid);
} "Subscriptions_deleteSingle failure leak";

is($status,
   "BadSubscriptionIdInvalid",
   "subscription deleteSingle failure response statuscode");

($deleted, $context) = (undef, undef);
no_leaks_ok {
    $response = $client->{client}->Subscriptions_create(
	$request,
	$context,
	undef,
	sub {$deleted = 1; $context = "foo"}
    );
    $subid = $response->{CreateSubscriptionResponse_subscriptionId};
    $status = $client->{client}->Subscriptions_deleteSingle($subid);
} "Subscriptions create delete callback leak";

is($deleted,
   1,
   "subscription deleted callback");
is($context,
   "foo",
   "subscription context callback");

# reach the limit of subscriptions
$response = $client->{client}->Subscriptions_create($request, undef, undef, undef);
is($response->{CreateSubscriptionResponse_responseHeader}{ResponseHeader_serviceResult},
   "Good",
   "subscription create response statuscode");
$response = $client->{client}->Subscriptions_create($request, undef, undef, undef);
is($response->{CreateSubscriptionResponse_responseHeader}{ResponseHeader_serviceResult},
   "BadTooManySubscriptions",
   "subscription create response too many");

($deleted, $context) = (undef, undef);
$response = $client->{client}->Subscriptions_create(
    $request,
    $context,
    sub {},
    sub {$deleted = 1; $context = "foo"},
);
is($response->{CreateSubscriptionResponse_responseHeader}{ResponseHeader_serviceResult},
   "BadTooManySubscriptions",
   "subscription create response too many");

$client->stop();

($deleted, $context) = (undef, undef);
no_leaks_ok {
    $client->{client}->connect($client->{url});
    $response = $client->{client}->Subscriptions_create(
	$request,
	$context,
	sub {},
	sub {$deleted = 1; $context = "foo"},
    );
    # open52651 1.3 disconnect calls the callback that frees the context
    $client->{client}->disconnect();
} "Subscriptions create too many callback leak";

$server->stop();
