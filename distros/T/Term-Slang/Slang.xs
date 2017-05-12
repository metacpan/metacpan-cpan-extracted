
/* $Id: Slang.xs,v 1.10 2000/04/17 22:46:08 daniel Exp $ */

#ifdef __cplusplus
"C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <slang.h>

typedef struct _Scroll_Line_Type {
	SV *sv_next;
	SV *sv_prev;
	char *data;
} Scroll_Line_Type;

/*
typedef struct _Scroll_Line_Type {
	struct _Scroll_Line_Type *next;
	struct _Scroll_Line_Type *prev;
	char *data;
} Scroll_Line_Type;
*/

MODULE = Term::Slang	PACKAGE = Term::Slang

################################
# Screen management
void
SLsmg_fill_region(r,c,nr,nc,ch)
	int		r;
	int		c;
	unsigned int	nr;
	unsigned int	nc;
	unsigned char	ch;

void
SLsmg_set_char_set(a)
	int a;

int
SLsmg_suspend_smg()

int
SLsmg_resume_smg()

void
SLsmg_erase_eol()

void
SLsmg_gotorc(row,col)
	int row;
	int col;

void
SLsmg_erase_eos()

void
SLsmg_reverse_video()

void
SLsmg_set_color(c)
	int c;

void
SLsmg_normal_video()

void
SLsmg_printf(fmt, ...)
	char *fmt;

#void
#SLsmg_vprintf(s,list)
#	char *s;
#	va_list list;

void
SLsmg_write_string(str)
	char *str;

void
SLsmg_write_nstring(str,len)
	char		*str;
	unsigned int	len;

void
SLsmg_write_char(ch)
	SV *ch;
	CODE:
	{
		if (SvIOK(ch)) {
			SLsmg_write_char(SvIV(ch));
		} else {
			SLsmg_write_char(*SvPV(ch,PL_na));
		}
	}

void
SLsmg_write_nchars(str,len)
	char		*str;
	unsigned int	len;

void
SLsmg_write_wrapped_string(str,p1,p2,p3,p4,p5)
	char *str
	int p1
	int p2;
	int p5;
	unsigned int p3;
	unsigned int p4;

void
SLsmg_cls()

void
SLsmg_refresh()

void
SLsmg_touch_lines(p1,p2)
	int p1;
	unsigned int p2;

int
SLsmg_init_smg()
	CODE:
		RETVAL = SLsmg_init_smg();
		RETVAL = RETVAL == 0 ? 1 : 0;
	OUTPUT:
	RETVAL

int
SLsmg_reinit_smg() 

void
SLsmg_reset_smg()

unsigned short
SLsmg_char_at()

void
SLsmg_set_screen_start(r,c)
	int r;
	int c;
	CODE:
		SLsmg_set_screen_start(&r, &c);

void
SLsmg_draw_hline(p1)
	unsigned int p1;

void
SLsmg_draw_vline(p1)
	int p1;

void
SLsmg_draw_object(p1,p2,s)
	int p1;
	int p2;
	unsigned char s;

void
SLsmg_draw_box(p1,p2,p3,p4)
	int p1;
	int p2;
	unsigned int p3;
	unsigned int p4;

int
SLsmg_get_column()

int
SLsmg_get_row()

void
SLsmg_forward(p1)
	int p1;

void
SLsmg_write_color_chars(us1,ui1)
	unsigned short &us1;
	unsigned int ui1;

unsigned int
SLsmg_read_raw(us1,ui1)
	unsigned short &us1;
	unsigned int ui1;

unsigned int
SLsmg_write_raw(us1,ui1)
	unsigned short &us1;
	unsigned int ui1;

void
SLsmg_set_color_in_region(i1,i2,i3,ui1,ui2)
	int i1;
	int i2;
	int i3;
	unsigned int ui1;
	unsigned int ui2;

void
SLsmg_set_terminal_info(info)
	SLsmg_Term_Type *info;

################################
# Tty stuff.

int
SLang_init_tty(abort_char,flow_control,opost)
	int abort_char;
	int flow_control;
	int opost;

void
SLang_reset_tty()

void
SLtty_set_suspend_state(p1)
	int p1;

int
SLang_getkey_intr_hook()

unsigned int
SLang_getkey()

