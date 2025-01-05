#include "EXTERN.h"
#include "perl.h"
#include "pdl.h"
#include "pdlcore.h"

#define PDL PDL_LinearAlgebra_Complex
extern Core *PDL;

#define PDL_LA_COMPLEX_INIT_PUSH(pdlvar, type, valp, svpdl) \
   pdl *pdlvar = PDL->pdlnew(); \
   PDL->setdims(pdlvar, dims, ndims); \
   pdlvar->datatype = type + type_add; \
   pdlvar->data = valp; \
   pdlvar->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED; \
   ENTER;   SAVETMPS;   PUSHMARK(sp); \
    SV *svpdl = sv_newmortal(); \
    PDL->SetSV_PDL(svpdl, pdlvar); \
    svpdl = sv_bless(svpdl, bless_stash); \
    XPUSHs(svpdl); \
   PUTBACK;

#define PDL_LA_COMPLEX_UNINIT(pdl) \
   PDL->setdims(pdl, odims, sizeof(odims)/sizeof(odims[0])); \
   pdl->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA); \
   pdl->data=NULL;

/* replace BLAS one so don't terminate on bad input */
int xerbla_(char *sub, int *info) { return 0; }

#define SEL_FUNC2(letter, letter2, type, pdl_type, args, init, uninit) \
  static SV* letter ## letter2 ## select_func = NULL; \
  void letter ## letter2 ## select_func_set(SV* func) { \
    if (letter ## letter2 ## select_func) SvREFCNT_dec(letter ## letter2 ## select_func); \
    SvREFCNT_inc(letter ## letter2 ## select_func = func); \
  } \
  PDL_Long letter ## letter2 ## select_wrapper args \
  { \
    dSP; \
    PDL_Indx odims[] = {0}; \
    PDL_Indx *dims = NULL; \
    PDL_Indx ndims = 0; \
    int type_add = PDL_CF - PDL_F; \
    HV *bless_stash = gv_stashpv("PDL", 0); \
    init \
    int count = perl_call_sv(letter ## select_func, G_SCALAR); \
    SPAGAIN; \
    uninit \
    if (count !=1) croak("Error calling perl function\n"); \
    long ret = (long ) POPl ; \
    PUTBACK ;   FREETMPS ;   LEAVE ; \
    return ret; \
  }

#define SEL_FUNC(letter, type, pdl_type) \
  SEL_FUNC2(letter, , type, pdl_type, (type *p), \
    PDL_LA_COMPLEX_INIT_PUSH(pdl, pdl_type, p, svpdl), \
    PDL_LA_COMPLEX_UNINIT(pdl) \
  )
SEL_FUNC(f, float, PDL_F)
SEL_FUNC(d, double, PDL_D)

#define GSEL_FUNC(letter, type, pdl_type) \
  SEL_FUNC2(letter, g, type, pdl_type, (type *p, type *q), \
    PDL_LA_COMPLEX_INIT_PUSH(pdl1, pdl_type, p, svpdl1) \
    PDL_LA_COMPLEX_INIT_PUSH(pdl2, pdl_type, q, svpdl2), \
    PDL_LA_COMPLEX_UNINIT(pdl1) \
    PDL_LA_COMPLEX_UNINIT(pdl2) \
  )
GSEL_FUNC(f, float, PDL_F)
GSEL_FUNC(d, double, PDL_D)

#define TRACE(letter, type) \
  void c ## letter ## trace(int n, void *a1, void *a2) { \
    type *mat = a1, *res = a2; \
    PDL_Indx i; \
    res[0] = mat[0]; \
    res[1] = mat[1]; \
    for (i = 1; i < n; i++) \
    { \
          res[0] += mat[(i*(n+1))*2]; \
          res[1] += mat[(i*(n+1))*2+1]; \
    } \
  }
TRACE(f, float)
TRACE(d, double)
