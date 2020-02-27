static void
unpack_UA_Boolean(SV *sv, void *p)
{
	UA_Boolean *data = p;
	*data = XS_unpack_UA_Boolean(sv);
}
static void
pack_UA_Boolean(SV *sv, void *p)
{
	UA_Boolean *data = p;
	XS_pack_UA_Boolean(sv, *data);
}

static void
unpack_UA_SByte(SV *sv, void *p)
{
	UA_SByte *data = p;
	*data = XS_unpack_UA_SByte(sv);
}
static void
pack_UA_SByte(SV *sv, void *p)
{
	UA_SByte *data = p;
	XS_pack_UA_SByte(sv, *data);
}

static void
unpack_UA_Byte(SV *sv, void *p)
{
	UA_Byte *data = p;
	*data = XS_unpack_UA_Byte(sv);
}
static void
pack_UA_Byte(SV *sv, void *p)
{
	UA_Byte *data = p;
	XS_pack_UA_Byte(sv, *data);
}

static void
unpack_UA_Int16(SV *sv, void *p)
{
	UA_Int16 *data = p;
	*data = XS_unpack_UA_Int16(sv);
}
static void
pack_UA_Int16(SV *sv, void *p)
{
	UA_Int16 *data = p;
	XS_pack_UA_Int16(sv, *data);
}

static void
unpack_UA_UInt16(SV *sv, void *p)
{
	UA_UInt16 *data = p;
	*data = XS_unpack_UA_UInt16(sv);
}
static void
pack_UA_UInt16(SV *sv, void *p)
{
	UA_UInt16 *data = p;
	XS_pack_UA_UInt16(sv, *data);
}

static void
unpack_UA_Int32(SV *sv, void *p)
{
	UA_Int32 *data = p;
	*data = XS_unpack_UA_Int32(sv);
}
static void
pack_UA_Int32(SV *sv, void *p)
{
	UA_Int32 *data = p;
	XS_pack_UA_Int32(sv, *data);
}

static void
unpack_UA_UInt32(SV *sv, void *p)
{
	UA_UInt32 *data = p;
	*data = XS_unpack_UA_UInt32(sv);
}
static void
pack_UA_UInt32(SV *sv, void *p)
{
	UA_UInt32 *data = p;
	XS_pack_UA_UInt32(sv, *data);
}

static void
unpack_UA_Int64(SV *sv, void *p)
{
	UA_Int64 *data = p;
	*data = XS_unpack_UA_Int64(sv);
}
static void
pack_UA_Int64(SV *sv, void *p)
{
	UA_Int64 *data = p;
	XS_pack_UA_Int64(sv, *data);
}

static void
unpack_UA_UInt64(SV *sv, void *p)
{
	UA_UInt64 *data = p;
	*data = XS_unpack_UA_UInt64(sv);
}
static void
pack_UA_UInt64(SV *sv, void *p)
{
	UA_UInt64 *data = p;
	XS_pack_UA_UInt64(sv, *data);
}

static void
unpack_UA_Float(SV *sv, void *p)
{
	UA_Float *data = p;
	*data = XS_unpack_UA_Float(sv);
}
static void
pack_UA_Float(SV *sv, void *p)
{
	UA_Float *data = p;
	XS_pack_UA_Float(sv, *data);
}

static void
unpack_UA_Double(SV *sv, void *p)
{
	UA_Double *data = p;
	*data = XS_unpack_UA_Double(sv);
}
static void
pack_UA_Double(SV *sv, void *p)
{
	UA_Double *data = p;
	XS_pack_UA_Double(sv, *data);
}

static void
unpack_UA_String(SV *sv, void *p)
{
	UA_String *data = p;
	*data = XS_unpack_UA_String(sv);
}
static void
pack_UA_String(SV *sv, void *p)
{
	UA_String *data = p;
	XS_pack_UA_String(sv, *data);
}

static void
unpack_UA_DateTime(SV *sv, void *p)
{
	UA_DateTime *data = p;
	*data = XS_unpack_UA_DateTime(sv);
}
static void
pack_UA_DateTime(SV *sv, void *p)
{
	UA_DateTime *data = p;
	XS_pack_UA_DateTime(sv, *data);
}

static void
unpack_UA_Guid(SV *sv, void *p)
{
	UA_Guid *data = p;
	*data = XS_unpack_UA_Guid(sv);
}
static void
pack_UA_Guid(SV *sv, void *p)
{
	UA_Guid *data = p;
	XS_pack_UA_Guid(sv, *data);
}

static void
unpack_UA_ByteString(SV *sv, void *p)
{
	UA_ByteString *data = p;
	*data = XS_unpack_UA_ByteString(sv);
}
static void
pack_UA_ByteString(SV *sv, void *p)
{
	UA_ByteString *data = p;
	XS_pack_UA_ByteString(sv, *data);
}

static void
unpack_UA_XmlElement(SV *sv, void *p)
{
	UA_XmlElement *data = p;
	*data = XS_unpack_UA_XmlElement(sv);
}
static void
pack_UA_XmlElement(SV *sv, void *p)
{
	UA_XmlElement *data = p;
	XS_pack_UA_XmlElement(sv, *data);
}

static void
unpack_UA_NodeId(SV *sv, void *p)
{
	UA_NodeId *data = p;
	*data = XS_unpack_UA_NodeId(sv);
}
static void
pack_UA_NodeId(SV *sv, void *p)
{
	UA_NodeId *data = p;
	XS_pack_UA_NodeId(sv, *data);
}

static void
unpack_UA_ExpandedNodeId(SV *sv, void *p)
{
	UA_ExpandedNodeId *data = p;
	*data = XS_unpack_UA_ExpandedNodeId(sv);
}
static void
pack_UA_ExpandedNodeId(SV *sv, void *p)
{
	UA_ExpandedNodeId *data = p;
	XS_pack_UA_ExpandedNodeId(sv, *data);
}

static void
unpack_UA_StatusCode(SV *sv, void *p)
{
	UA_StatusCode *data = p;
	*data = XS_unpack_UA_StatusCode(sv);
}
static void
pack_UA_StatusCode(SV *sv, void *p)
{
	UA_StatusCode *data = p;
	XS_pack_UA_StatusCode(sv, *data);
}

static void
unpack_UA_QualifiedName(SV *sv, void *p)
{
	UA_QualifiedName *data = p;
	*data = XS_unpack_UA_QualifiedName(sv);
}
static void
pack_UA_QualifiedName(SV *sv, void *p)
{
	UA_QualifiedName *data = p;
	XS_pack_UA_QualifiedName(sv, *data);
}

static void
unpack_UA_LocalizedText(SV *sv, void *p)
{
	UA_LocalizedText *data = p;
	*data = XS_unpack_UA_LocalizedText(sv);
}
static void
pack_UA_LocalizedText(SV *sv, void *p)
{
	UA_LocalizedText *data = p;
	XS_pack_UA_LocalizedText(sv, *data);
}

static void
unpack_UA_ExtensionObject(SV *sv, void *p)
{
	UA_ExtensionObject *data = p;
	*data = XS_unpack_UA_ExtensionObject(sv);
}
static void
pack_UA_ExtensionObject(SV *sv, void *p)
{
	UA_ExtensionObject *data = p;
	XS_pack_UA_ExtensionObject(sv, *data);
}

static void
unpack_UA_DataValue(SV *sv, void *p)
{
	UA_DataValue *data = p;
	*data = XS_unpack_UA_DataValue(sv);
}
static void
pack_UA_DataValue(SV *sv, void *p)
{
	UA_DataValue *data = p;
	XS_pack_UA_DataValue(sv, *data);
}

static void
unpack_UA_Variant(SV *sv, void *p)
{
	UA_Variant *data = p;
	*data = XS_unpack_UA_Variant(sv);
}
static void
pack_UA_Variant(SV *sv, void *p)
{
	UA_Variant *data = p;
	XS_pack_UA_Variant(sv, *data);
}

static void
unpack_UA_DiagnosticInfo(SV *sv, void *p)
{
	UA_DiagnosticInfo *data = p;
	*data = XS_unpack_UA_DiagnosticInfo(sv);
}
static void
pack_UA_DiagnosticInfo(SV *sv, void *p)
{
	UA_DiagnosticInfo *data = p;
	XS_pack_UA_DiagnosticInfo(sv, *data);
}

static void
unpack_UA_NodeClass(SV *sv, void *p)
{
	UA_NodeClass *data = p;
	*data = XS_unpack_UA_NodeClass(sv);
}
static void
pack_UA_NodeClass(SV *sv, void *p)
{
	UA_NodeClass *data = p;
	XS_pack_UA_NodeClass(sv, *data);
}

static void
unpack_UA_Argument(SV *sv, void *p)
{
	UA_Argument *data = p;
	*data = XS_unpack_UA_Argument(sv);
}
static void
pack_UA_Argument(SV *sv, void *p)
{
	UA_Argument *data = p;
	XS_pack_UA_Argument(sv, *data);
}

static void
unpack_UA_EnumValueType(SV *sv, void *p)
{
	UA_EnumValueType *data = p;
	*data = XS_unpack_UA_EnumValueType(sv);
}
static void
pack_UA_EnumValueType(SV *sv, void *p)
{
	UA_EnumValueType *data = p;
	XS_pack_UA_EnumValueType(sv, *data);
}

static void
unpack_UA_Duration(SV *sv, void *p)
{
	UA_Duration *data = p;
	*data = XS_unpack_UA_Duration(sv);
}
static void
pack_UA_Duration(SV *sv, void *p)
{
	UA_Duration *data = p;
	XS_pack_UA_Duration(sv, *data);
}

static void
unpack_UA_UtcTime(SV *sv, void *p)
{
	UA_UtcTime *data = p;
	*data = XS_unpack_UA_UtcTime(sv);
}
static void
pack_UA_UtcTime(SV *sv, void *p)
{
	UA_UtcTime *data = p;
	XS_pack_UA_UtcTime(sv, *data);
}

static void
unpack_UA_LocaleId(SV *sv, void *p)
{
	UA_LocaleId *data = p;
	*data = XS_unpack_UA_LocaleId(sv);
}
static void
pack_UA_LocaleId(SV *sv, void *p)
{
	UA_LocaleId *data = p;
	XS_pack_UA_LocaleId(sv, *data);
}

static void
unpack_UA_ApplicationType(SV *sv, void *p)
{
	UA_ApplicationType *data = p;
	*data = XS_unpack_UA_ApplicationType(sv);
}
static void
pack_UA_ApplicationType(SV *sv, void *p)
{
	UA_ApplicationType *data = p;
	XS_pack_UA_ApplicationType(sv, *data);
}

static void
unpack_UA_ApplicationDescription(SV *sv, void *p)
{
	UA_ApplicationDescription *data = p;
	*data = XS_unpack_UA_ApplicationDescription(sv);
}
static void
pack_UA_ApplicationDescription(SV *sv, void *p)
{
	UA_ApplicationDescription *data = p;
	XS_pack_UA_ApplicationDescription(sv, *data);
}

