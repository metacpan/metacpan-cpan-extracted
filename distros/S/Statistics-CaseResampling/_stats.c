#include "stats.h"
#include <math.h>

#define SWAP(a,b) tmp=(a);(a)=(b);(b)=tmp;

double
cs_select(double* sample, I32 n, U32 k) {
  U32 i, ir, j, l, mid;
  double a, tmp;

  l = 0;
  ir = n-1;
  while(1) {
    if (ir <= l+1) { 
      if (ir == l+1 && sample[ir] < sample[l]) {
	SWAP(sample[l], sample[ir]);
      }
      return sample[k];
    }
    else {
      mid = (l+ir) >> 1; 
      SWAP(sample[mid], sample[l+1]);
      if (sample[l] > sample[ir]) {
	SWAP(sample[l], sample[ir]);
      }
      if (sample[l+1] > sample[ir]) {
	SWAP(sample[l+1], sample[ir]);
      }
      if (sample[l] > sample[l+1]) {
	SWAP(sample[l], sample[l+1]);
      }
      i = l+1; 
      j = ir;
      a = sample[l+1]; 
      while(1) { 
	do i++; while (sample[i] < a); 
	do j--; while (sample[j] > a); 
	if (j < i)
          break; 
	SWAP(sample[i], sample[j]);
      } 
      sample[l+1] = sample[j]; 
      sample[j] = a;
      if (j >= k)
        ir = j-1; 
      if (j <= k)
        l = i;
    }
  }
}

double
cs_median(double* sample, I32 n)
{
  U32 k = n/2 - !(n & 1);
  return cs_select(sample, n, k);
}


double
cs_first_quartile(double* sample, I32 n)
{
  U32 k = (U32)((n/4) + 1);
  return cs_select(sample, n, k);
}


double
cs_third_quartile(double* sample, I32 n)
{
  U32 k = (U32)((n*3/4) + 1);
  return cs_select(sample, n, k);
}


double
cs_mean(double* sample, I32 n)
{
  I32 i;
  double sum = 0.;
  for (i = 0; i < n; ++i)
    sum += sample[i];
  return sum/(double)n;
}

void
do_resample(double* original, I32 n, struct mt* rdgen, double* dest)
{
  I32 rndElem;
  I32 i;
  for (i = 0; i < n; ++i) {
    rndElem = (I32) (mt_genrand(rdgen) * n);
    dest[i] = original[rndElem];
  }
}

/*
void
cs_sort(double arr[], I32 beg, I32 end)
{
  double t;
  if (end > beg + 1)
  {
    double piv = arr[beg];
    I32 l = beg + 1, r = end;
    while (l < r)
    {
      if (arr[l] <= piv)
        l++;
      else {
        t = arr[l];
        arr[l] = arr[--r];
        arr[r] = t;
      }
    }
    t = arr[--l];
    arr[l] = arr[beg];
    arr[beg] = t;
    cs_sort(arr, beg, l);
    cs_sort(arr, r, end);
  }
}
*/

/*
double
cs_median(double* sample, I32 n)
{
  cs_sort(sample, 0, n);
  if (n & 1) {
    return sample[n/2];
  }
  else {
    return 0.5*(sample[n/2-1]+sample[n/2]);
  }
}
*/


double
cs_approx_erf(double x)
{
  /*
   * const double a = ( 8./(3.*M_PI) )
   *                * (M_PI - 3.) / (4. - M_PI);
   */
  const double a = 0.147; /* better than the ~0.140 above */
  const double xsq = x*x;
  return
    (x < 0 ? -1. : 1.)
    * sqrt(
      1. - exp(
        -xsq * (4./M_PI + a*xsq) / (1. + a*xsq)
      )
    );
}


double
cs_approx_erf_inv(double x)
{
  const double a = 0.147; /* better than the ~0.140 above */
  const double b = log(1. - x*x);
  return
    (x < 0 ? -1. : 1.)
    * sqrt(
      (-2./(M_PI * a))
      - b/2.
      + sqrt(
        pow( 2./(M_PI*a) + b/2., 2. )
        - b/a
      )
    );
}


double
cs_alpha_to_nsigma(double alpha)
{
  return sqrt(2.) * cs_approx_erf_inv(1.-alpha);
}



double
cs_nsigma_to_alpha(double nsigma)
{
  return 1.-cs_approx_erf(nsigma/sqrt(2.));
}

