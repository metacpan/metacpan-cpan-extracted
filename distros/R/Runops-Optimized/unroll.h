#ifndef RUNOPS_OPTIMIZED_UNROLL_H
#define RUNOPS_OPTIMIZED_UNROLL_H

/* I don't regard this as "proper" JIT, so it's called unroll, not jit. */

#define PERL_NO_GET_CONTEXT 1
#include <EXTERN.h>
#include <perl.h>

/** Given a perl OP unroll the operations from that point onwards and patch the
 * appropriate op_ppcode members with the address of the new code.
 */
void unroll_this(pTHX_ OP* op);

#endif
