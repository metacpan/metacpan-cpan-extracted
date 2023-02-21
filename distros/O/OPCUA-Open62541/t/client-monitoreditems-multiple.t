use strict;
use warnings;

use OPCUA::Open62541 qw(:all);
use OPCUA::Open62541::Test::Client;
use OPCUA::Open62541::Test::Server;

use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 54;
use Test::Deep;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;

my (@nodes,@actions);
for my $i (0 .. 2) {
    $nodes[$i] = {
	NodeId_namespaceIndex => 1,
	NodeId_identifierType => NODEIDTYPE_STRING,
	NodeId_identifier     => "var$i",
    };
    push @actions, sub {
	my $self = shift;
	my $status = $self->{server}->writeValue(
	    $nodes[$i],
	    {
		Variant_type   => TYPES_INT32,
		Variant_scalar => ($i + 1),
	    });
	die("add node failed: $status") if $status != STATUSCODE_GOOD;
    };
}

my $server = OPCUA::Open62541::Test::Server->new(
    actions => \@actions,
    timeout => 60,
);

$server->start();

# pre create variable nodes

is($server->{server}->addVariableNode(
    $nodes[$_],
    {
	NodeId_namespaceIndex => 0,
	NodeId_identifierType => NODEIDTYPE_NUMERIC,
	NodeId_identifier     => NS0ID_OBJECTSFOLDER,
    }, {
	NodeId_namespaceIndex => 0,
	NodeId_identifierType => NODEIDTYPE_NUMERIC,
	NodeId_identifier     => NS0ID_ORGANIZES,
    }, {
	QualifiedName_namespaceIndex => 1,
	QualifiedName_name           => "var$_",
    }, {
	NodeId_namespaceIndex => 0,
	NodeId_identifierType => NODEIDTYPE_NUMERIC,
	NodeId_identifier     => NS0ID_BASEDATAVARIABLETYPE,
    }, {
	VariableAttributes_displayName => {LocalizedText_text => "variable $_"},
	VariableAttributes_description => {LocalizedText_text => "variable $_"},
	VariableAttributes_value       => {
	    Variant_type   => TYPES_INT32,
	    Variant_scalar => $_,
	},
	VariableAttributes_valueRank   => VALUERANK_SCALAR,
	VariableAttributes_dataType    => TYPES_INT32,
	VariableAttributes_accessLevel => ACCESSLEVELMASK_READ,
    },
    0,
    undef
), STATUSCODE_GOOD, "add variable node") for (0 .. 2);

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

# MonitoredItems_createDataChanges

$request  = {
    CreateMonitoredItemsRequest_subscriptionId => $subid,
    CreateMonitoredItemsRequest_timestampsToReturn => TIMESTAMPSTORETURN_BOTH,
    CreateMonitoredItemsRequest_itemsToCreate => [
	OPCUA::Open62541::Client->MonitoredItemCreateRequest_default({
	    NodeId_identifier => NS0ID_SERVER_SERVERSTATUS_CURRENTTIME,
	    NodeId_identifierType => 0,
	    NodeId_namespaceIndex => 0,
	}),
    ],
};

throws_ok {$client->{client}->MonitoredItems_createDataChanges($request, 0, undef, undef)}
    (qr/Not an ARRAY reference for contexts/, "croak no array contexts");
throws_ok {$client->{client}->MonitoredItems_createDataChanges($request, undef, 1, undef)}
    (qr/Not an ARRAY reference for callbacks/, "croak no array callbacks");
throws_ok {$client->{client}->MonitoredItems_createDataChanges($request, undef, undef, {})}
    (qr/Not an ARRAY reference for deleteCallbacks/, "croak no array deleteCallbacks");

throws_ok {$client->{client}->MonitoredItems_createDataChanges($request, [], [], [])}
    (qr/No elements in contexts/, "croak not enough contexts");
throws_ok {$client->{client}->MonitoredItems_createDataChanges($request, [1], [], [])}
    (qr/No elements in callbacks/, "croak not enough callbacks");
throws_ok {$client->{client}->MonitoredItems_createDataChanges($request, [1], [2], [])}
    (qr/No elements in deleteCallbacks/, "croak not enough deleteCallbacks");

