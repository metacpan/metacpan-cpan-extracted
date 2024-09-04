/* vi: set ft=c : */

#if HAVE_PERL_VERSION(5, 22, 0)
#  define PadnameIsNULL(pn)  (!(pn))
#else
#  define PadnameIsNULL(pn)  (!(pn) || (pn) == &PL_sv_undef)
#endif

#ifndef hv_deletes
#  define hv_deletes(hv, skey, flags)  hv_delete((hv), ("" skey ""), (sizeof(skey) - 1), flags)
#endif

#ifndef gv_fetchmeth_pvs
#  define gv_fetchmeth_pvs(stash, name, level, flags)  gv_fetchmeth_pvn((stash), ("" name ""), (sizeof(name) - 1), level, flags)
#endif

#if HAVE_PERL_VERSION(5, 22, 0)
#  define PadnameOUTER_off(pn)  (PadnameFLAGS(pn) &= ~PADNAMEt_OUTER)
#else
   /* PadnameOUTER is really the SvFAKE flag */
#  define PadnameOUTER_off(pn)  SvFAKE_off(pn)
#endif

#define save_strndup(s, l)  S_save_strndup(aTHX_ s, l)
static char *S_save_strndup(pTHX_ char *s, STRLEN l)
{
  /* savepvn doesn't put anything on the save stack, despite its name */
  char *ret = savepvn(s, l);
  SAVEFREEPV(ret);
  return ret;
}

#define dKWARG(count)      \
  U32 kwargi = count;      \
  U32 kwarg;               \
  SV *kwval;               \
  /* TODO: complain about odd number of args */

#define KWARG_NEXT(args) \
  S_kwarg_next(aTHX_ args, &kwargi, items, ax, &kwarg, &kwval)
static bool S_kwarg_next(pTHX_ const char *args[], U32 *kwargi, U32 argc, U32 ax, U32 *kwarg, SV **kwval)
{
  if(*kwargi >= argc)
    return FALSE;

  SV *argname = ST(*kwargi); (*kwargi)++;
  if(!SvOK(argname))
    croak("Expected string for next argument name, got undef");

  *kwarg = 0;
  while(args[*kwarg]) {
    if(strEQ(SvPV_nolen(argname), args[*kwarg])) {
      *kwval = ST(*kwargi); (*kwargi)++;
      return TRUE;
    }
    (*kwarg)++;
  }

  croak("Unrecognised argument name '%" SVf "'", SVfARG(argname));
}

#define import_pragma(pragma, arg)  S_import_pragma(aTHX_ pragma, arg)
static void S_import_pragma(pTHX_ const char *pragma, const char *arg)
{
  dSP;
  bool unimport = FALSE;

  if(pragma[0] == '-') {
    unimport = TRUE;
    pragma++;
  }

  SAVETMPS;

  EXTEND(SP, 2);
  PUSHMARK(SP);
  mPUSHp(pragma, strlen(pragma));
  if(arg)
    mPUSHp(arg, strlen(arg));
  PUTBACK;

  call_method(unimport ? "unimport" : "import", G_VOID);

  FREETMPS;
}

#define ensure_module_version(module, version)  S_ensure_module_version(aTHX_ module, version)
static void S_ensure_module_version(pTHX_ SV *module, SV *version)
{
  dSP;

  ENTER;

  PUSHMARK(SP);
  PUSHs(module);
  PUSHs(version);
  PUTBACK;

  call_method("VERSION", G_VOID);

  LEAVE;
}

#if HAVE_PERL_VERSION(5, 16, 0)
  /* TODO: perl 5.14 lacks HvNAMEUTF8, gv_fetchmeth_pvn() */
#  define fetch_superclass_method_pv(stash, pv, len, level)  S_fetch_superclass_method_pv(aTHX_ stash, pv, len, level)
static CV *S_fetch_superclass_method_pv(pTHX_ HV *stash, const char *pv, STRLEN len, U32 level)
{
#  if HAVE_PERL_VERSION(5, 18, 0)
  GV *gv = gv_fetchmeth_pvn(stash, pv, len, level, GV_SUPER);
#  else
  SV *superclassname = newSVpvf("%*s::SUPER", HvNAMELEN_get(stash), HvNAME_get(stash));
  if(HvNAMEUTF8(stash))
    SvUTF8_on(superclassname);
  SAVEFREESV(superclassname);

  HV *superstash = gv_stashsv(superclassname, GV_ADD);
  GV *gv = gv_fetchmeth_pvn(superstash, pv, len, level, 0);
#  endif

  if(!gv)
    return NULL;
  return GvCV(gv);
}
#endif /* HAVE_PERL_VERSION(5, 16, 0) */

#define get_class_isa(stash)  S_get_class_isa(aTHX_ stash)
static AV *S_get_class_isa(pTHX_ HV *stash)
{
  GV **gvp = (GV **)hv_fetchs(stash, "ISA", 0);
  if(!gvp || !GvAV(*gvp))
    croak("Expected %s to have a @ISA list", HvNAME(stash));

  return GvAV(*gvp);
}

#define find_cop_for_lvintro(padix, o, copp)  S_find_cop_for_lvintro(aTHX_ padix, o, copp)
static COP *S_find_cop_for_lvintro(pTHX_ PADOFFSET padix, OP *o, COP **copp)
{
  for( ; o; o = OpSIBLING(o)) {
    if(OP_CLASS(o) == OA_COP) {
      *copp = (COP *)o;
    }
    else if(o->op_type == OP_PADSV && o->op_targ == padix && o->op_private & OPpLVAL_INTRO) {
      return *copp;
    }
    else if(o->op_flags & OPf_KIDS) {
      COP *ret = find_cop_for_lvintro(padix, cUNOPx(o)->op_first, copp);
      if(ret)
        return ret;
    }
  }

  return NULL;
}

#define lex_consume_unichar(c)  MY_lex_consume_unichar(aTHX_ c)
static bool MY_lex_consume_unichar(pTHX_ U32 c)
{
  if(lex_peek_unichar(0) != c)
    return FALSE;

  lex_read_unichar(0);
  return TRUE;
}

#define av_push_from_av_inc(dst, src)    S_av_push_from_av(aTHX_ dst, src, TRUE)
#define av_push_from_av_noinc(dst, src)  S_av_push_from_av(aTHX_ dst, src, FALSE)
static void S_av_push_from_av(pTHX_ AV *dst, AV *src, bool refcnt_inc)
{
  SSize_t count = av_count(src);
  SSize_t i;

  av_extend(dst, av_count(dst) + count - 1);

  SV **vals = AvARRAY(src);

  for(i = 0; i < count; i++) {
    SV *sv = vals[i];
    av_push(dst, refcnt_inc ? SvREFCNT_inc(sv) : sv);
  }
}
