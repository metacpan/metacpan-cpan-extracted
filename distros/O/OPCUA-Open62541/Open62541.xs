/*
 * Copyright (c) 2020-2023 Alexander Bluhm
 * Copyright (c) 2020-2023 Anton Borowka
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
#include <open62541/plugin/pki.h>
#include <open62541/plugin/pki_default.h>
#include <open62541/plugin/accesscontrol_default.h>

#include <pwd.h>
#include <unistd.h>

//#define DEBUG
#ifdef DEBUG
# define DPRINTF(fmt, args...)						\
	fprintf(stderr, "%s: " fmt "\n", __func__, ##args)
#else
# define DPRINTF(fmt, x...)
#endif

/*
 * Define a constant for buffer overflow checks.
 *
 * This is sqrt(SIZE_MAX+1), as s1*s2 <= SIZE_MAX
 * if both s1 < MUL_NO_OVERFLOW and s2 < MUL_NO_OVERFLOW
 */
#define MUL_NO_OVERFLOW	(1UL << (sizeof(size_t) * 4))

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

typedef struct MonitoredItemContext {
	ClientCallbackData	mc_change;
	ClientCallbackData	mc_delete;
	SV *			mc_arrays;
} * MonitoredItemContext;

typedef struct MonitoredItemArrays {
	MonitoredItemContext				ma_mon;
	void **						ma_context;
	UA_Client_DataChangeNotificationCallback *	ma_change;
	UA_Client_DeleteMonitoredItemCallback *		ma_delete;
} * OPCUA_Open62541_MonitoredItemArrays;

static UA_UInt16
dataType2Index(OPCUA_Open62541_DataType dataType)
{
	if (dataType < &UA_TYPES[0] || dataType >= &UA_TYPES[UA_TYPES_COUNT])
		CROAK("DataType %p is not in UA_TYPES %p array",
		    dataType, UA_TYPES);
	return (dataType - UA_TYPES);
}

static void XS_pack_OPCUA_Open62541_DataType(SV *out,
    OPCUA_Open62541_DataType in) __attribute__((unused));
static OPCUA_Open62541_DataType XS_unpack_OPCUA_Open62541_DataType(SV *in)
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

static void
pack_UA_Boolean(SV *out, const UA_Boolean *in)
{
	dTHX;
	sv_setsv(out, boolSV(*in));
}

static void
unpack_UA_Boolean(UA_Boolean *out, SV *in)
{
	dTHX;
	*out = SvTRUE(in);
}

/* 6.1.2 SByte ... 6.1.9 UInt64, types.h */

#define PACKED_CHECK_IV(type, limit)					\
									\
static void								\
pack_UA_##type(SV *out, const UA_##type *in)				\
{									\
	dTHX;								\
	sv_setiv(out, *in);						\
}									\
									\
static void								\
unpack_UA_##type(UA_##type *out, SV *in)				\
{									\
	dTHX;								\
	IV iv = SvIV(in);						\
									\
	*out = iv;							\
	if (iv < UA_##limit##_MIN)					\
		CROAK("Integer value %li less than UA_"			\
		    #limit "_MIN", iv);					\
	if (iv > UA_##limit##_MAX)					\
		CROAK("Integer value %li greater than UA_"		\
		    #limit "_MAX", iv);					\
}

#define PACKED_CHECK_UV(type, limit)					\
									\
static void								\
pack_UA_##type(SV *out, const UA_##type *in)				\
{									\
	dTHX;								\
	sv_setuv(out, *in);						\
}									\
									\
static void								\
unpack_UA_##type(UA_##type *out, SV *in)				\
{									\
	dTHX;								\
	UV uv = SvUV(in);						\
									\
	*out = uv;							\
	if (uv > UA_##limit##_MAX)					\
		CROAK("Unsigned value %lu greater than UA_"		\
		    #limit "_MAX", uv);					\
}

PACKED_CHECK_IV(SByte, SBYTE)		/* 6.1.2 SByte, types.h */
PACKED_CHECK_UV(Byte, BYTE)		/* 6.1.3 Byte, types.h */
PACKED_CHECK_IV(Int16, INT16)		/* 6.1.4 Int16, types.h */
PACKED_CHECK_UV(UInt16, UINT16)		/* 6.1.5 UInt16, types.h */
PACKED_CHECK_IV(Int32, INT32)		/* 6.1.6 Int32, types.h */
PACKED_CHECK_UV(UInt32, UINT32)		/* 6.1.7 UInt32, types.h */
/* XXX this only works for Perl on 64 bit platforms */
PACKED_CHECK_IV(Int64, INT64)		/* 6.1.8 Int64, types.h */
PACKED_CHECK_UV(UInt64, UINT64)		/* 6.1.9 UInt64, types.h */

#undef PACKED_CHECK_IV
#undef PACKED_CHECK_UV

/* 6.1.10 Float, types.h */

static void
pack_UA_Float(SV *out, const UA_Float *in)
{
	dTHX;
	sv_setnv(out, *in);
}

static void
unpack_UA_Float(UA_Float *out, SV *in)
{
	dTHX;
	NV nv = SvNV(in);

	*out = nv;
	if (Perl_isinfnan(nv))
		return;
	if (nv < -FLT_MAX)
		CROAK("Float value %le less than %le", nv, -FLT_MAX);
	if (nv > FLT_MAX)
		CROAK("Float value %le greater than %le", nv, FLT_MAX);
}

/* 6.1.11 Double, types.h */

static void
pack_UA_Double(SV *out, const UA_Double *in)
{
	dTHX;
	sv_setnv(out, *in);
}

static void
unpack_UA_Double(UA_Double *out, SV *in)
{
	dTHX;
	*out = SvNV(in);
}

/* 6.1.12 StatusCode, types.h */

static void
pack_UA_StatusCode(SV *out, const UA_StatusCode *in)
{
	dTHX;
	const char *name;

	/* SV out contains number and string, like $! does. */
	sv_setnv(out, *in);
	name = UA_StatusCode_name(*in);
	if (name[0] != '\0' && strcmp(name, "Unknown StatusCode") != 0)
		sv_setpv(out, name);
	else
		sv_setuv(out, *in);
	SvNOK_on(out);
}

static void
unpack_UA_StatusCode(UA_StatusCode *out, SV *in)
{
	dTHX;
	*out = SvUV(in);
}

/* 6.1.13 String, types.h */

static void
pack_UA_String(SV *out, const UA_String *in)
{
	dTHX;
	if (in->data == NULL) {
		/* Convert NULL string to undef. */
		sv_set_undef(out);
		return;
	}
	sv_setpvn(out, in->data, in->length);
	SvUTF8_on(out);
}

static void
unpack_UA_String(UA_String *out, SV *in)
{
	dTHX;
	char *str;

	if (!SvOK(in)) {
		UA_String_init(out);
		return;
	}

	str = SvPVutf8(in, out->length);
	if (out->length > 0) {
		out->data = UA_malloc(out->length);
		if (out->data == NULL)
			CROAKE("UA_malloc size %zu", out->length);
		memcpy(out->data, str, out->length);
	} else {
		out->data = UA_EMPTY_ARRAY_SENTINEL;
	}
}

/* 6.1.14 DateTime, types.h */

static void
pack_UA_DateTime(SV *out, const UA_DateTime *in)
{
	dTHX;
	sv_setiv(out, *in);
}

static void
unpack_UA_DateTime(UA_DateTime *out, SV *in)
{
	dTHX;
	*out = SvIV(in);
}

/* 6.1.15 Guid, types.h */

static void
pack_UA_Guid(SV *out, const UA_Guid *in)
{
	dTHX;

	/*
	 * Print the Guid format defined in Part 6, 5.1.3.
	 * Format: C496578A-0DFE-4B8F-870A-745238C6AEAE
	 */
	sv_setpvf(out, "%08X-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X",
	    in->data1, in->data2, in->data3, in->data4[0], in->data4[1],
	    in->data4[2], in->data4[3], in->data4[4],
	    in->data4[5], in->data4[6], in->data4[7]);
}

static void
unpack_UA_Guid(UA_Guid *out, SV *in)
{
	dTHX;
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
	out->data1 = data;
	if (errno != 0 || *end != '\0' || data > UA_UINT32_MAX)
		CROAK("Guid string '%s' for data1 is not hex number", num);

	memcpy(num, &str[9], 4);
	num[4] = '\0';
	data = strtol(num, &end, 16);
	out->data2 = data;
	if (errno != 0 || *end != '\0' || data > UA_UINT16_MAX)
		CROAK("Guid string '%s' for data2 is not hex number", num);

	memcpy(num, &str[14], 4);
	num[4] = '\0';
	data = strtol(num, &end, 16);
	out->data3 = data;
	if (errno != 0 || *end != '\0' || data > UA_UINT16_MAX)
		CROAK("Guid string '%s' for data3 is not hex number", num);

	for (i = 19, j = 0; i < len && j < 8; i += 2, j++) {
		if (i == 23)
			i++;
		memcpy(num, &str[i], 2);
		num[2] = '\0';
		data = strtol(num, &end, 16);
		out->data4[j] = data;
		if (errno != 0 || *end != '\0' || data > UA_BYTE_MAX)
			CROAK("Guid string '%s' for data4[%zu] "
			    "is not hex number", num, j);
	}

	errno = save_errno;
}

/* 6.1.16 ByteString, types.h */

static void
pack_UA_ByteString(SV *out, const UA_ByteString *in)
{
	dTHX;
	if (in->data == NULL) {
		/* Convert NULL string to undef. */
		sv_set_undef(out);
		return;
	}
	sv_setpvn(out, in->data, in->length);
}

static void
unpack_UA_ByteString(UA_ByteString *out, SV *in)
{
	dTHX;
	char *str;

	if (!SvOK(in)) {
		UA_ByteString_init(out);
		return;
	}

	str = SvPV(in, out->length);
	if (out->length > 0) {
		out->data = UA_malloc(out->length);
		if (out->data == NULL)
			CROAKE("UA_malloc size %zu", out->length);
		memcpy(out->data, str, out->length);
	} else {
		out->data = UA_EMPTY_ARRAY_SENTINEL;
	}
}

static void
unpack_UA_ByteString_List(UA_ByteString **outList, size_t *outSize, SV *in)
{
	dTHX;
	AV *		av;
	SV *		sv;
	SV **		svp;
	UA_ByteString *	bs;
	size_t		i;

	*outList = NULL;
	*outSize = 0;

	if (SvOK(in)) {
		if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVAV) {
			CROAK("Not an ARRAY reference with ByteString list");
		}
		av = (AV*)SvRV(in);
		*outSize = av_top_index(av) + 1;
	}

	if (*outSize > 0) {
		if ((*outSize >= MUL_NO_OVERFLOW ||
		    sizeof(UA_ByteString) >= MUL_NO_OVERFLOW) &&
		    SIZE_MAX / *outSize < sizeof(UA_ByteString)) {
			CROAK("ByteString list too big");
		}
		sv = sv_2mortal(newSV(*outSize * sizeof(UA_ByteString)));
		*outList = (UA_ByteString *)SvPVX(sv);

		for (i = 0, bs = *outList; i < *outSize; i++, bs++) {
			svp = av_fetch(av, i, 0);

			if (svp == NULL || !SvOK(*svp)) {
				UA_ByteString_init(bs);
			} else {
				bs->data = SvPV(*svp, bs->length);
			}
		}
	}
}

/* 6.1.17 XmlElement, types.h */

static void
pack_UA_XmlElement(SV *out, const UA_XmlElement *in)
{
	pack_UA_String(out, in);
}

static void
unpack_UA_XmlElement(UA_XmlElement *out, SV *in)
{
	unpack_UA_String(out, in);
}

/* 6.1.18 NodeId, types.h */

static void
pack_UA_NodeId(SV *out, const UA_NodeId *in)
{
	dTHX;
	SV *sv;
	UA_Int32 type;
	UA_String print;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "NodeId_namespaceIndex", sv);
	pack_UA_UInt16(sv, &in->namespaceIndex);

	sv = newSV(0);
	hv_stores(hv, "NodeId_identifierType", sv);
	/* identifierType is enum UA_NodeIdType, convert to UA_Int32 */
	type = in->identifierType;
	pack_UA_Int32(sv, &type);

	sv = newSV(0);
	hv_stores(hv, "NodeId_identifier", sv);
	switch (in->identifierType) {
	case UA_NODEIDTYPE_NUMERIC:
		pack_UA_UInt32(sv, &in->identifier.numeric);
		break;
	case UA_NODEIDTYPE_STRING:
		pack_UA_String(sv, &in->identifier.string);
		break;
	case UA_NODEIDTYPE_GUID:
		pack_UA_Guid(sv, &in->identifier.guid);
		break;
	case UA_NODEIDTYPE_BYTESTRING:
		pack_UA_ByteString(sv, &in->identifier.byteString);
		break;
	default:
		CROAK("NodeId_identifierType %d unknown", in->identifierType);
	}

	/*
	 * For convenience add printable string based on XML encoding format.
	 * https://reference.opcfoundation.org/Core/Part6/v105/docs/5.3.1.10
	 */
	UA_String_init(&print);
	if (UA_NodeId_print(in, &print) == UA_STATUSCODE_GOOD) {
		sv = newSV(0);
		hv_stores(hv, "NodeId_print", sv);
		pack_UA_String(sv, &print);
		UA_String_clear(&print);
	}
}

static void
unpack_UA_NodeId(UA_NodeId *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in)) {
		/*
		 * There exists a node in UA_TYPES for each type.
		 * If we get passed a TYPES index, take this node.
		 */
		*out = XS_unpack_OPCUA_Open62541_DataType(in)->typeId;
		return;
	}
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_NodeId_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "NodeId_namespaceIndex", 0);
	if (svp == NULL)
		CROAK("No NodeId_namespaceIndex in HASH");
	unpack_UA_UInt16(&out->namespaceIndex, *svp);

	svp = hv_fetchs(hv, "NodeId_identifierType", 0);
	if (svp == NULL)
		CROAK("No NodeId_identifierType in HASH");
	out->identifierType = SvIV(*svp);

	svp = hv_fetchs(hv, "NodeId_identifier", 0);
	if (svp == NULL)
		CROAK("No NodeId_identifier in HASH");
	switch (out->identifierType) {
	case UA_NODEIDTYPE_NUMERIC:
		unpack_UA_UInt32(&out->identifier.numeric, *svp);
		break;
	case UA_NODEIDTYPE_STRING:
		unpack_UA_String(&out->identifier.string, *svp);
		break;
	case UA_NODEIDTYPE_GUID:
		unpack_UA_Guid(&out->identifier.guid, *svp);
		break;
	case UA_NODEIDTYPE_BYTESTRING:
		unpack_UA_ByteString(&out->identifier.byteString, *svp);
		break;
	default:
		CROAK("NodeId_identifierType %d unknown", out->identifierType);
	}
}

/* 6.1.19 ExpandedNodeId, types.h */

static void
pack_UA_ExpandedNodeId(SV *out, const UA_ExpandedNodeId *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ExpandedNodeId_nodeId", sv);
	pack_UA_NodeId(sv, &in->nodeId);

	sv = newSV(0);
	hv_stores(hv, "ExpandedNodeId_namespaceUri", sv);
	pack_UA_String(sv, &in->namespaceUri);

	sv = newSV(0);
	hv_stores(hv, "ExpandedNodeId_serverIndex", sv);
	pack_UA_UInt32(sv, &in->serverIndex);
}

static void
unpack_UA_ExpandedNodeId(UA_ExpandedNodeId *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ExpandedNodeId_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ExpandedNodeId_nodeId", 0);
	if (svp != NULL)
		unpack_UA_NodeId(&out->nodeId, *svp);

	svp = hv_fetchs(hv, "ExpandedNodeId_namespaceUri", 0);
	if (svp != NULL)
		unpack_UA_String(&out->namespaceUri, *svp);

	svp = hv_fetchs(hv, "ExpandedNodeId_serverIndex", 0);
	if (svp != NULL)
		unpack_UA_UInt32(&out->serverIndex, *svp);
}

/* 6.1.20 QualifiedName, types.h */

static void
pack_UA_QualifiedName(SV *out, const UA_QualifiedName *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "QualifiedName_namespaceIndex", sv);
	pack_UA_UInt16(sv, &in->namespaceIndex);

	sv = newSV(0);
	hv_stores(hv, "QualifiedName_name", sv);
	pack_UA_String(sv, &in->name);
}

