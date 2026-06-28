/*
 * pdfmake_ttf_subset.c - TrueType font subsetter
 *
 * Creates a minimal TrueType font containing only the glyphs used.
 * Required tables: head, hhea, maxp, loca, glyf, hmtx, cmap, post
 *
 * Reference: OpenType/TrueType specification
 */

#include "pdfmake_font.h"
#include "pdfmake_internal.h"
#include <string.h>
#include <stdlib.h>

/*============================================================================
 * Table tag helpers
 *==========================================================================*/

#define TAG(a,b,c,d) (((uint32_t)(a)<<24)|((uint32_t)(b)<<16)|((uint32_t)(c)<<8)|(d))

/*============================================================================
 * Calculate TTF table checksum
 *==========================================================================*/

static uint32_t ttf_checksum(const uint8_t *data, size_t len) {
    uint32_t sum = 0;
    size_t nwords = (len + 3) / 4;
    size_t i;
    
    for (i = 0; i < nwords; i++) {
        uint32_t word = 0;
        size_t offset = i * 4;
        
        if (offset < len) word |= (uint32_t)data[offset] << 24;
        if (offset + 1 < len) word |= (uint32_t)data[offset + 1] << 16;
        if (offset + 2 < len) word |= (uint32_t)data[offset + 2] << 8;
        if (offset + 3 < len) word |= (uint32_t)data[offset + 3];
        
        sum += word;
    }
    
    return sum;
}

/*============================================================================
 * Build glyph remapping table
 *==========================================================================*/

typedef struct {
    uint16_t *old_to_new;  /* old_glyph_id -> new_glyph_id */
    uint16_t *new_to_old;  /* new_glyph_id -> old_glyph_id */
    uint16_t new_count;
} glyph_map_t;

static glyph_map_t *build_glyph_map(pdfmake_ttf_t *ttf) {
    glyph_map_t *map = calloc(1, sizeof(glyph_map_t));
    if (!map) return NULL;
    
    map->old_to_new = calloc(ttf->num_glyphs, sizeof(uint16_t));
    map->new_to_old = calloc(ttf->num_glyphs, sizeof(uint16_t));
    if (!map->old_to_new || !map->new_to_old) {
        free(map->old_to_new);
        free(map->new_to_old);
        free(map);
        return NULL;
    }
    
    /* Always include glyph 0 (.notdef) */
    {
        int i;
        map->old_to_new[0] = 0;
        map->new_to_old[0] = 0;
        map->new_count = 1;
        
        /* Add used glyphs in order */
        for (i = 1; i < ttf->num_glyphs; i++) {
            size_t byte = i / 8;
            uint8_t bit = 1 << (i % 8);
            
            if (ttf->used_glyphs[byte] & bit) {
                map->old_to_new[i] = map->new_count;
                map->new_to_old[map->new_count] = i;
                map->new_count++;
            }
        }
    }
    
    return map;
}

static void free_glyph_map(glyph_map_t *map) {
    if (!map) return;
    free(map->old_to_new);
    free(map->new_to_old);
    free(map);
}

/*============================================================================
 * Get glyph data location from loca table
 *==========================================================================*/

static int get_glyph_location(pdfmake_ttf_t *ttf, uint16_t glyph_id,
                              uint32_t *offset, uint32_t *length) {
    const uint8_t *loca;
    uint32_t off1, off2;
    
    if (glyph_id >= ttf->num_glyphs) return 0;
    
    loca = ttf->data + ttf->loca.offset;
    
    if (ttf->index_to_loc_format == 0) {
        /* Short format: offsets are words, multiply by 2 */
        off1 = pdfmake_read_be16(loca + glyph_id * 2) * 2;
        off2 = pdfmake_read_be16(loca + (glyph_id + 1) * 2) * 2;
    } else {
        /* Long format: offsets are dwords */
        off1 = pdfmake_read_be32(loca + glyph_id * 4);
        off2 = pdfmake_read_be32(loca + (glyph_id + 1) * 4);
    }
    
    *offset = off1;
    *length = off2 - off1;
    return 1;
}

