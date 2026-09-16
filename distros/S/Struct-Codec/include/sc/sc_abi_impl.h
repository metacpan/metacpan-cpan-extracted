#ifndef SC_ABI_IMPL_H
#define SC_ABI_IMPL_H

/* The table behind Struct::Codec::_abi_ptr. Private to this build; consumers
 * see only include/sc_abi.h and resolve the address at runtime.
 *
 * Every entry points at a core function; nothing is IMPLEMENTED here. Needs
 * sc_abi.h and sc_codec.h.
 */

/* The version the table is built at and the version the public header
 * promises are two files, and a bump to one and not the other is silent
 * until a consumer refuses a provider that has what it wants. The array-size
 * trick rather than static_assert, which is C11 and this dist is C89. */
#define SC_ABI_IMPL_VERSION 1
typedef char sc_abi_assert_version[(SC_ABI_IMPL_VERSION == SC_ABI_VERSION) ? 1 : -1];

static const sc_abi SC_ABI = {
    SC_ABI_VERSION,
    sc_encode,
    sc_encode_to,
    sc_decode
};

/* ---- the selftest ---------------------------------------------------------
 *
 * A structure built in C, encoded through the TABLE, decoded through the
 * table, and every field checked - because a table is a list of addresses and
 * nothing about compiling one proves an entry points where its declaration
 * says. Numbered steps, and the number of the first that failed comes back,
 * so a failure says WHICH. The bytes and the structure come back too, for the
 * Perl side to compare against the Perl surface's encoding of the same data.
 */

#define SC_STEP(n) do { *step = (n); } while (0)

