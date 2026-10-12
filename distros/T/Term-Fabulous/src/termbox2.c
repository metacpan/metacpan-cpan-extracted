/*
 * termbox2.c - the single translation unit that compiles termbox2 in.
 *
 * perl.h stays out of this file on purpose: termbox2's implementation
 * defines feature-test macros and hundreds of static helpers that have
 * no business meeting Perl's macros.
 *
 * Besides the library this file holds the readers termbox2 lacks: Alt
 * keys, SGR mouse reports and the kitty keyboard protocol's key
 * reports. They run as termbox2's TB_FUNC_EXTRACT_PRE hook, before its
 * own parsers, and read the raw input buffer, which is static to this
 * translation unit. It also holds inline mode (tf_init_inline and its
 * helpers) and the terminal queries, which reach into termbox2's
 * internals the same way, and the end-of-input check of
 * tf_input_ended(). The operating system is reached only through the
 * platform layer at the end of termbox2.h (open_tty, init_fds,
 * wait_input, now_ms), except in tf_input_ended() and
 * tf_window_cell_size(), which ask it questions termbox2 never asks.
 */
#define TB_IMPL
#include "tf_termbox.h"

#ifdef __sun
#include <sys/filio.h> /* FIONREAD */
#endif

int tf_cluster_width(const uint32_t *codepoints, size_t count) {
	return tb_cluster_width((uint32_t *)codepoints, count);
}

/* Any larger coordinate or button number is not a mouse report. */
#define TF_MOUSE_NUMBER_LIMIT 65535

/*
 * ESC followed by one key, both in the buffer at once: Alt plus that key.
 * Alt+letter, Alt+Enter and Alt+umlaut arrive this way; ESC ESC, ESC [
 * and ESC O begin other sequences and are left to termbox2, which
 * then also delivers a lone ESC as the Escape key.
 */
static int tf_extract_alt_key(struct tb_event *event, size_t *consumed) {
	const unsigned char *buf = (const unsigned char *)global.in.buf;
	size_t len               = global.in.len;
	unsigned char key_byte;
	size_t key_len;

	if (len < 2) return TB_ERR;
	key_byte = buf[1];
	if (key_byte == 0x1b || key_byte == '[' || key_byte == 'O') return TB_ERR;
	if (key_byte >= 0x80 && key_byte < 0xc0) return TB_ERR; /* a stray UTF-8 continuation byte */

	key_len = key_byte < 0x80 ? 1 : (size_t)tb_utf8_char_length((char)key_byte);
	if (len < 1 + key_len) return TB_ERR_NEED_MORE;

	event->type = TB_EVENT_KEY;
	event->mod  = TB_MOD_ALT;
	if (key_byte < 0x20 || key_byte == 0x7f) {
		/* A control byte is its own key code, with Ctrl set, as termbox2 reports it. */
		event->key = key_byte;
		event->ch  = 0;
		event->mod |= TB_MOD_CTRL;
	} else {
		event->key = 0;
		tb_utf8_char_to_unicode(&event->ch, (const char *)buf + 1);
	}
	*consumed = 1 + key_len;
	return TB_OK;
}

/* The key code of an SGR button number, after its modifier and motion bits are masked off. */
static uint16_t tf_mouse_key(int button, int moving, int released) {
	int low = button & 3;

	if (button & 64) {
		if (low == 0) return TB_KEY_MOUSE_WHEEL_UP;
		if (low == 1) return TB_KEY_MOUSE_WHEEL_DOWN;
		if (low == 2) return TF_KEY_MOUSE_WHEEL_LEFT;
		return TF_KEY_MOUSE_WHEEL_RIGHT;
	}
	if (released) return TB_KEY_MOUSE_RELEASE;
	if (low == 0) return TB_KEY_MOUSE_LEFT;
	if (low == 1) return TB_KEY_MOUSE_MIDDLE;
	if (low == 2) return TB_KEY_MOUSE_RIGHT;
	return moving ? TF_KEY_MOUSE_MOVE : TB_KEY_MOUSE_RELEASE;
}

/* The press key of the button an SGR release ("m") names. Button number
 * 3 is the older "some button was released" form: 0, unknown. */
