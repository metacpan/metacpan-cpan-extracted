/*
 * pdfmake_ttf.c - TrueType font parser implementation
 *
 * Parses TrueType/OpenType fonts, extracts metrics, provides cmap lookup,
 * and supports subsetting for PDF embedding.
 *
 * Reference: OpenType specification (Microsoft), TrueType reference (Apple)
 */

#include "pdfmake_font.h"
#include "pdfmake_arena.h"
#include "pdfmake_internal.h"   /* pdfmake_read_be16 / be32 / sbe16 */
#include <string.h>
#include <stdlib.h>

/*============================================================================
 * TTF table tags
 *==========================================================================*/

#define TAG(a,b,c,d) (((uint32_t)(a)<<24)|((uint32_t)(b)<<16)|((uint32_t)(c)<<8)|(d))

#define TAG_CMAP TAG('c','m','a','p')
#define TAG_GLYF TAG('g','l','y','f')
#define TAG_HEAD TAG('h','e','a','d')
#define TAG_HHEA TAG('h','h','e','a')
#define TAG_HMTX TAG('h','m','t','x')
#define TAG_LOCA TAG('l','o','c','a')
#define TAG_MAXP TAG('m','a','x','p')
#define TAG_NAME TAG('n','a','m','e')
#define TAG_OS2  TAG('O','S','/','2')
#define TAG_POST TAG('p','o','s','t')
#define TAG_CVT  TAG('c','v','t',' ')
#define TAG_FPGM TAG('f','p','g','m')
#define TAG_PREP TAG('p','r','e','p')

/*============================================================================
 * TTF parsing - table directory
 *==========================================================================*/

static int ttf_locate_table(const uint8_t *data, size_t data_len, 
                            uint16_t num_tables, uint32_t tag, 
                            uint32_t *offset, uint32_t *length) {
    const uint8_t *p;
    uint16_t i;
    (void)data_len;
    p = data + 12;  /* Skip offset table header */
    
    for (i = 0; i < num_tables; i++) {
        uint32_t t = pdfmake_read_be32(p);
        if (t == tag) {
            *offset = pdfmake_read_be32(p + 8);
            *length = pdfmake_read_be32(p + 12);
            return 1;
        }
        p += 16;
    }
    return 0;
}

/*============================================================================
 * TTF parsing main entry
 *==========================================================================*/

