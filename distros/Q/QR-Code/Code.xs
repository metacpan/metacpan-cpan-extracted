#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <errno.h>

#include "qr/qr_encode.h"
#include "qr/qr_img.h"
#include "qr/qr_svg.h"
#include "qr_abi.h"

/* The whole battery is C: option parsing and validation, the encoder,
 * the serialisers, the ABI. The .pm is a version number and the POD.
 *
 * Every croak message here is pinned by a test; the messages are the
 * interface as much as the arguments are. */

static const char qr_ecc_letter[4] = { 'L', 'M', 'Q', 'H' };

/* ---- fetch helpers ------------------------------------------------------- */

static SV *qc_fetch(pTHX_ HV *hv, const char *key)
{
    SV **svp = hv_fetch(hv, key, (I32)strlen(key), 0);
    if (!svp || !SvOK(*svp))
        return NULL;
    return *svp;
}

static double qc_fetch_nv(pTHX_ HV *hv, const char *key, double dflt)
{
    SV *sv = qc_fetch(aTHX_ hv, key);
    return sv ? SvNV(sv) : dflt;
}

/* ---- scalar option validation -------------------------------------------- */

static int qc_ecc_of(pTHX_ SV *sv)
{
    STRLEN n;
    const char *p;

    if (!sv)
        return QR_ECC_M;
    p = SvPV_const(sv, n);
    if (n == 1)
        switch (*p) {
        case 'L': case 'l': return QR_ECC_L;
        case 'M': case 'm': return QR_ECC_M;
        case 'Q': case 'q': return QR_ECC_Q;
        case 'H': case 'h': return QR_ECC_H;
        }
    croak("ecc must be L, M, Q or H, not '%.*s'", (int)n, p);
    return -1;
}

static int qc_all_digits(const char *p, STRLEN n)
{
    STRLEN i;
    if (!n)
        return 0;
    for (i = 0; i < n; i++)
        if (p[i] < '0' || p[i] > '9')
            return 0;
    return 1;
}

static int qc_version_of(pTHX_ SV *sv)
{
    STRLEN n;
    const char *p;
    IV v;

    if (!sv)
        return 0;
    /* the digit check gates the numification: SvIV on 'seven' would
     * warn before the croak names it */
    p = SvPV_const(sv, n);
    if (!qc_all_digits(p, n))
        croak("version must be 1 to 15, not '%.*s'", (int)n, p);
    v = SvIV(sv);
    if (v < 1 || v > 15)
        croak("version must be 1 to 15, not '%.*s'", (int)n, p);
    return (int)v;
}

static int qc_quiet_of(pTHX_ SV *sv)
{
    STRLEN n;
    const char *p;
    IV q;

    if (!sv)
        return 4;
    p = SvPV_const(sv, n);
    if (!qc_all_digits(p, n))
        croak("quiet must be 0 to 16, not '%.*s'", (int)n, p);
    q = SvIV(sv);
    if (q > 16)
        croak("quiet must be 0 to 16, not '%.*s'", (int)n, p);
    return (int)q;
}

/* Unknown-key detection over a hash, in sorted order so the croak is
 * deterministic when several keys are wrong at once. */
static void qc_check_keys(pTHX_ const char *what, HV *hv,
                          const char *const *ok, int nok)
{
    AV *keys = newAV();
    HE *he;
    SSize_t i, n;

    sv_2mortal((SV *)keys);
    hv_iterinit(hv);
    while ((he = hv_iternext(hv)))
        av_push(keys, newSVpvn(HePV(he, PL_na), HeKLEN(he)));
    n = av_len(keys) + 1;
    if (n > 1) {
        /* insertion sort: option hashes are tiny */
        for (i = 1; i < n; i++) {
            SSize_t j = i;
            while (j > 0) {
                SV **a = av_fetch(keys, j - 1, 0);
                SV **b = av_fetch(keys, j, 0);
                if (strcmp(SvPV_nolen(*a), SvPV_nolen(*b)) <= 0)
                    break;
                {
                    SV *tmp = *a;
                    AvARRAY(keys)[j - 1] = *b;
                    AvARRAY(keys)[j] = tmp;
                }
                j--;
            }
        }
    }
    for (i = 0; i < n; i++) {
        SV **k = av_fetch(keys, i, 0);
        const char *kp = SvPV_nolen(*k);
        int j, found = 0;
        for (j = 0; j < nok; j++)
            if (strEQ(kp, ok[j])) { found = 1; break; }
        if (!found)
            croak("unknown %s option '%s'", what, kp);
    }
}

