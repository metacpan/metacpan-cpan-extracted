#ifndef QR_SVG_H
#define QR_SVG_H

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "qr/qr_encode.h"
#include "qr/qr_img.h"

/* qr_svg.h - the SVG serialiser, with styling that answers to decoders.
 *
 * Every styling option here is also a way to produce a symbol that does
 * not scan, so each carries the rule that keeps it decodable:
 *
 *  - Colour is checked as luminance contrast, because a decoder
 *    binarizes: it converts to luminance and thresholds, and a loud
 *    red-on-green pair with near-equal luminance is invisible to it.
 *  - Dark must be darker. Some decoders try the inversion as a
 *    fallback; many do not.
 *  - Finder patterns are always drawn as solid shapes, never as their
 *    constituent modules, because the locator wants an unbroken
 *    1:1:3:1:1 run and gaps between dots break it.
 *
 * The floors are calibrated against zbar blur sweeps (2026-08, level H,
 * 600px render, gaussian sigma):
 *
 *  - Dots at radius 0.30 to 0.50 meet or beat the square baseline;
 *    0.25 falls below it and 0.20 falls off a cliff. Floor: 0.30.
 *  - Blur tolerance holds at the baseline down to a luminance gap of
 *    0.40 and degrades steadily below it. zbar itself decodes a clean
 *    render at gaps far smaller, but a clean 600px PNG is the
 *    friendliest case a symbol will ever meet. Floor: 0.40.
 */

#define QR_CONTRAST_FLOOR   0.40
#define QR_DOT_RADIUS_FLOOR 0.30

#define QR_SHAPE_SQUARE  0
#define QR_SHAPE_ROUNDED 1
#define QR_SHAPE_DOT     2

#define QR_FINDER_SQUARE  0
#define QR_FINDER_ROUNDED 1
#define QR_FINDER_CIRCLE  2

#define QR_LOGO_NONE  0
#define QR_LOGO_TEXT  1
#define QR_LOGO_SVG   2
#define QR_LOGO_IMAGE 3

#define QR_MAX_STOPS 8

typedef struct {
    int    shape;                 /* QR_SHAPE_* */
    double radius;                /* modules: corner radius or dot radius */
    int    finder;                /* QR_FINDER_* */
    char   dark[12];              /* as given, normalised to #rrggbb */
    char   light[12];             /* likewise, or "none" */
    char   finder_dark[12];
    int    nstops;                /* 0 = no gradient */
    int    grad_radial;
    double grad_angle;            /* degrees, linear only */
    char   stops[QR_MAX_STOPS][12];
} qr_style;

typedef struct {
    int                  kind;    /* QR_LOGO_* */
    const char          *text;    /* TEXT: the string, escaped at emit */
    size_t               text_len;
    const char          *markup;  /* SVG: caller markup */
    size_t               markup_len;
    const unsigned char *img;     /* IMAGE: raw bytes */
    size_t               img_len;
    int                  img_fmt; /* QR_IMG_PNG or QR_IMG_JPEG */
    double               scale;   /* fraction of the symbol side, 0 = 0.17 */
    double               em;      /* TEXT cap height in modules, 0 = auto */
} qr_logo;

typedef struct {
    int    version, ecc, mask, size;
    double bx, by, bw, bh;        /* logo box, module coords sans quiet */
    int    covered;               /* modules under the box */
    int    fn_hit;                /* function pattern modules under it */
    char   hits[64];              /* first few "r,c" pairs */
} qr_svg_info;

static void qr_style_init(qr_style *st)
{
    memset(st, 0, sizeof *st);
    st->shape = QR_SHAPE_SQUARE;
    st->finder = QR_FINDER_SQUARE;
    st->radius = 0.0;
    strcpy(st->dark, "#000000");
    strcpy(st->light, "#ffffff");
    st->finder_dark[0] = '\0';    /* empty = follow dark */
}

static void qr_logo_init(qr_logo *lg)
{
    memset(lg, 0, sizeof *lg);
    lg->kind = QR_LOGO_NONE;
}

