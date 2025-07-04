package OPCUA::Open62541;

use 5.026001;
use strict;
use warnings;
require Exporter;
use parent 'Exporter';
use OPCUA::Open62541::Constant;

our $VERSION = '2.08';

our @EXPORT_OK = @OPCUA::Open62541::Constant::EXPORT_OK;
our %EXPORT_TAGS = %OPCUA::Open62541::Constant::EXPORT_TAGS;
$EXPORT_TAGS{all} = [@OPCUA::Open62541::Constant::EXPORT_OK];

require XSLoader;
XSLoader::load('OPCUA::Open62541', $VERSION);

1;

__END__

=pod

=head1 NAME

OPCUA::Open62541 - Perl XS wrapper for open62541 OPC UA library

=head1 SYNOPSIS

  use OPCUA::Open62541;

  my $server = OPCUA::Open62541::Server->new();

  my $client = OPCUA::Open62541::Client->new();

=head1 DESCRIPTION

The open62541 is a library implementing an OPC UA client and server.
This module provides access to the C functionality from Perl programs.

=head2 EXPORT

Refer to OPCUA::Open62541::Constant module about the exported values.

=head2 METHODS

Refer to the open62541 documentation for the semantic of classes
and methods.

=head3 Variant

=over 4

=item $variant = OPCUA::Open62541::Variant->new()

=item $boolean = $variant->isEmpty()

=item $boolean = $variant->isScalar()

=item $boolean = $variant->hasScalarType($data_type)

=item $boolean = $variant->hasArrayType($data_type)

=item $variant->setScalar($p, $data_type)

=item $data_type = $variant->getType()

=item $p = $variant->getScalar()

=back

=head3 Server

=over 4

=item $server = OPCUA::Open62541::Server->new()

=item $server_config = $server->getConfig()

=item $status_code = $server->run($server, $running)

$running should be TRUE at startup.
When set to FALSE during method invocation, the server stops
magically.

=item $status_code = $server->run_startup($server)

=item $wait_ms = $server->run_iterate($server, $wait_internal)

=item $status_code = $server->run_shutdown($server)

=item \%dataValue = $server->read(\%item, $timestamps)

=item $status_code = $server->readAccessLevel(\%nodeId, \$outByte)

=item $status_code = $server->readArrayDimensions(\%nodeId, \$outVariant)

=item $status_code = $server->readBrowseName(\%nodeId, \$outQualifiedName)

=item $status_code = $server->readContainsNoLoops(\%nodeId, \$outBoolean)

=item $status_code = $server->readDataType(\%nodeId, \$outDataType)

=item $status_code = $server->readDescription(\%nodeId, \$outLocalizedText)

=item $status_code = $server->readDisplayName(\%nodeId, \$outLocalizedText)

=item $status_code = $server->readEventNotifier(\%nodeId, \$outByte)

=item $status_code = $server->readExecutable(\%nodeId, \$outBoolean)

=item $status_code = $server->readHistorizing(\%nodeId, \$outBoolean)

=item $status_code = $server->readInverseName(\%nodeId, \$outLocalizedText)

=item $status_code = $server->readIsAbstract(\%nodeId, \$outBoolean)

=item $status_code = $server->readMinimumSamplingInterval(\%nodeId, \$outDouble)

=item $status_code = $server->readNodeClass(\%nodeId, \$outNodeClass)

=item $status_code = $server->readNodeId(\%nodeId, \$outNodeId)

=item $status_code = $server->readObjectProperty(\%nodeId, \%propertyName, \$outVariant)

=item $status_code = $server->readSymmetric(\%nodeId, \$outBoolean)

=item $status_code = $server->readValue(\%nodeId, \$outVariant)

=item $status_code = $server->readValueRank(\%nodeId, \$outInt32)

=item $status_code = $server->readWriteMask(\%nodeId, \$outUInt32)

=item $status_code = $server->write(\%value)

=item $status_code = $server->writeAccessLevel(\%nodeId, $newByte)

=item $status_code = $server->writeArrayDimensions(\%nodeId, \%newVariant)

=item $status_code = $server->writeDataType(\%nodeId, $newDataType)

=item $status_code = $server->writeDescription(\%nodeId, \%newLocalizedText)

