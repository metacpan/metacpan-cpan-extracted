/*
 * pdfmake_tounicode.c - ToUnicode CMap generation
 *
 * Generates a ToUnicode CMap stream that maps glyph codes to Unicode
 * codepoints, enabling text extraction and copy/paste from PDFs.
 *
 * Reference: PDF spec §9.10.3, Adobe Technical Note #5014 (CMap)
 */

#include "pdfmake_font.h"
#include "pdfmake_buf.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

/*============================================================================
 * ToUnicode CMap structure
 *
 * The CMap maps character codes (glyph IDs for CIDFont) to Unicode.
 * We use bfchar entries for individual mappings and bfrange for
 * contiguous ranges.
 *==========================================================================*/

typedef struct {
    uint16_t glyph_id;
    uint32_t unicode;
} glyph_unicode_t;

/*============================================================================
 * Build glyph->Unicode mapping from reverse cmap lookup
 *==========================================================================*/

static int compare_gu(const void *a, const void *b) {
    const glyph_unicode_t *ga = a;
    const glyph_unicode_t *gb = b;
    if (ga->glyph_id < gb->glyph_id) return -1;
    if (ga->glyph_id > gb->glyph_id) return 1;
    return 0;
}

/*============================================================================
 * Generate ToUnicode CMap for font
 *==========================================================================*/

pdfmake_err_t pdfmake_tounicode_generate(const pdfmake_font_t *font,
                                          pdfmake_buf_t *out_buf) {
    pdfmake_ttf_t *ttf;
    size_t used_count;
    int i;
    size_t byte;
    uint8_t bit;
    glyph_unicode_t *mappings;
    size_t map_count;
    uint32_t cp;
    uint16_t gid;
    int exists;
    size_t j;
    size_t mi;
    size_t range_start;
    size_t range_len;
    size_t next;
    uint16_t gid_start;
    uint16_t gid_end;
    uint32_t unicode_start;
    size_t batch_count;
    size_t batch_start;
    size_t possible_range;
    uint32_t unicode;

    if (!font || !out_buf) return PDFMAKE_EINVAL;
    
    /* For Standard 14 fonts, use WinAnsi ToUnicode */
    if (font->type == PDFMAKE_FONT_TYPE1) {
        /* WinAnsi to Unicode mapping (codes 128-159 differ from Latin-1) */
        static const uint16_t winansi_unicode[] = {
            /* 128-143 */
            0x20AC, 0x0081, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021,
            0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x008D, 0x017D, 0x008F,
            /* 144-159 */
            0x0090, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
            0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x009D, 0x017E, 0x0178,
        };
        
        /* CMap header */
        pdfmake_buf_appendf(out_buf,
            "/CIDInit /ProcSet findresource begin\n"
            "12 dict begin\n"
            "begincmap\n"
            "/CIDSystemInfo <<\n"
            "  /Registry (Adobe)\n"
            "  /Ordering (UCS)\n"
            "  /Supplement 0\n"
            ">> def\n"
            "/CMapName /Adobe-Identity-UCS def\n"
            "/CMapType 2 def\n"
            "1 begincodespacerange\n"
            "<00> <FF>\n"
            "endcodespacerange\n"
        );
        
        /* Range 32-127: direct ASCII mapping */
        pdfmake_buf_appendf(out_buf,
            "2 beginbfrange\n"
            "<20> <7E> <0020>\n"
            "<A0> <FF> <00A0>\n"
            "endbfrange\n"
        );
        
        /* Individual mappings for 128-159 (WinAnsi special) */
        pdfmake_buf_appendf(out_buf, "32 beginbfchar\n");
        
        for (i = 0; i < 32; i++) {
            pdfmake_buf_appendf(out_buf, "<%02X> <%04X>\n", 
                128 + i, winansi_unicode[i]);
        }
        
        pdfmake_buf_appendf(out_buf, "endbfchar\n");
        
        /* CMap trailer */
        pdfmake_buf_appendf(out_buf,
            "endcmap\n"
            "CMapName currentdict /CMap defineresource pop\n"
            "end\n"
            "end\n"
        );
        
        return PDFMAKE_OK;
    }
    
    /* For TrueType fonts, build from used glyphs */
    if (font->type != PDFMAKE_FONT_TRUETYPE || !font->ttf) {
        return PDFMAKE_EINVAL;
    }
    
    ttf = font->ttf;
    
    /* Count used glyphs */
    used_count = 0;
    for (i = 1; i < ttf->num_glyphs; i++) {
        byte = i / 8;
        bit = 1 << (i % 8);
        if (ttf->used_glyphs && (ttf->used_glyphs[byte] & bit)) {
            used_count++;
        }
    }
    
    if (used_count == 0) {
        return PDFMAKE_OK;  /* Nothing to map */
    }
    
    /* Build glyph->unicode mapping by scanning used codepoints */
    /* We need to reverse the cmap lookup - scan common Unicode ranges */
    mappings = calloc(used_count, sizeof(glyph_unicode_t));
    if (!mappings) return PDFMAKE_ENOMEM;
    
    map_count = 0;
    
    /* Scan BMP range */
    for (cp = 0x20; cp < 0x10000 && map_count < used_count; cp++) {
        gid = pdfmake_ttf_cmap_lookup(ttf, cp);
        if (gid > 0) {
            byte = gid / 8;
            bit = 1 << (gid % 8);
            if (ttf->used_glyphs && (ttf->used_glyphs[byte] & bit)) {
                /* Check if we already have this glyph */
                exists = 0;
                for (j = 0; j < map_count; j++) {
                    if (mappings[j].glyph_id == gid) {
                        exists = 1;
                        break;
                    }
                }
                if (!exists) {
                    mappings[map_count].glyph_id = gid;
                    mappings[map_count].unicode = cp;
                    map_count++;
                }
            }
        }
    }
    
    if (map_count == 0) {
        free(mappings);
        return PDFMAKE_OK;
    }
    
    /* Sort by glyph ID */
    qsort(mappings, map_count, sizeof(glyph_unicode_t), compare_gu);
    
    /* CMap header */
    pdfmake_buf_appendf(out_buf,
        "/CIDInit /ProcSet findresource begin\n"
        "12 dict begin\n"
        "begincmap\n"
        "/CIDSystemInfo <<\n"
        "  /Registry (Adobe)\n"
        "  /Ordering (UCS)\n"
        "  /Supplement 0\n"
        ">> def\n"
        "/CMapName /Adobe-Identity-UCS def\n"
        "/CMapType 2 def\n"
        "1 begincodespacerange\n"
        "<0000> <FFFF>\n"
        "endcodespacerange\n"
    );
    
    /* Emit mappings */
    mi = 0;
    while (mi < map_count) {
        /* Try to find a range */
        range_start = mi;
        range_len = 1;
        
        while (range_start + range_len < map_count) {
            next = range_start + range_len;
            if (mappings[next].glyph_id == mappings[range_start].glyph_id + range_len &&
                mappings[next].unicode == mappings[range_start].unicode + range_len) {
                range_len++;
            } else {
                break;
            }
        }
        
        if (range_len >= 3) {
            /* Emit as range */
            pdfmake_buf_appendf(out_buf, "1 beginbfrange\n");
            
            gid_start = mappings[range_start].glyph_id;
            gid_end = gid_start + range_len - 1;
            unicode_start = mappings[range_start].unicode;
            
            pdfmake_buf_appendf(out_buf, "<%04X> <%04X> <%04X>\n",
                gid_start, gid_end, (unsigned)unicode_start);
            
            pdfmake_buf_appendf(out_buf, "endbfrange\n");
            mi += range_len;
        } else {
            /* Emit individual characters */
            batch_count = 0;
            batch_start = mi;
            
            while (mi < map_count && batch_count < 100) {
                possible_range = 1;
                while (mi + possible_range < map_count) {
                    next = mi + possible_range;
                    if (mappings[next].glyph_id == mappings[mi].glyph_id + possible_range &&
                        mappings[next].unicode == mappings[mi].unicode + possible_range) {
                        possible_range++;
                    } else {
                        break;
                    }
                }
                
                if (possible_range >= 3) break;
                
                batch_count++;
                mi++;
            }
            
            if (batch_count > 0) {
                pdfmake_buf_appendf(out_buf, "%zu beginbfchar\n", batch_count);
                
                for (j = 0; j < batch_count; j++) {
                    gid = mappings[batch_start + j].glyph_id;
                    unicode = mappings[batch_start + j].unicode;
                    pdfmake_buf_appendf(out_buf, "<%04X> <%04X>\n", gid, (unsigned)unicode);
                }
                
                pdfmake_buf_appendf(out_buf, "endbfchar\n");
            }
        }
    }
    
    /* CMap trailer */
    pdfmake_buf_appendf(out_buf,
        "endcmap\n"
        "CMapName currentdict /CMap defineresource pop\n"
        "end\n"
        "end\n"
    );
    
    free(mappings);
    return PDFMAKE_OK;
}

