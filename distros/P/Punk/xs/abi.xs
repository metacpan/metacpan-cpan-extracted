MODULE = Punk        PACKAGE = Punk

PROTOTYPES: DISABLE

# Address of Punk's own C ABI table (pk_abi.h). A consumer XS module fetches
# this once at boot, INT2PTRs it to a `const pk_abi *`, and checks
# ->abi_version before using it. Not part of the public Perl API.
IV
_abi_ptr()
    CODE:
        RETVAL = PTR2IV(&PK_ABI);
    OUTPUT:
        RETVAL

# ---- the self-test consumer -------------------------------------------------
#
# Exercise the whole pk_abi table the way a C consumer would - register through
# the table's own on_request/on_response, then read the request back through
# its accessors - so the test suite proves the FUNCTION POINTERS work and not
# just the static functions behind them. Open::API's _abi_selftest is the same
# idea. Private.

# Install the observers, once. Returns 1 when both registered.
IV
_abi_selftest_install()
    CODE:
    {
        const pk_abi *A = INT2PTR(const pk_abi *, PTR2IV(&PK_ABI));
        if (!A || A->abi_version != PK_ABI_VERSION) XSRETURN_IV(0);
        if (PK_SELFTEST_ON) XSRETURN_IV(1);      /* idempotent */
        PK_SELFTEST_ON =
              A->on_request(aTHX_ pk_selftest_req, NULL)
           && A->on_response(aTHX_ pk_selftest_res, NULL)
           && A->on_query(aTHX_ pk_selftest_query, pk_selftest_query_done,
                          NULL);
        RETVAL = PK_SELFTEST_ON;
    }
    OUTPUT:
        RETVAL

# Everything the observers recorded since the last call, and reset.
# An arrayref of hashrefs; see pk_selftest_event in punk_obs_selftest.h.
SV *
_abi_selftest_events()
    CODE:
    {
        AV *ev = pk_selftest_av(aTHX);
        AV *out = newAV();
        SSize_t i, n = av_len(ev) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(ev, i, 0);
            if (e && *e) av_push(out, newSVsv(*e));
        }
        av_clear(ev);
        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL

# v2 on_query: (starts, dones, ok, nbind, sql) since load.
void
_abi_selftest_queries()
    PPCODE:
        EXTEND(SP, 5);
        mPUSHi(PK_SELFTEST_Q_STARTS);
        mPUSHi(PK_SELFTEST_Q_DONES);
        mPUSHi(PK_SELFTEST_Q_OK);
        mPUSHi(PK_SELFTEST_Q_BIND);
        mPUSHp(PK_SELFTEST_Q_SQL, strlen(PK_SELFTEST_Q_SQL));