throws_ok {$client->{client}->MonitoredItems_createDataChanges($request, undef, ['foo'], undef)}
    (qr/Callback 'foo' is not a CODE reference/, "croak no coderef callbacks");
throws_ok {$client->{client}->MonitoredItems_createDataChanges($request, undef, undef, [{}])}
    (qr/Callback 'HASH\([0-9a-fx]+\)' is not a CODE reference/, "croak no coderef deleteCallbacks");

my $expected_response = {
    CreateMonitoredItemsResponse_results => [
	{
	    MonitoredItemCreateResult_statusCode => 'Good',
	    MonitoredItemCreateResult_filterResult => ignore(),
	    MonitoredItemCreateResult_revisedSamplingInterval => 250,
	    MonitoredItemCreateResult_revisedQueueSize => 1,
	    MonitoredItemCreateResult_monitoredItemId => 1
	}
    ],
    CreateMonitoredItemsResponse_responseHeader => ignore(),
    CreateMonitoredItemsResponse_diagnosticInfos => [],
};

$response = $client->{client}->MonitoredItems_createDataChanges(
    $request, undef, undef, undef
);

cmp_deeply($response,
	   $expected_response,
	   "monitored items create response");

is($response->{CreateMonitoredItemsResponse_responseHeader}{ResponseHeader_serviceResult},
   "Good",
   "monitored items create response serviceresult");

is($response->{CreateMonitoredItemsResponse_results}[0]{MonitoredItemCreateResult_statusCode},
   "Good",
   "monitored items create result statuscode");

my @monids;
$monids[0] = $response->{CreateMonitoredItemsResponse_results}[0]
    ->{MonitoredItemCreateResult_monitoredItemId};
is($client->{client}->MonitoredItems_deleteSingle($subid, $monids[0]),
   "Good",
   "delete monitored item");

$request->{CreateMonitoredItemsRequest_itemsToCreate} = [ map {
    OPCUA::Open62541::Client->MonitoredItemCreateRequest_default($_)
    } @nodes[0 .. 2]
];

$request->{CreateMonitoredItemsRequest_subscriptionId} = 999;
my $deleted;
$response = $client->{client}->MonitoredItems_createDataChanges(
    $request,
    [0 .. 2],
    undef,
    [ map { sub { $deleted++ } } (0 .. 2) ],
);

is($response->{CreateMonitoredItemsResponse_responseHeader}
    {ResponseHeader_serviceResult}, 'BadSubscriptionIdInvalid',
    "monitored items create fail response statuscode");

is($deleted, undef, "subscription deleted callback");

$request->{CreateMonitoredItemsRequest_subscriptionId} = $subid;
my @values;
my $called = 0;
my $datachange = sub {
    my ($cl, $sid, $sctx, $mid, $mctx, $v) = @_;
    $called++;
    $values[$mctx] = $v->{DataValue_value}{Variant_scalar};
};

$response = $client->{client}->MonitoredItems_createDataChanges(
    $request, [0 .. 2], [$datachange, $datachange, $datachange], undef
);

is($response->{CreateMonitoredItemsResponse_responseHeader}
    {ResponseHeader_serviceResult}, 'Good',
    "monitored items create response serviceresult");

is($response->{CreateMonitoredItemsResponse_results}[$_]
    {MonitoredItemCreateResult_statusCode}, 'Good',
    "monitored items create result $_ statuscode") for (0 .. 2);

for (0 .. 2) {
    $monids[$_] = $response->{CreateMonitoredItemsResponse_results}[$_]
	->{MonitoredItemCreateResult_monitoredItemId};
}

ok(!defined $values[$_], "var $_ no callback yet") for 0 .. 2;

# receive the initial notifications (no changed data)
my $i;
$client->iterate(sub {sleep 1; ++$i > 2});

is($values[$_], $_, "var $_ initial callback") for 0 .. 2;

# verify "var0" is unchanged
my $out;
is($client->{client}->readValueAttribute($nodes[0], \$out),
   STATUSCODE_GOOD, "readValue statuscode");
is($out->{Variant_scalar}, 0, "readValue value");

# change the variable values 0 and 1 on the server
$server->next_action() for 0 .. 1;

