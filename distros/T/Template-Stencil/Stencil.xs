/* mg_findext is 5.14; ask ppport.h (included from stencil.h) to emit its
 * back-compat implementation into this TU, the only one that needs it. */
#define NEED_mg_findext

#include "stencil.h"

/* ====================================================================
 * Object lifecycle: a Template::Stencil object is a blessed hashref of
 * normalised options; the C engine hangs off it via ext magic. The
 * magic free callback releases the engine (no DESTROY needed), and
 * under ithreads the dup callback nulls the pointer so a cloned object
 * lazily rebuilds a fresh engine (with an empty cache) from its own
 * cloned options on first use.
 * ==================================================================== */

static UV stencil_stat_checker = 0;

static int stencil_mg_free(pTHX_ SV *sv, MAGIC *mg)
{
    PERL_UNUSED_ARG(sv);
    if (mg->mg_ptr) {
        stencil_engine_free(aTHX_ (stencil_engine *)mg->mg_ptr);
        mg->mg_ptr = NULL;
    }
    return 0;
}

#ifdef USE_ITHREADS
static int stencil_mg_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param)
{
    PERL_UNUSED_ARG(param);
    mg->mg_ptr = NULL;   /* clone rebuilds its own engine lazily */
    return 0;
}
#endif

static MGVTBL stencil_obj_vtbl = {
    NULL, NULL, NULL, NULL,
    stencil_mg_free,
    NULL,
#ifdef USE_ITHREADS
    stencil_mg_dup,
#else
    NULL,
#endif
    NULL
};

static stencil_engine *stencil_build_engine(pTHX_ HV *o)
{
    SV            **v;
    const char     *dir = NULL, *wrap = NULL;
    uint32_t        flags = 0;
    double          ttl = 1.0;
    UV              csize = 256;
    HV             *filters = NULL;
    stencil_engine *e;

    if ((v = hv_fetchs(o, "template_dir", 0)) && SvOK(*v))
        dir = SvPV_nolen(*v);
    if ((v = hv_fetchs(o, "wrapper", 0)) && SvOK(*v))
        wrap = SvPV_nolen(*v);
    if ((v = hv_fetchs(o, "filters", 0)) && SvROK(*v))
        filters = (HV *)SvRV(*v);
    if ((v = hv_fetchs(o, "strict", 0)) && SvTRUE(*v))
        flags |= STENCIL_RF_STRICT;
    if ((v = hv_fetchs(o, "sort_keys", 0)) && !SvTRUE(*v))
        flags |= STENCIL_RF_NO_SORT_KEYS;
    if ((v = hv_fetchs(o, "auto_escape", 0)) && !SvTRUE(*v))
        flags |= STENCIL_RF_NO_ESCAPE;
    if ((v = hv_fetchs(o, "chars", 0)) && SvTRUE(*v))
        flags |= STENCIL_RF_CHARS;
    if ((v = hv_fetchs(o, "pretty", 0)) && SvTRUE(*v))
        flags |= STENCIL_RF_PRETTY;
    if ((v = hv_fetchs(o, "cache", 0)) && !SvTRUE(*v))
        flags |= STENCIL_EF_NO_CACHE;
    if ((v = hv_fetchs(o, "stat_ttl", 0)) && SvOK(*v))
        ttl = SvNV(*v);
    if ((v = hv_fetchs(o, "cache_size", 0)) && SvOK(*v))
        csize = SvUV(*v);

    e = stencil_engine_new(aTHX_ dir, wrap, flags, ttl, (uint32_t)csize,
                           filters);
    if (!e)
        croak("Template::Stencil: engine allocation failed");
    return e;
}