/* Build an option HV from (key => value) stack pairs. */
static HV *qc_pairs(pTHX_ const char *what, SV **base, I32 from, I32 items)
{
    HV *hv = newHV();
    I32 i;

    sv_2mortal((SV *)hv);
    if ((items - from) % 2)
        croak("odd number of options given to %s", what);
    for (i = from; i < items; i += 2) {
        STRLEN kl;
        const char *k = SvPV_const(base[i], kl);
        (void)hv_store(hv, k, (I32)kl, SvREFCNT_inc(base[i + 1]), 0);
    }
    return hv;
}

/* ---- image sniffing ------------------------------------------------------ */

/* Sniff logo bytes and, for rasters, prove the dimensions parse. The
 * messages are shared between the public _sniff and the logo path, so
 * a defect reports identically wherever the bytes came from. */
static int qc_sniff(pTHX_ const unsigned char *p, STRLEN len,
                    unsigned long *w, unsigned long *h)
{
    int fmt = qr_img_sniff(p, len);

    *w = *h = 0;
    if (fmt == QR_IMG_UNKNOWN) {
        if (len >= 4)
            croak("logo bytes are neither PNG, JPEG nor SVG "
                  "(starts %02x %02x %02x %02x)",
                  p[0], p[1], p[2], p[3]);
        croak("logo bytes are neither PNG, JPEG nor SVG "
              "(%d bytes long)", (int)len);
    }
    if (fmt != QR_IMG_SVG && qr_img_dims(p, len, fmt, w, h) < 0)
        croak("%s bytes are truncated or malformed; no pixel "
              "dimensions found",
              fmt == QR_IMG_PNG ? "PNG" : "JPEG");
    return fmt;
}

/* ---- the logo option ----------------------------------------------------- */

static SV *qc_slurp(pTHX_ const char *path)
{
    PerlIO *f = PerlIO_open(path, "rb");
    SV *out;
    char buf[65536];
    SSize_t n;

    if (!f)
        croak("logo file '%s': %s", path, Strerror(errno));
    out = sv_2mortal(newSVpvs(""));
    while ((n = PerlIO_read(f, buf, sizeof buf)) > 0)
        sv_catpvn(out, buf, (STRLEN)n);
    PerlIO_close(f);
    return out;
}

/* Fills *lg. Any SV whose bytes the logo borrows is mortal and lives
 * to the end of the XSUB, which outlives the render. */
static void qc_logo_of(pTHX_ SV *sv, qr_logo *lg)
{
    static const char *const ok[] =
        { "text", "svg", "image", "file", "scale", "em" };
    HV *h;
    SV *text, *markup, *image, *file, *bytes;
    int kinds;

    qr_logo_init(lg);

    if (!SvROK(sv)) {
        STRLEN n;
        const char *p = SvPV_const(sv, n);
        if (!n)
            croak("logo text is empty");
        lg->kind = QR_LOGO_TEXT;
        lg->text = p;
        lg->text_len = n;
        return;
    }
    if (SvTYPE(SvRV(sv)) != SVt_PVHV)
        croak("logo must be a string or a hashref");
    h = (HV *)SvRV(sv);
    qc_check_keys(aTHX_ "logo", h, ok, 6);

    text   = qc_fetch(aTHX_ h, "text");
    markup = qc_fetch(aTHX_ h, "svg");
    image  = qc_fetch(aTHX_ h, "image");
    file   = qc_fetch(aTHX_ h, "file");
    kinds  = !!text + !!markup + !!image + !!file;
    if (kinds != 1)
        croak("logo needs exactly one of text, svg, image or file");

    lg->scale = qc_fetch_nv(aTHX_ h, "scale", 0.0);
    lg->em    = qc_fetch_nv(aTHX_ h, "em", 0.0);

    if (text) {
        lg->text = SvPV_const(text, lg->text_len);
        if (!lg->text_len)
            croak("logo text is empty");
        lg->kind = QR_LOGO_TEXT;
        return;
    }
    if (markup) {
        lg->markup = SvPV_const(markup, lg->markup_len);
        lg->kind = QR_LOGO_SVG;
        return;
    }

    /* image bytes, or a file holding any of the three formats; the
     * format always comes from the bytes, never from the name */
    bytes = image ? image : qc_slurp(aTHX_ SvPV_nolen_const(file));
    {
        const unsigned char *p;
        STRLEN n;
        unsigned long w, hgt;
        int fmt;

        p = (const unsigned char *)SvPVbyte(bytes, n);
        fmt = qc_sniff(aTHX_ p, n, &w, &hgt);
        if (fmt == QR_IMG_SVG) {
            lg->kind = QR_LOGO_SVG;
            lg->markup = (const char *)p;
            lg->markup_len = n;
        } else {
            lg->kind = QR_LOGO_IMAGE;
            lg->img = p;
            lg->img_len = n;
            lg->img_fmt = fmt;
        }
    }
}