/* --- a growable string --------------------------------------------------- */

typedef struct {
    char  *p;
    size_t len, cap;
} qr_str;

static int qr_str_grow(qr_str *s, size_t need)
{
    char *np;
    size_t cap = s->cap ? s->cap : 4096;

    while (cap < s->len + need + 1)
        cap *= 2;
    if (cap == s->cap)
        return 0;
    np = (char *)realloc(s->p, cap);
    if (!np)
        return -1;
    s->p = np;
    s->cap = cap;
    return 0;
}

static int qr_str_catf(qr_str *s, const char *fmt, ...)
{
    va_list ap, ap2;
    int n;

    va_start(ap, fmt);
    va_copy(ap2, ap);
    n = vsnprintf(NULL, 0, fmt, ap);
    va_end(ap);
    if (n < 0 || qr_str_grow(s, (size_t)n) < 0) {
        va_end(ap2);
        return -1;
    }
    vsnprintf(s->p + s->len, (size_t)n + 1, fmt, ap2);
    va_end(ap2);
    s->len += (size_t)n;
    return 0;
}

static int qr_str_catn(qr_str *s, const char *src, size_t n)
{
    if (qr_str_grow(s, n) < 0)
        return -1;
    memcpy(s->p + s->len, src, n);
    s->len += n;
    s->p[s->len] = '\0';
    return 0;
}

/* --- colour -------------------------------------------------------------- */

static int qr_hexval(char c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

/* Parse #rgb, #rrggbb or #rrggbbaa into 0..1 channels. Returns -1 for
 * anything else: the luminance check needs numbers, and a CSS
 * named-colour table is bloat with no consumer. */
static int qr_color_parse(const char *s, size_t n,
                          double *r, double *g, double *b, double *a)
{
    int v[8], i;

    if (n == 0 || s[0] != '#')
        return -1;
    s++; n--;
    if (n != 3 && n != 6 && n != 8)
        return -1;
    for (i = 0; i < (int)n; i++) {
        v[i] = qr_hexval(s[i]);
        if (v[i] < 0)
            return -1;
    }
    *a = 1.0;
    if (n == 3) {
        *r = (v[0] * 17) / 255.0;
        *g = (v[1] * 17) / 255.0;
        *b = (v[2] * 17) / 255.0;
    } else {
        *r = (v[0] * 16 + v[1]) / 255.0;
        *g = (v[2] * 16 + v[3]) / 255.0;
        *b = (v[4] * 16 + v[5]) / 255.0;
        if (n == 8)
            *a = (v[6] * 16 + v[7]) / 255.0;
    }
    return 0;
}

/* Relative luminance, sRGB linearised - the quantity a binarizer
 * effectively thresholds on. */
static double qr_lum_chan(double c)
{
    return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4);
}

static double qr_luminance(double r, double g, double b)
{
    return 0.2126 * qr_lum_chan(r) + 0.7152 * qr_lum_chan(g)
         + 0.0722 * qr_lum_chan(b);
}

/* Validate one colour option: hex, opaque, and store it normalised to
 * #rrggbb. Fills *lum. Returns -1 with err set. */
static int qr_color_check(const char *what, const char *s, size_t n,
                          char out[8], double *lum,
                          char *err, size_t errlen)
{
    double r, g, b, a;

    if (qr_color_parse(s, n, &r, &g, &b, &a) < 0) {
        snprintf(err, errlen,
            "%s '%.*s' is not a hex colour (#rgb, #rrggbb or #rrggbbaa)",
            what, (int)(n > 32 ? 32 : n), s);
        return -1;
    }
    if (a < 1.0) {
        snprintf(err, errlen,
            "%s '%.*s' is translucent (alpha %.2f); a translucent module "
            "is a contrast reduction wearing a costume",
            what, (int)n, s, a);
        return -1;
    }
    snprintf(out, 8, "#%02x%02x%02x",
             (int)(r * 255 + 0.5), (int)(g * 255 + 0.5), (int)(b * 255 + 0.5));
    *lum = qr_luminance(r, g, b);
    return 0;
}

