/* po_compat.h - the portability floor.
 *
 * Every fact this distribution needs about the platform lives here, so that
 * no other header has to ask twice and no call site has to guess. The probes
 * that set the PO_HAVE_* defines are in Makefile.PL, and they are LINK
 * probes: MSVC exits 0 on an undeclared function and old compilers take an
 * implicit declaration as a warning, so a compile-only probe reports a
 * symbol that is not there and the built .so fails to load. Punk::OpenTelemetry
 * learned that from CPAN Testers; this is the same probe, not a fresh guess.
 *
 * Perl headers must be included before this file.
 */
#ifndef PO_COMPAT_H
#define PO_COMPAT_H

#ifdef _MSC_VER
#  if _MSC_VER < 1600
     typedef signed char        int8_t;
     typedef unsigned char      uint8_t;
     typedef short              int16_t;
     typedef unsigned short     uint16_t;
     typedef int                int32_t;
     typedef unsigned int       uint32_t;
     typedef __int64            int64_t;
     typedef unsigned __int64   uint64_t;
#  else
#    include <stdint.h>
#  endif
#else
#  include <stdint.h>
#endif

#include <string.h>

/* The 64-bit type this dist stores timestamps, series ids and durations in.
 *
 * It is NOT an IV. On the i686, quadmath and long-double smokers IVSIZE is 4,
 * and a unix nanosecond timestamp for 2026 is about 1.79e18 - four hundred
 * million times IV_MAX. A cast through IV truncates silently: the developer's
 * box is fine, the smoker stores a wrong instant, and the test suite is green
 * on both. Nothing in this distribution passes one of these through SvIV, and
 * nothing formats one with %d or %f. See po_u64_to_sv / po_sv_to_u64 below. */
typedef uint64_t po_u64;
typedef int64_t  po_i64;

#define PO_U64_MAX ((po_u64)~(po_u64)0)

/* G_LIST IS PERL 5.36 AND THIS DISTRIBUTION SAYS 5.10.
 *
 * It is the modern spelling of G_ARRAY - the same value, renamed - and using
 * it unguarded made every perl below 5.36 fail to COMPILE, which a smoker
 * reported before any test could run. The local perl having it is exactly why
 * that went unnoticed: a name that only has to exist at build time leaves no
 * trace on a box that has it.
 *
 * The new name stays in the code because it is the one the perldoc uses now;
 * this is what makes it mean something on an older perl. */
/* isWORDCHAR_A is 5.14. Its callers test one ASCII byte for [0-9A-Za-z_]. */
#ifndef isWORDCHAR_A
#  define isWORDCHAR_A(c) (((c) >= 'a' && (c) <= 'z') || ((c) >= 'A' && (c) <= 'Z') \
                           || ((c) >= '0' && (c) <= '9') || (c) == '_')
#endif

/* SvIV_please_nomg is 5.18: an NV that is integral becomes an IV as well, the
 * way perl's own arithmetic asks of an operand. */
#ifndef SvIV_please_nomg
#  define SvIV_please_nomg(sv) \
     STMT_START { if (SvNOK(sv) && !SvIOK(sv)) (void)SvIV_nomg(sv); } STMT_END
#endif

#ifndef G_LIST
#  define G_LIST G_ARRAY
#endif

/* Is an po_u64 representable in this perl's IV/UV without loss? */
#define PO_FITS_UV(v) (UVSIZE >= 8 || (po_u64)(v) <= (po_u64)UV_MAX)

/* A 64-bit value crosses to Perl as a UV where that is lossless and as a
 * decimal STRING where it is not. A string is exact on every perl, sorts and
 * compares correctly after a numeric conversion in the caller, and - unlike an
 * NV - does not quietly drop the last two digits of a nanosecond timestamp.
 * The alternative, an (hi, lo) pair, moves the problem to every call site. */
static SV *po_u64_string_sv(pTHX_ po_u64 v) {
    char  buf[21];              /* 20 digits of UINT64_MAX, plus the NUL */
    char *p = buf + sizeof(buf);
    *--p = '\0';
    if (v == 0) *--p = '0';
    while (v) { *--p = (char)('0' + (int)(v % 10)); v /= 10; }
    return newSVpv(p, (STRLEN)(buf + sizeof(buf) - 1 - p));
}

/* A FUNCTION, and that is not a style preference.
 *
 * THE OBVIOUS MACRO EVALUATES ITS ARGUMENT A DIFFERENT NUMBER OF TIMES ON
 * DIFFERENT PERLS.
 *
 *     #define po_u64_to_sv(v) (PO_FITS_UV(v) ? newSVuv((UV)(v)) : ...)
 *
 * PO_FITS_UV begins `UVSIZE >= 8 ||`. On a 64-bit perl that is a compile-time
 * true and short-circuits the rest away, so the argument is evaluated once.
 * On a 32-bit-IV perl it is false, the second operand runs, and an argument
 * with a side effect happens TWICE. `po_u64_to_sv(po_br_get(&r, width))`
 * therefore advanced the bit reader twice - on exactly the perls nobody
 * develops on, and nowhere else. Passing through a function makes the count
 * one everywhere. */
static SV *po_u64_mksv(pTHX_ po_u64 v) {
    if (PO_FITS_UV(v)) return newSVuv((UV)v);
    return po_u64_string_sv(aTHX_ v);
}

#define po_u64_to_sv(v) po_u64_mksv(aTHX_ (v))

