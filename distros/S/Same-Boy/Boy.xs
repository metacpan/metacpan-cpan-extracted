#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include "gb.h"
#include "bootroms.h"

/* ------------------------------------------------------------------ *
 * Same::Boy - an XS bridge over the vendored SameBoy Core.
 *
 * The Perl object is a blessed scalar holding a pointer to one sb_t,
 * which owns a GB_gameboy_t (as its FIRST member, so a GB_gameboy_t* can
 * be cast back to sb_t* inside callbacks), a framebuffer the Core renders
 * into, and a growable capture buffer for APU audio samples. All of the
 * emulator's behaviour lives here: the OO surface, string->enum mapping,
 * file I/O and argument handling are done in C rather than in the .pm.
 * ------------------------------------------------------------------ */

/* Largest SameBoy screen (SGB with border) is 256x224. */
#define SB_FB_MAX (256 * 224)

typedef struct {
    GB_gameboy_t gb;            /* MUST be first member */
    uint32_t     fb[SB_FB_MAX];
    int16_t     *audio;         /* interleaved L,R int16 */
    size_t       audio_len;     /* samples used (in int16 units) */
    size_t       audio_cap;     /* samples allocated (in int16 units) */
    int          capture;       /* whether to store APU samples */
    char         model[8];      /* model string passed to the constructor */
} sb_t;

/* Extract the sb_t* from a blessed scalar reference. */
static sb_t *
sb_from_sv(pTHX_ SV *self)
{
    if (!SvROK(self))
        croak("Same::Boy: not a Same::Boy object");
    return INT2PTR(sb_t *, SvIV(SvRV(self)));
}

/* ASCII case-insensitive compare; b is a lower-case literal. */
static int
sb_ieq(const char *a, const char *b)
{
    while (*a && *b) {
        unsigned char ca = (unsigned char)*a++;
        unsigned char cb = (unsigned char)*b++;
        if (ca >= 'A' && ca <= 'Z') ca += 32;
        if (ca != cb) return 0;
    }
    return *a == 0 && *b == 0;
}

/* Lower-case src into dst (ASCII), NUL-terminated within dsz. */
static void
sb_strlower(const char *src, char *dst, size_t dsz)
{
    size_t i = 0;
    for (; src[i] && i + 1 < dsz; i++) {
        unsigned char c = (unsigned char)src[i];
        dst[i] = (c >= 'A' && c <= 'Z') ? (char)(c + 32) : (char)c;
    }
    dst[i] = '\0';
}

/* ---- string -> enum maps (croak on an unknown value) -------------------- */

/* Takes an already-lower-cased model string. */
static int
sb_model_id(pTHX_ const char *m)
{
    if (strEQ(m, "dmg"))  return 0x002;   /* GB_MODEL_DMG_B */
    if (strEQ(m, "mgb"))  return 0x100;   /* GB_MODEL_MGB   */
    if (strEQ(m, "sgb"))  return 0x004;   /* GB_MODEL_SGB   */
    if (strEQ(m, "sgb2")) return 0x101;   /* GB_MODEL_SGB2  */
    if (strEQ(m, "cgb"))  return 0x205;   /* GB_MODEL_CGB_E */
    croak("Same::Boy: unknown model '%s'", m);
    return 0; /* not reached */
}

static int
sb_key_index(pTHX_ const char *k)
{
    if (sb_ieq(k, "right"))  return 0;
    if (sb_ieq(k, "left"))   return 1;
    if (sb_ieq(k, "up"))     return 2;
    if (sb_ieq(k, "down"))   return 3;
    if (sb_ieq(k, "a"))      return 4;
    if (sb_ieq(k, "b"))      return 5;
    if (sb_ieq(k, "select")) return 6;
    if (sb_ieq(k, "start"))  return 7;
    croak("Same::Boy: unknown key '%s'", k);
    return -1; /* not reached */
}

