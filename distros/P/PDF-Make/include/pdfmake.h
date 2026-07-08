/*
 * libpdfmake — umbrella public header.
 *
 * Include this to get the full public C API of PDF::Make. For phase 01 the
 * surface is deliberately tiny: an error enum, an opaque doc forward
 * declaration, and a version accessor. Later phases add primitives,
 * writer/parser, filters, crypt, etc.
 */

#ifndef PDFMAKE_H
#define PDFMAKE_H

#ifdef __cplusplus
extern "C" {
#endif

#include "pdfmake_types.h"
#include "pdfmake_arena.h"

/* Compile-time version of the library. Matches $VERSION in lib/PDF/Make.pm. */
#define PDFMAKE_VERSION "0.06"

/* Returns the library version string. Phase 01 smoke symbol. */
const char *pdfmake_version(void);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_H */
