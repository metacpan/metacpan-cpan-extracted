#ifndef _GNU_SOURCE
#define _GNU_SOURCE        // glibc / Linux
#endif
#ifndef __EXTENSIONS__
#define __EXTENSIONS__ 1   // Solaris/illumos: expose off64_t, sigjmp_buf under -std=c99
#endif
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
#include <stdint.h> // uint64_t — harmless if perl.h already pulled it in
/*
XS words:
SvROK = scalar value reference is OK
*/
/* sample(): private splitmix64 PRNG

sample() gets its own PRNG state, completely separate from Drand01.
That means generate_binomial(), ruif(), rbinom(), and every other caller
of Drand01() are unaffected — their streams are never advanced or reseeded
by anything sample() does.

Seeding is lazy (first call) and reads from /dev/urandom; falls back to
time()^PID on systems without it.  No aTHX needed: all calls are plain C.
PERL_NO_GET_CONTEXT is therefore not a concern here. */
static uint64_t sample__state  = 0;

PERL_STATIC_INLINE uint64_t
sample__mix64(void)
{
	uint64_t z = (sample__state += UINT64_C(0x9e3779b97f4a7c15));
	z = (z ^ (z >> 30)) * UINT64_C(0xbf58476d1ce4e5b9);
	z = (z ^ (z >> 27)) * UINT64_C(0x94d049bb133111eb);
	return z ^ (z >> 31);
}

/* * Helper function to increment the count for a given SV.
 * Skips NULL or Undefined values as requested. */
static void increment_count(pTHX_ HV* counts_hv, SV* val) {
	/* Skip null pointers or undef (non-OK) values */
	if (!val || !SvOK(val)) return; 
	STRLEN len;
	// SvPV forces stringification (so numbers become string keys)
	char*restrict str = SvPV(val, len);
	// hv_fetch with lval=1 creates the key if it doesn't exist
	SV**restrict svp = hv_fetch(counts_hv, str, len, 1);
	if (svp) {
		if (!SvOK(*svp)) {
			sv_setuv(*svp, 1);// Initialize count to 1 as an Unsigned Value (UV)
		} else {
			sv_setuv(*svp, SvUV(*svp) + 1);// Increment existing Unsigned Value
		}
	}
}

// Uniform integer in [0, upper) — rejection loop, no modulo bias
PERL_STATIC_INLINE size_t
sample__rand(size_t upper) {
	const uint64_t u = (uint64_t)upper;
	const uint64_t t = (uint64_t)(-(uint64_t)u) % u;
	uint64_t r;
	do { r = sample__mix64(); } while (r < t);
	return (size_t)(r % u);
}
// end sample() private PRNG

// Ensure Perl's PRNG is seeded, matching the lazy-evaluation of Perl's rand()
#define AUTO_SEED_PRNG() \
	do { \
		if (!PL_srand_called) { \
			(void)seedDrand01((Rand_seed_t)Perl_seed(aTHX)); \
			PL_srand_called = TRUE; \
		} \
	} while (0)

// Helpers for Random Number Generation
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif
// C helper for EXACT Non-central T-distribution CDF via Numerical Integration.
// This perfectly replicates R's pt(..., ncp) exactness without requiring complex Beta functions.
static NV exact_pnt(NV t, NV df, NV ncp) {
	if (df <= 0.0) return 0.0;
	unsigned short int n_steps = 30000;
	NV step = 1.0 / n_steps;
	NV integral = 0.0, half_df = df / 2.0;
	NV log_coef = log(2.0) + half_df * log(half_df) - lgamma(half_df);
	NV root_half = 0.70710678118654752440; // 1 / sqrt(2)
	for (unsigned short i = 1; i < n_steps; i++) {
		NV u = i * step;
		NV w = u / (1.0 - u);
		// Scaled Chi-distribution log-density
		NV log_M = log_coef + (df - 1.0) * log(w) - half_df * w * w;
		NV M = exp(log_M);
		// Exact Normal CDF using the C standard library's erfc function
		NV z = t * w - ncp;
		NV pnorm_val = 0.5 * erfc(-z * root_half);
		NV weight = (i % 2 != 0) ? 4.0 : 2.0;
		integral += weight * (pnorm_val * M / ((1.0 - u) * (1.0 - u)));
	}
	return integral * (step / 3.0);
}
// --- Math Helpers for P-values and Confidence Intervals --- 

// Ranking helper with tie adjustment (matches R's tie handling)
typedef struct { NV val; size_t idx; NV rank; } RankInfo;
static int compare_rank(const void *restrict a, const void *restrict b) {
	NV diff = ((RankInfo*)a)->val - ((RankInfo*)b)->val;
	return (diff > 0) - (diff < 0);
}

static int compare_index(const void *restrict a, const void *restrict b) {
	return ((RankInfo*)a)->idx - ((RankInfo*)b)->idx;
}

static void compute_ranks(NV *restrict data, NV *restrict ranks, size_t n) {
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
		NV avg_rank = (i + 1 + j) / 2.0;
		for (size_t k = i; k < j; k++) items[k].rank = avg_rank;
		i = j;
	}
	qsort(items, n, sizeof(RankInfo), compare_index);
	for (size_t i = 0; i < n; i++) ranks[i] = items[i].rank;
	Safefree(items);
}
// Generates a single binomial random variate. 
//Uses the standard Bernoulli trial loop. Drand01() taps into Perl's PRNG.
static size_t generate_binomial(pTHX_ const size_t size, const NV prob) {
	if (prob <= 0.0) return 0;
	if (prob >= 1.0) return size;

	size_t successes = 0;
	for (size_t i = 0; i < size; i++) {
		if (Drand01() <= prob) successes++;
	}
	return successes;
}

#define FT_EPS 2.220446049250313e-16
#define FT_TOL 0.0001220703125 // .Machine$double.eps^0.25, R uniroot default

static NV ft_lchoose(long n, long k) {
	if (k < 0 || k > n || n < 0) return -INFINITY;
	return lgamma((NV)n + 1) - lgamma((NV)k + 1) - lgamma((NV)(n - k) + 1);
}

typedef struct {
	long lo, hi, ns, m, n, k, x;
	NV *restrict logdc;   // central log hypergeometric density over the support
} ft_support;

static int ft_init(ft_support *S, long a, long b, long c, long d) {
	S->m = a + c; S->n = b + d; S->k = a + b; S->x = a;
	S->lo = (S->k - S->n > 0) ? (S->k - S->n) : 0;
	S->hi = (S->k < S->m) ? S->k : S->m;
	S->ns = S->hi - S->lo + 1;
	if (S->ns <= 0) { S->logdc = NULL; return 0; }
	Newx(S->logdc, S->ns, NV);
	for (long i = 0; i < S->ns; i++) {
	  long j = S->lo + i;
	  S->logdc[i] = ft_lchoose(S->m, j) + ft_lchoose(S->n, S->k - j)
				   - ft_lchoose(S->m + S->n, S->k);
	}
	return 1;
}
static void ft_free(ft_support *S) { Safefree(S->logdc); S->logdc = NULL; }

static void ft_dnhyper(const ft_support *S, NV ncp, NV *out) {
	NV lncp = log(ncp), mx = -INFINITY;
	for (long i = 0; i < S->ns; i++) {
	  out[i] = S->logdc[i] + lncp * (NV)(S->lo + i);
	  if (out[i] > mx) mx = out[i];
	}
	NV s = 0;
	for (long i = 0; i < S->ns; i++) { out[i] = exp(out[i] - mx); s += out[i]; }
	for (long i = 0; i < S->ns; i++) out[i] /= s;
}

static NV ft_mnhyper(const ft_support *restrict S, NV ncp, NV *scratch) {
	if (ncp == 0)     return (NV)S->lo;
	if (isinf(ncp))   return (NV)S->hi;
	ft_dnhyper(S, ncp, scratch);
	NV mu = 0;
	for (long i = 0; i < S->ns; i++) mu += (NV)(S->lo + i) * scratch[i];
	return mu;
}

// upper != 0 => P(X >= q), upper == 0 => P(X <= q)
static NV ft_pnhyper(const ft_support *S, long q, NV ncp, int upper, NV *scratch) {
	if (ncp == 1.0) {
	  NV s = 0;
	  for (long i = 0; i < S->ns; i++) {
		   long j = S->lo + i;
		   if (upper ? (j >= q) : (j <= q)) s += exp(S->logdc[i]);
	  }
	  return s;
	}
	if (ncp == 0.0)   return upper ? (NV)(q <= S->lo) : (NV)(q >= S->lo);
	if (isinf(ncp))   return upper ? (NV)(q <= S->hi) : (NV)(q >= S->hi);
	ft_dnhyper(S, ncp, scratch);
	NV s = 0;
	for (long i = 0; i < S->ns; i++) {
	  long j = S->lo + i;
	  if (upper ? (j >= q) : (j <= q)) s += scratch[i];
	}
	return s;
}

/* R's src/library/stats/src/zeroin.c (Brent-Dekker) */
typedef NV (*ft_fn)(NV t, void *ctx);
static NV ft_zeroin(NV ax, NV bx, ft_fn f, void *ctx, NV tol, int maxit) {
	NV a = ax, b = bx, fa = f(a, ctx), fb = f(b, ctx), c = a, fc = fa;
	while (maxit-- > 0) {
	  NV prev = b - a;
	  if (fabs(fc) < fabs(fb)) { a = b; b = c; c = a; fa = fb; fb = fc; fc = fa; }
	  NV tol_act = 2 * FT_EPS * fabs(b) + tol / 2;
	  NV step = (c - b) / 2;
	  if (fabs(step) <= tol_act || fb == 0.0) return b;
	  if (fabs(prev) >= tol_act && fabs(fa) > fabs(fb)) {
		   NV cb = c - b, p, q;
		   if (a == c) { NV t1 = fb / fa; p = cb * t1; q = 1.0 - t1; }
		   else {
			   NV q0 = fa / fc, t1 = fb / fc, t2 = fb / fa;
			   p = t2 * (cb * q0 * (q0 - t1) - (b - a) * (t1 - 1.0));
			   q = (q0 - 1.0) * (t1 - 1.0) * (t2 - 1.0);
		   }
		   if (p > 0) q = -q; else p = -p;
		   if (p < 0.75 * cb * q - fabs(tol_act * q) / 2 && p < fabs(prev * q / 2)) step = p / q;
	  }
	  if (fabs(step) < tol_act) step = step > 0 ? tol_act : -tol_act;
	  a = b; fa = fb; b += step; fb = f(b, ctx);
	  if ((fb > 0) == (fc > 0)) { c = a; fc = fa; }
	}
	return b;
}

typedef struct { const ft_support *S; NV target; NV *scratch; int mode; } ft_rc;
/* mode 0: mnhyper(t)-target      1: mnhyper(1/t)-target
   mode 2: pnhyper(x,t,low)-tgt   3: pnhyper(x,1/t,low)-tgt
   mode 4: pnhyper(x,t,up)-tgt    5: pnhyper(x,1/t,up)-tgt */
static NV ft_rootf(NV t, void *ctx) {
	ft_rc *r = (ft_rc *)ctx; const ft_support *S = r->S;
	switch (r->mode) {
	  case 0: return ft_mnhyper(S, t, r->scratch) - r->target;
	  case 1: return ft_mnhyper(S, 1.0 / t, r->scratch) - r->target;
	  case 2: return ft_pnhyper(S, S->x, t, 0, r->scratch) - r->target;
	  case 3: return ft_pnhyper(S, S->x, 1.0 / t, 0, r->scratch) - r->target;
	  case 4: return ft_pnhyper(S, S->x, t, 1, r->scratch) - r->target;
	  default:return ft_pnhyper(S, S->x, 1.0 / t, 1, r->scratch) - r->target;
	}
}

static NV exact_p_value(long a, long b, long c, long d, const char *alt) {
	ft_support S;
	if (!ft_init(&S, a, b, c, d)) return 1.0;
	NV *restrict sc; Newx(sc, S.ns, NV);
	NV p;
	if (!strcmp(alt, "less"))         p = ft_pnhyper(&S, S.x, 1.0, 0, sc);
	else if (!strcmp(alt, "greater")) p = ft_pnhyper(&S, S.x, 1.0, 1, sc);
	else {
	  ft_dnhyper(&S, 1.0, sc);
	  NV dx = sc[S.x - S.lo], relErr = 1 + 1e-7, s = 0;
	  for (long i = 0; i < S.ns; i++) if (sc[i] <= dx * relErr) s += sc[i];
	  p = s;
	}
	if (p < 0) p = 0; if (p > 1) p = 1;
	Safefree(sc); ft_free(&S);
	return p;
}

static void calculate_exact_stats(long a, long b, long c, long d, NV conf,
								  const char *alt, NV *orp, NV *lop, NV *hip) {
	ft_support S;
	if (!ft_init(&S, a, b, c, d)) { *orp = NAN; *lop = NAN; *hip = NAN; return; }
	NV *restrict sc; Newx(sc, S.ns, NV);
	long x = S.x, lo = S.lo, hi = S.hi;

	// conditional MLE of the odds ratio
	NV est;
	if      (x == lo) est = 0.0;
	else if (x == hi) est = INFINITY;
	else {
	  NV mu = ft_mnhyper(&S, 1.0, sc);
	  ft_rc r = { &S, (NV)x, sc, 0 };
	  if      (mu > x) { r.mode = 0; est = ft_zeroin(0, 1, ft_rootf, &r, FT_TOL, 1000); }
	  else if (mu < x) { r.mode = 1; est = 1.0 / ft_zeroin(FT_EPS, 1, ft_rootf, &r, FT_TOL, 1000); }
	  else             est = 1.0;
	}
	*orp = est;
	// confidence interval via inversion of the noncentral hypergeometric
	NV clo, chi;
	ft_rc r = { &S, 0, sc, 0 };
	#define FT_NCP_L(alpha, dst) do {                                                    \
	  if (x == lo) { dst = 0.0; } else {                                               \
		   NV p = ft_pnhyper(&S, x, 1.0, 1, sc);                                     \
		   if (p > (alpha))      { r.mode = 4; r.target = (alpha); dst = ft_zeroin(0, 1, ft_rootf, &r, FT_TOL, 1000); } \
		   else if (p < (alpha)) { r.mode = 5; r.target = (alpha); dst = 1.0 / ft_zeroin(FT_EPS, 1, ft_rootf, &r, FT_TOL, 1000); } \
		   else dst = 1.0; } } while (0)
	#define FT_NCP_U(alpha, dst) do {                                                    \
	  if (x == hi) { dst = INFINITY; } else {                                          \
		   NV p = ft_pnhyper(&S, x, 1.0, 0, sc);                                     \
		   if (p < (alpha))      { r.mode = 2; r.target = (alpha); dst = ft_zeroin(0, 1, ft_rootf, &r, FT_TOL, 1000); } \
		   else if (p > (alpha)) { r.mode = 3; r.target = (alpha); dst = 1.0 / ft_zeroin(FT_EPS, 1, ft_rootf, &r, FT_TOL, 1000); } \
		   else dst = 1.0; } } while (0)

	if      (!strcmp(alt, "less"))    { clo = 0.0;            FT_NCP_U(1 - conf, chi); }
	else if (!strcmp(alt, "greater")) { FT_NCP_L(1 - conf, clo); chi = INFINITY; }
	else { NV al = (1 - conf) / 2; FT_NCP_L(al, clo); FT_NCP_U(al, chi); }

	*lop = clo; *hip = chi;
	Safefree(sc); ft_free(&S);
}

// small helper: fetch a nonnegative integer cell from an SV, with validation
static long ft_cell(pTHX_ SV *sv, const char *what) {
	if (!sv || !SvOK(sv)) croak("fisher_test: %s is undef", what);
	if (!looks_like_number(sv)) croak("fisher_test: %s is not a number", what);
	IV v = SvIV(sv);
	if (v < 0) croak("fisher_test: %s must be nonnegative (got %" IVdf ")", what, v);
	return (long)v;
}

/*Helpers for lm Linear Regression: OLS Matrix Math & Formula Parsing
 * -----------------------------------------------------------------------
 Sweep operator for symmetric positive-definite matrices (e.g., XtX).
 This gracefully handles collinearity by bypassing aliased columns.
 Utilizes a relative tolerance check to prevent dropping micro-variance features.*/