static int
sb_color_correction(pTHX_ const char *mode)
{
    if (sb_ieq(mode, "disabled"))              return 0;
    if (sb_ieq(mode, "correct_curves"))        return 1;
    if (sb_ieq(mode, "modern_balanced"))       return 2;
    if (sb_ieq(mode, "modern_boost_contrast")) return 3;
    if (sb_ieq(mode, "reduce_contrast"))       return 4;
    if (sb_ieq(mode, "low_contrast"))          return 5;
    if (sb_ieq(mode, "modern_accurate"))       return 6;
    croak("Same::Boy: unknown color correction '%s'", mode);
    return -1; /* not reached */
}

static int
sb_highpass_mode(pTHX_ const char *mode)
{
    if (sb_ieq(mode, "off"))              return 0;
    if (sb_ieq(mode, "accurate"))         return 1;
    if (sb_ieq(mode, "remove_dc_offset")) return 2;
    croak("Same::Boy: unknown highpass mode '%s'", mode);
    return -1; /* not reached */
}

static int
sb_rtc_mode_id(pTHX_ const char *mode)
{
    if (sb_ieq(mode, "sync_to_host")) return 0;
    if (sb_ieq(mode, "accurate"))     return 1;
    croak("Same::Boy: unknown rtc mode '%s'", mode);
    return -1; /* not reached */
}

static int
sb_dmg_palette(pTHX_ const char *name)
{
    if (sb_ieq(name, "grey")) return 0;
    if (sb_ieq(name, "dmg"))  return 1;
    if (sb_ieq(name, "mgb"))  return 2;
    if (sb_ieq(name, "gbl"))  return 3;
    croak("Same::Boy: unknown palette '%s'", name);
    return -1; /* not reached */
}

/* ---- file helpers ------------------------------------------------------- */

/* Read an entire file into a fresh mortal string SV; croak on failure. */
static SV *
sb_slurp(pTHX_ const char *path)
{
    FILE  *f = fopen(path, "rb");
    long   n;
    size_t got;
    SV    *sv;

    if (!f)
        croak("Same::Boy: cannot read '%s': %s", path, strerror(errno));

    if (fseek(f, 0, SEEK_END) != 0 || (n = ftell(f)) < 0) {
        fclose(f);
        croak("Same::Boy: cannot read '%s': %s", path, strerror(errno));
    }
    fseek(f, 0, SEEK_SET);

    sv = newSV(n ? (STRLEN)n : 1);
    SvPOK_on(sv);
    got = fread(SvPVX(sv), 1, (size_t)n, f);
    fclose(f);
    SvCUR_set(sv, got);
    SvPVX(sv)[got] = '\0';
    return sv_2mortal(sv);
}

/* Write the bytes of data to path; croak on failure. */
static void
sb_spew(pTHX_ const char *path, SV *data)
{
    STRLEN      len;
    const char *buf = SvPV(data, len);
    FILE       *f   = fopen(path, "wb");

    if (!f)
        croak("Same::Boy: cannot write '%s': %s", path, strerror(errno));
    if (len && fwrite(buf, 1, len, f) != len) {
        fclose(f);
        croak("Same::Boy: cannot write '%s': %s", path, strerror(errno));
    }
    fclose(f);
}

/* ---- Core callbacks ----------------------------------------------------- */

/* Core asks us to pack (r,g,b) into a pixel word; use 0x00RRGGBB. */
static uint32_t
sb_rgb_encode(GB_gameboy_t *gb, uint8_t r, uint8_t g, uint8_t b)
{
    PERL_UNUSED_ARG(gb);
    return ((uint32_t)r << 16) | ((uint32_t)g << 8) | (uint32_t)b;
}

static void
sb_vblank(GB_gameboy_t *gb, GB_vblank_type_t type)
{
    PERL_UNUSED_ARG(gb);
    PERL_UNUSED_ARG(type);
}

