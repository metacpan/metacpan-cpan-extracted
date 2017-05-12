#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gsl/gsl_roots.h>
#include <gsl/gsl_errno.h>

#define NEED_sv_2pv_flags
#include "ppport.h"

struct params {
  SV* eqn;
};

double function(double x, void *params) {

  dSP;

  SV* eqn;
  int count;
  double val;

  eqn = ((struct params *)params)->eqn;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);

  XPUSHs(sv_2mortal(newSVnv(x)));

  PUTBACK;

  count = call_sv(eqn, G_SCALAR);
  if (count != 1) 
    croak("Supplied function (closure) did not return a value");

  SPAGAIN;

  val = POPn;

  PUTBACK;
  FREETMPS;
  LEAVE;

  return val;
}

double c_findroot_1d(SV* eqn, double x_lo, double x_hi, 
                       int max_iter, double epsabs, double epsrel) {
  int status;
  int iter = 0;
  const gsl_root_fsolver_type *T;
  gsl_root_fsolver *s;
  double r;
  gsl_function F;
  struct params myparams;

  myparams.eqn = eqn;
  F.function = &function;
  F.params = &myparams;
     
  T = gsl_root_fsolver_brent;
  s = gsl_root_fsolver_alloc (T);
  gsl_root_fsolver_set (s, &F, x_lo, x_hi);
     
   
  do {

    iter++;
    status = gsl_root_fsolver_iterate (s);
    r = gsl_root_fsolver_root (s);
    x_lo = gsl_root_fsolver_x_lower (s);
    x_hi = gsl_root_fsolver_x_upper (s);
    status = gsl_root_test_interval (x_lo, x_hi, epsabs, epsrel);
  
  } while (status == GSL_CONTINUE && iter < max_iter);
     
  gsl_root_fsolver_free (s);
     
  return r;
}

MODULE = PerlGSL::RootFinding::SingleDim	PACKAGE = PerlGSL::RootFinding::SingleDim	

PROTOTYPES: DISABLE

double
c_findroot_1d (eqn, x_lo, x_hi, max_iter, epsabs, epsrel)
	SV*	eqn
	double	x_lo
	double	x_hi
	int	max_iter
	double	epsabs
	double	epsrel
