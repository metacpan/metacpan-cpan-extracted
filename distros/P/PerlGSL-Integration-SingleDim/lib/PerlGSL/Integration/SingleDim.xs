#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gsl/gsl_integration.h>

#define NEED_sv_2pv_flags
#include "ppport.h"

struct params {
  SV* eqn;
};

double integrand(double x, void *params) {

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
    croak("Integrand closure did not return a value");

  SPAGAIN;

  val = POPn;

  PUTBACK;
  FREETMPS;
  LEAVE;

  return val;
}

AV* c_int_1d(SV* eqn, SV* lower, SV* upper, int engine, 
               double epsabs, double epsrel, int calls) {

  int i, dim;
  double xl, xu, res, err;
  size_t dim_size, calls_size;
  struct params myparams;
  gsl_function F;
  AV* ret = newAV();
  sv_2mortal((SV*)ret);

  xl = SvNV(lower);
  xu = SvNV(upper);

  calls_size = (size_t)calls;
  gsl_integration_workspace * w
         = gsl_integration_workspace_alloc(calls_size);

  /* store the equation to pass to mock function */
  myparams.eqn = eqn;
  F.function = &integrand;
  F.params = &myparams;

  switch (engine) {
    case 0:
      gsl_integration_qng(&F, xl, xu, epsabs, epsrel, &res, &err, &calls_size);
      break;
    case 1:
      gsl_integration_qag(&F, xl, xu, epsabs, epsrel, calls_size, GSL_INTEG_GAUSS21, w, &res, &err);
      break;
    case 2:
      gsl_integration_qagi(&F, epsabs, epsrel, calls_size, w, &res, &err);
      break;
    case 3:
      gsl_integration_qagiu(&F, xl, epsabs, epsrel, calls_size, w, &res, &err);
      break;
    case 4:
      gsl_integration_qagil(&F, xu, epsabs, epsrel, calls_size, w, &res, &err);
      break;
    default:
      croak("Unknown integrator engine");
  }

  av_push(ret, newSVnv(res));
  av_push(ret, newSVnv(err));

  /* cleanup */
  gsl_integration_workspace_free(w);

  return ret;
}

MODULE = PerlGSL::Integration::SingleDim	PACKAGE = PerlGSL::Integration::SingleDim	

PROTOTYPES: DISABLE

AV *
c_int_1d (eqn, lower, upper, engine, epsabs, epsrel, calls)
	SV*	eqn
	SV*	lower
	SV*	upper
	int	engine
	double	epsabs
	double	epsrel
	int	calls

