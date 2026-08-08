/* punk_import.h - `use Punk` and the DSL it exports, in C.
 *
 * Every keyword is a magic CV carrying the application registrar it forwards
 * to (the punk_closure pattern from punk_static.h, the same one Punk::Model's
 * DSL uses), rather than a Perl closure over $app.
 *
 * This is a boot-time path - import runs once per application class - so the
 * point is not speed. It is that the DSL surface is now described in one table
 * instead of twenty-five near-identical closures, and that adding a keyword
 * means adding a row.
 *
 * Include after punk_static.h (punk_closure, punk_clos_cap).
 */

#ifndef PUNK_IMPORT_H
#define PUNK_IMPORT_H

/* How a keyword relates to the registrar method behind it. */
enum {
    PKW_FWD = 0,   /* $app->$method(@_)            - most of them */
    PKW_NOARG,     /* $app->$method()              - to_app ignores its class */
    PKW_SELF,      /* $app                         - punk_app */
    PKW_ROUTE,     /* $app->route($HTTP, @_, [])   - get/post/... */
    PKW_HELPER     /* $app->helper(@_, $caller)    - helpers know their owner */
};

/* capture slots */
enum { PKI_APP = 0, PKI_KIND, PKI_NAME, PKI_CALLER };

/* The one body behind every exported keyword. Which of the five shapes it
 * takes is in the capture, so there is a single place where a DSL call becomes
 * a registrar call. */
XS_INTERNAL(pki_kw_cb);
XS_INTERNAL(pki_kw_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *app, *name;
    IV kind;
    int i, count;
    I32 want = GIMME_V;

    if (!cap) XSRETURN_EMPTY;
    app  = *av_fetch(cap, PKI_APP,  0);
    kind = SvIV(*av_fetch(cap, PKI_KIND, 0));
    name = *av_fetch(cap, PKI_NAME, 0);

    if (kind == PKW_SELF) {              /* punk_app: the registrar itself */
        ST(0) = sv_2mortal(newSVsv(app));
        XSRETURN(1);
    }

    PUSHMARK(SP);
    switch (kind) {
        case PKW_NOARG:
            EXTEND(SP, 1);
            PUSHs(app);
            break;

        case PKW_ROUTE:
            /* $app->route($METHOD, $path, $target, []) - the empty guard list
             * is what `under` fills in for a scoped route */
            EXTEND(SP, 5);
            PUSHs(app);
            PUSHs(name);
            PUSHs(items > 0 ? ST(0) : &PL_sv_undef);
            PUSHs(items > 1 ? ST(1) : &PL_sv_undef);
            mPUSHs(newRV_noinc((SV *)newAV()));
            break;

        case PKW_HELPER:
            /* the owning class rides along so a collision can name both */
            EXTEND(SP, items + 2);
            PUSHs(app);
            for (i = 0; i < items; i++) PUSHs(ST(i));
            PUSHs(*av_fetch(cap, PKI_CALLER, 0));
            break;

        default:                                     /* PKW_FWD */
            EXTEND(SP, items + 1);
            PUSHs(app);
            for (i = 0; i < items; i++) PUSHs(ST(i));
            break;
    }
    PUTBACK;

    /* the caller's context is propagated: `my $s = under ...` wants the scope
     * object, and a chaining keyword wants its $self back */
    count = call_method(kind == PKW_ROUTE  ? "route"
                      : kind == PKW_HELPER ? "helper"
                      : SvPV_nolen(name),
                        want == G_VOID ? G_VOID : want);
    SPAGAIN;
    if (want == G_VOID) XSRETURN_EMPTY;

    /* The results sit above the arguments we were called with, but XSRETURN
     * returns the slots at ax - so they have to be copied down. Into mortals
     * first, and through a scratch vector, because the two regions can overlap
     * and a direct move would clobber a value not yet read. */
    if (count > 0) {
        SV **tmp;
        int j;
        Newx(tmp, count, SV *);
        for (j = 0; j < count; j++) tmp[j] = sv_2mortal(newSVsv(SP[j - count + 1]));
        for (j = 0; j < count; j++) ST(j) = tmp[j];
        Safefree(tmp);
    }
    XSRETURN(count);
}

/* The DSL, as a table. A keyword is a row: its name, the registrar method it
 * reaches, and which of the five shapes it takes. */
typedef struct pki_kw {
    const char *kw;      /* what the application writes */
    const char *method;  /* the Punk::App method behind it (or the HTTP verb) */
    int         kind;
} pki_kw;