static uint32_t tf_released_button(int button) {
	int low = button & 3;

	if (button & 64) return 0;
	if (low == 0) return TB_KEY_MOUSE_LEFT;
	if (low == 1) return TB_KEY_MOUSE_MIDDLE;
	if (low == 2) return TB_KEY_MOUSE_RIGHT;
	return 0;
}

/*
 * An SGR mouse report: ESC [ < button ; column ; row M, or m for a
 * release. Bits 2, 3 and 4 of the button number are Shift, Alt and
 * Ctrl, bit 5 is motion, bit 6 marks the wheel (0 up, 1 down, 2 left,
 * 3 right); a button number of 3 with the motion bit is the pointer
 * moving with no button held. A release keeps the button it names in
 * the event's ch (see tf_released_button). Buttons 8 to 11 (bit 7) are left to
 * termbox2. Other encodings (X10, urxvt) are left to it as well.
 */
static int tf_extract_sgr_mouse(struct tb_event *event, size_t *consumed) {
	const char *buf = global.in.buf;
	size_t len      = global.in.len;
	int numbers[3]  = {-1, -1, -1};
	int count       = 0;
	char trail      = 0;
	size_t i;

	if (len < 3) return TB_ERR;
	if (buf[2] != '<') return TB_ERR;

	for (i = 3; i < len && trail == 0; i++) {
		char c = buf[i];
		if (c >= '0' && c <= '9') {
			if (numbers[count] < 0) numbers[count] = 0;
			numbers[count] = numbers[count] * 10 + (c - '0');
			if (numbers[count] > TF_MOUSE_NUMBER_LIMIT) return TB_ERR;
		} else if (c == ';' && count < 2 && numbers[count] >= 0) {
			count++;
		} else if ((c == 'M' || c == 'm') && count == 2 && numbers[2] >= 0) {
			trail = c;
		} else {
			return TB_ERR;
		}
	}
	if (trail == 0) return TB_ERR_NEED_MORE;
	if (numbers[0] & 128) return TB_ERR;

	event->type = TB_EVENT_MOUSE;
	event->key  = tf_mouse_key(numbers[0], numbers[0] & 32, trail == 'm');
	event->ch   = trail == 'm' ? tf_released_button(numbers[0]) : 0;
	event->mod  = 0;
	if (numbers[0] & 4) event->mod |= TB_MOD_SHIFT;
	if (numbers[0] & 8) event->mod |= TB_MOD_ALT;
	if (numbers[0] & 16) event->mod |= TB_MOD_CTRL;
	if (numbers[0] & 32) event->mod |= TB_MOD_MOTION;
	event->x = numbers[1] > 0 ? numbers[1] - 1 : 0;
	event->y = numbers[2] > 0 ? numbers[2] - 1 : 0;
	*consumed = i;
	return TB_OK;
}

/* Any larger number is not a key report: the largest Unicode codepoint. */
#define TF_KEY_NUMBER_LIMIT 0x10ffff

/* kitty's numbers for the keys of its functional key table that have
 * no legacy encoding, and the private use area they come from. */
#define TF_KITTY_CAPS_LOCK   57358
#define TF_KITTY_MENU        57363
#define TF_KITTY_F13         57376
#define TF_KITTY_MUTE_VOLUME 57440
#define TF_KITTY_KP_BEGIN    57427
#define TF_PRIVATE_USE_FIRST 0xe000
#define TF_PRIVATE_USE_LAST  0xf8ff

/*
 * The numbers of a CSI key report, ESC [ code:shifted ; modifiers ...
 * final, that matter here; -1 marks one that is absent. Further
 * sub-fields (base layout key, event type) and fields (text) are read
 * over and ignored.
 */
struct tf_csi_key {
	int code;
	int shifted;
	int modifiers;
	char final;
};

static void tf_store_csi_number(struct tf_csi_key *report, int field, int sub_field, int value) {
	if (field == 0 && sub_field == 0) report->code = value;
	if (field == 0 && sub_field == 1) report->shifted = value;
	if (field == 1 && sub_field == 0) report->modifiers = value;
}

/*
 * Reads ESC [ followed by decimal numbers, ':' and ';', up to its final
 * byte. Any other byte, such as the private markers '<', '?' and '>',
 * means it is not a key report.
 */
