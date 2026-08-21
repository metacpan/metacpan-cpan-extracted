MODULE = Punk::OpenTelemetry    PACKAGE = Punk::OpenTelemetry::Schema

PROTOTYPES: DISABLE

# The converter. Loading a schema file stays in Perl - it is a YAML parse and
# a directory search, done once, and neither is a hot path - but converting a
# payload walks every attribute hash in it, so that half is C.

# Semantic version comparison. Exposed because it is the thing most easily got
# wrong and most cheaply asserted: "1.10.0" against "1.9.0" as strings puts
# them the wrong way round.
IV
_vcmp(a, b)
        SV *a
        SV *b
    CODE:
        RETVAL = (IV)otel_schema_vcmp(aTHX_ a, b);
    OUTPUT:
        RETVAL

# The version at the end of a schema URL, or undef.
SV *
_url_version(url)
        SV *url
    CODE:
    {
        SV *v = otel_schema_url_version(aTHX_ url);
        if (!v) XSRETURN_UNDEF;
        RETVAL = newSVsv(v);
    }
    OUTPUT:
        RETVAL

# The keys of a versions hash, in semantic order.
SV *
_order(versions)
        SV *versions
    CODE:
    {
        HV *v = otel_hv_of(aTHX_ versions);
        AV *out = newAV();
        HE *he;
        if (v) {
            hv_iterinit(v);
            while ((he = hv_iternext(v)))
                av_push(out, newSVsv(hv_iterkeysv(he)));
            sortsv(AvARRAY(out), (SSize_t)(av_len(out) + 1),
                   otel_schema_sortcmp);
        }
        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL

# convert($self, $payload, from => $v, to => $v, signal => $s)
#
# The payload is modified IN PLACE and returned, so a caller can convert a
# batch on its way to the exporter without copying it.
SV *
convert(self, payload, ...)
        SV *self
        SV *payload
    CODE:
    {
        HV *sh = otel_hv_of(aTHX_ self);
        HV *pl = otel_hv_of(aTHX_ payload);
        SV *from = NULL, *to = NULL;
        const char *signal = "spans";
        STRLEN siglen = 5;
        AV *order, *steps;
        int dir = 0, forward, i, n;

        if (!sh) croak("convert: not a schema object");
        for (i = 2; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            if      (strEQ(k, "from")) from = ST(i + 1);
            else if (strEQ(k, "to"))   to   = ST(i + 1);
            else if (strEQ(k, "signal") && SvOK(ST(i + 1)))
                signal = SvPV(ST(i + 1), siglen);
        }
        if (!(from && SvOK(from))) croak("convert: need from");
        if (!(to   && SvOK(to)))   croak("convert: need to");

        /* A schema file lists the versions at which something CHANGED, not
         * every version that ever existed, so a `from` below the lowest entry
         * is the ordinary case - it means "produced before any of these
         * changes" and the answer is to apply all of them.
         *
         * What the file genuinely cannot answer for is a version ABOVE its
         * own: it records changes up to its schema_url and knows nothing
         * beyond. That is an error the caller has to handle rather than a
         * silent no-op, because returning unconverted telemetry quietly is
         * indistinguishable from converting it correctly. */
        order = otel_h_av(aTHX_ sh, "order");
        if (order && av_len(order) >= 0) {
            SV **tp = av_fetch(order, av_len(order), 0);
            if (tp && *tp) {
                int j;
                for (j = 0; j < 2; j++) {
                    SV *v = j ? to : from;
                    if (otel_schema_vcmp(aTHX_ v, *tp) > 0)
                        croak("Punk::OpenTelemetry::Schema: this file "
                              "describes changes up to %" SVf " and cannot "
                              "convert %" SVf "\n", SVfARG(*tp), SVfARG(v));
                }
            }
        }

        if (!pl) { RETVAL = newSVsv(payload); XSRETURN(1); }

        steps = otel_schema_walk(aTHX_ sh, from, to, &dir);
        forward = dir > 0;
        n = (int)(av_len(steps) + 1);
        for (i = 0; i < n; i++) {
            SV **sp = av_fetch(steps, i, 0);
            HV *map;
            if (!(sp && *sp)) continue;
            map = otel_schema_renames(aTHX_ sh, *sp, signal, siglen);
            if (!HvUSEDKEYS(map)) continue;
            otel_schema_each_attrs(aTHX_ pl, signal, siglen, map, forward);
            if (siglen == 7 && memEQ(signal, "metrics", 7))
                otel_schema_each_metric(aTHX_ pl, map, forward);
        }
        RETVAL = newSVsv(payload);
    }
    OUTPUT:
        RETVAL

# ---- sourcing a schema file ----------------------------------------------

# _parse_yaml($text): the document, through whichever YAML parser is present,
# fastest first. WHICH parser is a runtime question and not a build one: the
# feature is opt-in and most deployments never touch it, so a hard dependency
# would tax everyone for the few. There is no C YAML parser to reach for -
# File::Raw::YAML publishes no ABI - so this is a call by name, as the
# exporter calls HTTP::Date.
SV *
_parse_yaml(text)
        SV *text
    CODE:
    {
        static const char *const REQS[3] = { "require YAML::XS; 1",
                                             "require YAML::PP; 1",
                                             "require YAML; 1" };
        SV *out = NULL;
        int i;
        for (i = 0; i < 3 && !out; i++) {
            dSP; int count;
            eval_pv(REQS[i], FALSE);
            SPAGAIN;
            if (SvTRUE(ERRSV)) continue;
            ENTER; SAVETMPS;
            if (i == 1) {                  /* YAML::PP->new->load_string($t) */
                SV *pp = NULL;
                PUSHMARK(SP); EXTEND(SP, 1);
                PUSHs(sv_2mortal(newSVpvs("YAML::PP")));
                PUTBACK;
                count = call_method("new", G_SCALAR | G_EVAL);
                SPAGAIN;
                if (!SvTRUE(ERRSV) && count > 0) pp = SvREFCNT_inc(POPs);
                else if (count > 0) (void)POPs;
                PUTBACK;
                if (pp) {
                    sv_2mortal(pp);
                    PUSHMARK(SP); EXTEND(SP, 2);
                    PUSHs(pp); PUSHs(text);
                    PUTBACK;
                    count = call_method("load_string", G_SCALAR | G_EVAL);
                    SPAGAIN;
                    if (!SvTRUE(ERRSV) && count > 0) {
                        SV *r = POPs;
                        if (SvTRUE(r)) out = newSVsv(r);
                    }
                    else if (count > 0) (void)POPs;
                    PUTBACK;
                }
            }
            else {
                const char *fn = i ? "YAML::Load" : "YAML::XS::Load";
                PUSHMARK(SP); EXTEND(SP, 1);
                PUSHs(text);
                PUTBACK;
                count = call_pv(fn, G_SCALAR | G_EVAL);
                SPAGAIN;
                if (!SvTRUE(ERRSV) && count > 0) {
                    SV *r = POPs;
                    if (SvTRUE(r)) out = newSVsv(r);
                }
                else if (count > 0) (void)POPs;
                PUTBACK;
            }
            FREETMPS; LEAVE;
        }
        if (!out)
            croak("Punk::OpenTelemetry::Schema: no usable YAML parser found "
                  "(File::Raw::YAML, YAML::XS, YAML::PP or YAML)\n");
        RETVAL = out;
    }
    OUTPUT:
        RETVAL

# _dirs(%opt): where a schema file may be found, in order.
#
# Nothing here is a network location and nothing here is a fallback TO one: a
# file is either on disk or it is not.
#
#   1. a directory the caller passes
#   2. $ENV{OTEL_SCHEMA_DIR}, for an operator carrying versions this release
#      predates - the whole reason a search path exists rather than only the
#      shipped file
#   3. the directory shipped beside this module, found through %INC rather
#      than guessed, so it is right under blib, under a local::lib and
#      installed
void
_dirs(...)
    PPCODE:
    {
        AV *out = (AV *)sv_2mortal((SV *)newAV());
        SSize_t i, n;
        int a;
        for (a = 0; a + 1 < items; a += 2) {
            STRLEN kl;
            const char *k = SvPV_const(ST(a), kl);
            if (kl == 3 && memEQ(k, "dir", 3) && SvOK(ST(a + 1)))
                av_push(out, newSVsv(ST(a + 1)));
        }
        {
            SV **e = hv_fetchs(GvHV(PL_envgv), "OTEL_SCHEMA_DIR", 0);
            if (e && *e && SvOK(*e)) av_push(out, newSVsv(*e));
        }
        {
            HV *inc = GvHV(PL_incgv);
            SV **e = inc ? hv_fetchs(inc, "Punk/OpenTelemetry/Schema.pm", 0)
                         : NULL;
            if (e && *e && SvOK(*e)) {
                STRLEN l;
                const char *p = SvPV_const(*e, l);
                if (l > 3 && memEQ(p + l - 3, ".pm", 3))
                    av_push(out, newSVpvn(p, l - 3));
            }
        }
        n = av_len(out) + 1;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(out, i, 0);
            if (e && *e && SvOK(*e) && SvCUR(*e))
                PUSHs(sv_2mortal(newSVsv(*e)));
        }
    }

