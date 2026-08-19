/* otel_value.h - AnyValue and KeyValue, from Perl scalars.
 *
 * Every attribute in every signal goes through here, which makes this both
 * the most-exercised code in the encoder and the easiest to get subtly wrong.
 *
 * AnyValue is a protobuf oneof over string, bool, int, double, array, kvlist
 * and bytes, and Perl scalars do not map onto it cleanly: a scalar can be an
 * IV and a PV at once, "3" and 3 are the same value with different histories,
 * and undef is not a member of the union at all. The rules below are chosen
 * so that a value round-trips as the type the application meant, and so that
 * the two encoders (protobuf here, JSON in otel_json.h) agree - a value that
 * arrives at a collector as an int over one transport and a string over the
 * other is a bug nobody finds until a dashboard filter stops matching.
 *
 * THE RULES, in order:
 *   1. undef        -> an AnyValue with NOTHING set. That is the protobuf
 *                      spelling of a null attribute; it is not the same as an
 *                      empty string and must not become one.
 *   2. a bool ref   -> bool. \1 and \0 are the JSON-boolean convention the
 *                      rest of this ecosystem already uses (File::Raw::JSON
 *                      encodes a scalar ref as true/false), so honouring it
 *                      here keeps one convention across the dist.
 *   3. any BLESSED  -> its stringification. An object is a value, not a
 *      ref            structure: one with an overloaded "" is a perfectly
 *                     ordinary thing to attach to a span, and dumping its
 *                     guts as a KeyValueList instead would be a silent
 *                     change of meaning. This is the same rule Punk::Logger
 *                     applies to a blessed reference, and the two agreeing
 *                     matters more than either being clever.
 *   4. arrayref     -> ArrayValue, recursively (unblessed only).
 *   5. hashref      -> KeyValueList, recursively (unblessed only).
 *   6. other ref    -> its stringification. A coderef is a mistake that must
 *                      not take the request down - the same discipline
 *                      Punk::Logger's scrubber applies, learned the same way.
 *   7. IOK, not POK -> int. An integer that has never been used as a string.
 *   8. NOK, not POK -> double.
 *   9. anything else-> string. Including a scalar that is both: if it has a
 *                      string form, the application has treated it as text,
 *                      and text is the safe answer. Guessing "3" into an int
 *                      changes an id into a number and breaks grouping.
 */

#ifndef OTEL_VALUE_H
#define OTEL_VALUE_H

#include "otel_pb.h"
#include "otel_proto.h"

static size_t otel_anyvalue_size(pTHX_ SV *v);
static void   otel_anyvalue_write(pTHX_ otel_buf *b, SV *v);

/* What an AnyValue IS, decided in exactly one place.
 *
 * Both encoders - protobuf here, OTLP/JSON in otel_json.h - classify through
 * this function rather than each applying the rules above themselves. If they
 * did it twice the two would drift, and the drift would be invisible: a value
 * arriving at a collector as an int over one transport and a string over the
 * other is a bug nobody finds until a dashboard filter quietly stops
 * matching. One classifier, two renderings. */
enum {
    OTV_NULL = 0,   /* undef: an AnyValue with nothing set */
    OTV_BOOL,
    OTV_INT,
    OTV_DOUBLE,
    OTV_ARRAY,
    OTV_KVLIST,
    OTV_STRING      /* includes every ref that is not a plain container */
};

/* Is this ref one of the two boolean spellings, \1 and \0? A ref to a plain
 * scalar holding 0 or 1 and nothing else. */
static int otel_is_bool(pTHX_ SV *rv) {
    SV *inner;
    if (!SvROK(rv)) return 0;
    inner = SvRV(rv);
    if (SvTYPE(inner) > SVt_PVMG || SvROK(inner)) return 0;
    if (!SvIOK(inner)) return 0;
    return (SvIVX(inner) == 0 || SvIVX(inner) == 1);
}

/* A ref protobuf cannot represent structurally: code, glob, regexp. Its
 * stringification is used instead. Deliberately the same list File::Raw::JSON
 * refuses, so both encoders make the same substitution. */
static int otel_ref_is_opaque(pTHX_ SV *v, SV *rv) {
#ifdef SvRXOK
    if (SvRXOK(v) || SvRXOK(rv)) return 1;
#endif
    return SvTYPE(rv) == SVt_PVCV || SvTYPE(rv) == SVt_PVGV;
}

/* The rules at the top of this file, as one decision. */
static int otel_value_kind(pTHX_ SV *v) {
    if (!v || !SvOK(v)) return OTV_NULL;             /* rule 1 */
    if (SvROK(v)) {
        SV *rv = SvRV(v);
        if (otel_is_bool(aTHX_ v)) return OTV_BOOL;  /* rule 2 */
        if (SvOBJECT(rv)) return OTV_STRING;         /* rule 3: an object is
                                                      * a value, not a shape */
        if (otel_ref_is_opaque(aTHX_ v, rv)) return OTV_STRING;  /* rule 6 */
        if (SvTYPE(rv) == SVt_PVAV) return OTV_ARRAY;            /* rule 4 */
        if (SvTYPE(rv) == SVt_PVHV) return OTV_KVLIST;           /* rule 5 */
        return OTV_STRING;
    }
    if (SvIOK(v) && !SvPOK(v)) return OTV_INT;       /* rule 7 */
    if (SvNOK(v) && !SvPOK(v)) return OTV_DOUBLE;    /* rule 8 */
    return OTV_STRING;                               /* rule 9 */
}