static void
unpack_UA_RequestHeader(SV *sv, void *p)
{
	UA_RequestHeader *data = p;
	*data = XS_unpack_UA_RequestHeader(sv);
}
static void
pack_UA_RequestHeader(SV *sv, void *p)
{
	UA_RequestHeader *data = p;
	XS_pack_UA_RequestHeader(sv, *data);
}

static void
unpack_UA_ResponseHeader(SV *sv, void *p)
{
	UA_ResponseHeader *data = p;
	*data = XS_unpack_UA_ResponseHeader(sv);
}
static void
pack_UA_ResponseHeader(SV *sv, void *p)
{
	UA_ResponseHeader *data = p;
	XS_pack_UA_ResponseHeader(sv, *data);
}

static void
unpack_UA_ServiceFault(SV *sv, void *p)
{
	UA_ServiceFault *data = p;
	*data = XS_unpack_UA_ServiceFault(sv);
}
static void
pack_UA_ServiceFault(SV *sv, void *p)
{
	UA_ServiceFault *data = p;
	XS_pack_UA_ServiceFault(sv, *data);
}

static void
unpack_UA_FindServersRequest(SV *sv, void *p)
{
	UA_FindServersRequest *data = p;
	*data = XS_unpack_UA_FindServersRequest(sv);
}
static void
pack_UA_FindServersRequest(SV *sv, void *p)
{
	UA_FindServersRequest *data = p;
	XS_pack_UA_FindServersRequest(sv, *data);
}

static void
unpack_UA_FindServersResponse(SV *sv, void *p)
{
	UA_FindServersResponse *data = p;
	*data = XS_unpack_UA_FindServersResponse(sv);
}
static void
pack_UA_FindServersResponse(SV *sv, void *p)
{
	UA_FindServersResponse *data = p;
	XS_pack_UA_FindServersResponse(sv, *data);
}

static void
unpack_UA_ServerOnNetwork(SV *sv, void *p)
{
	UA_ServerOnNetwork *data = p;
	*data = XS_unpack_UA_ServerOnNetwork(sv);
}
static void
pack_UA_ServerOnNetwork(SV *sv, void *p)
{
	UA_ServerOnNetwork *data = p;
	XS_pack_UA_ServerOnNetwork(sv, *data);
}

static void
unpack_UA_FindServersOnNetworkRequest(SV *sv, void *p)
{
	UA_FindServersOnNetworkRequest *data = p;
	*data = XS_unpack_UA_FindServersOnNetworkRequest(sv);
}
static void
pack_UA_FindServersOnNetworkRequest(SV *sv, void *p)
{
	UA_FindServersOnNetworkRequest *data = p;
	XS_pack_UA_FindServersOnNetworkRequest(sv, *data);
}

static void
unpack_UA_FindServersOnNetworkResponse(SV *sv, void *p)
{
	UA_FindServersOnNetworkResponse *data = p;
	*data = XS_unpack_UA_FindServersOnNetworkResponse(sv);
}
static void
pack_UA_FindServersOnNetworkResponse(SV *sv, void *p)
{
	UA_FindServersOnNetworkResponse *data = p;
	XS_pack_UA_FindServersOnNetworkResponse(sv, *data);
}

static void
unpack_UA_MessageSecurityMode(SV *sv, void *p)
{
	UA_MessageSecurityMode *data = p;
	*data = XS_unpack_UA_MessageSecurityMode(sv);
}
static void
pack_UA_MessageSecurityMode(SV *sv, void *p)
{
	UA_MessageSecurityMode *data = p;
	XS_pack_UA_MessageSecurityMode(sv, *data);
}

static void
unpack_UA_UserTokenType(SV *sv, void *p)
{
	UA_UserTokenType *data = p;
	*data = XS_unpack_UA_UserTokenType(sv);
}
static void
pack_UA_UserTokenType(SV *sv, void *p)
{
	UA_UserTokenType *data = p;
	XS_pack_UA_UserTokenType(sv, *data);
}

static void
unpack_UA_UserTokenPolicy(SV *sv, void *p)
{
	UA_UserTokenPolicy *data = p;
	*data = XS_unpack_UA_UserTokenPolicy(sv);
}
static void
pack_UA_UserTokenPolicy(SV *sv, void *p)
{
	UA_UserTokenPolicy *data = p;
	XS_pack_UA_UserTokenPolicy(sv, *data);
}

static void
unpack_UA_EndpointDescription(SV *sv, void *p)
{
	UA_EndpointDescription *data = p;
	*data = XS_unpack_UA_EndpointDescription(sv);
}
static void
pack_UA_EndpointDescription(SV *sv, void *p)
{
	UA_EndpointDescription *data = p;
	XS_pack_UA_EndpointDescription(sv, *data);
}

static void
unpack_UA_GetEndpointsRequest(SV *sv, void *p)
{
	UA_GetEndpointsRequest *data = p;
	*data = XS_unpack_UA_GetEndpointsRequest(sv);
}
static void
pack_UA_GetEndpointsRequest(SV *sv, void *p)
{
	UA_GetEndpointsRequest *data = p;
	XS_pack_UA_GetEndpointsRequest(sv, *data);
}

static void
unpack_UA_GetEndpointsResponse(SV *sv, void *p)
{
	UA_GetEndpointsResponse *data = p;
	*data = XS_unpack_UA_GetEndpointsResponse(sv);
}
static void
pack_UA_GetEndpointsResponse(SV *sv, void *p)
{
	UA_GetEndpointsResponse *data = p;
	XS_pack_UA_GetEndpointsResponse(sv, *data);
}

static void
unpack_UA_RegisteredServer(SV *sv, void *p)
{
	UA_RegisteredServer *data = p;
	*data = XS_unpack_UA_RegisteredServer(sv);
}
static void
pack_UA_RegisteredServer(SV *sv, void *p)
{
	UA_RegisteredServer *data = p;
	XS_pack_UA_RegisteredServer(sv, *data);
}

static void
unpack_UA_RegisterServerRequest(SV *sv, void *p)
{
	UA_RegisterServerRequest *data = p;
	*data = XS_unpack_UA_RegisterServerRequest(sv);
}
static void
pack_UA_RegisterServerRequest(SV *sv, void *p)
{
	UA_RegisterServerRequest *data = p;
	XS_pack_UA_RegisterServerRequest(sv, *data);
}

static void
unpack_UA_RegisterServerResponse(SV *sv, void *p)
{
	UA_RegisterServerResponse *data = p;
	*data = XS_unpack_UA_RegisterServerResponse(sv);
}
static void
pack_UA_RegisterServerResponse(SV *sv, void *p)
{
	UA_RegisterServerResponse *data = p;
	XS_pack_UA_RegisterServerResponse(sv, *data);
}

static void
unpack_UA_DiscoveryConfiguration(SV *sv, void *p)
{
	UA_DiscoveryConfiguration *data = p;
	*data = XS_unpack_UA_DiscoveryConfiguration(sv);
}
static void
pack_UA_DiscoveryConfiguration(SV *sv, void *p)
{
	UA_DiscoveryConfiguration *data = p;
	XS_pack_UA_DiscoveryConfiguration(sv, *data);
}

static void
unpack_UA_MdnsDiscoveryConfiguration(SV *sv, void *p)
{
	UA_MdnsDiscoveryConfiguration *data = p;
	*data = XS_unpack_UA_MdnsDiscoveryConfiguration(sv);
}
static void
pack_UA_MdnsDiscoveryConfiguration(SV *sv, void *p)
{
	UA_MdnsDiscoveryConfiguration *data = p;
	XS_pack_UA_MdnsDiscoveryConfiguration(sv, *data);
}

static void
unpack_UA_RegisterServer2Request(SV *sv, void *p)
{
	UA_RegisterServer2Request *data = p;
	*data = XS_unpack_UA_RegisterServer2Request(sv);
}
static void
pack_UA_RegisterServer2Request(SV *sv, void *p)
{
	UA_RegisterServer2Request *data = p;
	XS_pack_UA_RegisterServer2Request(sv, *data);
}

static void
unpack_UA_RegisterServer2Response(SV *sv, void *p)
{
	UA_RegisterServer2Response *data = p;
	*data = XS_unpack_UA_RegisterServer2Response(sv);
}
static void
pack_UA_RegisterServer2Response(SV *sv, void *p)
{
	UA_RegisterServer2Response *data = p;
	XS_pack_UA_RegisterServer2Response(sv, *data);
}

static void
unpack_UA_SecurityTokenRequestType(SV *sv, void *p)
{
	UA_SecurityTokenRequestType *data = p;
	*data = XS_unpack_UA_SecurityTokenRequestType(sv);
}
static void
pack_UA_SecurityTokenRequestType(SV *sv, void *p)
{
	UA_SecurityTokenRequestType *data = p;
	XS_pack_UA_SecurityTokenRequestType(sv, *data);
}

static void
unpack_UA_ChannelSecurityToken(SV *sv, void *p)
{
	UA_ChannelSecurityToken *data = p;
	*data = XS_unpack_UA_ChannelSecurityToken(sv);
}
static void
pack_UA_ChannelSecurityToken(SV *sv, void *p)
{
	UA_ChannelSecurityToken *data = p;
	XS_pack_UA_ChannelSecurityToken(sv, *data);
}

static void
unpack_UA_OpenSecureChannelRequest(SV *sv, void *p)
{
	UA_OpenSecureChannelRequest *data = p;
	*data = XS_unpack_UA_OpenSecureChannelRequest(sv);
}
static void
pack_UA_OpenSecureChannelRequest(SV *sv, void *p)
{
	UA_OpenSecureChannelRequest *data = p;
	XS_pack_UA_OpenSecureChannelRequest(sv, *data);
}

static void
unpack_UA_OpenSecureChannelResponse(SV *sv, void *p)
{
	UA_OpenSecureChannelResponse *data = p;
	*data = XS_unpack_UA_OpenSecureChannelResponse(sv);
}
static void
pack_UA_OpenSecureChannelResponse(SV *sv, void *p)
{
	UA_OpenSecureChannelResponse *data = p;
	XS_pack_UA_OpenSecureChannelResponse(sv, *data);
}

static void
unpack_UA_CloseSecureChannelRequest(SV *sv, void *p)
{
	UA_CloseSecureChannelRequest *data = p;
	*data = XS_unpack_UA_CloseSecureChannelRequest(sv);
}
static void
pack_UA_CloseSecureChannelRequest(SV *sv, void *p)
{
	UA_CloseSecureChannelRequest *data = p;
	XS_pack_UA_CloseSecureChannelRequest(sv, *data);
}

static void
unpack_UA_CloseSecureChannelResponse(SV *sv, void *p)
{
	UA_CloseSecureChannelResponse *data = p;
	*data = XS_unpack_UA_CloseSecureChannelResponse(sv);
}
static void
pack_UA_CloseSecureChannelResponse(SV *sv, void *p)
{
	UA_CloseSecureChannelResponse *data = p;
	XS_pack_UA_CloseSecureChannelResponse(sv, *data);
}

static void
unpack_UA_SignedSoftwareCertificate(SV *sv, void *p)
{
	UA_SignedSoftwareCertificate *data = p;
	*data = XS_unpack_UA_SignedSoftwareCertificate(sv);
}
static void
pack_UA_SignedSoftwareCertificate(SV *sv, void *p)
{
	UA_SignedSoftwareCertificate *data = p;
	XS_pack_UA_SignedSoftwareCertificate(sv, *data);
}

