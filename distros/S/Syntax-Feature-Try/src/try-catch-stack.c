#include "try-catch-constants.h"
#include "try-catch-stack.h"

#include <perl.h>

#define get_sub_context_ix(start_ix)    my_get_sub_context_ix(aTHX_ start_ix)
STATIC I32 my_get_sub_context_ix(pTHX_ I32 start_ix) {
    I32 i;

    for (i = start_ix; i >= 0; i--) {
        register const PERL_CONTEXT * const cx = &cxstack[i];
        switch (CxTYPE(cx)) {
            case CXt_EVAL:
            case CXt_SUB:
            case CXt_FORMAT:
                return i;
        }
    }
    return -1;
}

#define is_called_internally(cx) \
        CopSTASH_eq((cx)->blk_oldcop, internal_stash)

static PERL_CONTEXT* my_get_sub_context(pTHX_ int skip_internals) {
    I32 i;
    i = get_sub_context_ix(cxstack_ix);
    if (i < 0) {
        return NULL;
    }

    if (skip_internals && (i >= 0)) {
        // skip internally called
        while ((i >= 0) && is_called_internally(&cxstack[i])) i--;

        // skip last internal block and find upper sub
        i = get_sub_context_ix(i-1);
    }
    return (i >= 0) ? &cxstack[i] : NULL;
}