/* One dark-role colour against the light ground. Inversion and a
 * too-small gap are different defects and get different messages. */
static int qr_contrast_check(const char *what, const char *hex, double dl,
                             double ll, char *err, size_t errlen)
{
    if (dl >= ll) {
        snprintf(err, errlen,
            "inverted colours: %s %s (luminance %.3f) is not darker than "
            "light (luminance %.3f); decoders assume dark modules on a "
            "light ground",
            what, hex, dl, ll);
        return -1;
    }
    if (ll - dl < QR_CONTRAST_FLOOR) {
        snprintf(err, errlen,
            "contrast too low: %s %s (luminance %.3f) against light "
            "(luminance %.3f) leaves %.3f, floor is %.2f",
            what, hex, dl, ll, ll - dl, QR_CONTRAST_FLOOR);
        return -1;
    }
    return 0;
}

/* --- shape subpaths ------------------------------------------------------ */

/* A clockwise rounded-rect subpath; rx 0 degenerates to the rect. */
static int qr_sub_rrect(qr_str *s, double x, double y,
                        double w, double h, double rx)
{
    if (rx <= 0.0)
        return qr_str_catf(s, "M%.7g %.7gh%.7gv%.7gh-%.7gz", x, y, w, h, w);
    return qr_str_catf(s,
        "M%.7g %.7gh%.7ga%.7g %.7g 0 0 1 %.7g %.7gv%.7g"
        "a%.7g %.7g 0 0 1 -%.7g %.7gh-%.7ga%.7g %.7g 0 0 1 -%.7g -%.7g"
        "v-%.7ga%.7g %.7g 0 0 1 %.7g -%.7gz",
        x + rx, y, w - 2 * rx, rx, rx, rx, rx, h - 2 * rx,
        rx, rx, rx, rx, w - 2 * rx, rx, rx, rx, rx,
        h - 2 * rx, rx, rx, rx, rx);
}

static int qr_sub_circle(qr_str *s, double cx, double cy, double r)
{
    return qr_str_catf(s,
        "M%.7g %.7ga%.7g %.7g 0 1 0 %.7g 0a%.7g %.7g 0 1 0 -%.7g 0z",
        cx - r, cy, r, r, 2 * r, r, r, 2 * r);
}

/* One module, rounded only on corners where both orthogonal neighbours
 * are light, so runs of modules stay fused into solid bars and only the
 * outline of each blob curves. Rounding every module individually opens
 * a gap at every joint, which reads as contrast loss under blur. */
static int qr_sub_cell_rounded(qr_str *s, const qr_matrix *q,
                               int r, int c, double x, double y, double rad)
{
    int size = q->size;
    const unsigned char *m = q->mod;
    int up    = r > 0          && m[(r - 1) * size + c];
    int down  = r < size - 1   && m[(r + 1) * size + c];
    int left  = c > 0          && m[r * size + c - 1];
    int right = c < size - 1   && m[r * size + c + 1];
    int nw = !up && !left, ne = !up && !right;
    int se = !down && !right, sw = !down && !left;

    if (qr_str_catf(s, "M%.7g %.7g", x + (nw ? rad : 0), y) < 0) return -1;
    if (qr_str_catf(s, "H%.7g", x + 1 - (ne ? rad : 0)) < 0) return -1;
    if (ne && qr_str_catf(s, "a%.7g %.7g 0 0 1 %.7g %.7g",
                          rad, rad, rad, rad) < 0) return -1;
    if (qr_str_catf(s, "V%.7g", y + 1 - (se ? rad : 0)) < 0) return -1;
    if (se && qr_str_catf(s, "a%.7g %.7g 0 0 1 -%.7g %.7g",
                          rad, rad, rad, rad) < 0) return -1;
    if (qr_str_catf(s, "H%.7g", x + (sw ? rad : 0)) < 0) return -1;
    if (sw && qr_str_catf(s, "a%.7g %.7g 0 0 1 -%.7g -%.7g",
                          rad, rad, rad, rad) < 0) return -1;
    if (qr_str_catf(s, "V%.7g", y + (nw ? rad : 0)) < 0) return -1;
    if (nw && qr_str_catf(s, "a%.7g %.7g 0 0 1 %.7g -%.7g",
                          rad, rad, rad, rad) < 0) return -1;
    return qr_str_catf(s, "z");
}

