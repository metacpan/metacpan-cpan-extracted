#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "hook_op_check.h"

STATIC void
op_clone(pTHX_ OP *old_op, SVOP **new_op) {
  switch(old_op->op_type) {
  case OP_CONST:
    *new_op = (SVOP*)newSVOP(OP_CONST, (old_op)->op_flags, newSVsv(cSVOPx(old_op)->op_sv ));
    break;

  case OP_PADSV:
    *new_op = (SVOP*)newOP(OP_PADSV, old_op->op_flags);
    (*new_op)->op_targ = old_op->op_targ;
    break;
  }
}

STATIC OP *
range_replace(pTHX_ OP *op, void *user_data) {
  GV *xrange;
  UNOP *entersub_op, *xrange_op;
  SVOP *min_op, *max_op;
  LISTOP *entersub_args = NULL;

  /* Make sure that the %^H is localized */
  if ((PL_hints & 0x00020000) != 0x00020000) {
    return op;
  }

  /*
    Range.pm should properly set $^H{PerlXRange} to 1 to toggle the
    effectiveness of PerlX::Range
  */
  if (!hv_exists(GvHV(PL_hintgv), "PerlXRange", 10)) {
    return op;
  }

  if ( cUNOPx(op)->op_first->op_type != OP_FLIP) return op;
  if ( cUNOPx(cUNOPx(op)->op_first)->op_first->op_type != OP_RANGE ) return op;

#define ORIGINAL_RANGE_OP cLOGOPx(cUNOPx(cUNOPx(op)->op_first)->op_first)

  op_clone(aTHX_ (OP*)(ORIGINAL_RANGE_OP->op_first), &min_op);
  op_clone(aTHX_ (OP*)(ORIGINAL_RANGE_OP->op_other), &max_op);

#undef ORIGINAL_RANGE_OP

  xrange = gv_fetchpvs("PerlX::Range::xrange", 1, SVt_PVCV);

  xrange_op = (UNOP*)Perl_newUNOP(aTHX_ OP_RV2CV, 0, newGVOP(OP_GV, 0, xrange));

  entersub_args = (LISTOP*)Perl_append_elem(aTHX_ OP_LIST, (OP*)entersub_args, (OP*)min_op);
  entersub_args = (LISTOP*)Perl_append_elem(aTHX_ OP_LIST, (OP*)entersub_args, (OP*)max_op);
  entersub_args = (LISTOP*)Perl_append_elem(aTHX_ OP_LIST, (OP*)entersub_args, (OP*)xrange_op);

  entersub_op   = (UNOP*)Perl_newUNOP(aTHX_ OP_ENTERSUB, OPf_STACKED, (OP*)min_op);
  return (OP*)entersub_op;
}

STATIC hook_op_check_id perlx_range_flop_hook_id = 0;

MODULE = PerlX::Range		PACKAGE = PerlX::Range

PROTOTYPES: DISABLE

void
add_flop_hook()
CODE:
    perlx_range_flop_hook_id = hook_op_check(OP_FLOP, range_replace, NULL);

void
remove_flop_hook()
CODE:
    hook_op_check_remove(OP_FLOP, perlx_range_flop_hook_id);
