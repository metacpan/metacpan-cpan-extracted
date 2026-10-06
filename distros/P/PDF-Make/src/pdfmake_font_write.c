/*
 * pdfmake_font_write.c - Font PDF object output
 *
 * Writes Font dictionary, FontDescriptor, FontFile2 (embedded TTF subset),
 * CIDToGIDMap and ToUnicode CMap stream to PDF.
 *
 * Reference: PDF spec §9.6, §9.7, §9.8, §9.9
 *
 * A Standard 14 font is a simple /Type1 dictionary. A TrueType font is a
 * composite font: /Type0 with Identity-H encoding over a /CIDFontType2
 * descendant, because the content stream names glyphs by id and a simple
 * /TrueType font would restrict it to a single-byte encoding.
 *
 * CIDs here are glyph ids in the ORIGINAL font, which is what
 * pdfmake_font_encode_utf8 emits and what pdfmake_tounicode_generate keys
 * on. The subsetter renumbers glyphs, so the two are bridged by a
 * /CIDToGIDMap stream rather than /Identity.
 */

#include "pdfmake_font.h"
#include "pdfmake_arena.h"
#include "pdfmake_buf.h"
#include "pdfmake_doc.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#define KEY(name) pdfmake_arena_intern_name(arena, name, (size_t)strlen(name))

static int glyph_used(const pdfmake_ttf_t *ttf, int gid) {
    if (!ttf->used_glyphs) return 0;
    return (ttf->used_glyphs[gid / 8] & (1 << (gid % 8))) ? 1 : 0;
}

/*============================================================================
 * Subset tag
 *
 * §9.6.4: an embedded subset's BaseFont is prefixed with six uppercase
 * letters and a '+'. Derived from the font name and the exact set of glyphs
 * embedded, so the same document rendered twice gets the same tag — the
 * reproducible-output promise (t/44) covers font objects too.
 *==========================================================================*/

static void subset_tag(const pdfmake_font_t *font, char out[8]) {
    const pdfmake_ttf_t *ttf = font->ttf;
    uint32_t h = 2166136261u;        /* FNV-1a */
    const char *p;
    int i;

    for (p = font->base_font; p && *p; p++) {
        h ^= (uint32_t)(unsigned char)*p;
        h *= 16777619u;
    }
    for (i = 0; i < ttf->num_glyphs; i++) {
        if (!glyph_used(ttf, i)) continue;
        h ^= (uint32_t)i;
        h *= 16777619u;
    }

    for (i = 0; i < 6; i++) {
        out[i] = (char)('A' + (h % 26));
        h /= 26;
        if (h == 0) h = 2166136261u ^ (uint32_t)i;
    }
    out[6] = '+';
    out[7] = '\0';
}

/*============================================================================
 * /W widths array
 *
 * [ cid [w w w] cid [w] ... ] — one group per run of consecutive CIDs, which
 * is the compact form for a subset whose glyph ids cluster.
 *==========================================================================*/

static pdfmake_obj_t build_widths(pdfmake_arena_t *arena,
                                  const pdfmake_ttf_t *ttf) {
    pdfmake_obj_t arr = pdfmake_array_new(arena);
    pdfmake_obj_t run;
    int i;
    int in_run = 0;

    if (arr.kind != PDFMAKE_ARRAY) return arr;

    memset(&run, 0, sizeof(run));

    for (i = 0; i < ttf->num_glyphs; i++) {
        if (glyph_used(ttf, i)) {
            if (!in_run) {
                pdfmake_array_push(arena, &arr, pdfmake_int(i));
                run = pdfmake_array_new(arena);
                if (run.kind != PDFMAKE_ARRAY) return arr;
                in_run = 1;
            }
            pdfmake_array_push(arena, &run,
                pdfmake_int(pdfmake_ttf_glyph_advance(ttf, (uint16_t)i)));
        } else if (in_run) {
            pdfmake_array_push(arena, &arr, run);
            in_run = 0;
        }
    }
    if (in_run) pdfmake_array_push(arena, &arr, run);

    return arr;
}

/*============================================================================
 * Standard 14: a simple /Type1 dictionary
 *==========================================================================*/

