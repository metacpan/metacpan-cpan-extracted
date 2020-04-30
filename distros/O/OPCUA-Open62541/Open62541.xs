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
# define DPRINTF(fmt, args...)						\
	fprintf(stderr, "%s: " fmt "\n", __func__, ##args)
#else
# define DPRINTF(fmt, x...)
#endif

static void croak_func(const char *, char *, ...)
    __attribute__noreturn__
    __attribute__format__null_ok__(__printf__,2,3);
static void croak_errno(const char *, char *, ...)
    __attribute__noreturn__
    __attribute__format__null_ok__(__printf__,2,3);
static void croak_status(const char *, UA_StatusCode, char *, ...)
    __attribute__noreturn__
    __attribute__format__null_ok__(__printf__,3,4);

static void
croak_func(const char *func, char *pat, ...)
{
	dTHX;
	va_list args;
	SV *sv;

	sv = sv_2mortal(newSV(126));

	if (pat == NULL) {
	    sv_setpv(sv, func);
	    croak_sv(sv);
	} else {
	    sv_setpvf(sv, "%s: ", func);
	    va_start(args, pat);
	    sv_vcatpvf(sv, pat, &args);
	    croak_sv(sv);
	    NOT_REACHED; /* NOTREACHED */
	    va_end(args);
	}
	NORETURN_FUNCTION_END;
}

static void
croak_errno(const char *func, char *pat, ...)
{
	dTHX;
	va_list args;
	SV *sv;
	int sverrno;

	sverrno = errno;
	sv = sv_2mortal(newSV(126));

	if (pat == NULL) {
	    sv_setpvf(sv, "%s: %s", func, strerror(sverrno));
	    croak_sv(sv);
	} else {
	    sv_setpvf(sv, "%s: ", func);
	    va_start(args, pat);
	    sv_vcatpvf(sv, pat, &args);
	    sv_catpvf(sv, ": %s", strerror(sverrno));
	    croak_sv(sv);
	    NOT_REACHED; /* NOTREACHED */
	    va_end(args);
	}
	NORETURN_FUNCTION_END;
}

static void
croak_status(const char *func, UA_StatusCode status, char *pat, ...)
{
	dTHX;
	va_list args;
	SV *sv;

	sv = sv_2mortal(newSV(126));

	if (pat == NULL) {
	    sv_setpvf(sv, "%s: %s", func, UA_StatusCode_name(status));
	    croak_sv(sv);
	} else {
	    sv_setpvf(sv, "%s: ", func);
	    va_start(args, pat);
	    sv_vcatpvf(sv, pat, &args);
	    sv_catpvf(sv, ": %s", UA_StatusCode_name(status));
	    croak_sv(sv);
	    NOT_REACHED; /* NOTREACHED */
	    va_end(args);
	}
	NORETURN_FUNCTION_END;
}

#define CROAK(pat, args...)	croak_func(__func__, pat, ##args)
#define CROAKE(pat, args...)	croak_errno(__func__, pat, ##args)
#define CROAKS(sc, pat, args...)	croak_status(__func__, sc, pat, ##args)

/* types.h */
typedef UA_UInt32 *		OPCUA_Open62541_UInt32;
typedef const UA_DataType *	OPCUA_Open62541_DataType;
typedef UA_NodeId *		OPCUA_Open62541_NodeId;
typedef UA_LocalizedText *	OPCUA_Open62541_LocalizedText;

/* types_generated.h */
typedef UA_Variant *		OPCUA_Open62541_Variant;

/* plugin/log.h */
typedef struct OPCUA_Open62541_Logger {
	UA_Logger *		lg_logger;
	SV *			lg_log;
	SV *			lg_context;
	SV *			lg_clear;
	SV *			lg_storage;
} * OPCUA_Open62541_Logger;

/* server.h */
typedef struct OPCUA_Open62541_ServerConfig {
	struct OPCUA_Open62541_Logger	svc_logger;
	UA_ServerConfig *	svc_serverconfig;
	SV *			svc_storage;
} * OPCUA_Open62541_ServerConfig;

typedef struct {
	struct OPCUA_Open62541_ServerConfig sv_config;
	UA_Server *		sv_server;
} * OPCUA_Open62541_Server;

/* client.h */
typedef struct ClientCallbackData {
	SV *			ccd_callback;
	SV *			ccd_client;
	SV *			ccd_data;
	struct ClientCallbackData **	ccd_callbackdataref;
} * ClientCallbackData;

typedef struct OPCUA_Open62541_ClientConfig {
	struct OPCUA_Open62541_Logger	clc_logger;
	UA_ClientConfig *	clc_clientconfig;
	SV *			clc_storage;
} * OPCUA_Open62541_ClientConfig;

typedef struct {
	struct OPCUA_Open62541_ClientConfig cl_config;
	UA_Client *		cl_client;
	ClientCallbackData	cl_callbackdata;
} * OPCUA_Open62541_Client;

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
		warn("Unsigned value %lu greater than UA_"		\
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
		sv_set_undef(out);
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
		sv_set_undef(out);
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
		CROAK("Not a HASH reference");
	}
	UA_NodeId_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetch(hv, "NodeId_namespaceIndex", 21, 0);
	if (svp == NULL)
		CROAK("No NodeId_namespaceIndex in HASH");
	out.namespaceIndex = XS_unpack_UA_UInt16(*svp);

	svp = hv_fetch(hv, "NodeId_identifierType", 21, 0);
	if (svp == NULL)
		CROAK("No NodeId_identifierType in HASH");
	type = SvIV(*svp);
	out.identifierType = type;

	svp = hv_fetch(hv, "NodeId_identifier", 17, 0);
	if (svp == NULL)
		CROAK("No NodeId_identifier in HASH");
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
		CROAK("NodeId_identifierType %li unknown", type);
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
		CROAK("NodeId_identifierType %d unknown",
		    (int)in.identifierType);
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
		CROAK("Not a HASH reference");
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
		CROAK("Not a HASH reference");
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
	hv_stores(hv, "QualifiedName_namespaceIndex", sv);

	sv = newSV(0);
	XS_pack_UA_String(sv, in.name);
	hv_stores(hv, "QualifiedName_name", sv);

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
		CROAK("Not a HASH reference");
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
OPCUA_Open62541_Variant_setScalar(OPCUA_Open62541_Variant variant, SV *in,
    OPCUA_Open62541_DataType type)
{
	void *scalar;
	UA_StatusCode status;

	if (unpack_UA_table[type->typeIndex] == NULL) {
		CROAK("No unpack conversion for type '%s' index %u",
		    type->typeName, type->typeIndex);
	}

	scalar = UA_new(type);
	if (scalar == NULL) {
		CROAKE("UA_new type '%s' index %u",
		    type->typeName, type->typeIndex);
	}
	(unpack_UA_table[type->typeIndex])(in, scalar);

	status = UA_Variant_setScalarCopy(variant, scalar, type);
	/* Free, not destroy.  The nested data structures belong to Perl. */
	UA_free(scalar);
	if (status != UA_STATUSCODE_GOOD) {
		CROAKS(status, "UA_Variant_setScalarCopy type '%s' index %u",
		    type->typeName, type->typeIndex);
	}
}

static void
OPCUA_Open62541_Variant_setArray(OPCUA_Open62541_Variant variant, SV *in,
    OPCUA_Open62541_DataType type)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	char *p;
	void *array;
	UA_StatusCode status;

	if (!SvOK(in)) {
		UA_Variant_setArray(variant, NULL, 0, type);
		return;
	}
	if (unpack_UA_table[type->typeIndex] == NULL) {
		CROAK("No pack conversion for type '%s' index %u",
		    type->typeName, type->typeIndex);
	}

	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVAV)
		CROAK("Not an ARRAY reference");
	av = (AV*)SvRV(in);
	top = av_len(av);
	array = UA_Array_new(top + 1, type);
	if (array == NULL)
		CROAKE("UA_Array_new size %zd, type '%s' index %u",
		    top + 1, type->typeName, type->typeIndex);
	p = array;
	for (i = 0; i <= top; i++) {
		svp = av_fetch(av, i, 0);
		if (svp != NULL) {
			(unpack_UA_table[type->typeIndex])(*svp, p);
		}
		p += type->memSize;
	}

	status = UA_Variant_setArrayCopy(variant, array, top + 1, type);
	/* Free, not destroy.  The nested data structures belong to Perl. */
	if (array != UA_EMPTY_ARRAY_SENTINEL)
		UA_free(array);
	if (status != UA_STATUSCODE_GOOD) {
		CROAKS(status,
		    "UA_Variant_setArrayCopy size %zd, type '%s' index %u",
		    top + 1, type->typeName, type->typeIndex);
	}
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
		CROAK("Not a HASH reference");
	}
	UA_Variant_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "Variant_type", 0);
	if (svp == NULL)
		CROAK("No Variant_type in HASH");
	type = XS_unpack_OPCUA_Open62541_DataType(*svp);

	scalar = hv_fetchs(hv, "Variant_scalar", 0);
	array = hv_fetchs(hv, "Variant_array", 0);
	if (scalar != NULL && array != NULL) {
		CROAK("Both Variant_scalar and Variant_array in HASH");
	}
	if (scalar == NULL && array == NULL) {
		CROAK("Neither Variant_scalar not Variant_array in HASH");
	}
	if (scalar != NULL) {
		OPCUA_Open62541_Variant_setScalar(&out, *scalar, type);
	}
	if (array != NULL) {
		OPCUA_Open62541_Variant_setArray(&out, *array, type);
	}
	return out;
}

