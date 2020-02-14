/*
 * Copyright (c) 2020 Alexander Bluhm <bluhm@genua.de>
 *
 * This is free software; you can redistribute it and/or modify it under
 * the same terms as the Perl 5 programming language system itself.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <open62541/types.h>
#include <open62541/statuscodes.h>
#include <open62541/server.h>
#include <open62541/server_config_default.h>
#include <open62541/client.h>
#include <open62541/client_config_default.h>

//#define DEBUG
#ifdef DEBUG
# define DPRINTF(format, args...)					\
	do {								\
		fprintf(stderr, "%s: " format "\n", __func__, ##args);	\
	} while (0)
#else
# define DPRINTF(format, x...)
#endif

/* types.h */
typedef UA_Boolean		OPCUA_Open62541_Boolean;
typedef UA_SByte		OPCUA_Open62541_SByte;
typedef UA_Byte			OPCUA_Open62541_Byte;
typedef UA_Int16		OPCUA_Open62541_Int16;
typedef UA_UInt16		OPCUA_Open62541_UInt16;
typedef UA_Int32		OPCUA_Open62541_Int32;
typedef UA_UInt32		OPCUA_Open62541_UInt32;
typedef UA_Int64		OPCUA_Open62541_Int64;
typedef UA_UInt64		OPCUA_Open62541_UInt64;
typedef UA_ByteString		OPCUA_Open62541_ByteString;
typedef UA_StatusCode		OPCUA_Open62541_StatusCode;
typedef UA_String		OPCUA_Open62541_String;
typedef const UA_DataType *	OPCUA_Open62541_DataType;

/* types_generated.h */
typedef UA_Variant *		OPCUA_Open62541_Variant;
typedef UA_VariableAttributes *	OPCUA_Open62541_VariableAttributes;

