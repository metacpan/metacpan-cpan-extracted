#ifndef __TRY_CATCH_STACK__
#define __TRY_CATCH_STACK__

#define get_sub_context(skip_internals) my_get_sub_context(aTHX_ skip_internals)
static PERL_CONTEXT* my_get_sub_context(pTHX_ int skip_internals);

#endif /* __TRY_CATCH_STACK__ */
