#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
/* --- C HELPER SECTION --- */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <math.h>
#include <ctype.h>
#include <stdlib.h>
#include <float.h>
#include <string.h>
#include <strings.h>
#include <stdint.h>   /* uint64_t — harmless if perl.h already pulled it in */
/*
XS words:
SvROK = scalar value reference is OK
*/
/* ── sample(): private splitmix64 PRNG ─────────────────────────────────────
 *
 * sample() gets its own PRNG state, completely separate from Drand01.
 * That means generate_binomial(), ruif(), rbinom(), and every other caller
 * of Drand01() are unaffected — their streams are never advanced or reseeded
 * by anything sample() does.
 *
 * Seeding is lazy (first call) and reads from /dev/urandom; falls back to
 * time()^PID on systems without it.  No aTHX needed: all calls are plain C.
 * PERL_NO_GET_CONTEXT is therefore not a concern here.
 */
static uint64_t sample__state  = 0;
static bool     sample__seeded = FALSE;

PERL_STATIC_INLINE uint64_t
sample__mix64(void)
{
	uint64_t z = (sample__state += UINT64_C(0x9e3779b97f4a7c15));
	z = (z ^ (z >> 30)) * UINT64_C(0xbf58476d1ce4e5b9);
	z = (z ^ (z >> 27)) * UINT64_C(0x94d049bb133111eb);
	return z ^ (z >> 31);
}

static void
sample__seed(void)
{
	dTHX; /* fetch the Perl context */
	uint64_t s = 0;
	size_t   got = 0;
	FILE    *restrict ur  = fopen("/dev/urandom", "rb");
	if (ur) { got = fread(&s, sizeof s, 1, ur); fclose(ur); }
	if (got != 1 || s == 0)
	s = (uint64_t)time(NULL) ^ ((uint64_t)getpid() << 32);
	sample__state  = s;
	(void)sample__mix64();   /* discard first output to warm the state */
	sample__seeded = TRUE;
}

/* Uniform integer in [0, upper) — rejection loop, no modulo bias */
PERL_STATIC_INLINE size_t
sample__rand(size_t upper) {
	const uint64_t u = (uint64_t)upper;
	const uint64_t t = (uint64_t)(-(uint64_t)u) % u;
	uint64_t r;
	do { r = sample__mix64(); } while (r < t);
	return (size_t)(r % u);
}
/* ── end sample() private PRNG ─────────────────────────────────────────── */

/* Ensure Perl's PRNG is seeded, matching the lazy-evaluation of Perl's rand() */
#define AUTO_SEED_PRNG() \
	do { \
		if (!PL_srand_called) { \
			(void)seedDrand01((Rand_seed_t)Perl_seed(aTHX)); \
			PL_srand_called = TRUE; \
		} \
	} while (0)

// ---------------------------------------
//   Helpers for Random Number Generation
// ---------------------------------------
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif
// C helper for EXACT Non-central T-distribution CDF via Numerical Integration.
// This perfectly replicates R's pt(..., ncp) exactness without requiring complex Beta functions.
static double exact_pnt(double t, double df, double ncp) {
	if (df <= 0.0) return 0.0;
	unsigned short int n_steps = 30000;
	double step = 1.0 / n_steps;
	double integral = 0.0, half_df = df / 2.0;

	double log_coef = log(2.0) + half_df * log(half_df) - lgamma(half_df);
	double root_half = 0.70710678118654752440; // 1 / sqrt(2)

	for (unsigned short i = 1; i < n_steps; i++) {
		double u = i * step;
		double w = u / (1.0 - u);
		// Scaled Chi-distribution log-density
		double log_M = log_coef + (df - 1.0) * log(w) - half_df * w * w;
		double M = exp(log_M);
		// Exact Normal CDF using the C standard library's erfc function
		double z = t * w - ncp;
		double pnorm_val = 0.5 * erfc(-z * root_half);
		double weight = (i % 2 != 0) ? 4.0 : 2.0;
		integral += weight * (pnorm_val * M / ((1.0 - u) * (1.0 - u)));
	}
	return integral * (step / 3.0);
}
// --- Math Helpers for P-values and Confidence Intervals --- 

// Ranking helper with tie adjustment (matches R's tie handling)
typedef struct { double val; size_t idx; double rank; } RankInfo;
static int compare_rank(const void *restrict a, const void *restrict b) {
	double diff = ((RankInfo*)a)->val - ((RankInfo*)b)->val;
	return (diff > 0) - (diff < 0);
}

static int compare_index(const void *restrict a, const void *restrict b) {
	return ((RankInfo*)a)->idx - ((RankInfo*)b)->idx;
}

static void compute_ranks(double *restrict data, double *restrict ranks, size_t n) {
	RankInfo *restrict items = safemalloc(n * sizeof(RankInfo));
	for (size_t i = 0; i < n; i++) {
		items[i].val = data[i];
		items[i].idx = i;
	}
	qsort(items, n, sizeof(RankInfo), compare_rank);
	// Handle ties by averaging ranks
	for (size_t i = 0; i < n; ) {
		size_t j = i + 1;
		while (j < n && items[j].val == items[i].val) j++;
		double avg_rank = (i + 1 + j) / 2.0;
		for (size_t k = i; k < j; k++) items[k].rank = avg_rank;
		i = j;
	}
	qsort(items, n, sizeof(RankInfo), compare_index);
	for (size_t i = 0; i < n; i++) ranks[i] = items[i].rank;
	Safefree(items);
}
// Generates a single binomial random variate. 
//Uses the standard Bernoulli trial loop. Drand01() taps into Perl's PRNG.
static size_t generate_binomial(pTHX_ const size_t size, const double prob) {
	if (prob <= 0.0) return 0;
	if (prob >= 1.0) return size;

	size_t successes = 0;
	for (size_t i = 0; i < size; i++) {
		if (Drand01() <= prob) successes++;
	}
	return successes;
}
// Helper: log combination
static double log_choose(size_t n, size_t k) {
	return lgamma((double)n + 1.0) - lgamma((double)k + 1.0) - lgamma((double)(n - k) + 1.0);
}

// Log-space tails for non-central hypergeometric
static void calc_tails_logspace(size_t a, size_t min_x, size_t max_x, double omega, const double *logdc, double *restrict lower_tail, double *restrict upper_tail) {
	double max_d = -1e300, log_omega = log(omega);

	for(size_t k = 0; k <= max_x - min_x; ++k) {
	  double d_val = logdc[k] + log_omega * (min_x + k);
	  if (d_val > max_d) max_d = d_val;
	}

	double sum_d = 0.0;
	for(size_t k = 0; k <= max_x - min_x; ++k) {
	  sum_d += exp(logdc[k] + log_omega * (min_x + k) - max_d);
	}

	*lower_tail = 0.0;
	*upper_tail = 0.0;

	for(size_t k = 0; k <= max_x - min_x; ++k) {
	  double p_prob = exp(logdc[k] + log_omega * (min_x + k) - max_d) / sum_d;
	  if (min_x + k <= a) *lower_tail += p_prob;
	  if (min_x + k >= a) *upper_tail += p_prob;
	}
}

// Exact stats using log-space
static void calculate_exact_stats(size_t a, size_t b, size_t c, size_t d, double conf_level, const char*restrict alt, double *restrict mle_or, double *restrict ci_low, double *restrict ci_high) {
	double alpha = 1.0 - conf_level;
	size_t r1 = a + b, r2 = c + d, c1 = a + c;
	size_t min_x = (r2 > c1) ? 0 : c1 - r2;
	size_t max_x = (r1 < c1) ? r1 : c1;

	bool is_less = (strcmp(alt, "less") == 0);
	bool is_greater = (strcmp(alt, "greater") == 0);

	double *restrict logdc = (double*)safemalloc((max_x - min_x + 1) * sizeof(double));
	double denom = log_choose(r1 + r2, c1);
	for(size_t x = min_x; x <= max_x; ++x) {
	  logdc[x - min_x] = log_choose(r1, x) + log_choose(r2, c1 - x) - denom;
	}

	// MLE
	if (a == min_x && a == max_x) *mle_or = 1.0;
	else if (a == min_x) *mle_or = 0.0;
	else if (a == max_x) *mle_or = INFINITY;
	else {
		double log_low = -100.0, log_high = 100.0;
		for (unsigned short int i = 0; i < 3000; i++) {
			double log_mid = 0.5 * (log_low + log_high);
			double max_d = -1e300;
			for(size_t k = 0; k <= max_x - min_x; ++k) {
				 double d_val = logdc[k] + log_mid * (min_x + k);
				 if (d_val > max_d) max_d = d_val;
			}
			double sum_d = 0.0, exp_val = 0.0;
			for(size_t k = 0; k <= max_x - min_x; ++k) {
				 double p_prob = exp(logdc[k] + log_mid * (min_x + k) - max_d);
				 sum_d += p_prob;
				 exp_val += (min_x + k) * p_prob;
			}
			exp_val /= sum_d;
			if (exp_val > a) log_high = log_mid;
			else log_low = log_mid;
			if (log_high - log_low < 1e-15) break;
		}
		*mle_or = exp(0.5 * (log_low + log_high));
	}

	*ci_low = 0.0;
	*ci_high = INFINITY;

	// Lower CI
	if (!is_less) { 
		double target_alpha = is_greater ? alpha : alpha / 2.0;
		if (a != min_x) {
			double log_low = -100.0, log_high = 100.0, best = 1.0, best_err = 1e9, lt, ut;
			for (unsigned short int i = 0; i < 1000; i++) {
				double log_mid = 0.5 * (log_low + log_high);
				double mid = exp(log_mid);
				calc_tails_logspace(a, min_x, max_x, mid, logdc, &lt, &ut);
				double err = fabs(ut - target_alpha);
				if (err < best_err) { best_err = err; best = mid; }
				if (ut > target_alpha) log_high = log_mid;
				else log_low = log_mid;
				if (log_high - log_low < 1e-15) break;
			}
			*ci_low = best;
		}
	}

	// Upper CI
	if (!is_greater) { 
		double target_alpha = is_less ? alpha : alpha / 2.0;
		if (a != max_x) {
			double log_low = -100.0, log_high = 100.0, best = 1.0, best_err = 1e9, lt, ut;
			for (unsigned short int i = 0; i < 1000; i++) {
				double log_mid = 0.5 * (log_low + log_high);
				double mid = exp(log_mid);
				calc_tails_logspace(a, min_x, max_x, mid, logdc, &lt, &ut);
				double err = fabs(lt - target_alpha);
				if (err < best_err) { best_err = err; best = mid; }
				if (lt > target_alpha) log_low = log_mid;
				else log_high = log_mid;
				if (log_high - log_low < 1e-15) break;
			}
			*ci_high = best;
		}
	}
	safefree(logdc);
}

// Exact p-value using log-space
static double exact_p_value(size_t a, size_t b, size_t c, size_t d, const char* alt) {
	size_t r1 = a + b, r2 = c + d, c1 = a + c;
	size_t min_x = (r2 > c1) ? 0 : c1 - r2;
	size_t max_x = (r1 < c1) ? r1 : c1;

	double *logdc = (double*)safemalloc((max_x - min_x + 1) * sizeof(double));
	double denom = log_choose(r1 + r2, c1);
	for(size_t x = min_x; x <= max_x; ++x) {
		logdc[x - min_x] = log_choose(r1, x) + log_choose(r2, c1 - x) - denom;
	}
	double p_val = 0.0;
	if (strcmp(alt, "less") == 0) {
		for(size_t x = min_x; x <= a; ++x) p_val += exp(logdc[x - min_x]);
	} else if (strcmp(alt, "greater") == 0) {
		for(size_t x = a; x <= max_x; ++x) p_val += exp(logdc[x - min_x]);
	} else {
		double p_obs = exp(logdc[a - min_x]);
		double relErr = 1.0 + 1e-7;
		for(size_t x = min_x; x <= max_x; ++x) {
			double p_cur = exp(logdc[x - min_x]);
			if (p_cur <= p_obs * relErr) p_val += p_cur;
		}
	}
	safefree(logdc);
	return (p_val > 1.0) ? 1.0 : p_val;
}
/* -----------------------------------------------------------------------
 * Helpers for lm Linear Regression: OLS Matrix Math & Formula Parsing
 * -----------------------------------------------------------------------
 Sweep operator for symmetric positive-definite matrices (e.g., XtX).
 This gracefully handles collinearity by bypassing aliased columns.
 Utilizes a relative tolerance check to prevent dropping micro-variance features.
*/
static int sweep_matrix_ols(double *restrict A, size_t n, bool *restrict aliased) {
	int rank = 0;
	double *restrict orig_diag = (double*)safemalloc(n * sizeof(double));

	// Save the original diagonal values to use as a baseline for relative variance
	for (size_t k = 0; k < n; k++) {
		aliased[k] = FALSE;
		orig_diag[k] = A[k * n + k];
	}

	for (size_t k = 0; k < n; k++) {
		// Check pivot for collinearity using a RELATIVE tolerance
		// (Fallback to a tiny absolute tolerance of 1e-24 to catch literal zero vectors)
		if (fabs(A[k * n + k]) <= 1e-10 * orig_diag[k] || fabs(A[k * n + k]) < 1e-24) {
			aliased[k] = TRUE;
			// Isolate this column so it doesn't affect the rest of the matrix
			for (size_t i = 0; i < n; i++) { 
				A[k * n + i] = 0.0; 
				A[i * n + k] = 0.0; 
			}
			continue;
		}
		rank++;
		double pivot = 1.0 / A[k * n + k];
		A[k * n + k] = 1.0;
		for (size_t j = 0; j < n; j++) A[k * n + j] *= pivot;
		for (size_t i = 0; i < n; i++) {
			if (i != k && A[i * n + k] != 0.0) {
				  double factor = A[i * n + k];
				  A[i * n + k] = 0.0;
				  for (size_t j = 0; j < n; j++) {
				       A[i * n + j] -= factor * A[k * n + j];
				  }
			}
		}
	}
	Safefree(orig_diag);
	return rank;
}

// Internal extractor resolving single data values. Returns NAN on missing or non-numeric.
static double get_data_value(pTHX_ HV *restrict data_hoa, HV **restrict row_hashes, unsigned int i, const char *restrict var) {
	SV **restrict val = NULL;
	if (row_hashes) {
		val = hv_fetch(row_hashes[i], var, strlen(var), 0);
		if (val && SvROK(*val) && SvTYPE(SvRV(*val)) == SVt_PVAV) {
			AV*restrict av = (AV*)SvRV(*val);
			val = av_fetch(av, 0, 0);
		}
	} else if (data_hoa) {
		SV**restrict col = hv_fetch(data_hoa, var, strlen(var), 0);
		if (col && SvROK(*col) && SvTYPE(SvRV(*col)) == SVt_PVAV) {
			AV*restrict av = (AV*)SvRV(*col);
			val = av_fetch(av, i, 0);
		}
	}
	if (val && SvOK(*val)) {
		if (looks_like_number(*val)) return SvNV(*val);
		return NAN; // Catch strings like "blue"
	}
	return NAN; // Catch undef/missing keys
}

// Helper: Get all available columns for the '.' operator expansion
static AV* get_all_columns(pTHX_ HV *restrict data_hoa, HV **restrict row_hashes, size_t n) {
	AV *restrict cols = newAV();
	if (data_hoa) {
		hv_iterinit(data_hoa);
		HE *restrict entry;
		while ((entry = hv_iternext(data_hoa))) {
			av_push(cols, newSVsv(hv_iterkeysv(entry)));
		}
	} else if (row_hashes && n > 0 && row_hashes[0]) {
		hv_iterinit(row_hashes[0]);
		HE *restrict entry;
		while ((entry = hv_iternext(row_hashes[0]))) {
			av_push(cols, newSVsv(hv_iterkeysv(entry)));
		}
	}
	return cols;
}

// Recursive formula resolver with tightened NaN and Null handling
static double evaluate_term(pTHX_ HV *restrict data_hoa, HV **restrict row_hashes, unsigned int i, const char *restrict term) {
	if (!term || term[0] == '\0') return NAN;

	char *restrict term_cpy = savepv(term); 
	char *restrict colon = strchr(term_cpy, ':');
	if (colon) {
		*colon = '\0';
		double left = evaluate_term(aTHX_ data_hoa, row_hashes, i, term_cpy);
		double right = evaluate_term(aTHX_ data_hoa, row_hashes, i, colon + 1);
		Safefree(term_cpy); 
		if (isnan(left) || isnan(right)) return NAN;
		return left * right;
	}
	if (strncmp(term_cpy, "I(", 2) == 0) {
		char *restrict end = strrchr(term_cpy, ')');
		if (end) *end = '\0';
		char *restrict inner = term_cpy + 2;
		char *restrict caret = strchr(inner, '^');
		int power = 1;
		if (caret) {
			*caret = '\0';
			power = atoi(caret + 1);
		}
		double v = get_data_value(aTHX_ data_hoa, row_hashes, i, inner);
		Safefree(term_cpy); 

		if (isnan(v)) return NAN;
		return power == 1 ? v : pow(v, power);
	}
	double result = get_data_value(aTHX_ data_hoa, row_hashes, i, term_cpy);
	Safefree(term_cpy); 
	return result;
}

// Helper to infer column type from its first valid element
static bool is_column_categorical(pTHX_ HV *restrict data_hoa, HV **restrict row_hashes, size_t n, const char *restrict var) {
	for (size_t i = 0; i < n; i++) {
		SV **restrict val = NULL;
		if (row_hashes) {
			val = hv_fetch(row_hashes[i], var, strlen(var), 0);
			if (val && SvROK(*val) && SvTYPE(SvRV(*val)) == SVt_PVAV) {
				 AV*restrict av = (AV*)SvRV(*val);
				 val = av_fetch(av, 0, 0);
			}
		} else if (data_hoa) {
			SV **restrict col = hv_fetch(data_hoa, var, strlen(var), 0);
			if (col && SvROK(*col) && SvTYPE(SvRV(*col)) == SVt_PVAV) {
				 AV*restrict av = (AV*)SvRV(*col);
				 val = av_fetch(av, i, 0);
			}
		}
		if (val && SvOK(*val)) {
			if (looks_like_number(*val)) return FALSE; // First valid is number -> Numeric Column
			return TRUE; // First valid is string -> Categorical Column
		}
	}
	return FALSE;
}

/* Internal extractor resolving single data string values using dynamic allocation. */
static char* get_data_string_alloc(pTHX_ HV *restrict data_hoa, HV **restrict row_hashes, size_t i, const char *restrict var) {
	SV **restrict val = NULL;
	if (row_hashes) {
		val = hv_fetch(row_hashes[i], var, strlen(var), 0);
		if (val && SvROK(*val) && SvTYPE(SvRV(*val)) == SVt_PVAV) {
			AV*restrict av = (AV*)SvRV(*val);
			val = av_fetch(av, 0, 0);
		}
	} else if (data_hoa) {
		SV **restrict col = hv_fetch(data_hoa, var, strlen(var), 0);
		if (col && SvROK(*col) && SvTYPE(SvRV(*col)) == SVt_PVAV) {
			AV*restrict av = (AV*)SvRV(*col);
			val = av_fetch(av, i, 0);
		}
	}
	if (val && SvOK(*val)) {
		return savepv(SvPV_nolen(*val)); /* Allocates and returns string */
	}
	return NULL;
}

// Struct for sorting p-values while remembering their original index
typedef struct {
	double p;
	size_t orig_idx;
} PVal;

// Comparator for qsort
static int cmp_pval(const void *restrict a, const void *restrict b) {
	double diff = ((PVal*)a)->p - ((PVal*)b)->p;
	if (diff < 0) return -1;
	if (diff > 0) return 1;
	/* Stabilize sort by falling back to original index */
	return ((PVal*)a)->orig_idx - ((PVal*)b)->orig_idx; 
}
/* -----------------------------------------------------------------------
 * Helpers for cor(): ranking (Spearman), Pearson r, Kendall tau-b
 * ----------------------------------------------------------------------- */
/* Item used to sort values while remembering their original index,
 * needed for average-rank tie-breaking in Spearman correlation.        */
typedef struct {
	double val;
	size_t idx;
} RankItem;

static int cmp_rank_item(const void *restrict a, const void *restrict b) {
	double diff = ((RankItem*)a)->val - ((RankItem*)b)->val;
	if (diff < 0) return -1;
	if (diff > 0) return  1;
	return 0;
}

/* Compute 1-based average ranks with tie-breaking into out[].
 * in[] is not modified.                                                 */
static void rank_data(const double *restrict in, double *restrict out, size_t n) {
	RankItem *restrict ri;
	Newx(ri, n, RankItem);
	for (size_t i = 0; i < n; i++) { ri[i].val = in[i]; ri[i].idx = i; }
	qsort(ri, n, sizeof(RankItem), cmp_rank_item);

	size_t i = 0;
	while (i < n) {
		size_t j = i;
		/* Find the full extent of this tie group */
		while (j + 1 < n && ri[j + 1].val == ri[j].val) j++;
		/* All members get the average of ranks i+1 … j+1 (1-based) */
		double avg = (double)(i + j) / 2.0 + 1.0;
		for (size_t k = i; k <= j; k++) out[ri[k].idx] = avg;
		i = j + 1;
	}
	Safefree(ri);
}

/* Pearson product-moment r between two n-element arrays.
 * Returns NAN when either variable has zero variance (matches R).       */
static double pearson_corr(const double *restrict x, const double *restrict y, size_t n) {
	double sx = 0, sy = 0, sxy = 0, sx2 = 0, sy2 = 0;
	for (size_t i = 0; i < n; i++) {
	  sx  += x[i];     sy  += y[i];
	  sxy += x[i]*y[i]; sx2 += x[i]*x[i]; sy2 += y[i]*y[i];
	}
	double num = (double)n * sxy - sx * sy;
	double den = sqrt(((double)n * sx2 - sx*sx) * ((double)n * sy2 - sy*sy));
	if (den == 0.0) return NAN;
	return num / den;
}

/* Kendall's tau-b between two n-element arrays.

 *   tau-b = (C − D) / sqrt((C + D + T_x)(C + D + T_y))
 *
 * where C = concordant pairs, D = discordant, T_x = pairs tied only on
 * x, T_y = pairs tied only on y.  Joint ties (both zero) are excluded
 * from numerator and denominator, matching R's cor(method="kendall").
 * Returns NAN when the denominator is zero.                             */
static double kendall_tau_b(const double *restrict x, const double *restrict y, unsigned int n) {
	size_t C = 0, D = 0, tie_x = 0, tie_y = 0;
	for (size_t i = 0; i < n - 1; i++) {
		for (size_t j = i + 1; j < n; j++) {
			int sx = (x[i] > x[j]) - (x[i] < x[j]);   /* sign of x[i]-x[j] */
			int sy = (y[i] > y[j]) - (y[i] < y[j]);
			if      (sx == 0 && sy == 0) { /* joint tie — not counted */ }
			else if (sx == 0)            tie_x++;
			else if (sy == 0)            tie_y++;
			else if (sx == sy)           C++;
			else                         D++;
		}
	}
	double denom = sqrt((double)(C + D + tie_x) * (double)(C + D + tie_y));
	if (denom == 0.0) return NAN;
	return (double)(C - D) / denom;
}

/* Single dispatch: compute correlation according to method string.
 * Allocates and frees temporary rank arrays internally for Spearman.   */
static double compute_cor(const double *restrict x, const double *restrict y,
                           size_t n, const char *restrict method) {
	if (strcmp(method, "spearman") == 0) {
	  double *restrict rx, *restrict ry;
	  Newx(rx, n, double); Newx(ry, n, double);
	  rank_data(x, rx, n);
	  rank_data(y, ry, n);
	  double r = pearson_corr(rx, ry, n);
	  Safefree(rx); Safefree(ry);
	  return r;
	}
	if (strcmp(method, "kendall") == 0)
	  return kendall_tau_b(x, y, n);
	/* default: pearson */
	return pearson_corr(x, y, n);
}

// Math macros
#define MAX_ITER 500
#define EPS 3.0e-15
#define FPMIN 1.0e-30

static double _incbeta_cf(double a, double b, double x) {
	int m;
	double aa, c, d, del, h, qab, qam, qap;
	qab = a + b; qap = a + 1.0; qam = a - 1.0;
	c = 1.0; d = 1.0 - qab * x / qap;
	if (fabs(d) < FPMIN) d = FPMIN;
	d = 1.0 / d; h = d;
	for (m = 1; m <= MAX_ITER; m++) {
	  int m2 = 2 * m;
	  aa = m * (b - m) * x / ((qam + m2) * (a + m2));
	  d = 1.0 + aa * d;
	  if (fabs(d) < FPMIN) d = FPMIN;
	  c = 1.0 + aa / c;
	  if (fabs(c) < FPMIN) c = FPMIN;
	  d = 1.0 / d; h *= d * c;
	  aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2));
	  d = 1.0 + aa * d;
	  if (fabs(d) < FPMIN) d = FPMIN;
	  c = 1.0 + aa / c;
	  if (fabs(c) < FPMIN) c = FPMIN;
	  d = 1.0 / d; del = d * c; h *= del;
	  if (fabs(del - 1.0) < EPS) break;
	}
	return h;
}

static double incbeta(double a, double b, double x) {
	if (x <= 0.0) return 0.0;
	if (x >= 1.0) return 1.0;
	double bt = exp(lgamma(a + b) - lgamma(a) - lgamma(b) + a * log(x) + b * log(1.0 - x));
	if (x < (a + 1.0) / (a + b + 2.0)) return bt * _incbeta_cf(a, b, x) / a;
	return 1.0 - bt * _incbeta_cf(b, a, 1.0 - x) / b;
}

static double get_t_pvalue(double t, double df, const char*restrict alt) {
	double x = df / (df + t * t);
	double prob_2tail = incbeta(df / 2.0, 0.5, x);
	if (strcmp(alt, "less") == 0) return (t < 0) ? 0.5 * prob_2tail : 1.0 - 0.5 * prob_2tail;
	if (strcmp(alt, "greater") == 0) return (t > 0) ? 0.5 * prob_2tail : 1.0 - 0.5 * prob_2tail;
	return prob_2tail;
}

// Bisection algorithm to find the inverse t-distribution (Critical t-value)
static double qt_tail(double df, double p_tail) {
	double low = 0.0, high = 1.0;
	// Find upper bound
	while (get_t_pvalue(high, df, "greater") > p_tail) {
	  low = high;
	  high *= 2.0;
	  if (high > 1000000.0) break; /* Fallback limit */
	}
	// Bisect to find the root
	for (unsigned short int i = 0; i < 100; i++) {
	  double mid = (low + high) / 2.0;
	  double p_mid = get_t_pvalue(mid, df, "greater");
	  if (p_mid > p_tail) {
		   low = mid;
	  } else {
		   high = mid;
	  }
	  if (high - low < 1e-8) break;
	}
	return (low + high) / 2.0;
}

int compare_doubles(const void *restrict a, const void *restrict b) {
	double da = *(const double*restrict)a;
	double db = *(const double*restrict)b;
	return (da > db) - (da < db);
}
/* Helper to calculate the number of bins using Sturges' formula: log2(n) + 1 */
static size_t calculate_sturges_bins(size_t n) {
	if (n == 0) return 1;
	return (size_t)(log((double)n) / log(2.0) + 1.0);
}

// Logic for distributing data into bins (Optimized to O(N))
static void compute_hist_logic(double *restrict x, size_t n, double *restrict breaks, size_t n_bins, 
 size_t *restrict counts, double *restrict mids, double *restrict density) {
	double total_n = (double)n;
	double min_val = breaks[0];
	double step = (n_bins > 0) ? (breaks[1] - breaks[0]) : 0.0;
	// Initialize counts and compute midpoints
	for (size_t i = 0; i < n_bins; i++) {
	  counts[i] = 0;
	  mids[i] = (breaks[i] + breaks[i+1]) / 2.0;
	}
	// Single O(N) pass to assign elements to bins
	if (step > 0.0) {
		for (size_t j = 0; j < n; j++) {
			double val = x[j];
			// Ignore out-of-bounds or invalid values
			if (isnan(val) || isinf(val) || val < min_val) continue;
			// Calculate initial bin index mathematically
			size_t idx = (size_t)((val - min_val) / step);
			// Clamp to valid array bounds first to prevent overflow */
			if (idx >= n_bins) {
				 idx = n_bins - 1;
			}
			/* Adjust for exact boundaries (R's right-inclusive default: (a, b]) */
			/* If value is exactly on or slightly below the lower boundary of the assigned bin, 
				it belongs in the previous bin. (First bin [a, b] is inclusive on both ends) */
			while (idx > 0 && val <= breaks[idx]) {
				 idx--;
			}
			// Conversely, if floating-point truncation placed it too low, push it up
			while (idx < n_bins - 1 && val > breaks[idx + 1]) {
				 idx++;
			}
			counts[idx]++;
		}
	} else if (n_bins > 0) {
		// Edge case: All data points have the exact same value (step == 0)
		counts[0] = n;
	}
	// Compute densities
	for (size_t i = 0; i < n_bins; i++) {
		double bin_width = breaks[i+1] - breaks[i];
		if (bin_width > 0) {
			density[i] = (double)counts[i] / (total_n * bin_width);
		} else {
			density[i] = (n_bins == 1) ? 1.0 : 0.0;
		}
	}
}

// Standard Normal CDF approximation
double approx_pnorm(double x) {
	return 0.5 * erfc(-x * 0.70710678118654752440); // 0.707... = 1/sqrt(2)
}
#ifndef M_SQRT1_2
#define M_SQRT1_2 0.70710678118654752440
#endif

/* Macro for exact Wilcoxon 3D array indexing */
#define DP_INDEX(i, j, k, n2, max_u) ((i) * ((n2) + 1) * ((max_u) + 1) + (j) * ((max_u) + 1) + (k))
static double inverse_normal_cdf(double p) {
	double a[4] = {2.50662823884, -18.61500062529, 41.39119773534, -25.44106049637};
	double b[4] = {-8.47351093090, 23.08336743743, -21.06224101826, 3.13082909833};
	double c[9] = {0.3374754822726147, 0.9761690190917186, 0.1607979714918209,
		0.0276438810333863, 0.0038405729373609, 0.0003951896511919,
		0.0000321767881768, 0.0000002888167364, 0.0000003960315187};
	double x, r, y;
	y = p - 0.5;
	if (fabs(y) < 0.42) {
	  r = y * y;
	  x = y * (((a[3]*r + a[2])*r + a[1])*r + a[0]) /
		       ((((b[3]*r + b[2])*r + b[1])*r + b[0])*r + 1.0);
	} else {
	  r = p;
	  if (y > 0) r = 1.0 - p;
	  r = log(-log(r));
	  x = c[0] + r * (c[1] + r * (c[2] + r * (c[3] + r * (c[4] +
		   r * (c[5] + r * (c[6] + r * (c[7] + r * c[8])))))));
	  if (y < 0) x = -x;
	}
	return x;
}
/* -----------------------------------------------------------------------
 * Exact Spearman p-value via exhaustive permutation enumeration.
 *
 * Under H0, all n! orderings of ranks are equally probable.  We visit
 * every permutation of {1..n} with Heap's algorithm (O(n!), no allocs
 * inside the loop) and count how many yield S ≤ s_obs ("lower tail",
 * i.e. rho ≥ rho_obs) and how many yield S ≥ s_obs ("upper tail").
 *
 * Mirrors R's default: exact = (n < 10) with no ties.
 * Valid up to n = 9 (362 880 iterations — negligible cost).
 * ----------------------------------------------------------------------- */
static double spearman_exact_pvalue(double s_obs, size_t n, const char *restrict alt) {
	int *restrict perm = (int*)safemalloc(n * sizeof(int));
	int *restrict c    = (int*)safemalloc(n * sizeof(int));
	for (size_t i = 0; i < n; i++) { perm[i] = i + 1; c[i] = 0; }

	long count_le = 0, count_ge = 0, total = 0;

	#define TALLY_PERM() do {                                    \
	  double s_ = 0.0;                                     \
	  for (int ii = 0; ii < n; ii++) {                    \
		   double d_ = (double)(ii + 1) - (double)perm[ii];\
		   s_ += d_ * d_;                                   \
	  }                                                    \
	  if (s_ <= s_obs + 1e-9) count_le++;                 \
	  if (s_ >= s_obs - 1e-9) count_ge++;                 \
	  total++;                                             \
	} while (0)

	TALLY_PERM();   /* initial permutation [1, 2, ..., n] */

	unsigned int k = 1;
	while (k < n) {
		if (c[k] < k) {
			int tmp;
			if (k % 2 == 0) {
				 tmp = perm[0]; perm[0] = perm[k]; perm[k] = tmp;
			} else {
				 tmp = perm[c[k]]; perm[c[k]] = perm[k]; perm[k] = tmp;
			}
			TALLY_PERM();
			c[k]++;
			k = 1;
		} else {
			c[k] = 0;
			k++;
		}
	}
	#undef TALLY_PERM
	Safefree(perm); Safefree(c);
	/* p_le = P(S ≤ s_obs) ≡ P(rho ≥ rho_obs)  — upper rho tail
	* p_ge = P(S ≥ s_obs) ≡ P(rho ≤ rho_obs)  — lower rho tail  */
	double p_le = (double)count_le / (double)total;
	double p_ge = (double)count_ge / (double)total;

	if (strcmp(alt, "greater") == 0) return p_le;
	if (strcmp(alt, "less")    == 0) return p_ge;
	/* two.sided: 2 × the smaller tail, clamped to 1 */
	double p = 2.0 * (p_le < p_ge ? p_le : p_ge);
	return (p > 1.0) ? 1.0 : p;
}
/* -----------------------------------------------------------------------
 * Exact Kendall p-value via Mahonian Numbers (Inversions distribution)
 * Matches R's behavior for N < 50 without ties.
 * ----------------------------------------------------------------------- */
static double kendall_exact_pvalue(size_t n, double s_obs, const char *restrict alt) {
	long max_inv = (long)n * (n - 1) / 2;
	double *restrict dp = (double*)safemalloc((max_inv + 1) * sizeof(double));
	for (long i = 0; i <= max_inv; i++) dp[i] = 0.0;
	dp[0] = 1.0;
	/* Build the distribution of inversions via DP */
	for (size_t i = 2; i <= n; i++) {
		double *restrict next_dp = (double*)safemalloc((max_inv + 1) * sizeof(double));
		for (long k = 0; k <= max_inv; k++) next_dp[k] = 0.0;
		int current_max_inv = i * (i - 1) / 2;
		for (int k = 0; k <= current_max_inv; k++) {
			double sum = 0;
			for (int j = 0; j <= i - 1 && k - j >= 0; j++) {
				 sum += dp[k - j];
			}
			// Divide by 'i' directly to keep array as pure probabilities and prevent overflow
			next_dp[k] = sum / (double)i;
		}
		Safefree(dp);
		dp = next_dp;
	}
	// Convert S statistic to target number of inversions
	long i_obs = (long)round((max_inv - s_obs) / 2.0);
	if (i_obs < 0) i_obs = 0;
	if (i_obs > max_inv) i_obs = max_inv;
	double p_le = 0.0; /* P(S <= S_obs) */
	for (long k = i_obs; k <= max_inv; k++) p_le += dp[k];
	double p_ge = 0.0; /* P(S >= S_obs) */
	for (long k = 0; k <= i_obs; k++) p_ge += dp[k];
	Safefree(dp);
	if (strcmp(alt, "greater") == 0) return p_ge;
	if (strcmp(alt, "less") == 0) return p_le;
	// two.sided
	double p = 2.0 * (p_ge < p_le ? p_ge : p_le);
	return p > 1.0 ? 1.0 : p;
}
// F-distribution Cumulative Distribution Function P(F <= f)
static double pf(double f, double df1, double df2) {
	if (f <= 0.0) return 0.0;
	double x = (df1 * f) / (df1 * f + df2);
	return incbeta(df1 / 2.0, df2 / 2.0, x);
}

/* Householder QR Decomposition for Sequential Sums of Squares */
/* Householder QR Decomposition for Sequential Sums of Squares */
static void apply_householder_aov(double** restrict X, double* restrict y, size_t n, size_t p, bool* restrict aliased, size_t* restrict rank_map) {
	size_t r = 0; // Rank/Row tracker
	for (size_t k = 0; k < p; k++) {
		aliased[k] = FALSE;
		if (r >= n) {
			aliased[k] = TRUE;
			continue;
		}

		double max_val = 0;
		for (size_t i = r; i < n; i++) {
			if (fabs(X[i][k]) > max_val) max_val = fabs(X[i][k]);
		}
		if (max_val < 1e-10) { 
			aliased[k] = TRUE; 
			continue; 
		} // Collinear or zero column

		double norm = 0;
		for (size_t i = r; i < n; i++) {
			X[i][k] /= max_val;
			norm += X[i][k] * X[i][k];
		}
		norm = sqrt(norm);
		double s = (X[r][k] > 0) ? -norm : norm;
		double u1 = X[r][k] - s;
		X[r][k] = s * max_val;

		for (size_t j = k + 1; j < p; j++) {
			double dot = u1 * X[r][j];
			for (size_t i = r + 1; i < n; i++) dot += X[i][j] * X[i][k];
			double tau = dot / (s * u1);
			X[r][j] += tau * u1;
			for (size_t i = r + 1; i < n; i++) X[i][j] += tau * X[i][k];
		}

		// Transform the response vector y
		double dot_y = u1 * y[r];
		for (size_t i = r + 1; i < n; i++) dot_y += y[i] * X[i][k];
		double tau_y = dot_y / (s * u1);
		y[r] += tau_y * u1;
		for (size_t i = r + 1; i < n; i++) y[i] += tau_y * X[i][k];

		rank_map[k] = r; // Map original column index to orthogonal row index
		r++;
	}
}

// --- write_table Helpers ---

// Sorts string arrays alphabetically
static int cmp_string_wt(const void *a, const void *b) {
	return strcmp(*(const char**)a, *(const char**)b);
}

// Emulates Perl's /\D/ check
static bool contains_nondigit(pTHX_ SV *restrict sv) {
	if (!sv || !SvOK(sv)) return 0;
	STRLEN len;
	char *restrict s = SvPVbyte(sv, len);
	for (size_t i = 0; i < len; i++) {
	  if (!isdigit(s[i])) return 1;
	}
	return 0;
}

// Writes a properly quoted string dynamically
static void print_str_quoted(PerlIO *fh, const char *str, const char *sep) {
	if (!str) str = "";
	bool needs_quotes = 0;
	if (strstr(str, sep) != NULL || strchr(str, '"') != NULL || strchr(str, '\r') != NULL || strchr(str, '\n') != NULL) {
	  needs_quotes = 1;
	}

	if (needs_quotes) {
	  PerlIO_putc(fh, '"');
	  for (const char *restrict p = str; *p; p++) {
		   if (*p == '"') {
		       PerlIO_putc(fh, '"');
		       PerlIO_putc(fh, '"');
		   } else {
		       PerlIO_putc(fh, *p);
		   }
	  }
	  PerlIO_putc(fh, '"');
	} else {
	  PerlIO_puts(fh, str);
	}
}

// Writes an array of strings joined by sep
static void print_string_row(pTHX_ PerlIO *fh, const char **row, size_t len, const char *sep) {
	size_t sep_len = strlen(sep);
	for (size_t i = 0; i < len; i++) {
	  if (i > 0) PerlIO_write(fh, sep, sep_len);
	  if (row[i]) {
		   print_str_quoted(fh, row[i], sep);
	  } else {
		   print_str_quoted(fh, "", sep);
	  }
	}
	PerlIO_putc(fh, '\n');
}
// Calculates the Regularized Upper Incomplete Gamma Function Q(a, x)
// This perfectly replicates R's pchisq(..., lower.tail=FALSE)
double igamc(double a, double x) {
	if (x < 0.0 || a <= 0.0) return 1.0;
	if (x == 0.0) return 1.0;

	// Series expansion for x < a + 1
	if (x < a + 1.0) {
		double sum = 1.0 / a;
		double term = 1.0 / a;
		double n = 1.0;
		while (fabs(term) > 1e-15) {
			term *= x / (a + n);
			sum += term;
			n += 1.0;
		}
		return 1.0 - (sum * exp(-x + a * log(x) - lgamma(a)));
	}

	// Continued fraction for x >= a + 1
	double b = x + 1.0 - a;
	double c = 1.0 / 1e-30;
	double d = 1.0 / b;
	double h = d, i = 1.0;
	while (i < 10000) { // Safety bound
		double an = -i * (i - a);
		b += 2.0;
		d = an * d + b;
		if (fabs(d) < 1e-30) d = 1e-30;
		c = b + an / c;
		if (fabs(c) < 1e-30) c = 1e-30;
		d = 1.0 / d;
		double del = d * c;
		h *= del;
		if (fabs(del - 1.0) < 1e-15) break;
		i += 1.0;
	}
	return h * exp(-x + a * log(x) - lgamma(a));
}

// Chi-Squared p-value is simply the Incomplete Gamma of (df/2, stat/2)
double get_p_value(double stat, int df) {
	if (df <= 0) return 1.0;
	if (stat <= 0.0) return 1.0;
	return igamc((double)df / 2.0, stat / 2.0);
}

/* --- C HELPER SECTION --- */
#ifndef M_SQRT1_2
#define M_SQRT1_2 0.70710678118654752440
#endif

/* Robust Binomial Coefficient using long double */
static long double choose_comb(int n, int k) {
	if (k < 0 || k > n) return 0.0L;
	if (k > n / 2) k = n - k;
	long double res = 1.0L;
	for (int i = 1; i <= k; i++) {
	  res = res * (long double)(n - i + 1) / (long double)i;
	}
	return res;
}

/* Exact CDF for Mann-Whitney U: P(U <= q) 
   Mathematically identical to R's cwilcox generating function */
static double exact_pwilcox(double q, int m, int n) {
	int k = (int)floor(q + 1e-7); // R uses 1e-7 fuzz
	int max_u = m * n;
	if (k < 0) return 0.0;
	if (k >= max_u) return 1.0;

	long double *restrict w = (long double *)safecalloc(max_u + 1, sizeof(long double));
	w[0] = 1.0L;

	for (int j = 1; j <= n; j++) {
	  for (int i = j; i <= max_u; i++) w[i] += w[i - j];
	  for (int i = max_u; i >= j + m; i--) w[i] -= w[i - j - m];
	}

	long double cum_p = 0.0L;
	for (int i = 0; i <= k; i++) cum_p += w[i];

	long double total = choose_comb(m + n, n);
	double result = (double)(cum_p / total);

	Safefree(w);
	return result;
}

/* Exact CDF for Wilcoxon Signed Rank: P(V <= q) 
   Mathematically identical to R's csignrank subset-sum DP */
static double exact_psignrank(double q, int n) {
	int k = (int)floor(q + 1e-7);
	int max_v = n * (n + 1) / 2;
	if (k < 0) return 0.0;
	if (k >= max_v) return 1.0;

	long double *restrict w = (long double *)safecalloc(max_v + 1, sizeof(long double));
	w[0] = 1.0L;

	for (int i = 1; i <= n; i++) {
	  for (int j = max_v; j >= i; j--) w[j] += w[j - i];
	}

	long double cum_p = 0.0L;
	for (int i = 0; i <= k; i++) cum_p += w[i];

	long double total = powl(2.0L, (long double)n);
	double result = (double)(cum_p / total);

	Safefree(w);
	return result;
}

static int cmp_rank_info(const void *a, const void *b) {
	double da = ((const RankInfo*)a)->val;
	double db = ((const RankInfo*)b)->val;
	return (da > db) - (da < db);
}

static double rank_and_count_ties(RankInfo *restrict ri, size_t n, bool *restrict has_ties) {
	if (n == 0) return 0.0;
	qsort(ri, n, sizeof(RankInfo), cmp_rank_info);
	size_t i = 0;
	double tie_adj = 0.0;
	*has_ties = 0;
	while (i < n) {
		size_t j = i + 1;
		while (j < n && ri[j].val == ri[i].val) j++;
		double r = (double)(i + 1 + j) / 2.0; 
		for (size_t k = i; k < j; k++) ri[k].rank = r;
		size_t t = j - i;
		if (t > 1) { *has_ties = 1; tie_adj += ((double)t * t * t - t); }
		i = j;
	}
	return tie_adj;
}
/* --- KS-TEST C HELPER SECTION --- */
#ifndef M_PI_2
#define M_PI_2 1.57079632679489661923
#endif
#ifndef M_PI_4
#define M_PI_4 0.78539816339744830962
#endif
#ifndef M_1_SQRT_2PI
#define M_1_SQRT_2PI 0.39894228040143267794
#endif

// Scalar integer power used by K2x
static double r_pow_di(double x, int n) {
	if (n == 0) return 1.0;
	if (n < 0) return 1.0 / r_pow_di(x, -n);
	double val = 1.0;
	for (int i = 0; i < n; i++) val *= x;
	return val;
}

// Two-sample two-sided asymptotic distribution
static double K2l(double x, int lower, double tol) {
	double s, z, p;
	int k;
	if(x <= 0.) {
	  if(lower) p = 0.;
	  else p = 1.;
	} else if(x < 1.) {
	  int k_max = (int) sqrt(2.0 - log(tol));
	  double w = log(x);
	  z = - (M_PI_2 * M_PI_4) / (x * x);
	  s = 0;
	  for(k = 1; k < k_max; k += 2) {
		   s += exp(k * k * z - w);
	  }
	  p = s / M_1_SQRT_2PI;
	  if(!lower) p = 1.0 - p;
	} else {
	  double new_val, old_val;
	  z = -2.0 * x * x;
	  s = -1.0;
	  if(lower) {
		   k = 1; old_val = 0.0; new_val = 1.0;
	  } else {
		   k = 2; old_val = 0.0; new_val = 2.0 * exp(z);
	  }
	  while(fabs(old_val - new_val) > tol) {
		   old_val = new_val;
		   new_val += 2.0 * s * exp(z * k * k);
		   s *= -1.0;
		   k++;
	  }
	  p = new_val;
	}
	return p;
}

// Auxiliary routines used by K2x() for matrix operations
static void m_multiply(double *A, double *B, double *C, unsigned int m) {
	for(unsigned int i = 0; i < m; i++) {
	  for(unsigned int j = 0; j < m; j++) {
		   double s = 0.;
		   for(unsigned int k = 0; k < m; k++) s += A[i * m + k] * B[k * m + j];
		   C[i * m + j] = s;
	  }
	}
}

static void m_power(double *A, int eA, double *V, int *eV, int m, int n) {
	if(n == 1) {
	  for(int i = 0; i < m * m; i++) V[i] = A[i];
	  *eV = eA;
	  return;
	}
	m_power(A, eA, V, eV, m, n / 2);
	double *restrict B = (double*) safecalloc(m * m, sizeof(double));
	m_multiply(V, V, B, m);
	int eB = 2 * (*eV);
	if((n % 2) == 0) {
	  for(int i = 0; i < m * m; i++) V[i] = B[i];
	  *eV = eB;
	} else {
	  m_multiply(A, B, V, m);
	  *eV = eA + eB;
	}
	if(V[(m / 2) * m + (m / 2)] > 1e140) {
	  for(int i = 0; i < m * m; i++) V[i] = V[i] * 1e-140;
	  *eV += 140;
	}
	Safefree(B);
}

// One-sample two-sided exact distribution
static double K2x(int n, double d) {
	int k = (int) (n * d) + 1;
	int m = 2 * k - 1;
	double h = k - n * d;
	double *restrict H = (double*) safecalloc(m * m, sizeof(double));
	double *restrict Q = (double*) safecalloc(m * m, sizeof(double));

	for(int i = 0; i < m; i++) {
	  for(int j = 0; j < m; j++) {
		   if(i - j + 1 < 0) H[i * m + j] = 0;
		   else H[i * m + j] = 1;
	  }
	}
	for(int i = 0; i < m; i++) {
	  H[i * m] -= r_pow_di(h, i + 1);
	  H[(m - 1) * m + i] -= r_pow_di(h, (m - i));
	}
	H[(m - 1) * m] += ((2 * h - 1 > 0) ? r_pow_di(2 * h - 1, m) : 0);

	for(int i = 0; i < m; i++) {
	  for(int j = 0; j < m; j++) {
		   if(i - j + 1 > 0) {
		       for(int g = 1; g <= i - j + 1; g++) H[i * m + j] /= g;
		   }
	  }
	}

	int eH = 0, eQ;
	m_power(H, eH, Q, &eQ, m, n);
	double s = Q[(k - 1) * m + k - 1];

	for(int i = 1; i <= n; i++) {
	  s = s * (double)i / (double)n;
	  if(s < 1e-140) {
		   s *= 1e140;
		   eQ -= 140;
	  }
	}
	s *= pow(10.0, eQ);
	Safefree(H);
	Safefree(Q);
	return s;
}

// Calculate D (two-sided), D+ (greater), and D- (less) simultaneously
static void calc_2sample_stats(double *x, size_t nx, double *y, size_t ny,
                               double *d, double *d_plus, double *d_minus) {
	qsort(x, nx, sizeof(double), compare_doubles);
	qsort(y, ny, sizeof(double), compare_doubles);
	double max_d = 0.0, max_d_plus = 0.0, max_d_minus = 0.0;
	size_t i = 0, j = 0;

	while(i < nx || j < ny) {
	  double val;
	  if (i < nx && j < ny) val = (x[i] < y[j]) ? x[i] : y[j];
	  else if (i < nx) val = x[i];
	  else val = y[j];
	  
	  while(i < nx && x[i] <= val) i++;
	  while(j < ny && y[j] <= val) j++;
	  
	  double cdf1 = (double)i / nx;
	  double cdf2 = (double)j / ny;
	  double diff = cdf1 - cdf2;
	  
	  if (diff > max_d_plus) max_d_plus = diff;
	  if (-diff > max_d_minus) max_d_minus = -diff;
	  if (fabs(diff) > max_d) max_d = fabs(diff);
	}
	*d = max_d;
	*d_plus = max_d_plus;
	*d_minus = max_d_minus;
}

// Branch the DP boundary check based on the 'alternative'
static int psmirnov_exact_test(double q, double r, double s, int two_sided) {
	if (two_sided) return (fabs(r - s) >= q);
	return ((r - s) >= q); // Used for both D+ and D- via symmetry
}

// Evaluate the exact 2-sample probability
static double psmirnov_exact_uniq_upper(double q, int m, int n, int two_sided) {
	double md = (double) m, nd = (double) n;
	double *restrict u = (double *) safecalloc(n + 1, sizeof(double));
	u[0] = 0.;

	for(unsigned int j = 1; j <= n; j++) {
	  if(psmirnov_exact_test(q, 0., j / nd, two_sided)) u[j] = 1.;
	  else u[j] = u[j - 1];
	}
	for(unsigned int i = 1; i <= m; i++) {
		if(psmirnov_exact_test(q, i / md, 0., two_sided)) u[0] = 1.;
		for(int j = 1; j <= n; j++) {
			if(psmirnov_exact_test(q, i / md, j / nd, two_sided)) u[j] = 1.;
			else {
				 double v = (double)(i) / (double)(i + j);
				 double w = (double)(j) / (double)(i + j);
				 u[j] = v * u[j] + w * u[j - 1];
			}
		}
	}
	double res = u[n];
	Safefree(u);
	return res;
}

static double p_body(double n, double delta, double sd, double sig_level, int tsample, int tside, bool strict) {
	double nu = (n - 1.0) * (double)tsample;
	if (nu < 1e-7) nu = 1e-7; 

	// Ensure sig_level/tside is not truncated
	double p_tail = sig_level / (double)tside;
	double qu = qt_tail(nu, p_tail); // qt(p, df, lower.tail=FALSE)

	double ncp = sqrt(n / (double)tsample) * (delta / sd);

	if (strict && tside == 2) {
	  // Use R-style tail calls: 1 - P(T < qu) + P(T < -qu)
	  return (1.0 - exact_pnt(qu, nu, ncp)) + exact_pnt(-qu, nu, ncp);
	} else {
	  // Default: 1 - P(T < qu)
	  // Ensure exact_pnt is using a convergence tolerance of at least 1e-15
	  return 1.0 - exact_pnt(qu, nu, ncp);
	}
}

// Bisection algorithm to find the inverse F-distribution (Quantile function)
// Equivalent to R's qf(p, df1, df2)
static double qf_bisection(double p, double df1, double df2) {
	if (p <= 0.0) return 0.0;
	if (p >= 1.0) return INFINITY;
	double low = 0.0, high = 1.0;
	// Find upper bound
	while (pf(high, df1, df2) < p) {
	  low = high;
	  high *= 2.0;
	  if (high > 1e100) break; /* Fallback limit */
	}

	// Bisect to find the root
	for (unsigned short int i = 0; i < 150; i++) {
		double mid = low + (high - low) / 2.0;
		double p_mid = pf(mid, df1, df2);

		if (p_mid < p) {
			low = mid;
		} else {
			high = mid;
		}
		if (high - low < 1e-12) break;
	}
	return (low + high) / 2.0;
}
/* oneway_test  –  Welch / classic one-way ANOVA
 *
 * ── Mode 1: hash of groups (original behaviour) ───────────────────────────
 *
 *   my $res = oneway_test(\%groups);
 *   my $res = oneway_test(\%groups, var_equal => 1);
 *
 *   \%groups  – keys are group labels, values are array refs of numbers.
 *               Every group must have >= 2 observations.
 *
 * ── Mode 2: formula – response ~ factor ───────────────────────────────────
 *
 *   my $res = oneway_test(\%data, formula => "yield ~ ctrl");
 *   my $res = oneway_test(\%data, formula => "yield ~ ctrl", var_equal => 1);
 *
 *   \%data must contain two keys matching the formula:
 *     "yield" => [ numeric response values ... ]
 *     "ctrl"  => [ group labels (strings or numbers, same length) ... ]
 *
 *   This mirrors R's:
 *     my_data <- stack(list(yield = yield, ctrl = ctrl))
 *     oneway.test(Value ~ Group, data = my_data)
 *
 *   Absence of a formula argument falls back to Mode 1 automatically.
 *
 * ── Return value (both modes)
 *
 *   Hash ref with keys:
 *     statistic => F value
 *     num_df    => numerator degrees of freedom   (k − 1)
 *     denom_df  => denominator degrees of freedom
 *     p_value   => upper-tail p-value  P(F ≥ statistic)
 *     method    => description string
 *     k         => number of groups
 *     n         => total observations
 *     formula   => "response ~ factor"  (only present in Mode 2)
 *
 * =========================================================================
 * Integration: drop the C block above "--- XS SECTION ---", and the XS
 * block inside your MODULE … PACKAGE … PREFIX = section.
 * =========================================================================
 */

/* C HELPERS  (place above "--- XS SECTION ---") */

/* ── OneWayResult struct */
typedef struct {
	double  statistic;
	double  num_df;
	double  denom_df;
	double  p_value;
	double  ss_between;  /* between-group sum of squares  */
	double  ss_within;   /* within-group  sum of squares  */
	double  ms_between;  /* ss_between / num_df           */
	double  ms_within;   /* ss_within  / denom_df         */
	int     k;           /* number of groups              */
	IV      n;           /* total observations            */
	int     var_equal;   /* 0 = Welch, 1 = classic        */
} OneWayResult;

/* ── c_oneway_test ───────────────────────────────────────────────────────
 *
 *  data      – flat C array of all observations, groups concatenated
 *  sizes     – n_i for each group (length k)
 *  k         – number of groups
 *  var_equal – 0 = Welch (default), 1 = classic equal-variance F-test
 *
 *  Mirrors R's oneway.test() arithmetic exactly.
 *  Calls pf(f, df1, df2) declared elsewhere in the .xs file.
 * ----------------------------------------------------------------------- */
static OneWayResult
c_oneway_test(const double *restrict data,
              const size_t *restrict sizes,
              size_t k,
              int var_equal)
{
	OneWayResult res;
	res.var_equal = var_equal;
	res.k         = (int)k;

	double *restrict n_i = (double *)safemalloc(k * sizeof(double));
	double *restrict m_i = (double *)safemalloc(k * sizeof(double));
	double *restrict v_i = (double *)safemalloc(k * sizeof(double));

	size_t offset = 0;
	IV total_n = 0;
	for (size_t g = 0; g < k; g++) {
	  size_t ng  = sizes[g];
	  n_i[g]     = (double)ng;
	  total_n   += (IV)ng;

	  double sum = 0.0;
	  for (size_t i = 0; i < ng; i++) sum += data[offset + i];
	  double mean = sum / (double)ng;
	  m_i[g] = mean;

	  double ss = 0.0;
	  for (size_t i = 0; i < ng; i++) {
		   double d = data[offset + i] - mean;
		   ss += d * d;
	  }
	  v_i[g] = ss / (double)(ng - 1);   /* ng >= 2 guaranteed by caller */
	  offset += ng;
	}

	res.n = total_n;

	/* grand mean (simple average over all obs; used only by classic branch) */
	double grand_mean = 0.0;
	for (IV i = 0; i < (IV)total_n; i++) grand_mean += data[i];
	grand_mean /= (double)total_n;

	double df1 = (double)(k - 1);

	if (var_equal) {
		/* ── Classic one-way ANOVA ─────────────────────────────────────── *
		*  F = [Σ n_i·(m_i − ȳ)² / (k−1)]  /  [Σ (n_i−1)·v_i / (n−k)] *
		* ─────────────────────────────────────────────────────────────── */
		double ssbg = 0.0, sswg = 0.0;
		for (size_t g = 0; g < k; g++) {
			double dm = m_i[g] - grand_mean;
			ssbg += n_i[g] * dm * dm;
			sswg += (n_i[g] - 1.0) * v_i[g];
		}
		double df2    = (double)(total_n - (IV)k);
		res.statistic = (ssbg / df1) / (sswg / df2);
		res.num_df    = df1;
		res.denom_df  = df2;
		res.ss_between = ssbg;
		res.ss_within  = sswg;
		res.ms_between = ssbg / df1;
		res.ms_within  = sswg / df2;
	} else {
		/* ── Welch one-way (heteroscedastic) ───────────────────────────── *
		*  w_i  = n_i / v_i                                               *
		*  W    = Σ w_i                                                   *
		*  m̃    = Σ(w_i·m_i) / W          (weighted grand mean)           *
		*  tmp  = Σ[(1 − w_i/W)² / (n_i−1)] / (k²−1)                    *
		*  F    = Σ[w_i·(m_i − m̃)²] / [(k−1)·(1 + 2·(k−2)·tmp)]        *
		*  df2  = 1 / (3·tmp)                                             *
		*                                                                 *
		*  SS values use the unweighted grand mean (same as classic)      *
		*  so the output table is always populated.                        *
		* ─────────────────────────────────────────────────────────────── */
		double *restrict w_i = (double *)safemalloc(k * sizeof(double));
		double sum_w = 0.0;
		for (size_t g = 0; g < k; g++) { w_i[g] = n_i[g] / v_i[g]; sum_w += w_i[g]; }
		double wgrand = 0.0;
		for (size_t g = 0; g < k; g++) wgrand += w_i[g] * m_i[g];
		wgrand /= sum_w;
		double tmp = 0.0;
		for (size_t g = 0; g < k; g++) {
			double t = 1.0 - w_i[g] / sum_w;
			tmp += (t * t) / (n_i[g] - 1.0);
		}
		tmp /= ((double)k * (double)k - 1.0);   /* k² − 1 */
		double num = 0.0;
		for (size_t g = 0; g < k; g++) {
			double dm = m_i[g] - wgrand;
			num += w_i[g] * dm * dm;
		}
		res.statistic = num / (df1 * (1.0 + 2.0 * (double)(k - 2) * tmp));
		res.num_df    = df1;
		res.denom_df  = (tmp > 0.0) ? (1.0 / (3.0 * tmp)) : 1e300;
		/* unweighted SS for the output table */
		double ssbg = 0.0, sswg = 0.0;
		for (size_t g = 0; g < k; g++) {
			double dm = m_i[g] - grand_mean;
			ssbg += n_i[g] * dm * dm;
			sswg += (n_i[g] - 1.0) * v_i[g];
		}
		res.ss_between = ssbg;
		res.ss_within  = sswg;
		res.ms_between = (df1  > 0.0) ? ssbg / df1          : 0.0;
		res.ms_within  = (res.denom_df > 0.0) ? sswg / res.denom_df : 0.0;
		Safefree(w_i);
	}
	/* upper-tail p-value  P(F ≥ statistic) */
	res.p_value = 1 - pf(res.statistic, res.num_df, res.denom_df);
	Safefree(n_i);    Safefree(m_i);    Safefree(v_i);
	return res;
}

/* ── parse_formula
 *
 *  Splits "response ~ factor" into two NUL-terminated, heap-allocated
 *  strings.  Leading/trailing whitespace is stripped from each side.
 *  Returns 1 on success, 0 on failure (malformed / missing '~').
 *  Caller must Safefree() both *lhs and *rhs on success.
 * ----------------------------------------------------------------------- */
static int
parse_formula(const char *formula, char **lhs, char **rhs)
{
	const char *restrict tilde = strchr(formula, '~');
	if (!tilde) return 0;

	/* left-hand side: trim trailing whitespace */
	const char *l_start = formula;
	const char *l_end   = tilde - 1;
	while (l_end >= l_start && isspace((unsigned char)*l_end)) l_end--;
	if (l_end < l_start) return 0;             /* empty LHS */

	/* right-hand side: trim leading whitespace */
	const char *restrict r_start = tilde + 1;
	while (*r_start && isspace((unsigned char)*r_start)) r_start++;
	const char *restrict r_end = r_start + strlen(r_start) - 1;
	while (r_end >= r_start && isspace((unsigned char)*r_end)) r_end--;
	if (r_end < r_start) return 0;             /* empty RHS */

	size_t llen = (size_t)(l_end - l_start + 1);
	size_t rlen = (size_t)(r_end - r_start + 1);

	*lhs = (char *)safemalloc(llen + 1);
	*rhs = (char *)safemalloc(rlen + 1);
	memcpy(*lhs, l_start, llen); (*lhs)[llen] = '\0';
	memcpy(*rhs, r_start, rlen); (*rhs)[rlen] = '\0';
	return 1;
}

/* ── build_groups_from_formula ───────────────────────────────────────────
 *
 *  Takes parallel response[] and label[] arrays (each length n) and
 *  partitions them into groups, filling:
 *    out_flat[]  – observations sorted into contiguous group blocks
 *    out_sizes[] – number of observations per group  (caller allocates n
 *                  slots for both; actual group count returned via *out_k)
 *    out_names   – if non-NULL, receives a heap-allocated char** of k
 *                  group-name strings (caller must free each and the array)
 *
 *  Group identity is the string representation of each label element
 *  (SvPV_nolen), so integer 0 and string "0" are the same group.
 *  Groups are ordered by first appearance in label[], matching R's
 *  factor level ordering from stack().
 *
 *  Returns 1 on success; 0 if any validation error (sets errbuf).
 */
#define OWT_MAX_GROUPS 1024   /* sane ceiling; ANOVA with >1024 groups is absurd */

static int
build_groups_from_formula(pTHX_
	AV *restrict response_av,
	AV *restrict label_av,
	double *restrict out_flat,
	size_t *restrict out_sizes,
	size_t *restrict out_k,
	char ***restrict out_names,
	char *restrict errbuf,
	size_t errbuf_len)
{
	IV n = av_len(response_av) + 1;
	IV nl = av_len(label_av)   + 1;

	if (n != nl) {
	  snprintf(errbuf, errbuf_len,
		   "formula: response length (%"IVdf") != factor length (%"IVdf")",
		   n, nl);
	  return 0;
	}
	if (n < 2) {
	  snprintf(errbuf, errbuf_len, "formula: need at least 2 observations");
	  return 0;
	}

	/* ── discover unique group labels in order of first appearance ─── */
	/* We store pointers into a heap-allocated label string table.       */
	char  **restrict group_names  = (char **)safemalloc(OWT_MAX_GROUPS * sizeof(char *));
	size_t  ngroups      = 0;
	IV     *restrict obs_group    = (IV *)safemalloc((size_t)n * sizeof(IV));
		/* maps obs index → group index */

	for (IV i = 0; i < n; i++) {
	  SV **lsv = av_fetch(label_av, i, 0);
	  const char *label = (lsv && *lsv) ? SvPV_nolen(*lsv) : "";

	  /* linear scan for existing group (k is small, O(n·k) is fine) */
	  IV gidx = -1;
	  for (size_t g = 0; g < ngroups; g++) {
		   if (strEQ(group_names[g], label)) { gidx = (IV)g; break; }
	  }
	  if (gidx < 0) {
		   if (ngroups >= OWT_MAX_GROUPS) {
		       snprintf(errbuf, errbuf_len,
		           "formula: too many distinct groups (max %d)", OWT_MAX_GROUPS);
		       Safefree(group_names);
		       Safefree(obs_group);
		       return 0;
		   }
		   /* new group: copy the label string */
		   size_t lablen = strlen(label);
		   group_names[ngroups] = (char *)safemalloc(lablen + 1);
		   memcpy(group_names[ngroups], label, lablen + 1);
		   gidx = (IV)ngroups++;
	  }
	  obs_group[i] = gidx;
	}

	if (ngroups < 2) {
	  snprintf(errbuf, errbuf_len,
		   "formula: need at least 2 distinct groups, found %zu", ngroups);
	  for (size_t g = 0; g < ngroups; g++) Safefree(group_names[g]);
	  Safefree(group_names);  Safefree(obs_group);
	  return 0;
	}

	/* count per-group sizes */
	memset(out_sizes, 0, ngroups * sizeof(size_t));
	for (unsigned i = 0; i < n; i++) out_sizes[obs_group[i]]++;

	/* validate: every group needs >= 2 observations */
	for (size_t g = 0; g < ngroups; g++) {
	  if (out_sizes[g] < 2) {
		   snprintf(errbuf, errbuf_len,
		       "formula: group '%s' has only %zu observation(s); need >= 2",
		       group_names[g], out_sizes[g]);
		   for (size_t gg = 0; gg < ngroups; gg++) Safefree(group_names[gg]);
		   Safefree(group_names);  Safefree(obs_group);
		   return 0;
	  }
	}

	/* ── fill flat output array in group order ─────────────────────── *
	*  We compute a running write-offset per group, then scatter.      *
	*/
	size_t *restrict write_pos = (size_t *)safemalloc(ngroups * sizeof(size_t));
	write_pos[0] = 0;
	for (size_t g = 1; g < ngroups; g++)
	  write_pos[g] = write_pos[g - 1] + out_sizes[g - 1];

	for (IV i = 0; i < n; i++) {
	  SV **restrict rsv = av_fetch(response_av, i, 0);
	  double val = (rsv && *rsv) ? SvNV(*rsv) : 0.0;
	  size_t g   = (size_t)obs_group[i];
	  out_flat[write_pos[g]++] = val;
	}

	*out_k = ngroups;

	/* ── clean up or hand off group names */
	Safefree(write_pos);	Safefree(obs_group);
	if (out_names) {
	  *out_names = group_names;   /* caller takes ownership */
	} else {
	  for (size_t g = 0; g < ngroups; g++) Safefree(group_names[g]);
	  Safefree(group_names);
	}
	return 1;
}
#undef OWT_MAX_GROUPS
// --- Math Macros ---
#ifndef M_LN_SQRT_2PI
#define M_LN_SQRT_2PI 0.91893853320467274178
#endif
#ifndef M_LN2
#define M_LN2 0.69314718055994530941
#endif
#ifndef M_1_SQRT_2PI
#define M_1_SQRT_2PI 0.39894228040143267794
#endif

/* c_dnorm: Normal distribution PDF
 *
 * Mathematically identical to R's dnorm4.
 * Includes Morten Welinder's precision improvements for extreme tails.
 * ----------------------------------------------------------------------- */
static double c_dnorm(double x, double mu, double sigma, int give_log) {
	// Propagate NaNs
	if (isnan(x) || isnan(mu) || isnan(sigma)) return x + mu + sigma; 

	if (sigma < 0.0) {
	  warn("dnorm: standard deviation must be non-negative");
	  return NAN;
	}
	if (isinf(sigma)) return 0.0;
	if ((isnan(x) || isinf(x)) && mu == x) return NAN; // x-mu is NaN

	// Dirac delta behavior for zero variance
	if (sigma == 0.0) return (x == mu) ? INFINITY : 0.0;

	// Standardize x
	x = (x - mu) / sigma;
	if (isnan(x) || isinf(x)) return 0.0;

	x = fabs(x);

	// Catch massive limits early to prevent math overflow
	if (x >= 2.0 * sqrt(DBL_MAX)) return 0.0;

	if (give_log) {
	  return -(M_LN_SQRT_2PI + 0.5 * x * x + log(sigma));
	}

	/* Naive formula for standard bodies */
	if (x < 5.0) {
	  return M_1_SQRT_2PI * exp(-0.5 * x * x) / sigma;
	}

	// Underflow boundary check using IEEE float characteristics
	if (x > sqrt(-2.0 * M_LN2 * (DBL_MIN_EXP + 1.0 - DBL_MANT_DIG))) {
	  return 0.0;
	}

	/* Splitting x to dodge floating point inaccuracies in x^2 for large x.
	* x = x1 + x2, where |x2| <= 2^-16
	* trunc() safely substitutes R_forceint() */
	double x1 = ldexp(trunc(ldexp(x, 16)), -16);
	double x2 = x - x1;

	return (M_1_SQRT_2PI / sigma) * (exp(-0.5 * x1 * x1) * exp((-0.5 * x2 - x1) * x2));
}
// --- XS SECTION ---
MODULE = Stats::LikeR  PACKAGE = Stats::LikeR

SV *oneway_test(data_ref, ...)
	SV *data_ref
	PREINIT:
    HV          *restrict in_hv = NULL;
    AV          *restrict in_av = NULL;
    HE          *restrict he;
    bool         var_equal = 0;
    const char  *restrict formula_str  = NULL;
    const char  *restrict factor_name  = "Group";
    char        *lhs = NULL, *rhs = NULL;
    double      *restrict flat   = NULL;
    size_t      *restrict sizes  = NULL;
    char       ** gnames = NULL;
    double      *restrict gmeans = NULL;
    size_t       k = 0;
    IV           total_n = 0;
    OneWayResult res;
    HV          *restrict ret_hv;
    char         errbuf[512];
    CODE:
	/* parse named arguments */
	for (I32 ai = 1; ai + 1 < items; ai += 2) {
		const char *restrict key = SvPV_nolen(ST(ai));
		SV *restrict val = ST(ai + 1);
		if (strEQ(key, "var_equal"))
			var_equal = SvTRUE(val) ? 1 : 0;
		else if (strEQ(key, "formula"))
			formula_str = SvPV_nolen(val);
	}
	/* validate data_ref and determine if it's an Array or Hash */
	if (!SvROK(data_ref))
	  croak("oneway_test: first argument must be a hash or array reference");
	
	SV *restrict rv = SvRV(data_ref);
	if (SvTYPE(rv) == SVt_PVHV) {
		in_hv = (HV *)rv;
	} else if (SvTYPE(rv) == SVt_PVAV) {
		in_av = (AV *)rv;
	} else {
		croak("oneway_test: first argument must be a hash or array reference");
	}
	if (in_av) {
		/* MODE 3 – Array of Arrays (AoA) */
		if (formula_str != NULL)
			croak("oneway_test: formula mode is not supported with an array of arrays");

		k = (size_t)av_len(in_av) + 1;
		if (k < 2)
		  croak("oneway_test: need at least 2 groups, got %zu", k);
		sizes  = (size_t *)safemalloc(k * sizeof(size_t));
		gnames = (char  **)safemalloc(k * sizeof(char *));
		/* first pass: sizes, total_n, and generate index names */
		for (size_t g = 0; g < k; g++) {
		  SV **restrict val = av_fetch(in_av, (I32)g, 0);
		  if (!val || !*val || !SvROK(*val) || SvTYPE(SvRV(*val)) != SVt_PVAV)
				croak("oneway_test: index %zu is not an array reference", g);
		  IV len = av_len((AV *)SvRV(*val)) + 1;
		  if (len < 2)
				 croak("oneway_test: index %zu has fewer than 2 observations", g);
		  sizes[g] = (size_t)len;
		  total_n += (IV)len;
		  /* synthesize group names: "Index 0", "Index 1", ... to match 0-based index */
		  char buf[64];
		  snprintf(buf, sizeof(buf), "Index %zu", g);
		  size_t klen = strlen(buf);
		  gnames[g] = (char *)safemalloc(klen + 1);
		  memcpy(gnames[g], buf, klen + 1);
		}
		/* second pass: fill flat array */
		flat = (double *)safemalloc((size_t)total_n * sizeof(double));
		size_t offset = 0;
		for (size_t g = 0; g < k; g++) {
		  SV **restrict val = av_fetch(in_av, (I32)g, 0);
		  AV *restrict av = (AV *)SvRV(*val);
		  IV len = av_len(av) + 1;
		  for (IV i = 0; i < len; i++) {
				SV **restrict svp = av_fetch(av, i, 0);
				flat[offset++] = (svp && *svp) ? SvNV(*svp) : 0.0;
		  }
		}
	} else if (formula_str != NULL) {/* MODE 2 – formula  "response ~ factor" */
		if (!parse_formula(formula_str, &lhs, &rhs))
			croak("oneway_test: cannot parse formula '%s' — "
				   "expected 'response ~ factor'", formula_str);
		factor_name = rhs;   /* use the actual factor variable name */
		SV **restrict resp_svp = hv_fetch(in_hv, lhs, (I32)strlen(lhs), 0);
		if (!resp_svp || !*resp_svp || !SvROK(*resp_svp)
			|| SvTYPE(SvRV(*resp_svp)) != SVt_PVAV)
			croak("oneway_test: formula LHS '%s' not found as an array ref "
				   "in the hash", lhs);
		SV **restrict fact_svp = hv_fetch(in_hv, rhs, (I32)strlen(rhs), 0);
		if (!fact_svp || !*fact_svp || !SvROK(*fact_svp)
			|| SvTYPE(SvRV(*fact_svp)) != SVt_PVAV)
			croak("oneway_test: formula RHS '%s' not found as an array ref "
				   "in the hash", rhs);
		AV *restrict resp_av  = (AV *)SvRV(*resp_svp);
		AV *restrict label_av = (AV *)SvRV(*fact_svp);
		IV  n = av_len(resp_av) + 1;
		flat  = (double *)safemalloc((size_t)n * sizeof(double));
		sizes = (size_t *)safemalloc((size_t)n * sizeof(size_t));
		if (!build_groups_from_formula(aTHX_ resp_av, label_av,
				                        flat, sizes, &k, &gnames,
				                        errbuf, sizeof errbuf)) {
			Safefree(flat); Safefree(sizes); Safefree(lhs); Safefree(rhs);
			croak("oneway_test: %s", errbuf);
		}
		for (size_t g = 0; g < k; g++) total_n += (IV)sizes[g];
	} else {
		/* MODE 1 – hash of groups  { label => \@observations, … } */
		k = (size_t)hv_iterinit(in_hv);
		if (k < 2)
			croak("oneway_test: need at least 2 groups, got %zu", k);
		sizes  = (size_t *)safemalloc(k * sizeof(size_t));
		gnames = (char  **)safemalloc(k * sizeof(char *));
		/* first pass: sizes, total_n, and group name strings */
		{
			size_t g = 0;
			while ((he = hv_iternext(in_hv)) != NULL) {
				SV *restrict val = HeVAL(he);
				if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVAV)
				    croak("oneway_test: value for group '%s' is not an array ref",
				          HePV(he, PL_na));
				IV len = av_len((AV *)SvRV(val)) + 1;
				if (len < 2)
				     croak("oneway_test: group '%s' has fewer than 2 observations",
				           HePV(he, PL_na));
				sizes[g] = (size_t)len;
				total_n += (IV)len;
				/* save a copy of the key string */
				STRLEN klen;
				const char *kstr = HePV(he, klen);
				gnames[g] = (char *)safemalloc(klen + 1);
				memcpy(gnames[g], kstr, klen + 1);
				g++;
			}
		}
		/* second pass: fill flat in the same iteration order */
		flat = (double *)safemalloc((size_t)total_n * sizeof(double));
		{
			size_t offset = 0;
			hv_iterinit(in_hv);
			while ((he = hv_iternext(in_hv)) != NULL) {
				 AV *restrict av  = (AV *)SvRV(HeVAL(he));
				 IV  len = av_len(av) + 1;
				 for (IV i = 0; i < len; i++) {
				     SV **restrict svp = av_fetch(av, i, 0);
				     flat[offset++] = (svp && *svp) ? SvNV(*svp) : 0.0;
				 }
			}
		}
	}
	/* per-group means from flat (before c_oneway_test frees nothing) */
	gmeans = (double *)safemalloc(k * sizeof(double));
	{
		size_t offset = 0;
		for (size_t g = 0; g < k; g++) {
			double sum = 0.0;
			for (size_t i = 0; i < sizes[g]; i++) sum += flat[offset + i];
			gmeans[g] = sum / (double)sizes[g];
			offset   += sizes[g];
		}
	}
	/* run the arithmetic  */
	res = c_oneway_test(flat, sizes, k, var_equal);
	Safefree(flat);
	if (lhs) Safefree(lhs);
	/* rhs kept alive as factor_name until after output */
	/* ── build return hash ref
	* {                                                                 *
	* <factor>  => { Df, "Sum Sq", "Mean Sq", "F value", "Pr(>F)" }  *
	* Residuals => { Df, "Sum Sq", "Mean Sq" }                        *
	* group_stats => { mean => { g => v, … }, size => { g => n, … } } *
	* }*/
	ret_hv = (HV *)sv_2mortal((SV *)newHV());
	/* Group (factor) sub-hash */
	{
		HV *restrict g_hv = newHV();
		hv_stores(g_hv, "Df",      newSVnv(res.num_df));
		hv_stores(g_hv, "Sum Sq",  newSVnv(res.ss_between));
		hv_stores(g_hv, "Mean Sq", newSVnv(res.ms_between));
		hv_stores(g_hv, "F value", newSVnv(res.statistic));
		hv_stores(g_hv, "Pr(>F)",  newSVnv(res.p_value));
		hv_store(ret_hv, factor_name, (I32)strlen(factor_name),
				  newRV_noinc((SV *)g_hv), 0);
	}
	/* Residuals sub-hash */
	{
		HV *restrict r_hv = newHV();
		hv_stores(r_hv, "Df",      newSVnv(res.denom_df));
		hv_stores(r_hv, "Sum Sq",  newSVnv(res.ss_within));
		hv_stores(r_hv, "Mean Sq", newSVnv(res.ms_within));
		hv_stores(ret_hv, "Residuals", newRV_noinc((SV *)r_hv));
	}
	/* group_stats sub-hash */
	{
		HV *restrict gs_hv   = newHV();
		HV *restrict mean_hv = newHV();
		HV *restrict size_hv = newHV();
		for (size_t g = 0; g < k; g++) {
			const char *restrict gn  = gnames[g];
			I32         gnl = (I32)strlen(gn);
			hv_store(mean_hv, gn, gnl, newSVnv(gmeans[g]),       0);
			hv_store(size_hv, gn, gnl, newSViv((IV)sizes[g]),    0);
		}
		hv_stores(gs_hv, "mean", newRV_noinc((SV *)mean_hv));
		hv_stores(gs_hv, "size", newRV_noinc((SV *)size_hv));
		hv_stores(ret_hv, "group_stats", newRV_noinc((SV *)gs_hv));
	}
	/* clean up */
	Safefree(gmeans);	Safefree(sizes);
	for (size_t g = 0; g < k; g++) Safefree(gnames[g]);
	Safefree(gnames);
	if (rhs) Safefree(rhs);
	/* freed here, after factor_name is no longer needed */
	RETVAL = newRV((SV *)ret_hv);
  OUTPUT:
  	RETVAL

SV* ks_test(...)
CODE:
{
	SV *restrict x_sv = NULL, *restrict y_sv = NULL;
	short int exact = -1;
	const char *restrict alternative = "two.sided";
	int arg_idx = 0;

	// Shift arrays if provided positionally
	if (arg_idx < items && SvROK(ST(arg_idx)) && SvTYPE(SvRV(ST(arg_idx))) == SVt_PVAV) {
		x_sv = ST(arg_idx);
		arg_idx++;
	}
	// Check if second argument is an array (2-sample) or a string representing a CDF (1-sample)
	if (arg_idx < items) {
		if (SvROK(ST(arg_idx)) && SvTYPE(SvRV(ST(arg_idx))) == SVt_PVAV) {
			y_sv = ST(arg_idx);
			arg_idx++;
		} else if (SvPOK(ST(arg_idx))) {
			y_sv = ST(arg_idx); // Save string (e.g., "pnorm") for 1-sample test logic
			arg_idx++;
		}
	}
	// Parse named arguments
	for (; arg_idx < items; arg_idx += 2) {
		const char *restrict key = SvPV_nolen(ST(arg_idx));
		SV *restrict val = ST(arg_idx + 1);
		if      (strEQ(key, "x"))           x_sv = val;
		else if (strEQ(key, "y"))           y_sv = val;
		else if (strEQ(key, "exact"))       {
			if (!SvOK(val)) exact = -1;
			else exact = SvTRUE(val) ? 1 : 0;
		}
		else if (strEQ(key, "alternative")) alternative = SvPV_nolen(val);
		else croak("ks_test: unknown argument '%s'", key);
	}

	if (!x_sv || !SvROK(x_sv) || SvTYPE(SvRV(x_sv)) != SVt_PVAV) {
	  croak("ks_test: 'x' is a required argument and must be an ARRAY reference");
	}

	bool is_two_sided = strEQ(alternative, "two.sided") ? 1 : 0;
	bool is_greater   = strEQ(alternative, "greater") ? 1 : 0;
	bool is_less      = strEQ(alternative, "less") ? 1 : 0;

	if (!is_two_sided && !is_greater && !is_less) {
		croak("ks_test: alternative must be 'two.sided', 'less', or 'greater'");
	}

	AV *restrict x_av = (AV*)SvRV(x_sv);
	size_t nx = av_len(x_av) + 1;
	if (nx == 0) croak("Not enough 'x' observations");

	// Extract 'x' array to C-array
	double *restrict x_data = (double *)safemalloc(nx * sizeof(double));
	size_t valid_nx = 0;
	for (size_t i = 0; i < nx; i++) {
	  SV**restrict el = av_fetch(x_av, i, 0);
	  if (el && SvOK(*el) && looks_like_number(*el)) {
		   x_data[valid_nx++] = SvNV(*el);
	  }
	}

	double statistic = 0.0, p_value = 0.0;
	const char *restrict method_desc = "";

	// --- TWO SAMPLE ---
	if (y_sv && SvROK(y_sv) && SvTYPE(SvRV(y_sv)) == SVt_PVAV) {
	  AV *restrict y_av = (AV*)SvRV(y_sv);
	  size_t ny = av_len(y_av) + 1;
	  
	  double *restrict y_data = (double *)safemalloc(ny * sizeof(double));
	  size_t valid_ny = 0;
	  for (size_t i = 0; i < ny; i++) {
		   SV**restrict el = av_fetch(y_av, i, 0);
		   if (el && SvOK(*el) && looks_like_number(*el)) {
		       y_data[valid_ny++] = SvNV(*el);
		   }
	  }

	  if (valid_nx < 1 || valid_ny < 1) {
		   Safefree(x_data); Safefree(y_data);
		   croak("Not enough non-missing observations for KS test");
	  }

	  double d, d_plus, d_minus;
	  calc_2sample_stats(x_data, valid_nx, y_data, valid_ny, &d, &d_plus, &d_minus);

	  // Map alternative to the correct statistic
	  if (is_greater) statistic = d_plus;
	  else if (is_less) statistic = d_minus;
	  else statistic = d;

	  // Determine if exact or asymptotic
	  bool use_exact = FALSE;
	  if (exact == 1) use_exact = TRUE;
	  else if (exact == 0) use_exact = FALSE;
	  else use_exact = (valid_nx * valid_ny < 10000); 

	  // Check for ties in combined set
	  size_t total_n = valid_nx + valid_ny;
	  double *restrict comb = (double *)safemalloc(total_n * sizeof(double));
	  for(size_t i=0; i<valid_nx; i++) comb[i] = x_data[i];
	  for(size_t i=0; i<valid_ny; i++) comb[valid_nx+i] = y_data[i];
	  qsort(comb, total_n, sizeof(double), compare_doubles);

	  bool has_ties = FALSE;
	  for(size_t i = 1; i < total_n; i++) {
		   if(comb[i] == comb[i-1]) { has_ties = TRUE; break; }
	  }
	  Safefree(comb);
	  if (use_exact && has_ties) {
		   warn("cannot compute exact p-value with ties; falling back to asymptotic");
		   use_exact = FALSE;
	  }
	  if (use_exact) {
		   method_desc = "Two-sample Kolmogorov-Smirnov exact test";
		   double q = (0.5 + floor(statistic * valid_nx * valid_ny - 1e-7)) / ((double)valid_nx * valid_ny);
		   p_value = psmirnov_exact_uniq_upper(q, valid_nx, valid_ny, is_two_sided);
	  } else {
		   method_desc = "Two-sample Kolmogorov-Smirnov test (asymptotic)";
		   double z = statistic * sqrt((double)(valid_nx * valid_ny) / (valid_nx + valid_ny));
		   if (is_two_sided) {
		       p_value = K2l(z, 0, 1e-9); 
		   } else {
		       p_value = exp(-2.0 * z * z); // One-sided limit distribution
		   }
	  }
	  Safefree(y_data);
	} else if (y_sv && SvPOK(y_sv)) {// --- ONE SAMPLE (e.g. against pnorm) ---
		const char *restrict dist = SvPV_nolen(y_sv);
		if (strEQ(dist, "pnorm")) {
			qsort(x_data, valid_nx, sizeof(double), compare_doubles);
			double max_d = 0.0, max_d_plus = 0.0, max_d_minus = 0.0;
			for(size_t i = 0; i < valid_nx; i++) {
				double cdf_obs_low  = (double)i / valid_nx;
				double cdf_obs_high = (double)(i + 1) / valid_nx;
				double cdf_theor    = approx_pnorm(x_data[i]);
				double diff1 = cdf_obs_low - cdf_theor;
				double diff2 = cdf_obs_high - cdf_theor;
				if (diff1 > max_d_plus) max_d_plus = diff1;
				if (diff2 > max_d_plus) max_d_plus = diff2;
				if (-diff1 > max_d_minus) max_d_minus = -diff1;
				if (-diff2 > max_d_minus) max_d_minus = -diff2;
				if (fabs(diff1) > max_d) max_d = fabs(diff1);
				if (fabs(diff2) > max_d) max_d = fabs(diff2);
			}
			if (is_greater) statistic = max_d_plus;
			else if (is_less) statistic = max_d_minus;
			else statistic = max_d;
			bool use_exact = (exact == -1) ? (valid_nx < 100) : (exact == 1);
			if (use_exact) {
				method_desc = "One-sample Kolmogorov-Smirnov exact test";
				if (is_two_sided) {
					p_value = 1.0 - K2x(valid_nx, statistic);
				} else {
					warn("exact 1-sample 1-sided KS test not implemented; using asymptotic");
					double z = statistic * sqrt((double)valid_nx);
					p_value = exp(-2.0 * z * z);
				}
			} else {
				 method_desc = "One-sample Kolmogorov-Smirnov test (asymptotic)";
				 double z = statistic * sqrt((double)valid_nx);
				 if (is_two_sided) p_value = K2l(z, 0, 1e-6); 
				 else p_value = exp(-2.0 * z * z);
			}
		} else {
			 Safefree(x_data);
			 croak("ks_test: Unsupported 1-sample distribution '%s'. Use arrays for 2-sample.", dist);
		}
	} else {
	  Safefree(x_data);
	  croak("ks_test: Invalid arguments for 'y'.");
	}
	Safefree(x_data);
	if (p_value > 1.0) p_value = 1.0;
	if (p_value < 0.0) p_value = 0.0;
	HV *restrict res = newHV();
	hv_stores(res, "statistic", newSVnv(statistic));
	hv_stores(res, "p_value", newSVnv(p_value));
	hv_stores(res, "method", newSVpv(method_desc, 0));
	hv_stores(res, "alternative", newSVpv(alternative, 0));
	RETVAL = newRV_noinc((SV*)res);
}
OUTPUT:
	RETVAL

SV* wilcox_test(...)
CODE:
{
	SV *restrict x_sv = NULL, *restrict y_sv = NULL;
	bool paired = FALSE, correct = TRUE;
	double mu = 0.0;
	short int exact = -1;
	const char *restrict alternative = "two.sided";
	int arg_idx = 0;
	// 1. Shift first positional argument as 'x' if it's an array reference
	if (arg_idx < items && SvROK(ST(arg_idx)) && SvTYPE(SvRV(ST(arg_idx))) == SVt_PVAV) {
		x_sv = ST(arg_idx);
		arg_idx++;
	}
	// 2. Shift second positional argument as 'y' if it's an array reference
	if (arg_idx < items && SvROK(ST(arg_idx)) && SvTYPE(SvRV(ST(arg_idx))) == SVt_PVAV) {
		y_sv = ST(arg_idx);
		arg_idx++;
	}
	// Ensure the remaining arguments form complete key-value pairs
	if ((items - arg_idx) % 2 != 0) {
		croak("Usage: wilcox_test(\\@x, [\\@y], key => value, ...)");
	}
	// --- Parse named arguments from the remaining flat stack ---
	for (; arg_idx < items; arg_idx += 2) {
		const char *restrict key = SvPV_nolen(ST(arg_idx));
		SV *restrict val = ST(arg_idx + 1);
		if      (strEQ(key, "x"))          x_sv = val;
		else if (strEQ(key, "y"))          y_sv = val;
		else if (strEQ(key, "paired"))     paired = SvTRUE(val);
		else if (strEQ(key, "correct"))    correct = SvTRUE(val);
		else if (strEQ(key, "mu"))          mu = SvNV(val);
		else if (strEQ(key, "exact"))       {
			if (!SvOK(val)) exact = -1;
			else exact = SvTRUE(val) ? 1 : 0;
		}
		else if (strEQ(key, "alternative")) alternative = SvPV_nolen(val);
		else croak("wilcox_test: unknown argument '%s'", key);
	}
	// --- Validate required / types ---
	if (!x_sv || !SvROK(x_sv) || SvTYPE(SvRV(x_sv)) != SVt_PVAV)
		croak("wilcox_test: 'x' is a required argument and must be an ARRAY reference");
	AV *restrict x_av = (AV*)SvRV(x_sv);
	size_t nx = av_len(x_av) + 1;
	if (nx == 0) croak("Not enough 'x' observations");

	AV *restrict y_av = NULL;
	size_t ny = 0;
	if (y_sv && SvROK(y_sv) && SvTYPE(SvRV(y_sv)) == SVt_PVAV) {
		y_av = (AV*)SvRV(y_sv);
		ny = av_len(y_av) + 1;
	}
	double p_value = 0.0, statistic = 0.0;
	const char *restrict method_desc = "";
	bool use_exact = FALSE;
	// --- TWO SAMPLE (Mann-Whitney) ---
	if (ny > 0 && !paired) {
		RankInfo *restrict ri = (RankInfo *)safemalloc((nx + ny) * sizeof(RankInfo));
		size_t valid_nx = 0, valid_ny = 0;
		for (size_t i = 0; i < nx; i++) {
			SV**restrict el = av_fetch(x_av, i, 0);
			if (el && SvOK(*el) && looks_like_number(*el)) {
				ri[valid_nx].val = SvNV(*el) - mu; // R subtracts mu from x
				ri[valid_nx].idx = 1;
				valid_nx++;
			}
		}
		for (size_t i = 0; i < ny; i++) {
			SV**restrict el = av_fetch(y_av, i, 0);
			if (el && SvOK(*el) && looks_like_number(*el)) {
				ri[valid_nx + valid_ny].val = SvNV(*el);
				ri[valid_nx + valid_ny].idx = 2;
				valid_ny++;
			}
		}
		if (valid_nx == 0) { Safefree(ri); croak("not enough (non-missing) 'x' observations"); }
		if (valid_ny == 0) { Safefree(ri); croak("not enough 'y' observations"); }
		size_t total_n = valid_nx + valid_ny;
		bool has_ties = 0;
		double tie_adj = rank_and_count_ties(ri, total_n, &has_ties);
		double w_rank_sum = 0.0;
		for (size_t i = 0; i < total_n; i++) if (ri[i].idx == 1) w_rank_sum += ri[i].rank;
		statistic = w_rank_sum - (double)valid_nx * (valid_nx + 1.0) / 2.0;
		
		if (exact == 1) use_exact = TRUE;
		else if (exact == 0) use_exact = FALSE;
		else use_exact = (valid_nx < 50 && valid_ny < 50 && !has_ties);
		
		if (use_exact && has_ties) {
			warn("cannot compute exact p-value with ties; falling back to approximation");
			use_exact = FALSE;
		}
		if (use_exact) {
			method_desc = "Wilcoxon rank sum exact test";
			double p_less = exact_pwilcox(statistic, valid_nx, valid_ny);
			double p_greater = 1.0 - exact_pwilcox(statistic - 1.0, valid_nx, valid_ny);

			if (strcmp(alternative, "less") == 0) p_value = p_less;
			else if (strcmp(alternative, "greater") == 0) p_value = p_greater;
			else {
				double p = (p_less < p_greater) ? p_less : p_greater;
				p_value = 2.0 * p;
			}
		} else {
			method_desc = correct ? "Wilcoxon rank sum test with continuity correction" : "Wilcoxon rank sum test";
			double exp = (double)valid_nx * valid_ny / 2.0;
			double var = ((double)valid_nx * valid_ny / 12.0) * ((total_n + 1.0) - tie_adj / (total_n * (total_n - 1.0)));
			double z = statistic - exp;
			
			double CORRECTION = 0.0;
			if (correct) {
				if (strcmp(alternative, "two.sided") == 0) CORRECTION = (z > 0 ? 0.5 : -0.5);
				else if (strcmp(alternative, "greater") == 0) CORRECTION = 0.5;
				else if (strcmp(alternative, "less") == 0) CORRECTION = -0.5;
			}
			z = (z - CORRECTION) / sqrt(var);

			if (strcmp(alternative, "less") == 0) p_value = approx_pnorm(z);
			else if (strcmp(alternative, "greater") == 0) p_value = 1.0 - approx_pnorm(z);
			else p_value = 2.0 * approx_pnorm(-fabs(z));
		}
		Safefree(ri);
	} else { // --- ONE SAMPLE / PAIRED ---
		if (paired && (!y_av || nx != ny)) croak("'x' and 'y' must have the same length for paired test");
		double *restrict diffs = (double *)safemalloc(nx * sizeof(double));
		size_t n_nz = 0;
		bool has_zeroes = FALSE;
		for (size_t i = 0; i < nx; i++) {
			SV**restrict x_el = av_fetch(x_av, i, 0);
			if (!x_el || !SvOK(*x_el) || !looks_like_number(*x_el)) continue;
			double dx = SvNV(*x_el);

			if (paired) {
				SV**restrict y_el = av_fetch(y_av, i, 0);
				if (!y_el || !SvOK(*y_el) || !looks_like_number(*y_el)) continue;
				double dy = SvNV(*y_el);
				double d = dx - dy - mu;
				if (d == 0.0) has_zeroes = TRUE; // Drop exact zeroes
				else diffs[n_nz++] = d;
			} else {
				double d = dx - mu;
				if (d == 0.0) has_zeroes = TRUE;
				else diffs[n_nz++] = d;
			}
		}
		if (n_nz == 0) {
			Safefree(diffs);
			croak("not enough (non-missing) observations");
		}
		RankInfo *ri = (RankInfo *)safemalloc(n_nz * sizeof(RankInfo));
		for (size_t i = 0; i < n_nz; i++) { 
			ri[i].val = fabs(diffs[i]); 
			ri[i].idx = (diffs[i] > 0);
		}
		bool has_ties = 0;
		double tie_adj = rank_and_count_ties(ri, n_nz, &has_ties);
		statistic = 0.0;
		for (size_t i = 0; i < n_nz; i++) {
			if (ri[i].idx) statistic += ri[i].rank;
		}
		if (exact == 1) use_exact = TRUE;
		else if (exact == 0) use_exact = FALSE;
		else use_exact = (n_nz < 50 && !has_ties);
		if (use_exact && has_ties) {
			warn("cannot compute exact p-value with ties; falling back to approximation");
			use_exact = FALSE;
		}
		if (use_exact && has_zeroes) {
			warn("cannot compute exact p-value with zeroes; falling back to approximation");
			use_exact = FALSE;
		}
		if (use_exact) {
			method_desc = paired ? "Wilcoxon exact signed rank test" : "Wilcoxon exact signed rank test";
			double p_less = exact_psignrank(statistic, n_nz);
			double p_greater = 1.0 - exact_psignrank(statistic - 1.0, n_nz);

			if (strcmp(alternative, "less") == 0) p_value = p_less;
			else if (strcmp(alternative, "greater") == 0) p_value = p_greater;
			else {
				double p = (p_less < p_greater) ? p_less : p_greater;
				p_value = 2.0 * p;
			}
		} else {
			method_desc = correct ? "Wilcoxon signed rank test with continuity correction" : "Wilcoxon signed rank test";
			double exp = (double)n_nz * (n_nz + 1.0) / 4.0;
			double var = (n_nz * (n_nz + 1.0) * (2.0 * n_nz + 1.0) / 24.0) - (tie_adj / 48.0);
			double z = statistic - exp;
			double CORRECTION = 0.0;
			if (correct) {
				if (strcmp(alternative, "two.sided") == 0) CORRECTION = (z > 0 ? 0.5 : -0.5);
				else if (strcmp(alternative, "greater") == 0) CORRECTION = 0.5;
				else if (strcmp(alternative, "less") == 0) CORRECTION = -0.5;
			}
			z = (z - CORRECTION) / sqrt(var);

			if (strcmp(alternative, "less") == 0) p_value = approx_pnorm(z);
			else if (strcmp(alternative, "greater") == 0) p_value = 1.0 - approx_pnorm(z);
			else p_value = 2.0 * approx_pnorm(-fabs(z));
		}
		Safefree(ri); Safefree(diffs);
	}
	if (p_value > 1.0) p_value = 1.0;
	HV *restrict res = newHV();
	hv_stores(res, "statistic", newSVnv(statistic));
	hv_stores(res, "p_value", newSVnv(p_value));
	hv_stores(res, "method", newSVpv(method_desc, 0));
	hv_stores(res, "alternative", newSVpv(alternative, 0));
	RETVAL = newRV_noinc((SV*)res);
}
OUTPUT:
	RETVAL

SV* chisq_test(data_ref)
    SV* data_ref;
CODE:
{
	// 1. Input Validation (mimics: die 'Input must be an array reference')
	if (!SvROK(data_ref) || SvTYPE(SvRV(data_ref)) != SVt_PVAV) {
	croak("Input must be an array reference");
	}
	AV*restrict obs_av = (AV*)SvRV(data_ref);
	int r = av_top_index(obs_av) + 1, c = 0;
	bool is_2d = 0;
	SV**restrict first_elem = av_fetch(obs_av, 0, 0);
	if (first_elem && SvROK(*first_elem) && SvTYPE(SvRV(*first_elem)) == SVt_PVAV) {
		is_2d = 1;
		AV*restrict first_row = (AV*)SvRV(*first_elem);
		c = av_top_index(first_row) + 1;
	} else {
		c = r;
		r = 1;
	}
	double stat = 0.0, grand_total = 0.0;
	unsigned int df = 0;
	bool yates = (is_2d && r == 2 && c == 2) ? 1 : 0;
	AV*restrict expected_av = newAV();
	if (is_2d) {
		double *restrict row_sum = (double*)safemalloc(r * sizeof(double));
		double *restrict col_sum = (double*)safemalloc(c * sizeof(double));
		for(unsigned int i=0; i<r; i++) row_sum[i] = 0.0;
		for(unsigned int j=0; j<c; j++) col_sum[j] = 0.0;
		for (unsigned int i = 0; i < r; i++) {
			SV**restrict row_sv = av_fetch(obs_av, i, 0);
			AV*restrict row = (AV*)SvRV(*row_sv);
			for (unsigned int j = 0; j < c; j++) {
				  SV**restrict val_sv = av_fetch(row, j, 0);
				  double val = SvNV(*val_sv);
				  row_sum[i] += val;
				  col_sum[j] += val;
				  grand_total += val;
			}
		}
		for (unsigned int i = 0; i < r; i++) {
			AV*restrict exp_row = newAV();
			SV**restrict row_sv = av_fetch(obs_av, i, 0);
			AV*restrict row = (AV*)SvRV(*row_sv);
			for (unsigned int j = 0; j < c; j++) {
				double E = (row_sum[i] * col_sum[j]) / grand_total;
				SV**restrict val_sv = av_fetch(row, j, 0);
				double O = SvNV(*val_sv);
				av_push(exp_row, newSVnv(E));
				if (yates) {
				// Exact R logic: min(0.5, abs(O - E))
				double abs_diff = fabs(O - E);
				double y_corr = (abs_diff > 0.5) ? 0.5 : abs_diff;
				double diff = abs_diff - y_corr;
				stat += (diff * diff) / E;
				} else {
				stat += ((O - E) * (O - E)) / E;
				}
			}
			av_push(expected_av, newRV_noinc((SV*)exp_row));
		}
		safefree(row_sum); safefree(col_sum);
		df = (r - 1) * (c - 1);
	} else {
	for (unsigned int j = 0; j < c; j++) {
		SV**restrict val_sv = av_fetch(obs_av, j, 0);
		grand_total += SvNV(*val_sv);
	}
	double E = grand_total / (double)c;
	for (unsigned int j = 0; j < c; j++) {
		SV**restrict val_sv = av_fetch(obs_av, j, 0);
		double O = SvNV(*val_sv);
		av_push(expected_av, newSVnv(E));
		stat += ((O - E) * (O - E)) / E;
	}
	df = c - 1;
	}
	double p_val = get_p_value(stat, df);
	// 2. Build the top-level results Hash (mimicking R's htest structure)
	HV*restrict results = newHV();
	// 'statistic' => { 'X-squared' => stat }
	HV*restrict statistic_hv = newHV();
	hv_store(statistic_hv, "X-squared", 9, newSVnv(stat), 0);
	hv_store(results, "statistic", 9, newRV_noinc((SV*)statistic_hv), 0);
	// 'parameter' => { 'df' => df }
	HV*restrict parameter_hv = newHV();
	hv_store(parameter_hv, "df", 2, newSViv(df), 0);
	hv_store(results, "parameter", 9, newRV_noinc((SV*)parameter_hv), 0);
	// 'p.value' => p_val
	hv_store(results, "p.value", 7, newSVnv(p_val), 0);
	// 'expected' => expected_av
	hv_store(results, "expected", 8, newRV_noinc((SV*)expected_av), 0);
	// 'observed' => data_ref (Increment ref count since hv_store consumes ownership)
	hv_store(results, "observed", 8, SvREFCNT_inc(data_ref), 0);
	// 'data.name' => 'Perl ArrayRef'
	hv_store(results, "data.name", 9, newSVpv("Perl ArrayRef", 0), 0);
	// 'method' => String
	if (is_2d) {
	  if (yates) {
		   hv_store(results, "method", 6, newSVpv("Pearson's Chi-squared test with Yates' continuity correction", 0), 0);
	  } else {
		   hv_store(results, "method", 6, newSVpv("Pearson's Chi-squared test", 0), 0);
	  }
	} else {
		hv_store(results, "method", 6, newSVpv("Chi-squared test for given probabilities", 0), 0);
	}

	RETVAL = newRV_noinc((SV*)results);
}
OUTPUT:
    RETVAL

PROTOTYPES: ENABLE

void write_table(...)
PPCODE:
{
	SV *restrict data_sv = NULL;
	SV *restrict file_sv = NULL;
	unsigned int arg_idx = 0;

	// Mimic the Perl shift logic
	if (arg_idx < items && SvROK(ST(arg_idx))) {
		int type = SvTYPE(SvRV(ST(arg_idx)));
		if (type == SVt_PVHV || type == SVt_PVAV) {
			data_sv = ST(arg_idx);
			arg_idx++;
		}
	}
	if (arg_idx < items) {
	  file_sv = ST(arg_idx);
	  arg_idx++;
	}

	const char *restrict sep = ",";
	bool explicit_sep = 0; // Track if delimiter was manually specified
	const char *restrict undef_val = "NA";
	SV *restrict row_names_sv = sv_2mortal(newSViv(1));
	SV *restrict col_names_sv = NULL;

	// Read the remaining Hash-style arguments
	for (; arg_idx < items; arg_idx += 2) {
		if (arg_idx + 1 >= items) croak("write_table: Odd number of arguments passed");
		const char *restrict key = SvPV_nolen(ST(arg_idx));
		SV *restrict val = ST(arg_idx + 1);
		if (strEQ(key, "data")) data_sv = val;
		else if (strEQ(key, "col.names")) col_names_sv = val;
		else if (strEQ(key, "file")) file_sv = val;
		else if (strEQ(key, "row.names")) row_names_sv = val;
		// NEW: Check for either "sep" or "delim" and mark as explicitly provided
		else if (strEQ(key, "sep") || strEQ(key, "delim")) {
			sep = SvPV_nolen(val);
			explicit_sep = 1;
		}
		else if (strEQ(key, "undef.val")) undef_val = SvPV_nolen(val);
		else croak("write_table: Unknown arguments passed: %s", key);
	}
	if (!data_sv || !SvROK(data_sv)) {
	  croak("write_table: 'data' must be a HASH or ARRAY reference\n");
	}
	SV *restrict data_ref = SvRV(data_sv);
	if (SvTYPE(data_ref) != SVt_PVHV && SvTYPE(data_ref) != SVt_PVAV) {
	  croak("write_table: 'data' must be a HASH or ARRAY reference\n");
	}
	if (!file_sv || !SvOK(file_sv)) croak("write_table: file name missing\n");
	const char *restrict file = SvPV_nolen(file_sv);
	// NEW: Auto-detect separator from file extension if not overridden
	if (!explicit_sep) {
	  size_t file_len = strlen(file);
	  if (file_len >= 4) {
		   const char *restrict ext = file + file_len - 4;
		   if (strEQ(ext, ".tsv") || strEQ(ext, ".TSV")) {
		       sep = "\t";
		   } else if (strEQ(ext, ".csv") || strEQ(ext, ".CSV")) {
		       sep = ",";
		   }
	  }
	}

	if (col_names_sv && SvOK(col_names_sv)) {
		if (!SvROK(col_names_sv) || SvTYPE(SvRV(col_names_sv)) != SVt_PVAV) {
			croak("write_table: 'col.names' must be an ARRAY reference\n");
		}
	}
	bool is_hoh = 0, is_hoa = 0, is_aoh = 0;
	AV *restrict rows_av = NULL;
	// Validate Input Structures & Homogeneity 
	if (SvTYPE(data_ref) == SVt_PVHV) {
		HV *restrict hv = (HV*)data_ref;
		if (hv_iterinit(hv) == 0) XSRETURN_EMPTY;

		HE *restrict entry = hv_iternext(hv);
		SV *restrict first_val = hv_iterval(hv, entry);
		if (!first_val || !SvROK(first_val)) {
			croak("write_table: Data values must be either all HASHes or all ARRAYs\n");
		}
		int first_type = SvTYPE(SvRV(first_val));
		if (first_type != SVt_PVHV && first_type != SVt_PVAV) {
			croak("write_table: Data values must be either all HASHes or all ARRAYs\n");
		}
		is_hoh = (first_type == SVt_PVHV);
		is_hoa = (first_type == SVt_PVAV);
		hv_iterinit(hv);
		while ((entry = hv_iternext(hv))) {
			SV *restrict val = hv_iterval(hv, entry);
			if (!val || !SvROK(val) || SvTYPE(SvRV(val)) != first_type) {
				 croak("write_table: Mixed data types detected. Ensure all values are %s references.\n", is_hoh ? "HASH" : "ARRAY");
			}
		}
		if (is_hoh) {
			rows_av = newAV();
			hv_iterinit(hv);
			while ((entry = hv_iternext(hv))) {
				 av_push(rows_av, newSVsv(hv_iterkeysv(entry)));
			}
		}
	} else {
		AV *restrict av = (AV*)data_ref;
		if (av_len(av) < 0) XSRETURN_EMPTY;
		SV **restrict first_ptr = av_fetch(av, 0, 0);
		if (!first_ptr || !*first_ptr || !SvROK(*first_ptr) || SvTYPE(SvRV(*first_ptr)) != SVt_PVHV) {
			croak("write_table: For ARRAY data, all elements must be HASH references (Array of Hashes)\n");
		}

		for (size_t i = 0; i <= av_len(av); i++) {
			SV **restrict ptr = av_fetch(av, i, 0);
			if (!ptr || !*ptr || !SvROK(*ptr) || SvTYPE(SvRV(*ptr)) != SVt_PVHV) {
				 croak("write_table: Mixed data types detected in Array of Hashes. All elements must be HASH references.\n");
			}
		}
		is_aoh = 1;
	}
	PerlIO *restrict fh = PerlIO_open(file, "w");
	if (!fh) croak("write_table: Could not open '%s' for writing", file);
	AV *restrict headers_av = newAV();
	bool inc_rownames = (row_names_sv && SvTRUE(row_names_sv)) ? 1 : 0;
	const char *restrict rownames_col = NULL;
	// ----- Hash of Hashes -----
	if (is_hoh) {
	  if (col_names_sv && SvOK(col_names_sv)) {
		   AV *restrict c_av = (AV*)SvRV(col_names_sv);
		   for(size_t i=0; i<=av_len(c_av); i++) {
		       SV **restrict c = av_fetch(c_av, i, 0);
		       if(c && SvOK(*c)) av_push(headers_av, newSVsv(*c));
		   }
	  } else {
		   HV *restrict col_map = newHV();
		   hv_iterinit((HV*)data_ref);
		   HE *restrict entry;
		   while((entry = hv_iternext((HV*)data_ref))) {
		       HV *restrict inner = (HV*)SvRV(hv_iterval((HV*)data_ref, entry));
		       hv_iterinit(inner);
		       HE *restrict inner_entry;
		       while((inner_entry = hv_iternext(inner))) {
		           hv_store_ent(col_map, hv_iterkeysv(inner_entry), newSViv(1), 0);
		       }
		   }
		   unsigned num_cols = hv_iterinit(col_map);
		   const char **restrict col_array = safemalloc(num_cols * sizeof(char*));
		   for(unsigned i=0; i<num_cols; i++) {
		       HE *restrict ce = hv_iternext(col_map);
		       col_array[i] = SvPV_nolen(hv_iterkeysv(ce));
		   }
		   qsort(col_array, num_cols, sizeof(char*), cmp_string_wt);
		   for(unsigned i=0; i<num_cols; i++) av_push(headers_av, newSVpv(col_array[i], 0));
		   safefree(col_array);
		   SvREFCNT_dec(col_map);
	}
	size_t num_headers = av_len(headers_av) + 1;
	const char **restrict header_row = safemalloc((num_headers + 1) * sizeof(char*));

	size_t h_idx = 0;
	if (inc_rownames) header_row[h_idx++] = "";
	for(unsigned short int i=0; i<num_headers; i++) {
	  SV**restrict h_ptr = av_fetch(headers_av, i, 0);
	  header_row[h_idx++] = (h_ptr && SvOK(*h_ptr)) ? SvPV_nolen(*h_ptr) : "";
	}
	print_string_row(aTHX_ fh, header_row, h_idx, sep);
	safefree(header_row);

	size_t num_rows = av_len(rows_av) + 1;
	const char **restrict row_array = safemalloc(num_rows * sizeof(char*));
	for(size_t i=0; i<num_rows; i++) {
	  row_array[i] = SvPV_nolen(*av_fetch(rows_av, i, 0));
	}
	qsort(row_array, num_rows, sizeof(char*), cmp_string_wt);

	HV *restrict data_hv = (HV*)data_ref;
	const char **restrict row_data = safemalloc((num_headers + 1) * sizeof(char*));

	for(size_t i=0; i<num_rows; i++) {
	  size_t d_idx = 0;
	  if (inc_rownames) row_data[d_idx++] = row_array[i];

	  SV **restrict inner_hv_ptr = hv_fetch(data_hv, row_array[i], strlen(row_array[i]), 0);
	  HV *restrict inner_hv = inner_hv_ptr ? (HV*)SvRV(*inner_hv_ptr) : NULL;

	  for(size_t j=0; j<num_headers; j++) {
		   SV**restrict h_ptr = av_fetch(headers_av, j, 0);
		   const char *restrict col_name = (h_ptr && SvOK(*h_ptr)) ? SvPV_nolen(*h_ptr) : "";
		   SV **restrict cell_ptr = inner_hv ? hv_fetch(inner_hv, col_name, strlen(col_name), 0) : NULL;
		   if (cell_ptr && SvOK(*cell_ptr)) {
		   if (SvROK(*cell_ptr)) {
		     PerlIO_close(fh);
		     safefree(row_array); safefree(row_data);
		     if (headers_av) SvREFCNT_dec(headers_av);
		     if (rows_av) SvREFCNT_dec(rows_av);
		     croak("write_table: Cannot write nested reference types to table\n");
		   }
		       row_data[d_idx++] = SvPV_nolen(*cell_ptr);
		   } else {
		       row_data[d_idx++] = undef_val;
		   }
	  }
	  print_string_row(aTHX_ fh, row_data, d_idx, sep);
	}
	safefree(row_array); safefree(row_data);

	} else if (is_hoa) { // ----- Hash of Arrays -----
	  HV *restrict data_hv = (HV*)data_ref;
	  size_t max_rows = 0;
	  hv_iterinit(data_hv);
	  HE *restrict entry;
	  while((entry = hv_iternext(data_hv))) {
		   AV *restrict arr = (AV*)SvRV(hv_iterval(data_hv, entry));
		   size_t len = av_len(arr) + 1;
		   if (len > max_rows) max_rows = len;
	  }

	  if (col_names_sv && SvOK(col_names_sv)) {
		   AV *restrict c_av = (AV*)SvRV(col_names_sv);
		   for(size_t i=0; i<=av_len(c_av); i++) {
		       SV **restrict c = av_fetch(c_av, i, 0);
		       if(c && SvOK(*c)) av_push(headers_av, newSVsv(*c));
		   }
	  } else {
		   unsigned int num_cols = hv_iterinit(data_hv);
		   const char **restrict col_array = safemalloc(num_cols * sizeof(char*));
		   for(unsigned int i=0; i<num_cols; i++) {
		       HE *restrict ce = hv_iternext(data_hv);
		       col_array[i] = SvPV_nolen(hv_iterkeysv(ce));
		   }
		   qsort(col_array, num_cols, sizeof(char*), cmp_string_wt);
		   for(unsigned i=0; i<num_cols; i++) av_push(headers_av, newSVpv(col_array[i], 0));
		   safefree(col_array);
	  }
	  if (av_len(headers_av) < 0) croak("Could not get headers in write_table");
	  if (inc_rownames && contains_nondigit(aTHX_ row_names_sv)) {
		   rownames_col = SvPV_nolen(row_names_sv);
		   AV *restrict filtered_headers = (AV*)sv_2mortal((SV*)newAV());

		   for(size_t i=0; i<=av_len(headers_av); i++) {
		       SV**restrict h_ptr = av_fetch(headers_av, i, 0);
		       if (!h_ptr || !*h_ptr) continue;
		       SV *restrict h_sv = *h_ptr;
		       if (strcmp(SvPV_nolen(h_sv), rownames_col) != 0) {
		           av_push(filtered_headers, newSVsv(h_sv));
		       }
		   }
		   SvREFCNT_dec(headers_av);
		   headers_av = filtered_headers;
	  }
	  size_t num_headers = av_len(headers_av) + 1;
	  const char **restrict header_row = safemalloc((num_headers + 1) * sizeof(char*));
	  size_t h_idx = 0;
	  if (inc_rownames) header_row[h_idx++] = "";
	  for(size_t i=0; i<num_headers; i++) {
		   SV**restrict h_ptr = av_fetch(headers_av, i, 0);
		   header_row[h_idx++] = (h_ptr && SvOK(*h_ptr)) ? SvPV_nolen(*h_ptr) : "";
	  }
	  print_string_row(aTHX_ fh, header_row, h_idx, sep);
	  safefree(header_row);
	  const char **restrict row_data = safemalloc((num_headers + 1) * sizeof(char*));
	  for(size_t i=0; i<max_rows; i++) {
		   size_t d_idx = 0;
		   if (inc_rownames) {
		       if (rownames_col) {
		           SV **restrict rn_arr_ptr = hv_fetch(data_hv, rownames_col, strlen(rownames_col), 0);
		           if (rn_arr_ptr && SvROK(*rn_arr_ptr)) {
		               AV *restrict rn_arr = (AV*)SvRV(*rn_arr_ptr);
		               SV **restrict rn_val_ptr = av_fetch(rn_arr, i, 0);
		               if (rn_val_ptr && SvOK(*rn_val_ptr)) {
		                   if (SvROK(*rn_val_ptr)) {
		                          PerlIO_close(fh);
		                          safefree(row_data);
		                          if (headers_av) SvREFCNT_dec(headers_av);
		                          croak("write_table: Cannot write nested reference types to table\n");
		                    }
		                    row_data[d_idx++] = SvPV_nolen(*rn_val_ptr);
		                } else {
		                   row_data[d_idx++] = undef_val;
		                }
		           } else {
		                row_data[d_idx++] = undef_val;
		           }
		       } else {
		           char buf[32];
		           snprintf(buf, sizeof(buf), "%ld", (long)(i + 1));
		           row_data[d_idx++] = savepv(buf);
		       }
		   }
		   for(size_t j=0; j<num_headers; j++) {
		       SV**restrict h_ptr = av_fetch(headers_av, j, 0);
		       const char *restrict col_name = (h_ptr && SvOK(*h_ptr)) ? SvPV_nolen(*h_ptr) : "";
		       SV **restrict arr_ptr = hv_fetch(data_hv, col_name, strlen(col_name), 0);
		       if (arr_ptr && SvROK(*arr_ptr)) {
		           AV *restrict arr = (AV*)SvRV(*arr_ptr);
		           SV **restrict cell_ptr = av_fetch(arr, i, 0);
		           if (cell_ptr && SvOK(*cell_ptr)) {
		                if (SvROK(*cell_ptr)) {
		                     PerlIO_close(fh);
		                     safefree(row_data);
		                     if (headers_av) SvREFCNT_dec(headers_av);
		                     croak("write_table: Cannot write nested reference types to table\n");
		                }
		                row_data[d_idx++] = SvPV_nolen(*cell_ptr);
		           } else {
		                row_data[d_idx++] = undef_val;
		           }
		       } else {
		           row_data[d_idx++] = undef_val;
		       }
		   }
		   print_string_row(aTHX_ fh, row_data, d_idx, sep);
		   if (inc_rownames && !rownames_col) safefree((char*)row_data[0]);
	  }
	  safefree(row_data);
	} else if (is_aoh) {// ----- Array of Hashes -----
	AV *restrict data_av = (AV*)data_ref;
	size_t num_rows = av_len(data_av) + 1;
	if (col_names_sv && SvOK(col_names_sv)) {
		AV *restrict c_av = (AV*)SvRV(col_names_sv);
		for(size_t i=0; i<=av_len(c_av); i++) {
			 SV **restrict c = av_fetch(c_av, i, 0);
			 if(c && SvOK(*c)) av_push(headers_av, newSVsv(*c));
		}
	} else {
		HV *restrict col_map = newHV();
		for(size_t i=0; i<num_rows; i++) {
			SV **restrict row_ptr = av_fetch(data_av, i, 0);
			if (row_ptr && SvROK(*row_ptr)) {
				HV *restrict row_hv = (HV*)SvRV(*row_ptr);
				hv_iterinit(row_hv);
				HE *restrict entry;
				while((entry = hv_iternext(row_hv))) {
					hv_store_ent(col_map, hv_iterkeysv(entry), newSViv(1), 0);
				}
			}
		}
		unsigned num_cols = hv_iterinit(col_map);
		const char **restrict col_array = safemalloc(num_cols * sizeof(char*));
		for(unsigned int i=0; i<num_cols; i++) {
			 HE *restrict ce = hv_iternext(col_map);
			 col_array[i] = SvPV_nolen(hv_iterkeysv(ce));
		}
		qsort(col_array, num_cols, sizeof(char*), cmp_string_wt);
		for(unsigned int i=0; i<num_cols; i++) av_push(headers_av, newSVpv(col_array[i], 0));
		safefree(col_array);
		SvREFCNT_dec(col_map);
	}
	if (inc_rownames && contains_nondigit(aTHX_ row_names_sv)) {
		rownames_col = SvPV_nolen(row_names_sv);
		AV *restrict filtered_headers = newAV();
		for(size_t i=0; i<=av_len(headers_av); i++) {
			 SV**restrict h_ptr = av_fetch(headers_av, i, 0);
			 if (!h_ptr || !*h_ptr) continue;
			 SV *restrict h_sv = *h_ptr;
			 if (strcmp(SvPV_nolen(h_sv), rownames_col) != 0) {
				  av_push(filtered_headers, newSVsv(h_sv));
			 }
		}
		SvREFCNT_dec(headers_av);
		headers_av = filtered_headers;
	}
	size_t num_headers = av_len(headers_av) + 1;
	const char **restrict header_row = safemalloc((num_headers + 1) * sizeof(char*));
	size_t h_idx = 0;
	if (inc_rownames) header_row[h_idx++] = "";
	for(size_t i=0; i<num_headers; i++) {
		SV**restrict h_ptr = av_fetch(headers_av, i, 0);
		header_row[h_idx++] = (h_ptr && SvOK(*h_ptr)) ? SvPV_nolen(*h_ptr) : "";
	}
	print_string_row(aTHX_ fh, header_row, h_idx, sep);
	safefree(header_row);
	const char **restrict row_data = safemalloc((num_headers + 1) * sizeof(char*));
	for(size_t i=0; i<num_rows; i++) {
		size_t d_idx = 0;
		SV **restrict row_ptr = av_fetch(data_av, i, 0);
		HV *restrict row_hv = (row_ptr && SvROK(*row_ptr)) ? (HV*)SvRV(*row_ptr) : NULL;
		if (inc_rownames) {
			if (rownames_col) {
				SV **restrict rn_val_ptr = row_hv ? hv_fetch(row_hv, rownames_col, strlen(rownames_col), 0) : NULL;
				if (rn_val_ptr && SvOK(*rn_val_ptr)) {
					  if (SvROK(*rn_val_ptr)) {
							 PerlIO_close(fh);
								   safefree(row_data);
								   if (headers_av) SvREFCNT_dec(headers_av);
							 croak("write_table: Cannot write nested reference types to table\n");
					  }
					  row_data[d_idx++] = SvPV_nolen(*rn_val_ptr);
				} else {
					  row_data[d_idx++] = undef_val;
				}
			} else {
			  char buf[32];
			  snprintf(buf, sizeof(buf), "%ld", (long)(i + 1));
			  row_data[d_idx++] = savepv(buf);
			}
		}

		for(size_t j=0; j<num_headers; j++) {
			 SV**restrict h_ptr = av_fetch(headers_av, j, 0);
			 const char *restrict col_name = (h_ptr && SvOK(*h_ptr)) ? SvPV_nolen(*h_ptr) : "";
			 SV **restrict cell_ptr = row_hv ? hv_fetch(row_hv, col_name, strlen(col_name), 0) : NULL;
			 if (cell_ptr && SvOK(*cell_ptr)) {
				  if (SvROK(*cell_ptr)) {
				      PerlIO_close(fh);
				      safefree(row_data);
				      if (headers_av) SvREFCNT_dec(headers_av);
				      croak("write_table: Cannot write nested reference types to table\n");
				  }
				  row_data[d_idx++] = SvPV_nolen(*cell_ptr);
			 } else {
				  row_data[d_idx++] = undef_val;
			 }
		}
		print_string_row(aTHX_ fh, row_data, d_idx, sep);
		if (inc_rownames && !rownames_col) safefree((char*)row_data[0]);
	}
	safefree(row_data);
	}
	if (headers_av) SvREFCNT_dec(headers_av);
	if (rows_av) SvREFCNT_dec(rows_av);
	PerlIO_close(fh);
	XSRETURN_EMPTY;
}

SV* _parse_csv_file(char* file, const char* sep_str, const char* comment_str, SV* callback = &PL_sv_undef)
INIT:
	PerlIO *restrict fp;
	AV *restrict data = NULL;
	AV *restrict current_row = newAV();
	SV *restrict field = newSVpvs("");
	bool in_quotes = 0, post_quote = 0;
	size_t sep_len, comment_len;
	SV *restrict line_sv;
	bool use_cb = 0;
CODE:
	if (SvOK(callback) && SvROK(callback) && SvTYPE(SvRV(callback)) == SVt_PVCV) {
		use_cb = 1;
	} else {
		data = newAV();
	}
	sep_len = sep_str ? strlen(sep_str) : 0;
	comment_len = comment_str ? strlen(comment_str) : 0;

	fp = PerlIO_open(file, "r");
	if (!fp) {
		croak("Could not open file '%s'", file);
	}
	line_sv = newSV_type(SVt_PV);
	// Read line by line using PerlIO
	while (sv_gets(line_sv, fp, 0) != NULL) {
		char *restrict line = SvPV_nolen(line_sv);
		size_t len = SvCUR(line_sv);
		// chomp \r\n (Handles Windows invisible \r natively)
		if (len > 0 && line[len-1] == '\n') {
			len--;
			if (len > 0 && line[len-1] == '\r') {
				len--;
			}
		}
		if (!in_quotes) {
			// Skip completely empty lines (\h*[\r\n]+$ equivalent)
			bool is_empty = 1;
			for (size_t i = 0; i < len; i++) {
				if (line[i] != ' ' && line[i] != '\t') { is_empty = 0; break; }
			}
			if (is_empty) continue;

			// Skip comments
			if (comment_len > 0 && len >= comment_len && strncmp(line, comment_str, comment_len) == 0) {
				continue;
			}
		}
		// --- CORE PARSING MACHINE ---
		for (size_t i = 0; i < len; i++) {
			const char ch = line[i];
			if (ch == '\r') continue;
			if (ch == '"') {
				if (in_quotes && (i + 1 < len) && line[i+1] == '"') {
					sv_catpvn(field, "\"", 1);
					i++; // Skip the escaped second quote
				} else if (in_quotes) {
					in_quotes = 0;  // Close quotes
					post_quote = 1;
				} else if (!post_quote) {
					in_quotes = 1; // Open quotes (only when not in post-quote state)
				}
			} else if (!in_quotes && sep_len > 0 && (len - i) >= sep_len && strncmp(line + i, sep_str, sep_len) == 0) {
				av_push(current_row, newSVsv(field));
				sv_setpvs(field, ""); // Reset for next field
				i += sep_len - 1;     // Advance past multi-char separators
				post_quote = 0;
			} else {
				sv_catpvn(field, &ch, 1);
			}
		}
		if (in_quotes) {
			// Line ended but quotes are still open! Append newline and fetch next
			sv_catpvn(field, "\n", 1);
		} else {
			post_quote = 0; // Reset post-quote state at row boundary
			// Push the final field of the record
			av_push(current_row, newSVsv(field));
			sv_setpvs(field, "");
			// If a callback is provided, invoke it in a streaming fashion
			if (use_cb) {
				dSP;
				ENTER;
				SAVETMPS;
				PUSHMARK(SP);
				XPUSHs(sv_2mortal(newRV_inc((SV*)current_row)));
				PUTBACK;
				call_sv(callback, G_DISCARD);
				FREETMPS;
				LEAVE;
				SvREFCNT_dec(current_row); // Frees the row from C memory if Perl didn't keep it
			} else {
				av_push(data, newRV_noinc((SV*)current_row));
			}
			current_row = newAV();
		}
	}
	PerlIO_close(fp);
	SvREFCNT_dec(line_sv);

	if (in_quotes) {
		av_push(current_row, newSVsv(field));
		if (use_cb) {
			dSP;
			ENTER;
			SAVETMPS;
			PUSHMARK(SP);
			XPUSHs(sv_2mortal(newRV_inc((SV*)current_row)));
			PUTBACK;
			call_sv(callback, G_DISCARD);
			FREETMPS;
			LEAVE;
			SvREFCNT_dec(current_row);
		} else {
			av_push(data, newRV_noinc((SV*)current_row));
		}
		current_row = newAV();
	}
	SvREFCNT_dec(field);
	SvREFCNT_dec(current_row);
	if (use_cb) {
		RETVAL = &PL_sv_undef; // Memory was fully handled by callback stream
	} else {
		RETVAL = newRV_noinc((SV*)data);
	}
OUTPUT:
	RETVAL

SV* cov(SV* x_sv, SV* y_sv, const char* method = "pearson")
	CODE:
	{
		// 1. Validate inputs are Array References
		if (!SvROK(x_sv) || SvTYPE(SvRV(x_sv)) != SVt_PVAV) {
			croak("cov: first argument 'x' must be an ARRAY reference");
		}
		if (!SvROK(y_sv) || SvTYPE(SvRV(y_sv)) != SVt_PVAV) {
			croak("cov: second argument 'y' must be an ARRAY reference");
		}

		// 2. Validate method argument
		if (strcmp(method, "pearson") != 0 && 
			strcmp(method, "spearman") != 0 && 
			strcmp(method, "kendall") != 0) {
			croak("cov: unknown method '%s' (use 'pearson', 'spearman', or 'kendall')", method);
		}

		AV *restrict x_av = (AV*)SvRV(x_sv);
		AV *restrict y_av = (AV*)SvRV(y_sv);
		size_t nx = av_len(x_av) + 1;
		size_t ny = av_len(y_av) + 1;

		if (nx != ny) {
			croak("cov: incompatible dimensions (x has %lu, y has %lu)", 
				   (unsigned long)nx, (unsigned long)ny);
		}

		// 3. Extract Valid Pairwise Data
		// Allocate temporary C arrays for numeric processing
		double *restrict x_val = (double*)safemalloc(nx * sizeof(double));
		double *restrict y_val = (double*)safemalloc(nx * sizeof(double));
		size_t n = 0;

		for (size_t i = 0; i < nx; i++) {
			SV **restrict x_tv = av_fetch(x_av, i, 0);
			SV **restrict y_tv = av_fetch(y_av, i, 0);

			// Extract numeric values, defaulting to NAN for missing/invalid data
			double xv = (x_tv && SvOK(*x_tv) && looks_like_number(*x_tv)) ? SvNV(*x_tv) : NAN;
			double yv = (y_tv && SvOK(*y_tv) && looks_like_number(*y_tv)) ? SvNV(*y_tv) : NAN;

			// Pairwise complete observations (skips NAs seamlessly like R)
			if (!isnan(xv) && !isnan(yv)) {
				 x_val[n] = xv;
				 y_val[n] = yv;
				 n++;
			}
		}

		// 4. Handle edge cases where data is too sparse
		if (n < 2) {
			Safefree(x_val);	Safefree(y_val);
			RETVAL = newSVnv(NAN);
		} else {
			double ans = 0.0;			
			// 5. Algorithm routing
			if (strcmp(method, "kendall") == 0) {
				// R's default cov(..., method="kendall") iterates the full n x n space
				for (size_t i = 0; i < n; i++) {
				  for (size_t j = 0; j < n; j++) {
						int sx = (x_val[i] > x_val[j]) - (x_val[i] < x_val[j]);
						int sy = (y_val[i] > y_val[j]) - (y_val[i] < y_val[j]);
						ans += (double)(sx * sy);
				  }
				}
			} else {
				double mean_x = 0.0, mean_y = 0.0, cov_sum = 0.0;
				if (strcmp(method, "spearman") == 0) {
				  // Spearman: Rank the data first, then run standard covariance
				  double *restrict rx = (double*)safemalloc(n * sizeof(double));
				  double *restrict ry = (double*)safemalloc(n * sizeof(double));
				  // Uses your existing rank_data() helper from LikeR.xs
				  rank_data(x_val, rx, n);
				  rank_data(y_val, ry, n);
				  for (size_t i = 0; i < n; i++) {
						double dx = rx[i] - mean_x;
						mean_x += dx / (i + 1);
						double dy = ry[i] - mean_y;
						mean_y += dy / (i + 1);
						cov_sum += dx * (ry[i] - mean_y);
				  }
				  Safefree(rx); Safefree(ry);
				} else { 
				  // Pearson: Welford's Single-Pass Covariance Algorithm
				  for (size_t i = 0; i < n; i++) {
						double dx = x_val[i] - mean_x;
						mean_x += dx / (i + 1);
						double dy = y_val[i] - mean_y;
						mean_y += dy / (i + 1);
						cov_sum += dx * (y_val[i] - mean_y);
				  }
				}

				// Unbiased Sample Covariance (N - 1) for Pearson & Spearman
				ans = cov_sum / (n - 1);
			}
			Safefree(x_val); Safefree(y_val);
			RETVAL = newSVnv(ans);
		}
	}
	OUTPUT:
		RETVAL

SV* glm(...)
CODE:
{
	const char *restrict formula  = NULL;
	SV *restrict data_sv = NULL;
	const char *restrict family_str = "gaussian";
	char f_cpy[512];
	char *restrict src, *restrict dst, *restrict tilde, *restrict lhs, *restrict rhs, *restrict chunk;

	// Dynamic Term Arrays
	char **restrict terms = NULL, **restrict uniq_terms = NULL, **restrict exp_terms = NULL;
	bool *restrict is_dummy = NULL;
	char **restrict dummy_base = NULL, **restrict dummy_level = NULL;
	unsigned int term_cap = 64, exp_cap = 64, num_terms = 0, num_uniq = 0, p = 0, p_exp = 0;
	size_t n = 0, valid_n = 0, i;
	bool has_intercept = TRUE, converged = FALSE, boundary = FALSE;
	unsigned int iter = 0, max_iter = 25, final_rank = 0, df_res = 0;
	double deviance_old = 0.0, deviance_new = 0.0, null_dev = 0.0, aic = 0.0;
	double dispersion = 0.0, epsilon = 1e-8;

	char **restrict row_names = NULL;
	char **restrict valid_row_names = NULL;
	HV **restrict row_hashes = NULL;
	HV *restrict data_hoa = NULL;
	SV *restrict ref = NULL;

	double *restrict X = NULL, *restrict Y = NULL, *restrict mu = NULL, *restrict eta = NULL;
	double *restrict W = NULL, *restrict Z = NULL, *restrict beta = NULL, *restrict beta_old = NULL;
	bool *restrict aliased = NULL;
	double *restrict XtWX = NULL, *restrict XtWZ = NULL;

	HV *restrict res_hv, *restrict coef_hv, *restrict fitted_hv, *restrict resid_hv, *restrict summary_hv;
	AV *restrict terms_av;
	HE *restrict entry;

	if (items % 2 != 0) croak("Usage: glm(formula => 'am ~ wt + hp', data => \\%mtcars)");

	for (unsigned short i_arg = 0; i_arg < items; i_arg += 2) {
	  const char *restrict key = SvPV_nolen(ST(i_arg));
	  SV *restrict val = ST(i_arg + 1);
	  if      (strEQ(key, "formula")) formula = SvPV_nolen(val);
	  else if (strEQ(key, "data"))    data_sv = val;
	  else if (strEQ(key, "family"))  family_str = SvPV_nolen(val);
	  else croak("glm: unknown argument '%s'", key);
	}        
	if (!formula) croak("glm: formula is required");
	if (!data_sv || !SvROK(data_sv)) croak("glm: data is required and must be a reference");

	bool is_binomial = (strcmp(family_str, "binomial") == 0);
	bool is_gaussian = (strcmp(family_str, "gaussian") == 0);
	if (!is_binomial && !is_gaussian) croak("glm: unsupported family '%s'", family_str);

	// --- Formula Parsing & Expansion ---
	Newx(terms, term_cap, char*); Newx(uniq_terms, term_cap, char*);
	Newx(exp_terms, exp_cap, char*); Newx(is_dummy, exp_cap, bool);
	Newx(dummy_base, exp_cap, char*); Newx(dummy_level, exp_cap, char*);

	src = (char*restrict)formula; dst = f_cpy;
	while (*src && (dst - f_cpy < 511)) { if (!isspace(*src)) { *dst++ = *src; } src++; }
	*dst = '\0';

	tilde = strchr(f_cpy, '~');
	if (!tilde) croak("glm: invalid formula, missing '~'");
	*tilde = '\0';
	lhs = f_cpy; rhs = tilde + 1;

	if (strstr(rhs, "-1")) has_intercept = FALSE;
	if (has_intercept) terms[num_terms++] = savepv("Intercept");

	chunk = strtok(rhs, "+");
	while (chunk != NULL) {
	  if (num_terms >= term_cap - 3) {
		   term_cap *= 2;
		   Renew(terms, term_cap, char*); Renew(uniq_terms, term_cap, char*);
	  }
	  if (strcmp(chunk, "1") == 0 || strcmp(chunk, "-1") == 0) {
		   chunk = strtok(NULL, "+");
		   continue;
	  }
	  char *restrict star = strchr(chunk, '*');
	  if (star) {
		   *star = '\0';
		   char *restrict left = chunk; char *restrict right = star + 1;
		   char *restrict c_l = strchr(left, '^'); if (c_l && strncmp(left, "I(", 2) != 0) *c_l = '\0';
		   char *restrict c_r = strchr(right, '^'); if (c_r && strncmp(right, "I(", 2) != 0) *c_r = '\0';
		   
		   terms[num_terms++] = savepv(left);
		   terms[num_terms++] = savepv(right);
		   size_t inter_len = strlen(left) + strlen(right) + 2;
		   terms[num_terms] = (char*)safemalloc(inter_len);
		   snprintf(terms[num_terms++], inter_len, "%s:%s", left, right);
	  } else {
		   char *restrict c_chunk = strchr(chunk, '^'); 
		   if (c_chunk && strncmp(chunk, "I(", 2) != 0) *c_chunk = '\0';
		   terms[num_terms++] = savepv(chunk);
	  }
	  chunk = strtok(NULL, "+");
	}

	for (i = 0; i < num_terms; i++) {
	  bool found = FALSE;
	  for (size_t j = 0; j < num_uniq; j++) {
		   if (strcmp(terms[i], uniq_terms[j]) == 0) { found = TRUE; break; }
	  }
	  if (!found) uniq_terms[num_uniq++] = savepv(terms[i]);
	}
	p = num_uniq;

	// --- Data Extraction ---
	ref = SvRV(data_sv);
	if (SvTYPE(ref) == SVt_PVHV) {
		HV*restrict hv = (HV*)ref;
		if (hv_iterinit(hv) == 0) croak("glm: Data hash is empty");
		entry = hv_iternext(hv);
		if (entry) {
			SV*restrict val = hv_iterval(hv, entry);
			if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
				 data_hoa = hv;
				 n = av_len((AV*)SvRV(val)) + 1;
				 Newx(row_names, n, char*);
				 for(i = 0; i < n; i++) {
				     char buf[32]; snprintf(buf, sizeof(buf), "%lu", i+1);
				     row_names[i] = savepv(buf);
				 }
			} else if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
				 n = hv_iterinit(hv);
				 Newx(row_names, n, char*); Newx(row_hashes, n, HV*);
				 i = 0;
				 while ((entry = hv_iternext(hv))) {
				     I32 len;
				     row_names[i] = savepv(hv_iterkey(entry, &len));
				     row_hashes[i] = (HV*)SvRV(hv_iterval(hv, entry));
				     i++;
				 }
			} else croak("glm: Hash values must be ArrayRefs (HoA) or HashRefs (HoH)");
		}
	} else if (SvTYPE(ref) == SVt_PVAV) {
	  AV*restrict av = (AV*)ref;
	  n = av_len(av) + 1;
	  Newx(row_names, n, char*); Newx(row_hashes, n, HV*);
	  for (i = 0; i < n; i++) {
		   SV**restrict val = av_fetch(av, i, 0);
		   if (val && SvROK(*val) && SvTYPE(SvRV(*val)) == SVt_PVHV) {
		       row_hashes[i] = (HV*)SvRV(*val);
		       char buf[32]; snprintf(buf, sizeof(buf), "%lu", i + 1);
		       row_names[i] = savepv(buf);
		   } else {
		       for (size_t k = 0; k < i; k++) Safefree(row_names[k]);
		       Safefree(row_names); Safefree(row_hashes);
		       croak("glm: Array values must be HashRefs (AoH)");
		   }
	  }
	} else croak("glm: Data must be an Array or Hash reference");

	// --- Categorical Expansion ---
	for (size_t j = 0; j < p; j++) {
		if (p_exp + 32 >= exp_cap) {
			exp_cap *= 2;
			Renew(exp_terms, exp_cap, char*); Renew(is_dummy, exp_cap, bool);
			Renew(dummy_base, exp_cap, char*); Renew(dummy_level, exp_cap, char*);
		}
		if (strcmp(uniq_terms[j], "Intercept") == 0) {
			exp_terms[p_exp] = savepv("Intercept"); is_dummy[p_exp] = FALSE; p_exp++; continue;
		}
		if (is_column_categorical(aTHX_ data_hoa, row_hashes, n, uniq_terms[j])) {
			char **restrict levels = NULL; size_t num_levels = 0, levels_cap = 8;
			Newx(levels, levels_cap, char*);
			for (i = 0; i < n; i++) {
				char*restrict str_val = get_data_string_alloc(aTHX_ data_hoa, row_hashes, i, uniq_terms[j]);
				if (str_val) {
				  bool found = FALSE;
				  for (size_t l = 0; l < num_levels; l++) {
						if (strcmp(levels[l], str_val) == 0) { found = TRUE; break; }
				  }
				  if (!found) {
						if (num_levels >= levels_cap) { levels_cap *= 2; Renew(levels, levels_cap, char*); }
						levels[num_levels++] = savepv(str_val);
				  }
				  Safefree(str_val);
				}
			}
			if (num_levels > 0) {
				 for (size_t l1 = 0; l1 < num_levels - 1; l1++) {
				     for (size_t l2 = l1 + 1; l2 < num_levels; l2++) {
				         if (strcmp(levels[l1], levels[l2]) > 0) {
				             char *tmp = levels[l1]; levels[l1] = levels[l2]; levels[l2] = tmp;
				         }
				     }
				 }
				 for (size_t l = 1; l < num_levels; l++) {
				     if (p_exp >= exp_cap) {
				         exp_cap *= 2;
				         Renew(exp_terms, exp_cap, char*); Renew(is_dummy, exp_cap, bool);
				         Renew(dummy_base, exp_cap, char*); Renew(dummy_level, exp_cap, char*);
				     }
				     size_t t_len = strlen(uniq_terms[j]) + strlen(levels[l]) + 1;
				     exp_terms[p_exp] = (char*)safemalloc(t_len);
				     snprintf(exp_terms[p_exp], t_len, "%s%s", uniq_terms[j], levels[l]);
				     is_dummy[p_exp] = TRUE; dummy_base[p_exp] = savepv(uniq_terms[j]); dummy_level[p_exp] = savepv(levels[l]);
				     p_exp++;
				 }
				 for (size_t l = 0; l < num_levels; l++) Safefree(levels[l]);
				 Safefree(levels);
			} else {
				 Safefree(levels); exp_terms[p_exp] = savepv(uniq_terms[j]); is_dummy[p_exp] = FALSE; p_exp++;
			}
		} else {
			exp_terms[p_exp] = savepv(uniq_terms[j]); is_dummy[p_exp] = FALSE; p_exp++;
		}
	}
	p = p_exp;

	Newx(X, n * p, double); Newx(Y, n, double);
	Newx(valid_row_names, n, char*);

	// --- Listwise Deletion ---
	for (size_t i = 0; i < n; i++) {
		double y_val = evaluate_term(aTHX_ data_hoa, row_hashes, i, lhs);
		if (isnan(y_val)) { Safefree(row_names[i]); continue; }

		bool row_ok = TRUE;
		double *restrict row_x = (double*)safemalloc(p * sizeof(double));
		for (size_t j = 0; j < p; j++) {
			if (strcmp(exp_terms[j], "Intercept") == 0) {
				 row_x[j] = 1.0;
			} else if (is_dummy[j]) {
				 char* str_val = get_data_string_alloc(aTHX_ data_hoa, row_hashes, i, dummy_base[j]);
				 if (str_val) {
				     row_x[j] = (strcmp(str_val, dummy_level[j]) == 0) ? 1.0 : 0.0;
				     Safefree(str_val);
				 } else { row_ok = FALSE; break; }
			} else {
				 row_x[j] = evaluate_term(aTHX_ data_hoa, row_hashes, i, exp_terms[j]);
				 if (isnan(row_x[j])) { row_ok = FALSE; break; }
			}
		}
		if (!row_ok) { Safefree(row_names[i]); Safefree(row_x); continue; }
		Y[valid_n] = y_val;
		for (size_t j = 0; j < p; j++) X[valid_n * p + j] = row_x[j];
		valid_row_names[valid_n] = row_names[i];
		valid_n++;
		Safefree(row_x);
	}
	Safefree(row_names); 
	if (valid_n <= p) {
	  Safefree(X); Safefree(Y); Safefree(valid_row_names); if (row_hashes) Safefree(row_hashes);
	  croak("glm: 0 degrees of freedom (too many NAs or parameters > observations)");
	}
	// --- R glm.fit IRLS Implementation ---
	mu = (double*)safemalloc(valid_n * sizeof(double)); eta = (double*)safemalloc(valid_n * sizeof(double));
	W = (double*)safemalloc(valid_n * sizeof(double)); Z = (double*)safemalloc(valid_n * sizeof(double));
	beta = (double*)safemalloc(p * sizeof(double)); beta_old = (double*)safemalloc(p * sizeof(double));
	aliased = (bool*)safemalloc(p * sizeof(bool));
	XtWX = (double*)safemalloc(p * p * sizeof(double)); XtWZ = (double*)safemalloc(p * sizeof(double));
	for (i = 0; i < p; i++) { beta[i] = 0.0; beta_old[i] = 0.0; }
	// Initialize (mustart / etastart equivalent)
	double sum_y = 0.0;
	for (i = 0; i < valid_n; i++) sum_y += Y[i];
	double mean_y = sum_y / valid_n;
	for (i = 0; i < valid_n; i++) {
		if (is_binomial) {
			if (Y[i] < 0.0 || Y[i] > 1.0) croak("glm: binomial family requires response between 0 and 1");
			mu[i] = (Y[i] + 0.5) / 2.0; 
			eta[i] = log(mu[i] / (1.0 - mu[i]));
			double dev = 0.0;
			if (Y[i] == 0.0)      dev = -2.0 * log(1.0 - mu[i]);
			else if (Y[i] == 1.0) dev = -2.0 * log(mu[i]);
			else dev = 2.0 * (Y[i] * log(Y[i] / mu[i]) + (1.0 - Y[i]) * log((1.0 - Y[i]) / (1.0 - mu[i])));
			deviance_old += dev;
		} else { 
			mu[i] = mean_y; // R gaussian init
			eta[i] = mu[i]; 
		}
	}
	// IRLS Loop
	for (iter = 1; iter <= max_iter; iter++) {
		for (i = 0; i < valid_n; i++) {
			if (is_binomial) {
				 double varmu = mu[i] * (1.0 - mu[i]);
				 double mu_eta = varmu; // Link derivative for logit
				 if (varmu < 1e-10) varmu = 1e-10;
				 Z[i] = eta[i] + (Y[i] - mu[i]) / mu_eta;
				 W[i] = (mu_eta * mu_eta) / varmu; 
			} else { 
				 W[i] = 1.0; 
				 Z[i] = Y[i]; 
			}
		}
		// Formulate XtWX and XtWZ
		for (i = 0; i < p; i++) { XtWZ[i] = 0.0; for (size_t j = 0; j < p; j++) XtWX[i * p + j] = 0.0; }
		for (size_t k = 0; k < valid_n; k++) {
			double w = W[k], z = Z[k];
			for (i = 0; i < p; i++) {
				 XtWZ[i] += X[k * p + i] * w * z;
				 double xw = X[k * p + i] * w;
				 for (size_t j = 0; j < p; j++) XtWX[i * p + j] += xw * X[k * p + j];
			}
		}
		final_rank = sweep_matrix_ols(XtWX, p, aliased);
		for (i = 0; i < p; i++) {
			if (aliased[i]) { beta[i] = NAN; } else {
				 double sum = 0.0;
				 for (size_t j = 0; j < p; j++) if (!aliased[j]) sum += XtWX[i * p + j] * XtWZ[j];
				 beta[i] = sum;
			}
		}
		// Calculate updated ETA, MU, and Deviance (with Step-Halving)
		boundary = FALSE;
		for (unsigned short int half = 0; half < 10; half++) {
			deviance_new = 0.0;
			for (i = 0; i < valid_n; i++) {
				 double linear_pred = 0.0;
				 for (size_t j = 0; j < p; j++) if (!aliased[j]) linear_pred += X[i * p + j] * beta[j];
				 eta[i] = linear_pred;
				 if (is_binomial) {
				     mu[i] = 1.0 / (1.0 + exp(-eta[i]));
				     // Boundary enforcement
				     if (mu[i] < 10 * DBL_EPSILON) mu[i] = 10 * DBL_EPSILON;
				     if (mu[i] > 1.0 - 10 * DBL_EPSILON) mu[i] = 1.0 - 10 * DBL_EPSILON;
				     
				     double dev = 0.0;
				     if (Y[i] == 0.0)      dev = -2.0 * log(1.0 - mu[i]);
				     else if (Y[i] == 1.0) dev = -2.0 * log(mu[i]);
				     else dev = 2.0 * (Y[i] * log(Y[i] / mu[i]) + (1.0 - Y[i]) * log((1.0 - Y[i]) / (1.0 - mu[i])));
				     deviance_new += dev;
				 } else {
				     mu[i] = eta[i];
				     double res = Y[i] - mu[i];
				     deviance_new += res * res;
				 }
			}
			// Step halving divergence check
			if (!is_binomial || deviance_new <= deviance_old + 1e-7 || !isfinite(deviance_new)) {
				 continue; 
			}
			
			boundary = TRUE;
			for (size_t j = 0; j < p; j++) beta[j] = (beta[j] + beta_old[j]) / 2.0;
		}
		// Convergence Check
		if (fabs(deviance_new - deviance_old) / (0.1 + fabs(deviance_new)) < epsilon) { 
			converged = TRUE; break; 
		}
		deviance_old = deviance_new;
		for (size_t j = 0; j < p; j++) beta_old[j] = beta[j];
	}
	// Final accurate calculation of W for standard errors
	for (i = 0; i < p; i++) { for (size_t j = 0; j < p; j++) XtWX[i * p + j] = 0.0; }
	for (size_t k = 0; k < valid_n; k++) {
	  double w = is_binomial ? (mu[k] * (1.0 - mu[k])) : 1.0;
	  if (w < 1e-10) w = 1e-10;
	  for (i = 0; i < p; i++) {
		   double xw = X[k * p + i] * w;
		   for (size_t j = 0; j < p; j++) XtWX[i * p + j] += xw * X[k * p + j];
	  }
	}
	final_rank = sweep_matrix_ols(XtWX, p, aliased);
	// --- Null Deviance Calculation ---
	double wtdmu = mean_y; // Since weights are 1.0 initially
	for (i = 0; i < valid_n; i++) {
	  if (is_binomial) {
		   if (Y[i] == 0.0)      null_dev += -2.0 * log(1.0 - wtdmu);
		   else if (Y[i] == 1.0) null_dev += -2.0 * log(wtdmu);
		   else null_dev += 2.0 * (Y[i] * log(Y[i] / wtdmu) + (1.0 - Y[i]) * log((1.0 - Y[i]) / (1.0 - wtdmu)));
	  } else {
		   double diff = Y[i] - wtdmu;
		   null_dev += diff * diff;
	  }
	}
	// --- AIC Calculation ---
	if (is_gaussian) {
	  double n_f = (double)valid_n;
	  aic = n_f * (log(2.0 * M_PI) + 1.0 + log(deviance_new / n_f)) + 2.0 * (final_rank + 1.0);
	} else if (is_binomial) { 
	  aic = deviance_new + 2.0 * final_rank; 
	}
	// --- Return Structures ---
	res_hv = newHV(); coef_hv = newHV(); fitted_hv = newHV(); resid_hv = newHV();
	df_res = valid_n - final_rank;
	dispersion = is_binomial ? 1.0 : ((df_res > 0) ? (deviance_new / df_res) : NAN);
	for (size_t i = 0; i < valid_n; i++) {
		double res = Y[i] - mu[i];
		if (is_binomial) {
			// Deviance residuals for binomial
			double d_res = 0.0;
			if (Y[i] == 0.0)      d_res = sqrt(-2.0 * log(1.0 - mu[i]));
			else if (Y[i] == 1.0) d_res = sqrt(-2.0 * log(mu[i]));
			else d_res = sqrt(2.0 * (Y[i] * log(Y[i] / mu[i]) + (1.0 - Y[i]) * log((1.0 - Y[i]) / (1.0 - mu[i]))));
			res = (Y[i] > mu[i]) ? d_res : -d_res;
		}
		hv_store(fitted_hv, valid_row_names[i], strlen(valid_row_names[i]), newSVnv(mu[i]), 0);
		hv_store(resid_hv,  valid_row_names[i], strlen(valid_row_names[i]), newSVnv(res), 0);
		Safefree(valid_row_names[i]);
	}
	Safefree(valid_row_names);

	summary_hv = newHV(); terms_av = newAV();
	for (size_t j = 0; j < p; j++) {
		hv_store(coef_hv, exp_terms[j], strlen(exp_terms[j]), newSVnv(beta[j]), 0);
		av_push(terms_av, newSVpv(exp_terms[j], 0));

		HV *restrict row_hv = newHV();
		if (aliased[j]) {
			hv_store(row_hv, "Estimate",   8, newSVpv("NaN", 0), 0);
			hv_store(row_hv, "Std. Error", 10, newSVpv("NaN", 0), 0);
			hv_store(row_hv, is_binomial ? "z value" : "t value", 7, newSVpv("NaN", 0), 0);
			hv_store(row_hv, is_binomial ? "Pr(>|z|)" : "Pr(>|t|)", 8, newSVpv("NaN", 0), 0);
		} else {
			double se = sqrt(dispersion * XtWX[j * p + j]);
			double val_stat = beta[j] / se;
			double p_val = is_binomial ? 2.0 * (1.0 - approx_pnorm(fabs(val_stat))) : get_t_pvalue(val_stat, df_res, "two.sided");
			
			hv_store(row_hv, "Estimate",   8, newSVnv(beta[j]), 0);
			hv_store(row_hv, "Std. Error", 10, newSVnv(se), 0);
			hv_store(row_hv, is_binomial ? "z value" : "t value", 7, newSVnv(val_stat), 0);
			hv_store(row_hv, is_binomial ? "Pr(>|z|)" : "Pr(>|t|)", 8, newSVnv(p_val), 0);
		}
		hv_store(summary_hv, exp_terms[j], strlen(exp_terms[j]), newRV_noinc((SV*)row_hv), 0);
	}

	hv_store(res_hv, "aic",            3, newSVnv(aic), 0);
	hv_store(res_hv, "coefficients",  12, newRV_noinc((SV*)coef_hv), 0);
	hv_store(res_hv, "converged",      9, newSVuv(converged ? 1 : 0), 0);
	hv_store(res_hv, "boundary",       8, newSVuv(boundary ? 1 : 0), 0);
	hv_store(res_hv, "deviance",       8, newSVnv(deviance_new), 0);
	hv_store(res_hv, "deviance.resid", 14, newRV_noinc((SV*)resid_hv), 0);
	hv_store(res_hv, "df.null",        7, newSVuv(valid_n - has_intercept), 0);
	hv_store(res_hv, "df.residual",   11, newSVuv(df_res), 0);
	hv_store(res_hv, "family",         6, newSVpv(family_str, 0), 0);
	hv_store(res_hv, "fitted.values", 13, newRV_noinc((SV*)fitted_hv), 0);
	hv_store(res_hv, "iter",           4, newSVuv(iter > max_iter ? max_iter : iter), 0);
	hv_store(res_hv, "null.deviance", 13, newSVnv(null_dev), 0);
	hv_store(res_hv, "rank",           4, newSVuv(final_rank), 0);
	hv_store(res_hv, "summary",        7, newRV_noinc((SV*)summary_hv), 0);
	hv_store(res_hv, "terms",          5, newRV_noinc((SV*)terms_av), 0);

	// --- Cleanup ---
	for (i = 0; i < num_terms; i++) Safefree(terms[i]);
	Safefree(terms);
	for (i = 0; i < num_uniq; i++) Safefree(uniq_terms[i]);
	Safefree(uniq_terms);
	for (size_t j = 0; j < p_exp; j++) {
		Safefree(exp_terms[j]);
		if (is_dummy[j]) { Safefree(dummy_base[j]); Safefree(dummy_level[j]); }
	}
	Safefree(exp_terms); Safefree(is_dummy); Safefree(dummy_base); Safefree(dummy_level);

	Safefree(mu); Safefree(eta); Safefree(Z); Safefree(W);
	Safefree(beta); Safefree(beta_old); Safefree(aliased);
	Safefree(XtWX); Safefree(XtWZ); Safefree(X); Safefree(Y);
	if (row_hashes) Safefree(row_hashes);

	RETVAL = newRV_noinc((SV*)res_hv);
}
OUTPUT:
    RETVAL

SV* cor_test(...)
CODE:
{
	if (items < 2 || items % 2 != 0)
		croak("Usage: cor_test(\\@x, \\@y, method => 'pearson', ...)");

	SV *restrict x_ref = ST(0), *restrict y_ref = ST(1);

	const char *restrict alternative = "two.sided";
	const char *restrict method = "pearson";
	SV *restrict exact_sv = NULL;
	double conf_level = 0.95;
	bool continuity = 0;

	/* Parse named arguments from the flat stack starting at index 2 */
	for (unsigned short int i = 2; i < items; i += 2) {
	  const char *restrict key = SvPV_nolen(ST(i));
	  SV *restrict val = ST(i + 1);

	  if      (strEQ(key, "alternative")) alternative = SvPV_nolen(val);
	  else if (strEQ(key, "method"))      method = SvPV_nolen(val);
	  else if (strEQ(key, "exact"))       exact_sv = val;
	  else if (strEQ(key, "conf.level") || strEQ(key, "conf_level")) conf_level = SvNV(val);
	  else if (strEQ(key, "continuity"))  continuity = SvTRUE(val);
	  else croak("cor_test: unknown argument '%s'", key);
	}

	AV *restrict x_av, *restrict y_av;
	double *restrict x, *restrict y;
	double estimate = 0, p_value = 0, statistic = 0, df = 0, ci_lower = 0, ci_upper = 0;

	bool is_pearson  = (strcmp(method, "pearson")  == 0);
	bool is_kendall  = (strcmp(method, "kendall")  == 0);
	bool is_spearman = (strcmp(method, "spearman") == 0);
	HV *restrict rhv;

	if (!SvOK(x_ref) || !SvROK(x_ref) || SvTYPE(SvRV(x_ref)) != SVt_PVAV ||
	    !SvOK(y_ref) || !SvROK(y_ref) || SvTYPE(SvRV(y_ref)) != SVt_PVAV) {
	  croak("cor_test: x and y must be array references");
	}

	x_av = (AV*)SvRV(x_ref);
	y_av = (AV*)SvRV(y_ref);

	size_t n_raw = av_len(x_av) + 1;
	if (n_raw != (size_t)(av_len(y_av) + 1)) croak("incompatible dimensions");

	x = safemalloc(n_raw * sizeof(double));
	y = safemalloc(n_raw * sizeof(double));

	size_t n = 0; /* Final count of pairwise complete observations */
	for (size_t i = 0; i < n_raw; i++) {
	  SV **restrict x_val = av_fetch(x_av, i, 0);
	  SV **restrict y_val = av_fetch(y_av, i, 0);

	  double xv = (x_val && SvOK(*x_val) && looks_like_number(*x_val)) ? SvNV(*x_val) : NAN;
	  double yv = (y_val && SvOK(*y_val) && looks_like_number(*y_val)) ? SvNV(*y_val) : NAN;

	  /* Pairwise complete observations (skips NAs seamlessly like R) */
	  if (!isnan(xv) && !isnan(yv)) {
	      x[n] = xv;
	      y[n] = yv;
	      n++;
	  }
	}

	if (n < 3) {
	  Safefree(x);
	  Safefree(y);
	  croak("not enough finite observations");
	}

	if (is_pearson) {
	  /* Welford's one-pass algorithm for Pearson correlation */
	  double mean_x = 0.0, mean_y = 0.0, M2_x = 0.0, M2_y = 0.0, cov = 0.0;
	  for (size_t i = 0; i < n; i++) {
	      double dx = x[i] - mean_x;
	      mean_x += dx / (i + 1);
	      double dy = y[i] - mean_y;
	      mean_y += dy / (i + 1);
	      M2_x += dx * (x[i] - mean_x);
	      M2_y += dy * (y[i] - mean_y);
	      cov  += dx * (y[i] - mean_y);
	  }
	  estimate = (M2_x > 0.0 && M2_y > 0.0) ? cov / sqrt(M2_x * M2_y) : 0.0;

	  /* Clamp to [-1, 1] to guard against floating-point overshoot */
	  if      (estimate >  1.0) estimate =  1.0;
	  else if (estimate < -1.0) estimate = -1.0;

	  df = (double)(n - 2);

	  /* BUG FIX: guard divide-by-zero when |estimate| == 1 exactly.
	   * A perfect correlation gives t = ±Inf, matching R's behaviour. */
	  double denom_t = 1.0 - estimate * estimate;
	  if (denom_t <= 0.0)
	      statistic = (estimate > 0.0) ? INFINITY : -INFINITY;
	  else
	      statistic = estimate * sqrt(df / denom_t);

	  /* Confidence interval via Fisher's Z transform.
	   * BUG FIX: when |estimate| == 1 the log blows up; clamp first.
	   * We use a half-ULP margin so tanh can recover ±1 cleanly. */
	  double est_clamped = estimate;
	  if      (est_clamped >=  1.0) est_clamped =  1.0 - DBL_EPSILON;
	  else if (est_clamped <= -1.0) est_clamped = -1.0 + DBL_EPSILON;

	  double z     = 0.5 * log((1.0 + est_clamped) / (1.0 - est_clamped));
	  double se    = 1.0 / sqrt((double)(n - 3));
	  double alpha = 1.0 - conf_level;
	  double q     = inverse_normal_cdf(1.0 - alpha / 2.0);
	  ci_lower = tanh(z - q * se);
	  ci_upper = tanh(z + q * se);

	  /* High-precision p-value using incomplete beta */
	  p_value = get_t_pvalue(statistic, df, alternative);

	} else if (is_kendall) {
	  /* BUG FIX: use long to avoid int overflow for large n */
	  long c = 0, d = 0, tie_x = 0, tie_y = 0;
	  for (size_t i = 0; i < n - 1; i++) {
	      for (size_t j = i + 1; j < n; j++) {
	          double sign_x = (x[i] > x[j]) - (x[i] < x[j]);
	          double sign_y = (y[i] > y[j]) - (y[i] < y[j]);

	          if      (sign_x == 0 && sign_y == 0) { /* joint tie — ignore */ }
	          else if (sign_x == 0) tie_x++;
	          else if (sign_y == 0) tie_y++;
	          else if (sign_x * sign_y > 0) c++;
	          else d++;
	      }
	  }
	  double denom = sqrt((double)(c + d + tie_x) * (double)(c + d + tie_y));

	  /* BUG FIX: use NAN (from <math.h>) instead of 0.0/0.0 (UB in C) */
	  estimate = (denom == 0.0) ? NAN : (double)(c - d) / denom;

	  bool has_ties = (tie_x > 0 || tie_y > 0);
	  bool do_exact;

	  /* Mirror R: exact defaults to TRUE if n < 50 and no ties */
	  if (!exact_sv || !SvOK(exact_sv))
	      do_exact = (n < 50) && !has_ties;
	  else
	      do_exact = SvTRUE(exact_sv) ? 1 : 0;

	  /* R overrides forced-exact back to approximation when ties exist */
	  if (do_exact && has_ties) do_exact = 0;

	  if (do_exact) {
	      double S_stat = (double)(c - d);
	      statistic = (double)c;
	      p_value = kendall_exact_pvalue(n, S_stat, alternative);
	  } else {
	      /* Normal approximation for large n or when ties are present */
	      double var_S = (double)n * (double)(n - 1) * (2.0 * (double)n + 5.0) / 18.0;
	      double S = (double)(c - d);
	      if (continuity) S -= (S > 0.0 ? 1.0 : -1.0);
	      statistic = S / sqrt(var_S);

	      if      (strcmp(alternative, "two.sided") == 0)
	          p_value = 2.0 * (1.0 - approx_pnorm(fabs(statistic)));
	      else if (strcmp(alternative, "less") == 0)
	          p_value = approx_pnorm(statistic);
	      else
	          p_value = 1.0 - approx_pnorm(statistic);
	  }

	} else if (is_spearman) {
	  double *restrict rank_x = safemalloc(n * sizeof(double));
	  double *restrict rank_y = safemalloc(n * sizeof(double));
	  compute_ranks(x, rank_x, n);
	  compute_ranks(y, rank_y, n);

	  /* Spearman rho = Pearson r of the ranks (Welford's algorithm) */
	  double mean_x = 0.0, mean_y = 0.0, M2_x = 0.0, M2_y = 0.0, cov = 0.0;
	  for (size_t i = 0; i < n; i++) {
	      double dx = rank_x[i] - mean_x;
	      mean_x += dx / (i + 1);
	      double dy = rank_y[i] - mean_y;
	      mean_y += dy / (i + 1);
	      M2_x += dx * (rank_x[i] - mean_x);
	      M2_y += dy * (rank_y[i] - mean_y);
	      cov  += dx * (rank_y[i] - mean_y);
	  }
	  estimate = (M2_x > 0.0 && M2_y > 0.0) ? cov / sqrt(M2_x * M2_y) : 0.0;

	  /* Clamp to [-1, 1] to guard against floating-point overshoot */
	  if      (estimate >  1.0) estimate =  1.0;
	  else if (estimate < -1.0) estimate = -1.0;

	  /* S = sum of squared rank differences (R's reported statistic) */
	  double S_stat = 0.0;
	  for (size_t i = 0; i < n; i++) {
	      double diff = rank_x[i] - rank_y[i];
	      S_stat += diff * diff;
	  }

	  /* Ties produce fractional (averaged) ranks — detect them */
	  bool has_ties = 0;
	  for (size_t i = 0; i < n; i++) {
	      if (rank_x[i] != floor(rank_x[i]) || rank_y[i] != floor(rank_y[i])) {
	          has_ties = 1;
	          break;
	      }
	  }

	  bool do_exact;
	  if (!exact_sv || !SvOK(exact_sv))
	      do_exact = (n < 10) && !has_ties;
	  else
	      do_exact = SvTRUE(exact_sv) ? 1 : 0;

	  if (do_exact) {
	      statistic = S_stat;
	      p_value   = spearman_exact_pvalue(S_stat, n, alternative);
	  } else {
	      double r = estimate;
	      /* NOTE: R silently ignores continuity correction for Spearman.
	       * The adjustment below is non-standard; a warning is emitted
	       * so callers are not silently misled. */
	      if (continuity) {
	          warn("cor_test: continuity correction is not defined for Spearman in R and is ignored here");
	      }
	      /* BUG FIX: guard divide-by-zero when |r| == 1 exactly */
	      double denom_t = 1.0 - r * r;
	      if (denom_t <= 0.0)
	          statistic = (r > 0.0) ? INFINITY : -INFINITY;
	      else
	          statistic = r * sqrt((double)(n - 2) / denom_t);
	      p_value = get_t_pvalue(statistic, (double)(n - 2), alternative);
	  }
	  Safefree(rank_x);
	  Safefree(rank_y);

	} else {
	  Safefree(x);
	  Safefree(y);
	  croak("Unknown method '%s': must be 'pearson', 'kendall', or 'spearman'", method);
	}

	Safefree(x);
	Safefree(y);

	rhv = newHV();
	hv_stores(rhv, "estimate",    newSVnv(estimate));
	hv_stores(rhv, "p.value",     newSVnv(p_value));
	hv_stores(rhv, "statistic",   newSVnv(statistic));
	hv_stores(rhv, "method",      newSVpv(method, 0));
	hv_stores(rhv, "alternative", newSVpv(alternative, 0));
	if (is_pearson) {
	  hv_stores(rhv, "parameter", newSVnv(df));
	  AV *restrict ci_av = newAV();
	  av_push(ci_av, newSVnv(ci_lower));
	  av_push(ci_av, newSVnv(ci_upper));
	  hv_stores(rhv, "conf.int", newRV_noinc((SV*)ci_av));
	}

	RETVAL = newRV_noinc((SV*)rhv);
}
OUTPUT:
    RETVAL

void shapiro_test(data)
	SV *data
PREINIT:
	AV *restrict av;
	HV *restrict ret_hash;
	size_t n_raw, n = 0;
	double *restrict x, w = 0.0, p_val = 0.0, mean = 0.0, ssq = 0.0;
PPCODE:
	if (!SvROK(data) || SvTYPE(SvRV(data)) != SVt_PVAV) {
	  croak("Expected an array reference");
	}

	av = (AV *)SvRV(data);
	n_raw = av_len(av) + 1;

	Newx(x, n_raw, double);

	// Extract variables and calculate mean (skipping undefined/NaN values)
	for (size_t i = 0; i < n_raw; i++) {
	  SV **restrict elem = av_fetch(av, i, 0);
	  if (elem && SvOK(*elem)) {
		   double val = SvNV(*elem);
		   if (!isnan(val)) {
		       x[n] = val;
		       mean += val;
		       n++;
		   }
	  }
	}

	if (n < 3 || n > 5000) {
	  Safefree(x);
	  croak("Sample size must be between 3 and 5000 (R's limit)");
	}

	mean /= n;
	// Calculate Sum of Squares */
	for (size_t i = 0; i < n; i++) {
	  ssq += (x[i] - mean) * (x[i] - mean);
	}
	if (ssq == 0.0) {
	  Safefree(x);
	  croak("Data is perfectly constant; cannot compute Shapiro-Wilk test");
	}
	qsort(x, n, sizeof(double), compare_doubles);
	
	// --- Core AS R94 Algorithm: Weights and Statistic W ---
	if (n == 3) {
	  double a_val = 0.7071067811865475; /* sqrt(1/2) */
	  double b_val = a_val * (x[2] - x[0]);
	  w = (b_val * b_val) / ssq;
	  if (w < 0.75) w = 0.75; 
	  // Exact P-value for n=3
	  p_val = 1.90985931710274 * (asin(sqrt(w)) - 1.04719755119660);
	} else {
	  double *restrict m, *restrict a;
	  double sum_m2 = 0.0, b_val = 0.0;
	  Newx(m, n, double);
	  Newx(a, n, double);
	  for (size_t i = 0; i < n; i++) {
		   m[i] = inverse_normal_cdf((i + 1.0 - 0.375) / (n + 0.25));
		   sum_m2 += m[i] * m[i];
	  }
	  double u = 1.0 / sqrt((double)n);
	  double a_n = -2.706056*pow(u,5) + 4.434685*pow(u,4) - 2.071190*pow(u,3) - 0.147981*pow(u,2) + 0.221157*u + m[n-1]/sqrt(sum_m2);
	  a[n-1] = a_n;
	  a[0]   = -a_n;
	  if (n == 4 || n == 5) {
		   double eps = (sum_m2 - 2.0 * m[n-1]*m[n-1]) / (1.0 - 2.0 * a_n*a_n);
		   for (unsigned int i = 1; i < n-1; i++) {
		       a[i] = m[i] / sqrt(eps);
		   }
	  } else {
		   double a_n1 = -3.582633*pow(u,5) + 5.682633*pow(u,4) - 1.752461*pow(u,3) - 0.293762*pow(u,2) + 0.042981*u + m[n-2]/sqrt(sum_m2);
		   a[n-2] = a_n1;
		   a[1]   = -a_n1;
		   double eps = (sum_m2 - 2.0 * m[n-1]*m[n-1] - 2.0 * m[n-2]*m[n-2]) / (1.0 - 2.0 * a_n*a_n - 2.0 * a_n1*a_n1);
		   for (unsigned int i = 2; i < n-2; i++) {
		       a[i] = m[i] / sqrt(eps);
		   }
	  }
	  for (size_t i = 0; i < n; i++) {
		   b_val += a[i] * x[i];
	  }
	  w = (b_val * b_val) / ssq;
	// --- AS R94 P-Value Calculation: High Precision Refinement ---
	  /* NOTE: p_val is declared in PREINIT above;
		* do NOT shadow it with a local 'double p_val' here or the result will never reach the caller.
		*/
	  double y = log(1.0 - w);
	  double z;
	  if (n <= 11) {
		   // Royston's branch for 4 <= n <= 11 (AS R94, small-sample path).
		   // gamma is the upper bound on y = log(1-W);
		   // if y reaches gamma the p-value is essentially zero
		   double nn = (double)n;
		   double gamma = 0.459 * nn - 2.273;
		   if (y >= gamma) {
		       p_val = 1e-19;
		   } else {
		       // Horner-form polynomials in n for mu and log(sigma)
		       double mu     = 0.544  + nn * (-0.39978  + nn * ( 0.025054  - nn * 0.0006714));
		       double sig_val= 1.3822 + nn * (-0.77857  + nn * ( 0.062767  - nn * 0.0020322));
		       double sigma  = exp(sig_val);
		       z = (-log(gamma - y) - mu) / sigma;
		       /* Upper-tail probability P(Z > z): small W → large z → small p-value.
		       */
		       p_val = 0.5 * erfc(z * M_SQRT1_2);
		   }
	  } else {
		   // Royston's branch for n >= 12 (AS R94, large-sample path)
		   double ln_n   = log((double)n);
		   // Horner-form polynomials in log(n) for mu and log(sigma). */
		   double mu     = -1.5861 + ln_n * (-0.31082 + ln_n * (-0.083751 + ln_n * 0.0038915));
		   double sig_val= -0.4803 + ln_n * (-0.082676 + ln_n * 0.0030302);
		   double sigma  = exp(sig_val);
		   z = (y - mu) / sigma;
		   p_val = 0.5 * erfc(z * M_SQRT1_2);
	  }
	  // Clamp the p-value
	  if (p_val > 1.0) p_val = 1.0;
	  if (p_val < 0.0) p_val = 0.0;
	  
	  Safefree(m); m = NULL;  Safefree(a); a = NULL;
	}
	Safefree(x); x = NULL;
	ret_hash = newHV();
	hv_stores(ret_hash, "statistic", newSVnv(w));
	hv_stores(ret_hash, "W",         newSVnv(w));
	hv_stores(ret_hash, "p_value",   newSVnv(p_val));
	hv_stores(ret_hash, "p.value",   newSVnv(p_val));
	EXTEND(SP, 1);
	PUSHs(sv_2mortal(newRV_noinc((SV *)ret_hash)));

double min(...)
	PROTOTYPE: @
	INIT:
		double min_val = 0.0;
		size_t count = 0;
		bool first = TRUE;
	CODE:
		for (unsigned short int i = 0; i < items; i++) {
			SV* restrict arg = ST(i);
			if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) {
				AV* restrict av = (AV*)SvRV(arg);
				size_t len = av_len(av) + 1;
				for (size_t j = 0; j < len; j++) {
				     SV** restrict tv = av_fetch(av, j, 0);
				     if (tv && SvOK(*tv)) {
				         double val = SvNV(*tv);
				         if (first || val < min_val) {
				             min_val = val;
				             first = FALSE;
				         }
				         count++;
				     } else {
				         croak("min: undefined value at array ref index %zu (argument %d)", j, (int)i);
				     }
				 }
			} else if (SvOK(arg)) {
				 double val = SvNV(arg);
				 if (first || val < min_val) {
				     min_val = val;
				     first = FALSE;
				 }
				 count++;
			} else {
				 croak("min: undefined value at argument index %d", (int)i);
			}
		}
		if (count == 0) croak("min needs >= 1 numeric element");
		RETVAL = min_val;
	OUTPUT:
	  RETVAL

double max(...)
	PROTOTYPE: @
	INIT:
		double max_val = 0.0;
		size_t count = 0;
		bool first = TRUE;
	CODE:
		for (size_t i = 0; i < items; i++) {
		   SV* restrict arg = ST(i);
		   if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) {
		       AV* restrict av = (AV*)SvRV(arg);
		       size_t len = av_len(av) + 1;
		       for (size_t j = 0; j < len; j++) {
		           SV** restrict tv = av_fetch(av, j, 0);
		           if (tv && SvOK(*tv)) {
		               double val = SvNV(*tv);
		               if (first || val > max_val) {
		                   max_val = val;
		                   first = FALSE;
		               }
		               count++;
		           } else {
		               croak("max: undefined value at array ref index %zu (argument %zu)", j, i);
		           }
		       }
		   } else if (SvOK(arg)) {
		       double val = SvNV(arg);
		       if (first || val > max_val) {
		           max_val = val;
		           first = FALSE;
		       }
		       count++;
		   } else {
		       croak("max: undefined value at argument index %zu", i);
		   }
	  }
	  if (count == 0) croak("max needs >= 1 numeric element");
	  RETVAL = max_val;
	OUTPUT:
		RETVAL

SV* runif(...)
CODE:
{
	size_t n = 0;
	double min = 0.0, max = 1.0;

	// Flags to track what has been assigned
	bool n_set = 0, min_set = 0, max_set = 0;

	unsigned int i = 0;

	if (items == 0) {
	  croak("Usage: runif(n, [min=0], [max=1]) or runif(n => $n, ...)");
	}

	while (i < items) {
		// 1. Check if the current argument is a string key for a named parameter
		if (i + 1 < items && SvPOK(ST(i))) {
			char *restrict key = SvPV_nolen(ST(i));
			if (strEQ(key, "n")) {
				n = (size_t)SvUV(ST(i+1));
				n_set = 1;
				i += 2;
				continue;
			} else if (strEQ(key, "min")) {
				min = SvNV(ST(i+1));
				min_set = 1;
				i += 2;
				continue;
			} else if (strEQ(key, "max")) {
				max = SvNV(ST(i+1));
				max_set = 1;
				i += 2;
				continue;
			}
		}

		// 2. Fallback to positional parsing if it's not a recognized key
		if (!n_set) {
			n = (size_t)SvUV(ST(i));
			n_set = 1;
		} else if (!min_set) {
			min = SvNV(ST(i));
			min_set = 1;
		} else if (!max_set) {
			max = SvNV(ST(i));
			max_set = 1;
		} else {
			croak("Too many arguments or unrecognized parameter passed to runif()");
		}
		i++;
	}
	if (!n_set) {
		croak("runif() requires at least the 'n' parameter");
	}
	// Ensure PRNG is seeded
	AUTO_SEED_PRNG();
	AV *restrict results = newAV();
	if (n > 0) {
		av_extend(results, n - 1);
	}
	const double range = max - min;
	for (size_t j = 0; j < n; j++) {
		double r;
		if (max < min) {
			r = NAN; // R behavior for inverted ranges
		} else {
			r = min + range * Drand01();
		}
		av_push(results, newSVnv(r));
	}
	RETVAL = newRV_noinc((SV*)results);
}
OUTPUT:
    RETVAL

SV* rbinom(...)
	CODE:
	{
	// Auto-seed the PRNG if the Perl script hasn't done so yet
	AUTO_SEED_PRNG();
	if (items % 2 != 0)
		croak("Usage: rbinom(n => 10, size => 100, prob => 0.5)");
	//Parse named arguments
	size_t n = 0, size = 0;
	double prob = 0.5;

	bool size_set = FALSE, prob_set = FALSE;

	for (unsigned short i = 0; i < items; i += 2) {
		const char* restrict key = SvPV_nolen(ST(i));
		SV* restrict val = ST(i + 1);

		if      (strEQ(key, "n"))      n    = (unsigned int)SvUV(val);
		else if (strEQ(key, "size")) { size = (unsigned int)SvUV(val); size_set = TRUE; }
		else if (strEQ(key, "prob")) { prob = SvNV(val); prob_set = TRUE; }
		else croak("rbinom: unknown argument '%s'", key);
	}

	// R requires size and prob to be explicitly passed in rbinom
	if (!size_set || !prob_set) croak("rbinom: 'size' and 'prob' are required arguments");
	if (prob < 0.0 || prob > 1.0) croak("rbinom: prob must be between 0 and 1");

	AV *restrict result_av = newAV();
	if (n > 0) {
		av_extend(result_av, n - 1);
		for (unsigned int i = 0; i < n; i++) {
		    av_store(result_av, i, newSVuv(generate_binomial(aTHX_ size, prob)));
		}
	}

	RETVAL = newRV_noinc((SV*)result_av);
	}
	OUTPUT:
		RETVAL

SV* hist(SV* x_sv, ...)
	CODE:
	{
		// 1. Validate Input
		if (!SvROK(x_sv) || SvTYPE(SvRV(x_sv)) != SVt_PVAV)
			croak("hist: first argument must be an array reference");

		AV*restrict x_av = (AV*)SvRV(x_sv);
		size_t n_raw = av_len(x_av) + 1;
		if (n_raw == 0) croak("hist: input array is empty");

		// 2. Extract Data & Find Range
		double *restrict x;
		Newx(x, n_raw, double);
		size_t n = 0;
		double min_val = DBL_MAX, max_val = -DBL_MAX;

		for (size_t i = 0; i < n_raw; i++) {
			SV**restrict tv = av_fetch(x_av, i, 0);
			if (tv && SvOK(*tv)) {
				 double val = SvNV(*tv);
				 x[n++] = val;
				 if (val < min_val) min_val = val;
				 if (val > max_val) max_val = val;
			}
		}
		if (n == 0) {
			Safefree(x);
			croak("hist: input contains no valid numeric data");
		}
		// 3. Determine Bin Count (Sturges default or user-provided)
		size_t n_bins = 0;

		if (items == 2) {
			// Support pure positional argument: hist($data, 22)
			n_bins = (size_t)SvIV(ST(1));
		} else if (items > 2) {
			/* Support named parameters even if mixed with positional arguments */
			for (unsigned short i = 1; i < items - 1; i++) {
				 /* Make sure the SV holds a string before doing string comparison */
				 if (SvPOK(ST(i)) && strEQ(SvPV_nolen(ST(i)), "breaks")) {
				     n_bins = (size_t)SvIV(ST(i+1));
				     break;
				 }
			}
			/* Fallback: if 'breaks' wasn't found but a positional number was given first */
			if (n_bins == 0 && looks_like_number(ST(1))) {
				 n_bins = (size_t)SvIV(ST(1));
			}
		}
		if (n_bins == 0) n_bins = calculate_sturges_bins(n);
		// 4. Allocate Result Arrays
		double *restrict breaks, *restrict mids, *restrict density;
		size_t *restrict counts;
		Newx(breaks,  n_bins + 1, double);
		Newx(mids,    n_bins,     double);
		Newx(density, n_bins,     double);
		Newx(counts,  n_bins,     size_t);

		// Generate simple linear breaks
		double step = (max_val - min_val) / (double)n_bins;
		for (size_t i = 0; i <= n_bins; i++) {
			breaks[i] = min_val + (double)i * step;
		}

		// 5. Compute Statistics
		compute_hist_logic(x, n, breaks, n_bins, counts, mids, density);

		// 6. Build Return HashRef
		HV*restrict res_hv = newHV();
		AV*restrict av_breaks  = newAV();
		AV*restrict av_counts  = newAV();
		AV*restrict av_mids    = newAV();
		AV*restrict av_density = newAV();
		for (size_t i = 0; i <= n_bins; i++) {
			av_push(av_breaks, newSVnv(breaks[i]));
			if (i < n_bins) {
				 av_push(av_counts,  newSViv(counts[i]));
				 av_push(av_mids,    newSVnv(mids[i]));
				 av_push(av_density, newSVnv(density[i]));
			}
		}
		hv_stores(res_hv, "breaks",  newRV_noinc((SV*)av_breaks));
		hv_stores(res_hv, "counts",  newRV_noinc((SV*)av_counts));
		hv_stores(res_hv, "mids",    newRV_noinc((SV*)av_mids));
		hv_stores(res_hv, "density", newRV_noinc((SV*)av_density));

		// Clean
		Safefree(x); Safefree(breaks); Safefree(mids);
		Safefree(density); Safefree(counts);

		RETVAL = newRV_noinc((SV*)res_hv);
	}
	OUTPUT:
	  RETVAL

SV* quantile(...)
	CODE:
	{
		SV *restrict x_sv = NULL;
		SV *restrict probs_sv = NULL;
		int arg_idx = 0;

		/* --- 1. Consume first positional arg as 'x' if it's an array ref --- */
		if (arg_idx < items && SvROK(ST(arg_idx)) && SvTYPE(SvRV(ST(arg_idx))) == SVt_PVAV) {
			 x_sv = ST(arg_idx);
			 arg_idx++;
		}

		/* --- 2. Remaining args must be key-value pairs --- */
		if ((items - arg_idx) % 2 != 0)
			 croak("Usage: quantile(\\@data, probs => \\@probs)  OR  quantile(x => \\@data, probs => \\@probs)");

		for (; arg_idx < items; arg_idx += 2) {
			 const char *restrict key = SvPV_nolen(ST(arg_idx));
			 SV *restrict val = ST(arg_idx + 1);

			 if      (strEQ(key, "x"))     x_sv     = val;
			 else if (strEQ(key, "probs")) probs_sv = val;
			 else croak("quantile: unknown argument '%s'", key);
		}
		if (!x_sv || !SvROK(x_sv) || SvTYPE(SvRV(x_sv)) != SVt_PVAV)
			croak("quantile: 'x' must be an array reference");
		AV *restrict x_av = (AV*)SvRV(x_sv);
		size_t n_raw = av_len(x_av) + 1;
		if (n_raw == 0) croak("quantile: 'x' is empty");

		/* --- Extract valid numeric data & drop NAs --- */
		double *restrict x;
		Newx(x, n_raw, double);
		size_t n = 0;
		for (size_t i = 0; i < n_raw; i++) {
			SV **restrict tv = av_fetch(x_av, i, 0);
			if (tv && SvOK(*tv)) {
				 x[n++] = SvNV(*tv);
			}
		}
		if (n == 0) {
			Safefree(x);
			croak("quantile: 'x' contains no valid numbers");
		}
		// --- Sort Data for Quantile Math ---
		qsort(x, n, sizeof(double), compare_doubles);
		// --- Parse Probabilities (Default matches R's c(0, .25, .5, .75, 1)) ---
		double default_probs[] = {0.0, 0.25, 0.50, 0.75, 1.0};
		unsigned int n_probs = 5;
		double *restrict probs;

		if (probs_sv && SvROK(probs_sv) && SvTYPE(SvRV(probs_sv)) == SVt_PVAV) {
			AV *restrict p_av = (AV*)SvRV(probs_sv);
			n_probs = av_len(p_av) + 1;
			Newx(probs, n_probs, double);
			for (unsigned int i = 0; i < n_probs; i++) {
				 SV **tv = av_fetch(p_av, i, 0);
				 probs[i] = (tv && SvOK(*tv)) ? SvNV(*tv) : 0.0;
				 if (probs[i] < 0.0 || probs[i] > 1.0) {
				     Safefree(x); Safefree(probs);
				     croak("quantile: probabilities must be between 0 and 1");
				 }
			}
		} else {
			Newx(probs, n_probs, double);
			for (unsigned int i = 0; i < n_probs; i++) probs[i] = default_probs[i];
		}

		/* --- Calculate Quantiles (R Type 7 Algorithm) --- */
		HV *restrict res_hv = newHV();

		for (size_t i = 0; i < n_probs; i++) {
			double p = probs[i], q = 0.0;

			if (n == 1) {
				 q = x[0];
			} else if (p == 1.0) {
				 q = x[n - 1]; /* Prevent out-of-bounds mapping */
			} else if (p == 0.0) {
				 q = x[0];
			} else {
				 /* Continuous sample quantile interpolation (Type 7) */
				 double h = (n - 1) * p;
				 unsigned int j = (unsigned int)h; /* floor via cast */
				 double gamma = h - j;
				 q = (1.0 - gamma) * x[j] + gamma * x[j + 1];
			}

			/* Format hash key to exactly match R's naming convention ("25%", "33.3%") */
			char key[32];
			double pct = p * 100.0;
			
			if (pct == (unsigned int)pct) {
				 snprintf(key, sizeof(key), "%.0f%%", pct);
			} else {
				 snprintf(key, sizeof(key), "%.1f%%", pct);
			}

			hv_store(res_hv, key, strlen(key), newSVnv(q), 0);
		}

		Safefree(x);
		Safefree(probs);

		RETVAL = newRV_noinc((SV*)res_hv);
	}
	OUTPUT:
	  RETVAL

double mean(...)
	PROTOTYPE: @
	INIT:
	  double total = 0;
	  size_t count = 0;
	CODE:
		for (size_t i = 0; i < items; i++) {
			SV* restrict arg = ST(i);
			if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) {
				AV* restrict av = (AV*)SvRV(arg);
				size_t len = av_len(av) + 1;
				for (size_t j = 0; j < len; j++) {
				     SV** restrict tv = av_fetch(av, j, 0);
				     if (tv && SvOK(*tv)) {
				         total += SvNV(*tv);
				         count++;
				     } else {
				         croak("mean: undefined value at array ref index %zu (argument %zu)", j, i);
				     }
				}
			} else if (SvOK(arg)) {
				 total += SvNV(arg);
				 count++;
			} else {
				 croak("mean: undefined value at argument index %zu", i);
			}
		}
		if (count == 0) croak("mean needs >= 1 element");
		RETVAL = total / count;
	OUTPUT:
	  RETVAL

void mode(...)
	PROTOTYPE: @
	PREINIT:
	HV *restrict counts;
	HV *restrict originals;
	size_t max_count = 0, arg_count = 0;
	HE *restrict he;
	PPCODE:
	/* counts:    string(value) -> occurrence count */
	/* originals: string(value) -> SV* first-seen original */
	counts    = (HV *)sv_2mortal((SV *)newHV());
	originals = (HV *)sv_2mortal((SV *)newHV());

	for (size_t i = 0; i < items; i++) {
		SV *restrict arg = ST(i);
		if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) {
			AV *restrict av = (AV *)SvRV(arg);
			size_t len = av_len(av) + 1;
			for (size_t j = 0; j < len; j++) {
				SV **restrict tv = av_fetch(av, j, 0);
				if (tv && SvOK(*tv)) {
					STRLEN klen;
					const char *restrict key = SvPV(*tv, klen);
					SV **restrict slot = hv_fetch(counts, key, klen, 1);
					if (!slot) croak("mode: internal hash error");
					size_t cnt = SvOK(*slot) ? SvIV(*slot) + 1 : 1;
					sv_setiv(*slot, cnt);
					if (cnt > max_count) max_count = cnt;
					if (cnt == 1)
						 hv_store(originals, key, klen, newSVsv(*tv), 0);
					arg_count++;
				} else {
					croak("mode: undefined value at array ref index %zu (argument %zu)", j, i);
				}
			}
		} else if (SvOK(arg)) {
			STRLEN klen;
			const char *restrict key = SvPV(arg, klen);
			SV **restrict slot = hv_fetch(counts, key, klen, 1);
			if (!slot) croak("mode: internal hash error");
			size_t cnt = SvOK(*slot) ? SvIV(*slot) + 1 : 1;
			sv_setiv(*slot, cnt);
			if (cnt > max_count) max_count = cnt;
			if (cnt == 1)
			  hv_store(originals, key, klen, newSVsv(arg), 0);
			arg_count++;
		} else {
			croak("mode: undefined value at argument index %zu", i);
		}
	}

	if (arg_count == 0)
		croak("mode needs >= 1 element");

	hv_iterinit(counts);
	while ((he = hv_iternext(counts))) {
		if (SvIV(hv_iterval(counts, he)) == max_count) {
			STRLEN klen;
			const char *restrict key = HePV(he, klen);
			SV **restrict orig = hv_fetch(originals, key, klen, 0);
			mXPUSHs(orig ? newSVsv(*orig) : newSVpvn(key, klen));
		}
	}

double sum(...)
	PROTOTYPE: @
	INIT:
		double total = 0;
		size_t count = 0;
	CODE:
		for (size_t i = 0; i < items; i++) {
			SV* restrict arg = ST(i);
			if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) {
				 AV* restrict av = (AV*)SvRV(arg);
				 size_t len = av_len(av) + 1;
				 for (size_t j = 0; j < len; j++) {
				     SV** restrict tv = av_fetch(av, j, 0);
				     if (tv && SvOK(*tv)) {
				         total += SvNV(*tv);
				         count++;
				     } else {
				         croak("sum: undefined value at array ref index %zu (argument %zu)", j, i);
				     }
				 }
			} else if (SvOK(arg)) {
				 total += SvNV(arg);
				 count++;
			} else {
				 croak("sum: undefined value at argument index %zu", i);
			}
		}
		if (count == 0) croak("sum needs >= 1 element");
		RETVAL = total;
	OUTPUT:
	  RETVAL

double sd(...)
	PROTOTYPE: @
	INIT:
	  double mean = 0.0, M2 = 0.0;
	  size_t count = 0;
	CODE:
		/* Single Pass Standard Deviation via Welford's Algorithm */
		for (size_t i = 0; i < items; i++) {
			SV* restrict arg = ST(i);
			if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) {
				AV* restrict av = (AV*)SvRV(arg);
				size_t len = av_len(av) + 1;
				for (size_t j = 0; j < len; j++) {
				  SV** restrict tv = av_fetch(av, j, 0);
				  if (tv && SvOK(*tv)) {
						count++;
						double val = SvNV(*tv);
						double delta = val - mean;
						mean += delta / count;
						M2 += delta * (val - mean);
				  } else {
						croak("sd: undefined value at array ref index %zu (argument %zu)", j, i);
				  }
				}
			} else if (SvOK(arg)) {
				 count++;
				 double val = SvNV(arg);
				 double delta = val - mean;
				 mean += delta / count;
				 M2 += delta * (val - mean);
			} else {
				 croak("sd: undefined value at argument index %zu", i);
			}
		}
		if (count < 2) croak("sd needs >= 2 elements");
		RETVAL = sqrt(M2 / (count - 1));
	OUTPUT:
	  RETVAL

double var(...)
	PROTOTYPE: @
	INIT:
	  double mean = 0.0, M2 = 0.0;
	  size_t count = 0;
	CODE:
	/* Single Pass Variance via Welford's Algorithm */
		for (size_t i = 0; i < items; i++) {
			SV* restrict arg = ST(i);
			if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) {
				 AV* restrict av = (AV*)SvRV(arg);
				 size_t len = av_len(av) + 1;
				 for (size_t j = 0; j < len; j++) {
					  SV** restrict tv = av_fetch(av, j, 0);
					  if (tv && SvOK(*tv)) {
						   count++;
						   double val = SvNV(*tv);
						   double delta = val - mean;
						   mean += delta / count;
						   M2 += delta * (val - mean);
					  } else {
						   croak("var: undefined value at array ref index %zu (argument %zu)", j, i);
					  }
				 }
			} else if (SvOK(arg)) {
				 count++;
				 double val = SvNV(arg);
				 double delta = val - mean;
				 mean += delta / count;
				 M2 += delta * (val - mean);
			} else {
				 croak("var: undefined value at argument index %zu", i);
			}
		}
		if (count < 2) croak("var needs >= 2 elements");
		RETVAL = M2 / (count - 1);
	OUTPUT:
		RETVAL

SV* t_test(...)
	CODE:
	{
		SV*restrict x_sv = NULL;
		SV*restrict y_sv = NULL;
		double mu = 0.0, conf_level = 0.95;
		bool paired = FALSE, var_equal = FALSE;
		const char*restrict alternative = "two.sided";

		unsigned short int arg_idx = 0;

		// 1. Shift first positional argument as 'x' if it's an array reference
		if (arg_idx < items && SvROK(ST(arg_idx)) && SvTYPE(SvRV(ST(arg_idx))) == SVt_PVAV) {
		  x_sv = ST(arg_idx);
		  arg_idx++;
		}

		// 2. Shift second positional argument as 'y' if it's an array reference
		if (arg_idx < items && SvROK(ST(arg_idx)) && SvTYPE(SvRV(ST(arg_idx))) == SVt_PVAV) {
		  y_sv = ST(arg_idx);
		  arg_idx++;
		}

		// Ensure the remaining arguments form complete key-value pairs
		if ((items - arg_idx) % 2 != 0) {
		  croak("Usage: t_test(\\@x, [\\@y], key => value, ...)");
		}

		// --- Parse named arguments from the remaining flat stack ---
		for (; arg_idx < items; arg_idx += 2) {
			const char*restrict key = SvPV_nolen(ST(arg_idx));
			SV*restrict val = ST(arg_idx + 1);

			if      (strEQ(key, "x"))           x_sv        = val;
			else if (strEQ(key, "y"))           y_sv        = val;
			else if (strEQ(key, "mu"))          mu          = SvNV(val);
			else if (strEQ(key, "paired"))      paired      = SvTRUE(val);
			else if (strEQ(key, "var_equal"))   var_equal   = SvTRUE(val);
			else if (strEQ(key, "conf_level"))  conf_level  = SvNV(val);
			else if (strEQ(key, "alternative")) alternative = SvPV_nolen(val);
			else croak("t_test: unknown argument '%s'", key);
		}

		// --- Validate required / types ---
		if (!x_sv || !SvROK(x_sv) || SvTYPE(SvRV(x_sv)) != SVt_PVAV)
			croak("t_test: 'x' is a required argument and must be an ARRAY reference");
		AV*restrict x_av = (AV*)SvRV(x_sv);
		size_t nx = av_len(x_av) + 1;
		if (nx < 2) croak("t_test: 'x' needs at least 2 elements");
		AV*restrict y_av = NULL;
		if (y_sv && SvROK(y_sv) && SvTYPE(SvRV(y_sv)) == SVt_PVAV)
			y_av = (AV*)SvRV(y_sv);
			
		if (conf_level <= 0.0 || conf_level >= 1.0)
			croak("t_test: 'conf_level' must be between 0 and 1");
		// --- Computation via Welford's Algorithm --- */
		double mean_x = 0.0, M2_x = 0.0, var_x, t_stat, df, p_val, std_err, cint_est;
		HV*restrict results = newHV();
		for (size_t i = 0; i < nx; i++) {
			SV**restrict tv = av_fetch(x_av, i, 0);
			double val = (tv && SvOK(*tv)) ? SvNV(*tv) : 0;
			double delta = val - mean_x;
			mean_x += delta / (i + 1);
			M2_x += delta * (val - mean_x);
		}
		var_x = M2_x / (nx - 1);
		if (var_x == 0.0 && !y_av) croak("t_test: data are essentially constant");

		if (paired || y_av) {
			if (!y_av) croak("t_test: 'y' must be provided for paired or two-sample tests");
			size_t ny = av_len(y_av) + 1;
			if (paired && ny != nx) croak("t_test: Paired arrays must be same length");
			double mean_y = 0.0, M2_y = 0.0, var_y;
			for (size_t i = 0; i < ny; i++) {
				 SV**restrict tv = av_fetch(y_av, i, 0);
				 double val = (tv && SvOK(*tv)) ? SvNV(*tv) : 0;
				 double delta = val - mean_y;
				 mean_y += delta / (i + 1);
				 M2_y += delta * (val - mean_y);
			}
			var_y = M2_y / (ny - 1);
			if (paired) {
				 double mean_d = 0.0, M2_d = 0.0;
				 for (size_t i = 0; i < nx; i++) {
					  SV**restrict dx_ptr = av_fetch(x_av, i, 0);
					  SV**restrict dy_ptr = av_fetch(y_av, i, 0);
				     double dx = (dx_ptr && SvOK(*dx_ptr)) ? SvNV(*dx_ptr) : 0.0;
				     double dy = (dy_ptr && SvOK(*dy_ptr)) ? SvNV(*dy_ptr) : 0.0;
				     double val = dx - dy;
				     double delta = val - mean_d;
				     mean_d += delta / (i + 1);
				     M2_d += delta * (val - mean_d);
				 }
				 double var_d = M2_d / (nx - 1);
				 if (var_d == 0.0) croak("t_test: data are essentially constant");
				 cint_est = mean_d;
				 std_err  = sqrt(var_d / nx);
				 t_stat   = (cint_est - mu) / std_err;
				 df       = nx - 1;
				 hv_store(results, "estimate", 8, newSVnv(mean_d), 0);
			} else if (var_equal) {
				 if (var_x == 0.0 && var_y == 0.0) croak("t_test: data are essentially constant");
				 double pooled_var = ((nx - 1) * var_x + (ny - 1) * var_y) / (nx + ny - 2);
				 cint_est = mean_x - mean_y;
				 std_err  = sqrt(pooled_var * (1.0 / nx + 1.0 / ny));
				 t_stat   = (cint_est - mu) / std_err;
				 df       = nx + ny - 2;
				 hv_store(results, "estimate_x", 10, newSVnv(mean_x), 0);
				 hv_store(results, "estimate_y", 10, newSVnv(mean_y), 0);
			} else {
				 if (var_x == 0.0 && var_y == 0.0) croak("t_test: data are essentially constant");
				 cint_est         = mean_x - mean_y;
				 double stderr_x2 = var_x / nx;
				 double stderr_y2 = var_y / ny;
				 std_err          = sqrt(stderr_x2 + stderr_y2);
				 t_stat           = (cint_est - mu) / std_err;
				 df = pow(stderr_x2 + stderr_y2, 2) /
				      (pow(stderr_x2, 2) / (nx - 1) + pow(stderr_y2, 2) / (ny - 1));
				 hv_store(results, "estimate_x", 10, newSVnv(mean_x), 0);
				 hv_store(results, "estimate_y", 10, newSVnv(mean_y), 0);
			}
		} else {
			cint_est = mean_x;
			std_err  = sqrt(var_x / nx);
			t_stat   = (cint_est - mu) / std_err;
			df       = nx - 1;
			hv_store(results, "estimate", 8, newSVnv(mean_x), 0);
		}
		p_val = get_t_pvalue(t_stat, df, alternative);
		double alpha = 1.0 - conf_level, t_crit, ci_lower, ci_upper;
		if (strcmp(alternative, "less") == 0) {
			t_crit   = qt_tail(df, alpha);
			ci_lower = -INFINITY;
			ci_upper = cint_est + t_crit * std_err;
		} else if (strcmp(alternative, "greater") == 0) {
			t_crit   = qt_tail(df, alpha);
			ci_lower = cint_est - t_crit * std_err;
			ci_upper = INFINITY;
		} else {
			t_crit   = qt_tail(df, alpha / 2.0);
			ci_lower = cint_est - t_crit * std_err;
			ci_upper = cint_est + t_crit * std_err;
		}
		AV*restrict conf_int = newAV();
		av_push(conf_int, newSVnv(ci_lower));
		av_push(conf_int, newSVnv(ci_upper));
		hv_store(results, "statistic", 9, newSVnv(t_stat), 0);
		hv_store(results, "df",        2, newSVnv(df),     0);
		hv_store(results, "p_value",   7, newSVnv(p_val),  0);
		hv_store(results, "conf_int",  8, newRV_noinc((SV*)conf_int), 0);
		RETVAL = newRV_noinc((SV*)results);
	}
	OUTPUT:
		RETVAL

void p_adjust(SV* p_sv, const char* method = "holm")
	INIT:
		if (!SvROK(p_sv) || SvTYPE(SvRV(p_sv)) != SVt_PVAV) {
			croak("p_adjust: first argument must be an ARRAY reference of p-values");
		}
		AV *restrict p_av = (AV*)SvRV(p_sv);
		size_t n = av_len(p_av) + 1;
		// Handle empty input
		if (n == 0) {
			XSRETURN_EMPTY;
		}
		// Normalize method string
		char meth[64];
		strncpy(meth, method, 63); meth[63] = '\0';
		for(unsigned short int i = 0; meth[i]; i++) meth[i] = tolower(meth[i]);
		// Resolve aliases
		if (strstr(meth, "benjamini") && strstr(meth, "hochberg")) strcpy(meth, "bh");
		if (strstr(meth, "benjamini") && strstr(meth, "yekutieli")) strcpy(meth, "by");
		if (strcmp(meth, "fdr") == 0) strcpy(meth, "bh");
		// Allocate C memory
		PVal *restrict arr;
		double *restrict adj;
		Newx(arr, n, PVal);
		Newx(adj, n, double);

		for (size_t i = 0; i < n; i++) {
			SV**restrict tv = av_fetch(p_av, i, 0);
			arr[i].p = (tv && SvOK(*tv)) ? SvNV(*tv) : 1.0;
			arr[i].orig_idx = i;
		}
		// Sort ascending (Stable sort using original index)
		qsort(arr, n, sizeof(PVal), cmp_pval);
	PPCODE:
		if (strcmp(meth, "bonferroni") == 0) {
			for (size_t i = 0; i < n; i++) {
				double v = arr[i].p * n;
				adj[arr[i].orig_idx] = (v < 1.0) ? v : 1.0;
			}
		} else if (strcmp(meth, "holm") == 0) {
			double cummax = 0.0;
			for (size_t i = 0; i < n; i++) {
				 double v = arr[i].p * (n - i);
				 if (v > cummax) cummax = v;
				 adj[arr[i].orig_idx] = (cummax < 1.0) ? cummax : 1.0;
			}
		} else if (strcmp(meth, "hochberg") == 0) {
			double cummin = 1.0;
			for (ssize_t i = n - 1; i >= 0; i--) {
				 double v = arr[i].p * (n - i);
				 if (v < cummin) cummin = v;
				 adj[arr[i].orig_idx] = (cummin < 1.0) ? cummin : 1.0;
			}
		} else if (strcmp(meth, "bh") == 0) {
			double cummin = 1.0;
			for (ssize_t i = n - 1; i >= 0; i--) {
				double v = arr[i].p * n / (i + 1.0);
				if (v < cummin) cummin = v;
				adj[arr[i].orig_idx] = (cummin < 1.0) ? cummin : 1.0;
			}
		} else if (strcmp(meth, "by") == 0) {
			double q = 0.0;
			for (size_t i = 1; i <= n; i++) q += 1.0 / i;
			double cummin = 1.0;
			for (ssize_t i = n - 1; i >= 0; i--) {
				double v = arr[i].p * n / (i + 1.0) * q;
				if (v < cummin) cummin = v;
				adj[arr[i].orig_idx] = (cummin < 1.0) ? cummin : 1.0;
			}
		} else if (strcmp(meth, "hommel") == 0) {
			double *restrict pa, *restrict q_arr;
			Newx(pa, n, double);
			Newx(q_arr, n, double);
			// Initial: min(n * p[i] / (i + 1))
			double min_val = n * arr[0].p;
			for (size_t i = 1; i < n; i++) {
				double temp = (n * arr[i].p) / (i + 1.0);
				if (temp < min_val) {
				   min_val = temp;
				}
			}
			// pa <- q <- rep(min, n)
			for (size_t i = 0; i < n; i++) {
				 pa[i] = min_val;
				 q_arr[i] = min_val;
			}
			for (size_t j = n - 1; j >= 2; j--) {
				 ssize_t n_mj = n - j;       // Max index for 'ij'. Length is n_mj + 1
				 ssize_t i2_len = j - 1;     // Length of 'i2
				 // Calculate q1 = min(j * p[i2] / (2:j))
				 double q1 = (j * arr[n_mj + 1].p) / 2.0;
				 for (size_t k = 1; k < i2_len; k++) {
				     double temp_q1 = (j * arr[n_mj + 1 + k].p) / (2.0 + k);
				     if (temp_q1 < q1) {
				         q1 = temp_q1;
				     }
				 }
				 // q[ij] <- pmin(j * p[ij], q1)
				 for (size_t i = 0; i <= n_mj; i++) {
				     double v = j * arr[i].p;
				     q_arr[i] = (v < q1) ? v : q1;
				 }
				 // q[i2] <- q[n - j]
				 for (size_t i = 0; i < i2_len; i++) {
				     q_arr[n_mj + 1 + i] = q_arr[n_mj];
				}
				 // pa <- pmax(pa, q)
				for (size_t i = 0; i < n; i++) {
				    if (pa[i] < q_arr[i]) {
				       pa[i] = q_arr[i];
				    }
				}
			}
			// pmin(1, pmax(pa, p))[ro] — map sorted results back to original indices
			for (size_t i = 0; i < n; i++) {
				double v = (pa[i] > arr[i].p) ? pa[i] : arr[i].p;
				if (v > 1.0) v = 1.0;
				adj[arr[i].orig_idx] = v;
			}
			Safefree(pa);  Safefree(q_arr);
		} else if (strcmp(meth, "none") == 0) {
			for (size_t i = 0; i < n; i++) {
				adj[arr[i].orig_idx] = arr[i].p;
			}
		} else {
			Safefree(arr); Safefree(adj);
			croak("Unknown p-value adjustment method: %s", method);
		}
		// Push values onto the Perl stack as a flat list
		EXTEND(SP, n);
		for (size_t i = 0; i < n; i++) {
			PUSHs(sv_2mortal(newSVnv(adj[i])));
		}
		Safefree(arr); arr = NULL;
		Safefree(adj); adj = NULL;

double median(...)
	PROTOTYPE: @
	INIT:
	  size_t total_count = 0, k = 0;
	  double* restrict nums;
	  double median_val = 0.0;
	CODE:
	  /* Pass 1: Count valid elements — die immediately on any undef */
	  for (size_t i = 0; i < items; i++) {
		   SV* restrict arg = ST(i);
		   if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) {
		       AV* restrict av = (AV*)SvRV(arg);
		       size_t len = av_len(av) + 1;
		       for (size_t j = 0; j < len; j++) {
		           SV** restrict tv = av_fetch(av, j, 0);
		           if (tv && SvOK(*tv)) {
		               total_count++;
		           } else {
		               croak("median: undefined value at array ref index %zu (argument %zu)", j, i);
		           }
		       }
		   } else if (SvOK(arg)) {
		       total_count++;
		   } else {
		       croak("median: undefined value at argument index %zu", i);
		   }
	  }
	  if (total_count == 0) croak("median needs >= 1 element");

	  /* Allocate C array now that we know the exact size */
	  Newx(nums, total_count, double);

	  /* Pass 2: Populate the C array — Safefree before any croak */
	  for (size_t i = 0; i < items; i++) {
		   SV* restrict arg = ST(i);
		   if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) {
		       AV* restrict av = (AV*)SvRV(arg);
		       size_t len = av_len(av) + 1;
		       for (size_t j = 0; j < len; j++) {
		           SV** restrict tv = av_fetch(av, j, 0);
		           if (tv && SvOK(*tv)) {
		               nums[k++] = SvNV(*tv);
		           } else {
		               Safefree(nums);
		               croak("median: undefined value at array ref index %zu (argument %zu)", j, i);
		           }
		       }
		   } else if (SvOK(arg)) {
		       nums[k++] = SvNV(arg);
		   } else {
		       Safefree(nums);
		       croak("median: undefined value at argument index %zu", i);
		   }
	  }

	  /* Sort and calculate median */
	  qsort(nums, total_count, sizeof(double), compare_doubles);
	  if (total_count % 2 == 0) {
		   median_val = (nums[total_count / 2 - 1] + nums[total_count / 2]) / 2.0;
	  } else {
		   median_val = nums[total_count / 2];
	  }
	  Safefree(nums);
	  nums = NULL;
	  RETVAL = median_val;
	OUTPUT:
	  RETVAL

SV* cor(SV* x_sv, SV* y_sv = &PL_sv_undef, const char* method = "pearson")
	INIT:
	// --- validate method -------------------------------------------
	if (strcmp(method, "pearson")  != 0 &&
		strcmp(method, "spearman") != 0 &&
		strcmp(method, "kendall")  != 0)
		  croak("cor: unknown method '%s' (use 'pearson', 'spearman', or 'kendall')",
		        method);

	// --- validate x ------------------------------------------------
	if (!SvROK(x_sv) || SvTYPE(SvRV(x_sv)) != SVt_PVAV)
		  croak("cor: x must be an ARRAY reference");

	AV*restrict x_av = (AV*)SvRV(x_sv);
	size_t nx   = av_len(x_av) + 1;
	if (nx == 0) croak("cor: x is empty");

	// --- detect whether x is a flat vector or a matrix (AoA) -------
	bool x_is_matrix = 0;
	{
		  SV**restrict fp = av_fetch(x_av, 0, 0);
		  if (fp && SvROK(*fp) && SvTYPE(SvRV(*fp)) == SVt_PVAV)
		      x_is_matrix = 1;
	}

	// --- detect y ----------------------------
	bool has_y = (SvOK(y_sv) && SvROK(y_sv) &&
		           SvTYPE(SvRV(y_sv)) == SVt_PVAV);

	AV*restrict y_av = has_y ? (AV*)SvRV(y_sv) : NULL;
	size_t ny = has_y ? av_len(y_av) + 1 : 0;

	bool y_is_matrix = 0;
	if (has_y && ny > 0) {
		SV**restrict fp = av_fetch(y_av, 0, 0);
		if (fp && SvROK(*fp) && SvTYPE(SvRV(*fp)) == SVt_PVAV)
			y_is_matrix = 1;
	}

	CODE:
	// Branch 1: both inputs are flat vectors  →  scalar result
	if (!x_is_matrix && !y_is_matrix) {
		  if (!has_y) {
		      /* cor(vector) == 1 by definition */
		      RETVAL = newSVnv(1.0);
		  } else {
		      if (nx != ny)
		          croak("cor: x and y must have the same length (%lu vs %lu)",
		                nx, ny);

		      if (nx < 2)
		          croak("cor: need at least 2 observations");

		      double *restrict xd, *restrict yd;
		      Newx(xd, nx, double);
		      Newx(yd, ny, double);

		      bool x_sd0 = 1, y_sd0 = 1;
		      double x_first = NAN, y_first = NAN;

		      for (size_t i = 0; i < nx; i++) {
		          SV**restrict tv = av_fetch(x_av, i, 0);
		          double val = (tv && SvOK(*tv) && looks_like_number(*tv)) ? SvNV(*tv) : NAN;
		          xd[i] = val;
		          if (!isnan(val)) {
		              if (isnan(x_first)) x_first = val;
		              else if (val != x_first) x_sd0 = 0;
		          }
		      }
		      for (size_t i = 0; i < ny; i++) {
		          SV**restrict tv = av_fetch(y_av, i, 0);
		          double val = (tv && SvOK(*tv) && looks_like_number(*tv)) ? SvNV(*tv) : NAN;
		          yd[i] = val;
		          if (!isnan(val)) {
		              if (isnan(y_first)) y_first = val;
		              else if (val != y_first) y_sd0 = 0;
		          }
		      }

		      if (x_sd0 || y_sd0) {
		          Safefree(xd); Safefree(yd);
		          if (x_sd0) croak("cor: standard deviation of x is 0");
		          croak("cor: standard deviation of y is 0");
		      }

		      double r = compute_cor(xd, yd, nx, method);
		      Safefree(xd); Safefree(yd);
		      RETVAL = newSVnv(r);
		  }
	} else {//Branch 2: x is a matrix (or y is a matrix)  →  AoA result
		  // -- resolve x matrix dimensions
		  if (!x_is_matrix)
		      croak("cor: x must be a matrix (array ref of array refs) "
		            "when y is a matrix");

		  SV**restrict xr0 = av_fetch(x_av, 0, 0);
		  if (!xr0 || !SvROK(*xr0) || SvTYPE(SvRV(*xr0)) != SVt_PVAV)
		      croak("cor: each row of x must be an ARRAY reference");

		  size_t ncols_x = av_len((AV*)SvRV(*xr0)) + 1;
		  if (ncols_x == 0) croak("cor: x matrix has zero columns");

		  size_t nrows   = nx;    /* observations */

		  // PRE-VALIDATION PASS: Ensure all rows are arrays to prevent memory leaks on croak
		  for (size_t i = 0; i < nrows; i++) {
		      SV**restrict rv = av_fetch(x_av, i, 0);
		      if (!rv || !SvROK(*rv) || SvTYPE(SvRV(*rv)) != SVt_PVAV)
		          croak("cor: x row %lu is not an array ref", i);
		  }
		  
		  if (has_y && y_is_matrix) {
		      if (ny != nrows) croak("cor: x and y must have the same number of rows (%lu vs %lu)", nrows, ny);
		      for (size_t i = 0; i < nrows; i++) {
		          SV**restrict rv = av_fetch(y_av, i, 0);
		          if (!rv || !SvROK(*rv) || SvTYPE(SvRV(*rv)) != SVt_PVAV)
		              croak("cor: y row %lu is not an array ref", i);
		      }
		  }

		  // -- extract x columns
		  double **restrict col_x;
		  Newx(col_x, ncols_x, double*);

		  for (size_t j = 0; j < ncols_x; j++) {
		      Newx(col_x[j], nrows, double);
		      bool sd0 = 1;
		      double first = NAN;
		      for (size_t i = 0; i < nrows; i++) {
		          SV**restrict rv = av_fetch(x_av, i, 0);
		          AV*restrict  row = (AV*)SvRV(*rv);
		          SV**restrict cv  = av_fetch(row, j, 0);
		          double val = (cv && SvOK(*cv) && looks_like_number(*cv)) ? SvNV(*cv) : NAN;
		          col_x[j][i] = val;
		          if (!isnan(val)) {
		              if (isnan(first)) first = val;
		              else if (val != first) sd0 = 0;
		          }
		      }
		      if (sd0) {
		          for (size_t k = 0; k <= j; k++) Safefree(col_x[k]);
		          Safefree(col_x);
		          croak("cor: standard deviation is 0 in x column %lu", j);
		      }
		  }

		  // -- resolve y: separate matrix or re-use x (symmetric)
		  size_t ncols_y;
		  double **restrict col_y   = NULL;
		  bool symmetric = 0;

		  // 1 = cor(X) — result is symmetric
		  if (has_y && y_is_matrix) {
		      // cross-correlation: X (nrows × p) vs Y (nrows × q)
		      SV**restrict yr0 = av_fetch(y_av, 0, 0);
		      ncols_y = av_len((AV*)SvRV(*yr0)) + 1;
		      if (ncols_y == 0) croak("cor: y matrix has zero columns");

		      Newx(col_y, ncols_y, double*);
		      for (size_t j = 0; j < ncols_y; j++) {
		          Newx(col_y[j], nrows, double);
		          bool sd0 = 1;
		          double first = NAN;
		          for (size_t i = 0; i < nrows; i++) {
		              SV**restrict  rv = av_fetch(y_av, i, 0);
		              AV*restrict  row = (AV*)SvRV(*rv);
		              SV**restrict cv  = av_fetch(row, j, 0);
		              double val = (cv && SvOK(*cv) && looks_like_number(*cv)) ? SvNV(*cv) : NAN;
		              col_y[j][i] = val;
		              if (!isnan(val)) {
		                  if (isnan(first)) first = val;
		                  else if (val != first) sd0 = 0;
		              }
		          }
		          if (sd0) {
		              for (size_t k = 0; k < ncols_x; k++) Safefree(col_x[k]);
		              Safefree(col_x);
		              for (size_t k = 0; k <= j; k++) Safefree(col_y[k]);
		              Safefree(col_y);
		              croak("cor: standard deviation is 0 in y column %lu", j);
		          }
		      }
		  } else { // cor(X) — symmetric p×p result; share column arrays
		      ncols_y  = ncols_x;
		      col_y    = col_x;
		      symmetric = 1;
		  }
		  if (nrows < 2)
		      croak("cor: need at least 2 observations (got %lu)", nrows);
		  // -- build cache for symmetric case: compute upper triangle, store results, mirror to lower triangle
		  AV*restrict result_av = newAV();
		  av_extend(result_av, ncols_x - 1);
		  // Allocate per-row AVs up front so we can fill them in order
		  AV **restrict rows_out;
		  Newx(rows_out, ncols_x, AV*);
		  for (size_t i = 0; i < ncols_x; i++) {
		      rows_out[i] = newAV();
		      av_extend(rows_out[i], ncols_y - 1);
		  }
		  if (symmetric) {
/* Upper triangle + diagonal, then mirror. r_cache[i][j] (j >= i) holds the computed value. */
		      double **restrict r_cache;
		      Newx(r_cache, ncols_x, double*);
		      for (size_t i = 0; i < ncols_x; i++)
		          Newx(r_cache[i], ncols_x, double);

		      for (size_t i = 0; i < ncols_x; i++) {
		          r_cache[i][i] = 1.0; // diagonal
		          for (size_t j = i + 1; j < ncols_x; j++) {
		              double r = compute_cor(col_x[i], col_x[j], nrows, method);
		              r_cache[i][j] = r;
		              r_cache[j][i] = r; // symmetry
		          }
		      }
		      // fill output AoA from cache
		      for (size_t i = 0; i < ncols_x; i++)
		          for (size_t j = 0; j < ncols_x; j++)
		              av_store(rows_out[i], j, newSVnv(r_cache[i][j]));

		      for (size_t i = 0; i < ncols_x; i++) Safefree(r_cache[i]);
		      Safefree(r_cache); r_cache = NULL;
		  } else {
		      // cross-correlation: every (i,j) pair is independent
		      for (size_t i = 0; i < ncols_x; i++)
		          for (size_t j = 0; j < ncols_y; j++)
		              av_store(rows_out[i], j, newSVnv(compute_cor(col_x[i], col_y[j], nrows, method)));
		  }
		  // push row AVs into result
		  for (size_t i = 0; i < ncols_x; i++)
		      av_store(result_av, i, newRV_noinc((SV*)rows_out[i]));
		  Safefree(rows_out); rows_out = NULL;
		  // -- free column arrays -------------------------------------
		  for (size_t j = 0; j < ncols_x; j++) Safefree(col_x[j]);
		  Safefree(col_x); col_x = NULL;
		  if (!symmetric) {
		      for (size_t j = 0; j < ncols_y; j++) Safefree(col_y[j]);
		      Safefree(col_y);
		  }
		  RETVAL = newRV_noinc((SV*)result_av);
	}
	OUTPUT:
		RETVAL

void scale(...)
	PROTOTYPE: @
	PPCODE:
	{
		bool do_center_mean = TRUE, do_scale_sd = TRUE;
		double center_val = 0.0, scale_val = 1.0;
		size_t data_items = items;
		// 1. Parse Options Hash (if it exists as the last argument)
		if (items > 0) {
			SV*restrict last_arg = ST(items - 1);
			if (SvROK(last_arg) && SvTYPE(SvRV(last_arg)) == SVt_PVHV) {
				 data_items = items - 1; // Exclude hash from data processing
				 HV*restrict opt_hv = (HV*)SvRV(last_arg);
				 // --- Parse 'center'
				 SV**restrict center_sv = hv_fetch(opt_hv, "center", 6, 0);
				 if (center_sv) {
				     SV*restrict val_sv = *center_sv;
				     if (!SvOK(val_sv)) {
				         do_center_mean = FALSE; center_val = 0.0;
				     } else {
				         char *restrict str = SvPV_nolen(val_sv);
				         /* Trap booleans and empty strings before numeric checks */
				         if (strcasecmp(str, "mean") == 0 || strcasecmp(str, "true") == 0 || strcmp(str, "1") == 0) {
				             do_center_mean = TRUE;
				         } else if (strcasecmp(str, "none") == 0 || strcasecmp(str, "false") == 0 || strcmp(str, "0") == 0 || strcmp(str, "") == 0) {
				             do_center_mean = FALSE; center_val = 0.0;
				         } else if (looks_like_number(val_sv)) {
				             do_center_mean = FALSE; center_val = SvNV(val_sv);
				         } else if (SvTRUE(val_sv)) {
				             do_center_mean = TRUE;
				         } else {
				             do_center_mean = FALSE; center_val = 0.0;
				         }
				     }
				 }
				 // --- Parse 'scale' ---
				 SV**restrict scale_sv = hv_fetch(opt_hv, "scale", 5, 0);
				 if (scale_sv) {
				     SV*restrict val_sv = *scale_sv;
				     if (!SvOK(val_sv)) {
				         do_scale_sd = FALSE; scale_val = 1.0;
				     } else {
				         char *restrict str = SvPV_nolen(val_sv);
				         if (strcasecmp(str, "sd") == 0 || strcasecmp(str, "true") == 0 || strcmp(str, "1") == 0) {
				             do_scale_sd = TRUE;
				         } else if (strcasecmp(str, "none") == 0 || strcasecmp(str, "false") == 0 || strcmp(str, "0") == 0 || strcmp(str, "") == 0) {
				             do_scale_sd = FALSE; scale_val = 1.0;
				         } else if (looks_like_number(val_sv)) {
				             do_scale_sd = FALSE; scale_val = SvNV(val_sv);
				             if (scale_val == 0.0) scale_val = 1.0; /* Prevent Division By Zero */
				         } else if (SvTRUE(val_sv)) {
				             do_scale_sd = TRUE;
				         } else {
				             do_scale_sd = FALSE; scale_val = 1.0;
				         }
				     }
				 }
			}
		}
		// 2. Detect if the input is a Matrix (Array of Arrays)
		bool is_matrix = FALSE;
		if (data_items == 1) {
			SV*restrict first_arg = ST(0);
			if (SvROK(first_arg) && SvTYPE(SvRV(first_arg)) == SVt_PVAV) {
				 AV*restrict av = (AV*)SvRV(first_arg);
				 if (av_len(av) >= 0) {
				     SV**restrict first_elem = av_fetch(av, 0, 0);
				     if (first_elem && SvROK(*first_elem) && SvTYPE(SvRV(*first_elem)) == SVt_PVAV) {
				         is_matrix = TRUE;
				     }
				 }
			}
		}
		if (is_matrix) {
			//
			// MATRIX MODE: Scale columns independently (Just like R)
			//
			AV*restrict mat_av = (AV*)SvRV(ST(0));
			size_t nrow = av_len(mat_av) + 1, ncol = 0;
			
			SV**restrict first_row = av_fetch(mat_av, 0, 0);
			ncol = av_len((AV*)SvRV(*first_row)) + 1;

			if (nrow == 0 || ncol == 0) croak("scale requires non-empty matrix");

			// Create a new matrix for the scaled output
			AV*restrict result_av = newAV();
			av_extend(result_av, nrow - 1);
			AV**restrict row_ptrs = (AV**)safemalloc(nrow * sizeof(AV*));
			for (size_t r = 0; r < nrow; r++) {
				 row_ptrs[r] = newAV();
				 av_extend(row_ptrs[r], ncol - 1);
				 av_push(result_av, newRV_noinc((SV*)row_ptrs[r]));
			}
			// Calculate and apply scale per column
			for (size_t c = 0; c < ncol; c++) {
				 double col_sum = 0.0;
				 double *restrict col_data;
				 Newx(col_data, nrow, double);
				 // Extract the column data
				 for (size_t r = 0; r < nrow; r++) {
				     SV**restrict row_sv = av_fetch(mat_av, r, 0);
				     if (row_sv && SvROK(*row_sv)) {
				         AV*restrict row_av = (AV*)SvRV(*row_sv);
				         SV**restrict cell_sv = av_fetch(row_av, c, 0);
				         col_data[r] = (cell_sv && SvOK(*cell_sv)) ? SvNV(*cell_sv) : 0.0;
				     } else {
				         col_data[r] = 0.0;
				     }
				     col_sum += col_data[r];
				 }

				 double col_center = do_center_mean ? (col_sum / nrow) : center_val;
				 double col_scale = scale_val;
				 // Calculate Standard Deviation for this specific column if needed
				 if (do_scale_sd) {
				     if (nrow <= 1) {
				         Safefree(col_data);
				         safefree(row_ptrs);
				         croak("scale needs >= 2 rows to calculate standard deviation for a matrix column");
				     }
				     double sum_sq = 0.0;
				     for (size_t r = 0; r < nrow; r++) {
				         double diff = col_data[r] - col_center;
				         sum_sq += diff * diff;
				     }
				     col_scale = sqrt(sum_sq / (nrow - 1));
				 }
				 // Store scaled values back into the new matrix rows
				 for (size_t r = 0; r < nrow; r++) {
				     double centered = col_data[r] - col_center;
				     double final_val = (col_scale == 0.0) ? (0.0 / 0.0) : (centered / col_scale);
				     av_store(row_ptrs[r], c, newSVnv(final_val));
				 }
				 Safefree(col_data);
			}
			safefree(row_ptrs);
			// Push the resulting matrix as a single Reference onto the Perl stack
			EXTEND(SP, 1);
			PUSHs(sv_2mortal(newRV_noinc((SV*)result_av)));
		} else {
			// ======================================
			// FLAT LIST MODE: Original functionality
			// ======================================
			size_t total_count = 0, k = 0;
			double *restrict nums;
			double sum = 0.0;
			for (size_t i = 0; i < data_items; i++) {
				SV*restrict arg = ST(i);
				if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) {
					AV*restrict av = (AV*)SvRV(arg);
					size_t len = av_len(av) + 1;
					for (unsigned int j = 0; j < len; j++) {
						SV**restrict tv = av_fetch(av, j, 0);
						if (tv && SvOK(*tv)) { total_count++; }
					}
				} else if (SvOK(arg)) {
					total_count++;
				}
			}
			if (total_count == 0) croak("scale requires at least 1 numeric element");
			Newx(nums, total_count, double);
			for (size_t i = 0; i < data_items; i++) {
				 SV*restrict arg = ST(i);
				 if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) {
				     AV*restrict av = (AV*)SvRV(arg);
				     size_t len = av_len(av) + 1;
				     for (size_t j = 0; j < len; j++) {
				         SV**restrict tv = av_fetch(av, j, 0);
				         if (tv && SvOK(*tv)) { 
				             double val = SvNV(*tv);
				             nums[k++] = val; sum += val;
				         }
				     }
				 } else if (SvOK(arg)) {
				     double val = SvNV(arg);
				     nums[k++] = val; sum += val;
				 }
			}
			if (do_center_mean) center_val = sum / total_count;
			if (do_scale_sd) {
				 if (total_count <= 1) {
				     Safefree(nums);
				     croak("scale needs >= 2 elements to calculate SD");
				 }
				 double sum_sq = 0.0;
				 for (size_t i = 0; i < total_count; i++) {
				     double diff = nums[i] - center_val;
				     sum_sq += diff * diff;
				 }
				 scale_val = sqrt(sum_sq / (total_count - 1));
			}
			EXTEND(SP, total_count);
			for (size_t i = 0; i < total_count; i++) {
				double centered = nums[i] - center_val;
				double final_val = (scale_val == 0.0) ? (0.0 / 0.0) : (centered / scale_val);
				PUSHs(sv_2mortal(newSVnv(final_val)));
			}
			Safefree(nums); nums = NULL;
		}
	}

SV* matrix(...) 
CODE:
	// Basic check: must have an even number of arguments for key => value
	if (items % 2 != 0) {
	  croak("Usage: matrix(data => [...], nrow => $n, ncol => $m, byrow => $bool)");
	}
	SV*restrict data_sv = NULL;
	size_t nrow = 0, ncol = 0;
	bool byrow = FALSE, nrow_set = FALSE, ncol_set = FALSE;
	// Parse named arguments
	for (size_t i = 0; i < items; i += 2) {
	  char*restrict key = SvPV_nolen(ST(i));
	  SV*restrict val   = ST(i + 1);
	  if (strEQ(key, "data")) {
		   data_sv = val;
	  } else if (strEQ(key, "nrow")) {
		   nrow = (size_t)SvUV(val);
		   nrow_set = TRUE;
	  } else if (strEQ(key, "ncol")) {
		   ncol = (size_t)SvUV(val);
		   ncol_set = TRUE;
	  } else if (strEQ(key, "byrow")) {
		   byrow = SvTRUE(val);
	  } else {
		   croak("Unknown option: %s", key);
	  }
	}
	// Validate data input
	if (!data_sv || !SvROK(data_sv) || SvTYPE(SvRV(data_sv)) != SVt_PVAV) {
	  croak("The 'data' option must be an array reference (e.g. data => [1..6])");
	}
	AV*restrict data_av = (AV*)SvRV(data_sv);
	size_t data_len = (UV)(av_top_index(data_av) + 1);
	if (data_len == 0) {
	  croak("Data array cannot be empty");
	}
	// R-style dimension inference
	if (!nrow_set && !ncol_set) {
	  nrow = data_len;
	  ncol = 1;
	} else if (nrow_set && !ncol_set) {
	  ncol = (data_len + nrow - 1) / nrow;
	} else if (!nrow_set && ncol_set) {
	  nrow = (data_len + ncol - 1) / ncol;
	}
	// Final safety check for dimensions
	if (nrow == 0 || ncol == 0) {
	  croak("Dimensions must be greater than 0");
	}
	// Create the matrix (Array of Arrays)
	AV*restrict result_av = newAV();
	av_extend(result_av, nrow - 1);
	size_t r, c;// Use unsigned types for counters to prevent negative indexing
	AV**restrict row_ptrs = (AV**restrict)safemalloc(nrow * sizeof(AV*)); /* Pre-allocate row pointers */
	for (r = 0; r < nrow; r++) {
	  row_ptrs[r] = newAV();
	  av_extend(row_ptrs[r], ncol - 1);
	  av_push(result_av, newRV_noinc((SV*)row_ptrs[r]));
	}
	// Fill the matrix
	size_t total_cells = nrow * ncol;
	for (size_t i = 0; i < total_cells; i++) {
	  // Vector recycling logic
	  SV**restrict fetched = av_fetch(data_av, i % data_len, 0);
	  SV*restrict val = fetched ? newSVsv(*fetched) : newSV(0);
	  if (byrow) {
		   r = i / ncol;
		   c = i % ncol;
	  } else {
		   r = i % nrow;
		   c = i / nrow;
	  }
	  av_store(row_ptrs[r], c, val);
	}
	safefree(row_ptrs);
	RETVAL = newRV_noinc((SV*)result_av);
	OUTPUT:
	RETVAL

SV* lm(...)
CODE:
{
	const char *restrict formula  = NULL;
	SV *restrict data_sv = NULL;
	char f_cpy[512];
	char *restrict src, *restrict dst, *restrict tilde, *restrict lhs, *restrict rhs, *restrict chunk;

	char **restrict terms = NULL, **restrict uniq_terms = NULL, **restrict exp_terms = NULL;
	bool *restrict is_dummy = NULL;
	char **restrict dummy_base = NULL, **restrict dummy_level = NULL;
	unsigned int term_cap = 64, exp_cap = 64, num_terms = 0, num_uniq = 0, p = 0, p_exp = 0;
	size_t n = 0, valid_n = 0, i, j, k, l, l1, l2;
	bool has_intercept = TRUE;

	char **restrict row_names = NULL, **restrict valid_row_names = NULL;
	HV **restrict row_hashes = NULL;
	HV *restrict data_hoa = NULL;
	SV *restrict ref = NULL;

	double *restrict X = NULL, *restrict Y = NULL, *restrict XtX = NULL, *restrict XtY = NULL;
	bool *restrict aliased = NULL;
	double *restrict beta = NULL;
	int final_rank = 0, df_res = 0;
	HV *restrict res_hv, *restrict coef_hv, *restrict fitted_hv, *restrict resid_hv, *restrict summary_hv;
	AV *restrict terms_av;
	double rss = 0.0, rse_sq = 0.0;
	HE *restrict entry;

	if (items % 2 != 0) croak("Usage: lm(formula => 'mpg ~ wt * hp', data => \\%%mtcars)");

	for (unsigned short i_arg = 0; i_arg < items; i_arg += 2) {
	  const char *restrict key = SvPV_nolen(ST(i_arg));
	  SV *restrict val = ST(i_arg + 1);
	  if      (strEQ(key, "formula")) formula = SvPV_nolen(val);
	  else if (strEQ(key, "data"))    data_sv = val;
	  else croak("lm: unknown argument '%s'", key);
	}
	if (!formula) croak("lm: formula is required");
	if (!data_sv || !SvROK(data_sv)) croak("lm: data is required and must be a reference");

	// ========================================================================
	// PHASE 1: Data Extraction
	// ========================================================================
	ref = SvRV(data_sv);
	if (SvTYPE(ref) == SVt_PVHV) {
		HV *restrict hv = (HV*)ref;
		if (hv_iterinit(hv) == 0) croak("lm: Data hash is empty");
		entry = hv_iternext(hv);
		if (entry) {
			SV *restrict val = hv_iterval(hv, entry);
			if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
				data_hoa = hv;
				n = av_len((AV*)SvRV(val)) + 1;
				Newx(row_names, n, char*);
				for (size_t i = 0; i < n; i++) {
				  char buf[32];
				  snprintf(buf, sizeof(buf), "%lu", (unsigned long)(i + 1));
				  row_names[i] = savepv(buf);
				}
			} else if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
				n = hv_iterinit(hv);
				Newx(row_names, n, char*); Newx(row_hashes, n, HV*);
				i = 0;
				while ((entry = hv_iternext(hv))) {
				  I32 len;
				  row_names[i] = savepv(hv_iterkey(entry, &len));
				  row_hashes[i] = (HV*)SvRV(hv_iterval(hv, entry));
				  i++;
				}
			} else croak("lm: Hash values must be ArrayRefs (HoA) or HashRefs (HoH)");
		}
	} else if (SvTYPE(ref) == SVt_PVAV) {
		AV *restrict av = (AV*)ref; n = av_len(av) + 1;
		Newx(row_names, n, char*);
		Newx(row_hashes, n, HV*);
		for (size_t i = 0; i < n; i++) {
			SV **restrict val = av_fetch(av, i, 0);
			if (val && SvROK(*val) && SvTYPE(SvRV(*val)) == SVt_PVHV) {
				 row_hashes[i] = (HV*)SvRV(*val);
				 char buf[32]; snprintf(buf, sizeof(buf), "%lu", (unsigned long)(i + 1));
				 row_names[i] = savepv(buf);
			} else {
				 for (k = 0; k < i; k++) Safefree(row_names[k]);
				 Safefree(row_names); Safefree(row_hashes);
				 croak("lm: Array values must be HashRefs (AoH)");
			}
		}
	} else croak("lm: Data must be an Array or Hash reference");
	//
	// PHASE 2: Formula Parsing & `.` Expansion
	//
	src = (char*)formula; dst = f_cpy;
	while (*src && (dst - f_cpy < 511)) { if (!isspace(*src)) { *dst++ = *src; } src++; }
	*dst = '\0';

	tilde = strchr(f_cpy, '~');
	if (!tilde) {
	  for (size_t i = 0; i < n; i++) Safefree(row_names[i]);
	  Safefree(row_names); if (row_hashes) Safefree(row_hashes);
	  croak("lm: invalid formula, missing '~'");
	}
	*tilde = '\0';
	lhs = f_cpy;
	rhs = tilde + 1;

	// Remove intercept-suppression markers from RHS.
	// IMPORTANT: skip tokens that appear inside I(...) wrappers so that
	// expressions like I(x^-1) are never mistakenly treated as "-1".
	{
		char *restrict p_idx = rhs;
		while (*p_idx) {
			// Skip over I(...) sub-expressions entirely
			if (p_idx[0] == 'I' && p_idx[1] == '(') {
				int depth = 0;
				while (*p_idx) { if (*p_idx == '(') depth++; else if (*p_idx == ')') { depth--; if (depth == 0) { p_idx++; break; } } p_idx++; }
				continue;
			}
			// Match bare -1
			if (p_idx[0] == '-' && p_idx[1] == '1' &&
				(p_idx[2] == '\0' || p_idx[2] == '+' || p_idx[2] == '-')) {
				has_intercept = FALSE;
				memmove(p_idx, p_idx + 2, strlen(p_idx + 2) + 1);
				continue; // re-examine same position
			}
			// Match +0
			if (p_idx[0] == '+' && p_idx[1] == '0' &&
				(p_idx[2] == '\0' || p_idx[2] == '+' || p_idx[2] == '-')) {
				has_intercept = FALSE;
				memmove(p_idx, p_idx + 2, strlen(p_idx + 2) + 1);
				continue;
			}
			// Match leading 0+
			if (p_idx == rhs && p_idx[0] == '0' && p_idx[1] == '+') {
				has_intercept = FALSE;
				memmove(p_idx, p_idx + 2, strlen(p_idx + 2) + 1);
				continue;
			}
			// Match bare 0 (entire rhs)
			if (p_idx == rhs && p_idx[0] == '0' && p_idx[1] == '\0') {
				has_intercept = FALSE; p_idx[0] = '\0'; break;
			}
			// Strip redundant +1 (keep intercept, just remove marker)
			if (p_idx[0] == '+' && p_idx[1] == '1' &&
				(p_idx[2] == '\0' || p_idx[2] == '+' || p_idx[2] == '-')) {
				memmove(p_idx, p_idx + 2, strlen(p_idx + 2) + 1);
				continue;
			}
			// Strip leading bare 1 or 1+
			if (p_idx == rhs) {
				if (p_idx[0] == '1' && p_idx[1] == '\0') { p_idx[0] = '\0'; break; }
				if (p_idx[0] == '1' && p_idx[1] == '+') { memmove(p_idx, p_idx + 2, strlen(p_idx + 2) + 1); continue; }
			}
			p_idx++;
		}
	}
	// Clean up stray `++`, leading `+`, trailing `+`
	{
		char *restrict p_idx;
		while ((p_idx = strstr(rhs, "++")) != NULL)
			memmove(p_idx, p_idx + 1, strlen(p_idx + 1) + 1);
		if (rhs[0] == '+') memmove(rhs, rhs + 1, strlen(rhs + 1) + 1);
		size_t len_rhs = strlen(rhs);
		if (len_rhs > 0 && rhs[len_rhs - 1] == '+') rhs[len_rhs - 1] = '\0';
	}

	// Expand `.` Operator
	char rhs_expanded[2048] = "";
	size_t rhs_len = 0;
	chunk = strtok(rhs, "+");
	while (chunk != NULL) {
		if (strcmp(chunk, ".") == 0) {
			AV *restrict cols = get_all_columns(aTHX_ data_hoa, row_hashes, n);
			for (size_t c = 0; c <= (size_t)av_len(cols); c++) {
				SV **restrict col_sv = av_fetch(cols, c, 0);
				if (col_sv && SvOK(*col_sv)) {
					const char *restrict col_name = SvPV_nolen(*col_sv);
					if (strcmp(col_name, lhs) != 0) {
						size_t slen = strlen(col_name);
						if (rhs_len + slen + 2 < sizeof(rhs_expanded)) {
							if (rhs_len > 0) { strcat(rhs_expanded, "+"); rhs_len++; }
							strcat(rhs_expanded, col_name);
							rhs_len += slen;
						}
					}
				}
			}
			SvREFCNT_dec(cols);
		} else {
			size_t slen = strlen(chunk);
			if (rhs_len + slen + 2 < sizeof(rhs_expanded)) {
				 if (rhs_len > 0) { strcat(rhs_expanded, "+"); rhs_len++; }
				 strcat(rhs_expanded, chunk);
				 rhs_len += slen;
			}
		}
		chunk = strtok(NULL, "+");
	}

	Newx(terms, term_cap, char*); Newx(uniq_terms, term_cap, char*);
	Newx(exp_terms, exp_cap, char*); Newx(is_dummy, exp_cap, bool);
	Newx(dummy_base, exp_cap, char*); Newx(dummy_level, exp_cap, char*);

	if (has_intercept) { terms[num_terms++] = savepv("Intercept"); }

	if (strlen(rhs_expanded) > 0) {
	  chunk = strtok(rhs_expanded, "+");
	  while (chunk != NULL) {
		   if (num_terms >= term_cap - 3) {
		       term_cap *= 2;
		       Renew(terms, term_cap, char*); Renew(uniq_terms, term_cap, char*);
		   }
		   char *restrict star = strchr(chunk, '*');
		   if (star) {
		       *star = '\0';
		       char *restrict left = chunk;
		       char *restrict right = star + 1;
		       char *restrict c_l = strchr(left, '^');
		       if (c_l && strncmp(left, "I(", 2) != 0) *c_l = '\0';
		       char *restrict c_r = strchr(right, '^');
		       if (c_r && strncmp(right, "I(", 2) != 0) *c_r = '\0';
		       terms[num_terms++] = savepv(left);
		       terms[num_terms++] = savepv(right);
		       size_t inter_len = strlen(left) + strlen(right) + 2;
		       terms[num_terms] = (char*)safemalloc(inter_len);
		       snprintf(terms[num_terms++], inter_len, "%s:%s", left, right);
		   } else {
		       char *restrict c_chunk = strchr(chunk, '^');
		       if (c_chunk && strncmp(chunk, "I(", 2) != 0) *c_chunk = '\0';
		       terms[num_terms++] = savepv(chunk);
		   }
		   chunk = strtok(NULL, "+");
	  }
	}

	for (i = 0; i < num_terms; i++) {
	  bool found = FALSE;
	  for (j = 0; j < num_uniq; j++) { if (strcmp(terms[i], uniq_terms[j]) == 0) { found = TRUE; break; } }
	  if (!found) uniq_terms[num_uniq++] = savepv(terms[i]);
	}
	p = num_uniq;

	// ========================================================================
	// PHASE 3: Categorical Expansion
	// ========================================================================
	for (j = 0; j < p; j++) {
		if (p_exp + 32 >= exp_cap) {
			exp_cap *= 2;
			Renew(exp_terms, exp_cap, char*); Renew(is_dummy, exp_cap, bool);
			Renew(dummy_base, exp_cap, char*); Renew(dummy_level, exp_cap, char*);
		}
		if (strcmp(uniq_terms[j], "Intercept") == 0) {
			exp_terms[p_exp] = savepv("Intercept"); is_dummy[p_exp] = FALSE; p_exp++; continue;
		}
		if (is_column_categorical(aTHX_ data_hoa, row_hashes, n, uniq_terms[j])) {
		char **restrict levels = NULL;
		unsigned int num_levels = 0, levels_cap = 8;
		Newx(levels, levels_cap, char*);
		for (i = 0; i < n; i++) {
			char *restrict str_val = get_data_string_alloc(aTHX_ data_hoa, row_hashes, i, uniq_terms[j]);
			if (str_val) {
			  bool found = FALSE;
			  for (l = 0; l < num_levels; l++) { if (strcmp(levels[l], str_val) == 0) { found = TRUE; break; } }
			  if (!found) {
					if (num_levels >= levels_cap) { levels_cap *= 2; Renew(levels, levels_cap, char*); }
					levels[num_levels++] = savepv(str_val);
			  }
			  Safefree(str_val);
			}
		}
		if (num_levels > 0) {
			 for (l1 = 0; l1 < num_levels - 1; l1++)
				  for (l2 = l1 + 1; l2 < num_levels; l2++)
				      if (strcmp(levels[l1], levels[l2]) > 0) { char *tmp = levels[l1]; levels[l1] = levels[l2]; levels[l2] = tmp; }
			 for (l = 1; l < num_levels; l++) {
				  if (p_exp >= exp_cap) {
				      exp_cap *= 2;
				      Renew(exp_terms, exp_cap, char*); Renew(is_dummy, exp_cap, bool);
				      Renew(dummy_base, exp_cap, char*); Renew(dummy_level, exp_cap, char*);
				  }
				  size_t t_len = strlen(uniq_terms[j]) + strlen(levels[l]) + 1;
				  exp_terms[p_exp] = (char*)safemalloc(t_len);
				  snprintf(exp_terms[p_exp], t_len, "%s%s", uniq_terms[j], levels[l]);
				  is_dummy[p_exp] = TRUE;
				  dummy_base[p_exp]  = savepv(uniq_terms[j]);
				  dummy_level[p_exp] = savepv(levels[l]);
				  p_exp++;
			 }
			 for (l = 0; l < num_levels; l++) Safefree(levels[l]);
			 Safefree(levels);
		} else {
			 Safefree(levels);
			 exp_terms[p_exp] = savepv(uniq_terms[j]); is_dummy[p_exp] = FALSE; p_exp++;
		}
		} else {
			exp_terms[p_exp] = savepv(uniq_terms[j]); is_dummy[p_exp] = FALSE; p_exp++;
		}
	}
	p = p_exp;
	Newx(X, n * p, double); Newx(Y, n, double);
	Newx(valid_row_names, n, char*);

	//
	// PHASE 4: Matrix Construction & Listwise Deletion
	//
	for (i = 0; i < n; i++) {
	  double y_val = evaluate_term(aTHX_ data_hoa, row_hashes, i, lhs);
	  if (isnan(y_val)) { Safefree(row_names[i]); continue; }

	  bool row_ok = TRUE;
	  double *restrict row_x = (double*)safemalloc(p * sizeof(double));
	  for (j = 0; j < p; j++) {
		   if (strcmp(exp_terms[j], "Intercept") == 0) {
		       row_x[j] = 1.0;
		   } else if (is_dummy[j]) {
		       char *restrict str_val = get_data_string_alloc(aTHX_ data_hoa, row_hashes, i, dummy_base[j]);
		       if (str_val) {
		           row_x[j] = (strcmp(str_val, dummy_level[j]) == 0) ? 1.0 : 0.0;
		           Safefree(str_val);
		       } else { row_ok = FALSE; break; }
		   } else {
		       row_x[j] = evaluate_term(aTHX_ data_hoa, row_hashes, i, exp_terms[j]);
		       if (isnan(row_x[j])) { row_ok = FALSE; break; }
		   }
	  }
	  if (!row_ok) { Safefree(row_names[i]); Safefree(row_x); continue; }

	  Y[valid_n] = y_val;
	  for (j = 0; j < p; j++) X[valid_n * p + j] = row_x[j];
	  valid_row_names[valid_n] = row_names[i];
	  valid_n++;
	  Safefree(row_x);
	}
	Safefree(row_names);
	if (valid_n <= p) {
	  for (i = 0; i < num_terms; i++) Safefree(terms[i]); Safefree(terms);
	  for (i = 0; i < num_uniq; i++) Safefree(uniq_terms[i]); Safefree(uniq_terms);
	  for (j = 0; j < p_exp; j++) {
		   Safefree(exp_terms[j]);
		   if (is_dummy[j]) { Safefree(dummy_base[j]); Safefree(dummy_level[j]); }
	  }
	  Safefree(exp_terms); Safefree(is_dummy); Safefree(dummy_base); Safefree(dummy_level);
	  Safefree(X); Safefree(Y); Safefree(valid_row_names);
	  if (row_hashes) Safefree(row_hashes);
	  croak("lm: 0 degrees of freedom (too many NAs or parameters > observations)");
	}
	//
	// PHASE 5: OLS Math
	//
	Newxz(XtX, p * p, double);
	for (i = 0; i < p; i++)
	  for (j = 0; j < p; j++) {
		   double sum = 0.0;
		   for (k = 0; k < valid_n; k++) sum += X[k * p + i] * X[k * p + j];
		   XtX[i * p + j] = sum;
	  }
	Newxz(XtY, p, double);
	for (i = 0; i < p; i++) {
	  double sum = 0.0;
	  for (k = 0; k < valid_n; k++) sum += X[k * p + i] * Y[k];
	  XtY[i] = sum;
	}
	Newx(aliased, p, bool);
	final_rank = sweep_matrix_ols(XtX, p, aliased);
	Newxz(beta, p, double);
	for (i = 0; i < p; i++) {
	  if (aliased[i]) { beta[i] = NAN; }
	  else {
		   double sum = 0.0;
		   for (j = 0; j < p; j++) if (!aliased[j]) sum += XtX[i * p + j] * XtY[j];
		   beta[i] = sum;
	  }
	}
	//
	// PHASE 6: Metrics & Cleanup
	//
	res_hv = newHV(); coef_hv = newHV(); fitted_hv = newHV(); resid_hv = newHV();
	summary_hv = newHV(); terms_av = newAV();

	df_res = (int)valid_n - final_rank;

	// rss / mss accumulated here — rse_sq computed AFTER this loop (not before)
	double sum_y = 0.0, mss = 0.0;
	for (i = 0; i < valid_n; i++) sum_y += Y[i];
	double mean_y = sum_y / (double)valid_n;

	for (i = 0; i < valid_n; i++) {
	  double y_hat = 0.0;
	  for (j = 0; j < p; j++) if (!aliased[j]) y_hat += X[i * p + j] * beta[j];
	  double res   = Y[i] - y_hat;
	  rss          += res * res;
	  double diff_m = has_intercept ? (y_hat - mean_y) : y_hat;
	  mss          += diff_m * diff_m;
	  hv_store(fitted_hv, valid_row_names[i], strlen(valid_row_names[i]), newSVnv(y_hat), 0);
	  hv_store(resid_hv,  valid_row_names[i], strlen(valid_row_names[i]), newSVnv(res),   0);
	  Safefree(valid_row_names[i]);
	}
	Safefree(valid_row_names);

	// Single, authoritative rse_sq calculation
	rse_sq = (df_res > 0) ? (rss / (double)df_res) : NAN;

	int df_int = has_intercept ? 1 : 0;
	double r_squared = 0.0, adj_r_squared = 0.0, f_stat = NAN, f_pvalue = NAN;
	int numdf = final_rank - df_int;

	if (final_rank != df_int && (mss + rss) > 0.0) {
	  r_squared     = mss / (mss + rss);
	  adj_r_squared = 1.0 - (1.0 - r_squared) * ((valid_n - df_int) / (double)df_res);
	  if (rse_sq > 0.0 && numdf > 0) {
		   f_stat   = (mss / (double)numdf) / rse_sq;
		   f_pvalue = 1.0 - pf(f_stat, (double)numdf, (double)df_res);
	  } else if (rse_sq == 0.0) {
		   f_stat   = INFINITY;
		   f_pvalue = 0.0;
	  }
	} else if (final_rank == df_int) {
	  r_squared = 0.0; adj_r_squared = 0.0;
	}
	for (j = 0; j < p; j++) {
	  hv_store(coef_hv, exp_terms[j], strlen(exp_terms[j]), newSVnv(beta[j]), 0);
	  av_push(terms_av, newSVpv(exp_terms[j], 0));
	  HV *restrict row_hv = newHV();
	  if (aliased[j]) {
		   hv_store(row_hv, "Estimate",   8,  newSVpv("NaN", 0), 0);
		   hv_store(row_hv, "Std. Error", 10, newSVpv("NaN", 0), 0);
		   hv_store(row_hv, "t value",    7,  newSVpv("NaN", 0), 0);
		   hv_store(row_hv, "Pr(>|t|)",   8,  newSVpv("NaN", 0), 0);
	  } else {
		   double se    = sqrt(rse_sq * XtX[j * p + j]);
		   double t_val = (se > 0.0) ? (beta[j] / se) : (INFINITY * (beta[j] >= 0.0 ? 1.0 : -1.0));
		   double p_val = get_t_pvalue(t_val, df_res, "two.sided");
		   hv_store(row_hv, "Estimate",   8,  newSVnv(beta[j]), 0);
		   hv_store(row_hv, "Std. Error", 10, newSVnv(se),      0);
		   hv_store(row_hv, "t value",    7,  newSVnv(t_val),   0);
		   hv_store(row_hv, "Pr(>|t|)",   8,  newSVnv(p_val),   0);
	  }
	  hv_store(summary_hv, exp_terms[j], strlen(exp_terms[j]), newRV_noinc((SV*)row_hv), 0);
	}
	hv_store(res_hv, "coefficients",  12, newRV_noinc((SV*)coef_hv),   0);
	hv_store(res_hv, "fitted.values", 13, newRV_noinc((SV*)fitted_hv), 0);
	hv_store(res_hv, "residuals",      9, newRV_noinc((SV*)resid_hv),  0);
	hv_store(res_hv, "df.residual",   11, newSVuv(df_res),             0);
	hv_store(res_hv, "rank",           4, newSVuv(final_rank),         0);
	hv_store(res_hv, "rss",            3, newSVnv(rss),                0);
	hv_store(res_hv, "summary",        7, newRV_noinc((SV*)summary_hv),0);
	hv_store(res_hv, "terms",          5, newRV_noinc((SV*)terms_av),  0);
	hv_store(res_hv, "r.squared",      9, newSVnv(r_squared),          0);
	hv_store(res_hv, "adj.r.squared", 13, newSVnv(adj_r_squared),      0);
	if (!isnan(f_stat)) {
	  AV *fstat_av = newAV();
	  av_push(fstat_av, newSVnv(f_stat));
	  av_push(fstat_av, newSViv(numdf));
	  av_push(fstat_av, newSViv(df_res));
	  hv_store(res_hv, "fstatistic", 10, newRV_noinc((SV*)fstat_av), 0);
	  hv_store(res_hv, "f.pvalue",    8, newSVnv(f_pvalue),          0);
	}

	// Deep Cleanup
	for (i = 0; i < num_terms; i++) Safefree(terms[i]); Safefree(terms);
	for (i = 0; i < num_uniq; i++) Safefree(uniq_terms[i]); Safefree(uniq_terms);
	for (j = 0; j < p_exp; j++) {
	  Safefree(exp_terms[j]);
	  if (is_dummy[j]) { Safefree(dummy_base[j]); Safefree(dummy_level[j]); }
	}
	Safefree(exp_terms); Safefree(is_dummy); Safefree(dummy_base); Safefree(dummy_level);
	Safefree(X); Safefree(Y); Safefree(XtX); Safefree(XtY);
	Safefree(beta); Safefree(aliased);
	if (row_hashes) Safefree(row_hashes);

	RETVAL = newRV_noinc((SV*)res_hv);
}
OUTPUT:
    RETVAL

void seq(from, to, by = 1.0)
	double from
	double to
	double by
PPCODE:
	{
		//Handle the zero 'by' case
		if (by == 0.0) {
			if (from == to) {
				 EXTEND(SP, 1);
				 mPUSHn(from);
				 XSRETURN(1);
			} else {
				 croak("invalid 'by' argument: cannot be zero when from != to");
			}
		}
		// Check for wrong direction / infinite loop
		if ((from < to && by < 0.0) || (from > to && by > 0.0)) {
			croak("wrong sign in 'by' argument");
		}
		/* * Calculate number of elements. 
		* R uses a small epsilon (like 1e-10) to avoid dropping the last 
		* element due to floating point inaccuracies.
		*/
		double n_elements_d = (to - from) / by;
		if (n_elements_d < 0.0) n_elements_d = 0.0;
		size_t n_elements = (n_elements_d + 1e-10) + 1;
		// Pre-extend the stack to avoid reallocating inside the loop
		EXTEND(SP, n_elements);
		for (size_t i = 0; i < n_elements; i++) {
			mPUSHn(from + i * by);
		}
		XSRETURN(n_elements);
	}

SV* rnorm(...)
	CODE:
	{
	  // Auto-seed the PRNG if the Perl script hasn't done so yet
	  AUTO_SEED_PRNG();

	  size_t n = 0;
	  double mean = 0.0, sd = 1.0;
	  int arg_start = 0;

	  // Check if the first argument is a simple integer (rnorm(33))
	  if (items > 0 && SvIOK(ST(0)) && (items == 1 || items % 2 != 0)) {
		   n = (unsigned int)SvUV(ST(0));
		   arg_start = 1; // Start parsing named arguments from the second element
	  }

	  // --- Parse remaining named arguments from the flat stack ---
	  if ((items - arg_start) % 2 != 0) {
		   croak("Usage: rnorm(n), rnorm(n => 10, mean => 0, sd => 1), or rnorm(33, mean => 0)");
	  }

	  for (int i = arg_start; i < items; i += 2) {
		   const char* restrict key = SvPV_nolen(ST(i));
		   SV* restrict val = ST(i + 1);

		   if      (strEQ(key, "n"))    n    = (unsigned int)SvUV(val);
		   else if (strEQ(key, "mean")) mean = SvNV(val);
		   else if (strEQ(key, "sd"))   sd   = SvNV(val);
		   else croak("rnorm: unknown argument '%s'", key);
	  }

	  if (sd < 0.0) croak("rnorm: standard deviation must be non-negative");

	  AV *restrict result_av = newAV();
	  if (n > 0) {
		   av_extend(result_av, n - 1);
		   // Generate random normals using the Box-Muller transform
		   for (size_t i = 0; i < n; ) {
		        double u, v, s;
		        do {
		            // Drand01() hooks into Perl's internal PRNG, respecting Perl's srand()
		            u = 2.0 * Drand01() - 1.0;
		            v = 2.0 * Drand01() - 1.0;
		            s = u * u + v * v;
		        } while (s >= 1.0 || s == 0.0);
		        
		        double mul = sqrt(-2.0 * log(s) / s);
		        // Box-Muller generates two independent values per iteration
		        av_store(result_av, i++, newSVnv(mean + sd * u * mul));
		        if (i < n) {
		            av_store(result_av, i++, newSVnv(mean + sd * v * mul));
		        }
		   }
	  }
	  RETVAL = newRV_noinc((SV*)result_av);
	}
	OUTPUT:
	RETVAL

SV* aov(data_sv, formula_sv = &PL_sv_undef)
	SV* data_sv
	SV* formula_sv
	CODE:
	{
	const char *restrict formula;
	SV *restrict orig_data_sv = data_sv;
	bool is_stacked = FALSE;

	// ========================================================================
	// PHASE 0: R-style stack() for missing formula
	// ========================================================================
	if (!formula_sv || !SvOK(formula_sv) || SvCUR(formula_sv) == 0) {
		 if (!SvROK(data_sv) || SvTYPE(SvRV(data_sv)) != SVt_PVHV) {
		     croak("aov: Without a formula, data must be a HashRef of ArrayRefs (mimicking R's named list)");
		 }
		 
		 is_stacked = TRUE;
		 HV *restrict input_hv = (HV*)SvRV(data_sv);
		 HV *restrict stacked_hv = newHV();
		 AV *restrict val_av = newAV();
		 AV *restrict grp_av = newAV();

		 hv_iterinit(input_hv);
		 HE *restrict entry;
		 while ((entry = hv_iternext(input_hv))) {
		     SV *restrict grp_name_sv = hv_iterkeysv(entry);
		     SV *restrict arr_ref = hv_iterval(input_hv, entry);
		     
		     if (SvROK(arr_ref) && SvTYPE(SvRV(arr_ref)) == SVt_PVAV) {
		         AV *restrict arr = (AV*)SvRV(arr_ref);
		         size_t len = av_len(arr);
		         for (size_t k = 0; k <= len; k++) {
		             SV **restrict v = av_fetch(arr, k, 0);
		             if (v && *v && SvOK(*v)) {
		                 av_push(val_av, newSVsv(*v));
		                 av_push(grp_av, newSVsv(grp_name_sv));
		             }
		         }
		     } else {
		         SvREFCNT_dec(val_av); SvREFCNT_dec(grp_av); SvREFCNT_dec(stacked_hv);
		         croak("aov: Hash values must be ArrayRefs when no formula is provided");
		     }
		 }
		 
		 hv_stores(stacked_hv, "Value", newRV_noinc((SV*)val_av));
		 hv_stores(stacked_hv, "Group", newRV_noinc((SV*)grp_av));

		 // sv_2mortal ensures memory is freed automatically on return or croak
		 data_sv = sv_2mortal(newRV_noinc((SV*)stacked_hv));
		 formula = "Value~Group";
	} else {
		 formula = SvPV_nolen(formula_sv);
	}

	char f_cpy[512];
	char *restrict src, *restrict dst, *restrict tilde, *restrict lhs, *restrict rhs, *restrict chunk;

	char **restrict terms = NULL, **restrict uniq_terms = NULL, **restrict exp_terms = NULL, **restrict parent_term = NULL;
	bool *restrict is_dummy = NULL, *is_interact = NULL;
	char **restrict dummy_base = NULL, **restrict dummy_level = NULL;
	int *restrict term_map = NULL, *restrict left_idx = NULL, *restrict right_idx = NULL;
	unsigned int term_cap = 64, exp_cap = 64, num_terms = 0, num_uniq = 0, p = 0, p_exp = 0;
	size_t n = 0, valid_n = 0, i, j;
	bool has_intercept = TRUE;

	char **restrict row_names = NULL;
	HV **restrict row_hashes = NULL;
	HV *restrict data_hoa = NULL;
	SV *restrict ref = NULL;
	HE *restrict entry;
	double **restrict X_mat = NULL;
	double *restrict Y = NULL;

	char **restrict term_base_level = NULL;  /* reference level for each uniq_term (NULL if not categorical) */
	if (!SvROK(data_sv)) croak("aov: data is required and must be a reference");

	//
	// PHASE 1: Data Extraction
	//
	ref = SvRV(data_sv);
	if (SvTYPE(ref) == SVt_PVHV) {
		HV*restrict hv = (HV*)ref;
		if (hv_iterinit(hv) == 0) croak("aov: Data hash is empty");
		entry = hv_iternext(hv);
		if (entry) {
			 SV*restrict val = hv_iterval(hv, entry);
			 if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
				  data_hoa = hv;
				  n = av_len((AV*)SvRV(val)) + 1;
				  Newx(row_names, n, char*);
				  for(i = 0; i < n; i++) { 
				      char buf[32]; snprintf(buf, sizeof(buf), "%lu", (unsigned long)(i+1));
				      row_names[i] = savepv(buf); 
				  }
			 } else if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
				  n = hv_iterinit(hv);
				  Newx(row_names, n, char*); Newx(row_hashes, n, HV*);
				  i = 0;
				  while ((entry = hv_iternext(hv))) {
				      I32 len;
				      row_names[i] = savepv(hv_iterkey(entry, &len));
				      row_hashes[i] = (HV*)SvRV(hv_iterval(hv, entry));
				      i++;
				  }
			 } else croak("aov: Hash values must be ArrayRefs (HoA) or HashRefs (HoH)");
		}
	} else if (SvTYPE(ref) == SVt_PVAV) {
		AV*restrict av = (AV*)ref;
		n = av_len(av) + 1;
		Newx(row_names, n, char*);
		Newx(row_hashes, n, HV*);
		for (i = 0; i < n; i++) {
			SV**restrict val = av_fetch(av, i, 0);
			if (val && SvROK(*val) && SvTYPE(SvRV(*val)) == SVt_PVHV) {
			  row_hashes[i] = (HV*)SvRV(*val);
			  char buf[32];
			  snprintf(buf, sizeof(buf), "%lu", (unsigned long)(i + 1));
			  row_names[i] = savepv(buf);
			} else {
			  for (size_t k = 0; k < i; k++) Safefree(row_names[k]);
			  Safefree(row_names); Safefree(row_hashes);
			  croak("aov: Array values must be HashRefs (AoH)");
			}
		}
	} else croak("aov: Data must be an Array or Hash reference");

	//
	// PHASE 2: Formula Parsing & `.` Expansion
	//
	src = (char*)formula; dst = f_cpy;
	while (*src && (dst - f_cpy < 511)) { if (!isspace(*src)) { *dst++ = *src; } src++; }
	*dst = '\0';

	tilde = strchr(f_cpy, '~');
	if (!tilde) {
		  for (i = 0; i < n; i++) Safefree(row_names[i]);
		  Safefree(row_names); if (row_hashes) Safefree(row_hashes);
		  croak("aov: invalid formula, missing '~'");
	}
	*tilde = '\0';
	lhs = f_cpy;
	rhs = tilde + 1;

	char *restrict p_idx;
	while ((p_idx = strstr(rhs, "-1")) != NULL) { has_intercept = FALSE; memmove(p_idx, p_idx + 2, strlen(p_idx + 2) + 1); }
	while ((p_idx = strstr(rhs, "+0")) != NULL) { has_intercept = FALSE; memmove(p_idx, p_idx + 2, strlen(p_idx + 2) + 1); }
	while ((p_idx = strstr(rhs, "0+")) != NULL) { has_intercept = FALSE; memmove(p_idx, p_idx + 2, strlen(p_idx + 2) + 1); }
	if (rhs[0] == '0' && rhs[1] == '\0')        { has_intercept = FALSE; rhs[0] = '\0'; }
	while ((p_idx = strstr(rhs, "+1")) != NULL) { memmove(p_idx, p_idx + 2, strlen(p_idx + 2) + 1); }
	if (rhs[0] == '1' && rhs[1] == '\0')        { rhs[0] = '\0'; } 
	else if (rhs[0] == '1' && rhs[1] == '+')    { memmove(rhs, rhs + 2, strlen(rhs + 2) + 1); }

	while ((p_idx = strstr(rhs, "++")) != NULL) memmove(p_idx, p_idx + 1, strlen(p_idx + 1) + 1);
	if (rhs[0] == '+') memmove(rhs, rhs + 1, strlen(rhs + 1) + 1);
	size_t len_rhs = strlen(rhs);
	if (len_rhs > 0 && rhs[len_rhs - 1] == '+') rhs[len_rhs - 1] = '\0';

	char rhs_expanded[2048] = "";
	size_t rhs_len = 0;
	chunk = strtok(rhs, "+");
	while (chunk != NULL) {
		if (strcmp(chunk, ".") == 0) {
			AV *restrict cols = get_all_columns(aTHX_ data_hoa, row_hashes, n);
			for (size_t c = 0; c <= av_len(cols); c++) {
			  SV **restrict col_sv = av_fetch(cols, c, 0);
			  if (col_sv && SvOK(*col_sv)) {
					const char *restrict col_name = SvPV_nolen(*col_sv);
					if (strcmp(col_name, lhs) != 0) {
						 size_t slen = strlen(col_name);
						 if (rhs_len + slen + 2 < sizeof(rhs_expanded)) {
						     if (rhs_len > 0) { strcat(rhs_expanded, "+"); rhs_len++; }
						     strcat(rhs_expanded, col_name);
						     rhs_len += slen;
						 }
					}
			  }
			}
			SvREFCNT_dec(cols);
		} else {
			 size_t slen = strlen(chunk);
			 if (rhs_len + slen + 2 < sizeof(rhs_expanded)) {
				  if (rhs_len > 0) { strcat(rhs_expanded, "+"); rhs_len++; }
				  strcat(rhs_expanded, chunk);
				  rhs_len += slen;
			 }
		}
		chunk = strtok(NULL, "+");
	}
	// Setup arrays safely
	Newx(terms, term_cap, char*);
	Newx(uniq_terms, term_cap, char*);
	Newx(exp_terms, exp_cap, char*); Newx(parent_term, exp_cap, char*);
	Newx(is_dummy, exp_cap, bool); Newx(is_interact, exp_cap, bool);
	Newx(dummy_base, exp_cap, char*); Newx(dummy_level, exp_cap, char*);
	Newx(term_map, exp_cap, int); Newx(left_idx, exp_cap, int); Newx(right_idx, exp_cap, int);
	if (has_intercept) { terms[num_terms++] = savepv("Intercept"); }
	if (strlen(rhs_expanded) > 0) {
		chunk = strtok(rhs_expanded, "+");
		while (chunk != NULL) {
			 if (num_terms >= term_cap - 3) {
				  term_cap *= 2;
				  Renew(terms, term_cap, char*); Renew(uniq_terms, term_cap, char*);
			 }
			 char *restrict star = strchr(chunk, '*');
			 if (star) {
				  *star = '\0';
				  char *restrict left = chunk;
				  char *restrict right = star + 1;
				  char *restrict c_l = strchr(left, '^');
				  if (c_l && strncmp(left, "I(", 2) != 0) *c_l = '\0';
				  char *restrict c_r = strchr(right, '^'); if (c_r && strncmp(right, "I(", 2) != 0) *c_r = '\0';
				  terms[num_terms++] = savepv(left);
				  terms[num_terms++] = savepv(right);
				  size_t inter_len = strlen(left) + strlen(right) + 2;
				  terms[num_terms] = (char*)safemalloc(inter_len);
				  snprintf(terms[num_terms++], inter_len, "%s:%s", left, right);
			 } else {
				  char *restrict c_chunk = strchr(chunk, '^'); 
				  if (c_chunk && strncmp(chunk, "I(", 2) != 0) *c_chunk = '\0';
				  terms[num_terms++] = savepv(chunk);
			 }
			 chunk = strtok(NULL, "+");
		}
	}

	for (i = 0; i < num_terms; i++) {
		bool found = FALSE;
		for (size_t k = 0; k < num_uniq; k++) {
			if (strcmp(terms[i], uniq_terms[k]) == 0) { found = TRUE; break; }
		}
		if (!found) uniq_terms[num_uniq++] = savepv(terms[i]);
	}
	p = num_uniq;

	Newxz(term_base_level, num_uniq, char*);

	/* PHASE 3: Categorical & Interaction Expansion */
	for (j = 0; j < p; j++) {
		if (p_exp + 64 >= exp_cap) {
			exp_cap *= 2;
			Renew(exp_terms, exp_cap, char*); Renew(parent_term, exp_cap, char*);
			Renew(is_dummy, exp_cap, bool); Renew(is_interact, exp_cap, bool);
			Renew(dummy_base, exp_cap, char*); Renew(dummy_level, exp_cap, char*);
			Renew(term_map, exp_cap, int); Renew(left_idx, exp_cap, int); Renew(right_idx, exp_cap, int);
		}

		if (strcmp(uniq_terms[j], "Intercept") == 0) {
			exp_terms[p_exp] = savepv("Intercept");
			parent_term[p_exp] = savepv("Intercept");
			is_dummy[p_exp] = FALSE; is_interact[p_exp] = FALSE;
			term_map[p_exp] = j;
			p_exp++;
			continue;
		}

		char *restrict colon = strchr(uniq_terms[j], ':');
		if (colon) {
			char left[256], right[256];
			strncpy(left, uniq_terms[j], colon - uniq_terms[j]);
			left[colon - uniq_terms[j]] = '\0';
			strcpy(right, colon + 1);

			int *restrict l_indices = (int*)safemalloc(p_exp * sizeof(int)); int l_count = 0;
			int *restrict r_indices = (int*)safemalloc(p_exp * sizeof(int)); int r_count = 0;
			for (size_t e = 0; e < p_exp; e++) {
				if (strcmp(parent_term[e], left) == 0) l_indices[l_count++] = e;
				if (strcmp(parent_term[e], right) == 0) r_indices[r_count++] = e;
			}

			if (l_count == 0 || r_count == 0) {
				Safefree(l_indices); Safefree(r_indices);
				croak("aov: Interaction term '%s' requires its main effects to be explicitly included in the formula", uniq_terms[j]);
			} else {
				for (unsigned int li = 0; li < l_count; li++) {
					 for (unsigned int ri = 0; ri < r_count; ri++) {
						  if (p_exp >= exp_cap) {
						      exp_cap *= 2;
						      Renew(exp_terms, exp_cap, char*); Renew(parent_term, exp_cap, char*);
						      Renew(is_dummy, exp_cap, bool); Renew(is_interact, exp_cap, bool);
						      Renew(dummy_base, exp_cap, char*); Renew(dummy_level, exp_cap, char*);
						      Renew(term_map, exp_cap, int); Renew(left_idx, exp_cap, int); Renew(right_idx, exp_cap, int);
						  }
						  size_t t_len = strlen(exp_terms[l_indices[li]]) + strlen(exp_terms[r_indices[ri]]) + 2;
						  exp_terms[p_exp] = (char*)safemalloc(t_len);
						  snprintf(exp_terms[p_exp], t_len, "%s:%s", exp_terms[l_indices[li]], exp_terms[r_indices[ri]]);
						  parent_term[p_exp] = savepv(uniq_terms[j]);
						  is_dummy[p_exp] = FALSE; is_interact[p_exp] = TRUE;
						  left_idx[p_exp] = l_indices[li];
						  right_idx[p_exp] = r_indices[ri];
						  term_map[p_exp] = j;
						  p_exp++;
					 }
				}
			}
			Safefree(l_indices); Safefree(r_indices);
		} else {
			if (is_column_categorical(aTHX_ data_hoa, row_hashes, n, uniq_terms[j])) {
				char **restrict levels = NULL;
				unsigned int num_levels = 0, levels_cap = 8;
				Newx(levels, levels_cap, char*);
				for (i = 0; i < n; i++) {
					 char*restrict str_val = get_data_string_alloc(aTHX_ data_hoa, row_hashes, i, uniq_terms[j]);
					 if (str_val) {
						  bool found = FALSE;
						  for (size_t l = 0; l < num_levels; l++) {
						      if (strcmp(levels[l], str_val) == 0) { found = TRUE; break; }
						  }
						  if (!found) {
						      if (num_levels >= levels_cap) { levels_cap *= 2; Renew(levels, levels_cap, char*); }
						      levels[num_levels++] = savepv(str_val);
						  }
						  Safefree(str_val);
					 }
				}
				
				if (num_levels > 0) {
					 for (size_t l1 = 0; l1 < num_levels - 1; l1++) {
						  for (size_t l2 = l1 + 1; l2 < num_levels; l2++) {
						      if (strcmp(levels[l1], levels[l2]) > 0) {
						          char *tmp = levels[l1]; levels[l1] = levels[l2]; levels[l2] = tmp;
						      }
						  }
					 }

					 term_base_level[j] = savepv(levels[0]);

					 for (size_t l = 1; l < num_levels; l++) {
						  if (p_exp >= exp_cap) {
						      exp_cap *= 2;
						      Renew(exp_terms, exp_cap, char*); Renew(parent_term, exp_cap, char*);
						      Renew(is_dummy, exp_cap, bool); Renew(is_interact, exp_cap, bool);
						      Renew(dummy_base, exp_cap, char*); Renew(dummy_level, exp_cap, char*);
						      Renew(term_map, exp_cap, int); Renew(left_idx, exp_cap, int); Renew(right_idx, exp_cap, int);
						  }
						  size_t t_len = strlen(uniq_terms[j]) + strlen(levels[l]) + 1;
						  exp_terms[p_exp] = (char*)safemalloc(t_len);
						  snprintf(exp_terms[p_exp], t_len, "%s%s", uniq_terms[j], levels[l]);
						  parent_term[p_exp] = savepv(uniq_terms[j]);
						  is_dummy[p_exp] = TRUE; is_interact[p_exp] = FALSE;
						  dummy_base[p_exp] = savepv(uniq_terms[j]);
						  dummy_level[p_exp] = savepv(levels[l]);
						  term_map[p_exp] = j;
						  p_exp++;
					 }
					 for (size_t l = 0; l < num_levels; l++) Safefree(levels[l]);
					 Safefree(levels);
				} else {
					 Safefree(levels);
					 exp_terms[p_exp] = savepv(uniq_terms[j]);
					 parent_term[p_exp] = savepv(uniq_terms[j]);
					 is_dummy[p_exp] = FALSE; is_interact[p_exp] = FALSE;
					 term_map[p_exp] = j;
					 p_exp++;
				}
			} else {
				exp_terms[p_exp] = savepv(uniq_terms[j]);
				parent_term[p_exp] = savepv(uniq_terms[j]);
				is_dummy[p_exp] = FALSE; is_interact[p_exp] = FALSE;
				term_map[p_exp] = j;
				p_exp++;
			}
		}
	}
	X_mat = (double**)safemalloc(n * sizeof(double*));
	for(i = 0; i < n; i++) X_mat[i] = (double*)safemalloc(p_exp * sizeof(double));
	Newx(Y, n, double);

	/* PHASE 4: Matrix Construction & Listwise Deletion */
	for (i = 0; i < n; i++) {
		double y_val = evaluate_term(aTHX_ data_hoa, row_hashes, i, lhs);
		if (isnan(y_val)) { Safefree(row_names[i]); continue; }
		bool row_ok = TRUE;
		double *restrict row_x = (double*)safemalloc(p_exp * sizeof(double));
		for (j = 0; j < p_exp; j++) {
			  if (strcmp(exp_terms[j], "Intercept") == 0) {
				   row_x[j] = 1.0;
			  } else if (is_interact[j]) {
				   row_x[j] = row_x[left_idx[j]] * row_x[right_idx[j]];
			  } else if (is_dummy[j]) {
				   char*restrict str_val = get_data_string_alloc(aTHX_ data_hoa, row_hashes, i, dummy_base[j]);
				   if (str_val) {
				       row_x[j] = (strcmp(str_val, dummy_level[j]) == 0) ? 1.0 : 0.0;
				       Safefree(str_val);
				   } else { row_ok = FALSE; break; }
			  } else {
				   row_x[j] = evaluate_term(aTHX_ data_hoa, row_hashes, i, parent_term[j]);
				   if (isnan(row_x[j])) { row_ok = FALSE; break; }
			  }
		}
		if (!row_ok) { Safefree(row_names[i]); Safefree(row_x); continue; }
		Y[valid_n] = y_val;
		for (j = 0; j < p_exp; j++) X_mat[valid_n][j] = row_x[j];
		valid_n++;
		Safefree(row_x);
		Safefree(row_names[i]);
	}
	Safefree(row_names);
	if (valid_n <= p_exp) {
		// Full Clean Up 
		for (i = 0; i < num_terms; i++) Safefree(terms[i]); Safefree(terms);
		for (i = 0; i < num_uniq; i++) Safefree(uniq_terms[i]); Safefree(uniq_terms);
		for (j = 0; j < p_exp; j++) {
			 Safefree(exp_terms[j]); Safefree(parent_term[j]);
			 if (is_dummy[j]) { Safefree(dummy_base[j]); Safefree(dummy_level[j]); }
		}
		Safefree(exp_terms); Safefree(parent_term); 
		Safefree(is_dummy); Safefree(is_interact); 
		Safefree(dummy_base); Safefree(dummy_level);
		Safefree(term_map); Safefree(left_idx); Safefree(right_idx);
		for(i = 0; i < n; i++) Safefree(X_mat[i]);
		Safefree(X_mat); Safefree(Y);
		if (row_hashes) Safefree(row_hashes);
		for (i = 0; i < num_uniq; i++) { if (term_base_level[i]) Safefree(term_base_level[i]); }
		Safefree(term_base_level);
		croak("aov: 0 degrees of freedom (too many NAs or parameters > observations)");
	}
	/* PHASE 5: Math & Output Formatting */
	bool *restrict aliased_qr = (bool*)safemalloc(p_exp * sizeof(bool));
	size_t *restrict rank_map = (size_t*)safemalloc(p_exp * sizeof(size_t));
	apply_householder_aov(X_mat, Y, valid_n, p_exp, aliased_qr, rank_map);
	double *restrict term_ss;
	int *restrict term_df;
	Newxz(term_ss, num_uniq, double);
	Newxz(term_df, num_uniq, int);
	for (i = 0; i < p_exp; i++) {
		if (strcmp(exp_terms[i], "Intercept") == 0) continue; 
		if (aliased_qr[i]) continue;
		int t_idx = term_map[i];
		size_t r_k = rank_map[i];
		term_ss[t_idx] += Y[r_k] * Y[r_k];
		term_df[t_idx] += 1;
	}
	int rank = 0;
	for (i = 0; i < p_exp; i++) {
		  if (!aliased_qr[i]) rank++;
	}
	double rss_prev = 0.0;
	for (i = rank; i < valid_n; i++) {
		  rss_prev += Y[i] * Y[i];
	}
	int res_df = valid_n - rank;
	double ms_res = (res_df > 0) ? rss_prev / res_df : 0.0;
	HV*restrict ret_hash = newHV();
	for (j = 0; j < num_uniq; j++) {
		  if (strcmp(uniq_terms[j], "Intercept") == 0) continue;
		  HV*restrict term_stats = newHV();
		  double ss = term_ss[j];
		  int df = term_df[j];
		  double ms = (df > 0) ? ss / df : 0.0;

		  hv_stores(term_stats, "Df", newSViv(df));
		  hv_stores(term_stats, "Sum Sq", newSVnv(ss));
		  hv_stores(term_stats, "Mean Sq", newSVnv(ms));
		  if (ms_res > 0.0 && df > 0) {
		        double f_val = ms / ms_res;
		        hv_stores(term_stats, "F value", newSVnv(f_val));
		        hv_stores(term_stats, "Pr(>F)", newSVnv(1.0 - pf(f_val, (double)df, (double)res_df)));
		  } else {
		        hv_stores(term_stats, "F value", newSVnv(NAN));
		        hv_stores(term_stats, "Pr(>F)", newSVnv(NAN));
		  }
		  hv_store(ret_hash, uniq_terms[j], strlen(uniq_terms[j]), newRV_noinc((SV*)term_stats), 0);
	}
	HV*restrict res_stats = newHV();
	hv_stores(res_stats, "Df", newSViv(res_df));
	hv_stores(res_stats, "Sum Sq", newSVnv(rss_prev));
	hv_stores(res_stats, "Mean Sq", newSVnv(ms_res));
	hv_stores(ret_hash, "Residuals", newRV_noinc((SV*)res_stats));
	{
		  HV *restrict tgt_hoa = data_hoa;
		  HV **restrict tgt_row_hashes = row_hashes;
		  size_t tgt_n = n;
		  // Route evaluation to the original unstacked HoA when a formula was implied
		  if (is_stacked) {
		      tgt_hoa = (HV*)SvRV(orig_data_sv);
		      tgt_row_hashes = NULL;
		      hv_iterinit(tgt_hoa);
		      HE *restrict e = hv_iternext(tgt_hoa);
		      if (e) {
		          SV *val = hv_iterval(tgt_hoa, e);
		          if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
		              tgt_n = av_len((AV*)SvRV(val)) + 1;
		          }
		      }
		  }
		  AV *restrict all_cols = get_all_columns(aTHX_ tgt_hoa, tgt_row_hashes, tgt_n);
		  HV *restrict mean_hv  = newHV();
		  HV *restrict size_hv  = newHV();
		  for (size_t c = 0; c <= (size_t)av_len(all_cols); c++) {
		      SV **restrict col_sv = av_fetch(all_cols, c, 0);
		      if (!col_sv || !SvOK(*col_sv)) continue;
		      const char *restrict col_name = SvPV_nolen(*col_sv);
		      
		      double col_sum = 0.0;
		      IV      col_count = 0;
		      for (i = 0; i < tgt_n; i++) {
		          double val = evaluate_term(aTHX_ tgt_hoa, tgt_row_hashes, i, col_name);
		          if (!isnan(val)) { col_sum += val; col_count++; }
		      }
		      
		      double col_mean = (col_count > 0) ? col_sum / col_count : NAN;
		      hv_store(mean_hv, col_name, strlen(col_name), newSVnv(col_mean), 0);
		      hv_store(size_hv, col_name, strlen(col_name), newSViv(col_count), 0);
		  }
		  SvREFCNT_dec(all_cols);
		  HV *restrict gs_hv = newHV();
		  hv_stores(gs_hv, "mean", newRV_noinc((SV*)mean_hv));
		  hv_stores(gs_hv, "size", newRV_noinc((SV*)size_hv));
		  hv_stores(ret_hash, "group_stats", newRV_noinc((SV*)gs_hv));
	}
	/* Deep Cleanup */
	for (i = 0; i < num_terms; i++) Safefree(terms[i]); Safefree(terms);
	for (i = 0; i < num_uniq; i++) Safefree(uniq_terms[i]); Safefree(uniq_terms);
	for (j = 0; j < p_exp; j++) {
		  Safefree(exp_terms[j]); Safefree(parent_term[j]);
		  if (is_dummy[j]) { Safefree(dummy_base[j]); Safefree(dummy_level[j]); }
	}
	Safefree(exp_terms); Safefree(parent_term); 
	Safefree(is_dummy); Safefree(is_interact); 
	Safefree(dummy_base); Safefree(dummy_level);
	Safefree(term_map); Safefree(left_idx); Safefree(right_idx);
	Safefree(term_ss); Safefree(term_df);
	for (i = 0; i < n; i++) Safefree(X_mat[i]);
	Safefree(X_mat); Safefree(Y);
	Safefree(aliased_qr); Safefree(rank_map);
	for (i = 0; i < num_uniq; i++) { if (term_base_level[i]) Safefree(term_base_level[i]); }
	Safefree(term_base_level);
	if (row_hashes) Safefree(row_hashes);
	RETVAL = newRV_noinc((SV*)ret_hash);
	}
OUTPUT:
    RETVAL

PROTOTYPES: DISABLE

SV* fisher_test(...)
CODE:
{
	if (items < 1) croak("fisher_test requires at least a data reference");

	SV*restrict data_ref = ST(0);
	double conf_level = 0.95;
	const char*restrict alternative = "two.sided";

	// Parse named arguments
	for (unsigned short int i = 1; i < items; i += 2) {
		if (i + 1 >= items) croak("fisher_test: odd number of arguments");
		const char*restrict key = SvPV_nolen(ST(i));
		SV*restrict val = ST(i + 1);
		if (strEQ(key, "conf_level") || strEQ(key, "conf.level")) {
			conf_level = SvNV(val);
		} else if (strEQ(key, "alternative")) {
			alternative = SvPV_nolen(val);
		}
	}

	if (!SvROK(data_ref)) croak("fisher_test requires a reference to an Array or Hash");
	SV*restrict deref = SvRV(data_ref);
	size_t a = 0, b = 0, c = 0, d = 0;
	// Extract Data
	if (SvTYPE(deref) == SVt_PVAV) {
		AV*restrict outer = (AV*)deref;
		if (av_len(outer) != 1) croak("Outer array must have exactly 2 rows");
		SV**restrict row1_ptr = av_fetch(outer, 0, 0);
		SV**restrict row2_ptr = av_fetch(outer, 1, 0);
		if (row1_ptr && row2_ptr && SvROK(*row1_ptr) && SvROK(*row2_ptr)) {
			AV*restrict row1 = (AV*)SvRV(*row1_ptr);
			AV*restrict row2 = (AV*)SvRV(*row2_ptr);
			SV**restrict a_ptr = av_fetch(row1, 0, 0);
			SV**restrict b_ptr = av_fetch(row1, 1, 0);
			SV**restrict c_ptr = av_fetch(row2, 0, 0);
			SV**restrict d_ptr = av_fetch(row2, 1, 0);
			a = (a_ptr && SvOK(*a_ptr)) ? SvIV(*a_ptr) : 0;
			b = (b_ptr && SvOK(*b_ptr)) ? SvIV(*b_ptr) : 0;
			c = (c_ptr && SvOK(*c_ptr)) ? SvIV(*c_ptr) : 0;
			d = (d_ptr && SvOK(*d_ptr)) ? SvIV(*d_ptr) : 0;
		} else {
		  croak("Invalid 2D Array structure");
		}
	} else if (SvTYPE(deref) == SVt_PVHV) {
		// Fixed 2D Hash Logic: Sort keys lexically to enforce structured rows/columns
		HV*restrict outer = (HV*)deref;
		if (hv_iterinit(outer) != 2) croak("Outer hash must have exactly 2 keys");
		HE*restrict he1 = hv_iternext(outer);
		HE*restrict he2 = hv_iternext(outer);
		if (!he1 || !he2) croak("Invalid outer hash");
		const char*restrict k1 = SvPV_nolen(hv_iterkeysv(he1));
		const char*restrict k2 = SvPV_nolen(hv_iterkeysv(he2));
		HE*restrict row1_he = (strcmp(k1, k2) < 0) ? he1 : he2;
		HE*restrict row2_he = (strcmp(k1, k2) < 0) ? he2 : he1;
		SV*restrict row1_sv = hv_iterval(outer, row1_he);
		SV*restrict row2_sv = hv_iterval(outer, row2_he);
		if (!SvROK(row1_sv) || SvTYPE(SvRV(row1_sv)) != SVt_PVHV ||
			!SvROK(row2_sv) || SvTYPE(SvRV(row2_sv)) != SVt_PVHV) {
			croak("Inner elements must be hashes");
		}
		HV*restrict in1 = (HV*)SvRV(row1_sv);
		HV*restrict in2 = (HV*)SvRV(row2_sv);
		if (hv_iterinit(in1) != 2 || hv_iterinit(in2) != 2) croak("Inner hashes must have exactly 2 keys");
		HE*restrict in1_he1 = hv_iternext(in1);
		HE*restrict in1_he2 = hv_iternext(in1);
		const char*restrict in1_k1 = SvPV_nolen(hv_iterkeysv(in1_he1));
		const char*restrict in1_k2 = SvPV_nolen(hv_iterkeysv(in1_he2));
		HE*restrict in1_c1 = (strcmp(in1_k1, in1_k2) < 0) ? in1_he1 : in1_he2;
		HE*restrict in1_c2 = (strcmp(in1_k1, in1_k2) < 0) ? in1_he2 : in1_he1;
		HE*restrict in2_he1 = hv_iternext(in2);
		HE*restrict in2_he2 = hv_iternext(in2);
		const char*restrict in2_k1 = SvPV_nolen(hv_iterkeysv(in2_he1));
		const char*restrict in2_k2 = SvPV_nolen(hv_iterkeysv(in2_he2));
		HE*restrict in2_c1 = (strcmp(in2_k1, in2_k2) < 0) ? in2_he1 : in2_he2;
		HE*restrict in2_c2 = (strcmp(in2_k1, in2_k2) < 0) ? in2_he2 : in2_he1;
		a = (hv_iterval(in1, in1_c1) && SvOK(hv_iterval(in1, in1_c1))) ? SvIV(hv_iterval(in1, in1_c1)) : 0;
		b = (hv_iterval(in1, in1_c2) && SvOK(hv_iterval(in1, in1_c2))) ? SvIV(hv_iterval(in1, in1_c2)) : 0;
		c = (hv_iterval(in2, in2_c1) && SvOK(hv_iterval(in2, in2_c1))) ? SvIV(hv_iterval(in2, in2_c1)) : 0;
		d = (hv_iterval(in2, in2_c2) && SvOK(hv_iterval(in2, in2_c2))) ? SvIV(hv_iterval(in2, in2_c2)) : 0;
	} else {
	  croak("Input must be a 2D Array or 2D Hash");
	}

	// Perform Calculations via Helpers
	double p_val = exact_p_value(a, b, c, d, alternative);
	double mle_or, ci_low, ci_high;
	calculate_exact_stats(a, b, c, d, conf_level, alternative, &mle_or, &ci_low, &ci_high);

	// Construct the Return HashRef purely in C
	HV*restrict ret_hash = newHV();
	hv_stores(ret_hash, "method", newSVpv("Fisher's Exact Test for Count Data", 0));
	hv_stores(ret_hash, "alternative", newSVpv(alternative, 0));
	AV*restrict ci_array = newAV();
	av_push(ci_array, newSVnv(ci_low));
	av_push(ci_array, newSVnv(ci_high));
	hv_stores(ret_hash, "conf_int", newRV_noinc((SV*)ci_array));
	HV*restrict est_hash = newHV();
	hv_stores(ret_hash, "estimate", newRV_noinc((SV*)est_hash));
	hv_stores(est_hash, "odds ratio", newSVnv(mle_or));
	hv_stores(ret_hash, "p_value", newSVnv(p_val));
	// Return the HashRef
	RETVAL = newRV_noinc((SV*)ret_hash);
}
OUTPUT:
  RETVAL

SV* power_t_test(...)
CODE:
{
	SV*restrict sv_n = NULL;
	SV*restrict sv_delta = NULL;
	SV*restrict sv_sd = NULL;
	SV*restrict sv_sig_level = NULL;
	SV*restrict sv_power = NULL;

	const char* restrict type = "two.sample";
	const char* restrict alternative = "two.sided";
	bool strict = FALSE;
	double tol = pow(2.2204460492503131e-16, 0.25); 

	if (items % 2 != 0) croak("Usage: power_t_test(n => 30, delta => 0.5, sd => 1.0, ...)");
	for (unsigned short int i = 0; i < items; i += 2) {
	  const char* restrict key = SvPV_nolen(ST(i));
	  SV* restrict val = ST(i+1);

	  if      (strEQ(key, "n"))           sv_n = val;
	  else if (strEQ(key, "delta"))       sv_delta = val;
	  else if (strEQ(key, "sd"))          sv_sd = val;
	  else if (strEQ(key, "sig.level") || strEQ(key, "sig_level")) sv_sig_level = val;
	  else if (strEQ(key, "power"))       sv_power = val;
	  else if (strEQ(key, "type"))        type = SvPV_nolen(val);
	  else if (strEQ(key, "alternative")) alternative = SvPV_nolen(val);
	  else if (strEQ(key, "strict"))      strict = SvTRUE(val);
	  else if (strEQ(key, "tol"))         tol = SvNV(val);
	  else croak("power_t_test: unknown argument '%s'", key);
	}

	bool is_null_n = (!sv_n || !SvOK(sv_n));
	bool is_null_delta = (!sv_delta || !SvOK(sv_delta));
	bool is_null_power = (!sv_power || !SvOK(sv_power));
	bool is_null_sd = (sv_sd && !SvOK(sv_sd)); 
	bool is_null_sig_level = (sv_sig_level && !SvOK(sv_sig_level));

	unsigned int missing_count = 0;
	if (is_null_n) missing_count++;
	if (is_null_delta) missing_count++;
	if (is_null_power) missing_count++;
	if (is_null_sd) missing_count++;
	if (is_null_sig_level) missing_count++;

	if (missing_count != 1) {
	  croak("power_t_test: exactly one of 'n', 'delta', 'sd', 'power', and 'sig_level' must be undef/NULL");
	}

	double n = is_null_n ? 0.0 : SvNV(sv_n);
	double delta = is_null_delta ? 0.0 : SvNV(sv_delta);
	double sd = (!sv_sd || is_null_sd) ? 1.0 : SvNV(sv_sd);
	double sig_level = (!sv_sig_level || is_null_sig_level) ? 0.05 : SvNV(sv_sig_level);
	double power = is_null_power ? 0.0 : SvNV(sv_power);
	short int tsample = (strEQ(type, "one.sample") || strEQ(type, "paired")) ? 1 : 2;
	short int tside = (strEQ(alternative, "one.sided") || strEQ(alternative, "greater") || strEQ(alternative, "less")) ? 1 : 2;
	if (tside == 2 && !is_null_delta) delta = fabs(delta);
	if (is_null_power) {
	  power = p_body(n, delta, sd, sig_level, tsample, tside, strict);
	} else if (is_null_n) {
		double low = 2.0, high = 1e7;
		while (p_body(high, delta, sd, sig_level, tsample, tside, strict) < power && high < 1e12) high *= 2.0;
		while (high - low > tol) {
			double mid = low + (high - low) / 2.0;
			if (p_body(mid, delta, sd, sig_level, tsample, tside, strict) < power) low = mid;
			else high = mid;
		}
		n = low + (high - low) / 2.0;
	} else if (is_null_sd) {
	  double low = delta * 1e-7, high = delta * 1e7;
	  while (high - low > tol) {
		   double mid = low + (high - low) / 2.0;
		   if (p_body(n, delta, mid, sig_level, tsample, tside, strict) > power) low = mid;
		   else high = mid;
	  }
	  sd = low + (high - low) / 2.0;
	} else if (is_null_delta) {
	  double low = sd * 1e-7, high = sd * 1e7;
	  while (p_body(n, high, sd, sig_level, tsample, tside, strict) < power && high < 1e12) high *= 2.0;
	  while (high - low > tol) {
		   double mid = low + (high - low) / 2.0;
		   if (p_body(n, mid, sd, sig_level, tsample, tside, strict) < power) low = mid;
		   else high = mid;
	  }
	  delta = low + (high - low) / 2.0;
	} else if (is_null_sig_level) {
	  double low = 1e-10, high = 1.0 - 1e-10;
	  while (high - low > tol) {
		   double mid = low + (high - low) / 2.0;
		   if (p_body(n, delta, sd, mid, tsample, tside, strict) < power) low = mid;
		   else high = mid;
	  }
	  sig_level = low + (high - low) / 2.0;
	}
	HV*restrict ret = newHV();
	hv_stores(ret, "n", newSVnv(n));
	hv_stores(ret, "delta", newSVnv(delta));
	hv_stores(ret, "sd", newSVnv(sd));
	hv_stores(ret, "sig.level", newSVnv(sig_level));
	hv_stores(ret, "power", newSVnv(power));
	hv_stores(ret, "alternative", newSVpv(alternative, 0));
	const char*restrict m_str = (tsample == 1) ? (strEQ(type, "paired") ? "Paired t test power calculation" : "One-sample t test power calculation") : "Two-sample t test power calculation";
	hv_stores(ret, "method", newSVpv(m_str, 0));
	const char*restrict n_str = (tsample == 2) ? "n is number in *each* group" : (strEQ(type, "paired") ? "n is number of *pairs*, sd is std.dev. of *differences* within pairs" : "");
	if (n_str[0] != '\0') hv_stores(ret, "note", newSVpv(n_str, 0));
	RETVAL = newRV_noinc((SV*)ret);
}
OUTPUT:
	RETVAL

SV* kruskal_test(...)
CODE:
{
	SV *restrict x_sv = NULL, *restrict g_sv = NULL, *restrict h_sv = NULL;
	unsigned int arg_idx = 0;
	// 1. Shift positional arguments
	//    Accept either: (arrayref, arrayref) or (hashref)
	if (arg_idx < items && SvROK(ST(arg_idx))) {
		svtype t = SvTYPE(SvRV(ST(arg_idx)));
		if (t == SVt_PVAV) {
			x_sv = ST(arg_idx++);
		} else if (t == SVt_PVHV) {
			h_sv = ST(arg_idx++);          /* hash-of-arrays shortcut */
		}
	}
	if (!h_sv && arg_idx < items
		     && SvROK(ST(arg_idx))
		     && SvTYPE(SvRV(ST(arg_idx))) == SVt_PVAV) {
	  g_sv = ST(arg_idx++);
	}
	// 2. Parse named arguments (fallback)
	for (; arg_idx < items; arg_idx += 2) {
	  const char *restrict key = SvPV_nolen(ST(arg_idx));
	  SV         *restrict val = ST(arg_idx + 1);
	  if      (strEQ(key, "x")) x_sv = val;
	  else if (strEQ(key, "g")) g_sv = val;
	  else if (strEQ(key, "h")) h_sv = val;
	  else croak("kruskal_test: unknown argument '%s'", key);
	}
	// 3. Mutual-exclusion guard
	if (h_sv && (x_sv || g_sv))
	  croak("kruskal_test: cannot mix 'h' (hash-of-arrays) with 'x'/'g' inputs");

	/* ------------------------------------------------------------------ */
	/* Shared state filled by whichever input branch runs                 */
	/* ------------------------------------------------------------------ */
	RankInfo *restrict ri = NULL;
	char **restrict group_names = NULL; /* Track names to build group_stats */
	size_t valid_n = 0, k       = 0;
	/* 4a. Hash-of-arrays input path                                      */
	/*     my %x = ( group1 => [...], group2 => [...], ... )              */
	/* ------------------------------------------------------------------ */
	if (h_sv) {
		if (!SvROK(h_sv) || SvTYPE(SvRV(h_sv)) != SVt_PVHV)
			croak("kruskal_test: 'h' must be a HASH reference");
		HV *restrict h_hv = (HV*)SvRV(h_sv);
		// First pass – validate values and tally total elements
		size_t total = 0;
		hv_iterinit(h_hv);
		HE *restrict he;
		while ((he = hv_iternext(h_hv))) {
			SV *restrict val = HeVAL(he);
			if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVAV)
				croak("kruskal_test: every value in 'h' must be an ARRAY reference");
			total += (size_t)(av_len((AV*)SvRV(val)) + 1);
		}
		if (total < 2) croak("not enough observations");
		ri = (RankInfo *)safemalloc(total * sizeof(RankInfo));
		size_t num_keys = HvKEYS(h_hv);
		group_names = (char **)safecalloc(num_keys, sizeof(char*));
		/* 2nd pass – fill ri[], assigning one group_id per hash key */
		size_t group_id = 0;
		hv_iterinit(h_hv);
		while ((he = hv_iternext(h_hv))) {
			STRLEN klen;
			const char *restrict key_str = HePV(he, klen);
			group_names[group_id] = savepvn(key_str, klen); // Save string key
			AV *restrict av  = (AV*)SvRV(HeVAL(he));
			size_t       n_g = (size_t)(av_len(av) + 1);
			for (size_t i = 0; i < n_g; i++) {
				 SV **restrict el = av_fetch(av, i, 0);
				 if (el && SvOK(*el) && looks_like_number(*el)) {
				     ri[valid_n].val = SvNV(*el);
				     ri[valid_n].idx = group_id;   /* group identity */
				     valid_n++;
				 }
			}
			group_id++;
		}
		k = group_id;   /* number of unique groups = number of hash keys */
	/* 4b. Original x / g array-pair input path */
	} else {
		if (!x_sv || !SvROK(x_sv) || SvTYPE(SvRV(x_sv)) != SVt_PVAV)
			croak("kruskal_test: 'x' is a required argument and must be an ARRAY reference");
		if (!g_sv || !SvROK(g_sv) || SvTYPE(SvRV(g_sv)) != SVt_PVAV)
			croak("kruskal_test: 'g' is a required argument and must be an ARRAY reference");

		AV *restrict x_av = (AV*)SvRV(x_sv);
		AV *restrict g_av = (AV*)SvRV(g_sv);
		size_t nx = (size_t)(av_len(x_av) + 1);
		size_t ng = (size_t)(av_len(g_av) + 1);
		if (nx != ng) croak("kruskal_test: 'x' and 'g' must have the same length");
		if (nx < 2)   croak("not enough observations");

		ri = (RankInfo *)safemalloc(nx * sizeof(RankInfo));
		group_names = (char **)safecalloc(nx, sizeof(char*)); // Upper bound

		// Map string group names → contiguous integer IDs
		HV *restrict group_map    = newHV();
		size_t          next_group_id = 0;

		for (size_t i = 0; i < nx; i++) {
			SV **restrict x_el = av_fetch(x_av, i, 0);
			SV **restrict g_el = av_fetch(g_av, i, 0);
			if (x_el && SvOK(*x_el) && looks_like_number(*x_el)
				      && g_el && SvOK(*g_el)) {
				const char *restrict g_str = SvPV_nolen(*g_el);
				STRLEN               glen  = strlen(g_str);
				SV   **restrict id_sv = hv_fetch(group_map, g_str, glen, 0);
				size_t group_id;
				if (id_sv) {
				  group_id = SvUV(*id_sv);
				} else {
				  group_id = next_group_id++;
				  hv_store(group_map, g_str, glen, newSVuv(group_id), 0);
				  group_names[group_id] = savepvn(g_str, glen); // Save string key
				}
				ri[valid_n].val = SvNV(*x_el);
				ri[valid_n].idx = group_id;
				valid_n++;
			}
		}
		k = next_group_id;
		SvREFCNT_dec(group_map);
	}
	/* 5. Shared post-extraction validation */
	if (valid_n < 2 || k < 2) { 
	  Safefree(ri); 
	  if (group_names) {
		   for (size_t i = 0; i < k; i++) { if (group_names[i]) Safefree(group_names[i]); }
		   Safefree(group_names);
	  }
	  if (valid_n < 2) croak("not enough observations");
	  croak("all observations are in the same group");
	}
	// 6. Ranking and Tie Accumulation (Reusing LikeR Helper)
	bool   has_ties = 0;
	double tie_adj  = rank_and_count_ties(ri, valid_n, &has_ties);
	// 7. Aggregate Sum of Ranks AND Actual Values by Group
	double *restrict group_rank_sums = (double *)safecalloc(k, sizeof(double));
	double *restrict group_val_sums  = (double *)safecalloc(k, sizeof(double)); // For Mean
	size_t *restrict group_counts    = (size_t *)safecalloc(k, sizeof(size_t));
	for (size_t i = 0; i < valid_n; i++) {
		size_t g_id = ri[i].idx;
		group_rank_sums[g_id] += ri[i].rank;
		group_val_sums[g_id]  += ri[i].val;
		group_counts[g_id]++;
	}
	// 8. Calculate STATISTIC
	double stat_base = 0.0;
	for (size_t i = 0; i < k; i++) {
	  if (group_counts[i] > 0)
		   stat_base += (group_rank_sums[i] * group_rank_sums[i])
		                / (double)group_counts[i];
	}
	double n_d  = (double)valid_n;
	double stat = (12.0 * stat_base / (n_d * (n_d + 1.0))) - 3.0 * (n_d + 1.0);
	if (tie_adj > 0.0) {
	  double tie_denom = 1.0 - (tie_adj / (n_d * n_d * n_d - n_d));
	  stat /= tie_denom;
	}
	int    df    = (int)k - 1;
	double p_val = get_p_value(stat, df);
	// 9. Return structured data exactly like R's htest
	HV *restrict res = newHV();
	hv_stores(res, "statistic", newSVnv(stat));
	hv_stores(res, "parameter", newSViv(df));
	hv_stores(res, "p_value",   newSVnv(p_val));
	hv_stores(res, "p.value",   newSVnv(p_val));
	hv_stores(res, "method",    newSVpv("Kruskal-Wallis rank sum test", 0));
	// 10. Build the group_stats hash
	HV *restrict group_stats = newHV();
	HV *restrict stats_mean  = newHV();
	HV *restrict stats_size  = newHV();
	for (size_t i = 0; i < k; i++) {
	  if (group_counts[i] > 0 && group_names[i]) {
		   double mean = group_val_sums[i] / (double)group_counts[i];
		   size_t nlen = strlen(group_names[i]);
		   hv_store(stats_mean, group_names[i], nlen, newSVnv(mean), 0);
		   hv_store(stats_size, group_names[i], nlen, newSVuv(group_counts[i]), 0);
	  }
	  if (group_names[i]) Safefree(group_names[i]); // Clean up name copy
	}

	// Embed the nested hashes
	hv_stores(group_stats, "mean", newRV_noinc((SV*)stats_mean));
	hv_stores(group_stats, "size", newRV_noinc((SV*)stats_size));
	hv_stores(res, "group_stats",  newRV_noinc((SV*)group_stats));

	// Memory Cleanup
	Safefree(group_names);    Safefree(group_rank_sums); 
	Safefree(group_val_sums); Safefree(group_counts); Safefree(ri);

	RETVAL = newRV_noinc((SV*)res);
}
OUTPUT:
    RETVAL

SV* var_test(...)
CODE:
{
	SV* restrict x_sv = NULL;
	SV* restrict y_sv = NULL;
	double ratio = 1.0, conf_level = 0.95;
	const char* restrict alternative = "two.sided";
	unsigned int arg_idx = 0;

	// 1. Shift positional argument 'x' if it's an array reference
	if (arg_idx < items && SvROK(ST(arg_idx)) && SvTYPE(SvRV(ST(arg_idx))) == SVt_PVAV) {
	  x_sv = ST(arg_idx);
	  arg_idx++;
	}

	// 2. Shift positional argument 'y' if it's an array reference
	if (arg_idx < items && SvROK(ST(arg_idx)) && SvTYPE(SvRV(ST(arg_idx))) == SVt_PVAV) {
	  y_sv = ST(arg_idx);
	  arg_idx++;
	}
	// Ensure the remaining arguments form complete key-value pairs
	if ((items - arg_idx) % 2 != 0) {
	  croak("Usage: var_test(\\@x, \\@y, key => value, ...)");
	}
	// --- Parse named arguments from the remaining flat stack ---
	for (; arg_idx < items; arg_idx += 2) {
	  const char* restrict key = SvPV_nolen(ST(arg_idx));
	  SV* restrict val = ST(arg_idx + 1);

	  if      (strEQ(key, "x"))           x_sv        = val;
	  else if (strEQ(key, "y"))           y_sv        = val;
	  else if (strEQ(key, "ratio"))       ratio       = SvNV(val);
	  else if (strEQ(key, "conf_level") || strEQ(key, "conf.level")) conf_level = SvNV(val);
	  else if (strEQ(key, "alternative")) alternative = SvPV_nolen(val);
	  else croak("var_test: unknown argument '%s'", key);
	}
	// --- Validate required inputs / types ---
	if (!x_sv || !SvROK(x_sv) || SvTYPE(SvRV(x_sv)) != SVt_PVAV)
	  croak("var_test: 'x' is a required argument and must be an ARRAY reference");
	if (!y_sv || !SvROK(y_sv) || SvTYPE(SvRV(y_sv)) != SVt_PVAV)
	  croak("var_test: 'y' is a required argument and must be an ARRAY reference");

	if (ratio <= 0.0 || !isfinite(ratio)) 
	  croak("var_test: 'ratio' must be a single positive number");
	if (conf_level <= 0.0 || conf_level >= 1.0 || !isfinite(conf_level))
	  croak("var_test: 'conf.level' must be a single number between 0 and 1");
	AV* restrict x_av = (AV*)SvRV(x_sv);
	AV* restrict y_av = (AV*)SvRV(y_sv);
	size_t nx_raw = av_len(x_av) + 1;
	size_t ny_raw = av_len(y_av) + 1;
	// --- Computation via Welford's Algorithm (ignoring NaNs) ---
	double mean_x = 0.0, M2_x = 0.0;
	size_t nx = 0;
	for (size_t i = 0; i < nx_raw; i++) {
		SV** restrict tv = av_fetch(x_av, i, 0);
		if (tv && SvOK(*tv) && looks_like_number(*tv)) {
			double val = SvNV(*tv);
			if (!isnan(val) && isfinite(val)) {
				nx++;
				double delta = val - mean_x;
				mean_x += delta / nx;
				M2_x += delta * (val - mean_x);
			}
		}
	}

	double mean_y = 0.0, M2_y = 0.0;
	size_t ny = 0;
	for (size_t i = 0; i < ny_raw; i++) {
		SV** restrict tv = av_fetch(y_av, i, 0);
		if (tv && SvOK(*tv) && looks_like_number(*tv)) {
			double val = SvNV(*tv);
			if (!isnan(val) && isfinite(val)) {
				ny++;
				double delta = val - mean_y;
				mean_y += delta / ny;
				M2_y += delta * (val - mean_y);
			}
		}
	}

	if (nx < 2) croak("not enough 'x' observations");
	if (ny < 2) croak("not enough 'y' observations");

	double df_x = (double)(nx - 1);
	double df_y = (double)(ny - 1);
	double var_x = M2_x / df_x;
	double var_y = M2_y / df_y;
	if (var_y == 0.0) croak("var_test: variance of 'y' is zero (cannot divide by zero)");
	// --- Statistics Math ---
	double estimate = var_x / var_y;
	double statistic = estimate / ratio;
	double p_val = pf(statistic, df_x, df_y);
	double ci_lower = 0.0, ci_upper = INFINITY;
	if (strcmp(alternative, "less") == 0) {
	  ci_upper = estimate / qf_bisection(1.0 - conf_level, df_x, df_y);
	} else if (strcmp(alternative, "greater") == 0) {
	  p_val = 1.0 - p_val;
	  ci_lower = estimate / qf_bisection(conf_level, df_x, df_y);
	} else {
	  // two.sided
	  double p1 = p_val;
	  double p2 = 1.0 - p_val;
	  p_val = 2.0 * (p1 < p2 ? p1 : p2);
	  double beta = (1.0 - conf_level) / 2.0;
	  ci_lower = estimate / qf_bisection(1.0 - beta, df_x, df_y);
	  ci_upper = estimate / qf_bisection(beta, df_x, df_y);
	}

	// --- Pack Results ---
	HV* restrict results = newHV();
	hv_store(results, "statistic", 9, newSVnv(statistic), 0);

	AV* restrict param_av = newAV();
	av_push(param_av, newSVnv(df_x));
	av_push(param_av, newSVnv(df_y));
	hv_store(results, "parameter", 9, newRV_noinc((SV*)param_av), 0);

	hv_store(results, "p_value", 7, newSVnv(p_val), 0);

	AV* restrict conf_int = newAV();
	av_push(conf_int, newSVnv(ci_lower));
	av_push(conf_int, newSVnv(ci_upper));
	hv_store(results, "conf_int", 8, newRV_noinc((SV*)conf_int), 0);

	hv_store(results, "estimate", 8, newSVnv(estimate), 0);
	hv_store(results, "null_value", 10, newSVnv(ratio), 0);
	hv_store(results, "alternative", 11, newSVpv(alternative, 0), 0);
	hv_store(results, "method", 6, newSVpv("F test to compare two variances", 0), 0);

	RETVAL = newRV_noinc((SV*)results);
}
OUTPUT:
    RETVAL

SV *sample(ref, n = 1)
    SV *ref
    IV n
PREINIT:
    SV *restrict ret = &PL_sv_undef;
CODE:
	if (!PL_srand_called) {
	  (void)seedDrand01((Rand_seed_t)Perl_seed(aTHX));
	  PL_srand_called = TRUE;
	}
	if (n < 0) n = 0;
	if (SvROK(ref)) {
		SV *restrict rv = SvRV(ref);
		/* --- HASH REFERENCE --- */
		if (SvTYPE(rv) == SVt_PVHV) {
			HV *restrict hv    = (HV *)rv;
			unsigned count = hv_iterinit(hv);
			unsigned limit = (n < (IV)count) ? (I32)n : count;
			HV *restrict ret_hv = newHV();

			if (count > 0 && limit > 0) {
				 HE **restrict entries;
				 HE  *restrict entry;
				 unsigned i;

				 Newx(entries, count, HE *);

				 /* Collect all HE pointers in one pass */
				 i = 0;
				 while ((entry = hv_iternext(hv)))
				     entries[i++] = entry;

				 /* Partial Fisher-Yates (only 'limit' passes) */
				 for (i = 0; i < limit; i++) {
				     I32 j    = i + (I32)(Drand01() * (count - i));
				     HE *restrict tmp  = entries[i];
				     entries[i] = entries[j];
				     entries[j] = tmp;
				 }

				 /* Pre-size result hash to avoid rehashing during population */
				 hv_ksplit(ret_hv, limit);

				 for (i = 0; i < limit; i++) {
				     HEK *restrict hek = HeKEY_hek(entries[i]);
				     /*
				      * hv_store() with a precomputed hash skips the hash
				      * computation entirely.  Negative klen signals UTF-8.
				      */
				     (void)hv_store(
				         ret_hv,
				         HEK_KEY(hek),
				         HEK_UTF8(hek) ? -(I32)HEK_LEN(hek) : (I32)HEK_LEN(hek),
				         SvREFCNT_inc(HeVAL(entries[i])),  /* HeVAL: direct macro, no call */
				         HeHASH(entries[i])                /* reuse precomputed hash */
				     );
				 }
				 Safefree(entries);
			}
			ret = newRV_noinc((SV *)ret_hv);
		} else if (SvTYPE(rv) == SVt_PVAV) {/* --- ARRAY REFERENCE --- */
			AV    *restrict av    = (AV *)rv;
			size_t count = av_top_index(av) + 1;  /* signed; 0 for empty AV */
			size_t limit = (n < count) ? (size_t)n : count;
			AV    *restrict ret_av = newAV();

			/* Pre-allocate the result array to avoid incremental reallocs */
			if (n > 0)
				 av_extend(ret_av, (size_t)n - 1);

			if (count > 0) {
				 SV    **restrict src = AvARRAY(av);   /* direct pointer into AV's C array */
				 size_t *restrict idx;

				 /* Shuffle indices rather than SV** to keep the original AV intact */
				 Newx(idx, count, size_t);
				 for (size_t i = 0; i < count; i++)
				     idx[i] = i;

				 /* Partial Fisher-Yates on the index array */
				 for (size_t i = 0; i < limit; i++) {
				     size_t j   = i + (size_t)(Drand01() * (count - i));
				     size_t tmp = idx[i];
				     idx[i]  = idx[j];
				     idx[j]  = tmp;
				 }

				 for (size_t i = 0; i < (size_t)n; i++) {
				     if (i < limit) {
				         SV *restrict sv = src[idx[i]];   /* AvARRAY direct access — no av_fetch call */
				         SV *restrict push_sv;
							if (sv && sv != &PL_sv_undef)
								 push_sv = SvREFCNT_inc(sv);
							else
								 push_sv = newSV(0);
							av_push(ret_av, push_sv);
				     } else {
				         av_push(ret_av, newSV(0));
				     }
				 }
				 Safefree(idx);
			} else {
				for (size_t i = 0; i < (size_t)n; i++)
				    av_push(ret_av, newSV(0));
			}
			ret = newRV_noinc((SV *)ret_av);
		}
	}
	RETVAL = ret;
OUTPUT:
    RETVAL

SV* dnorm(...)
CODE:
{
	if (items < 1) {
	  croak("Usage: dnorm(x), dnorm(x, mean => 0, sd => 1, log => 0)");
	}
	SV*restrict x_sv = ST(0);
	double mean = 0.0, sd = 1.0; /*defaults*/
	bool give_log = 0;
	// --- Parse remaining named arguments from the flat stack ---
	if ((items - 1) % 2 != 0) {
	  croak("dnorm: Expected an even number of key-value named arguments after 'x'");
	}
	for (size_t i = 1; i < items; i += 2) {
	  const char* restrict key = SvPV_nolen(ST(i));
	  SV* restrict val = ST(i + 1);
	  if      (strEQ(key, "mean")) mean     = SvNV(val);
	  else if (strEQ(key, "sd"))   sd       = SvNV(val);
	  else if (strEQ(key, "log"))  give_log = SvTRUE(val) ? 1 : 0;
	  else croak("dnorm: unknown argument '%s'", key);
	}
	// --- Branch based on scalar vs. arrayref for 'x' ---
	if (SvROK(x_sv) && SvTYPE(SvRV(x_sv)) == SVt_PVAV) {
	  // x is an array reference
	  AV *restrict x_av = (AV*)SvRV(x_sv);
	  IV n = av_len(x_av) + 1;
	  AV *restrict result_av = newAV();
	  if (n > 0) {
		   av_extend(result_av, n - 1);
		   for (IV i = 0; i < n; i++) {
		       SV **restrict elem = av_fetch(x_av, i, 0);
		       double x_val = (elem && *elem) ? SvNV(*elem) : NAN;
		       double res = c_dnorm(x_val, mean, sd, give_log);
		       av_store(result_av, i, newSVnv(res));
		   }
	  }
	  RETVAL = newRV_noinc((SV*)result_av);
	} else {
	  // x is a single numeric scalar
	  double x_val = SvNV(x_sv);
	  double res = c_dnorm(x_val, mean, sd, give_log);
	  RETVAL = newSVnv(res);
	}
	}
OUTPUT:
	RETVAL

void ljoin(h_ref, i_ref)
	SV *h_ref;
	SV *i_ref;
PREINIT:
	HV *restrict h_hv, *restrict i_hv;
	HE *restrict h_entry;
CODE:
	/* 1. Validate inputs are hash references */
	if (!SvROK(h_ref) || SvTYPE(SvRV(h_ref)) != SVt_PVHV) {
	  croak("First argument to ljoin must be a hash reference");
	}
	if (!SvROK(i_ref) || SvTYPE(SvRV(i_ref)) != SVt_PVHV) {
	  croak("Second argument to ljoin must be a hash reference");
	}
	h_hv = (HV *)SvRV(h_ref);
	i_hv = (HV *)SvRV(i_ref);
	/* 2. Iterate through the primary hash ($h) */
	hv_iterinit(h_hv);
	while ((h_entry = hv_iternext(h_hv))) {
		SV *restrict row_key_sv = hv_iterkeysv(h_entry);
		SV *restrict h_row_sv   = hv_iterval(h_hv, h_entry);
		/* 3. Check if this row key exists in the secondary hash ($i) */
		HE *i_fetch_he = hv_fetch_ent(i_hv, row_key_sv, 0, 0);
		if (i_fetch_he) {
			SV *restrict i_row_sv = HeVAL(i_fetch_he);
			/* 4. Ensure $h->{row} is a Hash and $i->{row} is a valid reference */
			if (SvROK(h_row_sv) && SvTYPE(SvRV(h_row_sv)) == SVt_PVHV && SvROK(i_row_sv)) {
				HV *restrict h_row_hv = (HV *)SvRV(h_row_sv);
				/* Case A: $i->{row} is a Hash Reference */
				if (SvTYPE(SvRV(i_row_sv)) == SVt_PVHV) {
				  HV *restrict i_row_hv = (HV *)SvRV(i_row_sv);
				  HE *restrict i_entry;
				  hv_iterinit(i_row_hv);
				  while ((i_entry = hv_iternext(i_row_hv))) {
						SV *col_key_sv = hv_iterkeysv(i_entry);
						SV *col_val    = hv_iterval(i_row_hv, i_entry);
						hv_store_ent(h_row_hv, col_key_sv, SvREFCNT_inc(col_val), 0);
				  }
				} else if (SvTYPE(SvRV(i_row_sv)) == SVt_PVAV) {
				/* Case B: $i->{row} is an Array Reference */
				  AV *i_row_av = (AV *)SvRV(i_row_sv);
				  /* av_len returns the top index (length - 1) */
				  SSize_t top_idx = av_len(i_row_av); 
				  SSize_t idx;

				  /* Iterate through the array in chunks of 2 (key-value pairs) */
				  for (idx = 0; idx < top_idx; idx += 2) {
						SV **key_svp = av_fetch(i_row_av, idx, 0);
						SV **val_svp = av_fetch(i_row_av, idx + 1, 0);

						/* Ensure both the key and value exist in the array */
						if (key_svp && val_svp) {
							 hv_store_ent(h_row_hv, *key_svp, SvREFCNT_inc(*val_svp), 0);
						}
				  }
				}
			}
		}
	}

void add_data(h_ref, i_ref)
	SV *h_ref;
	SV *i_ref;
PREINIT:
	HV *restrict h_hv, *restrict i_hv;
	HE *restrict i_entry;
CODE:
	/* 1. Validate inputs */
	if (!SvROK(h_ref) || SvTYPE(SvRV(h_ref)) != SVt_PVHV) {
	  croak("First argument to add_data must be a hash reference");
	}
	if (!SvROK(i_ref) || SvTYPE(SvRV(i_ref)) != SVt_PVHV) {
	  croak("Second argument to add_data must be a hash reference");
	}
	h_hv = (HV *)SvRV(h_ref);
	i_hv = (HV *)SvRV(i_ref);
	/* 2. Iterate through the SECONDARY hash ($i) */
	hv_iterinit(i_hv);
	while ((i_entry = hv_iternext(i_hv))) {
		SV *restrict row_key_sv = hv_iterkeysv(i_entry);
		SV *restrict i_row_sv   = hv_iterval(i_hv, i_entry);
		/* Only proceed if the secondary row contains a valid reference */
		if (SvROK(i_row_sv)) {
			HE *restrict h_fetch_he = hv_fetch_ent(h_hv, row_key_sv, 0, 0);
			SV *restrict h_row_sv   = NULL;
			HV *restrict h_row_hv   = NULL;
			/* 3. Check if the row exists in $h */
			if (h_fetch_he) {
				h_row_sv = HeVAL(h_fetch_he);
				 /* Ensure existing row is a Hash Reference */
				if (SvROK(h_row_sv) && SvTYPE(SvRV(h_row_sv)) == SVt_PVHV) {
					h_row_hv = (HV *)SvRV(h_row_sv);
				}
			} else {
				 /* 4. Row DOES NOT exist in $h: Create it */
				 h_row_hv = newHV();
				 /* Create a reference to the new hash. newRV_noinc transfers 
				    ownership of the HV's initial reference count to the SV. */
				 h_row_sv = newRV_noinc((SV *)h_row_hv);
				 /* Store in $h. hv_store_ent takes ownership of the SV's ref count. */
				 hv_store_ent(h_hv, row_key_sv, h_row_sv, 0);
			}
			/* 5. Merge data if we successfully resolved a target hash row */
			if (h_row_hv) {
				/* Case A: $i->{row} is a Hash Reference */
				if (SvTYPE(SvRV(i_row_sv)) == SVt_PVHV) {
					HV *restrict i_inner_hv = (HV *)SvRV(i_row_sv);
					HE *restrict i_inner_entry;
					hv_iterinit(i_inner_hv);
					while ((i_inner_entry = hv_iternext(i_inner_hv))) {
						SV *restrict col_key_sv = hv_iterkeysv(i_inner_entry);
						SV *restrict col_val    = hv_iterval(i_inner_hv, i_inner_entry);
						hv_store_ent(h_row_hv, col_key_sv, SvREFCNT_inc(col_val), 0);
					}
				} else if (SvTYPE(SvRV(i_row_sv)) == SVt_PVAV) {
				/* Case B: $i->{row} is an Array Reference */
					AV *restrict i_inner_av = (AV *)SvRV(i_row_sv);
					SSize_t top_idx = av_len(i_inner_av);
					for (SSize_t idx = 0; idx < top_idx; idx += 2) {
						SV **restrict key_svp = av_fetch(i_inner_av, idx, 0);
						SV **restrict val_svp = av_fetch(i_inner_av, idx + 1, 0);
						if (key_svp && val_svp) {
							hv_store_ent(h_row_hv, *key_svp, SvREFCNT_inc(*val_svp), 0);
						}
					}
				}
			}
		}
	}

#define EVAL_FILTER(sub_sv, val_sv, keep) do {        \
 dSP;                                                 \
 unsigned int count;                                  \
 SV *restrict _ef_arg = (val_sv) ? (val_sv) : &PL_sv_undef; \
 ENTER;                                               \
 SAVETMPS;                                            \
 SAVE_DEFSV;                                          \
 SvREFCNT_inc(_ef_arg); /* Prevent LEAVE from stealing the refcount */ \
 DEFSV_set(_ef_arg);                                  \
 PUSHMARK(SP);                                        \
 XPUSHs(_ef_arg);                                     \
 PUTBACK;                                             \
 count = call_sv(sub_sv, G_SCALAR | G_EVAL);          \
 SPAGAIN;                                             \
 if (SvTRUE(ERRSV)) { FREETMPS; LEAVE; croak(NULL); } \
 if (count > 0) {                                     \
     SV *restrict ret_sv = POPs; \
     keep = SvTRUE(ret_sv);      \
 } else {                        \
     keep = 0;                   \
 }                               \
 PUTBACK;                        \
 FREETMPS;                       \
 LEAVE;                          \
} while (0)

SV *group_by(data_ref, target_key_sv, group_key_sv, ...)
	SV *data_ref;
	SV *target_key_sv;
	SV *group_key_sv;
PREINIT:
	HV *restrict result_hv;
	HV *restrict filter_hv = NULL;
	SV *restrict result_ref;
CODE:
	if (!SvOK(data_ref)) {
		croak("First argument to group_by is NOT defined");
	}
	if (!SvOK(target_key_sv)) {
		croak("Second argument to group_by is NOT defined");
	}
	if (!SvOK(group_key_sv)) {
		croak("Third argument to group_by is NOT defined");
	}
	/* 1. Validate the primary input is a reference */
	if (!SvROK(data_ref)) {
	croak("First argument to group_by must be a reference (Array of Hashes, Hash of Arrays, or Hash of Hashes)");
	}
	if (items > 3) { /* Capture the optional filter argument */
	  SV *restrict filter_ref = ST(3);
	  if (SvROK(filter_ref) && SvTYPE(SvRV(filter_ref)) == SVt_PVHV) {
		   filter_hv = (HV *)SvRV(filter_ref);
	  }
	}
	result_hv = newHV(); /* 2. Allocate the hash that we will return */
	/* Mortalize immediately! If the callback croaks, the tmps stack 
	* will safely clean this up. */
	result_ref = sv_2mortal(newRV_noinc((SV *)result_hv)); 
	if (SvTYPE(SvRV(data_ref)) == SVt_PVAV) { /* Input is an Array of Hashes (AoH) */
		AV *restrict data_av = (AV *)SvRV(data_ref);
		SSize_t len = av_len(data_av) + 1;
		for (SSize_t i = 0; i < len; i++) {
			SV **restrict row_svp = av_fetch(data_av, i, 0);
			if (row_svp && SvROK(*row_svp) && SvTYPE(SvRV(*row_svp)) == SVt_PVHV) {
				HV *restrict row_hv = (HV *)SvRV(*row_svp);
				HE *restrict group_he = hv_fetch_ent(row_hv, group_key_sv, 0, 0);
				HE *restrict target_he = hv_fetch_ent(row_hv, target_key_sv, 0, 0);
				if (group_he) {
					SV *restrict group_val = HeVAL(group_he);
					SV *restrict target_val = target_he ? HeVAL(target_he) : NULL;
					if (target_val && SvOK(target_val)) {
						bool pass_filter = 1;
						if (filter_hv) {
							HE *restrict f_he;
							hv_iterinit(filter_hv);
							while ((f_he = hv_iternext(filter_hv))) {
								SV *restrict f_col = hv_iterkeysv(f_he);
								SV *restrict f_sub = hv_iterval(filter_hv, f_he);
								HE *restrict val_he = hv_fetch_ent(row_hv, f_col, 0, 0);
								SV *restrict val_sv = val_he ? HeVAL(val_he) : NULL;
								bool keep;
								EVAL_FILTER(f_sub, val_sv, keep);
								if (!keep) {
									pass_filter = 0;
									break;
								}
							}
						}
						if (pass_filter) {
							HE *restrict res_he = hv_fetch_ent(result_hv, group_val, 0, 0);
							AV *restrict res_av;
							if (res_he) {
							  res_av = (AV *)SvRV(HeVAL(res_he));
							} else {
							  res_av = newAV();
							  hv_store_ent(result_hv, group_val, newRV_noinc((SV *)res_av), 0);
							}
							av_push(res_av, newSVsv(target_val));
						}
					}
				}
			}
		}
	} else if (SvTYPE(SvRV(data_ref)) == SVt_PVHV) {
		HV *restrict data_hv = (HV *)SvRV(data_ref);
		HE *restrict group_he = hv_fetch_ent(data_hv, group_key_sv, 0, 0);
		HE *restrict target_he = hv_fetch_ent(data_hv, target_key_sv, 0, 0);
		if (group_he && target_he &&
			SvROK(HeVAL(group_he)) && SvTYPE(SvRV(HeVAL(group_he))) == SVt_PVAV &&
			SvROK(HeVAL(target_he)) && SvTYPE(SvRV(HeVAL(target_he))) == SVt_PVAV) {
			AV *restrict group_av = (AV *)SvRV(HeVAL(group_he));
			AV *restrict target_av = (AV *)SvRV(HeVAL(target_he));
			SSize_t g_len = av_len(group_av) + 1;
			SSize_t t_len = av_len(target_av) + 1;
			SSize_t len = g_len < t_len ? g_len : t_len;
			for (SSize_t i = 0; i < len; i++) {
				 SV **restrict g_svp = av_fetch(group_av, i, 0);
				 SV **restrict t_svp = av_fetch(target_av, i, 0);
				 if (g_svp && *g_svp) {
				     SV *restrict g_val = *g_svp;
				     SV *restrict t_val = (t_svp && *t_svp) ? *t_svp : NULL;
				     if (t_val && SvOK(t_val)) {
				         bool pass_filter = 1;
				         if (filter_hv) {
				             HE *restrict f_he;
				             hv_iterinit(filter_hv);
				             while ((f_he = hv_iternext(filter_hv))) {
				                 SV *restrict f_col = hv_iterkeysv(f_he);
				                 SV *restrict f_sub = hv_iterval(filter_hv, f_he);
				                 SV *restrict val_sv = NULL;
				                 HE *restrict arr_he = hv_fetch_ent(data_hv, f_col, 0, 0);
				                 if (arr_he && SvROK(HeVAL(arr_he)) && SvTYPE(SvRV(HeVAL(arr_he))) == SVt_PVAV) {
				                     AV *restrict col_av = (AV *)SvRV(HeVAL(arr_he));
				                     SV **restrict val_svp = av_fetch(col_av, i, 0);
				                     if (val_svp) val_sv = *val_svp;
				                 }
				                 bool keep;
				                 EVAL_FILTER(f_sub, val_sv, keep);
				                 if (!keep) {
				                     pass_filter = 0;
				                     break;
				                 }
				             }
				         }
				         if (pass_filter) {
				             HE *restrict res_he = hv_fetch_ent(result_hv, g_val, 0, 0);
				             AV *restrict res_av;
				             if (res_he) {
				                 res_av = (AV *)SvRV(HeVAL(res_he));
				             } else {
				                 res_av = newAV();
				                 hv_store_ent(result_hv, g_val, newRV_noinc((SV *)res_av), 0);
				             }
				             av_push(res_av, newSVsv(t_val));
				         }
				     }
				 }
			}
		} else {
			HE *restrict row_he;
			hv_iterinit(data_hv);
			while ((row_he = hv_iternext(data_hv))) {
				SV *restrict row_val = hv_iterval(data_hv, row_he);
				if (SvROK(row_val) && SvTYPE(SvRV(row_val)) == SVt_PVHV) {
					HV *restrict inner_hv = (HV *)SvRV(row_val);
					HE *restrict inner_group_he = hv_fetch_ent(inner_hv, group_key_sv, 0, 0);
					HE *restrict inner_target_he = hv_fetch_ent(inner_hv, target_key_sv, 0, 0);
					if (inner_group_he) {
						SV *restrict g_val = HeVAL(inner_group_he);
						SV *restrict t_val = inner_target_he ? HeVAL(inner_target_he) : NULL;
						if (t_val && SvOK(t_val)) {
							bool pass_filter = 1;
							if (filter_hv) {
								HE *restrict f_he;
								hv_iterinit(filter_hv);
								while ((f_he = hv_iternext(filter_hv))) {
								  SV *restrict f_col = hv_iterkeysv(f_he);
								  SV *restrict f_sub = hv_iterval(filter_hv, f_he);
								  HE *restrict val_he = hv_fetch_ent(inner_hv, f_col, 0, 0);
								  SV *restrict val_sv = val_he ? HeVAL(val_he) : NULL;

								  bool keep;
								  EVAL_FILTER(f_sub, val_sv, keep);

								  if (!keep) {
										pass_filter = 0;
										break;
								  }
								}
							}
							if (pass_filter) {
								HE *restrict res_he = hv_fetch_ent(result_hv, g_val, 0, 0);
								AV *restrict res_av;
								if (res_he) {
								  res_av = (AV *)SvRV(HeVAL(res_he));
								} else {
								  res_av = newAV();
								  hv_store_ent(result_hv, g_val, newRV_noinc((SV *)res_av), 0);
								}
								av_push(res_av, newSVsv(t_val));
							}
						}
					}
				}
			}
		}
	} else {
	  croak("First argument to group_by must be an Array or Hash reference");
	}
	/* Balance xsubpp's automatic sv_2mortal to prevent refcount dropping to -1 */
	RETVAL = SvREFCNT_inc(result_ref);
OUTPUT:
    RETVAL