static int tf_parse_csi_key(struct tf_csi_key *report, size_t *length) {
	const char *buf = global.in.buf;
	size_t len      = global.in.len;
	int field       = 0;
	int sub_field   = 0;
	int value       = -1;
	size_t i;

	report->code      = -1;
	report->shifted   = -1;
	report->modifiers = -1;
	for (i = 2; i < len; i++) {
		char c = buf[i];
		if (c >= '0' && c <= '9') {
			value = (value < 0 ? 0 : value) * 10 + (c - '0');
			if (value > TF_KEY_NUMBER_LIMIT) return TB_ERR;
			continue;
		}
		tf_store_csi_number(report, field, sub_field, value);
		value = -1;
		if (c == ':') {
			sub_field++;
		} else if (c == ';') {
			if (++field > 2) return TB_ERR;
			sub_field = 0;
		} else if (c >= 0x40 && c <= 0x7e) {
			report->final = c;
			*length       = i + 1;
			return TB_OK;
		} else {
			return TB_ERR;
		}
	}
	return TB_ERR_NEED_MORE;
}

/* kitty sends 1 plus a bit field; the lock keys (Caps Lock, Num Lock) are dropped. */
static uint8_t tf_kitty_modifiers(int encoded) {
	int bits    = encoded > 0 ? encoded - 1 : 0;
	uint8_t mod = 0;

	if (bits & 1) mod |= TB_MOD_SHIFT;
	if (bits & 2) mod |= TB_MOD_ALT;
	if (bits & 4) mod |= TB_MOD_CTRL;
	if (bits & 8) mod |= TF_MOD_SUPER;
	if (bits & 16) mod |= TF_MOD_HYPER;
	if (bits & 32) mod |= TF_MOD_META;
	return mod;
}

static int tf_key_event(struct tb_event *event, uint16_t key, uint32_t ch, uint8_t mod) {
	event->type = TB_EVENT_KEY;
	event->key  = key;
	event->ch   = ch;
	event->mod  = mod;
	return TB_OK;
}

/* The TF_KEY_* code of a kitty functional key number, 0 for none. The
 * codes run in the order of the numbers (see tf_termbox.h). */
static uint16_t tf_kitty_functional_key(int code) {
	if (code >= TF_KITTY_CAPS_LOCK && code <= TF_KITTY_MENU) return (uint16_t)(TF_KEY_CAPS_LOCK - (code - TF_KITTY_CAPS_LOCK));
	if (code >= TF_KITTY_F13 && code <= TF_KITTY_MUTE_VOLUME) return (uint16_t)(TF_KEY_F13 - (code - TF_KITTY_F13));
	return 0;
}

/* The key of CSI number ~, 0 for a number that is not a key. */
static uint16_t tf_tilde_key(int number) {
	switch (number) {
		case 2: return TB_KEY_INSERT;
		case 3: return TB_KEY_DELETE;
		case 5: return TB_KEY_PGUP;
		case 6: return TB_KEY_PGDN;
		case 7: return TB_KEY_HOME;
		case 8: return TB_KEY_END;
		case 11: return TB_KEY_F1;
		case 12: return TB_KEY_F2;
		case 13: return TB_KEY_F3;
		case 14: return TB_KEY_F4;
		case 15: return TB_KEY_F5;
		case 17: return TB_KEY_F6;
		case 18: return TB_KEY_F7;
		case 19: return TB_KEY_F8;
		case 20: return TB_KEY_F9;
		case 21: return TB_KEY_F10;
		case 23: return TB_KEY_F11;
		case 24: return TB_KEY_F12;
		case TF_KITTY_KP_BEGIN: return TF_KEY_KP_BEGIN;
	}
	return 0;
}

/* The key of CSI 1 ; modifiers letter, 0 for a letter that is not a key.
 * F3 has no letter: CSI 1 ; modifiers R is also a cursor position report. */
static uint16_t tf_letter_key(char final) {
	switch (final) {
		case 'A': return TB_KEY_ARROW_UP;
		case 'B': return TB_KEY_ARROW_DOWN;
		case 'C': return TB_KEY_ARROW_RIGHT;
		case 'D': return TB_KEY_ARROW_LEFT;
		case 'E': return TF_KEY_KP_BEGIN;
		case 'F': return TB_KEY_END;
		case 'H': return TB_KEY_HOME;
		case 'P': return TB_KEY_F1;
		case 'Q': return TB_KEY_F2;
		case 'S': return TB_KEY_F4;
	}
	return 0;
}

