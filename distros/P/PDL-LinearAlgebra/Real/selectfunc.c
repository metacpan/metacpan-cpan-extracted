#include "EXTERN.h"
#include "perl.h"
#include "pdl.h"
#include "pdlcore.h"

#define PDL PDL_LinearAlgebra_Real
extern Core *PDL;

/* replace BLAS one so don't terminate on bad input */
int xerbla_(char *sub, int *info) { return 0; }

#define SEL_FUNC2(letter, letter2, type, args, push) \
  static SV* letter ## letter2 ## select_func; \
  void letter ## letter2 ## select_func_set(SV* func) { \
    letter ## letter2 ## select_func = func; \
  } \
  PDL_Long letter ## letter2 ## select_wrapper args \
  { \
    dSP ; \
    ENTER ; \
    SAVETMPS ; \
    PUSHMARK(sp) ; \
    push \
    PUTBACK ; \
    int count = perl_call_sv(letter ## select_func, G_SCALAR); \
    SPAGAIN; \
    if (count != 1) croak("Error calling perl function\n"); \
    long retval = (long ) POPl ;  /* Return value */ \
    PUTBACK ; \
    FREETMPS ; \
    LEAVE ; \
    return retval; \
  }

#define SEL_FUNC(letter, type) \
  SEL_FUNC2(letter, , type, (type *wr, type *wi), \
    XPUSHs(sv_2mortal(newSVnv((double ) *wr))); \
    XPUSHs(sv_2mortal(newSVnv((double ) *wi))); \
  )
SEL_FUNC(f, float)
SEL_FUNC(d, double)

#define GSEL_FUNC(letter, type) \
  SEL_FUNC2(letter, g, type, (type *zr, type *zi, type *d), \
    XPUSHs(sv_2mortal(newSVnv((double) *zr))); \
    XPUSHs(sv_2mortal(newSVnv((double) *zi))); \
    XPUSHs(sv_2mortal(newSVnv((double) *d))); \
  )
GSEL_FUNC(f, float)
GSEL_FUNC(d, double)

#define TRACE(letter, type) \
  type letter ## trace(int n, type *mat) { \
    PDL_Indx i; \
    type sum = mat[0]; \
    for (i = 1; i < n; i++) \
          sum += mat[i*(n+1)]; \
    return sum; \
  }
TRACE(f, float)
TRACE(d, double)
