#ifndef STENCIL_FILTERS_H
#define STENCIL_FILTERS_H

/* Built-in filter bodies: read `in`, write the result into `out` (a
 * render-state scratch SV that is grown and reused - the built-ins
 * never allocate at steady state beyond scratch growth). `in` is
 * always defined when these are called; undef passthrough is handled
 * by the caller. */

void stencil_filt_case(pTHX_ SV *in, SV *out, int to_upper);
void stencil_filt_trim(pTHX_ SV *in, SV *out);
void stencil_filt_html(pTHX_ SV *in, SV *out);
void stencil_filt_uri(pTHX_ SV *in, SV *out);
void stencil_filt_fmt(pTHX_ SV *in, SV *out, const char *fmt, STRLEN flen,
                      int src_utf8);

#endif /* STENCIL_FILTERS_H */