=item $status_code = $server->writeDisplayName(\%nodeId, \%newLocalizedText)

=item $status_code = $server->writeEventNotifier(\%nodeId, $newByte)

=item $status_code = $server->writeExecutable(\%nodeId, $newBoolean)

=item $status_code = $server->writeHistorizing(\%nodeId, $newBoolean)

=item $status_code = $server->writeInverseName(\%nodeId, \%newLocalizedText)

=item $status_code = $server->writeIsAbstract(\%nodeId, $newBoolean)

=item $status_code = $server->writeMinimumSamplingInterval(\%nodeId, $newDouble)

=item $status_code = $server->writeObjectProperty(\%nodeId, \%propertyName, \%newVariant)

=item $status_code = $server->writeValue(\%nodeId, \%newVariant)

=item $status_code = $server->writeValueRank(\%nodeId, $newInt32)

=item $status_code = $server->writeWriteMask(\%nodeId, $newUInt32)

=item \%browseResult = $server->browse($maxReferences, \%browseDescription)

=item \%browseResult = $server->browseNext($releaseContinuationPoint, $continuationPoint)

=item $server->setAdminSessionContext($context)

This method is only available if open62541 library supports it.

=item $status_code = $server->addVariableNode(\%requestedNewNodeId, \%parentNodeId, \%referenceTypeId, \%browseName, \%typeDefinition, \%attr, $nodeContext, \%outNewNodeId)

=item $status_code = $server->addVariableTypeNode(\%requestedNewNodeId, \%parentNodeId, \%referenceTypeId, \%browseName, \%typeDefinition, \%attr, $nodeContext, \%outNewNodeId)

=item $status_code = $server->addObjectNode(\%requestedNewNodeId, \%parentNodeId, \%referenceTypeId, \%browseName, \%typeDefinition, \%attr, $nodeContext, \%outNewNodeId)

=item $status_code = $server->addObjectTypeNode(\%requestedNewNodeId, \%parentNodeId, \%referenceTypeId, \%browseName, \%attr, $nodeContext, \%outNewNodeId)

=item $status_code = $server->addViewNode(\%requestedNewNodeId, \%parentNodeId, \%referenceTypeId, \%browseName, \%attr, $nodeContext, \%outNewNodeId)

=item $status_code = $server->addReferenceTypeNode(\%requestedNewNodeId, \%parentNodeId, \%referenceTypeId, \%browseName, \%attr, $nodeContext, \%outNewNodeId)

=item $status_code = $server->addDataTypeNode(\%requestedNewNodeId, \%parentNodeId, \%referenceTypeId, \%browseName, \%attr, $nodeContext, \%outNewNodeId)

=item $status_code = $server->deleteNode(\%nodeId, $deleteReferences)

=item $status_code = $server->addReference(\%sourceId, \%refTypeId, \%targetId, $isForward)

=item $status_code = $server->deleteReference(\%sourceNodeId, \%referenceTypeId, $isForward, \%targetNodeId, $deleteBidirectional)

=item $namespace_index = $server->addNamespace($namespace_name)

=back

=head3 ServerConfig

=over 4

=item $status_code = $server_config->setDefault()

=item $status_code = $server_config->setDefaultWithSecurityPolicies($port, $certificate, $privateKey, $trustList, $issuerList, $revocationList)

$trustList, $issuerList and $revocationList are currently not supported and have to be undef.

=item $status_code = $server_config->setMinimal($port, $certificate)

=item $server_config->setCustomHostname($custom_hostname)

=item $server_config->setGlobalNodeLifecycle(\%lifecycle)

=over 8

=item $lifecycle{GlobalNodeLifecycle_constructor} = sub { my ($server, $sessionId, $sessionContext, $nodeId, \$nodeContext) = @_ }

=item $lifecycle{GlobalNodeLifecycle_destructor} = sub { my ($server, $sessionId, $sessionContext, $nodeId, $nodeContext) = @_ }

=item $lifecycle{GlobalNodeLifecycle_createOptionalChild} = sub { my ($server, $sessionId, $sessionContext, $sourceNodeId, $targetParentNodeId, $referenceTypeId) = @_ }