int
SLang_ungetkey_string(buf,buflen)
	unsigned char	*buf;
	unsigned int	buflen;

int
SLang_buffer_keystring(buf,buflen)
	unsigned char	*buf;
	unsigned int	buflen;

int
SLang_ungetkey(ch)
	unsigned char ch;

void
SLang_flush_input()

int
SLang_input_pending(tsecs)
	int tsecs;

int
SLang_set_abort_signal(p1)
	void *p1;

################################
# Scrolling

SLscroll_Window_Type *
SLscroll_create()
	PREINIT:
		SLscroll_Window_Type *window;
		unsigned int nrows = 50;

	CODE:
	{
		window = safemalloc(sizeof(SLscroll_Window_Type));
		window->nrows = nrows;
		RETVAL = window;
	}
	OUTPUT:
	RETVAL

#   unsigned int flags;
#   SLscroll_Type *top_window_line;   /* list element at top of window */
#   SLscroll_Type *bot_window_line;   /* list element at bottom of window */
#   SLscroll_Type *current_line;    /* current list element */
#   SLscroll_Type *lines;               /* first list element */
#   unsigned int nrows;                 /* number of rows in window */
#   unsigned int hidden_mask;           /* applied to flags in SLscroll_Type */
#   unsigned int line_num;              /* current line number (visible) */
#   unsigned int num_lines;             /* total number of lines (visible) */
#   unsigned int window_row;            /* row of current_line in window */
#   unsigned int border;                /* number of rows that form scroll border */
#   int cannot_scroll;                  /* should window scroll or recenter */
# SLscroll_Window_Type;

void
SLscroll_get(window, key)
	SLscroll_Window_Type *window;
	char	*key;

	PREINIT:
		SV *sv;

	PPCODE:
	{
		if (strEQ(key, "flags")) {
			sv = newSViv(window->flags);
		} else if (strEQ(key, "top_window_line")) {
			sv = newSVpv((char*)window->top_window_line, 0);
		} else if (strEQ(key, "bot_window_line")) {
			sv = newSVpv((char*)window->bot_window_line, 0);
		} else if (strEQ(key, "current_line")) {
			sv = newSVpv((char*)window->current_line, 0);
		} else if (strEQ(key, "lines")) {
			sv = newSVpv((char*)window->lines, 0);
		} else if (strEQ(key, "nrows")) {
			sv = newSViv(window->nrows);
		} else if (strEQ(key, "hidden_mask")) {
			sv = newSViv(window->hidden_mask);
		} else if (strEQ(key, "line_num")) {
			sv = newSViv(window->line_num);
		} else if (strEQ(key, "num_lines")) {
			sv = newSViv(window->num_lines);
		} else if (strEQ(key, "window_row")) {
			sv = newSViv(window->window_row);
		} else if (strEQ(key, "border")) {
			sv = newSViv(window->border);
		} else if (strEQ(key, "cannot_scroll")) {
			sv = newSViv(window->cannot_scroll);
		}

		XPUSHs(sv);
	}

void
SLscroll_destroy(window)
	SLscroll_Window_Type	*window;
	CODE:
	{
		safefree(window);
	}

void
SLscroll_set(window, key, val)
	SLscroll_Window_Type	*window;
	char			*key;
	SV			*val;

	CODE:
	{
		if (strEQ(key, "flags")) {
			window->flags = SvIV(val);
		} else if (strEQ(key, "top_window_line")) {
			window->top_window_line = (SLscroll_Type*)SvPV(val, PL_na);
		} else if (strEQ(key, "bot_window_line")) {
			window->bot_window_line = (SLscroll_Type*)SvPV(val, PL_na);
		} else if (strEQ(key, "current_line")) {
			window->current_line = (SLscroll_Type*)SvPV(val, PL_na);
		} else if (strEQ(key, "lines")) {
			window->lines = (SLscroll_Type*)SvPV(val, PL_na);
		} else if (strEQ(key, "nrows")) {
			window->nrows = SvUV(val);
		} else if (strEQ(key, "hidden_mask")) {
			window->hidden_mask = SvUV(val);
		} else if (strEQ(key, "line_num")) {
			window->line_num = SvUV(val);
		} else if (strEQ(key, "num_lines")) {
			window->num_lines = SvUV(val);
		} else if (strEQ(key, "window_row")) {
			window->window_row = SvUV(val);
		} else if (strEQ(key, "border")) {
			window->border = SvUV(val);
		} else if (strEQ(key, "cannot_scroll")) {
			window->cannot_scroll = SvIV(val);
		}
	}

