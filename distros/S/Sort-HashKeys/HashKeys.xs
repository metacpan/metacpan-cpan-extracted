#define PERL_NO_GET_CONTEXT
#define _BSD_SOURCE
#define _GNU_SOURCE
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdlib.h>
#include <string.h>
 
#include "ppport.h"
#include <stdio.h>

/* We want to use qsort_r to avoid having to do fetch state from TLS on every compare
 * Unfortunately, qsort_r isn't standard, and the order of arguments differ between
 * glibc and BSD libc, so we need some preprocessor magic to handle the three cases
 */

#ifdef MULTIPLICITY
    #ifdef __linux__
        #define pCMP(my_perl, a, b) (a, b, my_perl)
        #define aCMP
        #define sort(base, nel, elemsz, data, cmpfn) qsort_r(base, nel, elemsz, cmpfn, data)

    #elif defined __FreeBSD__ || (defined __APPLE__ && defined __MACH__)
            #define pCMP
            #define aCMP
            #define sort qsort_r
    #endif

    #ifndef sort /* Meh. We'll do a TLS access on every compare then.. */
            #define pCMP(my_perl, a, b) (a, b)
            #define aCMP(my_perl, a, b) (PERL_GET_THX, a, b)
            #define sort(base, nel, elemsz, data, cmpfn) qsort(base, nel, elemsz, cmpfn)

    #endif
#else
    #define pCMP(my_perl, a, b) (a, b)
    #define aCMP(my_perl, a, b) (a, b)
    #define sort(base, nel, elemsz, data, cmpfn) qsort(base, nel, elemsz, cmpfn)

#endif

static int cmp_asc pCMP(pTHX, const void *a, const void *b) {
    return +Perl_sv_cmp aCMP(aTHX, *(SV**)a, *(SV**)b);
}

static int cmp_desc pCMP(pTHX, const void *a, const void *b) {
    return -Perl_sv_cmp aCMP(aTHX, *(SV**)a, *(SV**)b);
}

MODULE = Sort::HashKeys		PACKAGE = Sort::HashKeys
 
PROTOTYPES: ENABLE
 
void
sort(...)
    PROTOTYPE: @
    ALIAS:
        reverse_sort = 1
    INIT:
        int i;
        SV **elems;
    CODE:
        if (!items) {
            XSRETURN_UNDEF;
        }
        if (items % 2 == 1) {
            XPUSHs(&PL_sv_undef);
            items++;
        }

        sort(&PL_stack_base[ax], items / 2, 2*sizeof (SV*), aTHX, ix ? cmp_desc : cmp_asc);

        XSRETURN(items);
