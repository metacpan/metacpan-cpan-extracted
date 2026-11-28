#ifndef _S_CS_STATS_H_
#define _S_CS_STATS_H_
#ifdef _MSC_VER
#  define _USE_MATH_DEFINES
#endif

#include "EXTERN.h"
#include "perl.h"

#include "mt.h"
#include <float.h>

#define SWAP(a,b) tmp=(a);(a)=(b);(b)=tmp;

/*
 * On x87 / extended-precision platforms (FLT_EVAL_METHOD != 0),
 * force the Neumaier running sum `t = sum + x` to round to binary64
 * before computing the compensation term so spill-time rounding is
 * never lost.
 */
#if (defined(FLT_EVAL_METHOD) && FLT_EVAL_METHOD != 0) || defined(__i386__) || defined(_M_IX86)
#  define CS_NEUMAIER_VOLATILE volatile
#else
#  define CS_NEUMAIER_VOLATILE
#endif

#define CS_ISNAN(x) ((x) != (x))
#define CS_ISFINITE(x) (!CS_ISNAN(x) && !CS_ISNAN((x) - (x)))

/* O(n) selection algorithm selecting the kth value from the sample of size n */
double cs_select(double* sample, I32 n, U32 k);

/* O(n) quantile using Hyndman-Fan type 7 linear interpolation */
double cs_quantile(double* sample, I32 n, double p);

/* fast median in O(n) using selection (median == second quartile; legacy even-n behavior) */
double cs_median(double* sample, I32 n);

/* exact O(n) median averaging the two middle elements when n is even */
double cs_median_exact(double* sample, I32 n);

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


/* error function and inverse */
double cs_approx_erf(double x);
double cs_approx_erf_inv(double x);

/* standard normal CDF and inverse CDF (quantile) */
double cs_norm_cdf(double z);
double cs_norm_ppf(double p);

/* calculate the no. of std. dev. nsigma
 * from alpha, where alpha = 1 - P
 * and P is the probability that measurements
 * from a Gaussian are within mean +/- n*sigma.
 */
double cs_alpha_to_nsigma(double alpha);

/* inverse of cs_alpha_to_nsigma:
 * Calculate the probability that a measurement will be
 * outside the bounds of n*sigma around the mean.
 */
double cs_nsigma_to_alpha(double nsigma);

/* BCa bootstrap confidence limits */
void cs_bca_confidence_limits(
  double statistic,
  double* boot, I32 n_boot,
  double* jack, I32 n_jack,
  double confidence,
  double* lower_out, double* upper_out
);

/* Distribution-free exact binomial confidence limits for the median */
void cs_median_exact_confidence_limits(
  double* sample, I32 n,
  double confidence,
  double* lower_out, double* median_out, double* upper_out
);

/* Scaled single-pass sample/population standard deviation on a C array */
double cs_stddev(const double* sample, I32 n, double mean, int is_sample);

/* All-in-C BCa bootstrap confidence limits for the mean */
void cs_mean_bca_confidence_limits(
  double* sample, I32 n,
  double confidence, I32 runs, struct mt* rnd,
  double* lower_out, double* mean_out, double* upper_out
);

/* All-in-C studentized (bootstrap-t) confidence limits for the mean */
void cs_mean_studentized_confidence_limits(
  double* sample, I32 n,
  double confidence, I32 runs, struct mt* rnd,
  double* lower_out, double* mean_out, double* upper_out
);

#endif