static void
unpack_UA_SignatureData(SV *sv, void *p)
{
	UA_SignatureData *data = p;
	*data = XS_unpack_UA_SignatureData(sv);
}
static void
pack_UA_SignatureData(SV *sv, void *p)
{
	UA_SignatureData *data = p;
	XS_pack_UA_SignatureData(sv, *data);
}

static void
unpack_UA_CreateSessionRequest(SV *sv, void *p)
{
	UA_CreateSessionRequest *data = p;
	*data = XS_unpack_UA_CreateSessionRequest(sv);
}
static void
pack_UA_CreateSessionRequest(SV *sv, void *p)
{
	UA_CreateSessionRequest *data = p;
	XS_pack_UA_CreateSessionRequest(sv, *data);
}

static void
unpack_UA_CreateSessionResponse(SV *sv, void *p)
{
	UA_CreateSessionResponse *data = p;
	*data = XS_unpack_UA_CreateSessionResponse(sv);
}
static void
pack_UA_CreateSessionResponse(SV *sv, void *p)
{
	UA_CreateSessionResponse *data = p;
	XS_pack_UA_CreateSessionResponse(sv, *data);
}

static void
unpack_UA_UserIdentityToken(SV *sv, void *p)
{
	UA_UserIdentityToken *data = p;
	*data = XS_unpack_UA_UserIdentityToken(sv);
}
static void
pack_UA_UserIdentityToken(SV *sv, void *p)
{
	UA_UserIdentityToken *data = p;
	XS_pack_UA_UserIdentityToken(sv, *data);
}

static void
unpack_UA_AnonymousIdentityToken(SV *sv, void *p)
{
	UA_AnonymousIdentityToken *data = p;
	*data = XS_unpack_UA_AnonymousIdentityToken(sv);
}
static void
pack_UA_AnonymousIdentityToken(SV *sv, void *p)
{
	UA_AnonymousIdentityToken *data = p;
	XS_pack_UA_AnonymousIdentityToken(sv, *data);
}

static void
unpack_UA_UserNameIdentityToken(SV *sv, void *p)
{
	UA_UserNameIdentityToken *data = p;
	*data = XS_unpack_UA_UserNameIdentityToken(sv);
}
static void
pack_UA_UserNameIdentityToken(SV *sv, void *p)
{
	UA_UserNameIdentityToken *data = p;
	XS_pack_UA_UserNameIdentityToken(sv, *data);
}

static void
unpack_UA_X509IdentityToken(SV *sv, void *p)
{
	UA_X509IdentityToken *data = p;
	*data = XS_unpack_UA_X509IdentityToken(sv);
}
static void
pack_UA_X509IdentityToken(SV *sv, void *p)
{
	UA_X509IdentityToken *data = p;
	XS_pack_UA_X509IdentityToken(sv, *data);
}

static void
unpack_UA_IssuedIdentityToken(SV *sv, void *p)
{
	UA_IssuedIdentityToken *data = p;
	*data = XS_unpack_UA_IssuedIdentityToken(sv);
}
static void
pack_UA_IssuedIdentityToken(SV *sv, void *p)
{
	UA_IssuedIdentityToken *data = p;
	XS_pack_UA_IssuedIdentityToken(sv, *data);
}

static void
unpack_UA_ActivateSessionRequest(SV *sv, void *p)
{
	UA_ActivateSessionRequest *data = p;
	*data = XS_unpack_UA_ActivateSessionRequest(sv);
}
static void
pack_UA_ActivateSessionRequest(SV *sv, void *p)
{
	UA_ActivateSessionRequest *data = p;
	XS_pack_UA_ActivateSessionRequest(sv, *data);
}

static void
unpack_UA_ActivateSessionResponse(SV *sv, void *p)
{
	UA_ActivateSessionResponse *data = p;
	*data = XS_unpack_UA_ActivateSessionResponse(sv);
}
static void
pack_UA_ActivateSessionResponse(SV *sv, void *p)
{
	UA_ActivateSessionResponse *data = p;
	XS_pack_UA_ActivateSessionResponse(sv, *data);
}

static void
unpack_UA_CloseSessionRequest(SV *sv, void *p)
{
	UA_CloseSessionRequest *data = p;
	*data = XS_unpack_UA_CloseSessionRequest(sv);
}
static void
pack_UA_CloseSessionRequest(SV *sv, void *p)
{
	UA_CloseSessionRequest *data = p;
	XS_pack_UA_CloseSessionRequest(sv, *data);
}

static void
unpack_UA_CloseSessionResponse(SV *sv, void *p)
{
	UA_CloseSessionResponse *data = p;
	*data = XS_unpack_UA_CloseSessionResponse(sv);
}
static void
pack_UA_CloseSessionResponse(SV *sv, void *p)
{
	UA_CloseSessionResponse *data = p;
	XS_pack_UA_CloseSessionResponse(sv, *data);
}

static void
unpack_UA_NodeAttributesMask(SV *sv, void *p)
{
	UA_NodeAttributesMask *data = p;
	*data = XS_unpack_UA_NodeAttributesMask(sv);
}
static void
pack_UA_NodeAttributesMask(SV *sv, void *p)
{
	UA_NodeAttributesMask *data = p;
	XS_pack_UA_NodeAttributesMask(sv, *data);
}

static void
unpack_UA_NodeAttributes(SV *sv, void *p)
{
	UA_NodeAttributes *data = p;
	*data = XS_unpack_UA_NodeAttributes(sv);
}
static void
pack_UA_NodeAttributes(SV *sv, void *p)
{
	UA_NodeAttributes *data = p;
	XS_pack_UA_NodeAttributes(sv, *data);
}

static void
unpack_UA_ObjectAttributes(SV *sv, void *p)
{
	UA_ObjectAttributes *data = p;
	*data = XS_unpack_UA_ObjectAttributes(sv);
}
static void
pack_UA_ObjectAttributes(SV *sv, void *p)
{
	UA_ObjectAttributes *data = p;
	XS_pack_UA_ObjectAttributes(sv, *data);
}

static void
unpack_UA_VariableAttributes(SV *sv, void *p)
{
	UA_VariableAttributes *data = p;
	*data = XS_unpack_UA_VariableAttributes(sv);
}
static void
pack_UA_VariableAttributes(SV *sv, void *p)
{
	UA_VariableAttributes *data = p;
	XS_pack_UA_VariableAttributes(sv, *data);
}

static void
unpack_UA_MethodAttributes(SV *sv, void *p)
{
	UA_MethodAttributes *data = p;
	*data = XS_unpack_UA_MethodAttributes(sv);
}
static void
pack_UA_MethodAttributes(SV *sv, void *p)
{
	UA_MethodAttributes *data = p;
	XS_pack_UA_MethodAttributes(sv, *data);
}

static void
unpack_UA_ObjectTypeAttributes(SV *sv, void *p)
{
	UA_ObjectTypeAttributes *data = p;
	*data = XS_unpack_UA_ObjectTypeAttributes(sv);
}
static void
pack_UA_ObjectTypeAttributes(SV *sv, void *p)
{
	UA_ObjectTypeAttributes *data = p;
	XS_pack_UA_ObjectTypeAttributes(sv, *data);
}

static void
unpack_UA_VariableTypeAttributes(SV *sv, void *p)
{
	UA_VariableTypeAttributes *data = p;
	*data = XS_unpack_UA_VariableTypeAttributes(sv);
}
static void
pack_UA_VariableTypeAttributes(SV *sv, void *p)
{
	UA_VariableTypeAttributes *data = p;
	XS_pack_UA_VariableTypeAttributes(sv, *data);
}

static void
unpack_UA_ReferenceTypeAttributes(SV *sv, void *p)
{
	UA_ReferenceTypeAttributes *data = p;
	*data = XS_unpack_UA_ReferenceTypeAttributes(sv);
}
static void
pack_UA_ReferenceTypeAttributes(SV *sv, void *p)
{
	UA_ReferenceTypeAttributes *data = p;
	XS_pack_UA_ReferenceTypeAttributes(sv, *data);
}

static void
unpack_UA_DataTypeAttributes(SV *sv, void *p)
{
	UA_DataTypeAttributes *data = p;
	*data = XS_unpack_UA_DataTypeAttributes(sv);
}
static void
pack_UA_DataTypeAttributes(SV *sv, void *p)
{
	UA_DataTypeAttributes *data = p;
	XS_pack_UA_DataTypeAttributes(sv, *data);
}

static void
unpack_UA_ViewAttributes(SV *sv, void *p)
{
	UA_ViewAttributes *data = p;
	*data = XS_unpack_UA_ViewAttributes(sv);
}
static void
pack_UA_ViewAttributes(SV *sv, void *p)
{
	UA_ViewAttributes *data = p;
	XS_pack_UA_ViewAttributes(sv, *data);
}

static void
unpack_UA_AddNodesItem(SV *sv, void *p)
{
	UA_AddNodesItem *data = p;
	*data = XS_unpack_UA_AddNodesItem(sv);
}
static void
pack_UA_AddNodesItem(SV *sv, void *p)
{
	UA_AddNodesItem *data = p;
	XS_pack_UA_AddNodesItem(sv, *data);
}

static void
unpack_UA_AddNodesResult(SV *sv, void *p)
{
	UA_AddNodesResult *data = p;
	*data = XS_unpack_UA_AddNodesResult(sv);
}
static void
pack_UA_AddNodesResult(SV *sv, void *p)
{
	UA_AddNodesResult *data = p;
	XS_pack_UA_AddNodesResult(sv, *data);
}

static void
unpack_UA_AddNodesRequest(SV *sv, void *p)
{
	UA_AddNodesRequest *data = p;
	*data = XS_unpack_UA_AddNodesRequest(sv);
}
static void
pack_UA_AddNodesRequest(SV *sv, void *p)
{
	UA_AddNodesRequest *data = p;
	XS_pack_UA_AddNodesRequest(sv, *data);
}

static void
unpack_UA_AddNodesResponse(SV *sv, void *p)
{
	UA_AddNodesResponse *data = p;
	*data = XS_unpack_UA_AddNodesResponse(sv);
}
static void
pack_UA_AddNodesResponse(SV *sv, void *p)
{
	UA_AddNodesResponse *data = p;
	XS_pack_UA_AddNodesResponse(sv, *data);
}

static void
unpack_UA_AddReferencesItem(SV *sv, void *p)
{
	UA_AddReferencesItem *data = p;
	*data = XS_unpack_UA_AddReferencesItem(sv);
}
static void
pack_UA_AddReferencesItem(SV *sv, void *p)
{
	UA_AddReferencesItem *data = p;
	XS_pack_UA_AddReferencesItem(sv, *data);
}

static void
unpack_UA_AddReferencesRequest(SV *sv, void *p)
{
	UA_AddReferencesRequest *data = p;
	*data = XS_unpack_UA_AddReferencesRequest(sv);
}
static void
pack_UA_AddReferencesRequest(SV *sv, void *p)
{
	UA_AddReferencesRequest *data = p;
	XS_pack_UA_AddReferencesRequest(sv, *data);
}

