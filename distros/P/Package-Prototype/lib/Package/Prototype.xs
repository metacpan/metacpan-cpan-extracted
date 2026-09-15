#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#define NEED_mg_findext
#define NEED_newSVpvn_flags
#include "ppport.h"

#ifndef GvCV_set
# define GvCV_set(gv,cv) (GvGP(gv)->gp_cv = (cv))
#endif

#ifndef gv_init_pvn
# define gv_init_pvn gv_init
#endif

#define IsArrayRef(sv) (SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) == SVt_PVAV)
#define IsHashRef(sv) (SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) == SVt_PVHV)
#define IsCodeRef(sv) (SvROK(sv) && !SvOBJECT(SvRV(sv)) && SvTYPE(SvRV(sv)) == SVt_PVCV)
#define WANT_ARRAY GIMME_V == G_ARRAY

XS(XS_prototype_method);
XS(XS_prototype_getter);

static MGVTBL getter_vtbl = { 0 };

static GV *
prototype_gv_pvn(pTHX_ HV *stash, const char *name, STRLEN len, U32 flags)
{
    GV *gv = (GV *)newSV(0);
    gv_init_pvn(gv, stash, name, len, flags);
    return gv;
}

static GV *
prototype_gv_sv(pTHX_ HV *stash, SV *namesv)
{
    U32 flag = 0;
    char *namepv;
    STRLEN namelen;
    namepv = SvPV(namesv, namelen);
    if (SvUTF8(namesv)) flag = SVf_UTF8;
    return prototype_gv_pvn(aTHX_ stash, namepv, namelen, flag);
}

static void
add_method_sv(pTHX_ HV *stash, SV *method, CV *code)
{
    GV *gv;
    gv = prototype_gv_sv(aTHX_ stash, method);
    GvCV_set(gv, code);
    hv_store_ent(stash, method, (SV *)gv, 0);
#if PERL_VERSION >= 10
    mro_method_changed_in(stash);
#else
    PL_sub_generation++;
#endif
}

static CV *
make_closure(pTHX_ SV *retval)
{
    /* Release the destination even when fetching magic throws on older Perls. */
    SV *value = sv_newmortal();
    sv_setsv(value, retval);
    CV *xsub = newXS(NULL /* anonymous */, XS_prototype_getter, __FILE__);
    /* Magic owns the scalar for exactly as long as the getter CV. */
    sv_magicext((SV *)xsub, value, PERL_MAGIC_ext, &getter_vtbl, NULL, 0);
    return xsub;
}

static void
push_values(pTHX_ SV *retval)
{
    dSP;
    /* A later argument can replace the getter and release its owned values. */
    if (WANT_ARRAY && IsArrayRef(retval)) {
        AV *av  = (AV *)SvRV(retval);
        I32 len = av_len(av) + 1;
        EXTEND(SP, len);
        for (I32 i = 0; i < len; i++){
            SV **const svp = av_fetch(av, i, FALSE);
            PUSHs(svp ? sv_2mortal(SvREFCNT_inc(*svp)) : &PL_sv_undef);
        }
    } else if (WANT_ARRAY && IsHashRef(retval)) {
        HV *hv = (HV *)SvRV(retval);
        HE *he;
        hv_iterinit(hv);
        while ((he = hv_iternext(hv)) != NULL){
            EXTEND(SP, 2);
            PUSHs(hv_iterkeysv(he));
            PUSHs(sv_2mortal(SvREFCNT_inc(hv_iterval(hv, he))));
        }
    } else {
        XPUSHs(retval ? sv_2mortal(SvREFCNT_inc(retval)) : &PL_sv_undef);
    }
    PUTBACK;
}

static CV *
make_prototype_method(pTHX)
{
    CV *xsub;
    xsub = newXS(NULL /* anonymous */, XS_prototype_method, __FILE__);
    return xsub;
}

static void
install_prototype_method(pTHX_ HV *stash)
{
    char *prototype = "prototype";
    CV *prototype_cv = make_prototype_method(aTHX);
    GV *prototype_glob = prototype_gv_pvn(aTHX_ stash, prototype, 9, 0);
    GvCV_set(prototype_glob, prototype_cv);
    hv_store(stash, prototype, 9, (SV *)prototype_glob, 0);
}

XS(XS_prototype_getter)
{
    dVAR; dXSARGS;
    SV *retval = mg_findext((SV *)cv, PERL_MAGIC_ext, &getter_vtbl)->mg_obj;
    SP -= items; /* PPCODE */
    PUTBACK;
    push_values(aTHX_ retval);
}

XS(XS_prototype_method)
{
    dVAR; dXSARGS;
    if ((items - 1) % 2 != 0)
        Perl_croak(aTHX_ "Argument isn't hash type");
    
    if (items < 1 || !SvROK(ST(0)) || !SvOBJECT(SvRV(ST(0))))
        Perl_croak(aTHX_ "prototype requires an object invocant");
    HV *stash = SvSTASH(SvRV(ST(0)));
    I32 i = 1; /* First argument is skip: `my $self = shift;` */
    while (i < items) {
        SV *method = ST(i++);
        STRLEN namelen;
        const char *name = SvPV(method, namelen);
        method = sv_2mortal(newSVpvn_flags(name, namelen, SvUTF8(method) ? SVf_UTF8 : 0));
        SV *val = ST(i++);
        CV *cv = IsCodeRef(val) ? (CV *)SvREFCNT_inc(SvRV(val)) : make_closure(aTHX_ val);
        add_method_sv(aTHX_ stash, method, cv);
    }
    XSRETURN(0);
}

MODULE = Package::Prototype    PACKAGE = Package::Prototype
PROTOTYPES: DISABLE

void *
bless(klass, ref, pkgsv=NULL)
    SV *klass;
    SV *ref;
    SV *pkgsv;
PREINIT:
    char *pkg;
    STRLEN pkglen;
    HE* entry;
    HV *stash;
PPCODE:
{
    if (!IsHashRef(ref))
         Perl_croak(aTHX_ "Please pass an hash reference to the first argument");

    if (pkgsv) {
        pkg = SvPV(pkgsv, pkglen);
    } else {
        pkg = "__ANON__";
        pkglen = 8;
    }

    stash = (HV *)sv_2mortal((SV *)newHV());
    hv_name_set(stash, pkg, pkglen, pkgsv && SvUTF8(pkgsv) ? SVf_UTF8 : 0);

    install_prototype_method(aTHX_ stash);

    HV *hv = (HV *)SvRV(ref);
    hv_iterinit(hv);
    while ((entry = hv_iternext(hv)) != NULL){
        I32 keylen;
        char* key = hv_iterkey(entry, &keylen);
        if (0 < keylen && key[0] != '_') {
            SV *method = hv_iterkeysv(entry);
            SV *val = hv_delete_ent(hv, method, 0, 0);
            CV *cv = IsCodeRef(val) ? (CV *)SvREFCNT_inc(SvRV(val)) : make_closure(aTHX_ val);
            add_method_sv(aTHX_ stash, method, cv);
        }
    }

    ST(0) = sv_bless(ref, stash);
    XSRETURN(1);
}