# file_for($class, $version, %opt): the file for a version, or undef.
#
# Undef is an ordinary answer, not an error: an unknown schema URL means the
# telemetry passes through unchanged, which is correct and is the only thing
# that does not involve reaching out to a third party from the request path.
SV *
file_for(class, version, ...)
        SV *class
        SV *version
    CODE:
    {
        AV *dirs;
        SSize_t di, dn;
        SV *found = NULL;
        PERL_UNUSED_VAR(class);
        if (!SvOK(version)) XSRETURN_UNDEF;
        {   /* \A[0-9][0-9.]*\z - a version, and nothing that could climb out
             * of the directory it is about to be joined to */
            STRLEN l, j;
            const char *p = SvPV_const(version, l);
            if (!l || !isDIGIT(p[0])) XSRETURN_UNDEF;
            for (j = 0; j < l; j++)
                if (!isDIGIT(p[j]) && p[j] != '.') XSRETURN_UNDEF;
        }
        dirs = otel_schema_dirs(aTHX_ &ST(2), items - 2);
        dn = av_len(dirs) + 1;
        for (di = 0; di < dn; di++) {
            SV **d = av_fetch(dirs, di, 0);
            SV *path;
            Stat_t st;
            if (!(d && *d && SvOK(*d))) continue;
            path = sv_2mortal(newSVsv(*d));
            sv_catpvs(path, "/");
            sv_catsv(path, version);
            sv_catpvs(path, ".yaml");
            if (PerlLIO_stat(SvPV_nolen(path), &st) == 0
                && S_ISREG(st.st_mode)) {
                found = path;
                break;
            }
        }
        /* Nothing on the path is an ORDINARY answer, and it has to return
         * here rather than fall through: RETVAL is uninitialised until
         * something is found, and handing the typemap a stack pointer is
         * how a missing schema file becomes a crash. */
        if (!found) XSRETURN_UNDEF;
        RETVAL = newSVsv(found);
    }
    OUTPUT:
        RETVAL