static void
OPCUA_Open62541_Variant_getScalar(OPCUA_Open62541_Variant variant, SV *out)
{
	if (pack_UA_table[variant->type->typeIndex] == NULL) {
		/* XXX memory leak in caller */
		CROAK("No pack conversion for type '%s' index %u",
		    variant->type->typeName, variant->type->typeIndex);
	}
	(pack_UA_table[variant->type->typeIndex])(out, variant->data);
}

static void
OPCUA_Open62541_Variant_getArray(OPCUA_Open62541_Variant variant, SV *out)
{
	dTHX;
	SV *sv;
	AV *av;
	char *p;
	size_t i;

	if (variant->data == NULL) {
		sv_set_undef(out);
		return;
	}
	if (pack_UA_table[variant->type->typeIndex] == NULL) {
		/* XXX memory leak in caller */
		CROAK("No pack conversion for type '%s' index %u",
		    variant->type->typeName, variant->type->typeIndex);
	}

	av = newAV();
	av_extend(av, variant->arrayLength);
	p = variant->data;
	for (i = 0; i < variant->arrayLength; i++) {
		sv = newSV(0);
		(pack_UA_table[variant->type->typeIndex])(sv, p);
		av_push(av, sv);
		p += variant->type->memSize;
	}

	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)av)));
}

static void
XS_pack_UA_Variant(SV *out, UA_Variant in)
{
	dTHX;
	SV *sv;
	HV *hv;

	if (UA_Variant_isEmpty(&in)) {
		sv_set_undef(out);
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
		sv = newSV(0);
		OPCUA_Open62541_Variant_getArray(&in, sv);
		hv_stores(hv, "Variant_array", sv);
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
		CROAK("Not a HASH reference");
	}
	UA_ExtensionObject_init(&out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ExtensionObject_encoding", 0);
	if (svp == NULL)
		CROAK("No ExtensionObject_encoding in HASH");
	encoding = SvIV(*svp);
	out.encoding = encoding;

	svp = hv_fetchs(hv, "ExtensionObject_content", 0);
	if (svp == NULL)
		CROAK("No ExtensionObject_content in HASH");
	if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVHV)
		CROAK("ExtensionObject_content is not a HASH");
	content = (HV*)SvRV(*svp);

	switch (encoding) {
	case UA_EXTENSIONOBJECT_ENCODED_NOBODY:
	case UA_EXTENSIONOBJECT_ENCODED_BYTESTRING:
	case UA_EXTENSIONOBJECT_ENCODED_XML:
		svp = hv_fetchs(content, "ExtensionObject_content_typeId", 0);
		if (svp == NULL)
			CROAK("No ExtensionObject_content_typeId in HASH");
		out.content.encoded.typeId = XS_unpack_UA_NodeId(*svp);

		svp = hv_fetchs(content, "ExtensionObject_content_body", 0);
		if (svp == NULL)
			CROAK("No ExtensionObject_content_body in HASH");
		out.content.encoded.body = XS_unpack_UA_ByteString(*svp);

		break;
	case UA_EXTENSIONOBJECT_DECODED:
	case UA_EXTENSIONOBJECT_DECODED_NODELETE:
		svp = hv_fetchs(content, "ExtensionObject_content_type", 0);
		if (svp == NULL)
			CROAK("No ExtensionObject_content_type in HASH");
		type = XS_unpack_OPCUA_Open62541_DataType(*svp);
		if (unpack_UA_table[type->typeIndex] == NULL) {
			CROAK("No unpack conversion for type '%s' index %u",
			    type->typeName, type->typeIndex);
		}
		out.content.decoded.type = type;

		svp = hv_fetchs(content, "ExtensionObject_content_data", 0);
		if (svp == NULL)
			CROAK("No ExtensionObject_content_data in HASH");

		data = UA_new(type);
		if (data == NULL) {
			CROAK("UA_new type '%s' index %u",
			    type->typeName, type->typeIndex);
		}
		(unpack_UA_table[type->typeIndex])(*svp, data);

		break;
	default:
		CROAK("ExtensionObject_encoding %li unknown", encoding);
	}
	return out;
}

