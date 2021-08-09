/*
 * Copyright (c) 2020-2021 Alexander Bluhm
 * Copyright (c) 2020-2021 Anton Borowka
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
#include <open62541/client_subscriptions.h>

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
typedef const UA_DataType *	OPCUA_Open62541_DataType;

#include "Open62541-typedef.xsh"

/* plugin/log.h */
typedef struct OPCUA_Open62541_Logger {
	UA_Logger *		lg_logger;
	SV *			lg_log;
	SV *			lg_context;
	SV *			lg_clear;
	SV *			lg_storage;
} * OPCUA_Open62541_Logger;

/* server.h */

typedef struct OPCUA_Open62541_GlobalNodeLifecycle {
	SV *			gnl_constructor;
	SV *			gnl_destructor;
	SV *			gnl_createOptionalChild;
	SV *			gnl_generateChildNodeId;
} OPCUA_Open62541_GlobalNodeLifecycle;

typedef struct OPCUA_Open62541_ServerConfig {
	struct OPCUA_Open62541_Logger	svc_logger;
	struct OPCUA_Open62541_GlobalNodeLifecycle	svc_lifecycle;
	UA_ServerConfig *	svc_serverconfig;
	SV *			svc_storage;
} * OPCUA_Open62541_ServerConfig;

typedef struct {
	struct OPCUA_Open62541_ServerConfig sv_config;
	UA_Server *		sv_server;
	SV *			sv_lifecycle_server;
	SV *			sv_lifecycle_context;
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
	SV *			clc_clientcontext;
	SV *			clc_statecallback;
	SV *			clc_storage;
} * OPCUA_Open62541_ClientConfig;

typedef struct {
	struct OPCUA_Open62541_ClientConfig cl_config;
	UA_Client *		cl_client;
	ClientCallbackData	cl_callbackdata;
} * OPCUA_Open62541_Client;

typedef struct {
	SV *			sc_context;
	ClientCallbackData	sc_change;
	ClientCallbackData	sc_delete;
} * SubscriptionContext;

typedef struct {
	ClientCallbackData	mc_change;
	ClientCallbackData	mc_delete;
} * MonitoredItemContext;

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
		CROAK("Integer value %li less than UA_"			\
		    #limit "_MIN", out);				\
	if (out > UA_##limit##_MAX)					\
		CROAK("Integer value %li greater than UA_"		\
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
		CROAK("Unsigned value %lu greater than UA_"		\
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
		CROAK("Float value %le less than %le", out, -FLT_MAX);
	if (out > FLT_MAX)
		CROAK("Float value %le greater than %le", out, FLT_MAX);
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
	char *str;
	UA_String out;

	if (!SvOK(in)) {
		UA_String_init(&out);
		return out;
	}

	str = SvPVutf8(in, out.length);
	if (out.length > 0) {
		out.data = UA_malloc(out.length);
		if (out.data == NULL)
			CROAKE("UA_malloc");
		memcpy(out.data, str, out.length);
	} else {
		out.data = UA_EMPTY_ARRAY_SENTINEL;
	}
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
	char *str, *end, num[9];
	size_t len, i, j;
	unsigned long data;
	int save_errno;

	/*
	 * Parse the Guid format defined in Part 6, 5.1.3.
	 * Format: C496578A-0DFE-4B8F-870A-745238C6AEAE
	 */
	str = SvPV(in, len);
	if (len != 36)
		CROAK("Guid string length %zu is not 36", len);
	for (i = 0; i < len; i++) {
		switch (i) {
		case 8:
		case 13:
		case 18:
		case 23:
			if (str[i] != '-')
				CROAK("Guid string character '%c' at %zu "
				    "is not - separator", str[i], i);
			break;
		default:
			if (!isxdigit(str[i]))
				CROAK("Guid string character '%c' at %zu "
				    "is not hex digit", str[i], i);
			break;
		}
	}
	save_errno = errno;
	errno = 0;

	memcpy(num, &str[0], 8);
	num[8] = '\0';
	data = strtol(num, &end, 16);
	if (errno != 0 || *end != '\0' || data > UA_UINT32_MAX)
		CROAK("Guid string '%s' for data1 is not hex number", num);
	out.data1 = data;

	memcpy(num, &str[9], 4);
	num[4] = '\0';
	data = strtol(num, &end, 16);
	if (errno != 0 || *end != '\0' || data > UA_UINT16_MAX)
		CROAK("Guid string '%s' for data2 is not hex number", num);
	out.data2 = data;

	memcpy(num, &str[14], 4);
	num[4] = '\0';
	data = strtol(num, &end, 16);
	if (errno != 0 || *end != '\0' || data > UA_UINT16_MAX)
		CROAK("Guid string '%s' for data3 is not hex number", num);
	out.data3 = data;

	for (i = 19, j = 0; i < len && j < 8; i += 2, j++) {
		if (i == 23)
			i++;
		memcpy(num, &str[i], 2);
		num[2] = '\0';
		data = strtol(num, &end, 16);
		if (errno != 0 || *end != '\0' || data > UA_BYTE_MAX)
			CROAK("Guid string '%s' for data4[%zu] "
			    "is not hex number", num, j);
		out.data4[j] = data;
	}

	errno = save_errno;
	return out;
}

static void
XS_pack_UA_Guid(SV *out, UA_Guid in)
{
	dTHX;

	/*
	 * Print the Guid format defined in Part 6, 5.1.3.
	 * Format: C496578A-0DFE-4B8F-870A-745238C6AEAE
	 */
	sv_setpvf(out, "%08X-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X",
	    in.data1, in.data2, in.data3, in.data4[0], in.data4[1],
	    in.data4[2], in.data4[3], in.data4[4],
	    in.data4[5], in.data4[6], in.data4[7]);
}

/* 6.1.16 ByteString, types.h */

static UA_ByteString
XS_unpack_UA_ByteString(SV *in)
{
	dTHX;
	char *str;
	UA_ByteString out;

	if (!SvOK(in)) {
		UA_ByteString_init(&out);
		return out;
	}

	str = SvPV(in, out.length);
	if (out.length > 0) {
		out.data = UA_malloc(out.length);
		if (out.data == NULL)
			CROAKE("UA_malloc");
		memcpy(out.data, str, out.length);
	} else {
		out.data = UA_EMPTY_ARRAY_SENTINEL;
	}
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

	UA_Variant_setScalar(variant, scalar, type);
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

	UA_Variant_setArray(variant, array, top + 1, type);
}

static UA_Variant
XS_unpack_UA_Variant(SV *in)
{
	dTHX;
	UA_Variant out;
	OPCUA_Open62541_DataType type;
	SV **svp, **scalar, **array;
	HV *hv;
	AV *av;
	ssize_t i, top;
	int count;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	UA_Variant_init(&out);
	hv = (HV*)SvRV(in);

	count = hv_iterinit(hv);
	if (count == 0)
		return out;

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

		svp = hv_fetchs(hv, "Variant_arrayDimensions", 0);
		if (svp != NULL) {
			if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV) {
				CROAK("Not an ARRAY reference for Variant_arrayDimensions");
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
	AV *av;
	size_t i;

	hv = newHV();
	if (UA_Variant_isEmpty(&in)) {
		sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
		return;
	}

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

		if (in.arrayDimensions != NULL) {
			av = (AV*)sv_2mortal((SV*)newAV());
			av_extend(av, in.arrayDimensionsSize);
			for (i = 0; i < in.arrayDimensionsSize; i++) {
				sv = newSV(0);
				XS_pack_UA_UInt32(sv, in.arrayDimensions[i]);
				av_push(av, sv);
			}
			hv_stores(hv, "Variant_arrayDimensions", newRV_inc((SV*)av));
		}
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
		out.content.decoded.data = data;

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
	HV *content = newHV();

	sv = newSV(0);
	XS_pack_UA_Int32(sv, in.encoding);
	hv_stores(hv, "ExtensionObject_encoding", sv);

	switch (in.encoding) {
	case UA_EXTENSIONOBJECT_ENCODED_NOBODY:
	case UA_EXTENSIONOBJECT_ENCODED_BYTESTRING:
	case UA_EXTENSIONOBJECT_ENCODED_XML:
		sv = newSV(0);
		XS_pack_UA_NodeId(sv, in.content.encoded.typeId);
		hv_stores(content, "ExtensionObject_content_typeId", sv);

		sv = newSV(0);
		XS_pack_UA_ByteString(sv, in.content.encoded.body);
		hv_stores(content, "ExtensionObject_content_body", sv);

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
		hv_stores(content, "ExtensionObject_content_type", sv);

		sv = newSV(0);
		(pack_UA_table[type->typeIndex])(sv, in.content.decoded.data);
		hv_stores(content, "ExtensionObject_content_data", sv);

		break;
	default:
		CROAK("ExtensionObject_encoding %d unknown", (int)in.encoding);
	}

	hv_stores(hv, "ExtensionObject_content", newRV_noinc((SV*)content));
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

#ifndef HAVE_UA_SERVER_READCONTAINSNOLOOPS

/*
 * There is a typo in open62541 1.0 server read readContainsNoLoops,
 * the final s in the function name is missing.  Translate it to
 * get standard conforming name in Perl.
 * This code is not needed for open62541 1.1 as upstream has fixed the bug.
 */
static UA_StatusCode
UA_Server_readContainsNoLoops(UA_Server *server, const UA_NodeId nodeId,
    UA_Boolean *outContainsNoLoops)
{
    return UA_Server_readContainsNoLoop(server, nodeId, outContainsNoLoops);
}

#endif /* HAVE_UA_SERVER_READCONTAINSNOLOOPS */

/* 11.7.1 Node Lifecycle: Constructors, Destructors and Node Contexts */

#ifdef HAVE_UA_SERVER_SETADMINSESSIONCONTEXT

static OPCUA_Open62541_GlobalNodeLifecycle
XS_unpack_OPCUA_Open62541_GlobalNodeLifecycle(SV *in)
{
	dTHX;
	struct OPCUA_Open62541_GlobalNodeLifecycle out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV) {
		CROAK("Not a HASH reference");
	}
	memset(&out, 0, sizeof(out));
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "GlobalNodeLifecycle_constructor", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVCV)
			CROAK("constructor '%s' is not a CODE reference",
			    SvPV_nolen(*svp));
		out.gnl_constructor = *svp;
	}

	svp = hv_fetchs(hv, "GlobalNodeLifecycle_destructor", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVCV)
			CROAK("destructor '%s' is not a CODE reference",
			    SvPV_nolen(*svp));
		out.gnl_destructor = *svp;
	}

	svp = hv_fetchs(hv, "GlobalNodeLifecycle_createOptionalChild", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVCV)
			CROAK(
			    "createOptionalChild '%s' is not a CODE reference",
			    SvPV_nolen(*svp));
		out.gnl_createOptionalChild = *svp;
	}

	svp = hv_fetchs(hv, "GlobalNodeLifecycle_generateChildNodeId", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVCV)
			CROAK(
			    "generateChildNodeId '%s' is not a CODE reference",
			    SvPV_nolen(*svp));
		out.gnl_generateChildNodeId = *svp;
	}

	return out;
}

