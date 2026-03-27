#ifndef SEKHMET_CORE_H
#define SEKHMET_CORE_H

/*
 * sekhmet_core.h - Pure C orchestration layer (no Perl dependencies)
 *
 * Includes Horus's core library for time, random, and encoding,
 * then layers ULID-specific logic on top.
 *
 * Usage from another XS module:
 *     #define HORUS_FATAL(msg) croak("%s", (msg))
 *     #include "sekhmet_core.h"
 */

#include "horus_core.h"
#include "sekhmet_ulid.h"

#endif /* SEKHMET_CORE_H */
