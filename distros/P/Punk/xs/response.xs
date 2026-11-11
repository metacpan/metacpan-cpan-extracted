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
            if (kl == 6 && memEQ(k, "status", 6)) { /* # uncoverable condition right count:2 class:ignore_covered_err */
                sv_2mortal((SV *)res);              /* freed if this croaks */
                (void)ps_status_arg(aTHX_ v);
                SvREFCNT_inc_simple_void_NN((SV *)res);
                (void)av_store(res, PS_STATUS, newSVsv(v));
            }
            # uncoverable branch true
            # uncoverable condition left count:1 class:ignore_covered_err
            # uncoverable condition left count:2 class:ignore_covered_err
            # uncoverable condition right count:2 class:ignore_covered_err
            else if (kl == 7 && memEQ(k, "headers", 7)) {
                # uncoverable statement
                # uncoverable branch true
                # uncoverable branch false
                # uncoverable condition left count:1
                # uncoverable condition right count:1
                # uncoverable condition left count:2
                # uncoverable condition right count:2
                if (!SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVAV)
                    croak("Punk::Response: headers must be an arrayref"); /* # uncoverable statement */
                (void)av_store(res, PS_HEADERS, newSVsv(v)); /* # uncoverable statement */
            }
            # uncoverable branch false
            # uncoverable condition right count:1 class:ignore_covered_err
            # uncoverable condition right count:2 class:ignore_covered_err
            else if (kl == 4 && memEQ(k, "body", 4))
                (void)av_store(res, PS_BODY, newSVsv(v));
            # uncoverable statement
            # uncoverable branch true
            # uncoverable branch false
            # uncoverable condition left count:1
            # uncoverable condition right count:1
            # uncoverable condition left count:2
            # uncoverable condition right count:2
            else if (kl == 4 && memEQ(k, "type", 4))
                (void)av_store(res, PS_TYPE, newSVsv(v)); /* # uncoverable statement */
            else
                croak("Punk::Response: unknown option '%.*s'", (int)kl, k); /* # uncoverable statement */
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
        # uncoverable branch false
        # uncoverable condition right count:1 class:ignore_covered_err
        if (items > 1) {
            if (ix == 0) (void)ps_status_arg(aTHX_ ST(1));
            (void)av_store(res, slot[ix], newSVsv(ST(1)));
            RETVAL = newSVsv(self);
        }
        else {
            SV **e = av_fetch(res, slot[ix], 0); /* # uncoverable statement */
            # uncoverable statement
            # uncoverable condition left count:1
            # uncoverable condition right count:1
            # uncoverable condition left count:2
            # uncoverable condition right count:2
            RETVAL = e && *e ? newSVsv(*e) : newSV(0);
        }
    }
    OUTPUT:
        RETVAL

# the live header-pair arrayref
SV *
# uncoverable statement
# uncoverable subroutine
headers(self)
        SV *self
    CODE:
        RETVAL = newRV_inc((SV *)punk_res_headers(aTHX_ /* # uncoverable statement */
            punk_res_av(aTHX_ self)));
    OUTPUT:
        RETVAL

