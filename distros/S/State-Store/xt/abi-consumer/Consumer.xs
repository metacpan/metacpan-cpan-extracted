#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* The only thing this file knows about State::Store. */
#include "state_store_abi.h"

static const state_store_abi *STORE = NULL;

#define NEED_ABI(what) do { if (!STORE) croak("%s: no State::Store ABI", what); } while (0)

/* What the C watcher saw: a log of "was>now", and the store each time. */
static SV *seen = NULL;
static SV *seen_store = NULL;

static void log_change(pTHX_ void *ud, SV *was, SV *now, SV *st) {
    PERL_UNUSED_ARG(ud);
    if (SvCUR(seen)) sv_catpvs(seen, " ");
    sv_catpvf(seen, "%" SVf ">%" SVf, SVfARG(was), SVfARG(now));
    sv_setsv(seen_store, st);
}

static int below(pTHX_ void *ud, SV *proposed, SV *held, SV *st) {
    PERL_UNUSED_ARG(held); PERL_UNUSED_ARG(st);
    return SvIV(proposed) < *(IV *)ud;
}
static IV ceiling = 0;

static SV *add(pTHX_ void *ud, SV *current) {
    return sv_2mortal(newSViv(SvIV(current) + *(IV *)ud));
}

static int collect(pTHX_ void *ud, const char *name, STRLEN len, int utf8, SV *value) {
    SV *n = newSVpvn(name, len);
    if (utf8) SvUTF8_on(n);
    hv_store_ent((HV *)ud, sv_2mortal(n), newSVsv(value), 0);
    return 0;
}

MODULE = State::Store::ABI::Consumer    PACKAGE = State::Store::ABI::Consumer

PROTOTYPES: DISABLE

BOOT:
{
    SV *err;
    SV *sv = eval_pv("require State::Store; State::Store::_abi_ptr()", 0);
    err = get_sv("@", 0);
    if (sv && SvOK(sv) && (!err || !SvTRUE(err))) {
        const state_store_abi *t = INT2PTR(const state_store_abi *, SvUV(sv));
        if (t && t->abi_version >= STATE_STORE_ABI_VERSION) STORE = t;
    }
    seen = newSVpvs("");
    seen_store = newSV(0);
}

IV
abi_version()
    CODE:
        RETVAL = STORE ? STORE->abi_version : 0;
    OUTPUT:
        RETVAL

SV *
make(initial)
        SV *initial
    CODE:
        NEED_ABI("make");
        RETVAL = (STORE->store_new)(aTHX_ initial);
    OUTPUT:
        RETVAL

IV
is_store(sv)
        SV *sv
    CODE:
        NEED_ABI("is_store");
        RETVAL = (STORE->is_store)(aTHX_ sv);
    OUTPUT:
        RETVAL

SV *
get(st)
        SV *st
    PREINIT:
        SV *v;
    CODE:
        NEED_ABI("get");
        v = (STORE->current)(aTHX_ st);
        RETVAL = v ? newSVsv(v) : &PL_sv_undef;
    OUTPUT:
        RETVAL

IV
set(st, value)
        SV *st
        SV *value
    CODE:
        NEED_ABI("set");
        RETVAL = (STORE->set)(aTHX_ st, value);
    OUTPUT:
        RETVAL

# set, with a mortal the caller keeps using: what it holds afterwards.
SV *
set_temp(st, text)
        SV *st
        SV *text
    PREINIT:
        SV *tmp;
    CODE:
        NEED_ABI("set_temp");
        tmp = sv_2mortal(newSVsv(text));
        (STORE->set)(aTHX_ st, tmp);
        RETVAL = newSVsv(tmp);
    OUTPUT:
        RETVAL

IV
swap_add(st, n)
        SV *st
        IV n
    CODE:
        NEED_ABI("swap_add");
        RETVAL = (STORE->swap)(aTHX_ st, add, &n);
    OUTPUT:
        RETVAL

void
undo(st, n)
        SV *st
        UV n
    PREINIT:
        size_t taken = 999;
        int rc;
    PPCODE:
        NEED_ABI("undo");
        rc = (STORE->undo)(aTHX_ st, (size_t)n, &taken);
        mXPUSHi(rc);
        mXPUSHu((UV)taken);

UV
counts(st)
        SV *st
    CODE:
        NEED_ABI("counts");
        RETVAL = (UV)(STORE->undo_count)(aTHX_ st) * 1000 + (UV)(STORE->redo_count)(aTHX_ st);
    OUTPUT:
        RETVAL

