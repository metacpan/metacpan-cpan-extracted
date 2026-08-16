/*
 * libpdfmake - the rules a template runs under.
 *
 * Templates are written by whoever holds the account and run on our machines,
 * over data that often came from someone else again - an end customer's name
 * on a tenant's invoice. Two things follow, and both are decided here rather
 * than in Perl: a template must not be able to reach code, and a data value
 * must not be able to become markup.
 */

#ifndef PDFMAKE_MARKUP_PROFILE_H
#define PDFMAKE_MARKUP_PROFILE_H

#include "pdfmake_types.h"

#ifdef __cplusplus
extern "C" {
#endif

#define PDFMAKE_PROFILE_ERR_LEN 256

/*
 * Refuse the constructs a template may not use. Returns 1 when the source is
 * acceptable, or 0 with err filled in and err_line set to the line the
 * offending construct is on.
 */
int pdfmake_profile_check_source(const char *src, size_t len,
                                 uint32_t *err_line,
                                 char *err, size_t errlen);

/*
 * The two filters this profile adds on top of Stencil's own. Both write a
 * null-terminated result and return its length, or write "" and return 0 for
 * anything that is not a number. Pure functions of their input: a filter that
 * could do more would be a way back to code.
 */
size_t pdfmake_profile_money(const char *v, size_t len,
                             char *out, size_t outlen);
size_t pdfmake_profile_number(const char *v, size_t len,
                              char *out, size_t outlen);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_MARKUP_PROFILE_H */
