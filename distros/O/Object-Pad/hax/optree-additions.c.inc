/* vi: set ft=c : */

#define newAELEMOP(flags, first, key)  S_newAELEMOP(aTHX_ flags, first, key)
static OP *S_newAELEMOP(pTHX_ U32 flags, OP *first, I32 key)
{
  if(key >= -128 && key < 128 && first->op_type == OP_PADAV) {
    OP *o = newOP(OP_AELEMFAST_LEX, flags);
    o->op_private = (I8)key;
    o->op_targ = first->op_targ;
    op_free(first);
    return o;
  }

  return newBINOP(OP_AELEM, flags, first, newSVOP(OP_CONST, 0, newSViv(key)));
}

#define newPADxVOP(type, flags, padix)  S_newPADxVOP(aTHX_ type, flags, padix)
static OP *S_newPADxVOP(pTHX_ I32 type, I32 flags, PADOFFSET padix)
{
  OP *op = newOP(type, flags);
  op->op_targ = padix;
  return op;
}

#if HAVE_PERL_VERSION(5, 22, 0)
#  define HAVE_UNOP_AUX
#endif

#ifndef HAVE_UNOP_AUX
typedef struct UNOP_with_IV {
  UNOP baseop;
  IV   iv;
} UNOP_with_IV;

#define newUNOP_with_IV(type, flags, first, iv)  S_newUNOP_with_IV(aTHX_ type, flags, first, iv)
static OP *S_newUNOP_with_IV(pTHX_ I32 type, I32 flags, OP *first, IV iv)
{
  /* Cargoculted from perl's op.c:Perl_newUNOP()
   */
  UNOP_with_IV *op = PerlMemShared_malloc(sizeof(UNOP_with_IV) * 1);
  NewOp(1101, op, 1, UNOP_with_IV);

  if(!first)
    first = newOP(OP_STUB, 0);
  UNOP *unop = (UNOP *)op;
  unop->op_type = (OPCODE)type;
  unop->op_first = first;
  unop->op_ppaddr = NULL;
  unop->op_flags = (U8)flags | OPf_KIDS;
  unop->op_private = (U8)(1 | (flags >> 8));

  op->iv = iv;

  return (OP *)op;
}
#endif

#define newMETHOD_REDIR_OP(rclass, methname, flags)  S_newMETHOD_REDIR_OP(aTHX_ rclass, methname, flags)
static OP *S_newMETHOD_REDIR_OP(pTHX_ SV *rclass, SV *methname, I32 flags)
{
#if HAVE_PERL_VERSION(5, 22, 0)
  OP *op = newMETHOP_named(OP_METHOD_REDIR, flags, methname);
#  ifdef USE_ITHREADS
  {
    /* cargoculted from S_op_relocate_sv() */
    PADOFFSET ix = pad_alloc(OP_CONST, SVf_READONLY);
    PAD_SETSV(ix, rclass);
    cMETHOPx(op)->op_rclass_targ = ix;
  }
#  else
  cMETHOPx(op)->op_rclass_sv = rclass;
#  endif
#else
  OP *op = newUNOP(OP_METHOD, flags,
    newSVOP(OP_CONST, 0, newSVpvf("%" SVf "::%" SVf, rclass, methname)));
#endif

  return op;
}