union type_storage {
	UA_Boolean			ts_Boolean;
	UA_SByte			ts_SByte;
	UA_Byte				ts_Byte;
	UA_Int16			ts_Int16;
	UA_UInt16			ts_UInt16;
	UA_Int32			ts_Int32;
	UA_UInt32			ts_UInt32;
	UA_Int64			ts_Int64;
	UA_UInt64			ts_UInt64;
	UA_Float			ts_Float;
	UA_Double			ts_Double;
	UA_String			ts_String;
	UA_DateTime			ts_DateTime;
	UA_Guid				ts_Guid;
	UA_ByteString			ts_ByteString;
	UA_XmlElement			ts_XmlElement;
	UA_NodeId			ts_NodeId;
	UA_ExpandedNodeId		ts_ExpandedNodeId;
	UA_StatusCode			ts_StatusCode;
	UA_QualifiedName		ts_QualifiedName;
	UA_LocalizedText		ts_LocalizedText;
	UA_ExtensionObject		ts_ExtensionObject;
	UA_DataValue			ts_DataValue;
	UA_Variant			ts_Variant;
	UA_DiagnosticInfo		ts_DiagnosticInfo;
	UA_NodeClass			ts_NodeClass;
	UA_Argument			ts_Argument;
	UA_EnumValueType		ts_EnumValueType;
	UA_Duration			ts_Duration;
	UA_UtcTime			ts_UtcTime;
	UA_LocaleId			ts_LocaleId;
	UA_ApplicationType		ts_ApplicationType;
	UA_ApplicationDescription	ts_ApplicationDescription;
	UA_RequestHeader		ts_RequestHeader;
	UA_ResponseHeader		ts_ResponseHeader;
	UA_ServiceFault			ts_ServiceFault;
	UA_FindServersRequest		ts_FindServersRequest;
	UA_FindServersResponse		ts_FindServersResponse;
	UA_ServerOnNetwork		ts_ServerOnNetwork;
	UA_FindServersOnNetworkRequest	ts_FindServersOnNetworkRequest;
	UA_FindServersOnNetworkResponse	ts_FindServersOnNetworkResponse;
	UA_MessageSecurityMode		ts_MessageSecurityMode;
	UA_UserTokenType		ts_UserTokenType;
	UA_UserTokenPolicy		ts_UserTokenPolicy;
	UA_EndpointDescription		ts_EndpointDescription;
	UA_GetEndpointsRequest		ts_GetEndpointsRequest;
	UA_GetEndpointsResponse		ts_GetEndpointsResponse;
	UA_RegisteredServer		ts_RegisteredServer;
	UA_RegisterServerRequest	ts_RegisterServerRequest;
	UA_RegisterServerResponse	ts_RegisterServerResponse;
	UA_DiscoveryConfiguration	ts_DiscoveryConfiguration;
	UA_MdnsDiscoveryConfiguration	ts_MdnsDiscoveryConfiguration;
	UA_RegisterServer2Request	ts_RegisterServer2Request;
	UA_RegisterServer2Response	ts_RegisterServer2Response;
	UA_SecurityTokenRequestType	ts_SecurityTokenRequestType;
	UA_ChannelSecurityToken		ts_ChannelSecurityToken;
	UA_OpenSecureChannelRequest	ts_OpenSecureChannelRequest;
	UA_OpenSecureChannelResponse	ts_OpenSecureChannelResponse;
	UA_CloseSecureChannelRequest	ts_CloseSecureChannelRequest;
	UA_CloseSecureChannelResponse	ts_CloseSecureChannelResponse;
	UA_SignedSoftwareCertificate	ts_SignedSoftwareCertificate;
	UA_SignatureData		ts_SignatureData;
	UA_CreateSessionRequest		ts_CreateSessionRequest;
	UA_CreateSessionResponse	ts_CreateSessionResponse;
	UA_UserIdentityToken		ts_UserIdentityToken;
	UA_AnonymousIdentityToken	ts_AnonymousIdentityToken;
	UA_UserNameIdentityToken	ts_UserNameIdentityToken;
	UA_X509IdentityToken		ts_X509IdentityToken;
	UA_IssuedIdentityToken		ts_IssuedIdentityToken;
	UA_ActivateSessionRequest	ts_ActivateSessionRequest;
	UA_ActivateSessionResponse	ts_ActivateSessionResponse;
	UA_CloseSessionRequest		ts_CloseSessionRequest;
	UA_CloseSessionResponse		ts_CloseSessionResponse;
	UA_NodeAttributesMask		ts_NodeAttributesMask;
	UA_NodeAttributes		ts_NodeAttributes;
	UA_ObjectAttributes		ts_ObjectAttributes;
	UA_VariableAttributes		ts_VariableAttributes;
	UA_MethodAttributes		ts_MethodAttributes;
	UA_ObjectTypeAttributes		ts_ObjectTypeAttributes;
	UA_VariableTypeAttributes	ts_VariableTypeAttributes;
	UA_ReferenceTypeAttributes	ts_ReferenceTypeAttributes;
	UA_DataTypeAttributes		ts_DataTypeAttributes;
	UA_ViewAttributes		ts_ViewAttributes;
	UA_AddNodesItem			ts_AddNodesItem;
	UA_AddNodesResult		ts_AddNodesResult;
	UA_AddNodesRequest		ts_AddNodesRequest;
	UA_AddNodesResponse		ts_AddNodesResponse;
	UA_AddReferencesItem		ts_AddReferencesItem;
	UA_AddReferencesRequest		ts_AddReferencesRequest;
	UA_AddReferencesResponse	ts_AddReferencesResponse;
	UA_DeleteNodesItem		ts_DeleteNodesItem;
	UA_DeleteNodesRequest		ts_DeleteNodesRequest;
	UA_DeleteNodesResponse		ts_DeleteNodesResponse;
	UA_DeleteReferencesItem		ts_DeleteReferencesItem;
	UA_DeleteReferencesRequest	ts_DeleteReferencesRequest;
	UA_DeleteReferencesResponse	ts_DeleteReferencesResponse;
	UA_BrowseDirection		ts_BrowseDirection;
	UA_ViewDescription		ts_ViewDescription;
	UA_BrowseDescription		ts_BrowseDescription;
	UA_BrowseResultMask		ts_BrowseResultMask;
	UA_ReferenceDescription		ts_ReferenceDescription;
	UA_BrowseResult			ts_BrowseResult;
	UA_BrowseRequest		ts_BrowseRequest;
	UA_BrowseResponse		ts_BrowseResponse;
	UA_BrowseNextRequest		ts_BrowseNextRequest;
	UA_BrowseNextResponse		ts_BrowseNextResponse;
	UA_RelativePathElement		ts_RelativePathElement;
	UA_RelativePath			ts_RelativePath;
	UA_BrowsePath			ts_BrowsePath;
	UA_BrowsePathTarget		ts_BrowsePathTarget;
	UA_BrowsePathResult		ts_BrowsePathResult;
	UA_TranslateBrowsePathsToNodeIdsRequest
	    ts_TranslateBrowsePathsToNodeIdsRequest;
	UA_TranslateBrowsePathsToNodeIdsResponse
	    ts_TranslateBrowsePathsToNodeIdsResponse;
	UA_RegisterNodesRequest		ts_RegisterNodesRequest;
	UA_RegisterNodesResponse	ts_RegisterNodesResponse;
	UA_UnregisterNodesRequest	ts_UnregisterNodesRequest;
	UA_UnregisterNodesResponse	ts_UnregisterNodesResponse;
	UA_FilterOperator		ts_FilterOperator;
	UA_ContentFilterElement		ts_ContentFilterElement;
	UA_ContentFilter		ts_ContentFilter;
	UA_FilterOperand		ts_FilterOperand;
	UA_ElementOperand		ts_ElementOperand;
	UA_LiteralOperand		ts_LiteralOperand;
	UA_AttributeOperand		ts_AttributeOperand;
	UA_SimpleAttributeOperand	ts_SimpleAttributeOperand;
	UA_ContentFilterElementResult	ts_ContentFilterElementResult;
	UA_ContentFilterResult		ts_ContentFilterResult;
	UA_TimestampsToReturn		ts_TimestampsToReturn;
	UA_ReadValueId			ts_ReadValueId;
	UA_ReadRequest			ts_ReadRequest;
	UA_ReadResponse			ts_ReadResponse;
	UA_WriteValue			ts_WriteValue;
	UA_WriteRequest			ts_WriteRequest;
	UA_WriteResponse		ts_WriteResponse;
	UA_CallMethodRequest		ts_CallMethodRequest;
	UA_CallMethodResult		ts_CallMethodResult;
	UA_CallRequest			ts_CallRequest;
	UA_CallResponse			ts_CallResponse;
	UA_MonitoringMode		ts_MonitoringMode;
	UA_DataChangeTrigger		ts_DataChangeTrigger;
	UA_DeadbandType			ts_DeadbandType;
	UA_DataChangeFilter		ts_DataChangeFilter;
	UA_EventFilter			ts_EventFilter;
	UA_AggregateConfiguration	ts_AggregateConfiguration;
	UA_AggregateFilter		ts_AggregateFilter;
	UA_EventFilterResult		ts_EventFilterResult;
	UA_MonitoringParameters		ts_MonitoringParameters;
	UA_MonitoredItemCreateRequest	ts_MonitoredItemCreateRequest;
	UA_MonitoredItemCreateResult	ts_MonitoredItemCreateResult;
	UA_CreateMonitoredItemsRequest	ts_CreateMonitoredItemsRequest;
	UA_CreateMonitoredItemsResponse	ts_CreateMonitoredItemsResponse;
	UA_MonitoredItemModifyRequest	ts_MonitoredItemModifyRequest;
	UA_MonitoredItemModifyResult	ts_MonitoredItemModifyResult;
	UA_ModifyMonitoredItemsRequest	ts_ModifyMonitoredItemsRequest;
	UA_ModifyMonitoredItemsResponse	ts_ModifyMonitoredItemsResponse;
	UA_SetMonitoringModeRequest	ts_SetMonitoringModeRequest;
	UA_SetMonitoringModeResponse	ts_SetMonitoringModeResponse;
	UA_SetTriggeringRequest		ts_SetTriggeringRequest;
	UA_SetTriggeringResponse	ts_SetTriggeringResponse;
	UA_DeleteMonitoredItemsRequest	ts_DeleteMonitoredItemsRequest;
	UA_DeleteMonitoredItemsResponse	ts_DeleteMonitoredItemsResponse;
	UA_CreateSubscriptionRequest	ts_CreateSubscriptionRequest;
	UA_CreateSubscriptionResponse	ts_CreateSubscriptionResponse;
	UA_ModifySubscriptionRequest	ts_ModifySubscriptionRequest;
	UA_ModifySubscriptionResponse	ts_ModifySubscriptionResponse;
	UA_SetPublishingModeRequest	ts_SetPublishingModeRequest;
	UA_SetPublishingModeResponse	ts_SetPublishingModeResponse;
	UA_NotificationMessage		ts_NotificationMessage;
	UA_MonitoredItemNotification	ts_MonitoredItemNotification;
	UA_EventFieldList		ts_EventFieldList;
	UA_StatusChangeNotification	ts_StatusChangeNotification;
	UA_SubscriptionAcknowledgement	ts_SubscriptionAcknowledgement;
	UA_PublishRequest		ts_PublishRequest;
	UA_PublishResponse		ts_PublishResponse;
	UA_RepublishRequest		ts_RepublishRequest;
	UA_RepublishResponse		ts_RepublishResponse;
	UA_DeleteSubscriptionsRequest	ts_DeleteSubscriptionsRequest;
	UA_DeleteSubscriptionsResponse	ts_DeleteSubscriptionsResponse;
	UA_BuildInfo			ts_BuildInfo;
	UA_RedundancySupport		ts_RedundancySupport;
	UA_ServerState			ts_ServerState;
	UA_ServerDiagnosticsSummaryDataType
	    ts_ServerDiagnosticsSummaryDataType;
	UA_ServerStatusDataType		ts_ServerStatusDataType;
	UA_Range			ts_Range;
	UA_DataChangeNotification	ts_DataChangeNotification;
	UA_EventNotificationList	ts_EventNotificationList;
};