/*============================================================================
 * Generate CID width array (W entry for CIDFont)
 * 
 * Format: [ c [w1 w2 ...] c [w1 w2 ...] ... ]
 * or:     [ c_first c_last w ]
 *==========================================================================*/

pdfmake_err_t pdfmake_cid_widths(const pdfmake_font_t *font,
                                  pdfmake_buf_t *out_buf) {
    pdfmake_ttf_t *ttf;
    size_t used_count;
    int i;
    size_t byte;
    uint8_t bit;
    int in_group;
    uint16_t advance;

    if (!font || !out_buf) return PDFMAKE_EINVAL;
    
    if (font->type != PDFMAKE_FONT_TRUETYPE || !font->ttf) {
        return PDFMAKE_EINVAL;
    }
    
    ttf = font->ttf;
    
    /* Collect used glyphs in order */
    used_count = 0;
    for (i = 0; i < ttf->num_glyphs; i++) {
        byte = i / 8;
        bit = 1 << (i % 8);
        if (ttf->used_glyphs && (ttf->used_glyphs[byte] & bit)) {
            used_count++;
        }
    }
    
    if (used_count == 0) {
        pdfmake_buf_appendf(out_buf, "[]");
        return PDFMAKE_OK;
    }
    
    pdfmake_buf_appendf(out_buf, "[");
    
    /* Group consecutive glyphs */
    in_group = 0;
    
    for (i = 0; i < ttf->num_glyphs; i++) {
        byte = i / 8;
        bit = 1 << (i % 8);
        
        if (ttf->used_glyphs && (ttf->used_glyphs[byte] & bit)) {
            if (!in_group) {
                in_group = 1;
                pdfmake_buf_appendf(out_buf, " %d [", i);
            }
            
            advance = pdfmake_ttf_glyph_advance(ttf, i);
            pdfmake_buf_appendf(out_buf, " %d", advance);
        } else if (in_group) {
            pdfmake_buf_appendf(out_buf, " ]");
            in_group = 0;
        }
    }
    
    if (in_group) {
        pdfmake_buf_appendf(out_buf, " ]");
    }
    
    pdfmake_buf_appendf(out_buf, " ]");
    
    return PDFMAKE_OK;
}
