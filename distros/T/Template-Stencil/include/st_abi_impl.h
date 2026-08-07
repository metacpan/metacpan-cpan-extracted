#ifndef ST_ABI_IMPL_H
#define ST_ABI_IMPL_H

/* Template::Stencil-side implementation of the shared C ABI (st_abi.h).
 * Included by Stencil.xs AFTER stencil_obj_vtbl and stencil_build_engine are
 * in scope, since the engine hangs off the object as ext magic. Everything
 * here is private to this translation unit; consumers reach it only through
 * the ST_ABI table returned by Template::Stencil::_abi_ptr. */

#include "st_abi.h"

/* Like stencil_engine_of but returns NULL where that croaks: a consumer
 * probing whether an object is renderable through the ABI must be able to ask
 * without an eval. The lazy build is the same one the render method does, so
 * an object that has never rendered - or a clone that dropped its engine on
 * ithread dup - still hands back a working engine here. */
static void *st_abi_engine_of(pTHX_ SV *obj_sv)
{
    SV    *rv;
    MAGIC *mg;
    if (!obj_sv || !SvROK(obj_sv)) return NULL;
    rv = SvRV(obj_sv);
    if (SvTYPE(rv) != SVt_PVHV
        || !sv_derived_from(obj_sv, "Template::Stencil")) return NULL;
    mg = mg_findext(rv, PERL_MAGIC_ext, &stencil_obj_vtbl);
    if (!mg) return NULL;
    if (!mg->mg_ptr)
        mg->mg_ptr = (char *)stencil_build_engine(aTHX_ (HV *)rv);
    return (void *)mg->mg_ptr;
}

/* The whole render path, minus the XS prologue and the croak. Errors come back
 * through *err exactly as stencil_engine_render sets them (the render, engine
 * and compile cores never croak), so a consumer can turn a template error into
 * its own 500 rather than an exception it has to catch. */
static SV *st_abi_render(pTHX_ void *engine, SV *tmpl, HV *data,
                         SV *opts, SV **err)
{
    stencil_engine *e = (stencil_engine *)engine;
    HV             *dhv;
    if (!e || !tmpl) {
        if (err) *err = sv_2mortal(newSVpvs(
            "Template::Stencil: render needs an engine and a template"));
        return NULL;
    }
    dhv = data ? data : (HV *)sv_2mortal((SV *)newHV());
    return stencil_engine_render(aTHX_ e, tmpl, dhv, opts, err);
}

static const st_abi ST_ABI = {
    ST_ABI_VERSION,
    st_abi_engine_of,
    st_abi_render,
};

#endif /* ST_ABI_IMPL_H */
