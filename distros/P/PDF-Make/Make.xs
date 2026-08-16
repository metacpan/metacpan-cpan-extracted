#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "pdfmake.h"
#include "pdfmake_buf.h"
#include "pdfmake_writer.h"
#include "pdfmake_doc.h"
#include "pdfmake_meta.h"
#include "pdfmake_page.h"
#include "pdfmake_content.h"
#include "pdfmake_parser.h"
#include "pdfmake_arena.h"
#include "pdfmake_reader.h"
#include "pdfmake_image.h"
#include "pdfmake_font.h"
#include "pdfmake_interpreter.h"
#include "pdfmake_textract.h"
#include "pdfmake_edit.h"
#include "pdfmake_import.h"
#include "pdfmake_ocg.h"
#include "pdfmake_attach.h"
#include "pdfmake_tag.h"
#include "pdfmake_redact.h"
#include "pdfmake_color_mgmt.h"
#include "pdfmake_annot.h"
#include "pdfmake_outline.h"
#include "pdfmake_action.h"
#include "pdfmake_crypt.h"
#include "pdfmake_form.h"
#include "pdfmake_watermark.h"
#include "pdfmake_signature.h"
#include "pdfmake_x509.h"
#include "pdfmake_pkcs12.h"
#include "pdfmake_linear.h"
#include "pdfmake_image_render.h"
#include "pdfmake_custom_ops.h"
#include "pdfmake_filter.h"
#include "pdfmake_markup.h"
#include "pdfmake_markup_style.h"
#include "pdfmake_markup_profile.h"

/* -------------------------------------------------------------------------
 * Render API forward declarations
 * ------------------------------------------------------------------------- */
struct pdfmake_render_ctx {
    uint32_t *pixels;
    int width;
    int height;
    int stride;
};
#ifndef PDFMAKE_RENDER_CTX_T_DEFINED
#define PDFMAKE_RENDER_CTX_T_DEFINED
typedef struct pdfmake_render_ctx pdfmake_render_ctx_t;
#endif

typedef pdfmake_render_ctx_t* PDF__Make__Render;

typedef enum {
    PDFMAKE_RENDER_OK = 0,
    PDFMAKE_RENDER_ERR_NULL,
    PDFMAKE_RENDER_ERR_MEMORY,
    PDFMAKE_RENDER_ERR_INVALID,
    PDFMAKE_RENDER_ERR_OVERFLOW,
    PDFMAKE_RENDER_ERR_EMPTY_PATH,
} pdfmake_render_err_t;

typedef int pdfmake_line_cap_t;
typedef int pdfmake_line_join_t;
typedef int pdfmake_fill_rule_t;

typedef struct {
    double a, b, c, d, e, f;
} pdfmake_matrix_t;

pdfmake_render_ctx_t *pdfmake_render_create(int width, int height);
void pdfmake_render_destroy(pdfmake_render_ctx_t *ctx);
void pdfmake_render_clear(pdfmake_render_ctx_t *ctx, pdfmake_color_t color);
pdfmake_render_err_t pdfmake_render_save(pdfmake_render_ctx_t *ctx);
pdfmake_render_err_t pdfmake_render_restore(pdfmake_render_ctx_t *ctx);
void pdfmake_render_set_fill_color(pdfmake_render_ctx_t *ctx, double r, double g, double b, double a);
void pdfmake_render_set_stroke_color(pdfmake_render_ctx_t *ctx, double r, double g, double b, double a);
void pdfmake_render_set_line_width(pdfmake_render_ctx_t *ctx, double width);
void pdfmake_render_set_line_cap(pdfmake_render_ctx_t *ctx, pdfmake_line_cap_t cap);
void pdfmake_render_set_line_join(pdfmake_render_ctx_t *ctx, pdfmake_line_join_t join);
void pdfmake_render_set_miter_limit(pdfmake_render_ctx_t *ctx, double limit);
pdfmake_render_err_t pdfmake_render_set_dash(pdfmake_render_ctx_t *ctx, double *array, size_t count, double phase);
void pdfmake_render_set_fill_rule(pdfmake_render_ctx_t *ctx, pdfmake_fill_rule_t rule);
void pdfmake_render_translate(pdfmake_render_ctx_t *ctx, double tx, double ty);
void pdfmake_render_scale(pdfmake_render_ctx_t *ctx, double sx, double sy);
void pdfmake_render_rotate(pdfmake_render_ctx_t *ctx, double angle);
void pdfmake_render_set_matrix(pdfmake_render_ctx_t *ctx, pdfmake_matrix_t *m);
pdfmake_render_err_t pdfmake_render_move_to(pdfmake_render_ctx_t *ctx, double x, double y);
pdfmake_render_err_t pdfmake_render_line_to(pdfmake_render_ctx_t *ctx, double x, double y);
pdfmake_render_err_t pdfmake_render_curve_to(pdfmake_render_ctx_t *ctx, double x1, double y1, double x2, double y2, double x3, double y3);
pdfmake_render_err_t pdfmake_render_close_path(pdfmake_render_ctx_t *ctx);
pdfmake_render_err_t pdfmake_render_rect(pdfmake_render_ctx_t *ctx, double x, double y, double w, double h);
void pdfmake_render_new_path(pdfmake_render_ctx_t *ctx);
pdfmake_render_err_t pdfmake_render_fill(pdfmake_render_ctx_t *ctx);
pdfmake_render_err_t pdfmake_render_fill_preserve(pdfmake_render_ctx_t *ctx);
pdfmake_render_err_t pdfmake_render_stroke(pdfmake_render_ctx_t *ctx);
pdfmake_render_err_t pdfmake_render_clip(pdfmake_render_ctx_t *ctx);
void pdfmake_render_reset_clip(pdfmake_render_ctx_t *ctx);
uint32_t pdfmake_render_get_pixel(pdfmake_render_ctx_t *ctx, int x, int y);

