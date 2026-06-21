#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

static OP *
splice_build_op(pTHX_ SV **opdata, OP *lhs, OP *rhs,
                struct Perl_custom_infix *def)
{
    PERL_UNUSED_ARG(opdata);
    PERL_UNUSED_ARG(def);
    return newCONDOP(0, lhs, rhs, newOP(OP_STUB, 0));
}

MODULE = Syntax::Infix::ConditionalSplice   PACKAGE = Syntax::Infix::ConditionalSplice

IV
_build_op_addr()
CODE:
    RETVAL = PTR2IV(splice_build_op);
OUTPUT:
    RETVAL