/* --- the pieces ---------------------------------------------------------- */

static int qr_in_finder(int r, int c, int size)
{
    return (r < 7 && c < 7) || (r < 7 && c >= size - 7) ||
           (r >= size - 7 && c < 7);
}

/* The data-and-function module path: everything dark except the three
 * finders, which are drawn separately as solid shapes. Timing,
 * alignment and format modules follow the module shape; they are
 * sampled at their centres exactly as data modules are. */
static int qr_emit_modules(qr_str *s, const qr_matrix *q, int quiet,
                           const qr_style *st, const char *fill)
{
    int size = q->size, r, c;
    double rad = st->radius;

    if (qr_str_catf(s, "<path%s fill=\"%s\" d=\"",
                    st->shape == QR_SHAPE_SQUARE
                        ? " shape-rendering=\"crispEdges\"" : "",
                    fill) < 0)
        return -1;

    for (r = 0; r < size; r++) {
        for (c = 0; c < size; c++) {
            double x = c + quiet, y = r + quiet;

            if (!q->mod[r * size + c] || qr_in_finder(r, c, size))
                continue;

            if (st->shape == QR_SHAPE_SQUARE) {
                int run = 0;
                while (c + run < size && q->mod[r * size + c + run] &&
                       !qr_in_finder(r, c + run, size))
                    run++;
                if (qr_str_catf(s, "M%d %dh%dv1h-%dz",
                                c + quiet, r + quiet, run, run) < 0)
                    return -1;
                c += run - 1;
            } else if (st->shape == QR_SHAPE_DOT) {
                if (qr_sub_circle(s, x + 0.5, y + 0.5, rad) < 0)
                    return -1;
            } else {
                if (qr_sub_cell_rounded(s, q, r, c, x, y, rad) < 0)
                    return -1;
            }
        }
    }
    return qr_str_catf(s, "\"/>\n");
}

/* One finder: a ring drawn with fill-rule evenodd so the 5x5 gap is a
 * hole showing the ground, then the 3x3 pupil. Two elements, never 33
 * modules. A horizontal line through the centre of the circle form
 * reads exactly 1:1:3:1:1, which is the line the locator tests; the
 * corners it rounds away are the part the ratio test never touches. */
static int qr_emit_finder(qr_str *s, int top, int left, int quiet,
                          const qr_style *st, const char *fill)
{
    double x = left + quiet, y = top + quiet;
    double cx = x + 3.5, cy = y + 3.5;
    int sq = st->finder == QR_FINDER_SQUARE;

    if (qr_str_catf(s, "<path%s fill-rule=\"evenodd\" fill=\"%s\" d=\"",
                    sq ? " shape-rendering=\"crispEdges\"" : "", fill) < 0)
        return -1;
    if (st->finder == QR_FINDER_CIRCLE) {
        if (qr_sub_circle(s, cx, cy, 3.5) < 0) return -1;
        if (qr_sub_circle(s, cx, cy, 2.5) < 0) return -1;
    } else {
        double rx = sq ? 0.0 : 0.3;
        if (qr_sub_rrect(s, x, y, 7, 7, rx * 7) < 0) return -1;
        if (qr_sub_rrect(s, x + 1, y + 1, 5, 5, rx * 5) < 0) return -1;
    }
    if (qr_str_catf(s, "\"/>\n<path%s fill=\"%s\" d=\"",
                    sq ? " shape-rendering=\"crispEdges\"" : "", fill) < 0)
        return -1;
    if (st->finder == QR_FINDER_CIRCLE) {
        if (qr_sub_circle(s, cx, cy, 1.5) < 0) return -1;
    } else {
        if (qr_sub_rrect(s, x + 2, y + 2, 3, 3,
                         (sq ? 0.0 : 0.3) * 3) < 0) return -1;
    }
    return qr_str_catf(s, "\"/>\n");
}

