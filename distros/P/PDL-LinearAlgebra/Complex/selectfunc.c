#include "EXTERN.h"
#include "perl.h"
#include "pdl.h"
#include "pdlcore.h"

#define PDL PDL_LinearAlgebra_Complex
extern Core *PDL;

#define PDL_LA_COMPLEX_INIT_PUSH(pdl, type, valp, svpdl) \
   pdl = PDL->pdlnew(); \
   PDL->setdims (pdl, dims, 2); \
   pdl->datatype = type; \
   pdl->data = valp; \
   pdl->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED; \
   ENTER;   SAVETMPS;   PUSHMARK(sp); \
    svpdl = sv_newmortal(); \
    PDL->SetSV_PDL(svpdl, pdl); \
    svpdl = sv_bless(svpdl, bless_stash); /* bless in PDL::Complex  */ \
    XPUSHs(svpdl); \
   PUTBACK;

#define PDL_LA_COMPLEX_UNINIT(pdl) \
   PDL->setdims (pdl, odims, 0); \
   pdl->state &= ~ (PDL_ALLOCATED |PDL_DONTTOUCHDATA); \
   pdl->data=NULL;

#define PDL_LA_CALL_SV(type, valp, sv_func) \
   dSP; \
   int count; \
   long ret; \
   SV *pdl1; \
   HV *bless_stash; \
   pdl *pdl; \
   PDL_Indx odims[1]; \
   PDL_Indx dims[] = {2,1}; \
   bless_stash = gv_stashpv("PDL::Complex", 0); \
   PDL_LA_COMPLEX_INIT_PUSH(pdl, type, valp, pdl1) \
   count = perl_call_sv(sv_func, G_SCALAR); \
   SPAGAIN; \
   if (count !=1) \
      croak("Error calling perl function\n"); \
   /* For pdl_free */ \
   odims[0] = 0; \
   PDL_LA_COMPLEX_UNINIT(pdl) \
   ret = (long ) POPl ; \
   PUTBACK ;   FREETMPS ;   LEAVE ; \
   return ret;

static SV *fselect_func;
void fselect_func_set(SV* func) {
  fselect_func = func;
}
PDL_Long fselect_wrapper(float *p)
{
  PDL_LA_CALL_SV(PDL_F, p, fselect_func)
}

static SV*   dselect_func;
void dselect_func_set(SV* func) {
  dselect_func = func;
}
PDL_Long dselect_wrapper(double *p)
{
  PDL_LA_CALL_SV(PDL_D, p, dselect_func)
}

#define PDL_LA_CALL_GSV(type, val1p, val2p, sv_func) \
   dSP; \
   int count; \
   long ret; \
   SV *svpdl1, *svpdl2; \
   HV *bless_stash; \
   pdl *pdl1, *pdl2; \
   PDL_Indx odims[1]; \
   PDL_Indx dims[] = {2,1}; \
   bless_stash = gv_stashpv("PDL::Complex", 0); \
   PDL_LA_COMPLEX_INIT_PUSH(pdl1, type, val1p, svpdl1) \
   PDL_LA_COMPLEX_INIT_PUSH(pdl2, type, val2p, svpdl2) \
   count = perl_call_sv(sv_func, G_SCALAR); \
   SPAGAIN; \
   if (count !=1) \
      croak("Error calling perl function\n"); \
   /* For pdl_free */ \
   odims[0] = 0; \
   PDL_LA_COMPLEX_UNINIT(pdl1) \
   PDL_LA_COMPLEX_UNINIT(pdl2) \
   ret = (long ) POPl ; \
   PUTBACK ;   FREETMPS ;   LEAVE ; \
   return ret;

static SV*   fgselect_func;
void fgselect_func_set(SV* func) {
  fgselect_func = func;
}
PDL_Long fgselect_wrapper(float *p, float *q)
{
  PDL_LA_CALL_GSV(PDL_F, p, q, fgselect_func)
}

static SV*   dgselect_func;
void dgselect_func_set(SV* func) {
  dgselect_func = func;
}
PDL_Long dgselect_wrapper(double *p, double *q)
{
  PDL_LA_CALL_GSV(PDL_D, p, q, dgselect_func)
}

void cftrace(int n, void *a1, void *a2)
{
  float *mat = a1, *res = a2;
  int i;
  res[0] = mat[0];
  res[1] = mat[1];
  for (i = 1; i < n; i++)
  {
	res[0] += mat[(i*(n+1))*2];
	res[1] += mat[(i*(n+1))*2+1];
  }
}

void cdtrace(int n, void *a1, void *a2)
{
  double *mat = a1, *res = a2;
  int i;
  res[0] = mat[0];
  res[1] = mat[1];
  for (i = 1; i < n; i++)
  {
	res[0] += mat[(i*(n+1))*2];
	res[1] += mat[(i*(n+1))*2+1];
  }
}
