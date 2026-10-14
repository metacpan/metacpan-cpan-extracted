# State::Store: the cell. CODE blocks that set ST(0) and return by count:
# a swap runs Perl, which can move the stack, and ST() reads its base afresh
# each time where a saved SP would not.

MODULE = State::Store    PACKAGE = State::Store

# new($initial, %options). The options are read before the store is made,
# so a bad one leaves nothing behind.
void
new(klass, ...)
        SV *klass
    PREINIT:
        store *s;
        SV *obj;
        I32 i;
        size_t limit = 0;
        int limited = 0;
        SV *validator = NULL, *initial;
    CODE:
        if (items > 2 && (items & 1))
            croak("State::Store::new: odd number of options");
        for (i = 2; i < items; i += 2) {
            const char *name = SvPV_nolen(ST(i));
            if (strEQ(name, "history"))
                store_limit_arg(aTHX_ ST(i + 1), &limit, &limited, "State::Store::new");
            else if (strEQ(name, "validator"))
                validator = store_validator_arg(aTHX_ ST(i + 1), "State::Store::new");
            else
                croak("State::Store::new: unknown option \"%" SVf "\"", SVfARG(ST(i)));
        }
        /* The first value is checked, with undef for the one before it,
         * before there is a store to refuse it. */
        initial = sv_2mortal(store_copy_in(aTHX_ items > 1 ? ST(1) : &PL_sv_undef));
        if (validator && !store_validate(aTHX_ validator, NULL, NULL, initial, &PL_sv_undef, &PL_sv_undef, NULL))
            croak("State::Store::new: the validator refused the value");
        obj = store_new(aTHX_ store_class_stash(aTHX_ klass), initial, &s);
        s->limit   = limit;
        s->limited = limited;
        s->validator = validator ? SvREFCNT_inc_simple_NN(validator) : NULL;
        ST(0) = obj;
        XSRETURN(1);

void
current(self)
        SV *self
    CODE:
        ST(0) = store_get(aTHX_ store_handle(aTHX_ self, "State::Store::current"));
        XSRETURN(1);

# The store is returned, so calls chain. It is held for the length of the
# call: the value displaced may have a DESTROY that drops the last other
# reference to it.
void
set(self, value)
        SV *self
        SV *value
    PREINIT:
        store *s;
        SV *hold;
    CODE:
        s = store_handle(aTHX_ self, "State::Store::set");
        hold = sv_2mortal(newSVsv(self));
        if (store_put(aTHX_ s, value, hold, 1, "State::Store::set") < 0)
            croak("State::Store::set: the validator refused the value");
        store_deliver(aTHX_ s, hold);
        ST(0) = self;
        XSRETURN(1);

# swap($code, @args): the value becomes what $code returns when called with
# the current value and @args. Called once, in scalar context. A die leaves
# the store as it was and goes on up.
void
swap(self, code, ...)
        SV *self
        SV *code
    PREINIT:
        store *s;
        SV *current, *result, *hold, *err, **args;
        I32 i;
    CODE:
        s = store_handle(aTHX_ self, "State::Store::swap");
        SvGETMAGIC(code);
        if (!SvROK(code) || SvTYPE(SvRV(code)) != SVt_PVCV)
            croak("State::Store::swap: not a code reference");
        store_check_mutable(aTHX_ s, "State::Store::swap");
        hold = sv_2mortal(newSVsv(self));
        /* The callback may set the store it is swapping, which would free
         * the value it was handed. */
        current = sv_2mortal(SvREFCNT_inc_simple_NN(s->value));

        ENTER;
        SAVETMPS;
        Newx(args, items - 1, SV *);
        SAVEFREEPV(args);
        args[0] = current;
        for (i = 2; i < items; i++) args[i - 1] = ST(i);
        err = store_call(aTHX_ code, args, items - 1, G_SCALAR, &result, NULL);
        if (err) store_rethrow(aTHX_ err);
        if (store_put(aTHX_ s, result, hold, 1, "State::Store::swap") < 0)
            croak("State::Store::swap: the validator refused the value");
        FREETMPS;
        LEAVE;
        store_deliver(aTHX_ s, hold);

        ST(0) = self;
        XSRETURN(1);

void
CLONE_SKIP(...)
    CODE:
        ST(0) = &PL_sv_yes;
        XSRETURN(1);
