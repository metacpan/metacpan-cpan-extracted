#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef gv_init_pvn
# define gv_init_pvn gv_init
#endif

static void
anon_isa (pTHX_ CV *cv)
{
  SV *sv;
  dXSARGS;

  if (items != 2)
	croak_xs_usage(cv, "reference, kind");

  sv = ST(1);
  SvGETMAGIC(sv);

  ST(0) = boolSV(SvTYPE(sv) == SVt_RV
                 && PTR2UV(SvRV(sv)) == CvXSUBANY(cv).any_uv);
  XSRETURN(1);
}

static GV *
anon_gv_pvn (pTHX_ HV *stash, const char *name, STRLEN namelen)
{
  GV *gv = (GV *)newSV(0);
  gv_init_pvn(gv, stash, name, namelen, 0);
  return gv;
}

static GV *
anon_gv_sv (pTHX_ HV *stash, SV *namesv)
{
  char *name;
  STRLEN namelen;
  name = SvPV(namesv, namelen);
  return anon_gv_pvn(aTHX_ stash, name, namelen);
}

static CV *
make_isa_method (pTHX_ HV *stash)
{
  CV *cv;
  cv = (CV *)newSV(0);
  sv_upgrade((SV *)cv, SVt_PVCV);
  CvISXSUB_on(cv);
  CvXSUB(cv) = anon_isa;
  CvXSUBANY(cv).any_uv = PTR2UV(stash);
  CvFILE(cv) = __FILE__;
  return cv;
}

MODULE = Package::Anon  PACKAGE = Package::Anon

PROTOTYPES: DISABLE

SV *
new (klass, namesv=NULL)
    SV *klass
    SV *namesv
  PREINIT:
    HV *stash;
    char *name;
    STRLEN namelen;
    CV *isa_method;
    GV *isa_glob;
  CODE:
    if (namesv)
      name = SvPV(namesv, namelen);
    else {
      name = "__ANON__";
      namelen = 8;
    }

    stash = newHV();
    hv_name_set(stash, name, namelen, 0);

    isa_glob = anon_gv_pvn(aTHX_ stash, "isa", 3);
    isa_method = make_isa_method(aTHX_ stash);
    GvCVGEN(isa_glob) = 0;
    GvCV_set(isa_glob, isa_method);
    CvGV_set(isa_method, isa_glob);

    (void)hv_store(stash, "isa", 3, (SV *)isa_glob, 0);
    RETVAL = newRV_noinc((SV *)stash);
    sv_bless(RETVAL, gv_stashsv(klass, 0));
  OUTPUT:
    RETVAL

SV *
create_glob (stash, name)
    SV *stash
    SV *name
  CODE:
    RETVAL = newRV_noinc((SV *)anon_gv_sv(aTHX_ (HV *)SvRV(stash), name));
  OUTPUT:
    RETVAL

void
bless (stash, rv)
    SV *stash
    SV *rv
  PPCODE:
    sv_bless(rv, (HV *)SvRV(stash));
    PUSHs(rv);

SV *
blessed (klass, obj)
    SV *klass
    SV *obj
  CODE:
    if (!SvROK(obj) || !SvOBJECT(SvRV(obj)))
      XSRETURN_UNDEF;
    RETVAL = newRV_inc((SV *)SvSTASH(SvRV(obj)));
    sv_bless(RETVAL, gv_stashsv(klass, 0));
  OUTPUT:
    RETVAL