#ifndef PDFMAKE_FILL_NONZERO
#define PDFMAKE_FILL_NONZERO 0
#endif
#ifndef PDFMAKE_FILL_EVENODD
#define PDFMAKE_FILL_EVENODD 1
#endif

/* -------------------------------------------------------------------------
 * Render-page API forward declarations
 * ------------------------------------------------------------------------- */
typedef enum {
    PDFMAKE_SCALE_NEAREST  = 0,
    PDFMAKE_SCALE_BILINEAR = 1,
    PDFMAKE_SCALE_BICUBIC  = 2,
} pdfmake_scale_mode_t;

typedef struct pdfmake_render_opts {
    double dpi;
    double scale;
    pdfmake_scale_mode_t scale_mode;
    int antialias;
    double flatness;
    pdfmake_rotation_t rotation;
    uint32_t background;
    double clip_x, clip_y;
    double clip_width, clip_height;
    int use_clip;
    int render_text;
    int render_images;
    int render_vectors;
    int render_annotations;
    int show_text_bounds;
    int show_image_bounds;
    int show_clip_regions;
} pdfmake_render_opts_t;

typedef struct pdfmake_page_render {
    uint32_t *pixels;
    int width;
    int height;
    int stride;
    double page_width;
    double page_height;
    double effective_dpi;
    int text_objects;
    int path_objects;
    int image_objects;
    double render_time_ms;
    int error_count;
    char error_msg[256];
} pdfmake_page_render_t;

void pdfmake_render_opts_init(pdfmake_render_opts_t *opts);
pdfmake_err_t pdfmake_render_page_to_pixels(pdfmake_reader_t *reader, int page_num, const pdfmake_render_opts_t *opts, pdfmake_page_render_t *result);
pdfmake_err_t pdfmake_render_page_region(pdfmake_reader_t *reader, int page_num, double region_x, double region_y, double region_w, double region_h, const pdfmake_render_opts_t *opts, pdfmake_page_render_t *result);
void pdfmake_page_render_free(pdfmake_page_render_t *result);
void pdfmake_page_get_render_size(pdfmake_reader_t *reader, int page_num, double dpi, int *width, int *height);

/* Missing prototype in header, implemented in src/pdfmake_image_scale.c */
pdfmake_imgr_err_t pdfmake_decoded_image_resize(
    pdfmake_decoded_image_t *img,
    int new_w, int new_h,
    pdfmake_interp_mode_t mode,
    pdfmake_arena_t *arena);

/* Portable strndup: POSIX 2008 / GNU only, not in C99/C11 and missing from
 * Windows UCRT.  Uses Newx so callers must Safefree the returned buffer.
 * pTHX_ is required: XSUB.h redefines malloc→PerlMem_malloc on Windows
 * PERL_IMPLICIT_SYS builds, which needs the thread context. */
static char *pdfmake_xs_strndup(pTHX_ const char *s, size_t n)
{
    char *p;
    size_t i;

    if (!s) return NULL;
    for (i = 0; i < n && s[i]; i++) ;
    Newx(p, i + 1, char);
    memcpy(p, s, i);
    p[i] = '\0';
    return p;
}

/* Shared helper for markup.xs: the C node tree as a plain Perl structure.
 *
 * Elements become { kind => 'elem', tag, attrs, children, line, col } and text
 * becomes { kind => 'text', text, line, col }. The conversion happens while
 * the arena is still alive and the caller frees it immediately afterwards, so
 * nothing Perl-side ever points into C memory.
 *
 * Recursion is bounded by the parser's own depth limit, so the C stack here
 * is bounded too. */
static SV *pdfmake_markup_node_to_sv(pTHX_ const pdfmake_markup_node_t *n)
{
    HV *h;
    const pdfmake_markup_node_t *c;

    if (!n) return newSV(0);

    h = newHV();
    (void)hv_stores(h, "line", newSVuv(n->line));
    (void)hv_stores(h, "col",  newSVuv(n->col));

    if (n->kind == PDFMAKE_MARKUP_TEXT) {
        SV *t = newSVpvn(n->text ? n->text : "", n->text_len);
        SvUTF8_on(t);
        (void)hv_stores(h, "kind", newSVpvs("text"));
        (void)hv_stores(h, "text", t);
        return newRV_noinc((SV *)h);
    }

    {
        const char *name = pdfmake_markup_tag_name(n->tag);
        HV *attrs = newHV();
        AV *kids  = newAV();
        const pdfmake_markup_attr_t *a;

        (void)hv_stores(h, "kind", newSVpvs("elem"));
        (void)hv_stores(h, "tag",  newSVpv(name ? name : "", 0));

        for (a = n->attrs; a; a = a->next) {
            SV *v = newSVpvn(a->value, a->value_len);
            SvUTF8_on(v);
            (void)hv_store(attrs, a->name, (I32)a->name_len, v, 0);
        }
        (void)hv_stores(h, "attrs", newRV_noinc((SV *)attrs));

        for (c = n->first_child; c; c = c->next_sibling)
            av_push(kids, pdfmake_markup_node_to_sv(aTHX_ c));
        (void)hv_stores(h, "children", newRV_noinc((SV *)kids));
    }

    return newRV_noinc((SV *)h);
}

