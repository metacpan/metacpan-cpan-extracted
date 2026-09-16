#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_mg_findext
#include "ppport.h"

#include <ghostty/vt.h>

enum { CB_PTY_WRITE, CB_TITLE_CHANGED, CB_BELL, CB_PWD_CHANGED, CB_COUNT };

static const char *const cb_names[CB_COUNT] = {
    "on_pty_write", "on_title_changed", "on_bell", "on_pwd_changed",
};

static const GhosttyTerminalOption cb_options[CB_COUNT] = {
    GHOSTTY_TERMINAL_OPT_WRITE_PTY,
    GHOSTTY_TERMINAL_OPT_TITLE_CHANGED,
    GHOSTTY_TERMINAL_OPT_BELL,
    GHOSTTY_TERMINAL_OPT_PWD_CHANGED,
};

typedef struct {
    GhosttyTerminal terminal;
    SV *self;
    SV *cb[CB_COUNT];
    SV *error;
    uint32_t cell_width;
    uint32_t cell_height;
    bool busy;
    bool destroy_pending;
} PerlGhostty;

static STRLEN utf8_seq_len(const U8 *s, const U8 *e) {
    U8 c = s[0];
    if (c < 0x80)
        return 1;
    if (c < 0xC2)
        return 0;
    if (c < 0xE0)
        return e - s >= 2 && (s[1] & 0xC0) == 0x80 ? 2 : 0;
    if (c < 0xF0) {
        if (e - s < 3 || (s[1] & 0xC0) != 0x80 || (s[2] & 0xC0) != 0x80)
            return 0;
        if ((c == 0xE0 && s[1] < 0xA0) || (c == 0xED && s[1] > 0x9F))
            return 0;
        return 3;
    }
    if (c < 0xF5) {
        if (e - s < 4 || (s[1] & 0xC0) != 0x80 || (s[2] & 0xC0) != 0x80
            || (s[3] & 0xC0) != 0x80)
            return 0;
        if ((c == 0xF0 && s[1] < 0x90) || (c == 0xF4 && s[1] > 0x8F))
            return 0;
        return 4;
    }
    return 0;
}

/* Decode UTF-8 from the library, replacing malformed sequences with U+FFFD. */
static SV *new_text_sv(pTHX_ const uint8_t *buf, size_t len) {
    const U8 *s = buf, *e = buf + len;
    SV *sv;

    while (s < e) {
        STRLEN n = utf8_seq_len(s, e);
        if (!n)
            break;
        s += n;
    }
    if (s == e)
        return newSVpvn_flags(len ? (const char *)buf : "", len, SVf_UTF8);

    sv = newSVpvn((const char *)buf, s - (const U8 *)buf);
    sv_grow(sv, len + len / 2 + 4);
    while (s < e) {
        STRLEN n = utf8_seq_len(s, e);
        if (n) {
            sv_catpvn(sv, (const char *)s, n);
            s += n;
        } else {
            sv_catpvn(sv, "\xEF\xBF\xBD", 3);
            s++;
        }
    }
    SvUTF8_on(sv);
    return sv;
}

static bool allowed_href(const char *v, STRLEN n) {
    static const char *const schemes[] = { "http://", "https://", "ftp://", "mailto:", "file://" };
    size_t i, k;
    for (i = 0; i < sizeof(schemes) / sizeof(schemes[0]); i++) {
        const char *p = schemes[i];
        for (k = 0; p[k] && k < n && toLOWER(v[k]) == p[k]; k++)
            ;
        if (!p[k])
            return true;
    }
    return false;
}

/* Drop the href of links (OSC 8) whose scheme could run script in a browser. */
static void filter_links(SV *sv) {
    static const char tag[] = "<a href=\"";
    const STRLEN taglen = sizeof(tag) - 1;
    char *s = SvPVX(sv), *e = s + SvCUR(sv), *r = s, *w = s;
    char *hit, *v, *q;

    while (r < e && (hit = ninstr(r, e, tag, tag + taglen)) != NULL) {
        v = hit + taglen;
        q = (char *)memchr(v, '"', e - v);
        if (!q)
            break;
        if (allowed_href(v, q - v)) {
            Move(r, w, q + 1 - r, char);
            w += q + 1 - r;
        } else {
            Move(r, w, hit - r, char);
            w += hit - r;
            Copy("<a", w, 2, char);
            w += 2;
        }
        r = q + 1;
    }
    Move(r, w, e - r, char);
    w += e - r;
    *w = '\0';
    SvCUR_set(sv, w - s);
}

