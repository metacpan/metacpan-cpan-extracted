#ifndef SEKHMET_H
#define SEKHMET_H

/*
 * sekhmet.h - Perl XS bridge for Sekhmet ULID library
 *
 * Sets up Perl error handling, includes the pure C core,
 * and defines MY_CXT for thread-safe monotonic state.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* Route fatal errors through Perl's croak() */
#define HORUS_FATAL(msg) croak("%s", (msg))

/* Pull in Horus primitives + ULID logic */
#include "sekhmet_core.h"

/* ── MY_CXT for thread-safe monotonic state ────────────────────── */

#define MY_CXT_KEY "Sekhmet::_guts" XS_VERSION

typedef struct {
    sekhmet_monotonic_state_t mono_state;
} my_cxt_t;

START_MY_CXT

#endif /* SEKHMET_H */
