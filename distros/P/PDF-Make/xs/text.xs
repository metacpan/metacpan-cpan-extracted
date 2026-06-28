/*
 * text.xs - XS bindings for PDF::Make text rendering
 *
 * Provides Perl interface to the text rendering functions.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "pdfmake_text.h"
#include "pdfmake_font.h"
#include "pdfmake_render.h"
#include "pdfmake_arena.h"

typedef pdfmake_text_state_t* PDF__Make__TextState;
typedef pdfmake_glyph_cache_t* PDF__Make__GlyphCache;
typedef pdfmake_font_t* PDF__Make__Font;
typedef pdfmake_render_ctx_t* PDF__Make__Render;
typedef pdfmake_arena_t* PDF__Make__Arena;

MODULE = PDF::Make::Text    PACKAGE = PDF::Make::TextState    PREFIX = pdfmake_text_

PROTOTYPES: DISABLE

#
# TextState Constructor / Destructor
#

PDF::Make::TextState
pdfmake_text_new(class)
    char *class
CODE:
    PERL_UNUSED_VAR(class);
    pdfmake_text_state_t *ts;
    Newxz(ts, 1, pdfmake_text_state_t);
    pdfmake_text_state_init(ts);
    RETVAL = ts;
OUTPUT:
    RETVAL

void
pdfmake_text_DESTROY(ts)
    PDF::Make::TextState ts
CODE:
    Safefree(ts);

#
# Text State Configuration
#

void
pdfmake_text_reset(ts)
    PDF::Make::TextState ts
CODE:
    pdfmake_text_state_reset(ts);

int
pdfmake_text_set_font(ts, font, size, arena)
    PDF::Make::TextState ts
    PDF::Make::Font font
    double size
    PDF::Make::Arena arena
CODE:
    RETVAL = pdfmake_text_set_font(ts, font, size, arena);
OUTPUT:
    RETVAL

void
pdfmake_text_set_matrix(ts, a, b, c, d, e, f)
    PDF::Make::TextState ts
    double a
    double b
    double c
    double d
    double e
    double f
CODE:
    pdfmake_text_set_matrix(ts, a, b, c, d, e, f);

void
pdfmake_text_next_line(ts)
    PDF::Make::TextState ts
CODE:
    pdfmake_text_next_line(ts);

void
pdfmake_text_move(ts, tx, ty)
    PDF::Make::TextState ts
    double tx
    double ty
CODE:
    pdfmake_text_move(ts, tx, ty);

#
# Text State Getters/Setters
#

double
pdfmake_text_get_font_size(ts)
    PDF::Make::TextState ts
CODE:
    RETVAL = ts->font_size;
OUTPUT:
    RETVAL

void
pdfmake_text_set_char_spacing(ts, spacing)
    PDF::Make::TextState ts
    double spacing
CODE:
    ts->char_spacing = spacing;

double
pdfmake_text_get_char_spacing(ts)
    PDF::Make::TextState ts
CODE:
    RETVAL = ts->char_spacing;
OUTPUT:
    RETVAL

void
pdfmake_text_set_word_spacing(ts, spacing)
    PDF::Make::TextState ts
    double spacing
CODE:
    ts->word_spacing = spacing;

double
pdfmake_text_get_word_spacing(ts)
    PDF::Make::TextState ts
CODE:
    RETVAL = ts->word_spacing;
OUTPUT:
    RETVAL

void
pdfmake_text_set_horiz_scale(ts, scale)
    PDF::Make::TextState ts
    double scale
CODE:
    ts->horiz_scale = scale;

double
pdfmake_text_get_horiz_scale(ts)
    PDF::Make::TextState ts
CODE:
    RETVAL = ts->horiz_scale;
OUTPUT:
    RETVAL

void
pdfmake_text_set_leading(ts, leading)
    PDF::Make::TextState ts
    double leading
CODE:
    ts->leading = leading;

double
pdfmake_text_get_leading(ts)
    PDF::Make::TextState ts
CODE:
    RETVAL = ts->leading;
OUTPUT:
    RETVAL

void
pdfmake_text_set_rise(ts, rise)
    PDF::Make::TextState ts
    double rise
CODE:
    ts->text_rise = rise;

double
pdfmake_text_get_rise(ts)
    PDF::Make::TextState ts
CODE:
    RETVAL = ts->text_rise;
OUTPUT:
    RETVAL

void
pdfmake_text_set_render_mode(ts, mode)
    PDF::Make::TextState ts
    int mode
CODE:
    ts->render_mode = (pdfmake_text_render_mode_t)mode;

int
pdfmake_text_get_render_mode(ts)
    PDF::Make::TextState ts
CODE:
    RETVAL = (int)ts->render_mode;
OUTPUT:
    RETVAL

#
# Text Matrix Access
#

void
pdfmake_text_get_matrix(ts)
    PDF::Make::TextState ts
PPCODE:
    EXTEND(SP, 6);
    mPUSHn(ts->tm[0]);
    mPUSHn(ts->tm[1]);
    mPUSHn(ts->tm[2]);
    mPUSHn(ts->tm[3]);
    mPUSHn(ts->tm[4]);
    mPUSHn(ts->tm[5]);

void
pdfmake_text_get_position(ts)
    PDF::Make::TextState ts
PPCODE:
    EXTEND(SP, 2);
    mPUSHn(ts->tm[4]);
    mPUSHn(ts->tm[5]);

MODULE = PDF::Make::Text    PACKAGE = PDF::Make::Text    PREFIX = pdfmake_

#
# Text Rendering Functions
#

int
pdfmake_render_text(ctx, ts, text)
    PDF::Make::Render ctx
    PDF::Make::TextState ts
    SV *text
CODE:
    STRLEN len;
    const char *str = SvPVbyte(text, len);
    RETVAL = pdfmake_render_text(ctx, ts, (const uint8_t *)str, len);
OUTPUT:
    RETVAL

int
pdfmake_render_text_utf8(ctx, ts, text)
    PDF::Make::Render ctx
    PDF::Make::TextState ts
    SV *text
CODE:
    STRLEN len;
    const char *str = SvPVutf8(text, len);
    RETVAL = pdfmake_render_text_utf8(ctx, ts, str, len);
OUTPUT:
    RETVAL

int
pdfmake_render_text_at(ctx, ts, x, y, text)
    PDF::Make::Render ctx
    PDF::Make::TextState ts
    double x
    double y
    SV *text
CODE:
    STRLEN len;
    const char *str = SvPVutf8(text, len);
    RETVAL = pdfmake_render_text_at(ctx, ts, x, y, str, len);
OUTPUT:
    RETVAL

int
pdfmake_render_glyph(ctx, ts, glyph_id)
    PDF::Make::Render ctx
    PDF::Make::TextState ts
    int glyph_id
CODE:
    RETVAL = pdfmake_render_glyph(ctx, ts, (uint16_t)glyph_id);
OUTPUT:
    RETVAL

#
# Text Measurement
#

double
pdfmake_text_string_width(ts, text)
    PDF::Make::TextState ts
    SV *text
CODE:
    STRLEN len;
    const char *str = SvPVutf8(text, len);
    RETVAL = pdfmake_text_string_width(ts, (const uint8_t *)str, len);
OUTPUT:
    RETVAL

double
pdfmake_text_glyph_advance(font, glyph_id, font_size)
    PDF::Make::Font font
    int glyph_id
    double font_size
CODE:
    RETVAL = pdfmake_text_glyph_advance(font, (uint16_t)glyph_id, font_size);
OUTPUT:
    RETVAL

void
pdfmake_text_bbox(ts, text)
    PDF::Make::TextState ts
    SV *text
PPCODE:
    STRLEN len;
    const char *str = SvPVutf8(text, len);
    double width, height, descent;
    pdfmake_text_bbox(ts, str, len, &width, &height, &descent);
    EXTEND(SP, 3);
    mPUSHn(width);
    mPUSHn(height);
    mPUSHn(descent);

#
# Character Mapping
#

int
pdfmake_text_char_to_glyph(font, charcode)
    PDF::Make::Font font
    int charcode
CODE:
    RETVAL = pdfmake_text_char_to_glyph(font, (uint32_t)charcode);
OUTPUT:
    RETVAL

int
pdfmake_text_unicode_to_glyph(font, unicode)
    PDF::Make::Font font
    int unicode
CODE:
    RETVAL = pdfmake_text_unicode_to_glyph(font, (uint32_t)unicode);
OUTPUT:
    RETVAL

MODULE = PDF::Make::Text    PACKAGE = PDF::Make::GlyphCache    PREFIX = pdfmake_glyph_

#
# Glyph Cache
#

PDF::Make::GlyphCache
pdfmake_glyph_cache_new(class, font, arena)
    char *class
    PDF::Make::Font font
    PDF::Make::Arena arena
CODE:
    PERL_UNUSED_VAR(class);
    RETVAL = pdfmake_glyph_cache_create(font, arena);
    if (!RETVAL) {
        croak("Failed to create glyph cache");
    }
OUTPUT:
    RETVAL

void
pdfmake_glyph_cache_DESTROY(cache)
    PDF::Make::GlyphCache cache
CODE:
    pdfmake_glyph_cache_free(cache);

int
pdfmake_glyph_load(cache, font, glyph_id)
    PDF::Make::GlyphCache cache
    PDF::Make::Font font
    int glyph_id
CODE:
    RETVAL = pdfmake_glyph_load(cache, font, (uint16_t)glyph_id);
OUTPUT:
    RETVAL

int
pdfmake_glyph_cache_count(cache)
    PDF::Make::GlyphCache cache
CODE:
    RETVAL = (int)cache->glyph_count;
OUTPUT:
    RETVAL

int
pdfmake_glyph_cache_loaded(cache)
    PDF::Make::GlyphCache cache
CODE:
    RETVAL = (int)cache->loaded_count;
OUTPUT:
    RETVAL

#
# Glyph Info Access
#

void
pdfmake_glyph_get_info(cache, font, glyph_id)
    PDF::Make::GlyphCache cache
    PDF::Make::Font font
    int glyph_id
PPCODE:
    pdfmake_glyph_outline_t *outline = pdfmake_glyph_get(cache, font, 
                                                         (uint16_t)glyph_id);
    if (!outline) {
        XSRETURN_EMPTY;
    }
    
    HV *info = newHV();
    hv_store(info, "glyph_id", 8, newSViv(outline->glyph_id), 0);
    hv_store(info, "advance_width", 13, newSViv(outline->advance_width), 0);
    hv_store(info, "lsb", 3, newSViv(outline->lsb), 0);
    hv_store(info, "x_min", 5, newSViv(outline->x_min), 0);
    hv_store(info, "y_min", 5, newSViv(outline->y_min), 0);
    hv_store(info, "x_max", 5, newSViv(outline->x_max), 0);
    hv_store(info, "y_max", 5, newSViv(outline->y_max), 0);
    hv_store(info, "loaded", 6, newSViv(outline->loaded), 0);
    hv_store(info, "composite", 9, newSViv(outline->composite), 0);
    hv_store(info, "has_path", 8, newSViv(outline->path ? 1 : 0), 0);
    
    mPUSHs(newRV_noinc((SV *)info));

MODULE = PDF::Make::Text    PACKAGE = PDF::Make::Encoding    PREFIX = pdfmake_encoding_

#
# Encoding Access
#

void
pdfmake_encoding_get_table(name)
    const char *name
PPCODE:
    const uint16_t *table = pdfmake_encoding_get(name);
    if (!table) {
        XSRETURN_EMPTY;
    }
    
    AV *av = newAV();
    av_extend(av, 255);
    for (int i = 0; i < 256; i++) {
        av_push(av, newSVuv(table[i]));
    }
    
    mPUSHs(newRV_noinc((SV *)av));

void
pdfmake_encoding_names()
PPCODE:
    EXTEND(SP, 5);
    mPUSHp("StandardEncoding", 16);
    mPUSHp("WinAnsiEncoding", 15);
    mPUSHp("MacRomanEncoding", 16);
    mPUSHp("SymbolEncoding", 14);
    mPUSHp("ZapfDingbatsEncoding", 20);

MODULE = PDF::Make::Text    PACKAGE = PDF::Make::TextRenderMode

#
# Render Mode Constants
#

int
FILL()
CODE:
    RETVAL = PDFMAKE_TEXT_FILL;
OUTPUT:
    RETVAL

int
STROKE()
CODE:
    RETVAL = PDFMAKE_TEXT_STROKE;
OUTPUT:
    RETVAL

int
FILL_STROKE()
CODE:
    RETVAL = PDFMAKE_TEXT_FILL_STROKE;
OUTPUT:
    RETVAL

int
INVISIBLE()
CODE:
    RETVAL = PDFMAKE_TEXT_INVISIBLE;
OUTPUT:
    RETVAL

int
FILL_CLIP()
CODE:
    RETVAL = PDFMAKE_TEXT_FILL_CLIP;
OUTPUT:
    RETVAL

int
STROKE_CLIP()
CODE:
    RETVAL = PDFMAKE_TEXT_STROKE_CLIP;
OUTPUT:
    RETVAL

int
FILL_STROKE_CLIP()
CODE:
    RETVAL = PDFMAKE_TEXT_FILL_STROKE_CLIP;
OUTPUT:
    RETVAL

int
CLIP()
CODE:
    RETVAL = PDFMAKE_TEXT_CLIP;
OUTPUT:
    RETVAL

BOOT:
{
    HV *stash = gv_stashpv("PDF::Make::TextRender", GV_ADD);
    PDFMAKE_REGISTER_CONST(stash, "FILL",             PDFMAKE_TEXT_FILL);
    PDFMAKE_REGISTER_CONST(stash, "STROKE",           PDFMAKE_TEXT_STROKE);
    PDFMAKE_REGISTER_CONST(stash, "FILL_STROKE",      PDFMAKE_TEXT_FILL_STROKE);
    PDFMAKE_REGISTER_CONST(stash, "INVISIBLE",        PDFMAKE_TEXT_INVISIBLE);
    PDFMAKE_REGISTER_CONST(stash, "FILL_CLIP",        PDFMAKE_TEXT_FILL_CLIP);
    PDFMAKE_REGISTER_CONST(stash, "STROKE_CLIP",      PDFMAKE_TEXT_STROKE_CLIP);
    PDFMAKE_REGISTER_CONST(stash, "FILL_STROKE_CLIP", PDFMAKE_TEXT_FILL_STROKE_CLIP);
    PDFMAKE_REGISTER_CONST(stash, "CLIP",             PDFMAKE_TEXT_CLIP);
}
