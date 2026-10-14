# Named checkpoints.

MODULE = State::Store    PACKAGE = State::Store

# checkpoint($name): the current value under that name. Returns the store.
void
checkpoint(self, name)
        SV *self
        SV *name
    CODE:
        store_checkpoint(aTHX_ store_handle(aTHX_ self, "State::Store::checkpoint"),
                         name, "State::Store::checkpoint");
        ST(0) = self;
        XSRETURN(1);

# restore($name): the value named becomes current, as a change: a step, the
# redo stack emptied, the watchers told; not the validator. Returns the store.
void
restore(self, name)
        SV *self
        SV *name
    PREINIT:
        store *s;
        SV *hold, *value;
    CODE:
        s = store_handle(aTHX_ self, "State::Store::restore");
        store_check_mutable(aTHX_ s, "State::Store::restore");
        store_check_no_txn(aTHX_ s, "State::Store::restore");
        hold  = sv_2mortal(newSVsv(self));
        value = sv_2mortal(SvREFCNT_inc_simple_NN(store_named(aTHX_ s, name, "State::Store::restore")));
        store_put(aTHX_ s, value, hold, 0, "State::Store::restore");
        store_deliver(aTHX_ s, hold);
        ST(0) = self;
        XSRETURN(1);

void
has_checkpoint(self, name)
        SV *self
        SV *name
    PREINIT:
        store *s;
        STRLEN len;
        int utf8;
        const char *p;
    CODE:
        s = store_handle(aTHX_ self, "State::Store::has_checkpoint");
        p = store_name(aTHX_ name, &len, &utf8, "State::Store::has_checkpoint");
        ST(0) = boolSV(s->checkpoints && (STORE_HAMT->map_has)(aTHX_ s->checkpoints, p, len, utf8));
        XSRETURN(1);

void
drop_checkpoint(self, name)
        SV *self
        SV *name
    CODE:
        sv_2mortal(newSVsv(self));
        store_drop_checkpoint(aTHX_ store_handle(aTHX_ self, "State::Store::drop_checkpoint"),
                              name, "State::Store::drop_checkpoint");
        ST(0) = self;
        XSRETURN(1);

# The names, sorted; in scalar context, how many.
void
checkpoints(self)
        SV *self
    PREINIT:
        store *s;
        AV *names;
        SSize_t i, n;
    PPCODE:
        s = store_handle(aTHX_ self, "State::Store::checkpoints");
        n = s->checkpoints ? (SSize_t)(STORE_HAMT->map_count)(aTHX_ s->checkpoints) : 0;
        if (GIMME_V != G_LIST) {
            XPUSHs(sv_2mortal(newSVuv((UV)n)));
            XSRETURN(1);
        }
        if (!n) XSRETURN_EMPTY;
        names = (AV *)sv_2mortal((SV *)newAV());
        (STORE_HAMT->map_walk)(aTHX_ s->checkpoints, store_name_into_av, names);
        sortsv(AvARRAY(names), av_len(names) + 1, Perl_sv_cmp);
        EXTEND(SP, n);
        for (i = 0; i < n; i++) PUSHs(*av_fetch(names, i, 0));