/* Defined below, with the rest of the markup SV plumbing. */
static const char *pdfmake_markup_sv_bytes(pTHX_ SV *sv, STRLEN *len);

/* Parse markup and hand back the result hash: { ok => 1, root => ... } or
 * { ok => 0, error, line, col }. The arena is freed before returning, so
 * nothing Perl-side ever points into C memory. */
static SV *pdfmake_markup_parse_sv(pTHX_ SV *src)
{
    STRLEN len;
    const char *bytes;
    pdfmake_markup_doc_t *doc;
    HV *out;

    /* Characters or UTF-8 bytes, whichever the caller has: one is encoded,
     * the other passed through. Upgrading unconditionally would re-encode a
     * byte string that was already UTF-8, turning every accented character
     * into mojibake. */
    bytes = pdfmake_markup_sv_bytes(aTHX_ src, &len);
    doc = pdfmake_markup_parse(bytes, len);
    if (!doc) croak("PDF::Make::Markup::Parse: out of memory");

    out = newHV();
    if (!doc->ok) {
        (void)hv_stores(out, "ok",    newSViv(0));
        (void)hv_stores(out, "error", newSVpv(doc->err, 0));
        (void)hv_stores(out, "line",  newSVuv(doc->err_line));
        (void)hv_stores(out, "col",   newSVuv(doc->err_col));
    } else {
        (void)hv_stores(out, "ok",   newSViv(1));
        (void)hv_stores(out, "root", pdfmake_markup_node_to_sv(aTHX_ doc->root));
    }
    pdfmake_markup_free(doc);
    return newRV_noinc((SV *)out);
}

/* ---- markup style: SV plumbing only, every decision is in the C ---------- */

/* Bytes out of an SV without re-encoding one that is already UTF-8 bytes. */
static const char *pdfmake_markup_sv_bytes(pTHX_ SV *sv, STRLEN *len)
{
    if (!sv || !SvOK(sv)) { *len = 0; return ""; }
    if (SvUTF8(sv)) {
        SV *copy = sv_2mortal(newSVsv(sv));
        sv_utf8_encode(copy);
        return SvPV(copy, *len);
    }
    return SvPV(sv, *len);
}

/* Croak with the position the node carries, which is what makes an error in a
 * template actionable rather than a puzzle. */
static void pdfmake_markup_croak_at(pTHX_ SV *node, SV *what, const char *msg)
{
    SV *out = sv_2mortal(newSVpvs(""));

    if (what && SvOK(what))
        sv_catpvf(out, "%" SVf " ", SVfARG(what));
    sv_catpv(out, msg);

    if (node && SvROK(node) && SvTYPE(SvRV(node)) == SVt_PVHV) {
        HV *h = (HV *)SvRV(node);
        SV **line = hv_fetchs(h, "line", 0);
        SV **col  = hv_fetchs(h, "col", 0);
        if (line && col && SvOK(*line))
            sv_catpvf(out, " at line %" IVdf ", column %" IVdf,
                      (IV)SvIV(*line), (IV)SvIV(*col));
    }
    croak("%" SVf, SVfARG(out));
}

/* A resolved value as the SV the Perl side expects: a number, a colour
 * string, an alignment word, or the string itself. */
static SV *pdfmake_markup_value_sv(pTHX_ pdfmake_prop_t p,
                                   const pdfmake_value_t *v)
{
    switch (pdfmake_style_type(p)) {
    case PDFMAKE_T_COLOUR:
        return newSVpv(v->colour, 0);
    case PDFMAKE_T_ALIGN:
        return newSVpv(v->num == PDFMAKE_ALIGN_CENTER ? "center"
                     : v->num == PDFMAKE_ALIGN_RIGHT  ? "right" : "left", 0);
    case PDFMAKE_T_VALIGN:
        return newSVpv(v->num == PDFMAKE_VALIGN_MIDDLE ? "middle"
                     : v->num == PDFMAKE_VALIGN_BOTTOM ? "bottom" : "top", 0);
    case PDFMAKE_T_STR:
        {
            SV *s = newSVpvn(v->str ? v->str : "", v->str_len);
            SvUTF8_on(s);
            return s;
        }
    case PDFMAKE_T_BOOL:
        return newSViv((IV)v->num);
    default:
        /* An integral value comes back as an integer, the way "1" + 0 does in
         * Perl. Handing back 1.0 instead broke an Int type constraint on
         * add_page(columns => ...), which is the sort of thing a port turns
         * up only when a document happens to use it. */
        if (v->num == (double)(IV)v->num &&
            v->num >= (double)IV_MIN && v->num <= (double)IV_MAX)
            return newSViv((IV)v->num);
        return newSVnv(v->num);
    }
}

