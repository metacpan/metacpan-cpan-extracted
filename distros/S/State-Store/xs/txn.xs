# Transactions.

MODULE = State::Store    PACKAGE = State::Store

# txn($code): runs $code with the store, in the caller's context, and
# returns what it returns. A die inside puts the store back as it was and
# goes on up.
void
txn(self, code)
        SV *self
        SV *code
    PREINIT:
        store *s;
        SV *hold, *err, *one;
        AV *many;
        store_saved saved;
        I32 n, gimme, i;
    PPCODE:
        s = store_handle(aTHX_ self, "State::Store::txn");
        SvGETMAGIC(code);
        if (!SvROK(code) || SvTYPE(SvRV(code)) != SVt_PVCV)
            croak("State::Store::txn: not a code reference");
        store_check_mutable(aTHX_ s, "State::Store::txn");
        hold  = sv_2mortal(newSVsv(self));
        gimme = GIMME_V;
        store_txn_begin(aTHX_ s, &saved, "State::Store::txn");

        many = (AV *)sv_2mortal((SV *)newAV());
        PUTBACK;
        err = store_call(aTHX_ code, &hold, 1, gimme, &one, many);
        if (err) {
            store_txn_restore(aTHX_ s, &saved);
            store_rethrow(aTHX_ err);
        }
        if (s->txn_depth > 1) store_txn_forget(aTHX_ s, &saved);
        else {
            store_txn_commit(aTHX_ s, &saved, "State::Store::txn");
            store_deliver(aTHX_ s, hold);
        }
        SPAGAIN;
        if (gimme == G_SCALAR) {
            XPUSHs(one);
        }
        else if (gimme == G_LIST) {
            n = av_len(many) + 1;
            EXTEND(SP, n);
            for (i = 0; i < n; i++) PUSHs(*av_fetch(many, i, 0));
        }

void
in_txn(self)
        SV *self
    CODE:
        ST(0) = boolSV(store_handle(aTHX_ self, "State::Store::in_txn")->txn_depth > 0);
        XSRETURN(1);
