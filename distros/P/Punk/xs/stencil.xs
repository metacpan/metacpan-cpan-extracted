MODULE = Punk        PACKAGE = Punk::View::Stencil

PROTOTYPES: DISABLE

# The shipped view engine (punk_stencil.h). Two array slots - the options as
# registered and the Template::Stencil object built from them - and a render
# that reaches the template VM through Template::Stencil's C ABI, so no Perl
# frame sits between the dispatcher and the engine. lib/Punk/View/Stencil.pm
# is documentation only.

# new(\%opts) or new(%opts). Punk::Views (punk_views.h) hands the registered
# options as one positional hashref; the list form is for anyone constructing
# the view directly. Builds the Template::Stencil engine here and now, so an
# option it will not accept fails at boot with the rest of the configuration
# rather than on the first render.
SV *
new(class, ...)
        SV *class
    CODE:
    {
        HV *opts;
        SV *opts_rv;
        AV *av;
        if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV) {
            opts = (HV *)SvRV(ST(1));
            SvREFCNT_inc((SV *)opts);
        }
        else {
            int i;
            if (!(items % 2))
                croak("Punk::View::Stencil->new: odd number of options");
            opts = newHV();
            for (i = 1; i + 1 < items; i += 2)
                (void)hv_store_ent(opts, ST(i), newSVsv(ST(i + 1)), 0);
        }
        opts_rv = sv_2mortal(newRV_noinc((SV *)opts));

        /* resolve the ABI before building anything, so a missing or too-old
         * Template::Stencil is a boot error naming the version it needs */
        (void)punk_st(aTHX);

        av = newAV();
        av_extend(av, PVS_ENGINE);
        (void)av_store(av, PVS_OPTS,   newSVsv(opts_rv));
        (void)av_store(av, PVS_ENGINE, pvs_build_engine(aTHX_ opts_rv));
        RETVAL = sv_bless(newRV_noinc((SV *)av), gv_stashsv(class, GV_ADD));
    }
    OUTPUT:
        RETVAL

# render($template, \%data, \%opts?) - one indirect call into Template::Stencil
# and back. The bytes belong to the caller; Punk::Views copies them into the
# response body rather than letting a lexical steal the buffer.
SV *
render(self, template, data = &PL_sv_undef, opts = &PL_sv_undef)
        SV *self
        SV *template
        SV *data
        SV *opts
    CODE:
        RETVAL = pvs_render(aTHX_ self, template, data, opts);
    OUTPUT:
        RETVAL

# The registered options, and the Template::Stencil object itself for anything
# that wants to reach past the adapter. Both read/write, as the slots were.
SV *
opts(self, ...)
        SV *self
    ALIAS:
        engine = 1
    CODE:
    {
        AV *av = pvs_av(aTHX_ self);
        I32 slot = ix ? PVS_ENGINE : PVS_OPTS;
        SV **e;
        if (items > 1) (void)av_store(av, slot, newSVsv(ST(1)));
        e = av_fetch(av, slot, 0);
        RETVAL = (e && *e) ? newSVsv(*e) : newSV(0);
    }
    OUTPUT:
        RETVAL

# Whether the C ABI resolved - the guard test drives this with
# PUNK_FAKE_ST_BAD to prove the boot-time croak, since there is no Perl
# render path to fall back to.
IV
_abi_ok()
    CODE:
        RETVAL = punk_st_try(aTHX) ? 1 : 0;
    OUTPUT:
        RETVAL