# header(Name => $v, ...) appends and chains; header('Name') reads the
# first case-insensitive match. A name or value carrying CR, LF or NUL is
# refused before anything is appended: those bytes end a header, and one
# built from request input would otherwise be a second header of the
# client's choosing.
SV *
header(self, ...)
        SV *self
    CODE:
    {
        AV *headers = punk_res_headers(aTHX_ punk_res_av(aTHX_ self));
        if (items > 2) {
            int i;
            for (i = 1; i < items; i++) {
                STRLEN l, j;
                const char *p;
                # uncoverable branch true
                # uncoverable condition left count:1 class:ignore_covered_err
                if (!SvOK(ST(i))) continue;
                p = SvPV_const(ST(i), l);
                for (j = 0; j < l; j++)
                    if (p[j] == '\r' || p[j] == '\n' || p[j] == '\0')
                        croak("Punk::Response: a header %s may not contain "
                              "CR, LF or NUL", (i & 1) ? "name" : "value");
            }
            for (i = 1; i < items; i++)
                av_push(headers, newSVsv(ST(i)));
            RETVAL = newSVsv(self);
        }
        # uncoverable branch false
        # uncoverable condition right count:1 class:ignore_covered_err
        else if (items == 2) {
            STRLEN wl;
            const char *want = SvPV_const(ST(1), wl);
            SSize_t i, n = av_len(headers) + 1;
            RETVAL = newSV(0);
            # uncoverable branch false
            # uncoverable condition right count:1 class:ignore_covered_err
            for (i = 0; i + 1 < n; i += 2) {
                SV **k = av_fetch(headers, i, 0);
                STRLEN kl;
                const char *kp;
                # uncoverable branch true
                # uncoverable condition left count:1 class:ignore_covered_err
                # uncoverable condition left count:2 class:ignore_covered_err
                if (!(k && *k)) continue;
                kp = SvPV_const(*k, kl);
                # uncoverable branch false
                # uncoverable condition right count:1 class:ignore_covered_err
                # uncoverable condition right count:2 class:ignore_covered_err
                if (kl == wl && foldEQ(kp, want, (I32)wl)) {
                    SV **v = av_fetch(headers, i + 1, 0);
                    # uncoverable branch false
                    # uncoverable condition right count:1 class:ignore_covered_err
                    # uncoverable condition right count:2 class:ignore_covered_err
                    if (v && *v) sv_setsv(RETVAL, *v);
                    break;
                }
            }
        }
        else croak("Punk::Response: header needs a name"); /* # uncoverable statement */
    }
    OUTPUT:
        RETVAL

# The PSGI triplet: an XML document or node serialises through the frx ABI,
# any other reference body JSON-encodes through the frj ABI, a string is html
# unless type says otherwise, no body is text/plain.
SV *
finalize(self, ...)
        SV *self
    CODE:
    {
        /* finalize($canonical): the dispatcher passes true on an
         * `etag => 1` route, so a JSON body is encoded with its keys in
         * order and the tag is the same in every worker */
        # uncoverable condition left count:1 class:ignore_covered_err
        # uncoverable condition left count:2 class:ignore_covered_err
        int canon = items > 1 && SvTRUE(ST(1));
        AV *res = punk_res_av(aTHX_ self);
        SV **b = av_fetch(res, PS_BODY, 0);
        SV **t = av_fetch(res, PS_TYPE, 0);
        SV **s = av_fetch(res, PS_STATUS, 0);
        # uncoverable condition right count:2 class:ignore_covered_err
        # uncoverable condition right count:3 class:ignore_covered_err
        SV *type = (t && *t && SvOK(*t)) ? *t : NULL;
        IV status = (s && *s && SvOK(*s)) ? SvIV(*s) : 200; /* # uncoverable condition right count:2 class:ignore_covered_err */
        AV *extra = punk_res_headers(aTHX_ res);
        SV *bytes, *ct;
        if (!status) status = 200;          /* none given */
        # uncoverable condition left count:2 class:ignore_covered_err
        # uncoverable condition left count:3 class:ignore_covered_err
        if (!(b && *b && SvOK(*b))) {
            bytes = newSVpvs("");
            ct = type ? type
                      : sv_2mortal(newSVpvs("text/plain; charset=utf-8"));
        }
        else if (punk_xml_is(aTHX_ *b)) {
            /* before the reference arm below, which would otherwise hand a
             * document - a blessed reference like any other - to the JSON
             * encoder */
            SV *err = NULL;
            bytes = punk_xml_bytes(aTHX_ *b, &err);
            # uncoverable branch true
            # uncoverable condition left count:1 class:ignore_covered_err
            # uncoverable condition left count:2 class:ignore_covered_err
            # uncoverable condition right count:2 class:ignore_covered_err
            if (!bytes) croak("%s", err ? SvPV_nolen(err) : "Punk: xml");
            ct = type ? type : sv_2mortal(newSVpvs(PK_XML_CT));
        }
        else if (SvROK(*b)) {
            const frj_abi *J = punk_frj(aTHX);
            frj_opts o;
            Zero(&o, 1, frj_opts);
            o.canonical = 1;
            bytes = J->encode(aTHX_ *b, canon ? &o : NULL); /* # uncoverable condition left count:1 class:ignore_covered_err */
            ct = type ? type : sv_2mortal(newSVpvs("application/json")); /* # uncoverable condition right count:1 class:ignore_covered_err */
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