pdfmake_ttf_t *pdfmake_ttf_parse(pdfmake_arena_t *arena,
                                  const uint8_t *data, size_t len) {
    uint32_t sfnt_version;
    uint16_t num_tables;
    pdfmake_ttf_t *ttf;
    size_t bitmap_size;

    if (!arena || !data || len < 12) return NULL;
    
    sfnt_version = pdfmake_read_be32(data);
    
    /* Check for valid TrueType signature */
    if (sfnt_version != 0x00010000 && sfnt_version != TAG('t','r','u','e') &&
        sfnt_version != TAG('O','T','T','O')) {
        return NULL;
    }
    
    num_tables = pdfmake_read_be16(data + 4);
    if (len < 12 + num_tables * 16) return NULL;
    
    ttf = pdfmake_arena_alloc(arena, sizeof(pdfmake_ttf_t));
    if (!ttf) return NULL;
    memset(ttf, 0, sizeof(pdfmake_ttf_t));
    
    ttf->data = data;
    ttf->data_len = len;
    
    /* Locate tables */
    #define LOCATE(member, tag_val) \
        ttf_locate_table(data, len, num_tables, tag_val, &ttf->member.offset, &ttf->member.length)
    
    LOCATE(head, TAG_HEAD);
    LOCATE(hhea, TAG_HHEA);
    LOCATE(hmtx, TAG_HMTX);
    LOCATE(maxp, TAG_MAXP);
    LOCATE(cmap, TAG_CMAP);
    LOCATE(glyf, TAG_GLYF);
    LOCATE(loca, TAG_LOCA);
    LOCATE(name, TAG_NAME);
    LOCATE(post, TAG_POST);
    LOCATE(os2, TAG_OS2);
    LOCATE(cvt, TAG_CVT);
    LOCATE(fpgm, TAG_FPGM);
    LOCATE(prep, TAG_PREP);
    
    #undef LOCATE
    
    /* Parse head */
    if (ttf->head.length >= 54) {
        const uint8_t *p = data + ttf->head.offset;
        ttf->units_per_em = pdfmake_read_be16(p + 18);
        ttf->x_min = pdfmake_read_sbe16(p + 36);
        ttf->y_min = pdfmake_read_sbe16(p + 38);
        ttf->x_max = pdfmake_read_sbe16(p + 40);
        ttf->y_max = pdfmake_read_sbe16(p + 42);
        ttf->mac_style = pdfmake_read_sbe16(p + 44);
        ttf->index_to_loc_format = pdfmake_read_sbe16(p + 50);
    }
    
    /* Parse maxp */
    if (ttf->maxp.length >= 6) {
        ttf->num_glyphs = pdfmake_read_be16(data + ttf->maxp.offset + 4);
    }
    
    /* Parse hhea */
    if (ttf->hhea.length >= 36) {
        const uint8_t *p = data + ttf->hhea.offset;
        ttf->ascender = pdfmake_read_sbe16(p + 4);
        ttf->descender = pdfmake_read_sbe16(p + 6);
        ttf->line_gap = pdfmake_read_sbe16(p + 8);
        ttf->num_h_metrics = pdfmake_read_be16(p + 34);
    }
    
    /* Parse OS/2 if present */
    if (ttf->os2.length >= 78) {
        const uint8_t *p = data + ttf->os2.offset;
        ttf->has_os2 = 1;
        ttf->us_weight_class = pdfmake_read_be16(p + 4);
        ttf->us_width_class = pdfmake_read_be16(p + 6);
        ttf->fs_selection = pdfmake_read_be16(p + 62);
        
        if (ttf->os2.length >= 72) {
            ttf->s_typo_ascender = pdfmake_read_sbe16(p + 68);
            ttf->s_typo_descender = pdfmake_read_sbe16(p + 70);
            ttf->s_typo_line_gap = pdfmake_read_sbe16(p + 72);
        }
        if (ttf->os2.length >= 90) {
            ttf->s_x_height = pdfmake_read_sbe16(p + 86);
            ttf->s_cap_height = pdfmake_read_sbe16(p + 88);
        }
    }
    
    /* Find best cmap subtable */
    if (ttf->cmap.length >= 4) {
        const uint8_t *p = data + ttf->cmap.offset;
        uint16_t num_subtables = pdfmake_read_be16(p + 2);
        uint16_t i;
        
        p += 4;
        for (i = 0; i < num_subtables && ttf->cmap.offset + 4 + i*8 + 8 <= len; i++) {
            uint16_t platform = pdfmake_read_be16(p);
            uint16_t encoding = pdfmake_read_be16(p + 2);
            uint32_t subtable_offset = pdfmake_read_be32(p + 4);
            
            if (ttf->cmap.offset + subtable_offset + 2 <= len) {
                uint16_t format = pdfmake_read_be16(data + ttf->cmap.offset + subtable_offset);
                
                /* Prefer format 12 (full Unicode) then format 4 (BMP) */
                if (format == 12 && ((platform == 3 && encoding == 10) || 
                                     (platform == 0 && encoding >= 3))) {
                    ttf->cmap_format = 12;
                    ttf->cmap_offset = ttf->cmap.offset + subtable_offset;
                } else if (format == 4 && ttf->cmap_format != 12 &&
                           ((platform == 3 && encoding == 1) ||
                            (platform == 0 && encoding <= 3))) {
                    ttf->cmap_format = 4;
                    ttf->cmap_offset = ttf->cmap.offset + subtable_offset;
                }
            }
            p += 8;
        }
    }
    
    /* Allocate used glyph bitmap */
    bitmap_size = (ttf->num_glyphs + 7) / 8;
    ttf->used_glyphs = pdfmake_arena_alloc(arena, bitmap_size);
    if (ttf->used_glyphs) {
        memset(ttf->used_glyphs, 0, bitmap_size);
    }
    ttf->used_count = 0;
    
    return ttf;
}

/*============================================================================
 * cmap format 4 decoder (BMP)
 *==========================================================================*/

static uint16_t cmap_format4_lookup(const pdfmake_ttf_t *ttf, uint32_t codepoint) {
    const uint8_t *p;
    uint16_t length, seg_count_x2, seg_count;
    const uint8_t *end_codes, *start_codes, *id_deltas, *id_range_offsets;
    uint16_t lo, hi;
    uint16_t end_code, start_code;
    int16_t id_delta;
    uint16_t id_range_offset;
    uint16_t glyph_id;
    if (codepoint > 0xFFFF) return 0;  /* Format 4 only handles BMP */
    
    p = ttf->data + ttf->cmap_offset;
    
    length = pdfmake_read_be16(p + 2);
    seg_count_x2 = pdfmake_read_be16(p + 6);
    seg_count = seg_count_x2 / 2;
    
    if (ttf->cmap_offset + length > ttf->data_len) return 0;
    
    end_codes = p + 14;
    start_codes = end_codes + seg_count_x2 + 2;
    id_deltas = start_codes + seg_count_x2;
    id_range_offsets = id_deltas + seg_count_x2;
    
    /* Binary search for segment */
    lo = 0; hi = seg_count;
    while (lo < hi) {
        uint16_t mid = lo + (hi - lo) / 2;
        uint16_t mid_end = pdfmake_read_be16(end_codes + mid * 2);
        if (mid_end < codepoint) {
            lo = mid + 1;
        } else {
            hi = mid;
        }
    }
    
    if (lo >= seg_count) return 0;
    
    end_code = pdfmake_read_be16(end_codes + lo * 2);
    start_code = pdfmake_read_be16(start_codes + lo * 2);
    
    if (codepoint < start_code || codepoint > end_code) return 0;
    
    id_delta = pdfmake_read_sbe16(id_deltas + lo * 2);
    id_range_offset = pdfmake_read_be16(id_range_offsets + lo * 2);
    
    if (id_range_offset == 0) {
        glyph_id = (uint16_t)((codepoint + id_delta) & 0xFFFF);
    } else {
        const uint8_t *glyph_addr = id_range_offsets + lo * 2 + id_range_offset +
                                    (codepoint - start_code) * 2;
        if (glyph_addr >= ttf->data + ttf->data_len - 1) return 0;
        glyph_id = pdfmake_read_be16(glyph_addr);
        if (glyph_id != 0) {
            glyph_id = (uint16_t)((glyph_id + id_delta) & 0xFFFF);
        }
    }
    
    return glyph_id;
}