/* ---- the style option ---------------------------------------------------- */

static void qc_color_copy(pTHX_ SV *sv, char *dst, size_t dstlen)
{
    STRLEN n;
    const char *p = SvPV_const(sv, n);

    if (n >= dstlen)
        n = dstlen - 1;
    memcpy(dst, p, n);
    dst[n] = '\0';
}

static void qc_style_of(pTHX_ SV *sv, qr_style *st)
{
    static const char *const ok[] =
        { "shape", "radius", "finder", "dark", "light", "finder_dark",
          "gradient" };
    HV *h;
    SV *v;

    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV)
        croak("style must be a hashref");
    h = (HV *)SvRV(sv);
    qc_check_keys(aTHX_ "style", h, ok, 7);

    if ((v = qc_fetch(aTHX_ h, "shape"))) {
        const char *p = SvPV_nolen_const(v);
        if      (strEQ(p, "square"))  st->shape = QR_SHAPE_SQUARE;
        else if (strEQ(p, "rounded")) st->shape = QR_SHAPE_ROUNDED;
        else if (strEQ(p, "dot"))     st->shape = QR_SHAPE_DOT;
        else croak("style shape must be square, rounded or dot, "
                   "not '%s'", p);
    }
    if ((v = qc_fetch(aTHX_ h, "finder"))) {
        const char *p = SvPV_nolen_const(v);
        if      (strEQ(p, "square"))  st->finder = QR_FINDER_SQUARE;
        else if (strEQ(p, "rounded")) st->finder = QR_FINDER_ROUNDED;
        else if (strEQ(p, "circle"))  st->finder = QR_FINDER_CIRCLE;
        else croak("style finder must be square, rounded or circle, "
                   "not '%s'", p);
    }
    if ((v = qc_fetch(aTHX_ h, "radius")))
        st->radius = SvNV(v);
    if ((v = qc_fetch(aTHX_ h, "dark")))
        qc_color_copy(aTHX_ v, st->dark, sizeof st->dark);
    if ((v = qc_fetch(aTHX_ h, "light")))
        qc_color_copy(aTHX_ v, st->light, sizeof st->light);
    if ((v = qc_fetch(aTHX_ h, "finder_dark")))
        qc_color_copy(aTHX_ v, st->finder_dark, sizeof st->finder_dark);

    if ((v = qc_fetch(aTHX_ h, "gradient"))) {
        static const char *const gok[] = { "type", "angle", "stops" };
        HV *g;
        SV *t, *stops;

        if (!SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVHV)
            croak("style gradient must be a hashref");
        g = (HV *)SvRV(v);
        qc_check_keys(aTHX_ "gradient", g, gok, 3);

        st->grad_radial = 0;
        if ((t = qc_fetch(aTHX_ g, "type"))) {
            const char *p = SvPV_nolen_const(t);
            if      (strEQ(p, "radial")) st->grad_radial = 1;
            else if (!strEQ(p, "linear"))
                croak("gradient type must be linear or radial, "
                      "not '%s'", p);
        }
        st->grad_angle = qc_fetch_nv(aTHX_ g, "angle", 0.0);

        stops = qc_fetch(aTHX_ g, "stops");
        if (!stops || !SvROK(stops) ||
            SvTYPE(SvRV(stops)) != SVt_PVAV ||
            av_len((AV *)SvRV(stops)) + 1 < 2)
            croak("gradient needs an arrayref of at least two stops");
        {
            AV *av = (AV *)SvRV(stops);
            SSize_t n = av_len(av) + 1, i;

            if (n > QR_MAX_STOPS)
                croak("gradient takes at most %d stops, got %d",
                      QR_MAX_STOPS, (int)n);
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(av, i, 0);
                if (!e || !SvOK(*e))
                    croak("gradient stop %d is undef", (int)i + 1);
                qc_color_copy(aTHX_ *e, st->stops[i],
                              sizeof st->stops[i]);
            }
            st->nstops = (int)n;
        }
    }
}

