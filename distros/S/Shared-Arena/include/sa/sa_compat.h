#ifndef SA_COMPAT_H
#define SA_COMPAT_H

/* sa_compat.h - what the perl floor costs, and what the perl headers take away.
 * Must be included FIRST, after the perl headers and before anything in sa/.
 *
 * ---- PERL_IMPLICIT_SYS rewrites the C library out from under a header -------
 *
 * On a perl built with PERL_IMPLICIT_SYS - which every Strawberry is - XSUB.h
 * redefines about a hundred CRT names as function-like macros: `close` becomes
 * PerlLIO_close, `malloc` becomes PerlMem_malloc, and each expands to something
 * that dereferences an interpreter the caller may not have.
 *
 * Everything under include/sa/ is deliberately perl-free, so that a harness or
 * a fuzzer with no interpreter can drive it. A perl-free function that calls
 * `close(fd)` is not perl-free at all once XSUB.h has been through it, and on a
 * POSIX perl configured with PERL_IMPLICIT_SYS it does not even compile.
 *
 * So the names this dist uses in its perl-free layer are put back. The region
 * belongs to no interpreter and outlives none of them, so the C library is the
 * right allocator and the raw syscalls are the right syscalls.
 *
 * The same trap has a second half that no #undef can fix: a STRUCT MEMBER named
 * `close` or `open` breaks at its call site, because the member name lands in
 * front of `(` where a function-like macro fires. Frozen 0.01 shipped broken on
 * the Strawberry 5.42 smoker for exactly that, in its ABI table's own selftest.
 * The rule for sa_abi.h is therefore to avoid the names entirely rather than
 * rely on parentheses: no member here is called open, close, read, write, stat,
 * link, unlink, send, recv, socket, select, time, exit, abort, malloc or free.
 */

#undef open
#undef close
#undef read
#undef write
#undef fstat
#undef stat
#undef unlink
#undef malloc
#undef calloc
#undef realloc
#undef free
#undef getpid
#undef kill

#include <stdlib.h>
#include <string.h>
#include <stdint.h>

/* Perl's own <stdint.h> reach varies; the format is uint32_t and uint64_t
 * throughout and 5.010 is the floor, which is where <stdint.h> became safe to
 * assume for the platforms this claims. */

#endif /* SA_COMPAT_H */