static SV *pdfmake_markup_style_hv(pTHX_ const pdfmake_style_t *st)
{
    HV *out = newHV();
    int p;
    for (p = 1; p < PDFMAKE_P_MAX; p++) {
        const char *name;
        if (!st->v[p].set) continue;
        name = pdfmake_style_prop_name((pdfmake_prop_t)p);
        if (!name) continue;
        (void)hv_store(out, name, (I32)strlen(name),
                       pdfmake_markup_value_sv(aTHX_ (pdfmake_prop_t)p,
                                               &st->v[p]), 0);
    }
    return newRV_noinc((SV *)out);
}

/* Read a style hash back into the C struct, for inherit() and font_args(),
 * which take the hashes attrs() handed out. */
static void pdfmake_markup_style_from_hv(pTHX_ SV *sv, pdfmake_style_t *st)
{
    HV *h;
    int p;

    pdfmake_style_init(st);
    if (!sv || !SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV) return;
    h = (HV *)SvRV(sv);

    for (p = 1; p < PDFMAKE_P_MAX; p++) {
        const char *name = pdfmake_style_prop_name((pdfmake_prop_t)p);
        SV **slot;
        STRLEN len;
        const char *bytes;
        char err[PDFMAKE_STYLE_ERR_LEN];

        if (!name) continue;
        slot = hv_fetch(h, name, (I32)strlen(name), 0);
        if (!slot || !SvOK(*slot)) continue;

        bytes = pdfmake_markup_sv_bytes(aTHX_ *slot, &len);
        switch (pdfmake_style_type((pdfmake_prop_t)p)) {
        case PDFMAKE_T_COLOUR:
            if (!pdfmake_style_colour(bytes, len, st->v[p].colour,
                                      err, sizeof(err)))
                continue;
            break;
        case PDFMAKE_T_ALIGN:
            st->v[p].num = (len == 6 && memcmp(bytes, "center", 6) == 0)
                             ? PDFMAKE_ALIGN_CENTER
                         : (len == 5 && memcmp(bytes, "right", 5) == 0)
                             ? PDFMAKE_ALIGN_RIGHT : PDFMAKE_ALIGN_LEFT;
            break;
        case PDFMAKE_T_VALIGN:
            st->v[p].num = (len == 6 && memcmp(bytes, "middle", 6) == 0)
                             ? PDFMAKE_VALIGN_MIDDLE
                         : (len == 6 && memcmp(bytes, "bottom", 6) == 0)
                             ? PDFMAKE_VALIGN_BOTTOM : PDFMAKE_VALIGN_TOP;
            break;
        case PDFMAKE_T_STR:
            st->v[p].str = bytes;
            st->v[p].str_len = len;
            break;
        default:
            st->v[p].num = SvNV(*slot);
            break;
        }
        st->v[p].set = 1;
    }
}

/* One element's own attributes. The node comes from the parser as a hash, so
 * the attribute names and values are walked here and handed to the C for the
 * decisions. */
static SV *pdfmake_markup_style_attrs_sv(pTHX_ SV *node)
{
    pdfmake_style_t st;
    HV *nh, *attrs;
    SV **slot;
    STRLEN tlen;
    const char *tag_name;
    pdfmake_markup_tag_t tag;
    HE *he;
    char err[PDFMAKE_STYLE_ERR_LEN];

    pdfmake_style_init(&st);
    if (!node || !SvROK(node) || SvTYPE(SvRV(node)) != SVt_PVHV)
        croak("PDF::Make::Markup::Style::attrs: not a node");
    nh = (HV *)SvRV(node);

    slot = hv_fetchs(nh, "tag", 0);
    tag_name = slot ? pdfmake_markup_sv_bytes(aTHX_ *slot, &tlen) : "";
    if (!slot) tlen = 0;
    tag = pdfmake_markup_tag_id(tag_name, tlen);
    if (tag == PDFMAKE_MK_INVALID) {
        snprintf(err, sizeof(err), "no such tag '<%.*s>'", (int)tlen, tag_name);
        pdfmake_markup_croak_at(aTHX_ node, NULL, err);
    }

    slot = hv_fetchs(nh, "attrs", 0);
    if (!slot || !SvROK(*slot) || SvTYPE(SvRV(*slot)) != SVt_PVHV)
        return pdfmake_markup_style_hv(aTHX_ &st);
    attrs = (HV *)SvRV(*slot);

    hv_iterinit(attrs);
    while ((he = hv_iternext(attrs))) {
        I32 klen;
        const char *key = hv_iterkey(he, &klen);
        SV *val = hv_iterval(attrs, he);
        STRLEN vlen;
        const char *vbytes;
        pdfmake_prop_t p = pdfmake_style_prop(key, (size_t)klen);

        if (p == PDFMAKE_P_NONE) {
            snprintf(err, sizeof(err), "unknown attribute '%.*s' on <%.*s>",
                     (int)klen, key, (int)tlen, tag_name);
            pdfmake_markup_croak_at(aTHX_ node, NULL, err);
        }
        if (!pdfmake_style_tag_allows(tag, p)) {
            snprintf(err, sizeof(err),
                     "<%.*s> does not take '%.*s' (it takes: %s)",
                     (int)tlen, tag_name, (int)klen, key,
                     pdfmake_style_tag_allowed(tag));
            pdfmake_markup_croak_at(aTHX_ node, NULL, err);
        }

        vbytes = pdfmake_markup_sv_bytes(aTHX_ val, &vlen);
        {
            /* One attribute through the same coercion the C uses everywhere,
             * so a value means the same thing wherever it is written. */
            pdfmake_markup_node_t tmp;
            pdfmake_markup_attr_t attr;
            pdfmake_style_t one;

            memset(&tmp, 0, sizeof(tmp));
            memset(&attr, 0, sizeof(attr));
            tmp.kind = PDFMAKE_MARKUP_ELEM;
            tmp.tag  = tag;
            tmp.attrs = &attr;
            attr.name = key;
            attr.name_len = (size_t)klen;
            attr.value = vbytes;
            attr.value_len = vlen;

            if (!pdfmake_style_attrs(&tmp, &one, err, sizeof(err)))
                pdfmake_markup_croak_at(aTHX_ node, NULL, err);
            st.v[p] = one.v[p];
        }
    }
    return pdfmake_markup_style_hv(aTHX_ &st);
}

