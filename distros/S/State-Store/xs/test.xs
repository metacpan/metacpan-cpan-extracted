# Doors for the tests. Nothing here is part of the interface.

MODULE = State::Store    PACKAGE = State::Store

# The version of the table this library resolved when it loaded.
IV
_hamt_abi_version()
    CODE:
        RETVAL = STORE_HAMT ? STORE_HAMT->abi_version : 0;
    OUTPUT:
        RETVAL

# The version of the header it was compiled against.
IV
_hamt_abi_built()
    CODE:
        RETVAL = HAMT_ABI_VERSION;
    OUTPUT:
        RETVAL

# A vector made, filled, read and given up through the table: how many it
# held, its last value, and whether HAMT called it well formed. Proof that
# the table resolved is one that can be called.
void
_hamt_roundtrip(...)
    PREINIT:
        hamt_vec *v;
        I32 i;
        size_t n;
        SV *last;
        int bad;
    PPCODE:
        v = (STORE_HAMT->vec_new)(aTHX);
        if (!v) croak("State::Store::_hamt_roundtrip: out of memory");
        for (i = 0; i < items; i++) {
            if ((STORE_HAMT->vec_push)(aTHX_ v, ST(i)) != HAMT_ABI_OK) {
                (STORE_HAMT->vec_release)(aTHX_ v);
                croak("State::Store::_hamt_roundtrip: out of memory");
            }
        }
        n    = (STORE_HAMT->vec_count)(aTHX_ v);
        last = n ? (STORE_HAMT->vec_fetch)(aTHX_ v, n - 1) : NULL;
        last = last ? newSVsv(last) : newSV(0);
        bad  = (STORE_HAMT->vec_check)(aTHX_ v);
        (STORE_HAMT->vec_release)(aTHX_ v);
        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSVuv((UV)n)));
        PUSHs(sv_2mortal(last));
        PUSHs(sv_2mortal(newSViv(bad)));

# How many blocks this library holds for itself.
IV
_live_blocks()
    CODE:
        RETVAL = (IV)store_live_blocks;
    OUTPUT:
        RETVAL

# perl's temporaries stack, for a test that says a loop of calls leaves
# nothing on it.
IV
_tmps_ix()
    CODE:
        RETVAL = (IV)PL_tmps_ix;
    OUTPUT:
        RETVAL

# Places in the watcher list, removed ones not yet swept out included.
IV
_watcher_slots(self)
        SV *self
    CODE:
        RETVAL = (IV)store_handle(aTHX_ self, "State::Store::_watcher_slots")->nwatchers;
    OUTPUT:
        RETVAL
