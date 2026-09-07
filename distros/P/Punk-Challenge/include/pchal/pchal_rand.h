#ifndef PCHAL_RAND_H
#define PCHAL_RAND_H

/* Entropy, for `punk challenge key` and nothing else: a puzzle's salt is a
 * counter on purpose, and nothing on the request path draws from here.
 *
 * getentropy when the configure probe LINKED it (a compile-only probe is a
 * recorded CPAN Testers failure), /dev/urandom otherwise. Failure is -1 for
 * the caller to croak on: a secret an attacker could predict is worse than
 * no secret.
 *
 * getentropy costs the same ~700ns for 16 bytes as for its 256-byte
 * maximum, so one call fills a pool the next draws come from. The pool is
 * keyed to the pid: a forked process that inherited its parent's pool would
 * otherwise hand out the parent's next bytes. (Punk-Mailer's pmail_rand.h,
 * with its names.)
 *
 * Needs nothing before it but the perl headers.
 */

#ifdef PCHAL_HAVE_GETENTROPY
#  ifdef PCHAL_GETENTROPY_SYS_RANDOM
#    include <sys/random.h>
#  else
#    include <unistd.h>
#  endif
#endif

static int pchal_rand_fill(unsigned char *out, size_t n)
{
#ifdef PCHAL_HAVE_GETENTROPY
    size_t off = 0;
    while (off < n) {
        size_t take = n - off > 256 ? 256 : n - off;
        if (getentropy(out + off, take) != 0) return -1;
        off += take;
    }
    return 0;
#else
    FILE *f = fopen("/dev/urandom", "rb");
    size_t got;
    if (!f) return -1;
    got = fread(out, 1, n, f);
    fclose(f);
    return got == n ? 0 : -1;
#endif
}

static int pchal_random_bytes(unsigned char *out, size_t n)
{
    static unsigned char pool[256];
    static size_t have = 0;
    static UV owner = 0;
    UV me = (UV)PerlProc_getpid();

    if (owner != me) { have = 0; owner = me; }
    while (n) {
        size_t take;
        if (!have) {
            if (pchal_rand_fill(pool, sizeof pool) != 0) return -1;
            have = sizeof pool;
        }
        take = n < have ? n : have;
        memcpy(out, pool + (sizeof pool - have), take);
        have -= take; out += take; n -= take;
    }
    return 0;
}

#endif /* PCHAL_RAND_H */
