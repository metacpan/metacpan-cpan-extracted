#ifndef __eff_ci_h_
#define __eff_ci_h_

#include <EXTERN.h>
#include <perl.h>


void efficiency_ci(pTHX_ int k, int N, double conflevel, double* mode, double* low, double* high);

int use_exceptions(pTHX);

#endif