/*
 * The legacy forms of the function keys, CSI number ; modifiers ~ and
 * CSI 1 ; modifiers letter, when they carry modifiers: kitty adds Super,
 * Hyper, Meta and the lock keys to the modifiers termbox2 knows. The
 * unmodified forms are left to termbox2, which knows them from
 * terminfo, except for the keypad's Begin key, which it has no code for.
 */
static int tf_function_key_event(const struct tf_csi_key *report, struct tb_event *event) {
	uint16_t key = report->final == '~' ? tf_tilde_key(report->code) : tf_letter_key(report->final);

	if (key == 0) return TB_ERR;
	if (report->final != '~' && report->code > 1) return TB_ERR;
	if (report->modifiers < 0 && key != TF_KEY_KP_BEGIN) return TB_ERR;
	return tf_key_event(event, key, 0, tf_kitty_modifiers(report->modifiers));
}

/*
 * Escape, Enter, Tab, Backspace and the other control codes. Without
 * Ctrl they come as termbox2 reports their bytes: the byte as the key,
 * with TB_MOD_CTRL on all but Escape, and Shift+Tab as TB_KEY_BACK_TAB.
 * With Ctrl, which their bytes cannot carry, ch holds the byte instead
 * and mod is exact.
 */
static int tf_kitty_control_key(struct tb_event *event, int code, uint8_t mod) {
	if (mod & TB_MOD_CTRL) return tf_key_event(event, 0, (uint32_t)code, mod);
	if (code == TB_KEY_TAB && mod == TB_MOD_SHIFT) return tf_key_event(event, TB_KEY_BACK_TAB, 0, 0);
	if (code == TB_KEY_ESC) return tf_key_event(event, TB_KEY_ESC, 0, mod);
	return tf_key_event(event, (uint16_t)code, 0, mod | TB_MOD_CTRL);
}

/*
 * The control byte terminals send for Ctrl and this key, or -1 when it
 * has none or its byte is also another key's: Ctrl+H is Backspace,
 * Ctrl+I Tab, Ctrl+M Enter and Ctrl+[ Escape.
 */
static int tf_control_byte(int code) {
	if (code >= 'A' && code <= 'Z') code += 'a' - 'A';
	if (code == 'h' || code == 'i' || code == 'm') return -1;
	if (code >= 'a' && code <= 'z') return code - 'a' + 1;
	if (code == ' ') return 0x00;
	if (code == '\\') return 0x1c;
	if (code == ']') return 0x1d;
	return -1;
}

/*
 * A key that types text, reported because of its modifiers. With Ctrl,
 * a key with a control byte of its own comes as termbox2 reports that
 * byte, any other with its unshifted character in ch; Shift stays a
 * modifier either way. Without Ctrl, ch is the character Shift makes,
 * as legacy terminals send it after the Escape of Alt.
 */
static int tf_kitty_text_key(struct tb_event *event, int code, int shifted, uint8_t mod) {
	int control_byte;

	if (mod & TB_MOD_CTRL) {
		control_byte = tf_control_byte(code);
		if (control_byte >= 0) return tf_key_event(event, (uint16_t)control_byte, 0, mod);
		return tf_key_event(event, 0, (uint32_t)code, mod);
	}
	if (!(mod & TB_MOD_SHIFT)) return tf_key_event(event, 0, (uint32_t)code, mod);
	if (shifted > 0) return tf_key_event(event, 0, (uint32_t)shifted, mod & ~TB_MOD_SHIFT);
	if (code >= 'a' && code <= 'z') return tf_key_event(event, 0, (uint32_t)(code - 'a' + 'A'), mod & ~TB_MOD_SHIFT);
	return tf_key_event(event, 0, (uint32_t)code, mod);
}

/*
 * A kitty key report, CSI code ; modifiers u. kitty sends it for keys
 * the legacy encodings cannot tell apart once the program asked for it
 * (see Term::Fabulous), and for keys that have no legacy encoding at
 * all even before that. The keys of the private use area that are not
 * in the functional key table, such as the modifier keys themselves,
 * are not reported.
 */
