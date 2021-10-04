#include "EXTERN.h"
#include "perl.h"
#include "pdl.h"
#include "pdlcore.h"

#define PDL PDL_LinearAlgebra_Real
extern Core *PDL;

#define PDL_LA_CALL_SV(val1p, val2p, sv_func) \
  dSP ; \
  long  retval; \
  int count; \
  ENTER ; \
  SAVETMPS ; \
  PUSHMARK(sp) ; \
  XPUSHs(sv_2mortal(newSVnv((double ) *val1p))); \
  XPUSHs(sv_2mortal(newSVnv((double ) *val2p))); \
  PUTBACK ; \
  count = perl_call_sv(sv_func, G_SCALAR); \
  SPAGAIN; \
  if (count != 1) \
    croak("Error calling perl function\n"); \
  retval = (long ) POPl ;  /* Return value */ \
  PUTBACK ; \
  FREETMPS ; \
  LEAVE ; \
  return retval;

static SV *fselect_func;
void fselect_func_set(SV* func) {
  fselect_func = func;
}
PDL_Long fselect_wrapper(float *wr, float *wi)
{
  PDL_LA_CALL_SV(wr, wi, fselect_func)
}

static SV*   dselect_func;
void dselect_func_set(SV* func) {
  dselect_func = func;
}
PDL_Long dselect_wrapper(double *wr, double *wi)
{
  PDL_LA_CALL_SV(wr, wi, dselect_func)
}

#define PDL_LA_CALL_GSV(val1p, val2p, val3p, sv_func) \
  dSP ; \
  long  retval; \
  int count; \
  ENTER ; \
  SAVETMPS ; \
  PUSHMARK(sp) ; \
  XPUSHs(sv_2mortal(newSVnv((double)  *val1p))); \
  XPUSHs(sv_2mortal(newSVnv((double)  *val2p))); \
  XPUSHs(sv_2mortal(newSVnv((double)  *val3p))); \
  PUTBACK ; \
  count = perl_call_sv(sv_func, G_SCALAR); \
  SPAGAIN; \
  if (count != 1) \
    croak("Error calling perl function\n"); \
  retval = (long ) POPl ;  /* Return value */ \
  PUTBACK ; \
  FREETMPS ; \
  LEAVE ; \
  return retval;

static SV*   fgselect_func;
void fgselect_func_set(SV* func) {
  fgselect_func = func;
}
PDL_Long fgselect_wrapper(float *zr, float *zi, float *d)
{
  PDL_LA_CALL_GSV(zr, zi, d, fgselect_func)
}

static SV*   dgselect_func;
void dgselect_func_set(SV* func) {
  dgselect_func = func;
}
PDL_Long dgselect_wrapper(double *zr, double *zi, double *d)
{
  PDL_LA_CALL_GSV(zr, zi, d, dgselect_func)
}

float ftrace(int n, float *mat)
{
  int i;
  float sum = mat[0];
  for (i = 1; i < n; i++)
	sum += mat[i*(n+1)];
  return sum;
}

double dtrace(int n, double *mat)
{
  int i;
  double sum = mat[0];
  for (i = 1; i < n; i++)
	sum += mat[i*(n+1)];
  return sum;
}
