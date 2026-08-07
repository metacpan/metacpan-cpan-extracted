MODULE = Punk        PACKAGE = Punk::Request

PROTOTYPES: DISABLE

SV *
new(class, env)
        SV *class
        SV *env
    CODE:
    {
        AV *req = newAV();
        av_extend(req, PQ_READ);
        (void)av_store(req, PQ_ENV, newSVsv(env));
        RETVAL = sv_bless(newRV_noinc((SV *)req),
                          gv_stashsv(class, GV_ADD));
    }
    OUTPUT:
        RETVAL

SV *
env(self)
        SV *self
    CODE:
    {
        SV **e = av_fetch(punk_req_av(aTHX_ self), PQ_ENV, 0);
        RETVAL = e && *e ? newSVsv(*e) : newSV(0);
    }
    OUTPUT:
        RETVAL

# The raw body bytes, read once from psgi.input and cached; the cached
# SV itself is returned, matching the Perl aliasing semantics.
SV *
body(self)
        SV *self
    CODE:
    {
        SV *body = pq_body(aTHX_ punk_req_av(aTHX_ self));
        RETVAL = SvREFCNT_inc_simple_NN(body);
    }
    OUTPUT:
        RETVAL

# The body decoded through File::Raw::JSON's C ABI.
SV *
json(self)
        SV *self
    CODE:
    {
        SV *body = pq_body(aTHX_ punk_req_av(aTHX_ self));
        if (SvOK(body) && SvCUR(body)) {
            const frj_abi *J = punk_frj(aTHX);
            STRLEN bl;
            const char *b = SvPV_const(body, bl);
            RETVAL = J->decode(aTHX_ b, bl, NULL);
        }
        else RETVAL = newSV(0);
    }
    OUTPUT:
        RETVAL

SV *
method(self)
        SV *self
    CODE:
    {
        HV *env = punk_req_env(aTHX_ punk_req_av(aTHX_ self));
        SV **e  = hv_fetchs(env, "REQUEST_METHOD", 0);
        RETVAL = e && *e ? newSVsv(*e) : newSV(0);
    }
    OUTPUT:
        RETVAL

SV *
path(self)
        SV *self
    CODE:
    {
        HV *env = punk_req_env(aTHX_ punk_req_av(aTHX_ self));
        SV **e  = hv_fetchs(env, "PATH_INFO", 0);
        RETVAL = (e && *e && SvOK(*e) && SvCUR(*e))
            ? newSVsv(*e) : newSVpvs("/");
    }
    OUTPUT:
        RETVAL

SV *
header(self, name)
        SV *self
        SV *name
    CODE:
    {
        HV *env = punk_req_env(aTHX_ punk_req_av(aTHX_ self));
        STRLEN nl, i;
        const char *n = SvPV_const(name, nl);
        char buf[256] = "HTTP_";
        SV **e;
        if (nl > 240) croak("Punk::Request: header name too long");
        for (i = 0; i < nl; i++) {
            char c = n[i];
            buf[5 + i] = c == '-' ? '_' : (char)toUPPER((U8)c);
        }
        e = hv_fetch(env, buf, (I32)(nl + 5), 0);
        if (!(e && *e && SvOK(*e))) {
            if (nl == 12 && memEQ(buf + 5, "CONTENT_TYPE", 12))
                e = hv_fetchs(env, "CONTENT_TYPE", 0);
            else if (nl == 14 && memEQ(buf + 5, "CONTENT_LENGTH", 14))
                e = hv_fetchs(env, "CONTENT_LENGTH", 0);
            else e = NULL;
        }
        RETVAL = e && *e ? newSVsv(*e) : newSV(0);
    }
    OUTPUT:
        RETVAL

# headers: every header at once, as a hashref keyed lowercase and
# dash-separated ('x-forwarded-for'). That is the spelling HTTP/2 uses and
# the one header() already accepts, but note the asymmetry: header() folds
# case for you, a plain hash cannot, so $req->headers->{'X-Foo'} misses where
# $req->header('X-Foo') hits. CONTENT_TYPE and CONTENT_LENGTH appear as
# 'content-type' and 'content-length' - PSGI keeps them out of HTTP_*, and
# header() special-cases them for the same reason.
#
# A fresh hash per call, so a caller may keep or mutate it freely.
SV *
headers(self)
        SV *self
    CODE:
    {
        HV *env = punk_req_env(aTHX_ punk_req_av(aTHX_ self));
        HV *h   = pq_headers(aTHX_ env);
        SV **e  = hv_fetchs(env, "CONTENT_LENGTH", 0);
        if (e && *e && SvOK(*e)) {
            STRLEN vl;
            (void)SvPV_const(*e, vl);   /* may be an IV; do not read SvCUR */
            if (vl) (void)hv_stores(h, "content-length", newSVsv(*e));
        }
        RETVAL = newRV_noinc((SV *)h);
    }
    OUTPUT:
        RETVAL