static void release(pTHX_ PerlGhostty *self);

static int ghostty_mg_free(pTHX_ SV *sv, MAGIC *mg) {
    PerlGhostty *self = (PerlGhostty *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (self) {
        mg->mg_ptr = NULL;
        release(aTHX_ self);
    }
    return 0;
}

#ifdef USE_ITHREADS
static int ghostty_mg_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
    PERL_UNUSED_ARG(param);
    mg->mg_ptr = NULL;
    return 0;
}
#else
#define ghostty_mg_dup NULL
#endif

static MGVTBL ghostty_vtbl = {
    NULL, NULL, NULL, NULL, ghostty_mg_free, NULL, ghostty_mg_dup, NULL
};

static MAGIC *ghostty_magic(pTHX_ SV *sv) {
    return SvROK(sv) ? mg_findext(SvRV(sv), PERL_MAGIC_ext, &ghostty_vtbl) : NULL;
}

static PerlGhostty *get_ghostty(pTHX_ SV *sv, const char *method) {
    MAGIC *mg = ghostty_magic(aTHX_ sv);
    if (!mg)
        croak("Term::Ghostty::%s: not a Term::Ghostty object", method);
    if (!mg->mg_ptr)
        croak("Term::Ghostty::%s: object has been destroyed", method);
    return (PerlGhostty *)mg->mg_ptr;
}

/* Callbacks may reassign or free the caller's variable while the library reads it. */
static PerlGhostty *get_input(pTHX_ SV *self_sv, SV *data_sv, const char *method,
                              const char **data, STRLEN *len) {
    PerlGhostty *self;
    int i;
    *data = SvPV(data_sv, *len);
    self = get_ghostty(aTHX_ self_sv, method);
    for (i = 0; i < CB_COUNT; i++)
        if (self->cb[i]) {
            *data = SvPVX(sv_2mortal(newSVpvn(*data, *len)));
            break;
        }
    return self;
}

static uint16_t cell_count(pTHX_ SV *sv, const char *what) {
    NV n = SvNV(sv);
    if (!(n >= 1 && n <= 65535))
        croak("Term::Ghostty: %s must be between 1 and 65535", what);
    return (uint16_t)n;
}

static uint32_t pixel_size(pTHX_ SV *sv, const char *what) {
    NV n = SvNV(sv);
    if (!(n >= 0 && n <= 4294967295.0))
        croak("Term::Ghostty: %s must be between 0 and 4294967295", what);
    return (uint32_t)n;
}

static SV *callback_arg(pTHX_ SV *sv, const char *name) {
    SvGETMAGIC(sv);
    if (!SvOK(sv))
        return NULL;
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVCV)
        croak("Term::Ghostty: %s must be a code reference or undef", name);
    return sv_2mortal(newRV_inc(SvRV(sv)));
}

typedef struct {
    const char *ptr;
    STRLEN len;
    bool set;
} TextArg;

static TextArg text_arg(pTHX_ SV *sv) {
    TextArg t = { NULL, 0, false };
    if (sv) {
        SV *copy = sv_mortalcopy(sv);
        if (SvOK(copy)) {
            t.ptr = SvPVutf8(copy, t.len);
            t.set = true;
        }
    }
    return t;
}

static void set_text_option(GhosttyTerminal term, GhosttyTerminalOption opt, TextArg t) {
    GhosttyString gstr;
    gstr.ptr = (const uint8_t *)t.ptr;
    gstr.len = t.len;
    ghostty_terminal_set(term, opt, t.set ? &gstr : NULL);
}

static void release(pTHX_ PerlGhostty *self) {
    int i;
    if (self->terminal)
        ghostty_terminal_free(self->terminal);
    for (i = 0; i < CB_COUNT; i++)
        SvREFCNT_dec(self->cb[i]);
    SvREFCNT_dec(self->error);
    Safefree(self);
}

static void guard_enter(pTHX_ PerlGhostty *self, const char *method) {
    if (self->busy)
        croak("Term::Ghostty::%s: cannot be called from inside a callback", method);
    self->busy = true;
    SvREFCNT_inc_simple_void_NN(self->self);
}

/* May free self; the caller must not touch self afterwards. */
static void guard_leave(pTHX_ PerlGhostty *self) {
    SV *obj = self->self;
    SV *err = self->error;

    self->error = NULL;
    self->busy = false;
    if (self->destroy_pending) {
        mg_findext(obj, PERL_MAGIC_ext, &ghostty_vtbl)->mg_ptr = NULL;
        release(aTHX_ self);
    }
    SvREFCNT_dec(obj);
    if (err)
        croak_sv(sv_2mortal(err));
}

/* The callback gets its own stack so next/last/goto cannot unwind past the library. */
static void invoke(pTHX_ PerlGhostty *self, int slot, SV *arg) {
    dSP;
    SV *cb = self->cb[slot];

    if (!cb || self->error) {
        SvREFCNT_dec(arg);
        return;
    }

    ENTER;
    SAVETMPS;
    save_scalar(PL_errgv);
    SAVEFREESV(SvREFCNT_inc_simple_NN(cb));
    if (arg)
        sv_2mortal(arg);

    PUSHSTACKi(PERLSI_MAGIC);
    SPAGAIN;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    mPUSHs(newRV_inc(self->self));
    if (arg)
        PUSHs(arg);
    PUTBACK;
    call_sv(cb, G_VOID | G_DISCARD | G_EVAL);
    POPSTACK;

    if (SvROK(ERRSV) || SvTRUE(ERRSV))
        self->error = newSVsv(ERRSV);

    FREETMPS;
    LEAVE;
}

static SV *terminal_text(pTHX_ GhosttyTerminal term, GhosttyTerminalData which) {
    GhosttyString str = { NULL, 0 };
    ghostty_terminal_get(term, which, &str);
    return new_text_sv(aTHX_ str.ptr, str.len);
}

static void cb_write_pty(GhosttyTerminal term, void *ud, const uint8_t *data, size_t len) {
    dTHX;
    PERL_UNUSED_ARG(term);
    invoke(aTHX_ (PerlGhostty *)ud, CB_PTY_WRITE, newSVpvn((const char *)data, len));
}

static void cb_title_changed(GhosttyTerminal term, void *ud) {
    dTHX;
    invoke(aTHX_ (PerlGhostty *)ud, CB_TITLE_CHANGED,
           terminal_text(aTHX_ term, GHOSTTY_TERMINAL_DATA_TITLE));
}

static void cb_bell(GhosttyTerminal term, void *ud) {
    dTHX;
    PERL_UNUSED_ARG(term);
    invoke(aTHX_ (PerlGhostty *)ud, CB_BELL, NULL);
}

static void cb_pwd_changed(GhosttyTerminal term, void *ud) {
    dTHX;
    invoke(aTHX_ (PerlGhostty *)ud, CB_PWD_CHANGED,
           terminal_text(aTHX_ term, GHOSTTY_TERMINAL_DATA_PWD));
}

static const void *const cb_trampolines[CB_COUNT] = {
    (const void *)cb_write_pty,
    (const void *)cb_title_changed,
    (const void *)cb_bell,
    (const void *)cb_pwd_changed,
};

static bool cb_device_attributes(GhosttyTerminal term, void *ud, GhosttyDeviceAttributes *out) {
    PERL_UNUSED_ARG(term);
    PERL_UNUSED_ARG(ud);
    Zero(out, 1, GhosttyDeviceAttributes);
    out->primary.conformance_level = 62;
    out->primary.features[0] = 22;
    out->primary.num_features = 1;
    out->secondary.device_type = GHOSTTY_DA_DEVICE_TYPE_VT220;
    return true;
}

static bool cb_size(GhosttyTerminal term, void *ud, GhosttySizeReportSize *out) {
    PerlGhostty *self = (PerlGhostty *)ud;
    out->rows = 0;
    out->columns = 0;
    ghostty_terminal_get(term, GHOSTTY_TERMINAL_DATA_ROWS, &out->rows);
    ghostty_terminal_get(term, GHOSTTY_TERMINAL_DATA_COLS, &out->columns);
    out->cell_width = self->cell_width;
    out->cell_height = self->cell_height;
    return true;
}

static void set_callback(pTHX_ PerlGhostty *self, int slot, SV *cb) {
    SV *old = self->cb[slot];
    self->cb[slot] = cb ? newSVsv(cb) : NULL;
    ghostty_terminal_set(self->terminal, cb_options[slot], cb ? cb_trampolines[slot] : NULL);
    SvREFCNT_dec(old);
}

MODULE = Term::Ghostty  PACKAGE = Term::Ghostty

PROTOTYPES: DISABLE

SV *
new(klass, ...)
    SV *klass
  PREINIT:
    PerlGhostty *self;
    HV *stash;
    uint16_t cols = 80, rows = 24;
    uint32_t cell_w = 0, cell_h = 0;
    SV *title_sv = NULL, *pwd_sv = NULL, *scrollback_sv = NULL;
    TextArg title, pwd;
    size_t scrollback = 0;
    SV *cbs[CB_COUNT] = { NULL, NULL, NULL, NULL };
    GhosttyResult res;
    int i, slot;
  CODE:
    if (items % 2 == 0)
        croak("Term::Ghostty->new: odd number of option arguments");
    for (i = 1; i < items; i += 2) {
        const char *key = SvPV_nolen(sv_mortalcopy(ST(i)));
        SV *val = ST(i + 1);
        if (strEQ(key, "cols"))
            cols = cell_count(aTHX_ val, "cols");
        else if (strEQ(key, "rows"))
            rows = cell_count(aTHX_ val, "rows");
        else if (strEQ(key, "cell_width_px"))
            cell_w = pixel_size(aTHX_ val, "cell_width_px");
        else if (strEQ(key, "cell_height_px"))
            cell_h = pixel_size(aTHX_ val, "cell_height_px");
        else if (strEQ(key, "max_scrollback")) {
            SV *copy = sv_mortalcopy(val);
            scrollback_sv = NULL;
            if (SvOK(copy)) {
                NV n = SvNV(copy);
                if (!(n >= 0 && n <= 4294967295.0))
                    croak("Term::Ghostty: max_scrollback must be between 0 and 4294967295");
                scrollback = (size_t)n;
                scrollback_sv = copy;
            }
        }
        else if (strEQ(key, "title"))
            title_sv = val;
        else if (strEQ(key, "pwd"))
            pwd_sv = val;
        else {
            for (slot = 0; slot < CB_COUNT; slot++)
                if (strEQ(key, cb_names[slot]))
                    break;
            if (slot == CB_COUNT)
                croak("Term::Ghostty->new: unknown option '%s'", key);
            cbs[slot] = callback_arg(aTHX_ val, cb_names[slot]);
        }
    }
    title = text_arg(aTHX_ title_sv);
    pwd = text_arg(aTHX_ pwd_sv);

    stash = SvROK(klass) && SvOBJECT(SvRV(klass))
        ? SvSTASH(SvRV(klass)) : gv_stashsv(klass, GV_ADD);

    Newxz(self, 1, PerlGhostty);
    self->cell_width = cell_w;
    self->cell_height = cell_h;
    res = ghostty_terminal_new(NULL, &self->terminal, cols, rows);
    if (res == GHOSTTY_SUCCESS && (cell_w || cell_h))
        res = ghostty_terminal_resize(self->terminal, cols, rows, cell_w, cell_h);
    if (res != GHOSTTY_SUCCESS) {
        release(aTHX_ self);
        croak("Term::Ghostty->new: cannot create a %ux%u terminal (error %d)",
              (unsigned)cols, (unsigned)rows, (int)res);
    }

    self->self = newSV(0);
    sv_magicext(self->self, NULL, PERL_MAGIC_ext, &ghostty_vtbl, (const char *)self, 0)
        ->mg_flags |= MGf_DUP;
    RETVAL = sv_bless(newRV_noinc(self->self), stash);

    ghostty_terminal_set(self->terminal, GHOSTTY_TERMINAL_OPT_USERDATA, self);
    ghostty_terminal_set(self->terminal, GHOSTTY_TERMINAL_OPT_DEVICE_ATTRIBUTES,
                         (const void *)cb_device_attributes);
    ghostty_terminal_set(self->terminal, GHOSTTY_TERMINAL_OPT_SIZE, (const void *)cb_size);
    if (scrollback_sv) {
        ghostty_terminal_set(self->terminal, GHOSTTY_TERMINAL_OPT_SCROLLBACK_MAX_BYTES,
                             scrollback ? NULL : &scrollback);
        ghostty_terminal_set(self->terminal, GHOSTTY_TERMINAL_OPT_SCROLLBACK_MAX_LINES, &scrollback);
    }
    for (slot = 0; slot < CB_COUNT; slot++)
        if (cbs[slot])
            set_callback(aTHX_ self, slot, cbs[slot]);
    set_text_option(self->terminal, GHOSTTY_TERMINAL_OPT_TITLE, title);
    set_text_option(self->terminal, GHOSTTY_TERMINAL_OPT_PWD, pwd);
  OUTPUT:
    RETVAL