static int sweep_matrix_ols(NV *restrict A, size_t n, bool *restrict aliased) {
	int rank = 0;
	NV *restrict orig_diag = (NV*)safemalloc(n * sizeof(NV));
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
		NV pivot = 1.0 / A[k * n + k];
		A[k * n + k] = 1.0;
		for (size_t j = 0; j < n; j++) A[k * n + j] *= pivot;
		for (size_t i = 0; i < n; i++) {
			if (i != k && A[i * n + k] != 0.0) {
				  NV factor = A[i * n + k];
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
static NV get_data_value(pTHX_ HV *restrict data_hoa, HV **restrict row_hashes, unsigned int i, const char *restrict var) {
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
static NV evaluate_term(pTHX_ HV *restrict data_hoa, HV **restrict row_hashes, unsigned int i, const char *restrict term) {
	if (!term || term[0] == '\0') return NAN;

	char *restrict term_cpy = savepv(term); 
	char *restrict colon = strchr(term_cpy, ':');
	if (colon) {
		*colon = '\0';
		NV left = evaluate_term(aTHX_ data_hoa, row_hashes, i, term_cpy);
		NV right = evaluate_term(aTHX_ data_hoa, row_hashes, i, colon + 1);
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
		NV v = get_data_value(aTHX_ data_hoa, row_hashes, i, inner);
		Safefree(term_cpy); 

		if (isnan(v)) return NAN;
		return power == 1 ? v : pow(v, power);
	}
	NV result = get_data_value(aTHX_ data_hoa, row_hashes, i, term_cpy);
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
	NV p;
	size_t orig_idx;
} PVal;

// Comparator for qsort
static int cmp_pval(const void *restrict a, const void *restrict b) {
	NV diff = ((PVal*)a)->p - ((PVal*)b)->p;
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
	NV val;
	size_t idx;
} RankItem;

static int cmp_rank_item(const void *restrict a, const void *restrict b) {
	NV diff = ((RankItem*)a)->val - ((RankItem*)b)->val;
	if (diff < 0) return -1;
	if (diff > 0) return  1;
	return 0;
}

/* Compute 1-based average ranks with tie-breaking into out[].
 * in[] is not modified.                                                 */
static void rank_data(const NV *restrict in, NV *restrict out, size_t n) {
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
		NV avg = (NV)(i + j) / 2.0 + 1.0;
		for (size_t k = i; k <= j; k++) out[ri[k].idx] = avg;
		i = j + 1;
	}
	Safefree(ri);
}

/* Pearson product-moment r between two n-element arrays.
 * Returns NAN when either variable has zero variance (matches R).       */
static NV pearson_corr(const NV *restrict x, const NV *restrict y, size_t n) {
	NV sx = 0, sy = 0, sxy = 0, sx2 = 0, sy2 = 0;
	for (size_t i = 0; i < n; i++) {
	  sx  += x[i];     sy  += y[i];
	  sxy += x[i]*y[i]; sx2 += x[i]*x[i]; sy2 += y[i]*y[i];
	}
	NV num = (NV)n * sxy - sx * sy;
	NV den = sqrt(((NV)n * sx2 - sx*sx) * ((NV)n * sy2 - sy*sy));
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
static NV kendall_tau_b(const NV *restrict x, const NV *restrict y, unsigned int n) {
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
	NV denom = sqrt((NV)(C + D + tie_x) * (NV)(C + D + tie_y));
	if (denom == 0.0) return NAN;
	return (NV)(C - D) / denom;
}

/* Single dispatch: compute correlation according to method string.
 * Allocates and frees temporary rank arrays internally for Spearman.   */
static NV compute_cor(const NV *restrict x, const NV *restrict y,
						   size_t n, const char *restrict method) {
	if (strcmp(method, "spearman") == 0) {
	  NV *restrict rx, *restrict ry;
	  Newx(rx, n, NV); Newx(ry, n, NV);
	  rank_data(x, rx, n);
	  rank_data(y, ry, n);
	  NV r = pearson_corr(rx, ry, n);
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

static NV _incbeta_cf(NV a, NV b, NV x) {
	int m;
	NV aa, c, d, del, h, qab, qam, qap;
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

static NV incbeta(NV a, NV b, NV x) {
	if (x <= 0.0) return 0.0;
	if (x >= 1.0) return 1.0;
	NV bt = exp(lgamma(a + b) - lgamma(a) - lgamma(b) + a * log(x) + b * log(1.0 - x));
	if (x < (a + 1.0) / (a + b + 2.0)) return bt * _incbeta_cf(a, b, x) / a;
	return 1.0 - bt * _incbeta_cf(b, a, 1.0 - x) / b;
}

static NV get_t_pvalue(NV t, NV df, const char*restrict alt) {
	NV x = df / (df + t * t);
	NV prob_2tail = incbeta(df / 2.0, 0.5, x);
	if (strcmp(alt, "less") == 0) return (t < 0) ? 0.5 * prob_2tail : 1.0 - 0.5 * prob_2tail;
	if (strcmp(alt, "greater") == 0) return (t > 0) ? 0.5 * prob_2tail : 1.0 - 0.5 * prob_2tail;
	return prob_2tail;
}

// Bisection algorithm to find the inverse t-distribution (Critical t-value)
static NV qt_tail(NV df, NV p_tail) {
	NV low = 0.0, high = 1.0;
	// Find upper bound
	while (get_t_pvalue(high, df, "greater") > p_tail) {
	  low = high;
	  high *= 2.0;
	  if (high > 1000000.0) break; /* Fallback limit */
	}
	// Bisect to find the root
	for (unsigned short int i = 0; i < 100; i++) {
	  NV mid = (low + high) / 2.0;
	  NV p_mid = get_t_pvalue(mid, df, "greater");
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
	NV da = *(const NV*restrict)a;
	NV db = *(const NV*restrict)b;
	return (da > db) - (da < db);
}
/* Helper to calculate the number of bins using Sturges' formula: log2(n) + 1 */
static size_t calculate_sturges_bins(size_t n) {
	if (n == 0) return 1;
	return (size_t)(log((NV)n) / log(2.0) + 1.0);
}

// Logic for distributing data into bins (Optimized to O(N))
static void compute_hist_logic(NV *restrict x, size_t n, NV *restrict breaks, size_t n_bins, 
 size_t *restrict counts, NV *restrict mids, NV *restrict density) {
	NV total_n = (NV)n;
	NV min_val = breaks[0];
	NV step = (n_bins > 0) ? (breaks[1] - breaks[0]) : 0.0;
	// Initialize counts and compute midpoints
	for (size_t i = 0; i < n_bins; i++) {
	  counts[i] = 0;
	  mids[i] = (breaks[i] + breaks[i+1]) / 2.0;
	}
	// Single O(N) pass to assign elements to bins
	if (step > 0.0) {
		for (size_t j = 0; j < n; j++) {
			NV val = x[j];
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
		NV bin_width = breaks[i+1] - breaks[i];
		if (bin_width > 0) {
			density[i] = (NV)counts[i] / (total_n * bin_width);
		} else {
			density[i] = (n_bins == 1) ? 1.0 : 0.0;
		}
	}
}

// Standard Normal CDF approximation
NV approx_pnorm(NV x) {
	return 0.5 * erfc(-x * 0.70710678118654752440); // 0.707... = 1/sqrt(2)
}
#ifndef M_SQRT1_2
#define M_SQRT1_2 0.70710678118654752440
#endif

/* Macro for exact Wilcoxon 3D array indexing */
#define DP_INDEX(i, j, k, n2, max_u) ((i) * ((n2) + 1) * ((max_u) + 1) + (j) * ((max_u) + 1) + (k))
static NV inverse_normal_cdf(NV p) {
	NV a[4] = {2.50662823884, -18.61500062529, 41.39119773534, -25.44106049637};
	NV b[4] = {-8.47351093090, 23.08336743743, -21.06224101826, 3.13082909833};
	NV c[9] = {0.3374754822726147, 0.9761690190917186, 0.1607979714918209,
		0.0276438810333863, 0.0038405729373609, 0.0003951896511919,
		0.0000321767881768, 0.0000002888167364, 0.0000003960315187};
	NV x, r, y;
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
static NV spearman_exact_pvalue(NV s_obs, size_t n, const char *restrict alt) {
	int *restrict perm = (int*)safemalloc(n * sizeof(int));
	int *restrict c    = (int*)safemalloc(n * sizeof(int));
	for (size_t i = 0; i < n; i++) { perm[i] = i + 1; c[i] = 0; }

	long count_le = 0, count_ge = 0, total = 0;

	#define TALLY_PERM() do {                                    \
	  NV s_ = 0.0;                                     \
	  for (int ii = 0; ii < n; ii++) {                    \
		   NV d_ = (NV)(ii + 1) - (NV)perm[ii];\
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
	NV p_le = (NV)count_le / (NV)total;
	NV p_ge = (NV)count_ge / (NV)total;

	if (strcmp(alt, "greater") == 0) return p_le;
	if (strcmp(alt, "less")    == 0) return p_ge;
	/* two.sided: 2 × the smaller tail, clamped to 1 */
	NV p = 2.0 * (p_le < p_ge ? p_le : p_ge);
	return (p > 1.0) ? 1.0 : p;
}
/* -----------------------------------------------------------------------
 * Exact Kendall p-value via Mahonian Numbers (Inversions distribution)
 * Matches R's behavior for N < 50 without ties.
 * ----------------------------------------------------------------------- */
static NV kendall_exact_pvalue(size_t n, NV s_obs, const char *restrict alt) {
	long max_inv = (long)n * (n - 1) / 2;
	NV *restrict dp = (NV*)safemalloc((max_inv + 1) * sizeof(NV));
	for (long i = 0; i <= max_inv; i++) dp[i] = 0.0;
	dp[0] = 1.0;
	/* Build the distribution of inversions via DP */
	for (size_t i = 2; i <= n; i++) {
		NV *restrict next_dp = (NV*)safemalloc((max_inv + 1) * sizeof(NV));
		for (long k = 0; k <= max_inv; k++) next_dp[k] = 0.0;
		int current_max_inv = i * (i - 1) / 2;
		for (int k = 0; k <= current_max_inv; k++) {
			NV sum = 0;
			for (int j = 0; j <= i - 1 && k - j >= 0; j++) {
				 sum += dp[k - j];
			}
			// Divide by 'i' directly to keep array as pure probabilities and prevent overflow
			next_dp[k] = sum / (NV)i;
		}
		Safefree(dp);
		dp = next_dp;
	}
	// Convert S statistic to target number of inversions
	long i_obs = (long)round((max_inv - s_obs) / 2.0);
	if (i_obs < 0) i_obs = 0;
	if (i_obs > max_inv) i_obs = max_inv;
	NV p_le = 0.0; /* P(S <= S_obs) */
	for (long k = i_obs; k <= max_inv; k++) p_le += dp[k];
	NV p_ge = 0.0; /* P(S >= S_obs) */
	for (long k = 0; k <= i_obs; k++) p_ge += dp[k];
	Safefree(dp);
	if (strcmp(alt, "greater") == 0) return p_ge;
	if (strcmp(alt, "less") == 0) return p_le;
	// two.sided
	NV p = 2.0 * (p_ge < p_le ? p_ge : p_le);
	return p > 1.0 ? 1.0 : p;
}
// F-distribution Cumulative Distribution Function P(F <= f)
static NV pf(NV f, NV df1, NV df2) {
	if (f <= 0.0) return 0.0;
	NV x = (df1 * f) / (df1 * f + df2);
	return incbeta(df1 / 2.0, df2 / 2.0, x);
}

/* Householder QR Decomposition for Sequential Sums of Squares */
/* Householder QR Decomposition for Sequential Sums of Squares */
static void apply_householder_aov(NV** restrict X, NV* restrict y, size_t n, size_t p, bool* restrict aliased, size_t* restrict rank_map) {
	size_t r = 0; // Rank/Row tracker
	for (size_t k = 0; k < p; k++) {
		aliased[k] = FALSE;
		if (r >= n) {
			aliased[k] = TRUE;
			continue;
		}

		NV max_val = 0;
		for (size_t i = r; i < n; i++) {
			if (fabs(X[i][k]) > max_val) max_val = fabs(X[i][k]);
		}
		if (max_val < 1e-10) { 
			aliased[k] = TRUE; 
			continue; 
		} // Collinear or zero column

		NV norm = 0;
		for (size_t i = r; i < n; i++) {
			X[i][k] /= max_val;
			norm += X[i][k] * X[i][k];
		}
		norm = sqrt(norm);
		NV s = (X[r][k] > 0) ? -norm : norm;
		NV u1 = X[r][k] - s;
		X[r][k] = s * max_val;

		for (size_t j = k + 1; j < p; j++) {
			NV dot = u1 * X[r][j];
			for (size_t i = r + 1; i < n; i++) dot += X[i][j] * X[i][k];
			NV tau = dot / (s * u1);
			X[r][j] += tau * u1;
			for (size_t i = r + 1; i < n; i++) X[i][j] += tau * X[i][k];
		}

		// Transform the response vector y
		NV dot_y = u1 * y[r];
		for (size_t i = r + 1; i < n; i++) dot_y += y[i] * X[i][k];
		NV tau_y = dot_y / (s * u1);
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

/* ---------------------------------------------------------------------------
 * print_string_row: emit one record.
 *
 * Quoting contract (matches the behaviors your tests pin down):
 *	- A field is quoted IFF it contains the separator string, a double
 *	  quote, or a newline / carriage return. Quoting is per-field, so in a
 *	  TSV "hello,world" stays bare while "tab\tin" becomes "tab	in".
 *	- Inside a quoted field, embedded double quotes are doubled:
 *	  p"q -> "p""q"   (RFC 4180 style)
 *	- A NULL or zero-length field prints as NOTHING between separators:
 *	  a,,c  -- never '' or "". A zero-length field cannot contain a
 *	  separator, quote, or newline, so it never needs quoting.
 *	- The separator is treated as a string (strstr), so multi-character
 *	  separators work; an empty separator never triggers quoting.
 *
 * Returns nothing; I/O errors surface on PerlIO_close at the call site.
*/
static void print_string_row(pTHX_ PerlIO *restrict fh,
	const char **restrict fields, size_t n, const char *restrict sep)
{
	const size_t sep_len = sep ? strlen(sep) : 0;
	for (size_t i = 0; i < n; i++) {
		if (i && sep_len) PerlIO_write(fh, sep, sep_len);
		const char *restrict f = fields[i];
		if (!f || !*f) continue; /* undef/empty -> print nothing */
		/* Does this field need quoting? */
		bool need_quotes = 0;
		if (strchr(f, '"') || strchr(f, '\n') || strchr(f, '\r')) {
			need_quotes = 1;
		} else if (sep_len && strstr(f, sep)) {
			need_quotes = 1;
		}
		if (!need_quotes) {
			PerlIO_write(fh, f, strlen(f));
		} else {
			PerlIO_putc(fh, '"');
			for (const char *restrict p = f; *p; p++) {
				if (*p == '"') PerlIO_putc(fh, '"'); /* double it */
				PerlIO_putc(fh, *p);
			}
			PerlIO_putc(fh, '"');
		}
	}
	PerlIO_putc(fh, '\n');
}

// Calculates the Regularized Upper Incomplete Gamma Function Q(a, x)
// This perfectly replicates R's pchisq(..., lower.tail=FALSE)
NV igamc(NV a, NV x) {
	if (x < 0.0 || a <= 0.0) return 1.0;
	if (x == 0.0) return 1.0;

	// Series expansion for x < a + 1
	if (x < a + 1.0) {
		NV sum = 1.0 / a;
		NV term = 1.0 / a;
		NV n = 1.0;
		while (fabs(term) > 1e-15) {
			term *= x / (a + n);
			sum += term;
			n += 1.0;
		}
		return 1.0 - (sum * exp(-x + a * log(x) - lgamma(a)));
	}

	// Continued fraction for x >= a + 1
	NV b = x + 1.0 - a;
	NV c = 1.0 / 1e-30;
	NV d = 1.0 / b;
	NV h = d, i = 1.0;
	while (i < 10000) { // Safety bound
		NV an = -i * (i - a);
		b += 2.0;
		d = an * d + b;
		if (fabs(d) < 1e-30) d = 1e-30;
		c = b + an / c;
		if (fabs(c) < 1e-30) c = 1e-30;
		d = 1.0 / d;
		NV del = d * c;
		h *= del;
		if (fabs(del - 1.0) < 1e-15) break;
		i += 1.0;
	}
	return h * exp(-x + a * log(x) - lgamma(a));
}

// Chi-Squared p-value is simply the Incomplete Gamma of (df/2, stat/2)
NV get_p_value(NV stat, int df) {
	if (df <= 0) return 1.0;
	if (stat <= 0.0) return 1.0;
	return igamc((NV)df / 2.0, stat / 2.0);
}

#ifndef M_SQRT1_2
#define M_SQRT1_2 0.70710678118654752440
#endif

// Robust Binomial Coefficient using long double
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
static NV exact_pwilcox(NV q, int m, int n) {
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
	NV result = (NV)(cum_p / total);

	Safefree(w);
	return result;
}

/* Exact CDF for Wilcoxon Signed Rank: P(V <= q)
   Subset-sum DP, same recurrence as R's csignrank.
   Portable: no long-double libm calls (powl/ldexpl/expl), which are
   absent on some platforms (e.g. older FreeBSD). 2^n is built exactly
   by repeated doubling — exact in any radix-2 float format. */
static NV exact_psignrank(NV q, size_t n) {
	long k = (long)floor(q + 1e-7);          /* signed: negative q is a valid sentinel */
	if (k < 0) return 0.0;
	size_t max_v = n * (n + 1) / 2;
	if ((size_t)k >= max_v) return 1.0;

	long double *restrict w = (long double *)safecalloc(max_v + 1, sizeof(long double));
	w[0] = 1.0L;
	for (size_t i = 1; i <= n; i++)
		for (size_t j = max_v; j >= i; j--)
			w[j] += w[j - i];

	long double cum_p = 0.0L;
	for (size_t v = 0; v <= (size_t)k; v++) cum_p += w[v];

	long double total = 1.0L;                /* 2^n, exact, zero libm dependency */
	for (size_t i = 0; i < n; i++) total *= 2.0L;

	NV result = (NV)(cum_p / total);
	Safefree(w);
	return result;
}

static int cmp_rank_info(const void *a, const void *b) {
	NV da = ((const RankInfo*)a)->val;
	NV db = ((const RankInfo*)b)->val;
	return (da > db) - (da < db);
}

static NV rank_and_count_ties(RankInfo *restrict ri, size_t n, bool *restrict has_ties) {
	if (n == 0) return 0.0;
	qsort(ri, n, sizeof(RankInfo), cmp_rank_info);
	size_t i = 0;
	NV tie_adj = 0.0;
	*has_ties = 0;
	while (i < n) {
		size_t j = i + 1;
		while (j < n && ri[j].val == ri[i].val) j++;
		NV r = (NV)(i + 1 + j) / 2.0; 
		for (size_t k = i; k < j; k++) ri[k].rank = r;
		size_t t = j - i;
		if (t > 1) { *has_ties = 1; tie_adj += ((NV)t * t * t - t); }
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
static NV r_pow_di(NV x, int n) {
	if (n == 0) return 1.0;
	if (n < 0) return 1.0 / r_pow_di(x, -n);
	NV val = 1.0;
	for (int i = 0; i < n; i++) val *= x;
	return val;
}

// Two-sample two-sided asymptotic distribution
static NV K2l(NV x, int lower, NV tol) {
	NV s, z, p;
	int k;
	if(x <= 0.) {
	  if(lower) p = 0.;
	  else p = 1.;
	} else if(x < 1.) {
	  int k_max = (int) sqrt(2.0 - log(tol));
	  NV w = log(x);
	  z = - (M_PI_2 * M_PI_4) / (x * x);
	  s = 0;
	  for(k = 1; k < k_max; k += 2) {
		   s += exp(k * k * z - w);
	  }
	  p = s / M_1_SQRT_2PI;
	  if(!lower) p = 1.0 - p;
	} else {
	  NV new_val, old_val;
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
static void m_multiply(NV *A, NV *B, NV *C, unsigned int m) {
	for(unsigned int i = 0; i < m; i++) {
	  for(unsigned int j = 0; j < m; j++) {
		   NV s = 0.;
		   for(unsigned int k = 0; k < m; k++) s += A[i * m + k] * B[k * m + j];
		   C[i * m + j] = s;
	  }
	}
}

static void m_power(NV *A, int eA, NV *V, int *eV, int m, int n) {
	if(n == 1) {
	  for(int i = 0; i < m * m; i++) V[i] = A[i];
	  *eV = eA;
	  return;
	}
	m_power(A, eA, V, eV, m, n / 2);
	NV *restrict B = (NV*) safecalloc(m * m, sizeof(NV));
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
static NV K2x(int n, NV d) {
	int k = (int) (n * d) + 1;
	int m = 2 * k - 1;
	NV h = k - n * d;
	NV *restrict H = (NV*) safecalloc(m * m, sizeof(NV));
	NV *restrict Q = (NV*) safecalloc(m * m, sizeof(NV));

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
	NV s = Q[(k - 1) * m + k - 1];

	for(int i = 1; i <= n; i++) {
	  s = s * (NV)i / (NV)n;
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
/* One comparator, used by every qsort below. Branch form avoids overflow that
 * a subtraction-based comparator would hit, and is correct for any NV width. */
static int compare_NVs(const void *a, const void *b) {
    NV x = *(const NV *)a, y = *(const NV *)b;
    return (x > y) - (x < y);
}
/* Largest m*n for which we will run the exact DP even when exact=>1 is forced.
 * Time is O(m*n); memory is O(min(m,n)). Beyond this we warn and go asymptotic. */
#define KS_EXACT_MAX_PRODUCT 10000000.0
static void calc_2sample_stats(NV *x, size_t nx, NV *y, size_t ny,
                               NV *d, NV *d_plus, NV *d_minus) {
    qsort(x, nx, sizeof(NV), compare_NVs);
    qsort(y, ny, sizeof(NV), compare_NVs);
    NV max_d = 0.0, max_d_plus = 0.0, max_d_minus = 0.0;
    size_t i = 0, j = 0;
    while (i < nx || j < ny) {
        NV val;
        if (i < nx && j < ny) val = (x[i] < y[j]) ? x[i] : y[j];
        else if (i < nx)      val = x[i];
        else                  val = y[j];
        while (i < nx && x[i] <= val) i++;
        while (j < ny && y[j] <= val) j++;
        NV cdf1 = (NV)i / nx;
        NV cdf2 = (NV)j / ny;
        NV diff = cdf1 - cdf2;
        if (diff > max_d_plus)  max_d_plus  = diff;
        if (-diff > max_d_minus) max_d_minus = -diff;
        if (fabs(diff) > max_d)  max_d = fabs(diff);
    }
    *d = max_d; *d_plus = max_d_plus; *d_minus = max_d_minus;
}

static int psmirnov_exact_test(NV q, NV r, NV s, int two_sided) {
    if (two_sided) return (fabs(r - s) >= q);
    return ((r - s) >= q);
}

// Evaluate the exact 2-sample probability
static NV psmirnov_exact_uniq_upper(NV q, size_t m, size_t n, int two_sided) {
	NV md = (NV) m, nd = (NV) n;
	NV *u = (NV *) safemalloc((n + 1) * sizeof(NV)); /* malloc + full init below */
	u[0] = 0.;
	for (size_t j = 1; j <= n; j++)
	  u[j] = psmirnov_exact_test(q, 0., j / nd, two_sided) ? 1. : u[j - 1];
	for (size_t i = 1; i <= m; i++) {
	  if (psmirnov_exact_test(q, i / md, 0., two_sided)) u[0] = 1.;
	  for (size_t j = 1; j <= n; j++) {
		   if (psmirnov_exact_test(q, i / md, j / nd, two_sided)) u[j] = 1.;
		   else {
		       NV v = (NV)(i) / (NV)(i + j);
		       NV w = (NV)(j) / (NV)(i + j);
		       u[j] = v * u[j] + w * u[j - 1];
		   }
	  }
	}
	NV res = u[n];
	Safefree(u);
	return res;
}

static NV p_body(NV n, NV delta, NV sd, NV sig_level, int tsample, int tside, bool strict) {
	NV nu = (n - 1.0) * (NV)tsample;
	if (nu < 1e-7) nu = 1e-7; 

	// Ensure sig_level/tside is not truncated
	NV p_tail = sig_level / (NV)tside;
	NV qu = qt_tail(nu, p_tail); // qt(p, df, lower.tail=FALSE)

	NV ncp = sqrt(n / (NV)tsample) * (delta / sd);

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
static NV qf_bisection(NV p, NV df1, NV df2) {
	if (p <= 0.0) return 0.0;
	if (p >= 1.0) return INFINITY;
	NV low = 0.0, high = 1.0;
	// Find upper bound
	while (pf(high, df1, df2) < p) {
	  low = high;
	  high *= 2.0;
	  if (high > 1e100) break; /* Fallback limit */
	}

	// Bisect to find the root
	for (unsigned short int i = 0; i < 150; i++) {
		NV mid = low + (high - low) / 2.0;
		NV p_mid = pf(mid, df1, df2);

		if (p_mid < p) {
			low = mid;
		} else {
			high = mid;
		}
		if (high - low < 1e-12) break;
	}
	return (low + high) / 2.0;
}

typedef struct {
	NV  statistic;
	NV  num_df;
	NV  denom_df;
	NV  p_value;
	NV  ss_between;  /* between-group sum of squares  */
	NV  ss_within;   /* within-group  sum of squares  */
	NV  ms_between;  /* ss_between / num_df           */
	NV  ms_within;   /* ss_within  / denom_df         */
	int     k;           /* number of groups              */
	IV      n;           /* total observations            */
	bool     var_equal;   /* 0 = Welch, 1 = classic        */
} OneWayResult;

static OneWayResult
c_oneway_test(const NV *restrict data, const size_t *restrict sizes,
			  size_t k, bool var_equal)
{
	OneWayResult res;
	res.var_equal = var_equal;
	res.k         = (int)k;

	NV *restrict n_i = (NV *)safemalloc(k * sizeof(NV));
	NV *restrict m_i = (NV *)safemalloc(k * sizeof(NV));
	NV *restrict v_i = (NV *)safemalloc(k * sizeof(NV));
	size_t offset = 0;
	IV total_n = 0;
	for (size_t g = 0; g < k; g++) {
	  size_t ng  = sizes[g];
	  n_i[g]     = (NV)ng;
	  total_n   += (IV)ng;
	  NV sum = 0.0;
	  for (size_t i = 0; i < ng; i++) sum += data[offset + i];
	  NV mean = sum / (NV)ng;
	  m_i[g] = mean;

	  NV ss = 0.0;
	  for (size_t i = 0; i < ng; i++) {
		   NV d = data[offset + i] - mean;
		   ss += d * d;
	  }
	  v_i[g] = ss / (NV)(ng - 1);   /* ng >= 2 guaranteed by caller */
	  offset += ng;
	}
	res.n = total_n;
	// grand mean (simple average over all obs; used only by classic branch)/
	NV grand_mean = 0.0;
	for (IV i = 0; i < (IV)total_n; i++) grand_mean += data[i];
	grand_mean /= (NV)total_n;

	NV df1 = (NV)(k - 1);

	if (var_equal) {/* ── Classic one-way ANOVA
		*  F = [Σ n_i·(m_i − ȳ)² / (k−1)]  /  [Σ (n_i−1)·v_i / (n−k)] */
		NV ssbg = 0.0, sswg = 0.0;
		for (size_t g = 0; g < k; g++) {
			NV dm = m_i[g] - grand_mean;
			ssbg += n_i[g] * dm * dm;
			sswg += (n_i[g] - 1.0) * v_i[g];
		}
		NV df2    = (NV)(total_n - (IV)k);
		res.statistic = (ssbg / df1) / (sswg / df2);
		res.num_df    = df1;
		res.denom_df  = df2;
		res.ss_between = ssbg;
		res.ss_within  = sswg;
		res.ms_between = ssbg / df1;
		res.ms_within  = sswg / df2;
	} else {// ── Welch one-way (heteroscedastic)
		NV *restrict w_i = (NV *)safemalloc(k * sizeof(NV));
		NV sum_w = 0.0;
		for (size_t g = 0; g < k; g++) { w_i[g] = n_i[g] / v_i[g]; sum_w += w_i[g]; }
		NV wgrand = 0.0;
		for (size_t g = 0; g < k; g++) wgrand += w_i[g] * m_i[g];
		wgrand /= sum_w;
		NV tmp = 0.0;
		for (size_t g = 0; g < k; g++) {
			NV t = 1.0 - w_i[g] / sum_w;
			tmp += (t * t) / (n_i[g] - 1.0);
		}
		tmp /= ((NV)k * (NV)k - 1.0);   /* k² − 1 */
		NV num = 0.0;
		for (size_t g = 0; g < k; g++) {
			NV dm = m_i[g] - wgrand;
			num += w_i[g] * dm * dm;
		}
		res.statistic = num / (df1 * (1.0 + 2.0 * (NV)(k - 2) * tmp));
		res.num_df    = df1;
		res.denom_df  = (tmp > 0.0) ? (1.0 / (3.0 * tmp)) : 1e300;
		/* unweighted SS for the output table */
		NV ssbg = 0.0, sswg = 0.0;
		for (size_t g = 0; g < k; g++) {
			NV dm = m_i[g] - grand_mean;
			ssbg += n_i[g] * dm * dm;
			sswg += (n_i[g] - 1.0) * v_i[g];
		}
		res.ss_between = ssbg;
		res.ss_within  = sswg;
		res.ms_between = (df1  > 0.0) ? ssbg / df1          : 0.0;
		res.ms_within  = (res.denom_df > 0.0) ? sswg / res.denom_df : 0.0;
		Safefree(w_i);
	}
	// upper-tail p-value  P(F ≥ statistic)
	res.p_value = 1 - pf(res.statistic, res.num_df, res.denom_df);
	Safefree(n_i);    Safefree(m_i);    Safefree(v_i);
	return res;
}

/* ── parse_formula
 *
 *  Splits "response ~ factor" into two NUL-terminated, heap-allocated
 *  strings.  Leading/trailing whitespace is stripped from each side.
 *  Returns 1 on success, 0 on failure (malformed / missing '~').
 *  Caller must Safefree() both *lhs and *rhs on success. */
static int
parse_formula(const char *formula, char **lhs, char **rhs)
{
	const char *restrict tilde = strchr(formula, '~');
	if (!tilde) return 0;

	// left-hand side: trim trailing whitespace
	const char *restrict l_start = formula;
	const char *restrict l_end   = tilde - 1;
	while (l_end >= l_start && isspace((unsigned char)*l_end)) l_end--;
	if (l_end < l_start) return 0; /* empty LHS */

	// right-hand side: trim leading whitespace */
	const char *restrict r_start = tilde + 1;
	while (*r_start && isspace((unsigned char)*r_start)) r_start++;
	const char *restrict r_end = r_start + strlen(r_start) - 1;
	while (r_end >= r_start && isspace((unsigned char)*r_end)) r_end--;
	if (r_end < r_start) return 0; /* empty RHS */

	size_t llen = (size_t)(l_end - l_start + 1);
	size_t rlen = (size_t)(r_end - r_start + 1);

	*lhs = (char *)safemalloc(llen + 1);
	*rhs = (char *)safemalloc(rlen + 1);
	memcpy(*lhs, l_start, llen); (*lhs)[llen] = '\0';
	memcpy(*rhs, r_start, rlen); (*rhs)[rlen] = '\0';
	return 1;
}

/* ── build_groups_from_formula ───────────────
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

static int build_groups_from_formula(pTHX_
	AV *restrict response_av,
	AV *restrict label_av,
	NV *restrict out_flat,
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
	  SV **restrict lsv = av_fetch(label_av, i, 0);
	  const char *restrict label = (lsv && *lsv) ? SvPV_nolen(*lsv) : "";
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
	/* ── fill flat output array in group order *
	*  We compute a running write-offset per group, then scatter*/
	size_t *restrict write_pos = (size_t *)safemalloc(ngroups * sizeof(size_t));
	write_pos[0] = 0;
	for (size_t g = 1; g < ngroups; g++)
	  write_pos[g] = write_pos[g - 1] + out_sizes[g - 1];
	for (IV i = 0; i < n; i++) {
	  SV **restrict rsv = av_fetch(response_av, i, 0);
	  NV val = (rsv && *rsv) ? SvNV(*rsv) : 0.0;
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
*/
static NV c_dnorm(NV x, NV mu, NV sigma, int give_log) {
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
	// Naive formula for standard bodies
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
	NV x1 = ldexp(trunc(ldexp(x, 16)), -16);
	NV x2 = x - x1;
	return (M_1_SQRT_2PI / sigma) * (exp(-0.5 * x1 * x1) * exp((-0.5 * x2 - x1) * x2));
}
/*Helper for prcomp: Jacobi Eigenvalue Algorithm for Symmetric Matrices
 * Used to compute the eigendecomposition of the X^T X covariance matrix.*/
static void jacobi_eigen(NV *restrict A, size_t n, NV *restrict d, NV *restrict v) {
	for (size_t i = 0; i < n; i++) {
	  for (size_t j = 0; j < n; j++) v[i * n + j] = (i == j) ? 1.0 : 0.0;
	  d[i] = A[i * n + i];
	}
	NV *restrict b = (NV*)safemalloc(n * sizeof(NV));
	NV *restrict z = (NV*)safemalloc(n * sizeof(NV));
	for (size_t i = 0; i < n; i++) { b[i] = d[i]; z[i] = 0.0; }
	for (int iter = 1; iter <= 50; iter++) {
		NV sm = 0.0;
		for (size_t i = 0; i < n - 1; i++) {
			for (size_t j = i + 1; j < n; j++) sm += fabs(A[i * n + j]);
		}
		if (sm == 0.0) break;
		NV tresh = (iter < 4) ? 0.2 * sm / (n * n) : 0.0;
		for (size_t i = 0; i < n - 1; i++) {
			for (size_t j = i + 1; j < n; j++) {
				NV g = 100.0 * fabs(A[i * n + j]);
				if (iter > 4 && fabs(d[i]) + g == fabs(d[i]) && fabs(d[j]) + g == fabs(d[j])) {
					A[i * n + j] = 0.0;
				} else if (fabs(A[i * n + j]) > tresh) {
					NV h = d[j] - d[i];
					NV t;
					if (fabs(h) + g == fabs(h)) {
						t = A[i * n + j] / h;
					} else {
						NV theta = 0.5 * h / A[i * n + j];
						t = 1.0 / (fabs(theta) + sqrt(1.0 + theta * theta));
						if (theta < 0.0) t = -t;
					}
					NV c = 1.0 / sqrt(1.0 + t * t);
					NV s = t * c;
					NV tau = s / (1.0 + c);
					NV h_t = t * A[i * n + j];
					z[i] -= h_t;
					z[j] += h_t;
					d[i] -= h_t;
					d[j] += h_t;
					A[i * n + j] = 0.0;
					for (size_t k = 0; k < i; k++) {
						g = A[k * n + i]; NV h_val = A[k * n + j];
						A[k * n + i] = g - s * (h_val + g * tau);
						A[k * n + j] = h_val + s * (g - h_val * tau);
					}
					for (size_t k = i + 1; k < j; k++) {
						g = A[i * n + k]; NV h_val = A[k * n + j];
						A[i * n + k] = g - s * (h_val + g * tau);
						A[k * n + j] = h_val + s * (g - h_val * tau);
					}
					for (size_t k = j + 1; k < n; k++) {
						g = A[i * n + k]; NV h_val = A[j * n + k];
						A[i * n + k] = g - s * (h_val + g * tau);
						A[j * n + k] = h_val + s * (g - h_val * tau);
					}
					for (size_t k = 0; k < n; k++) {
						g = v[k * n + i]; NV h_val = v[k * n + j];
						v[k * n + i] = g - s * (h_val + g * tau);
						v[k * n + j] = h_val + s * (g - h_val * tau);
					}
				}
			}
		}
		for (size_t i = 0; i < n; i++) {
			b[i] += z[i];
			d[i] = b[i];
			z[i] = 0.0;
		}
	}
	Safefree(b); Safefree(z);
	// Sort eigenvalues and corresponding eigenvectors in descending order
	for (size_t i = 0; i < n - 1; i++) {
		size_t max_k = i;
		NV max_val = d[i];
		for (size_t j = i + 1; j < n; j++) {
			if (d[j] > max_val) {
				 max_val = d[j];
				 max_k = j;
			}
		}
		if (max_k != i) {
			d[max_k] = d[i];
			d[i] = max_val;
			for (size_t k = 0; k < n; k++) {
				 NV tmp = v[k * n + i];
				 v[k * n + i] = v[k * n + max_k];
				 v[k * n + max_k] = tmp;
			}
		}
	}
}

// --- pull a numeric value out of an SV* slot
static int c2c_num(pTHX_ SV **restrict ep, NV *restrict out) {
	if (ep && *ep && SvOK(*ep) && looks_like_number(*ep)) {
		*out = SvNV(*ep);
		return 1;
	}
	return 0;
}

static SV* c2c_call(pTHX_ SV *restrict cv, SV *restrict rv1, SV *restrict rv2) {
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	EXTEND(SP, 2);
	PUSHs(rv1);
	PUSHs(rv2);
	PUTBACK;
	unsigned int count = call_sv(cv, G_SCALAR);
	SPAGAIN;
	SV *restrict ret = (count > 0) ? newSVsv(POPs) : newSV(0);
	PUTBACK;
	FREETMPS;
	LEAVE;
	return ret;
}
// Mark col_names[idx] whose name equals (wname,wl) as an outer column; returns
// 1 if a matching column was found, 0 otherwise.
static int c2c_mark(SV **col_names, STRLEN *name_len, size_t ncols, const char *wname, STRLEN wl, char *is_outer) {
	for (size_t cc = 0; cc < ncols; cc++) {
		if (name_len[cc] == wl && memEQ(SvPVX(col_names[cc]), wname, wl)) { is_outer[cc] = 1; return 1; }
	}
	return 0;
}
//
// filter() helpers — place this block in the C section, ABOVE the MODULE line
//
// Resolve the cell SV for a column in the "current row".
//   AoH: current row is row_hv         -> hv_fetch(row_hv, col)
//   HoA: current row is index idx      -> hv_fetch(data_hv,col) -> AV -> av_fetch(idx)
typedef struct {
	int is_aoh;
	HV *restrict row_hv;
	HV *restrict data_hv;
	SSize_t idx;
} filt_ctx;
static SV* filt_cell(pTHX_ filt_ctx *restrict ctx, const char *restrict col, STRLEN clen) {
	if (ctx->is_aoh) {
		SV **restrict p = hv_fetch(ctx->row_hv, col, clen, 0);
		return (p && *p) ? *p : NULL;
	}
	SV **restrict cp = hv_fetch(ctx->data_hv, col, clen, 0);
	if (!cp || !*cp || !SvROK(*cp) || SvTYPE(SvRV(*cp)) != SVt_PVAV) return NULL;
	SV **restrict vp = av_fetch((AV*)SvRV(*cp), ctx->idx, 0);
	return (vp && *vp) ? *vp : NULL;
}
// Recursively interpret a Stats::LikeR::Pred tree against the current row.
static bool filt_eval(pTHX_ SV *restrict pred, filt_ctx *restrict ctx) {
	if (!pred || !SvROK(pred) || SvTYPE(SvRV(pred)) != SVt_PVHV)
		croak("filter: malformed predicate (expected an object built with col())");
	HV *restrict h = (HV*)SvRV(pred);
	SV **restrict opp = hv_fetchs(h, "op", 0);
	if (!opp || !*opp) croak("filter: predicate node missing 'op'");
	const char *restrict op = SvPV_nolen(*opp);
	if (strEQ(op, "and") || strEQ(op, "or")) {
		SV **restrict lp = hv_fetchs(h, "l", 0);
		SV **restrict rp = hv_fetchs(h, "r", 0);
		bool L = filt_eval(aTHX_ (lp ? *lp : NULL), ctx);
		if (op[0] == 'a') return L ? filt_eval(aTHX_ (rp ? *rp : NULL), ctx) : 0; // and
		return L ? 1 : filt_eval(aTHX_ (rp ? *rp : NULL), ctx);                   // or
	}
	if (strEQ(op, "not")) {
		SV **restrict lp = hv_fetchs(h, "l", 0);
		return !filt_eval(aTHX_ (lp ? *lp : NULL), ctx);
	}
	SV **restrict cp = hv_fetchs(h, "col", 0);
	SV **restrict vp = hv_fetchs(h, "val", 0);
	if (!cp || !*cp) croak("filter: comparison node missing 'col'");
	STRLEN clen;
	const char *restrict col = SvPV(*cp, clen);
	SV *restrict cell = filt_cell(aTHX_ ctx, col, clen);
	if (!cell || !SvOK(cell)) return 0; // missing / undef cell never matches
	SV *restrict val = (vp && *vp) ? *vp : &PL_sv_undef;
	if (strEQ(op, ">"))  return SvNV(cell) >  SvNV(val);
	if (strEQ(op, "<"))  return SvNV(cell) <  SvNV(val);
	if (strEQ(op, ">=")) return SvNV(cell) >= SvNV(val);
	if (strEQ(op, "<=")) return SvNV(cell) <= SvNV(val);
	if (strEQ(op, "==")) return SvNV(cell) == SvNV(val);
	if (strEQ(op, "!=")) return SvNV(cell) != SvNV(val);
	{
		STRLEN al, bl;
		const char *restrict a = SvPV(cell, al);
		const char *restrict b = SvPV(val, bl);
		STRLEN m = al < bl ? al : bl;
		int c = m ? memcmp(a, b, m) : 0;
		if (c == 0) c = (al > bl) - (al < bl);
		if (strEQ(op, "eq")) return c == 0;
		if (strEQ(op, "ne")) return c != 0;
		if (strEQ(op, "lt")) return c <  0;
		if (strEQ(op, "gt")) return c >  0;
		if (strEQ(op, "le")) return c <= 0;
		if (strEQ(op, "ge")) return c >= 0;
	}
	croak("filter: unknown operator '%s' in predicate", op);
	return 0; // not reached
}
// Call a coderef predicate with $_ (and $_[0]) set to the row hashref.
static bool filt_call(pTHX_ SV *restrict cv, SV *restrict row) {
	dSP;
	bool keep;
	int n;
	ENTER; SAVETMPS;
	SAVE_DEFSV;
	DEFSV_set(row);
	PUSHMARK(SP);
	EXTEND(SP, 1);
	PUSHs(row);
	PUTBACK;
	n = call_sv(cv, G_SCALAR);
	SPAGAIN;
	keep = (n > 0) ? (bool)SvTRUE(TOPs) : 0;
	if (n > 0) (void)POPs;
	PUTBACK;
	FREETMPS; LEAVE;
	return keep;
}

static int h2h_keycmp(const void *pa, const void *pb) {
	dTHX;
	SV *restrict const *a = (SV * const *)pa;
	SV *restrict const *b = (SV * const *)pb;
	return sv_cmp(*a, *b);
}
// Call a column predicate as $cv->($col_values, $col_name) and return its truth.
// $col_values is an array ref of the column's DEFINED cells; $col_name is the
// column key. Used so a block like sub { sd($_[0]) == 0 } can pick columns out.
static bool cf_pred(pTHX_ SV *cv_sv, AV *a_av, AV *b_av, SV *name_sv) {
	dSP;
	bool truth = FALSE;
	int count;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newRV_inc((SV*)a_av)));
	if (b_av) XPUSHs(sv_2mortal(newRV_inc((SV*)b_av)));
	XPUSHs(sv_2mortal(newSVsv(name_sv)));
	PUTBACK;
	count = call_sv(cv_sv, G_SCALAR);
	SPAGAIN;
	if (count > 0) {
		SV *restrict ret = POPs;        // POPs has a side effect: pop exactly once,
		truth = cBOOL(SvTRUE(ret));     // because SvTRUE() may evaluate its arg twice.
	}
	PUTBACK;
	FREETMPS;
	LEAVE;
	return truth;
}
/* ---------------------------------------------------------------------------
 * Helpers for _parse_csv_file. Place in the C section of the .xs file
 * (above the first MODULE line).
 * ------------------------------------------------------------------------- */

/* save-stack destructor: closes the input handle on ANY exit, including a
 * croak thrown inside the row callback */
static void S_pclose(pTHX_ void *p)
{
	PerlIO_close((PerlIO*)p);
}

/* Finish the current record: push the pending field, hand the row to the
 * callback (streaming) or to @$data (slurp), and start a fresh row.
 *
 * Ownership: the row AV's single reference is transferred to a MORTAL RV
 * (newRV_noinc + sv_2mortal). On the normal path the inner FREETMPS releases
 * it; if the callback dies, the unwind's FREETMPS releases it just the same.
 * If the callback kept a copy of the ref, that copy bumped the refcount and
 * the row survives for the caller -- exactly the old semantics, minus the
 * leak and minus one SvREFCNT_dec per row. */
static void S_emit_row(pTHX_ AV **rowp, SV *field, bool use_cb, SV *callback, AV *data)
{
	av_push(*rowp, newSVsv(field));
	sv_setpvs(field, "");
	if (use_cb) {
		AV *restrict row = *rowp;
		*rowp = NULL;	/* ownership leaves this function NOW */
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		XPUSHs(sv_2mortal(newRV_noinc((SV*)row)));
		PUTBACK;
		call_sv(callback, G_DISCARD);	/* may die: nothing left to leak */
		FREETMPS;
		LEAVE;
	} else {
		av_push(data, newRV_noinc((SV*)*rowp));
		*rowp = NULL;
	}
	*rowp = newAV();
}

static void
lm_append(pTHX_ char **bufp, size_t *lenp, size_t *capp, const char *s)
{
	size_t slen = strlen(s);
	size_t sep  = (*lenp > 0) ? 1 : 0;
	size_t need = *lenp + sep + slen + 1;            /* + NUL */
	if (need > *capp) {
		size_t nc = (*capp > 0) ? *capp : 64;
		while (nc < need) nc *= 2;
		Renew(*bufp, nc, char);
		*capp = nc;
	}
	char *dst = *bufp + *lenp;
	if (sep) *dst++ = '+';
	memcpy(dst, s, slen);
	dst[slen] = '\0';
	*lenp += sep + slen;
}

static int
lm_str_qsort(const void *a, const void *b)
{
	return strcmp(*(const char *const *)a, *(const char *const *)b);
}
typedef int (*cs_cmp_fn)(pTHX_ void *restrict ctx, size_t i, size_t j);

/* Sort by a named column: pre-fetched cell SVs plus a numeric/string flag. */
typedef struct {
	SV **restrict vals;	/* borrowed cell SV* per row (NULL == missing) */
	unsigned short numeric;	/* 1 => compare with SvNV, 0 => compare with sv_cmp */
} cs_col_ctx;

/* Sort by a user comparator: per-row refs handed to $a/$b before each call. */
typedef struct {
	SV **restrict rows;	/* row ref per index (RV to HV) */
	CV  *restrict cv;	/* the comparator */
	SV  *a_sv;		/* scalar currently aliased to package $a */
	SV  *b_sv;		/* scalar currently aliased to package $b */
} cs_code_ctx;

static int cs_col_cmp(pTHX_ void *restrict vctx, size_t i, size_t j) {
	cs_col_ctx *restrict c = (cs_col_ctx *)vctx;
	SV *restrict av = c->vals[i];
	SV *restrict bv = c->vals[j];
	int a_ok = (av && SvOK(av));
	int b_ok = (bv && SvOK(bv));
	if (!a_ok || !b_ok) {		/* undef/missing always sorts last */
		if (!a_ok && !b_ok) return 0;
		return a_ok ? -1 : 1;
	}
	if (c->numeric) {
		NV x = SvNV(av), y = SvNV(bv);
		return (x > y) - (x < y);
	}
	return sv_cmp(av, bv);		/* Perl's `cmp` semantics */
}

static int cs_code_cmp(pTHX_ void *restrict vctx, size_t i, size_t j) {
	cs_code_ctx *restrict c = (cs_code_ctx *)vctx;
	dSP;
	size_t count;
	NV r;
	/* alias the two rows into the comparator's $a / $b */
	sv_setsv(c->a_sv, c->rows[i]);
	sv_setsv(c->b_sv, c->rows[j]);
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	/* sort comparators read $a/$b, not @_, so we push no arguments */
	PUTBACK;
	count = call_sv((SV *)c->cv, G_SCALAR);
	SPAGAIN;
	if (count > 0) {
		/* POPs has a side effect (sp--) and SvNV is a macro that may
		 * evaluate its argument more than once on older perls (5.10),
		 * so capture the SV first rather than writing SvNV(POPs). */
		SV *res = POPs;
		r = SvNV(res);
	} else {
		r = 0.0;
	}
	PUTBACK;
	FREETMPS;
	LEAVE;
	return (r > 0) - (r < 0);
}

/* Stable bottom merge for the index permutation. */
static void cs_merge(pTHX_ size_t *restrict idx, size_t *restrict tmp,
					 size_t lo, size_t mid, size_t hi,
					 cs_cmp_fn cmp, void *restrict ctx) {
	size_t i = lo, j = mid, k = lo;
	while (i < mid && j < hi) {
		/* `<= 0` keeps equal elements in original order => stable */
		if (cmp(aTHX_ ctx, idx[i], idx[j]) <= 0) tmp[k++] = idx[i++];
		else                                     tmp[k++] = idx[j++];
	}
	while (i < mid) tmp[k++] = idx[i++];
	while (j < hi)  tmp[k++] = idx[j++];
	for (size_t t = lo; t < hi; t++) idx[t] = tmp[t];
}

static void cs_msort(pTHX_ size_t *restrict idx, size_t *restrict tmp,
					 size_t lo, size_t hi,
					 cs_cmp_fn cmp, void *restrict ctx) {
	if (hi - lo < 2) return;
	size_t mid = lo + (hi - lo) / 2;
	cs_msort(aTHX_ idx, tmp, lo, mid, cmp, ctx);
	cs_msort(aTHX_ idx, tmp, mid, hi, cmp, ctx);
	/* skip the merge when the halves are already in order */
	if (cmp(aTHX_ ctx, idx[mid - 1], idx[mid]) <= 0) return;
	cs_merge(aTHX_ idx, tmp, lo, mid, hi, cmp, ctx);
}

/* Resolve $a / $b in the package where the comparator was compiled, localize
 * them for the duration of the sort, and point them at two fresh scalars.
 * Mirrors what Perl's own sort does. The save stack (ENTER must already be in
 * effect) restores the caller's $a/$b on scope exit, including via croak. */
static void cs_bind_ab(pTHX_ CV *restrict cv, SV **a_out, SV **b_out) {
	HV *restrict stash = CvSTASH(cv);
	if (!stash) stash = PL_curstash;
	const char *restrict pkg = stash ? HvNAME(stash) : NULL;
	if (!pkg) pkg = "main";
	STRLEN plen = strlen(pkg);

	/* build "<pkg>::a" / "<pkg>::b" so the GVs land in the right stash */
	char *restrict buf;
	Newx(buf, plen + 4, char);
	SAVEFREEPV(buf);
	memcpy(buf, pkg, plen);
	buf[plen] = ':'; buf[plen + 1] = ':'; buf[plen + 3] = '\0';

	buf[plen + 2] = 'a';
	GV *agv = gv_fetchpv(buf, GV_ADD, SVt_PV);
	buf[plen + 2] = 'b';
	GV *bgv = gv_fetchpv(buf, GV_ADD, SVt_PV);

	SAVESPTR(GvSV(agv));
	SAVESPTR(GvSV(bgv));
	SV *a_sv = sv_newmortal();
	SV *b_sv = sv_newmortal();
	GvSV(agv) = a_sv;
	GvSV(bgv) = b_sv;
	*a_out = a_sv;
	*b_out = b_sv;
}

/* Build the sorted result in the requested shape (out_aoh = 1 => AoH, else
 * HoA), reading from whichever shape the input was. idx[0..n) is the sorted
 * permutation of original row indices. Handles all four input/output
 * combinations, including transposing AoH<->HoA. Returns a new owned ref. */
static SV *cs_materialize(pTHX_ bool out_aoh, bool is_aoh, AV *restrict src_av,
						  SV **restrict colkeys, AV **restrict colavs,
						  size_t ncols, size_t *restrict idx, size_t n) {
	if (out_aoh) {
		AV *out = newAV();
		if (n) av_extend(out, (SSize_t)n - 1);
		if (is_aoh) {
			/* AoH -> AoH: reorder, sharing the original row hashrefs */
			for (size_t k = 0; k < n; k++) {
				SV **restrict rp = av_fetch(src_av, (SSize_t)idx[k], 0);
				SV *restrict row = (rp && *rp) ? *rp : &PL_sv_undef;
				av_push(out, SvREFCNT_inc_simple_NN(row));
			}
		} else {
			/* HoA -> AoH: synthesize one hashref per row (copied cells) */
			for (size_t k = 0; k < n; k++) {
				HV *rh = newHV();
				for (size_t c = 0; c < ncols; c++) {
					SV **cp = av_fetch(colavs[c], (SSize_t)idx[k], 0);
					hv_store_ent(rh, colkeys[c],
								 (cp && *cp) ? newSVsv(*cp) : newSV(0), 0);
				}
				av_push(out, newRV_noinc((SV *)rh));
			}
		}
		return newRV_noinc((SV *)out);
	}
	/* ---- output is HoA */
	HV *restrict out = newHV();
	if (!is_aoh) {
		/* HoA -> HoA: permute every column in lockstep (copied cells) */
		for (size_t c = 0; c < ncols; c++) {
			AV *restrict ncol = newAV();
			if (n) av_extend(ncol, (SSize_t)n - 1);
			for (size_t k = 0; k < n; k++) {
				SV **restrict cp = av_fetch(colavs[c], (SSize_t)idx[k], 0);
				av_push(ncol, (cp && *cp) ? newSVsv(*cp) : newSV(0));
			}
			hv_store_ent(out, colkeys[c], newRV_noinc((SV *)ncol), 0);
		}
		return newRV_noinc((SV *)out);
	}
	/* AoH -> HoA: column set is the union of the rows' keys, ordered by
	 * first appearance; absent cells become undef. */
	AV *restrict keylist = (AV *)sv_2mortal((SV *)newAV());
	HV *restrict seen    = (HV *)sv_2mortal((SV *)newHV());
	for (size_t i = 0; i < n; i++) {
		SV **restrict rp = av_fetch(src_av, (SSize_t)i, 0);
		if (!(rp && *rp && SvROK(*rp) && SvTYPE(SvRV(*rp)) == SVt_PVHV))
			continue;
		HV *restrict rh = (HV *)SvRV(*rp);
		HE *restrict he;
		hv_iterinit(rh);
		while ((he = hv_iternext(rh))) {
			SV *restrict ksv = hv_iterkeysv(he);
			if (!hv_exists_ent(seen, ksv, 0)) {
				(void)hv_store_ent(seen, ksv, newSViv(1), 0);
				av_push(keylist, newSVsv(ksv));
			}
		}
	}
	SSize_t nk = av_len(keylist) + 1;
	for (SSize_t c = 0; c < nk; c++) {
		SV *restrict ksv = *av_fetch(keylist, c, 0);
		AV *restrict ncol = newAV();
		if (n) av_extend(ncol, (SSize_t)n - 1);
		for (size_t k = 0; k < n; k++) {
			SV **restrict rp = av_fetch(src_av, (SSize_t)idx[k], 0);
			SV *restrict cell = NULL;
			if (rp && *rp && SvROK(*rp) && SvTYPE(SvRV(*rp)) == SVt_PVHV) {
				HE *restrict he = hv_fetch_ent((HV *)SvRV(*rp), ksv, 0, 0);
				if (he) cell = HeVAL(he);
			}
			av_push(ncol, cell ? newSVsv(cell) : newSV(0));
		}
		hv_store_ent(out, ksv, newRV_noinc((SV *)ncol), 0);
	}
	return newRV_noinc((SV *)out);
}
// --- XS SECTION ---
MODULE = Stats::LikeR  PACKAGE = Stats::LikeR

SV *aoh2hoa(data)
	SV *data
	CODE:
	{
		/* =================================================================
		 * aoh2hoa($aoh) -- transpose an Array-of-Hashes into a
		 * Hash-of-Arrays.
		 *
		 *   in : arrayref of hashrefs (rows)  [ {a=>1,b=>2}, {a=>3} ]
		 *   out: hashref of arrayrefs (cols)  { a=>[1,3], b=>[2,undef] }
		 *
		 * - Columns are the union of all row keys.
		 * - Every column has exactly scalar(@$aoh) elements; cells absent
		 *   from a given row are undef (kept as cheap holes, not SVs).
		 * - Values are copied, so the result is independent of the input
		 *   (a value that is itself a reference is copied shallowly, just
		 *   like Perl's  $col->[$i] = $row->{$k} ).
		 * - A row that is not a hashref contributes undef to every column
		 *   at its index (skipped, not fatal).
		 * ================================================================= */
		AV *restrict aoh;
		HV *restrict out;
		SSize_t n, i;
		HE *he;

		if (!SvROK(data) || SvTYPE(SvRV(data)) != SVt_PVAV)
			croak("aoh2hoa: argument must be an arrayref of hashrefs");

		aoh = (AV *)SvRV(data);
		n   = av_len(aoh) + 1;			/* number of rows */
		out = newHV();

		for (i = 0; i < n; i++) {
			SV **rp = av_fetch(aoh, i, 0);
			HV  *row;

			if (!(rp && *rp && SvROK(*rp)
			           && SvTYPE(SvRV(*rp)) == SVt_PVHV))
				continue;		/* non-hashref row -> all undef */

			row = (HV *)SvRV(*rp);
			hv_iterinit(row);
			while ((he = hv_iternext(row))) {
				SV *ksv  = hv_iterkeysv(he);	/* utf8 / SV-key safe */
				HE *oute = hv_fetch_ent(out, ksv, 0, 0);
				AV *col;

				if (oute && SvROK(HeVAL(oute))
				         && SvTYPE(SvRV(HeVAL(oute))) == SVt_PVAV) {
					col = (AV *)SvRV(HeVAL(oute));
				} else {
					col = newAV();
					if (n > 0) av_extend(col, n - 1);
					(void)hv_store_ent(out, ksv,
					                   newRV_noinc((SV *)col), 0);
				}
				av_store(col, i, newSVsv(HeVAL(he)));
			}
		}

		/* pad every column out to exactly n elements (trailing undefs) */
		hv_iterinit(out);
		while ((he = hv_iternext(out))) {
			AV *col = (AV *)SvRV(HeVAL(he));
			if (av_len(col) < n - 1)
				av_fill(col, n - 1);
		}

		RETVAL = newRV_noinc((SV *)out);
	}
	OUTPUT:
		RETVAL

void
csort(data, by, output=&PL_sv_undef)
	SV *data
	SV *by
	SV *output
PREINIT:
	bool is_aoh, is_code, out_aoh;
	const char *restrict colname = NULL;
	STRLEN collen = 0;
	CV *restrict cmp_cv = NULL;
	AV *restrict src_av = NULL;	/* AoH input */
	HV *restrict src_hv = NULL;	/* HoA input */
	SSize_t n = 0;
	size_t *restrict idx = NULL, *tmp = NULL;
	SV **restrict rowrefs = NULL;	/* coderef mode: row ref per index */
	SV **restrict colkeys = NULL;	/* HoA: column key SVs */
	AV **restrict colavs  = NULL;	/* HoA: column AVs */
	size_t ncols = 0;
	SV *restrict result = NULL;
PPCODE:
{
	/* ---- classify $by: coderef comparator vs column name ------------ */
	if (SvROK(by) && SvTYPE(SvRV(by)) == SVt_PVCV) {
		is_code = 1;
		cmp_cv  = (CV *)SvRV(by);
	} else if (SvOK(by) && !SvROK(by)) {
		is_code = 0;
		colname = SvPV(by, collen);
	} else {
		croak("csort: second argument must be a column name or a "
			  "comparator code-ref using $a and $b");
	}

	/* ---- classify $data: AoH (arrayref) vs HoA (hashref) ------------ */
	if (!SvROK(data))
		croak("csort: first argument must be an array-ref (AoH) or "
			  "hash-ref (HoA)");
	if (SvTYPE(SvRV(data)) == SVt_PVAV) {
		is_aoh  = 1;
		src_av  = (AV *)SvRV(data);
		n       = av_len(src_av) + 1;
	} else if (SvTYPE(SvRV(data)) == SVt_PVHV) {
		is_aoh  = 0;
		src_hv  = (HV *)SvRV(data);
	} else {
		croak("csort: first argument must be an array-ref (AoH) or "
			  "hash-ref (HoA)");
	}

	/* ---- resolve requested output shape (default: match input) ------ */
	if (!SvOK(output)) {
		out_aoh = is_aoh;
	} else {
		STRLEN ol;
		const char *restrict os = SvPV(output, ol);
		if (ol == 3 && toLOWER(os[0]) == 'a' && toLOWER(os[1]) == 'o'
				&& toLOWER(os[2]) == 'h')
			out_aoh = 1;
		else if (ol == 3 && toLOWER(os[0]) == 'h' && toLOWER(os[1]) == 'o'
				&& toLOWER(os[2]) == 'a')
			out_aoh = 0;
		else
			croak("csort: output type must be 'aoh' or 'hoa' (got '%s')", os);
	}

	ENTER;	 /* scope for SAVEFREEPV / SAVESPTR cleanups */
	SAVETMPS; /* reap transient synthesized rows here   */

	// ---- gather HoA column metadata + validate equal lengths --------
	if (!is_aoh) {
		HE *restrict he;
		SSize_t common = -2;	/* -2 = unset sentinel */
		hv_iterinit(src_hv);
		while ((he = hv_iternext(src_hv))) {
			SV *restrict cv = HeVAL(he);
			if (!cv || !SvROK(cv) || SvTYPE(SvRV(cv)) != SVt_PVAV)
				croak("csort: HoA value for column '%s' is not an "
					  "array-ref", HePV(he, PL_na));
			SSize_t len = av_len((AV *)SvRV(cv)) + 1;
			if (common == -2) common = len;
			else if (len != common)
				croak("csort: HoA columns have unequal lengths "
					  "(%" IVdf " vs %" IVdf ")",
					  (IV)common, (IV)len);
			ncols++;
		}
		n = (common < 0) ? 0 : common;

		if (ncols) {
			Newx(colkeys, ncols, SV *);  SAVEFREEPV(colkeys);
			Newx(colavs,  ncols, AV *);  SAVEFREEPV(colavs);
			size_t c = 0;
			hv_iterinit(src_hv);
			while ((he = hv_iternext(src_hv))) {
				colkeys[c] = sv_2mortal(newSVsv(hv_iterkeysv(he)));
				colavs[c]  = (AV *)SvRV(HeVAL(he));
				c++;
			}
		}
	}

	/* ---- build the identity permutation (sorted in place below) ----- */
	Newx(idx, (size_t)(n > 0 ? n : 1), size_t);  SAVEFREEPV(idx);
	Newx(tmp, (size_t)(n > 0 ? n : 1), size_t);  SAVEFREEPV(tmp);
	for (size_t i = 0; i < (size_t)n; i++) idx[i] = i;

	if (n > 1) {
		if (is_code) {
			/* ---- comparator mode: prepare row refs + bind $a/$b -------- */
			Newx(rowrefs, (size_t)n, SV *);  SAVEFREEPV(rowrefs);
	
			if (is_aoh) {
				for (size_t i = 0; i < (size_t)n; i++) {
					SV **restrict rp = av_fetch(src_av, (SSize_t)i, 0);
					rowrefs[i] = (rp && *rp) ? *rp : &PL_sv_undef;
				}
			} else {
				/* synthesize a per-row hashref view of the columns;
				 * cells are aliased (shared) -- read-only in a comparator */
				for (size_t i = 0; i < (size_t)n; i++) {
					HV *restrict rh = newHV();
					for (size_t c = 0; c < ncols; c++) {
						SV **restrict cp = av_fetch(colavs[c], (SSize_t)i, 0);
						SV *restrict cell = (cp && *cp)
								 ? SvREFCNT_inc_simple_NN(*cp) : newSV(0);
						hv_store_ent(rh, colkeys[c], cell, 0);
					}
					rowrefs[i] = sv_2mortal(newRV_noinc((SV *)rh));
				}
			}
	
			cs_code_ctx ctx;
			ctx.rows = rowrefs;
			ctx.cv   = cmp_cv;
			cs_bind_ab(aTHX_ cmp_cv, &ctx.a_sv, &ctx.b_sv);
			cs_msort(aTHX_ idx, tmp, 0, (size_t)n, cs_code_cmp, &ctx);
		} else {
			/* ---- column mode: gather cells, detect numeric, sort ------- */
			SV **restrict vals;
			Newx(vals, (size_t)n, SV *);  SAVEFREEPV(vals);
			bool found = 0;
			unsigned short numeric = 1;
	
			if (is_aoh) {
				for (size_t i = 0; i < (size_t)n; i++) {
					SV *restrict cell = NULL;
					SV **restrict rp = av_fetch(src_av, (SSize_t)i, 0);
					if (rp && *rp && SvROK(*rp)
							&& SvTYPE(SvRV(*rp)) == SVt_PVHV) {
						SV **restrict cp = hv_fetch((HV *)SvRV(*rp),
										   colname, collen, 0);
						if (cp && *cp) { cell = *cp; found = 1; }
					}
					if (cell && SvOK(cell) && !looks_like_number(cell))
						numeric = 0;
					vals[i] = cell;
				}
			} else {
				SV **colp = hv_fetch(src_hv, colname, collen, 0);
				if (!(colp && *colp && SvROK(*colp)
						&& SvTYPE(SvRV(*colp)) == SVt_PVAV))
					croak("csort: column '%s' not found in HoA", colname);
				found = 1;
				AV *col = (AV *)SvRV(*colp);
				for (size_t i = 0; i < (size_t)n; i++) {
					SV **cp = av_fetch(col, (SSize_t)i, 0);
					SV *cell = (cp && *cp) ? *cp : NULL;
					if (cell && SvOK(cell) && !looks_like_number(cell))
						numeric = 0;
					vals[i] = cell;
				}
			}
			if (!found)
				croak("csort: column '%s' not found", colname);
	
			cs_col_ctx ctx;
			ctx.vals    = vals;
			ctx.numeric = numeric;
			cs_msort(aTHX_ idx, tmp, 0, (size_t)n, cs_col_cmp, &ctx);
		}
	}	/* end if (n > 1) */

	/* ---- materialize the result in the requested shape -------------- */
	result = cs_materialize(aTHX_ out_aoh, is_aoh, src_av,
							colkeys, colavs, ncols, idx, (size_t)n);

	FREETMPS;	/* reap synthesized rows; restores $a/$b via the save stack at LEAVE */
	LEAVE;

	XPUSHs(sv_2mortal(result));
	XSRETURN(1);
}

SV *cfilter(data, ...)
		SV *data
	CODE:
	{
/* 0. options. Exactly one of keep/remove is required; it is either an
    array ref of column names or a value predicate (CODE ref / function
    name). For a predicate, undef handling is:
      na => 'keep' (default) - the predicate sees every cell, incl undef
      na => 'omit'           - single-column funcs (sd) get defined cells
      against => 'col'       - two-column funcs (cor): the predicate gets
                               ($col, $ref) over rows defined in BOTH.*/
		SV *restrict keep_sv = NULL, *restrict remove_sv = NULL;
		SV *restrict na_sv = NULL, *restrict against_sv = NULL;
		if ((items - 1) & 1) croak("cfilter: trailing options must be name => value pairs");
		for (int oi = 1; oi < items; oi += 2) {
			STRLEN ol;
			const char *restrict oname = SvPV(ST(oi), ol);
			SV *restrict oval = ST(oi + 1);
			if (ol == 4 && memEQ(oname, "keep", 4)) keep_sv = oval;
			else if (ol == 6 && memEQ(oname, "remove", 6)) remove_sv = oval;
			else if (ol == 2 && memEQ(oname, "na", 2)) na_sv = oval;
			else if (ol == 7 && memEQ(oname, "against", 7)) against_sv = oval;
			else croak("cfilter: unknown option '%s'", oname);
		}
		if (keep_sv && remove_sv) croak("cfilter: give either keep or remove, not both");
		if (!keep_sv && !remove_sv) croak("cfilter: need a keep or remove argument");
		bool removing = (remove_sv != NULL);
		SV *restrict sel = removing ? remove_sv : keep_sv;
		// classify the selector: array ref of names, or a value predicate.
		bool by_name;
		SV *restrict cv_sv = NULL;
		if (SvROK(sel) && SvTYPE(SvRV(sel)) == SVt_PVAV) by_name = TRUE;
		else if ((SvROK(sel) && SvTYPE(SvRV(sel)) == SVt_PVCV) || (SvOK(sel) && !SvROK(sel))) {
			by_name = FALSE;
			if (SvROK(sel)) cv_sv = SvRV(sel);
			else {
				STRLEN nl;
				const char *restrict name = SvPV(sel, nl);
				SV *restrict fq = strstr(name, "::") ? newSVpvn(name, nl) : newSVpvf("Stats::LikeR::%s", name);
				CV *restrict cv = get_cv(SvPV_nolen(fq), 0);
				SvREFCNT_dec(fq);
				if (!cv) croak("cfilter: unknown function '%s'", name);
				cv_sv = (SV*)cv;
			}
		}
		else croak("cfilter: keep/remove must be an array ref of column names or a code ref / function name");
		// decode the undef policy (predicate only).
		bool na_omit = FALSE;
		if (na_sv && SvOK(na_sv)) {
			STRLEN nl;
			const char *restrict nv = SvPV(na_sv, nl);
			if (nl == 4 && memEQ(nv, "omit", 4)) na_omit = TRUE;
			else if (nl == 4 && memEQ(nv, "keep", 4)) na_omit = FALSE;
			else croak("cfilter: na must be 'keep' or 'omit'");
		}
		if (by_name && (na_sv || against_sv)) croak("cfilter: na/against only apply to a predicate selector");
		if (against_sv && na_sv) croak("cfilter: give na or against, not both");
		// 1. detect the data shape.
		if (!SvROK(data)) croak("cfilter: data must be a reference");
		SV *restrict rv = SvRV(data);
		short int kind; // 0 = array-of-hashes, 1 = hash-of-arrays, 2 = hash-of-hashes
		if (SvTYPE(rv) == SVt_PVAV) kind = 0;
		else if (SvTYPE(rv) == SVt_PVHV) {
			HV *restrict h = (HV*)rv;
			hv_iterinit(h);
			HE *restrict fe = hv_iternext(h);
			if (!fe) kind = 2;
			else {
				SV *restrict fv = hv_iterval(h, fe);
				if (SvROK(fv) && SvTYPE(SvRV(fv)) == SVt_PVAV) kind = 1;
				else if (SvROK(fv) && SvTYPE(SvRV(fv)) == SVt_PVHV) kind = 2;
				else croak("cfilter: hash values must be array refs (HoA) or hash refs (HoH)");
			}
		}
		else croak("cfilter: data must be an array ref or hash ref");
		// 2. the column universe, and (predicate only) a row-aligned cell table
		//    `cellmap`: colname -> AV of length nrows, undef in the gaps. The
		//    alignment lets `against` pair two columns by row.
		HV *restrict universe = newHV();
		AV *restrict colnames = newAV();
		HV *restrict cellmap = by_name ? NULL : newHV();
		SSize_t nrows = 0;
		if (kind == 1) {
			HV *restrict h = (HV*)rv;
			HE *restrict e;
			hv_iterinit(h);
			while ((e = hv_iternext(h))) {
				SV *restrict val = hv_iterval(h, e);
				if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVAV) croak("cfilter: every value must be an array ref (hash of arrays)");
				SSize_t len = av_len((AV*)SvRV(val)) + 1;
				if (len > nrows) nrows = len;
			}
			hv_iterinit(h);
			while ((e = hv_iternext(h))) {
				SV *restrict ck = hv_iterkeysv(e);
				(void)hv_store_ent(universe, ck, newSViv(1), 0);
				av_push(colnames, newSVsv(ck));
				if (!by_name) {
					AV *restrict src = (AV*)SvRV(hv_iterval(h, e)), *restrict col = newAV();
					if (nrows > 0) av_extend(col, nrows - 1);
					for (SSize_t r = 0; r < nrows; r++) {
						SV **restrict ep = (r <= av_len(src)) ? av_fetch(src, r, 0) : NULL;
						av_push(col, (ep && *ep && SvOK(*ep)) ? newSVsv(*ep) : newSV(0));
					}
					(void)hv_store_ent(cellmap, ck, newRV_noinc((SV*)col), 0);
				}
			}
		} else {
			// row-major: collect the rows in a stable order, then build per column.
			AV *restrict rows = newAV();
			if (kind == 0) {
				AV *restrict a = (AV*)rv;
				SSize_t n = av_len(a) + 1;
				for (SSize_t r = 0; r < n; r++) {
					SV **restrict ep = av_fetch(a, r, 0);
					if (!ep || !*ep || !SvROK(*ep) || SvTYPE(SvRV(*ep)) != SVt_PVHV) croak("cfilter: array elements must be hash refs (array of hashes)");
					av_push(rows, newRV_inc(SvRV(*ep)));
				}
			} else {
				HV *restrict h = (HV*)rv;
				HE *restrict e;
				hv_iterinit(h);
				while ((e = hv_iternext(h))) {
					SV *restrict val = hv_iterval(h, e);
					if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVHV) croak("cfilter: every value must be a hash ref (hash of hashes)");
					av_push(rows, newRV_inc(SvRV(val)));
				}
			}
			nrows = av_len(rows) + 1;
			// union of columns, in first-seen order.
			{
				HV *restrict seen = newHV();
				for (SSize_t r = 0; r < nrows; r++) {
					HV *restrict row = (HV*)SvRV(*av_fetch(rows, r, 0));
					HE *restrict ie;
					hv_iterinit(row);
					while ((ie = hv_iternext(row))) {
						SV *restrict ck = hv_iterkeysv(ie);
						if (!hv_exists_ent(seen, ck, 0)) {
							(void)hv_store_ent(seen, ck, newSViv(1), 0);
							(void)hv_store_ent(universe, ck, newSViv(1), 0);
							av_push(colnames, newSVsv(ck));
						}
					}
				}
				SvREFCNT_dec((SV*)seen);
			}
			if (!by_name) {
				SSize_t nc = av_len(colnames) + 1;
				for (SSize_t c = 0; c < nc; c++) {
					SV *restrict ck = *av_fetch(colnames, c, 0);
					AV *restrict col = newAV();
					if (nrows > 0) av_extend(col, nrows - 1);
					for (SSize_t r = 0; r < nrows; r++) {
						HV *restrict row = (HV*)SvRV(*av_fetch(rows, r, 0));
						HE *restrict che = hv_fetch_ent(row, ck, 0, 0);
						SV *restrict cell = che ? HeVAL(che) : NULL;
						av_push(col, (cell && SvOK(cell)) ? newSVsv(cell) : newSV(0));
					}
					(void)hv_store_ent(cellmap, ck, newRV_noinc((SV*)col), 0);
				}
			}
			SvREFCNT_dec((SV*)rows);
		}
		// 2b. resolve the `against` reference column into its cell array.
		AV *restrict against_av = NULL;
		if (against_sv) {
			if (!SvOK(against_sv) || SvROK(against_sv)) croak("cfilter: against must be a column name (string)");
			if (!hv_exists_ent(universe, against_sv, 0)) croak("cfilter: against column '%s' not found in data", SvPV_nolen(against_sv));
			against_av = (AV*)SvRV(HeVAL(hv_fetch_ent(cellmap, against_sv, 0, 0)));
		}
		// 3. decide which columns to keep.
		HV *restrict keepset = newHV();
		if (by_name) {
			AV *restrict names = (AV*)SvRV(sel);
			HV *restrict listed = newHV();
			SSize_t n = av_len(names) + 1;
			for (SSize_t i = 0; i < n; i++) {
				SV **restrict ep = av_fetch(names, i, 0);
				if (!ep || !*ep || !SvOK(*ep)) croak("cfilter: column list contains an undefined entry");
				if (!hv_exists_ent(universe, *ep, 0)) croak("cfilter: column '%s' not found in data", SvPV_nolen(*ep));
				(void)hv_store_ent(listed, *ep, newSViv(1), 0);
			}
			SSize_t nc = av_len(colnames) + 1;
			for (SSize_t c = 0; c < nc; c++) {
				SV *restrict ck = *av_fetch(colnames, c, 0);
				bool in_list = cBOOL(hv_exists_ent(listed, ck, 0));
				if (removing ? !in_list : in_list) (void)hv_store_ent(keepset, ck, newSViv(1), 0);
			}
			SvREFCNT_dec((SV*)listed);
		} else {
			// predicate over the flat colnames list (never a live hash iterator
			// across call_sv). Apply the undef policy per column.
			SSize_t nc = av_len(colnames) + 1;
			for (SSize_t c = 0; c < nc; c++) {
				SV *restrict ck = *av_fetch(colnames, c, 0);
				AV *restrict cells = (AV*)SvRV(HeVAL(hv_fetch_ent(cellmap, ck, 0, 0)));
				bool pass;
				if (against_av) {
					// two columns, pairwise complete: rows defined in BOTH.
					AV *restrict a1 = newAV(), *restrict a2 = newAV();
					for (SSize_t r = 0; r < nrows; r++) {
						SV **restrict p1 = av_fetch(cells, r, 0);
						SV **restrict p2 = av_fetch(against_av, r, 0);
						if (p1 && *p1 && SvOK(*p1) && p2 && *p2 && SvOK(*p2)) {
							av_push(a1, newSVsv(*p1));
							av_push(a2, newSVsv(*p2));
						}
					}
					pass = cf_pred(aTHX_ cv_sv, a1, a2, ck);
					SvREFCNT_dec((SV*)a1);
					SvREFCNT_dec((SV*)a2);
				} else if (na_omit) {
					// one column, defined cells only.
					AV *restrict a1 = newAV();
					for (SSize_t r = 0; r < nrows; r++) {
						SV **restrict p = av_fetch(cells, r, 0);
						if (p && *p && SvOK(*p)) av_push(a1, newSVsv(*p));
					}
					pass = cf_pred(aTHX_ cv_sv, a1, NULL, ck);
					SvREFCNT_dec((SV*)a1);
				} else {
					// one column, every cell including undef.
					pass = cf_pred(aTHX_ cv_sv, cells, NULL, ck);
				}
				if (removing ? !pass : pass) (void)hv_store_ent(keepset, ck, newSViv(1), 0);
			}
		}
		// 4. rebuild the data in its original shape with only the kept columns.
		SV *restrict out;
		if (kind == 1) {
			HV *restrict outh = newHV(), *restrict h = (HV*)rv;
			HE *restrict e;
			hv_iterinit(h);
			while ((e = hv_iternext(h))) {
				SV *restrict ck = hv_iterkeysv(e);
				if (!hv_exists_ent(keepset, ck, 0)) continue;
				AV *restrict src = (AV*)SvRV(hv_iterval(h, e)), *restrict dst = newAV();
				SSize_t n = av_len(src) + 1;
				if (n > 0) av_extend(dst, n - 1);
				for (SSize_t i = 0; i < n; i++) {
					SV **restrict ep = av_fetch(src, i, 0);
					av_push(dst, (ep && *ep) ? newSVsv(*ep) : newSV(0));
				}
				(void)hv_store_ent(outh, ck, newRV_noinc((SV*)dst), 0);
			}
			out = (SV*)outh;
		} else if (kind == 2) {
			HV *restrict outh = newHV(), *restrict h = (HV*)rv;
			HE *restrict e;
			hv_iterinit(h);
			while ((e = hv_iternext(h))) {
				SV *restrict rk = hv_iterkeysv(e);
				HV *restrict row = (HV*)SvRV(hv_iterval(h, e)), *restrict nr = newHV();
				HE *restrict ie;
				hv_iterinit(row);
				while ((ie = hv_iternext(row))) {
					SV *restrict ck = hv_iterkeysv(ie);
					if (!hv_exists_ent(keepset, ck, 0)) continue;
					(void)hv_store_ent(nr, ck, newSVsv(HeVAL(ie)), 0);
				}
				(void)hv_store_ent(outh, rk, newRV_noinc((SV*)nr), 0);
			}
			out = (SV*)outh;
		} else {
			AV *restrict outa = newAV(), *restrict a = (AV*)rv;
			SSize_t n = av_len(a) + 1;
			for (SSize_t r = 0; r < n; r++) {
				HV *restrict row = (HV*)SvRV(*av_fetch(a, r, 0)), *restrict nr = newHV();
				HE *restrict ie;
				hv_iterinit(row);
				while ((ie = hv_iternext(row))) {
					SV *restrict ck = hv_iterkeysv(ie);
					if (!hv_exists_ent(keepset, ck, 0)) continue;
					(void)hv_store_ent(nr, ck, newSVsv(HeVAL(ie)), 0);
				}
				av_push(outa, newRV_noinc((SV*)nr));
			}
			out = (SV*)outa;
		}
		// 5. tidy up the scratch tables (the result keeps its own copies).
		SvREFCNT_dec((SV*)universe);
		SvREFCNT_dec((SV*)colnames);
		SvREFCNT_dec((SV*)keepset);
		if (cellmap) SvREFCNT_dec((SV*)cellmap);
		RETVAL = newRV_noinc(out);
	}
	OUTPUT:
		RETVAL

SV *hoh2hoa(data, ...)
		SV *data
	CODE:
	{
		// 0. parse trailing name => value options (done before any allocation so
		//    option/usage errors can't leak). undef.val sets the fill for a
		//    missing key or an undef cell (default: undef). row.names, if given,
		//    adds a column of that name holding the sorted row labels.
		SV *restrict fill = NULL;   // NULL => fill gaps with undef
		SV *restrict rn_sv = NULL;  // NULL => do not emit a row-names column
		if ((items - 1) & 1) croak("hoh2hoa: trailing options must be name => value pairs");
		for (int oi = 1; oi < items; oi += 2) {
			STRLEN ol;
			const char *restrict oname = SvPV(ST(oi), ol);
			SV *restrict oval = ST(oi + 1);
			if (ol == 9 && memEQ(oname, "undef.val", 9)) fill = SvOK(oval) ? oval : NULL;
			else if (ol == 9 && memEQ(oname, "row.names", 9)) {
				if (SvOK(oval) && !SvROK(oval)) rn_sv = oval;
				else croak("hoh2hoa: row.names must be a column name (string)");
			}
			else croak("hoh2hoa: unknown option '%s'", oname);
		}
		// 1. the input must be a hash ref (a hash of hashes).
		if (!SvROK(data) || SvTYPE(SvRV(data)) != SVt_PVHV) croak("hoh2hoa: data must be a hash ref (hash of hashes)");
		HV *restrict in_hv = (HV*)SvRV(data);
		// 2. these cross the section boundaries (gather -> build -> cleanup).
		HV *restrict out_hv = newHV();    // the result: column name -> array ref
		AV *restrict rows_av = newAV();   // outer keys, sorted into the row order
		AV *restrict cols_av = newAV();   // union of inner keys (column names)
		HV *restrict seen = newHV();      // membership test while taking the union
		// 3. collect the outer keys (row labels) and sort for a stable row order.
		{
			HE *restrict e;
			hv_iterinit(in_hv);
			while ((e = hv_iternext(in_hv))) {
				SV *restrict rv = hv_iterval(in_hv, e);
				if (!SvROK(rv) || SvTYPE(SvRV(rv)) != SVt_PVHV) croak("hoh2hoa: every value must be a hash ref (hash of hashes)");
				av_push(rows_av, newSVsv(hv_iterkeysv(e)));
			}
		}
		SSize_t nrows = av_len(rows_av) + 1;
		if (nrows > 1) qsort(AvARRAY(rows_av), (size_t)nrows, sizeof(SV*), h2h_keycmp);
		// 4. discover the union of inner keys. Each new column gets an empty array
		//    in the result straight away so step 5 can just push into it.
		{
			HE *restrict e;
			hv_iterinit(in_hv);
			while ((e = hv_iternext(in_hv))) {
				HV *restrict row = (HV*)SvRV(hv_iterval(in_hv, e));
				HE *restrict ie;
				hv_iterinit(row);
				while ((ie = hv_iternext(row))) {
					SV *restrict ck = hv_iterkeysv(ie);
					if (!hv_exists_ent(seen, ck, 0)) {
						(void)hv_store_ent(seen, ck, &PL_sv_yes, 0);
						av_push(cols_av, newSVsv(ck));
						(void)hv_store_ent(out_hv, ck, newRV_noinc((SV*)newAV()), 0);
					}
				}
			}
		}
		SSize_t ncols = av_len(cols_av) + 1;
		// 5. walk the rows in sorted order; for every column push the cell (a copy)
		//    or the fill value, so each column ends up exactly nrows long.
		for (SSize_t r = 0; r < nrows; r++) {
			SV *restrict rk = *av_fetch(rows_av, r, 0);
			HE *restrict rhe = hv_fetch_ent(in_hv, rk, 0, 0);
			HV *restrict row = (HV*)SvRV(HeVAL(rhe));
			for (SSize_t c = 0; c < ncols; c++) {
				SV *restrict ck = *av_fetch(cols_av, c, 0);
				HE *restrict che = hv_fetch_ent(row, ck, 0, 0);
				SV *restrict src = che ? HeVAL(che) : NULL;
				SV *restrict cell = (src && SvOK(src)) ? newSVsv(src) : (fill ? newSVsv(fill) : newSV(0));
				HE *restrict colhe = hv_fetch_ent(out_hv, ck, 0, 0);
				av_push((AV*)SvRV(HeVAL(colhe)), cell);
			}
		}
		// 6. optional row-names column: the sorted labels under the requested name.
		if (rn_sv) {
			if (hv_exists_ent(out_hv, rn_sv, 0)) croak("hoh2hoa: row.names column '%s' collides with an existing column", SvPV_nolen(rn_sv));
			AV *restrict rn_av = newAV();
			for (SSize_t r = 0; r < nrows; r++) av_push(rn_av, newSVsv(*av_fetch(rows_av, r, 0)));
			(void)hv_store_ent(out_hv, rn_sv, newRV_noinc((SV*)rn_av), 0);
		}
		// 7. tidy up the scratch structures (the result keeps its own copies).
		SvREFCNT_dec((SV*)rows_av);
		SvREFCNT_dec((SV*)cols_av);
		SvREFCNT_dec((SV*)seen);
		RETVAL = newRV_noinc((SV*)out_hv);
	}
	OUTPUT:
		RETVAL

void filter(df, pred)
	SV *df
	SV *pred
PPCODE:
{
	if (!df || !SvROK(df))
		croak("filter: first argument must be a HASH or ARRAY reference (a data frame)");
	bool is_code = (pred && SvROK(pred) && SvTYPE(SvRV(pred)) == SVt_PVCV);
	if (!is_code && (!pred || !SvROK(pred) || SvTYPE(SvRV(pred)) != SVt_PVHV))
		croak("filter: second argument must be a CODE ref or a predicate built with col()");
	SV *restrict ref = SvRV(df);
	SV *restrict result;
	if (SvTYPE(ref) == SVt_PVAV) {
		// ----- Array of Hashes: keep matching row hashrefs (shared, not copied) -----
		AV *restrict in = (AV*)ref;
		AV *restrict out = newAV();
		SSize_t n = av_len(in) + 1, i;
		filt_ctx ctx; ctx.is_aoh = 1; ctx.data_hv = NULL; ctx.idx = 0;
		for (i = 0; i < n; i++) {
			SV **restrict rp = av_fetch(in, i, 0);
			if (!rp || !*rp || !SvROK(*rp) || SvTYPE(SvRV(*rp)) != SVt_PVHV) {
				SvREFCNT_dec((SV*)out);
				croak("filter: array data frame must hold HASH references; element %ld is not one", (long)i);
			}
			bool keep;
			if (is_code) keep = filt_call(aTHX_ pred, *rp);
			else { ctx.row_hv = (HV*)SvRV(*rp); keep = filt_eval(aTHX_ pred, &ctx); }
			if (keep) av_push(out, SvREFCNT_inc_simple_NN(*rp));
		}
		result = newRV_noinc((SV*)out);
	} else if (SvTYPE(ref) == SVt_PVHV) {
		// ----- Hash of Arrays: keep matching row indices across every column -----
		HV *restrict in = (HV*)ref;
		I32 ncols = hv_iterinit(in);
		if (ncols <= 0) {
			result = newRV_noinc((SV*)newHV());
		} else {
			char   **restrict names = (char**)safemalloc(ncols * sizeof(char*));
			STRLEN  *restrict nlens = (STRLEN*)safemalloc(ncols * sizeof(STRLEN));
			AV     **restrict inav  = (AV**)safemalloc(ncols * sizeof(AV*));
			AV     **restrict outav = (AV**)safemalloc(ncols * sizeof(AV*));
			HV *restrict out = newHV();
			SSize_t maxrows = 0, i;
			I32 c = 0, cc;
			HE *restrict e;
			while ((e = hv_iternext(in)) && c < ncols) {
				STRLEN klen;
				char *restrict k = HePV(e, klen);
				SV *restrict v = HeVAL(e);
				if (!v || !SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVAV) {
					safefree(names); safefree(nlens); safefree(inav); safefree(outav);
					SvREFCNT_dec((SV*)out);
					croak("filter: hash data frame must hold ARRAY references (a hash of arrays); column '%s' is not one", k);
				}
				AV *restrict a = (AV*)SvRV(v);
				SSize_t len = av_len(a) + 1;
				if (len > maxrows) maxrows = len;
				names[c] = k; nlens[c] = klen; inav[c] = a;
				outav[c] = newAV();
				hv_store(out, k, klen, newRV_noinc((SV*)outav[c]), 0);
				c++;
			}
			filt_ctx ctx; ctx.is_aoh = 0; ctx.row_hv = NULL; ctx.data_hv = in;
			for (i = 0; i < maxrows; i++) {
				bool keep;
				if (is_code) {
					HV *restrict rowh = newHV();
					for (cc = 0; cc < ncols; cc++) {
						SV **restrict vp = av_fetch(inav[cc], i, 0);
						hv_store(rowh, names[cc], nlens[cc], newSVsv((vp && *vp) ? *vp : &PL_sv_undef), 0);
					}
					SV *restrict rowrv = newRV_noinc((SV*)rowh);
					keep = filt_call(aTHX_ pred, rowrv);
					SvREFCNT_dec(rowrv);
				} else {
					ctx.idx = i;
					keep = filt_eval(aTHX_ pred, &ctx);
				}
				if (keep) {
					for (cc = 0; cc < ncols; cc++) {
						SV **restrict vp = av_fetch(inav[cc], i, 0);
						av_push(outav[cc], newSVsv((vp && *vp) ? *vp : &PL_sv_undef));
					}
				}
			}
			safefree(names); safefree(nlens); safefree(inav); safefree(outav);
			result = newRV_noinc((SV*)out);
		}
	} else {
		croak("filter: unsupported data frame; expected an array of hashes (AoH) or a hash of arrays (HoA)");
	}
	ST(0) = sv_2mortal(result);
	XSRETURN(1);
}

SV *col2col(data, cmd, cols = &PL_sv_undef, ...)
		SV *data
		SV *cmd
		SV *cols
	CODE:
	{
// Only these cross the section boundaries (build -> loop -> cleanup);
// everything else is declared at its point of use just below.
		SV *restrict cv_sv = NULL;
		size_t ncols = 0, nrows = 0;
		AV *restrict names_av = newAV();
		NV **restrict col_val = NULL;
		char **restrict col_def = NULL;
		short int na_mode = 0;	// 0 = pairwise, 1 = omit, 2 = keep; see section 0
		bool skip_errors = TRUE;	// skip.errors (default true): trap a croaking block, store its message
// 0. options. They may be given either as trailing name => value pairs
//    (after the positional cols), or - so no placeholder is needed when
//    there is no column restriction - as a single hash ref in cols's
//    place, e.g. col2col($data, 'cor', { 'skip.errors' => 1 }).
//    `na` controls how undef is handled when one column is paired with
//    another:
//      'pairwise' (default) - a row counts for the (a,b) pair only if
//          BOTH columns are defined there, so the block gets two equal
//          length, aligned columns. This is what paired stats (cor) want.
//      'omit'   - each column independently drops its own undef values,
//          so the two columns may differ in length. This is what unpaired
//          tests (t_test, kruskal_test) want: a gap in one column must not
//          throw away a good value in the other.
//      'keep'   - every row passes through and undef reaches the block.
//    rm.undef / rm.na (bool) remain as aliases: true => 'pairwise' (the
//    old default), false => 'keep'.
//    skip.errors (bool, default true): a block that croaks for a pair
//    does not abort col2col; instead the first line of its error message
//    is stored as that cell's value, so the result shows which
//    (outer => inner) pair failed and why. Set it false to make a croak
//    propagate and abort the whole call instead.
		SV *restrict cols_eff = cols;
		bool na_set = FALSE, rm_set = FALSE;
#define C2C_DECODE_OPT(ONAME, OL, OVAL) do { \
		if ((OL) == 2 && memEQ((ONAME), "na", 2)) { \
			STRLEN vl_; const char *restrict nv_ = SvPV((OVAL), vl_); \
			if (vl_ == 8 && memEQ(nv_, "pairwise", 8)) na_mode = 0; \
			else if (vl_ == 4 && memEQ(nv_, "omit", 4)) na_mode = 1; \
			else if (vl_ == 4 && memEQ(nv_, "keep", 4)) na_mode = 2; \
			else croak("col2col: na must be 'pairwise', 'omit' or 'keep'"); \
			na_set = TRUE; \
		} else if (((OL) == 8 && memEQ((ONAME), "rm.undef", 8)) || ((OL) == 5 && memEQ((ONAME), "rm.na", 5))) { \
			na_mode = cBOOL(SvTRUE((OVAL))) ? 0 : 2; rm_set = TRUE; \
		} else if ((OL) == 11 && memEQ((ONAME), "skip.errors", 11)) { \
			skip_errors = cBOOL(SvTRUE((OVAL))); \
		} else croak("col2col: unknown option '%s'", (ONAME)); \
		} while (0)
		if (SvROK(cols) && SvTYPE(SvRV(cols)) == SVt_PVHV) {
			// options supplied as a hash ref instead of cols: no column restriction
			HV *restrict oh = (HV*)SvRV(cols);
			HE *restrict he;
			if (items > 3) croak("col2col: an options hash ref must be the last argument");
			hv_iterinit(oh);
			while ((he = hv_iternext(oh))) {
				STRLEN ol;
				const char *restrict oname = HePV(he, ol);
				SV *restrict oval = HeVAL(he);
				C2C_DECODE_OPT(oname, ol, oval);
			}
			cols_eff = &PL_sv_undef;
		} else if (items > 3) {
			if ((items - 3) & 1) croak("col2col: trailing options must be name => value pairs");
			for (int oi = 3; oi < items; oi += 2) {
				STRLEN ol;
				const char *restrict oname = SvPV(ST(oi), ol);
				SV *restrict oval = ST(oi + 1);
				C2C_DECODE_OPT(oname, ol, oval);
			}
		}
		if (na_set && rm_set) croak("col2col: give na or rm.undef, not both");
#undef C2C_DECODE_OPT
		// 1. resolve the command: a CODE block or a function name. Either way
		//    we end up with the CV to call as $cv->($col_a, $col_b).
		if (SvROK(cmd) && SvTYPE(SvRV(cmd)) == SVt_PVCV) cv_sv = SvRV(cmd);
		else if (SvOK(cmd) && !SvROK(cmd)) {
			STRLEN nl;
			const char *restrict name = SvPV(cmd, nl);
			SV *restrict fq = strstr(name, "::") ? newSVpvn(name, nl) : newSVpvf("Stats::LikeR::%s", name);
			CV *restrict cv = get_cv(SvPV_nolen(fq), 0);
			SvREFCNT_dec(fq);
			if (!cv) croak("col2col: unknown function '%s'", name);
			cv_sv = (SV*)cv;
		} else croak("col2col: command must be a CODE ref or a function name");
		// 2. detect the data shape and build per-column value/defined tables.
		if (!SvROK(data)) croak("col2col: data must be a reference");
		{
			SV *restrict rv = SvRV(data);
			short int kind;
			if (SvTYPE(rv) == SVt_PVAV) kind = 1;
			else if (SvTYPE(rv) == SVt_PVHV) {
				HV *restrict h = (HV*)rv;
				hv_iterinit(h);
				HE *restrict e = hv_iternext(h);
				if (!e) croak("col2col: empty data hash");
				SV *restrict first = hv_iterval(h, e);
				if (SvROK(first) && SvTYPE(SvRV(first)) == SVt_PVAV) kind = 0;
				else if (SvROK(first) && SvTYPE(SvRV(first)) == SVt_PVHV) kind = 2;
				else croak("col2col: hash values must be array refs (HoA) or hash refs (HoH)");
			}
			else croak("col2col: data must be an array ref or hash ref");
			if (kind == 0) {
				// hash of arrays: names = keys, rows = longest column.
				HV *restrict h = (HV*)rv;
				AV **restrict src = NULL;
				HE *restrict e;
				hv_iterinit(h);
				while ((e = hv_iternext(h))) {
					SV *restrict val = hv_iterval(h, e);
					if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVAV) continue;
					av_push(names_av, newSVsv(hv_iterkeysv(e)));
					AV *restrict a = (AV*)SvRV(val);
					size_t len = (size_t)(av_len(a) + 1);
					if (len > nrows) nrows = len;
					Renew(src, av_len(names_av) + 1, AV*);
					src[av_len(names_av)] = a;
				}
				ncols = (size_t)(av_len(names_av) + 1);
				Newxz(col_val, ncols ? ncols : 1, NV*);
				Newxz(col_def, ncols ? ncols : 1, char*);
				for (size_t cc = 0; cc < ncols; cc++) {
					Newxz(col_val[cc], nrows ? nrows : 1, NV);
					Newxz(col_def[cc], nrows ? nrows : 1, char);
					AV *restrict a = src[cc];
					for (size_t r = 0; r < nrows; r++) {
						NV v;
						if (c2c_num(aTHX_ av_fetch(a, (SSize_t)r, 0), &v)) { col_val[cc][r] = v; col_def[cc][r] = 1; }
					}
				}
				Safefree(src);
			} else {
				// row-major (array of hashes / hash of hashes): union of keys.
				HV **restrict row_hv = NULL;
				if (kind == 1) {
					AV *restrict a = (AV*)rv;
					nrows = (size_t)(av_len(a) + 1);
					Newxz(row_hv, nrows ? nrows : 1, HV*);
					for (size_t r = 0; r < nrows; r++) {
						SV **restrict ep = av_fetch(a, (SSize_t)r, 0);
						if (ep && *ep && SvROK(*ep) && SvTYPE(SvRV(*ep)) == SVt_PVHV) row_hv[r] = (HV*)SvRV(*ep);
					}
				} else {
					HV *restrict h = (HV*)rv;
					HE *restrict e;
					size_t r = 0;
					nrows = (size_t)HvKEYS(h);
					Newxz(row_hv, nrows ? nrows : 1, HV*);
					hv_iterinit(h);
					while ((e = hv_iternext(h)) && r < nrows) {
						SV *restrict val = hv_iterval(h, e);
						if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) row_hv[r] = (HV*)SvRV(val);
						r++;
					}
				}
				{
					HV *restrict seen = newHV();
					for (size_t r = 0; r < nrows; r++) {
						if (!row_hv[r]) continue;
						HE *restrict e;
						hv_iterinit(row_hv[r]);
						while ((e = hv_iternext(row_hv[r]))) {
							STRLEN kl;
							char *restrict k = HePV(e, kl);
							if (!hv_exists(seen, k, kl)) { (void)hv_store(seen, k, kl, &PL_sv_yes, 0); av_push(names_av, newSVsv(hv_iterkeysv(e))); }
						}
					}
					SvREFCNT_dec((SV*)seen);
				}
				ncols = (size_t)(av_len(names_av) + 1);
				Newxz(col_val, ncols ? ncols : 1, NV*);
				Newxz(col_def, ncols ? ncols : 1, char*);
				for (size_t cc = 0; cc < ncols; cc++) {
					STRLEN kl;
					char *restrict k = SvPV(*av_fetch(names_av, (SSize_t)cc, 0), kl);
					Newxz(col_val[cc], nrows ? nrows : 1, NV);
					Newxz(col_def[cc], nrows ? nrows : 1, char);
					for (size_t r = 0; r < nrows; r++) {
						NV v;
						if (!row_hv[r]) continue;
						if (c2c_num(aTHX_ hv_fetch(row_hv[r], k, kl, 0), &v)) { col_val[cc][r] = v; col_def[cc][r] = 1; }
					}
				}
				Safefree(row_hv);
			}
		}
		if (ncols == 0) croak("col2col: no usable columns found");
		// 3. flatten the column names for fast hv_store keys in the loop.
		SV **restrict col_names;
		STRLEN *restrict name_len;
		Newx(col_names, ncols, SV*);
		Newx(name_len, ncols, STRLEN);
		for (size_t cc = 0; cc < ncols; cc++) {
			col_names[cc] = *av_fetch(names_av, (SSize_t)cc, 0);
			(void)SvPV(col_names[cc], name_len[cc]);
		}
		// 3b. decide which columns may be col_a (the outer/"from" side). With no
		//     restriction every column qualifies; a name or list narrows it.
		char *restrict is_outer;
		Newxz(is_outer, ncols, char);
		if (!SvOK(cols_eff)) {
			for (size_t cc = 0; cc < ncols; cc++) is_outer[cc] = 1;
		}
		else if (SvROK(cols_eff) && SvTYPE(SvRV(cols_eff)) == SVt_PVAV) {
			AV *restrict want = (AV*)SvRV(cols_eff);
			SSize_t n = av_len(want) + 1;
			for (SSize_t i = 0; i < n; i++) {
				SV **restrict ep = av_fetch(want, i, 0);
				STRLEN wl;
				const char *restrict wname;
				if (!ep || !*ep || !SvOK(*ep)) croak("col2col: column list contains an undefined entry");
				wname = SvPV(*ep, wl);
				if (!c2c_mark(col_names, name_len, ncols, wname, wl, is_outer)) croak("col2col: column '%s' not found in data", wname);
			}
		} else if (!SvROK(cols_eff)) {
			STRLEN wl;
			const char *restrict wname = SvPV(cols_eff, wl);
			if (!c2c_mark(col_names, name_len, ncols, wname, wl, is_outer)) croak("col2col: column '%s' not found in data", wname);
		} else croak("col2col: cols must be a column name or an array ref of names");
		// 4. each selected column vs every other column. The two columns reach
		//    the block as @_ = ($col_a, $col_b); how undef is handled depends on
		//    na (section 0): 'pairwise' drops a row missing in either side (equal
		//    aligned lengths, for cor); 'omit' drops each column's own undef
		//    independently (lengths may differ, for t_test / kruskal_test);
		//    'keep' passes every row through with undef in the gaps.
		HV *restrict out_hv = newHV();
		for (size_t a = 0; a < ncols; a++) {
			HV *restrict inner;
			if (!is_outer[a]) continue;
			inner = newHV();
			for (size_t b = 0; b < ncols; b++) {
				AV *restrict ca, *restrict cb;
				SV *restrict rv1, *restrict rv2, *restrict res;
				if (a == b) continue;
				ca = newAV();
				cb = newAV();
				if (na_mode == 0) { // pairwise complete: keep rows defined in both
					for (size_t r = 0; r < nrows; r++)
						if (col_def[a][r] && col_def[b][r]) { av_push(ca, newSVnv(col_val[a][r])); av_push(cb, newSVnv(col_val[b][r])); }
				} else if (na_mode == 1) { // omit: each column drops its own undef (lengths may differ)
					for (size_t r = 0; r < nrows; r++) if (col_def[a][r]) av_push(ca, newSVnv(col_val[a][r]));
					for (size_t r = 0; r < nrows; r++) if (col_def[b][r]) av_push(cb, newSVnv(col_val[b][r]));
				} else { // keep: every row, undef passed through
					for (size_t r = 0; r < nrows; r++) {
						av_push(ca, col_def[a][r] ? newSVnv(col_val[a][r]) : newSV(0));
						av_push(cb, col_def[b][r] ? newSVnv(col_val[b][r]) : newSV(0));
					}
				}
				rv1 = newRV_noinc((SV*)ca);
				rv2 = newRV_noinc((SV*)cb);
				if (av_len(ca) < 0 || av_len(cb) < 0) {
					res = newSV(0);	// a column had no usable values for this pair
				} else if (!skip_errors) {
					res = c2c_call(aTHX_ cv_sv, rv1, rv2);	// a croak here propagates
				} else {
					// skip.errors: run the block under eval; on a croak keep the
					// first line of its message as this cell so the caller sees
					// which pair failed and why instead of the whole call dying.
					dSP;
					int n;
					ENTER; SAVETMPS;
					PUSHMARK(SP);
					XPUSHs(rv1); XPUSHs(rv2);
					PUTBACK;
					n = call_sv(cv_sv, G_SCALAR | G_EVAL);
					SPAGAIN;
					if (SvTRUE(ERRSV)) {
						STRLEN el;
						const char *restrict ep = SvPV(ERRSV, el);
						STRLEN ll = 0;	// length of the first line only
						while (ll < el && ep[ll] != '\n' && ep[ll] != '\r') ll++;
						res = newSVpvn(ep, ll);
						if (n > 0) (void)POPs;	// discard the undef G_SCALAR leaves
					} else {
						res = (n > 0) ? newSVsv(POPs) : newSV(0);
					}
					PUTBACK;
					FREETMPS; LEAVE;
				}
				(void)hv_store(inner, SvPVX(col_names[b]), (I32)name_len[b], res, 0);
				SvREFCNT_dec(rv1);
				SvREFCNT_dec(rv2);
			}
			(void)hv_store(out_hv, SvPVX(col_names[a]), (I32)name_len[a], newRV_noinc((SV*)inner), 0);
		}
		// 5. tidy up.
		for (size_t cc = 0; cc < ncols; cc++) { Safefree(col_val[cc]); Safefree(col_def[cc]); }
		Safefree(col_val);	Safefree(col_def); Safefree(col_names);
		Safefree(name_len);	Safefree(is_outer);	SvREFCNT_dec((SV*)names_av);
		RETVAL = newRV_noinc((SV*)out_hv);
	}
	OUTPUT:
		RETVAL

SV *
oneway_test(data_ref, ...)
	SV *data_ref
	PREINIT:
		HV          *restrict in_hv = NULL;
		AV          *restrict in_av = NULL;
		HE          *restrict he;
		bool         var_equal = 0;
		const char  *restrict formula_str = NULL;
		const char  *restrict factor_name = "Group";
		char        *lhs = NULL, *rhs = NULL;
		NV          *restrict flat   = NULL;
		size_t      *restrict sizes  = NULL;
		char       **gnames = NULL;
		NV          *restrict gmeans = NULL;
		size_t       k = 0;
		IV           total_n = 0;
		OneWayResult res;
		HV          *restrict ret_hv;
		char         errbuf[512];
	CODE:
	{
		/* ---- parse named arguments ---- */
		for (I32 ai = 1; ai + 1 < items; ai += 2) {
			const char *restrict key = SvPV_nolen(ST(ai));
			SV         *restrict val = ST(ai + 1);
			if (strEQ(key, "var_equal") || strEQ(key, "var.equal"))
				var_equal = SvTRUE(val) ? 1 : 0;
			else if (strEQ(key, "formula"))
				formula_str = SvPV_nolen(val);
		}

		/* ---- validate data_ref: must be an ARRAY or HASH reference ---- */
		if (!SvROK(data_ref))
			croak("oneway_test: first argument must be a hash or array reference");
		SV *restrict rv = SvRV(data_ref);
		if      (SvTYPE(rv) == SVt_PVHV) in_hv = (HV *)rv;
		else if (SvTYPE(rv) == SVt_PVAV) in_av = (AV *)rv;
		else croak("oneway_test: first argument must be a hash or array reference");

		if (in_av) {
			/* ---- MODE 3: array of arrays (AoA) ---- */
			if (formula_str != NULL)
				croak("oneway_test: formula mode is not supported with an array of arrays");

			k = (size_t)(av_len(in_av) + 1);          /* +1 inside the signed math */
			if (k < 2)
				croak("oneway_test: need at least 2 groups, got %zu", k);

			Newx(sizes,   k, size_t);
			Newxz(gnames, k, char *);                  /* zeroed: safe to free on error */

			/* first pass: validate, sizes, total_n, synthesised names */
			for (size_t g = 0; g < k; g++) {
				SV **restrict val = av_fetch(in_av, (I32)g, 0);
				if (!val || !*val || !SvROK(*val) || SvTYPE(SvRV(*val)) != SVt_PVAV) {
					snprintf(errbuf, sizeof errbuf, "index %zu is not an array reference", g);
					goto fail;
				}
				IV len = av_len((AV *)SvRV(*val)) + 1;
				if (len < 2) {
					snprintf(errbuf, sizeof errbuf, "index %zu has fewer than 2 observations", g);
					goto fail;
				}
				sizes[g] = (size_t)len;
				total_n += len;
				char buf[64];
				snprintf(buf, sizeof buf, "Index %zu", g);
				gnames[g] = savepv(buf);               /* perl-managed copy */
			}

			/* second pass: fill flat, validating each cell */
			Newx(flat, (size_t)total_n, NV);
			size_t offset = 0;
			for (size_t g = 0; g < k; g++) {
				AV *restrict av = (AV *)SvRV(*av_fetch(in_av, (I32)g, 0));
				IV len = av_len(av) + 1;
				for (IV i = 0; i < len; i++) {
					SV **restrict svp = av_fetch(av, i, 0);
					if (!svp || !*svp || !SvOK(*svp) || !looks_like_number(*svp)) {
						snprintf(errbuf, sizeof errbuf,
							"index %zu, observation %ld is undefined or non-numeric",
							g, (long)i);
						goto fail;
					}
					flat[offset++] = SvNV(*svp);
				}
			}
		}
		else if (formula_str != NULL) {
			/* ---- MODE 2: formula "response ~ factor" ---- */
			if (!parse_formula(formula_str, &lhs, &rhs))
				croak("oneway_test: cannot parse formula '%s' — expected 'response ~ factor'",
					formula_str);
			factor_name = rhs;                          /* freed after output */

			SV **restrict resp_svp = hv_fetch(in_hv, lhs, (I32)strlen(lhs), 0);
			if (!resp_svp || !*resp_svp || !SvROK(*resp_svp)
					|| SvTYPE(SvRV(*resp_svp)) != SVt_PVAV) {
				snprintf(errbuf, sizeof errbuf,
					"formula LHS '%s' not found as an array ref in the hash", lhs);
				goto fail;                              /* was leaking lhs/rhs */
			}
			SV **restrict fact_svp = hv_fetch(in_hv, rhs, (I32)strlen(rhs), 0);
			if (!fact_svp || !*fact_svp || !SvROK(*fact_svp)
					|| SvTYPE(SvRV(*fact_svp)) != SVt_PVAV) {
				snprintf(errbuf, sizeof errbuf,
					"formula RHS '%s' not found as an array ref in the hash", rhs);
				goto fail;                              /* was leaking lhs/rhs */
			}

			AV *restrict resp_av  = (AV *)SvRV(*resp_svp);
			AV *restrict label_av = (AV *)SvRV(*fact_svp);
			IV  n = av_len(resp_av) + 1;
			Newx(flat,  (size_t)(n > 0 ? n : 0), NV);
			Newx(sizes, (size_t)(n > 0 ? n : 0), size_t);   /* k <= n upper bound */

			if (!build_groups_from_formula(aTHX_ resp_av, label_av,
					flat, sizes, &k, &gnames, errbuf, sizeof errbuf))
				goto fail;                              /* errbuf already set; fail frees all */

			for (size_t g = 0; g < k; g++) total_n += (IV)sizes[g];
		}
		else {
			/* ---- MODE 1: hash of groups { label => \@obs, ... } ---- */
			k = (size_t)HvUSEDKEYS(in_hv);              /* robust count, not iterinit's */
			if (k < 2)
				croak("oneway_test: need at least 2 groups, got %zu", k);

			Newx(sizes,   k, size_t);
			Newxz(gnames, k, char *);

			/* first pass: validate, sizes, total_n, key strings */
			hv_iterinit(in_hv);
			for (size_t g = 0; (he = hv_iternext(in_hv)) != NULL; g++) {
				SV *restrict val = HeVAL(he);
				if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVAV) {
					snprintf(errbuf, sizeof errbuf,
						"value for group '%s' is not an array ref", HePV(he, PL_na));
					goto fail;
				}
				IV len = av_len((AV *)SvRV(val)) + 1;
				if (len < 2) {
					snprintf(errbuf, sizeof errbuf,
						"group '%s' has fewer than 2 observations", HePV(he, PL_na));
					goto fail;
				}
				sizes[g] = (size_t)len;
				total_n += len;
				STRLEN klen;
				const char *kstr = HePV(he, klen);
				gnames[g] = savepvn(kstr, klen);        /* keeps embedded NULs */
			}

			/* second pass: fill flat in the same iteration order, validating */
			Newx(flat, (size_t)total_n, NV);
			size_t offset = 0;
			hv_iterinit(in_hv);
			while ((he = hv_iternext(in_hv)) != NULL) {
				AV *restrict av  = (AV *)SvRV(HeVAL(he));
				IV  len = av_len(av) + 1;
				for (IV i = 0; i < len; i++) {
					SV **restrict svp = av_fetch(av, i, 0);
					if (!svp || !*svp || !SvOK(*svp) || !looks_like_number(*svp)) {
						snprintf(errbuf, sizeof errbuf,
							"group '%s', observation %ld is undefined or non-numeric",
							HePV(he, PL_na), (long)i);
						goto fail;
					}
					flat[offset++] = SvNV(*svp);
				}
			}
		}

		/* ---- per-group means from flat (computed before the arithmetic) ---- */
		Newx(gmeans, k, NV);
		{
			size_t offset = 0;
			for (size_t g = 0; g < k; g++) {
				NV sum = 0.0;
				for (size_t i = 0; i < sizes[g]; i++) sum += flat[offset + i];
				gmeans[g] = sum / (NV)sizes[g];
				offset += sizes[g];
			}
		}

		res = c_oneway_test(flat, sizes, k, var_equal);
		Safefree(flat); flat = NULL;

		/* ---- build the return hash ---- */
		ret_hv = (HV *)sv_2mortal((SV *)newHV());
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
		{
			HV *restrict r_hv = newHV();
			hv_stores(r_hv, "Df",      newSVnv(res.denom_df));
			hv_stores(r_hv, "Sum Sq",  newSVnv(res.ss_within));
			hv_stores(r_hv, "Mean Sq", newSVnv(res.ms_within));
			hv_stores(ret_hv, "Residuals", newRV_noinc((SV *)r_hv));
		}
		{
			HV *restrict gs_hv   = newHV();
			HV *restrict mean_hv = newHV();
			HV *restrict size_hv = newHV();
			for (size_t g = 0; g < k; g++) {
				const char *restrict gn = gnames[g];
				I32 gnl = (I32)strlen(gn);
				hv_store(mean_hv, gn, gnl, newSVnv(gmeans[g]),    0);
				hv_store(size_hv, gn, gnl, newSViv((IV)sizes[g]), 0);
			}
			hv_stores(gs_hv, "mean", newRV_noinc((SV *)mean_hv));
			hv_stores(gs_hv, "size", newRV_noinc((SV *)size_hv));
			hv_stores(ret_hv, "group_stats", newRV_noinc((SV *)gs_hv));
		}

		/* ---- normal cleanup ---- */
		Safefree(gmeans);
		Safefree(sizes);
		for (size_t g = 0; g < k; g++) Safefree(gnames[g]);
		Safefree(gnames);
		if (lhs) Safefree(lhs);
		if (rhs) Safefree(rhs);

		RETVAL = newRV_inc((SV *)ret_hv);
	}

	if (0) {
	fail:
		/* single cleanup point for every error after an allocation */
		if (flat)   Safefree(flat);
		if (sizes)  Safefree(sizes);
		if (gnames) {
			for (size_t g = 0; g < k; g++) if (gnames[g]) Safefree(gnames[g]);
			Safefree(gnames);
		}
		if (gmeans) Safefree(gmeans);
		if (lhs) Safefree(lhs);
		if (rhs) Safefree(rhs);
		croak("oneway_test: %s", errbuf);
	}
	OUTPUT:
		RETVAL

SV* ks_test(...)
CODE:
{
    /* NOTE: these may legitimately alias (e.g. ks_test(\@a, \@a)), so no
     * `restrict` here — only the private C buffers below get it. */
    SV *restrict x_sv = NULL, *restrict y_sv = NULL;
    short int exact = -1;
    const char *restrict alternative = "two.sided";
    int arg_idx = 0;

    /* Leading positional 'x' (array ref). */
    if (arg_idx < items && SvROK(ST(arg_idx)) && SvTYPE(SvRV(ST(arg_idx))) == SVt_PVAV) {
        x_sv = ST(arg_idx);
        arg_idx++;
    }

    /* Optional positional 'y':
     *   - an ARRAY ref  -> 2-sample (keys are never array refs, so safe)
     *   - a STRING      -> 1-sample CDF name, BUT only if consuming it leaves
     *                      an even number of trailing args. Otherwise the
     *                      "string" is really a named-argument key (e.g.
     *                      "exact", "alternative") and must not be eaten here.
     *                      (Fix #1) */
    if (arg_idx < items) {
        if (SvROK(ST(arg_idx)) && SvTYPE(SvRV(ST(arg_idx))) == SVt_PVAV) {
            y_sv = ST(arg_idx);
            arg_idx++;
        } else if (SvPOK(ST(arg_idx)) && (((items - arg_idx) % 2) == 1)) {
            y_sv = ST(arg_idx);   /* positional 1-sample CDF, e.g. "pnorm" */
            arg_idx++;
        }
    }

    /* Named arguments (key => value pairs). */
    for (; arg_idx < items; arg_idx += 2) {
        const char *restrict key = SvPV_nolen(ST(arg_idx));
        SV *restrict val;
        if (arg_idx + 1 >= items)      /* Fix #2: no value -> would read off stack */
            croak("ks_test: argument '%s' is missing a value", key);
        val = ST(arg_idx + 1);
        if      (strEQ(key, "x"))           x_sv = val;
        else if (strEQ(key, "y"))           y_sv = val;
        else if (strEQ(key, "exact")) {
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
    bool is_greater   = strEQ(alternative, "greater")   ? 1 : 0;
    bool is_less      = strEQ(alternative, "less")      ? 1 : 0;

    if (!is_two_sided && !is_greater && !is_less) {
        croak("ks_test: alternative must be 'two.sided', 'less', or 'greater'");
    }

    AV *x_av = (AV *)SvRV(x_sv);
    size_t nx = (size_t)(av_len(x_av) + 1);
    if (nx == 0) croak("Not enough 'x' observations");

    /* Extract 'x' to a C array (numeric elements only). */
    NV *restrict x_data = (NV *)safemalloc(nx * sizeof(NV));
    size_t valid_nx = 0;
    for (size_t i = 0; i < nx; i++) {
        SV **el = av_fetch(x_av, i, 0);
        if (el && *el && (SvNIOK(*el) || (SvOK(*el) && looks_like_number(*el)))) {
            x_data[valid_nx++] = SvNV(*el);   /* SvNIOK shortcut avoids string parse */
        }
    }
    /* Fix #4: guard before any path can divide by valid_nx. */
    if (valid_nx < 1) {
        Safefree(x_data);
        croak("Not enough non-missing 'x' observations");
    }

    NV statistic = 0.0, p_value = 0.0;
    const char *method_desc = "";

    /* ----------------------------- TWO SAMPLE ----------------------------- */
    if (y_sv && SvROK(y_sv) && SvTYPE(SvRV(y_sv)) == SVt_PVAV) {
        AV *y_av = (AV *)SvRV(y_sv);
        size_t ny = (size_t)(av_len(y_av) + 1);
        NV *restrict y_data = (NV *)safemalloc((ny ? ny : 1) * sizeof(NV));
        size_t valid_ny = 0;
        for (size_t i = 0; i < ny; i++) {
            SV **el = av_fetch(y_av, i, 0);
            if (el && *el && (SvNIOK(*el) || (SvOK(*el) && looks_like_number(*el)))) {
                y_data[valid_ny++] = SvNV(*el);
            }
        }
        if (valid_ny < 1) {
            Safefree(x_data); Safefree(y_data);
            croak("Not enough non-missing observations for KS test");
        }

        NV d, d_plus, d_minus;
        calc_2sample_stats(x_data, valid_nx, y_data, valid_ny, &d, &d_plus, &d_minus);
        if (is_greater)   statistic = d_plus;
        else if (is_less) statistic = d_minus;
        else              statistic = d;

        /* Decide exact vs asymptotic. Use a double product so the threshold
         * comparison itself can't overflow size_t. */
        double mn = (double)valid_nx * (double)valid_ny;
        bool use_exact;
        if      (exact == 1) use_exact = TRUE;
        else if (exact == 0) use_exact = FALSE;
        else                 use_exact = (mn < 10000.0);

        /* Fix #6: cap the cost of a *forced* exact run. */
        if (use_exact && mn > KS_EXACT_MAX_PRODUCT) {
            warn("ks_test: sample sizes too large for an exact p-value; using asymptotic");
            use_exact = FALSE;
        }

        /* Tie detection is only needed for the exact path. Both arrays are
         * already sorted by calc_2sample_stats(), so detect ties with an O(N)
         * merge instead of concatenate + re-sort. (Speed/RAM improvement.) */
        if (use_exact) {
            bool has_ties = FALSE;
            size_t a = 0, b = 0;
            NV prev = 0; bool have_prev = FALSE;
            while (a < valid_nx || b < valid_ny) {
                NV v = (b >= valid_ny || (a < valid_nx && x_data[a] <= y_data[b]))
                       ? x_data[a++] : y_data[b++];
                if (have_prev && v == prev) { has_ties = TRUE; break; }
                prev = v; have_prev = TRUE;
            }
            if (has_ties) {
                warn("ks_test: cannot compute exact p-value with ties; falling back to asymptotic");
                use_exact = FALSE;
            }
        }

        if (use_exact) {
            method_desc = "Two-sample Kolmogorov-Smirnov exact test";
            NV q = (0.5 + floor(statistic * valid_nx * valid_ny - 1e-7))
                   / ((NV)valid_nx * (NV)valid_ny);
            /* One-sided 'less' uses the D+ routine directly; correct when
             * valid_nx == valid_ny and a documented approximation otherwise. */
            p_value = psmirnov_exact_uniq_upper(q, valid_nx, valid_ny, is_two_sided);
        } else {
            method_desc = "Two-sample Kolmogorov-Smirnov test (asymptotic)";
            /* Overflow-safe scaling: cast each operand to NV before multiplying. */
            NV z = statistic * sqrt(((NV)valid_nx * (NV)valid_ny)
                                    / ((NV)valid_nx + (NV)valid_ny));
            if (is_two_sided) p_value = K2l(z, 0, 1e-9);
            else              p_value = exp(-2.0 * z * z);
        }
        Safefree(y_data);
    // 1 SAMPLE
    } else if (y_sv && SvPOK(y_sv)) {
        const char *restrict dist = SvPV_nolen(y_sv);
        if (strEQ(dist, "pnorm")) {
            qsort(x_data, valid_nx, sizeof(NV), compare_NVs);
            NV max_d = 0.0, max_d_plus = 0.0, max_d_minus = 0.0;
            for (size_t i = 0; i < valid_nx; i++) {
                NV cdf_obs_low  = (NV)i / valid_nx;
                NV cdf_obs_high = (NV)(i + 1) / valid_nx;
                NV cdf_theor    = approx_pnorm(x_data[i]);
                NV diff1 = cdf_obs_low  - cdf_theor;
                NV diff2 = cdf_obs_high - cdf_theor;
                if (diff1 > max_d_plus)  max_d_plus  = diff1;
                if (diff2 > max_d_plus)  max_d_plus  = diff2;
                if (-diff1 > max_d_minus) max_d_minus = -diff1;
                if (-diff2 > max_d_minus) max_d_minus = -diff2;
                if (fabs(diff1) > max_d) max_d = fabs(diff1);
                if (fabs(diff2) > max_d) max_d = fabs(diff2);
            }
            if (is_greater)   statistic = max_d_plus;
            else if (is_less) statistic = max_d_minus;
            else              statistic = max_d;

            bool use_exact = (exact == -1) ? (valid_nx < 100) : (exact == 1);
            if (use_exact) {
                method_desc = "One-sample Kolmogorov-Smirnov exact test";
                if (is_two_sided) {
                    p_value = 1.0 - K2x(valid_nx, statistic);
                } else {
                    warn("exact 1-sample 1-sided KS test not implemented; using asymptotic");
                    NV z = statistic * sqrt((NV)valid_nx);
                    p_value = exp(-2.0 * z * z);
                }
            } else {
                method_desc = "One-sample Kolmogorov-Smirnov test (asymptotic)";
                NV z = statistic * sqrt((NV)valid_nx);
                if (is_two_sided) p_value = K2l(z, 0, 1e-6);
                else              p_value = exp(-2.0 * z * z);
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
    hv_stores(res, "statistic",   newSVnv(statistic));
    hv_stores(res, "p_value",     newSVnv(p_value));
    hv_stores(res, "method",      newSVpv(method_desc, 0));
    hv_stores(res, "alternative", newSVpv(alternative, 0));
    RETVAL = newRV_noinc((SV *)res);
}
OUTPUT:
    RETVAL

SV* wilcox_test(...)
CODE:
{
	SV *restrict x_sv = NULL, *restrict y_sv = NULL;
	bool paired = FALSE, correct = TRUE;
	NV mu = 0.0;
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
	// FIX 1: validate 'alternative' rather than silently falling through to two-sided
	if (strNE(alternative, "two.sided") && strNE(alternative, "less") && strNE(alternative, "greater"))
		croak("wilcox_test: 'alternative' must be one of 'two.sided', 'less', 'greater'");
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
	NV p_value = 0.0, statistic = 0.0;
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
		NV tie_adj = rank_and_count_ties(ri, total_n, &has_ties);
		NV w_rank_sum = 0.0;
		for (size_t i = 0; i < total_n; i++) if (ri[i].idx == 1) w_rank_sum += ri[i].rank;
		statistic = w_rank_sum - (NV)valid_nx * (valid_nx + 1.0) / 2.0;
		if (exact == 1) use_exact = TRUE;
		else if (exact == 0) use_exact = FALSE;
		else use_exact = (valid_nx < 50 && valid_ny < 50 && !has_ties);
		if (use_exact && has_ties) {
			warn("wilcox_test: cannot compute exact p-value with ties; falling back to approximation");
			use_exact = FALSE;
		}
		if (use_exact) {
			method_desc = "Wilcoxon rank sum exact test";
			NV p_less = exact_pwilcox(statistic, valid_nx, valid_ny);
			NV p_greater = 1.0 - exact_pwilcox(statistic - 1.0, valid_nx, valid_ny);

			if (strcmp(alternative, "less") == 0) p_value = p_less;
			else if (strcmp(alternative, "greater") == 0) p_value = p_greater;
			else {
				NV p = (p_less < p_greater) ? p_less : p_greater;
				p_value = 2.0 * p;
			}
		} else {
			method_desc = correct ? "Wilcoxon rank sum test with continuity correction" : "Wilcoxon rank sum test";
			NV mean_w = (NV)valid_nx * valid_ny / 2.0;	// FIX 4: was 'exp' (shadowed libm exp)
			NV var = ((NV)valid_nx * valid_ny / 12.0) * ((total_n + 1.0) - tie_adj / ((NV)total_n * (total_n - 1.0)));
			NV z = statistic - mean_w;
			NV CORRECTION = 0.0;
			if (correct) {
				// FIX 3: sign(z)*0.5, so z == 0 -> 0 (not -0.5)
				if (strcmp(alternative, "two.sided") == 0) CORRECTION = (z > 0) ? 0.5 : (z < 0) ? -0.5 : 0.0;
				else if (strcmp(alternative, "greater") == 0) CORRECTION = 0.5;
				else if (strcmp(alternative, "less") == 0) CORRECTION = -0.5;
			}
			// FIX 2: guard against degenerate (all-tied) variance instead of dividing by zero
			if (var <= 0.0) {
				warn("wilcox_test: zero variance (all values tied); p-value is undefined");
				p_value = 1.0;
			} else {
				z = (z - CORRECTION) / sqrt(var);
				if (strcmp(alternative, "less") == 0) p_value = approx_pnorm(z);
				else if (strcmp(alternative, "greater") == 0) p_value = 1.0 - approx_pnorm(z);
				else p_value = 2.0 * approx_pnorm(-fabs(z));
			}
		}
		Safefree(ri);
	} else { // --- 1 SAMPLE / PAIRED ---
		if (paired && (!y_av || nx != ny)) croak("'x' and 'y' must have the same length for paired test");
		NV *restrict diffs = (NV *)safemalloc(nx * sizeof(NV));
		size_t n_nz = 0;
		bool has_zeroes = FALSE;
		for (size_t i = 0; i < nx; i++) {
			SV**restrict x_el = av_fetch(x_av, i, 0);
			if (!x_el || !SvOK(*x_el) || !looks_like_number(*x_el)) continue;
			NV dx = SvNV(*x_el);

			if (paired) {
				SV**restrict y_el = av_fetch(y_av, i, 0);
				if (!y_el || !SvOK(*y_el) || !looks_like_number(*y_el)) continue;
				NV dy = SvNV(*y_el);
				NV d = dx - dy - mu;
				if (d == 0.0) has_zeroes = TRUE; // Drop exact zeroes
				else diffs[n_nz++] = d;
			} else {
				NV d = dx - mu;
				if (d == 0.0) has_zeroes = TRUE;
				else diffs[n_nz++] = d;
			}
		}
		if (n_nz == 0) {
			Safefree(diffs);
			croak("not enough (non-missing) observations");
		}
		RankInfo *restrict ri = (RankInfo *)safemalloc(n_nz * sizeof(RankInfo));
		for (size_t i = 0; i < n_nz; i++) {
			ri[i].val = fabs(diffs[i]);
			ri[i].idx = (diffs[i] > 0);
		}
		bool has_ties = 0;
		NV tie_adj = rank_and_count_ties(ri, n_nz, &has_ties);
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
			method_desc = "Wilcoxon signed rank exact test";	// FIX 5: was an identical-branch ternary
			NV p_less = exact_psignrank(statistic, n_nz);
			NV p_greater = 1.0 - exact_psignrank(statistic - 1.0, n_nz);

			if (strcmp(alternative, "less") == 0) p_value = p_less;
			else if (strcmp(alternative, "greater") == 0) p_value = p_greater;
			else {
				NV p = (p_less < p_greater) ? p_less : p_greater;
				p_value = 2.0 * p;
			}
		} else {
			method_desc = correct ? "Wilcoxon signed rank test with continuity correction" : "Wilcoxon signed rank test";
			NV mean_v = (NV)n_nz * (n_nz + 1.0) / 4.0;	// FIX 4: was 'exp'
			NV var = (n_nz * (n_nz + 1.0) * (2.0 * n_nz + 1.0) / 24.0) - (tie_adj / 48.0);
			NV z = statistic - mean_v;
			NV CORRECTION = 0.0;
			if (correct) {
				// FIX 3: sign(z)*0.5
				if (strcmp(alternative, "two.sided") == 0) CORRECTION = (z > 0) ? 0.5 : (z < 0) ? -0.5 : 0.0;
				else if (strcmp(alternative, "greater") == 0) CORRECTION = 0.5;
				else if (strcmp(alternative, "less") == 0) CORRECTION = -0.5;
			}

			// FIX 2: guard against degenerate variance
			if (var <= 0.0) {
				warn("wilcox_test: zero variance (all values tied); p-value is undefined");
				p_value = 1.0;
			} else {
				z = (z - CORRECTION) / sqrt(var);
				if (strcmp(alternative, "less") == 0) p_value = approx_pnorm(z);
				else if (strcmp(alternative, "greater") == 0) p_value = 1.0 - approx_pnorm(z);
				else p_value = 2.0 * approx_pnorm(-fabs(z));
			}
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
	// 1. Input Validation & Data Matrix Construction
	if (!SvROK(data_ref)) {
		croak("Input must be a reference");
	}

	svtype input_type = SvTYPE(SvRV(data_ref));
	if (input_type != SVt_PVAV && input_type != SVt_PVHV) {
		croak("Input must be an array reference or a hash reference");
	}

	NV **restrict obs_matrix = NULL;
	NV *restrict obs_array = NULL;
	AV*restrict row_keys = NULL;
	AV*restrict col_keys = NULL;
	unsigned int r = 0, c = 0;
	bool is_2d = 0;

	if (input_type == SVt_PVAV) {
		AV*restrict obs_av = (AV*)SvRV(data_ref);
		r = av_top_index(obs_av) + 1;
		if (r > 0) {
			SV**restrict first_elem = av_fetch(obs_av, 0, 0);
			if (first_elem && SvROK(*first_elem) && SvTYPE(SvRV(*first_elem)) == SVt_PVAV) {
				is_2d = 1;
				c = av_top_index((AV*)SvRV(*first_elem)) + 1;
				obs_matrix = (NV**)safemalloc(r * sizeof(NV*));
				for (unsigned int i = 0; i < r; i++) {
					obs_matrix[i] = (NV*)safecalloc(c, sizeof(NV));
					SV**restrict row_sv = av_fetch(obs_av, i, 0);
					if (row_sv && SvROK(*row_sv)) {
						AV*restrict row_av = (AV*)SvRV(*row_sv);
						for (unsigned int j = 0; j < c; j++) {
							SV**restrict val_sv = av_fetch(row_av, j, 0);
							if (val_sv) obs_matrix[i][j] = SvNV(*val_sv);
						}
					}
				}
			} else {
				c = r;
				r = 1;
				obs_array = (NV*)safemalloc(c * sizeof(NV));
				for (unsigned int j = 0; j < c; j++) {
					SV**restrict val_sv = av_fetch(obs_av, j, 0);
					if (val_sv) obs_array[j] = SvNV(*val_sv);
				}
			}
		}
	} else if (input_type == SVt_PVHV) {
		HV*restrict obs_hv = (HV*)SvRV(data_ref);
		row_keys = newAV();
		col_keys = newAV();

		HE*restrict first_entry;
		hv_iterinit(obs_hv);
		first_entry = hv_iternext(obs_hv);

		if (first_entry) {
			SV*restrict first_val = hv_iterval(obs_hv, first_entry);
			if (SvROK(first_val) && SvTYPE(SvRV(first_val)) == SVt_PVHV) {
				is_2d = 1;
				HV*restrict col_idx_map = newHV();
				hv_iterinit(obs_hv);
				HE*restrict row_entry;
				while ((row_entry = hv_iternext(obs_hv))) {
					av_push(row_keys, newSVsv(hv_iterkeysv(row_entry)));
					r++;
					SV*restrict inner_sv = hv_iterval(obs_hv, row_entry);
					if (SvROK(inner_sv) && SvTYPE(SvRV(inner_sv)) == SVt_PVHV) {
						HV*restrict inner_hv = (HV*)SvRV(inner_sv);
						HE*restrict col_entry;
						hv_iterinit(inner_hv);
						while ((col_entry = hv_iternext(inner_hv))) {
							SV*restrict col_key = hv_iterkeysv(col_entry);
							if (!hv_exists_ent(col_idx_map, col_key, 0)) {
								hv_store_ent(col_idx_map, col_key, newSViv(c), 0);
								av_push(col_keys, newSVsv(col_key));
								c++;
							}
						}
					}
				}

				obs_matrix = (NV**)safemalloc(r * sizeof(NV*));
				for (unsigned int i = 0; i < r; i++) {
					obs_matrix[i] = (NV*)safecalloc(c, sizeof(NV));
					SV**restrict row_key_sv = av_fetch(row_keys, i, 0);
					
					// FIX 1: Extract HE* instead of SV**
					HE* inner_he = hv_fetch_ent(obs_hv, *row_key_sv, 0, 0);
					if (inner_he) {
						SV*restrict inner_sv = HeVAL(inner_he);
						if (SvROK(inner_sv)) {
							HV*restrict inner_hv = (HV*)SvRV(inner_sv);
							for (unsigned int j = 0; j < c; j++) {
								SV**restrict col_key_sv = av_fetch(col_keys, j, 0);
								
								// FIX 2: Extract HE* instead of SV**
								HE*restrict val_he = hv_fetch_ent(inner_hv, *col_key_sv, 0, 0);
								if (val_he) {
									obs_matrix[i][j] = SvNV(HeVAL(val_he));
								}
							}
						}
					}
				}
				SvREFCNT_dec(col_idx_map);
			} else {
				// 1D Hash Handling
				hv_iterinit(obs_hv);
				HE*restrict row_entry;
				while ((row_entry = hv_iternext(obs_hv))) {
					av_push(col_keys, newSVsv(hv_iterkeysv(row_entry)));
					c++;
				}
				obs_array = (NV*)safemalloc(c * sizeof(NV));
				for (unsigned int j = 0; j < c; j++) {
					SV**restrict col_key_sv = av_fetch(col_keys, j, 0);
					// FIX 3: Extract HE* instead of SV**
					HE*restrict val_he = hv_fetch_ent(obs_hv, *col_key_sv, 0, 0);
					if (val_he) {
						obs_array[j] = SvNV(HeVAL(val_he));
					}
				}
			}
		}
	}

	if ((is_2d && (r == 0 || c == 0)) || (!is_2d && c == 0)) {
		croak("Empty data structure");
	}

	// 2. Perform Math Algorithm
	NV stat = 0.0, grand_total = 0.0;
	unsigned int df = 0;
	bool yates = (is_2d && r == 2 && c == 2) ? 1 : 0;
	SV*restrict expected_ref = NULL;

	if (is_2d) {
		NV *restrict row_sum = (NV*)safemalloc(r * sizeof(NV));
		NV *restrict col_sum = (NV*)safemalloc(c * sizeof(NV));
		for(unsigned int i=0; i<r; i++) row_sum[i] = 0.0;
		for(unsigned int j=0; j<c; j++) col_sum[j] = 0.0;

		for (unsigned int i = 0; i < r; i++) {
			for (unsigned int j = 0; j < c; j++) {
				NV val = obs_matrix[i][j];
				row_sum[i] += val;
				col_sum[j] += val;
				grand_total += val;
			}
		}

		if (input_type == SVt_PVAV) {
			AV*restrict expected_av = newAV();
			for (unsigned int i = 0; i < r; i++) {
				AV*restrict exp_row = newAV();
				for (unsigned int j = 0; j < c; j++) {
					NV E = (row_sum[i] * col_sum[j]) / grand_total;
					NV O = obs_matrix[i][j];
					av_push(exp_row, newSVnv(E));
					if (yates) {
						NV abs_diff = fabs(O - E);
						NV y_corr = (abs_diff > 0.5) ? 0.5 : abs_diff;
						NV diff = abs_diff - y_corr;
						stat += (diff * diff) / E;
					} else {
						stat += ((O - E) * (O - E)) / E;
					}
				}
				av_push(expected_av, newRV_noinc((SV*)exp_row));
			}
			expected_ref = newRV_noinc((SV*)expected_av);
		} else { // SVt_PVHV
			HV*restrict expected_hv = newHV();
			for (unsigned int i = 0; i < r; i++) {
				HV*restrict exp_row = newHV();
				for (unsigned int j = 0; j < c; j++) {
					NV E = (row_sum[i] * col_sum[j]) / grand_total;
					NV O = obs_matrix[i][j];
					SV**restrict col_key_sv = av_fetch(col_keys, j, 0);
					hv_store_ent(exp_row, *col_key_sv, newSVnv(E), 0);

					if (yates) {
						NV abs_diff = fabs(O - E);
						NV y_corr = (abs_diff > 0.5) ? 0.5 : abs_diff;
						NV diff = abs_diff - y_corr;
						stat += (diff * diff) / E;
					} else {
						stat += ((O - E) * (O - E)) / E;
					}
				}
				SV**restrict row_key_sv = av_fetch(row_keys, i, 0);
				hv_store_ent(expected_hv, *row_key_sv, newRV_noinc((SV*)exp_row), 0);
			}
			expected_ref = newRV_noinc((SV*)expected_hv);
		}
		safefree(row_sum); safefree(col_sum);
		df = (r - 1) * (c - 1);
	} else {
		for (unsigned int j = 0; j < c; j++) {
			grand_total += obs_array[j];
		}
		NV E = grand_total / (NV)c;

		if (input_type == SVt_PVAV) {
			AV*restrict expected_av = newAV();
			for (unsigned int j = 0; j < c; j++) {
				NV O = obs_array[j];
				av_push(expected_av, newSVnv(E));
				stat += ((O - E) * (O - E)) / E;
			}
			expected_ref = newRV_noinc((SV*)expected_av);
		} else { // SVt_PVHV
			HV*restrict expected_hv = newHV();
			for (unsigned int j = 0; j < c; j++) {
				NV O = obs_array[j];
				SV**restrict col_key_sv = av_fetch(col_keys, j, 0);
				hv_store_ent(expected_hv, *col_key_sv, newSVnv(E), 0);
				stat += ((O - E) * (O - E)) / E;
			}
			expected_ref = newRV_noinc((SV*)expected_hv);
		}
		df = c - 1;
	}

	// Memory Cleanup for Matrices/Arrays
	if (obs_matrix) {
		for (unsigned int i = 0; i < r; i++) {
			safefree(obs_matrix[i]);
		}
		safefree(obs_matrix);
	}
	if (obs_array) safefree(obs_array);
	if (row_keys) SvREFCNT_dec(row_keys);
	if (col_keys) SvREFCNT_dec(col_keys);

	NV p_val = get_p_value(stat, df);

	// 3. Build the top-level results Hash (mimicking R's htest structure)
	HV*restrict results = newHV();

	HV*restrict statistic_hv = newHV();
	hv_store(statistic_hv, "X-squared", 9, newSVnv(stat), 0);
	hv_store(results, "statistic", 9, newRV_noinc((SV*)statistic_hv), 0);

	HV*restrict parameter_hv = newHV();
	hv_store(parameter_hv, "df", 2, newSViv(df), 0);
	hv_store(results, "parameter", 9, newRV_noinc((SV*)parameter_hv), 0);

	hv_store(results, "p.value", 7, newSVnv(p_val), 0);
	hv_store(results, "expected", 8, expected_ref, 0);
	hv_store(results, "observed", 8, SvREFCNT_inc(data_ref), 0);

	if (input_type == SVt_PVAV) {
		hv_store(results, "data.name", 9, newSVpv("Perl ArrayRef", 0), 0);
	} else {
		hv_store(results, "data.name", 9, newSVpv("Perl HashRef", 0), 0);
	}

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
// Only consume a positional file argument if it is a plain string that is
// NOT one of the named option keys. Otherwise write_table(data=>..., file=>...)
// would grab the literal string "data" as the filename.
	if (arg_idx < items) {
		SV *restrict cand = ST(arg_idx);
		if (SvOK(cand) && !SvROK(cand)) {
			const char *restrict k = SvPV_nolen(cand);
			if (!(strEQ(k, "data") || strEQ(k, "file") || strEQ(k, "col.names") ||
				  strEQ(k, "row.names") || strEQ(k, "sep") || strEQ(k, "delim") ||
				  strEQ(k, "undef.val"))) {
				file_sv = cand;
				arg_idx++;
			}
		}
	}
	const char *restrict sep = ",";
	bool explicit_sep = 0; // Track if delimiter was manually specified
	// CHANGED: default undef cells to a true empty value ("") instead of NULL.
	// With print_string_row emitting zero-length fields bare (no quotes), an
	// undef cell now prints as nothing at all: a,,c -- not a,'',c or a,"",c.
	// 'undef.val' => 'NA' (etc.) still overrides this.
	const char *restrict undef_val = "";
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
		// Check for either "sep" or "delim" and mark as explicitly provided
		else if (strEQ(key, "sep") || strEQ(key, "delim")) {
			sep = SvPV_nolen(val);
			explicit_sep = 1;
		}
		// FIX: 'undef.val' => undef used to call SvPV_nolen(&PL_sv_undef)
		// (warning + empty string by accident); make it explicit.
		else if (strEQ(key, "undef.val")) undef_val = SvOK(val) ? SvPV_nolen(val) : "";
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
	// Auto-detect separator from file extension if not overridden
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
	bool is_hoh = 0, is_hoa = 0, is_aoh = 0, is_flat_hash = 0;
	AV *restrict rows_av = NULL;
// Validate Input Structures & Homogeneity
	if (SvTYPE(data_ref) == SVt_PVHV) {
		HV *restrict hv = (HV*)data_ref;
		if (hv_iterinit(hv) == 0) XSRETURN_EMPTY;
		HE *restrict entry = hv_iternext(hv);
		SV *restrict first_val = hv_iterval(hv, entry);

		if (!first_val) {
			croak("write_table: Invalid hash entry\n");
		}
// Check if top level values are scalars (Flat Hash)
		if (!SvROK(first_val)) {
			is_flat_hash = 1;
		} else {
			int first_type = SvTYPE(SvRV(first_val));
			if (first_type != SVt_PVHV && first_type != SVt_PVAV) {
				croak("write_table: Data values must be either all HASHes, all ARRAYs, or all scalars\n");
			}
			is_hoh = (first_type == SVt_PVHV);
			is_hoa = (first_type == SVt_PVAV);
		}
		hv_iterinit(hv);
		while ((entry = hv_iternext(hv))) {
			SV *restrict val = hv_iterval(hv, entry);
			if (is_flat_hash) {
				if (val && SvROK(val)) {
					croak("write_table: Mixed data types detected. Ensure all values are scalars for a flat hash.\n");
				}
			} else {
				if (!val || !SvROK(val) || SvTYPE(SvRV(val)) != (is_hoh ? SVt_PVHV : SVt_PVAV)) {
					croak("write_table: Mixed data types detected. Ensure all values are %s references.\n", is_hoh ? "HASH" : "ARRAY");
				}
			}
		}
		if (is_hoh) { // Rows are only explicitly pre-gathered for HOH
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
			if (first_ptr && *first_ptr && SvROK(*first_ptr))
				croak("write_table: For ARRAY data, every element must be a HASH reference "
					  "(Array of Hashes); element 0 is a reference of type '%s'\n",
					  sv_reftype(SvRV(*first_ptr), 0));
			else if (first_ptr && *first_ptr && SvOK(*first_ptr))
				croak("write_table: For ARRAY data, every element must be a HASH reference "
					  "(Array of Hashes); element 0 is a non-reference scalar (value: '%s')\n",
					  SvPV_nolen(*first_ptr));
			else
				croak("write_table: For ARRAY data, every element must be a HASH reference "
					  "(Array of Hashes); element 0 is undef\n");
		}
// FIX: i was size_t while av_len() returns SSize_t; keep both signed.
		for (SSize_t i = 0; i <= av_len(av); i++) {
			SV **restrict ptr = av_fetch(av, i, 0);
			if (!ptr || !*ptr || !SvROK(*ptr) || SvTYPE(SvRV(*ptr)) != SVt_PVHV) {
				croak("write_table: Mixed data types detected in Array of Hashes. All elements must be HASH references.\n");
			}
		}
		is_aoh = 1;
	}
	PerlIO *restrict fh = PerlIO_open(file, "w");
	if (!fh) {
		// FIX: rows_av was leaked here when the open failed on HoH input.
		if (rows_av) SvREFCNT_dec(rows_av);
		croak("write_table: Could not open '%s' for writing", file);
	}
	AV *restrict headers_av = newAV();
	bool inc_rownames = (row_names_sv && SvTRUE(row_names_sv)) ? 1 : 0;
	const char *restrict rownames_col = NULL;
	// ----- Hash of Hashes -----
	if (is_hoh) {
		if (col_names_sv && SvOK(col_names_sv)) {
			AV *restrict c_av = (AV*)SvRV(col_names_sv);
			// FIX: i was size_t; av_len() == -1 on an empty col.names array
			// converted to SIZE_MAX and looped (effectively) forever.
			for (SSize_t i = 0; i <= av_len(c_av); i++) {
				SV **restrict c = av_fetch(c_av, i, 0);
				if (c && SvOK(*c)) av_push(headers_av, newSVsv(*c));
			}
		} else {
			HV *restrict col_map = newHV();
			hv_iterinit((HV*)data_ref);
			HE *restrict entry;
			while ((entry = hv_iternext((HV*)data_ref))) {
				HV *restrict inner = (HV*)SvRV(hv_iterval((HV*)data_ref, entry));
				hv_iterinit(inner);
				HE *restrict inner_entry;
				while ((inner_entry = hv_iternext(inner))) {
					hv_store_ent(col_map, hv_iterkeysv(inner_entry), newSViv(1), 0);
				}
			}
			unsigned num_cols = hv_iterinit(col_map);
			// FIX (UTF-8 safety): keep the key SVs (flags intact) and sort
			// them with sv_cmp instead of round-tripping through char*.
			for (unsigned i = 0; i < num_cols; i++) {
				HE *restrict ce = hv_iternext(col_map);
				av_push(headers_av, newSVsv(hv_iterkeysv(ce)));
			}
			if (num_cols > 1)
				sortsv(AvARRAY(headers_av), num_cols, Perl_sv_cmp);
			SvREFCNT_dec(col_map);
		}
		size_t num_headers = (size_t)(av_len(headers_av) + 1);
		const char **restrict header_row = safemalloc((num_headers + 1) * sizeof(char*));
		size_t h_idx = 0;
		if (inc_rownames) header_row[h_idx++] = "";
		// FIX: loop index was 'unsigned short int' -- silently wraps (and
		// loops forever) past 65535 columns. Use size_t like everywhere else.
		for (size_t i = 0; i < num_headers; i++) {
			SV **restrict h_ptr = av_fetch(headers_av, (SSize_t)i, 0);
			header_row[h_idx++] = (h_ptr && SvOK(*h_ptr)) ? SvPV_nolen(*h_ptr) : "";
		}
		print_string_row(aTHX_ fh, header_row, h_idx, sep);
		safefree(header_row);
		size_t num_rows = (size_t)(av_len(rows_av) + 1);
		// FIX (UTF-8/NUL safety): sort the key SVs themselves and look rows
		// up by SV (hv_fetch_ent) so UTF-8-flagged or NUL-containing outer
		// keys still match. sortsv+sv_cmp is plain string order, as before.
		sortsv(AvARRAY(rows_av), num_rows, Perl_sv_cmp);
		HV *restrict data_hv = (HV*)data_ref;
		const char **restrict row_data = safemalloc((num_headers + 1) * sizeof(char*));
		for (size_t i = 0; i < num_rows; i++) {
			size_t d_idx = 0;
			SV *restrict row_key_sv = *av_fetch(rows_av, (SSize_t)i, 0);
			if (inc_rownames) row_data[d_idx++] = SvPV_nolen(row_key_sv);
			HE *restrict inner_he = hv_fetch_ent(data_hv, row_key_sv, 0, 0);
			SV *restrict inner_sv = inner_he ? HeVAL(inner_he) : NULL;
			HV *restrict inner_hv = (inner_sv && SvROK(inner_sv)) ? (HV*)SvRV(inner_sv) : NULL;
			for (size_t j = 0; j < num_headers; j++) {
				SV **restrict h_ptr = av_fetch(headers_av, (SSize_t)j, 0);
				SV *restrict h_sv = (h_ptr && SvOK(*h_ptr)) ? *h_ptr : NULL;
				// FIX (UTF-8/NUL safety): fetch by SV, not by raw bytes
				HE *restrict cell_he = (inner_hv && h_sv) ? hv_fetch_ent(inner_hv, h_sv, 0, 0) : NULL;
				SV *restrict cell_sv = cell_he ? HeVAL(cell_he) : NULL;
				if (cell_sv && SvOK(cell_sv)) {
					if (SvROK(cell_sv)) {
						PerlIO_close(fh);
						safefree(row_data);
						if (headers_av) SvREFCNT_dec(headers_av);
						if (rows_av) SvREFCNT_dec(rows_av);
						croak("write_table: Cannot write nested reference types to table\n");
					}
					row_data[d_idx++] = SvPV_nolen(cell_sv);
				} else {
					row_data[d_idx++] = undef_val;
				}
			}
			print_string_row(aTHX_ fh, row_data, d_idx, sep);
		}
		safefree(row_data);
	// ----- Flat Hash -----
	} else if (is_flat_hash) {
		HV *restrict data_hv = (HV*)data_ref;
		if (col_names_sv && SvOK(col_names_sv)) {
			AV *restrict c_av = (AV*)SvRV(col_names_sv);
			for (SSize_t i = 0; i <= av_len(c_av); i++) {
				SV **restrict c = av_fetch(c_av, i, 0);
				if (c && SvOK(*c)) av_push(headers_av, newSVsv(*c));
			}
		} else {
			// FIX (UTF-8 safety): keep the key SVs (flags intact) and sort
			// them with sv_cmp instead of round-tripping through char*.
			unsigned int num_cols = hv_iterinit(data_hv);
			for (unsigned int i = 0; i < num_cols; i++) {
				HE *restrict ce = hv_iternext(data_hv);
				av_push(headers_av, newSVsv(hv_iterkeysv(ce)));
			}
			if (num_cols > 1)
				sortsv(AvARRAY(headers_av), num_cols, Perl_sv_cmp);
		}
		size_t num_headers = (size_t)(av_len(headers_av) + 1);
		const char **restrict header_row = safemalloc((num_headers + 1) * sizeof(char*));
		size_t h_idx = 0;
		if (inc_rownames) header_row[h_idx++] = "";
		for (size_t i = 0; i < num_headers; i++) {
			SV **restrict h_ptr = av_fetch(headers_av, (SSize_t)i, 0);
			header_row[h_idx++] = (h_ptr && SvOK(*h_ptr)) ? SvPV_nolen(*h_ptr) : "";
		}
		print_string_row(aTHX_ fh, header_row, h_idx, sep);
		safefree(header_row);
		const char **restrict row_data = safemalloc((num_headers + 1) * sizeof(char*));
		size_t d_idx = 0;
		// Give the single row a default numeric identifier if row names are on
		if (inc_rownames) row_data[d_idx++] = "1";
		for (size_t j = 0; j < num_headers; j++) {
			SV **restrict h_ptr = av_fetch(headers_av, (SSize_t)j, 0);
			SV *restrict h_sv = (h_ptr && SvOK(*h_ptr)) ? *h_ptr : NULL;
			// FIX (UTF-8/NUL safety): fetch by SV, not by raw bytes
			HE *restrict val_he = h_sv ? hv_fetch_ent(data_hv, h_sv, 0, 0) : NULL;
			SV *restrict val_sv = val_he ? HeVAL(val_he) : NULL;
			// FIX: a flat-hash cell holding a reference was stringified
			// (e.g. ARRAY(0x...)) instead of croaking like every other shape.
			if (val_sv && SvOK(val_sv)) {
				if (SvROK(val_sv)) {
					PerlIO_close(fh);
					safefree(row_data);
					if (headers_av) SvREFCNT_dec(headers_av);
					croak("write_table: Cannot write nested reference types to table\n");
				}
				row_data[d_idx++] = SvPV_nolen(val_sv);
			} else {
				row_data[d_idx++] = undef_val;
			}
		}
		print_string_row(aTHX_ fh, row_data, d_idx, sep);
		safefree(row_data);
	// ----- Hash of Arrays -----
	} else if (is_hoa) {
		HV *restrict data_hv = (HV*)data_ref;
		size_t max_rows = 0;
		hv_iterinit(data_hv);
		HE *restrict entry;
		while ((entry = hv_iternext(data_hv))) {
			AV *restrict arr = (AV*)SvRV(hv_iterval(data_hv, entry));
			size_t len = (size_t)(av_len(arr) + 1);
			if (len > max_rows) max_rows = len;
		}
		if (col_names_sv && SvOK(col_names_sv)) {
			AV *restrict c_av = (AV*)SvRV(col_names_sv);
			// FIX: size_t vs av_len() == -1 (empty col.names looped forever)
			for (SSize_t i = 0; i <= av_len(c_av); i++) {
				SV **restrict c = av_fetch(c_av, i, 0);
				if (c && SvOK(*c)) av_push(headers_av, newSVsv(*c));
			}
		} else {
			// FIX (UTF-8 safety): keep the key SVs (flags intact) and sort
			// them with sv_cmp instead of round-tripping through char*.
			unsigned int num_cols = hv_iterinit(data_hv);
			for (unsigned int i = 0; i < num_cols; i++) {
				HE *restrict ce = hv_iternext(data_hv);
				av_push(headers_av, newSVsv(hv_iterkeysv(ce)));
			}
			if (num_cols > 1)
				sortsv(AvARRAY(headers_av), num_cols, Perl_sv_cmp);
		}
		if (av_len(headers_av) < 0) {
			// FIX: this croak leaked the open filehandle and headers_av.
			PerlIO_close(fh);
			SvREFCNT_dec(headers_av);
			croak("Could not get headers in write_table");
		}
		if (inc_rownames && contains_nondigit(aTHX_ row_names_sv)) {
			rownames_col = SvPV_nolen(row_names_sv);
			AV *restrict filtered_headers = newAV();
			// FIX: size_t vs av_len() (same wrap as above if headers empty)
			for (SSize_t i = 0; i <= av_len(headers_av); i++) {
				SV **restrict h_ptr = av_fetch(headers_av, i, 0);
				if (!h_ptr || !*h_ptr) continue;
				SV *restrict h_sv = *h_ptr;
				// FIX (UTF-8 safety): sv_eq, not strcmp on raw bytes
				if (!sv_eq(h_sv, row_names_sv)) {
					av_push(filtered_headers, newSVsv(h_sv));
				}
			}
			SvREFCNT_dec(headers_av);
			headers_av = filtered_headers;
		}
		size_t num_headers = (size_t)(av_len(headers_av) + 1);
		const char **restrict header_row = safemalloc((num_headers + 1) * sizeof(char*));
		size_t h_idx = 0;
		if (inc_rownames) header_row[h_idx++] = "";
		for (size_t i = 0; i < num_headers; i++) {
			SV **restrict h_ptr = av_fetch(headers_av, (SSize_t)i, 0);
			header_row[h_idx++] = (h_ptr && SvOK(*h_ptr)) ? SvPV_nolen(*h_ptr) : "";
		}
		print_string_row(aTHX_ fh, header_row, h_idx, sep);
		safefree(header_row);
		const char **restrict row_data = safemalloc((num_headers + 1) * sizeof(char*));
		// FIX: numeric row labels used savepv() + safefree() every row; a
		// stack buffer reused per row does the same job with no allocation
		// (and removes the const-away cast in the old safefree call).
		char rn_buf[32];
		for (size_t i = 0; i < max_rows; i++) {
			size_t d_idx = 0;
			if (inc_rownames) {
				if (rownames_col) {
					// FIX (UTF-8 safety): fetch the row-name column by SV
					HE *restrict rn_arr_he = hv_fetch_ent(data_hv, row_names_sv, 0, 0);
					SV *restrict rn_arr_sv = rn_arr_he ? HeVAL(rn_arr_he) : NULL;
					if (rn_arr_sv && SvROK(rn_arr_sv)) {
						AV *restrict rn_arr = (AV*)SvRV(rn_arr_sv);
						SV **restrict rn_val_ptr = av_fetch(rn_arr, (SSize_t)i, 0);
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
					snprintf(rn_buf, sizeof(rn_buf), "%lu", (unsigned long)(i + 1));
					row_data[d_idx++] = rn_buf;
				}
			}
			for (size_t j = 0; j < num_headers; j++) {
				SV **restrict h_ptr = av_fetch(headers_av, (SSize_t)j, 0);
				SV *restrict h_sv = (h_ptr && SvOK(*h_ptr)) ? *h_ptr : NULL;
				// FIX (UTF-8/NUL safety): fetch by SV, not by raw bytes
				HE *restrict arr_he = h_sv ? hv_fetch_ent(data_hv, h_sv, 0, 0) : NULL;
				SV *restrict arr_sv = arr_he ? HeVAL(arr_he) : NULL;
				if (arr_sv && SvROK(arr_sv)) {
					AV *restrict arr = (AV*)SvRV(arr_sv);
					SV **restrict cell_ptr = av_fetch(arr, (SSize_t)i, 0);
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
		}
		safefree(row_data);
	} else if (is_aoh) { // ----- Array of Hashes
		AV *restrict data_av = (AV*)data_ref;
		size_t num_rows = (size_t)(av_len(data_av) + 1);
		if (col_names_sv && SvOK(col_names_sv)) {
			AV *restrict c_av = (AV*)SvRV(col_names_sv);
			// FIX: size_t vs av_len() == -1 (empty col.names looped forever)
			for (SSize_t i = 0; i <= av_len(c_av); i++) {
				SV **restrict c = av_fetch(c_av, i, 0);
				if (c && SvOK(*c)) av_push(headers_av, newSVsv(*c));
			}
		} else {
			HV *restrict col_map = newHV();
			for (size_t i = 0; i < num_rows; i++) {
				SV **restrict row_ptr = av_fetch(data_av, (SSize_t)i, 0);
				if (row_ptr && SvROK(*row_ptr)) {
					HV *restrict row_hv = (HV*)SvRV(*row_ptr);
					hv_iterinit(row_hv);
					HE *restrict entry;
					while ((entry = hv_iternext(row_hv))) {
						hv_store_ent(col_map, hv_iterkeysv(entry), newSViv(1), 0);
					}
				}
			}
			unsigned num_cols = hv_iterinit(col_map);
			// FIX (UTF-8 safety): keep the key SVs (flags intact) and sort
			// them with sv_cmp instead of round-tripping through char*.
			for (unsigned int i = 0; i < num_cols; i++) {
				HE *restrict ce = hv_iternext(col_map);
				av_push(headers_av, newSVsv(hv_iterkeysv(ce)));
			}
			if (num_cols > 1)
				sortsv(AvARRAY(headers_av), num_cols, Perl_sv_cmp);
			SvREFCNT_dec(col_map);
		}
		if (inc_rownames && contains_nondigit(aTHX_ row_names_sv)) {
			rownames_col = SvPV_nolen(row_names_sv);
			AV *restrict filtered_headers = newAV();
			// FIX: size_t vs av_len() (same wrap as above if headers empty)
			for (SSize_t i = 0; i <= av_len(headers_av); i++) {
				SV **restrict h_ptr = av_fetch(headers_av, i, 0);
				if (!h_ptr || !*h_ptr) continue;
				SV *restrict h_sv = *h_ptr;
				// FIX (UTF-8 safety): sv_eq, not strcmp on raw bytes
				if (!sv_eq(h_sv, row_names_sv)) {
					av_push(filtered_headers, newSVsv(h_sv));
				}
			}
			SvREFCNT_dec(headers_av);
			headers_av = filtered_headers;
		}
		size_t num_headers = (size_t)(av_len(headers_av) + 1);
		const char **restrict header_row = safemalloc((num_headers + 1) * sizeof(char*));
		size_t h_idx = 0;
		if (inc_rownames) header_row[h_idx++] = "";
		for (size_t i = 0; i < num_headers; i++) {
			SV **restrict h_ptr = av_fetch(headers_av, (SSize_t)i, 0);
			header_row[h_idx++] = (h_ptr && SvOK(*h_ptr)) ? SvPV_nolen(*h_ptr) : "";
		}
		print_string_row(aTHX_ fh, header_row, h_idx, sep);
		safefree(header_row);
		const char **restrict row_data = safemalloc((num_headers + 1) * sizeof(char*));
		char rn_buf[32]; // FIX: replaces per-row savepv/safefree (see HoA)
		for (size_t i = 0; i < num_rows; i++) {
			size_t d_idx = 0;
			SV **restrict row_ptr = av_fetch(data_av, (SSize_t)i, 0);
			HV *restrict row_hv = (row_ptr && SvROK(*row_ptr)) ? (HV*)SvRV(*row_ptr) : NULL;
			if (inc_rownames) {
				if (rownames_col) {
					// FIX (UTF-8 safety): fetch the row-name cell by SV
					HE *restrict rn_he = row_hv ? hv_fetch_ent(row_hv, row_names_sv, 0, 0) : NULL;
					SV *restrict rn_sv = rn_he ? HeVAL(rn_he) : NULL;
					if (rn_sv && SvOK(rn_sv)) {
						if (SvROK(rn_sv)) {
							PerlIO_close(fh);
							safefree(row_data);
							if (headers_av) SvREFCNT_dec(headers_av);
							croak("write_table: Cannot write nested reference types to table\n");
						}
						row_data[d_idx++] = SvPV_nolen(rn_sv);
					} else {
						row_data[d_idx++] = undef_val;
					}
				} else {
					snprintf(rn_buf, sizeof(rn_buf), "%lu", (unsigned long)(i + 1));
					row_data[d_idx++] = rn_buf;
				}
			}
			for (size_t j = 0; j < num_headers; j++) {
				SV **restrict h_ptr = av_fetch(headers_av, (SSize_t)j, 0);
				SV *restrict h_sv = (h_ptr && SvOK(*h_ptr)) ? *h_ptr : NULL;
				// FIX (UTF-8/NUL safety): fetch by SV, not by raw bytes
				HE *restrict cell_he = (row_hv && h_sv) ? hv_fetch_ent(row_hv, h_sv, 0, 0) : NULL;
				SV *restrict cell_sv = cell_he ? HeVAL(cell_he) : NULL;
				if (cell_sv && SvOK(cell_sv)) {
					if (SvROK(cell_sv)) {
						PerlIO_close(fh);
						safefree(row_data);
						if (headers_av) SvREFCNT_dec(headers_av);
						croak("write_table: Cannot write nested reference types to table\n");
					}
					row_data[d_idx++] = SvPV_nolen(cell_sv);
				} else {
					row_data[d_idx++] = undef_val;
				}
			}
			print_string_row(aTHX_ fh, row_data, d_idx, sep);
		}
		safefree(row_data);
	}
	if (headers_av) SvREFCNT_dec(headers_av);
	if (rows_av) SvREFCNT_dec(rows_av);
	PerlIO_close(fh);
	XSRETURN_EMPTY;
}

SV* _parse_csv_file(char* file, const char* sep_str, const char* comment_str, SV* callback = &PL_sv_undef)
PREINIT:
	/* Declarations only -- C declarations cost nothing. ALLOCATIONS are
	 * deferred into CODE, after every croak-able validation, so that no
	 * error path can leak. (The old version allocated current_row, field,
	 * and data in INIT: the open-failure croak leaked all three, and a die
	 * inside the callback leaked those plus line_sv plus the open handle.) */
	PerlIO *restrict fp;
	AV *restrict data = NULL;
	AV *current_row = NULL;
	SV *restrict field = NULL;
	SV *restrict line_sv = NULL;
	bool in_quotes = 0, post_quote = 0, use_cb = 0;
	size_t sep_len, comment_len;
	char sep0 = 0;
CODE:
	/* ---- validation: nothing is allocated yet, so croaks are leak-free */
	if (SvOK(callback)) {
		if (SvROK(callback) && SvTYPE(SvRV(callback)) == SVt_PVCV)
			use_cb = 1;
		else
			/* FIX: a defined non-CODE callback used to be silently ignored
			 * (falling back to slurp mode); now it is an error. */
			croak("_parse_csv_file: callback must be a CODE reference");
	}
	sep_len = sep_str ? strlen(sep_str) : 0;
	comment_len = comment_str ? strlen(comment_str) : 0;
	sep0 = sep_len ? sep_str[0] : 0;
	fp = PerlIO_open(file, "r");
	if (!fp)
		croak("Could not open file '%s'", file);
	/* ---- from here on, a die inside the callback must not leak anything:
	 * tie every long-lived resource to the save stack, which croak unwinds */
	ENTER;
	SAVEDESTRUCTOR_X(S_pclose, fp);		/* fp closes on normal LEAVE or die */
	line_sv = newSV(128);
	SAVEFREESV(line_sv);
	field = newSVpvs("");
	SAVEFREESV(field);
	if (!use_cb)
		data = newAV();	/* slurp mode runs no perl code: no die can reach it */
	current_row = newAV();	/* covered by the ownership dance in S_emit_row */
	/* The wrapper strips a leading comment marker from the HEADER itself, so
	 * the first content line must reach the callback even when it begins with
	 * the comment string. Comment-skipping therefore starts only after the
	 * first row has been emitted. (In the old code the header-strip logic in
	 * read_table was dead: the parser ate any '#'-prefixed header first.) */
	bool seen_first = 0;
	while (sv_gets(line_sv, fp, 0) != NULL) {
		char *restrict line = SvPVX(line_sv);
		size_t len = SvCUR(line_sv);
		// chomp \n and a preceding \r (CRLF)
		if (len && line[len-1] == '\n') {
			len--;
			if (len && line[len-1] == '\r')
				len--;
		}
		if (!in_quotes) {
			// skip blank / whitespace-only lines
			size_t k = 0;
			while (k < len && (line[k] == ' ' || line[k] == '\t'))
				k++;
			if (k == len)
				continue;
			// skip comment lines -- but never the first content line
			if (seen_first && comment_len && len >= comment_len
					&& memcmp(line, comment_str, comment_len) == 0)
				continue;
		}
		// ---- core parser: chunked copies instead of per-char appends
		{
		size_t i = 0;
		while (i < len) {
			if (in_quotes) {
				/* Everything up to the next quote is literal -- including
				 * \r, which the old parser wrongly stripped inside quotes
				 * (breaking round-trips of values like "x\ry"). */
				const char *restrict q = (const char *)memchr(line + i, '"', len - i);
				if (!q) {
					sv_catpvn(field, line + i, len - i);
					i = len;
					break;
				}
				{
					size_t run = (size_t)(q - (line + i));
					if (run)
						sv_catpvn(field, line + i, run);
					i += run;	/* i is now at the quote */
				}
				if (i + 1 < len && line[i+1] == '"') {
					sv_catpvn(field, "\"", 1);	/* "" -> literal " */
					i += 2;
				} else {
					in_quotes = 0;
					post_quote = 1;
					i += 1;
				}
			} else {
				/* copy a run of ordinary bytes in one shot */
				size_t start = i;
				while (i < len) {
					const char c = line[i];
					if (c == '"' || c == '\r')
						break;
					if (c == sep0 && sep_len && (len - i) >= sep_len
							&& (sep_len == 1
								|| memcmp(line + i, sep_str, sep_len) == 0))
						break;
					i++;
				}
				if (i > start)
					sv_catpvn(field, line + start, i - start);
				if (i >= len)
					break;
				{
					const char c = line[i];
					if (c == '"') {
						/* lenient: a quote after a closed quote is dropped,
						 * matching the old parser */
						if (!post_quote)
							in_quotes = 1;
						i++;
					} else if (c == '\r') {
						i++;	/* stray CR outside quotes: ignored, as before */
					} else {
						/* separator */
						av_push(current_row, newSVsv(field));
						sv_setpvs(field, "");
						post_quote = 0;
						i += sep_len;
					}
				}
			}
		}
		}
		if (in_quotes) {
			/* open quote at EOL: logical record continues on the next line */
			sv_catpvn(field, "\n", 1);
		} else {
			post_quote = 0;
			S_emit_row(aTHX_ &current_row, field, use_cb, callback, data);
			seen_first = 1;
		}
	}
	if (in_quotes) {/* EOF with an unterminated quote: flush the trailing record */
		S_emit_row(aTHX_ &current_row, field, use_cb, callback, data);
	}
	SvREFCNT_dec((SV*)current_row);// the spare row S_emit_row left behind
	LEAVE;// closes fp, frees line_sv and field
	if (use_cb) {
		RETVAL = newSV(0); // fresh undef; mortalizing immortal &PL_sv_undef underflows it on perl<5.18
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
		NV *restrict x_val = (NV*)safemalloc(nx * sizeof(NV));
		NV *restrict y_val = (NV*)safemalloc(nx * sizeof(NV));
		size_t n = 0;

		for (size_t i = 0; i < nx; i++) {
			SV **restrict x_tv = av_fetch(x_av, i, 0);
			SV **restrict y_tv = av_fetch(y_av, i, 0);

			// Extract numeric values, defaulting to NAN for missing/invalid data
			NV xv = (x_tv && SvOK(*x_tv) && looks_like_number(*x_tv)) ? SvNV(*x_tv) : NAN;
			NV yv = (y_tv && SvOK(*y_tv) && looks_like_number(*y_tv)) ? SvNV(*y_tv) : NAN;

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
			NV ans = 0.0;			
			// 5. Algorithm routing
			if (strcmp(method, "kendall") == 0) {
				// R's default cov(..., method="kendall") iterates the full n x n space
				for (size_t i = 0; i < n; i++) {
				  for (size_t j = 0; j < n; j++) {
						int sx = (x_val[i] > x_val[j]) - (x_val[i] < x_val[j]);
						int sy = (y_val[i] > y_val[j]) - (y_val[i] < y_val[j]);
						ans += (NV)(sx * sy);
				  }
				}
			} else {
				NV mean_x = 0.0, mean_y = 0.0, cov_sum = 0.0;
				if (strcmp(method, "spearman") == 0) {
				  // Spearman: Rank the data first, then run standard covariance
				  NV *restrict rx = (NV*)safemalloc(n * sizeof(NV));
				  NV *restrict ry = (NV*)safemalloc(n * sizeof(NV));
				  // Uses your existing rank_data() helper from LikeR.xs
				  rank_data(x_val, rx, n);
				  rank_data(y_val, ry, n);
				  for (size_t i = 0; i < n; i++) {
						NV dx = rx[i] - mean_x;
						mean_x += dx / (i + 1);
						NV dy = ry[i] - mean_y;
						mean_y += dy / (i + 1);
						cov_sum += dx * (ry[i] - mean_y);
				  }
				  Safefree(rx); Safefree(ry);
				} else { 
				  // Pearson: Welford's Single-Pass Covariance Algorithm
				  for (size_t i = 0; i < n; i++) {
						NV dx = x_val[i] - mean_x;
						mean_x += dx / (i + 1);
						NV dy = y_val[i] - mean_y;
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

SV *glm(...)
	CODE:
	{
	const char *restrict formula  = NULL;
	SV *restrict data_sv = NULL;
	const char *restrict family_str = "gaussian";
	char f_cpy[512];
	char *restrict src, *restrict dst, *restrict tilde, *restrict lhs, *restrict rhs, *restrict chunk;

	char **restrict terms = NULL, **restrict uniq_terms = NULL, **restrict exp_terms = NULL;
	bool *restrict is_dummy = NULL;
	char **restrict dummy_base = NULL, **restrict dummy_level = NULL;
	unsigned int term_cap = 64, exp_cap = 64, num_terms = 0, num_uniq = 0, p = 0, p_exp = 0;
	size_t n = 0, valid_n = 0, i;
	bool has_intercept = TRUE, converged = FALSE, boundary = FALSE;
	unsigned int iter = 0, max_iter = 25, final_rank = 0, df_res = 0;
	NV deviance_old = 0.0, deviance_new = 0.0, null_dev = 0.0, aic = 0.0;
	NV dispersion = 0.0, epsilon = 1e-8;

	char **restrict row_names = NULL;
	char **restrict valid_row_names = NULL;
	HV **restrict row_hashes = NULL;
	HV *restrict data_hoa = NULL;
	SV *restrict ref = NULL;

	NV *restrict X = NULL, *restrict Y = NULL, *restrict mu = NULL, *restrict eta = NULL;
	NV *restrict W = NULL, *restrict Z = NULL, *restrict beta = NULL, *restrict beta_old = NULL;
	bool *restrict aliased = NULL;
	NV *restrict XtWX = NULL, *restrict XtWZ = NULL;

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

	Newx(terms, term_cap, char*); Newx(uniq_terms, term_cap, char*);
	Newx(exp_terms, exp_cap, char*); Newx(is_dummy, exp_cap, bool);
	Newx(dummy_base, exp_cap, char*); Newx(dummy_level, exp_cap, char*);

	src = (char*restrict)formula; dst = f_cpy;
	while (*src && (dst - f_cpy < 511)) { if (!isspace(*src)) { *dst++ = *src; } src++; }
	*dst = '\0';

	tilde = strchr(f_cpy, '~');
	if (!tilde) croak("glm: invalid formula, missing '~'");
	*tilde = '\0';
	lhs = f_cpy;
	rhs = tilde + 1;
	char *restrict minus_one;
	if ((minus_one = strstr(rhs, "-1")) != NULL) {
		has_intercept = FALSE;
		memmove(
		  minus_one,  minus_one + 2,  strlen(minus_one + 2) + 1
		);
	}
	char *restrict minus1 = strstr(rhs, "-1");
	if (minus1) {
		has_intercept = FALSE;
		memmove(
		  minus1,  minus1 + 2,  strlen(minus1 + 2) + 1
		);
	}
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
				 {
					 /* Row labels: use an explicit row-names column if the
					  * caller supplied one (R carries these as "row.names");
					  * otherwise fall back to 1-based integer labels. */
					 static const char *const rn_keys[] =
						 { "row.names", "_row", "rownames", ".rownames" };
					 AV *restrict rn_av = NULL;
					 for (size_t k = 0; k < sizeof rn_keys / sizeof rn_keys[0]; k++) {
						 SV **restrict rn = hv_fetch(hv, rn_keys[k],
							 (I32)strlen(rn_keys[k]), 0);
						 if (rn && *rn && SvROK(*rn)
							 && SvTYPE(SvRV(*rn)) == SVt_PVAV) {
							 rn_av = (AV*)SvRV(*rn);
							 break;
						 }
					 }
					 for (i = 0; i < n; i++) {
						 SV **restrict nm = rn_av
							 ? av_fetch(rn_av, (SSize_t)i, 0) : NULL;
						 if (nm && *nm && SvOK(*nm)) {
							 STRLEN l; const char *restrict s = SvPV(*nm, l);
							 row_names[i] = savepvn(s, l);
						 } else {
							 char buf[32];
							 snprintf(buf, sizeof(buf), "%lu", (unsigned long)(i + 1));
							 row_names[i] = savepv(buf);
						 }
					 }
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
				HV *restrict rh = (HV*)SvRV(*val);
				row_hashes[i] = rh;
				/* Row label: a "row.names" (etc.) field on the row, else int. */
				{
					static const char *const rn_keys[] =
						{ "row.names", "_row", "rownames", ".rownames" };
					SV **restrict nm = NULL;
					for (size_t k = 0; k < sizeof rn_keys / sizeof rn_keys[0]; k++) {
						nm = hv_fetch(rh, rn_keys[k], (I32)strlen(rn_keys[k]), 0);
						if (nm && *nm && SvOK(*nm)) break;
						nm = NULL;
					}
					if (nm && *nm && SvOK(*nm)) {
						STRLEN l; const char *restrict s = SvPV(*nm, l);
						row_names[i] = savepvn(s, l);
					} else {
						char buf[32];
						snprintf(buf, sizeof(buf), "%lu", (unsigned long)(i + 1));
						row_names[i] = savepv(buf);
					}
				}
			} else {
				for (size_t k = 0; k < i; k++) Safefree(row_names[k]);
				Safefree(row_names); Safefree(row_hashes);
				croak("glm: Array values must be HashRefs (AoH)");
			}
		}
	} else croak("glm: Data must be an Array or Hash reference");
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
							char *restrict tmp = levels[l1]; levels[l1] = levels[l2]; levels[l2] = tmp;
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

	Newx(X, n * p, NV); Newx(Y, n, NV);
	Newx(valid_row_names, n, char*);

	for (size_t i = 0; i < n; i++) {
		NV y_val = evaluate_term(aTHX_ data_hoa, row_hashes, i, lhs);
		if (isnan(y_val)) { Safefree(row_names[i]); continue; }

		bool row_ok = TRUE;
		NV *restrict row_x = (NV*)safemalloc(p * sizeof(NV));
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
	if (valid_n < p) {
	  Safefree(X); Safefree(Y); Safefree(valid_row_names); if (row_hashes) Safefree(row_hashes);
	  croak("glm: 0 degrees of freedom (too many NAs or parameters > observations)");
	}
	mu = (NV*)safemalloc(valid_n * sizeof(NV)); eta = (NV*)safemalloc(valid_n * sizeof(NV));
	W = (NV*)safemalloc(valid_n * sizeof(NV)); Z = (NV*)safemalloc(valid_n * sizeof(NV));
	beta = (NV*)safemalloc(p * sizeof(NV)); beta_old = (NV*)safemalloc(p * sizeof(NV));
	aliased = (bool*)safemalloc(p * sizeof(bool));
	XtWX = (NV*)safemalloc(p * p * sizeof(NV)); XtWZ = (NV*)safemalloc(p * sizeof(NV));
	for (i = 0; i < p; i++) { beta[i] = 0.0; beta_old[i] = 0.0; }
	NV sum_y = 0.0;
	for (i = 0; i < valid_n; i++) sum_y += Y[i];
	NV mean_y = sum_y / valid_n;
	for (i = 0; i < valid_n; i++) {
		if (is_binomial) {
			if (Y[i] < 0.0 || Y[i] > 1.0) croak("glm: binomial family requires response between 0 and 1");
			mu[i] = (Y[i] + 0.5) / 2.0; 
			eta[i] = log(mu[i] / (1.0 - mu[i]));
			NV dev = 0.0;
			if (Y[i] == 0.0)      dev = -2.0 * log(1.0 - mu[i]);
			else if (Y[i] == 1.0) dev = -2.0 * log(mu[i]);
			else dev = 2.0 * (Y[i] * log(Y[i] / mu[i]) + (1.0 - Y[i]) * log((1.0 - Y[i]) / (1.0 - mu[i])));
			deviance_old += dev;
		} else { 
			mu[i] = mean_y;
			eta[i] = mu[i]; 
		}
	}
	for (iter = 1; iter <= max_iter; iter++) {
		for (i = 0; i < valid_n; i++) {
			if (is_binomial) {
				 NV varmu = mu[i] * (1.0 - mu[i]);
				 NV mu_eta = varmu;
				 if (varmu < 1e-10) varmu = 1e-10;
				 Z[i] = eta[i] + (Y[i] - mu[i]) / mu_eta;
				 W[i] = (mu_eta * mu_eta) / varmu; 
			} else { 
				 W[i] = 1.0; 
				 Z[i] = Y[i]; 
			}
		}
		for (i = 0; i < p; i++) { XtWZ[i] = 0.0; for (size_t j = 0; j < p; j++) XtWX[i * p + j] = 0.0; }
		for (size_t k = 0; k < valid_n; k++) {
			NV w = W[k], z = Z[k];
			for (i = 0; i < p; i++) {
				 XtWZ[i] += X[k * p + i] * w * z;
				 NV xw = X[k * p + i] * w;
				 for (size_t j = 0; j < p; j++) XtWX[i * p + j] += xw * X[k * p + j];
			}
		}
		final_rank = sweep_matrix_ols(XtWX, p, aliased);
		for (i = 0; i < p; i++) {
			if (aliased[i]) { beta[i] = NAN; } else {
				 NV sum = 0.0;
				 for (size_t j = 0; j < p; j++) if (!aliased[j]) sum += XtWX[i * p + j] * XtWZ[j];
				 beta[i] = sum;
			}
		}
		boundary = FALSE;
		for (unsigned short int half = 0; half < 10; half++) {
			deviance_new = 0.0;
			for (i = 0; i < valid_n; i++) {
				 NV linear_pred = 0.0;
				 for (size_t j = 0; j < p; j++) if (!aliased[j]) linear_pred += X[i * p + j] * beta[j];
				 eta[i] = linear_pred;
				 if (is_binomial) {
					 mu[i] = 1.0 / (1.0 + exp(-eta[i]));
					 if (mu[i] < 10 * DBL_EPSILON) mu[i] = 10 * DBL_EPSILON;
					 if (mu[i] > 1.0 - 10 * DBL_EPSILON) mu[i] = 1.0 - 10 * DBL_EPSILON;
					 NV dev = 0.0;
					 if (Y[i] == 0.0)      dev = -2.0 * log(1.0 - mu[i]);
					 else if (Y[i] == 1.0) dev = -2.0 * log(mu[i]);
					 else dev = 2.0 * (Y[i] * log(Y[i] / mu[i]) + (1.0 - Y[i]) * log((1.0 - Y[i]) / (1.0 - mu[i])));
					 deviance_new += dev;
				 } else {
					 mu[i] = eta[i];
					 NV res = Y[i] - mu[i];
					 deviance_new += res * res;
				 }
			}
			if (!is_binomial || deviance_new <= deviance_old + 1e-7 || !isfinite(deviance_new)) {
				 continue; 
			}
			boundary = TRUE;
			for (size_t j = 0; j < p; j++) beta[j] = (beta[j] + beta_old[j]) / 2.0;
		}
		if (fabs(deviance_new - deviance_old) / (0.1 + fabs(deviance_new)) < epsilon) { 
			converged = TRUE; break; 
		}
		deviance_old = deviance_new;
		for (size_t j = 0; j < p; j++) beta_old[j] = beta[j];
	}
	for (i = 0; i < p; i++) { for (size_t j = 0; j < p; j++) XtWX[i * p + j] = 0.0; }
	for (size_t k = 0; k < valid_n; k++) {
	  NV w = is_binomial ? (mu[k] * (1.0 - mu[k])) : 1.0;
	  if (w < 1e-10) w = 1e-10;
	  for (i = 0; i < p; i++) {
		   NV xw = X[k * p + i] * w;
		   for (size_t j = 0; j < p; j++) XtWX[i * p + j] += xw * X[k * p + j];
	  }
	}
	final_rank = sweep_matrix_ols(XtWX, p, aliased);
	NV wtdmu = has_intercept ? mean_y : (is_binomial ? 0.5 : 0.0);

	for (i = 0; i < valid_n; i++) {
		if (is_binomial) {
			if (Y[i] == 0.0)      null_dev += -2.0 * log(1.0 - wtdmu);
			else if (Y[i] == 1.0) null_dev += -2.0 * log(wtdmu);
			else null_dev += 2.0 * (Y[i] * log(Y[i] / wtdmu) + (1.0 - Y[i]) * log((1.0 - Y[i]) / (1.0 - wtdmu)));
		} else {
			NV diff = Y[i] - wtdmu;
			null_dev += diff * diff;
		}
	}
	if (is_gaussian) {
		NV n_f = (NV)valid_n;
		NV dev_for_aic = deviance_new;
		if (dev_for_aic < 1.0355727742801604e-30) {
			dev_for_aic = 1.0355727742801604e-30;
		}
		aic = n_f * (log(2.0 * M_PI) + 1.0 + log(dev_for_aic / n_f)) + 2.0 * (final_rank + 1.0);
	} else if (is_binomial) { 
		aic = deviance_new + 2.0 * final_rank; 
	}
	res_hv = newHV(); coef_hv = newHV(); fitted_hv = newHV(); resid_hv = newHV();
	df_res = valid_n - final_rank;
	dispersion = is_binomial ? 1.0 : ((df_res > 0) ? (deviance_new / df_res) : NAN);
	for (size_t i = 0; i < valid_n; i++) {
		NV res = Y[i] - mu[i];
		if (is_binomial) {
			NV d_res = 0.0;
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
			NV se = sqrt(dispersion * XtWX[j * p + j]);
			NV val_stat = beta[j] / se;
			NV p_val = is_binomial ? 2.0 * (1.0 - approx_pnorm(fabs(val_stat))) : get_t_pvalue(val_stat, df_res, "two.sided");
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
	NV conf_level = 0.95;
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
	NV *restrict x, *restrict y;
	NV estimate = 0, p_value = 0, statistic = 0, df = 0, ci_lower = 0, ci_upper = 0;
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
	x = safemalloc(n_raw * sizeof(NV));
	y = safemalloc(n_raw * sizeof(NV));
	size_t n = 0; /* Final count of pairwise complete observations */
	for (size_t i = 0; i < n_raw; i++) {
	  SV **restrict x_val = av_fetch(x_av, i, 0);
	  SV **restrict y_val = av_fetch(y_av, i, 0);
	  NV xv = (x_val && SvOK(*x_val) && looks_like_number(*x_val)) ? SvNV(*x_val) : NAN;
	  NV yv = (y_val && SvOK(*y_val) && looks_like_number(*y_val)) ? SvNV(*y_val) : NAN;
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
		NV mean_x = 0.0, mean_y = 0.0, M2_x = 0.0, M2_y = 0.0, cov = 0.0;
		for (size_t i = 0; i < n; i++) {
			NV dx = x[i] - mean_x;
			mean_x += dx / (i + 1);
			NV dy = y[i] - mean_y;
			mean_y += dy / (i + 1);
			M2_x += dx * (x[i] - mean_x);
			M2_y += dy * (y[i] - mean_y);
			cov  += dx * (y[i] - mean_y);
	  }
	  estimate = (M2_x > 0.0 && M2_y > 0.0) ? cov / sqrt(M2_x * M2_y) : 0.0;
	  /* Clamp to [-1, 1] to guard against floating-point overshoot */
	  if      (estimate >  1.0) estimate =  1.0;
	  else if (estimate < -1.0) estimate = -1.0;
	  df = (NV)(n - 2);
	  /* BUG FIX: guard divide-by-zero when |estimate| == 1 exactly.
	   * A perfect correlation gives t = ±Inf, matching R's behaviour. */
	  NV denom_t = 1.0 - estimate * estimate;
	  if (denom_t <= 0.0)
		  statistic = (estimate > 0.0) ? INFINITY : -INFINITY;
	  else
		  statistic = estimate * sqrt(df / denom_t);
	  /* Confidence interval via Fisher's Z transform.
	   * BUG FIX: when |estimate| == 1 the log blows up; clamp first.
	   * We use a half-ULP margin so tanh can recover ±1 cleanly. */
	  NV est_clamped = estimate;
	  if      (est_clamped >=  1.0) est_clamped =  1.0 - DBL_EPSILON;
	  else if (est_clamped <= -1.0) est_clamped = -1.0 + DBL_EPSILON;
	  NV z     = 0.5 * log((1.0 + est_clamped) / (1.0 - est_clamped));
	  NV se    = 1.0 / sqrt((NV)(n - 3));
	  NV alpha = 1.0 - conf_level;
	  NV q     = inverse_normal_cdf(1.0 - alpha / 2.0);
	  ci_lower = tanh(z - q * se);
	  ci_upper = tanh(z + q * se);
	  // High-precision p-value using incomplete beta
	  p_value = get_t_pvalue(statistic, df, alternative);
	} else if (is_kendall) {
	  // BUG FIX: use long to avoid int overflow for large n
	  long c = 0, d = 0, tie_x = 0, tie_y = 0;
	  for (size_t i = 0; i < n - 1; i++) {
		  for (size_t j = i + 1; j < n; j++) {
			  NV sign_x = (x[i] > x[j]) - (x[i] < x[j]);
			  NV sign_y = (y[i] > y[j]) - (y[i] < y[j]);
			  if      (sign_x == 0 && sign_y == 0) { /* joint tie — ignore */ }
			  else if (sign_x == 0) tie_x++;
			  else if (sign_y == 0) tie_y++;
			  else if (sign_x * sign_y > 0) c++;
			  else d++;
		  }
	  }
	  NV denom = sqrt((NV)(c + d + tie_x) * (NV)(c + d + tie_y));
	  // BUG FIX: use NAN (from <math.h>) instead of 0.0/0.0 (UB in C)
	  estimate = (denom == 0.0) ? NAN : (NV)(c - d) / denom;
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
		  NV S_stat = (NV)(c - d);
		  statistic = (NV)c;
		  p_value = kendall_exact_pvalue(n, S_stat, alternative);
	  } else {
		  /* Normal approximation for large n or when ties are present */
		  NV var_S = (NV)n * (NV)(n - 1) * (2.0 * (NV)n + 5.0) / 18.0;
		  NV S = (NV)(c - d);
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
	  NV *restrict rank_x = safemalloc(n * sizeof(NV));
	  NV *restrict rank_y = safemalloc(n * sizeof(NV));
	  compute_ranks(x, rank_x, n);
	  compute_ranks(y, rank_y, n);

	  /* Spearman rho = Pearson r of the ranks (Welford's algorithm) */
	  NV mean_x = 0.0, mean_y = 0.0, M2_x = 0.0, M2_y = 0.0, cov = 0.0;
	  for (size_t i = 0; i < n; i++) {
		  NV dx = rank_x[i] - mean_x;
		  mean_x += dx / (i + 1);
		  NV dy = rank_y[i] - mean_y;
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
	  NV S_stat = 0.0;
	  for (size_t i = 0; i < n; i++) {
		  NV diff = rank_x[i] - rank_y[i];
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
		  NV r = estimate;
		  /* NOTE: R silently ignores continuity correction for Spearman.
		   * The adjustment below is non-standard; a warning is emitted
		   * so callers are not silently misled. */
		  if (continuity) {
			  warn("cor_test: continuity correction is not defined for Spearman in R and is ignored here");
		  }
		  /* BUG FIX: guard divide-by-zero when |r| == 1 exactly */
		  NV denom_t = 1.0 - r * r;
		  if (denom_t <= 0.0)
			  statistic = (r > 0.0) ? INFINITY : -INFINITY;
		  else
			  statistic = r * sqrt((NV)(n - 2) / denom_t);
		  p_value = get_t_pvalue(statistic, (NV)(n - 2), alternative);
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
	NV *restrict x, w = 0.0, p_val = 0.0, mean = 0.0, ssq = 0.0;
PPCODE:
	if (!SvROK(data) || SvTYPE(SvRV(data)) != SVt_PVAV) {
	  croak("Expected an array reference");
	}

	av = (AV *)SvRV(data);
	n_raw = av_len(av) + 1;

	Newx(x, n_raw, NV);

	// Extract variables and calculate mean (skipping undefined/NaN values)
	for (size_t i = 0; i < n_raw; i++) {
	  SV **restrict elem = av_fetch(av, i, 0);
	  if (elem && SvOK(*elem)) {
		   NV val = SvNV(*elem);
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
	// Calculate Sum of Squares
	for (size_t i = 0; i < n; i++) {
	  ssq += (x[i] - mean) * (x[i] - mean);
	}
	if (ssq == 0.0) {
	  Safefree(x);
	  croak("Data is perfectly constant; cannot compute Shapiro-Wilk test");
	}
	qsort(x, n, sizeof(NV), compare_doubles);
	// --- Core AS R94 Algorithm: Weights and Statistic W
	if (n == 3) {
	  NV a_val = 0.7071067811865475; // sqrt(1/2)
	  NV b_val = a_val * (x[2] - x[0]);
	  w = (b_val * b_val) / ssq;
	  if (w < 0.75) w = 0.75; 
	  // Exact P-value for n=3
	  p_val = 1.90985931710274 * (asin(sqrt(w)) - 1.04719755119660);
	} else {
		NV *restrict m, *restrict a;
		NV sum_m2 = 0.0, b_val = 0.0;
		Newx(m, n, NV);
		Newx(a, n, NV);
		for (size_t i = 0; i < n; i++) {
			m[i] = inverse_normal_cdf((i + 1.0 - 0.375) / (n + 0.25));
			sum_m2 += m[i] * m[i];
		}
		NV u = 1.0 / sqrt((NV)n);
		NV a_n = -2.706056*pow(u,5) + 4.434685*pow(u,4) - 2.071190*pow(u,3) - 0.147981*pow(u,2) + 0.221157*u + m[n-1]/sqrt(sum_m2);
		a[n-1] = a_n;
		a[0]   = -a_n;
		if (n == 4 || n == 5) {
			NV eps = (sum_m2 - 2.0 * m[n-1]*m[n-1]) / (1.0 - 2.0 * a_n*a_n);
			for (unsigned int i = 1; i < n-1; i++) {
				 a[i] = m[i] / sqrt(eps);
			}
		} else {
			NV a_n1 = -3.582633*pow(u,5) + 5.682633*pow(u,4) - 1.752461*pow(u,3) - 0.293762*pow(u,2) + 0.042981*u + m[n-2]/sqrt(sum_m2);
			a[n-2] = a_n1;
			a[1]   = -a_n1;
			NV eps = (sum_m2 - 2.0 * m[n-1]*m[n-1] - 2.0 * m[n-2]*m[n-2]) / (1.0 - 2.0 * a_n*a_n - 2.0 * a_n1*a_n1);
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
		NV y = log(1.0 - w);
		NV z;
		if (n <= 11) {
			// Royston's branch for 4 <= n <= 11 (AS R94, small-sample path).
			// gamma is the upper bound on y = log(1-W);
			// if y reaches gamma the p-value is essentially zero
			NV nn = (NV)n;
			NV gamma = 0.459 * nn - 2.273;
			if (y >= gamma) {
				 p_val = 1e-19;
			} else {
				 // Horner-form polynomials in n for mu and log(sigma)
				 NV mu     = 0.544  + nn * (-0.39978  + nn * ( 0.025054  - nn * 0.0006714));
				 NV sig_val= 1.3822 + nn * (-0.77857  + nn * ( 0.062767  - nn * 0.0020322));
				 NV sigma  = exp(sig_val);
				 z = (-log(gamma - y) - mu) / sigma;
				 /* Upper-tail probability P(Z > z): small W → large z → small p-value.
				 */
				 p_val = 0.5 * erfc(z * M_SQRT1_2);
			}
		} else {
			// Royston's branch for n >= 12 (AS R94, large-sample path)
			NV ln_n   = log((NV)n);
			// Horner-form polynomials in log(n) for mu and log(sigma). */
			NV mu     = -1.5861 + ln_n * (-0.31082 + ln_n * (-0.083751 + ln_n * 0.0038915));
			NV sig_val= -0.4803 + ln_n * (-0.082676 + ln_n * 0.0030302);
			NV sigma  = exp(sig_val);
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

NV min(...)
	PROTOTYPE: @
	INIT:
		NV min_val = 0.0;
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
						 NV val = SvNV(*tv);
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
				 NV val = SvNV(arg);
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

NV max(...)
	PROTOTYPE: @
	INIT:
		NV max_val = 0.0;
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
					   NV val = SvNV(*tv);
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
			   NV val = SvNV(arg);
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
	NV min = 0.0, max = 1.0;

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
	const NV range = max - min;
	for (size_t j = 0; j < n; j++) {
		NV r;
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
	NV prob = 0.5;

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
		NV *restrict x;
		Newx(x, n_raw, NV);
		size_t n = 0;
		NV min_val = DBL_MAX, max_val = -DBL_MAX;

		for (size_t i = 0; i < n_raw; i++) {
			SV**restrict tv = av_fetch(x_av, i, 0);
			if (tv && SvOK(*tv)) {
				 NV val = SvNV(*tv);
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
// Support named parameters even if mixed with positional arguments
			for (unsigned short i = 1; i < items - 1; i++) {
				 // Make sure the SV holds a string before doing string comparison
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
		NV *restrict breaks, *restrict mids, *restrict density;
		size_t *restrict counts;
		Newx(breaks,  n_bins + 1, NV);
		Newx(mids,    n_bins,     NV);
		Newx(density, n_bins,     NV);
		Newx(counts,  n_bins,     size_t);
		// Generate simple linear breaks
		NV step = (max_val - min_val) / (NV)n_bins;
		for (size_t i = 0; i <= n_bins; i++) {
			breaks[i] = min_val + (NV)i * step;
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
		unsigned int arg_idx = 0;
		// --- 1. Consume first positional arg as 'x' if it's an array ref
		if (arg_idx < items && SvROK(ST(arg_idx)) && SvTYPE(SvRV(ST(arg_idx))) == SVt_PVAV) {
			 x_sv = ST(arg_idx);
			 arg_idx++;
		}
		// --- 2. Remaining args must be key-value pairs
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
		// --- Extract valid numeric data & drop NAs (Upgraded to NV)
		NV *restrict x;
		Newx(x, n_raw, NV);
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
		// Note: You must update `compare_doubles` to accept and compare `NV` types!
		qsort(x, n, sizeof(NV), compare_NVs); 
		// --- Parse Probabilities (Upgraded to NV) ---
		NV default_probs[] = {0.0, 0.25, 0.50, 0.75, 1.0};
		unsigned int n_probs = 5;
		NV *restrict probs;
		if (probs_sv && SvROK(probs_sv) && SvTYPE(SvRV(probs_sv)) == SVt_PVAV) {
			AV *restrict p_av = (AV*)SvRV(probs_sv);
			n_probs = av_len(p_av) + 1;
			Newx(probs, n_probs, NV);
			for (unsigned int i = 0; i < n_probs; i++) {
				 SV **tv = av_fetch(p_av, i, 0);
				 probs[i] = (tv && SvOK(*tv)) ? SvNV(*tv) : 0.0;
				 if (probs[i] < 0.0 || probs[i] > 1.0) {
					 Safefree(x); Safefree(probs);
					 croak("quantile: probabilities must be between 0 and 1");
				 }
			}
		} else {
			Newx(probs, n_probs, NV);
			for (unsigned int i = 0; i < n_probs; i++) probs[i] = default_probs[i];
		}
		// --- Calculate Quantiles (R Type 7 Algorithm) ---
		HV *restrict res_hv = newHV();
		for (size_t i = 0; i < n_probs; i++) {
			NV p = probs[i];
			NV q = 0.0;

			if (n == 1) {
				 q = x[0];
			} else if (p == 1.0) {
				 q = x[n - 1]; 
			} else if (p == 0.0) {
				 q = x[0];
			} else {
				 NV h = (n - 1) * p;
				 unsigned int j = (unsigned int)h; 
				 NV gamma = h - j;
				 q = (1.0 - gamma) * x[j] + gamma * x[j + 1];
			}
			// --- Format hash key with Epsilon guarding ---
			char key[32];
			double pct = (double)(p * 100.0); // Safe to cast to double just for formatting
			double pct_rounded = floor(pct + 0.5); // C89 safe rounding
			// Use 1e-9 epsilon check instead of strict integer equality
			if (fabs(pct - pct_rounded) < 1e-9) {
				 snprintf(key, sizeof(key), "%.0f%%", pct_rounded);
			} else {
				 snprintf(key, sizeof(key), "%.1f%%", pct);
			}
			
			hv_store(res_hv, key, strlen(key), newSVnv(q), 0);
		}
		Safefree(x); Safefree(probs);
		RETVAL = newRV_noinc((SV*)res_hv);
	}
	OUTPUT:
	  RETVAL

NV mean(...)
	PROTOTYPE: @
	INIT:
	  NV total = 0;
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

NV sum(...)
	PROTOTYPE: @
	INIT:
		NV total = 0;
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

NV sd(...)
	PROTOTYPE: @
	INIT:
	  NV mean = 0.0, M2 = 0.0;
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
						NV val = SvNV(*tv);
						NV delta = val - mean;
						mean += delta / count;
						M2 += delta * (val - mean);
				  } else {
						croak("sd: undefined value at array ref index %zu (argument %zu)", j, i);
				  }
				}
			} else if (SvOK(arg)) {
				 count++;
				 NV val = SvNV(arg);
				 NV delta = val - mean;
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

NV var(...)
	PROTOTYPE: @
	INIT:
	  NV mean = 0.0, M2 = 0.0;
	  size_t count = 0;
	CODE:
	// Single Pass Variance via Welford's Algorithm
		for (size_t i = 0; i < items; i++) {
			SV* restrict arg = ST(i);
			if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) {
				 AV* restrict av = (AV*)SvRV(arg);
				 size_t len = av_len(av) + 1;
				 for (size_t j = 0; j < len; j++) {
					  SV** restrict tv = av_fetch(av, j, 0);
					  if (tv && SvOK(*tv)) {
						   count++;
						   NV val = SvNV(*tv);
						   NV delta = val - mean;
						   mean += delta / count;
						   M2 += delta * (val - mean);
					  } else {
						   croak("var: undefined value at array ref index %zu (argument %zu)", j, i);
					  }
				 }
			} else if (SvOK(arg)) {
				 count++;
				 NV val = SvNV(arg);
				 NV delta = val - mean;
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
		NV mu = 0.0, conf_level = 0.95;
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
		NV mean_x = 0.0, M2_x = 0.0, var_x, t_stat, df, p_val, std_err, cint_est;
		HV*restrict results = newHV();
		for (size_t i = 0; i < nx; i++) {
			SV**restrict tv = av_fetch(x_av, i, 0);
			NV val = (tv && SvOK(*tv)) ? SvNV(*tv) : 0;
			NV delta = val - mean_x;
			mean_x += delta / (i + 1);
			M2_x += delta * (val - mean_x);
		}
		var_x = M2_x / (nx - 1);
		if (var_x == 0.0 && !y_av) croak("t_test: data are essentially constant");

		if (paired || y_av) {
			if (!y_av) croak("t_test: 'y' must be provided for paired or two-sample tests");
			size_t ny = av_len(y_av) + 1;
			if (paired && ny != nx) croak("t_test: Paired arrays must be same length");
			NV mean_y = 0.0, M2_y = 0.0, var_y;
			for (size_t i = 0; i < ny; i++) {
				 SV**restrict tv = av_fetch(y_av, i, 0);
				 NV val = (tv && SvOK(*tv)) ? SvNV(*tv) : 0;
				 NV delta = val - mean_y;
				 mean_y += delta / (i + 1);
				 M2_y += delta * (val - mean_y);
			}
			var_y = M2_y / (ny - 1);
			if (paired) {
				 NV mean_d = 0.0, M2_d = 0.0;
				 for (size_t i = 0; i < nx; i++) {
					  SV**restrict dx_ptr = av_fetch(x_av, i, 0);
					  SV**restrict dy_ptr = av_fetch(y_av, i, 0);
					 NV dx = (dx_ptr && SvOK(*dx_ptr)) ? SvNV(*dx_ptr) : 0.0;
					 NV dy = (dy_ptr && SvOK(*dy_ptr)) ? SvNV(*dy_ptr) : 0.0;
					 NV val = dx - dy;
					 NV delta = val - mean_d;
					 mean_d += delta / (i + 1);
					 M2_d += delta * (val - mean_d);
				 }
				 NV var_d = M2_d / (nx - 1);
				 if (var_d == 0.0) croak("t_test: data are essentially constant");
				 cint_est = mean_d;
				 std_err  = sqrt(var_d / nx);
				 t_stat   = (cint_est - mu) / std_err;
				 df       = nx - 1;
				 hv_store(results, "estimate", 8, newSVnv(mean_d), 0);
			} else if (var_equal) {
				 if (var_x == 0.0 && var_y == 0.0) croak("t_test: data are essentially constant");
				 NV pooled_var = ((nx - 1) * var_x + (ny - 1) * var_y) / (nx + ny - 2);
				 cint_est = mean_x - mean_y;
				 std_err  = sqrt(pooled_var * (1.0 / nx + 1.0 / ny));
				 t_stat   = (cint_est - mu) / std_err;
				 df       = nx + ny - 2;
				 hv_store(results, "estimate_x", 10, newSVnv(mean_x), 0);
				 hv_store(results, "estimate_y", 10, newSVnv(mean_y), 0);
			} else {
				 if (var_x == 0.0 && var_y == 0.0) croak("t_test: data are essentially constant");
				 cint_est         = mean_x - mean_y;
				 NV stderr_x2 = var_x / nx;
				 NV stderr_y2 = var_y / ny;
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
		NV alpha = 1.0 - conf_level, t_crit, ci_lower, ci_upper;
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
		NV *restrict adj;
		Newx(arr, n, PVal);
		Newx(adj, n, NV);

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
				NV v = arr[i].p * n;
				adj[arr[i].orig_idx] = (v < 1.0) ? v : 1.0;
			}
		} else if (strcmp(meth, "holm") == 0) {
			NV cummax = 0.0;
			for (size_t i = 0; i < n; i++) {
				 NV v = arr[i].p * (n - i);
				 if (v > cummax) cummax = v;
				 adj[arr[i].orig_idx] = (cummax < 1.0) ? cummax : 1.0;
			}
		} else if (strcmp(meth, "hochberg") == 0) {
			NV cummin = 1.0;
			for (ssize_t i = n - 1; i >= 0; i--) {
				 NV v = arr[i].p * (n - i);
				 if (v < cummin) cummin = v;
				 adj[arr[i].orig_idx] = (cummin < 1.0) ? cummin : 1.0;
			}
		} else if (strcmp(meth, "bh") == 0) {
			NV cummin = 1.0;
			for (ssize_t i = n - 1; i >= 0; i--) {
				NV v = arr[i].p * n / (i + 1.0);
				if (v < cummin) cummin = v;
				adj[arr[i].orig_idx] = (cummin < 1.0) ? cummin : 1.0;
			}
		} else if (strcmp(meth, "by") == 0) {
			NV q = 0.0;
			for (size_t i = 1; i <= n; i++) q += 1.0 / i;
			NV cummin = 1.0;
			for (ssize_t i = n - 1; i >= 0; i--) {
				NV v = arr[i].p * n / (i + 1.0) * q;
				if (v < cummin) cummin = v;
				adj[arr[i].orig_idx] = (cummin < 1.0) ? cummin : 1.0;
			}
		} else if (strcmp(meth, "hommel") == 0) {
			NV *restrict pa, *restrict q_arr;
			Newx(pa, n, NV);
			Newx(q_arr, n, NV);
			// Initial: min(n * p[i] / (i + 1))
			NV min_val = n * arr[0].p;
			for (size_t i = 1; i < n; i++) {
				NV temp = (n * arr[i].p) / (i + 1.0);
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
				 NV q1 = (j * arr[n_mj + 1].p) / 2.0;
				 for (size_t k = 1; k < i2_len; k++) {
					 NV temp_q1 = (j * arr[n_mj + 1 + k].p) / (2.0 + k);
					 if (temp_q1 < q1) {
						 q1 = temp_q1;
					 }
				 }
				 // q[ij] <- pmin(j * p[ij], q1)
				 for (size_t i = 0; i <= n_mj; i++) {
					 NV v = j * arr[i].p;
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
				NV v = (pa[i] > arr[i].p) ? pa[i] : arr[i].p;
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

NV median(...)
	PROTOTYPE: @
	INIT:
	  size_t total_count = 0, k = 0;
	  NV* restrict nums;
	  NV median_val = 0.0;
	CODE:
	  // Pass 1: Count valid elements — die immediately on any undef
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
	  Newx(nums, total_count, NV);

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
	  qsort(nums, total_count, sizeof(NV), compare_doubles);
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
			NV *restrict xd, *restrict yd;
			Newx(xd, nx, NV);
			Newx(yd, ny, NV);
			bool x_sd0 = 1, y_sd0 = 1;
			NV x_first = NAN, y_first = NAN;
			for (size_t i = 0; i < nx; i++) {
				SV**restrict tv = av_fetch(x_av, i, 0);
				NV val = (tv && SvOK(*tv) && looks_like_number(*tv)) ? SvNV(*tv) : NAN;
				xd[i] = val;
				if (!isnan(val)) {
				  if (isnan(x_first)) x_first = val;
				  else if (val != x_first) x_sd0 = 0;
				}
			}
			for (size_t i = 0; i < ny; i++) {
				SV**restrict tv = av_fetch(y_av, i, 0);
				NV val = (tv && SvOK(*tv) && looks_like_number(*tv)) ? SvNV(*tv) : NAN;
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
			NV r = compute_cor(xd, yd, nx, method);
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
		NV **restrict col_x;
		Newx(col_x, ncols_x, NV*);
		for (size_t j = 0; j < ncols_x; j++) {
			Newx(col_x[j], nrows, NV);
			bool sd0 = 1;
			NV first = NAN;
			for (size_t i = 0; i < nrows; i++) {
				SV**restrict rv = av_fetch(x_av, i, 0);
				AV*restrict  row = (AV*)SvRV(*rv);
				SV**restrict cv  = av_fetch(row, j, 0);
				NV val = (cv && SvOK(*cv) && looks_like_number(*cv)) ? SvNV(*cv) : NAN;
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
		NV **restrict col_y = NULL;
		bool symmetric = 0;
		// 1 = cor(X) — result is symmetric
		if (has_y && y_is_matrix) {
			// cross-correlation: X (nrows × p) vs Y (nrows × q)
			SV**restrict yr0 = av_fetch(y_av, 0, 0);
			ncols_y = av_len((AV*)SvRV(*yr0)) + 1;
			if (ncols_y == 0) croak("cor: y matrix has zero columns");

			Newx(col_y, ncols_y, NV*);
			for (size_t j = 0; j < ncols_y; j++) {
				 Newx(col_y[j], nrows, NV);
				 bool sd0 = 1;
				 NV first = NAN;
				 for (size_t i = 0; i < nrows; i++) {
					 SV**restrict  rv = av_fetch(y_av, i, 0);
					 AV*restrict  row = (AV*)SvRV(*rv);
					 SV**restrict cv  = av_fetch(row, j, 0);
					 NV val = (cv && SvOK(*cv) && looks_like_number(*cv)) ? SvNV(*cv) : NAN;
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
			NV **restrict r_cache;
			Newx(r_cache, ncols_x, NV*);
			for (size_t i = 0; i < ncols_x; i++)
				 Newx(r_cache[i], ncols_x, NV);

			for (size_t i = 0; i < ncols_x; i++) {
				 r_cache[i][i] = 1.0; // diagonal
				 for (size_t j = i + 1; j < ncols_x; j++) {
					 NV r = compute_cor(col_x[i], col_x[j], nrows, method);
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
		NV center_val = 0.0, scale_val = 1.0;
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
			// MATRIX MODE: Scale columns independently (Just like R)
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
				 NV col_sum = 0.0;
				 NV *restrict col_data;
				 Newx(col_data, nrow, NV);
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

				 NV col_center = do_center_mean ? (col_sum / nrow) : center_val;
				 NV col_scale = scale_val;
				 // Calculate Standard Deviation for this specific column if needed
				 if (do_scale_sd) {
					 if (nrow <= 1) {
						 Safefree(col_data);
						 safefree(row_ptrs);
						 croak("scale needs >= 2 rows to calculate standard deviation for a matrix column");
					 }
					 NV sum_sq = 0.0;
					 for (size_t r = 0; r < nrow; r++) {
						 NV diff = col_data[r] - col_center;
						 sum_sq += diff * diff;
					 }
					 col_scale = sqrt(sum_sq / (nrow - 1));
				 }
				 // Store scaled values back into the new matrix rows
				 for (size_t r = 0; r < nrow; r++) {
					 NV centered = col_data[r] - col_center;
					 NV final_val = (col_scale == 0.0) ? (0.0 / 0.0) : (centered / col_scale);
					 av_store(row_ptrs[r], c, newSVnv(final_val));
				 }
				 Safefree(col_data);
			}
			safefree(row_ptrs);
			// Push the resulting matrix as a single Reference onto the Perl stack
			EXTEND(SP, 1);
			PUSHs(sv_2mortal(newRV_noinc((SV*)result_av)));
		} else {
			// FLAT LIST MODE: Original functionality
			size_t total_count = 0, k = 0;
			NV *restrict nums;
			NV sum = 0.0;
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
			Newx(nums, total_count, NV);
			for (size_t i = 0; i < data_items; i++) {
				 SV*restrict arg = ST(i);
				 if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) {
					 AV*restrict av = (AV*)SvRV(arg);
					 size_t len = av_len(av) + 1;
					 for (size_t j = 0; j < len; j++) {
						 SV**restrict tv = av_fetch(av, j, 0);
						 if (tv && SvOK(*tv)) { 
							 NV val = SvNV(*tv);
							 nums[k++] = val; sum += val;
						 }
					 }
				 } else if (SvOK(arg)) {
					 NV val = SvNV(arg);
					 nums[k++] = val; sum += val;
				 }
			}
			if (do_center_mean) center_val = sum / total_count;
			if (do_scale_sd) {
				 if (total_count <= 1) {
					 Safefree(nums);
					 croak("scale needs >= 2 elements to calculate SD");
				 }
				 NV sum_sq = 0.0;
				 for (size_t i = 0; i < total_count; i++) {
					 NV diff = nums[i] - center_val;
					 sum_sq += diff * diff;
				 }
				 scale_val = sqrt(sum_sq / (total_count - 1));
			}
			EXTEND(SP, total_count);
			for (size_t i = 0; i < total_count; i++) {
				NV centered = nums[i] - center_val;
				NV final_val = (scale_val == 0.0) ? (0.0 / 0.0) : (centered / scale_val);
				PUSHs(sv_2mortal(newSVnv(final_val)));
			}
			Safefree(nums); nums = NULL;
		}
	}

SV* matrix(...) 
CODE:
	SV*restrict data_sv = NULL;
	size_t nrow = 0, ncol = 0;
	bool byrow = FALSE, nrow_set = FALSE, ncol_set = FALSE;

	/* Hybrid Argument Parser */
	if (items > 0 && SvROK(ST(0)) && SvTYPE(SvRV(ST(0))) == SVt_PVAV) {
		/* POSITIONAL: matrix($data_ref, $nrow, $ncol, $byrow) */
		data_sv = ST(0);
		if (items > 1 && SvOK(ST(1))) {
			nrow = (size_t)SvUV(ST(1));
			nrow_set = TRUE;
		}
		if (items > 2 && SvOK(ST(2))) {
			ncol = (size_t)SvUV(ST(2));
			ncol_set = TRUE;
		}
		if (items > 3 && SvOK(ST(3))) {
			byrow = SvTRUE(ST(3));
		}
	} else if (items % 2 == 0) {
	  /* NAMED: matrix(data => [...], nrow => $n, ncol => $m) */
		for (size_t i = 0; i < items; i += 2) {
			char*restrict key = SvPV_nolen(ST(i));
			SV*restrict val   = ST(i + 1);
			if (strEQ(key, "data")) {
				 data_sv = val;
			} else if (strEQ(key, "nrow")) {
				 if (SvOK(val)) { nrow = (size_t)SvUV(val); nrow_set = TRUE; }
			} else if (strEQ(key, "ncol")) {
				 if (SvOK(val)) { ncol = (size_t)SvUV(val); ncol_set = TRUE; }
			} else if (strEQ(key, "byrow")) {
				 byrow = SvTRUE(val);
			} else {
				 croak("Unknown option: %s", key);
			}
		}
	} else {
		croak("Usage: matrix($data_ref, $nrow, $ncol, $byrow) OR matrix(data => $data_ref, ...)");
	}
	// Validate data input
	if (!data_sv || !SvROK(data_sv) || SvTYPE(SvRV(data_sv)) != SVt_PVAV) {
		croak("The 'data' option must be an array reference (e.g. [1..6] or rnorm(6))");
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
	size_t r, c; // Use unsigned types for counters to prevent negative indexing
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

SV *
lm(...)
	CODE:
	{
		const char *restrict formula = NULL;
		SV   *restrict data_sv = NULL;
		char *restrict f_cpy   = NULL;          /* heap, sized to the formula */
		char *restrict src, *restrict dst, *restrict tilde, *restrict lhs, *restrict rhs, *restrict chunk;
		char **restrict terms = NULL, **restrict uniq_terms = NULL, **restrict exp_terms = NULL;
		bool *restrict is_dummy = NULL;
		char **restrict dummy_base = NULL, **restrict dummy_level = NULL;
		unsigned int term_cap = 64, exp_cap = 64, num_terms = 0, num_uniq = 0, p = 0, p_exp = 0;
		size_t n = 0, valid_n = 0, i, j, k, l;
		bool has_intercept = TRUE;
		char **restrict row_names = NULL, **restrict valid_row_names = NULL;
		HV  **restrict row_hashes = NULL;
		HV   *restrict data_hoa = NULL;
		SV   *restrict ref = NULL;
		NV   *restrict X = NULL, *restrict Y = NULL, *restrict XtX = NULL, *restrict XtY = NULL;
		bool *restrict aliased = NULL;
		NV   *restrict beta = NULL;
		int   final_rank = 0, df_res = 0;
		HV   *restrict res_hv, *restrict coef_hv, *restrict fitted_hv, *restrict resid_hv, *restrict summary_hv;
		AV   *restrict terms_av;
		NV    rss = 0.0, rse_sq = 0.0;
		HE   *restrict entry;
		char *rhs_expanded = NULL;              /* heap, grows as needed */
		size_t rhs_len = 0, rhs_cap = 0;

		if (items % 2 != 0)
			croak("Usage: lm(formula => 'mpg ~ wt * hp', data => \\%%mtcars)");

		for (I32 i_arg = 0; i_arg < items; i_arg += 2) {
			const char *restrict key = SvPV_nolen(ST(i_arg));
			SV         *restrict val = ST(i_arg + 1);
			if      (strEQ(key, "formula")) formula = SvPV_nolen(val);
			else if (strEQ(key, "data"))    data_sv = val;
			else croak("lm: unknown argument '%s'", key);
		}
		if (!formula) croak("lm: formula is required");
		if (!data_sv || !SvROK(data_sv)) croak("lm: data is required and must be a reference");

		/* PHASE 1: Data Extraction */
		ref = SvRV(data_sv);
		if (SvTYPE(ref) == SVt_PVHV) {
			HV *restrict hv = (HV*)ref;
			if (hv_iterinit(hv) == 0) croak("lm: Data hash is empty");
			entry = hv_iternext(hv);
			if (entry) {
				SV *restrict val = hv_iterval(hv, entry);
				if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
					data_hoa = hv;
					n = (size_t)(av_len((AV*)SvRV(val)) + 1);
					Newx(row_names, n, char*);
					for (i = 0; i < n; i++) {
						char buf[32];
						snprintf(buf, sizeof(buf), "%lu", (unsigned long)(i + 1));
						row_names[i] = savepv(buf);
					}
				} else if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
					n = (size_t)HvUSEDKEYS(hv);
					Newx(row_names, n, char*);
					Newx(row_hashes, n, HV*);
					hv_iterinit(hv);
					i = 0;
					while ((entry = hv_iternext(hv))) {
						SV *restrict rval = hv_iterval(hv, entry);
						/* BUG FIX: validate every row, not just the first */
						if (!SvROK(rval) || SvTYPE(SvRV(rval)) != SVt_PVHV) {
							for (k = 0; k < i; k++) Safefree(row_names[k]);
							Safefree(row_names); Safefree(row_hashes);
							croak("lm: Hash values must all be HashRefs (HoH)");
						}
						I32 klen;
						row_names[i]  = savepv(hv_iterkey(entry, &klen));
						row_hashes[i] = (HV*)SvRV(rval);
						i++;
					}
				} else croak("lm: Hash values must be ArrayRefs (HoA) or HashRefs (HoH)");
			}
		} else if (SvTYPE(ref) == SVt_PVAV) {
			AV *restrict av = (AV*)ref;
			n = (size_t)(av_len(av) + 1);
			Newx(row_names, n, char*);
			Newx(row_hashes, n, HV*);
			for (i = 0; i < n; i++) {
				SV **restrict val = av_fetch(av, (SSize_t)i, 0);
				if (val && SvROK(*val) && SvTYPE(SvRV(*val)) == SVt_PVHV) {
					row_hashes[i] = (HV*)SvRV(*val);
					char buf[32];
					snprintf(buf, sizeof(buf), "%lu", (unsigned long)(i + 1));
					row_names[i] = savepv(buf);
				} else {
					for (k = 0; k < i; k++) Safefree(row_names[k]);
					Safefree(row_names); Safefree(row_hashes);
					croak("lm: Array values must be HashRefs (AoH)");
				}
			}
		} else croak("lm: Data must be an Array or Hash reference");

		/* PHASE 2: Formula Parsing & `.` Expansion */
		/* IMPROVEMENT: copy the formula into a buffer sized to the formula
		 * itself instead of a fixed 512-byte stack array (no truncation). */
		Newx(f_cpy, strlen(formula) + 1, char);
		src = (char*)formula; dst = f_cpy;
		while (*src) { if (!isspace((unsigned char)*src)) *dst++ = *src; src++; }
		*dst = '\0';

		tilde = strchr(f_cpy, '~');
		if (!tilde) {
			for (i = 0; i < n; i++) Safefree(row_names[i]);
			Safefree(row_names); if (row_hashes) Safefree(row_hashes);
			Safefree(f_cpy);
			croak("lm: invalid formula, missing '~'");
		}
		*tilde = '\0';
		lhs = f_cpy;
		rhs = tilde + 1;

		/* Remove intercept-suppression markers from RHS, skipping I(...). */
		{
			char *restrict p_idx = rhs;
			while (*p_idx) {
				if (p_idx[0] == 'I' && p_idx[1] == '(') {
					int depth = 0;
					while (*p_idx) { if (*p_idx == '(') depth++; else if (*p_idx == ')') { depth--; if (depth == 0) { p_idx++; break; } } p_idx++; }
					continue;
				}
				if (p_idx[0] == '-' && p_idx[1] == '1' &&
					(p_idx[2] == '\0' || p_idx[2] == '+' || p_idx[2] == '-')) {
					has_intercept = FALSE;
					memmove(p_idx, p_idx + 2, strlen(p_idx + 2) + 1);
					continue;
				}
				if (p_idx[0] == '+' && p_idx[1] == '0' &&
					(p_idx[2] == '\0' || p_idx[2] == '+' || p_idx[2] == '-')) {
					has_intercept = FALSE;
					memmove(p_idx, p_idx + 2, strlen(p_idx + 2) + 1);
					continue;
				}
				if (p_idx == rhs && p_idx[0] == '0' && p_idx[1] == '+') {
					has_intercept = FALSE;
					memmove(p_idx, p_idx + 2, strlen(p_idx + 2) + 1);
					continue;
				}
				if (p_idx == rhs && p_idx[0] == '0' && p_idx[1] == '\0') {
					has_intercept = FALSE; p_idx[0] = '\0'; break;
				}
				if (p_idx[0] == '+' && p_idx[1] == '1' &&
					(p_idx[2] == '\0' || p_idx[2] == '+' || p_idx[2] == '-')) {
					memmove(p_idx, p_idx + 2, strlen(p_idx + 2) + 1);
					continue;
				}
				if (p_idx == rhs) {
					if (p_idx[0] == '1' && p_idx[1] == '\0') { p_idx[0] = '\0'; break; }
					if (p_idx[0] == '1' && p_idx[1] == '+') { memmove(p_idx, p_idx + 2, strlen(p_idx + 2) + 1); continue; }
				}
				p_idx++;
			}
		}
		/* Clean up stray `++`, leading `+`, trailing `+` */
		{
			char *restrict p_idx;
			while ((p_idx = strstr(rhs, "++")) != NULL)
				memmove(p_idx, p_idx + 1, strlen(p_idx + 1) + 1);
			if (rhs[0] == '+') memmove(rhs, rhs + 1, strlen(rhs + 1) + 1);
			size_t len_rhs = strlen(rhs);
			if (len_rhs > 0 && rhs[len_rhs - 1] == '+') rhs[len_rhs - 1] = '\0';
		}

		/* Expand `.` operator.
		 * IMPROVEMENT: rhs_expanded is a heap buffer that grows on demand
		 * (was a fixed 2048-byte array that silently truncated), and each
		 * append is O(1) instead of strcat's O(n^2) rescan. */
		Newxz(rhs_expanded, 1, char); rhs_cap = 1;     /* valid "" to start */
		chunk = strtok(rhs, "+");
		while (chunk != NULL) {
			if (strcmp(chunk, ".") == 0) {
				AV *restrict cols = get_all_columns(aTHX_ data_hoa, row_hashes, n);
				for (size_t c = 0; c <= (size_t)av_len(cols); c++) {
					SV **restrict col_sv = av_fetch(cols, (SSize_t)c, 0);
					if (col_sv && SvOK(*col_sv)) {
						const char *restrict col_name = SvPV_nolen(*col_sv);
						if (strcmp(col_name, lhs) != 0)
							lm_append(aTHX_ &rhs_expanded, &rhs_len, &rhs_cap, col_name);
					}
				}
				SvREFCNT_dec(cols);
			} else {
				lm_append(aTHX_ &rhs_expanded, &rhs_len, &rhs_cap, chunk);
			}
			chunk = strtok(NULL, "+");
		}

		Newx(terms, term_cap, char*); Newx(uniq_terms, term_cap, char*);
		Newx(exp_terms, exp_cap, char*); Newx(is_dummy, exp_cap, bool);
		Newx(dummy_base, exp_cap, char*); Newx(dummy_level, exp_cap, char*);

		if (has_intercept) terms[num_terms++] = savepv("Intercept");

		if (rhs_len > 0) {
			chunk = strtok(rhs_expanded, "+");
			while (chunk != NULL) {
				if (num_terms >= term_cap - 3) {
					term_cap *= 2;
					Renew(terms, term_cap, char*); Renew(uniq_terms, term_cap, char*);
				}
				char *restrict star = strchr(chunk, '*');
				if (star) {
					*star = '\0';
					char *restrict left  = chunk;
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
		/* done with the parsed RHS text */
		Safefree(rhs_expanded); rhs_expanded = NULL;

		for (i = 0; i < num_terms; i++) {
			bool found = FALSE;
			for (j = 0; j < num_uniq; j++) { if (strcmp(terms[i], uniq_terms[j]) == 0) { found = TRUE; break; } }
			if (!found) uniq_terms[num_uniq++] = savepv(terms[i]);
		}
		p = num_uniq;

		/* PHASE 3: Categorical Expansion */
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
					/* IMPROVEMENT: qsort instead of an O(n^2) bubble sort */
					qsort(levels, num_levels, sizeof(char*), lm_str_qsort);
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
		Newx(X, n * p, NV); Newx(Y, n, NV);
		Newx(valid_row_names, n, char*);

		/* PHASE 4: Matrix Construction & Listwise Deletion
		 * IMPROVEMENT: write each candidate row straight into X at its
		 * commit position instead of malloc/copy/free of a per-row scratch
		 * buffer (removes n allocations and n*p copies). A dropped row's
		 * partial writes are simply overwritten by the next candidate. */
		for (i = 0; i < n; i++) {
			NV y_val = evaluate_term(aTHX_ data_hoa, row_hashes, i, lhs);
			if (isnan(y_val)) { Safefree(row_names[i]); continue; }

			bool row_ok = TRUE;
			size_t base = valid_n * (size_t)p;
			for (j = 0; j < p; j++) {
				if (strcmp(exp_terms[j], "Intercept") == 0) {
					X[base + j] = 1.0;
				} else if (is_dummy[j]) {
					char *restrict str_val = get_data_string_alloc(aTHX_ data_hoa, row_hashes, i, dummy_base[j]);
					if (str_val) {
						X[base + j] = (strcmp(str_val, dummy_level[j]) == 0) ? 1.0 : 0.0;
						Safefree(str_val);
					} else { row_ok = FALSE; break; }
				} else {
					NV v = evaluate_term(aTHX_ data_hoa, row_hashes, i, exp_terms[j]);
					if (isnan(v)) { row_ok = FALSE; break; }
					X[base + j] = v;
				}
			}
			if (!row_ok) { Safefree(row_names[i]); continue; }
			Y[valid_n] = y_val;
			valid_row_names[valid_n] = row_names[i];
			valid_n++;
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
			/* BUG FIX: free the committed row-name strings, not just the array */
			for (i = 0; i < valid_n; i++) Safefree(valid_row_names[i]);
			Safefree(X); Safefree(Y); Safefree(valid_row_names);
			if (row_hashes) Safefree(row_hashes);
			Safefree(f_cpy);
			croak("lm: 0 degrees of freedom (too many NAs or parameters > observations)");
		}
		/* lhs (into f_cpy) is no longer needed past PHASE 4 */
		Safefree(f_cpy); f_cpy = NULL;

		/* IMPROVEMENT: reclaim the tail of X left unused by listwise deletion */
		if (valid_n < n) Renew(X, valid_n * (size_t)p, NV);

		/* PHASE 5: OLS Math */
		Newxz(XtX, p * p, NV);
		for (i = 0; i < p; i++)
			for (j = 0; j < p; j++) {
				NV sum = 0.0;
				for (k = 0; k < valid_n; k++) sum += X[k * p + i] * X[k * p + j];
				XtX[i * p + j] = sum;
			}
		Newxz(XtY, p, NV);
		for (i = 0; i < p; i++) {
			NV sum = 0.0;
			for (k = 0; k < valid_n; k++) sum += X[k * p + i] * Y[k];
			XtY[i] = sum;
		}
		Newx(aliased, p, bool);
		final_rank = sweep_matrix_ols(XtX, p, aliased);
		Newxz(beta, p, NV);
		for (i = 0; i < p; i++) {
			if (aliased[i]) { beta[i] = NAN; }
			else {
				NV sum = 0.0;
				for (j = 0; j < p; j++) if (!aliased[j]) sum += XtX[i * p + j] * XtY[j];
				beta[i] = sum;
			}
		}

		/* PHASE 6: Metrics & Cleanup */
		res_hv = newHV(); coef_hv = newHV(); fitted_hv = newHV(); resid_hv = newHV();
		summary_hv = newHV(); terms_av = newAV();
		df_res = (int)valid_n - final_rank;
		NV sum_y = 0.0, mss = 0.0;
		for (i = 0; i < valid_n; i++) sum_y += Y[i];
		NV mean_y = sum_y / (NV)valid_n;
		for (i = 0; i < valid_n; i++) {
			NV y_hat = 0.0;
			for (j = 0; j < p; j++) if (!aliased[j]) y_hat += X[i * p + j] * beta[j];
			NV res    = Y[i] - y_hat;
			rss      += res * res;
			NV diff_m = has_intercept ? (y_hat - mean_y) : y_hat;
			mss      += diff_m * diff_m;
			hv_store(fitted_hv, valid_row_names[i], strlen(valid_row_names[i]), newSVnv(y_hat), 0);
			hv_store(resid_hv,  valid_row_names[i], strlen(valid_row_names[i]), newSVnv(res),   0);
			Safefree(valid_row_names[i]);
		}
		Safefree(valid_row_names);
		rse_sq = (df_res > 0) ? (rss / (NV)df_res) : NAN;

		int df_int = has_intercept ? 1 : 0;
		NV r_squared = 0.0, adj_r_squared = 0.0, f_stat = NAN, f_pvalue = NAN;
		int numdf = final_rank - df_int;

		if (final_rank != df_int && (mss + rss) > 0.0) {
			r_squared     = mss / (mss + rss);
			adj_r_squared = 1.0 - (1.0 - r_squared) * ((NV)(valid_n - df_int) / (NV)df_res);
			if (rse_sq > 0.0 && numdf > 0) {
				f_stat   = (mss / (NV)numdf) / rse_sq;
				f_pvalue = 1.0 - pf(f_stat, (NV)numdf, (NV)df_res);
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
				NV se    = sqrt(rse_sq * XtX[j * p + j]);
				NV t_val = (se > 0.0) ? (beta[j] / se) : (INFINITY * (beta[j] >= 0.0 ? 1.0 : -1.0));
				NV p_val = get_t_pvalue(t_val, df_res, "two.sided");
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
		/* Deep Cleanup */
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
	NV from
	NV to
	NV by
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
		NV n_elements_d = (to - from) / by;
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
	  NV mean = 0.0, sd = 1.0;
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
				NV u, v, s;
				do {
					// Drand01() hooks into Perl's internal PRNG, respecting Perl's srand()
					u = 2.0 * Drand01() - 1.0;
					v = 2.0 * Drand01() - 1.0;
					s = u * u + v * v;
				} while (s >= 1.0 || s == 0.0);
				NV mul = sqrt(-2.0 * log(s) / s);
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
	//
	// PHASE 0: R-style stack() for missing formula
	//
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
	NV **restrict X_mat = NULL;
	NV *restrict Y = NULL;
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
	X_mat = (NV**)safemalloc(n * sizeof(NV*));
	for(i = 0; i < n; i++) X_mat[i] = (NV*)safemalloc(p_exp * sizeof(NV));
	Newx(Y, n, NV);
	// PHASE 4: Matrix Construction & Listwise Deletion
	for (i = 0; i < n; i++) {
		NV y_val = evaluate_term(aTHX_ data_hoa, row_hashes, i, lhs);
		if (isnan(y_val)) { Safefree(row_names[i]); continue; }
		bool row_ok = TRUE;
		NV *restrict row_x = (NV*)safemalloc(p_exp * sizeof(NV));
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
	// PHASE 5: Math & Output Formatting
	bool *restrict aliased_qr = (bool*)safemalloc(p_exp * sizeof(bool));
	size_t *restrict rank_map = (size_t*)safemalloc(p_exp * sizeof(size_t));
	apply_householder_aov(X_mat, Y, valid_n, p_exp, aliased_qr, rank_map);
	NV *restrict term_ss;
	int *restrict term_df;
	Newxz(term_ss, num_uniq, NV);
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
	NV rss_prev = 0.0;
	for (i = rank; i < valid_n; i++) {
		  rss_prev += Y[i] * Y[i];
	}
	int res_df = valid_n - rank;
	NV ms_res = (res_df > 0) ? rss_prev / res_df : 0.0;
	HV*restrict ret_hash = newHV();
	for (j = 0; j < num_uniq; j++) {
		if (strcmp(uniq_terms[j], "Intercept") == 0) continue;
		HV*restrict term_stats = newHV();
		NV ss = term_ss[j];
		int df = term_df[j];
		NV ms = (df > 0) ? ss / df : 0.0;

		hv_stores(term_stats, "Df", newSViv(df));
		hv_stores(term_stats, "Sum Sq", newSVnv(ss));
		hv_stores(term_stats, "Mean Sq", newSVnv(ms));
		if (ms_res > 0.0 && df > 0) {
			NV f_val = ms / ms_res;
			hv_stores(term_stats, "F value", newSVnv(f_val));
			hv_stores(term_stats, "Pr(>F)", newSVnv(1.0 - pf(f_val, (NV)df, (NV)res_df)));
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
			NV col_sum = 0.0;
			IV      col_count = 0;
			for (i = 0; i < tgt_n; i++) {
				 NV val = evaluate_term(aTHX_ tgt_hoa, tgt_row_hashes, i, col_name);
				 if (!isnan(val)) { col_sum += val; col_count++; }
			}
			NV col_mean = (col_count > 0) ? col_sum / col_count : NAN;
			hv_store(mean_hv, col_name, strlen(col_name), newSVnv(col_mean), 0);
			hv_store(size_hv, col_name, strlen(col_name), newSViv(col_count), 0);
		}
		SvREFCNT_dec(all_cols);
		HV *restrict gs_hv = newHV();
		hv_stores(gs_hv, "mean", newRV_noinc((SV*)mean_hv));
		hv_stores(gs_hv, "size", newRV_noinc((SV*)size_hv));
		hv_stores(ret_hash, "group_stats", newRV_noinc((SV*)gs_hv));
	}
	// Deep Cleanup
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

	SV *restrict data_ref = ST(0);
	NV conf_level = 0.95;
	const char *restrict alternative = "two.sided";

	for (unsigned int i = 1; i < items; i += 2) {
		if (i + 1 >= items) croak("fisher_test: odd number of named arguments");
		const char *restrict key = SvPV_nolen(ST(i));
		SV *restrict val = ST(i + 1);
		if (strEQ(key, "conf_level") || strEQ(key, "conf.level")) {
			conf_level = SvNV(val);
			if (!(conf_level > 0 && conf_level < 1))
				 croak("fisher_test: conf_level must be between 0 and 1");
		} else if (strEQ(key, "alternative")) {
			alternative = SvPV_nolen(val);
			if (strNE(alternative, "two.sided") && strNE(alternative, "less") &&
				 strNE(alternative, "greater"))
				 croak("fisher_test: alternative must be 'two.sided', 'less' or 'greater'");
		} else {
			croak("fisher_test: unknown argument '%s'", key);
		}
	}
	if (!SvROK(data_ref)) croak("fisher_test requires a reference to a 2x2 Array or Hash");
	SV *restrict deref = SvRV(data_ref);
	long a = 0, b = 0, c = 0, d = 0;
	if (SvTYPE(deref) == SVt_PVAV) {
	  AV *restrict outer = (AV *)deref;
	  if (av_len(outer) != 1) croak("Outer array must have exactly 2 rows");
	  SV **restrict r1p = av_fetch(outer, 0, 0);
	  SV **restrict r2p = av_fetch(outer, 1, 0);
	  if (!(r1p && r2p && SvROK(*r1p) && SvROK(*r2p)
			 && SvTYPE(SvRV(*r1p)) == SVt_PVAV && SvTYPE(SvRV(*r2p)) == SVt_PVAV))
		   croak("Invalid 2D array structure: need two array-ref rows");
	  AV *restrict r1 = (AV *)SvRV(*r1p), *r2 = (AV *)SvRV(*r2p);
	  if (av_len(r1) != 1 || av_len(r2) != 1)
		   croak("Each row must have exactly 2 columns");
	  a = ft_cell(aTHX_ *av_fetch(r1, 0, 0), "cell [0][0]");
	  b = ft_cell(aTHX_ *av_fetch(r1, 1, 0), "cell [0][1]");
	  c = ft_cell(aTHX_ *av_fetch(r2, 0, 0), "cell [1][0]");
	  d = ft_cell(aTHX_ *av_fetch(r2, 1, 0), "cell [1][1]");
	} else if (SvTYPE(deref) == SVt_PVHV) {
	  /* 2x2 hash; rows and columns are ordered by lexical key sort so the
		* result is deterministic regardless of Perl's hash randomization. */
	  HV *restrict outer = (HV *)deref;
	  if (HvUSEDKEYS(outer) != 2) croak("Outer hash must have exactly 2 keys");
	  hv_iterinit(outer);
	  HE *restrict e1 = hv_iternext(outer), *e2 = hv_iternext(outer);
	  const char *restrict ok1 = SvPV_nolen(hv_iterkeysv(e1));
	  int swap_rows = strcmp(ok1, SvPV_nolen(hv_iterkeysv(e2))) > 0;
	  SV *restrict row1_sv = hv_iterval(outer, swap_rows ? e2 : e1);
	  SV *restrict row2_sv = hv_iterval(outer, swap_rows ? e1 : e2);
	  if (!SvROK(row1_sv) || SvTYPE(SvRV(row1_sv)) != SVt_PVHV ||
		   !SvROK(row2_sv) || SvTYPE(SvRV(row2_sv)) != SVt_PVHV)
		   croak("Inner elements must be hash refs");

	  HV *restrict rows[2]; rows[0] = (HV *)SvRV(row1_sv); rows[1] = (HV *)SvRV(row2_sv);
	  long cells[2][2];
	  for (unsigned int rr = 0; rr < 2; rr++) {
		   HV *restrict in = rows[rr];
		   if (HvUSEDKEYS(in) != 2) croak("Inner hashes must have exactly 2 keys");
		   hv_iterinit(in);
		   HE *c1 = hv_iternext(in), *c2 = hv_iternext(in);
		   const char *k1 = SvPV_nolen(hv_iterkeysv(c1));
		   int swap_cols = strcmp(k1, SvPV_nolen(hv_iterkeysv(c2))) > 0;
		   HE *col0 = swap_cols ? c2 : c1;
		   HE *col1 = swap_cols ? c1 : c2;
		   cells[rr][0] = ft_cell(aTHX_ hv_iterval(in, col0), "hash cell");
		   cells[rr][1] = ft_cell(aTHX_ hv_iterval(in, col1), "hash cell");
	  }
	  a = cells[0][0]; b = cells[0][1]; c = cells[1][0]; d = cells[1][1];
	} else {
	  croak("Input must be a 2D Array or 2D Hash");
	}
	if (a + b + c + d == 0) croak("fisher_test: table is all zeros");
	NV p_val = exact_p_value(a, b, c, d, alternative);
	NV mle_or, ci_low, ci_high;
	calculate_exact_stats(a, b, c, d, conf_level, alternative, &mle_or, &ci_low, &ci_high);

	HV *restrict ret = newHV();
	hv_stores(ret, "method", newSVpv("Fisher's Exact Test for Count Data", 0));
	hv_stores(ret, "alternative", newSVpv(alternative, 0));
	AV *restrict ci = newAV();
	av_push(ci, newSVnv(ci_low));
	av_push(ci, newSVnv(ci_high));
	hv_stores(ret, "conf_int", newRV_noinc((SV *)ci));
	HV *restrict est = newHV();
	hv_stores(est, "odds ratio", newSVnv(mle_or));
	hv_stores(ret, "estimate", newRV_noinc((SV *)est));
	hv_stores(ret, "p_value", newSVnv(p_val));
	hv_stores(ret, "conf_level", newSVnv(conf_level));
	RETVAL = newRV_noinc((SV *)ret);
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
	NV tol = pow(2.2204460492503131e-16, 0.25); 

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

	NV n = is_null_n ? 0.0 : SvNV(sv_n);
	NV delta = is_null_delta ? 0.0 : SvNV(sv_delta);
	NV sd = (!sv_sd || is_null_sd) ? 1.0 : SvNV(sv_sd);
	NV sig_level = (!sv_sig_level || is_null_sig_level) ? 0.05 : SvNV(sv_sig_level);
	NV power = is_null_power ? 0.0 : SvNV(sv_power);
	short int tsample = (strEQ(type, "one.sample") || strEQ(type, "paired")) ? 1 : 2;
	short int tside = (strEQ(alternative, "one.sided") || strEQ(alternative, "greater") || strEQ(alternative, "less")) ? 1 : 2;
	if (tside == 2 && !is_null_delta) delta = fabs(delta);
	if (is_null_power) {
	  power = p_body(n, delta, sd, sig_level, tsample, tside, strict);
	} else if (is_null_n) {
		NV low = 2.0, high = 1e7;
		while (p_body(high, delta, sd, sig_level, tsample, tside, strict) < power && high < 1e12) high *= 2.0;
		while (high - low > tol) {
			NV mid = low + (high - low) / 2.0;
			if (p_body(mid, delta, sd, sig_level, tsample, tside, strict) < power) low = mid;
			else high = mid;
		}
		n = low + (high - low) / 2.0;
	} else if (is_null_sd) {
	  NV low = delta * 1e-7, high = delta * 1e7;
	  while (high - low > tol) {
		   NV mid = low + (high - low) / 2.0;
		   if (p_body(n, delta, mid, sig_level, tsample, tside, strict) > power) low = mid;
		   else high = mid;
	  }
	  sd = low + (high - low) / 2.0;
	} else if (is_null_delta) {
	  NV low = sd * 1e-7, high = sd * 1e7;
	  while (p_body(n, high, sd, sig_level, tsample, tside, strict) < power && high < 1e12) high *= 2.0;
	  while (high - low > tol) {
		   NV mid = low + (high - low) / 2.0;
		   if (p_body(n, mid, sd, sig_level, tsample, tside, strict) < power) low = mid;
		   else high = mid;
	  }
	  delta = low + (high - low) / 2.0;
	} else if (is_null_sig_level) {
	  NV low = 1e-10, high = 1.0 - 1e-10;
	  while (high - low > tol) {
		   NV mid = low + (high - low) / 2.0;
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

	// Shared state filled by whichever input branch runs
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
	NV tie_adj  = rank_and_count_ties(ri, valid_n, &has_ties);
	// 7. Aggregate Sum of Ranks AND Actual Values by Group
	NV *restrict group_rank_sums = (NV *)safecalloc(k, sizeof(NV));
	NV *restrict group_val_sums  = (NV *)safecalloc(k, sizeof(NV)); // For Mean
	size_t *restrict group_counts    = (size_t *)safecalloc(k, sizeof(size_t));
	for (size_t i = 0; i < valid_n; i++) {
		size_t g_id = ri[i].idx;
		group_rank_sums[g_id] += ri[i].rank;
		group_val_sums[g_id]  += ri[i].val;
		group_counts[g_id]++;
	}
	// 8. Calculate STATISTIC
	NV stat_base = 0.0;
	for (size_t i = 0; i < k; i++) {
	  if (group_counts[i] > 0)
		   stat_base += (group_rank_sums[i] * group_rank_sums[i])
						/ (NV)group_counts[i];
	}
	NV n_d  = (NV)valid_n;
	NV stat = (12.0 * stat_base / (n_d * (n_d + 1.0))) - 3.0 * (n_d + 1.0);
	if (tie_adj > 0.0) {
	  NV tie_denom = 1.0 - (tie_adj / (n_d * n_d * n_d - n_d));
	  stat /= tie_denom;
	}
	int    df    = (int)k - 1;
	NV p_val = get_p_value(stat, df);
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
		   NV mean = group_val_sums[i] / (NV)group_counts[i];
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
	NV ratio = 1.0, conf_level = 0.95;
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
	NV mean_x = 0.0, M2_x = 0.0;
	size_t nx = 0;
	for (size_t i = 0; i < nx_raw; i++) {
		SV** restrict tv = av_fetch(x_av, i, 0);
		if (tv && SvOK(*tv) && looks_like_number(*tv)) {
			NV val = SvNV(*tv);
			if (!isnan(val) && isfinite(val)) {
				nx++;
				NV delta = val - mean_x;
				mean_x += delta / nx;
				M2_x += delta * (val - mean_x);
			}
		}
	}

	NV mean_y = 0.0, M2_y = 0.0;
	size_t ny = 0;
	for (size_t i = 0; i < ny_raw; i++) {
		SV** restrict tv = av_fetch(y_av, i, 0);
		if (tv && SvOK(*tv) && looks_like_number(*tv)) {
			NV val = SvNV(*tv);
			if (!isnan(val) && isfinite(val)) {
				ny++;
				NV delta = val - mean_y;
				mean_y += delta / ny;
				M2_y += delta * (val - mean_y);
			}
		}
	}

	if (nx < 2) croak("not enough 'x' observations");
	if (ny < 2) croak("not enough 'y' observations");

	NV df_x = (NV)(nx - 1);
	NV df_y = (NV)(ny - 1);
	NV var_x = M2_x / df_x;
	NV var_y = M2_y / df_y;
	if (var_y == 0.0) croak("var_test: variance of 'y' is zero (cannot divide by zero)");
	// --- Statistics Math ---
	NV estimate = var_x / var_y;
	NV statistic = estimate / ratio;
	NV p_val = pf(statistic, df_x, df_y);
	NV ci_lower = 0.0, ci_upper = INFINITY;
	if (strcmp(alternative, "less") == 0) {
	  ci_upper = estimate / qf_bisection(1.0 - conf_level, df_x, df_y);
	} else if (strcmp(alternative, "greater") == 0) {
	  p_val = 1.0 - p_val;
	  ci_lower = estimate / qf_bisection(conf_level, df_x, df_y);
	} else {
	  // two.sided
	  NV p1 = p_val;
	  NV p2 = 1.0 - p_val;
	  p_val = 2.0 * (p1 < p2 ? p1 : p2);
	  NV beta = (1.0 - conf_level) / 2.0;
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
				 // Partial Fisher-Yates on the index array
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
	NV mean = 0.0, sd = 1.0; /*defaults*/
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
			   NV x_val = (elem && *elem) ? SvNV(*elem) : NAN;
			   NV res = c_dnorm(x_val, mean, sd, give_log);
			   av_store(result_av, i, newSVnv(res));
		   }
	  }
	  RETVAL = newRV_noinc((SV*)result_av);
	} else {
	  // x is a single numeric scalar
	  NV x_val = SvNV(x_sv);
	  NV res = c_dnorm(x_val, mean, sd, give_log);
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
		// 3. Check if this row key exists in the secondary hash ($i)
		HE *restrict i_fetch_he = hv_fetch_ent(i_hv, row_key_sv, 0, 0);
		if (i_fetch_he) {
			SV *restrict i_row_sv = HeVAL(i_fetch_he);
			// 4. Ensure $h->{row} is a Hash and $i->{row} is a valid reference
			if (SvROK(h_row_sv) && SvTYPE(SvRV(h_row_sv)) == SVt_PVHV && SvROK(i_row_sv)) {
				HV *restrict h_row_hv = (HV *)SvRV(h_row_sv);
				/* Case A: $i->{row} is a Hash Reference */
				if (SvTYPE(SvRV(i_row_sv)) == SVt_PVHV) {
					HV *restrict i_row_hv = (HV *)SvRV(i_row_sv);
					HE *restrict i_entry;
					hv_iterinit(i_row_hv);
					while ((i_entry = hv_iternext(i_row_hv))) {
						SV *restrict col_key_sv = hv_iterkeysv(i_entry);
						SV *restrict col_val    = hv_iterval(i_row_hv, i_entry);
						hv_store_ent(h_row_hv, col_key_sv, SvREFCNT_inc(col_val), 0);
					}
				} else if (SvTYPE(SvRV(i_row_sv)) == SVt_PVAV) {
					// Case B: $i->{row} is an Array Reference
					AV *restrict i_row_av = (AV *)SvRV(i_row_sv);
					// av_len returns the top index (length - 1)
					SSize_t top_idx = av_len(i_row_av); 
					// Iterate through the array in chunks of 2 (key-value pairs)
					for (SSize_t idx = 0; idx < top_idx; idx += 2) {
						SV **restrict key_svp = av_fetch(i_row_av, idx, 0);
						SV **restrict val_svp = av_fetch(i_row_av, idx + 1, 0);
						// Ensure both the key and value exist in the array
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
	short int target_root_mode = 0; // 1 = Hash, 2 = Array
	short int i_root_mode = 0;      // 1 = Hash, 2 = Array
	short int target_inner_mode = 0; // 0 = Unknown, 1 = Hash, 2 = Array
CODE:
	// 1. Validate inputs (Allow both Hash and Array references at the root)
	if (!SvROK(h_ref) || (SvTYPE(SvRV(h_ref)) != SVt_PVHV && SvTYPE(SvRV(h_ref)) != SVt_PVAV)) {
		croak("1st argument to add_data must be a hash or array reference");
	}
	if (!SvROK(i_ref) || (SvTYPE(SvRV(i_ref)) != SVt_PVHV && SvTYPE(SvRV(i_ref)) != SVt_PVAV)) {
		croak("2nd argument to add_data must be a hash or array reference");
	}
	target_root_mode = (SvTYPE(SvRV(h_ref)) == SVt_PVHV) ? 1 : 2;
	i_root_mode      = (SvTYPE(SvRV(i_ref)) == SVt_PVHV) ? 1 : 2;
	// Probe h_ref for inner structure
	if (target_root_mode == 1) {
		HV *restrict h_hv = (HV *)SvRV(h_ref);
		if (HvKEYS(h_hv) > 0) {
			HE **restrict probe_array = HvARRAY(h_hv);
			STRLEN probe_max = HvMAX(h_hv);
			for (STRLEN p_idx = 0; p_idx <= probe_max && target_inner_mode == 0; p_idx++) {
				for (HE *restrict p_entry = probe_array[p_idx]; p_entry && target_inner_mode == 0; p_entry = HeNEXT(p_entry)) {
					SV *restrict val = HeVAL(p_entry);
					if (SvROK(val)) {
						if (SvTYPE(SvRV(val)) == SVt_PVHV) target_inner_mode = 1;
						else if (SvTYPE(SvRV(val)) == SVt_PVAV) target_inner_mode = 2;
					}
				}
			}
		}
	} else {
		AV *restrict h_av = (AV *)SvRV(h_ref);
		SSize_t top = av_len(h_av);
		for (SSize_t p_idx = 0; p_idx <= top && target_inner_mode == 0; p_idx++) {
			SV **restrict svp = av_fetch(h_av, p_idx, 0);
			if (svp && *svp && SvROK(*svp)) {
				if (SvTYPE(SvRV(*svp)) == SVt_PVHV) target_inner_mode = 1;
				else if (SvTYPE(SvRV(*svp)) == SVt_PVAV) target_inner_mode = 2;
			}
		}
	}
	// Target is empty, infer intent from source hash/array
	if (target_inner_mode == 0) {
		if (i_root_mode == 1) {
			HV *restrict i_hv = (HV *)SvRV(i_ref);
			if (HvKEYS(i_hv) > 0) {
				HE **restrict probe_array = HvARRAY(i_hv);
				STRLEN probe_max = HvMAX(i_hv);
				for (STRLEN p_idx = 0; p_idx <= probe_max && target_inner_mode == 0; p_idx++) {
					for (HE *restrict p_entry = probe_array[p_idx]; p_entry && target_inner_mode == 0; p_entry = HeNEXT(p_entry)) {
						SV *restrict val = HeVAL(p_entry);
						if (SvROK(val)) {
							if (SvTYPE(SvRV(val)) == SVt_PVHV) target_inner_mode = 1;
							else if (SvTYPE(SvRV(val)) == SVt_PVAV) target_inner_mode = 2;
						}
					}
				}
			}
		} else {
			AV *restrict i_av = (AV *)SvRV(i_ref);
			SSize_t top = av_len(i_av);
			for (SSize_t p_idx = 0; p_idx <= top && target_inner_mode == 0; p_idx++) {
				SV **restrict svp = av_fetch(i_av, p_idx, 0);
				if (svp && *svp && SvROK(*svp)) {
					if (SvTYPE(SvRV(*svp)) == SVt_PVHV) target_inner_mode = 1;
					else if (SvTYPE(SvRV(*svp)) == SVt_PVAV) target_inner_mode = 2;
				}
			}
		}
	}
	if (target_inner_mode == 0) { target_inner_mode = 1; }
	// 2. Iterate through the SECONDARY structure ($i) using a unified loop
	SSize_t i_idx = 0, i_top = -1;
	HV *restrict i_hv = NULL;
	AV *restrict i_av = NULL;
	if (i_root_mode == 1) {
		i_hv = (HV *)SvRV(i_ref);
		hv_iterinit(i_hv);
	} else {
		i_av = (AV *)SvRV(i_ref);
		i_top = av_len(i_av);
	}
	while (1) {
		SV *restrict row_key_sv = NULL;
		SV *restrict i_row_sv   = NULL;
		SSize_t current_idx = 0;
		if (i_root_mode == 1) {
			HE *restrict i_entry = hv_iternext(i_hv);
			if (!i_entry) break;
			row_key_sv = hv_iterkeysv(i_entry);
			i_row_sv   = hv_iterval(i_hv, i_entry);
			// Prep integer index in case target is an Array (Suppress warnings for non-numeric string keys)
			current_idx = looks_like_number(row_key_sv) ? SvIV(row_key_sv) : -1; 
		} else {
			if (i_idx > i_top) break;
			current_idx = i_idx++;
			SV **restrict svp = av_fetch(i_av, current_idx, 0);
			if (!svp || !*svp) continue;
			i_row_sv = *svp;
			// Prep string key in case target is a Hash
			row_key_sv = sv_2mortal(newSViv(current_idx)); 
		}
		if (SvROK(i_row_sv)) {
			SV *restrict h_row_sv   = NULL;
			HV *restrict h_row_hv   = NULL;
			AV *restrict h_row_av   = NULL;
			// 3. Fetch from $h
			if (target_root_mode == 1) {
				HE *restrict h_fetch_he = hv_fetch_ent((HV *)SvRV(h_ref), row_key_sv, 0, 0);
				if (h_fetch_he) h_row_sv = HeVAL(h_fetch_he);
			} else {
				if (current_idx >= 0) {
					SV **restrict h_fetch_svp = av_fetch((AV *)SvRV(h_ref), current_idx, 0);
					if (h_fetch_svp && *h_fetch_svp) h_row_sv = *h_fetch_svp;
				}
			}
			if (h_row_sv && SvROK(h_row_sv)) {
				if (SvTYPE(SvRV(h_row_sv)) == SVt_PVHV) {
					h_row_hv = (HV *)SvRV(h_row_sv);
				} else if (SvTYPE(SvRV(h_row_sv)) == SVt_PVAV) {
					h_row_av = (AV *)SvRV(h_row_sv);
				}
			}
			// 4. Row DOES NOT exist (or is incompatible type): Create it matching target_inner_mode
			if (!h_row_hv && !h_row_av) {
				if (target_inner_mode == 2) {
					h_row_av = newAV();
					h_row_sv = newRV_noinc((SV *)h_row_av);
				} else {
					h_row_hv = newHV();
					h_row_sv = newRV_noinc((SV *)h_row_hv);
				}
				if (target_root_mode == 1) {
					hv_store_ent((HV *)SvRV(h_ref), row_key_sv, h_row_sv, 0);
				} else {
					if (current_idx >= 0) {
						av_store((AV *)SvRV(h_ref), current_idx, h_row_sv);
					}
				}
			}
			// 5. Merge data across potentially mismatched inner structures
			if (h_row_hv) {
				if (SvTYPE(SvRV(i_row_sv)) == SVt_PVHV) {
					// Hash into Hash (Direct copy)
					HV *restrict i_inner_hv = (HV *)SvRV(i_row_sv);
					HE *restrict i_inner_entry;
					hv_iterinit(i_inner_hv);
					while ((i_inner_entry = hv_iternext(i_inner_hv))) {
						SV *restrict col_key_sv = hv_iterkeysv(i_inner_entry);
						SV *restrict col_val    = hv_iterval(i_inner_hv, i_inner_entry);
						hv_store_ent(h_row_hv, col_key_sv, SvREFCNT_inc(col_val), 0);
					}
				} else if (SvTYPE(SvRV(i_row_sv)) == SVt_PVAV) {
					// Array into Hash (Read pairs)
					AV *restrict i_inner_av = (AV *)SvRV(i_row_sv);
					SSize_t inner_top_idx = av_len(i_inner_av);
					for (SSize_t idx = 0; idx < inner_top_idx; idx += 2) {
						SV **restrict key_svp = av_fetch(i_inner_av, idx, 0);
						SV **restrict val_svp = av_fetch(i_inner_av, idx + 1, 0);
						if (key_svp && *key_svp && val_svp) {
							SV *restrict val_to_store = *val_svp ? *val_svp : &PL_sv_undef;
							hv_store_ent(h_row_hv, *key_svp, SvREFCNT_inc(val_to_store), 0);
						}
					}
				}
			} else if (h_row_av) {
				if (SvTYPE(SvRV(i_row_sv)) == SVt_PVAV) {
					// Array into Array (Direct push with non-null pointer assurance)
					AV *restrict i_inner_av = (AV *)SvRV(i_row_sv);
					SSize_t inner_top_idx = av_len(i_inner_av);
					for (SSize_t idx = 0; idx <= inner_top_idx; ++idx) {
						SV **restrict val_svp = av_fetch(i_inner_av, idx, 0);
						if (val_svp) {
							SV *restrict val_to_push = *val_svp ? *val_svp : &PL_sv_undef;
							SV *restrict sv_inc = SvREFCNT_inc(val_to_push);
							if (sv_inc) {
								av_push(h_row_av, sv_inc);
							}
						}
					}
				} else if (SvTYPE(SvRV(i_row_sv)) == SVt_PVHV) {
					// Hash into Array (Flatten and push pairs with non-null pointer assurance)
					HV *restrict i_inner_hv = (HV *)SvRV(i_row_sv);
					HE *restrict i_inner_entry;
					hv_iterinit(i_inner_hv);
					while ((i_inner_entry = hv_iternext(i_inner_hv))) {
						SV *restrict col_key_sv = hv_iterkeysv(i_inner_entry);
						SV *restrict col_val    = hv_iterval(i_inner_hv, i_inner_entry);
						if (col_key_sv && col_val) {
							SV *restrict sv_key_inc = SvREFCNT_inc(col_key_sv);
							SV *restrict sv_val_inc = SvREFCNT_inc(col_val);
							if (sv_key_inc && sv_val_inc) {
								av_push(h_row_av, sv_key_inc);
								av_push(h_row_av, sv_val_inc);
							}
						}
					}
				}
			}
		}
	}

SV* value_counts(...)
PREINIT:
	HV*restrict counts_hv;
	SV*restrict arg1;
CODE:
// 1. CHECK FOR DATA FIRST to prevent memory leaks if we die
	if (items == 0) {
	  croak("value_counts: no data provided. At least one argument is required.");
	}
	arg1 = ST(0);
	if (!SvOK(arg1)) {
	  croak("First argument to value_counts is NOT defined");
	}
	// 2. Allocate memory only after we know we are proceeding
	counts_hv = newHV();
	// CASE 1: Flattened Array (or single scalar)
	if (!SvROK(arg1)) {
	  for (unsigned i = 0; i < items; i++) {
		   increment_count(aTHX_ counts_hv, ST(i));
	  }
	} else {// CASE 2: Array Reference
		SV*restrict rv = SvRV(arg1);
		if (SvTYPE(rv) == SVt_PVAV) {
			AV*restrict av = (AV*)rv;
			SSize_t len = av_len(av) + 1;
			for (unsigned i = 0; i < len; i++) {
				SV**restrict valp = av_fetch(av, i, 0);
				if (valp) increment_count(aTHX_ counts_hv, *valp);
			}
		} else if (SvTYPE(rv) == SVt_PVHV) { // CASES 3, 4, 5: Hash Reference
			HV*restrict hv = (HV*)rv;
		// CASES 4 & 5: Nested Structure requiring a 2nd Argument
			if (items > 1) {
				SV*restrict arg2 = ST(1);
				STRLEN klen;
				const char*restrict key = SvPV(arg2, klen); 
				// DataFrame-style Column-Oriented data check
				SV**restrict col_svp = hv_fetch(hv, key, klen, 0);
				if (col_svp && SvROK(*col_svp) && SvTYPE(SvRV(*col_svp)) == SVt_PVAV) {
					AV*restrict av = (AV*)SvRV(*col_svp);
					SSize_t len = av_len(av) + 1;
					for (unsigned i = 0; i < len; i++) {
						SV**restrict valp = av_fetch(av, i, 0);
						if (valp) increment_count(aTHX_ counts_hv, *valp);
					}
				} else {
					// Fallback: Row-Oriented nested structure
					HE*restrict he;
					hv_iterinit(hv);
					while ((he = hv_iternext(hv))) {
						SV*restrict inner_sv = HeVAL(he);
						if (SvROK(inner_sv)) {
							 SV*restrict inner_rv = SvRV(inner_sv);
							 if (SvTYPE(inner_rv) == SVt_PVHV) {// CASE 5: Hash of Hashes
								 HV*restrict inner_hv = (HV*)inner_rv;
								 SV**restrict valp = hv_fetch(inner_hv, key, klen, 0);
								 if (valp) increment_count(aTHX_ counts_hv, *valp);
							 } else if (SvTYPE(inner_rv) == SVt_PVAV) {// CASE 4: Hash of Arrays (Row-Oriented)
								if (looks_like_number(arg2)) {
									AV*restrict inner_av = (AV*)inner_rv;
									SSize_t idx = SvIV(arg2); 
									SV**restrict valp = av_fetch(inner_av, idx, 0);
									if (valp) increment_count(aTHX_ counts_hv, *valp);
								}
							}
						}
					}
				}
			} else { // CASE 3: Hash Reference (No 2nd argument)
				 HE*restrict he;
				 hv_iterinit(hv);
				 while ((he = hv_iternext(hv))) {
					 SV*restrict val = HeVAL(he);
					 if (SvROK(val)) {// --- SAFETY CHECK
						 SV*restrict inner_rv = SvRV(val);
						 // If it's a Hash of Arrays, count ALL elements in the inner arrays
						 if (SvTYPE(inner_rv) == SVt_PVAV) {
							 AV*restrict inner_av = (AV*)inner_rv;
							 SSize_t len = av_len(inner_av) + 1;
							 for (unsigned i = 0; i < len; i++) {
								 SV**restrict valp = av_fetch(inner_av, i, 0);
								 if (valp) increment_count(aTHX_ counts_hv, *valp);
							 }
						 } else if (SvTYPE(inner_rv) == SVt_PVHV) {
						 // If it's a Hash of Hashes, count ALL elements across all inner keys
							 HV*restrict inner_hv = (HV*)inner_rv;
							 HE*restrict inner_he;
							 hv_iterinit(inner_hv);
							 while ((inner_he = hv_iternext(inner_hv))) {
								 SV*restrict inner_val = HeVAL(inner_he);
								 increment_count(aTHX_ counts_hv, inner_val);
							 }
						 } else { /* Unrecognized nested reference type */
							 SvREFCNT_dec((SV*)counts_hv);
							 croak("value_counts: Unsupported nested reference type.");
						 }
					 } else {
						 /* Simple scalar value */
						 increment_count(aTHX_ counts_hv, val);
					 }
				 }
			}
		} else {
		/* Safely decrement the reference count of our hash before dying to prevent a leak */
			SvREFCNT_dec((SV*)counts_hv);
			croak("value_counts: Unsupported reference type.");
		}
	}
	RETVAL = newRV_noinc((SV*)counts_hv);
OUTPUT:
	RETVAL

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
	// Balance xsubpp's automatic sv_2mortal to prevent refcount dropping to -1
	RETVAL = SvREFCNT_inc(result_ref);
OUTPUT:
	RETVAL

SV* prcomp(...)
CODE:
{
	SV *restrict x_sv = NULL;
	bool retx = TRUE, center = TRUE, do_scale = FALSE;
	NV tol = -1.0;
	long rank_opt = -1;
	unsigned int arg_idx = 0;
	// 1. Shift positional 'x' argument if provided
	if (arg_idx < items && SvROK(ST(arg_idx))) {
	  int t = SvTYPE(SvRV(ST(arg_idx)));
	  if (t == SVt_PVAV || t == SVt_PVHV) {
		   x_sv = ST(arg_idx);
		   arg_idx++;
	  }
	}
	// 2. Parse named arguments
	if ((items - arg_idx) % 2 != 0) croak("Usage: prcomp($data, key => value, ...)");
	for (; arg_idx < items; arg_idx += 2) {
	  const char *restrict key = SvPV_nolen(ST(arg_idx));
	  SV *restrict val = ST(arg_idx + 1);
	  if      (strEQ(key, "x"))      x_sv      = val;
	  else if (strEQ(key, "retx"))   retx      = SvTRUE(val);
	  else if (strEQ(key, "center")) center    = SvTRUE(val);
	  else if (strEQ(key, "scale"))  do_scale  = SvTRUE(val);
	  else if (strEQ(key, "tol"))    tol       = SvOK(val) ? SvNV(val) : -1.0;
	  else if (strEQ(key, "rank"))   rank_opt  = SvOK(val) ? (long)SvIV(val) : -1;
	  else croak("prcomp: unknown argument '%s'", key);
	}

	if (!x_sv || !SvROK(x_sv))
	  croak("prcomp: 'x' is a required argument and must be a reference");

	// 3. Detect Data Structure (AoA, HoA, HoH)
	bool is_aoa = FALSE, is_hoa = FALSE, is_hoh = FALSE;
	size_t n_raw = 0, p = 0;
	char **restrict colnames = NULL;
	SV *restrict ref = SvRV(x_sv);

	if (SvTYPE(ref) == SVt_PVAV) {
	  AV *restrict av = (AV*)ref;
	  n_raw = av_len(av) + 1;
	  if (n_raw > 0) {
		   SV **restrict first = av_fetch(av, 0, 0);
		   if (first && SvROK(*first) && SvTYPE(SvRV(*first)) == SVt_PVAV) {
			   is_aoa = TRUE;
			   p = av_len((AV*)SvRV(*first)) + 1;
		   } else croak("prcomp: Array reference must contain ArrayRefs (AoA)");
	  }
	} else if (SvTYPE(ref) == SVt_PVHV) {
	  HV *restrict hv = (HV*)ref;
	  if (hv_iterinit(hv) > 0) {
		   HE *restrict entry = hv_iternext(hv);
		   SV *restrict val = hv_iterval(hv, entry);
		   if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
			   is_hoa = TRUE;
			   n_raw = av_len((AV*)SvRV(val)) + 1;
		   } else if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
			   is_hoh = TRUE;
			   n_raw = hv_iterinit(hv);
		   } else croak("prcomp: Hash reference must contain ArrayRefs (HoA) or HashRefs (HoH)");
	  }
	}

	if (n_raw == 0 || (p == 0 && !is_hoa && !is_hoh)) croak("prcomp: input matrix is empty or has zero columns");

	// 4. Extract and Sort Column Names (for Hash inputs)
	if (is_hoh) {
		HV *restrict hv = (HV*)ref;
		hv_iterinit(hv);
		HE *restrict entry = hv_iternext(hv);
		HV *restrict inner = (HV*)SvRV(hv_iterval(hv, entry));
		p = hv_iterinit(inner);
		if (p == 0) croak("prcomp: inner hashes cannot be empty");

		colnames = (char**)safemalloc(p * sizeof(char*));
		size_t c = 0;
		while ((entry = hv_iternext(inner))) {
			colnames[c++] = savepv(SvPV_nolen(hv_iterkeysv(entry)));
		}
		qsort(colnames, p, sizeof(char*), cmp_string_wt);
	} else if (is_hoa) {
		HV *restrict hv = (HV*)ref;
		p = hv_iterinit(hv);
		if (p == 0) croak("prcomp: input hash is empty");
		colnames = (char**)safemalloc(p * sizeof(char*));
		size_t c = 0;
		HE *restrict entry;
		while ((entry = hv_iternext(hv))) {
			colnames[c++] = savepv(SvPV_nolen(hv_iterkeysv(entry)));
		}
		qsort(colnames, p, sizeof(char*), cmp_string_wt);
	}
	// 5. Extract data & apply listwise deletion for NaNs
	NV *restrict X_mat = (NV*)safemalloc(n_raw * p * sizeof(NV));
	size_t n = 0;
	if (is_aoa) {
	  AV *restrict av = (AV*)ref;
	  for (size_t i = 0; i < n_raw; i++) {
		   SV **restrict row_sv = av_fetch(av, i, 0);
		   if (row_sv && SvROK(*row_sv) && SvTYPE(SvRV(*row_sv)) == SVt_PVAV) {
			   AV *restrict row_av = (AV*)SvRV(*row_sv);
			   bool row_ok = TRUE;
			   for (size_t j = 0; j < p; j++) {
				   SV **restrict cell_sv = av_fetch(row_av, j, 0);
				   if (cell_sv && SvOK(*cell_sv) && looks_like_number(*cell_sv)) {
					   NV v = SvNV(*cell_sv);
					   if (!isfinite(v)) row_ok = FALSE;
					   else X_mat[n * p + j] = v;
				   } else row_ok = FALSE;
			   }
			   if (row_ok) n++;
		   }
	  }
	} else if (is_hoa) {
		HV *restrict hv = (HV*)ref;
		AV **restrict col_arrays = (AV**)safemalloc(p * sizeof(AV*));
		for (size_t j = 0; j < p; j++) {
			SV **restrict val = hv_fetch(hv, colnames[j], strlen(colnames[j]), 0);
			col_arrays[j] = (AV*)SvRV(*val);
		}
		for (size_t i = 0; i < n_raw; i++) {
			bool row_ok = TRUE;
			for (size_t j = 0; j < p; j++) {
				SV **restrict cell = av_fetch(col_arrays[j], i, 0);
				if (cell && SvOK(*cell) && looks_like_number(*cell)) {
				  NV v = SvNV(*cell);
				  if (!isfinite(v)) row_ok = FALSE;
				  else X_mat[n * p + j] = v;
				} else row_ok = FALSE;
			}
			if (row_ok) n++;
		}
		Safefree(col_arrays);
	} else if (is_hoh) {
		HV *restrict hv = (HV*)ref;
		hv_iterinit(hv);
		HE *restrict entry;
		while ((entry = hv_iternext(hv))) {
			HV *restrict row_hv = (HV*)SvRV(hv_iterval(hv, entry));
			bool row_ok = TRUE;
			for (size_t j = 0; j < p; j++) {
				SV **restrict cell = hv_fetch(row_hv, colnames[j], strlen(colnames[j]), 0);
				if (cell && SvOK(*cell) && looks_like_number(*cell)) {
				  NV v = SvNV(*cell);
				  if (!isfinite(v)) row_ok = FALSE;
				  else X_mat[n * p + j] = v;
				} else row_ok = FALSE;
			}
			if (row_ok) n++;
		}
	}
	if (n == 0) {
	  if (colnames) {
		   for (size_t i = 0; i < p; i++) Safefree(colnames[i]);
		   Safefree(colnames);
	  }
	  Safefree(X_mat);
	  croak("prcomp: 0 valid observations after listwise NA deletion");
	}
	// 6. Center and Scale
	NV *restrict cen_vec = (NV*)safecalloc(p, sizeof(NV));
	NV *restrict sc_vec  = (NV*)safecalloc(p, sizeof(NV));
	for (size_t j = 0; j < p; j++) {
	  NV col_sum = 0.0;
	  for (size_t i = 0; i < n; i++) col_sum += X_mat[i * p + j];
	  if (center) {
		   cen_vec[j] = col_sum / n;
		   for (size_t i = 0; i < n; i++) X_mat[i * p + j] -= cen_vec[j];
	  }
	  if (do_scale) {
		   NV sum_sq = 0.0;
		   for (size_t i = 0; i < n; i++) {
			   NV val = X_mat[i * p + j] - (center ? 0 : (col_sum / n));
			   sum_sq += val * val;
		   }
		   sc_vec[j] = (n > 1) ? sqrt(sum_sq / (n - 1)) : 0.0;
		   if (sc_vec[j] <= 1e-15) {
			   Safefree(X_mat); Safefree(cen_vec); Safefree(sc_vec);
			   if (colnames) { for (size_t k = 0; k < p; k++) Safefree(colnames[k]); Safefree(colnames); }
			   croak("prcomp: cannot rescale a constant/zero column to unit variance");
		   }
		   for (size_t i = 0; i < n; i++) X_mat[i * p + j] /= sc_vec[j];
	  }
	}
	// 7. Construct Covariance Matrix X^T X
	NV *restrict XtX = (NV*)safecalloc(p * p, sizeof(NV));
	for (size_t i = 0; i < n; i++) {
	  for (size_t j = 0; j < p; j++) {
		   for (size_t k = j; k < p; k++) {
			   XtX[j * p + k] += X_mat[i * p + j] * X_mat[i * p + k];
		   }
	  }
	}
	// Mirror the symmetric lower triangle
	for (size_t j = 0; j < p; j++) {
	  for (size_t k = 0; k < j; k++) {
		   XtX[j * p + k] = XtX[k * p + j];
	  }
	}
	// 8. Jacobi Eigen Decomposition
	NV *restrict eigen_val = (NV*)safemalloc(p * sizeof(NV));
	NV *restrict eigen_vec = (NV*)safemalloc(p * p * sizeof(NV));
	jacobi_eigen(XtX, p, eigen_val, eigen_vec);
	// 9. Calculate singular values (sdev) & handle dimensions (rank/tol)
	size_t k_cols = (n < p) ? n : p;
	if (rank_opt > 0 && rank_opt < (long)k_cols) k_cols = (size_t)rank_opt;
	NV *restrict sdev = (NV*)safemalloc(k_cols * sizeof(NV));
	NV n_adj = (n > 1) ? (NV)(n - 1) : 1.0;
	for (size_t j = 0; j < k_cols; j++) {
	  NV e_val = eigen_val[j];
	  if (e_val < 0.0) e_val = 0.0; // clamp floating point inaccuracy
	  sdev[j] = sqrt(e_val / n_adj);
	}
	if (tol >= 0.0) {
	  size_t rank_est = 0;
	  NV threshold = sdev[0] * tol;
	  for (size_t j = 0; j < k_cols; j++) {
		   if (sdev[j] > threshold) rank_est++;
	  }
	  if (rank_est < k_cols) k_cols = rank_est;
	}
	// 10. Build Return Hash
	HV *restrict res_hv = newHV();
	AV *restrict sdev_av = newAV();
	for (size_t j = 0; j < k_cols; j++) av_push(sdev_av, newSVnv(sdev[j]));
	hv_stores(res_hv, "sdev", newRV_noinc((SV*)sdev_av));
	AV *restrict rot_av = newAV();
	for (size_t j = 0; j < p; j++) {
	  AV *restrict row_rot = newAV();
	  for (size_t m = 0; m < k_cols; m++) {
		   av_push(row_rot, newSVnv(eigen_vec[j * p + m]));
	  }
	  av_push(rot_av, newRV_noinc((SV*)row_rot));
	}
	hv_stores(res_hv, "rotation", newRV_noinc((SV*)rot_av));
	if (retx) {
	  AV *restrict x_ret_av = newAV();
	  for (size_t i = 0; i < n; i++) {
		   AV *restrict row_x = newAV();
		   for (size_t m = 0; m < k_cols; m++) {
			   NV x_rot_val = 0.0;
			   for (size_t c = 0; c < p; c++) {
				   x_rot_val += X_mat[i * p + c] * eigen_vec[c * p + m];
			   }
			   av_push(row_x, newSVnv(x_rot_val));
		   }
		   av_push(x_ret_av, newRV_noinc((SV*)row_x));
	  }
	  hv_stores(res_hv, "x", newRV_noinc((SV*)x_ret_av));
	}
	if (colnames) {
	  AV *restrict names_av = newAV();
	  for (size_t j = 0; j < p; j++) {
		   av_push(names_av, newSVpv(colnames[j], 0));
	  }
	  hv_stores(res_hv, "varnames", newRV_noinc((SV*)names_av));
	}
	if (center) {
	  AV *restrict c_av = newAV();
	  for (size_t j = 0; j < p; j++) av_push(c_av, newSVnv(cen_vec[j]));
	  hv_stores(res_hv, "center", newRV_noinc((SV*)c_av));
	} else {
	  hv_stores(res_hv, "center", newSVsv(&PL_sv_no));
	}
	if (do_scale) {
	  AV *restrict sc_av = newAV();
	  for (size_t j = 0; j < p; j++) av_push(sc_av, newSVnv(sc_vec[j]));
	  hv_stores(res_hv, "scale", newRV_noinc((SV*)sc_av));
	} else {
	  hv_stores(res_hv, "scale", newSVsv(&PL_sv_no));
	}
	// Cleanup
	if (colnames) {
	  for (size_t i = 0; i < p; i++) Safefree(colnames[i]);
	  Safefree(colnames);
	}
	Safefree(X_mat); Safefree(cen_vec); Safefree(sc_vec);
	Safefree(XtX); Safefree(eigen_val); Safefree(eigen_vec); Safefree(sdev);

	RETVAL = newRV_noinc((SV*)res_hv);
}
OUTPUT:
	RETVAL

SV *transpose(input_ref)
	SV *input_ref
PREINIT:
	svtype  ref_type;
	SV     *restrict retval_sv;
CODE:
	SvGETMAGIC(input_ref);
	if (!SvROK(input_ref))
	  croak("Stats::LikeR::transpose: Input must be a hash ref or array ref");
	ref_type = SvTYPE(SvRV(input_ref));
	if (ref_type == SVt_PVHV) {// ── Hash-of-Hashes
		HV *restrict in_hv  = (HV *)SvRV(input_ref);
		HV *restrict out_hv = newHV();
		HE *restrict he_row, *restrict he_col, *restrict out_inner_he;
		retval_sv = sv_2mortal(newRV_noinc((SV *)out_hv));
		hv_iterinit(in_hv);
		while ((he_row = hv_iternext(in_hv))) {
			SV *restrict row_key_sv  = hv_iterkeysv(he_row);
			SV *restrict row_val     = hv_iterval(in_hv, he_row);
			HV *restrict in_inner_hv;
			SvGETMAGIC(row_val);

			if (!SvROK(row_val) || SvTYPE(SvRV(row_val)) != SVt_PVHV)
				 croak("Stats::LikeR::transpose: Hash mode – inner element is not a hash ref");
			in_inner_hv = (HV *)SvRV(row_val);
			hv_iterinit(in_inner_hv);
			while ((he_col = hv_iternext(in_inner_hv))) {
				SV *restrict col_key_sv = hv_iterkeysv(he_col);
				SV *restrict val        = hv_iterval(in_inner_hv, he_col);
				HV *restrict out_inner_hv;
				SV *restrict inner_ref;
				SvGETMAGIC(val);
				out_inner_he = hv_fetch_ent(out_hv, col_key_sv, 0, 0);
				if (out_inner_he) {
				  inner_ref = HeVAL(out_inner_he);
				  if (!SvROK(inner_ref) || SvTYPE(SvRV(inner_ref)) != SVt_PVHV)
						croak("Stats::LikeR::transpose: Internal error – output structure corrupted");
				  out_inner_hv = (HV *)SvRV(inner_ref);
				} else {
				  out_inner_hv = newHV();
				  inner_ref    = newRV_noinc((SV *)out_inner_hv);
				  if (!hv_store_ent(out_hv, col_key_sv, inner_ref, 0)) {
						SvREFCNT_dec(inner_ref);
						croak("Stats::LikeR::transpose: Failed to allocate inner hash");
				  }
				}
				SvREFCNT_inc(val);
				if (!hv_store_ent(out_inner_hv, row_key_sv, val, 0)) {
				  SvREFCNT_dec(val);
				  croak("Stats::LikeR::transpose: Failed to store transposed value");
				}
			}
		}
	} else if (ref_type == SVt_PVAV) { // Array-of-Arrays
		AV     *restrict in_av  = (AV *)SvRV(input_ref);
		AV     *restrict out_av = newAV();
		SSize_t nrows  = av_len(in_av) + 1;
		SSize_t ncols  = 0;
		retval_sv = sv_2mortal(newRV_noinc((SV *)out_av));
		if (nrows > 0) {// Pass 1: validate all rows; fix ncols from row 0
			{
				 SV **restrict elem = av_fetch(in_av, 0, 0);
				 if (!elem || !*elem)
					  croak("Stats::LikeR::transpose: Array mode – row 0 is missing");
				 SvGETMAGIC(*elem);
				 if (!SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVAV)
					  croak("Stats::LikeR::transpose: Array mode – row 0 is not an array ref");
				 ncols = av_len((AV *)SvRV(*elem)) + 1;
			}
			for (SSize_t i = 1; i < nrows; i++) {
				 SV     **restrict elem      = av_fetch(in_av, i, 0);
				 SSize_t  row_ncols;
				 if (!elem || !*elem)
					  croak("Stats::LikeR::transpose: Array mode – row %d is missing", (int)i);
				 SvGETMAGIC(*elem);
				 if (!SvROK(*elem) || SvTYPE(SvRV(*elem)) != SVt_PVAV)
					  croak("Stats::LikeR::transpose: Array mode – row %d is not an array ref", (int)i);
				 row_ncols = av_len((AV *)SvRV(*elem)) + 1;
				 if (row_ncols != ncols)
					  croak("Stats::LikeR::transpose: Array mode – ragged array: "
							"row 0 has %d cols, row %d has %d",
							(int)ncols, (int)i, (int)row_ncols);
			}
			// Pass 2: output[j][i] = input[i][j]
			if (ncols > 0) {
				av_extend(out_av, ncols - 1);
				for (SSize_t j = 0; j < ncols; j++) {
					AV *restrict out_col_av = newAV();
					SV *restrict col_ref    = newRV_noinc((SV *)out_col_av);
					if (!av_store(out_av, j, col_ref)) {
						SvREFCNT_dec(col_ref);
						croak("Stats::LikeR::transpose: Array mode – "
								"failed to allocate output column %d", (int)j);
					}
					av_extend(out_col_av, nrows - 1);
					for (SSize_t i = 0; i < nrows; i++) {
						SV **restrict elem = av_fetch(in_av, i, 0);
						if (elem && *elem) {
							SvGETMAGIC(*elem); 
						}
						AV *restrict in_row_av = (AV *)SvRV(*elem);
						SV **restrict val_ptr   = av_fetch(in_row_av, j, 0);
						SV  *restrict val       = (val_ptr && *val_ptr) ? *val_ptr : &PL_sv_undef;
						SvGETMAGIC(val);
						SvREFCNT_inc(val);
						if (!av_store(out_col_av, i, val)) {
							SvREFCNT_dec(val);
							croak("Stats::LikeR::transpose: Array mode – "
									 "failed to store [%d][%d]", (int)j, (int)i);
						}
					}
				}
			}
		}
	} else { // Unsupported
	  croak("Stats::LikeR::transpose: Input must be a hash ref or array ref");
	}
	RETVAL = SvREFCNT_inc(retval_sv);
OUTPUT:
	RETVAL