SV *
query(self)
        SV *self
    CODE:
    {
        AV *req = punk_req_av(aTHX_ self);
        SV **c  = av_fetch(req, PQ_QUERY, 0);
        if (c && *c && SvROK(*c))
            RETVAL = newSVsv(*c);
        else {
            HV *env = punk_req_env(aTHX_ req);
            SV **qs = hv_fetchs(env, "QUERY_STRING", 0);
            STRLEN ql = 0;
            const char *q = qs && *qs && SvOK(*qs)
                ? SvPV_const(*qs, ql) : "";
            RETVAL = newSVsv(pq_cached(aTHX_ req, PQ_QUERY,
                pq_parse_pairs(aTHX_ q, ql)));
        }
    }
    OUTPUT:
        RETVAL

SV *
form(self)
        SV *self
    CODE:
    {
        AV *req = punk_req_av(aTHX_ self);
        SV **c  = av_fetch(req, PQ_FORM, 0);
        if (c && *c && SvROK(*c))
            RETVAL = newSVsv(*c);
        else {
            HV *env = punk_req_env(aTHX_ req);
            SV **ct = hv_fetchs(env, "CONTENT_TYPE", 0);
            STRLEN cl = 0;
            const char *cts = ct && *ct && SvOK(*ct)
                ? SvPV_const(*ct, cl) : "";
            HV *built;
            if (cl >= 33
                && memEQ(cts, "application/x-www-form-urlencoded", 33)) {
                /* the body read is I/O and stays Perl - one method
                 * call, after which the parse is cached here */
                dSP;
                SV *body;
                int count;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(self);
                PUTBACK;
                count = call_method("body", G_SCALAR);
                SPAGAIN;
                body = count > 0 ? POPs : &PL_sv_undef;
                if (SvOK(body)) {
                    STRLEN bl;
                    const char *b = SvPV_const(body, bl);
                    built = pq_parse_pairs(aTHX_ b, bl);
                }
                else built = newHV();
                PUTBACK; FREETMPS; LEAVE;
            }
            else if (cl >= 19 && memEQ(cts, "multipart/form-data", 19)) {
                /* field parts -> the form hash, file parts -> PQ_UPLOADS */
                STRLEN boundl = 0;
                const char *boundary = pq_hdr_param(cts, cl, "boundary", &boundl);
                HV *uploads = newHV();
                built = newHV();
                if (boundary && boundl) {
                    dSP; SV *body; int count;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP); XPUSHs(self); PUTBACK;
                    count = call_method("body", G_SCALAR);
                    SPAGAIN;
                    body = count > 0 ? POPs : &PL_sv_undef;
                    if (SvOK(body)) {
                        STRLEN bl; const char *b = SvPV_const(body, bl);
                        pq_parse_multipart(aTHX_ b, bl, boundary, boundl,
                                           built, uploads);
                    }
                    PUTBACK; FREETMPS; LEAVE;
                }
                (void)pq_cached(aTHX_ req, PQ_UPLOADS, uploads);
            }
            else built = newHV();
            RETVAL = newSVsv(pq_cached(aTHX_ req, PQ_FORM, built));
        }
    }
    OUTPUT:
        RETVAL