void
DESTROY(self_sv)
    SV *self_sv
  PREINIT:
    MAGIC *mg;
    PerlGhostty *self;
  CODE:
    mg = ghostty_magic(aTHX_ self_sv);
    if (!mg || !mg->mg_ptr)
        XSRETURN_EMPTY;
    self = (PerlGhostty *)mg->mg_ptr;
    if (self->busy) {
        self->destroy_pending = true;
        XSRETURN_EMPTY;
    }
    mg->mg_ptr = NULL;
    release(aTHX_ self);

void
write(self_sv, data_sv)
    SV *self_sv
    SV *data_sv
  ALIAS:
    feed = 1
  PREINIT:
    PerlGhostty *self;
    STRLEN len;
    const char *data;
  CODE:
    self = get_input(aTHX_ self_sv, data_sv, ix ? "feed" : "write", &data, &len);
    guard_enter(aTHX_ self, ix ? "feed" : "write");
    ghostty_terminal_vt_write(self->terminal, (const uint8_t *)data, len);
    guard_leave(aTHX_ self);

void
write_until_ground(self_sv, data_sv)
    SV *self_sv
    SV *data_sv
  PREINIT:
    PerlGhostty *self;
    STRLEN len;
    const char *data;
    size_t consumed = 0;
    GhosttyResult res;
  PPCODE:
    self = get_input(aTHX_ self_sv, data_sv, "write_until_ground", &data, &len);
    guard_enter(aTHX_ self, "write_until_ground");
    res = ghostty_terminal_vt_write_until_ground(self->terminal, (const uint8_t *)data, len, &consumed);
    guard_leave(aTHX_ self);
    SP = PL_stack_base + ax - 1;
    EXTEND(SP, 2);
    mPUSHu(consumed);
    if (GIMME_V == G_LIST)
        PUSHs(boolSV(res == GHOSTTY_SUCCESS));

void
resize(self_sv, cols_sv, rows_sv, cell_w_sv = NULL, cell_h_sv = NULL)
    SV *self_sv
    SV *cols_sv
    SV *rows_sv
    SV *cell_w_sv
    SV *cell_h_sv
  PREINIT:
    PerlGhostty *self;
    uint16_t cols, rows;
    uint32_t cell_w, cell_h;
    GhosttyResult res;
  CODE:
    if (cell_w_sv)
        cell_w_sv = sv_mortalcopy(cell_w_sv);
    if (cell_h_sv)
        cell_h_sv = sv_mortalcopy(cell_h_sv);
    cols = cell_count(aTHX_ cols_sv, "cols");
    rows = cell_count(aTHX_ rows_sv, "rows");
    cell_w = cell_w_sv && SvOK(cell_w_sv) ? pixel_size(aTHX_ cell_w_sv, "cell_width_px") : 0;
    cell_h = cell_h_sv && SvOK(cell_h_sv) ? pixel_size(aTHX_ cell_h_sv, "cell_height_px") : 0;
    self = get_ghostty(aTHX_ self_sv, "resize");
    if (!(cell_w_sv && SvOK(cell_w_sv)))
        cell_w = self->cell_width;
    if (!(cell_h_sv && SvOK(cell_h_sv)))
        cell_h = self->cell_height;
    guard_enter(aTHX_ self, "resize");
    res = ghostty_terminal_resize(self->terminal, cols, rows, cell_w, cell_h);
    if (res == GHOSTTY_SUCCESS) {
        self->cell_width = cell_w;
        self->cell_height = cell_h;
    }
    guard_leave(aTHX_ self);
    if (res != GHOSTTY_SUCCESS)
        croak("Term::Ghostty::resize: cannot resize to %ux%u (error %d)",
              (unsigned)cols, (unsigned)rows, (int)res);

