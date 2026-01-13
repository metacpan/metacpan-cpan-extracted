use strict;
use warnings;
use OPCUA::Open62541 qw(:RULEHANDLING);

use Test::More tests => 99;
use Test::Deep;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;

ok(my $server = OPCUA::Open62541::Server->new(), "server new");
ok(my $config = $server->getConfig(), "config get");
is($config->setDefault(), "Good", "default set");
no_leaks_ok { $config->setDefault() } "default set leak";

throws_ok { OPCUA::Open62541::ServerConfig::setDefault() }
    (qr/OPCUA::Open62541::ServerConfig::setDefault\(config\) /,
    "config missing");
no_leaks_ok { eval { OPCUA::Open62541::ServerConfig::setDefault() } }
    "config missing leak";

throws_ok { OPCUA::Open62541::ServerConfig::setDefault(1) }
    (qr/Self config is not a OPCUA::Open62541::ServerConfig /,
    "config type");
no_leaks_ok { eval { OPCUA::Open62541::ServerConfig::setDefault(1) } }
    "config type leak";

if ($config->can("setCustomHostname")) {
    lives_ok { $config->setCustomHostname("foo\0bar") }
	"custom hostname";
    no_leaks_ok { $config->setCustomHostname("foo\0bar") }
	"custom hostname leak";
}
if ($config->can("setServerUrls")) {
    lives_ok {
	$config->setServerUrls("opc.tcp://foo/", "opc.tcp://bar:4840/");
    } "custom hostname";
    no_leaks_ok {
	$config->setServerUrls("opc.tcp://foo/", "opc.tcp://bar:4840/");
    } "custom hostname leak";
}

ok(my $buildinfo = $config->getBuildInfo(), "buildinfo get");
no_leaks_ok { $config->getBuildInfo() } "buildinfo leak";
my %info = (
    BuildInfo_buildDate => re(qr/^\d+$/),  # '132325380645571530',
    BuildInfo_buildNumber => re(qr/^.+$/),  # 'deb',
    BuildInfo_manufacturerName => 'open62541',
    BuildInfo_productName => 'open62541 OPC UA Server',
    BuildInfo_productUri => 'http://open62541.org',
    BuildInfo_softwareVersion => re(qr/^1\./)  # '1.0.1'
);
cmp_deeply($buildinfo, \%info, "buildinfo hash");

lives_ok { $config->setMaxSessions(42) }
    "custom max sessions";
no_leaks_ok { $config->setMaxSessions(42) }
    "custom max sessions leak";

ok(my $maxsessions = $config->getMaxSessions(), "max sessions get");
no_leaks_ok { $config->getMaxSessions() } "max sessions leak";
is($maxsessions, 42, "max sessions");

lives_ok { $config->setMaxSessionTimeout(30000) }
    "custom max session timeout";
no_leaks_ok { $config->setMaxSessionTimeout(30000) }
    "custom max session timeout leak";

ok(my $maxsessiontimeout = $config->getMaxSessionTimeout(),
    "max session timeout get");
no_leaks_ok { $config->getMaxSessionTimeout() } "max session timeout leak";
is($maxsessiontimeout, 30000, "max session timeout");

lives_ok { $config->setMaxSecureChannels(23) }
    "custom max secure channels";
no_leaks_ok { $config->setMaxSecureChannels(23) }
    "custom max secure channels leak";

ok(my $maxsecurechannels = $config->getMaxSecureChannels(),
    "max secure channels get");
no_leaks_ok { $config->getMaxSecureChannels() } "max secure channels leak";
is($maxsecurechannels, 23, "max secure channels");

# operation limits

lives_ok { $config->setMaxNodesPerRead(10001) }
    "custom max nodes per read";
no_leaks_ok { $config->setMaxNodesPerRead(10001) }
    "custom max nodes per read leak";

ok(my $maxnodesperread = $config->getMaxNodesPerRead(),
    "max nodes per read get");
no_leaks_ok { $config->getMaxNodesPerRead() } "max nodes per read leak";
is($maxnodesperread, 10001, "max max nodes per read");

lives_ok { $config->setMaxNodesPerWrite(10002) }
    "custom max nodes per write";
no_leaks_ok { $config->setMaxNodesPerWrite(10002) }
    "custom max nodes per write leak";

ok(my $maxnodesperwrite = $config->getMaxNodesPerWrite(),
    "max nodes per write get");
no_leaks_ok { $config->getMaxNodesPerWrite() } "max nodes per write leak";
is($maxnodesperwrite, 10002, "max max nodes per write");

lives_ok { $config->setMaxNodesPerMethodCall(10003) }
    "custom max nodes per method call";
no_leaks_ok { $config->setMaxNodesPerMethodCall(10003) }
    "custom max nodes per method call leak";

ok(my $maxnodespermethodcall = $config->getMaxNodesPerMethodCall(),
    "max nodes per method call get");
no_leaks_ok { $config->getMaxNodesPerMethodCall() }
    "max nodes per method call leak";
is($maxnodespermethodcall, 10003, "max max nodes per method call");

lives_ok { $config->setMaxNodesPerBrowse(10004) }
    "custom max nodes per browse";
no_leaks_ok { $config->setMaxNodesPerBrowse(10004) }
    "custom max nodes per browse leak";

ok(my $maxnodesperbrowse = $config->getMaxNodesPerBrowse(),
    "max nodes per browse get");
no_leaks_ok { $config->getMaxNodesPerBrowse() } "max nodes per browse leak";
is($maxnodesperbrowse, 10004, "max max nodes per browse");

