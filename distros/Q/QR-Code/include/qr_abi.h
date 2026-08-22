#ifndef QR_ABI_H
#define QR_ABI_H

/* qr_abi.h - the C ABI QR::Code exposes to other XS distributions.
 *
 * The table is reached at runtime through QR::Code::_abi_ptr, so a
 * consumer needs no symbols from this distribution at link time:
 *
 *     dSP; int count;
 *     qr_abi_t *qr;
 *     ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
 *     count = call_pv("QR::Code::_abi_ptr", G_SCALAR | G_NOARGS);
 *     SPAGAIN;
 *     qr = count == 1 ? INT2PTR(qr_abi_t *, POPi) : NULL;
 *     PUTBACK; FREETMPS; LEAVE;
 *
 * Check `version <= QR_ABI_VERSION`, never `==`. The table is
 * append-only: a newer QR::Code adds members after `free_fn` and bumps
 * the version, and a consumer compiled against this header keeps
 * working untouched. An equality check turns every append into a
 * breaking change for every consumer already shipped.
 *
 * This header is self-contained on purpose: it is the only header the
 * distribution installs, so nothing in it may depend on the internal
 * qr/ tree.
 */

#define QR_ABI_VERSION 2

/* ECC levels, matching the encoder's own constants. */
#define QR_ABI_ECC_L 0
#define QR_ABI_ECC_M 1
#define QR_ABI_ECC_Q 2
#define QR_ABI_ECC_H 3

/* Versions run 1 to 15, so a symbol is at most 77 modules a side. */
#define QR_ABI_MAX_SIZE 77

/* --- version 2: styling and the centre logo ------------------------------ */

#define QR_ABI_SHAPE_SQUARE   0
#define QR_ABI_SHAPE_ROUNDED  1
#define QR_ABI_SHAPE_DOT      2

#define QR_ABI_FINDER_SQUARE  0
#define QR_ABI_FINDER_ROUNDED 1
#define QR_ABI_FINDER_CIRCLE  2

#define QR_ABI_GRAD_NONE      0
#define QR_ABI_GRAD_LINEAR    1
#define QR_ABI_GRAD_RADIAL    2

#define QR_ABI_LOGO_TEXT      1
#define QR_ABI_LOGO_SVG       2
#define QR_ABI_LOGO_IMAGE     3

#define QR_ABI_IMG_PNG        1
#define QR_ABI_IMG_JPEG       2

#define QR_ABI_MAX_STOPS      8

/* Each struct opens with `size`, which the CALLER sets to sizeof() the
 * struct as it compiled it. The provider reads and writes only fields
 * that fit inside the declared size, so a consumer built against this
 * header keeps working against a provider whose structs have since
 * grown - the same append-only discipline as the table, carried into
 * its arguments. Zero the struct, set size, fill what you use. */

typedef struct {
    size_t size;
    int    shape;                 /* QR_ABI_SHAPE_* */
    int    finder;                /* QR_ABI_FINDER_* */
    double radius;                /* modules; 0 = the shape's default */
    char   dark[16];              /* hex, empty = default */
    char   light[16];             /* hex, "none", or empty */
    char   finder_dark[16];       /* empty = follow dark */
    int    grad_type;             /* QR_ABI_GRAD_* */
    double grad_angle;            /* degrees, linear only */
    int    nstops;
    char   stops[QR_ABI_MAX_STOPS][16];
} qr_abi_style_t;

typedef struct {
    size_t               size;
    int                  kind;    /* QR_ABI_LOGO_* */
    const char          *text;    /* TEXT */
    size_t               text_len;
    const char          *markup;  /* SVG */
    size_t               markup_len;
    const unsigned char *img;     /* IMAGE */
    size_t               img_len;
    int                  img_fmt; /* QR_ABI_IMG_* */
    double               scale;   /* fraction of the side, 0 = default */
    double               em;      /* TEXT cap height in modules, 0 = auto */
} qr_abi_logo_t;

typedef struct {
    size_t size;
    int    version, ecc, mask, symbol_size;
    double logo_x, logo_y, logo_w, logo_h;    /* modules, sans quiet */
    int    logo_covered;
    int    logo_function_hits;
} qr_abi_info_t;

typedef struct {
    unsigned int version;

    /* Encode `len` bytes of `data` at ECC level `ecc`. Pass `want_version`
     * 0 to select the smallest version that fits. `mod` and `fixed` are
     * caller-owned buffers of at least QR_ABI_MAX_SIZE * QR_ABI_MAX_SIZE
     * bytes; on success the first size*size bytes of `mod` hold the
     * modules row-major (1 = dark) and `fixed` marks function-pattern
     * modules. `size`, `version_out` and `mask` may be NULL. Returns 0,
     * -1 when the payload does not fit, -2 on bad arguments. */
    int (*matrix)(const unsigned char *data, int len, int ecc,
                  int want_version,
                  unsigned char *mod, unsigned char *fixed,
                  int *size, int *version_out, int *mask);

    /* Serialise to a default-styled SVG document with the given quiet
     * zone in modules (4 is the spec minimum). Returns a malloc'd
     * NUL-terminated string to release with free_fn, or NULL on the
     * same failures matrix reports. */
    char *(*svg)(const unsigned char *data, int len, int ecc,
                 int want_version, int quiet);

    void (*free_fn)(void *p);

    /* --- version 2 -------------------------------------------------------- */

    /* Byte-mode payload capacity of a version at an ECC level. */
    int (*capacity)(int ecc, int version);

    /* The full serialiser: styling and the centre logo, validated the
     * same way the Perl API validates - luminance contrast, shape
     * floors, the logo box clamped to the data region. `style`, `logo`
     * and `info` may each be NULL. Returns a malloc'd NUL-terminated
     * document for free_fn, or NULL with a reason in `err` (which may
     * itself be NULL when the reason does not matter). */
    char *(*svg_styled)(const unsigned char *data, int len, int ecc,
                        int want_version, int quiet,
                        const qr_abi_style_t *style,
                        const qr_abi_logo_t *logo,
                        qr_abi_info_t *info,
                        char *err, size_t errlen);
} qr_abi_t;

#endif /* QR_ABI_H */
