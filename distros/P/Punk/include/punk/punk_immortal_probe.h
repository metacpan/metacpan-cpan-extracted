#ifndef PUNK_IMMORTAL_PROBE_H
#define PUNK_IMMORTAL_PROBE_H

/* An author tool. Compiles to nothing unless -DPUNK_IMMORTAL_PROBE is set.
 *
 *     make OPTIMIZE="-O0 -g -DPUNK_IMMORTAL_PROBE" && prove -b t/ 2>&1 \
 *       | grep '^IMMORTAL' | sort | uniq -c | sort -rn
 *
 * Must be included AFTER perl.h/XSUB.h and BEFORE any punk header, or those
 * headers compile against the real functions and report nothing.
 */

#ifdef PUNK_IMMORTAL_PROBE

#define PUNK_IS_IMM(s) ((SV *)(s) == &PL_sv_undef || (SV *)(s) == &PL_sv_yes \
                     || (SV *)(s) == &PL_sv_no)

static void punk_probe_hit(pTHX_ const char *what, const char *file, int line,
                           SV *sv) {
    const char *n = sv == &PL_sv_undef ? "undef"
                  : sv == &PL_sv_yes   ? "yes"
                  : sv == &PL_sv_no    ? "no" : "?";
    PerlIO_printf(PerlIO_stderr(), "IMMORTAL\t%s(&PL_sv_%s)\t%s:%d\n",
                  what, n, file, line);
}

/* the originals, captured while the real macros are still in scope */
static SV  *punk_real_2mortal(pTHX_ SV *s)                 { return sv_2mortal(s); }
static SV **punk_real_av_store(pTHX_ AV *a, SSize_t i, SV *v) { return av_store(a, i, v); }
static void punk_real_av_push(pTHX_ AV *a, SV *v)          { av_push(a, v); }
static SV **punk_real_hv_store(pTHX_ HV *h, const char *k, I32 kl, SV *v, U32 hash)
                                                           { return hv_store(h, k, kl, v, hash); }
static HE  *punk_real_hv_store_ent(pTHX_ HV *h, SV *k, SV *v, U32 hash)
                                                           { return hv_store_ent(h, k, v, hash); }

#undef sv_2mortal
#define sv_2mortal(s) \
    (PUNK_IS_IMM(s) \
       ? (punk_probe_hit(aTHX_ "sv_2mortal", __FILE__, __LINE__, (SV *)(s)), \
          (SV *)(s)) \
       : punk_real_2mortal(aTHX_ (SV *)(s)))

#undef av_store
#define av_store(av, i, val) \
    (PUNK_IS_IMM(val) \
       ? (punk_probe_hit(aTHX_ "av_store", __FILE__, __LINE__, (SV *)(val)), \
          punk_real_av_store(aTHX_ (av), (i), (SV *)(val))) \
       : punk_real_av_store(aTHX_ (av), (i), (SV *)(val)))

#undef av_push
#define av_push(av, val) \
    (PUNK_IS_IMM(val) \
       ? (punk_probe_hit(aTHX_ "av_push", __FILE__, __LINE__, (SV *)(val)), \
          punk_real_av_push(aTHX_ (av), (SV *)(val))) \
       : punk_real_av_push(aTHX_ (av), (SV *)(val)))

#undef hv_store
#define hv_store(hv, k, kl, val, hash) \
    (PUNK_IS_IMM(val) \
       ? (punk_probe_hit(aTHX_ "hv_store", __FILE__, __LINE__, (SV *)(val)), \
          punk_real_hv_store(aTHX_ (hv), (k), (kl), (SV *)(val), (hash))) \
       : punk_real_hv_store(aTHX_ (hv), (k), (kl), (SV *)(val), (hash)))

#undef hv_store_ent
#define hv_store_ent(hv, k, val, hash) \
    (PUNK_IS_IMM(val) \
       ? (punk_probe_hit(aTHX_ "hv_store_ent", __FILE__, __LINE__, (SV *)(val)), \
          punk_real_hv_store_ent(aTHX_ (hv), (k), (SV *)(val), (hash))) \
       : punk_real_hv_store_ent(aTHX_ (hv), (k), (SV *)(val), (hash)))

#endif /* PUNK_IMMORTAL_PROBE */

/* -DPUNK_OLD_AV_HOLES: make a modern perl account for array holes the way
 * every perl before 5.20 did.
 *
 *     make OPTIMIZE="-O0 -g -DPUNK_OLD_AV_HOLES" && prove -b t/42*.t
 *
 * Before 5.20, av_extend filled the slots it allocated with &PL_sv_undef
 * (perl5200delta: "Arrays now use NULL internally to represent unused slots,
 * instead of &PL_sv_undef"), and av_undef / av_clear then SvREFCNT_dec every
 * slot up to the fill - fillers included. So on those perls a later av_store
 * past a gap drags the gap into the live range, and freeing the array spends
 * one immortal reference per hole. That is perl's own bookkeeping, not a
 * mistake in the XS, and it is why t/42 cannot hold its invariant there.
 *
 * This reproduces exactly that on a current perl, for the arrays punk itself
 * extends, so the arithmetic can be checked without an old perl to hand. */
#ifdef PUNK_OLD_AV_HOLES

static void punk_real_av_extend(pTHX_ AV *av, SSize_t key) { av_extend(av, key); }

static void punk_old_av_extend(pTHX_ AV *av, SSize_t key) {
    SSize_t i = AvFILLp(av) + 1;
    SV **ary;
    punk_real_av_extend(aTHX_ av, key);
    if (!AvREAL(av)) return;
    ary = AvARRAY(av);
    for (; i <= key && i <= AvMAX(av); i++)
        if (!ary[i]) ary[i] = &PL_sv_undef;
}

#undef av_extend
#define av_extend(av, key) punk_old_av_extend(aTHX_ (av), (SSize_t)(key))

#endif /* PUNK_OLD_AV_HOLES */
#endif /* PUNK_IMMORTAL_PROBE_H */
