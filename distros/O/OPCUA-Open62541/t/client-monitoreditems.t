use strict;
use warnings;

use OPCUA::Open62541 qw(:all);
use OPCUA::Open62541::Test::Client;
use OPCUA::Open62541::Test::Server;

use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 41;
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

my (%subcontext, @notifications);
my $request = OPCUA::Open62541::Client->CreateSubscriptionRequest_default();
my $response = $client->{client}->Subscriptions_create(
    $request,
    \%subcontext,
    sub {
	my ($cl, $sid, $sctx, $n) = @_;
	$sctx->{sub}++;
	push @notifications, $n;
    },
    sub {
	my ($cl, $sid, $sctx) = @_;
	$sctx->{sub_delete}++;
    },
);
is($response->{CreateSubscriptionResponse_responseHeader}
    {ResponseHeader_serviceResult},
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
    (qr/unpack_UA_UInt32: Unsigned value \d+ greater than UA_UINT32_MAX/,
    "monitored items create negative subscription ID");

my ($deleted, %moncontext, @values);
$response = $client->{client}->MonitoredItems_createDataChange(
    999,
    TIMESTAMPSTORETURN_BOTH,
    $request,
    \%moncontext,
    sub {},
    sub {
	$deleted = 1;
    },
);

is($response->{MonitoredItemCreateResult_statusCode},
   "BadSubscriptionIdInvalid",
   "monitored items create fail response statuscode");

ok(my $buildinfo = $server->{config}->getBuildInfo());
note explain $buildinfo;
# the semantics whether the callback is called in case of error has changed
if ($buildinfo->{BuildInfo_softwareVersion} =~ /^1\.0\./) {
    ok($deleted,
       "subscription deleted callback");
} else {
    is($deleted, undef,
       "subscription deleted callback");
}

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
    \%moncontext,
    sub {
	my ($cl, $sid, $sctx, $mid, $mctx, $v) = @_;
	$sctx->{mon}++;
	$mctx->{mon}++;
	push @values, $v->{DataValue_value}{Variant_scalar};
    },
    sub {
	my ($cl, $sid, $sctx, $mid, $mctx) = @_;
	$sctx->{mon_delete}++;
	$mctx->{mon_delete}++;
    },
);

cmp_deeply($response,
	   $expected_response,
	   "subscription create response");

is($response->{MonitoredItemCreateResult_statusCode},
   "Good",
   "monitored items create response statuscode");

is($subcontext{mon}, undef,
   "subscription context callback");
is($moncontext{mon}, undef,
   "monitored item context callback");
is($subcontext{mon_delete}, undef,
   "subscription context delete callback");
is($moncontext{mon_delete}, undef,
   "monitored item context delete callback");

my $monid = $response->{MonitoredItemCreateResult_monitoredItemId};

my $i;
$client->iterate(sub {sleep 1; ++$i > 3});

cmp_ok($subcontext{mon}, '==', 6,
   "subscription context multiple calls");
cmp_ok($moncontext{mon}, '==', 6,
   "monitored item context multiple calls");
cmp_ok(@values, '==', 6,
   "monitored item context same as values");
is("@values", "@{[sort @values]}",
   "monitored item values sorted");
is($subcontext{mon_delete}, undef,
   "subscription context no mon delete calls");
is($moncontext{mon_delete}, undef,
   "monitored item context no mon delete calls");

# delete monitored items

$response = $client->{client}->MonitoredItems_deleteSingle($subid, $monid);
is($response,
   "Good",
   "subscription delete response statuscode");

cmp_ok($subcontext{mon_delete}, '==', 1,
   "subscription context mon delete call");
cmp_ok($moncontext{mon_delete}, '==', 1,
   "monitored item context mon delete call");
is($subcontext{sub_delete}, undef,
   "subscription context no sub delete calls");

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

cmp_ok($subcontext{mon_delete}, '==', 1,
   "subscription context mon delete call");
cmp_ok($moncontext{mon_delete}, '==', 1,
   "monitored item context mon delete call");
cmp_ok($subcontext{sub_delete}, '==', 1,
   "subscription context sub delete call");

################################################################################

$request = OPCUA::Open62541::Client->CreateSubscriptionRequest_default();
$response = $client->{client}->Subscriptions_create(
    $request,
    \%subcontext,
    sub {
	my ($cl, $sid, $sctx, $n) = @_;
	$sctx->{sub}++;
    },
    sub {
	my ($cl, $sid, $sctx) = @_;
	$sctx->{sub_delete}++;
    },
);
is($response->{CreateSubscriptionResponse_responseHeader}
    {ResponseHeader_serviceResult},
    "Good",
    "subscription create response statuscode");
$subid = $response->{CreateSubscriptionResponse_subscriptionId};

# create multiple MonitoredItemCreateRequests to check memory managemnt

for (1..5) {
    ok(OPCUA::Open62541::Client->MonitoredItemCreateRequest_default({
	NodeId_namespaceIndex => 1,
	NodeId_identifierType => NODEIDTYPE_STRING,
	NodeId_identifier     => "var1",
    }), "multi MonitoredItemCreateRequest_default $_");
}

# no_leaks

no_leaks_ok {
    $request = OPCUA::Open62541::Client->MonitoredItemCreateRequest_default({
	NodeId_identifier => NS0ID_SERVER_SERVERSTATUS_CURRENTTIME,
	NodeId_identifierType => 0,
	NodeId_namespaceIndex => 0,
    });
} "MonitoredItemCreateRequest_default leak";

no_leaks_ok {
    $i = 0;
    $response = $client->{client}->MonitoredItems_createDataChange(
	$subid,
	TIMESTAMPSTORETURN_BOTH,
	$request,
	undef,
	undef,
	undef,
    );
    # iterate until all delete callbacks have been called
    $client->iterate(sub {sleep 1; ++$i > 10 &&
	$response->{MonitoredItemCreateResult_statusCode} eq 'Good'});
} "MonitoredItems_createDataChange leak";

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
	\%moncontext,
	sub {
	    my ($cl, $sid, $sctx, $mid, $mctx, $v) = @_;
	    $sctx->{mon}++;
	    $mctx->{mon}++;
	},
	sub {
	    my ($cl, $sid, $sctx, $mid, $mctx, $v) = @_;
	    $sctx->{mon_delete}++;
	    $mctx->{mon_delete}++;
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
	\%moncontext,
	sub {
	    my ($cl, $sid, $sctx, $mid, $mctx, $v) = @_;
	    $sctx->{mon}++;
	    $mctx->{mon}++;
	},
	sub {
	    my ($cl, $sid, $sctx, $mid, $mctx, $v) = @_;
	    $sctx->{mon_delete}++;
	    $mctx->{mon_delete}++;
	},
    );
    $monid = $response->{MonitoredItemCreateResult_monitoredItemId};
    $response = $client->{client}->MonitoredItems_deleteSingle($subid, $monid);
} "MonitoredItems_createDataChange + delete callback leak";

no_leaks_ok {
    for (1..5) {
	OPCUA::Open62541::Client->MonitoredItemCreateRequest_default({
	    NodeId_namespaceIndex => 1,
	    NodeId_identifierType => NODEIDTYPE_STRING,
	    NodeId_identifier     => "var1",
	});
    }
} "multi MonitoredItemCreateRequest_default leak";

$client->stop();
$server->stop();