# upload($name) -> the Punk::Upload for that field (the first if several);
# uploads -> the { name => upload|[uploads] } hash. Both parse the body once.
SV *
upload(self, name)
        SV *self
        SV *name
    CODE:
    {
        AV *req = punk_req_av(aTHX_ self);
        SV **u;
        STRLEN nl; const char *n = SvPV_const(name, nl);
        SV **got;
        /* ensure the body is parsed (populates PQ_UPLOADS) */
        { dSP; ENTER; SAVETMPS; PUSHMARK(SP); XPUSHs(self); PUTBACK;
          (void)call_method("form", G_SCALAR | G_DISCARD); SPAGAIN;
          PUTBACK; FREETMPS; LEAVE; }
        u = av_fetch(req, PQ_UPLOADS, 0);
        got = (u && *u && SvROK(*u)) ? hv_fetch((HV *)SvRV(*u), n, (I32)nl, 0) : NULL;
        if (got && *got && SvROK(*got) && SvTYPE(SvRV(*got)) == SVt_PVAV) {
            SV **first = av_fetch((AV *)SvRV(*got), 0, 0);   /* first of several */
            RETVAL = (first && *first) ? newSVsv(*first) : &PL_sv_undef;
        }
        else RETVAL = (got && *got) ? newSVsv(*got) : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

SV *
uploads(self)
        SV *self
    CODE:
    {
        AV *req = punk_req_av(aTHX_ self);
        SV **u;
        { dSP; ENTER; SAVETMPS; PUSHMARK(SP); XPUSHs(self); PUTBACK;
          (void)call_method("form", G_SCALAR | G_DISCARD); SPAGAIN;
          PUTBACK; FREETMPS; LEAVE; }
        u = av_fetch(req, PQ_UPLOADS, 0);
        RETVAL = (u && *u && SvROK(*u)) ? newSVsv(*u)
                                        : newRV_noinc((SV *)newHV());
    }
    OUTPUT:
        RETVAL

SV *
param(self, name)
        SV *self
        SV *name
    CODE:
    {
        AV *req = punk_req_av(aTHX_ self);
        HE *he  = NULL;
        SV **c  = av_fetch(req, PQ_QUERY, 0);
        SV *table;
        dSP;
        if (!(c && *c && SvROK(*c))) {
            /* build the query cache through our own accessor */
            PUSHMARK(SP); XPUSHs(self); PUTBACK;
            call_method("query", G_SCALAR);
            SPAGAIN; (void)POPs; PUTBACK;
            c = av_fetch(req, PQ_QUERY, 0);
        }
        table = c && *c ? *c : NULL;
        if (table && SvROK(table))
            he = hv_fetch_ent((HV *)SvRV(table), name, 0, 0);
        if (!he) {
            c = av_fetch(req, PQ_FORM, 0);
            if (!(c && *c && SvROK(*c))) {
                PUSHMARK(SP); XPUSHs(self); PUTBACK;
                call_method("form", G_SCALAR);
                SPAGAIN; (void)POPs; PUTBACK;
                c = av_fetch(req, PQ_FORM, 0);
            }
            table = c && *c ? *c : NULL;
            if (table && SvROK(table))
                he = hv_fetch_ent((HV *)SvRV(table), name, 0, 0);
        }
        RETVAL = he ? newSVsv(HeVAL(he)) : newSV(0);
    }
    OUTPUT:
        RETVAL

SV *
params(self)
        SV *self
    CODE:
    {
        HV *merged = newHV();
        HV *src;
        HE *he;
        SV *table;
        AV *req = punk_req_av(aTHX_ self);
        SV **c;
        int pass;
        dSP;
        /* make both caches exist */
        PUSHMARK(SP); XPUSHs(self); PUTBACK;
        call_method("form", G_SCALAR);
        SPAGAIN; (void)POPs; PUTBACK;
        PUSHMARK(SP); XPUSHs(self); PUTBACK;
        call_method("query", G_SCALAR);
        SPAGAIN; (void)POPs; PUTBACK;
        for (pass = 0; pass < 2; pass++) {
            c = av_fetch(req, pass == 0 ? PQ_FORM : PQ_QUERY, 0);
            table = c && *c ? *c : NULL;
            if (!(table && SvROK(table))) continue;
            src = (HV *)SvRV(table);
            hv_iterinit(src);
            while ((he = hv_iternext(src)))
                (void)hv_store_ent(merged, HeSVKEY_force(he),
                                   newSVsv(HeVAL(he)), 0);
        }
        RETVAL = newRV_noinc((SV *)merged);
    }
    OUTPUT:
        RETVAL

SV *
cookies(self)
        SV *self
    CODE:
    {
        AV *req = punk_req_av(aTHX_ self);
        SV **c  = av_fetch(req, PQ_COOKIES, 0);
        if (c && *c && SvROK(*c))
            RETVAL = newSVsv(*c);
        else {
            HV *env = punk_req_env(aTHX_ req);
            SV **h  = hv_fetchs(env, "HTTP_COOKIE", 0);
            STRLEN hl = 0;
            const char *hs = h && *h && SvOK(*h)
                ? SvPV_const(*h, hl) : "";
            RETVAL = newSVsv(pq_cached(aTHX_ req, PQ_COOKIES,
                pq_parse_cookies(aTHX_ hs, hl)));
        }
    }
    OUTPUT:
        RETVAL

SV *
cookie(self, name)
        SV *self
        SV *name
    CODE:
    {
        AV *req = punk_req_av(aTHX_ self);
        SV **c  = av_fetch(req, PQ_COOKIES, 0);
        HE *he  = NULL;
        dSP;
        if (!(c && *c && SvROK(*c))) {
            PUSHMARK(SP); XPUSHs(self); PUTBACK;
            call_method("cookies", G_SCALAR);
            SPAGAIN; (void)POPs; PUTBACK;
            c = av_fetch(req, PQ_COOKIES, 0);
        }
        if (c && *c && SvROK(*c))
            he = hv_fetch_ent((HV *)SvRV(*c), name, 0, 0);
        RETVAL = he ? newSVsv(HeVAL(he)) : newSV(0);
    }
    OUTPUT:
        RETVAL