=item $lifecycle{GlobalNodeLifecycle_generateChildNodeId} = sub { my ($server, $sessionId, $sessionContext, $sourceNodeId, $targetParentNodeId, $referenceTypeId, \%targetNodeId) = @_ }

=back

Call $server->setAdminSessionContext() to set $server and $sessionContext
in the callback.

=item $logger = $server_config->getLogger()

=item $buildInfo = $server_config->getBuildInfo()

=item $server_config->setBuildInfo(\%buildInfo)

=item $applicationDescription = $server_config->getApplicationDescription()

=item $server_config->setApplicationDescription(\%applicationDescription)

=item $limit = $server_config->getMaxSecureChannels()

=item $server_config->setMaxSecureChannels($maxSecureChannels)

=item $limit = $server_config->getMaxSessions()

=item $server_config->setMaxSessions($maxSessions)

=item $limit = $server_config->getMaxSessionTimeout()

=item $server_config->setMaxSessionTimeout($maxSessionTimeout)

=item $limit = $server_config->getMaxNodesPerRead()

=item $server_config->setMaxNodesPerRead($maxNodesPerRead)

=item $limit = $server_config->getMaxNodesPerWrite()

=item $server_config->setMaxNodesPerWrite($maxNodesPerWrite)

=item $limit = $server_config->getMaxNodesPerMethodCall()

=item $server_config->setMaxNodesPerMethodCall($maxNodesPerMethodCall)

=item $limit = $server_config->getMaxNodesPerBrowse()

=item $server_config->setMaxNodesPerBrowse($maxNodesPerBrowse)

=item $limit = $server_config->getMaxNodesPerRegisterNodes()

=item $server_config->setMaxNodesPerRegisterNodes($maxNodesPerRegisterNodes)

=item $limit = $server_config->getMaxNodesPerTranslateBrowsePathsToNodeIds()

=item $server_config->setMaxNodesPerTranslateBrowsePathsToNodeIds($maxNodesPerTranslateBrowsePathsToNodeIds)

=item $limit = $server_config->getMaxNodesPerNodeManagement()

=item $server_config->setMaxNodesPerNodeManagement($maxNodesPerNodeManagement)

=item $limit = $server_config->getMaxMonitoredItemsPerCall()

=item $server_config->setMaxMonitoredItemsPerCall($maxMonitoredItemsPerCall)

=item $limit = $server_config->getMaxSubscriptions()

=item $server_config->setMaxSubscriptions($maxSubscriptions)

=item $limit = $server_config->getMaxSubscriptionsPerSession()

=item $server_config->setMaxSubscriptionsPerSession($maxSubscriptionsPerSession)

=item $limit = $server_config->getMaxNotificationsPerPublish()

=item $server_config->setMaxNotificationsPerPublish($maxNotificationsPerPublish)

=item $limit = $server_config->getEnableRetransmissionQueue()

=item $server_config->setEnableRetransmissionQueue($enableRetransmissionQueue)

=item $limit = $server_config->getMaxRetransmissionQueueSize()

=item $server_config->setMaxRetransmissionQueueSize($maxRetransmissionQueueSize)

=item $limit = $server_config->getMaxEventsPerNode()

=item $server_config->setMaxEventsPerNode($maxEventsPerNode)

=item $server_config->setUserRightsMaskReadonly($readonly)

If $readonly is set to true, only reading of attributes is allowed.
If set to false, no additional restrictions on the UserWriteMask are made and
attributes will also be writable (this is the default behaviour).
Values of variable nodes are excluded from the UserWriteMask and are handled by
the AccessLevel instead (see setUserAccessLevelReadonly()).

=item $server_config->setUserAccessLevelReadonly($readonly)

If $readonly is set to true, only reading of variable values is allowed
(including reading historical data of values).
If set to false, no additional restrictions on the AccessLevel are made and
values will also be writable (this is the default behaviour).

=item $server_config->disableUserExecutable($disable)

If $disable is set to true, method nodes will not be shown as executable for
users (UserExecutable attribute of the method node).
If set to false, no addtional restrictions are made on the UserExecutable
attribute of method nodes (this is the default).

=item $server_config->disableUserExecutableOnObject($disable)

If $disable is set to true, methods can not be executed.
If set to false, no addtional restrictions are made on the execution of methods
(this is the default).