static SV *pdfmake_markup_style_decls_sv(pTHX_ SV *string, SV *node, SV *tag)
{
    pdfmake_style_t st;
    STRLEN slen, tlen;
    const char *src, *tag_name;
    pdfmake_markup_tag_t t;
    char err[PDFMAKE_STYLE_ERR_LEN];

    src      = pdfmake_markup_sv_bytes(aTHX_ string, &slen);
    tag_name = pdfmake_markup_sv_bytes(aTHX_ tag, &tlen);
    t = pdfmake_markup_tag_id(tag_name, tlen);

    if (t == PDFMAKE_MK_INVALID) {
        snprintf(err, sizeof(err), "no such tag '<%.*s>' in <style>",
                 (int)tlen, tag_name);
        pdfmake_markup_croak_at(aTHX_ node, NULL, err);
    }
    if (!pdfmake_style_declarations(src, slen, t, &st, err, sizeof(err)))
        pdfmake_markup_croak_at(aTHX_ node, NULL, err);

    return pdfmake_markup_style_hv(aTHX_ &st);
}

static SV *pdfmake_markup_style_inherit_sv(pTHX_ SV *parent, SV *own)
{
    pdfmake_style_t p, o, out;
    pdfmake_markup_style_from_hv(aTHX_ parent, &p);
    pdfmake_markup_style_from_hv(aTHX_ own, &o);
    pdfmake_style_inherit(&p, &o, &out);
    return pdfmake_markup_style_hv(aTHX_ &out);
}

static SV *pdfmake_markup_style_font_sv(pTHX_ SV *style)
{
    pdfmake_style_t st;
    HV *out = newHV();

    pdfmake_markup_style_from_hv(aTHX_ style, &st);

    if (st.v[PDFMAKE_P_SIZE].set)
        (void)hv_stores(out, "size", newSVnv(st.v[PDFMAKE_P_SIZE].num));
    if (st.v[PDFMAKE_P_COLOUR].set)
        (void)hv_stores(out, "colour", newSVpv(st.v[PDFMAKE_P_COLOUR].colour, 0));
    if (st.v[PDFMAKE_P_FONT].set) {
        SV *s = newSVpvn(st.v[PDFMAKE_P_FONT].str, st.v[PDFMAKE_P_FONT].str_len);
        SvUTF8_on(s);
        (void)hv_stores(out, "family", s);
    }
    if (st.v[PDFMAKE_P_BOLD].set)
        (void)hv_stores(out, "bold", newSViv((IV)st.v[PDFMAKE_P_BOLD].num));
    if (st.v[PDFMAKE_P_ITALIC].set)
        (void)hv_stores(out, "italic", newSViv((IV)st.v[PDFMAKE_P_ITALIC].num));
    if (st.v[PDFMAKE_P_LINE_HEIGHT].set)
        (void)hv_stores(out, "line_height",
                        newSVnv(st.v[PDFMAKE_P_LINE_HEIGHT].num));

    return newRV_noinc((SV *)out);
}

/* ---- markup profile ------------------------------------------------------
 *
 * Template::Stencil is constructed and driven through its own interface,
 * which is Perl methods. That call happens here rather than in a .pm so that
 * the arguments - escaping on, strictness on, this filter map and no other -
 * are not something a caller can reach past. Using Stencil's C ABI instead
 * would save a method dispatch per render and cost a build-time dependency on
 * its headers; the dispatch is not what a render spends its time on, so it
 * stays a method call until a profile says otherwise.
 */

static SV *pdfmake_markup_profile_filters(pTHX)
{
    HV *out = newHV();
    CV *money  = get_cv("PDF::Make::Markup::Profile::_filter_money", 0);
    CV *number = get_cv("PDF::Make::Markup::Profile::_filter_number", 0);
    if (money)  (void)hv_stores(out, "money",  newRV_inc((SV *)money));
    if (number) (void)hv_stores(out, "number", newRV_inc((SV *)number));
    return newRV_noinc((SV *)out);
}

