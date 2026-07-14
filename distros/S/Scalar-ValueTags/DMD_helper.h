#ifndef __DEVEL_MAT_DUMPER_HELPER_H__
#define __DEVEL_MAT_DUMPER_HELPER_H__

#define DMD_ANNOTATE_SV(targ, val, name)  S_DMD_AnnotateSv(aTHX_ targ, val, name)
static int S_DMD_AnnotateSv(pTHX_ const SV *targ, const SV *val, const char *name)
{
  dSP;
  if(!targ || !val)
    return 0;

  mXPUSHi(0x87); /* TODO PMAT_SVxSVSVnote */
  XPUSHs((SV *)targ);
  XPUSHs((SV *)val);
  mXPUSHp(name, strlen(name));
  PUTBACK;
  return 4;
}

#ifdef WANT_DMD_API_044
typedef struct DMDContext DMDContext;

typedef int DMD_Helper(pTHX_ DMDContext *ctx, const SV *sv);

#define DMD_SET_PACKAGE_HELPER(package, helper) S_DMD_SetPackageHelper(aTHX_ package, helper)
static void S_DMD_SetPackageHelper(pTHX_ char *package, DMD_Helper *helper)
{
  HV *helper_per_package;
  SV **svp;
  if((svp = hv_fetchs(PL_modglobal, "Devel::MAT::Dumper/%helper_per_package", 0)))
    helper_per_package = (HV *)SvRV(*svp);
  else {
    helper_per_package = newHV();
    hv_stores(PL_modglobal, "Devel::MAT::Dumper/%helper_per_package", newRV_noinc((SV *)helper_per_package));
  }

  hv_store(helper_per_package, package, strlen(package), newSVuv(PTR2UV(helper)), 0);
}

typedef int DMD_MagicHelper(pTHX_ DMDContext *ctx, const SV *sv, MAGIC *mg);

#define DMD_SET_MAGIC_HELPER(vtbl, helper) S_DMD_SetMagicHelper(aTHX_ vtbl, helper)
static void S_DMD_SetMagicHelper(pTHX_ MGVTBL *vtbl, DMD_MagicHelper *helper)
{
  HV *helper_per_magic;
  SV **svp;
  if((svp = hv_fetchs(PL_modglobal, "Devel::MAT::Dumper/%helper_per_magic", 0)))
    helper_per_magic = (HV *)SvRV(*svp);
  else {
    helper_per_magic = newHV();
    hv_stores(PL_modglobal, "Devel::MAT::Dumper/%helper_per_magic", newRV_noinc((SV *)helper_per_magic));
  }

  SV *keysv = newSViv((IV)vtbl);
  hv_store_ent(helper_per_magic, keysv, newSVuv(PTR2UV(helper)), 0);
  SvREFCNT_dec(keysv);
}

typedef struct
{
   const char *name;
   enum {
      DMD_FIELD_PTR,
      DMD_FIELD_BOOL,
      DMD_FIELD_U8,
      DMD_FIELD_U32,
      DMD_FIELD_UINT,
   }           type;
   struct {
      void       *ptr;
      bool        b;
      long        n;
   };
} DMDNamedField;

#define DMD_DUMP_STRUCT(ctx, name, addr, size, nfields, fields)  \
    S_DMD_DumpStruct(aTHX_ ctx, name, addr, size, nfields, fields)
static void S_DMD_DumpStruct(pTHX_ DMDContext *ctx, const char *name, void *addr, size_t size,
   size_t nfields, const DMDNamedField fields[])
{
  static void (*func)(pTHX_ DMDContext *ctx, const char *, void *, size_t,
     size_t, const DMDNamedField []);
  if(!func) {
    SV **svp = hv_fetchs(PL_modglobal, "Devel::MAT::Dumper/writestruct()", 0);
    if(svp)
      func = INT2PTR(void (*)(pTHX_ DMDContext *ctx, const char *, void *, size_t,
            size_t, const DMDNamedField[]), SvUV(*svp));
    else
      func = (void *)(-1);
  }

  if(func != (void *)(-1))
    (*func)(aTHX_ ctx, name, addr, size, nfields, fields);
}

#else
typedef int DMD_Helper(pTHX_ const SV *sv);

#define DMD_SET_PACKAGE_HELPER(package, helper) S_DMD_SetPackageHelper(aTHX_ package, helper)
static void S_DMD_SetPackageHelper(pTHX_ char *package, DMD_Helper *helper)
{
  HV *helper_per_package = get_hv("Devel::MAT::Dumper::HELPER_PER_PACKAGE", GV_ADD);

  hv_store(helper_per_package, package, strlen(package), newSVuv(PTR2UV(helper)), 0);
}

typedef int DMD_MagicHelper(pTHX_ const SV *sv, MAGIC *mg);

#define DMD_SET_MAGIC_HELPER(vtbl, helper) S_DMD_SetMagicHelper(aTHX_ vtbl, helper)
static void S_DMD_SetMagicHelper(pTHX_ MGVTBL *vtbl, DMD_MagicHelper *helper)
{
  HV *helper_per_magic = get_hv("Devel::MAT::Dumper::HELPER_PER_MAGIC", GV_ADD);
  SV *keysv = newSViv((IV)vtbl);

  hv_store_ent(helper_per_magic, keysv, newSVuv(PTR2UV(helper)), 0);

  SvREFCNT_dec(keysv);
}
#endif

#define DMD_IS_ACTIVE()  S_DMD_is_active(aTHX)
static bool S_DMD_is_active(pTHX)
{
#ifdef MULTIPLICITY
  return !!get_cv("Devel::MAT::Dumper::dump", 0);
#else
  static bool active;
  static bool cached = FALSE;
  if(!cached) {
    active = !!get_cv("Devel::MAT::Dumper::dump", 0);
    cached = TRUE;
  }
  return active;
#endif
}

#define DMD_ADD_ROOT(sv, name) S_DMD_add_root(aTHX_ sv, name)
static void S_DMD_add_root(pTHX_ SV *sv, const char *name)
{
  AV *moreroots = get_av("Devel::MAT::Dumper::MORE_ROOTS", GV_ADD);

  av_push(moreroots, newSVpvn(name, strlen(name)));
  av_push(moreroots, sv);
}

#endif
