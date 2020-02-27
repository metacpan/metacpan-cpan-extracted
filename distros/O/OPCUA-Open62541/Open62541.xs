/*
 * Copyright (c) 2020 Alexander Bluhm
 * Copyright (c) 2020 Anton Borowka
 * Copyright (c) 2020 Marvin Knoblauch
 *
 * This is free software; you can redistribute it and/or modify it under
 * the same terms as the Perl 5 programming language system itself.
 *
 * Thanks to genua GmbH, https://www.genua.de/ for sponsoring this work.
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
#include <open62541/client_highlevel.h>
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
typedef UA_LocalizedText *	OPCUA_Open62541_LocalizedText;

/* types_generated.h */
typedef UA_BrowseResultMask	OPCUA_Open62541_BrowseResultMask;
typedef UA_Variant *		OPCUA_Open62541_Variant;

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
	dTHX;
	return SvTRUE(in);
}

static void
XS_pack_UA_Boolean(SV *out, UA_Boolean in)
{
	dTHX;
	sv_setsv(out, boolSV(in));
}

/* 6.1.2 SByte ... 6.1.9 UInt64, types.h */

#define XS_PACKED_CHECK_IV(type, limit)					\
									\
static UA_##type							\
XS_unpack_UA_##type(SV *in)						\
{									\
	dTHX;								\
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
	dTHX;								\
	sv_setiv(out, in);						\
}

#define XS_PACKED_CHECK_UV(type, limit)					\
									\
static UA_##type							\
XS_unpack_UA_##type(SV *in)						\
{									\
	dTHX;								\
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
	dTHX;								\
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
	dTHX;
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
	dTHX;
	sv_setnv(out, in);
}

/* 6.1.11 Double, types.h */

static UA_Double
XS_unpack_UA_Double(SV *in)
{
	dTHX;
	return SvNV(in);
}

static void
XS_pack_UA_Double(SV *out, UA_Double in)
{
	dTHX;
	sv_setnv(out, in);
}

/* 6.1.12 StatusCode, types.h */

static UA_StatusCode
XS_unpack_UA_StatusCode(SV *in)
{
	dTHX;
	return SvUV(in);
}

static void
XS_pack_UA_StatusCode(SV *out, UA_StatusCode in)
{
	dTHX;
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
	dTHX;
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
	dTHX;
	if (in.data == NULL) {
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
	dTHX;
	return SvIV(in);
}

static void
XS_pack_UA_DateTime(SV *out, UA_DateTime in)
{
	dTHX;
	sv_setiv(out, in);
}

/* 6.1.15 Guid, types.h */

static UA_Guid
XS_unpack_UA_Guid(SV *in)
{
	dTHX;
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
	dTHX;
	sv_setpvn(out, (char *)&in, sizeof(in));
}

/* 6.1.16 ByteString, types.h */

static UA_ByteString
XS_unpack_UA_ByteString(SV *in)
{
	dTHX;
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
	dTHX;
	if (in.data == NULL) {
		/* Convert NULL string to undef. */
		sv_setsv(out, &PL_sv_undef);
		return;
	}
	sv_setpvn(out, in.data, in.length);
}

/* 6.1.17 XmlElement, types.h */

static void
XS_pack_UA_XmlElement(SV *out, UA_XmlElement in)
{
	XS_pack_UA_String(out, in);
}

static UA_XmlElement
XS_unpack_UA_XmlElement(SV *in)
{
	return XS_unpack_UA_String(in);
}

/* 6.1.18 NodeId, types.h */

static UA_NodeId
XS_unpack_UA_NodeId(SV *in)
{
	dTHX;
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
	dTHX;
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

/* 6.1.19 ExpandedNodeId, types.h */

static UA_ExpandedNodeId
XS_unpack_UA_ExpandedNodeId(SV *in)
{
	dTHX;
	UA_ExpandedNodeId out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		croak("%s: Not a HASH reference", __func__);
	}
	UA_ExpandedNodeId_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ExpandedNodeId_nodeId", 0);
	if (svp != NULL)
		out.nodeId = XS_unpack_UA_NodeId(*svp);

	svp = hv_fetchs(hv, "ExpandedNodeId_namespaceUri", 0);
	if (svp != NULL)
		out.namespaceUri = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "ExpandedNodeId_serverIndex", 0);
	if (svp != NULL)
		out.serverIndex = XS_unpack_UA_UInt32(*svp);

	return out;
}