# shipped_version(): the semantic convention version this distribution emits,
# which is also the version of the file it ships. DERIVED from the C pin
# (OTEL_SCHEMA_URL in otel_semconv.h) rather than written down twice, so it
# cannot drift from what the encoder puts on the wire.
SV *
shipped_version(class = &PL_sv_undef)
        SV *class
    CODE:
    {
        SV *url = sv_2mortal(newSVpvs(OTEL_SCHEMA_URL));
        SV *v;
        PERL_UNUSED_VAR(class);
        v = otel_schema_url_version(aTHX_ url);
        if (!v) XSRETURN_UNDEF;
        RETVAL = newSVsv(v);
    }
    OUTPUT:
        RETVAL

# load($class, text => ... | path => ... | version => ...)
#
# With no source at all: the shipped file for the version this dist emits,
# which is what a caller almost always means.
SV *
load(class, ...)
        SV *class
    CODE:
    {
        SV *text = NULL, *path = NULL, *version = NULL;
        SV *doc, *self;
        HV *d, *versions;
        int a;
        for (a = 1; a + 1 < items; a += 2) {
            STRLEN kl;
            const char *k = SvPV_const(ST(a), kl);
            if      (kl == 4 && memEQ(k, "text", 4))    text    = ST(a + 1);
            else if (kl == 4 && memEQ(k, "path", 4))    path    = ST(a + 1);
            else if (kl == 7 && memEQ(k, "version", 7)) version = ST(a + 1);
        }
        if (!(text && SvOK(text))) text = NULL;
        if (!(path && SvOK(path))) path = NULL;

        if (!text && !path) {
            SV *v = (version && SvOK(version))
                  ? sv_2mortal(newSVsv(version))
                  : otel_schema_url_version(aTHX_
                        sv_2mortal(newSVpvs(OTEL_SCHEMA_URL)));
            path = otel_schema_file_for(aTHX_ v, &ST(1), items - 1);
            if (!path) {
                AV *dirs = otel_schema_dirs(aTHX_ &ST(1), items - 1);
                SV *joined = sv_2mortal(newSVpvs(""));
                SSize_t i, n = av_len(dirs) + 1;
                for (i = 0; i < n; i++) {
                    SV **e = av_fetch(dirs, i, 0);
                    if (i) sv_catpvs(joined, ", ");
                    if (e && *e) sv_catsv(joined, *e);
                }
                croak("Punk::OpenTelemetry::Schema->load: no schema file for "
                      "%" SVf " in %" SVf "\n",
                      SVfARG(v ? v : sv_2mortal(newSVpvs("(unknown version)"))),
                      SVfARG(joined));
            }
        }

        if (!text) {
            PerlIO *fh;
            SV *buf;
            char chunk[8192];
            SSize_t got;
            fh = PerlIO_open(SvPV_nolen(path), "r");
            if (!fh)
                croak("Punk::OpenTelemetry::Schema->load: %" SVf ": %s\n",
                      SVfARG(path), Strerror(errno));
            buf = sv_2mortal(newSVpvs(""));
            while ((got = PerlIO_read(fh, chunk, sizeof chunk)) > 0)
                sv_catpvn(buf, chunk, (STRLEN)got);
            PerlIO_close(fh);
            text = buf;
        }

        {   /* the parse is the one call out; everything either side is here */
            dSP; int count;
            doc = NULL;
            ENTER; SAVETMPS;
            PUSHMARK(SP); EXTEND(SP, 1); PUSHs(text); PUTBACK;
            count = call_pv("Punk::OpenTelemetry::Schema::_parse_yaml",
                            G_SCALAR);
            SPAGAIN;
            if (count > 0) doc = SvREFCNT_inc(POPs);
            PUTBACK; FREETMPS; LEAVE;
        }
        if (doc) sv_2mortal(doc);
        d = doc ? otel_hv_of(aTHX_ doc) : NULL;
        versions = d ? otel_h_hv(aTHX_ d, "versions") : NULL;
        if (!versions)
            croak("Punk::OpenTelemetry::Schema: not a schema file "
                  "(no 'versions')\n");

        {
            HV *h = newHV();
            AV *order = newAV();
            HE *he;
            SV *u = otel_h(aTHX_ d, "schema_url");
            SV *ff = otel_h(aTHX_ d, "file_format");
            const char *cls = (SvROK(class) && SvOBJECT(SvRV(class)))
                            ? HvNAME(SvSTASH(SvRV(class))) : SvPV_nolen(class);
            (void)hv_stores(h, "schema_url",  u  ? newSVsv(u)  : newSV(0));
            (void)hv_stores(h, "file_format", ff ? newSVsv(ff) : newSV(0));
            (void)hv_stores(h, "versions", newSVsv(*hv_fetchs(d, "versions", 0)));
            hv_iterinit(versions);
            while ((he = hv_iternext(versions)))
                av_push(order, newSVsv(hv_iterkeysv(he)));
            /* semantic order, not string order: the steps are applied one at
             * a time, so the order IS the behaviour */
            if (av_len(order) > 0)
                sortsv(AvARRAY(order), (STRLEN)(av_len(order) + 1),
                       otel_schema_sortcmp);
            (void)hv_stores(h, "order", newRV_noinc((SV *)order));
            self = sv_bless(newRV_noinc((SV *)h), gv_stashpv(cls, GV_ADD));
        }
        RETVAL = self;
    }
    OUTPUT:
        RETVAL