/* server.h */
typedef UA_Server *		OPCUA_Open62541_Server;
typedef struct {
	UA_ServerConfig *	svc_serverconfig;
	SV *			svc_server;
} *				OPCUA_Open62541_ServerConfig;

/* client.h */
typedef UA_Client *		OPCUA_Open62541_Client;
typedef struct {
	UA_ClientConfig *	clc_clientconfig;
	SV *			clc_client;
} *				OPCUA_Open62541_ClientConfig;
typedef UA_ClientState		OPCUA_Open62541_ClientState;

/* Magic callback for UA_Server_run() will change the C variable. */
static int
server_run_mgset(pTHX_ SV* sv, MAGIC* mg)
{
	volatile OPCUA_Open62541_Boolean	*running;

	DPRINTF("sv %p, mg %p, ptr %p", sv, mg, mg->mg_ptr);
	running = (void *)mg->mg_ptr;
	*running = (bool)SvTRUE(sv);
	return 0;
}

static MGVTBL server_run_mgvtbl = { 0, server_run_mgset, 0, 0, 0, 0, 0, 0 };

/*#########################################################################*/
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541

PROTOTYPES: DISABLE

INCLUDE: Open62541-types.xsh

OPCUA_Open62541_Boolean
TRUE()
    CODE:
	RETVAL = UA_TRUE;
    OUTPUT:
	RETVAL