void
reset(self_sv)
    SV *self_sv
  PREINIT:
    PerlGhostty *self;
  CODE:
    self = get_ghostty(aTHX_ self_sv, "reset");
    guard_enter(aTHX_ self, "reset");
    ghostty_terminal_reset(self->terminal);
    guard_leave(aTHX_ self);

void
set_title(self_sv, value)
    SV *self_sv
    SV *value
  ALIAS:
    set_pwd = 1
  PREINIT:
    PerlGhostty *self;
    const char *name;
    TextArg text;
  CODE:
    name = ix ? "set_pwd" : "set_title";
    text = text_arg(aTHX_ value);
    self = get_ghostty(aTHX_ self_sv, name);
    guard_enter(aTHX_ self, name);
    set_text_option(self->terminal, ix ? GHOSTTY_TERMINAL_OPT_PWD : GHOSTTY_TERMINAL_OPT_TITLE, text);
    guard_leave(aTHX_ self);

SV *
title(self_sv)
    SV *self_sv
  ALIAS:
    pwd = 1
  PREINIT:
    PerlGhostty *self;
  CODE:
    self = get_ghostty(aTHX_ self_sv, ix ? "pwd" : "title");
    RETVAL = terminal_text(aTHX_ self->terminal, ix ? GHOSTTY_TERMINAL_DATA_PWD : GHOSTTY_TERMINAL_DATA_TITLE);
  OUTPUT:
    RETVAL

