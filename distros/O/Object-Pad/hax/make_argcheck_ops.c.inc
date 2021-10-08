/* vi: set ft=c : */

#define make_croak_op(message)  S_make_croak_op(aTHX_ message)
static OP *S_make_croak_op(pTHX_ SV *message)
{
#if HAVE_PERL_VERSION(5, 22, 0)
  sv_catpvs(message, " at %s line %d.\n");
  /* die sprintf($message, (caller)[1,2]) */
  return op_convert_list(OP_DIE, 0,
    op_convert_list(OP_SPRINTF, 0,
      op_append_list(OP_LIST,
        newSVOP(OP_CONST, 0, message),
        newSLICEOP(0,
          op_append_list(OP_LIST,
            newSVOP(OP_CONST, 0, newSViv(1)),
            newSVOP(OP_CONST, 0, newSViv(2))),
          newOP(OP_CALLER, 0)))));
#else
  /* For some reason I can't work out, the above tree isn't correct. Attempts
   * to correct it still make OP_SPRINTF crash with "Out of memory!". For now
   * lets just avoid the sprintf
   */
  sv_catpvs(message, "\n");
  return newLISTOP(OP_DIE, 0, newOP(OP_PUSHMARK, 0),
    newSVOP(OP_CONST, 0, message));
#endif
}

#if HAVE_PERL_VERSION(5, 26, 0)
#  define HAVE_OP_ARGCHECK

#  include "make_argcheck_aux.c.inc"
#endif

#define make_argcheck_ops(required, optional, slurpy, subname)  S_make_argcheck_ops(aTHX_ required, optional, slurpy, subname)
static OP *S_make_argcheck_ops(pTHX_ int required, int optional, char slurpy, SV *subname)
{
  int params = required + optional;

#ifdef HAVE_OP_ARGCHECK
  UNOP_AUX_item *aux = make_argcheck_aux(params, optional, slurpy);

  return op_prepend_elem(OP_LINESEQ, newSTATEOP(0, NULL, NULL),
      op_prepend_elem(OP_LINESEQ, newUNOP_AUX(OP_ARGCHECK, 0, NULL, aux), NULL));
#else
  /* Older perls lack the convenience of OP_ARGCHECK so we'll have to build an
   * optree ourselves. For now we only support required + optional, no slurpy
   *
   * This code heavily inspired by Perl_parse_subsignature() in toke.c from perl 5.24
   */

  OP *ret = NULL;

  if(required > 0) {
    SV *message = newSVpvf("Too few arguments for subroutine '%" SVf "'", subname);
    /* @_ >= required or die ... */
    OP *checkop = 
      newSTATEOP(0, NULL,
        newLOGOP(OP_OR, 0,
          newBINOP(OP_GE, 0,
            /* scalar @_ */
            op_contextualize(newUNOP(OP_RV2AV, 0, newGVOP(OP_GV, 0, PL_defgv)), G_SCALAR),
            newSVOP(OP_CONST, 0, newSViv(required))),
          make_croak_op(message)));

    ret = op_append_list(OP_LINESEQ, ret, checkop);
  }

  if(!slurpy) {
    SV *message = newSVpvf("Too many arguments for subroutine '%" SVf "'", subname);
    /* @_ <= (required+optional) or die ... */
    OP *checkop =
      newSTATEOP(0, NULL,
        newLOGOP(OP_OR, 0,
          newBINOP(OP_LE, 0,
            /* scalar @_ */
            op_contextualize(newUNOP(OP_RV2AV, 0, newGVOP(OP_GV, 0, PL_defgv)), G_SCALAR),
            newSVOP(OP_CONST, 0, newSViv(params))),
          make_croak_op(message)));

    ret = op_append_list(OP_LINESEQ, ret, checkop);
  }

  /* TODO: If slurpy is % then maybe complain about odd number of leftovers */

  return ret;
#endif
}