/* ---- shared build steps -------------------------------------------------- */

static void qc_encode_or_croak(pTHX_ qr_matrix *q,
                               SV *data, int ecc, int version)
{
    STRLEN len;
    const unsigned char *p = (const unsigned char *)SvPVbyte(data, len);
    int rc = qr_encode(q, p, (int)len, ecc, version);

    if (rc == 0)
        return;
    if (rc == -1) {
        int v = version ? version : QR_MAX_VERSION;
        croak("payload of %d bytes exceeds the %d byte capacity of "
              "version %d at ECC %c",
              (int)len, qr_capacity(v, ecc), v, qr_ecc_letter[ecc]);
    }
    croak("qr_encode rejected its arguments (ecc %d, version %d)",
          ecc, version);
}

/* Parse the svg/analyse option set, encode, render. The returned
 * string is malloc'd; the caller frees. */
static char *qc_render(pTHX_ const char *what, SV *data,
                       SV **base, I32 from, I32 items,
                       qr_svg_info *info)
{
    static const char *const ok[] =
        { "ecc", "version", "quiet", "logo", "style" };
    HV *opt = qc_pairs(aTHX_ what, base, from, items);
    qr_matrix q;
    qr_style st;
    qr_logo lg;
    char err[256];
    SV *osv;
    int ecc, version, quiet;
    char *out;

    qc_check_keys(aTHX_ what, opt, ok, 5);

    qr_style_init(&st);
    qr_logo_init(&lg);

    if ((osv = qc_fetch(aTHX_ opt, "logo"))) {
        /* a logo is erasures, and erasures need budget from a standing
         * start: Q or H only, and H unless the caller says otherwise */
        SV *esv = qc_fetch(aTHX_ opt, "ecc");
        ecc = esv ? qc_ecc_of(aTHX_ esv) : QR_ECC_H;
        if (ecc < QR_ECC_Q)
            croak("a centre logo needs ECC level Q or H, not %c",
                  qr_ecc_letter[ecc]);
        qc_logo_of(aTHX_ osv, &lg);
    } else {
        ecc = qc_ecc_of(aTHX_ qc_fetch(aTHX_ opt, "ecc"));
    }

    if ((osv = qc_fetch(aTHX_ opt, "style")))
        qc_style_of(aTHX_ osv, &st);

    version = qc_version_of(aTHX_ qc_fetch(aTHX_ opt, "version"));
    quiet   = qc_quiet_of(aTHX_ qc_fetch(aTHX_ opt, "quiet"));

    qc_encode_or_croak(aTHX_ &q, data, ecc, version);

    out = qr_svg_render(&q, quiet, &st, &lg, info, err, sizeof err);
    if (!out) {
        if (err[0])
            croak("%s", err);
        croak("out of memory rendering SVG");
    }
    return out;
}