/* --- the logo box -------------------------------------------------------- */

/* Text wants a box wider than it is tall, and that matters beyond
 * looks: alignment patterns sit on a diagonal grid, and a short wide
 * box slips between rows of them where a square box of the same area
 * does not. An image's box follows its aspect ratio, so a wide
 * wordmark collects the same advantage. */
static int qr_logo_box(const qr_matrix *q, const qr_logo *lg,
                       double *bw, double *bh,
                       double *aw, double *ah,   /* art size inside the pad */
                       char *err, size_t errlen)
{
    int size = q->size;
    double scale = lg->scale > 0 ? lg->scale : 0.17;
    double side = size * scale;
    double aspect = 1.0;

    if (lg->kind == QR_LOGO_TEXT) {
        double em = lg->em > 0 ? lg->em : size * 0.105;
        /* a generic bold sans averages a little over half an em per
         * character; the box is padded and the text centred inside it */
        *aw = em * (0.62 * (double)lg->text_len + 0.85);
        *ah = em * 1.75;
        *bw = *aw;
        *bh = *ah;
        return 0;
    }

    if (lg->kind == QR_LOGO_IMAGE) {
        unsigned long w, h;
        if (qr_img_dims(lg->img, lg->img_len, lg->img_fmt, &w, &h) < 0) {
            snprintf(err, errlen, "logo image bytes are truncated or "
                     "malformed; no pixel dimensions found");
            return -1;
        }
        aspect = (double)w / (double)h;
    } else if (lg->kind == QR_LOGO_SVG) {
        /* aspect from the root viewBox when there is one */
        const char *vb = NULL, *end = lg->markup + lg->markup_len;
        const char *p = lg->markup;
        while (p + 8 < end && !vb) {
            if (memcmp(p, "viewBox=\"", 9) == 0)
                vb = p + 9;
            p++;
        }
        if (vb) {
            double a, b, c, d;
            if (sscanf(vb, "%lf %lf %lf %lf", &a, &b, &c, &d) == 4 &&
                c > 0 && d > 0)
                aspect = c / d;
        }
    }

    if (aspect >= 1.0) {
        *aw = side;
        *ah = side / aspect;
    } else {
        *ah = side;
        *aw = side * aspect;
    }
    *bw = *aw * 1.22;
    *bh = *ah * 1.22;
    return 0;
}

static int qr_xml_escape(qr_str *s, const char *p, size_t n)
{
    size_t i;
    for (i = 0; i < n; i++) {
        int rc;
        switch (p[i]) {
        case '&': rc = qr_str_catf(s, "&amp;"); break;
        case '<': rc = qr_str_catf(s, "&lt;"); break;
        case '>': rc = qr_str_catf(s, "&gt;"); break;
        default:  rc = qr_str_catn(s, p + i, 1); break;
        }
        if (rc < 0)
            return -1;
    }
    return 0;
}

