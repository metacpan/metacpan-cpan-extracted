#include "stencil.h"

stencil_dispatch_t stencil_dispatch;

/* Scalar fallbacks. Phase 02 supplies the SWAR/SIMD implementations and
 * registers them here; the selection pattern is fixed from day one. */

static const char *stencil_scan_scalar(const char *p, const char *end)
{
    const char *hit;
    if (p >= end)
        return end;
    hit = (const char *)memchr(p, '{', (size_t)(end - p));
    return hit ? hit : end;
}

/* cpuid.h first shipped in gcc 4.3; older x86 gccs (FreeBSD 9's base
 * gcc 4.2.1) define __GNUC__ but lack the header, so without the version
 * check caps stays 0 and the scalar paths are used there. */
#if (defined(__x86_64__) || defined(__i386__) || defined(_M_X64)) \
    && defined(__GNUC__) \
    && (defined(__clang__) \
        || __GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 3))
#  include <cpuid.h>
#  define STENCIL_X86_CPUID 1
static uint32_t stencil_x86_caps(void)
{
    uint32_t caps = 0;
    unsigned int a, b, c, d;
    unsigned int max = __get_cpuid_max(0, 0);
    if (max >= 1) {
        __cpuid_count(1, 0, a, b, c, d);
        if (d & (1u << 26)) caps |= STENCIL_CAP_SSE2;
        if (c & (1u << 20)) caps |= STENCIL_CAP_SSE42;
    }
    if (max >= 7) {
        __cpuid_count(7, 0, a, b, c, d);
        if (b & (1u << 5))  caps |= STENCIL_CAP_AVX2;
    }
    return caps;
}
#endif

void stencil_boot(pTHX)
{
    uint32_t caps = 0;
    const char *force;
    PERL_UNUSED_CONTEXT;

#ifdef STENCIL_HAVE_COMPUTED_GOTO
    caps |= STENCIL_CAP_COMPUTED_GOTO;
#endif
#ifdef STENCIL_HAVE_BUILTIN_EXPECT
    caps |= STENCIL_CAP_BUILTIN_EXPECT;
#endif

    /* SIMD: a capability is advertised only when the variant was both
     * compiled in (STENCIL_HAVE_*) and supported by this CPU. */
    {
        uint32_t cpu = 0;
#ifdef STENCIL_X86_CPUID
        cpu = stencil_x86_caps();
#endif
#ifdef STENCIL_HAVE_NEON
        cpu |= STENCIL_CAP_NEON; /* baseline on arm64 */
#endif
#ifndef STENCIL_HAVE_SSE2
        cpu &= ~STENCIL_CAP_SSE2;
#endif
#ifndef STENCIL_HAVE_SSE42
        cpu &= ~STENCIL_CAP_SSE42;
#endif
#ifndef STENCIL_HAVE_AVX2
        cpu &= ~STENCIL_CAP_AVX2;
#endif
        caps |= cpu;
    }

    /* Force the portable paths - kept in shipped code so exotic hardware
     * effectively tests both variants. */
    force = PerlEnv_getenv("STENCIL_FORCE_SWAR");
    if (force && *force && !(*force == '0' && !force[1]))
        caps &= ~(STENCIL_CAP_SSE2 | STENCIL_CAP_SSE42
                | STENCIL_CAP_AVX2 | STENCIL_CAP_NEON);

    force = PerlEnv_getenv("STENCIL_FORCE_SWITCH");
    stencil_dispatch.force_switch =
        force && *force && !(*force == '0' && !force[1]);

    stencil_dispatch.caps = caps;

    /* scan: libc memchr is already vectorised on every platform we
     * care about; revisit in phase 03 only if profiling demands. */
    stencil_dispatch.scan = stencil_scan_scalar;

    /* escape: best compiled-in variant the CPU supports; SWAR baseline
     * is always available. Selection happens exactly once. */
    stencil_dispatch.escape = stencil_escape_swar;
#ifdef STENCIL_HAVE_AVX2
    if (caps & STENCIL_CAP_AVX2)
        stencil_dispatch.escape = stencil_escape_avx2;
    else
#endif
#ifdef STENCIL_HAVE_SSE2
    if (caps & STENCIL_CAP_SSE2)
        stencil_dispatch.escape = stencil_escape_sse2;
    else
#endif
#ifdef STENCIL_HAVE_NEON
    if (caps & STENCIL_CAP_NEON)
        stencil_dispatch.escape = stencil_escape_neon;
    else
#endif
        ; /* SWAR baseline stands */
}