static const pki_kw PKI_KEYWORDS[] = {
    /* the verbs: one route each, with the method they mean */
    { "get",        "GET",         PKW_ROUTE  },
    { "post",       "POST",        PKW_ROUTE  },
    { "put",        "PUT",         PKW_ROUTE  },
    { "patch",      "PATCH",       PKW_ROUTE  },
    { "del",        "DELETE",      PKW_ROUTE  },
    { "any",        "ANY",         PKW_ROUTE  },

    /* everything that forwards straight through */
    { "under",      "under",       PKW_FWD    },
    { "api",        "api",         PKW_FWD    },
    { "websocket",  "websocket",   PKW_FWD    },
    { "sse",        "sse",         PKW_FWD    },
    { "session",    "session",     PKW_FWD    },
    { "ua",         "ua",          PKW_FWD    },
    { "csrf",       "csrf",        PKW_FWD    },
    { "cors",       "cors",        PKW_FWD    },
    { "logging",    "logging",     PKW_FWD    },
    { "docs",       "docs",        PKW_FWD    },
    { "static",     "static",      PKW_FWD    },
    { "markdown",   "markdown",    PKW_FWD    },
    { "mount",      "mount",       PKW_FWD    },
    { "views",      "views",       PKW_FWD    },
    { "config",     "config",      PKW_FWD    },
    { "secret",     "secret",      PKW_FWD    },
    { "database",   "database",    PKW_FWD    },
    { "model",      "model_class", PKW_FWD    },
    { "hook",       "hook",        PKW_FWD    },
    { "middleware", "middleware",  PKW_FWD    },
    { "on_error",   "on_error",    PKW_FWD    },
    { "plugin",     "plugin",      PKW_FWD    },

    { "helper",     "helper",      PKW_HELPER },
    { "to_app",     "compile",     PKW_NOARG  },
    { "punk_app",   NULL,          PKW_SELF   },
    { NULL, NULL, 0 }
};

/* One application registrar per class, cached in %Punk::APPS the way the Perl
 * import did - a second `use Punk` in the same package must not start a second
 * application. */
static SV *pki_app_for(pTHX_ SV *caller, int *fresh) {
    HV *apps = get_hv("Punk::APPS", GV_ADD);
    HE *he = hv_fetch_ent(apps, caller, 0, 0);
    SV *app;
    if (fresh) *fresh = 0;
    if (he && HeVAL(he) && SvROK(HeVAL(he))) return HeVAL(he);
    if (fresh) *fresh = 1;

    {
        dSP;
        int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 3);
        mPUSHs(newSVpvs("Punk::App"));
        mPUSHs(newSVpvs("caller"));
        PUSHs(caller);
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        app = count > 0 ? newSVsv(POPs) : &PL_sv_undef;
        PUTBACK; FREETMPS; LEAVE;
    }
    if (!SvROK(app))
        croak("Punk: Punk::App->new returned no registrar");
    (void)hv_store_ent(apps, caller, app, 0);
    return app;
}

/* strict and warnings, exactly as `use strict; use warnings;` would: both are
 * plain import calls that set hint bits in the scope being compiled, and
 * calling them from here reaches the same scope a Perl import would. */
static void pki_pragma(pTHX_ const char *pragma) {
    dSP;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 1);
    mPUSHs(newSVpv(pragma, 0));
    PUTBACK;
    (void)call_method("import", G_VOID | G_DISCARD);
    SPAGAIN;
    PUTBACK; FREETMPS; LEAVE;
}

/* Install the whole DSL into the calling package. */
static void pki_export(pTHX_ SV *caller) {
    int fresh = 0;
    SV *app = pki_app_for(aTHX_ caller, &fresh);
    STRLEN cl;
    const char *cs = SvPV_const(caller, cl);
    int i;

    /* A second `use Punk` in the same package extends that application rather
     * than starting another - so the keywords are already installed, and
     * reinstalling them would only warn about redefining every one. */
    if (!fresh) return;

    for (i = 0; PKI_KEYWORDS[i].kw; i++) {
        const pki_kw *k = &PKI_KEYWORDS[i];
        AV *cap = newAV();
        SV *code;
        av_push(cap, newSVsv(app));
        av_push(cap, newSViv(k->kind));
        av_push(cap, k->method ? newSVpv(k->method, 0) : newSV(0));
        if (k->kind == PKW_HELPER) av_push(cap, newSVsv(caller));
        code = punk_closure(aTHX_ pki_kw_cb, cap);
        {
            GV *gv = gv_fetchpvn_flags(form("%.*s::%s", (int)cl, cs, k->kw),
                                       cl + 2 + strlen(k->kw), GV_ADD, SVt_PVCV);
            sv_setsv((SV *)gv, code);
        }
        SvREFCNT_dec(code);
    }
}

#endif /* PUNK_IMPORT_H */