static int qr_emit_logo(qr_str *s, const qr_matrix *q, int quiet,
                        const qr_style *st, const qr_logo *lg,
                        double bw, double bh, double aw, double ah)
{
    double cx = quiet + q->size / 2.0, cy = quiet + q->size / 2.0;

    /* The knockout pad. It takes the light colour, and when the ground
     * is transparent it stays an opaque white pad: the logo needs a
     * ground, and modules showing through are modules the overlap
     * budget never counted. */
    if (qr_str_catf(s,
            "<rect x=\"%.3f\" y=\"%.3f\" width=\"%.3f\" height=\"%.3f\" "
            "rx=\"%.3f\" fill=\"%s\"/>\n",
            cx - bw / 2, cy - bh / 2, bw, bh, bh * 0.22,
            strcmp(st->light, "none") == 0 ? "#ffffff" : st->light) < 0)
        return -1;

    if (lg->kind == QR_LOGO_TEXT) {
        double em = lg->em > 0 ? lg->em : q->size * 0.105;
        /* dy rather than dominant-baseline, which renderers honour
         * inconsistently; half a line low is modules not budgeted for */
        if (qr_str_catf(s,
                "<text x=\"%.3f\" y=\"%.3f\" dy=\"%.3f\" "
                "text-anchor=\"middle\" "
                "font-family=\"Helvetica,Arial,sans-serif\" "
                "font-weight=\"700\" font-size=\"%.3f\" fill=\"%s\">",
                cx, cy, em * 0.35, em, st->dark) < 0)
            return -1;
        if (qr_xml_escape(s, lg->text, lg->text_len) < 0)
            return -1;
        return qr_str_catf(s, "</text>\n");
    }

    if (lg->kind == QR_LOGO_IMAGE) {
        size_t b64 = qr_b64_len(lg->img_len);
        char *enc = (char *)malloc(b64 + 1);
        int rc;

        if (!enc)
            return -1;
        qr_b64_encode(lg->img, lg->img_len, enc);
        rc = qr_str_catf(s,
            "<image x=\"%.3f\" y=\"%.3f\" width=\"%.3f\" height=\"%.3f\" "
            "preserveAspectRatio=\"xMidYMid meet\" "
            "href=\"data:image/%s;base64,%s\"/>\n",
            cx - aw / 2, cy - ah / 2, aw, ah,
            lg->img_fmt == QR_IMG_PNG ? "png" : "jpeg", enc);
        free(enc);
        return rc;
    }

    /* SVG markup. A document with an <svg> root nests: its content is
     * lifted into an inner <svg> with the original viewBox, so it
     * scales with the symbol and needs no encoding. A rootless
     * fragment is assumed to live in a 100x100 box. */
    {
        const char *p = lg->markup, *end = p + lg->markup_len;
        const char *root = NULL, *open_end = NULL, *close = NULL;
        const char *scan;

        for (scan = p; scan + 4 <= end; scan++) {
            if (memcmp(scan, "<svg", 4) == 0) {
                root = scan;
                break;
            }
        }
        if (root) {
            for (scan = root; scan < end; scan++)
                if (*scan == '>') { open_end = scan + 1; break; }
            for (scan = end - 6; scan >= open_end; scan--)
                if (memcmp(scan, "</svg", 5) == 0) { close = scan; break; }
        }
        if (root && open_end && close) {
            const char *vb = NULL;
            for (scan = root; scan + 9 < open_end; scan++)
                if (memcmp(scan, "viewBox=\"", 9) == 0) { vb = scan; break; }
            if (qr_str_catf(s,
                    "<svg x=\"%.3f\" y=\"%.3f\" width=\"%.3f\" "
                    "height=\"%.3f\" preserveAspectRatio=\"xMidYMid meet\"",
                    cx - aw / 2, cy - ah / 2, aw, ah) < 0)
                return -1;
            if (vb) {
                const char *q2 = vb + 9;
                while (q2 < open_end && *q2 != '"')
                    q2++;
                if (qr_str_catf(s, " viewBox=\"") < 0)
                    return -1;
                if (qr_str_catn(s, vb + 9, (size_t)(q2 - vb - 9)) < 0)
                    return -1;
                if (qr_str_catf(s, "\"") < 0)
                    return -1;
            } else {
                if (qr_str_catf(s, " viewBox=\"0 0 100 100\"") < 0)
                    return -1;
            }
            if (qr_str_catf(s, ">") < 0)
                return -1;
            if (qr_str_catn(s, open_end, (size_t)(close - open_end)) < 0)
                return -1;
            return qr_str_catf(s, "</svg>\n");
        }

        if (qr_str_catf(s,
                "<g transform=\"translate(%.4f %.4f) scale(%.6f)\">",
                cx - aw / 2, cy - ah / 2, aw / 100.0) < 0)
            return -1;
        if (qr_str_catn(s, p, lg->markup_len) < 0)
            return -1;
        return qr_str_catf(s, "</g>\n");
    }
}

/* --- validation ---------------------------------------------------------- */

/* Normalises colours in place and runs every contrast check. The
 * gradient stops each face the same check a flat dark does; the worst
 * stop is what gates, so all of them are tested. */