/* ---- the body of an AnyValue (no tag, no length) ------------------------ */

static size_t otel_anyvalue_body_size(pTHX_ SV *v) {
    if (!v || !SvOK(v)) return 0;                    /* rule 1: nothing set */

    if (SvROK(v)) {
        SV *rv = SvRV(v);
        if (otel_is_bool(aTHX_ v))                   /* rule 2 */
            return otel_pb_bool_size(PB_ANYVALUE_BOOL);
        if (!SvOBJECT(rv) && !otel_ref_is_opaque(aTHX_ v, rv)) {
            if (SvTYPE(rv) == SVt_PVAV) {            /* rule 3 */
                AV *av = (AV *)rv;
                SSize_t i, n = av_len(av) + 1;
                size_t inner = 0;
                for (i = 0; i < n; i++) {
                    SV **e = av_fetch(av, i, 0);
                    inner += otel_pb_msg_size(PB_ARRAYVALUE_VALUES,
                                 otel_anyvalue_body_size(aTHX_ (e ? *e : NULL)));
                }
                return otel_pb_msg_size(PB_ANYVALUE_ARRAY, inner);
            }
            if (SvTYPE(rv) == SVt_PVHV) {            /* rule 4 */
                HV *hv = (HV *)rv;
                HE *he;
                size_t inner = 0;
                hv_iterinit(hv);
                while ((he = hv_iternext(hv))) {
                    STRLEN kl;
                    const char *k = HePV(he, kl);
                    size_t kv = otel_pb_bytes_size(PB_KEYVALUE_KEY, kl)
                              + otel_pb_msg_size(PB_KEYVALUE_VALUE,
                                    otel_anyvalue_body_size(aTHX_ HeVAL(he)));
                    inner += otel_pb_msg_size(PB_KVLIST_VALUES, kv);
                }
                return otel_pb_msg_size(PB_ANYVALUE_KVLIST, inner);
            }
        }
        {   /* rule 5 */
            STRLEN l; (void)SvPV_const(v, l);
            return otel_pb_bytes_size(PB_ANYVALUE_STRING, l);
        }
    }

    if (SvIOK(v) && !SvPOK(v))                       /* rule 6 */
        return otel_pb_uint64_size(PB_ANYVALUE_INT, (UV)SvIVX(v));
    if (SvNOK(v) && !SvPOK(v))                       /* rule 7 */
        return otel_pb_double_size(PB_ANYVALUE_DOUBLE);
    {                                                /* rule 8 */
        STRLEN l; (void)SvPV_const(v, l);
        return otel_pb_bytes_size(PB_ANYVALUE_STRING, l);
    }
}

static void otel_anyvalue_body_write(pTHX_ otel_buf *b, SV *v) {
    if (!v || !SvOK(v)) return;

    if (SvROK(v)) {
        SV *rv = SvRV(v);
        if (otel_is_bool(aTHX_ v)) {
            otel_pb_bool(b, PB_ANYVALUE_BOOL, SvIVX(SvRV(v)) ? 1 : 0);
            return;
        }
        if (!SvOBJECT(rv) && !otel_ref_is_opaque(aTHX_ v, rv)) {
            if (SvTYPE(rv) == SVt_PVAV) {
                AV *av = (AV *)rv;
                SSize_t i, n = av_len(av) + 1;
                size_t inner = 0, mark;
                for (i = 0; i < n; i++) {
                    SV **e = av_fetch(av, i, 0);
                    inner += otel_pb_msg_size(PB_ARRAYVALUE_VALUES,
                                 otel_anyvalue_body_size(aTHX_ (e ? *e : NULL)));
                }
                otel_pb_msg_head(b, PB_ANYVALUE_ARRAY, inner);
                mark = b->len;
                for (i = 0; i < n; i++) {
                    SV **e = av_fetch(av, i, 0);
                    SV  *ev = e ? *e : NULL;
                    otel_pb_msg_head(b, PB_ARRAYVALUE_VALUES,
                                     otel_anyvalue_body_size(aTHX_ ev));
                    otel_anyvalue_body_write(aTHX_ b, ev);
                }
                OTEL_PB_CHECK(b, mark, inner, "ArrayValue");
                return;
            }
            if (SvTYPE(rv) == SVt_PVHV) {
                HV *hv = (HV *)rv;
                HE *he;
                size_t inner = 0, mark;
                hv_iterinit(hv);
                while ((he = hv_iternext(hv))) {
                    STRLEN kl;
                    const char *k = HePV(he, kl);
                    inner += otel_pb_msg_size(PB_KVLIST_VALUES,
                        otel_pb_bytes_size(PB_KEYVALUE_KEY, kl)
                      + otel_pb_msg_size(PB_KEYVALUE_VALUE,
                            otel_anyvalue_body_size(aTHX_ HeVAL(he))));
                }
                otel_pb_msg_head(b, PB_ANYVALUE_KVLIST, inner);
                mark = b->len;
                hv_iterinit(hv);
                while ((he = hv_iternext(hv))) {
                    STRLEN kl;
                    const char *k = HePV(he, kl);
                    SV *val = HeVAL(he);
                    size_t vsz = otel_anyvalue_body_size(aTHX_ val);
                    otel_pb_msg_head(b, PB_KVLIST_VALUES,
                        otel_pb_bytes_size(PB_KEYVALUE_KEY, kl)
                      + otel_pb_msg_size(PB_KEYVALUE_VALUE, vsz));
                    otel_pb_bytes(b, PB_KEYVALUE_KEY, k, kl);
                    otel_pb_msg_head(b, PB_KEYVALUE_VALUE, vsz);
                    otel_anyvalue_body_write(aTHX_ b, val);
                }
                OTEL_PB_CHECK(b, mark, inner, "KeyValueList");
                return;
            }
        }
        {
            STRLEN l;
            const char *s = SvPV_const(v, l);
            otel_pb_bytes(b, PB_ANYVALUE_STRING, s, l);
            return;
        }
    }

    if (SvIOK(v) && !SvPOK(v)) {
        otel_pb_uint64(b, PB_ANYVALUE_INT, (UV)SvIVX(v));
        return;
    }
    if (SvNOK(v) && !SvPOK(v)) {
        otel_pb_double(b, PB_ANYVALUE_DOUBLE, SvNVX(v));
        return;
    }
    {
        STRLEN l;
        const char *s = SvPV_const(v, l);
        otel_pb_bytes(b, PB_ANYVALUE_STRING, s, l);
    }
}

/* ---- KeyValue lists ----------------------------------------------------- *
 * Attributes arrive as a Perl hashref. Keys are SORTED, for the same reason
 * the logger sorts its logfmt pairs: perl's hash order is randomised per
 * process, and a payload whose bytes differ run to run cannot be compared
 * against a golden vector, diffed, or cached. */

static size_t otel_kv_size(pTHX_ const char *k, STRLEN kl, SV *v) {
    return otel_pb_bytes_size(PB_KEYVALUE_KEY, kl)
         + otel_pb_msg_size(PB_KEYVALUE_VALUE,
                            otel_anyvalue_body_size(aTHX_ v));
}

static void otel_kv_write(pTHX_ otel_buf *b, const char *k, STRLEN kl, SV *v) {
    size_t vsz = otel_anyvalue_body_size(aTHX_ v);
    otel_pb_bytes(b, PB_KEYVALUE_KEY, k, kl);
    otel_pb_msg_head(b, PB_KEYVALUE_VALUE, vsz);
    otel_anyvalue_body_write(aTHX_ b, v);
}

/* The sorted key list of an attribute hash, as a mortal AV. */
static AV *otel_attr_keys(pTHX_ HV *hv) {
    AV *keys = (AV *)sv_2mortal((SV *)newAV());
    HE *he;
    SSize_t n = 0;
    if (!hv) return keys;
    hv_iterinit(hv);
    while ((he = hv_iternext(hv))) { av_push(keys, newSVsv(hv_iterkeysv(he))); n++; }
    if (n > 1) sortsv(AvARRAY(keys), (STRLEN)n, Perl_sv_cmp);
    return keys;
}

/* sum of `field`-tagged KeyValue messages for every pair in hv */
static size_t otel_attrs_size(pTHX_ HV *hv, int field) {
    AV *keys = otel_attr_keys(aTHX_ hv);
    SSize_t i, n = av_len(keys) + 1;
    size_t total = 0;
    for (i = 0; i < n; i++) {
        SV **kp = av_fetch(keys, i, 0);
        HE  *e;
        STRLEN kl;
        const char *k;
        if (!(kp && *kp)) continue;
        k = SvPV_const(*kp, kl);
        e = hv_fetch_ent(hv, *kp, 0, 0);
        total += otel_pb_msg_size(field,
                     otel_kv_size(aTHX_ k, kl, e ? HeVAL(e) : NULL));
    }
    return total;
}

static void otel_attrs_write(pTHX_ otel_buf *b, HV *hv, int field) {
    AV *keys = otel_attr_keys(aTHX_ hv);
    SSize_t i, n = av_len(keys) + 1;
    for (i = 0; i < n; i++) {
        SV **kp = av_fetch(keys, i, 0);
        HE  *e;
        STRLEN kl;
        const char *k;
        SV *v;
        if (!(kp && *kp)) continue;
        k = SvPV_const(*kp, kl);
        e = hv_fetch_ent(hv, *kp, 0, 0);
        v = e ? HeVAL(e) : NULL;
        otel_pb_msg_head(b, field, otel_kv_size(aTHX_ k, kl, v));
        otel_kv_write(aTHX_ b, k, kl, v);
    }
}

#endif /* OTEL_VALUE_H */