static SV *pdfmake_markup_profile_engine(pTHX_ HV *args)
{
    dSP;
    SV *engine;
    HE *he;
    int count;

    /* Load it here rather than relying on the caller having done so. Without
     * this the constructor call fails method resolution, which surfaces as an
     * error with no message at all - the least useful failure there is. */
    if (!gv_stashpvs("Template::Stencil", 0)) {
        load_module(PERL_LOADMOD_NOIMPORT,
                    newSVpvs("Template::Stencil"), NULL);
        if (!gv_stashpvs("Template::Stencil", 0)) {
            SvREFCNT_dec((SV *)args);
            croak("PDF::Make::Markup::Profile needs Template::Stencil");
        }
    }

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvs("Template::Stencil")));

    hv_iterinit(args);
    while ((he = hv_iternext(args))) {
        I32 klen;
        const char *k = hv_iterkey(he, &klen);
        XPUSHs(sv_2mortal(newSVpvn(k, klen)));
        XPUSHs(sv_2mortal(newSVsv(hv_iterval(args, he))));
    }
    SvREFCNT_dec((SV *)args);
    PUTBACK;

    count = call_method("new", G_SCALAR | G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV)) {
        /* Copy before FREETMPS, which frees anything mortalised in here. */
        char msg[512];
        STRLEN elen;
        const char *etext = SvPV(ERRSV, elen);
        if (elen >= sizeof(msg)) elen = sizeof(msg) - 1;
        memcpy(msg, etext, elen);
        msg[elen] = 0;
        if (count > 0) (void)POPs;
        PUTBACK;
        FREETMPS;
        LEAVE;
        croak("PDF::Make::Markup::Profile: %s",
              elen ? msg : "Template::Stencil->new failed with no message");
    }

    /* Pop into a local before touching it: before 5.30 the SvREFCNT_inc
     * macros evaluated their argument twice, so inc(POPs) popped twice. */
    {
        SV *tmp = count > 0 ? POPs : &PL_sv_undef;
        engine = newSVsv(tmp);
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return engine;
}

static SV *pdfmake_markup_profile_render(pTHX_ SV *src, SV *data, SV *engine,
                                         HV *opts, UV max)
{
    dSP;
    STRLEN len;
    const char *bytes;
    char err[PDFMAKE_PROFILE_ERR_LEN];
    uint32_t line = 0;
    SV *out;
    int count;

    bytes = pdfmake_markup_sv_bytes(aTHX_ src, &len);
    if (!pdfmake_profile_check_source(bytes, len, &line, err, sizeof(err)))
        croak("template error at line %" UVuf ": %s", (UV)line, err);

    if (!engine || !SvOK(engine)) {
        HV *args = newHV();
        HE *he;
        (void)hv_stores(args, "auto_escape", newSViv(1));
        (void)hv_stores(args, "strict",      newSViv(1));
        (void)hv_stores(args, "sort_keys",   newSViv(1));
        (void)hv_stores(args, "cache",       newSViv(1));
        (void)hv_stores(args, "filters", pdfmake_markup_profile_filters(aTHX));
        hv_iterinit(opts);
        while ((he = hv_iternext(opts))) {
            I32 klen;
            const char *k = hv_iterkey(he, &klen);
            (void)hv_store(args, k, klen, newSVsv(hv_iterval(opts, he)), 0);
        }
        engine = sv_2mortal(pdfmake_markup_profile_engine(aTHX_ args));
    }

    /* Building the engine called into Perl, which can reallocate the stack.
     * The SP taken at the top of this function may now point into freed
     * memory, and pushing through it puts garbage where the arguments should
     * be - which shows up as "uninitialized value in subroutine entry" and a
     * call that receives nothing it was given. */
    SPAGAIN;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(engine);
    XPUSHs(src);
    XPUSHs(data && SvOK(data) ? data
                              : sv_2mortal(newRV_noinc((SV *)newHV())));
    PUTBACK;

    count = call_method("render", G_SCALAR | G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV)) {
        /* Copy the message out before FREETMPS: an SV mortalised inside this
         * scope is freed by it, and croaking with the corpse prints nothing
         * at all. */
        char msg[512];
        STRLEN elen;
        const char *etext = SvPV(ERRSV, elen);
        if (elen >= sizeof(msg)) elen = sizeof(msg) - 1;
        memcpy(msg, etext, elen);
        msg[elen] = 0;
        if (count > 0) (void)POPs;
        PUTBACK;
        FREETMPS;
        LEAVE;
        croak("%s", elen ? msg : "template render failed with no message");
    }

    {
        SV *tmp = count > 0 ? POPs : &PL_sv_undef;
        out = newSVsv(tmp);
    }
    PUTBACK;
    FREETMPS;
    LEAVE;

    if (max && SvOK(out)) {
        STRLEN olen;
        (void)SvPV(out, olen);
        if ((UV)olen > max) {
            SvREFCNT_dec(out);
            croak("template produced %" UVuf " bytes of markup, over the "
                  "%" UVuf " byte limit", (UV)olen, max);
        }
    }
    return out;
}

/* ---- markup render -------------------------------------------------------
 *
 * Profile, then parse, then build. The build stage is still Perl - it drives
 * PDF::Make::Builder, which is Perl - so this chains three calls rather than
 * pretending otherwise. When the document compiler is C, only this function
 * changes.
 */

#ifndef PDFMAKE_ENGINE_VERSION
#define PDFMAKE_ENGINE_VERSION 1
#endif