static HV *qc_info_hv(pTHX_ const qr_svg_info *info, int has_logo)
{
    HV *ih = newHV();

    (void)hv_stores(ih, "version", newSViv(info->version));
    (void)hv_stores(ih, "ecc", newSVpvn(&qr_ecc_letter[info->ecc], 1));
    (void)hv_stores(ih, "mask", newSViv(info->mask));
    (void)hv_stores(ih, "size", newSViv(info->size));
    if (has_logo) {
        HV *lh = newHV();
        (void)hv_stores(lh, "x", newSVnv(info->bx));
        (void)hv_stores(lh, "y", newSVnv(info->by));
        (void)hv_stores(lh, "width", newSVnv(info->bw));
        (void)hv_stores(lh, "height", newSVnv(info->bh));
        (void)hv_stores(lh, "covered", newSViv(info->covered));
        (void)hv_stores(lh, "function_hits", newSViv(info->fn_hit));
        (void)hv_stores(lh, "hits", newSVpv(info->hits, 0));
        (void)hv_stores(ih, "logo", newRV_noinc((SV *)lh));
    }
    return ih;
}

/* ---- the ABI ------------------------------------------------------------- */

static int qc_abi_matrix(const unsigned char *data, int len, int ecc,
                         int want_version,
                         unsigned char *mod, unsigned char *fixed,
                         int *size, int *version_out, int *mask)
{
    qr_matrix q;
    int rc = qr_encode(&q, data, len, ecc, want_version);

    if (rc != 0)
        return rc;
    memcpy(mod, q.mod, (size_t)(q.size * q.size));
    memcpy(fixed, q.fixed, (size_t)(q.size * q.size));
    if (size)        *size = q.size;
    if (version_out) *version_out = q.version;
    if (mask)        *mask = q.mask;
    return 0;
}

static char *qc_abi_svg(const unsigned char *data, int len, int ecc,
                        int want_version, int quiet)
{
    qr_matrix q;
    qr_style st;
    qr_logo lg;
    char err[256];

    if (qr_encode(&q, data, len, ecc, want_version) != 0)
        return NULL;
    qr_style_init(&st);
    qr_logo_init(&lg);
    return qr_svg_render(&q, quiet, &st, &lg, NULL, err, sizeof err);
}

static int qc_abi_capacity(int ecc, int version)
{
    if (ecc < 0 || ecc > 3 ||
        version < QR_MIN_VERSION || version > QR_MAX_VERSION)
        return -1;
    return qr_capacity(version, ecc);
}

/* Read only what the caller's declared struct size covers: a consumer
 * compiled against an older, shorter layout hands over a shorter
 * struct, and the fields beyond it stay at their defaults. */
#define QC_HAS(sp, field) \
    ((sp)->size >= (size_t)((char *)(&(sp)->field + 1) - (char *)(sp)))