lives_ok { $config->setMaxNodesPerRegisterNodes(10005) }
    "custom max nodes per RegisterNodes";
no_leaks_ok { $config->setMaxNodesPerRegisterNodes(10005) }
    "custom max nodes per RegisterNodes leak";

ok(my $maxnodesperregisternodes = $config->getMaxNodesPerRegisterNodes(),
    "max nodes per RegisterNodes get");
no_leaks_ok { $config->getMaxNodesPerRegisterNodes() }
    "max nodes per RegisterNodes leak";
is($maxnodesperregisternodes, 10005, "max max nodes per RegisterNodes");

lives_ok { $config->setMaxNodesPerTranslateBrowsePathsToNodeIds(10006) }
    "custom max nodes per TranslateBrowsePathsToNodeIds";
no_leaks_ok { $config->setMaxNodesPerTranslateBrowsePathsToNodeIds(10006) }
    "custom max nodes per TranslateBrowsePathsToNodeIds leak";

ok(my $maxnodespertranslatebrowsepathstonodeids =
    $config->getMaxNodesPerTranslateBrowsePathsToNodeIds(),
    "max nodes per TranslateBrowsePathsToNodeIds get");
no_leaks_ok { $config->getMaxNodesPerTranslateBrowsePathsToNodeIds() }
    "max nodes per TranslateBrowsePathsToNodeIds leak";
is($maxnodespertranslatebrowsepathstonodeids, 10006,
    "max max nodes per TranslateBrowsePathsToNodeIds");

lives_ok { $config->setMaxNodesPerNodeManagement(10007) }
    "custom max nodes per node management";
no_leaks_ok { $config->setMaxNodesPerNodeManagement(10007) }
    "custom max nodes per node management leak";

ok(my $maxnodespernodemanagement = $config->getMaxNodesPerNodeManagement(),
    "max nodes per node management get");
no_leaks_ok { $config->getMaxNodesPerNodeManagement() }
    "max nodes per node management leak";
is($maxnodespernodemanagement, 10007, "max max nodes per node management");

lives_ok { $config->setMaxMonitoredItemsPerCall(10008) }
    "custom max monitored items per call";
no_leaks_ok { $config->setMaxMonitoredItemsPerCall(10008) }
    "custom max monitored items per call";

ok(my $maxmonitoreditemspercall = $config->getMaxMonitoredItemsPerCall(),
    "max monitored items per call get");
no_leaks_ok { $config->getMaxMonitoredItemsPerCall() }
    "max monitored items per call leak";
is($maxmonitoreditemspercall, 10008, "max max monitored items per call");

lives_ok { $config->setMaxSubscriptions(42) }
    "set max subscriptions";
no_leaks_ok { $config->setMaxSubscriptions(42) }
    "set max subscriptions leak";

ok(my $maxsubscriptions = $config->getMaxSubscriptions(),
    "get max subscriptions");
no_leaks_ok { $config->getMaxSubscriptions() }
    "get max subscriptions leak";
is($maxsubscriptions, 42, "custom max subscriptions");

lives_ok { $config->setMaxSubscriptionsPerSession(42) }
    "set max subscriptions per session";
no_leaks_ok { $config->setMaxSubscriptionsPerSession(42) }
    "set max subscriptions per session leak";

ok(my $maxsubscriptionspersession = $config->getMaxSubscriptionsPerSession(),
    "get max subscriptions per session");
no_leaks_ok { $config->getMaxSubscriptionsPerSession() }
    "get max subscriptions per session leak";
is($maxsubscriptionspersession, 42, "custom max subscriptions per session");

lives_ok { $config->setMaxNotificationsPerPublish(42) }
    "set max notifications per publish";
no_leaks_ok { $config->setMaxNotificationsPerPublish(42) }
    "set max notifications per publish leak";

ok(my $maxnotificationsperpublish = $config->getMaxNotificationsPerPublish(),
    "get max notifications per publish");
no_leaks_ok { $config->getMaxNotificationsPerPublish() }
    "get max notifications per publish leak";
is($maxnotificationsperpublish, 42, "custom max notifications per publish");

lives_ok { $config->setEnableRetransmissionQueue(1) }
    "set enable retransmission queue";
no_leaks_ok { $config->setEnableRetransmissionQueue(1) }
    "set enable retransmission queue leak";

ok(my $enableretransmissionqueue = $config->getEnableRetransmissionQueue(),
    "get enable retransmission queue");
no_leaks_ok { $config->getEnableRetransmissionQueue() }
    "get enable retransmission queue leak";
is($enableretransmissionqueue, 1, "custom enable retransmission queue");

lives_ok { $config->setMaxRetransmissionQueueSize(42) }
    "set max retransmission queue size";
no_leaks_ok { $config->setMaxRetransmissionQueueSize(42) }
    "set max retransmission queue size leak";

ok(my $maxretransmissionqueuesize = $config->getMaxRetransmissionQueueSize(),
    "get max retransmission queue size");
no_leaks_ok { $config->getMaxRetransmissionQueueSize() }
    "get max retransmission queue size leak";
is($maxretransmissionqueuesize, 42, "custom max retransmission queue size");

lives_ok { $config->setAllowEmptyVariables(RULEHANDLING_ACCEPT) }
    "set allow empty variables";
no_leaks_ok { $config->setAllowEmptyVariables(RULEHANDLING_ACCEPT) }
    "set allow empty variables leak";
ok(my $allowemptyvariables = $config->getAllowEmptyVariables(),
    "get allow empty variables");
no_leaks_ok { $config->getAllowEmptyVariables() }
    "get allow empty variables leak";
is($allowemptyvariables, 3, "custom allow empty variables");