static SV *pdfmake_markup_call_1(pTHX_ const char *pkg, const char *method,
                                 SV *a, SV *b, SV *c)
{
    dSP;
    SV *out;
    int count;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(pkg, 0)));
    if (a) XPUSHs(a);
    if (b) XPUSHs(b);
    if (c) XPUSHs(c);
    PUTBACK;

    count = call_method(method, G_SCALAR);
    SPAGAIN;

    {
        SV *tmp = count > 0 ? POPs : &PL_sv_undef;
        out = newSVsv(tmp);
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return out;
}

static SV *pdfmake_markup_render_sv(pTHX_ SV *template, SV *data,
                                    HV *opts, SV *file_name)
{
    SV *markup, *root, *pdf, *bytes;
    HE *he;

    if (data) {
        /* Through the profile: escaping on, filters fixed, {% raw %} refused. */
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("PDF::Make::Markup::Profile")));
        XPUSHs(template);
        XPUSHs(SvOK(data) ? data : sv_2mortal(newRV_noinc((SV *)newHV())));
        hv_iterinit(opts);
        while ((he = hv_iternext(opts))) {
            I32 klen;
            const char *k = hv_iterkey(he, &klen);
            /* Only what the profile understands; the rest is for the build. */
            if ((klen == 6 && memcmp(k, "engine", 6) == 0) ||
                (klen == 12 && memcmp(k, "template_dir", 12) == 0) ||
                (klen == 5 && memcmp(k, "cache", 5) == 0) ||
                (klen == 10 && memcmp(k, "max_output", 10) == 0)) {
                XPUSHs(sv_2mortal(newSVpvn(k, klen)));
                XPUSHs(sv_2mortal(newSVsv(hv_iterval(opts, he))));
            }
        }
        PUTBACK;
        count = call_method("render", G_SCALAR);
        SPAGAIN;
        {
            /* Not mortal yet: a mortal made after SAVETMPS is freed by the
             * FREETMPS below, and the markup would be gone before it could be
             * parsed. Mortalise once the scope it belongs to is the caller's. */
            SV *tmp = count > 0 ? POPs : &PL_sv_undef;
            markup = newSVsv(tmp);
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
        markup = sv_2mortal(markup);
    } else {
        markup = template;
    }

    root = sv_2mortal(pdfmake_markup_call_1(aTHX_
        "PDF::Make::Markup::Parse", "parse", markup, NULL, NULL));

    /* The builder writes through a file name; when the caller only wants
     * bytes, give it one it will never use rather than a temporary file on
     * disk. Nothing is written unless save() is called. */
    pdf = sv_2mortal(pdfmake_markup_call_1(aTHX_
        "PDF::Make::Markup::Build", "build", root,
        sv_2mortal(newSVpvs("file_name")),
        file_name && SvOK(file_name) ? file_name
                                     : sv_2mortal(newSVpvs("unsaved"))));

    if (file_name && SvOK(file_name)) {
        dSP;
        ENTER; SAVETMPS; PUSHMARK(SP);
        XPUSHs(pdf);
        PUTBACK;
        (void)call_method("save", G_VOID | G_DISCARD);
        FREETMPS; LEAVE;
    }

    {
        dSP;
        int count;
        ENTER; SAVETMPS; PUSHMARK(SP);
        XPUSHs(pdf);
        PUTBACK;
        count = call_method("to_bytes", G_SCALAR);
        SPAGAIN;
        {
            SV *tmp = count > 0 ? POPs : &PL_sv_undef;
            bytes = newSVsv(tmp);
        }
        PUTBACK;
        FREETMPS; LEAVE;
    }
    return bytes;
}

/* Shared helper for render_page.xs */
static void hv_to_render_opts(pTHX_ HV *hv, pdfmake_render_opts_t *opts)
{
    SV **sv;

    pdfmake_render_opts_init(opts);

    if (!hv) return;

    if ((sv = hv_fetchs(hv, "dpi", 0)) && SvOK(*sv)) {
        opts->dpi = SvNV(*sv);
    }
    if ((sv = hv_fetchs(hv, "scale", 0)) && SvOK(*sv)) {
        opts->scale = SvNV(*sv);
    }
    if ((sv = hv_fetchs(hv, "scale_mode", 0)) && SvOK(*sv)) {
        opts->scale_mode = (pdfmake_scale_mode_t)SvIV(*sv);
    }
    if ((sv = hv_fetchs(hv, "antialias", 0)) && SvOK(*sv)) {
        opts->antialias = SvIV(*sv);
    }
    if ((sv = hv_fetchs(hv, "flatness", 0)) && SvOK(*sv)) {
        opts->flatness = SvNV(*sv);
    }
    if ((sv = hv_fetchs(hv, "rotation", 0)) && SvOK(*sv)) {
        opts->rotation = (pdfmake_rotation_t)SvIV(*sv);
    }
    if ((sv = hv_fetchs(hv, "background", 0)) && SvOK(*sv)) {
        opts->background = (uint32_t)SvUV(*sv);
    }
    if ((sv = hv_fetchs(hv, "render_text", 0)) && SvOK(*sv)) {
        opts->render_text = SvIV(*sv);
    }
    if ((sv = hv_fetchs(hv, "render_images", 0)) && SvOK(*sv)) {
        opts->render_images = SvIV(*sv);
    }
    if ((sv = hv_fetchs(hv, "render_vectors", 0)) && SvOK(*sv)) {
        opts->render_vectors = SvIV(*sv);
    }
    if ((sv = hv_fetchs(hv, "render_annotations", 0)) && SvOK(*sv)) {
        opts->render_annotations = SvIV(*sv);
    }
    if ((sv = hv_fetchs(hv, "show_text_bounds", 0)) && SvOK(*sv)) {
        opts->show_text_bounds = SvIV(*sv);
    }
    if ((sv = hv_fetchs(hv, "show_image_bounds", 0)) && SvOK(*sv)) {
        opts->show_image_bounds = SvIV(*sv);
    }
}