static int tf_kitty_key_event(const struct tf_csi_key *report, struct tb_event *event) {
	int code    = report->code;
	uint8_t mod     = tf_kitty_modifiers(report->modifiers);
	uint16_t functional;

	if (code < 0) return TB_ERR;
	functional = tf_kitty_functional_key(code);
	if (functional != 0) return tf_key_event(event, functional, 0, mod);
	if (code >= TF_PRIVATE_USE_FIRST && code <= TF_PRIVATE_USE_LAST) return TB_ERR;
	if (code < 0x20 || code == 0x7f) return tf_kitty_control_key(event, code, mod);
	return tf_kitty_text_key(event, code, report->shifted, mod);
}

static int tf_extract_csi_key(struct tb_event *event, size_t *consumed) {
	struct tf_csi_key report;
	size_t length;
	int rv;

	if_err_return(rv, tf_parse_csi_key(&report, &length));
	rv = report.final == 'u' ? tf_kitty_key_event(&report, event) : tf_function_key_event(&report, event);
	if (rv == TB_OK) *consumed = length;
	return rv;
}

static int tf_extract_input(struct tb_event *event, size_t *consumed) {
	const char *buf = global.in.buf;

	if (global.in.len < 2 || buf[0] != '\x1b') return TB_ERR;
	if (buf[1] != '[') return tf_extract_alt_key(event, consumed);
	if (global.in.len >= 3 && buf[2] == '<') return tf_extract_sgr_mouse(event, consumed);
	return tf_extract_csi_key(event, consumed);
}

int tf_install_input_parser(void) {
	return tb_set_func(TB_FUNC_EXTRACT_PRE, tf_extract_input);
}

/*
 * Inline mode. termbox2 has no switch for it, so tf_init_inline_rwfd()
 * runs the steps of tb_init_rwfd() itself and empties the capabilities
 * that take over the screen before anything is sent: the alternate
 * screen, entered at the start and left at tb_shutdown(), and the clear
 * that tb_init_rwfd(), every resize and tb_shutdown() send.
 */
static void tf_drop_screen_takeover(void) {
	global.caps[TB_CAP_ENTER_CA]     = "";
	global.caps[TB_CAP_EXIT_CA]      = "";
	global.caps[TB_CAP_CLEAR_SCREEN] = "";
}

int tf_init_inline(void) {
	int rv, rfd, wfd;

	if (global.initialized) return TB_ERR_INIT_ALREADY;
	if_err_return(rv, open_tty("/dev/tty", &rfd, &wfd));
	global.ttyfd_open = 1;
	return tf_init_inline_rwfd(rfd, wfd);
}

int tf_init_inline_rwfd(int rfd, int wfd) {
	int rv;

	if (global.initialized) return TB_ERR_INIT_ALREADY;
	tb_reset();

	do {
		if_err_break(rv, init_fds(rfd, wfd));
		if_err_break(rv, init_term_attrs());
		if_err_break(rv, init_term_caps());
		tf_drop_screen_takeover();
		if_err_break(rv, init_cap_trie());
		if_err_break(rv, init_resize_handler());
		if_err_break(rv, send_init_escape_codes());
		if_err_break(rv, bytebuf_flush(&global.out, global.wfd));
		if_err_break(rv, update_term_size());
		if_err_break(rv, init_cellbuf());
		global.initialized = 1;
	} while (0);

	if (rv != TB_OK) tb_deinit();
	return rv;
}

/* Any larger row or column is not a cursor position report. */
#define TF_CURSOR_NUMBER_LIMIT 65535

/*
 * Finds a cursor position report, ESC [ row ; column R, in the input
 * buffer from offset `from` on: TB_OK with its offset, length and
 * numbers, or TB_ERR while there is no complete one.
 */
static int tf_find_cursor_report(size_t from, size_t *at, size_t *length, int *row, int *column) {
	const char *buf = global.in.buf;
	size_t len      = global.in.len;
	size_t start, i;

	for (start = from; start + 1 < len; start++) {
		int numbers[2] = {0, 0};
		int count      = 0;
		int digits     = 0;

		if (buf[start] != '\x1b' || buf[start + 1] != '[') continue;
		for (i = start + 2; i < len; i++) {
			char c = buf[i];
			if (c >= '0' && c <= '9') {
				numbers[count] = numbers[count] * 10 + (c - '0');
				if (numbers[count] > TF_CURSOR_NUMBER_LIMIT) break;
				digits++;
			} else if (c == ';' && count == 0 && digits > 0) {
				count  = 1;
				digits = 0;
			} else if (c == 'R' && count == 1 && digits > 0) {
				*at     = start;
				*length = i + 1 - start;
				*row    = numbers[0];
				*column = numbers[1];
				return TB_OK;
			} else {
				break;
			}
		}
	}
	return TB_ERR;
}