static void
XS_pack_UA_ExpandedNodeId(SV *out, UA_ExpandedNodeId in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_NodeId(sv, in.nodeId);
	hv_stores(hv, "ExpandedNodeId_nodeId", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.namespaceUri);
	hv_stores(hv, "ExpandedNodeId_namespaceUri", sv);

	sv = newSV(0);
	XS_pack_UA_UInt32(sv, in.serverIndex);
	hv_stores(hv, "ExpandedNodeId_serverIndex", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

/* 6.1.20 QualifiedName, types.h */

static UA_QualifiedName
XS_unpack_UA_QualifiedName(SV *in)
{
	dTHX;
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
	dTHX;
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

/* 6.1.21 LocalizedText, types.h */

static UA_LocalizedText
XS_unpack_UA_LocalizedText(SV *in)
{
	dTHX;
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
	dTHX;
	SV *sv;
	HV *hv = newHV();

	if (in.locale.data != NULL) {
		sv = newSV(0);
		XS_pack_UA_String(sv, in.locale);
		hv_stores(hv, "LocalizedText_locale", sv);
	}

	sv = newSV(0);
	XS_pack_UA_String(sv, in.text);
	hv_stores(hv, "LocalizedText_text", sv);

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

/* 6.1.23 Variant, types.h */

typedef void (*packed_UA)(SV *, void *);
#include "Open62541-packed-type.xsh"

static void
OPCUA_Open62541_Variant_setScalar(OPCUA_Open62541_Variant variant, SV *sv,
    OPCUA_Open62541_DataType type)
{
	void *scalar;

	scalar = UA_new(type);
	if (scalar == NULL) {
		croak("%s: UA_new type %d, name %s",
		    __func__, type->typeIndex, type->typeName);
	}
	(unpack_UA_table[type->typeIndex])(sv, scalar);
	UA_Variant_setScalar(variant, scalar, type);
}

static UA_Variant
XS_unpack_UA_Variant(SV *in)
{
	dTHX;
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
	(pack_UA_table[variant->type->typeIndex])(sv, variant->data);
}

static void
XS_pack_UA_Variant(SV *out, UA_Variant in)
{
	dTHX;
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

/* 6.1.24 ExtensionObject, types.h */

static UA_ExtensionObject
XS_unpack_UA_ExtensionObject(SV *in)
{
	dTHX;
	UA_ExtensionObject out;
	SV **svp;
	HV *hv, *content;
	IV encoding;
	void *data;
	OPCUA_Open62541_DataType type;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		croak("is not a HASH reference");
	}
	UA_ExtensionObject_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ExtensionObject_encoding", 0);
	if (svp == NULL)
		croak("%s: No ExtensionObject_encoding in HASH", __func__);
	encoding = SvIV(*svp);
	out.encoding = encoding;

	svp = hv_fetchs(hv, "ExtensionObject_content", 0);
	if (svp == NULL)
		croak("%s: No ExtensionObject_content in HASH", __func__);
	if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVHV)
		croak("%s: ExtensionObject_content is not a HASH", __func__);
	content = (HV*)SvRV(*svp);

	switch (encoding) {
	case UA_EXTENSIONOBJECT_ENCODED_NOBODY:
	case UA_EXTENSIONOBJECT_ENCODED_BYTESTRING:
	case UA_EXTENSIONOBJECT_ENCODED_XML:
		svp = hv_fetchs(content, "ExtensionObject_content_typeId", 0);
		if (svp == NULL)
			croak("%s: No ExtensionObject_content_typeId in HASH", __func__);
		out.content.encoded.typeId = XS_unpack_UA_NodeId(*svp);

		svp = hv_fetchs(content, "ExtensionObject_content_body", 0);
		if (svp == NULL)
			croak("%s: No ExtensionObject_content_body in HASH", __func__);
		out.content.encoded.body = XS_unpack_UA_ByteString(*svp);

		break;
	case UA_EXTENSIONOBJECT_DECODED:
	case UA_EXTENSIONOBJECT_DECODED_NODELETE:
		svp = hv_fetchs(content, "ExtensionObject_content_type", 0);
		if (svp == NULL)
			croak("%s: No ExtensionObject_content_type in HASH", __func__);
		type = XS_unpack_OPCUA_Open62541_DataType(*svp);
		out.content.decoded.type = type;

		svp = hv_fetchs(content, "ExtensionObject_content_data", 0);
		if (svp == NULL)
			croak("%s: No ExtensionObject_content_data in HASH", __func__);

		data = UA_new(type);
		if (data == NULL) {
			croak("%s: UA_new type %d, name %s",
			    __func__, type->typeIndex, type->typeName);
		}
		(unpack_UA_table[type->typeIndex])(*svp, data);

		break;
	default:
		croak("%s: ExtensionObject_encoding %ld unknown",
		    __func__, encoding);
	}
	return out;
}

static void
XS_pack_UA_ExtensionObject(SV *out, UA_ExtensionObject in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_Int32(sv, in.encoding);
	hv_stores(hv, "ExtensionObject_encoding", sv);

	switch (in.encoding) {
	case UA_EXTENSIONOBJECT_ENCODED_NOBODY:
	case UA_EXTENSIONOBJECT_ENCODED_BYTESTRING:
	case UA_EXTENSIONOBJECT_ENCODED_XML:
		sv = newSV(0);
		XS_pack_UA_NodeId(sv, in.content.encoded.typeId);
		hv_stores(hv, "ExtensionObject_content_typeId", sv);

		sv = newSV(0);
		XS_pack_UA_ByteString(sv, in.content.encoded.body);
		hv_stores(hv, "ExtensionObject_content_body", sv);

		break;
	case UA_EXTENSIONOBJECT_DECODED:
	case UA_EXTENSIONOBJECT_DECODED_NODELETE:
		sv = newSV(0);
		XS_pack_OPCUA_Open62541_DataType(sv, in.content.decoded.type);
		hv_stores(hv, "ExtensionObject_content_type", sv);

		sv = newSV(0);
		(pack_UA_table[in.content.decoded.type->typeIndex])(sv, in.content.decoded.data);
		hv_stores(hv, "ExtensionObject_content_data", sv);

		break;
	default:
		croak("%s: ExtensionObject_encoding %d unknown",
		    __func__, (int)in.encoding);
	}

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

/* 6.2 Generic Type Handling, UA_DataType, types.h */

static OPCUA_Open62541_DataType
XS_unpack_OPCUA_Open62541_DataType(SV *in)
{
	dTHX;
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
	dTHX;
	sv_setuv(out, in->typeIndex);
}

/* 6.1.25 DataValue, types.h */

static UA_DataValue
XS_unpack_UA_DataValue(SV *in)
{
	dTHX;
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
	dTHX;
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

/* 6.1.26 DiagnosticInfo, types.h */

static UA_DiagnosticInfo
XS_unpack_UA_DiagnosticInfo(SV *in)
{
	dTHX;
	UA_DiagnosticInfo out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		croak("%s: Not a HASH reference", __func__);
	}
	UA_DiagnosticInfo_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DiagnosticInfo_hasSymbolicId", 0);
	if (svp != NULL)
		out.hasSymbolicId = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_hasNamespaceUri", 0);
	if (svp != NULL)
		out.hasNamespaceUri = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_hasLocalizedText", 0);
	if (svp != NULL)
		out.hasLocalizedText = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_hasLocale", 0);
	if (svp != NULL)
		out.hasLocale = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_hasAdditionalInfo", 0);
	if (svp != NULL)
		out.hasAdditionalInfo = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_hasInnerStatusCode", 0);
	if (svp != NULL)
		out.hasInnerStatusCode = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_hasInnerDiagnosticInfo", 0);
	if (svp != NULL)
		out.hasInnerDiagnosticInfo = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_symbolicId", 0);
	if (svp != NULL)
		out.symbolicId = XS_unpack_UA_Int32(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_namespaceUri", 0);
	if (svp != NULL)
		out.namespaceUri = XS_unpack_UA_Int32(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_localizedText", 0);
	if (svp != NULL)
		out.localizedText = XS_unpack_UA_Int32(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_locale", 0);
	if (svp != NULL)
		out.locale = XS_unpack_UA_Int32(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_additionalInfo", 0);
	if (svp != NULL)
		out.additionalInfo = XS_unpack_UA_String(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_innerStatusCode", 0);
	if (svp != NULL)
		out.innerStatusCode = XS_unpack_UA_StatusCode(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_innerDiagnosticInfo", 0);
	if (svp != NULL) {
		UA_DiagnosticInfo *innerDiagnostic = UA_DiagnosticInfo_new();
		*innerDiagnostic = XS_unpack_UA_DiagnosticInfo(*svp);
		out.innerDiagnosticInfo = innerDiagnostic;
	}

	return out;
}

static void
XS_pack_UA_DiagnosticInfo(SV *out, UA_DiagnosticInfo in)
{
	dTHX;
	SV *sv;
	HV *hv = newHV();

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.hasSymbolicId);
	hv_stores(hv, "DiagnosticInfo_hasSymbolicId", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.hasNamespaceUri);
	hv_stores(hv, "DiagnosticInfo_hasNamespaceUri", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.hasLocalizedText);
	hv_stores(hv, "DiagnosticInfo_hasLocalizedText", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.hasLocale);
	hv_stores(hv, "DiagnosticInfo_hasLocale", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.hasAdditionalInfo);
	hv_stores(hv, "DiagnosticInfo_hasAdditionalInfo", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.hasInnerStatusCode);
	hv_stores(hv, "DiagnosticInfo_hasInnerStatusCode", sv);

	sv = newSV(0);
	XS_pack_UA_Boolean(sv, in.hasInnerDiagnosticInfo);
	hv_stores(hv, "DiagnosticInfo_hasInnerDiagnosticInfo", sv);

	sv = newSV(0);
	XS_pack_UA_Int32(sv, in.symbolicId);
	hv_stores(hv, "DiagnosticInfo_symbolicId", sv);

	sv = newSV(0);
	XS_pack_UA_Int32(sv, in.namespaceUri);
	hv_stores(hv, "DiagnosticInfo_namespaceUri", sv);

	sv = newSV(0);
	XS_pack_UA_Int32(sv, in.localizedText);
	hv_stores(hv, "DiagnosticInfo_localizedText", sv);

	sv = newSV(0);
	XS_pack_UA_Int32(sv, in.locale);
	hv_stores(hv, "DiagnosticInfo_locale", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.additionalInfo);
	hv_stores(hv, "DiagnosticInfo_additionalInfo", sv);

	sv = newSV(0);
	XS_pack_UA_StatusCode(sv, in.innerStatusCode);
	hv_stores(hv, "DiagnosticInfo_innerStatusCode", sv);

	/* only make recursive call to inner diagnostic if it exists */
	if (in.innerDiagnosticInfo != NULL) {
		sv = newSV(0);
		XS_pack_UA_DiagnosticInfo(sv, *in.innerDiagnosticInfo);
		hv_stores(hv, "DiagnosticInfo_innerDiagnosticInfo", sv);
	}

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
}

/* Magic callback for UA_Server_run() will change the C variable. */
static int
server_run_mgset(pTHX_ SV* sv, MAGIC* mg)
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
	dTHX;
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
	dTHX;
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
	dTHX;
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
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::LocalizedText	PREFIX = UA_LocalizedText_

# 6.1.21 LocalizedText, types.h

OPCUA_Open62541_LocalizedText
UA_LocalizedText_new(class)
	char *				class
    INIT:
	if (strcmp(class, "OPCUA::Open62541::LocalizedText") != 0)
		croak("class '%s' is not OPCUA::Open62541::LocalizedText",
		    class);
    CODE:
	RETVAL = UA_LocalizedText_new();
	if (RETVAL == NULL)
		croak("%s: UA_LocalizedText_new", __func__);
	DPRINTF("localizedText %p", RETVAL);
    OUTPUT:
	RETVAL

void
UA_LocalizedText_DESTROY(localizedText)
	OPCUA_Open62541_LocalizedText		localizedText
    CODE:
	DPRINTF("localizedText %p", localizedText);
	UA_LocalizedText_delete(localizedText);

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

UA_StatusCode
UA_Client_readDisplayNameAttribute(client, nodeId, outDisplayName)
	OPCUA_Open62541_Client		client
	UA_NodeId			nodeId
	OPCUA_Open62541_LocalizedText	outDisplayName
    CODE:
	RETVAL = UA_Client_readDisplayNameAttribute(client, nodeId,
	    outDisplayName);
	if (SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) < SVt_PVAV)
		XS_pack_UA_LocalizedText(SvRV(ST(2)), *outDisplayName);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_readDescriptionAttribute(client, nodeId, outDescription)
	OPCUA_Open62541_Client		client
	UA_NodeId			nodeId
	OPCUA_Open62541_LocalizedText	outDescription
    CODE:
	RETVAL = UA_Client_readDescriptionAttribute(client, nodeId,
	    outDescription);
	if (SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) < SVt_PVAV)
		XS_pack_UA_LocalizedText(SvRV(ST(2)), *outDescription);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_readValueAttribute(client, nodeId, outValue)
	OPCUA_Open62541_Client		client
	UA_NodeId			nodeId
	OPCUA_Open62541_Variant		outValue
    CODE:
	RETVAL = UA_Client_readValueAttribute(client, nodeId, outValue);
	if (SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) < SVt_PVAV)
		XS_pack_UA_Variant(SvRV(ST(2)), *outValue);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_readDataTypeAttribute(client, nodeId, outDataType)
	OPCUA_Open62541_Client		client
	UA_NodeId			nodeId
	SV *				outDataType
    INIT:
	UA_NodeId			outNodeId;
	UV				index;
    CODE:
	if (!SvROK(outDataType) || SvTYPE(SvRV(outDataType)) >= SVt_PVAV) {
		croak("%s: outDataType is not a scalar reference", __func__);
	}
	RETVAL = UA_Client_readDataTypeAttribute(client, nodeId, &outNodeId);
	/*
	 * Convert NodeId to DataType, see XS_unpack_UA_NodeId() for
	 * the opposite direction.
	 */
	for (index = 0; index < UA_TYPES_COUNT; index++) {
		if (UA_NodeId_equal(&outNodeId, &UA_TYPES[index].typeId))
			break;
	}
	if (index < UA_TYPES_COUNT)
		XS_pack_OPCUA_Open62541_DataType(SvRV(outDataType),
		    &UA_TYPES[index]);
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