#############################################

Scroll_Line_Type *
SLline_create(CLASS)
	char *CLASS;
	CODE:
	{
		RETVAL = (Scroll_Line_Type*)safemalloc(sizeof(Scroll_Line_Type));
		if (RETVAL == NULL) {
			warn("Unable to malloc Scroll_Line_Type");
			XSRETURN_UNDEF;
		}
	}
	OUTPUT:
	RETVAL

void
SLline_destroy(self)
	Scroll_Line_Type *self;
	CODE:
	{
		if (self->sv_next != NULL) {
			SvREFCNT_dec( self->sv_next );
		}

		if (self->sv_prev != NULL) {
			SvREFCNT_dec( self->sv_prev );
		}

		safefree((char*)self);
	}

void
SLline_get(lines, key)
	Scroll_Line_Type *lines;
	char		 *key;

	PREINIT:
		SV *sv;

	PPCODE:
	{
		if (strEQ(key, "next")) {
			sv = (Scroll_Line_Type*)SvPV( lines->sv_next, PL_na );

			/* c = (PAIR*)SvIV( c->sv_next ); */
		} else if (strEQ(key, "prev")) {
			/* sv = newSVpv((char*)lines->sv_prev, 0); */
			sv = (Scroll_Line_Type*)SvIV( lines->sv_prev );

		} else if (strEQ(key, "data")) {
			sv = newSVpv((char*)lines->data, 0);
		}

		XPUSHs(sv);
	}

void
SLline_set(self, key, val)
	Scroll_Line_Type	*self;
	char			*key;
	SV			*val;

	CODE:
	{
		Scroll_Line_Type *foo;
		foo = (Scroll_Line_Type*)safemalloc(sizeof(Scroll_Line_Type));

		printf("in SLline_set\n");
		/*
		foo = (Scroll_Line_Type*)SvRV(val);
		printf("in SLline_set\n");
		printf("VAL1: %s\n", (char*)foo->data);
		*/

		if (strEQ(key, "next")) {
			self->sv_next = SvRV(val);
			SvREFCNT_inc( self->sv_next );

			if (SvIOK(self->sv_next)) {
				foo = (Scroll_Line_Type*)self->sv_next;
				printf("SLline_set->next->data: %s\n", (char*)foo->data);
			}

		} else if (strEQ(key, "prev")) {
			self->sv_prev = SvRV(val);
			SvREFCNT_inc( self->sv_prev );

			if (SvIOK(self->sv_prev)) {
				foo = (Scroll_Line_Type*)self->sv_prev;
				printf("SLline_set->prev->data: %s\n", (char*)foo->data);
			}

		} else if (strEQ(key, "data")) {
			self->data = (char*)SvPV(val, PL_na);
			printf("DATAVAL: %s\n", (char*)self->data);
		}
	}

int
SLscroll_find_top(scroll)
	SLscroll_Window_Type *scroll;

int
SLscroll_find_line_num(scroll)
	SLscroll_Window_Type *scroll;

unsigned int
SLscroll_next_n(scroll,ui1)
	SLscroll_Window_Type *scroll;
	unsigned int ui1;

unsigned int
SLscroll_prev_n(scroll,ui1)
	SLscroll_Window_Type *scroll;
	unsigned int ui1;

int
SLscroll_pageup(scroll)
	SLscroll_Window_Type *scroll;

int
SLscroll_pagedown(scroll)
	SLscroll_Window_Type *scroll;

################################
# Readline

SLang_Read_Line_Type*
SLang_rline_save_line(rline)
	SLang_RLine_Info_Type *rline;

int
SLang_init_readline(rline)
	SLang_RLine_Info_Type *rline;

int
SLang_read_line(rline)
	SLang_RLine_Info_Type *rline;

int
SLang_rline_insert(s)
	char *s;

void
SLrline_redraw(rline)
	SLang_RLine_Info_Type *rline;

################################
# Signals

void
SLsig_block_signals()

void
SLsig_unblock_signals()

################################
# Keys

int
SLkp_define_keysym(key,map)
	char *key;
	unsigned int map;