static SV *sc_abi_selftest(pTHX_ int *step, SV **data) {
    const sc_abi *A = &SC_ABI;
    HV *h = newHV();
    AV *shared = newAV();
    HV *obj = newHV();
    SV *in, *bytes = NULL, *out = NULL;
    char small[8];
    STRLEN need = 0, blen, got;

    *step = 0;
    *data = NULL;

    /* the structure: every kind, a shared referent, and an object */
    (void)hv_stores(h, "s",   newSVpvs("hello"));
    {
        SV *u = newSVpvs("caf\xc3\xa9");
        SvUTF8_on(u);
        (void)hv_stores(h, "u", u);
    }
    (void)hv_stores(h, "n",   newSViv(-5));
    (void)hv_stores(h, "big", newSVuv(UV_MAX));
    (void)hv_stores(h, "f",   newSVnv(1.5));
    /* A third is exact at no NV width, so on a perl built -Duselongdouble or
     * -Dusequadmath this is the value the 8-byte wire float cannot hold and it
     * goes through the table as decimal digits. On a double perl it is an
     * ordinary float and the step below still holds. */
    (void)hv_stores(h, "w",   newSVnv((NV)1 / (NV)3));
    (void)hv_stores(h, "un",  newSV(0));
    av_push(shared, newSViv(1));
    av_push(shared, newSVpvs("two"));
    (void)hv_stores(h, "a",  newRV_inc((SV *)shared));
    (void)hv_stores(h, "a2", newRV_inc((SV *)shared));
    (void)hv_stores(obj, "k", newSViv(7));
    (void)hv_stores(h, "obj", sv_bless(newRV_inc((SV *)obj), gv_stashpvs("Struct::Codec::SelfTest", GV_ADD)));
    SvREFCNT_dec((SV *)shared);
    SvREFCNT_dec((SV *)obj);
    in = newRV_noinc((SV *)h);
    *data = in;

    /* 1: the version */
    if (A->abi_version < SC_ABI_VERSION) { SC_STEP(1); goto done; }

    /* 2: encode gives bytes with the header */
    bytes = (A->encode)(aTHX_ in);
    if (!bytes || !SvPOK(bytes) || SvUTF8(bytes)) { SC_STEP(2); goto done; }
    if (SvCUR(bytes) < SC_HDR_LEN + 1 || SvPVX(bytes)[0] != SC_MAGIC) { SC_STEP(2); goto done; }

    /* 3: decode gives the structure back */
    out = (A->decode)(aTHX_ SvPVX(bytes), SvCUR(bytes));
    if (!out || !SvROK(out) || SvTYPE(SvRV(out)) != SVt_PVHV) { SC_STEP(3); goto done; }
    {
        HV *oh = (HV *)SvRV(out);
        SV **v;
        if (HvUSEDKEYS(oh) != 10) { SC_STEP(3); goto done; }

        /* 4: a string is a string, and bytes stay bytes */
        v = hv_fetchs(oh, "s", 0);
        if (!v || !SvPOK(*v) || SvUTF8(*v) || !strEQ(SvPVX(*v), "hello")) { SC_STEP(4); goto done; }

        /* 5: a utf8 string keeps its flag */
        v = hv_fetchs(oh, "u", 0);
        if (!v || !SvPOK(*v) || !SvUTF8(*v) || SvCUR(*v) != 5) { SC_STEP(5); goto done; }

        /* 6: a negative integer, and a UV that does not fit an IV */
        v = hv_fetchs(oh, "n", 0);
        if (!v || !SvIOK(*v) || SvIV(*v) != -5) { SC_STEP(6); goto done; }
        v = hv_fetchs(oh, "big", 0);
        if (!v || !SvIOK(*v) || !SvIsUV(*v) || SvUV(*v) != UV_MAX) { SC_STEP(6); goto done; }

        /* 7: a float, a float no double holds, and undef */
        v = hv_fetchs(oh, "f", 0);
        if (!v || !SvNOK(*v) || SvNV(*v) != 1.5) { SC_STEP(7); goto done; }
        v = hv_fetchs(oh, "w", 0);
        if (!v || !SvNOK(*v) || SvNV(*v) != (NV)1 / (NV)3) { SC_STEP(7); goto done; }
        v = hv_fetchs(oh, "un", 0);
        if (!v || SvOK(*v)) { SC_STEP(7); goto done; }

        /* 8: the array came back, and a and a2 share ONE referent */
        {
            SV **a = hv_fetchs(oh, "a", 0), **a2 = hv_fetchs(oh, "a2", 0);
            if (!a || !a2 || !SvROK(*a) || !SvROK(*a2)) { SC_STEP(8); goto done; }
            if (SvRV(*a) != SvRV(*a2)) { SC_STEP(8); goto done; }
            if (SvTYPE(SvRV(*a)) != SVt_PVAV || av_len((AV *)SvRV(*a)) != 1) { SC_STEP(8); goto done; }
            v = av_fetch((AV *)SvRV(*a), 1, 0);
            if (!v || !SvPOK(*v) || !strEQ(SvPVX(*v), "two")) { SC_STEP(8); goto done; }
        }

        /* 9: the object is blessed into its class */
        v = hv_fetchs(oh, "obj", 0);
        if (!v || !SvROK(*v) || !SvOBJECT(SvRV(*v))
            || !strEQ(HvNAME(SvSTASH(SvRV(*v))), "Struct::Codec::SelfTest")) { SC_STEP(9); goto done; }
    }

    /* 10: encode_to refuses a buffer one byte short, allocating nothing, and
     * reports what it needed */
    blen = SvCUR(bytes);
    {
        char *buf;
        Newx(buf, blen, char);
        got = (A->encode_to)(aTHX_ in, buf, blen - 1, &need);
        if (got != 0 || need != blen) { Safefree(buf); SC_STEP(10); goto done; }

        /* 11: and fills one exactly big enough with the same bytes */
        got = (A->encode_to)(aTHX_ in, buf, blen, &need);
        if (got != blen || need != blen || memcmp(buf, SvPVX(bytes), blen)) {
            Safefree(buf); SC_STEP(11); goto done;
        }
        Safefree(buf);
    }

    /* 12: a tiny value fits a tiny buffer, and need may be NULL */
    {
        SV *five = sv_2mortal(newSViv(5));
        got = (A->encode_to)(aTHX_ five, small, sizeof small, NULL);
        if (got != SC_HDR_LEN + 1 || (unsigned char)small[SC_HDR_LEN] != 5) { SC_STEP(12); goto done; }
    }

done:
    if (out) SvREFCNT_dec(out);
    return bytes;
}

#undef SC_STEP

#endif /* SC_ABI_IMPL_H */