static pdfmake_ref_t write_simple(pdfmake_font_t *font, pdfmake_doc_t *doc,
                                  pdfmake_arena_t *arena) {
    pdfmake_ref_t null_ref = {0, 0};
    pdfmake_obj_t dict;
    uint32_t num;

    dict = pdfmake_dict_new(arena);
    if (dict.kind != PDFMAKE_DICT) return null_ref;

    pdfmake_dict_set(arena, &dict, KEY("Type"), pdfmake_name_cstr(arena, "Font"));
    pdfmake_dict_set(arena, &dict, KEY("Subtype"), pdfmake_name_cstr(arena, "Type1"));
    pdfmake_dict_set(arena, &dict, KEY("BaseFont"),
        pdfmake_name_cstr(arena, font->base_font ? font->base_font : "Helvetica"));

    /* Symbol and ZapfDingbats carry their own built-in encoding; naming
     * WinAnsi over the top of one remaps every glyph. */
    if (font->std14_id != PDFMAKE_STD14_SYMBOL &&
        font->std14_id != PDFMAKE_STD14_ZAPFDINGBATS) {
        pdfmake_dict_set(arena, &dict, KEY("Encoding"),
            pdfmake_name_cstr(arena, "WinAnsiEncoding"));
    }

    num = pdfmake_doc_add(doc, dict);
    if (num == 0) return null_ref;

    font->font_ref.num = num;
    font->font_ref.gen = 0;
    return font->font_ref;
}

/*============================================================================
 * TrueType: /Type0 over /CIDFontType2
 *==========================================================================*/

