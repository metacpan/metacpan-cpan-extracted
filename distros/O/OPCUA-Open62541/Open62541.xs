/*
 * Copyright (c) 2020 Alexander Bluhm <bluhm@genua.de>
 * Copyright (c) 2020 Anton Borowka
 * Copyright (c) 2020 Marvin Knoblauch <mknob@genua.de>
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
#include <open62541/client_highlevel_async.h>

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
typedef UA_UInt32 *		OPCUA_Open62541_UInt32;
typedef const UA_DataType *	OPCUA_Open62541_DataType;
typedef enum UA_NodeIdType	OPCUA_Open62541_NodeIdType;
typedef UA_NodeId *		OPCUA_Open62541_NodeId;

/* types_generated.h */
typedef UA_BrowseResultMask	OPCUA_Open62541_BrowseResultMask;
typedef UA_Variant *		OPCUA_Open62541_Variant;

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

static void XS_pack_OPCUA_Open62541_DataType(SV *, OPCUA_Open62541_DataType)
    __attribute__((unused));
static OPCUA_Open62541_DataType XS_unpack_OPCUA_Open62541_DataType(SV *)
    __attribute__((unused));

/*
 * Prototypes for builtin and generated types.
 * Pack and unpack conversions for generated types.
 * 6.1 Builtin Types
 * 6.5 Generated Data Type Definitions
 */
#include "Open62541-packed.xsh"

/* 6.1 Builtin Types, pack and unpack type conversions for builtin types. */

/* 6.1.1 Boolean, types.h */

static UA_Boolean
XS_unpack_UA_Boolean(SV *in)
{
	return SvTRUE(in);
}

static void
XS_pack_UA_Boolean(SV *out, UA_Boolean in)
{
	sv_setsv(out, boolSV(in));
}

/* 6.1.2 SByte ... 6.1.9 UInt64, types.h */

#define XS_PACKED_CHECK_IV(type, limit)					\
									\