/*============================================================================
 * Build subset glyf table
 *==========================================================================*/

typedef struct {
    uint8_t *data;
    size_t len;
    uint32_t *offsets;  /* num_glyphs + 1 offsets for loca */
} glyf_result_t;

static glyf_result_t *build_subset_glyf(pdfmake_ttf_t *ttf, glyph_map_t *map) {
    glyf_result_t *result = calloc(1, sizeof(glyf_result_t));
    if (!result) return NULL;
    
    result->offsets = calloc(map->new_count + 1, sizeof(uint32_t));
    if (!result->offsets) {
        free(result);
        return NULL;
    }
    
    /* First pass: calculate total size */
    {
        size_t total = 0;
        uint16_t i;
        for (i = 0; i < map->new_count; i++) {
            uint16_t old_id = map->new_to_old[i];
            uint32_t off, len;
            if (get_glyph_location(ttf, old_id, &off, &len)) {
                /* Align to 2 bytes (short loca format) or 4 bytes (long) */
                total += len;
                if (len % 2) total++;  /* Pad to even */
            }
        }
    
        result->data = calloc(1, total > 0 ? total : 1);
    }
    if (!result->data) {
        free(result->offsets);
        free(result);
        return NULL;
    }
    
    /* Second pass: copy glyph data */
    {
        size_t pos = 0;
        uint16_t i;
        for (i = 0; i < map->new_count; i++) {
            uint16_t old_id;
            uint32_t off, len;
            result->offsets[i] = pos;
            
            old_id = map->new_to_old[i];
            if (get_glyph_location(ttf, old_id, &off, &len) && len > 0) {
                memcpy(result->data + pos, ttf->data + ttf->glyf.offset + off, len);
                pos += len;
                if (len % 2) pos++;  /* Pad to even */
            }
        }
        result->offsets[map->new_count] = pos;
        result->len = pos;
    }
    
    return result;
}

static void free_glyf_result(glyf_result_t *r) {
    if (!r) return;
    free(r->data);
    free(r->offsets);
    free(r);
}

/*============================================================================
 * Build subset loca table
 *==========================================================================*/

static uint8_t *build_subset_loca(glyph_map_t *map, glyf_result_t *glyf, 
                                   int short_format, size_t *out_len) {
    size_t count = map->new_count + 1;
    size_t len;
    uint8_t *data;
    
    if (short_format) {
        size_t i;
        len = count * 2;
        data = calloc(1, len);
        if (!data) return NULL;
        
        for (i = 0; i < count; i++) {
            pdfmake_write_be16(data + i * 2, glyf->offsets[i] / 2);
        }
    } else {
        size_t i;
        len = count * 4;
        data = calloc(1, len);
        if (!data) return NULL;
        
        for (i = 0; i < count; i++) {
            pdfmake_write_be32(data + i * 4, glyf->offsets[i]);
        }
    }
    
    *out_len = len;
    return data;
}

/*============================================================================
 * Build subset hmtx table
 *==========================================================================*/

static uint8_t *build_subset_hmtx(pdfmake_ttf_t *ttf, glyph_map_t *map, 
                                   size_t *out_len) {
    /* Each glyph gets full metric (advance + lsb) */
    size_t len = map->new_count * 4;
    uint8_t *data = calloc(1, len);
    const uint8_t *hmtx;
    uint16_t i;
    if (!data) return NULL;
    
    hmtx = ttf->data + ttf->hmtx.offset;
    
    for (i = 0; i < map->new_count; i++) {
        uint16_t old_id = map->new_to_old[i];
        uint16_t advance, lsb;
        
        if (old_id < ttf->num_h_metrics) {
            advance = pdfmake_read_be16(hmtx + old_id * 4);
            lsb = pdfmake_read_be16(hmtx + old_id * 4 + 2);
        } else {
            /* Last advance, variable lsb */
            size_t lsb_offset;
            advance = pdfmake_read_be16(hmtx + (ttf->num_h_metrics - 1) * 4);
            lsb_offset = ttf->num_h_metrics * 4 + 
                               (old_id - ttf->num_h_metrics) * 2;
            if (ttf->hmtx.offset + lsb_offset + 2 <= ttf->data_len) {
                lsb = pdfmake_read_be16(hmtx + lsb_offset);
            } else {
                lsb = 0;
            }
        }
        
        pdfmake_write_be16(data + i * 4, advance);
        pdfmake_write_be16(data + i * 4 + 2, lsb);
    }
    
    *out_len = len;
    return data;
}

