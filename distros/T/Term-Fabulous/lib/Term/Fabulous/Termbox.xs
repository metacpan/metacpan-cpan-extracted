/*
 * Termbox.xs - the XS surface of Term::Fabulous::Termbox.
 *
 * A thin layer over termbox2 (compiled in src/termbox2.c): every function
 * keeps its C name and status code. Characters cross the boundary as Perl
 * strings, which this file decodes into codepoints; events come back as a
 * list the Perl side copies into a Term::Fabulous::Termbox::Event.
 */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "tf_termbox.h"

/*
 * The UTF-8 bytes of a string, or a croak when the string carries the UTF8
 * flag over bytes that are not well-formed UTF-8 (Encode::_utf8_on, a
 * ":utf8" read layer). Decoding such bytes would let the codepoint count and
 * the bytes consumed disagree.
 */
static const U8 *well_formed_utf8(pTHX_ SV *text, const char *function, STRLEN *length) {
	const U8 *bytes = (const U8 *)SvPVutf8(text, *length);

	if (!is_utf8_string(bytes, *length)) croak("Term::Fabulous::Termbox: %s needs well-formed UTF-8", function);
	return bytes;
}

/*
 * True when the decoder consumed no bytes: 0, or (STRLEN)-1 for a
 * malformation with utf8 warnings enabled. A decode loop that went on would
 * stall or walk backwards.
 */
static bool decoder_stalled(STRLEN consumed) {
	return consumed == 0 || consumed == (STRLEN)-1;
}

/*
 * The first codepoint of a one-character string. An integer that was
 * never a string is taken as the codepoint itself, so the C form of the
 * call stays reachable.
 */
static uint32_t first_codepoint(pTHX_ SV *glyph, const char *function) {
	STRLEN length;
	STRLEN consumed;
	const U8 *bytes;
	uint32_t codepoint;

	if (SvIOK(glyph) && !SvPOK(glyph)) return (uint32_t)SvUV(glyph);

	bytes = well_formed_utf8(aTHX_ glyph, function, &length);
	if (length == 0) croak("Term::Fabulous::Termbox: %s needs a non-empty character", function);
	codepoint = (uint32_t)utf8_to_uvchr_buf(bytes, bytes + length, &consumed);
	if (decoder_stalled(consumed)) croak("Term::Fabulous::Termbox: %s needs well-formed UTF-8", function);
	return codepoint;
}

/*
 * Every codepoint of a string, in an array the caller releases with
 * Safefree. Returns the number of codepoints. The array has room for one
 * codepoint per byte, an upper bound the loop cannot pass because every
 * step consumes at least one byte.
 */
static size_t decode_codepoints(pTHX_ SV *text, const char *function, uint32_t **codepoints) {
	STRLEN length;
	const U8 *bytes = well_formed_utf8(aTHX_ text, function, &length);
	const U8 *end   = bytes + length;
	size_t count    = 0;

	if (length == 0) croak("Term::Fabulous::Termbox: %s needs a non-empty string", function);

	Newx(*codepoints, length, uint32_t);
	while (bytes < end) {
		STRLEN consumed;
		(*codepoints)[count++] = (uint32_t)utf8_to_uvchr_buf(bytes, end, &consumed);
		if (decoder_stalled(consumed)) {
			Safefree(*codepoints);
			croak("Term::Fabulous::Termbox: %s needs well-formed UTF-8", function);
		}
		bytes += consumed;
	}
	return count;
}

/* The text of a cell: its grapheme cluster when it has one, else its codepoint. */
static SV *cell_text(pTHX_ const struct tb_cell *cell) {
	const uint32_t *codepoints = cell->nech > 0 ? cell->ech : &cell->ch;
	size_t count               = cell->nech > 0 ? cell->nech : 1;
	SV *text                   = newSVpvs("");
	U8 buffer[UTF8_MAXBYTES + 1];
	size_t i;

	SvUTF8_on(text);
	for (i = 0; i < count; i++) {
		U8 *end = uvchr_to_utf8(buffer, codepoints[i]);
		sv_catpvn(text, (const char *)buffer, end - buffer);
	}
	return text;
}