static pdfmake_ref_t write_truetype(pdfmake_font_t *font, pdfmake_doc_t *doc,
                                    pdfmake_arena_t *arena) {
    pdfmake_ref_t null_ref = {0, 0};
    pdfmake_ttf_t *ttf = font->ttf;
    pdfmake_buf_t subset;
    pdfmake_buf_t c2g;
    pdfmake_buf_t tounicode;
    pdfmake_obj_t stream;
    pdfmake_obj_t descr;
    pdfmake_obj_t cidfont;
    pdfmake_obj_t type0;
    pdfmake_obj_t bbox;
    pdfmake_obj_t sysinfo;
    pdfmake_obj_t descendants;
    uint32_t fontfile_num = 0;
    uint32_t c2g_num = 0;
    uint32_t descr_num = 0;
    uint32_t cidfont_num = 0;
    uint32_t tounicode_num = 0;
    uint32_t num;
    char tag[8];
    char tagged[128];
    const char *base;

    /* .notdef is always embedded; a font nothing drew with still has to be a
     * valid font rather than an empty one. */
    pdfmake_ttf_mark_glyph(ttf, 0);

    pdfmake_buf_init(&subset);
    if (pdfmake_ttf_subset(ttf, &subset) != PDFMAKE_OK || subset.len == 0) {
        pdfmake_buf_free(&subset);
        return null_ref;
    }

    subset_tag(font, tag);
    base = font->base_font ? font->base_font : "PDFMakeTTF";
    if (strlen(base) > sizeof(tagged) - 8) {
        /* A name longer than the buffer is not worth truncating into an
         * ambiguous one; drop the tag and use the name as given. */
        snprintf(tagged, sizeof(tagged), "%s", base);
    } else {
        snprintf(tagged, sizeof(tagged), "%s%s", tag, base);
    }

    /* ── /FontFile2: the embedded subset ────────────────── */
    stream = pdfmake_stream_new(arena);
    if (stream.kind != PDFMAKE_STREAM) { pdfmake_buf_free(&subset); return null_ref; }
    if (!pdfmake_stream_set_data(arena, &stream, subset.data, subset.len)) {
        pdfmake_buf_free(&subset);
        return null_ref;
    }
    {
        pdfmake_dict_t *sd = pdfmake_stream_dict(&stream);
        pdfmake_obj_t sdo;
        sdo.kind = PDFMAKE_DICT;
        sdo.as.dict = sd;
        /* /Length1 is the size of the decoded font program. */
        pdfmake_dict_set(arena, &sdo, KEY("Length1"), pdfmake_int((int64_t)subset.len));
    }
    pdfmake_stream_set_flate(arena, &stream);
    fontfile_num = pdfmake_doc_add(doc, stream);
    pdfmake_buf_free(&subset);
    if (fontfile_num == 0) return null_ref;

    /* ── /CIDToGIDMap ───────────────────────────────────── */
    pdfmake_buf_init(&c2g);
    if (pdfmake_ttf_subset_cidtogid(ttf, &c2g) != PDFMAKE_OK || c2g.len == 0) {
        pdfmake_buf_free(&c2g);
        return null_ref;
    }
    stream = pdfmake_stream_new(arena);
    if (stream.kind != PDFMAKE_STREAM) { pdfmake_buf_free(&c2g); return null_ref; }
    if (!pdfmake_stream_set_data(arena, &stream, c2g.data, c2g.len)) {
        pdfmake_buf_free(&c2g);
        return null_ref;
    }
    pdfmake_stream_set_flate(arena, &stream);
    c2g_num = pdfmake_doc_add(doc, stream);
    pdfmake_buf_free(&c2g);
    if (c2g_num == 0) return null_ref;

    /* ── /FontDescriptor ────────────────────────────────── */
    descr = pdfmake_dict_new(arena);
    if (descr.kind != PDFMAKE_DICT) return null_ref;

    bbox = pdfmake_array_new(arena);
    pdfmake_array_push(arena, &bbox, pdfmake_int(font->metrics.bbox[0]));
    pdfmake_array_push(arena, &bbox, pdfmake_int(font->metrics.bbox[1]));
    pdfmake_array_push(arena, &bbox, pdfmake_int(font->metrics.bbox[2]));
    pdfmake_array_push(arena, &bbox, pdfmake_int(font->metrics.bbox[3]));

    pdfmake_dict_set(arena, &descr, KEY("Type"),
        pdfmake_name_cstr(arena, "FontDescriptor"));
    pdfmake_dict_set(arena, &descr, KEY("FontName"),
        pdfmake_name_cstr(arena, tagged));
    pdfmake_dict_set(arena, &descr, KEY("Flags"),
        pdfmake_int((int64_t)font->metrics.flags));
    pdfmake_dict_set(arena, &descr, KEY("FontBBox"), bbox);
    pdfmake_dict_set(arena, &descr, KEY("ItalicAngle"),
        pdfmake_int(font->metrics.italic_angle));
    pdfmake_dict_set(arena, &descr, KEY("Ascent"),
        pdfmake_int(font->metrics.ascent));
    pdfmake_dict_set(arena, &descr, KEY("Descent"),
        pdfmake_int(font->metrics.descent));
    pdfmake_dict_set(arena, &descr, KEY("CapHeight"),
        pdfmake_int(font->metrics.cap_height));
    pdfmake_dict_set(arena, &descr, KEY("StemV"),
        pdfmake_int(font->metrics.stem_v));
    pdfmake_dict_set(arena, &descr, KEY("FontFile2"),
        pdfmake_ref(fontfile_num, 0));

    descr_num = pdfmake_doc_add(doc, descr);
    if (descr_num == 0) return null_ref;

    /* ── /CIDFontType2 descendant ───────────────────────── */
    cidfont = pdfmake_dict_new(arena);
    if (cidfont.kind != PDFMAKE_DICT) return null_ref;

    sysinfo = pdfmake_dict_new(arena);
    pdfmake_dict_set(arena, &sysinfo, KEY("Registry"),
        pdfmake_str_cstr(arena, "Adobe"));
    pdfmake_dict_set(arena, &sysinfo, KEY("Ordering"),
        pdfmake_str_cstr(arena, "Identity"));
    pdfmake_dict_set(arena, &sysinfo, KEY("Supplement"), pdfmake_int(0));

    pdfmake_dict_set(arena, &cidfont, KEY("Type"),
        pdfmake_name_cstr(arena, "Font"));
    pdfmake_dict_set(arena, &cidfont, KEY("Subtype"),
        pdfmake_name_cstr(arena, "CIDFontType2"));
    pdfmake_dict_set(arena, &cidfont, KEY("BaseFont"),
        pdfmake_name_cstr(arena, tagged));
    pdfmake_dict_set(arena, &cidfont, KEY("CIDSystemInfo"), sysinfo);
    pdfmake_dict_set(arena, &cidfont, KEY("FontDescriptor"),
        pdfmake_ref(descr_num, 0));
    pdfmake_dict_set(arena, &cidfont, KEY("DW"), pdfmake_int(1000));
    pdfmake_dict_set(arena, &cidfont, KEY("W"), build_widths(arena, ttf));
    pdfmake_dict_set(arena, &cidfont, KEY("CIDToGIDMap"),
        pdfmake_ref(c2g_num, 0));

    cidfont_num = pdfmake_doc_add(doc, cidfont);
    if (cidfont_num == 0) return null_ref;

    /* ── /ToUnicode ─────────────────────────────────────── */
    pdfmake_buf_init(&tounicode);
    if (pdfmake_tounicode_generate(font, &tounicode) == PDFMAKE_OK &&
        tounicode.len > 0) {
        stream = pdfmake_stream_new(arena);
        if (stream.kind == PDFMAKE_STREAM &&
            pdfmake_stream_set_data(arena, &stream,
                                    tounicode.data, tounicode.len)) {
            pdfmake_stream_set_flate(arena, &stream);
            tounicode_num = pdfmake_doc_add(doc, stream);
        }
    }
    pdfmake_buf_free(&tounicode);

    /* ── /Type0 ─────────────────────────────────────────── */
    type0 = pdfmake_dict_new(arena);
    if (type0.kind != PDFMAKE_DICT) return null_ref;

    descendants = pdfmake_array_new(arena);
    pdfmake_array_push(arena, &descendants, pdfmake_ref(cidfont_num, 0));

    pdfmake_dict_set(arena, &type0, KEY("Type"),
        pdfmake_name_cstr(arena, "Font"));
    pdfmake_dict_set(arena, &type0, KEY("Subtype"),
        pdfmake_name_cstr(arena, "Type0"));
    pdfmake_dict_set(arena, &type0, KEY("BaseFont"),
        pdfmake_name_cstr(arena, tagged));
    pdfmake_dict_set(arena, &type0, KEY("Encoding"),
        pdfmake_name_cstr(arena, "Identity-H"));
    pdfmake_dict_set(arena, &type0, KEY("DescendantFonts"), descendants);
    if (tounicode_num) {
        pdfmake_dict_set(arena, &type0, KEY("ToUnicode"),
            pdfmake_ref(tounicode_num, 0));
    }

    num = pdfmake_doc_add(doc, type0);
    if (num == 0) return null_ref;

    font->fontfile_ref.num   = fontfile_num;
    font->descriptor_ref.num = descr_num;
    font->tounicode_ref.num  = tounicode_num;
    font->font_ref.num       = num;
    font->font_ref.gen       = 0;
    return font->font_ref;
}