static void
unpack_UA_AddReferencesResponse(SV *sv, void *p)
{
	UA_AddReferencesResponse *data = p;
	*data = XS_unpack_UA_AddReferencesResponse(sv);
}
static void
pack_UA_AddReferencesResponse(SV *sv, void *p)
{
	UA_AddReferencesResponse *data = p;
	XS_pack_UA_AddReferencesResponse(sv, *data);
}

static void
unpack_UA_DeleteNodesItem(SV *sv, void *p)
{
	UA_DeleteNodesItem *data = p;
	*data = XS_unpack_UA_DeleteNodesItem(sv);
}
static void
pack_UA_DeleteNodesItem(SV *sv, void *p)
{
	UA_DeleteNodesItem *data = p;
	XS_pack_UA_DeleteNodesItem(sv, *data);
}

static void
unpack_UA_DeleteNodesRequest(SV *sv, void *p)
{
	UA_DeleteNodesRequest *data = p;
	*data = XS_unpack_UA_DeleteNodesRequest(sv);
}
static void
pack_UA_DeleteNodesRequest(SV *sv, void *p)
{
	UA_DeleteNodesRequest *data = p;
	XS_pack_UA_DeleteNodesRequest(sv, *data);
}

static void
unpack_UA_DeleteNodesResponse(SV *sv, void *p)
{
	UA_DeleteNodesResponse *data = p;
	*data = XS_unpack_UA_DeleteNodesResponse(sv);
}
static void
pack_UA_DeleteNodesResponse(SV *sv, void *p)
{
	UA_DeleteNodesResponse *data = p;
	XS_pack_UA_DeleteNodesResponse(sv, *data);
}

static void
unpack_UA_DeleteReferencesItem(SV *sv, void *p)
{
	UA_DeleteReferencesItem *data = p;
	*data = XS_unpack_UA_DeleteReferencesItem(sv);
}
static void
pack_UA_DeleteReferencesItem(SV *sv, void *p)
{
	UA_DeleteReferencesItem *data = p;
	XS_pack_UA_DeleteReferencesItem(sv, *data);
}

static void
unpack_UA_DeleteReferencesRequest(SV *sv, void *p)
{
	UA_DeleteReferencesRequest *data = p;
	*data = XS_unpack_UA_DeleteReferencesRequest(sv);
}
static void
pack_UA_DeleteReferencesRequest(SV *sv, void *p)
{
	UA_DeleteReferencesRequest *data = p;
	XS_pack_UA_DeleteReferencesRequest(sv, *data);
}

static void
unpack_UA_DeleteReferencesResponse(SV *sv, void *p)
{
	UA_DeleteReferencesResponse *data = p;
	*data = XS_unpack_UA_DeleteReferencesResponse(sv);
}
static void
pack_UA_DeleteReferencesResponse(SV *sv, void *p)
{
	UA_DeleteReferencesResponse *data = p;
	XS_pack_UA_DeleteReferencesResponse(sv, *data);
}

static void
unpack_UA_BrowseDirection(SV *sv, void *p)
{
	UA_BrowseDirection *data = p;
	*data = XS_unpack_UA_BrowseDirection(sv);
}
static void
pack_UA_BrowseDirection(SV *sv, void *p)
{
	UA_BrowseDirection *data = p;
	XS_pack_UA_BrowseDirection(sv, *data);
}

static void
unpack_UA_ViewDescription(SV *sv, void *p)
{
	UA_ViewDescription *data = p;
	*data = XS_unpack_UA_ViewDescription(sv);
}
static void
pack_UA_ViewDescription(SV *sv, void *p)
{
	UA_ViewDescription *data = p;
	XS_pack_UA_ViewDescription(sv, *data);
}

static void
unpack_UA_BrowseDescription(SV *sv, void *p)
{
	UA_BrowseDescription *data = p;
	*data = XS_unpack_UA_BrowseDescription(sv);
}
static void
pack_UA_BrowseDescription(SV *sv, void *p)
{
	UA_BrowseDescription *data = p;
	XS_pack_UA_BrowseDescription(sv, *data);
}

static void
unpack_UA_BrowseResultMask(SV *sv, void *p)
{
	UA_BrowseResultMask *data = p;
	*data = XS_unpack_UA_BrowseResultMask(sv);
}
static void
pack_UA_BrowseResultMask(SV *sv, void *p)
{
	UA_BrowseResultMask *data = p;
	XS_pack_UA_BrowseResultMask(sv, *data);
}

static void
unpack_UA_ReferenceDescription(SV *sv, void *p)
{
	UA_ReferenceDescription *data = p;
	*data = XS_unpack_UA_ReferenceDescription(sv);
}
static void
pack_UA_ReferenceDescription(SV *sv, void *p)
{
	UA_ReferenceDescription *data = p;
	XS_pack_UA_ReferenceDescription(sv, *data);
}

static void
unpack_UA_BrowseResult(SV *sv, void *p)
{
	UA_BrowseResult *data = p;
	*data = XS_unpack_UA_BrowseResult(sv);
}
static void
pack_UA_BrowseResult(SV *sv, void *p)
{
	UA_BrowseResult *data = p;
	XS_pack_UA_BrowseResult(sv, *data);
}

static void
unpack_UA_BrowseRequest(SV *sv, void *p)
{
	UA_BrowseRequest *data = p;
	*data = XS_unpack_UA_BrowseRequest(sv);
}
static void
pack_UA_BrowseRequest(SV *sv, void *p)
{
	UA_BrowseRequest *data = p;
	XS_pack_UA_BrowseRequest(sv, *data);
}

static void
unpack_UA_BrowseResponse(SV *sv, void *p)
{
	UA_BrowseResponse *data = p;
	*data = XS_unpack_UA_BrowseResponse(sv);
}
static void
pack_UA_BrowseResponse(SV *sv, void *p)
{
	UA_BrowseResponse *data = p;
	XS_pack_UA_BrowseResponse(sv, *data);
}

static void
unpack_UA_BrowseNextRequest(SV *sv, void *p)
{
	UA_BrowseNextRequest *data = p;
	*data = XS_unpack_UA_BrowseNextRequest(sv);
}
static void
pack_UA_BrowseNextRequest(SV *sv, void *p)
{
	UA_BrowseNextRequest *data = p;
	XS_pack_UA_BrowseNextRequest(sv, *data);
}

static void
unpack_UA_BrowseNextResponse(SV *sv, void *p)
{
	UA_BrowseNextResponse *data = p;
	*data = XS_unpack_UA_BrowseNextResponse(sv);
}
static void
pack_UA_BrowseNextResponse(SV *sv, void *p)
{
	UA_BrowseNextResponse *data = p;
	XS_pack_UA_BrowseNextResponse(sv, *data);
}

static void
unpack_UA_RelativePathElement(SV *sv, void *p)
{
	UA_RelativePathElement *data = p;
	*data = XS_unpack_UA_RelativePathElement(sv);
}
static void
pack_UA_RelativePathElement(SV *sv, void *p)
{
	UA_RelativePathElement *data = p;
	XS_pack_UA_RelativePathElement(sv, *data);
}

static void
unpack_UA_RelativePath(SV *sv, void *p)
{
	UA_RelativePath *data = p;
	*data = XS_unpack_UA_RelativePath(sv);
}
static void
pack_UA_RelativePath(SV *sv, void *p)
{
	UA_RelativePath *data = p;
	XS_pack_UA_RelativePath(sv, *data);
}

static void
unpack_UA_BrowsePath(SV *sv, void *p)
{
	UA_BrowsePath *data = p;
	*data = XS_unpack_UA_BrowsePath(sv);
}
static void
pack_UA_BrowsePath(SV *sv, void *p)
{
	UA_BrowsePath *data = p;
	XS_pack_UA_BrowsePath(sv, *data);
}

static void
unpack_UA_BrowsePathTarget(SV *sv, void *p)
{
	UA_BrowsePathTarget *data = p;
	*data = XS_unpack_UA_BrowsePathTarget(sv);
}
static void
pack_UA_BrowsePathTarget(SV *sv, void *p)
{
	UA_BrowsePathTarget *data = p;
	XS_pack_UA_BrowsePathTarget(sv, *data);
}

static void
unpack_UA_BrowsePathResult(SV *sv, void *p)
{
	UA_BrowsePathResult *data = p;
	*data = XS_unpack_UA_BrowsePathResult(sv);
}
static void
pack_UA_BrowsePathResult(SV *sv, void *p)
{
	UA_BrowsePathResult *data = p;
	XS_pack_UA_BrowsePathResult(sv, *data);
}

static void
unpack_UA_TranslateBrowsePathsToNodeIdsRequest(SV *sv, void *p)
{
	UA_TranslateBrowsePathsToNodeIdsRequest *data = p;
	*data = XS_unpack_UA_TranslateBrowsePathsToNodeIdsRequest(sv);
}
static void
pack_UA_TranslateBrowsePathsToNodeIdsRequest(SV *sv, void *p)
{
	UA_TranslateBrowsePathsToNodeIdsRequest *data = p;
	XS_pack_UA_TranslateBrowsePathsToNodeIdsRequest(sv, *data);
}

static void
unpack_UA_TranslateBrowsePathsToNodeIdsResponse(SV *sv, void *p)
{
	UA_TranslateBrowsePathsToNodeIdsResponse *data = p;
	*data = XS_unpack_UA_TranslateBrowsePathsToNodeIdsResponse(sv);
}
static void
pack_UA_TranslateBrowsePathsToNodeIdsResponse(SV *sv, void *p)
{
	UA_TranslateBrowsePathsToNodeIdsResponse *data = p;
	XS_pack_UA_TranslateBrowsePathsToNodeIdsResponse(sv, *data);
}

static void
unpack_UA_RegisterNodesRequest(SV *sv, void *p)
{
	UA_RegisterNodesRequest *data = p;
	*data = XS_unpack_UA_RegisterNodesRequest(sv);
}
static void
pack_UA_RegisterNodesRequest(SV *sv, void *p)
{
	UA_RegisterNodesRequest *data = p;
	XS_pack_UA_RegisterNodesRequest(sv, *data);
}

static void
unpack_UA_RegisterNodesResponse(SV *sv, void *p)
{
	UA_RegisterNodesResponse *data = p;
	*data = XS_unpack_UA_RegisterNodesResponse(sv);
}
static void
pack_UA_RegisterNodesResponse(SV *sv, void *p)
{
	UA_RegisterNodesResponse *data = p;
	XS_pack_UA_RegisterNodesResponse(sv, *data);
}

static void
unpack_UA_UnregisterNodesRequest(SV *sv, void *p)
{
	UA_UnregisterNodesRequest *data = p;
	*data = XS_unpack_UA_UnregisterNodesRequest(sv);
}
static void
pack_UA_UnregisterNodesRequest(SV *sv, void *p)
{
	UA_UnregisterNodesRequest *data = p;
	XS_pack_UA_UnregisterNodesRequest(sv, *data);
}