UV
watch(st)
        SV *st
    CODE:
        NEED_ABI("watch");
        sv_setpvs(seen, "");
        RETVAL = (STORE->watch)(aTHX_ st, log_change, NULL);
    OUTPUT:
        RETVAL

IV
unwatch(st, id)
        SV *st
        UV id
    CODE:
        NEED_ABI("unwatch");
        RETVAL = (STORE->unwatch)(aTHX_ st, id);
    OUTPUT:
        RETVAL

SV *
seen()
    CODE:
        RETVAL = newSVsv(seen);
    OUTPUT:
        RETVAL

SV *
seen_store()
    CODE:
        RETVAL = newSVsv(seen_store);
    OUTPUT:
        RETVAL

void
forget_seen()
    CODE:
        sv_setpvs(seen, "");
        sv_setsv(seen_store, &PL_sv_undef);

IV
cap(st, max)
        SV *st
        IV max
    CODE:
        NEED_ABI("cap");
        ceiling = max;
        RETVAL = (STORE->set_validator)(aTHX_ st, max ? below : NULL, &ceiling);
    OUTPUT:
        RETVAL

# Opens a transaction, sets each value, then commits or aborts it. With
# `wrong`, tries to close the outer one while an inner one is open first.
void
txn(st, abort, wrong, ...)
        SV *st
        IV abort
        IV wrong
    PREINIT:
        state_store_txn *t, *inner = NULL;
        int status = 0, rc, order = 0;
        I32 i;
    PPCODE:
        NEED_ABI("txn");
        t = (STORE->txn_begin)(aTHX_ st, &status);
        if (!t) { mXPUSHi(status); XSRETURN(1); }
        if (wrong) {
            inner = (STORE->txn_begin)(aTHX_ st, NULL);
            order = (STORE->txn_commit)(aTHX_ t);
        }
        for (i = 3; i < items; i++) (STORE->set)(aTHX_ st, ST(i));
        if (inner) (STORE->txn_commit)(aTHX_ inner);
        rc = abort ? (STORE->txn_abort)(aTHX_ t) : (STORE->txn_commit)(aTHX_ t);
        mXPUSHi(rc);
        mXPUSHi(order);

IV
in_txn(st)
        SV *st
    CODE:
        NEED_ABI("in_txn");
        RETVAL = (STORE->in_txn)(aTHX_ st);
    OUTPUT:
        RETVAL

IV
checkpoint(st, name)
        SV *st
        SV *name
    PREINIT:
        STRLEN len;
        const char *p;
    CODE:
        NEED_ABI("checkpoint");
        p = SvPV(name, len);
        RETVAL = (STORE->checkpoint)(aTHX_ st, p, len, SvUTF8(name) ? 1 : 0);
    OUTPUT:
        RETVAL

IV
restore(st, name)
        SV *st
        SV *name
    PREINIT:
        STRLEN len;
        const char *p;
    CODE:
        NEED_ABI("restore");
        p = SvPV(name, len);
        RETVAL = (STORE->restore)(aTHX_ st, p, len, SvUTF8(name) ? 1 : 0);
    OUTPUT:
        RETVAL

IV
drop(st, name)
        SV *st
        SV *name
    PREINIT:
        STRLEN len;
        const char *p;
    CODE:
        NEED_ABI("drop");
        p = SvPV(name, len);
        RETVAL = (STORE->drop_checkpoint)(aTHX_ st, p, len, SvUTF8(name) ? 1 : 0);
    OUTPUT:
        RETVAL

SV *
named(st)
        SV *st
    PREINIT:
        HV *hv;
    CODE:
        NEED_ABI("named");
        hv = newHV();
        (STORE->checkpoint_walk)(aTHX_ st, collect, hv);
        RETVAL = newRV_noinc((SV *)hv);
    OUTPUT:
        RETVAL

IV
limit(st, n)
        SV *st
        IV n
    PREINIT:
        size_t got = 0;
        int rc;
    CODE:
        NEED_ABI("limit");
        rc = (STORE->set_history_limit)(aTHX_ st, n >= 0, n >= 0 ? (size_t)n : 0);
        if (rc < 0) RETVAL = rc;
        else RETVAL = (STORE->history_limit)(aTHX_ st, &got) ? (IV)got : -100;
    OUTPUT:
        RETVAL

IV
clear(st)
        SV *st
    CODE:
        NEED_ABI("clear");
        RETVAL = (STORE->clear_history)(aTHX_ st);
    OUTPUT:
        RETVAL
