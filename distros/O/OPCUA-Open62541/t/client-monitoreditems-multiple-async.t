use strict;
use warnings;

use OPCUA::Open62541 qw(:all);
use OPCUA::Open62541::Test::Client;
use OPCUA::Open62541::Test::Server;

use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 24;
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

my $request = OPCUA::Open62541::Client->CreateSubscriptionRequest_default();
my $response = $client->{client}->Subscriptions_create(
    $request, undef, undef, undef);
is($response->{CreateSubscriptionResponse_responseHeader}
    {ResponseHeader_serviceResult},
   "Good",
   "subscription create response statuscode");
my $subid = $response->{CreateSubscriptionResponse_subscriptionId};

# MonitoredItems_createDataChanges_async

my @nodes = map {{
    NodeId_identifier => $_,
    NodeId_identifierType => 0,
    NodeId_namespaceIndex => 0,
}} NS0ID_SERVER_SERVERSTATUS_STARTTIME, NS0ID_SERVER_SERVERSTATUS_CURRENTTIME;

$request = {
    CreateMonitoredItemsRequest_subscriptionId => $subid,
    CreateMonitoredItemsRequest_timestampsToReturn => TIMESTAMPSTORETURN_BOTH,
    CreateMonitoredItemsRequest_itemsToCreate => [ map {
	OPCUA::Open62541::Client->MonitoredItemCreateRequest_default($_)
    } @nodes ],
};

my $noop_create = sub {};

# input validation

throws_ok { $client->{client}->MonitoredItems_createDataChanges_async(
    $request, 0, undef, undef, $noop_create, undef, undef) }
    qr/Not an ARRAY reference for contexts/, "croak no array contexts";
throws_ok { $client->{client}->MonitoredItems_createDataChanges_async(
    $request, undef, 1, undef, $noop_create, undef, undef) }
    qr/Not an ARRAY reference for callbacks/, "croak no array callbacks";
throws_ok { $client->{client}->MonitoredItems_createDataChanges_async(
    $request, undef, undef, {}, $noop_create, undef, undef) }
    qr/Not an ARRAY reference for deleteCallbacks/,
    "croak no array deleteCallbacks";
throws_ok { $client->{client}->MonitoredItems_createDataChanges_async(
    $request, [], [], [], $noop_create, undef, undef) }
    qr/No elements in contexts/, "croak no elements contexts";
throws_ok { $client->{client}->MonitoredItems_createDataChanges_async(
    $request, [1, 2], [], [], $noop_create, undef, undef) }
    qr/No elements in callbacks/, "croak no elements callbacks";
throws_ok { $client->{client}->MonitoredItems_createDataChanges_async(
    $request, [1, 2], [3, 4], [], $noop_create, undef, undef) }
    qr/No elements in deleteCallbacks/, "croak no elements deleteCallbacks";
throws_ok { $client->{client}->MonitoredItems_createDataChanges_async(
    $request, undef, ['foo', 'bar'], undef, $noop_create, undef, undef) }
    qr/Callback 'foo' is not a CODE reference/, "croak no coderef callbacks";
throws_ok { $client->{client}->MonitoredItems_createDataChanges_async(
    $request, undef, undef, [{}, {}], $noop_create, undef, undef) }
    qr/Callback 'HASH\([0-9a-fx]+\)' is not a CODE reference/,
    "croak no coderef deleteCallbacks";

# happy path: create monitored items, verify callbacks fire, then delete them

my $expected_response = {
    CreateMonitoredItemsResponse_results => [
	{
	    MonitoredItemCreateResult_statusCode => 'Good',
	    MonitoredItemCreateResult_filterResult => ignore(),
	    MonitoredItemCreateResult_revisedSamplingInterval => 250,
	    MonitoredItemCreateResult_revisedQueueSize => 1,
	    MonitoredItemCreateResult_monitoredItemId => 1,
	},
	{
	    MonitoredItemCreateResult_statusCode => 'Good',
	    MonitoredItemCreateResult_filterResult => ignore(),
	    MonitoredItemCreateResult_revisedSamplingInterval => 250,
	    MonitoredItemCreateResult_revisedQueueSize => 1,
	    MonitoredItemCreateResult_monitoredItemId => 2,
	},
    ],
    CreateMonitoredItemsResponse_responseHeader => ignore(),
    CreateMonitoredItemsResponse_diagnosticInfos => [],
};

