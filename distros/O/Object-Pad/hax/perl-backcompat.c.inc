/* vi: set ft=c : */

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#ifndef NOT_REACHED
#  define NOT_REACHED  assert(0)
#endif

#ifndef SvTRUE_NN
#  define SvTRUE_NN(sv)  SvTRUE(sv)
#endif

#ifndef G_LIST
#  define G_LIST  G_ARRAY
#endif

#if !HAVE_PERL_VERSION(5, 18, 0)
typedef AV PADNAMELIST;
#  define PadlistARRAY(pl)        ((PAD **)AvARRAY(pl))
#  define PadlistNAMES(pl)        (*PadlistARRAY(pl))

typedef SV PADNAME;
#  define PadnamePV(pn)           (SvPOKp(pn) ? SvPVX(pn) : NULL)
#  define PadnameLEN(pn)          SvCUR(pn)
#  define PadnameOUTER(pn)        (SvFAKE(pn) && !SvPAD_STATE(pn))
#  define PadnamelistARRAY(pnl)   AvARRAY(pnl)
#  define PadnamelistMAX(pnl)     AvFILLp(pnl)

#  define PadARRAY(p)             AvARRAY(p)
#  define PadMAX(pad)             AvFILLp(pad)
#endif

#ifndef av_top_index
#  define av_top_index(av)       AvFILL(av)
#endif

#ifndef block_end
#  define block_end(a,b)         Perl_block_end(aTHX_ a,b)
#endif

#ifndef block_start
#  define block_start(a)         Perl_block_start(aTHX_ a)
#endif

#ifndef cv_clone
#  define cv_clone(a)            Perl_cv_clone(aTHX_ a)
#endif

#ifndef intro_my
#  define intro_my()             Perl_intro_my(aTHX)
#endif

#ifndef pad_alloc
#  define pad_alloc(a,b)         Perl_pad_alloc(aTHX_ a,b)
#endif

#ifndef CX_CUR
#  define CX_CUR() (&cxstack[cxstack_ix])
#endif

#if HAVE_PERL_VERSION(5, 24, 0)
#  define OLDSAVEIX(cx)  (cx->blk_oldsaveix)
#else
#  define OLDSAVEIX(cx)  (PL_scopestack[cx->blk_oldscopesp-1])
#endif

#ifndef OpSIBLING
#  define OpSIBLING(op)  ((op)->op_sibling)
#endif

#ifndef OpMORESIB_set
#  define OpMORESIB_set(op,sib)  ((op)->op_sibling = (sib))
#endif

#ifndef OpLASTSIB_set
   /* older perls don't need to store this at all */
#  define OpLASTSIB_set(op,parent)
#endif

#ifndef op_convert_list
#  define op_convert_list(type, flags, o)  S_op_convert_list(aTHX_ type, flags, o)
static OP *S_op_convert_list(pTHX_ I32 type, I32 flags, OP *o)
{
  /* A minimal recreation just for our purposes */
  assert(
    /* A hardcoded list of the optypes we know this will work for */
    type == OP_ENTERSUB ||
    type == OP_JOIN ||
    type == OP_PUSH ||
    0);

  o->op_type = type;
  o->op_flags |= flags;
  o->op_ppaddr = PL_ppaddr[type];

  o = PL_check[type](aTHX_ o);

  /* op_std_init() */
  if(PL_opargs[type] & OA_RETSCALAR)
    o = op_contextualize(o, G_SCALAR);
  if(PL_opargs[type] & OA_TARGET && !o->op_targ)
    o->op_targ = pad_alloc(type, SVs_PADTMP);

  return o;
}
#endif

#ifndef newMETHOP_named
#  define newMETHOP_named(type, flags, name)  newSVOP(type, flags, name)
#endif

#ifndef PARENT_PAD_INDEX_set
#  if HAVE_PERL_VERSION(5, 22, 0)
#    define PARENT_PAD_INDEX_set(pn,val) (PARENT_PAD_INDEX(pn) = val)
#  else
     /* stolen from perl-5.20.0's pad.c */
#    define PARENT_PAD_INDEX_set(sv,val) \
        STMT_START { ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xlow = (val); } STMT_END
#  endif
#endif

/* On Perl 5.14 this had a different name */
#ifndef pad_add_name_pvn
#define pad_add_name_pvn(name, len, flags, typestash, ourstash)  MY_pad_add_name(aTHX_ name, len, flags, typestash, ourstash)
static PADOFFSET MY_pad_add_name(pTHX_ const char *name, STRLEN len, U32 flags, HV *typestash, HV *ourstash)
{
  /* perl 5.14's Perl_pad_add_name requires a NUL-terminated name */
  SV *namesv = sv_2mortal(newSVpvn(name, len));

  return Perl_pad_add_name(aTHX_ SvPV_nolen(namesv), SvCUR(namesv), flags, typestash, ourstash);
}
#endif

#if !HAVE_PERL_VERSION(5, 26, 0)
#  define isIDFIRST_utf8_safe(s, e)  (PERL_UNUSED_ARG(e), isIDFIRST_utf8(s))
#  define isIDCONT_utf8_safe(s, e)   (PERL_UNUSED_ARG(e), isIDCONT_utf8(s))
#endif