/* APU sample callback: append one stereo frame to the capture buffer. */
static void
sb_sample(GB_gameboy_t *gb, GB_sample_t *sample)
{
    sb_t *s = (sb_t *)gb;   /* gb is the first member of sb_t */
    if (!s->capture) return;    /* still emitted, just not stored */
    if (s->audio_len + 2 > s->audio_cap) {
        size_t ncap = s->audio_cap ? s->audio_cap * 2 : 8192;
        int16_t *n = (int16_t *)saferealloc(s->audio, ncap * sizeof(int16_t));
        s->audio = n;
        s->audio_cap = ncap;
    }
    s->audio[s->audio_len++] = sample->left;
    s->audio[s->audio_len++] = sample->right;
}

/* Allocate and initialise an sb_t for the given GB model. */
static sb_t *
sb_create(pTHX_ int model_id)
{
    sb_t   *s = (sb_t *)safecalloc(1, sizeof(sb_t));
    size_t  brlen;
    const unsigned char *br;

    GB_init(&s->gb, (GB_model_t)model_id);
    GB_set_rgb_encode_callback(&s->gb, sb_rgb_encode);
    GB_set_vblank_callback(&s->gb, sb_vblank);
    GB_set_pixels_output(&s->gb, s->fb);
    /* Always install the sample callback so the APU emits (and thus resets)
     * samples; capture is gated by s->capture so we don't store anything
     * until the user enables audio. */
    GB_set_sample_rate(&s->gb, 44100);
    GB_apu_set_sample_callback(&s->gb, sb_sample);
    /* Auto-load the matching open-source boot ROM. */
    br = sb_default_bootrom(model_id, &brlen);
    GB_load_boot_rom_from_buffer(&s->gb, br, brlen);
    return s;
}

MODULE = Same::Boy		PACKAGE = Same::Boy

PROTOTYPES: DISABLE

BOOT:
{
    HV *stash = gv_stashpv("Same::Boy", GV_ADD);
    newCONSTSUB(stash, "KEY_RIGHT",  newSViv(1 << 0));
    newCONSTSUB(stash, "KEY_LEFT",   newSViv(1 << 1));
    newCONSTSUB(stash, "KEY_UP",     newSViv(1 << 2));
    newCONSTSUB(stash, "KEY_DOWN",   newSViv(1 << 3));
    newCONSTSUB(stash, "KEY_A",      newSViv(1 << 4));
    newCONSTSUB(stash, "KEY_B",      newSViv(1 << 5));
    newCONSTSUB(stash, "KEY_SELECT", newSViv(1 << 6));
    newCONSTSUB(stash, "KEY_START",  newSViv(1 << 7));
}

# ---- construction -------------------------------------------------------

SV *
new(class, ...)
    SV *class
    CODE:
    {
        int    i;
        char   model_lc[8];
        int    model_id;
        SV    *rom_sv  = NULL;
        SV    *boot_sv = NULL;
        SV    *rate_sv = NULL;
        sb_t  *s;
        SV    *obj;

        /* default model 'cgb' */
        strcpy(model_lc, "cgb");

        for (i = 1; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            SV         *v = ST(i + 1);
            if      (strEQ(k, "model"))       sb_strlower(SvPV_nolen(v), model_lc, sizeof(model_lc));
            else if (strEQ(k, "rom"))         rom_sv  = v;
            else if (strEQ(k, "boot_rom"))    boot_sv = v;
            else if (strEQ(k, "sample_rate")) rate_sv = v;
        }

        model_id = sb_model_id(aTHX_ model_lc);
        s = sb_create(aTHX_ model_id);
        strncpy(s->model, model_lc, sizeof(s->model) - 1);
        s->model[sizeof(s->model) - 1] = '\0';

        /* boot ROM before ROM, matching the original constructor order */
        if (boot_sv && SvOK(boot_sv)) {
            STRLEN len;
            SV *bytes = SvROK(boot_sv) ? SvRV(boot_sv)
                                       : sb_slurp(aTHX_ SvPV_nolen(boot_sv));
            const unsigned char *buf = (const unsigned char *)SvPV(bytes, len);
            GB_load_boot_rom_from_buffer(&s->gb, buf, (size_t)len);
        }
        if (rom_sv && SvOK(rom_sv)) {
            STRLEN len;
            SV *bytes = SvROK(rom_sv) ? SvRV(rom_sv)
                                      : sb_slurp(aTHX_ SvPV_nolen(rom_sv));
            const unsigned char *buf = (const unsigned char *)SvPV(bytes, len);
            GB_load_rom_from_buffer(&s->gb, buf, (size_t)len);
        }
        if (rate_sv && SvTRUE(rate_sv)) {
            GB_set_sample_rate(&s->gb, (unsigned)SvUV(rate_sv));
            s->capture = 1;
        }

        obj = newSV(0);
        sv_setiv(obj, PTR2IV(s));
        RETVAL = sv_bless(newRV_noinc(obj), gv_stashsv(class, GV_ADD));
    }
    OUTPUT:
        RETVAL