/*
 * Appends what the terminal sent to the input buffer, waiting for it no
 * later than the deadline (a time of termbox2's now_ms clock):
 * TB_ERR_NO_EVENT once the deadline has passed. A wait a signal
 * interrupted reads nothing and returns TB_OK. A terminal at end of
 * file wakes the wait with nothing to append; that is TB_ERR_READ with
 * tb_last_errno 0, as a read of 0 bytes was before. A resize that
 * arrives meanwhile stays pending for tb_peek_event.
 */
static int tf_read_input_before(int64_t deadline) {
	int64_t left  = deadline - now_ms();
	size_t before = global.in.len;
	int rv;

	if (left <= 0) return TB_ERR_NO_EVENT;
	rv = wait_input((int)left, NULL);
#ifndef _WIN32
	if (rv == TB_ERR_POLL && global.last_errno == EINTR) return TB_OK;
#endif
	if (rv == TB_OK && global.in.len == before) {
		global.last_errno = 0;
		return TB_ERR_READ;
	}
	return rv;
}

/* Sends a question to the terminal and returns the time its answer must arrive by. */
static int tf_ask_terminal(const char *question, int timeout_ms, int64_t *deadline) {
	int rv;

	if_err_return(rv, bytebuf_puts(&global.out, question));
	if_err_return(rv, bytebuf_flush(&global.out, global.wfd));
	*deadline = now_ms() + timeout_ms;
	return TB_OK;
}

/* Takes an answer out of the input buffer, so that only keys stay queued. */
static void tf_drop_input(size_t at, size_t length) {
	memmove(global.in.buf + at, global.in.buf + at + length, global.in.len - at - length);
	global.in.len -= length;
	global.in.buf[global.in.len] = '\0';
}

int tf_cursor_position(int timeout_ms, int *x, int *y) {
	int64_t deadline;
	size_t from, at, length;
	int rv, row, column;

	if_not_init_return();
	from = global.in.len; /* input from before the question cannot hold the answer */
	if_err_return(rv, tf_ask_terminal("\x1b[6n", timeout_ms, &deadline));

	while (tf_find_cursor_report(from, &at, &length, &row, &column) != TB_OK) {
		if_err_return(rv, tf_read_input_before(deadline));
	}
	tf_drop_input(at, length);

	*x = column > 0 ? column - 1 : 0;
	*y = row > 0 ? row - 1 : 0;
	return TB_OK;
}

/*
 * Finds a private mode answer, ESC [ ? parameters final with the
 * parameters made of digits and ';', in the input buffer from offset
 * `from` on: TB_OK with its offset and length, or TB_ERR while there is
 * no complete one. The kitty keyboard flags end in 'u', the primary
 * device attributes in 'c'.
 */
static int tf_find_private_answer(size_t from, char final, size_t *at, size_t *length) {
	const char *buf = global.in.buf;
	size_t len      = global.in.len;
	size_t start, i;

	for (start = from; start + 2 < len; start++) {
		if (buf[start] != '\x1b' || buf[start + 1] != '[' || buf[start + 2] != '?') continue;
		for (i = start + 3; i < len && ((buf[i] >= '0' && buf[i] <= '9') || buf[i] == ';'); i++) {}
		if (i < len && buf[i] == final) {
			*at     = start;
			*length = i + 1 - start;
			return TB_OK;
		}
	}
	return TB_ERR;
}

