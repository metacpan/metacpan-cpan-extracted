char* get_gsl_version ();

#ifndef PERLGSL_DIFFEQ_PARAMS_STRUCT
#define PERLGSL_DIFFEQ_PARAMS_STRUCT

struct params {
  int num;
  SV* eqn;
  SV* jac;
};

#endif

int diff_eqs (double t, const double y[], double f[], void *params);

int jacobian_matrix (double t, const double y[], double *dfdy, 
          double dfdt[], void *params);

/* c_ode_solver needs stack to be clear when called,
   I recommend `local @_;` before calling. */
SV* c_ode_solver
  (SV* eqn, SV* jac, double t1, double t2, int steps, int step_type_num,
    double h_init, const double h_max,
    double epsabs, double epsrel, double a_y, double a_dydt);