static int qr_style_check(qr_style *st, char *err, size_t errlen)
{
    double dl, ll = 1.0, fl, sl;
    char norm[8];
    int transparent = strcmp(st->light, "none") == 0;
    int i;

    if (qr_color_check("style dark", st->dark, strlen(st->dark),
                       norm, &dl, err, errlen) < 0)
        return -1;
    memcpy(st->dark, norm, 8);

    if (!transparent) {
        if (qr_color_check("style light", st->light, strlen(st->light),
                           norm, &ll, err, errlen) < 0)
            return -1;
        memcpy(st->light, norm, 8);
        if (qr_contrast_check("dark", st->dark, dl, ll, err, errlen) < 0)
            return -1;
    }

    if (st->finder_dark[0]) {
        if (qr_color_check("style finder_dark", st->finder_dark,
                           strlen(st->finder_dark), norm, &fl,
                           err, errlen) < 0)
            return -1;
        memcpy(st->finder_dark, norm, 8);
        if (!transparent &&
            qr_contrast_check("finder_dark", st->finder_dark, fl, ll,
                              err, errlen) < 0)
            return -1;
    }

    for (i = 0; i < st->nstops; i++) {
        char what[32];
        snprintf(what, sizeof what, "gradient stop %d", i + 1);
        if (qr_color_check(what, st->stops[i], strlen(st->stops[i]),
                           norm, &sl, err, errlen) < 0)
            return -1;
        memcpy(st->stops[i], norm, 8);
        if (!transparent &&
            qr_contrast_check(what, st->stops[i], sl, ll, err, errlen) < 0)
            return -1;
    }

    if (st->shape == QR_SHAPE_DOT) {
        if (st->radius <= 0)
            st->radius = 0.5;
        if (st->radius > 0.5) {
            snprintf(err, errlen, "dot radius %.2f overlaps neighbouring "
                     "modules; the maximum is 0.5", st->radius);
            return -1;
        }
        if (st->radius < QR_DOT_RADIUS_FLOOR) {
            snprintf(err, errlen, "dot radius %.2f is below the floor of "
                     "%.2f; smaller dots stop scanning under blur",
                     st->radius, QR_DOT_RADIUS_FLOOR);
            return -1;
        }
    } else if (st->shape == QR_SHAPE_ROUNDED) {
        if (st->radius <= 0)
            st->radius = 0.3;
        if (st->radius > 0.5) {
            snprintf(err, errlen, "corner radius %.2f exceeds half a "
                     "module; the maximum is 0.5", st->radius);
            return -1;
        }
    }

    return 0;
}

/* --- the renderer -------------------------------------------------------- */

/* Serialise a matrix. Returns a malloc'd SVG document, or NULL with
 * err filled in (or empty on allocation failure). The caller frees. */