static void
unpack_UA_UnregisterNodesResponse(SV *sv, void *p)
{
	UA_UnregisterNodesResponse *data = p;
	*data = XS_unpack_UA_UnregisterNodesResponse(sv);
}
static void
pack_UA_UnregisterNodesResponse(SV *sv, void *p)
{
	UA_UnregisterNodesResponse *data = p;
	XS_pack_UA_UnregisterNodesResponse(sv, *data);
}

static void
unpack_UA_FilterOperator(SV *sv, void *p)
{
	UA_FilterOperator *data = p;
	*data = XS_unpack_UA_FilterOperator(sv);
}
static void
pack_UA_FilterOperator(SV *sv, void *p)
{
	UA_FilterOperator *data = p;
	XS_pack_UA_FilterOperator(sv, *data);
}

static void
unpack_UA_ContentFilterElement(SV *sv, void *p)
{
	UA_ContentFilterElement *data = p;
	*data = XS_unpack_UA_ContentFilterElement(sv);
}
static void
pack_UA_ContentFilterElement(SV *sv, void *p)
{
	UA_ContentFilterElement *data = p;
	XS_pack_UA_ContentFilterElement(sv, *data);
}

static void
unpack_UA_ContentFilter(SV *sv, void *p)
{
	UA_ContentFilter *data = p;
	*data = XS_unpack_UA_ContentFilter(sv);
}
static void
pack_UA_ContentFilter(SV *sv, void *p)
{
	UA_ContentFilter *data = p;
	XS_pack_UA_ContentFilter(sv, *data);
}

static void
unpack_UA_FilterOperand(SV *sv, void *p)
{
	UA_FilterOperand *data = p;
	*data = XS_unpack_UA_FilterOperand(sv);
}
static void
pack_UA_FilterOperand(SV *sv, void *p)
{
	UA_FilterOperand *data = p;
	XS_pack_UA_FilterOperand(sv, *data);
}

static void
unpack_UA_ElementOperand(SV *sv, void *p)
{
	UA_ElementOperand *data = p;
	*data = XS_unpack_UA_ElementOperand(sv);
}
static void
pack_UA_ElementOperand(SV *sv, void *p)
{
	UA_ElementOperand *data = p;
	XS_pack_UA_ElementOperand(sv, *data);
}

static void
unpack_UA_LiteralOperand(SV *sv, void *p)
{
	UA_LiteralOperand *data = p;
	*data = XS_unpack_UA_LiteralOperand(sv);
}
static void
pack_UA_LiteralOperand(SV *sv, void *p)
{
	UA_LiteralOperand *data = p;
	XS_pack_UA_LiteralOperand(sv, *data);
}

static void
unpack_UA_AttributeOperand(SV *sv, void *p)
{
	UA_AttributeOperand *data = p;
	*data = XS_unpack_UA_AttributeOperand(sv);
}
static void
pack_UA_AttributeOperand(SV *sv, void *p)
{
	UA_AttributeOperand *data = p;
	XS_pack_UA_AttributeOperand(sv, *data);
}

static void
unpack_UA_SimpleAttributeOperand(SV *sv, void *p)
{
	UA_SimpleAttributeOperand *data = p;
	*data = XS_unpack_UA_SimpleAttributeOperand(sv);
}
static void
pack_UA_SimpleAttributeOperand(SV *sv, void *p)
{
	UA_SimpleAttributeOperand *data = p;
	XS_pack_UA_SimpleAttributeOperand(sv, *data);
}

static void
unpack_UA_ContentFilterElementResult(SV *sv, void *p)
{
	UA_ContentFilterElementResult *data = p;
	*data = XS_unpack_UA_ContentFilterElementResult(sv);
}
static void
pack_UA_ContentFilterElementResult(SV *sv, void *p)
{
	UA_ContentFilterElementResult *data = p;
	XS_pack_UA_ContentFilterElementResult(sv, *data);
}

static void
unpack_UA_ContentFilterResult(SV *sv, void *p)
{
	UA_ContentFilterResult *data = p;
	*data = XS_unpack_UA_ContentFilterResult(sv);
}
static void
pack_UA_ContentFilterResult(SV *sv, void *p)
{
	UA_ContentFilterResult *data = p;
	XS_pack_UA_ContentFilterResult(sv, *data);
}

static void
unpack_UA_TimestampsToReturn(SV *sv, void *p)
{
	UA_TimestampsToReturn *data = p;
	*data = XS_unpack_UA_TimestampsToReturn(sv);
}
static void
pack_UA_TimestampsToReturn(SV *sv, void *p)
{
	UA_TimestampsToReturn *data = p;
	XS_pack_UA_TimestampsToReturn(sv, *data);
}

static void
unpack_UA_ReadValueId(SV *sv, void *p)
{
	UA_ReadValueId *data = p;
	*data = XS_unpack_UA_ReadValueId(sv);
}
static void
pack_UA_ReadValueId(SV *sv, void *p)
{
	UA_ReadValueId *data = p;
	XS_pack_UA_ReadValueId(sv, *data);
}

static void
unpack_UA_ReadRequest(SV *sv, void *p)
{
	UA_ReadRequest *data = p;
	*data = XS_unpack_UA_ReadRequest(sv);
}
static void
pack_UA_ReadRequest(SV *sv, void *p)
{
	UA_ReadRequest *data = p;
	XS_pack_UA_ReadRequest(sv, *data);
}

static void
unpack_UA_ReadResponse(SV *sv, void *p)
{
	UA_ReadResponse *data = p;
	*data = XS_unpack_UA_ReadResponse(sv);
}
static void
pack_UA_ReadResponse(SV *sv, void *p)
{
	UA_ReadResponse *data = p;
	XS_pack_UA_ReadResponse(sv, *data);
}

static void
unpack_UA_WriteValue(SV *sv, void *p)
{
	UA_WriteValue *data = p;
	*data = XS_unpack_UA_WriteValue(sv);
}
static void
pack_UA_WriteValue(SV *sv, void *p)
{
	UA_WriteValue *data = p;
	XS_pack_UA_WriteValue(sv, *data);
}

static void
unpack_UA_WriteRequest(SV *sv, void *p)
{
	UA_WriteRequest *data = p;
	*data = XS_unpack_UA_WriteRequest(sv);
}
static void
pack_UA_WriteRequest(SV *sv, void *p)
{
	UA_WriteRequest *data = p;
	XS_pack_UA_WriteRequest(sv, *data);
}

static void
unpack_UA_WriteResponse(SV *sv, void *p)
{
	UA_WriteResponse *data = p;
	*data = XS_unpack_UA_WriteResponse(sv);
}
static void
pack_UA_WriteResponse(SV *sv, void *p)
{
	UA_WriteResponse *data = p;
	XS_pack_UA_WriteResponse(sv, *data);
}

static void
unpack_UA_CallMethodRequest(SV *sv, void *p)
{
	UA_CallMethodRequest *data = p;
	*data = XS_unpack_UA_CallMethodRequest(sv);
}
static void
pack_UA_CallMethodRequest(SV *sv, void *p)
{
	UA_CallMethodRequest *data = p;
	XS_pack_UA_CallMethodRequest(sv, *data);
}

static void
unpack_UA_CallMethodResult(SV *sv, void *p)
{
	UA_CallMethodResult *data = p;
	*data = XS_unpack_UA_CallMethodResult(sv);
}
static void
pack_UA_CallMethodResult(SV *sv, void *p)
{
	UA_CallMethodResult *data = p;
	XS_pack_UA_CallMethodResult(sv, *data);
}

static void
unpack_UA_CallRequest(SV *sv, void *p)
{
	UA_CallRequest *data = p;
	*data = XS_unpack_UA_CallRequest(sv);
}
static void
pack_UA_CallRequest(SV *sv, void *p)
{
	UA_CallRequest *data = p;
	XS_pack_UA_CallRequest(sv, *data);
}

static void
unpack_UA_CallResponse(SV *sv, void *p)
{
	UA_CallResponse *data = p;
	*data = XS_unpack_UA_CallResponse(sv);
}
static void
pack_UA_CallResponse(SV *sv, void *p)
{
	UA_CallResponse *data = p;
	XS_pack_UA_CallResponse(sv, *data);
}

static void
unpack_UA_MonitoringMode(SV *sv, void *p)
{
	UA_MonitoringMode *data = p;
	*data = XS_unpack_UA_MonitoringMode(sv);
}
static void
pack_UA_MonitoringMode(SV *sv, void *p)
{
	UA_MonitoringMode *data = p;
	XS_pack_UA_MonitoringMode(sv, *data);
}

static void
unpack_UA_DataChangeTrigger(SV *sv, void *p)
{
	UA_DataChangeTrigger *data = p;
	*data = XS_unpack_UA_DataChangeTrigger(sv);
}
static void
pack_UA_DataChangeTrigger(SV *sv, void *p)
{
	UA_DataChangeTrigger *data = p;
	XS_pack_UA_DataChangeTrigger(sv, *data);
}

static void
unpack_UA_DeadbandType(SV *sv, void *p)
{
	UA_DeadbandType *data = p;
	*data = XS_unpack_UA_DeadbandType(sv);
}
static void
pack_UA_DeadbandType(SV *sv, void *p)
{
	UA_DeadbandType *data = p;
	XS_pack_UA_DeadbandType(sv, *data);
}

static void
unpack_UA_DataChangeFilter(SV *sv, void *p)
{
	UA_DataChangeFilter *data = p;
	*data = XS_unpack_UA_DataChangeFilter(sv);
}
static void
pack_UA_DataChangeFilter(SV *sv, void *p)
{
	UA_DataChangeFilter *data = p;
	XS_pack_UA_DataChangeFilter(sv, *data);
}

static void
unpack_UA_EventFilter(SV *sv, void *p)
{
	UA_EventFilter *data = p;
	*data = XS_unpack_UA_EventFilter(sv);
}
static void
pack_UA_EventFilter(SV *sv, void *p)
{
	UA_EventFilter *data = p;
	XS_pack_UA_EventFilter(sv, *data);
}

static void
unpack_UA_AggregateConfiguration(SV *sv, void *p)
{
	UA_AggregateConfiguration *data = p;
	*data = XS_unpack_UA_AggregateConfiguration(sv);
}
static void
pack_UA_AggregateConfiguration(SV *sv, void *p)
{
	UA_AggregateConfiguration *data = p;
	XS_pack_UA_AggregateConfiguration(sv, *data);
}

static void
unpack_UA_AggregateFilter(SV *sv, void *p)
{
	UA_AggregateFilter *data = p;
	*data = XS_unpack_UA_AggregateFilter(sv);
}
static void
pack_UA_AggregateFilter(SV *sv, void *p)
{
	UA_AggregateFilter *data = p;
	XS_pack_UA_AggregateFilter(sv, *data);
}

static void
unpack_UA_EventFilterResult(SV *sv, void *p)
{
	UA_EventFilterResult *data = p;
	*data = XS_unpack_UA_EventFilterResult(sv);
}
static void
pack_UA_EventFilterResult(SV *sv, void *p)
{
	UA_EventFilterResult *data = p;
	XS_pack_UA_EventFilterResult(sv, *data);
}