static void scalar_ref_or_croak(pTHX_ SV *ref, const char *function, const char *what) {
	if (SvROK(ref) && SvTYPE(SvRV(ref)) < SVt_PVAV) return;
	croak("Term::Fabulous::Termbox: %s needs a scalar reference for the %s", function, what);
}

/* Installs a constant sub and records its name under an export tag. */
static void export_constant(pTHX_ HV *stash, HV *tags, const char *tag, const char *name, SV *value) {
	SV **members = hv_fetch(tags, tag, (I32)strlen(tag), 1);
	if (!SvROK(*members)) sv_setsv(*members, sv_2mortal(newRV_noinc((SV *)newAV())));
	newCONSTSUB(stash, name, value);
	av_push((AV *)SvRV(*members), newSVpv(name, 0));
}

/* (status, name => value, ...) for one filled struct tb_event. */
#define PUSH_EVENT_FIELD(field) STMT_START { \
	mPUSHp(#field, sizeof(#field) - 1);      \
	mPUSHi(event.field);                     \
} STMT_END

#define PUSH_EVENT(status)         \
	STMT_START {                   \
		EXTEND(SP, 17);            \
		mPUSHi(status);            \
		if ((status) == TB_OK) {   \
			PUSH_EVENT_FIELD(type); \
			PUSH_EVENT_FIELD(mod);  \
			PUSH_EVENT_FIELD(key);  \
			PUSH_EVENT_FIELD(ch);   \
			PUSH_EVENT_FIELD(w);    \
			PUSH_EVENT_FIELD(h);    \
			PUSH_EVENT_FIELD(x);    \
			PUSH_EVENT_FIELD(y);    \
		}                          \
	} STMT_END

MODULE = Term::Fabulous::Termbox    PACKAGE = Term::Fabulous::Termbox

PROTOTYPES: DISABLE

# --- Lifecycle --------------------------------------------------------

int
tb_init()

int
tb_init_file(const char *path)

int
tb_init_fd(int ttyfd)

int
tb_init_rwfd(int rfd, int wfd)

int
tb_shutdown()

int
tb_width()

int
tb_height()

int
tf_init_inline()

int
tf_init_inline_rwfd(int rfd, int wfd)

int
tb_set_input_mode(int mode)

int
tb_set_output_mode(int mode)

# --- Drawing ----------------------------------------------------------

int
tb_clear()

int
tb_set_clear_attrs(uintattr_t fg, uintattr_t bg)

int
tb_present()

int
tb_invalidate()

int
tb_set_cursor(int cx, int cy)

int
tb_hide_cursor()

int
tb_set_cell(int x, int y, SV *glyph, uintattr_t fg, uintattr_t bg)
	CODE:
		RETVAL = tb_set_cell(x, y, first_codepoint(aTHX_ glyph, "tb_set_cell"), fg, bg);
	OUTPUT:
		RETVAL

int
tb_set_cell_ex(int x, int y, SV *cluster, uintattr_t fg, uintattr_t bg)
	PREINIT:
		uint32_t *codepoints;
		size_t count;
	CODE:
		count  = decode_codepoints(aTHX_ cluster, "tb_set_cell_ex", &codepoints);
		RETVAL = tb_set_cell_ex(x, y, codepoints, count, fg, bg);
		Safefree(codepoints);
	OUTPUT:
		RETVAL

int
tb_extend_cell(int x, int y, SV *glyph)
	CODE:
		RETVAL = tb_extend_cell(x, y, first_codepoint(aTHX_ glyph, "tb_extend_cell"));
	OUTPUT:
		RETVAL

void
tb_get_cell(int x, int y, int back)
	PREINIT:
		struct tb_cell *cell;
		int status;
	PPCODE:
		status = tb_get_cell(x, y, back, &cell);
		EXTEND(SP, 4);
		mPUSHi(status);
		if (status == TB_OK) {
			mPUSHs(cell_text(aTHX_ cell));
			mPUSHu(cell->fg);
			mPUSHu(cell->bg);
		}

int
tb_print(int x, int y, uintattr_t fg, uintattr_t bg, SV *text)
	CODE:
		RETVAL = tb_print(x, y, fg, bg, SvPVutf8_nolen(text));
	OUTPUT:
		RETVAL

int
tf_reset_attrs()

int
tf_flush()

