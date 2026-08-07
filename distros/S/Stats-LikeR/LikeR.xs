#ifndef _GNU_SOURCE
#define _GNU_SOURCE // glibc / Linux
#endif
#ifndef __EXTENSIONS__
#define __EXTENSIONS__ 1 // Solaris/illumos: expose off64_t, sigjmp_buf under -std=c99
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
/* croak() with an NV argument: croak() carries a printf format attribute, but
the compiler's format checker doesn't know the "Q" length modifier that NVgf
expands to on a quadmath build, so every NV-bearing croak() draws a bogus
-Wformat / -Wformat-extra-args pair there (harmless, but it buries the real
warnings). The format is read by Perl's own formatter, not the C library, and
that handles NVgf on every build, so route those messages through vcroak(),
which has no format attribute. -Wformat stays useful everywhere else. */
static void croak_nv(const char *pat, ...) __attribute__noreturn__;
static void croak_nv(const char *pat, ...)
{
	dTHX;
	va_list args;
	va_start(args, pat);
	vcroak(pat, &args); // noreturn; no va_end needed
}
/* Format a single NV with my_snprintf(). my_snprintf() carries a format
attribute of its own, so an NVgf format written at the call site draws the same
bogus warning pair described above; taking the format as an ordinary argument
keeps the checker out of it. my_snprintf() is the portable spelling here --
plain snprintf() cannot print an NV on a quadmath build. */
static int snprintf_nv(char *buf, Size_t buflen, const char *fmt, NV x)
{
	return my_snprintf(buf, buflen, fmt, x);
}
/*
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
sample__mix64(void){
	uint64_t z = (sample__state += UINT64_C(0x9e3779b97f4a7c15));
	z = (z ^ (z >> 30)) * UINT64_C(0xbf58476d1ce4e5b9);
	z = (z ^ (z >> 27)) * UINT64_C(0x94d049bb133111eb);
	return z ^ (z >> 31);
}

// Helper function to increment the count for a given SV. * Skips NULL or Undefined values as requested
static void increment_count(pTHX_ HV* counts_hv, SV* val) {
	if (!val || !SvOK(val)) return; // Skip null pointers or undef (non-OK) values
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
/* Where the standard normal's lower tail stops being a number a double can
 * hold, and so the point past which this file stops asking erfc() for it.
 *
 * 0.5 * erfc(-x/sqrt(2)) reaches DBL_MIN at x = -37.5194 and its last
 * subnormal just past -38.4674; R's pnorm() returns a flat 0 below that, as
 * does scipy. erfc() takes and returns a double whatever perl's NV is, so
 * nothing it says out here can be trusted -- and on i386, where a double is
 * returned in an x87 register, what it says is not even 0: glibc spells
 * erfc()'s underflow case as a product of two 1e-300 constants, formed in
 * extended precision and handed back in st(0) still holding 1e-600. A perl
 * whose NV is a double rounds that away on return; a perl built
 * -Duselongdouble keeps it. glm's Wald p-value for |z| = 149 duly came back
 * as 1e-600 from a 32-bit long-double smoker (CPAN Testers, perl
 * 5.32.1-longdouble, i686-linux-ld) where every other build reported 0.
 * Stopping short of the call gives every build the same answer, which is
 * also R's and scipy's. */
#define PNORM_LOWER_ZERO (-38.4674)   /* R's own cutoff, nmath/pnorm.c */
NV approx_pnorm(NV x);                /* defined below, after the histogram code */

// C helper for the non-central T-distribution CDF: quadrature over the scaled
// chi density up to PNT_NORMAL_DF, an asymptotic form above it. Matches R's
// pt(..., ncp) without needing the non-central beta function.
/* Thresholds between exact_pnt()'s three regimes. Below PNT_LARGE_DF the chi
 * density is broad enough to integrate over its whole support; above it the
 * density is a narrow spike and the steps have to be packed around the mode.
 * 1e3 suits both: the support integral still holds ~2e-13 there, and the spike
 * integral needs df/2 > 500 for its Stirling series to be good to 4e-14. Past
 * PNT_NORMAL_DF no quadrature is worth running -- see the asymptotic form in
 * exact_pnt(). That second cut-off is R's, from nmath/pnt.c; the first has no
 * counterpart there, R using one series throughout. */
#define PNT_LARGE_DF 1.0e3
#define PNT_NORMAL_DF 4.0e5

/* Integer power by squaring, for the w = z^m substitution below: m is a small
 * integer, and pow() would neither be exact at z^4 nor as quick. */
static NV pow_uint(NV base, unsigned int e) {
	NV r = 1.0;
	while (e) {
		if (e & 1u) r *= base;
		base *= base;
		e >>= 1u;
	}
	return r;
}

/* Scaled chi log-density of W = sqrt(chi2_df / df) at its mode, w = 1:
 *
 *   log f(1) = log 2 + x log x - lgamma(x) - x,   x = df/2
 *
 * Evaluated as written, the three large terms cancel down to a result of order
 * log(df): at df = 1e8 that is 8.9e8 - 8.4e8 - 5e7 = 8.7, which keeps only eight
 * of sixteen digits. Stirling's series for lgamma collapses the same expression
 * to log 2 + 0.5 log(x/2pi) - 1/(12x) + 1/(360x^3), where nothing cancels at
 * all. Only used for x > 500, where truncating after the x^-3 term costs
 * 1/(1260 x^5) < 4e-14. */
static NV chi_log_peak(NV half_df) {
	const NV x = half_df;
	return M_LN2 + 0.5 * log(x / (2.0 * M_PI))
		 - 1.0 / (12.0 * x) + 1.0 / (360.0 * x * x * x);
}

/* `upper` picks which tail comes back: the lower CDF P(T <= t), or the upper
 * tail P(T > t) obtained by integrating Phi(ncp - t*w) instead of
 * Phi(t*w - ncp), the two differing by 1 - Phi(z) = Phi(-z) under an integral
 * whose weight sums to exactly 1. Forming the upper tail as 1 - lower loses it
 * to cancellation whenever the answer is small: power_t_test(n => 2.182,
 * delta => 0.4088, sd => 0.9733, sig_level => 0.001) has a power of 1.03e-3, and
 * subtracting a lower tail of 0.99897 from 1 left only four good digits of it. */
static NV exact_pnt(NV t, NV df, NV ncp, bool upper) {
	if (df <= 0.0) return 0.0;
	const unsigned int n_steps = 30000;            /* even, for Simpson */
	NV integral = 0.0;
	const NV half_df = df / 2.0;

	/* W = sqrt(chi2_df / df) has mean ~1 and standard deviation ~1/sqrt(2 df),
	 * so its density narrows as df grows while a fixed 30000-step grid does not.
	 * By df ~ 1e8 the steps go clean over the peak: power_t_test(n => 4e7,
	 * delta => 0) returned 0.138 where the answer has to be sig_level/2 = 0.025,
	 * and the n solved for a large-cohort effect size came back 9% low. Above
	 * PNT_LARGE_DF, spend the steps on w across +/- 12 standard deviations of the
	 * mode -- 12 sd of a density this symmetric leaves under 1e-30 in the tails,
	 * and the peak then gets ~1250 steps per standard deviation.
	 *
	 * That holds to ~1e-11 up to df ~ 4e5 and then gives way, because log_M's
	 * two large terms cancel harder as df climbs: 1e-8 by df = 8e7 and 5e-7 by
	 * df = 1e9. Beyond there, don't integrate at all. T is asymptotically
	 * normal, and Abramowitz & Stegun 26.7.10 carries the O(1/df) correction, so
	 * its error falls as 1/df^2 -- 4e-12 at the cut-off and 3e-16 by df = 1e9,
	 * i.e. it gets better exactly where the quadrature gets worse. R's pnt.c
	 * switches to the same formula at the same df. */
	if (df > PNT_NORMAL_DF) {
		const NV s = 1.0 / (4.0 * df);
		const NV num = upper ? (ncp - t * (1.0 - s)) : (t * (1.0 - s) - ncp);
		return approx_pnorm(num / sqrt(1.0 + t * t * 2.0 * s));
	}

	if (df > PNT_LARGE_DF) {
		const NV s = 1.0 / sqrt(2.0 * df);
		const NV lo = 1.0 - 12.0 * s, hi = 1.0 + 12.0 * s;   /* lo > 0.7 here */
		const NV w_step = (hi - lo) / (NV)n_steps;
		const NV log_peak = chi_log_peak(half_df);
		for (unsigned int i = 0; i <= n_steps; i++) {
			const NV w = lo + i * w_step;
			const NV e = w - 1.0;
			/* Written against the mode rather than from log_coef: (df-1)log(w)
			 * and half_df*w^2 are each ~1e5 at the ends of this interval and
			 * cancel to ~70, so pairing them as one difference keeps thirteen
			 * digits where summing the raw terms keeps eight. */
			const NV log_M = log_peak + (df - 1.0) * log1p(e) - half_df * e * (e + 2.0);
			const NV weight = (i == 0 || i == n_steps) ? 1.0 : ((i % 2) ? 4.0 : 2.0);
			const NV z = upper ? (ncp - t * w) : (t * w - ncp);
			integral += weight * approx_pnorm(z) * exp(log_M);
		}
		return integral * (w_step / 3.0);
	}

	/* Ordinary df. The density carries w^(df-1), so unless df is a whole number
	 * that factor has a derivative of some order that is infinite at w = 0, and
	 * Simpson -- which assumes four bounded derivatives -- cannot have it. The
	 * earlier u = w/(1+w) grid took the full brunt: nine good digits at df = 1.8,
	 * five at df = 1.2, two at df = 1.2 with sig_level = 1e-4, while whole-number
	 * df stayed at machine precision because there the factor is a polynomial.
	 *
	 * Substituting w = z^m turns the measure into z^(m*df - 1) dz, so choosing m
	 * with m*df - 1 >= 3 leaves the first three derivatives bounded and Simpson
	 * gets what it needs. m = 4 covers every df >= 1; below that it has to grow,
	 * and is capped because z^m must stay computable. The substitution also
	 * clusters the steps towards w = 0 exactly where the old grid was thinnest,
	 * and puts the origin's contribution at z^(m*df - 1) = 0, which is why no
	 * separate endpoint term is needed here.
	 *
	 * The upper limit only has to reach past the density: sqrt(120/df) puts
	 * exp(-df w^2 / 2) below e^-60 for a mode near zero, and 1 + 12/sqrt(2 df)
	 * covers twelve standard deviations once the mode has settled near w = 1.
	 * Whichever is larger serves both shapes. */
	const unsigned int m = (df >= 1.0) ? 4u
		: (unsigned int)(ceil(4.0 / df) > 64.0 ? 64.0 : ceil(4.0 / df));
	const NV log_coef = log(2.0) + half_df * log(half_df) - lgamma(half_df);
	const NV w_max = fmax(sqrt(120.0 / df), 1.0 + 12.0 / sqrt(2.0 * df));
	const NV z_step = pow(w_max, 1.0 / (NV)m) / (NV)n_steps;
	/* i = 0 is skipped: z = 0 makes log(z) -inf, and the term it belongs to is
	 * zero anyway since m*df - 1 > 0 by construction. */
	for (unsigned int i = 1; i <= n_steps; i++) {
		const NV zq = i * z_step;
		const NV w = pow_uint(zq, m);
		const NV log_M = log_coef + ((NV)m * df - 1.0) * log(zq) - half_df * w * w;
		const NV z = upper ? (ncp - t * w) : (t * w - ncp);
		const NV weight = (i == n_steps) ? 1.0 : ((i % 2) ? 4.0 : 2.0);
		integral += weight * approx_pnorm(z) * exp(log_M);
	}
	return integral * (NV)m * (z_step / 3.0);
}
// --- Math Helpers for P-values and Confidence Intervals --- 
// Ranking helper with tie adjustment (matches R's tie handling)
typedef struct { NV val; size_t idx; NV rank; } RankInfo;
/* Single three-way ascending comparator for qsort. Works on raw NV arrays
 * and on any struct whose first member is an NV (RankInfo, RankItem): a
 * pointer to such a struct converts to a pointer to its leading NV. Replaces
 * the former compare_rank/compare_index/cmp_rank_item/cmp_rank_info/compare_NVs
 * family. Order-restoring re-sorts (the old compare_index pass) are gone:
 * rank_data() scatters averaged ranks straight into out[idx]. */
static int cmp_nv3(const void *a, const void *b) {
	NV x = *(const NV *)a, y = *(const NV *)b;
	return (x > y) - (x < y);
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

/* Loader's saddle-point binomial, in log form; defined with the binom_test
 * helpers further down.  Declared here because the hypergeometric density
 * below is built out of it. */
static NV bt_dbinom_raw_log(NV x, NV n, NV p, NV q);

/* log dhyper(x; m white, n black, k drawn), by R's dhyper():
 *
 *      dhyper = dbinom(x; m, p) * dbinom(k-x; n, p) / dbinom(k; m+n, p),
 *      p = k/(m+n)
 *
 * Differencing lgamma() gets the same answer for small tables and loses the
 * back half of it for large ones: lgamma(8.4e7) is about 1.4e9, where a
 * double's spacing is 2.4e-7, so a table like SciPy's gh-3014
 * ([[1,2],[9,84419233]]) came out right to only seven digits.  The three
 * saddle-point terms stay O(1) whatever the margins are, which is exactly why
 * R computes its own hypergeometric this way. */
static NV ft_dhyper_log(long x, long m, long n, long k) {
	if (x < 0 || x > k || x > m || k - x > n) return -INFINITY;
	if (k == 0) return (x == 0) ? 0.0 : -INFINITY;
	NV N = (NV)m + (NV)n;
	NV p = (NV)k / N, q = (N - (NV)k) / N;
	return bt_dbinom_raw_log((NV)x, (NV)m, p, q)
	     + bt_dbinom_raw_log((NV)(k - x), (NV)n, p, q)
	     - bt_dbinom_raw_log((NV)k, N, p, q);
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
	  S->logdc[i] = ft_dhyper_log(j, S->m, S->n, S->k);
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
	ft_rc *restrict r = (ft_rc *)ctx; const ft_support *restrict S = r->S;
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

/* --- General R x C exact test (used for anything that is not 2x2) ---------
 *
 * The 2x2 machinery above cannot describe larger tables, so the R x C case
 * is handled by direct enumeration of every contingency table that shares
 * the observed row and column margins.  Under the null the probability of a
 * table T with fixed margins is the multivariate hypergeometric
 *
 *      P(T) = (prod_i R_i!)(prod_j C_j!) / ( N! prod_ij t_ij! )
 *
 * The (two-sided) p-value is the sum of P(T) over all such T whose
 * probability is <= P(observed).  Only two-sided is defined for R x C, so
 * 'alternative' is ignored for larger tables (matching R's fisher.test). */
typedef struct {
	int nrow, ncol;
	const long *restrict R;   /* fixed row totals                       */
	long *restrict C_rem;     /* remaining column totals (mutated)      */
	const NV *restrict lgR;   /* lgR[i]  = sum_{k>=i} lgamma(R_k+1)     */
	const NV *restrict jenR;  /* jenR[i] = sum_{k>=i} cheapest split of R_k  */
	NV const_term;            /* sum lgamma(R_i+1)+lgamma(C_j+1)-lgamma(N+1) */
	NV log_p_obs_tol;         /* log P(observed) + log1p(relErr)        */
	NV p_total;               /* accumulated p-value                    */
	long long nodes, cap;     /* work counter + runaway guard           */
	int aborted;              /* set once cap is exceeded               */
} ft_rxc_ctx;

static void ft_rxc_row(ft_rxc_ctx *restrict X, int row, int col, long row_rem, NV cur_lc);

/* qsort comparator: ascending margin totals. */
static int ft_long_cmp(const void *a, const void *b) {
	long x = *(const long *)a, y = *(const long *)b;
	return (x > y) - (x < y);
}

/* The smallest sum of lgamma(t+1) that k cells adding up to `total` can have.
 * lgamma(x+1) is convex, so the minimum is the most even split there is: the
 * remainder r gets q+1 and the other k-r cells get q.  The continuous Jensen
 * bound k*lgamma(total/k + 1) is easier to write but slacker, and the slack
 * is what decides whether a subtree gets summed in closed form or walked. */
static NV ft_even_split_lc(long total, long k) {
	long q = total / k, r = total % k;
	return (NV)r * lgamma((NV)q + 2.0) + (NV)(k - r) * lgamma((NV)q + 1.0);
}

/* Decide a whole subtree without walking it, where that is possible.
 *
 * With rows 0..row-1 placed (their lgamma(t+1) terms already summed into
 * cur_lc) and C_rem holding what is left of each column, every completion T
 * of the table satisfies
 *
 *      log P(T) = const_term - cur_lc - S,
 *      S = sum of lgamma(t_ij + 1) over the cells still to be filled,
 *
 * so bounding S bounds log P over the entire subtree.  lgamma(x+1) is convex,
 * so Jensen puts a floor under S -- spreading a row (or column) total evenly
 * is the cheapest it can ever be -- and a! b! <= (a+b)! puts a ceiling on it,
 * since piling a total into one cell is the dearest.  Rows and columns each
 * yield both bounds; the tighter of the two is used.
 *
 * If even the most probable completion is already at or below the observed
 * table's probability then every completion counts, and their combined mass
 * has a closed form.  Counting the N' = sum(C_rem) remaining observations two
 * ways -- assigned directly to rows, or column by column -- gives
 *
 *      sum over completions of prod 1/t_ij!
 *          = N'! / ( prod_{i>=row} R_i!  prod_j C_rem_j! )
 *
 * which is the whole subtree in a single exp() instead of a walk over it.  If
 * even the least probable completion sits above the threshold, nothing in the
 * subtree counts and it is dropped outright.  Both tests are exact: they skip
 * only work the enumeration would have done, and never change the sum.
 *
 * Returns 1 if the subtree was added whole, 2 if it was discarded whole, and
 * 0 if it has to be enumerated after all. */
static int ft_rxc_prune(ft_rxc_ctx *restrict X, int row, NV cur_lc) {
	const long nrem = (long)(X->nrow - row);
	NV n_left = 0.0;      /* N'                                       */
	NV lg_c = 0.0;        /* sum_j lgamma(C_rem_j + 1)                */
	NV jen_c = 0.0;       /* sum_j (cheapest split of C_rem_j over nrem cells) */
	for (int j = 0; j < X->ncol; j++) {
		long c = X->C_rem[j];
		n_left += (NV)c;
		lg_c   += lgamma((NV)c + 1.0);
		jen_c  += ft_even_split_lc(c, nrem);
	}
	NV s_lo = X->jenR[row] > jen_c ? X->jenR[row] : jen_c;  /* S >= s_lo */
	NV s_hi = X->lgR[row]  < lg_c  ? X->lgR[row]  : lg_c;   /* S <= s_hi */
	NV base = X->const_term - cur_lc;

	/* A rounding wobble at the threshold must not take a shortcut the
	 * enumeration itself would not have taken, so both tests are asked for a
	 * little more than they strictly need; falling through is always safe. */
	const NV slack = 1e-9;
	if (base - s_lo <= X->log_p_obs_tol - slack) {
		X->p_total += exp(base + lgamma(n_left + 1.0) - X->lgR[row] - lg_c);
		return 1;
	}
	if (base - s_hi > X->log_p_obs_tol + slack) return 2;
	return 0;
}

/* Finish the current row; either recurse to the next free row, or (once the
 * last free row is placed) derive the final row from the column residuals. */
static void ft_rxc_after_row(ft_rxc_ctx *restrict X, int row, NV cur_lc) {
	if (row == X->nrow - 2) {
		NV lc = cur_lc;
		for (int j = 0; j < X->ncol; j++) lc += lgamma((NV)X->C_rem[j] + 1.0);
		NV logP = X->const_term - lc;
		if (logP <= X->log_p_obs_tol) X->p_total += exp(logP);
		if (++X->nodes > X->cap) X->aborted = 1;
		return;
	}
	ft_rxc_row(X, row + 1, 0, X->R[row + 1], cur_lc);
}

/* Distribute row `row`'s total across the columns.  The last column of the
 * row is fixed by the remaining row total; interior columns range over every
 * value that keeps both the row and the column residuals nonnegative. */
static void ft_rxc_row(ft_rxc_ctx *restrict X, int row, int col, long row_rem, NV cur_lc) {
	if (X->aborted) return;
	/* Every visit is counted, not just the leaves: a table like PR#4688's
	 * (4x3, N = 16442) spends minutes inside the interior of the tree before
	 * it reaches enough leaves for a leaf-only counter to notice. */
	if (++X->nodes > X->cap) { X->aborted = 1; return; }
	if (col == 0) {
		int decided = ft_rxc_prune(X, row, cur_lc);
		if (decided) return;
	}
	if (col == X->ncol - 1) {
		long v = row_rem;
		if (v < 0 || v > X->C_rem[col]) return;
		X->C_rem[col] -= v;
		ft_rxc_after_row(X, row, cur_lc + lgamma((NV)v + 1.0));
		X->C_rem[col] += v;
		return;
	}
	long maxv = row_rem < X->C_rem[col] ? row_rem : X->C_rem[col];
	for (long v = 0; v <= maxv; v++) {
		X->C_rem[col] -= v;
		ft_rxc_row(X, row, col + 1, row_rem - v, cur_lc + lgamma((NV)v + 1.0));
		X->C_rem[col] += v;
		if (X->aborted) return;
	}
}

/* Returns the two-sided exact p-value, or -1.0 if the enumeration exceeded
 * the safety cap (the caller turns that into a croak). */
static NV fisher_rxc_pvalue(pTHX_ const long *restrict cells, int nrow, int ncol) {
	long *restrict R = NULL, *restrict C = NULL;
	Newxz(R, nrow, long);
	Newxz(C, ncol, long);
	long N = 0;
	for (int i = 0; i < nrow; i++)
		for (int j = 0; j < ncol; j++) {
			long v = cells[i * ncol + j];
			R[i] += v; C[j] += v; N += v;
		}

	NV const_term = -lgamma((NV)N + 1.0);
	for (int i = 0; i < nrow; i++) const_term += lgamma((NV)R[i] + 1.0);
	for (int j = 0; j < ncol; j++) const_term += lgamma((NV)C[j] + 1.0);

	NV obs_lc = 0.0;
	for (int i = 0; i < nrow * ncol; i++) obs_lc += lgamma((NV)cells[i] + 1.0);

	/* Everything the enumeration needs -- the two margins, const_term and
	 * obs_lc -- is unchanged by permuting rows and columns or by transposing
	 * the table, but the amount of walking is not, so the margins are put in
	 * the cheapest arrangement before the walk starts.
	 *
	 * A row is laid out one cell at a time with its last cell forced by what
	 * is left of the row, and the final row is forced outright by the column
	 * residuals, so the branching factor of a row grows like R_i^(ncol-1) and
	 * whatever lands last costs nothing.  Two consequences: keep the shorter
	 * side as the columns (transposing MP6's 5x7 to 7x5 drops its worst case
	 * from ~1e14 completions to ~1e11), and sort both margins ascending so
	 * that the fattest row and the fattest column are the ones forced. */
	if (ncol > nrow) {
		long *restrict t = R; R = C; C = t;
		int ti = nrow; nrow = ncol; ncol = ti;
	}
	qsort(R, nrow, sizeof(long), ft_long_cmp);
	qsort(C, ncol, sizeof(long), ft_long_cmp);

	/* Suffix sums over the rows still to be placed, for ft_rxc_prune(). */
	NV *restrict lgR = NULL, *restrict jenR = NULL;
	Newx(lgR, nrow + 1, NV);
	Newx(jenR, nrow + 1, NV);
	lgR[nrow] = jenR[nrow] = 0.0;
	for (int i = nrow - 1; i >= 0; i--) {
		lgR[i]  = lgR[i + 1]  + lgamma((NV)R[i] + 1.0);
		jenR[i] = jenR[i + 1] + ft_even_split_lc(R[i], ncol);
	}

	ft_rxc_ctx X;
	X.nrow = nrow; X.ncol = ncol; X.R = R; X.C_rem = C;
	X.lgR = lgR; X.jenR = jenR;
	X.const_term = const_term;
	X.log_p_obs_tol = (const_term - obs_lc) + log1p(1e-7);
	X.p_total = 0.0;
	X.nodes = 0; X.cap = 50000000LL; X.aborted = 0;

	ft_rxc_row(&X, 0, 0, R[0], 0.0);

	NV p = X.aborted ? -1.0 : X.p_total;
	if (p > 1.0) p = 1.0;
	Safefree(R); Safefree(C); Safefree(lgR); Safefree(jenR);
	return p;
}

/* qsort comparator: order (key,value) pairs by their string key. */
typedef struct { const char *restrict k; SV *restrict v; } ft_kv;
static int ft_kv_cmp(const void *a, const void *b) {
	return strcmp(((const ft_kv *)a)->k, ((const ft_kv *)b)->k);
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
 *
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

/* ---------------------------------------------------------------------------
 * Design-matrix construction, shared by lm() and glm().
 *
 * A model term is a set of variables: "wt" is one, "wt:hp" is two, and a
 * variable holding strings is a factor that expands to indicator columns. The
 * question each factor raises is whether to emit a column for every level or to
 * drop the first as a reference, and R answers it with the margin rule:
 *
 *   The factor f inside term T is coded by contrasts -- reference level dropped
 *   -- when T with f removed is itself a term of the model, and by full
 *   indicators when it is not. The empty margin, which is what a main effect
 *   reduces to once its own variable is removed, counts as present whenever the
 *   model has an intercept. Without an intercept it counts as present only
 *   after the first factor main effect has consumed it.
 *
 * That one rule reproduces R everywhere:
 *
 *   y ~ g          g's margin is empty and the intercept supplies it, so g is
 *                  coded by contrasts: gb, gc.
 *   y ~ g - 1      nothing supplies the empty margin, so g is coded in full:
 *                  ga, gb, gc. This is the case that used to lose a level and
 *                  fit a model forcing the reference group's fitted values to 0.
 *   y ~ a + b - 1  a consumes the empty margin and is coded in full; b then
 *                  finds it present and is coded by contrasts. Coding both in
 *                  full would be rank deficient.
 *   y ~ a * b      both main effects are present, so both components of a:b are
 *                  coded by contrasts: aB:bY.
 *   y ~ a:b        neither main effect is present, so both components are coded
 *                  in full and the term spans the whole cross-classification.
 *
 * Terms are ordered by degree first, as R's terms() does, so that a margin is
 * always decided against terms that precede it.
 * ------------------------------------------------------------------------- */

/* Defined further down, next to the other qsort comparators. */
static int cmp_string_wt(const void *a, const void *b);

/* One component of one design column. */
typedef struct {
	int         fbase;  /* index into LmDesign.factor, or -1 when continuous */
	const char *level;  /* borrowed from LmFactor.level, when fbase >= 0     */
	const char *expr;   /* borrowed from LmDesign.var,   when fbase <  0     */
} LmComp;

typedef struct {
	char        *name;
	char       **level;
	unsigned int nlevel;
} LmFactor;

typedef struct {
	char        *name;   /* the coefficient name, e.g. "woolB:tensionM" */
	LmComp      *comp;
	unsigned int ncomp;  /* 0 marks the intercept column */
} LmCol;

typedef struct {
	LmFactor    *factor;
	unsigned int nfactor;
	LmCol       *col;
	unsigned int ncol;
	char       **var;    /* every distinct variable named by any term */
	unsigned int nvar;
	char       **raw;    /* scratch: this row's raw level per factor */
} LmDesign;

static void lm_design_free(pTHX_ LmDesign *restrict d) {
	unsigned int i, j;
	if (!d) return;
	if (d->factor) {
		for (i = 0; i < d->nfactor; i++) {
			if (d->factor[i].level) {
				for (j = 0; j < d->factor[i].nlevel; j++)
					Safefree(d->factor[i].level[j]);
				Safefree(d->factor[i].level);
			}
			Safefree(d->factor[i].name);
		}
		Safefree(d->factor);
	}
	if (d->col) {
		for (i = 0; i < d->ncol; i++) {
			Safefree(d->col[i].name);
			if (d->col[i].comp) Safefree(d->col[i].comp);
		}
		Safefree(d->col);
	}
	if (d->var) {
		for (i = 0; i < d->nvar; i++) Safefree(d->var[i]);
		Safefree(d->var);
	}
	if (d->raw) Safefree(d->raw);
	Safefree(d);
}

/* Split a term on top-level ':' only, so that a ':' inside I(...) is left
 * alone. Returns the component count and fills starts[]/lens[]. */
static unsigned int lm_split_term(const char *restrict term,
                                  const char **restrict starts,
                                  size_t *restrict lens,
                                  unsigned int cap) {
	unsigned int n = 0;
	int depth = 0;
	const char *restrict p = term, *restrict start = term;
	for (;; p++) {
		if (*p == '(') depth++;
		else if (*p == ')') { if (depth > 0) depth--; }
		if ((*p == ':' && depth == 0) || *p == '\0') {
			if (n < cap) { starts[n] = start; lens[n] = (size_t)(p - start); }
			n++;
			if (*p == '\0') break;
			start = p + 1;
		}
	}
	return n;
}

/* Build the design description for a set of unique model terms. Returns NULL
 * only on an allocation path that cannot happen; croaks nowhere, so callers can
 * free their own state. xlevels_hv, when non-NULL, receives every factor's
 * sorted level list. */
static LmDesign *lm_design_build(pTHX_ HV *restrict data_hoa,
                                 HV **restrict row_hashes, size_t n,
                                 char **restrict uniq_terms,
                                 unsigned int num_uniq,
                                 bool has_intercept,
                                 HV *restrict xlevels_hv) {
	LmDesign *restrict d;
	unsigned int i, j, k, t, c;
	unsigned int max_comp = 0, tcount = 0;
	unsigned int *restrict tstart = NULL, *restrict tlen = NULL;
	unsigned int *restrict tvar = NULL;      /* flat variable indices per term */
	int          *restrict vfac = NULL;      /* variable -> factor index or -1 */
	unsigned int  nwords;
	UV           *restrict tmask = NULL, *restrict margin = NULL;
	bool         *restrict full = NULL;      /* per flat component: full coding? */
	bool          empty_present = has_intercept;
	unsigned int  col_cap, comp_cap;

	Newxz(d, 1, LmDesign);

	/* ---- pass 1: intern variables, record each term's component list ---- */
	for (i = 0; i < num_uniq; i++) {
		if (strEQ(uniq_terms[i], "Intercept")) continue;
		max_comp += lm_split_term(uniq_terms[i], NULL, NULL, 0);
		tcount++;
	}
	if (max_comp == 0) max_comp = 1;
	Newxz(tstart, tcount ? tcount : 1, unsigned int);
	Newxz(tlen,   tcount ? tcount : 1, unsigned int);
	Newxz(tvar,   max_comp, unsigned int);
	Newxz(d->var, max_comp, char*);

	{
		const char **restrict cs = NULL;
		size_t      *restrict cl = NULL;
		unsigned int flat = 0;
		Newxz(cs, max_comp, const char*);
		Newxz(cl, max_comp, size_t);
		t = 0;
		for (i = 0; i < num_uniq; i++) {
			unsigned int nc;
			if (strEQ(uniq_terms[i], "Intercept")) continue;
			nc = lm_split_term(uniq_terms[i], cs, cl, max_comp);
			tstart[t] = flat;
			tlen[t]   = nc;
			for (c = 0; c < nc; c++) {
				char *restrict nm;
				bool found = FALSE;
				Newx(nm, cl[c] + 1, char);
				memcpy(nm, cs[c], cl[c]);
				nm[cl[c]] = '\0';
				for (j = 0; j < d->nvar; j++) {
					if (strEQ(d->var[j], nm)) { tvar[flat] = j; found = TRUE; break; }
				}
				if (found) Safefree(nm);
				else { d->var[d->nvar] = nm; tvar[flat] = d->nvar; d->nvar++; }
				flat++;
			}
			t++;
		}
		Safefree(cs); Safefree(cl);
	}

	// pass 2: which variables are factors, and what are their levels
	Newxz(vfac, d->nvar ? d->nvar : 1, int);
	Newxz(d->factor, d->nvar ? d->nvar : 1, LmFactor);
	for (j = 0; j < d->nvar; j++) {
		vfac[j] = -1;
		if (!is_column_categorical(aTHX_ data_hoa, row_hashes, n, d->var[j])) continue;
		{
			char       **restrict levels = NULL;
			unsigned int nlev = 0, cap = 8;
			Newx(levels, cap, char*);
			for (i = 0; i < n; i++) {
				char *restrict s = get_data_string_alloc(aTHX_ data_hoa, row_hashes,
				                                         i, d->var[j]);
				if (!s) continue;
				{
					bool found = FALSE;
					for (k = 0; k < nlev; k++)
						if (strEQ(levels[k], s)) { found = TRUE; break; }
					if (!found) {
						if (nlev >= cap) { cap *= 2; Renew(levels, cap, char*); }
						levels[nlev++] = savepv(s);
					}
				}
				Safefree(s);
			}
			/* A column of strings with nothing readable in it is no use as a
			 * factor; fall back to treating it as continuous, which is what
			 * this code did before factors were expanded per component. */
			if (nlev == 0) { Safefree(levels); continue; }
			qsort(levels, nlev, sizeof(char*), cmp_string_wt);
			vfac[j] = (int)d->nfactor;
			d->factor[d->nfactor].name   = savepv(d->var[j]);
			d->factor[d->nfactor].level  = levels;
			d->factor[d->nfactor].nlevel = nlev;
			d->nfactor++;
			if (xlevels_hv) {
				AV *restrict lv = newAV();
				for (k = 0; k < nlev; k++) av_push(lv, newSVpv(levels[k], 0));
				hv_store(xlevels_hv, d->var[j], (I32)strlen(d->var[j]),
				         newRV_noinc((SV*)lv), 0);
			}
		}
	}

	/* ---- pass 3: order terms by degree, as R's terms() does ---- */
	{
		unsigned int *restrict order = NULL;
		unsigned int w = 0, deg;
		Newxz(order, tcount ? tcount : 1, unsigned int);
		for (deg = 1; deg <= max_comp; deg++)
			for (t = 0; t < tcount; t++)
				if (tlen[t] == deg) order[w++] = t;
		/* Any term whose degree somehow exceeded max_comp would be dropped, so
		 * sweep up the remainder rather than losing it. */
		if (w < tcount)
			for (t = 0; t < tcount; t++) {
				bool seen = FALSE;
				for (i = 0; i < w; i++) if (order[i] == t) { seen = TRUE; break; }
				if (!seen) order[w++] = t;
			}
		{
			unsigned int *restrict ns = NULL, *restrict nl = NULL;
			Newxz(ns, tcount ? tcount : 1, unsigned int);
			Newxz(nl, tcount ? tcount : 1, unsigned int);
			for (i = 0; i < tcount; i++) { ns[i] = tstart[order[i]]; nl[i] = tlen[order[i]]; }
			Safefree(tstart); Safefree(tlen);
			tstart = ns; tlen = nl;
		}
		Safefree(order);
	}
	// pass 4: the margin rule
	nwords = (d->nvar + (unsigned int)(8 * sizeof(UV)) - 1) / (unsigned int)(8 * sizeof(UV));
	if (nwords == 0) nwords = 1;
	Newxz(tmask,  (size_t)tcount * nwords + nwords, UV);
	Newxz(margin, nwords, UV);
	Newxz(full,   max_comp, bool);
	for (t = 0; t < tcount; t++)
		for (c = 0; c < tlen[t]; c++) {
			unsigned int v = tvar[tstart[t] + c];
			tmask[(size_t)t * nwords + v / (8 * sizeof(UV))] |=
				((UV)1 << (v % (8 * sizeof(UV))));
		}
	for (t = 0; t < tcount; t++) {
		for (c = 0; c < tlen[t]; c++) {
			unsigned int v = tvar[tstart[t] + c];
			bool present = FALSE, empty = TRUE;
			if (vfac[v] < 0) continue;              /* continuous: nothing to code */
			for (i = 0; i < nwords; i++) margin[i] = tmask[(size_t)t * nwords + i];
			margin[v / (8 * sizeof(UV))] &= ~((UV)1 << (v % (8 * sizeof(UV))));
			for (i = 0; i < nwords; i++) if (margin[i]) { empty = FALSE; break; }
			if (empty) {
				present = empty_present;
				if (!present) empty_present = TRUE;  /* consumed by this term */
			} else {
				for (k = 0; k < t && !present; k++) {
					bool same = TRUE;
					for (i = 0; i < nwords; i++)
						if (tmask[(size_t)k * nwords + i] != margin[i]) { same = FALSE; break; }
					present = same;
				}
			}
			full[tstart[t] + c] = !present;
		}
	}

	/* ---- pass 5: emit the columns ---- */
	col_cap = 16; comp_cap = 4;
	Newxz(d->col, col_cap, LmCol);
	if (has_intercept) {
		d->col[0].name = savepv("Intercept");
		d->col[0].comp = NULL;
		d->col[0].ncomp = 0;
		d->ncol = 1;
	}
	for (t = 0; t < tcount; t++) {
		unsigned int nc = tlen[t];
		unsigned int *restrict lo = NULL, *restrict hi = NULL, *restrict at = NULL;
		size_t combos = 1;
		if (nc > comp_cap) comp_cap = nc;
		Newxz(lo, nc ? nc : 1, unsigned int);
		Newxz(hi, nc ? nc : 1, unsigned int);
		Newxz(at, nc ? nc : 1, unsigned int);
		for (c = 0; c < nc; c++) {
			int f = vfac[tvar[tstart[t] + c]];
			if (f < 0) { lo[c] = 0; hi[c] = 1; }
			else {
				lo[c] = full[tstart[t] + c] ? 0 : 1;
				hi[c] = d->factor[f].nlevel;
			}
			if (hi[c] <= lo[c]) { combos = 0; break; }
			combos *= (size_t)(hi[c] - lo[c]);
		}
		/* combos == 0 happens for a single-level factor coded by contrasts:
		 * the term contributes nothing, exactly as before. */
		for (c = 0; c < nc; c++) at[c] = lo[c];
		while (combos > 0) {
			size_t len = 0;
			char *restrict nm = NULL;
			LmComp *restrict cm = NULL;
			if (d->ncol >= col_cap) {
				col_cap *= 2;
				Renew(d->col, col_cap, LmCol);
				for (i = d->ncol; i < col_cap; i++) {
					d->col[i].name = NULL; d->col[i].comp = NULL; d->col[i].ncomp = 0;
				}
			}
			Newxz(cm, nc ? nc : 1, LmComp);
			for (c = 0; c < nc; c++) {
				int f = vfac[tvar[tstart[t] + c]];
				if (f < 0) {
					cm[c].fbase = -1;
					cm[c].expr  = d->var[tvar[tstart[t] + c]];
					cm[c].level = NULL;
					len += strlen(cm[c].expr);
				} else {
					cm[c].fbase = f;
					cm[c].level = d->factor[f].level[at[c]];
					cm[c].expr  = NULL;
					len += strlen(d->factor[f].name) + strlen(cm[c].level);
				}
			}
			len += nc;                       /* separators and the NUL */
			Newxz(nm, len + 1, char);
			for (c = 0; c < nc; c++) {
				if (c) strcat(nm, ":");
				if (cm[c].fbase < 0) strcat(nm, cm[c].expr);
				else {
					strcat(nm, d->factor[cm[c].fbase].name);
					strcat(nm, cm[c].level);
				}
			}
			d->col[d->ncol].name  = nm;
			d->col[d->ncol].comp  = cm;
			d->col[d->ncol].ncomp = nc;
			d->ncol++;
			/* Odometer, leftmost component fastest, which is R's column order
			 * within a term. */
			for (c = 0; c < nc; c++) {
				at[c]++;
				if (at[c] < hi[c]) break;
				at[c] = lo[c];
			}
			if (c == nc) break;
		}
		Safefree(lo); Safefree(hi); Safefree(at);
	}

	if (d->nfactor) Newxz(d->raw, d->nfactor, char*);

	Safefree(tstart); Safefree(tlen); Safefree(tvar);
	Safefree(vfac); Safefree(tmask); Safefree(margin); Safefree(full);
	return d;
}

/* Expand one `*`-crossed chunk of a formula into model terms.
 *
 * `a*b` is a + b + a:b, and crossing is associative, so `a*b*c` is every
 * non-empty subset: a, b, c, a:b, a:c, b:c, a:b:c. Subsets are emitted by
 * increasing degree and, within a degree, in the left-to-right order of the
 * formula, which is the order R's terms() produces. A chunk with no `*` is one
 * term and is appended unchanged.
 *
 * `^` is crossing rather than exponentiation in a formula, so a trailing `^n` on
 * a component is dropped -- `hp^2` is just hp -- unless the component is an
 * I(...) escape, where the caret is arithmetic and belongs to evaluate_term.
 *
 * chunk is written through: the separators become NULs.
 */
static void lm_expand_cross(pTHX_ char *restrict chunk,
                            const char *restrict fname,
                            char **restrict *restrict terms,
                            unsigned int *restrict num_terms,
                            unsigned int *restrict term_cap) {
	char *restrict part[16];
	unsigned int k = 0, i;
	UV mask, limit;
	char *restrict s = chunk;

	for (;;) {
		char *restrict star = strchr(s, '*');
		if (k >= (unsigned int)(sizeof(part) / sizeof(part[0])))
			croak("%s: formula crosses more than %u terms with '*'", fname,
			      (unsigned int)(sizeof(part) / sizeof(part[0])));
		if (star) *star = '\0';
		{
			char *restrict caret = strchr(s, '^');
			if (caret && strncmp(s, "I(", 2) != 0) *caret = '\0';
		}
		part[k++] = s;
		if (!star) break;
		s = star + 1;
	}

	limit = (UV)1 << k;
	/* Grow once for the worst case rather than testing inside the loop. */
	if (*num_terms + (limit - 1) + 1 >= (UV)*term_cap) {
		while ((UV)*term_cap <= *num_terms + limit) *term_cap *= 2;
		Renew(*terms, *term_cap, char*);
	}
	for (i = 1; i <= k; i++) {                    /* degree */
		for (mask = 1; mask < limit; mask++) {
			unsigned int bits = 0, b;
			size_t len = 0;
			char *restrict nm;
			for (b = 0; b < k; b++) if (mask & ((UV)1 << b)) bits++;
			if (bits != i) continue;
			for (b = 0; b < k; b++)
				if (mask & ((UV)1 << b)) len += strlen(part[b]) + 1;
			Newxz(nm, len + 1, char);
			for (b = 0; b < k; b++) {
				if (!(mask & ((UV)1 << b))) continue;
				if (*nm) strcat(nm, ":");
				strcat(nm, part[b]);
			}
			(*terms)[(*num_terms)++] = nm;
		}
	}
}

/* Fill one row of the design matrix. Returns FALSE when the row is incomplete,
 * i.e. when any factor it needs has no readable value or any continuous term
 * evaluates to NaN; the caller drops such rows, as R's na.omit does. */
static bool lm_design_row(pTHX_ LmDesign *restrict d, HV *restrict data_hoa,
                          HV **restrict row_hashes, size_t i,
                          NV *restrict out) {
	unsigned int f, j, c;
	bool ok = TRUE;
	for (f = 0; f < d->nfactor; f++) {
		d->raw[f] = get_data_string_alloc(aTHX_ data_hoa, row_hashes, i,
		                                  d->factor[f].name);
		if (!d->raw[f]) ok = FALSE;
	}
	if (ok) {
		for (j = 0; j < d->ncol && ok; j++) {
			NV v = 1.0;
			for (c = 0; c < d->col[j].ncomp; c++) {
				const LmComp *restrict cm = &d->col[j].comp[c];
				if (cm->fbase >= 0) {
					v *= strEQ(d->raw[cm->fbase], cm->level) ? 1.0 : 0.0;
				} else {
					NV e = evaluate_term(aTHX_ data_hoa, row_hashes,
					                     (unsigned int)i, cm->expr);
					if (isnan(e)) { ok = FALSE; break; }
					v *= e;
				}
			}
			out[j] = v;
		}
	}
	for (f = 0; f < d->nfactor; f++) {
		if (d->raw[f]) { Safefree(d->raw[f]); d->raw[f] = NULL; }
	}
	return ok;
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
	/* Stabilize sort by falling back to original index. Compare as size_t
	 * rather than returning the subtraction: orig_idx is unsigned, so
	 * a - b would wrap and then truncate to int with the wrong sign. */
	size_t ai = ((PVal*)a)->orig_idx, bi = ((PVal*)b)->orig_idx;
	return (ai > bi) - (ai < bi);
}

/* ---- p_adjust() helpers ---
 p_adjust() takes either a flat list of p-values or a whole data frame
 (AoA, AoH, HoA or HoH). Either way the p-values are gathered into one
 family, run through the same kernel, and written back into slots reserved
 while walking the input, so the result comes out in the shape and the
 order it arrived in. */

#define PA_METH_LEN 64

// Lowercase `method` into `out` (PA_METH_LEN bytes) and resolve its aliases
static void pa_method(const char *restrict method, char *restrict out) {
	strncpy(out, method, PA_METH_LEN - 1); out[PA_METH_LEN - 1] = '\0';
	for (unsigned short int i = 0; out[i]; i++) out[i] = tolower(out[i]);
	if (strstr(out, "benjamini") && strstr(out, "hochberg"))  strcpy(out, "bh");
	if (strstr(out, "benjamini") && strstr(out, "yekutieli")) strcpy(out, "by");
	if (strcmp(out, "fdr") == 0) strcpy(out, "bh");
}

static int pa_known(const char *restrict meth) {
	return strcmp(meth, "bonferroni") == 0 || strcmp(meth, "holm")   == 0
	    || strcmp(meth, "hochberg")   == 0 || strcmp(meth, "bh")     == 0
	    || strcmp(meth, "by")         == 0 || strcmp(meth, "hommel") == 0
	    || strcmp(meth, "none")       == 0;
}

/* Adjust n p-values. p[] and adj[] are indexed identically and must not
 * alias; `meth` is already normalized and known to pa_known().             */
static void pa_kernel(const NV *restrict p, NV *restrict adj, size_t n,
                      const char *restrict meth) {
	PVal *restrict arr;
	Newx(arr, n, PVal);
	for (size_t i = 0; i < n; i++) { arr[i].p = p[i]; arr[i].orig_idx = i; }
	// Sort ascending (stable sort using the original index)
	qsort(arr, n, sizeof(PVal), cmp_pval);

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
	} else {   /* "none" — pa_known() already rejected anything else */
		for (size_t i = 0; i < n; i++) {
			adj[arr[i].orig_idx] = arr[i].p;
		}
	}
	Safefree(arr);
}

/* Order hash entries by key, so that tied p-values break the same way on
 * every run instead of following hash iteration order.*/
static int pa_cmp_he(const void *restrict a, const void *restrict b) {
	HE *restrict const ha = *(HE * const *)a;
	HE *restrict const hb = *(HE * const *)b;
	STRLEN la, lb;
	const char *restrict ka, *restrict kb;
/* Read the key bytes straight out of the entry. HePV would do the same,
 except for an SV key, where it goes through SvPV -- and SvPV wants the
 interpreter context, which qsort has no way to hand a comparator. On a
 threaded or MULTIPLICITY perl that is a compile error, so take the SV
 key branch ourselves and pay for a dTHX only there.*/
	if (HeKLEN(ha) == HEf_SVKEY || HeKLEN(hb) == HEf_SVKEY) {
		dTHX;
		ka = HePV(ha, la);
		kb = HePV(hb, lb);
	} else {
		ka = HeKEY(ha);  la = (STRLEN)HeKLEN(ha);
		kb = HeKEY(hb);  lb = (STRLEN)HeKLEN(hb);
	}
	STRLEN m = la < lb ? la : lb;
	int c = m ? memcmp(ka, kb, m) : 0;
	if (c) return c;
	return (la > lb) - (la < lb);
}

static SSize_t pa_sorted_keys(pTHX_ HV *restrict hv, HE **restrict out) {
	SSize_t k = 0;
	HE *restrict e;
	hv_iterinit(hv);
	while ((e = hv_iternext(hv))) out[k++] = e;
	qsort(out, (size_t)k, sizeof(HE*), pa_cmp_he);
	return k;
}

/* Is this column one of the ones holding p-values? `want == NULL` means the
 * caller named none, so every column counts. Returns the marker SV for the
 * column and flags it as seen, so an unmatched name can be reported. */
static SV *pa_mark(pTHX_ HV *restrict want, const char *restrict key,
                   STRLEN klen, U32 utf8) {
	if (!want) return &PL_sv_yes;
	SV **restrict m = hv_fetch(want, key, utf8 ? -(I32)klen : (I32)klen, 0);
	if (!m) return NULL;
	sv_setiv(*m, 1);
	return *m;
}

/* A cell in a frame must be a number or undef; anything else is far more
 * likely to be a label column the caller forgot to exclude than a p-value. */
static void pa_check(pTHX_ SV *restrict cell, const char *restrict col, IV idx) {
	if (!cell || !SvOK(cell) || looks_like_number(cell)) return;
	if (col)
		croak("p_adjust: '%s' in column '%s' is not a p-value; name the columns "
		      "that hold p-values with columns => [...]", SvPV_nolen(cell), col);
	croak("p_adjust: '%s' in column %" IVdf " is not a p-value; name the columns "
	      "that hold p-values with columns => [...]", SvPV_nolen(cell), idx);
}

/* Reserve this cell's place in the family and return the SV that stands in
 for it in the output frame until the adjusted value is written back. */
static SV *pa_place(pTHX_ SV *restrict cell, NV *restrict pv,
                    SV **restrict slots, size_t *restrict k, size_t n) {
	NV p = (cell && SvOK(cell)) ? SvNV(cell) : 1.0;
	SV *restrict place = newSVnv(p);
	if (*k < n) { pv[*k] = p; slots[(*k)++] = place; }
	return place;
}

static SV *pa_copy(pTHX_ SV *restrict cell) {
	return cell ? newSVsv(cell) : newSV(0);
}

/* Helpers for cor(): ranking (Spearman), Pearson r, Kendall tau-b/
 Item used to sort values while remembering their original index,
 * needed for average-rank tie-breaking in Spearman correlation.        */
typedef struct {
	NV val;
	size_t idx;
} RankItem;

/* Compute 1-based average ranks with tie-breaking into out[].
 * in[] is not modified.                                                 */
static void rank_data(const NV *restrict in, NV *restrict out, size_t n) {
	RankItem *restrict ri;
	Newx(ri, n, RankItem);
	for (size_t i = 0; i < n; i++) { ri[i].val = in[i]; ri[i].idx = i; }
	qsort(ri, n, sizeof(RankItem), cmp_nv3);

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

/* (x,y) pair sorted by x ascending, then y ascending — for Kendall's tau. */
typedef struct { NV xv, yv; } KPair;
static int kpair_cmp(const void *a, const void *b) {
	const KPair *pa = (const KPair *)a, *pb = (const KPair *)b;
	if (pa->xv < pb->xv) return -1;
	if (pa->xv > pb->xv) return 1;
	if (pa->yv < pb->yv) return -1;
	if (pa->yv > pb->yv) return 1;
	return 0;
}

/* Count pairs i<j with a[i] > a[j] (strict) while merge-sorting a[] ascending
 * into itself via scratch tmp[].  Equal elements are not inversions.          */
static uint64_t nv_merge_count(NV *restrict a, NV *restrict tmp, size_t lo, size_t hi) {
	if (hi - lo < 2) return 0;
	size_t mid = lo + (hi - lo) / 2;
	uint64_t inv = nv_merge_count(a, tmp, lo, mid) + nv_merge_count(a, tmp, mid, hi);
	size_t i = lo, j = mid, k = lo;
	while (i < mid && j < hi) {
		if (a[i] <= a[j]) tmp[k++] = a[i++];
		else { tmp[k++] = a[j++]; inv += (uint64_t)(mid - i); }
	}
	while (i < mid) tmp[k++] = a[i++];
	while (j < hi)  tmp[k++] = a[j++];
	for (size_t t = lo; t < hi; t++) a[t] = tmp[t];
	return inv;
}

/* Kendall's tau-b between two n-element arrays.
 *
 *   tau-b = (C − D) / sqrt((C + D + T_x)(C + D + T_y))
 *
 * where C = concordant pairs, D = discordant, T_x = pairs tied only on
 * x, T_y = pairs tied only on y.  Joint ties (both zero) are excluded
 * from numerator and denominator, matching R's cor(method="kendall").
 * Returns NAN when the denominator is zero.
 *
 * Implemented via Knight's O(n log n) algorithm: sort by (x,y), tally the
 * tie corrections, and count discordant pairs D as y-inversions with a
 * merge sort.  With tot = n(n-1)/2, xtie/ytie = pairs tied on x/y (incl.
 * joint), ntie = pairs tied on both, the identity
 *   C − D = tot − xtie − ytie + ntie − 2·D
 * recovers the exact same tau-b as the former O(n²) double loop.           */
static NV kendall_tau_b(const NV *restrict x, const NV *restrict y, size_t n) {
	if (n < 2) return NAN;
	KPair *restrict p;
	Newx(p, n, KPair);
	for (size_t i = 0; i < n; i++) { p[i].xv = x[i]; p[i].yv = y[i]; }
	qsort(p, n, sizeof(KPair), kpair_cmp);

	const uint64_t tot = (uint64_t)n * (n - 1) / 2;

	/* xtie: pairs of equal x; ntie: pairs of equal (x,y) — both from p[]. */
	uint64_t xtie = 0, ntie = 0;
	size_t i = 0;
	while (i < n) {
		size_t j = i;
		while (j + 1 < n && p[j + 1].xv == p[i].xv) j++;
		uint64_t t = (uint64_t)(j - i + 1);
		xtie += t * (t - 1) / 2;
		size_t a = i;                       /* subgroup by equal y within equal x */
		while (a <= j) {
			size_t b = a;
			while (b + 1 <= j && p[b + 1].yv == p[a].yv) b++;
			uint64_t u = (uint64_t)(b - a + 1);
			ntie += u * (u - 1) / 2;
			a = b + 1;
		}
		i = j + 1;
	}

	/* ytie: pairs of equal y over all data — from a separate y sort. */
	NV *restrict ys;
	Newx(ys, n, NV);
	for (size_t k = 0; k < n; k++) ys[k] = y[k];
	qsort(ys, n, sizeof(NV), cmp_nv3);
	uint64_t ytie = 0;
	i = 0;
	while (i < n) {
		size_t j = i;
		while (j + 1 < n && ys[j + 1] == ys[i]) j++;
		uint64_t t = (uint64_t)(j - i + 1);
		ytie += t * (t - 1) / 2;
		i = j + 1;
	}
	Safefree(ys);

	/* D: discordant pairs = y-inversions in (x,y)-sorted order. */
	NV *restrict yv, *restrict tmp;
	Newx(yv, n, NV);
	Newx(tmp, n, NV);
	for (size_t k = 0; k < n; k++) yv[k] = p[k].yv;
	uint64_t dis = nv_merge_count(yv, tmp, 0, n);
	Safefree(yv); Safefree(tmp); Safefree(p);

	NV num   = (NV)tot - (NV)xtie - (NV)ytie + (NV)ntie - 2.0 * (NV)dis;
	NV denom = sqrt(((NV)tot - (NV)xtie) * ((NV)tot - (NV)ytie));
	if (denom == 0.0) return NAN;
	return num / denom;
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

// P(T > t): pt(t, df, lower.tail = FALSE)
static NV pt_upper(NV t, NV df) {
	NV prob_2tail = incbeta(df / 2.0, 0.5, df / (df + t * t));
	return (t > 0) ? 0.5 * prob_2tail : 1.0 - 0.5 * prob_2tail;
}

static NV get_t_pvalue(NV t, NV df, const char*restrict alt) {
	NV x = df / (df + t * t);
	NV prob_2tail = incbeta(df / 2.0, 0.5, x);
	if (strcmp(alt, "less") == 0) return (t < 0) ? 0.5 * prob_2tail : 1.0 - 0.5 * prob_2tail;
	if (strcmp(alt, "greater") == 0) return (t > 0) ? 0.5 * prob_2tail : 1.0 - 0.5 * prob_2tail;
	return prob_2tail;
}

/* qt(p_tail, df, lower.tail = FALSE): the t with P(T > t) == p_tail.
 *
 Symmetry first, so the bracket is always [0, high) and the root always
 positive; then bisection to adjacent doubles. Searching upward from zero
 alone cannot express the negative quantile a p_tail above 0.5 asks for --
 which is what a one-sided interval at conf_level < 0.5 needs -- and the old
 1e6 ceiling on the doubling silently saturated instead of failing, so two
 different extreme conf_levels came back with the identical interval. The
 convergence test is relative for the same reason: an absolute 1e-8 on the
 quantile is an error of 1e-8 * std_err on the interval, which grows without
 bound as the data's scale does. */
static NV qt_tail(NV df, NV p_tail) {
	if (!(p_tail > 0.0)) return INFINITY;    /* also catches NaN */
	if (p_tail >= 1.0)   return -INFINITY;
	if (p_tail == 0.5)   return 0.0;
	if (p_tail  > 0.5)   return -qt_tail(df, 1.0 - p_tail);
	NV low = 0.0, high = 1.0;
	/* t * t overflows past sqrt(DBL_MAX); pt_upper() there is already 0, so the
	 * loop ends on its own well before that, and the guard is only a backstop. */
	while (high < sqrt(DBL_MAX) && pt_upper(high, df) > p_tail) {
		low   = high;
		high *= 2.0;
	}
	for (unsigned short int i = 0; i < 200; i++) {
		NV mid = 0.5 * (low + high);
		if (mid <= low || mid >= high) break;   /* low and high are adjacent */
		if (pt_upper(mid, df) > p_tail) low = mid; else high = mid;
	}
	return 0.5 * (low + high);
}

/* Welford over one sample for t_test(), skipping undef and NaN the way R's
 t.test() drops NA (is.na(NaN) is TRUE there too). Infinities are kept, as R
 keeps them. Returns the number of values used; *var_out is NaN for a single
 value, matching var() of length one, and the caller must not fold that into a
 pooled variance -- R skips the term instead.

 AvARRAY, not av_fetch: the length is already known and a sample here is a
 plain array of numbers, so the bounds check and the call per element are the
 only things standing between the loop and the data. */
static size_t t_test_scan(pTHX_ AV *restrict av, NV *restrict mean_out, NV *restrict var_out) {
	const size_t n = (size_t)(av_len(av) + 1);
	size_t kept = 0;
	NV mean = 0.0, M2 = 0.0;
	SV **restrict a = AvARRAY(av);
	for (size_t i = 0; a && i < n; i++) {
		SV *restrict e = a[i];
		if (!e || !SvOK(e)) continue;
		const NV v = SvNV(e);
		if (v != v) continue;
		kept++;
		const NV delta = v - mean;
		mean += delta / (NV)kept;
		M2   += delta * (v - mean);
	}
	*mean_out = mean;
	*var_out  = (kept > 1) ? M2 / (NV)(kept - 1) : NAN;
	return kept;
}

int compare_doubles(const void *restrict a, const void *restrict b) {
	NV da = *(const NV*restrict)a;
	NV db = *(const NV*restrict)b;
	return (da > db) - (da < db);
}

/* --- order statistics ----
 * A median is the middle one or two values, not a sorted array, so median()
 * selects those instead of ordering everything: quickselect touches ~2n
 * elements on average where qsort spends n log n comparisons, every one of
 * them an indirect call through a function pointer the compiler cannot see
 * into, let alone inline.
 *
 * The refinements are the usual ones.  A median-of-three pivot keeps the data
 * people actually have -- already sorted, reverse sorted, mostly duplicates --
 * off the quadratic path; a small range finishes with an insertion sort; and a
 * depth limit hands the rest to heapsort, so an input crafted to defeat the
 * pivot choice degrades to O(n log n) rather than O(n^2).  That combination is
 * introselect, the same shape numpy's partition uses.
 *
 * NaN makes every comparison false, which stops each scan where it stands
 * instead of running it off the end of the array, so a NaN in the data cannot
 * push the partition out of bounds.  Which value comes back is as undefined as
 * it was when this went through qsort.
 */
#define NV_SEL_ISORT 20		/* ranges this small finish with an insertion sort */

static void nv_swap(NV *x, NV *y) { NV t = *x; *x = *y; *y = t; }

static void nv_isort(NV *restrict a, size_t n) {
	for (size_t i = 1; i < n; i++) {
		NV v = a[i];
		size_t j = i;
		while (j > 0 && a[j - 1] > v) { a[j] = a[j - 1]; j--; }
		a[j] = v;
	}
}

/* sift a[root] down through the heap held in a[0..n-1] */
static void nv_sift(NV *restrict a, size_t root, size_t n) {
	NV v = a[root];
	size_t child;
	while ((child = 2 * root + 1) < n) {
		if (child + 1 < n && a[child] < a[child + 1]) child++;
		if (!(v < a[child])) break;
		a[root] = a[child];
		root = child;
	}
	a[root] = v;
}

static void nv_heapsort(NV *restrict a, size_t n) {
	if (n < 2) return;
	for (size_t i = n / 2; i-- > 0; ) nv_sift(a, i, n);
	for (size_t end = n - 1; end > 0; end--) {
		nv_swap(&a[0], &a[end]);
		nv_sift(a, 0, end);
	}
}

/* Leave the k-th smallest of a[0..n-1] at a[k], everything ahead of it no
 * larger and everything after it no smaller.  a[] is reordered in place.     */
static void nv_select(NV *restrict a, size_t n, size_t k) {
	if (n < 2) return;
	size_t lo = 0, hi = n - 1;
	unsigned depth = 0;
	for (size_t t = n; t > 1; t >>= 1) depth += 2;	/* 2*floor(log2 n) */

	while (hi - lo >= NV_SEL_ISORT) {
		if (depth-- == 0) { nv_heapsort(a + lo, hi - lo + 1); return; }

		/* median of three, left in place: a[lo] <= pivot <= a[hi], so both
		 * ends double as sentinels that stop the scans below */
		size_t mid = lo + (hi - lo) / 2;
		if (a[mid] < a[lo])  nv_swap(&a[mid], &a[lo]);
		if (a[hi]  < a[lo])  nv_swap(&a[hi],  &a[lo]);
		if (a[hi]  < a[mid]) nv_swap(&a[hi],  &a[mid]);
		const NV pivot = a[mid];

		size_t i = lo, j = hi;
		for (;;) {
			do { i++; } while (a[i] < pivot);
			do { j--; } while (a[j] > pivot);
			if (i >= j) break;
			nv_swap(&a[i], &a[j]);
		}
		/* a[lo..j] <= pivot <= a[j+1..hi]; keep only the side holding k */
		if (k <= j) hi = j; else lo = j + 1;
	}
	nv_isort(a + lo, hi - lo + 1);
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
	// Nothing erfc() returns this far out is a number: see PNORM_LOWER_ZERO
	if (x <= PNORM_LOWER_ZERO) return 0.0;
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
/* Exact Kendall p-value via Mahonian Numbers (Inversions distribution)
 * Matches R's behavior for N < 50 without ties.*/
static NV kendall_exact_pvalue(size_t n, NV s_obs, const char *restrict alt) {
	long max_inv = (long)n * (n - 1) / 2;
	/* Two ping-pong buffers, allocated once, instead of one malloc/free per
	 * outer step.  The inner recurrence
	 *   next_dp[k] = (1/i) * sum_{j=0..min(i-1,k)} dp[k-j]
	 * is a fixed-width (i) sliding window over dp[], so a running sum makes
	 * each cell O(1) rather than O(i) — dropping the build from O(n^4) to
	 * O(n^3).  Results match the from-scratch sum to floating-point noise. */
	NV *restrict buf_a = (NV*)safemalloc((max_inv + 1) * sizeof(NV));
	NV *restrict buf_b = (NV*)safemalloc((max_inv + 1) * sizeof(NV));
	for (long i = 0; i <= max_inv; i++) buf_a[i] = 0.0;
	buf_a[0] = 1.0;
	NV *restrict dp = buf_a, *restrict next_dp = buf_b;
	/* Build the distribution of inversions via DP */
	for (size_t i = 2; i <= n; i++) {
		long current_max_inv = (long)i * (i - 1) / 2;
		for (long k = 0; k <= max_inv; k++) next_dp[k] = 0.0;
		NV window = 0.0;
		for (long k = 0; k <= current_max_inv; k++) {
			window += dp[k];              /* element entering the window        */
			long out = k - (long)i;       /* element leaving it (width i)        */
			if (out >= 0) window -= dp[out];
			// Divide by 'i' directly to keep array as pure probabilities and prevent overflow
			next_dp[k] = window / (NV)i;
		}
		NV *restrict tmp = dp; dp = next_dp; next_dp = tmp;
	}
	// Convert S statistic to target number of inversions
	long i_obs = (long)round((max_inv - s_obs) / 2.0);
	if (i_obs < 0) i_obs = 0;
	if (i_obs > max_inv) i_obs = max_inv;
	NV p_le = 0.0; /* P(S <= S_obs) */
	for (long k = i_obs; k <= max_inv; k++) p_le += dp[k];
	NV p_ge = 0.0; /* P(S >= S_obs) */
	for (long k = 0; k <= i_obs; k++) p_ge += dp[k];
	Safefree(buf_a); Safefree(buf_b);
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

/* Upper tail P(F > f)  ==  R's pf(f, df1, df2, lower.tail = FALSE).
 *
 * Computed in the upper tail directly via the beta symmetry
 *   1 - I_x(a, b) = I_{1-x}(b, a),  x = df1·f / (df1·f + df2)
 * so 1-x = df2 / (df1·f + df2) is formed without any subtraction.  Writing
 * this as `1 - pf(...)` instead throws away the whole answer once the p-value
 * drops below ~1e-16 (the ulp of 1.0): R reports 1.2e-76 where the naive form
 * returns a flat 0, and loses relative precision from about 1e-9 downward. */
static NV pf_upper(NV f, NV df1, NV df2) {
	if (isnan(f) || isnan(df1) || isnan(df2)) return NAN;   /* NaN in, NaN out */
	if (f <= 0.0)   return 1.0;
	if (isinf(f))   return 0.0;   /* zero within-group variance: R gives p = 0 */
	NV denom = df1 * f + df2;
	if (isinf(denom)) return 0.0; /* p underflows anyway */
	return incbeta(df2 / 2.0, df1 / 2.0, df2 / denom);
}

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

/* write_table: the "wrote <file>" confirmation line.
 *
 * This is say 'wrote ' . colored(['black on_cyan'], $file), with the SGR codes
 * written out inline (black foreground 30, cyan background 46, reset 0) so the
 * module keeps no dependency on Term::ANSIColor.
 *
 * Every format announces itself the same way -- delimited, LaTeX and .xlsx
 * alike -- so a caller always learns where the table went, and learns it in
 * the same shape whatever they asked for. The colour is unconditional, exactly
 * as it was when only LaTeX and .xlsx printed this: a caller who is capturing
 * STDOUT and does not want the escape sequences should capture and strip, or
 * redirect, as they would for any other coloured tool.
 */
static void write_table_announce(pTHX_ const char *restrict file) {
	PerlIO *restrict out = PerlIO_stdout();
	if (!out || !file) return;
	static const char pre[]  = "wrote \033[30;46m";
	static const char post[] = "\033[0m\n";
	PerlIO_write(out, pre, sizeof(pre) - 1);
	PerlIO_write(out, file, strlen(file));
	PerlIO_write(out, post, sizeof(post) - 1);
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

static void print_string_row(pTHX_ PerlIO *restrict fh,
	const char **restrict fields, size_t n, const char *restrict sep,
	AV *restrict collect)
{
	const size_t sep_len = sep ? strlen(sep) : 0;
/* When 'collect' is non-NULL the caller wants the rows captured for the
 * LaTeX renderer (the 'tex' option): stash a copy of this record's fields
 * as an array of SVs so write_tex_tabular() can format them afterwards.
 * The copy captures exactly the fields that would be written to the
 * delimited file, including undef.val substitution. When 'fh' is NULL the
 * row is only collected, not rendered (tex-only output). */
	AV *restrict crow = collect ? newAV() : NULL;
	for (size_t i = 0; i < n; i++) {
		const char *restrict f = fields[i];
		if (crow) {
			SV *restrict fsv = newSVpv(f ? f : "", 0);
// Flattening the cell to a C string dropped its UTF-8 flag; put it
// back so write_tex_tabular() decodes code points (and can map
// Greek). Only when the bytes are valid UTF-8 with a byte >= 0x80:
// pure ASCII needs no flag, and invalid/Latin-1 bytes stay bytes.
			STRLEN flen = SvCUR(fsv);
			const U8 *restrict fb = (const U8*)SvPVX(fsv);
			bool high = 0;
			for (STRLEN k = 0; k < flen; k++) if (fb[k] >= 0x80) { high = 1; break; }
			if (high && is_utf8_string(fb, flen)) SvUTF8_on(fsv);
			av_push(crow, fsv);
		}
		if (!fh) continue; /* collect-only mode: no delimited rendering */
		if (i && sep_len) PerlIO_write(fh, sep, sep_len);
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
	if (fh) PerlIO_putc(fh, '\n');
	if (collect) av_push(collect, newRV_noinc((SV*)crow));
}

/* 
 * write_table: LaTeX tabular output (the 'tex' option / a ".tex" file name).
 *
 Modeled on a stand-alone "2D array -> LaTeX tabular" routine, but driven by
 the rows print_string_row() already assembled, so every data shape the
 delimited writer supports (flat hash, HoA, HoH, AoH, AoA) produces a table
 with no shape-specific code here. The xlsx / worksheet / JSON side outputs
 of the original routine are intentionally omitted.
*/
#define TEX_PUTS(fh, lit) PerlIO_write((fh), (lit), sizeof(lit) - 1)

/* Loose match for /^\includesvg.*\{.+\.svg\}$/: such cells pass through
 * unescaped so an embedded graphics macro survives verbatim. */
static bool tex_is_includesvg(const char *restrict s) {
	size_t n = strlen(s);
	if (n < 5 || strncmp(s, "\\includesvg", 11) != 0) return 0;
	return strcmp(s + n - 5, ".svg}") == 0;
}

// Map a Greek code point to its textgreek macro (\usepackage{textgreek}),
// e.g. U+0394 -> \textDelta. Covers the monotonic Greek block, upper and
// lower case, plus both sigma forms; returns NULL for anything else so the
// caller passes it through unchanged. Add rows here for other symbols.
static const char *tex_greek_macro(UV cp) {
	switch (cp) {
	case 0x0391: return "\\textAlpha";
	case 0x0392: return "\\textBeta";
	case 0x0393: return "\\textGamma";
	case 0x0394: return "\\textDelta";
	case 0x0395: return "\\textEpsilon";
	case 0x0396: return "\\textZeta";
	case 0x0397: return "\\textEta";
	case 0x0398: return "\\textTheta";
	case 0x0399: return "\\textIota";
	case 0x039A: return "\\textKappa";
	case 0x039B: return "\\textLambda";
	case 0x039C: return "\\textMu";
	case 0x039D: return "\\textNu";
	case 0x039E: return "\\textXi";
	case 0x039F: return "\\textOmikron";
	case 0x03A0: return "\\textPi";
	case 0x03A1: return "\\textRho";
	case 0x03A3: return "\\textSigma";
	case 0x03A4: return "\\textTau";
	case 0x03A5: return "\\textUpsilon";
	case 0x03A6: return "\\textPhi";
	case 0x03A7: return "\\textChi";
	case 0x03A8: return "\\textPsi";
	case 0x03A9: return "\\textOmega";
	case 0x03B1: return "\\textalpha";
	case 0x03B2: return "\\textbeta";
	case 0x03B3: return "\\textgamma";
	case 0x03B4: return "\\textdelta";
	case 0x03B5: return "\\textepsilon";
	case 0x03B6: return "\\textzeta";
	case 0x03B7: return "\\texteta";
	case 0x03B8: return "\\texttheta";
	case 0x03B9: return "\\textiota";
	case 0x03BA: return "\\textkappa";
	case 0x03BB: return "\\textlambda";
	case 0x03BC: return "\\textmu";
	case 0x03BD: return "\\textnu";
	case 0x03BE: return "\\textxi";
	case 0x03BF: return "\\textomikron";
	case 0x03C0: return "\\textpi";
	case 0x03C1: return "\\textrho";
	case 0x03C2: return "\\textvarsigma";
	case 0x03C3: return "\\textsigma";
	case 0x03C4: return "\\texttau";
	case 0x03C5: return "\\textupsilon";
	case 0x03C6: return "\\textphi";
	case 0x03C7: return "\\textchi";
	case 0x03C8: return "\\textpsi";
	case 0x03C9: return "\\textomega";
	default:     return NULL;
	}
}

/* Escape one cell into 'out' (reset first): the LaTeX-active characters
 * # _ % & gain a leading backslash and '>' becomes \textgreater. When the
 * source SV is UTF-8, Greek letters are turned into their textgreek macros
 * (e.g. U+0394 Greek Delta -> \textDelta{}; the trailing {} keeps a following letter
 * from being swallowed into the control word). With do_format set, a numeric
 * cell is first rendered with %.4g (mirrors the original 'format' option). */
static void tex_escape_sv(pTHX_ SV *restrict out, const char *restrict s,
	bool is_utf8, bool do_format)
{
	sv_setpvs(out, "");
	if (!s) return;
	char numbuf[64];
	if (do_format && *s) {
		SV *restrict tmp = sv_2mortal(newSVpv(s, 0));
		if (looks_like_number(tmp)) {
// snprintf_nv (my_snprintf), not snprintf: NVgf is "g", "Lg" or "Qg"
// depending on the build, and the C library only knows the first two. A
// quadmath build gets "%.4Qg" right here only because libquadmath's
// constructor teaches glibc the Q modifier -- a glibc extension no other
// platform offers. my_snprintf routes through quadmath_snprintf() itself,
// so it is correct on every build.
			snprintf_nv(numbuf, sizeof(numbuf), "%.4" NVgf, SvNV(tmp));
			s = numbuf;
			is_utf8 = 0; // the formatted number is plain ASCII
		}
	}
	if (tex_is_includesvg(s)) { sv_catpv(out, s); return; }
	if (is_utf8) {
// Walk one Unicode code point at a time so multi-byte letters can be
// remapped. utf8n_to_uvchr (not the _buf form) keeps this on 5.10.
		const U8 *restrict p   = (const U8*)s;
		const U8 *restrict end = p + strlen(s);
		while (p < end) {
			STRLEN clen;
			UV cp = utf8n_to_uvchr(p, (STRLEN)(end - p), &clen, 0);
			if (clen == 0) clen = 1; // never stall on malformed input
			if (cp < 0x80) {
				const char c = (char)cp;
				if (c == '#' || c == '_' || c == '%' || c == '&') {
					sv_catpvn(out, "\\", 1);
					sv_catpvn(out, (const char*)p, 1);
				} else if (c == '>') {
					sv_catpvn(out, "\\textgreater{}", 14);
				} else {
					sv_catpvn(out, (const char*)p, 1);
				}
			} else {
				const char *restrict mac = tex_greek_macro(cp);
				if (mac) { sv_catpv(out, mac); sv_catpvn(out, "{}", 2); }
				else sv_catpvn(out, (const char*)p, clen); // pass through
			}
			p += clen;
		}
		return;
	}
	for (const char *restrict p = s; *p; p++) {
		const char c = *p;
		if (c == '#' || c == '_' || c == '%' || c == '&') {
			sv_catpvn(out, "\\", 1);
			sv_catpvn(out, p, 1);
		} else if (c == '>') {
			sv_catpvn(out, "\\textgreater{}", 14);
		} else {
			sv_catpvn(out, p, 1);
		}
	}
}

// Build the provenance path "<cwd>/<RealScript>" as a mortal SV, mirroring the
// original pure-Perl `getcwd() . '/' . $RealScript`. getcwd() is Cwd::getcwd
// (core, cross-platform) and $RealScript is $FindBin::RealScript; both are read
// from Perl-land so behaviour matches the original. Returns NULL if neither the
// cwd nor a script name is available. Shared by the LaTeX and xlsx writers.
static SV *provenance_path(pTHX) {
	SV *restrict out = sv_2mortal(newSVpvs(""));
	bool have = 0;
// cwd via Cwd::getcwd() -- load Cwd (core) if it is not already in.
	if (!get_cv("Cwd::getcwd", 0))
		load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Cwd"), NULL);
	if (get_cv("Cwd::getcwd", 0)) {
		dSP;
		ENTER; SAVETMPS;
		PUSHMARK(SP);
		PUTBACK;
		int cnt = call_pv("Cwd::getcwd", G_SCALAR);
		SPAGAIN;
		SV *restrict cwd = (cnt > 0) ? POPs : NULL;
		if (cwd && SvOK(cwd)) {
			STRLEN l; const char *restrict cs = SvPV(cwd, l);
			if (l) { sv_catpvn(out, cs, l); have = 1; }
		}
		PUTBACK;
		FREETMPS; LEAVE;
	}
// Script name: prefer $FindBin::RealScript (what the original used); fall
// back to basename($0) when FindBin was never loaded.
	SV *restrict rs = get_sv("FindBin::RealScript", 0);
	const char *restrict script = NULL;
	STRLEN sl = 0;
	if (rs && SvOK(rs)) {
		script = SvPV(rs, sl);
	} else {
		SV *restrict dollar0 = get_sv("0", 0);
		if (dollar0 && SvOK(dollar0)) {
			STRLEN l0; const char *restrict s0 = SvPV(dollar0, l0);
			const char *restrict slash = strrchr(s0, '/');
			script = slash ? slash + 1 : s0;
			sl = strlen(script);
		}
	}
	if (script && sl) {
		sv_catpvn(out, "/", 1);
		sv_catpvn(out, script, sl);
		have = 1;
	}
	return have ? out : NULL;
}

// The LaTeX provenance banner "%written by <cwd>/<script>", or NULL when no
// path is available (the caller then emits a generic fallback line).
static SV *tex_written_by(pTHX) {
	SV *restrict path = provenance_path(aTHX);
	if (!path) return NULL;
	SV *restrict out = sv_2mortal(newSVpvs("%written by "));
	sv_catsv(out, path);
	return out;
}

// The xlsx provenance string "written by <cwd>/<script>" for the workbook's
// document "comments" property; a generic line when no path is available.
static SV *xlsx_written_by(pTHX) {
	SV *restrict path = provenance_path(aTHX);
	SV *restrict out = sv_2mortal(newSVpvs("written by "));
	if (path) sv_catsv(out, path);
	else      sv_catpvn(out, "Stats::LikeR write_table", 24);
	return out;
}

/* Emit one header record -- bold cells joined by " & ", no row terminator.
 * Factored out because 'tex.longtable.head' writes the same record twice
 * (\endfirsthead and \endhead), and the two must never drift apart. */
static void tex_put_header_row(pTHX_ PerlIO *restrict fh, AV *restrict header,
	size_t ncols, SV *restrict scratch)
{
	for (size_t j = 0; j < ncols; j++) {
		if (j) TEX_PUTS(fh, " & ");
		SV **restrict cp = av_fetch(header, (SSize_t)j, 0);
		SV *restrict cv = (cp && *cp && SvOK(*cp)) ? *cp : NULL;
		const char *restrict cs = cv ? SvPV_nolen(cv) : "";
		TEX_PUTS(fh, "\\textbf{");
		tex_escape_sv(aTHX_ scratch, cs, cv ? (SvUTF8(cv) ? 1 : 0) : 0, 0);
		PerlIO_write(fh, SvPVX(scratch), SvCUR(scratch));
		PerlIO_putc(fh, '}');
	}
}

/* Write the full LaTeX tabular. 'rows' is the collected table: element 0 is
 * the header record, the rest are data records (each an AV of SVs). */
static void write_tex_tabular(pTHX_ AV *restrict rows, const char *restrict file,
	const char *restrict col_align, bool bold_first_col, bool do_format,
	const char *restrict size, SV *restrict comment, bool longtable,
	SV *restrict longtable_head)
{
	PerlIO *restrict fh = PerlIO_open(file, "w");
	if (!fh)
		croak("write_table: Could not open '%s' for writing", file);
	SV *restrict scratch = sv_2mortal(newSVpvs(""));
// Provenance banner (see tex_written_by); fall back to a generic line.
	SV *restrict prov = tex_written_by(aTHX);
	if (prov) {
		STRLEN pl; const char *restrict ps = SvPV(prov, pl);
		PerlIO_write(fh, ps, pl); PerlIO_putc(fh, '\n');
	} else {
		TEX_PUTS(fh, "%written by Stats::LikeR write_table\n");
	}
	if (comment && SvOK(comment)) {
		if (SvROK(comment) && SvTYPE(SvRV(comment)) == SVt_PVAV) {
			AV *restrict ca = (AV*)SvRV(comment);
			for (SSize_t i = 0; i <= av_len(ca); i++) {
				SV **restrict c = av_fetch(ca, i, 0);
				if (c && *c && SvOK(*c)) {
					STRLEN l; const char *restrict cs = SvPV(*c, l);
					TEX_PUTS(fh, "% "); PerlIO_write(fh, cs, l); PerlIO_putc(fh, '\n');
				}
			}
		} else if (!SvROK(comment)) {
			STRLEN l; const char *restrict cs = SvPV(comment, l);
			TEX_PUTS(fh, "% "); PerlIO_write(fh, cs, l); PerlIO_putc(fh, '\n');
		}
	}
	SV **restrict h0 = av_fetch(rows, 0, 0);
	AV *restrict header = (h0 && *h0 && SvROK(*h0)) ? (AV*)SvRV(*h0) : NULL;
	const size_t ncols = header ? (size_t)(av_len(header) + 1) : 0;
// With 'tex.longtable' the caller writes the surrounding
// \begin{longtable}{...} ... \end{longtable} (and any \caption / \label)
// and \input{}s this file, so emit only the body: a top rule, the header,
// the data rows, a bottom rule -- no \begin{tabular}/\end{tabular}. The real
// column spec lives on the caller's \begin{longtable}; we emit it once as a
// % comment so the caller can copy a spec with the right number of columns.
	if (longtable) {
// Copy-paste hint for the wrapper the caller must supply, e.g.
//   % \begin{longtable}{ccc}
// one 'tex.col.align' char per column. It is a comment, so it never affects
// typesetting -- the caller still writes the real \begin{longtable}{...}.
		TEX_PUTS(fh, "% \\begin{longtable}{");
		for (size_t i = 0; i < ncols; i++)
			PerlIO_write(fh, col_align, strlen(col_align));
		TEX_PUTS(fh, "}\n");
//		TEX_PUTS(fh, "\\hline\n");
	} else {
		TEX_PUTS(fh, "\\begin{tabular}{|");
		for (size_t i = 0; i < ncols; i++) {
			PerlIO_write(fh, col_align, strlen(col_align));
			PerlIO_putc(fh, '|');
		}
		TEX_PUTS(fh, "} \\hline\n");
	}
	if (size && *size) { PerlIO_write(fh, size, strlen(size)); PerlIO_putc(fh, '\n'); }
// 'tex.longtable.head': emit the header inside longtable's repeat machinery
// instead of as a plain first row. Without it the header is an ordinary body
// row, so the header frozen at the top of every page is whichever one the
// caller hand-wrote into \endfirsthead / \endhead -- which silently stops
// matching 'col.names' the moment the column order changes, and leaves the
// generated header showing up a second time as the first body row.
	const bool lt_head = longtable && longtable_head && SvTRUE(longtable_head);
	if (header) {
		if (lt_head) {
	// No leading \hline: \hline expands to \noalign, and TeX has already
	// begun a row by the time it expands the caller's \input, so a rule as
	// the file's first token is a "Misplaced \noalign" error. The top rule
	// for the first page belongs on the caller's \caption line ("\\ \hline"),
	// where it is a static token that cannot fall out of step with the data.
	// Every later \hline here follows a \\ inside this file, where the
	// lookahead sees it and it is legal.
			tex_put_header_row(aTHX_ fh, header, ncols, scratch);
			TEX_PUTS(fh, " \\\\ \\hline\n\\endfirsthead\n");
	// A non-numeric 'tex.longtable.head' is the caption for every page after
	// the first, written verbatim so LaTeX macros survive. The empty optional
	// argument keeps the continuation out of the List of Tables.
			if (contains_nondigit(aTHX_ longtable_head)) {
				STRLEN cl;
				const char *restrict cc = SvPV(longtable_head, cl);
				TEX_PUTS(fh, "\\caption[]{");
				PerlIO_write(fh, cc, cl);
				TEX_PUTS(fh, "}\\\\\n");
			}
			TEX_PUTS(fh, "\\hline\n");
			tex_put_header_row(aTHX_ fh, header, ncols, scratch);
	// \endfoot (no \endlastfoot) rules the bottom of every page, the last
	// one included -- the counterpart of the tabular branch's closing \hline.
			TEX_PUTS(fh, " \\\\ \\hline\n\\endhead\n\\hline\n\\endfoot\n");
		} else {
			tex_put_header_row(aTHX_ fh, header, ncols, scratch);
			TEX_PUTS(fh, " \\\\ \\hline\n");
		}
	}
	const size_t nrows = av_len(rows) + 1;
	for (size_t i = 1; i < nrows; i++) {
		SV **restrict rp = av_fetch(rows, i, 0);
		AV *restrict row = (rp && *rp && SvROK(*rp)) ? (AV*)SvRV(*rp) : NULL;
		const size_t rc = row ? (size_t)(av_len(row) + 1) : 0;
		for (size_t j = 0; j < rc; j++) {
			if (j) TEX_PUTS(fh, " & ");
			const bool bold = (bold_first_col && j == 0);
			SV **restrict cp = av_fetch(row, (SSize_t)j, 0);
			SV *restrict cv = (cp && *cp && SvOK(*cp)) ? *cp : NULL;
			const char *restrict cs = cv ? SvPV_nolen(cv) : "";
			if (bold) TEX_PUTS(fh, "\\textbf{");
			tex_escape_sv(aTHX_ scratch, cs, cv ? (SvUTF8(cv) ? 1 : 0) : 0, do_format);
			PerlIO_write(fh, SvPVX(scratch), SvCUR(scratch));
			if (bold) PerlIO_putc(fh, '}');
		}
		TEX_PUTS(fh, "\\\\\n");
	}
	if (!longtable) {
		TEX_PUTS(fh, "\\hline \\end{tabular}\n");
	}
	PerlIO_close(fh);
}

/* ---- write_table: .xlsx (Excel) output, dependency-free ------------------
 * An .xlsx file is a ZIP of XML parts. We build the parts as strings and pack
 * them into a STORED (uncompressed) ZIP ourselves, so there is no zlib / CPAN
 * dependency and everything stays in XS. The provenance line (provenance_path)
 * is written into the workbook's document properties as the "comments" field
 * -- dc:description in docProps/core.xml -- mirroring
 *     $workbook->set_properties(comments => comments());
 * from Excel::Writer::XLSX. A numeric-looking cell is written as a number;
 * every other non-empty cell as an inline string. read_table reads it back.
 */
#define SV_CATLIT(sv, lit) sv_catpvn((sv), "" lit, sizeof(lit) - 1)

// CRC-32/IEEE over a byte buffer (each stored ZIP member needs its checksum)
static uint32_t xlsx_crc32(const unsigned char *restrict data, size_t len) {
	/* The 256-entry lookup table is data-independent, so build it once and
	 * reuse it across the many calls per workbook.  A concurrent first call
	 * on another thread merely recomputes the identical constants — benign. */
	static uint32_t table[256];
	static bool table_ready = 0;
	if (!table_ready) {
		for (uint32_t i = 0; i < 256; i++) {
			uint32_t c = i;
			for (int k = 0; k < 8; k++)
				c = (c & 1u) ? (0xEDB88320u ^ (c >> 1)) : (c >> 1);
			table[i] = c;
		}
		table_ready = 1;
	}
	uint32_t crc = 0xFFFFFFFFu;
	for (size_t i = 0; i < len; i++)
		crc = table[(crc ^ data[i]) & 0xFFu] ^ (crc >> 8);
	return crc ^ 0xFFFFFFFFu;
}

// little-endian field writers, appending to a byte-buffer SV
static void zip_le16(pTHX_ SV *restrict b, unsigned v) {
	unsigned char x[2] = { (unsigned char)(v & 0xFF), (unsigned char)((v >> 8) & 0xFF) };
	sv_catpvn(b, (char*)x, 2);
}
static void zip_le32(pTHX_ SV *restrict b, uint32_t v) {
	unsigned char x[4] = { (unsigned char)(v & 0xFF), (unsigned char)((v >> 8) & 0xFF),
		(unsigned char)((v >> 16) & 0xFF), (unsigned char)((v >> 24) & 0xFF) };
	sv_catpvn(b, (char*)x, 4);
}

// Append an unsigned integer's decimal text to an SV
static void xlsx_cat_uint(pTHX_ SV *restrict b, unsigned long v) {
	char tmp[24];
	int n = snprintf(tmp, sizeof(tmp), "%lu", v);
	if (n > 0) sv_catpvn(b, tmp, (STRLEN)n);
}

/* Append s (UTF-8 bytes) to out, escaping XML metacharacters and dropping the
 * control characters XML 1.0 forbids (all but tab / newline / carriage-return). */
static void xlsx_xml_cat(pTHX_ SV *restrict out, const char *restrict s, STRLEN len) {
	for (STRLEN i = 0; i < len; i++) {
		unsigned char c = (unsigned char)s[i];
		switch (c) {
		case '&':  SV_CATLIT(out, "&amp;");  break;
		case '<':  SV_CATLIT(out, "&lt;");   break;
		case '>':  SV_CATLIT(out, "&gt;");   break;
		case '"':  SV_CATLIT(out, "&quot;"); break;
		case '\'': SV_CATLIT(out, "&apos;"); break;
		default:
			if (c < 0x20 && c != '\t' && c != '\n' && c != '\r') break;
			sv_catpvn(out, (const char*)&s[i], 1);
		}
	}
}

// 0-based column index -> A1-style letters (A, B, ..., Z, AA, ...) appended
static void xlsx_col_letters(pTHX_ SV *restrict b, size_t idx) {
	char tmp[16];
	int n = 0;
	size_t v = idx + 1; // bijective base-26
	while (v > 0 && n < (int)sizeof(tmp)) {
		v -= 1;
		tmp[n++] = (char)('A' + (int)(v % 26));
		v /= 26;
	}
	while (n > 0) { char c = tmp[--n]; sv_catpvn(b, &c, 1); }
}

/* True when a cell should be written as an xlsx number: looks_like_number and
 * made only of the characters a plain/scientific decimal uses, so "Inf"/"NaN"
 * and space-padded values fall back to text and never produce an invalid <v>. */
static bool xlsx_plain_number(pTHX_ SV *restrict cell) {
	if (!cell || !SvOK(cell) || !looks_like_number(cell)) return 0;
	STRLEN l; const char *restrict s = SvPV(cell, l);
	if (l == 0) return 0;
	for (STRLEN i = 0; i < l; i++) {
		char c = s[i];
		if (!((c >= '0' && c <= '9') || c == '.' || c == 'e' || c == 'E'
				|| c == '+' || c == '-')) return 0;
	}
	return 1;
}

/* Append one STORED (uncompressed) member to the ZIP under construction: 'zip'
 * is the growing archive, 'cdir' accumulates its central-directory records and
 * '*count' the member count. */
static void xlsx_zip_add(pTHX_ SV *restrict zip, SV *restrict cdir,
	unsigned *restrict count, const char *restrict name, SV *restrict content)
{
	STRLEN nlen = strlen(name);
	STRLEN clen; const char *restrict cdata = SvPV(content, clen);
	uint32_t crc = xlsx_crc32((const unsigned char*)cdata, (size_t)clen);
	uint32_t off = (uint32_t)SvCUR(zip);
	/* local file header */
	zip_le32(aTHX_ zip, 0x04034b50);
	zip_le16(aTHX_ zip, 20);		/* version needed to extract */
	zip_le16(aTHX_ zip, 0);			/* general-purpose flags */
	zip_le16(aTHX_ zip, 0);			/* method 0 = stored */
	zip_le16(aTHX_ zip, 0);			/* mod time */
	zip_le16(aTHX_ zip, 0x21);		/* mod date = 1980-01-01 */
	zip_le32(aTHX_ zip, crc);
	zip_le32(aTHX_ zip, (uint32_t)clen);	/* compressed size */
	zip_le32(aTHX_ zip, (uint32_t)clen);	/* uncompressed size */
	zip_le16(aTHX_ zip, (unsigned)nlen);
	zip_le16(aTHX_ zip, 0);			/* extra length */
	sv_catpvn(zip, name, nlen);
	sv_catpvn(zip, cdata, clen);
	/* central-directory header */
	zip_le32(aTHX_ cdir, 0x02014b50);
	zip_le16(aTHX_ cdir, 20);		/* version made by */
	zip_le16(aTHX_ cdir, 20);		/* version needed */
	zip_le16(aTHX_ cdir, 0);
	zip_le16(aTHX_ cdir, 0);
	zip_le16(aTHX_ cdir, 0);
	zip_le16(aTHX_ cdir, 0x21);
	zip_le32(aTHX_ cdir, crc);
	zip_le32(aTHX_ cdir, (uint32_t)clen);
	zip_le32(aTHX_ cdir, (uint32_t)clen);
	zip_le16(aTHX_ cdir, (unsigned)nlen);
	zip_le16(aTHX_ cdir, 0);		/* extra length */
	zip_le16(aTHX_ cdir, 0);		/* comment length */
	zip_le16(aTHX_ cdir, 0);		/* disk number start */
	zip_le16(aTHX_ cdir, 0);		/* internal attributes */
	zip_le32(aTHX_ cdir, 0);		/* external attributes */
	zip_le32(aTHX_ cdir, off);		/* local-header offset */
	sv_catpvn(cdir, name, nlen);
	(*count)++;
}

/* Build a complete .xlsx from the collected rows (element 0 = header record,
 * the rest data records, each an AV of SVs -- exactly what print_string_row()
 * gathers for the tex path) and write it to 'file'. freeze_rows / freeze_cols
 * give the number of leading rows / columns to freeze in place (0 = none). */
static void write_xlsx_workbook(pTHX_ AV *restrict rows, const char *restrict file,
	const char *restrict sheet_name, SV *restrict comment,
	unsigned freeze_rows, unsigned freeze_cols)
{
	/* ---- worksheet ---- */
	SV *restrict sheet = sv_2mortal(newSVpvs(
		"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
		"<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">"));
	/* Freeze panes: a <sheetViews> block, which the schema requires *before*
	 * <sheetData>. topLeftCell is the first cell below/right of the frozen
	 * region -- e.g. freezing 1 row gives "A2"; 1 row + 2 cols gives "C2". */
	if (freeze_rows || freeze_cols) {
		SV *restrict tl = sv_2mortal(newSVpvs(""));
		xlsx_col_letters(aTHX_ tl, (size_t)freeze_cols);
		xlsx_cat_uint(aTHX_ tl, (unsigned long)freeze_rows + 1);
		STRLEN tll; const char *restrict tls = SvPV(tl, tll);
		const char *restrict ap = (freeze_rows && freeze_cols) ? "bottomRight"
			: freeze_cols ? "topRight" : "bottomLeft";
		SV_CATLIT(sheet, "<sheetViews><sheetView workbookViewId=\"0\"><pane ");
		if (freeze_cols) {
			SV_CATLIT(sheet, "xSplit=\"");
			xlsx_cat_uint(aTHX_ sheet, (unsigned long)freeze_cols);
			SV_CATLIT(sheet, "\" ");
		}
		if (freeze_rows) {
			SV_CATLIT(sheet, "ySplit=\"");
			xlsx_cat_uint(aTHX_ sheet, (unsigned long)freeze_rows);
			SV_CATLIT(sheet, "\" ");
		}
		SV_CATLIT(sheet, "topLeftCell=\"");
		sv_catpvn(sheet, tls, tll);
		SV_CATLIT(sheet, "\" activePane=\"");
		sv_catpv(sheet, ap);
		SV_CATLIT(sheet, "\" state=\"frozen\"/><selection pane=\"");
		sv_catpv(sheet, ap);
		SV_CATLIT(sheet, "\" activeCell=\"");
		sv_catpvn(sheet, tls, tll);
		SV_CATLIT(sheet, "\" sqref=\"");
		sv_catpvn(sheet, tls, tll);
		SV_CATLIT(sheet, "\"/></sheetView></sheetViews>");
	}
	SV_CATLIT(sheet, "<sheetData>");
	SSize_t nrows = av_len(rows) + 1;
	for (SSize_t r = 0; r < nrows; r++) {
		SV **restrict rp = av_fetch(rows, r, 0);
		AV *restrict row = (rp && *rp && SvROK(*rp)
			&& SvTYPE(SvRV(*rp)) == SVt_PVAV) ? (AV*)SvRV(*rp) : NULL;
		SSize_t ncols = row ? av_len(row) + 1 : 0;
		SV_CATLIT(sheet, "<row r=\"");
		xlsx_cat_uint(aTHX_ sheet, (unsigned long)(r + 1));
		SV_CATLIT(sheet, "\">");
		for (SSize_t c = 0; c < ncols; c++) {
			SV **restrict cp = av_fetch(row, c, 0);
			SV *restrict cell = (cp && *cp) ? *cp : NULL;
			if (!cell || !SvOK(cell)) continue;	/* undef -> omit cell */
			if (xlsx_plain_number(aTHX_ cell)) {
				STRLEN vl; const char *restrict vs = SvPV(cell, vl);
				SV_CATLIT(sheet, "<c r=\"");
				xlsx_col_letters(aTHX_ sheet, (size_t)c);
				xlsx_cat_uint(aTHX_ sheet, (unsigned long)(r + 1));
				SV_CATLIT(sheet, "\"><v>");
				sv_catpvn(sheet, vs, vl);
				SV_CATLIT(sheet, "</v></c>");
			} else {
				STRLEN vl; const char *restrict vs = SvPVutf8(cell, vl);
				if (vl == 0) continue;		/* empty string -> omit cell */
				SV_CATLIT(sheet, "<c r=\"");
				xlsx_col_letters(aTHX_ sheet, (size_t)c);
				xlsx_cat_uint(aTHX_ sheet, (unsigned long)(r + 1));
				SV_CATLIT(sheet, "\" t=\"inlineStr\"><is><t xml:space=\"preserve\">");
				xlsx_xml_cat(aTHX_ sheet, vs, vl);
				SV_CATLIT(sheet, "</t></is></c>");
			}
		}
		SV_CATLIT(sheet, "</row>");
	}
	SV_CATLIT(sheet, "</sheetData></worksheet>");

	// ---- document properties: provenance goes in the "comments" field ----
	SV *restrict core = sv_2mortal(newSVpvs(
		"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
		"<cp:coreProperties "
		"xmlns:cp=\"http://schemas.openxmlformats.org/package/2006/metadata/core-properties\" "
		"xmlns:dc=\"http://purl.org/dc/elements/1.1/\" "
		"xmlns:dcterms=\"http://purl.org/dc/terms/\" "
		"xmlns:dcmitype=\"http://purl.org/dc/dcmitype/\" "
		"xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">"
		"<dc:creator>Stats::LikeR</dc:creator>"
		"<cp:lastModifiedBy>Stats::LikeR</cp:lastModifiedBy>"
		"<dc:description>"));
	if (comment && SvOK(comment)) {
		STRLEN dl; const char *restrict ds = SvPVutf8(comment, dl);
		xlsx_xml_cat(aTHX_ core, ds, dl);
	}
	SV_CATLIT(core, "</dc:description></cp:coreProperties>");

	SV *restrict ctypes = sv_2mortal(newSVpvs(
		"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
		"<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">"
		"<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>"
		"<Default Extension=\"xml\" ContentType=\"application/xml\"/>"
		"<Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/>"
		"<Override PartName=\"/xl/worksheets/sheet1.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>"
		"<Override PartName=\"/docProps/core.xml\" ContentType=\"application/vnd.openxmlformats-package.core-properties+xml\"/>"
		"</Types>"));
	SV *restrict rels = sv_2mortal(newSVpvs(
		"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
		"<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
		"<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"xl/workbook.xml\"/>"
		"<Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties\" Target=\"docProps/core.xml\"/>"
		"</Relationships>"));
	SV *restrict wbrels = sv_2mortal(newSVpvs(
		"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
		"<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
		"<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet1.xml\"/>"
		"</Relationships>"));
	SV *restrict workbook = sv_2mortal(newSVpvs(
		"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
		"<workbook xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" "
		"xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\">"
		"<sheets><sheet name=\""));
	xlsx_xml_cat(aTHX_ workbook, sheet_name, strlen(sheet_name));
	SV_CATLIT(workbook, "\" sheetId=\"1\" r:id=\"rId1\"/></sheets></workbook>");

	// ---- pack the ZIP (stored, no compression) ---- */
	SV *restrict zip  = sv_2mortal(newSVpvs(""));
	SV *restrict cdir = sv_2mortal(newSVpvs(""));
	unsigned count = 0;
	xlsx_zip_add(aTHX_ zip, cdir, &count, "[Content_Types].xml",        ctypes);
	xlsx_zip_add(aTHX_ zip, cdir, &count, "_rels/.rels",                rels);
	xlsx_zip_add(aTHX_ zip, cdir, &count, "docProps/core.xml",          core);
	xlsx_zip_add(aTHX_ zip, cdir, &count, "xl/workbook.xml",            workbook);
	xlsx_zip_add(aTHX_ zip, cdir, &count, "xl/_rels/workbook.xml.rels", wbrels);
	xlsx_zip_add(aTHX_ zip, cdir, &count, "xl/worksheets/sheet1.xml",   sheet);
	// central directory, then end-of-central-directory record */
	uint32_t cd_off = (uint32_t)SvCUR(zip);
	STRLEN cd_len; const char *restrict cd = SvPV(cdir, cd_len);
	sv_catpvn(zip, cd, cd_len);
	zip_le32(aTHX_ zip, 0x06054b50);
	zip_le16(aTHX_ zip, 0);			/* number of this disk */
	zip_le16(aTHX_ zip, 0);			/* disk with central directory */
	zip_le16(aTHX_ zip, (unsigned)count);	/* central-dir entries this disk */
	zip_le16(aTHX_ zip, (unsigned)count);	/* total central-dir entries */
	zip_le32(aTHX_ zip, (uint32_t)cd_len);
	zip_le32(aTHX_ zip, cd_off);
	zip_le16(aTHX_ zip, 0);			/* archive comment length */

	PerlIO *restrict fh = PerlIO_open(file, "wb");
	if (!fh) croak("write_table: Could not open '%s' for writing", file);
	STRLEN zl; const char *restrict zb = SvPV(zip, zl);
	PerlIO_write(fh, zb, zl);
	PerlIO_close(fh);
}

// Calculates the Regularized Upper Incomplete Gamma Function Q(a, x)
// Perfectly replicates R's pchisq(..., lower.tail=FALSE)
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

/* Digamma psi(x) and trigamma psi'(x) for x > 0, via recurrence up to x>=6
 * then an asymptotic (Stirling) series. Accuracy ~1e-12, matching R's
 * digamma()/trigamma() to the precision the negative-binomial theta ML needs. */
static NV c_digamma(NV x) {
	NV result = 0.0;
	while (x < 6.0) { result -= 1.0 / x; x += 1.0; }
	NV f = 1.0 / (x * x);
	result += log(x) - 0.5 / x
		- f * (1.0/12.0 - f * (1.0/120.0 - f * (1.0/252.0 - f * (1.0/240.0))));
	return result;
}
static NV c_trigamma(NV x) {
	NV result = 0.0;
	while (x < 6.0) { result += 1.0 / (x * x); x += 1.0; }
	NV f = 1.0 / (x * x);
	result += 1.0 / x + 0.5 * f
		+ (f / x) * (1.0/6.0 - f * (1.0/30.0 - f * (1.0/42.0)));
	return result;
}

/* ML estimate of the negative-binomial dispersion theta at the fitted means
 * mu[i], following MASS::theta.ml step for step: unit weights, the moment
 * estimator n / sum((y/mu - 1)^2) as the starting value, and Newton on the
 * score using the observed information.
 *
 * The stopping rule is MASS's, and it is deliberately slack for a Newton
 * iteration: an ABSOLUTE step tolerance of .Machine$double.eps^0.25, which is
 * exactly 2^-13 (1.22e-4), and at most limit - 1 steps. Because Newton squares
 * its error, a step that small means theta itself is already good to around
 * 1e-8, so the looseness costs little -- and reproducing it matters more than
 * tightening it would gain, since glm.nb's alternation feeds each theta straight
 * back into the next fit. Iterating further here would converge to a slightly
 * different fixed point of that alternation than MASS reaches.
 *
 * MASS also has `t0 <- abs(t0)` at the top of each step and truncates a negative
 * result at zero; the truncation is floored at a tiny positive value instead,
 * because theta divides the variance downstream and an exact zero would poison
 * the fit rather than report it. */
static NV nb_theta_ml(const NV *restrict y, const NV *restrict mu, size_t n,
                      unsigned int limit) {
	NV denom = 0.0;
	for (size_t i = 0; i < n; i++) {
		NV r = y[i] / mu[i] - 1.0;
		denom += r * r;
	}
	NV t0 = (denom > 0.0) ? (NV)n / denom : 1.0;
	if (!(t0 > 0.0) || !isfinite(t0)) t0 = 1.0;
	{
		const NV eps = pow((NV)DBL_EPSILON, 0.25);   /* MASS: double.eps^0.25 */
		NV del = 1.0;
		unsigned int it = 0;
		/* MASS: while ((it <- it + 1) < limit && abs(del) > eps) */
		while (++it < limit && fabs(del) > eps) {
			NV score = 0.0, info = 0.0;
			t0 = fabs(t0);
			for (size_t i = 0; i < n; i++) {
				NV mt = mu[i] + t0;
				score += c_digamma(t0 + y[i]) - c_digamma(t0)
					+ log(t0) + 1.0 - log(mt) - (y[i] + t0) / mt;
				info += -c_trigamma(t0 + y[i]) + c_trigamma(t0)
					- 1.0 / t0 + 2.0 / mt - (y[i] + t0) / (mt * mt);
			}
			if (info == 0.0 || !isfinite(info)) break;
			del = score / info;
			t0 += del;
		}
	}
	if (!(t0 > 0.0) || !isfinite(t0)) t0 = 1e-8;
	return t0;
}

/* Per-observation unit deviance for the log-link count families. */
static NV dev_poisson(NV y, NV mu) {
	NV t = (y > 0.0) ? y * log(y / mu) : 0.0;
	return 2.0 * (t - (y - mu));
}
static NV dev_negbin(NV y, NV mu, NV th) {
	NV t = (y > 0.0) ? y * log(y / mu) : 0.0;
	/* log1p keeps (y+th)*log((y+th)/(mu+th)) accurate when th >> mu (the log
	 * of a ratio very near 1), preventing negative deviances near the
	 * Poisson limit. */
	return 2.0 * (t - (y + th) * log1p((y - mu) / (mu + th)));
}
/* Total log-likelihood of a fitted negative-binomial model (used for the
 * theta outer-loop convergence check and AIC). */
static NV nb_loglik(const NV *restrict y, const NV *restrict mu, size_t n, NV th) {
	NV ll = 0.0;
	for (size_t i = 0; i < n; i++) {
		NV yi = y[i], mi = mu[i];
		/* lgamma(th+yi) - lgamma(th): sum logs directly for integer counts to
		 * avoid catastrophic cancellation when th is large (near-Poisson). */
		NV lg, k = floor(yi + 0.5);
		if (fabs(yi - k) < 1e-9 && k >= 0.0 && k < 1e6) {
			lg = 0.0;
			for (NV j = 0.0; j < k; j += 1.0) lg += log(th + j);
		} else {
			lg = lgamma(th + yi) - lgamma(th);
		}
		/* th*log(th) + yi*log(mu) - (th+yi)*log(th+mu), regrouped for stability */
		ll += lg - lgamma(yi + 1.0)
			- th * log1p(mi / th)
			+ (yi > 0.0 ? yi * log(mi / (th + mi)) : 0.0);
	}
	return ll;
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

static NV rank_and_count_ties(RankInfo *restrict ri, size_t n, bool *restrict has_ties) {
	if (n == 0) return 0.0;
	qsort(ri, n, sizeof(RankInfo), cmp_nv3);
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
// --- KS-TEST C HELPER SECTION ---
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
static NV r_pow_di(NV x, unsigned int n) {
	if (n == 0) return 1.0;
	if (n < 0) return 1.0 / r_pow_di(x, -n);
	NV val = 1.0;
	for (unsigned int i = 0; i < n; i++) val *= x;
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
	Safefree(H);	Safefree(Q);
	return s;
}
/* One comparator, used by every qsort below. Branch form avoids overflow that
 * a subtraction-based comparator would hit, and is correct for any NV width. */
/* Largest m*n for which we will run the exact DP even when exact=>1 is forced.
 * Time is O(m*n); memory is O(min(m,n)). Beyond this we warn and go asymptotic. */
#define KS_EXACT_MAX_PRODUCT 10000000.0
static void calc_2sample_stats(NV *x, size_t nx, NV *y, size_t ny,
                               NV *d, NV *d_plus, NV *d_minus) {
	qsort(x, nx, sizeof(NV), cmp_nv3);
	qsort(y, ny, sizeof(NV), cmp_nv3);
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

static int psmirnov_exact_test(NV q, NV r, NV s, bool two_sided) {
    if (two_sided) return (fabs(r - s) >= q);
    return ((r - s) >= q);
}

// Evaluate the exact 2-sample probability
static NV psmirnov_exact_uniq_upper(NV q, size_t m, size_t n, bool two_sided) {
	NV md = (NV) m, nd = (NV) n;
	NV *restrict u = (NV *) safemalloc((n + 1) * sizeof(NV)); // malloc + full init below
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
	/* R floors n - 1 and only then scales by tsample: pmax(1e-07, n - 1) *
	 * tsample. Flooring the product instead left the two-sample case with half
	 * of R's nu whenever the floor bit. power_t_test() refuses n < 2 outright,
	 * so this is only a backstop now, but it should be R's backstop. */
	NV nu = ((n - 1.0) > 1e-7 ? (n - 1.0) : 1e-7) * (NV)tsample;

	// Ensure sig_level/tside is not truncated
	NV p_tail = sig_level / (NV)tside;
	NV qu = qt_tail(nu, p_tail); // qt(p, df, lower.tail=FALSE)

	NV ncp = sqrt(n / (NV)tsample) * (delta / sd);

	/* R writes these as 1 - pt(qu, ...) and pt(-qu, ...); taking the upper tail
	 * straight from exact_pnt() is the same quantity without the subtraction. */
	if (strict && tside == 2) {
	  return exact_pnt(qu, nu, ncp, TRUE) + exact_pnt(-qu, nu, ncp, FALSE);
	} else {
	  return exact_pnt(qu, nu, ncp, TRUE);
	}
}

/* --- power_t_test's inverse solvers ---
 *
 * Each of n, delta, sd and sig_level is recovered by driving p_body() to the
 * requested power. The four searches differ only in which argument is free, so
 * they share one context and one root finder. */
enum { PTT_N = 0, PTT_DELTA, PTT_SD, PTT_SIG };

typedef struct {
	NV n, delta, sd, sig_level, target;
	int tsample, tside, which;
	bool strict;
} ptt_ctx;

/* p_body() with c->which held free, less the requested power: the function the
 * solver drives to zero. */
static NV ptt_f(const ptt_ctx *restrict c, NV x) {
	switch (c->which) {
	  case PTT_N:     return p_body(x, c->delta, c->sd, c->sig_level, c->tsample, c->tside, c->strict) - c->target;
	  case PTT_DELTA: return p_body(c->n, x, c->sd, c->sig_level, c->tsample, c->tside, c->strict) - c->target;
	  case PTT_SD:    return p_body(c->n, c->delta, x, c->sig_level, c->tsample, c->tside, c->strict) - c->target;
	  default:        return p_body(c->n, c->delta, c->sd, x, c->tsample, c->tside, c->strict) - c->target;
	}
}

/* Regula falsi with the Illinois correction. It stays bracketed the way the
 * plain bisection this replaces did, but converges superlinearly, so it reaches
 * a far tighter answer in fewer evaluations of p_body() -- around a dozen
 * against bisection's three dozen.
 *
 * `tol` is a *relative* tolerance on the step between successive iterates, not
 * on the width of the bracket. Illinois shrinks one side of the bracket much
 * faster than the other, so a bracket-width test declares victory while the
 * iterate is still poor; and R's uniroot() bracket-width default of
 * .Machine$double.eps^0.25 is why R's own delta and sig.level come back with
 * only four or five good digits.
 *
 * Returns NaN when [lo, hi] holds no sign change. Callers croak on that instead
 * of handing back a bracket endpoint dressed up as an answer, which is how
 * solving for sd used to report a standard deviation of delta * 1e7. */
static NV ptt_root(const ptt_ctx *restrict c, NV lo, NV hi, NV tol) {
	if (!(lo < hi)) return NAN;
	NV flo = ptt_f(c, lo), fhi = ptt_f(c, hi);
	if (flo == 0.0) return lo;
	if (fhi == 0.0) return hi;
	if (flo != flo || fhi != fhi) return NAN;
	if ((flo > 0.0) == (fhi > 0.0)) return NAN;
	NV x = 0.5 * (lo + hi), prev = INFINITY;
	/* Which endpoint the previous step replaced: -1 for lo, +1 for hi, 0 for
	 * neither yet. The Illinois halving below is applied only when the same
	 * endpoint is replaced twice running, i.e. when the far side really has gone
	 * stale. Halving it on every step -- the way the correction is usually
	 * written -- discounts a value that was fresh one iteration ago, and once
	 * the iterates start straddling the root (which they do here from about the
	 * fifteenth step) both stored values end up scaled down together and the
	 * secant degenerates to bisection: |f| then halves exactly, step after step.
	 * Waiting for the second retention holds the p_body() count near two dozen,
	 * against roughly fifty for the unconditional halving and sixty for plain
	 * bisection, and matches what Brent's method needs on the same brackets. */
	int side = 0;
	for (unsigned short int i = 0; i < 200; i++) {
		x = hi - fhi * (hi - lo) / (fhi - flo);
		/* an interpolation that lands on or outside the bracket (which the
		 * halved stale value can produce) falls back to the midpoint */
		if (!(x > lo && x < hi)) x = 0.5 * (lo + hi);
		NV fx = ptt_f(c, x);
		/* x == prev is the machine-precision floor: the step has stopped
		 * changing the iterate at all, so no tol can ask for more. */
		if (fx == 0.0 || x == prev || fabs(x - prev) <= tol * fabs(x)) return x;
		prev = x;
		if ((fx > 0.0) == (flo > 0.0)) {
			lo = x; flo = fx;
			if (side == -1) fhi *= 0.5;
			side = -1;
		} else {
			hi = x; fhi = fx;
			if (side == 1) flo *= 0.5;
			side = 1;
		}
	}
	return x;
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
		/* Left unguarded on purpose: a zero-variance group makes w_i infinite,
		 * hence tmp NaN, and R's oneway.test reports NaN df here too. A magic
		 * 1e300 sentinel instead looked like a real (huge) df. */
		res.denom_df  = 1.0 / (3.0 * tmp);
		/* unweighted SS for the output table */
		NV ssbg = 0.0, sswg = 0.0;
		for (size_t g = 0; g < k; g++) {
			NV dm = m_i[g] - grand_mean;
			ssbg += n_i[g] * dm * dm;
			sswg += (n_i[g] - 1.0) * v_i[g];
		}
		res.ss_between = ssbg;
		res.ss_within  = sswg;
		res.ms_between = ssbg / df1;                 /* df1 = k-1 >= 1 */
		res.ms_within  = sswg / res.denom_df;        /* NaN if denom_df is NaN */
		Safefree(w_i);
	}
	// upper-tail p-value  P(F ≥ statistic), evaluated in the tail itself
	res.p_value = pf_upper(res.statistic, res.num_df, res.denom_df);
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
	for (IV i = 0; i < n; i++) out_sizes[obs_group[i]]++;
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
	  /* Same contract as the hash / array-of-arrays modes: an undef or
	   * non-numeric response cell dies rather than being silently read as 0.0 */
	  if (!rsv || !*rsv || !SvOK(*rsv) || !looks_like_number(*rsv)) {
		   snprintf(errbuf, errbuf_len,
			   "formula: response observation %" IVdf " (group '%s') is undefined or non-numeric",
			   i, group_names[obs_group[i]]);
		   for (size_t g = 0; g < ngroups; g++) Safefree(group_names[g]);
		   Safefree(group_names);  Safefree(obs_group);  Safefree(write_pos);
		   return 0;
	  }
	  size_t g   = (size_t)obs_group[i];
	  out_flat[write_pos[g]++] = SvNV(*rsv);
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
// Mark the column whose name equals `want` as an outer column; returns 1 if a
// matching column was found, 0 otherwise. Comparison is via sv_eq so that a
// non-ASCII name (e.g. "ΔG") matches regardless of whether either side carries
// the UTF-8 flag - a plain byte memEQ would miss when the flags differ.
static int c2c_mark(pTHX_ SV **col_names, size_t ncols, SV *want, char *is_outer) {
	for (size_t cc = 0; cc < ncols; cc++) {
		if (sv_eq(col_names[cc], want)) { is_outer[cc] = 1; return 1; }
	}
	return 0;
}
//
// filter() helpers
//
// Resolve the cell SV for a column in the "current row".
//   AoH: current row is row_hv         -> hv_fetch(row_hv, col)
//   HoA: current row is index idx      -> hv_fetch(data_hv,col) -> AV -> av_fetch(idx)
typedef struct {
	bool is_aoh;
	HV *restrict row_hv;
	HV *restrict data_hv;
	SSize_t idx;
} filt_ctx;

#define FLT_AOH 1
#define FLT_HOA 2
#define FLT_HOH 3

/* Call the predicate coderef with the row as $_ and $_[0], and the row
 * identifier as $_[1] (the outer key for HoH, the 0-based row index for
 * AoH/HoA; undef if none). true => keep. */
static bool filt_call(pTHX_ SV *code, SV *row_rv, SV *id) {
	dSP;
	bool keep;
	ENTER; SAVETMPS;
	SAVE_DEFSV;
	DEFSV_set(row_rv);
	PUSHMARK(SP);
	EXTEND(SP, 2);
	PUSHs(row_rv);
	PUSHs(id ? id : &PL_sv_undef);
	PUTBACK;
	(void)call_sv(code, G_SCALAR);
	SPAGAIN;
	{
		SV *restrict res = POPs;	/* POP once; SvTRUE is a multi-eval macro */
		keep = SvTRUE(res) ? 1 : 0;
	}
	PUTBACK;
	FREETMPS; LEAVE;
	return keep;
}

/* Perl's own "give me an IV if this value really is one" test, which decides
 * whether a comparison can be done in integers.  It arrived in 5.13.2 and is
 * core-only -- ppport lists it Viu and does not backport it -- so the 5.10 and
 * 5.12 builds get the same definition perl uses, verbatim from sv.h. */
#ifndef SvIV_please_nomg
#  define SvIV_please_nomg(sv) \
	(!(SvFLAGS(sv) & (SVf_IOK|SVp_IOK)) && (SvNOK(sv) || SvPOK(sv)) \
		? (sv_2iv(sv), SvIOK(sv)) : SvIOK(sv))
#endif

/* ---- col() predicates compiled to C ---------------------------------------
 * A col() object hands filter() two descriptions of the same test: the {code}
 * closure, and -- when every part of the expression is something C can
 * reproduce exactly -- a {plan}, the expression as nested array refs (see
 * Stats::LikeR::col in LikeR.pm for the layout).  Compiling the plan once per
 * filter() call replaces, for every row, one hash allocation with a cell per
 * column plus a call into perl with two or three pointer dereferences and a
 * comparison.  No plan (a ->match regex, an operand that is a reference) means
 * the closure path below runs exactly as it always has.
 */
#define FLTP_NUM 0
#define FLTP_STR 1
#define FLTP_AND 2
#define FLTP_OR	 3
#define FLTP_NOT 4
/* comparison ids; the numeric (> < >= <= == !=) and string (gt lt ge le eq ne)
 * tables are in the same order, so one set of names serves both */
#define FLTC_GT 0
#define FLTC_LT 1
#define FLTC_GE 2
#define FLTC_LE 3
#define FLTC_EQ 4
#define FLTC_NE 5

typedef struct flt_node {
	U8 kind;			/* FLTP_* */
	U8 op;				/* FLTC_*, leaves only */
	U8 swap;			/* literal was on the left: 3 > col('x') */
	bool is_iv;			/* numeric literal fits an IV, so compare as integers */
	int slot;			/* which column, leaves only */
	SV *val;			/* the literal; borrowed from the plan, which the caller holds */
	NV nv;				/* its numeric value ... */
	IV iv;				/* ... and its integer value when is_iv */
	struct flt_node *l, *r;
} flt_node;

typedef struct {
	flt_node *nodes;	/* every node of the tree; the root is nodes[0] */
	int used;
	SV **names;			/* one shared-hash-key SV per distinct column */
	AV **cav;			/* HoA only: that column's array, or NULL when absent */
	SV **cells;			/* scratch: the current row's cell for each column */
	int nslots;
} flt_prog;

static SV *flt_pe(pTHX_ AV *restrict a, SSize_t i) {	/* plan element or NULL */
	SV **restrict p = av_fetch(a, i, 0);
	return (p && *p) ? *p : NULL;
}

/* Node count of a well-formed plan, or -1 if it is not one.  Anything odd here
 * (a hand-built object, a plan from a newer LikeR.pm) just falls back to the
 * closure, so this validates rather than croaks. */
static int flt_plan_size(pTHX_ SV *restrict p) {
	if (!p || !SvROK(p) || SvTYPE(SvRV(p)) != SVt_PVAV) return -1;
	AV *restrict a = (AV *)SvRV(p);
	SV *restrict k = flt_pe(aTHX_ a, 0);
	if (!k || !SvIOK(k)) return -1;
	switch (SvIVX(k)) {
		case FLTP_NUM: case FLTP_STR: {
			SV *restrict op = flt_pe(aTHX_ a, 1);
			SV *restrict nm = flt_pe(aTHX_ a, 2);
			SV *restrict vl = flt_pe(aTHX_ a, 3);
			if (av_len(a) != 4 || !op || !SvIOK(op) || SvIVX(op) < 0 || SvIVX(op) > FLTC_NE)
				return -1;
			if (!nm || !SvOK(nm) || SvROK(nm)) return -1;
			if (!vl || !SvOK(vl) || SvROK(vl)) return -1;
			return 1;
		}
		case FLTP_AND: case FLTP_OR: {
			if (av_len(a) != 2) return -1;
			int l = flt_plan_size(aTHX_ flt_pe(aTHX_ a, 1));
			if (l < 0) return -1;
			int r = flt_plan_size(aTHX_ flt_pe(aTHX_ a, 2));
			return (r < 0) ? -1 : 1 + l + r;
		}
		case FLTP_NOT: {
			if (av_len(a) != 1) return -1;
			int c = flt_plan_size(aTHX_ flt_pe(aTHX_ a, 1));
			return (c < 0) ? -1 : 1 + c;
		}
	}
	return -1;
}

/* Intern a column name: same name -> same slot, so col('x') > 0 & col('x') < 9
 * looks the column up once per row.  The name is kept as a shared-hash-key SV,
 * which carries its hash with it and makes hv_fetch_ent cheap. */
static int flt_slot(pTHX_ flt_prog *restrict pg, SV *restrict name) {
	STRLEN l;
	const char *restrict s = SvPV_const(name, l);
	const bool u = cBOOL(SvUTF8(name));
	for (int i = 0; i < pg->nslots; i++) {
		STRLEN l2;
		const char *restrict s2 = SvPV_const(pg->names[i], l2);
		if (l == l2 && cBOOL(SvUTF8(pg->names[i])) == u && memEQ(s, s2, l)) return i;
	}
	pg->names[pg->nslots] = sv_2mortal(newSVpvn_share(s, u ? -(I32)l : (I32)l, 0));
	return pg->nslots++;
}

static flt_node *flt_build(pTHX_ flt_prog *restrict pg, SV *restrict p) {
	AV *restrict a  = (AV *)SvRV(p);
	flt_node *restrict nd = &pg->nodes[pg->used++];
	Zero(nd, 1, flt_node);
	nd->kind = (U8)SvIVX(flt_pe(aTHX_ a, 0));
	switch (nd->kind) {
		case FLTP_NUM: case FLTP_STR: {
			SV *restrict sw = flt_pe(aTHX_ a, 4);
			nd->op	 = (U8)SvIVX(flt_pe(aTHX_ a, 1));
			nd->slot = flt_slot(aTHX_ pg, flt_pe(aTHX_ a, 2));
			nd->val	 = flt_pe(aTHX_ a, 3);
			nd->swap = (sw && SvTRUE(sw)) ? 1 : 0;
			if (nd->kind == FLTP_NUM) {
				/* the perl side only plans a literal that looks like a number,
				 * so numifying it here cannot warn */
				SvIV_please_nomg(nd->val);
				nd->is_iv = cBOOL(SvIOK(nd->val) && !SvIsUV(nd->val));
				nd->iv	  = nd->is_iv ? SvIVX(nd->val) : 0;
				nd->nv	  = SvNV(nd->val);
			}
			break;
		}
		case FLTP_AND: case FLTP_OR:
			nd->l = flt_build(aTHX_ pg, flt_pe(aTHX_ a, 1));
			nd->r = flt_build(aTHX_ pg, flt_pe(aTHX_ a, 2));
			break;
		default:	/* FLTP_NOT */
			nd->l = flt_build(aTHX_ pg, flt_pe(aTHX_ a, 1));
			break;
	}
	return nd;
}

/* Compile {plan} into PG, or return false to leave the caller on the closure
 * path.  Everything allocated here is freed by the caller's scope exit (so a
 * croak from a later row cannot leak it). */
static bool flt_compile(pTHX_ flt_prog *restrict pg, SV *restrict plan) {
	int n = flt_plan_size(aTHX_ plan);
	if (n < 1) return FALSE;
	Zero(pg, 1, flt_prog);
	pg->nodes = (flt_node *)safemalloc(n * sizeof(flt_node));
	SAVEFREEPV(pg->nodes);
	pg->names = (SV **)safemalloc(n * sizeof(SV *));		/* <= n leaves */
	SAVEFREEPV(pg->names);
	pg->cav	  = (AV **)safemalloc(n * sizeof(AV *));
	SAVEFREEPV(pg->cav);
	pg->cells = (SV **)safemalloc(n * sizeof(SV *));
	SAVEFREEPV(pg->cells);
	(void)flt_build(aTHX_ pg, plan);
	return TRUE;
}

/* One numeric comparison.  Same rules as the perl closure: a missing, undef or
 * non-numeric cell never matches, and the comparison itself is perl's (integer
 * when both sides are integers, otherwise floating point). */
static bool flt_num(pTHX_ SV *restrict cell, const flt_node *restrict nd) {
	if (!cell) return FALSE;
	SvGETMAGIC(cell);
	if (!SvOK(cell) || !looks_like_number(cell)) return FALSE;
	int c;
	/* Read the cell where it can be read, and only convert it where it must
	 * be.  A cell that is already a number answers from SvNVX/SvIVX; caching a
	 * conversion into it instead would write to the caller's frame, and on a
	 * numeric column that is a dirtied page per few dozen rows for nothing.
	 * Only a string cell is numified, which is what perl's own `>` does too. */
	if (!SvIOK(cell) && !SvNOK(cell)) SvIV_please_nomg(cell);
	if (nd->is_iv && SvIOK(cell) && !SvIsUV(cell)) {
		const IV a = SvIVX(cell), b = nd->iv;
		c = (a < b) ? -1 : (a > b) ? 1 : 0;
	} else {
		const NV a = SvNOK(cell)  ? SvNVX(cell)
		          : !SvIOK(cell)  ? SvNV_nomg(cell)
		          : SvIsUV(cell)  ? (NV)SvUVX(cell) : (NV)SvIVX(cell);
		const NV b = nd->nv;
		if	(a < b) c = -1;
		else if (a > b) c =  1;
		else if (a == b) c = 0;
		else return nd->op == FLTC_NE;	/* NaN: unequal to everything, ordered by nothing */
	}
	if (nd->swap) c = -c;
	switch (nd->op) {
		case FLTC_GT: return c >  0;
		case FLTC_LT: return c <  0;
		case FLTC_GE: return c >= 0;
		case FLTC_LE: return c <= 0;
		case FLTC_EQ: return c == 0;
		default:	  return c != 0;	/* FLTC_NE */
	}
}

/* One string comparison; an undef or missing cell never matches. */
static bool flt_str(pTHX_ SV *restrict cell, const flt_node *restrict nd) {
	if (!cell) return FALSE;
	SvGETMAGIC(cell);
	if (!SvOK(cell)) return FALSE;
	if (nd->op == FLTC_EQ || nd->op == FLTC_NE) {
		const bool e = cBOOL(sv_eq(cell, nd->val));
		return (nd->op == FLTC_EQ) ? e : !e;
	}
	int c = sv_cmp(cell, nd->val);
	if (nd->swap) c = -c;
	switch (nd->op) {
		case FLTC_GT: return c >  0;
		case FLTC_LT: return c <  0;
		case FLTC_GE: return c >= 0;
		default:	  return c <= 0;	/* FLTC_LE */
	}
}

static bool flt_eval(pTHX_ const flt_prog *restrict pg, const flt_node *restrict nd) {
	switch (nd->kind) {
		case FLTP_AND: return flt_eval(aTHX_ pg, nd->l) && flt_eval(aTHX_ pg, nd->r);
		case FLTP_OR:  return flt_eval(aTHX_ pg, nd->l) || flt_eval(aTHX_ pg, nd->r);
		case FLTP_NOT: return !flt_eval(aTHX_ pg, nd->l);
		case FLTP_NUM: return flt_num(aTHX_ pg->cells[nd->slot], nd);
		default:	   return flt_str(aTHX_ pg->cells[nd->slot], nd);
	}
}

/* Test one row given as a hash (AoH, HoH). */
static bool flt_row_hv(pTHX_ flt_prog *restrict pg, HV *restrict row) {
	for (int s = 0; s < pg->nslots; s++) {
		HE *restrict e = hv_fetch_ent(row, pg->names[s], 0, 0);
		pg->cells[s] = e ? HeVAL(e) : NULL;
	}
	return flt_eval(aTHX_ pg, &pg->nodes[0]);
}

/* Test row I of a HoA, whose columns were bound once by flt_bind_hoa. */
static bool flt_row_hoa(pTHX_ flt_prog *restrict pg, SSize_t i) {
	for (int s = 0; s < pg->nslots; s++) {
		AV *restrict av = pg->cav[s];
		SV **restrict p = (av && i <= AvFILLp(av)) ? &AvARRAY(av)[i] : NULL;
		pg->cells[s] = p ? *p : NULL;
	}
	return flt_eval(aTHX_ pg, &pg->nodes[0]);
}

/* Resolve every column the predicate names against a HoA frame, once. */
static void flt_bind_hoa(pTHX_ flt_prog *restrict pg, HV *restrict data) {
	for (int s = 0; s < pg->nslots; s++) {
		HE *restrict e = hv_fetch_ent(data, pg->names[s], 0, 0);
		SV *restrict v = e ? HeVAL(e) : NULL;
		pg->cav[s] = (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV) ? (AV *)SvRV(v) : NULL;
	}
}

/* Hand back an exactly-sized array: filter() knows how many rows it kept
 * before it fills anything, so no output array is ever grown, over-allocated
 * or copied.  Fill AvARRAY[0 .. n-1] and call this. */
#define FLT_AV_FILLED(av, n) (AvFILLp(av) = (SSize_t)(n) - 1)

/* One output cell: newSVsv, with the two shapes a numeric data frame is almost
 * entirely made of taken directly.  sv_setsv has to look for get-magic, decide
 * between stealing, copy-on-write and a plain copy, and dispatch on both source
 * and destination type before it can move an NV; when the source is a bare
 * number none of that can apply.  NULL (a hole, or a column that stops short of
 * the frame) becomes undef, as it did when this was newSVsv(&PL_sv_undef).
 * Anything else -- strings, refs, objects, magic, undef -- falls through to
 * newSVsv unchanged, so nothing about the copy's semantics moves. */
/* The kept row positions, from the flags the predicate pass set.  A materialise
 * loop that walks these is `kept` trips of straight-line copying; one that walks
 * the flags is `n` trips around a branch no CPU can predict at any interesting
 * selectivity.  Worth its 8 bytes per KEPT row only where a frame is rebuilt
 * column by column -- ncol passes over the same rows -- so that is the only
 * place it is built; a single-pass rebuild reads the flags directly. */
PERL_STATIC_INLINE SSize_t *flt_kept_index(pTHX_ const char *restrict keep,
                                           SSize_t n, SSize_t kept) {
	SSize_t *restrict idx = (SSize_t*)safemalloc((kept ? (size_t)kept : 1) * sizeof(SSize_t));
	SAVEFREEPV(idx);
	SSize_t t = 0;
	for (SSize_t i = 0; i < n && t < kept; i++) if (keep[i]) idx[t++] = i;
	return idx;
}

PERL_STATIC_INLINE SV *flt_cell_copy(pTHX_ SV *restrict s) {
	/* SVt_PVNV is the last body type that can hold a bare number; PVMG and
	 * above bring a stash, magic or an lvalue behind them and are left to
	 * newSVsv along with anything flagged below. */
	if (s && SvTYPE(s) <= SVt_PVNV) {
		const U32 f = SvFLAGS(s);
		if (!(f & (SVs_GMG|SVs_SMG|SVs_RMG|SVs_OBJECT|SVf_ROK|SVf_POK|SVf_UTF8))) {
			if ((f & (SVf_NOK|SVf_IOK)) == SVf_NOK) return newSVnv(SvNVX(s));
			if ((f & (SVf_NOK|SVf_IOK|SVf_IVisUV)) == SVf_IOK) return newSViv(SvIVX(s));
		}
	}
	return newSVsv(s ? s : &PL_sv_undef);
}

/* ---- the row a closure predicate sees, over a HoA frame -------------------
 * A HoA has no row hashes, so one has to be built for the predicate.  Building
 * a fresh one per row costs a hash, a hash entry and a scalar per column per
 * row, nearly all of it thrown away again; instead one hash is built and its
 * cells are overwritten as the scan moves down the frame.
 *
 * That is only safe while the predicate treats the row as read-only and lets
 * go of it, which is the normal case and is checked rather than assumed: if
 * anything still holds the hash, its reference or any of its cells when the
 * predicate returns, or if the predicate added or removed a key, the buffer is
 * abandoned (whoever kept it keeps a hash nobody else will touch) and the next
 * row gets a fresh one.  So the old one-hash-per-row behaviour is still there
 * for predicates that need it, and only they pay for it.
 */
typedef struct {
	HV *hv;
	SV *rv;				/* our reference to hv; NULL once handed away */
	SV **slot;			/* the cell SV of each column, in `names` order */
	U32 n;
	char **names;
	STRLEN *nlens;
} flt_rowbuf;

static void flt_rb_new(pTHX_ flt_rowbuf *restrict rb) {
	rb->hv = newHV();
	hv_ksplit(rb->hv, rb->n ? rb->n : 1);
	rb->rv = newRV_noinc((SV *)rb->hv);
	for (U32 c = 0; c < rb->n; c++) {
		SV **restrict sp = hv_store(rb->hv, rb->names[c], rb->nlens[c], newSV(0), 0);
		rb->slot[c] = *sp;
	}
}

static bool flt_rb_reusable(pTHX_ const flt_rowbuf *restrict rb) {
	PERL_UNUSED_CONTEXT;
	if (SvREFCNT(rb->rv) > 1 || SvREFCNT((SV *)rb->hv) > 1) return FALSE;
	if ((U32)HvUSEDKEYS(rb->hv) != rb->n) return FALSE;
	for (U32 c = 0; c < rb->n; c++)
		if (SvREFCNT(rb->slot[c]) > 1) return FALSE;
	return TRUE;
}

/* Registered on the save stack, so a croaking predicate frees the row buffer
 * on its way out instead of leaking it. */
static void flt_rb_free(pTHX_ void *p) {
	flt_rowbuf *restrict rb = (flt_rowbuf *)p;
	if (rb->rv) { SvREFCNT_dec(rb->rv); rb->rv = NULL; }
}

/* register column NAME in (reg,order) the first time it is seen, creating its
 * output array in OUT; used to build HoA output from AoH/HoH input. */
static void
flt_reg_col(pTHX_ HV *reg, AV *order, HV *out, const char *name, STRLEN nlen){
	if (!hv_exists(reg, name, nlen)) {
		hv_store(reg, name, nlen, newSViv(1), 0);
		hv_store(out, name, nlen, newRV_noinc((SV*)newAV()), 0);
		av_push(order, newSVpvn(name, nlen));
	}
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
	unsigned int count;
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
// Helpers for _parse_csv_file
/* save-stack destructor: closes the input handle on ANY exit, including a
 * croak thrown inside the row callback */
static void S_pclose(pTHX_ void *p) {
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

static void lm_append(pTHX_ char **bufp, size_t *lenp, size_t *capp, const char *s){
	size_t slen = strlen(s);
	size_t sep  = (*lenp > 0) ? 1 : 0;
	size_t need = *lenp + sep + slen + 1;            /* + NUL */
	if (need > *capp) {
		size_t nc = (*capp > 0) ? *capp : 64;
		while (nc < need) nc *= 2;
		Renew(*bufp, nc, char);
		*capp = nc;
	}
	char *restrict dst = *bufp + *lenp;
	if (sep) *dst++ = '+';
	memcpy(dst, s, slen);
	dst[slen] = '\0';
	*lenp += sep + slen;
}

/* ---------------------------------------------------------------------------
 * Formula and data-shape handling shared by lm() and glm().
 *
 * The two functions differ only in what they do with the design matrix once it
 * exists, so everything up to that point is here: how a data argument is read,
 * how its rows are named, and how a formula string becomes a term list. Keeping
 * one copy is what makes a fit's fitted.values, residuals and deviance.resid
 * key on the same names whichever function produced them.
 * ------------------------------------------------------------------------- */

/* Column names that label an observation rather than measure it. A HoA with one
 * of these among its keys -- or an AoH whose rows carry one -- names its rows
 * with that column instead of 1..n, and '.' leaves the column out of the
 * predictors, since a row label is not a variable. */
static const char *const lm_row_name_keys[] =
	{ "row.names", "_row", "rownames", ".rownames" };
#define LM_N_ROW_NAME_KEYS (sizeof lm_row_name_keys / sizeof lm_row_name_keys[0])

static bool lm_is_row_name_key(const char *restrict k, STRLEN len) {
	for (size_t i = 0; i < LM_N_ROW_NAME_KEYS; i++)
		if (strlen(lm_row_name_keys[i]) == len
		    && memcmp(k, lm_row_name_keys[i], len) == 0) return TRUE;
	return FALSE;
}

/* Work out whether the data argument is a hash of columns (HoA), a hash of rows
 * (HoH) or an array of rows (AoH), label every observation, and hand back the
 * two views the design-matrix helpers accept: *data_hoa_out for a HoA,
 * *row_hashes_out otherwise (exactly one of the two is non-NULL).
 *
 * Returns the observation count. *row_names_out is a Newx array of savepv'd
 * names; the caller frees each name and then the array. Croaks -- with fname as
 * the message prefix, and after freeing whatever it had allocated -- on a shape
 * neither function can read. Callers run lm_formula_split() first and pass its
 * buffer as fbuf so that those croaks release it too. */
static size_t lm_read_rows(pTHX_ SV *restrict data_sv, const char *restrict fname,
                           char *restrict fbuf,
                           HV  *restrict *restrict data_hoa_out,
                           HV **restrict *restrict row_hashes_out,
                           char **restrict *restrict row_names_out) {
	SV  *restrict ref        = SvRV(data_sv);
	HV  *restrict data_hoa   = NULL;
	HV **restrict row_hashes = NULL;
	char **restrict row_names = NULL;
	size_t n = 0, i, k;
	HE *restrict entry;

	*data_hoa_out = NULL; *row_hashes_out = NULL; *row_names_out = NULL;

	if (SvTYPE(ref) == SVt_PVHV) {
		HV *restrict hv = (HV*)ref;
		SV *restrict val;
		if (hv_iterinit(hv) == 0) { Safefree(fbuf); croak("%s: Data hash is empty", fname); }
		entry = hv_iternext(hv);
		if (!entry) return 0;
		val = hv_iterval(hv, entry);
		if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
			AV *restrict rn_av = NULL;
			data_hoa = hv;
			n = (size_t)(av_len((AV*)SvRV(val)) + 1);
			for (k = 0; k < LM_N_ROW_NAME_KEYS; k++) {
				SV **restrict rn = hv_fetch(hv, lm_row_name_keys[k],
				                            (I32)strlen(lm_row_name_keys[k]), 0);
				if (rn && *rn && SvROK(*rn) && SvTYPE(SvRV(*rn)) == SVt_PVAV) {
					rn_av = (AV*)SvRV(*rn);
					break;
				}
			}
			Newx(row_names, n ? n : 1, char*);
			for (i = 0; i < n; i++) {
				SV **restrict nm = rn_av ? av_fetch(rn_av, (SSize_t)i, 0) : NULL;
				if (nm && *nm && SvOK(*nm)) {
					STRLEN l; const char *restrict s = SvPV(*nm, l);
					row_names[i] = savepvn(s, l);
				} else {
					char buf[32];
					snprintf(buf, sizeof buf, "%lu", (unsigned long)(i + 1));
					row_names[i] = savepv(buf);
				}
			}
		} else if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV) {
			/* HoH: the outer keys already name the rows. */
			n = (size_t)HvUSEDKEYS(hv);
			Newx(row_names, n ? n : 1, char*);
			Newx(row_hashes, n ? n : 1, HV*);
			hv_iterinit(hv);
			i = 0;
			while ((entry = hv_iternext(hv))) {
				SV *restrict rval = hv_iterval(hv, entry);
				I32 klen;
				if (!SvROK(rval) || SvTYPE(SvRV(rval)) != SVt_PVHV) {
					for (k = 0; k < i; k++) Safefree(row_names[k]);
					Safefree(row_names); Safefree(row_hashes); Safefree(fbuf);
					croak("%s: Hash values must all be HashRefs (HoH)", fname);
				}
				row_names[i]  = savepv(hv_iterkey(entry, &klen));
				row_hashes[i] = (HV*)SvRV(rval);
				i++;
			}
		} else { Safefree(fbuf); croak("%s: Hash values must be ArrayRefs (HoA) or HashRefs (HoH)", fname); }
	} else if (SvTYPE(ref) == SVt_PVAV) {
		AV *restrict av = (AV*)ref;
		n = (size_t)(av_len(av) + 1);
		Newx(row_names, n ? n : 1, char*);
		Newx(row_hashes, n ? n : 1, HV*);
		for (i = 0; i < n; i++) {
			SV **restrict val = av_fetch(av, (SSize_t)i, 0);
			HV  *restrict rh;
			SV **restrict nm = NULL;
			if (!val || !SvROK(*val) || SvTYPE(SvRV(*val)) != SVt_PVHV) {
				for (k = 0; k < i; k++) Safefree(row_names[k]);
				Safefree(row_names); Safefree(row_hashes); Safefree(fbuf);
				croak("%s: Array values must be HashRefs (AoH)", fname);
			}
			rh = (HV*)SvRV(*val);
			row_hashes[i] = rh;
			for (k = 0; k < LM_N_ROW_NAME_KEYS; k++) {
				nm = hv_fetch(rh, lm_row_name_keys[k],
				              (I32)strlen(lm_row_name_keys[k]), 0);
				if (nm && *nm && SvOK(*nm)) break;
				nm = NULL;
			}
			if (nm && *nm && SvOK(*nm)) {
				STRLEN l; const char *restrict s = SvPV(*nm, l);
				row_names[i] = savepvn(s, l);
			} else {
				char buf[32];
				snprintf(buf, sizeof buf, "%lu", (unsigned long)(i + 1));
				row_names[i] = savepv(buf);
			}
		}
	} else { Safefree(fbuf); croak("%s: Data must be an Array or Hash reference", fname); }

	*data_hoa_out   = data_hoa;
	*row_hashes_out = row_hashes;
	*row_names_out  = row_names;
	return n;
}

/* Stage one of formula handling: copy the formula with whitespace removed, split
 * it at '~', and take the intercept markers out of the right-hand side.
 *
 * R accepts several spellings of "no intercept" -- a trailing `- 1`, `+ 0`, or a
 * leading `0 +` -- as well as `+ 1` and a leading `1 +` for the intercept that
 * would be there anyway; all of them are recognised. The scan steps over
 * `I(...)` so the `-1` inside `I(x-1)` stays where it is instead of being read
 * as intercept suppression, and the buffer grows with the formula rather than
 * being a fixed size a long model can overrun.
 *
 * Returns a Newx buffer the caller must Safefree; *lhs_out and *rhs_out point
 * into it, so it has to outlive the last use of the response name. Runs before
 * any data is read, so a croak here has nothing to clean up but its own copy. */
static char *lm_formula_split(pTHX_ const char *restrict formula,
                              const char *restrict fname,
                              char *restrict *restrict lhs_out,
                              char *restrict *restrict rhs_out,
                              bool *restrict has_intercept) {
	char *restrict f_cpy = NULL;
	char *restrict src, *restrict dst, *restrict tilde, *restrict rhs, *restrict p_idx;

	Newx(f_cpy, strlen(formula) + 1, char);
	src = (char*)formula; dst = f_cpy;
	while (*src) { if (!isspace((unsigned char)*src)) *dst++ = *src; src++; }
	*dst = '\0';

	tilde = strchr(f_cpy, '~');
	if (!tilde) {
		Safefree(f_cpy);
		croak("%s: invalid formula, missing '~'", fname);
	}
	*tilde = '\0';
	rhs = tilde + 1;
	*lhs_out = f_cpy;
	*rhs_out = rhs;
	*has_intercept = TRUE;

	p_idx = rhs;
	while (*p_idx) {
		if (p_idx[0] == 'I' && p_idx[1] == '(') {
			int depth = 0;
			while (*p_idx) { if (*p_idx == '(') depth++; else if (*p_idx == ')') { depth--; if (depth == 0) { p_idx++; break; } } p_idx++; }
			continue;
		}
		if (p_idx[0] == '-' && p_idx[1] == '1' &&
			(p_idx[2] == '\0' || p_idx[2] == '+' || p_idx[2] == '-')) {
			*has_intercept = FALSE;
			memmove(p_idx, p_idx + 2, strlen(p_idx + 2) + 1);
			continue;
		}
		if (p_idx[0] == '+' && p_idx[1] == '0' &&
			(p_idx[2] == '\0' || p_idx[2] == '+' || p_idx[2] == '-')) {
			*has_intercept = FALSE;
			memmove(p_idx, p_idx + 2, strlen(p_idx + 2) + 1);
			continue;
		}
		if (p_idx == rhs && p_idx[0] == '0' && p_idx[1] == '+') {
			*has_intercept = FALSE;
			memmove(p_idx, p_idx + 2, strlen(p_idx + 2) + 1);
			continue;
		}
		if (p_idx == rhs && p_idx[0] == '0' && p_idx[1] == '\0') {
			*has_intercept = FALSE; p_idx[0] = '\0'; break;
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

	/* Removing a marker can leave the '+' that joined it behind. */
	while ((p_idx = strstr(rhs, "++")) != NULL)
		memmove(p_idx, p_idx + 1, strlen(p_idx + 1) + 1);
	if (rhs[0] == '+') memmove(rhs, rhs + 1, strlen(rhs + 1) + 1);
	{
		size_t len_rhs = strlen(rhs);
		if (len_rhs > 0 && rhs[len_rhs - 1] == '+') rhs[len_rhs - 1] = '\0';
	}
	return f_cpy;
}

/* Stage two: turn the cleaned right-hand side into the term list the design
 * matrix is built from. '.' expands to every column except the response and any
 * row-name column; `a*b` expands to its main effects and interactions; repeated
 * terms are dropped, as R's formula parser drops them.
 *
 * Needs the data, hence the split from lm_formula_split(): '.' cannot be
 * expanded until the columns are known. rhs is consumed in place (strtok).
 * *terms_out and *uniq_out come back as Newx arrays of savepv'd strings; the
 * caller frees the strings and then the arrays. */
static void lm_formula_terms(pTHX_ char *restrict rhs, const char *restrict lhs,
                             HV *restrict data_hoa, HV **restrict row_hashes,
                             size_t n, bool has_intercept,
                             const char *restrict fname,
                             char **restrict *restrict terms_out,
                             unsigned int *restrict num_terms_out,
                             char **restrict *restrict uniq_out,
                             unsigned int *restrict num_uniq_out) {
	char **restrict terms = NULL, **restrict uniq_terms = NULL;
	unsigned int term_cap = 64, num_terms = 0, num_uniq = 0, i, j;
	char *rhs_expanded = NULL;
	char *restrict chunk;
	size_t rhs_len = 0, rhs_cap = 1;

	Newxz(rhs_expanded, 1, char);
	chunk = strtok(rhs, "+");
	while (chunk != NULL) {
		if (strcmp(chunk, ".") == 0) {
			AV *restrict cols = get_all_columns(aTHX_ data_hoa, row_hashes, n);
			for (SSize_t c = 0; c <= av_len(cols); c++) {
				SV **restrict col_sv = av_fetch(cols, c, 0);
				if (col_sv && *col_sv && SvOK(*col_sv)) {
					STRLEN cl;
					const char *restrict col_name = SvPV(*col_sv, cl);
					if (strcmp(col_name, lhs) != 0 && !lm_is_row_name_key(col_name, cl))
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
	if (has_intercept) terms[num_terms++] = savepv("Intercept");

	if (rhs_len > 0) {
		chunk = strtok(rhs_expanded, "+");
		while (chunk != NULL) {
			if (num_terms >= term_cap - 3) {
				term_cap *= 2;
				Renew(terms, term_cap, char*); Renew(uniq_terms, term_cap, char*);
			}
			lm_expand_cross(aTHX_ chunk, fname, &terms, &num_terms, &term_cap);
			chunk = strtok(NULL, "+");
		}
	}
	Safefree(rhs_expanded);

	for (i = 0; i < num_terms; i++) {
		bool found = FALSE;
		for (j = 0; j < num_uniq; j++)
			if (strcmp(terms[i], uniq_terms[j]) == 0) { found = TRUE; break; }
		if (!found) uniq_terms[num_uniq++] = savepv(terms[i]);
	}

	*terms_out    = terms;      *num_terms_out = num_terms;
	*uniq_out     = uniq_terms; *num_uniq_out  = num_uniq;
}

typedef int (*cs_cmp_fn)(pTHX_ void *restrict ctx, size_t i, size_t j);

/* Sort by a named column: pre-fetched cell SVs plus a numeric/string flag. */
typedef struct {
	SV **restrict vals;	/* borrowed cell SV* per row (NULL == missing) */
	unsigned short numeric;	/* 1 => compare with SvNV, 0 => compare with sv_cmp */
} cs_col_ctx;

/* Sort by a user comparator: per-row refs handed to $a/$b before each call. */
typedef struct {
	SV **restrict rows;	// row ref per index (RV to HV)
	CV  *restrict cv;	// the comparator
	SV  *a_sv;		// scalar currently aliased to package $a
	SV  *b_sv;		// scalar currently aliased to package $b
} cs_code_ctx;

static int cs_col_cmp(pTHX_ void *restrict vctx, size_t i, size_t j) {
	cs_col_ctx *restrict c = (cs_col_ctx *)vctx;
	SV *restrict av = c->vals[i];
	SV *restrict bv = c->vals[j];
	int a_ok = (av && SvOK(av));
	int b_ok = (bv && SvOK(bv));
	if (!a_ok || !b_ok) { // undef/missing always sorts last
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
	// alias the two rows into the comparator's $a / $b
	sv_setsv(c->a_sv, c->rows[i]);
	sv_setsv(c->b_sv, c->rows[j]);
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	// sort comparators read $a/$b, not @_, so we push no arguments
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
	// skip the merge when the halves are already in order
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
	GV *restrict agv = gv_fetchpv(buf, GV_ADD, SVt_PV);
	buf[plen + 2] = 'b';
	GV *restrict bgv = gv_fetchpv(buf, GV_ADD, SVt_PV);

	SAVESPTR(GvSV(agv));
	SAVESPTR(GvSV(bgv));
	SV *restrict a_sv = sv_newmortal();
	SV *restrict b_sv = sv_newmortal();
	GvSV(agv) = a_sv;
	GvSV(bgv) = b_sv;
	*a_out = a_sv;
	*b_out = b_sv;
}

/* ---- 1. NEW: shape tag for input/output (put beside the ctx structs) -- */
typedef enum { CS_AOH = 0, CS_HOA = 1, CS_AOA = 2 } cs_shape;

/* ---- 2. NEW: comparator undef-probe (put right after cs_code_cmp) ---- */
/* ---- undef-last for comparator mode -------------------------------------
 * A comparator is opaque: csort can't see which column it keys on, so it
 * can't read undef-ness off the data the way column mode does.  Instead we
 * probe each row once, comparing it against itself; a comparator that reads
 * an undef value raises an "uninitialized" warning (or dies, under fatal
 * warnings).  We trap that here.  Rows that trip it are moved to the end (in
 * stable order); the rest are sorted normally and never see an undef, so the
 * user's comparator runs cleanly even under `use warnings FATAL => 'all'`.
 *
 * __cs_uninit_catcher is installed as $SIG{__WARN__} for the probe only; it
 * flags $Stats::LikeR::_cs_uninit on an uninitialized warning and passes any
 * other warning through.  (Both the flag and catcher are interpreter-local.)
 */
XS(cs_uninit_catcher);
XS(cs_uninit_catcher) {
	dXSARGS;
	if (items >= 1) {
		STRLEN l;
		const char *restrict m = SvPV(ST(0), l);
		if (strstr(m, "uninitialized"))
			sv_setiv(get_sv("Stats::LikeR::_cs_uninit", GV_ADD), 1);
		else
			warn("%s", m);		/* pass unrelated warnings through */
	}
	XSRETURN_EMPTY;
}

static int cs_row_touches_undef(pTHX_ cs_code_ctx *restrict c, size_t i) {
	sv_setsv(c->a_sv, c->rows[i]);
	sv_setsv(c->b_sv, c->rows[i]);

	SV *restrict flag = get_sv("Stats::LikeR::_cs_uninit", GV_ADD);
	sv_setiv(flag, 0);
	CV *restrict catcher = get_cv("Stats::LikeR::__cs_uninit_catcher", 0);

	dSP;
	ENTER;
	SAVETMPS;
	if (catcher) {
		/* install our $SIG{__WARN__} for the probe; the save stack restores
		 * the previous hook (and frees ours) on LEAVE *and* on croak-unwind */
		SAVESPTR(PL_warnhook);
		PL_warnhook = newRV_inc((SV *)catcher);
		SAVEFREESV(PL_warnhook);
	}
	PUSHMARK(SP);
	int count = call_sv((SV *)c->cv, G_SCALAR | G_NOARGS | G_EVAL);
	SPAGAIN;
	if (count) (void)POPs;
	PUTBACK;

	int undef = SvTRUE(flag) ? 1 : 0;
	if (SvTRUE(ERRSV)) {
		STRLEN el;
		const char *restrict em = SvPV(ERRSV, el);
		if (strstr(em, "uninitialized")) {
			undef = 1;
			sv_setsv(ERRSV, &PL_sv_no);	/* clear $@ */
		} else {
			/* a genuine error from the comparator: propagate it verbatim.
			 * croak reads the string now; the die unwinds the save stack,
			 * which restores PL_warnhook for us. */
			croak("%s", em);
		}
	}
	FREETMPS;
	LEAVE;
	return undef;
}

static SV *cs_materialize(pTHX_ cs_shape out_shape, cs_shape in_shape,
                          AV *restrict src_av,
                          SV **restrict colkeys, AV **restrict colavs,
                          size_t ncols, size_t *restrict idx, size_t n) {
	if (out_shape == CS_AOA) {/* output: AoA */
		AV *restrict out = newAV();
		if (n) av_extend(out, (SSize_t)n - 1);
		if (in_shape == CS_AOA) {
			/* AoA -> AoA: reorder, sharing the original row arrayrefs */
			for (size_t k = 0; k < n; k++) {
				SV **restrict rp = av_fetch(src_av, (SSize_t)idx[k], 0);
				SV *restrict row = (rp && *rp) ? *rp : &PL_sv_undef;
				av_push(out, SvREFCNT_inc_simple_NN(row));
			}
			return newRV_noinc((SV *)out);
		}
		if (in_shape == CS_HOA) {
			/* HoA -> AoA: positional rows ordered by sorted column-key name
			 * (hash iteration order is randomized, so sort for determinism) */
			size_t *restrict ord;
			Newx(ord, ncols ? ncols : 1, size_t);
			SAVEFREEPV(ord);
			for (size_t c = 0; c < ncols; c++) ord[c] = c;
			for (size_t a = 1; a < ncols; a++) {
				size_t o = ord[a];
				STRLEN al; const char *restrict ap = SvPV_const(colkeys[o], al);
				SSize_t b = (SSize_t)a - 1;
				while (b >= 0) {
					STRLEN bl;
					const char *restrict bp = SvPV_const(colkeys[ord[b]], bl);
					int cmp = memcmp(bp, ap, bl < al ? bl : al);
					if (cmp == 0) cmp = (bl > al) - (bl < al);
					if (cmp <= 0) break;
					ord[b + 1] = ord[b];
					b--;
				}
				ord[b + 1] = o;
			}
			for (size_t k = 0; k < n; k++) {
				AV *restrict row = newAV();
				if (ncols) av_extend(row, (SSize_t)ncols - 1);
				for (size_t c = 0; c < ncols; c++) {
					SV **restrict cp =
					        av_fetch(colavs[ord[c]], (SSize_t)idx[k], 0);
					av_push(row, (cp && *cp) ? newSVsv(*cp) : newSV(0));
				}
				av_push(out, newRV_noinc((SV *)row));
			}
			return newRV_noinc((SV *)out);
		}
		// AoH -> AoA: union of keys (first appearance) -> positional rows
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
		/* positional columns need a deterministic order: sort the union of
		 * keys by name (the keylist AV keeps them alive; korder just points) */
		SV **restrict korder;
		Newx(korder, (size_t)(nk > 0 ? nk : 1), SV *);
		SAVEFREEPV(korder);
		for (SSize_t c = 0; c < nk; c++) korder[c] = *av_fetch(keylist, c, 0);
		for (SSize_t a = 1; a < nk; a++) {
			SV *restrict key = korder[a];
			STRLEN al; const char *restrict ap = SvPV_const(key, al);
			SSize_t b = a - 1;
			while (b >= 0) {
				STRLEN bl; const char *restrict bp = SvPV_const(korder[b], bl);
				int cmp = memcmp(bp, ap, bl < al ? bl : al);
				if (cmp == 0) cmp = (bl > al) - (bl < al);
				if (cmp <= 0) break;
				korder[b + 1] = korder[b];
				b--;
			}
			korder[b + 1] = key;
		}
		for (size_t k = 0; k < n; k++) {
			AV *restrict row = newAV();
			if (nk > 0) av_extend(row, nk - 1);
			SV **restrict rp = av_fetch(src_av, (SSize_t)idx[k], 0);
			HV *restrict rh = (rp && *rp && SvROK(*rp)
			        && SvTYPE(SvRV(*rp)) == SVt_PVHV) ? (HV *)SvRV(*rp) : NULL;
			for (SSize_t c = 0; c < nk; c++) {
				SV *restrict cell = NULL;
				if (rh) {
					HE *restrict he = hv_fetch_ent(rh, korder[c], 0, 0);
					if (he) cell = HeVAL(he);
				}
				av_push(row, cell ? newSVsv(cell) : newSV(0));
			}
			av_push(out, newRV_noinc((SV *)row));
		}
		return newRV_noinc((SV *)out);
	}
	if (out_shape == CS_AOH) {/* output: AoH  */
		AV *restrict out = newAV();
		if (n) av_extend(out, (SSize_t)n - 1);

		if (in_shape == CS_AOH) {// AoH -> AoH: reorder, sharing the original row hashrefs */
			for (size_t k = 0; k < n; k++) {
				SV **restrict rp = av_fetch(src_av, (SSize_t)idx[k], 0);
				SV *restrict row = (rp && *rp) ? *rp : &PL_sv_undef;
				av_push(out, SvREFCNT_inc_simple_NN(row));
			}
			return newRV_noinc((SV *)out);
		}
		if (in_shape == CS_HOA) {
			/* HoA -> AoH: synthesize one hashref per row (copied cells) */
			for (size_t k = 0; k < n; k++) {
				HV *restrict rh = newHV();
				for (size_t c = 0; c < ncols; c++) {
					SV **restrict cp = av_fetch(colavs[c], (SSize_t)idx[k], 0);
					hv_store_ent(rh, colkeys[c],
					             (cp && *cp) ? newSVsv(*cp) : newSV(0), 0);
				}
				av_push(out, newRV_noinc((SV *)rh));
			}
			return newRV_noinc((SV *)out);
		}
		/* AoA -> AoH: keys are the integer indices "0".."ncols-1" */
		for (size_t k = 0; k < n; k++) {
			HV *restrict rh = newHV();
			SV **restrict rp = av_fetch(src_av, (SSize_t)idx[k], 0);
			AV *restrict row = (rp && *rp && SvROK(*rp)
			        && SvTYPE(SvRV(*rp)) == SVt_PVAV) ? (AV *)SvRV(*rp) : NULL;
			for (size_t c = 0; c < ncols; c++) {
				SV **restrict cp = row ? av_fetch(row, (SSize_t)c, 0) : NULL;
				char kb[24];
				int kl = snprintf(kb, sizeof kb, "%zu", c);
				(void)hv_store(rh, kb, (I32)kl,
				               (cp && *cp) ? newSVsv(*cp) : newSV(0), 0);
			}
			av_push(out, newRV_noinc((SV *)rh));
		}
		return newRV_noinc((SV *)out);
	}
	// output: HoA
	HV *restrict out = newHV();
	if (in_shape == CS_HOA) {// HoA -> HoA: permute every column in lockstep (copied cells)
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
	if (in_shape == CS_AOA) {// AoA -> HoA: keys "0".."ncols-1", columns permuted (copied cells)
		for (size_t c = 0; c < ncols; c++) {
			AV *restrict ncol = newAV();
			if (n) av_extend(ncol, (SSize_t)n - 1);
			for (size_t k = 0; k < n; k++) {
				SV **restrict rp = av_fetch(src_av, (SSize_t)idx[k], 0);
				SV *restrict cell = NULL;
				if (rp && *rp && SvROK(*rp)
				        && SvTYPE(SvRV(*rp)) == SVt_PVAV) {
					SV **restrict cp = av_fetch((AV *)SvRV(*rp), (SSize_t)c, 0);
					if (cp && *cp) cell = *cp;
				}
				av_push(ncol, cell ? newSVsv(cell) : newSV(0));
			}
			char kb[24];
			int kl = snprintf(kb, sizeof kb, "%zu", c);
			(void)hv_store(out, kb, (I32)kl, newRV_noinc((SV *)ncol), 0);
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

#ifndef M_LN_SQRT_2PI
#define M_LN_SQRT_2PI 0.918938533204672741780329736406  /* log(sqrt(2*pi)) */
#endif
#ifndef M_LN_2PI
#define M_LN_2PI      1.837877066409345483560659472811  /* log(2*pi) */
#endif
#ifndef DBL_MIN
#define DBL_MIN 2.2250738585072014e-308
#endif

/* Stirling's error  stirlerr(n) = log(n!) - log( sqrt(2*pi*n) * (n/e)^n )
 * (Catherine Loader 2000; same table + series R uses) */
static NV bt_stirlerr(NV n) {
	static const NV S0 = 0.083333333333333333333;        /* 1/12   */
	static const NV S1 = 0.00277777777777777777778;      /* 1/360  */
	static const NV S2 = 0.00079365079365079365079365;   /* 1/1260 */
	static const NV S3 = 0.000595238095238095238095238;  /* 1/1680 */
	static const NV S4 = 0.0008417508417508417508417508; /* 1/1188 */
	static const NV halves[31] = {
		0.0,                            /* 0.0 (placeholder; unreachable here) */
		0.1534264097200273452913848,    /* 0.5  */
		0.0810614667953272582196702,    /* 1.0  */
		0.0548141210519176538961390,    /* 1.5  */
		0.0413406959554092940938221,    /* 2.0  */
		0.03316287351993628748511048,   /* 2.5  */
		0.02767792568499833914878929,   /* 3.0  */
		0.02374616365629749597132920,   /* 3.5  */
		0.02079067210376509311152277,   /* 4.0  */
		0.01848845053267318523077934,   /* 4.5  */
		0.01664469118982119216319487,   /* 5.0  */
		0.01513497322191737887351255,   /* 5.5  */
		0.01387612882307074799874573,   /* 6.0  */
		0.01281046524292022692424986,   /* 6.5  */
		0.01189670994589177009505572,   /* 7.0  */
		0.01110455975820691732662991,   /* 7.5  */
		0.010411265261972096497478567,  /* 8.0  */
		0.009799416126158803298389475,  /* 8.5  */
		0.009255462182712732917728637,  /* 9.0  */
		0.008768700134139385462952823,  /* 9.5  */
		0.008330563433362871256469318,  /* 10.0 */
		0.007934114564314020547248100,  /* 10.5 */
		0.007573675487951840794972024,  /* 11.0 */
		0.007244554301320383179543912,  /* 11.5 */
		0.006942840107209529865664152,  /* 12.0 */
		0.006665247032707682442354394,  /* 12.5 */
		0.006408994188004207068439631,  /* 13.0 */
		0.006171712263039457647532867,  /* 13.5 */
		0.005951370112758847735624416,  /* 14.0 */
		0.005746216513010115682023589,  /* 14.5 */
		0.005554733551962801371038690   /* 15.0 */
	};
	NV nn;
	if (n <= 15.0) {
		nn = n + n;
		if (nn == floor(nn)) return halves[(int)nn];
		return lgamma(n + 1.0) - (n + 0.5) * log(n) + n - M_LN_SQRT_2PI;
	}
	nn = n * n;
	if (n > 500.0) return (S0 - S1 / nn) / n;
	if (n >  80.0) return (S0 - (S1 - S2 / nn) / nn) / n;
	if (n >  35.0) return (S0 - (S1 - (S2 - S3 / nn) / nn) / nn) / n;
	return (S0 - (S1 - (S2 - (S3 - S4 / nn) / nn) / nn) / nn) / n;
}

/* Deviance term  bd0(x, np) = x*log(x/np) + np - x, summed as a Taylor series
 * when x is close to np to avoid catastrophic cancellation. */
static NV bt_bd0(NV x, NV np) {
	if (np == 0.0) return 0.0;            /* unreachable: callers guarantee np > 0 */
	if (fabs(x - np) < 0.1 * (x + np)) {
		NV v = (x - np) / (x + np);
		NV s = (x - np) * v;
		if (fabs(s) < DBL_MIN) return s;
		NV ej = 2.0 * x * v;
		v *= v;
		for (int j = 1; ; j++) {          /* |v| < 0.1, so this converges quickly */
			ej *= v;
			NV s1 = s + ej / (NV)(2 * j + 1);
			if (s1 == s) return s1;
			s = s1;
		}
	}
	return x * log(x / np) + np - x;
}

/* Binomial PMF via R's dbinom_raw (q = 1 - p), in log form.  The plain form
 * below is exp() of this, so the two cannot drift apart; the log form is what
 * the hypergeometric density wants, since a term there can be 1e-178. */
static NV bt_dbinom_raw_log(NV x, NV n, NV p, NV q) {
	if (p == 0.0) return (x == 0.0) ? 0.0 : -INFINITY;
	if (q == 0.0) return (x == n)   ? 0.0 : -INFINITY;
	if (x == 0.0) {
		if (n == 0.0) return 0.0;
		return (p < 0.1) ? -bt_bd0(n, n * q) - n * p : n * log(q);
	}
	if (x == n) return (q < 0.1) ? -bt_bd0(n, n * p) - n * q : n * log(p);
	if (x < 0.0 || x > n) return -INFINITY;
	NV lc = bt_stirlerr(n) - bt_stirlerr(x) - bt_stirlerr(n - x)
	      - bt_bd0(x, n * p) - bt_bd0(n - x, n * q);
	NV lf = M_LN_2PI + log(x) + log1p(-x / n); // better than log(n-x)-log(n) for x<<n
	return lc - 0.5 * lf;
}

static NV bt_dbinom_raw(NV x, NV n, NV p, NV q) {
	return exp(bt_dbinom_raw_log(x, n, p, q));
}

static NV bt_dbinom(long x, long n, NV p) {
	if (x < 0 || x > n) return 0.0;
	return bt_dbinom_raw((NV)x, (NV)n, p, 1.0 - p);
}

/* Lower tail P(X <= k) = I_{1-p}(n-k, k+1); upper P(X > k) = I_p(k+1, n-k) */
static NV bt_pbinom_lower(long k, long n, NV p) {
	if (k < 0)  return 0.0;
	if (k >= n) return 1.0;
	return incbeta((NV)(n - k), (NV)(k + 1), 1.0 - p);
}
static NV bt_pbinom_upper(long k, long n, NV p) {
	if (k < 0)  return 1.0;
	if (k >= n) return 0.0;
	return incbeta((NV)(k + 1), (NV)(n - k), p);
}

/* Inverse regularized incomplete beta (R's qbeta): incbeta is monotone in x,
 * so safeguarded bisection converges to full double precision. */
static NV bt_qbeta(NV alpha, NV a, NV b) {
	if (alpha <= 0.0) return 0.0;
	if (alpha >= 1.0) return 1.0;
	NV lo = 0.0, hi = 1.0, mid = 0.5;
	for (unsigned short int i = 0; i < 200; i++) {
		mid = 0.5 * (lo + hi);
		if (incbeta(a, b, mid) < alpha) lo = mid; else hi = mid;
		if (hi - lo < 1e-15) break;
	}
	return 0.5 * (lo + hi);
}

/* Clopper-Pearson endpoints (R's p.L / p.U) */
static NV bt_pL(NV alpha, long x, long n) {
	if (x == 0) return 0.0;
	return bt_qbeta(alpha, (NV)x, (NV)(n - x + 1));
}
static NV bt_pU(NV alpha, long x, long n) {
	if (x == n) return 1.0;
	return bt_qbeta(1.0 - alpha, (NV)(x + 1), (NV)(n - x));
}

// Validate one count argument: a nonnegative integer
static long bt_check_count(pTHX_ SV *sv, const char *what) {
	if (!sv || !SvOK(sv)) croak("binom_test: %s is undef", what);
	if (!looks_like_number(sv)) croak("binom_test: %s is not a number", what);
	NV v = SvNV(sv);
	NV r = floor(v + 0.5);
	if (v < 0 || fabs(v - r) > 1e-7)
		croak("binom_test: %s must be a nonnegative integer", what);
	return (long)r;
}
/*
 * Studentized range distribution (Tukey's) -- ptukey() / qtukey().
 *
 * Faithful C port of R's src/nmath/{ptukey,qtukey}.c (Copenhaver &
 * Holland 1988), the exact algorithm underlying R's TukeyHSD.  The only
 * substitutions are approx_pnorm() for pnorm() (both are 0.5*erfc based,
 * so identical to machine precision) and the libc lgamma() for
 * lgammafn().  Internals are kept in plain double / long double exactly
 * as upstream so results are bit-faithful regardless of Perl's NV width.
 *
 *   st_wprob(w, rr, cc)          integral of Hartley's range over (0,w)
 *   st_ptukey(q, rr, cc, df)     lower-tail P(range < q)
 *   st_qinv(p, c, v)             AS 70 initial estimate for the secant
 *   st_qtukey(p, rr, cc, df)     inverse of st_ptukey via secant method
 *
 * rr = number of groups/ranges (1 for a single ANOVA factor),
 * cc = number of means, df = residual degrees of freedom.
  */
static NV st_wprob(NV w, NV rr, NV cc)
{
#define TK_NLEG  12
#define TK_IHALF 6
	const double C1 = -30.0, C2 = -50.0, C3 = 60.0;
	const double bb = 8.0, wlar = 3.0, wincr1 = 2.0, wincr2 = 3.0;
	static const double xleg[TK_IHALF] = {
		0.981560634246719250690549090149,
		0.904117256370474856678465866119,
		0.769902674194304687036893833213,
		0.587317954286617447296702418941,
		0.367831498998180193752691536644,
		0.125233408511468915472441369464
	};
	static const double aleg[TK_IHALF] = {
		0.047175336386511827194615961485,
		0.106939325995318430960254718194,
		0.160078328543346226334652529543,
		0.203167426723065921749064455810,
		0.233492536538354808760849898925,
		0.249147045813402785000562436043
	};
	double a, ac, pr_w, b, binc, c, cc1,
		pminus, pplus, qexpo, qsqz, rinsum, wi, wincr, xx;
	long double blb, bub, einsum, elsum;
	int j, jj;

	qsqz = w * 0.5;
	if (qsqz >= bb) return 1.0;

	pr_w = 2.0 * approx_pnorm(qsqz) - 1.0;
	if (pr_w >= exp(C2 / cc)) pr_w = pow(pr_w, cc);
	else                      pr_w = 0.0;

	if (w > wlar) wincr = wincr1;
	else          wincr = wincr2;

	blb = qsqz;
	binc = (bb - qsqz) / wincr;
	bub = blb + binc;
	einsum = 0.0;
	cc1 = cc - 1.0;

	for (wi = 1; wi <= wincr; wi++) {
		elsum = 0.0;
		a = (double)(0.5 * (bub + blb));
		b = (double)(0.5 * (bub - blb));
		for (jj = 1; jj <= TK_NLEG; jj++) {
			if (TK_IHALF < jj) { j = (TK_NLEG - jj) + 1; xx = xleg[j - 1]; }
			else               { j = jj;                 xx = -xleg[j - 1]; }
			c = b * xx;
			ac = a + c;
			qexpo = ac * ac;
			if (qexpo > C3) break;
			pplus  = 2.0 * approx_pnorm(ac);
			pminus = 2.0 * approx_pnorm(ac - w);
			rinsum = (pplus * 0.5) - (pminus * 0.5);
			if (rinsum >= exp(C1 / cc1)) {
				rinsum = (aleg[j - 1] * exp(-(0.5 * qexpo))) * pow(rinsum, cc1);
				elsum += rinsum;
			}
		}
		elsum *= (((2.0 * b) * cc) * M_1_SQRT_2PI);
		einsum += elsum;
		blb = bub;
		bub += binc;
	}
	pr_w += (double) einsum;
	if (pr_w <= exp(C1 / rr)) return 0.0;
	pr_w = pow(pr_w, rr);
	if (pr_w >= 1.0) return 1.0;
	return pr_w;
#undef TK_NLEG
#undef TK_IHALF
}

static NV st_ptukey(NV q, NV rr, NV cc, NV df){
#define TK_NLEGQ  16
#define TK_IHALFQ 8
	const double eps1 = -30.0, eps2 = 1.0e-14;
	const double dhaf = 100.0, dquar = 800.0, deigh = 5000.0, dlarg = 25000.0;
	const double ulen1 = 1.0, ulen2 = 0.5, ulen3 = 0.25, ulen4 = 0.125;
	static const double xlegq[TK_IHALFQ] = {
		0.989400934991649932596154173450,
		0.944575023073232576077988415535,
		0.865631202387831743880467897712,
		0.755404408355003033895101194847,
		0.617876244402643748446671764049,
		0.458016777657227386342419442984,
		0.281603550779258913230460501460,
		0.950125098376374401853193354250e-1
	};
	static const double alegq[TK_IHALFQ] = {
		0.271524594117540948517805724560e-1,
		0.622535239386478928628438369944e-1,
		0.951585116824927848099251076022e-1,
		0.124628971255533872052476282192,
		0.149595988816576732081501730547,
		0.169156519395002538189312079030,
		0.182603415044923588866763667969,
		0.189450610455068496285396723208
	};
	double ans, f2, f21, f2lf, ff4, otsum, qsqz, rotsum, t1, twa1, ulen, wprb;
	int i, j, jj;

	if (q <= 0.0) return 0.0;
	if (df < 2.0 || rr < 1.0 || cc < 2.0) return NAN;
	if (!isfinite(q)) return 1.0;
	if (df > dlarg) return st_wprob(q, rr, cc);

	f2 = df * 0.5;
	f2lf = ((f2 * log(df)) - (df * M_LN2)) - lgamma(f2);
	f21 = f2 - 1.0;
	ff4 = df * 0.25;
	if      (df <= dhaf)  ulen = ulen1;
	else if (df <= dquar) ulen = ulen2;
	else if (df <= deigh) ulen = ulen3;
	else                  ulen = ulen4;
	f2lf += log(ulen);
	ans = 0.0;

	for (i = 1; i <= 50; i++) {
		otsum = 0.0;
		twa1 = (2 * i - 1) * ulen;
		for (jj = 1; jj <= TK_NLEGQ; jj++) {
			if (TK_IHALFQ < jj) {
				j = jj - TK_IHALFQ - 1;
				t1 = (f2lf + (f21 * log(twa1 + (xlegq[j] * ulen))))
					- (((xlegq[j] * ulen) + twa1) * ff4);
			} else {
				j = jj - 1;
				t1 = (f2lf + (f21 * log(twa1 - (xlegq[j] * ulen))))
					+ (((xlegq[j] * ulen) - twa1) * ff4);
			}
			if (t1 >= eps1) {
				if (TK_IHALFQ < jj)
					qsqz = q * sqrt(((xlegq[j] * ulen) + twa1) * 0.5);
				else
					qsqz = q * sqrt(((-(xlegq[j] * ulen)) + twa1) * 0.5);
				wprb = st_wprob(qsqz, rr, cc);
				rotsum = (wprb * alegq[j]) * exp(t1);
				otsum += rotsum;
			}
		}
		if (i * ulen >= 1.0 && otsum <= eps2) break;
		ans += otsum;
	}
	if (ans > 1.0) ans = 1.0;
	return ans;
#undef TK_NLEGQ
#undef TK_IHALFQ
}

static NV st_qinv(NV p, NV c, NV v)
{
	const double p0 = 0.322232421088,    q0 = 0.993484626060e-01;
	const double p1 = -1.0,              q1 = 0.588581570495;
	const double p2 = -0.342242088547,   q2 = 0.531103462366;
	const double p3 = -0.204231210125,   q3 = 0.103537752850;
	const double p4 = -0.453642210148e-04, q4 = 0.38560700634e-02;
	const double c1 = 0.8832, c2 = 0.2368, c3 = 1.214, c4 = 1.208, c5 = 1.4142;
	const double vmax = 120.0;
	double ps, qq, t, yi;

	ps = 0.5 - 0.5 * p;
	yi = sqrt(log(1.0 / (ps * ps)));
	t = yi + (((( yi * p4 + p3) * yi + p2) * yi + p1) * yi + p0)
		/ (((( yi * q4 + q3) * yi + q2) * yi + q1) * yi + q0);
	if (v < vmax) t += (t * t * t + t) / v / 4.0;
	qq = c1 - c2 * t;
	if (v < vmax) qq += -c3 / v + c4 * t / v;
	return t * (qq * log(c - 1.0) + c5);
}

static NV st_qtukey(NV p, NV rr, NV cc, NV df)
{
	const double eps = 0.0001;
	const int maxiter = 50;
	double ans = 0.0, valx0, valx1, x0, x1, xabs;
	int iter;

	if (df < 2.0 || rr < 1.0 || cc < 2.0) return NAN;
	if (p <= 0.0) return 0.0;
	if (p >= 1.0) return INFINITY;

	x0 = st_qinv(p, cc, df);
	valx0 = st_ptukey(x0, rr, cc, df) - p;
	if (valx0 > 0.0) x1 = fmax(0.0, x0 - 1.0);
	else             x1 = x0 + 1.0;
	valx1 = st_ptukey(x1, rr, cc, df) - p;

	for (iter = 1; iter < maxiter; iter++) {
		ans = x1 - ((valx1 * (x1 - x0)) / (valx1 - valx0));
		valx0 = valx1;
		x0 = x1;
		if (ans < 0.0) { ans = 0.0; valx1 = -p; }
		valx1 = st_ptukey(ans, rr, cc, df) - p;
		x1 = ans;
		xabs = fabs(x1 - x0);
		if (xabs < eps) return ans;
	}
	return ans; /* did not converge in maxiter; best estimate */
}

/*
 * Shared engines for the set-operation XSUBs. Each pushes its result list
 * (or a single count in scalar context) onto the Perl stack and returns the
 * updated stack pointer, so callers use:  sp = helper(aTHX_ sp, ...);
 * XPUSHs/EXTEND operate on the local `sp`, hence the in/out pointer.
 */

/* Backs is_equivalent(). Returns 1 iff all `nrefs` array refs share one
 * distinct-value set (multiplicity/order ignored), matching List::Compare's
 * is_LequivalentR() generalised to N lists; else 0. Equivalence is transitive,
 * so each ref is checked against the distinct-value set of the FIRST ref:
 * ref i matches iff it holds no value outside that set (foreign key => 0) AND
 * covers every value in it (matched == ref_size). Single pass per array;
 * memory is the first ref's set plus one reusable per-ref dedup set. */
static int set_equivalent(pTHX_ SV **restrict args, size_t nrefs, const char *name) {
	HV *restrict ref;   /* distinct values of the first array ref */
	AV *restrict av;
	size_t len;
	IV ref_size;
	if (!(SvROK(args[0]) && SvTYPE(SvRV(args[0])) == SVt_PVAV))
		croak("%s: argument index 0 of %" UVuf " total (max index %" UVuf ") is not an array reference", name, (UV)nrefs, (UV)(nrefs - 1));
	ref = (HV*)sv_2mortal((SV*)newHV());
	av  = (AV*)SvRV(args[0]);
	len = (size_t)(av_len(av) + 1);
	for (size_t j = 0; j < len; j++) {
		SV **restrict tv = av_fetch(av, j, 0);
		STRLEN klen; const char *restrict key; I32 hklen;
		if (!(tv && SvOK(*tv)))
			croak("%s: undefined value at array ref index %" UVuf " (argument 0)", name, (UV)j);
		key   = SvPV(*tv, klen);
		hklen = SvUTF8(*tv) ? -(I32)klen : (I32)klen;
		(void)hv_store(ref, key, hklen, &PL_sv_undef, 0);
	}
	ref_size = (IV)HvUSEDKEYS(ref);
	for (size_t i = 1; i < nrefs; i++) {
		HV *restrict seen; IV matched = 0;
		if (!(SvROK(args[i]) && SvTYPE(SvRV(args[i])) == SVt_PVAV))
			croak("%s: argument index %" UVuf " of %" UVuf " total (max index %" UVuf ") is not an array reference", name, (UV)i, (UV)nrefs, (UV)(nrefs - 1));
		av   = (AV*)SvRV(args[i]);
		len  = (size_t)(av_len(av) + 1);
		seen = (HV*)sv_2mortal((SV*)newHV());   /* per-ref dedup */
		for (size_t j = 0; j < len; j++) {
			SV **restrict tv = av_fetch(av, j, 0);
			STRLEN klen; const char *restrict key; I32 hklen;
			if (!(tv && SvOK(*tv)))
				croak("%s: undefined value at array ref index %" UVuf " (argument %" UVuf ")", name, (UV)j, (UV)i);
			key   = SvPV(*tv, klen);
			hklen = SvUTF8(*tv) ? -(I32)klen : (I32)klen;
			if (hv_exists(seen, key, hklen)) continue;   /* already counted for this ref */
			(void)hv_store(seen, key, hklen, &PL_sv_undef, 0);
			if (!hv_exists(ref, key, hklen)) return 0;   /* value absent from first ref */
			matched++;
		}
		if (matched != ref_size) return 0;              /* first ref has a value this ref lacks */
	}
	return 1;
}
/* Backs intersection(), Lonly() and Ronly(). For every distinct value it counts
 * how many of the input arrays contain it (per-array dedup via `loc`), building
 * the candidate list `order` from one chosen array in first-appearance order,
 * then emits the candidates whose count matches the wanted multiplicity:
 *   want_all != 0 -> count == nrefs (in every array: intersection)
 *   want_all == 0 -> count == 1     (in the chosen array and no other)
 * `from_last` picks which array supplies the candidates: the FIRST (0) for
 * intersection/Lonly, or the LAST (1) for Ronly. With want_all == 0 that makes
 * Lonly "only in the first array" and Ronly "only in the last array", so the
 * two-array Ronly(a,b) still equals Lonly(b,a). Every emitted value is present
 * in the chosen array, so drawing candidates from it is correct for all three. */
static SV** set_multiplicity(pTHX_ SV **sp, SV **restrict args, size_t nrefs,
                             int want_all, int from_last, const char *name, int gimme) {
	HV *restrict count = (HV*)sv_2mortal((SV*)newHV());
	AV *restrict order = (AV*)sv_2mortal((SV*)newAV());
	size_t n = 0, olen;
	IV want = want_all ? (IV)nrefs : 1;
	for (size_t i = 0; i < nrefs; i++) {
		SV *restrict arg = args[i];
		HV *restrict loc; AV *restrict av; size_t len;
		if (!(SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV))
			croak("%s: argument index %" UVuf " of %" UVuf " total (max index %" UVuf ") is not an array reference", name, (UV)i, (UV)nrefs, (UV)(nrefs - 1));
		av  = (AV*)SvRV(arg);
		len = (size_t)(av_len(av) + 1);
		loc = (HV*)sv_2mortal((SV*)newHV());   /* per-ref dedup */
		for (size_t j = 0; j < len; j++) {
			SV **restrict tv = av_fetch(av, j, 0);
			STRLEN klen; const char *restrict key; I32 hklen; SV **restrict cv;
			if (!(tv && SvOK(*tv)))
				croak("%s: undefined value at array ref index %" UVuf " (argument %" UVuf ")", name, (UV)j, (UV)i);
			key   = SvPV(*tv, klen);
			hklen = SvUTF8(*tv) ? -(I32)klen : (I32)klen;
			if (hv_exists(loc, key, hklen)) continue;   /* already counted for this ref */
			(void)hv_store(loc, key, hklen, &PL_sv_undef, 0);
			cv = hv_fetch(count, key, hklen, 1);
			if (cv && *cv) sv_setiv(*cv, SvOK(*cv) ? SvIV(*cv) + 1 : 1);
			if (i == (from_last ? nrefs - 1 : 0))       /* candidates: chosen ref only */
				av_push(order, newSVsv(*tv));
		}
	}
	olen = (size_t)(av_len(order) + 1);
	for (size_t oi = 0; oi < olen; oi++) {
		SV **restrict e = av_fetch(order, oi, 0);
		STRLEN klen; const char *restrict key; I32 hklen; SV **restrict cv;
		if (!(e && *e)) continue;
		key   = SvPV(*e, klen);
		hklen = SvUTF8(*e) ? -(I32)klen : (I32)klen;
		cv    = hv_fetch(count, key, hklen, 0);
		if (cv && *cv && SvIV(*cv) == want) {
			if (gimme != G_SCALAR) XPUSHs(sv_2mortal(newSVsv(*e)));
			n++;
		}
	}
	if (gimme == G_SCALAR) XPUSHs(sv_2mortal(newSVuv(n)));
	return sp;
}
/* ---- pnorm helpers: normal CDF via Cody's rational approximation ----------
 Ported from R's src/nmath/pnorm.c (Cody 1969; "_both"/lower/upper/log_p
 variants by Martin Maechler). The Cody approximation is a double-precision
 algorithm -- R itself computes pnorm in double and the coefficients carry
 only double precision -- so the core runs in `double` regardless of the NV width, and results match R to full double precision. The XS wrapper converts at the NV boundary.*/

#ifndef M_SQRT_32
#define M_SQRT_32     5.656854249492380195206754896838  /* sqrt(32) */
#endif
#ifndef M_1_SQRT_2PI
#define M_1_SQRT_2PI  0.398942280401432677939946059934  /* 1/sqrt(2*pi) */
#endif

/* d_2(x) == x/2, exactly; and R's do_del / swap_tail body macros. */
#define pn_d2(_x_)  ldexp(_x_, -1)
#define pn_do_del(X)                                                       \
	xsq = ldexp(trunc(ldexp(X, 4)), -4);                               \
	del = (X - xsq) * (X + xsq);                                       \
	if (log_p) {                                                       \
		*cum = (-xsq * pn_d2(xsq)) - pn_d2(del) + log(temp);       \
		if ((lower && x > 0.) || (upper && x <= 0.))               \
			*ccum = log1p(-exp(-xsq * pn_d2(xsq)) *            \
			              exp(-pn_d2(del)) * temp);            \
	} else {                                                           \
		*cum  = exp(-xsq * pn_d2(xsq)) * exp(-pn_d2(del)) * temp;  \
		*ccum = 1.0 - *cum;                                        \
	}
#define pn_swap_tail                                                       \
	if (x > 0.) { temp = *cum; if (lower) *cum = *ccum; *ccum = temp; }

static void c_pnorm_both(double x, double *cum, double *ccum, int i_tail, int log_p) {
	const static double a[5] = {
		2.2352520354606839287, 161.02823106855587881, 1067.6894854603709582,
		18154.981253343561249, 0.065682337918207449113
	};
	const static double b[4] = {
		47.20258190468824187, 976.09855173777669322,
		10260.932208618978205, 45507.789335026729956
	};
	const static double c[9] = {
		0.39894151208813466764, 8.8831497943883759412, 93.506656132177855979,
		597.27027639480026226, 2494.5375852903726711, 6848.1904505362823326,
		11602.651437647350124, 9842.7148383839780218, 1.0765576773720192317e-8
	};
	const static double d[8] = {
		22.266688044328115691, 235.38790178262499861, 1519.377599407554805,
		6485.558298266760755, 18615.571640885098091, 34900.952721145977266,
		38912.003286093271411, 19685.429676859990727
	};
	const static double p[6] = {
		0.21589853405795699, 0.1274011611602473639, 0.022235277870649807,
		0.001421619193227893466, 2.9112874951168792e-5, 0.02307344176494017303
	};
	const static double q[5] = {
		1.28426009614491121, 0.468238212480865118, 0.0659881378689285515,
		0.00378239633202758244, 7.29751555083966205e-5
	};
	double xden, xnum, temp, del, eps, xsq, y;
	int i, lower, upper;

	if (isnan(x)) { *cum = *ccum = x; return; }

	eps = DBL_EPSILON * 0.5;
	lower = i_tail != 1;
	upper = i_tail != 0;

	y = fabs(x);
	if (y <= 0.67448975) { /* qnorm(3/4) */
		if (y > eps) {
			xsq = x * x;
			xnum = a[4] * xsq;
			xden = xsq;
			for (i = 0; i < 3; ++i) {
				xnum = (xnum + a[i]) * xsq;
				xden = (xden + b[i]) * xsq;
			}
		} else xnum = xden = 0.0;
		temp = x * (xnum + a[3]) / (xden + b[3]);
		if (lower)  *cum  = 0.5 + temp;
		if (upper)  *ccum = 0.5 - temp;
		if (log_p) {
			if (lower)  *cum  = log(*cum);
			if (upper)  *ccum = log(*ccum);
		}
	} else if (y <= M_SQRT_32) { /* 0.674.. < |x| <= sqrt(32) ~= 5.657 */
		xnum = c[8] * y;
		xden = y;
		for (i = 0; i < 7; ++i) {
			xnum = (xnum + c[i]) * y;
			xden = (xden + d[i]) * y;
		}
		temp = (xnum + c[7]) / (xden + d[7]);
		pn_do_del(y);
		pn_swap_tail;
	} else if ((log_p && y < 1e170)
	           || (lower && -38.4674 < x && x < 8.2924)
	           || (upper && -8.2924  < x && x < 38.4674)) {
		/* |x| in the (5.657, 37.5) region */
		xsq = 1.0 / (x * x);
		xnum = p[5] * xsq;
		xden = xsq;
		for (i = 0; i < 4; ++i) {
			xnum = (xnum + p[i]) * xsq;
			xden = (xden + q[i]) * xsq;
		}
		temp = xsq * (xnum + p[4]) / (xden + q[4]);
		temp = (M_1_SQRT_2PI - temp) / y;
		pn_do_del(x);
		pn_swap_tail;
	} else { /* large |x|: probs are 0 or 1 */
		if (x > 0) { *cum  = log_p ? 0.0 : 1.0; *ccum = log_p ? -INFINITY : 0.0; }
		else       { *cum  = log_p ? -INFINITY : 0.0; *ccum = log_p ? 0.0 : 1.0; }
	}
	return;
}

#undef pn_do_del
#undef pn_swap_tail
#undef pn_d2

/* Scalar normal CDF. lower_tail / log_p as in R's pnorm(). sigma < 0 -> NaN. */
static double c_pnorm(double x, double mu, double sigma, int lower_tail, int log_p) {
	double pp, cp;
#define PN_D__0 (log_p ? -INFINITY : 0.0)
#define PN_D__1 (log_p ? 0.0 : 1.0)
#define PN_DT_0 (lower_tail ? PN_D__0 : PN_D__1)
#define PN_DT_1 (lower_tail ? PN_D__1 : PN_D__0)
	if (isnan(x) || isnan(mu) || isnan(sigma)) return x + mu + sigma;
	if (!isfinite(x) && mu == x) return NAN; /* x - mu = NaN */
	if (sigma <= 0) {
		if (sigma < 0) return NAN;
		return (x < mu) ? PN_DT_0 : PN_DT_1; /* sigma == 0 */
	}
	pp = (x - mu) / sigma;
	if (!isfinite(pp)) return (x < mu) ? PN_DT_0 : PN_DT_1;
	x = pp;
	c_pnorm_both(x, &pp, &cp, (lower_tail ? 0 : 1), log_p);
	return lower_tail ? pp : cp;
#undef PN_D__0
#undef PN_D__1
#undef PN_DT_0
#undef PN_DT_1
}
/*
 * anova() : sequential (Type-I) ANOVA table for a linear model, returned in
 *           the same shape as aov() in this module, OR an F-test comparison
 *           of two or more nested models (R's anova(m1, m2, ...) generic).
 *
 *   my $tab = anova(\%data, 'yield ~ ctrl');            # one model  -> HashRef
 *   my $tab = anova(\%data, 'len ~ supp * dose');       # one model  -> HashRef
 *   my $cmp = anova(\%data, 'y ~ a', 'y ~ a + b');      # 2+ models  -> ArrayRef
 *
 * ---- single-model form (one formula) --------------------------------------
 * Input mirrors aov(): a Hash-of-Arrays (\%h, columns) or Array-of-Hashes
 * (\@a, rows), plus a formula string 'response ~ rhs'. The RHS understands
 * '+', ':' (interaction) and '*' (factorial expansion: a*b -> a + b + a:b,
 * a*b*c -> a + b + c + a:b + a:c + b:c + a:b:c). Bare string columns are
 * treated as factors and treatment-coded (first level = reference); numeric
 * columns and I(x^2) enter as single regressors. Interactions form the
 * product of their factors' coded columns, so factor:factor uses
 * (la-1)*(lb-1) columns exactly as R's treatment contrasts do.
 *
 * The model is fit sequentially by Householder QR (apply_householder_aov)
 * and the model SS is decomposed term by term, in formula order (Type I).
 * Collinear / rank-deficient terms gracefully receive 0 df and 0 Sum Sq.
 * Rows with any missing / non-numeric response or predictor are dropped
 * listwise (R's default na.omit).
 *
 * Returns a HashRef keyed by term name (plus "Residuals"); each value is a
 * nested hash using R's column names:
 *     term        => { Df, "Sum Sq", "Mean Sq", "F value", "Pr(>F)" }
 *     Residuals   => { Df, "Sum Sq", "Mean Sq" }
 * "Mean Sq"/"F value"/"Pr(>F)" are omitted where undefined (0-df terms; the
 * Residuals row never carries an F test), matching aov()'s output.
 *
 * ---- model-comparison form (two or more formulas) -------------------------
 * anova(\%data, 'y ~ a', 'y ~ a + b', ...) fits every model and returns an
 * ArrayRef with one HashRef per model, in the order supplied, mirroring R's
 * anova(m1, m2, ...) table (columns Res.Df, RSS, Df, Sum of Sq, F, Pr(>F)):
 *     [ { "Res.Df", "RSS", formula },
 *       { "Res.Df", "RSS", "Df", "Sum of Sq", "F", "Pr(>F)", formula }, ... ]
 * The first row carries no comparison stats (nothing precedes it). For each
 * later row: Df = drop in residual df from the previous model, "Sum of Sq" =
 * drop in RSS, and F = ("Sum of Sq"/Df) / scale, where scale is the residual
 * mean square of the *largest* model in the set (smallest residual df) --
 * the common denominator R uses for the whole table. "F"/"Pr(>F)" are omitted
 * for any row whose Df is not positive (non-nested / equal-size steps).
 *
 * All models are fit on ONE shared row set: completeness is evaluated
 * listwise over the UNION of every response and predictor across every
 * formula, so the fits are always mutually comparable (unlike R, which fits
 * each model on its own na.omit and then errors if the sizes disagree).
 *
 * This form performs the F-test only. R's Chisq/LRT variant would need a
 * chi-square CDF; it can be layered on later behind a test option.
 *
 * Depends on: parse_formula(), apply_householder_aov(), pf(),
 * evaluate_term(), is_column_categorical(), get_data_string_alloc().
 */

/* A factor token may be treated as categorical only when it is a plain
 * column name (no ':' interaction, no 'I(...)' / '^' transform). */
static bool anova_is_bare(const char *restrict t) {
	return !(strchr(t, ':') || strchr(t, '(') || strchr(t, '^'));
}

/* First-appearance distinct string levels of a bare column over the rows
 * flagged complete[]. Returns count; *out gets a malloc'd array of savepv'd
 * strings (caller frees each + the array). */
static size_t anova_levels(pTHX_ HV *restrict hoa, HV **restrict rows,
		size_t n, const bool *restrict complete,
		const char *restrict var, char ***restrict out) {
	char **restrict lv = NULL;
	size_t cnt = 0, cap = 0;
	for (size_t i = 0; i < n; i++) {
		if (!complete[i]) continue;
		char *restrict s = get_data_string_alloc(aTHX_ hoa, rows, i, var);
		if (!s) continue;
		bool seen = FALSE;
		for (size_t j = 0; j < cnt; j++)
			if (strcmp(lv[j], s) == 0) { seen = TRUE; break; }
		if (seen) { Safefree(s); continue; }
		if (cnt == cap) { cap = cap ? cap * 2 : 4; Renew(lv, cap, char*); }
		lv[cnt++] = s;
	}
	*out = lv;
	return cnt;
}

/* Split str on separator `sep` at parenthesis depth 0. Returns a malloc'd
 * array of savepv'd, whitespace-trimmed tokens; empty tokens are dropped. */
static char** anova_split0(pTHX_ const char *restrict str, char sep, size_t *restrict cnt) {
	char **restrict out = NULL;
	size_t n = 0, cap = 0, depth = 0;
	const char *restrict start = str, *restrict p = str;
	for (;; p++) {
		if (*p == '(') depth++;
		else if (*p == ')') { if (depth) depth--; }
		if ((*p == sep && depth == 0) || *p == '\0') {
			const char *a = start, *b = p;
			while (a < b && isspace((unsigned char)*a)) a++;
			while (b > a && isspace((unsigned char)b[-1])) b--;
			if (b > a) {
				if (n == cap) { cap = cap ? cap * 2 : 4; Renew(out, cap, char*); }
				out[n++] = savepvn(a, (STRLEN)(b - a));
			}
			start = p + 1;
		}
		if (*p == '\0') break;
	}
	*cnt = n;
	return out;
}

/* Does s contain char c at paren depth 0? */
static int anova_has0(const char *restrict s, char c) {
	size_t d = 0;
	for (; *s; s++) {
		if (*s == '(') d++;
		else if (*s == ')') { if (d) d--; }
		else if (*s == c && d == 0) return 1;
	}
	return 0;
}

// Join f[idx[0..m-1]] with ':' into a fresh savemalloc'd string
static char* anova_joinf(pTHX_ char **restrict f, const size_t *restrict idx, size_t m) {
	size_t len = 0;
	for (size_t i = 0; i < m; i++) len += strlen(f[idx[i]]) + 1;
	char *restrict out = (char*)safemalloc(len + 1);
	out[0] = '\0';
	for (size_t i = 0; i < m; i++) { if (i) strcat(out, ":"); strcat(out, f[idx[i]]); }
	return out;
}

typedef struct { char **factors; size_t *fi; size_t nf; char *name; size_t width, start; } AnTerm;
typedef struct { char *name; int is_cat; size_t width, nlv; NV *col; char **lv; } AnFac;

/* Append a term built from f[idx[0..m-1]] unless a term with the same
 * canonical name already exists (R merges duplicate terms). */
static void anova_term_add(pTHX_ AnTerm **restrict tp, size_t *restrict np,
		size_t *restrict cp, char **restrict f, const size_t *restrict idx, size_t m) {
	char *restrict name = anova_joinf(aTHX_ f, idx, m);
	for (size_t i = 0; i < *np; i++)
		if (strcmp((*tp)[i].name, name) == 0) { Safefree(name); return; }
	if (*np == *cp) { *cp = *cp ? *cp * 2 : 8; Renew(*tp, *cp, AnTerm); }
	AnTerm *restrict t = &(*tp)[*np];
	t->nf = m; t->name = name; t->width = 0; t->start = 0; t->fi = NULL;
	Newx(t->factors, m, char*);
	for (size_t i = 0; i < m; i++) t->factors[i] = savepv(f[idx[i]]);
	(*np)++;
}

static void anova_free_terms(pTHX_ AnTerm *restrict t, size_t n) {
	if (!t) return;
	for (size_t i = 0; i < n; i++) {
		for (size_t j = 0; j < t[i].nf; j++) Safefree(t[i].factors[j]);
		Safefree(t[i].factors);
		Safefree(t[i].fi);
		Safefree(t[i].name);
	}
	Safefree(t);
}

static void anova_free_facs(pTHX_ AnFac *restrict f, size_t n) {
	if (!f) return;
	for (size_t i = 0; i < n; i++) {
		Safefree(f[i].name);
		Safefree(f[i].col);
		if (f[i].lv) {
			for (size_t j = 0; j < f[i].nlv; j++) Safefree(f[i].lv[j]);
			Safefree(f[i].lv);
		}
	}
	Safefree(f);
}

/* Free the parsed lhs/rhs pairs produced by parse_formula for the multi-model
 * form (parse_formula allocates with the safefree-compatible allocator, the
 * same convention the single-model path frees under). Tolerates NULL slots so
 * it is safe to call after a partial parse. */
static void anova_free_formulas(pTHX_ char **restrict lhss, char **restrict rhss, size_t nf) {
	if (lhss) for (size_t i = 0; i < nf; i++) if (lhss[i]) safefree(lhss[i]);
	if (rhss) for (size_t i = 0; i < nf; i++) if (rhss[i]) safefree(rhss[i]);
	Safefree(lhss);
	Safefree(rhss);
}

/* Find-or-add a factor token in the registry; classifies on insertion. */
static size_t anova_fac(pTHX_ AnFac **restrict fp, size_t *restrict np, size_t *restrict cp,
		HV *restrict hoa, HV **restrict rows, size_t n, const char *restrict name) {
	for (size_t i = 0; i < *np; i++) if (strcmp((*fp)[i].name, name) == 0) return i;
	if (*np == *cp) { *cp = *cp ? *cp * 2 : 8; Renew(*fp, *cp, AnFac); }
	AnFac *restrict f = &(*fp)[*np];
	f->name  = savepv(name);
	f->is_cat = anova_is_bare(name) && is_column_categorical(aTHX_ hoa, rows, n, name);
	f->width = 0; f->nlv = 0; f->col = NULL; f->lv = NULL;
	return (*np)++;
}

/* Expand a formula RHS string into ordered, de-duplicated terms, appending to
 * *tp (with count *np / capacity *cp). Understands '+', ':' and the '*'
 * factorial expansion. Shared by the single-model table path and the
 * per-model fitter below so both parse identically. */
static void anova_expand_rhs(pTHX_ const char *restrict rhs,
		AnTerm **restrict tp, size_t *restrict np, size_t *restrict cp) {
	size_t nsum;
	char **restrict sum = anova_split0(aTHX_ rhs, '+', &nsum);
	for (size_t si = 0; si < nsum; si++) {
		char *restrict s = sum[si];
		if (!strcmp(s, "1") || !strcmp(s, "0") || !strcmp(s, "-1")) continue;
		if (anova_has0(s, '*')) {
			size_t k;
			char **fk = anova_split0(aTHX_ s, '*', &k);
			for (size_t sz = 1; sz <= k; sz++) {
				size_t *idx; Newx(idx, sz, size_t);
				for (size_t i = 0; i < sz; i++) idx[i] = i;
				for (;;) {
					anova_term_add(aTHX_ tp, np, cp, fk, idx, sz);
					long i = (long)sz - 1;
					while (i >= 0 && idx[i] == k - sz + (size_t)i) i--;
					if (i < 0) break;
					idx[i]++;
					for (size_t j = (size_t)i + 1; j < sz; j++) idx[j] = idx[j-1] + 1;
				}
				Safefree(idx);
			}
			for (size_t j = 0; j < k; j++) Safefree(fk[j]);
			Safefree(fk);
		} else if (anova_has0(s, ':')) {
			size_t k;
			char **fk = anova_split0(aTHX_ s, ':', &k);
			size_t *idx; Newx(idx, k, size_t);
			for (size_t i = 0; i < k; i++) idx[i] = i;
			anova_term_add(aTHX_ tp, np, cp, fk, idx, k);
			Safefree(idx);
			for (size_t j = 0; j < k; j++) Safefree(fk[j]);
			Safefree(fk);
		} else {
			char *one[1]; size_t z = 0; one[0] = s;
			anova_term_add(aTHX_ tp, np, cp, one, &z, 1);
		}
	}
	for (size_t si = 0; si < nsum; si++) Safefree(sum[si]);
	Safefree(sum);
}

/* Fit a single model `lhs ~ rhs` on the shared complete-case row set
 * (ridx[0..n_used-1]) and report its residual SS and model rank. Builds its
 * own term/factor registries and design matrix, runs the sequential QR, then
 * frees all of its own scratch. Returns 1 on success, 0 if the RHS expands to
 * no predictor terms (caller croaks). Used only by the model-comparison form;
 * the single-model table path below is unchanged. */
static int anova_fit_one(pTHX_ HV *restrict hoa, HV **restrict rows, size_t n,
		const bool *restrict complete, const size_t *restrict ridx, size_t n_used,
		const char *restrict lhs, const char *restrict rhs,
		NV *restrict rss_out, size_t *restrict rank_out) {
	AnTerm *terms = NULL;
	AnFac  *facs  = NULL;
	size_t nterms = 0, tcap = 0, nfac = 0, fcap = 0;

	anova_expand_rhs(aTHX_ rhs, &terms, &nterms, &tcap);
	if (nterms == 0) { anova_free_terms(aTHX_ terms, nterms); return 0; }

	/* factor registry + per-term factor indices */
	for (size_t t = 0; t < nterms; t++) {
		Newx(terms[t].fi, terms[t].nf, size_t);
		for (size_t j = 0; j < terms[t].nf; j++)
			terms[t].fi[j] = anova_fac(aTHX_ &facs, &nfac, &fcap, hoa, rows, n, terms[t].factors[j]);
	}

	// factor widths + coded columns (levels taken over the shared row set)
	for (size_t f = 0; f < nfac; f++) {
		if (facs[f].is_cat) {
			facs[f].nlv = anova_levels(aTHX_ hoa, rows, n, complete, facs[f].name, &facs[f].lv);
			facs[f].width = facs[f].nlv > 1 ? facs[f].nlv - 1 : 0;
		} else {
			facs[f].width = 1;
		}
		if (facs[f].width == 0) continue;
		Newx(facs[f].col, n_used * facs[f].width, NV);
		if (facs[f].is_cat) {
			for (size_t r = 0; r < n_used; r++) {
				char *sv = get_data_string_alloc(aTHX_ hoa, rows, ridx[r], facs[f].name);
				for (size_t j = 1; j < facs[f].nlv; j++)
					facs[f].col[r * facs[f].width + (j - 1)] =
						(sv && strcmp(sv, facs[f].lv[j]) == 0) ? 1.0 : 0.0;
				Safefree(sv);
			}
		} else {
			for (size_t r = 0; r < n_used; r++)
				facs[f].col[r] = evaluate_term(aTHX_ hoa, rows, (unsigned)ridx[r], facs[f].name);
		}
	}

	// term widths + design layout */
	size_t p = 1;
	for (size_t t = 0; t < nterms; t++) {
		size_t w = 1;
		for (size_t j = 0; j < terms[t].nf; j++) w *= facs[terms[t].fi[j]].width;
		terms[t].width = w;
		terms[t].start = p;
		p += w;
	}
	// design matrix (intercept + term blocks)
	NV **restrict X = NULL, *restrict y = NULL;
	Newx(y, n_used, NV);
	Newx(X, n_used, NV*);
	for (size_t r = 0; r < n_used; r++) {
		Newx(X[r], p, NV);
		X[r][0] = 1.0;
		y[r] = evaluate_term(aTHX_ hoa, rows, (unsigned)ridx[r], lhs);
	}
	for (size_t t = 0; t < nterms; t++) {
		size_t w = terms[t].width;
		if (w == 0) continue;
		for (size_t r = 0; r < n_used; r++) {
			for (size_t c = 0; c < w; c++) {
				size_t rem = c; NV v = 1.0;
				for (size_t j = 0; j < terms[t].nf; j++) {
					AnFac *fj = &facs[terms[t].fi[j]];
					size_t d = rem % fj->width; rem /= fj->width;
					v *= fj->col[r * fj->width + d];
				}
				X[r][terms[t].start + c] = v;
			}
		}
	}

	/* sequential QR (X, y overwritten in place) -> residual SS + rank */
	bool   *restrict aliased  = NULL;
	size_t *restrict rank_map = NULL;
	Newx(aliased,  p, bool);
	Newx(rank_map, p, size_t);
	for (size_t k = 0; k < p; k++) rank_map[k] = 0;
	apply_householder_aov(X, y, n_used, p, aliased, rank_map);

	size_t rank = 0;
	for (size_t k = 0; k < p; k++) if (!aliased[k]) rank++;
	NV rss = 0.0;
	for (size_t r = rank; r < n_used; r++) rss += y[r] * y[r];

	*rss_out  = rss;
	*rank_out = rank;

	for (size_t r = 0; r < n_used; r++) Safefree(X[r]);
	Safefree(X); Safefree(y);	Safefree(aliased); Safefree(rank_map);
	anova_free_terms(aTHX_ terms, nterms);	anova_free_facs(aTHX_ facs, nfac);
	return 1;
}
// ------------------------------------------------------------------
// rank() helpers: sort a small record carrying value, original index
// (among non-NA elements) and a random tie-break key.
// ------------------------------------------------------------------
typedef struct {
	NV val;   // numeric value
	IV idx;   // 0-based index among non-NA elements
	NV rnd;   // random tie-break key (ties.method => 'random')
} rank_pair;

// value ascending, ties broken by original index ascending
static int rank_cmp_idx_asc(const void *a, const void *b) {
	const rank_pair *pa = (const rank_pair *)a;
	const rank_pair *pb = (const rank_pair *)b;
	if (pa->val < pb->val) return -1;
	if (pa->val > pb->val) return  1;
	if (pa->idx < pb->idx) return -1;
	if (pa->idx > pb->idx) return  1;
	return 0;
}

// value ascending, ties broken by original index descending ('last')
static int rank_cmp_idx_desc(const void *a, const void *b) {
	const rank_pair *pa = (const rank_pair *)a;
	const rank_pair *pb = (const rank_pair *)b;
	if (pa->val < pb->val) return -1;
	if (pa->val > pb->val) return  1;
	if (pa->idx > pb->idx) return -1;
	if (pa->idx < pb->idx) return  1;
	return 0;
}

// value ascending, ties broken randomly ('random'); idx as final fallback
static int rank_cmp_rnd_asc(const void *a, const void *b) {
	const rank_pair *pa = (const rank_pair *)a;
	const rank_pair *pb = (const rank_pair *)b;
	if (pa->val < pb->val) return -1;
	if (pa->val > pb->val) return  1;
	if (pa->rnd < pb->rnd) return -1;
	if (pa->rnd > pb->rnd) return  1;
	if (pa->idx < pb->idx) return -1;
	if (pa->idx > pb->idx) return  1;
	return 0;
}

// ties.method codes
#define RANK_AVERAGE 0
#define RANK_FIRST   1
#define RANK_LAST    2
#define RANK_RANDOM  3
#define RANK_MAX     4
#define RANK_MIN     5

// na.last codes
#define NALAST_TRUE  0  // NAs get the highest ranks (default)
#define NALAST_FALSE 1  // NAs get the lowest ranks
#define NALAST_KEEP  2  // NAs stay undef, in place
#define NALAST_DROP  3  // NAs removed (R's na.last = NA)

// ============================================================================
// Column verbs for Stats::LikeR -- fast, low-RAM paths for select_cols /
// drop_cols / rename_cols on the row-oriented shapes (AoH, HoH, AoA).
//
// INTEGRATION: paste the three `static` helpers below in with the other
// file-scope C helpers (above the existing `MODULE = Stats::LikeR` line), and
// paste the three XSUBs into the existing MODULE block. The `MODULE = ... `
// line here is a marker only -- drop it if you already have one, so it is not
// duplicated. Headers (EXTERN.h / perl.h / XSUB.h / ppport.h) are assumed to
// be present at the top of LikeR.xs already.
//
// These are PRIVATE (leading underscore) and are NOT added to @EXPORT_OK; the
// Perl wrappers in LikeR.pm validate their arguments and call them. All cell
// SVs are SHARED by refcount (like transpose), so results are shallow views:
// no per-cell copy (speed) and no duplicate scalar bodies (RAM). HoA is left
// to pure Perl in the wrapper (it just aliases whole column arrayrefs).
//
// Verified: compiles -O2 clean; correctness vs a pure-Perl reference across
// AoH/HoH/AoA incl. ragged + utf8 keys; SV sharing confirmed by address; and
// zero net live-SV growth over 20k build/free iterations on every path.
// ============================================================================

// ---- shared inner-row builders (all SHARE cell SVs via refcount) ----------

// select: new inner HV holding keys[0..nkeys-1]; a present cell is shared, an
// absent one becomes a fresh mutable undef.  hash=0 lets hv normalise utf8.
static HV *row_select(pTHX_ HV *src, SV **keys, SSize_t nkeys) {
	HV *restrict out = newHV();
	if (nkeys > 0) hv_ksplit(out, (IV)nkeys);
	for (SSize_t j = 0; j < nkeys; j++) {
		HE *restrict e = src ? hv_fetch_ent(src, keys[j], 0, 0) : NULL;
		SV *restrict val;
		if (e && HeVAL(e)) { val = HeVAL(e); SvREFCNT_inc_simple_void(val); }
		else               { val = newSV(0); }                 // absent -> undef
		(void)hv_store_ent(out, keys[j], val, 0);
	}
	return out;
}

// drop: new inner HV = every source key not present in drop_hv; cells shared.
// The source entry's own key bytes/utf8/hash are reused (no re-hash, utf8-safe).
static HV *row_drop(pTHX_ HV *src, HV *drop_hv) {
	HV *restrict out = newHV();
	if (!src) return out;
	hv_iterinit(src);
	HE *restrict he;
	while ((he = hv_iternext(src))) {
		STRLEN kl; char *restrict kp = HePV(he, kl);
		I32 sk = HeUTF8(he) ? -(I32)kl : (I32)kl;
		if (hv_exists(drop_hv, kp, sk)) continue;
		SV *restrict val = HeVAL(he); SvREFCNT_inc_simple_void(val);
		(void)hv_store(out, kp, sk, val, HeHASH(he));
	}
	return out;
}

// rename: new inner HV; a key found in map_hv is re-labelled with the map's
// new-name SV (utf8-normalised), others keep their source key verbatim.
static HV *row_rename(pTHX_ HV *src, HV *map_hv) {
	HV *restrict out = newHV();
	if (!src) return out;
	hv_iterinit(src);
	HE *restrict he;
	while ((he = hv_iternext(src))) {
		STRLEN kl; char *restrict kp = HePV(he, kl);
		I32 sk = HeUTF8(he) ? -(I32)kl : (I32)kl;
		SV *restrict val = HeVAL(he); SvREFCNT_inc_simple_void(val);
		SV **restrict mp = hv_fetch(map_hv, kp, sk, 0);
		if (mp && *mp) (void)hv_store_ent(out, *mp, val, 0);
		else           (void)hv_store(out, kp, sk, val, HeHASH(he));
	}
	return out;
}

// AoA select/keep: new inner AV of the given positions; cells shared, an
// out-of-range position becomes a fresh mutable undef.
static AV *rowA_select(pTHX_ AV *src, IV *idx, SSize_t n) {
	AV *restrict out = newAV();
	if (n > 0) av_extend(out, n - 1);
	for (SSize_t j = 0; j < n; j++) {
		SV **restrict ep = src ? av_fetch(src, idx[j], 0) : NULL;
		SV *restrict val;
		if (ep && *ep) { val = *ep; SvREFCNT_inc_simple_void(val); }
		else           { val = newSV(0); }
		av_push(out, val);
	}
	return out;
}

/* ======================================================================
 * merge() helpers -- full relational join (R merge / pandas merge).
 *
 * The join reads its inputs where they lie.  A HoA frame is used column by
 * column and a row frame (AoH/HoH) row by row, so neither is transposed into
 * the other on the way in and the only cells copied are the ones the result
 * keeps.  Join keys match on the *stringified* cell value (canonical,
 * length-prefixed), the natural Perl hash-join semantics; an undef/missing
 * key cell never matches (pandas NaN rule).
 * ====================================================================== */
#define MG_KEYSEP "\x1e"
#define MG_INNER 0
#define MG_LEFT  1
#define MG_RIGHT 2
#define MG_OUTER 3
#define MG_CROSS 4

/* An input frame, ready to be read cell by cell.  A HoA keeps its column
 * arrays; an AoH/HoH is an AV of row hashrefs, aliased rather than copied.
 * `names`/`seen` are the frame's column universe in first-seen order. */
typedef struct {
	int      hoa;			/* 1 = column-major (HoA) */
	HV      *cols;			/* hoa: the source hash of column array-refs */
	AV      *rows;			/* !hoa: mortal AV of row hashrefs */
	SSize_t  nrows;
	AV      *names;			/* mortal AV of column-name SVs */
	HV      *seen;			/* mortal HV, name -> 1 */
} mg_frame;

/* One column of a frame, resolved once and then read by row index: the
 * column array for a HoA, the column name for a row frame. */
typedef struct {
	AV *av;					/* hoa */
	SV *name;				/* !hoa */
} mg_col;

/* Note a column name the first time it is seen. */
static void
mg_saw(pTHX_ mg_frame *restrict f, SV *restrict name) {
	if (hv_exists_ent(f->seen, name, 0)) return;
	(void)hv_store_ent(f->seen, name, newSViv(1), 0);
	av_push(f->names, newSVsv(name));
}

/* Validate a frame and describe it in *f.  Nothing is copied: an AoH/HoH
 * lends its rows, a HoA its columns. */
static void
mg_prep(pTHX_ SV *restrict frame, const char *restrict side, mg_frame *restrict f) {
	if (!frame || !SvROK(frame))
		croak("merge: %s frame must be an array-ref (AoH) or hash-ref (HoA/HoH)", side);
	SV *restrict rv = SvRV(frame);
	f->hoa   = 0;
	f->cols  = NULL;
	f->rows  = (AV *)sv_2mortal((SV *)newAV());
	f->nrows = 0;
	f->names = (AV *)sv_2mortal((SV *)newAV());
	f->seen  = (HV *)sv_2mortal((SV *)newHV());

	if (SvTYPE(rv) == SVt_PVAV) {			/* AoH */
		AV *restrict av = (AV *)rv;
		SSize_t n = av_len(av) + 1;
		for (SSize_t i = 0; i < n; i++) {
			SV **restrict rp = av_fetch(av, i, 0);
			if (!rp || !*rp || !SvOK(*rp)) continue;
			SV *restrict r = *rp;
			if (!SvROK(r) || SvTYPE(SvRV(r)) != SVt_PVHV) {
				if (SvROK(r) && SvTYPE(SvRV(r)) == SVt_PVAV)
					croak("merge: %s frame is an array-of-arrays; merge needs "
					      "named columns (give it an AoH, HoA, or HoH)", side);
				croak("merge: %s frame row %ld is not a hash-ref (need an AoH)",
				      side, (long)i);
			}
			av_push(f->rows, SvREFCNT_inc_simple_NN(r));
			HE *restrict e; hv_iterinit((HV *)SvRV(r));
			while ((e = hv_iternext((HV *)SvRV(r)))) mg_saw(aTHX_ f, hv_iterkeysv(e));
		}
		f->nrows = av_len(f->rows) + 1;
		return;
	}
	if (SvTYPE(rv) != SVt_PVHV)
		croak("merge: %s frame must be AoH/HoA/HoH", side);
	HV *restrict hv = (HV *)rv;
	hv_iterinit(hv);
	HE *restrict e0 = hv_iternext(hv);
	if (!e0) return;						/* empty hash -> empty frame */
	SV *restrict v0 = HeVAL(e0);
	if (SvROK(v0) && SvTYPE(SvRV(v0)) == SVt_PVHV) {	/* HoH: values are rows */
		HE *restrict e;
		hv_iterinit(hv);
		while ((e = hv_iternext(hv))) {
			SV *restrict v = HeVAL(e);
			if (!SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVHV)
				croak("merge: %s frame (HoH) value for row '%s' is not a hash-ref",
				      side, HePV(e, PL_na));
			av_push(f->rows, SvREFCNT_inc_simple_NN(v));
			HE *restrict re; hv_iterinit((HV *)SvRV(v));
			while ((re = hv_iternext((HV *)SvRV(v)))) mg_saw(aTHX_ f, hv_iterkeysv(re));
		}
		f->nrows = av_len(f->rows) + 1;
		return;
	}
	if (!(SvROK(v0) && SvTYPE(SvRV(v0)) == SVt_PVAV))
		croak("merge: %s frame hash values must be array-refs (HoA) or hash-refs (HoH)", side);
	/* HoA: the columns are read where they are.  Row count is the longest
	 * column; a short one reads as undef past its end, as a transpose would
	 * have padded it. */
	f->hoa  = 1;
	f->cols = hv;
	f->rows = NULL;
	HE *restrict e;
	hv_iterinit(hv);
	while ((e = hv_iternext(hv))) {
		SV *restrict v = HeVAL(e);
		if (!SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVAV)
			croak("merge: %s frame (HoA) column '%s' is not an array-ref",
			      side, HePV(e, PL_na));
		SSize_t l = av_len((AV *)SvRV(v)) + 1;
		if (l > f->nrows) f->nrows = l;
		mg_saw(aTHX_ f, hv_iterkeysv(e));
	}
}

/* A shared-hash copy of a column name.  Every hv_fetch_ent/hv_store_ent that
 * uses it gets the key's hash for free (perl keeps it in the SV) and finds the
 * HEK already interned, which is worth having when the same dozen names are
 * looked up once per output row. */
static SV *
mg_shared(pTHX_ SV *restrict name) {
	STRLEN l;
	const char *restrict p = SvPV(name, l);
	return sv_2mortal(newSVpvn_share(p, SvUTF8(name) ? -(I32)l : (I32)l, 0));
}

/* Resolve one column name against a frame, once, for the whole join. */
static void
mg_resolve(pTHX_ const mg_frame *restrict f, SV *restrict name, mg_col *restrict c) {
	c->av = NULL;
	c->name = mg_shared(aTHX_ name);
	if (!f->hoa) return;
	HE *restrict e = hv_fetch_ent(f->cols, name, 0, 0);
	if (e && SvROK(HeVAL(e)) && SvTYPE(SvRV(HeVAL(e))) == SVt_PVAV)
		c->av = (AV *)SvRV(HeVAL(e));
}

/* The cell at (row, column), or NULL when the frame has none there. */
static SV *
mg_cell(pTHX_ const mg_frame *restrict f, const mg_col *restrict c, SSize_t i) {
	if (f->hoa) {
		if (!c->av) return NULL;
		SV **restrict p = av_fetch(c->av, i, 0);
		return (p && *p) ? *p : NULL;
	}
	SV **restrict rp = av_fetch(f->rows, i, 0);
	if (!rp || !*rp) return NULL;
	HE *restrict e = hv_fetch_ent((HV *)SvRV(*rp), c->name, 0, 0);
	return e ? HeVAL(e) : NULL;
}

/* Canonical, length-prefixed join key over `nkeys` columns of row `i`,
 * built into the caller's buffer so the whole join needs one SV rather than
 * one per row.  Returns 0 if any key cell is missing or undef. */
static int
mg_key(pTHX_ const mg_frame *restrict f, const mg_col *restrict keys, SSize_t nkeys,
       SSize_t i, SV *restrict buf) {
	SvCUR_set(buf, 0);
	SvPOK_only(buf);				/* also clears any UTF8 flag: bytes only */
	for (SSize_t j = 0; j < nkeys; j++) {
		SV *restrict cell = mg_cell(aTHX_ f, &keys[j], i);
		if (!cell || !SvOK(cell)) return 0;
		STRLEN l;
		const char *restrict p = SvPV(cell, l);
		char nb[24];
		char *restrict np = nb + sizeof nb;
		size_t v = (size_t)l;
		do { *--np = (char)('0' + (v % 10)); v /= 10; } while (v);
		sv_catpvn(buf, np, (STRLEN)(nb + sizeof nb - np));
		sv_catpvn(buf, MG_KEYSEP, 1);
		sv_catpvn(buf, p, l);
		sv_catpvn(buf, MG_KEYSEP, 1);
	}
	return 1;
}

/* Everything the emitter needs, resolved once before the join runs. */
typedef struct {
	const mg_frame *L, *R;
	mg_col  *lk, *rk;		/* join key columns, nkeys of each */
	mg_col  *lc, *rc;		/* data columns, nlc / nrc of them */
	SSize_t  nkeys, nlc, nrc;
	SV     **oname;			/* nkeys + nlc + nrc output names, in that order */
	int      out_hoa;
	AV      *result;		/* AoH output: the rows */
	AV     **ocol;			/* HoA output: nkeys + nlc + nrc columns */
} mg_join;

/* Emit the row made of left row `li` and right row `ri`; either may be -1
 * for the unmatched side of an outer join.  A key cell comes from the left
 * when it has one, otherwise from the right. */
static void
mg_emit(pTHX_ mg_join *restrict J, SSize_t li, SSize_t ri) {
	HV *restrict row = NULL;
	SSize_t o = 0;
	if (!J->out_hoa) {
		row = newHV();
		hv_ksplit(row, J->nkeys + J->nlc + J->nrc);	/* no rehash mid-row */
	}

	for (SSize_t k = 0; k < J->nkeys; k++, o++) {
		SV *restrict val = NULL;
		if (li >= 0) {
			SV *restrict v = mg_cell(aTHX_ J->L, &J->lk[k], li);
			if (v && SvOK(v)) val = v;
		}
		if (!val && ri >= 0) val = mg_cell(aTHX_ J->R, &J->rk[k], ri);
		SV *restrict cell = val ? newSVsv(val) : newSV(0);
		if (row) (void)hv_store_ent(row, J->oname[o], cell, 0);
		else     av_push(J->ocol[o], cell);
	}
	for (SSize_t c = 0; c < J->nlc; c++, o++) {
		SV *restrict val = (li >= 0) ? mg_cell(aTHX_ J->L, &J->lc[c], li) : NULL;
		SV *restrict cell = val ? newSVsv(val) : newSV(0);
		if (row) (void)hv_store_ent(row, J->oname[o], cell, 0);
		else     av_push(J->ocol[o], cell);
	}
	for (SSize_t c = 0; c < J->nrc; c++, o++) {
		SV *restrict val = (ri >= 0) ? mg_cell(aTHX_ J->R, &J->rc[c], ri) : NULL;
		SV *restrict cell = val ? newSVsv(val) : newSV(0);
		if (row) (void)hv_store_ent(row, J->oname[o], cell, 0);
		else     av_push(J->ocol[o], cell);
	}
	if (row) av_push(J->result, newRV_noinc((SV *)row));
}

/* 0 = AoH, 1 = HoA, 2 = HoH (used only to pick the default output shape). */
static int
mg_shape(pTHX_ SV *restrict frame) {
	SV *restrict rv = SvRV(frame);
	if (SvTYPE(rv) == SVt_PVAV) return 0;
	HV *restrict hv = (HV *)rv;
	hv_iterinit(hv);
	HE *restrict e = hv_iternext(hv);
	if (!e) return 1;
	SV *restrict v = HeVAL(e);
	if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV) return 2;
	return 1;
}

/* Expand a scalar-or-arrayref option into a mortal AV of name SVs. */
static AV *
mg_names(pTHX_ SV *restrict v) {
	AV *restrict a = (AV *)sv_2mortal((SV *)newAV());
	if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV) {
		AV *restrict s = (AV *)SvRV(v);
		SSize_t n = av_len(s) + 1;
		for (SSize_t i = 0; i < n; i++) {
			SV **restrict p = av_fetch(s, i, 0);
			av_push(a, newSVsv((p && *p) ? *p : &PL_sv_undef));
		}
	} else {
		av_push(a, newSVsv(v));
	}
	return a;
}

/* ======================================================================
 * drop_duplicates() helpers -- row-level de-duplication for AoA / AoH / HoA.
 *
 * A row's identity is a canonical, length-prefixed key over the subset
 * cells, exactly the hash-join semantics merge() uses (mg_key): two cells
 * are "the same" iff they stringify equally, an undef cell gets its own
 * sentinel that never collides with a real value (a real cell always opens
 * with a decimal length, the undef token opens with '~'). HoH is handled
 * entirely in the Perl wrapper (it dies) so there is no code path for it.
 *
 * The keys are interned into one growable arena behind a small open-addressed
 * table instead of a Perl hash of per-row key SVs.  A row whose key is already
 * present rewinds the arena, so a pass costs one copy of each *distinct* key
 * plus ~40 bytes per distinct row -- not an SV, an HE, a HEK and a value SV
 * per input row, all of them alive at once.  Everything the pass allocates is
 * hung off a dd_ctx that a save-stack destructor releases, so a croak out of
 * an overloaded stringification cannot leak it.
 * ====================================================================== */
typedef struct {
	char     *buf;      /* arena: the distinct keys, back to back */
	size_t    len, cap;
	SSize_t  *off;      /* group -> key offset; off[ng] == len, so the key
	                     * length of group g is off[g + 1] - off[g] */
	uint64_t *khash;    /* group -> key hash */
	SSize_t  *first;    /* group -> row that created it (ascending in g) */
	SSize_t  *cnt;      /* group -> occurrences (kept only when use_cnt) */
	int       use_cnt;
	SSize_t   ng, gcap;
	SSize_t  *slot;     /* open addressing: slot -> group + 1, 0 = free */
	size_t    nslot;    /* always a power of two */
	IV       *pos;      /* AoA: subset column positions */
	AV      **cols;     /* HoA: subset column arrays */
} dd_ctx;

static void
dd_ctx_free(pTHX_ void *p) {
	dd_ctx *restrict T = (dd_ctx *)p;
	Safefree(T->buf);   Safefree(T->off);  Safefree(T->khash);
	Safefree(T->first); Safefree(T->cnt);  Safefree(T->slot);
	Safefree(T->pos);   Safefree(T->cols);
	Safefree(T);
}

/* 64-bit key hash, eight bytes at a time (keys are long: every cell in them
 * carries its own length prefix and separators). */
PERL_STATIC_INLINE uint64_t
dd_hash(const char *restrict p, size_t n) {
	const uint64_t M1 = UINT64_C(0x9e3779b97f4a7c15),
	               M2 = UINT64_C(0xc2b2ae3d27d4eb4f);
	uint64_t h = M1 ^ (n * M2), k;
	for (; n >= 8; p += 8, n -= 8) {
		memcpy(&k, p, 8);
		k *= M1; k ^= k >> 47; k *= M2;
		h ^= k;  h *= M1;
	}
	k = 0;
	if (n) memcpy(&k, p, n);
	h ^= k * M2;
	h ^= h >> 32; h *= M2; h ^= h >> 29;
	return h;
}

/* make room for `extra` more key bytes */
PERL_STATIC_INLINE void
dd_reserve(pTHX_ dd_ctx *restrict T, size_t extra) {
	if (T->len + extra > T->cap) {
		size_t want = T->cap ? T->cap * 2 : 4096;
		while (want < T->len + extra) want *= 2;
		Renew(T->buf, want, char);
		T->cap = want;
	}
}

/* append one cell's canonical form to the key under construction */
PERL_STATIC_INLINE void
dd_cell(pTHX_ dd_ctx *restrict T, SV *restrict c) {
	if (c && SvOK(c)) {
		STRLEN l;
		const char *restrict p = SvPV(c, l);   /* before dd_reserve: may croak */
		char nb[24], *restrict np = nb + sizeof nb;
		size_t v = (size_t)l;
		do { *--np = (char)('0' + (v % 10)); v /= 10; } while (v);
		size_t nd = (size_t)(nb + sizeof nb - np);
		dd_reserve(aTHX_ T, l + nd + 2);
		char *restrict w = T->buf + T->len;
		memcpy(w, np, nd);      w += nd;
		*w++ = MG_KEYSEP[0];
		memcpy(w, p, l);        w += l;
		*w++ = MG_KEYSEP[0];
		T->len = (size_t)(w - T->buf);
	} else {
		dd_reserve(aTHX_ T, 2);                      /* undef sentinel */
		T->buf[T->len++] = '~';
		T->buf[T->len++] = MG_KEYSEP[0];
	}
}

/* double the slot table and reinsert every group (hashes are already known) */
static void
dd_rehash(pTHX_ dd_ctx *restrict T) {
	size_t n = T->nslot ? T->nslot * 2 : 64, mask = n - 1;
	Safefree(T->slot);
	Newxz(T->slot, n, SSize_t);
	T->nslot = n;
	for (SSize_t g = 0; g < T->ng; g++) {
		size_t i = (size_t)T->khash[g] & mask;
		while (T->slot[i]) i = (i + 1) & mask;
		T->slot[i] = g + 1;
	}
}

/* Intern the key just appended at buf[start .. len).  Returns its group; a key
 * already interned rewinds the arena, so only distinct keys are kept.  `row`
 * is recorded as the group's first occurrence when the group is new -- and
 * because groups are created in row order, first[] comes out sorted. */
static SSize_t
dd_intern(pTHX_ dd_ctx *restrict T, size_t start, SSize_t row) {
	const size_t n = T->len - start;
	const uint64_t h = dd_hash(T->buf + start, n);
	if ((T->ng + 1) * 2 >= (SSize_t)T->nslot) dd_rehash(aTHX_ T);
	const size_t mask = T->nslot - 1;
	size_t i = (size_t)h & mask;
	while (T->slot[i]) {
		const SSize_t g = T->slot[i] - 1;
		if (T->khash[g] == h && (size_t)(T->off[g + 1] - T->off[g]) == n
		    && memcmp(T->buf + T->off[g], T->buf + start, n) == 0) {
			T->len = start;                    /* duplicate: drop the copy */
			return g;
		}
		i = (i + 1) & mask;
	}
	if (T->ng + 2 > T->gcap) {                 /* +2: off[] holds ng + 1 */
		SSize_t want = T->gcap ? T->gcap * 2 : 64;
		Renew(T->off,   want + 1, SSize_t);
		Renew(T->khash, want,     uint64_t);
		Renew(T->first, want,     SSize_t);
		if (T->use_cnt) Renew(T->cnt, want, SSize_t);
		T->gcap = want;
	}
	const SSize_t g = T->ng++;
	T->off[g]     = (SSize_t)start;
	T->off[g + 1] = (SSize_t)T->len;
	T->khash[g]   = h;
	T->first[g]   = row;
	if (T->use_cnt) T->cnt[g] = 0;
	T->slot[i]    = g + 1;
	return g;
}

/* ===========================================================================
 * interpolate() numeric core.  Backs Stats::LikeR::_interp_column_xs, which
 * fills the undef gaps of one already-extracted column (an AV of numbers /
 * undef gaps / defined non-numeric barriers) in place.  A direct C port of the
 * former pure-Perl kernels (_interp_* in LikeR.pm); the per-method maths is
 * validated against pandas/scipy by t/interpolate*.t.  All scratch is Newx +
 * SAVEFREEPV so it is freed at the XSUB's LEAVE, on normal and croak exits.
 *
 * kind[i]: 0 = undef gap (fillable), 1 = numeric anchor, 2 = defined non-numeric
 * barrier (preserved; blocks the piecewise-local fits, ignored by the fits).
 * ========================================================================= */

#define IP_LINEAR   1   /* interior fill rules */
#define IP_NEAREST  2
#define IP_LEFT     3
#define IP_RIGHT    4
#define IP_EDGE_NONE  0 /* leading/trailing hold rules */
#define IP_EDGE_BOTH  1
#define IP_EDGE_LEFT  2
#define IP_EDGE_RIGHT 3
#define IP_KLINEAR 1    /* fit-kernel types */
#define IP_KCUBIC  2
#define IP_KQUAD   3
#define IP_KPCHIP  4
#define IP_KAKIMA  5
#define IP_KBARY   6

/* largest i with xa[i] <= t, clamped to a valid interval [0, n-2] */
static IV ip_seg(const NV *xa, IV n, NV t) {
	IV lo = 0, hi = n - 1;
	while (lo < hi) {
		IV mid = (lo + hi + 1) / 2;
		if (xa[mid] <= t) lo = mid; else hi = mid - 1;
	}
	if (lo > n - 2) lo = n - 2;
	if (lo < 0)     lo = 0;
	return lo;
}

/* dense Gaussian elimination with partial pivoting: solve A x = b (A row-major
 * n*n, both overwritten), writing the solution into out.  Croaks if singular. */
static void ip_solve(pTHX_ NV *A, NV *b, IV n, NV *out) {
	for (IV col = 0; col < n; col++) {
		IV piv = col; NV best = fabs(A[col * n + col]);
		for (IV r = col + 1; r < n; r++) {
			NV a = fabs(A[r * n + col]);
			if (a > best) { best = a; piv = r; }
		}
		if (piv != col) {
			for (IV k = 0; k < n; k++) {
				NV t = A[col * n + k]; A[col * n + k] = A[piv * n + k]; A[piv * n + k] = t;
			}
			NV t = b[col]; b[col] = b[piv]; b[piv] = t;
		}
		NV d = A[col * n + col];
		if (d == 0) croak("interpolate: singular system in spline solve");
		for (IV r = col + 1; r < n; r++) {
			NV f = A[r * n + col] / d;
			if (f == 0) continue;
			for (IV k = col; k < n; k++) A[r * n + k] -= f * A[col * n + k];
			b[r] -= f * b[col];
		}
	}
	for (IV i = n - 1; i >= 0; i--) {
		NV s = b[i];
		for (IV k = i + 1; k < n; k++) s -= A[i * n + k] * out[k];
		out[i] = s / A[i * n + i];
	}
}

/* nearest numeric anchor strictly below / above each index, or -1 across a
 * barrier or the edge (kind==2 resets the search; kind==0 leaves it running). */
static void ip_prevnext(const char *kind, IV n, IV *prev, IV *next) {
	IV p = -1;
	for (IV i = 0; i < n; i++) {
		prev[i] = p;
		if (kind[i] == 1) p = i; else if (kind[i] == 2) p = -1;
	}
	IV q = -1;
	for (IV i = n - 1; i >= 0; i--) {
		next[i] = q;
		if (kind[i] == 1) q = i; else if (kind[i] == 2) q = -1;
	}
}

// Cox-de Boor B-spline basis B_{j,kk}(tv) over knot vector t (length nt)
static NV ip_bspline(const NV *t, IV nt, IV j, int kk, NV tv) {
	if (kk == 0) {
		if ((t[j] <= tv && tv < t[j + 1])
		 || (tv == t[nt - 1] && t[j] <= tv && tv <= t[j + 1])) return 1.0;
		return 0.0;
	}
	NV d1 = t[j + kk]     - t[j];
	NV d2 = t[j + kk + 1] - t[j + 1];
	NV c1 = d1 > 0 ? (tv - t[j]) / d1 * ip_bspline(t, nt, j, kk - 1, tv) : 0.0;
	NV c2 = d2 > 0 ? (t[j + kk + 1] - tv) / d2 * ip_bspline(t, nt, j + 1, kk - 1, tv) : 0.0;
	return c1 + c2;
}

// scipy PchipInterpolator's one-sided endpoint slope
static NV ip_pchip_edge(NV h0, NV h1, NV d0, NV d1) {
	NV d = ((2 * h0 + h1) * d0 - h0 * d1) / (h0 + h1);
	int sd = (d > 0) - (d < 0), s0 = (d0 > 0) - (d0 < 0), s1 = (d1 > 0) - (d1 < 0);
	if (sd != s0)                                        d = 0;
	else if (s0 != s1 && fabs(d) > 3 * fabs(d0))         d = 3 * d0;
	return d;
}

typedef struct {
	int type;          // IP_K*
	IV  na;            // anchor count
	const NV *restrict xa, *ya; // anchors (borrowed)
	NV *h;             // spacings (cubic/pchip/akima)
	NV *M;             // cubic second derivatives
	NV *d;             // pchip slopes / akima tangents
	NV *w;             // barycentric weights
	NV *knots, *coef;  // quadratic B-spline
	IV  nknots;
} ip_fit;

/* not-a-knot interpolating cubic spline (== scipy CubicSpline / interp1d cubic) */
static void ip_build_cubic(pTHX_ ip_fit *F) {
	IV n = F->na; const NV *xa = F->xa, *ya = F->ya;
	Newx(F->h, n > 1 ? n - 1 : 1, NV); SAVEFREEPV(F->h);
	for (IV i = 0; i < n - 1; i++) F->h[i] = xa[i + 1] - xa[i];
	if (n <= 3) { F->M = NULL; return; }        /* eval handles 2 / 3 directly */
	NV *A; Newxz(A, n * n, NV); SAVEFREEPV(A);
	NV *b; Newxz(b, n, NV);     SAVEFREEPV(b);
	for (IV i = 1; i <= n - 2; i++) {
		A[i * n + (i - 1)] = F->h[i - 1];
		A[i * n + i]       = 2 * (F->h[i - 1] + F->h[i]);
		A[i * n + (i + 1)] = F->h[i];
		b[i] = 6 * ((ya[i + 1] - ya[i]) / F->h[i] - (ya[i] - ya[i - 1]) / F->h[i - 1]);
	}
	A[0]           = -F->h[1]; A[1] = F->h[0] + F->h[1]; A[2] = -F->h[0];
	A[(n - 1) * n + (n - 3)] = -F->h[n - 2];
	A[(n - 1) * n + (n - 2)] =  F->h[n - 3] + F->h[n - 2];
	A[(n - 1) * n + (n - 1)] = -F->h[n - 3];
	Newx(F->M, n, NV); SAVEFREEPV(F->M);
	ip_solve(aTHX_ A, b, n, F->M);
}
static NV ip_eval_cubic(const ip_fit *F, NV t) {
	IV n = F->na; const NV *xa = F->xa, *ya = F->ya, *h = F->h;
	if (n == 2) return ya[0] + (ya[1] - ya[0]) * (t - xa[0]) / h[0];
	if (n == 3)
		return ya[0] * (t - xa[1]) * (t - xa[2]) / ((xa[0] - xa[1]) * (xa[0] - xa[2]))
		     + ya[1] * (t - xa[0]) * (t - xa[2]) / ((xa[1] - xa[0]) * (xa[1] - xa[2]))
		     + ya[2] * (t - xa[0]) * (t - xa[1]) / ((xa[2] - xa[0]) * (xa[2] - xa[1]));
	IV i = ip_seg(xa, n, t);
	NV hi = h[i], A_ = (xa[i + 1] - t) / hi, B_ = (t - xa[i]) / hi;
	return A_ * ya[i] + B_ * ya[i + 1]
	     + ((A_ * A_ * A_ - A_) * F->M[i] + (B_ * B_ * B_ - B_) * F->M[i + 1]) * hi * hi / 6;
}

// degree-2 interpolating B-spline, scipy's midpoint interior knots
static void ip_build_quad(pTHX_ ip_fit *F) {
	IV n = F->na; const NV *restrict xa = F->xa, *ya = F->ya; int k = 2;
	IV nk = n + 3, idx = 0;
	Newx(F->knots, nk, NV); SAVEFREEPV(F->knots);
	for (int r = 0; r < k + 1; r++)  F->knots[idx++] = xa[0];
	for (IV i = 1; i <= n - 3; i++)  F->knots[idx++] = (xa[i] + xa[i + 1]) / 2;
	for (int r = 0; r < k + 1; r++)  F->knots[idx++] = xa[n - 1];
	F->nknots = nk;
	IV m = nk - k - 1;                            /* == n */
	NV *restrict A; Newxz(A, n * n, NV); SAVEFREEPV(A);
	NV *restrict b; Newx(b, n, NV);      SAVEFREEPV(b);
	for (IV i = 0; i < n; i++) {
		for (IV j = 0; j < m; j++) A[i * n + j] = ip_bspline(F->knots, nk, j, k, xa[i]);
		b[i] = ya[i];
	}
	Newx(F->coef, m, NV); SAVEFREEPV(F->coef);
	ip_solve(aTHX_ A, b, n, F->coef);
}
static NV ip_eval_quad(const ip_fit *F, NV t) {
	IV m = F->na; NV s = 0;
	for (IV j = 0; j < m; j++) s += F->coef[j] * ip_bspline(F->knots, F->nknots, j, 2, t);
	return s;
}

// monotone piecewise cubic Hermite (Fritsch-Carlson; == scipy Pchip)
static void ip_build_pchip(pTHX_ ip_fit *F) {
	IV n = F->na; const NV *xa = F->xa, *ya = F->ya;
	Newx(F->h, n - 1, NV); SAVEFREEPV(F->h);
	NV *dk; Newx(dk, n - 1, NV); SAVEFREEPV(dk);
	for (IV i = 0; i < n - 1; i++) { F->h[i] = xa[i + 1] - xa[i]; dk[i] = (ya[i + 1] - ya[i]) / F->h[i]; }
	Newx(F->d, n, NV); SAVEFREEPV(F->d);
	if (n == 2) { F->d[0] = dk[0]; F->d[1] = dk[0]; return; }
	F->d[0]     = ip_pchip_edge(F->h[0], F->h[1], dk[0], dk[1]);
	F->d[n - 1] = ip_pchip_edge(F->h[n - 2], F->h[n - 3], dk[n - 2], dk[n - 3]);
	for (IV i = 1; i <= n - 2; i++) {
		if (dk[i - 1] * dk[i] <= 0) F->d[i] = 0;
		else {
			NV w1 = 2 * F->h[i] + F->h[i - 1], w2 = F->h[i] + 2 * F->h[i - 1];
			F->d[i] = (w1 + w2) / (w1 / dk[i - 1] + w2 / dk[i]);
		}
	}
}
static NV ip_eval_pchip(const ip_fit *F, NV t) {
	IV n = F->na; const NV *xa = F->xa, *ya = F->ya, *h = F->h, *d = F->d;
	IV i = ip_seg(xa, n, t); NV hi = h[i], s = (t - xa[i]) / hi, s2 = s * s, s3 = s2 * s;
	NV h00 = 2 * s3 - 3 * s2 + 1, h10 = s3 - 2 * s2 + s, h01 = -2 * s3 + 3 * s2, h11 = s3 - s2;
	return h00 * ya[i] + h10 * hi * d[i] + h01 * ya[i + 1] + h11 * hi * d[i + 1];
}

/* Akima piecewise cubic (== scipy Akima1DInterpolator); needs >= 3 anchors */
static void ip_build_akima(pTHX_ ip_fit *F) {
	IV n = F->na; const NV *restrict xa = F->xa, *restrict ya = F->ya;
	Newx(F->h, n - 1, NV); SAVEFREEPV(F->h);
	NV *restrict m; Newx(m, n - 1, NV); SAVEFREEPV(m);
	for (IV i = 0; i < n - 1; i++) { F->h[i] = xa[i + 1] - xa[i]; m[i] = (ya[i + 1] - ya[i]) / F->h[i]; }
	NV *mm; Newx(mm, n + 3, NV); SAVEFREEPV(mm); // slopes extended two each side
	for (IV i = 0; i < n - 1; i++) mm[i + 2] = m[i];
	mm[1] = 2 * mm[2] - mm[3];
	mm[0] = 2 * mm[1] - mm[2];
	mm[n + 1] = 2 * mm[n]     - mm[n - 1];
	mm[n + 2] = 2 * mm[n + 1] - mm[n];
	Newx(F->d, n, NV); SAVEFREEPV(F->d); // tangents
	for (IV i = 0; i < n; i++) {
		NV m1 = mm[i], m2 = mm[i + 1], m3 = mm[i + 2], m4 = mm[i + 3];
		NV d1 = fabs(m4 - m3), d2 = fabs(m2 - m1);
		F->d[i] = (d1 + d2 == 0) ? (m2 + m3) / 2 : (d1 * m2 + d2 * m3) / (d1 + d2);
	}
}
static NV ip_eval_akima(const ip_fit *F, NV t) {
	IV n = F->na; const NV *xa = F->xa, *ya = F->ya, *h = F->h, *tk = F->d;
	IV i = ip_seg(xa, n, t); NV hi = h[i], s = t - xa[i];
	NV c2 = (3 * (ya[i + 1] - ya[i]) / hi - 2 * tk[i] - tk[i + 1]) / hi;
	NV c3 = (tk[i] + tk[i + 1] - 2 * (ya[i + 1] - ya[i]) / hi) / (hi * hi);
	return ya[i] + tk[i] * s + c2 * s * s + c3 * s * s * s;
}

// global interpolating polynomial in barycentric form (== scipy barycentric/krogh)
static void ip_build_bary(pTHX_ ip_fit *F) {
	IV n = F->na; const NV *restrict xa = F->xa;
	Newx(F->w, n, NV); SAVEFREEPV(F->w);
	for (IV j = 0; j < n; j++) {
		NV wj = 1.0;
		for (IV k = 0; k < n; k++) if (k != j) wj /= (xa[j] - xa[k]);
		F->w[j] = wj;
	}
}
static NV ip_eval_bary(const ip_fit *F, NV t) {
	IV n = F->na; const NV *restrict xa = F->xa, *restrict ya = F->ya, *restrict w = F->w;
	NV num = 0, den = 0;
	for (IV j = 0; j < n; j++) {
		if (t == xa[j]) return ya[j];
		NV c = w[j] / (t - xa[j]);
		num += c * ya[j]; den += c;
	}
	return num / den;
}

static NV ip_eval_linear(const ip_fit *F, NV t) {
	IV n = F->na; const NV *restrict xa = F->xa, *restrict ya = F->ya;
	IV i = ip_seg(xa, n, t);
	return ya[i] + (ya[i + 1] - ya[i]) * (t - xa[i]) / (xa[i + 1] - xa[i]);
}

static NV ip_eval(const ip_fit *F, NV t) {
	switch (F->type) {
		case IP_KLINEAR: return ip_eval_linear(F, t);
		case IP_KCUBIC:  return ip_eval_cubic(F, t);
		case IP_KQUAD:   return ip_eval_quad(F, t);
		case IP_KPCHIP:  return ip_eval_pchip(F, t);
		case IP_KAKIMA:  return ip_eval_akima(F, t);
		case IP_KBARY:   return ip_eval_bary(F, t);
	}
	return 0;
}

/* map a piecewise-local method name to its (interior rule, edge rule); returns
 * 0 for the fit-based methods */
static int ip_local_rule(const char *m, int *rule, int *edge) {
	if (!strcmp(m, "linear") || !strcmp(m, "index") || !strcmp(m, "values") || !strcmp(m, "time"))
		{ *rule = IP_LINEAR; *edge = IP_EDGE_BOTH; return 1; }
	if (!strcmp(m, "slinear")) { *rule = IP_LINEAR;  *edge = IP_EDGE_NONE;  return 1; }
	if (!strcmp(m, "nearest")) { *rule = IP_NEAREST; *edge = IP_EDGE_NONE;  return 1; }
	if (!strcmp(m, "zero"))    { *rule = IP_LEFT;    *edge = IP_EDGE_NONE;  return 1; }
	if (!strcmp(m, "pad") || !strcmp(m, "ffill"))    { *rule = IP_LEFT;  *edge = IP_EDGE_LEFT;  return 1; }
	if (!strcmp(m, "bfill") || !strcmp(m, "backfill")) { *rule = IP_RIGHT; *edge = IP_EDGE_RIGHT; return 1; }
	return 0;
}

/* pandas _interp_limit (readable form): mark every gap whose [i-fw .. i+bw]
 * window is entirely gaps */
static void ip_far(const char *kind, IV n, IV fw, IV bw, char *pre) {
	for (IV i = 0; i < n; i++) {
		if (kind[i] != 0) continue;
		IV lo = i - fw; if (lo < 0) lo = 0;
		IV hi = i + bw; if (hi > n - 1) hi = n - 1;
		bool all = 1;
		for (IV k = lo; k <= hi; k++) if (kind[k] != 0) { all = 0; break; }
		if (all) pre[i] = 1;
	}
}

/* fill the undef gaps of one column in place (see block header) */
static void ip_fill_column(pTHX_ AV *vals, AV *xav, const char *method,
                           SV *order_sv, const char *dir, SV *limit_sv, SV *area_sv) {
	IV n = av_len(vals) + 1;
	if (n <= 0) return;

	NV  *restrict x, *restrict y; char *restrict kind;
	Newx(x, n, NV);       SAVEFREEPV(x);
	Newx(y, n, NV);       SAVEFREEPV(y);
	Newx(kind, n, char);  SAVEFREEPV(kind);
	IV anchors = 0;
	for (IV i = 0; i < n; i++) {
		SV **restrict xp = av_fetch(xav, i, 0);
		x[i] = (xp && *xp) ? SvNV(*xp) : 0;
		SV **restrict vp = av_fetch(vals, i, 0);
		SV  *restrict v  = (vp && *vp) ? *vp : NULL;
		if (!v || !SvOK(v))            kind[i] = 0; // gap
		else if (looks_like_number(v)) { kind[i] = 1; y[i] = SvNV(v); anchors++; } // anchor
		else                           kind[i] = 2; // barrier
	}
	if (anchors == 0) return;

	NV   *restrict cand; Newx(cand, n, NV);   SAVEFREEPV(cand);
	char *restrict has;  Newxz(has, n, char); SAVEFREEPV(has);

	int rule, edge;
	if (ip_local_rule(method, &rule, &edge)) {
		IV *restrict prev, *restrict next;
		Newx(prev, n, IV); SAVEFREEPV(prev);
		Newx(next, n, IV); SAVEFREEPV(next);
		ip_prevnext(kind, n, prev, next);
		for (IV i = 0; i < n; i++) {
			if (kind[i] != 0) continue;
			IV l = prev[i], r = next[i];
			if (l >= 0 && r >= 0) {
				NV vl = y[l], vr = y[r];
				if      (rule == IP_LINEAR)  cand[i] = vl + (vr - vl) * (x[i] - x[l]) / (x[r] - x[l]);
				else if (rule == IP_NEAREST) cand[i] = (x[i] - x[l] <= x[r] - x[i]) ? vl : vr;
				else if (rule == IP_LEFT)    cand[i] = vl;
				else                         cand[i] = vr;
				has[i] = 1;
			} else if (l >= 0) {
				if (edge == IP_EDGE_BOTH || edge == IP_EDGE_LEFT)  { cand[i] = y[l]; has[i] = 1; }
			} else if (r >= 0) {
				if (edge == IP_EDGE_BOTH || edge == IP_EDGE_RIGHT) { cand[i] = y[r]; has[i] = 1; }
			}
		}
	} else if (anchors >= 2) {
		NV *restrict xa, *restrict ya;
		Newx(xa, anchors, NV); SAVEFREEPV(xa);
		Newx(ya, anchors, NV); SAVEFREEPV(ya);
		IV na = 0;
		for (IV i = 0; i < n; i++) if (kind[i] == 1) { xa[na] = x[i]; ya[na] = y[i]; na++; }
		for (IV i = 1; i < na; i++)
			if (!(xa[i] > xa[i - 1]))
				croak("interpolate: method '%s' needs strictly increasing x coordinates", method);

		IV order = SvOK(order_sv) ? SvIV(order_sv) : 0;
		int deg = -1, extrap = 0, ktype = 0;
		if      (!strcmp(method, "pchip")) { ktype = IP_KPCHIP; extrap = 1; }
		else if (!strcmp(method, "akima")) { ktype = IP_KAKIMA; extrap = 0; }
		else if (!strcmp(method, "barycentric") || !strcmp(method, "krogh")) { ktype = IP_KBARY; extrap = 1; }
		else {
			if      (!strcmp(method, "cubicspline")) { extrap = 1; deg = 3; }
			else if (!strcmp(method, "spline"))      { extrap = 0; deg = order; }
			else if (!strcmp(method, "polynomial"))  { extrap = 0; deg = order; }
			else if (!strcmp(method, "quadratic"))   { extrap = 0; deg = 2; }
			else if (!strcmp(method, "cubic"))       { extrap = 0; deg = 3; }
			if      (deg == 1) ktype = IP_KLINEAR;
			else if (deg == 2) {
				if (na < 3) croak("interpolate: method '%s' (degree 2) needs at least 3 numeric anchors", method);
				ktype = IP_KQUAD;
			} else if (deg == 3) {
				if (na < 4 && strcmp(method, "cubicspline") != 0)
					croak("interpolate: method '%s' (degree 3) needs at least 4 numeric anchors", method);
				ktype = IP_KCUBIC;
			} else
				croak("interpolate: method '%s' supports order 1, 2, or 3 (got %ld)", method, (long)order);
		}
		if (ktype == IP_KAKIMA && na == 2) ktype = IP_KCUBIC;// akima degenerates to the line

		ip_fit F; Zero(&F, 1, ip_fit);
		F.na = na; F.xa = xa; F.ya = ya; F.type = ktype;
		switch (ktype) {
			case IP_KLINEAR: break;
			case IP_KCUBIC:  ip_build_cubic(aTHX_ &F); break;
			case IP_KQUAD:   ip_build_quad(aTHX_ &F);  break;
			case IP_KPCHIP:  ip_build_pchip(aTHX_ &F); break;
			case IP_KAKIMA:  ip_build_akima(aTHX_ &F); break;
			case IP_KBARY:   ip_build_bary(aTHX_ &F);  break;
		}
		NV xmin = xa[0], xmax = xa[na - 1];
		for (IV i = 0; i < n; i++) {
			if (kind[i] != 0) continue;
			NV xv = x[i];
			if      (xv >= xmin && xv <= xmax) { cand[i] = ip_eval(&F, xv); has[i] = 1; }
			else if (extrap)                   { cand[i] = ip_eval(&F, xv); has[i] = 1; }
		}
	}

	/* pandas preserve_nans: which gaps must stay NA under limit/direction/area */
	char *restrict pre; Newxz(pre, n, char); SAVEFREEPV(pre);
	IV first = n, last = -1;
	for (IV i = 0; i < n; i++)     if (kind[i] == 1) { first = i; break; }
	for (IV i = n - 1; i >= 0; i--) if (kind[i] == 1) { last = i; break; }
	int have_limit = SvOK(limit_sv);
	IV  limit = have_limit ? SvIV(limit_sv) : 0;
	if (!strcmp(dir, "forward")) {
		for (IV i = 0; i < first; i++) pre[i] = 1;
		if (have_limit) ip_far(kind, n, limit, 0, pre);
	} else if (!strcmp(dir, "backward")) {
		for (IV i = last + 1; i < n; i++) pre[i] = 1;
		if (have_limit) ip_far(kind, n, 0, limit, pre);
	} else { // both
		if (have_limit) ip_far(kind, n, limit, limit, pre);
	}
	if (SvOK(area_sv)) {
		const char *area = SvPV_nolen(area_sv);
		if (!strcmp(area, "inside")) {
			for (IV i = 0; i < first; i++)    pre[i] = 1;
			for (IV i = last + 1; i < n; i++) pre[i] = 1;
		} else if (!strcmp(area, "outside")) {
			for (IV i = 0; i < n; i++) if (kind[i] == 0 && i >= first && i <= last) pre[i] = 1;
		}
	}

	for (IV i = 0; i < n; i++) {
		if (kind[i] != 0 || !has[i] || pre[i]) continue;
		SV *nsv = newSVnv(cand[i]);
		if (av_store(vals, i, nsv) == NULL) SvREFCNT_dec(nsv);
	}
}

/* ---- epidemiology: parse a 2x2 table from an array ref ------------------
 * Accepts a flat [a,b,c,d] or a nested [[a,b],[c,d]].  Layout convention
 * (rows = exposure/treatment, columns = outcome):
 *          outcome+   outcome-
 *   exp+       a          b
 *   exp-       c          d
 * Croaks on a malformed shape or a negative count.                          */
static void epi_read_2x2(pTHX_ SV *restrict sv, const char *restrict who,
                         NV *restrict a, NV *restrict b, NV *restrict c, NV *restrict d) {
	if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV)
		croak("%s: expected a 2x2 table as an array ref [a,b,c,d] or [[a,b],[c,d]]", who);
	AV *restrict av = (AV *)SvRV(sv);
	SSize_t top = av_len(av);
	if (top == 3) {                                   /* flat [a,b,c,d] */
		*a = SvNV(*av_fetch(av, 0, 0)); *b = SvNV(*av_fetch(av, 1, 0));
		*c = SvNV(*av_fetch(av, 2, 0)); *d = SvNV(*av_fetch(av, 3, 0));
	} else if (top == 1) {                            /* nested [[a,b],[c,d]] */
		SV **restrict r0 = av_fetch(av, 0, 0), **restrict r1 = av_fetch(av, 1, 0);
		if (!r0 || !r1 || !SvROK(*r0) || !SvROK(*r1)
		    || SvTYPE(SvRV(*r0)) != SVt_PVAV || SvTYPE(SvRV(*r1)) != SVt_PVAV)
			croak("%s: 2-row form must be [[a,b],[c,d]]", who);
		AV *restrict ar0 = (AV *)SvRV(*r0), *restrict ar1 = (AV *)SvRV(*r1);
		if (av_len(ar0) != 1 || av_len(ar1) != 1)
			croak("%s: each row of a 2x2 table needs exactly 2 cells", who);
		*a = SvNV(*av_fetch(ar0, 0, 0)); *b = SvNV(*av_fetch(ar0, 1, 0));
		*c = SvNV(*av_fetch(ar1, 0, 0)); *d = SvNV(*av_fetch(ar1, 1, 0));
	} else {
		croak("%s: expected 4 cells (a,b,c,d) or 2 rows of 2 cells", who);
	}
	if (*a < 0 || *b < 0 || *c < 0 || *d < 0)
		croak("%s: cell counts must be non-negative", who);
}

/* ---- ROC / AUC ---------------------------------------------------------- */
typedef struct { NV score; int lab; } ROCPt;      /* lab: 1 = positive case */
static int rocpt_cmp_desc(const void *a, const void *b) {
	const ROCPt *pa = (const ROCPt *)a, *pb = (const ROCPt *)b;
	if (pa->score > pb->score) return -1;
	if (pa->score < pb->score) return 1;
	return 0;
}

/* (value, original-index) pair, sorted ascending by value.  Used by bedroc's
 * active_frac mode to pick exactly ceil(frac*N) items from the low or high
 * tail of the second array as the actives (matching an argsort selection). */
typedef struct { NV v; size_t i; } NVIdx;
static int nvidx_cmp_asc(const void *a, const void *b) {
	NV x = ((const NVIdx *)a)->v, y = ((const NVIdx *)b)->v;
	return (x > y) - (x < y);
}

/* Split parallel score/label arrays into the positive and negative score
 * vectors.  A label counts as positive when its string form equals `positive`.
 * With lower_pos set, the score sign is flipped (lower marker => more positive).
 * Allocates pos/neg via Newx; the caller frees them.  Croaks on a bad shape. */
static void roc_split(pTHX_ AV *restrict sav, AV *restrict lav,
                      const char *restrict positive, int lower_pos,
                      NV **restrict pos, size_t *restrict m,
                      NV **restrict neg, size_t *restrict n, const char *who) {
	SSize_t N = av_len(sav) + 1;
	if (N != av_len(lav) + 1)
		croak("%s: scores and labels must be the same length", who);
	if (N < 1) croak("%s: need at least one observation", who);
	NV *restrict P; Newx(P, N, NV);
	NV *restrict Q; Newx(Q, N, NV);
	size_t mm = 0, nn = 0;
	for (SSize_t i = 0; i < N; i++) {
		SV **restrict sp = av_fetch(sav, i, 0), **lp = av_fetch(lav, i, 0);
		NV s = (sp && *sp) ? SvNV(*sp) : NAN;
		if (lower_pos) s = -s;
		bool ispos = (lp && *lp) ? strEQ(SvPV_nolen(*lp), positive) : 0;
		if (ispos) P[mm++] = s; else Q[nn++] = s;
	}
	if (mm == 0 || nn == 0) {
		Safefree(P); Safefree(Q);
		croak("%s: need both positive and negative labels (positive='%s')", who, positive);
	}
	*pos = P; *m = mm; *neg = Q; *n = nn;
}

/* DeLong AUC (c-statistic) and its standard error for one ROC curve.  Higher
 * score = more positive.  Midranks make ties exact; AUC equals the
 * Mann-Whitney concordance probability.                                     */
static void roc_delong(pTHX_ const NV *restrict pos, size_t m,
                       const NV *restrict neg, size_t n,
                       NV *restrict auc_out, NV *restrict se_out) {
	size_t N = m + n;
	NV *restrict comb, *restrict TX, *restrict TY, *restrict TZ, *restrict V10, *restrict V01;
	Newx(comb, N, NV); Newx(TX, m, NV); Newx(TY, n, NV);
	Newx(TZ, N, NV);   Newx(V10, m, NV); Newx(V01, n, NV);
	for (size_t i = 0; i < m; i++) comb[i]     = pos[i];
	for (size_t j = 0; j < n; j++) comb[m + j] = neg[j];
	rank_data(pos,  TX, m);           /* midranks within positives          */
	rank_data(neg,  TY, n);           /* midranks within negatives          */
	rank_data(comb, TZ, N);           /* midranks in the combined sample    */
	NV auc = 0.0;
	for (size_t i = 0; i < m; i++) { V10[i] = (TZ[i] - TX[i]) / (NV)n; auc += V10[i]; }
	auc /= (NV)m;
	for (size_t j = 0; j < n; j++)   V01[j] = 1.0 - (TZ[m + j] - TY[j]) / (NV)m;
	NV s10 = 0.0, s01 = 0.0;
	for (size_t i = 0; i < m; i++) { NV dz = V10[i] - auc; s10 += dz * dz; }
	for (size_t j = 0; j < n; j++) { NV dz = V01[j] - auc; s01 += dz * dz; }
	s10 = (m > 1) ? s10 / (NV)(m - 1) : 0.0;
	s01 = (n > 1) ? s01 / (NV)(n - 1) : 0.0;
	*auc_out = auc;
	*se_out  = sqrt(s10 / (NV)m + s01 / (NV)n);
	Safefree(comb); Safefree(TX); Safefree(TY); Safefree(TZ); Safefree(V10); Safefree(V01);
}

/* ---- survival analysis -------------------------------------------------- */
typedef struct { NV time; int status; int grp; } SurvObs;   /* status: 1=event */
static int survobs_cmp(const void *a, const void *b) {
	const SurvObs *pa = (const SurvObs *)a, *pb = (const SurvObs *)b;
	if (pa->time < pb->time) return -1;
	if (pa->time > pb->time) return 1;
	return pb->status - pa->status;      /* events before censors at a tie */
}

/* Gauss-Jordan solve of A x = b (A is n*n row-major, destroyed in place).
 * Returns 0 on success, 1 if (near-)singular.  Used for the log-rank quadratic
 * form on the (g-1)-dimensional reduced observed-minus-expected vector.      */
static int srv_solve(NV *restrict A, const NV *restrict b, int n, NV *restrict x) {
	for (int i = 0; i < n; i++) x[i] = b[i];
	for (int col = 0; col < n; col++) {
		int piv = col; NV best = fabs(A[col * n + col]);
		for (int r = col + 1; r < n; r++) { NV v = fabs(A[r * n + col]); if (v > best) { best = v; piv = r; } }
		if (best < 1e-300) return 1;
		if (piv != col) {
			for (int c = 0; c < n; c++) { NV t = A[col*n+c]; A[col*n+c] = A[piv*n+c]; A[piv*n+c] = t; }
			NV t = x[col]; x[col] = x[piv]; x[piv] = t;
		}
		NV d = A[col * n + col];
		for (int r = 0; r < n; r++) {
			if (r == col) continue;
			NV f = A[r * n + col] / d;
			for (int c = col; c < n; c++) A[r * n + c] -= f * A[col * n + c];
			x[r] -= f * x[col];
		}
	}
	for (int i = 0; i < n; i++) x[i] /= A[i * n + i];
	return 0;
}

/* Invert an n*n matrix A (row-major) into inv via Gauss-Jordan with partial
 * pivoting; A is destroyed.  Returns 0 on success, 1 if (near-)singular.
 * Used for the Cox information matrix (coef covariance = its inverse).       */
static int mat_inv(NV *restrict A, int n, NV *restrict inv) {
	for (int i = 0; i < n * n; i++) inv[i] = (i % n == i / n) ? 1.0 : 0.0;
	for (int col = 0; col < n; col++) {
		int piv = col; NV best = fabs(A[col * n + col]);
		for (int r = col + 1; r < n; r++) { NV v = fabs(A[r * n + col]); if (v > best) { best = v; piv = r; } }
		if (best < 1e-300) return 1;
		if (piv != col)
			for (int c = 0; c < n; c++) {
				NV t = A[col*n+c]; A[col*n+c] = A[piv*n+c]; A[piv*n+c] = t;
				t = inv[col*n+c]; inv[col*n+c] = inv[piv*n+c]; inv[piv*n+c] = t;
			}
		NV d = A[col * n + col];
		for (int c = 0; c < n; c++) { A[col*n+c] /= d; inv[col*n+c] /= d; }
		for (int r = 0; r < n; r++) {
			if (r == col) continue;
			NV f = A[r * n + col];
			for (int c = 0; c < n; c++) { A[r*n+c] -= f * A[col*n+c]; inv[r*n+c] -= f * inv[col*n+c]; }
		}
	}
	return 0;
}

typedef struct { NV time; int idx; } TimeIdx; // sort observations by time

/* Read parallel time/status(/group) arrays into a SurvObs array.  Group index
 * is assigned by first appearance of each label string; the labels are pushed
 * (as SVs) into *labels_out in that order.  gav == NULL => one group "".
 * status is 1 (event) when the value is non-zero, else 0 (censored).         */
static SurvObs* srv_read(pTHX_ AV *restrict tav, AV *restrict sav, AV *restrict gav,
                         size_t *restrict N_out, AV *restrict labels, const char *who) {
	SSize_t N = av_len(tav) + 1;
	if (N != av_len(sav) + 1) croak("%s: time and status must be the same length", who);
	if (gav && N != av_len(gav) + 1) croak("%s: group must match time/status length", who);
	if (N < 1) croak("%s: need at least one observation", who);
	SurvObs *restrict o; Newx(o, N, SurvObs);
	for (SSize_t i = 0; i < N; i++) {
		SV **restrict tp = av_fetch(tav, i, 0), **sp = av_fetch(sav, i, 0);
		NV t = (tp && *tp) ? SvNV(*tp) : NAN;
		if (t < 0) { Safefree(o); croak("%s: negative survival time", who); }
		o[i].time   = t;
		o[i].status = (sp && *sp && SvNV(*sp) != 0.0) ? 1 : 0;
		int g = 0;
		if (gav) {
			SV **gp = av_fetch(gav, i, 0);
			const char *lab = (gp && *gp) ? SvPV_nolen(*gp) : "";
			SSize_t G = av_len(labels) + 1, found = -1;
			for (SSize_t k = 0; k < G; k++)
				if (strEQ(SvPV_nolen(*av_fetch(labels, k, 0)), lab)) { found = k; break; }
			if (found < 0) { found = G; av_push(labels, newSVpv(lab, 0)); }
			g = (int)found;
		}
		o[i].grp = g;
	}
	if (av_len(labels) < 0) av_push(labels, newSVpv("", 0));   /* single group */
	*N_out = (size_t)N;
	return o;
}

/* Adjust m raw p-values (writes adj[]) for a family of methods, matching R's
 * p.adjust / the dunn.test package.  Used by dunn_test. */
static void dunn_padjust(const NV *restrict p, size_t m, const char *restrict meth, NV *restrict adj) {
	size_t *restrict ord = NULL; Newx(ord, m, size_t);   /* indices of p sorted ascending */
	for (size_t i = 0; i < m; i++) ord[i] = i;
	for (size_t a = 0; a + 1 < m; a++)                   /* small m; simple insertion sort */
		for (size_t b = a + 1; b < m; b++)
			if (p[ord[b]] < p[ord[a]]) { size_t t = ord[a]; ord[a] = ord[b]; ord[b] = t; }

	if (strEQ(meth, "none")) {
		for (size_t i = 0; i < m; i++) adj[i] = p[i];
	} else if (strEQ(meth, "bonferroni")) {
		for (size_t i = 0; i < m; i++) { NV v = p[i] * m; adj[i] = v < 1.0 ? v : 1.0; }
	} else if (strEQ(meth, "sidak")) {
		for (size_t i = 0; i < m; i++) { NV v = 1.0 - pow(1.0 - p[i], (NV)m); adj[i] = v < 1.0 ? v : 1.0; }
	} else if (strEQ(meth, "holm")) {
		NV cummax = 0.0;
		for (size_t i = 0; i < m; i++) { NV v = p[ord[i]] * (m - i); if (v > cummax) cummax = v; adj[ord[i]] = cummax < 1.0 ? cummax : 1.0; }
	} else if (strEQ(meth, "hs")) {   /* Holm-Sidak */
		NV cummax = 0.0;
		for (size_t i = 0; i < m; i++) { NV v = 1.0 - pow(1.0 - p[ord[i]], (NV)(m - i)); if (v > cummax) cummax = v; adj[ord[i]] = cummax < 1.0 ? cummax : 1.0; }
	} else if (strEQ(meth, "bh")) {
		NV cummin = 1.0;
		for (ssize_t i = (ssize_t)m - 1; i >= 0; i--) { NV v = p[ord[i]] * m / (i + 1.0); if (v < cummin) cummin = v; adj[ord[i]] = cummin < 1.0 ? cummin : 1.0; }
	} else if (strEQ(meth, "by")) {
		NV q = 0.0; for (size_t i = 1; i <= m; i++) q += 1.0 / i;
		NV cummin = 1.0;
		for (ssize_t i = (ssize_t)m - 1; i >= 0; i--) { NV v = p[ord[i]] * m / (i + 1.0) * q; if (v < cummin) cummin = v; adj[ord[i]] = cummin < 1.0 ? cummin : 1.0; }
	} else {
		Safefree(ord);
		croak("dunn_test: unknown method '%s' (none, bonferroni, sidak, holm, hs, bh, by)", meth);
	}
	Safefree(ord);
}

/* --- shared machinery for skew() and kurtosis() ------------------------
 Both statistics are ratios of central moments, so both need the same one
 pass over the sample.  The recurrence is Welford's, carried up to the third
 and fourth moments (Terriberry).  What this buys over the textbook
 expansion in raw moments -- m3 = Sx^3/n - 3*xbar*Sx^2/n + 2*xbar^3 -- is
 everything: for a column of values around 1e7 (a lab value in the wrong
 units, a timestamp) Sx^3/n is ~1e21 while m3 is single digits, so that form
 cancels away every significant figure.  Centering first, whether in a
 second pass or by this recurrence, is what keeps the answer; the recurrence
 additionally needs no second look at the input, which matters because the
 input here may be a bare list on the argument stack.  m2..m4 hold the
 *sums* of the powered deviations, not the moments; callers divide by n. */
typedef struct {
	NV mean, m2, m3, m4;
	size_t n;
} moment_acc;

static void moment_push(moment_acc *restrict a, NV x) {
	const NV n1 = (NV)a->n;                /* count before this observation */
	a->n++;
	const NV n     = (NV)a->n;
	const NV delta = x - a->mean;
	const NV dn    = delta / n;
	const NV dn2   = dn * dn;
	const NV term  = delta * dn * n1;      /* == n1/n * delta^2 */
	a->m4   += term * dn2 * (n * n - 3.0 * n + 3.0)
	         + 6.0 * dn2 * a->m2 - 4.0 * dn * a->m3;
	a->m3   += term * dn * (n - 2.0) - 3.0 * dn * a->m2;
	a->m2   += term;
	a->mean += dn;
}

static void moment_av(pTHX_ AV *restrict av, size_t argi,
                      const char *restrict fname, moment_acc *restrict acc) {
	const size_t len = av_len(av) + 1;
	if (SvRMAGICAL((SV*)av)) {
		/* Tied, so the cells are not in AvARRAY at all.  av_fetch hands back
		 * a deferred PVLV rather than the value, and SvOK on that is false
		 * until the get-magic runs -- without SvGETMAGIC every element of a
		 * tied array looks undefined. */
		for (size_t j = 0; j < len; j++) {
			SV **restrict tv = av_fetch(av, j, 0);
			if (tv) SvGETMAGIC(*tv);
			if (tv && SvOK(*tv)) moment_push(acc, SvNV(*tv));
			else croak("%s: undefined value at array ref index %" UVuf
			           " (argument %" UVuf ")", fname, (UV)j, (UV)argi);
		}
		return;
	}
	SV **restrict src = AvARRAY(av);
	for (SSize_t j = 0; j < len; j++) {
		SV *restrict tv = src[j];
		if (tv && SvOK(tv)) moment_push(acc, SvNV(tv));
		else croak("%s: undefined value at array ref index %" UVuf
		           " (argument %" UVuf ")", fname, (UV)j, (UV)argi);
	}
}

/* Walk an argument list of numbers, array refs of numbers and 'type'/'x'
 * named pairs.  Shared so that skew() and kurtosis() cannot drift apart on
 * what they accept.  A named key is recognised only when the SV is a string
 * that is not a number, so it can never swallow a data value -- and anything
 * else that looks like a bareword is a typo worth reporting rather than
 * silently averaging in as zero.                                            */
static void moment_args(pTHX_ SV **restrict args, size_t items,
                        const char *restrict fname,
                        moment_acc *restrict acc, IV *restrict type) {
	for (size_t i = 0; i < items; i++) {
		SV *restrict arg = args[i];
		if (arg && SvPOK(arg) && !SvROK(arg) && !looks_like_number(arg)) {
			const char *restrict key = SvPV_nolen(arg);
			const bool is_type = strEQ(key, "type");
			if (!is_type && !strEQ(key, "x"))
				croak("%s: unknown argument '%s' (expected numbers, array "
				      "refs, x => \\@data or type => 1|2|3)", fname, key);
			if (i + 1 >= items)
				croak("%s: '%s' needs a value", fname, key);
			SV *restrict val = args[++i];
			if (is_type) {
				if (!SvOK(val) || !looks_like_number(val))
					croak("%s: type must be 1, 2 or 3", fname);
				*type = SvIV(val);
				if (*type < 1 || *type > 3)
					croak("%s: type must be 1, 2 or 3, not %" IVdf, fname, *type);
			} else {
				if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVAV)
					croak("%s: 'x' must be an array reference", fname);
				moment_av(aTHX_ (AV*)SvRV(val), i, fname, acc);
			}
		} else if (arg && SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) {
			moment_av(aTHX_ (AV*)SvRV(arg), i, fname, acc);
		} else if (arg && SvOK(arg)) {
			moment_push(acc, SvNV(arg));
		} else {
			croak("%s: undefined value at argument index %" UVuf, fname, (UV)i);
		}
	}
}

// --- XS SECTION ---
MODULE = Stats::LikeR  PACKAGE = Stats::LikeR

void
_interp_column_xs(vals_ref, x_ref, method, order_sv, dir, limit_sv, area_sv)
	SV *vals_ref
	SV *x_ref
	const char *method
	SV *order_sv
	const char *dir
	SV *limit_sv
	SV *area_sv
	PPCODE:
		if (!(SvROK(vals_ref) && SvTYPE(SvRV(vals_ref)) == SVt_PVAV))
			croak("_interp_column_xs: values must be an array reference");
		if (!(SvROK(x_ref) && SvTYPE(SvRV(x_ref)) == SVt_PVAV))
			croak("_interp_column_xs: x must be an array reference");
		ENTER; SAVETMPS;
		ip_fill_column(aTHX_ (AV *)SvRV(vals_ref), (AV *)SvRV(x_ref),
		               method, order_sv, dir, limit_sv, area_sv);
		FREETMPS; LEAVE;
		XSRETURN_EMPTY;

SV *_cols_select(df, shape, spec)
	SV *df
	IV shape
	SV *spec
  PREINIT:
	SV *restrict retval; AV *restrict spec_av; SSize_t n, i;
  CODE:
{
	spec_av = (AV *)SvRV(spec);
	n = av_len(spec_av) + 1;
	if (shape == 3) { // ---- AoA ----
		IV *restrict idx; Newx(idx, n > 0 ? n : 1, IV);
		for (i = 0; i < n; i++) { SV **e = av_fetch(spec_av, i, 0); idx[i] = SvIV(*e); }
		AV *restrict src = (AV *)SvRV(df); SSize_t R = av_len(src) + 1;
		AV *restrict out = newAV(); if (R > 0) av_extend(out, R - 1);
		for (i = 0; i < R; i++) {
			SV **restrict rp = av_fetch(src, i, 0); AV *inner;
			if (rp && *rp && SvROK(*rp) && SvTYPE(SvRV(*rp)) == SVt_PVAV)
				inner = rowA_select(aTHX_ (AV *)SvRV(*rp), idx, n);
			else
				inner = rowA_select(aTHX_ NULL, idx, n);
			av_store(out, i, newRV_noinc((SV *)inner));
		}
		Safefree(idx);
		retval = sv_2mortal(newRV_noinc((SV *)out));
	} else {
		SV **restrict keys; Newx(keys, n > 0 ? n : 1, SV *);
		for (i = 0; i < n; i++) { SV **e = av_fetch(spec_av, i, 0); keys[i] = *e; }
		if (shape == 1) { // ---- AoH ----
			AV *restrict src = (AV *)SvRV(df); SSize_t R = av_len(src) + 1;
			AV *restrict out = newAV(); if (R > 0) av_extend(out, R - 1);
			for (i = 0; i < R; i++) {
				SV **restrict rp = av_fetch(src, i, 0); HV *inner;
				if (rp && *rp && SvROK(*rp) && SvTYPE(SvRV(*rp)) == SVt_PVHV)
					inner = row_select(aTHX_ (HV *)SvRV(*rp), keys, n);
				else
					inner = row_select(aTHX_ NULL, keys, n);
				av_store(out, i, newRV_noinc((SV *)inner));
			}
			retval = sv_2mortal(newRV_noinc((SV *)out));
		} else { // ---- HoH ----
			HV *restrict src = (HV *)SvRV(df); HV *out = newHV();
			hv_iterinit(src); HE *restrict he;
			while ((he = hv_iternext(src))) {
				STRLEN kl; char *restrict kp = HePV(he, kl); I32 sk = HeUTF8(he) ? -(I32)kl : (I32)kl;
				SV *restrict rv = HeVAL(he); HV *inner;
				if (rv && SvROK(rv) && SvTYPE(SvRV(rv)) == SVt_PVHV)
					inner = row_select(aTHX_ (HV *)SvRV(rv), keys, n);
				else
					inner = row_select(aTHX_ NULL, keys, n);
				(void)hv_store(out, kp, sk, newRV_noinc((SV *)inner), HeHASH(he));
			}
			retval = sv_2mortal(newRV_noinc((SV *)out));
		}
		Safefree(keys);
	}
	RETVAL = SvREFCNT_inc(retval);
}
  OUTPUT:
	RETVAL

# shape: 1 = AoH, 2 = HoH. dropset: hashref whose keys are the columns to remove
SV *
_cols_drop(df, shape, dropset)
	SV *df
	IV shape
	SV *dropset
  PREINIT:
	SV *restrict retval; HV *restrict drop_hv; SSize_t i;
  CODE:
{
	drop_hv = (HV *)SvRV(dropset);
	if (shape == 1) { // AoH
		AV *restrict src = (AV *)SvRV(df); SSize_t R = av_len(src) + 1;
		AV *restrict out = newAV(); if (R > 0) av_extend(out, R - 1);
		for (i = 0; i < R; i++) {
			SV **restrict rp = av_fetch(src, i, 0); HV *inner;
			if (rp && *rp && SvROK(*rp) && SvTYPE(SvRV(*rp)) == SVt_PVHV)
				inner = row_drop(aTHX_ (HV *)SvRV(*rp), drop_hv);
			else
				inner = row_drop(aTHX_ NULL, drop_hv);
			av_store(out, i, newRV_noinc((SV *)inner));
		}
		retval = sv_2mortal(newRV_noinc((SV *)out));
	} else { // HoH
		HV *restrict src = (HV *)SvRV(df); HV *out = newHV();
		hv_iterinit(src); HE *he;
		while ((he = hv_iternext(src))) {
			STRLEN kl; char *kp = HePV(he, kl); I32 sk = HeUTF8(he) ? -(I32)kl : (I32)kl;
			SV *restrict rv = HeVAL(he); HV *inner;
			if (rv && SvROK(rv) && SvTYPE(SvRV(rv)) == SVt_PVHV)
				inner = row_drop(aTHX_ (HV *)SvRV(rv), drop_hv);
			else
				inner = row_drop(aTHX_ NULL, drop_hv);
			(void)hv_store(out, kp, sk, newRV_noinc((SV *)inner), HeHASH(he));
		}
		retval = sv_2mortal(newRV_noinc((SV *)out));
	}
	RETVAL = SvREFCNT_inc(retval);
}
  OUTPUT:
	RETVAL

# shape: 1 = AoH, 2 = HoH. map: hashref old-name => new-name
SV *
_cols_rename(df, shape, map)
	SV *df
	IV shape
	SV *map
  PREINIT:
	SV *restrict retval; HV *restrict map_hv; SSize_t i;
  CODE:
{
	map_hv = (HV *)SvRV(map);
	if (shape == 1) { // ---- AoH ----
		AV *restrict src = (AV *)SvRV(df); SSize_t R = av_len(src) + 1;
		AV *restrict out = newAV(); if (R > 0) av_extend(out, R - 1);
		for (i = 0; i < R; i++) {
			SV **restrict rp = av_fetch(src, i, 0); HV *inner;
			if (rp && *rp && SvROK(*rp) && SvTYPE(SvRV(*rp)) == SVt_PVHV)
				inner = row_rename(aTHX_ (HV *)SvRV(*rp), map_hv);
			else
				inner = row_rename(aTHX_ NULL, map_hv);
			av_store(out, i, newRV_noinc((SV *)inner));
		}
		retval = sv_2mortal(newRV_noinc((SV *)out));
	} else { // ---- HoH ----
		HV *restrict src = (HV *)SvRV(df); HV *out = newHV();
		hv_iterinit(src); HE *he;
		while ((he = hv_iternext(src))) {
			STRLEN kl; char *kp = HePV(he, kl); I32 sk = HeUTF8(he) ? -(I32)kl : (I32)kl;
			SV *restrict rv = HeVAL(he); HV *inner;
			if (rv && SvROK(rv) && SvTYPE(SvRV(rv)) == SVt_PVHV)
				inner = row_rename(aTHX_ (HV *)SvRV(rv), map_hv);
			else
				inner = row_rename(aTHX_ NULL, map_hv);
			(void)hv_store(out, kp, sk, newRV_noinc((SV *)inner), HeHASH(he));
		}
		retval = sv_2mortal(newRV_noinc((SV *)out));
	}
	RETVAL = SvREFCNT_inc(retval);
}
  OUTPUT:
	RETVAL

# Union of the column names over an AoH's rows, in first-seen order.  Same scan
# as _present_keys, but the Perl loop it replaces walked every key of every row
# through the interpreter and cost more than the de-duplication itself on a
# large frame.  As in _present_keys, a row that is not a plain (unblessed) hash
# ref contributes nothing.  The HeHASH of a key is reused so no key is hashed
# twice -- except for a UTF-8 key, where hv_store may canonicalise the bytes
# first and the stored hash would then be the wrong one.
SV *
_aoh_key_union(df)
	SV *df
  PREINIT:
	AV *restrict src; AV *restrict out; HV *restrict seen; SSize_t i, R;
  CODE:
{
	src   = (AV *)SvRV(df);
	R     = av_len(src) + 1;
	out   = newAV();
	seen  = (HV *)sv_2mortal((SV *)newHV());
	for (i = 0; i < R; i++) {
		SV *restrict rv = AvARRAY(src)[i];
		if (!rv || !SvROK(rv)) continue;
		HV *restrict row = (HV *)SvRV(rv);
		if (SvTYPE((SV *)row) != SVt_PVHV || SvOBJECT((SV *)row)) continue;
		HE *restrict he; hv_iterinit(row);
		while ((he = hv_iternext(row))) {
			STRLEN kl; char *restrict kp = HePV(he, kl);
			const bool u8 = cBOOL(HeUTF8(he));
			const SSize_t before = HvUSEDKEYS(seen);
			(void)hv_store(seen, kp, u8 ? -(I32)kl : (I32)kl,
			               SvREFCNT_inc_simple_NN(&PL_sv_yes), u8 ? 0 : HeHASH(he));
			if (HvUSEDKEYS(seen) != before)     /* first sighting of this name */
				av_push(out, newSVpvn_flags(kp, kl, u8 ? SVf_UTF8 : 0));
		}
	}
	RETVAL = newRV_noinc((SV *)out);
}
  OUTPUT:
	RETVAL

# Row-level de-duplication core for drop_duplicates().  The Perl wrapper
# validates the frame, rejects HoH, and resolves `subset` into an ordered
# list of column identifiers (integer positions for AoA, names for AoH/HoA).
#   shape: 1 = AoH, 3 = AoA, 4 = HoA
#   subset: arrayref of the columns whose cells define a row's identity
#   keep:  1 = first occurrence, -1 = last occurrence, 0 = drop every dup
# AoA/AoH survivors reuse the original row refs (cells shared, like dropna);
# HoA rebuilds every column sliced to the surviving row positions.
#
# One pass over the rows interns each row key (see dd_intern) and that is all
# the bookkeeping any of the three `keep` modes needs, because groups are
# created in row order: T.first[] -- the row that first showed each distinct
# key -- therefore comes out already sorted, and IS the survivor list.
#   keep ==  1  every T.first[g], as is
#   keep == -1  the rows are walked backwards, so T.first[g] is each key's LAST
#               occurrence and the list only has to be reversed
#   keep ==  0  the groups seen exactly once, filtered in place
# So nothing is allocated per input row: the pass costs one copy of each
# distinct key plus a handful of words per distinct row.
SV *
_drop_dups_core(df, shape, subset, keep)
	SV *df
	IV shape
	SV *subset
	IV keep
  PREINIT:
	SV *restrict retval; AV *restrict sub_av; SSize_t ns, i, j, R = 0, nsurv = 0;
	SSize_t *restrict surv; dd_ctx *restrict T;
  CODE:
{
	sub_av = (AV *)SvRV(subset);
	ns = av_len(sub_av) + 1;
	ENTER;                          /* everything below is freed on croak too */
	Newxz(T, 1, dd_ctx);
	SAVEDESTRUCTOR_X(dd_ctx_free, T);
	T->use_cnt = (keep == 0);

	if (shape == 3) { // ---- AoA ----
		AV *restrict src = (AV *)SvRV(df);
		R = av_len(src) + 1;
		Newx(T->pos, ns > 0 ? ns : 1, IV);
		for (j = 0; j < ns; j++) T->pos[j] = SvIV(AvARRAY(sub_av)[j]);
		for (SSize_t r = 0; r < R; r++) {
			i = keep == -1 ? R - 1 - r : r;    /* backwards == keep last */
			SV *restrict rv = (i <= AvFILLp(src)) ? AvARRAY(src)[i] : NULL;
			AV *restrict inner = (rv && SvROK(rv) && SvTYPE(SvRV(rv)) == SVt_PVAV)
			          ? (AV *)SvRV(rv) : NULL;
			const size_t start = T->len;
			for (j = 0; j < ns; j++) {
				const IV p = T->pos[j];
				SV *restrict c = (inner && p >= 0 && p <= AvFILLp(inner))
				               ? AvARRAY(inner)[p] : NULL;
				dd_cell(aTHX_ T, c);
			}
			const SSize_t g = dd_intern(aTHX_ T, start, i);
			if (T->use_cnt) T->cnt[g]++;
		}
	} else if (shape == 1) { // ---- AoH ----
		AV *restrict src = (AV *)SvRV(df);
		SV **restrict names = AvARRAY(sub_av);
		R = av_len(src) + 1;
		for (SSize_t r = 0; r < R; r++) {
			i = keep == -1 ? R - 1 - r : r;
			SV *restrict rv = (i <= AvFILLp(src)) ? AvARRAY(src)[i] : NULL;
			HV *restrict inner = (rv && SvROK(rv) && SvTYPE(SvRV(rv)) == SVt_PVHV)
			          ? (HV *)SvRV(rv) : NULL;
			const size_t start = T->len;
			for (j = 0; j < ns; j++) {
				HE *restrict he = inner ? hv_fetch_ent(inner, names[j], 0, 0) : NULL;
				dd_cell(aTHX_ T, he ? HeVAL(he) : NULL);
			}
			const SSize_t g = dd_intern(aTHX_ T, start, i);
			if (T->use_cnt) T->cnt[g]++;
		}
	} else { // ---- HoA ----
		HV *restrict src = (HV *)SvRV(df);
		HE *restrict he; hv_iterinit(src);
		while ((he = hv_iternext(src))) { // R = longest column
			SV *v = HeVAL(he);
			if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV) {
				SSize_t l = av_len((AV *)SvRV(v)) + 1;
				if (l > R) R = l;
			}
		}
		Newx(T->cols, ns > 0 ? ns : 1, AV *);
		for (j = 0; j < ns; j++) {
			HE *restrict ce = hv_fetch_ent(src, AvARRAY(sub_av)[j], 0, 0);
			T->cols[j] = (ce && SvROK(HeVAL(ce)) && SvTYPE(SvRV(HeVAL(ce))) == SVt_PVAV)
			        ? (AV *)SvRV(HeVAL(ce)) : NULL;
		}
		for (SSize_t r = 0; r < R; r++) {
			i = keep == -1 ? R - 1 - r : r;
			const size_t start = T->len;
			for (j = 0; j < ns; j++) {
				AV *restrict cv = T->cols[j];
				SV *restrict c = (cv && i <= AvFILLp(cv)) ? AvARRAY(cv)[i] : NULL;
				dd_cell(aTHX_ T, c);
			}
			const SSize_t g = dd_intern(aTHX_ T, start, i);
			if (T->use_cnt) T->cnt[g]++;
		}
	}
	/* the keys have done their job; only first[]/cnt[] are still needed */
	Safefree(T->buf);   T->buf   = NULL; T->len = T->cap = 0;
	Safefree(T->off);   T->off   = NULL;
	Safefree(T->khash); T->khash = NULL;
	Safefree(T->slot);  T->slot  = NULL; T->nslot = 0;
	Safefree(T->pos);   T->pos   = NULL;
	Safefree(T->cols);  T->cols  = NULL;

	// the surviving row positions, in input order
	surv  = T->first;
	nsurv = T->ng;
	if (keep == -1) {                       /* rows were walked backwards */
		for (i = 0, j = nsurv - 1; i < j; i++, j--) {
			const SSize_t t = surv[i]; surv[i] = surv[j]; surv[j] = t;
		}
	} else if (keep == 0) {                 /* drop every duplicated row */
		nsurv = 0;
		for (i = 0; i < T->ng; i++) if (T->cnt[i] == 1) surv[nsurv++] = surv[i];
	}

	// materialise the survivors back into the input's shape
	if (shape == 4) { // ---- HoA ----
		HV *restrict src = (HV *)SvRV(df);
		HV *restrict out = newHV();
		HE *restrict he; hv_iterinit(src);
		while ((he = hv_iternext(src))) {
			SV *restrict v = HeVAL(he);
			AV *restrict col = (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV) ? (AV *)SvRV(v) : NULL;
			const SSize_t cfill = col ? AvFILLp(col) : -1;
			SV **restrict ca = col ? AvARRAY(col) : NULL;
			AV *restrict nc = newAV();
			if (nsurv > 0) {
				av_extend(nc, nsurv - 1);
				SV **restrict na = AvARRAY(nc);
				for (SSize_t k = 0; k < nsurv; k++) {
					SV *restrict c = surv[k] <= cfill ? ca[surv[k]] : NULL;
					na[k] = c ? newSVsv(c) : newSV(0);
				}
				AvFILLp(nc) = nsurv - 1;
			}
			STRLEN kl; char *kp = HePV(he, kl); I32 sk = HeUTF8(he) ? -(I32)kl : (I32)kl;
			(void)hv_store(out, kp, sk, newRV_noinc((SV *)nc), HeHASH(he));
		}
		retval = sv_2mortal(newRV_noinc((SV *)out));
	} else { // AoA / AoH
		AV *restrict src = (AV *)SvRV(df);
		const SSize_t sfill = AvFILLp(src);
		SV **restrict sa = AvARRAY(src);
		AV *restrict out = newAV();
		if (nsurv > 0) {
			av_extend(out, nsurv - 1);
			SV **restrict oa = AvARRAY(out);
			for (SSize_t k = 0; k < nsurv; k++) {
				SV *restrict rv = surv[k] <= sfill ? sa[surv[k]] : NULL;
				oa[k] = newSVsv(rv ? rv : &PL_sv_undef);
			}
			AvFILLp(out) = nsurv - 1;
		}
		retval = sv_2mortal(newRV_noinc((SV *)out));
	}
	RETVAL = SvREFCNT_inc(retval);
	LEAVE;                                  /* dd_ctx_free releases the rest */
}
  OUTPUT:
	RETVAL

void anova(...)
	PROTOTYPE: $@
	PREINIT:
		SV *restrict data;
		char *lhs = NULL, *rhs = NULL;
		HV *restrict hoa = NULL, *restrict result = NULL;
		HV **restrict rows = NULL;
		AnTerm *terms = NULL;
		AnFac  *facs  = NULL;
		size_t nterms = 0, tcap = 0, nfac = 0, fcap = 0;
		bool *restrict complete = NULL, *restrict aliased = NULL;
		size_t *restrict ridx = NULL, *rank_map = NULL;
		size_t n = 0, n_used = 0, p, rank;
		NV **restrict X = NULL, *restrict y = NULL, rss, msres;
		IV dfres;
	PPCODE:
	{
		if (items < 2)
			croak("anova: usage anova(\\%%data, 'response ~ terms' [, 'model2', ...])");
		data = ST(0);

		if (items > 2) {
			/*  nested model comparison  *
			 * anova(\%data, 'y ~ a', 'y ~ a + b', ...) -> ArrayRef table.  */
			size_t nform = (size_t)items - 1;
			char **restrict lhss = NULL, **rhss = NULL;
			Newxz(lhss, nform, char*);
			Newxz(rhss, nform, char*);

			/* ---- parse every formula */
			for (size_t fi = 0; fi < nform; fi++) {
				SV *restrict fsv = ST(1 + fi);
				if (!(SvPOK(fsv) || SvOK(fsv))) {
					anova_free_formulas(aTHX_ lhss, rhss, nform);
					croak("anova: model argument %" UVuf " must be a formula string", (UV)(fi + 1));
				}
				if (!parse_formula(SvPV_nolen(fsv), &lhss[fi], &rhss[fi])) {
					anova_free_formulas(aTHX_ lhss, rhss, nform);
					croak("anova: could not parse formula %" UVuf " (need 'response ~ terms')", (UV)(fi + 1));
				}
			}
// ---- resolve data form + row count (response 1 length)
			if (!SvROK(data)) {
				anova_free_formulas(aTHX_ lhss, rhss, nform);
				croak("anova: first argument must be a hash or array reference");
			}
			{
				SV *rv = SvRV(data);
				if (SvTYPE(rv) == SVt_PVHV) {
					hoa = (HV*)rv;
					SV **restrict col = hv_fetch(hoa, lhss[0], (I32)strlen(lhss[0]), 0);
					if (col && SvROK(*col) && SvTYPE(SvRV(*col)) == SVt_PVAV)
						n = (size_t)(av_len((AV*)SvRV(*col)) + 1);
					else {
						hv_iterinit(hoa);
						HE *restrict e;
						while ((e = hv_iternext(hoa))) {
							SV *v = hv_iterval(hoa, e);
							if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV) {
								size_t l = (size_t)(av_len((AV*)SvRV(v)) + 1);
								if (l > n) n = l;
							}
						}
					}
				} else if (SvTYPE(rv) == SVt_PVAV) {
					AV *top = (AV*)rv;
					n = (size_t)(av_len(top) + 1);
					Newx(rows, n ? n : 1, HV*);
					for (size_t i = 0; i < n; i++) {
						SV **ep = av_fetch(top, i, 0);
						if (!(ep && SvROK(*ep) && SvTYPE(SvRV(*ep)) == SVt_PVHV)) {
							Safefree(rows);
							anova_free_formulas(aTHX_ lhss, rhss, nform);
							croak("anova: element %" UVuf " is not a hash reference", (UV)i);
						}
						rows[i] = (HV*)SvRV(*ep);
					}
				} else {
					anova_free_formulas(aTHX_ lhss, rhss, nform);
					croak("anova: first argument must be a hash or array reference");
				}
			}
// union factor registry across all formulas
			{
				AnFac *ufacs = NULL; size_t unfac = 0, ufcap = 0;
				for (size_t fi = 0; fi < nform; fi++) {
					AnTerm *tt = NULL; size_t ntt = 0, ttcap = 0;
					anova_expand_rhs(aTHX_ rhss[fi], &tt, &ntt, &ttcap);
					for (size_t t = 0; t < ntt; t++)
						for (size_t j = 0; j < tt[t].nf; j++)
							(void)anova_fac(aTHX_ &ufacs, &unfac, &ufcap, hoa, rows, n, tt[t].factors[j]);
					anova_free_terms(aTHX_ tt, ntt);
				}
// ---- listwise completeness over the union */
				Newx(complete, n ? n : 1, bool);
				n_used = 0;
				for (size_t i = 0; i < n; i++) {
					bool ok = TRUE;
					for (size_t fi = 0; ok && fi < nform; fi++)
						if (!isfinite(evaluate_term(aTHX_ hoa, rows, (unsigned)i, lhss[fi]))) ok = FALSE;
					for (size_t f = 0; ok && f < unfac; f++) {
						if (ufacs[f].is_cat) {
							char *sv = get_data_string_alloc(aTHX_ hoa, rows, i, ufacs[f].name);
							if (!sv) ok = FALSE; else Safefree(sv);
						} else if (!isfinite(evaluate_term(aTHX_ hoa, rows, (unsigned)i, ufacs[f].name))) {
							ok = FALSE;
						}
					}
					complete[i] = ok;
					if (ok) n_used++;
				}
				anova_free_facs(aTHX_ ufacs, unfac);
			}

			if (n_used < 2) {
				Safefree(complete); Safefree(rows);
				anova_free_formulas(aTHX_ lhss, rhss, nform);
				croak("anova: fewer than 2 complete observations after dropping NA");
			}

			Newx(ridx, n_used, size_t);
			{ size_t r = 0; for (size_t i = 0; i < n; i++) if (complete[i]) ridx[r++] = i; }
// fit every model on the shared row set
			{
				NV *restrict mrss = NULL; IV *restrict mresdf = NULL;
				Newx(mrss,   nform, NV);
				Newx(mresdf, nform, IV);
				for (size_t fi = 0; fi < nform; fi++) {
					NV rss_i; size_t rank_i;
					if (!anova_fit_one(aTHX_ hoa, rows, n, complete, ridx, n_used,
					                   lhss[fi], rhss[fi], &rss_i, &rank_i)) {
						Safefree(mrss); Safefree(mresdf);
						Safefree(ridx); Safefree(complete); Safefree(rows);
						anova_free_formulas(aTHX_ lhss, rhss, nform);
						croak("anova: formula %" UVuf " has no predictor terms", (UV)(fi + 1));
					}
					mrss[fi]   = rss_i;
					mresdf[fi] = (IV)n_used - (IV)rank_i;
				}
				/* common scale = residual MS of the largest model
				 * (smallest residual df), exactly as R's anova.lmlist. */
				size_t big = 0;
				for (size_t fi = 1; fi < nform; fi++)
					if (mresdf[fi] < mresdf[big]) big = fi;
				NV scale  = (mresdf[big] > 0) ? mrss[big] / (NV)mresdf[big] : NAN;
				IV df_big = mresdf[big];
				// one row per model, in supplied order
				AV *restrict table = newAV();
				for (size_t fi = 0; fi < nform; fi++) {
					HV *row = newHV();
					(void)hv_store(row, "Res.Df", 6, newSViv(mresdf[fi]), 0);
					(void)hv_store(row, "RSS",    3, newSVnv(mrss[fi]),   0);
					(void)hv_store(row, "formula", 7,
					               newSVpvf("%s ~ %s", lhss[fi], rhss[fi]), 0);
					if (fi > 0) {
						IV ddf = mresdf[fi - 1] - mresdf[fi];
						NV dss = mrss[fi - 1] - mrss[fi];
						(void)hv_store(row, "Df", 2, newSViv(ddf), 0);
						(void)hv_store(row, "Sum of Sq", 9, newSVnv(dss), 0);
						if (ddf > 0 && isfinite(scale) && scale > 0.0) {
							NV F = (dss / (NV)ddf) / scale;
							(void)hv_store(row, "F", 1, newSVnv(F), 0);
							(void)hv_store(row, "Pr(>F)", 6,
							               newSVnv(pf_upper(F, (NV)ddf, (NV)df_big)), 0);
						}
					}
					av_push(table, newRV_noinc((SV*)row));
				}

				Safefree(mrss); Safefree(mresdf);
				Safefree(ridx); Safefree(complete); Safefree(rows);
				anova_free_formulas(aTHX_ lhss, rhss, nform);

				XPUSHs(sv_2mortal(newRV_noinc((SV*)table)));
			}
		} else {// single-model Type-I table */
			if (!(SvPOK(ST(1)) || SvOK(ST(1))))
				croak("anova: second argument must be a formula string");
			if (!parse_formula(SvPV_nolen(ST(1)), &lhs, &rhs))
				croak("anova: could not parse formula (need 'response ~ terms')");
			// ---- resolve data form + row count
			if (!SvROK(data)) { safefree(lhs); safefree(rhs); croak("anova: first argument must be a hash or array reference"); }
			{
				SV *restrict rv = SvRV(data);
				if (SvTYPE(rv) == SVt_PVHV) {
					hoa = (HV*)rv;
					SV **restrict col = hv_fetch(hoa, lhs, (I32)strlen(lhs), 0);
					if (col && SvROK(*col) && SvTYPE(SvRV(*col)) == SVt_PVAV)
						n = (size_t)(av_len((AV*)SvRV(*col)) + 1);
					else {
// response may be an expression; fall back to longest column
						hv_iterinit(hoa);
						HE *restrict e;
						while ((e = hv_iternext(hoa))) {
							SV *restrict v = hv_iterval(hoa, e);
							if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV) {
								size_t l = (size_t)(av_len((AV*)SvRV(v)) + 1);
								if (l > n) n = l;
							}
						}
					}
				} else if (SvTYPE(rv) == SVt_PVAV) {
					AV *restrict top = (AV*)rv;
					n = (size_t)(av_len(top) + 1);
					Newx(rows, n ? n : 1, HV*);
					for (size_t i = 0; i < n; i++) {
						SV **restrict ep = av_fetch(top, i, 0);
						if (!(ep && SvROK(*ep) && SvTYPE(SvRV(*ep)) == SVt_PVHV)) {
							Safefree(rows); safefree(lhs); safefree(rhs);
							croak("anova: element %" UVuf " is not a hash reference", (UV)i);
						}
						rows[i] = (HV*)SvRV(*ep);
					}
				} else {
					safefree(lhs); safefree(rhs);
					croak("anova: first argument must be a hash or array reference");
				}
			}
			/* expand RHS into ordered, de-duplicated terms  */
			anova_expand_rhs(aTHX_ rhs, &terms, &nterms, &tcap);
			if (nterms == 0) {
				anova_free_terms(aTHX_ terms, nterms); Safefree(rows);
				safefree(lhs); safefree(rhs);
				croak("anova: formula has no predictor terms");
			}
			/* factor registry + per-term factor indices  */
			for (size_t t = 0; t < nterms; t++) {
				Newx(terms[t].fi, terms[t].nf, size_t);
				for (size_t j = 0; j < terms[t].nf; j++)
					terms[t].fi[j] = anova_fac(aTHX_ &facs, &nfac, &fcap, hoa, rows, n, terms[t].factors[j]);
			}
			// listwise completeness
			Newx(complete, n ? n : 1, bool);
			n_used = 0;
			for (size_t i = 0; i < n; i++) {
				bool ok = isfinite(evaluate_term(aTHX_ hoa, rows, (unsigned)i, lhs)) ? TRUE : FALSE;
				for (size_t f = 0; ok && f < nfac; f++) {
					if (facs[f].is_cat) {
						char *sv = get_data_string_alloc(aTHX_ hoa, rows, i, facs[f].name);
						if (!sv) ok = FALSE; else Safefree(sv);
					} else if (!isfinite(evaluate_term(aTHX_ hoa, rows, (unsigned)i, facs[f].name))) {
						ok = FALSE;
					}
				}
				complete[i] = ok;
				if (ok) n_used++;
			}
			if (n_used < 2) {
				anova_free_terms(aTHX_ terms, nterms);
				anova_free_facs(aTHX_ facs, nfac);
				Safefree(complete); Safefree(rows); safefree(lhs); safefree(rhs);
				croak("anova: fewer than 2 complete observations after dropping NA");
			}
			Newx(ridx, n_used, size_t);
			{ size_t r = 0; for (size_t i = 0; i < n; i++) if (complete[i]) ridx[r++] = i; }

			/* ---- factor widths + coded columns ------------------------- */
			for (size_t f = 0; f < nfac; f++) {
				if (facs[f].is_cat) {
					facs[f].nlv = anova_levels(aTHX_ hoa, rows, n, complete, facs[f].name, &facs[f].lv);
					facs[f].width = facs[f].nlv > 1 ? facs[f].nlv - 1 : 0;
				} else {
					facs[f].width = 1;
				}
				if (facs[f].width == 0) continue;
				Newx(facs[f].col, n_used * facs[f].width, NV);
				if (facs[f].is_cat) {
					for (size_t r = 0; r < n_used; r++) {
						char *sv = get_data_string_alloc(aTHX_ hoa, rows, ridx[r], facs[f].name);
						for (size_t j = 1; j < facs[f].nlv; j++)
							facs[f].col[r * facs[f].width + (j - 1)] =
								(sv && strcmp(sv, facs[f].lv[j]) == 0) ? 1.0 : 0.0;
						Safefree(sv);
					}
				} else {
					for (size_t r = 0; r < n_used; r++)
						facs[f].col[r] = evaluate_term(aTHX_ hoa, rows, (unsigned)ridx[r], facs[f].name);
				}
			}
			/* ---- term widths + design layout ------------------*/
			p = 1;
			for (size_t t = 0; t < nterms; t++) {
				size_t w = 1;
				for (size_t j = 0; j < terms[t].nf; j++) w *= facs[terms[t].fi[j]].width;
				terms[t].width = w;
				terms[t].start = p;
				p += w;
			}
			/* ---- build design matrix (intercept + term blocks) */
			Newx(y, n_used, NV);
			Newx(X, n_used, NV*);
			for (size_t r = 0; r < n_used; r++) {
				Newx(X[r], p, NV);
				X[r][0] = 1.0;
				y[r] = evaluate_term(aTHX_ hoa, rows, (unsigned)ridx[r], lhs);
			}
			for (size_t t = 0; t < nterms; t++) {
				size_t w = terms[t].width;
				if (w == 0) continue;                    /* degenerate: no columns */
				for (size_t r = 0; r < n_used; r++) {
					for (size_t c = 0; c < w; c++) {
						size_t rem = c; NV v = 1.0;
						for (size_t j = 0; j < terms[t].nf; j++) {
							AnFac *fj = &facs[terms[t].fi[j]];
							size_t d = rem % fj->width; rem /= fj->width;
							v *= fj->col[r * fj->width + d];
						}
						X[r][terms[t].start + c] = v;
					}
				}
			}
			// sequential QR (X, y overwritten in place)
			Newx(aliased,  p, bool);
			Newx(rank_map, p, size_t);
			for (size_t k = 0; k < p; k++) rank_map[k] = 0;
			apply_householder_aov(X, y, n_used, p, aliased, rank_map);

			rank = 0;
			for (size_t k = 0; k < p; k++) if (!aliased[k]) rank++;
			rss = 0.0;
			for (size_t r = rank; r < n_used; r++) rss += y[r] * y[r];
			dfres = (IV)n_used - (IV)rank;
			msres = dfres > 0 ? rss / (NV)dfres : NAN;

			// assemble term-keyed table
			result = newHV();
			for (size_t t = 0; t < nterms; t++) {
				NV ss = 0.0; IV df = 0;
				for (size_t k = terms[t].start; k < terms[t].start + terms[t].width; k++)
					if (!aliased[k]) { ss += y[rank_map[k]] * y[rank_map[k]]; df++; }

				HV *restrict in = newHV();
				(void)hv_store(in, "Df", 2, newSViv(df), 0);
				(void)hv_store(in, "Sum Sq", 6, newSVnv(ss), 0);
				if (df > 0) {
					(void)hv_store(in, "Mean Sq", 7, newSVnv(ss / (NV)df), 0);
					if (dfres > 0 && rss > 0.0) {
						NV F = (ss / (NV)df) / msres;
						(void)hv_store(in, "F value", 7, newSVnv(F), 0);
						(void)hv_store(in, "Pr(>F)", 6, newSVnv(pf_upper(F, (NV)df, (NV)dfres)), 0);
					}
				}
				(void)hv_store(result, terms[t].name, (I32)strlen(terms[t].name),
				               newRV_noinc((SV*)in), 0);
			}
			{
				HV *restrict in = newHV();
				(void)hv_store(in, "Df", 2, newSViv(dfres), 0);
				(void)hv_store(in, "Sum Sq", 6, newSVnv(rss), 0);
				if (dfres > 0) (void)hv_store(in, "Mean Sq", 7, newSVnv(msres), 0);
				(void)hv_store(result, "Residuals", 9, newRV_noinc((SV*)in), 0);
			}
			// teardown
			for (size_t r = 0; r < n_used; r++) Safefree(X[r]);
			Safefree(X); Safefree(y);
			Safefree(aliased); Safefree(rank_map); Safefree(ridx); Safefree(complete);
			anova_free_terms(aTHX_ terms, nterms);
			anova_free_facs(aTHX_ facs, nfac);
			Safefree(rows);
			safefree(lhs); safefree(rhs);

			XPUSHs(sv_2mortal(newRV_noinc((SV*)result)));
		}
	}

void rank(...)
	PROTOTYPE: @
	PPCODE:
		int ties   = RANK_AVERAGE;
		int nalast = NALAST_TRUE;

		// ---- locate trailing "key => value" options -------------
		// Options begin at the first plain-string arg equal to a
		// known option name; everything before it is data.
		int opt_start = items;
		for (int i = 0; i < items; i++) {
			SV *a = ST(i);
			if (SvOK(a) && !SvROK(a) && SvPOK(a)) {
				STRLEN klen;
				const char *k = SvPV_const(a, klen);
				if ((klen == 11 && strEQ(k, "ties.method")) ||
				    (klen == 7  && strEQ(k, "na.last"))) {
					opt_start = i;
					break;
				}
			}
		}

		if (((items - opt_start) & 1) != 0)
			croak("rank: named options must be key => value pairs");

		for (int i = opt_start; i < items; i += 2) {
			STRLEN klen, vlen;
			const char *k = SvPV_const(ST(i), klen);
			SV *vsv = ST(i + 1);
			if (strEQ(k, "ties.method")) {
				if (!SvOK(vsv))
					croak("rank: ties.method cannot be undef");
				const char *v = SvPV_const(vsv, vlen);
				if      (strEQ(v, "average")) ties = RANK_AVERAGE;
				else if (strEQ(v, "first"))   ties = RANK_FIRST;
				else if (strEQ(v, "last"))    ties = RANK_LAST;
				else if (strEQ(v, "random"))  ties = RANK_RANDOM;
				else if (strEQ(v, "max"))     ties = RANK_MAX;
				else if (strEQ(v, "min"))     ties = RANK_MIN;
				else croak("rank: unknown ties.method '%s' "
				           "(average, first, last, random, max, min)", v);
			} else if (strEQ(k, "na.last")) {
				if (!SvOK(vsv)) {
					nalast = NALAST_DROP;             // undef => R's NA
				} else {
					const char *v = SvPV_const(vsv, vlen);
					if      (strEQ(v, "keep"))                       nalast = NALAST_KEEP;
					else if (strEQ(v, "na")    || strEQ(v, "NA"))    nalast = NALAST_DROP;
					else if (strEQ(v, "false") || strEQ(v, "FALSE")
					     ||  strEQ(v, "F")     || strEQ(v, "0"))     nalast = NALAST_FALSE;
					else if (strEQ(v, "true")  || strEQ(v, "TRUE")
					     ||  strEQ(v, "T")     || strEQ(v, "1"))     nalast = NALAST_TRUE;
					else croak("rank: unknown na.last '%s' "
					           "(true, false, keep, na)", v);
				}
			} else {
				croak("rank: unknown option '%s' (ties.method, na.last)", k);
			}
		}

		// ---- count total data elements --------------------------
		size_t N = 0;
		for (int i = 0; i < opt_start; i++) {
			SV *a = ST(i);
			if (SvROK(a) && SvTYPE(SvRV(a)) == SVt_PVAV)
				N += (size_t)(av_len((AV *)SvRV(a)) + 1);
			else
				N += 1;
		}
		if (N == 0) XSRETURN_EMPTY;

		// ---- gather values, flag NAs (undef or NaN) -------------
		char      *na    = NULL;   // 1 if element is NA
		IV        *nidx  = NULL;   // non-NA index per position, else -1
		rank_pair *pairs = NULL;   // packed non-NA values
		Newx(na,    N, char);
		Newx(nidx,  N, IV);
		Newx(pairs, N, rank_pair);

		size_t n = 0;   // number of non-NA values
		size_t p = 0;   // running position
		for (int i = 0; i < opt_start; i++) {
			SV *a = ST(i);
			if (SvROK(a) && SvTYPE(SvRV(a)) == SVt_PVAV) {
				AV *av = (AV *)SvRV(a);
				size_t len = (size_t)(av_len(av) + 1);
				for (size_t j = 0; j < len; j++) {
					SV **tv = av_fetch(av, j, 0);
					if (tv && SvOK(*tv)) {
						NV val = SvNV(*tv);
						if (val != val) {          // NaN => NA
							na[p] = 1; nidx[p] = -1;
						} else {
							na[p] = 0; nidx[p] = (IV)n;
							pairs[n].val = val;
							pairs[n].idx = (IV)n;
							n++;
						}
					} else {
						na[p] = 1; nidx[p] = -1;
					}
					p++;
				}
			} else if (SvOK(a)) {
				NV val = SvNV(a);
				if (val != val) {                  // NaN => NA
					na[p] = 1; nidx[p] = -1;
				} else {
					na[p] = 0; nidx[p] = (IV)n;
					pairs[n].val = val;
					pairs[n].idx = (IV)n;
					n++;
				}
				p++;
			} else {
				na[p] = 1; nidx[p] = -1;
				p++;
			}
		}

		// ---- sort the non-NA values -----------------------------
		if (ties == RANK_RANDOM)
			for (size_t k = 0; k < n; k++) pairs[k].rnd = Drand01();

		if (n > 1) {
			if      (ties == RANK_RANDOM) qsort(pairs, n, sizeof(rank_pair), rank_cmp_rnd_asc);
			else if (ties == RANK_LAST)   qsort(pairs, n, sizeof(rank_pair), rank_cmp_idx_desc);
			else                          qsort(pairs, n, sizeof(rank_pair), rank_cmp_idx_asc);
		}

		// ---- assign ranks (1-based) by non-NA index -------------
		NV *rank_of = NULL;
		Newx(rank_of, n ? n : 1, NV);
		if (ties == RANK_AVERAGE || ties == RANK_MIN || ties == RANK_MAX) {
			size_t k = 0;
			while (k < n) {
				size_t j = k;
				while (j + 1 < n && pairs[j + 1].val == pairs[k].val) j++;
				NV assigned;
				if      (ties == RANK_MIN) assigned = (NV)(k + 1);
				else if (ties == RANK_MAX) assigned = (NV)(j + 1);
				else                       assigned = ((NV)(k + 1) + (NV)(j + 1)) / 2.0;
				for (size_t m = k; m <= j; m++)
					rank_of[pairs[m].idx] = assigned;
				k = j + 1;
			}
		} else {
			for (size_t k = 0; k < n; k++)
				rank_of[pairs[k].idx] = (NV)(k + 1);
		}
		Safefree(pairs); pairs = NULL;

		// ---- emit results in original order, per na.last --------
		size_t nna = N - n;                          // number of NAs
		size_t M   = (nalast == NALAST_DROP) ? n : N;
		EXTEND(SP, (SSize_t)M);

		if (nalast == NALAST_DROP) {
			for (size_t q = 0; q < N; q++) {
				if (na[q]) continue;
				NV rv = rank_of[nidx[q]];
				if (rv == (NV)(IV)rv) mPUSHi((IV)rv); else mPUSHn(rv);
			}
		} else if (nalast == NALAST_KEEP) {
			for (size_t q = 0; q < N; q++) {
				if (na[q]) { PUSHs(&PL_sv_undef); continue; }
				NV rv = rank_of[nidx[q]];
				if (rv == (NV)(IV)rv) mPUSHi((IV)rv); else mPUSHn(rv);
			}
		} else if (nalast == NALAST_TRUE) {
			size_t na_rank = n;
			for (size_t q = 0; q < N; q++) {
				if (na[q]) { mPUSHi((IV)(++na_rank)); continue; }
				NV rv = rank_of[nidx[q]];
				if (rv == (NV)(IV)rv) mPUSHi((IV)rv); else mPUSHn(rv);
			}
		} else { // NALAST_FALSE
			size_t na_rank = 0;
			for (size_t q = 0; q < N; q++) {
				if (na[q]) { mPUSHi((IV)(++na_rank)); continue; }
				NV rv = rank_of[nidx[q]] + (NV)nna;
				if (rv == (NV)(IV)rv) mPUSHi((IV)rv); else mPUSHn(rv);
			}
		}

		Safefree(rank_of);
		Safefree(nidx);
		Safefree(na);

NV ptukey(q, nmeans, df, ...)
	NV q
	NV nmeans
	NV df
CODE:
{
	/* ptukey(q, nmeans, df, nranges => 1, lower_tail => 1, log_p => 0)
	 * Studentized range CDF, as in R's ptukey().  q may also be an
	 * arrayref, in which case a mortal arrayref is returned (see OUTPUT
	 * note below -- scalar form here, vector form handled by caller). */
	NV nranges = 1.0;
	bool lower_tail = TRUE, log_p = FALSE;
	if ((items - 3) % 2 != 0)
		croak("ptukey: expected q, nmeans, df followed by key => value pairs");
	for (int i = 3; i < items; i += 2) {
		const char *restrict key = SvPV_nolen(ST(i));
		SV *restrict val = ST(i + 1);
		if      (strEQ(key, "nranges"))    nranges    = SvNV(val);
		else if (strEQ(key, "lower_tail")) lower_tail = SvTRUE(val) ? TRUE : FALSE;
		else if (strEQ(key, "lower.tail")) lower_tail = SvTRUE(val) ? TRUE : FALSE;
		else if (strEQ(key, "log_p"))      log_p      = SvTRUE(val) ? TRUE : FALSE;
		else if (strEQ(key, "log.p"))      log_p      = SvTRUE(val) ? TRUE : FALSE;
		else croak("ptukey: unknown argument '%s'", key);
	}
	NV pr = st_ptukey(q, nranges, nmeans, df);
	if (!lower_tail) pr = 1.0 - pr;
	RETVAL = log_p ? log(pr) : pr;
}
OUTPUT:
	RETVAL

NV qtukey(p, nmeans, df, ...)
	NV p
	NV nmeans
	NV df
CODE:
{
	/* qtukey(p, nmeans, df, nranges => 1, lower_tail => 1, log_p => 0)
	 * Inverse studentized range CDF, as in R's qtukey(). */
	NV nranges = 1.0;
	bool lower_tail = TRUE, log_p = FALSE;
	if ((items - 3) % 2 != 0)
		croak("qtukey: expected p, nmeans, df followed by key => value pairs");
	for (int i = 3; i < items; i += 2) {
		const char *restrict key = SvPV_nolen(ST(i));
		SV *restrict val = ST(i + 1);
		if      (strEQ(key, "nranges"))    nranges    = SvNV(val);
		else if (strEQ(key, "lower_tail")) lower_tail = SvTRUE(val) ? TRUE : FALSE;
		else if (strEQ(key, "lower.tail")) lower_tail = SvTRUE(val) ? TRUE : FALSE;
		else if (strEQ(key, "log_p"))      log_p      = SvTRUE(val) ? TRUE : FALSE;
		else if (strEQ(key, "log.p"))      log_p      = SvTRUE(val) ? TRUE : FALSE;
		else croak("qtukey: unknown argument '%s'", key);
	}
	if (log_p)       p = exp(p);
	if (!lower_tail) p = 1.0 - p;
	RETVAL = st_qtukey(p, nranges, nmeans, df);
}
OUTPUT:
	RETVAL

SV *aoh2hoa(data)
	SV *data
	CODE:
	{
/* aoh2hoa($aoh) -- transpose an Array-of-Hashes into a Hash-of-Arrays.

 *   in : arrayref of hashrefs (rows)  [ {a=>1,b=>2}, {a=>3} ]
 *   out: hashref of arrayrefs (cols)  { a=>[1,3], b=>[2,undef] }

 * - Columns are the union of all row keys.
 * - Every column has exactly scalar(@$aoh) elements; cells absent
 *   from a given row are undef (kept as cheap holes, not SVs).
 * - Values are copied, so the result is independent of the input
 *   (a value that is itself a reference is copied shallowly, just
 *   like Perl's  $col->[$i] = $row->{$k} ).
 * - A row that is not a hashref contributes undef to every column
 *   at its index (skipped, not fatal).
*/
		AV *restrict aoh;
		HV *restrict out;
		SSize_t n, i;
		HE *restrict he;

		if (!SvROK(data) || SvTYPE(SvRV(data)) != SVt_PVAV)
			croak("aoh2hoa: argument must be an arrayref of hashrefs");

		aoh = (AV *)SvRV(data);
		n   = av_len(aoh) + 1;			/* number of rows */
		out = newHV();

		for (i = 0; i < n; i++) {
			SV **restrict rp = av_fetch(aoh, i, 0);
			HV  *restrict row;

			if (!(rp && *rp && SvROK(*rp)
			           && SvTYPE(SvRV(*rp)) == SVt_PVHV))
				continue;		/* non-hashref row -> all undef */

			row = (HV *)SvRV(*rp);
			hv_iterinit(row);
			while ((he = hv_iternext(row))) {
				SV *restrict ksv  = hv_iterkeysv(he);	/* utf8 / SV-key safe */
				HE *restrict oute = hv_fetch_ent(out, ksv, 0, 0);
				AV *restrict col;
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
		// pad every column out to exactly n elements (trailing undefs)
		hv_iterinit(out);
		while ((he = hv_iternext(out))) {
			AV *restrict col = (AV *)SvRV(HeVAL(he));
			if (av_len(col) < n - 1)
				av_fill(col, n - 1);
		}
		RETVAL = newRV_noinc((SV *)out);
	}
	OUTPUT:
		RETVAL

SV* binom_test(...)
CODE:
{
	if (items < 1) croak("binom_test requires at least the number of successes");

	long x = 0, n = 0;
	bool have_n = 0;
	unsigned int pos = 1; // index where named args begin

	SV *restrict x_sv = ST(0);
	if (SvROK(x_sv) && SvTYPE(SvRV(x_sv)) == SVt_PVAV) {
		/* x = [successes, failures]; n is derived */
		AV *restrict xa = (AV *)SvRV(x_sv);
		if (av_len(xa) != 1)
			croak("binom_test: x as an array ref must hold exactly 2 elements "
			      "(successes, failures)");
		long s = bt_check_count(aTHX_ *av_fetch(xa, 0, 0), "successes");
		long f = bt_check_count(aTHX_ *av_fetch(xa, 1, 0), "failures");
		x = s;
		n = s + f;
		have_n = 1;
	} else {
		/* x = successes (scalar); n must follow positionally */
		x = bt_check_count(aTHX_ x_sv, "x");
		if (items >= 2 && SvOK(ST(1)) && looks_like_number(ST(1))) {
			n = bt_check_count(aTHX_ ST(1), "n");
			have_n = 1;
			pos = 2;
		}
	}
	if (!have_n)
		croak("binom_test: number of trials n is required when x is a scalar");

	NV   p          = 0.5;
	/* parse through Perl so the echoed default is the exact nearest NV to
	 * 0.95 on every build (see fisher_test for the full rationale). */
	NV   conf_level = SvNV(sv_2mortal(newSVpvs("0.95")));
	const char *restrict alternative = "two.sided";

	for (unsigned int i = pos; i < items; i += 2) {
		if (i + 1 >= items) croak("binom_test: odd number of named arguments");
		const char *restrict key = SvPV_nolen(ST(i));
		SV *restrict val = ST(i + 1);
		if (strEQ(key, "p")) {
			p = SvNV(val);
			if (!(p >= 0.0 && p <= 1.0))
				croak("binom_test: p must be between 0 and 1");
		} else if (strEQ(key, "conf_level") || strEQ(key, "conf.level")) {
			conf_level = SvNV(val);
			if (!(conf_level > 0.0 && conf_level < 1.0))
				croak("binom_test: conf_level must be between 0 and 1");
		} else if (strEQ(key, "alternative")) {
			alternative = SvPV_nolen(val);
			if (strNE(alternative, "two.sided") && strNE(alternative, "less") &&
			    strNE(alternative, "greater"))
				croak("binom_test: alternative must be 'two.sided', 'less' or 'greater'");
		} else {
			croak("binom_test: unknown argument '%s'", key);
		}
	}
	if (n < 1) croak("binom_test: n must be a positive integer >= x");
	if (x > n) croak("binom_test: number of successes cannot exceed trials");
	// ---- p-value (switch on alternative, as R does)
	NV PVAL;
	if (strEQ(alternative, "less")) {
		PVAL = bt_pbinom_lower(x, n, p);              /* P(X <= x) */
	} else if (strEQ(alternative, "greater")) {
		PVAL = bt_pbinom_upper(x - 1, n, p);          /* P(X >= x) */
	} else {                                          /* two.sided */
		if (p == 0.0) {
			PVAL = (x == 0) ? 1.0 : 0.0;
		} else if (p == 1.0) {
			PVAL = (x == n) ? 1.0 : 0.0;
		} else {
			const NV relErr = 1.0 + 1e-7;
			NV d = bt_dbinom(x, n, p);
			NV m = (NV)n * p;
			if ((NV)x == m) {
				PVAL = 1.0;
			} else if ((NV)x < m) {
				long y = 0;
				for (long i = (long)ceil(m); i <= n; i++)
					if (bt_dbinom(i, n, p) <= d * relErr) y++;
				PVAL = bt_pbinom_lower(x, n, p) + bt_pbinom_upper(n - y, n, p);
			} else {
				long y = 0;
				for (long i = 0; i <= (long)floor(m); i++)
					if (bt_dbinom(i, n, p) <= d * relErr) y++;
				PVAL = bt_pbinom_lower(y - 1, n, p) + bt_pbinom_upper(x - 1, n, p);
			}
		}
	}
	if (PVAL > 1.0) PVAL = 1.0;
	// confidence interval (Clopper-Pearson)
	NV ci_lo, ci_hi;
	if (strEQ(alternative, "less")) {
		ci_lo = 0.0;
		ci_hi = bt_pU(1.0 - conf_level, x, n);
	} else if (strEQ(alternative, "greater")) {
		ci_lo = bt_pL(1.0 - conf_level, x, n);
		ci_hi = 1.0;
	} else {
		NV a = (1.0 - conf_level) / 2.0;
		ci_lo = bt_pL(a, x, n);
		ci_hi = bt_pU(a, x, n);
	}
	// ---- htest-style result ----
	HV *restrict ret = newHV();
	hv_stores(ret, "method",      newSVpv("Exact binomial test", 0));
	hv_stores(ret, "alternative", newSVpv(alternative, 0));
	hv_stores(ret, "statistic",   newSViv(x));             /* number of successes    */
	hv_stores(ret, "parameter",   newSViv(n));             /* number of trials       */
	hv_stores(ret, "estimate",    newSVnv((NV)x / (NV)n)); /* probability of success */
	hv_stores(ret, "null_value",  newSVnv(p));
	hv_stores(ret, "p_value",     newSVnv(PVAL));
	hv_stores(ret, "conf_level",  newSVnv(conf_level));
	AV *restrict ci = newAV();
	av_push(ci, newSVnv(ci_lo));
	av_push(ci, newSVnv(ci_hi));
	hv_stores(ret, "conf_int",    newRV_noinc((SV *)ci));
	RETVAL = newRV_noinc((SV *)ret);
}
OUTPUT:
  RETVAL

BOOT:
	newXS("Stats::LikeR::__cs_uninit_catcher", cs_uninit_catcher, __FILE__);

void csort(...)
PREINIT:
	SV *restrict data = NULL, *restrict by = NULL, *restrict output = NULL;
	cs_shape in_shape = CS_AOH, out_shape = CS_AOH;
	bool is_hoh = 0, is_code = 0;
	const char *restrict colname = NULL;
	STRLEN collen = 0;
	IV aoa_col = 0;				// AoA: parsed non-negative column index
	const char *restrict rowname_col = NULL;	// HoH: row-name column name
	STRLEN rowname_len = 0;
	CV *restrict cmp_cv = NULL;
	AV *restrict src_av = NULL;	// AoH / AoA input
	HV *restrict src_hv = NULL;	// HoA / HoH input
	SSize_t n = 0;
	size_t *restrict idx = NULL, *tmp = NULL;
	SV **restrict rowrefs = NULL;	// coderef mode: row ref per index
	SV **restrict colkeys = NULL;	// HoA: column key SVs
	AV **restrict colavs  = NULL;	// HoA: column AVs
	size_t ncols = 0;
	SV *restrict result = NULL;
PPCODE:
{
// ---- own the usage message (variadic: xsubpp won't invent one)
	if (items < 2 || items > 4)
		croak("Usage: csort($df, 'column.name', 'HoA')\n"
		      "   or  csort($df, sub { $b->{'No.'} <=> $a->{'No.'} }, 'hoa')\n"
		      "   or  csort($aoa, 0, 'aoa')   # array-of-arrays, integer column\n"
		      "  (optional 4th arg names the row-name column when sorting a "
		      "HoH; default 'row.name')");

	data   = ST(0);
	by     = ST(1);
	output = (items >= 3) ? ST(2) : &PL_sv_undef;
	if (items >= 4 && SvOK(ST(3)))
		rowname_col = SvPV(ST(3), rowname_len);
	else {
		rowname_col = "row.name";
		rowname_len = 8;
	}
	ENTER;    // scope for SAVEFREEPV / SAVESPTR cleanups
	SAVETMPS; // reap transient synthesized rows and mortals here
	// classify $by: coderef comparator vs column name/index
	if (SvROK(by) && SvTYPE(SvRV(by)) == SVt_PVCV) {
		is_code = 1;
		cmp_cv  = (CV *)SvRV(by);
	} else if (SvOK(by) && !SvROK(by)) {
		is_code = 0;
		colname = SvPV(by, collen);
	} else {
		croak("csort: second argument must be a column name (e.g. 'No.'), an "
		      "integer column index for an AoA, or a comparator code-ref "
		      "using $a and $b, e.g. sub { $b->{'No.'} <=> $a->{'No.'} }");
	}
	/* ---- classify $data: AoH/AoA (arrayref) vs HoA/HoH (hashref) ------ */
	if (!SvROK(data))
		croak("csort: first argument must be an array-ref (AoH or AoA) or "
		      "hash-ref (HoA or HoH); Usage: csort($df, 'column.name', 'HoA')");
	if (SvTYPE(SvRV(data)) == SVt_PVAV) {
		src_av   = (AV *)SvRV(data);
		n        = av_len(src_av) + 1;
		in_shape = CS_AOH;		/* default; refine by peeking at row 0 */
		if (n > 0) {
			SV **restrict rp = av_fetch(src_av, 0, 0);
			if (rp && *rp && SvROK(*rp)
			        && SvTYPE(SvRV(*rp)) == SVt_PVAV)
				in_shape = CS_AOA;	/* first row is an arrayref => AoA */
		}
	} else if (SvTYPE(SvRV(data)) == SVt_PVHV) {
		src_hv = (HV *)SvRV(data);
		hv_iterinit(src_hv);
		HE *restrict he = hv_iternext(src_hv);
		if (!he) {
			in_shape = CS_HOA;	/* empty hash defaults to HoA path */
		} else {
			SV *restrict val = HeVAL(he);
			if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV)
				is_hoh = 1;
			else
				in_shape = CS_HOA;
		}
	} else {
		croak("csort: first argument must be an array-ref (AoH or AoA) or "
		      "hash-ref (HoA or HoH); Usage: csort($df, 'column.name', 'HoA')");
	}
	// ---- gracefully fold HoH into a stable AoH for sorting ---------- */
	if (is_hoh) {
		n = hv_iterinit(src_hv);
		src_av = newAV();
		sv_2mortal((SV *)src_av); // cleanup on LEAVE */
		if (n > 0) {
			SV **restrict keys;
			Newx(keys, n, SV*);
			SAVEFREEPV(keys);
			size_t i = 0;
			HE *restrict he;
			while ((he = hv_iternext(src_hv))) {
				keys[i++] = hv_iterkeysv(he);
			}
/* Sort keys alphabetically via insertion sort to guarantee
 * stable and fully deterministic row initialization */
			for (size_t i = 1; i < (size_t)n; i++) {
				SV *restrict k = keys[i];
				STRLEN kl; const char *restrict kp = SvPV_const(k, kl);
				SSize_t j = i - 1;
				while (j >= 0) {
					STRLEN jl; const char *restrict jp = SvPV_const(keys[j], jl);
					int cmp = memcmp(jp, kp, jl < kl ? jl : kl);
					if (cmp == 0) cmp = (jl > kl) - (jl < kl);
					if (cmp <= 0) break;
					keys[j + 1] = keys[j];
					j--;
				}
				keys[j + 1] = k;
			}
/* Materialize each HoH row as a fresh AoH row that also carries
 * its outer key under the row-name column, so the name survives
 * into either output shape.  The row *container* is a private
 * copy (leaf cells are aliased/shared read-only), so injecting
 * the row-name column never mutates the caller's data. */
			for (size_t i = 0; i < (size_t)n; i++) {
				HE *restrict entry = hv_fetch_ent(src_hv, keys[i], 0, 0);
				if (!entry) continue;
				SV *restrict val = HeVAL(entry);
				if (!val || !SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVHV)
					croak("csort: HoH row '%s' is not a hash-ref",
					      SvPV_nolen(keys[i]));

				HV *restrict orig = (HV *)SvRV(val);
				HV *restrict rowh = newHV();
				hv_iterinit(orig);
				HE *restrict cell;
				while ((cell = hv_iternext(orig))) {
					SV *restrict cv = HeVAL(cell);
					(void)hv_store_ent(rowh, hv_iterkeysv(cell),
					        cv ? SvREFCNT_inc_simple_NN(cv) : newSV(0), 0);
				}
// the outer hash key is the authoritative row name */
				(void)hv_store(rowh, rowname_col, (I32)rowname_len,
				               newSVsv(keys[i]), 0);
				av_push(src_av, newRV_noinc((SV *)rowh));
			}
		}
		in_shape = CS_AOH;	/* route through the standard AoH logic hereafter */
	}
// ---- resolve requested output shape (default: match input) ------ */
	if (!SvOK(output)) {
		out_shape = in_shape;
	} else {
		STRLEN ol;
		const char *restrict os = SvPV(output, ol);
		if (ol == 3 && toLOWER(os[0]) == 'a' && toLOWER(os[1]) == 'o'
		    && toLOWER(os[2]) == 'h')
			out_shape = CS_AOH;
		else if (ol == 3 && toLOWER(os[0]) == 'h' && toLOWER(os[1]) == 'o'
		         && toLOWER(os[2]) == 'a')
			out_shape = CS_HOA;
		else if (ol == 3 && toLOWER(os[0]) == 'a' && toLOWER(os[1]) == 'o'
		         && toLOWER(os[2]) == 'a')
			out_shape = CS_AOA;
		else
			croak("csort: output type must be 'aoh', 'hoa', or 'aoa' "
			      "(got '%s')", os);
	}
	if (in_shape == CS_HOA) {// ---- gather HoA column metadata + validate equal lengths
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
	if (in_shape == CS_AOA) {// ---- AoA: validate the integer column index + measure width
		if (!is_code) {
			if (collen == 0)
				croak("csort: AoA column must be a non-negative integer "
				      "index (got empty string)");
			STRLEN p = 0;
			IV v = 0;
			for (; p < collen; p++) {
				if (colname[p] < '0' || colname[p] > '9') break;
				v = v * 10 + (colname[p] - '0');
			}
			if (p != collen)
				croak("csort: AoA column must be a non-negative integer "
				      "index (got '%s')", colname);
			aoa_col = v;
		}
// widest row governs how many positional columns a transpose emits
		for (size_t i = 0; i < (size_t)n; i++) {
			SV **restrict rp = av_fetch(src_av, (SSize_t)i, 0);
			if (rp && *rp && SvROK(*rp) && SvTYPE(SvRV(*rp)) == SVt_PVAV) {
				SSize_t w = av_len((AV *)SvRV(*rp)) + 1;
				if (w > 0 && (size_t)w > ncols) ncols = (size_t)w;
			}
		}
	}
	// ---- build the identity permutation (sorted in place below)
	Newx(idx, (size_t)(n > 0 ? n : 1), size_t);  SAVEFREEPV(idx);
	Newx(tmp, (size_t)(n > 0 ? n : 1), size_t);  SAVEFREEPV(tmp);
	for (size_t i = 0; i < (size_t)n; i++) idx[i] = i;
	if (n > 1) {
		if (is_code) {// comparator mode: prepare row refs + bind $a/$b
			Newx(rowrefs, (size_t)n, SV *);  SAVEFREEPV(rowrefs);
			if (in_shape == CS_AOH || in_shape == CS_AOA) {
				/* rows are already refs (hashref or arrayref); alias them */
				for (size_t i = 0; i < (size_t)n; i++) {
					SV **restrict rp = av_fetch(src_av, (SSize_t)i, 0);
					rowrefs[i] = (rp && *rp) ? *rp : &PL_sv_undef;
				}
			} else {/* HoA: synthesize a per-row hashref view of the columns;
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
/* undef-last: probe each row once; rows whose comparator touches
 * an undef go to the end in stable order, the rest are sorted so
 * the comparator never sees an undef (safe under fatal warnings) */
			{
				size_t *restrict undefs;
				Newx(undefs, (size_t)n, size_t);  SAVEFREEPV(undefs);
				size_t d = 0, u = 0;
				for (size_t i = 0; i < (size_t)n; i++) {
					if (cs_row_touches_undef(aTHX_ &ctx, i)) undefs[u++] = i;
					else                                     idx[d++]   = i;
				}
				for (size_t k = 0; k < u; k++) idx[d + k] = undefs[k];
				cs_msort(aTHX_ idx, tmp, 0, d, cs_code_cmp, &ctx);
			}
		} else {// column mode: gather cells, detect numeric, sort
			SV **restrict vals;
			Newx(vals, (size_t)n, SV *);  SAVEFREEPV(vals);
			bool found = 0;
			unsigned short numeric = 1;
			if (in_shape == CS_AOH) {
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
			} else if (in_shape == CS_AOA) {
				for (size_t i = 0; i < (size_t)n; i++) {
					SV *restrict cell = NULL;
					SV **restrict rp = av_fetch(src_av, (SSize_t)i, 0);
					if (rp && *rp && SvROK(*rp)
					        && SvTYPE(SvRV(*rp)) == SVt_PVAV) {
						SV **restrict cp = av_fetch((AV *)SvRV(*rp),
						                   (SSize_t)aoa_col, 0);
						if (cp && *cp) { cell = *cp; found = 1; }
					}
					if (cell && SvOK(cell) && !looks_like_number(cell))
						numeric = 0;
					vals[i] = cell;
				}
			} else {
				SV **restrict colp = hv_fetch(src_hv, colname, collen, 0);
				if (!(colp && *colp && SvROK(*colp)
				        && SvTYPE(SvRV(*colp)) == SVt_PVAV))
					croak("csort: column '%s' not found in HoA", colname);
				found = 1;
				AV *restrict col = (AV *)SvRV(*colp);
				for (size_t i = 0; i < (size_t)n; i++) {
					SV **restrict cp = av_fetch(col, (SSize_t)i, 0);
					SV *restrict cell = (cp && *cp) ? *cp : NULL;
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
	}// end if (n > 1)
// ---- materialize the result in the requested shape
	result = cs_materialize(aTHX_ out_shape, in_shape, src_av,
	                        colkeys, colavs, ncols, idx, (size_t)n);
	FREETMPS;
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
		// classify the selector: array ref of names, a qr// name pattern, or a
		// value predicate.
		bool by_name = FALSE, by_regex = FALSE;
		SV *restrict cv_sv = NULL;
		if (SvROK(sel) && SvTYPE(SvRV(sel)) == SVt_PVAV) by_name = TRUE;
		else if (SvRXOK(sel)) by_regex = TRUE;
		else if ((SvROK(sel) && SvTYPE(SvRV(sel)) == SVt_PVCV) || (SvOK(sel) && !SvROK(sel))) {
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
		else croak("cfilter: keep/remove must be an array ref of column names, a qr// regex, or a code ref / function name");
		// decode the undef policy (predicate only).
		bool na_omit = FALSE;
		if (na_sv && SvOK(na_sv)) {
			STRLEN nl;
			const char *restrict nv = SvPV(na_sv, nl);
			if (nl == 4 && memEQ(nv, "omit", 4)) na_omit = TRUE;
			else if (nl == 4 && memEQ(nv, "keep", 4)) na_omit = FALSE;
			else croak("cfilter: na must be 'keep' or 'omit'");
		}
		if ((by_name || by_regex) && (na_sv || against_sv)) croak("cfilter: na/against only apply to a predicate selector");
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
		} else croak("cfilter: data must be an array ref or hash ref");
/* 2. the column universe, and (predicate only) a row-aligned cell table
    `cellmap`: colname -> AV of length nrows, undef in the gaps. The
    alignment lets `against` pair two columns by row.*/
		HV *restrict universe = newHV();
		AV *restrict colnames = newAV();
		HV *restrict cellmap = (by_name || by_regex) ? NULL : newHV();
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
				if (!by_name && !by_regex) {
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
			if (!by_name && !by_regex) {
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
		} else if (by_regex) {
			// name pattern: keep/drop each column by matching its name against
			// the compiled qr//. No data is inspected, so na/against don't apply.
			REGEXP *restrict rx = SvRX(sel);
			SSize_t nc = av_len(colnames) + 1;
			for (SSize_t c = 0; c < nc; c++) {
				SV *restrict ck = *av_fetch(colnames, c, 0);
				STRLEN len;
				char *restrict s = SvPV(ck, len);
				bool match = cBOOL(pregexec(rx, s, s + len, s, 0, ck, 1));
				if (removing ? !match : match) (void)hv_store_ent(keepset, ck, newSViv(1), 0);
			}
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


void filter(...)
PPCODE:
{
	if (items < 2)
		croak("Usage: filter($df, $code [, 'output.type' => 'aoh'|'hoa'])");
	SV *restrict df      = ST(0);
	SV *restrict predarg = ST(1);
	const char *restrict otype = NULL;
	if (items == 3) {
		otype = SvPV_nolen(ST(2));
	} else if (items == 4) {
		const char *restrict key = SvPV_nolen(ST(2));
		if (strNE(key, "output.type") && strNE(key, "out") && strNE(key, "output_type"))
			croak("filter: unknown option '%s' (expected 'output.type')", key);
		otype = SvPV_nolen(ST(3));
	} else if (items > 4) {
		croak("Usage: filter($df, $code [, 'output.type' => 'aoh'|'hoa'])");
	}
	int want = 0; // 0 = preserve input shape
	if (otype) {
		if      (strEQ(otype, "aoh")) want = FLT_AOH;
		else if (strEQ(otype, "hoa")) want = FLT_HOA;
		else croak("filter: output.type must be 'aoh' or 'hoa' (got '%s')", otype);
	}
	if (!df || !SvROK(df))
		croak("filter: first argument must be a data frame (AoH, HoA, or HoH reference)");
	/* The predicate is a CODE ref, or a col() object carrying a CODE ref in
	 * its {code} field; either way we end up calling a single CV per row --
	 * unless the col() object also carries a {plan}, which is the same test as
	 * data and runs in C without touching perl at all. */
	SV *restrict code = NULL;
	SV *restrict plan = NULL;
	if (predarg && SvROK(predarg) && SvTYPE(SvRV(predarg)) == SVt_PVCV) {
		code = predarg;
	} else if (predarg && sv_isobject(predarg)
			&& sv_derived_from(predarg, "Stats::LikeR::col")) {
		SV **restrict cp = hv_fetchs((HV*)SvRV(predarg), "code", 0);
		if (!cp || !*cp || !SvROK(*cp) || SvTYPE(SvRV(*cp)) != SVt_PVCV)
			croak("filter: incomplete col() predicate -- a bare column needs a comparison, e.g. col('x') > 0");
		code = *cp;
		SV **restrict pp = hv_fetchs((HV*)SvRV(predarg), "plan", 0);
		if (pp && *pp && SvROK(*pp)) plan = *pp;
	} else {
		croak("filter: predicate must be a CODE reference or a col() expression");
	}

	SV *restrict ref = SvRV(df);
	int in_shape;
	HV *restrict inhv = NULL;
	AV *restrict inav = NULL;
	if (SvTYPE(ref) == SVt_PVAV) {
		in_shape = FLT_AOH; inav = (AV*)ref;
	} else if (SvTYPE(ref) == SVt_PVHV) {
		inhv = (HV*)ref;
		hv_iterinit(inhv);
		HE *restrict e0 = hv_iternext(inhv);
		if (!e0) { // empty hash: ambiguous shape -> empty result of the chosen/own shape
			SV *restrict r = (want == FLT_AOH) ? newRV_noinc((SV*)newAV())
			                                   : newRV_noinc((SV*)newHV());
			ST(0) = sv_2mortal(r);
			XSRETURN(1);
		}
		SV *restrict v0 = HeVAL(e0);
		if (v0 && SvROK(v0) && SvTYPE(SvRV(v0)) == SVt_PVAV)      in_shape = FLT_HOA;
		else if (v0 && SvROK(v0) && SvTYPE(SvRV(v0)) == SVt_PVHV) in_shape = FLT_HOH;
		else croak("filter: hash data frame must be a hash of arrays (HoA) or a hash of hashes (HoH)");
	} else {
		croak("filter: unsupported data frame; expected AoH, HoA, or HoH");
	}
	int out_shape = want ? want : in_shape;

	SV *restrict result = NULL;
	ENTER; SAVETMPS;
	/* A col() expression that describes itself is run in C; anything else
	 * (a plain sub, a ->match regex) goes through filt_call as before. */
	flt_prog prog_buf;
	flt_prog *restrict prog = (plan && flt_compile(aTHX_ &prog_buf, plan)) ? &prog_buf : NULL;
	if (in_shape == FLT_AOH) {
		SSize_t n = av_len(inav) + 1, i;
		/* pass 1: which rows are kept.  Knowing the count before anything is
		 * built lets every output array be allocated at its final size. */
		char *restrict keep = (char*)safemalloc(n ? (size_t)n : 1);
		SAVEFREEPV(keep);
		SSize_t kept = 0;
		/* AoH -> HoA also needs the union of the columns, taken from every row
		 * and not just the kept ones, so a column that only dropped rows had
		 * still appears (as a column of undefs) in the output. */
		HV *restrict out   = NULL;
		HV *restrict reg   = NULL;
		AV *restrict order = NULL;
		if (out_shape == FLT_HOA) {
			out   = (HV*)sv_2mortal((SV*)newHV());
			reg   = (HV*)sv_2mortal((SV*)newHV());
			order = (AV*)sv_2mortal((SV*)newAV());
		}
		for (i = 0; i < n; i++) {
			SV **restrict rp = av_fetch(inav, i, 0);
			if (!rp || !*rp || !SvROK(*rp) || SvTYPE(SvRV(*rp)) != SVt_PVHV)
				croak("filter: AoH element %ld is not a HASH reference", (long)i);
			HV *restrict rh = (HV*)SvRV(*rp);
			if (order) {
				hv_iterinit(rh); HE *restrict e;
				while ((e = hv_iternext(rh))) {
					STRLEN kl; char *restrict k = HePV(e, kl);
					flt_reg_col(aTHX_ reg, order, out, k, kl);
				}
			}
			char k = (prog ? flt_row_hv(aTHX_ prog, rh)
			               : filt_call(aTHX_ code, *rp, sv_2mortal(newSViv(i)))) ? 1 : 0;
			keep[i] = k; kept += k;
		}
		if (out_shape == FLT_AOH) {
			AV *restrict outa = (AV*)sv_2mortal((SV*)newAV());
			if (kept) {
				av_extend(outa, kept - 1);
				SV **restrict d = AvARRAY(outa); SSize_t t = 0;
				for (i = 0; i < n; i++) {
					if (!keep[i]) continue;
					/* the row was a hash ref when it was tested; a predicate
					 * that went and emptied the frame behind us must not turn
					 * that into a crash */
					SV **restrict rp = av_fetch(inav, i, 0);
					d[t++] = (rp && *rp) ? SvREFCNT_inc_simple_NN(*rp) : newSV(0);	/* share row */
				}
				FLT_AV_FILLED(outa, kept);
			}
			result = newRV_inc((SV*)outa);
		} else {	// AoH -> HoA: fill column by column
			SSize_t ncn = av_len(order) + 1, j;
			SSize_t *restrict idx = flt_kept_index(aTHX_ keep, n, kept);
			for (j = 0; j < ncn; j++) {
				SV **restrict np = av_fetch(order, j, 0);
				STRLEN kl; char *restrict k = SvPV(*np, kl);
				AV *restrict o = (AV*)SvRV(*hv_fetch(out, k, kl, 0));
				if (!kept) continue;
				av_extend(o, kept - 1);
				SV **restrict d = AvARRAY(o);
				for (SSize_t t = 0; t < kept; t++) {
					SV **restrict rp = av_fetch(inav, idx[t], 0);
					HV *restrict rh = (rp && *rp && SvROK(*rp)
					                   && SvTYPE(SvRV(*rp)) == SVt_PVHV)
					                 ? (HV*)SvRV(*rp) : NULL;
					SV **restrict cp = rh ? hv_fetch(rh, k, kl, 0) : NULL;
					d[t] = newSVsv((cp && *cp) ? *cp : &PL_sv_undef);
				}
				FLT_AV_FILLED(o, kept);
			}
			result = newRV_inc((SV*)out);
		}
	} else if (in_shape == FLT_HOA) {
		U32 ncols = hv_iterinit(inhv), c;
		char   **restrict names = (char**)safemalloc((ncols?ncols:1) * sizeof(char*));
		STRLEN  *restrict nlens = (STRLEN*)safemalloc((ncols?ncols:1) * sizeof(STRLEN));
		AV     **restrict cols  = (AV**)safemalloc((ncols?ncols:1) * sizeof(AV*));
		SAVEFREEPV(names); SAVEFREEPV(nlens); SAVEFREEPV(cols);
		SSize_t maxrows = 0, i; HE *restrict e; c = 0;
		while ((e = hv_iternext(inhv)) && c < ncols) {
			SV *restrict v = HeVAL(e);
			STRLEN kl; char *restrict k = HePV(e, kl);
			if (!v || !SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVAV)
				croak("filter: HoA column '%s' is not an ARRAY reference", k);
			AV *restrict a = (AV*)SvRV(v);
			SSize_t len = av_len(a) + 1;
			if (len > maxrows) maxrows = len;
			names[c] = k; nlens[c] = kl; cols[c] = a; c++;
		}
		if (prog) flt_bind_hoa(aTHX_ prog, inhv);
		/* The closure path needs a row hash; the compiled path reads the
		 * columns straight out of the frame and never builds one. */
		flt_rowbuf *restrict rb = NULL;
		if (!prog) {
			rb = (flt_rowbuf*)safemalloc(sizeof(flt_rowbuf));
			SAVEFREEPV(rb);
			Zero(rb, 1, flt_rowbuf);
			rb->n = c; rb->names = names; rb->nlens = nlens;
			rb->slot = (SV**)safemalloc((c?c:1) * sizeof(SV*));
			SAVEFREEPV(rb->slot);
			SAVEDESTRUCTOR_X(flt_rb_free, rb);
			flt_rb_new(aTHX_ rb);
		}
		char *restrict keep = (char*)safemalloc(maxrows ? (size_t)maxrows : 1);
		SAVEFREEPV(keep);
		SSize_t kept = 0;
		if (out_shape == FLT_HOA) {
			for (i = 0; i < maxrows; i++) {
				bool k;
				if (prog) {
					k = flt_row_hoa(aTHX_ prog, i);
				} else {
					for (U32 cc = 0; cc < c; cc++) {
						SV **restrict vp = av_fetch(cols[cc], i, 0);
						sv_setsv(rb->slot[cc], (vp && *vp) ? *vp : &PL_sv_undef);
					}
					k = filt_call(aTHX_ code, rb->rv, sv_2mortal(newSViv(i)));
					if (!flt_rb_reusable(aTHX_ rb)) { flt_rb_free(aTHX_ rb); flt_rb_new(aTHX_ rb); }
				}
				keep[i] = k ? 1 : 0; kept += k ? 1 : 0;
			}
			SSize_t *restrict idx = flt_kept_index(aTHX_ keep, maxrows, kept);
			HV *restrict out = (HV*)sv_2mortal((SV*)newHV());
			for (U32 cc = 0; cc < c; cc++) {
				AV *restrict o = newAV();
				hv_store(out, names[cc], nlens[cc], newRV_noinc((SV*)o), 0);
				if (!kept) continue;
				av_extend(o, kept - 1);
				SV **restrict d = AvARRAY(o);
				SV **restrict src = AvARRAY(cols[cc]);
				const SSize_t srcn = AvFILLp(cols[cc]) + 1;
				if (srcn >= maxrows) {			/* the usual case: no ragged tail */
					for (SSize_t t = 0; t < kept; t++) {
						SV *restrict v = src[idx[t]];
						d[t] = flt_cell_copy(aTHX_ v);
					}
				} else {
					for (SSize_t t = 0; t < kept; t++) {
						const SSize_t r = idx[t];
						d[t] = flt_cell_copy(aTHX_ (r < srcn) ? src[r] : NULL);
					}
				}
				FLT_AV_FILLED(o, kept);
			}
			result = newRV_inc((SV*)out);
		} else {	// HoA -> AoH
			AV *restrict out = (AV*)sv_2mortal((SV*)newAV());
			if (prog) {
				for (i = 0; i < maxrows; i++) {
					char k = flt_row_hoa(aTHX_ prog, i) ? 1 : 0;
					keep[i] = k; kept += k;
				}
				if (kept) {
					av_extend(out, kept - 1);
					SV **restrict d = AvARRAY(out); SSize_t t = 0;
					for (i = 0; i < maxrows; i++) {
						if (!keep[i]) continue;
						HV *restrict rowh = newHV();
						hv_ksplit(rowh, c ? c : 1);
						for (U32 cc = 0; cc < c; cc++) {
							SV **restrict vp = av_fetch(cols[cc], i, 0);
							hv_store(rowh, names[cc], nlens[cc],
							         newSVsv((vp && *vp) ? *vp : &PL_sv_undef), 0);
						}
						d[t++] = newRV_noinc((SV*)rowh);
					}
					FLT_AV_FILLED(out, kept);
				}
			} else {
				for (i = 0; i < maxrows; i++) {
					for (U32 cc = 0; cc < c; cc++) {
						SV **restrict vp = av_fetch(cols[cc], i, 0);
						sv_setsv(rb->slot[cc], (vp && *vp) ? *vp : &PL_sv_undef);
					}
					if (filt_call(aTHX_ code, rb->rv, sv_2mortal(newSViv(i)))) {
						av_push(out, rb->rv);	/* the kept row IS the buffer */
						rb->rv = NULL;
						flt_rb_new(aTHX_ rb);
					} else if (!flt_rb_reusable(aTHX_ rb)) {
						flt_rb_free(aTHX_ rb); flt_rb_new(aTHX_ rb);
					}
				}
			}
			result = newRV_inc((SV*)out);
		}
	} else {	// FLT_HOH
		HE *restrict e;
		if (out_shape == FLT_HOA) {
			HV *restrict out   = (HV*)sv_2mortal((SV*)newHV());
			HV *restrict reg   = (HV*)sv_2mortal((SV*)newHV());
			AV *restrict order = (AV*)sv_2mortal((SV*)newAV());
			AV *restrict rows  = (AV*)sv_2mortal((SV*)newAV());	/* the kept rows */
			hv_iterinit(inhv);
			while ((e = hv_iternext(inhv))) {
				SV *restrict v = HeVAL(e);
				STRLEN kl; char *restrict k = HePV(e, kl);
				if (!v || !SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVHV)
					croak("filter: HoH row '%s' is not a HASH reference", k);
				HV *restrict rh = (HV*)SvRV(v);
				hv_iterinit(rh); HE *ie;	/* columns come from every row ... */
				while ((ie = hv_iternext(rh))) {
					STRLEN il; char *restrict ik = HePV(ie, il);
					flt_reg_col(aTHX_ reg, order, out, ik, il);
				}
				if (prog ? flt_row_hv(aTHX_ prog, rh)		/* ... values only from the kept ones */
				         : filt_call(aTHX_ code, v, hv_iterkeysv(e)))
					av_push(rows, SvREFCNT_inc_simple_NN(v));
			}
			SSize_t ncn = av_len(order) + 1, j;
			SSize_t kept = av_len(rows) + 1;
			for (j = 0; j < ncn; j++) {
				SV **restrict np = av_fetch(order, j, 0);
				STRLEN kl; char *restrict k = SvPV(*np, kl);
				AV *restrict o = (AV*)SvRV(*hv_fetch(out, k, kl, 0));
				if (!kept) continue;
				av_extend(o, kept - 1);
				SV **restrict d = AvARRAY(o);
				for (SSize_t t = 0; t < kept; t++) {
					HV *restrict rh = (HV*)SvRV(AvARRAY(rows)[t]);
					SV **restrict cp = hv_fetch(rh, k, kl, 0);
					d[t] = newSVsv((cp && *cp) ? *cp : &PL_sv_undef);
				}
				FLT_AV_FILLED(o, kept);
			}
			result = newRV_inc((SV*)out);
		} else {	/* HoH -> HoH (preserve) or HoH -> AoH */
			HV *restrict outh = NULL; AV *restrict outa = NULL;
			if (out_shape == FLT_HOH) outh = (HV*)sv_2mortal((SV*)newHV());
			else                      outa = (AV*)sv_2mortal((SV*)newAV());
			hv_iterinit(inhv);
			while ((e = hv_iternext(inhv))) {
				SV *restrict v = HeVAL(e);
				STRLEN kl; char *restrict k = HePV(e, kl);
				if (!v || !SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVHV)
					croak("filter: HoH row '%s' is not a HASH reference", k);
				if (!(prog ? flt_row_hv(aTHX_ prog, (HV*)SvRV(v))
				           : filt_call(aTHX_ code, v, hv_iterkeysv(e)))) continue;
				if (outh) hv_store(outh, k, kl, SvREFCNT_inc_simple_NN(v), 0);
				else      av_push(outa, SvREFCNT_inc_simple_NN(v));
			}
			result = newRV_inc(outh ? (SV*)outh : (SV*)outa);
		}
	}
	FREETMPS; LEAVE;
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
			if (kind == 0) { // hash of arrays: names = keys, rows = longest column.
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
							SV *restrict knm = hv_iterkeysv(e);	// preserves the UTF-8 flag
							if (!hv_exists_ent(seen, knm, 0)) { (void)hv_store_ent(seen, knm, &PL_sv_yes, 0); av_push(names_av, newSVsv(knm)); }
						}
					}
					SvREFCNT_dec((SV*)seen);
				}
				ncols = (size_t)(av_len(names_av) + 1);
				Newxz(col_val, ncols ? ncols : 1, NV*);
				Newxz(col_def, ncols ? ncols : 1, char*);
				for (size_t cc = 0; cc < ncols; cc++) {
					SV *restrict knm = *av_fetch(names_av, (SSize_t)cc, 0);	// keep the SV so UTF-8 keys match
					Newxz(col_val[cc], nrows ? nrows : 1, NV);
					Newxz(col_def[cc], nrows ? nrows : 1, char);
					for (size_t r = 0; r < nrows; r++) {
						NV v;
						HE *restrict he;
						SV *cell;
						if (!row_hv[r]) continue;
						he = hv_fetch_ent(row_hv[r], knm, 0, 0);
						cell = he ? HeVAL(he) : NULL;
						if (c2c_num(aTHX_ &cell, &v)) { col_val[cc][r] = v; col_def[cc][r] = 1; }
					}
				}
				Safefree(row_hv);
			}
		}
		if (ncols == 0) croak("col2col: no usable columns found");
// 3. gather the column-name SVs; keys are stored via hv_store_ent below
//    so the UTF-8 flag rides along and non-ASCII names round-trip.
		SV **restrict col_names;
		Newx(col_names, ncols, SV*);
		for (size_t cc = 0; cc < ncols; cc++) {
			col_names[cc] = *av_fetch(names_av, (SSize_t)cc, 0);
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
				if (!ep || !*ep || !SvOK(*ep)) croak("col2col: column list contains an undefined entry");
				if (!c2c_mark(aTHX_ col_names, ncols, *ep, is_outer)) croak("col2col: column '%s' not found in data", SvPV_nolen(*ep));
			}
		} else if (!SvROK(cols_eff)) {
			if (!c2c_mark(aTHX_ col_names, ncols, cols_eff, is_outer)) croak("col2col: column '%s' not found in data", SvPV_nolen(cols_eff));
		} else croak("col2col: cols must be a column name or an array ref of names");
/* 4. each selected column vs every other column. The two columns reach
 the block as @_ = ($col_a, $col_b); how undef is handled depends on
 na (section 0): 'pairwise' drops a row missing in either side (equal
 aligned lengths, for cor); 'omit' drops each column's own undef
 independently (lengths may differ, for t_test / kruskal_test);
 'keep' passes every row through with undef in the gaps.*/
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
				(void)hv_store_ent(inner, col_names[b], res, 0);
				SvREFCNT_dec(rv1);
				SvREFCNT_dec(rv2);
			}
			(void)hv_store_ent(out_hv, col_names[a], newRV_noinc((SV*)inner), 0);
		}
		// 5. tidy up.
		for (size_t cc = 0; cc < ncols; cc++) { Safefree(col_val[cc]); Safefree(col_def[cc]); }
		Safefree(col_val);	Safefree(col_def); Safefree(col_names);
		Safefree(is_outer);	SvREFCNT_dec((SV*)names_av);
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
				croak("oneway_test: need at least 2 groups, got %" UVuf, (UV)k);

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
				croak("oneway_test: need at least 2 groups, got %" UVuf, (UV)k);

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

	AV *restrict x_av = (AV *)SvRV(x_sv);
	size_t nx = (size_t)(av_len(x_av) + 1);
	if (nx == 0) croak("Not enough 'x' observations");

	// Extract 'x' to a C array (numeric elements only).
	NV *restrict x_data = (NV *)safemalloc(nx * sizeof(NV));
	size_t valid_nx = 0;
	for (size_t i = 0; i < nx; i++) {
	  SV **restrict el = av_fetch(x_av, i, 0);
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
	const char *restrict method_desc = "";

	// TWO SAMPLE
	if (y_sv && SvROK(y_sv) && SvTYPE(SvRV(y_sv)) == SVt_PVAV) {
	  AV *restrict y_av = (AV *)SvRV(y_sv);
	  size_t ny = (size_t)(av_len(y_av) + 1);
	  NV *restrict y_data = (NV *)safemalloc((ny ? ny : 1) * sizeof(NV));
	  size_t valid_ny = 0;
	  for (size_t i = 0; i < ny; i++) {
		   SV **restrict el = av_fetch(y_av, i, 0);
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
		   qsort(x_data, valid_nx, sizeof(NV), cmp_nv3);
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
	// --- 2 SAMPLE (Mann-Whitney)
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
			// guard against degenerate (all-tied) variance instead of dividing by zero
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
				if (strcmp(alternative, "two.sided") == 0) CORRECTION = (z > 0) ? 0.5 : (z < 0) ? -0.5 : 0.0;
				else if (strcmp(alternative, "greater") == 0) CORRECTION = 0.5;
				else if (strcmp(alternative, "less") == 0) CORRECTION = -0.5;
			}
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
	if (!SvROK(data_ref)) {// 1. Input Validation & Data Matrix Construction
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
					
					HE*restrict inner_he = hv_fetch_ent(obs_hv, *row_key_sv, 0, 0);
					if (inner_he) {
						SV*restrict inner_sv = HeVAL(inner_he);
						if (SvROK(inner_sv)) {
							HV*restrict inner_hv = (HV*)SvRV(inner_sv);
							for (unsigned int j = 0; j < c; j++) {
								SV**restrict col_key_sv = av_fetch(col_keys, j, 0);
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
	if (obs_matrix) {// Memory Cleanup for Matrices/Arrays
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
				  strEQ(k, "undef.val") || strEQ(k, "tex") ||
				  strEQ(k, "tex.col.align") || strEQ(k, "tex.size") ||
				  strEQ(k, "tex.comment") || strEQ(k, "tex.bold.1st.col") ||
				  strEQ(k, "tex.format") || strEQ(k, "tex.longtable") ||
				  strEQ(k, "tex.longtable.head") ||
				  strEQ(k, "xlsx") || strEQ(k, "xlsx.sheet") ||
				  strEQ(k, "xlsx.comment") || strEQ(k, "xlsx.freeze.rows") ||
				  strEQ(k, "xlsx.freeze.cols"))) {
				file_sv = cand;
				arg_idx++;
			}
		}
	}
	const char *restrict sep = ",";
	bool explicit_sep = 0; // Track if delimiter was manually specified
// default undef cells to a true empty value ("") instead of NULL.
// With print_string_row emitting zero-length fields bare (no quotes), an
// undef cell now prints as nothing at all: a,,c -- not a,'',c or a,"",c.
// 'undef.val' => 'NA' (etc.) still overrides this.
	const char *restrict undef_val = "";
	SV *restrict row_names_sv = sv_2mortal(newSViv(0));
	SV *restrict col_names_sv = NULL;
// LaTeX tabular output. 'tex' selects LaTeX for the main output file; the
// remaining tex.* keys tune the rendering. tex_opt is tri-state: -1 = not
// given (auto-detect from a ".tex" file name), 0 = off, 1 = on.
	short int tex_opt = -1;
	const char *restrict tex_align = "c";  // per-column alignment: c / l / r
	const char *restrict tex_size  = NULL; // optional size directive, e.g. \small
	SV *restrict tex_comment       = NULL; // string or array ref of % comment lines
	bool tex_bold1  = 1;                    // bold the first column of each data row
	bool tex_format = 0;                    // %.4g-format numeric cells
	bool tex_longtable = 0;                 // body only, for \input into a longtable
// Generate longtable's own repeat-header machinery (\endfirsthead / \endhead /
// \endfoot) instead of a plain header row. A non-numeric value is the caption
// used on continuation pages. Implies tex.longtable.
	SV *restrict tex_longtable_head = NULL;
	// .xlsx (Excel) output, dependency-free. xlsx_opt is tri-state like tex_opt:
	// -1 = auto-detect from a ".xlsx" file name, 0 = off, 1 = on.
	short int xlsx_opt = -1;
	const char *restrict xlsx_sheet = "Sheet1"; // worksheet name
	SV *restrict xlsx_comment = NULL;            // extra comment line(s) appended after the provenance
	IV xlsx_freeze_rows = 0;                     // leading rows to freeze (0 = none)
	IV xlsx_freeze_cols = 0;                     // leading columns to freeze (0 = none)
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
		else if (strEQ(key, "undef.val")) undef_val = SvOK(val) ? SvPV_nolen(val) : "";
		else if (strEQ(key, "tex"))              tex_opt     = SvTRUE(val) ? 1 : 0;
		else if (strEQ(key, "tex.col.align"))  { if (SvOK(val)) tex_align = SvPV_nolen(val); }
		else if (strEQ(key, "tex.size"))         tex_size    = SvOK(val) ? SvPV_nolen(val) : NULL;
		else if (strEQ(key, "tex.comment"))      tex_comment = SvOK(val) ? val : NULL;
		else if (strEQ(key, "tex.bold.1st.col")) tex_bold1   = SvTRUE(val) ? 1 : 0;
		else if (strEQ(key, "tex.format"))       tex_format  = SvTRUE(val) ? 1 : 0;
		else if (strEQ(key, "tex.longtable"))    tex_longtable = SvTRUE(val) ? 1 : 0;
		else if (strEQ(key, "tex.longtable.head")) tex_longtable_head = SvOK(val) ? val : NULL;
		else if (strEQ(key, "xlsx"))             xlsx_opt    = SvTRUE(val) ? 1 : 0;
		else if (strEQ(key, "xlsx.sheet"))     { if (SvOK(val)) xlsx_sheet = SvPV_nolen(val); }
		else if (strEQ(key, "xlsx.comment"))     xlsx_comment = SvOK(val) ? val : NULL;
		else if (strEQ(key, "xlsx.freeze.rows")) {
			if (SvOK(val)) {
				xlsx_freeze_rows = SvIV(val);
				if (xlsx_freeze_rows < 0)
					croak("write_table: 'xlsx.freeze.rows' must be a non-negative integer\n");
			}
		}
		else if (strEQ(key, "xlsx.freeze.cols")) {
			if (SvOK(val)) {
				xlsx_freeze_cols = SvIV(val);
				if (xlsx_freeze_cols < 0)
					croak("write_table: 'xlsx.freeze.cols' must be a non-negative integer\n");
			}
		}
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
	// Decide LaTeX vs delimited. A ".tex" file name turns LaTeX on by default;
	// an explicit tex => 0/1 always wins (so tex => 0 forces a delimited file
	// even when it is named *.tex, and tex => 1 forces LaTeX for any name).
	bool tex = 0;
	if (tex_opt == -1) {
		size_t file_len = strlen(file);
		if (file_len >= 4) {
			const char *restrict ext = file + file_len - 4;
			if (strEQ(ext, ".tex") || strEQ(ext, ".TEX")) tex = 1;
		}
	} else {
		tex = tex_opt ? 1 : 0;
	}
// Requesting a longtable body is a LaTeX request; force 'tex' on even for
// a non-".tex" file name or tex => 0. (tex.longtable only affects the
// LaTeX renderer, so without this it would be silently ignored.)
// 'tex.longtable.head' only has meaning inside a longtable body, so asking for
// it is asking for one.
	if (tex_longtable_head && SvTRUE(tex_longtable_head)) tex_longtable = 1;
	if (tex_longtable) tex = 1;
// .xlsx decision, mirroring the tex logic: a ".xlsx" file name turns it on
// unless an explicit xlsx => 0/1 says otherwise.
	bool xlsx = 0;
	if (xlsx_opt == -1) {
		size_t file_len = strlen(file);
		if (file_len >= 5) {
			const char *restrict ext = file + file_len - 5;
			if (strEQ(ext, ".xlsx") || strEQ(ext, ".XLSX")) xlsx = 1;
		}
	} else {
		xlsx = xlsx_opt ? 1 : 0;
	}
	if (tex && xlsx)
		croak("write_table: 'tex' and 'xlsx' output are mutually exclusive\n");
// LaTeX and xlsx are both rendered from collected rows, not streamed to a
// delimited file handle.
	bool collect = tex || xlsx;
	if (!explicit_sep) {// Auto-detect separator from file extension if not overridden
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
	bool is_hoh = 0, is_hoa = 0, is_aoh = 0, is_flat_hash = 0, is_aoa = 0;
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
		if (first_ptr && *first_ptr && SvROK(*first_ptr)
				&& SvTYPE(SvRV(*first_ptr)) == SVt_PVAV) {
// Array of Arrays: every element must be an ARRAY reference.
			for (SSize_t i = 0; i <= av_len(av); i++) {
				SV **restrict ptr = av_fetch(av, i, 0);
				if (!ptr || !*ptr || !SvROK(*ptr) || SvTYPE(SvRV(*ptr)) != SVt_PVAV) {
					croak("write_table: Mixed data types detected in Array of Arrays. All elements must be ARRAY references.\n");
				}
			}
			is_aoa = 1;
		} else {
			if (!first_ptr || !*first_ptr || !SvROK(*first_ptr) || SvTYPE(SvRV(*first_ptr)) != SVt_PVHV) {
				if (first_ptr && *first_ptr && SvROK(*first_ptr))
					croak("write_table: For ARRAY data, every element must be a HASH reference "
						  "(Array of Hashes) or all ARRAY references (Array of Arrays); element 0 is a reference of type '%s'\n",
						  sv_reftype(SvRV(*first_ptr), 0));
				else if (first_ptr && *first_ptr && SvOK(*first_ptr))
					croak("write_table: For ARRAY data, every element must be a HASH reference "
						  "(Array of Hashes) or all ARRAY references (Array of Arrays); element 0 is a non-reference scalar (value: '%s')\n",
						  SvPV_nolen(*first_ptr));
				else
					croak("write_table: For ARRAY data, every element must be a HASH reference "
						  "(Array of Hashes) or all ARRAY references (Array of Arrays); element 0 is undef\n");
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
	}
// With 'tex' or 'xlsx' on, the main file receives the rendered output, written
// once the rows have been collected; no delimited handle is opened here (fh
// stays NULL and print_string_row() collects each record without emitting it).
	PerlIO *restrict fh = collect ? NULL : PerlIO_open(file, "w");
	if (!collect && !fh) {
		if (rows_av) SvREFCNT_dec(rows_av);
		croak("write_table: Could not open '%s' for writing", file);
	}
	AV *restrict headers_av = newAV();
// row.names is off unless asked for, in every format -- delimited, LaTeX and
// .xlsx alike. R's write.table() defaults it on, and this used to follow suit,
// but a label column nobody asked for is the wrong default here: the common
// case is a frame whose rows are already identified by one of its own columns,
// and the leading empty header cell it produces (",gene,n") is a well known
// nuisance to read back. row.names => 1 opts in and gives the old behaviour;
// row.names => 'col' uses that column's values as the labels.
	bool inc_rownames = (row_names_sv && SvTRUE(row_names_sv)) ? 1 : 0;
	const char *restrict rownames_col = NULL;
// When 'tex' or 'xlsx' is on, collect every record here (as an AV of AVs of
// SVs) so the renderer can build the output afterwards. Mortal => reclaimed
// automatically if any of the croak paths below fire.
	AV *restrict collect_av = collect ? (AV*)sv_2mortal((SV*)newAV()) : NULL;
	if (is_hoh) {// ----- Hash of Hashes -----
		if (col_names_sv && SvOK(col_names_sv)) {
			AV *restrict c_av = (AV*)SvRV(col_names_sv);
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
		for (size_t i = 0; i < num_headers; i++) {
			SV **restrict h_ptr = av_fetch(headers_av, (SSize_t)i, 0);
			header_row[h_idx++] = (h_ptr && SvOK(*h_ptr)) ? SvPV_nolen(*h_ptr) : "";
		}
		print_string_row(aTHX_ fh, header_row, h_idx, sep, collect_av);
		safefree(header_row);
		size_t num_rows = (size_t)(av_len(rows_av) + 1);
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
						if (fh) PerlIO_close(fh);
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
			print_string_row(aTHX_ fh, row_data, d_idx, sep, collect_av);
		}
		safefree(row_data);
	} else if (is_flat_hash) {// Flat Hash
		HV *restrict data_hv = (HV*)data_ref;
		if (col_names_sv && SvOK(col_names_sv)) {
			AV *restrict c_av = (AV*)SvRV(col_names_sv);
			for (SSize_t i = 0; i <= av_len(c_av); i++) {
				SV **restrict c = av_fetch(c_av, i, 0);
				if (c && SvOK(*c)) av_push(headers_av, newSVsv(*c));
			}
		} else {
// UTF-8 safety: keep the key SVs (flags intact) and sort
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
		print_string_row(aTHX_ fh, header_row, h_idx, sep, collect_av);
		safefree(header_row);
		const char **restrict row_data = safemalloc((num_headers + 1) * sizeof(char*));
		size_t d_idx = 0;
// Give the single row a default numeric identifier if row names are on
		if (inc_rownames) row_data[d_idx++] = "1";
		for (size_t j = 0; j < num_headers; j++) {
			SV **restrict h_ptr = av_fetch(headers_av, (SSize_t)j, 0);
			SV *restrict h_sv = (h_ptr && SvOK(*h_ptr)) ? *h_ptr : NULL;
			HE *restrict val_he = h_sv ? hv_fetch_ent(data_hv, h_sv, 0, 0) : NULL;
			SV *restrict val_sv = val_he ? HeVAL(val_he) : NULL;
			if (val_sv && SvOK(val_sv)) {
				if (SvROK(val_sv)) {
					if (fh) PerlIO_close(fh);
					safefree(row_data);
					if (headers_av) SvREFCNT_dec(headers_av);
					croak("write_table: Cannot write nested reference types to table\n");
				}
				row_data[d_idx++] = SvPV_nolen(val_sv);
			} else {
				row_data[d_idx++] = undef_val;
			}
		}
		print_string_row(aTHX_ fh, row_data, d_idx, sep, collect_av);
		safefree(row_data);
	} else if (is_hoa) {// Hash of Arrays
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
			for (SSize_t i = 0; i <= av_len(c_av); i++) {
				SV **restrict c = av_fetch(c_av, i, 0);
				if (c && SvOK(*c)) av_push(headers_av, newSVsv(*c));
			}
		} else {
			unsigned int num_cols = hv_iterinit(data_hv);
			for (unsigned int i = 0; i < num_cols; i++) {
				HE *restrict ce = hv_iternext(data_hv);
				av_push(headers_av, newSVsv(hv_iterkeysv(ce)));
			}
			if (num_cols > 1)
				sortsv(AvARRAY(headers_av), num_cols, Perl_sv_cmp);
		}
		if (av_len(headers_av) < 0) {
			if (fh) PerlIO_close(fh);
			SvREFCNT_dec(headers_av);
			croak("Could not get headers in write_table");
		}
		if (inc_rownames && contains_nondigit(aTHX_ row_names_sv)) {
			rownames_col = SvPV_nolen(row_names_sv);
			AV *restrict filtered_headers = newAV();
			for (SSize_t i = 0; i <= av_len(headers_av); i++) {
				SV **restrict h_ptr = av_fetch(headers_av, i, 0);
				if (!h_ptr || !*h_ptr) continue;
				SV *restrict h_sv = *h_ptr;
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
		print_string_row(aTHX_ fh, header_row, h_idx, sep, collect_av);
		safefree(header_row);
		const char **restrict row_data = safemalloc((num_headers + 1) * sizeof(char*));
		char rn_buf[32];
		for (size_t i = 0; i < max_rows; i++) {
			size_t d_idx = 0;
			if (inc_rownames) {
				if (rownames_col) {
					HE *restrict rn_arr_he = hv_fetch_ent(data_hv, row_names_sv, 0, 0);
					SV *restrict rn_arr_sv = rn_arr_he ? HeVAL(rn_arr_he) : NULL;
					if (rn_arr_sv && SvROK(rn_arr_sv)) {
						AV *restrict rn_arr = (AV*)SvRV(rn_arr_sv);
						SV **restrict rn_val_ptr = av_fetch(rn_arr, (SSize_t)i, 0);
						if (rn_val_ptr && SvOK(*rn_val_ptr)) {
							if (SvROK(*rn_val_ptr)) {
								if (fh) PerlIO_close(fh);
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
				HE *restrict arr_he = h_sv ? hv_fetch_ent(data_hv, h_sv, 0, 0) : NULL;
				SV *restrict arr_sv = arr_he ? HeVAL(arr_he) : NULL;
				if (arr_sv && SvROK(arr_sv)) {
					AV *restrict arr = (AV*)SvRV(arr_sv);
					SV **restrict cell_ptr = av_fetch(arr, (SSize_t)i, 0);
					if (cell_ptr && SvOK(*cell_ptr)) {
						if (SvROK(*cell_ptr)) {
							if (fh) PerlIO_close(fh);
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
			print_string_row(aTHX_ fh, row_data, d_idx, sep, collect_av);
		}
		safefree(row_data);
	} else if (is_aoh) { // Array of Hashes
		AV *restrict data_av = (AV*)data_ref;
		size_t num_rows = (size_t)(av_len(data_av) + 1);
		if (col_names_sv && SvOK(col_names_sv)) {
			AV *restrict c_av = (AV*)SvRV(col_names_sv);
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
// UTF-8 safety: keep the key SVs (flags intact) and sort
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
			for (SSize_t i = 0; i <= av_len(headers_av); i++) {
				SV **restrict h_ptr = av_fetch(headers_av, i, 0);
				if (!h_ptr || !*h_ptr) continue;
				SV *restrict h_sv = *h_ptr;
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
		print_string_row(aTHX_ fh, header_row, h_idx, sep, collect_av);
		safefree(header_row);
		const char **restrict row_data = safemalloc((num_headers + 1) * sizeof(char*));
		char rn_buf[32];
		for (size_t i = 0; i < num_rows; i++) {
			size_t d_idx = 0;
			SV **restrict row_ptr = av_fetch(data_av, (SSize_t)i, 0);
			HV *restrict row_hv = (row_ptr && SvROK(*row_ptr)) ? (HV*)SvRV(*row_ptr) : NULL;
			if (inc_rownames) {
				if (rownames_col) {
					HE *restrict rn_he = row_hv ? hv_fetch_ent(row_hv, row_names_sv, 0, 0) : NULL;
					SV *restrict rn_sv = rn_he ? HeVAL(rn_he) : NULL;
					if (rn_sv && SvOK(rn_sv)) {
						if (SvROK(rn_sv)) {
							if (fh) PerlIO_close(fh);
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
				HE *restrict cell_he = (row_hv && h_sv) ? hv_fetch_ent(row_hv, h_sv, 0, 0) : NULL;
				SV *restrict cell_sv = cell_he ? HeVAL(cell_he) : NULL;
				if (cell_sv && SvOK(cell_sv)) {
					if (SvROK(cell_sv)) {
						if (fh) PerlIO_close(fh);
						safefree(row_data);
						if (headers_av) SvREFCNT_dec(headers_av);
						croak("write_table: Cannot write nested reference types to table\n");
					}
					row_data[d_idx++] = SvPV_nolen(cell_sv);
				} else {
					row_data[d_idx++] = undef_val;
				}
			}
			print_string_row(aTHX_ fh, row_data, d_idx, sep, collect_av);
		}
		safefree(row_data);
	} else if (is_aoa) {// ----- Array of Arrays 
		AV *restrict data_av = (AV*)data_ref;
		SSize_t last = av_len(data_av);   // index of last element
		SSize_t data_start = 0;            // first data-row index
// Headers: explicit col.names, else the first inner array (which is
// then consumed as the header rather than emitted as data).
		if (col_names_sv && SvOK(col_names_sv)) {
			AV *restrict c_av = (AV*)SvRV(col_names_sv);
			for (SSize_t i = 0; i <= av_len(c_av); i++) {
				SV **restrict c = av_fetch(c_av, i, 0);
				if (c && SvOK(*c)) av_push(headers_av, newSVsv(*c));
			}
		} else {
			SV **restrict h0 = av_fetch(data_av, 0, 0);
			AV *restrict h_av = (h0 && *h0 && SvROK(*h0)) ? (AV*)SvRV(*h0) : NULL;
			if (h_av) {
				for (SSize_t i = 0; i <= av_len(h_av); i++) {
					SV **restrict c = av_fetch(h_av, i, 0);
					av_push(headers_av, (c && *c && SvOK(*c)) ? newSVsv(*c) : newSVpvs(""));
				}
			}
			data_start = 1;
		}
		size_t num_headers = (size_t)(av_len(headers_av) + 1);
		const char **restrict header_row = safemalloc((num_headers + 1) * sizeof(char*));
		size_t h_idx = 0;
		if (inc_rownames) header_row[h_idx++] = "";
		for (size_t i = 0; i < num_headers; i++) {
			SV **restrict h_ptr = av_fetch(headers_av, (SSize_t)i, 0);
			header_row[h_idx++] = (h_ptr && *h_ptr && SvOK(*h_ptr)) ? SvPV_nolen(*h_ptr) : "";
		}
		print_string_row(aTHX_ fh, header_row, h_idx, sep, collect_av);
		safefree(header_row);
		const char **restrict row_data = safemalloc((num_headers + 1) * sizeof(char*));
		char rn_buf[32]; // numeric row labels, printed before reuse (see HoA)
		unsigned long rn = 0;
		for (SSize_t r = data_start; r <= last; r++) {
			size_t d_idx = 0;
			if (inc_rownames) {
				snprintf(rn_buf, sizeof(rn_buf), "%lu", ++rn);
				row_data[d_idx++] = rn_buf;
			}
			SV **restrict row_ptr = av_fetch(data_av, r, 0);
			AV *restrict row_av = (row_ptr && *row_ptr && SvROK(*row_ptr)) ? (AV*)SvRV(*row_ptr) : NULL;
			for (size_t j = 0; j < num_headers; j++) {
				SV **restrict cell_ptr = row_av ? av_fetch(row_av, (SSize_t)j, 0) : NULL;
				if (cell_ptr && *cell_ptr && SvOK(*cell_ptr)) {
					if (SvROK(*cell_ptr)) {
						if (fh) PerlIO_close(fh);
						safefree(row_data);
						if (headers_av) SvREFCNT_dec(headers_av);
						croak("write_table: Cannot write nested reference types to table\n");
					}
					row_data[d_idx++] = SvPV_nolen(*cell_ptr);
				} else {
					row_data[d_idx++] = undef_val;
				}
			}
			print_string_row(aTHX_ fh, row_data, d_idx, sep, collect_av);
		}
		safefree(row_data);
	}
	if (headers_av) SvREFCNT_dec(headers_av);
	if (rows_av) SvREFCNT_dec(rows_av);
	if (fh) PerlIO_close(fh);
// Delimited output is already on disk by the time the handle closes, so this
// is where csv/tsv announces itself. Guarded on 'fh' rather than on '!collect'
// so the line is printed only when a file was actually opened and written.
	if (fh) write_table_announce(aTHX_ file);
// LaTeX output: render the collected table to the main file now that the
// rows are gathered. With 'tex' on nothing was written above, so this is
// the only writer of 'file'.
	if (tex && collect_av && av_len(collect_av) >= 0) {
		write_tex_tabular(aTHX_ collect_av, file, tex_align,
			tex_bold1, tex_format, tex_size, tex_comment, tex_longtable,
			tex_longtable_head);
		write_table_announce(aTHX_ file);
	}
// .xlsx output: build the workbook from the collected rows. The provenance
// line goes into the workbook's document "comments" property (dc:description),
// with any user-supplied xlsx.comment line(s) appended after it.
	if (xlsx && collect_av && av_len(collect_av) >= 0) {
		SV *restrict prov = xlsx_written_by(aTHX);
		if (xlsx_comment && SvOK(xlsx_comment)) {
			if (SvROK(xlsx_comment) && SvTYPE(SvRV(xlsx_comment)) == SVt_PVAV) {
				AV *restrict ca = (AV*)SvRV(xlsx_comment);
				for (SSize_t i = 0; i <= av_len(ca); i++) {
					SV **restrict c = av_fetch(ca, i, 0);
					if (c && *c && SvOK(*c)) { SV_CATLIT(prov, "\n"); sv_catsv(prov, *c); }
				}
			} else if (!SvROK(xlsx_comment)) {
				SV_CATLIT(prov, "\n"); sv_catsv(prov, xlsx_comment);
			}
		}
		write_xlsx_workbook(aTHX_ collect_av, file, xlsx_sheet, prov,
			(unsigned)xlsx_freeze_rows, (unsigned)xlsx_freeze_cols);
		write_table_announce(aTHX_ file);
	}
	XSRETURN_EMPTY;
}

SV* _parse_csv_file(char* file, const char* sep_str, const char* comment_str, SV* callback = &PL_sv_undef)
PREINIT:
	PerlIO *restrict fp;
	AV *restrict data = NULL;
	AV *current_row = NULL;
	SV *restrict field = NULL;
	SV *restrict line_sv = NULL;
	bool in_quotes = 0, post_quote = 0, use_cb = 0;
	size_t sep_len, comment_len;
	char sep0 = 0;
CODE:
	if (SvOK(callback)) {
		if (SvROK(callback) && SvTYPE(SvRV(callback)) == SVt_PVCV)
			use_cb = 1;
		else
			croak("_parse_csv_file: callback must be a CODE reference");
	}
	sep_len = sep_str ? strlen(sep_str) : 0;
	comment_len = comment_str ? strlen(comment_str) : 0;
	sep0 = sep_len ? sep_str[0] : 0;
	fp = PerlIO_open(file, "r");
	if (!fp)
		croak("Could not open file '%s'", file);
	ENTER;
	SAVEDESTRUCTOR_X(S_pclose, fp);
	line_sv = newSV(128);
	SAVEFREESV(line_sv);
	field = newSVpvs("");
	SAVEFREESV(field);
	if (!use_cb)
		data = newAV();
	current_row = newAV();
	while (sv_gets(line_sv, fp, 0) != NULL) {
		char *restrict line = SvPVX(line_sv);
		size_t len = SvCUR(line_sv);
		if (len && line[len-1] == '\n') {
			len--;
			if (len && line[len-1] == '\r')
				len--;
		}
		if (!in_quotes) {
			size_t k = 0;
			while (k < len && (line[k] == ' ' || line[k] == '\t'))
				k++;
			if (k == len)
				continue;
/* A line is a comment only when the marker is followed by whitespace
 * or end-of-line: "# prose" and a bare "#" are skipped, but "#id,val"
 * (marker hugging content) is treated as content so a "#"-prefixed
 * header survives to read_table for stripping. */
			if (comment_len && len >= comment_len
					&& memcmp(line, comment_str, comment_len) == 0
					&& (len == comment_len
						|| line[comment_len] == 0x20 || line[comment_len] == 0x09))
				continue;
		}
		{
		size_t i = 0;
		while (i < len) {
			if (in_quotes) {
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
					i += run;
				}
				if (i + 1 < len && line[i+1] == '"') {
					sv_catpvn(field, "\"", 1);
					i += 2;
				} else {
					in_quotes = 0;
					post_quote = 1;
					i += 1;
				}
			} else {
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
						if (!post_quote)
							in_quotes = 1;
						i++;
					} else if (c == '\r') {
						i++;
					} else {
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
			sv_catpvn(field, "\n", 1);
		} else {
			post_quote = 0;
			S_emit_row(aTHX_ &current_row, field, use_cb, callback, data);
		}
	}
	if (in_quotes) {
		S_emit_row(aTHX_ &current_row, field, use_cb, callback, data);
	}
	SvREFCNT_dec((SV*)current_row);
	LEAVE;
	if (use_cb) {
		RETVAL = newSV(0);
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

SV *predict(...)
	CODE:
	{
		SV   *restrict model_sv   = NULL;
		SV   *restrict newdata_sv  = NULL;
		const char *restrict type  = "response";
		HV   *restrict model = NULL, *restrict coef_hv = NULL, *restrict xlevels_hv = NULL;
		HV   *restrict dummy_hv = NULL;
		SV  **restrict svp = NULL;
		bool  is_binomial = FALSE, want_response = TRUE;
		HV   *restrict data_hoa = NULL;
		HV  **restrict row_hashes = NULL;
		char **restrict row_names = NULL;
		const char **restrict fbase = NULL;   /* factor base column names (borrowed) */
		AV  **restrict flev = NULL;            /* factor level lists      (borrowed) */
		size_t nbase = 0, scratch_cap = 16;
		char  *restrict scratch = NULL;        /* buffer for "base"."level" */
		const char **restrict cterm = NULL;    /* non-dummy, non-factor-interaction coef terms (borrowed) */
		NV   *restrict cbeta = NULL;
		size_t n = 0, ncoef = 0, i, j, kk;
		SV   *restrict ref = NULL;
		HV   *restrict out_hv = NULL;
		HE   *restrict he = NULL;

		/* NEW: factor-bearing interaction terms, parsed into components */
		char  **restrict icopy   = NULL;       /* writable "GroupB:Sexmale" copies (split in place) */
		NV     *restrict ibeta   = NULL;       /* their betas */
		size_t  nint = 0;
		bool        *restrict cf_isfac = NULL; /* per flat component: is it a factor dummy? */
		int         *restrict cf_base  = NULL; /* component's factor base index (into fbase/flev) */
		const char **restrict cf_lvl   = NULL; /* component's level string (borrowed into icopy) */
		const char **restrict cf_term  = NULL; /* component's continuous term string (borrowed into icopy) */
		size_t      *restrict ic_off   = NULL; /* per interaction: offset into flat component arrays */
		size_t      *restrict ic_cnt   = NULL; /* per interaction: component count */
		char       **restrict raw_lv   = NULL; /* per-row raw level string per factor base */

		if (items < 1)
			croak("Usage: predict($model, $newdata, type => 'response')");
		model_sv = ST(0);
		if (items >= 2) newdata_sv = ST(1);
		if (items > 2) {
			if ((items - 2) % 2 != 0)
				croak("predict: options after newdata must be name => value pairs");
			for (unsigned short a = 2; a < items; a += 2) {
				const char *restrict key = SvPV_nolen(ST(a));
				if (strEQ(key, "type")) type = SvPV_nolen(ST(a + 1));
				else croak("predict: unknown argument '%s'", key);
			}
		}
		if (strNE(type, "response") && strNE(type, "link"))
			croak("predict: type must be 'response' or 'link'");
		want_response = strEQ(type, "response");

		if (!SvROK(model_sv) || SvTYPE(SvRV(model_sv)) != SVt_PVHV)
			croak("predict: model must be a fitted lm/glm hashref");
		model = (HV*)SvRV(model_sv);

		svp = hv_fetch(model, "family", 6, 0);
		if (svp && *svp && SvOK(*svp))
			is_binomial = (strcmp(SvPV_nolen(*svp), "binomial") == 0);

		if (!newdata_sv || !SvOK(newdata_sv)) {
			/* no newdata -> hand back the stored fitted values unchanged */
			svp = hv_fetch(model, "fitted.values", 13, 0);
			if (!svp || !*svp || !SvROK(*svp))
				croak("predict: no newdata given and model has no 'fitted.values'");
			RETVAL = newRV_inc(SvRV(*svp));
		} else {
			if (!SvROK(newdata_sv))
				croak("predict: newdata must be a HoA/HoH/AoH or a flat hashref");

			svp = hv_fetch(model, "coefficients", 12, 0);
			if (!svp || !*svp || !SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVHV)
				croak("predict: model has no 'coefficients' hashref");
			coef_hv = (HV*)SvRV(*svp);

			svp = hv_fetch(model, "xlevels", 7, 0);
			if (svp && *svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV)
				xlevels_hv = (HV*)SvRV(*svp);

			ENTER; SAVETMPS;

			/* ---- resolve newdata: HoA / HoH / AoH / flat single-row hash ---- */
			ref = SvRV(newdata_sv);
			if (SvTYPE(ref) == SVt_PVHV) {
				HV *restrict hv = (HV*)ref;
				HE *restrict e;
				SV *restrict v0;
				if (hv_iterinit(hv) == 0)
					croak("predict: newdata hash is empty");
				e  = hv_iternext(hv);
				v0 = HeVAL(e);
				if (SvROK(v0) && SvTYPE(SvRV(v0)) == SVt_PVAV) {        /* HoA */
					static const char *const rn_keys[] =
						{ "row.names", "_row", "rownames", ".rownames" };
					AV *restrict rn_av = NULL;
					data_hoa = hv;
					n = (size_t)(av_len((AV*)SvRV(v0)) + 1);
					Newx(row_names, n ? n : 1, char*); SAVEFREEPV(row_names);
					for (kk = 0; kk < sizeof rn_keys / sizeof rn_keys[0]; kk++) {
						SV **restrict rn = hv_fetch(hv, rn_keys[kk], (I32)strlen(rn_keys[kk]), 0);
						if (rn && *rn && SvROK(*rn) && SvTYPE(SvRV(*rn)) == SVt_PVAV) {
							rn_av = (AV*)SvRV(*rn); break;
						}
					}
					for (i = 0; i < n; i++) {
						SV **restrict nm = rn_av ? av_fetch(rn_av, (SSize_t)i, 0) : NULL;
						if (nm && *nm && SvOK(*nm)) {
							STRLEN l; const char *restrict s = SvPV(*nm, l);
							row_names[i] = savepvn(s, l);
						} else {
							char buf[32];
							snprintf(buf, sizeof(buf), "%lu", (unsigned long)(i + 1));
							row_names[i] = savepv(buf);
						}
						SAVEFREEPV(row_names[i]);
					}
				} else if (SvROK(v0) && SvTYPE(SvRV(v0)) == SVt_PVHV) { /* HoH */
					n = (size_t)HvUSEDKEYS(hv);
					Newx(row_names,  n ? n : 1, char*); SAVEFREEPV(row_names);
					Newx(row_hashes, n ? n : 1, HV*);   SAVEFREEPV(row_hashes);
					hv_iterinit(hv);
					i = 0;
					while ((e = hv_iternext(hv))) {
						I32 klen;
						row_names[i]  = savepv(hv_iterkey(e, &klen)); SAVEFREEPV(row_names[i]);
						row_hashes[i] = (HV*)SvRV(HeVAL(e));
						i++;
					}
				} else {                                               /* flat single row */
					n = 1;
					Newx(row_names,  1, char*); SAVEFREEPV(row_names);
					Newx(row_hashes, 1, HV*);   SAVEFREEPV(row_hashes);
					row_names[0]  = savepv("1"); SAVEFREEPV(row_names[0]);
					row_hashes[0] = hv;
				}
			} else if (SvTYPE(ref) == SVt_PVAV) {                      /* AoH */
				static const char *const rn_keys[] =
					{ "row.names", "_row", "rownames", ".rownames" };
				AV *restrict av = (AV*)ref;
				n = (size_t)(av_len(av) + 1);
				Newx(row_names,  n ? n : 1, char*); SAVEFREEPV(row_names);
				Newx(row_hashes, n ? n : 1, HV*);   SAVEFREEPV(row_hashes);
				for (i = 0; i < n; i++) {
					SV **restrict vp = av_fetch(av, (SSize_t)i, 0);
					HV  *restrict rh;
					SV **restrict nm = NULL;
					if (!vp || !SvROK(*vp) || SvTYPE(SvRV(*vp)) != SVt_PVHV)
						croak("predict: AoH values must be hashrefs");
					rh = (HV*)SvRV(*vp);
					row_hashes[i] = rh;
					for (kk = 0; kk < sizeof rn_keys / sizeof rn_keys[0]; kk++) {
						nm = hv_fetch(rh, rn_keys[kk], (I32)strlen(rn_keys[kk]), 0);
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
					SAVEFREEPV(row_names[i]);
				}
			} else {
				croak("predict: newdata must be a HoA/HoH/AoH or a flat hashref");
			}

			/* ---- factor bases from xlevels, plus the dummy-name set ---- */
			if (xlevels_hv && HvUSEDKEYS(xlevels_hv) > 0) {
				nbase = (size_t)HvUSEDKEYS(xlevels_hv);
				Newx(fbase, nbase, const char*); SAVEFREEPV(fbase);
				Newx(flev,  nbase, AV*);         SAVEFREEPV(flev);
				dummy_hv = newHV(); SAVEFREESV((SV*)dummy_hv);
				hv_iterinit(xlevels_hv);
				kk = 0;
				while ((he = hv_iternext(xlevels_hv))) {
					I32 blen;
					SV *restrict lv = HeVAL(he);
					if (!SvROK(lv) || SvTYPE(SvRV(lv)) != SVt_PVAV) continue;
					fbase[kk] = hv_iterkey(he, &blen);          /* borrowed */
					flev[kk]  = (AV*)SvRV(lv);
					{
						size_t blen2 = strlen(fbase[kk]);
						SSize_t nl = av_len(flev[kk]) + 1, l1;
						/* Every level, not just levels[1..]. A factor coded in
						 * full -- one in a model with no intercept, or one whose
						 * margin is absent -- also has a column for its first
						 * level, and without it registered here that column
						 * would be mistaken for a continuous term and looked up
						 * as a data column. A reduced-coded model simply never
						 * names the extra entry. */
						for (l1 = 0; l1 < nl; l1++) {
							SV **restrict ls = av_fetch(flev[kk], l1, 0);
							if (ls && *ls && SvOK(*ls)) {
								STRLEN ll; const char *restrict lp = SvPV(*ls, ll);
								if (blen2 + ll + 1 > scratch_cap) scratch_cap = blen2 + ll + 1;
								char *restrict dn = (char*)safemalloc(blen2 + ll + 1);
								memcpy(dn, fbase[kk], blen2);
								memcpy(dn + blen2, lp, ll);
								dn[blen2 + ll] = '\0';
								/* CHANGED: store the base index so interaction parsing can
								   recover (base, level) from a dummy name in O(1) */
								hv_store(dummy_hv, dn, (I32)(blen2 + ll), newSViv((IV)kk), 0);
								Safefree(dn);
							}
						}
					}
					kk++;
				}
				nbase = kk;
				Newx(scratch, scratch_cap, char); SAVEFREEPV(scratch);
			}

			/* ---- cache coef terms; route factor-bearing interactions aside ---- */
			{
				I32 nk = (I32)HvUSEDKEYS(coef_hv);
				Newx(cterm, nk ? nk : 1, const char*); SAVEFREEPV(cterm);
				Newx(cbeta, nk ? nk : 1, NV);          SAVEFREEPV(cbeta);
				Newx(icopy, nk ? nk : 1, char*);       SAVEFREEPV(icopy);   /* NEW */
				Newx(ibeta, nk ? nk : 1, NV);          SAVEFREEPV(ibeta);   /* NEW */
				hv_iterinit(coef_hv);
				ncoef = 0;
				while ((he = hv_iternext(coef_hv))) {
					I32 klen;
					const char *restrict t = hv_iterkey(he, &klen);
					NV b = SvNV(HeVAL(he));
					if (isnan(b)) continue;                         /* aliased -> drop */
					if (dummy_hv && hv_exists(dummy_hv, t, klen)) continue;  /* main-effect factor */

					/* NEW: an interaction with >=1 factor component needs special handling;
					   pure-continuous interactions (e.g. x:z) stay on the evaluate_term path */
					if (strchr(t, ':')) {
						char tbuf[512];
						snprintf(tbuf, sizeof(tbuf), "%s", t);
						bool has_factor = FALSE;
						char *restrict cp = tbuf;
						while (cp) {
							char *restrict cl = strchr(cp, ':');
							if (cl) *cl = '\0';
							if (dummy_hv && hv_exists(dummy_hv, cp, (I32)strlen(cp)))
								has_factor = TRUE;
							cp = cl ? cl + 1 : NULL;
						}
						if (has_factor) {
							icopy[nint] = savepv(t); SAVEFREEPV(icopy[nint]);
							ibeta[nint] = b;
							nint++;
							continue;
						}
					}

					cterm[ncoef] = t;     /* continuous term or pure-continuous interaction */
					cbeta[ncoef] = b;
					ncoef++;
				}
			}

			/* ---- NEW: parse factor-bearing interactions into flat components ---- */
			{
				size_t total_comp = 0, k, pos = 0;
				for (k = 0; k < nint; k++) {
					const char *restrict s = icopy[k];
					total_comp++;
					for (; *s; s++) if (*s == ':') total_comp++;
				}
				Newx(cf_isfac, total_comp ? total_comp : 1, bool);        SAVEFREEPV(cf_isfac);
				Newx(cf_base,  total_comp ? total_comp : 1, int);         SAVEFREEPV(cf_base);
				Newx(cf_lvl,   total_comp ? total_comp : 1, const char*); SAVEFREEPV(cf_lvl);
				Newx(cf_term,  total_comp ? total_comp : 1, const char*); SAVEFREEPV(cf_term);
				Newx(ic_off,   nint ? nint : 1, size_t);                  SAVEFREEPV(ic_off);
				Newx(ic_cnt,   nint ? nint : 1, size_t);                  SAVEFREEPV(ic_cnt);
				for (k = 0; k < nint; k++) {
					char *restrict comp = icopy[k];   /* split in place on ':' */
					ic_off[k] = pos;
					while (comp) {
						char *restrict colon = strchr(comp, ':');
						if (colon) *colon = '\0';
						SV **restrict dv = dummy_hv ? hv_fetch(dummy_hv, comp, (I32)strlen(comp), 0) : NULL;
						if (dv && *dv && SvOK(*dv)) {
							int bidx = (int)SvIV(*dv);
							cf_isfac[pos] = TRUE;
							cf_base[pos]  = bidx;
							cf_lvl[pos]   = comp + strlen(fbase[bidx]);  /* level part of base.level */
							cf_term[pos]  = NULL;
						} else {
							cf_isfac[pos] = FALSE;
							cf_base[pos]  = -1;
							cf_lvl[pos]   = NULL;
							cf_term[pos]  = comp;
							/* validate a simple continuous component up front (parity with main terms) */
							if (strNE(comp, "Intercept") && strncmp(comp, "I(", 2) != 0) {
								bool okc = data_hoa
									? (hv_exists(data_hoa, comp, (I32)strlen(comp)) ? TRUE : FALSE)
									: (n > 0 ? (hv_exists(row_hashes[0], comp, (I32)strlen(comp)) ? TRUE : FALSE) : TRUE);
								if (!okc)
									croak("predict: newdata is missing column '%s' (in interaction)", comp);
							}
						}
						pos++;
						comp = colon ? colon + 1 : NULL;
					}
					ic_cnt[k] = pos - ic_off[k];
				}
			}

			/* ---- validate required columns are present (clean die, not NaN) ---- */
			for (kk = 0; kk < nbase; kk++) {
				const char *restrict b = fbase[kk];
				bool ok = data_hoa ? (hv_exists(data_hoa, b, (I32)strlen(b)) ? TRUE : FALSE)
				        : (n > 0 ? (hv_exists(row_hashes[0], b, (I32)strlen(b)) ? TRUE : FALSE) : TRUE);
				if (!ok) croak("predict: newdata is missing factor column '%s'", b);
			}
			for (j = 0; j < ncoef; j++) {
				const char *restrict t = cterm[j];
				if (strEQ(t, "Intercept")) continue;
				if (strchr(t, ':') || strncmp(t, "I(", 2) == 0) continue;  /* interaction/transform */
				bool ok = data_hoa ? (hv_exists(data_hoa, t, (I32)strlen(t)) ? TRUE : FALSE)
				        : (n > 0 ? (hv_exists(row_hashes[0], t, (I32)strlen(t)) ? TRUE : FALSE) : TRUE);
				if (!ok) croak("predict: newdata is missing column '%s'", t);
			}

			/* per-row raw level scratch */
			if (nbase) { Newx(raw_lv, nbase, char*); SAVEFREEPV(raw_lv); }

			/* ---- per row: linear predictor, then inverse link ---- */
			out_hv = newHV(); SAVEFREESV((SV*)out_hv);   /* freed on croak; ref taken before LEAVE on success */
			for (i = 0; i < n; i++) {
				NV   eta = 0.0, pred;
				bool ok  = TRUE;

				for (kk = 0; kk < nbase; kk++) raw_lv[kk] = NULL;

				/* read each factor's raw level once; reused by main effects + interactions */
				for (kk = 0; ok && kk < nbase; kk++) {
					char *restrict raw = get_data_string_alloc(aTHX_ data_hoa, row_hashes, (unsigned int)i, fbase[kk]);
					SSize_t nl, l1, found = -1;
					if (!raw) { ok = FALSE; break; }             /* missing value -> NaN row */
					nl = av_len(flev[kk]) + 1;
					for (l1 = 0; l1 < nl; l1++) {
						SV **restrict ls = av_fetch(flev[kk], l1, 0);
						if (ls && *ls && SvOK(*ls) && strcmp(SvPV_nolen(*ls), raw) == 0) { found = l1; break; }
					}
					if (found < 0) {
						char base_cpy[256], lvl_cpy[256];
						size_t z;
						snprintf(base_cpy, sizeof(base_cpy), "%s", fbase[kk]);
						snprintf(lvl_cpy,  sizeof(lvl_cpy),  "%s", raw);
						Safefree(raw);
						for (z = 0; z < kk; z++) if (raw_lv[z]) Safefree(raw_lv[z]);
						croak("predict: factor '%s' has unseen level '%s'", base_cpy, lvl_cpy);
					}
					raw_lv[kk] = raw;                            /* keep; freed at row end */
					/* Look the level's dummy up whatever its position. A factor
					 * coded by contrasts has no coefficient for its reference
					 * level, so the fetch simply misses and contributes nothing;
					 * one coded in full does have that column, and skipping it
					 * on the strength of found == 0 would score every reference
					 * row as if the term were absent. */
					snprintf(scratch, scratch_cap, "%s%s", fbase[kk], raw);
					svp = hv_fetch(coef_hv, scratch, (I32)strlen(scratch), 0);
					if (svp && *svp) {
						NV b = SvNV(*svp);
						if (!isnan(b)) eta += b;
					}
				}

				/* non-factor terms via the same engine used at fit time */
				for (j = 0; ok && j < ncoef; j++) {
					NV v;
					if (strEQ(cterm[j], "Intercept")) v = 1.0;
					else v = evaluate_term(aTHX_ data_hoa, row_hashes, (unsigned int)i, cterm[j]);
					if (isnan(v)) { ok = FALSE; break; }
					eta += cbeta[j] * v;
				}

				/* NEW: factor-bearing interactions — product of component values */
				for (size_t k = 0; ok && k < nint; k++) {
					NV prod = 1.0;
					size_t off = ic_off[k], cnt = ic_cnt[k], m;
					for (m = off; m < off + cnt; m++) {
						if (cf_isfac[m]) {
							int bidx = cf_base[m];
							/* indicator: 1 iff this row's level for that base equals the dummy's level */
							prod *= (raw_lv[bidx] && strcmp(raw_lv[bidx], cf_lvl[m]) == 0) ? 1.0 : 0.0;
						} else {
							NV v = evaluate_term(aTHX_ data_hoa, row_hashes, (unsigned int)i, cf_term[m]);
							if (isnan(v)) { ok = FALSE; break; }
							prod *= v;
						}
					}
					if (!ok) break;
					eta += ibeta[k] * prod;
				}

				for (kk = 0; kk < nbase; kk++)
					if (raw_lv[kk]) { Safefree(raw_lv[kk]); raw_lv[kk] = NULL; }

				pred = (!ok) ? NAN
				     : (is_binomial && want_response) ? (1.0 / (1.0 + exp(-eta)))
				     : eta;
				hv_store(out_hv, row_names[i], (I32)strlen(row_names[i]), newSVnv(pred), 0);
			}

			RETVAL = newRV_inc((SV*)out_hv);   /* +1 -> survives the SAVEFREESV decrement at LEAVE */
			FREETMPS; LEAVE;
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
	char *restrict f_cpy = NULL;
	char *restrict lhs = NULL, *restrict rhs = NULL;

	char **restrict terms = NULL, **restrict uniq_terms = NULL;
	LmDesign *restrict design = NULL;
	unsigned int num_terms = 0, num_uniq = 0, p = 0;
	size_t n = 0, valid_n = 0, i;
	bool has_intercept = TRUE, converged = FALSE, boundary = FALSE;
	unsigned int iter = 0, max_iter = 25, final_rank = 0, df_res = 0;
	NV deviance_old = 0.0, deviance_new = 0.0, null_dev = 0.0, aic = 0.0;
	NV dispersion = 0.0, epsilon = 1e-8;
	NV theta = 0.0, conf_level = 0.95;
	bool theta_given = FALSE;

	char **restrict row_names = NULL;
	char **restrict valid_row_names = NULL;
	HV **restrict row_hashes = NULL;
	HV *restrict data_hoa = NULL;

	NV *restrict X = NULL, *restrict Y = NULL, *restrict mu = NULL, *restrict eta = NULL;
	NV *restrict W = NULL, *restrict Z = NULL, *restrict beta = NULL, *restrict beta_old = NULL;
	bool *restrict aliased = NULL;
	NV *restrict XtWX = NULL, *restrict XtWZ = NULL;

	HV *restrict res_hv, *restrict coef_hv, *restrict fitted_hv, *restrict resid_hv, *restrict summary_hv;
	HV *restrict xlevels_hv = NULL;
	AV *restrict terms_av;

	if (items % 2 != 0) croak("Usage: glm(formula => 'am ~ wt + hp', data => \\%mtcars)");

	for (unsigned short i_arg = 0; i_arg < items; i_arg += 2) {
	  const char *restrict key = SvPV_nolen(ST(i_arg));
	  SV *restrict val = ST(i_arg + 1);
	  if      (strEQ(key, "formula")) formula = SvPV_nolen(val);
	  else if (strEQ(key, "data"))    data_sv = val;
	  else if (strEQ(key, "family"))  family_str = SvPV_nolen(val);
	  else if (strEQ(key, "theta"))   { theta = SvNV(val); theta_given = TRUE; }
	  else if (strEQ(key, "conf.level") || strEQ(key, "conf_level")) conf_level = SvNV(val);
	  else croak("glm: unknown argument '%s'", key);
	}
	if (!formula) croak("glm: formula is required");
	if (!data_sv || !SvROK(data_sv)) croak("glm: data is required and must be a reference");
	if (conf_level <= 0.0 || conf_level >= 1.0) croak("glm: conf.level must be between 0 and 1");

	bool is_binomial = (strcmp(family_str, "binomial") == 0);
	bool is_gaussian = (strcmp(family_str, "gaussian") == 0);
	bool is_poisson  = (strcmp(family_str, "poisson")  == 0);
	bool is_negbin   = (strcmp(family_str, "negbin") == 0
		|| strcmp(family_str, "negative.binomial") == 0 || strcmp(family_str, "nb") == 0);
	if (!is_binomial && !is_gaussian && !is_poisson && !is_negbin)
		croak("glm: unsupported family '%s' (gaussian, binomial, poisson, negbin)", family_str);
	bool log_link = is_poisson || is_negbin;
	if (theta_given && theta <= 0.0) croak("glm: theta must be positive");
	if (theta_given && !is_negbin)
		warn("glm: 'theta' is only used by the negbin family; ignoring");
	/* negbin without a supplied theta: seed with a large theta so the first
	 * IRLS pass is effectively Poisson (matching MASS::glm.nb, which seeds the
	 * theta ML from a Poisson fit's fitted means); theta is then re-estimated
	 * by ML after each pass. */
	if (is_negbin && !theta_given) theta = 1e6;

	/* Split the formula before touching the data: a malformed one croaks with
	 * nothing else allocated. '.' needs the columns, so the term list has to
	 * wait until after the rows are read. */
	f_cpy = lm_formula_split(aTHX_ formula, "glm", &lhs, &rhs, &has_intercept);
	n = lm_read_rows(aTHX_ data_sv, "glm", f_cpy, &data_hoa, &row_hashes, &row_names);
	lm_formula_terms(aTHX_ rhs, lhs, data_hoa, row_hashes, n, has_intercept, "glm",
	                 &terms, &num_terms, &uniq_terms, &num_uniq);
	xlevels_hv = newHV(); sv_2mortal((SV*)xlevels_hv);
	design = lm_design_build(aTHX_ data_hoa, row_hashes, n,
	                         uniq_terms, (unsigned int)num_uniq, has_intercept,
	                         xlevels_hv);
	p = design->ncol;

	Newx(X, n * (p ? p : 1), NV); Newx(Y, n, NV);
	Newx(valid_row_names, n, char*);

	for (size_t i = 0; i < n; i++) {
		NV y_val = evaluate_term(aTHX_ data_hoa, row_hashes, i, lhs);
		if (isnan(y_val)) { Safefree(row_names[i]); continue; }

		if (!lm_design_row(aTHX_ design, data_hoa, row_hashes, i,
		                   X + valid_n * (size_t)p)) {
			Safefree(row_names[i]); continue;
		}
		Y[valid_n] = y_val;
		valid_row_names[valid_n] = row_names[i];
		valid_n++;
	}
	Safefree(row_names);
	if (valid_n < p) {
	  for (i = 0; i < num_terms; i++) Safefree(terms[i]); Safefree(terms);
	  for (i = 0; i < num_uniq; i++) Safefree(uniq_terms[i]); Safefree(uniq_terms);
	  lm_design_free(aTHX_ design);
	  for (i = 0; i < valid_n; i++) Safefree(valid_row_names[i]);
	  Safefree(X); Safefree(Y); Safefree(valid_row_names); if (row_hashes) Safefree(row_hashes);
	  Safefree(f_cpy);
	  croak("glm: 0 degrees of freedom (too many NAs or parameters > observations)");
	}
	/* lhs was the last thing pointing into the formula copy. */
	Safefree(f_cpy); f_cpy = NULL;
	mu = (NV*)safemalloc(valid_n * sizeof(NV)); eta = (NV*)safemalloc(valid_n * sizeof(NV));
	W = (NV*)safemalloc(valid_n * sizeof(NV)); Z = (NV*)safemalloc(valid_n * sizeof(NV));
	beta = (NV*)safemalloc(p * sizeof(NV)); beta_old = (NV*)safemalloc(p * sizeof(NV));
	aliased = (bool*)safemalloc(p * sizeof(bool));
	XtWX = (NV*)safemalloc(p * p * sizeof(NV)); XtWZ = (NV*)safemalloc(p * sizeof(NV));
	NV sum_y = 0.0;
	for (i = 0; i < valid_n; i++) sum_y += Y[i];
	NV mean_y = sum_y / valid_n;
	if (log_link && mean_y <= 0.0) croak("glm: poisson/negbin family requires some positive counts");

	/* Negative binomial: alternate an IRLS fit at the current theta with a fresh
	 * ML estimate of theta at the current fitted means, exactly as MASS::glm.nb
	 * does. Every other family runs the body once.
	 *
	 * Three details of glm.nb decide whether the answers agree, and all three
	 * are reproduced below:
	 *
	 *  - The FIRST pass is an ordinary Poisson fit, not a negative-binomial one
	 *    at some large stand-in theta. Its fitted means are what the first theta
	 *    is estimated from, and its residual degrees of freedom set d1.
	 *  - Each later pass is WARM STARTED from the previous pass's means
	 *    (glm.nb passes etastart = log(mu)), so the fit it lands on is the one
	 *    MASS lands on rather than merely the same optimum reached from
	 *    elsewhere.
	 *  - Inside the loop theta is re-estimated from the means that STARTED the
	 *    pass, not the ones the pass just produced: glm.nb calls
	 *    theta.ml(Y, mu) and only then reassigns mu <- fit$fitted.values. The
	 *    lag is easy to miss and moves theta in the eighth digit.
	 *
	 * The convergence test is MASS's as well:
	 *
	 *     (|Lm0 - Lm| / d1 + |theta - theta_prev| / d2) < epsilon
	 *
	 * with d1 = sqrt(2 * max(1, df.residual)) from the Poisson pass, d2 = 1 and
	 * epsilon = 1e-8. What used to be here was a relative test on the
	 * log-likelihood alone -- |dll| < 1e-7 * (|ll| + 0.1) -- which on an
	 * 80-observation fit is satisfied roughly 2e-5 of log-likelihood early and
	 * left theta 8e-7 away from MASS's, dragging the coefficients 8e-6 with it.
	 * Dividing the log-likelihood move by d1 and requiring theta itself to have
	 * settled is what makes the alternation stop in the same place. */
	unsigned int outer_max = (is_negbin && !theta_given) ? (max_iter + 1) : 1;
	NV  nb_d1 = 1.0, nb_Lm = 0.0, nb_Lm0 = 0.0, nb_del = 1.0;
	NV *restrict nb_mu_prev = NULL;
	bool nb_alt_converged = FALSE;
	for (unsigned int outer = 0; outer < outer_max; outer++) {
	/* Pass 0 of a theta-estimating fit is Poisson; treat the family as Poisson
	 * throughout that pass rather than approximating it with a huge theta. */
	bool nb_pois_pass = (is_negbin && !theta_given && outer == 0);
	bool use_negbin   = is_negbin && !nb_pois_pass;
	/* Passes after the first warm start where the previous one finished, and the
	 * means they start from are also the ones theta is re-estimated at. */
	bool nb_warm = (is_negbin && !theta_given && outer > 0);
	if (nb_warm) {
		/* Allocated on first use rather than before the loop: the response
		 * validation in the cold-start block below can croak, and there is no
		 * reason to have an allocation outstanding when it does. */
		if (!nb_mu_prev) nb_mu_prev = (NV*)safemalloc(valid_n * sizeof(NV));
		memcpy(nb_mu_prev, mu, valid_n * sizeof(NV));
	}
	if (nb_warm) {
		/* Keep mu, eta and beta where the last pass left them; only the
		 * deviance has to be restated under the new theta so that the IRLS
		 * convergence test starts from the right place. */
		deviance_old = 0.0;
		for (i = 0; i < valid_n; i++)
			deviance_old += dev_negbin(Y[i], mu[i], theta);
		converged = FALSE;
	} else {
	for (i = 0; i < p; i++) { beta[i] = 0.0; beta_old[i] = 0.0; }
	deviance_old = 0.0; converged = FALSE;
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
		} else if (log_link) {
			if (Y[i] < 0.0) croak("glm: poisson/negbin family requires a non-negative response");
			/* Each family's own mustart. R's poisson()$initialize sets y + 0.1,
			 * but MASS's negative.binomial()$initialize sets y + (y == 0)/6 --
			 * the observed count itself wherever it is positive. Starting a
			 * negative-binomial fit from the Poisson value instead walks a
			 * different sequence of iterates, and since the standard errors come
			 * from the penultimate one, that showed up as standard errors 6e-7
			 * out from R while the coefficients agreed to 1e-9. glm.nb's own
			 * first pass IS Poisson, so it keeps y + 0.1; its later passes are
			 * warm started and use no mustart at all. */
			mu[i]  = use_negbin ? (Y[i] + (Y[i] == 0.0 ? 1.0 / 6.0 : 0.0))
			                    : (Y[i] + 0.1);
			eta[i] = log(mu[i]);
			deviance_old += use_negbin ? dev_negbin(Y[i], mu[i], theta) : dev_poisson(Y[i], mu[i]);
		} else {
			mu[i] = mean_y;
			eta[i] = mu[i];
		}
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
			} else if (log_link) {
				 NV mu_eta = mu[i];  /* dmu/deta for the log link */
				 NV varmu  = use_negbin ? (mu[i] + mu[i] * mu[i] / theta) : mu[i];
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
				 } else if (log_link) {
					 mu[i] = exp(eta[i]);
					 if (mu[i] < 1e-10) mu[i] = 1e-10;
					 deviance_new += use_negbin ? dev_negbin(Y[i], mu[i], theta) : dev_poisson(Y[i], mu[i]);
				 } else {
					 mu[i] = eta[i];
					 NV res = Y[i] - mu[i];
					 deviance_new += res * res;
				 }
			}
			/* Halve the step only when the deviance came out non-finite, which is
			 * R's rule (glm.fit truncates the step "due to divergence" for a
			 * non-finite deviance, or when the link puts eta or mu outside its
			 * range -- the clamps above already prevent that here).
			 *
			 * A deviance that merely rose is NOT divergence, and treating it as
			 * such was costing iterations on every non-gaussian fit. The standard
			 * IRLS start puts mu at y + 0.1, i.e. essentially on the data, so the
			 * initial deviance is near zero -- 0.016 for the nine-point poisson
			 * fit in t/glm.t -- and the first real step necessarily raises it, to
			 * 1.54 there. The old test read that as divergence and halved the
			 * step ten times over, crippling the first move and turning a
			 * four-iteration fit into a seven-iteration one. The extra iterations
			 * converged to the same coefficients, but they left the weights of
			 * the penultimate iterate -- the ones the standard errors are built
			 * from, here and in R alike -- a different distance from the MLE than
			 * R's, which is why poisson and binomial standard errors used to sit
			 * 5e-8 to 2e-5 away from R's while the coefficients agreed to twelve
			 * digits.
			 *
			 * Note also that the old condition had the isfinite test on the
			 * accepting side, so a genuinely divergent step producing a NaN
			 * deviance was kept rather than truncated. */
			if (is_gaussian || isfinite(deviance_new)) break;
			if (half + 1 >= 10) break;   /* stop halving rather than spin */
			boundary = TRUE;
			for (size_t j = 0; j < p; j++) beta[j] = (beta[j] + beta_old[j]) / 2.0;
		}
		if (fabs(deviance_new - deviance_old) / (0.1 + fabs(deviance_new)) < epsilon) {
			converged = TRUE; break;
		}
		deviance_old = deviance_new;
		for (size_t j = 0; j < p; j++) beta_old[j] = beta[j];
	}
	if (is_negbin && !theta_given) {
		if (nb_pois_pass) {
			/* Pre-loop half of glm.nb: the Poisson fit is done, so take the first
			 * theta from its means, size the log-likelihood scale d1 from its
			 * residual degrees of freedom, and prime the test the way MASS does
			 * -- Lm0 = Lm + 2 * d1, which makes the first term 2 and guarantees
			 * at least one alternation. */
			int pois_df = (int)valid_n - final_rank;
			nb_d1  = sqrt(2.0 * (NV)(pois_df > 1 ? pois_df : 1));
			theta  = nb_theta_ml(Y, mu, valid_n, max_iter);
			nb_Lm  = nb_loglik(Y, mu, valid_n, theta);
			nb_Lm0 = nb_Lm + 2.0 * nb_d1;
			nb_del = 1.0;
		} else {
			/* One alternation. theta comes from the means this pass STARTED at,
			 * which is the lag glm.nb has; mu is by now the means this pass
			 * produced, and the log-likelihood is taken at the pair (new theta,
			 * new mu). d2 is 1 in MASS and never changes, so |del| enters the
			 * test unscaled. */
			NV th_prev = theta;
			theta  = nb_theta_ml(Y, nb_mu_prev, valid_n, max_iter);
			nb_del = th_prev - theta;
			nb_Lm0 = nb_Lm;
			nb_Lm  = nb_loglik(Y, mu, valid_n, theta);
			if (fabs(nb_Lm0 - nb_Lm) / nb_d1 + fabs(nb_del) < epsilon) {
				nb_alt_converged = TRUE;
				break;
			}
			if (outer == outer_max - 1) {
				warn("glm: theta ML did not converge in %u alternations "
				     "(data may be under-dispersed / near-Poisson)", max_iter);
				converged = FALSE;
				break;
			}
		}
	}
	} /* end outer theta loop */
	/* The alternation exits with theta and the coefficients in step: the last
	 * pass fitted at the theta before it, then replaced theta with the estimate
	 * taken at that pass's starting means -- which is the pairing glm.nb reports,
	 * since it too returns the fit from before its final theta update. */
	if (is_negbin && !theta_given) {
		if (nb_alt_converged) converged = TRUE;
		if (nb_mu_prev) { Safefree(nb_mu_prev); nb_mu_prev = NULL; }
	}
	/* XtWX already holds what the standard errors need: sweep_matrix_ols
	 * inverted it in place during the last IRLS iteration, and nothing since has
	 * written to it. Those weights come from the mu that went INTO that
	 * iteration, i.e. from the iterate before the final coefficient update, and
	 * that is deliberate -- it is the matrix R reports from.
	 *
	 * R's glm.fit keeps the QR factorisation of its last weighted design matrix
	 * and summary.glm forms chol2inv(qr.R) from it, so R's standard errors are
	 * likewise built from the weights of the penultimate iterate; its
	 * $weights component is that same vector, one step behind $fitted.values.
	 * Rebuilding X'WX here from the converged mu instead is the more defensible
	 * estimator -- it evaluates the Fisher information at the MLE rather than a
	 * step short of it -- but it is not what R prints, and for a poisson fit the
	 * two differ by far more than the coefficients do: on `y ~ x + z` over nine
	 * observations the weights are 2.1e-7 apart, moving the standard errors by
	 * 5.4e-8 relative while the coefficients agree to twelve digits. Reusing the
	 * matrix the iteration already produced reproduces R to 2e-14.
	 *
	 * This is safe to rely on because the two implementations take the same path
	 * to get here: identical starting values (mustart of y + 0.1 for a log link,
	 * (y + 0.5)/2 for binomial), the same convergence test on the deviance
	 * (|dev - devold| / (0.1 + |dev|) < epsilon) and the same epsilon of 1e-8, so
	 * they stop on the same iteration and their penultimate iterates agree. For
	 * gaussian the weights are all 1 and the question does not arise: the matrix
	 * is X'X either way.
	 *
	 * final_rank and aliased[] likewise come from that same in-loop sweep. */
	NV wtdmu = has_intercept ? mean_y : (is_binomial ? 0.5 : (log_link ? 1.0 : 0.0));

	for (i = 0; i < valid_n; i++) {
		if (is_binomial) {
			if (Y[i] == 0.0)      null_dev += -2.0 * log(1.0 - wtdmu);
			else if (Y[i] == 1.0) null_dev += -2.0 * log(wtdmu);
			else null_dev += 2.0 * (Y[i] * log(Y[i] / wtdmu) + (1.0 - Y[i]) * log((1.0 - Y[i]) / (1.0 - wtdmu)));
		} else if (log_link) {
			null_dev += is_negbin ? dev_negbin(Y[i], wtdmu, theta) : dev_poisson(Y[i], wtdmu);
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
	} else if (is_poisson) {
		NV ll = 0.0;
		for (i = 0; i < valid_n; i++)
			ll += (Y[i] > 0.0 ? Y[i] * log(mu[i]) : 0.0) - mu[i] - lgamma(Y[i] + 1.0);
		aic = -2.0 * ll + 2.0 * final_rank;
	} else if (is_negbin) {
		NV ll = nb_loglik(Y, mu, valid_n, theta);
		aic = -2.0 * ll + 2.0 * final_rank + (theta_given ? 0.0 : 2.0);
	}
	res_hv = newHV(); coef_hv = newHV(); fitted_hv = newHV(); resid_hv = newHV();
	df_res = valid_n - final_rank;
	dispersion = (is_binomial || log_link) ? 1.0 : ((df_res > 0) ? (deviance_new / df_res) : NAN);
	for (size_t i = 0; i < valid_n; i++) {
		NV res = Y[i] - mu[i];
		if (is_binomial) {
			NV d_res = 0.0;
			if (Y[i] == 0.0)      d_res = sqrt(-2.0 * log(1.0 - mu[i]));
			else if (Y[i] == 1.0) d_res = sqrt(-2.0 * log(mu[i]));
			else d_res = sqrt(2.0 * (Y[i] * log(Y[i] / mu[i]) + (1.0 - Y[i]) * log((1.0 - Y[i]) / (1.0 - mu[i]))));
			res = (Y[i] > mu[i]) ? d_res : -d_res;
		} else if (log_link) {
			NV d = is_negbin ? dev_negbin(Y[i], mu[i], theta) : dev_poisson(Y[i], mu[i]);
			if (d < 0.0) d = 0.0;
			NV d_res = sqrt(d);
			res = (Y[i] >= mu[i]) ? d_res : -d_res;
		}
		hv_store(fitted_hv, valid_row_names[i], strlen(valid_row_names[i]), newSVnv(mu[i]), 0);
		hv_store(resid_hv,  valid_row_names[i], strlen(valid_row_names[i]), newSVnv(res), 0);
		Safefree(valid_row_names[i]);
	}
	Safefree(valid_row_names);
	summary_hv = newHV(); terms_av = newAV();
	/* Wald confidence intervals on the link scale (confint.default), and, for
	 * the non-gaussian families, exponentiated coefficients: odds ratios
	 * (binomial), rate/incidence-rate ratios (poisson/negbin). */
	bool use_z = is_binomial || log_link;
	NV zcrit = inverse_normal_cdf(1.0 - (1.0 - conf_level) / 2.0);
	HV *restrict conf_hv = newHV();
	HV *restrict exp_hv  = is_gaussian ? NULL : newHV();
	for (size_t j = 0; j < p; j++) {
		const char *restrict cname = design->col[j].name;
		hv_store(coef_hv, cname, strlen(cname), newSVnv(beta[j]), 0);
		av_push(terms_av, newSVpv(cname, 0));

		HV *restrict row_hv = newHV();
		if (aliased[j]) {
			hv_store(row_hv, "Estimate",   8, newSVpv("NaN", 0), 0);
			hv_store(row_hv, "Std. Error", 10, newSVpv("NaN", 0), 0);
			hv_store(row_hv, use_z ? "z value" : "t value", 7, newSVpv("NaN", 0), 0);
			hv_store(row_hv, use_z ? "Pr(>|z|)" : "Pr(>|t|)", 8, newSVpv("NaN", 0), 0);
			hv_store(row_hv, "CI.lower", 8, newSVpv("NaN", 0), 0);
			hv_store(row_hv, "CI.upper", 8, newSVpv("NaN", 0), 0);
		} else {
			NV se = sqrt(dispersion * XtWX[j * p + j]);
			NV val_stat = beta[j] / se;
			/* 2*pnorm(-|z|), not 2*(1 - pnorm(|z|)): erfc is accurate deep in
			 * the lower tail, but subtracting a near-1 value from 1 discards
			 * the answer entirely once the p-value falls below ~1e-16. R
			 * writes it the same way. get_t_pvalue() already computes its
			 * two-tail probability directly, so it needs no such care. */
			NV p_val = use_z ? 2.0 * approx_pnorm(-fabs(val_stat))
			                 : get_t_pvalue(val_stat, df_res, "two.sided");
			NV ci_lo = beta[j] - zcrit * se;
			NV ci_hi = beta[j] + zcrit * se;
			hv_store(row_hv, "Estimate",   8, newSVnv(beta[j]), 0);
			hv_store(row_hv, "Std. Error", 10, newSVnv(se), 0);
			hv_store(row_hv, use_z ? "z value" : "t value", 7, newSVnv(val_stat), 0);
			hv_store(row_hv, use_z ? "Pr(>|z|)" : "Pr(>|t|)", 8, newSVnv(p_val), 0);
			hv_store(row_hv, "CI.lower", 8, newSVnv(ci_lo), 0);
			hv_store(row_hv, "CI.upper", 8, newSVnv(ci_hi), 0);

			AV *restrict ci_av = newAV();
			av_push(ci_av, newSVnv(ci_lo)); av_push(ci_av, newSVnv(ci_hi));
			hv_store(conf_hv, cname, strlen(cname), newRV_noinc((SV*)ci_av), 0);
			if (exp_hv) {
				HV *restrict e = newHV();
				hv_store(e, "estimate",  8, newSVnv(exp(beta[j])), 0);
				hv_store(e, "conf.low",  8, newSVnv(exp(ci_lo)), 0);
				hv_store(e, "conf.high", 9, newSVnv(exp(ci_hi)), 0);
				hv_store(exp_hv, cname, strlen(cname), newRV_noinc((SV*)e), 0);
			}
		}
		hv_store(summary_hv, cname, strlen(cname), newRV_noinc((SV*)row_hv), 0);
	}
	hv_store(res_hv, "aic",            3, newSVnv(aic), 0);
	hv_store(res_hv, "coefficients",  12, newRV_noinc((SV*)coef_hv), 0);
	hv_store(res_hv, "conf.int",       8, newRV_noinc((SV*)conf_hv), 0);
	hv_store(res_hv, "conf.level",    10, newSVnv(conf_level), 0);
	if (exp_hv) hv_store(res_hv, "exp", 3, newRV_noinc((SV*)exp_hv), 0);
	if (is_negbin) hv_store(res_hv, "theta", 5, newSVnv(theta), 0);
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
	hv_store(res_hv, "xlevels",       7, newRV_inc((SV*)xlevels_hv), 0);
	for (i = 0; i < num_terms; i++) Safefree(terms[i]);
	Safefree(terms);
	for (i = 0; i < num_uniq; i++) Safefree(uniq_terms[i]);
	Safefree(uniq_terms);
	lm_design_free(aTHX_ design);
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
	  /* guard divide-by-zero when |estimate| == 1 exactly.
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
	  // use long to avoid int overflow for large n
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
	  estimate = (denom == 0.0) ? NAN : (NV)(c - d) / denom;
	  bool has_ties = (tie_x > 0 || tie_y > 0);
	  bool do_exact;
	  // Mirror R: exact defaults to TRUE if n < 50 and no ties
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

		  /* Tails evaluated where they lie: approx_pnorm is erfc-based and so
		   * is accurate deep into its lower tail, but subtracting a near-1
		   * value from 1 discards the answer below ~1e-16. pnorm(-x) is the
		   * upper tail exactly, by symmetry, at no cost. */
		  if      (strcmp(alternative, "two.sided") == 0)
			  p_value = 2.0 * approx_pnorm(-fabs(statistic));
		  else if (strcmp(alternative, "less") == 0)
			  p_value = approx_pnorm(statistic);
		  else
			  p_value = approx_pnorm(-statistic);
	  }

	} else if (is_spearman) {
	  NV *restrict rank_x = safemalloc(n * sizeof(NV));
	  NV *restrict rank_y = safemalloc(n * sizeof(NV));
	  rank_data(x, rank_x, n);
	  rank_data(y, rank_y, n);
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
		  NV denom_t = 1.0 - r * r;
		  if (denom_t <= 0.0)
			  statistic = (r > 0.0) ? INFINITY : -INFINITY;
		  else
			  statistic = r * sqrt((NV)(n - 2) / denom_t);
		  p_value = get_t_pvalue(statistic, (NV)(n - 2), alternative);
	  }
	  Safefree(rank_x);	  Safefree(rank_y);
	} else {
	  Safefree(x);	  Safefree(y);
	  croak("Unknown method '%s': must be 'pearson', 'kendall', or 'spearman'", method);
	}
	Safefree(x);	Safefree(y);
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
	for (size_t i = 0; i < n; i++) {// Calculate Sum of Squares
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
		* do NOT shadow it with a local 'double p_val' here or the result will never reach the caller.*/
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
				// Upper-tail probability P(Z > z): small W → large z → small
				// p-value. pnorm(-z) is that tail exactly, by symmetry.
				p_val = approx_pnorm(-z);
			}
		} else {
			// Royston's branch for n >= 12 (AS R94, large-sample path)
			NV ln_n   = log((NV)n);
			// Horner-form polynomials in log(n) for mu and log(sigma). */
			NV mu     = -1.5861 + ln_n * (-0.31082 + ln_n * (-0.083751 + ln_n * 0.0038915));
			NV sig_val= -0.4803 + ln_n * (-0.082676 + ln_n * 0.0030302);
			NV sigma  = exp(sig_val);
			z = (y - mu) / sigma;
			p_val = approx_pnorm(-z);
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
						 croak("min: undefined value at array ref index %" UVuf " (argument %d)", (UV)j, (int)i);
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
					   croak("max: undefined value at array ref index %" UVuf " (argument %" UVuf ")", (UV)j, (UV)i);
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
			   croak("max: undefined value at argument index %" UVuf, (UV)i);
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
		qsort(x, n, sizeof(NV), cmp_nv3); 
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
				SSize_t len = av_len(av) + 1;
				for (SSize_t j = 0; j < len; j++) {
					SV** restrict tv = av_fetch(av, j, 0);
					if (tv && SvOK(*tv)) {
						total += SvNV(*tv);
						count++;
					} else {
						croak("mean: undefined value at array ref index %" UVuf " (argument %" UVuf ")", (UV)j, (UV)i);
					}
				}
			} else if (SvOK(arg)) {
				total += SvNV(arg);
				count++;
			} else {
				croak("mean: undefined value at argument index %" UVuf, (UV)i);
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
			SSize_t len = av_len(av) + 1;
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
					croak("mode: undefined value at array ref index %" UVuf " (argument %" UVuf ")", (UV)j, (UV)i);
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
			croak("mode: undefined value at argument index %" UVuf, (UV)i);
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
				 SSize_t len = av_len(av) + 1;
				 for (size_t j = 0; j < len; j++) {
					 SV** restrict tv = av_fetch(av, j, 0);
					 if (tv && SvOK(*tv)) {
						 total += SvNV(*tv);
						 count++;
					 } else {
						 croak("sum: undefined value at array ref index %" UVuf " (argument %" UVuf ")", (UV)j, (UV)i);
					 }
				 }
			} else if (SvOK(arg)) {
				 total += SvNV(arg);
				 count++;
			} else {
				 croak("sum: undefined value at argument index %" UVuf, (UV)i);
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
		for (size_t i = 0; i < items; i++) { // Single Pass Standard Deviation via Welford's Algorithm
			SV* restrict arg = ST(i);
			if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) {
				AV* restrict av = (AV*)SvRV(arg);
				SSize_t len = av_len(av) + 1;
				for (size_t j = 0; j < len; j++) {
				  SV** restrict tv = av_fetch(av, j, 0);
				  if (tv && SvOK(*tv)) {
						count++;
						NV val = SvNV(*tv);
						NV delta = val - mean;
						mean += delta / count;
						M2 += delta * (val - mean);
				  } else {
						croak("sd: undefined value at array ref index %" UVuf " (argument %" UVuf ")", (UV)j, (UV)i);
				  }
				}
			} else if (SvOK(arg)) {
				 count++;
				 NV val = SvNV(arg);
				 NV delta = val - mean;
				 mean += delta / count;
				 M2 += delta * (val - mean);
			} else {
				 croak("sd: undefined value at argument index %" UVuf, (UV)i);
			}
		}
		if (count < 2) croak("sd needs >= 2 elements");
		RETVAL = sqrt(M2 / (count - 1));
	OUTPUT:
	  RETVAL

void uniq(...)
	PROTOTYPE: @
	PREINIT:
		HV*restrict seen;
		AV*restrict out;
		size_t n, k;
		int gimme;
	PPCODE:
		n = 0;
		gimme = GIMME_V;
		seen = (HV*)sv_2mortal((SV*)newHV());
		out  = (AV*)sv_2mortal((SV*)newAV());
		for (size_t i = 0; i < items; i++) {
			SV* restrict arg = ST(i);
			if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) {
				AV* restrict av = (AV*)SvRV(arg);
				size_t len = av_len(av) + 1;
				for (size_t j = 0; j < len; j++) {
					SV** restrict tv = av_fetch(av, j, 0);
					if (tv && SvOK(*tv)) {
						STRLEN klen;
						const char*restrict key = SvPV(*tv, klen);
						I32 hklen = SvUTF8(*tv) ? -(I32)klen : (I32)klen;
						if (!hv_exists(seen, key, hklen)) {
							(void)hv_store(seen, key, hklen, &PL_sv_undef, 0);
							if (gimme != G_SCALAR)
								av_push(out, newSVsv(*tv));
							n++;
						}
					} else {
						croak("uniq: undefined value at array ref index %" UVuf " (argument %" UVuf ")", (UV)j, (UV)i);
					}
				}
			} else if (SvOK(arg)) {
				STRLEN klen;
				const char*restrict key = SvPV(arg, klen);
				I32 hklen = SvUTF8(arg) ? -(I32)klen : (I32)klen;
				if (!hv_exists(seen, key, hklen)) {
					(void)hv_store(seen, key, hklen, &PL_sv_undef, 0);
					if (gimme != G_SCALAR)
						av_push(out, newSVsv(arg));
					n++;
				}
			} else {
				croak("uniq: undefined value at argument index %" UVuf, (UV)i);
			}
		}
		if (gimme == G_SCALAR) {
			XPUSHs(sv_2mortal(newSVuv(n)));
		} else {
			size_t outlen = av_len(out) + 1;
			EXTEND(SP, (SSize_t)outlen);
			for (k = 0; k < outlen; k++)
				PUSHs(sv_2mortal(av_shift(out)));
		}

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
						   croak("var: undefined value at array ref index %" UVuf " (argument %" UVuf ")", (UV)j, (UV)i);
					  }
				 }
			} else if (SvOK(arg)) {
				 count++;
				 NV val = SvNV(arg);
				 NV delta = val - mean;
				 mean += delta / count;
				 M2 += delta * (val - mean);
			} else {
				 croak("var: undefined value at argument index %" UVuf, (UV)i);
			}
		}
		if (count < 2) croak("var needs >= 2 elements");
		RETVAL = M2 / (count - 1);
	OUTPUT:
		RETVAL

NV skew(...)
	PROTOTYPE: @
	INIT:
	  moment_acc acc = { 0.0, 0.0, 0.0, 0.0, 0 };
	  IV type = 2;
	CODE:
		/* Sample skewness.  type 2 (the default) is G1, the estimator SAS,
		 * SPSS, Stata, Excel's SKEW() and scipy's bias=FALSE all report;
		 * type 1 is the plain moment ratio g1 (moments::skewness) and type 3
		 * is b1 (e1071::skewness's own default). */
		moment_args(aTHX_ &ST(0), (size_t)items, "skew", &acc, &type);
		if (acc.n < 2) croak("skew needs >= 2 elements");
		if (type == 2 && acc.n < 3) croak("skew: type 2 needs >= 3 elements");
		{
			const NV n  = (NV)acc.n;
			const NV m2 = acc.m2 / n;
			if (!(m2 > 0.0))
				croak("skew: zero variance (all %" UVuf " values are equal), "
				      "so skewness is undefined", (UV)acc.n);
			const NV g1 = (acc.m3 / n) / pow(m2, 1.5);
			RETVAL = type == 1 ? g1
			       : type == 2 ? g1 * sqrt(n * (n - 1.0)) / (n - 2.0)
			       :             g1 * pow((n - 1.0) / n, 1.5);
		}
	OUTPUT:
		RETVAL

NV kurtosis(...)
	PROTOTYPE: @
	INIT:
	  moment_acc acc = { 0.0, 0.0, 0.0, 0.0, 0 };
	  IV type = 2;
	CODE:
/* Excess kurtosis: 3 is already subtracted, so a normal sample sits
  near 0 rather than near 3.  type 2 (the default) is G2, as in SAS,
  SPSS, Stata, Excel's KURT() and scipy's bias=FALSE; type 1 is g2
  (moments::kurtosis minus 3) and type 3 is b2 (e1071::kurtosis's
  own default). */
		moment_args(aTHX_ &ST(0), (size_t)items, "kurtosis", &acc, &type);
		if (acc.n < 2) croak("kurtosis needs >= 2 elements");
		if (type == 2 && acc.n < 4) croak("kurtosis: type 2 needs >= 4 elements");
		{
			const NV n  = (NV)acc.n;
			const NV m2 = acc.m2 / n;
			if (!(m2 > 0.0))
				croak("kurtosis: zero variance (all %" UVuf " values are "
				      "equal), so kurtosis is undefined", (UV)acc.n);
			const NV r  = (acc.m4 / n) / (m2 * m2);   /* 4th standardised moment */
			RETVAL = type == 1 ? r - 3.0
			       : type == 2 ? ((n + 1.0) * (r - 3.0) + 6.0) * (n - 1.0)
			                     / ((n - 2.0) * (n - 3.0))
			       :             r * pow(1.0 - 1.0 / n, 2.0) - 3.0;
		}
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
		/* 'y' may be absent or an explicit undef -- R's default is y = NULL --
		 * but a defined non-array 'y' is a mistake worth refusing: dropping it
		 * silently runs a one-sample test on data meant for a comparison. */
		AV*restrict y_av = NULL;
		if (y_sv && SvOK(y_sv)) {
			if (!SvROK(y_sv) || SvTYPE(SvRV(y_sv)) != SVt_PVAV)
				croak("t_test: 'y' must be an ARRAY reference");
			y_av = (AV*)SvRV(y_sv);
		}
		/* R's match.arg(): an unrecognised alternative is an error there, where
		 * falling through to a two-sided test would answer a question nobody
		 * asked. scipy's "two-sided" spelling is unambiguous, so take it too. */
		if (strEQ(alternative, "two-sided") || strEQ(alternative, "two_sided"))
			alternative = "two.sided";
		if (strNE(alternative, "two.sided") && strNE(alternative, "less")
		    && strNE(alternative, "greater"))
			croak("t_test: 'alternative' must be 'two.sided', 'less' or 'greater', "
			      "not '%s'", alternative);
		if (conf_level <= 0.0 || conf_level >= 1.0)
			croak("t_test: 'conf_level' must be between 0 and 1");
		if (paired && !y_av)
			croak("t_test: 'y' must be provided for paired or two-sample tests");

		/* --- Computation via Welford's Algorithm --- */
		NV mean_x = 0.0, var_x = NAN, mean_y = 0.0, var_y = NAN;
		NV t_stat, df, p_val, std_err, cint_est, constant_scale;
		/* which estimate keys the result carries; set with the branch below so
		 * the hash is only built once every croak is behind us */
		enum { EST_MEAN_X, EST_MEAN_DIFF, EST_BOTH } estimates = EST_MEAN_X;

		if (paired) {
			/* R uses complete.cases(x, y): a pair goes whole if either side is
			 * NA, so the differences stay paired. Lengths are compared before
			 * any filtering, as complete.cases() refuses unequal ones. */
			const size_t nx_raw = (size_t)(av_len(x_av) + 1);
			const size_t ny_raw = (size_t)(av_len(y_av) + 1);
			if (nx_raw != ny_raw) croak("t_test: Paired arrays must be same length");
			SV**restrict x_a = AvARRAY(x_av);
			SV**restrict y_a = AvARRAY(y_av);
			size_t n = 0;
			NV mean_d = 0.0, M2_d = 0.0;
			for (size_t i = 0; x_a && y_a && i < nx_raw; i++) {
				SV *restrict xe = x_a[i], *restrict ye = y_a[i];
				if (!xe || !SvOK(xe) || !ye || !SvOK(ye)) continue;
				const NV dx = SvNV(xe), dy = SvNV(ye);
				if (dx != dx || dy != dy) continue;
				const NV val = dx - dy;
				n++;
				const NV delta = val - mean_d;
				mean_d += delta / (NV)n;
				M2_d   += delta * (val - mean_d);
			}
			if (n < 2) croak("t_test: not enough complete pairs; need at least 2");
			const NV var_d = M2_d / (NV)(n - 1);
			cint_est       = mean_d;
			std_err        = sqrt(var_d / (NV)n);
			df             = (NV)n - 1.0;
			constant_scale = fabs(mean_d);
			estimates      = EST_MEAN_DIFF;
		} else if (y_av) {
			const size_t nx = t_test_scan(aTHX_ x_av, &mean_x, &var_x);
			const size_t ny = t_test_scan(aTHX_ y_av, &mean_y, &var_y);
			/* R's thresholds: a pooled variance can carry a group of one, since
			 * that group contributes no sum of squares, but a Welch test needs a
			 * variance from each side. Both were missing here, so an n = 1 'y'
			 * divided by (ny - 1) == 0 and returned NaN throughout. */
			if (nx < 1 || (!var_equal && nx < 2))
				croak("t_test: not enough 'x' observations");
			if (ny < 1 || (!var_equal && ny < 2))
				croak("t_test: not enough 'y' observations");
			if (var_equal && nx + ny < 3)
				croak("t_test: not enough observations");
			cint_est       = mean_x - mean_y;
			constant_scale = fmax(fabs(mean_x), fabs(mean_y));
			estimates      = EST_BOTH;
			if (var_equal) {
				df = (NV)nx + (NV)ny - 2.0;
				NV pooled_var = 0.0;
				if (nx > 1) pooled_var += ((NV)nx - 1.0) * var_x;
				if (ny > 1) pooled_var += ((NV)ny - 1.0) * var_y;
				pooled_var /= df;
				std_err = sqrt(pooled_var * (1.0 / (NV)nx + 1.0 / (NV)ny));
			} else {
				const NV stderr_x2 = var_x / (NV)nx;
				const NV stderr_y2 = var_y / (NV)ny;
				std_err = sqrt(stderr_x2 + stderr_y2);
				df = pow(stderr_x2 + stderr_y2, 2) /
				     (pow(stderr_x2, 2) / ((NV)nx - 1.0) + pow(stderr_y2, 2) / ((NV)ny - 1.0));
			}
		} else {
			const size_t nx = t_test_scan(aTHX_ x_av, &mean_x, &var_x);
			if (nx < 2) croak("t_test: 'x' needs at least 2 elements");
			cint_est       = mean_x;
			std_err        = sqrt(var_x / (NV)nx);
			df             = (NV)nx - 1.0;
			constant_scale = fabs(mean_x);
		}
		/* R stops once the standard error has sunk into the rounding noise of
		 * the data's own magnitude, not only when the variance is exactly zero.
		 * An absolute test lets through a sample whose spread a double cannot
		 * resolve at that scale and reports the noise as an enormous t: four
		 * values around 1e10 differing by 1e-5 gave t = 4e15, p = 3e-47. The
		 * exactly-zero case is R's NaN, croaked rather than returned. */
		if (std_err == 0.0
		    || (isfinite(std_err) && std_err < 10.0 * DBL_EPSILON * constant_scale))
			croak("t_test: data are essentially constant");
		t_stat = (cint_est - mu) / std_err;
		p_val  = get_t_pvalue(t_stat, df, alternative);
		HV*restrict results = newHV();
		switch (estimates) {
			case EST_MEAN_DIFF:
				hv_store(results, "estimate", 8, newSVnv(cint_est), 0);
				break;
			case EST_BOTH:
				hv_store(results, "estimate_x", 10, newSVnv(mean_x), 0);
				hv_store(results, "estimate_y", 10, newSVnv(mean_y), 0);
				break;
			default:
				hv_store(results, "estimate", 8, newSVnv(mean_x), 0);
		}
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

void prop_test(...)
PPCODE:
{
	/* Test of equality of proportions / a single proportion against a target.
	 * Faithful port of R's stats::prop.test (Pearson chi-square on the 2xk
	 * table of successes/failures, Yates correction for k<=2, Wilson score CI
	 * for one proportion and a Wald CI for a difference of two). */
	if (items < 2)
		croak("Usage: prop_test(\\@successes, \\@trials, p => ..., "
		      "alternative => 'two.sided', conf.level => 0.95, correct => 1)\n"
		      "   or prop_test($x, $n, ...) for a single sample");
	const char *restrict alt = "two.sided";
	NV conf_level = 0.95;
	bool correct = 1;
	SV *restrict p_sv = NULL;
	for (int i = 2; i + 1 < items; i += 2) {
		const char *restrict key = SvPV_nolen(ST(i)); SV *v = ST(i + 1);
		if      (strEQ(key, "p"))            p_sv = v;
		else if (strEQ(key, "alternative"))  alt = SvPV_nolen(v);
		else if (strEQ(key, "conf_level") || strEQ(key, "conf.level")) conf_level = SvNV(v);
		else if (strEQ(key, "correct"))      correct = SvTRUE(v) ? 1 : 0;
		else croak("prop_test: unknown argument '%s'", key);
	}
	if (!(conf_level > 0.0 && conf_level < 1.0))
		croak("prop_test: conf.level must be between 0 and 1");
	if (strNE(alt, "two.sided") && strNE(alt, "less") && strNE(alt, "greater"))
		croak("prop_test: alternative must be 'two.sided', 'less' or 'greater'");

	/* --- read x (successes) and n (trials): each a scalar or an array ref --- */
	NV *restrict x = NULL, *restrict nn = NULL, *restrict pnull = NULL;
	size_t k = 0;
	{
		SV *restrict xsv = ST(0), *restrict nsv = ST(1);
		if (SvROK(xsv) && SvTYPE(SvRV(xsv)) == SVt_PVAV) {
			AV *av = (AV*)SvRV(xsv); k = (size_t)(av_len(av) + 1);
			if (k == 0) croak("prop_test: 'x' is empty");
			Newx(x, k, NV);
			for (size_t i = 0; i < k; i++) { SV **e = av_fetch(av, i, 0); x[i] = (e && *e) ? SvNV(*e) : NAN; }
		} else { k = 1; Newx(x, 1, NV); x[0] = SvNV(xsv); }
		size_t kn;
		if (SvROK(nsv) && SvTYPE(SvRV(nsv)) == SVt_PVAV) {
			AV *restrict av = (AV*)SvRV(nsv); kn = (size_t)(av_len(av) + 1);
			Newx(nn, kn, NV);
			for (size_t i = 0; i < kn; i++) { SV **e = av_fetch(av, i, 0); nn[i] = (e && *e) ? SvNV(*e) : NAN; }
		} else { kn = 1; Newx(nn, 1, NV); nn[0] = SvNV(nsv); }
		if (kn != k) { Safefree(x); Safefree(nn); croak("prop_test: 'x' and 'n' must have the same length"); }
	}
	for (size_t i = 0; i < k; i++) {
		if (nn[i] <= 0)          { Safefree(x); Safefree(nn); croak("prop_test: elements of 'n' must be positive"); }
		if (x[i] < 0)            { Safefree(x); Safefree(nn); croak("prop_test: elements of 'x' must be nonnegative"); }
		if (x[i] > nn[i])        { Safefree(x); Safefree(nn); croak("prop_test: elements of 'x' must not exceed 'n'"); }
	}

	/* --- null probabilities and degrees of freedom --- */
	bool p_is_null;   /* true => testing equality (pooled p, df = k-1) */
	Newx(pnull, k, NV);
	if (p_sv && SvOK(p_sv)) {
		p_is_null = FALSE;
		if (SvROK(p_sv) && SvTYPE(SvRV(p_sv)) == SVt_PVAV) {
			AV *restrict av = (AV*)SvRV(p_sv);
			if ((size_t)(av_len(av) + 1) != k) { Safefree(x); Safefree(nn); Safefree(pnull); croak("prop_test: 'p' must have the same length as 'x'"); }
			for (size_t i = 0; i < k; i++) { SV **e = av_fetch(av, i, 0); pnull[i] = (e && *e) ? SvNV(*e) : NAN; }
		} else { NV pv = SvNV(p_sv); for (size_t i = 0; i < k; i++) pnull[i] = pv; }
		for (size_t i = 0; i < k; i++)
			if (!(pnull[i] > 0.0 && pnull[i] < 1.0)) { Safefree(x); Safefree(nn); Safefree(pnull); croak("prop_test: elements of 'p' must be in (0,1)"); }
	} else if (k == 1) {
		p_is_null = FALSE; pnull[0] = 0.5;   /* one-sample default target */
	} else {
		p_is_null = TRUE;
		NV sx = 0.0, sn = 0.0;
		for (size_t i = 0; i < k; i++) { sx += x[i]; sn += nn[i]; }
		NV pooled = sx / sn;
		for (size_t i = 0; i < k; i++) pnull[i] = pooled;
	}
	/* R forces a two-sided test whenever a one-sided one is not meaningful:
	 * more than two groups, or exactly two groups tested against given p. */
	bool p_given = (p_sv && SvOK(p_sv));
	if (k > 2 || (k == 2 && p_given)) alt = "two.sided";

	NV YATES = (correct && k <= 2) ? 0.5 : 0.0;

	// estimates
	NV *restrict est = NULL; Newx(est, k, NV);
	for (size_t i = 0; i < k; i++) est[i] = x[i] / nn[i];

	NV ci_lo = NAN, ci_hi = NAN; bool have_ci = FALSE;
	NV delta = 0.0;
	if (k == 1) {
		NV cap = fabs(x[0] - nn[0] * pnull[0]);
		if (cap < YATES) YATES = cap;
		NV z  = inverse_normal_cdf(strEQ(alt, "two.sided") ? (1.0 + conf_level) / 2.0 : conf_level);
		NV z22n = z * z / (2.0 * nn[0]);
		NV pcu = est[0] + YATES / nn[0];
		NV p_u = (pcu >= 1.0) ? 1.0 : (pcu + z22n + z * sqrt(pcu * (1.0 - pcu) / nn[0] + z22n / (2.0 * nn[0]))) / (1.0 + 2.0 * z22n);
		NV pcl = est[0] - YATES / nn[0];
		NV p_l = (pcl <= 0.0) ? 0.0 : (pcl + z22n - z * sqrt(pcl * (1.0 - pcl) / nn[0] + z22n / (2.0 * nn[0]))) / (1.0 + 2.0 * z22n);
		if      (strEQ(alt, "two.sided")) { ci_lo = p_l < 0.0 ? 0.0 : p_l; ci_hi = p_u > 1.0 ? 1.0 : p_u; }
		else if (strEQ(alt, "greater"))   { ci_lo = p_l < 0.0 ? 0.0 : p_l; ci_hi = 1.0; }
		else                              { ci_lo = 0.0; ci_hi = p_u > 1.0 ? 1.0 : p_u; }
		have_ci = TRUE;
	} else if (k == 2 && p_is_null) {
		delta = est[0] - est[1];
		NV inv_sum = 1.0 / nn[0] + 1.0 / nn[1];
		NV cap = fabs(delta) / inv_sum;
		if (cap < YATES) YATES = cap;
		NV z = inverse_normal_cdf(strEQ(alt, "two.sided") ? (1.0 + conf_level) / 2.0 : conf_level);
		NV width = z * sqrt(est[0] * (1.0 - est[0]) / nn[0] + est[1] * (1.0 - est[1]) / nn[1]) + YATES * inv_sum;
		if      (strEQ(alt, "two.sided")) { ci_lo = (delta - width < -1.0) ? -1.0 : delta - width; ci_hi = (delta + width > 1.0) ? 1.0 : delta + width; }
		else if (strEQ(alt, "greater"))   { ci_lo = (delta - width < -1.0) ? -1.0 : delta - width; ci_hi = 1.0; }
		else                              { ci_lo = -1.0; ci_hi = (delta + width > 1.0) ? 1.0 : delta + width; }
		have_ci = TRUE;
	}

	int df = p_is_null ? (int)(k - 1) : (int)k;

	/* --- Pearson chi-square with (capped) Yates correction --- */
	NV stat = 0.0;
	for (size_t i = 0; i < k; i++) {
		NV E0 = nn[i] * pnull[i], E1 = nn[i] * (1.0 - pnull[i]);
		NV o0 = x[i], o1 = nn[i] - x[i];
		NV d0 = fabs(o0 - E0) - YATES;   /* R does not floor this at 0 */
		NV d1 = fabs(o1 - E1) - YATES;
		stat += d0 * d0 / E0 + d1 * d1 / E1;
	}

	NV p_value;
	if (strEQ(alt, "two.sided")) {
		p_value = get_p_value(stat, df);
	} else {
		NV z = (k == 1) ? ((est[0] > pnull[0]) - (est[0] < pnull[0])) * sqrt(stat)
		                : ((delta > 0.0) - (delta < 0.0)) * sqrt(stat);
		p_value = strEQ(alt, "less") ? approx_pnorm(z) : 1.0 - approx_pnorm(z);
	}

	// Chi-square approximation warning, as in R
	for (size_t i = 0; i < k; i++)
		if (nn[i] * pnull[i] < 5.0 || nn[i] * (1.0 - pnull[i]) < 5.0) {
			warn("prop_test: Chi-squared approximation may be incorrect");
			break;
		}

	HV *restrict ret = newHV();
	hv_stores(ret, "statistic",   newSVnv(stat));
	hv_stores(ret, "parameter",   newSViv(df));
	hv_stores(ret, "p_value",     newSVnv(p_value));
	hv_stores(ret, "alternative", newSVpv(alt, 0));
	hv_stores(ret, "conf_level",  newSVnv(conf_level));
	{
		char method[96];
		if (k == 1) snprintf(method, sizeof method, "1-sample proportions test %s continuity correction", YATES > 0.0 ? "with" : "without");
		else snprintf(method, sizeof method, "%zu-sample test for %s proportions %s continuity correction",
			k, p_is_null ? "equality of" : "given", YATES > 0.0 ? "with" : "without");
		hv_stores(ret, "method", newSVpv(method, 0));
	}
	{
		AV *restrict ev = newAV();
		for (size_t i = 0; i < k; i++) av_push(ev, newSVnv(est[i]));
		hv_stores(ret, "estimate", newRV_noinc((SV*)ev));
	}
	if (have_ci) {
		AV *restrict ci = newAV(); av_push(ci, newSVnv(ci_lo)); av_push(ci, newSVnv(ci_hi));
		hv_stores(ret, "conf.int", newRV_noinc((SV*)ci));
	}
	Safefree(x); Safefree(nn); Safefree(pnull); Safefree(est);
	ST(0) = sv_2mortal(newRV_noinc((SV *)ret));
	XSRETURN(1);
}

void mcnemar_test(...)
PPCODE:
{
/* McNemar's test for paired categorical data.  Faithful port of R's
  stats::mcnemar.test (chi-square on the off-diagonal disagreement,
  with Yates continuity correction for a 2x2 table).  An `exact => 1`
  option gives the two-sided exact binomial test for a 2x2 table. */
	if (items < 1)
		croak("Usage: mcnemar_test([[a,b],[c,d]], correct => 1, exact => 0)\n"
		      "   or mcnemar_test(\\@x, \\@y, ...)   # paired observations");
	int correct = 1, exact = 0, opt_start;
	size_t r = 0;
	NV *restrict tab = NULL;

	bool is_matrix = FALSE;
	if (SvROK(ST(0)) && SvTYPE(SvRV(ST(0))) == SVt_PVAV
		&& av_len((AV*)SvRV(ST(0))) >= 0) {
		SV **restrict e0 = av_fetch((AV*)SvRV(ST(0)), 0, 0);
		is_matrix = e0 && *e0 && SvROK(*e0) && SvTYPE(SvRV(*e0)) == SVt_PVAV;
	}

	if (is_matrix) {
		AV *restrict m = (AV*)SvRV(ST(0));
		r = (size_t)(av_len(m) + 1);
		if (r < 2) croak("mcnemar_test: matrix must have at least two rows");
		Newxz(tab, r * r, NV);
		for (size_t i = 0; i < r; i++) {
			SV **restrict row = av_fetch(m, i, 0);
			if (!row || !*row || !SvROK(*row) || SvTYPE(SvRV(*row)) != SVt_PVAV)
				{ Safefree(tab); croak("mcnemar_test: row %" UVuf " is not an array ref", (UV)i); }
			AV *rv = (AV*)SvRV(*row);
			if ((size_t)(av_len(rv) + 1) != r) { Safefree(tab); croak("mcnemar_test: matrix must be square"); }
			for (size_t j = 0; j < r; j++) {
				SV **restrict c = av_fetch(rv, j, 0);
				NV v = (c && *c) ? SvNV(*c) : 0.0;
				if (v < 0 || isnan(v)) { Safefree(tab); croak("mcnemar_test: entries must be nonnegative and finite"); }
				tab[i * r + j] = v;
			}
		}
		opt_start = 1;
	} else {
		if (items < 2 || !SvROK(ST(0)) || !SvROK(ST(1))
			|| SvTYPE(SvRV(ST(0))) != SVt_PVAV || SvTYPE(SvRV(ST(1))) != SVt_PVAV)
			croak("mcnemar_test: expected a square matrix or two array refs");
		AV *restrict xa = (AV*)SvRV(ST(0)), *ya = (AV*)SvRV(ST(1));
		size_t n = (size_t)(av_len(xa) + 1);
		if ((size_t)(av_len(ya) + 1) != n) croak("mcnemar_test: 'x' and 'y' must have the same length");
		/* collect sorted unique levels across both vectors */
		char **restrict lev = NULL; size_t nlev = 0, cap = 8; Newx(lev, cap, char*);
		for (size_t src = 0; src < 2; src++) {
			AV *a = src ? ya : xa;
			for (size_t i = 0; i < n; i++) {
				SV **e = av_fetch(a, i, 0);
				if (!e || !*e || !SvOK(*e)) continue;
				STRLEN l; const char *s = SvPV(*e, l);
				bool found = FALSE;
				for (size_t k = 0; k < nlev; k++) if (strEQ(lev[k], s)) { found = TRUE; break; }
				if (!found) { if (nlev >= cap) { cap *= 2; Renew(lev, cap, char*); } lev[nlev++] = savepvn(s, l); }
			}
		}
		/* sort levels lexically for a deterministic table order */
		for (size_t a = 0; a + 1 < nlev; a++) for (size_t b = a + 1; b < nlev; b++)
			if (strcmp(lev[a], lev[b]) > 0) { char *t = lev[a]; lev[a] = lev[b]; lev[b] = t; }
		r = nlev;
		if (r < 2) { for (size_t k = 0; k < nlev; k++) Safefree(lev[k]); Safefree(lev); croak("mcnemar_test: need at least two levels"); }
		Newxz(tab, r * r, NV);
		for (size_t i = 0; i < n; i++) {
			SV **ex = av_fetch(xa, i, 0), **ey = av_fetch(ya, i, 0);
			if (!ex || !*ex || !SvOK(*ex) || !ey || !*ey || !SvOK(*ey)) continue;
			STRLEN lx, ly; const char *sx = SvPV(*ex, lx), *sy = SvPV(*ey, ly);
			size_t ix = 0, iy = 0;
			for (size_t k = 0; k < r; k++) { if (strEQ(lev[k], sx)) ix = k; if (strEQ(lev[k], sy)) iy = k; }
			tab[ix * r + iy] += 1.0;
		}
		for (size_t k = 0; k < nlev; k++) Safefree(lev[k]);
		Safefree(lev);
		opt_start = 2;
	}
	for (int i = opt_start; i + 1 < items; i += 2) {
		const char *restrict k = SvPV_nolen(ST(i)); SV *v = ST(i + 1);
		if      (strEQ(k, "correct")) correct = SvTRUE(v) ? 1 : 0;
		else if (strEQ(k, "exact"))   exact   = SvTRUE(v) ? 1 : 0;
		else { Safefree(tab); croak("mcnemar_test: unknown argument '%s'", k); }
	}
	if (exact && r != 2) { Safefree(tab); croak("mcnemar_test: exact test requires a 2x2 table"); }

	HV *restrict ret = newHV();
	if (exact) {// two-sided exact binomial test of the discordant pairs, b ~ Bin(b+c, 0.5)
		NV b = tab[0 * 2 + 1], c = tab[1 * 2 + 0];
		NV nn = b + c, m = (b < c) ? b : c;
		NV p_value;
		if (nn == 0.0) p_value = 1.0;
		else {
			NV s = 0.0, lognn2 = nn * log(2.0);
			for (NV kk = 0.0; kk <= m; kk += 1.0) s += exp(ft_lchoose((long)nn, (long)kk) - lognn2);
			p_value = 2.0 * s; if (p_value > 1.0) p_value = 1.0;
		}
		hv_stores(ret, "statistic",   newSVnv(b));
		hv_stores(ret, "p_value",     newSVnv(p_value));
		hv_stores(ret, "method",      newSVpv("McNemar's test (exact binomial)", 0));
	} else {
		bool use_cc = 0;
		if (correct && r == 2) {
			for (size_t i = 0; i < r && !use_cc; i++)
				for (size_t j = 0; j < r; j++)
					if (tab[i * r + j] != tab[j * r + i]) { use_cc = 1; break; }
		}
		NV stat = 0.0;
		for (size_t i = 0; i < r; i++)
			for (size_t j = i + 1; j < r; j++) {
				NV diff = tab[i * r + j] - tab[j * r + i];
				NV sum  = tab[i * r + j] + tab[j * r + i];
				if (sum <= 0.0) continue;
				NV num = use_cc ? (fabs(diff) - 1.0) : diff;
				stat += num * num / sum;
			}
		int df = (int)(r * (r - 1) / 2);
		NV p_value = get_p_value(stat, df);
		hv_stores(ret, "statistic", newSVnv(stat));
		hv_stores(ret, "parameter", newSViv(df));
		hv_stores(ret, "p_value",   newSVnv(p_value));
		hv_stores(ret, "method",    newSVpv(use_cc ?
			"McNemar's Chi-squared test with continuity correction" :
			"McNemar's Chi-squared test", 0));
	}
	Safefree(tab);
	ST(0) = sv_2mortal(newRV_noinc((SV *)ret));
	XSRETURN(1);
}

void dunn_test(...)
PPCODE:
{
	/* Dunn's (1964) post-hoc test following a Kruskal-Wallis test: pairwise
	 * rank-mean comparisons using the shared ranking and tie correction, with
	 * a family-wise / FDR adjustment.  Two-sided p-values (as in FSA::dunnTest).
	 * Validated against the canonical formula implemented in base R. */
	if (items < 2 || !SvROK(ST(0)) || !SvROK(ST(1))
		|| SvTYPE(SvRV(ST(0))) != SVt_PVAV || SvTYPE(SvRV(ST(1))) != SVt_PVAV)
		croak("Usage: dunn_test(\\@values, \\@groups, method => 'holm')");
	const char *restrict method = "holm";
	for (int i = 2; i + 1 < items; i += 2) {
		const char *key = SvPV_nolen(ST(i)); SV *v = ST(i + 1);
		if (strEQ(key, "method")) method = SvPV_nolen(v);
		else croak("dunn_test: unknown argument '%s'", key);
	}
	char meth[32]; strncpy(meth, method, 31); meth[31] = '\0';
	for (unsigned i = 0; meth[i]; i++) meth[i] = tolower(meth[i]);
	if (strEQ(meth, "fdr")) strcpy(meth, "bh");
	if (strEQ(meth, "holm-sidak")) strcpy(meth, "hs");

	AV *restrict xa = (AV*)SvRV(ST(0)), *ga = (AV*)SvRV(ST(1));
	size_t raw = (size_t)(av_len(xa) + 1);
	if ((size_t)(av_len(ga) + 1) != raw) croak("dunn_test: values and groups must have the same length");

	/* gather complete (value, group) pairs */
	NV *restrict x = NULL; char **restrict glab = NULL;
	Newx(x, raw, NV); Newx(glab, raw, char*);
	size_t N = 0;
	for (size_t i = 0; i < raw; i++) {
		SV **xv = av_fetch(xa, i, 0), **gv = av_fetch(ga, i, 0);
		if (!xv || !*xv || !SvOK(*xv) || !looks_like_number(*xv)) continue;
		if (!gv || !*gv || !SvOK(*gv)) continue;
		NV val = SvNV(*xv); if (isnan(val)) continue;
		STRLEN l; const char *s = SvPV(*gv, l);
		x[N] = val; glab[N] = savepvn(s, l); N++;
	}
	if (N < 3) { for (size_t i = 0; i < N; i++) Safefree(glab[i]); Safefree(x); Safefree(glab); croak("dunn_test: not enough complete observations"); }
	// sorted unique group levels
	char **restrict lev = NULL; size_t k = 0, cap = 8; Newx(lev, cap, char*);
	for (size_t i = 0; i < N; i++) {
		bool found = FALSE;
		for (size_t j = 0; j < k; j++) if (strEQ(lev[j], glab[i])) { found = TRUE; break; }
		if (!found) { if (k >= cap) { cap *= 2; Renew(lev, cap, char*); } lev[k++] = savepv(glab[i]); }
	}
	for (size_t a = 0; a + 1 < k; a++) for (size_t b = a + 1; b < k; b++)
		if (strcmp(lev[a], lev[b]) > 0) { char *t = lev[a]; lev[a] = lev[b]; lev[b] = t; }
	if (k < 2) { for (size_t i = 0; i < N; i++) Safefree(glab[i]); for (size_t j = 0; j < k; j++) Safefree(lev[j]); Safefree(x); Safefree(glab); Safefree(lev); croak("dunn_test: need at least two groups"); }

	/* ranks over all observations (tie-averaged) */
	NV *restrict r = NULL; Newx(r, N, NV);
	rank_data(x, r, N);

	/* per-group rank sums and sizes */
	NV *restrict rsum = NULL; size_t *restrict ns = NULL;
	Newxz(rsum, k, NV); Newxz(ns, k, size_t);
	for (size_t i = 0; i < N; i++) {
		size_t gi = 0;
		for (size_t j = 0; j < k; j++) if (strEQ(lev[j], glab[i])) { gi = j; break; }
		rsum[gi] += r[i]; ns[gi]++;
	}
	/* tie correction: sum over distinct values of (t^3 - t) */
	NV *restrict xs = NULL; Newx(xs, N, NV);
	memcpy(xs, x, N * sizeof(NV));
	qsort(xs, N, sizeof(NV), cmp_nv3);
	NV tsum = 0.0;
	{
		size_t a = 0;
		while (a < N) {
			size_t b = a;
			while (b + 1 < N && xs[b + 1] == xs[a]) b++;
			NV t = (NV)(b - a + 1);
			tsum += t * t * t - t;
			a = b + 1;
		}
	}
	Safefree(xs);
	NV Nf = (NV)N;
	NV sigma_base = (Nf * (Nf + 1.0)) / 12.0 - tsum / (12.0 * (Nf - 1.0));
	size_t m = k * (k - 1) / 2;
	NV *restrict z = NULL, *restrict praw = NULL, *restrict padj = NULL;
	Newx(z, m, NV); Newx(praw, m, NV); Newx(padj, m, NV);
	size_t *restrict gi_ = NULL, *restrict gj_ = NULL;
	Newx(gi_, m, size_t); Newx(gj_, m, size_t);
	size_t c = 0;
	for (size_t i = 0; i < k; i++)
		for (size_t j = i + 1; j < k; j++) {
			NV rbar_i = rsum[i] / ns[i], rbar_j = rsum[j] / ns[j];
			NV se = sqrt(sigma_base * (1.0 / ns[i] + 1.0 / ns[j]));
			NV zz = (rbar_i - rbar_j) / se;
			z[c] = zz;
			praw[c] = 2.0 * (1.0 - approx_pnorm(fabs(zz)));
			if (praw[c] > 1.0) praw[c] = 1.0;
			gi_[c] = i; gj_[c] = j;
			c++;
		}
	dunn_padjust(praw, m, meth, padj);

	AV *restrict out = newAV();
	for (size_t t = 0; t < m; t++) {
		HV *restrict h = newHV();
		char comp[256];
		snprintf(comp, sizeof comp, "%s - %s", lev[gi_[t]], lev[gj_[t]]);
		hv_stores(h, "comparison", newSVpv(comp, 0));
		hv_stores(h, "group1",     newSVpv(lev[gi_[t]], 0));
		hv_stores(h, "group2",     newSVpv(lev[gj_[t]], 0));
		hv_stores(h, "Z",          newSVnv(z[t]));
		hv_stores(h, "p_value",    newSVnv(praw[t]));
		hv_stores(h, "p_adjust",   newSVnv(padj[t]));
		av_push(out, newRV_noinc((SV*)h));
	}

	for (size_t i = 0; i < N; i++) Safefree(glab[i]);
	for (size_t j = 0; j < k; j++) Safefree(lev[j]);
	Safefree(x); Safefree(glab); Safefree(lev); Safefree(r);
	Safefree(rsum); Safefree(ns); Safefree(z); Safefree(praw); Safefree(padj);
	Safefree(gi_); Safefree(gj_);
	ST(0) = sv_2mortal(newRV_noinc((SV*)out));
	XSRETURN(1);
}

void friedman_test(...)
PPCODE:
{
	/* Friedman rank-sum test for an unreplicated complete block design.
	 * Input is a matrix (array of array refs) with one block/subject per row
	 * and one treatment/condition per column.  Faithful port of R's
	 * stats::friedman.test, including the tie correction. */
	if (items < 1 || !SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV)
		croak("Usage: friedman_test([[..row1..],[..row2..], ...])  # rows = blocks, cols = treatments");
	AV *restrict m = (AV*)SvRV(ST(0));
	size_t nrow_raw = (size_t)(av_len(m) + 1);
	if (nrow_raw < 2) croak("friedman_test: need at least two blocks (rows)");

	// determine k from the first row
	SV **restrict r0 = av_fetch(m, 0, 0);
	if (!r0 || !*r0 || !SvROK(*r0) || SvTYPE(SvRV(*r0)) != SVt_PVAV)
		croak("friedman_test: each row must be an array ref");
	size_t k = (size_t)(av_len((AV*)SvRV(*r0)) + 1);
	if (k < 2) croak("friedman_test: need at least two treatments (columns)");

	NV *restrict colsum = NULL; Newxz(colsum, k, NV);
	NV *restrict rowbuf = NULL; Newx(rowbuf, k, NV);
	NV *restrict ranks  = NULL; Newx(ranks, k, NV);
	NV *restrict sorted = NULL; Newx(sorted, k, NV);
	NV tie_sum = 0.0;
	size_t n = 0; // complete blocks actually used

	for (size_t i = 0; i < nrow_raw; i++) {
		SV **restrict rr = av_fetch(m, i, 0);
		if (!rr || !*rr || !SvROK(*rr) || SvTYPE(SvRV(*rr)) != SVt_PVAV)
			{ Safefree(colsum); Safefree(rowbuf); Safefree(ranks); Safefree(sorted); croak("friedman_test: row %" UVuf " is not an array ref", (UV)i); }
		AV *rv = (AV*)SvRV(*rr);
		if ((size_t)(av_len(rv) + 1) != k)
			{ Safefree(colsum); Safefree(rowbuf); Safefree(ranks); Safefree(sorted); croak("friedman_test: all rows must have the same number of columns"); }
		bool complete = TRUE;
		for (size_t j = 0; j < k; j++) {
			SV **c = av_fetch(rv, j, 0);
			if (!c || !*c || !SvOK(*c) || !looks_like_number(*c)) { complete = FALSE; break; }
			rowbuf[j] = SvNV(*c);
			if (isnan(rowbuf[j])) { complete = FALSE; break; }
		}
		if (!complete) continue;   /* drop incomplete blocks, like R's complete.cases */

		rank_data(rowbuf, ranks, k);
		for (size_t j = 0; j < k; j++) colsum[j] += ranks[j];

		/* tie correction: sum over tie groups of (u^3 - u) within this block */
		memcpy(sorted, rowbuf, k * sizeof(NV));
		qsort(sorted, k, sizeof(NV), cmp_nv3);
		size_t a = 0;
		while (a < k) {
			size_t b = a;
			while (b + 1 < k && sorted[b + 1] == sorted[a]) b++;
			NV u = (NV)(b - a + 1);
			tie_sum += u * u * u - u;
			a = b + 1;
		}
		n++;
	}
	Safefree(rowbuf); Safefree(ranks); Safefree(sorted);
	if (n < 1) { Safefree(colsum); croak("friedman_test: no complete blocks"); }

	NV nf = (NV)n, kf = (NV)k;
	NV ssq = 0.0, target = nf * (kf + 1.0) / 2.0;
	for (size_t j = 0; j < k; j++) { NV d = colsum[j] - target; ssq += d * d; }
	Safefree(colsum);
	NV denom = nf * kf * (kf + 1.0) - tie_sum / (kf - 1.0);
	NV stat = 12.0 * ssq / denom;
	int df = (int)(k - 1);
	NV p_value = get_p_value(stat, df);

	HV *ret = newHV();
	hv_stores(ret, "statistic", newSVnv(stat));
	hv_stores(ret, "parameter", newSViv(df));
	hv_stores(ret, "p_value",   newSVnv(p_value));
	hv_stores(ret, "n",         newSViv((int)n));
	hv_stores(ret, "method",    newSVpv("Friedman rank sum test", 0));
	ST(0) = sv_2mortal(newRV_noinc((SV *)ret));
	XSRETURN(1);
}

void epi_2x2(...)
PPCODE:
{
	NV a, b, c, d, conf_level = 0.95;
	int correct = 0, opt_start;
	if (items < 1)
		croak("Usage: epi_2x2(a, b, c, d, conf_level => 0.95, correct => 0)\n"
		      "   or  epi_2x2([[a,b],[c,d]], ...)   # rows=exposure, cols=outcome");
	if (SvROK(ST(0))) {
		epi_read_2x2(aTHX_ ST(0), "epi_2x2", &a, &b, &c, &d);
		opt_start = 1;
	} else {
		if (items < 4)
			croak("epi_2x2: need 4 cell counts a,b,c,d (or a single 2x2 array ref)");
		a = SvNV(ST(0)); b = SvNV(ST(1)); c = SvNV(ST(2)); d = SvNV(ST(3));
		if (a < 0 || b < 0 || c < 0 || d < 0)
			croak("epi_2x2: cell counts must be non-negative");
		opt_start = 4;
	}
	for (int i = opt_start; i + 1 < items; i += 2) {
		const char *k = SvPV_nolen(ST(i)); SV *v = ST(i + 1);
		if      (strEQ(k, "conf_level") || strEQ(k, "conf.level")) conf_level = SvNV(v);
		else if (strEQ(k, "correct"))                              correct = SvTRUE(v) ? 1 : 0;
		else croak("epi_2x2: unknown argument '%s'", k);
	}
	if (!(conf_level > 0.0 && conf_level < 1.0))
		croak("epi_2x2: conf_level must be between 0 and 1");

	/* Haldane-Anscombe +0.5 when asked, or forced by a zero cell (avoids
	 * division by zero / log of zero).  Point estimates then shift too, so
	 * the applied flag is reported back.                                    */
	NV A = a, B = b, C = c, D = d; int corrected = 0;
	if (correct || a == 0 || b == 0 || c == 0 || d == 0) {
		A += 0.5; B += 0.5; C += 0.5; D += 0.5; corrected = 1;
	}
	NV z  = inverse_normal_cdf(1.0 - (1.0 - conf_level) / 2.0);
	NV n1 = A + B, n0 = C + D;

	NV or_    = (A * D) / (B * C);
	NV se_lor = sqrt(1.0 / A + 1.0 / B + 1.0 / C + 1.0 / D);
	NV or_lo  = or_ * exp(-z * se_lor), or_hi = or_ * exp(z * se_lor);

	NV p1 = A / n1, p0 = C / n0;
	NV rr     = p1 / p0;                          /* Katz log-RR variance */
	NV se_lrr = sqrt(B / (A * n1) + D / (C * n0));
	NV rr_lo  = rr * exp(-z * se_lrr), rr_hi = rr * exp(z * se_lrr);

	NV rd    = p1 - p0;
	NV se_rd = sqrt(p1 * (1.0 - p1) / n1 + p0 * (1.0 - p0) / n0);
	NV rd_lo = rd - z * se_rd, rd_hi = rd + z * se_rd;

	HV *restrict ret = newHV();
	hv_stores(ret, "method",         newSVpv("2x2 epidemiological measures (Wald)", 0));
	hv_stores(ret, "conf_level",     newSVnv(conf_level));
	hv_stores(ret, "correction",     newSViv(corrected));
	hv_stores(ret, "odds_ratio",     newSVnv(or_));
	hv_stores(ret, "risk_ratio",     newSVnv(rr));
	hv_stores(ret, "risk_diff",      newSVnv(rd));
	hv_stores(ret, "risk_exposed",   newSVnv(p1));
	hv_stores(ret, "risk_unexposed", newSVnv(p0));
	hv_stores(ret, "nnt",            newSVnv(1.0 / fabs(rd)));
#define EPI_CI(name, lo, hi) do { AV *ci = newAV(); \
	av_push(ci, newSVnv(lo)); av_push(ci, newSVnv(hi)); \
	hv_stores(ret, name, newRV_noinc((SV *)ci)); } while (0)
	EPI_CI("odds_ratio_ci", or_lo, or_hi);
	EPI_CI("risk_ratio_ci", rr_lo, rr_hi);
	EPI_CI("risk_diff_ci",  rd_lo, rd_hi);
#undef EPI_CI
	ST(0) = sv_2mortal(newRV_noinc((SV *)ret));
	XSRETURN(1);
}

void cmh_test(...)
PPCODE:
{
	if (items < 1 || !SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV)
		croak("Usage: cmh_test([ [a,b,c,d], [a,b,c,d], ... ], "
		      "conf_level => 0.95, correct => 1)");
	AV *restrict strata = (AV *)SvRV(ST(0));
	SSize_t K = av_len(strata) + 1;
	if (K < 1) croak("cmh_test: need at least one 2x2 stratum");
	NV conf_level = 0.95; int correct = 1;
	for (int i = 1; i + 1 < items; i += 2) {
		const char *k = SvPV_nolen(ST(i)); SV *v = ST(i + 1);
		if      (strEQ(k, "conf_level") || strEQ(k, "conf.level")) conf_level = SvNV(v);
		else if (strEQ(k, "correct"))                              correct = SvTRUE(v) ? 1 : 0;
		else croak("cmh_test: unknown argument '%s'", k);
	}
	if (!(conf_level > 0.0 && conf_level < 1.0))
		croak("cmh_test: conf_level must be between 0 and 1");

	NV sum_a = 0, E = 0, V = 0;      /* CMH statistic pieces               */
	NV sumR = 0, sumS = 0;           /* Mantel-Haenszel common-OR num/den  */
	NV vR = 0, vRS = 0, vS = 0;      /* Robins-Breslow-Greenland variance  */
	for (SSize_t s = 0; s < K; s++) {
		SV **restrict ep = av_fetch(strata, s, 0);
		NV a, b, c, d;
		epi_read_2x2(aTHX_ (ep ? *ep : &PL_sv_undef), "cmh_test", &a, &b, &c, &d);
		NV n = a + b + c + d;
		if (n <= 0) continue;
		NV r1 = a + b, r2 = c + d, c1 = a + c, c2 = b + d;
		sum_a += a;
		E     += r1 * c1 / n;
		if (n > 1.0) V += (r1 * r2 * c1 * c2) / (n * n * (n - 1.0));
		NV Rk = a * d / n, Sk = b * c / n;
		sumR += Rk; sumS += Sk;
		NV Pk = (a + d) / n, Qk = (b + c) / n;
		vR  += Pk * Rk;
		vRS += Pk * Sk + Qk * Rk;
		vS  += Qk * Sk;
	}
	NV diff = fabs(sum_a - E) - (correct ? 0.5 : 0.0);
	if (diff < 0) diff = 0;
	NV chi  = (V > 0) ? (diff * diff) / V : 0.0;
	NV pval = get_p_value(chi, 1);

	NV or_mh    = (sumS > 0) ? sumR / sumS : NAN;
	NV var_lnor = vR / (2.0 * sumR * sumR)
	            + vRS / (2.0 * sumR * sumS)
	            + vS / (2.0 * sumS * sumS);
	NV z     = inverse_normal_cdf(1.0 - (1.0 - conf_level) / 2.0);
	NV or_lo = or_mh * exp(-z * sqrt(var_lnor)), or_hi = or_mh * exp(z * sqrt(var_lnor));

	HV *ret = newHV();
	hv_stores(ret, "method", newSVpv(correct
		? "Mantel-Haenszel chi-squared test with continuity correction"
		: "Mantel-Haenszel chi-squared test", 0));
	hv_stores(ret, "statistic",  newSVnv(chi));
	hv_stores(ret, "parameter",  newSViv(1));       /* degrees of freedom  */
	hv_stores(ret, "p_value",    newSVnv(pval));
	hv_stores(ret, "estimate",   newSVnv(or_mh));   /* common odds ratio   */
	hv_stores(ret, "conf_level", newSVnv(conf_level));
	hv_stores(ret, "correction", newSViv(correct));
	hv_stores(ret, "k",          newSViv((IV)K));
	AV *ci = newAV(); av_push(ci, newSVnv(or_lo)); av_push(ci, newSVnv(or_hi));
	hv_stores(ret, "conf_int", newRV_noinc((SV *)ci));
	ST(0) = sv_2mortal(newRV_noinc((SV *)ret));
	XSRETURN(1);
}

NV auc(...)
CODE:
{
	if (items < 2 || !SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV
	              || !SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVAV)
		croak("Usage: auc(\\@scores, \\@labels, positive => 1, direction => '>')");
	const char *restrict positive = "1"; int lower_pos = 0;
	for (int i = 2; i + 1 < items; i += 2) {
		const char *restrict k = SvPV_nolen(ST(i)); SV *restrict v = ST(i + 1);
		if      (strEQ(k, "positive"))  positive = SvPV_nolen(v);
		else if (strEQ(k, "direction")) { const char *restrict d = SvPV_nolen(v); lower_pos = (d[0] == '<'); }
		else croak("auc: unknown argument '%s'", k);
	}
	NV *pos, *neg; size_t m, n;
	roc_split(aTHX_ (AV *)SvRV(ST(0)), (AV *)SvRV(ST(1)), positive, lower_pos,
	          &pos, &m, &neg, &n, "auc");
	NV a, se; roc_delong(aTHX_ pos, m, neg, n, &a, &se);
	Safefree(pos); Safefree(neg);
	RETVAL = a;
}
OUTPUT:
	RETVAL

NV auroc(...)
CODE:
{
/* sklearn-style AUROC: auroc(\@y_true, \@y_score, ...) -- LABELS first,
 * SCORES second, higher score = positive class.  This mirrors the call the
 * ~/ui/pep-priml scripts make, sklearn.metrics.roc_auc_score(y_true,
 * y_score) (e.g. _compute.py's roc_auc_score(y_te, fold_scores) and the
 * figs' roc_auc_score(y_true_bin, -pred)).  Ties count 0.5 (Mann-Whitney /
 * DeLong midranks), so the number matches sklearn exactly.  Returns the
 * scalar AUC; use roc() for the full curve, SE and CI, or auc() for the
 * same number with the (scores, labels) argument order.
 *
 * The pep-priml "roc_auc_score(y_true_bin, -pred)" idiom (lower prediction
 * = positive, truth derived from a continuous column by a percentile cut)
 * is reproduced in one call: pass direction => '<' instead of negating the
 * scores, and cutoff / active_frac to binarize a continuous truth column
 * the way y_true_bin = (exp <= threshold) does.*/
	if (items < 2 || !SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV
	              || !SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVAV)
		croak("Usage: auroc(\\@y_true, \\@y_score, positive => 1, "
		      "direction => '>', cutoff => x, active_frac => 0.1, "
		      "active_side => 'high')");
	const char *restrict positive = "1"; int lower_pos = 0;
	bool have_cutoff = 0, have_frac = 0; NV cutoff = 0.0, active_frac = 0.0;
	int frac_low = 0;
	for (int i = 2; i + 1 < items; i += 2) {
		const char *restrict k = SvPV_nolen(ST(i)); SV *restrict v = ST(i + 1);
		if      (strEQ(k, "positive"))  positive = SvPV_nolen(v);
		else if (strEQ(k, "direction")) { const char *restrict d = SvPV_nolen(v); lower_pos = (d[0] == '<'); }
		else if (strEQ(k, "cutoff"))    { have_cutoff = 1; cutoff = SvNV(v); }
		else if (strEQ(k, "active_frac") || strEQ(k, "active")) { have_frac = 1; active_frac = SvNV(v); }
		else if (strEQ(k, "active_side")) {
			const char *sd = SvPV_nolen(v); // 'low'/'bottom' vs 'high'/'top'
			frac_low = (sd[0] == 'l' || sd[0] == 'L' || sd[0] == 'b' || sd[0] == 'B');
		}
		else croak("auroc: unknown argument '%s'", k);
	}
	if (have_frac && have_cutoff)
		croak("auroc: give either cutoff => or active_frac =>, not both");
	if (have_frac && !(active_frac > 0.0 && active_frac < 1.0))
		croak("auroc: active_frac must be strictly between 0 and 1");

	AV *restrict lav = (AV *)SvRV(ST(0));   /* y_true  (labels first, like sklearn) */
	AV *restrict sav = (AV *)SvRV(ST(1));   /* y_score */

	if (have_cutoff || have_frac) {
		/* Binarize a continuous truth column, then DeLong on the pos/neg
		 * score vectors -- same shape as bedroc's cutoff/active_frac. */
		SSize_t Ns = av_len(sav) + 1;
		if (Ns != av_len(lav) + 1)
			croak("auroc: y_true and y_score must be the same length");
		if (Ns < 1) croak("auroc: need at least one observation");
		size_t N = (size_t)Ns;
		int *restrict act; Newxz(act, N, int);
		if (have_frac) {
			size_t n_a = (size_t)ceil(active_frac * (NV)N);
			if (n_a < 1) n_a = 1;
			if (N >= 2 && n_a > N - 1) n_a = N - 1;
			NVIdx *restrict tmp; Newx(tmp, N, NVIdx);
			for (size_t i = 0; i < N; i++) {
				SV **restrict lp = av_fetch(lav, i, 0);
				tmp[i].v = (lp && *lp) ? SvNV(*lp) : NAN; tmp[i].i = i;
			}
			qsort(tmp, N, sizeof(NVIdx), nvidx_cmp_asc);
			if (frac_low) for (size_t k = 0; k < n_a; k++) act[tmp[k].i] = 1;
			else          for (size_t k = N - n_a; k < N; k++) act[tmp[k].i] = 1;
			Safefree(tmp);
		} else {
			for (size_t i = 0; i < N; i++) {
				SV **restrict lp = av_fetch(lav, i, 0);
				act[i] = (((lp && *lp) ? SvNV(*lp) : NAN) >= cutoff);
			}
		}
		NV *restrict P; Newx(P, N, NV); NV *restrict Q; Newx(Q, N, NV);
		size_t m = 0, n = 0;
		for (size_t i = 0; i < N; i++) {
			SV **restrict sp = av_fetch(sav, i, 0);
			NV s = (sp && *sp) ? SvNV(*sp) : NAN;
			if (lower_pos) s = -s;
			if (act[i]) P[m++] = s; else Q[n++] = s;
		}
		Safefree(act);
		if (m == 0 || n == 0) {
			Safefree(P); Safefree(Q);
			croak("auroc: need both positive and negative labels%s",
			      have_cutoff ? " (check cutoff)" : "");
		}
		NV a, se; roc_delong(aTHX_ P, m, Q, n, &a, &se);
		Safefree(P); Safefree(Q);
		RETVAL = a;
	} else {
		/* Pre-built 0/1 (or string) labels: roc_split does the parallel-array
		 * walk; note swapped args so labels are ST(0), scores ST(1).      */
		NV *pos, *neg; size_t m, n;
		roc_split(aTHX_ sav, lav, positive, lower_pos, &pos, &m, &neg, &n, "auroc");
		NV a, se; roc_delong(aTHX_ pos, m, neg, n, &a, &se);
		Safefree(pos); Safefree(neg);
		RETVAL = a;
	}
}
OUTPUT:
	RETVAL

void roc(...)
PPCODE:
{
	if (items < 2 || !SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV
	              || !SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVAV)
		croak("Usage: roc(\\@scores, \\@labels, positive => 1, "
		      "conf_level => 0.95, direction => '>')");
	const char *restrict positive = "1"; NV conf_level = 0.95; int lower_pos = 0;
	for (int i = 2; i + 1 < items; i += 2) {
		const char *restrict k = SvPV_nolen(ST(i)); SV *restrict v = ST(i + 1);
		if      (strEQ(k, "positive"))  positive = SvPV_nolen(v);
		else if (strEQ(k, "conf_level") || strEQ(k, "conf.level")) conf_level = SvNV(v);
		else if (strEQ(k, "direction")) { const char *restrict d = SvPV_nolen(v); lower_pos = (d[0] == '<'); }
		else croak("roc: unknown argument '%s'", k);
	}
	if (!(conf_level > 0.0 && conf_level < 1.0))
		croak("roc: conf_level must be between 0 and 1");

	NV *pos, *neg; size_t m, n;
	roc_split(aTHX_ (AV *)SvRV(ST(0)), (AV *)SvRV(ST(1)), positive, lower_pos,
	          &pos, &m, &neg, &n, "roc");
	NV auc_val, se; roc_delong(aTHX_ pos, m, neg, n, &auc_val, &se);
	NV z  = inverse_normal_cdf(1.0 - (1.0 - conf_level) / 2.0);
	NV lo = auc_val - z * se, hi = auc_val + z * se;
	if (lo < 0.0) lo = 0.0; if (hi > 1.0) hi = 1.0;

	// Curve + Youden by sweeping thresholds high -> low over all points
	size_t N = m + n;
	ROCPt *restrict pts; Newx(pts, N, ROCPt);
	for (size_t i = 0; i < m; i++) { pts[i].score     = pos[i]; pts[i].lab     = 1; }
	for (size_t j = 0; j < n; j++) { pts[m + j].score = neg[j]; pts[m + j].lab = 0; }
	Safefree(pos); Safefree(neg);
	qsort(pts, N, sizeof(ROCPt), rocpt_cmp_desc);

	AV *restrict curve = newAV();
	{ /* leading operating point: threshold = +inf, nothing called positive */
		HV *restrict p0 = newHV();
		hv_stores(p0, "threshold",   newSVnv(INFINITY));
		hv_stores(p0, "sensitivity", newSVnv(0.0));
		hv_stores(p0, "specificity", newSVnv(1.0));
		av_push(curve, newRV_noinc((SV *)p0));
	}
	NV TP = 0.0, FP = 0.0, P = (NV)m, Nn = (NV)n;
	NV best_j = -2.0, best_thr = 0.0, best_sens = 0.0, best_spec = 0.0;
	size_t i = 0;
	while (i < N) {
		NV thr = pts[i].score;
		size_t j = i;
		while (j < N && pts[j].score == thr) { if (pts[j].lab) TP += 1.0; else FP += 1.0; j++; }
		NV sens = TP / P, spec = (Nn - FP) / Nn;
		HV *restrict pt = newHV();
		hv_stores(pt, "threshold",   newSVnv(thr));
		hv_stores(pt, "sensitivity", newSVnv(sens));
		hv_stores(pt, "specificity", newSVnv(spec));
		av_push(curve, newRV_noinc((SV *)pt));
		NV jstat = sens + spec - 1.0;
		if (jstat > best_j) { best_j = jstat; best_thr = thr; best_sens = sens; best_spec = spec; }
		i = j;
	}
	Safefree(pts);

	HV *restrict youden = newHV();
	hv_stores(youden, "threshold",   newSVnv(best_thr));
	hv_stores(youden, "sensitivity", newSVnv(best_sens));
	hv_stores(youden, "specificity", newSVnv(best_spec));
	hv_stores(youden, "j",           newSVnv(best_j));

	HV *restrict ret = newHV();
	hv_stores(ret, "auc",        newSVnv(auc_val));
	hv_stores(ret, "auc_se",     newSVnv(se));
	{ AV *restrict ci = newAV(); av_push(ci, newSVnv(lo)); av_push(ci, newSVnv(hi));
	  hv_stores(ret, "auc_ci", newRV_noinc((SV *)ci)); }
	hv_stores(ret, "conf_level", newSVnv(conf_level));
	hv_stores(ret, "n_pos",      newSViv((IV)m));
	hv_stores(ret, "n_neg",      newSViv((IV)n));
	hv_stores(ret, "n",          newSViv((IV)N));
	hv_stores(ret, "direction",  newSVpv(lower_pos ? "<" : ">", 1));
	hv_stores(ret, "youden",     newRV_noinc((SV *)youden));
	hv_stores(ret, "curve",      newRV_noinc((SV *)curve));
	hv_stores(ret, "method",     newSVpv("ROC curve with DeLong AUC", 0));
	ST(0) = sv_2mortal(newRV_noinc((SV *)ret));
	XSRETURN(1);
}

void bedroc(...)
PPCODE:
{
	/* Boltzmann-Enhanced Discrimination of ROC (Truchon & Bayly 2007, eq. 36).
	 * Rewards early recognition: actives ranked near the top count far more
	 * than actives buried deep in the list.  alpha sets how sharply the weight
	 * decays with rank; ties get the average (mid)rank.                       */
	if (items == 1 && !SvROK(ST(0))) {          /* bedroc('h'|'H'|'?') => help */
		const char *restrict h = SvPV_nolen(ST(0));
		if (strEQ(h, "h") || strEQ(h, "H") || strEQ(h, "?")) {
			GV *ogv = gv_fetchpvs("STDOUT", 0, SVt_PVIO);
			PerlIO *pio = (ogv && GvIO(ogv) && IoOFP(GvIO(ogv)))
			            ? IoOFP(GvIO(ogv)) : PerlIO_stdout();
			PerlIO_printf(pio,
"bedroc - Boltzmann-Enhanced Discrimination of ROC (Truchon & Bayly 2007)\n"
"\n"
"Early-recognition metric: scores actives ranked near the TOP of the list\n"
"far more than actives buried deep.  Result is in [0, 1] (1 = ideal early\n"
"recognition, 0 = worst, ~0.5 = random-ish depending on alpha & R_a).\n"
"\n"
"USAGE\n"
"  my $r = bedroc(\\@scores, \\@labels, alpha => 20);\n"
"  print $r->{bedroc};\n"
"\n"
"ARGUMENTS\n"
"  \\@scores      ranking scores (higher = better by default)\n"
"  \\@labels      class labels, OR a numeric column when cutoff/active_frac\n"
"                is given (then bedroc binarizes it for you)\n"
"  alpha => 20   early-recognition weight, > 0 (Truchon-Bayly default 20)\n"
"  positive => 1 label value that marks an active (string compare)\n"
"  cutoff => x   define actives as \\@labels entries with value >= x\n"
"  active_frac=>f binarize \\@labels: take a fraction f in (0,1) as active,\n"
"                from one tail (see active_side).  Exactly ceil(f*N) actives,\n"
"                clamped so both classes exist -- never dies for lack of a\n"
"                pre-built 0/1 label.  Mutually exclusive with cutoff.\n"
"  active_side=>  with active_frac: 'high' (default) = largest values are\n"
"    'high'      active (like cutoff); 'low' = smallest values (e.g. actives\n"
"                = strongest binders when the column is dG).\n"
"  direction=>'>' '>' higher score ranks first (default); '<' flips\n"
"  top => 0.05   also report enrichment in the top fraction (0..1]\n"
"\n"
"Unlike the common Python implementations (which need a pre-built 0/1 label\n"
"array, or reimplement a regression variant per script), active_frac lets one\n"
"call turn a raw measured column straight into a BEDROC score.\n"
"\n"
"RETURNS a hashref: bedroc, alpha, rie, rie_min, rie_max, n, n_active,\n"
"  n_inactive, ra, direction, method, and (with top=>) enrichment =>\n"
"  { fraction, n_top, active_count, expected, enrichment_factor }.\n"
"\n"
"  bedroc('h'), bedroc('H') or bedroc('?') prints this help.\n");
			XSRETURN(0);
		}
	}
	if (items < 2 || !SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV
	              || !SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVAV)
		croak("Usage: bedroc(\\@scores, \\@labels, alpha => 20, "
		      "positive => 1, cutoff => x, active_frac => 0.1, "
		      "active_side => 'high', direction => '>', top => 0.05)");
	NV alpha = 20.0; const char *restrict positive = "1"; int lower_pos = 0;
	bool have_cutoff = 0, have_top = 0, have_frac = 0;
	NV cutoff = 0.0, top = 0.0, active_frac = 0.0;
	int frac_low = 0;
	for (int i = 2; i + 1 < items; i += 2) {
		const char *restrict k = SvPV_nolen(ST(i)); SV *v = ST(i + 1);
		if      (strEQ(k, "alpha"))     alpha = SvNV(v);
		else if (strEQ(k, "positive"))  positive = SvPV_nolen(v);
		else if (strEQ(k, "cutoff"))    { have_cutoff = 1; cutoff = SvNV(v); }
		else if (strEQ(k, "top") || strEQ(k, "fraction")) { have_top = 1; top = SvNV(v); }
		else if (strEQ(k, "active_frac") || strEQ(k, "active")) { have_frac = 1; active_frac = SvNV(v); }
		else if (strEQ(k, "active_side")) {
			const char *restrict sd = SvPV_nolen(v);           /* 'low'/'bottom' vs 'high'/'top' */
			frac_low = (sd[0] == 'l' || sd[0] == 'L' || sd[0] == 'b' || sd[0] == 'B');
		}
		else if (strEQ(k, "direction")) { const char *d = SvPV_nolen(v); lower_pos = (d[0] == '<'); }
		else croak("bedroc: unknown argument '%s'", k);
	}
	if (!(alpha > 0.0)) croak("bedroc: alpha must be > 0");
	if (have_top && !(top > 0.0 && top <= 1.0))
		croak("bedroc: top must be between 0 and 1");
	if (have_frac && have_cutoff)
		croak("bedroc: give either cutoff => or active_frac =>, not both");
	if (have_frac && !(active_frac > 0.0 && active_frac < 1.0))
		croak("bedroc: active_frac must be strictly between 0 and 1");

	AV *restrict sav = (AV *)SvRV(ST(0)), *restrict lav = (AV *)SvRV(ST(1));
	SSize_t Ns = av_len(sav) + 1;
	if (Ns != av_len(lav) + 1)
		croak("bedroc: scores and labels must be the same length");
	if (Ns < 1) croak("bedroc: need at least one observation");
	size_t N = (size_t)Ns;

	/* active_frac mode: binarize the second array by taking exactly
	 * ceil(active_frac*N) items from one tail (default the HIGH end, like
	 * cutoff; active_side => 'low' takes the low end).  n_a is clamped to
	 * [1, N-1] so both classes always exist — no "need both labels" death. */
	int *restrict act_by_frac = NULL;
	if (have_frac) {
		size_t n_a = (size_t)ceil(active_frac * (NV)N);
		if (n_a < 1) n_a = 1;
		if (N >= 2 && n_a > N - 1) n_a = N - 1;
		NVIdx *restrict tmp; Newx(tmp, N, NVIdx);
		for (size_t i = 0; i < N; i++) {
			SV **restrict lp = av_fetch(lav, i, 0);
			tmp[i].v = (lp && *lp) ? SvNV(*lp) : NAN;
			tmp[i].i = i;
		}
		qsort(tmp, N, sizeof(NVIdx), nvidx_cmp_asc);
		Newxz(act_by_frac, N, int);
		if (frac_low) for (size_t k = 0; k < n_a; k++) act_by_frac[tmp[k].i] = 1;
		else          for (size_t k = N - n_a; k < N; k++) act_by_frac[tmp[k].i] = 1;
		Safefree(tmp);
	}

	ROCPt *restrict pts; Newx(pts, N, ROCPt);
	size_t m = 0;                            // actives
	for (size_t i = 0; i < N; i++) {
		SV **restrict sp = av_fetch(sav, i, 0), **lp = av_fetch(lav, i, 0);
		NV s = (sp && *sp) ? SvNV(*sp) : NAN;
		if (lower_pos) s = -s;
		bool active = act_by_frac ? act_by_frac[i]
			: have_cutoff
			? (((lp && *lp) ? SvNV(*lp) : NAN) >= cutoff)
			: ((lp && *lp) ? strEQ(SvPV_nolen(*lp), positive) : 0);
		pts[i].score = s; pts[i].lab = active ? 1 : 0;
		if (active) m++;
	}
	Safefree(act_by_frac);
	size_t n = N - m;                        // inactives
	if (m == 0 || n == 0) {
		Safefree(pts);
		croak("bedroc: need both active and inactive labels%s",
		      have_cutoff ? " (check cutoff)" : "");
	}

	qsort(pts, N, sizeof(ROCPt), rocpt_cmp_desc);
// sum over actives of exp(-alpha * midrank / N), 1-based ranks, best = 1 */
	NV sum = 0.0;
	for (size_t i = 0; i < N; ) {
		size_t j = i;
		while (j < N && pts[j].score == pts[i].score) j++;
		NV midrank = ((NV)(i + 1) + (NV)j) / 2.0; // avg of positions i+1..j
		NV w = exp(-alpha * midrank / (NV)N);
		for (size_t k = i; k < j; k++) if (pts[k].lab) sum += w;
		i = j;
	}

	NV ra   = (NV)m / (NV)N;
	NV rand_ = ra * (1.0 - exp(-alpha)) / (exp(alpha / (NV)N) - 1.0);
	NV rie   = sum / rand_;
	NV f1    = ra * sinh(alpha / 2.0)
	         / (cosh(alpha / 2.0) - cosh(alpha / 2.0 - alpha * ra));
	NV f2    = 1.0 / (1.0 - exp(alpha * (1.0 - ra)));
	NV bedroc   = rie * f1 + f2;
	NV rie_max  = (1.0 - exp(-alpha * ra)) / (ra * (1.0 - exp(-alpha)));
	NV rie_min  = (1.0 - exp( alpha * ra)) / (ra * (1.0 - exp( alpha)));

	HV *restrict ret = newHV();
	hv_stores(ret, "bedroc",     newSVnv(bedroc));
	hv_stores(ret, "alpha",      newSVnv(alpha));
	hv_stores(ret, "rie",        newSVnv(rie));
	hv_stores(ret, "rie_min",    newSVnv(rie_min));
	hv_stores(ret, "rie_max",    newSVnv(rie_max));
	hv_stores(ret, "n",          newSViv((IV)N));
	hv_stores(ret, "n_active",   newSViv((IV)m));
	hv_stores(ret, "n_inactive", newSViv((IV)n));
	hv_stores(ret, "ra",         newSVnv(ra));
	hv_stores(ret, "direction",  newSVpv(lower_pos ? "<" : ">", 1));
	hv_stores(ret, "method",     newSVpv("BEDROC (Truchon-Bayly early recognition)", 0));

	if (have_top) {/* enrichment in the top fraction: EF = (hits/n_top) / R_a */
		size_t n_top = (size_t)ceil(top * (NV)N);
		if (n_top < 1) n_top = 1; if (n_top > N) n_top = N;
		size_t hits = 0;
		for (size_t i = 0; i < n_top; i++) if (pts[i].lab) hits++;
		NV expected = ra * (NV)n_top;
		HV *enr = newHV();
		hv_stores(enr, "fraction",         newSVnv(top));
		hv_stores(enr, "n_top",            newSViv((IV)n_top));
		hv_stores(enr, "active_count",     newSViv((IV)hits));
		hv_stores(enr, "expected",         newSVnv(expected));
		hv_stores(enr, "enrichment_factor",
		          newSVnv((expected > 0.0) ? ((NV)hits / (NV)n_top) / ra : NAN));
		hv_stores(ret, "enrichment", newRV_noinc((SV *)enr));
	}

	Safefree(pts);
	ST(0) = sv_2mortal(newRV_noinc((SV *)ret));
	XSRETURN(1);
}

void survfit(...)
PPCODE:
{
	if (items < 2 || !SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV
	              || !SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVAV)
		croak("Usage: survfit(\\@time, \\@status, group => \\@grp, conf_level => 0.95)");
	AV *restrict gav = NULL; NV conf_level = 0.95;
	for (int i = 2; i + 1 < items; i += 2) {
		const char *restrict k = SvPV_nolen(ST(i)); SV *v = ST(i + 1);
		if      (strEQ(k, "group")) {
			if (!SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVAV) croak("survfit: group must be an array ref");
			gav = (AV *)SvRV(v);
		}
		else if (strEQ(k, "conf_level") || strEQ(k, "conf.level")) conf_level = SvNV(v);
		else croak("survfit: unknown argument '%s'", k);
	}
	if (!(conf_level > 0.0 && conf_level < 1.0)) croak("survfit: conf_level must be between 0 and 1");

	AV *labels = (AV *)sv_2mortal((SV *)newAV());
	size_t N; SurvObs *o = srv_read(aTHX_ (AV *)SvRV(ST(0)), (AV *)SvRV(ST(1)), gav, &N, labels, "survfit");
	qsort(o, N, sizeof(SurvObs), survobs_cmp);
	SSize_t G = av_len(labels) + 1;
	NV z = inverse_normal_cdf(1.0 - (1.0 - conf_level) / 2.0);

	HV *strata = newHV();
	for (SSize_t g = 0; g < G; g++) {// group size
		size_t ng = 0; for (size_t i = 0; i < N; i++) if (o[i].grp == g) ng++;
		AV *t_av=newAV(), *nr_av=newAV(), *ne_av=newAV(), *nc_av=newAV(),
		   *s_av=newAV(), *se_av=newAV(), *lo_av=newAV(), *hi_av=newAV();
		NV S = 1.0, vterm = 0.0, median = NAN;
		size_t at_risk = ng, total_events = 0;
		size_t i = 0;
		while (i < N) {
			if (o[i].grp != g) { i++; continue; }
			NV t = o[i].time;
			size_t d = 0, c = 0, block = 0;
			size_t j = i;
			while (j < N && o[j].time == t) {
				if (o[j].grp == g) { block++; if (o[j].status) d++; else c++; }
				j++;
			}
			size_t nr = at_risk;    // at risk just before t
			if (d > 0 && nr > d) {
				S *= 1.0 - (NV)d / (NV)nr;
				vterm += (NV)d / ((NV)nr * (NV)(nr - d));
				total_events += d;
			} else if (d > 0) {    // everyone remaining has an event
				S = 0.0; total_events += d;
			}
			NV se_S = S * sqrt(vterm);
			NV lo = (S > 0.0) ? S * exp(-z * sqrt(vterm)) : 0.0;
			NV hi = (S > 0.0) ? S * exp( z * sqrt(vterm)) : 0.0;
			if (hi > 1.0) hi = 1.0;
			av_push(t_av,  newSVnv(t));
			av_push(nr_av, newSViv((IV)nr));
			av_push(ne_av, newSViv((IV)d));
			av_push(nc_av, newSViv((IV)c));
			av_push(s_av,  newSVnv(S));
			av_push(se_av, newSVnv(se_S));
			av_push(lo_av, newSVnv(lo));
			av_push(hi_av, newSVnv(hi));
			if (isnan(median) && S <= 0.5) median = t;
			at_risk -= block;
			i = j;
		}
		HV *st = newHV();
		hv_stores(st, "time",     newRV_noinc((SV *)t_av));
		hv_stores(st, "n_risk",   newRV_noinc((SV *)nr_av));
		hv_stores(st, "n_event",  newRV_noinc((SV *)ne_av));
		hv_stores(st, "n_censor", newRV_noinc((SV *)nc_av));
		hv_stores(st, "surv",     newRV_noinc((SV *)s_av));
		hv_stores(st, "std_err",  newRV_noinc((SV *)se_av));
		hv_stores(st, "lower",    newRV_noinc((SV *)lo_av));
		hv_stores(st, "upper",    newRV_noinc((SV *)hi_av));
		hv_stores(st, "n",        newSViv((IV)ng));
		hv_stores(st, "events",   newSViv((IV)total_events));
		hv_stores(st, "median",   isnan(median) ? newSV(0) : newSVnv(median));
		SV *key = *av_fetch(labels, g, 0);
		STRLEN klen; const char *kp = SvPV(key, klen);
		hv_store(strata, kp, klen, newRV_noinc((SV *)st), 0);
	}
	Safefree(o);

	HV *ret = newHV();
	hv_stores(ret, "strata",     newRV_noinc((SV *)strata));
	hv_stores(ret, "groups",     newRV_inc((SV *)labels));
	hv_stores(ret, "conf_level", newSVnv(conf_level));
	hv_stores(ret, "method",     newSVpv("Kaplan-Meier survival estimate", 0));
	ST(0) = sv_2mortal(newRV_noinc((SV *)ret));
	XSRETURN(1);
}

void logrank_test(...)
PPCODE:
{
	if (items < 3 || !SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV
	              || !SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVAV
	              || !SvROK(ST(2)) || SvTYPE(SvRV(ST(2))) != SVt_PVAV)
		croak("Usage: logrank_test(\\@time, \\@status, \\@group)");
	AV *restrict labels = (AV *)sv_2mortal((SV *)newAV());
	size_t N; SurvObs *o = srv_read(aTHX_ (AV *)SvRV(ST(0)), (AV *)SvRV(ST(1)),
	                                (AV *)SvRV(ST(2)), &N, labels, "logrank_test");
	SSize_t G = av_len(labels) + 1;
	if (G < 2) { Safefree(o); croak("logrank_test: need at least two groups"); }
	qsort(o, N, sizeof(SurvObs), survobs_cmp);

	NV *restrict O, *restrict E, *restrict V; Newx(O, G, NV); Newx(E, G, NV); Newx(V, G * G, NV);
	for (SSize_t k = 0; k < G; k++) { O[k] = 0.0; E[k] = 0.0; }
	for (SSize_t k = 0; k < G * G; k++) V[k] = 0.0;

	size_t *restrict nrisk; Newx(nrisk, G, size_t);
	for (SSize_t k = 0; k < G; k++) { size_t c = 0; for (size_t i = 0; i < N; i++) if (o[i].grp == k) c++; nrisk[k] = c; }

	size_t i = 0;
	while (i < N) {
		NV t = o[i].time;
		size_t d_tot = 0, n_tot = 0;
		size_t *restrict dj; Newx(dj, G, size_t); for (SSize_t k = 0; k < G; k++) dj[k] = 0;
		for (SSize_t k = 0; k < G; k++) n_tot += nrisk[k];
		size_t j = i, block_j0 = 0; (void)block_j0;
		while (j < N && o[j].time == t) { if (o[j].status) { dj[o[j].grp]++; d_tot++; } j++; }
		if (d_tot > 0 && n_tot > 1) {
			for (SSize_t a = 0; a < G; a++) {
				NV nja = (NV)nrisk[a];
				O[a] += (NV)dj[a];
				E[a] += (NV)d_tot * nja / (NV)n_tot;
				for (SSize_t b = 0; b < G; b++) {
					NV njb = (NV)nrisk[b];
					NV term = (NV)d_tot * ((NV)n_tot - (NV)d_tot) / ((NV)n_tot - 1.0)
					          * (((a == b) ? nja / (NV)n_tot : 0.0) - nja * njb / ((NV)n_tot * (NV)n_tot));
					V[a * G + b] += term;
				}
			}
		}
		// remove this time's observations from the risk sets
		for (size_t k2 = i; k2 < j; k2++) nrisk[o[k2].grp]--;
		Safefree(dj);
		i = j;
	}

	int m = (int)G - 1; // reduced dimension
	NV *restrict Vr; Newx(Vr, m * m, NV);
	NV *restrict OE; Newx(OE, m, NV);
	for (int a = 0; a < m; a++) { OE[a] = O[a] - E[a]; for (int b = 0; b < m; b++) Vr[a*m+b] = V[a*G+b]; }
	NV *restrict xsol; Newx(xsol, m, NV);
	NV chi = 0.0;
	if (srv_solve(Vr, OE, m, xsol) == 0)
		for (int a = 0; a < m; a++) chi += OE[a] * xsol[a];
	NV pval = get_p_value(chi, m);

	HV *restrict ret = newHV();
	hv_stores(ret, "statistic", newSVnv(chi));
	hv_stores(ret, "parameter", newSViv(m));
	hv_stores(ret, "p_value",   newSVnv(pval));
	AV *obs = newAV(), *exp_av = newAV();
	for (SSize_t k = 0; k < G; k++) { av_push(obs, newSVnv(O[k])); av_push(exp_av, newSVnv(E[k])); }
	hv_stores(ret, "observed",  newRV_noinc((SV *)obs));
	hv_stores(ret, "expected",  newRV_noinc((SV *)exp_av));
	hv_stores(ret, "groups",    newRV_inc((SV *)labels));
	hv_stores(ret, "method",    newSVpv("Log-rank (Mantel-Cox) test", 0));

	Safefree(o); Safefree(O); Safefree(E); Safefree(V); Safefree(nrisk);
	Safefree(Vr); Safefree(OE); Safefree(xsol);
	ST(0) = sv_2mortal(newRV_noinc((SV *)ret));
	XSRETURN(1);
}

void coxph(...)
PPCODE:
{
	if (items < 3 || !SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVAV
	              || !SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVAV
	              || !SvROK(ST(2)) || SvTYPE(SvRV(ST(2))) != SVt_PVAV)
		croak("Usage: coxph(\\@time, \\@status, \\@covariate | [\\@x1, \\@x2, ...], "
		      "conf_level => 0.95, ties => 'efron', names => [...])");
	AV *restrict tav = (AV *)SvRV(ST(0)), *sav = (AV *)SvRV(ST(1)), *Xav = (AV *)SvRV(ST(2));
	SSize_t n = av_len(tav) + 1;
	if (n < 2) croak("coxph: need at least two observations");
	if (av_len(sav) + 1 != n) croak("coxph: time and status must be the same length");

	/* covariates: [\@x1, \@x2, ...] (multiple) or a single flat \@x */
	int p, multi = 0;
	SV **restrict first = av_fetch(Xav, 0, 0);
	if (first && *first && SvROK(*first) && SvTYPE(SvRV(*first)) == SVt_PVAV) { multi = 1; p = (int)(av_len(Xav) + 1); }
	else { multi = 0; p = 1; }
	if (p < 1) croak("coxph: need at least one covariate");

	NV conf_level = 0.95; int breslow = 0, maxit = 25; NV eps = 1e-9;
	AV *names_av = NULL;
	for (int i = 3; i + 1 < items; i += 2) {
		const char *k = SvPV_nolen(ST(i)); SV *v = ST(i + 1);
		if      (strEQ(k, "conf_level") || strEQ(k, "conf.level")) conf_level = SvNV(v);
		else if (strEQ(k, "ties"))  breslow = strEQ(SvPV_nolen(v), "breslow");
		else if (strEQ(k, "maxit")) maxit = (int)SvIV(v);
		else if (strEQ(k, "names")) { if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV) names_av = (AV *)SvRV(v); }
		else croak("coxph: unknown argument '%s'", k);
	}
	if (!(conf_level > 0.0 && conf_level < 1.0)) croak("coxph: conf_level must be between 0 and 1");

	/* pull data into contiguous C arrays */
	NV *restrict X; Newx(X, (size_t)n * p, NV);
	NV *restrict tm; Newx(tm, n, NV);
	int *restrict st; Newx(st, n, int);
	for (SSize_t i = 0; i < n; i++) {
		tm[i] = SvNV(*av_fetch(tav, i, 0));
		st[i] = (SvNV(*av_fetch(sav, i, 0)) != 0.0) ? 1 : 0;
	}
	if (multi) {
		for (int k = 0; k < p; k++) {
			AV *col = (AV *)SvRV(*av_fetch(Xav, k, 0));
			if (av_len(col) + 1 != n) { Safefree(X); Safefree(tm); Safefree(st); croak("coxph: covariate %d length mismatch", k + 1); }
			for (SSize_t i = 0; i < n; i++) X[i * p + k] = SvNV(*av_fetch(col, i, 0));
		}
	} else {
		if (av_len(Xav) + 1 != n) { Safefree(X); Safefree(tm); Safefree(st); croak("coxph: covariate length mismatch"); }
		for (SSize_t i = 0; i < n; i++) X[i] = SvNV(*av_fetch(Xav, i, 0));
	}

	/* observations sorted by time ascending (risk sets built time-descending) */
	TimeIdx *restrict ord; Newx(ord, n, TimeIdx);
	for (SSize_t i = 0; i < n; i++) { ord[i].time = tm[i]; ord[i].idx = (int)i; }
	qsort(ord, n, sizeof(TimeIdx), cmp_nv3);

	NV *beta = NULL, *U = NULL, *Imat = NULL, *Iinv = NULL, *ratio = NULL,
	   *S1 = NULL, *S2 = NULL, *SD1 = NULL, *SD2 = NULL, *sumX_D = NULL, *eta = NULL, *w = NULL;
	Newx(beta, p, NV);   Newx(U, p, NV);       Newx(Imat, p * p, NV); Newx(Iinv, p * p, NV);
	Newx(ratio, p, NV);  Newx(S1, p, NV);      Newx(S2, p * p, NV);
	Newx(SD1, p, NV);    Newx(SD2, p * p, NV); Newx(sumX_D, p, NV);
	Newx(eta, n, NV);    Newx(w, n, NV);
	for (int k = 0; k < p; k++) beta[k] = 0.0;

	NV loglik = 0.0, loglik_null = 0.0, prev = 0.0;
	int iter = 0, converged = 0, singular = 0;
	for (iter = 0; iter < maxit; iter++) {
		for (SSize_t i = 0; i < n; i++) {
			NV e = 0.0; for (int k = 0; k < p; k++) e += X[i * p + k] * beta[k];
			eta[i] = e; w[i] = exp(e);
		}
		loglik = 0.0;
		for (int k = 0; k < p; k++) U[k] = 0.0;
		for (int k = 0; k < p * p; k++) Imat[k] = 0.0;
		NV S0 = 0.0;
		for (int k = 0; k < p; k++) S1[k] = 0.0;
		for (int k = 0; k < p * p; k++) S2[k] = 0.0;

		SSize_t pos = n - 1;
		while (pos >= 0) {
			NV t = ord[pos].time;
			SSize_t lo = pos; while (lo > 0 && ord[lo - 1].time == t) lo--;
			NV SD0 = 0.0; int m = 0; NV sumEta_D = 0.0;
			for (int k = 0; k < p; k++) { SD1[k] = 0.0; sumX_D[k] = 0.0; }
			for (int k = 0; k < p * p; k++) SD2[k] = 0.0;
			for (SSize_t q = lo; q <= pos; q++) {
				int oi = ord[q].idx; NV wq = w[oi];
				S0 += wq;
				for (int k = 0; k < p; k++) {
					NV xk = X[oi * p + k];
					S1[k] += wq * xk;
					for (int l = 0; l < p; l++) S2[k * p + l] += wq * xk * X[oi * p + l];
				}
				if (st[oi]) {
					m++; SD0 += wq; sumEta_D += eta[oi];
					for (int k = 0; k < p; k++) {
						NV xk = X[oi * p + k];
						SD1[k] += wq * xk; sumX_D[k] += xk;
						for (int l = 0; l < p; l++) SD2[k * p + l] += wq * xk * X[oi * p + l];
					}
				}
			}
			if (m > 0) {
				loglik += sumEta_D;
				for (int k = 0; k < p; k++) U[k] += sumX_D[k];
				for (int l = 0; l < m; l++) {
					NV d = breslow ? 0.0 : (NV)l / (NV)m;
					NV Z0 = S0 - d * SD0;
					loglik -= log(Z0);
					for (int k = 0; k < p; k++) ratio[k] = (S1[k] - d * SD1[k]) / Z0;
					for (int k = 0; k < p; k++) {
						U[k] -= ratio[k];
						for (int l2 = 0; l2 < p; l2++)
							Imat[k * p + l2] += (S2[k * p + l2] - d * SD2[k * p + l2]) / Z0
							                    - ratio[k] * ratio[l2];
					}
				}
			}
			pos = lo - 1;
		}

		if (iter == 0) loglik_null = loglik;
		for (int k = 0; k < p * p; k++) Iinv[k] = Imat[k];   /* mat_inv destroys input */
		{ NV *tmp; Newx(tmp, p * p, NV); for (int k = 0; k < p*p; k++) tmp[k] = Imat[k];
		  if (mat_inv(tmp, p, Iinv) != 0) singular = 1; Safefree(tmp); }
		if (singular) break;
		if (iter > 0 && fabs(loglik - prev) <= eps * (fabs(loglik) + eps)) { converged = 1; break; }
		prev = loglik;
		/* Newton update: beta += Iinv * U */
		for (int k = 0; k < p; k++) { NV s = 0.0; for (int l = 0; l < p; l++) s += Iinv[k * p + l] * U[l]; beta[k] += s; }
	}

	int nevent = 0; for (SSize_t i = 0; i < n; i++) if (st[i]) nevent++;
	NV zc = inverse_normal_cdf(1.0 - (1.0 - conf_level) / 2.0);

	AV *coef=newAV(), *hr=newAV(), *se=newAV(), *zv=newAV(), *pv=newAV(),
	   *ci=newAV(), *nm=newAV();
	for (int k = 0; k < p; k++) {
		NV b = beta[k];
		NV sek = (Iinv[k * p + k] > 0.0) ? sqrt(Iinv[k * p + k]) : NAN;
		NV zk = b / sek;
		NV pk = 2.0 * approx_pnorm(-fabs(zk));
		av_push(coef, newSVnv(b));
		av_push(hr,   newSVnv(exp(b)));
		av_push(se,   newSVnv(sek));
		av_push(zv,   newSVnv(zk));
		av_push(pv,   newSVnv(pk));
		AV *cik = newAV();
		av_push(cik, newSVnv(exp(b - zc * sek)));
		av_push(cik, newSVnv(exp(b + zc * sek)));
		av_push(ci, newRV_noinc((SV *)cik));
		if (names_av && k <= av_len(names_av)) av_push(nm, newSVsv(*av_fetch(names_av, k, 0)));
		else { SV *dn = newSVpvf("x%d", k + 1); av_push(nm, dn); }
	}
	NV lr = 2.0 * (loglik - loglik_null);
	NV lr_p = get_p_value(lr, p);

	HV *restrict ret = newHV();
	hv_stores(ret, "coef",        newRV_noinc((SV *)coef));
	hv_stores(ret, "exp_coef",    newRV_noinc((SV *)hr));      /* hazard ratios */
	hv_stores(ret, "se",          newRV_noinc((SV *)se));
	hv_stores(ret, "z",           newRV_noinc((SV *)zv));
	hv_stores(ret, "p_value",     newRV_noinc((SV *)pv));
	hv_stores(ret, "conf_int",    newRV_noinc((SV *)ci));      /* on the HR scale */
	hv_stores(ret, "names",       newRV_noinc((SV *)nm));
	hv_stores(ret, "loglik",      newSVnv(loglik));
	hv_stores(ret, "loglik_null", newSVnv(loglik_null));
	hv_stores(ret, "lr_stat",     newSVnv(lr));
	hv_stores(ret, "lr_df",       newSViv(p));
	hv_stores(ret, "lr_p_value",  newSVnv(lr_p));
	hv_stores(ret, "n",           newSViv((IV)n));
	hv_stores(ret, "nevent",      newSViv(nevent));
	hv_stores(ret, "iterations",  newSViv(iter));
	hv_stores(ret, "converged",   newSViv(converged));
	hv_stores(ret, "conf_level",  newSVnv(conf_level));
	hv_stores(ret, "ties",        newSVpv(breslow ? "breslow" : "efron", 0));
	hv_stores(ret, "method",      newSVpv("Cox proportional hazards model", 0));

	Safefree(X); Safefree(tm); Safefree(st); Safefree(ord);
	Safefree(beta); Safefree(U); Safefree(Imat); Safefree(Iinv); Safefree(ratio);
	Safefree(S1); Safefree(S2); Safefree(SD1); Safefree(SD2); Safefree(sumX_D);
	Safefree(eta); Safefree(w);
	ST(0) = sv_2mortal(newRV_noinc((SV *)ret));
	XSRETURN(1);
}

void p_adjust(...)
	PROTOTYPE: $;@
	PPCODE:
		if (items < 1)
			croak("Usage: p_adjust($p_values, $method, columns => ...)");
		SV *restrict p_sv    = ST(0);
		const char *restrict method = "holm";
		SV *restrict cols_sv = NULL;
		IV first_pair = 1;
		/* The method may still arrive positionally, the way it always has;
		 * anything after it (or after the frame) is key => value.          */
		if (items > 1 && ((items - 1) % 2) == 1) {
			if (!SvOK(ST(1)) || SvROK(ST(1)))
				croak("p_adjust: the second argument must be an adjustment method name");
			method = SvPV_nolen(ST(1));
			first_pair = 2;
		}
		for (IV a = first_pair; a + 1 < (IV)items; a += 2) {
			const char *restrict key = SvPV_nolen(ST(a));
			SV *restrict val = ST(a + 1);
			if      (strEQ(key, "method")) method = SvPV_nolen(val);
			else if (strEQ(key, "columns") || strEQ(key, "column")
			      || strEQ(key, "cols")    || strEQ(key, "col")) cols_sv = val;
			else croak("p_adjust: unknown argument '%s'", key);
		}

		char meth[PA_METH_LEN];
		pa_method(method, meth);
		if (!pa_known(meth)) croak("Unknown p-value adjustment method: %s", method);

		/* Which columns hold p-values? Nothing named means all of them. The
		 * value is a flag, set once the column turns up in the frame.      */
		HV *restrict want = NULL;
		if (cols_sv && SvOK(cols_sv)) {
			want = (HV*)sv_2mortal((SV*)newHV());
			if (SvROK(cols_sv) && SvTYPE(SvRV(cols_sv)) == SVt_PVAV) {
				AV *restrict cav = (AV*)SvRV(cols_sv);
				for (SSize_t i = 0; i <= av_len(cav); i++) {
					SV **restrict c = av_fetch(cav, i, 0);
					if (!c || !SvOK(*c))
						croak("p_adjust: undefined column name in 'columns'");
					(void)hv_store_ent(want, *c, newSViv(0), 0);
				}
			} else if (SvROK(cols_sv)) {
				croak("p_adjust: 'columns' must be a column name or an ARRAY "
				      "reference of column names");
			} else {
				(void)hv_store_ent(want, cols_sv, newSViv(0), 0);
			}
			if (HvUSEDKEYS(want) == 0) croak("p_adjust: 'columns' names no columns");
		}

		/* Which of the five shapes is this? */
		enum { PA_FLAT, PA_AOA, PA_AOH, PA_HOA, PA_HOH } kind = PA_FLAT;
		SV *restrict ref = SvROK(p_sv) ? SvRV(p_sv) : NULL;
		if (!ref || (SvTYPE(ref) != SVt_PVAV && SvTYPE(ref) != SVt_PVHV))
			croak("p_adjust: first argument must be an ARRAY reference of p-values, "
			      "or a reference to an AoA, AoH, HoA or HoH data frame");
		if (SvTYPE(ref) == SVt_PVAV) {
			AV *restrict av = (AV*)ref;
			for (SSize_t i = 0; i <= av_len(av); i++) {
				SV **restrict e = av_fetch(av, i, 0);
				if (!e || !SvOK(*e)) continue;      /* undef p-value: still flat */
				if (SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVAV)      kind = PA_AOA;
				else if (SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV) kind = PA_AOH;
				else if (SvROK(*e))
					croak("p_adjust: an ARRAY reference must hold p-values, "
					      "ARRAY references (AoA) or HASH references (AoH)");
				break;
			}
		} else {
			HV *restrict hv = (HV*)ref;
			HE *restrict e;
			kind = PA_HOA;                          /* an empty hash is either */
			hv_iterinit(hv);
			while ((e = hv_iternext(hv))) {
				SV *restrict v = HeVAL(e);
				if (!v || !SvOK(v)) continue;
				if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV)      kind = PA_HOA;
				else if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV) kind = PA_HOH;
				else croak("p_adjust: a HASH reference must hold ARRAY references "
				           "(HoA) or HASH references (HoH)");
				break;
			}
		}

		/* ---- the flat list, unchanged: a list of p-values in, a list out */
		if (kind == PA_FLAT) {
			if (want)
				croak("p_adjust: 'columns' needs a data frame, not a flat list "
				      "of p-values");
			AV *restrict p_av = (AV*)ref;
			size_t n = av_len(p_av) + 1;
			if (n == 0) XSRETURN_EMPTY;
			NV *restrict pv;
			NV *restrict adj;
			Newx(pv, n, NV);
			Newx(adj, n, NV);
			for (size_t i = 0; i < n; i++) {
				SV **restrict tv = av_fetch(p_av, i, 0);
				pv[i] = (tv && SvOK(*tv)) ? SvNV(*tv) : 1.0;
			}
			pa_kernel(pv, adj, n, meth);
			EXTEND(SP, (SSize_t)n);
			for (size_t i = 0; i < n; i++) ST(i) = sv_2mortal(newSVnv(adj[i]));
			Safefree(pv);  pv  = NULL;
			Safefree(adj); adj = NULL;
			XSRETURN((int)n);
		}

		/* ---- a frame: validate and size the family before building anything,
		 * so the second pass cannot die part way through and strand memory. */
		size_t n = 0;
		SSize_t maxk = 0, nouter = 0;   /* widest row hash; outer hash size */
		if (kind == PA_AOA) {
			AV *restrict av = (AV*)ref;
			for (SSize_t i = 0; i <= av_len(av); i++) {
				SV **restrict rs = av_fetch(av, i, 0);
				if (!rs || !SvROK(*rs) || SvTYPE(SvRV(*rs)) != SVt_PVAV)
					croak("p_adjust: row %" IVdf " of the AoA is not an ARRAY reference",
					      (IV)i);
				AV *restrict row = (AV*)SvRV(*rs);
				for (SSize_t j = 0; j <= av_len(row); j++) {
					if (want) {
						char kb[24];
						I32 kl = (I32)snprintf(kb, sizeof kb, "%" IVdf, (IV)j);
						if (!pa_mark(aTHX_ want, kb, (STRLEN)kl, 0)) continue;
					}
					SV **restrict c = av_fetch(row, j, 0);
					pa_check(aTHX_ c ? *c : NULL, NULL, (IV)j);
					n++;
				}
			}
		} else if (kind == PA_AOH) {
			AV *restrict av = (AV*)ref;
			for (SSize_t i = 0; i <= av_len(av); i++) {
				SV **restrict rs = av_fetch(av, i, 0);
				if (!rs || !SvROK(*rs) || SvTYPE(SvRV(*rs)) != SVt_PVHV)
					croak("p_adjust: row %" IVdf " of the AoH is not a HASH reference",
					      (IV)i);
				HV *restrict row = (HV*)SvRV(*rs);
				SSize_t hk = (SSize_t)HvUSEDKEYS(row);
				if (hk > maxk) maxk = hk;
				HE *restrict e;
				hv_iterinit(row);
				while ((e = hv_iternext(row))) {
					STRLEN kl;
					const char *restrict kp = HePV(e, kl);
					if (!pa_mark(aTHX_ want, kp, kl, HeUTF8(e))) continue;
					pa_check(aTHX_ HeVAL(e), kp, 0);
					n++;
				}
			}
		} else if (kind == PA_HOA) {
			HV *restrict hv = (HV*)ref;
			HE *restrict e;
			nouter = (SSize_t)HvUSEDKEYS(hv);
			hv_iterinit(hv);
			while ((e = hv_iternext(hv))) {
				STRLEN kl;
				const char *restrict kp = HePV(e, kl);
				SV *restrict cv = HeVAL(e);
				if (!cv || !SvROK(cv) || SvTYPE(SvRV(cv)) != SVt_PVAV)
					croak("p_adjust: column '%s' of the HoA is not an ARRAY reference", kp);
				if (!pa_mark(aTHX_ want, kp, kl, HeUTF8(e))) continue;
				AV *restrict cav = (AV*)SvRV(cv);
				for (SSize_t i = 0; i <= av_len(cav); i++) {
					SV **restrict c = av_fetch(cav, i, 0);
					pa_check(aTHX_ c ? *c : NULL, kp, 0);
					n++;
				}
			}
		} else {                                                   /* PA_HOH */
			HV *restrict hv = (HV*)ref;
			HE *restrict e;
			nouter = (SSize_t)HvUSEDKEYS(hv);
			hv_iterinit(hv);
			while ((e = hv_iternext(hv))) {
				SV *restrict rv = HeVAL(e);
				if (!rv || !SvROK(rv) || SvTYPE(SvRV(rv)) != SVt_PVHV)
					croak("p_adjust: row '%s' of the HoH is not a HASH reference",
					      HePV(e, PL_na));
				HV *restrict row = (HV*)SvRV(rv);
				SSize_t hk = (SSize_t)HvUSEDKEYS(row);
				if (hk > maxk) maxk = hk;
				HE *restrict f;
				hv_iterinit(row);
				while ((f = hv_iternext(row))) {
					STRLEN kl;
					const char *restrict kp = HePV(f, kl);
					if (!pa_mark(aTHX_ want, kp, kl, HeUTF8(f))) continue;
					pa_check(aTHX_ HeVAL(f), kp, 0);
					n++;
				}
			}
		}
		if (want) {
			HE *restrict e;
			hv_iterinit(want);
			while ((e = hv_iternext(want)))
				if (!SvTRUE(HeVAL(e)))
					croak("p_adjust: the frame has no column named '%s'",
					      HePV(e, PL_na));
		}

		/* ---- second pass: rebuild the frame, reserving a slot per p-value */
		NV *restrict pv     = NULL;
		NV *restrict adj    = NULL;
		SV **restrict slots = NULL;
		HE **restrict kbuf  = NULL;
		HE **restrict obuf  = NULL;
		if (n) { Newx(pv, n, NV); Newx(adj, n, NV); Newx(slots, n, SV*); }
		if (maxk)   Newx(kbuf, maxk,   HE*);
		if (nouter) Newx(obuf, nouter, HE*);
		size_t k = 0;
		SV *restrict out_sv;

		if (kind == PA_AOA) {
			AV *restrict in = (AV*)ref, *restrict out = newAV();
			out_sv = sv_2mortal(newRV_noinc((SV*)out));
			SSize_t nr = av_len(in) + 1;
			if (nr > 0) av_extend(out, nr - 1);
			for (SSize_t i = 0; i < nr; i++) {
				AV *restrict row = (AV*)SvRV(*av_fetch(in, i, 0));
				AV *restrict rout = newAV();
				av_push(out, newRV_noinc((SV*)rout));
				SSize_t nc = av_len(row) + 1;
				if (nc > 0) av_extend(rout, nc - 1);
				for (SSize_t j = 0; j < nc; j++) {
					SV **restrict c = av_fetch(row, j, 0);
					int sel = 1;
					if (want) {
						char kb[24];
						I32 kl = (I32)snprintf(kb, sizeof kb, "%" IVdf, (IV)j);
						sel = hv_fetch(want, kb, kl, 0) != NULL;
					}
					av_push(rout, sel
						? pa_place(aTHX_ c ? *c : NULL, pv, slots, &k, n)
						: pa_copy(aTHX_ c ? *c : NULL));
				}
			}
		} else if (kind == PA_AOH) {
			AV *restrict in = (AV*)ref, *restrict out = newAV();
			out_sv = sv_2mortal(newRV_noinc((SV*)out));
			SSize_t nr = av_len(in) + 1;
			if (nr > 0) av_extend(out, nr - 1);
			for (SSize_t i = 0; i < nr; i++) {
				HV *restrict row = (HV*)SvRV(*av_fetch(in, i, 0));
				HV *restrict rout = newHV();
				av_push(out, newRV_noinc((SV*)rout));
				SSize_t nk = pa_sorted_keys(aTHX_ row, kbuf);
				for (SSize_t j = 0; j < nk; j++) {
					HE *restrict e = kbuf[j];
					STRLEN kl;
					const char *restrict kp = HePV(e, kl);
					I32 sk = HeUTF8(e) ? -(I32)kl : (I32)kl;
					int sel = !want || hv_fetch(want, kp, sk, 0) != NULL;
					(void)hv_store(rout, kp, sk, sel
						? pa_place(aTHX_ HeVAL(e), pv, slots, &k, n)
						: pa_copy(aTHX_ HeVAL(e)), 0);
				}
			}
		} else if (kind == PA_HOA) {
			HV *restrict in = (HV*)ref, *restrict out = newHV();
			out_sv = sv_2mortal(newRV_noinc((SV*)out));
			SSize_t nk = pa_sorted_keys(aTHX_ in, obuf);
			for (SSize_t ci = 0; ci < nk; ci++) {
				HE *restrict e = obuf[ci];
				STRLEN kl;
				const char *restrict kp = HePV(e, kl);
				I32 sk = HeUTF8(e) ? -(I32)kl : (I32)kl;
				AV *restrict cin = (AV*)SvRV(HeVAL(e));
				AV *restrict cout = newAV();
				(void)hv_store(out, kp, sk, newRV_noinc((SV*)cout), 0);
				SSize_t nrw = av_len(cin) + 1;
				if (nrw > 0) av_extend(cout, nrw - 1);
				int sel = !want || hv_fetch(want, kp, sk, 0) != NULL;
				for (SSize_t i = 0; i < nrw; i++) {
					SV **restrict c = av_fetch(cin, i, 0);
					av_push(cout, sel
						? pa_place(aTHX_ c ? *c : NULL, pv, slots, &k, n)
						: pa_copy(aTHX_ c ? *c : NULL));
				}
			}
		} else {                                                   /* PA_HOH */
			HV *restrict in = (HV*)ref, *restrict out = newHV();
			out_sv = sv_2mortal(newRV_noinc((SV*)out));
			SSize_t nr = pa_sorted_keys(aTHX_ in, obuf);
			for (SSize_t ri = 0; ri < nr; ri++) {
				HE *restrict re = obuf[ri];
				STRLEN rl;
				const char *restrict rp = HePV(re, rl);
				HV *restrict row = (HV*)SvRV(HeVAL(re));
				HV *restrict rout = newHV();
				(void)hv_store(out, rp, HeUTF8(re) ? -(I32)rl : (I32)rl,
				               newRV_noinc((SV*)rout), 0);
				SSize_t nk = pa_sorted_keys(aTHX_ row, kbuf);
				for (SSize_t j = 0; j < nk; j++) {
					HE *restrict e = kbuf[j];
					STRLEN kl;
					const char *restrict kp = HePV(e, kl);
					I32 sk = HeUTF8(e) ? -(I32)kl : (I32)kl;
					int sel = !want || hv_fetch(want, kp, sk, 0) != NULL;
					(void)hv_store(rout, kp, sk, sel
						? pa_place(aTHX_ HeVAL(e), pv, slots, &k, n)
						: pa_copy(aTHX_ HeVAL(e)), 0);
				}
			}
		}

		if (n) {
			pa_kernel(pv, adj, n, meth);
			for (size_t i = 0; i < n; i++) sv_setnv(slots[i], adj[i]);
		}
		Safefree(pv);    pv    = NULL;
		Safefree(adj);   adj   = NULL;
		Safefree(slots); slots = NULL;
		Safefree(kbuf);  kbuf  = NULL;
		Safefree(obuf);  obuf  = NULL;
		ST(0) = out_sv;
		XSRETURN(1);

NV median(...)
	PROTOTYPE: @
	INIT:
	  size_t total_count = 0, k = 0;
	  NV* restrict nums;
	  NV median_val = 0.0;
	  /* Small samples -- a per-group median under agg()/group_by(), say --
	   * are the common case by call count, and for those the malloc/free pair
	   * cost more than the arithmetic.  They borrow the C stack instead.     */
	  NV stackbuf[256];
	CODE:
	  /* How many values there are, from the array lengths alone.  Every
	   * element has to be defined (an undef croaks below, as it always has),
	   * so this bound is exact and the old counting pass over every SV -- a
	   * second walk of the whole input before any arithmetic -- is gone.     */
	  for (size_t i = 0; i < items; i++) {
		   SV* restrict arg = ST(i);
		   if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV)
			   total_count += (size_t)(av_len((AV*)SvRV(arg)) + 1);
		   else
			   total_count++;
	  }
	  if (total_count == 0) croak("median needs >= 1 element");

	  nums = (total_count <= sizeof(stackbuf) / sizeof(stackbuf[0])) ? stackbuf : NULL;
	  if (!nums) Newx(nums, total_count, NV);

	  /* Populate the C array — free the buffer before any croak */
	  for (size_t i = 0; i < items; i++) {
		   SV* restrict arg = ST(i);
		   if (SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV) {
			   AV* restrict av = (AV*)SvRV(arg);
			   size_t len = av_len(av) + 1;
			   if (SvRMAGICAL((SV*)av)) {
				   /* Tied, so the cells are not in AvARRAY -- which is NULL,
				    * while av_len reports the tied FETCHSIZE, so the branch
				    * below would read off a null pointer.  av_fetch hands back
				    * a deferred PVLV rather than the value, and SvOK on that is
				    * false until its get-magic runs: without SvGETMAGIC every
				    * element of a tied array looks undefined and this croaks
				    * on data that is perfectly well defined. */
				   for (size_t j = 0; j < len; j++) {
					   SV** restrict tv = av_fetch(av, j, 0);
					   if (tv) SvGETMAGIC(*tv);
					   if (tv && SvOK(*tv)) {
						   nums[k++] = SvNV(*tv);
					   } else {
						   if (nums != stackbuf) Safefree(nums);
						   /* UVuf, not %zu: croak() runs perl's own formatter, which does not
						    * understand the C99 z modifier and prints it literally on older
						    * perls (5.10 and 5.12 both do) */
						   croak("median: undefined value at array ref index %" UVuf " (argument %" UVuf ")", (UV)j, (UV)i);
					   }
				   }
			   } else {
				   /* AvARRAY, not av_fetch: the length is known and the cells
				    * are right there, so the bounds check and the call per
				    * element buy nothing */
				   SV** restrict src = AvARRAY(av);
				   for (size_t j = 0; j < len; j++) {
					   SV* restrict tv = src[j];
					   if (tv && SvOK(tv)) {
						   nums[k++] = SvNV(tv);
					   } else {
						   if (nums != stackbuf) Safefree(nums);
						   croak("median: undefined value at array ref index %" UVuf " (argument %" UVuf ")", (UV)j, (UV)i);
					   }
				   }
			   }
		   } else if (SvOK(arg)) {
			   nums[k++] = SvNV(arg);
		   } else {
			   if (nums != stackbuf) Safefree(nums);
			   croak("median: undefined value at argument index %" UVuf, (UV)i);
		   }
	  }
	  /* Select the middle value(s) rather than sorting all of them.  For an
	   * even count the lower of the pair is the largest value left below the
	   * upper one, which a scan of that side finds without a second select. */
	  if (total_count & 1) {
		   nv_select(nums, total_count, total_count / 2);
		   median_val = nums[total_count / 2];
	  } else {
		   const size_t up = total_count / 2;
		   nv_select(nums, total_count, up);
		   NV lower = nums[0];
		   for (size_t i = 1; i < up; i++) if (nums[i] > lower) lower = nums[i];
		   median_val = (lower + nums[up]) / 2.0;
	  }
	  if (nums != stackbuf) Safefree(nums);
	  RETVAL = median_val;
	OUTPUT:
	  RETVAL

void intersection(...)
	PROTOTYPE: @
	PPCODE:
		if (items == 0)
			croak("intersection needs >= 1 array ref");
		SP = set_multiplicity(aTHX_ SP, &ST(0), (size_t)items, 1, 0,
		                      "intersection", GIMME_V);

SV* cor(SV* x_sv, SV* y_sv = &PL_sv_undef, const char* method = "pearson")
	INIT:
	// --- validate method
	if (strcmp(method, "pearson")  != 0 &&
		strcmp(method, "spearman") != 0 &&
		strcmp(method, "kendall")  != 0)
		  croak("cor: unknown method '%s' (use 'pearson', 'spearman', or 'kendall')",
				method);

	// --- validate x
	if (!SvROK(x_sv) || SvTYPE(SvRV(x_sv)) != SVt_PVAV)
		  croak("cor: x must be an ARRAY reference");

	AV*restrict x_av = (AV*)SvRV(x_sv);
	size_t nx   = av_len(x_av) + 1;
	if (nx == 0) croak("cor: x is empty");

	// --- detect whether x is a flat vector or a matrix (AoA)
	bool x_is_matrix = 0;
	{
		SV**restrict fp = av_fetch(x_av, 0, 0);
		if (fp && SvROK(*fp) && SvTYPE(SvRV(*fp)) == SVt_PVAV)
			x_is_matrix = 1;
	}

	// --- detect y
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
			// cor(vector) == 1 by definition
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
		// Upper triangle + diagonal, then mirror. r_cache[i][j] (j >= i) holds the computed value
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
	} else if (items % 2 == 0) {// NAMED: matrix(data => [...], nrow => $n, ncol => $m)
		for (unsigned i = 0; i < items; i += 2) {
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

SV *lm(...)
	CODE:
	{
		const char *restrict formula = NULL;
		SV   *restrict data_sv = NULL;
		char *restrict f_cpy   = NULL;
		char *restrict lhs = NULL, *restrict rhs = NULL;
		char **restrict terms = NULL, **restrict uniq_terms = NULL;
		LmDesign *restrict design = NULL;
		unsigned int num_terms = 0, num_uniq = 0, p = 0;
		size_t n = 0, valid_n = 0, i, j, k;
		bool has_intercept = TRUE;
		char **restrict row_names = NULL, **restrict valid_row_names = NULL;
		HV  **restrict row_hashes = NULL;
		HV   *restrict data_hoa = NULL;
		NV   *restrict X = NULL, *restrict Y = NULL, *restrict XtX = NULL, *restrict XtY = NULL;
		bool *restrict aliased = NULL;
		NV   *restrict beta = NULL;
		int   final_rank = 0, df_res = 0;
		HV   *restrict res_hv, *restrict coef_hv, *restrict fitted_hv, *restrict resid_hv, *restrict summary_hv;
		AV   *restrict terms_av;
		HV   *restrict xlevels_hv = NULL;
		NV    rss = 0.0, rse_sq = 0.0;

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

		/* Split the formula before touching the data: a malformed one croaks
		 * with nothing else allocated. '.' needs the columns, so the term list
		 * has to wait until after the rows are read. */
		f_cpy = lm_formula_split(aTHX_ formula, "lm", &lhs, &rhs, &has_intercept);
		n = lm_read_rows(aTHX_ data_sv, "lm", f_cpy, &data_hoa, &row_hashes, &row_names);
		lm_formula_terms(aTHX_ rhs, lhs, data_hoa, row_hashes, n, has_intercept, "lm",
		                 &terms, &num_terms, &uniq_terms, &num_uniq);
			xlevels_hv = newHV(); sv_2mortal((SV*)xlevels_hv);
		design = lm_design_build(aTHX_ data_hoa, row_hashes, n,
		                         uniq_terms, num_uniq, has_intercept, xlevels_hv);
		p = design->ncol;
		Newx(X, n * (p ? p : 1), NV); Newx(Y, n, NV);
		Newx(valid_row_names, n, char*);

		for (i = 0; i < n; i++) {
			NV y_val = evaluate_term(aTHX_ data_hoa, row_hashes, i, lhs);
			if (isnan(y_val)) { Safefree(row_names[i]); continue; }

			if (!lm_design_row(aTHX_ design, data_hoa, row_hashes, i,
			                   X + valid_n * (size_t)p)) {
				Safefree(row_names[i]); continue;
			}
			Y[valid_n] = y_val;
			valid_row_names[valid_n] = row_names[i];
			valid_n++;
		}
		Safefree(row_names);

		if (valid_n <= p) {
			for (i = 0; i < num_terms; i++) Safefree(terms[i]); Safefree(terms);
			for (i = 0; i < num_uniq; i++) Safefree(uniq_terms[i]); Safefree(uniq_terms);
			lm_design_free(aTHX_ design);
			for (i = 0; i < valid_n; i++) Safefree(valid_row_names[i]);
			Safefree(X); Safefree(Y); Safefree(valid_row_names);
			if (row_hashes) Safefree(row_hashes);
			Safefree(f_cpy);
			croak("lm: 0 degrees of freedom (too many NAs or parameters > observations)");
		}
		Safefree(f_cpy); f_cpy = NULL;

		if (valid_n < n) Renew(X, valid_n * (size_t)p, NV);

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
				f_pvalue = pf_upper(f_stat, (NV)numdf, (NV)df_res);
			} else if (rse_sq == 0.0) {
				f_stat   = INFINITY;
				f_pvalue = 0.0;
			}
		} else if (final_rank == df_int) {
			r_squared = 0.0; adj_r_squared = 0.0;
		}
		for (j = 0; j < p; j++) {
			const char *restrict cname = design->col[j].name;
			hv_store(coef_hv, cname, strlen(cname), newSVnv(beta[j]), 0);
			av_push(terms_av, newSVpv(cname, 0));
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
			hv_store(summary_hv, cname, strlen(cname), newRV_noinc((SV*)row_hv), 0);
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
		hv_store(res_hv, "xlevels",       7, newRV_inc((SV*)xlevels_hv), 0);
		if (!isnan(f_stat)) {
			AV *fstat_av = newAV();
			av_push(fstat_av, newSVnv(f_stat));
			av_push(fstat_av, newSViv(numdf));
			av_push(fstat_av, newSViv(df_res));
			hv_store(res_hv, "fstatistic", 10, newRV_noinc((SV*)fstat_av), 0);
			hv_store(res_hv, "f.pvalue",    8, newSVnv(f_pvalue),          0);
		}
		for (i = 0; i < num_terms; i++) Safefree(terms[i]); Safefree(terms);
		for (i = 0; i < num_uniq; i++) Safefree(uniq_terms[i]); Safefree(uniq_terms);
		lm_design_free(aTHX_ design);
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
		if (by == 0.0) {//Handle the zero 'by' case
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
	SV *orig_data_sv = data_sv; // dropped `restrict` — this aliases data_sv (UB)
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
				SSize_t len = av_len(arr);           // signed — av_len is -1 when empty
				for (SSize_t k = 0; k <= len; k++) { // SSize_t, no SIZE_MAX underflow
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
				  n = (size_t)HvUSEDKEYS(hv);     /* CHANGED: real key count, not hv_iterinit's return */
				  hv_iterinit(hv);
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
			SSize_t ncols = av_len(cols);                  /* CHANGED: signed bound */
			for (SSize_t c = 0; c <= ncols; c++) {          /* CHANGED: SSize_t loop */
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

	HV *restrict xlevels_hv = newHV();   /* NEW: factor base -> [sorted levels], idx 0 = reference */

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
			snprintf(right, sizeof(right), "%s", colon + 1);   /* CHANGED: snprintf, was strcpy (overflow) */

			int *restrict l_indices = (int*)safemalloc(p_exp * sizeof(int)); int l_count = 0;
			int *restrict r_indices = (int*)safemalloc(p_exp * sizeof(int)); int r_count = 0;
			for (size_t e = 0; e < p_exp; e++) {
				if (strcmp(parent_term[e], left) == 0) l_indices[l_count++] = e;
				if (strcmp(parent_term[e], right) == 0) r_indices[r_count++] = e;
			}

			if (l_count == 0 || r_count == 0) {
				Safefree(l_indices); Safefree(r_indices);
				SvREFCNT_dec((SV*)xlevels_hv);   /* NEW */
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

					 /* NEW: expose full sorted level list for predict (idx 0 = reference) */
					 {
						 AV *restrict lv_av = newAV();
						 for (size_t l = 0; l < num_levels; l++)
							 av_push(lv_av, newSVpv(levels[l], 0));
						 hv_store(xlevels_hv, uniq_terms[j], (I32)strlen(uniq_terms[j]),
							 newRV_noinc((SV*)lv_av), 0);
					 }

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
	NV **restrict Dsav = (NV**)safemalloc(n * sizeof(NV*));   /* NEW: preserved design rows for fitted.values */
	char **restrict surv_names = NULL;                        /* NEW: row names of surviving rows */
	Newx(surv_names, n ? n : 1, char*);
	Newx(Y, n, NV);
	// PHASE 4: Matrix Construction & Listwise Deletion
	for (i = 0; i < n; i++) {
		NV y_val = evaluate_term(aTHX_ data_hoa, row_hashes, i, lhs);
		if (isnan(y_val)) { Safefree(row_names[i]); row_names[i] = NULL; continue; }
		bool row_ok = TRUE;
		NV *restrict row_x = X_mat[valid_n];   /* CHANGED: build straight into the QR row (no per-row temp) */
		for (j = 0; j < p_exp; j++) {
			if (strcmp(exp_terms[j], "Intercept") == 0) {
				row_x[j] = 1.0;
			} else if (is_interact[j]) {
				row_x[j] = row_x[left_idx[j]] * row_x[right_idx[j]];   /* left/right already filled this row */
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
		if (!row_ok) { Safefree(row_names[i]); row_names[i] = NULL; continue; }  /* X_mat[valid_n] reused next iter */
		Y[valid_n] = y_val;
		Dsav[valid_n] = (NV*)safemalloc(p_exp * sizeof(NV));   /* NEW: snapshot before QR destroys X_mat */
		memcpy(Dsav[valid_n], row_x, p_exp * sizeof(NV));
		surv_names[valid_n] = row_names[i];                    /* NEW: transfer ownership */
		row_names[i] = NULL;
		valid_n++;
	}
	Safefree(row_names);   /* entries either transferred to surv_names or already freed */
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
		for (i = 0; i < valid_n; i++) Safefree(Dsav[i]);   /* NEW */
		Safefree(Dsav);                                     /* NEW */
		for (i = 0; i < valid_n; i++) Safefree(surv_names[i]);   /* NEW */
		Safefree(surv_names);                                    /* NEW */
		SvREFCNT_dec((SV*)xlevels_hv);                      /* NEW: ret_hash doesn't exist on this path */
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
			hv_stores(term_stats, "Pr(>F)", newSVnv(pf_upper(f_val, (NV)df, (NV)res_df)));
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
		SSize_t ncols = av_len(all_cols);                  /* CHANGED: signed bound */
		for (SSize_t c = 0; c <= ncols; c++) {              /* CHANGED: SSize_t loop */
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
	//
	// NEW: predict-compatible output -- coefficients, fitted.values, xlevels, family
	// X_mat now holds R (rows 0..rank-1, original column index, original units);
	// Y holds Q'y (effects in y[0..rank-1]). Recover beta by back-substitution.
	//
	{
		size_t *restrict col_of_rank = (size_t*)safemalloc((rank ? (size_t)rank : 1) * sizeof(size_t));
		NV     *restrict beta        = (NV*)safemalloc((p_exp ? p_exp : 1) * sizeof(NV));
		for (j = 0; j < p_exp; j++) {
			beta[j] = NAN;
			if (!aliased_qr[j]) col_of_rank[rank_map[j]] = j;   /* rank row -> actual column */
		}
		for (size_t mi = (size_t)rank; mi-- > 0; ) {            /* unsigned countdown */
			size_t km = col_of_rank[mi];
			NV acc = Y[mi];
			for (size_t l = mi + 1; l < (size_t)rank; l++) {
				size_t kl = col_of_rank[l];
				acc -= X_mat[mi][kl] * beta[kl];                /* R[mi][kl] * beta[kl] */
			}
			beta[km] = acc / X_mat[mi][km];                     /* diagonal nonzero by construction */
		}

		HV *restrict coef_hv = newHV();
		for (j = 0; j < p_exp; j++)
			hv_store(coef_hv, exp_terms[j], (I32)strlen(exp_terms[j]), newSVnv(beta[j]), 0);
		hv_stores(ret_hash, "coefficients", newRV_noinc((SV*)coef_hv));

		/* fitted.values: Xb over non-aliased columns, keyed by surviving row name */
		HV *restrict fitted_hv = newHV();
		for (i = 0; i < valid_n; i++) {
			NV fit = 0.0;
			for (j = 0; j < p_exp; j++)
				if (!aliased_qr[j]) fit += Dsav[i][j] * beta[j];
			hv_store(fitted_hv, surv_names[i], (I32)strlen(surv_names[i]), newSVnv(fit), 0);
		}
		hv_stores(ret_hash, "fitted.values", newRV_noinc((SV*)fitted_hv));

		hv_stores(ret_hash, "xlevels", newRV_noinc((SV*)xlevels_hv));
		hv_stores(ret_hash, "family",  newSVpvn("gaussian", 8));

		Safefree(col_of_rank);
		Safefree(beta);
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
	for (i = 0; i < valid_n; i++) Safefree(Dsav[i]);        /* NEW */
	Safefree(Dsav);                                          /* NEW */
	for (i = 0; i < valid_n; i++) Safefree(surv_names[i]);   /* NEW */
	Safefree(surv_names);                                    /* NEW */
	Safefree(aliased_qr); Safefree(rank_map);
	for (i = 0; i < num_uniq; i++) { if (term_base_level[i]) Safefree(term_base_level[i]); }
	Safefree(term_base_level);
	if (row_hashes) Safefree(row_hashes);
	/* xlevels_hv ownership transferred to ret_hash; do not dec here */
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
	/* Derive the default through Perl's own number parser so it is the exact
	 * nearest NV to 0.95 in every build (double, long double, or __float128).
	 * A bare 0.95 mismatches on long-double builds and 0.95L mismatches on
	 * quadmath builds; either way the echoed default would fail to stringify
	 * back to "0.95". SvNV("0.95") is identical to the Perl-side literal 0.95. */
	NV conf_level = SvNV(sv_2mortal(newSVpvs("0.95")));
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
	if (!SvROK(data_ref)) croak("fisher_test requires a reference to a 2D Array or Hash");
	SV *restrict deref = SvRV(data_ref);

	/* Parse the input into a flat nrow x ncol table of nonnegative counts.
	 * Both a 2D array-of-arrays and a 2D hash-of-hashes are accepted, and any
	 * dimensions >= 2x2 are supported (2x2 keeps the exact odds-ratio path;
	 * everything else uses the R x C enumeration below). */
	unsigned nrow = 0, ncol = 0;
	long *restrict cells = NULL;

	if (SvTYPE(deref) == SVt_PVAV) {
	  AV *restrict outer = (AV *)deref;
	  nrow = (int)(av_len(outer) + 1);
	  if (nrow < 2) croak("Outer array must have at least 2 rows");
	  SV **restrict r0p = av_fetch(outer, 0, 0);
	  if (!r0p || !SvROK(*r0p) || SvTYPE(SvRV(*r0p)) != SVt_PVAV)
		   croak("Invalid 2D array structure: each row must be an array ref");
	  ncol = (int)(av_len((AV *)SvRV(*r0p)) + 1);
	  if (ncol < 2) croak("Each row must have at least 2 columns");
	  Newx(cells, (size_t)nrow * ncol, long);
	  for (unsigned int rr = 0; rr < nrow; rr++) {
		   SV **restrict rp = av_fetch(outer, rr, 0);
		   if (!rp || !SvROK(*rp) || SvTYPE(SvRV(*rp)) != SVt_PVAV) {
			   Safefree(cells);
			   croak("Invalid 2D array structure: each row must be an array ref");
		   }
		   AV *restrict row = (AV *)SvRV(*rp);
		   if ((int)(av_len(row) + 1) != ncol) {
			   Safefree(cells);
			   croak("All rows must have the same number of columns (%d)", ncol);
		   }
		   for (int cc = 0; cc < ncol; cc++)
			   cells[rr * ncol + cc] = ft_cell(aTHX_ *av_fetch(row, cc, 0), "array cell");
	  }
	} else if (SvTYPE(deref) == SVt_PVHV) {
	  /* Rows are ordered by lexical key sort, and columns by the sorted keys
		* of the first row, so the result is deterministic regardless of
		* Perl's hash randomization.  Every row must expose that same column
		* key set. */
	  HV *restrict outer = (HV *)deref;
	  nrow = (int)HvUSEDKEYS(outer);
	  if (nrow < 2) croak("Outer hash must have at least 2 keys");
	  ft_kv *restrict rows = NULL; Newx(rows, nrow, ft_kv);
	  hv_iterinit(outer);
	  for (unsigned int i = 0; i < nrow; i++) {
		   HE *restrict e = hv_iternext(outer);
		   rows[i].k = SvPV_nolen(hv_iterkeysv(e));
		   rows[i].v = hv_iterval(outer, e);
	  }
	  qsort(rows, nrow, sizeof(ft_kv), ft_kv_cmp);

	  if (!SvROK(rows[0].v) || SvTYPE(SvRV(rows[0].v)) != SVt_PVHV) {
		   Safefree(rows); croak("Inner elements must be hash refs");
	  }
	  HV *restrict first = (HV *)SvRV(rows[0].v);
	  ncol = (int)HvUSEDKEYS(first);
	  if (ncol < 2) { Safefree(rows); croak("Inner hashes must have at least 2 keys"); }
	  ft_kv *restrict cols = NULL; Newx(cols, ncol, ft_kv);
	  hv_iterinit(first);
	  for (unsigned int j = 0; j < ncol; j++) {
		   HE *restrict e = hv_iternext(first);
		   cols[j].k = SvPV_nolen(hv_iterkeysv(e));
		   cols[j].v = NULL;
	  }
	  qsort(cols, ncol, sizeof(ft_kv), ft_kv_cmp);

	  Newx(cells, (size_t)nrow * ncol, long);
	  for (unsigned int rr = 0; rr < nrow; rr++) {
		   if (!SvROK(rows[rr].v) || SvTYPE(SvRV(rows[rr].v)) != SVt_PVHV) {
			   Safefree(cells); Safefree(cols); Safefree(rows);
			   croak("Inner elements must be hash refs");
		   }
		   HV *restrict in = (HV *)SvRV(rows[rr].v);
		   if ((int)HvUSEDKEYS(in) != ncol) {
			   Safefree(cells); Safefree(cols); Safefree(rows);
			   croak("All rows must have the same %d column keys", ncol);
		   }
		   for (unsigned int cc = 0; cc < ncol; cc++) {
			   SV **restrict vp = hv_fetch(in, cols[cc].k, (I32)strlen(cols[cc].k), 0);
			   if (!vp) {
/* Capture the key pointers (they point into still-live mortal SV
 * buffers, not into rows/cols) before freeing the arrays --
 * otherwise croak() reads freed memory, which SIGBUSes on
 * strict allocators such as FreeBSD's. */
				   const char *restrict rk = rows[rr].k;
				   const char *restrict ck = cols[cc].k;
				   Safefree(cells); Safefree(cols); Safefree(rows);
				   croak("Row '%s' is missing column key '%s'", rk, ck);
			   }
			   cells[rr * ncol + cc] = ft_cell(aTHX_ *vp, "hash cell");
		   }
	  }
	  Safefree(cols); Safefree(rows);
	} else {
	  croak("Input must be a 2D Array or 2D Hash");
	}

	long total = 0;
	for (unsigned int i = 0; i < nrow * ncol; i++) total += cells[i];
	if (total == 0) { Safefree(cells); croak("fisher_test: table is all zeros"); }

	HV *restrict ret = newHV();
	hv_stores(ret, "method", newSVpv("Fisher's Exact Test for Count Data", 0));
	hv_stores(ret, "conf_level", newSVnv(conf_level));

	if (nrow == 2 && ncol == 2) {
	  /* 2x2: full exact test with the conditional MLE odds ratio and CI. */
	  long a = cells[0], b = cells[1], c = cells[2], d = cells[3];
	  NV p_val = exact_p_value(a, b, c, d, alternative);
	  NV mle_or, ci_low, ci_high;
	  calculate_exact_stats(a, b, c, d, conf_level, alternative, &mle_or, &ci_low, &ci_high);
	  hv_stores(ret, "alternative", newSVpv(alternative, 0));
	  AV *restrict ci = newAV();
	  av_push(ci, newSVnv(ci_low));
	  av_push(ci, newSVnv(ci_high));
	  hv_stores(ret, "conf_int", newRV_noinc((SV *)ci));
	  HV *restrict est = newHV();
	  hv_stores(est, "odds ratio", newSVnv(mle_or));
	  hv_stores(ret, "estimate", newRV_noinc((SV *)est));
	  hv_stores(ret, "p_value", newSVnv(p_val));
	} else {
	  /* R x C: only the two-sided p-value is defined (no odds ratio / CI). */
	  NV p_val = fisher_rxc_pvalue(aTHX_ cells, nrow, ncol);
	  if (p_val < 0) {
		   Safefree(cells);
		   croak("fisher_test: %dx%d table is too large for exact enumeration", nrow, ncol);
	  }
	  hv_stores(ret, "alternative", newSVpv("two.sided", 0));
	  hv_stores(ret, "p_value", newSVnv(p_val));
	}
	Safefree(cells);
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
	/* R's default is .Machine$double.eps^0.25 (1.2e-4) on uniroot's bracket
	 * width, which leaves its own delta and sig.level good to four or five
	 * digits. ptt_root() converges superlinearly, so a tolerance this tight
	 * costs a couple of extra p_body() calls and still runs in fewer than the
	 * bisection it replaced. */
	NV tol = 1e-12;

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

	/* R's assert_NULL_or_prob(): a probability outside [0, 1] is a typo, not a
	 * place to start searching from. power => 1.5 used to run the n bracket out
	 * to 1.3e12 and hand that back as the required sample size. */
	if (!is_null_sig_level && !(sig_level >= 0.0 && sig_level <= 1.0))
	  croak("power_t_test: 'sig_level' must be numeric in [0, 1]");
	if (!is_null_power && !(power >= 0.0 && power <= 1.0))
	  croak("power_t_test: 'power' must be numeric in [0, 1]");
	/* nu = (n - 1) * tsample, so below n = 2 there is no variance left to
	 * estimate: the critical value runs off to infinity and exact_pnt()'s grid
	 * loses the whole chi density, which is how n => 1 used to report a power
	 * of 0.99998. R hides the same degeneracy behind pmax(1e-07, n - 1) and
	 * returns a power of 0; saying so outright is more use than either number. */
	/* croak() formats through Perl, not the C library, so an NV needs NVgf
	 * ("g", "Lg", or "Qg") rather than a bare %g: a quadmath build rejects a
	 * format without the Q modifier outright ("panic: quadmath invalid
	 * format"), and casting the argument to double cannot rescue it.
	 * croak_nv() (see the top of this file) is croak() minus the format
	 * attribute, which the compiler's format checker mis-flags on "Qg". */
	if (!is_null_n && !(n >= 2.0))
	  croak_nv("power_t_test: 'n' must be at least 2, not %" NVgf, n);
	if (!is_null_sd && sd < 0.0)
	  croak_nv("power_t_test: 'sd' must not be negative, not %" NVgf, sd);

	/* R reaches these through match.arg(), so a misspelling is an error there.
	 * Silently reading an unrecognised type as "two.sample" turned every typo
	 * into a plausible-looking answer for the wrong test. */
	short int tsample;
	if      (strEQ(type, "two.sample")) tsample = 2;
	else if (strEQ(type, "one.sample") || strEQ(type, "paired")) tsample = 1;
	else croak("power_t_test: 'type' must be 'two.sample', 'one.sample', or 'paired', not '%s'", type);

	short int tside;
	if      (strEQ(alternative, "two.sided")) tside = 2;
	else if (strEQ(alternative, "one.sided") || strEQ(alternative, "greater")
			  || strEQ(alternative, "less")) tside = 1;
	else croak("power_t_test: 'alternative' must be 'two.sided', 'one.sided', 'greater', or 'less', not '%s'", alternative);

	if (tside == 2 && !is_null_delta) delta = fabs(delta);

	ptt_ctx c;
	c.n = n; c.delta = delta; c.sd = sd; c.sig_level = sig_level;
	c.tsample = tsample; c.tside = tside; c.strict = strict; c.target = power;

	if (is_null_power) {
	  power = p_body(n, delta, sd, sig_level, tsample, tside, strict);
	} else if (is_null_n) {
	  /* power rises with n; R's bracket is c(2, 1e7), grown upward as needed */
	  c.which = PTT_N;
	  NV low = 2.0, high = 1e7;
	  while (high < 1e12 && ptt_f(&c, high) < 0.0) high *= 2.0;
	  n = ptt_root(&c, low, high, tol);
	  if (n != n) croak_nv("power_t_test: no 'n' in [%" NVgf ", %" NVgf "] gives a power of %" NVgf " "
			  "(delta = %" NVgf ", sd = %" NVgf ", sig_level = %" NVgf ")",
			  low, high, power, delta, sd, sig_level);
	} else if (is_null_sd) {
	  /* power falls as sd rises. The bracket scales with |delta|, so a delta of
	   * 0 collapses it to a single point -- R fails there with "lower < upper is
	   * not fulfilled"; this says why. */
	  if (delta == 0.0) croak("power_t_test: cannot solve for 'sd' when 'delta' is 0");
	  c.which = PTT_SD;
	  NV ad = fabs(delta), low = ad * 1e-7, high = ad * 1e7;
	  while (high < ad * 1e12 && ptt_f(&c, high) > 0.0) high *= 2.0;
	  while (low > ad * 1e-12 && ptt_f(&c, low) < 0.0) low *= 0.5;
	  sd = ptt_root(&c, low, high, tol);
	  if (sd != sd) croak_nv("power_t_test: no 'sd' in [%" NVgf ", %" NVgf "] gives a power of %" NVgf " "
			  "(n = %" NVgf ", delta = %" NVgf ", sig_level = %" NVgf ")",
			  low, high, power, n, delta, sig_level);
	} else if (is_null_delta) {
	  if (!(sd > 0.0)) croak("power_t_test: cannot solve for 'delta' unless 'sd' is positive");
	  c.which = PTT_DELTA;
	  NV low = sd * 1e-7, high = sd * 1e7;
	  while (high < sd * 1e12 && ptt_f(&c, high) < 0.0) high *= 2.0;
	  delta = ptt_root(&c, low, high, tol);
	  if (delta != delta) croak_nv("power_t_test: no 'delta' in [%" NVgf ", %" NVgf "] gives a power of %" NVgf " "
			  "(n = %" NVgf ", sd = %" NVgf ", sig_level = %" NVgf ")",
			  low, high, power, n, sd, sig_level);
	} else { /* is_null_sig_level */
	  /* A significance level is a probability, so unlike the others this bracket
	   * cannot be widened. R widens it anyway (extendInt = "yes") and will
	   * happily return a sig.level above 1; refusing is the honest answer. */
	  c.which = PTT_SIG;
	  sig_level = ptt_root(&c, 1e-10, 1.0 - 1e-10, tol);
	  if (sig_level != sig_level) croak_nv("power_t_test: no 'sig_level' in (0, 1) gives a power of %" NVgf " "
			  "(n = %" NVgf ", delta = %" NVgf ", sd = %" NVgf ")",
			  power, n, delta, sd);
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
		k = group_id; // number of unique groups = number of hash keys
	} else {// 4b. Original x / g array-pair input path
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
	bool has_ties = 0;
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
		
		if (SvTYPE(rv) == SVt_PVHV) {// HASH REFERENCE
			HV *restrict hv    = (HV *)rv;
			unsigned count = hv_iterinit(hv);
			unsigned limit = (n < (IV)count) ? (I32)n : count;
			HV *restrict ret_hv = newHV();

			if (count > 0 && limit > 0) {
				HE **restrict entries;
				HE  *restrict entry;
				unsigned i;
				Newx(entries, count, HE *);
				i = 0;
				while ((entry = hv_iternext(hv))) // Collect all HE pointers in one pass
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

void merge(...)
PPCODE:
{
	if (items < 2)
		croak("Usage: merge($left, $right, how => 'inner'|'left'|'right'|"
		      "'outer'|'cross', on => 'col' | ['c1','c2'] "
		      "[, 'left.on' => .., 'right.on' => ..] "
		      "[, suffixes => ['.x','.y']] [, 'output.type' => 'aoh'|'hoa'])");
	if ((items - 2) & 1)
		croak("merge: options after the two frames must be name => value pairs");

	SV *restrict left  = ST(0);
	SV *restrict right = ST(1);

	SV *restrict how_sv = NULL, *restrict on_sv = NULL;
	SV *restrict lon_sv = NULL, *restrict ron_sv = NULL;
	SV *restrict suf_sv = NULL, *restrict out_sv = NULL;
	for (int oi = 2; oi < items; oi += 2) {
		STRLEN ol;
		const char *restrict on = SvPV(ST(oi), ol);
		SV *restrict ov = ST(oi + 1);
		if      (strEQ(on, "how"))                              how_sv = ov;
		else if (strEQ(on, "on") || strEQ(on, "by"))            on_sv  = ov;
		else if (strEQ(on, "left.on")  || strEQ(on, "left_on")
		      || strEQ(on, "by.x"))                             lon_sv = ov;
		else if (strEQ(on, "right.on") || strEQ(on, "right_on")
		      || strEQ(on, "by.y"))                             ron_sv = ov;
		else if (strEQ(on, "suffixes"))                         suf_sv = ov;
		else if (strEQ(on, "output.type") || strEQ(on, "output_type")
		      || strEQ(on, "out"))                              out_sv = ov;
		else croak("merge: unknown option '%s'", on);
	}

	/* how */
	int how = MG_INNER;
	if (how_sv && SvOK(how_sv)) {
		const char *restrict h = SvPV_nolen(how_sv);
		if      (strEQ(h, "inner"))                 how = MG_INNER;
		else if (strEQ(h, "left"))                  how = MG_LEFT;
		else if (strEQ(h, "right"))                 how = MG_RIGHT;
		else if (strEQ(h, "outer") || strEQ(h, "full")) how = MG_OUTER;
		else if (strEQ(h, "cross"))                 how = MG_CROSS;
		else croak("merge: how must be 'inner', 'left', 'right', 'outer', or "
		           "'cross' (got '%s')", h);
	}

	if (on_sv && (lon_sv || ron_sv))
		croak("merge: give either 'on'/'by' or 'left.on'/'right.on', not both");
	if ((lon_sv && !ron_sv) || (ron_sv && !lon_sv))
		croak("merge: 'left.on' and 'right.on' must be given together");
	if (how == MG_CROSS && (on_sv || lon_sv || ron_sv))
		croak("merge: a cross join takes no join keys");

	ENTER; SAVETMPS;

	/* suffixes */
	SV *restrict suf0 = NULL, *restrict suf1 = NULL;
	if (suf_sv) {
		if (!SvROK(suf_sv) || SvTYPE(SvRV(suf_sv)) != SVt_PVAV
		    || av_len((AV *)SvRV(suf_sv)) != 1)
			croak("merge: suffixes must be a two-element array-ref, e.g. ['.x','.y']");
		AV *restrict sa = (AV *)SvRV(suf_sv);
		suf0 = *av_fetch(sa, 0, 0);
		suf1 = *av_fetch(sa, 1, 0);
	} else {
		suf0 = sv_2mortal(newSVpvs(".x"));
		suf1 = sv_2mortal(newSVpvs(".y"));
	}

	/* default output shape follows the left frame */
	int def_shape = SvROK(left) ? mg_shape(aTHX_ left) : 0;
	int out_hoa = (def_shape == 1);		/* AoH & HoH default to AoH */
	if (out_sv && SvOK(out_sv)) {
		const char *restrict os = SvPV_nolen(out_sv);
		if      (strEQ(os, "aoh")) out_hoa = 0;
		else if (strEQ(os, "hoa")) out_hoa = 1;
		else croak("merge: output.type must be 'aoh' or 'hoa' (got '%s')", os);
	}

	mg_frame Lf, Rf;
	mg_prep(aTHX_ left,  "left",  &Lf);
	mg_prep(aTHX_ right, "right", &Rf);
	SSize_t nL = Lf.nrows;
	SSize_t nR = Rf.nrows;
	AV *restrict Lall  = Lf.names, *restrict Rall  = Rf.names;
	HV *restrict Lseen = Lf.seen,  *restrict Rseen = Rf.seen;

	/* resolve join keys into lkeys / rkeys */
	AV *restrict lkeys, *restrict rkeys;
	if (how == MG_CROSS) {
		lkeys = (AV *)sv_2mortal((SV *)newAV());
		rkeys = (AV *)sv_2mortal((SV *)newAV());
	} else if (lon_sv) {
		lkeys = mg_names(aTHX_ lon_sv);
		rkeys = mg_names(aTHX_ ron_sv);
		if (av_len(lkeys) != av_len(rkeys))
			croak("merge: 'left.on' and 'right.on' must name the same number of columns");
	} else if (on_sv) {
		lkeys = mg_names(aTHX_ on_sv);
		rkeys = lkeys;
	} else {
		/* natural join: sorted intersection of column names. Gather the
		 * shared names (aliases into Lall), insertion-sort the pointers,
		 * then copy them into lkeys. */
		lkeys = (AV *)sv_2mortal((SV *)newAV());
		SSize_t na = av_len(Lall) + 1;
		SV **restrict names;
		Newx(names, (size_t)(na > 0 ? na : 1), SV *);
		SAVEFREEPV(names);
		SSize_t cnt = 0;
		for (SSize_t i = 0; i < na; i++) {
			SV *restrict kn = *av_fetch(Lall, i, 0);
			if (hv_exists_ent(Rseen, kn, 0)) names[cnt++] = kn;
		}
		if (cnt == 0)
			croak("merge: no common columns to join on; pass 'on' or "
			      "'left.on'/'right.on'");
		for (SSize_t a = 1; a < cnt; a++) {
			SV *restrict cur = names[a];
			STRLEN al; const char *restrict ap = SvPV_const(cur, al);
			SSize_t b = a - 1;
			while (b >= 0) {
				STRLEN bl; const char *restrict bp = SvPV_const(names[b], bl);
				int cmp = memcmp(bp, ap, bl < al ? bl : al);
				if (cmp == 0) cmp = (bl > al) - (bl < al);
				if (cmp <= 0) break;
				names[b + 1] = names[b];
				b--;
			}
			names[b + 1] = cur;
		}
		for (SSize_t c = 0; c < cnt; c++) av_push(lkeys, newSVsv(names[c]));
		rkeys = lkeys;
	}
	SSize_t nkeys = av_len(lkeys) + 1;

	/* validate that the named keys exist in each frame */
	for (SSize_t j = 0; j < nkeys; j++) {
		SV *restrict kn = *av_fetch(lkeys, j, 0);
		if (!hv_exists_ent(Lseen, kn, 0))
			croak("merge: left frame has no join column '%s'", SvPV_nolen(kn));
	}
	for (SSize_t j = 0; j < nkeys; j++) {
		SV *restrict kn = *av_fetch(rkeys, j, 0);
		if (!hv_exists_ent(Rseen, kn, 0))
			croak("merge: right frame has no join column '%s'", SvPV_nolen(kn));
	}

	/* key-name sets, to exclude keys from the data-column universe */
	HV *restrict lkset = (HV *)sv_2mortal((SV *)newHV());
	HV *restrict rkset = (HV *)sv_2mortal((SV *)newHV());
	for (SSize_t j = 0; j < nkeys; j++) {
		(void)hv_store_ent(lkset, *av_fetch(lkeys, j, 0), newSViv(1), 0);
		(void)hv_store_ent(rkset, *av_fetch(rkeys, j, 0), newSViv(1), 0);
	}

	/* non-key data columns for each side, plus name-membership sets */
	AV *restrict lc_src = (AV *)sv_2mortal((SV *)newAV());
	HV *restrict lc_set = (HV *)sv_2mortal((SV *)newHV());
	for (SSize_t i = 0, n = av_len(Lall) + 1; i < n; i++) {
		SV *restrict kn = *av_fetch(Lall, i, 0);
		if (hv_exists_ent(lkset, kn, 0)) continue;
		av_push(lc_src, newSVsv(kn));
		(void)hv_store_ent(lc_set, kn, newSViv(1), 0);
	}
	AV *restrict rc_src = (AV *)sv_2mortal((SV *)newAV());
	HV *restrict rc_set = (HV *)sv_2mortal((SV *)newHV());
	for (SSize_t i = 0, n = av_len(Rall) + 1; i < n; i++) {
		SV *restrict kn = *av_fetch(Rall, i, 0);
		if (hv_exists_ent(rkset, kn, 0)) continue;
		av_push(rc_src, newSVsv(kn));
		(void)hv_store_ent(rc_set, kn, newSViv(1), 0);
	}
	SSize_t nlc = av_len(lc_src) + 1;
	SSize_t nrc = av_len(rc_src) + 1;

	/* output column names: overlapping non-key columns get suffixed. Guard
	 * the resulting universe against accidental collisions. */
	AV *restrict lc_out = (AV *)sv_2mortal((SV *)newAV());
	AV *restrict rc_out = (AV *)sv_2mortal((SV *)newAV());
	HV *restrict uni = (HV *)sv_2mortal((SV *)newHV());
	for (SSize_t j = 0; j < nkeys; j++) {
		SV *restrict kn = *av_fetch(lkeys, j, 0);
		if (hv_exists_ent(uni, kn, 0))
			croak("merge: duplicate join column '%s'", SvPV_nolen(kn));
		(void)hv_store_ent(uni, kn, newSViv(1), 0);
	}
	for (SSize_t c = 0; c < nlc; c++) {
		SV *restrict kn = *av_fetch(lc_src, c, 0);
		SV *restrict outn;
		if (hv_exists_ent(rc_set, kn, 0)) {
			outn = newSVsv(kn); sv_catsv(outn, suf0);
		} else outn = newSVsv(kn);
		if (hv_exists_ent(uni, outn, 0))
			croak("merge: output column '%s' collides; adjust 'suffixes'",
			      SvPV_nolen(outn));
		(void)hv_store_ent(uni, outn, newSViv(1), 0);
		av_push(lc_out, outn);
	}
	for (SSize_t c = 0; c < nrc; c++) {
		SV *restrict kn = *av_fetch(rc_src, c, 0);
		SV *restrict outn;
		if (hv_exists_ent(lc_set, kn, 0)) {
			outn = newSVsv(kn); sv_catsv(outn, suf1);
		} else outn = newSVsv(kn);
		if (hv_exists_ent(uni, outn, 0))
			croak("merge: output column '%s' collides; adjust 'suffixes'",
			      SvPV_nolen(outn));
		(void)hv_store_ent(uni, outn, newSViv(1), 0);
		av_push(rc_out, outn);
	}
	/* ---- resolve every column that will be read, once for the whole join ---- */
	SSize_t nu = nkeys + nlc + nrc;
	mg_col *restrict lk, *restrict rk, *restrict lc, *restrict rc;
	SV **restrict oname;
	Newx(lk,    (size_t)(nkeys > 0 ? nkeys : 1), mg_col); SAVEFREEPV(lk);
	Newx(rk,    (size_t)(nkeys > 0 ? nkeys : 1), mg_col); SAVEFREEPV(rk);
	Newx(lc,    (size_t)(nlc   > 0 ? nlc   : 1), mg_col); SAVEFREEPV(lc);
	Newx(rc,    (size_t)(nrc   > 0 ? nrc   : 1), mg_col); SAVEFREEPV(rc);
	Newx(oname, (size_t)(nu    > 0 ? nu    : 1), SV *);   SAVEFREEPV(oname);
	{
		SSize_t o = 0;
		for (SSize_t j = 0; j < nkeys; j++, o++) {
			mg_resolve(aTHX_ &Lf, *av_fetch(lkeys, j, 0), &lk[j]);
			mg_resolve(aTHX_ &Rf, *av_fetch(rkeys, j, 0), &rk[j]);
			oname[o] = mg_shared(aTHX_ *av_fetch(lkeys, j, 0));	/* keys keep the left name */
		}
		for (SSize_t c = 0; c < nlc; c++, o++) {
			mg_resolve(aTHX_ &Lf, *av_fetch(lc_src, c, 0), &lc[c]);
			oname[o] = mg_shared(aTHX_ *av_fetch(lc_out, c, 0));
		}
		for (SSize_t c = 0; c < nrc; c++, o++) {
			mg_resolve(aTHX_ &Rf, *av_fetch(rc_src, c, 0), &rc[c]);
			oname[o] = mg_shared(aTHX_ *av_fetch(rc_out, c, 0));
		}
	}

	/* ---- the output frame, built directly in the shape being returned ---- */
	/* How many rows the join is likely to produce, so the arrays are sized
	 * once instead of doubling their way there.  Only a hint: av_push grows
	 * them if the join returns more, and a cross join is left to grow on its
	 * own rather than reserving nL * nR up front. */
	SSize_t guess = (how == MG_OUTER) ? nL + nR
	              : (how == MG_RIGHT) ? nR
	              : (how == MG_CROSS) ? 0
	              :                     nL;
	if (guess > (SSize_t)1 << 16) guess = (SSize_t)1 << 16;

	AV *restrict result = NULL;			/* AoH output */
	HV *restrict out    = NULL;			/* HoA output */
	AV **restrict ocol  = NULL;
	if (out_hoa) {
		out = newHV();
		Newx(ocol, (size_t)(nu > 0 ? nu : 1), AV *); SAVEFREEPV(ocol);
		for (SSize_t o = 0; o < nu; o++) {
			ocol[o] = newAV();
			if (guess > 0) av_extend(ocol[o], guess - 1);
			/* the hash owns the column from here; ocol[] only borrows it */
			(void)hv_store_ent(out, oname[o], newRV_noinc((SV *)ocol[o]), 0);
		}
	} else {
		result = (AV *)sv_2mortal((SV *)newAV());
		if (guess > 0) av_extend(result, guess - 1);
	}

	mg_join J;
	J.L = &Lf; J.R = &Rf;
	J.lk = lk; J.rk = rk; J.lc = lc; J.rc = rc;
	J.nkeys = nkeys; J.nlc = nlc; J.nrc = nrc;
	J.oname = oname; J.out_hoa = out_hoa;
	J.result = result; J.ocol = ocol;

	/* ---- perform the join ---- */
	if (how == MG_CROSS) {
		for (SSize_t i = 0; i < nL; i++)
			for (SSize_t j = 0; j < nR; j++)
				mg_emit(aTHX_ &J, i, j);
	} else {
		/* Index the right frame: join key -> the first row carrying it, with
		 * the rest of its rows chained through next[].  One IV in the hash
		 * and one slot in a flat array per row, rather than an array-ref of
		 * index SVs per distinct key.  Filling it backwards leaves each chain
		 * in ascending row order, which is the order the rows come out in. */
		HV *restrict ridx = (HV *)sv_2mortal((SV *)newHV());
		SSize_t *restrict next;
		Newx(next, (size_t)(nR > 0 ? nR : 1), SSize_t); SAVEFREEPV(next);
		SV *restrict kbuf = sv_2mortal(newSVpvs(""));	/* reused by every row */

		for (SSize_t j = nR - 1; j >= 0; j--) {
			next[j] = -1;
			if (!mg_key(aTHX_ &Rf, rk, nkeys, j, kbuf)) continue;
			HE *restrict he = hv_fetch_ent(ridx, kbuf, 1, 0);
			SV *restrict slot = HeVAL(he);
			if (SvOK(slot)) next[j] = (SSize_t)SvIV(slot);
			sv_setiv(slot, (IV)j);
		}

		char *restrict matched = NULL;
		if (how == MG_RIGHT || how == MG_OUTER) {
			Newxz(matched, (size_t)(nR > 0 ? nR : 1), char);
			SAVEFREEPV(matched);
		}

		for (SSize_t i = 0; i < nL; i++) {
			int ok = mg_key(aTHX_ &Lf, lk, nkeys, i, kbuf);
			HE *restrict he = ok ? hv_fetch_ent(ridx, kbuf, 0, 0) : NULL;
			if (he) {
				for (SSize_t j = (SSize_t)SvIV(HeVAL(he)); j >= 0; j = next[j]) {
					mg_emit(aTHX_ &J, i, j);
					if (matched) matched[j] = 1;
				}
			} else if (how == MG_LEFT || how == MG_OUTER) {
				mg_emit(aTHX_ &J, i, -1);
			}
		}
		if (matched) {
			for (SSize_t j = 0; j < nR; j++)
				if (!matched[j]) mg_emit(aTHX_ &J, -1, j);
		}
	}

	/* ---- hand it back ---- */
	SV *restrict retval;
	if (out_hoa) {
		retval = newRV_noinc((SV *)out);
	} else {
		SvREFCNT_inc((SV *)result);		/* survive FREETMPS */
		retval = newRV_noinc((SV *)result);
	}

	FREETMPS; LEAVE;
	XPUSHs(sv_2mortal(retval));
	XSRETURN(1);
}

void ljoin(h_ref, i_ref)
	SV *h_ref;
	SV *i_ref;
PREINIT:
	HV *restrict h_hv, *restrict i_hv;
	HE *restrict h_entry;
CODE:
	// 1. Validate inputs are hash references
	if (!SvROK(h_ref) || SvTYPE(SvRV(h_ref)) != SVt_PVHV) {
	  croak("First argument to ljoin must be a hash reference");
	}
	if (!SvROK(i_ref) || SvTYPE(SvRV(i_ref)) != SVt_PVHV) {
	  croak("Second argument to ljoin must be a hash reference");
	}
	h_hv = (HV *)SvRV(h_ref);
	i_hv = (HV *)SvRV(i_ref);
	// 2. Iterate through the primary hash ($h)
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
			size_t len = av_len(av) + 1;
			if (items > 1) {
				// CASE 2b: Array of Hashes (string key) or Array of Arrays (numeric index)
				SV*restrict arg2 = ST(1);
				STRLEN klen;
				const char*restrict key = SvPV(arg2, klen);
				for (unsigned i = 0; i < len; i++) {
					SV**restrict elemp = av_fetch(av, i, 0);
					if (!elemp) continue;
					SV*restrict elem = *elemp;
					if (!SvROK(elem)) {
						SvREFCNT_dec((SV*)counts_hv);
						croak("value_counts: array element %u is not a reference; a HASH ref (Array of Hashes) or ARRAY ref (Array of Arrays) is required when a key/index is given", i);
					}
					SV*restrict inner_rv = SvRV(elem);
					if (SvTYPE(inner_rv) == SVt_PVHV) {// Array of Hashes: extract column by key
						HV*restrict inner_hv = (HV*)inner_rv;
						SV**restrict valp = hv_fetch(inner_hv, key, klen, 0);
						if (valp) increment_count(aTHX_ counts_hv, *valp);// missing key -> skip row
					} else if (SvTYPE(inner_rv) == SVt_PVAV) {// Array of Arrays: extract column by index
						if (!looks_like_number(arg2)) {
							SvREFCNT_dec((SV*)counts_hv);
							croak("value_counts: array element %u is an ARRAY ref but index '%s' is not numeric", i, key);
						}
						AV*restrict inner_av = (AV*)inner_rv;
						SSize_t idx = SvIV(arg2);
						SV**restrict valp = av_fetch(inner_av, idx, 0);
						if (valp) increment_count(aTHX_ counts_hv, *valp);
					} else {
						SvREFCNT_dec((SV*)counts_hv);
						croak("value_counts: unsupported nested reference type in array element %u", i);
					}
				}
			} else {
				// CASE 2a: Flattened/simple array (one value per element)
				for (unsigned i = 0; i < len; i++) {
					SV**restrict valp = av_fetch(av, i, 0);
					if (valp) increment_count(aTHX_ counts_hv, *valp);
				}
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
					size_t len = av_len(av) + 1;
					for (size_t i = 0; i < len; i++) {
						SV**restrict valp = av_fetch(av, i, 0);
						if (valp) increment_count(aTHX_ counts_hv, *valp);
					}
				} else {// Fallback: Row-Oriented nested structure
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
							 size_t len = av_len(inner_av) + 1;
							 for (size_t i = 0; i < len; i++) {
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
		} else {// Safely decrement the reference count of our hash before dying to prevent a leak
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
#define FOR_EACH_FILTER(body) do {                                        \
 for (int _fi = 3; _fi < items && pass_filter; _fi++) {                   \
  SV *restrict _f_ref = ST(_fi);                                          \
  if (!(SvROK(_f_ref) && SvTYPE(SvRV(_f_ref)) == SVt_PVHV)) continue;     \
  HV *restrict _filter_hv = (HV *)SvRV(_f_ref);                           \
  HE *restrict f_he;                                                      \
  hv_iterinit(_filter_hv);                                                \
  while ((f_he = hv_iternext(_filter_hv))) {                              \
   SV *restrict f_col = hv_iterkeysv(f_he);                               \
   SV *restrict f_sub = hv_iterval(_filter_hv, f_he);                     \
   bool keep;                                                             \
   body;                                                                  \
   if (!keep) { pass_filter = 0; break; }                                 \
  }                                                                       \
 }                                                                        \
} while (0)
#define FOR_EACH_FILTER_COL(colvar, body) do {                            \
 for (int _fi = 3; _fi < items; _fi++) {                                  \
  SV *restrict _f_ref = ST(_fi);                                          \
  if (!(SvROK(_f_ref) && SvTYPE(SvRV(_f_ref)) == SVt_PVHV)) continue;     \
  HV *restrict _filter_hv = (HV *)SvRV(_f_ref);                           \
  HE *restrict _fc_he;                                                    \
  hv_iterinit(_filter_hv);                                                \
  while ((_fc_he = hv_iternext(_filter_hv))) {                            \
   SV *restrict colvar = hv_iterkeysv(_fc_he);                            \
   body;                                                                  \
  }                                                                       \
 }                                                                        \
} while (0)
#define GROUP_BY_NO_COL(col_sv) \
 croak("group_by: \"%s\" is not present in the dataset", SvPV_nolen(col_sv))

SV *group_by(data_ref, target_key_sv, group_key_sv, ...)
	SV *data_ref;
	SV *target_key_sv;
	SV *group_key_sv;
PREINIT:
	HV *restrict result_hv;
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
	/* Optional filters are every argument from ST(3) onward. Each must be a
	 * hashref of { column => sub }; all of them are ANDed together. The
	 * FOR_EACH_FILTER macro walks the arg stack directly (rather than collecting
	 * into a heap array) so a croaking filter sub can't leak anything: for each
	 * { column => sub } pair the body it wraps runs with f_col (column-name SV)
	 * and f_sub (sub SV) in scope and sets `keep`; pass_filter is cleared and the
	 * loop breaks as soon as any sub returns false. Non-hashref args are skipped. */
	result_hv = newHV(); /* 2. Allocate the hash that we will return */
	/* Mortalize immediately! If the callback croaks, the tmps stack 
	* will safely clean this up. */
	result_ref = sv_2mortal(newRV_noinc((SV *)result_hv)); 
	if (SvTYPE(SvRV(data_ref)) == SVt_PVAV) { // Input is an Array of Hashes (AoH)
		AV *restrict data_av = (AV *)SvRV(data_ref);
		SSize_t len = av_len(data_av) + 1;
		// A column must exist in at least one row; a missing column name is fatal
		{
			bool group_found = 0, target_found = 0;
			for (SSize_t i = 0; i < len && !(group_found && target_found); i++) {
				SV **restrict rp = av_fetch(data_av, i, 0);
				if (rp && SvROK(*rp) && SvTYPE(SvRV(*rp)) == SVt_PVHV) {
					HV *restrict rh = (HV *)SvRV(*rp);
					if (hv_exists_ent(rh, group_key_sv, 0))  group_found = 1;
					if (hv_exists_ent(rh, target_key_sv, 0)) target_found = 1;
				}
			}
			if (!group_found)  GROUP_BY_NO_COL(group_key_sv);
			if (!target_found) GROUP_BY_NO_COL(target_key_sv);
			FOR_EACH_FILTER_COL(fc, {
				bool found = 0;
				for (SSize_t i = 0; i < len && !found; i++) {
					SV **restrict rp = av_fetch(data_av, i, 0);
					if (rp && SvROK(*rp) && SvTYPE(SvRV(*rp)) == SVt_PVHV
						&& hv_exists_ent((HV *)SvRV(*rp), fc, 0)) found = 1;
				}
				if (!found) GROUP_BY_NO_COL(fc);
			});
		}
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
						FOR_EACH_FILTER({
							HE *restrict val_he = hv_fetch_ent(row_hv, f_col, 0, 0);
							SV *restrict val_sv = val_he ? HeVAL(val_he) : NULL;
							EVAL_FILTER(f_sub, val_sv, keep);
						});
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
/* Classify: a Hash of Arrays has arrayref values (columns); a Hash of
 * Hashes has hashref values (rows). Deciding by value type (rather than
 * by whether the requested keys happen to exist) lets a mistyped column
 * in a HoA die loudly instead of being mistaken for an empty HoH. */
		bool is_hoa = 0;
		{
			HE *restrict ce;
			hv_iterinit(data_hv);
			while ((ce = hv_iternext(data_hv))) {
				SV *restrict cv = hv_iterval(data_hv, ce);
				if (SvROK(cv)) {
					U32 ct = SvTYPE(SvRV(cv));
					if (ct == SVt_PVHV) { is_hoa = 0; break; }
					if (ct == SVt_PVAV) { is_hoa = 1; break; }
				}
			}
		}
		if (is_hoa) {
			HE *restrict group_he  = hv_fetch_ent(data_hv, group_key_sv, 0, 0);
			HE *restrict target_he = hv_fetch_ent(data_hv, target_key_sv, 0, 0);
			if (!group_he  || !SvROK(HeVAL(group_he))  || SvTYPE(SvRV(HeVAL(group_he)))  != SVt_PVAV)
				GROUP_BY_NO_COL(group_key_sv);
			if (!target_he || !SvROK(HeVAL(target_he)) || SvTYPE(SvRV(HeVAL(target_he))) != SVt_PVAV)
				GROUP_BY_NO_COL(target_key_sv);
			FOR_EACH_FILTER_COL(fc, { if (!hv_exists_ent(data_hv, fc, 0)) GROUP_BY_NO_COL(fc); });
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
						FOR_EACH_FILTER({
							SV *restrict val_sv = NULL;
							HE *restrict arr_he = hv_fetch_ent(data_hv, f_col, 0, 0);
							if (arr_he && SvROK(HeVAL(arr_he)) && SvTYPE(SvRV(HeVAL(arr_he))) == SVt_PVAV) {
								AV *restrict col_av = (AV *)SvRV(HeVAL(arr_he));
								SV **restrict val_svp = av_fetch(col_av, i, 0);
								if (val_svp) val_sv = *val_svp;
							}
							EVAL_FILTER(f_sub, val_sv, keep);
						});
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
			/* Hash of Hashes: a column must exist in at least one inner row. */
			bool group_found = 0, target_found = 0;
			HE *restrict ve;
			hv_iterinit(data_hv);
			while ((ve = hv_iternext(data_hv))) {
				SV *restrict rv = hv_iterval(data_hv, ve);
				if (SvROK(rv) && SvTYPE(SvRV(rv)) == SVt_PVHV) {
					HV *restrict ih = (HV *)SvRV(rv);
					if (hv_exists_ent(ih, group_key_sv, 0))  group_found = 1;
					if (hv_exists_ent(ih, target_key_sv, 0)) target_found = 1;
				}
			}
			if (!group_found)  GROUP_BY_NO_COL(group_key_sv);
			if (!target_found) GROUP_BY_NO_COL(target_key_sv);
			FOR_EACH_FILTER_COL(fc, {
				bool found = 0;
				HE *restrict ve2;
				hv_iterinit(data_hv);
				while ((ve2 = hv_iternext(data_hv))) {
					SV *restrict rv2 = hv_iterval(data_hv, ve2);
					if (SvROK(rv2) && SvTYPE(SvRV(rv2)) == SVt_PVHV
						&& hv_exists_ent((HV *)SvRV(rv2), fc, 0)) { found = 1; break; }
				}
				if (!found) GROUP_BY_NO_COL(fc);
			});
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
							FOR_EACH_FILTER({
								HE *restrict val_he = hv_fetch_ent(inner_hv, f_col, 0, 0);
								SV *restrict val_sv = val_he ? HeVAL(val_he) : NULL;
								EVAL_FILTER(f_sub, val_sv, keep);
							});
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

	// 3. Detect Data Structure (AoA, AoH, HoA, HoH)
	bool is_aoa = FALSE, is_aoh = FALSE, is_hoa = FALSE, is_hoh = FALSE;
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
		   } else if (first && SvROK(*first) && SvTYPE(SvRV(*first)) == SVt_PVHV) {
			   is_aoh = TRUE;
		   } else croak("prcomp: Array reference must contain ArrayRefs (AoA) or HashRefs (AoH)");
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

	if (n_raw == 0 || (p == 0 && !is_aoh && !is_hoa && !is_hoh)) croak("prcomp: input matrix is empty or has zero columns");

	// 4. Extract and Sort Column Names (for named-column inputs)
	if (is_aoh) {
		AV *restrict av = (AV*)ref;
		HV *restrict first = (HV*)SvRV(*av_fetch(av, 0, 0));
		p = hv_iterinit(first);
		if (p == 0) croak("prcomp: row hashes cannot be empty");

		colnames = (char**)safemalloc(p * sizeof(char*));
		size_t c = 0;
		HE *restrict entry;
		while ((entry = hv_iternext(first))) {
			colnames[c++] = savepv(SvPV_nolen(hv_iterkeysv(entry)));
		}
		qsort(colnames, p, sizeof(char*), cmp_string_wt);
	} else if (is_hoh) {
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
	} else if (is_aoh) {
	  AV *restrict av = (AV*)ref;
	  for (size_t i = 0; i < n_raw; i++) {
		   SV **restrict row_sv = av_fetch(av, i, 0);
		   if (row_sv && SvROK(*row_sv) && SvTYPE(SvRV(*row_sv)) == SVt_PVHV) {
			   HV *restrict row_hv = (HV*)SvRV(*row_sv);
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
		size_t nrows  = av_len(in_av) + 1;
		size_t ncols  = 0;
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
			if (ncols > 0) {// Pass 2: output[j][i] = input[i][j]
				av_extend(out_av, ncols - 1);
				for (size_t j = 0; j < ncols; j++) {
					AV *restrict out_col_av = newAV();
					SV *restrict col_ref    = newRV_noinc((SV *)out_col_av);
					if (!av_store(out_av, j, col_ref)) {
						SvREFCNT_dec(col_ref);
						croak("Stats::LikeR::transpose: Array mode – "
								"failed to allocate output column %d", (int)j);
					}
					av_extend(out_col_av, nrows - 1);
					for (size_t i = 0; i < nrows; i++) {
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

SV *hoa2aoh(hoa)
	SV *hoa
	PREINIT:
		HV *restrict in;
		AV *restrict out;
		HE *restrict he;
		SV **restrict kv;	// per-column key SVs (mortal)
		AV **restrict cv;	// per-column array bodies (borrowed)
		SSize_t n, i;
		U32 ncols, ci;
	CODE:
	{
		if (!SvROK(hoa) || SvTYPE(SvRV(hoa)) != SVt_PVHV)
			croak("hoa2aoh: argument must be a hash-of-arrays (hashref)");
		in = (HV *)SvRV(hoa);
		ncols = (U32)HvUSEDKEYS(in);
		if (ncols < 0)
			ncols = 0;
		// SAVEFREEPV makes these scratch arrays croak-safe
		ENTER;
		SAVETMPS;
		Newx(kv, ncols ? ncols : 1, SV *);
		SAVEFREEPV(kv);
		Newx(cv, ncols ? ncols : 1, AV *);
		SAVEFREEPV(cv);
		// one pass to collect columns and find the longest */
		n  = 0;
		ci = 0;
		hv_iterinit(in);
		while ((he = hv_iternext(in))) {
			SV *restrict val = HeVAL(he);
			SSize_t len;
			if (!val || !SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVAV)
				croak("hoa2aoh: column '%s' is not an arrayref",
					SvPV_nolen(hv_iterkeysv(he)));
			kv[ci] = hv_iterkeysv(he);	/* mortal; valid until our LEAVE */
			cv[ci] = (AV *)SvRV(val);
			len = av_len(cv[ci]) + 1;
			if (len > n)
				n = len;
			ci++;
		}
		ncols = ci;
		out = newAV();
		if (n > 0)
			av_extend(out, n - 1);
		for (i = 0; i < n; i++) {
			HV *restrict row = newHV();
			for (ci = 0; ci < ncols; ci++) {
				SV **restrict cp = av_fetch(cv[ci], i, 0);
				SV	*restrict cell = (cp && *cp) ? newSVsv(*cp) : newSV(0);
				(void)hv_store_ent(row, kv[ci], cell, 0);
			}
			av_push(out, newRV_noinc((SV *)row));
		}
		FREETMPS;
		LEAVE;
		RETVAL = newRV_noinc((SV *)out);
	}
	OUTPUT:
		RETVAL

SV *hoa2hoh(hoa, key)
	SV *hoa
	SV *key
	PREINIT:
		HV *restrict in;
		HV *restrict out;
		AV *restrict keycol;
		HE *restrict he;
		SV **restrict kv;	// per-column key SVs (mortal)
		AV **restrict cv;	// per-column array bodies (borrowed)
		size_t n, i;
		size_t ncols, ci;
	CODE:
	{
		if (!SvROK(hoa) || SvTYPE(SvRV(hoa)) != SVt_PVHV)
			croak("hoa2hoh: first argument must be a hash-of-arrays (hashref)");
		if (!SvOK(key))
			croak("hoa2hoh: key column name is undefined");
		in    = (HV *)SvRV(hoa);
		ncols = (size_t)HvUSEDKEYS(in);
		/* the key column must exist and be an arrayref */
		{
			HE *restrict khe  = hv_fetch_ent(in, key, 0, 0);
			SV *restrict kval = khe ? HeVAL(khe) : NULL;
			if (!khe || !kval || !SvROK(kval) || SvTYPE(SvRV(kval)) != SVt_PVAV)
				croak("hoa2hoh: key column '%s' is not present as an arrayref",
					SvPV_nolen(key));
			keycol = (AV *)SvRV(kval);
		}
		/* SAVEFREEPV makes these scratch arrays croak-safe */
		ENTER;
		SAVETMPS;
		Newx(kv, ncols ? ncols : 1, SV *);
		SAVEFREEPV(kv);
		Newx(cv, ncols ? ncols : 1, AV *);
		SAVEFREEPV(cv);
		/* one pass to collect columns and find the longest */
		n  = 0;
		ci = 0;
		hv_iterinit(in);
		while ((he = hv_iternext(in))) {
			SV *restrict val = HeVAL(he);
			size_t len;
			if (!val || !SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVAV)
				croak("hoa2hoh: column '%s' is not an arrayref",
					SvPV_nolen(hv_iterkeysv(he)));
			kv[ci] = hv_iterkeysv(he);	/* mortal; valid until our LEAVE */
			cv[ci] = (AV *)SvRV(val);
			len = (size_t)(av_len(cv[ci]) + 1);
			if (len > n)
				n = len;
			ci++;
		}
		ncols = ci;
		out = newHV();
		sv_2mortal((SV *)out);	/* reclaimed on croak; +1'd below on success */
		for (i = 0; i < n; i++) {
			HV  *restrict row;
			SV  *restrict rowname;
			SV **restrict kp = av_fetch(keycol, i, 0);
			if (!kp || !*kp || !SvOK(*kp))
				croak("hoa2hoh: key column '%s' has an undefined value at row %" UVuf,
					SvPV_nolen(key), (UV)i);
			rowname = *kp;
			if (hv_exists_ent(out, rowname, 0))
				croak("hoa2hoh: duplicate row name '%s'", SvPV_nolen(rowname));
			row = newHV();
			for (ci = 0; ci < ncols; ci++) {
				SV **restrict cp   = av_fetch(cv[ci], i, 0);
				SV	*restrict cell = (cp && *cp) ? newSVsv(*cp) : newSV(0);
				(void)hv_store_ent(row, kv[ci], cell, 0);
			}
			(void)hv_store_ent(out, rowname, newRV_noinc((SV *)row), 0);
		}
		RETVAL = newRV_inc((SV *)out);
		FREETMPS;
		LEAVE;
	}
	OUTPUT:
		RETVAL

void vals(data, colname_sv)
	SV *data
	SV *colname_sv
PREINIT:
	bool is_aoh = 0, is_hoh = 0;
	const char *restrict colname = NULL;
	STRLEN collen = 0;
	AV *restrict src_av = NULL;
	HV *restrict src_hv = NULL;
	SSize_t n = 0;
	AV *restrict out_av = NULL;
PPCODE:
{
	if (!SvOK(colname_sv))
		croak("vals: column name must be defined");
	colname = SvPV(colname_sv, collen);		/* kept for the error message */
	if (!SvROK(data))
		croak("vals: first argument must be an array-ref (AoH) or hash-ref (HoA, HoH)");
	/* ---- classify $data: AoH (arrayref) vs HoA/HoH (hashref) -------- */
	if (SvTYPE(SvRV(data)) == SVt_PVAV) {
		is_aoh = 1;
		src_av = (AV *)SvRV(data);
		n      = av_len(src_av) + 1;
	} else if (SvTYPE(SvRV(data)) == SVt_PVHV) {
		src_hv = (HV *)SvRV(data);
		hv_iterinit(src_hv);
		HE *restrict he = hv_iternext(src_hv);
		if (he) {
			SV *restrict val = HeVAL(he);
			if (val && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV)
				is_hoh = 1;			/* a hash whose values are hashes => HoH */
			/* else leave is_aoh/is_hoh = 0 => HoA path below */
		}
		// empty hash: is_aoh = is_hoh = 0 => HoA path yields []
	} else {
		croak("vals: first argument must be an array-ref (AoH) or hash-ref (HoA, HoH)");
	}
	/* out_av is mortalised up front so any later croak frees it cleanly */
	out_av = newAV();
	sv_2mortal((SV *)out_av);
	if (is_aoh) { // AoH
		if (n > 0) av_extend(out_av, n - 1);
		for (SSize_t i = 0; i < n; i++) {
			SV **restrict rp  = av_fetch(src_av, i, 0);
			SV *restrict  row = (rp && *rp) ? *rp : &PL_sv_undef;
			// strict: a row must be a hash-ref, else fail here with the index
			// rather than returning undef and letting the caller die vaguely
			if (!SvOK(row))
				croak("vals: AoH row %" IVdf " is undef (expected a hash-ref)", (IV)i);
			if (!SvROK(row) || SvTYPE(SvRV(row)) != SVt_PVHV)
				croak("vals: AoH row %" IVdf " is not a hash-ref", (IV)i);
			HE *restrict ent = hv_fetch_ent((HV *)SvRV(row), colname_sv, 0, 0);
			// a valid row that simply lacks the column still yields undef (R-like NA)
			SV *restrict cell = (ent && HeVAL(ent)) ? HeVAL(ent) : &PL_sv_undef;
			/* copy, so the result is independent of the source and undef
			 * slots are writable (not the shared read-only PL_sv_undef) */
			av_push(out_av, newSVsv(cell));
		}
	} else if (is_hoh) { // HoH
		n = hv_iterinit(src_hv);
		if (n > 0) {
			av_extend(out_av, n - 1);
			ENTER;
			SV **restrict keys; SV **restrict rows;
			Newx(keys, n, SV *);  SAVEFREEPV(keys);
			Newx(rows, n, SV *);  SAVEFREEPV(rows);
			SSize_t cnt = 0;
			HE *restrict he;
			while ((he = hv_iternext(src_hv)) && cnt < n) {
				keys[cnt] = hv_iterkeysv(he);	/* mortal copy of the key */
				rows[cnt] = HeVAL(he);
				cnt++;
			}
			/* stable insertion sort by key (sv_cmp = Perl string order, UTF-8 aware),
			 * carrying the matching row value alongside each key */
			for (SSize_t i = 1; i < cnt; i++) {
				SV *restrict k = keys[i], *r = rows[i];
				SSize_t j = i - 1;
				while (j >= 0 && sv_cmp(keys[j], k) > 0) {
					keys[j + 1] = keys[j];
					rows[j + 1] = rows[j];
					j--;
				}
				keys[j + 1] = k;
				rows[j + 1] = r;
			}
			for (SSize_t i = 0; i < cnt; i++) {
				SV *restrict row_sv = rows[i];
				// strict: name the offending key instead of silently emitting undef
				if (!row_sv || !SvROK(row_sv) || SvTYPE(SvRV(row_sv)) != SVt_PVHV)
					croak("vals: HoH value for key '%s' is not a hash-ref",
						SvPV_nolen(keys[i]));
				HE *restrict ent = hv_fetch_ent((HV *)SvRV(row_sv), colname_sv, 0, 0);
				SV *restrict cell = (ent && HeVAL(ent)) ? HeVAL(ent) : &PL_sv_undef;
				av_push(out_av, newSVsv(cell));
			}
			LEAVE;
		}
	} else { // HoA
		if (hv_iterinit(src_hv) > 0) {		/* non-empty hash */
			HE *restrict colent = hv_fetch_ent(src_hv, colname_sv, 0, 0);
			SV *restrict cv = colent ? HeVAL(colent) : NULL;
			if (!cv || !SvROK(cv) || SvTYPE(SvRV(cv)) != SVt_PVAV)
				croak("vals: column '%s' not found or is not an array-ref", colname);
			AV *restrict col_av = (AV *)SvRV(cv);
			n = av_len(col_av) + 1;
			if (n > 0) {
				/* the length is known, so the result is sized once and filled
				 * straight through AvARRAY rather than pushed a cell at a time */
				av_extend(out_av, n - 1);
				SV **restrict d = AvARRAY(out_av);
				SV **restrict src = AvARRAY(col_av);
				const SSize_t srcn = AvFILLp(col_av) + 1;
				for (SSize_t i = 0; i < n; i++)
					d[i] = newSVsv((i < srcn && src[i]) ? src[i] : &PL_sv_undef);
				AvFILLp(out_av) = n - 1;
			}
		}
	}
	/* out_av is mortal (freed on any croak); newRV_inc balances that so the
	 * returned RV holds the surviving reference -- newRV_noinc here would
	 * double-free with the mortal. */
	XPUSHs(sv_2mortal(newRV_inc((SV *)out_av)));
	XSRETURN(1);
}

void
_qcut_core(data_ref, probs_ref, drop_dups, want_codes)
	SV *data_ref
	SV *probs_ref
	IV drop_dups
	IV want_codes
PREINIT:
	AV  *data_av;
	AV  *probs_av;
	AV  *edge_av;
	AV  *code_av = NULL;
	SV **el;
	IV   n, m, i, j, ne, w;
	NV  *srt  = NULL;
	NV  *edges = NULL;
	NV   p, h, frac, v;
	IV   lo, bin, lo2, hi2, mid, k;
PPCODE:
	if (!SvROK(data_ref) || SvTYPE(SvRV(data_ref)) != SVt_PVAV)
		croak("_qcut_core: data must be an ARRAY reference");
	if (!SvROK(probs_ref) || SvTYPE(SvRV(probs_ref)) != SVt_PVAV)
		croak("_qcut_core: probs must be an ARRAY reference");

	data_av  = (AV *) SvRV(data_ref);
	probs_av = (AV *) SvRV(probs_ref);
	n = av_len(data_av)  + 1;
	m = av_len(probs_av) + 1;
	if (n < 1)
		croak("_qcut_core: need at least one data value");
	if (m < 2)
		croak("_qcut_core: need at least two probabilities (one bin)");

	Newx(srt, n, NV);
	for (i = 0; i < n; i++) {
		el = av_fetch(data_av, i, 0);
		srt[i] = (el && SvOK(*el)) ? SvNV(*el) : 0.0;
	}
	qsort(srt, (size_t) n, sizeof(NV), cmp_nv3);

	/* quantile cutpoints via linear interpolation (numpy/pandas default) */
	Newx(edges, m, NV);
	for (j = 0; j < m; j++) {
		el = av_fetch(probs_av, j, 0);
		p = el ? SvNV(*el) : 0.0;
		if (p < 0.0) p = 0.0;
		if (p > 1.0) p = 1.0;
		h    = (NV)(n - 1) * p;
		lo   = (IV) floor((double) h);
		frac = h - (NV) lo;
		if (lo + 1 < n)
			edges[j] = srt[lo] + frac * (srt[lo + 1] - srt[lo]);
		else
			edges[j] = srt[lo];
	}
	/* guard fp drift: enforce non-decreasing edges */
	for (j = 1; j < m; j++)
		if (edges[j] < edges[j - 1])
			edges[j] = edges[j - 1];

	Safefree(srt);		/* no longer needed once cutpoints exist */

	/* duplicate edges: raise (default) or drop */
	w = 1;
	for (j = 1; j < m; j++) {
		if (edges[j] == edges[w - 1]) {
			if (!drop_dups) {
				Safefree(edges);
				croak("_qcut_core: bin edges are not unique; pass duplicates => 'drop' (or use fewer bins)");
			}
		} else {
			edges[w++] = edges[j];
		}
	}
	ne = w;
	if (ne < 2) {
		Safefree(edges);
		croak("_qcut_core: data has too few distinct values to form bins");
	}

	edge_av = newAV();
	av_extend(edge_av, ne - 1);
	for (j = 0; j < ne; j++)
		av_push(edge_av, newSVnv(edges[j]));

	/* assign each original value to a 0-based bin only if codes are wanted;
	   lowest bin is inclusive on both ends */
	if (want_codes) {
		code_av = newAV();
		av_extend(code_av, n - 1);
		for (i = 0; i < n; i++) {
			el = av_fetch(data_av, i, 0);
			v  = (el && SvOK(*el)) ? SvNV(*el) : 0.0;
			if (v <= edges[0]) {
				bin = 0;
			} else if (v >= edges[ne - 1]) {
				bin = ne - 2;
			} else {
				lo2 = 1;
				hi2 = ne - 1;
				k   = ne - 1;
				while (lo2 <= hi2) {
					mid = lo2 + ((hi2 - lo2) >> 1);
					if (edges[mid] >= v) {
						k   = mid;
						hi2 = mid - 1;
					} else {
						lo2 = mid + 1;
					}
				}
				bin = k - 1;
			}
			av_push(code_av, newSViv(bin));
		}
	}

	Safefree(edges);

	EXTEND(SP, 2);
	if (want_codes)
		PUSHs(sv_2mortal(newRV_noinc((SV *) code_av)));
	else
		PUSHs(&PL_sv_undef);
	PUSHs(sv_2mortal(newRV_noinc((SV *) edge_av)));


void get_union(...)
	PROTOTYPE: @
	PREINIT:
		HV*restrict seen;
		AV*restrict order;
		size_t nrefs, n, oi, olen;
		int gimme;
	PPCODE:
		gimme = GIMME_V;
		nrefs = items;
		if (nrefs == 0)
			croak("union needs >= 1 array ref");
		seen  = (HV*)sv_2mortal((SV*)newHV());
		order = (AV*)sv_2mortal((SV*)newAV()); /* buffer: pushing to the stack while still reading ST() would clobber the args */
		n = 0;
		for (size_t i = 0; i < nrefs; i++) {
			SV*restrict arg = ST(i);
			AV*restrict av;
			size_t len;
			if (!(SvROK(arg) && SvTYPE(SvRV(arg)) == SVt_PVAV))
				croak("union: argument index %" UVuf " of %" UVuf " total (max index %" UVuf ") is not an array reference", (UV)i, (UV)nrefs, (UV)(nrefs - 1));
			av = (AV*)SvRV(arg);
			len = (size_t)(av_len(av) + 1);
			for (size_t j = 0; j < len; j++) {
				SV**restrict tv = av_fetch(av, j, 0);
				STRLEN klen;
				const char*restrict key;
				I32 hklen;
				if (!(tv && SvOK(*tv)))
					croak("union: undefined value at array ref index %" UVuf " (argument %" UVuf ")", (UV)j, (UV)i);
				key = SvPV(*tv, klen);
				hklen = SvUTF8(*tv) ? -(I32)klen : (I32)klen;
				if (hv_exists(seen, key, hklen))
					continue;
				(void)hv_store(seen, key, hklen, &PL_sv_undef, 0);
				n++;
				if (gimme != G_SCALAR)
					av_push(order, newSVsv(*tv));
			}
		}
		if (gimme == G_SCALAR) {
			XPUSHs(sv_2mortal(newSVuv(n)));
		} else {
			olen = (size_t)(av_len(order) + 1);
			for (oi = 0; oi < olen; oi++) {
				SV**restrict e = av_fetch(order, oi, 0);
				if (e && *e)
					XPUSHs(sv_2mortal(newSVsv(*e)));
			}
		}

void Lonly(...)
	PROTOTYPE: @
	PPCODE:
		if (items == 0)
			croak("Lonly needs >= 1 array ref");
		SP = set_multiplicity(aTHX_ SP, &ST(0), (size_t)items, 0, 0,
		                      "Lonly", GIMME_V);

void Ronly(...)
	PROTOTYPE: @
	PPCODE:
		if (items == 0)
			croak("Ronly needs >= 1 array ref");
		/* mirror of Lonly: values only in the LAST array (from_last = 1), so
		 * the two-array Ronly(a,b) still equals Lonly(b,a). */
		SP = set_multiplicity(aTHX_ SP, &ST(0), (size_t)items, 0, 1,
		                      "Ronly", GIMME_V);

void is_equivalent(...)
	PROTOTYPE: @
	PPCODE:
		if (items < 2)
			croak("is_equivalent needs >= 2 array refs (got %" UVuf ")", (UV)items);
		XPUSHs(sv_2mortal(newSViv(set_equivalent(aTHX_ &ST(0), (size_t)items, "is_equivalent"))));

SV* pnorm(...)
CODE:
{
	if (items < 1)
		croak("Usage: pnorm(x), pnorm(x, mean => 0, sd => 1, lower => 1, log => 0)");
	SV *restrict x_sv = ST(0);
	NV mean = 0.0, sd = 1.0; // defaults
	bool lower_tail = 1, give_log = 0;
	if ((items - 1) % 2 != 0)
		croak("pnorm: Expected an even number of key-value named arguments after 'x'");
	for (size_t i = 1; i < items; i += 2) {
		const char *restrict key = SvPV_nolen(ST(i));
		SV *restrict val = ST(i + 1);
		if      (strEQ(key, "mean"))                              mean       = SvNV(val);
		else if (strEQ(key, "sd"))                                sd         = SvNV(val);
		else if (strEQ(key, "lower") || strEQ(key, "lower.tail")) lower_tail = SvTRUE(val) ? 1 : 0;
		else if (strEQ(key, "log")   || strEQ(key, "log.p"))      give_log   = SvTRUE(val) ? 1 : 0;
		else croak("pnorm: unknown argument '%s'", key);
	}
	if (sd < 0.0)
		warn("pnorm: standard deviation must be non-negative");
	if (SvROK(x_sv) && SvTYPE(SvRV(x_sv)) == SVt_PVAV) {
		AV *restrict x_av = (AV*)SvRV(x_sv);
		IV n = av_len(x_av) + 1;
		AV *restrict result_av = newAV();
		if (n > 0) {
			av_extend(result_av, n - 1);
			for (IV i = 0; i < n; i++) {
				SV **restrict elem = av_fetch(x_av, i, 0);
				NV x_val = (elem && *elem) ? SvNV(*elem) : NAN;
				NV res = (NV)c_pnorm((double)x_val, (double)mean, (double)sd,
				                     lower_tail, give_log);
				av_store(result_av, i, newSVnv(res));
			}
		}
		RETVAL = newRV_noinc((SV*)result_av);
	} else {
		NV x_val = SvNV(x_sv);
		NV res = (NV)c_pnorm((double)x_val, (double)mean, (double)sd,
		                     lower_tail, give_log);
		RETVAL = newSVnv(res);
	}
}
OUTPUT:
	RETVAL

# Private numeric helpers.  These replace pure-Perl ports that used to live in
# LikeR.pm (_lgamma/_igamc/_pchisq_upper); igamc() here is the one authoritative
# implementation, so the Perl and C copies can no longer drift apart.  Not
# exported -- callers inside Stats::LikeR use them unqualified.

NV _igamc(a, x)
	NV a
	NV x
CODE:
	RETVAL = igamc(a, x);
OUTPUT:
	RETVAL

# Upper-tail chi-square p-value P(X > stat) on df degrees of freedom.  df is
# taken as an NV (not get_p_value's int) so a fractional df is not truncated,
# matching what the Perl version computed as _igamc($df/2, $stat/2).
NV _pchisq_upper(stat, df)
	NV stat
	NV df
CODE:
	RETVAL = (df <= 0.0 || stat <= 0.0) ? 1.0 : igamc(df / 2.0, stat / 2.0);
OUTPUT:
	RETVAL