int
SLkp_init()

int
SLkp_getkey()

################################
# Low level

int
SLtt_flush_output()

void
SLtt_set_scroll_region(i1,i2)
	int i1;
	int i2;

void
SLtt_reset_scroll_region()

void
SLtt_reverse_video(i1)
	int i1;

void
SLtt_bold_video()

void
SLtt_begin_insert()

void
SLtt_end_insert()

void
SLtt_del_eol()

void
SLtt_goto_rc(i1,i2)
	int i1;
	int i2;

void
SLtt_delete_nlines(i1)
	int i1;

void
SLtt_delete_char()

void
SLtt_erase_line()

void
SLtt_normal_video()

void
SLtt_cls()

void
SLtt_beep()

void
SLtt_reverse_index(i1)
	int i1;

void
SLtt_smart_puts(us1,us2,i1,i2)
	unsigned short *us1;
	unsigned short *us2;
	int i1;
	int i2;

void
SLtt_write_string(s)
	char *s;

void
SLtt_putchar(s)
	char s;

int
SLtt_init_video()

int
SLtt_reset_video()

void
SLtt_get_terminfo()

void
SLtt_get_screen_size()
	PROTOTYPE: ;
	PPCODE:
		SLtt_get_screen_size();
		EXTEND(sp,2);
		PUSHs(sv_2mortal(newSViv(SLtt_Screen_Rows)));
		PUSHs(sv_2mortal(newSViv(SLtt_Screen_Cols)));

void
SLtt_set_screen_size(r, c)
	int r;
	int c;
	CODE:
		SLtt_Screen_Rows = r;
		SLtt_Screen_Cols = c;

int
SLtt_set_cursor_visibility(i1)
	int i1;

int
SLtt_set_mouse_mode(i1,i2)
	int i1;
	int i2;

void
SLtt_set_color(obj,name,fg,bg)
	int	obj;
	char	*name;
	char	*fg;
	char	*bg;

void
SLtt_set_mono(i1, s1, l1)
	int i1;
	char *s1;
	unsigned long l1;

