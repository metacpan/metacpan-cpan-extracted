#ifndef EASYXS_INIT
#define EASYXS_INIT 1

#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"

/* Implement perl5 7169efc77525df for older perls (part 1): */
#define STMT_START  do
#define STMT_END    while (0)

#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifdef __cplusplus
}
#endif

/* Implement perl5 7169efc77525df for older perls (part 2): */
#undef STMT_START
#undef STMT_END
#define STMT_START  do
#define STMT_END    while (0)

#endif
