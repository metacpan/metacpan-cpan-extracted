/* -*- c -*- */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "libxwrite.h"
#include <string.h>
#include <glib.h>

#ifndef PERL_UNUSED_VAR
#define PERL_UNUSED_VAR(var) if (0) var = var
#endif

/* マクロ */
#if defined(NDEBUG)
#define passert(COND) ((void)0)
#else
#define passert(COND) \
    do {                                                                \
        if (!G_LIKELY((COND))) {					\
            croak("assertion failed: %s(%d): %s", __FILE__, __LINE__, #COND); \
        }                                                               \
    } while (0)
#endif


/* データ型 */
typedef struct {
    XWrite* writer;
    SV*     src;
} deparser_context_t;

typedef void(*deparse_func_t)(deparser_context_t* this, const gchar* type, SV* src);


/* 定数 */
static GTree* deparser_functions;


/* 初期化 */
static void init_module();


/* 本体 */
static void deparse_rpc_xml(deparser_context_t* this, SV* src);
static void deparse_simple_type(deparser_context_t* this, const char* type, SV* src);
static void deparse_array(deparser_context_t* this, const char* type, SV* src);
static void deparse_struct(deparser_context_t* this, const char* type, SV* src);
static void deparse_base64(deparser_context_t* this, const char* type, SV* src);
static void deparse_fault(deparser_context_t* this, const char* type, SV* src);
static void deparse_request(deparser_context_t* this, const char* type, SV* src);
static void deparse_response(deparser_context_t* this, const char* type, SV* src);

/* 実装 */
static void init_module() {
    deparser_functions = g_tree_new((gpointer)&strcmp);

#define REGISTER_DEPARSER_FUNC(TYPE, FUNC)		\
    g_tree_insert(deparser_functions, #TYPE, (FUNC));

    REGISTER_DEPARSER_FUNC(int             , &deparse_simple_type);
    REGISTER_DEPARSER_FUNC(i4              , &deparse_simple_type);
    REGISTER_DEPARSER_FUNC(double          , &deparse_simple_type);
    REGISTER_DEPARSER_FUNC(string          , &deparse_simple_type);
    REGISTER_DEPARSER_FUNC(boolean         , &deparse_simple_type);
    REGISTER_DEPARSER_FUNC(datetime_iso8601, &deparse_simple_type);
    REGISTER_DEPARSER_FUNC(array           , &deparse_array);
    REGISTER_DEPARSER_FUNC(struct          , &deparse_struct);
    REGISTER_DEPARSER_FUNC(base64          , &deparse_base64);
    REGISTER_DEPARSER_FUNC(fault           , &deparse_fault);
    REGISTER_DEPARSER_FUNC(request         , &deparse_request);
    REGISTER_DEPARSER_FUNC(response        , &deparse_response);
}

static void deparse_rpc_xml(deparser_context_t* this, SV* src) {
    const gchar* reftype;

    if (!G_LIKELY(SvROK(src))) {
	croak("deparse_rpc_xml: src is not an RV");
    }

    reftype = sv_reftype(SvRV(src), TRUE);

    if (G_LIKELY(g_str_has_prefix(reftype, "RPC::XML::"))) {
	const gchar*         type    = reftype + strlen("RPC::XML::");
	const deparse_func_t deparse = g_tree_lookup(deparser_functions, type);
	
	if (deparse == NULL) {
	    croak("deparse_rpc_xml: unknown type: %s", reftype);
	}
	else {
	    deparse(this, type, src);
	}
    }
    else {
	croak("deparse_rpc_xml: src is not of type RPC::XML::* : %s", reftype);
    }
}

static void deparse_simple_type(deparser_context_t* this, const char* type, SV* src) {
    SV*    val;

    passert(SvROK(src));
    val = SvRV(src);

    if (G_UNLIKELY(strcmp(type, "datetime_iso8601") == 0)) {
	/* 特例 */
	xwrite_start_element(this->writer, "dateTime.iso8601");
	xwrite_add_text(this->writer, SvPV_nolen(val));
	xwrite_end_element(this->writer, "dateTime.iso8601");
    }
    else {
	xwrite_start_element(this->writer, type);
	xwrite_add_text(this->writer, SvPV_nolen(val));
	xwrite_end_element(this->writer, type);
    }
}

static void deparse_array(deparser_context_t* this, const char* type, SV* src) {
    I32 i, len;
    AV* array;

    PERL_UNUSED_VAR(type);

    passert(SvROK(src) && SvTYPE(SvRV(src)) == SVt_PVAV);
    array = (AV*)SvRV(src);

    xwrite_start_element(this->writer, "array");
    xwrite_start_element(this->writer, "data");

    len = av_len((AV*)array);
    for (i = 0; G_LIKELY(i <= len); i++) {
	SV** e;

	e = av_fetch((AV*)array, i, FALSE);
	passert(e != NULL);

	xwrite_start_element(this->writer, "value");
	deparse_rpc_xml(this, *e);
	xwrite_end_element(this->writer, "value");
    }

    xwrite_end_element(this->writer, "data");
    xwrite_end_element(this->writer, "array");
}

static void deparse_struct(deparser_context_t* this, const char* type, SV* src) {
    HV* hash;

    PERL_UNUSED_VAR(type);

    passert(SvROK(src) && SvTYPE(SvRV(src)) == SVt_PVHV);
    hash = (HV*)SvRV(src);

    xwrite_start_element(this->writer, "struct");

    hv_iterinit((HV*)hash);
    while (TRUE) {
	const gchar* key;
	I32          keylen;
	SV*          e;
	
	e = hv_iternextsv(hash, (char**)&key, &keylen);

	if (G_UNLIKELY(e == NULL)) {
	    break;
	}
	else {
	    xwrite_start_element(this->writer, "member");

	    xwrite_start_element(this->writer, "name");
	    xwrite_add_text(this->writer, key);
	    xwrite_end_element(this->writer, "name");

	    xwrite_start_element(this->writer, "value");
	    deparse_rpc_xml(this, e);
	    xwrite_end_element(this->writer, "value");
	    
	    xwrite_end_element(this->writer, "member");
	}
    }

    xwrite_end_element(this->writer, "struct");
}

static void deparse_base64(deparser_context_t* this, const char* type, SV* src) {
    gchar* decoded;

    PERL_UNUSED_VAR(type);

    xwrite_start_element(this->writer, "base64");

    do {
	SV*    value;
	gchar* buf;
	STRLEN buf_len;
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK(sp);
	XPUSHs((SV*)src);
	PUTBACK;

	call_method("value", G_SCALAR);

	SPAGAIN;
	value = POPs;
	buf   = SvPV(value, buf_len);
	xwrite_add_base64(this->writer, buf, buf_len);
	PUTBACK;

	FREETMPS;
	LEAVE;
    } while (0);

    xwrite_end_element(this->writer, "base64");
}

static void deparse_fault(deparser_context_t* this, const char* type, SV* src) {
    xwrite_start_element(this->writer, "fault");
    xwrite_start_element(this->writer, "value");

    deparse_struct(this, type, src);

    xwrite_end_element(this->writer, "value");
    xwrite_end_element(this->writer, "fault");
}

static void deparse_request(deparser_context_t* this, const char* type, SV* src) {
    HV* hash;

    PERL_UNUSED_VAR(type);

    passert(SvROK(src) && SvTYPE(SvRV(src)) == SVt_PVHV);
    hash = (HV*)SvRV(src);

    xwrite_start_document(this->writer, NULL, NULL, NULL);
    xwrite_start_element(this->writer, "methodCall");
    
    do {
	SV**   sv_name_ptr = hv_fetch((HV*)hash, "name", strlen("name"), FALSE);
	SV*    sv_name;

	passert(sv_name_ptr != NULL);
	sv_name = *sv_name_ptr;

	xwrite_start_element(this->writer, "methodName");
	xwrite_add_text(this->writer, SvPV_nolen(sv_name));
	xwrite_end_element(this->writer, "methodName");
    } while (0);

    do {
	SV** sv_args_ptr = hv_fetch((HV*)hash, "args", strlen("args"), FALSE);
	AV*  av_args;
	I32  i;

	passert(sv_args_ptr != NULL);
	passert(SvROK(*sv_args_ptr) && SvTYPE(SvRV(*sv_args_ptr)) == SVt_PVAV);
	av_args = (AV*)SvRV(*sv_args_ptr);

	xwrite_start_element(this->writer, "params");
	for (i = 0; i <= av_len((AV*)av_args); i++) {
	    SV** argp;

	    argp = av_fetch((AV*)av_args, i, FALSE);
	    passert(argp != NULL);
	    
	    xwrite_start_element(this->writer, "param");
	    xwrite_start_element(this->writer, "value");
	    deparse_rpc_xml(this, *argp);
	    xwrite_end_element(this->writer, "value");
	    xwrite_end_element(this->writer, "param");
	}
	xwrite_end_element(this->writer, "params");
    } while (0);
    
    xwrite_end_element(this->writer, "methodCall");
    xwrite_end_document(this->writer);
}

static void deparse_response(deparser_context_t* this, const char* type, SV* src) {
    HV* hash;

    PERL_UNUSED_VAR(type);

    passert(SvROK(src) && SvTYPE(SvRV(src)) == SVt_PVHV);
    hash = (HV*)SvRV(src);

    xwrite_start_document(this->writer, NULL, NULL, NULL);
    xwrite_start_element(this->writer, "methodResponse");
    
    do {
	SV** sv_value_ptr = hv_fetch((HV*)hash, "value", strlen("value"), FALSE);
	SV*  sv_value;
	const gchar* reftype;

	passert(sv_value_ptr != NULL);
	sv_value = *sv_value_ptr;

	passert(SvROK(sv_value));
	reftype = sv_reftype(SvRV(sv_value), TRUE);

	if (strcmp(reftype, "RPC::XML::fault") == 0) {
	    deparse_fault(this, reftype, sv_value);
	}
	else {
	    xwrite_start_element(this->writer, "params");
	    xwrite_start_element(this->writer, "param");
	    xwrite_start_element(this->writer, "value");
	    deparse_rpc_xml(this, sv_value);
	    xwrite_end_element(this->writer, "value");
	    xwrite_end_element(this->writer, "param");
	    xwrite_end_element(this->writer, "params");
	}
    } while (0);
    
    xwrite_end_element(this->writer, "methodResponse");
    xwrite_end_document(this->writer);
}


MODULE = RPC::XML::Deparser::XS		PACKAGE = RPC::XML::Deparser::XS

SV*
deparse_rpc_xml(SV* src)
    PROTOTYPE: $
    CODE:
        SV* obj;

        {
            /* Writer オブジェクトを作成 */
            dSP;

            ENTER;
            SAVETMPS;

            PUSHMARK(sp);
            XPUSHs(
                sv_2mortal(
                    newSVpv(
                        "RPC::XML::Deparser::XS::Writer",
                        strlen("RPC::XML::Deparser::XS::Writer"))));
            XPUSHs(src);
            PUTBACK;

            call_method("new_string_writer", G_SCALAR);

            SPAGAIN;
            obj = SvREFCNT_inc(POPs);
            PUTBACK;

            FREETMPS;
            LEAVE;
        }

        sv_2mortal(obj);

        {
            /* run を呼ぶ */
            dSP;

            ENTER;
            SAVETMPS;

            PUSHMARK(sp);
            XPUSHs(obj);
            PUTBACK;

            call_method("run", G_SCALAR);

            SPAGAIN;
            RETVAL = SvREFCNT_inc(POPs);
            PUTBACK;

            FREETMPS;
            LEAVE;
        }

    OUTPUT:
        RETVAL


MODULE = RPC::XML::Deparser::XS       PACKAGE = RPC::XML::Deparser::XS::Writer

deparser_context_t*
new_string_writer(char* class, SV* src)
   CODE:
        deparser_context_t* this;
        init_module();

        PERL_UNUSED_VAR(class);
        /* deparser_context_t* を blessed pointer にしなければ croak 時
         * にメモリを自動的に解放させる事が出来ない。
         */
        this = malloc(sizeof(deparser_context_t));

        if (this == NULL) {
            croak("failed to allocate deparser_context_t");
        }

        this->writer = xwrite_new(0);
        if (this->writer == NULL) {
            free(this);
            croak("Failed to create XML string writer");
        }

        this->src = SvREFCNT_inc(src);

        RETVAL = this;

    OUTPUT:
        RETVAL

SV*
run(deparser_context_t* this)
    CODE:
        do {
	    gchar* tmp;

	    deparse_rpc_xml(this, this->src);

	    tmp = xwrite_get_result(this->writer);
	    RETVAL = newSVpv(tmp, 0);
	    g_free(tmp);
	} while (0);

    OUTPUT:
        RETVAL

void
DESTROY(deparser_context_t* this)
    CODE:
        xwrite_free(this->writer);
        SvREFCNT_dec(this->src);
        free(this);
