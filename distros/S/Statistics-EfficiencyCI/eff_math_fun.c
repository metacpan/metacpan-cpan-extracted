#include "eff_math_fun.h"
#include <stdio.h>
#include <math.h>

#include "eff_ci.h"

#ifndef DEBUG
# define DEBUG 0
#endif

#define MY_kDBL_MAX (1.79769e+308)
#define MY_kMAXLGM (2.556348e305)
#define MY_kLS2PI (0.91893853320467274178)

/* Logarithm of gamma function */
/* A[]: Stirling's formula expansion of log gamma
 * B[], C[]: log gamma function between 2 and 3
 */

static double A[5] = {
   8.11614167470508450300E-4,
   -5.95061904284301438324E-4,
   7.93650340457716943945E-4,
   -2.77777777730099687205E-3,
   8.33333333333331927722E-2
};

static double B[6] = {
   -1.37825152569120859100E3,
   -3.88016315134637840924E4,
   -3.31612992738871184744E5,
   -1.16237097492762307383E6,
   -1.72173700820839662146E6,
   -8.53555664245765465627E5
};

static double C[6] = {
/* 1.00000000000000000000E0, */
   -3.51815701436523470549E2,
   -1.70642106651881159223E4,
   -2.20528590553854454839E5,
   -1.13933444367982507207E6,
   -2.53252307177582951285E6,
   -2.01889141433532773231E6
};

double polynomial_1eval(double x, double* a, unsigned int N);
double polynomial_eval(double x, double* a, unsigned int N);

/*
 * calculates a value of a polynomial of the form:
 * a[0]x^N+a[1]x^(N-1) + ... + a[N]
*/
double
polynomial_eval(double x, double* a, unsigned int N)
{
  double pom;
  unsigned int i;
  if (N==0)
    return a[0];
  else {
    pom = a[0];
    for (i=1; i <= N; i++)
      pom = pom *x + a[i];
    return pom;
  }
}

/*
 * calculates a value of a polynomial of the form:
 * x^N+a[0]x^(N-1) + ... + a[N-1]
*/
double
polynomial_1eval(double x, double* a, unsigned int N)
{
  double pom;
  unsigned int i;
  if (N==0)
    return a[0];
  else {
    pom = x + a[0];
    for (i=1; i < N; i++)
      pom = pom *x + a[i];
    return pom;
  }
}



double
log_gamma(double x)
{
  double p, q, u, w, z;
  int i;

  int sgngam = 1;

  if (x >= MY_kDBL_MAX)
    return(MY_kDBL_MAX);

  if( x < -34.0 )
  {
    q = -x;
    w = log_gamma(q);
    p = floor(q);
    if( p==q )//_unur_FP_same(p,q)
      return(MY_kDBL_MAX);
    i = (int) p;
    if( (i & 1) == 0 )
      sgngam = -1;
    else
      sgngam = 1;
    z = q - p;
    if( z > 0.5 )
    {
      p += 1.0;
      z = p - q;
    }
    z = q * sin( M_PI * z );
    if( z == 0 )
      return(MY_kDBL_MAX);
    z = log(M_PI) - log( z ) - w;
    return( z );
  }

  if( x < 13.0 )
  {
    z = 1.0;
    p = 0.0;
    u = x;
    while( u >= 3.0 )
    {
      p -= 1.0;
      u = x + p;
      z *= u;
    }
    while( u < 2.0 )
    {
      if( u == 0 )
        return (MY_kDBL_MAX);
      z /= u;
      p += 1.0;
      u = x + p;
    }
    if( z < 0.0 )
    {
      sgngam = -1;
      z = -z;
    }
    else
      sgngam = 1;
    if( u == 2.0 )
      return( log(z) );
    p -= 2.0;
    x = x + p;
    p = x * polynomial_eval(x, B, 5 ) / polynomial_1eval( x, C, 6);
    return( log(z) + p );
  }

  if( x > MY_kMAXLGM )
    return( sgngam * MY_kDBL_MAX );

  q = ( x - 0.5 ) * log(x) - x + MY_kLS2PI;
  if( x > 1.0e8 )
    return( q );

  p = 1.0/(x*x);
  if( x >= 1000.0 )
    q += ((   7.9365079365079365079365e-4 * p
          - 2.7777777777777777777778e-3) *p
        + 0.0833333333333333333333) / x;
  else
    q += polynomial_eval( p, A, 4 ) / x;
  return( q );
}


double
beta_ab(pTHX_ double a, double b, int k, int N)
{
  int c1, c2;
  /* Calculates the fraction of the area under the
   * curve x^k*(1-x)^(N-k) between x=a and x=b */

  if (a == b) return 0;    /* don't bother integrating over zero range */
  c1 = k+1;
  c2 = N-k+1;
  return ibetai(aTHX_ c1,c2,b)-ibetai(aTHX_ c1,c2,a);
}

double
ibetai(pTHX_ double a, double b, double x)
{
  /* Calculates the incomplete beta function  I_x(a,b); this is
   * the incomplete beta function divided by the complete beta function */

  double bt;
  if (x < 0.0 || x > 1.0) {
    const char *err = "ibetai: Illegal x in routine ibetai: x = %g";
    if (use_exceptions(aTHX))
      croak(err, x);
    else
      warn(err, x);
    return 0;
  }
  if (x == 0.0 || x == 1.0)
    bt=0.0;
  else
    bt=exp(log_gamma(a+b)-log_gamma(a)-log_gamma(b)+a*log(x)+b*log(1.0-x));

  if (x < (a+1.0)/(a+b+2.0))
    return bt*beta_cf(aTHX_ x,a,b)/a;
  else
    return 1.0-bt*beta_cf(aTHX_ 1-x,b,a)/b;
}


double beta_cf(pTHX_ double x, double a, double b)
{
  /* Continued fraction evaluation by modified Lentz's method
   * used in calculation of incomplete Beta function. */

  const int itmax = 5000;
  const double eps = 3.e-14;
  const double fpmin = 1.e-30;

  int m, m2;
  double aa, c, d, del, qab, qam, qap;
  double h;

  qab = a+b;
  qap = a+1.0;
  qam = a-1.0;
  c = 1.0;
  d = 1.0 - qab*x/qap;

  if (fabs(d) < fpmin)
    d = fpmin;

  d = 1.0/d;
  h = d;
  for (m = 1; m <= itmax; m++) {
    m2 = m * 2;
    aa = m * (b-m) * x / ((qam + m2) * (a + m2));
    d = 1.0 + aa * d;
    if (fabs(d) < fpmin)
      d = fpmin;
    c = 1 + aa / c;
    if (fabs(c) < fpmin)
      c = fpmin;
    d = 1.0/d;
    h *= d*c;
    aa = -(a+m) * (qab +m) * x / ((a+m2)*(qap+m2));
    d = 1.0 + aa*d;
    if (fabs(d) < fpmin)
      d = fpmin;
    c = 1.0 + aa/c;
    if (fabs(c) < fpmin)
      c = fpmin;
    d = 1.0/d;
    del = d*c;
    h *= del;
    if (fabs(del-1) <= eps)
      break;
  }

  if (DEBUG && m > itmax) {
    const char *err = "beta_cf: a or b too big, or itmax too small, a=%g, b=%g, x=%g, h=%g, itmax=%d";
    if (use_exceptions(aTHX))
      croak(err, a,b,x,h,itmax);
    else
      warn(err, a,b,x,h,itmax);
  }
  return h;
}


#undef MY_kDBL_MAX
#undef MY_kMAXLGM
#undef MY_kLS2PI

