#ifndef __eff_math_fun_h_
#define __eff_math_fun_h_

#include <EXTERN.h>
#include <perl.h>

double log_gamma(double x);
double beta_ab(pTHX_ double a, double b, int k, int N);
double ibetai(pTHX_ double a, double b, double x);
double beta_cf(pTHX_ double x, double a, double b);

#endif