/* The SIGNED crossing, for values that are two's complement on the wire.
 *
 * OTLP declares an integer attribute `int64`, so the bit pattern stored is
 * signed. Rendering it unsigned turns -1 into 18446744073709551615 - a number
 * that is not wrong so much as unrecognisable, and one that compares above
 * every positive value in a query. */
static SV *po_i64_mksv(pTHX_ po_u64 bits) {
    po_i64 v;
    memcpy(&v, &bits, sizeof(v));
    if (v >= 0) return po_u64_mksv(aTHX_ (po_u64)v);
    /* The magnitude, then a sign. Negating in the signed type is undefined
     * at the bottom of the range, so it is done in the unsigned one. */
    {
        po_u64 mag = (po_u64)0 - bits;
        if (IVSIZE >= 8 || mag <= (po_u64)IV_MAX) return newSViv(-(IV)mag);
        {
            SV *sv = po_u64_string_sv(aTHX_ mag);
            SV *out = newSVpvs("-");
            sv_catsv(out, sv);
            SvREFCNT_dec(sv);
            return out;
        }
    }
}

#define po_i64_to_sv(v) po_i64_mksv(aTHX_ (v))

/* The inverse, accepting either form. Returns 0 and leaves *out alone if the
 * string is not a bare non-negative integer or would overflow - a caller that
 * ignores the return value gets zero, not garbage. */
static int po_sv_to_u64(pTHX_ SV *sv, po_u64 *out) {
    STRLEN len;
    const char *p, *end;
    po_u64 v = 0;

    if (!sv || !SvOK(sv)) return 0;

    /* Only trust the numeric slot where it cannot have lost anything. Taking
     * SvUV of an NV-backed SV is exactly the silent truncation this type
     * exists to avoid, so a string is parsed as a string even when perl has
     * helpfully given it a numeric value too. */
    if (!SvPOK(sv) && SvIOK(sv) && !SvIsUV(sv) && SvIVX(sv) >= 0) {
        *out = (po_u64)SvIVX(sv);
        return 1;
    }
    if (!SvPOK(sv) && SvIOK(sv) && SvIsUV(sv)) {
        *out = (po_u64)SvUVX(sv);
        return 1;
    }

    p = SvPV(sv, len);          /* on its own line: see the sibling-arg note */
    end = p + len;
    if (p == end) return 0;
    while (p < end && *p == ' ') p++;
    if (p == end) return 0;
    for (; p < end; p++) {
        po_u64 d;
        if (*p < '0' || *p > '9') return 0;
        d = (po_u64)(*p - '0');
        if (v > (PO_U64_MAX - d) / 10) return 0;    /* overflow, not wrap */
        v = v * 10 + d;
    }
    *out = v;
    return 1;
}

/* Formats. A Perl-flavoured formatter (croak, warn, sv_catpvf, newSVpvf)
 * reads an NV for %f and an IV for %d, so a double or a 64-bit integer passed
 * to one is undefined: the quadmath smokers panic and x86_64 reads silent
 * garbage. These are the only spellings used in this distribution. */
#define PO_UVf "%" UVuf
#define PO_IVf "%" IVdf
#define PO_NVf "%" NVff

/* Byte order. The WAL and the segment are little-endian on disk, and the
 * READER swaps rather than the writer, because the writer is the hot path and
 * every box that matters is already little-endian. */
#if defined(__BYTE_ORDER__) && defined(__ORDER_BIG_ENDIAN__) && \
    __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#  define PO_BIG_ENDIAN 1
#endif

static po_u64 po_le64(po_u64 v) {
#ifdef PO_BIG_ENDIAN
    return ((v & 0x00000000000000FFULL) << 56)
         | ((v & 0x000000000000FF00ULL) << 40)
         | ((v & 0x0000000000FF0000ULL) << 24)
         | ((v & 0x00000000FF000000ULL) <<  8)
         | ((v & 0x000000FF00000000ULL) >>  8)
         | ((v & 0x0000FF0000000000ULL) >> 24)
         | ((v & 0x00FF000000000000ULL) >> 40)
         | ((v & 0xFF00000000000000ULL) >> 56);
#else
    return v;
#endif
}

static uint32_t po_le32(uint32_t v) {
#ifdef PO_BIG_ENDIAN
    return ((v & 0x000000FFU) << 24) | ((v & 0x0000FF00U) << 8)
         | ((v & 0x00FF0000U) >>  8) | ((v & 0xFF000000U) >> 24);
#else
    return v;
#endif
}

/* Atomics. The FreeBSD 9 smoker is gcc 4.2.1 and has no __atomic builtins at
 * all, so the feature is probed rather than inferred from __GNUC__. Hyperman
 * solved this once in hm_atomic.h; where this dist is built beside it that
 * header is used instead of this fallback. */
#ifdef PO_HAVE_ATOMICS
#  define po_atomic_add(p, n)  __atomic_add_fetch((p), (n), __ATOMIC_SEQ_CST)
#  define po_atomic_load(p)    __atomic_load_n((p), __ATOMIC_SEQ_CST)
#  define po_atomic_store(p,v) __atomic_store_n((p), (v), __ATOMIC_SEQ_CST)
#else
   /* Single-threaded fallback. Correct for one process; the cross-worker
    * counters in phase 15 REQUIRE the real thing and check for it at boot
    * rather than silently miscounting. */
#  define po_atomic_add(p, n)  (*(p) += (n))
#  define po_atomic_load(p)    (*(p))
#  define po_atomic_store(p,v) (*(p) = (v))
#endif

#endif /* PO_COMPAT_H */