=item $server_config->disableAddNode($disable)

If $disable is set to true, nodes can not be added.
If set to false, nodes can be added (this is the default).

=item $server_config->disableAddReference($disable)

If $disable is set to true, references can not be added.
If set to false, references can be added (this is the default).

=item $server_config->disableDeleteNode($disable)

If $disable is set to true, nodes can not be deleted.
If set to false, nodes can be deleted (this is the default).

=item $server_config->disableDeleteReference($disable)

If $disable is set to true, references can not be deleted.
If set to false, references can be deleted (this is the default).

=item $server_config->disableHistoryUpdateUpdateData($disable)

If $disable is set to true, historical data may not be inserted, replaced or
updated.
If set to false, no addtional restrictions are made on the modification of
historical data (this is the default).

=item $server_config->disableHistoryUpdateDeleteRawModified($disable)

If $disable is set to true, historical data may not be deleted.
If set to false, historical data can be deleted (this is the default).

=back

=head3 Client

=over 4

=item $client = OPCUA::Open62541::Client->new()

=item $client_config = $client->getConfig()

=item $status_code = $client->connect($url)

=item $status_code = $client->connectAsync($endpointUrl)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, $status_code) = @_ }

=back

There should be an interval of 100ms between the call to connectAsync() and
run_iterate() or open62541 may try to operate on a non existent socket.

=item $status_code = $client->run_iterate($timeout)

=item $status_code = $client->disconnect()

=item $status_code = $client->disconnectAsync()

=item ($channel_state, $session_state, $connect_status) = $client->getState()

=item $status_code = $client->getEndpoints($serverUrl, \$endpointDescriptions)

1.1 API

In scalar context croak due to 1.0 API incompatibility.

=item $status_code = $client->sendAsyncBrowseRequest(\%request, \&callback, $data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, \%response) = @_ }

=back

=item $status_code = $client->sendAsyncBrowseNextRequest(\%request, \&callback, $data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, \%response) = @_ }

=back

=item $response = $client->Service_read(\%request)

=item $response = $client->Service_browse(\%request)

=item $response = $client->Service_browseNext(\%request)

=item $status_code = $client->readAccessLevelAttribute(\%nodeId, \$outByte)

=item $status_code = $client->readBrowseNameAttribute(\%nodeId, \$outQualifiedName)

=item $status_code = $client->readContainsNoLoopsAttribute(\%nodeId, \$outBoolean)

=item $status_code = $client->readDataTypeAttribute(\%nodeId, \$outDataType)

=item $status_code = $client->readDescriptionAttribute(\%nodeId, \$outLocalizedText)

=item $status_code = $client->readDisplayNameAttribute(\%nodeId, \$outLocalizedText)

=item $status_code = $client->readEventNotifierAttribute(\%nodeId, \$outByte)

=item $status_code = $client->readExecutableAttribute(\%nodeId, \$outBoolean)

=item $status_code = $client->readHistorizingAttribute(\%nodeId, \$outBoolean)

=item $status_code = $client->readInverseNameAttribute(\%nodeId, \$outLocalizedText)

=item $status_code = $client->readIsAbstractAttribute(\%nodeId, \$outBoolean)

=item $status_code = $client->readMinimumSamplingIntervalAttribute(\%nodeId, \$outDouble)

=item $status_code = $client->readNodeClassAttribute(\%nodeId, \$outNodeClass)

=item $status_code = $client->readNodeIdAttribute(\%nodeId, \$outNodeId)

=item $status_code = $client->readSymmetricAttribute(\%nodeId, \$outBoolean)

=item $status_code = $client->readUserAccessLevelAttribute(\%nodeId, \$outByte)

=item $status_code = $client->readUserExecutableAttribute(\%nodeId, \$outBoolean)

=item $status_code = $client->readUserWriteMaskAttribute(\%nodeId, \$outUInt32)

=item $status_code = $client->readValueAttribute(\%nodeId, \$outVariant)

=item $status_code = $client->readValueRankAttribute(\%nodeId, \$outInt32)

=item $status_code = $client->readWriteMaskAttribute(\%nodeId, \$outUInt32)

=item $status_code = $client->sendAsyncReadRequest(\%request, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, \%response) = @_ }

