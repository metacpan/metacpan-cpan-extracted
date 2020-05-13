/* Boolean */
static void XS_pack_UA_Boolean(SV *out, UA_Boolean in)  __attribute__((unused));
static UA_Boolean XS_unpack_UA_Boolean(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* SByte */
static void XS_pack_UA_SByte(SV *out, UA_SByte in)  __attribute__((unused));
static UA_SByte XS_unpack_UA_SByte(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* Byte */
static void XS_pack_UA_Byte(SV *out, UA_Byte in)  __attribute__((unused));
static UA_Byte XS_unpack_UA_Byte(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* Int16 */
static void XS_pack_UA_Int16(SV *out, UA_Int16 in)  __attribute__((unused));
static UA_Int16 XS_unpack_UA_Int16(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* UInt16 */
static void XS_pack_UA_UInt16(SV *out, UA_UInt16 in)  __attribute__((unused));
static UA_UInt16 XS_unpack_UA_UInt16(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* Int32 */
static void XS_pack_UA_Int32(SV *out, UA_Int32 in)  __attribute__((unused));
static UA_Int32 XS_unpack_UA_Int32(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* UInt32 */
static void XS_pack_UA_UInt32(SV *out, UA_UInt32 in)  __attribute__((unused));
static UA_UInt32 XS_unpack_UA_UInt32(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* Int64 */
static void XS_pack_UA_Int64(SV *out, UA_Int64 in)  __attribute__((unused));
static UA_Int64 XS_unpack_UA_Int64(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* UInt64 */
static void XS_pack_UA_UInt64(SV *out, UA_UInt64 in)  __attribute__((unused));
static UA_UInt64 XS_unpack_UA_UInt64(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* Float */
static void XS_pack_UA_Float(SV *out, UA_Float in)  __attribute__((unused));
static UA_Float XS_unpack_UA_Float(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* Double */
static void XS_pack_UA_Double(SV *out, UA_Double in)  __attribute__((unused));
static UA_Double XS_unpack_UA_Double(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* String */
static void XS_pack_UA_String(SV *out, UA_String in)  __attribute__((unused));
static UA_String XS_unpack_UA_String(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* DateTime */
static void XS_pack_UA_DateTime(SV *out, UA_DateTime in)  __attribute__((unused));
static UA_DateTime XS_unpack_UA_DateTime(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* Guid */
static void XS_pack_UA_Guid(SV *out, UA_Guid in)  __attribute__((unused));
static UA_Guid XS_unpack_UA_Guid(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* ByteString */
static void XS_pack_UA_ByteString(SV *out, UA_ByteString in)  __attribute__((unused));
static UA_ByteString XS_unpack_UA_ByteString(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* XmlElement */
static void XS_pack_UA_XmlElement(SV *out, UA_XmlElement in)  __attribute__((unused));
static UA_XmlElement XS_unpack_UA_XmlElement(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* NodeId */
static void XS_pack_UA_NodeId(SV *out, UA_NodeId in)  __attribute__((unused));
static UA_NodeId XS_unpack_UA_NodeId(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* ExpandedNodeId */
static void XS_pack_UA_ExpandedNodeId(SV *out, UA_ExpandedNodeId in)  __attribute__((unused));
static UA_ExpandedNodeId XS_unpack_UA_ExpandedNodeId(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* StatusCode */
static void XS_pack_UA_StatusCode(SV *out, UA_StatusCode in)  __attribute__((unused));
static UA_StatusCode XS_unpack_UA_StatusCode(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* QualifiedName */
static void XS_pack_UA_QualifiedName(SV *out, UA_QualifiedName in)  __attribute__((unused));
static UA_QualifiedName XS_unpack_UA_QualifiedName(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* LocalizedText */
static void XS_pack_UA_LocalizedText(SV *out, UA_LocalizedText in)  __attribute__((unused));
static UA_LocalizedText XS_unpack_UA_LocalizedText(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* ExtensionObject */
static void XS_pack_UA_ExtensionObject(SV *out, UA_ExtensionObject in)  __attribute__((unused));
static UA_ExtensionObject XS_unpack_UA_ExtensionObject(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* DataValue */
static void XS_pack_UA_DataValue(SV *out, UA_DataValue in)  __attribute__((unused));
static UA_DataValue XS_unpack_UA_DataValue(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* Variant */
static void XS_pack_UA_Variant(SV *out, UA_Variant in)  __attribute__((unused));
static UA_Variant XS_unpack_UA_Variant(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* DiagnosticInfo */
static void XS_pack_UA_DiagnosticInfo(SV *out, UA_DiagnosticInfo in)  __attribute__((unused));
static UA_DiagnosticInfo XS_unpack_UA_DiagnosticInfo(SV *in)  __attribute__((unused));
/* implemented in Open62541.xs */

/* NodeClass */
static void XS_pack_UA_NodeClass(SV *out, UA_NodeClass in)  __attribute__((unused));
static void
XS_pack_UA_NodeClass(SV *out, UA_NodeClass in)
{
	dTHX;
	sv_setiv(out, in);
}

static UA_NodeClass XS_unpack_UA_NodeClass(SV *in)  __attribute__((unused));
static UA_NodeClass
XS_unpack_UA_NodeClass(SV *in)
{
	dTHX;
	return SvIV(in);
}

/* Argument */
static void XS_pack_UA_Argument(SV *out, UA_Argument in)  __attribute__((unused));
static void
XS_pack_UA_Argument(SV *out, UA_Argument in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_String(sv, in.name);
	hv_stores(hv, "Argument_name", sv);

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.dataType);
	hv_stores(hv, "Argument_dataType", sv);

	sv = newSV(0);
	XS_pack_UA_Int32(sv, in.valueRank);
	hv_stores(hv, "Argument_valueRank", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.arrayDimensionsSize);
	for (i = 0; i < in.arrayDimensionsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_UInt32(sv, in.arrayDimensions[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "Argument_arrayDimensions", newRV_inc((SV*)av));

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.description);
	hv_stores(hv, "Argument_description", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_Argument XS_unpack_UA_Argument(SV *in)  __attribute__((unused));
static UA_Argument
XS_unpack_UA_Argument(SV *in)
{
	dTHX;
	UA_Argument out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_Argument_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "Argument_name", 0);
	if (svp != NULL)
		out.name = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "Argument_dataType", 0);
	if (svp != NULL)
		out.dataType = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "Argument_valueRank", 0);
	if (svp != NULL)
		out.valueRank = XS_unpack_UA_Int32(*svp);

	svp = hv_fetchs(hv, "Argument_arrayDimensions", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for Argument_arrayDimensions");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.arrayDimensions = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out.arrayDimensions == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.arrayDimensions[i] = XS_unpack_UA_UInt32(*svp);
			}
		}
		out.arrayDimensionsSize = i;
	}

	svp = hv_fetchs(hv, "Argument_description", 0);
	if (svp != NULL)
		out.description = XS_unpack_UA_LocalizedText(*svp);

	return out;
}

/* EnumValueType */
static void XS_pack_UA_EnumValueType(SV *out, UA_EnumValueType in)  __attribute__((unused));
static void
XS_pack_UA_EnumValueType(SV *out, UA_EnumValueType in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_Int64(sv, in.value);
	hv_stores(hv, "EnumValueType_value", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.displayName);
	hv_stores(hv, "EnumValueType_displayName", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.description);
	hv_stores(hv, "EnumValueType_description", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_EnumValueType XS_unpack_UA_EnumValueType(SV *in)  __attribute__((unused));
static UA_EnumValueType
XS_unpack_UA_EnumValueType(SV *in)
{
	dTHX;
	UA_EnumValueType out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_EnumValueType_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EnumValueType_value", 0);
	if (svp != NULL)
		out.value = XS_unpack_UA_Int64(*svp);

	svp = hv_fetchs(hv, "EnumValueType_displayName", 0);
	if (svp != NULL)
		out.displayName = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "EnumValueType_description", 0);
	if (svp != NULL)
		out.description = XS_unpack_UA_LocalizedText(*svp);

	return out;
}

/* Duration */
static void XS_pack_UA_Duration(SV *out, UA_Duration in)  __attribute__((unused));
static void
XS_pack_UA_Duration(SV *out, UA_Duration in)
{
	dTHX;
	XS_pack_UA_Double(out, in);
}

static UA_Duration XS_unpack_UA_Duration(SV *in)  __attribute__((unused));
static UA_Duration
XS_unpack_UA_Duration(SV *in)
{
	dTHX;
	return XS_unpack_UA_Double(in);
}

/* UtcTime */
static void XS_pack_UA_UtcTime(SV *out, UA_UtcTime in)  __attribute__((unused));
static void
XS_pack_UA_UtcTime(SV *out, UA_UtcTime in)
{
	dTHX;
	XS_pack_UA_DateTime(out, in);
}

static UA_UtcTime XS_unpack_UA_UtcTime(SV *in)  __attribute__((unused));
static UA_UtcTime
XS_unpack_UA_UtcTime(SV *in)
{
	dTHX;
	return XS_unpack_UA_DateTime(in);
}

/* LocaleId */
static void XS_pack_UA_LocaleId(SV *out, UA_LocaleId in)  __attribute__((unused));
static void
XS_pack_UA_LocaleId(SV *out, UA_LocaleId in)
{
	dTHX;
	XS_pack_UA_String(out, in);
}

static UA_LocaleId XS_unpack_UA_LocaleId(SV *in)  __attribute__((unused));
static UA_LocaleId
XS_unpack_UA_LocaleId(SV *in)
{
	dTHX;
	return XS_unpack_UA_String(in);
}

/* ApplicationType */
static void XS_pack_UA_ApplicationType(SV *out, UA_ApplicationType in)  __attribute__((unused));
static void
XS_pack_UA_ApplicationType(SV *out, UA_ApplicationType in)
{
	dTHX;
	sv_setiv(out, in);
}

static UA_ApplicationType XS_unpack_UA_ApplicationType(SV *in)  __attribute__((unused));
static UA_ApplicationType
XS_unpack_UA_ApplicationType(SV *in)
{
	dTHX;
	return SvIV(in);
}

/* ApplicationDescription */
static void XS_pack_UA_ApplicationDescription(SV *out, UA_ApplicationDescription in)  __attribute__((unused));
static void
XS_pack_UA_ApplicationDescription(SV *out, UA_ApplicationDescription in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_String(sv, in.applicationUri);
	hv_stores(hv, "ApplicationDescription_applicationUri", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.productUri);
	hv_stores(hv, "ApplicationDescription_productUri", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.applicationName);
	hv_stores(hv, "ApplicationDescription_applicationName", sv);

	sv = newSV(0);
	XS_pack_UA_ApplicationType(sv, in.applicationType);
	hv_stores(hv, "ApplicationDescription_applicationType", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.gatewayServerUri);
	hv_stores(hv, "ApplicationDescription_gatewayServerUri", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.discoveryProfileUri);
	hv_stores(hv, "ApplicationDescription_discoveryProfileUri", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.discoveryUrlsSize);
	for (i = 0; i < in.discoveryUrlsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_String(sv, in.discoveryUrls[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ApplicationDescription_discoveryUrls", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ApplicationDescription XS_unpack_UA_ApplicationDescription(SV *in)  __attribute__((unused));
static UA_ApplicationDescription
XS_unpack_UA_ApplicationDescription(SV *in)
{
	dTHX;
	UA_ApplicationDescription out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ApplicationDescription_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ApplicationDescription_applicationUri", 0);
	if (svp != NULL)
		out.applicationUri = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "ApplicationDescription_productUri", 0);
	if (svp != NULL)
		out.productUri = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "ApplicationDescription_applicationName", 0);
	if (svp != NULL)
		out.applicationName = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "ApplicationDescription_applicationType", 0);
	if (svp != NULL)
		out.applicationType = XS_unpack_UA_ApplicationType(*svp);

	svp = hv_fetchs(hv, "ApplicationDescription_gatewayServerUri", 0);
	if (svp != NULL)
		out.gatewayServerUri = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "ApplicationDescription_discoveryProfileUri", 0);
	if (svp != NULL)
		out.discoveryProfileUri = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "ApplicationDescription_discoveryUrls", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ApplicationDescription_discoveryUrls");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.discoveryUrls = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out.discoveryUrls == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.discoveryUrls[i] = XS_unpack_UA_String(*svp);
			}
		}
		out.discoveryUrlsSize = i;
	}

	return out;
}

/* RequestHeader */
static void XS_pack_UA_RequestHeader(SV *out, UA_RequestHeader in)  __attribute__((unused));
static void
XS_pack_UA_RequestHeader(SV *out, UA_RequestHeader in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.authenticationToken);
	hv_stores(hv, "RequestHeader_authenticationToken", sv);

	sv = newSV(0);
	XS_pack_UA_DateTime(sv, in.timestamp);
	hv_stores(hv, "RequestHeader_timestamp", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.requestHandle);
	hv_stores(hv, "RequestHeader_requestHandle", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.returnDiagnostics);
	hv_stores(hv, "RequestHeader_returnDiagnostics", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.auditEntryId);
	hv_stores(hv, "RequestHeader_auditEntryId", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.timeoutHint);
	hv_stores(hv, "RequestHeader_timeoutHint", sv);

	sv = newSV(0);
	XS_pack_UA_ExtensionObject(sv, in.additionalHeader);
	hv_stores(hv, "RequestHeader_additionalHeader", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_RequestHeader XS_unpack_UA_RequestHeader(SV *in)  __attribute__((unused));
static UA_RequestHeader
XS_unpack_UA_RequestHeader(SV *in)
{
	dTHX;
	UA_RequestHeader out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_RequestHeader_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RequestHeader_authenticationToken", 0);
	if (svp != NULL)
		out.authenticationToken = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "RequestHeader_timestamp", 0);
	if (svp != NULL)
		out.timestamp = XS_unpack_UA_DateTime(*svp);

	svp = hv_fetchs(hv, "RequestHeader_requestHandle", 0);
	if (svp != NULL)
		out.requestHandle = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "RequestHeader_returnDiagnostics", 0);
	if (svp != NULL)
		out.returnDiagnostics = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "RequestHeader_auditEntryId", 0);
	if (svp != NULL)
		out.auditEntryId = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "RequestHeader_timeoutHint", 0);
	if (svp != NULL)
		out.timeoutHint = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "RequestHeader_additionalHeader", 0);
	if (svp != NULL)
		out.additionalHeader = XS_unpack_UA_ExtensionObject(*svp);

	return out;
}

/* ResponseHeader */
static void XS_pack_UA_ResponseHeader(SV *out, UA_ResponseHeader in)  __attribute__((unused));
static void
XS_pack_UA_ResponseHeader(SV *out, UA_ResponseHeader in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_DateTime(sv, in.timestamp);
	hv_stores(hv, "ResponseHeader_timestamp", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.requestHandle);
	hv_stores(hv, "ResponseHeader_requestHandle", sv);

	sv = newSV(0);
	XS_pack_UA_StatusCode(sv, in.serviceResult);
	hv_stores(hv, "ResponseHeader_serviceResult", sv);

	sv = newSV(0);
	XS_pack_UA_DiagnosticInfo(sv, in.serviceDiagnostics);
	hv_stores(hv, "ResponseHeader_serviceDiagnostics", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.stringTableSize);
	for (i = 0; i < in.stringTableSize; i++) {
		sv = newSV(0);
		XS_pack_UA_String(sv, in.stringTable[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ResponseHeader_stringTable", newRV_inc((SV*)av));

	sv = newSV(0);
	XS_pack_UA_ExtensionObject(sv, in.additionalHeader);
	hv_stores(hv, "ResponseHeader_additionalHeader", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ResponseHeader XS_unpack_UA_ResponseHeader(SV *in)  __attribute__((unused));
static UA_ResponseHeader
XS_unpack_UA_ResponseHeader(SV *in)
{
	dTHX;
	UA_ResponseHeader out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ResponseHeader_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ResponseHeader_timestamp", 0);
	if (svp != NULL)
		out.timestamp = XS_unpack_UA_DateTime(*svp);

	svp = hv_fetchs(hv, "ResponseHeader_requestHandle", 0);
	if (svp != NULL)
		out.requestHandle = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ResponseHeader_serviceResult", 0);
	if (svp != NULL)
		out.serviceResult = XS_unpack_UA_StatusCode(*svp);

	svp = hv_fetchs(hv, "ResponseHeader_serviceDiagnostics", 0);
	if (svp != NULL)
		out.serviceDiagnostics = XS_unpack_UA_DiagnosticInfo(*svp);

	svp = hv_fetchs(hv, "ResponseHeader_stringTable", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ResponseHeader_stringTable");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.stringTable = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out.stringTable == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.stringTable[i] = XS_unpack_UA_String(*svp);
			}
		}
		out.stringTableSize = i;
	}

	svp = hv_fetchs(hv, "ResponseHeader_additionalHeader", 0);
	if (svp != NULL)
		out.additionalHeader = XS_unpack_UA_ExtensionObject(*svp);

	return out;
}

/* ServiceFault */
static void XS_pack_UA_ServiceFault(SV *out, UA_ServiceFault in)  __attribute__((unused));
static void
XS_pack_UA_ServiceFault(SV *out, UA_ServiceFault in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "ServiceFault_responseHeader", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ServiceFault XS_unpack_UA_ServiceFault(SV *in)  __attribute__((unused));
static UA_ServiceFault
XS_unpack_UA_ServiceFault(SV *in)
{
	dTHX;
	UA_ServiceFault out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ServiceFault_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ServiceFault_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	return out;
}

/* FindServersRequest */
static void XS_pack_UA_FindServersRequest(SV *out, UA_FindServersRequest in)  __attribute__((unused));
static void
XS_pack_UA_FindServersRequest(SV *out, UA_FindServersRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "FindServersRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.endpointUrl);
	hv_stores(hv, "FindServersRequest_endpointUrl", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.localeIdsSize);
	for (i = 0; i < in.localeIdsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_String(sv, in.localeIds[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "FindServersRequest_localeIds", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.serverUrisSize);
	for (i = 0; i < in.serverUrisSize; i++) {
		sv = newSV(0);
		XS_pack_UA_String(sv, in.serverUris[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "FindServersRequest_serverUris", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_FindServersRequest XS_unpack_UA_FindServersRequest(SV *in)  __attribute__((unused));
static UA_FindServersRequest
XS_unpack_UA_FindServersRequest(SV *in)
{
	dTHX;
	UA_FindServersRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_FindServersRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "FindServersRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "FindServersRequest_endpointUrl", 0);
	if (svp != NULL)
		out.endpointUrl = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "FindServersRequest_localeIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for FindServersRequest_localeIds");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.localeIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out.localeIds == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.localeIds[i] = XS_unpack_UA_String(*svp);
			}
		}
		out.localeIdsSize = i;
	}

	svp = hv_fetchs(hv, "FindServersRequest_serverUris", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for FindServersRequest_serverUris");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.serverUris = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out.serverUris == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.serverUris[i] = XS_unpack_UA_String(*svp);
			}
		}
		out.serverUrisSize = i;
	}

	return out;
}

/* FindServersResponse */
static void XS_pack_UA_FindServersResponse(SV *out, UA_FindServersResponse in)  __attribute__((unused));
static void
XS_pack_UA_FindServersResponse(SV *out, UA_FindServersResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "FindServersResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.serversSize);
	for (i = 0; i < in.serversSize; i++) {
		sv = newSV(0);
		XS_pack_UA_ApplicationDescription(sv, in.servers[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "FindServersResponse_servers", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_FindServersResponse XS_unpack_UA_FindServersResponse(SV *in)  __attribute__((unused));
static UA_FindServersResponse
XS_unpack_UA_FindServersResponse(SV *in)
{
	dTHX;
	UA_FindServersResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_FindServersResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "FindServersResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "FindServersResponse_servers", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for FindServersResponse_servers");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.servers = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_APPLICATIONDESCRIPTION]);
		if (out.servers == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.servers[i] = XS_unpack_UA_ApplicationDescription(*svp);
			}
		}
		out.serversSize = i;
	}

	return out;
}

/* ServerOnNetwork */
static void XS_pack_UA_ServerOnNetwork(SV *out, UA_ServerOnNetwork in)  __attribute__((unused));
static void
XS_pack_UA_ServerOnNetwork(SV *out, UA_ServerOnNetwork in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.recordId);
	hv_stores(hv, "ServerOnNetwork_recordId", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.serverName);
	hv_stores(hv, "ServerOnNetwork_serverName", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.discoveryUrl);
	hv_stores(hv, "ServerOnNetwork_discoveryUrl", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.serverCapabilitiesSize);
	for (i = 0; i < in.serverCapabilitiesSize; i++) {
		sv = newSV(0);
		XS_pack_UA_String(sv, in.serverCapabilities[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ServerOnNetwork_serverCapabilities", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ServerOnNetwork XS_unpack_UA_ServerOnNetwork(SV *in)  __attribute__((unused));
static UA_ServerOnNetwork
XS_unpack_UA_ServerOnNetwork(SV *in)
{
	dTHX;
	UA_ServerOnNetwork out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ServerOnNetwork_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ServerOnNetwork_recordId", 0);
	if (svp != NULL)
		out.recordId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ServerOnNetwork_serverName", 0);
	if (svp != NULL)
		out.serverName = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "ServerOnNetwork_discoveryUrl", 0);
	if (svp != NULL)
		out.discoveryUrl = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "ServerOnNetwork_serverCapabilities", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ServerOnNetwork_serverCapabilities");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.serverCapabilities = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out.serverCapabilities == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.serverCapabilities[i] = XS_unpack_UA_String(*svp);
			}
		}
		out.serverCapabilitiesSize = i;
	}

	return out;
}

/* FindServersOnNetworkRequest */
static void XS_pack_UA_FindServersOnNetworkRequest(SV *out, UA_FindServersOnNetworkRequest in)  __attribute__((unused));
static void
XS_pack_UA_FindServersOnNetworkRequest(SV *out, UA_FindServersOnNetworkRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "FindServersOnNetworkRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.startingRecordId);
	hv_stores(hv, "FindServersOnNetworkRequest_startingRecordId", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.maxRecordsToReturn);
	hv_stores(hv, "FindServersOnNetworkRequest_maxRecordsToReturn", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.serverCapabilityFilterSize);
	for (i = 0; i < in.serverCapabilityFilterSize; i++) {
		sv = newSV(0);
		XS_pack_UA_String(sv, in.serverCapabilityFilter[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "FindServersOnNetworkRequest_serverCapabilityFilter", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_FindServersOnNetworkRequest XS_unpack_UA_FindServersOnNetworkRequest(SV *in)  __attribute__((unused));
static UA_FindServersOnNetworkRequest
XS_unpack_UA_FindServersOnNetworkRequest(SV *in)
{
	dTHX;
	UA_FindServersOnNetworkRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_FindServersOnNetworkRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "FindServersOnNetworkRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "FindServersOnNetworkRequest_startingRecordId", 0);
	if (svp != NULL)
		out.startingRecordId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "FindServersOnNetworkRequest_maxRecordsToReturn", 0);
	if (svp != NULL)
		out.maxRecordsToReturn = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "FindServersOnNetworkRequest_serverCapabilityFilter", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for FindServersOnNetworkRequest_serverCapabilityFilter");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.serverCapabilityFilter = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out.serverCapabilityFilter == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.serverCapabilityFilter[i] = XS_unpack_UA_String(*svp);
			}
		}
		out.serverCapabilityFilterSize = i;
	}

	return out;
}

/* FindServersOnNetworkResponse */
static void XS_pack_UA_FindServersOnNetworkResponse(SV *out, UA_FindServersOnNetworkResponse in)  __attribute__((unused));
static void
XS_pack_UA_FindServersOnNetworkResponse(SV *out, UA_FindServersOnNetworkResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "FindServersOnNetworkResponse_responseHeader", sv);

	sv = newSV(0);
	XS_pack_UA_DateTime(sv, in.lastCounterResetTime);
	hv_stores(hv, "FindServersOnNetworkResponse_lastCounterResetTime", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.serversSize);
	for (i = 0; i < in.serversSize; i++) {
		sv = newSV(0);
		XS_pack_UA_ServerOnNetwork(sv, in.servers[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "FindServersOnNetworkResponse_servers", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_FindServersOnNetworkResponse XS_unpack_UA_FindServersOnNetworkResponse(SV *in)  __attribute__((unused));
static UA_FindServersOnNetworkResponse
XS_unpack_UA_FindServersOnNetworkResponse(SV *in)
{
	dTHX;
	UA_FindServersOnNetworkResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_FindServersOnNetworkResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "FindServersOnNetworkResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "FindServersOnNetworkResponse_lastCounterResetTime", 0);
	if (svp != NULL)
		out.lastCounterResetTime = XS_unpack_UA_DateTime(*svp);

	svp = hv_fetchs(hv, "FindServersOnNetworkResponse_servers", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for FindServersOnNetworkResponse_servers");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.servers = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_SERVERONNETWORK]);
		if (out.servers == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.servers[i] = XS_unpack_UA_ServerOnNetwork(*svp);
			}
		}
		out.serversSize = i;
	}

	return out;
}

/* MessageSecurityMode */
static void XS_pack_UA_MessageSecurityMode(SV *out, UA_MessageSecurityMode in)  __attribute__((unused));
static void
XS_pack_UA_MessageSecurityMode(SV *out, UA_MessageSecurityMode in)
{
	dTHX;
	sv_setiv(out, in);
}

static UA_MessageSecurityMode XS_unpack_UA_MessageSecurityMode(SV *in)  __attribute__((unused));
static UA_MessageSecurityMode
XS_unpack_UA_MessageSecurityMode(SV *in)
{
	dTHX;
	return SvIV(in);
}

/* UserTokenType */
static void XS_pack_UA_UserTokenType(SV *out, UA_UserTokenType in)  __attribute__((unused));
static void
XS_pack_UA_UserTokenType(SV *out, UA_UserTokenType in)
{
	dTHX;
	sv_setiv(out, in);
}

static UA_UserTokenType XS_unpack_UA_UserTokenType(SV *in)  __attribute__((unused));
static UA_UserTokenType
XS_unpack_UA_UserTokenType(SV *in)
{
	dTHX;
	return SvIV(in);
}

/* UserTokenPolicy */
static void XS_pack_UA_UserTokenPolicy(SV *out, UA_UserTokenPolicy in)  __attribute__((unused));
static void
XS_pack_UA_UserTokenPolicy(SV *out, UA_UserTokenPolicy in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_String(sv, in.policyId);
	hv_stores(hv, "UserTokenPolicy_policyId", sv);

	sv = newSV(0);
	XS_pack_UA_UserTokenType(sv, in.tokenType);
	hv_stores(hv, "UserTokenPolicy_tokenType", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.issuedTokenType);
	hv_stores(hv, "UserTokenPolicy_issuedTokenType", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.issuerEndpointUrl);
	hv_stores(hv, "UserTokenPolicy_issuerEndpointUrl", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.securityPolicyUri);
	hv_stores(hv, "UserTokenPolicy_securityPolicyUri", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_UserTokenPolicy XS_unpack_UA_UserTokenPolicy(SV *in)  __attribute__((unused));
static UA_UserTokenPolicy
XS_unpack_UA_UserTokenPolicy(SV *in)
{
	dTHX;
	UA_UserTokenPolicy out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_UserTokenPolicy_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UserTokenPolicy_policyId", 0);
	if (svp != NULL)
		out.policyId = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "UserTokenPolicy_tokenType", 0);
	if (svp != NULL)
		out.tokenType = XS_unpack_UA_UserTokenType(*svp);

	svp = hv_fetchs(hv, "UserTokenPolicy_issuedTokenType", 0);
	if (svp != NULL)
		out.issuedTokenType = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "UserTokenPolicy_issuerEndpointUrl", 0);
	if (svp != NULL)
		out.issuerEndpointUrl = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "UserTokenPolicy_securityPolicyUri", 0);
	if (svp != NULL)
		out.securityPolicyUri = XS_unpack_UA_String(*svp);

	return out;
}

/* EndpointDescription */
static void XS_pack_UA_EndpointDescription(SV *out, UA_EndpointDescription in)  __attribute__((unused));
static void
XS_pack_UA_EndpointDescription(SV *out, UA_EndpointDescription in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_String(sv, in.endpointUrl);
	hv_stores(hv, "EndpointDescription_endpointUrl", sv);

	sv = newSV(0);
	XS_pack_UA_ApplicationDescription(sv, in.server);
	hv_stores(hv, "EndpointDescription_server", sv);

	sv = newSV(0);
	XS_pack_UA_ByteString(sv, in.serverCertificate);
	hv_stores(hv, "EndpointDescription_serverCertificate", sv);

	sv = newSV(0);
	XS_pack_UA_MessageSecurityMode(sv, in.securityMode);
	hv_stores(hv, "EndpointDescription_securityMode", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.securityPolicyUri);
	hv_stores(hv, "EndpointDescription_securityPolicyUri", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.userIdentityTokensSize);
	for (i = 0; i < in.userIdentityTokensSize; i++) {
		sv = newSV(0);
		XS_pack_UA_UserTokenPolicy(sv, in.userIdentityTokens[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "EndpointDescription_userIdentityTokens", newRV_inc((SV*)av));

	sv = newSV(0);
	XS_pack_UA_String(sv, in.transportProfileUri);
	hv_stores(hv, "EndpointDescription_transportProfileUri", sv);

	sv = newSV(0);
	XS_pack_UA_Byte(sv, in.securityLevel);
	hv_stores(hv, "EndpointDescription_securityLevel", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_EndpointDescription XS_unpack_UA_EndpointDescription(SV *in)  __attribute__((unused));
static UA_EndpointDescription
XS_unpack_UA_EndpointDescription(SV *in)
{
	dTHX;
	UA_EndpointDescription out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_EndpointDescription_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EndpointDescription_endpointUrl", 0);
	if (svp != NULL)
		out.endpointUrl = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "EndpointDescription_server", 0);
	if (svp != NULL)
		out.server = XS_unpack_UA_ApplicationDescription(*svp);

	svp = hv_fetchs(hv, "EndpointDescription_serverCertificate", 0);
	if (svp != NULL)
		out.serverCertificate = XS_unpack_UA_ByteString(*svp);

	svp = hv_fetchs(hv, "EndpointDescription_securityMode", 0);
	if (svp != NULL)
		out.securityMode = XS_unpack_UA_MessageSecurityMode(*svp);

	svp = hv_fetchs(hv, "EndpointDescription_securityPolicyUri", 0);
	if (svp != NULL)
		out.securityPolicyUri = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "EndpointDescription_userIdentityTokens", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for EndpointDescription_userIdentityTokens");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.userIdentityTokens = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_USERTOKENPOLICY]);
		if (out.userIdentityTokens == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.userIdentityTokens[i] = XS_unpack_UA_UserTokenPolicy(*svp);
			}
		}
		out.userIdentityTokensSize = i;
	}

	svp = hv_fetchs(hv, "EndpointDescription_transportProfileUri", 0);
	if (svp != NULL)
		out.transportProfileUri = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "EndpointDescription_securityLevel", 0);
	if (svp != NULL)
		out.securityLevel = XS_unpack_UA_Byte(*svp);

	return out;
}

/* GetEndpointsRequest */
static void XS_pack_UA_GetEndpointsRequest(SV *out, UA_GetEndpointsRequest in)  __attribute__((unused));
static void
XS_pack_UA_GetEndpointsRequest(SV *out, UA_GetEndpointsRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "GetEndpointsRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.endpointUrl);
	hv_stores(hv, "GetEndpointsRequest_endpointUrl", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.localeIdsSize);
	for (i = 0; i < in.localeIdsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_String(sv, in.localeIds[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "GetEndpointsRequest_localeIds", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.profileUrisSize);
	for (i = 0; i < in.profileUrisSize; i++) {
		sv = newSV(0);
		XS_pack_UA_String(sv, in.profileUris[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "GetEndpointsRequest_profileUris", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_GetEndpointsRequest XS_unpack_UA_GetEndpointsRequest(SV *in)  __attribute__((unused));
static UA_GetEndpointsRequest
XS_unpack_UA_GetEndpointsRequest(SV *in)
{
	dTHX;
	UA_GetEndpointsRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_GetEndpointsRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "GetEndpointsRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "GetEndpointsRequest_endpointUrl", 0);
	if (svp != NULL)
		out.endpointUrl = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "GetEndpointsRequest_localeIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for GetEndpointsRequest_localeIds");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.localeIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out.localeIds == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.localeIds[i] = XS_unpack_UA_String(*svp);
			}
		}
		out.localeIdsSize = i;
	}

	svp = hv_fetchs(hv, "GetEndpointsRequest_profileUris", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for GetEndpointsRequest_profileUris");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.profileUris = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out.profileUris == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.profileUris[i] = XS_unpack_UA_String(*svp);
			}
		}
		out.profileUrisSize = i;
	}

	return out;
}

/* GetEndpointsResponse */
static void XS_pack_UA_GetEndpointsResponse(SV *out, UA_GetEndpointsResponse in)  __attribute__((unused));
static void
XS_pack_UA_GetEndpointsResponse(SV *out, UA_GetEndpointsResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "GetEndpointsResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.endpointsSize);
	for (i = 0; i < in.endpointsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_EndpointDescription(sv, in.endpoints[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "GetEndpointsResponse_endpoints", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_GetEndpointsResponse XS_unpack_UA_GetEndpointsResponse(SV *in)  __attribute__((unused));
static UA_GetEndpointsResponse
XS_unpack_UA_GetEndpointsResponse(SV *in)
{
	dTHX;
	UA_GetEndpointsResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_GetEndpointsResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "GetEndpointsResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "GetEndpointsResponse_endpoints", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for GetEndpointsResponse_endpoints");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.endpoints = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ENDPOINTDESCRIPTION]);
		if (out.endpoints == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.endpoints[i] = XS_unpack_UA_EndpointDescription(*svp);
			}
		}
		out.endpointsSize = i;
	}

	return out;
}

/* RegisteredServer */
static void XS_pack_UA_RegisteredServer(SV *out, UA_RegisteredServer in)  __attribute__((unused));
static void
XS_pack_UA_RegisteredServer(SV *out, UA_RegisteredServer in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_String(sv, in.serverUri);
	hv_stores(hv, "RegisteredServer_serverUri", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.productUri);
	hv_stores(hv, "RegisteredServer_productUri", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.serverNamesSize);
	for (i = 0; i < in.serverNamesSize; i++) {
		sv = newSV(0);
		XS_pack_UA_LocalizedText(sv, in.serverNames[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "RegisteredServer_serverNames", newRV_inc((SV*)av));

	sv = newSV(0);
	XS_pack_UA_ApplicationType(sv, in.serverType);
	hv_stores(hv, "RegisteredServer_serverType", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.gatewayServerUri);
	hv_stores(hv, "RegisteredServer_gatewayServerUri", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.discoveryUrlsSize);
	for (i = 0; i < in.discoveryUrlsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_String(sv, in.discoveryUrls[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "RegisteredServer_discoveryUrls", newRV_inc((SV*)av));

	sv = newSV(0);
	XS_pack_UA_String(sv, in.semaphoreFilePath);
	hv_stores(hv, "RegisteredServer_semaphoreFilePath", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.isOnline);
	hv_stores(hv, "RegisteredServer_isOnline", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_RegisteredServer XS_unpack_UA_RegisteredServer(SV *in)  __attribute__((unused));
static UA_RegisteredServer
XS_unpack_UA_RegisteredServer(SV *in)
{
	dTHX;
	UA_RegisteredServer out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_RegisteredServer_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RegisteredServer_serverUri", 0);
	if (svp != NULL)
		out.serverUri = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "RegisteredServer_productUri", 0);
	if (svp != NULL)
		out.productUri = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "RegisteredServer_serverNames", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for RegisteredServer_serverNames");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.serverNames = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_LOCALIZEDTEXT]);
		if (out.serverNames == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.serverNames[i] = XS_unpack_UA_LocalizedText(*svp);
			}
		}
		out.serverNamesSize = i;
	}

	svp = hv_fetchs(hv, "RegisteredServer_serverType", 0);
	if (svp != NULL)
		out.serverType = XS_unpack_UA_ApplicationType(*svp);

	svp = hv_fetchs(hv, "RegisteredServer_gatewayServerUri", 0);
	if (svp != NULL)
		out.gatewayServerUri = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "RegisteredServer_discoveryUrls", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for RegisteredServer_discoveryUrls");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.discoveryUrls = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out.discoveryUrls == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.discoveryUrls[i] = XS_unpack_UA_String(*svp);
			}
		}
		out.discoveryUrlsSize = i;
	}

	svp = hv_fetchs(hv, "RegisteredServer_semaphoreFilePath", 0);
	if (svp != NULL)
		out.semaphoreFilePath = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "RegisteredServer_isOnline", 0);
	if (svp != NULL)
		out.isOnline = XS_unpack_UA_Boolean(*svp);

	return out;
}

/* RegisterServerRequest */
static void XS_pack_UA_RegisterServerRequest(SV *out, UA_RegisterServerRequest in)  __attribute__((unused));
static void
XS_pack_UA_RegisterServerRequest(SV *out, UA_RegisterServerRequest in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "RegisterServerRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_RegisteredServer(sv, in.server);
	hv_stores(hv, "RegisterServerRequest_server", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_RegisterServerRequest XS_unpack_UA_RegisterServerRequest(SV *in)  __attribute__((unused));
static UA_RegisterServerRequest
XS_unpack_UA_RegisterServerRequest(SV *in)
{
	dTHX;
	UA_RegisterServerRequest out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_RegisterServerRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RegisterServerRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "RegisterServerRequest_server", 0);
	if (svp != NULL)
		out.server = XS_unpack_UA_RegisteredServer(*svp);

	return out;
}

/* RegisterServerResponse */
static void XS_pack_UA_RegisterServerResponse(SV *out, UA_RegisterServerResponse in)  __attribute__((unused));
static void
XS_pack_UA_RegisterServerResponse(SV *out, UA_RegisterServerResponse in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "RegisterServerResponse_responseHeader", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_RegisterServerResponse XS_unpack_UA_RegisterServerResponse(SV *in)  __attribute__((unused));
static UA_RegisterServerResponse
XS_unpack_UA_RegisterServerResponse(SV *in)
{
	dTHX;
	UA_RegisterServerResponse out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_RegisterServerResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RegisterServerResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	return out;
}

/* DiscoveryConfiguration */
static void XS_pack_UA_DiscoveryConfiguration(SV *out, UA_DiscoveryConfiguration in)  __attribute__((unused));
static void
XS_pack_UA_DiscoveryConfiguration(SV *out, UA_DiscoveryConfiguration in)
{
	dTHX;
	CROAK("No conversion implemented");
}

static UA_DiscoveryConfiguration XS_unpack_UA_DiscoveryConfiguration(SV *in)  __attribute__((unused));
static UA_DiscoveryConfiguration
XS_unpack_UA_DiscoveryConfiguration(SV *in)
{
	dTHX;
	CROAK("No conversion implemented");
}

/* MdnsDiscoveryConfiguration */
static void XS_pack_UA_MdnsDiscoveryConfiguration(SV *out, UA_MdnsDiscoveryConfiguration in)  __attribute__((unused));
static void
XS_pack_UA_MdnsDiscoveryConfiguration(SV *out, UA_MdnsDiscoveryConfiguration in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_String(sv, in.mdnsServerName);
	hv_stores(hv, "MdnsDiscoveryConfiguration_mdnsServerName", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.serverCapabilitiesSize);
	for (i = 0; i < in.serverCapabilitiesSize; i++) {
		sv = newSV(0);
		XS_pack_UA_String(sv, in.serverCapabilities[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "MdnsDiscoveryConfiguration_serverCapabilities", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_MdnsDiscoveryConfiguration XS_unpack_UA_MdnsDiscoveryConfiguration(SV *in)  __attribute__((unused));
static UA_MdnsDiscoveryConfiguration
XS_unpack_UA_MdnsDiscoveryConfiguration(SV *in)
{
	dTHX;
	UA_MdnsDiscoveryConfiguration out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_MdnsDiscoveryConfiguration_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "MdnsDiscoveryConfiguration_mdnsServerName", 0);
	if (svp != NULL)
		out.mdnsServerName = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "MdnsDiscoveryConfiguration_serverCapabilities", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for MdnsDiscoveryConfiguration_serverCapabilities");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.serverCapabilities = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out.serverCapabilities == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.serverCapabilities[i] = XS_unpack_UA_String(*svp);
			}
		}
		out.serverCapabilitiesSize = i;
	}

	return out;
}

/* RegisterServer2Request */
static void XS_pack_UA_RegisterServer2Request(SV *out, UA_RegisterServer2Request in)  __attribute__((unused));
static void
XS_pack_UA_RegisterServer2Request(SV *out, UA_RegisterServer2Request in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "RegisterServer2Request_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_RegisteredServer(sv, in.server);
	hv_stores(hv, "RegisterServer2Request_server", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.discoveryConfigurationSize);
	for (i = 0; i < in.discoveryConfigurationSize; i++) {
		sv = newSV(0);
		XS_pack_UA_ExtensionObject(sv, in.discoveryConfiguration[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "RegisterServer2Request_discoveryConfiguration", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_RegisterServer2Request XS_unpack_UA_RegisterServer2Request(SV *in)  __attribute__((unused));
static UA_RegisterServer2Request
XS_unpack_UA_RegisterServer2Request(SV *in)
{
	dTHX;
	UA_RegisterServer2Request out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_RegisterServer2Request_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RegisterServer2Request_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "RegisterServer2Request_server", 0);
	if (svp != NULL)
		out.server = XS_unpack_UA_RegisteredServer(*svp);

	svp = hv_fetchs(hv, "RegisterServer2Request_discoveryConfiguration", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for RegisterServer2Request_discoveryConfiguration");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.discoveryConfiguration = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_EXTENSIONOBJECT]);
		if (out.discoveryConfiguration == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.discoveryConfiguration[i] = XS_unpack_UA_ExtensionObject(*svp);
			}
		}
		out.discoveryConfigurationSize = i;
	}

	return out;
}

/* RegisterServer2Response */
static void XS_pack_UA_RegisterServer2Response(SV *out, UA_RegisterServer2Response in)  __attribute__((unused));
static void
XS_pack_UA_RegisterServer2Response(SV *out, UA_RegisterServer2Response in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "RegisterServer2Response_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.configurationResultsSize);
	for (i = 0; i < in.configurationResultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_StatusCode(sv, in.configurationResults[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "RegisterServer2Response_configurationResults", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "RegisterServer2Response_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_RegisterServer2Response XS_unpack_UA_RegisterServer2Response(SV *in)  __attribute__((unused));
static UA_RegisterServer2Response
XS_unpack_UA_RegisterServer2Response(SV *in)
{
	dTHX;
	UA_RegisterServer2Response out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_RegisterServer2Response_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RegisterServer2Response_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "RegisterServer2Response_configurationResults", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for RegisterServer2Response_configurationResults");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.configurationResults = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out.configurationResults == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.configurationResults[i] = XS_unpack_UA_StatusCode(*svp);
			}
		}
		out.configurationResultsSize = i;
	}

	svp = hv_fetchs(hv, "RegisterServer2Response_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for RegisterServer2Response_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* SecurityTokenRequestType */
static void XS_pack_UA_SecurityTokenRequestType(SV *out, UA_SecurityTokenRequestType in)  __attribute__((unused));
static void
XS_pack_UA_SecurityTokenRequestType(SV *out, UA_SecurityTokenRequestType in)
{
	dTHX;
	sv_setiv(out, in);
}

static UA_SecurityTokenRequestType XS_unpack_UA_SecurityTokenRequestType(SV *in)  __attribute__((unused));
static UA_SecurityTokenRequestType
XS_unpack_UA_SecurityTokenRequestType(SV *in)
{
	dTHX;
	return SvIV(in);
}

/* ChannelSecurityToken */
static void XS_pack_UA_ChannelSecurityToken(SV *out, UA_ChannelSecurityToken in)  __attribute__((unused));
static void
XS_pack_UA_ChannelSecurityToken(SV *out, UA_ChannelSecurityToken in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.channelId);
	hv_stores(hv, "ChannelSecurityToken_channelId", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.tokenId);
	hv_stores(hv, "ChannelSecurityToken_tokenId", sv);

	sv = newSV(0);
	XS_pack_UA_DateTime(sv, in.createdAt);
	hv_stores(hv, "ChannelSecurityToken_createdAt", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.revisedLifetime);
	hv_stores(hv, "ChannelSecurityToken_revisedLifetime", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ChannelSecurityToken XS_unpack_UA_ChannelSecurityToken(SV *in)  __attribute__((unused));
static UA_ChannelSecurityToken
XS_unpack_UA_ChannelSecurityToken(SV *in)
{
	dTHX;
	UA_ChannelSecurityToken out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ChannelSecurityToken_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ChannelSecurityToken_channelId", 0);
	if (svp != NULL)
		out.channelId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ChannelSecurityToken_tokenId", 0);
	if (svp != NULL)
		out.tokenId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ChannelSecurityToken_createdAt", 0);
	if (svp != NULL)
		out.createdAt = XS_unpack_UA_DateTime(*svp);

	svp = hv_fetchs(hv, "ChannelSecurityToken_revisedLifetime", 0);
	if (svp != NULL)
		out.revisedLifetime = XS_unpack_UA_UInt32(*svp);

	return out;
}

/* OpenSecureChannelRequest */
static void XS_pack_UA_OpenSecureChannelRequest(SV *out, UA_OpenSecureChannelRequest in)  __attribute__((unused));
static void
XS_pack_UA_OpenSecureChannelRequest(SV *out, UA_OpenSecureChannelRequest in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "OpenSecureChannelRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.clientProtocolVersion);
	hv_stores(hv, "OpenSecureChannelRequest_clientProtocolVersion", sv);

	sv = newSV(0);
	XS_pack_UA_SecurityTokenRequestType(sv, in.requestType);
	hv_stores(hv, "OpenSecureChannelRequest_requestType", sv);

	sv = newSV(0);
	XS_pack_UA_MessageSecurityMode(sv, in.securityMode);
	hv_stores(hv, "OpenSecureChannelRequest_securityMode", sv);

	sv = newSV(0);
	XS_pack_UA_ByteString(sv, in.clientNonce);
	hv_stores(hv, "OpenSecureChannelRequest_clientNonce", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.requestedLifetime);
	hv_stores(hv, "OpenSecureChannelRequest_requestedLifetime", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_OpenSecureChannelRequest XS_unpack_UA_OpenSecureChannelRequest(SV *in)  __attribute__((unused));
static UA_OpenSecureChannelRequest
XS_unpack_UA_OpenSecureChannelRequest(SV *in)
{
	dTHX;
	UA_OpenSecureChannelRequest out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_OpenSecureChannelRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "OpenSecureChannelRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "OpenSecureChannelRequest_clientProtocolVersion", 0);
	if (svp != NULL)
		out.clientProtocolVersion = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "OpenSecureChannelRequest_requestType", 0);
	if (svp != NULL)
		out.requestType = XS_unpack_UA_SecurityTokenRequestType(*svp);

	svp = hv_fetchs(hv, "OpenSecureChannelRequest_securityMode", 0);
	if (svp != NULL)
		out.securityMode = XS_unpack_UA_MessageSecurityMode(*svp);

	svp = hv_fetchs(hv, "OpenSecureChannelRequest_clientNonce", 0);
	if (svp != NULL)
		out.clientNonce = XS_unpack_UA_ByteString(*svp);

	svp = hv_fetchs(hv, "OpenSecureChannelRequest_requestedLifetime", 0);
	if (svp != NULL)
		out.requestedLifetime = XS_unpack_UA_UInt32(*svp);

	return out;
}

/* OpenSecureChannelResponse */
static void XS_pack_UA_OpenSecureChannelResponse(SV *out, UA_OpenSecureChannelResponse in)  __attribute__((unused));
static void
XS_pack_UA_OpenSecureChannelResponse(SV *out, UA_OpenSecureChannelResponse in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "OpenSecureChannelResponse_responseHeader", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.serverProtocolVersion);
	hv_stores(hv, "OpenSecureChannelResponse_serverProtocolVersion", sv);

	sv = newSV(0);
	XS_pack_UA_ChannelSecurityToken(sv, in.securityToken);
	hv_stores(hv, "OpenSecureChannelResponse_securityToken", sv);

	sv = newSV(0);
	XS_pack_UA_ByteString(sv, in.serverNonce);
	hv_stores(hv, "OpenSecureChannelResponse_serverNonce", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_OpenSecureChannelResponse XS_unpack_UA_OpenSecureChannelResponse(SV *in)  __attribute__((unused));
static UA_OpenSecureChannelResponse
XS_unpack_UA_OpenSecureChannelResponse(SV *in)
{
	dTHX;
	UA_OpenSecureChannelResponse out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_OpenSecureChannelResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "OpenSecureChannelResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "OpenSecureChannelResponse_serverProtocolVersion", 0);
	if (svp != NULL)
		out.serverProtocolVersion = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "OpenSecureChannelResponse_securityToken", 0);
	if (svp != NULL)
		out.securityToken = XS_unpack_UA_ChannelSecurityToken(*svp);

	svp = hv_fetchs(hv, "OpenSecureChannelResponse_serverNonce", 0);
	if (svp != NULL)
		out.serverNonce = XS_unpack_UA_ByteString(*svp);

	return out;
}

/* CloseSecureChannelRequest */
static void XS_pack_UA_CloseSecureChannelRequest(SV *out, UA_CloseSecureChannelRequest in)  __attribute__((unused));
static void
XS_pack_UA_CloseSecureChannelRequest(SV *out, UA_CloseSecureChannelRequest in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "CloseSecureChannelRequest_requestHeader", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_CloseSecureChannelRequest XS_unpack_UA_CloseSecureChannelRequest(SV *in)  __attribute__((unused));
static UA_CloseSecureChannelRequest
XS_unpack_UA_CloseSecureChannelRequest(SV *in)
{
	dTHX;
	UA_CloseSecureChannelRequest out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_CloseSecureChannelRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CloseSecureChannelRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	return out;
}

/* CloseSecureChannelResponse */
static void XS_pack_UA_CloseSecureChannelResponse(SV *out, UA_CloseSecureChannelResponse in)  __attribute__((unused));
static void
XS_pack_UA_CloseSecureChannelResponse(SV *out, UA_CloseSecureChannelResponse in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "CloseSecureChannelResponse_responseHeader", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_CloseSecureChannelResponse XS_unpack_UA_CloseSecureChannelResponse(SV *in)  __attribute__((unused));
static UA_CloseSecureChannelResponse
XS_unpack_UA_CloseSecureChannelResponse(SV *in)
{
	dTHX;
	UA_CloseSecureChannelResponse out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_CloseSecureChannelResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CloseSecureChannelResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	return out;
}

/* SignedSoftwareCertificate */
static void XS_pack_UA_SignedSoftwareCertificate(SV *out, UA_SignedSoftwareCertificate in)  __attribute__((unused));
static void
XS_pack_UA_SignedSoftwareCertificate(SV *out, UA_SignedSoftwareCertificate in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ByteString(sv, in.certificateData);
	hv_stores(hv, "SignedSoftwareCertificate_certificateData", sv);

	sv = newSV(0);
	XS_pack_UA_ByteString(sv, in.signature);
	hv_stores(hv, "SignedSoftwareCertificate_signature", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_SignedSoftwareCertificate XS_unpack_UA_SignedSoftwareCertificate(SV *in)  __attribute__((unused));
static UA_SignedSoftwareCertificate
XS_unpack_UA_SignedSoftwareCertificate(SV *in)
{
	dTHX;
	UA_SignedSoftwareCertificate out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_SignedSoftwareCertificate_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SignedSoftwareCertificate_certificateData", 0);
	if (svp != NULL)
		out.certificateData = XS_unpack_UA_ByteString(*svp);

	svp = hv_fetchs(hv, "SignedSoftwareCertificate_signature", 0);
	if (svp != NULL)
		out.signature = XS_unpack_UA_ByteString(*svp);

	return out;
}

/* SignatureData */
static void XS_pack_UA_SignatureData(SV *out, UA_SignatureData in)  __attribute__((unused));
static void
XS_pack_UA_SignatureData(SV *out, UA_SignatureData in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_String(sv, in.algorithm);
	hv_stores(hv, "SignatureData_algorithm", sv);

	sv = newSV(0);
	XS_pack_UA_ByteString(sv, in.signature);
	hv_stores(hv, "SignatureData_signature", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_SignatureData XS_unpack_UA_SignatureData(SV *in)  __attribute__((unused));
static UA_SignatureData
XS_unpack_UA_SignatureData(SV *in)
{
	dTHX;
	UA_SignatureData out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_SignatureData_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SignatureData_algorithm", 0);
	if (svp != NULL)
		out.algorithm = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "SignatureData_signature", 0);
	if (svp != NULL)
		out.signature = XS_unpack_UA_ByteString(*svp);

	return out;
}

/* CreateSessionRequest */
static void XS_pack_UA_CreateSessionRequest(SV *out, UA_CreateSessionRequest in)  __attribute__((unused));
static void
XS_pack_UA_CreateSessionRequest(SV *out, UA_CreateSessionRequest in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "CreateSessionRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_ApplicationDescription(sv, in.clientDescription);
	hv_stores(hv, "CreateSessionRequest_clientDescription", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.serverUri);
	hv_stores(hv, "CreateSessionRequest_serverUri", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.endpointUrl);
	hv_stores(hv, "CreateSessionRequest_endpointUrl", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.sessionName);
	hv_stores(hv, "CreateSessionRequest_sessionName", sv);

	sv = newSV(0);
	XS_pack_UA_ByteString(sv, in.clientNonce);
	hv_stores(hv, "CreateSessionRequest_clientNonce", sv);

	sv = newSV(0);
	XS_pack_UA_ByteString(sv, in.clientCertificate);
	hv_stores(hv, "CreateSessionRequest_clientCertificate", sv);

	sv = newSV(0);
	XS_pack_UA_Double(sv, in.requestedSessionTimeout);
	hv_stores(hv, "CreateSessionRequest_requestedSessionTimeout", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.maxResponseMessageSize);
	hv_stores(hv, "CreateSessionRequest_maxResponseMessageSize", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_CreateSessionRequest XS_unpack_UA_CreateSessionRequest(SV *in)  __attribute__((unused));
static UA_CreateSessionRequest
XS_unpack_UA_CreateSessionRequest(SV *in)
{
	dTHX;
	UA_CreateSessionRequest out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_CreateSessionRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CreateSessionRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "CreateSessionRequest_clientDescription", 0);
	if (svp != NULL)
		out.clientDescription = XS_unpack_UA_ApplicationDescription(*svp);

	svp = hv_fetchs(hv, "CreateSessionRequest_serverUri", 0);
	if (svp != NULL)
		out.serverUri = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "CreateSessionRequest_endpointUrl", 0);
	if (svp != NULL)
		out.endpointUrl = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "CreateSessionRequest_sessionName", 0);
	if (svp != NULL)
		out.sessionName = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "CreateSessionRequest_clientNonce", 0);
	if (svp != NULL)
		out.clientNonce = XS_unpack_UA_ByteString(*svp);

	svp = hv_fetchs(hv, "CreateSessionRequest_clientCertificate", 0);
	if (svp != NULL)
		out.clientCertificate = XS_unpack_UA_ByteString(*svp);

	svp = hv_fetchs(hv, "CreateSessionRequest_requestedSessionTimeout", 0);
	if (svp != NULL)
		out.requestedSessionTimeout = XS_unpack_UA_Double(*svp);

	svp = hv_fetchs(hv, "CreateSessionRequest_maxResponseMessageSize", 0);
	if (svp != NULL)
		out.maxResponseMessageSize = XS_unpack_UA_UInt32(*svp);

	return out;
}

/* CreateSessionResponse */
static void XS_pack_UA_CreateSessionResponse(SV *out, UA_CreateSessionResponse in)  __attribute__((unused));
static void
XS_pack_UA_CreateSessionResponse(SV *out, UA_CreateSessionResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "CreateSessionResponse_responseHeader", sv);

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.sessionId);
	hv_stores(hv, "CreateSessionResponse_sessionId", sv);

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.authenticationToken);
	hv_stores(hv, "CreateSessionResponse_authenticationToken", sv);

	sv = newSV(0);
	XS_pack_UA_Double(sv, in.revisedSessionTimeout);
	hv_stores(hv, "CreateSessionResponse_revisedSessionTimeout", sv);

	sv = newSV(0);
	XS_pack_UA_ByteString(sv, in.serverNonce);
	hv_stores(hv, "CreateSessionResponse_serverNonce", sv);

	sv = newSV(0);
	XS_pack_UA_ByteString(sv, in.serverCertificate);
	hv_stores(hv, "CreateSessionResponse_serverCertificate", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.serverEndpointsSize);
	for (i = 0; i < in.serverEndpointsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_EndpointDescription(sv, in.serverEndpoints[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "CreateSessionResponse_serverEndpoints", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.serverSoftwareCertificatesSize);
	for (i = 0; i < in.serverSoftwareCertificatesSize; i++) {
		sv = newSV(0);
		XS_pack_UA_SignedSoftwareCertificate(sv, in.serverSoftwareCertificates[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "CreateSessionResponse_serverSoftwareCertificates", newRV_inc((SV*)av));

	sv = newSV(0);
	XS_pack_UA_SignatureData(sv, in.serverSignature);
	hv_stores(hv, "CreateSessionResponse_serverSignature", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.maxRequestMessageSize);
	hv_stores(hv, "CreateSessionResponse_maxRequestMessageSize", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_CreateSessionResponse XS_unpack_UA_CreateSessionResponse(SV *in)  __attribute__((unused));
static UA_CreateSessionResponse
XS_unpack_UA_CreateSessionResponse(SV *in)
{
	dTHX;
	UA_CreateSessionResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_CreateSessionResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CreateSessionResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "CreateSessionResponse_sessionId", 0);
	if (svp != NULL)
		out.sessionId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "CreateSessionResponse_authenticationToken", 0);
	if (svp != NULL)
		out.authenticationToken = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "CreateSessionResponse_revisedSessionTimeout", 0);
	if (svp != NULL)
		out.revisedSessionTimeout = XS_unpack_UA_Double(*svp);

	svp = hv_fetchs(hv, "CreateSessionResponse_serverNonce", 0);
	if (svp != NULL)
		out.serverNonce = XS_unpack_UA_ByteString(*svp);

	svp = hv_fetchs(hv, "CreateSessionResponse_serverCertificate", 0);
	if (svp != NULL)
		out.serverCertificate = XS_unpack_UA_ByteString(*svp);

	svp = hv_fetchs(hv, "CreateSessionResponse_serverEndpoints", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for CreateSessionResponse_serverEndpoints");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.serverEndpoints = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ENDPOINTDESCRIPTION]);
		if (out.serverEndpoints == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.serverEndpoints[i] = XS_unpack_UA_EndpointDescription(*svp);
			}
		}
		out.serverEndpointsSize = i;
	}

	svp = hv_fetchs(hv, "CreateSessionResponse_serverSoftwareCertificates", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for CreateSessionResponse_serverSoftwareCertificates");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.serverSoftwareCertificates = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_SIGNEDSOFTWARECERTIFICATE]);
		if (out.serverSoftwareCertificates == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.serverSoftwareCertificates[i] = XS_unpack_UA_SignedSoftwareCertificate(*svp);
			}
		}
		out.serverSoftwareCertificatesSize = i;
	}

	svp = hv_fetchs(hv, "CreateSessionResponse_serverSignature", 0);
	if (svp != NULL)
		out.serverSignature = XS_unpack_UA_SignatureData(*svp);

	svp = hv_fetchs(hv, "CreateSessionResponse_maxRequestMessageSize", 0);
	if (svp != NULL)
		out.maxRequestMessageSize = XS_unpack_UA_UInt32(*svp);

	return out;
}

/* UserIdentityToken */
static void XS_pack_UA_UserIdentityToken(SV *out, UA_UserIdentityToken in)  __attribute__((unused));
static void
XS_pack_UA_UserIdentityToken(SV *out, UA_UserIdentityToken in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_String(sv, in.policyId);
	hv_stores(hv, "UserIdentityToken_policyId", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_UserIdentityToken XS_unpack_UA_UserIdentityToken(SV *in)  __attribute__((unused));
static UA_UserIdentityToken
XS_unpack_UA_UserIdentityToken(SV *in)
{
	dTHX;
	UA_UserIdentityToken out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_UserIdentityToken_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UserIdentityToken_policyId", 0);
	if (svp != NULL)
		out.policyId = XS_unpack_UA_String(*svp);

	return out;
}

/* AnonymousIdentityToken */
static void XS_pack_UA_AnonymousIdentityToken(SV *out, UA_AnonymousIdentityToken in)  __attribute__((unused));
static void
XS_pack_UA_AnonymousIdentityToken(SV *out, UA_AnonymousIdentityToken in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_String(sv, in.policyId);
	hv_stores(hv, "AnonymousIdentityToken_policyId", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_AnonymousIdentityToken XS_unpack_UA_AnonymousIdentityToken(SV *in)  __attribute__((unused));
static UA_AnonymousIdentityToken
XS_unpack_UA_AnonymousIdentityToken(SV *in)
{
	dTHX;
	UA_AnonymousIdentityToken out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_AnonymousIdentityToken_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AnonymousIdentityToken_policyId", 0);
	if (svp != NULL)
		out.policyId = XS_unpack_UA_String(*svp);

	return out;
}

/* UserNameIdentityToken */
static void XS_pack_UA_UserNameIdentityToken(SV *out, UA_UserNameIdentityToken in)  __attribute__((unused));
static void
XS_pack_UA_UserNameIdentityToken(SV *out, UA_UserNameIdentityToken in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_String(sv, in.policyId);
	hv_stores(hv, "UserNameIdentityToken_policyId", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.userName);
	hv_stores(hv, "UserNameIdentityToken_userName", sv);

	sv = newSV(0);
	XS_pack_UA_ByteString(sv, in.password);
	hv_stores(hv, "UserNameIdentityToken_password", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.encryptionAlgorithm);
	hv_stores(hv, "UserNameIdentityToken_encryptionAlgorithm", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_UserNameIdentityToken XS_unpack_UA_UserNameIdentityToken(SV *in)  __attribute__((unused));
static UA_UserNameIdentityToken
XS_unpack_UA_UserNameIdentityToken(SV *in)
{
	dTHX;
	UA_UserNameIdentityToken out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_UserNameIdentityToken_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UserNameIdentityToken_policyId", 0);
	if (svp != NULL)
		out.policyId = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "UserNameIdentityToken_userName", 0);
	if (svp != NULL)
		out.userName = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "UserNameIdentityToken_password", 0);
	if (svp != NULL)
		out.password = XS_unpack_UA_ByteString(*svp);

	svp = hv_fetchs(hv, "UserNameIdentityToken_encryptionAlgorithm", 0);
	if (svp != NULL)
		out.encryptionAlgorithm = XS_unpack_UA_String(*svp);

	return out;
}

/* X509IdentityToken */
static void XS_pack_UA_X509IdentityToken(SV *out, UA_X509IdentityToken in)  __attribute__((unused));
static void
XS_pack_UA_X509IdentityToken(SV *out, UA_X509IdentityToken in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_String(sv, in.policyId);
	hv_stores(hv, "X509IdentityToken_policyId", sv);

	sv = newSV(0);
	XS_pack_UA_ByteString(sv, in.certificateData);
	hv_stores(hv, "X509IdentityToken_certificateData", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_X509IdentityToken XS_unpack_UA_X509IdentityToken(SV *in)  __attribute__((unused));
static UA_X509IdentityToken
XS_unpack_UA_X509IdentityToken(SV *in)
{
	dTHX;
	UA_X509IdentityToken out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_X509IdentityToken_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "X509IdentityToken_policyId", 0);
	if (svp != NULL)
		out.policyId = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "X509IdentityToken_certificateData", 0);
	if (svp != NULL)
		out.certificateData = XS_unpack_UA_ByteString(*svp);

	return out;
}

/* IssuedIdentityToken */
static void XS_pack_UA_IssuedIdentityToken(SV *out, UA_IssuedIdentityToken in)  __attribute__((unused));
static void
XS_pack_UA_IssuedIdentityToken(SV *out, UA_IssuedIdentityToken in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_String(sv, in.policyId);
	hv_stores(hv, "IssuedIdentityToken_policyId", sv);

	sv = newSV(0);
	XS_pack_UA_ByteString(sv, in.tokenData);
	hv_stores(hv, "IssuedIdentityToken_tokenData", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.encryptionAlgorithm);
	hv_stores(hv, "IssuedIdentityToken_encryptionAlgorithm", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_IssuedIdentityToken XS_unpack_UA_IssuedIdentityToken(SV *in)  __attribute__((unused));
static UA_IssuedIdentityToken
XS_unpack_UA_IssuedIdentityToken(SV *in)
{
	dTHX;
	UA_IssuedIdentityToken out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_IssuedIdentityToken_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "IssuedIdentityToken_policyId", 0);
	if (svp != NULL)
		out.policyId = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "IssuedIdentityToken_tokenData", 0);
	if (svp != NULL)
		out.tokenData = XS_unpack_UA_ByteString(*svp);

	svp = hv_fetchs(hv, "IssuedIdentityToken_encryptionAlgorithm", 0);
	if (svp != NULL)
		out.encryptionAlgorithm = XS_unpack_UA_String(*svp);

	return out;
}

/* ActivateSessionRequest */
static void XS_pack_UA_ActivateSessionRequest(SV *out, UA_ActivateSessionRequest in)  __attribute__((unused));
static void
XS_pack_UA_ActivateSessionRequest(SV *out, UA_ActivateSessionRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "ActivateSessionRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_SignatureData(sv, in.clientSignature);
	hv_stores(hv, "ActivateSessionRequest_clientSignature", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.clientSoftwareCertificatesSize);
	for (i = 0; i < in.clientSoftwareCertificatesSize; i++) {
		sv = newSV(0);
		XS_pack_UA_SignedSoftwareCertificate(sv, in.clientSoftwareCertificates[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ActivateSessionRequest_clientSoftwareCertificates", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.localeIdsSize);
	for (i = 0; i < in.localeIdsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_String(sv, in.localeIds[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ActivateSessionRequest_localeIds", newRV_inc((SV*)av));

	sv = newSV(0);
	XS_pack_UA_ExtensionObject(sv, in.userIdentityToken);
	hv_stores(hv, "ActivateSessionRequest_userIdentityToken", sv);

	sv = newSV(0);
	XS_pack_UA_SignatureData(sv, in.userTokenSignature);
	hv_stores(hv, "ActivateSessionRequest_userTokenSignature", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ActivateSessionRequest XS_unpack_UA_ActivateSessionRequest(SV *in)  __attribute__((unused));
static UA_ActivateSessionRequest
XS_unpack_UA_ActivateSessionRequest(SV *in)
{
	dTHX;
	UA_ActivateSessionRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ActivateSessionRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ActivateSessionRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "ActivateSessionRequest_clientSignature", 0);
	if (svp != NULL)
		out.clientSignature = XS_unpack_UA_SignatureData(*svp);

	svp = hv_fetchs(hv, "ActivateSessionRequest_clientSoftwareCertificates", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ActivateSessionRequest_clientSoftwareCertificates");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.clientSoftwareCertificates = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_SIGNEDSOFTWARECERTIFICATE]);
		if (out.clientSoftwareCertificates == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.clientSoftwareCertificates[i] = XS_unpack_UA_SignedSoftwareCertificate(*svp);
			}
		}
		out.clientSoftwareCertificatesSize = i;
	}

	svp = hv_fetchs(hv, "ActivateSessionRequest_localeIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ActivateSessionRequest_localeIds");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.localeIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STRING]);
		if (out.localeIds == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.localeIds[i] = XS_unpack_UA_String(*svp);
			}
		}
		out.localeIdsSize = i;
	}

	svp = hv_fetchs(hv, "ActivateSessionRequest_userIdentityToken", 0);
	if (svp != NULL)
		out.userIdentityToken = XS_unpack_UA_ExtensionObject(*svp);

	svp = hv_fetchs(hv, "ActivateSessionRequest_userTokenSignature", 0);
	if (svp != NULL)
		out.userTokenSignature = XS_unpack_UA_SignatureData(*svp);

	return out;
}

/* ActivateSessionResponse */
static void XS_pack_UA_ActivateSessionResponse(SV *out, UA_ActivateSessionResponse in)  __attribute__((unused));
static void
XS_pack_UA_ActivateSessionResponse(SV *out, UA_ActivateSessionResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "ActivateSessionResponse_responseHeader", sv);

	sv = newSV(0);
	XS_pack_UA_ByteString(sv, in.serverNonce);
	hv_stores(hv, "ActivateSessionResponse_serverNonce", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.resultsSize);
	for (i = 0; i < in.resultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_StatusCode(sv, in.results[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ActivateSessionResponse_results", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ActivateSessionResponse_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ActivateSessionResponse XS_unpack_UA_ActivateSessionResponse(SV *in)  __attribute__((unused));
static UA_ActivateSessionResponse
XS_unpack_UA_ActivateSessionResponse(SV *in)
{
	dTHX;
	UA_ActivateSessionResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ActivateSessionResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ActivateSessionResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "ActivateSessionResponse_serverNonce", 0);
	if (svp != NULL)
		out.serverNonce = XS_unpack_UA_ByteString(*svp);

	svp = hv_fetchs(hv, "ActivateSessionResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ActivateSessionResponse_results");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out.results == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.results[i] = XS_unpack_UA_StatusCode(*svp);
			}
		}
		out.resultsSize = i;
	}

	svp = hv_fetchs(hv, "ActivateSessionResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ActivateSessionResponse_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* CloseSessionRequest */
static void XS_pack_UA_CloseSessionRequest(SV *out, UA_CloseSessionRequest in)  __attribute__((unused));
static void
XS_pack_UA_CloseSessionRequest(SV *out, UA_CloseSessionRequest in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "CloseSessionRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.deleteSubscriptions);
	hv_stores(hv, "CloseSessionRequest_deleteSubscriptions", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_CloseSessionRequest XS_unpack_UA_CloseSessionRequest(SV *in)  __attribute__((unused));
static UA_CloseSessionRequest
XS_unpack_UA_CloseSessionRequest(SV *in)
{
	dTHX;
	UA_CloseSessionRequest out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_CloseSessionRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CloseSessionRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "CloseSessionRequest_deleteSubscriptions", 0);
	if (svp != NULL)
		out.deleteSubscriptions = XS_unpack_UA_Boolean(*svp);

	return out;
}

/* CloseSessionResponse */
static void XS_pack_UA_CloseSessionResponse(SV *out, UA_CloseSessionResponse in)  __attribute__((unused));
static void
XS_pack_UA_CloseSessionResponse(SV *out, UA_CloseSessionResponse in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "CloseSessionResponse_responseHeader", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_CloseSessionResponse XS_unpack_UA_CloseSessionResponse(SV *in)  __attribute__((unused));
static UA_CloseSessionResponse
XS_unpack_UA_CloseSessionResponse(SV *in)
{
	dTHX;
	UA_CloseSessionResponse out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_CloseSessionResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CloseSessionResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	return out;
}

/* NodeAttributesMask */
static void XS_pack_UA_NodeAttributesMask(SV *out, UA_NodeAttributesMask in)  __attribute__((unused));
static void
XS_pack_UA_NodeAttributesMask(SV *out, UA_NodeAttributesMask in)
{
	dTHX;
	sv_setiv(out, in);
}

static UA_NodeAttributesMask XS_unpack_UA_NodeAttributesMask(SV *in)  __attribute__((unused));
static UA_NodeAttributesMask
XS_unpack_UA_NodeAttributesMask(SV *in)
{
	dTHX;
	return SvIV(in);
}

/* NodeAttributes */
static void XS_pack_UA_NodeAttributes(SV *out, UA_NodeAttributes in)  __attribute__((unused));
static void
XS_pack_UA_NodeAttributes(SV *out, UA_NodeAttributes in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.specifiedAttributes);
	hv_stores(hv, "NodeAttributes_specifiedAttributes", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.displayName);
	hv_stores(hv, "NodeAttributes_displayName", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.description);
	hv_stores(hv, "NodeAttributes_description", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.writeMask);
	hv_stores(hv, "NodeAttributes_writeMask", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.userWriteMask);
	hv_stores(hv, "NodeAttributes_userWriteMask", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_NodeAttributes XS_unpack_UA_NodeAttributes(SV *in)  __attribute__((unused));
static UA_NodeAttributes
XS_unpack_UA_NodeAttributes(SV *in)
{
	dTHX;
	UA_NodeAttributes out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_NodeAttributes_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "NodeAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		out.specifiedAttributes = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "NodeAttributes_displayName", 0);
	if (svp != NULL)
		out.displayName = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "NodeAttributes_description", 0);
	if (svp != NULL)
		out.description = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "NodeAttributes_writeMask", 0);
	if (svp != NULL)
		out.writeMask = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "NodeAttributes_userWriteMask", 0);
	if (svp != NULL)
		out.userWriteMask = XS_unpack_UA_UInt32(*svp);

	return out;
}

/* ObjectAttributes */
static void XS_pack_UA_ObjectAttributes(SV *out, UA_ObjectAttributes in)  __attribute__((unused));
static void
XS_pack_UA_ObjectAttributes(SV *out, UA_ObjectAttributes in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.specifiedAttributes);
	hv_stores(hv, "ObjectAttributes_specifiedAttributes", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.displayName);
	hv_stores(hv, "ObjectAttributes_displayName", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.description);
	hv_stores(hv, "ObjectAttributes_description", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.writeMask);
	hv_stores(hv, "ObjectAttributes_writeMask", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.userWriteMask);
	hv_stores(hv, "ObjectAttributes_userWriteMask", sv);

	sv = newSV(0);
	XS_pack_UA_Byte(sv, in.eventNotifier);
	hv_stores(hv, "ObjectAttributes_eventNotifier", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ObjectAttributes XS_unpack_UA_ObjectAttributes(SV *in)  __attribute__((unused));
static UA_ObjectAttributes
XS_unpack_UA_ObjectAttributes(SV *in)
{
	dTHX;
	UA_ObjectAttributes out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ObjectAttributes_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ObjectAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		out.specifiedAttributes = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ObjectAttributes_displayName", 0);
	if (svp != NULL)
		out.displayName = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "ObjectAttributes_description", 0);
	if (svp != NULL)
		out.description = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "ObjectAttributes_writeMask", 0);
	if (svp != NULL)
		out.writeMask = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ObjectAttributes_userWriteMask", 0);
	if (svp != NULL)
		out.userWriteMask = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ObjectAttributes_eventNotifier", 0);
	if (svp != NULL)
		out.eventNotifier = XS_unpack_UA_Byte(*svp);

	return out;
}

/* VariableAttributes */
static void XS_pack_UA_VariableAttributes(SV *out, UA_VariableAttributes in)  __attribute__((unused));
static void
XS_pack_UA_VariableAttributes(SV *out, UA_VariableAttributes in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.specifiedAttributes);
	hv_stores(hv, "VariableAttributes_specifiedAttributes", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.displayName);
	hv_stores(hv, "VariableAttributes_displayName", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.description);
	hv_stores(hv, "VariableAttributes_description", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.writeMask);
	hv_stores(hv, "VariableAttributes_writeMask", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.userWriteMask);
	hv_stores(hv, "VariableAttributes_userWriteMask", sv);

	sv = newSV(0);
	XS_pack_UA_Variant(sv, in.value);
	hv_stores(hv, "VariableAttributes_value", sv);

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.dataType);
	hv_stores(hv, "VariableAttributes_dataType", sv);

	sv = newSV(0);
	XS_pack_UA_Int32(sv, in.valueRank);
	hv_stores(hv, "VariableAttributes_valueRank", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.arrayDimensionsSize);
	for (i = 0; i < in.arrayDimensionsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_UInt32(sv, in.arrayDimensions[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "VariableAttributes_arrayDimensions", newRV_inc((SV*)av));

	sv = newSV(0);
	XS_pack_UA_Byte(sv, in.accessLevel);
	hv_stores(hv, "VariableAttributes_accessLevel", sv);

	sv = newSV(0);
	XS_pack_UA_Byte(sv, in.userAccessLevel);
	hv_stores(hv, "VariableAttributes_userAccessLevel", sv);

	sv = newSV(0);
	XS_pack_UA_Double(sv, in.minimumSamplingInterval);
	hv_stores(hv, "VariableAttributes_minimumSamplingInterval", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.historizing);
	hv_stores(hv, "VariableAttributes_historizing", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_VariableAttributes XS_unpack_UA_VariableAttributes(SV *in)  __attribute__((unused));
static UA_VariableAttributes
XS_unpack_UA_VariableAttributes(SV *in)
{
	dTHX;
	UA_VariableAttributes out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_VariableAttributes_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "VariableAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		out.specifiedAttributes = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "VariableAttributes_displayName", 0);
	if (svp != NULL)
		out.displayName = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "VariableAttributes_description", 0);
	if (svp != NULL)
		out.description = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "VariableAttributes_writeMask", 0);
	if (svp != NULL)
		out.writeMask = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "VariableAttributes_userWriteMask", 0);
	if (svp != NULL)
		out.userWriteMask = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "VariableAttributes_value", 0);
	if (svp != NULL)
		out.value = XS_unpack_UA_Variant(*svp);

	svp = hv_fetchs(hv, "VariableAttributes_dataType", 0);
	if (svp != NULL)
		out.dataType = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "VariableAttributes_valueRank", 0);
	if (svp != NULL)
		out.valueRank = XS_unpack_UA_Int32(*svp);

	svp = hv_fetchs(hv, "VariableAttributes_arrayDimensions", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for VariableAttributes_arrayDimensions");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.arrayDimensions = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out.arrayDimensions == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.arrayDimensions[i] = XS_unpack_UA_UInt32(*svp);
			}
		}
		out.arrayDimensionsSize = i;
	}

	svp = hv_fetchs(hv, "VariableAttributes_accessLevel", 0);
	if (svp != NULL)
		out.accessLevel = XS_unpack_UA_Byte(*svp);

	svp = hv_fetchs(hv, "VariableAttributes_userAccessLevel", 0);
	if (svp != NULL)
		out.userAccessLevel = XS_unpack_UA_Byte(*svp);

	svp = hv_fetchs(hv, "VariableAttributes_minimumSamplingInterval", 0);
	if (svp != NULL)
		out.minimumSamplingInterval = XS_unpack_UA_Double(*svp);

	svp = hv_fetchs(hv, "VariableAttributes_historizing", 0);
	if (svp != NULL)
		out.historizing = XS_unpack_UA_Boolean(*svp);

	return out;
}

/* MethodAttributes */
static void XS_pack_UA_MethodAttributes(SV *out, UA_MethodAttributes in)  __attribute__((unused));
static void
XS_pack_UA_MethodAttributes(SV *out, UA_MethodAttributes in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.specifiedAttributes);
	hv_stores(hv, "MethodAttributes_specifiedAttributes", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.displayName);
	hv_stores(hv, "MethodAttributes_displayName", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.description);
	hv_stores(hv, "MethodAttributes_description", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.writeMask);
	hv_stores(hv, "MethodAttributes_writeMask", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.userWriteMask);
	hv_stores(hv, "MethodAttributes_userWriteMask", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.executable);
	hv_stores(hv, "MethodAttributes_executable", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.userExecutable);
	hv_stores(hv, "MethodAttributes_userExecutable", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_MethodAttributes XS_unpack_UA_MethodAttributes(SV *in)  __attribute__((unused));
static UA_MethodAttributes
XS_unpack_UA_MethodAttributes(SV *in)
{
	dTHX;
	UA_MethodAttributes out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_MethodAttributes_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "MethodAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		out.specifiedAttributes = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "MethodAttributes_displayName", 0);
	if (svp != NULL)
		out.displayName = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "MethodAttributes_description", 0);
	if (svp != NULL)
		out.description = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "MethodAttributes_writeMask", 0);
	if (svp != NULL)
		out.writeMask = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "MethodAttributes_userWriteMask", 0);
	if (svp != NULL)
		out.userWriteMask = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "MethodAttributes_executable", 0);
	if (svp != NULL)
		out.executable = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "MethodAttributes_userExecutable", 0);
	if (svp != NULL)
		out.userExecutable = XS_unpack_UA_Boolean(*svp);

	return out;
}

/* ObjectTypeAttributes */
static void XS_pack_UA_ObjectTypeAttributes(SV *out, UA_ObjectTypeAttributes in)  __attribute__((unused));
static void
XS_pack_UA_ObjectTypeAttributes(SV *out, UA_ObjectTypeAttributes in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.specifiedAttributes);
	hv_stores(hv, "ObjectTypeAttributes_specifiedAttributes", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.displayName);
	hv_stores(hv, "ObjectTypeAttributes_displayName", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.description);
	hv_stores(hv, "ObjectTypeAttributes_description", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.writeMask);
	hv_stores(hv, "ObjectTypeAttributes_writeMask", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.userWriteMask);
	hv_stores(hv, "ObjectTypeAttributes_userWriteMask", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.isAbstract);
	hv_stores(hv, "ObjectTypeAttributes_isAbstract", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ObjectTypeAttributes XS_unpack_UA_ObjectTypeAttributes(SV *in)  __attribute__((unused));
static UA_ObjectTypeAttributes
XS_unpack_UA_ObjectTypeAttributes(SV *in)
{
	dTHX;
	UA_ObjectTypeAttributes out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ObjectTypeAttributes_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ObjectTypeAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		out.specifiedAttributes = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ObjectTypeAttributes_displayName", 0);
	if (svp != NULL)
		out.displayName = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "ObjectTypeAttributes_description", 0);
	if (svp != NULL)
		out.description = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "ObjectTypeAttributes_writeMask", 0);
	if (svp != NULL)
		out.writeMask = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ObjectTypeAttributes_userWriteMask", 0);
	if (svp != NULL)
		out.userWriteMask = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ObjectTypeAttributes_isAbstract", 0);
	if (svp != NULL)
		out.isAbstract = XS_unpack_UA_Boolean(*svp);

	return out;
}

/* VariableTypeAttributes */
static void XS_pack_UA_VariableTypeAttributes(SV *out, UA_VariableTypeAttributes in)  __attribute__((unused));
static void
XS_pack_UA_VariableTypeAttributes(SV *out, UA_VariableTypeAttributes in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.specifiedAttributes);
	hv_stores(hv, "VariableTypeAttributes_specifiedAttributes", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.displayName);
	hv_stores(hv, "VariableTypeAttributes_displayName", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.description);
	hv_stores(hv, "VariableTypeAttributes_description", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.writeMask);
	hv_stores(hv, "VariableTypeAttributes_writeMask", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.userWriteMask);
	hv_stores(hv, "VariableTypeAttributes_userWriteMask", sv);

	sv = newSV(0);
	XS_pack_UA_Variant(sv, in.value);
	hv_stores(hv, "VariableTypeAttributes_value", sv);

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.dataType);
	hv_stores(hv, "VariableTypeAttributes_dataType", sv);

	sv = newSV(0);
	XS_pack_UA_Int32(sv, in.valueRank);
	hv_stores(hv, "VariableTypeAttributes_valueRank", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.arrayDimensionsSize);
	for (i = 0; i < in.arrayDimensionsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_UInt32(sv, in.arrayDimensions[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "VariableTypeAttributes_arrayDimensions", newRV_inc((SV*)av));

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.isAbstract);
	hv_stores(hv, "VariableTypeAttributes_isAbstract", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_VariableTypeAttributes XS_unpack_UA_VariableTypeAttributes(SV *in)  __attribute__((unused));
static UA_VariableTypeAttributes
XS_unpack_UA_VariableTypeAttributes(SV *in)
{
	dTHX;
	UA_VariableTypeAttributes out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_VariableTypeAttributes_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "VariableTypeAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		out.specifiedAttributes = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "VariableTypeAttributes_displayName", 0);
	if (svp != NULL)
		out.displayName = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "VariableTypeAttributes_description", 0);
	if (svp != NULL)
		out.description = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "VariableTypeAttributes_writeMask", 0);
	if (svp != NULL)
		out.writeMask = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "VariableTypeAttributes_userWriteMask", 0);
	if (svp != NULL)
		out.userWriteMask = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "VariableTypeAttributes_value", 0);
	if (svp != NULL)
		out.value = XS_unpack_UA_Variant(*svp);

	svp = hv_fetchs(hv, "VariableTypeAttributes_dataType", 0);
	if (svp != NULL)
		out.dataType = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "VariableTypeAttributes_valueRank", 0);
	if (svp != NULL)
		out.valueRank = XS_unpack_UA_Int32(*svp);

	svp = hv_fetchs(hv, "VariableTypeAttributes_arrayDimensions", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for VariableTypeAttributes_arrayDimensions");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.arrayDimensions = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out.arrayDimensions == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.arrayDimensions[i] = XS_unpack_UA_UInt32(*svp);
			}
		}
		out.arrayDimensionsSize = i;
	}

	svp = hv_fetchs(hv, "VariableTypeAttributes_isAbstract", 0);
	if (svp != NULL)
		out.isAbstract = XS_unpack_UA_Boolean(*svp);

	return out;
}

/* ReferenceTypeAttributes */
static void XS_pack_UA_ReferenceTypeAttributes(SV *out, UA_ReferenceTypeAttributes in)  __attribute__((unused));
static void
XS_pack_UA_ReferenceTypeAttributes(SV *out, UA_ReferenceTypeAttributes in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.specifiedAttributes);
	hv_stores(hv, "ReferenceTypeAttributes_specifiedAttributes", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.displayName);
	hv_stores(hv, "ReferenceTypeAttributes_displayName", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.description);
	hv_stores(hv, "ReferenceTypeAttributes_description", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.writeMask);
	hv_stores(hv, "ReferenceTypeAttributes_writeMask", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.userWriteMask);
	hv_stores(hv, "ReferenceTypeAttributes_userWriteMask", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.isAbstract);
	hv_stores(hv, "ReferenceTypeAttributes_isAbstract", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.symmetric);
	hv_stores(hv, "ReferenceTypeAttributes_symmetric", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.inverseName);
	hv_stores(hv, "ReferenceTypeAttributes_inverseName", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ReferenceTypeAttributes XS_unpack_UA_ReferenceTypeAttributes(SV *in)  __attribute__((unused));
static UA_ReferenceTypeAttributes
XS_unpack_UA_ReferenceTypeAttributes(SV *in)
{
	dTHX;
	UA_ReferenceTypeAttributes out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ReferenceTypeAttributes_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ReferenceTypeAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		out.specifiedAttributes = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ReferenceTypeAttributes_displayName", 0);
	if (svp != NULL)
		out.displayName = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "ReferenceTypeAttributes_description", 0);
	if (svp != NULL)
		out.description = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "ReferenceTypeAttributes_writeMask", 0);
	if (svp != NULL)
		out.writeMask = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ReferenceTypeAttributes_userWriteMask", 0);
	if (svp != NULL)
		out.userWriteMask = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ReferenceTypeAttributes_isAbstract", 0);
	if (svp != NULL)
		out.isAbstract = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "ReferenceTypeAttributes_symmetric", 0);
	if (svp != NULL)
		out.symmetric = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "ReferenceTypeAttributes_inverseName", 0);
	if (svp != NULL)
		out.inverseName = XS_unpack_UA_LocalizedText(*svp);

	return out;
}

/* DataTypeAttributes */
static void XS_pack_UA_DataTypeAttributes(SV *out, UA_DataTypeAttributes in)  __attribute__((unused));
static void
XS_pack_UA_DataTypeAttributes(SV *out, UA_DataTypeAttributes in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.specifiedAttributes);
	hv_stores(hv, "DataTypeAttributes_specifiedAttributes", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.displayName);
	hv_stores(hv, "DataTypeAttributes_displayName", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.description);
	hv_stores(hv, "DataTypeAttributes_description", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.writeMask);
	hv_stores(hv, "DataTypeAttributes_writeMask", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.userWriteMask);
	hv_stores(hv, "DataTypeAttributes_userWriteMask", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.isAbstract);
	hv_stores(hv, "DataTypeAttributes_isAbstract", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_DataTypeAttributes XS_unpack_UA_DataTypeAttributes(SV *in)  __attribute__((unused));
static UA_DataTypeAttributes
XS_unpack_UA_DataTypeAttributes(SV *in)
{
	dTHX;
	UA_DataTypeAttributes out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_DataTypeAttributes_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DataTypeAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		out.specifiedAttributes = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "DataTypeAttributes_displayName", 0);
	if (svp != NULL)
		out.displayName = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "DataTypeAttributes_description", 0);
	if (svp != NULL)
		out.description = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "DataTypeAttributes_writeMask", 0);
	if (svp != NULL)
		out.writeMask = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "DataTypeAttributes_userWriteMask", 0);
	if (svp != NULL)
		out.userWriteMask = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "DataTypeAttributes_isAbstract", 0);
	if (svp != NULL)
		out.isAbstract = XS_unpack_UA_Boolean(*svp);

	return out;
}

/* ViewAttributes */
static void XS_pack_UA_ViewAttributes(SV *out, UA_ViewAttributes in)  __attribute__((unused));
static void
XS_pack_UA_ViewAttributes(SV *out, UA_ViewAttributes in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.specifiedAttributes);
	hv_stores(hv, "ViewAttributes_specifiedAttributes", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.displayName);
	hv_stores(hv, "ViewAttributes_displayName", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.description);
	hv_stores(hv, "ViewAttributes_description", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.writeMask);
	hv_stores(hv, "ViewAttributes_writeMask", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.userWriteMask);
	hv_stores(hv, "ViewAttributes_userWriteMask", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.containsNoLoops);
	hv_stores(hv, "ViewAttributes_containsNoLoops", sv);

	sv = newSV(0);
	XS_pack_UA_Byte(sv, in.eventNotifier);
	hv_stores(hv, "ViewAttributes_eventNotifier", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ViewAttributes XS_unpack_UA_ViewAttributes(SV *in)  __attribute__((unused));
static UA_ViewAttributes
XS_unpack_UA_ViewAttributes(SV *in)
{
	dTHX;
	UA_ViewAttributes out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ViewAttributes_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ViewAttributes_specifiedAttributes", 0);
	if (svp != NULL)
		out.specifiedAttributes = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ViewAttributes_displayName", 0);
	if (svp != NULL)
		out.displayName = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "ViewAttributes_description", 0);
	if (svp != NULL)
		out.description = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "ViewAttributes_writeMask", 0);
	if (svp != NULL)
		out.writeMask = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ViewAttributes_userWriteMask", 0);
	if (svp != NULL)
		out.userWriteMask = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ViewAttributes_containsNoLoops", 0);
	if (svp != NULL)
		out.containsNoLoops = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "ViewAttributes_eventNotifier", 0);
	if (svp != NULL)
		out.eventNotifier = XS_unpack_UA_Byte(*svp);

	return out;
}

/* AddNodesItem */
static void XS_pack_UA_AddNodesItem(SV *out, UA_AddNodesItem in)  __attribute__((unused));
static void
XS_pack_UA_AddNodesItem(SV *out, UA_AddNodesItem in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ExpandedNodeId(sv, in.parentNodeId);
	hv_stores(hv, "AddNodesItem_parentNodeId", sv);

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.referenceTypeId);
	hv_stores(hv, "AddNodesItem_referenceTypeId", sv);

	sv = newSV(0);
	XS_pack_UA_ExpandedNodeId(sv, in.requestedNewNodeId);
	hv_stores(hv, "AddNodesItem_requestedNewNodeId", sv);

	sv = newSV(0);
	XS_pack_UA_QualifiedName(sv, in.browseName);
	hv_stores(hv, "AddNodesItem_browseName", sv);

	sv = newSV(0);
	XS_pack_UA_NodeClass(sv, in.nodeClass);
	hv_stores(hv, "AddNodesItem_nodeClass", sv);

	sv = newSV(0);
	XS_pack_UA_ExtensionObject(sv, in.nodeAttributes);
	hv_stores(hv, "AddNodesItem_nodeAttributes", sv);

	sv = newSV(0);
	XS_pack_UA_ExpandedNodeId(sv, in.typeDefinition);
	hv_stores(hv, "AddNodesItem_typeDefinition", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_AddNodesItem XS_unpack_UA_AddNodesItem(SV *in)  __attribute__((unused));
static UA_AddNodesItem
XS_unpack_UA_AddNodesItem(SV *in)
{
	dTHX;
	UA_AddNodesItem out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_AddNodesItem_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AddNodesItem_parentNodeId", 0);
	if (svp != NULL)
		out.parentNodeId = XS_unpack_UA_ExpandedNodeId(*svp);

	svp = hv_fetchs(hv, "AddNodesItem_referenceTypeId", 0);
	if (svp != NULL)
		out.referenceTypeId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "AddNodesItem_requestedNewNodeId", 0);
	if (svp != NULL)
		out.requestedNewNodeId = XS_unpack_UA_ExpandedNodeId(*svp);

	svp = hv_fetchs(hv, "AddNodesItem_browseName", 0);
	if (svp != NULL)
		out.browseName = XS_unpack_UA_QualifiedName(*svp);

	svp = hv_fetchs(hv, "AddNodesItem_nodeClass", 0);
	if (svp != NULL)
		out.nodeClass = XS_unpack_UA_NodeClass(*svp);

	svp = hv_fetchs(hv, "AddNodesItem_nodeAttributes", 0);
	if (svp != NULL)
		out.nodeAttributes = XS_unpack_UA_ExtensionObject(*svp);

	svp = hv_fetchs(hv, "AddNodesItem_typeDefinition", 0);
	if (svp != NULL)
		out.typeDefinition = XS_unpack_UA_ExpandedNodeId(*svp);

	return out;
}

/* AddNodesResult */
static void XS_pack_UA_AddNodesResult(SV *out, UA_AddNodesResult in)  __attribute__((unused));
static void
XS_pack_UA_AddNodesResult(SV *out, UA_AddNodesResult in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_StatusCode(sv, in.statusCode);
	hv_stores(hv, "AddNodesResult_statusCode", sv);

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.addedNodeId);
	hv_stores(hv, "AddNodesResult_addedNodeId", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_AddNodesResult XS_unpack_UA_AddNodesResult(SV *in)  __attribute__((unused));
static UA_AddNodesResult
XS_unpack_UA_AddNodesResult(SV *in)
{
	dTHX;
	UA_AddNodesResult out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_AddNodesResult_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AddNodesResult_statusCode", 0);
	if (svp != NULL)
		out.statusCode = XS_unpack_UA_StatusCode(*svp);

	svp = hv_fetchs(hv, "AddNodesResult_addedNodeId", 0);
	if (svp != NULL)
		out.addedNodeId = XS_unpack_UA_NodeId(*svp);

	return out;
}

/* AddNodesRequest */
static void XS_pack_UA_AddNodesRequest(SV *out, UA_AddNodesRequest in)  __attribute__((unused));
static void
XS_pack_UA_AddNodesRequest(SV *out, UA_AddNodesRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "AddNodesRequest_requestHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.nodesToAddSize);
	for (i = 0; i < in.nodesToAddSize; i++) {
		sv = newSV(0);
		XS_pack_UA_AddNodesItem(sv, in.nodesToAdd[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "AddNodesRequest_nodesToAdd", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_AddNodesRequest XS_unpack_UA_AddNodesRequest(SV *in)  __attribute__((unused));
static UA_AddNodesRequest
XS_unpack_UA_AddNodesRequest(SV *in)
{
	dTHX;
	UA_AddNodesRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_AddNodesRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AddNodesRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "AddNodesRequest_nodesToAdd", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for AddNodesRequest_nodesToAdd");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.nodesToAdd = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ADDNODESITEM]);
		if (out.nodesToAdd == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.nodesToAdd[i] = XS_unpack_UA_AddNodesItem(*svp);
			}
		}
		out.nodesToAddSize = i;
	}

	return out;
}

/* AddNodesResponse */
static void XS_pack_UA_AddNodesResponse(SV *out, UA_AddNodesResponse in)  __attribute__((unused));
static void
XS_pack_UA_AddNodesResponse(SV *out, UA_AddNodesResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "AddNodesResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.resultsSize);
	for (i = 0; i < in.resultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_AddNodesResult(sv, in.results[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "AddNodesResponse_results", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "AddNodesResponse_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_AddNodesResponse XS_unpack_UA_AddNodesResponse(SV *in)  __attribute__((unused));
static UA_AddNodesResponse
XS_unpack_UA_AddNodesResponse(SV *in)
{
	dTHX;
	UA_AddNodesResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_AddNodesResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AddNodesResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "AddNodesResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for AddNodesResponse_results");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ADDNODESRESULT]);
		if (out.results == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.results[i] = XS_unpack_UA_AddNodesResult(*svp);
			}
		}
		out.resultsSize = i;
	}

	svp = hv_fetchs(hv, "AddNodesResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for AddNodesResponse_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* AddReferencesItem */
static void XS_pack_UA_AddReferencesItem(SV *out, UA_AddReferencesItem in)  __attribute__((unused));
static void
XS_pack_UA_AddReferencesItem(SV *out, UA_AddReferencesItem in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.sourceNodeId);
	hv_stores(hv, "AddReferencesItem_sourceNodeId", sv);

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.referenceTypeId);
	hv_stores(hv, "AddReferencesItem_referenceTypeId", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.isForward);
	hv_stores(hv, "AddReferencesItem_isForward", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.targetServerUri);
	hv_stores(hv, "AddReferencesItem_targetServerUri", sv);

	sv = newSV(0);
	XS_pack_UA_ExpandedNodeId(sv, in.targetNodeId);
	hv_stores(hv, "AddReferencesItem_targetNodeId", sv);

	sv = newSV(0);
	XS_pack_UA_NodeClass(sv, in.targetNodeClass);
	hv_stores(hv, "AddReferencesItem_targetNodeClass", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_AddReferencesItem XS_unpack_UA_AddReferencesItem(SV *in)  __attribute__((unused));
static UA_AddReferencesItem
XS_unpack_UA_AddReferencesItem(SV *in)
{
	dTHX;
	UA_AddReferencesItem out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_AddReferencesItem_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AddReferencesItem_sourceNodeId", 0);
	if (svp != NULL)
		out.sourceNodeId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "AddReferencesItem_referenceTypeId", 0);
	if (svp != NULL)
		out.referenceTypeId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "AddReferencesItem_isForward", 0);
	if (svp != NULL)
		out.isForward = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "AddReferencesItem_targetServerUri", 0);
	if (svp != NULL)
		out.targetServerUri = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "AddReferencesItem_targetNodeId", 0);
	if (svp != NULL)
		out.targetNodeId = XS_unpack_UA_ExpandedNodeId(*svp);

	svp = hv_fetchs(hv, "AddReferencesItem_targetNodeClass", 0);
	if (svp != NULL)
		out.targetNodeClass = XS_unpack_UA_NodeClass(*svp);

	return out;
}

/* AddReferencesRequest */
static void XS_pack_UA_AddReferencesRequest(SV *out, UA_AddReferencesRequest in)  __attribute__((unused));
static void
XS_pack_UA_AddReferencesRequest(SV *out, UA_AddReferencesRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "AddReferencesRequest_requestHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.referencesToAddSize);
	for (i = 0; i < in.referencesToAddSize; i++) {
		sv = newSV(0);
		XS_pack_UA_AddReferencesItem(sv, in.referencesToAdd[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "AddReferencesRequest_referencesToAdd", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_AddReferencesRequest XS_unpack_UA_AddReferencesRequest(SV *in)  __attribute__((unused));
static UA_AddReferencesRequest
XS_unpack_UA_AddReferencesRequest(SV *in)
{
	dTHX;
	UA_AddReferencesRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_AddReferencesRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AddReferencesRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "AddReferencesRequest_referencesToAdd", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for AddReferencesRequest_referencesToAdd");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.referencesToAdd = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_ADDREFERENCESITEM]);
		if (out.referencesToAdd == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.referencesToAdd[i] = XS_unpack_UA_AddReferencesItem(*svp);
			}
		}
		out.referencesToAddSize = i;
	}

	return out;
}

/* AddReferencesResponse */
static void XS_pack_UA_AddReferencesResponse(SV *out, UA_AddReferencesResponse in)  __attribute__((unused));
static void
XS_pack_UA_AddReferencesResponse(SV *out, UA_AddReferencesResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "AddReferencesResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.resultsSize);
	for (i = 0; i < in.resultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_StatusCode(sv, in.results[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "AddReferencesResponse_results", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "AddReferencesResponse_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_AddReferencesResponse XS_unpack_UA_AddReferencesResponse(SV *in)  __attribute__((unused));
static UA_AddReferencesResponse
XS_unpack_UA_AddReferencesResponse(SV *in)
{
	dTHX;
	UA_AddReferencesResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_AddReferencesResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AddReferencesResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "AddReferencesResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for AddReferencesResponse_results");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out.results == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.results[i] = XS_unpack_UA_StatusCode(*svp);
			}
		}
		out.resultsSize = i;
	}

	svp = hv_fetchs(hv, "AddReferencesResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for AddReferencesResponse_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* DeleteNodesItem */
static void XS_pack_UA_DeleteNodesItem(SV *out, UA_DeleteNodesItem in)  __attribute__((unused));
static void
XS_pack_UA_DeleteNodesItem(SV *out, UA_DeleteNodesItem in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.nodeId);
	hv_stores(hv, "DeleteNodesItem_nodeId", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.deleteTargetReferences);
	hv_stores(hv, "DeleteNodesItem_deleteTargetReferences", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_DeleteNodesItem XS_unpack_UA_DeleteNodesItem(SV *in)  __attribute__((unused));
static UA_DeleteNodesItem
XS_unpack_UA_DeleteNodesItem(SV *in)
{
	dTHX;
	UA_DeleteNodesItem out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_DeleteNodesItem_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteNodesItem_nodeId", 0);
	if (svp != NULL)
		out.nodeId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "DeleteNodesItem_deleteTargetReferences", 0);
	if (svp != NULL)
		out.deleteTargetReferences = XS_unpack_UA_Boolean(*svp);

	return out;
}

/* DeleteNodesRequest */
static void XS_pack_UA_DeleteNodesRequest(SV *out, UA_DeleteNodesRequest in)  __attribute__((unused));
static void
XS_pack_UA_DeleteNodesRequest(SV *out, UA_DeleteNodesRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "DeleteNodesRequest_requestHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.nodesToDeleteSize);
	for (i = 0; i < in.nodesToDeleteSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DeleteNodesItem(sv, in.nodesToDelete[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "DeleteNodesRequest_nodesToDelete", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_DeleteNodesRequest XS_unpack_UA_DeleteNodesRequest(SV *in)  __attribute__((unused));
static UA_DeleteNodesRequest
XS_unpack_UA_DeleteNodesRequest(SV *in)
{
	dTHX;
	UA_DeleteNodesRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_DeleteNodesRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteNodesRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "DeleteNodesRequest_nodesToDelete", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for DeleteNodesRequest_nodesToDelete");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.nodesToDelete = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DELETENODESITEM]);
		if (out.nodesToDelete == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.nodesToDelete[i] = XS_unpack_UA_DeleteNodesItem(*svp);
			}
		}
		out.nodesToDeleteSize = i;
	}

	return out;
}

/* DeleteNodesResponse */
static void XS_pack_UA_DeleteNodesResponse(SV *out, UA_DeleteNodesResponse in)  __attribute__((unused));
static void
XS_pack_UA_DeleteNodesResponse(SV *out, UA_DeleteNodesResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "DeleteNodesResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.resultsSize);
	for (i = 0; i < in.resultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_StatusCode(sv, in.results[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "DeleteNodesResponse_results", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "DeleteNodesResponse_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_DeleteNodesResponse XS_unpack_UA_DeleteNodesResponse(SV *in)  __attribute__((unused));
static UA_DeleteNodesResponse
XS_unpack_UA_DeleteNodesResponse(SV *in)
{
	dTHX;
	UA_DeleteNodesResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_DeleteNodesResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteNodesResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "DeleteNodesResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for DeleteNodesResponse_results");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out.results == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.results[i] = XS_unpack_UA_StatusCode(*svp);
			}
		}
		out.resultsSize = i;
	}

	svp = hv_fetchs(hv, "DeleteNodesResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for DeleteNodesResponse_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* DeleteReferencesItem */
static void XS_pack_UA_DeleteReferencesItem(SV *out, UA_DeleteReferencesItem in)  __attribute__((unused));
static void
XS_pack_UA_DeleteReferencesItem(SV *out, UA_DeleteReferencesItem in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.sourceNodeId);
	hv_stores(hv, "DeleteReferencesItem_sourceNodeId", sv);

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.referenceTypeId);
	hv_stores(hv, "DeleteReferencesItem_referenceTypeId", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.isForward);
	hv_stores(hv, "DeleteReferencesItem_isForward", sv);

	sv = newSV(0);
	XS_pack_UA_ExpandedNodeId(sv, in.targetNodeId);
	hv_stores(hv, "DeleteReferencesItem_targetNodeId", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.deleteBidirectional);
	hv_stores(hv, "DeleteReferencesItem_deleteBidirectional", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_DeleteReferencesItem XS_unpack_UA_DeleteReferencesItem(SV *in)  __attribute__((unused));
static UA_DeleteReferencesItem
XS_unpack_UA_DeleteReferencesItem(SV *in)
{
	dTHX;
	UA_DeleteReferencesItem out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_DeleteReferencesItem_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteReferencesItem_sourceNodeId", 0);
	if (svp != NULL)
		out.sourceNodeId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "DeleteReferencesItem_referenceTypeId", 0);
	if (svp != NULL)
		out.referenceTypeId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "DeleteReferencesItem_isForward", 0);
	if (svp != NULL)
		out.isForward = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DeleteReferencesItem_targetNodeId", 0);
	if (svp != NULL)
		out.targetNodeId = XS_unpack_UA_ExpandedNodeId(*svp);

	svp = hv_fetchs(hv, "DeleteReferencesItem_deleteBidirectional", 0);
	if (svp != NULL)
		out.deleteBidirectional = XS_unpack_UA_Boolean(*svp);

	return out;
}

/* DeleteReferencesRequest */
static void XS_pack_UA_DeleteReferencesRequest(SV *out, UA_DeleteReferencesRequest in)  __attribute__((unused));
static void
XS_pack_UA_DeleteReferencesRequest(SV *out, UA_DeleteReferencesRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "DeleteReferencesRequest_requestHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.referencesToDeleteSize);
	for (i = 0; i < in.referencesToDeleteSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DeleteReferencesItem(sv, in.referencesToDelete[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "DeleteReferencesRequest_referencesToDelete", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_DeleteReferencesRequest XS_unpack_UA_DeleteReferencesRequest(SV *in)  __attribute__((unused));
static UA_DeleteReferencesRequest
XS_unpack_UA_DeleteReferencesRequest(SV *in)
{
	dTHX;
	UA_DeleteReferencesRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_DeleteReferencesRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteReferencesRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "DeleteReferencesRequest_referencesToDelete", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for DeleteReferencesRequest_referencesToDelete");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.referencesToDelete = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DELETEREFERENCESITEM]);
		if (out.referencesToDelete == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.referencesToDelete[i] = XS_unpack_UA_DeleteReferencesItem(*svp);
			}
		}
		out.referencesToDeleteSize = i;
	}

	return out;
}

/* DeleteReferencesResponse */
static void XS_pack_UA_DeleteReferencesResponse(SV *out, UA_DeleteReferencesResponse in)  __attribute__((unused));
static void
XS_pack_UA_DeleteReferencesResponse(SV *out, UA_DeleteReferencesResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "DeleteReferencesResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.resultsSize);
	for (i = 0; i < in.resultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_StatusCode(sv, in.results[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "DeleteReferencesResponse_results", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "DeleteReferencesResponse_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_DeleteReferencesResponse XS_unpack_UA_DeleteReferencesResponse(SV *in)  __attribute__((unused));
static UA_DeleteReferencesResponse
XS_unpack_UA_DeleteReferencesResponse(SV *in)
{
	dTHX;
	UA_DeleteReferencesResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_DeleteReferencesResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteReferencesResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "DeleteReferencesResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for DeleteReferencesResponse_results");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out.results == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.results[i] = XS_unpack_UA_StatusCode(*svp);
			}
		}
		out.resultsSize = i;
	}

	svp = hv_fetchs(hv, "DeleteReferencesResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for DeleteReferencesResponse_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* BrowseDirection */
static void XS_pack_UA_BrowseDirection(SV *out, UA_BrowseDirection in)  __attribute__((unused));
static void
XS_pack_UA_BrowseDirection(SV *out, UA_BrowseDirection in)
{
	dTHX;
	sv_setiv(out, in);
}

static UA_BrowseDirection XS_unpack_UA_BrowseDirection(SV *in)  __attribute__((unused));
static UA_BrowseDirection
XS_unpack_UA_BrowseDirection(SV *in)
{
	dTHX;
	return SvIV(in);
}

/* ViewDescription */
static void XS_pack_UA_ViewDescription(SV *out, UA_ViewDescription in)  __attribute__((unused));
static void
XS_pack_UA_ViewDescription(SV *out, UA_ViewDescription in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.viewId);
	hv_stores(hv, "ViewDescription_viewId", sv);

	sv = newSV(0);
	XS_pack_UA_DateTime(sv, in.timestamp);
	hv_stores(hv, "ViewDescription_timestamp", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.viewVersion);
	hv_stores(hv, "ViewDescription_viewVersion", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ViewDescription XS_unpack_UA_ViewDescription(SV *in)  __attribute__((unused));
static UA_ViewDescription
XS_unpack_UA_ViewDescription(SV *in)
{
	dTHX;
	UA_ViewDescription out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ViewDescription_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ViewDescription_viewId", 0);
	if (svp != NULL)
		out.viewId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "ViewDescription_timestamp", 0);
	if (svp != NULL)
		out.timestamp = XS_unpack_UA_DateTime(*svp);

	svp = hv_fetchs(hv, "ViewDescription_viewVersion", 0);
	if (svp != NULL)
		out.viewVersion = XS_unpack_UA_UInt32(*svp);

	return out;
}

/* BrowseDescription */
static void XS_pack_UA_BrowseDescription(SV *out, UA_BrowseDescription in)  __attribute__((unused));
static void
XS_pack_UA_BrowseDescription(SV *out, UA_BrowseDescription in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.nodeId);
	hv_stores(hv, "BrowseDescription_nodeId", sv);

	sv = newSV(0);
	XS_pack_UA_BrowseDirection(sv, in.browseDirection);
	hv_stores(hv, "BrowseDescription_browseDirection", sv);

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.referenceTypeId);
	hv_stores(hv, "BrowseDescription_referenceTypeId", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.includeSubtypes);
	hv_stores(hv, "BrowseDescription_includeSubtypes", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.nodeClassMask);
	hv_stores(hv, "BrowseDescription_nodeClassMask", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.resultMask);
	hv_stores(hv, "BrowseDescription_resultMask", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_BrowseDescription XS_unpack_UA_BrowseDescription(SV *in)  __attribute__((unused));
static UA_BrowseDescription
XS_unpack_UA_BrowseDescription(SV *in)
{
	dTHX;
	UA_BrowseDescription out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_BrowseDescription_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrowseDescription_nodeId", 0);
	if (svp != NULL)
		out.nodeId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "BrowseDescription_browseDirection", 0);
	if (svp != NULL)
		out.browseDirection = XS_unpack_UA_BrowseDirection(*svp);

	svp = hv_fetchs(hv, "BrowseDescription_referenceTypeId", 0);
	if (svp != NULL)
		out.referenceTypeId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "BrowseDescription_includeSubtypes", 0);
	if (svp != NULL)
		out.includeSubtypes = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "BrowseDescription_nodeClassMask", 0);
	if (svp != NULL)
		out.nodeClassMask = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "BrowseDescription_resultMask", 0);
	if (svp != NULL)
		out.resultMask = XS_unpack_UA_UInt32(*svp);

	return out;
}

/* BrowseResultMask */
static void XS_pack_UA_BrowseResultMask(SV *out, UA_BrowseResultMask in)  __attribute__((unused));
static void
XS_pack_UA_BrowseResultMask(SV *out, UA_BrowseResultMask in)
{
	dTHX;
	sv_setiv(out, in);
}

static UA_BrowseResultMask XS_unpack_UA_BrowseResultMask(SV *in)  __attribute__((unused));
static UA_BrowseResultMask
XS_unpack_UA_BrowseResultMask(SV *in)
{
	dTHX;
	return SvIV(in);
}

/* ReferenceDescription */
static void XS_pack_UA_ReferenceDescription(SV *out, UA_ReferenceDescription in)  __attribute__((unused));
static void
XS_pack_UA_ReferenceDescription(SV *out, UA_ReferenceDescription in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.referenceTypeId);
	hv_stores(hv, "ReferenceDescription_referenceTypeId", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.isForward);
	hv_stores(hv, "ReferenceDescription_isForward", sv);

	sv = newSV(0);
	XS_pack_UA_ExpandedNodeId(sv, in.nodeId);
	hv_stores(hv, "ReferenceDescription_nodeId", sv);

	sv = newSV(0);
	XS_pack_UA_QualifiedName(sv, in.browseName);
	hv_stores(hv, "ReferenceDescription_browseName", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.displayName);
	hv_stores(hv, "ReferenceDescription_displayName", sv);

	sv = newSV(0);
	XS_pack_UA_NodeClass(sv, in.nodeClass);
	hv_stores(hv, "ReferenceDescription_nodeClass", sv);

	sv = newSV(0);
	XS_pack_UA_ExpandedNodeId(sv, in.typeDefinition);
	hv_stores(hv, "ReferenceDescription_typeDefinition", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ReferenceDescription XS_unpack_UA_ReferenceDescription(SV *in)  __attribute__((unused));
static UA_ReferenceDescription
XS_unpack_UA_ReferenceDescription(SV *in)
{
	dTHX;
	UA_ReferenceDescription out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ReferenceDescription_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ReferenceDescription_referenceTypeId", 0);
	if (svp != NULL)
		out.referenceTypeId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "ReferenceDescription_isForward", 0);
	if (svp != NULL)
		out.isForward = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "ReferenceDescription_nodeId", 0);
	if (svp != NULL)
		out.nodeId = XS_unpack_UA_ExpandedNodeId(*svp);

	svp = hv_fetchs(hv, "ReferenceDescription_browseName", 0);
	if (svp != NULL)
		out.browseName = XS_unpack_UA_QualifiedName(*svp);

	svp = hv_fetchs(hv, "ReferenceDescription_displayName", 0);
	if (svp != NULL)
		out.displayName = XS_unpack_UA_LocalizedText(*svp);

	svp = hv_fetchs(hv, "ReferenceDescription_nodeClass", 0);
	if (svp != NULL)
		out.nodeClass = XS_unpack_UA_NodeClass(*svp);

	svp = hv_fetchs(hv, "ReferenceDescription_typeDefinition", 0);
	if (svp != NULL)
		out.typeDefinition = XS_unpack_UA_ExpandedNodeId(*svp);

	return out;
}

/* BrowseResult */
static void XS_pack_UA_BrowseResult(SV *out, UA_BrowseResult in)  __attribute__((unused));
static void
XS_pack_UA_BrowseResult(SV *out, UA_BrowseResult in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_StatusCode(sv, in.statusCode);
	hv_stores(hv, "BrowseResult_statusCode", sv);

	sv = newSV(0);
	XS_pack_UA_ByteString(sv, in.continuationPoint);
	hv_stores(hv, "BrowseResult_continuationPoint", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.referencesSize);
	for (i = 0; i < in.referencesSize; i++) {
		sv = newSV(0);
		XS_pack_UA_ReferenceDescription(sv, in.references[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "BrowseResult_references", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_BrowseResult XS_unpack_UA_BrowseResult(SV *in)  __attribute__((unused));
static UA_BrowseResult
XS_unpack_UA_BrowseResult(SV *in)
{
	dTHX;
	UA_BrowseResult out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_BrowseResult_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrowseResult_statusCode", 0);
	if (svp != NULL)
		out.statusCode = XS_unpack_UA_StatusCode(*svp);

	svp = hv_fetchs(hv, "BrowseResult_continuationPoint", 0);
	if (svp != NULL)
		out.continuationPoint = XS_unpack_UA_ByteString(*svp);

	svp = hv_fetchs(hv, "BrowseResult_references", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for BrowseResult_references");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.references = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_REFERENCEDESCRIPTION]);
		if (out.references == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.references[i] = XS_unpack_UA_ReferenceDescription(*svp);
			}
		}
		out.referencesSize = i;
	}

	return out;
}

/* BrowseRequest */
static void XS_pack_UA_BrowseRequest(SV *out, UA_BrowseRequest in)  __attribute__((unused));
static void
XS_pack_UA_BrowseRequest(SV *out, UA_BrowseRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "BrowseRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_ViewDescription(sv, in.view);
	hv_stores(hv, "BrowseRequest_view", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.requestedMaxReferencesPerNode);
	hv_stores(hv, "BrowseRequest_requestedMaxReferencesPerNode", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.nodesToBrowseSize);
	for (i = 0; i < in.nodesToBrowseSize; i++) {
		sv = newSV(0);
		XS_pack_UA_BrowseDescription(sv, in.nodesToBrowse[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "BrowseRequest_nodesToBrowse", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_BrowseRequest XS_unpack_UA_BrowseRequest(SV *in)  __attribute__((unused));
static UA_BrowseRequest
XS_unpack_UA_BrowseRequest(SV *in)
{
	dTHX;
	UA_BrowseRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_BrowseRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrowseRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "BrowseRequest_view", 0);
	if (svp != NULL)
		out.view = XS_unpack_UA_ViewDescription(*svp);

	svp = hv_fetchs(hv, "BrowseRequest_requestedMaxReferencesPerNode", 0);
	if (svp != NULL)
		out.requestedMaxReferencesPerNode = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "BrowseRequest_nodesToBrowse", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for BrowseRequest_nodesToBrowse");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.nodesToBrowse = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BROWSEDESCRIPTION]);
		if (out.nodesToBrowse == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.nodesToBrowse[i] = XS_unpack_UA_BrowseDescription(*svp);
			}
		}
		out.nodesToBrowseSize = i;
	}

	return out;
}

/* BrowseResponse */
static void XS_pack_UA_BrowseResponse(SV *out, UA_BrowseResponse in)  __attribute__((unused));
static void
XS_pack_UA_BrowseResponse(SV *out, UA_BrowseResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "BrowseResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.resultsSize);
	for (i = 0; i < in.resultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_BrowseResult(sv, in.results[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "BrowseResponse_results", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "BrowseResponse_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_BrowseResponse XS_unpack_UA_BrowseResponse(SV *in)  __attribute__((unused));
static UA_BrowseResponse
XS_unpack_UA_BrowseResponse(SV *in)
{
	dTHX;
	UA_BrowseResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_BrowseResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrowseResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "BrowseResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for BrowseResponse_results");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BROWSERESULT]);
		if (out.results == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.results[i] = XS_unpack_UA_BrowseResult(*svp);
			}
		}
		out.resultsSize = i;
	}

	svp = hv_fetchs(hv, "BrowseResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for BrowseResponse_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* BrowseNextRequest */
static void XS_pack_UA_BrowseNextRequest(SV *out, UA_BrowseNextRequest in)  __attribute__((unused));
static void
XS_pack_UA_BrowseNextRequest(SV *out, UA_BrowseNextRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "BrowseNextRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.releaseContinuationPoints);
	hv_stores(hv, "BrowseNextRequest_releaseContinuationPoints", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.continuationPointsSize);
	for (i = 0; i < in.continuationPointsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_ByteString(sv, in.continuationPoints[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "BrowseNextRequest_continuationPoints", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_BrowseNextRequest XS_unpack_UA_BrowseNextRequest(SV *in)  __attribute__((unused));
static UA_BrowseNextRequest
XS_unpack_UA_BrowseNextRequest(SV *in)
{
	dTHX;
	UA_BrowseNextRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_BrowseNextRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrowseNextRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "BrowseNextRequest_releaseContinuationPoints", 0);
	if (svp != NULL)
		out.releaseContinuationPoints = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "BrowseNextRequest_continuationPoints", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for BrowseNextRequest_continuationPoints");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.continuationPoints = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BYTESTRING]);
		if (out.continuationPoints == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.continuationPoints[i] = XS_unpack_UA_ByteString(*svp);
			}
		}
		out.continuationPointsSize = i;
	}

	return out;
}

/* BrowseNextResponse */
static void XS_pack_UA_BrowseNextResponse(SV *out, UA_BrowseNextResponse in)  __attribute__((unused));
static void
XS_pack_UA_BrowseNextResponse(SV *out, UA_BrowseNextResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "BrowseNextResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.resultsSize);
	for (i = 0; i < in.resultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_BrowseResult(sv, in.results[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "BrowseNextResponse_results", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "BrowseNextResponse_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_BrowseNextResponse XS_unpack_UA_BrowseNextResponse(SV *in)  __attribute__((unused));
static UA_BrowseNextResponse
XS_unpack_UA_BrowseNextResponse(SV *in)
{
	dTHX;
	UA_BrowseNextResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_BrowseNextResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrowseNextResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "BrowseNextResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for BrowseNextResponse_results");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BROWSERESULT]);
		if (out.results == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.results[i] = XS_unpack_UA_BrowseResult(*svp);
			}
		}
		out.resultsSize = i;
	}

	svp = hv_fetchs(hv, "BrowseNextResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for BrowseNextResponse_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* RelativePathElement */
static void XS_pack_UA_RelativePathElement(SV *out, UA_RelativePathElement in)  __attribute__((unused));
static void
XS_pack_UA_RelativePathElement(SV *out, UA_RelativePathElement in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.referenceTypeId);
	hv_stores(hv, "RelativePathElement_referenceTypeId", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.isInverse);
	hv_stores(hv, "RelativePathElement_isInverse", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.includeSubtypes);
	hv_stores(hv, "RelativePathElement_includeSubtypes", sv);

	sv = newSV(0);
	XS_pack_UA_QualifiedName(sv, in.targetName);
	hv_stores(hv, "RelativePathElement_targetName", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_RelativePathElement XS_unpack_UA_RelativePathElement(SV *in)  __attribute__((unused));
static UA_RelativePathElement
XS_unpack_UA_RelativePathElement(SV *in)
{
	dTHX;
	UA_RelativePathElement out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_RelativePathElement_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RelativePathElement_referenceTypeId", 0);
	if (svp != NULL)
		out.referenceTypeId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "RelativePathElement_isInverse", 0);
	if (svp != NULL)
		out.isInverse = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "RelativePathElement_includeSubtypes", 0);
	if (svp != NULL)
		out.includeSubtypes = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "RelativePathElement_targetName", 0);
	if (svp != NULL)
		out.targetName = XS_unpack_UA_QualifiedName(*svp);

	return out;
}

/* RelativePath */
static void XS_pack_UA_RelativePath(SV *out, UA_RelativePath in)  __attribute__((unused));
static void
XS_pack_UA_RelativePath(SV *out, UA_RelativePath in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.elementsSize);
	for (i = 0; i < in.elementsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_RelativePathElement(sv, in.elements[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "RelativePath_elements", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_RelativePath XS_unpack_UA_RelativePath(SV *in)  __attribute__((unused));
static UA_RelativePath
XS_unpack_UA_RelativePath(SV *in)
{
	dTHX;
	UA_RelativePath out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_RelativePath_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RelativePath_elements", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for RelativePath_elements");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.elements = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_RELATIVEPATHELEMENT]);
		if (out.elements == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.elements[i] = XS_unpack_UA_RelativePathElement(*svp);
			}
		}
		out.elementsSize = i;
	}

	return out;
}

/* BrowsePath */
static void XS_pack_UA_BrowsePath(SV *out, UA_BrowsePath in)  __attribute__((unused));
static void
XS_pack_UA_BrowsePath(SV *out, UA_BrowsePath in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.startingNode);
	hv_stores(hv, "BrowsePath_startingNode", sv);

	sv = newSV(0);
	XS_pack_UA_RelativePath(sv, in.relativePath);
	hv_stores(hv, "BrowsePath_relativePath", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_BrowsePath XS_unpack_UA_BrowsePath(SV *in)  __attribute__((unused));
static UA_BrowsePath
XS_unpack_UA_BrowsePath(SV *in)
{
	dTHX;
	UA_BrowsePath out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_BrowsePath_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrowsePath_startingNode", 0);
	if (svp != NULL)
		out.startingNode = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "BrowsePath_relativePath", 0);
	if (svp != NULL)
		out.relativePath = XS_unpack_UA_RelativePath(*svp);

	return out;
}

/* BrowsePathTarget */
static void XS_pack_UA_BrowsePathTarget(SV *out, UA_BrowsePathTarget in)  __attribute__((unused));
static void
XS_pack_UA_BrowsePathTarget(SV *out, UA_BrowsePathTarget in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ExpandedNodeId(sv, in.targetId);
	hv_stores(hv, "BrowsePathTarget_targetId", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.remainingPathIndex);
	hv_stores(hv, "BrowsePathTarget_remainingPathIndex", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_BrowsePathTarget XS_unpack_UA_BrowsePathTarget(SV *in)  __attribute__((unused));
static UA_BrowsePathTarget
XS_unpack_UA_BrowsePathTarget(SV *in)
{
	dTHX;
	UA_BrowsePathTarget out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_BrowsePathTarget_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrowsePathTarget_targetId", 0);
	if (svp != NULL)
		out.targetId = XS_unpack_UA_ExpandedNodeId(*svp);

	svp = hv_fetchs(hv, "BrowsePathTarget_remainingPathIndex", 0);
	if (svp != NULL)
		out.remainingPathIndex = XS_unpack_UA_UInt32(*svp);

	return out;
}

/* BrowsePathResult */
static void XS_pack_UA_BrowsePathResult(SV *out, UA_BrowsePathResult in)  __attribute__((unused));
static void
XS_pack_UA_BrowsePathResult(SV *out, UA_BrowsePathResult in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_StatusCode(sv, in.statusCode);
	hv_stores(hv, "BrowsePathResult_statusCode", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.targetsSize);
	for (i = 0; i < in.targetsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_BrowsePathTarget(sv, in.targets[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "BrowsePathResult_targets", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_BrowsePathResult XS_unpack_UA_BrowsePathResult(SV *in)  __attribute__((unused));
static UA_BrowsePathResult
XS_unpack_UA_BrowsePathResult(SV *in)
{
	dTHX;
	UA_BrowsePathResult out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_BrowsePathResult_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BrowsePathResult_statusCode", 0);
	if (svp != NULL)
		out.statusCode = XS_unpack_UA_StatusCode(*svp);

	svp = hv_fetchs(hv, "BrowsePathResult_targets", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for BrowsePathResult_targets");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.targets = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BROWSEPATHTARGET]);
		if (out.targets == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.targets[i] = XS_unpack_UA_BrowsePathTarget(*svp);
			}
		}
		out.targetsSize = i;
	}

	return out;
}

/* TranslateBrowsePathsToNodeIdsRequest */
static void XS_pack_UA_TranslateBrowsePathsToNodeIdsRequest(SV *out, UA_TranslateBrowsePathsToNodeIdsRequest in)  __attribute__((unused));
static void
XS_pack_UA_TranslateBrowsePathsToNodeIdsRequest(SV *out, UA_TranslateBrowsePathsToNodeIdsRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "TranslateBrowsePathsToNodeIdsRequest_requestHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.browsePathsSize);
	for (i = 0; i < in.browsePathsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_BrowsePath(sv, in.browsePaths[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "TranslateBrowsePathsToNodeIdsRequest_browsePaths", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_TranslateBrowsePathsToNodeIdsRequest XS_unpack_UA_TranslateBrowsePathsToNodeIdsRequest(SV *in)  __attribute__((unused));
static UA_TranslateBrowsePathsToNodeIdsRequest
XS_unpack_UA_TranslateBrowsePathsToNodeIdsRequest(SV *in)
{
	dTHX;
	UA_TranslateBrowsePathsToNodeIdsRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_TranslateBrowsePathsToNodeIdsRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "TranslateBrowsePathsToNodeIdsRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "TranslateBrowsePathsToNodeIdsRequest_browsePaths", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for TranslateBrowsePathsToNodeIdsRequest_browsePaths");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.browsePaths = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BROWSEPATH]);
		if (out.browsePaths == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.browsePaths[i] = XS_unpack_UA_BrowsePath(*svp);
			}
		}
		out.browsePathsSize = i;
	}

	return out;
}

/* TranslateBrowsePathsToNodeIdsResponse */
static void XS_pack_UA_TranslateBrowsePathsToNodeIdsResponse(SV *out, UA_TranslateBrowsePathsToNodeIdsResponse in)  __attribute__((unused));
static void
XS_pack_UA_TranslateBrowsePathsToNodeIdsResponse(SV *out, UA_TranslateBrowsePathsToNodeIdsResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "TranslateBrowsePathsToNodeIdsResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.resultsSize);
	for (i = 0; i < in.resultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_BrowsePathResult(sv, in.results[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "TranslateBrowsePathsToNodeIdsResponse_results", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "TranslateBrowsePathsToNodeIdsResponse_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_TranslateBrowsePathsToNodeIdsResponse XS_unpack_UA_TranslateBrowsePathsToNodeIdsResponse(SV *in)  __attribute__((unused));
static UA_TranslateBrowsePathsToNodeIdsResponse
XS_unpack_UA_TranslateBrowsePathsToNodeIdsResponse(SV *in)
{
	dTHX;
	UA_TranslateBrowsePathsToNodeIdsResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_TranslateBrowsePathsToNodeIdsResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "TranslateBrowsePathsToNodeIdsResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "TranslateBrowsePathsToNodeIdsResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for TranslateBrowsePathsToNodeIdsResponse_results");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_BROWSEPATHRESULT]);
		if (out.results == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.results[i] = XS_unpack_UA_BrowsePathResult(*svp);
			}
		}
		out.resultsSize = i;
	}

	svp = hv_fetchs(hv, "TranslateBrowsePathsToNodeIdsResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for TranslateBrowsePathsToNodeIdsResponse_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* RegisterNodesRequest */
static void XS_pack_UA_RegisterNodesRequest(SV *out, UA_RegisterNodesRequest in)  __attribute__((unused));
static void
XS_pack_UA_RegisterNodesRequest(SV *out, UA_RegisterNodesRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "RegisterNodesRequest_requestHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.nodesToRegisterSize);
	for (i = 0; i < in.nodesToRegisterSize; i++) {
		sv = newSV(0);
		XS_pack_UA_NodeId(sv, in.nodesToRegister[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "RegisterNodesRequest_nodesToRegister", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_RegisterNodesRequest XS_unpack_UA_RegisterNodesRequest(SV *in)  __attribute__((unused));
static UA_RegisterNodesRequest
XS_unpack_UA_RegisterNodesRequest(SV *in)
{
	dTHX;
	UA_RegisterNodesRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_RegisterNodesRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RegisterNodesRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "RegisterNodesRequest_nodesToRegister", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for RegisterNodesRequest_nodesToRegister");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.nodesToRegister = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_NODEID]);
		if (out.nodesToRegister == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.nodesToRegister[i] = XS_unpack_UA_NodeId(*svp);
			}
		}
		out.nodesToRegisterSize = i;
	}

	return out;
}

/* RegisterNodesResponse */
static void XS_pack_UA_RegisterNodesResponse(SV *out, UA_RegisterNodesResponse in)  __attribute__((unused));
static void
XS_pack_UA_RegisterNodesResponse(SV *out, UA_RegisterNodesResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "RegisterNodesResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.registeredNodeIdsSize);
	for (i = 0; i < in.registeredNodeIdsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_NodeId(sv, in.registeredNodeIds[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "RegisterNodesResponse_registeredNodeIds", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_RegisterNodesResponse XS_unpack_UA_RegisterNodesResponse(SV *in)  __attribute__((unused));
static UA_RegisterNodesResponse
XS_unpack_UA_RegisterNodesResponse(SV *in)
{
	dTHX;
	UA_RegisterNodesResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_RegisterNodesResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RegisterNodesResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "RegisterNodesResponse_registeredNodeIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for RegisterNodesResponse_registeredNodeIds");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.registeredNodeIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_NODEID]);
		if (out.registeredNodeIds == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.registeredNodeIds[i] = XS_unpack_UA_NodeId(*svp);
			}
		}
		out.registeredNodeIdsSize = i;
	}

	return out;
}

/* UnregisterNodesRequest */
static void XS_pack_UA_UnregisterNodesRequest(SV *out, UA_UnregisterNodesRequest in)  __attribute__((unused));
static void
XS_pack_UA_UnregisterNodesRequest(SV *out, UA_UnregisterNodesRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "UnregisterNodesRequest_requestHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.nodesToUnregisterSize);
	for (i = 0; i < in.nodesToUnregisterSize; i++) {
		sv = newSV(0);
		XS_pack_UA_NodeId(sv, in.nodesToUnregister[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "UnregisterNodesRequest_nodesToUnregister", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_UnregisterNodesRequest XS_unpack_UA_UnregisterNodesRequest(SV *in)  __attribute__((unused));
static UA_UnregisterNodesRequest
XS_unpack_UA_UnregisterNodesRequest(SV *in)
{
	dTHX;
	UA_UnregisterNodesRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_UnregisterNodesRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UnregisterNodesRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "UnregisterNodesRequest_nodesToUnregister", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for UnregisterNodesRequest_nodesToUnregister");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.nodesToUnregister = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_NODEID]);
		if (out.nodesToUnregister == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.nodesToUnregister[i] = XS_unpack_UA_NodeId(*svp);
			}
		}
		out.nodesToUnregisterSize = i;
	}

	return out;
}

/* UnregisterNodesResponse */
static void XS_pack_UA_UnregisterNodesResponse(SV *out, UA_UnregisterNodesResponse in)  __attribute__((unused));
static void
XS_pack_UA_UnregisterNodesResponse(SV *out, UA_UnregisterNodesResponse in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "UnregisterNodesResponse_responseHeader", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_UnregisterNodesResponse XS_unpack_UA_UnregisterNodesResponse(SV *in)  __attribute__((unused));
static UA_UnregisterNodesResponse
XS_unpack_UA_UnregisterNodesResponse(SV *in)
{
	dTHX;
	UA_UnregisterNodesResponse out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_UnregisterNodesResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UnregisterNodesResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	return out;
}

/* FilterOperator */
static void XS_pack_UA_FilterOperator(SV *out, UA_FilterOperator in)  __attribute__((unused));
static void
XS_pack_UA_FilterOperator(SV *out, UA_FilterOperator in)
{
	dTHX;
	sv_setiv(out, in);
}

static UA_FilterOperator XS_unpack_UA_FilterOperator(SV *in)  __attribute__((unused));
static UA_FilterOperator
XS_unpack_UA_FilterOperator(SV *in)
{
	dTHX;
	return SvIV(in);
}

/* ContentFilterElement */
static void XS_pack_UA_ContentFilterElement(SV *out, UA_ContentFilterElement in)  __attribute__((unused));
static void
XS_pack_UA_ContentFilterElement(SV *out, UA_ContentFilterElement in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_FilterOperator(sv, in.filterOperator);
	hv_stores(hv, "ContentFilterElement_filterOperator", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.filterOperandsSize);
	for (i = 0; i < in.filterOperandsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_ExtensionObject(sv, in.filterOperands[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ContentFilterElement_filterOperands", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ContentFilterElement XS_unpack_UA_ContentFilterElement(SV *in)  __attribute__((unused));
static UA_ContentFilterElement
XS_unpack_UA_ContentFilterElement(SV *in)
{
	dTHX;
	UA_ContentFilterElement out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ContentFilterElement_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ContentFilterElement_filterOperator", 0);
	if (svp != NULL)
		out.filterOperator = XS_unpack_UA_FilterOperator(*svp);

	svp = hv_fetchs(hv, "ContentFilterElement_filterOperands", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ContentFilterElement_filterOperands");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.filterOperands = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_EXTENSIONOBJECT]);
		if (out.filterOperands == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.filterOperands[i] = XS_unpack_UA_ExtensionObject(*svp);
			}
		}
		out.filterOperandsSize = i;
	}

	return out;
}

/* ContentFilter */
static void XS_pack_UA_ContentFilter(SV *out, UA_ContentFilter in)  __attribute__((unused));
static void
XS_pack_UA_ContentFilter(SV *out, UA_ContentFilter in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.elementsSize);
	for (i = 0; i < in.elementsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_ContentFilterElement(sv, in.elements[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ContentFilter_elements", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ContentFilter XS_unpack_UA_ContentFilter(SV *in)  __attribute__((unused));
static UA_ContentFilter
XS_unpack_UA_ContentFilter(SV *in)
{
	dTHX;
	UA_ContentFilter out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ContentFilter_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ContentFilter_elements", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ContentFilter_elements");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.elements = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_CONTENTFILTERELEMENT]);
		if (out.elements == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.elements[i] = XS_unpack_UA_ContentFilterElement(*svp);
			}
		}
		out.elementsSize = i;
	}

	return out;
}

/* FilterOperand */
static void XS_pack_UA_FilterOperand(SV *out, UA_FilterOperand in)  __attribute__((unused));
static void
XS_pack_UA_FilterOperand(SV *out, UA_FilterOperand in)
{
	dTHX;
	CROAK("No conversion implemented");
}

static UA_FilterOperand XS_unpack_UA_FilterOperand(SV *in)  __attribute__((unused));
static UA_FilterOperand
XS_unpack_UA_FilterOperand(SV *in)
{
	dTHX;
	CROAK("No conversion implemented");
}

/* ElementOperand */
static void XS_pack_UA_ElementOperand(SV *out, UA_ElementOperand in)  __attribute__((unused));
static void
XS_pack_UA_ElementOperand(SV *out, UA_ElementOperand in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.index);
	hv_stores(hv, "ElementOperand_index", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ElementOperand XS_unpack_UA_ElementOperand(SV *in)  __attribute__((unused));
static UA_ElementOperand
XS_unpack_UA_ElementOperand(SV *in)
{
	dTHX;
	UA_ElementOperand out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ElementOperand_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ElementOperand_index", 0);
	if (svp != NULL)
		out.index = XS_unpack_UA_UInt32(*svp);

	return out;
}

/* LiteralOperand */
static void XS_pack_UA_LiteralOperand(SV *out, UA_LiteralOperand in)  __attribute__((unused));
static void
XS_pack_UA_LiteralOperand(SV *out, UA_LiteralOperand in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_Variant(sv, in.value);
	hv_stores(hv, "LiteralOperand_value", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_LiteralOperand XS_unpack_UA_LiteralOperand(SV *in)  __attribute__((unused));
static UA_LiteralOperand
XS_unpack_UA_LiteralOperand(SV *in)
{
	dTHX;
	UA_LiteralOperand out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_LiteralOperand_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "LiteralOperand_value", 0);
	if (svp != NULL)
		out.value = XS_unpack_UA_Variant(*svp);

	return out;
}

/* AttributeOperand */
static void XS_pack_UA_AttributeOperand(SV *out, UA_AttributeOperand in)  __attribute__((unused));
static void
XS_pack_UA_AttributeOperand(SV *out, UA_AttributeOperand in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.nodeId);
	hv_stores(hv, "AttributeOperand_nodeId", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.alias);
	hv_stores(hv, "AttributeOperand_alias", sv);

	sv = newSV(0);
	XS_pack_UA_RelativePath(sv, in.browsePath);
	hv_stores(hv, "AttributeOperand_browsePath", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.attributeId);
	hv_stores(hv, "AttributeOperand_attributeId", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.indexRange);
	hv_stores(hv, "AttributeOperand_indexRange", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_AttributeOperand XS_unpack_UA_AttributeOperand(SV *in)  __attribute__((unused));
static UA_AttributeOperand
XS_unpack_UA_AttributeOperand(SV *in)
{
	dTHX;
	UA_AttributeOperand out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_AttributeOperand_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AttributeOperand_nodeId", 0);
	if (svp != NULL)
		out.nodeId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "AttributeOperand_alias", 0);
	if (svp != NULL)
		out.alias = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "AttributeOperand_browsePath", 0);
	if (svp != NULL)
		out.browsePath = XS_unpack_UA_RelativePath(*svp);

	svp = hv_fetchs(hv, "AttributeOperand_attributeId", 0);
	if (svp != NULL)
		out.attributeId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "AttributeOperand_indexRange", 0);
	if (svp != NULL)
		out.indexRange = XS_unpack_UA_String(*svp);

	return out;
}

/* SimpleAttributeOperand */
static void XS_pack_UA_SimpleAttributeOperand(SV *out, UA_SimpleAttributeOperand in)  __attribute__((unused));
static void
XS_pack_UA_SimpleAttributeOperand(SV *out, UA_SimpleAttributeOperand in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.typeDefinitionId);
	hv_stores(hv, "SimpleAttributeOperand_typeDefinitionId", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.browsePathSize);
	for (i = 0; i < in.browsePathSize; i++) {
		sv = newSV(0);
		XS_pack_UA_QualifiedName(sv, in.browsePath[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "SimpleAttributeOperand_browsePath", newRV_inc((SV*)av));

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.attributeId);
	hv_stores(hv, "SimpleAttributeOperand_attributeId", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.indexRange);
	hv_stores(hv, "SimpleAttributeOperand_indexRange", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_SimpleAttributeOperand XS_unpack_UA_SimpleAttributeOperand(SV *in)  __attribute__((unused));
static UA_SimpleAttributeOperand
XS_unpack_UA_SimpleAttributeOperand(SV *in)
{
	dTHX;
	UA_SimpleAttributeOperand out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_SimpleAttributeOperand_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SimpleAttributeOperand_typeDefinitionId", 0);
	if (svp != NULL)
		out.typeDefinitionId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "SimpleAttributeOperand_browsePath", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for SimpleAttributeOperand_browsePath");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.browsePath = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_QUALIFIEDNAME]);
		if (out.browsePath == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.browsePath[i] = XS_unpack_UA_QualifiedName(*svp);
			}
		}
		out.browsePathSize = i;
	}

	svp = hv_fetchs(hv, "SimpleAttributeOperand_attributeId", 0);
	if (svp != NULL)
		out.attributeId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "SimpleAttributeOperand_indexRange", 0);
	if (svp != NULL)
		out.indexRange = XS_unpack_UA_String(*svp);

	return out;
}

/* ContentFilterElementResult */
static void XS_pack_UA_ContentFilterElementResult(SV *out, UA_ContentFilterElementResult in)  __attribute__((unused));
static void
XS_pack_UA_ContentFilterElementResult(SV *out, UA_ContentFilterElementResult in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_StatusCode(sv, in.statusCode);
	hv_stores(hv, "ContentFilterElementResult_statusCode", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.operandStatusCodesSize);
	for (i = 0; i < in.operandStatusCodesSize; i++) {
		sv = newSV(0);
		XS_pack_UA_StatusCode(sv, in.operandStatusCodes[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ContentFilterElementResult_operandStatusCodes", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.operandDiagnosticInfosSize);
	for (i = 0; i < in.operandDiagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.operandDiagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ContentFilterElementResult_operandDiagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ContentFilterElementResult XS_unpack_UA_ContentFilterElementResult(SV *in)  __attribute__((unused));
static UA_ContentFilterElementResult
XS_unpack_UA_ContentFilterElementResult(SV *in)
{
	dTHX;
	UA_ContentFilterElementResult out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ContentFilterElementResult_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ContentFilterElementResult_statusCode", 0);
	if (svp != NULL)
		out.statusCode = XS_unpack_UA_StatusCode(*svp);

	svp = hv_fetchs(hv, "ContentFilterElementResult_operandStatusCodes", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ContentFilterElementResult_operandStatusCodes");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.operandStatusCodes = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out.operandStatusCodes == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.operandStatusCodes[i] = XS_unpack_UA_StatusCode(*svp);
			}
		}
		out.operandStatusCodesSize = i;
	}

	svp = hv_fetchs(hv, "ContentFilterElementResult_operandDiagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ContentFilterElementResult_operandDiagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.operandDiagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.operandDiagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.operandDiagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.operandDiagnosticInfosSize = i;
	}

	return out;
}

/* ContentFilterResult */
static void XS_pack_UA_ContentFilterResult(SV *out, UA_ContentFilterResult in)  __attribute__((unused));
static void
XS_pack_UA_ContentFilterResult(SV *out, UA_ContentFilterResult in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.elementResultsSize);
	for (i = 0; i < in.elementResultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_ContentFilterElementResult(sv, in.elementResults[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ContentFilterResult_elementResults", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.elementDiagnosticInfosSize);
	for (i = 0; i < in.elementDiagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.elementDiagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ContentFilterResult_elementDiagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ContentFilterResult XS_unpack_UA_ContentFilterResult(SV *in)  __attribute__((unused));
static UA_ContentFilterResult
XS_unpack_UA_ContentFilterResult(SV *in)
{
	dTHX;
	UA_ContentFilterResult out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ContentFilterResult_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ContentFilterResult_elementResults", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ContentFilterResult_elementResults");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.elementResults = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_CONTENTFILTERELEMENTRESULT]);
		if (out.elementResults == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.elementResults[i] = XS_unpack_UA_ContentFilterElementResult(*svp);
			}
		}
		out.elementResultsSize = i;
	}

	svp = hv_fetchs(hv, "ContentFilterResult_elementDiagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ContentFilterResult_elementDiagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.elementDiagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.elementDiagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.elementDiagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.elementDiagnosticInfosSize = i;
	}

	return out;
}

/* TimestampsToReturn */
static void XS_pack_UA_TimestampsToReturn(SV *out, UA_TimestampsToReturn in)  __attribute__((unused));
static void
XS_pack_UA_TimestampsToReturn(SV *out, UA_TimestampsToReturn in)
{
	dTHX;
	sv_setiv(out, in);
}

static UA_TimestampsToReturn XS_unpack_UA_TimestampsToReturn(SV *in)  __attribute__((unused));
static UA_TimestampsToReturn
XS_unpack_UA_TimestampsToReturn(SV *in)
{
	dTHX;
	return SvIV(in);
}

/* ReadValueId */
static void XS_pack_UA_ReadValueId(SV *out, UA_ReadValueId in)  __attribute__((unused));
static void
XS_pack_UA_ReadValueId(SV *out, UA_ReadValueId in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.nodeId);
	hv_stores(hv, "ReadValueId_nodeId", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.attributeId);
	hv_stores(hv, "ReadValueId_attributeId", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.indexRange);
	hv_stores(hv, "ReadValueId_indexRange", sv);

	sv = newSV(0);
	XS_pack_UA_QualifiedName(sv, in.dataEncoding);
	hv_stores(hv, "ReadValueId_dataEncoding", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ReadValueId XS_unpack_UA_ReadValueId(SV *in)  __attribute__((unused));
static UA_ReadValueId
XS_unpack_UA_ReadValueId(SV *in)
{
	dTHX;
	UA_ReadValueId out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ReadValueId_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ReadValueId_nodeId", 0);
	if (svp != NULL)
		out.nodeId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "ReadValueId_attributeId", 0);
	if (svp != NULL)
		out.attributeId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ReadValueId_indexRange", 0);
	if (svp != NULL)
		out.indexRange = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "ReadValueId_dataEncoding", 0);
	if (svp != NULL)
		out.dataEncoding = XS_unpack_UA_QualifiedName(*svp);

	return out;
}

/* ReadRequest */
static void XS_pack_UA_ReadRequest(SV *out, UA_ReadRequest in)  __attribute__((unused));
static void
XS_pack_UA_ReadRequest(SV *out, UA_ReadRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "ReadRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_Double(sv, in.maxAge);
	hv_stores(hv, "ReadRequest_maxAge", sv);

	sv = newSV(0);
	XS_pack_UA_TimestampsToReturn(sv, in.timestampsToReturn);
	hv_stores(hv, "ReadRequest_timestampsToReturn", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.nodesToReadSize);
	for (i = 0; i < in.nodesToReadSize; i++) {
		sv = newSV(0);
		XS_pack_UA_ReadValueId(sv, in.nodesToRead[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ReadRequest_nodesToRead", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ReadRequest XS_unpack_UA_ReadRequest(SV *in)  __attribute__((unused));
static UA_ReadRequest
XS_unpack_UA_ReadRequest(SV *in)
{
	dTHX;
	UA_ReadRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ReadRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ReadRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "ReadRequest_maxAge", 0);
	if (svp != NULL)
		out.maxAge = XS_unpack_UA_Double(*svp);

	svp = hv_fetchs(hv, "ReadRequest_timestampsToReturn", 0);
	if (svp != NULL)
		out.timestampsToReturn = XS_unpack_UA_TimestampsToReturn(*svp);

	svp = hv_fetchs(hv, "ReadRequest_nodesToRead", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ReadRequest_nodesToRead");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.nodesToRead = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_READVALUEID]);
		if (out.nodesToRead == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.nodesToRead[i] = XS_unpack_UA_ReadValueId(*svp);
			}
		}
		out.nodesToReadSize = i;
	}

	return out;
}

/* ReadResponse */
static void XS_pack_UA_ReadResponse(SV *out, UA_ReadResponse in)  __attribute__((unused));
static void
XS_pack_UA_ReadResponse(SV *out, UA_ReadResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "ReadResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.resultsSize);
	for (i = 0; i < in.resultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DataValue(sv, in.results[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ReadResponse_results", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ReadResponse_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ReadResponse XS_unpack_UA_ReadResponse(SV *in)  __attribute__((unused));
static UA_ReadResponse
XS_unpack_UA_ReadResponse(SV *in)
{
	dTHX;
	UA_ReadResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ReadResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ReadResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "ReadResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ReadResponse_results");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DATAVALUE]);
		if (out.results == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.results[i] = XS_unpack_UA_DataValue(*svp);
			}
		}
		out.resultsSize = i;
	}

	svp = hv_fetchs(hv, "ReadResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ReadResponse_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* WriteValue */
static void XS_pack_UA_WriteValue(SV *out, UA_WriteValue in)  __attribute__((unused));
static void
XS_pack_UA_WriteValue(SV *out, UA_WriteValue in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.nodeId);
	hv_stores(hv, "WriteValue_nodeId", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.attributeId);
	hv_stores(hv, "WriteValue_attributeId", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.indexRange);
	hv_stores(hv, "WriteValue_indexRange", sv);

	sv = newSV(0);
	XS_pack_UA_DataValue(sv, in.value);
	hv_stores(hv, "WriteValue_value", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_WriteValue XS_unpack_UA_WriteValue(SV *in)  __attribute__((unused));
static UA_WriteValue
XS_unpack_UA_WriteValue(SV *in)
{
	dTHX;
	UA_WriteValue out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_WriteValue_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "WriteValue_nodeId", 0);
	if (svp != NULL)
		out.nodeId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "WriteValue_attributeId", 0);
	if (svp != NULL)
		out.attributeId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "WriteValue_indexRange", 0);
	if (svp != NULL)
		out.indexRange = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "WriteValue_value", 0);
	if (svp != NULL)
		out.value = XS_unpack_UA_DataValue(*svp);

	return out;
}

/* WriteRequest */
static void XS_pack_UA_WriteRequest(SV *out, UA_WriteRequest in)  __attribute__((unused));
static void
XS_pack_UA_WriteRequest(SV *out, UA_WriteRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "WriteRequest_requestHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.nodesToWriteSize);
	for (i = 0; i < in.nodesToWriteSize; i++) {
		sv = newSV(0);
		XS_pack_UA_WriteValue(sv, in.nodesToWrite[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "WriteRequest_nodesToWrite", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_WriteRequest XS_unpack_UA_WriteRequest(SV *in)  __attribute__((unused));
static UA_WriteRequest
XS_unpack_UA_WriteRequest(SV *in)
{
	dTHX;
	UA_WriteRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_WriteRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "WriteRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "WriteRequest_nodesToWrite", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for WriteRequest_nodesToWrite");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.nodesToWrite = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_WRITEVALUE]);
		if (out.nodesToWrite == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.nodesToWrite[i] = XS_unpack_UA_WriteValue(*svp);
			}
		}
		out.nodesToWriteSize = i;
	}

	return out;
}

/* WriteResponse */
static void XS_pack_UA_WriteResponse(SV *out, UA_WriteResponse in)  __attribute__((unused));
static void
XS_pack_UA_WriteResponse(SV *out, UA_WriteResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "WriteResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.resultsSize);
	for (i = 0; i < in.resultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_StatusCode(sv, in.results[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "WriteResponse_results", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "WriteResponse_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_WriteResponse XS_unpack_UA_WriteResponse(SV *in)  __attribute__((unused));
static UA_WriteResponse
XS_unpack_UA_WriteResponse(SV *in)
{
	dTHX;
	UA_WriteResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_WriteResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "WriteResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "WriteResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for WriteResponse_results");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out.results == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.results[i] = XS_unpack_UA_StatusCode(*svp);
			}
		}
		out.resultsSize = i;
	}

	svp = hv_fetchs(hv, "WriteResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for WriteResponse_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* CallMethodRequest */
static void XS_pack_UA_CallMethodRequest(SV *out, UA_CallMethodRequest in)  __attribute__((unused));
static void
XS_pack_UA_CallMethodRequest(SV *out, UA_CallMethodRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.objectId);
	hv_stores(hv, "CallMethodRequest_objectId", sv);

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.methodId);
	hv_stores(hv, "CallMethodRequest_methodId", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.inputArgumentsSize);
	for (i = 0; i < in.inputArgumentsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_Variant(sv, in.inputArguments[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "CallMethodRequest_inputArguments", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_CallMethodRequest XS_unpack_UA_CallMethodRequest(SV *in)  __attribute__((unused));
static UA_CallMethodRequest
XS_unpack_UA_CallMethodRequest(SV *in)
{
	dTHX;
	UA_CallMethodRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_CallMethodRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CallMethodRequest_objectId", 0);
	if (svp != NULL)
		out.objectId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "CallMethodRequest_methodId", 0);
	if (svp != NULL)
		out.methodId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "CallMethodRequest_inputArguments", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for CallMethodRequest_inputArguments");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.inputArguments = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_VARIANT]);
		if (out.inputArguments == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.inputArguments[i] = XS_unpack_UA_Variant(*svp);
			}
		}
		out.inputArgumentsSize = i;
	}

	return out;
}

/* CallMethodResult */
static void XS_pack_UA_CallMethodResult(SV *out, UA_CallMethodResult in)  __attribute__((unused));
static void
XS_pack_UA_CallMethodResult(SV *out, UA_CallMethodResult in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_StatusCode(sv, in.statusCode);
	hv_stores(hv, "CallMethodResult_statusCode", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.inputArgumentResultsSize);
	for (i = 0; i < in.inputArgumentResultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_StatusCode(sv, in.inputArgumentResults[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "CallMethodResult_inputArgumentResults", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.inputArgumentDiagnosticInfosSize);
	for (i = 0; i < in.inputArgumentDiagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.inputArgumentDiagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "CallMethodResult_inputArgumentDiagnosticInfos", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.outputArgumentsSize);
	for (i = 0; i < in.outputArgumentsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_Variant(sv, in.outputArguments[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "CallMethodResult_outputArguments", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_CallMethodResult XS_unpack_UA_CallMethodResult(SV *in)  __attribute__((unused));
static UA_CallMethodResult
XS_unpack_UA_CallMethodResult(SV *in)
{
	dTHX;
	UA_CallMethodResult out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_CallMethodResult_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CallMethodResult_statusCode", 0);
	if (svp != NULL)
		out.statusCode = XS_unpack_UA_StatusCode(*svp);

	svp = hv_fetchs(hv, "CallMethodResult_inputArgumentResults", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for CallMethodResult_inputArgumentResults");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.inputArgumentResults = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out.inputArgumentResults == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.inputArgumentResults[i] = XS_unpack_UA_StatusCode(*svp);
			}
		}
		out.inputArgumentResultsSize = i;
	}

	svp = hv_fetchs(hv, "CallMethodResult_inputArgumentDiagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for CallMethodResult_inputArgumentDiagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.inputArgumentDiagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.inputArgumentDiagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.inputArgumentDiagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.inputArgumentDiagnosticInfosSize = i;
	}

	svp = hv_fetchs(hv, "CallMethodResult_outputArguments", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for CallMethodResult_outputArguments");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.outputArguments = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_VARIANT]);
		if (out.outputArguments == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.outputArguments[i] = XS_unpack_UA_Variant(*svp);
			}
		}
		out.outputArgumentsSize = i;
	}

	return out;
}

/* CallRequest */
static void XS_pack_UA_CallRequest(SV *out, UA_CallRequest in)  __attribute__((unused));
static void
XS_pack_UA_CallRequest(SV *out, UA_CallRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "CallRequest_requestHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.methodsToCallSize);
	for (i = 0; i < in.methodsToCallSize; i++) {
		sv = newSV(0);
		XS_pack_UA_CallMethodRequest(sv, in.methodsToCall[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "CallRequest_methodsToCall", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_CallRequest XS_unpack_UA_CallRequest(SV *in)  __attribute__((unused));
static UA_CallRequest
XS_unpack_UA_CallRequest(SV *in)
{
	dTHX;
	UA_CallRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_CallRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CallRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "CallRequest_methodsToCall", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for CallRequest_methodsToCall");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.methodsToCall = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_CALLMETHODREQUEST]);
		if (out.methodsToCall == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.methodsToCall[i] = XS_unpack_UA_CallMethodRequest(*svp);
			}
		}
		out.methodsToCallSize = i;
	}

	return out;
}

/* CallResponse */
static void XS_pack_UA_CallResponse(SV *out, UA_CallResponse in)  __attribute__((unused));
static void
XS_pack_UA_CallResponse(SV *out, UA_CallResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "CallResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.resultsSize);
	for (i = 0; i < in.resultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_CallMethodResult(sv, in.results[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "CallResponse_results", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "CallResponse_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_CallResponse XS_unpack_UA_CallResponse(SV *in)  __attribute__((unused));
static UA_CallResponse
XS_unpack_UA_CallResponse(SV *in)
{
	dTHX;
	UA_CallResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_CallResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CallResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "CallResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for CallResponse_results");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_CALLMETHODRESULT]);
		if (out.results == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.results[i] = XS_unpack_UA_CallMethodResult(*svp);
			}
		}
		out.resultsSize = i;
	}

	svp = hv_fetchs(hv, "CallResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for CallResponse_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* MonitoringMode */
static void XS_pack_UA_MonitoringMode(SV *out, UA_MonitoringMode in)  __attribute__((unused));
static void
XS_pack_UA_MonitoringMode(SV *out, UA_MonitoringMode in)
{
	dTHX;
	sv_setiv(out, in);
}

static UA_MonitoringMode XS_unpack_UA_MonitoringMode(SV *in)  __attribute__((unused));
static UA_MonitoringMode
XS_unpack_UA_MonitoringMode(SV *in)
{
	dTHX;
	return SvIV(in);
}

/* DataChangeTrigger */
static void XS_pack_UA_DataChangeTrigger(SV *out, UA_DataChangeTrigger in)  __attribute__((unused));
static void
XS_pack_UA_DataChangeTrigger(SV *out, UA_DataChangeTrigger in)
{
	dTHX;
	sv_setiv(out, in);
}

static UA_DataChangeTrigger XS_unpack_UA_DataChangeTrigger(SV *in)  __attribute__((unused));
static UA_DataChangeTrigger
XS_unpack_UA_DataChangeTrigger(SV *in)
{
	dTHX;
	return SvIV(in);
}

/* DeadbandType */
static void XS_pack_UA_DeadbandType(SV *out, UA_DeadbandType in)  __attribute__((unused));
static void
XS_pack_UA_DeadbandType(SV *out, UA_DeadbandType in)
{
	dTHX;
	sv_setiv(out, in);
}

static UA_DeadbandType XS_unpack_UA_DeadbandType(SV *in)  __attribute__((unused));
static UA_DeadbandType
XS_unpack_UA_DeadbandType(SV *in)
{
	dTHX;
	return SvIV(in);
}

/* DataChangeFilter */
static void XS_pack_UA_DataChangeFilter(SV *out, UA_DataChangeFilter in)  __attribute__((unused));
static void
XS_pack_UA_DataChangeFilter(SV *out, UA_DataChangeFilter in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_DataChangeTrigger(sv, in.trigger);
	hv_stores(hv, "DataChangeFilter_trigger", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.deadbandType);
	hv_stores(hv, "DataChangeFilter_deadbandType", sv);

	sv = newSV(0);
	XS_pack_UA_Double(sv, in.deadbandValue);
	hv_stores(hv, "DataChangeFilter_deadbandValue", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_DataChangeFilter XS_unpack_UA_DataChangeFilter(SV *in)  __attribute__((unused));
static UA_DataChangeFilter
XS_unpack_UA_DataChangeFilter(SV *in)
{
	dTHX;
	UA_DataChangeFilter out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_DataChangeFilter_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DataChangeFilter_trigger", 0);
	if (svp != NULL)
		out.trigger = XS_unpack_UA_DataChangeTrigger(*svp);

	svp = hv_fetchs(hv, "DataChangeFilter_deadbandType", 0);
	if (svp != NULL)
		out.deadbandType = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "DataChangeFilter_deadbandValue", 0);
	if (svp != NULL)
		out.deadbandValue = XS_unpack_UA_Double(*svp);

	return out;
}

/* EventFilter */
static void XS_pack_UA_EventFilter(SV *out, UA_EventFilter in)  __attribute__((unused));
static void
XS_pack_UA_EventFilter(SV *out, UA_EventFilter in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.selectClausesSize);
	for (i = 0; i < in.selectClausesSize; i++) {
		sv = newSV(0);
		XS_pack_UA_SimpleAttributeOperand(sv, in.selectClauses[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "EventFilter_selectClauses", newRV_inc((SV*)av));

	sv = newSV(0);
	XS_pack_UA_ContentFilter(sv, in.whereClause);
	hv_stores(hv, "EventFilter_whereClause", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_EventFilter XS_unpack_UA_EventFilter(SV *in)  __attribute__((unused));
static UA_EventFilter
XS_unpack_UA_EventFilter(SV *in)
{
	dTHX;
	UA_EventFilter out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_EventFilter_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EventFilter_selectClauses", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for EventFilter_selectClauses");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.selectClauses = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_SIMPLEATTRIBUTEOPERAND]);
		if (out.selectClauses == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.selectClauses[i] = XS_unpack_UA_SimpleAttributeOperand(*svp);
			}
		}
		out.selectClausesSize = i;
	}

	svp = hv_fetchs(hv, "EventFilter_whereClause", 0);
	if (svp != NULL)
		out.whereClause = XS_unpack_UA_ContentFilter(*svp);

	return out;
}

/* AggregateConfiguration */
static void XS_pack_UA_AggregateConfiguration(SV *out, UA_AggregateConfiguration in)  __attribute__((unused));
static void
XS_pack_UA_AggregateConfiguration(SV *out, UA_AggregateConfiguration in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.useServerCapabilitiesDefaults);
	hv_stores(hv, "AggregateConfiguration_useServerCapabilitiesDefaults", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.treatUncertainAsBad);
	hv_stores(hv, "AggregateConfiguration_treatUncertainAsBad", sv);

	sv = newSV(0);
	XS_pack_UA_Byte(sv, in.percentDataBad);
	hv_stores(hv, "AggregateConfiguration_percentDataBad", sv);

	sv = newSV(0);
	XS_pack_UA_Byte(sv, in.percentDataGood);
	hv_stores(hv, "AggregateConfiguration_percentDataGood", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.useSlopedExtrapolation);
	hv_stores(hv, "AggregateConfiguration_useSlopedExtrapolation", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_AggregateConfiguration XS_unpack_UA_AggregateConfiguration(SV *in)  __attribute__((unused));
static UA_AggregateConfiguration
XS_unpack_UA_AggregateConfiguration(SV *in)
{
	dTHX;
	UA_AggregateConfiguration out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_AggregateConfiguration_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AggregateConfiguration_useServerCapabilitiesDefaults", 0);
	if (svp != NULL)
		out.useServerCapabilitiesDefaults = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "AggregateConfiguration_treatUncertainAsBad", 0);
	if (svp != NULL)
		out.treatUncertainAsBad = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "AggregateConfiguration_percentDataBad", 0);
	if (svp != NULL)
		out.percentDataBad = XS_unpack_UA_Byte(*svp);

	svp = hv_fetchs(hv, "AggregateConfiguration_percentDataGood", 0);
	if (svp != NULL)
		out.percentDataGood = XS_unpack_UA_Byte(*svp);

	svp = hv_fetchs(hv, "AggregateConfiguration_useSlopedExtrapolation", 0);
	if (svp != NULL)
		out.useSlopedExtrapolation = XS_unpack_UA_Boolean(*svp);

	return out;
}

/* AggregateFilter */
static void XS_pack_UA_AggregateFilter(SV *out, UA_AggregateFilter in)  __attribute__((unused));
static void
XS_pack_UA_AggregateFilter(SV *out, UA_AggregateFilter in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_DateTime(sv, in.startTime);
	hv_stores(hv, "AggregateFilter_startTime", sv);

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.aggregateType);
	hv_stores(hv, "AggregateFilter_aggregateType", sv);

	sv = newSV(0);
	XS_pack_UA_Double(sv, in.processingInterval);
	hv_stores(hv, "AggregateFilter_processingInterval", sv);

	sv = newSV(0);
	XS_pack_UA_AggregateConfiguration(sv, in.aggregateConfiguration);
	hv_stores(hv, "AggregateFilter_aggregateConfiguration", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_AggregateFilter XS_unpack_UA_AggregateFilter(SV *in)  __attribute__((unused));
static UA_AggregateFilter
XS_unpack_UA_AggregateFilter(SV *in)
{
	dTHX;
	UA_AggregateFilter out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_AggregateFilter_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "AggregateFilter_startTime", 0);
	if (svp != NULL)
		out.startTime = XS_unpack_UA_DateTime(*svp);

	svp = hv_fetchs(hv, "AggregateFilter_aggregateType", 0);
	if (svp != NULL)
		out.aggregateType = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "AggregateFilter_processingInterval", 0);
	if (svp != NULL)
		out.processingInterval = XS_unpack_UA_Double(*svp);

	svp = hv_fetchs(hv, "AggregateFilter_aggregateConfiguration", 0);
	if (svp != NULL)
		out.aggregateConfiguration = XS_unpack_UA_AggregateConfiguration(*svp);

	return out;
}

/* EventFilterResult */
static void XS_pack_UA_EventFilterResult(SV *out, UA_EventFilterResult in)  __attribute__((unused));
static void
XS_pack_UA_EventFilterResult(SV *out, UA_EventFilterResult in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.selectClauseResultsSize);
	for (i = 0; i < in.selectClauseResultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_StatusCode(sv, in.selectClauseResults[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "EventFilterResult_selectClauseResults", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.selectClauseDiagnosticInfosSize);
	for (i = 0; i < in.selectClauseDiagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.selectClauseDiagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "EventFilterResult_selectClauseDiagnosticInfos", newRV_inc((SV*)av));

	sv = newSV(0);
	XS_pack_UA_ContentFilterResult(sv, in.whereClauseResult);
	hv_stores(hv, "EventFilterResult_whereClauseResult", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_EventFilterResult XS_unpack_UA_EventFilterResult(SV *in)  __attribute__((unused));
static UA_EventFilterResult
XS_unpack_UA_EventFilterResult(SV *in)
{
	dTHX;
	UA_EventFilterResult out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_EventFilterResult_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EventFilterResult_selectClauseResults", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for EventFilterResult_selectClauseResults");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.selectClauseResults = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out.selectClauseResults == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.selectClauseResults[i] = XS_unpack_UA_StatusCode(*svp);
			}
		}
		out.selectClauseResultsSize = i;
	}

	svp = hv_fetchs(hv, "EventFilterResult_selectClauseDiagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for EventFilterResult_selectClauseDiagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.selectClauseDiagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.selectClauseDiagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.selectClauseDiagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.selectClauseDiagnosticInfosSize = i;
	}

	svp = hv_fetchs(hv, "EventFilterResult_whereClauseResult", 0);
	if (svp != NULL)
		out.whereClauseResult = XS_unpack_UA_ContentFilterResult(*svp);

	return out;
}

/* MonitoringParameters */
static void XS_pack_UA_MonitoringParameters(SV *out, UA_MonitoringParameters in)  __attribute__((unused));
static void
XS_pack_UA_MonitoringParameters(SV *out, UA_MonitoringParameters in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.clientHandle);
	hv_stores(hv, "MonitoringParameters_clientHandle", sv);

	sv = newSV(0);
	XS_pack_UA_Double(sv, in.samplingInterval);
	hv_stores(hv, "MonitoringParameters_samplingInterval", sv);

	sv = newSV(0);
	XS_pack_UA_ExtensionObject(sv, in.filter);
	hv_stores(hv, "MonitoringParameters_filter", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.queueSize);
	hv_stores(hv, "MonitoringParameters_queueSize", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.discardOldest);
	hv_stores(hv, "MonitoringParameters_discardOldest", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_MonitoringParameters XS_unpack_UA_MonitoringParameters(SV *in)  __attribute__((unused));
static UA_MonitoringParameters
XS_unpack_UA_MonitoringParameters(SV *in)
{
	dTHX;
	UA_MonitoringParameters out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_MonitoringParameters_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "MonitoringParameters_clientHandle", 0);
	if (svp != NULL)
		out.clientHandle = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "MonitoringParameters_samplingInterval", 0);
	if (svp != NULL)
		out.samplingInterval = XS_unpack_UA_Double(*svp);

	svp = hv_fetchs(hv, "MonitoringParameters_filter", 0);
	if (svp != NULL)
		out.filter = XS_unpack_UA_ExtensionObject(*svp);

	svp = hv_fetchs(hv, "MonitoringParameters_queueSize", 0);
	if (svp != NULL)
		out.queueSize = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "MonitoringParameters_discardOldest", 0);
	if (svp != NULL)
		out.discardOldest = XS_unpack_UA_Boolean(*svp);

	return out;
}

/* MonitoredItemCreateRequest */
static void XS_pack_UA_MonitoredItemCreateRequest(SV *out, UA_MonitoredItemCreateRequest in)  __attribute__((unused));
static void
XS_pack_UA_MonitoredItemCreateRequest(SV *out, UA_MonitoredItemCreateRequest in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ReadValueId(sv, in.itemToMonitor);
	hv_stores(hv, "MonitoredItemCreateRequest_itemToMonitor", sv);

	sv = newSV(0);
	XS_pack_UA_MonitoringMode(sv, in.monitoringMode);
	hv_stores(hv, "MonitoredItemCreateRequest_monitoringMode", sv);

	sv = newSV(0);
	XS_pack_UA_MonitoringParameters(sv, in.requestedParameters);
	hv_stores(hv, "MonitoredItemCreateRequest_requestedParameters", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_MonitoredItemCreateRequest XS_unpack_UA_MonitoredItemCreateRequest(SV *in)  __attribute__((unused));
static UA_MonitoredItemCreateRequest
XS_unpack_UA_MonitoredItemCreateRequest(SV *in)
{
	dTHX;
	UA_MonitoredItemCreateRequest out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_MonitoredItemCreateRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "MonitoredItemCreateRequest_itemToMonitor", 0);
	if (svp != NULL)
		out.itemToMonitor = XS_unpack_UA_ReadValueId(*svp);

	svp = hv_fetchs(hv, "MonitoredItemCreateRequest_monitoringMode", 0);
	if (svp != NULL)
		out.monitoringMode = XS_unpack_UA_MonitoringMode(*svp);

	svp = hv_fetchs(hv, "MonitoredItemCreateRequest_requestedParameters", 0);
	if (svp != NULL)
		out.requestedParameters = XS_unpack_UA_MonitoringParameters(*svp);

	return out;
}

/* MonitoredItemCreateResult */
static void XS_pack_UA_MonitoredItemCreateResult(SV *out, UA_MonitoredItemCreateResult in)  __attribute__((unused));
static void
XS_pack_UA_MonitoredItemCreateResult(SV *out, UA_MonitoredItemCreateResult in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_StatusCode(sv, in.statusCode);
	hv_stores(hv, "MonitoredItemCreateResult_statusCode", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.monitoredItemId);
	hv_stores(hv, "MonitoredItemCreateResult_monitoredItemId", sv);

	sv = newSV(0);
	XS_pack_UA_Double(sv, in.revisedSamplingInterval);
	hv_stores(hv, "MonitoredItemCreateResult_revisedSamplingInterval", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.revisedQueueSize);
	hv_stores(hv, "MonitoredItemCreateResult_revisedQueueSize", sv);

	sv = newSV(0);
	XS_pack_UA_ExtensionObject(sv, in.filterResult);
	hv_stores(hv, "MonitoredItemCreateResult_filterResult", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_MonitoredItemCreateResult XS_unpack_UA_MonitoredItemCreateResult(SV *in)  __attribute__((unused));
static UA_MonitoredItemCreateResult
XS_unpack_UA_MonitoredItemCreateResult(SV *in)
{
	dTHX;
	UA_MonitoredItemCreateResult out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_MonitoredItemCreateResult_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "MonitoredItemCreateResult_statusCode", 0);
	if (svp != NULL)
		out.statusCode = XS_unpack_UA_StatusCode(*svp);

	svp = hv_fetchs(hv, "MonitoredItemCreateResult_monitoredItemId", 0);
	if (svp != NULL)
		out.monitoredItemId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "MonitoredItemCreateResult_revisedSamplingInterval", 0);
	if (svp != NULL)
		out.revisedSamplingInterval = XS_unpack_UA_Double(*svp);

	svp = hv_fetchs(hv, "MonitoredItemCreateResult_revisedQueueSize", 0);
	if (svp != NULL)
		out.revisedQueueSize = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "MonitoredItemCreateResult_filterResult", 0);
	if (svp != NULL)
		out.filterResult = XS_unpack_UA_ExtensionObject(*svp);

	return out;
}

/* CreateMonitoredItemsRequest */
static void XS_pack_UA_CreateMonitoredItemsRequest(SV *out, UA_CreateMonitoredItemsRequest in)  __attribute__((unused));
static void
XS_pack_UA_CreateMonitoredItemsRequest(SV *out, UA_CreateMonitoredItemsRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "CreateMonitoredItemsRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.subscriptionId);
	hv_stores(hv, "CreateMonitoredItemsRequest_subscriptionId", sv);

	sv = newSV(0);
	XS_pack_UA_TimestampsToReturn(sv, in.timestampsToReturn);
	hv_stores(hv, "CreateMonitoredItemsRequest_timestampsToReturn", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.itemsToCreateSize);
	for (i = 0; i < in.itemsToCreateSize; i++) {
		sv = newSV(0);
		XS_pack_UA_MonitoredItemCreateRequest(sv, in.itemsToCreate[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "CreateMonitoredItemsRequest_itemsToCreate", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_CreateMonitoredItemsRequest XS_unpack_UA_CreateMonitoredItemsRequest(SV *in)  __attribute__((unused));
static UA_CreateMonitoredItemsRequest
XS_unpack_UA_CreateMonitoredItemsRequest(SV *in)
{
	dTHX;
	UA_CreateMonitoredItemsRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_CreateMonitoredItemsRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CreateMonitoredItemsRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "CreateMonitoredItemsRequest_subscriptionId", 0);
	if (svp != NULL)
		out.subscriptionId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "CreateMonitoredItemsRequest_timestampsToReturn", 0);
	if (svp != NULL)
		out.timestampsToReturn = XS_unpack_UA_TimestampsToReturn(*svp);

	svp = hv_fetchs(hv, "CreateMonitoredItemsRequest_itemsToCreate", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for CreateMonitoredItemsRequest_itemsToCreate");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.itemsToCreate = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_MONITOREDITEMCREATEREQUEST]);
		if (out.itemsToCreate == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.itemsToCreate[i] = XS_unpack_UA_MonitoredItemCreateRequest(*svp);
			}
		}
		out.itemsToCreateSize = i;
	}

	return out;
}

/* CreateMonitoredItemsResponse */
static void XS_pack_UA_CreateMonitoredItemsResponse(SV *out, UA_CreateMonitoredItemsResponse in)  __attribute__((unused));
static void
XS_pack_UA_CreateMonitoredItemsResponse(SV *out, UA_CreateMonitoredItemsResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "CreateMonitoredItemsResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.resultsSize);
	for (i = 0; i < in.resultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_MonitoredItemCreateResult(sv, in.results[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "CreateMonitoredItemsResponse_results", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "CreateMonitoredItemsResponse_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_CreateMonitoredItemsResponse XS_unpack_UA_CreateMonitoredItemsResponse(SV *in)  __attribute__((unused));
static UA_CreateMonitoredItemsResponse
XS_unpack_UA_CreateMonitoredItemsResponse(SV *in)
{
	dTHX;
	UA_CreateMonitoredItemsResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_CreateMonitoredItemsResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CreateMonitoredItemsResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "CreateMonitoredItemsResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for CreateMonitoredItemsResponse_results");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_MONITOREDITEMCREATERESULT]);
		if (out.results == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.results[i] = XS_unpack_UA_MonitoredItemCreateResult(*svp);
			}
		}
		out.resultsSize = i;
	}

	svp = hv_fetchs(hv, "CreateMonitoredItemsResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for CreateMonitoredItemsResponse_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* MonitoredItemModifyRequest */
static void XS_pack_UA_MonitoredItemModifyRequest(SV *out, UA_MonitoredItemModifyRequest in)  __attribute__((unused));
static void
XS_pack_UA_MonitoredItemModifyRequest(SV *out, UA_MonitoredItemModifyRequest in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.monitoredItemId);
	hv_stores(hv, "MonitoredItemModifyRequest_monitoredItemId", sv);

	sv = newSV(0);
	XS_pack_UA_MonitoringParameters(sv, in.requestedParameters);
	hv_stores(hv, "MonitoredItemModifyRequest_requestedParameters", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_MonitoredItemModifyRequest XS_unpack_UA_MonitoredItemModifyRequest(SV *in)  __attribute__((unused));
static UA_MonitoredItemModifyRequest
XS_unpack_UA_MonitoredItemModifyRequest(SV *in)
{
	dTHX;
	UA_MonitoredItemModifyRequest out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_MonitoredItemModifyRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "MonitoredItemModifyRequest_monitoredItemId", 0);
	if (svp != NULL)
		out.monitoredItemId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "MonitoredItemModifyRequest_requestedParameters", 0);
	if (svp != NULL)
		out.requestedParameters = XS_unpack_UA_MonitoringParameters(*svp);

	return out;
}

/* MonitoredItemModifyResult */
static void XS_pack_UA_MonitoredItemModifyResult(SV *out, UA_MonitoredItemModifyResult in)  __attribute__((unused));
static void
XS_pack_UA_MonitoredItemModifyResult(SV *out, UA_MonitoredItemModifyResult in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_StatusCode(sv, in.statusCode);
	hv_stores(hv, "MonitoredItemModifyResult_statusCode", sv);

	sv = newSV(0);
	XS_pack_UA_Double(sv, in.revisedSamplingInterval);
	hv_stores(hv, "MonitoredItemModifyResult_revisedSamplingInterval", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.revisedQueueSize);
	hv_stores(hv, "MonitoredItemModifyResult_revisedQueueSize", sv);

	sv = newSV(0);
	XS_pack_UA_ExtensionObject(sv, in.filterResult);
	hv_stores(hv, "MonitoredItemModifyResult_filterResult", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_MonitoredItemModifyResult XS_unpack_UA_MonitoredItemModifyResult(SV *in)  __attribute__((unused));
static UA_MonitoredItemModifyResult
XS_unpack_UA_MonitoredItemModifyResult(SV *in)
{
	dTHX;
	UA_MonitoredItemModifyResult out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_MonitoredItemModifyResult_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "MonitoredItemModifyResult_statusCode", 0);
	if (svp != NULL)
		out.statusCode = XS_unpack_UA_StatusCode(*svp);

	svp = hv_fetchs(hv, "MonitoredItemModifyResult_revisedSamplingInterval", 0);
	if (svp != NULL)
		out.revisedSamplingInterval = XS_unpack_UA_Double(*svp);

	svp = hv_fetchs(hv, "MonitoredItemModifyResult_revisedQueueSize", 0);
	if (svp != NULL)
		out.revisedQueueSize = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "MonitoredItemModifyResult_filterResult", 0);
	if (svp != NULL)
		out.filterResult = XS_unpack_UA_ExtensionObject(*svp);

	return out;
}

/* ModifyMonitoredItemsRequest */
static void XS_pack_UA_ModifyMonitoredItemsRequest(SV *out, UA_ModifyMonitoredItemsRequest in)  __attribute__((unused));
static void
XS_pack_UA_ModifyMonitoredItemsRequest(SV *out, UA_ModifyMonitoredItemsRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "ModifyMonitoredItemsRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.subscriptionId);
	hv_stores(hv, "ModifyMonitoredItemsRequest_subscriptionId", sv);

	sv = newSV(0);
	XS_pack_UA_TimestampsToReturn(sv, in.timestampsToReturn);
	hv_stores(hv, "ModifyMonitoredItemsRequest_timestampsToReturn", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.itemsToModifySize);
	for (i = 0; i < in.itemsToModifySize; i++) {
		sv = newSV(0);
		XS_pack_UA_MonitoredItemModifyRequest(sv, in.itemsToModify[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ModifyMonitoredItemsRequest_itemsToModify", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ModifyMonitoredItemsRequest XS_unpack_UA_ModifyMonitoredItemsRequest(SV *in)  __attribute__((unused));
static UA_ModifyMonitoredItemsRequest
XS_unpack_UA_ModifyMonitoredItemsRequest(SV *in)
{
	dTHX;
	UA_ModifyMonitoredItemsRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ModifyMonitoredItemsRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ModifyMonitoredItemsRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "ModifyMonitoredItemsRequest_subscriptionId", 0);
	if (svp != NULL)
		out.subscriptionId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ModifyMonitoredItemsRequest_timestampsToReturn", 0);
	if (svp != NULL)
		out.timestampsToReturn = XS_unpack_UA_TimestampsToReturn(*svp);

	svp = hv_fetchs(hv, "ModifyMonitoredItemsRequest_itemsToModify", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ModifyMonitoredItemsRequest_itemsToModify");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.itemsToModify = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_MONITOREDITEMMODIFYREQUEST]);
		if (out.itemsToModify == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.itemsToModify[i] = XS_unpack_UA_MonitoredItemModifyRequest(*svp);
			}
		}
		out.itemsToModifySize = i;
	}

	return out;
}

/* ModifyMonitoredItemsResponse */
static void XS_pack_UA_ModifyMonitoredItemsResponse(SV *out, UA_ModifyMonitoredItemsResponse in)  __attribute__((unused));
static void
XS_pack_UA_ModifyMonitoredItemsResponse(SV *out, UA_ModifyMonitoredItemsResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "ModifyMonitoredItemsResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.resultsSize);
	for (i = 0; i < in.resultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_MonitoredItemModifyResult(sv, in.results[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ModifyMonitoredItemsResponse_results", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "ModifyMonitoredItemsResponse_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ModifyMonitoredItemsResponse XS_unpack_UA_ModifyMonitoredItemsResponse(SV *in)  __attribute__((unused));
static UA_ModifyMonitoredItemsResponse
XS_unpack_UA_ModifyMonitoredItemsResponse(SV *in)
{
	dTHX;
	UA_ModifyMonitoredItemsResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ModifyMonitoredItemsResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ModifyMonitoredItemsResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "ModifyMonitoredItemsResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ModifyMonitoredItemsResponse_results");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_MONITOREDITEMMODIFYRESULT]);
		if (out.results == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.results[i] = XS_unpack_UA_MonitoredItemModifyResult(*svp);
			}
		}
		out.resultsSize = i;
	}

	svp = hv_fetchs(hv, "ModifyMonitoredItemsResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for ModifyMonitoredItemsResponse_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* SetMonitoringModeRequest */
static void XS_pack_UA_SetMonitoringModeRequest(SV *out, UA_SetMonitoringModeRequest in)  __attribute__((unused));
static void
XS_pack_UA_SetMonitoringModeRequest(SV *out, UA_SetMonitoringModeRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "SetMonitoringModeRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.subscriptionId);
	hv_stores(hv, "SetMonitoringModeRequest_subscriptionId", sv);

	sv = newSV(0);
	XS_pack_UA_MonitoringMode(sv, in.monitoringMode);
	hv_stores(hv, "SetMonitoringModeRequest_monitoringMode", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.monitoredItemIdsSize);
	for (i = 0; i < in.monitoredItemIdsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_UInt32(sv, in.monitoredItemIds[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "SetMonitoringModeRequest_monitoredItemIds", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_SetMonitoringModeRequest XS_unpack_UA_SetMonitoringModeRequest(SV *in)  __attribute__((unused));
static UA_SetMonitoringModeRequest
XS_unpack_UA_SetMonitoringModeRequest(SV *in)
{
	dTHX;
	UA_SetMonitoringModeRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_SetMonitoringModeRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SetMonitoringModeRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "SetMonitoringModeRequest_subscriptionId", 0);
	if (svp != NULL)
		out.subscriptionId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "SetMonitoringModeRequest_monitoringMode", 0);
	if (svp != NULL)
		out.monitoringMode = XS_unpack_UA_MonitoringMode(*svp);

	svp = hv_fetchs(hv, "SetMonitoringModeRequest_monitoredItemIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for SetMonitoringModeRequest_monitoredItemIds");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.monitoredItemIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out.monitoredItemIds == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.monitoredItemIds[i] = XS_unpack_UA_UInt32(*svp);
			}
		}
		out.monitoredItemIdsSize = i;
	}

	return out;
}

/* SetMonitoringModeResponse */
static void XS_pack_UA_SetMonitoringModeResponse(SV *out, UA_SetMonitoringModeResponse in)  __attribute__((unused));
static void
XS_pack_UA_SetMonitoringModeResponse(SV *out, UA_SetMonitoringModeResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "SetMonitoringModeResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.resultsSize);
	for (i = 0; i < in.resultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_StatusCode(sv, in.results[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "SetMonitoringModeResponse_results", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "SetMonitoringModeResponse_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_SetMonitoringModeResponse XS_unpack_UA_SetMonitoringModeResponse(SV *in)  __attribute__((unused));
static UA_SetMonitoringModeResponse
XS_unpack_UA_SetMonitoringModeResponse(SV *in)
{
	dTHX;
	UA_SetMonitoringModeResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_SetMonitoringModeResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SetMonitoringModeResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "SetMonitoringModeResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for SetMonitoringModeResponse_results");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out.results == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.results[i] = XS_unpack_UA_StatusCode(*svp);
			}
		}
		out.resultsSize = i;
	}

	svp = hv_fetchs(hv, "SetMonitoringModeResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for SetMonitoringModeResponse_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* SetTriggeringRequest */
static void XS_pack_UA_SetTriggeringRequest(SV *out, UA_SetTriggeringRequest in)  __attribute__((unused));
static void
XS_pack_UA_SetTriggeringRequest(SV *out, UA_SetTriggeringRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "SetTriggeringRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.subscriptionId);
	hv_stores(hv, "SetTriggeringRequest_subscriptionId", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.triggeringItemId);
	hv_stores(hv, "SetTriggeringRequest_triggeringItemId", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.linksToAddSize);
	for (i = 0; i < in.linksToAddSize; i++) {
		sv = newSV(0);
		XS_pack_UA_UInt32(sv, in.linksToAdd[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "SetTriggeringRequest_linksToAdd", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.linksToRemoveSize);
	for (i = 0; i < in.linksToRemoveSize; i++) {
		sv = newSV(0);
		XS_pack_UA_UInt32(sv, in.linksToRemove[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "SetTriggeringRequest_linksToRemove", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_SetTriggeringRequest XS_unpack_UA_SetTriggeringRequest(SV *in)  __attribute__((unused));
static UA_SetTriggeringRequest
XS_unpack_UA_SetTriggeringRequest(SV *in)
{
	dTHX;
	UA_SetTriggeringRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_SetTriggeringRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SetTriggeringRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "SetTriggeringRequest_subscriptionId", 0);
	if (svp != NULL)
		out.subscriptionId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "SetTriggeringRequest_triggeringItemId", 0);
	if (svp != NULL)
		out.triggeringItemId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "SetTriggeringRequest_linksToAdd", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for SetTriggeringRequest_linksToAdd");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.linksToAdd = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out.linksToAdd == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.linksToAdd[i] = XS_unpack_UA_UInt32(*svp);
			}
		}
		out.linksToAddSize = i;
	}

	svp = hv_fetchs(hv, "SetTriggeringRequest_linksToRemove", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for SetTriggeringRequest_linksToRemove");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.linksToRemove = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out.linksToRemove == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.linksToRemove[i] = XS_unpack_UA_UInt32(*svp);
			}
		}
		out.linksToRemoveSize = i;
	}

	return out;
}

/* SetTriggeringResponse */
static void XS_pack_UA_SetTriggeringResponse(SV *out, UA_SetTriggeringResponse in)  __attribute__((unused));
static void
XS_pack_UA_SetTriggeringResponse(SV *out, UA_SetTriggeringResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "SetTriggeringResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.addResultsSize);
	for (i = 0; i < in.addResultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_StatusCode(sv, in.addResults[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "SetTriggeringResponse_addResults", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.addDiagnosticInfosSize);
	for (i = 0; i < in.addDiagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.addDiagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "SetTriggeringResponse_addDiagnosticInfos", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.removeResultsSize);
	for (i = 0; i < in.removeResultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_StatusCode(sv, in.removeResults[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "SetTriggeringResponse_removeResults", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.removeDiagnosticInfosSize);
	for (i = 0; i < in.removeDiagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.removeDiagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "SetTriggeringResponse_removeDiagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_SetTriggeringResponse XS_unpack_UA_SetTriggeringResponse(SV *in)  __attribute__((unused));
static UA_SetTriggeringResponse
XS_unpack_UA_SetTriggeringResponse(SV *in)
{
	dTHX;
	UA_SetTriggeringResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_SetTriggeringResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SetTriggeringResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "SetTriggeringResponse_addResults", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for SetTriggeringResponse_addResults");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.addResults = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out.addResults == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.addResults[i] = XS_unpack_UA_StatusCode(*svp);
			}
		}
		out.addResultsSize = i;
	}

	svp = hv_fetchs(hv, "SetTriggeringResponse_addDiagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for SetTriggeringResponse_addDiagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.addDiagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.addDiagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.addDiagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.addDiagnosticInfosSize = i;
	}

	svp = hv_fetchs(hv, "SetTriggeringResponse_removeResults", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for SetTriggeringResponse_removeResults");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.removeResults = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out.removeResults == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.removeResults[i] = XS_unpack_UA_StatusCode(*svp);
			}
		}
		out.removeResultsSize = i;
	}

	svp = hv_fetchs(hv, "SetTriggeringResponse_removeDiagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for SetTriggeringResponse_removeDiagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.removeDiagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.removeDiagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.removeDiagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.removeDiagnosticInfosSize = i;
	}

	return out;
}

/* DeleteMonitoredItemsRequest */
static void XS_pack_UA_DeleteMonitoredItemsRequest(SV *out, UA_DeleteMonitoredItemsRequest in)  __attribute__((unused));
static void
XS_pack_UA_DeleteMonitoredItemsRequest(SV *out, UA_DeleteMonitoredItemsRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "DeleteMonitoredItemsRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.subscriptionId);
	hv_stores(hv, "DeleteMonitoredItemsRequest_subscriptionId", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.monitoredItemIdsSize);
	for (i = 0; i < in.monitoredItemIdsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_UInt32(sv, in.monitoredItemIds[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "DeleteMonitoredItemsRequest_monitoredItemIds", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_DeleteMonitoredItemsRequest XS_unpack_UA_DeleteMonitoredItemsRequest(SV *in)  __attribute__((unused));
static UA_DeleteMonitoredItemsRequest
XS_unpack_UA_DeleteMonitoredItemsRequest(SV *in)
{
	dTHX;
	UA_DeleteMonitoredItemsRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_DeleteMonitoredItemsRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteMonitoredItemsRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "DeleteMonitoredItemsRequest_subscriptionId", 0);
	if (svp != NULL)
		out.subscriptionId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "DeleteMonitoredItemsRequest_monitoredItemIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for DeleteMonitoredItemsRequest_monitoredItemIds");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.monitoredItemIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out.monitoredItemIds == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.monitoredItemIds[i] = XS_unpack_UA_UInt32(*svp);
			}
		}
		out.monitoredItemIdsSize = i;
	}

	return out;
}

/* DeleteMonitoredItemsResponse */
static void XS_pack_UA_DeleteMonitoredItemsResponse(SV *out, UA_DeleteMonitoredItemsResponse in)  __attribute__((unused));
static void
XS_pack_UA_DeleteMonitoredItemsResponse(SV *out, UA_DeleteMonitoredItemsResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "DeleteMonitoredItemsResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.resultsSize);
	for (i = 0; i < in.resultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_StatusCode(sv, in.results[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "DeleteMonitoredItemsResponse_results", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "DeleteMonitoredItemsResponse_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_DeleteMonitoredItemsResponse XS_unpack_UA_DeleteMonitoredItemsResponse(SV *in)  __attribute__((unused));
static UA_DeleteMonitoredItemsResponse
XS_unpack_UA_DeleteMonitoredItemsResponse(SV *in)
{
	dTHX;
	UA_DeleteMonitoredItemsResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_DeleteMonitoredItemsResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteMonitoredItemsResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "DeleteMonitoredItemsResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for DeleteMonitoredItemsResponse_results");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out.results == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.results[i] = XS_unpack_UA_StatusCode(*svp);
			}
		}
		out.resultsSize = i;
	}

	svp = hv_fetchs(hv, "DeleteMonitoredItemsResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for DeleteMonitoredItemsResponse_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* CreateSubscriptionRequest */
static void XS_pack_UA_CreateSubscriptionRequest(SV *out, UA_CreateSubscriptionRequest in)  __attribute__((unused));
static void
XS_pack_UA_CreateSubscriptionRequest(SV *out, UA_CreateSubscriptionRequest in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "CreateSubscriptionRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_Double(sv, in.requestedPublishingInterval);
	hv_stores(hv, "CreateSubscriptionRequest_requestedPublishingInterval", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.requestedLifetimeCount);
	hv_stores(hv, "CreateSubscriptionRequest_requestedLifetimeCount", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.requestedMaxKeepAliveCount);
	hv_stores(hv, "CreateSubscriptionRequest_requestedMaxKeepAliveCount", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.maxNotificationsPerPublish);
	hv_stores(hv, "CreateSubscriptionRequest_maxNotificationsPerPublish", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.publishingEnabled);
	hv_stores(hv, "CreateSubscriptionRequest_publishingEnabled", sv);

	sv = newSV(0);
	XS_pack_UA_Byte(sv, in.priority);
	hv_stores(hv, "CreateSubscriptionRequest_priority", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_CreateSubscriptionRequest XS_unpack_UA_CreateSubscriptionRequest(SV *in)  __attribute__((unused));
static UA_CreateSubscriptionRequest
XS_unpack_UA_CreateSubscriptionRequest(SV *in)
{
	dTHX;
	UA_CreateSubscriptionRequest out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_CreateSubscriptionRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CreateSubscriptionRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "CreateSubscriptionRequest_requestedPublishingInterval", 0);
	if (svp != NULL)
		out.requestedPublishingInterval = XS_unpack_UA_Double(*svp);

	svp = hv_fetchs(hv, "CreateSubscriptionRequest_requestedLifetimeCount", 0);
	if (svp != NULL)
		out.requestedLifetimeCount = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "CreateSubscriptionRequest_requestedMaxKeepAliveCount", 0);
	if (svp != NULL)
		out.requestedMaxKeepAliveCount = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "CreateSubscriptionRequest_maxNotificationsPerPublish", 0);
	if (svp != NULL)
		out.maxNotificationsPerPublish = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "CreateSubscriptionRequest_publishingEnabled", 0);
	if (svp != NULL)
		out.publishingEnabled = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "CreateSubscriptionRequest_priority", 0);
	if (svp != NULL)
		out.priority = XS_unpack_UA_Byte(*svp);

	return out;
}

/* CreateSubscriptionResponse */
static void XS_pack_UA_CreateSubscriptionResponse(SV *out, UA_CreateSubscriptionResponse in)  __attribute__((unused));
static void
XS_pack_UA_CreateSubscriptionResponse(SV *out, UA_CreateSubscriptionResponse in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "CreateSubscriptionResponse_responseHeader", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.subscriptionId);
	hv_stores(hv, "CreateSubscriptionResponse_subscriptionId", sv);

	sv = newSV(0);
	XS_pack_UA_Double(sv, in.revisedPublishingInterval);
	hv_stores(hv, "CreateSubscriptionResponse_revisedPublishingInterval", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.revisedLifetimeCount);
	hv_stores(hv, "CreateSubscriptionResponse_revisedLifetimeCount", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.revisedMaxKeepAliveCount);
	hv_stores(hv, "CreateSubscriptionResponse_revisedMaxKeepAliveCount", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_CreateSubscriptionResponse XS_unpack_UA_CreateSubscriptionResponse(SV *in)  __attribute__((unused));
static UA_CreateSubscriptionResponse
XS_unpack_UA_CreateSubscriptionResponse(SV *in)
{
	dTHX;
	UA_CreateSubscriptionResponse out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_CreateSubscriptionResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "CreateSubscriptionResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "CreateSubscriptionResponse_subscriptionId", 0);
	if (svp != NULL)
		out.subscriptionId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "CreateSubscriptionResponse_revisedPublishingInterval", 0);
	if (svp != NULL)
		out.revisedPublishingInterval = XS_unpack_UA_Double(*svp);

	svp = hv_fetchs(hv, "CreateSubscriptionResponse_revisedLifetimeCount", 0);
	if (svp != NULL)
		out.revisedLifetimeCount = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "CreateSubscriptionResponse_revisedMaxKeepAliveCount", 0);
	if (svp != NULL)
		out.revisedMaxKeepAliveCount = XS_unpack_UA_UInt32(*svp);

	return out;
}

/* ModifySubscriptionRequest */
static void XS_pack_UA_ModifySubscriptionRequest(SV *out, UA_ModifySubscriptionRequest in)  __attribute__((unused));
static void
XS_pack_UA_ModifySubscriptionRequest(SV *out, UA_ModifySubscriptionRequest in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "ModifySubscriptionRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.subscriptionId);
	hv_stores(hv, "ModifySubscriptionRequest_subscriptionId", sv);

	sv = newSV(0);
	XS_pack_UA_Double(sv, in.requestedPublishingInterval);
	hv_stores(hv, "ModifySubscriptionRequest_requestedPublishingInterval", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.requestedLifetimeCount);
	hv_stores(hv, "ModifySubscriptionRequest_requestedLifetimeCount", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.requestedMaxKeepAliveCount);
	hv_stores(hv, "ModifySubscriptionRequest_requestedMaxKeepAliveCount", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.maxNotificationsPerPublish);
	hv_stores(hv, "ModifySubscriptionRequest_maxNotificationsPerPublish", sv);

	sv = newSV(0);
	XS_pack_UA_Byte(sv, in.priority);
	hv_stores(hv, "ModifySubscriptionRequest_priority", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ModifySubscriptionRequest XS_unpack_UA_ModifySubscriptionRequest(SV *in)  __attribute__((unused));
static UA_ModifySubscriptionRequest
XS_unpack_UA_ModifySubscriptionRequest(SV *in)
{
	dTHX;
	UA_ModifySubscriptionRequest out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ModifySubscriptionRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ModifySubscriptionRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "ModifySubscriptionRequest_subscriptionId", 0);
	if (svp != NULL)
		out.subscriptionId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ModifySubscriptionRequest_requestedPublishingInterval", 0);
	if (svp != NULL)
		out.requestedPublishingInterval = XS_unpack_UA_Double(*svp);

	svp = hv_fetchs(hv, "ModifySubscriptionRequest_requestedLifetimeCount", 0);
	if (svp != NULL)
		out.requestedLifetimeCount = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ModifySubscriptionRequest_requestedMaxKeepAliveCount", 0);
	if (svp != NULL)
		out.requestedMaxKeepAliveCount = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ModifySubscriptionRequest_maxNotificationsPerPublish", 0);
	if (svp != NULL)
		out.maxNotificationsPerPublish = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ModifySubscriptionRequest_priority", 0);
	if (svp != NULL)
		out.priority = XS_unpack_UA_Byte(*svp);

	return out;
}

/* ModifySubscriptionResponse */
static void XS_pack_UA_ModifySubscriptionResponse(SV *out, UA_ModifySubscriptionResponse in)  __attribute__((unused));
static void
XS_pack_UA_ModifySubscriptionResponse(SV *out, UA_ModifySubscriptionResponse in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "ModifySubscriptionResponse_responseHeader", sv);

	sv = newSV(0);
	XS_pack_UA_Double(sv, in.revisedPublishingInterval);
	hv_stores(hv, "ModifySubscriptionResponse_revisedPublishingInterval", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.revisedLifetimeCount);
	hv_stores(hv, "ModifySubscriptionResponse_revisedLifetimeCount", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.revisedMaxKeepAliveCount);
	hv_stores(hv, "ModifySubscriptionResponse_revisedMaxKeepAliveCount", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ModifySubscriptionResponse XS_unpack_UA_ModifySubscriptionResponse(SV *in)  __attribute__((unused));
static UA_ModifySubscriptionResponse
XS_unpack_UA_ModifySubscriptionResponse(SV *in)
{
	dTHX;
	UA_ModifySubscriptionResponse out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ModifySubscriptionResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ModifySubscriptionResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "ModifySubscriptionResponse_revisedPublishingInterval", 0);
	if (svp != NULL)
		out.revisedPublishingInterval = XS_unpack_UA_Double(*svp);

	svp = hv_fetchs(hv, "ModifySubscriptionResponse_revisedLifetimeCount", 0);
	if (svp != NULL)
		out.revisedLifetimeCount = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ModifySubscriptionResponse_revisedMaxKeepAliveCount", 0);
	if (svp != NULL)
		out.revisedMaxKeepAliveCount = XS_unpack_UA_UInt32(*svp);

	return out;
}

/* SetPublishingModeRequest */
static void XS_pack_UA_SetPublishingModeRequest(SV *out, UA_SetPublishingModeRequest in)  __attribute__((unused));
static void
XS_pack_UA_SetPublishingModeRequest(SV *out, UA_SetPublishingModeRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "SetPublishingModeRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.publishingEnabled);
	hv_stores(hv, "SetPublishingModeRequest_publishingEnabled", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.subscriptionIdsSize);
	for (i = 0; i < in.subscriptionIdsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_UInt32(sv, in.subscriptionIds[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "SetPublishingModeRequest_subscriptionIds", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_SetPublishingModeRequest XS_unpack_UA_SetPublishingModeRequest(SV *in)  __attribute__((unused));
static UA_SetPublishingModeRequest
XS_unpack_UA_SetPublishingModeRequest(SV *in)
{
	dTHX;
	UA_SetPublishingModeRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_SetPublishingModeRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SetPublishingModeRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "SetPublishingModeRequest_publishingEnabled", 0);
	if (svp != NULL)
		out.publishingEnabled = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "SetPublishingModeRequest_subscriptionIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for SetPublishingModeRequest_subscriptionIds");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.subscriptionIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out.subscriptionIds == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.subscriptionIds[i] = XS_unpack_UA_UInt32(*svp);
			}
		}
		out.subscriptionIdsSize = i;
	}

	return out;
}

/* SetPublishingModeResponse */
static void XS_pack_UA_SetPublishingModeResponse(SV *out, UA_SetPublishingModeResponse in)  __attribute__((unused));
static void
XS_pack_UA_SetPublishingModeResponse(SV *out, UA_SetPublishingModeResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "SetPublishingModeResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.resultsSize);
	for (i = 0; i < in.resultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_StatusCode(sv, in.results[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "SetPublishingModeResponse_results", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "SetPublishingModeResponse_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_SetPublishingModeResponse XS_unpack_UA_SetPublishingModeResponse(SV *in)  __attribute__((unused));
static UA_SetPublishingModeResponse
XS_unpack_UA_SetPublishingModeResponse(SV *in)
{
	dTHX;
	UA_SetPublishingModeResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_SetPublishingModeResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SetPublishingModeResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "SetPublishingModeResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for SetPublishingModeResponse_results");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out.results == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.results[i] = XS_unpack_UA_StatusCode(*svp);
			}
		}
		out.resultsSize = i;
	}

	svp = hv_fetchs(hv, "SetPublishingModeResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for SetPublishingModeResponse_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* NotificationMessage */
static void XS_pack_UA_NotificationMessage(SV *out, UA_NotificationMessage in)  __attribute__((unused));
static void
XS_pack_UA_NotificationMessage(SV *out, UA_NotificationMessage in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.sequenceNumber);
	hv_stores(hv, "NotificationMessage_sequenceNumber", sv);

	sv = newSV(0);
	XS_pack_UA_DateTime(sv, in.publishTime);
	hv_stores(hv, "NotificationMessage_publishTime", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.notificationDataSize);
	for (i = 0; i < in.notificationDataSize; i++) {
		sv = newSV(0);
		XS_pack_UA_ExtensionObject(sv, in.notificationData[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "NotificationMessage_notificationData", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_NotificationMessage XS_unpack_UA_NotificationMessage(SV *in)  __attribute__((unused));
static UA_NotificationMessage
XS_unpack_UA_NotificationMessage(SV *in)
{
	dTHX;
	UA_NotificationMessage out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_NotificationMessage_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "NotificationMessage_sequenceNumber", 0);
	if (svp != NULL)
		out.sequenceNumber = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "NotificationMessage_publishTime", 0);
	if (svp != NULL)
		out.publishTime = XS_unpack_UA_DateTime(*svp);

	svp = hv_fetchs(hv, "NotificationMessage_notificationData", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for NotificationMessage_notificationData");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.notificationData = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_EXTENSIONOBJECT]);
		if (out.notificationData == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.notificationData[i] = XS_unpack_UA_ExtensionObject(*svp);
			}
		}
		out.notificationDataSize = i;
	}

	return out;
}

/* MonitoredItemNotification */
static void XS_pack_UA_MonitoredItemNotification(SV *out, UA_MonitoredItemNotification in)  __attribute__((unused));
static void
XS_pack_UA_MonitoredItemNotification(SV *out, UA_MonitoredItemNotification in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.clientHandle);
	hv_stores(hv, "MonitoredItemNotification_clientHandle", sv);

	sv = newSV(0);
	XS_pack_UA_DataValue(sv, in.value);
	hv_stores(hv, "MonitoredItemNotification_value", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_MonitoredItemNotification XS_unpack_UA_MonitoredItemNotification(SV *in)  __attribute__((unused));
static UA_MonitoredItemNotification
XS_unpack_UA_MonitoredItemNotification(SV *in)
{
	dTHX;
	UA_MonitoredItemNotification out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_MonitoredItemNotification_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "MonitoredItemNotification_clientHandle", 0);
	if (svp != NULL)
		out.clientHandle = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "MonitoredItemNotification_value", 0);
	if (svp != NULL)
		out.value = XS_unpack_UA_DataValue(*svp);

	return out;
}

/* EventFieldList */
static void XS_pack_UA_EventFieldList(SV *out, UA_EventFieldList in)  __attribute__((unused));
static void
XS_pack_UA_EventFieldList(SV *out, UA_EventFieldList in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.clientHandle);
	hv_stores(hv, "EventFieldList_clientHandle", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.eventFieldsSize);
	for (i = 0; i < in.eventFieldsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_Variant(sv, in.eventFields[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "EventFieldList_eventFields", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_EventFieldList XS_unpack_UA_EventFieldList(SV *in)  __attribute__((unused));
static UA_EventFieldList
XS_unpack_UA_EventFieldList(SV *in)
{
	dTHX;
	UA_EventFieldList out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_EventFieldList_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EventFieldList_clientHandle", 0);
	if (svp != NULL)
		out.clientHandle = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "EventFieldList_eventFields", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for EventFieldList_eventFields");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.eventFields = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_VARIANT]);
		if (out.eventFields == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.eventFields[i] = XS_unpack_UA_Variant(*svp);
			}
		}
		out.eventFieldsSize = i;
	}

	return out;
}

/* StatusChangeNotification */
static void XS_pack_UA_StatusChangeNotification(SV *out, UA_StatusChangeNotification in)  __attribute__((unused));
static void
XS_pack_UA_StatusChangeNotification(SV *out, UA_StatusChangeNotification in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_StatusCode(sv, in.status);
	hv_stores(hv, "StatusChangeNotification_status", sv);

	sv = newSV(0);
	XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfo);
	hv_stores(hv, "StatusChangeNotification_diagnosticInfo", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_StatusChangeNotification XS_unpack_UA_StatusChangeNotification(SV *in)  __attribute__((unused));
static UA_StatusChangeNotification
XS_unpack_UA_StatusChangeNotification(SV *in)
{
	dTHX;
	UA_StatusChangeNotification out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_StatusChangeNotification_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "StatusChangeNotification_status", 0);
	if (svp != NULL)
		out.status = XS_unpack_UA_StatusCode(*svp);

	svp = hv_fetchs(hv, "StatusChangeNotification_diagnosticInfo", 0);
	if (svp != NULL)
		out.diagnosticInfo = XS_unpack_UA_DiagnosticInfo(*svp);

	return out;
}

/* SubscriptionAcknowledgement */
static void XS_pack_UA_SubscriptionAcknowledgement(SV *out, UA_SubscriptionAcknowledgement in)  __attribute__((unused));
static void
XS_pack_UA_SubscriptionAcknowledgement(SV *out, UA_SubscriptionAcknowledgement in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.subscriptionId);
	hv_stores(hv, "SubscriptionAcknowledgement_subscriptionId", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.sequenceNumber);
	hv_stores(hv, "SubscriptionAcknowledgement_sequenceNumber", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_SubscriptionAcknowledgement XS_unpack_UA_SubscriptionAcknowledgement(SV *in)  __attribute__((unused));
static UA_SubscriptionAcknowledgement
XS_unpack_UA_SubscriptionAcknowledgement(SV *in)
{
	dTHX;
	UA_SubscriptionAcknowledgement out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_SubscriptionAcknowledgement_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "SubscriptionAcknowledgement_subscriptionId", 0);
	if (svp != NULL)
		out.subscriptionId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "SubscriptionAcknowledgement_sequenceNumber", 0);
	if (svp != NULL)
		out.sequenceNumber = XS_unpack_UA_UInt32(*svp);

	return out;
}

/* PublishRequest */
static void XS_pack_UA_PublishRequest(SV *out, UA_PublishRequest in)  __attribute__((unused));
static void
XS_pack_UA_PublishRequest(SV *out, UA_PublishRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "PublishRequest_requestHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.subscriptionAcknowledgementsSize);
	for (i = 0; i < in.subscriptionAcknowledgementsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_SubscriptionAcknowledgement(sv, in.subscriptionAcknowledgements[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "PublishRequest_subscriptionAcknowledgements", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_PublishRequest XS_unpack_UA_PublishRequest(SV *in)  __attribute__((unused));
static UA_PublishRequest
XS_unpack_UA_PublishRequest(SV *in)
{
	dTHX;
	UA_PublishRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_PublishRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "PublishRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "PublishRequest_subscriptionAcknowledgements", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for PublishRequest_subscriptionAcknowledgements");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.subscriptionAcknowledgements = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_SUBSCRIPTIONACKNOWLEDGEMENT]);
		if (out.subscriptionAcknowledgements == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.subscriptionAcknowledgements[i] = XS_unpack_UA_SubscriptionAcknowledgement(*svp);
			}
		}
		out.subscriptionAcknowledgementsSize = i;
	}

	return out;
}

/* PublishResponse */
static void XS_pack_UA_PublishResponse(SV *out, UA_PublishResponse in)  __attribute__((unused));
static void
XS_pack_UA_PublishResponse(SV *out, UA_PublishResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "PublishResponse_responseHeader", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.subscriptionId);
	hv_stores(hv, "PublishResponse_subscriptionId", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.availableSequenceNumbersSize);
	for (i = 0; i < in.availableSequenceNumbersSize; i++) {
		sv = newSV(0);
		XS_pack_UA_UInt32(sv, in.availableSequenceNumbers[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "PublishResponse_availableSequenceNumbers", newRV_inc((SV*)av));

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.moreNotifications);
	hv_stores(hv, "PublishResponse_moreNotifications", sv);

	sv = newSV(0);
	XS_pack_UA_NotificationMessage(sv, in.notificationMessage);
	hv_stores(hv, "PublishResponse_notificationMessage", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.resultsSize);
	for (i = 0; i < in.resultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_StatusCode(sv, in.results[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "PublishResponse_results", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "PublishResponse_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_PublishResponse XS_unpack_UA_PublishResponse(SV *in)  __attribute__((unused));
static UA_PublishResponse
XS_unpack_UA_PublishResponse(SV *in)
{
	dTHX;
	UA_PublishResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_PublishResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "PublishResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "PublishResponse_subscriptionId", 0);
	if (svp != NULL)
		out.subscriptionId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "PublishResponse_availableSequenceNumbers", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for PublishResponse_availableSequenceNumbers");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.availableSequenceNumbers = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out.availableSequenceNumbers == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.availableSequenceNumbers[i] = XS_unpack_UA_UInt32(*svp);
			}
		}
		out.availableSequenceNumbersSize = i;
	}

	svp = hv_fetchs(hv, "PublishResponse_moreNotifications", 0);
	if (svp != NULL)
		out.moreNotifications = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "PublishResponse_notificationMessage", 0);
	if (svp != NULL)
		out.notificationMessage = XS_unpack_UA_NotificationMessage(*svp);

	svp = hv_fetchs(hv, "PublishResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for PublishResponse_results");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out.results == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.results[i] = XS_unpack_UA_StatusCode(*svp);
			}
		}
		out.resultsSize = i;
	}

	svp = hv_fetchs(hv, "PublishResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for PublishResponse_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* RepublishRequest */
static void XS_pack_UA_RepublishRequest(SV *out, UA_RepublishRequest in)  __attribute__((unused));
static void
XS_pack_UA_RepublishRequest(SV *out, UA_RepublishRequest in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "RepublishRequest_requestHeader", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.subscriptionId);
	hv_stores(hv, "RepublishRequest_subscriptionId", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.retransmitSequenceNumber);
	hv_stores(hv, "RepublishRequest_retransmitSequenceNumber", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_RepublishRequest XS_unpack_UA_RepublishRequest(SV *in)  __attribute__((unused));
static UA_RepublishRequest
XS_unpack_UA_RepublishRequest(SV *in)
{
	dTHX;
	UA_RepublishRequest out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_RepublishRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RepublishRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "RepublishRequest_subscriptionId", 0);
	if (svp != NULL)
		out.subscriptionId = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "RepublishRequest_retransmitSequenceNumber", 0);
	if (svp != NULL)
		out.retransmitSequenceNumber = XS_unpack_UA_UInt32(*svp);

	return out;
}

/* RepublishResponse */
static void XS_pack_UA_RepublishResponse(SV *out, UA_RepublishResponse in)  __attribute__((unused));
static void
XS_pack_UA_RepublishResponse(SV *out, UA_RepublishResponse in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "RepublishResponse_responseHeader", sv);

	sv = newSV(0);
	XS_pack_UA_NotificationMessage(sv, in.notificationMessage);
	hv_stores(hv, "RepublishResponse_notificationMessage", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_RepublishResponse XS_unpack_UA_RepublishResponse(SV *in)  __attribute__((unused));
static UA_RepublishResponse
XS_unpack_UA_RepublishResponse(SV *in)
{
	dTHX;
	UA_RepublishResponse out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_RepublishResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "RepublishResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "RepublishResponse_notificationMessage", 0);
	if (svp != NULL)
		out.notificationMessage = XS_unpack_UA_NotificationMessage(*svp);

	return out;
}

/* DeleteSubscriptionsRequest */
static void XS_pack_UA_DeleteSubscriptionsRequest(SV *out, UA_DeleteSubscriptionsRequest in)  __attribute__((unused));
static void
XS_pack_UA_DeleteSubscriptionsRequest(SV *out, UA_DeleteSubscriptionsRequest in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_RequestHeader(sv, in.requestHeader);
	hv_stores(hv, "DeleteSubscriptionsRequest_requestHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.subscriptionIdsSize);
	for (i = 0; i < in.subscriptionIdsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_UInt32(sv, in.subscriptionIds[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "DeleteSubscriptionsRequest_subscriptionIds", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_DeleteSubscriptionsRequest XS_unpack_UA_DeleteSubscriptionsRequest(SV *in)  __attribute__((unused));
static UA_DeleteSubscriptionsRequest
XS_unpack_UA_DeleteSubscriptionsRequest(SV *in)
{
	dTHX;
	UA_DeleteSubscriptionsRequest out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_DeleteSubscriptionsRequest_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteSubscriptionsRequest_requestHeader", 0);
	if (svp != NULL)
		out.requestHeader = XS_unpack_UA_RequestHeader(*svp);

	svp = hv_fetchs(hv, "DeleteSubscriptionsRequest_subscriptionIds", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for DeleteSubscriptionsRequest_subscriptionIds");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.subscriptionIds = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
		if (out.subscriptionIds == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.subscriptionIds[i] = XS_unpack_UA_UInt32(*svp);
			}
		}
		out.subscriptionIdsSize = i;
	}

	return out;
}

/* DeleteSubscriptionsResponse */
static void XS_pack_UA_DeleteSubscriptionsResponse(SV *out, UA_DeleteSubscriptionsResponse in)  __attribute__((unused));
static void
XS_pack_UA_DeleteSubscriptionsResponse(SV *out, UA_DeleteSubscriptionsResponse in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_ResponseHeader(sv, in.responseHeader);
	hv_stores(hv, "DeleteSubscriptionsResponse_responseHeader", sv);

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.resultsSize);
	for (i = 0; i < in.resultsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_StatusCode(sv, in.results[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "DeleteSubscriptionsResponse_results", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "DeleteSubscriptionsResponse_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_DeleteSubscriptionsResponse XS_unpack_UA_DeleteSubscriptionsResponse(SV *in)  __attribute__((unused));
static UA_DeleteSubscriptionsResponse
XS_unpack_UA_DeleteSubscriptionsResponse(SV *in)
{
	dTHX;
	UA_DeleteSubscriptionsResponse out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_DeleteSubscriptionsResponse_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DeleteSubscriptionsResponse_responseHeader", 0);
	if (svp != NULL)
		out.responseHeader = XS_unpack_UA_ResponseHeader(*svp);

	svp = hv_fetchs(hv, "DeleteSubscriptionsResponse_results", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for DeleteSubscriptionsResponse_results");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.results = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_STATUSCODE]);
		if (out.results == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.results[i] = XS_unpack_UA_StatusCode(*svp);
			}
		}
		out.resultsSize = i;
	}

	svp = hv_fetchs(hv, "DeleteSubscriptionsResponse_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for DeleteSubscriptionsResponse_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* BuildInfo */
static void XS_pack_UA_BuildInfo(SV *out, UA_BuildInfo in)  __attribute__((unused));
static void
XS_pack_UA_BuildInfo(SV *out, UA_BuildInfo in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_String(sv, in.productUri);
	hv_stores(hv, "BuildInfo_productUri", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.manufacturerName);
	hv_stores(hv, "BuildInfo_manufacturerName", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.productName);
	hv_stores(hv, "BuildInfo_productName", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.softwareVersion);
	hv_stores(hv, "BuildInfo_softwareVersion", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.buildNumber);
	hv_stores(hv, "BuildInfo_buildNumber", sv);

	sv = newSV(0);
	XS_pack_UA_DateTime(sv, in.buildDate);
	hv_stores(hv, "BuildInfo_buildDate", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_BuildInfo XS_unpack_UA_BuildInfo(SV *in)  __attribute__((unused));
static UA_BuildInfo
XS_unpack_UA_BuildInfo(SV *in)
{
	dTHX;
	UA_BuildInfo out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_BuildInfo_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "BuildInfo_productUri", 0);
	if (svp != NULL)
		out.productUri = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "BuildInfo_manufacturerName", 0);
	if (svp != NULL)
		out.manufacturerName = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "BuildInfo_productName", 0);
	if (svp != NULL)
		out.productName = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "BuildInfo_softwareVersion", 0);
	if (svp != NULL)
		out.softwareVersion = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "BuildInfo_buildNumber", 0);
	if (svp != NULL)
		out.buildNumber = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "BuildInfo_buildDate", 0);
	if (svp != NULL)
		out.buildDate = XS_unpack_UA_DateTime(*svp);

	return out;
}

/* RedundancySupport */
static void XS_pack_UA_RedundancySupport(SV *out, UA_RedundancySupport in)  __attribute__((unused));
static void
XS_pack_UA_RedundancySupport(SV *out, UA_RedundancySupport in)
{
	dTHX;
	sv_setiv(out, in);
}

static UA_RedundancySupport XS_unpack_UA_RedundancySupport(SV *in)  __attribute__((unused));
static UA_RedundancySupport
XS_unpack_UA_RedundancySupport(SV *in)
{
	dTHX;
	return SvIV(in);
}

/* ServerState */
static void XS_pack_UA_ServerState(SV *out, UA_ServerState in)  __attribute__((unused));
static void
XS_pack_UA_ServerState(SV *out, UA_ServerState in)
{
	dTHX;
	sv_setiv(out, in);
}

static UA_ServerState XS_unpack_UA_ServerState(SV *in)  __attribute__((unused));
static UA_ServerState
XS_unpack_UA_ServerState(SV *in)
{
	dTHX;
	return SvIV(in);
}

/* ServerDiagnosticsSummaryDataType */
static void XS_pack_UA_ServerDiagnosticsSummaryDataType(SV *out, UA_ServerDiagnosticsSummaryDataType in)  __attribute__((unused));
static void
XS_pack_UA_ServerDiagnosticsSummaryDataType(SV *out, UA_ServerDiagnosticsSummaryDataType in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.serverViewCount);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_serverViewCount", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.currentSessionCount);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_currentSessionCount", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.cumulatedSessionCount);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_cumulatedSessionCount", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.securityRejectedSessionCount);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_securityRejectedSessionCount", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.rejectedSessionCount);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_rejectedSessionCount", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.sessionTimeoutCount);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_sessionTimeoutCount", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.sessionAbortCount);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_sessionAbortCount", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.currentSubscriptionCount);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_currentSubscriptionCount", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.cumulatedSubscriptionCount);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_cumulatedSubscriptionCount", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.publishingIntervalCount);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_publishingIntervalCount", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.securityRejectedRequestsCount);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_securityRejectedRequestsCount", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.rejectedRequestsCount);
	hv_stores(hv, "ServerDiagnosticsSummaryDataType_rejectedRequestsCount", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ServerDiagnosticsSummaryDataType XS_unpack_UA_ServerDiagnosticsSummaryDataType(SV *in)  __attribute__((unused));
static UA_ServerDiagnosticsSummaryDataType
XS_unpack_UA_ServerDiagnosticsSummaryDataType(SV *in)
{
	dTHX;
	UA_ServerDiagnosticsSummaryDataType out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ServerDiagnosticsSummaryDataType_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_serverViewCount", 0);
	if (svp != NULL)
		out.serverViewCount = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_currentSessionCount", 0);
	if (svp != NULL)
		out.currentSessionCount = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_cumulatedSessionCount", 0);
	if (svp != NULL)
		out.cumulatedSessionCount = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_securityRejectedSessionCount", 0);
	if (svp != NULL)
		out.securityRejectedSessionCount = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_rejectedSessionCount", 0);
	if (svp != NULL)
		out.rejectedSessionCount = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_sessionTimeoutCount", 0);
	if (svp != NULL)
		out.sessionTimeoutCount = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_sessionAbortCount", 0);
	if (svp != NULL)
		out.sessionAbortCount = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_currentSubscriptionCount", 0);
	if (svp != NULL)
		out.currentSubscriptionCount = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_cumulatedSubscriptionCount", 0);
	if (svp != NULL)
		out.cumulatedSubscriptionCount = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_publishingIntervalCount", 0);
	if (svp != NULL)
		out.publishingIntervalCount = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_securityRejectedRequestsCount", 0);
	if (svp != NULL)
		out.securityRejectedRequestsCount = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ServerDiagnosticsSummaryDataType_rejectedRequestsCount", 0);
	if (svp != NULL)
		out.rejectedRequestsCount = XS_unpack_UA_UInt32(*svp);

	return out;
}

/* ServerStatusDataType */
static void XS_pack_UA_ServerStatusDataType(SV *out, UA_ServerStatusDataType in)  __attribute__((unused));
static void
XS_pack_UA_ServerStatusDataType(SV *out, UA_ServerStatusDataType in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_DateTime(sv, in.startTime);
	hv_stores(hv, "ServerStatusDataType_startTime", sv);

	sv = newSV(0);
	XS_pack_UA_DateTime(sv, in.currentTime);
	hv_stores(hv, "ServerStatusDataType_currentTime", sv);

	sv = newSV(0);
	XS_pack_UA_ServerState(sv, in.state);
	hv_stores(hv, "ServerStatusDataType_state", sv);

	sv = newSV(0);
	XS_pack_UA_BuildInfo(sv, in.buildInfo);
	hv_stores(hv, "ServerStatusDataType_buildInfo", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.secondsTillShutdown);
	hv_stores(hv, "ServerStatusDataType_secondsTillShutdown", sv);

	sv = newSV(0);
	XS_pack_UA_LocalizedText(sv, in.shutdownReason);
	hv_stores(hv, "ServerStatusDataType_shutdownReason", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_ServerStatusDataType XS_unpack_UA_ServerStatusDataType(SV *in)  __attribute__((unused));
static UA_ServerStatusDataType
XS_unpack_UA_ServerStatusDataType(SV *in)
{
	dTHX;
	UA_ServerStatusDataType out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_ServerStatusDataType_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ServerStatusDataType_startTime", 0);
	if (svp != NULL)
		out.startTime = XS_unpack_UA_DateTime(*svp);

	svp = hv_fetchs(hv, "ServerStatusDataType_currentTime", 0);
	if (svp != NULL)
		out.currentTime = XS_unpack_UA_DateTime(*svp);

	svp = hv_fetchs(hv, "ServerStatusDataType_state", 0);
	if (svp != NULL)
		out.state = XS_unpack_UA_ServerState(*svp);

	svp = hv_fetchs(hv, "ServerStatusDataType_buildInfo", 0);
	if (svp != NULL)
		out.buildInfo = XS_unpack_UA_BuildInfo(*svp);

	svp = hv_fetchs(hv, "ServerStatusDataType_secondsTillShutdown", 0);
	if (svp != NULL)
		out.secondsTillShutdown = XS_unpack_UA_UInt32(*svp);

	svp = hv_fetchs(hv, "ServerStatusDataType_shutdownReason", 0);
	if (svp != NULL)
		out.shutdownReason = XS_unpack_UA_LocalizedText(*svp);

	return out;
}

/* Range */
static void XS_pack_UA_Range(SV *out, UA_Range in)  __attribute__((unused));
static void
XS_pack_UA_Range(SV *out, UA_Range in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_Double(sv, in.low);
	hv_stores(hv, "Range_low", sv);

	sv = newSV(0);
	XS_pack_UA_Double(sv, in.high);
	hv_stores(hv, "Range_high", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_Range XS_unpack_UA_Range(SV *in)  __attribute__((unused));
static UA_Range
XS_unpack_UA_Range(SV *in)
{
	dTHX;
	UA_Range out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_Range_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "Range_low", 0);
	if (svp != NULL)
		out.low = XS_unpack_UA_Double(*svp);

	svp = hv_fetchs(hv, "Range_high", 0);
	if (svp != NULL)
		out.high = XS_unpack_UA_Double(*svp);

	return out;
}

/* DataChangeNotification */
static void XS_pack_UA_DataChangeNotification(SV *out, UA_DataChangeNotification in)  __attribute__((unused));
static void
XS_pack_UA_DataChangeNotification(SV *out, UA_DataChangeNotification in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.monitoredItemsSize);
	for (i = 0; i < in.monitoredItemsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_MonitoredItemNotification(sv, in.monitoredItems[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "DataChangeNotification_monitoredItems", newRV_inc((SV*)av));

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.diagnosticInfosSize);
	for (i = 0; i < in.diagnosticInfosSize; i++) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, in.diagnosticInfos[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "DataChangeNotification_diagnosticInfos", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_DataChangeNotification XS_unpack_UA_DataChangeNotification(SV *in)  __attribute__((unused));
static UA_DataChangeNotification
XS_unpack_UA_DataChangeNotification(SV *in)
{
	dTHX;
	UA_DataChangeNotification out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_DataChangeNotification_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DataChangeNotification_monitoredItems", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for DataChangeNotification_monitoredItems");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.monitoredItems = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_MONITOREDITEMNOTIFICATION]);
		if (out.monitoredItems == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.monitoredItems[i] = XS_unpack_UA_MonitoredItemNotification(*svp);
			}
		}
		out.monitoredItemsSize = i;
	}

	svp = hv_fetchs(hv, "DataChangeNotification_diagnosticInfos", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for DataChangeNotification_diagnosticInfos");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.diagnosticInfos = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_DIAGNOSTICINFO]);
		if (out.diagnosticInfos == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.diagnosticInfos[i] = XS_unpack_UA_DiagnosticInfo(*svp);
			}
		}
		out.diagnosticInfosSize = i;
	}

	return out;
}

/* EventNotificationList */
static void XS_pack_UA_EventNotificationList(SV *out, UA_EventNotificationList in)  __attribute__((unused));
static void
XS_pack_UA_EventNotificationList(SV *out, UA_EventNotificationList in)
{
	dTHX;
	SV *sv;
	AV *av;
	size_t i;
	HV *hv = newHV();

	av = (AV*)sv_2mortal((SV*)newAV());
	av_extend(av, in.eventsSize);
	for (i = 0; i < in.eventsSize; i++) {
		sv = newSV(0);
		XS_pack_UA_EventFieldList(sv, in.events[i]);
		av_push(av, sv);
	}
	hv_stores(hv, "EventNotificationList_events", newRV_inc((SV*)av));

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

static UA_EventNotificationList XS_unpack_UA_EventNotificationList(SV *in)  __attribute__((unused));
static UA_EventNotificationList
XS_unpack_UA_EventNotificationList(SV *in)
{
	dTHX;
	UA_EventNotificationList out;
	SV **svp;
	AV *av;
	ssize_t i, top;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_EventNotificationList_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "EventNotificationList_events", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
			CROAK("No ARRAY reference for EventNotificationList_events");
		}
		av = (AV*)SvRV(*svp);
		top = av_top_index(av);
		out.events = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_EVENTFIELDLIST]);
		if (out.events == NULL) {
			CROAKE("UA_Array_new");
		}
		for (i = 0; i <= top; i++) {
			svp = av_fetch(av, i, 0);
			if (svp != NULL) {
				out.events[i] = XS_unpack_UA_EventFieldList(*svp);
			}
		}
		out.eventsSize = i;
	}

	return out;
}