static void
unpack_UA_MonitoringParameters(SV *sv, void *p)
{
	UA_MonitoringParameters *data = p;
	*data = XS_unpack_UA_MonitoringParameters(sv);
}
static void
pack_UA_MonitoringParameters(SV *sv, void *p)
{
	UA_MonitoringParameters *data = p;
	XS_pack_UA_MonitoringParameters(sv, *data);
}

static void
unpack_UA_MonitoredItemCreateRequest(SV *sv, void *p)
{
	UA_MonitoredItemCreateRequest *data = p;
	*data = XS_unpack_UA_MonitoredItemCreateRequest(sv);
}
static void
pack_UA_MonitoredItemCreateRequest(SV *sv, void *p)
{
	UA_MonitoredItemCreateRequest *data = p;
	XS_pack_UA_MonitoredItemCreateRequest(sv, *data);
}

static void
unpack_UA_MonitoredItemCreateResult(SV *sv, void *p)
{
	UA_MonitoredItemCreateResult *data = p;
	*data = XS_unpack_UA_MonitoredItemCreateResult(sv);
}
static void
pack_UA_MonitoredItemCreateResult(SV *sv, void *p)
{
	UA_MonitoredItemCreateResult *data = p;
	XS_pack_UA_MonitoredItemCreateResult(sv, *data);
}

static void
unpack_UA_CreateMonitoredItemsRequest(SV *sv, void *p)
{
	UA_CreateMonitoredItemsRequest *data = p;
	*data = XS_unpack_UA_CreateMonitoredItemsRequest(sv);
}
static void
pack_UA_CreateMonitoredItemsRequest(SV *sv, void *p)
{
	UA_CreateMonitoredItemsRequest *data = p;
	XS_pack_UA_CreateMonitoredItemsRequest(sv, *data);
}

static void
unpack_UA_CreateMonitoredItemsResponse(SV *sv, void *p)
{
	UA_CreateMonitoredItemsResponse *data = p;
	*data = XS_unpack_UA_CreateMonitoredItemsResponse(sv);
}
static void
pack_UA_CreateMonitoredItemsResponse(SV *sv, void *p)
{
	UA_CreateMonitoredItemsResponse *data = p;
	XS_pack_UA_CreateMonitoredItemsResponse(sv, *data);
}

static void
unpack_UA_MonitoredItemModifyRequest(SV *sv, void *p)
{
	UA_MonitoredItemModifyRequest *data = p;
	*data = XS_unpack_UA_MonitoredItemModifyRequest(sv);
}
static void
pack_UA_MonitoredItemModifyRequest(SV *sv, void *p)
{
	UA_MonitoredItemModifyRequest *data = p;
	XS_pack_UA_MonitoredItemModifyRequest(sv, *data);
}

static void
unpack_UA_MonitoredItemModifyResult(SV *sv, void *p)
{
	UA_MonitoredItemModifyResult *data = p;
	*data = XS_unpack_UA_MonitoredItemModifyResult(sv);
}
static void
pack_UA_MonitoredItemModifyResult(SV *sv, void *p)
{
	UA_MonitoredItemModifyResult *data = p;
	XS_pack_UA_MonitoredItemModifyResult(sv, *data);
}

static void
unpack_UA_ModifyMonitoredItemsRequest(SV *sv, void *p)
{
	UA_ModifyMonitoredItemsRequest *data = p;
	*data = XS_unpack_UA_ModifyMonitoredItemsRequest(sv);
}
static void
pack_UA_ModifyMonitoredItemsRequest(SV *sv, void *p)
{
	UA_ModifyMonitoredItemsRequest *data = p;
	XS_pack_UA_ModifyMonitoredItemsRequest(sv, *data);
}

static void
unpack_UA_ModifyMonitoredItemsResponse(SV *sv, void *p)
{
	UA_ModifyMonitoredItemsResponse *data = p;
	*data = XS_unpack_UA_ModifyMonitoredItemsResponse(sv);
}
static void
pack_UA_ModifyMonitoredItemsResponse(SV *sv, void *p)
{
	UA_ModifyMonitoredItemsResponse *data = p;
	XS_pack_UA_ModifyMonitoredItemsResponse(sv, *data);
}

static void
unpack_UA_SetMonitoringModeRequest(SV *sv, void *p)
{
	UA_SetMonitoringModeRequest *data = p;
	*data = XS_unpack_UA_SetMonitoringModeRequest(sv);
}
static void
pack_UA_SetMonitoringModeRequest(SV *sv, void *p)
{
	UA_SetMonitoringModeRequest *data = p;
	XS_pack_UA_SetMonitoringModeRequest(sv, *data);
}

static void
unpack_UA_SetMonitoringModeResponse(SV *sv, void *p)
{
	UA_SetMonitoringModeResponse *data = p;
	*data = XS_unpack_UA_SetMonitoringModeResponse(sv);
}
static void
pack_UA_SetMonitoringModeResponse(SV *sv, void *p)
{
	UA_SetMonitoringModeResponse *data = p;
	XS_pack_UA_SetMonitoringModeResponse(sv, *data);
}

static void
unpack_UA_SetTriggeringRequest(SV *sv, void *p)
{
	UA_SetTriggeringRequest *data = p;
	*data = XS_unpack_UA_SetTriggeringRequest(sv);
}
static void
pack_UA_SetTriggeringRequest(SV *sv, void *p)
{
	UA_SetTriggeringRequest *data = p;
	XS_pack_UA_SetTriggeringRequest(sv, *data);
}

static void
unpack_UA_SetTriggeringResponse(SV *sv, void *p)
{
	UA_SetTriggeringResponse *data = p;
	*data = XS_unpack_UA_SetTriggeringResponse(sv);
}
static void
pack_UA_SetTriggeringResponse(SV *sv, void *p)
{
	UA_SetTriggeringResponse *data = p;
	XS_pack_UA_SetTriggeringResponse(sv, *data);
}

static void
unpack_UA_DeleteMonitoredItemsRequest(SV *sv, void *p)
{
	UA_DeleteMonitoredItemsRequest *data = p;
	*data = XS_unpack_UA_DeleteMonitoredItemsRequest(sv);
}
static void
pack_UA_DeleteMonitoredItemsRequest(SV *sv, void *p)
{
	UA_DeleteMonitoredItemsRequest *data = p;
	XS_pack_UA_DeleteMonitoredItemsRequest(sv, *data);
}

static void
unpack_UA_DeleteMonitoredItemsResponse(SV *sv, void *p)
{
	UA_DeleteMonitoredItemsResponse *data = p;
	*data = XS_unpack_UA_DeleteMonitoredItemsResponse(sv);
}
static void
pack_UA_DeleteMonitoredItemsResponse(SV *sv, void *p)
{
	UA_DeleteMonitoredItemsResponse *data = p;
	XS_pack_UA_DeleteMonitoredItemsResponse(sv, *data);
}

static void
unpack_UA_CreateSubscriptionRequest(SV *sv, void *p)
{
	UA_CreateSubscriptionRequest *data = p;
	*data = XS_unpack_UA_CreateSubscriptionRequest(sv);
}
static void
pack_UA_CreateSubscriptionRequest(SV *sv, void *p)
{
	UA_CreateSubscriptionRequest *data = p;
	XS_pack_UA_CreateSubscriptionRequest(sv, *data);
}

static void
unpack_UA_CreateSubscriptionResponse(SV *sv, void *p)
{
	UA_CreateSubscriptionResponse *data = p;
	*data = XS_unpack_UA_CreateSubscriptionResponse(sv);
}
static void
pack_UA_CreateSubscriptionResponse(SV *sv, void *p)
{
	UA_CreateSubscriptionResponse *data = p;
	XS_pack_UA_CreateSubscriptionResponse(sv, *data);
}

static void
unpack_UA_ModifySubscriptionRequest(SV *sv, void *p)
{
	UA_ModifySubscriptionRequest *data = p;
	*data = XS_unpack_UA_ModifySubscriptionRequest(sv);
}
static void
pack_UA_ModifySubscriptionRequest(SV *sv, void *p)
{
	UA_ModifySubscriptionRequest *data = p;
	XS_pack_UA_ModifySubscriptionRequest(sv, *data);
}

static void
unpack_UA_ModifySubscriptionResponse(SV *sv, void *p)
{
	UA_ModifySubscriptionResponse *data = p;
	*data = XS_unpack_UA_ModifySubscriptionResponse(sv);
}
static void
pack_UA_ModifySubscriptionResponse(SV *sv, void *p)
{
	UA_ModifySubscriptionResponse *data = p;
	XS_pack_UA_ModifySubscriptionResponse(sv, *data);
}

static void
unpack_UA_SetPublishingModeRequest(SV *sv, void *p)
{
	UA_SetPublishingModeRequest *data = p;
	*data = XS_unpack_UA_SetPublishingModeRequest(sv);
}
static void
pack_UA_SetPublishingModeRequest(SV *sv, void *p)
{
	UA_SetPublishingModeRequest *data = p;
	XS_pack_UA_SetPublishingModeRequest(sv, *data);
}

static void
unpack_UA_SetPublishingModeResponse(SV *sv, void *p)
{
	UA_SetPublishingModeResponse *data = p;
	*data = XS_unpack_UA_SetPublishingModeResponse(sv);
}
static void
pack_UA_SetPublishingModeResponse(SV *sv, void *p)
{
	UA_SetPublishingModeResponse *data = p;
	XS_pack_UA_SetPublishingModeResponse(sv, *data);
}

static void
unpack_UA_NotificationMessage(SV *sv, void *p)
{
	UA_NotificationMessage *data = p;
	*data = XS_unpack_UA_NotificationMessage(sv);
}
static void
pack_UA_NotificationMessage(SV *sv, void *p)
{
	UA_NotificationMessage *data = p;
	XS_pack_UA_NotificationMessage(sv, *data);
}

static void
unpack_UA_MonitoredItemNotification(SV *sv, void *p)
{
	UA_MonitoredItemNotification *data = p;
	*data = XS_unpack_UA_MonitoredItemNotification(sv);
}
static void
pack_UA_MonitoredItemNotification(SV *sv, void *p)
{
	UA_MonitoredItemNotification *data = p;
	XS_pack_UA_MonitoredItemNotification(sv, *data);
}

static void
unpack_UA_EventFieldList(SV *sv, void *p)
{
	UA_EventFieldList *data = p;
	*data = XS_unpack_UA_EventFieldList(sv);
}
static void
pack_UA_EventFieldList(SV *sv, void *p)
{
	UA_EventFieldList *data = p;
	XS_pack_UA_EventFieldList(sv, *data);
}

static void
unpack_UA_StatusChangeNotification(SV *sv, void *p)
{
	UA_StatusChangeNotification *data = p;
	*data = XS_unpack_UA_StatusChangeNotification(sv);
}
static void
pack_UA_StatusChangeNotification(SV *sv, void *p)
{
	UA_StatusChangeNotification *data = p;
	XS_pack_UA_StatusChangeNotification(sv, *data);
}