int
tf_cells_differ(int x, int y, int width, int height, SV *differ_ref)
	PREINIT:
		int differ = 0;
	CODE:
		scalar_ref_or_croak(aTHX_ differ_ref, "tf_cells_differ", "answer");
		RETVAL = tf_cells_differ(x, y, width, height, &differ);
		if (RETVAL == TB_OK) sv_setiv(SvRV(differ_ref), differ);
	OUTPUT:
		RETVAL

int
tf_invalidate_cells(int x, int y, int width, int height)

int
tb_send(SV *bytes)
	PREINIT:
		STRLEN length;
		const char *buffer;
		SV *copy;
	CODE:
		/* Bytes go out as they are; only a string with a character above
		 * 0xFF has no byte form and is sent UTF-8 encoded. */
		copy = sv_mortalcopy(bytes);
		if (!sv_utf8_downgrade(copy, TRUE)) sv_utf8_encode(copy);
		buffer = SvPV(copy, length);
		RETVAL = tb_send(buffer, length);
	OUTPUT:
		RETVAL

# --- Events -----------------------------------------------------------

void
_peek_event(int timeout_ms)
	PREINIT:
		struct tb_event event;
		int status;
	PPCODE:
		Zero(&event, 1, struct tb_event);
		status = tb_peek_event(&event, timeout_ms);
		PUSH_EVENT(status);

void
_poll_event()
	PREINIT:
		struct tb_event event;
		int status;
	PPCODE:
		Zero(&event, 1, struct tb_event);
		status = tb_poll_event(&event);
		PUSH_EVENT(status);

int
tf_install_input_parser()

int
tf_cursor_position(int timeout_ms, SV *x_ref, SV *y_ref)
	PREINIT:
		int x = 0;
		int y = 0;
	CODE:
		scalar_ref_or_croak(aTHX_ x_ref, "tf_cursor_position", "column");
		scalar_ref_or_croak(aTHX_ y_ref, "tf_cursor_position", "row");
		RETVAL = tf_cursor_position(timeout_ms, &x, &y);
		if (RETVAL == TB_OK) {
			sv_setiv(SvRV(x_ref), x);
			sv_setiv(SvRV(y_ref), y);
		}
	OUTPUT:
		RETVAL

int
tf_kitty_keyboard_query(int timeout_ms, SV *supported_ref)
	PREINIT:
		int supported = 0;
	CODE:
		scalar_ref_or_croak(aTHX_ supported_ref, "tf_kitty_keyboard_query", "answer");
		RETVAL = tf_kitty_keyboard_query(timeout_ms, &supported);
		if (RETVAL == TB_OK) sv_setiv(SvRV(supported_ref), supported);
	OUTPUT:
		RETVAL

int
tf_sixel_query(int timeout_ms, SV *supported_ref, SV *cell_width_ref, SV *cell_height_ref)
	PREINIT:
		int supported   = 0;
		int cell_width  = 0;
		int cell_height = 0;
	CODE:
		scalar_ref_or_croak(aTHX_ supported_ref, "tf_sixel_query", "answer");
		scalar_ref_or_croak(aTHX_ cell_width_ref, "tf_sixel_query", "cell width");
		scalar_ref_or_croak(aTHX_ cell_height_ref, "tf_sixel_query", "cell height");
		RETVAL = tf_sixel_query(timeout_ms, &supported, &cell_width, &cell_height);
		if (RETVAL == TB_OK) {
			sv_setiv(SvRV(supported_ref), supported);
			sv_setiv(SvRV(cell_width_ref), cell_width);
			sv_setiv(SvRV(cell_height_ref), cell_height);
		}
	OUTPUT:
		RETVAL

int
tf_input_ended(int fd)

int
tb_get_fds(SV *tty_ref, SV *resize_ref)
	PREINIT:
		int ttyfd    = -1;
		int resizefd = -1;
	CODE:
		scalar_ref_or_croak(aTHX_ tty_ref, "tb_get_fds", "tty descriptor");
		scalar_ref_or_croak(aTHX_ resize_ref, "tb_get_fds", "resize descriptor");
		RETVAL = tb_get_fds(&ttyfd, &resizefd);
		sv_setiv(SvRV(tty_ref), ttyfd);
		sv_setiv(SvRV(resize_ref), resizefd);
	OUTPUT:
		RETVAL

# --- Widths -----------------------------------------------------------

