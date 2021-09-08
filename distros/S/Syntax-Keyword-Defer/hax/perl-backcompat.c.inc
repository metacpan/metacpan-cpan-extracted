/* vi: set ft=c : */

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#ifndef SvTRUE_NN
#  define SvTRUE_NN(sv)  SvTRUE(sv)
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

#ifndef CX_CUR
#  define CX_CUR() (&cxstack[cxstack_ix])
#endif

#if HAVE_PERL_VERSION(5, 24, 0)
#  define OLDSAVEIX(cx)  (cx->blk_oldsaveix)
#else
#  define OLDSAVEIX(cx)  (PL_scopestack[cx->blk_oldscopesp-1])
#endif

#ifndef OpSIBLING
#  define OpSIBLING(op)  (op->op_sibling)
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
  o->op_type = type;
  o->op_flags |= flags;
  o->op_ppaddr = PL_ppaddr[type];

  o = PL_check[type](aTHX_ o);

  return o;
}
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
PADOFFSET MY_pad_add_name(pTHX_ const char *name, STRLEN len, U32 flags, HV *typestash, HV *ourstash)
{
  /* perl 5.14's Perl_pad_add_name requires a NUL-terminated name */
  SV *namesv = sv_2mortal(newSVpvn(name, len));

  return Perl_pad_add_name(aTHX_ SvPV_nolen(namesv), SvCUR(namesv), flags, typestash, ourstash);
}
#endif