/*============================================================================
 * Main font writer entry point
 *==========================================================================*/

pdfmake_ref_t pdfmake_font_write(pdfmake_font_t *font, pdfmake_doc_t *doc) {
    pdfmake_ref_t null_ref = {0, 0};
    pdfmake_arena_t *arena;

    if (!font || !doc) return null_ref;

    /* Written once per document: the caller may well ask again from each
     * page that uses the font. */
    if (font->font_ref.num != 0) return font->font_ref;

    arena = pdfmake_doc_arena(doc);
    if (!arena) return null_ref;

    if (font->type == PDFMAKE_FONT_TYPE1)
        return write_simple(font, doc, arena);
    if (font->type == PDFMAKE_FONT_TRUETYPE && font->ttf)
        return write_truetype(font, doc, arena);

    return null_ref;
}

/*============================================================================
 * UTF-8 encoding
 *==========================================================================*/

pdfmake_err_t pdfmake_font_encode_utf8(pdfmake_font_t *font,
                                        const char *utf8, size_t len,
                                        pdfmake_buf_t *out_bytes) {
    const uint8_t *p;
    const uint8_t *end;

    if (!font || !utf8 || !out_bytes) return PDFMAKE_EINVAL;

    p = (const uint8_t *)utf8;
    end = p + len;

    while (p < end) {
        uint32_t cp;

        /* Decode UTF-8 */
        if ((*p & 0x80) == 0) {
            cp = *p++;
        } else if ((*p & 0xE0) == 0xC0) {
            if (p + 1 >= end) break;
            cp = (*p++ & 0x1F) << 6;
            cp |= (*p++ & 0x3F);
        } else if ((*p & 0xF0) == 0xE0) {
            if (p + 2 >= end) break;
            cp = (*p++ & 0x0F) << 12;
            cp |= (*p++ & 0x3F) << 6;
            cp |= (*p++ & 0x3F);
        } else if ((*p & 0xF8) == 0xF0) {
            if (p + 3 >= end) break;
            cp = (*p++ & 0x07) << 18;
            cp |= (*p++ & 0x3F) << 12;
            cp |= (*p++ & 0x3F) << 6;
            cp |= (*p++ & 0x3F);
        } else {
            p++;
            continue;
        }

        /* Encode based on font type */
        if (font->type == PDFMAKE_FONT_TYPE1) {
            /* WinAnsi encoding */
            uint8_t byte;
            if (cp >= 32 && cp <= 255) {
                byte = (uint8_t)cp;
            } else if (cp == 0x2018) {
                byte = 0x91;
            } else if (cp == 0x2019) {
                byte = 0x92;
            } else if (cp == 0x201C) {
                byte = 0x93;
            } else if (cp == 0x201D) {
                byte = 0x94;
            } else {
                byte = '?';
            }
            pdfmake_buf_append(out_bytes, &byte, 1);
        } else if (font->type == PDFMAKE_FONT_TRUETYPE && font->ttf) {
            /* CID encoding - 2-byte glyph IDs */
            uint16_t gid = pdfmake_ttf_cmap_lookup(font->ttf, cp);
            uint8_t bytes[2];
            pdfmake_ttf_mark_glyph(font->ttf, gid);
            bytes[0] = (gid >> 8) & 0xFF;
            bytes[1] = gid & 0xFF;
            pdfmake_buf_append(out_bytes, bytes, 2);
        }
    }

    return PDFMAKE_OK;
}
