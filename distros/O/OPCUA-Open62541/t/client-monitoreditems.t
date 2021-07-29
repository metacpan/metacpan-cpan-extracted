use strict;
use warnings;

use OPCUA::Open62541 qw(:all);
use OPCUA::Open62541::Test::Client;
use OPCUA::Open62541::Test::Server;

use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 26;
use Test::Deep;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();

$server->start();
$server->run();

my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();
$client->run();

# pre create subscription

my $subcontext;
my $request = OPCUA::Open62541::Client->CreateSubscriptionRequest_default();
my $response = $client->{client}->Subscriptions_create($request, \$subcontext, undef, undef);
is($response->{CreateSubscriptionResponse_responseHeader}{ResponseHeader_serviceResult},
   "Good",
   "subscription create response statuscode");
my $subid = $response->{CreateSubscriptionResponse_subscriptionId};

# MonitoredItemCreateRequest_default

my $expected_request = {
    MonitoredItemCreateRequest_requestedParameters => {
	MonitoringParameters_samplingInterval => 250,
	MonitoringParameters_queueSize => 1,
	MonitoringParameters_clientHandle => 0,
	MonitoringParameters_filter => ignore(),
	MonitoringParameters_discardOldest => 1
    },
    MonitoredItemCreateRequest_monitoringMode => MONITORINGMODE_REPORTING,
    MonitoredItemCreateRequest_itemToMonitor => {
	ReadValueId_indexRange => undef,
	ReadValueId_nodeId => {
	    NodeId_identifier => NS0ID_SERVER_SERVERSTATUS_CURRENTTIME,
	    NodeId_identifierType => 0,
	    NodeId_namespaceIndex => 0
	},
	ReadValueId_attributeId => ATTRIBUTEID_VALUE,
	ReadValueId_dataEncoding => ignore(),
    }
};
$request = OPCUA::Open62541::Client->MonitoredItemCreateRequest_default({
    NodeId_identifier => NS0ID_SERVER_SERVERSTATUS_CURRENTTIME,
    NodeId_identifierType => 0,
    NodeId_namespaceIndex => 0,
});
cmp_deeply($request,
	   $expected_request,
	   "default monitored item create request");

# MonitoredItems_createDataChange

throws_ok { $client->{client}->MonitoredItems_createDataChange(
    -1, TIMESTAMPSTORETURN_BOTH, $request, undef, undef, undef
)}
    (qr/XS_unpack_UA_UInt32: Unsigned value \d+ greater than UA_UINT32_MAX/,
    "monitored items create negative subscription ID");

my ($deleted, $moncontext, @values);
$response = $client->{client}->MonitoredItems_createDataChange(
    999,
    TIMESTAMPSTORETURN_BOTH,
    $request,
    \$moncontext,
    sub {
	my ($cl, $sid, $sctx, $mid, $mctx, $v) = @_;
	$$mctx++;
	push @values, $v->{DataValue_value}{Variant_scalar};
    },
    sub {
	my ($cl, $sid, $sctx, $mid, $mctx) = @_;
	$deleted = 1;
    },
);

is($response->{MonitoredItemCreateResult_statusCode},
   "BadSubscriptionIdInvalid",
   "monitored items create fail response statuscode");

is($deleted,
   1,
   "subscription deleted callback");
$deleted = undef;

my $expected_response = {
    MonitoredItemCreateResult_filterResult => ignore(),
    MonitoredItemCreateResult_revisedSamplingInterval => '250',
    MonitoredItemCreateResult_monitoredItemId => 1,
    MonitoredItemCreateResult_statusCode => 'Good',
    MonitoredItemCreateResult_revisedQueueSize => 1
};

$response = $client->{client}->MonitoredItems_createDataChange(
    $subid,
    TIMESTAMPSTORETURN_BOTH,
    $request,
    \$moncontext,
    sub {
	my ($cl, $sid, $sctx, $mid, $mctx, $v) = @_;
	$$mctx++;
	push @values, $v->{DataValue_value}{Variant_scalar};
    },
    sub {
	my ($cl, $sid, $sctx, $mid, $mctx) = @_;
	$deleted = 1;
    },
);