/*============================================================================
 * cmap format 12 decoder (full Unicode)
 *==========================================================================*/

static uint16_t cmap_format12_lookup(const pdfmake_ttf_t *ttf, uint32_t codepoint) {
    const uint8_t *p = ttf->data + ttf->cmap_offset;
    const uint8_t *groups;
    uint32_t length, num_groups;
    uint32_t lo, hi;
    uint32_t start_code, end_code, start_glyph;
    
    length = pdfmake_read_be32(p + 4);
    num_groups = pdfmake_read_be32(p + 12);
    
    if (ttf->cmap_offset + length > ttf->data_len) return 0;
    if (length < 16 + num_groups * 12) return 0;
    
    groups = p + 16;
    
    /* Binary search */
    lo = 0; hi = num_groups;
    while (lo < hi) {
        uint32_t mid = lo + (hi - lo) / 2;
        uint32_t mid_end = pdfmake_read_be32(groups + mid * 12 + 4);
        if (mid_end < codepoint) {
            lo = mid + 1;
        } else {
            hi = mid;
        }
    }
    
    if (lo >= num_groups) return 0;
    
    start_code = pdfmake_read_be32(groups + lo * 12);
    end_code = pdfmake_read_be32(groups + lo * 12 + 4);
    start_glyph = pdfmake_read_be32(groups + lo * 12 + 8);
    
    if (codepoint < start_code || codepoint > end_code) return 0;
    
    return (uint16_t)(start_glyph + (codepoint - start_code));
}

/*============================================================================
 * cmap lookup (public API)
 *==========================================================================*/

uint16_t pdfmake_ttf_cmap_lookup(const pdfmake_ttf_t *ttf, uint32_t codepoint) {
    if (!ttf || ttf->cmap_offset == 0) return 0;
    
    if (ttf->cmap_format == 12) {
        return cmap_format12_lookup(ttf, codepoint);
    } else if (ttf->cmap_format == 4) {
        return cmap_format4_lookup(ttf, codepoint);
    }
    
    return 0;
}

/*============================================================================
 * Glyph advance width lookup
 *==========================================================================*/

uint16_t pdfmake_ttf_glyph_advance(const pdfmake_ttf_t *ttf, uint16_t glyph_id) {
    const uint8_t *hmtx;
    uint16_t advance;
    if (!ttf || glyph_id >= ttf->num_glyphs) return 0;
    if (ttf->hmtx.offset == 0) return 0;
    
    hmtx = ttf->data + ttf->hmtx.offset;
    
    if (glyph_id < ttf->num_h_metrics) {
        advance = pdfmake_read_be16(hmtx + glyph_id * 4);
    } else {
        advance = pdfmake_read_be16(hmtx + (ttf->num_h_metrics - 1) * 4);
    }
    
    /* Convert from font units to 1/1000 em */
    if (ttf->units_per_em == 0) return advance;
    return (advance * 1000) / ttf->units_per_em;
}

/*============================================================================
 * Mark glyph as used (for subsetting)
 *==========================================================================*/

void pdfmake_ttf_mark_glyph(pdfmake_ttf_t *ttf, uint16_t glyph_id) {
    size_t byte;
    uint8_t bit;
    if (!ttf || !ttf->used_glyphs) return;
    if (glyph_id >= ttf->num_glyphs) return;
    
    byte = glyph_id / 8;
    bit = 1 << (glyph_id % 8);
    
    if (!(ttf->used_glyphs[byte] & bit)) {
        ttf->used_glyphs[byte] |= bit;
        ttf->used_count++;
    }
}