static UA_##type							\
XS_unpack_UA_##type(SV *in)						\
{									\
	IV out = SvIV(in);						\
									\
	if (out < UA_##limit##_MIN)					\
		warn("Integer value %li less than UA_"			\
		    #limit "_MIN", out);				\
	if (out > UA_##limit##_MAX)					\
		warn("Integer value %li greater than UA_"		\
		    #limit "_MAX", out);				\
	return out;							\
}									\
									\
static void								\
XS_pack_UA_##type(SV *out, UA_##type in)				\
{									\
	sv_setiv(out, in);						\
}

#define XS_PACKED_CHECK_UV(type, limit)					\
									\
static UA_##type							\
XS_unpack_UA_##type(SV *in)						\
{									\
	UV out = SvUV(in);						\
									\
	if (out > UA_##limit##_MAX)					\
		warn("Unsigned value %li greater than UA_"		\
		    #limit "_MAX", out);				\
	return out;							\
}									\
									\
static void								\
XS_pack_UA_##type(SV *out, UA_##type in)				\
{									\
	sv_setuv(out, in);						\
}

XS_PACKED_CHECK_IV(SByte, SBYTE)	/* 6.1.2 SByte, types.h */
XS_PACKED_CHECK_UV(Byte, BYTE)		/* 6.1.3 Byte, types.h */
XS_PACKED_CHECK_IV(Int16, INT16)	/* 6.1.4 Int16, types.h */
XS_PACKED_CHECK_UV(UInt16, UINT16)	/* 6.1.5 UInt16, types.h */
XS_PACKED_CHECK_IV(Int32, INT32)	/* 6.1.6 Int32, types.h */
XS_PACKED_CHECK_UV(UInt32, UINT32)	/* 6.1.7 UInt32, types.h */
/* XXX this only works for Perl on 64 bit platforms */
XS_PACKED_CHECK_IV(Int64, INT64)	/* 6.1.8 Int64, types.h */
XS_PACKED_CHECK_UV(UInt64, UINT64)	/* 6.1.9 UInt64, types.h */

#undef XS_PACKED_CHECK_IV
#undef XS_PACKED_CHECK_UV

/* 6.1.10 Float, types.h */

static UA_Float
XS_unpack_UA_Float(SV *in)
{
	NV out = SvNV(in);

	if (out < -FLT_MAX)
		warn("Float value %le less than %le", out, -FLT_MAX);
	if (out > FLT_MAX)
		warn("Float value %le greater than %le", out, FLT_MAX);
	return out;
}

static void
XS_pack_UA_Float(SV *out, UA_Float in)
{
	sv_setnv(out, in);
}

/* 6.1.11 Double, types.h */

static UA_Double
XS_unpack_UA_Double(SV *in)
{
	return SvNV(in);
}

static void
XS_pack_UA_Double(SV *out, UA_Double in)
{
	sv_setnv(out, in);
}

/* 6.1.12 StatusCode, types.h */

static UA_StatusCode
XS_unpack_UA_StatusCode(SV *in)
{
	return SvUV(in);
}

static void
XS_pack_UA_StatusCode(SV *out, UA_StatusCode in)
{
	const char *name;

	/* SV out contains number and string, like $! does. */
	sv_setnv(out, in);
	name = UA_StatusCode_name(in);
	if (name[0] != '\0' && strcmp(name, "Unknown StatusCode") != 0)
		sv_setpv(out, name);
	else
		sv_setuv(out, in);
	SvNOK_on(out);
}

/* 6.1.13 String, types.h */

static UA_String
XS_unpack_UA_String(SV *in)
{
	UA_String out;

	/* XXX
	 * Converting undef to NULL string may be dangerous, check
	 * that all users of UA_String cope with NULL strings, before
	 * implementing that feature.  Currently Perl will warn about
	 * undef and convert to empty string.
	 */
	out.data = SvPVutf8(in, out.length);
	return out;
}

static void
XS_pack_UA_String(SV *out, UA_String in)
{
	if (in.length == 0 && in.data == NULL) {
		/* Convert NULL string to undef. */
		sv_setsv(out, &PL_sv_undef);
		return;
	}
	sv_setpvn(out, in.data, in.length);
	SvUTF8_on(out);
}

/* 6.1.14 DateTime, types.h */

static UA_DateTime
XS_unpack_UA_DateTime(SV *in)
{
	return SvIV(in);
}

static void
XS_pack_UA_DateTime(SV *out, UA_DateTime in)
{
	sv_setiv(out, in);
}

/* 6.1.15 Guid, types.h */

static UA_Guid
XS_unpack_UA_Guid(SV *in)
{
	UA_Guid out;
	char *data;
	size_t len;

	out = UA_GUID_NULL;
	data = SvPV(in, len);
	if (len > sizeof(out))
		len = sizeof(out);
	memcpy(&out, data, len);
	return out;
}

static void
XS_pack_UA_Guid(SV *out, UA_Guid in)
{
	sv_setpvn(out, (char *)&in, sizeof(in));
}

/* 6.1.16 ByteString, types.h */

static UA_ByteString
XS_unpack_UA_ByteString(SV *in)
{
	UA_ByteString out;

	/* XXX
	 * Converting undef to NULL string may be dangerous, check
	 * that all users of UA_ByteString cope with NULL strings, before
	 * implementing that feature.  Currently Perl will warn about
	 * undef and convert to empty string.
	 */
	out.data = SvPV(in, out.length);
	return out;
}

static void
XS_pack_UA_ByteString(SV *out, UA_ByteString in)
{
	if (in.length == 0 && in.data == NULL) {
		/* Convert NULL string to undef. */
		sv_setsv(out, &PL_sv_undef);
		return;
	}
	sv_setpvn(out, in.data, in.length);
}

/* 6.1.18 NodeId, types.h */

static UA_NodeId
XS_unpack_UA_NodeId(SV *in)
{
	UA_NodeId out;
	SV **svp;
	HV *hv;
	IV type;

	SvGETMAGIC(in);
	if (!SvROK(in)) {
		/*
		 * There exists a node in UA_TYPES for each type.
		 * If we get passed a TYPES index, take this node.
		 */
		return XS_unpack_OPCUA_Open62541_DataType(in)->typeId;
	}
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		croak("is not a HASH reference");
	}
	UA_NodeId_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetch(hv, "NodeId_namespaceIndex", 21, 0);
	if (svp == NULL)
		croak("%s: No NodeId_namespaceIndex in HASH", __func__);
	out.namespaceIndex = XS_unpack_UA_UInt16(*svp);

	svp = hv_fetch(hv, "NodeId_identifierType", 21, 0);
	if (svp == NULL)
		croak("%s: No NodeId_identifierType in HASH", __func__);
	type = SvIV(*svp);
	out.identifierType = type;

	svp = hv_fetch(hv, "NodeId_identifier", 17, 0);
	if (svp == NULL)
		croak("%s: No NodeId_identifier in HASH", __func__);
	switch (type) {
	case UA_NODEIDTYPE_NUMERIC:
		out.identifier.numeric = XS_unpack_UA_UInt32(*svp);
		break;
	case UA_NODEIDTYPE_STRING:
		out.identifier.string = XS_unpack_UA_String(*svp);
		break;
	case UA_NODEIDTYPE_GUID:
		out.identifier.guid = XS_unpack_UA_Guid(*svp);
		break;
	case UA_NODEIDTYPE_BYTESTRING:
		out.identifier.byteString = XS_unpack_UA_ByteString(*svp);
		break;
	default:
		croak("%s: NodeId_identifierType %ld unknown",
		    __func__, type);
	}
	return out;
}

static void
XS_pack_UA_NodeId(SV *out, UA_NodeId in)
{
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt16(sv, in.namespaceIndex);
	hv_stores(hv, "NodeId_namespaceIndex", sv);

	sv = newSV(0);
	XS_pack_UA_Int32(sv, in.identifierType);
	hv_stores(hv, "NodeId_identifierType", sv);

	sv = newSV(0);
	switch (in.identifierType) {
	case UA_NODEIDTYPE_NUMERIC:
		XS_pack_UA_UInt32(sv, in.identifier.numeric);
		break;
	case UA_NODEIDTYPE_STRING:
		XS_pack_UA_String(sv, in.identifier.string);
		break;
	case UA_NODEIDTYPE_GUID:
		XS_pack_UA_Guid(sv, in.identifier.guid);
		break;
	case UA_NODEIDTYPE_BYTESTRING:
		XS_pack_UA_ByteString(sv, in.identifier.byteString);
		break;
	default:
		croak("%s: NodeId_identifierType %d unknown",
		    __func__, (int)in.identifierType);
	}
	hv_stores(hv, "NodeId_identifier", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_QualifiedName
XS_unpack_UA_QualifiedName(SV *in)
{
	UA_QualifiedName out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		croak("is not a HASH reference");
	}
	UA_QualifiedName_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "QualifiedName_namespaceIndex", 0);
	if (svp != NULL)
		out.namespaceIndex = XS_unpack_UA_UInt16(*svp);

	svp = hv_fetchs(hv, "QualifiedName_name", 0);
	if (svp != NULL)
		out.name = XS_unpack_UA_String(*svp);

	return out;
}

static void
XS_pack_UA_QualifiedName(SV *out, UA_QualifiedName in)
{
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt16(sv, in.namespaceIndex);
	hv_stores(hv, "namespaceIndex", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.name);
	hv_stores(hv, "name", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_LocalizedText
XS_unpack_UA_LocalizedText(SV *in)
{
	UA_LocalizedText out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		croak("is not a HASH reference");
	}
	UA_LocalizedText_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "LocalizedText_locale", 0);
	if (svp != NULL)
		out.locale = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "LocalizedText_text", 0);
	if (svp != NULL)
		out.text = XS_unpack_UA_String(*svp);

	return out;
}

static void
XS_pack_UA_LocalizedText(SV *out, UA_LocalizedText in)
{
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_String(sv, in.locale);
	hv_stores(hv, "locale", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.text);
	hv_stores(hv, "text", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

/* 6.1.23 Variant, types.h */

static void
OPCUA_Open62541_Variant_setScalar(OPCUA_Open62541_Variant variant, SV *sv,
    OPCUA_Open62541_DataType type)
{
	union type_storage ts;
	UA_StatusCode sc;

	switch (type->typeIndex) {
	case UA_TYPES_BOOLEAN:
		ts.ts_Boolean = XS_unpack_UA_Boolean(sv);
		break;
	case UA_TYPES_SBYTE:
		ts.ts_SByte = XS_unpack_UA_SByte(sv);
		break;
	case UA_TYPES_BYTE:
		ts.ts_Byte = XS_unpack_UA_Byte(sv);
		break;
	case UA_TYPES_INT16:
		ts.ts_Int16 = XS_unpack_UA_Int16(sv);
		break;
	case UA_TYPES_UINT16:
		ts.ts_UInt16 = XS_unpack_UA_UInt16(sv);
		break;
	case UA_TYPES_INT32:
		ts.ts_Int32 = XS_unpack_UA_Int32(sv);
		break;
	case UA_TYPES_UINT32:
		ts.ts_UInt32 = XS_unpack_UA_UInt32(sv);
		break;
	case UA_TYPES_INT64:
		ts.ts_Int64 = XS_unpack_UA_Int64(sv);
		break;
	case UA_TYPES_UINT64:
		ts.ts_UInt64 = XS_unpack_UA_UInt64(sv);
		break;
	case UA_TYPES_STRING:
		ts.ts_String = XS_unpack_UA_String(sv);
		break;
	case UA_TYPES_BYTESTRING:
		ts.ts_ByteString = XS_unpack_UA_ByteString(sv);
		break;
	case UA_TYPES_STATUSCODE:
		ts.ts_StatusCode = XS_unpack_UA_StatusCode(sv);
		break;
	case UA_TYPES_DATETIME:
		ts.ts_DateTime = XS_unpack_UA_DateTime(sv);
		break;
	default:
		croak("%s: type %s index %u not implemented", __func__,
		    type->typeName, type->typeIndex);
	}
	sc = UA_Variant_setScalarCopy(variant, &ts, type);
	if (sc != UA_STATUSCODE_GOOD) {
		croak("%s: UA_Variant_setScalarCopy: status code %u",
		    __func__, sc);
	}
}

static UA_Variant
XS_unpack_UA_Variant(SV *in)
{
	UA_Variant out;
	OPCUA_Open62541_DataType type;
	SV **svp, **scalar, **array;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		croak("%s: Not a HASH reference", __func__);
	}
	UA_Variant_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "Variant_type", 0);
	if (svp == NULL)
		croak("%s: No Variant_type in HASH", __func__);
	type = XS_unpack_OPCUA_Open62541_DataType(*svp);

	scalar = hv_fetchs(hv, "Variant_scalar", 0);
	array = hv_fetchs(hv, "Variant_array", 0);
	if (scalar != NULL && array != NULL) {
		croak("%s: Both Variant_scalar and Variant_array in HASH",
		    __func__);
	}
	if (scalar == NULL && array == NULL) {
		croak("%s: Neither Variant_scalar not Variant_array in HASH",
		    __func__);
	}
	if (scalar != NULL) {
		OPCUA_Open62541_Variant_setScalar(&out, *scalar, type);
	}
	if (array != NULL) {
		croak("%s: Variant_array not implemented", __func__);
	}
	return out;
}

static void
OPCUA_Open62541_Variant_getScalar(OPCUA_Open62541_Variant variant, SV *sv)
{
	union type_storage *ts;

	ts = variant->data;
	switch (variant->type->typeIndex) {
	case UA_TYPES_BOOLEAN:
		XS_pack_UA_Boolean(sv, ts->ts_Boolean);
		break;
	case UA_TYPES_SBYTE:
		XS_pack_UA_SByte(sv, ts->ts_SByte);
		break;
	case UA_TYPES_BYTE:
		XS_pack_UA_Byte(sv, ts->ts_Byte);
		break;
	case UA_TYPES_INT16:
		XS_pack_UA_Int16(sv, ts->ts_Int16);
		break;
	case UA_TYPES_UINT16:
		XS_pack_UA_UInt16(sv, ts->ts_UInt16);
		break;
	case UA_TYPES_INT32:
		XS_pack_UA_Int32(sv, ts->ts_Int32);
		break;
	case UA_TYPES_UINT32:
		XS_pack_UA_UInt32(sv, ts->ts_UInt32);
		break;
	case UA_TYPES_INT64:
		XS_pack_UA_Int64(sv, ts->ts_Int64);
		break;
	case UA_TYPES_UINT64:
		XS_pack_UA_UInt64(sv, ts->ts_UInt64);
		break;
	case UA_TYPES_STRING:
		XS_pack_UA_String(sv, ts->ts_String);
		break;
	case UA_TYPES_BYTESTRING:
		XS_pack_UA_ByteString(sv, ts->ts_ByteString);
		break;
	case UA_TYPES_STATUSCODE:
		XS_pack_UA_StatusCode(sv, ts->ts_StatusCode);
		break;
	case UA_TYPES_DATETIME:
		XS_pack_UA_DateTime(sv, ts->ts_DateTime);
		break;
	default:
		croak("%s: type %s index %u not implemented", __func__,
		    variant->type->typeName, variant->type->typeIndex);
	}
}

static void
XS_pack_UA_Variant(SV *out, UA_Variant in)
{
	SV *sv;
	HV *hv;

	if (UA_Variant_isEmpty(&in)) {
		sv_setsv(out, &PL_sv_undef);
		return;
	}
	hv = newHV();

	sv = newSV(0);
	XS_pack_OPCUA_Open62541_DataType(sv, in.type);
	hv_stores(hv, "Variant_type", sv);

	if (UA_Variant_isScalar(&in)) {
		sv = newSV(0);
		OPCUA_Open62541_Variant_getScalar(&in, sv);
		hv_stores(hv, "Variant_scalar", sv);
	} else {
		croak("%s: Variant_array not implemented", __func__);
	}

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

/* 6.2 Generic Type Handling, UA_DataType, types.h */

static OPCUA_Open62541_DataType
XS_unpack_OPCUA_Open62541_DataType(SV *in)
{
	UV index = SvUV(in);

	if (index >= UA_TYPES_COUNT) {
		croak("%s: Unsigned value %li not below UA_TYPES_COUNT",
		    __func__,  index);
	}
	return &UA_TYPES[index];
}

static void
XS_pack_OPCUA_Open62541_DataType(SV *out, OPCUA_Open62541_DataType in)
{
	sv_setuv(out, in->typeIndex);
}

/* types.h */

static UA_DataValue
XS_unpack_UA_DataValue(SV *in)
{
	UA_DataValue out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		croak("%s: Not a HASH reference", __func__);
	}
	UA_DataValue_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DataValue_value", 0);
	if (svp != NULL)
		out.value = XS_unpack_UA_Variant(*svp);

	svp = hv_fetchs(hv, "DataValue_sourceTimestamp", 0);
	if (svp != NULL)
		out.sourceTimestamp = XS_unpack_UA_DateTime(*svp);

	svp = hv_fetchs(hv, "DataValue_serverTimestamp", 0);
	if (svp != NULL)
		out.serverTimestamp = XS_unpack_UA_DateTime(*svp);

	svp = hv_fetchs(hv, "DataValue_sourcePicoseconds", 0);
	if (svp != NULL)
		out.sourcePicoseconds = XS_unpack_UA_UInt16(*svp);

	svp = hv_fetchs(hv, "DataValue_serverPicoseconds", 0);
	if (svp != NULL)
		out.serverPicoseconds = XS_unpack_UA_UInt16(*svp);

	svp = hv_fetchs(hv, "DataValue_status", 0);
	if (svp != NULL)
		out.status = XS_unpack_UA_StatusCode(*svp);

	svp = hv_fetchs(hv, "DataValue_hasValue", 0);
	if (svp != NULL)
		out.hasValue = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DataValue_hasStatus", 0);
	if (svp != NULL)
		out.hasStatus = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DataValue_hasSourceTimestamp", 0);
	if (svp != NULL)
		out.hasSourceTimestamp = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DataValue_hasServerTimestamp", 0);
	if (svp != NULL)
		out.hasServerTimestamp = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DataValue_hasSourcePicoseconds", 0);
	if (svp != NULL)
		out.hasSourcePicoseconds = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DataValue_hasServerPicoseconds", 0);
	if (svp != NULL)
		out.hasServerPicoseconds = XS_unpack_UA_Boolean(*svp);

	return out;
}

static void
XS_pack_UA_DataValue(SV *out, UA_DataValue in)
{
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_Variant(sv, in.value);
	hv_stores(hv, "DataValue_value", sv);

	sv = newSV(0);
	XS_pack_UA_DateTime(sv, in.sourceTimestamp);
	hv_stores(hv, "DataValue_sourceTimestamp", sv);

	sv = newSV(0);
	XS_pack_UA_DateTime(sv, in.serverTimestamp);
	hv_stores(hv, "DataValue_serverTimestamp", sv);

	sv = newSV(0);
	XS_pack_UA_UInt16(sv, in.sourcePicoseconds);
	hv_stores(hv, "DataValue_sourcePicoseconds", sv);

	sv = newSV(0);
	XS_pack_UA_UInt16(sv, in.serverPicoseconds);
	hv_stores(hv, "DataValue_serverPicoseconds", sv);

	sv = newSV(0);
	XS_pack_UA_StatusCode(sv, in.status);
	hv_stores(hv, "DataValue_status", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.hasValue);
	hv_stores(hv, "DataValue_hasValue", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.hasStatus);
	hv_stores(hv, "DataValue_hasStatus", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.hasSourceTimestamp);
	hv_stores(hv, "DataValue_hasSourceTimestamp", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.hasServerTimestamp);
	hv_stores(hv, "DataValue_hasServerTimestamp", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.hasSourcePicoseconds);
	hv_stores(hv, "DataValue_hasSourcePicoseconds", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.hasServerPicoseconds);
	hv_stores(hv, "DataValue_hasServerPicoseconds", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

/* Magic callback for UA_Server_run() will change the C variable. */
static int
server_run_mgset(SV* sv, MAGIC* mg)
{
	volatile UA_Boolean		*running;

	DPRINTF("sv %p, mg %p, ptr %p", sv, mg, mg->mg_ptr);
	running = (void *)mg->mg_ptr;
	*running = (bool)SvTRUE(sv);
	return 0;
}

static MGVTBL server_run_mgvtbl = { 0, server_run_mgset, 0, 0, 0, 0, 0, 0 };

/* Open62541 C callback handling */

typedef struct {
	SV *			pcc_callback;
	SV *			pcc_client;
	SV *			pcc_data;
}				PerlClientCallback;

static PerlClientCallback*
prepareClientCallback(SV *callback, SV *client, SV *data)
{
	PerlClientCallback *pcc;

	if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
		croak("callback is not a CODE reference");

	pcc = malloc(sizeof(PerlClientCallback));
	if (pcc == NULL)
		croak("malloc");

	pcc->pcc_callback = callback;
	pcc->pcc_client = client;
	pcc->pcc_data = data;

	SvREFCNT_inc(callback);
	SvREFCNT_inc(client);
	SvREFCNT_inc(data);

	return pcc;
}

static void
clientCallbackPerl(UA_Client *client, void *userdata, UA_UInt32 requestId,
    SV *response) {
	PerlClientCallback *pcc = (PerlClientCallback*) userdata;
	SV * callback = pcc->pcc_callback;
	SV * cl = pcc->pcc_client;
	SV * data = pcc->pcc_data;

	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	EXTEND(SP, 4);
	PUSHs(cl);
	PUSHs(data);
	mPUSHu(requestId);
	mPUSHs(response);
	PUTBACK;

	call_sv(callback, G_DISCARD);

	FREETMPS;
	LEAVE;

	SvREFCNT_dec(callback);
	SvREFCNT_dec(cl);
	SvREFCNT_dec(data);

	free(pcc);
}

static void
clientAsyncServiceCallbackPerl(UA_Client *client, void *userdata,
    UA_UInt32 requestId, void *response)
{
	SV *sv;

	sv = newSV(0);
	if (response != NULL)
		XS_pack_UA_StatusCode(sv, *(UA_StatusCode *)response);

	clientCallbackPerl(client, userdata, requestId, sv);
}

static void
clientAsyncBrowseCallbackPerl(UA_Client *client, void *userdata,
    UA_UInt32 requestId, UA_BrowseResponse *response)
{
	SV *sv;

	sv = newSV(0);
	if (response != NULL)
		XS_pack_UA_BrowseResponse(sv, *response);

	clientCallbackPerl(client, userdata, requestId, sv);
}

/*#########################################################################*/
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541

PROTOTYPES: DISABLE

INCLUDE: Open62541-types.xsh

UA_Boolean
TRUE()
    CODE:
	RETVAL = UA_TRUE;
    OUTPUT:
	RETVAL

UA_Boolean
FALSE()
    CODE:
	RETVAL = UA_FALSE;
    OUTPUT:
	RETVAL

UA_SByte
SBYTE_MIN()
    CODE:
	RETVAL = UA_SBYTE_MIN;
    OUTPUT:
	RETVAL

UA_SByte
SBYTE_MAX()
    CODE:
	RETVAL = UA_SBYTE_MAX;
    OUTPUT:
	RETVAL

UA_Byte
BYTE_MIN()
    CODE:
	RETVAL = UA_BYTE_MIN;
    OUTPUT:
	RETVAL

UA_Byte
BYTE_MAX()
    CODE:
	RETVAL = UA_BYTE_MAX;
    OUTPUT:
	RETVAL

UA_Int16
INT16_MIN()
    CODE:
	RETVAL = UA_INT16_MIN;
    OUTPUT:
	RETVAL

UA_Int16
INT16_MAX()
    CODE:
	RETVAL = UA_INT16_MAX;
    OUTPUT:
	RETVAL

UA_UInt16
UINT16_MIN()
    CODE:
	RETVAL = UA_UINT16_MIN;
    OUTPUT:
	RETVAL

UA_UInt16
UINT16_MAX()
    CODE:
	RETVAL = UA_UINT16_MAX;
    OUTPUT:
	RETVAL

UA_Int32
INT32_MIN()
    CODE:
	RETVAL = UA_INT32_MIN;
    OUTPUT:
	RETVAL

UA_Int32
INT32_MAX()
    CODE:
	RETVAL = UA_INT32_MAX;
    OUTPUT:
	RETVAL

UA_UInt32
UINT32_MIN()
    CODE:
	RETVAL = UA_UINT32_MIN;
    OUTPUT:
	RETVAL

UA_UInt32
UINT32_MAX()
    CODE:
	RETVAL = UA_UINT32_MAX;
    OUTPUT:
	RETVAL

UA_Int64
INT64_MIN()
    CODE:
	RETVAL = UA_INT64_MIN;
    OUTPUT:
	RETVAL

UA_Int64
INT64_MAX()
    CODE:
	RETVAL = UA_INT64_MAX;
    OUTPUT:
	RETVAL

UA_UInt64
UINT64_MIN()
    CODE:
	RETVAL = UA_UINT64_MIN;
    OUTPUT:
	RETVAL

UA_UInt64
UINT64_MAX()
    CODE:
	RETVAL = UA_UINT64_MAX;
    OUTPUT:
	RETVAL

# 6.1.12 StatusCode, statuscodes.c, unknown just for testing

UA_StatusCode
STATUSCODE_UNKNOWN()
    CODE:
	RETVAL = 0xffffffff;
    OUTPUT:
	RETVAL

# 6.1.18 NodeId, types.h

OPCUA_Open62541_NodeIdType
NODEIDTYPE_NUMERIC()
    CODE:
	RETVAL = UA_NODEIDTYPE_NUMERIC;
    OUTPUT:
	RETVAL

OPCUA_Open62541_NodeIdType
NODEIDTYPE_STRING()
    CODE:
	RETVAL = UA_NODEIDTYPE_STRING;
    OUTPUT:
	RETVAL

OPCUA_Open62541_NodeIdType
NODEIDTYPE_GUID()
    CODE:
	RETVAL = UA_NODEIDTYPE_GUID;
    OUTPUT:
	RETVAL

OPCUA_Open62541_NodeIdType
NODEIDTYPE_BYTESTRING()
    CODE:
	RETVAL = UA_NODEIDTYPE_BYTESTRING;
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

INCLUDE: Open62541-accesslevelmask.xsh

# 6.5.49 BrowseResultMask, types_generated.h

OPCUA_Open62541_BrowseResultMask
BROWSERESULTMASK_NONE()
    CODE:
	RETVAL = UA_BROWSERESULTMASK_NONE;
    OUTPUT:
	RETVAL

OPCUA_Open62541_BrowseResultMask
BROWSERESULTMASK_REFERENCETYPEID()
    CODE:
	RETVAL = UA_BROWSERESULTMASK_REFERENCETYPEID;
    OUTPUT:
	RETVAL

OPCUA_Open62541_BrowseResultMask
BROWSERESULTMASK_ISFORWARD()
    CODE:
	RETVAL = UA_BROWSERESULTMASK_ISFORWARD;
    OUTPUT:
	RETVAL

OPCUA_Open62541_BrowseResultMask
BROWSERESULTMASK_NODECLASS()
    CODE:
	RETVAL = UA_BROWSERESULTMASK_NODECLASS;
    OUTPUT:
	RETVAL

OPCUA_Open62541_BrowseResultMask
BROWSERESULTMASK_BROWSENAME()
    CODE:
	RETVAL = UA_BROWSERESULTMASK_BROWSENAME;
    OUTPUT:
	RETVAL

OPCUA_Open62541_BrowseResultMask
BROWSERESULTMASK_DISPLAYNAME()
    CODE:
	RETVAL = UA_BROWSERESULTMASK_DISPLAYNAME;
    OUTPUT:
	RETVAL

OPCUA_Open62541_BrowseResultMask
BROWSERESULTMASK_TYPEDEFINITION()
    CODE:
	RETVAL = UA_BROWSERESULTMASK_TYPEDEFINITION;
    OUTPUT:
	RETVAL

OPCUA_Open62541_BrowseResultMask
BROWSERESULTMASK_ALL()
    CODE:
	RETVAL = UA_BROWSERESULTMASK_ALL;
    OUTPUT:
	RETVAL

OPCUA_Open62541_BrowseResultMask
BROWSERESULTMASK_REFERENCETYPEINFO()
    CODE:
	RETVAL = UA_BROWSERESULTMASK_REFERENCETYPEINFO;
    OUTPUT:
	RETVAL

OPCUA_Open62541_BrowseResultMask
BROWSERESULTMASK_TARGETINFO()
    CODE:
	RETVAL = UA_BROWSERESULTMASK_TARGETINFO;
    OUTPUT:
	RETVAL

#############################################################################
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::UInt32	PREFIX = UA_UInt32_

# 6.1.18 UInt32, types.h
# pointer needed for optional function arguments

void
UA_UInt32_DESTROY(uint32)
	OPCUA_Open62541_UInt32		uint32
    CODE:
	DPRINTF("uint32 %p", uint32);
	UA_UInt32_delete(uint32);

#############################################################################
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::NodeId	PREFIX = UA_NodeId_

# 6.1.18 NodeId, types_generated_handling.h
# pointer needed for optional function arguments

void
UA_NodeId_DESTROY(nodeid)
	OPCUA_Open62541_NodeId		nodeid
    CODE:
	DPRINTF("nodeid %p", nodeid);
	UA_NodeId_delete(nodeid);

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
		croak("%s: UA_Variant_new", __func__);
	DPRINTF("variant %p", RETVAL);
    OUTPUT:
	RETVAL

void
UA_Variant_DESTROY(variant)
	OPCUA_Open62541_Variant		variant
    CODE:
	DPRINTF("variant %p", variant);
	UA_Variant_delete(variant);

UA_Boolean
UA_Variant_isEmpty(variant)
	OPCUA_Open62541_Variant		variant

UA_Boolean
UA_Variant_isScalar(variant)
	OPCUA_Open62541_Variant		variant

UA_Boolean
UA_Variant_hasScalarType(variant, type)
	OPCUA_Open62541_Variant		variant
	OPCUA_Open62541_DataType	type

UA_Boolean
UA_Variant_hasArrayType(variant, type)
	OPCUA_Open62541_Variant		variant
	OPCUA_Open62541_DataType	type

void
UA_Variant_setScalar(variant, sv, type)
	OPCUA_Open62541_Variant		variant
	SV *				sv
	OPCUA_Open62541_DataType	type
    CODE:
	OPCUA_Open62541_Variant_setScalar(variant, sv, type);

UA_UInt16
UA_Variant_getType(variant)
	OPCUA_Open62541_Variant		variant
    CODE:
	if (UA_Variant_isEmpty(variant))
		XSRETURN_UNDEF;
	RETVAL = variant->type->typeIndex;
    OUTPUT:
	RETVAL

SV *
UA_Variant_getScalar(variant)
	OPCUA_Open62541_Variant		variant
    CODE:
	if (UA_Variant_isEmpty(variant))
		XSRETURN_UNDEF;
	if (!UA_Variant_isScalar(variant))
		XSRETURN_UNDEF;
	RETVAL = newSV(0);
	OPCUA_Open62541_Variant_getScalar(variant, RETVAL);
    OUTPUT:
	RETVAL

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

UA_StatusCode
UA_Server_run(server, running)
	OPCUA_Open62541_Server		server
	UA_Boolean			&running
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

UA_StatusCode
UA_Server_run_startup(server)
	OPCUA_Open62541_Server		server

UA_UInt16
UA_Server_run_iterate(server, waitInternal)
	OPCUA_Open62541_Server		server
	UA_Boolean			waitInternal

UA_StatusCode
UA_Server_run_shutdown(server)
	OPCUA_Open62541_Server		server

UA_StatusCode
UA_Server_addVariableNode(server, requestedNewNodeId, parentNodeId, referenceTypeId, browseName, typeDefinition, attr, nodeContext, outNewNodeId)
	OPCUA_Open62541_Server		server
	UA_NodeId			requestedNewNodeId
	UA_NodeId			parentNodeId
	UA_NodeId			referenceTypeId
	UA_QualifiedName		browseName
	UA_NodeId			typeDefinition
	UA_VariableAttributes		attr
	void *				nodeContext
	OPCUA_Open62541_NodeId		outNewNodeId

#############################################################################
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::ServerConfig	PREFIX = UA_ServerConfig_

void
UA_ServerConfig_DESTROY(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	DPRINTF("config %p", config->svc_serverconfig);
	SvREFCNT_dec(config->svc_server);
	free(config);

UA_StatusCode
UA_ServerConfig_setDefault(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	DPRINTF("config %p", config->svc_serverconfig);
	RETVAL = UA_ServerConfig_setDefault(config->svc_serverconfig);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_ServerConfig_setMinimal(config, portNumber, certificate)
	OPCUA_Open62541_ServerConfig	config
	UA_UInt16			portNumber
	UA_ByteString			certificate;
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
	UA_String			customHostname
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

UA_StatusCode
UA_Client_connect(client, endpointUrl)
	OPCUA_Open62541_Client		client
	char *				endpointUrl

UA_StatusCode
UA_Client_connect_async(client, endpointUrl, callback, data)
	OPCUA_Open62541_Client		client
	char *				endpointUrl
	SV *				callback
	SV *				data
    CODE:
	if (!SvOK(callback)) {
		/* ignore callback and data if no callback is defined */
		RETVAL = UA_Client_connect_async(client, endpointUrl, NULL,
		    NULL);
	} else {
		RETVAL = UA_Client_connect_async(client, endpointUrl,
		    clientAsyncServiceCallbackPerl,
		    prepareClientCallback(callback, ST(0), data));
	}
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_run_iterate(client, timeout)
	OPCUA_Open62541_Client		client
	UA_UInt16			timeout

UA_StatusCode
UA_Client_disconnect(client)
	OPCUA_Open62541_Client		client

OPCUA_Open62541_ClientState
UA_Client_getState(client)
	OPCUA_Open62541_Client		client

UA_StatusCode
UA_Client_sendAsyncBrowseRequest(client, request, callback, data, reqId)
	OPCUA_Open62541_Client		client
	UA_BrowseRequest		request
	SV *				callback
	SV *				data
	OPCUA_Open62541_UInt32		reqId
    CODE:
	RETVAL = UA_Client_sendAsyncBrowseRequest(client, &request,
	    clientAsyncBrowseCallbackPerl,
	    prepareClientCallback(callback, ST(0), data), reqId);
	if (reqId && SvROK(ST(4)) && SvTYPE(SvRV(ST(4))) < SVt_PVAV)
		XS_pack_UA_UInt32(SvRV(ST(4)), *reqId);
    OUTPUT:
	RETVAL

#############################################################################
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::ClientConfig	PREFIX = UA_ClientConfig_

void
UA_ClientConfig_DESTROY(config)
	OPCUA_Open62541_ClientConfig	config
    CODE:
	DPRINTF("config %p", config->clc_clientconfig);
	SvREFCNT_dec(config->clc_client);
	free(config);

UA_StatusCode
UA_ClientConfig_setDefault(config)
	OPCUA_Open62541_ClientConfig	config
    CODE:
	DPRINTF("config %p", config->clc_clientconfig);
	RETVAL = UA_ClientConfig_setDefault(config->clc_clientconfig);
    OUTPUT:
	RETVAL