static void
unpack_UA_QualifiedName(UA_QualifiedName *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_QualifiedName_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "QualifiedName_namespaceIndex", 0);
	if (svp != NULL)
		unpack_UA_UInt16(&out->namespaceIndex, *svp);

	svp = hv_fetchs(hv, "QualifiedName_name", 0);
	if (svp != NULL)
		unpack_UA_String(&out->name, *svp);
}

/* 6.1.21 LocalizedText, types.h */

static void
pack_UA_LocalizedText(SV *out, const UA_LocalizedText *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	if (in->locale.data != NULL) {
		sv = newSV(0);
		hv_stores(hv, "LocalizedText_locale", sv);
		pack_UA_String(sv, &in->locale);
	}

	sv = newSV(0);
	hv_stores(hv, "LocalizedText_text", sv);
	pack_UA_String(sv, &in->text);
}

static void
unpack_UA_LocalizedText(UA_LocalizedText *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_LocalizedText_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "LocalizedText_locale", 0);
	if (svp != NULL)
		unpack_UA_String(&out->locale, *svp);

	svp = hv_fetchs(hv, "LocalizedText_text", 0);
	if (svp != NULL)
		unpack_UA_String(&out->text, *svp);
}

/* 6.1.23 Variant, types.h */

typedef void (*packed_UA)(SV *, void *);
#include "Open62541-packed-type.xsh"

static void
OPCUA_Open62541_Variant_getScalar(const UA_Variant *variant, SV *out)
{
	UA_UInt16 index;

	index = dataType2Index(variant->type);
	if (pack_UA_table[index] == NULL) {
		CROAK("No pack conversion for type '%s' index %u",
		    variant->type->typeName, index);
	}
	(pack_UA_table[index])(out, variant->data);
}

static void
OPCUA_Open62541_Variant_getArray(const UA_Variant *variant, SV *out)
{
	dTHX;
	SV *sv;
	AV *av;
	char *p;
	size_t i;
	UA_UInt16 index;

	if (variant->data == NULL) {
		sv_set_undef(out);
		return;
	}
	index = dataType2Index(variant->type);
	if (pack_UA_table[index] == NULL) {
		CROAK("No pack conversion for type '%s' index %u",
		    variant->type->typeName, index);
	}

	av = newAV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)av)));
	av_extend(av, variant->arrayLength);
	p = variant->data;
	for (i = 0; i < variant->arrayLength; i++) {
		sv = newSV(0);
		av_push(av, sv);
		(pack_UA_table[index])(sv, p);
		p += variant->type->memSize;
	}
}

static void
OPCUA_Open62541_Variant_getArrayDimensions(const UA_Variant *variant, SV *out)
{
	dTHX;
	SV *sv;
	AV *av;
	UA_Int32 *p;
	size_t i;

	av = newAV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)av)));
	av_extend(av, variant->arrayDimensionsSize);
	p = variant->arrayDimensions;
	for (i = 0; i < variant->arrayDimensionsSize; i++) {
		sv = newSV(0);
		av_push(av, sv);
		pack_UA_UInt32(sv, p);
		p++;
	}
}

static void
pack_UA_Variant(SV *out, const UA_Variant *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));
	if (UA_Variant_isEmpty(in))
		return;

	sv = newSV(0);
	hv_stores(hv, "Variant_type", sv);
	XS_pack_OPCUA_Open62541_DataType(sv, in->type);

	if (UA_Variant_isScalar(in)) {
		sv = newSV(0);
		hv_stores(hv, "Variant_scalar", sv);
		OPCUA_Open62541_Variant_getScalar(in, sv);
	} else {
		sv = newSV(0);
		hv_stores(hv, "Variant_array", sv);
		OPCUA_Open62541_Variant_getArray(in, sv);

		if (in->arrayDimensions != NULL) {
			sv = newSV(0);
			hv_stores(hv, "Variant_arrayDimensions", sv);
			OPCUA_Open62541_Variant_getArrayDimensions(in, sv);
		}
	}
}

static void
OPCUA_Open62541_Variant_setScalar(OPCUA_Open62541_Variant variant, SV *in,
    OPCUA_Open62541_DataType type)
{
	void *scalar;
	UA_UInt16 index;

	index = dataType2Index(type);
	if (unpack_UA_table[index] == NULL) {
		CROAK("No unpack conversion for type '%s' index %u",
		    type->typeName, index);
	}

	scalar = UA_new(type);
	if (scalar == NULL) {
		CROAKE("UA_new type '%s' index %u",
		    type->typeName, index);
	}
	UA_Variant_setScalar(variant, scalar, type);
	(unpack_UA_table[index])(scalar, in);
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
	UA_UInt16 index;

	if (!SvOK(in)) {
		UA_Variant_setArray(variant, NULL, 0, type);
		return;
	}
	index = dataType2Index(type);
	if (unpack_UA_table[index] == NULL) {
		CROAK("No pack conversion for type '%s' index %u",
		    type->typeName, index);
	}

	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVAV)
		CROAK("Not an ARRAY reference");
	av = (AV*)SvRV(in);
	top = av_top_index(av);
	array = UA_Array_new(top + 1, type);
	if (array == NULL) {
		CROAKE("UA_Array_new size %zd, type '%s' index %u",
		    top + 1, type->typeName, index);
	}
	UA_Variant_setArray(variant, array, top + 1, type);
	p = array;
	for (i = 0; i <= top; i++) {
		svp = av_fetch(av, i, 0);
		if (svp != NULL)
			(unpack_UA_table[index])(p, *svp);
		p += type->memSize;
	}
}

static void
OPCUA_Open62541_Variant_setArrayDimensions(OPCUA_Open62541_Variant variant,
    SV *in)
{
	dTHX;
	SV **svp;
	AV *av;
	ssize_t i, top;
	UA_Int32 *p;
	void *array;

	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVAV)
		CROAK("Not an ARRAY reference");
	av = (AV*)SvRV(in);
	top = av_top_index(av);
	array = UA_Array_new(top + 1, &UA_TYPES[UA_TYPES_UINT32]);
	if (array == NULL)
		CROAKE("UA_Array_new size %zd", top + 1);
	variant->arrayDimensions = array;
	variant->arrayDimensionsSize = top + 1;
	p = array;
	for (i = 0; i <= top; i++) {
		svp = av_fetch(av, i, 0);
		if (svp != NULL)
			unpack_UA_UInt32(p, *svp);
		p++;
	}
}

static void
unpack_UA_Variant(UA_Variant *out, SV *in)
{
	dTHX;
	OPCUA_Open62541_DataType type;
	SV **svp, **scalar, **array, **dimensions;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_Variant_init(out);
	hv = (HV*)SvRV(in);

	if (hv_iterinit(hv) == 0)
		return;

	svp = hv_fetchs(hv, "Variant_type", 0);
	if (svp == NULL)
		CROAK("No Variant_type in HASH");
	type = XS_unpack_OPCUA_Open62541_DataType(*svp);

	scalar = hv_fetchs(hv, "Variant_scalar", 0);
	array = hv_fetchs(hv, "Variant_array", 0);
	dimensions = hv_fetchs(hv, "Variant_arrayDimensions", 0);
	if (scalar != NULL && array != NULL)
		CROAK("Both Variant_scalar and Variant_array in HASH");
	if (scalar == NULL && array == NULL)
		CROAK("Neither Variant_scalar nor Variant_array in HASH");
	if (array == NULL && dimensions != NULL)
		CROAK("Variant_arrayDimensions requires Variant_array in HASH");

	if (scalar != NULL)
		OPCUA_Open62541_Variant_setScalar(out, *scalar, type);
	if (array != NULL)
		OPCUA_Open62541_Variant_setArray(out, *array, type);
	if (dimensions != NULL)
		OPCUA_Open62541_Variant_setArrayDimensions(out, *dimensions);
}

/* 6.1.24 ExtensionObject, types.h */

