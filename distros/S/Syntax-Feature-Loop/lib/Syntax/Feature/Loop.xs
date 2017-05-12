#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "../../../callparser1.h"


STATIC OP* remove_sub_call(pTHX_ OP* entersubop) {
#define remove_sub_call(a) remove_sub_call(aTHX_ a)
   OP* pushop;
   OP* realop;

   pushop = cUNOPx(entersubop)->op_first;
   if (!pushop->op_sibling)
      pushop = cUNOPx(pushop)->op_first;

   realop = pushop->op_sibling;
   if (!realop || !realop->op_sibling)
      return entersubop;

   pushop->op_sibling = realop->op_sibling;
   realop->op_sibling = NULL;
   op_free(entersubop);
   return realop;
}


STATIC OP* parse_loop(pTHX_ GV* namegv, SV* psobj, U32* flagsp) {
#define parse_loop(a,b,c) parse_loop(aTHX_ a,b,c)
   OP* exprop;
   OP* blockop;
   OP* loopop;

   PERL_UNUSED_ARG(namegv);
   PERL_UNUSED_ARG(psobj);

   exprop  = newSVOP(OP_CONST, 0, &PL_sv_yes);
   blockop = parse_block(0);
   loopop  = newWHILEOP(0, 1, NULL, exprop, blockop, NULL, 0);

   *flagsp |= CALLPARSER_STATEMENT;
   return loopop;
}


STATIC OP* ck_loop(pTHX_ OP* o, GV* namegv, SV* ckobj) {
#define check_loop(a,b,c) check_loop(aTHX_ a,b,c)
   PERL_UNUSED_ARG(namegv);
   PERL_UNUSED_ARG(ckobj);
   return remove_sub_call(o);
}


/* ======================================== */

MODULE = Syntax::Feature::Loop   PACKAGE = Syntax::Feature::Loop

BOOT:
{
   CV* const loopcv = get_cvn_flags("Syntax::Feature::Loop::loop", 27, GV_ADD);
   cv_set_call_parser(loopcv, parse_loop, &PL_sv_undef);
   cv_set_call_checker(loopcv, ck_loop, &PL_sv_undef);
}