static stencil_engine *stencil_engine_of(pTHX_ SV *self)
{
    SV    *rv;
    MAGIC *mg;
    if (!SvROK(self) || SvTYPE(rv = SvRV(self)) != SVt_PVHV
        || !sv_derived_from(self, "Template::Stencil"))
        croak("Template::Stencil::render: not a Template::Stencil "
              "object");
    mg = mg_findext(rv, PERL_MAGIC_ext, &stencil_obj_vtbl);
    if (!mg)
        croak("Template::Stencil::render: object has no engine magic");
    if (!mg->mg_ptr)
        mg->mg_ptr = (char *)stencil_build_engine(aTHX_ (HV *)rv);
    return (stencil_engine *)mg->mg_ptr;
}

static SV *stencil_obj_render(pTHX_ SV *self, SV *tmpl, SV *data,
                              SV *opts)
{
    stencil_engine *e = stencil_engine_of(aTHX_ self);
    HV             *dhv;
    SV             *err = NULL;
    SV             *out;

    if (!data || !SvOK(data))
        dhv = (HV *)sv_2mortal((SV *)newHV());
    else if (SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV)
        dhv = (HV *)SvRV(data);
    else
        croak("Template::Stencil::render: data must be a hashref");
    out = stencil_engine_render(aTHX_ e, tmpl, dhv, opts, &err);
    if (!out)
        croak_sv(err);
    return out;
}

#ifdef STENCIL_HAVE_CALL_CHECKER
/* Fast path installed by the call checker for statically resolved
 * calls: the entersub's op_ppaddr is swapped for this pp, which reads
 * the args directly (the trailing stack item is the CV, skipped) and
 * calls the render core without XS prologue overhead. */
static OP *stencil_pp_render(pTHX)
{
    dSP;
    dMARK;
    SSize_t n    = SP - MARK - 1;   /* last item is the CV */
    SV    **args = MARK + 1;
    SV     *out;
    stencil_stat_checker++;
    if (n < 2 || n > 4)
        croak("Usage: $stencil->render($template, \\%%data, \\%%opts)");
    out = stencil_obj_render(aTHX_ args[0], args[1],
                             n >= 3 ? args[2] : NULL,
                             n >= 4 ? args[3] : NULL);
    SP = MARK;
    XPUSHs(sv_2mortal(out));
    RETURN;
}

static OP *stencil_render_checker(pTHX_ OP *entersubop, GV *namegv,
                                  SV *ckobj)
{
    PERL_UNUSED_ARG(namegv);
    PERL_UNUSED_ARG(ckobj);
    entersubop = ck_entersub_args_list(entersubop);
    entersubop->op_ppaddr = stencil_pp_render;
    return entersubop;
}
#endif /* STENCIL_HAVE_CALL_CHECKER */

/* The shared C ABI, after the object magic and the engine builder it wraps. */
#include "st_abi_impl.h"

MODULE = Template::Stencil    PACKAGE = Template::Stencil

PROTOTYPES: DISABLE

BOOT:
    stencil_boot(aTHX);
#ifdef STENCIL_HAVE_CALL_CHECKER
    {
        CV *rcv = get_cv("Template::Stencil::render", 0);
        if (rcv)
            cv_set_call_checker(rcv, stencil_render_checker,
                                (SV *)rcv);
    }
#endif

UV
_stencil_built()
    CODE:
        RETVAL = (UV)stencil_dispatch.caps;
    OUTPUT:
        RETVAL

