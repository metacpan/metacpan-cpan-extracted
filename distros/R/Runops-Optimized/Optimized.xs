#define PERL_NO_GET_CONTEXT 1
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "unroll.h"

static int runops_optimized(pTHX)
{
    dVAR;
    register OP *op = PL_op;

    while ((PL_op = op = op->op_ppaddr(aTHX))) {

        if (op->op_type == OP_ENTERSUB && !IN_PERL_COMPILETIME) {
            /* We have an entersub op, call it, then decide what to do */
            const OP *const next = op->op_next;

            PL_op = op = op->op_ppaddr(aTHX);
            if (!op) /* e.g. call_method */
                break;
            else if (next == op->op_next) /* An XSUB just did its work */
                continue;

            if (!op->op_spare) {
                op->op_spare = 1;
            }
            else if (op->op_spare == 1 && op->op_opt) {
                unroll_this(aTHX_ op);
            }
        }
    }

    TAINT_NOT;
    return 0;
}

MODULE = Runops::Optimized	PACKAGE = Runops::Optimized

PROTOTYPES: ENABLE

int
is_optimized(SV* code)
CODE:
    if (SvROK(code))
        code = SvRV(code);

    if (SvTYPE(code) == SVt_PVCV && !CvISXSUB((CV*)code))
        RETVAL = CvSTART((CV*)code)->op_spare == 3;
    else
        croak("Usage: is_optimized(CODEREF)");
OUTPUT:
    RETVAL

BOOT:
	PL_runops = runops_optimized;
