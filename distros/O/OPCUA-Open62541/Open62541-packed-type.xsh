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
	[UA_TYPES_BOOLEAN] = unpack_UA_Boolean,
	[UA_TYPES_SBYTE] = unpack_UA_SByte,
	[UA_TYPES_BYTE] = unpack_UA_Byte,
	[UA_TYPES_INT16] = unpack_UA_Int16,
	[UA_TYPES_UINT16] = unpack_UA_UInt16,
	[UA_TYPES_INT32] = unpack_UA_Int32,
	[UA_TYPES_UINT32] = unpack_UA_UInt32,
	[UA_TYPES_INT64] = unpack_UA_Int64,
	[UA_TYPES_UINT64] = unpack_UA_UInt64,
	[UA_TYPES_FLOAT] = unpack_UA_Float,
	[UA_TYPES_DOUBLE] = unpack_UA_Double,
	[UA_TYPES_STRING] = unpack_UA_String,
	[UA_TYPES_DATETIME] = unpack_UA_DateTime,
	[UA_TYPES_GUID] = unpack_UA_Guid,
	[UA_TYPES_BYTESTRING] = unpack_UA_ByteString,
	[UA_TYPES_XMLELEMENT] = unpack_UA_XmlElement,
	[UA_TYPES_NODEID] = unpack_UA_NodeId,
	[UA_TYPES_EXPANDEDNODEID] = unpack_UA_ExpandedNodeId,
	[UA_TYPES_STATUSCODE] = unpack_UA_StatusCode,
	[UA_TYPES_QUALIFIEDNAME] = unpack_UA_QualifiedName,
	[UA_TYPES_LOCALIZEDTEXT] = unpack_UA_LocalizedText,
	[UA_TYPES_EXTENSIONOBJECT] = unpack_UA_ExtensionObject,
	[UA_TYPES_DATAVALUE] = unpack_UA_DataValue,
	[UA_TYPES_VARIANT] = unpack_UA_Variant,
	[UA_TYPES_DIAGNOSTICINFO] = unpack_UA_DiagnosticInfo,
	[UA_TYPES_NODECLASS] = unpack_UA_NodeClass,
	[UA_TYPES_ARGUMENT] = unpack_UA_Argument,
	[UA_TYPES_ENUMVALUETYPE] = unpack_UA_EnumValueType,
	[UA_TYPES_DURATION] = unpack_UA_Duration,
	[UA_TYPES_UTCTIME] = unpack_UA_UtcTime,
	[UA_TYPES_LOCALEID] = unpack_UA_LocaleId,
	[UA_TYPES_APPLICATIONTYPE] = unpack_UA_ApplicationType,
	[UA_TYPES_APPLICATIONDESCRIPTION] = unpack_UA_ApplicationDescription,
	[UA_TYPES_REQUESTHEADER] = unpack_UA_RequestHeader,
	[UA_TYPES_RESPONSEHEADER] = unpack_UA_ResponseHeader,
	[UA_TYPES_SERVICEFAULT] = unpack_UA_ServiceFault,
	[UA_TYPES_FINDSERVERSREQUEST] = unpack_UA_FindServersRequest,
	[UA_TYPES_FINDSERVERSRESPONSE] = unpack_UA_FindServersResponse,
	[UA_TYPES_SERVERONNETWORK] = unpack_UA_ServerOnNetwork,
	[UA_TYPES_FINDSERVERSONNETWORKREQUEST] = unpack_UA_FindServersOnNetworkRequest,
	[UA_TYPES_FINDSERVERSONNETWORKRESPONSE] = unpack_UA_FindServersOnNetworkResponse,
	[UA_TYPES_MESSAGESECURITYMODE] = unpack_UA_MessageSecurityMode,
	[UA_TYPES_USERTOKENTYPE] = unpack_UA_UserTokenType,
	[UA_TYPES_USERTOKENPOLICY] = unpack_UA_UserTokenPolicy,
	[UA_TYPES_ENDPOINTDESCRIPTION] = unpack_UA_EndpointDescription,
	[UA_TYPES_GETENDPOINTSREQUEST] = unpack_UA_GetEndpointsRequest,
	[UA_TYPES_GETENDPOINTSRESPONSE] = unpack_UA_GetEndpointsResponse,
	[UA_TYPES_REGISTEREDSERVER] = unpack_UA_RegisteredServer,
	[UA_TYPES_REGISTERSERVERREQUEST] = unpack_UA_RegisterServerRequest,
	[UA_TYPES_REGISTERSERVERRESPONSE] = unpack_UA_RegisterServerResponse,
	[UA_TYPES_DISCOVERYCONFIGURATION] = unpack_UA_DiscoveryConfiguration,
	[UA_TYPES_MDNSDISCOVERYCONFIGURATION] = unpack_UA_MdnsDiscoveryConfiguration,
	[UA_TYPES_REGISTERSERVER2REQUEST] = unpack_UA_RegisterServer2Request,
	[UA_TYPES_REGISTERSERVER2RESPONSE] = unpack_UA_RegisterServer2Response,
	[UA_TYPES_SECURITYTOKENREQUESTTYPE] = unpack_UA_SecurityTokenRequestType,
	[UA_TYPES_CHANNELSECURITYTOKEN] = unpack_UA_ChannelSecurityToken,
	[UA_TYPES_OPENSECURECHANNELREQUEST] = unpack_UA_OpenSecureChannelRequest,
	[UA_TYPES_OPENSECURECHANNELRESPONSE] = unpack_UA_OpenSecureChannelResponse,
	[UA_TYPES_CLOSESECURECHANNELREQUEST] = unpack_UA_CloseSecureChannelRequest,
	[UA_TYPES_CLOSESECURECHANNELRESPONSE] = unpack_UA_CloseSecureChannelResponse,
	[UA_TYPES_SIGNEDSOFTWARECERTIFICATE] = unpack_UA_SignedSoftwareCertificate,
	[UA_TYPES_SIGNATUREDATA] = unpack_UA_SignatureData,
	[UA_TYPES_CREATESESSIONREQUEST] = unpack_UA_CreateSessionRequest,
	[UA_TYPES_CREATESESSIONRESPONSE] = unpack_UA_CreateSessionResponse,
	[UA_TYPES_USERIDENTITYTOKEN] = unpack_UA_UserIdentityToken,
	[UA_TYPES_ANONYMOUSIDENTITYTOKEN] = unpack_UA_AnonymousIdentityToken,
	[UA_TYPES_USERNAMEIDENTITYTOKEN] = unpack_UA_UserNameIdentityToken,
	[UA_TYPES_X509IDENTITYTOKEN] = unpack_UA_X509IdentityToken,
	[UA_TYPES_ISSUEDIDENTITYTOKEN] = unpack_UA_IssuedIdentityToken,
	[UA_TYPES_ACTIVATESESSIONREQUEST] = unpack_UA_ActivateSessionRequest,
	[UA_TYPES_ACTIVATESESSIONRESPONSE] = unpack_UA_ActivateSessionResponse,
	[UA_TYPES_CLOSESESSIONREQUEST] = unpack_UA_CloseSessionRequest,
	[UA_TYPES_CLOSESESSIONRESPONSE] = unpack_UA_CloseSessionResponse,
	[UA_TYPES_NODEATTRIBUTESMASK] = unpack_UA_NodeAttributesMask,
	[UA_TYPES_NODEATTRIBUTES] = unpack_UA_NodeAttributes,
	[UA_TYPES_OBJECTATTRIBUTES] = unpack_UA_ObjectAttributes,
	[UA_TYPES_VARIABLEATTRIBUTES] = unpack_UA_VariableAttributes,
	[UA_TYPES_METHODATTRIBUTES] = unpack_UA_MethodAttributes,
	[UA_TYPES_OBJECTTYPEATTRIBUTES] = unpack_UA_ObjectTypeAttributes,
	[UA_TYPES_VARIABLETYPEATTRIBUTES] = unpack_UA_VariableTypeAttributes,
	[UA_TYPES_REFERENCETYPEATTRIBUTES] = unpack_UA_ReferenceTypeAttributes,
	[UA_TYPES_DATATYPEATTRIBUTES] = unpack_UA_DataTypeAttributes,
	[UA_TYPES_VIEWATTRIBUTES] = unpack_UA_ViewAttributes,
	[UA_TYPES_ADDNODESITEM] = unpack_UA_AddNodesItem,
	[UA_TYPES_ADDNODESRESULT] = unpack_UA_AddNodesResult,
	[UA_TYPES_ADDNODESREQUEST] = unpack_UA_AddNodesRequest,
	[UA_TYPES_ADDNODESRESPONSE] = unpack_UA_AddNodesResponse,
	[UA_TYPES_ADDREFERENCESITEM] = unpack_UA_AddReferencesItem,
	[UA_TYPES_ADDREFERENCESREQUEST] = unpack_UA_AddReferencesRequest,
	[UA_TYPES_ADDREFERENCESRESPONSE] = unpack_UA_AddReferencesResponse,
	[UA_TYPES_DELETENODESITEM] = unpack_UA_DeleteNodesItem,
	[UA_TYPES_DELETENODESREQUEST] = unpack_UA_DeleteNodesRequest,
	[UA_TYPES_DELETENODESRESPONSE] = unpack_UA_DeleteNodesResponse,
	[UA_TYPES_DELETEREFERENCESITEM] = unpack_UA_DeleteReferencesItem,
	[UA_TYPES_DELETEREFERENCESREQUEST] = unpack_UA_DeleteReferencesRequest,
	[UA_TYPES_DELETEREFERENCESRESPONSE] = unpack_UA_DeleteReferencesResponse,
	[UA_TYPES_BROWSEDIRECTION] = unpack_UA_BrowseDirection,
	[UA_TYPES_VIEWDESCRIPTION] = unpack_UA_ViewDescription,
	[UA_TYPES_BROWSEDESCRIPTION] = unpack_UA_BrowseDescription,
	[UA_TYPES_BROWSERESULTMASK] = unpack_UA_BrowseResultMask,
	[UA_TYPES_REFERENCEDESCRIPTION] = unpack_UA_ReferenceDescription,
	[UA_TYPES_BROWSERESULT] = unpack_UA_BrowseResult,
	[UA_TYPES_BROWSEREQUEST] = unpack_UA_BrowseRequest,
	[UA_TYPES_BROWSERESPONSE] = unpack_UA_BrowseResponse,
	[UA_TYPES_BROWSENEXTREQUEST] = unpack_UA_BrowseNextRequest,
	[UA_TYPES_BROWSENEXTRESPONSE] = unpack_UA_BrowseNextResponse,
	[UA_TYPES_RELATIVEPATHELEMENT] = unpack_UA_RelativePathElement,
	[UA_TYPES_RELATIVEPATH] = unpack_UA_RelativePath,
	[UA_TYPES_BROWSEPATH] = unpack_UA_BrowsePath,
	[UA_TYPES_BROWSEPATHTARGET] = unpack_UA_BrowsePathTarget,
	[UA_TYPES_BROWSEPATHRESULT] = unpack_UA_BrowsePathResult,
	[UA_TYPES_TRANSLATEBROWSEPATHSTONODEIDSREQUEST] = unpack_UA_TranslateBrowsePathsToNodeIdsRequest,
	[UA_TYPES_TRANSLATEBROWSEPATHSTONODEIDSRESPONSE] = unpack_UA_TranslateBrowsePathsToNodeIdsResponse,
	[UA_TYPES_REGISTERNODESREQUEST] = unpack_UA_RegisterNodesRequest,
	[UA_TYPES_REGISTERNODESRESPONSE] = unpack_UA_RegisterNodesResponse,
	[UA_TYPES_UNREGISTERNODESREQUEST] = unpack_UA_UnregisterNodesRequest,
	[UA_TYPES_UNREGISTERNODESRESPONSE] = unpack_UA_UnregisterNodesResponse,
	[UA_TYPES_FILTEROPERATOR] = unpack_UA_FilterOperator,
	[UA_TYPES_CONTENTFILTERELEMENT] = unpack_UA_ContentFilterElement,
	[UA_TYPES_CONTENTFILTER] = unpack_UA_ContentFilter,
	[UA_TYPES_FILTEROPERAND] = unpack_UA_FilterOperand,
	[UA_TYPES_ELEMENTOPERAND] = unpack_UA_ElementOperand,
	[UA_TYPES_LITERALOPERAND] = unpack_UA_LiteralOperand,
	[UA_TYPES_ATTRIBUTEOPERAND] = unpack_UA_AttributeOperand,
	[UA_TYPES_SIMPLEATTRIBUTEOPERAND] = unpack_UA_SimpleAttributeOperand,
	[UA_TYPES_CONTENTFILTERELEMENTRESULT] = unpack_UA_ContentFilterElementResult,
	[UA_TYPES_CONTENTFILTERRESULT] = unpack_UA_ContentFilterResult,
	[UA_TYPES_TIMESTAMPSTORETURN] = unpack_UA_TimestampsToReturn,
	[UA_TYPES_READVALUEID] = unpack_UA_ReadValueId,
	[UA_TYPES_READREQUEST] = unpack_UA_ReadRequest,
	[UA_TYPES_READRESPONSE] = unpack_UA_ReadResponse,
	[UA_TYPES_WRITEVALUE] = unpack_UA_WriteValue,
	[UA_TYPES_WRITEREQUEST] = unpack_UA_WriteRequest,
	[UA_TYPES_WRITERESPONSE] = unpack_UA_WriteResponse,
	[UA_TYPES_CALLMETHODREQUEST] = unpack_UA_CallMethodRequest,
	[UA_TYPES_CALLMETHODRESULT] = unpack_UA_CallMethodResult,
	[UA_TYPES_CALLREQUEST] = unpack_UA_CallRequest,
	[UA_TYPES_CALLRESPONSE] = unpack_UA_CallResponse,
	[UA_TYPES_MONITORINGMODE] = unpack_UA_MonitoringMode,
	[UA_TYPES_DATACHANGETRIGGER] = unpack_UA_DataChangeTrigger,
	[UA_TYPES_DEADBANDTYPE] = unpack_UA_DeadbandType,
	[UA_TYPES_DATACHANGEFILTER] = unpack_UA_DataChangeFilter,
	[UA_TYPES_EVENTFILTER] = unpack_UA_EventFilter,
	[UA_TYPES_AGGREGATECONFIGURATION] = unpack_UA_AggregateConfiguration,
	[UA_TYPES_AGGREGATEFILTER] = unpack_UA_AggregateFilter,
	[UA_TYPES_EVENTFILTERRESULT] = unpack_UA_EventFilterResult,
	[UA_TYPES_MONITORINGPARAMETERS] = unpack_UA_MonitoringParameters,
	[UA_TYPES_MONITOREDITEMCREATEREQUEST] = unpack_UA_MonitoredItemCreateRequest,
	[UA_TYPES_MONITOREDITEMCREATERESULT] = unpack_UA_MonitoredItemCreateResult,
	[UA_TYPES_CREATEMONITOREDITEMSREQUEST] = unpack_UA_CreateMonitoredItemsRequest,
	[UA_TYPES_CREATEMONITOREDITEMSRESPONSE] = unpack_UA_CreateMonitoredItemsResponse,
	[UA_TYPES_MONITOREDITEMMODIFYREQUEST] = unpack_UA_MonitoredItemModifyRequest,
	[UA_TYPES_MONITOREDITEMMODIFYRESULT] = unpack_UA_MonitoredItemModifyResult,
	[UA_TYPES_MODIFYMONITOREDITEMSREQUEST] = unpack_UA_ModifyMonitoredItemsRequest,
	[UA_TYPES_MODIFYMONITOREDITEMSRESPONSE] = unpack_UA_ModifyMonitoredItemsResponse,
	[UA_TYPES_SETMONITORINGMODEREQUEST] = unpack_UA_SetMonitoringModeRequest,
	[UA_TYPES_SETMONITORINGMODERESPONSE] = unpack_UA_SetMonitoringModeResponse,
	[UA_TYPES_SETTRIGGERINGREQUEST] = unpack_UA_SetTriggeringRequest,
	[UA_TYPES_SETTRIGGERINGRESPONSE] = unpack_UA_SetTriggeringResponse,
	[UA_TYPES_DELETEMONITOREDITEMSREQUEST] = unpack_UA_DeleteMonitoredItemsRequest,
	[UA_TYPES_DELETEMONITOREDITEMSRESPONSE] = unpack_UA_DeleteMonitoredItemsResponse,
	[UA_TYPES_CREATESUBSCRIPTIONREQUEST] = unpack_UA_CreateSubscriptionRequest,
	[UA_TYPES_CREATESUBSCRIPTIONRESPONSE] = unpack_UA_CreateSubscriptionResponse,
	[UA_TYPES_MODIFYSUBSCRIPTIONREQUEST] = unpack_UA_ModifySubscriptionRequest,
	[UA_TYPES_MODIFYSUBSCRIPTIONRESPONSE] = unpack_UA_ModifySubscriptionResponse,
	[UA_TYPES_SETPUBLISHINGMODEREQUEST] = unpack_UA_SetPublishingModeRequest,
	[UA_TYPES_SETPUBLISHINGMODERESPONSE] = unpack_UA_SetPublishingModeResponse,
	[UA_TYPES_NOTIFICATIONMESSAGE] = unpack_UA_NotificationMessage,
	[UA_TYPES_MONITOREDITEMNOTIFICATION] = unpack_UA_MonitoredItemNotification,
	[UA_TYPES_EVENTFIELDLIST] = unpack_UA_EventFieldList,
	[UA_TYPES_STATUSCHANGENOTIFICATION] = unpack_UA_StatusChangeNotification,
	[UA_TYPES_SUBSCRIPTIONACKNOWLEDGEMENT] = unpack_UA_SubscriptionAcknowledgement,
	[UA_TYPES_PUBLISHREQUEST] = unpack_UA_PublishRequest,
	[UA_TYPES_PUBLISHRESPONSE] = unpack_UA_PublishResponse,
	[UA_TYPES_REPUBLISHREQUEST] = unpack_UA_RepublishRequest,
	[UA_TYPES_REPUBLISHRESPONSE] = unpack_UA_RepublishResponse,
	[UA_TYPES_DELETESUBSCRIPTIONSREQUEST] = unpack_UA_DeleteSubscriptionsRequest,
	[UA_TYPES_DELETESUBSCRIPTIONSRESPONSE] = unpack_UA_DeleteSubscriptionsResponse,
	[UA_TYPES_BUILDINFO] = unpack_UA_BuildInfo,
	[UA_TYPES_REDUNDANCYSUPPORT] = unpack_UA_RedundancySupport,
	[UA_TYPES_SERVERSTATE] = unpack_UA_ServerState,
	[UA_TYPES_SERVERDIAGNOSTICSSUMMARYDATATYPE] = unpack_UA_ServerDiagnosticsSummaryDataType,
	[UA_TYPES_SERVERSTATUSDATATYPE] = unpack_UA_ServerStatusDataType,
	[UA_TYPES_RANGE] = unpack_UA_Range,
	[UA_TYPES_DATACHANGENOTIFICATION] = unpack_UA_DataChangeNotification,
	[UA_TYPES_EVENTNOTIFICATIONLIST] = unpack_UA_EventNotificationList,
};
static packed_UA pack_UA_table[UA_TYPES_COUNT] = {
	[UA_TYPES_BOOLEAN] = pack_UA_Boolean,
	[UA_TYPES_SBYTE] = pack_UA_SByte,
	[UA_TYPES_BYTE] = pack_UA_Byte,
	[UA_TYPES_INT16] = pack_UA_Int16,
	[UA_TYPES_UINT16] = pack_UA_UInt16,
	[UA_TYPES_INT32] = pack_UA_Int32,
	[UA_TYPES_UINT32] = pack_UA_UInt32,
	[UA_TYPES_INT64] = pack_UA_Int64,
	[UA_TYPES_UINT64] = pack_UA_UInt64,
	[UA_TYPES_FLOAT] = pack_UA_Float,
	[UA_TYPES_DOUBLE] = pack_UA_Double,
	[UA_TYPES_STRING] = pack_UA_String,
	[UA_TYPES_DATETIME] = pack_UA_DateTime,
	[UA_TYPES_GUID] = pack_UA_Guid,
	[UA_TYPES_BYTESTRING] = pack_UA_ByteString,
	[UA_TYPES_XMLELEMENT] = pack_UA_XmlElement,
	[UA_TYPES_NODEID] = pack_UA_NodeId,
	[UA_TYPES_EXPANDEDNODEID] = pack_UA_ExpandedNodeId,
	[UA_TYPES_STATUSCODE] = pack_UA_StatusCode,
	[UA_TYPES_QUALIFIEDNAME] = pack_UA_QualifiedName,
	[UA_TYPES_LOCALIZEDTEXT] = pack_UA_LocalizedText,
	[UA_TYPES_EXTENSIONOBJECT] = pack_UA_ExtensionObject,
	[UA_TYPES_DATAVALUE] = pack_UA_DataValue,
	[UA_TYPES_VARIANT] = pack_UA_Variant,
	[UA_TYPES_DIAGNOSTICINFO] = pack_UA_DiagnosticInfo,
	[UA_TYPES_NODECLASS] = pack_UA_NodeClass,
	[UA_TYPES_ARGUMENT] = pack_UA_Argument,
	[UA_TYPES_ENUMVALUETYPE] = pack_UA_EnumValueType,
	[UA_TYPES_DURATION] = pack_UA_Duration,
	[UA_TYPES_UTCTIME] = pack_UA_UtcTime,
	[UA_TYPES_LOCALEID] = pack_UA_LocaleId,
	[UA_TYPES_APPLICATIONTYPE] = pack_UA_ApplicationType,
	[UA_TYPES_APPLICATIONDESCRIPTION] = pack_UA_ApplicationDescription,
	[UA_TYPES_REQUESTHEADER] = pack_UA_RequestHeader,
	[UA_TYPES_RESPONSEHEADER] = pack_UA_ResponseHeader,
	[UA_TYPES_SERVICEFAULT] = pack_UA_ServiceFault,
	[UA_TYPES_FINDSERVERSREQUEST] = pack_UA_FindServersRequest,
	[UA_TYPES_FINDSERVERSRESPONSE] = pack_UA_FindServersResponse,
	[UA_TYPES_SERVERONNETWORK] = pack_UA_ServerOnNetwork,
	[UA_TYPES_FINDSERVERSONNETWORKREQUEST] = pack_UA_FindServersOnNetworkRequest,
	[UA_TYPES_FINDSERVERSONNETWORKRESPONSE] = pack_UA_FindServersOnNetworkResponse,
	[UA_TYPES_MESSAGESECURITYMODE] = pack_UA_MessageSecurityMode,
	[UA_TYPES_USERTOKENTYPE] = pack_UA_UserTokenType,
	[UA_TYPES_USERTOKENPOLICY] = pack_UA_UserTokenPolicy,
	[UA_TYPES_ENDPOINTDESCRIPTION] = pack_UA_EndpointDescription,
	[UA_TYPES_GETENDPOINTSREQUEST] = pack_UA_GetEndpointsRequest,
	[UA_TYPES_GETENDPOINTSRESPONSE] = pack_UA_GetEndpointsResponse,
	[UA_TYPES_REGISTEREDSERVER] = pack_UA_RegisteredServer,
	[UA_TYPES_REGISTERSERVERREQUEST] = pack_UA_RegisterServerRequest,
	[UA_TYPES_REGISTERSERVERRESPONSE] = pack_UA_RegisterServerResponse,
	[UA_TYPES_DISCOVERYCONFIGURATION] = pack_UA_DiscoveryConfiguration,
	[UA_TYPES_MDNSDISCOVERYCONFIGURATION] = pack_UA_MdnsDiscoveryConfiguration,
	[UA_TYPES_REGISTERSERVER2REQUEST] = pack_UA_RegisterServer2Request,
	[UA_TYPES_REGISTERSERVER2RESPONSE] = pack_UA_RegisterServer2Response,
	[UA_TYPES_SECURITYTOKENREQUESTTYPE] = pack_UA_SecurityTokenRequestType,
	[UA_TYPES_CHANNELSECURITYTOKEN] = pack_UA_ChannelSecurityToken,
	[UA_TYPES_OPENSECURECHANNELREQUEST] = pack_UA_OpenSecureChannelRequest,
	[UA_TYPES_OPENSECURECHANNELRESPONSE] = pack_UA_OpenSecureChannelResponse,
	[UA_TYPES_CLOSESECURECHANNELREQUEST] = pack_UA_CloseSecureChannelRequest,
	[UA_TYPES_CLOSESECURECHANNELRESPONSE] = pack_UA_CloseSecureChannelResponse,
	[UA_TYPES_SIGNEDSOFTWARECERTIFICATE] = pack_UA_SignedSoftwareCertificate,
	[UA_TYPES_SIGNATUREDATA] = pack_UA_SignatureData,
	[UA_TYPES_CREATESESSIONREQUEST] = pack_UA_CreateSessionRequest,
	[UA_TYPES_CREATESESSIONRESPONSE] = pack_UA_CreateSessionResponse,
	[UA_TYPES_USERIDENTITYTOKEN] = pack_UA_UserIdentityToken,
	[UA_TYPES_ANONYMOUSIDENTITYTOKEN] = pack_UA_AnonymousIdentityToken,
	[UA_TYPES_USERNAMEIDENTITYTOKEN] = pack_UA_UserNameIdentityToken,
	[UA_TYPES_X509IDENTITYTOKEN] = pack_UA_X509IdentityToken,
	[UA_TYPES_ISSUEDIDENTITYTOKEN] = pack_UA_IssuedIdentityToken,
	[UA_TYPES_ACTIVATESESSIONREQUEST] = pack_UA_ActivateSessionRequest,
	[UA_TYPES_ACTIVATESESSIONRESPONSE] = pack_UA_ActivateSessionResponse,
	[UA_TYPES_CLOSESESSIONREQUEST] = pack_UA_CloseSessionRequest,
	[UA_TYPES_CLOSESESSIONRESPONSE] = pack_UA_CloseSessionResponse,
	[UA_TYPES_NODEATTRIBUTESMASK] = pack_UA_NodeAttributesMask,
	[UA_TYPES_NODEATTRIBUTES] = pack_UA_NodeAttributes,
	[UA_TYPES_OBJECTATTRIBUTES] = pack_UA_ObjectAttributes,
	[UA_TYPES_VARIABLEATTRIBUTES] = pack_UA_VariableAttributes,
	[UA_TYPES_METHODATTRIBUTES] = pack_UA_MethodAttributes,
	[UA_TYPES_OBJECTTYPEATTRIBUTES] = pack_UA_ObjectTypeAttributes,
	[UA_TYPES_VARIABLETYPEATTRIBUTES] = pack_UA_VariableTypeAttributes,
	[UA_TYPES_REFERENCETYPEATTRIBUTES] = pack_UA_ReferenceTypeAttributes,
	[UA_TYPES_DATATYPEATTRIBUTES] = pack_UA_DataTypeAttributes,
	[UA_TYPES_VIEWATTRIBUTES] = pack_UA_ViewAttributes,
	[UA_TYPES_ADDNODESITEM] = pack_UA_AddNodesItem,
	[UA_TYPES_ADDNODESRESULT] = pack_UA_AddNodesResult,
	[UA_TYPES_ADDNODESREQUEST] = pack_UA_AddNodesRequest,
	[UA_TYPES_ADDNODESRESPONSE] = pack_UA_AddNodesResponse,
	[UA_TYPES_ADDREFERENCESITEM] = pack_UA_AddReferencesItem,
	[UA_TYPES_ADDREFERENCESREQUEST] = pack_UA_AddReferencesRequest,
	[UA_TYPES_ADDREFERENCESRESPONSE] = pack_UA_AddReferencesResponse,
	[UA_TYPES_DELETENODESITEM] = pack_UA_DeleteNodesItem,
	[UA_TYPES_DELETENODESREQUEST] = pack_UA_DeleteNodesRequest,
	[UA_TYPES_DELETENODESRESPONSE] = pack_UA_DeleteNodesResponse,
	[UA_TYPES_DELETEREFERENCESITEM] = pack_UA_DeleteReferencesItem,
	[UA_TYPES_DELETEREFERENCESREQUEST] = pack_UA_DeleteReferencesRequest,
	[UA_TYPES_DELETEREFERENCESRESPONSE] = pack_UA_DeleteReferencesResponse,
	[UA_TYPES_BROWSEDIRECTION] = pack_UA_BrowseDirection,
	[UA_TYPES_VIEWDESCRIPTION] = pack_UA_ViewDescription,
	[UA_TYPES_BROWSEDESCRIPTION] = pack_UA_BrowseDescription,
	[UA_TYPES_BROWSERESULTMASK] = pack_UA_BrowseResultMask,
	[UA_TYPES_REFERENCEDESCRIPTION] = pack_UA_ReferenceDescription,
	[UA_TYPES_BROWSERESULT] = pack_UA_BrowseResult,
	[UA_TYPES_BROWSEREQUEST] = pack_UA_BrowseRequest,
	[UA_TYPES_BROWSERESPONSE] = pack_UA_BrowseResponse,
	[UA_TYPES_BROWSENEXTREQUEST] = pack_UA_BrowseNextRequest,
	[UA_TYPES_BROWSENEXTRESPONSE] = pack_UA_BrowseNextResponse,
	[UA_TYPES_RELATIVEPATHELEMENT] = pack_UA_RelativePathElement,
	[UA_TYPES_RELATIVEPATH] = pack_UA_RelativePath,
	[UA_TYPES_BROWSEPATH] = pack_UA_BrowsePath,
	[UA_TYPES_BROWSEPATHTARGET] = pack_UA_BrowsePathTarget,
	[UA_TYPES_BROWSEPATHRESULT] = pack_UA_BrowsePathResult,
	[UA_TYPES_TRANSLATEBROWSEPATHSTONODEIDSREQUEST] = pack_UA_TranslateBrowsePathsToNodeIdsRequest,
	[UA_TYPES_TRANSLATEBROWSEPATHSTONODEIDSRESPONSE] = pack_UA_TranslateBrowsePathsToNodeIdsResponse,
	[UA_TYPES_REGISTERNODESREQUEST] = pack_UA_RegisterNodesRequest,
	[UA_TYPES_REGISTERNODESRESPONSE] = pack_UA_RegisterNodesResponse,
	[UA_TYPES_UNREGISTERNODESREQUEST] = pack_UA_UnregisterNodesRequest,
	[UA_TYPES_UNREGISTERNODESRESPONSE] = pack_UA_UnregisterNodesResponse,
	[UA_TYPES_FILTEROPERATOR] = pack_UA_FilterOperator,
	[UA_TYPES_CONTENTFILTERELEMENT] = pack_UA_ContentFilterElement,
	[UA_TYPES_CONTENTFILTER] = pack_UA_ContentFilter,
	[UA_TYPES_FILTEROPERAND] = pack_UA_FilterOperand,
	[UA_TYPES_ELEMENTOPERAND] = pack_UA_ElementOperand,
	[UA_TYPES_LITERALOPERAND] = pack_UA_LiteralOperand,
	[UA_TYPES_ATTRIBUTEOPERAND] = pack_UA_AttributeOperand,
	[UA_TYPES_SIMPLEATTRIBUTEOPERAND] = pack_UA_SimpleAttributeOperand,
	[UA_TYPES_CONTENTFILTERELEMENTRESULT] = pack_UA_ContentFilterElementResult,
	[UA_TYPES_CONTENTFILTERRESULT] = pack_UA_ContentFilterResult,
	[UA_TYPES_TIMESTAMPSTORETURN] = pack_UA_TimestampsToReturn,
	[UA_TYPES_READVALUEID] = pack_UA_ReadValueId,
	[UA_TYPES_READREQUEST] = pack_UA_ReadRequest,
	[UA_TYPES_READRESPONSE] = pack_UA_ReadResponse,
	[UA_TYPES_WRITEVALUE] = pack_UA_WriteValue,
	[UA_TYPES_WRITEREQUEST] = pack_UA_WriteRequest,
	[UA_TYPES_WRITERESPONSE] = pack_UA_WriteResponse,
	[UA_TYPES_CALLMETHODREQUEST] = pack_UA_CallMethodRequest,
	[UA_TYPES_CALLMETHODRESULT] = pack_UA_CallMethodResult,
	[UA_TYPES_CALLREQUEST] = pack_UA_CallRequest,
	[UA_TYPES_CALLRESPONSE] = pack_UA_CallResponse,
	[UA_TYPES_MONITORINGMODE] = pack_UA_MonitoringMode,
	[UA_TYPES_DATACHANGETRIGGER] = pack_UA_DataChangeTrigger,
	[UA_TYPES_DEADBANDTYPE] = pack_UA_DeadbandType,
	[UA_TYPES_DATACHANGEFILTER] = pack_UA_DataChangeFilter,
	[UA_TYPES_EVENTFILTER] = pack_UA_EventFilter,
	[UA_TYPES_AGGREGATECONFIGURATION] = pack_UA_AggregateConfiguration,
	[UA_TYPES_AGGREGATEFILTER] = pack_UA_AggregateFilter,
	[UA_TYPES_EVENTFILTERRESULT] = pack_UA_EventFilterResult,
	[UA_TYPES_MONITORINGPARAMETERS] = pack_UA_MonitoringParameters,
	[UA_TYPES_MONITOREDITEMCREATEREQUEST] = pack_UA_MonitoredItemCreateRequest,
	[UA_TYPES_MONITOREDITEMCREATERESULT] = pack_UA_MonitoredItemCreateResult,
	[UA_TYPES_CREATEMONITOREDITEMSREQUEST] = pack_UA_CreateMonitoredItemsRequest,
	[UA_TYPES_CREATEMONITOREDITEMSRESPONSE] = pack_UA_CreateMonitoredItemsResponse,
	[UA_TYPES_MONITOREDITEMMODIFYREQUEST] = pack_UA_MonitoredItemModifyRequest,
	[UA_TYPES_MONITOREDITEMMODIFYRESULT] = pack_UA_MonitoredItemModifyResult,
	[UA_TYPES_MODIFYMONITOREDITEMSREQUEST] = pack_UA_ModifyMonitoredItemsRequest,
	[UA_TYPES_MODIFYMONITOREDITEMSRESPONSE] = pack_UA_ModifyMonitoredItemsResponse,
	[UA_TYPES_SETMONITORINGMODEREQUEST] = pack_UA_SetMonitoringModeRequest,
	[UA_TYPES_SETMONITORINGMODERESPONSE] = pack_UA_SetMonitoringModeResponse,
	[UA_TYPES_SETTRIGGERINGREQUEST] = pack_UA_SetTriggeringRequest,
	[UA_TYPES_SETTRIGGERINGRESPONSE] = pack_UA_SetTriggeringResponse,
	[UA_TYPES_DELETEMONITOREDITEMSREQUEST] = pack_UA_DeleteMonitoredItemsRequest,
	[UA_TYPES_DELETEMONITOREDITEMSRESPONSE] = pack_UA_DeleteMonitoredItemsResponse,
	[UA_TYPES_CREATESUBSCRIPTIONREQUEST] = pack_UA_CreateSubscriptionRequest,
	[UA_TYPES_CREATESUBSCRIPTIONRESPONSE] = pack_UA_CreateSubscriptionResponse,
	[UA_TYPES_MODIFYSUBSCRIPTIONREQUEST] = pack_UA_ModifySubscriptionRequest,
	[UA_TYPES_MODIFYSUBSCRIPTIONRESPONSE] = pack_UA_ModifySubscriptionResponse,
	[UA_TYPES_SETPUBLISHINGMODEREQUEST] = pack_UA_SetPublishingModeRequest,
	[UA_TYPES_SETPUBLISHINGMODERESPONSE] = pack_UA_SetPublishingModeResponse,
	[UA_TYPES_NOTIFICATIONMESSAGE] = pack_UA_NotificationMessage,
	[UA_TYPES_MONITOREDITEMNOTIFICATION] = pack_UA_MonitoredItemNotification,
	[UA_TYPES_EVENTFIELDLIST] = pack_UA_EventFieldList,
	[UA_TYPES_STATUSCHANGENOTIFICATION] = pack_UA_StatusChangeNotification,
	[UA_TYPES_SUBSCRIPTIONACKNOWLEDGEMENT] = pack_UA_SubscriptionAcknowledgement,
	[UA_TYPES_PUBLISHREQUEST] = pack_UA_PublishRequest,
	[UA_TYPES_PUBLISHRESPONSE] = pack_UA_PublishResponse,
	[UA_TYPES_REPUBLISHREQUEST] = pack_UA_RepublishRequest,
	[UA_TYPES_REPUBLISHRESPONSE] = pack_UA_RepublishResponse,
	[UA_TYPES_DELETESUBSCRIPTIONSREQUEST] = pack_UA_DeleteSubscriptionsRequest,
	[UA_TYPES_DELETESUBSCRIPTIONSRESPONSE] = pack_UA_DeleteSubscriptionsResponse,
	[UA_TYPES_BUILDINFO] = pack_UA_BuildInfo,
	[UA_TYPES_REDUNDANCYSUPPORT] = pack_UA_RedundancySupport,
	[UA_TYPES_SERVERSTATE] = pack_UA_ServerState,
	[UA_TYPES_SERVERDIAGNOSTICSSUMMARYDATATYPE] = pack_UA_ServerDiagnosticsSummaryDataType,
	[UA_TYPES_SERVERSTATUSDATATYPE] = pack_UA_ServerStatusDataType,
	[UA_TYPES_RANGE] = pack_UA_Range,
	[UA_TYPES_DATACHANGENOTIFICATION] = pack_UA_DataChangeNotification,
	[UA_TYPES_EVENTNOTIFICATIONLIST] = pack_UA_EventNotificationList,
};