SV *
new(class, ...)
        SV *class
    CODE:
    {
        const char *cls = (SvROK(class) && SvOBJECT(SvRV(class)))
                        ? HvNAME(SvSTASH(SvRV(class)))
                        : SvPV_nolen(class);
        HV      *o = newHV();
        AV      *pairs = newAV();
        SSize_t  np, i;
        stencil_engine *e;
        MAGIC   *mg;

        sv_2mortal((SV *)o);
        sv_2mortal((SV *)pairs);
        if (items == 2 && SvROK(ST(1))
            && SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
            HV *src = (HV *)SvRV(ST(1));
            HE *he;
            hv_iterinit(src);
            while ((he = hv_iternext(src))) {
                STRLEN klen;
                const char *k = HePV(he, klen);
                av_push(pairs, newSVpvn(k, klen));
                av_push(pairs, SvREFCNT_inc(HeVAL(he)));
            }
        } else {
            if (!(items % 2))
                croak("Template::Stencil->new: odd number of options");
            for (i = 1; i < items; i++)
                av_push(pairs, SvREFCNT_inc(ST(i)));
        }

        np = av_top_index(pairs) + 1;
        for (i = 0; i + 1 < np; i += 2) {
            STRLEN      klen;
            const char *k = SvPV(*av_fetch(pairs, i, 0), klen);
            SV         *v = *av_fetch(pairs, i + 1, 0);
            if (klen == 12 && memEQ(k, "template_dir", 12)) {
                if (SvOK(v)) {
                    Stat_t st;
                    if (stat(SvPV_nolen(v), &st) != 0
                        || !S_ISDIR(st.st_mode))
                        croak("Template::Stencil->new: template_dir "
                              "'%s' is not a directory",
                              SvPV_nolen(v));
                    (void)hv_stores(o, "template_dir", newSVsv(v));
                }
            } else if (klen == 7 && memEQ(k, "wrapper", 7)) {
                if (SvOK(v))
                    (void)hv_stores(o, "wrapper", newSVsv(v));
            } else if (klen == 7 && memEQ(k, "filters", 7)) {
                HE *fe;
                HV *fh;
                if (!SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVHV)
                    croak("Template::Stencil->new: filters must be a "
                          "hashref");
                fh = (HV *)SvRV(v);
                hv_iterinit(fh);
                while ((fe = hv_iternext(fh))) {
                    SV *fv = HeVAL(fe);
                    if (!SvROK(fv) || SvTYPE(SvRV(fv)) != SVt_PVCV) {
                        STRLEN fklen;
                        const char *fk = HePV(fe, fklen);
                        croak("Template::Stencil->new: filter '%.*s' "
                              "is not a coderef", (int)fklen, fk);
                    }
                }
                (void)hv_stores(o, "filters", newSVsv(v));
            } else if ((klen == 11 && memEQ(k, "auto_escape", 11))
                    || (klen == 6  && memEQ(k, "strict", 6))
                    || (klen == 5  && memEQ(k, "cache", 5))
                    || (klen == 5  && memEQ(k, "chars", 5))
                    || (klen == 6  && memEQ(k, "pretty", 6))
                    || (klen == 9  && memEQ(k, "sort_keys", 9))) {
                (void)hv_store(o, k, (I32)klen,
                               newSViv(SvTRUE(v) ? 1 : 0), 0);
            } else if (klen == 8 && memEQ(k, "stat_ttl", 8)) {
                if (!SvOK(v) || !looks_like_number(v))
                    croak("Template::Stencil->new: stat_ttl must be a "
                          "number");
                (void)hv_stores(o, "stat_ttl", newSVnv(SvNV(v)));
            } else if (klen == 10 && memEQ(k, "cache_size", 10)) {
                if (!SvOK(v) || !looks_like_number(v) || SvNV(v) < 1)
                    croak("Template::Stencil->new: cache_size must be "
                          "a positive integer");
                (void)hv_stores(o, "cache_size", newSVuv(SvUV(v)));
            } else {
                croak("Template::Stencil->new: unknown option '%.*s'",
                      (int)klen, k);
            }
        }

        /* defaults, stored so a thread-cloned object can rebuild */
        if (!hv_fetchs(o, "auto_escape", 0))
            (void)hv_stores(o, "auto_escape", newSViv(1));
        if (!hv_fetchs(o, "strict", 0))
            (void)hv_stores(o, "strict", newSViv(0));
        if (!hv_fetchs(o, "cache", 0))
            (void)hv_stores(o, "cache", newSViv(1));
        if (!hv_fetchs(o, "sort_keys", 0))
            (void)hv_stores(o, "sort_keys", newSViv(1));
        if (!hv_fetchs(o, "chars", 0))
            (void)hv_stores(o, "chars", newSViv(0));
        if (!hv_fetchs(o, "pretty", 0))
            (void)hv_stores(o, "pretty", newSViv(0));
        if (!hv_fetchs(o, "stat_ttl", 0))
            (void)hv_stores(o, "stat_ttl", newSVnv(1.0));
        if (!hv_fetchs(o, "cache_size", 0))
            (void)hv_stores(o, "cache_size", newSVuv(256));

        e  = stencil_build_engine(aTHX_ o);
        mg = sv_magicext((SV *)o, NULL, PERL_MAGIC_ext,
                         &stencil_obj_vtbl, (char *)e, 0);
#ifdef USE_ITHREADS
        mg->mg_flags |= MGf_DUP;
#else
        PERL_UNUSED_VAR(mg);
#endif
        RETVAL = sv_bless(newRV_inc((SV *)o),
                          gv_stashpv(cls, GV_ADD));
    }
    OUTPUT:
        RETVAL