OPCUA_Open62541_Boolean
FALSE()
    CODE:
	RETVAL = UA_FALSE;
    OUTPUT:
	RETVAL

OPCUA_Open62541_SByte
SBYTE_MIN()
    CODE:
	RETVAL = UA_SBYTE_MIN;
    OUTPUT:
	RETVAL

OPCUA_Open62541_SByte
SBYTE_MAX()
    CODE:
	RETVAL = UA_SBYTE_MAX;
    OUTPUT:
	RETVAL

OPCUA_Open62541_Byte
BYTE_MIN()
    CODE:
	RETVAL = UA_BYTE_MIN;
    OUTPUT:
	RETVAL

OPCUA_Open62541_Byte
BYTE_MAX()
    CODE:
	RETVAL = UA_BYTE_MAX;
    OUTPUT:
	RETVAL

OPCUA_Open62541_Int16
INT16_MIN()
    CODE:
	RETVAL = UA_INT16_MIN;
    OUTPUT:
	RETVAL

OPCUA_Open62541_Int16
INT16_MAX()
    CODE:
	RETVAL = UA_INT16_MAX;
    OUTPUT:
	RETVAL

OPCUA_Open62541_UInt16
UINT16_MIN()
    CODE:
	RETVAL = UA_UINT16_MIN;
    OUTPUT:
	RETVAL

