/* -*- c -*- */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libxml/xmlreader.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#ifndef PERL_UNUSED_VAR
#define PERL_UNUSED_VAR(var) if (0) var = var
#endif

#if LIBXML_VERSION < 20622
#define XML_PARSE_COMPACT 0
#endif

/* このモジュールの至る所で sv_2mortal している理由は、エラー処理を
 * croak に任せている為。定命でなければエラー時にメモリリークが起こる。
 */

/* マクロ */

#if defined(NDEBUG)
#define passert(COND) ((void)0)
#else
#define passert(COND) \
    do {                                                                \
        if (! (COND)) {                                                 \
            croak("assertion failed: %s(%d): %s", __FILE__, __LINE__, #COND); \
        }                                                               \
    } while (0)
#endif

#define INTERN(this, var, str)                              \
    (this)->var == NULL                                     \
        ? intern_string((this), &(this)->var, BAD_CAST str) \
        : (this)->var

/* データ型 */

typedef struct {
    xmlTextReaderPtr reader;

    const xmlChar* s_array;
    const xmlChar* s_base64;
    const xmlChar* s_boolean;
    const xmlChar* s_data;
    const xmlChar* s_dateTime_iso8601;
    const xmlChar* s_double;
    const xmlChar* s_fault;
    const xmlChar* s_i4;
    const xmlChar* s_int;
    const xmlChar* s_member;
    const xmlChar* s_methodCall;
    const xmlChar* s_methodName;
    const xmlChar* s_methodResponse;
    const xmlChar* s_name;
    const xmlChar* s_param;
    const xmlChar* s_params;
    const xmlChar* s_string;
    const xmlChar* s_struct;
    const xmlChar* s_value;
} parser_context_t;


/* 初期化 */
static void init_module();

/* intern */
static const xmlChar* intern_string(
    parser_context_t* this, const xmlChar** field, const xmlChar* str);

/* エラーハンドラ */
static void xml_error_handler(void* arg, xmlErrorPtr error);

/* ノード移動 */
static void go_next_node(parser_context_t* this);
static void skip_until(parser_context_t* this, xmlReaderTypes type);
static int skip_until_2(parser_context_t* this, xmlReaderTypes type1, xmlReaderTypes type2);
static int skip_until_3(parser_context_t* this, xmlReaderTypes type1, xmlReaderTypes type2, xmlReaderTypes type3);
static void go_next_element(parser_context_t* this);
static void go_next_text(parser_context_t* this);

/* 期待 */
static void croak_for_unexpected_element(parser_context_t* this, const char* expected);
static void expect_element_name(parser_context_t* this, const xmlChar* expected);
static void expect_closing_element_name(parser_context_t* this, const xmlChar* expected);
static void expect_int_value(const xmlChar* str);
static void expect_boolean_value(const xmlChar* str);

/* 試験 */
/*
static int is_name_equal_to(parser_context_t* this, const xmlChar* str);
*/

/* perl オブジェクト生成 */
static SV* wrap_simple_type(const char* class, const xmlChar* str);

/* 解析 */
static SV* parse_int(parser_context_t* this);
static SV* parse_boolean(parser_context_t* this);
static SV* parse_string(parser_context_t* this);
static SV* parse_double(parser_context_t* this);
static SV* parse_dateTime_iso8601(parser_context_t* this);
static SV* parse_base64(parser_context_t* this);
static SV* parse_struct(parser_context_t* this);
static SV* parse_array(parser_context_t* this);
static SV* parse_value(parser_context_t* this);
static SV* parse_param(parser_context_t* this);
static AV* parse_params(parser_context_t* this);
static SV* parse_fault(parser_context_t* this);
static SV* parse_methodCall(parser_context_t* this);
static SV* parse_methodResponse(parser_context_t* this);
static SV* parse_rpc_xml(parser_context_t* this);


static void init_module() {
    LIBXML_TEST_VERSION;

    eval_pv("use RPC::XML     ();", TRUE);
    eval_pv("use MIME::Base64 ();", TRUE);

    /* Reader のコンテクスト外でエラーが起きた時に呼ばれる。 */
    xmlSetStructuredErrorFunc(NULL, xml_error_handler);
}

static const xmlChar* intern_string(
    parser_context_t* this, const xmlChar** field, const xmlChar* str) {
    
    *field = xmlTextReaderConstString(this->reader, str);
    return *field;
}

static void xml_error_handler(void* arg, xmlErrorPtr error) {
    switch (error->level) {
    case XML_ERR_NONE:
        /* no error? */
        break;

    case XML_ERR_WARNING:
        warn(
            "XML parser warning: line %d: %s",
            error->line,
            error->message);
        break;

    case XML_ERR_ERROR:
        croak(
            "XML parser error: line %d: %s",
            error->line,
            error->message);
        break;

    case XML_ERR_FATAL:
        croak(
            "XML parser fatal error: line %d: %s",
            error->line,
            error->message);

    default:
        croak(
            "XML parser unknown error: line %d: %s",
            error->line,
            error->message);
    }
}

static void go_next_node(parser_context_t* this) {
    switch (xmlTextReaderRead(this->reader)) {
    case 0:
        croak("ran short of XML node");
        break;

    case 1:
        /* ok */
        break;

    default:
        /* エラーだが、xml_error_handler が croak するのでここには来ない */
        croak("internal error: unreachable point");
        break;
    }
}

static void skip_until(parser_context_t* this, xmlReaderTypes type) {
    while (1) {
        if (xmlTextReaderNodeType(this->reader) == type) {
            break;
        }

        go_next_node(this);
    }
}

static int skip_until_2(parser_context_t* this, xmlReaderTypes type1, xmlReaderTypes type2) {
    while (1) {
        int type = xmlTextReaderNodeType(this->reader);

        if (type == type1 || type == type2) {
            return type;
        }

        go_next_node(this);
    }
}

static int skip_until_3(parser_context_t* this, xmlReaderTypes type1, xmlReaderTypes type2, xmlReaderTypes type3) {
    while (1) {
        int type = xmlTextReaderNodeType(this->reader);

        if (type == type1 || type == type2 || type == type3) {
            return type;
        }

        go_next_node(this);
    }
}

static void go_next_element(parser_context_t* this) {
    go_next_node(this);
    skip_until(this, XML_READER_TYPE_ELEMENT);
}

static void go_next_text(parser_context_t* this) {
    /* CDATA は TEXT に融合している事が前提 */
    go_next_node(this);
    skip_until(this, XML_READER_TYPE_TEXT);
}

static void croak_for_unexpected_element(parser_context_t* this, const char* expected) {
    croak(
        "unexpected XML element: line %d: expected %s: got `%s'",
        xmlTextReaderGetParserLineNumber(this->reader),
        expected,
        xmlTextReaderConstName(this->reader));
}

static void expect_element_name(parser_context_t* this, const xmlChar* expected) {
    const xmlChar* name = xmlTextReaderConstName(this->reader);

    passert(xmlTextReaderNodeType(this->reader) == XML_READER_TYPE_ELEMENT);
    
    if (xmlStrcmp(name, expected) != 0) {
        croak(
            "unexpected XML element: line %d: expected `%s': got `%s'",
            xmlTextReaderGetParserLineNumber(this->reader),
            expected,
            xmlTextReaderConstName(this->reader));
    }
}

static void expect_closing_element_name(parser_context_t* this, const xmlChar* expected) {
    const xmlChar* name = xmlTextReaderConstName(this->reader);

    passert(xmlTextReaderNodeType(this->reader) == XML_READER_TYPE_END_ELEMENT);

    if (xmlStrcmp(name, expected) != 0) {
        croak(
            "unexpected closing XML element: line %d: expected `%s': got `%s'",
            xmlTextReaderGetParserLineNumber(this->reader),
            expected,
            xmlTextReaderConstName(this->reader));
    }
}

static void expect_int_value(const xmlChar* str) {
    /* int ::= ('-' | '+')? DIGIT+
     */
    const xmlChar* ptr = str;

    if (*ptr != '+' && *ptr != '-' && !isdigit(*ptr)) {
        croak("invalid integer: %s", str);
    }

    if (!isdigit(*ptr)) {
        /* ('-' | '+') だった */
        ptr++;

        /* 最低でも DIGIT は一つは無ければならない */
        if (!isdigit(*ptr)) {
            croak("invalid integer: %s", str);
        }
        ptr++;
    }

    for (; *ptr != '\0'; ptr++) {
        if (!isdigit(*ptr)) {
            croak("invalid integer: %s", str);
        }
    }
}

static void expect_boolean_value(const xmlChar* str) {
    /* boolean :: '0' | '1' */
    const xmlChar* ptr = str;

    if (*ptr != '0' && *ptr != '1') {
        croak("invalid boolean: %s", str);
    }
    ptr++;

    if (*ptr != '\0') {
        croak("invalid boolean: %s", str);
    }
}

/*
static int is_name_equal_to(parser_context_t* this, const xmlChar* str) {
    const xmlChar* name = xmlTextReaderConstName(this->reader);

    return xmlStrcmp(name, str) == 0 ? TRUE : FALSE;
}
*/

static SV* wrap_simple_type(const char* class, const xmlChar* str) {
    /* 常に bless \(my $o = 'xxx') => 'RPC::XML::*' という形になる。
     * この関数が返す SV* は定命でない事に注意せよ。
     */
    HV* stash = gv_stashpv(class, TRUE);
    SV* ref   = newRV_noinc(newSVpv((const char*)str, 0));

    return sv_bless(ref, stash);
}

static SV* parse_int(parser_context_t* this) {
    const xmlChar* name = xmlTextReaderConstName(this->reader);
    const xmlChar* str;
    SV* value;

    go_next_text(this);

    str = xmlTextReaderConstValue(this->reader);
    expect_int_value(str);

    value = sv_2mortal(
        wrap_simple_type("RPC::XML::int", str)
        );

    skip_until(this, XML_READER_TYPE_END_ELEMENT);
    expect_closing_element_name(this, name);
    go_next_node(this);
    return value;
}

static SV* parse_boolean(parser_context_t* this) {
    const xmlChar* str;
    SV* value;

    /* parse_* 呼び出し前は、カーソルは読もうとしている要素の位置にある。
     * 呼び出し後は、読んだ要素の次のノードの位置にある。(但し
     * methodCall と methodResponse だけはそこで Document が終わるので
     * 例外)
     */
    
    expect_element_name(this, INTERN(this, s_boolean, "boolean"));
    go_next_text(this);

    str = xmlTextReaderConstValue(this->reader);
    expect_boolean_value(str);

    value = sv_2mortal(
        wrap_simple_type("RPC::XML::boolean", str)
        );

    skip_until(this, XML_READER_TYPE_END_ELEMENT);
    expect_closing_element_name(this, INTERN(this, s_boolean, "boolean"));
    go_next_node(this);
    return value;
}

static SV* parse_string(parser_context_t* this) {
    SV* value = NULL;

    /* <string /> になっている場合がある事に注意せよ。その場合には閉じ
     * タグが無く、isEmptyElement が真になる。<string></string> の場合
     * は閉じタグがあり、isEmptyElement は偽になるが、今度は TEXT ノー
     * ドが無い。
     */
    expect_element_name(this, INTERN(this, s_string, "string"));
    
    if (!xmlTextReaderIsEmptyElement(this->reader)) {
        go_next_node(this);
        skip_until_2(
            this,
            XML_READER_TYPE_TEXT,
            XML_READER_TYPE_END_ELEMENT);

        if (xmlTextReaderNodeType(this->reader) == XML_READER_TYPE_TEXT) {
            value = sv_2mortal(
                wrap_simple_type(
                    "RPC::XML::string",
                    xmlTextReaderConstValue(this->reader)
                    )
                );
        }

        skip_until(this, XML_READER_TYPE_END_ELEMENT);
        expect_closing_element_name(this, INTERN(this, s_string, "string"));
        go_next_node(this);
    }

    if (value == NULL) {
        value = sv_2mortal(
            wrap_simple_type("RPC::XML::string", BAD_CAST "")
            );
    }
    
    return value;
}

static SV* parse_double(parser_context_t* this) {
    const xmlChar* str;
    SV* value;

    expect_element_name(this, INTERN(this, s_double, "double"));
    go_next_text(this);

    str   = xmlTextReaderConstValue(this->reader);
    value = sv_2mortal(
        wrap_simple_type("RPC::XML::double", str)
        );

    /* FIXME: looks_like_number は XML-RPC で許されていないような形式の
     * 数値も許してしまう。しかし XML-RPC の仕様は曖昧過ぎて、厳密な
     * validator を作れない。
     */
    passert(SvROK(value));
    if (!looks_like_number(SvRV(value))) {
        croak("invalid number (double): %s", str);
    }

    skip_until(this, XML_READER_TYPE_END_ELEMENT);
    expect_closing_element_name(this, INTERN(this, s_double, "double"));
    go_next_node(this);
    return value;
}

static SV* parse_dateTime_iso8601(parser_context_t* this) {
    const xmlChar* str;
    SV* value;

    expect_element_name(this, INTERN(this, s_dateTime_iso8601, "dateTime.iso8601"));
    go_next_text(this);

    str   = xmlTextReaderConstValue(this->reader);
    value = sv_2mortal(
        wrap_simple_type("RPC::XML::datetime_iso8601", str)
        );

    /* FIXME: ISO-8601 形式で許される日付の種類には大変多くの種類があり、
     * とても validator を C で書く気にはなれない。後で perl でも良いか
     * ら書く事。
     */
    skip_until(this, XML_READER_TYPE_END_ELEMENT);
    expect_closing_element_name(this, INTERN(this, s_dateTime_iso8601, "dateTime.iso8601"));
    go_next_node(this);
    return value;
}

static SV* parse_base64(parser_context_t* this) {
    SV* decoded = NULL;
    SV* value;

    /* <base64 /> になっている場合がある事に注意せよ。その場合には閉じ
     * タグが無く、isEmptyElement が真になる。<base64></base64> の場合
     * は閉じタグがあり、isEmptyElement は偽になるが、今度は TEXT ノー
     * ドが無い。
     */
    expect_element_name(this, INTERN(this, s_base64, "base64"));

    if (!xmlTextReaderIsEmptyElement(this->reader)) {
        go_next_node(this);
        skip_until_2(
            this,
            XML_READER_TYPE_TEXT,
            XML_READER_TYPE_END_ELEMENT);

        if (xmlTextReaderNodeType(this->reader) == XML_READER_TYPE_TEXT) {
            const xmlChar* encoded = xmlTextReaderConstValue(this->reader);
            dSP;

            /* RPC::XML::base64 には Base64 をデコードした状態で格納さ
             * れる。だからここでデコードする必要がある。
             */
            ENTER;
            SAVETMPS;

            PUSHMARK(sp);
            XPUSHs(sv_2mortal(newSVpv((const char*)encoded, 0)));
            PUTBACK;

            call_pv("MIME::Base64::decode_base64", G_SCALAR);

            SPAGAIN;
            decoded = SvREFCNT_inc(POPs);
            PUTBACK;

            FREETMPS;
            LEAVE;

            decoded = sv_2mortal(decoded);
        }

        skip_until(this, XML_READER_TYPE_END_ELEMENT);
        expect_closing_element_name(this, INTERN(this, s_base64, "base64"));
        go_next_node(this);
    }

    if (decoded == NULL) {
        decoded = sv_2mortal(newSVpv("", 0));
    }

    {
        /* RPC::XML::base64 オブジェクトを作って返す */
        HV*  obj   = newHV();
        HV*  stash = gv_stashpv("RPC::XML::base64", TRUE);
        SV** ent;

        ent = hv_store(obj, "encoded", strlen("encoded"), newSViv(0), 0);
        passert(ent != NULL);

        ent = hv_store(obj, "inmem", strlen("inmem"), newSViv(1), 0);
        passert(ent != NULL);

        ent = hv_store(obj, "value", strlen("value"), SvREFCNT_inc(decoded), 0);
        passert(ent != NULL);

        value = sv_2mortal(
            sv_bless(newRV_noinc((SV*)obj), stash)
            );
    }
    return value;
}

static SV* parse_struct(parser_context_t* this) {
    HV* hash;
    SV* value;
    
    expect_element_name(this, INTERN(this, s_struct, "struct"));

    hash = (HV*)sv_2mortal((SV*)newHV());
    
    if (!xmlTextReaderIsEmptyElement(this->reader)) {
        go_next_node(this);

        /* 0個以上の任意の個数の member を持つ */
        while (1) {
            skip_until_2(
                this,
                XML_READER_TYPE_ELEMENT,
                XML_READER_TYPE_END_ELEMENT);

            if (xmlTextReaderNodeType(this->reader) == XML_READER_TYPE_ELEMENT) {
                /* 要素を発見したからには member でなければならない */
                SV* name;
                SV* value;
            
                expect_element_name(this, INTERN(this, s_member, "member"));
                go_next_element(this);

                /* member には name と value が含まれる。 */
                {
                    expect_element_name(this, INTERN(this, s_name, "name"));
                    go_next_text(this);

                    name = sv_2mortal(
                        newSVpv((const char*)xmlTextReaderConstValue(this->reader), 0)
                        );

                    skip_until(this, XML_READER_TYPE_END_ELEMENT);
                    expect_closing_element_name(this, INTERN(this, s_name, "name"));
                    go_next_element(this);
                }
                
                value = parse_value(this);

                {
                    HE* ent = hv_store_ent(hash, name, SvREFCNT_inc(value), 0);

                    passert(ent != NULL);
                }
                
                skip_until(this, XML_READER_TYPE_END_ELEMENT);
                expect_closing_element_name(this, INTERN(this, s_member, "member"));
                go_next_node(this);
            }
            else {
                /* </struct> */
                expect_closing_element_name(this, INTERN(this, s_struct, "struct"));
                go_next_node(this);
                break;
            }
        }
    }

    /* RPC::XML::struct オブジェクトを作る。これは単に hash を
     * RPC::XML::struct に bless するだけで良い。
     */
    {
        HV* stash = gv_stashpv("RPC::XML::struct", TRUE);
        
        value = sv_2mortal(
            sv_bless(newRV_inc((SV*)hash), stash)
            );
    }
    
    return value;
}

static SV* parse_array(parser_context_t* this) {
    AV* array;
    SV* value;

    expect_element_name(this, INTERN(this, s_array, "array"));
    go_next_element(this);

    array = (AV*)sv_2mortal((SV*)av_make(0, NULL));

    /* array は一つの data を持つ */
    {
        expect_element_name(this, INTERN(this, s_data, "data"));

        if (!xmlTextReaderIsEmptyElement(this->reader)) {
            go_next_node(this);

            /* data は0個以上の任意の個数の value を持つ */
            while (1) {
                skip_until_2(
                    this,
                    XML_READER_TYPE_ELEMENT,
                    XML_READER_TYPE_END_ELEMENT);

                if (xmlTextReaderNodeType(this->reader) == XML_READER_TYPE_ELEMENT) {
                    /* 要素を発見したからには value でなければならない */
                    av_push(array, SvREFCNT_inc(parse_value(this)));
                }
                else {
                    /* </data> */
                    expect_closing_element_name(this, INTERN(this, s_data, "data"));
                    go_next_node(this);
                    break;
                }
            }
        }
    }

    skip_until(this, XML_READER_TYPE_END_ELEMENT);
    expect_closing_element_name(this, INTERN(this, s_array, "array"));
    go_next_node(this);

    /* RPC::XML::array オブジェクトを作る。これは単に array を
     * RPC::XML::array に bless するだけで良い。
     */
    {
        HV* stash = gv_stashpv("RPC::XML::array", TRUE);

        value = sv_2mortal(
            sv_bless(newRV_inc((SV*)array), stash)
            );
    }

    return value;
}

static SV* parse_value(parser_context_t* this) {
    SV* value = NULL;

    expect_element_name(this, INTERN(this, s_value, "value"));

    if (!xmlTextReaderIsEmptyElement(this->reader)) {
        go_next_node(this);

        skip_until_3(
            this,
            XML_READER_TYPE_TEXT,
            XML_READER_TYPE_ELEMENT,
            XML_READER_TYPE_END_ELEMENT);

        switch (xmlTextReaderNodeType(this->reader)) {
        case XML_READER_TYPE_TEXT:
            value = sv_2mortal(
                wrap_simple_type(
                    "RPC::XML::string",
                    xmlTextReaderConstValue(this->reader)));
            skip_until(this, XML_READER_TYPE_END_ELEMENT);
            break;

        case XML_READER_TYPE_ELEMENT:
            do {
                const xmlChar* name = xmlTextReaderConstName(this->reader);

                if (xmlStrcmp(name, INTERN(this, s_i4 , "i4" )) == 0 ||
                    xmlStrcmp(name, INTERN(this, s_int, "int")) == 0   ) {

                    value = parse_int(this);
                }
                else if (xmlStrcmp(name, INTERN(this, s_boolean, "boolean")) == 0) {
                    value = parse_boolean(this);
                }
                else if (xmlStrcmp(name, INTERN(this, s_string, "string")) == 0) {
                    value = parse_string(this);
                }
                else if (xmlStrcmp(name, INTERN(this, s_double, "double")) == 0) {
                    value = parse_double(this);
                }
                else if (xmlStrcmp(name, INTERN(this, s_dateTime_iso8601, "dateTime.iso8601")) == 0) {
                    value = parse_dateTime_iso8601(this);
                }
                else if (xmlStrcmp(name, INTERN(this, s_base64, "base64")) == 0) {
                    value = parse_base64(this);
                }
                else if (xmlStrcmp(name, INTERN(this, s_struct, "struct")) == 0) {
                    value = parse_struct(this);
                }
                else if (xmlStrcmp(name, INTERN(this, s_array, "array")) == 0) {
                    value = parse_array(this);
                }
                else {
                    croak_for_unexpected_element(
                        this,
                        "`i4', `int', `boolean', `double', `dateTime.iso8601', "
                        "`struct' or `array'"
                        );
                }
                skip_until(this, XML_READER_TYPE_END_ELEMENT);
            } while (0);
            break;

        case XML_READER_TYPE_END_ELEMENT:
            break;

        default:
            croak("parse_value: internal error");
            break;
        }

        expect_closing_element_name(this, INTERN(this, s_value, "value"));
    }

    if (value == NULL) {
        value = sv_2mortal(
            wrap_simple_type("RPC::XML::string", BAD_CAST ""));
    }

    go_next_node(this);
    return value;
}

static SV* parse_param(parser_context_t* this) {
    SV* value;

    expect_element_name(this, INTERN(this, s_param, "param"));
    go_next_element(this);

    /* 一つの value が存在する */
    value = parse_value(this);

    skip_until(this, XML_READER_TYPE_END_ELEMENT);
    expect_closing_element_name(this, INTERN(this, s_param, "param"));
    go_next_node(this);
    return value;
}

static AV* parse_params(parser_context_t* this) {
    AV* params = NULL;

    expect_element_name(this, INTERN(this, s_params, "params"));
    
    if (xmlTextReaderIsEmptyElement(this->reader)) {
        go_next_node(this);
        return NULL;
    }
    go_next_node(this);

    params = (AV*)sv_2mortal((SV*)av_make(0, NULL));

    /* 0 個以上の任意の個数の param が存在する */
    while (1) {
        skip_until_2(
            this,
            XML_READER_TYPE_ELEMENT,
            XML_READER_TYPE_END_ELEMENT);

        if (xmlTextReaderNodeType(this->reader) == XML_READER_TYPE_ELEMENT) {
            /* 要素を発見したからには param でなければならない */
            av_push(params, SvREFCNT_inc(parse_param(this)));
        }
        else {
            /* </params> */
            expect_closing_element_name(this, INTERN(this, s_params, "params"));
            go_next_node(this);
            break;
        }
    }

    return params;
}

static SV* parse_fault(parser_context_t* this) {
    SV* value;
    
    expect_element_name(this, INTERN(this, s_fault, "fault"));
    go_next_element(this);

    /* value が無ければならない */
    {
        HV*  hash;
        SV** ent;
        
        value = parse_value(this);

        /* 型は RPC::XML::struct であり、それには二つの要素がある。片方
         * は faultCode であり型は int。もう一方は faultString であり型
         * は string。
         */
        if (!sv_derived_from(value, "RPC::XML::struct")) {
            croak("non-struct value in fault");
        }
        passert(SvROK(value));

        hash = (HV*)SvRV(value);
        passert(SvTYPE(hash) == SVt_PVHV);
        
        if (hv_iterinit(hash) != 2) {
            croak(
                "the number of keys in fault struct is not 2: %d",
                hv_iterinit(hash));
        }

        ent = hv_fetch(hash, "faultCode", strlen("faultCode"), 0);
        if (ent == NULL || *ent == &PL_sv_undef) {
            croak(
                "missing faultCode from fault struct");
        }
        else if (!sv_derived_from(*ent, "RPC::XML::int")) {
            croak("faultCode isn't int");
        }

        ent = hv_fetch(hash, "faultString", strlen("faultString"), 0);
        if (ent == NULL || *ent == &PL_sv_undef) {
            croak(
                "missing faultString from fault struct");
        }
        else if (!sv_derived_from(*ent, "RPC::XML::string")) {
            croak("faultString isn't string");
        }
    }

    /* RPC::XML::fault は RPC::XML::struct を bless し直す事で作られる
     */
    {
        HV* stash = gv_stashpv("RPC::XML::fault", TRUE);
        
        value = sv_bless(value, stash);
    }

    skip_until(this, XML_READER_TYPE_END_ELEMENT);
    expect_closing_element_name(this, INTERN(this, s_fault, "fault"));
    go_next_node(this);
    return value;
}

static SV* parse_methodCall(parser_context_t* this) {
    SV* methodName;
    AV* params = NULL;
    SV* request;

    expect_element_name(this, INTERN(this, s_methodCall, "methodCall"));
    go_next_element(this);

    /* methodName は必須。params はオプション。*/
    {
        expect_element_name(this, INTERN(this, s_methodName, "methodName"));
        
        go_next_text(this);
        methodName = sv_2mortal(
            newSVpv((const char*)xmlTextReaderConstValue(this->reader), 0)
            );

        skip_until(this, XML_READER_TYPE_END_ELEMENT);
        expect_closing_element_name(this, INTERN(this, s_methodName, "methodName"));
        go_next_node(this);
    }
    
    skip_until_2(
        this,
        XML_READER_TYPE_ELEMENT,
        XML_READER_TYPE_END_ELEMENT);

    if (xmlTextReaderNodeType(this->reader) == XML_READER_TYPE_ELEMENT) {
        /* 要素を発見したからには params でなければならない */
        params = parse_params(this);
    }

    if (params == NULL) {
        params = (AV*)sv_2mortal((SV*)av_make(0, NULL));
    }

    /* RPC::XML::request を作って返す */
    {
        HV*  obj   = newHV();
        HV*  stash = gv_stashpv("RPC::XML::request", TRUE);
        SV** ent;

        ent = hv_store(obj, "name", strlen("name"), SvREFCNT_inc(methodName), 0);
        passert(ent != NULL);

        ent = hv_store(obj, "args", strlen("args"), newRV_inc((SV*)params), 0);
        passert(ent != NULL);

        request = sv_2mortal(
            sv_bless(newRV_noinc((SV*)obj), stash)
            );
    }

    skip_until(this, XML_READER_TYPE_END_ELEMENT);
    expect_closing_element_name(this, INTERN(this, s_methodCall, "methodCall"));
    /* 次のノードは無い */
    return request;
}

static SV* parse_methodResponse(parser_context_t* this) {
    SV* value;
    SV* response;
    
    expect_element_name(this, INTERN(this, s_methodResponse, "methodResponse"));
    go_next_element(this);

    /* params もしくは fault が無ければならない */
    {
        const xmlChar* name = xmlTextReaderConstName(this->reader);

        if (xmlStrcmp(name, INTERN(this, s_params, "params")) == 0) {
            AV*  params = parse_params(this);
            SV** ent;

            /* 要素数は 1 でなければならない */
            if (av_len(params) + 1 != 1) {
                croak("methodResponse must have exactly one param");
            }

            ent = av_fetch(params, 0, 0);
            passert(ent != NULL);

            /* *ent の refcount 状況
             * 1. 作成される。   [1] (parse_value)
             * 2. 定命になる。       (parse_value)
             * 3. ARRAY に入る。 [2] (parse_params) 但し ARRAY も定命。
             * 4. ここに来る。
             */
            value = *ent;
        }
        else if (xmlStrcmp(name, INTERN(this, s_fault, "fault")) == 0) {
            value = parse_fault(this);
        }
        else {
            value = NULL; /* avoid unused warning. */
            croak_for_unexpected_element(this, "`params' or `fault'");
        }
    }

    /* RPC::XML::response オブジェクトを作る */
    {
        HV*  obj   = newHV();
        HV*  stash = gv_stashpv("RPC::XML::response", TRUE);
        SV** ent;

        ent = hv_store(obj, "value", strlen("value"), SvREFCNT_inc(value), 0);
        passert(ent != NULL);

        response = sv_2mortal(
            sv_bless(newRV_noinc((SV*)obj), stash)
            );
    }

    skip_until(this, XML_READER_TYPE_END_ELEMENT);
    expect_closing_element_name(this, INTERN(this, s_methodResponse, "methodResponse"));
    /* 次のノードは無い */
    return response;
}

static SV* parse_rpc_xml(parser_context_t* this) {
    SV* result;

    skip_until(this, XML_READER_TYPE_ELEMENT);
    {
        const xmlChar* name = xmlTextReaderConstName(this->reader);
        
        if (xmlStrcmp(name, INTERN(this, s_methodCall, "methodCall")) == 0) {
            result = parse_methodCall(this);
        }
        else if (xmlStrcmp(name, INTERN(this, s_methodResponse, "methodResponse")) == 0) {
            result = parse_methodResponse(this);
        }
        else {
            result = NULL; /* avoid unused warning. */
            croak_for_unexpected_element(this, "`methodCall' or `methodResponse'");
        }
    }

    /* result は定命である */
    return result;
}


MODULE = RPC::XML::Parser::XS		PACKAGE = RPC::XML::Parser::XS		

SV*
parse_rpc_xml(SV* src)
    PROTOTYPE: $
    CODE:
        SV* obj;

        {
            /* Reader オブジェクトを作成 */
            dSP;

            ENTER;
            SAVETMPS;

            PUSHMARK(sp);
            XPUSHs(
                sv_2mortal(
                    newSVpv(
                        "RPC::XML::Parser::XS::Reader",
                        strlen("RPC::XML::Parser::XS::Reader"))));
            XPUSHs(src);
            PUTBACK;

            call_method("new_string_reader", G_SCALAR);

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

int
libxml_version(SV* pkg = NULL)
  CODE:
    RETVAL = (LIBXML_VERSION);
  OUTPUT:
    RETVAL

MODULE = RPC::XML::Parser::XS       PACKAGE = RPC::XML::Parser::XS::Reader

parser_context_t*
new_string_reader(char* class, SV* src)
   CODE:
        parser_context_t* this;
        init_module();

        PERL_UNUSED_VAR(class);
        /* xmlTextReaderPtr を blessed pointer にしなければ croak 時に
         * メモリを自動的に解放させる事が出来ない。
         */
        this = malloc(sizeof(parser_context_t));

        if (this == NULL) {
            croak("failed to allocate parser_context_t");
        }
        bzero(this, sizeof(parser_context_t));

        this->reader = xmlReaderForMemory(
            SvPV_nolen(src), /* buffer   */
            SvCUR(src),      /* size     */
            NULL,            /* URL      */
            NULL,            /* encoding */
            XML_PARSE_NOENT    |
            XML_PARSE_NOBLANKS |
            XML_PARSE_NSCLEAN  |
            XML_PARSE_NOCDATA  |
            XML_PARSE_COMPACT);

        if (this->reader == NULL) {
            free(this);
            croak("failed to create XML string reader: %.*s", SvCUR(src), SvPV_nolen(src));
        }

        xmlTextReaderSetStructuredErrorHandler(this->reader, xml_error_handler, NULL);

        RETVAL = this;

    OUTPUT:
        RETVAL

SV*
run(parser_context_t* this)
    CODE:
        RETVAL = SvREFCNT_inc(parse_rpc_xml(this));

    OUTPUT:
        RETVAL

void
DESTROY(parser_context_t* this)
    CODE:
        xmlFreeTextReader(this->reader);
        free(this);