/*============================================================================
 * Build minimal cmap table (format 4 or format 12)
 * 
 * For PDF embedding, we typically use Identity-H/Identity-V with CIDFont,
 * so cmap maps GID to GID directly. But for simple TrueType, we need
 * a proper Unicode cmap.
 *==========================================================================*/

static uint8_t *build_subset_cmap_format4(glyph_map_t *map, size_t *out_len) {
    /* Build a simple format 4 cmap for the subset */
    /* For PDF embedding with /Identity-H, glyphs are accessed by GID directly */
    /* We create a minimal cmap that maps GID -> GID */
    
    /* Simplified: single segment 0 to num_glyphs-1 */
    uint16_t seg_count = 2;  /* One real segment + terminator */
    size_t len = 4 + 8 + 14 + seg_count * 8;  /* header + encoding record + format 4 */
    
    uint8_t *data = calloc(1, len);
    if (!data) return NULL;
    
    /* cmap header */
    pdfmake_write_be16(data, 0);      /* version */
    pdfmake_write_be16(data + 2, 1);  /* numTables */
    
    /* Encoding record: platform 3 (Windows), encoding 1 (Unicode BMP) */
    pdfmake_write_be16(data + 4, 3);   /* platformID */
    pdfmake_write_be16(data + 6, 1);   /* encodingID */
    pdfmake_write_be32(data + 8, 12);  /* offset to subtable */
    
    /* Format 4 subtable */
    {
    uint8_t *fmt = data + 12;
    uint16_t fmt_len = 14 + seg_count * 8;
    /* Segment arrays */
    uint8_t *endCode;
    uint8_t *reservedPad;
    uint8_t *startCode;
    uint8_t *idDelta;
    uint8_t *idRangeOffset;
    
    pdfmake_write_be16(fmt, 4);           /* format */
    pdfmake_write_be16(fmt + 2, fmt_len); /* length */
    pdfmake_write_be16(fmt + 4, 0);       /* language */
    pdfmake_write_be16(fmt + 6, seg_count * 2);  /* segCountX2 */
    pdfmake_write_be16(fmt + 8, 2);       /* searchRange */
    pdfmake_write_be16(fmt + 10, 0);      /* entrySelector */
    pdfmake_write_be16(fmt + 12, 2);      /* rangeShift */
    
    endCode = fmt + 14;
    reservedPad = endCode + seg_count * 2;
    startCode = reservedPad + 2;
    idDelta = startCode + seg_count * 2;
    idRangeOffset = idDelta + seg_count * 2;
    
    /* Segment 0: 0 to num_glyphs-1 -> direct mapping (delta=0) */
    pdfmake_write_be16(endCode, map->new_count - 1);
    pdfmake_write_be16(startCode, 0);
    pdfmake_write_be16(idDelta, 0);
    pdfmake_write_be16(idRangeOffset, 0);
    
    /* Terminator segment (required): 0xFFFF */
    pdfmake_write_be16(endCode + 2, 0xFFFF);
    pdfmake_write_be16(reservedPad, 0);
    pdfmake_write_be16(startCode + 2, 0xFFFF);
    pdfmake_write_be16(idDelta + 2, 1);
    pdfmake_write_be16(idRangeOffset + 2, 0);
    }
    
    *out_len = len;
    return data;
}

/*============================================================================
 * Copy and adjust head table
 *==========================================================================*/

static uint8_t *build_subset_head(pdfmake_ttf_t *ttf, int short_loca,
                                   size_t *out_len) {
    uint8_t *data;
    if (ttf->head.length < 54) return NULL;
    
    data = malloc(ttf->head.length);
    if (!data) return NULL;
    
    memcpy(data, ttf->data + ttf->head.offset, ttf->head.length);
    
    /* Update indexToLocFormat */
    pdfmake_write_be16(data + 50, short_loca ? 0 : 1);
    
    /* Clear checkSumAdjustment (will be updated later) */
    pdfmake_write_be32(data + 8, 0);
    
    *out_len = ttf->head.length;
    return data;
}