SV *
render(self, tmpl, ...)
        SV *self
        SV *tmpl
    CODE:
        RETVAL = stencil_obj_render(aTHX_ self, tmpl,
                                    items > 2 ? ST(2) : NULL,
                                    items > 3 ? ST(3) : NULL);
    OUTPUT:
        RETVAL

SV *
_arena_selftest()
    CODE:
    {
        const char *err = stencil_arena_selftest();
        RETVAL = err ? newSVpv(err, 0) : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

SV *
_escape(sv)
        SV *sv
    CODE:
    {
        STRLEN      len;
        const char *p = SvPV_const(sv, len);
        stencil_buf b;
        stencil_buf_init(aTHX_ &b, len + 16);
        stencil_dispatch.escape(&b, p, len);
        if (SvUTF8(sv))
            b.utf8 = 1;
        RETVAL = stencil_buf_done(&b);
    }
    OUTPUT:
        RETVAL

SV *
_escape_off(sv, off)
        SV *sv
        UV  off
    CODE:
    {
        STRLEN      len;
        const char *p = SvPV_const(sv, len);
        stencil_buf b;
        if (off > len)
            croak("_escape_off: offset %" UVuf " past end", off);
        stencil_buf_init(aTHX_ &b, len - off + 16);
        stencil_dispatch.escape(&b, p + off, len - off);
        if (SvUTF8(sv))
            b.utf8 = 1;
        RETVAL = stencil_buf_done(&b);
    }
    OUTPUT:
        RETVAL

SV *
_inspect(src)
        SV *src
    CODE:
    {
        STRLEN      len;
        const char *p = SvPV_const(src, len);
        SV         *err = NULL;
        stencil_program *prog =
            stencil_compile(aTHX_ p, len, "<string>",
                            SvUTF8(src) ? STENCIL_PROG_SRC_UTF8 : 0,
                            &err);
        if (!prog)
            croak_sv(err);
        RETVAL = stencil_program_inspect(aTHX_ prog);
        stencil_program_free(prog);
    }
    OUTPUT:
        RETVAL

SV *
_render(src, data, ...)
        SV *src
        SV *data
    CODE:
    {
        STRLEN      len;
        const char *p = SvPV_const(src, len);
        SV         *err = NULL;
        UV          flags = items > 2 ? SvUV(ST(2)) : 0;
        SV         *out;
        stencil_program *prog;
        if (!SvROK(data) || SvTYPE(SvRV(data)) != SVt_PVHV)
            croak("Template::Stencil: render data must be a hashref");
        prog = stencil_compile(aTHX_ p, len, "<string>",
                               SvUTF8(src) ? STENCIL_PROG_SRC_UTF8 : 0,
                               &err);
        if (!prog)
            croak_sv(err);
        out = stencil_render_run(aTHX_ prog, (HV *)SvRV(data),
                                 (uint32_t)flags, "<string>", &err);
        stencil_program_free(prog);
        if (!out)
            croak_sv(err);
        RETVAL = out;
    }
    OUTPUT:
        RETVAL

IV
_compile_handle(src)
        SV *src
    CODE:
    {
        STRLEN      len;
        const char *p = SvPV_const(src, len);
        SV         *err = NULL;
        stencil_program *prog =
            stencil_compile(aTHX_ p, len, "<string>",
                            SvUTF8(src) ? STENCIL_PROG_SRC_UTF8 : 0,
                            &err);
        if (!prog)
            croak_sv(err);
        RETVAL = PTR2IV(prog);
    }
    OUTPUT:
        RETVAL

SV *
_run_handle(handle, data, ...)
        IV  handle
        SV *data
    CODE:
    {
        stencil_program *prog = INT2PTR(stencil_program *, handle);
        SV *err = NULL;
        UV  flags = items > 2 ? SvUV(ST(2)) : 0;
        SV *out;
        if (!SvROK(data) || SvTYPE(SvRV(data)) != SVt_PVHV)
            croak("Template::Stencil: render data must be a hashref");
        out = stencil_render_run(aTHX_ prog, (HV *)SvRV(data),
                                 (uint32_t)flags, "<string>", &err);
        if (!out)
            croak_sv(err);
        RETVAL = out;
    }
    OUTPUT:
        RETVAL

void
_free_handle(handle)
        IV handle
    CODE:
        stencil_program_free(INT2PTR(stencil_program *, handle));

SV *
_stencil_stats()
    CODE:
    {
        HV *hv = newHV();
        (void)hv_stores(hv, "buf_grows", newSVuv(stencil_stat_buf_grows));
        (void)hv_stores(hv, "scratch_allocs",
                        newSVuv(stencil_stat_scratch_allocs));
        (void)hv_stores(hv, "compiles", newSVuv(stencil_stat_compiles));
        (void)hv_stores(hv, "cache_hits",
                        newSVuv(stencil_stat_cache_hits));
        (void)hv_stores(hv, "stats", newSVuv(stencil_stat_stats));
        (void)hv_stores(hv, "checker", newSVuv(stencil_stat_checker));
        (void)hv_stores(hv, "engines", newSVuv(stencil_stat_engines));
        RETVAL = newRV_noinc((SV *)hv);
    }
    OUTPUT:
        RETVAL

IV
_engine_new(template_dir, wrapper, flags, stat_ttl, cache_size, ...)
        SV *template_dir
        SV *wrapper
        UV  flags
        NV  stat_ttl
        UV  cache_size
    CODE:
    {
        HV *filters = NULL;
        stencil_engine *e;
        if (items > 5 && SvOK(ST(5))) {
            HE *he;
            if (!SvROK(ST(5)) || SvTYPE(SvRV(ST(5))) != SVt_PVHV)
                croak("Template::Stencil: filters must be a hashref");
            filters = (HV *)SvRV(ST(5));
            hv_iterinit(filters);
            while ((he = hv_iternext(filters))) {
                SV *v = HeVAL(he);
                if (!SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVCV) {
                    STRLEN klen;
                    const char *k = HePV(he, klen);
                    croak("Template::Stencil: filter '%.*s' is not a "
                          "coderef", (int)klen, k);
                }
            }
        }
        e = stencil_engine_new(aTHX_
            SvOK(template_dir) ? SvPV_nolen(template_dir) : NULL,
            SvOK(wrapper)      ? SvPV_nolen(wrapper)      : NULL,
            (uint32_t)flags, (double)stat_ttl, (uint32_t)cache_size,
            filters);
        if (!e)
            croak("Template::Stencil: engine allocation failed");
        RETVAL = PTR2IV(e);
    }
    OUTPUT:
        RETVAL

void
_engine_free(handle)
        IV handle
    CODE:
        stencil_engine_free(aTHX_ INT2PTR(stencil_engine *, handle));

SV *
_engine_render(handle, tmpl, data, ...)
        IV  handle
        SV *tmpl
        SV *data
    CODE:
    {
        stencil_engine *e = INT2PTR(stencil_engine *, handle);
        SV *opts = items > 3 ? ST(3) : NULL;
        SV *err  = NULL;
        SV *out;
        if (!SvROK(data) || SvTYPE(SvRV(data)) != SVt_PVHV)
            croak("Template::Stencil: render data must be a hashref");
        out = stencil_engine_render(aTHX_ e, tmpl, (HV *)SvRV(data),
                                    opts, &err);
        if (!out)
            croak_sv(err);
        RETVAL = out;
    }
    OUTPUT:
        RETVAL

UV
_perl_hash(sv)
        SV *sv
    CODE:
    {
        STRLEN      len;
        const char *p = SvPV_const(sv, len);
        U32         hash;
        PERL_HASH(hash, p, len);
        RETVAL = (UV)hash;
    }
    OUTPUT:
        RETVAL

SV *
_buf_selftest()
    CODE:
    {
        stencil_buf b;
        int         i;
        stencil_buf_init(aTHX_ &b, 4);
        for (i = 0; i < 1000; i++)
            stencil_buf_write(&b, "abc", 3);
        stencil_buf_write8(&b, "12345678", 4);
        RETVAL = stencil_buf_done(&b);
    }
    OUTPUT:
        RETVAL

# Address of Template::Stencil's own C ABI table (st_abi.h). A consumer XS
# module (Punk's view tier) fetches this once at boot, INT2PTRs it to a
# `const st_abi *`, and checks ->abi_version before using it. Not part of the
# public Perl API.
IV
_abi_ptr()
    CODE:
        RETVAL = PTR2IV(&ST_ABI);
    OUTPUT:
        RETVAL

# Exercise the whole st_abi table the way a C consumer would: resolve it from
# the IV _abi_ptr hands back, gate on abi_version, then drive engine_of ->
# render through the function pointers rather than calling the C directly.
# Returns the rendered bytes; (undef, $error) when the template fails; and an
# empty list when the gate rejects the table or the invocant is not a Stencil
# object - which is where a consumer would fall back to the render method.
void
_abi_selftest(self, tmpl, data = &PL_sv_undef, opts = &PL_sv_undef)
        SV *self
        SV *tmpl
        SV *data
        SV *opts
    PPCODE:
    {
        const st_abi *abi = NULL;
        void         *engine;
        SV           *err = NULL, *out;
        HV           *dhv;
        {
            dSP;
            IV  ptr   = 0;
            int count;
            ENTER; SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;
            count = call_pv("Template::Stencil::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (count > 0) {
                /* Pop into a local first: before 5.30 SvIV was a macro that
                 * evaluated its argument twice (SvIOK(sv) ? SvIVX(sv) :
                 * sv_2iv(sv)), so SvIV(POPs) popped twice and read the IV
                 * off whatever sat one slot lower. Modern perls make it an
                 * inline function, which is why this only ever bit on old
                 * ones. */
                SV *rv = POPs;
                if (!SvTRUE(ERRSV)) ptr = SvIV(rv);
            }
            PUTBACK; FREETMPS; LEAVE;
            if (ptr) abi = INT2PTR(const st_abi *, ptr);
        }
        if (!abi || abi->abi_version < ST_ABI_VERSION) XSRETURN_EMPTY;
        engine = abi->engine_of(aTHX_ self);
        if (!engine) XSRETURN_EMPTY;
        dhv = (data && SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV)
            ? (HV *)SvRV(data) : NULL;
        out = abi->render(aTHX_ engine, tmpl, dhv,
                          (opts && SvOK(opts)) ? opts : NULL, &err);
        if (!out) {
            EXTEND(SP, 2);
            mPUSHs(newSV(0));
            PUSHs(err ? err : sv_2mortal(newSVpvs("unknown render error")));
            XSRETURN(2);
        }
        EXTEND(SP, 1);
        mPUSHs(out);
        XSRETURN(1);
    }
