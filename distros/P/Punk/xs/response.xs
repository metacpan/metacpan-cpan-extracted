MODULE = Punk        PACKAGE = Punk::Response

PROTOTYPES: DISABLE

# new(%args): status, headers (a live pair arrayref), body, type.
SV *
new(class, ...)
        SV *class
    CODE:
    {
        AV *res = newAV();
        int i;
        av_extend(res, PS_BODY);
        for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl;
            const char *k = SvPV_const(ST(i), kl);
            SV *v = ST(i + 1);
            if (kl == 6 && memEQ(k, "status", 6))
                (void)av_store(res, PS_STATUS, newSVsv(v));
            else if (kl == 7 && memEQ(k, "headers", 7)) {
                if (!SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVAV)
                    croak("Punk::Response: headers must be an arrayref");
                (void)av_store(res, PS_HEADERS, newSVsv(v));
            }
            else if (kl == 4 && memEQ(k, "body", 4))
                (void)av_store(res, PS_BODY, newSVsv(v));
            else if (kl == 4 && memEQ(k, "type", 4))
                (void)av_store(res, PS_TYPE, newSVsv(v));
            else
                croak("Punk::Response: unknown option '%.*s'", (int)kl, k);
        }
        RETVAL = sv_bless(newRV_noinc((SV *)res),
                          gv_stashsv(class, GV_ADD));
    }
    OUTPUT:
        RETVAL

# get/set accessors; setters chain.
SV *
status(self, ...)
        SV *self
    ALIAS:
        type = 1
        body = 2
    CODE:
    {
        static const I32 slot[] = { PS_STATUS, PS_TYPE, PS_BODY };
        AV *res = punk_res_av(aTHX_ self);
        if (items > 1) {
            (void)av_store(res, slot[ix], newSVsv(ST(1)));
            RETVAL = newSVsv(self);
        }
        else {
            SV **e = av_fetch(res, slot[ix], 0);
            RETVAL = e && *e ? newSVsv(*e) : newSV(0);
        }
    }
    OUTPUT:
        RETVAL

# the live header-pair arrayref
SV *
headers(self)
        SV *self
    CODE:
        RETVAL = newRV_inc((SV *)punk_res_headers(aTHX_
            punk_res_av(aTHX_ self)));
    OUTPUT:
        RETVAL

# header(Name => $v, ...) appends and chains; header('Name') reads the
# first case-insensitive match.
SV *
header(self, ...)
        SV *self
    CODE:
    {
        AV *headers = punk_res_headers(aTHX_ punk_res_av(aTHX_ self));
        if (items > 2) {
            int i;
            for (i = 1; i < items; i++)
                av_push(headers, newSVsv(ST(i)));
            RETVAL = newSVsv(self);
        }
        else if (items == 2) {
            STRLEN wl;
            const char *want = SvPV_const(ST(1), wl);
            SSize_t i, n = av_len(headers) + 1;
            RETVAL = newSV(0);
            for (i = 0; i + 1 < n; i += 2) {
                SV **k = av_fetch(headers, i, 0);
                STRLEN kl;
                const char *kp;
                if (!(k && *k)) continue;
                kp = SvPV_const(*k, kl);
                if (kl == wl && foldEQ(kp, want, (I32)wl)) {
                    SV **v = av_fetch(headers, i + 1, 0);
                    if (v && *v) sv_setsv(RETVAL, *v);
                    break;
                }
            }
        }
        else croak("Punk::Response: header needs a name");
    }
    OUTPUT:
        RETVAL

# The PSGI triplet: a reference body JSON-encodes through the frj ABI,
# a string is html unless type says otherwise, no body is text/plain.
SV *
finalize(self)
        SV *self
    CODE:
    {
        AV *res = punk_res_av(aTHX_ self);
        SV **b = av_fetch(res, PS_BODY, 0);
        SV **t = av_fetch(res, PS_TYPE, 0);
        SV **s = av_fetch(res, PS_STATUS, 0);
        SV *type = (t && *t && SvOK(*t)) ? *t : NULL;
        IV status = (s && *s && SvOK(*s)) ? SvIV(*s) : 200;
        AV *extra = punk_res_headers(aTHX_ res);
        SV *bytes, *ct;
        if (!(b && *b && SvOK(*b))) {
            bytes = newSVpvs("");
            ct = type ? type
                      : sv_2mortal(newSVpvs("text/plain; charset=utf-8"));
        }
        else if (SvROK(*b)) {
            const frj_abi *J = punk_frj(aTHX);
            bytes = J->encode(aTHX_ *b, NULL);
            ct = type ? type : sv_2mortal(newSVpvs("application/json"));
        }
        else {
            bytes = newSVsv(*b);
            ct = type ? type
                      : sv_2mortal(newSVpvs("text/html; charset=utf-8"));
        }
        RETVAL = punk_triplet(aTHX_ status, ct, bytes, extra);
    }
    OUTPUT:
        RETVAL