/*============================================================================
 * Copy and adjust maxp table
 *==========================================================================*/

static uint8_t *build_subset_maxp(pdfmake_ttf_t *ttf, glyph_map_t *map,
                                   size_t *out_len) {
    uint8_t *data = malloc(ttf->maxp.length);
    if (!data) return NULL;
    
    memcpy(data, ttf->data + ttf->maxp.offset, ttf->maxp.length);
    
    /* Update numGlyphs */
    pdfmake_write_be16(data + 4, map->new_count);
    
    *out_len = ttf->maxp.length;
    return data;
}

/*============================================================================
 * Copy and adjust hhea table
 *==========================================================================*/

static uint8_t *build_subset_hhea(pdfmake_ttf_t *ttf, glyph_map_t *map,
                                   size_t *out_len) {
    uint8_t *data = malloc(ttf->hhea.length);
    if (!data) return NULL;
    
    memcpy(data, ttf->data + ttf->hhea.offset, ttf->hhea.length);
    
    /* Update numberOfHMetrics - all glyphs have full metrics */
    pdfmake_write_be16(data + 34, map->new_count);
    
    *out_len = ttf->hhea.length;
    return data;
}

/*============================================================================
 * Build minimal post table
 *==========================================================================*/

static uint8_t *build_subset_post(size_t *out_len) {
    /* Create minimal version 3.0 post table (no glyph names) */
    size_t len = 32;
    uint8_t *data = calloc(1, len);
    if (!data) return NULL;
    
    pdfmake_write_be32(data, 0x00030000);  /* version 3.0 */
    /* italicAngle, underlinePosition, etc. default to 0 */
    
    *out_len = len;
    return data;
}

/*============================================================================
 * Assemble final subset TTF
 *==========================================================================*/