cmp_deeply($response,
	   $expected_response,
	   "subscription create response");

is($response->{MonitoredItemCreateResult_statusCode},
   "Good",
   "monitored items create response statuscode");

is($deleted,
   undef,
   "subscription not deleted callback");
is($subcontext,
   undef,
   "subscription context callback");
is($moncontext,
   undef,
   "monitored item context callback");

my $monid = $response->{MonitoredItemCreateResult_monitoredItemId};

my $i;
$client->iterate(sub {sleep 1; ++$i > 3});

ok($moncontext > 3,
   "monitored item context multiple calls");
ok(@values == $moncontext,
   "monitored item context same as values");
ok("@values" eq "@{[sort @values]}",
   "monitored item values sorted");

# delete monitored items

$response = $client->{client}->MonitoredItems_deleteSingle($subid, $monid);
is($response,
   "Good",
   "subscription delete response statuscode");

# delete subscription and monitored items

$response = $client->{client}->MonitoredItems_createDataChange(
    $subid, TIMESTAMPSTORETURN_BOTH, $request, undef, undef, undef
);
is($response->{MonitoredItemCreateResult_statusCode},
   "Good",
   "monitored items create response statuscode");

$response = $client->{client}->Subscriptions_deleteSingle($subid);
is($response,
   "Good",
   "subscription delete response statuscode");

is($deleted,
   1,
   "subscription deleted callback");

################################################################################

$request = OPCUA::Open62541::Client->CreateSubscriptionRequest_default();
$response = $client->{client}->Subscriptions_create($request, \$subcontext, undef, undef);
is($response->{CreateSubscriptionResponse_responseHeader}{ResponseHeader_serviceResult},
   "Good",
   "subscription create response statuscode");
$subid = $response->{CreateSubscriptionResponse_subscriptionId};

# no_leaks

no_leaks_ok {
    $request = OPCUA::Open62541::Client->MonitoredItemCreateRequest_default({
	NodeId_identifier => NS0ID_SERVER_SERVERSTATUS_CURRENTTIME,
	NodeId_identifierType => 0,
	NodeId_namespaceIndex => 0,
    });
} "MonitoredItemCreateRequest_default leak";

no_leaks_ok {
    $response = $client->{client}->MonitoredItems_createDataChange(
	$subid,
	TIMESTAMPSTORETURN_BOTH,
	$request,
	undef,
	undef,
	undef,
    );
} "MonitoredItems_createDataChange leak";

is($response->{MonitoredItemCreateResult_statusCode},
   "Good",
   "monitored items create response statuscode");

no_leaks_ok {
    $response = $client->{client}->MonitoredItems_createDataChange(
	999,
	TIMESTAMPSTORETURN_BOTH,
	$request,
	undef,
	undef,
	undef,
    );
} "MonitoredItems_createDataChange fail leak";

no_leaks_ok {
    $response = $client->{client}->MonitoredItems_createDataChange(
	999,
	TIMESTAMPSTORETURN_BOTH,
	$request,
	\$moncontext,
	sub {
	    my ($cl, $sid, $sctx, $mid, $mctx, $v) = @_;
	    $$mctx++;
	},
	sub {
	    $deleted = 1;
	},
    );
} "MonitoredItems_createDataChange fail callback leak";

is($response->{MonitoredItemCreateResult_statusCode},
   "BadSubscriptionIdInvalid",
   "monitored items create response fail statuscode");

no_leaks_ok {
    $response = $client->{client}->MonitoredItems_createDataChange(
	$subid,
	TIMESTAMPSTORETURN_BOTH,
	$request,
	\$moncontext,
	sub {
	    my ($cl, $sid, $sctx, $mid, $mctx, $v) = @_;
	    $$mctx++;
	},
	sub {
	    $deleted = 1;
	},
    );
    $monid = $response->{MonitoredItemCreateResult_monitoredItemId};
    $response = $client->{client}->MonitoredItems_deleteSingle($subid, $monid);
} "MonitoredItems_createDataChange + delete callback leak";

$client->stop();
$server->stop();
