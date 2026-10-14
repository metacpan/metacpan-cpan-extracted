# Undo and redo.

MODULE = State::Store    PACKAGE = State::Store

# undo / redo, with an optional number of steps: how many were taken.
void
undo(self, ...)
        SV *self
    ALIAS:
        redo = 1
    PREINIT:
        store *s;
        size_t n;
        const char *what;
        SV *hold;
    CODE:
        what = ix ? "State::Store::redo" : "State::Store::undo";
        s = store_handle(aTHX_ self, what);
        if (items > 2) croak("%s: too many arguments", what);
        n = store_steps(aTHX_ items > 1 ? ST(1) : NULL, what);
        hold = sv_2mortal(newSVsv(self));
        n = store_move(aTHX_ s, !ix, n, what);
        store_deliver(aTHX_ s, hold);
        ST(0) = sv_2mortal(newSVuv((UV)n));
        XSRETURN(1);

void
can_undo(self)
        SV *self
    ALIAS:
        can_redo = 1
    PREINIT:
        store *s;
    CODE:
        s = store_handle(aTHX_ self, ix ? "State::Store::can_redo" : "State::Store::can_undo");
        ST(0) = boolSV((ix ? (STORE_HAMT->vec_count)(aTHX_ s->future) : store_past_len(aTHX_ s)) > 0);
        XSRETURN(1);

void
undo_count(self)
        SV *self
    ALIAS:
        redo_count = 1
    PREINIT:
        store *s;
    CODE:
        s = store_handle(aTHX_ self, ix ? "State::Store::redo_count" : "State::Store::undo_count");
        ST(0) = sv_2mortal(newSVuv((UV)(ix ? (STORE_HAMT->vec_count)(aTHX_ s->future) : store_past_len(aTHX_ s))));
        XSRETURN(1);

void
clear_history(self)
        SV *self
    PREINIT:
        store *s;
    CODE:
        s = store_handle(aTHX_ self, "State::Store::clear_history");
        sv_2mortal(newSVsv(self));
        store_clear_history(aTHX_ s, "State::Store::clear_history");
        ST(0) = self;
        XSRETURN(1);

# 0 when both stacks are well formed vectors, or the number of the first
# check that failed: 1 for the past, 2 for the future. For the tests.
IV
_check(self)
        SV *self
    PREINIT:
        store *s;
    CODE:
        s = store_handle(aTHX_ self, "State::Store::_check");
        RETVAL = (STORE_HAMT->vec_check)(aTHX_ s->past)   ? 1
               : (STORE_HAMT->vec_check)(aTHX_ s->future) ? 2 : 0;
    OUTPUT:
        RETVAL

# Both stacks as lists, past then future, for a test to compare with a model:
# the past as undo sees it, without steps beyond the limit not yet cut.
void
_stacks(self)
        SV *self
    PREINIT:
        store *s;
        AV *past, *future;
    PPCODE:
        s = store_handle(aTHX_ self, "State::Store::_stacks");
        past   = (STORE_HAMT->vec_to_av)(aTHX_ s->past);
        future = (STORE_HAMT->vec_to_av)(aTHX_ s->future);
        if (!past || !future) croak("State::Store::_stacks: out of memory");
        while ((size_t)(av_len(past) + 1) > store_past_len(aTHX_ s)) SvREFCNT_dec(av_shift(past));
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newRV_noinc((SV *)past)));
        PUSHs(sv_2mortal(newRV_noinc((SV *)future)));

# history_limit: the limit, or undef for none. With an argument, sets it,
# cuts the past to it at once, and returns the store.
void
history_limit(self, ...)
        SV *self
    PREINIT:
        store *s;
        size_t limit;
        int limited;
    CODE:
        s = store_handle(aTHX_ self, "State::Store::history_limit");
        if (items > 2) croak("State::Store::history_limit: too many arguments");
        if (items == 1) {
            ST(0) = s->limited ? sv_2mortal(newSVuv((UV)s->limit)) : &PL_sv_undef;
            XSRETURN(1);
        }
        store_limit_arg(aTHX_ ST(1), &limit, &limited, "State::Store::history_limit");
        sv_2mortal(newSVsv(self));
        store_set_limit(aTHX_ s, limit, limited, "State::Store::history_limit");
        ST(0) = self;
        XSRETURN(1);
