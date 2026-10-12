/*
 * tf_termbox.h - termbox2 as Term::Fabulous compiles it.
 *
 * Every translation unit that touches termbox2 includes this header, so
 * the options below are the same in the library (termbox2.c) and in the
 * XS layer (lib/Term/Fabulous/Termbox.xs). uintattr_t is then uint64_t.
 */
#ifndef TF_TERMBOX_H
#define TF_TERMBOX_H

/* 64-bit attributes: 24-bit color plus every style bit, including
 * TB_STRIKEOUT, TB_UNDERLINE_2, TB_OVERLINE and TB_INVISIBLE. */
#define TB_OPT_ATTR_W 64

/* Grapheme clusters per cell (tb_extend_cell, tb_set_cell_ex). */
#define TB_OPT_EGC

#include "termbox2.h"

/*
 * Mouse keys termbox2 has no code for, numbered below its own
 * TB_KEY_MOUSE_* codes. tf_install_input_parser() makes tb_peek_event
 * report them.
 */
#define TF_KEY_MOUSE_MOVE        (0xffff - 29)
#define TF_KEY_MOUSE_WHEEL_LEFT  (0xffff - 30)
#define TF_KEY_MOUSE_WHEEL_RIGHT (0xffff - 31)

/*
 * Keys only the kitty keyboard protocol reports, numbered below the
 * mouse keys in the order of kitty's functional key table: the lock and
 * system keys, then F13 to F35, the keypad and the media keys.
 * tf_install_input_parser() makes tb_peek_event report them.
 */
#define TF_KEY_CAPS_LOCK            (0xffff - 32)
#define TF_KEY_SCROLL_LOCK          (0xffff - 33)
#define TF_KEY_NUM_LOCK             (0xffff - 34)
#define TF_KEY_PRINT_SCREEN         (0xffff - 35)
#define TF_KEY_PAUSE                (0xffff - 36)
#define TF_KEY_MENU                 (0xffff - 37)
#define TF_KEY_F13                  (0xffff - 38)
#define TF_KEY_F14                  (0xffff - 39)
#define TF_KEY_F15                  (0xffff - 40)
#define TF_KEY_F16                  (0xffff - 41)
#define TF_KEY_F17                  (0xffff - 42)
#define TF_KEY_F18                  (0xffff - 43)
#define TF_KEY_F19                  (0xffff - 44)
#define TF_KEY_F20                  (0xffff - 45)
#define TF_KEY_F21                  (0xffff - 46)
#define TF_KEY_F22                  (0xffff - 47)
#define TF_KEY_F23                  (0xffff - 48)
#define TF_KEY_F24                  (0xffff - 49)
#define TF_KEY_F25                  (0xffff - 50)
#define TF_KEY_F26                  (0xffff - 51)
#define TF_KEY_F27                  (0xffff - 52)
#define TF_KEY_F28                  (0xffff - 53)
#define TF_KEY_F29                  (0xffff - 54)
#define TF_KEY_F30                  (0xffff - 55)
#define TF_KEY_F31                  (0xffff - 56)
#define TF_KEY_F32                  (0xffff - 57)
#define TF_KEY_F33                  (0xffff - 58)
#define TF_KEY_F34                  (0xffff - 59)
#define TF_KEY_F35                  (0xffff - 60)
#define TF_KEY_KP_0                 (0xffff - 61)
#define TF_KEY_KP_1                 (0xffff - 62)
#define TF_KEY_KP_2                 (0xffff - 63)
#define TF_KEY_KP_3                 (0xffff - 64)
#define TF_KEY_KP_4                 (0xffff - 65)
#define TF_KEY_KP_5                 (0xffff - 66)
#define TF_KEY_KP_6                 (0xffff - 67)
#define TF_KEY_KP_7                 (0xffff - 68)
#define TF_KEY_KP_8                 (0xffff - 69)
#define TF_KEY_KP_9                 (0xffff - 70)
#define TF_KEY_KP_DECIMAL           (0xffff - 71)
#define TF_KEY_KP_DIVIDE            (0xffff - 72)
#define TF_KEY_KP_MULTIPLY          (0xffff - 73)
#define TF_KEY_KP_SUBTRACT          (0xffff - 74)
#define TF_KEY_KP_ADD               (0xffff - 75)
#define TF_KEY_KP_ENTER             (0xffff - 76)
#define TF_KEY_KP_EQUAL             (0xffff - 77)
#define TF_KEY_KP_SEPARATOR         (0xffff - 78)
#define TF_KEY_KP_LEFT              (0xffff - 79)
#define TF_KEY_KP_RIGHT             (0xffff - 80)
#define TF_KEY_KP_UP                (0xffff - 81)
#define TF_KEY_KP_DOWN              (0xffff - 82)
#define TF_KEY_KP_PAGE_UP           (0xffff - 83)
#define TF_KEY_KP_PAGE_DOWN         (0xffff - 84)
#define TF_KEY_KP_HOME              (0xffff - 85)
#define TF_KEY_KP_END               (0xffff - 86)
#define TF_KEY_KP_INSERT            (0xffff - 87)
#define TF_KEY_KP_DELETE            (0xffff - 88)
#define TF_KEY_KP_BEGIN             (0xffff - 89)
#define TF_KEY_MEDIA_PLAY           (0xffff - 90)
#define TF_KEY_MEDIA_PAUSE          (0xffff - 91)
#define TF_KEY_MEDIA_PLAY_PAUSE     (0xffff - 92)
#define TF_KEY_MEDIA_REVERSE        (0xffff - 93)
#define TF_KEY_MEDIA_STOP           (0xffff - 94)
#define TF_KEY_MEDIA_FAST_FORWARD   (0xffff - 95)
#define TF_KEY_MEDIA_REWIND         (0xffff - 96)
#define TF_KEY_MEDIA_TRACK_NEXT     (0xffff - 97)
#define TF_KEY_MEDIA_TRACK_PREVIOUS (0xffff - 98)
#define TF_KEY_MEDIA_RECORD         (0xffff - 99)
#define TF_KEY_LOWER_VOLUME         (0xffff - 100)
#define TF_KEY_RAISE_VOLUME         (0xffff - 101)
#define TF_KEY_MUTE_VOLUME          (0xffff - 102)