SV *
model(self)
    SV *self
    CODE:
        RETVAL = newSVpv(sb_from_sv(aTHX_ self)->model, 0);
    OUTPUT:
        RETVAL

void
DESTROY(self)
    SV *self
    CODE:
    {
        sb_t *s;
        if (SvROK(self) && (s = INT2PTR(sb_t *, SvIV(SvRV(self))))) {
            GB_free(&s->gb);
            if (s->audio) safefree(s->audio);
            safefree(s);
        }
    }

# ---- ROM / boot ROM -----------------------------------------------------

SV *
load_rom(self, src)
    SV *self
    SV *src
    CODE:
    {
        sb_t   *s = sb_from_sv(aTHX_ self);
        STRLEN  len;
        SV     *bytes = SvROK(src) ? SvRV(src) : sb_slurp(aTHX_ SvPV_nolen(src));
        const unsigned char *buf = (const unsigned char *)SvPV(bytes, len);
        GB_load_rom_from_buffer(&s->gb, buf, (size_t)len);
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

SV *
load_boot_rom(self, src)
    SV *self
    SV *src
    CODE:
    {
        sb_t   *s = sb_from_sv(aTHX_ self);
        STRLEN  len;
        SV     *bytes = SvROK(src) ? SvRV(src) : sb_slurp(aTHX_ SvPV_nolen(src));
        const unsigned char *buf = (const unsigned char *)SvPV(bytes, len);
        GB_load_boot_rom_from_buffer(&s->gb, buf, (size_t)len);
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

# ---- lifecycle / execution ----------------------------------------------

SV *
reset(self)
    SV *self
    CODE:
    {
        sb_t *s = sb_from_sv(aTHX_ self);
        GB_reset(&s->gb);
        GB_set_pixels_output(&s->gb, s->fb);
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

UV
run_frame(self)
    SV *self
    CODE:
        RETVAL = (UV)GB_run_frame(&sb_from_sv(aTHX_ self)->gb);
    OUTPUT:
        RETVAL

UV
run(self)
    SV *self
    CODE:
        RETVAL = (UV)GB_run(&sb_from_sv(aTHX_ self)->gb);
    OUTPUT:
        RETVAL

SV *
set_clock_multiplier(self, mult)
    SV     *self
    double  mult
    CODE:
        GB_set_clock_multiplier(&sb_from_sv(aTHX_ self)->gb, mult);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV *
set_turbo(self, on, no_frame_skip)
    SV   *self
    bool  on
    bool  no_frame_skip
    CODE:
        GB_set_turbo_mode(&sb_from_sv(aTHX_ self)->gb, on, no_frame_skip);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV *
set_rtc_mode(self, mode)
    SV         *self
    const char *mode
    CODE:
        GB_set_rtc_mode(&sb_from_sv(aTHX_ self)->gb,
                        (GB_rtc_mode_t)sb_rtc_mode_id(aTHX_ mode));
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

# ---- introspection ------------------------------------------------------

int
is_cgb(self)
    SV *self
    CODE:
        RETVAL = GB_is_cgb(&sb_from_sv(aTHX_ self)->gb) ? 1 : 0;
    OUTPUT:
        RETVAL

int
is_sgb(self)
    SV *self
    CODE:
        RETVAL = GB_is_sgb(&sb_from_sv(aTHX_ self)->gb) ? 1 : 0;
    OUTPUT:
        RETVAL

SV *
rom_title(self)
    SV *self
    CODE:
    {
        char title[17];
        memset(title, 0, sizeof(title));
        GB_get_rom_title(&sb_from_sv(aTHX_ self)->gb, title);
        RETVAL = newSVpv(title, 0);
    }
    OUTPUT:
        RETVAL

UV
rom_crc32(self)
    SV *self
    CODE:
        RETVAL = (UV)GB_get_rom_crc32(&sb_from_sv(aTHX_ self)->gb);
    OUTPUT:
        RETVAL

# ---- screen -------------------------------------------------------------

void
dimensions(self)
    SV *self
    PPCODE:
    {
        sb_t *s = sb_from_sv(aTHX_ self);
        EXTEND(SP, 2);
        mPUSHu(GB_get_screen_width(&s->gb));
        mPUSHu(GB_get_screen_height(&s->gb));
    }

SV *
pixels(self)
    SV *self
    CODE:
    {
        sb_t    *s = sb_from_sv(aTHX_ self);
        unsigned w = GB_get_screen_width(&s->gb);
        unsigned h = GB_get_screen_height(&s->gb);
        RETVAL = newSVpvn((const char *)s->fb,
                          (STRLEN)w * h * sizeof(uint32_t));
    }
    OUTPUT:
        RETVAL

# Canvas-ready pixels: tightly packed R,G,B,A (A=255) bytes, w*h*4 of them,
# suitable for a JS ImageData buffer.
SV *
pixels_rgba(self)
    SV *self
    CODE:
    {
        sb_t          *s = sb_from_sv(aTHX_ self);
        unsigned       w = GB_get_screen_width(&s->gb);
        unsigned       h = GB_get_screen_height(&s->gb);
        STRLEN         n = (STRLEN)w * h;
        STRLEN         i;
        unsigned char *out;
        RETVAL = newSV(n * 4 + 1);
        SvPOK_on(RETVAL);
        SvCUR_set(RETVAL, n * 4);
        out = (unsigned char *)SvPVX(RETVAL);
        for (i = 0; i < n; i++) {
            uint32_t px = s->fb[i];        /* 0x00RRGGBB */
            out[i*4+0] = (px >> 16) & 0xFF;
            out[i*4+1] = (px >> 8)  & 0xFF;
            out[i*4+2] =  px        & 0xFF;
            out[i*4+3] = 0xFF;
        }
        SvPVX(RETVAL)[n * 4] = '\0';
    }
    OUTPUT:
        RETVAL

SV *
set_color_correction(self, mode)
    SV         *self
    const char *mode
    CODE:
        GB_set_color_correction_mode(&sb_from_sv(aTHX_ self)->gb,
            (GB_color_correction_mode_t)sb_color_correction(aTHX_ mode));
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV *
set_dmg_palette(self, name)
    SV         *self
    const char *name
    CODE:
    {
        sb_t *s = sb_from_sv(aTHX_ self);
        const GB_palette_t *p;
        switch (sb_dmg_palette(aTHX_ name)) {
            case 1:  p = &GB_PALETTE_DMG; break;
            case 2:  p = &GB_PALETTE_MGB; break;
            case 3:  p = &GB_PALETTE_GBL; break;
            default: p = &GB_PALETTE_GREY; break;
        }
        GB_set_palette(&s->gb, p);
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

# ---- audio --------------------------------------------------------------

SV *
set_sample_rate(self, rate)
    SV       *self
    unsigned  rate
    CODE:
    {
        sb_t *s = sb_from_sv(aTHX_ self);
        /* Callback stays installed (see sb_create); toggle capture and, when
         * enabling, apply the requested rate. */
        if (rate) {
            GB_set_sample_rate(&s->gb, rate);
            s->capture = 1;
        }
        else {
            s->capture = 0;
        }
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

SV *
set_highpass_filter(self, mode)
    SV         *self
    const char *mode
    CODE:
        GB_set_highpass_filter_mode(&sb_from_sv(aTHX_ self)->gb,
            (GB_highpass_mode_t)sb_highpass_mode(aTHX_ mode));
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

# Drain captured audio: return interleaved int16 L,R as a packed string
# and reset the capture buffer.
SV *
samples(self)
    SV *self
    CODE:
    {
        sb_t *s = sb_from_sv(aTHX_ self);
        RETVAL = s->audio_len
            ? newSVpvn((const char *)s->audio, s->audio_len * sizeof(int16_t))
            : newSVpvn("", 0);
        s->audio_len = 0;
    }
    OUTPUT:
        RETVAL

# ---- input --------------------------------------------------------------

SV *
press(self, button)
    SV         *self
    const char *button
    CODE:
        GB_set_key_state(&sb_from_sv(aTHX_ self)->gb,
                         (GB_key_t)sb_key_index(aTHX_ button), true);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV *
release(self, button)
    SV         *self
    const char *button
    CODE:
        GB_set_key_state(&sb_from_sv(aTHX_ self)->gb,
                         (GB_key_t)sb_key_index(aTHX_ button), false);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV *
press_for_player(self, button, player)
    SV         *self
    const char *button
    unsigned    player
    CODE:
        GB_set_key_state_for_player(&sb_from_sv(aTHX_ self)->gb,
            (GB_key_t)sb_key_index(aTHX_ button), player, true);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV *
release_for_player(self, button, player)
    SV         *self
    const char *button
    unsigned    player
    CODE:
        GB_set_key_state_for_player(&sb_from_sv(aTHX_ self)->gb,
            (GB_key_t)sb_key_index(aTHX_ button), player, false);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV *
set_key_mask(self, mask)
    SV  *self
    int  mask
    CODE:
        GB_set_key_mask(&sb_from_sv(aTHX_ self)->gb, (GB_key_mask_t)mask);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

# ---- battery-backed save RAM --------------------------------------------

SV *
save_battery(self)
    SV *self
    CODE:
    {
        sb_t *s = sb_from_sv(aTHX_ self);
        int   size = GB_save_battery_size(&s->gb);
        if (size <= 0) {
            RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = newSV(size);
            SvPOK_on(RETVAL);
            SvCUR_set(RETVAL, size);
            GB_save_battery_to_buffer(&s->gb,
                (uint8_t *)SvPVX(RETVAL), (size_t)size);
            *SvEND(RETVAL) = '\0';
        }
    }
    OUTPUT:
        RETVAL

SV *
load_battery(self, src)
    SV *self
    SV *src
    CODE:
    {
        sb_t   *s = sb_from_sv(aTHX_ self);
        STRLEN  len;
        SV     *bytes = SvROK(src) ? SvRV(src) : src;
        const unsigned char *buf = (const unsigned char *)SvPV(bytes, len);
        GB_load_battery_from_buffer(&s->gb, buf, (size_t)len);
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

SV *
save_battery_to_file(self, path)
    SV         *self
    const char *path
    CODE:
    {
        sb_t *s = sb_from_sv(aTHX_ self);
        int   size = GB_save_battery_size(&s->gb);
        SV   *data;
        if (size <= 0)
            croak("Same::Boy: no battery-backed RAM to save");
        data = sv_2mortal(newSV(size));
        SvPOK_on(data);
        SvCUR_set(data, size);
        GB_save_battery_to_buffer(&s->gb, (uint8_t *)SvPVX(data), (size_t)size);
        *SvEND(data) = '\0';
        sb_spew(aTHX_ path, data);
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

SV *
load_battery_from_file(self, path)
    SV         *self
    const char *path
    CODE:
    {
        sb_t   *s = sb_from_sv(aTHX_ self);
        STRLEN  len;
        SV     *bytes = sb_slurp(aTHX_ path);
        const unsigned char *buf = (const unsigned char *)SvPV(bytes, len);
        GB_load_battery_from_buffer(&s->gb, buf, (size_t)len);
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

# ---- save states --------------------------------------------------------

SV *
save_state(self)
    SV *self
    CODE:
    {
        sb_t  *s = sb_from_sv(aTHX_ self);
        size_t size = GB_get_save_state_size(&s->gb);
        RETVAL = newSV(size);
        SvPOK_on(RETVAL);
        SvCUR_set(RETVAL, size);
        GB_save_state_to_buffer(&s->gb, (uint8_t *)SvPVX(RETVAL));
        *SvEND(RETVAL) = '\0';
    }
    OUTPUT:
        RETVAL

SV *
load_state(self, src)
    SV *self
    SV *src
    CODE:
    {
        sb_t   *s = sb_from_sv(aTHX_ self);
        STRLEN  len;
        SV     *bytes = SvROK(src) ? SvRV(src) : src;
        const unsigned char *buf = (const unsigned char *)SvPV(bytes, len);
        int rc = GB_load_state_from_buffer(&s->gb, buf, (size_t)len);
        if (rc != 0)
            croak("Same::Boy: load_state failed (rc=%d)", rc);
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

SV *
save_state_to_file(self, path)
    SV         *self
    const char *path
    CODE:
    {
        sb_t  *s = sb_from_sv(aTHX_ self);
        size_t size = GB_get_save_state_size(&s->gb);
        SV    *data = sv_2mortal(newSV(size));
        SvPOK_on(data);
        SvCUR_set(data, size);
        GB_save_state_to_buffer(&s->gb, (uint8_t *)SvPVX(data));
        *SvEND(data) = '\0';
        sb_spew(aTHX_ path, data);
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

SV *
load_state_from_file(self, path)
    SV         *self
    const char *path
    CODE:
    {
        sb_t   *s = sb_from_sv(aTHX_ self);
        STRLEN  len;
        SV     *bytes = sb_slurp(aTHX_ path);
        const unsigned char *buf = (const unsigned char *)SvPV(bytes, len);
        int rc = GB_load_state_from_buffer(&s->gb, buf, (size_t)len);
        if (rc != 0)
            croak("Same::Boy: load_state failed (rc=%d)", rc);
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

# ---- rewind -------------------------------------------------------------

SV *
set_rewind_length(self, seconds)
    SV     *self
    double  seconds
    CODE:
        GB_set_rewind_length(&sb_from_sv(aTHX_ self)->gb, seconds);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

int
rewind(self)
    SV *self
    CODE:
        RETVAL = GB_rewind_pop(&sb_from_sv(aTHX_ self)->gb) ? 1 : 0;
    OUTPUT:
        RETVAL

# ---- cheats -------------------------------------------------------------

SV *
set_cheats_enabled(self, enabled)
    SV   *self
    bool  enabled
    CODE:
        GB_set_cheats_enabled(&sb_from_sv(aTHX_ self)->gb, enabled);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

int
cheats_enabled(self)
    SV *self
    CODE:
        RETVAL = GB_cheats_enabled(&sb_from_sv(aTHX_ self)->gb) ? 1 : 0;
    OUTPUT:
        RETVAL

# Import a Game Genie or GameShark code; returns true on success.
# Optional named args: description => $str, enabled => $bool (default true).
int
import_cheat(self, code, ...)
    SV         *self
    const char *code
    CODE:
    {
        sb_t       *s       = sb_from_sv(aTHX_ self);
        const char *desc    = code;
        bool        enabled = true;
        int         i;
        for (i = 2; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            SV         *v = ST(i + 1);
            if      (strEQ(k, "description")) desc    = SvPV_nolen(v);
            else if (strEQ(k, "enabled"))     enabled = SvTRUE(v) ? true : false;
        }
        RETVAL = GB_import_cheat(&s->gb, code, desc, enabled) != NULL ? 1 : 0;
    }
    OUTPUT:
        RETVAL

SV *
remove_all_cheats(self)
    SV *self
    CODE:
        GB_remove_all_cheats(&sb_from_sv(aTHX_ self)->gb);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL
