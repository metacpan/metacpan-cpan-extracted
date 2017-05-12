#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pv_flags
#include "ppport.h"

#include <gsl/gsl_errno.h>
#include <gsl/gsl_odeiv2.h>
#include <gsl/gsl_matrix.h>
#include <gsl/gsl_version.h>

#include "container.h"
#include "common.h"

char* get_gsl_version () {
  return GSL_VERSION;
}

int diff_eqs (double t, const double y[], double f[], void *params) {

  dSP;

  SV* eqn = ((struct params *)params)->eqn;
  int num = ((struct params *)params)->num;
  int count;
  int i;

  SV* holder;
  int badfunc = 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);

  XPUSHs(sv_2mortal(newSVnv(t)));

  for (i = 1; i <= num; i++) {
    XPUSHs(sv_2mortal(newSVnv(y[i-1])));
  }
  PUTBACK;

  count = call_sv(eqn, G_ARRAY);
  if (count != num) 
    warn("Equation did not return the specified number of values");

  SPAGAIN;

  for (i = 1; i <= num; i++) {
    /* Get return */
    holder = POPs;

    /* Test for numeric return */
    if (looks_like_number(holder)) {
      /* if numeric return then save and move on */
      f[num-i] = SvNV(holder);
    } else {
      /* if non numeric return store 0.0 and set badfunc
         N.B. if I was sure about my C mem management I would just clear then break */
      if (badfunc == 0) /* only warn once */
        warn("'ode_solver' has encountered a bad return value\n");

      f[num-i] = 0.0;
      badfunc = 1;
    }
    
  }
  PUTBACK;

  FREETMPS;
  LEAVE;

  if (badfunc)
    return GSL_EBADFUNC;

  return GSL_SUCCESS;

}

int jacobian_matrix (double t, const double y[], double *dfdy, 
          double dfdt[], void *params) {

  dSP;

  SV* jac = ((struct params *)params)->jac;
  int num = ((struct params *)params)->num;
  int count;
  int i;
  int row;
  int column;

  SV* avr_jacobian;
  SV* avr_dfdt;

  SV* avr_row;
  SV* holder;

  gsl_matrix_view dfdy_mat = gsl_matrix_view_array (dfdy, num, num);
  gsl_matrix * m = &dfdy_mat.matrix; 

  int badfunc = 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);

  XPUSHs(sv_2mortal(newSVnv(t)));

  for (i = 1; i <= num; i++) {
    XPUSHs(sv_2mortal(newSVnv(y[i-1])));
  }
  PUTBACK;

  count = call_sv(jac, G_ARRAY);
  if (count != 2) 
    warn("Jacobian code reference did not return two items (arrayrefs)");

  SPAGAIN;

  avr_dfdt = POPs;
  avr_jacobian = POPs;

  PUTBACK;

  count = av_len((AV*)SvRV(avr_jacobian)) + 1;
  if (count != num)
    warn("Jacobian array reference does not contain the specified number of rows (expected %i, got %i)\n", num, count); 

  count = av_len((AV*)SvRV(avr_dfdt)) + 1;
  if (count != num)
    warn("dfdt array reference does not contain the specified number of values (expected %i, got %i)\n", num, count);

  /* pack Jacobian values into a GSL matrix */
  for (row = 0; row < num; row++) {
    /* get array reference to row-1 in 0 base notation */
    avr_row = av_shift((AV*)SvRV(avr_jacobian));

    count = av_len((AV*)SvRV(avr_row)) + 1;
    if (count != num)
      warn("Jacobian array reference row %i does not contain the specified number of columns (expected %i, got %i)\n", row, num, count);

    for (column = 0; column < num; column++) {
      /* get value at (row-1, column-1) in 0 base notation */
      holder = av_shift((AV*)SvRV(avr_row));

      /* Test for numeric return */
      if (looks_like_number(holder)) {
        /* if numeric return then save and move on */
        gsl_matrix_set (m, row, column, SvNV(holder));
      } else {
        /* if non numeric return store 0.0 and set badfunc
           N.B. if I was sure about my C mem management I would just clear then break */
        if (badfunc == 0) /* only warn once */
          warn("'ode_solver' has encountered a bad return value (in Jacobian at (%i, %i))\n", row, column);

        gsl_matrix_set (m, row, column, 0.0);
        badfunc = 1;
      }
    }
  }

  /* pack dfdt */
  for (i = 1; i <= num; i++) {
    /* Get next value */
    holder = av_shift((AV*)SvRV(avr_dfdt));

    /* Test for numeric return */
    if (looks_like_number(holder)) {
      /* if numeric return then save and move on */
      dfdt[num-i] = SvNV(holder);
    } else {
      /* if non numeric return store 0.0 and set badfunc
         N.B. if I was sure about my C mem management I would just clear then break */
      if (badfunc == 0) /* only warn once */
        warn("'ode_solver' has encountered a bad return value (in Jacobian dfdt)\n");

      dfdt[num-i] = 0.0;
      badfunc = 1;
    }
    
  }

  FREETMPS;
  LEAVE;

  if (badfunc)
    return GSL_EBADFUNC;

  return GSL_SUCCESS;

}

/* c_ode_solver needs stack to be clear when called,
   I recommend `local @_;` before calling. */
SV* c_ode_solver
  (SV* eqn, SV* jac, double t1, double t2, int steps, int step_type_num,
    double h_init, const double h_max,
    double epsabs, double epsrel, double a_y, double a_dydt) {

  dSP;

  int num;
  int i;
  double t = t1;
  double * y;
  SV* ret;
  const gsl_odeiv2_step_type * step_type;
  int has_jacobian = SvOK(jac);

  double step_size = (t2 - t1) / steps;

  /* create step_type_num, selected with $opt->{type}
     then .pm converts user choice to number */
  switch (step_type_num) {
    case 1:
      step_type = gsl_odeiv2_step_rk2;
      break;
    case 2:
      step_type = gsl_odeiv2_step_rk4;
      break;
    case 3:
      step_type = gsl_odeiv2_step_rkf45;
      break;
    case 4:
      step_type = gsl_odeiv2_step_rkck;
      break;
    case 5:
      step_type = gsl_odeiv2_step_rk8pd;
      break;
    case 6:
      if (has_jacobian == 0) 
        warn ("The specified step type requires the Jacobian");
      step_type = gsl_odeiv2_step_rk1imp;
      break;
    case 7:
      if (has_jacobian == 0) 
        warn ("The specified step type requires the Jacobian");
      step_type = gsl_odeiv2_step_rk2imp;
      break;
    case 8:
      if (has_jacobian == 0) 
        warn ("The specified step type requires the Jacobian");
      step_type = gsl_odeiv2_step_rk4imp;
      break;
    case 9:
      if (has_jacobian == 0) 
        warn ("The specified step type requires the Jacobian");
      step_type = gsl_odeiv2_step_bsimp;
      break;
    case 10:
      step_type = gsl_odeiv2_step_msadams;
      break;
    case 11:
      if (has_jacobian == 0) 
        warn ("The specified step type requires the Jacobian");
      step_type = gsl_odeiv2_step_msbdf;
      break;
    default:
      warn("Could not determine step type, using rk8pd");
      step_type = gsl_odeiv2_step_rk8pd;
  }

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);

  num = call_sv(eqn, G_ARRAY|G_NOARGS);

  Newx(y, num, double);
  if(y == NULL) 
    croak ("Failed to allocate memory to 'y' in 'c_ode_solver'");

  SPAGAIN;

  for (i = 1; i <= num; i++) {
    y[num-i] = POPn;
  }
  PUTBACK;

  FREETMPS;
  LEAVE;

  ret = make_container(num, steps);
  store_data(ret, num, t, y);

  struct params myparams;
  myparams.num = num;
  myparams.eqn = eqn;
  myparams.jac = jac;

  gsl_odeiv2_system sys = {diff_eqs, NULL, num, &myparams};
  if (has_jacobian != 0) 
    sys.jacobian = jacobian_matrix;
     
  gsl_odeiv2_driver * d = 
    gsl_odeiv2_driver_alloc_standard_new (
      &sys, step_type, h_init, epsabs, epsrel, a_y, a_dydt
    );

  if ( h_max != 0 )
    gsl_odeiv2_driver_set_hmax(d, h_max);
     
  for (i = 1; i <= steps; i++)
    {
      double ti = i * step_size + t1;
      int status = gsl_odeiv2_driver_apply (d, &t, ti, y);
     
      if (status != GSL_SUCCESS)
        {
          if (status != GSL_EBADFUNC) 
            warn("error, return value=%d\n", status);
          break;
        }

      /* At this point I envision that PDL could be used to store the data
         rather than creating tons of SVs. Of course the current behavior
         should remain for those systems without PDL */

      store_data(ret, num, t, y);
    }
     
  gsl_odeiv2_driver_free(d);
  Safefree(y);

  return ret;
}