OPCUA_Open62541_UInt16
UINT16_MAX()
    CODE:
	RETVAL = UA_UINT16_MAX;
    OUTPUT:
	RETVAL

OPCUA_Open62541_Int32
INT32_MIN()
    CODE:
	RETVAL = UA_INT32_MIN;
    OUTPUT:
	RETVAL

OPCUA_Open62541_Int32
INT32_MAX()
    CODE:
	RETVAL = UA_INT32_MAX;
    OUTPUT:
	RETVAL

OPCUA_Open62541_UInt32
UINT32_MIN()
    CODE:
	RETVAL = UA_UINT32_MIN;
    OUTPUT:
	RETVAL

OPCUA_Open62541_UInt32
UINT32_MAX()
    CODE:
	RETVAL = UA_UINT32_MAX;
    OUTPUT:
	RETVAL

OPCUA_Open62541_Int64
INT64_MIN()
    CODE:
	RETVAL = UA_INT64_MIN;
    OUTPUT:
	RETVAL

OPCUA_Open62541_Int64
INT64_MAX()
    CODE:
	RETVAL = UA_INT64_MAX;
    OUTPUT:
	RETVAL

OPCUA_Open62541_UInt64
UINT64_MIN()
    CODE:
	RETVAL = UA_UINT64_MIN;
    OUTPUT:
	RETVAL

OPCUA_Open62541_UInt64
UINT64_MAX()
    CODE:
	RETVAL = UA_UINT64_MAX;
    OUTPUT:
	RETVAL

OPCUA_Open62541_ClientState
CLIENTSTATE_DISCONNECTED()
    CODE:
	RETVAL = UA_CLIENTSTATE_DISCONNECTED;
    OUTPUT:
	RETVAL

OPCUA_Open62541_ClientState
CLIENTSTATE_WAITING_FOR_ACK()
    CODE:
	RETVAL = UA_CLIENTSTATE_WAITING_FOR_ACK;
    OUTPUT:
	RETVAL

OPCUA_Open62541_ClientState
CLIENTSTATE_CONNECTED()
    CODE:
	RETVAL = UA_CLIENTSTATE_CONNECTED;
    OUTPUT:
	RETVAL

OPCUA_Open62541_ClientState
CLIENTSTATE_SECURECHANNEL()
    CODE:
	RETVAL = UA_CLIENTSTATE_SECURECHANNEL;
    OUTPUT:
	RETVAL

OPCUA_Open62541_ClientState
CLIENTSTATE_SESSION()
    CODE:
	RETVAL = UA_CLIENTSTATE_SESSION;
    OUTPUT:
	RETVAL

OPCUA_Open62541_ClientState
CLIENTSTATE_SESSION_DISCONNECTED()
    CODE:
	RETVAL = UA_CLIENTSTATE_SESSION_DISCONNECTED;
    OUTPUT:
	RETVAL

OPCUA_Open62541_ClientState
CLIENTSTATE_SESSION_RENEWED()
    CODE:
	RETVAL = UA_CLIENTSTATE_SESSION_RENEWED;
    OUTPUT:
	RETVAL

INCLUDE: Open62541-statuscodes.xsh

#############################################################################
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::Variant	PREFIX = UA_Variant_

# 6.1.23 Variant, types_generated_handling.h

OPCUA_Open62541_Variant
UA_Variant_new(class)
	char *				class
    INIT:
	if (strcmp(class, "OPCUA::Open62541::Variant") != 0)
		croak("class '%s' is not OPCUA::Open62541::Variant", class);
    CODE:
	RETVAL = UA_Variant_new();
	if (RETVAL == NULL)
		croak("UA_Variant_new");
	DPRINTF("attr %p", RETVAL);
    OUTPUT:
	RETVAL

