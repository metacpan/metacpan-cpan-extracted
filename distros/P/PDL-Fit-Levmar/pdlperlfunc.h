#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "pdl.h"
#include "pdlcore.h"

// Don't remember why i called it DFP
typedef struct {
  SV * p_sv; // sv to pass directly to perl fit subs
  SV * d_sv;
  SV * x_sv;
  SV * t_sv;
  pdl * p_pdl; // the pdl pointer
  pdl * d_pdl;
  pdl * x_pdl;
  pdl * t_pdl;
  SV* perl_fit_func; // perl refs to user's fit and jac functions
  SV* perl_jac_func;
  int datatype;
} DFP;

void DFP_check(DFP **dat, int data_type, int m, int n, int nt, void *t );
void LEVFUNC(double *p, double *x, int m, int n, DFP *dat);
void JLEVFUNC(double *p, double *d, int m, int n, DFP *dat);
