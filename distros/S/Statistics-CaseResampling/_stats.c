#include "stats.h"
#include <math.h>

#ifndef M_PI
#  define M_PI 3.14159265358979323846264338327950288
#endif

#ifndef M_SQRT2
#  define M_SQRT2 1.41421356237309504880168872420969808
#endif

#ifndef M_LN2
#  define M_LN2 0.693147180559945309417232121458176568
#endif

#define CS_SQRT2PI  2.50662827463100050241576528481104525
#define CS_SQRTPI_2 0.886226925452758013649083741670572591

#if (defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L) || (defined(_MSC_VER) && _MSC_VER >= 1800) || defined(__GNUC__) || defined(__clang__)
#  define CS_HAVE_C99_MATH 1
#else
#  define CS_HAVE_C99_MATH 0
#endif

#define SWAP(a,b) tmp=(a);(a)=(b);(b)=tmp;

static void
cs_heapsort(double* arr, U32 n)
{
  U32 start, end;
  double tmp;
  if (n <= 1)
    return;
  for (start = n / 2; start > 0; ) {
    U32 root;
    start--;
    root = start;
    while (2 * root + 1 < n) {
      U32 child = 2 * root + 1;
      if (child + 1 < n && arr[child] < arr[child + 1])
        child++;
      if (arr[root] >= arr[child])
        break;
      SWAP(arr[root], arr[child]);
      root = child;
    }
  }
  for (end = n - 1; end > 0; end--) {
    U32 root = 0;
    SWAP(arr[0], arr[end]);
    while (2 * root + 1 < end) {
      U32 child = 2 * root + 1;
      if (child + 1 < end && arr[child] < arr[child + 1])
        child++;
      if (arr[root] >= arr[child])
        break;
      SWAP(arr[root], arr[child]);
      root = child;
    }
  }
}