static void
XS_pack_UA_ExtensionObject(SV *out, UA_ExtensionObject in)
{
	dTHX;
	OPCUA_Open62541_DataType type;
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
		type = in.content.decoded.type;
		if (pack_UA_table[type->typeIndex] == NULL) {
			/* XXX memory leak in caller */
			CROAK("No pack conversion for type '%s' index %u",
			    type->typeName, type->typeIndex);
		}

		sv = newSV(0);
		XS_pack_OPCUA_Open62541_DataType(sv, type);
		hv_stores(hv, "ExtensionObject_content_type", sv);

		sv = newSV(0);
		(pack_UA_table[type->typeIndex])(sv, in.content.decoded.data);
		hv_stores(hv, "ExtensionObject_content_data", sv);

		break;
	default:
		CROAK("ExtensionObject_encoding %d unknown", (int)in.encoding);
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
		CROAK("Unsigned value %lu not below UA_TYPES_COUNT", index);
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
		CROAK("Not a HASH reference");
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
		CROAK("Not a HASH reference");
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

static ClientCallbackData
newClientCallbackData(SV *callback, SV *client, SV *data)
{
	dTHX;
	ClientCallbackData ccd;

	if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
		CROAK("Callback '%s' is not a CODE reference",
		    SvPV_nolen(callback));

	ccd = calloc(1, sizeof(*ccd));
	if (ccd == NULL)
		CROAKE("malloc");
	DPRINTF("ccd %p", ccd);

	/*
	 * XXX should we make a copy of the callback?
	 * see perlguts, Using call_sv, newSVsv()
	 */
	ccd->ccd_callback = callback;
	ccd->ccd_client = client;
	ccd->ccd_data = data;

	/*
	 * Client remembers a ref to callback data and destroys it when freed.
	 * So we must not increase the Perl refcount of the client.  Perl must
	 * free the client and then the callback data is destroyed.
	 * This API sucks.  Callbacks that may be called are hard to handle.
	 */
	SvREFCNT_inc(callback);
	SvREFCNT_inc(data);

	return ccd;
}

static void
deleteClientCallbackData(ClientCallbackData ccd)
{
	dTHX;
	DPRINTF("ccd %p, ccd_callbackdataref %p",
	    ccd, ccd->ccd_callbackdataref);

	SvREFCNT_dec(ccd->ccd_callback);
	SvREFCNT_dec(ccd->ccd_data);

	/* The callback data is freed now, do not remember to free it later. */
	if (ccd->ccd_callbackdataref != NULL)
		*ccd->ccd_callbackdataref = NULL;

	free(ccd);
}

static void
clientCallbackPerl(UA_Client *client, void *userdata, UA_UInt32 requestId,
    SV *response) {
	dTHX;
	dSP;
	ClientCallbackData ccd = userdata;

	DPRINTF("client %p, ccd %p", client, ccd);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	EXTEND(SP, 4);
	PUSHs(ccd->ccd_client);
	PUSHs(ccd->ccd_data);
	mPUSHu(requestId);
	mPUSHs(response);
	PUTBACK;

	call_sv(ccd->ccd_callback, G_VOID | G_DISCARD);

	FREETMPS;
	LEAVE;

	deleteClientCallbackData(ccd);
}

static void
clientAsyncServiceCallback(UA_Client *client, void *userdata,
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
clientAsyncBrowseCallback(UA_Client *client, void *userdata,
    UA_UInt32 requestId, UA_BrowseResponse *response)
{
	dTHX;
	SV *sv;

	sv = newSV(0);
	if (response != NULL)
		XS_pack_UA_BrowseResponse(sv, *response);

	clientCallbackPerl(client, userdata, requestId, sv);
}

static void
clientAsyncReadValueAttributeCallback(UA_Client *client, void *userdata,
    UA_UInt32 requestId, UA_Variant *var)
{
	dTHX;
	SV *sv;

	sv = newSV(0);
	if (var != NULL)
		XS_pack_UA_Variant(sv, *var);

	clientCallbackPerl(client, userdata, requestId, sv);
}

/* 16.4 Logging Plugin API, log and clear callbacks */

static void XS_pack_UA_LogLevel(SV *, UA_LogLevel) __attribute__((unused));
static UA_LogLevel XS_unpack_UA_LogLevel(SV *) __attribute__((unused));

static UA_LogLevel
XS_unpack_UA_LogLevel(SV *in)
{
	dTHX;
	return SvIV(in);
}

#define LOG_LEVEL_COUNT		6
const char *logLevelNames[LOG_LEVEL_COUNT] = {
	"trace",
	"debug",
	"info",
	"warn",
	"error",
	"fatal",
};

static void
XS_pack_UA_LogLevel(SV *out, UA_LogLevel in)
{
	dTHX;

	/* SV out contains number and string, like $! does. */
	sv_setnv(out, in);
	if (in >= 0 && in < LOG_LEVEL_COUNT)
		sv_setpv(out, logLevelNames[in]);
	else
		sv_setuv(out, in);
	SvNOK_on(out);
}

static void XS_pack_UA_LogCategory(SV *, UA_LogCategory)
	__attribute__((unused));
static UA_LogCategory XS_unpack_UA_LogCategory(SV *) __attribute__((unused));

static UA_LogCategory
XS_unpack_UA_LogCategory(SV *in)
{
	dTHX;
	return SvIV(in);
}

#define LOG_CATEGORY_COUNT	7
const char *logCategoryNames[LOG_CATEGORY_COUNT] = {
	"network",
	"channel",
	"session",
	"server",
	"client",
	"userland",
	"securitypolicy",
};

static void
XS_pack_UA_LogCategory(SV *out, UA_LogCategory in)
{
	dTHX;

	/* SV out contains number and string, like $! does. */
	sv_setnv(out, in);
	if (in >= 0 && in < LOG_CATEGORY_COUNT)
		sv_setpv(out, logCategoryNames[in]);
	else
		sv_setuv(out, in);
	SvNOK_on(out);
}

static void
loggerLogCallback(void *context, UA_LogLevel level, UA_LogCategory category,
    const char *msg, va_list args)
{
	dTHX;
	dSP;
	OPCUA_Open62541_Logger	logger = context;
	SV *			levelName;
	SV *			categoryName;
	SV *			message;
	va_list			vp;

	if (!SvOK(logger->lg_log))
		return;

	ENTER;
	SAVETMPS;

	levelName = newSV(5);
	XS_pack_UA_LogLevel(levelName, level);
	categoryName = newSV(14);
	XS_pack_UA_LogCategory(categoryName, category);
	/* Perl expects a pointer to va_list, so we have to copy it. */
	va_copy(vp, args);
	message = newSV(0);
	sv_vsetpvf(message, msg, &vp);
	va_end(vp);

	PUSHMARK(SP);
	EXTEND(SP, 4);
	PUSHs(logger->lg_context);
	mPUSHs(levelName);
	mPUSHs(categoryName);
	mPUSHs(message);
	PUTBACK;

	call_sv(logger->lg_log, G_VOID | G_DISCARD);

	FREETMPS;
	LEAVE;
}

static void
loggerClearCallback(void *context)
{
	dTHX;
	dSP;
	OPCUA_Open62541_Logger	logger = context;

	if (!SvOK(logger->lg_clear))
		return;

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	EXTEND(SP, 1);
	PUSHs(logger->lg_context);
	PUTBACK;

	call_sv(logger->lg_clear, G_VOID | G_DISCARD);

	FREETMPS;
	LEAVE;
}

/*#########################################################################*/
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541

PROTOTYPES: DISABLE

# just for testing

void
test_croak(sv)
	SV *			sv
    CODE:
	if (SvOK(sv)) {
		CROAK("%s", SvPV_nolen(sv));
	} else {
		CROAK(NULL);
	}

void
test_croake(sv, errnum)
	SV *			sv
	int			errnum
    CODE:
	errno = errnum;
	if (SvOK(sv)) {
		CROAKE("%s", SvPV_nolen(sv));
	} else {
		CROAKE(NULL);
	}

void
test_croaks(sv, status)
	SV *			sv
	UA_StatusCode		status
    CODE:
	if (SvOK(sv)) {
		CROAKS(status, "%s", SvPV_nolen(sv));
	} else {
		CROAKS(status, NULL);
	}

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

INCLUDE: Open62541-types.xsh

# 6.1.12 StatusCode, statuscodes.c, unknown just for testing

UA_StatusCode
STATUSCODE_UNKNOWN()
    CODE:
	RETVAL = 0xffffffff;
    OUTPUT:
	RETVAL

INCLUDE: Open62541-statuscode.xsh

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
		CROAK("Class '%s' is not OPCUA::Open62541::LocalizedText",
		    class);
    CODE:
	RETVAL = UA_LocalizedText_new();
	if (RETVAL == NULL)
		CROAKE("UA_LocalizedText_new");
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
		CROAK("Class '%s' is not OPCUA::Open62541::Variant", class);
    CODE:
	RETVAL = UA_Variant_new();
	if (RETVAL == NULL)
		CROAKE("UA_Variant_new");
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

void
UA_Variant_setArray(variant, sv, type)
	OPCUA_Open62541_Variant		variant
	SV *				sv
	OPCUA_Open62541_DataType	type
    CODE:
	OPCUA_Open62541_Variant_setArray(variant, sv, type);

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

SV *
UA_Variant_getArray(variant)
	OPCUA_Open62541_Variant		variant
    CODE:
	if (UA_Variant_isEmpty(variant))
		XSRETURN_UNDEF;
	if (UA_Variant_isScalar(variant))
		XSRETURN_UNDEF;
	RETVAL = newSV(0);
	OPCUA_Open62541_Variant_getArray(variant, RETVAL);
    OUTPUT:
	RETVAL

#############################################################################
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::Server		PREFIX = UA_Server_

# 11.2 Server Lifecycle

OPCUA_Open62541_Server
UA_Server_new(class)
	char *				class
    INIT:
	if (strcmp(class, "OPCUA::Open62541::Server") != 0)
		CROAK("Class '%s' is not OPCUA::Open62541::Server", class);
    CODE:
	RETVAL = calloc(1, sizeof(*RETVAL));
	if (RETVAL == NULL)
		CROAKE("calloc");
	RETVAL->sv_server = UA_Server_new();
	if (RETVAL->sv_server == NULL) {
		free(RETVAL);
		CROAKE("UA_Server_new");
	}
	DPRINTF("class %s, server %p, sv_server %p",
	    class, RETVAL, RETVAL->sv_server);
    OUTPUT:
	RETVAL

OPCUA_Open62541_Server
UA_Server_newWithConfig(class, config)
	char *				class
	OPCUA_Open62541_ServerConfig	config
    INIT:
	if (strcmp(class, "OPCUA::Open62541::Server") != 0)
		CROAK("Class '%s' is not OPCUA::Open62541::Server", class);
    CODE:
	RETVAL = calloc(1, sizeof(*RETVAL));
	if (RETVAL == NULL)
		CROAKE("calloc");
	RETVAL->sv_server = UA_Server_newWithConfig(config->svc_serverconfig);
	if (RETVAL->sv_server == NULL)
		CROAKE("UA_Server_newWithConfig");
	DPRINTF("class %s, config %p, svc_serverconfig %p, "
	    "server %p, sv_server %p",
	    class, config, config->svc_serverconfig,
	    RETVAL, RETVAL->sv_server);
    OUTPUT:
	RETVAL

void
UA_Server_DESTROY(server)
	OPCUA_Open62541_Server		server
    PREINIT:
	OPCUA_Open62541_Logger		logger;
    CODE:
	logger =  &server->sv_config.svc_logger;
	DPRINTF("server %p, sv_server %p, logger %p",
	    server, server->sv_server, logger);
	UA_Server_delete(server->sv_server);
	/* SvREFCNT_dec checks for NULL pointer. */
	SvREFCNT_dec(logger->lg_log);
	SvREFCNT_dec(logger->lg_context);
	SvREFCNT_dec(logger->lg_clear);

OPCUA_Open62541_ServerConfig
UA_Server_getConfig(server)
	OPCUA_Open62541_Server		server
    CODE:
	RETVAL = &server->sv_config;
	RETVAL->svc_serverconfig = UA_Server_getConfig(server->sv_server);
	DPRINTF("server %p, sv_server %p, config %p, svc_serverconfig %p",
	    server, server->sv_server, RETVAL, RETVAL->svc_serverconfig);
	if (RETVAL->svc_serverconfig == NULL)
		XSRETURN_UNDEF;
	/* When server goes out of scope, config still uses its memory. */
	RETVAL->svc_storage = SvREFCNT_inc(SvRV(ST(0)));
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_run(server, running)
	OPCUA_Open62541_Server		server
	UA_Boolean			&running
    PREINIT:
#ifdef DEBUG
	MAGIC *mg;
#endif
    CODE:
	/* If running is changed, the magic callback will report to server. */
#ifdef DEBUG
	mg =
#endif
	sv_magicext(ST(1), NULL, PERL_MAGIC_ext, &server_run_mgvtbl,
	    (void *)&running, 0);
	DPRINTF("server %p, sv_server %p, &running %p, mg %p",
	    server, server->sv_server, &running, mg);
	RETVAL = UA_Server_run(server->sv_server, &running);
	sv_unmagicext(ST(1), PERL_MAGIC_ext, &server_run_mgvtbl);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_run_startup(server)
	OPCUA_Open62541_Server		server
    CODE:
	RETVAL = UA_Server_run_startup(server->sv_server);
    OUTPUT:
	RETVAL

UA_UInt16
UA_Server_run_iterate(server, waitInternal)
	OPCUA_Open62541_Server		server
	UA_Boolean			waitInternal
    CODE:
	RETVAL = UA_Server_run_iterate(server->sv_server, waitInternal);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_run_shutdown(server)
	OPCUA_Open62541_Server		server
    CODE:
	RETVAL = UA_Server_run_shutdown(server->sv_server);
    OUTPUT:
	RETVAL


# 11.4 Reading and Writing Node Attributes

UA_StatusCode
UA_Server_readValue(server, nodeId, outValue)
	OPCUA_Open62541_Server		server
	UA_NodeId			nodeId
	OPCUA_Open62541_Variant		outValue
    INIT:
	if (!SvOK(ST(2)) || !(SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) < SVt_PVAV))
		CROAK("outValue is not a scalar reference");
    CODE:
	RETVAL = UA_Server_readValue(server->sv_server, nodeId, outValue);
	if (outValue != NULL)
		XS_pack_UA_Variant(SvRV(ST(2)), *outValue);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_writeValue(server, nodeId, value)
	OPCUA_Open62541_Server		server
	UA_NodeId			nodeId
	UA_Variant			value
    CODE:
	RETVAL = UA_Server_writeValue(server->sv_server, nodeId, value);
    OUTPUT:
	RETVAL

# 11.5 Browsing

UA_BrowseResult
UA_Server_browse(server, maxReferences, bd)
	OPCUA_Open62541_Server		server
	UA_UInt32			maxReferences
	UA_BrowseDescription		bd
    CODE:
	RETVAL = UA_Server_browse(server->sv_server, maxReferences, &bd);
    OUTPUT:
	RETVAL

# 11.9 Node Addition and Deletion

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
    CODE:
	RETVAL = UA_Server_addVariableNode(server->sv_server,
	    requestedNewNodeId, parentNodeId, referenceTypeId, browseName,
	    typeDefinition, attr, nodeContext, outNewNodeId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_addVariableTypeNode(server, requestedNewNodeId, parentNodeId, referenceTypeId, browseName, typeDefinition, attr, nodeContext, outNewNodeId)
	OPCUA_Open62541_Server		server
	UA_NodeId			requestedNewNodeId
	UA_NodeId			parentNodeId
	UA_NodeId			referenceTypeId
	UA_QualifiedName		browseName
	UA_NodeId			typeDefinition
	UA_VariableTypeAttributes	attr
	void *				nodeContext
	OPCUA_Open62541_NodeId		outNewNodeId
    CODE:
	RETVAL = UA_Server_addVariableTypeNode(server->sv_server,
	    requestedNewNodeId, parentNodeId, referenceTypeId, browseName,
	    typeDefinition, attr, nodeContext, outNewNodeId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_addObjectNode(server, requestedNewNodeId, parentNodeId, referenceTypeId, browseName, typeDefinition, attr, nodeContext, outNewNodeId)
	OPCUA_Open62541_Server		server
	UA_NodeId			requestedNewNodeId
	UA_NodeId			parentNodeId
	UA_NodeId			referenceTypeId
	UA_QualifiedName		browseName
	UA_NodeId			typeDefinition
	UA_ObjectAttributes		attr
	void *				nodeContext
	OPCUA_Open62541_NodeId		outNewNodeId
    CODE:
	RETVAL = UA_Server_addObjectNode(server->sv_server,
	    requestedNewNodeId, parentNodeId, referenceTypeId, browseName,
	    typeDefinition, attr, nodeContext, outNewNodeId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_addObjectTypeNode(server, requestedNewNodeId, parentNodeId, referenceTypeId, browseName, attr, nodeContext, outNewNodeId)
	OPCUA_Open62541_Server		server
	UA_NodeId			requestedNewNodeId
	UA_NodeId			parentNodeId
	UA_NodeId			referenceTypeId
	UA_QualifiedName		browseName
	UA_ObjectTypeAttributes		attr
	void *				nodeContext
	OPCUA_Open62541_NodeId		outNewNodeId
    CODE:
	RETVAL = UA_Server_addObjectTypeNode(server->sv_server,
	    requestedNewNodeId, parentNodeId, referenceTypeId, browseName,
	    attr, nodeContext, outNewNodeId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_addViewNode(server, requestedNewNodeId, parentNodeId, referenceTypeId, browseName, attr, nodeContext, outNewNodeId)
	OPCUA_Open62541_Server		server
	UA_NodeId			requestedNewNodeId
	UA_NodeId			parentNodeId
	UA_NodeId			referenceTypeId
	UA_QualifiedName		browseName
	UA_ViewAttributes		attr
	void *				nodeContext
	OPCUA_Open62541_NodeId		outNewNodeId
    CODE:
	RETVAL = UA_Server_addViewNode(server->sv_server,
	    requestedNewNodeId, parentNodeId, referenceTypeId, browseName,
	    attr, nodeContext, outNewNodeId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_addReferenceTypeNode(server, requestedNewNodeId, parentNodeId, referenceTypeId, browseName, attr, nodeContext, outNewNodeId)
	OPCUA_Open62541_Server		server
	UA_NodeId			requestedNewNodeId
	UA_NodeId			parentNodeId
	UA_NodeId			referenceTypeId
	UA_QualifiedName		browseName
	UA_ReferenceTypeAttributes	attr
	void *				nodeContext
	OPCUA_Open62541_NodeId		outNewNodeId
    CODE:
	RETVAL = UA_Server_addReferenceTypeNode(server->sv_server,
	    requestedNewNodeId, parentNodeId, referenceTypeId, browseName,
	    attr, nodeContext, outNewNodeId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_addDataTypeNode(server, requestedNewNodeId, parentNodeId, referenceTypeId, browseName, attr, nodeContext, outNewNodeId)
	OPCUA_Open62541_Server		server
	UA_NodeId			requestedNewNodeId
	UA_NodeId			parentNodeId
	UA_NodeId			referenceTypeId
	UA_QualifiedName		browseName
	UA_DataTypeAttributes		attr
	void *				nodeContext
	OPCUA_Open62541_NodeId		outNewNodeId
    CODE:
	RETVAL = UA_Server_addDataTypeNode(server->sv_server,
	    requestedNewNodeId, parentNodeId, referenceTypeId, browseName,
	    attr, nodeContext, outNewNodeId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_deleteNode(server, nodeId, deleteReferences)
	OPCUA_Open62541_Server		server
	UA_NodeId			nodeId
	UA_Boolean			deleteReferences
    CODE:
	RETVAL = UA_Server_deleteNode(server->sv_server, nodeId,
	    deleteReferences);
    OUTPUT:
	RETVAL

# 11.10 Reference Management

UA_StatusCode
UA_Server_addReference(server, sourceId, refTypeId, targetId, isForward)
	OPCUA_Open62541_Server		server
	UA_NodeId			sourceId
	UA_NodeId			refTypeId
	UA_ExpandedNodeId		targetId
	UA_Boolean			isForward
    CODE:
	RETVAL = UA_Server_addReference(server->sv_server, sourceId, refTypeId,
	    targetId, isForward);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_deleteReference(server, sourceNodeId, referenceTypeId, isForward, targetNodeId, deleteBidirectional)
	OPCUA_Open62541_Server		server
	UA_NodeId			sourceNodeId
	UA_NodeId			referenceTypeId
	UA_Boolean			isForward
	UA_ExpandedNodeId		targetNodeId
	UA_Boolean			deleteBidirectional
    CODE:
	RETVAL = UA_Server_deleteReference(server->sv_server, sourceNodeId,
	    referenceTypeId, isForward, targetNodeId, deleteBidirectional);
    OUTPUT:
	RETVAL

# Namespace Handling

UA_UInt16
UA_Server_addNamespace(server, name)
	OPCUA_Open62541_Server		server
	const char *			name
    CODE:
	RETVAL = UA_Server_addNamespace(server->sv_server, name);
    OUTPUT:
	RETVAL

#############################################################################
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::ServerConfig	PREFIX = UA_ServerConfig_

void
UA_ServerConfig_DESTROY(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	DPRINTF("config %p, svc_serverconfig %p, svc_storage %p",
	    config, config->svc_serverconfig, config->svc_storage);
	/* Delayed server destroy after server config destroy. */
	SvREFCNT_dec(config->svc_storage);

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
	RETVAL = UA_ServerConfig_setMinimal(config->svc_serverconfig,
	    portNumber, &certificate);
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setCustomHostname(config, customHostname)
	OPCUA_Open62541_ServerConfig	config
	UA_String			customHostname
    CODE:
	UA_ServerConfig_setCustomHostname(config->svc_serverconfig,
	    customHostname);

OPCUA_Open62541_Logger
UA_ServerConfig_getLogger(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	RETVAL = &config->svc_logger;
	RETVAL->lg_logger = &config->svc_serverconfig->logger;
	/* When config goes out of scope, logger still uses server memory. */
	RETVAL->lg_storage = SvREFCNT_inc(config->svc_storage);
	DPRINTF("config %p, svc_serverconfig %p, logger %p, lg_logger %p, "
	    "lg_storage %p",
	    config, config->svc_serverconfig, RETVAL, RETVAL->lg_logger,
	    RETVAL->lg_storage);
    OUTPUT:
	RETVAL

UA_BuildInfo
UA_ServerConfig_getBuildInfo(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	RETVAL = config->svc_serverconfig->buildInfo;
    OUTPUT:
	RETVAL

#############################################################################
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::Client		PREFIX = UA_Client_

# 12.2 Client Lifecycle

OPCUA_Open62541_Client
UA_Client_new(class)
	char *				class
    INIT:
	if (strcmp(class, "OPCUA::Open62541::Client") != 0)
		CROAK("Class '%s' is not OPCUA::Open62541::Client", class);
    CODE:
	RETVAL = calloc(1, sizeof(*RETVAL));
	if (RETVAL == NULL)
		CROAKE("calloc");
	RETVAL->cl_client = UA_Client_new();
	if (RETVAL->cl_client == NULL) {
		free(RETVAL);
		CROAKE("UA_Client_new");
	}
	DPRINTF("class %s, client %p, cl_client %p",
	    class, RETVAL, RETVAL->cl_client);
    OUTPUT:
	RETVAL

void
UA_Client_DESTROY(client)
	OPCUA_Open62541_Client		client
    PREINIT:
	OPCUA_Open62541_Logger		logger;
    CODE:
	logger = &client->cl_config.clc_logger;
	DPRINTF("client %p, cl_client %p, cl_callbackdata %p, logger %p",
	    client, client->cl_client, client->cl_callbackdata, logger);
	UA_Client_delete(client->cl_client);
	/* SvREFCNT_dec checks for NULL pointer. */
	SvREFCNT_dec(logger->lg_log);
	SvREFCNT_dec(logger->lg_context);
	SvREFCNT_dec(logger->lg_clear);
	/* The client may still have an uncalled connect callback. */
	if (client->cl_callbackdata != NULL)
		deleteClientCallbackData(client->cl_callbackdata);
	free(client);

OPCUA_Open62541_ClientConfig
UA_Client_getConfig(client)
	OPCUA_Open62541_Client		client
    CODE:
	RETVAL = &client->cl_config;
	RETVAL->clc_clientconfig = UA_Client_getConfig(client->cl_client);
	DPRINTF("client %p, cl_client %p, config %p, clc_clientconfig %p",
	    client, client->cl_client, RETVAL, RETVAL->clc_clientconfig);
	if (RETVAL->clc_clientconfig == NULL)
		XSRETURN_UNDEF;
	/* When client goes out of scope, config still uses its memory. */
	RETVAL->clc_storage = SvREFCNT_inc(SvRV(ST(0)));
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_connect(client, endpointUrl)
	OPCUA_Open62541_Client		client
	char *				endpointUrl
    CODE:
	RETVAL = UA_Client_connect(client->cl_client, endpointUrl);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_connect_async(client, endpointUrl, callback, data)
	OPCUA_Open62541_Client		client
	char *				endpointUrl
	SV *				callback
	SV *				data
    CODE:
	/*
	 * If the client is already connecting, it will immediately return
	 * a good status code.  In this case, the callback is never called.
	 * We must not allocate its data structure to avoid a memory leak.
	 * The socket API is smarter in this case, connect(2) fails with
	 * EINPROGRESS which can be detected by the caller.
	 */
	if (UA_Client_getState(client->cl_client) >=
	    UA_CLIENTSTATE_WAITING_FOR_ACK || !SvOK(callback)) {
		/* ignore callback and data if no callback is defined */
		RETVAL = UA_Client_connect_async(client->cl_client,
		    endpointUrl, NULL, NULL);
	} else {
		ClientCallbackData ccd;

		ccd = newClientCallbackData(callback, ST(0), data);
		RETVAL = UA_Client_connect_async(client->cl_client,
		    endpointUrl, clientAsyncServiceCallback, ccd);
		if (RETVAL == UA_STATUSCODE_GOOD) {
			if (client->cl_callbackdata != NULL)
				deleteClientCallbackData(
				    client->cl_callbackdata);
			/* Pointer to free ccd if callback is not called. */
			client->cl_callbackdata = ccd;
			ccd->ccd_callbackdataref = &client->cl_callbackdata;
		} else {
			deleteClientCallbackData(ccd);
		}
	}
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_run_iterate(client, timeout)
	OPCUA_Open62541_Client		client
	UA_UInt16			timeout
    CODE:
	RETVAL = UA_Client_run_iterate(client->cl_client, timeout);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_disconnect(client)
	OPCUA_Open62541_Client		client
    CODE:
	RETVAL = UA_Client_disconnect(client->cl_client);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_disconnect_async(client, requestId)
	OPCUA_Open62541_Client		client
	OPCUA_Open62541_UInt32		requestId
    INIT:
	if (SvOK(ST(1)) && !(SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) < SVt_PVAV))
		CROAK("requestId is not a scalar reference");
    CODE:
	RETVAL = UA_Client_disconnect_async(client->cl_client, requestId);
	if (requestId != NULL)
		XS_pack_UA_UInt32(SvRV(ST(1)), *requestId);
    OUTPUT:
	RETVAL

UA_ClientState
UA_Client_getState(client)
	OPCUA_Open62541_Client		client
    CODE:
	RETVAL = UA_Client_getState(client->cl_client);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_sendAsyncBrowseRequest(client, request, callback, data, reqId)
	OPCUA_Open62541_Client		client
	UA_BrowseRequest		request
	SV *				callback
	SV *				data
	OPCUA_Open62541_UInt32		reqId
    PREINIT:
	ClientCallbackData		ccd;
    INIT:
	if (SvOK(ST(4)) && !(SvROK(ST(4)) && SvTYPE(SvRV(ST(4))) < SVt_PVAV))
		CROAK("reqId is not a scalar reference");
    CODE:
	ccd = newClientCallbackData(callback, ST(0), data);
	RETVAL = UA_Client_sendAsyncBrowseRequest(client->cl_client, &request,
	    clientAsyncBrowseCallback, ccd, reqId);
	if (RETVAL != UA_STATUSCODE_GOOD)
		deleteClientCallbackData(ccd);
	if (reqId != NULL)
		XS_pack_UA_UInt32(SvRV(ST(4)), *reqId);
    OUTPUT:
	RETVAL

UA_BrowseResponse
UA_Client_Service_browse(client, request)
	OPCUA_Open62541_Client		client
	UA_BrowseRequest		request
    CODE:
	RETVAL = UA_Client_Service_browse(client->cl_client, request);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_readValueAttribute_async(client, nodeId, callback, data, reqId)
	OPCUA_Open62541_Client		client
	UA_NodeId			nodeId
	SV *				callback
	SV *				data
	OPCUA_Open62541_UInt32		reqId
    PREINIT:
	ClientCallbackData		ccd;
    INIT:
	if (SvOK(ST(4)) && !(SvROK(ST(4)) && SvTYPE(SvRV(ST(4))) < SVt_PVAV))
		CROAK("reqId is not a scalar reference");
    CODE:
	ccd = newClientCallbackData(callback, ST(0), data);
	RETVAL = UA_Client_readValueAttribute_async(client->cl_client, nodeId,
	    clientAsyncReadValueAttributeCallback, ccd, reqId);
	if (RETVAL != UA_STATUSCODE_GOOD)
		deleteClientCallbackData(ccd);
	if (reqId != NULL)
		XS_pack_UA_UInt32(SvRV(ST(4)), *reqId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_readDisplayNameAttribute(client, nodeId, outDisplayName)
	OPCUA_Open62541_Client		client
	UA_NodeId			nodeId
	OPCUA_Open62541_LocalizedText	outDisplayName
    INIT:
	if (!SvOK(ST(2)) || !(SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) < SVt_PVAV))
		CROAK("outDisplayName is not a scalar reference");
    CODE:
	RETVAL = UA_Client_readDisplayNameAttribute(client->cl_client, nodeId,
	    outDisplayName);
	if (outDisplayName != NULL)
		XS_pack_UA_LocalizedText(SvRV(ST(2)), *outDisplayName);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_readDescriptionAttribute(client, nodeId, outDescription)
	OPCUA_Open62541_Client		client
	UA_NodeId			nodeId
	OPCUA_Open62541_LocalizedText	outDescription
    INIT:
	if (!SvOK(ST(2)) || !(SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) < SVt_PVAV))
		CROAK("outDescription is not a scalar reference");
    CODE:
	RETVAL = UA_Client_readDescriptionAttribute(client->cl_client, nodeId,
	    outDescription);
	if (outDescription != NULL)
		XS_pack_UA_LocalizedText(SvRV(ST(2)), *outDescription);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_readValueAttribute(client, nodeId, outValue)
	OPCUA_Open62541_Client		client
	UA_NodeId			nodeId
	OPCUA_Open62541_Variant		outValue
    INIT:
	if (!SvOK(ST(2)) || !(SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) < SVt_PVAV))
		CROAK("outValue is not a scalar reference");
    CODE:
	RETVAL = UA_Client_readValueAttribute(client->cl_client, nodeId,
	    outValue);
	if (outValue != NULL)
		XS_pack_UA_Variant(SvRV(ST(2)), *outValue);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_readDataTypeAttribute(client, nodeId, outDataType)
	OPCUA_Open62541_Client		client
	UA_NodeId			nodeId
	SV *				outDataType
    PREINIT:
	UA_NodeId			outNodeId;
	UV				index;
    INIT:
	if (!SvOK(ST(2)) || !(SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) < SVt_PVAV))
		CROAK("outDataType is not a scalar reference");
    CODE:
	RETVAL = UA_Client_readDataTypeAttribute(client->cl_client, nodeId,
	    &outNodeId);
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
	DPRINTF("config %p, clc_clientconfig %p, clc_storage %p",
	    config, config->clc_clientconfig, config->clc_storage);
	/* Delayed client destroy after client config destroy. */
	SvREFCNT_dec(config->clc_storage);

UA_StatusCode
UA_ClientConfig_setDefault(config)
	OPCUA_Open62541_ClientConfig	config
    CODE:
	RETVAL = UA_ClientConfig_setDefault(config->clc_clientconfig);
    OUTPUT:
	RETVAL

OPCUA_Open62541_Logger
UA_ClientConfig_getLogger(config)
	OPCUA_Open62541_ClientConfig	config
    CODE:
	RETVAL = &config->clc_logger;
	RETVAL->lg_logger = &config->clc_clientconfig->logger;
	/* When config goes out of scope, logger still uses client memory. */
	RETVAL->lg_storage = SvREFCNT_inc(config->clc_storage);
	DPRINTF("config %p, clc_clientconfig %p, logger %p, lg_logger %p, "
	    "lg_storage %p",
	    config, config->clc_clientconfig, RETVAL, RETVAL->lg_logger,
	    RETVAL->lg_storage);
    OUTPUT:
	RETVAL

#############################################################################
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::Logger	PREFIX = UA_Logger_

# 16.4 Logging Plugin API, plugin/log.h

void
UA_Logger_DESTROY(logger)
	OPCUA_Open62541_Logger		logger
    CODE:
	DPRINTF("logger %p, lg_logger %p, lg_storage %p, context %p",
	    logger, logger->lg_logger, logger->lg_storage,
	    logger->lg_logger->context);
	/* Delayed server or client destroy after logger destroy. */
	SvREFCNT_dec(logger->lg_storage);

void
UA_Logger_setCallback(logger, log, context, clear)
	OPCUA_Open62541_Logger		logger
	SV *				log
	SV *				context
	SV *				clear
    INIT:
	if (SvOK(log) && !(SvROK(log) && SvTYPE(SvRV(log)) == SVt_PVCV))
		CROAK("Log '%s' is not a CODE reference",
		    SvPV_nolen(log));
	if (SvOK(clear) && !(SvROK(clear) && SvTYPE(SvRV(clear)) == SVt_PVCV))
		CROAK("Clear '%s' is not a CODE reference",
		    SvPV_nolen(clear));
    CODE:
	logger->lg_logger->context = logger;
	logger->lg_logger->log = SvOK(log) ? loggerLogCallback : NULL;
	logger->lg_logger->clear = SvOK(clear) ? loggerClearCallback : NULL;
	if (logger->lg_log == NULL)
		logger->lg_log = newSV(0);
	SvSetSV_nosteal(logger->lg_log, log);
	if (logger->lg_context == NULL)
		logger->lg_context = newSV(0);
	SvSetSV_nosteal(logger->lg_context, context);
	if (logger->lg_clear == NULL)
		logger->lg_clear = newSV(0);
	SvSetSV_nosteal(logger->lg_clear, clear);
	DPRINTF("logger %p, lg_logger %p, lg_storage %p, context %p",
	    logger, logger->lg_logger, logger->lg_storage,
	    logger->lg_logger->context);

void
UA_Logger_logTrace(logger, category, msg, ...)
	OPCUA_Open62541_Logger		logger
	UA_LogCategory			category
	SV *				msg
    PREINIT:
	SV *				message;
    CODE:
	message = sv_newmortal();
	sv_vsetpvfn(message, SvPV_nolen(msg), SvCUR(msg), NULL,
	    &ST(3), items - 3, NULL);
	UA_LOG_TRACE(logger->lg_logger, category, "%s", SvPV_nolen(message));

void
UA_Logger_logDebug(logger, category, msg, ...)
	OPCUA_Open62541_Logger		logger
	UA_LogCategory			category
	SV *				msg
    PREINIT:
	SV *				message;
    CODE:
	message = sv_newmortal();
	sv_vsetpvfn(message, SvPV_nolen(msg), SvCUR(msg), NULL,
	    &ST(3), items - 3, NULL);
	UA_LOG_DEBUG(logger->lg_logger, category, "%s", SvPV_nolen(message));

void
UA_Logger_logInfo(logger, category, msg, ...)
	OPCUA_Open62541_Logger		logger
	UA_LogCategory			category
	SV *				msg
    PREINIT:
	SV *				message;
    CODE:
	message = sv_newmortal();
	sv_vsetpvfn(message, SvPV_nolen(msg), SvCUR(msg), NULL,
	    &ST(3), items - 3, NULL);
	UA_LOG_INFO(logger->lg_logger, category, "%s", SvPV_nolen(message));

void
UA_Logger_logWarning(logger, category, msg, ...)
	OPCUA_Open62541_Logger		logger
	UA_LogCategory			category
	SV *				msg
    PREINIT:
	SV *				message;
    CODE:
	message = sv_newmortal();
	sv_vsetpvfn(message, SvPV_nolen(msg), SvCUR(msg), NULL,
	    &ST(3), items - 3, NULL);
	UA_LOG_WARNING(logger->lg_logger, category, "%s", SvPV_nolen(message));

void
UA_Logger_logError(logger, category, msg, ...)
	OPCUA_Open62541_Logger		logger
	UA_LogCategory			category
	SV *				msg
    PREINIT:
	SV *				message;
    CODE:
	message = sv_newmortal();
	sv_vsetpvfn(message, SvPV_nolen(msg), SvCUR(msg), NULL,
	    &ST(3), items - 3, NULL);
	UA_LOG_ERROR(logger->lg_logger, category, "%s", SvPV_nolen(message));

void
UA_Logger_logFatal(logger, category, msg, ...)
	OPCUA_Open62541_Logger		logger
	UA_LogCategory			category
	SV *				msg
    PREINIT:
	SV *				message;
    CODE:
	message = sv_newmortal();
	sv_vsetpvfn(message, SvPV_nolen(msg), SvCUR(msg), NULL,
	    &ST(3), items - 3, NULL);
	UA_LOG_FATAL(logger->lg_logger, category, "%s", SvPV_nolen(message));
