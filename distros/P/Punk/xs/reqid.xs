MODULE = Punk        PACKAGE = Punk::Plugin::RequestId

PROTOTYPES: DISABLE

# The whole plugin's request path lives in include/punk/punk_reqid.h. What is
# exposed here is registration and one mint, which is all lib/Punk/Plugin/
# RequestId.pm needs.

# _enable($app, $header_name_or_undef)
#
# Registers the process-wide observers once, and freezes THIS app's header
# name onto its app hash - beside where the `session` and `csrf` keywords keep
# theirs. Per-app, because two Punk apps can share a process under
# Plack::Builder and a header name held in a static made the last one to
# register name the header for both.
#
# An undefined header stores a false value rather than nothing: "the plugin is
# loaded and the header is off" has to stay distinguishable from "this app
# never loaded the plugin", or an app without the plugin would still mint ids.
# (Starting that sentence with the word `undef` made the line read as a cpp
# #undef directive - the xsubpp trap this workspace has met before.)
IV
_enable(class, app, header = &PL_sv_undef, envkey = &PL_sv_undef)
        SV *class
        SV *app
        SV *header
        SV *envkey
    CODE:
    {
        HV *h   = app_hv(aTHX_ app);
        AV *cfg = newAV();
        av_push(cfg, (SvOK(header) && SvTRUE(header))
                        ? newSVsv(header) : newSViv(0));
        av_push(cfg, (SvOK(envkey) && SvTRUE(envkey))
                        ? newSVsv(envkey) : newSV(0));
        (void)hv_stores(h, PR_APP_KEY, newRV_noinc((SV *)cfg));
        PERL_UNUSED_VAR(class);
        RETVAL = pr_enable(aTHX);
    }
    OUTPUT:
        RETVAL

# One id, for a caller that wants one outside a request - and for the tests
# that assert uniqueness and format without standing a server up.
SV *
_mint(class = &PL_sv_undef)
        SV *class
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = pr_mint(aTHX);
    OUTPUT:
        RETVAL

# $c->request_id - installed as the helper itself, so the accessor is an XSUB
# rather than a Perl closure wrapping one.
SV *
_id(c)
        SV *c
    CODE:
    {
        AV *av = pcx_av(aTHX_ c);
        SV *id = av ? pcx_get(aTHX_ av, PCX_REQID) : NULL;
        RETVAL = (id && SvOK(id)) ? newSVsv(id) : newSV(0);
    }
    OUTPUT:
        RETVAL

# What the plugin has done, process-wide. `adopted` and `rejected` are only
# ever non-zero where trust_header is on, and a rising `rejected` is somebody
# sending ids that are not ids - which is worth being able to see rather than
# discarding silently.
void
stats(class = &PL_sv_undef)
        SV *class
    PPCODE:
    {
        PERL_UNUSED_VAR(class);
        EXTEND(SP, 6);
        mPUSHs(newSVpvs("minted"));   mPUSHu(pr_n_minted);
        mPUSHs(newSVpvs("adopted"));  mPUSHu(pr_n_adopted);
        mPUSHs(newSVpvs("rejected")); mPUSHu(pr_n_rejected);
        XSRETURN(6);
    }