double
cs_select(double* sample, I32 n, U32 k) {
  U32 i, ir, j, l, mid;
  double a, tmp;
  cs_u64 work = 0;
  cs_u64 limit;

  if (n <= 0)
    return 0.;
  if (k >= (U32)n)
    k = (U32)(n - 1);

  /* Propagate NaN deterministically regardless of element permutation */
  for (i = 0; i < (U32)n; ++i) {
    if (CS_ISNAN(sample[i]))
      return sample[i];
  }

  limit = (cs_u64)(U32)n * 6;
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
      work += (cs_u64)(ir - l + 1);
      if (work > limit) {
        cs_heapsort(sample + l, ir - l + 1);
        return sample[k];
      }
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
cs_quantile(double* sample, I32 n, double p)
{
  double h, frac, val_lo, val_hi;
  U32 lo, hi, i;

  if (n <= 0)
    return 0.;
  if (CS_ISNAN(p))
    return p;
  if (p <= 0.0)
    p = 0.0;
  else if (p >= 1.0)
    p = 1.0;

  h = (double)(n - 1) * p;
  lo = (U32)floor(h);
  hi = (U32)ceil(h);
  if (lo >= (U32)n)
    lo = (U32)(n - 1);
  if (hi >= (U32)n)
    hi = (U32)(n - 1);
  frac = h - (double)lo;

  val_lo = cs_select(sample, n, lo);
  if (CS_ISNAN(val_lo) || lo == hi || frac == 0.0)
    return val_lo;

  /* Partition invariant of cs_select guarantees sample[lo+1..n-1] >= val_lo */
  val_hi = sample[lo + 1];
  if (CS_ISNAN(val_hi))
    return val_hi;
  for (i = lo + 2; i < (U32)n; ++i) {
    if (CS_ISNAN(sample[i]))
      return sample[i];
    if (sample[i] < val_hi)
      val_hi = sample[i];
  }

  if (val_lo == val_hi)
    return val_lo;
  return (1.0 - frac) * val_lo + frac * val_hi;
}

double
cs_median(double* sample, I32 n)
{
  return cs_quantile(sample, n, 0.5);
}

double
cs_median_exact(double* sample, I32 n)
{
  return cs_quantile(sample, n, 0.5);
}


double
cs_first_quartile(double* sample, I32 n)
{
  return cs_quantile(sample, n, 0.25);
}


double
cs_third_quartile(double* sample, I32 n)
{
  return cs_quantile(sample, n, 0.75);
}


double
cs_mean(double* sample, I32 n)
{
  I32 i;
  double sum = 0.;
  double c = 0.;
  int has_nonfinite = 0;

  if (n <= 0)
    return 0.;

  for (i = 0; i < n; ++i) {
    double x = sample[i];
    CS_NEUMAIER_VOLATILE double t_store;
    double t;
    if (!CS_ISFINITE(x))
      has_nonfinite = 1;
    t_store = sum + x;
    t = t_store;
    if (CS_ISFINITE(t)) {
      if (fabs(sum) >= fabs(x))
        c += (sum - t) + x;
      else
        c += (x - t) + sum;
    }
    sum = t;
  }

  if (CS_ISFINITE(sum)) {
    double total = sum + c;
    if (CS_ISFINITE(total))
      return total / (double)n;
  }

  if (has_nonfinite)
    return sum / (double)n;

  /* All inputs were finite, but sum overflowed: compute scaled incremental mean */
  {
    double m = 0.;
    for (i = 0; i < n; ++i) {
      double d = (double)(i + 1);
      m = m * ((double)i / d) + sample[i] / d;
    }
    return m;
  }
}

void
do_resample(double* original, I32 n, struct mt* rdgen, double* dest)
{
  I32 i;
  if (n <= 0)
    return;
  for (i = 0; i < n; ++i) {
    dest[i] = original[mt_genrand_bounded(rdgen, (uint32_t)n)];
  }
}

static double
cs_erfc_impl(double x)
{
#if CS_HAVE_C99_MATH
  return erfc(x);
#else
  /* Fallback for pre-C99 compilers */
  if (x < 0.0)
    return 2.0 - cs_erfc_impl(-x);
  if (x > 27.0)
    return 0.0;
  {
    /* Abramowitz & Stegun 7.1.26 */
    const double t = 1.0 / (1.0 + 0.3275911 * x);
    const double poly = t * (0.254829592
      + t * (-0.284496736
      + t * (1.421413741
      + t * (-1.453152027
      + t * 1.061405429))));
    return poly * exp(-x * x);
  }
#endif
}

double
cs_approx_erf(double x)
{
#if CS_HAVE_C99_MATH
  return erf(x);
#else
  if (fabs(x) < 1e-4) {
    const double x2 = x * x;
    return (2.0 / sqrt(M_PI)) * x * (1.0 - x2 / 3.0 + x2 * x2 / 10.0);
  }
  return (x < 0.0) ? -(1.0 - cs_erfc_impl(-x)) : (1.0 - cs_erfc_impl(x));
#endif
}

double
cs_norm_cdf(double z)
{
  return 0.5 * cs_erfc_impl(-z / M_SQRT2);
}

double
cs_norm_ppf(double p)
{
  static const double a1 = -3.969683028665376e+01;
  static const double a2 =  2.209460984245205e+02;
  static const double a3 = -2.759285104469687e+02;
  static const double a4 =  1.383577518672690e+02;
  static const double a5 = -3.066479806614716e+01;
  static const double a6 =  2.506628277459239e+00;

  static const double b1 = -5.447609879822406e+01;
  static const double b2 =  1.615858368580409e+02;
  static const double b3 = -1.556989798598866e+02;
  static const double b4 =  6.680131188771972e+01;
  static const double b5 = -1.328068155288572e+01;

  static const double c1 = -7.784894002430293e-03;
  static const double c2 = -3.223964580411365e-01;
  static const double c3 = -2.400758277161838e+00;
  static const double c4 = -2.549732539343734e+00;
  static const double c5 =  4.374664141464968e+00;
  static const double c6 =  2.938163982698783e+00;

  static const double d1 =  7.784695709041462e-03;
  static const double d2 =  3.224671290700398e-01;
  static const double d3 =  2.445134137142996e+00;
  static const double d4 =  3.754408661907416e+00;

  const double p_low  = 0.02425;
  const double p_high = 1.0 - p_low;
  double q, r, z, e, u;

  if (CS_ISNAN(p))
    return p;
  if (p < 0.0 || p > 1.0)
    return log(-1.0); /* NaN */
  if (p == 0.0)
    return log(0.0);  /* -Inf */
  if (p == 1.0)
    return -log(0.0); /* +Inf */

  if (p < p_low) {
    q = sqrt(-2.0 * log(p));
    z = (((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6)
      / ((((d1 * q + d2) * q + d3) * q + d4) * q + 1.0);
  }
  else if (p <= p_high) {
    q = p - 0.5;
    r = q * q;
    z = (((((a1 * r + a2) * r + a3) * r + a4) * r + a5) * r + a6) * q
      / (((((b1 * r + b2) * r + b3) * r + b4) * r + b5) * r + 1.0);
  }
  else {
    q = sqrt(-2.0 * log(1.0 - p));
    z = -(((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6)
       / ((((d1 * q + d2) * q + d3) * q + d4) * q + 1.0);
  }

  /* One Halley refinement step for full IEEE-754 double precision */
  if (p < 0.25)
    e = 0.5 * cs_erfc_impl(-z / M_SQRT2) - p;
  else if (p > 0.75)
    e = (1.0 - p) - 0.5 * cs_erfc_impl(z / M_SQRT2);
  else
    e = 0.5 * cs_approx_erf(z / M_SQRT2) - (p - 0.5);

  u = e * CS_SQRT2PI * exp(0.5 * z * z);
  if (CS_ISFINITE(u)) {
    double denom = 1.0 + 0.5 * z * u;
    if (denom != 0.0)
      z -= u / denom;
  }

  return z;
}

double
cs_approx_erf_inv(double x)
{
  double z;

  if (CS_ISNAN(x))
    return x;
  if (x <= -1.0 || x >= 1.0) {
    if (x == 1.0)
      return -log(0.0);
    if (x == -1.0)
      return log(0.0);
    return log(-1.0);
  }
  if (x == 0.0)
    return 0.0;

  if (x > 0.0)
    z = -cs_norm_ppf(0.5 * (1.0 - x)) / M_SQRT2;
  else
    z = cs_norm_ppf(0.5 * (1.0 + x)) / M_SQRT2;

  /* Halley step directly on erf(z) - x avoids 1 - x cancellation near 0 */
  if (fabs(x) < 0.5) {
    double e = cs_approx_erf(z) - x;
    double u = e * CS_SQRTPI_2 * exp(z * z);
    if (CS_ISFINITE(u)) {
      double denom = 1.0 + z * u;
      if (denom != 0.0)
        z -= u / denom;
    }
  }

  return z;
}

double
cs_alpha_to_nsigma(double alpha)
{
  if (CS_ISNAN(alpha))
    return alpha;
  if (alpha > 0.0 && alpha < 2.0)
    return -cs_norm_ppf(0.5 * alpha);
  if (alpha == 0.0)
    return -log(0.0);
  if (alpha == 2.0)
    return log(0.0);
  return log(-1.0);
}

double
cs_nsigma_to_alpha(double nsigma)
{
  return cs_erfc_impl(nsigma / M_SQRT2);
}

static double
cs_lgamma_impl(double x)
{
#if CS_HAVE_C99_MATH
  return lgamma(x);
#else
  /* 9-term Lanczos approximation (g = 7) for x > 0 */
  static const double c[9] = {
     0.99999999999980993,
     676.5203681218851,
    -1259.1392167224028,
     771.32342877765313,
    -176.61502916214059,
     12.507343278686905,
    -0.13857109526572012,
     9.9843695780195716e-6,
     1.5056327351493116e-7
  };
  double z, sum, t;
  int i;
  if (x < 0.5)
    return log(M_PI / sin(M_PI * x)) - cs_lgamma_impl(1.0 - x);
  z = x - 1.0;
  sum = c[0];
  for (i = 1; i < 9; ++i)
    sum += c[i] / (z + (double)i);
  t = z + 7.5;
  return 0.5 * log(2.0 * M_PI) + (z + 0.5) * log(t) - t + log(sum);
#endif
}

static double
cs_bca_adj_prob(double z0, double a, double z_val)
{
  double num = z0 + z_val;
  double denom = 1.0 - a * num;
  double p;
  if (denom <= 0.0)
    return (num < 0.0) ? 0.0 : 1.0;
  p = cs_norm_cdf(z0 + num / denom);
  if (p < 0.0) return 0.0;
  if (p > 1.0) return 1.0;
  return p;
}

void
cs_bca_confidence_limits(
  double statistic,
  double* boot, I32 n_boot,
  double* jack, I32 n_jack,
  double confidence,
  double* lower_out, double* upper_out)
{
  I32 i, n_less = 0, n_eq = 0;
  double p0, z0, jack_mean, max_d = 0.0, a = 0.0;
  double alpha, z_lo, z_hi, p_lo, p_hi;

  if (CS_ISNAN(statistic)) {
    *lower_out = statistic;
    *upper_out = statistic;
    return;
  }
  for (i = 0; i < n_boot; ++i) {
    if (CS_ISNAN(boot[i])) {
      *lower_out = boot[i];
      *upper_out = boot[i];
      return;
    }
    if (boot[i] < statistic)
      n_less++;
    else if (boot[i] == statistic)
      n_eq++;
  }
  for (i = 0; i < n_jack; ++i) {
    if (CS_ISNAN(jack[i])) {
      *lower_out = jack[i];
      *upper_out = jack[i];
      return;
    }
  }

  /* Bias-correction factor z0 (with mid-p tie handling and boundary clamping) */
  if (n_boot <= 1) {
    p0 = 0.5;
  }
  else {
    double min_p = 0.5 / (double)n_boot;
    p0 = ((double)n_less + 0.5 * (double)n_eq) / (double)n_boot;
    if (p0 < min_p)
      p0 = min_p;
    else if (p0 > 1.0 - min_p)
      p0 = 1.0 - min_p;
  }
  z0 = cs_norm_ppf(p0);

  /* Acceleration factor a from jackknife leave-one-out replicates */
  if (n_jack >= 2) {
    jack_mean = cs_mean(jack, n_jack);
    for (i = 0; i < n_jack; ++i) {
      double ad = fabs(jack_mean - jack[i]);
      if (ad > max_d)
        max_d = ad;
    }
    if (max_d > 0.0 && CS_ISFINITE(max_d)) {
      double s2 = 0.0, s3 = 0.0;
      for (i = 0; i < n_jack; ++i) {
        double d = (jack_mean - jack[i]) / max_d;
        double d2 = d * d;
        s2 += d2;
        s3 += d2 * d;
      }
      if (s2 > 0.0)
        a = s3 / (6.0 * s2 * sqrt(s2));
    }
  }

  alpha = 1.0 - confidence;
  z_lo = cs_norm_ppf(0.5 * alpha);
  z_hi = -z_lo;

  p_lo = cs_bca_adj_prob(z0, a, z_lo);
  p_hi = cs_bca_adj_prob(z0, a, z_hi);
  if (p_lo > p_hi) {
    double tmp = p_lo;
    p_lo = p_hi;
    p_hi = tmp;
  }

  *lower_out = cs_quantile(boot, n_boot, p_lo);
  *upper_out = cs_quantile(boot, n_boot, p_hi);
}

void
cs_median_exact_confidence_limits(
  double* sample, I32 n,
  double confidence,
  double* lower_out, double* median_out, double* upper_out)
{
  I32 m, k;
  double p, cov;
  U32 lower_idx, upper_idx;

  *median_out = cs_median_exact(sample, n);
  if (n <= 0 || CS_ISNAN(*median_out)) {
    *lower_out = *median_out;
    *upper_out = *median_out;
    return;
  }
  if (n == 1) {
    *lower_out = sample[0];
    *upper_out = sample[0];
    return;
  }

  /*
   * Exact distribution-free confidence interval via Binomial(n, 0.5):
   * P(X_(k) <= med <= X_(n-k+1)) = sum_{j=k}^{n-k} C(n,j) / 2^n.
   * Walk outward symmetrically from the mode m = floor(n/2).
   */
  m = n / 2;
  p = exp(
    cs_lgamma_impl((double)n + 1.0)
    - cs_lgamma_impl((double)m + 1.0)
    - cs_lgamma_impl((double)(n - m) + 1.0)
    - (double)n * M_LN2
  );

  k = m;
  if (n & 1)
    cov = 2.0 * p;
  else
    cov = p;

  while (k > 1 && cov < confidence - 1e-14) {
    p *= (double)k / (double)(n - k + 1);
    k--;
    cov += 2.0 * p;
  }

  lower_idx = (U32)(k - 1);
  upper_idx = (U32)(n - k);

  *lower_out = cs_select(sample, n, lower_idx);
  *upper_out = cs_select(sample, n, upper_idx);
}

double
cs_stddev(const double* sample, I32 n, double mean, int is_sample)
{
  I32 i;
  double scale = 0.;
  double ssq = 1.;
  int has_inf = 0;

  if (n <= 0 || (is_sample && n < 2))
    return 0.;
  if (CS_ISNAN(mean))
    return mean;
  if (!CS_ISFINITE(mean))
    has_inf = 1;

  for (i = 0; i < n; ++i) {
    double val = sample[i];
    double d, ad;
    if (CS_ISNAN(val))
      return val;
    d = val - mean;
    if (CS_ISNAN(d))
      return d;
    if (!CS_ISFINITE(d)) {
      has_inf = 1;
      continue;
    }
    ad = fabs(d);
    if (ad > 0.) {
      if (scale < ad) {
        double r = scale / ad;
        ssq = 1. + ssq * r * r;
        scale = ad;
      }
      else {
        double r = ad / scale;
        ssq += r * r;
      }
    }
  }

  if (has_inf)
    return HUGE_VAL;
  if (scale == 0.)
    return 0.;
  return scale * sqrt(ssq / (double)(is_sample ? n - 1 : n));
}

void
cs_mean_bca_confidence_limits(
  double* sample, I32 n,
  double confidence, I32 runs, struct mt* rnd,
  double* lower_out, double* mean_out, double* upper_out)
{
  double m;
  double *boot = NULL, *jack = NULL, *dest = NULL;
  I32 i;

  m = cs_mean(sample, n);
  *mean_out = m;
  if (n <= 0 || CS_ISNAN(m)) {
    *lower_out = m;
    *upper_out = m;
    return;
  }

  Newx(boot, runs, double);
  Newx(jack, n, double);
  Newx(dest, n, double);

  for (i = 0; i < runs; ++i) {
    do_resample(sample, n, rnd, dest);
    boot[i] = cs_mean(dest, n);
  }

  if (n == 1) {
    jack[0] = sample[0];
  }
  else {
    double nm1 = (double)(n - 1);
    for (i = 0; i < n; ++i) {
      jack[i] = m + (m / nm1 - sample[i] / nm1);
    }
  }

  cs_bca_confidence_limits(m, boot, runs, jack, n, confidence, lower_out, upper_out);

  Safefree(dest);
  Safefree(jack);
  Safefree(boot);
}

void
cs_mean_studentized_confidence_limits(
  double* sample, I32 n,
  double confidence, I32 runs, struct mt* rnd,
  double* lower_out, double* mean_out, double* upper_out)
{
  double m, se, alpha, t_lo, t_hi;
  double *tvals = NULL, *dest = NULL;
  I32 i;

  m = cs_mean(sample, n);
  *mean_out = m;
  if (n < 2 || CS_ISNAN(m)) {
    *lower_out = m;
    *upper_out = m;
    return;
  }

  se = cs_stddev(sample, n, m, 1) / sqrt((double)n);
  if (CS_ISNAN(se)) {
    *lower_out = se;
    *upper_out = se;
    return;
  }
  if (se == 0.0) {
    *lower_out = m;
    *upper_out = m;
    return;
  }
  if (!CS_ISFINITE(se)) {
    *lower_out = -HUGE_VAL;
    *upper_out = HUGE_VAL;
    return;
  }

  Newx(tvals, runs, double);
  Newx(dest, n, double);

  for (i = 0; i < runs; ++i) {
    double bm, bse;
    do_resample(sample, n, rnd, dest);
    bm = cs_mean(dest, n);
    bse = cs_stddev(dest, n, bm, 1) / sqrt((double)n);
    if (CS_ISNAN(bm) || CS_ISNAN(bse))
      tvals[i] = log(-1.0);
    else if (bse > 0.0)
      tvals[i] = (bm - m) / bse;
    else if (bm == m)
      tvals[i] = 0.0;
    else
      tvals[i] = (bm > m) ? HUGE_VAL : -HUGE_VAL;
  }

  alpha = 1.0 - confidence;
  t_hi = cs_quantile(tvals, runs, 1.0 - 0.5 * alpha);
  t_lo = cs_quantile(tvals, runs, 0.5 * alpha);

  *lower_out = m - t_hi * se;
  *upper_out = m - t_lo * se;

  Safefree(dest);
  Safefree(tvals);
}

