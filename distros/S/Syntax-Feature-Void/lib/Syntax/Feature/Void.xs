#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "../../../ppport.h"
#include "../../../callparser1.h"


STATIC OP* remove_sub_call(pTHX_ OP* entersubop) {
#define remove_sub_call(a) remove_sub_call(aTHX_ a)
   OP* pushop;
   OP* realop;
   OP* cvop;

   pushop = cUNOPx(entersubop)->op_first;
   if (!OpHAS_SIBLING(pushop))
      pushop = cUNOPx(pushop)->op_first;

   realop = OpSIBLING(pushop);
   if (!realop)
      return entersubop;

   cvop = OpSIBLING(realop);
   if (!cvop)
      return entersubop;

   OpMORESIB_set(pushop, cvop);
   OpLASTSIB_set(realop, NULL);
   op_free(entersubop);
   return realop;
}

STATIC OP* parse_void(pTHX_ GV* namegv, SV* psobj, U32* flagsp) {
#define parse_void(a,b,c) parse_void(aTHX_ a,b,c)
   PERL_UNUSED_ARG(namegv);
   PERL_UNUSED_ARG(psobj);
   return op_contextualize(parse_termexpr(0), G_VOID);
}


STATIC OP* ck_void(pTHX_ OP* o, GV* namegv, SV* ckobj) {
#define check_void(a,b,c) check_void(aTHX_ a,b,c)
   PERL_UNUSED_ARG(namegv);
   PERL_UNUSED_ARG(ckobj);
   return remove_sub_call(o);
}


/* ======================================== */

MODULE = Syntax::Feature::Void   PACKAGE = Syntax::Feature::Void

BOOT:
{
   const char voidname[] = "Syntax::Feature::Void::void";
   CV* const voidcv = get_cvn_flags(voidname, sizeof(voidname)-1, GV_ADD);
   cv_set_call_parser(voidcv, parse_void, &PL_sv_undef);
   cv_set_call_checker(voidcv, ck_void, &PL_sv_undef);
}
