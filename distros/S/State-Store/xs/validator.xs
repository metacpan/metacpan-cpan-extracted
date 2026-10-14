# The validator.

MODULE = State::Store    PACKAGE = State::Store

# validator: the sub, or undef. With an argument, sets it (undef removes
# it) and returns the store. Setting one does not check the value held.
# One set through the C ABI is a function, not a sub: it reads as undef
# here, and setting a sub replaces it.
void
validator(self, ...)
        SV *self
    PREINIT:
        store *s;
        SV *code, *dead;
    CODE:
        s = store_handle(aTHX_ self, "State::Store::validator");
        if (items > 2) croak("State::Store::validator: too many arguments");
        if (items == 1) {
            ST(0) = s->validator ? sv_2mortal(newRV_inc(s->validator)) : &PL_sv_undef;
            XSRETURN(1);
        }
        store_check_mutable(aTHX_ s, "State::Store::validator");
        code = store_validator_arg(aTHX_ ST(1), "State::Store::validator");
        dead = s->validator;
        s->validator = code ? SvREFCNT_inc_simple_NN(code) : NULL;
        s->cvalidator = NULL;
        s->cvalidator_ud = NULL;
        if (dead) SvREFCNT_dec(dead);
        ST(0) = self;
        XSRETURN(1);
