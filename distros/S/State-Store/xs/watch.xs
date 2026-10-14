# Watchers.

MODULE = State::Store    PACKAGE = State::Store

# watch($code): an id for unwatch.
void
watch(self, code)
        SV *self
        SV *code
    PREINIT:
        store *s;
    CODE:
        s = store_handle(aTHX_ self, "State::Store::watch");
        SvGETMAGIC(code);
        if (!SvROK(code) || SvTYPE(SvRV(code)) != SVt_PVCV)
            croak("State::Store::watch: not a code reference");
        ST(0) = sv_2mortal(newSVuv(store_watch_add(aTHX_ s, SvRV(code), NULL, NULL)));
        XSRETURN(1);

void
unwatch(self, id)
        SV *self
        SV *id
    PREINIT:
        store *s;
        UV n;
    CODE:
        s = store_handle(aTHX_ self, "State::Store::unwatch");
        id = store_read_once(aTHX_ id);
        n = (SvOK(id) && looks_like_number(id) && SvNV(id) >= 1 && SvNV(id) == (NV)SvUV(id))
          ? SvUV(id) : 0;
        ST(0) = boolSV(n && store_watch_remove(aTHX_ s, n));
        XSRETURN(1);

void
watchers(self)
        SV *self
    CODE:
        ST(0) = sv_2mortal(newSVuv((UV)store_handle(aTHX_ self, "State::Store::watchers")->live_watchers));
        XSRETURN(1);