void
UA_Variant_DESTROY(p)
	OPCUA_Open62541_Variant		p
    CODE:
	DPRINTF("variant %p", p);
	UA_Variant_delete(p);

OPCUA_Open62541_Boolean
UA_Variant_isEmpty(v)
	OPCUA_Open62541_Variant		v

OPCUA_Open62541_Boolean
UA_Variant_isScalar(v)
	OPCUA_Open62541_Variant		v

OPCUA_Open62541_Boolean
UA_Variant_hasScalarType(v, type)
	OPCUA_Open62541_Variant		v
	OPCUA_Open62541_DataType	type

OPCUA_Open62541_Boolean
UA_Variant_hasArrayType(v, type)
	OPCUA_Open62541_Variant		v
	OPCUA_Open62541_DataType	type

void
UA_Variant_setScalar(v, p, type)
	OPCUA_Open62541_Variant		v
	SV *				p
	OPCUA_Open62541_DataType	type
    INIT:
	union type_storage ts;
	UA_StatusCode sc;
	IV iv;
	UV uv;
    CODE:
	switch (type->typeIndex) {
	case UA_TYPES_BOOLEAN:
		ts.ts_Boolean = SvTRUE(p);
		break;
	case UA_TYPES_SBYTE:
		iv = SvIV(p);
		if (iv < UA_SBYTE_MIN)
			warn("Integer value %li less than UA_SBYTE_MIN", iv);
		if (iv > UA_SBYTE_MAX)
			warn("Integer value %li greater than UA_SBYTE_MAX", iv);
		ts.ts_SByte = iv;
		break;
	case UA_TYPES_BYTE:
		uv = SvUV(p);
		if (uv > UA_BYTE_MAX)
			warn("Unsigned value %lu greater than UA_BYTE_MAX", uv);
		ts.ts_Byte = uv;
		break;
	case UA_TYPES_INT16:
		iv = SvIV(p);
		if (iv < UA_INT16_MIN)
			warn("Integer value %li less than UA_INT16_MIN", iv);
		if (iv > UA_INT16_MAX)
			warn("Integer value %li greater than UA_INT16_MAX", iv);
		ts.ts_Int16 = iv;
		break;
	case UA_TYPES_UINT16:
		uv = SvUV(p);
		if (uv > UA_UINT16_MAX)
			warn("Unsigned value %lu greater than UA_UINT16_MAX",
			    uv);
		ts.ts_UInt16 = uv;
		break;
	case UA_TYPES_INT32:
		iv = SvIV(p);
		if (iv < UA_INT32_MIN)
			warn("Integer value %li less than UA_INT32_MIN", iv);
		if (iv > UA_INT32_MAX)
			warn("Integer value %li greater than UA_INT32_MAX", iv);
		ts.ts_Int32 = iv;
		break;
	case UA_TYPES_UINT32:
		uv = SvUV(p);
		if (uv > UA_UINT32_MAX)
			warn("Unsigned value %lu greater than UA_UINT32_MAX",
			    uv);
		ts.ts_UInt32 = uv;
		break;
	case UA_TYPES_INT64:
		/* XXX this only works for Perl on 64 bit platforms */
		iv = SvIV(p);
		if (iv < UA_INT64_MIN)
			warn("Integer value %li less than UA_INT64_MIN", iv);
		if (iv > UA_INT64_MAX)
			warn("Integer value %li greater than UA_INT64_MAX", iv);
		ts.ts_Int64 = iv;
		break;
	case UA_TYPES_UINT64:
		/* XXX this only works for Perl on 64 bit platforms */
		uv = SvUV(p);
		if (uv > UA_UINT64_MAX)
			warn("Unsigned value %lu greater than UA_UINT64_MAX",
			    uv);
		ts.ts_UInt64 = uv;
		break;
	case UA_TYPES_STRING:
		ts.ts_String.data = SvPV(p, ts.ts_String.length);
		break;
	case UA_TYPES_BYTESTRING:
		ts.ts_ByteString.data = SvPV(p, ts.ts_ByteString.length);
		break;
	case UA_TYPES_STATUSCODE:
		ts.ts_StatusCode = SvUV(p);
		break;
	default:
		croak("%s: type %s index %u not implemented", __func__,
		    type->typeName, type->typeIndex);
	}
	sc = UA_Variant_setScalarCopy(v, &ts, type);
	if (sc != UA_STATUSCODE_GOOD) {
		croak("%s: UA_Variant_setScalarCopy: status code %u",
		    __func__, sc);
	}

