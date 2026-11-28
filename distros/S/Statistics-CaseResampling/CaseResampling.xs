#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "mt.h"
#include "stats.h"
#include <math.h>
#include <stdlib.h>


typedef struct mt * Statistics__CaseResampling__RdGen;

void*
U32ArrayPtr (pTHX_ int n)
{
  SV * sv;
  if (n <= 0 || n > 10000000)
    croak("Invalid array size for U32ArrayPtr");
  sv = sv_2mortal( NEWSV( 0, n*sizeof(U32) ) );
  SvGROW(sv, n*sizeof(U32));
  return SvPVX(sv);
}

static int
cs_sv_to_double(pTHX_ SV* sv, double* out)
{
  if (sv == NULL)
    return 0;
  SvGETMAGIC(sv);
  if (!SvOK(sv))
    return 0;
  if (!SvIOK(sv) && !SvNOK(sv) && !SvAMAGIC(sv) && !looks_like_number(sv))
    return -1;
  *out = SvNV(sv);
  return 1;
}

static double
cs_require_double(pTHX_ SV* sv, const char* name)
{
  double val = 0.;
  int ok = cs_sv_to_double(aTHX_ sv, &val);
  if (ok == 0)
    croak("%s must be defined", name);
  if (ok < 0)
    croak("%s must be numeric", name);
  return val;
}

static I32
cs_require_runs(pTHX_ SV* sv)
{
  double d = cs_require_double(aTHX_ sv, "Number of resample runs");
  if (!CS_ISFINITE(d) || d < 1. || d > 100000000.)
    croak("Number of resample runs must be between 1 and 100000000");
  return (I32)d;
}

double
cs_mean_av(pTHX_ AV* sample)
{
  I32 i, n;
  SV** elem;
  double sum = 0.;
  double c = 0.;
  int has_nonfinite = 0;

  n = av_len(sample)+1;
  if (n <= 0)
    croak("Cannot compute mean of empty sample");

  for (i = 0; i < n; ++i) {
    double x, t;
    CS_NEUMAIER_VOLATILE double t_store;
    int ok;
    if (NULL == (elem = av_fetch(sample, i, 0))) {
      croak("Could not fetch element from array");
    }
    ok = cs_sv_to_double(aTHX_ *elem, &x);
    if (ok == 0)
      croak("Undefined value in sample");
    if (ok < 0)
      croak("Non-numeric value in sample");
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

  /* All inputs were finite, but sum overflowed: use scaled incremental mean */
  {
    double m = 0.;
    for (i = 0; i < n; ++i) {
      double d = (double)(i + 1);
      double x;
      elem = av_fetch(sample, i, 0);
      cs_sv_to_double(aTHX_ *elem, &x);
      m = m * ((double)i / d) + x / d;
    }
    return m;
  }
}

double
cs_stddev_av(pTHX_ double mean, AV* sample, int is_sample)
{
  I32 i, n;
  SV** elem;
  double scale = 0.;
  double ssq = 1.;
  int has_inf = 0;

  n = av_len(sample)+1;
  if (n <= 0)
    return 0.;
  if (CS_ISNAN(mean))
    return mean;
  if (!CS_ISFINITE(mean))
    has_inf = 1;

  for (i = 0; i < n; ++i) {
    double val, d, ad;
    int ok;
    if (NULL == (elem = av_fetch(sample, i, 0))) {
      croak("Could not fetch element from array");
    }
    ok = cs_sv_to_double(aTHX_ *elem, &val);
    if (ok == 0)
      croak("Undefined value in sample");
    if (ok < 0)
      croak("Non-numeric value in sample");
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
avToCAry(pTHX_ AV* in, double** out, I32* n)
{
  I32 thisN;
  double* ary;
  SV** elem;
  I32 i;
  *out = NULL;
  thisN = av_len(in)+1;
  if (thisN <= 0) {
    *n = 0;
    return;
  }
  *n = thisN;

  Newx(ary, thisN, double);
  *out = ary;
  for (i = 0; i < thisN; ++i) {
    int ok;
    if (NULL == (elem = av_fetch(in, i, 0))) {
      Safefree(ary);
      *out = NULL;
      croak("Could not fetch element from array");
    }
    ok = cs_sv_to_double(aTHX_ *elem, &ary[i]);
    if (ok <= 0) {
      Safefree(ary);
      *out = NULL;
      croak(ok == 0 ? "Undefined value in sample" : "Non-numeric value in sample");
    }
  }
}

void
cAryToAV(pTHX_ double* in, AV** out, I32 n)
{
  SV* elem;
  I32 i;
  *out = newAV();
  if (n == 0)
    return;

  av_extend(*out, n-1);

  for (i = 0; i < n; ++i) {
    elem = newSVnv(in[i]);
    if (NULL == av_store(*out, i, elem))
      SvREFCNT_dec(elem);
  }
}

struct mt*
get_rnd(pTHX)
{
  IV tmp;
  struct mt* rnd;
  SV* therndsv = get_sv("Statistics::CaseResampling::Rnd", 0);
  if (therndsv == NULL
      || !SvROK(therndsv)
      || !sv_derived_from(therndsv, "Statistics::CaseResampling::RdGen"))
  {
    croak("Random number generator not set up!");
  }
  tmp = SvIV((SV*)SvRV(therndsv));
  rnd = INT2PTR(struct mt*, tmp);
  if (rnd != NULL && rnd->auto_seeded && rnd->pid != (long)PerlProc_getpid()) {
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;
    call_pv("Statistics::CaseResampling::_reseed_default_rng", G_VOID | G_DISCARD);
    FREETMPS;
    LEAVE;
    therndsv = get_sv("Statistics::CaseResampling::Rnd", 0);
    if (therndsv == NULL
        || !SvROK(therndsv)
        || !sv_derived_from(therndsv, "Statistics::CaseResampling::RdGen"))
    {
      croak("Random number generator not set up!");
    }
    tmp = SvIV((SV*)SvRV(therndsv));
    rnd = INT2PTR(struct mt*, tmp);
  }
  return rnd;
}


MODULE = Statistics::CaseResampling		PACKAGE = Statistics::CaseResampling
PROTOTYPES: DISABLE

INCLUDE: RdGen.xs.inc

MODULE = Statistics::CaseResampling		PACKAGE = Statistics::CaseResampling
PROTOTYPES: DISABLE

AV*
resample(sample)
    AV* sample
  PREINIT:
    I32 nelem;
    double* csample = NULL;
    double* destsample = NULL;
    struct mt* rnd;
  CODE:
    rnd = get_rnd(aTHX);
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (nelem != 0) {
      Newx(destsample, nelem, double);
      do_resample(csample, nelem, rnd, destsample);
      cAryToAV(aTHX_ destsample, &RETVAL, nelem);
      Safefree(destsample);
    }
    else
      RETVAL = newAV();
    Safefree(csample);
    sv_2mortal((SV*)RETVAL);
  OUTPUT: RETVAL


AV*
resample_medians(sample, runs_sv)
    AV* sample
    SV* runs_sv
  PREINIT:
    I32 runs, nelem, i_run;
    double* csample = NULL;
    double* destsample = NULL;
    struct mt* rnd;
  CODE:
    runs = cs_require_runs(aTHX_ runs_sv);
    rnd = get_rnd(aTHX);
    avToCAry(aTHX_ sample, &csample, &nelem);
    RETVAL = newAV();
    if (nelem != 0) {
      Newx(destsample, nelem, double);
      av_extend(RETVAL, runs-1);
      for (i_run = 0; i_run < runs; ++i_run) {
        do_resample(csample, nelem, rnd, destsample);
        av_store(RETVAL, i_run, newSVnv(cs_median(destsample, nelem)));
      }
      Safefree(destsample);
    }
    Safefree(csample);
    sv_2mortal((SV*)RETVAL);
  OUTPUT: RETVAL


AV*
resample_quantiles(sample, p_sv, runs_sv)
    AV* sample
    SV* p_sv
    SV* runs_sv
  PREINIT:
    double p;
    I32 runs, nelem, i_run;
    double* csample = NULL;
    double* destsample = NULL;
    struct mt* rnd;
  CODE:
    p = cs_require_double(aTHX_ p_sv, "Quantile probability p");
    if (!(p >= 0. && p <= 1.))
      croak("Quantile probability p must be in [0, 1]");
    runs = cs_require_runs(aTHX_ runs_sv);
    rnd = get_rnd(aTHX);
    avToCAry(aTHX_ sample, &csample, &nelem);
    RETVAL = newAV();
    if (nelem != 0) {
      Newx(destsample, nelem, double);
      av_extend(RETVAL, runs-1);
      for (i_run = 0; i_run < runs; ++i_run) {
        do_resample(csample, nelem, rnd, destsample);
        av_store(RETVAL, i_run, newSVnv(cs_quantile(destsample, nelem, p)));
      }
      Safefree(destsample);
    }
    Safefree(csample);
    sv_2mortal((SV*)RETVAL);
  OUTPUT: RETVAL


AV*
resample_means(sample, runs_sv)
    AV* sample
    SV* runs_sv
  PREINIT:
    I32 runs, nelem, i_run;
    double* csample = NULL;
    double* destsample = NULL;
    struct mt* rnd;
  CODE:
    runs = cs_require_runs(aTHX_ runs_sv);
    rnd = get_rnd(aTHX);
    avToCAry(aTHX_ sample, &csample, &nelem);
    RETVAL = newAV();
    if (nelem != 0) {
      Newx(destsample, nelem, double);
      av_extend(RETVAL, runs-1);
      for (i_run = 0; i_run < runs; ++i_run) {
        do_resample(csample, nelem, rnd, destsample);
        av_store(RETVAL, i_run, newSVnv(cs_mean(destsample, nelem)));
      }
      Safefree(destsample);
    }
    Safefree(csample);
    sv_2mortal((SV*)RETVAL);
  OUTPUT: RETVAL


double
median(sample)
    AV* sample
  PREINIT:
    I32 nelem;
    double* csample = NULL;
  CODE:
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (nelem == 0) {
      Safefree(csample);
      croak("Cannot compute median of empty sample");
    }
    RETVAL = cs_median(csample, nelem);
    Safefree(csample);
  OUTPUT: RETVAL

double
median_absolute_deviation(sample)
    AV* sample
  PREINIT:
    I32 nelem;
    double* csample = NULL;
  CODE:
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (nelem == 0) {
      Safefree(csample);
      croak("Cannot compute median absolute deviation of empty sample");
    }
    {
      I32 i;
      double* absdev;

      const double median = cs_median(csample, nelem);
      /* in principle, I think one could write an algorithm
       * that doesn't require mallocing the second array by inlining an
       * O(n) median that visits each element only once? */
      Newx(absdev, nelem, double);
      for (i = 0; i < nelem; ++i)
        absdev[i] = fabs(csample[i] - median);
      RETVAL = cs_median(absdev, nelem);
      Safefree(absdev);
    }
    Safefree(csample);
  OUTPUT: RETVAL


double
first_quartile(sample)
    AV* sample
  PREINIT:
    I32 nelem;
    double* csample = NULL;
  CODE:
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (nelem == 0) {
      Safefree(csample);
      croak("Cannot compute first quartile of empty sample");
    }
    RETVAL = cs_first_quartile(csample, nelem);
    Safefree(csample);
  OUTPUT: RETVAL


double
third_quartile(sample)
    AV* sample
  PREINIT:
    I32 nelem;
    double* csample = NULL;
  CODE:
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (nelem == 0) {
      Safefree(csample);
      croak("Cannot compute third quartile of empty sample");
    }
    RETVAL = cs_third_quartile(csample, nelem);
    Safefree(csample);
  OUTPUT: RETVAL


double
mean(sample)
    AV* sample
  CODE:
    RETVAL = cs_mean_av(aTHX_ sample);
  OUTPUT: RETVAL


double
sample_standard_deviation(...)
  PREINIT:
    AV* sample = NULL;
    double mean_val = 0.;
    I32 n;
  CODE:
    if (items == 1) {
      SV* arg = ST(0);
      if (!SvROK(arg) || SvTYPE(SvRV(arg)) != SVt_PVAV)
        croak("sample_standard_deviation: argument must be an array reference");
      sample = (AV*)SvRV(arg);
      n = av_len(sample)+1;
      if (n < 2)
        croak("Sample standard deviation requires at least 2 data points");
      mean_val = cs_mean_av(aTHX_ sample);
    }
    else if (items == 2) {
      SV* arg = ST(1);
      int ok;
      if (!SvROK(arg) || SvTYPE(SvRV(arg)) != SVt_PVAV)
        croak("sample_standard_deviation: second argument must be an array reference");
      ok = cs_sv_to_double(aTHX_ ST(0), &mean_val);
      if (ok <= 0)
        croak(ok == 0 ? "Undefined mean value" : "Non-numeric mean value");
      sample = (AV*)SvRV(arg);
      n = av_len(sample)+1;
      if (n < 2)
        croak("Sample standard deviation requires at least 2 data points");
    }
    else {
      croak("Usage: sample_standard_deviation([$mean,] \\@sample)");
    }
    RETVAL = cs_stddev_av(aTHX_ mean_val, sample, 1);
  OUTPUT: RETVAL


double
population_standard_deviation(...)
  PREINIT:
    AV* sample = NULL;
    double mean_val = 0.;
    I32 n;
  CODE:
    if (items == 1) {
      SV* arg = ST(0);
      if (!SvROK(arg) || SvTYPE(SvRV(arg)) != SVt_PVAV)
        croak("population_standard_deviation: argument must be an array reference");
      sample = (AV*)SvRV(arg);
      n = av_len(sample)+1;
      if (n < 1)
        croak("Population standard deviation requires at least 1 data point");
      mean_val = cs_mean_av(aTHX_ sample);
    }
    else if (items == 2) {
      SV* arg = ST(1);
      int ok;
      if (!SvROK(arg) || SvTYPE(SvRV(arg)) != SVt_PVAV)
        croak("population_standard_deviation: second argument must be an array reference");
      ok = cs_sv_to_double(aTHX_ ST(0), &mean_val);
      if (ok <= 0)
        croak(ok == 0 ? "Undefined mean value" : "Non-numeric mean value");
      sample = (AV*)SvRV(arg);
      n = av_len(sample)+1;
      if (n < 1)
        croak("Population standard deviation requires at least 1 data point");
    }
    else {
      croak("Usage: population_standard_deviation([$mean,] \\@sample)");
    }
    RETVAL = cs_stddev_av(aTHX_ mean_val, sample, 0);
  OUTPUT: RETVAL


double
quantile(sample, p_sv)
    AV* sample
    SV* p_sv
  PREINIT:
    I32 nelem;
    double p;
    double* csample = NULL;
  CODE:
    p = cs_require_double(aTHX_ p_sv, "Quantile probability p");
    if (!(p >= 0. && p <= 1.)) {
      croak("Quantile probability p must be in [0, 1]");
    }
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (nelem == 0) {
      Safefree(csample);
      croak("Cannot compute quantile of empty sample");
    }
    RETVAL = cs_quantile(csample, nelem, p);
    Safefree(csample);
  OUTPUT: RETVAL


double
select_kth(sample, kth_sv)
    AV* sample
    SV* kth_sv
  PREINIT:
    I32 nelem;
    I32 kth;
    double kth_d;
    double* csample = NULL;
  CODE:
    kth_d = cs_require_double(aTHX_ kth_sv, "kth");
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (!CS_ISFINITE(kth_d) || kth_d < 1. || kth_d > (double)nelem) {
      Safefree(csample);
      kth = CS_ISFINITE(kth_d) ? (I32)kth_d : 0;
      croak("Can't select %ith smallest element from a list of %i elements", (int)kth, (int)nelem);
    }
    kth = (I32)kth_d;
    RETVAL = cs_select(csample, nelem, kth-1);
    Safefree(csample);
  OUTPUT: RETVAL


void
median_simple_confidence_limits(sample, confidence_sv, ...)
    AV* sample
    SV* confidence_sv
  PREINIT:
    I32 runs, nelem, i_run;
    double *csample = NULL, *destsample = NULL, *medians = NULL;
    struct mt* rnd;
    double confidence;
    double median   = 0.;
    double lower_ci = 0.;
    double upper_ci = 0.;
    double alpha, q_lo, q_hi;
  PPCODE:
    if (items == 2)
      runs = 1000;
    else if (items == 3)
      runs = cs_require_runs(aTHX_ ST(2));
    else {
      croak("Usage: ($lower, $median, $upper) = median_simple_confidence_limits(\\@sample, $confidence, [$nruns]);");
    }
    confidence = cs_require_double(aTHX_ confidence_sv, "Confidence level");
    if (!(confidence > 0. && confidence < 1.)) {
      croak("Confidence level has to be in (0, 1)");
    }
    alpha = 1. - confidence;
    rnd = get_rnd(aTHX);
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (nelem == 0) {
      Safefree(csample);
      croak("Cannot compute confidence limits of empty sample");
    }
    median = cs_median(csample, nelem);
    Newx(medians, runs, double);
    Newx(destsample, nelem, double);
    for (i_run = 0; i_run < runs; ++i_run) {
      do_resample(csample, nelem, rnd, destsample);
      medians[i_run] = cs_median(destsample, nelem);
    }
    Safefree(destsample);
    q_hi = cs_quantile(medians, runs, 1. - 0.5 * alpha);
    q_lo = cs_quantile(medians, runs, 0.5 * alpha);
    lower_ci = 2.*median - q_hi;
    upper_ci = 2.*median - q_lo;
    Safefree(medians);
    Safefree(csample);
    EXTEND(SP, 3);
    mPUSHn(lower_ci);
    mPUSHn(median);
    mPUSHn(upper_ci);


void
simple_confidence_limits_from_samples(statistic_sv, statistics, confidence_sv)
    SV* statistic_sv
    AV* statistics
    SV* confidence_sv
  ALIAS:
    basic_confidence_limits_from_samples = 1
  PREINIT:
    I32 nelem;
    double *cstatistics = NULL;
    double statistic, confidence;
    double lower_ci = 0.;
    double upper_ci = 0.;
    double alpha, q_lo, q_hi;
  PPCODE:
    PERL_UNUSED_VAR(ix);
    statistic = cs_require_double(aTHX_ statistic_sv, "Statistic");
    confidence = cs_require_double(aTHX_ confidence_sv, "Confidence level");
    if (!(confidence > 0. && confidence < 1.)) {
      croak("Confidence level has to be in (0, 1)");
    }
    alpha = 1. - confidence;
    avToCAry(aTHX_ statistics, &cstatistics, &nelem);
    if (nelem == 0) {
      Safefree(cstatistics);
      croak("Cannot compute confidence limits from empty sample");
    }
    q_hi = cs_quantile(cstatistics, nelem, 1. - 0.5 * alpha);
    q_lo = cs_quantile(cstatistics, nelem, 0.5 * alpha);
    lower_ci = 2.*statistic - q_hi;
    upper_ci = 2.*statistic - q_lo;
    Safefree(cstatistics);
    EXTEND(SP, 3);
    mPUSHn(lower_ci);
    mPUSHn(statistic);
    mPUSHn(upper_ci);


void
percentile_confidence_limits_from_samples(statistic_sv, statistics, confidence_sv)
    SV* statistic_sv
    AV* statistics
    SV* confidence_sv
  PREINIT:
    I32 nelem;
    double *cstatistics = NULL;
    double statistic, confidence;
    double lower_ci = 0.;
    double upper_ci = 0.;
    double alpha;
  PPCODE:
    statistic = cs_require_double(aTHX_ statistic_sv, "Statistic");
    confidence = cs_require_double(aTHX_ confidence_sv, "Confidence level");
    if (!(confidence > 0. && confidence < 1.)) {
      croak("Confidence level has to be in (0, 1)");
    }
    alpha = 1. - confidence;
    avToCAry(aTHX_ statistics, &cstatistics, &nelem);
    if (nelem == 0) {
      Safefree(cstatistics);
      croak("Cannot compute confidence limits from empty sample");
    }
    lower_ci = cs_quantile(cstatistics, nelem, 0.5 * alpha);
    upper_ci = cs_quantile(cstatistics, nelem, 1. - 0.5 * alpha);
    Safefree(cstatistics);
    EXTEND(SP, 3);
    mPUSHn(lower_ci);
    mPUSHn(statistic);
    mPUSHn(upper_ci);


void
bca_confidence_limits_from_samples(statistic_sv, statistics, jackknife, confidence_sv)
    SV* statistic_sv
    AV* statistics
    AV* jackknife
    SV* confidence_sv
  PREINIT:
    I32 n_boot, n_jack;
    double *cboot = NULL, *cjack = NULL;
    double statistic, confidence;
    double lower_ci = 0.;
    double upper_ci = 0.;
  PPCODE:
    statistic = cs_require_double(aTHX_ statistic_sv, "Statistic");
    confidence = cs_require_double(aTHX_ confidence_sv, "Confidence level");
    if (!(confidence > 0. && confidence < 1.)) {
      croak("Confidence level has to be in (0, 1)");
    }
    if (av_len(statistics) < 0) {
      croak("Cannot compute BCa confidence limits from empty bootstrap sample");
    }
    if (av_len(jackknife) < 0) {
      croak("Cannot compute BCa confidence limits from empty jackknife sample");
    }
    ENTER;
    avToCAry(aTHX_ statistics, &cboot, &n_boot);
    SAVEFREEPV(cboot);
    avToCAry(aTHX_ jackknife, &cjack, &n_jack);
    SAVEFREEPV(cjack);
    cs_bca_confidence_limits(statistic, cboot, n_boot, cjack, n_jack, confidence, &lower_ci, &upper_ci);
    LEAVE;
    EXTEND(SP, 3);
    mPUSHn(lower_ci);
    mPUSHn(statistic);
    mPUSHn(upper_ci);


void
median_percentile_confidence_limits(sample, confidence_sv, ...)
    AV* sample
    SV* confidence_sv
  PREINIT:
    I32 runs, nelem, i_run;
    double *csample = NULL, *destsample = NULL, *medians = NULL;
    struct mt* rnd;
    double confidence;
    double median   = 0.;
    double lower_ci = 0.;
    double upper_ci = 0.;
    double alpha;
  PPCODE:
    if (items == 2)
      runs = 1000;
    else if (items == 3)
      runs = cs_require_runs(aTHX_ ST(2));
    else {
      croak("Usage: ($lower, $median, $upper) = median_percentile_confidence_limits(\\@sample, $confidence, [$nruns]);");
    }
    confidence = cs_require_double(aTHX_ confidence_sv, "Confidence level");
    if (!(confidence > 0. && confidence < 1.)) {
      croak("Confidence level has to be in (0, 1)");
    }
    alpha = 1. - confidence;
    rnd = get_rnd(aTHX);
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (nelem == 0) {
      Safefree(csample);
      croak("Cannot compute confidence limits of empty sample");
    }
    median = cs_median_exact(csample, nelem);
    Newx(medians, runs, double);
    Newx(destsample, nelem, double);
    for (i_run = 0; i_run < runs; ++i_run) {
      do_resample(csample, nelem, rnd, destsample);
      medians[i_run] = cs_median_exact(destsample, nelem);
    }
    Safefree(destsample);
    lower_ci = cs_quantile(medians, runs, 0.5 * alpha);
    upper_ci = cs_quantile(medians, runs, 1. - 0.5 * alpha);
    Safefree(medians);
    Safefree(csample);
    EXTEND(SP, 3);
    mPUSHn(lower_ci);
    mPUSHn(median);
    mPUSHn(upper_ci);


void
median_exact_confidence_limits(sample, confidence_sv)
    AV* sample
    SV* confidence_sv
  PREINIT:
    I32 nelem;
    double *csample = NULL;
    double confidence;
    double median   = 0.;
    double lower_ci = 0.;
    double upper_ci = 0.;
  PPCODE:
    confidence = cs_require_double(aTHX_ confidence_sv, "Confidence level");
    if (!(confidence > 0. && confidence < 1.)) {
      croak("Confidence level has to be in (0, 1)");
    }
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (nelem == 0) {
      Safefree(csample);
      croak("Cannot compute confidence limits of empty sample");
    }
    cs_median_exact_confidence_limits(csample, nelem, confidence, &lower_ci, &median, &upper_ci);
    Safefree(csample);
    EXTEND(SP, 3);
    mPUSHn(lower_ci);
    mPUSHn(median);
    mPUSHn(upper_ci);


void
mean_percentile_confidence_limits(sample, confidence_sv, ...)
    AV* sample
    SV* confidence_sv
  PREINIT:
    I32 runs, nelem, i_run;
    double *csample = NULL, *destsample = NULL, *means = NULL;
    struct mt* rnd;
    double confidence;
    double mean_val = 0.;
    double lower_ci = 0.;
    double upper_ci = 0.;
    double alpha;
  PPCODE:
    if (items == 2)
      runs = 1000;
    else if (items == 3)
      runs = cs_require_runs(aTHX_ ST(2));
    else {
      croak("Usage: ($lower, $mean, $upper) = mean_percentile_confidence_limits(\\@sample, $confidence, [$nruns]);");
    }
    confidence = cs_require_double(aTHX_ confidence_sv, "Confidence level");
    if (!(confidence > 0. && confidence < 1.)) {
      croak("Confidence level has to be in (0, 1)");
    }
    alpha = 1. - confidence;
    rnd = get_rnd(aTHX);
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (nelem == 0) {
      Safefree(csample);
      croak("Cannot compute confidence limits of empty sample");
    }
    mean_val = cs_mean(csample, nelem);
    Newx(means, runs, double);
    Newx(destsample, nelem, double);
    for (i_run = 0; i_run < runs; ++i_run) {
      do_resample(csample, nelem, rnd, destsample);
      means[i_run] = cs_mean(destsample, nelem);
    }
    Safefree(destsample);
    lower_ci = cs_quantile(means, runs, 0.5 * alpha);
    upper_ci = cs_quantile(means, runs, 1. - 0.5 * alpha);
    Safefree(means);
    Safefree(csample);
    EXTEND(SP, 3);
    mPUSHn(lower_ci);
    mPUSHn(mean_val);
    mPUSHn(upper_ci);


void
mean_bca_confidence_limits(sample, confidence_sv, ...)
    AV* sample
    SV* confidence_sv
  PREINIT:
    I32 runs, nelem;
    double *csample = NULL;
    struct mt* rnd;
    double confidence;
    double mean_val = 0.;
    double lower_ci = 0.;
    double upper_ci = 0.;
  PPCODE:
    if (items == 2)
      runs = 1000;
    else if (items == 3)
      runs = cs_require_runs(aTHX_ ST(2));
    else {
      croak("Usage: ($lower, $mean, $upper) = mean_bca_confidence_limits(\\@sample, $confidence, [$nruns]);");
    }
    confidence = cs_require_double(aTHX_ confidence_sv, "Confidence level");
    if (!(confidence > 0. && confidence < 1.)) {
      croak("Confidence level has to be in (0, 1)");
    }
    rnd = get_rnd(aTHX);
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (nelem == 0) {
      Safefree(csample);
      croak("Cannot compute confidence limits of empty sample");
    }
    cs_mean_bca_confidence_limits(csample, nelem, confidence, runs, rnd, &lower_ci, &mean_val, &upper_ci);
    Safefree(csample);
    EXTEND(SP, 3);
    mPUSHn(lower_ci);
    mPUSHn(mean_val);
    mPUSHn(upper_ci);


void
mean_studentized_confidence_limits(sample, confidence_sv, ...)
    AV* sample
    SV* confidence_sv
  PREINIT:
    I32 runs, nelem;
    double *csample = NULL;
    struct mt* rnd;
    double confidence;
    double mean_val = 0.;
    double lower_ci = 0.;
    double upper_ci = 0.;
  PPCODE:
    if (items == 2)
      runs = 1000;
    else if (items == 3)
      runs = cs_require_runs(aTHX_ ST(2));
    else {
      croak("Usage: ($lower, $mean, $upper) = mean_studentized_confidence_limits(\\@sample, $confidence, [$nruns]);");
    }
    confidence = cs_require_double(aTHX_ confidence_sv, "Confidence level");
    if (!(confidence > 0. && confidence < 1.)) {
      croak("Confidence level has to be in (0, 1)");
    }
    rnd = get_rnd(aTHX);
    avToCAry(aTHX_ sample, &csample, &nelem);
    if (nelem < 2) {
      Safefree(csample);
      croak("Studentized bootstrap confidence limits require at least 2 data points");
    }
    cs_mean_studentized_confidence_limits(csample, nelem, confidence, runs, rnd, &lower_ci, &mean_val, &upper_ci);
    Safefree(csample);
    EXTEND(SP, 3);
    mPUSHn(lower_ci);
    mPUSHn(mean_val);
    mPUSHn(upper_ci);


double
approx_erf(x_sv)
    SV* x_sv
  CODE:
    RETVAL = cs_approx_erf(cs_require_double(aTHX_ x_sv, "x"));
  OUTPUT: RETVAL


double
approx_erf_inv(x_sv)
    SV* x_sv
  PREINIT:
    double x;
  CODE:
    x = cs_require_double(aTHX_ x_sv, "x");
    if (!(x > -1. && x < 1.))
      croak("The inverse error function is defined in (-1, 1). %f is outside that range", x);
    RETVAL = cs_approx_erf_inv(x);
  OUTPUT: RETVAL


double
alpha_to_nsigma(x_sv)
    SV* x_sv
  PREINIT:
    double x;
  CODE:
    x = cs_require_double(aTHX_ x_sv, "alpha");
    if (!(x > 0. && x <= 1.))
      croak("alpha must be in (0, 1]; got %f", x);
    RETVAL = cs_alpha_to_nsigma(x);
  OUTPUT: RETVAL


double
nsigma_to_alpha(x_sv)
    SV* x_sv
  PREINIT:
    double x;
  CODE:
    x = cs_require_double(aTHX_ x_sv, "nsigma");
    if (!(x >= 0.))
      croak("nsigma must be >= 0; got %f", x);
    RETVAL = cs_nsigma_to_alpha(x);
  OUTPUT: RETVAL