static char *qr_svg_render(const qr_matrix *q, int quiet,
                           const qr_style *st_in, const qr_logo *lg,
                           qr_svg_info *info, char *err, size_t errlen)
{
    qr_str s;
    qr_style st = *st_in;
    int size = q->size, span = size + 2 * quiet;
    const char *module_fill;
    const char *finder_fill;
    double bw = 0, bh = 0, aw = 0, ah = 0;

    err[0] = '\0';
    memset(&s, 0, sizeof s);
    if (info) {
        memset(info, 0, sizeof *info);
        info->version = q->version;
        info->ecc = q->ecc;
        info->mask = q->mask;
        info->size = size;
    }

    if (qr_style_check(&st, err, errlen) < 0)
        return NULL;
    finder_fill = st.finder_dark[0] ? st.finder_dark : st.dark;
    module_fill = st.nstops ? "url(#qg)" : st.dark;

    /* the logo box, clamped to the data region before anything renders:
     * rows and columns 8 to size-9, so a wide word cannot reach the
     * timing patterns or the format block */
    if (lg && lg->kind != QR_LOGO_NONE) {
        double half;

        if (qr_logo_box(q, lg, &bw, &bh, &aw, &ah, err, errlen) < 0)
            return NULL;
        half = size / 2.0;
        if (half - bw / 2 < 8 || half + bw / 2 > size - 8 ||
            half - bh / 2 < 8 || half + bh / 2 > size - 8) {
            snprintf(err, errlen,
                "logo box %.1f x %.1f modules exceeds the data region of "
                "the version %d symbol (%d x %d); shorten the text, lower "
                "the scale, or raise the version",
                bw, bh, q->version, size, size);
            return NULL;
        }

        if (info) {
            int r, c, hits = 0;
            size_t hl = 0;

            info->bx = half - bw / 2;
            info->by = half - bh / 2;
            info->bw = bw;
            info->bh = bh;
            for (r = 0; r < size; r++)
                for (c = 0; c < size; c++) {
                    double mx = c + 0.5, my = r + 0.5;
                    if (mx < half - bw / 2 || mx > half + bw / 2 ||
                        my < half - bh / 2 || my > half + bh / 2)
                        continue;
                    info->covered++;
                    if (q->fixed[r * size + c]) {
                        info->fn_hit++;
                        if (hits < 4) {
                            int n = snprintf(info->hits + hl,
                                             sizeof info->hits - hl,
                                             "%s%d,%d", hits ? " " : "",
                                             r, c);
                            if (n > 0 && hl + (size_t)n < sizeof info->hits)
                                hl += (size_t)n;
                            hits++;
                        }
                    }
                }
        }
    }

    if (qr_str_catf(&s,
            "<svg xmlns=\"http://www.w3.org/2000/svg\" "
            "viewBox=\"0 0 %d %d\" width=\"%d\" height=\"%d\">\n",
            span, span, span * 10, span * 10) < 0)
        goto oom;

    if (st.nstops) {
        int i;
        if (st.grad_radial) {
            if (qr_str_catf(&s,
                    "<defs><radialGradient id=\"qg\" cx=\"0.5\" cy=\"0.5\" "
                    "r=\"0.7071\">") < 0)
                goto oom;
        } else {
            double a = st.grad_angle * (3.14159265358979323846 / 180.0);
            double dx = cos(a) / 2, dy = sin(a) / 2;
            if (qr_str_catf(&s,
                    "<defs><linearGradient id=\"qg\" "
                    "x1=\"%.4f\" y1=\"%.4f\" x2=\"%.4f\" y2=\"%.4f\">",
                    0.5 - dx, 0.5 - dy, 0.5 + dx, 0.5 + dy) < 0)
                goto oom;
        }
        for (i = 0; i < st.nstops; i++)
            if (qr_str_catf(&s,
                    "<stop offset=\"%.4f\" stop-color=\"%s\"/>",
                    st.nstops == 1 ? 0.0 : (double)i / (st.nstops - 1),
                    st.stops[i]) < 0)
                goto oom;
        if (qr_str_catf(&s, st.grad_radial
                ? "</radialGradient></defs>\n"
                : "</linearGradient></defs>\n") < 0)
            goto oom;
    }

    if (strcmp(st.light, "none") != 0)
        if (qr_str_catf(&s,
                "<rect width=\"%d\" height=\"%d\" fill=\"%s\"/>\n",
                span, span, st.light) < 0)
            goto oom;

    if (qr_emit_modules(&s, q, quiet, &st, module_fill) < 0)
        goto oom;

    if (qr_emit_finder(&s, 0, 0, quiet, &st, finder_fill) < 0 ||
        qr_emit_finder(&s, 0, size - 7, quiet, &st, finder_fill) < 0 ||
        qr_emit_finder(&s, size - 7, 0, quiet, &st, finder_fill) < 0)
        goto oom;

    if (lg && lg->kind != QR_LOGO_NONE) {
        if (qr_emit_logo(&s, q, quiet, &st, lg, bw, bh, aw, ah) < 0)
            goto oom;
    }

    if (qr_str_catf(&s, "</svg>\n") < 0)
        goto oom;

    return s.p;

oom:
    free(s.p);
    if (!err[0])
        err[0] = '\0';
    return NULL;
}

#endif /* QR_SVG_H */
