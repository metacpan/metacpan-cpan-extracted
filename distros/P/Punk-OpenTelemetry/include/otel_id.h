/* otel_id.h - trace and span ids.
 *
 * A trace id is 16 bytes, a span id 8, and both must be random enough that
 * two processes that have never met do not collide. getentropy(2) where it
 * exists, a cached /dev/urandom descriptor where it does not.
 *
 * The descriptor is cached because opening /dev/urandom per span would be a
 * syscall and a file-table entry per request; it is reopened after a fork,
 * because a child inheriting the parent's descriptor is fine but a child
 * inheriting a BUFFER would not be - which is exactly why nothing here
 * buffers.
 *
 * ALL-ZERO IS NOT A VALID ID. The spec says so, and it matters in both
 * directions: never generate one, and treat one arriving in a header as
 * absent rather than as a parent. A generator that can return all-zero turns
 * "no parent" into "a parent nobody has", which is worse than either.
 */

#ifndef OTEL_ID_H
#define OTEL_ID_H

#include <fcntl.h>
#ifndef _WIN32
#  include <unistd.h>
#endif
#ifdef OTEL_GETENTROPY_SYS_RANDOM
#  include <sys/random.h>
#endif

static int   OTEL_URANDOM_FD  = -1;
static pid_t OTEL_URANDOM_PID = 0;

/* Fill n bytes. Returns 1 on success, 0 when no source could be reached. */
static int otel_random_bytes(unsigned char *out, size_t n) {
#ifdef OTEL_HAVE_GETENTROPY
    /* getentropy caps at 256 bytes a call; an id is 16, so one call always. */
    if (n <= 256 && getentropy(out, n) == 0) return 1;
#endif
#ifndef _WIN32
    {
        pid_t me = getpid();
        size_t got = 0;
        /* Reopen after a fork. The descriptor itself would survive, but a
         * worker that inherited the parent's is a worker sharing a source
         * with every sibling, and this is the one place in the SDK where
         * sharing state across a fork is a correctness question rather than
         * a performance one. */
        if (OTEL_URANDOM_FD >= 0 && OTEL_URANDOM_PID != me) {
            close(OTEL_URANDOM_FD);
            OTEL_URANDOM_FD = -1;
        }
        if (OTEL_URANDOM_FD < 0) {
            OTEL_URANDOM_FD = open("/dev/urandom", O_RDONLY);
            OTEL_URANDOM_PID = me;
        }
        if (OTEL_URANDOM_FD >= 0) {
            while (got < n) {
                ssize_t r = read(OTEL_URANDOM_FD, out + got, n - got);
                if (r <= 0) break;
                got += (size_t)r;
            }
            if (got == n) return 1;
        }
    }
#endif
    return 0;
}

static int otel_all_zero(const unsigned char *p, size_t n) {
    size_t i;
    for (i = 0; i < n; i++) if (p[i]) return 0;
    return 1;
}

/* Generate an id, retrying the vanishingly unlikely all-zero draw. The retry
 * is cheap and the alternative is a span that claims a parent nobody has. */
static int otel_gen_id(unsigned char *out, size_t n) {
    int tries;
    for (tries = 0; tries < 4; tries++) {
        if (!otel_random_bytes(out, n)) return 0;
        if (!otel_all_zero(out, n)) return 1;
    }
    return 0;
}

/* Parse `want` bytes of lowercase or uppercase hex. Returns 1 on success.
 * Rejects an all-zero result, which is how an invalid id in an inbound header
 * becomes "no parent" rather than a parent that cannot exist. */
static int otel_hex_to_bytes(const char *s, STRLEN len, unsigned char *out,
                             STRLEN want) {
    STRLEN i;
    if (len != want * 2) return 0;
    for (i = 0; i < want; i++) {
        int hi, lo, j, d[2];
        for (j = 0; j < 2; j++) {
            char c = s[i * 2 + j];
            d[j] = (c >= '0' && c <= '9') ? c - '0'
                 : (c >= 'a' && c <= 'f') ? c - 'a' + 10
                 : (c >= 'A' && c <= 'F') ? c - 'A' + 10 : -1;
            if (d[j] < 0) return 0;
        }
        hi = d[0]; lo = d[1];
        out[i] = (unsigned char)((hi << 4) | lo);
    }
    return !otel_all_zero(out, want);
}

static void otel_bytes_to_hex(const unsigned char *in, STRLEN n, char *out) {
    static const char H[] = "0123456789abcdef";
    STRLEN i;
    for (i = 0; i < n; i++) {
        out[i * 2]     = H[in[i] >> 4];
        out[i * 2 + 1] = H[in[i] & 0xf];
    }
}

#endif /* OTEL_ID_H */