static void
unpack_UA_SubscriptionAcknowledgement(SV *sv, void *p)
{
	UA_SubscriptionAcknowledgement *data = p;
	*data = XS_unpack_UA_SubscriptionAcknowledgement(sv);
}
static void
pack_UA_SubscriptionAcknowledgement(SV *sv, void *p)
{
	UA_SubscriptionAcknowledgement *data = p;
	XS_pack_UA_SubscriptionAcknowledgement(sv, *data);
}

static void
unpack_UA_PublishRequest(SV *sv, void *p)
{
	UA_PublishRequest *data = p;
	*data = XS_unpack_UA_PublishRequest(sv);
}
static void
pack_UA_PublishRequest(SV *sv, void *p)
{
	UA_PublishRequest *data = p;
	XS_pack_UA_PublishRequest(sv, *data);
}

static void
unpack_UA_PublishResponse(SV *sv, void *p)
{
	UA_PublishResponse *data = p;
	*data = XS_unpack_UA_PublishResponse(sv);
}
static void
pack_UA_PublishResponse(SV *sv, void *p)
{
	UA_PublishResponse *data = p;
	XS_pack_UA_PublishResponse(sv, *data);
}

static void
unpack_UA_RepublishRequest(SV *sv, void *p)
{
	UA_RepublishRequest *data = p;
	*data = XS_unpack_UA_RepublishRequest(sv);
}
static void
pack_UA_RepublishRequest(SV *sv, void *p)
{
	UA_RepublishRequest *data = p;
	XS_pack_UA_RepublishRequest(sv, *data);
}

static void
unpack_UA_RepublishResponse(SV *sv, void *p)
{
	UA_RepublishResponse *data = p;
	*data = XS_unpack_UA_RepublishResponse(sv);
}
static void
pack_UA_RepublishResponse(SV *sv, void *p)
{
	UA_RepublishResponse *data = p;
	XS_pack_UA_RepublishResponse(sv, *data);
}

static void
unpack_UA_DeleteSubscriptionsRequest(SV *sv, void *p)
{
	UA_DeleteSubscriptionsRequest *data = p;
	*data = XS_unpack_UA_DeleteSubscriptionsRequest(sv);
}
static void
pack_UA_DeleteSubscriptionsRequest(SV *sv, void *p)
{
	UA_DeleteSubscriptionsRequest *data = p;
	XS_pack_UA_DeleteSubscriptionsRequest(sv, *data);
}

static void
unpack_UA_DeleteSubscriptionsResponse(SV *sv, void *p)
{
	UA_DeleteSubscriptionsResponse *data = p;
	*data = XS_unpack_UA_DeleteSubscriptionsResponse(sv);
}
static void
pack_UA_DeleteSubscriptionsResponse(SV *sv, void *p)
{
	UA_DeleteSubscriptionsResponse *data = p;
	XS_pack_UA_DeleteSubscriptionsResponse(sv, *data);
}

static void
unpack_UA_BuildInfo(SV *sv, void *p)
{
	UA_BuildInfo *data = p;
	*data = XS_unpack_UA_BuildInfo(sv);
}
static void
pack_UA_BuildInfo(SV *sv, void *p)
{
	UA_BuildInfo *data = p;
	XS_pack_UA_BuildInfo(sv, *data);
}

static void
unpack_UA_RedundancySupport(SV *sv, void *p)
{
	UA_RedundancySupport *data = p;
	*data = XS_unpack_UA_RedundancySupport(sv);
}
static void
pack_UA_RedundancySupport(SV *sv, void *p)
{
	UA_RedundancySupport *data = p;
	XS_pack_UA_RedundancySupport(sv, *data);
}

static void
unpack_UA_ServerState(SV *sv, void *p)
{
	UA_ServerState *data = p;
	*data = XS_unpack_UA_ServerState(sv);
}
static void
pack_UA_ServerState(SV *sv, void *p)
{
	UA_ServerState *data = p;
	XS_pack_UA_ServerState(sv, *data);
}

static void
unpack_UA_ServerDiagnosticsSummaryDataType(SV *sv, void *p)
{
	UA_ServerDiagnosticsSummaryDataType *data = p;
	*data = XS_unpack_UA_ServerDiagnosticsSummaryDataType(sv);
}
static void
pack_UA_ServerDiagnosticsSummaryDataType(SV *sv, void *p)
{
	UA_ServerDiagnosticsSummaryDataType *data = p;
	XS_pack_UA_ServerDiagnosticsSummaryDataType(sv, *data);
}

static void
unpack_UA_ServerStatusDataType(SV *sv, void *p)
{
	UA_ServerStatusDataType *data = p;
	*data = XS_unpack_UA_ServerStatusDataType(sv);
}
static void
pack_UA_ServerStatusDataType(SV *sv, void *p)
{
	UA_ServerStatusDataType *data = p;
	XS_pack_UA_ServerStatusDataType(sv, *data);
}

static void
unpack_UA_Range(SV *sv, void *p)
{
	UA_Range *data = p;
	*data = XS_unpack_UA_Range(sv);
}
static void
pack_UA_Range(SV *sv, void *p)
{
	UA_Range *data = p;
	XS_pack_UA_Range(sv, *data);
}

static void
unpack_UA_DataChangeNotification(SV *sv, void *p)
{
	UA_DataChangeNotification *data = p;
	*data = XS_unpack_UA_DataChangeNotification(sv);
}
static void
pack_UA_DataChangeNotification(SV *sv, void *p)
{
	UA_DataChangeNotification *data = p;
	XS_pack_UA_DataChangeNotification(sv, *data);
}

static void
unpack_UA_EventNotificationList(SV *sv, void *p)
{
	UA_EventNotificationList *data = p;
	*data = XS_unpack_UA_EventNotificationList(sv);
}
static void
pack_UA_EventNotificationList(SV *sv, void *p)
{
	UA_EventNotificationList *data = p;
	XS_pack_UA_EventNotificationList(sv, *data);
}