=back

=item $status_code = $client->readAccessLevelAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, $byte) = @_ }

=back

=item $status_code = $client->readBrowseNameAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, \%qualifiedName) = @_ }

=back

=item $status_code = $client->readContainsNoLoopsAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, $boolean) = @_ }

=back

=item $status_code = $client->readDataTypeAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, $dataType) = @_ }

=back

=item $status_code = $client->readDescriptionAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, \%localizedText) = @_ }

=back

=item $status_code = $client->readDisplayNameAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, \%localizedText) = @_ }

=back

=item $status_code = $client->readEventNotifierAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, $byte) = @_ }

=back

=item $status_code = $client->readExecutableAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, $boolean) = @_ }

=back

=item $status_code = $client->readHistorizingAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, $boolean) = @_ }

=back

=item $status_code = $client->readInverseNameAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, \%localizedText) = @_ }

=back

=item $status_code = $client->readIsAbstractAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, $boolean) = @_ }

=back

=item $status_code = $client->readMinimumSamplingIntervalAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, $double) = @_ }

=back

=item $status_code = $client->readNodeClassAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, $nodeClass) = @_ }

=back

=item $status_code = $client->readNodeIdAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, \%nodeId) = @_ }

=back

=item $status_code = $client->readSymmetricAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, $boolean) = @_ }

=back

=item $status_code = $client->readUserAccessLevelAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, $byte) = @_ }

=back

=item $status_code = $client->readUserExecutableAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, $boolean) = @_ }

=back

=item $status_code = $client->readUserWriteMaskAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, $uint32) = @_ }

=back

=item $status_code = $client->readValueAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, \%variant) = @_ }

=back

=item $status_code = $client->readValueRankAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, $int32) = @_ }

=back

=item $status_code = $client->readWriteMaskAttribute_async(\%nodeId, \&callback, \$data, \$reqId)

=over 8

=item $callback = sub { my ($client, $userdata, $requestId, $uint32) = @_ }

=back

=item $status_code = $client->writeAccessLevelAttribute(\%nodeId, $newByte)

=item $status_code = $client->writeBrowseNameAttribute(\%nodeId, \%newQualifiedName)

=item $status_code = $client->writeContainsNoLoopsAttribute(\%nodeId, $outBoolean)

=item $status_code = $client->writeDataTypeAttribute(\%nodeId, $newDataType)

=item $status_code = $client->writeDescriptionAttribute(\%nodeId, \%newLocalizedText)

=item $status_code = $client->writeDisplayNameAttribute(\%nodeId, \%newLocalizedText)

=item $status_code = $client->writeEventNotifierAttribute(\%nodeId, $newByte)

=item $status_code = $client->writeExecutableAttribute(\%nodeId, $newBoolean)

=item $status_code = $client->writeHistorizingAttribute(\%nodeId, $newBoolean)

=item $status_code = $client->writeInverseNameAttribute(\%nodeId, \%newLocalizedText)

=item $status_code = $client->writeIsAbstractAttribute(\%nodeId, $newBoolean)

=item $status_code = $client->writeMinimumSamplingIntervalAttribute(\%nodeId, $newDouble)

=item $status_code = $client->writeNodeClassAttribute(\%nodeId, $newNodeClass)

=item $status_code = $client->writeNodeIdAttribute(\%nodeId, \%newNodeId)

=item $status_code = $client->writeSymmetricAttribute(\%nodeId, $newBoolean)

=item $status_code = $client->writeUserAccessLevelAttribute(\%nodeId, $newByte)

=item $status_code = $client->writeUserExecutableAttribute(\%nodeId, $newBoolean)

=item $status_code = $client->writeUserWriteMaskAttribute(\%nodeId, $newUInt32)

=item $status_code = $client->writeValueAttribute(\%nodeId, \%newVariant)

=item $status_code = $client->writeValueRankAttribute(\%nodeId, $newInt32)

=item $status_code = $client->writeWriteMaskAttribute(\%nodeId, $newUInt32)

=item $request  = OPCUA::Open62541::Client->CreateSubscriptionRequest_default()

=item $response = $client->Subscriptions_create(\%request, $subscriptionContext, \&statusChangeCallback, \&deleteCallback)

=over 8