/*
 * Modifiers only the kitty keyboard protocol reports, in the bits of
 * the event's mod that termbox2 leaves free.
 */
#define TF_MOD_SUPER 16
#define TF_MOD_HYPER 32
#define TF_MOD_META  64

/*
 * Width of a grapheme cluster the way tb_present() measures it. termbox2
 * keeps tb_cluster_width() static, so termbox2.c exports this wrapper
 * from the same translation unit.
 */
int tf_cluster_width(const uint32_t *codepoints, size_t count);

/*
 * Reads the input termbox2 gets wrong before termbox2 sees it: Alt plus
 * a key, SGR mouse reports with their motion, modifier and horizontal
 * wheel bits, the kitty keyboard protocol's CSI u key reports, and
 * modified function keys with modifiers termbox2 has no entry for.
 * Call it after every tb_init(); tb_shutdown() forgets it. Returns a
 * termbox2 status code.
 *
 * It relies on tb_set_func(TB_FUNC_EXTRACT_PRE) and on termbox2's
 * input buffer (global.in), which upstream removes in version 3.x; see
 * README.termbox2 before updating termbox2.h.
 */
int tf_install_input_parser(void);

/*
 * Inline mode: tb_init_rwfd without taking over the screen. termbox2
 * neither switches to the alternate screen nor clears it, not at the
 * start, not on a resize and not at tb_shutdown(); its cell buffers
 * still cover the whole terminal, and the caller paints only the rows
 * it owns. tf_init_inline() opens /dev/tty like tb_init(). Both return
 * a termbox2 status code.
 *
 * They call termbox2's internal init steps and replace entries of its
 * capability table (global.caps); see README.termbox2 before updating
 * termbox2.h.
 */
int tf_init_inline(void);
int tf_init_inline_rwfd(int rfd, int wfd);

/*
 * Asks the terminal where the cursor is (ESC [ 6 n) and waits up to
 * timeout_ms milliseconds for its report. x and y count from 0. Input
 * that arrives meanwhile stays queued for tb_peek_event. Returns
 * TB_ERR_NO_EVENT when no report arrived in time, else a termbox2
 * status code.
 */
int tf_cursor_position(int timeout_ms, int *x, int *y);

/*
 * Asks whether the terminal speaks the kitty keyboard protocol: the
 * query for its flags (ESC [ ? u) followed by the one for its primary
 * device attributes (ESC [ c), which every terminal answers. Waits up
 * to timeout_ms milliseconds for that answer and sets *supported to 1
 * when the flags were reported, else to 0. Input that arrives
 * meanwhile stays queued for tb_peek_event. Returns TB_ERR_NO_EVENT
 * when no device attributes arrived in time and no flags either, else
 * a termbox2 status code.
 */
int tf_kitty_keyboard_query(int timeout_ms, int *supported);

/*
 * Asks whether the terminal shows sixel graphics and how many pixels a
 * cell has: the query for the size of a cell (ESC [ 16 t) followed by
 * the one for the primary device attributes (ESC [ c), which every
 * terminal answers and which lists 4 for sixel. Waits up to timeout_ms
 * milliseconds for that answer and sets *supported to 1 when it lists
 * 4, else to 0. The cell size is the one the terminal reported, else
 * the one the tty's window size gives (TIOCGWINSZ), else 0 x 0. Input
 * that arrives meanwhile stays queued for tb_peek_event. Returns
 * TB_ERR_NO_EVENT when no device attributes arrived in time, else a
 * termbox2 status code.
 */
int tf_sixel_query(int timeout_ms, int *supported, int *cell_width, int *cell_height);

/*
 * Sets *differ to 1 when tb_present() would draw a cell of the
 * rectangle, because the cell differs between the back and the front
 * buffer, else to 0. The part of the rectangle outside the screen is
 * ignored. Returns a termbox2 status code.
 */
int tf_cells_differ(int x, int y, int width, int height, int *differ);

/*
 * Makes the next tb_present() draw every cell of the rectangle, like
 * tb_invalidate() does for the whole screen: for cells whose content
 * the terminal shows differently from what termbox2 believes, such as
 * the cells a sixel image covered. The part of the rectangle outside
 * the screen is ignored. Returns a termbox2 status code.
 */
int tf_invalidate_cells(int x, int y, int width, int height);

/*
 * Queues the reset of all colors and styles (SGR 0), and makes the next
 * cell tb_present() draws set its colors again: termbox2 otherwise
 * skips colors it believes the terminal still has.
 */
int tf_reset_attrs(void);

/* Writes what tb_send() and the other output calls queued. */
int tf_flush(void);

/*
 * Whether the input descriptor fd, which termbox2 reads (tb_get_fds),
 * has ended for good: 1 when it reports readable but has no byte to
 * read, or cannot even tell because the terminal hung up (EIO, or
 * ENXIO on FreeBSD); on Windows, when a console no longer answers, a
 * pipe has lost its writer or a file is at its end. Else 0. termbox2
 * itself reports the end of the input only as "no event", again and
 * again. Works before tb_init() and after tb_shutdown() as well.
 */
int tf_input_ended(int fd);

#endif /* TF_TERMBOX_H */