static UA_StatusCode
serverGlobalNodeLifecycleConstructor(UA_Server *ua_server,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_NodeId *nodeId, void **nodeContext)
{
	dTHX;
	dSP;
	SV *sv;
	int count;
	UA_StatusCode status;
	OPCUA_Open62541_Server server = sessionContext;

	DPRINTF("ua_server %p, server %p, sv_server %p",
	    ua_server, server, server->sv_server);
	if (ua_server != server->sv_server) {
		CROAK("Server pointer mismatch callback %p, context %p",
		    ua_server, server->sv_server);
	}

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	EXTEND(SP, 5);
	sv = &PL_sv_undef;
	if (server->sv_lifecycle_server != NULL)
		sv = server->sv_lifecycle_server;
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (sessionId != NULL) {
		sv = sv_newmortal();
		XS_pack_UA_NodeId(sv, *sessionId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (server->sv_lifecycle_context != NULL)
		sv = server->sv_lifecycle_context;
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (nodeId != NULL) {
		sv = sv_newmortal();
		XS_pack_UA_NodeId(sv, *nodeId);
	}
	PUSHs(sv);
	/* Constructor uses reference to context, pass a reference to Perl. */
	if (*nodeContext == NULL)
		*nodeContext = newSV(0);
	sv = *nodeContext;
	mPUSHs(newRV_inc(sv));
	PUTBACK;

	count = call_sv(server->sv_config.svc_lifecycle.gnl_constructor,
	    G_SCALAR);

	SPAGAIN;

	if (count != 1)
		CROAK("Constructor callback return count %d is not 1", count);
	status = POPu;

	PUTBACK;
	FREETMPS;
	LEAVE;

	return status;
}

static void
serverGlobalNodeLifecycleDestructor(UA_Server *ua_server,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_NodeId *nodeId, void *nodeContext) {
	dTHX;
	dSP;
	SV *sv;
	OPCUA_Open62541_Server server = sessionContext;

	DPRINTF("ua_server %p, server %p, sv_server %p",
	    ua_server, server, server->sv_server);
	if (ua_server != server->sv_server) {
		CROAK("Server pointer mismatch callback %p, context %p",
		    ua_server, server->sv_server);
	}

	/* C destructor is always called to destroy node context. */
	if (server->sv_config.svc_lifecycle.gnl_destructor == NULL) {
		/* Reference count has been increased in server add...Node. */
		sv = nodeContext;
		SvREFCNT_dec(sv);
		return;
	}

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	EXTEND(SP, 5);
	sv = &PL_sv_undef;
	if (server->sv_lifecycle_server != NULL)
		sv = server->sv_lifecycle_server;
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (sessionId != NULL) {
		sv = sv_newmortal();
		XS_pack_UA_NodeId(sv, *sessionId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (server->sv_lifecycle_context != NULL)
		sv = server->sv_lifecycle_context;
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (nodeId != NULL) {
		sv = sv_newmortal();
		XS_pack_UA_NodeId(sv, *nodeId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (nodeContext != NULL) {
		/* Make node context mortal, destroy it at function return. */
		sv = nodeContext;
		sv_2mortal(sv);
	}
	PUSHs(sv);
	PUTBACK;

	call_sv(server->sv_config.svc_lifecycle.gnl_destructor,
	    G_VOID | G_DISCARD);

	FREETMPS;
	LEAVE;
}

static UA_Boolean
serverGlobalNodeLifecycleCreateOptionalChild(UA_Server *ua_server,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_NodeId *sourceNodeId, const UA_NodeId *targetParentNodeId,
    const UA_NodeId *referenceTypeId)
{
	dTHX;
	dSP;
	SV *sv;
	int count;
	UA_Boolean instantiate;
	OPCUA_Open62541_Server server = sessionContext;

	DPRINTF("ua_server %p, server %p, sv_server %p",
	    ua_server, server, server->sv_server);
	if (ua_server != server->sv_server) {
		CROAK("Server pointer mismatch callback %p, context %p",
		    ua_server, server->sv_server);
	}

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	EXTEND(SP, 6);
	sv = &PL_sv_undef;
	if (server->sv_lifecycle_server != NULL)
		sv = server->sv_lifecycle_server;
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (sessionId != NULL) {
		sv = sv_newmortal();
		XS_pack_UA_NodeId(sv, *sessionId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (server->sv_lifecycle_context != NULL)
		sv = server->sv_lifecycle_context;
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (sourceNodeId != NULL) {
		sv = sv_newmortal();
		XS_pack_UA_NodeId(sv, *sourceNodeId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (targetParentNodeId != NULL) {
		sv = sv_newmortal();
		XS_pack_UA_NodeId(sv, *targetParentNodeId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (referenceTypeId != NULL) {
		sv = sv_newmortal();
		XS_pack_UA_NodeId(sv, *referenceTypeId);
	}
	PUSHs(sv);
	PUTBACK;

	count = call_sv(server->sv_config.svc_lifecycle.gnl_createOptionalChild,
	    G_SCALAR);

	SPAGAIN;

	if (count != 1)
		CROAK("CreateOptionalChild callback return count %d is not 1",
		    count);
	sv = POPs;
	instantiate = SvOK(sv) && SvTRUE(sv);

	PUTBACK;
	FREETMPS;
	LEAVE;

	return instantiate;
}

static UA_StatusCode
serverGlobalNodeLifecycleGenerateChildNodeId(UA_Server *ua_server,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_NodeId *sourceNodeId, const UA_NodeId *targetParentNodeId,
    const UA_NodeId *referenceTypeId, UA_NodeId *targetNodeId)
{
	dTHX;
	dSP;
	SV *sv;
	int count;
	UA_StatusCode status;
	OPCUA_Open62541_Server server = sessionContext;

	DPRINTF("ua_server %p, server %p, sv_server %p",
	    ua_server, server, server->sv_server);
	if (ua_server != server->sv_server) {
		CROAK("Server pointer mismatch callback %p, context %p",
		    ua_server, server->sv_server);
	}

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	EXTEND(SP, 7);
	sv = &PL_sv_undef;
	if (server->sv_lifecycle_server != NULL)
		sv = server->sv_lifecycle_server;
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (sessionId != NULL) {
		sv = sv_newmortal();
		XS_pack_UA_NodeId(sv, *sessionId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (server->sv_lifecycle_context != NULL)
		sv = server->sv_lifecycle_context;
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (sourceNodeId != NULL) {
		sv = sv_newmortal();
		XS_pack_UA_NodeId(sv, *sourceNodeId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (targetParentNodeId != NULL) {
		sv = sv_newmortal();
		XS_pack_UA_NodeId(sv, *targetParentNodeId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (referenceTypeId != NULL) {
		sv = sv_newmortal();
		XS_pack_UA_NodeId(sv, *referenceTypeId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (targetNodeId != NULL) {
		sv = sv_newmortal();
		XS_pack_UA_NodeId(sv, *targetNodeId);
	}
	PUSHs(sv);
	PUTBACK;

	count = call_sv(server->sv_config.svc_lifecycle.gnl_generateChildNodeId,
	    G_SCALAR);

	SPAGAIN;

	if (count != 1)
		CROAK("GenerateChildNodeId callback return count %d is not 1",
		    count);
	status = POPu;
	if (targetNodeId != NULL) {
		/* sv contains the targetNodeId, convert the values back. */
		*targetNodeId = XS_unpack_UA_NodeId(sv);
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return status;
}

#endif /* HAVE_UA_SERVER_SETADMINSESSIONCONTEXT */

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
		CROAKE("calloc");
	DPRINTF("ccd %p", ccd);

	/*
	 * Make a copy of the callback.
	 * see perlcall, Using call_sv, newSVsv()
	 */
	ccd->ccd_callback = newSVsv(callback);
	/*
	 * Client remembers a ref to callback data and destroys it when freed.
	 * So we must not increase the Perl refcount of the client.  Perl must
	 * free the client and then the callback data is destroyed.
	 * This API sucks.  Callbacks that may be called are hard to handle.
	 */
	ccd->ccd_client = client;
	ccd->ccd_data = SvREFCNT_inc(data);

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
clientCallbackPerl(UA_Client *ua_client, void *userdata, UA_UInt32 requestId,
    SV *response)
{
	dTHX;
	dSP;
	ClientCallbackData ccd = userdata;

	DPRINTF("ua_client %p, ccd %p", ua_client, ccd);

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
clientStateCallback(UA_Client *ua_client,
#ifdef HAVE_UA_CLIENT_GETSTATE_3
    UA_SecureChannelState channelState, UA_SessionState sessionState,
    UA_StatusCode connectStatus)
#else
    UA_ClientState clientState)
#endif
{
	dTHX;
	dSP;
	SV *sv;
	OPCUA_Open62541_Client client;

	sv = UA_Client_getContext(ua_client);
	DPRINTF("client context sv %p, SvOK %d, SvROK %d, sv_derived_from %d",
	    sv, SvOK(sv), SvROK(sv),
	    sv_derived_from(sv, "OPCUA::Open62541::Client"));
	if (!(SvOK(sv) && SvROK(sv) &&
	    sv_derived_from(sv, "OPCUA::Open62541::Client"))) {
		CROAK("Client context is not a OPCUA::Open62541::Client");
	}
	client = INT2PTR(OPCUA_Open62541_Client, SvIV(SvRV(sv)));

	DPRINTF("ua_client %p, client %p", ua_client, client);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
#ifdef HAVE_UA_CLIENT_GETSTATE_3
	EXTEND(SP, 4);
	PUSHs(sv);
	sv = newSViv(channelState);
	mPUSHs(sv);
	sv = newSViv(sessionState);
	mPUSHs(sv);
	sv = newSViv(connectStatus);
	mPUSHs(sv);
#else
	EXTEND(SP, 2);
	PUSHs(sv);
	sv = newSViv(clientState);
	mPUSHs(sv);
#endif
	PUTBACK;

	call_sv(client->cl_config.clc_statecallback, G_VOID | G_DISCARD);

	FREETMPS;
	LEAVE;
}

#ifndef HAVE_UA_CLIENT_CONNECTASYNC

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

#endif /* HAVE_UA_CLIENT_CONNECTASYNC */

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
clientAsyncBrowseNextCallback(UA_Client *client, void *userdata,
    UA_UInt32 requestId, UA_BrowseNextResponse *response)
{
	dTHX;
	SV *sv;

	sv = newSV(0);
	if (response != NULL)
		XS_pack_UA_BrowseNextResponse(sv, *response);

	clientCallbackPerl(client, userdata, requestId, sv);
}

#include "Open62541-client-read-callback.xsh"

static void
clientAsyncReadDataTypeCallback(UA_Client *client, void *userdata,
    UA_UInt32 requestId, UA_NodeId *nodeId)
{
	dTHX;
	SV *sv;
	UV index;

	sv = newSV(0);
	if (nodeId != NULL) {
		/*
		 * Convert NodeId to DataType, see XS_unpack_UA_NodeId() for
		 * the opposite direction.
		 */
		for (index = 0; index < UA_TYPES_COUNT; index++) {
			if (UA_NodeId_equal(nodeId, &UA_TYPES[index].typeId))
				break;
		}
		if (index < UA_TYPES_COUNT)
			XS_pack_OPCUA_Open62541_DataType(sv, &UA_TYPES[index]);
	}

	clientCallbackPerl(client, userdata, requestId, sv);
}

static void
clientAsyncReadCallback(UA_Client *client, void *userdata,
    UA_UInt32 requestId, UA_ReadResponse *response)
{
	dTHX;
	SV *sv;

	sv = newSV(0);
	if (response != NULL)
		XS_pack_UA_ReadResponse(sv, *response);

	clientCallbackPerl(client, userdata, requestId, sv);
}

static void
clientDeleteSubscriptionCallback(UA_Client *client, UA_UInt32 subId,
    void *subContext)
{
	dTHX;
	dSP;
	SubscriptionContext sub = subContext;

	DPRINTF("client %p, sub %p, sc_change %p, sc_delete %p",
	    client, sub, sub->sc_change, sub->sc_delete);

	if (sub->sc_delete) {
		ENTER;
		SAVETMPS;

		PUSHMARK(SP);
		EXTEND(SP, 3);
		PUSHs(sub->sc_delete->ccd_client);
		mPUSHu(subId);
		PUSHs(sub->sc_delete->ccd_data);
		PUTBACK;

		call_sv(sub->sc_delete->ccd_callback, G_VOID | G_DISCARD);

		FREETMPS;
		LEAVE;

		deleteClientCallbackData(sub->sc_delete);
	}

	if (sub->sc_change)
		deleteClientCallbackData(sub->sc_change);
	if (sub->sc_context)
		SvREFCNT_dec(sub->sc_context);
	free(sub);
}

static void
clientStatusChangeNotificationCallback(UA_Client *client, UA_UInt32 subId,
    void *subContext, UA_StatusChangeNotification *notification)
{
	dTHX;
	dSP;
	SubscriptionContext sub = subContext;
	SV *notificationPerl;

	DPRINTF("client %p, sub %p, sc_change %p, sc_delete %p",
	    client, sub, sub->sc_change, sub->sc_delete);

	if (sub->sc_change == NULL)
		return;

	notificationPerl = newSV(0);
	if (notification != NULL)
		XS_pack_UA_StatusChangeNotification(notificationPerl,
		    *notification);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	EXTEND(SP, 4);
	PUSHs(sub->sc_change->ccd_client);
	mPUSHu(subId);
	PUSHs(sub->sc_change->ccd_data);
	mPUSHs(notificationPerl);
	PUTBACK;

	call_sv(sub->sc_change->ccd_callback, G_VOID | G_DISCARD);

	FREETMPS;
	LEAVE;
}

static void
clientDeleteMonitoredItemCallback(UA_Client *client, UA_UInt32 subId,
    void *subContext, UA_UInt32 monId, void *monContext)
{
	dTHX;
	dSP;
	SubscriptionContext sub = subContext;
	MonitoredItemContext mon = monContext;

	DPRINTF("client %p, sub %p, sc_change %p, sc_delete %p, "
	    "mon %p, mc_change %p, mc_delete %p",
	    client, sub, sub->sc_change, sub->sc_delete,
	    mon, mon->mc_change, mon->mc_delete);

	if (mon->mc_delete) {
		ENTER;
		SAVETMPS;

		PUSHMARK(SP);
		EXTEND(SP, 5);
		PUSHs(mon->mc_delete->ccd_client);
		mPUSHu(subId);
		/* subContext can be NULL if the request failed */
		if (sub && sub->sc_context) {
			PUSHs(sub->sc_context);
		} else {
			PUSHmortal;
		}
		mPUSHu(monId);
		PUSHs(mon->mc_delete->ccd_data);
		PUTBACK;

		call_sv(mon->mc_delete->ccd_callback, G_VOID | G_DISCARD);

		FREETMPS;
		LEAVE;

		deleteClientCallbackData(mon->mc_delete);
	}

	if (mon->mc_change)
		deleteClientCallbackData(mon->mc_change);
	free(mon);
}

static void
clientDataChangeNotificationCallback(UA_Client *client, UA_UInt32 subId,
    void *subContext, UA_UInt32 monId, void *monContext, UA_DataValue *value)
{
	dTHX;
	dSP;
	SubscriptionContext sub = subContext;
	MonitoredItemContext mon = monContext;
	SV *valuePerl;

	DPRINTF("client %p, sub %p, sc_change %p, sc_delete %p, "
	    "mon %p, mc_change %p, mc_delete %p",
	    client, sub, sub->sc_change, sub->sc_delete,
	    mon, mon->mc_change, mon->mc_delete);

	if (mon->mc_change == NULL)
		return;

	valuePerl = newSV(0);
	if (value != NULL)
		XS_pack_UA_DataValue(valuePerl, *(UA_DataValue *)value);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	EXTEND(SP, 6);
	PUSHs(mon->mc_change->ccd_client);
	mPUSHu(subId);
	if (sub && sub->sc_context)
		PUSHs(sub->sc_context);
	else
		PUSHmortal;
	mPUSHu(monId);
	PUSHs(mon->mc_change->ccd_data);
	mPUSHs(valuePerl);
	PUTBACK;

	call_sv(mon->mc_change->ccd_callback, G_VOID | G_DISCARD);

	FREETMPS;
	LEAVE;
}

/* 16.3 Access Control Plugin API */

static UA_UInt32
getUserRightsMask_default(UA_Server *server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *nodeId,
    void *nodeContext) {
	return 0xFFFFFFFF;
}

static UA_UInt32
getUserRightsMask_readonly(UA_Server *server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *nodeId,
    void *nodeContext) {
	return 0x00000000;
}

static UA_Byte
getUserAccessLevel_default(UA_Server *server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *nodeId,
    void *nodeContext) {
	return 0xFF;
}

static UA_Byte
getUserAccessLevel_readonly(UA_Server *server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *nodeId,
    void *nodeContext) {
	return UA_ACCESSLEVELMASK_READ | UA_ACCESSLEVELMASK_HISTORYREAD;
}

static UA_Boolean
getUserExecutable_default(UA_Server *server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *methodId,
    void *methodContext) {
	return true;
}

static UA_Boolean
getUserExecutable_false(UA_Server *server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *methodId,
    void *methodContext) {
	return false;
}

static UA_Boolean
getUserExecutableOnObject_default(UA_Server *server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *methodId,
    void *methodContext, const UA_NodeId *objectId, void *objectContext) {
	return true;
}

static UA_Boolean
getUserExecutableOnObject_false(UA_Server *server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *methodId,
    void *methodContext, const UA_NodeId *objectId, void *objectContext) {
	return false;
}

static UA_Boolean
allowAddNode_default(UA_Server *server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_AddNodesItem *item) {
	return true;
}

static UA_Boolean
allowAddNode_false(UA_Server *server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_AddNodesItem *item) {
	return false;
}

static UA_Boolean
allowAddReference_default(UA_Server *server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_AddReferencesItem *item) {
	return true;
}

static UA_Boolean
allowAddReference_false(UA_Server *server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_AddReferencesItem *item) {
	return false;
}

static UA_Boolean
allowDeleteNode_default(UA_Server *server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_DeleteNodesItem *item) {
	return true;
}

static UA_Boolean
allowDeleteNode_false(UA_Server *server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_DeleteNodesItem *item) {
	return false;
}

static UA_Boolean
allowDeleteReference_default(UA_Server *server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_DeleteReferencesItem *item) {
	return true;
}

static UA_Boolean
allowDeleteReference_false(UA_Server *server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_DeleteReferencesItem *item) {
	return false;
}

#ifdef UA_ENABLE_HISTORIZING

static UA_Boolean
allowHistoryUpdateUpdateData_default(UA_Server *server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *nodeId,
    UA_PerformUpdateType performInsertReplace, const UA_DataValue *value) {
	return true;
}

static UA_Boolean
allowHistoryUpdateUpdateData_false(UA_Server *server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *nodeId,
    UA_PerformUpdateType performInsertReplace, const UA_DataValue *value) {
	return false;
}

static UA_Boolean
allowHistoryUpdateDeleteRawModified_default(UA_Server *server,
    UA_AccessControl *ac, const UA_NodeId *sessionId, void *sessionContext,
    const UA_NodeId *nodeId, UA_DateTime startTimestamp,
    UA_DateTime endTimestamp, bool isDeleteModified) {
	return true;
}

static UA_Boolean
allowHistoryUpdateDeleteRawModified_false(UA_Server *server,
    UA_AccessControl *ac, const UA_NodeId *sessionId, void *sessionContext,
    const UA_NodeId *nodeId, UA_DateTime startTimestamp,
    UA_DateTime endTimestamp, bool isDeleteModified) {
	return false;
}

#endif /* UA_ENABLE_HISTORIZING*/

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
INCLUDE: Open62541-destroy.xsh

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
	RETVAL->sv_config.svc_serverconfig =
	    UA_Server_getConfig(RETVAL->sv_server);
	if (RETVAL->sv_config.svc_serverconfig == NULL) {
		UA_Server_delete(RETVAL->sv_server);
		free(RETVAL);
		CROAKE("UA_Server_getConfig");
	}
	DPRINTF("class %s, server %p, sv_server %p",
	    class, RETVAL, RETVAL->sv_server);
#ifdef HAVE_UA_SERVER_SETADMINSESSIONCONTEXT
	/* Needed for lifecycle callbacks. */
	UA_Server_setAdminSessionContext(RETVAL->sv_server, RETVAL);
	/* Node context has to be freed in destructor, call it always. */
	RETVAL->sv_config.svc_serverconfig->nodeLifecycle.destructor =
	    serverGlobalNodeLifecycleDestructor;
#endif
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
	SvREFCNT_dec(server->sv_lifecycle_context);
	free(server);

OPCUA_Open62541_ServerConfig
UA_Server_getConfig(server)
	OPCUA_Open62541_Server		server
    CODE:
	RETVAL = &server->sv_config;
	DPRINTF("server %p, sv_server %p, config %p, svc_serverconfig %p",
	    server, server->sv_server, RETVAL, RETVAL->svc_serverconfig);
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

INCLUDE: Open62541-server-read-write.xsh

UA_DataValue
UA_Server_read(server, item, timestamps)
	OPCUA_Open62541_Server			server
	OPCUA_Open62541_ReadValueId		item
	UA_TimestampsToReturn			timestamps
    CODE:
	RETVAL = UA_Server_read(server->sv_server, item, timestamps);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_readDataType(server, nodeId, outDataType)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		nodeId
	SV *				outDataType
    PREINIT:
	UA_NodeId			outNodeId;
	UV				index;
    CODE:
	RETVAL = UA_Server_readDataType(server->sv_server,
	    *nodeId, &outNodeId);
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

UA_StatusCode
UA_Server_write(server, value)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_WriteValue	value
    CODE:
	RETVAL = UA_Server_write(server->sv_server, value);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_writeDataType(server, nodeId, newDataType)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		nodeId
	OPCUA_Open62541_DataType	newDataType
    CODE:
	RETVAL = UA_Server_writeDataType(server->sv_server,
	    *nodeId, newDataType->typeId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_readObjectProperty(server, nodeId, propertyName, outVariant)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		nodeId
	OPCUA_Open62541_QualifiedName	propertyName
	OPCUA_Open62541_Variant		outVariant
    CODE:
	RETVAL = UA_Server_readObjectProperty(server->sv_server, *nodeId,
	    *propertyName, outVariant);
	XS_pack_UA_Variant(SvRV(ST(2)), *outVariant);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_writeObjectProperty(server, nodeId, propertyName, newVariant)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		nodeId
	OPCUA_Open62541_QualifiedName	propertyName
	OPCUA_Open62541_Variant		newVariant
    CODE:
	RETVAL = UA_Server_writeObjectProperty(server->sv_server,
	    *nodeId, *propertyName, *newVariant);
    OUTPUT:
	RETVAL

# 11.5 Browsing

UA_BrowseResult
UA_Server_browse(server, maxReferences, bd)
	OPCUA_Open62541_Server			server
	UA_UInt32				maxReferences
	OPCUA_Open62541_BrowseDescription	bd
    CODE:
	RETVAL = UA_Server_browse(server->sv_server, maxReferences, bd);
    OUTPUT:
	RETVAL

UA_BrowseResult
UA_Server_browseNext(server, releaseContinuationPoint, continuationPoint)
	OPCUA_Open62541_Server			server
	UA_Boolean				releaseContinuationPoint
	OPCUA_Open62541_ByteString		continuationPoint
    CODE:
	RETVAL = UA_Server_browseNext(server->sv_server,
	    releaseContinuationPoint, continuationPoint);
    OUTPUT:
	RETVAL


# 11.7 Information Model Callbacks

#ifdef HAVE_UA_SERVER_SETADMINSESSIONCONTEXT

void
UA_Server_setAdminSessionContext(server, context)
	OPCUA_Open62541_Server		server
	SV *				context
    CODE:
	/* Server new() has called open62541 setAdminSessionContext(). */
	server->sv_lifecycle_server = ST(0);
	SvREFCNT_dec(server->sv_lifecycle_context);
	server->sv_lifecycle_context = SvREFCNT_inc(context);

#endif /* HAVE_UA_SERVER_SETADMINSESSIONCONTEXT */

# 11.9 Node Addition and Deletion

UA_StatusCode
UA_Server_addVariableNode(server, requestedNewNodeId, parentNodeId, referenceTypeId, browseName, typeDefinition, attr, nodeContext, outoptNewNodeId)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		requestedNewNodeId
	OPCUA_Open62541_NodeId		parentNodeId
	OPCUA_Open62541_NodeId		referenceTypeId
	OPCUA_Open62541_QualifiedName	browseName
	OPCUA_Open62541_NodeId		typeDefinition
	OPCUA_Open62541_VariableAttributes	attr
	SV *				nodeContext
	OPCUA_Open62541_NodeId		outoptNewNodeId
    PREINIT:
	SV *				nc = NULL;
    CODE:
	if (!SvOK(nodeContext))
		nodeContext = NULL;
#ifndef HAVE_UA_SERVER_SETADMINSESSIONCONTEXT
	nodeContext = NULL;
#endif
	if (nodeContext != NULL)
		nc = newSVsv(nodeContext);
	RETVAL = UA_Server_addVariableNode(server->sv_server,
	    *requestedNewNodeId, *parentNodeId, *referenceTypeId, *browseName,
	    *typeDefinition, *attr, nc, outoptNewNodeId);
	if (RETVAL != UA_STATUSCODE_GOOD)
		SvREFCNT_dec(nc);
	else if (outoptNewNodeId != NULL)
		XS_pack_UA_NodeId(SvRV(ST(8)), *outoptNewNodeId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_addVariableTypeNode(server, requestedNewNodeId, parentNodeId, referenceTypeId, browseName, typeDefinition, attr, nodeContext, outoptNewNodeId)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		requestedNewNodeId
	OPCUA_Open62541_NodeId		parentNodeId
	OPCUA_Open62541_NodeId		referenceTypeId
	OPCUA_Open62541_QualifiedName	browseName
	OPCUA_Open62541_NodeId		typeDefinition
	OPCUA_Open62541_VariableTypeAttributes	attr
	SV *				nodeContext
	OPCUA_Open62541_NodeId		outoptNewNodeId
    PREINIT:
	SV *				nc = NULL;
    CODE:
	if (!SvOK(nodeContext))
		nodeContext = NULL;
#ifndef HAVE_UA_SERVER_SETADMINSESSIONCONTEXT
	nodeContext = NULL;
#endif
	if (nodeContext != NULL)
		nc = newSVsv(nodeContext);
	RETVAL = UA_Server_addVariableTypeNode(server->sv_server,
	    *requestedNewNodeId, *parentNodeId, *referenceTypeId, *browseName,
	    *typeDefinition, *attr, nc, outoptNewNodeId);
	if (RETVAL != UA_STATUSCODE_GOOD)
		SvREFCNT_dec(nc);
	else if (outoptNewNodeId != NULL)
		XS_pack_UA_NodeId(SvRV(ST(8)), *outoptNewNodeId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_addObjectNode(server, requestedNewNodeId, parentNodeId, referenceTypeId, browseName, typeDefinition, attr, nodeContext, outoptNewNodeId)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		requestedNewNodeId
	OPCUA_Open62541_NodeId		parentNodeId
	OPCUA_Open62541_NodeId		referenceTypeId
	OPCUA_Open62541_QualifiedName	browseName
	OPCUA_Open62541_NodeId		typeDefinition
	OPCUA_Open62541_ObjectAttributes	attr
	SV *				nodeContext
	OPCUA_Open62541_NodeId		outoptNewNodeId
    PREINIT:
	SV *				nc = NULL;
    CODE:
	if (!SvOK(nodeContext))
		nodeContext = NULL;
#ifndef HAVE_UA_SERVER_SETADMINSESSIONCONTEXT
	nodeContext = NULL;
#endif
	if (nodeContext != NULL)
		nc = newSVsv(nodeContext);
	RETVAL = UA_Server_addObjectNode(server->sv_server,
	    *requestedNewNodeId, *parentNodeId, *referenceTypeId, *browseName,
	    *typeDefinition, *attr, nc, outoptNewNodeId);
	if (RETVAL != UA_STATUSCODE_GOOD)
		SvREFCNT_dec(nc);
	else if (outoptNewNodeId != NULL)
		XS_pack_UA_NodeId(SvRV(ST(8)), *outoptNewNodeId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_addObjectTypeNode(server, requestedNewNodeId, parentNodeId, referenceTypeId, browseName, attr, nodeContext, outoptNewNodeId)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		requestedNewNodeId
	OPCUA_Open62541_NodeId		parentNodeId
	OPCUA_Open62541_NodeId		referenceTypeId
	OPCUA_Open62541_QualifiedName	browseName
	OPCUA_Open62541_ObjectTypeAttributes	attr
	SV *				nodeContext
	OPCUA_Open62541_NodeId		outoptNewNodeId
    PREINIT:
	SV *				nc = NULL;
    CODE:
	if (!SvOK(nodeContext))
		nodeContext = NULL;
#ifndef HAVE_UA_SERVER_SETADMINSESSIONCONTEXT
	nodeContext = NULL;
#endif
	if (nodeContext != NULL)
		nc = newSVsv(nodeContext);
	RETVAL = UA_Server_addObjectTypeNode(server->sv_server,
	    *requestedNewNodeId, *parentNodeId, *referenceTypeId, *browseName,
	    *attr, nc, outoptNewNodeId);
	if (RETVAL != UA_STATUSCODE_GOOD)
		SvREFCNT_dec(nc);
	else if (outoptNewNodeId != NULL)
		XS_pack_UA_NodeId(SvRV(ST(7)), *outoptNewNodeId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_addViewNode(server, requestedNewNodeId, parentNodeId, referenceTypeId, browseName, attr, nodeContext, outoptNewNodeId)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		requestedNewNodeId
	OPCUA_Open62541_NodeId		parentNodeId
	OPCUA_Open62541_NodeId		referenceTypeId
	OPCUA_Open62541_QualifiedName	browseName
	OPCUA_Open62541_ViewAttributes	attr
	SV *				nodeContext
	OPCUA_Open62541_NodeId		outoptNewNodeId
    PREINIT:
	SV *				nc = NULL;
    CODE:
	if (!SvOK(nodeContext))
		nodeContext = NULL;
#ifndef HAVE_UA_SERVER_SETADMINSESSIONCONTEXT
	nodeContext = NULL;
#endif
	if (nodeContext != NULL)
		nc = newSVsv(nodeContext);
	RETVAL = UA_Server_addViewNode(server->sv_server,
	    *requestedNewNodeId, *parentNodeId, *referenceTypeId, *browseName,
	    *attr, nc, outoptNewNodeId);
	if (RETVAL != UA_STATUSCODE_GOOD)
		SvREFCNT_dec(nc);
	else if (outoptNewNodeId != NULL)
		XS_pack_UA_NodeId(SvRV(ST(7)), *outoptNewNodeId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_addReferenceTypeNode(server, requestedNewNodeId, parentNodeId, referenceTypeId, browseName, attr, nodeContext, outoptNewNodeId)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		requestedNewNodeId
	OPCUA_Open62541_NodeId		parentNodeId
	OPCUA_Open62541_NodeId		referenceTypeId
	OPCUA_Open62541_QualifiedName	browseName
	OPCUA_Open62541_ReferenceTypeAttributes	attr
	SV *				nodeContext
	OPCUA_Open62541_NodeId		outoptNewNodeId
    PREINIT:
	SV *				nc = NULL;
    CODE:
	if (!SvOK(nodeContext))
		nodeContext = NULL;
#ifndef HAVE_UA_SERVER_SETADMINSESSIONCONTEXT
	nodeContext = NULL;
#endif
	if (nodeContext != NULL)
		nc = newSVsv(nodeContext);
	RETVAL = UA_Server_addReferenceTypeNode(server->sv_server,
	    *requestedNewNodeId, *parentNodeId, *referenceTypeId, *browseName,
	    *attr, nc, outoptNewNodeId);
	if (RETVAL != UA_STATUSCODE_GOOD)
		SvREFCNT_dec(nc);
	else if (outoptNewNodeId != NULL)
		XS_pack_UA_NodeId(SvRV(ST(7)), *outoptNewNodeId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_addDataTypeNode(server, requestedNewNodeId, parentNodeId, referenceTypeId, browseName, attr, nodeContext, outoptNewNodeId)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		requestedNewNodeId
	OPCUA_Open62541_NodeId		parentNodeId
	OPCUA_Open62541_NodeId		referenceTypeId
	OPCUA_Open62541_QualifiedName	browseName
	OPCUA_Open62541_DataTypeAttributes	attr
	SV *				nodeContext
	OPCUA_Open62541_NodeId		outoptNewNodeId
    PREINIT:
	SV *				nc = NULL;
    CODE:
	if (!SvOK(nodeContext))
		nodeContext = NULL;
#ifndef HAVE_UA_SERVER_SETADMINSESSIONCONTEXT
	nodeContext = NULL;
#endif
	if (nodeContext != NULL)
		nc = newSVsv(nodeContext);
	RETVAL = UA_Server_addDataTypeNode(server->sv_server,
	    *requestedNewNodeId, *parentNodeId, *referenceTypeId, *browseName,
	    *attr, nc, outoptNewNodeId);
	if (RETVAL != UA_STATUSCODE_GOOD)
		SvREFCNT_dec(nc);
	else if (outoptNewNodeId != NULL)
		XS_pack_UA_NodeId(SvRV(ST(7)), *outoptNewNodeId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_deleteNode(server, nodeId, deleteReferences)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		nodeId
	UA_Boolean			deleteReferences
    CODE:
	RETVAL = UA_Server_deleteNode(server->sv_server, *nodeId,
	    deleteReferences);
    OUTPUT:
	RETVAL

# 11.10 Reference Management

UA_StatusCode
UA_Server_addReference(server, sourceId, refTypeId, targetId, isForward)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		sourceId
	OPCUA_Open62541_NodeId		refTypeId
	OPCUA_Open62541_ExpandedNodeId	targetId
	UA_Boolean			isForward
    CODE:
	RETVAL = UA_Server_addReference(server->sv_server, *sourceId,
	    *refTypeId, *targetId, isForward);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_deleteReference(server, sourceNodeId, referenceTypeId, isForward, targetNodeId, deleteBidirectional)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		sourceNodeId
	OPCUA_Open62541_NodeId		referenceTypeId
	UA_Boolean			isForward
	OPCUA_Open62541_ExpandedNodeId	targetNodeId
	UA_Boolean			deleteBidirectional
    CODE:
	RETVAL = UA_Server_deleteReference(server->sv_server, *sourceNodeId,
	    *referenceTypeId, isForward, *targetNodeId, deleteBidirectional);
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
	SvREFCNT_dec(config->svc_lifecycle.gnl_constructor);
	SvREFCNT_dec(config->svc_lifecycle.gnl_destructor);
	SvREFCNT_dec(config->svc_lifecycle.gnl_createOptionalChild);
	SvREFCNT_dec(config->svc_lifecycle.gnl_generateChildNodeId);
	/* Delayed server destroy after server config destroy. */
	SvREFCNT_dec(config->svc_storage);

UA_StatusCode
UA_ServerConfig_setDefault(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	DPRINTF("config %p", config->svc_serverconfig);
	RETVAL = UA_ServerConfig_setDefault(config->svc_serverconfig);
#ifdef HAVE_UA_SERVER_SETADMINSESSIONCONTEXT
	/* We always need the destructor, setDefault() clears it. */
	config->svc_serverconfig->nodeLifecycle.destructor =
	    serverGlobalNodeLifecycleDestructor;
#endif
    OUTPUT:
	RETVAL

UA_StatusCode
UA_ServerConfig_setMinimal(config, portNumber, certificate)
	OPCUA_Open62541_ServerConfig	config
	UA_UInt16			portNumber
	OPCUA_Open62541_ByteString	certificate;
    CODE:
	RETVAL = UA_ServerConfig_setMinimal(config->svc_serverconfig,
	    portNumber, certificate);
#ifdef HAVE_UA_SERVER_SETADMINSESSIONCONTEXT
	/* We always need the destructor, setMinimal() clears it. */
	config->svc_serverconfig->nodeLifecycle.destructor =
	    serverGlobalNodeLifecycleDestructor;
#endif
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setCustomHostname(config, customHostname)
	OPCUA_Open62541_ServerConfig	config
	OPCUA_Open62541_String		customHostname
    CODE:
	UA_ServerConfig_setCustomHostname(config->svc_serverconfig,
	    *customHostname);

#ifdef HAVE_UA_SERVER_SETADMINSESSIONCONTEXT

void
UA_ServerConfig_setGlobalNodeLifecycle(config, lifecycle);
	OPCUA_Open62541_ServerConfig		config
	OPCUA_Open62541_GlobalNodeLifecycle	lifecycle
    CODE:
	/*
	 * Free old callback.  Make a copy of new callback.
	 * see perlcall, Using call_sv, newSVsv()
	 */
	SvREFCNT_dec(config->svc_lifecycle.gnl_constructor);
	config->svc_lifecycle.gnl_constructor = NULL;
	config->svc_serverconfig->nodeLifecycle.constructor = NULL;
	if (lifecycle.gnl_constructor != NULL) {
		config->svc_lifecycle.gnl_constructor =
		    newSVsv(lifecycle.gnl_constructor);
		config->svc_serverconfig->nodeLifecycle.constructor =
		    serverGlobalNodeLifecycleConstructor;
	}
	SvREFCNT_dec(config->svc_lifecycle.gnl_destructor);
	config->svc_lifecycle.gnl_destructor = NULL;
	if (lifecycle.gnl_destructor != NULL) {
		config->svc_lifecycle.gnl_destructor =
		    newSVsv(lifecycle.gnl_destructor);
		/* Server new() has already set nodeLifecycle destructor. */
	}
	SvREFCNT_dec(config->svc_lifecycle.gnl_createOptionalChild);
	config->svc_lifecycle.gnl_createOptionalChild = NULL;
	config->svc_serverconfig->nodeLifecycle.createOptionalChild = NULL;
	if (lifecycle.gnl_createOptionalChild != NULL) {
		config->svc_lifecycle.gnl_createOptionalChild =
		    newSVsv(lifecycle.gnl_createOptionalChild);
		config->svc_serverconfig->nodeLifecycle.createOptionalChild =
		    serverGlobalNodeLifecycleCreateOptionalChild;
	}
	SvREFCNT_dec(config->svc_lifecycle.gnl_generateChildNodeId);
	config->svc_lifecycle.gnl_generateChildNodeId = NULL;
	config->svc_serverconfig->nodeLifecycle.generateChildNodeId = NULL;
	if (lifecycle.gnl_generateChildNodeId != NULL) {
		config->svc_lifecycle.gnl_generateChildNodeId =
		    newSVsv(lifecycle.gnl_generateChildNodeId);
		config->svc_serverconfig->nodeLifecycle.generateChildNodeId =
		    serverGlobalNodeLifecycleGenerateChildNodeId;
	}

#endif /* HAVE_UA_SERVER_SETADMINSESSIONCONTEXT */

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
	/* Build info is part of the server memory.  Typemap clears retval. */
	UA_BuildInfo_copy(&config->svc_serverconfig->buildInfo, &RETVAL);
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setBuildInfo(config, buildinfo)
	OPCUA_Open62541_ServerConfig	config
	OPCUA_Open62541_BuildInfo	buildinfo
    CODE:
	UA_BuildInfo_copy(buildinfo, &config->svc_serverconfig->buildInfo);

# Limits for SecureChannels

UA_UInt16
UA_ServerConfig_getMaxSecureChannels(config)
	OPCUA_Open62541_ServerConfig		config
    CODE:
	RETVAL = config->svc_serverconfig->maxSecureChannels;
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setMaxSecureChannels(config, maxSecureChannels);
	OPCUA_Open62541_ServerConfig		config
	UA_UInt16	maxSecureChannels
    CODE:
	config->svc_serverconfig->maxSecureChannels = maxSecureChannels;

# Limits for Sessions

UA_UInt16
UA_ServerConfig_getMaxSessions(config)
	OPCUA_Open62541_ServerConfig		config
    CODE:
	RETVAL = config->svc_serverconfig->maxSessions;
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setMaxSessions(config, maxSessions);
	OPCUA_Open62541_ServerConfig		config
	UA_UInt16	maxSessions
    CODE:
	config->svc_serverconfig->maxSessions = maxSessions;

UA_Double
UA_ServerConfig_getMaxSessionTimeout(config)
	OPCUA_Open62541_ServerConfig		config
    CODE:
	RETVAL = config->svc_serverconfig->maxSessionTimeout;
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setMaxSessionTimeout(config, maxSessionTimeout);
	OPCUA_Open62541_ServerConfig		config
	UA_Double	maxSessionTimeout
    CODE:
	config->svc_serverconfig->maxSessionTimeout = maxSessionTimeout;

# Operation Limits

UA_UInt32
UA_ServerConfig_getMaxNodesPerRead(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	RETVAL = config->svc_serverconfig->maxNodesPerRead;
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setMaxNodesPerRead(config, maxNodesPerRead)
	OPCUA_Open62541_ServerConfig	config
	UA_UInt32			maxNodesPerRead
    CODE:
	config->svc_serverconfig->maxNodesPerRead = maxNodesPerRead;

UA_UInt32
UA_ServerConfig_getMaxNodesPerWrite(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	RETVAL = config->svc_serverconfig->maxNodesPerWrite;
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setMaxNodesPerWrite(config, maxNodesPerWrite)
	OPCUA_Open62541_ServerConfig	config
	UA_UInt32			maxNodesPerWrite
    CODE:
	config->svc_serverconfig->maxNodesPerWrite = maxNodesPerWrite;

UA_UInt32
UA_ServerConfig_getMaxNodesPerMethodCall(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	RETVAL = config->svc_serverconfig->maxNodesPerMethodCall;
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setMaxNodesPerMethodCall(config, maxNodesPerMethodCall)
	OPCUA_Open62541_ServerConfig	config
	UA_UInt32			maxNodesPerMethodCall
    CODE:
	config->svc_serverconfig->maxNodesPerMethodCall = maxNodesPerMethodCall;

UA_UInt32
UA_ServerConfig_getMaxNodesPerBrowse(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	RETVAL = config->svc_serverconfig->maxNodesPerBrowse;
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setMaxNodesPerBrowse(config, maxNodesPerBrowse)
	OPCUA_Open62541_ServerConfig	config
	UA_UInt32			maxNodesPerBrowse
    CODE:
	config->svc_serverconfig->maxNodesPerBrowse = maxNodesPerBrowse;

UA_UInt32
UA_ServerConfig_getMaxNodesPerRegisterNodes(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	RETVAL = config->svc_serverconfig->maxNodesPerRegisterNodes;
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setMaxNodesPerRegisterNodes(config, maxNodesPerRegisterNodes)
	OPCUA_Open62541_ServerConfig	config
	UA_UInt32			maxNodesPerRegisterNodes
    CODE:
	config->svc_serverconfig->maxNodesPerRegisterNodes =
	    maxNodesPerRegisterNodes;

UA_UInt32
UA_ServerConfig_getMaxNodesPerTranslateBrowsePathsToNodeIds(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	RETVAL = config->svc_serverconfig->maxNodesPerTranslateBrowsePathsToNodeIds;
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setMaxNodesPerTranslateBrowsePathsToNodeIds(config, \
    maxNodesPerTranslateBrowsePathsToNodeIds)
	OPCUA_Open62541_ServerConfig	config
	UA_UInt32			maxNodesPerTranslateBrowsePathsToNodeIds
    CODE:
	config->svc_serverconfig->maxNodesPerTranslateBrowsePathsToNodeIds =
	    maxNodesPerTranslateBrowsePathsToNodeIds;

UA_UInt32
UA_ServerConfig_getMaxNodesPerNodeManagement(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	RETVAL = config->svc_serverconfig->maxNodesPerNodeManagement;
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setMaxNodesPerNodeManagement(config, maxNodesPerNodeManagement)
	OPCUA_Open62541_ServerConfig	config
	UA_UInt32			maxNodesPerNodeManagement
    CODE:
	config->svc_serverconfig->maxNodesPerNodeManagement =
	    maxNodesPerNodeManagement;

UA_UInt32
UA_ServerConfig_getMaxMonitoredItemsPerCall(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	RETVAL = config->svc_serverconfig->maxMonitoredItemsPerCall;
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setMaxMonitoredItemsPerCall(config, maxMonitoredItemsPerCall)
	OPCUA_Open62541_ServerConfig	config
	UA_UInt32			maxMonitoredItemsPerCall
    CODE:
	config->svc_serverconfig->maxMonitoredItemsPerCall =
	    maxMonitoredItemsPerCall;

# Limits for Subscriptions

UA_UInt32
UA_ServerConfig_getMaxSubscriptions(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	RETVAL = config->svc_serverconfig->maxSubscriptions;
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setMaxSubscriptions(config, maxSubscriptions)
	OPCUA_Open62541_ServerConfig	config
	UA_UInt32			maxSubscriptions
    CODE:
	config->svc_serverconfig->maxSubscriptions = maxSubscriptions;

UA_UInt32
UA_ServerConfig_getMaxSubscriptionsPerSession(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	RETVAL = config->svc_serverconfig->maxSubscriptionsPerSession;
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setMaxSubscriptionsPerSession(config, maxSubscriptionsPerSession)
	OPCUA_Open62541_ServerConfig	config
	UA_UInt32			maxSubscriptionsPerSession
    CODE:
	config->svc_serverconfig->maxSubscriptionsPerSession =
	    maxSubscriptionsPerSession;

UA_UInt32
UA_ServerConfig_getMaxNotificationsPerPublish(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	RETVAL = config->svc_serverconfig->maxNotificationsPerPublish;
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setMaxNotificationsPerPublish(config, maxNotificationsPerPublish)
	OPCUA_Open62541_ServerConfig	config
	UA_UInt32			maxNotificationsPerPublish
    CODE:
	config->svc_serverconfig->maxNotificationsPerPublish =
	    maxNotificationsPerPublish;

UA_Boolean
UA_ServerConfig_getEnableRetransmissionQueue(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	RETVAL = config->svc_serverconfig->enableRetransmissionQueue;
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setEnableRetransmissionQueue(config, enableRetransmissionQueue)
	OPCUA_Open62541_ServerConfig	config
	UA_Boolean			enableRetransmissionQueue
    CODE:
	config->svc_serverconfig->enableRetransmissionQueue =
	    enableRetransmissionQueue;

UA_UInt32
UA_ServerConfig_getMaxRetransmissionQueueSize(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	RETVAL = config->svc_serverconfig->maxRetransmissionQueueSize;
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setMaxRetransmissionQueueSize(config, maxRetransmissionQueueSize)
	OPCUA_Open62541_ServerConfig	config
	UA_UInt32			maxRetransmissionQueueSize
    CODE:
	config->svc_serverconfig->maxRetransmissionQueueSize = maxRetransmissionQueueSize;

#ifdef UA_ENABLE_SUBSCRIPTIONS_EVENTS

UA_UInt32
UA_ServerConfig_getMaxEventsPerNode(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	RETVAL = config->svc_serverconfig->maxEventsPerNode;
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setMaxEventsPerNode(config, maxEventsPerNode)
	OPCUA_Open62541_ServerConfig	config
	UA_UInt32			maxEventsPerNode
    CODE:
	config->svc_serverconfig->maxEventsPerNode = maxEventsPerNode;

#endif /* UA_ENABLE_SUBSCRIPTIONS_EVENTS */


# AccessControl plugin callbacks

void
UA_ServerConfig_setUserRightsMaskReadonly(config, readonly);
	OPCUA_Open62541_ServerConfig	config
	SV *				readonly
    CODE:
	if (SvTRUE(readonly))
		config->svc_serverconfig->accessControl.getUserRightsMask =
		    getUserRightsMask_readonly;
	else
		config->svc_serverconfig->accessControl.getUserRightsMask =
		    getUserRightsMask_default;

void
UA_ServerConfig_setUserAccessLevelReadonly(config, readonly);
	OPCUA_Open62541_ServerConfig	config
	SV *				readonly
    CODE:
	if (SvTRUE(readonly))
		config->svc_serverconfig->accessControl.getUserAccessLevel =
		    getUserAccessLevel_readonly;
	else
		config->svc_serverconfig->accessControl.getUserAccessLevel =
		    getUserAccessLevel_default;

void
UA_ServerConfig_disableUserExecutable(config, disable);
	OPCUA_Open62541_ServerConfig	config
	SV *				disable
    CODE:
	if (SvTRUE(disable))
		config->svc_serverconfig->accessControl.getUserExecutable =
		    getUserExecutable_false;
	else
		config->svc_serverconfig->accessControl.getUserExecutable =
		    getUserExecutable_default;

void
UA_ServerConfig_disableUserExecutableOnObject(config, disable);
	OPCUA_Open62541_ServerConfig	config
	SV *				disable
    CODE:
	if (SvTRUE(disable))
		config->svc_serverconfig->accessControl.getUserExecutableOnObject =
		    getUserExecutableOnObject_false;
	else
		config->svc_serverconfig->accessControl.getUserExecutableOnObject =
		    getUserExecutableOnObject_default;

void
UA_ServerConfig_disableAddNode(config, disable);
	OPCUA_Open62541_ServerConfig	config
	SV *				disable
    CODE:
	if (SvTRUE(disable))
		config->svc_serverconfig->accessControl.allowAddNode =
		    allowAddNode_false;
	else
		config->svc_serverconfig->accessControl.allowAddNode =
		    allowAddNode_default;

void
UA_ServerConfig_disableAddReference(config, disable);
	OPCUA_Open62541_ServerConfig	config
	SV *				disable
    CODE:
	if (SvTRUE(disable))
		config->svc_serverconfig->accessControl.allowAddReference =
		    allowAddReference_false;
	else
		config->svc_serverconfig->accessControl.allowAddReference =
		    allowAddReference_default;

void
UA_ServerConfig_disableDeleteNode(config, disable);
	OPCUA_Open62541_ServerConfig	config
	SV *				disable
    CODE:
	if (SvTRUE(disable))
		config->svc_serverconfig->accessControl.allowDeleteNode =
		    allowDeleteNode_false;
	else
		config->svc_serverconfig->accessControl.allowDeleteNode =
		    allowDeleteNode_default;

void
UA_ServerConfig_disableDeleteReference(config, disable);
	OPCUA_Open62541_ServerConfig	config
	SV *				disable
    CODE:
	if (SvTRUE(disable))
		config->svc_serverconfig->accessControl.allowDeleteReference =
		    allowDeleteReference_false;
	else
		config->svc_serverconfig->accessControl.allowDeleteReference =
		    allowDeleteReference_default;

#ifdef UA_ENABLE_HISTORIZING

void
UA_ServerConfig_disableHistoryUpdateUpdateData(config, disable);
	OPCUA_Open62541_ServerConfig	config
	SV *				disable
    CODE:
	if (SvTRUE(disable))
		config->svc_serverconfig->accessControl.allowHistoryUpdateUpdateData =
		    allowHistoryUpdateUpdateData_false;
	else
		config->svc_serverconfig->accessControl.allowHistoryUpdateUpdateData =
		    allowHistoryUpdateUpdateData_default;

void
UA_ServerConfig_disableHistoryUpdateDeleteRawModified(config, disable);
	OPCUA_Open62541_ServerConfig	config
	SV *				disable
    CODE:
	if (SvTRUE(disable))
		config->svc_serverconfig->accessControl.allowHistoryUpdateDeleteRawModified =
		    allowHistoryUpdateDeleteRawModified_false;
	else
		config->svc_serverconfig->accessControl.allowHistoryUpdateDeleteRawModified =
		    allowHistoryUpdateDeleteRawModified_default;

#endif /* UA_ENABLE_HISTORIZING */

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
	RETVAL->cl_config.clc_clientconfig =
	    UA_Client_getConfig(RETVAL->cl_client);
	if (RETVAL->cl_config.clc_clientconfig == NULL) {
		UA_Client_delete(RETVAL->cl_client);
		free(RETVAL);
		CROAKE("UA_Client_getConfig");
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
	DPRINTF("client %p, cl_client %p, config %p, clc_clientconfig %p",
	    client, client->cl_client, RETVAL, RETVAL->clc_clientconfig);
	/* When client goes out of scope, config still uses its memory. */
	RETVAL->clc_storage = SvREFCNT_inc(SvRV(ST(0)));
	/*
	 * Set clientContext to OPCUA_Open62541_Client.  This will allow
	 * us to reach back from the UA client to the XS client.  The
	 * SV is created on the stack during OUTPUT.
	 */
	client->cl_config.clc_clientconfig->clientContext = ST(0);
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

#ifdef HAVE_UA_CLIENT_CONNECTASYNC

# XXX UA_Client_connectAsync not implemented

#else /* HAVE_UA_CLIENT_CONNECTASYNC */

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

#endif /* HAVE_UA_CLIENT_CONNECTASYNC */

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

#ifndef HAVE_UA_CLIENT_CONNECTASYNC

UA_StatusCode
UA_Client_disconnect_async(client, outoptReqId)
	OPCUA_Open62541_Client		client
	OPCUA_Open62541_UInt32		outoptReqId
    CODE:
	RETVAL = UA_Client_disconnect_async(client->cl_client, outoptReqId);
	if (outoptReqId != NULL)
		XS_pack_UA_UInt32(SvRV(ST(1)), *outoptReqId);
    OUTPUT:
	RETVAL

#endif /* HAVE_UA_CLIENT_CONNECTASYNC */

#ifdef HAVE_UA_CLIENT_GETSTATE_3

SV *
UA_Client_getState(client)
	OPCUA_Open62541_Client		client
    PREINIT:
	UA_SecureChannelState		channelState;
	UA_SessionState			sessionState;
	UA_StatusCode			connectStatus;
	int				clientState;
    CODE:
	UA_Client_getState(client->cl_client,
	    &channelState, &sessionState, &connectStatus);
	switch (GIMME_V) {
	case G_ARRAY:
		/* open62541 1.1 API gets 3 values, return them as array. */
		EXTEND(SP, 3);
		/* Use IV for enum. */
		ST(0) = sv_2mortal(newSViv(channelState));
		ST(1) = sv_2mortal(newSViv(sessionState));
		/* Use magic status code. */
		ST(2) = sv_newmortal();
		XS_pack_UA_StatusCode(ST(2), connectStatus);
		XSRETURN(3);
		break;
	case G_SCALAR:
		/* open62541 1.0 API returns the client state. */
		/* XXX This is just a rough guess to get the tests pass. */
		switch (sessionState) {
		case UA_SESSIONSTATE_CLOSED:
			clientState = 0;
			/* UA_CLIENTSTATE_DISCONNECTED */
			break;
		case UA_SESSIONSTATE_CREATE_REQUESTED:
			clientState = 1;
			/* UA_CLIENTSTATE_WAITING_FOR_ACK */
			break;
		case UA_SESSIONSTATE_CREATED:
			clientState = 2;
			/* UA_CLIENTSTATE_CONNECTED */
			break;
		case UA_SESSIONSTATE_ACTIVATE_REQUESTED:
			clientState = 2;
			/* UA_CLIENTSTATE_CONNECTED */
			break;
		case UA_SESSIONSTATE_ACTIVATED:
			clientState = 4;
			/* UA_CLIENTSTATE_SESSION */
			break;
		case UA_SESSIONSTATE_CLOSING:
			clientState = 5;
			/* UA_CLIENTSTATE_SESSION_DISCONNECTED */
			break;
		default:
			clientState = 0;
			break;
		}
		RETVAL = newSViv(clientState);
		break;
	default:
		RETVAL = &PL_sv_undef;
		break;
	}
    OUTPUT:
	RETVAL

#else /* HAVE_UA_CLIENT_GETSTATE_3 */

UA_ClientState
UA_Client_getState(client)
	OPCUA_Open62541_Client		client
    CODE:
	/* open62541 1.0 API returns client state. */
	RETVAL = UA_Client_getState(client->cl_client);
    OUTPUT:
	RETVAL

#endif /* HAVE_UA_CLIENT_GETSTATE_3 */

UA_StatusCode
UA_Client_sendAsyncBrowseRequest(client, request, callback, data, outoptReqId)
	OPCUA_Open62541_Client		client
	OPCUA_Open62541_BrowseRequest	request
	SV *				callback
	SV *				data
	OPCUA_Open62541_UInt32		outoptReqId
    PREINIT:
	ClientCallbackData		ccd;
    CODE:
	ccd = newClientCallbackData(callback, ST(0), data);
	RETVAL = UA_Client_sendAsyncBrowseRequest(client->cl_client, request,
	    clientAsyncBrowseCallback, ccd, outoptReqId);
	if (RETVAL != UA_STATUSCODE_GOOD)
		deleteClientCallbackData(ccd);
	if (outoptReqId != NULL)
		XS_pack_UA_UInt32(SvRV(ST(4)), *outoptReqId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_sendAsyncBrowseNextRequest(client, request, callback, data, outoptReqId)
	OPCUA_Open62541_Client		client
	OPCUA_Open62541_BrowseNextRequest	request
	SV *				callback
	SV *				data
	OPCUA_Open62541_UInt32		outoptReqId
    PREINIT:
	ClientCallbackData		ccd;
    CODE:
	ccd = newClientCallbackData(callback, ST(0), data);
	RETVAL = UA_Client_sendAsyncRequest(client->cl_client, request,
	    &UA_TYPES[UA_TYPES_BROWSENEXTREQUEST],
	    (UA_ClientAsyncServiceCallback)clientAsyncBrowseNextCallback,
	    &UA_TYPES[UA_TYPES_BROWSENEXTRESPONSE], ccd, outoptReqId);
	if (RETVAL != UA_STATUSCODE_GOOD)
		deleteClientCallbackData(ccd);
	if (outoptReqId != NULL)
		XS_pack_UA_UInt32(SvRV(ST(4)), *outoptReqId);
    OUTPUT:
	RETVAL

UA_BrowseResponse
UA_Client_Service_browse(client, request)
	OPCUA_Open62541_Client		client
	OPCUA_Open62541_BrowseRequest	request
    CODE:
	RETVAL = UA_Client_Service_browse(client->cl_client, *request);
    OUTPUT:
	RETVAL

# 12.7.1 Highlevel Client Functionality

INCLUDE: Open62541-client-read-write.xsh

UA_StatusCode
UA_Client_readDataTypeAttribute(client, nodeId, outDataType)
	OPCUA_Open62541_Client		client
	OPCUA_Open62541_NodeId		nodeId
	SV *				outDataType
    PREINIT:
	UA_NodeId			outNodeId;
	UV				index;
    CODE:
	RETVAL = UA_Client_readDataTypeAttribute(client->cl_client,
	    *nodeId, &outNodeId);
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

UA_StatusCode
UA_Client_sendAsyncReadRequest(client, request, callback, data, outoptReqId)
	OPCUA_Open62541_Client		client
	OPCUA_Open62541_ReadRequest	request
	SV *				callback
	SV *				data
	OPCUA_Open62541_UInt32		outoptReqId
    PREINIT:
	ClientCallbackData		ccd;
    CODE:
	ccd = newClientCallbackData(callback, ST(0), data);
	RETVAL = UA_Client_sendAsyncRequest(client->cl_client, request,
	    &UA_TYPES[UA_TYPES_READREQUEST],
	    (UA_ClientAsyncServiceCallback)clientAsyncReadCallback,
	    &UA_TYPES[UA_TYPES_READRESPONSE], ccd, outoptReqId);
	if (RETVAL != UA_STATUSCODE_GOOD)
		deleteClientCallbackData(ccd);
	if (outoptReqId != NULL)
		XS_pack_UA_UInt32(SvRV(ST(4)), *outoptReqId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_writeDataTypeAttribute(client, nodeId, newDataType)
	OPCUA_Open62541_Client		client
	OPCUA_Open62541_NodeId		nodeId
	OPCUA_Open62541_DataType	newDataType
    CODE:
	RETVAL = UA_Client_writeDataTypeAttribute(client->cl_client,
	    *nodeId, &newDataType->typeId);
    OUTPUT:
	RETVAL

# 12.7.2 Subscriptions

UA_CreateSubscriptionRequest
UA_Client_CreateSubscriptionRequest_default(class)
	char *	class
    CODE:
	(void)class;
	RETVAL = UA_CreateSubscriptionRequest_default();
    OUTPUT:
	RETVAL

UA_CreateSubscriptionResponse
UA_Client_Subscriptions_create(client, request, subscriptionContext, statusChangeCallback, deleteCallback)
	OPCUA_Open62541_Client				client
	OPCUA_Open62541_CreateSubscriptionRequest	request
	SV *						subscriptionContext
	SV *						statusChangeCallback
	SV *						deleteCallback
    PREINIT:
	SubscriptionContext				sub;
    CODE:
	sub = calloc(1, sizeof(*sub));
	if (sub == NULL)
		CROAKE("calloc");
	if (SvOK(subscriptionContext))
		sub->sc_context = SvREFCNT_inc(subscriptionContext);
	if (SvOK(statusChangeCallback))
		sub->sc_change = newClientCallbackData(
		    statusChangeCallback, ST(0), subscriptionContext);
	if (SvOK(deleteCallback))
		sub->sc_delete = newClientCallbackData(
		    deleteCallback, ST(0), subscriptionContext);

	RETVAL = UA_Client_Subscriptions_create(client->cl_client, *request,
	    sub, clientStatusChangeNotificationCallback,
	    clientDeleteSubscriptionCallback);

	if (RETVAL.responseHeader.serviceResult != UA_STATUSCODE_GOOD) {
		if (sub->sc_delete)
			deleteClientCallbackData(sub->sc_delete);
		if (sub->sc_change)
			deleteClientCallbackData(sub->sc_change);
		if (sub->sc_context)
			SvREFCNT_dec(sub->sc_context);
		free(sub);
	}
    OUTPUT:
	RETVAL

UA_ModifySubscriptionResponse
UA_Client_Subscriptions_modify(client, request)
	OPCUA_Open62541_Client				client
	OPCUA_Open62541_ModifySubscriptionRequest	request
    CODE:
	RETVAL = UA_Client_Subscriptions_modify(client->cl_client, *request);
    OUTPUT:
	RETVAL

UA_DeleteSubscriptionsResponse
UA_Client_Subscriptions_delete(client, request)
	OPCUA_Open62541_Client				client
	OPCUA_Open62541_DeleteSubscriptionsRequest	request
    CODE:
	RETVAL = UA_Client_Subscriptions_delete(client->cl_client, *request);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_Subscriptions_deleteSingle(client, subscriptionId)
	OPCUA_Open62541_Client	client
	UA_UInt32		subscriptionId
    CODE:
	RETVAL = UA_Client_Subscriptions_deleteSingle(client->cl_client, subscriptionId);
    OUTPUT:
	RETVAL

UA_SetPublishingModeResponse
UA_Client_Subscriptions_setPublishingMode(client, request)
	OPCUA_Open62541_Client				client
	OPCUA_Open62541_SetPublishingModeRequest	request
    CODE:
	RETVAL = UA_Client_Subscriptions_setPublishingMode(client->cl_client, *request);
    OUTPUT:
	RETVAL

UA_MonitoredItemCreateRequest
UA_Client_MonitoredItemCreateRequest_default(class, nodeId)
	char *			class
	OPCUA_Open62541_NodeId	nodeId
    PREINIT:
	UA_NodeId		ni;
	UA_StatusCode		sc;
    CODE:
	(void)class;
	/*
	 * The new monitored item create request will contain a
	 * copy of the given node Id.  It will manage its memory.
	 * So we have to duplicate the node Id.
	 */
	sc = UA_NodeId_copy(nodeId, &ni);
	if (sc != UA_STATUSCODE_GOOD)
		CROAKS(sc, "UA_NodeId_copy");
	RETVAL = UA_MonitoredItemCreateRequest_default(ni);
    OUTPUT:
	RETVAL

UA_CreateMonitoredItemsResponse
UA_Client_MonitoredItems_createDataChanges(client, request, contextsSV, callbacksSV, deleteCallbacksSV)
	OPCUA_Open62541_Client				client
	OPCUA_Open62541_CreateMonitoredItemsRequest	request
	SV *						contextsSV
	SV *						callbacksSV
	SV *						deleteCallbacksSV
    INIT:
	size_t						itemsToCreateSize;
	size_t						i;
	ssize_t						top;
	UA_Client_DataChangeNotificationCallback *	callbacks;
	UA_Client_DeleteMonitoredItemCallback *		deleteCallbacks;
	AV *						contextsAV;
	AV *						callbacksAV;
	AV *						deleteCallbacksAV;
	SV **						contextSV;
	SV **						callbackSV;
	SV **						deleteCallbackSV;
	MonitoredItemContext *				mons;
	SV *						sv;
    CODE:
	itemsToCreateSize = request->itemsToCreateSize;

	if (SvOK(contextsSV)) {
		if (!SvROK(contextsSV) || SvTYPE(SvRV(contextsSV)) != SVt_PVAV)
			CROAK("Not an ARRAY reference for contexts");

		contextsAV = (AV*)SvRV(contextsSV);

		top = av_top_index(contextsAV);
		if (top == -1)
			CROAK("No elements in contexts");
		if ((size_t)(top + 1) != itemsToCreateSize)
			CROAK("Not enough elements in contexts");
	} else {
		contextsAV = NULL;
	}
	if (SvOK(callbacksSV)) {
		if (!SvROK(callbacksSV) || SvTYPE(SvRV(callbacksSV)) != SVt_PVAV)
			CROAK("Not an ARRAY reference for callbacks");

		callbacksAV = (AV*)SvRV(callbacksSV);

		top = av_top_index(callbacksAV);
		if (top == -1)
			CROAK("No elements in callbacks");
		if ((size_t)(top + 1) != itemsToCreateSize)
			CROAK("Not enough elements in callbacks");
	} else {
		callbacksAV = NULL;
	}
	if (SvOK(deleteCallbacksSV)) {
		if (!SvROK(deleteCallbacksSV) || SvTYPE(SvRV(deleteCallbacksSV)) != SVt_PVAV)
			CROAK("Not an ARRAY reference for deleteCallbacks");

		deleteCallbacksAV = (AV*)SvRV(deleteCallbacksSV);

		top = av_top_index(deleteCallbacksAV);
		if (top == -1)
			CROAK("No elements in deleteCallbacks");
		if ((size_t)(top + 1) != itemsToCreateSize)
			CROAK("Not enough elements in deleteCallbacks");
	} else {
		deleteCallbacksAV = NULL;
	}

	callbacks = calloc(itemsToCreateSize,
	    sizeof(UA_Client_DataChangeNotificationCallback*));
	if (callbacks == NULL)
		CROAKE("calloc");

	deleteCallbacks = calloc(itemsToCreateSize,
	    sizeof(UA_Client_DeleteMonitoredItemCallback*));
	if (deleteCallbacks == NULL)
		CROAKE("calloc");

	mons = calloc(itemsToCreateSize, sizeof(*mons));
	if (mons == NULL)
		CROAKE("calloc");

	for (i = 0; i < itemsToCreateSize; i++) {
		mons[i] = calloc(2, sizeof(**mons));
		if (mons[i] == NULL)
			CROAKE("calloc");

		if (contextsAV != NULL)
			contextSV = av_fetch(contextsAV, i, 0);
		else {
			sv = sv_2mortal(newSV(0));
			contextSV = &sv;
		}

		if (callbacksAV != NULL)
			callbackSV = av_fetch(callbacksAV, i, 0);
		else
			callbackSV = NULL;

		if (deleteCallbacksAV != NULL)
			deleteCallbackSV = av_fetch(deleteCallbacksAV, i, 0);
		else
			deleteCallbackSV = NULL;

		if (callbackSV != NULL && SvOK(*callbackSV))
			mons[i]->mc_change = newClientCallbackData(
			    *callbackSV, ST(0), *contextSV);

		if (deleteCallbackSV != NULL && SvOK(*deleteCallbackSV))
			mons[i]->mc_delete = newClientCallbackData(
			    *deleteCallbackSV, ST(0), *contextSV);

		callbacks[i] = clientDataChangeNotificationCallback;
		deleteCallbacks[i] = clientDeleteMonitoredItemCallback;
	}

	RETVAL = UA_Client_MonitoredItems_createDataChanges(client->cl_client,
	    *request, (void **)mons, callbacks, deleteCallbacks);
    OUTPUT:
	RETVAL

UA_MonitoredItemCreateResult
UA_Client_MonitoredItems_createDataChange(client, subscriptionId, timestampsToReturn, item, context, callback, deleteCallback)
	OPCUA_Open62541_Client				client
	UA_UInt32					subscriptionId
	UA_TimestampsToReturn				timestampsToReturn
	OPCUA_Open62541_MonitoredItemCreateRequest	item
	SV *						context
	SV *						callback
	SV *						deleteCallback
    PREINIT:
	MonitoredItemContext				mon;
    CODE:
	mon = calloc(1, sizeof(*mon));
	if (mon == NULL)
		CROAKE("calloc");
	if (SvOK(callback))
		mon->mc_change = newClientCallbackData(
		    callback, ST(0), context);
	if (SvOK(deleteCallback))
		mon->mc_delete = newClientCallbackData(
		    deleteCallback, ST(0), context);

	RETVAL = UA_Client_MonitoredItems_createDataChange(client->cl_client,
	    subscriptionId, timestampsToReturn, *item, mon,
	    clientDataChangeNotificationCallback,
	    clientDeleteMonitoredItemCallback);
    OUTPUT:
	RETVAL

UA_DeleteMonitoredItemsResponse
UA_Client_MonitoredItems_delete(client, request)
	OPCUA_Open62541_Client				client
	OPCUA_Open62541_DeleteMonitoredItemsRequest	request
    CODE:
	RETVAL = UA_Client_MonitoredItems_delete(client->cl_client, *request);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_MonitoredItems_deleteSingle(client, subscriptionId, monitoredItemId)
	OPCUA_Open62541_Client	client
	UA_UInt32		subscriptionId
	UA_UInt32		monitoredItemId
    CODE:
	RETVAL = UA_Client_MonitoredItems_deleteSingle(client->cl_client,
	    subscriptionId, monitoredItemId);
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
	/*
	 * XXX The client context and state callback should live longer than
	 * the config.  They should live until the client dies, but reference
	 * counting the client SV in the client object does not work.
	 */
	config->clc_clientconfig->clientContext = NULL;
	config->clc_clientconfig->stateCallback = NULL;
	SvREFCNT_dec(config->clc_clientcontext);
	SvREFCNT_dec(config->clc_statecallback);
	/* Delayed client destroy after client config destroy. */
	SvREFCNT_dec(config->clc_storage);

UA_StatusCode
UA_ClientConfig_setDefault(config)
	OPCUA_Open62541_ClientConfig	config
    PREINIT:
	SV *				client;
    CODE:
	client = config->clc_clientconfig->clientContext;
	RETVAL = UA_ClientConfig_setDefault(config->clc_clientconfig);
	config->clc_clientconfig->clientContext = client;
    OUTPUT:
	RETVAL

SV *
UA_ClientConfig_getClientContext(config)
	OPCUA_Open62541_ClientConfig	config
    CODE:
	RETVAL = newSVsv(config->clc_clientcontext);
    OUTPUT:
	RETVAL

void
UA_ClientConfig_setClientContext(config, context)
	OPCUA_Open62541_ClientConfig	config
	SV *				context
    CODE:
	SvREFCNT_dec(config->clc_clientcontext);
	config->clc_clientcontext = newSVsv(context);

void
UA_ClientConfig_setStateCallback(config, callback)
	OPCUA_Open62541_ClientConfig	config
	SV *				callback
    INIT:
	if (SvOK(callback) &&
	    !(SvROK(callback) && SvTYPE(SvRV(callback)) == SVt_PVCV)) {
		CROAK("Context '%s' is not a CODE reference",
		    SvPV_nolen(callback));
	}
    CODE:
	SvREFCNT_dec(config->clc_statecallback);
	if (SvOK(callback)) {
		config->clc_statecallback = newSVsv(callback);
		config->clc_clientconfig->stateCallback = clientStateCallback;
	} else {
		config->clc_statecallback = NULL;
		config->clc_clientconfig->stateCallback = NULL;
	}

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
