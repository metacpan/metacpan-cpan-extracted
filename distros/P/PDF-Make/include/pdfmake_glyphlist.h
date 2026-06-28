/*
 * pdfmake_glyphlist.h — Adobe Glyph List (AGL) lookups.
 *
 * Maps PostScript glyph names to Unicode codepoints for /Encoding dict
 * /Differences array resolution. Supports:
 *
 *   - Named glyphs from the AGL: /A -> U+0041, /Aacute -> U+00C1, ...
 *   - "uniXXXX" form (4 hex digits, BMP only): /uni00C1 -> U+00C1
 *   - "uXXXXXX" / "uXXXXXXXX" form (4-8 hex digits, up to U+10FFFF)
 *
 * Reference: Adobe Glyph List v2.0, §9.10.2 (PDF 32000).
 */

#ifndef PDFMAKE_GLYPHLIST_H
#define PDFMAKE_GLYPHLIST_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Map a glyph name to Unicode.
 * Returns 0 if not found (callers should treat 0 as "no mapping").
 */
uint32_t pdfmake_glyphname_to_unicode(const char *name);

/* Number of AGL entries (diagnostics). */
size_t pdfmake_glyphlist_size(void);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_GLYPHLIST_H */