static char *qc_abi_svg_styled(const unsigned char *data, int len,
                               int ecc, int want_version, int quiet,
                               const qr_abi_style_t *style,
                               const qr_abi_logo_t *logo,
                               qr_abi_info_t *info,
                               char *err, size_t errlen)
{
    qr_matrix q;
    qr_style st;
    qr_logo lg;
    qr_svg_info si;
    char lerr[256];
    char *out;

    if (!err || !errlen) {
        err = lerr;
        errlen = sizeof lerr;
    }
    err[0] = '\0';

    qr_style_init(&st);
    qr_logo_init(&lg);

    if (style) {
        if (QC_HAS(style, shape))  st.shape  = style->shape;
        if (QC_HAS(style, finder)) st.finder = style->finder;
        if (QC_HAS(style, radius)) st.radius = style->radius;
        if (QC_HAS(style, dark) && style->dark[0]) {
            memcpy(st.dark, style->dark, sizeof st.dark - 1);
            st.dark[sizeof st.dark - 1] = '\0';
        }
        if (QC_HAS(style, light) && style->light[0]) {
            memcpy(st.light, style->light, sizeof st.light - 1);
            st.light[sizeof st.light - 1] = '\0';
        }
        if (QC_HAS(style, finder_dark) && style->finder_dark[0]) {
            memcpy(st.finder_dark, style->finder_dark,
                   sizeof st.finder_dark - 1);
            st.finder_dark[sizeof st.finder_dark - 1] = '\0';
        }
        if (QC_HAS(style, stops) && style->grad_type != QR_ABI_GRAD_NONE) {
            int i, n = style->nstops;
            if (n < 2 || n > QR_MAX_STOPS) {
                snprintf(err, errlen, "gradient needs 2 to %d stops, "
                         "got %d", QR_MAX_STOPS, n);
                return NULL;
            }
            for (i = 0; i < n; i++) {
                memcpy(st.stops[i], style->stops[i],
                       sizeof st.stops[i] - 1);
                st.stops[i][sizeof st.stops[i] - 1] = '\0';
            }
            st.nstops = n;
            st.grad_radial = style->grad_type == QR_ABI_GRAD_RADIAL;
            st.grad_angle = style->grad_angle;
        }
    }

    if (logo && QC_HAS(logo, kind) && logo->kind) {
        if (ecc < QR_ECC_Q) {
            snprintf(err, errlen,
                     "a centre logo needs ECC level Q or H");
            return NULL;
        }
        switch (logo->kind) {
        case QR_ABI_LOGO_TEXT:
            lg.kind = QR_LOGO_TEXT;
            lg.text = logo->text;
            lg.text_len = logo->text_len;
            break;
        case QR_ABI_LOGO_SVG:
            lg.kind = QR_LOGO_SVG;
            lg.markup = logo->markup;
            lg.markup_len = logo->markup_len;
            break;
        case QR_ABI_LOGO_IMAGE:
            lg.kind = QR_LOGO_IMAGE;
            lg.img = logo->img;
            lg.img_len = logo->img_len;
            lg.img_fmt = logo->img_fmt;
            break;
        default:
            snprintf(err, errlen, "unknown logo kind %d", logo->kind);
            return NULL;
        }
        if (QC_HAS(logo, scale)) lg.scale = logo->scale;
        if (QC_HAS(logo, em))    lg.em    = logo->em;
    }

    if (qr_encode(&q, data, len, ecc, want_version) != 0) {
        snprintf(err, errlen, "payload does not fit (ecc %d, "
                 "version %d)", ecc, want_version);
        return NULL;
    }

    out = qr_svg_render(&q, quiet, &st, &lg, &si, err, errlen);
    if (out && info && info->size >= sizeof(qr_abi_info_t)) {
        info->version = si.version;
        info->ecc = si.ecc;
        info->mask = si.mask;
        info->symbol_size = si.size;
        info->logo_x = si.bx;
        info->logo_y = si.by;
        info->logo_w = si.bw;
        info->logo_h = si.bh;
        info->logo_covered = si.covered;
        info->logo_function_hits = si.fn_hit;
    }
    return out;
}

static const qr_abi_t qc_abi = {
    QR_ABI_VERSION,
    qc_abi_matrix,
    qc_abi_svg,
    free,
    qc_abi_capacity,
    qc_abi_svg_styled
};

MODULE = QR::Code    PACKAGE = QR::Code

PROTOTYPES: DISABLE

void
matrix(class, data, ...)
    SV *class
    SV *data
  PPCODE:
    {
        static const char *const ok[] = { "ecc", "version" };
        HV *opt = qc_pairs(aTHX_ "matrix", &ST(0), 2, items);
        qr_matrix q;
        AV *rows, *frows;
        int r, c;

        PERL_UNUSED_VAR(class);
        qc_check_keys(aTHX_ "matrix", opt, ok, 2);
        qc_encode_or_croak(aTHX_ &q, data,
            qc_ecc_of(aTHX_ qc_fetch(aTHX_ opt, "ecc")),
            qc_version_of(aTHX_ qc_fetch(aTHX_ opt, "version")));

        rows = newAV();
        frows = (GIMME_V == G_LIST) ? newAV() : NULL;
        for (r = 0; r < q.size; r++) {
            AV *row = newAV();
            av_extend(row, q.size - 1);
            for (c = 0; c < q.size; c++)
                av_push(row, newSViv(q.mod[r * q.size + c]));
            av_push(rows, newRV_noinc((SV *)row));
            if (frows) {
                AV *frow = newAV();
                av_extend(frow, q.size - 1);
                for (c = 0; c < q.size; c++)
                    av_push(frow, newSViv(q.fixed[r * q.size + c]));
                av_push(frows, newRV_noinc((SV *)frow));
            }
        }

        if (frows) {
            EXTEND(SP, 5);
            mPUSHs(newRV_noinc((SV *)rows));
            mPUSHs(newRV_noinc((SV *)frows));
            mPUSHi(q.version);
            mPUSHi(q.mask);
            mPUSHi(q.size);
        } else {
            mXPUSHs(newRV_noinc((SV *)rows));
        }
    }