static void
pack_UA_ExtensionObject(SV *out, const UA_ExtensionObject *in)
{
	dTHX;
	SV *sv;
	OPCUA_Open62541_DataType type;
	UA_Int32 encoding;
	UA_UInt16 index;
	HV *content, *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "ExtensionObject_encoding", sv);
	/* encoding is enum UA_ExtensionObjectEncoding, convert to UA_Int32 */
	encoding = in->encoding;
	pack_UA_Int32(sv, &encoding);

	content = newHV();
	hv_stores(hv, "ExtensionObject_content", newRV_noinc((SV*)content));
	switch (in->encoding) {
	case UA_EXTENSIONOBJECT_ENCODED_NOBODY:
	case UA_EXTENSIONOBJECT_ENCODED_BYTESTRING:
	case UA_EXTENSIONOBJECT_ENCODED_XML:
		sv = newSV(0);
		hv_stores(content, "ExtensionObject_content_typeId", sv);
		pack_UA_NodeId(sv, &in->content.encoded.typeId);

		sv = newSV(0);
		hv_stores(content, "ExtensionObject_content_body", sv);
		pack_UA_ByteString(sv, &in->content.encoded.body);

		break;
	case UA_EXTENSIONOBJECT_DECODED:
	case UA_EXTENSIONOBJECT_DECODED_NODELETE:
		type = in->content.decoded.type;
		index = dataType2Index(type);
		if (pack_UA_table[index] == NULL) {
			CROAK("No pack conversion for type '%s' index %u",
			    type->typeName, index);
		}

		sv = newSV(0);
		hv_stores(content, "ExtensionObject_content_type", sv);
		XS_pack_OPCUA_Open62541_DataType(sv, type);

		sv = newSV(0);
		hv_stores(content, "ExtensionObject_content_data", sv);
		(pack_UA_table[index])(sv, in->content.decoded.data);

		break;
	default:
		CROAK("ExtensionObject_encoding %d unknown", in->encoding);
	}
}

static void
unpack_UA_ExtensionObject(UA_ExtensionObject *out, SV *in)
{
	dTHX;
	SV **svp;
	void *data;
	OPCUA_Open62541_DataType type;
	UA_UInt16 index;
	HV *content, *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_ExtensionObject_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "ExtensionObject_encoding", 0);
	if (svp == NULL)
		CROAK("No ExtensionObject_encoding in HASH");
	out->encoding = SvIV(*svp);

	svp = hv_fetchs(hv, "ExtensionObject_content", 0);
	if (svp == NULL)
		CROAK("No ExtensionObject_content in HASH");
	if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVHV)
		CROAK("ExtensionObject_content is not a HASH");
	content = (HV*)SvRV(*svp);

	switch (out->encoding) {
	case UA_EXTENSIONOBJECT_ENCODED_NOBODY:
	case UA_EXTENSIONOBJECT_ENCODED_BYTESTRING:
	case UA_EXTENSIONOBJECT_ENCODED_XML:
		svp = hv_fetchs(content, "ExtensionObject_content_typeId", 0);
		if (svp == NULL)
			CROAK("No ExtensionObject_content_typeId in HASH");
		unpack_UA_NodeId(&out->content.encoded.typeId, *svp);

		svp = hv_fetchs(content, "ExtensionObject_content_body", 0);
		if (svp == NULL)
			CROAK("No ExtensionObject_content_body in HASH");
		unpack_UA_ByteString(&out->content.encoded.body, *svp);

		break;
	case UA_EXTENSIONOBJECT_DECODED:
	case UA_EXTENSIONOBJECT_DECODED_NODELETE:
		svp = hv_fetchs(content, "ExtensionObject_content_type", 0);
		if (svp == NULL)
			CROAK("No ExtensionObject_content_type in HASH");
		type = XS_unpack_OPCUA_Open62541_DataType(*svp);
		index = dataType2Index(type);
		if (unpack_UA_table[index] == NULL) {
			CROAK("No unpack conversion for type '%s' index %u",
			    type->typeName, index);
		}
		out->content.decoded.type = type;

		svp = hv_fetchs(content, "ExtensionObject_content_data", 0);
		if (svp == NULL)
			CROAK("No ExtensionObject_content_data in HASH");
		data = UA_new(type);
		if (data == NULL) {
			CROAK("UA_new type '%s' index %u",
			    type->typeName, index);
		}
		out->content.decoded.data = data;
		(unpack_UA_table[index])(data, *svp);

		break;
	default:
		CROAK("ExtensionObject_encoding %d unknown", out->encoding);
	}
}

/* 6.2 Generic Type Handling, UA_DataType, types.h */

static void
XS_pack_OPCUA_Open62541_DataType(SV *out, OPCUA_Open62541_DataType in)
{
	dTHX;
	sv_setuv(out, dataType2Index(in));
}

static OPCUA_Open62541_DataType
XS_unpack_OPCUA_Open62541_DataType(SV *in)
{
	dTHX;
	UV index = SvUV(in);

	if (index >= UA_TYPES_COUNT)
		CROAK("Unsigned value %lu not below UA_TYPES_COUNT", index);
	return &UA_TYPES[index];
}

/* 6.1.25 DataValue, types.h */

static void
pack_UA_DataValue(SV *out, const UA_DataValue *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	sv = newSV(0);
	hv_stores(hv, "DataValue_value", sv);
	pack_UA_Variant(sv, &in->value);

	sv = newSV(0);
	hv_stores(hv, "DataValue_sourceTimestamp", sv);
	pack_UA_DateTime(sv, &in->sourceTimestamp);

	sv = newSV(0);
	hv_stores(hv, "DataValue_serverTimestamp", sv);
	pack_UA_DateTime(sv, &in->serverTimestamp);

	sv = newSV(0);
	hv_stores(hv, "DataValue_sourcePicoseconds", sv);
	pack_UA_UInt16(sv, &in->sourcePicoseconds);

	sv = newSV(0);
	hv_stores(hv, "DataValue_serverPicoseconds", sv);
	pack_UA_UInt16(sv, &in->serverPicoseconds);

	sv = newSV(0);
	hv_stores(hv, "DataValue_status", sv);
	pack_UA_StatusCode(sv, &in->status);

	/*
	 * hasValue ... hasServerPicoseconds is a bit field.
	 * As there is no pointer to bits, use XS_pack_...() for these.
	 */
	sv = newSV(0);
	hv_stores(hv, "DataValue_hasValue", sv);
	XS_pack_UA_Boolean(sv, in->hasValue);

	sv = newSV(0);
	hv_stores(hv, "DataValue_hasStatus", sv);
	XS_pack_UA_Boolean(sv, in->hasStatus);

	sv = newSV(0);
	hv_stores(hv, "DataValue_hasSourceTimestamp", sv);
	XS_pack_UA_Boolean(sv, in->hasSourceTimestamp);

	sv = newSV(0);
	hv_stores(hv, "DataValue_hasServerTimestamp", sv);
	XS_pack_UA_Boolean(sv, in->hasServerTimestamp);

	sv = newSV(0);
	hv_stores(hv, "DataValue_hasSourcePicoseconds", sv);
	XS_pack_UA_Boolean(sv, in->hasSourcePicoseconds);

	sv = newSV(0);
	hv_stores(hv, "DataValue_hasServerPicoseconds", sv);
	XS_pack_UA_Boolean(sv, in->hasServerPicoseconds);
}

static void
unpack_UA_DataValue(UA_DataValue *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DataValue_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "DataValue_value", 0);
	if (svp != NULL)
		unpack_UA_Variant(&out->value, *svp);

	svp = hv_fetchs(hv, "DataValue_sourceTimestamp", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->sourceTimestamp, *svp);

	svp = hv_fetchs(hv, "DataValue_serverTimestamp", 0);
	if (svp != NULL)
		unpack_UA_DateTime(&out->serverTimestamp, *svp);

	svp = hv_fetchs(hv, "DataValue_sourcePicoseconds", 0);
	if (svp != NULL)
		unpack_UA_UInt16(&out->sourcePicoseconds, *svp);

	svp = hv_fetchs(hv, "DataValue_serverPicoseconds", 0);
	if (svp != NULL)
		unpack_UA_UInt16(&out->serverPicoseconds, *svp);

	svp = hv_fetchs(hv, "DataValue_status", 0);
	if (svp != NULL)
		unpack_UA_StatusCode(&out->status, *svp);

	/*
	 * hasValue ... hasServerPicoseconds is a bit field.
	 * As there is no pointer to bits, use XS_unpack_...() for these.
	 */
	svp = hv_fetchs(hv, "DataValue_hasValue", 0);
	if (svp != NULL)
		out->hasValue = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DataValue_hasStatus", 0);
	if (svp != NULL)
		out->hasStatus = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DataValue_hasSourceTimestamp", 0);
	if (svp != NULL)
		out->hasSourceTimestamp = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DataValue_hasServerTimestamp", 0);
	if (svp != NULL)
		out->hasServerTimestamp = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DataValue_hasSourcePicoseconds", 0);
	if (svp != NULL)
		out->hasSourcePicoseconds = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DataValue_hasServerPicoseconds", 0);
	if (svp != NULL)
		out->hasServerPicoseconds = XS_unpack_UA_Boolean(*svp);
}

/* 6.1.26 DiagnosticInfo, types.h */

static void
pack_UA_DiagnosticInfo(SV *out, const UA_DiagnosticInfo *in)
{
	dTHX;
	SV *sv;
	HV *hv;

	hv = newHV();
	sv_setsv(out, sv_2mortal(newRV_noinc((SV*)hv)));

	/*
	 * hasSymbolicId ... hasInnerDiagnosticInfo is a bit field.
	 * As there is no pointer to bits, use XS_pack_...() for these.
	 */
	sv = newSV(0);
	hv_stores(hv, "DiagnosticInfo_hasSymbolicId", sv);
	XS_pack_UA_Boolean(sv, in->hasSymbolicId);

	sv = newSV(0);
	hv_stores(hv, "DiagnosticInfo_hasNamespaceUri", sv);
	XS_pack_UA_Boolean(sv, in->hasNamespaceUri);

	sv = newSV(0);
	hv_stores(hv, "DiagnosticInfo_hasLocalizedText", sv);
	XS_pack_UA_Boolean(sv, in->hasLocalizedText);

	sv = newSV(0);
	hv_stores(hv, "DiagnosticInfo_hasLocale", sv);
	XS_pack_UA_Boolean(sv, in->hasLocale);

	sv = newSV(0);
	hv_stores(hv, "DiagnosticInfo_hasAdditionalInfo", sv);
	XS_pack_UA_Boolean(sv, in->hasAdditionalInfo);

	sv = newSV(0);
	hv_stores(hv, "DiagnosticInfo_hasInnerStatusCode", sv);
	XS_pack_UA_Boolean(sv, in->hasInnerStatusCode);

	sv = newSV(0);
	hv_stores(hv, "DiagnosticInfo_hasInnerDiagnosticInfo", sv);
	XS_pack_UA_Boolean(sv, in->hasInnerDiagnosticInfo);

	sv = newSV(0);
	hv_stores(hv, "DiagnosticInfo_symbolicId", sv);
	pack_UA_Int32(sv, &in->symbolicId);

	sv = newSV(0);
	hv_stores(hv, "DiagnosticInfo_namespaceUri", sv);
	pack_UA_Int32(sv, &in->namespaceUri);

	sv = newSV(0);
	hv_stores(hv, "DiagnosticInfo_localizedText", sv);
	pack_UA_Int32(sv, &in->localizedText);

	sv = newSV(0);
	hv_stores(hv, "DiagnosticInfo_locale", sv);
	pack_UA_Int32(sv, &in->locale);

	sv = newSV(0);
	hv_stores(hv, "DiagnosticInfo_additionalInfo", sv);
	pack_UA_String(sv, &in->additionalInfo);

	sv = newSV(0);
	hv_stores(hv, "DiagnosticInfo_innerStatusCode", sv);
	pack_UA_StatusCode(sv, &in->innerStatusCode);

	/* only make recursive call to inner diagnostic if it exists */
	if (in->innerDiagnosticInfo != NULL) {
		sv = newSV(0);
		hv_stores(hv, "DiagnosticInfo_innerDiagnosticInfo", sv);
		pack_UA_DiagnosticInfo(sv, in->innerDiagnosticInfo);
	}
}