SV *
format(self_sv, ...)
    SV *self_sv
  PREINIT:
    PerlGhostty *self;
    GhosttyFormatter formatter = NULL;
    GhosttyFormatterTerminalOptions opts;
    GhosttySelection screen;
    GhosttyPoint corner;
    GhosttyResult res;
    uint8_t *buf = NULL;
    size_t len = 0;
    uint16_t cols = 0, rows = 0;
    bool scrollback = false;
    int palette = -1;
    int i;
  CODE:
    if (items % 2 == 0)
        croak("Term::Ghostty::format: odd number of option arguments");
    Zero(&opts, 1, GhosttyFormatterTerminalOptions);
    opts.size = sizeof(opts);
    opts.extra.size = sizeof(opts.extra);
    opts.extra.screen.size = sizeof(opts.extra.screen);
    opts.emit = GHOSTTY_FORMATTER_FORMAT_PLAIN;
    opts.trim = true;
    for (i = 1; i < items; i += 2) {
        const char *key = SvPV_nolen(sv_mortalcopy(ST(i)));
        SV *val = ST(i + 1);
        bool on = SvTRUE(val);
        if (strEQ(key, "format")) {
            const char *f = SvPV_nolen(val);
            if (strEQ(f, "plain"))
                opts.emit = GHOSTTY_FORMATTER_FORMAT_PLAIN;
            else if (strEQ(f, "vt"))
                opts.emit = GHOSTTY_FORMATTER_FORMAT_VT;
            else if (strEQ(f, "html"))
                opts.emit = GHOSTTY_FORMATTER_FORMAT_HTML;
            else
                croak("Term::Ghostty::format: format must be 'plain', 'vt' or 'html', not '%s'", f);
        }
        else if (strEQ(key, "scrollback"))       scrollback = on;
        else if (strEQ(key, "trim"))             opts.trim = on;
        else if (strEQ(key, "unwrap"))           opts.unwrap = on;
        else if (strEQ(key, "palette"))          palette = on;
        else if (strEQ(key, "modes"))            opts.extra.modes = on;
        else if (strEQ(key, "scrolling_region")) opts.extra.scrolling_region = on;
        else if (strEQ(key, "tabstops"))         opts.extra.tabstops = on;
        else if (strEQ(key, "pwd"))              opts.extra.pwd = on;
        else if (strEQ(key, "keyboard"))         opts.extra.keyboard = on;
        else if (strEQ(key, "cursor"))           opts.extra.screen.cursor = on;
        else if (strEQ(key, "style"))            opts.extra.screen.style = on;
        else if (strEQ(key, "hyperlink"))        opts.extra.screen.hyperlink = on;
        else if (strEQ(key, "protection"))       opts.extra.screen.protection = on;
        else if (strEQ(key, "kitty_keyboard"))   opts.extra.screen.kitty_keyboard = on;
        else if (strEQ(key, "charsets"))         opts.extra.screen.charsets = on;
        else
            croak("Term::Ghostty::format: unknown option '%s'", key);
    }
    opts.extra.palette = palette < 0 ? opts.emit == GHOSTTY_FORMATTER_FORMAT_HTML : palette;

    self = get_ghostty(aTHX_ self_sv, "format");
    if (!scrollback) {
        Zero(&screen, 1, GhosttySelection);
        screen.size = sizeof(screen);
        screen.start.size = sizeof(screen.start);
        screen.end.size = sizeof(screen.end);
        ghostty_terminal_get(self->terminal, GHOSTTY_TERMINAL_DATA_COLS, &cols);
        ghostty_terminal_get(self->terminal, GHOSTTY_TERMINAL_DATA_ROWS, &rows);
        Zero(&corner, 1, GhosttyPoint);
        corner.tag = GHOSTTY_POINT_TAG_ACTIVE;
        if (ghostty_terminal_grid_ref(self->terminal, corner, &screen.start) != GHOSTTY_SUCCESS)
            croak("Term::Ghostty::format: cannot locate the screen origin");
        corner.value.coordinate.x = cols - 1;
        corner.value.coordinate.y = rows - 1;
        if (ghostty_terminal_grid_ref(self->terminal, corner, &screen.end) != GHOSTTY_SUCCESS)
            croak("Term::Ghostty::format: cannot locate the screen corner");
        opts.selection = &screen;
    }

    res = ghostty_formatter_terminal_new(NULL, &formatter, self->terminal, opts);
    if (res != GHOSTTY_SUCCESS)
        croak("Term::Ghostty::format: cannot create formatter (error %d)", (int)res);
    res = ghostty_formatter_format_alloc(formatter, NULL, &buf, &len);
    ghostty_formatter_free(formatter);
    if (res != GHOSTTY_SUCCESS)
        croak("Term::Ghostty::format: formatting failed (error %d)", (int)res);
    RETVAL = new_text_sv(aTHX_ buf, len);
    ghostty_free(NULL, buf, len);
    if (opts.emit == GHOSTTY_FORMATTER_FORMAT_HTML)
        filter_links(RETVAL);
  OUTPUT:
    RETVAL

UV
cols(self_sv)
    SV *self_sv
  ALIAS:
    rows = 1
    cursor_x = 2
    cursor_y = 3
  PREINIT:
    PerlGhostty *self;
    static const char *const names[] = { "cols", "rows", "cursor_x", "cursor_y" };
    static const GhosttyTerminalData data[] = {
        GHOSTTY_TERMINAL_DATA_COLS, GHOSTTY_TERMINAL_DATA_ROWS,
        GHOSTTY_TERMINAL_DATA_CURSOR_X, GHOSTTY_TERMINAL_DATA_CURSOR_Y,
    };
    uint16_t value = 0;
  CODE:
    self = get_ghostty(aTHX_ self_sv, names[ix]);
    ghostty_terminal_get(self->terminal, data[ix], &value);
    RETVAL = value;
  OUTPUT:
    RETVAL

void
cursor_pos(self_sv)
    SV *self_sv
  PREINIT:
    PerlGhostty *self;
    uint16_t cx = 0, cy = 0;
  PPCODE:
    self = get_ghostty(aTHX_ self_sv, "cursor_pos");
    ghostty_terminal_get(self->terminal, GHOSTTY_TERMINAL_DATA_CURSOR_X, &cx);
    ghostty_terminal_get(self->terminal, GHOSTTY_TERMINAL_DATA_CURSOR_Y, &cy);
    if (GIMME_V == G_LIST) {
        EXTEND(SP, 2);
        mPUSHu(cx);
        mPUSHu(cy);
    } else {
        AV *av = newAV();
        av_push(av, newSVuv(cx));
        av_push(av, newSVuv(cy));
        mXPUSHs(newRV_noinc((SV *)av));
    }