void
svg(class, data, ...)
    SV *class
    SV *data
  PPCODE:
    {
        qr_svg_info info;
        int want_info = GIMME_V == G_LIST;
        char *out;
        int has_logo;

        PERL_UNUSED_VAR(class);
        out = qc_render(aTHX_ "svg", data, &ST(0), 2, items, &info);
        has_logo = info.bw > 0;

        mXPUSHs(newSVpvn(out, strlen(out)));
        free(out);
        if (want_info)
            mXPUSHs(newRV_noinc((SV *)qc_info_hv(aTHX_ &info, has_logo)));
    }

void
analyse(class, data, ...)
    SV *class
    SV *data
  ALIAS:
    analyze = 1
  PPCODE:
    {
        qr_svg_info info;
        char *out;
        HV *ih;

        PERL_UNUSED_VAR(class);
        PERL_UNUSED_VAR(ix);
        out = qc_render(aTHX_ "analyse", data, &ST(0), 2, items, &info);
        free(out);

        ih = qc_info_hv(aTHX_ &info, info.bw > 0);
        (void)hv_stores(ih, "capacity",
            newSViv(qr_capacity(info.version, info.ecc)));
        if (info.bw > 0) {
            (void)hv_stores(ih, "logo_covered", newSViv(info.covered));
            (void)hv_stores(ih, "logo_function_hit",
                            newSViv(info.fn_hit));
            (void)hv_stores(ih, "logo_box_w", newSVnv(info.bw));
            (void)hv_stores(ih, "logo_box_h", newSVnv(info.bh));
        }
        mXPUSHs(newRV_noinc((SV *)ih));
    }

SV *
pbm(class, data, ...)
    SV *class
    SV *data
  CODE:
    {
        static const char *const ok[] = { "ecc", "version", "quiet" };
        HV *opt = qc_pairs(aTHX_ "pbm", &ST(0), 2, items);
        qr_matrix q;
        int quiet, span, r, c;

        PERL_UNUSED_VAR(class);
        qc_check_keys(aTHX_ "pbm", opt, ok, 3);
        quiet = qc_quiet_of(aTHX_ qc_fetch(aTHX_ opt, "quiet"));
        qc_encode_or_croak(aTHX_ &q, data,
            qc_ecc_of(aTHX_ qc_fetch(aTHX_ opt, "ecc")),
            qc_version_of(aTHX_ qc_fetch(aTHX_ opt, "version")));

        span = q.size + 2 * quiet;
        RETVAL = newSVpvf("P1\n%d %d\n", span, span);
        for (r = 0; r < span; r++) {
            int rr = r - quiet;
            for (c = 0; c < span; c++) {
                int cc = c - quiet;
                int dark = rr >= 0 && cc >= 0 &&
                           rr < q.size && cc < q.size &&
                           q.mod[rr * q.size + cc];
                sv_catpvn(RETVAL, dark ? "1" : "0", 1);
                sv_catpvn(RETVAL, c + 1 < span ? " " : "\n", 1);
            }
        }
    }
    OUTPUT:
        RETVAL

int
_capacity(ecc, version)
    int ecc
    int version
  CODE:
    if (ecc < 0 || ecc > 3 ||
        version < QR_MIN_VERSION || version > QR_MAX_VERSION)
        croak("_capacity: ecc %d version %d out of range", ecc, version);
    RETVAL = qr_capacity(version, ecc);
  OUTPUT:
    RETVAL