# for_url($class, $url, %opt): load by schema URL, or undef when nothing local
# describes it - an ordinary answer, not a failure.
SV *
for_url(class, url, ...)
        SV *class
        SV *url
    CODE:
    {
        SV *v = otel_schema_url_version(aTHX_ url);
        SV *f = v ? otel_schema_file_for(aTHX_ v, &ST(2), items - 2) : NULL;
        if (!f) XSRETURN_UNDEF;
        {
            dSP; int count; SV *obj = NULL;
            ENTER; SAVETMPS;
            PUSHMARK(SP); EXTEND(SP, 3);
            PUSHs(class);
            PUSHs(sv_2mortal(newSVpvs("path")));
            PUSHs(f);
            PUTBACK;
            count = call_pv("Punk::OpenTelemetry::Schema::load", G_SCALAR);
            SPAGAIN;
            if (count > 0) obj = SvREFCNT_inc(POPs);
            PUTBACK; FREETMPS; LEAVE;
            if (obj) RETVAL = obj;
        }
    }
    OUTPUT:
        RETVAL

# ---- the loaded object ----------------------------------------------------

SV *
schema_url(self)
        SV *self
    CODE:
    {
        HV *h = otel_hv_of(aTHX_ self);
        SV *u = h ? otel_h(aTHX_ h, "schema_url") : NULL;
        if (!u) XSRETURN_UNDEF;
        RETVAL = newSVsv(u);
    }
    OUTPUT:
        RETVAL

void
versions(self)
        SV *self
    PPCODE:
    {
        HV *h = otel_hv_of(aTHX_ self);
        AV *order = h ? otel_h_av(aTHX_ h, "order") : NULL;
        SSize_t i, n = order ? av_len(order) + 1 : 0;
        /* This was `@{ $_[0]{order} }`, and an array in scalar context is its
         * COUNT. A list-returning XSUB in scalar context yields its LAST
         * value instead, so scalar($s->versions) would quietly become a
         * version string - true-ish, wrong, and only visible to something
         * that compared it. */
        if (GIMME_V == G_SCALAR) {
            EXTEND(SP, 1);
            mPUSHi((IV)n);
            XSRETURN(1);
        }
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(order, i, 0);
            PUSHs(sv_2mortal(newSVsv((e && *e) ? *e : &PL_sv_undef)));
        }
    }

IV
knows(self, v)
        SV *self
        SV *v
    CODE:
    {
        HV *h = otel_hv_of(aTHX_ self);
        HV *versions = h ? otel_h_hv(aTHX_ h, "versions") : NULL;
        RETVAL = (versions && SvOK(v) && hv_exists_ent(versions, v, 0)) ? 1 : 0;
    }
    OUTPUT:
        RETVAL