bool
cursor_visible(self_sv)
    SV *self_sv
  ALIAS:
    cursor_pending_wrap = 1
    mouse_tracking = 2
  PREINIT:
    PerlGhostty *self;
    static const char *const names[] = { "cursor_visible", "cursor_pending_wrap", "mouse_tracking" };
    static const GhosttyTerminalData data[] = {
        GHOSTTY_TERMINAL_DATA_CURSOR_VISIBLE, GHOSTTY_TERMINAL_DATA_CURSOR_PENDING_WRAP,
        GHOSTTY_TERMINAL_DATA_MOUSE_TRACKING,
    };
    bool value = false;
  CODE:
    self = get_ghostty(aTHX_ self_sv, names[ix]);
    ghostty_terminal_get(self->terminal, data[ix], &value);
    RETVAL = value;
  OUTPUT:
    RETVAL

UV
scrollback_rows(self_sv)
    SV *self_sv
  PREINIT:
    PerlGhostty *self;
    size_t value = 0;
  CODE:
    self = get_ghostty(aTHX_ self_sv, "scrollback_rows");
    ghostty_terminal_get(self->terminal, GHOSTTY_TERMINAL_DATA_SCROLLBACK_ROWS, &value);
    RETVAL = value;
  OUTPUT:
    RETVAL

const char *
active_screen(self_sv)
    SV *self_sv
  PREINIT:
    PerlGhostty *self;
    GhosttyTerminalScreen screen = GHOSTTY_TERMINAL_SCREEN_PRIMARY;
  CODE:
    self = get_ghostty(aTHX_ self_sv, "active_screen");
    ghostty_terminal_get(self->terminal, GHOSTTY_TERMINAL_DATA_ACTIVE_SCREEN, &screen);
    RETVAL = screen == GHOSTTY_TERMINAL_SCREEN_ALTERNATE ? "alternate" : "primary";
  OUTPUT:
    RETVAL

SV *
mode(self_sv, number, ansi = false)
    SV *self_sv
    IV number
    bool ansi
  PREINIT:
    PerlGhostty *self;
    GhosttyTerminalModeConfig cfg;
  CODE:
    self = get_ghostty(aTHX_ self_sv, "mode");
    if (number < 0 || number > 32767)
        croak("Term::Ghostty::mode: mode must be between 0 and 32767");
    cfg.mode = ghostty_mode_new((uint16_t)number, ansi);
    cfg.value = false;
    RETVAL = ghostty_terminal_get(self->terminal, GHOSTTY_TERMINAL_DATA_MODE, &cfg) == GHOSTTY_SUCCESS
        ? boolSV(cfg.value) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
on_pty_write(self_sv, ...)
    SV *self_sv
  ALIAS:
    on_title_changed = CB_TITLE_CHANGED
    on_bell = CB_BELL
    on_pwd_changed = CB_PWD_CHANGED
  PREINIT:
    PerlGhostty *self;
    SV *cb;
  CODE:
    if (items > 2)
        croak("Usage: $term->%s([$callback])", cb_names[ix]);
    cb = items == 2 ? callback_arg(aTHX_ ST(1), cb_names[ix]) : NULL;
    self = get_ghostty(aTHX_ self_sv, cb_names[ix]);
    RETVAL = self->cb[ix] ? newSVsv(self->cb[ix]) : &PL_sv_undef;
    if (items == 2)
        set_callback(aTHX_ self, ix, cb);
  OUTPUT:
    RETVAL

SV *
lib_version(...)
  PREINIT:
    GhosttyString v = { NULL, 0 };
  CODE:
    PERL_UNUSED_VAR(items);
    ghostty_build_info(GHOSTTY_BUILD_INFO_VERSION_STRING, &v);
    RETVAL = newSVpvn(v.len ? (const char *)v.ptr : "", v.len);
  OUTPUT:
    RETVAL