/* XOP descriptors — registered once in main BOOT, used by all modules */
static XOP pdfmake_chain_xop;
static XOP pdfmake_getter_xop;

/* Writer wrapper struct for XS binding. */
typedef struct {
    pdfmake_buf_t buf;
} pdfmake_writer_xs_t;

/* Arena wrapper struct - owns the arena. */
typedef struct {
    pdfmake_arena_t *arena;
} pdfmake_arena_xs_t;

/* Parser wrapper struct - owns parser, keeps buffer alive. */
typedef struct {
    pdfmake_parser_t *parser;
    SV               *bytes_sv;  /* Keep input buffer alive for parser */
    pdfmake_doc_t    *doc;       /* Parsed document (NULL until parsed) */
    int               parsed;    /* Whether parse() has been called */
} pdfmake_parser_xs_t;

/* Reader wrapper struct - owns reader, references parser. */
typedef struct {
    pdfmake_reader_t *reader;
    SV               *parser_sv;  /* SV ref to parser to keep it alive */
} pdfmake_reader_xs_t;

/* Reader page wrapper - references reader. */
typedef struct {
    pdfmake_reader_page_t *page;
    SV                    *reader_sv;  /* SV ref to reader to keep it alive */
} pdfmake_reader_page_xs_t;

/* Obj wrapper struct - holds arena and pointer to obj in arena. */
typedef struct {
    pdfmake_arena_xs_t *arena_xs;  /* Ref to arena wrapper (kept alive via SV) */
    SV                 *arena_sv;  /* SV ref to arena to prevent GC */
    pdfmake_obj_t      *obj;       /* Pointer to obj allocated in arena */
} pdfmake_obj_xs_t;
/* Encryption context wrapper. */
typedef struct {
    pdfmake_crypt_ctx_t ctx;
} pdfmake_crypt_xs_t;

MODULE = PDF::Make  PACKAGE = PDF::Make
PROTOTYPES: ENABLE

const char *
version()
    CODE:
        RETVAL = pdfmake_version();
    OUTPUT:
        RETVAL

BOOT:
{
    /* Register custom op XOPs */
    PDFMAKE_REGISTER_XOP(pdfmake_chain_xop, pp_pdfmake_chain,
                         "pdfmake_chain", "PDF::Make chainable method");
    PDFMAKE_REGISTER_XOP(pdfmake_getter_xop, pp_pdfmake_getter,
                         "pdfmake_getter", "PDF::Make struct getter");

    /* Register additional XOPs */
    static XOP pdfmake_meta_xop;
    PDFMAKE_REGISTER_XOP(pdfmake_meta_xop, pp_pdfmake_meta,
                         "pdfmake_meta", "PDF::Make metadata getter/setter");
    static XOP pdfmake_indirect_xop;
    PDFMAKE_REGISTER_XOP(pdfmake_indirect_xop, pp_pdfmake_indirect_getter,
                         "pdfmake_indirect", "PDF::Make indirect getter");
    static XOP pdfmake_typetest_xop;
    PDFMAKE_REGISTER_XOP(pdfmake_typetest_xop, pp_pdfmake_typetest,
                         "pdfmake_typetest", "PDF::Make type test");
    static XOP pdfmake_arena_ctor_xop;
    PDFMAKE_REGISTER_XOP(pdfmake_arena_ctor_xop, pp_pdfmake_arena_ctor,
                         "pdfmake_arena_ctor", "PDF::Make arena constructor");

    /* Per-module BOOT sections register their own getters, constants,
     * and chain dispatch tables via INCLUDE: directives below */
}

INCLUDE: xs/writer.xs
INCLUDE: xs/document.xs
INCLUDE: xs/page.xs
INCLUDE: xs/canvas.xs
INCLUDE: xs/parser.xs
INCLUDE: xs/arena.xs
INCLUDE: xs/obj.xs
INCLUDE: xs/reader.xs
INCLUDE: xs/image.xs
INCLUDE: xs/font.xs
INCLUDE: xs/extract.xs
INCLUDE: xs/outline.xs
INCLUDE: xs/action.xs
INCLUDE: xs/crypt.xs
INCLUDE: xs/form.xs
INCLUDE: xs/layer.xs
INCLUDE: xs/attach.xs
INCLUDE: xs/tag.xs
INCLUDE: xs/redact.xs
INCLUDE: xs/color.xs
INCLUDE: xs/watermark.xs
INCLUDE: xs/signature.xs
INCLUDE: xs/linear.xs
INCLUDE: xs/render.xs
INCLUDE: xs/render_page.xs
INCLUDE: xs/image_render.xs
INCLUDE: xs/import.xs
INCLUDE: xs/filter.xs
INCLUDE: xs/markup.xs
INCLUDE: xs/markup_style.xs
INCLUDE: xs/markup_profile.xs
INCLUDE: xs/markup_render.xs