pdfmake_err_t pdfmake_ttf_subset(const pdfmake_ttf_t *ttf, pdfmake_buf_t *out_buf) {
    /* Cast away const for internal processing - we don't modify the source */
    pdfmake_ttf_t *mutable_ttf;
    glyph_map_t *map;
    glyf_result_t *glyf;
    int short_loca;
    size_t loca_len, hmtx_len, cmap_len, head_len, maxp_len, hhea_len, post_len;
    uint8_t *loca, *hmtx, *cmap, *head, *maxp, *hhea, *post;
    const int num_tables = 8;  /* head, hhea, maxp, loca, glyf, hmtx, cmap, post */
    size_t header_size;
    /* Align each table to 4 bytes */
    #define ALIGN4(x) (((x) + 3) & ~3)
    size_t tables_size;
    size_t total_size;
    uint8_t *result;
    int power, selector;
    uint8_t *dir;
    size_t offset;
    int i;
    uint32_t file_checksum;
    uint32_t head_offset;
    struct table_entry {
        uint32_t tag;
        uint8_t *data;
        size_t len;
    } tables[8];
    
    if (!ttf || !out_buf) return PDFMAKE_EINVAL;
    
    mutable_ttf = (pdfmake_ttf_t *)ttf;
    
    map = build_glyph_map(mutable_ttf);
    if (!map) return PDFMAKE_ENOMEM;
    
    /* Build subset tables */
    glyf = build_subset_glyf(mutable_ttf, map);
    if (!glyf) { free_glyph_map(map); return PDFMAKE_ENOMEM; }
    
    /* Determine if we can use short loca format */
    short_loca = (glyf->len / 2) <= 0xFFFF;
    
    loca = build_subset_loca(map, glyf, short_loca, &loca_len);
    hmtx = build_subset_hmtx(mutable_ttf, map, &hmtx_len);
    cmap = build_subset_cmap_format4(map, &cmap_len);
    head = build_subset_head(mutable_ttf, short_loca, &head_len);
    maxp = build_subset_maxp(mutable_ttf, map, &maxp_len);
    hhea = build_subset_hhea(mutable_ttf, map, &hhea_len);
    post = build_subset_post(&post_len);
    
    if (!loca || !hmtx || !cmap || !head || !maxp || !hhea || !post) {
        free(loca); free(hmtx); free(cmap); free(head);
        free(maxp); free(hhea); free(post);
        free_glyf_result(glyf);
        free_glyph_map(map);
        return PDFMAKE_ENOMEM;
    }
    
    /* Calculate file size */
    header_size = 12 + num_tables * 16;
    
    tables_size = ALIGN4(head_len) + ALIGN4(hhea_len) + ALIGN4(maxp_len) +
                         ALIGN4(cmap_len) + ALIGN4(hmtx_len) + ALIGN4(loca_len) +
                         ALIGN4(glyf->len) + ALIGN4(post_len);
    
    total_size = header_size + tables_size;
    
    result = calloc(1, total_size);
    if (!result) {
        free(loca); free(hmtx); free(cmap); free(head);
        free(maxp); free(hhea); free(post);
        free_glyf_result(glyf);
        free_glyph_map(map);
        return PDFMAKE_ENOMEM;
    }
    
    /* Write offset table header */
    pdfmake_write_be32(result, 0x00010000);    /* sfntVersion */
    pdfmake_write_be16(result + 4, num_tables);
    
    /* searchRange, entrySelector, rangeShift */
    power = 1; selector = 0;
    while (power * 2 <= num_tables) { power *= 2; selector++; }
    pdfmake_write_be16(result + 6, power * 16);
    pdfmake_write_be16(result + 8, selector);
    pdfmake_write_be16(result + 10, num_tables * 16 - power * 16);
    
    /* Table directory entries */
    tables[0].tag = TAG('c','m','a','p'); tables[0].data = cmap;       tables[0].len = cmap_len;
    tables[1].tag = TAG('g','l','y','f'); tables[1].data = glyf->data; tables[1].len = glyf->len;
    tables[2].tag = TAG('h','e','a','d'); tables[2].data = head;       tables[2].len = head_len;
    tables[3].tag = TAG('h','h','e','a'); tables[3].data = hhea;       tables[3].len = hhea_len;
    tables[4].tag = TAG('h','m','t','x'); tables[4].data = hmtx;       tables[4].len = hmtx_len;
    tables[5].tag = TAG('l','o','c','a'); tables[5].data = loca;       tables[5].len = loca_len;
    tables[6].tag = TAG('m','a','x','p'); tables[6].data = maxp;       tables[6].len = maxp_len;
    tables[7].tag = TAG('p','o','s','t'); tables[7].data = post;       tables[7].len = post_len;
    
    dir = result + 12;
    offset = header_size;
    
    for (i = 0; i < num_tables; i++) {
        pdfmake_write_be32(dir, tables[i].tag);
        pdfmake_write_be32(dir + 4, ttf_checksum(tables[i].data, tables[i].len));
        pdfmake_write_be32(dir + 8, offset);
        pdfmake_write_be32(dir + 12, tables[i].len);
        
        memcpy(result + offset, tables[i].data, tables[i].len);
        offset += ALIGN4(tables[i].len);
        dir += 16;
    }
    
    /* Update head checkSumAdjustment */
    file_checksum = ttf_checksum(result, total_size);
    head_offset = 0;
    for (i = 0; i < num_tables; i++) {
        if (tables[i].tag == TAG('h','e','a','d')) {
            head_offset = pdfmake_read_be32(result + 12 + i * 16 + 8);
            break;
        }
    }
    pdfmake_write_be32(result + head_offset + 8, 0xB1B0AFBA - file_checksum);
    
    /* Copy to output buffer */
    pdfmake_buf_append(out_buf, result, total_size);
    
    /* Cleanup */
    free(result);
    free(loca); free(hmtx); free(cmap); free(head);
    free(maxp); free(hhea); free(post);
    free_glyf_result(glyf);
    free_glyph_map(map);
    
    return PDFMAKE_OK;
    
    #undef ALIGN4
}
