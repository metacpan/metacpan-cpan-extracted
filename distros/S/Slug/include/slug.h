#ifndef SLUG_H
#define SLUG_H

/*
 * slug.h — Perl bridge layer
 *
 * Includes Perl headers, ppport.h, then the pure-C slug_core.h.
 * Defines the SLUG_FATAL macro for error reporting through croak().
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "slug_core.h"

#endif /* SLUG_H */