my (@changed, @deleted, @monids);
my $reqid;
my $data = 'foo';
my $monitored = 0;
is($client->{client}->MonitoredItems_createDataChanges_async(
    $request,
    [0, 1],
    [ map { sub {
	my ($cl, $sid, $sctx, $mid, $mctx, $v) = @_;
	$changed[$mctx]++;
    } } @nodes ],
    [ map { sub {
	my ($cl, $sid, $sctx, $mid, $mctx) = @_;
	$deleted[$mctx]++;
    } } @nodes ],
    sub {
	my ($cl, $d, $r, $resp) = @_;
	$$d = "bar";
	$monitored = 1;
	cmp_deeply($resp, $expected_response, "create response");
	for my $result (@{$resp->{CreateMonitoredItemsResponse_results}}) {
	    push @monids, $result->{MonitoredItemCreateResult_monitoredItemId};
	}
    },
    \$data,
    \$reqid,
), STATUSCODE_GOOD, 'MonitoredItems_createDataChanges_async status');

is($data, "foo", "data unchanged");
$client->iterate(\$monitored, "async create monitored");
like($reqid, qr/^\d+$/, "reqid number");
is($data, 'bar', "data changed by create callback");

# iterate long enough to receive the initial data change notifications

my $i;
$client->iterate(sub { sleep 1; ++$i > 2 });
ok($changed[0] && $changed[1], "dataChangeCallback fired for each item");

# delete items; verify delete callbacks fire

$response = $client->{client}->MonitoredItems_delete({
    DeleteMonitoredItemsRequest_subscriptionId => $subid,
    DeleteMonitoredItemsRequest_monitoredItemIds => \@monids,
});
is($response->{DeleteMonitoredItemsResponse_responseHeader}
    {ResponseHeader_serviceResult}, 'Good',
    "monitored items delete serviceresult");

$i = 0;
$client->iterate(sub { sleep 1; ++$i > 1 });
ok($deleted[0] && $deleted[1], "deleteCallback fired for each item");

# failure path: invalid subscription id; async returns error synchronously,
# createCallback is not invoked.

{
    my $called = 0;
    my $bad_request = { %$request };
    $bad_request->{CreateMonitoredItemsRequest_subscriptionId} = 999;
    is($client->{client}->MonitoredItems_createDataChanges_async(
	$bad_request,
	undef, undef, undef,
	sub { $called = 1 },
	undef, undef,
    ), 'BadSubscriptionIdInvalid', "async create bad sub returns error");
    is($called, 0, "createCallback not called on bad sub");
}

# leak tests

no_leaks_ok {
    my $done = 0;
    my @ids;
    my $data = 'foo';
    my $reqid;
    $client->{client}->MonitoredItems_createDataChanges_async(
	$request,
	[0, 1],
	[ map { sub {} } @nodes ],
	[ map { sub {} } @nodes ],
	sub {
	    my ($cl, $d, $r, $resp) = @_;
	    $done = 1;
	    @ids = map { $_->{MonitoredItemCreateResult_monitoredItemId} }
		@{$resp->{CreateMonitoredItemsResponse_results}};
	},
	\$data, \$reqid,
    );
    $client->iterate(\$done);
    $client->{client}->MonitoredItems_delete({
	DeleteMonitoredItemsRequest_subscriptionId => $subid,
	DeleteMonitoredItemsRequest_monitoredItemIds => \@ids,
    });
} "async create delete leak";

no_leaks_ok {
    my $bad_request = { %$request };
    $bad_request->{CreateMonitoredItemsRequest_subscriptionId} = 999;
    my $data = 'foo';
    my $reqid;
    $client->{client}->MonitoredItems_createDataChanges_async(
	$bad_request,
	[0, 1],
	[ map { sub {} } @nodes ],
	[ map { sub {} } @nodes ],
	sub {}, \$data, \$reqid,
    );
} "async create bad sub leak";

no_leaks_ok {
    my $done = 0;
    my $bad_node_request = {
	CreateMonitoredItemsRequest_subscriptionId => $subid,
	CreateMonitoredItemsRequest_timestampsToReturn => TIMESTAMPSTORETURN_BOTH,
	CreateMonitoredItemsRequest_itemsToCreate => [ map {
	    OPCUA::Open62541::Client->MonitoredItemCreateRequest_default({
		NodeId_identifier => 0,
		NodeId_identifierType => 0,
		NodeId_namespaceIndex => 0,
	    })
	} @nodes ],
    };
    my $data = 'foo';
    my $reqid;
    $client->{client}->MonitoredItems_createDataChanges_async(
	$bad_node_request,
	[0, 1],
	[ map { sub {} } @nodes ],
	[ map { sub {} } @nodes ],
	sub { $done = 1 }, \$data, \$reqid,
    );
    $client->iterate(\$done);
} "async create bad node leak";

$client->stop();
$server->stop();
