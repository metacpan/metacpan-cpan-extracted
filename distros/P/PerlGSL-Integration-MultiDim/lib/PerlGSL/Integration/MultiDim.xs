#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <gsl/gsl_math.h>
#include <gsl/gsl_monte.h>
#include <gsl/gsl_monte_miser.h>

#define NEED_sv_2pv_flags
#include "ppport.h"

struct params {
  SV* eqn;
};

double integrand(double *x, size_t size, void *params) {

  dSP;

  SV* eqn;
  int i, count, dim;
  double val;

  eqn = ((struct params *)params)->eqn;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);

  dim = (int)size;
  for(i=0; i<dim; i++) {
    XPUSHs(sv_2mortal(newSVnv(x[i])));
  }

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

AV* c_int_multi(SV* eqn, AV* lower, AV* upper, int calls) {

  int i, dim;
  double * xl;
  double * xu;
  double res, err;
  size_t dim_size, calls_size;
  const gsl_rng_type *T;
  gsl_rng *r;
  struct params myparams;
  gsl_monte_function F;
  AV* ret = newAV();
  sv_2mortal((SV*)ret);

  /* deal with lower and upper limits */

  dim = av_len(lower) + 1;
  if((av_len(upper)+1) != dim)
    croak("dimension mismatch");

  Newx(xl, dim, double);
  if(xl == NULL) 
    croak ("Failed to allocate memory to 'xl' in 'c_int_multi'");
  Newx(xu, dim, double);
  if(xu == NULL) 
    croak ("Failed to allocate memory to 'xu' in 'c_int_multi'");

  for (i=0; i<dim; i++) {
    xl[i] = SvNV(*av_fetch(lower, i, 0));
    xu[i] = SvNV(*av_fetch(upper, i, 0));
  }

  /* store the equation to pass to mock function */
  myparams.eqn = eqn;

  /* setup the random number generator */
  gsl_rng_env_setup();
  T = gsl_rng_default;
  r = gsl_rng_alloc(T);

  /* setup the integrator */
  dim_size = (size_t)dim;
  calls_size = (size_t)calls;

  F.f = &integrand;
  F.dim = dim_size;
  F.params = &myparams;
  gsl_monte_miser_state *s = gsl_monte_miser_alloc(dim_size);

  gsl_monte_miser_integrate(&F, xl, xu, dim_size, calls_size, r, s, &res, &err);

  av_push(ret, newSVnv(res));
  av_push(ret, newSVnv(err));

  /* cleanup */
  gsl_monte_miser_free(s);
  gsl_rng_free(r);
  Safefree(xl);
  Safefree(xu);

  return ret;
}

MODULE = PerlGSL::Integration::MultiDim	PACKAGE = PerlGSL::Integration::MultiDim	

PROTOTYPES: DISABLE

AV *
c_int_multi (eqn, lower, upper, calls)
	SV*	eqn
	AV*	lower
	AV*	upper
	int	calls