static void
unpack_UA_DiagnosticInfo(UA_DiagnosticInfo *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_DiagnosticInfo_init(out);
	hv = (HV*)SvRV(in);

	/*
	 * hasSymbolicId ... hasInnerDiagnosticInfo is a bit field.
	 * As there is no pointer to bits, use XS_pack_...() for these.
	 */
	svp = hv_fetchs(hv, "DiagnosticInfo_hasSymbolicId", 0);
	if (svp != NULL)
		out->hasSymbolicId = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_hasNamespaceUri", 0);
	if (svp != NULL)
		out->hasNamespaceUri = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_hasLocalizedText", 0);
	if (svp != NULL)
		out->hasLocalizedText = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_hasLocale", 0);
	if (svp != NULL)
		out->hasLocale = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_hasAdditionalInfo", 0);
	if (svp != NULL)
		out->hasAdditionalInfo = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_hasInnerStatusCode", 0);
	if (svp != NULL)
		out->hasInnerStatusCode = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_hasInnerDiagnosticInfo", 0);
	if (svp != NULL)
		out->hasInnerDiagnosticInfo = XS_unpack_UA_Boolean(*svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_symbolicId", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->symbolicId, *svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_namespaceUri", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->namespaceUri, *svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_localizedText", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->localizedText, *svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_locale", 0);
	if (svp != NULL)
		unpack_UA_Int32(&out->locale, *svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_additionalInfo", 0);
	if (svp != NULL)
		unpack_UA_String(&out->additionalInfo, *svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_innerStatusCode", 0);
	if (svp != NULL)
		unpack_UA_StatusCode(&out->innerStatusCode, *svp);

	svp = hv_fetchs(hv, "DiagnosticInfo_innerDiagnosticInfo", 0);
	if (svp != NULL) {
		out->innerDiagnosticInfo = UA_DiagnosticInfo_new();
		if (out->innerDiagnosticInfo == NULL)
			CROAKE("UA_DiagnosticInfo_new");
		unpack_UA_DiagnosticInfo(out->innerDiagnosticInfo, *svp);
	}
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

/* 11.7.1 Node Lifecycle: Constructors, Destructors and Node Contexts */

static OPCUA_Open62541_GlobalNodeLifecycle
XS_unpack_OPCUA_Open62541_GlobalNodeLifecycle(SV *in)
{
	dTHX;
	struct OPCUA_Open62541_GlobalNodeLifecycle out;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	memset(&out, 0, sizeof(out));
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "GlobalNodeLifecycle_constructor", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVCV)
			CROAK("Constructor '%s' is not a CODE reference",
			    SvPV_nolen(*svp));
		out.gnl_constructor = *svp;
	}

	svp = hv_fetchs(hv, "GlobalNodeLifecycle_destructor", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVCV)
			CROAK("Destructor '%s' is not a CODE reference",
			    SvPV_nolen(*svp));
		out.gnl_destructor = *svp;
	}

	svp = hv_fetchs(hv, "GlobalNodeLifecycle_createOptionalChild", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVCV)
			CROAK(
			    "CreateOptionalChild '%s' is not a CODE reference",
			    SvPV_nolen(*svp));
		out.gnl_createOptionalChild = *svp;
	}

	svp = hv_fetchs(hv, "GlobalNodeLifecycle_generateChildNodeId", 0);
	if (svp != NULL) {
		if (!SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVCV)
			CROAK(
			    "GenerateChildNodeId '%s' is not a CODE reference",
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
		pack_UA_NodeId(sv, sessionId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (server->sv_lifecycle_context != NULL)
		sv = server->sv_lifecycle_context;
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (nodeId != NULL) {
		sv = sv_newmortal();
		pack_UA_NodeId(sv, nodeId);
	}
	PUSHs(sv);
	/* Setting *nodeContext is broken, use generic undef to avoid leak. */
	sv = &PL_sv_undef;
	if (*nodeContext != NULL) {
		DPRINTF("node context %p", *nodeContext);
		sv = *nodeContext;
	}
	/* Constructor uses reference to context, pass a reference to Perl. */
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
    const UA_NodeId *nodeId, void *nodeContext)
{
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
		DPRINTF("node context %p", nodeContext);
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
		pack_UA_NodeId(sv, sessionId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (server->sv_lifecycle_context != NULL)
		sv = server->sv_lifecycle_context;
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (nodeId != NULL) {
		sv = sv_newmortal();
		pack_UA_NodeId(sv, nodeId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (nodeContext != NULL) {
		/* Make node context mortal, destroy it at function return. */
		DPRINTF("node context %p", nodeContext);
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
		pack_UA_NodeId(sv, sessionId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (server->sv_lifecycle_context != NULL)
		sv = server->sv_lifecycle_context;
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (sourceNodeId != NULL) {
		sv = sv_newmortal();
		pack_UA_NodeId(sv, sourceNodeId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (targetParentNodeId != NULL) {
		sv = sv_newmortal();
		pack_UA_NodeId(sv, targetParentNodeId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (referenceTypeId != NULL) {
		sv = sv_newmortal();
		pack_UA_NodeId(sv, referenceTypeId);
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
		pack_UA_NodeId(sv, sessionId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (server->sv_lifecycle_context != NULL)
		sv = server->sv_lifecycle_context;
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (sourceNodeId != NULL) {
		sv = sv_newmortal();
		pack_UA_NodeId(sv, sourceNodeId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (targetParentNodeId != NULL) {
		sv = sv_newmortal();
		pack_UA_NodeId(sv, targetParentNodeId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (referenceTypeId != NULL) {
		sv = sv_newmortal();
		pack_UA_NodeId(sv, referenceTypeId);
	}
	PUSHs(sv);
	sv = &PL_sv_undef;
	if (targetNodeId != NULL) {
		sv = sv_newmortal();
		pack_UA_NodeId(sv, targetNodeId);
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

static void
addNodeProlog(pTHX_ OPCUA_Open62541_Server server, SV **nodeContext)
{
	UA_GlobalNodeLifecycle *lc;
	SV *nc;

	lc = &server->sv_config.svc_serverconfig->nodeLifecycle;
	if (*nodeContext == NULL || !SvOK(*nodeContext) ||
	    (lc->constructor == NULL && lc->destructor == NULL)) {
		*nodeContext = NULL;
		DPRINTF("node context %p", *nodeContext);
		return;
	}

	nc = newSVsv(*nodeContext);
	SvREFCNT_inc_NN(nc);
	sv_2mortal(nc);
	*nodeContext = nc;
	DPRINTF("node context %p", *nodeContext);
}

static void
addNodeEpilog(pTHX_ OPCUA_Open62541_Server server, SV *nodeContext,
    OPCUA_Open62541_NodeId outoptNewNodeId, SV *outStack,
    UA_StatusCode statusCode)
{
	UA_GlobalNodeLifecycle *lc;

	DPRINTF("node context %p, status %s",
	    nodeContext, UA_StatusCode_name(statusCode));

	/* You never know when open62541 chooses to call the destructor. */
	lc = &server->sv_config.svc_serverconfig->nodeLifecycle;
	if (nodeContext != NULL && SvREFCNT(nodeContext) == 2 &&
	    (statusCode != UA_STATUSCODE_GOOD || lc->destructor == NULL)) {
		SvREFCNT_dec_NN(nodeContext);
	}
	if (statusCode == UA_STATUSCODE_GOOD && outoptNewNodeId != NULL) {
		pack_UA_NodeId(SvRV(outStack), outoptNewNodeId);
	}
}

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
    UA_SecureChannelState channelState, UA_SessionState sessionState,
    UA_StatusCode connectStatus)
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
	EXTEND(SP, 4);
	PUSHs(sv);
	sv = newSViv(channelState);
	mPUSHs(sv);
	sv = newSViv(sessionState);
	mPUSHs(sv);
	/* Use magic status code. */
	sv = newSV(0);
	pack_UA_StatusCode(sv, &connectStatus);
	mPUSHs(sv);
	PUTBACK;

	call_sv(client->cl_config.clc_statecallback, G_VOID | G_DISCARD);

	FREETMPS;
	LEAVE;
}

static void
clientAsyncBrowseCallback(UA_Client *ua_client, void *userdata,
    UA_UInt32 requestId, UA_BrowseResponse *response)
{
	dTHX;
	SV *sv;

	sv = newSV(0);
	if (response != NULL)
		pack_UA_BrowseResponse(sv, response);

	clientCallbackPerl(ua_client, userdata, requestId, sv);
}

static void
clientAsyncBrowseNextCallback(UA_Client *ua_client, void *userdata,
    UA_UInt32 requestId, UA_BrowseNextResponse *response)
{
	dTHX;
	SV *sv;

	sv = newSV(0);
	if (response != NULL)
		pack_UA_BrowseNextResponse(sv, response);

	clientCallbackPerl(ua_client, userdata, requestId, sv);
}

#include "Open62541-client-read-callback.xsh"

static void
clientAsyncReadDataTypeCallback(UA_Client *ua_client, void *userdata,
    UA_UInt32 requestId,
    UA_StatusCode status,
    UA_NodeId *nodeId)
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

	/* XXX we do not propagate the status code */
	clientCallbackPerl(ua_client, userdata, requestId, sv);
}

static void
clientAsyncReadCallback(UA_Client *ua_client, void *userdata,
    UA_UInt32 requestId, UA_ReadResponse *response)
{
	dTHX;
	SV *sv;

	sv = newSV(0);
	if (response != NULL)
		pack_UA_ReadResponse(sv, response);

	clientCallbackPerl(ua_client, userdata, requestId, sv);
}

static void
clientDeleteSubscriptionCallback(UA_Client *ua_client, UA_UInt32 subId,
    void *subContext)
{
	dTHX;
	dSP;
	SubscriptionContext sub = subContext;

	DPRINTF("ua_client %p, sub %p, sc_change %p, sc_delete %p",
	    ua_client, sub, sub->sc_change, sub->sc_delete);

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
clientStatusChangeNotificationCallback(UA_Client *ua_client, UA_UInt32 subId,
    void *subContext, UA_StatusChangeNotification *notification)
{
	dTHX;
	dSP;
	SubscriptionContext sub = subContext;
	SV *notificationPerl;

	DPRINTF("ua_client %p, sub %p, sc_change %p, sc_delete %p",
	    ua_client, sub, sub->sc_change, sub->sc_delete);

	if (sub->sc_change == NULL)
		return;

	notificationPerl = newSV(0);
	if (notification != NULL)
		pack_UA_StatusChangeNotification(notificationPerl,
		    notification);

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
clientDeleteMonitoredItemCallback(UA_Client *ua_client, UA_UInt32 subId,
    void *subContext, UA_UInt32 monId, void *monContext)
{
	dTHX;
	dSP;
	SubscriptionContext sub = subContext;
	MonitoredItemContext mon = monContext;

	DPRINTF("ua_client %p, sub %p, mon %p, mc_change %p, mc_delete %p",
	    ua_client, sub, mon, mon->mc_change, mon->mc_delete);

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

	SvREFCNT_dec(mon->mc_arrays);
}

static void
clientDataChangeNotificationCallback(UA_Client *ua_client, UA_UInt32 subId,
    void *subContext, UA_UInt32 monId, void *monContext, UA_DataValue *value)
{
	dTHX;
	dSP;
	SubscriptionContext sub = subContext;
	MonitoredItemContext mon = monContext;
	SV *valuePerl;

	DPRINTF("ua_client %p, sub %p, sc_change %p, sc_delete %p, "
	    "mon %p, mc_change %p, mc_delete %p",
	    ua_client, sub, sub->sc_change, sub->sc_delete,
	    mon, mon->mc_change, mon->mc_delete);

	if (mon->mc_change == NULL)
		return;

	valuePerl = newSV(0);
	if (value != NULL)
		pack_UA_DataValue(valuePerl, value);

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
getUserRightsMask_default(UA_Server *ua_server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *nodeId,
    void *nodeContext) {
	return 0xFFFFFFFF;
}

static UA_UInt32
getUserRightsMask_readonly(UA_Server *ua_server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *nodeId,
    void *nodeContext) {
	return 0x00000000;
}

static UA_Byte
getUserAccessLevel_default(UA_Server *ua_server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *nodeId,
    void *nodeContext) {
	return 0xFF;
}

static UA_Byte
getUserAccessLevel_readonly(UA_Server *ua_server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *nodeId,
    void *nodeContext) {
	return UA_ACCESSLEVELMASK_READ | UA_ACCESSLEVELMASK_HISTORYREAD;
}

static UA_Boolean
getUserExecutable_default(UA_Server *ua_server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *methodId,
    void *methodContext) {
	return true;
}

static UA_Boolean
getUserExecutable_false(UA_Server *ua_server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *methodId,
    void *methodContext) {
	return false;
}

static UA_Boolean
getUserExecutableOnObject_default(UA_Server *ua_server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *methodId,
    void *methodContext, const UA_NodeId *objectId, void *objectContext) {
	return true;
}

static UA_Boolean
getUserExecutableOnObject_false(UA_Server *ua_server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *methodId,
    void *methodContext, const UA_NodeId *objectId, void *objectContext) {
	return false;
}

static UA_Boolean
allowAddNode_default(UA_Server *ua_server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_AddNodesItem *item) {
	return true;
}

static UA_Boolean
allowAddNode_false(UA_Server *ua_server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_AddNodesItem *item) {
	return false;
}

static UA_Boolean
allowAddReference_default(UA_Server *ua_server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_AddReferencesItem *item) {
	return true;
}

static UA_Boolean
allowAddReference_false(UA_Server *ua_server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_AddReferencesItem *item) {
	return false;
}

static UA_Boolean
allowDeleteNode_default(UA_Server *ua_server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_DeleteNodesItem *item) {
	return true;
}

static UA_Boolean
allowDeleteNode_false(UA_Server *ua_server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_DeleteNodesItem *item) {
	return false;
}

static UA_Boolean
allowDeleteReference_default(UA_Server *ua_server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_DeleteReferencesItem *item) {
	return true;
}

static UA_Boolean
allowDeleteReference_false(UA_Server *ua_server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext,
    const UA_DeleteReferencesItem *item) {
	return false;
}

#ifdef UA_ENABLE_HISTORIZING

static UA_Boolean
allowHistoryUpdateUpdateData_default(UA_Server *ua_server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *nodeId,
    UA_PerformUpdateType performInsertReplace, const UA_DataValue *value) {
	return true;
}

static UA_Boolean
allowHistoryUpdateUpdateData_false(UA_Server *ua_server, UA_AccessControl *ac,
    const UA_NodeId *sessionId, void *sessionContext, const UA_NodeId *nodeId,
    UA_PerformUpdateType performInsertReplace, const UA_DataValue *value) {
	return false;
}

static UA_Boolean
allowHistoryUpdateDeleteRawModified_default(UA_Server *ua_server,
    UA_AccessControl *ac, const UA_NodeId *sessionId, void *sessionContext,
    const UA_NodeId *nodeId, UA_DateTime startTimestamp,
    UA_DateTime endTimestamp, bool isDeleteModified) {
	return true;
}

static UA_Boolean
allowHistoryUpdateDeleteRawModified_false(UA_Server *ua_server,
    UA_AccessControl *ac, const UA_NodeId *sessionId, void *sessionContext,
    const UA_NodeId *nodeId, UA_DateTime startTimestamp,
    UA_DateTime endTimestamp, bool isDeleteModified) {
	return false;
}

#endif /* UA_ENABLE_HISTORIZING*/

/* 16.4 Logging Plugin API, log and clear callbacks */

static void XS_pack_UA_LogLevel(SV *out, UA_LogLevel in)
    __attribute__((unused));
static UA_LogLevel XS_unpack_UA_LogLevel(SV *in) __attribute__((unused));

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

static UA_LogLevel
XS_unpack_UA_LogLevel(SV *in)
{
	dTHX;
	return SvIV(in);
}

static void XS_pack_UA_LogCategory(SV *in, UA_LogCategory out)
    __attribute__((unused));
static UA_LogCategory XS_unpack_UA_LogCategory(SV *in) __attribute__((unused));

#define LOG_CATEGORY_COUNT	8
const char *logCategoryNames[LOG_CATEGORY_COUNT] = {
	"network",
	"channel",
	"session",
	"server",
	"client",
	"userland",
	"securitypolicy",
	"eventloop",
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

static UA_LogCategory
XS_unpack_UA_LogCategory(SV *in)
{
	dTHX;
	return SvIV(in);
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

/*
 * CertificateVerification new and delete should be defined in open62541,
 * but is missing there.
 */

static UA_CertificateVerification *
UA_CertificateVerification_new(void)
{
	UA_CertificateVerification *verifyX509;

	verifyX509 = UA_calloc(1, sizeof(*verifyX509));
	return verifyX509;
}

static void
UA_CertificateVerification_delete(UA_CertificateVerification *verifyX509)
{
	if (verifyX509->clear)
		(*verifyX509->clear)(verifyX509);
	UA_free(verifyX509);
}

static void
UA_UsernamePasswordLogin_init(UA_UsernamePasswordLogin *upl)
{
	UA_String_init(&upl->username);
	UA_String_init(&upl->password);
}

static void
unpack_UA_UsernamePasswordLogin(UA_UsernamePasswordLogin *out, SV *in)
{
	dTHX;
	SV **svp;
	HV *hv;

	SvGETMAGIC(in);
	if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVHV)
		CROAK("Not a HASH reference");
	UA_UsernamePasswordLogin_init(out);
	hv = (HV*)SvRV(in);

	svp = hv_fetchs(hv, "UsernamePasswordLogin_username", 0);
	if (svp == NULL)
		CROAK("No UsernamePasswordLogin_username in HASH");
	if (!SvOK(*svp)) {
		UA_String_init(&out->username);
	} else {
		out->username.data = SvPV(*svp, out->username.length);
	}

	svp = hv_fetchs(hv, "UsernamePasswordLogin_password", 0);
	if (svp == NULL)
		CROAK("No UsernamePasswordLogin_password in HASH");
	if (!SvOK(*svp)) {
		UA_String_init(&out->password);
	} else {
		out->password.data = SvPV(*svp, out->password.length);
	}
}

static void
unpack_UA_UsernamePasswordLogin_List(UA_UsernamePasswordLogin **outList,
    size_t *outSize, SV *in)
{
	dTHX;
	AV *				av;
	SV *				sv;
	SV **				svp;
	UA_UsernamePasswordLogin *	upl;
	size_t	i;

	*outList = NULL;
	*outSize = 0;

	if (SvOK(in)) {
		if (!SvROK(in) || SvTYPE(SvRV(in)) != SVt_PVAV) {
			CROAK("Not an ARRAY reference with "
			    "UsernamePasswordLogin list");
		}
		av = (AV*)SvRV(in);
		*outSize = av_top_index(av) + 1;
	}

	if (*outSize > 0) {
		if ((*outSize >= MUL_NO_OVERFLOW ||
		    sizeof(UA_UsernamePasswordLogin) >= MUL_NO_OVERFLOW) &&
		    SIZE_MAX / *outSize < sizeof(UA_UsernamePasswordLogin)) {
			CROAK("UsernamePasswordLogin list too big");
		}
		sv = sv_2mortal(
		    newSV(*outSize * sizeof(UA_UsernamePasswordLogin)));
		*outList = (UA_UsernamePasswordLogin *)SvPVX(sv);

		for (i = 0, upl = *outList; i < *outSize; i++, upl++) {
			svp = av_fetch(av, i, 0);

			if (svp == NULL || !SvOK(*svp)) {
				UA_UsernamePasswordLogin_init(upl);
			} else {
				unpack_UA_UsernamePasswordLogin(upl, *svp);
			}
		}
	}
}

#ifdef HAVE_UA_ACCESSCONTROL_SETCALLBACK

#ifdef HAVE_CRYPT_CHECKPASS

static UA_StatusCode
loginCryptCheckpassCallback(const UA_String *userName, const UA_ByteString
    *password, size_t loginSize, const UA_UsernamePasswordLogin *loginList,
    void *loginContext)
{
	char *pass;
	size_t i;
	int userok = 0, passok = 0;

	/* UA_ByteString has no terminating NUL byte */
	pass = UA_malloc(password->length + 1);
	if (pass == NULL)
		return UA_STATUSCODE_BADOUTOFMEMORY;
	memcpy(pass, password->data, password->length);
	pass[password->length] = '\0';

	/* Always run though full loop to avoid timing attack. */
	for (i = 0; i < loginSize; i++, loginList++) {
		char hash[_PASSWORD_LEN + 1];
		size_t hashlen;

		if (userName->length == loginList->username.length &&
		    timingsafe_bcmp(userName->data, loginList->username.data,
		    userName->length) == 0)
			userok = 1;
		else
			continue;

		/* UA_String has no terminating NUL byte */
		hashlen = loginList->password.length < _PASSWORD_LEN ?
		    loginList->password.length : _PASSWORD_LEN;
		memcpy(hash, loginList->password.data, hashlen);
		hash[hashlen] = '\0';

		if (crypt_checkpass(pass, hash) == 0)
			passok = 1;
	}
	/* Do some work if user does not match to avoid user guessing. */
	if (!userok)
		crypt_checkpass(pass, NULL);

	UA_free(pass);
	return passok ? UA_STATUSCODE_GOOD : UA_STATUSCODE_BADUSERACCESSDENIED;
}

#endif /* HAVE_CRYPT_CHECKPASS */

#endif /* HAVE_UA_ACCESSCONTROL_SETCALLBACK */

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
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::MonitoredItemArrays

void
MonitoredItemArrays_DESTROY(marr)
	OPCUA_Open62541_MonitoredItemArrays		marr;
    CODE:
	DPRINTF("marr %p, ma_mon %p, ma_context %p, ma_change %p, "
	    "ma_delete %p",
	    marr, marr->ma_mon, marr->ma_context, marr->ma_change,
	    marr->ma_delete);
	free(marr->ma_delete);
	free(marr->ma_change);
	free(marr->ma_context);
	free(marr->ma_mon);
	free(marr);

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
	RETVAL = dataType2Index(variant->type);
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
	RETVAL = sv_newmortal();
	OPCUA_Open62541_Variant_getScalar(variant, RETVAL);
	SvREFCNT_inc_NN(RETVAL);
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
	RETVAL = sv_newmortal();
	OPCUA_Open62541_Variant_getArray(variant, RETVAL);
	SvREFCNT_inc_NN(RETVAL);
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
	/* Needed for lifecycle callbacks. */
	UA_Server_setAdminSessionContext(RETVAL->sv_server, RETVAL);
	/* Node context has to be freed in destructor, call it always. */
	RETVAL->sv_config.svc_serverconfig->nodeLifecycle.destructor =
	    serverGlobalNodeLifecycleDestructor;
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
	pack_UA_Variant(SvRV(ST(2)), outVariant);
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

void
UA_Server_setAdminSessionContext(server, context)
	OPCUA_Open62541_Server		server
	SV *				context
    CODE:
	/* Server new() has called open62541 setAdminSessionContext(). */
	server->sv_lifecycle_server = ST(0);
	SvREFCNT_dec(server->sv_lifecycle_context);
	server->sv_lifecycle_context = SvREFCNT_inc(context);

# 11.9 Node Addition and Deletion

UA_StatusCode
UA_Server_addVariableNode(server, requestedNewNodeId, parentNodeId, \
    referenceTypeId, browseName, typeDefinition, attr, nodeContext, \
    outoptNewNodeId)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		requestedNewNodeId
	OPCUA_Open62541_NodeId		parentNodeId
	OPCUA_Open62541_NodeId		referenceTypeId
	OPCUA_Open62541_QualifiedName	browseName
	OPCUA_Open62541_NodeId		typeDefinition
	OPCUA_Open62541_VariableAttributes	attr
	SV *				nodeContext
	OPCUA_Open62541_NodeId		outoptNewNodeId
    CODE:
	addNodeProlog(aTHX_ server, &nodeContext);
	RETVAL = UA_Server_addVariableNode(server->sv_server,
	    *requestedNewNodeId, *parentNodeId, *referenceTypeId, *browseName,
	    *typeDefinition, *attr, nodeContext, outoptNewNodeId);
	addNodeEpilog(aTHX_ server, nodeContext, outoptNewNodeId, ST(8),
	    RETVAL);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_addVariableTypeNode(server, requestedNewNodeId, parentNodeId, \
    referenceTypeId, browseName, typeDefinition, attr, nodeContext, \
    outoptNewNodeId)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		requestedNewNodeId
	OPCUA_Open62541_NodeId		parentNodeId
	OPCUA_Open62541_NodeId		referenceTypeId
	OPCUA_Open62541_QualifiedName	browseName
	OPCUA_Open62541_NodeId		typeDefinition
	OPCUA_Open62541_VariableTypeAttributes	attr
	SV *				nodeContext
	OPCUA_Open62541_NodeId		outoptNewNodeId
    CODE:
	addNodeProlog(aTHX_ server, &nodeContext);
	RETVAL = UA_Server_addVariableTypeNode(server->sv_server,
	    *requestedNewNodeId, *parentNodeId, *referenceTypeId, *browseName,
	    *typeDefinition, *attr, nodeContext, outoptNewNodeId);
	addNodeEpilog(aTHX_ server, nodeContext, outoptNewNodeId, ST(8),
	    RETVAL);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_addObjectNode(server, requestedNewNodeId, parentNodeId, \
    referenceTypeId, browseName, typeDefinition, attr, nodeContext, \
    outoptNewNodeId)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		requestedNewNodeId
	OPCUA_Open62541_NodeId		parentNodeId
	OPCUA_Open62541_NodeId		referenceTypeId
	OPCUA_Open62541_QualifiedName	browseName
	OPCUA_Open62541_NodeId		typeDefinition
	OPCUA_Open62541_ObjectAttributes	attr
	SV *				nodeContext
	OPCUA_Open62541_NodeId		outoptNewNodeId
    CODE:
	addNodeProlog(aTHX_ server, &nodeContext);
	RETVAL = UA_Server_addObjectNode(server->sv_server,
	    *requestedNewNodeId, *parentNodeId, *referenceTypeId, *browseName,
	    *typeDefinition, *attr, nodeContext, outoptNewNodeId);
	addNodeEpilog(aTHX_ server, nodeContext, outoptNewNodeId, ST(8),
	    RETVAL);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_addObjectTypeNode(server, requestedNewNodeId, parentNodeId, \
    referenceTypeId, browseName, attr, nodeContext, outoptNewNodeId)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		requestedNewNodeId
	OPCUA_Open62541_NodeId		parentNodeId
	OPCUA_Open62541_NodeId		referenceTypeId
	OPCUA_Open62541_QualifiedName	browseName
	OPCUA_Open62541_ObjectTypeAttributes	attr
	SV *				nodeContext
	OPCUA_Open62541_NodeId		outoptNewNodeId
    CODE:
	addNodeProlog(aTHX_ server, &nodeContext);
	RETVAL = UA_Server_addObjectTypeNode(server->sv_server,
	    *requestedNewNodeId, *parentNodeId, *referenceTypeId, *browseName,
	    *attr, nodeContext, outoptNewNodeId);
	addNodeEpilog(aTHX_ server, nodeContext, outoptNewNodeId, ST(7),
	    RETVAL);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_addViewNode(server, requestedNewNodeId, parentNodeId, \
    referenceTypeId, browseName, attr, nodeContext, outoptNewNodeId)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		requestedNewNodeId
	OPCUA_Open62541_NodeId		parentNodeId
	OPCUA_Open62541_NodeId		referenceTypeId
	OPCUA_Open62541_QualifiedName	browseName
	OPCUA_Open62541_ViewAttributes	attr
	SV *				nodeContext
	OPCUA_Open62541_NodeId		outoptNewNodeId
    CODE:
	addNodeProlog(aTHX_ server, &nodeContext);
	RETVAL = UA_Server_addViewNode(server->sv_server,
	    *requestedNewNodeId, *parentNodeId, *referenceTypeId, *browseName,
	    *attr, nodeContext, outoptNewNodeId);
	addNodeEpilog(aTHX_ server, nodeContext, outoptNewNodeId, ST(7),
	    RETVAL);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_addReferenceTypeNode(server, requestedNewNodeId, parentNodeId, \
    referenceTypeId, browseName, attr, nodeContext, outoptNewNodeId)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		requestedNewNodeId
	OPCUA_Open62541_NodeId		parentNodeId
	OPCUA_Open62541_NodeId		referenceTypeId
	OPCUA_Open62541_QualifiedName	browseName
	OPCUA_Open62541_ReferenceTypeAttributes	attr
	SV *				nodeContext
	OPCUA_Open62541_NodeId		outoptNewNodeId
    CODE:
	addNodeProlog(aTHX_ server, &nodeContext);
	RETVAL = UA_Server_addReferenceTypeNode(server->sv_server,
	    *requestedNewNodeId, *parentNodeId, *referenceTypeId, *browseName,
	    *attr, nodeContext, outoptNewNodeId);
	addNodeEpilog(aTHX_ server, nodeContext, outoptNewNodeId, ST(7),
	    RETVAL);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Server_addDataTypeNode(server, requestedNewNodeId, parentNodeId, \
    referenceTypeId, browseName, attr, nodeContext, outoptNewNodeId)
	OPCUA_Open62541_Server		server
	OPCUA_Open62541_NodeId		requestedNewNodeId
	OPCUA_Open62541_NodeId		parentNodeId
	OPCUA_Open62541_NodeId		referenceTypeId
	OPCUA_Open62541_QualifiedName	browseName
	OPCUA_Open62541_DataTypeAttributes	attr
	SV *				nodeContext
	OPCUA_Open62541_NodeId		outoptNewNodeId
    CODE:
	addNodeProlog(aTHX_ server, &nodeContext);
	RETVAL = UA_Server_addDataTypeNode(server->sv_server,
	    *requestedNewNodeId, *parentNodeId, *referenceTypeId, *browseName,
	    *attr, nodeContext, outoptNewNodeId);
	addNodeEpilog(aTHX_ server, nodeContext, outoptNewNodeId, ST(7),
	    RETVAL);
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
UA_Server_deleteReference(server, sourceNodeId, referenceTypeId, isForward, \
    targetNodeId, deleteBidirectional)
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
	/* We always need the destructor, setDefault() clears it. */
	config->svc_serverconfig->nodeLifecycle.destructor =
	    serverGlobalNodeLifecycleDestructor;
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
	/* We always need the destructor, setMinimal() clears it. */
	config->svc_serverconfig->nodeLifecycle.destructor =
	    serverGlobalNodeLifecycleDestructor;
    OUTPUT:
	RETVAL

#ifdef UA_ENABLE_ENCRYPTION

UA_StatusCode
UA_ServerConfig_setDefaultWithSecurityPolicies(conf, portNumber, certificate, \
    privateKey, trustListRAV = &PL_sv_undef, issuerListRAV = &PL_sv_undef, \
    revocationListRAV = &PL_sv_undef)
	OPCUA_Open62541_ServerConfig	conf
	UA_UInt16			portNumber
	OPCUA_Open62541_ByteString	certificate
	OPCUA_Open62541_ByteString	privateKey
	SV *				trustListRAV
	SV *				issuerListRAV
	SV *				revocationListRAV
    PREINIT:
	UA_ByteString *			trustList;
	size_t				trustListSize;
	UA_ByteString *			issuerList;
	size_t				issuerListSize;
	UA_ByteString *			revocationList;
	size_t				revocationListSize;
    CODE:
	unpack_UA_ByteString_List(&trustList, &trustListSize, trustListRAV);
	unpack_UA_ByteString_List(&issuerList, &issuerListSize, issuerListRAV);
	unpack_UA_ByteString_List(&revocationList, &revocationListSize,
	    revocationListRAV);

	RETVAL = UA_ServerConfig_setDefaultWithSecurityPolicies(
	    conf->svc_serverconfig, portNumber, certificate, privateKey,
	    trustList, trustListSize, issuerList, issuerListSize,
	    revocationList, revocationListSize);

	/* accept all certificates as fallback ? */
	if (trustList == NULL && issuerList == NULL && revocationList == NULL) {
		UA_CertificateVerification_AcceptAll(
		    &conf->svc_serverconfig->certificateVerification);
	}
    OUTPUT:
	RETVAL

#endif /* UA_ENABLE_ENCRYPTION */

UA_StatusCode
UA_ServerConfig_setAccessControl_default(config, allowAnonymous, \
    optVerifyX509, optUserTokenPolicyUri, usernamePasswordLogin)
	OPCUA_Open62541_ServerConfig		config
	UA_Boolean				allowAnonymous
	OPCUA_Open62541_CertificateVerification	optVerifyX509
	OPCUA_Open62541_ByteString		optUserTokenPolicyUri
	SV *					usernamePasswordLogin
    PREINIT:
	UA_UsernamePasswordLogin *		loginList;
	size_t					loginSize;
    CODE:
	if (optVerifyX509 && optUserTokenPolicyUri == NULL)
		CROAK("VerifyX509 needs userTokenPolicyUri");
	unpack_UA_UsernamePasswordLogin_List(&loginList, &loginSize,
	    usernamePasswordLogin);
	if (loginSize > 0 && optUserTokenPolicyUri == NULL)
		CROAK("UsernamePasswordLogin needs userTokenPolicyUri");
	RETVAL = UA_AccessControl_default(config->svc_serverconfig,
	    allowAnonymous, optVerifyX509, optUserTokenPolicyUri,
	   loginSize, loginList);
    OUTPUT:
	RETVAL

#ifdef HAVE_UA_ACCESSCONTROL_SETCALLBACK

UA_StatusCode
UA_ServerConfig_setAccessControl_loginCheck(config, check)
	OPCUA_Open62541_ServerConfig	config
	SV *				check;
    CODE:
	if (!SvOK(check)) {
		RETVAL = UA_AccessControl_setCallback(config->svc_serverconfig,
		    NULL, NULL);
#ifdef HAVE_CRYPT_CHECKPASS
	} else if (strcmp(SvPV_nolen(check), "crypt_checkpass") == 0) {
		RETVAL = UA_AccessControl_setCallback(config->svc_serverconfig,
		    loginCryptCheckpassCallback, NULL);
#endif /* HAVE_CRYPT_CHECKPASS */
	} else {
		/* TODO: implement pure Perl callback */
		RETVAL = UA_STATUSCODE_BADINVALIDARGUMENT;
	}
    OUTPUT:
	RETVAL

#endif /* HAVE_UA_ACCESSCONTROL_SETCALLBACK */

#ifdef HAVE_CRYPT_CHECKPASS

SV *
UA_ServerConfig_AccessControl_CryptNewhash(config, password, \
    pref = &PL_sv_undef)
	OPCUA_Open62541_ServerConfig	config
	SV *				password
	SV *				pref
    PREINIT:
	const char *passstr;
	const char *prefstr = NULL;
	char hash[_PASSWORD_LEN + 1];
    CODE:
	(void)config;
	if (!SvOK(password))
		CROAK("Undef password");
	passstr = SvPV_nolen(password);
	if (SvOK(pref))
		prefstr = SvPV_nolen(pref);
	if (crypt_newhash(passstr, prefstr, hash, _PASSWORD_LEN) != 0)
		CROAKE("crypt_newhash");
	RETVAL = newSVpv(hash, 0);
    OUTPUT:
	RETVAL

#endif /* HAVE_CRYPT_CHECKPASS */

#ifdef HAVE_UA_SERVERCONFIG_CUSTOMHOSTNAME

SV *
UA_ServerConfig_getCustomHostname(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	RETVAL = sv_2mortal(newSV(0));
	pack_UA_String(RETVAL, &config->svc_serverconfig->customHostname);
	SvREFCNT_inc_NN(RETVAL);
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setCustomHostname(config, customHostname)
	OPCUA_Open62541_ServerConfig	config
	SV *				customHostname
    CODE:
	UA_String_clear(&config->svc_serverconfig->customHostname);
	unpack_UA_String(&config->svc_serverconfig->customHostname,
	    customHostname);

#endif /* HAVE_UA_SERVERCONFIG_CUSTOMHOSTNAME */

#ifdef HAVE_UA_SERVERCONFIG_SERVERURLS

void
UA_ServerConfig_setServerUrls(config, ...)
	OPCUA_Open62541_ServerConfig	config
    PREINIT:
	int i;
    CODE:
	UA_Array_delete(config->svc_serverconfig->serverUrls,
	    config->svc_serverconfig->serverUrlsSize,
	    &UA_TYPES[UA_TYPES_STRING]);
	config->svc_serverconfig->serverUrls = NULL;
	config->svc_serverconfig->serverUrlsSize = 0;
	if (items <= 1)
		XSRETURN_EMPTY;
	config->svc_serverconfig->serverUrls = UA_Array_new(items - 1,
	    &UA_TYPES[UA_TYPES_STRING]);
	if (config->svc_serverconfig->serverUrls == NULL)
		CROAKE("UA_Array_new size %d", items - 1);
	config->svc_serverconfig->serverUrlsSize = items - 1;
	for (i = 1; i < items; i++) {
		config->svc_serverconfig->serverUrls[i - 1] =
		    XS_unpack_UA_String(ST(i));
	}

#endif

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
	UA_BuildInfo_clear(&config->svc_serverconfig->buildInfo);
	UA_BuildInfo_copy(buildinfo, &config->svc_serverconfig->buildInfo);

UA_ApplicationDescription
UA_ServerConfig_getApplicationDescription(config)
	OPCUA_Open62541_ServerConfig	config
    CODE:
	UA_ApplicationDescription_copy(
	    &config->svc_serverconfig->applicationDescription, &RETVAL);
    OUTPUT:
	RETVAL

void
UA_ServerConfig_setApplicationDescription(config, applicationDescription)
	OPCUA_Open62541_ServerConfig		config
	OPCUA_Open62541_ApplicationDescription	applicationDescription
    CODE:
	UA_ApplicationDescription_clear(
	    &config->svc_serverconfig->applicationDescription);
	UA_ApplicationDescription_copy(applicationDescription,
	    &config->svc_serverconfig->applicationDescription);

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
	RETVAL =
	    config->svc_serverconfig->maxNodesPerTranslateBrowsePathsToNodeIds;
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
UA_ServerConfig_setMaxSubscriptionsPerSession(config, \
    maxSubscriptionsPerSession)
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
UA_ServerConfig_setMaxNotificationsPerPublish(config, \
    maxNotificationsPerPublish)
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
UA_ServerConfig_setMaxRetransmissionQueueSize(config, \
    maxRetransmissionQueueSize)
	OPCUA_Open62541_ServerConfig	config
	UA_UInt32			maxRetransmissionQueueSize
    CODE:
	config->svc_serverconfig->maxRetransmissionQueueSize =
	    maxRetransmissionQueueSize;

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
	if (SvTRUE(readonly)) {
		config->svc_serverconfig->accessControl.getUserRightsMask =
		    getUserRightsMask_readonly;
	} else {
		config->svc_serverconfig->accessControl.getUserRightsMask =
		    getUserRightsMask_default;
	}

void
UA_ServerConfig_setUserAccessLevelReadonly(config, readonly);
	OPCUA_Open62541_ServerConfig	config
	SV *				readonly
    CODE:
	if (SvTRUE(readonly)) {
		config->svc_serverconfig->accessControl.getUserAccessLevel =
		    getUserAccessLevel_readonly;
	} else {
		config->svc_serverconfig->accessControl.getUserAccessLevel =
		    getUserAccessLevel_default;
	}

void
UA_ServerConfig_disableUserExecutable(config, disable);
	OPCUA_Open62541_ServerConfig	config
	SV *				disable
    CODE:
	if (SvTRUE(disable)) {
		config->svc_serverconfig->accessControl.getUserExecutable =
		    getUserExecutable_false;
	} else {
		config->svc_serverconfig->accessControl.getUserExecutable =
		    getUserExecutable_default;
	}

void
UA_ServerConfig_disableUserExecutableOnObject(config, disable);
	OPCUA_Open62541_ServerConfig	config
	SV *				disable
    CODE:
	if (SvTRUE(disable)) {
		config->svc_serverconfig->accessControl.
		    getUserExecutableOnObject =
		    getUserExecutableOnObject_false;
	} else {
		config->svc_serverconfig->accessControl.
		    getUserExecutableOnObject =
		    getUserExecutableOnObject_default;
	}

void
UA_ServerConfig_disableAddNode(config, disable);
	OPCUA_Open62541_ServerConfig	config
	SV *				disable
    CODE:
	if (SvTRUE(disable)) {
		config->svc_serverconfig->accessControl.allowAddNode =
		    allowAddNode_false;
	} else {
		config->svc_serverconfig->accessControl.allowAddNode =
		    allowAddNode_default;
	}

void
UA_ServerConfig_disableAddReference(config, disable);
	OPCUA_Open62541_ServerConfig	config
	SV *				disable
    CODE:
	if (SvTRUE(disable)) {
		config->svc_serverconfig->accessControl.allowAddReference =
		    allowAddReference_false;
	} else {
		config->svc_serverconfig->accessControl.allowAddReference =
		    allowAddReference_default;
	}

void
UA_ServerConfig_disableDeleteNode(config, disable);
	OPCUA_Open62541_ServerConfig	config
	SV *				disable
    CODE:
	if (SvTRUE(disable)) {
		config->svc_serverconfig->accessControl.allowDeleteNode =
		    allowDeleteNode_false;
	} else {
		config->svc_serverconfig->accessControl.allowDeleteNode =
		    allowDeleteNode_default;
	}

void
UA_ServerConfig_disableDeleteReference(config, disable);
	OPCUA_Open62541_ServerConfig	config
	SV *				disable
    CODE:
	if (SvTRUE(disable)) {
		config->svc_serverconfig->accessControl.allowDeleteReference =
		    allowDeleteReference_false;
	} else {
		config->svc_serverconfig->accessControl.allowDeleteReference =
		    allowDeleteReference_default;
	}

#ifdef UA_ENABLE_HISTORIZING

void
UA_ServerConfig_disableHistoryUpdateUpdateData(config, disable);
	OPCUA_Open62541_ServerConfig	config
	SV *				disable
    CODE:
	if (SvTRUE(disable)) {
		config->svc_serverconfig->accessControl.
		    allowHistoryUpdateUpdateData =
		    allowHistoryUpdateUpdateData_false;
	} else {
		config->svc_serverconfig->accessControl.
		    allowHistoryUpdateUpdateData =
		    allowHistoryUpdateUpdateData_default;
	}

void
UA_ServerConfig_disableHistoryUpdateDeleteRawModified(config, disable);
	OPCUA_Open62541_ServerConfig	config
	SV *				disable
    CODE:
	if (SvTRUE(disable)) {
		config->svc_serverconfig->accessControl.
		    allowHistoryUpdateDeleteRawModified =
		    allowHistoryUpdateDeleteRawModified_false;
	} else {
		config->svc_serverconfig->accessControl.
		    allowHistoryUpdateDeleteRawModified =
		    allowHistoryUpdateDeleteRawModified_default;
	}

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
	OPCUA_Open62541_ClientConfig	config;
	OPCUA_Open62541_Logger		logger;
    CODE:
	config = &client->cl_config;
	logger = &config->clc_logger;
	DPRINTF("client %p, cl_client %p, cl_callbackdata %p, "
	    "config %p, logger %p",
	    client, client->cl_client, client->cl_callbackdata, config, logger);
	client->cl_config.clc_clientconfig->clientContext = ST(0);
	UA_Client_delete(client->cl_client);
	/* SvREFCNT_dec checks for NULL pointer. */
	SvREFCNT_dec(config->clc_clientcontext);
	SvREFCNT_dec(config->clc_statecallback);
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
	client->cl_config.clc_clientconfig->clientContext = ST(0);
	RETVAL = UA_Client_connect(client->cl_client, endpointUrl);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_connectAsync(client, endpointUrl)
	OPCUA_Open62541_Client		client
	char *				endpointUrl
    CODE:
	client->cl_config.clc_clientconfig->clientContext = ST(0);
	RETVAL = UA_Client_connectAsync(client->cl_client, endpointUrl);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_run_iterate(client, timeout)
	OPCUA_Open62541_Client		client
	UA_UInt32			timeout
    CODE:
	client->cl_config.clc_clientconfig->clientContext = ST(0);
	/* open62541 1.0 had UA_UInt16 timeout, it is implicitly casted */
	RETVAL = UA_Client_run_iterate(client->cl_client, timeout);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_disconnect(client)
	OPCUA_Open62541_Client		client
    CODE:
	client->cl_config.clc_clientconfig->clientContext = ST(0);
	RETVAL = UA_Client_disconnect(client->cl_client);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_disconnectAsync(client)
	OPCUA_Open62541_Client		client
    CODE:
	client->cl_config.clc_clientconfig->clientContext = ST(0);
	RETVAL = UA_Client_disconnectAsync(client->cl_client);
    OUTPUT:
	RETVAL

SV *
UA_Client_getState(client)
	OPCUA_Open62541_Client		client
    PREINIT:
	UA_SecureChannelState		channelState;
	UA_SessionState			sessionState;
	UA_StatusCode			connectStatus;
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
		pack_UA_StatusCode(ST(2), &connectStatus);
		XSRETURN(3);
		break;
	case G_SCALAR:
		/* open62541 1.0 API returns the client state. */
		RETVAL = &PL_sv_undef;
		CROAK("obsolete API, use client getState() in list context");
		break;
	default:
		RETVAL = &PL_sv_undef;
		break;
	}
    OUTPUT:
	RETVAL

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
		pack_UA_UInt32(SvRV(ST(4)), outoptReqId);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_Client_sendAsyncBrowseNextRequest(client, request, callback, data, \
    outoptReqId)
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
		pack_UA_UInt32(SvRV(ST(4)), outoptReqId);
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
		pack_UA_UInt32(SvRV(ST(4)), outoptReqId);
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
UA_Client_Subscriptions_create(client, request, subscriptionContext, \
    statusChangeCallback, deleteCallback)
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

	DPRINTF("client %p, sub %p, sc_change %p, sc_delete %p",
	    client, sub, sub->sc_change, sub->sc_delete);

	RETVAL = UA_Client_Subscriptions_create(client->cl_client, *request,
	    sub, clientStatusChangeNotificationCallback,
	    clientDeleteSubscriptionCallback);

	/*
	 * Old open62541 1.0 did not call callback on failure.  The logic
	 * introduced in 2d5355b7be11233e67d5ff6be6b2a34e971e1814 does
	 * it in most cases.
	 */
	if (RETVAL.responseHeader.serviceResult ==
	    UA_STATUSCODE_BADOUTOFMEMORY) {
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
	RETVAL = UA_Client_Subscriptions_deleteSingle(client->cl_client,
	    subscriptionId);
    OUTPUT:
	RETVAL

UA_SetPublishingModeResponse
UA_Client_Subscriptions_setPublishingMode(client, request)
	OPCUA_Open62541_Client				client
	OPCUA_Open62541_SetPublishingModeRequest	request
    CODE:
	RETVAL = UA_Client_Subscriptions_setPublishingMode(client->cl_client,
	    *request);
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
UA_Client_MonitoredItems_createDataChanges(client, request, contextsSV, \
    callbacksSV, deleteCallbacksSV)
	OPCUA_Open62541_Client				client
	OPCUA_Open62541_CreateMonitoredItemsRequest	request
	SV *						contextsSV
	SV *						callbacksSV
	SV *						deleteCallbacksSV
    PREINIT:
	size_t						itemsToCreateSize;
	size_t						i;
	ssize_t						top;
	AV *						contextsAV;
	AV *						callbacksAV;
	AV *						deleteCallbacksAV;
	SV **						contextSV;
	SV **						callbackSV;
	SV **						deleteCallbackSV;
	OPCUA_Open62541_MonitoredItemArrays		marr;
	SV *						marrSV;
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
		if (!SvROK(callbacksSV) ||
		    SvTYPE(SvRV(callbacksSV)) != SVt_PVAV) {
			CROAK("Not an ARRAY reference for callbacks");
		}
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
		if (!SvROK(deleteCallbacksSV) ||
		    SvTYPE(SvRV(deleteCallbacksSV)) != SVt_PVAV) {
			CROAK("Not an ARRAY reference for deleteCallbacks");
		}
		deleteCallbacksAV = (AV*)SvRV(deleteCallbacksSV);

		top = av_top_index(deleteCallbacksAV);
		if (top == -1)
			CROAK("No elements in deleteCallbacks");
		if ((size_t)(top + 1) != itemsToCreateSize)
			CROAK("Not enough elements in deleteCallbacks");
	} else {
		deleteCallbacksAV = NULL;
	}

	marr = calloc(1, sizeof(*marr));
	if (marr == NULL)
		CROAKE("calloc");
	/*
	 * Convert struct MonitoredItemArrays into a PV.  This
	 * allows to use Perl's ref counting for memory management.
	 * The destroy function will free everything.  Leaks can
	 * be found with Test::LeakTrace.
	 */
	marrSV = sv_2mortal(sv_setref_pv(newSV(0),
	    "OPCUA::Open62541::MonitoredItemArrays", marr));

	marr->ma_mon = calloc(itemsToCreateSize, sizeof(*marr->ma_mon));
	marr->ma_context = calloc(itemsToCreateSize, sizeof(*marr->ma_context));
	marr->ma_change = calloc(itemsToCreateSize, sizeof(*marr->ma_change));
	marr->ma_delete = calloc(itemsToCreateSize, sizeof(*marr->ma_delete));
	if (marr->ma_mon == NULL || marr->ma_context == NULL ||
	    marr->ma_change == NULL || marr->ma_delete == NULL) {
		/* The destroy function of the mortal marrSV will free. */
		CROAKE("calloc");
	}

	for (i = 0; i < itemsToCreateSize; i++) {
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
			marr->ma_mon[i].mc_change = newClientCallbackData(
			    *callbackSV, ST(0), *contextSV);
		if (deleteCallbackSV != NULL && SvOK(*deleteCallbackSV))
			marr->ma_mon[i].mc_delete = newClientCallbackData(
			    *deleteCallbackSV, ST(0), *contextSV);
		marr->ma_mon[i].mc_arrays = SvREFCNT_inc(marrSV);

		marr->ma_context[i] = &marr->ma_mon[i];
		marr->ma_change[i] = clientDataChangeNotificationCallback;
		marr->ma_delete[i] = clientDeleteMonitoredItemCallback;
	}

	DPRINTF("client %p, items %zu, marr %p, ma_mon %p, ma_context %p, "
	    "ma_change %p, ma_delete %p",
	    client, itemsToCreateSize, marr, marr->ma_mon, marr->ma_context,
	    marr->ma_change, marr->ma_delete);

	RETVAL = UA_Client_MonitoredItems_createDataChanges(client->cl_client,
	    *request, marr->ma_context, marr->ma_change, marr->ma_delete);

	if (SvREFCNT(marrSV) > 1 &&
	    RETVAL.responseHeader.serviceResult != UA_STATUSCODE_GOOD) {
		for (i = 0; i < itemsToCreateSize; i++) {
			if (marr->ma_mon[i].mc_delete)
				deleteClientCallbackData(
				    marr->ma_mon[i].mc_delete);
			if (marr->ma_mon[i].mc_change)
				deleteClientCallbackData(
				    marr->ma_mon[i].mc_change);
			/*
			 * When mc_arrays ref count reaches 0, Perl will free
			 * everything in MonitoredItemArrays destroy function.
			 */
			SvREFCNT_dec(marr->ma_mon[i].mc_arrays);
		}
	}
    OUTPUT:
	RETVAL

UA_MonitoredItemCreateResult
UA_Client_MonitoredItems_createDataChange(client, subscriptionId, \
    timestampsToReturn, item, context, callback, deleteCallback)
	OPCUA_Open62541_Client				client
	UA_UInt32					subscriptionId
	UA_TimestampsToReturn				timestampsToReturn
	OPCUA_Open62541_MonitoredItemCreateRequest	item
	SV *						context
	SV *						callback
	SV *						deleteCallback
    PREINIT:
	OPCUA_Open62541_MonitoredItemArrays		marr;
	SV *						marrSV;
    CODE:
	marr = calloc(1, sizeof(*marr));
	if (marr == NULL)
		CROAKE("calloc");
	/*
	 * Convert struct MonitoredItemArrays into a PV.  This
	 * allows to use Perl's ref counting for memory management.
	 * The destroy function will free everything.  Leaks can
	 * be found with Test::LeakTrace.
	 */
	marrSV = sv_2mortal(sv_setref_pv(newSV(0),
	    "OPCUA::Open62541::MonitoredItemArrays", marr));

	marr->ma_mon = calloc(1, sizeof(*marr->ma_mon));
	if (marr->ma_mon == NULL) {
		/* The destroy function of the mortal marrSV will free. */
		CROAKE("calloc");
	}
	if (SvOK(callback))
		marr->ma_mon[0].mc_change = newClientCallbackData(
		    callback, ST(0), context);
	if (SvOK(deleteCallback))
		marr->ma_mon[0].mc_delete = newClientCallbackData(
		    deleteCallback, ST(0), context);
	marr->ma_mon[0].mc_arrays = SvREFCNT_inc(marrSV);

	DPRINTF("client %p, marr %p, ma_mon %p, mc_change %p, mc_delete %p",
	    client, marr, marr->ma_mon,
	    marr->ma_mon[0].mc_change, marr->ma_mon[0].mc_delete);

	RETVAL = UA_Client_MonitoredItems_createDataChange(client->cl_client,
	    subscriptionId, timestampsToReturn, *item, &marr->ma_mon[0],
	    clientDataChangeNotificationCallback,
	    clientDeleteMonitoredItemCallback);

	if (SvREFCNT(marrSV) > 1 && RETVAL.statusCode != UA_STATUSCODE_GOOD) {
		if (marr->ma_mon[0].mc_delete)
			deleteClientCallbackData(marr->ma_mon[0].mc_delete);
		if (marr->ma_mon[0].mc_change)
			deleteClientCallbackData(marr->ma_mon[0].mc_change);
		/*
		 * When mc_arrays ref count reaches 0, Perl will free
		 * everything in MonitoredItemArrays destroy function.
		 */
		SvREFCNT_dec(marr->ma_mon[0].mc_arrays);
	}
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

#ifdef UA_ENABLE_ENCRYPTION

UA_StatusCode
UA_ClientConfig_setDefaultEncryption(config, localCertificate, privateKey, \
    trustListRAV = &PL_sv_undef, revocationListRAV = &PL_sv_undef)
	OPCUA_Open62541_ClientConfig	config
	OPCUA_Open62541_ByteString	localCertificate
	OPCUA_Open62541_ByteString	privateKey
	SV *				trustListRAV
	SV *				revocationListRAV
    PREINIT:
	UA_ByteString *			trustList;
	size_t				trustListSize;
	UA_ByteString *			revocationList;
	size_t				revocationListSize;
    CODE:
	unpack_UA_ByteString_List(&trustList, &trustListSize, trustListRAV);
	unpack_UA_ByteString_List(&revocationList, &revocationListSize,
	    revocationListRAV);

	RETVAL = UA_ClientConfig_setDefaultEncryption(config->clc_clientconfig,
	    *localCertificate, *privateKey, trustList, trustListSize,
	    revocationList, revocationListSize);

	/* accept all certificates as fallback ? */
	if (trustList == NULL && revocationList == NULL) {
		UA_CertificateVerification_AcceptAll(
		    &config->clc_clientconfig->certificateVerification);
	}
    OUTPUT:
	RETVAL

#endif /* UA_ENABLE_ENCRYPTION */

void
UA_ClientConfig_setUsernamePassword(config, userName, password)
	OPCUA_Open62541_ClientConfig	config
	SV *				userName
	SV *				password
    PREINIT:
	UA_UserNameIdentityToken *	identityToken;
    CODE:
	UA_ExtensionObject_clear(&config->clc_clientconfig->userIdentityToken);

	/*
	 * The userTokenPolicy and endpoint have to be removed from the
	 * client config or open62541 may try to use the userTokenPolicy
	 * of a previous connection.
	 */
	UA_UserTokenPolicy_clear(&config->clc_clientconfig->userTokenPolicy);
	UA_EndpointDescription_clear(&config->clc_clientconfig->endpoint);

	if (!SvOK(userName) || !SvCUR(userName))
		XSRETURN_EMPTY;

	identityToken = UA_UserNameIdentityToken_new();
	if (identityToken == NULL)
		CROAKE("UA_UserNameIdentityToken_new");

	config->clc_clientconfig->userIdentityToken.encoding =
	    UA_EXTENSIONOBJECT_DECODED;
	config->clc_clientconfig->userIdentityToken.content.decoded.type =
	    &UA_TYPES[UA_TYPES_USERNAMEIDENTITYTOKEN];
	config->clc_clientconfig->userIdentityToken.content.decoded.data =
	    identityToken;

	unpack_UA_String(&identityToken->userName, userName);
	unpack_UA_String(&identityToken->password, password);

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

UA_MessageSecurityMode
UA_ClientConfig_getSecurityMode(config)
	OPCUA_Open62541_ClientConfig	config
    CODE:
	UA_MessageSecurityMode_copy(&config->clc_clientconfig->securityMode,
	    &RETVAL);
    OUTPUT:
	RETVAL

void
UA_ClientConfig_setSecurityMode(config, securityMode)
	OPCUA_Open62541_ClientConfig		config
	OPCUA_Open62541_MessageSecurityMode	securityMode
    CODE:
	UA_MessageSecurityMode_clear(&config->clc_clientconfig->securityMode);
	UA_MessageSecurityMode_copy(securityMode,
	    &config->clc_clientconfig->securityMode);

#ifdef HAVE_UA_CLIENTCONFIG_APPLICATIONURI

SV *
UA_ClientConfig_getApplicationUri(config)
	OPCUA_Open62541_ClientConfig	config
    CODE:
	RETVAL = sv_2mortal(newSV(0));
	pack_UA_String(RETVAL, &config->clc_clientconfig->applicationUri);
	SvREFCNT_inc_NN(RETVAL);
    OUTPUT:
	RETVAL

void
UA_ClientConfig_setApplicationUri(config, applicationUri)
	OPCUA_Open62541_ClientConfig	config
	SV *				applicationUri
    CODE:
	UA_String_clear(&config->clc_clientconfig->applicationUri);
	unpack_UA_String(&config->clc_clientconfig->applicationUri,
	    applicationUri);

#endif /* HAVE_UA_CLIENTCONFIG_APPLICATIONURI */

UA_ApplicationDescription
UA_ClientConfig_getClientDescription(config)
	OPCUA_Open62541_ClientConfig	config
    CODE:
	UA_ApplicationDescription_copy(
	    &config->clc_clientconfig->clientDescription, &RETVAL);
    OUTPUT:
	RETVAL

void
UA_ClientConfig_setClientDescription(config, clientDescription)
	OPCUA_Open62541_ClientConfig		config
	OPCUA_Open62541_ApplicationDescription	clientDescription
    CODE:
	UA_ApplicationDescription_clear(
	    &config->clc_clientconfig->clientDescription);
	UA_ApplicationDescription_copy(clientDescription,
	    &config->clc_clientconfig->clientDescription);

void
UA_ClientConfig_setStateCallback(config, callback)
	OPCUA_Open62541_ClientConfig	config
	SV *				callback
    INIT:
	if (SvOK(callback) &&
	    !(SvROK(callback) && SvTYPE(SvRV(callback)) == SVt_PVCV)) {
		CROAK("Callback '%s' is not a CODE reference",
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

#############################################################################
MODULE = OPCUA::Open62541	PACKAGE = OPCUA::Open62541::CertificateVerification	PREFIX = UA_CertificateVerification_

OPCUA_Open62541_CertificateVerification
UA_CertificateVerification_new(class)
	char *				class
    INIT:
	if (strcmp(class, "OPCUA::Open62541::CertificateVerification") != 0)
		CROAK("Class '%s' is not "
		    "OPCUA::Open62541::CertificateVerification", class);
    CODE:
	RETVAL = UA_CertificateVerification_new();
	if (RETVAL == NULL)
		CROAKE("UA_CertificateVerification_new");
	DPRINTF("class %s, verifyX509 %p", class, RETVAL);
    OUTPUT:
	RETVAL

UA_StatusCode
UA_CertificateVerification_Trustlist(verifyX509, trustListRAV, issuerListRAV, \
    revocationListRAV)
	OPCUA_Open62541_CertificateVerification	verifyX509
	SV *					trustListRAV
	SV *					issuerListRAV
	SV *					revocationListRAV
    PREINIT:
	UA_ByteString *				trustList;
	size_t					trustListSize;
	UA_ByteString *				issuerList;
	size_t					issuerListSize;
	UA_ByteString *				revocationList;
	size_t					revocationListSize;
    CODE:
	unpack_UA_ByteString_List(&trustList, &trustListSize, trustListRAV);
	unpack_UA_ByteString_List(&issuerList, &issuerListSize, issuerListRAV);
	unpack_UA_ByteString_List(&revocationList, &revocationListSize,
	    revocationListRAV);

	RETVAL = UA_CertificateVerification_Trustlist(verifyX509, trustList,
	    trustListSize, issuerList, issuerListSize, revocationList,
	    revocationListSize);
    OUTPUT:
	RETVAL
