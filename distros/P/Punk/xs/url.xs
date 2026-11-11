MODULE = Punk        PACKAGE = Punk::URL

PROTOTYPES: DISABLE

# The tied hash behind `{% url.books %}`. punk_url.h says why it is tied
# rather than built: Stencil resolves a missing path to the empty string, and
# `href=""` is a link to the current page that looks like it works.
#
# Static routes only - a dynamic one needs captures, which is the filter's
# job. A template only ever reads, so FETCH and EXISTS are the whole class.

SV *
FETCH(self, key)
        SV *self
        SV *key
    CODE:
    {
        AV *o = (AV *)SvRV(self);
        SV **appsv = av_fetch(o, PKU_T_APP, 0);
        SV **pfx   = av_fetch(o, PKU_T_PREFIX, 0);
        HV *app = (appsv && *appsv && SvROK(*appsv)
                   && SvTYPE(SvRV(*appsv)) == SVt_PVHV)
                  ? (HV *)SvRV(*appsv) : NULL;
        SV *path = NULL;

        # uncoverable branch true
        # uncoverable condition left count:1 class:ignore_covered_err
        if (!app)
            croak("Punk: {%% url.%s %%}: the application is gone", /* # uncoverable statement */
                  SvPV_nolen(key)); /* # uncoverable statement */

        if (!pk_url_static_path(aTHX_ app, key, &path)) {
            /* Two different mistakes, and the message says which. A dynamic
             * route in the hash would have to invent its captures; a name
             * that is not there at all is a typo. */
            IV idx = pk_url_idx(aTHX_ app, key);
            if (idx >= 0)
                croak("Punk: {%% url.%s %%}: '%s' captures, so it needs "
                      "values - use the filter: {%% row | url_for('%s') %%}",
                      SvPV_nolen(key), SvPV_nolen(key), SvPV_nolen(key));
            croak("Punk: {%% url.%s %%}: no route is named '%s' - the `url` "
                  "hash holds the application's named static routes",
                  SvPV_nolen(key), SvPV_nolen(key));
        }

        RETVAL = newSVpvs("");
        # uncoverable branch false
        # uncoverable condition right count:1 class:ignore_covered_err
        # uncoverable condition right count:2 class:ignore_covered_err
        # uncoverable condition right count:3 class:ignore_covered_err
        if (pfx && *pfx && SvOK(*pfx)) sv_catsv(RETVAL, *pfx);
        # uncoverable branch false
        # uncoverable condition right count:1 class:ignore_covered_err
        if (path) sv_catsv(RETVAL, path);
    }
    OUTPUT:
        RETVAL

# A template asking whether a name is there, without building the URL.
bool
# uncoverable statement
# uncoverable subroutine
EXISTS(self, key)
        SV *self
        SV *key
    CODE:
    {
        AV *o = (AV *)SvRV(self); /* # uncoverable statement */
        SV **appsv = av_fetch(o, PKU_T_APP, 0); /* # uncoverable statement */
        HV *app = (appsv && *appsv && SvROK(*appsv) /* # uncoverable statement */
                   && SvTYPE(SvRV(*appsv)) == SVt_PVHV) /* # uncoverable statement */
                  ? (HV *)SvRV(*appsv) : NULL; /* # uncoverable statement */
        # uncoverable statement
        # uncoverable condition left count:1
        # uncoverable condition right count:1
        RETVAL = app ? pk_url_static_path(aTHX_ app, key, NULL) : 0;
    }
    OUTPUT:
        RETVAL