=item $statusChangeCallback = sub { my ($client, $subscriptionId, $subscriptionContext, $notification) = @_ }

=item $deleteCallback = sub { my ($client, $subscriptionId, $subscriptionContext) = @_ }

=back

=item $response = $client->Subscriptions_modify(\%request)

=item $response = $client->Subscriptions_delete(\%request)

=item $status_code = $client->Subscriptions_deleteSingle($subscriptionId)

=item $response = $client->setPublishingMode(\%request)

=item $request  = OPCUA::Open62541::Client->MonitoredItemCreateRequest_default(\%nodeId)

=item $response = $client->MonitoredItems_createDataChange($subscriptionId,
	$timestamps, \%request, $monitoredContext, \&dataChangeCallback, \&deleteCallback)

=over 8

=item $dataChangeCallback = sub { my ($client, $subscriptionId,
	$subscriptionContext, $monitoredId, $monitoredContext, $value) = @_ }

=item $deleteCallback = sub { my ($client, $subscriptionId,
	$subscriptionContext, $monitoredId, $monitoredContext) = @_ }

=back

=item $response = $client->MonitoredItems_createDataChanges(\%request,
	\@monitoredContexts, \@dataChangeCallbacks, \@deleteCallbacks)

=item $response  = $client->MonitoredItems_delete(\%request)

=item $status_code  = $client->MonitoredItems_deleteSingle($subscriptionId, $monitoredItemId)

=back

=head3 ClientConfig

=over 4

=item $status_code = $client_config->setDefault()

=item $status_code = $client_config->setDefaultEncryption($certificate, $privateKey, $trustList, $revocationList)

If no trust or revocation list is set, the client will accept all certificates.

=item $context = $client_config->getClientContext()

=item $client_config->setClientContext($context)

=item $securityMode = $client_config->getSecurityMode()

=item $client_config->setSecurityMode($securityMode)

=item $timeout = $client_config->getTimeout()

=item $client_config->setTimeout($timeout)

=item $clientDescription = $client_config->getClientDescription()

=item $client_config->setClientDescription($clientDescription)

=item $client_config->setStateCallback($callback)

=item $logger = $client_config->getLogger()

=item $client_config->setUsernamePassword($userName, $password)

With this method a username and password can be set for the OPC UA connection.
If $userName is an empty string or undef, username and password are cleared in
the client configuration.
Calling this method will also clear endpoint and userTokenPolicy data in the
client configuration that may exist from previous connection.
If a previous connection was made, the client will again try to get and match
the endpoints and policies from the server.

=back

=head3 Logger

The Logger uses the embedded logger of a client or server config.
The scope of the logger object may extend the lifetime of the client
or sever object.
It contains Perl callbacks to the log and clear functions.
The log functions are exported to Perl.

=over 4

=item $logger->setCallback($log, $context, $clear);

=over 8

=item $log = sub { my ($context, $level, $category, $message) = @_ }

=item $clear = sub { my ($context) = @_ }

=back

=item $logger->logTrace($category, $msg, ...);

=item $logger->logDebug($category, $msg, ...);

=item $logger->logInfo($category, $msg, ...);

=item $logger->logWarning($category, $msg, ...);

=item $logger->logError($category, $msg, ...);

=item $logger->logFatal($category, $msg, ...);

=back

=head1 SEE ALSO

OPC UA library, L<https://open62541.org/>

OPC Foundation, L<https://opcfoundation.org/>

OPCUA::Open62541::Constant

=head1 AUTHORS

Alexander Bluhm E<lt>bluhm@genua.deE<gt>,
Anton Borowka,
Arne Becker,
Marvin Knoblauch E<lt>mknob@genua.deE<gt>

=head1 CAVEATS

This interface is far from complete.

The C types UA_Int64 and UA_UInt64 are implemented as Perl integers
IV and UV respectively.
This only works for Perl that is compiled on a 64 bit platform.
32 bit platforms are currently not supported.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2020-2023 Alexander Bluhm

Copyright (c) 2020-2023 Anton Borowka

Copyright (c) 2020 Arne Becker

Copyright (c) 2020 Marvin Knoblauch

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Thanks to genua GmbH, https://www.genua.de/ for sponsoring this work.

=cut