# receive the "real" change notifications
$i = 0;
$client->iterate(sub {sleep 1; ++$i > 2});

is($values[$_], $_ + 1, "var $_ changed callback") for 0 .. 1;
is($values[2], 2, "var 2 no change callback");

# change the variable value 2 on the server
$server->next_action();
$i = 0;
$client->iterate(sub {sleep 1; ++$i > 2});

is($values[2], 3, "var 2 changed callback");

is($called, 6, "called count");

is($client->{client}->readValueAttribute($nodes[0], \$out),
   STATUSCODE_GOOD, "readValue statuscode");
is($out->{Variant_scalar}, 1, "readValue value");

$response = $client->{client}->MonitoredItems_delete({
    DeleteMonitoredItemsRequest_subscriptionId => $subid,
    DeleteMonitoredItemsRequest_monitoredItemIds => \@monids,
});

is($response->{DeleteMonitoredItemsResponse_responseHeader}{ResponseHeader_serviceResult},
   "Good",
   "monitored items delete response serviceresult");

for (0 .. 2) {
    is($response->{DeleteMonitoredItemsResponse_results}[$_],
	"Good",
	"monitored items delete result $_ statuscode");
}

# test leaks

no_leaks_ok {
    $response = $client->{client}->MonitoredItems_createDataChanges(
	$request, undef, undef, undef
    );
    for (0 .. 2) {
	$monids[$_] = $response->{CreateMonitoredItemsResponse_results}[$_]
	    ->{MonitoredItemCreateResult_monitoredItemId};
	$client->{client}->MonitoredItems_deleteSingle($subid, $monids[$_]);
    }
} "monitored items creates leak";

no_leaks_ok {
    $response = $client->{client}->MonitoredItems_createDataChanges(
	$request, [0 .. 2], undef, undef
    );
    for (0 .. 2) {
	$monids[$_] = $response->{CreateMonitoredItemsResponse_results}[$_]
	    ->{MonitoredItemCreateResult_monitoredItemId};
	$client->{client}->MonitoredItems_deleteSingle($subid, $monids[$_]);
    }
} "monitored items creates context leak";

no_leaks_ok {
    $response = $client->{client}->MonitoredItems_createDataChanges(
	$request, [0 .. 2], [$datachange, $datachange, $datachange], undef
    );
    for (0 .. 2) {
	$monids[$_] = $response->{CreateMonitoredItemsResponse_results}[$_]
	    ->{MonitoredItemCreateResult_monitoredItemId};
	$client->{client}->MonitoredItems_deleteSingle($subid, $monids[$_]);
    }
} "monitored items creates callbacks leak";

no_leaks_ok {
    $response = $client->{client}->MonitoredItems_createDataChanges(
	$request, [0 .. 2], [map {sub{}} 0 .. 2], [map {sub{}} 0 .. 2]
    );
    for (0 .. 2) {
	$monids[$_] = $response->{CreateMonitoredItemsResponse_results}[$_]
	    ->{MonitoredItemCreateResult_monitoredItemId};
	$client->{client}->MonitoredItems_deleteSingle($subid, $monids[$_]);
    }
} "monitored items creates delete callbacks leak";

no_leaks_ok {
    $response = $client->{client}->MonitoredItems_createDataChanges(
	$request, [0 .. 2], [map {sub{}} 0 .. 2], [map {sub{}} 0 .. 2]
    );
    for (0 .. 2) {
	$monids[$_] = $response->{CreateMonitoredItemsResponse_results}[$_]
	    ->{MonitoredItemCreateResult_monitoredItemId};
    }
    $client->{client}->MonitoredItems_delete({
	DeleteMonitoredItemsRequest_subscriptionId => $subid,
	DeleteMonitoredItemsRequest_monitoredItemIds => \@monids,
    });
} "monitored items creates delete all leak";

no_leaks_ok {
    $request->{CreateMonitoredItemsRequest_subscriptionId} = 999;
    $response = $client->{client}->MonitoredItems_createDataChanges(
	$request,
	[0 .. 2],
	undef,
	[ map { sub { $deleted++ } } (0 .. 2) ],
    );
} "monitored items create fail deleted leak";

$client->stop();
$server->stop();
