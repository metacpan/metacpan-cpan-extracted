/* pmcp_rpc.h - JSON-RPC 2.0: decode, classify, encode, the envelope.
 *
 * Needs: pmcp_clos.h, pmcp_abi.h.
 * Gives: pmcp_rpc_decode, pmcp_rpc_classify, pmcp_json, pmcp_rpc_result,
 * pmcp_rpc_error, and the small builders pmcp_str and pmcp_bool.
 *
 * Bytes on the wire match Maat's (Maat/include/mt_mcp.h:208-248): canonical
 * encoding, so keys are sorted and an envelope reads {"error"|"id","jsonrpc",
 * "result"}, and the same lowercase messages. A client that talks to both sees
 * the same framing.
 */

#ifndef PMCP_RPC_H
#define PMCP_RPC_H

#define PMCP_PARSE    (-32700)
#define PMCP_REQUEST  (-32600)
#define PMCP_METHOD   (-32601)
#define PMCP_PARAMS   (-32602)
#define PMCP_INTERNAL (-32603)

/* ---- decode -------------------------------------------------------------- */

static SV *PMCP_DECODE = NULL;   /* \&File::Raw::JSON::file_json_decode */

/* BOOT, after pmcp_abi_boot has loaded File::Raw::JSON. */
static void pmcp_rpc_boot(pTHX)
{
    CV *cv = get_cv("File::Raw::JSON::file_json_decode", 0);
    if (!cv) croak(PMCP_DIST ": File::Raw::JSON has no file_json_decode");
    PMCP_DECODE = newRV_inc((SV *)cv);
}

/* Decode a body. Returns +1, or NULL when the bytes are not JSON.
 *
 * Through the XSUB under G_EVAL, never through the ABI's decode pointer. These
 * bytes are the caller's, so a croak from the parser is normal operation here,
 * and only a real G_EVAL frame unwinds the stacks a croak abandons. Trapping it
 * with JMPENV_PUSH answers correctly and leaves the interpreter to die later in
 * some loop it does not own (plan_maat_mcp 02, "panic: pp_iter"). */
static SV *pmcp_rpc_decode(pTHX_ SV *bytes)
{
    SV *err = NULL;
    SV *doc;
    SV *arg[1];

    arg[0] = bytes;
    doc = pmcp_call_sv(aTHX_ PMCP_DECODE, arg, 1, G_SCALAR, &err);
    if (!doc) {
        SvREFCNT_dec(err);
        return NULL;
    }
    return doc;
}

/* ---- encode -------------------------------------------------------------- */

/* Canonical JSON of a value this dist built. Returns +1.
 *
 * Through the ABI, with no G_EVAL, so only for values whose shape is known:
 * the envelope, initialize, the frozen lists. A value an application handed
 * back can hold anything, and goes through pmcp_json_trapped instead (05). */
static SV *pmcp_json(pTHX_ SV *value)
{
    frj_opts o;
    PMCP_FRJ->opts_init(&o);
    o.canonical = 1;
    return PMCP_FRJ->encode(aTHX_ value, &o);
}

/* A new string SV with only the string slot: a version given as 1.10 in Perl
 * goes out as "1.10" and not as the number 1.1. Returns +1. */
static SV *pmcp_str(pTHX_ SV *sv)
{
    STRLEN l;
    const char *p = SvPV_const(sv, l);
    SV *out = newSVpvn(p, l);
    if (SvUTF8(sv)) SvUTF8_on(out);
    return out;
}

/* A JSON boolean: frj encodes a reference to 1 or 0 as true or false. */
static SV *pmcp_bool(pTHX_ int b)
{
    return newRV_noinc(newSViv(b ? 1 : 0));
}

/* ---- the envelope -------------------------------------------------------- */

/* The id as it was sent, encoded alone: 1 stays 1 and "1" stays "1". */
static void pmcp_cat_id(pTHX_ SV *out, SV *id)
{
    if (!id || !SvOK(id)) {
        sv_catpvs(out, "null");
        return;
    }
    {
        SV *b = pmcp_json(aTHX_ id);
        sv_catsv(out, b);
        SvREFCNT_dec(b);
    }
}

/* {"id":ID,"jsonrpc":"2.0","result":RESULT}, with RESULT already encoded.
 * Spliced rather than encoded whole so a frozen list (05) goes out as stored.
 * The key order is the canonical one. Returns +1. */
static SV *pmcp_rpc_result_bytes(pTHX_ SV *id, SV *result_bytes)
{
    SV *out = newSVpvs("{\"id\":");
    pmcp_cat_id(aTHX_ out, id);
    sv_catpvs(out, ",\"jsonrpc\":\"2.0\",\"result\":");
    sv_catsv(out, result_bytes);
    sv_catpvs(out, "}");
    return out;
}

/* The same, encoding RESULT (a value this dist built, or NULL for {}). Takes
 * ownership of result. Returns +1. */