BOOT:
{
	HV *stash = gv_stashpvn("Term::Slang", 11, TRUE);
	struct { char *n; I32 v; } Term__Slang__const[] = {
#ifdef SLANG_GETKEY_ERROR
	{"SLANG_GETKEY_ERROR", SLANG_GETKEY_ERROR},
#endif
#ifdef SLANG_VERSION
	{"SLANG_VERSION", SLANG_VERSION},
#endif
#ifdef SLSMG_BLOCK_CHAR
	{"SLSMG_BLOCK_CHAR", SLSMG_BLOCK_CHAR},
#endif
#ifdef SLSMG_BOARD_CHAR
	{"SLSMG_BOARD_CHAR", SLSMG_BOARD_CHAR},
#endif
#ifdef SLSMG_BULLET_CHAR
	{"SLSMG_BULLET_CHAR", SLSMG_BULLET_CHAR},
#endif
#ifdef SLSMG_CKBRD_CHAR
	{"SLSMG_CKBRD_CHAR", SLSMG_CKBRD_CHAR},
#endif
#ifdef SLSMG_COLOR_BLACK
	{"SLSMG_COLOR_BLACK", SLSMG_COLOR_BLACK},
#endif
#ifdef SLSMG_COLOR_BLUE
	{"SLSMG_COLOR_BLUE", SLSMG_COLOR_BLUE},
#endif
#ifdef SLSMG_COLOR_BRIGHT_BLUE
	{"SLSMG_COLOR_BRIGHT_BLUE", SLSMG_COLOR_BRIGHT_BLUE},
#endif
#ifdef SLSMG_COLOR_BRIGHT_BROWN
	{"SLSMG_COLOR_BRIGHT_BROWN", SLSMG_COLOR_BRIGHT_BROWN},
#endif
#ifdef SLSMG_COLOR_BRIGHT_CYAN
	{"SLSMG_COLOR_BRIGHT_CYAN", SLSMG_COLOR_BRIGHT_CYAN},
#endif
#ifdef SLSMG_COLOR_BRIGHT_GREEN
	{"SLSMG_COLOR_BRIGHT_GREEN", SLSMG_COLOR_BRIGHT_GREEN},
#endif
#ifdef SLSMG_COLOR_BRIGHT_MAGENTA
	{"SLSMG_COLOR_BRIGHT_MAGENTA", SLSMG_COLOR_BRIGHT_MAGENTA},
#endif
#ifdef SLSMG_COLOR_BRIGHT_RED
	{"SLSMG_COLOR_BRIGHT_RED", SLSMG_COLOR_BRIGHT_RED},
#endif
#ifdef SLSMG_COLOR_BRIGHT_WHITE
	{"SLSMG_COLOR_BRIGHT_WHITE", SLSMG_COLOR_BRIGHT_WHITE},
#endif
#ifdef SLSMG_COLOR_BROWN
	{"SLSMG_COLOR_BROWN", SLSMG_COLOR_BROWN},
#endif
#ifdef SLSMG_COLOR_CYAN
	{"SLSMG_COLOR_CYAN", SLSMG_COLOR_CYAN},
#endif
#ifdef SLSMG_COLOR_GRAY
	{"SLSMG_COLOR_GRAY", SLSMG_COLOR_GRAY},
#endif
#ifdef SLSMG_COLOR_GREEN
	{"SLSMG_COLOR_GREEN", SLSMG_COLOR_GREEN},
#endif
#ifdef SLSMG_COLOR_LGRAY
	{"SLSMG_COLOR_LGRAY", SLSMG_COLOR_LGRAY},
#endif
#ifdef SLSMG_COLOR_MAGENTA
	{"SLSMG_COLOR_MAGENTA", SLSMG_COLOR_MAGENTA},
#endif
#ifdef SLSMG_COLOR_RED
	{"SLSMG_COLOR_RED", SLSMG_COLOR_RED},
#endif
#ifdef SLSMG_DARROW_CHAR
	{"SLSMG_DARROW_CHAR", SLSMG_DARROW_CHAR},
#endif
#ifdef SLSMG_DEGREE_CHAR
	{"SLSMG_DEGREE_CHAR", SLSMG_DEGREE_CHAR},
#endif
#ifdef SLSMG_DIAMOND_CHAR
	{"SLSMG_DIAMOND_CHAR", SLSMG_DIAMOND_CHAR},
#endif
#ifdef SLSMG_DTEE_CHAR
	{"SLSMG_DTEE_CHAR", SLSMG_DTEE_CHAR},
#endif
#ifdef SLSMG_HLINE_CHAR
	{"SLSMG_HLINE_CHAR", SLSMG_HLINE_CHAR},
#endif
#ifdef SLSMG_LARROW_CHAR
	{"SLSMG_LARROW_CHAR", SLSMG_LARROW_CHAR},
#endif
#ifdef SLSMG_LLCORN_CHAR
	{"SLSMG_LLCORN_CHAR", SLSMG_LLCORN_CHAR},
#endif
#ifdef SLSMG_LRCORN_CHAR
	{"SLSMG_LRCORN_CHAR", SLSMG_LRCORN_CHAR},
#endif
#ifdef SLSMG_LTEE_CHAR
	{"SLSMG_LTEE_CHAR", SLSMG_LTEE_CHAR},
#endif
#ifdef SLSMG_NEWLINE_IGNORED
	{"SLSMG_NEWLINE_IGNORED", SLSMG_NEWLINE_IGNORED},
#endif
#ifdef SLSMG_NEWLINE_MOVES
	{"SLSMG_NEWLINE_MOVES", SLSMG_NEWLINE_MOVES},
#endif
#ifdef SLSMG_NEWLINE_PRINTABLE
	{"SLSMG_NEWLINE_PRINTABLE", SLSMG_NEWLINE_PRINTABLE},
#endif
#ifdef SLSMG_NEWLINE_SCROLLS
	{"SLSMG_NEWLINE_SCROLLS", SLSMG_NEWLINE_SCROLLS},
#endif
#ifdef SLSMG_PLMINUS_CHAR
	{"SLSMG_PLMINUS_CHAR", SLSMG_PLMINUS_CHAR},
#endif
#ifdef SLSMG_PLUS_CHAR
	{"SLSMG_PLUS_CHAR", SLSMG_PLUS_CHAR},
#endif
#ifdef SLSMG_RARROW_CHAR
	{"SLSMG_RARROW_CHAR", SLSMG_RARROW_CHAR},
#endif
#ifdef SLSMG_RTEE_CHAR
	{"SLSMG_RTEE_CHAR", SLSMG_RTEE_CHAR},
#endif
#ifdef SLSMG_UARROW_CHAR
	{"SLSMG_UARROW_CHAR", SLSMG_UARROW_CHAR},
#endif
#ifdef SLSMG_ULCORN_CHAR
	{"SLSMG_ULCORN_CHAR", SLSMG_ULCORN_CHAR},
#endif
#ifdef SLSMG_URCORN_CHAR
	{"SLSMG_URCORN_CHAR", SLSMG_URCORN_CHAR},
#endif
#ifdef SLSMG_UTEE_CHAR
	{"SLSMG_UTEE_CHAR", SLSMG_UTEE_CHAR},
#endif
#ifdef SLSMG_VLINE_CHAR
	{"SLSMG_VLINE_CHAR", SLSMG_VLINE_CHAR},
#endif
#ifdef SLTT_ALTC_MASK
	{"SLTT_ALTC_MASK", SLTT_ALTC_MASK},
#endif
#ifdef SLTT_BLINK_MASK
	{"SLTT_BLINK_MASK", SLTT_BLINK_MASK},
#endif
#ifdef SLTT_BOLD_MASK
	{"SLTT_BOLD_MASK", SLTT_BOLD_MASK},
#endif
#ifdef SLTT_REV_MASK
	{"SLTT_REV_MASK", SLTT_REV_MASK},
#endif
#ifdef SLTT_ULINE_MASK
	{"SLTT_ULINE_MASK", SLTT_ULINE_MASK},
#endif
#ifdef SL_KEY_A1
	{"SL_KEY_A1", SL_KEY_A1},
#endif
#ifdef SL_KEY_A3
	{"SL_KEY_A3", SL_KEY_A3},
#endif
#ifdef SL_KEY_B2
	{"SL_KEY_B2", SL_KEY_B2},
#endif
#ifdef SL_KEY_BACKSPACE
	{"SL_KEY_BACKSPACE", SL_KEY_BACKSPACE},
#endif
#ifdef SL_KEY_C1
	{"SL_KEY_C1", SL_KEY_C1},
#endif
#ifdef SL_KEY_C3
	{"SL_KEY_C3", SL_KEY_C3},
#endif
#ifdef SL_KEY_DELETE
	{"SL_KEY_DELETE", SL_KEY_DELETE},
#endif
#ifdef SL_KEY_DOWN
	{"SL_KEY_DOWN", SL_KEY_DOWN},
#endif
#ifdef SL_KEY_END
	{"SL_KEY_END", SL_KEY_END},
#endif
#ifdef SL_KEY_ENTER
	{"SL_KEY_ENTER", SL_KEY_ENTER},
#endif
#ifdef SL_KEY_ERR
	{"SL_KEY_ERR", SL_KEY_ERR},
#endif
#ifdef SL_KEY_F0
	{"SL_KEY_F0", SL_KEY_F0},
#endif
#ifdef SL_KEY_HOME
	{"SL_KEY_HOME", SL_KEY_HOME},
#endif
#ifdef SL_KEY_IC
	{"SL_KEY_IC", SL_KEY_IC},
#endif
#ifdef SL_KEY_LEFT
	{"SL_KEY_LEFT", SL_KEY_LEFT},
#endif
#ifdef SL_KEY_NPAGE
	{"SL_KEY_NPAGE", SL_KEY_NPAGE},
#endif
#ifdef SL_KEY_PPAGE
	{"SL_KEY_PPAGE", SL_KEY_PPAGE},
#endif
#ifdef SL_KEY_REDO
	{"SL_KEY_REDO", SL_KEY_REDO},
#endif
#ifdef SL_KEY_RIGHT
	{"SL_KEY_RIGHT", SL_KEY_RIGHT},
#endif
#ifdef SL_KEY_UNDO
	{"SL_KEY_UNDO", SL_KEY_UNDO},
#endif
#ifdef SL_KEY_UP
	{"SL_KEY_UP", SL_KEY_UP},
#endif
	{Nullch,0}};

	char *name;
	int i;
	for (i = 0; name = Term__Slang__const[i].n; i++) {
		newCONSTSUB(stash, name, newSViv(Term__Slang__const[i].v));
	}
}