typedef void (*packed_UA)(SV *, void *);
static packed_UA unpack_UA_table[UA_TYPES_COUNT] = {
	unpack_UA_Boolean,
	unpack_UA_SByte,
	unpack_UA_Byte,
	unpack_UA_Int16,
	unpack_UA_UInt16,
	unpack_UA_Int32,
	unpack_UA_UInt32,
	unpack_UA_Int64,
	unpack_UA_UInt64,
	unpack_UA_Float,
	unpack_UA_Double,
	unpack_UA_String,
	unpack_UA_DateTime,
	unpack_UA_Guid,
	unpack_UA_ByteString,
	unpack_UA_XmlElement,
	unpack_UA_NodeId,
	unpack_UA_ExpandedNodeId,
	unpack_UA_StatusCode,
	unpack_UA_QualifiedName,
	unpack_UA_LocalizedText,
	unpack_UA_ExtensionObject,
	unpack_UA_DataValue,
	unpack_UA_Variant,
	unpack_UA_DiagnosticInfo,
	unpack_UA_NodeClass,
	unpack_UA_Argument,
	unpack_UA_EnumValueType,
	unpack_UA_Duration,
	unpack_UA_UtcTime,
	unpack_UA_LocaleId,
	unpack_UA_ApplicationType,
	unpack_UA_ApplicationDescription,
	unpack_UA_RequestHeader,
	unpack_UA_ResponseHeader,
	unpack_UA_ServiceFault,
	unpack_UA_FindServersRequest,
	unpack_UA_FindServersResponse,
	unpack_UA_ServerOnNetwork,
	unpack_UA_FindServersOnNetworkRequest,
	unpack_UA_FindServersOnNetworkResponse,
	unpack_UA_MessageSecurityMode,
	unpack_UA_UserTokenType,
	unpack_UA_UserTokenPolicy,
	unpack_UA_EndpointDescription,
	unpack_UA_GetEndpointsRequest,
	unpack_UA_GetEndpointsResponse,
	unpack_UA_RegisteredServer,
	unpack_UA_RegisterServerRequest,
	unpack_UA_RegisterServerResponse,
	unpack_UA_DiscoveryConfiguration,
	unpack_UA_MdnsDiscoveryConfiguration,
	unpack_UA_RegisterServer2Request,
	unpack_UA_RegisterServer2Response,
	unpack_UA_SecurityTokenRequestType,
	unpack_UA_ChannelSecurityToken,
	unpack_UA_OpenSecureChannelRequest,
	unpack_UA_OpenSecureChannelResponse,
	unpack_UA_CloseSecureChannelRequest,
	unpack_UA_CloseSecureChannelResponse,
	unpack_UA_SignedSoftwareCertificate,
	unpack_UA_SignatureData,
	unpack_UA_CreateSessionRequest,
	unpack_UA_CreateSessionResponse,
	unpack_UA_UserIdentityToken,
	unpack_UA_AnonymousIdentityToken,
	unpack_UA_UserNameIdentityToken,
	unpack_UA_X509IdentityToken,
	unpack_UA_IssuedIdentityToken,
	unpack_UA_ActivateSessionRequest,
	unpack_UA_ActivateSessionResponse,
	unpack_UA_CloseSessionRequest,
	unpack_UA_CloseSessionResponse,
	unpack_UA_NodeAttributesMask,
	unpack_UA_NodeAttributes,
	unpack_UA_ObjectAttributes,
	unpack_UA_VariableAttributes,
	unpack_UA_MethodAttributes,
	unpack_UA_ObjectTypeAttributes,
	unpack_UA_VariableTypeAttributes,
	unpack_UA_ReferenceTypeAttributes,
	unpack_UA_DataTypeAttributes,
	unpack_UA_ViewAttributes,
	unpack_UA_AddNodesItem,
	unpack_UA_AddNodesResult,
	unpack_UA_AddNodesRequest,
	unpack_UA_AddNodesResponse,
	unpack_UA_AddReferencesItem,
	unpack_UA_AddReferencesRequest,
	unpack_UA_AddReferencesResponse,
	unpack_UA_DeleteNodesItem,
	unpack_UA_DeleteNodesRequest,
	unpack_UA_DeleteNodesResponse,
	unpack_UA_DeleteReferencesItem,
	unpack_UA_DeleteReferencesRequest,
	unpack_UA_DeleteReferencesResponse,
	unpack_UA_BrowseDirection,
	unpack_UA_ViewDescription,
	unpack_UA_BrowseDescription,
	unpack_UA_BrowseResultMask,
	unpack_UA_ReferenceDescription,
	unpack_UA_BrowseResult,
	unpack_UA_BrowseRequest,
	unpack_UA_BrowseResponse,
	unpack_UA_BrowseNextRequest,
	unpack_UA_BrowseNextResponse,
	unpack_UA_RelativePathElement,
	unpack_UA_RelativePath,
	unpack_UA_BrowsePath,
	unpack_UA_BrowsePathTarget,
	unpack_UA_BrowsePathResult,
	unpack_UA_TranslateBrowsePathsToNodeIdsRequest,
	unpack_UA_TranslateBrowsePathsToNodeIdsResponse,
	unpack_UA_RegisterNodesRequest,
	unpack_UA_RegisterNodesResponse,
	unpack_UA_UnregisterNodesRequest,
	unpack_UA_UnregisterNodesResponse,
	unpack_UA_FilterOperator,
	unpack_UA_ContentFilterElement,
	unpack_UA_ContentFilter,
	unpack_UA_FilterOperand,
	unpack_UA_ElementOperand,
	unpack_UA_LiteralOperand,
	unpack_UA_AttributeOperand,
	unpack_UA_SimpleAttributeOperand,
	unpack_UA_ContentFilterElementResult,
	unpack_UA_ContentFilterResult,
	unpack_UA_TimestampsToReturn,
	unpack_UA_ReadValueId,
	unpack_UA_ReadRequest,
	unpack_UA_ReadResponse,
	unpack_UA_WriteValue,
	unpack_UA_WriteRequest,
	unpack_UA_WriteResponse,
	unpack_UA_CallMethodRequest,
	unpack_UA_CallMethodResult,
	unpack_UA_CallRequest,
	unpack_UA_CallResponse,
	unpack_UA_MonitoringMode,
	unpack_UA_DataChangeTrigger,
	unpack_UA_DeadbandType,
	unpack_UA_DataChangeFilter,
	unpack_UA_EventFilter,
	unpack_UA_AggregateConfiguration,
	unpack_UA_AggregateFilter,
	unpack_UA_EventFilterResult,
	unpack_UA_MonitoringParameters,
	unpack_UA_MonitoredItemCreateRequest,
	unpack_UA_MonitoredItemCreateResult,
	unpack_UA_CreateMonitoredItemsRequest,
	unpack_UA_CreateMonitoredItemsResponse,
	unpack_UA_MonitoredItemModifyRequest,
	unpack_UA_MonitoredItemModifyResult,
	unpack_UA_ModifyMonitoredItemsRequest,
	unpack_UA_ModifyMonitoredItemsResponse,
	unpack_UA_SetMonitoringModeRequest,
	unpack_UA_SetMonitoringModeResponse,
	unpack_UA_SetTriggeringRequest,
	unpack_UA_SetTriggeringResponse,
	unpack_UA_DeleteMonitoredItemsRequest,
	unpack_UA_DeleteMonitoredItemsResponse,
	unpack_UA_CreateSubscriptionRequest,
	unpack_UA_CreateSubscriptionResponse,
	unpack_UA_ModifySubscriptionRequest,
	unpack_UA_ModifySubscriptionResponse,
	unpack_UA_SetPublishingModeRequest,
	unpack_UA_SetPublishingModeResponse,
	unpack_UA_NotificationMessage,
	unpack_UA_MonitoredItemNotification,
	unpack_UA_EventFieldList,
	unpack_UA_StatusChangeNotification,
	unpack_UA_SubscriptionAcknowledgement,
	unpack_UA_PublishRequest,
	unpack_UA_PublishResponse,
	unpack_UA_RepublishRequest,
	unpack_UA_RepublishResponse,
	unpack_UA_DeleteSubscriptionsRequest,
	unpack_UA_DeleteSubscriptionsResponse,
	unpack_UA_BuildInfo,
	unpack_UA_RedundancySupport,
	unpack_UA_ServerState,
	unpack_UA_ServerDiagnosticsSummaryDataType,
	unpack_UA_ServerStatusDataType,
	unpack_UA_Range,
	unpack_UA_DataChangeNotification,
	unpack_UA_EventNotificationList,
};
static packed_UA pack_UA_table[UA_TYPES_COUNT] = {
	pack_UA_Boolean,
	pack_UA_SByte,
	pack_UA_Byte,
	pack_UA_Int16,
	pack_UA_UInt16,
	pack_UA_Int32,
	pack_UA_UInt32,
	pack_UA_Int64,
	pack_UA_UInt64,
	pack_UA_Float,
	pack_UA_Double,
	pack_UA_String,
	pack_UA_DateTime,
	pack_UA_Guid,
	pack_UA_ByteString,
	pack_UA_XmlElement,
	pack_UA_NodeId,
	pack_UA_ExpandedNodeId,
	pack_UA_StatusCode,
	pack_UA_QualifiedName,
	pack_UA_LocalizedText,
	pack_UA_ExtensionObject,
	pack_UA_DataValue,
	pack_UA_Variant,
	pack_UA_DiagnosticInfo,
	pack_UA_NodeClass,
	pack_UA_Argument,
	pack_UA_EnumValueType,
	pack_UA_Duration,
	pack_UA_UtcTime,
	pack_UA_LocaleId,
	pack_UA_ApplicationType,
	pack_UA_ApplicationDescription,
	pack_UA_RequestHeader,
	pack_UA_ResponseHeader,
	pack_UA_ServiceFault,
	pack_UA_FindServersRequest,
	pack_UA_FindServersResponse,
	pack_UA_ServerOnNetwork,
	pack_UA_FindServersOnNetworkRequest,
	pack_UA_FindServersOnNetworkResponse,
	pack_UA_MessageSecurityMode,
	pack_UA_UserTokenType,
	pack_UA_UserTokenPolicy,
	pack_UA_EndpointDescription,
	pack_UA_GetEndpointsRequest,
	pack_UA_GetEndpointsResponse,
	pack_UA_RegisteredServer,
	pack_UA_RegisterServerRequest,
	pack_UA_RegisterServerResponse,
	pack_UA_DiscoveryConfiguration,
	pack_UA_MdnsDiscoveryConfiguration,
	pack_UA_RegisterServer2Request,
	pack_UA_RegisterServer2Response,
	pack_UA_SecurityTokenRequestType,
	pack_UA_ChannelSecurityToken,
	pack_UA_OpenSecureChannelRequest,
	pack_UA_OpenSecureChannelResponse,
	pack_UA_CloseSecureChannelRequest,
	pack_UA_CloseSecureChannelResponse,
	pack_UA_SignedSoftwareCertificate,
	pack_UA_SignatureData,
	pack_UA_CreateSessionRequest,
	pack_UA_CreateSessionResponse,
	pack_UA_UserIdentityToken,
	pack_UA_AnonymousIdentityToken,
	pack_UA_UserNameIdentityToken,
	pack_UA_X509IdentityToken,
	pack_UA_IssuedIdentityToken,
	pack_UA_ActivateSessionRequest,
	pack_UA_ActivateSessionResponse,
	pack_UA_CloseSessionRequest,
	pack_UA_CloseSessionResponse,
	pack_UA_NodeAttributesMask,
	pack_UA_NodeAttributes,
	pack_UA_ObjectAttributes,
	pack_UA_VariableAttributes,
	pack_UA_MethodAttributes,
	pack_UA_ObjectTypeAttributes,
	pack_UA_VariableTypeAttributes,
	pack_UA_ReferenceTypeAttributes,
	pack_UA_DataTypeAttributes,
	pack_UA_ViewAttributes,
	pack_UA_AddNodesItem,
	pack_UA_AddNodesResult,
	pack_UA_AddNodesRequest,
	pack_UA_AddNodesResponse,
	pack_UA_AddReferencesItem,
	pack_UA_AddReferencesRequest,
	pack_UA_AddReferencesResponse,
	pack_UA_DeleteNodesItem,
	pack_UA_DeleteNodesRequest,
	pack_UA_DeleteNodesResponse,
	pack_UA_DeleteReferencesItem,
	pack_UA_DeleteReferencesRequest,
	pack_UA_DeleteReferencesResponse,
	pack_UA_BrowseDirection,
	pack_UA_ViewDescription,
	pack_UA_BrowseDescription,
	pack_UA_BrowseResultMask,
	pack_UA_ReferenceDescription,
	pack_UA_BrowseResult,
	pack_UA_BrowseRequest,
	pack_UA_BrowseResponse,
	pack_UA_BrowseNextRequest,
	pack_UA_BrowseNextResponse,
	pack_UA_RelativePathElement,
	pack_UA_RelativePath,
	pack_UA_BrowsePath,
	pack_UA_BrowsePathTarget,
	pack_UA_BrowsePathResult,
	pack_UA_TranslateBrowsePathsToNodeIdsRequest,
	pack_UA_TranslateBrowsePathsToNodeIdsResponse,
	pack_UA_RegisterNodesRequest,
	pack_UA_RegisterNodesResponse,
	pack_UA_UnregisterNodesRequest,
	pack_UA_UnregisterNodesResponse,
	pack_UA_FilterOperator,
	pack_UA_ContentFilterElement,
	pack_UA_ContentFilter,
	pack_UA_FilterOperand,
	pack_UA_ElementOperand,
	pack_UA_LiteralOperand,
	pack_UA_AttributeOperand,
	pack_UA_SimpleAttributeOperand,
	pack_UA_ContentFilterElementResult,
	pack_UA_ContentFilterResult,
	pack_UA_TimestampsToReturn,
	pack_UA_ReadValueId,
	pack_UA_ReadRequest,
	pack_UA_ReadResponse,
	pack_UA_WriteValue,
	pack_UA_WriteRequest,
	pack_UA_WriteResponse,
	pack_UA_CallMethodRequest,
	pack_UA_CallMethodResult,
	pack_UA_CallRequest,
	pack_UA_CallResponse,
	pack_UA_MonitoringMode,
	pack_UA_DataChangeTrigger,
	pack_UA_DeadbandType,
	pack_UA_DataChangeFilter,
	pack_UA_EventFilter,
	pack_UA_AggregateConfiguration,
	pack_UA_AggregateFilter,
	pack_UA_EventFilterResult,
	pack_UA_MonitoringParameters,
	pack_UA_MonitoredItemCreateRequest,
	pack_UA_MonitoredItemCreateResult,
	pack_UA_CreateMonitoredItemsRequest,
	pack_UA_CreateMonitoredItemsResponse,
	pack_UA_MonitoredItemModifyRequest,
	pack_UA_MonitoredItemModifyResult,
	pack_UA_ModifyMonitoredItemsRequest,
	pack_UA_ModifyMonitoredItemsResponse,
	pack_UA_SetMonitoringModeRequest,
	pack_UA_SetMonitoringModeResponse,
	pack_UA_SetTriggeringRequest,
	pack_UA_SetTriggeringResponse,
	pack_UA_DeleteMonitoredItemsRequest,
	pack_UA_DeleteMonitoredItemsResponse,
	pack_UA_CreateSubscriptionRequest,
	pack_UA_CreateSubscriptionResponse,
	pack_UA_ModifySubscriptionRequest,
	pack_UA_ModifySubscriptionResponse,
	pack_UA_SetPublishingModeRequest,
	pack_UA_SetPublishingModeResponse,
	pack_UA_NotificationMessage,
	pack_UA_MonitoredItemNotification,
	pack_UA_EventFieldList,
	pack_UA_StatusChangeNotification,
	pack_UA_SubscriptionAcknowledgement,
	pack_UA_PublishRequest,
	pack_UA_PublishResponse,
	pack_UA_RepublishRequest,
	pack_UA_RepublishResponse,
	pack_UA_DeleteSubscriptionsRequest,
	pack_UA_DeleteSubscriptionsResponse,
	pack_UA_BuildInfo,
	pack_UA_RedundancySupport,
	pack_UA_ServerState,
	pack_UA_ServerDiagnosticsSummaryDataType,
	pack_UA_ServerStatusDataType,
	pack_UA_Range,
	pack_UA_DataChangeNotification,
	pack_UA_EventNotificationList,
};
