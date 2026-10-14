#ifndef STORE_HAMT_H
#define STORE_HAMT_H

/* HAMT's table, resolved once when this library loads and never per call.
 * Calls are written (STORE_HAMT->vec_push)(aTHX_ ...): the parentheses keep
 * a member's name from being read as one of the macros XSUB.h makes of
 * ordinary names on a perl built with PERL_IMPLICIT_SYS. */
static const hamt_abi *STORE_HAMT = NULL;

/* hamt_abi.h tells an optional consumer to carry on without the table. This
 * one cannot: there is no history without a vector to keep it in. So a
 * missing or older HAMT stops the load, saying which it was. */
static void store_hamt_boot(pTHX) {
    const hamt_abi *t;
    SV *sv = eval_pv("require HAMT; HAMT::_abi_ptr()", 0);

    if (SvTRUE(ERRSV))
        croak("State::Store: cannot load HAMT: %" SVf, SVfARG(ERRSV));
    if (!sv || !SvOK(sv))
        croak("State::Store: HAMT did not hand over its C ABI");
    t = INT2PTR(const hamt_abi *, SvUV(sv));
    if (!t)
        croak("State::Store: HAMT did not hand over its C ABI");
    if (t->abi_version < HAMT_ABI_VERSION)
        croak("State::Store: HAMT's C ABI is version %d and version %d or later is needed",
              t->abi_version, HAMT_ABI_VERSION);
    STORE_HAMT = t;
}

#endif
