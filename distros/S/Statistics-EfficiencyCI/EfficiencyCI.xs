#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <float.h>
#include <math.h>
#include "eff_math_fun.h"

MODULE = Statistics::EfficiencyCI		PACKAGE = Statistics::EfficiencyCI		


void
efficiency_ci(k, N, conflevel = 0.683)
    int k
    int N
    double conflevel
  PREINIT:
    double mode = 0.0;
    double low = 0.0;
    double high = 0.0;
  PPCODE:
    efficiency_ci(aTHX_ k, N, conflevel, &mode, &low, &high);
    EXTEND(SP, 3);
    mPUSHn(mode);
    mPUSHn(low);
    mPUSHn(high);


void
log_gamma(x)
    double x
  PPCODE:
    dTARG;
    if (x <= 0
        && ( fabs(x - (int)x) <= DBL_EPSILON))
    {
      XSRETURN_UNDEF;
    }
    else {
      NV rv = log_gamma(x);
      SV *sv = sv_2mortal(newSVnv(rv));
      XPUSHs(sv);
      XSRETURN(1);
    }

double
beta_ab(double a, double b, int k, int N)
  CODE:
    RETVAL = beta_ab(aTHX_ a, b, k, N);
  OUTPUT: RETVAL

double
ibetai(double a, double b, double x)
  CODE:
    RETVAL = ibetai(aTHX_ a, b, x);
  OUTPUT: RETVAL

double
beta_cf(double x, double a, double b)
  CODE:
    RETVAL = beta_cf(aTHX_ x, a, b);
  OUTPUT: RETVAL