int tf_kitty_keyboard_query(int timeout_ms, int *supported) {
	int64_t deadline;
	size_t from, at, length;
	int rv, attributes_arrived;

	*supported = 0;
	if_not_init_return();
	from = global.in.len; /* input from before the question cannot hold the answer */
	if_err_return(rv, tf_ask_terminal("\x1b[?u\x1b[c", timeout_ms, &deadline));

	for (;;) {
		attributes_arrived = tf_find_private_answer(from, 'c', &at, &length) == TB_OK;
		if (attributes_arrived) break;
		rv = tf_read_input_before(deadline);
		if (rv == TB_ERR_NO_EVENT) break;
		if (rv != TB_OK) return rv;
	}
	if (attributes_arrived) tf_drop_input(at, length);

	*supported = tf_find_private_answer(from, 'u', &at, &length) == TB_OK;
	if (*supported) tf_drop_input(at, length);
	return attributes_arrived || *supported ? TB_OK : TB_ERR_NO_EVENT;
}

/*
 * Whether the parameters of a primary device attributes answer, the
 * ESC [ ? 62;4;22 c at `at` with `length` bytes, list the number 4:
 * the terminal shows sixel graphics.
 */
static int tf_lists_sixel(size_t at, size_t length) {
	const char *buf = global.in.buf;
	size_t i;
	int number = 0, digits = 0;

	for (i = at + 3; i < at + length; i++) {
		if (buf[i] >= '0' && buf[i] <= '9') {
			if (number <= TF_CURSOR_NUMBER_LIMIT) number = number * 10 + (buf[i] - '0');
			digits++;
			continue;
		}
		if (digits > 0 && number == 4) return 1;
		number = digits = 0;
	}
	return 0;
}

/*
 * Finds a cell size report, ESC [ 6 ; height ; width t, in the input
 * buffer from offset `from` on: TB_OK with its offset, length and
 * numbers, or TB_ERR while there is no complete one.
 */
static int tf_find_cell_size_report(size_t from, size_t *at, size_t *length, int *height, int *width) {
	const char *buf = global.in.buf;
	size_t len      = global.in.len;
	size_t start, i;

	for (start = from; start + 3 < len; start++) {
		int numbers[2] = {0, 0};
		int count      = 0;
		int digits     = 0;

		if (buf[start] != '\x1b' || buf[start + 1] != '[' || buf[start + 2] != '6' || buf[start + 3] != ';') continue;
		for (i = start + 4; i < len; i++) {
			char c = buf[i];
			if (c >= '0' && c <= '9') {
				numbers[count] = numbers[count] * 10 + (c - '0');
				if (numbers[count] > TF_CURSOR_NUMBER_LIMIT) break;
				digits++;
			} else if (c == ';' && count == 0 && digits > 0) {
				count  = 1;
				digits = 0;
			} else if (c == 't' && count == 1 && digits > 0) {
				*at     = start;
				*length = i + 1 - start;
				*height = numbers[0];
				*width  = numbers[1];
				return TB_OK;
			} else {
				break;
			}
		}
	}
	return TB_ERR;
}

/*
 * The cell size the tty's window size gives, 0 x 0 when it has no
 * pixels. A Windows console knows no pixel size.
 */
static void tf_window_cell_size(int *cell_width, int *cell_height) {
	*cell_width = *cell_height = 0;
#ifndef _WIN32
	struct winsize size;

	memset(&size, 0, sizeof(size));
	if (global.ttyfd < 0 || ioctl(global.ttyfd, TIOCGWINSZ, &size) != 0) return;
	if (size.ws_col == 0 || size.ws_row == 0) return;
	*cell_width  = size.ws_xpixel / size.ws_col;
	*cell_height = size.ws_ypixel / size.ws_row;
	if (*cell_width == 0 || *cell_height == 0) *cell_width = *cell_height = 0;
#endif
}

int tf_sixel_query(int timeout_ms, int *supported, int *cell_width, int *cell_height) {
	int64_t deadline;
	size_t from, at, length;
	int rv, attributes_arrived, reported_height, reported_width;

	*supported   = 0;
	*cell_width  = 0;
	*cell_height = 0;
	if_not_init_return();
	from = global.in.len; /* input from before the question cannot hold the answer */
	if_err_return(rv, tf_ask_terminal("\x1b[16t\x1b[c", timeout_ms, &deadline));

	for (;;) {
		attributes_arrived = tf_find_private_answer(from, 'c', &at, &length) == TB_OK;
		if (attributes_arrived) break;
		rv = tf_read_input_before(deadline);
		if (rv == TB_ERR_NO_EVENT) break;
		if (rv != TB_OK) return rv;
	}
	if (attributes_arrived) {
		*supported = tf_lists_sixel(at, length);
		tf_drop_input(at, length);
	}

	if (tf_find_cell_size_report(from, &at, &length, &reported_height, &reported_width) == TB_OK) {
		tf_drop_input(at, length);
		if (reported_width > 0 && reported_height > 0) {
			*cell_width  = reported_width;
			*cell_height = reported_height;
		}
	}
	if (*cell_width == 0) tf_window_cell_size(cell_width, cell_height);
	return attributes_arrived ? TB_OK : TB_ERR_NO_EVENT;
}

