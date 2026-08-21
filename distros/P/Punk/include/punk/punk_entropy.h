#ifndef PUNK_ENTROPY_H
#define PUNK_ENTROPY_H

/* Sliced entropy, for the things that need a fresh unguessable value on every
 * request: a request id, a CSP nonce.
 *
 * ---- why it is sliced -----------------------------------------------------
 *
 * `getentropy` costs per CALL, not per byte. Measured on darwin/arm64:
 *
 *      bytes   ns/call   amortised ns per 16-byte draw
 *         16     731.2                            731.2
 *        256     669.7                             41.9
 *
 * A flat ~640-730 ns whether it is asked for 16 bytes or 256. So it is asked
 * for 256 - its documented maximum - and sixteen draws come out of the
 * result. That one constant is worth 17x, and for scale a bare Punk request
 * is about 1 us: per-call entropy would be most of it.
 *
 * A LARGER buffer buys nothing. CAP bytes still needs CAP/256 calls, so draws
 * per syscall is pinned at 16 however much is held; 256 B and 256 KB measure
 * the same. So 256 B: least memory, and the least unused entropy sitting in a
 * worker's address space.
 *
 * ---- why the pid guard is not optional ------------------------------------
 *
 * A buffer filled once and inherited through `fork` hands every worker the
 * same bytes. Measured while building Punk::Plugin::RequestId: 767 duplicate
 * values in 8000 across four workers, and it looks perfectly random the whole
 * time - the code reads correctly, the output passes any eyeball test, and
 * only a forked-pool test finds it.
 *
 * For a request id that is a nuisance. For a CSP nonce it is the
 * vulnerability, reached from the inside: two users on two workers served the
 * same nonce means one of them can predict the other's, and a predictable
 * nonce is an attacker's `<script nonce="...">` running on somebody else's
 * page.
 *
 * `getpid()` is 1.5 ns - libc-cached, not a syscall - so the guard costs
 * nothing measurable. Worth checking rather than assuming: a guard that was
 * itself a syscall would have handed back everything the slicing won.
 *
 * Needs punk_csrf.h first, for pk_urandom_fd.
 */

#define PK_ENT_CAP 256              /* getentropy's documented maximum */

static unsigned char pk_ent_buf[PK_ENT_CAP];
static size_t        pk_ent_off = sizeof pk_ent_buf;
static Pid_t         pk_ent_pid = 0;

static void pk_ent_fill(pTHX) {
#ifdef PUNK_HAVE_GETENTROPY
    if (getentropy(pk_ent_buf, sizeof pk_ent_buf) != 0)
        croak("Punk: getentropy failed: %s", Strerror(errno));
#else
    /* The same cached descriptor punk_csrf.h uses, and the same refusal to
     * fall back to anything weaker: a guessable nonce or token is worse than
     * a server that will not start. */
    size_t off = 0;
    if (pk_urandom_fd < 0) {
        pk_urandom_fd = PerlLIO_open3("/dev/urandom", O_RDONLY, 0);
        if (pk_urandom_fd < 0)
            croak("Punk: cannot open /dev/urandom: %s", Strerror(errno));
    }
    while (off < sizeof pk_ent_buf) {
        SSize_t got = PerlLIO_read(pk_urandom_fd, pk_ent_buf + off,
                                   sizeof pk_ent_buf - off);
        if (got <= 0) croak("Punk: short read from /dev/urandom");
        off += (size_t)got;
    }
#endif
    pk_ent_off = 0;
    pk_ent_pid = getpid();
}

/* n bytes of entropy. n must be <= PK_ENT_CAP. */
static void pk_ent_take(pTHX_ unsigned char *out, size_t n) {
    if (pk_ent_pid != getpid() || pk_ent_off + n > sizeof pk_ent_buf)
        pk_ent_fill(aTHX);
    Copy(pk_ent_buf + pk_ent_off, out, n, unsigned char);
    pk_ent_off += n;
}

#endif /* PUNK_ENTROPY_H */