#############################################################################
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::VariableAttributes	PREFIX = UA_VariableAttributes_

OPCUA_Open62541_VariableAttributes
UA_VariableAttributes_default(class)
	char *				class
    INIT:
	if (strcmp(class, "OPCUA::Open62541::VariableAttributes") != 0)
		croak("class '%s' is not OPCUA::Open62541::VariableAttributes",
		    class);
    CODE:
	RETVAL = malloc(sizeof(*RETVAL));
	if (RETVAL == NULL)
		croak("malloc");
	DPRINTF("attr %p", RETVAL);
	*RETVAL = UA_VariableAttributes_default;
    OUTPUT:
	RETVAL

void
UA_VariableAttributes_DESTROY(attr)
	OPCUA_Open62541_VariableAttributes	attr
    CODE:
	DPRINTF("attr %p", attr);
	free(attr);

#############################################################################
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::Server		PREFIX = UA_Server_

OPCUA_Open62541_Server
UA_Server_new(class)
	char *				class
    INIT:
	if (strcmp(class, "OPCUA::Open62541::Server") != 0)
		croak("class '%s' is not OPCUA::Open62541::Server", class);
    CODE:
	RETVAL = UA_Server_new();
	DPRINTF("class %s, server %p", class, RETVAL);
    OUTPUT:
	RETVAL

OPCUA_Open62541_Server
UA_Server_newWithConfig(class, config)
	char *				class
	OPCUA_Open62541_ServerConfig	config
    INIT:
	if (strcmp(class, "OPCUA::Open62541::Server") != 0)
		croak("class '%s' is not OPCUA::Open62541::Server", class);
    CODE:
	RETVAL = UA_Server_newWithConfig(config->svc_serverconfig);
	DPRINTF("class %s, config %p, server %p", class,
	    config->svc_serverconfig, RETVAL);
    OUTPUT:
	RETVAL

void
UA_Server_DESTROY(server)
	OPCUA_Open62541_Server		server
    CODE:
	DPRINTF("server %p", server);
	UA_Server_delete(server);

OPCUA_Open62541_ServerConfig
UA_Server_getConfig(server)
	OPCUA_Open62541_Server		server
    CODE:
	RETVAL = malloc(sizeof(*RETVAL));
	if (RETVAL == NULL)
		croak("malloc");
	RETVAL->svc_serverconfig = UA_Server_getConfig(server);
	DPRINTF("server %p, config %p", server, RETVAL->svc_serverconfig);
	if (RETVAL->svc_serverconfig == NULL) {
		free(RETVAL);
		XSRETURN_UNDEF;
	}
	/* When server gets out of scope, config still uses its memory. */
	RETVAL->svc_server = SvREFCNT_inc(SvRV(ST(0)));
    OUTPUT:
	RETVAL

OPCUA_Open62541_StatusCode
UA_Server_run(server, running)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_Boolean		&running
    INIT:
	MAGIC *mg;
    CODE:
	/* If running is changed, the magic callback will report to server. */
	mg = sv_magicext(ST(1), NULL, PERL_MAGIC_ext, &server_run_mgvtbl,
	    (void *)&running, 0);
	DPRINTF("server %p, &running %p, mg %p", server, &running, mg);
	RETVAL = UA_Server_run(server, &running);
	sv_unmagicext(ST(1), PERL_MAGIC_ext, &server_run_mgvtbl);
    OUTPUT:
	RETVAL

OPCUA_Open62541_StatusCode
UA_Server_run_startup(server)
	OPCUA_Open62541_Server		server

OPCUA_Open62541_UInt16
UA_Server_run_iterate(server, waitInternal)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_Boolean		waitInternal

OPCUA_Open62541_StatusCode
UA_Server_run_shutdown(server)
	OPCUA_Open62541_Server		server