int tf_cells_differ(int x, int y, int width, int height, int *differ) {
	struct tb_cell *back, *front;
	int rv, column, row;
	int right  = x + width;
	int bottom = y + height;

	*differ = 0;
	if_not_init_return();
	if (x < 0) x = 0;
	if (y < 0) y = 0;
	if (right > global.front.width) right = global.front.width;
	if (bottom > global.front.height) bottom = global.front.height;

	for (row = y; row < bottom; row++) {
		for (column = x; column < right; column++) {
			if_err_return(rv, cellbuf_get(&global.back, column, row, &back));
			if_err_return(rv, cellbuf_get(&global.front, column, row, &front));
			if (cell_cmp(back, front) != 0) {
				*differ = 1;
				return TB_OK;
			}
		}
	}
	return TB_OK;
}

int tf_invalidate_cells(int x, int y, int width, int height) {
	struct tb_cell *front;
	uint32_t invalid = (uint32_t)-1; /* what tb_present marks the hidden cells of a wide glyph with */
	int rv, column, row;
	int right  = x + width;
	int bottom = y + height;

	if_not_init_return();
	if (x < 0) x = 0;
	if (y < 0) y = 0;
	if (right > global.front.width) right = global.front.width;
	if (bottom > global.front.height) bottom = global.front.height;

	for (row = y; row < bottom; row++) {
		for (column = x; column < right; column++) {
			if_err_return(rv, cellbuf_get(&global.front, column, row, &front));
			if_err_return(rv, cell_set(front, &invalid, 1, (uintattr_t)-1, (uintattr_t)-1));
		}
	}
	return TB_OK;
}

int tf_reset_attrs(void) {
	if_not_init_return();
	global.last_fg = ~global.fg;
	global.last_bg = ~global.bg;
	return bytebuf_puts(&global.out, global.caps[TB_CAP_SGR0]);
}

int tf_flush(void) {
	if_not_init_return();
	return bytebuf_flush(&global.out, global.wfd);
}

/*
 * The end of the input. On POSIX, a descriptor that reports readable
 * with no byte to read is at end of file; a terminal that hung up
 * cannot even say how many bytes wait (EIO on Linux, ENXIO on FreeBSD).
 * On Windows, a console is gone when it no longer answers, a pipe when
 * its writer went away, a file at its end.
 */
#ifndef _WIN32
int tf_input_ended(int fd) {
	fd_set fds;
	struct timeval no_wait = {0, 0};
	int waiting;

	FD_ZERO(&fds);
	FD_SET(fd, &fds);
	if (select(fd + 1, &fds, NULL, NULL, &no_wait) <= 0) return 0;
	if (ioctl(fd, FIONREAD, &waiting) != 0) return errno == EIO || errno == ENXIO;
	return waiting == 0;
}
#else
int tf_input_ended(int fd) {
	HANDLE handle = (HANDLE)_get_osfhandle(fd);
	DWORD count;
	DWORD error;

	if (handle == INVALID_HANDLE_VALUE) return 1;
	switch (GetFileType(handle)) {
		case FILE_TYPE_PIPE:
			if (PeekNamedPipe(handle, NULL, 0, NULL, &count, NULL)) return 0;
			error = GetLastError();
			return error == ERROR_BROKEN_PIPE || error == ERROR_PIPE_NOT_CONNECTED;
		case FILE_TYPE_DISK:
			return _eof(fd) == 1;
		case FILE_TYPE_CHAR:
			/* A character device that is no console (NUL, a serial port)
			 * answers ERROR_INVALID_HANDLE and never ends; a console that
			 * went away fails in another way. */
			if (GetNumberOfConsoleInputEvents(handle, &count)) return 0;
			return GetLastError() != ERROR_INVALID_HANDLE;
		default:
			return 0;
	}
}
#endif
