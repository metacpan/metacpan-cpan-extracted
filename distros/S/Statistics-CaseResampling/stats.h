#ifndef _S_CS_STATS_H_
#define _S_CS_STATS_H_
#ifdef _MSC_VER
#  define _USE_MATH_DEFINES
#endif

#include "EXTERN.h"
#include "perl.h"

#include "mt.h"

#define SWAP(a,b) tmp=(a);(a)=(b);(b)=tmp;

/* O(n) selection algorithm selecting the kth value from the sample of size n */
double cs_select(double* sample, I32 n, U32 k);

/* fast median in O(n) using selection (median == second quartile) */
double cs_median(double* sample, I32 n);

/* fast first quartile (25%) in O(n) using selection */
double cs_first_quartile(double* sample, I32 n);

/* fast third quartile (75%) in O(n) using selection */
double cs_third_quartile(double* sample, I32 n);

/* run-of-the-mill mean */
double cs_mean(double* sample, I32 n);

/* resample the sample into the provided destination array (doesn't malloc for you!) */
void do_resample(double* original, I32 n, struct mt* rdgen, double* dest);

/* an unoptimized quicksort implementation. Currently not used */
/* void cs_sort(double arr[], I32 beg, I32 end); */

/* median using the unoptimized quicksort. Currently not used */
/* double cs_median(double* sample, I32 n)  */


/* an approximate error function and its inverse
 * Implemented after
 * Winitzki, Sergei (6 February 2008).
 * "A handy approximation for the error function and its inverse" (PDF). 
 * http://homepages.physik.uni-muenchen.de/~Winitzki/erf-approx.pdf
 *
 * Quoting: erf: Rel. precision better than 1.3e-4
 *          erf_inv: Rel. precision better than 2e-3
 *
 * erf(x) defined in the R
 * erf_inv(x) defined in (0,1)
 */
double cs_approx_erf(double x);
double cs_approx_erf_inv(double x);

/* calculate the no. of std. dev. nsigma
 * from alpha, where alpha = 1 - P
 * and P is the probability that measurements
 * from a Gaussian are within mean +/- n*sigma.
 */
double cs_alpha_to_nsigma(double alpha);

/* inverse of cs_nsigma_from_alpha:
 * Calculate the probability that a measurement will be
 * outside the bounds of n*sigma around the mean.
 */
double cs_nsigma_to_alpha(double nsigma);

#endif