void
_sniff(bytes)
    SV *bytes
  PPCODE:
    {
        const unsigned char *p;
        STRLEN len;
        unsigned long w, h;
        int fmt;
        const char *name;

        p = (const unsigned char *)SvPVbyte(bytes, len);
        fmt = qc_sniff(aTHX_ p, len, &w, &h);
        name = fmt == QR_IMG_PNG ? "png"
             : fmt == QR_IMG_JPEG ? "jpeg" : "svg";
        EXTEND(SP, 3);
        mPUSHp(name, strlen(name));
        mPUSHu((UV)w);
        mPUSHu((UV)h);
    }

IV
_abi_ptr()
  CODE:
    RETVAL = PTR2IV(&qc_abi);
  OUTPUT:
    RETVAL

void
_abi_selftest()
  PPCODE:
    {
        HV *hv = newHV();
        unsigned char mod[QR_ABI_MAX_SIZE * QR_ABI_MAX_SIZE];
        unsigned char fixed[QR_ABI_MAX_SIZE * QR_ABI_MAX_SIZE];
        int size = 0, ver = 0, mask = 0;
        static const unsigned char payload[] = "qr-abi-selftest";
        int plen = (int)sizeof(payload) - 1;
        int matrix_ok = 0, svg_ok = 0, capacity_ok = 0, styled_ok = 0;
        qr_matrix q;
        char *s;

        if (qc_abi.matrix &&
            qc_abi.matrix(payload, plen, QR_ABI_ECC_M, 0,
                          mod, fixed, &size, &ver, &mask) == 0 &&
            qr_encode(&q, payload, plen, QR_ECC_M, 0) == 0 &&
            size == q.size && ver == q.version && mask == q.mask &&
            memcmp(mod, q.mod, (size_t)(size * size)) == 0 &&
            memcmp(fixed, q.fixed, (size_t)(size * size)) == 0)
            matrix_ok = 1;

        s = qc_abi.svg ? qc_abi.svg(payload, plen, QR_ABI_ECC_M, 0, 4)
                       : NULL;
        if (s) {
            svg_ok = strncmp(s, "<svg ", 5) == 0;
            qc_abi.free_fn(s);
        }

        capacity_ok = qc_abi.capacity &&
            qc_abi.capacity(QR_ABI_ECC_M, 1) == qr_capacity(1, QR_ECC_M) &&
            qc_abi.capacity(QR_ABI_ECC_H, 15) == qr_capacity(15, QR_ECC_H) &&
            qc_abi.capacity(0, 99) == -1;

        if (qc_abi.svg_styled) {
            qr_abi_style_t st;
            qr_abi_logo_t lg;
            qr_abi_info_t inf;
            char err[128];

            memset(&st, 0, sizeof st);
            st.size = sizeof st;
            st.shape = QR_ABI_SHAPE_ROUNDED;
            strcpy(st.dark, "#102a43");

            memset(&lg, 0, sizeof lg);
            lg.size = sizeof lg;
            lg.kind = QR_ABI_LOGO_TEXT;
            lg.text = "ok";
            lg.text_len = 2;

            memset(&inf, 0, sizeof inf);
            inf.size = sizeof inf;

            s = qc_abi.svg_styled(payload, plen, QR_ABI_ECC_H, 0, 4,
                                  &st, &lg, &inf, err, sizeof err);
            if (s) {
                styled_ok = strncmp(s, "<svg ", 5) == 0 &&
                            strstr(s, "#102a43") != NULL &&
                            strstr(s, ">ok</text>") != NULL &&
                            inf.symbol_size == 17 + 4 * inf.version &&
                            inf.logo_covered > 0;
                qc_abi.free_fn(s);
            }
        }

        (void)hv_stores(hv, "version", newSVuv(qc_abi.version));
        (void)hv_stores(hv, "matrix_ok", newSViv(matrix_ok));
        (void)hv_stores(hv, "svg_ok", newSViv(svg_ok));
        (void)hv_stores(hv, "free_ok", newSViv(qc_abi.free_fn != NULL));
        (void)hv_stores(hv, "capacity_ok", newSViv(capacity_ok));
        (void)hv_stores(hv, "styled_ok", newSViv(styled_ok));
        mXPUSHs(newRV_noinc((SV *)hv));
    }