int
tb_iswprint(uint32_t ch)

int
tb_wcwidth(uint32_t ch)

int
tb_cluster_width(SV *cluster)
	PREINIT:
		uint32_t *codepoints;
		size_t count;
	CODE:
		count  = decode_codepoints(aTHX_ cluster, "tb_cluster_width", &codepoints);
		RETVAL = tf_cluster_width(codepoints, count);
		Safefree(codepoints);
	OUTPUT:
		RETVAL

# --- Diagnostics ------------------------------------------------------

int
tb_last_errno()

const char *
tb_strerror(int err)

int
tb_has_truecolor()

int
tb_has_egc()

int
tb_attr_width()

const char *
tb_version()

BOOT:
{
	HV *stash = gv_stashpvs("Term::Fabulous::Termbox", GV_ADD);
	HV *tags  = get_hv("Term::Fabulous::Termbox::EXPORT_TAGS", GV_ADD);
#define EXPORT_IV(tag, name) export_constant(aTHX_ stash, tags, tag, #name, newSViv((IV)(name)))
#define EXPORT_UV(tag, name) export_constant(aTHX_ stash, tags, tag, #name, newSVuv((UV)(name)))
	/* Keys of the ASCII control range, with their aliases. */
	EXPORT_IV("keys", TB_KEY_CTRL_TILDE);
	EXPORT_IV("keys", TB_KEY_CTRL_2);
	EXPORT_IV("keys", TB_KEY_CTRL_A);
	EXPORT_IV("keys", TB_KEY_CTRL_B);
	EXPORT_IV("keys", TB_KEY_CTRL_C);
	EXPORT_IV("keys", TB_KEY_CTRL_D);
	EXPORT_IV("keys", TB_KEY_CTRL_E);
	EXPORT_IV("keys", TB_KEY_CTRL_F);
	EXPORT_IV("keys", TB_KEY_CTRL_G);
	EXPORT_IV("keys", TB_KEY_BACKSPACE);
	EXPORT_IV("keys", TB_KEY_CTRL_H);
	EXPORT_IV("keys", TB_KEY_TAB);
	EXPORT_IV("keys", TB_KEY_CTRL_I);
	EXPORT_IV("keys", TB_KEY_CTRL_J);
	EXPORT_IV("keys", TB_KEY_CTRL_K);
	EXPORT_IV("keys", TB_KEY_CTRL_L);
	EXPORT_IV("keys", TB_KEY_ENTER);
	EXPORT_IV("keys", TB_KEY_CTRL_M);
	EXPORT_IV("keys", TB_KEY_CTRL_N);
	EXPORT_IV("keys", TB_KEY_CTRL_O);
	EXPORT_IV("keys", TB_KEY_CTRL_P);
	EXPORT_IV("keys", TB_KEY_CTRL_Q);
	EXPORT_IV("keys", TB_KEY_CTRL_R);
	EXPORT_IV("keys", TB_KEY_CTRL_S);
	EXPORT_IV("keys", TB_KEY_CTRL_T);
	EXPORT_IV("keys", TB_KEY_CTRL_U);
	EXPORT_IV("keys", TB_KEY_CTRL_V);
	EXPORT_IV("keys", TB_KEY_CTRL_W);
	EXPORT_IV("keys", TB_KEY_CTRL_X);
	EXPORT_IV("keys", TB_KEY_CTRL_Y);
	EXPORT_IV("keys", TB_KEY_CTRL_Z);
	EXPORT_IV("keys", TB_KEY_ESC);
	EXPORT_IV("keys", TB_KEY_CTRL_LSQ_BRACKET);
	EXPORT_IV("keys", TB_KEY_CTRL_3);
	EXPORT_IV("keys", TB_KEY_CTRL_4);
	EXPORT_IV("keys", TB_KEY_CTRL_BACKSLASH);
	EXPORT_IV("keys", TB_KEY_CTRL_5);
	EXPORT_IV("keys", TB_KEY_CTRL_RSQ_BRACKET);
	EXPORT_IV("keys", TB_KEY_CTRL_6);
	EXPORT_IV("keys", TB_KEY_CTRL_7);
	EXPORT_IV("keys", TB_KEY_CTRL_SLASH);
	EXPORT_IV("keys", TB_KEY_CTRL_UNDERSCORE);
	EXPORT_IV("keys", TB_KEY_SPACE);
	EXPORT_IV("keys", TB_KEY_BACKSPACE2);
	EXPORT_IV("keys", TB_KEY_CTRL_8);
	/* Terminal-dependent keys. */
	EXPORT_IV("keys", TB_KEY_F1);
	EXPORT_IV("keys", TB_KEY_F2);
	EXPORT_IV("keys", TB_KEY_F3);
	EXPORT_IV("keys", TB_KEY_F4);
	EXPORT_IV("keys", TB_KEY_F5);
	EXPORT_IV("keys", TB_KEY_F6);
	EXPORT_IV("keys", TB_KEY_F7);
	EXPORT_IV("keys", TB_KEY_F8);
	EXPORT_IV("keys", TB_KEY_F9);
	EXPORT_IV("keys", TB_KEY_F10);
	EXPORT_IV("keys", TB_KEY_F11);
	EXPORT_IV("keys", TB_KEY_F12);
	EXPORT_IV("keys", TB_KEY_INSERT);
	EXPORT_IV("keys", TB_KEY_DELETE);
	EXPORT_IV("keys", TB_KEY_HOME);
	EXPORT_IV("keys", TB_KEY_END);
	EXPORT_IV("keys", TB_KEY_PGUP);
	EXPORT_IV("keys", TB_KEY_PGDN);
	EXPORT_IV("keys", TB_KEY_ARROW_UP);
	EXPORT_IV("keys", TB_KEY_ARROW_DOWN);
	EXPORT_IV("keys", TB_KEY_ARROW_LEFT);
	EXPORT_IV("keys", TB_KEY_ARROW_RIGHT);
	EXPORT_IV("keys", TB_KEY_BACK_TAB);
	EXPORT_IV("keys", TB_KEY_MOUSE_LEFT);
	EXPORT_IV("keys", TB_KEY_MOUSE_RIGHT);
	EXPORT_IV("keys", TB_KEY_MOUSE_MIDDLE);
	EXPORT_IV("keys", TB_KEY_MOUSE_RELEASE);
	EXPORT_IV("keys", TB_KEY_MOUSE_WHEEL_UP);
	EXPORT_IV("keys", TB_KEY_MOUSE_WHEEL_DOWN);
	/* Term::Fabulous additions, see tf_termbox.h. */
	EXPORT_IV("keys", TF_KEY_MOUSE_MOVE);
	EXPORT_IV("keys", TF_KEY_MOUSE_WHEEL_LEFT);
	EXPORT_IV("keys", TF_KEY_MOUSE_WHEEL_RIGHT);
	/* Keys only the kitty keyboard protocol reports, see tf_termbox.h. */
	EXPORT_IV("keys", TF_KEY_CAPS_LOCK);
	EXPORT_IV("keys", TF_KEY_SCROLL_LOCK);
	EXPORT_IV("keys", TF_KEY_NUM_LOCK);
	EXPORT_IV("keys", TF_KEY_PRINT_SCREEN);
	EXPORT_IV("keys", TF_KEY_PAUSE);
	EXPORT_IV("keys", TF_KEY_MENU);
	EXPORT_IV("keys", TF_KEY_F13);
	EXPORT_IV("keys", TF_KEY_F14);
	EXPORT_IV("keys", TF_KEY_F15);
	EXPORT_IV("keys", TF_KEY_F16);
	EXPORT_IV("keys", TF_KEY_F17);
	EXPORT_IV("keys", TF_KEY_F18);
	EXPORT_IV("keys", TF_KEY_F19);
	EXPORT_IV("keys", TF_KEY_F20);
	EXPORT_IV("keys", TF_KEY_F21);
	EXPORT_IV("keys", TF_KEY_F22);
	EXPORT_IV("keys", TF_KEY_F23);
	EXPORT_IV("keys", TF_KEY_F24);
	EXPORT_IV("keys", TF_KEY_F25);
	EXPORT_IV("keys", TF_KEY_F26);
	EXPORT_IV("keys", TF_KEY_F27);
	EXPORT_IV("keys", TF_KEY_F28);
	EXPORT_IV("keys", TF_KEY_F29);
	EXPORT_IV("keys", TF_KEY_F30);
	EXPORT_IV("keys", TF_KEY_F31);
	EXPORT_IV("keys", TF_KEY_F32);
	EXPORT_IV("keys", TF_KEY_F33);
	EXPORT_IV("keys", TF_KEY_F34);
	EXPORT_IV("keys", TF_KEY_F35);
	EXPORT_IV("keys", TF_KEY_KP_0);
	EXPORT_IV("keys", TF_KEY_KP_1);
	EXPORT_IV("keys", TF_KEY_KP_2);
	EXPORT_IV("keys", TF_KEY_KP_3);
	EXPORT_IV("keys", TF_KEY_KP_4);
	EXPORT_IV("keys", TF_KEY_KP_5);
	EXPORT_IV("keys", TF_KEY_KP_6);
	EXPORT_IV("keys", TF_KEY_KP_7);
	EXPORT_IV("keys", TF_KEY_KP_8);
	EXPORT_IV("keys", TF_KEY_KP_9);
	EXPORT_IV("keys", TF_KEY_KP_DECIMAL);
	EXPORT_IV("keys", TF_KEY_KP_DIVIDE);
	EXPORT_IV("keys", TF_KEY_KP_MULTIPLY);
	EXPORT_IV("keys", TF_KEY_KP_SUBTRACT);
	EXPORT_IV("keys", TF_KEY_KP_ADD);
	EXPORT_IV("keys", TF_KEY_KP_ENTER);
	EXPORT_IV("keys", TF_KEY_KP_EQUAL);
	EXPORT_IV("keys", TF_KEY_KP_SEPARATOR);
	EXPORT_IV("keys", TF_KEY_KP_LEFT);
	EXPORT_IV("keys", TF_KEY_KP_RIGHT);
	EXPORT_IV("keys", TF_KEY_KP_UP);
	EXPORT_IV("keys", TF_KEY_KP_DOWN);
	EXPORT_IV("keys", TF_KEY_KP_PAGE_UP);
	EXPORT_IV("keys", TF_KEY_KP_PAGE_DOWN);
	EXPORT_IV("keys", TF_KEY_KP_HOME);
	EXPORT_IV("keys", TF_KEY_KP_END);
	EXPORT_IV("keys", TF_KEY_KP_INSERT);
	EXPORT_IV("keys", TF_KEY_KP_DELETE);
	EXPORT_IV("keys", TF_KEY_KP_BEGIN);
	EXPORT_IV("keys", TF_KEY_MEDIA_PLAY);
	EXPORT_IV("keys", TF_KEY_MEDIA_PAUSE);
	EXPORT_IV("keys", TF_KEY_MEDIA_PLAY_PAUSE);
	EXPORT_IV("keys", TF_KEY_MEDIA_REVERSE);
	EXPORT_IV("keys", TF_KEY_MEDIA_STOP);
	EXPORT_IV("keys", TF_KEY_MEDIA_FAST_FORWARD);
	EXPORT_IV("keys", TF_KEY_MEDIA_REWIND);
	EXPORT_IV("keys", TF_KEY_MEDIA_TRACK_NEXT);
	EXPORT_IV("keys", TF_KEY_MEDIA_TRACK_PREVIOUS);
	EXPORT_IV("keys", TF_KEY_MEDIA_RECORD);
	EXPORT_IV("keys", TF_KEY_LOWER_VOLUME);
	EXPORT_IV("keys", TF_KEY_RAISE_VOLUME);
	EXPORT_IV("keys", TF_KEY_MUTE_VOLUME);
	/* Colors and style bits. */
	EXPORT_UV("colors", TB_DEFAULT);
	EXPORT_UV("colors", TB_BLACK);
	EXPORT_UV("colors", TB_RED);
	EXPORT_UV("colors", TB_GREEN);
	EXPORT_UV("colors", TB_YELLOW);
	EXPORT_UV("colors", TB_BLUE);
	EXPORT_UV("colors", TB_MAGENTA);
	EXPORT_UV("colors", TB_CYAN);
	EXPORT_UV("colors", TB_WHITE);
	EXPORT_UV("colors", TB_BOLD);
	EXPORT_UV("colors", TB_UNDERLINE);
	EXPORT_UV("colors", TB_REVERSE);
	EXPORT_UV("colors", TB_ITALIC);
	EXPORT_UV("colors", TB_BLINK);
	EXPORT_UV("colors", TB_HI_BLACK);
	EXPORT_UV("colors", TB_BRIGHT);
	EXPORT_UV("colors", TB_DIM);
	EXPORT_UV("colors", TB_STRIKEOUT);
	EXPORT_UV("colors", TB_UNDERLINE_2);
	EXPORT_UV("colors", TB_OVERLINE);
	EXPORT_UV("colors", TB_INVISIBLE);
	/* Deprecated upstream aliases, kept for code written against Termbox.pm. */
	EXPORT_UV("colors", TB_TRUECOLOR_BOLD);
	EXPORT_UV("colors", TB_TRUECOLOR_UNDERLINE);
	EXPORT_UV("colors", TB_TRUECOLOR_REVERSE);
	EXPORT_UV("colors", TB_TRUECOLOR_ITALIC);
	EXPORT_UV("colors", TB_TRUECOLOR_BLINK);
	EXPORT_UV("colors", TB_TRUECOLOR_BLACK);
	/* Event types, modifiers, input and output modes. */
	EXPORT_IV("event", TB_EVENT_KEY);
	EXPORT_IV("event", TB_EVENT_RESIZE);
	EXPORT_IV("event", TB_EVENT_MOUSE);
	EXPORT_IV("event", TB_MOD_ALT);
	EXPORT_IV("event", TB_MOD_CTRL);
	EXPORT_IV("event", TB_MOD_SHIFT);
	EXPORT_IV("event", TB_MOD_MOTION);
	EXPORT_IV("event", TF_MOD_SUPER);
	EXPORT_IV("event", TF_MOD_HYPER);
	EXPORT_IV("event", TF_MOD_META);
	EXPORT_IV("event", TB_INPUT_CURRENT);
	EXPORT_IV("event", TB_INPUT_ESC);
	EXPORT_IV("event", TB_INPUT_ALT);
	EXPORT_IV("event", TB_INPUT_MOUSE);
	EXPORT_IV("event", TB_OUTPUT_CURRENT);
	EXPORT_IV("event", TB_OUTPUT_NORMAL);
	EXPORT_IV("event", TB_OUTPUT_256);
	EXPORT_IV("event", TB_OUTPUT_216);
	EXPORT_IV("event", TB_OUTPUT_GRAYSCALE);
	EXPORT_IV("event", TB_OUTPUT_TRUECOLOR);
	/* Status codes. */
	EXPORT_IV("return", TB_OK);
	EXPORT_IV("return", TB_ERR);
	EXPORT_IV("return", TB_ERR_NEED_MORE);
	EXPORT_IV("return", TB_ERR_INIT_ALREADY);
	EXPORT_IV("return", TB_ERR_INIT_OPEN);
	EXPORT_IV("return", TB_ERR_MEM);
	EXPORT_IV("return", TB_ERR_NO_EVENT);
	EXPORT_IV("return", TB_ERR_NO_TERM);
	EXPORT_IV("return", TB_ERR_NOT_INIT);
	EXPORT_IV("return", TB_ERR_OUT_OF_BOUNDS);
	EXPORT_IV("return", TB_ERR_READ);
	EXPORT_IV("return", TB_ERR_RESIZE_IOCTL);
	EXPORT_IV("return", TB_ERR_RESIZE_PIPE);
	EXPORT_IV("return", TB_ERR_RESIZE_SIGACTION);
	EXPORT_IV("return", TB_ERR_POLL);
	EXPORT_IV("return", TB_ERR_TCGETATTR);
	EXPORT_IV("return", TB_ERR_TCSETATTR);
	EXPORT_IV("return", TB_ERR_UNSUPPORTED_TERM);
	EXPORT_IV("return", TB_ERR_RESIZE_WRITE);
	EXPORT_IV("return", TB_ERR_RESIZE_POLL);
	EXPORT_IV("return", TB_ERR_RESIZE_READ);
	EXPORT_IV("return", TB_ERR_RESIZE_SSCANF);
	EXPORT_IV("return", TB_ERR_CAP_COLLISION);
	EXPORT_IV("return", TB_ERR_SELECT);
	EXPORT_IV("return", TB_ERR_RESIZE_SELECT);
#undef EXPORT_IV
#undef EXPORT_UV
}