#############################################################################
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::ServerConfig	PREFIX = UA_ServerConfig_

void
UA_ServerConfig_DESTROY(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	DPRINTF("config %p", config->svc_serverconfig);
	SvREFCNT_dec(config->svc_server);
	free(config);

OPCUA_Open62541_StatusCode
UA_ServerConfig_setDefault(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	DPRINTF("config %p", config->svc_serverconfig);
	RETVAL = UA_ServerConfig_setDefault(config->svc_serverconfig);
    OUTPUT:
	RETVAL

OPCUA_Open62541_StatusCode
UA_ServerConfig_setMinimal(config, portNumber, certificate)
	OPCUA_Open62541_ServerConfig	config
	OPCUA_Open62541_UInt16		portNumber
	OPCUA_Open62541_ByteString	certificate;
    CODE:
	DPRINTF("config %p, port %hu", config->svc_serverconfig, portNumber);
	RETVAL = UA_ServerConfig_setMinimal(config->svc_serverconfig,
	    portNumber, &certificate);
    OUTPUT:
	RETVAL

void
UA_ServerConfig_clean(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	DPRINTF("config %p", config->svc_serverconfig);
	UA_ServerConfig_clean(config->svc_serverconfig);

void
UA_ServerConfig_setCustomHostname(config, customHostname)
	OPCUA_Open62541_ServerConfig	config
	OPCUA_Open62541_String		customHostname
    CODE:
	DPRINTF("config %p, data %p, length %zu", config->svc_serverconfig,
	    customHostname.data, customHostname.length);
	UA_ServerConfig_setCustomHostname(config->svc_serverconfig,
	    customHostname);

#############################################################################
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::Client		PREFIX = UA_Client_

OPCUA_Open62541_Client
UA_Client_new(class)
	char *				class
    INIT:
	if (strcmp(class, "OPCUA::Open62541::Client") != 0)
		croak("class '%s' is not OPCUA::Open62541::Client", class);
    CODE:
	RETVAL = UA_Client_new();
	DPRINTF("class %s, client %p", class, RETVAL);
    OUTPUT:
	RETVAL

void
UA_Client_DESTROY(client)
	OPCUA_Open62541_Client		client
    CODE:
	DPRINTF("client %p", client);
	UA_Client_delete(client);

OPCUA_Open62541_ClientConfig
UA_Client_getConfig(client)
	OPCUA_Open62541_Client		client
    CODE:
	RETVAL = malloc(sizeof(*RETVAL));
	if (RETVAL == NULL)
		croak("malloc");
	RETVAL->clc_clientconfig = UA_Client_getConfig(client);
	DPRINTF("client %p, config %p", client, RETVAL->clc_clientconfig);
	if (RETVAL->clc_clientconfig == NULL) {
		free(RETVAL);
		XSRETURN_UNDEF;
	}
	/* When client gets out of scope, config still uses its memory. */
	RETVAL->clc_client = SvREFCNT_inc(SvRV(ST(0)));
    OUTPUT:
	RETVAL

OPCUA_Open62541_StatusCode
UA_Client_connect(client, endpointUrl)
	OPCUA_Open62541_Client		client
	char *				endpointUrl

OPCUA_Open62541_StatusCode
UA_Client_disconnect(client)
	OPCUA_Open62541_Client		client

OPCUA_Open62541_ClientState
UA_Client_getState(client)
	OPCUA_Open62541_Client		client

#############################################################################
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::ClientConfig	PREFIX = UA_ClientConfig_

void
UA_ClientConfig_DESTROY(config)
	OPCUA_Open62541_ClientConfig	config
    CODE:
	DPRINTF("config %p", config->clc_clientconfig);
	SvREFCNT_dec(config->clc_client);
	free(config);

OPCUA_Open62541_StatusCode
UA_ClientConfig_setDefault(config)
	OPCUA_Open62541_ClientConfig	config
    CODE:
	DPRINTF("config %p", config->clc_clientconfig);
	RETVAL = UA_ClientConfig_setDefault(config->clc_clientconfig);
    OUTPUT:
	RETVAL