static SV *pmcp_rpc_result(pTHX_ SV *id, SV *result)
{
    SV *bytes, *out;
    if (!result) result = newRV_noinc((SV *)newHV());
    bytes = pmcp_json(aTHX_ result);
    SvREFCNT_dec(result);
    out = pmcp_rpc_result_bytes(aTHX_ id, bytes);
    SvREFCNT_dec(bytes);
    return out;
}

/* {"error":{"code":C,"data":D,"message":M},"id":ID,"jsonrpc":"2.0"}. Takes
 * ownership of data, which may be NULL. Returns +1. */
static SV *pmcp_rpc_error(pTHX_ SV *id, int code, const char *msg, SV *data)
{
    HV *r = newHV(), *e = newHV();
    SV *rv, *out;

    (void)hv_stores(e, "code", newSViv(code));
    (void)hv_stores(e, "message", newSVpv(msg, 0));
    if (data) (void)hv_stores(e, "data", data);
    (void)hv_stores(r, "error", newRV_noinc((SV *)e));
    (void)hv_stores(r, "id", (id && SvOK(id)) ? newSVsv(id) : newSV(0));
    (void)hv_stores(r, "jsonrpc", newSVpvs("2.0"));
    rv = newRV_noinc((SV *)r);
    out = pmcp_json(aTHX_ rv);
    SvREFCNT_dec(rv);
    return out;
}

/* ---- classification ------------------------------------------------------ */

enum pmcp_kind {
    PMCP_K_INVALID = 0,   /* answer err_code, with the id when it is usable */
    PMCP_K_REQUEST,       /* method and id: owed an answer                  */
    PMCP_K_NOTIFY,        /* method and no id: owed nothing                 */
    PMCP_K_RESPONSE       /* result or error and an id: owed nothing        */
};

typedef struct {
    enum pmcp_kind kind;
    int         err_code;    /* for PMCP_K_INVALID                        */
    const char *err_msg;
    SV         *id;          /* borrowed from the document, or NULL       */
    const char *method;      /* borrowed                                  */
    STRLEN      mlen;
    HV         *params;      /* borrowed, NULL when absent                */
} pmcp_msg;

/* A usable id: a string, or an integer. Not null, not a float, not a boolean,
 * object or array. MCP narrows JSON-RPC here: an id MUST NOT be null. */
static int pmcp_id_ok(SV *id)
{
    if (!id || !SvOK(id) || SvROK(id)) return 0;
    if (SvPOK(id)) return 1;
    if (SvIOK(id) && !SvNOK(id)) return 1;
    return 0;
}

/* A plain string: not a reference, not a number. */
static int pmcp_is_str(SV *sv)
{
    return sv && SvOK(sv) && !SvROK(sv) && SvPOK(sv);
}

static void pmcp_rpc_classify(pTHX_ SV *doc, pmcp_msg *m)
{
    HV *h;
    SV **jv, **mv, **iv, **pv;

    Zero(m, 1, pmcp_msg);
    m->kind = PMCP_K_INVALID;
    m->err_code = PMCP_REQUEST;
    m->err_msg = "invalid request";

    /* An array is a 2025-03-26 batch. Later versions removed them, and this
     * server says so rather than serving half of one (16). */
    if (pmcp_is_array(doc)) {
        m->err_msg = "batches are not supported";
        return;
    }
    if (!pmcp_is_hash(doc)) return;
    h = (HV *)SvRV(doc);

    iv = hv_fetchs(h, "id", 0);
    if (iv && pmcp_id_ok(*iv)) m->id = *iv;

    jv = hv_fetchs(h, "jsonrpc", 0);
    if (!jv || !pmcp_is_str(*jv) || !strEQ(SvPV_nolen(*jv), "2.0")) return;

    mv = hv_fetchs(h, "method", 0);
    if (!mv) {
        /* A response to a request this server sent. None are sent in v1 (16),
         * so one is accepted and dropped. */
        if (iv && m->id && (hv_exists(h, "result", 6) || hv_exists(h, "error", 5)))
            m->kind = PMCP_K_RESPONSE;
        return;
    }
    if (!pmcp_is_str(*mv)) return;
    m->method = SvPV_const(*mv, m->mlen);

    pv = hv_fetchs(h, "params", 0);
    if (pv && SvOK(*pv)) {
        if (!pmcp_is_hash(*pv)) {
            if (iv) {
                m->err_code = PMCP_PARAMS;
                m->err_msg = "params must be an object";
            }
            else m->kind = PMCP_K_NOTIFY;   /* owed nothing, even when wrong */
            return;
        }
        m->params = (HV *)SvRV(*pv);
    }

    if (!iv) { m->kind = PMCP_K_NOTIFY; return; }
    if (!m->id) return;                     /* an id that is not usable */
    m->kind = PMCP_K_REQUEST;
}

#endif /* PMCP_RPC_H */
