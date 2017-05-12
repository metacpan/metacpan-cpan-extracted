#ifndef __TRY_CATCH_PARSER__
#define __TRY_CATCH_PARSER__

#include <perl.h>

#define parse_try_statement()   my_parse_try_statement(aTHX)
static OP *my_parse_try_statement(pTHX);

#endif /* __TRY_CATCH_PARSER__ */
