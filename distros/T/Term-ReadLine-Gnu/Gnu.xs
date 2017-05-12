/*
 *	Gnu.xs --- GNU Readline wrapper module
 *
 *	$Id: Gnu.xs 555 2016-11-03 14:04:27Z hayashi $
 *
 *	Copyright (c) 1996-2016 Hiroo Hayashi.  All rights reserved.
 *
 *	This program is free software; you can redistribute it and/or
 *	modify it under the same terms as Perl itself.
 */

#ifdef __cplusplus
extern "C" {
#endif
#define PERLIO_NOT_STDIO 0
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#include <stdio.h>
#ifdef __CYGWIN__
#include <sys/termios.h>
#endif /* __CYGWIN__ */
#include <readline/readline.h>
#include <readline/history.h>

/*
 * Perl 5.005 requires an ANSI C Compiler.  Good news.
 * But I should still support legacy C compilers now.
 */
/* Adapted from BSD /usr/include/sys/cdefs.h. */
#if defined (__STDC__)
#  if !defined (PARAMS)
#    define PARAMS(protos) protos
#  endif
#else /* !__STDC__ */
#  if !defined (PARAMS)
#    define PARAMS(protos) ()
#  endif
#endif /* !__STDC__ */

/*
 * In Readline 4.2 many variables, function arguments, and function
 * return values are now declared `const' where appropriate.
 */
#if (RL_READLINE_VERSION < 0x0402)
#define CONST
#else  /* (RL_READLINE_VERSION >= 0x0402) */
#define CONST const
#endif /* (RL_READLINE_VERSION >= 0x0402) */

typedef char *	t_utf8;			/* string which must not be xfreed */
typedef char *	t_utf8_free;		/* string which must be xfreed */

/* 
 * utf8_mode is set in the Perl side, and it must be set before
 * calling sv_2mortal_utf8()
 */
static int utf8_mode = 0;
static SV*
sv_2mortal_utf8(SV *sv)
{
  sv = sv_2mortal(sv);
  if (utf8_mode)
    sv_utf8_decode(sv);
  return sv;
}

/*
 * compatibility definitions
 */
#if (RL_READLINE_VERSION < 0x0402)
typedef int rl_command_func_t PARAMS((int, int));
typedef char *rl_compentry_func_t PARAMS((const char *, int));
typedef char **rl_completion_func_t PARAMS((const char *, int, int));
typedef char *rl_quote_func_t PARAMS((char *, int, char *));
typedef char *rl_dequote_func_t PARAMS((char *, int));
typedef int rl_compignore_func_t PARAMS((char **));
typedef void rl_compdisp_func_t PARAMS((char **, int, int));
typedef int rl_hook_func_t PARAMS((void));
typedef int rl_getc_func_t PARAMS((FILE *));
typedef int rl_linebuf_func_t PARAMS((char *, int));

/* `Generic' function pointer typedefs */
typedef int rl_intfunc_t PARAMS((int));
#define rl_ivoidfunc_t rl_hook_func_t
typedef int rl_icpfunc_t PARAMS((char *));
typedef int rl_icppfunc_t PARAMS((char **));

typedef void rl_voidfunc_t PARAMS((void));
typedef void rl_vintfunc_t PARAMS((int));
typedef void rl_vcpfunc_t PARAMS((char *));
typedef void rl_vcppfunc_t PARAMS((char **));

/* rl_last_func() is defined in rlprivate.h */
extern rl_command_func_t *rl_last_func;
#endif /* (RL_READLINE_VERSION < 0x0402) */

#if (RL_READLINE_VERSION < 0x0500)
typedef char *rl_cpvfunc_t PARAMS((void));
#endif /* (RL_READLINE_VERSION < 0x0500) */


#if (RL_READLINE_VERSION < 0x0201)
/* features introduced by GNU Readline 2.1 */
static rl_vintfunc_t *rl_prep_term_function;
static rl_voidfunc_t *rl_deprep_term_function;
#endif /* (RL_READLINE_VERSION < 0x0201) */

#if (RL_READLINE_VERSION < 0x0202)
/* features introduced by GNU Readline 2.2 */
static int
rl_unbind_function_in_map (func, map)
     rl_command_func_t *func;
     Keymap map;
{
  register int i, rval;

  for (i = rval = 0; i < KEYMAP_SIZE; i++)
    {
      if (map[i].type == ISFUNC && map[i].function == func)
	{
	  map[i].function = (rl_command_func_t *)NULL;
	  rval = 1;
	}
    }
  return rval;
}

static int
rl_unbind_command_in_map (command, map)
     const char *command;
     Keymap map;
{
  rl_command_func_t *func;

  func = rl_named_function (command);
  if (func == 0)
    return 0;
  return (rl_unbind_function_in_map (func, map));
}
#endif /* (RL_READLINE_VERSION < 0x0202) */

#if (RL_VERSION_MAJOR < 4)
/* documented by Readline 4.0 but already implemented since 2.0 or 2.1. */
extern void rl_extend_line_buffer PARAMS((int));
extern char **rl_funmap_names PARAMS((void));
extern int rl_add_funmap_entry PARAMS((CONST char *, rl_command_func_t *));
extern void rl_prep_terminal PARAMS((int));
extern void rl_deprep_terminal PARAMS((void));
extern int rl_execute_next PARAMS((int));

/* features introduced by GNU Readline 4.0 */
/* dummy variable/function definition */
static int rl_erase_empty_line = 0;
static rl_hook_func_t *rl_pre_input_hook;
static int rl_catch_signals = 1;
static int rl_catch_sigwinch = 1;
static rl_compdisp_func_t *rl_completion_display_matches_hook;

static void rl_display_match_list(){}
static void rl_cleanup_after_signal(){}
static void rl_free_line_state(){}
static void rl_reset_after_signal(){}
static void rl_resize_terminal(){}

/*
 * Before GNU Readline Library Version 4.0, rl_save_prompt() was
 * _rl_save_prompt and rl_restore_prompt() was _rl_restore_prompt().
 */
extern void _rl_save_prompt PARAMS((void));
extern void _rl_restore_prompt PARAMS((void));
static void rl_save_prompt() { _rl_save_prompt(); }
static void rl_restore_prompt() { _rl_restore_prompt(); }
#endif /* (RL_VERSION_MAJOR < 4) */

#if (RL_READLINE_VERSION < 0x0401)
/* features introduced by GNU Readline 4.1 */
static int rl_already_prompted = 0;
static int rl_num_chars_to_read = 0;
static int rl_gnu_readline_p = 1;
static int rl_on_new_line_with_prompt(){ return 0; }
#endif /* (RL_READLINE_VERSION < 0x0401) */

#if (RL_READLINE_VERSION < 0x0402)
/* documented by 4.2 but implemented since 2.1 */
extern int rl_explicit_arg;
extern int rl_numeric_arg;
extern int rl_editing_mode;

/* features introduced by GNU Readline 4.2 */
static int rl_set_prompt(){ return 0; }
static int rl_clear_pending_input(){ return 0; }
static int rl_set_keyboard_input_timeout(){ return 0; }
static int rl_alphabetic(){ return 0; }
static int rl_set_paren_blink_timeout(){ return 0; }
static void rl_set_screen_size(int row, int col){}
static void rl_get_screen_size(int *row, int *col){
  *row = *col = 0;
}

static char *rl_executing_macro = NULL; /* was _rl_executing_macro */
static int rl_readline_state = 2; /* RL_STATE_INITIALIZED */
static rl_icppfunc_t *rl_directory_rewrite_hook = NULL;
static char *history_word_delimiters = " \t\n;&()|<>";

/* documented by 4.2a but implemented since 2.1 */
extern char *rl_get_termcap PARAMS((const char *));

/* features introduced by GNU Readline 4.2a */
static int rl_readline_version = RL_READLINE_VERSION;

/* Provide backwards-compatible entry points for old function names
   which are rename from readline-4.2. */
static void
rl_free_undo_list ()
{
  free_undo_list ();
}

static int
rl_crlf ()
{
  return crlf ();
}

static void
rl_tty_set_default_bindings (keymap)
Keymap keymap;
{
#if (RL_VERSION_MAJOR >= 4)
  rltty_set_default_bindings (keymap);
#endif /* (RL_VERSION_MAJOR >= 4) */
}

static int
rl_ding ()
{
  return ding ();
}

static char **
rl_completion_matches (s, f)
     char *s;
     rl_compentry_func_t *f;
{
  return completion_matches (s, f);
}

static char *
rl_username_completion_function (s, i)
     const char *s;
     int i;
{
  return username_completion_function ((char *)s, i);
}

static char *
rl_filename_completion_function (s, i)
     const char *s;
     int i;
{
  return filename_completion_function ((char *)s, i);
}
#endif /* (RL_READLINE_VERSION >= 0x0402) */

#if (RL_READLINE_VERSION < 0x0403)
/* features introduced by GNU Readline 4.3 */
static int rl_completion_suppress_append = 0;
static int rl_completion_mark_symlink_dirs = 0;
static void rl_replace_line(){}
static int rl_completion_mode(){ return 0; }

/* documented by 6.0 but implemented since 4.3 */
struct readline_state { };
static int rl_save_state(struct readline_state *sp){ return 0; }
static int rl_restore_state(struct readline_state *sp){ return 0; }
#endif /* (RL_READLINE_VERSION < 0x0403) */

typedef struct readline_state readline_state_t; /* for typemap */

#if (RL_VERSION_MAJOR < 5)
/* features introduced by GNU Readline 5.0 */
static rl_cpvfunc_t *rl_completion_word_break_hook = NULL;
static int rl_completion_quote_character = 0;
static int rl_completion_suppress_quote = 0;
static int rl_completion_found_quote = 0;
static int history_write_timestamps = 0;
static int rl_bind_key_if_unbound_in_map(){ return 0; }
static int rl_bind_keyseq_in_map(){ return 0; }
static int rl_bind_keyseq_if_unbound_in_map(){ return 0; }
static void rl_tty_unset_default_bindings(){}
static void add_history_time(){}
static time_t history_get_time(){ return 0; }
#endif /* (RL_VERSION_MAJOR < 5) */

#if (RL_READLINE_VERSION < 0x0501)
/* features introduced by GNU Readline 5.1 */
static int rl_prefer_env_winsize = 0;
static t_utf8 rl_variable_value(CONST char * v){ return NULL; }
static void rl_reset_screen_size(){}
#endif /* (RL_READLINE_VERSION < 0x0501) */

#if (RL_VERSION_MAJOR < 6)
/* documented by 6.0 but implemented since 2.1 */
extern char *rl_display_prompt;
/* features introduced by GNU Readline 6.0 */
static int rl_sort_completion_matches = 1;
static int rl_completion_invoking_key = 0;
static void rl_echo_signal_char(int sig){}
#endif /* (RL_VERSION_MAJOR < 6) */

#if (RL_READLINE_VERSION < 0x0601)
/* features introduced by GNU Readline 6.1 */
static rl_dequote_func_t *rl_filename_rewrite_hook;

/* Convenience function that discards, then frees, MAP. */
static void xfree(void *);
static void
rl_free_keymap (map)
     Keymap map;
{
  rl_discard_keymap (map);
  xfree ((char *)map);
}
#endif /* (RL_READLINE_VERSION < 0x0601) */

/* No feature to be handled by this module is introduced by GNU Readline 6.2 */

#if (RL_READLINE_VERSION < 0x0603)
/* documented by 6.3 but implemented since 2.1 */
extern int rl_key_sequence_length;
#if (RL_READLINE_VERSION > 0x0600)
/* externed by 6.3 but implemented since 6.1 */
extern void rl_free_keymap PARAMS((Keymap));
#endif
/* features introduced by GNU Readline 6.3 */
static rl_hook_func_t *rl_signal_event_hook = NULL;
static rl_hook_func_t *rl_input_available_hook = NULL;
static int rl_executing_key = 0;
static char *rl_executing_keyseq = NULL;
static int rl_change_environment = 1;
static rl_icppfunc_t *rl_filename_stat_hook = NULL;

void rl_clear_history (void) {}
/*
  documented by 6.3 but implemented since 2.1
static HISTORY_STATE	*history_get_hitory_state();
static void	*history_set_hitory_state(HISTORY_STATE *state)
 */
#endif /* (RL_READLINE_VERSION < 0x0603) */

#if (RL_READLINE_VERSION < 0x0700)
/* features introduced by GNU Readline 7.0 */
static int rl_clear_visible_line(void) { return 0; }
static int rl_tty_set_echoing(int value) { return 0; }
static void rl_callback_sigcleanup (void) {}
static int rl_pending_signal(void) { return 0; }
static int rl_persistent_signal_handlers = 0;
#endif /* (RL_READLINE_VERSION < 0x0700) */

#if (RL_READLINE_VERSION == 0x0700)
/* not defined in readline.h */
extern int rl_tty_set_echoing PARAMS((int));
#endif /* (RL_READLINE_VERSION == 0x0700) */

/*
 * utility/dummy functions
 */                                                                                
/* from GNU Readline:xmalloc.h */
#ifndef PTR_T
#ifdef __STDC__
#  define PTR_T void *
#else
#  define PTR_T char *
#endif
#endif /* !PTR_T */

/* from GNU Readline:xmalloc.c */
extern PTR_T xmalloc PARAMS((int));
extern char *tgetstr PARAMS((const char *, char **));
extern int tputs PARAMS((const char *, int, int (*)(int)));

/*
 * Using xfree() in GNU Readline Library causes problem with Solaris
 * 2.5.  It seems that the DLL mechanism of Solaris 2.5 links another
 * xfree() that does not do NULL argument check.
 * I choose this as default since some other OSs may have same problem.
 * usemymalloc=n is required.
 */
static void
xfree (string)
     PTR_T string;
{
  if (string)
    free (string);
}

static char *
dupstr(s)			/* duplicate string */
     CONST char * s;
{
  /*
   * Use xmalloc(), because allocated block will be freed in the GNU
   * Readline Library routine.
   * Don't make a macro, because the variable 's' is evaluated twice.
   */
  int len = strlen(s) + 1;
  char *d = xmalloc(len);
  Copy(s, d, len, char);	/* Is Copy() better than strcpy() in XS? */
  return d;
}

/*
 * for tputs XS routine
 */
static char *tputs_ptr;
static int
tputs_char(c)
     int c;
{
  return *tputs_ptr++ = c;
}

/*
 * return name of FUNCTION.
 * I asked Chet Ramey to add this function in readline/bind.c.  But he
 * did not, since he could not find any reasonable excuse.
 */
static const char *
rl_get_function_name (function)
     rl_command_func_t *function;
{
  register int i;

  rl_initialize_funmap ();

  for (i = 0; funmap[i]; i++)
    if (funmap[i]->function == function)
      return ((const char *)funmap[i]->name); /* cast is for oldies */
  return NULL;
}

/*
 * from readline-4.0:complete.c
 * Redefine here since the function defined as static in complete.c.
 * This function is used for default value for rl_filename_quoting_function.
 */
static char * rl_quote_filename PARAMS((char *s, int rtype, char *qcp));

static char *
rl_quote_filename (s, rtype, qcp)
     char *s;
     int rtype;
     char *qcp;
{
  char *r;

  r = xmalloc (strlen (s) + 2);
  *r = *rl_completer_quote_characters;
  strcpy (r + 1, s);
  if (qcp)
    *qcp = *rl_completer_quote_characters;
  return r;
}

/*
 *	string variable table for _rl_store_str(), _rl_fetch_str()
 */

static struct str_vars {
  char **var;
  int accessed;
  int read_only;
} str_tbl[] = {
  /* When you change length of rl_line_buffer, you must call
     rl_extend_line_buffer().  See _rl_store_rl_line_buffer() */
  { &rl_line_buffer,					0, 0 },	/* 0 */
  { &rl_prompt,						0, 1 },	/* 1 */
  { (char **)&rl_library_version,			0, 1 },	/* 2 */
  { (char **)&rl_terminal_name,				0, 0 },	/* 3 */
  { (char **)&rl_readline_name,				0, 0 },	/* 4 */
  
  { (char **)&rl_basic_word_break_characters,		0, 0 },	/* 5 */
  { (char **)&rl_basic_quote_characters,		0, 0 },	/* 6 */
  { (char **)&rl_completer_word_break_characters,	0, 0 },	/* 7 */
  { (char **)&rl_completer_quote_characters,		0, 0 },	/* 8 */
  { (char **)&rl_filename_quote_characters,		0, 0 },	/* 9 */
  { (char **)&rl_special_prefixes,			0, 0 },	/* 10 */
  
  { &history_no_expand_chars,				0, 0 },	/* 11 */
  { &history_search_delimiter_chars,			0, 0 },	/* 12 */

  { &rl_executing_macro,				0, 1 },	/* 13 */
  { &history_word_delimiters,				0, 0 },	/* 14 */
  { &rl_display_prompt,					0, 0 },	/* 15 */
  { &rl_executing_keyseq,				0, 1 }	/* 16 */
};

/*
 *	integer variable table for _rl_store_int(), _rl_fetch_int()
 */

static struct int_vars {
  int *var;
  int charp;
  int read_only;
  int ulong;
} int_tbl[] = {
  { &rl_point,					0, 0, 0},	/* 0 */
  { &rl_end,					0, 0, 0},	/* 1 */
  { &rl_mark,					0, 0, 0},	/* 2 */
  { &rl_done,					0, 0, 0},	/* 3 */
  { &rl_pending_input,				0, 0, 0},	/* 4 */

  { &rl_completion_query_items,			0, 0, 0},	/* 5 */
  { &rl_completion_append_character,		0, 0, 0},	/* 6 */
  { &rl_ignore_completion_duplicates,		0, 0, 0},	/* 7 */
  { &rl_filename_completion_desired,		0, 0, 0},	/* 8 */
  { &rl_filename_quoting_desired,		0, 0, 0},	/* 9 */
  { &rl_inhibit_completion,			0, 0, 0},	/* 10 */

  { &history_base,				0, 0, 0},	/* 11 */
  { &history_length,				0, 0, 0},	/* 12 */
#if (RL_READLINE_VERSION >= 0x0402)
  { &history_max_entries,			0, 1, 0},	/* 13 */
#else /* (RL_READLINE_VERSION < 0x0402) */
  { &max_input_history,				0, 1, 0},	/* 13 */
#endif /* (RL_READLINE_VERSION < 0x0402) */
  { &history_write_timestamps,			0, 0, 0},	/* 14 */
  { (int *)&history_expansion_char,		1, 0, 0},	/* 15 */
  { (int *)&history_subst_char,			1, 0, 0},	/* 16 */
  { (int *)&history_comment_char,		1, 0, 0},	/* 17 */
  { &history_quotes_inhibit_expansion,		0, 0, 0},	/* 18 */
  { &rl_erase_empty_line,			0, 0, 0},	/* 19 */
  { &rl_catch_signals,				0, 0, 0},	/* 20 */
  { &rl_catch_sigwinch,				0, 0, 0},	/* 21 */
  { &rl_already_prompted,			0, 0, 0},	/* 22 */
  { &rl_num_chars_to_read,			0, 0, 0},	/* 23 */
  { &rl_dispatching,				0, 0, 0},	/* 24 */
  { &rl_gnu_readline_p,				0, 1, 0},	/* 25 */
#if (RL_READLINE_VERSION >= 0x0700)
  /*
   * rl_readline_state becomes unsigned long on RL 7.0
   * It still holds 32bit value.
   */
  { (int *)&rl_readline_state,			0, 0, 1},	/* 26 */
#else
  { &rl_readline_state,				0, 0, 0},	/* 26 */
#endif
  { &rl_explicit_arg,				0, 1, 0},	/* 27 */
  { &rl_numeric_arg,				0, 1, 0},	/* 28 */
  { &rl_editing_mode,				0, 1, 0},	/* 29 */
  { &rl_attempted_completion_over,		0, 0, 0},	/* 30 */
  { &rl_completion_type,			0, 0, 0},	/* 31 */
  { &rl_readline_version,			0, 1, 0},	/* 32 */
  { &rl_completion_suppress_append,		0, 0, 0},	/* 33 */
  { &rl_completion_quote_character,		0, 1, 0},	/* 34 */
  { &rl_completion_suppress_quote,		0, 0, 0},	/* 35 */
  { &rl_completion_found_quote,			0, 1, 0},	/* 36 */
  { &rl_completion_mark_symlink_dirs,		0, 0, 0},	/* 37 */
  { &rl_prefer_env_winsize,			0, 0, 0},	/* 38 */
  { &rl_sort_completion_matches,		0, 0, 0},	/* 39 */
  { &rl_completion_invoking_key,		0, 1, 0},	/* 40 */
  { &rl_executing_key,				0, 1, 0},	/* 41 */
  { &rl_key_sequence_length,			0, 1, 0},	/* 42 */
  { &rl_change_environment,			0, 0, 0},	/* 43 */
  { &rl_persistent_signal_handlers,		0, 0, 0},	/* 44 */
  { &utf8_mode,					0, 0, 0}	/* 45 */
};

/*
 *	function pointer variable table for _rl_store_function(),
 *	_rl_fetch_funtion()
 */
static int startup_hook_wrapper PARAMS((void));
static int event_hook_wrapper PARAMS((void));
static int getc_function_wrapper PARAMS((PerlIO *));
static void redisplay_function_wrapper PARAMS((void));
static char *completion_entry_function_wrapper PARAMS((const char *, int));;
static char **attempted_completion_function_wrapper PARAMS((char *, int, int));
static char *filename_quoting_function_wrapper PARAMS((char *text, int match_type,
						    char *quote_pointer));
static char *filename_dequoting_function_wrapper PARAMS((char *text, int quote_char));
static int char_is_quoted_p_wrapper PARAMS((char *text, int index));
static void ignore_some_completions_function_wrapper PARAMS((char **matches));
static int directory_completion_hook_wrapper PARAMS((char **textp));
static int history_inhibit_expansion_function_wrapper PARAMS((char *str, int i));
static int pre_input_hook_wrapper PARAMS((void));
static void completion_display_matches_hook_wrapper PARAMS((char **matches,
							 int len, int max));
static char *completion_word_break_hook_wrapper PARAMS((void));
static int prep_term_function_wrapper PARAMS((int meta_flag));
static int deprep_term_function_wrapper PARAMS((void));
static int directory_rewrite_hook_wrapper PARAMS((char **dirnamep));
static char *filename_rewrite_hook_wrapper PARAMS((char *text, int quote_char));
static int signal_event_hook_wrapper PARAMS((void));
static int input_available_hook_wrapper PARAMS((void));
static int filename_stat_hook_wrapper PARAMS((char **fnamep));

enum { STARTUP_HOOK, EVENT_HOOK, GETC_FN, REDISPLAY_FN,
       CMP_ENT, ATMPT_COMP,
       FN_QUOTE, FN_DEQUOTE, CHAR_IS_QUOTEDP,
       IGNORE_COMP, DIR_COMP, HIST_INHIBIT_EXP,
       PRE_INPUT_HOOK, COMP_DISP_HOOK, COMP_WD_BRK_HOOK,
       PREP_TERM, DEPREP_TERM, DIR_REWRITE, FN_REWRITE,
       SIG_EVT, INP_AVL, FN_STAT
};

typedef int XFunction ();
static struct fn_vars {
  XFunction **rlfuncp;		/* GNU Readline Library variable */
  XFunction *defaultfn;		/* default function */
  XFunction *wrapper;		/* wrapper function */
  SV *callback;			/* Perl function */
} fn_tbl[] = {
  { &rl_startup_hook,	NULL,	startup_hook_wrapper,	NULL },	/* 0 */
  { &rl_event_hook,	NULL,	event_hook_wrapper,	NULL },	/* 1 */
  { &rl_getc_function,	rl_getc, getc_function_wrapper,	NULL },	/* 2 */
  {								
    (XFunction **)&rl_redisplay_function,			/* 3 */
    (XFunction *)rl_redisplay,
    (XFunction *)redisplay_function_wrapper,
    NULL
  },
  {
    (XFunction **)&rl_completion_entry_function,		/* 4 */
    NULL,
    (XFunction *)completion_entry_function_wrapper,		
    NULL
  },
  {
    (XFunction **)&rl_attempted_completion_function,		/* 5 */
    NULL,
    (XFunction *)attempted_completion_function_wrapper,
    NULL
  },
  {
    (XFunction **)&rl_filename_quoting_function,		/* 6 */
    (XFunction *)rl_quote_filename,
    (XFunction *)filename_quoting_function_wrapper,
    NULL
  },
  {
    (XFunction **)&rl_filename_dequoting_function,		/* 7 */
    NULL,
    (XFunction *)filename_dequoting_function_wrapper,
    NULL
  },
  {
    (XFunction **)&rl_char_is_quoted_p,				/* 8 */
    NULL,
    (XFunction *)char_is_quoted_p_wrapper,
    NULL
  },
  {
    (XFunction **)&rl_ignore_some_completions_function,		/* 9 */
    NULL,
    (XFunction *)ignore_some_completions_function_wrapper,
    NULL
  },
  {
    (XFunction **)&rl_directory_completion_hook,		/* 10 */
    NULL,
    (XFunction *)directory_completion_hook_wrapper,
    NULL
  },
  {
    (XFunction **)&history_inhibit_expansion_function,		/* 11 */
    NULL,
    (XFunction *)history_inhibit_expansion_function_wrapper,
    NULL
  },
  { &rl_pre_input_hook,	NULL,	pre_input_hook_wrapper,	NULL },	/* 12 */
  {
    (XFunction **)&rl_completion_display_matches_hook,		/* 13 */
    NULL,
    (XFunction *)completion_display_matches_hook_wrapper,
    NULL
  },
  {
    (XFunction **)&rl_completion_word_break_hook,		/* 14 */
    NULL,
    (XFunction *)completion_word_break_hook_wrapper,
    NULL
  },
  {
    (XFunction **)&rl_prep_term_function,			/* 15 */
    (XFunction *)rl_prep_terminal,
    (XFunction *)prep_term_function_wrapper,
    NULL
  },
  {
    (XFunction **)&rl_deprep_term_function,			/* 16 */
    (XFunction *)rl_deprep_terminal,
    (XFunction *)deprep_term_function_wrapper,
    NULL
  },
  {
    (XFunction **)&rl_directory_rewrite_hook,			/* 17 */
    NULL,
    (XFunction *)directory_rewrite_hook_wrapper,
    NULL
  },
  {
    (XFunction **)&rl_filename_rewrite_hook,			/* 18 */
    NULL,
    (XFunction *)filename_rewrite_hook_wrapper,
    NULL
  },
  {
    (XFunction **)&rl_signal_event_hook,			/* 19 */
    NULL,
    (XFunction *)signal_event_hook_wrapper,
    NULL
  },
  {
    (XFunction **)&rl_input_available_hook,			/* 20 */
    NULL,
    (XFunction *)input_available_hook_wrapper,
    NULL
  },
  {
    (XFunction **)&rl_filename_stat_hook,			/* 21 */
    NULL,
    (XFunction *)filename_stat_hook_wrapper,
    NULL
  }
};

/*
 * Perl function wrappers
 */

/*
 * common utility wrappers
 */
/* for rl_voidfunc_t : void fn(void) */
static int
voidfunc_wrapper(type)
     int type;
{
  dSP;
  int count;
  int ret;
  SV *svret;

  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  count = call_sv(fn_tbl[type].callback, G_SCALAR);
  SPAGAIN;

  if (count != 1)
    croak("Gnu.xs:voidfunc_wrapper: Internal error\n");

  svret = POPs;
  ret = SvIOK(svret) ? SvIV(svret) : -1;
  PUTBACK;
  FREETMPS;
  LEAVE;
  return ret;
}

/* for rl_vintfunc_t : void fn(int) */
static int
vintfunc_wrapper(type, arg)
     int type;
     int arg;
{
  dSP;
  int count;
  int ret;
  SV *svret;

  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  XPUSHs(sv_2mortal(newSViv(arg)));
  PUTBACK;
  count = call_sv(fn_tbl[type].callback, G_SCALAR);
  SPAGAIN;

  if (count != 1)
    croak("Gnu.xs:vintfunc_wrapper: Internal error\n");

  svret = POPs;
  ret = SvIOK(svret) ? SvIV(svret) : -1;
  PUTBACK;
  FREETMPS;
  LEAVE;
  return ret;
}

/* for rl_vcpfunc_t  : void fn(char *) */
#if 0
static int
vcpfunc_wrapper(type, text)
     int type;
     char *text;
{
  dSP;
  int count;
  int ret;
  SV *svret;
  
  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  if (text) {
    XPUSHs(sv_2mortal(newSVpv(text, 0)));
  } else {
    XPUSHs(&PL_sv_undef);
  }
  PUTBACK;

  count = call_sv(fn_tbl[type].callback, G_SCALAR);
  SPAGAIN;

  if (count != 1)
    croak("Gnu.xs:vcpfunc_wrapper: Internal error\n");

  svret = POPs;
  ret = SvIOK(svret) ? SvIV(svret) : -1;
  PUTBACK;
  FREETMPS;
  LEAVE;
  return ret;
}
#endif

/* for rl_vcppfunc_t : void fn(char **) */
#if 0
static int
vcppfunc_wrapper(type, arg)
     int type;
     char **arg;
{
  dSP;
  int count;
  SV *sv;
  int ret;
  SV *svret;
  char *rstr;
  
  ENTER;
  SAVETMPS;

  if (arg && *arg) {
    sv = sv_2mortal(newSVpv(*arg, 0));
  } else {
    sv = &PL_sv_undef;
  }

  PUSHMARK(sp);
  XPUSHs(sv);
  PUTBACK;

  count = call_sv(fn_tbl[type].callback, G_SCALAR);

  SPAGAIN;

  if (count != 1)
    croak("Gnu.xs:vcppfunc_wrapper: Internal error\n");

  svret = POPs;
  ret = SvIOK(svret) ? SvIV(svret) : -1;

  rstr = SvPV(sv, PL_na);
  if (strcmp(*arg, rstr) != 0) {
    xfree(*arg);
    *arg = dupstr(rstr);
  }

  PUTBACK;
  FREETMPS;
  LEAVE;
  return ret;
}
#endif

/* for rl_hook_func_t, rl_ivoidfunc_t : int fn(void) */
static int
hook_func_wrapper(type)
     int type;
{
  dSP;
  int count;
  int ret;

  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  count = call_sv(fn_tbl[type].callback, G_SCALAR);
  SPAGAIN;

  if (count != 1)
    croak("Gnu.xs:hook_func_wrapper: Internal error\n");

  ret = POPi;			/* warns unless integer */
  PUTBACK;
  FREETMPS;
  LEAVE;
  return ret;
}

/* for rl_intfunc_t  : int fn(int) */
#if 0
static int
intfunc_wrapper(type, arg)
     int type;
     int arg;
{
  dSP;
  int count;
  int ret;

  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  XPUSHs(sv_2mortal(newSViv(arg)));
  PUTBACK;
  count = call_sv(fn_tbl[type].callback, G_SCALAR);
  SPAGAIN;

  if (count != 1)
    croak("Gnu.xs:intfunc_wrapper: Internal error\n");

  ret = POPi;			/* warns unless integer */
  PUTBACK;
  FREETMPS;
  LEAVE;
  return ret;
}
#endif

/* for rl_icpfunc_t : int fn(char *) */
#if 0
static int
icpfunc_wrapper(type, text)
     int type;
     char *text;
{
  dSP;
  int count;
  int ret;
  
  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  if (text) {
    XPUSHs(sv_2mortal(newSVpv(text, 0)));
  } else {
    XPUSHs(&PL_sv_undef);
  }
  PUTBACK;

  count = call_sv(fn_tbl[type].callback, G_SCALAR);

  SPAGAIN;

  if (count != 1)
    croak("Gnu.xs:icpfunc_wrapper: Internal error\n");

  ret = POPi;			/* warns unless integer */
  PUTBACK;
  FREETMPS;
  LEAVE;
  return ret;
}
#endif

/* for rl_icppfunc_t : int fn(char **) */
static int
icppfunc_wrapper(type, arg)
     int type;
     char **arg;
{
  dSP;
  int count;
  SV *sv;
  int ret;
  char *rstr;
  
  ENTER;
  SAVETMPS;

  if (arg && *arg) {
    sv = sv_2mortal(newSVpv(*arg, 0));
  } else {
    sv = &PL_sv_undef;
  }

  PUSHMARK(sp);
  XPUSHs(sv);
  PUTBACK;

  count = call_sv(fn_tbl[type].callback, G_SCALAR);

  SPAGAIN;

  if (count != 1)
    croak("Gnu.xs:icppfunc_wrapper: Internal error\n");

  ret = POPi;

  rstr = SvPV(sv, PL_na);
  if (strcmp(*arg, rstr) != 0) {
    xfree(*arg);
    *arg = dupstr(rstr);
  }

  PUTBACK;
  FREETMPS;
  LEAVE;
  return ret;
}

/* for rl_cpvfunc_t : (char *)fn(void) */
static char *
cpvfunc_wrapper(type)
     int type;
{
  dSP;
  int count;
  char *str;
  SV *svret;
  
  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  count = call_sv(fn_tbl[type].callback, G_SCALAR);
  SPAGAIN;

  if (count != 1)
    croak("Gnu.xs:cpvfunc_wrapper: Internal error\n");

  svret = POPs;
  str = SvOK(svret) ? dupstr(SvPV(svret, PL_na)) : NULL;
  PUTBACK;
  FREETMPS;
  LEAVE;
  return str;
}

/* for rl_cpifunc_t   : (char *)fn(int) */
#if 0
static char *
cpifunc_wrapper(type, arg)
     int type;
     int arg;
{
  dSP;
  int count;
  char *str;
  SV *svret;
  
  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  XPUSHs(sv_2mortal(newSViv(arg)));
  PUTBACK;
  count = call_sv(fn_tbl[type].callback, G_SCALAR);
  SPAGAIN;

  if (count != 1)
    croak("Gnu.xs:cpifunc_wrapper: Internal error\n");

  svret = POPs;
  str = SvOK(svret) ? dupstr(SvPV(svret, PL_na)) : NULL;
  PUTBACK;
  FREETMPS;
  LEAVE;
  return str;
}
#endif

/* for rl_cpcpfunc_t  : (char *)fn(char *) */
#if 0
static char *
cpcpfunc_wrapper(type, text)
     int type;
     char *text;
{
  dSP;
  int count;
  char *str;
  SV *svret;
  
  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  if (text) {
    XPUSHs(sv_2mortal(newSVpv(text, 0)));
  } else {
    XPUSHs(&PL_sv_undef);
  }
  PUTBACK;

  count = call_sv(fn_tbl[type].callback, G_SCALAR);
  SPAGAIN;

  if (count != 1)
    croak("Gnu.xs:cpcpfunc_wrapper: Internal error\n");

  svret = POPs;
  str = SvOK(svret) ? dupstr(SvPV(svret, PL_na)) : NULL;
  PUTBACK;
  FREETMPS;
  LEAVE;
  return str;
}
#endif

/* for rl_cpcppfunc_t : (char *)fn(char **) */
#if 0
static char *
cpcppfunc_wrapper(type, arg)
     int type;
     char **arg;
{
  dSP;
  int count;
  SV *sv;
  char *str;
  SV *svret;
  char *rstr;
  
  ENTER;
  SAVETMPS;

  if (arg && *arg) {
    sv = sv_2mortal(newSVpv(*arg, 0));
  } else {
    sv = &PL_sv_undef;
  }

  PUSHMARK(sp);
  XPUSHs(sv);
  PUTBACK;

  count = call_sv(fn_tbl[type].callback, G_SCALAR);

  SPAGAIN;

  if (count != 1)
    croak("Gnu.xs:cpcppfunc_wrapper: Internal error\n");

  svret = POPs;
  str = SvOK(svret) ? dupstr(SvPV(svret, PL_na)) : NULL;

  rstr = SvPV(sv, PL_na);
  if (strcmp(*arg, rstr) != 0) {
    xfree(*arg);
    *arg = dupstr(rstr);
  }

  PUTBACK;
  FREETMPS;
  LEAVE;
  return str;
}
#endif

/*
 * for rl_icpintfunc_t : int fn(char *, int)
 */
static int
icpintfunc_wrapper(type, text, index)
     int type;
     char *text;
     int index;
{
  dSP;
  int count;
  int ret;
  
  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  if (text) {
    XPUSHs(sv_2mortal_utf8(newSVpv(text, 0)));
  } else {
    XPUSHs(&PL_sv_undef);
  }
  XPUSHs(sv_2mortal(newSViv(index)));
  PUTBACK;

  count = call_sv(fn_tbl[type].callback, G_SCALAR);

  SPAGAIN;

  if (count != 1)
    croak("Gnu.xs:icpintfunc_wrapper: Internal error\n");

  ret = POPi;			/* warns unless integer */
  PUTBACK;
  FREETMPS;
  LEAVE;
  return ret;
}

/*
 * for rl_dequote_func_t : (char *)fn(char *, int)
 */
static char *
dequoting_function_wrapper(type, text, quote_char)
     int type;
     char *text;
     int quote_char;
{
  dSP;
  int count;
  SV *replacement;
  char *str;
  
  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  if (text) {
    XPUSHs(sv_2mortal_utf8(newSVpv(text, 0)));
  } else {
    XPUSHs(&PL_sv_undef);
  }
  XPUSHs(sv_2mortal(newSViv(quote_char)));
  PUTBACK;

  count = call_sv(fn_tbl[type].callback, G_SCALAR);

  SPAGAIN;

  if (count != 1)
    croak("Gnu.xs:dequoting_function_wrapper: Internal error\n");

  replacement = POPs;
  str = SvOK(replacement) ? dupstr(SvPV(replacement, PL_na)) : NULL;

  PUTBACK;
  FREETMPS;
  LEAVE;
  return str;
}

/*
 * Specific wrappers for each variable
 */
static int
startup_hook_wrapper()		{ return voidfunc_wrapper(STARTUP_HOOK); }
static int
event_hook_wrapper()		{ return voidfunc_wrapper(EVENT_HOOK); }

static int
getc_function_wrapper(fp)
     PerlIO *fp;
{
  /*
   * 'PerlIO *fp' is ignored.  Use rl_instream instead in the getc_function.
   * How can I pass 'PerlIO *fp'?
   */
  return voidfunc_wrapper(GETC_FN);
}

static void
redisplay_function_wrapper()	{ voidfunc_wrapper(REDISPLAY_FN); }

/*
 * call a perl function as rl_completion_entry_function
 * for rl_compentry_func_t : (char *)fn(const char *, int)
 */
static char *
completion_entry_function_wrapper(text, state)
     const char *text;
     int state;
{
  dSP;
  int count;
  SV *match;
  char *str;
  
  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  if (text) {
    XPUSHs(sv_2mortal_utf8(newSVpv(text, 0)));
  } else {
    XPUSHs(&PL_sv_undef);
  }
  XPUSHs(sv_2mortal(newSViv(state)));
  PUTBACK;

  count = call_sv(fn_tbl[CMP_ENT].callback, G_SCALAR);

  SPAGAIN;

  if (count != 1)
    croak("Gnu.xs:completion_entry_function_wrapper: Internal error\n");

  match = POPs;
  str = SvOK(match) ? dupstr(SvPV(match, PL_na)) : NULL;

  PUTBACK;
  FREETMPS;
  LEAVE;
  return str;
}

/*
 * call a perl function as rl_attempted_completion_function
 * for rl_completion_func_t : (char **)fn(const char *, int, int)
 */

static char **
attempted_completion_function_wrapper(text, start, end)
     char *text;
     int start;
     int end;
{
  dSP;
  int count;
  char **matches;
  
  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  if (text) {
    XPUSHs(sv_2mortal_utf8(newSVpv(text, 0)));
  } else {
    XPUSHs(&PL_sv_undef);
  }
  if (rl_line_buffer) {
    XPUSHs(sv_2mortal_utf8(newSVpv(rl_line_buffer, 0)));
  } else {
    XPUSHs(&PL_sv_undef);
  }
  XPUSHs(sv_2mortal(newSViv(start)));
  XPUSHs(sv_2mortal(newSViv(end)));
  PUTBACK;

  count = call_sv(fn_tbl[ATMPT_COMP].callback, G_ARRAY);

  SPAGAIN;

  /* cf. ignore_some_completions_function_wrapper() */
  if (count > 0) {
    int i;
    int dopack = -1;

    /*
     * The returned array may contain some undef items.
     * Pack the array in such case.
     */
    matches = (char **)xmalloc (sizeof(char *) * (count + 1));
    matches[count] = NULL;
    for (i = count - 1; i >= 0; i--) {
      SV *v = POPs;
      if (SvOK(v)) {
	matches[i] = dupstr(SvPV(v, PL_na));
      } else {
	matches[i] = NULL;
	if (i != 0)
	  dopack = i;		/* lowest index of hole */
      }
    }
    /* pack undef items */
    if (dopack > 0) {		/* don't pack matches[0] */
      int j = dopack;
      for (i = dopack; i < count; i++) {
	if (matches[i])
	  matches[j++] = matches[i];
      }
      matches[count = j] = NULL;
    }
    if (count == 2) {	/* only one match */
      xfree(matches[0]);
      matches[0] = matches[1];
      matches[1] = NULL;
    } else if (count == 1 && !matches[0]) { /* in case of a list of undef */
      xfree(matches);
      matches = NULL;
    }
  } else {
    matches = NULL;
  }

  PUTBACK;
  FREETMPS;
  LEAVE;

  return matches;
}

/*
 * call a perl function as rl_filename_quoting_function
 * for rl_quote_func_t : (char *)fn(char *, int, char *)
 */

static char *
filename_quoting_function_wrapper(text, match_type, quote_pointer)
     char *text;
     int match_type;
     char *quote_pointer;
{
  dSP;
  int count;
  SV *replacement;
  char *str;
  
  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  if (text) {
    XPUSHs(sv_2mortal_utf8(newSVpv(text, 0)));
  } else {
    XPUSHs(&PL_sv_undef);
  }
  XPUSHs(sv_2mortal(newSViv(match_type)));
  if (quote_pointer) {
    XPUSHs(sv_2mortal(newSVpv(quote_pointer, 0)));
  } else {
    XPUSHs(&PL_sv_undef);
  }
  PUTBACK;

  count = call_sv(fn_tbl[FN_QUOTE].callback, G_SCALAR);

  SPAGAIN;

  if (count != 1)
    croak("Gnu.xs:filename_quoting_function_wrapper: Internal error\n");

  replacement = POPs;
  str = SvOK(replacement) ? dupstr(SvPV(replacement, PL_na)) : NULL;

  PUTBACK;
  FREETMPS;
  LEAVE;
  return str;
}

static char *
filename_dequoting_function_wrapper(text, quote_char)
     char *text;
     int quote_char;
{
  return dequoting_function_wrapper(FN_DEQUOTE, text, quote_char);
}  

static int
char_is_quoted_p_wrapper(text, index)
     char *text;
     int index;
{
  return icpintfunc_wrapper(CHAR_IS_QUOTEDP, text, index);
}

/*
 * call a perl function as rl_ignore_some_completions_function
 * for rl_compignore_func_t : int fn(char **)
 */

static void
ignore_some_completions_function_wrapper(matches)
     char **matches;
{
  dSP;
  int count, i, only_one_match;
  
  only_one_match = matches[1] == NULL ? 1 : 0;

  ENTER;
  SAVETMPS;

  PUSHMARK(sp);

  /* matches[0] is the maximal matching substring.  So it may NULL, even rest
   * of matches[] has values. */
  if (matches[0]) {
    XPUSHs(sv_2mortal_utf8(newSVpv(matches[0], 0)));
    /* xfree(matches[0]);*/
  } else {
    XPUSHs(&PL_sv_undef);
  }
  for (i = 1; matches[i]; i++) {
      XPUSHs(sv_2mortal_utf8(newSVpv(matches[i], 0)));
      xfree(matches[i]);
  }
  /*xfree(matches);*/
  PUTBACK;

  count = call_sv(fn_tbl[IGNORE_COMP].callback, G_ARRAY);

  SPAGAIN;

  if (only_one_match) {
    if (count == 0) {		/* no match */
      xfree(matches[0]);
      matches[0] = NULL;
    } /* else only one match */
  } else if (count > 0) {
    int i;
    int dopack = -1;

    /*
     * The returned array may contain some undef items.
     * Pack the array in such case.
     */
    matches[count] = NULL;
    for (i = count - 1; i > 0; i--) { /* don't pop matches[0] */
      SV *v = POPs;
      if (SvOK(v)) {
	matches[i] = dupstr(SvPV(v, PL_na));
      } else {
	matches[i] = NULL;
	dopack = i;		/* lowest index of undef */
      }
    }
    /* pack undef items */
    if (dopack > 0) {		/* don't pack matches[0] */
      int j = dopack;
      for (i = dopack; i < count; i++) {
	if (matches[i])
	  matches[j++] = matches[i];
      }
      matches[count = j] = NULL;
    }
    if (count == 1) {		/* no match */
      xfree(matches[0]);
      matches[0] = NULL;
    } else if (count == 2) {	/* only one match */
      xfree(matches[0]);
      matches[0] = matches[1];
      matches[1] = NULL;
    }
  } else {			/* no match */
    xfree(matches[0]);
    matches[0] = NULL;
  }

  PUTBACK;
  FREETMPS;
  LEAVE;
}

static int
directory_completion_hook_wrapper(textp)
     char **textp;
{
  return icppfunc_wrapper(DIR_COMP, textp);
}

static int
history_inhibit_expansion_function_wrapper(text, index)
     char *text;
     int index;
{
  return icpintfunc_wrapper(HIST_INHIBIT_EXP, text, index);
}

static int
pre_input_hook_wrapper() { return voidfunc_wrapper(PRE_INPUT_HOOK); }

#if (RL_VERSION_MAJOR >= 4)
/*
 * call a perl function as rl_completion_display_matches_hook
 * for rl_compdisp_func_t : void fn(char **, int, int)
 */

static void
completion_display_matches_hook_wrapper(matches, len, max)
     char **matches;
     int len;
     int max;
{
  dSP;
  int i;
  AV *av_matches;
  
  /* copy C matches[] array into perl array */
  av_matches = newAV();

  /* matches[0] is the maximal matching substring.  So it may NULL, even rest
   * of matches[] has values. */
  if (matches[0]) {
    av_push(av_matches, sv_2mortal_utf8(newSVpv(matches[0], 0)));
  } else {
    av_push(av_matches, &PL_sv_undef);
  }

  for (i = 1; matches[i]; i++)
    if (matches[i]) {
      av_push(av_matches, sv_2mortal_utf8(newSVpv(matches[i], 0)));
    } else {
      av_push(av_matches, &PL_sv_undef);
    }

  PUSHMARK(sp);
  XPUSHs(sv_2mortal(newRV_inc((SV *)av_matches))); /* push reference of array */
  XPUSHs(sv_2mortal(newSViv(len)));
  XPUSHs(sv_2mortal(newSViv(max)));
  PUTBACK;

  call_sv(fn_tbl[COMP_DISP_HOOK].callback, G_DISCARD);
}
#else /* (RL_VERSION_MAJOR < 4) */
static void
completion_display_matches_hook_wrapper(matches, len, max)
     char **matches;
     int len;
     int max;
{
  /* dummy */
}
#endif /* (RL_VERSION_MAJOR < 4) */

static char *
completion_word_break_hook_wrapper()
{
  return cpvfunc_wrapper(COMP_WD_BRK_HOOK);
}

static int
prep_term_function_wrapper(meta_flag)
     int meta_flag;
{
  return vintfunc_wrapper(PREP_TERM, meta_flag);
}

static int
deprep_term_function_wrapper() { return voidfunc_wrapper(DEPREP_TERM); }

static int
directory_rewrite_hook_wrapper(dirnamep)
     char **dirnamep;
{
  return icppfunc_wrapper(DIR_REWRITE, dirnamep);
}

static char *
filename_rewrite_hook_wrapper(text, quote_char)
     char *text;
     int quote_char;
{
  return dequoting_function_wrapper(FN_REWRITE, text, quote_char);
}  

static int
signal_event_hook_wrapper() { return hook_func_wrapper(SIG_EVT); }

static int
input_available_hook_wrapper() { return hook_func_wrapper(INP_AVL); }

static int
filename_stat_hook_wrapper(fnamep)
     char **fnamep;
{
  return icppfunc_wrapper(FN_STAT, fnamep);
}

/*
 *	If you need more custom functions, define more funntion_wrapper_xx()
 *	and add entry on fntbl[].
 */

static int function_wrapper PARAMS((int count, int key, int id));

static int fw_00(c, k) int c; int k; { return function_wrapper(c, k,  0); }
static int fw_01(c, k) int c; int k; { return function_wrapper(c, k,  1); }
static int fw_02(c, k) int c; int k; { return function_wrapper(c, k,  2); }
static int fw_03(c, k) int c; int k; { return function_wrapper(c, k,  3); }
static int fw_04(c, k) int c; int k; { return function_wrapper(c, k,  4); }
static int fw_05(c, k) int c; int k; { return function_wrapper(c, k,  5); }
static int fw_06(c, k) int c; int k; { return function_wrapper(c, k,  6); }
static int fw_07(c, k) int c; int k; { return function_wrapper(c, k,  7); }
static int fw_08(c, k) int c; int k; { return function_wrapper(c, k,  8); }
static int fw_09(c, k) int c; int k; { return function_wrapper(c, k,  9); }
static int fw_10(c, k) int c; int k; { return function_wrapper(c, k, 10); }
static int fw_11(c, k) int c; int k; { return function_wrapper(c, k, 11); }
static int fw_12(c, k) int c; int k; { return function_wrapper(c, k, 12); }
static int fw_13(c, k) int c; int k; { return function_wrapper(c, k, 13); }
static int fw_14(c, k) int c; int k; { return function_wrapper(c, k, 14); }
static int fw_15(c, k) int c; int k; { return function_wrapper(c, k, 15); }

static struct fnnode {
  rl_command_func_t *wrapper;	/* C wrapper function */
  SV *pfn;			/* Perl function */
} fntbl[] = {
  { fw_00,	NULL },
  { fw_01,	NULL },
  { fw_02,	NULL },
  { fw_03,	NULL },
  { fw_04,	NULL },
  { fw_05,	NULL },
  { fw_06,	NULL },
  { fw_07,	NULL },
  { fw_08,	NULL },
  { fw_09,	NULL },
  { fw_10,	NULL },
  { fw_11,	NULL },
  { fw_12,	NULL },
  { fw_13,	NULL },
  { fw_14,	NULL },
  { fw_15,	NULL }
};

static int
function_wrapper(count, key, id)
     int count;
     int key;
     int id;
{
  dSP;

  PUSHMARK(sp);
  XPUSHs(sv_2mortal(newSViv(count)));
  XPUSHs(sv_2mortal(newSViv(key)));
  PUTBACK;

  call_sv(fntbl[id].pfn, G_DISCARD);

  return 0;
}

static SV *callback_handler_callback = NULL;

static void
callback_handler_wrapper(line)
     char *line;
{
  dSP;

  PUSHMARK(sp);
  if (line) {
    XPUSHs(sv_2mortal_utf8(newSVpv(line, 0)));
  } else {
    XPUSHs(&PL_sv_undef);
  }
  PUTBACK;

  call_sv(callback_handler_callback, G_DISCARD);
}

#if 0 /* 2016/06/07 worked but no advantage */
/* to keep PerlIO given by _rl_store_iostream() */
static PerlIO *perlio_in;
static PerlIO *perlio_out;

/* for rl_getc_function */
static int
trg_getc()
{
  return PerlIO_getc(perlio_in);
}
/* for rl_input_available_hook */
static int
trg_input_available()
{
  return PerlIO_get_cnt(perlio_in) > 0;
}
#endif


/*
 * make separate name space for low level XS functions and their methods
 */

MODULE = Term::ReadLine::Gnu		PACKAGE = Term::ReadLine::Gnu::XS

 ########################################################################
 #
 #	Gnu Readline Library
 #
 ########################################################################
 #
 #	2.1 Basic Behavior
 #

 # The function name "readline()" is reserved for a method name.

t_utf8_free
rl_readline(prompt = NULL)
	CONST char *	prompt
    PROTOTYPE: ;$
    CODE:
	RETVAL = readline(prompt);
    OUTPUT:
	RETVAL

 #
 #	2.4 Readline Convenience Functions
 #
 #
 #	2.4.1 Naming a Function
 #
rl_command_func_t *
rl_add_defun(name, fn, key = -1)
	CONST char *	name
	SV *		fn
	int key
    PROTOTYPE: $$;$
    CODE:
	{
	  int i;
	  int nentry = sizeof(fntbl)/sizeof(struct fnnode);

	  /* search an empty slot */
	  for (i = 0; i < nentry; i++)
	    if (! fntbl[i].pfn)
	      break;
	  
	  if (i >= nentry) {
	    warn("Gnu.xs:rl_add_defun: custom function table is full. The maximum number of custum function is %d.\n",
		 nentry);
	    XSRETURN_UNDEF;
	  }

	  fntbl[i].pfn = newSVsv(fn);
	  
	  /* rl_add_defun() always returns 0. */
	  rl_add_defun(dupstr(name), fntbl[i].wrapper, key);
	  RETVAL = fntbl[i].wrapper;
	}
    OUTPUT:
	RETVAL

 #
 #	2.4.2 Selection a Keymap
 #
Keymap
rl_make_bare_keymap()
    PROTOTYPE:
	  
Keymap
_rl_copy_keymap(map)
	Keymap map
    PROTOTYPE: $
    CODE:
	RETVAL = rl_copy_keymap(map);
    OUTPUT:
	RETVAL

Keymap
rl_make_keymap()
    PROTOTYPE:

Keymap
_rl_discard_keymap(map)
	Keymap map
    PROTOTYPE: $
    CODE:
	rl_discard_keymap(map);
	RETVAL = map;
    OUTPUT:
	RETVAL

 # comment out until GNU Readline 6.2 will be released.

void
rl_free_keymap(map)
	Keymap map
    PROTOTYPE: $

Keymap
rl_get_keymap()
    PROTOTYPE:

Keymap
_rl_set_keymap(map)
	Keymap map
    PROTOTYPE: $
    CODE:
	rl_set_keymap(map);
	RETVAL = map;
    OUTPUT:
	RETVAL

Keymap
rl_get_keymap_by_name(name)
	CONST char *	name
    PROTOTYPE: $

 # Do not free the string returned.
char *
rl_get_keymap_name(map)
	Keymap map
    PROTOTYPE: $

 #
 #	2.4.3 Binding Keys
 #
int
_rl_bind_key(key, function, map = rl_get_keymap())
	int key
	rl_command_func_t *	function
	Keymap map
    PROTOTYPE: $$;$
    CODE:
	RETVAL = rl_bind_key_in_map(key, function, map);
    OUTPUT:
	RETVAL

int
_rl_bind_key_if_unbound(key, function, map = rl_get_keymap())
	int key
	rl_command_func_t *	function
	Keymap map
    PROTOTYPE: $$;$
    CODE:
	RETVAL = rl_bind_key_if_unbound_in_map(key, function, map);
    OUTPUT:
	RETVAL

int
_rl_unbind_key(key, map = rl_get_keymap())
	int key
	Keymap map
    PROTOTYPE: $;$
    CODE:
	RETVAL = rl_unbind_key_in_map(key, map);
    OUTPUT:
	RETVAL

 # rl_unbind_function_in_map() and rl_unbind_command_in_map() are introduced
 # by readline-2.2.

int
_rl_unbind_function(function, map = rl_get_keymap())
	rl_command_func_t *	function
	Keymap map
    PROTOTYPE: $;$
    CODE:
	RETVAL = rl_unbind_function_in_map(function, map);
    OUTPUT:
	RETVAL

int
_rl_unbind_command(command, map = rl_get_keymap())
	CONST char *	command
	Keymap map
    PROTOTYPE: $;$
    CODE:
	RETVAL = rl_unbind_command_in_map(command, map);
    OUTPUT:
	RETVAL

int
_rl_bind_keyseq(keyseq, function, map = rl_get_keymap())
	const char *keyseq
	rl_command_func_t *	function
	Keymap map
    PROTOTYPE: $$;$
    CODE:
	RETVAL = rl_bind_keyseq_in_map(keyseq, function, map);
    OUTPUT:
	RETVAL

 # rl_set_key() is introduced by readline-4.2 and equivalent with
 # rl_generic_bind(ISFUNC, keyseq, (char *)function, map).
int
_rl_set_key(keyseq, function, map = rl_get_keymap())
	CONST char *	keyseq
	rl_command_func_t *	function
	Keymap map
    PROTOTYPE: $$;$
    CODE:
#if (RL_READLINE_VERSION >= 0x0402)
	RETVAL = rl_set_key(keyseq, function, map);
#else
	RETVAL = rl_generic_bind(ISFUNC, keyseq, (char *)function, map);
#endif
    OUTPUT:
	RETVAL

int
_rl_bind_keyseq_if_unbound(keyseq, function, map = rl_get_keymap())
	const char *keyseq
	rl_command_func_t *	function
	Keymap map
    PROTOTYPE: $$;$
    CODE:
	RETVAL = rl_bind_keyseq_if_unbound_in_map(keyseq, function, map);
    OUTPUT:
	RETVAL

int
_rl_generic_bind_function(keyseq, function, map = rl_get_keymap())
	CONST char *	keyseq
	rl_command_func_t *	function
	Keymap map
    PROTOTYPE: $$;$
    CODE:
	RETVAL = rl_generic_bind(ISFUNC, keyseq, (char *)function, map);
    OUTPUT:
	RETVAL

int
_rl_generic_bind_keymap(keyseq, keymap, map = rl_get_keymap())
	CONST char *	keyseq
	Keymap keymap
	Keymap map
    PROTOTYPE: $$;$
    CODE:
	RETVAL = rl_generic_bind(ISKMAP, keyseq, (char *)keymap, map);
    OUTPUT:
	RETVAL

int
_rl_generic_bind_macro(keyseq, macro, map = rl_get_keymap())
	CONST char *	keyseq
	CONST char *	macro
	Keymap map
    PROTOTYPE: $$;$
    CODE:
	RETVAL = rl_generic_bind(ISMACR, keyseq, dupstr(macro), map);
    OUTPUT:
	RETVAL

void
rl_parse_and_bind(line)
	char *	line
    PROTOTYPE: $
    CODE:
	{
	  char *s = dupstr(line);
	  rl_parse_and_bind(s); /* Some NULs may be inserted in "s". */
	  xfree(s);
	}

int
rl_read_init_file(filename = NULL)
	CONST char *	filename
    PROTOTYPE: ;$

 #
 #	2.4.4 Associating Function Names and Bindings
 #
int
_rl_call_function(function, count = 1, key = -1)
	rl_command_func_t *	function
	int count
	int key
    PROTOTYPE: $;$$
    CODE:
	RETVAL = (*function)(count, key);
    OUTPUT:
	RETVAL

rl_command_func_t *
rl_named_function(name)
	CONST char *	name
    PROTOTYPE: $

 # Do not free the string returned.
const char *
rl_get_function_name(function)
	rl_command_func_t *	function
    PROTOTYPE: $

void
rl_function_of_keyseq(keyseq, map = rl_get_keymap())
	CONST char *	keyseq
	Keymap map
    PROTOTYPE: $;$
    PPCODE:
	{
	  int type;
	  rl_command_func_t *p = rl_function_of_keyseq(keyseq, map, &type);
	  SV *sv;

	  if (p) {
	    sv = sv_newmortal();
	    switch (type) {
	    case ISFUNC:
	      sv_setref_pv(sv, "rl_command_func_tPtr", (void*)p);
	      break;
	    case ISKMAP:
	      sv_setref_pv(sv, "Keymap", (void*)p);
	      break;
	    case ISMACR:
	      if (p) {
		sv_setpv(sv, (char *)p);
	      }
	      break;
	    default:
	      warn("Gnu.xs:rl_function_of_keyseq: illegal type `%d'\n", type);
	      XSRETURN_EMPTY;	/* return NULL list */
	    }
	    EXTEND(sp, 2);
	    PUSHs(sv);
	    PUSHs(sv_2mortal(newSViv(type)));
	  } else
	    ;			/* return NULL list */
	}
	  
void
_rl_invoking_keyseqs(function, map = rl_get_keymap())
	rl_command_func_t *	function
	Keymap map
    PROTOTYPE: $;$
    PPCODE:
	{
	  char **keyseqs;
	  
	  keyseqs = rl_invoking_keyseqs_in_map(function, map);

	  if (keyseqs) {
	    int i, count;

	    /* count number of entries */
	    for (count = 0; keyseqs[count]; count++)
	      ;

	    EXTEND(sp, count);
	    for (i = 0; i < count; i++) {
	      PUSHs(sv_2mortal(newSVpv(keyseqs[i], 0)));
	      xfree(keyseqs[i]);
	    }
	    xfree((char *)keyseqs);
	  } else {
	    /* return null list */
	  }
	}

void
rl_function_dumper(readable = 0)
	int readable
    PROTOTYPE: ;$

void
rl_list_funmap_names()
    PROTOTYPE:

 # return list of all function name. (Term::Readline::Gnu specific function)
void
rl_get_all_function_names()
    PROTOTYPE:
    PPCODE:
	{
	  int i, count;
	  /* count number of entries */
	  for (count = 0; funmap[count]; count++)
	    ;
	  
	  EXTEND(sp, count);
	  for (i = 0; i < count; i++) {
	    PUSHs(sv_2mortal(newSVpv(funmap[i]->name, 0)));
	  }
	}

void
rl_funmap_names()
    PROTOTYPE:
    PPCODE:
	{
	  const char **funmap;

	  /* don't free returned memory */
	  funmap = (const char **)rl_funmap_names();/* cast is for oldies */

	  if (funmap) {
	    int i, count;

	    /* count number of entries */
	    for (count = 0; funmap[count]; count++)
	      ;

	    EXTEND(sp, count);
	    for (i = 0; i < count; i++) {
	      PUSHs(sv_2mortal(newSVpv(funmap[i], 0)));
	    }
	  } else {
	    /* return null list */
	  }
	}

int
_rl_add_funmap_entry(name, function)
	CONST char *		name
	rl_command_func_t *	function
    PROTOTYPE: $$
    CODE:
	RETVAL = rl_add_funmap_entry(name, function);
    OUTPUT:
	RETVAL

 #
 #	2.4.5 Allowing Undoing
 #
int
rl_begin_undo_group()
    PROTOTYPE:

int
rl_end_undo_group()
    PROTOTYPE:

void
rl_add_undo(what, start, end, text)
	int what
	int start
	int end
	char *	text
    PROTOTYPE: $$$$
    CODE:
	/* rl_free_undo_list will free the duplicated memory */
	rl_add_undo((enum undo_code)what, start, end, dupstr(text));

void
rl_free_undo_list()
    PROTOTYPE:

int
rl_do_undo()
    PROTOTYPE:

int
rl_modifying(start = 0, end = rl_end)
	int start
	int end
    PROTOTYPE: ;$$

 #
 #	2.4.6 Redisplay
 #
void
rl_redisplay()
    PROTOTYPE:

int
rl_forced_update_display()
    PROTOTYPE:

int
rl_on_new_line()
    PROTOTYPE:

int
rl_on_new_line_with_prompt()
    PROTOTYPE:

int
rl_clear_visible_line()
    PROTOTYPE:

int
rl_reset_line_state()
    PROTOTYPE:

int
rl_show_char(i)
	int i
    PROTOTYPE: $

int
_rl_message(text)
	const char *	text
    PROTOTYPE: $
    CODE:
	RETVAL = rl_message(text);
    OUTPUT:
	RETVAL

int
rl_crlf()
    PROTOTYPE:

int
rl_clear_message()
    PROTOTYPE:

void
rl_save_prompt()
    PROTOTYPE:

void
rl_restore_prompt()
    PROTOTYPE:

int
rl_expand_prompt(prompt)
	# should be defined as 'const char *'
	char *		prompt

int
rl_set_prompt(prompt)
	const char *	prompt

 #
 #	2.4.7 Modifying Text
 #
int
rl_insert_text(text)
	CONST char *	text
    PROTOTYPE: $

int
rl_delete_text(start = 0, end = rl_end)
	int start
	int end
    PROTOTYPE: ;$$

t_utf8_free
rl_copy_text(start = 0, end = rl_end)
	int start
	int end
    PROTOTYPE: ;$$

int
rl_kill_text(start = 0, end = rl_end)
	int start
	int end
    PROTOTYPE: ;$$

 # rl_push_macro_input() is documented by readline-4.2 but it has been
 # implemented from 2.2.1.

void
rl_push_macro_input(macro)
	CONST char *	macro
    PROTOTYPE: $
    CODE:
	rl_push_macro_input(dupstr(macro));

 #
 #	2.4.8 Character Input
 #
int
rl_read_key()
    PROTOTYPE:

int
rl_getc(stream)
	FILE *	stream
    PROTOTYPE: $

int
rl_stuff_char(c)
	int c
    PROTOTYPE: $

int
rl_execute_next(c)
	int c
    PROTOTYPE: $

int
rl_clear_pending_input()
    PROTOTYPE:

int
rl_set_keyboard_input_timeout(usec)
	int usec
    PROTOTYPE: $

 #
 #	2.4.9 Terminal Management
 #

void
rl_prep_terminal(meta_flag)
	int meta_flag
    PROTOTYPE: $

void
rl_deprep_terminal()
    PROTOTYPE:

void
_rl_tty_set_default_bindings(kmap = rl_get_keymap())
	Keymap kmap
    PROTOTYPE: ;$
    CODE:
	rl_tty_set_default_bindings(kmap);

void
_rl_tty_unset_default_bindings(kmap = rl_get_keymap())
	Keymap kmap
    PROTOTYPE: ;$
    CODE:
	rl_tty_unset_default_bindings(kmap);

int
rl_tty_set_echoing(value)
	int value
    PROTOTYPE: $

int
rl_reset_terminal(terminal_name = NULL)
	CONST char *	terminal_name
    PROTOTYPE: ;$

 #
 #	2.4.10 Utility Functions
 #
readline_state_t *
rl_save_state()
    PROTOTYPE:
    CODE:
    {
      readline_state_t *state;
      Newx(state, 1, readline_state_t);
      rl_save_state(state);
      RETVAL = state;
    }
    OUTPUT:
	RETVAL

int
rl_restore_state(state)
	readline_state_t *	state

MODULE = Term::ReadLine::Gnu	PACKAGE = readline_state_tPtr	PREFIX = my_

void
my_DESTROY(state)
	readline_state_t *	state
    CODE:
    {
      #warn("readline_state_tPtr::DESTROY\n");
      Safefree(state);
    }

MODULE = Term::ReadLine::Gnu	PACKAGE = Term::ReadLine::Gnu::XS

void
rl_replace_line(text, clear_undo = 0)
	const char *text
	int clear_undo
    PROTOTYPE: $;$

int
rl_initialize()
    PROTOTYPE:
    CODE:
    {
      RETVAL = rl_initialize();
      /*
       * Perl optionally maintains its own envirnment variable array
       * using its own memory management functions.  On the other hand
       * the GNU Readline Library sets variables, $LINES and $COLUMNS,
       * by using the C library function putenv() in
       * rl_initialize(). When Perl frees the memory for the variables
       * during the destruction (perl.c:perl_destruct()), it may cause
       * segmentation faults.
       *
       * CPAN ticket #37194
       *   https://rt.cpan.org/Public/Bug/Display.html?id=37194
       *
       * To solve the problem, make a copy of the whole environment
       * variable array which might be reallocated by rl_initialize().
       */
      /* from perl.c:perl_destruct() */
#if defined(USE_ENVIRON_ARRAY) && !defined(PERL_USE_SAFE_PUTENV) \
  && !defined(PERL_DARWIN)
# if ((PERL_VERSION > 8) || (PERL_VERSION == 8 && PERL_SUBVERSION >= 6)) 
      /* Perl 5.8.6 introduced PL_use_safe_putenv. */
      if (environ != PL_origenviron && !PL_use_safe_putenv
#  else
      if (environ != PL_origenviron
#  endif
#  ifdef USE_ITHREADS
	  /* only main thread can free environ[0] contents */
	  && PL_curinterp == aTHX
#  endif
	  ) {
	int i, len;
	char *s;
	char **tmpenv;
	for (i = 0; environ[i]; i++)
	  ;
	/* 
	 * We cannot use New*() which uses safemalloc() instead of
	 * safesysmalloc().
	 */
	tmpenv = (char **)safesysmalloc((i+1)*sizeof(char *));
	for (i = 0; environ[i]; i++) {
	  len = strlen(environ[i]);
	  s = (char*)safesysmalloc((len+1)*sizeof(char));
	  Copy(environ[i], s, len+1, char);
	  tmpenv[i] = s;
	}
	tmpenv[i] = NULL;
	environ = tmpenv;
      }
#endif
    }
    OUTPUT:
	RETVAL

int
rl_ding()
    PROTOTYPE:

int
rl_alphabetic(c)
	int c
    PROTOTYPE: $

void
rl_display_match_list(pmatches, plen = -1, pmax = -1)
	SV *	pmatches
	int plen
	int pmax
    PROTOTYPE: $;$$
    CODE:
	{
	  unsigned int len, max, i;
	  STRLEN l;
	  char **matches;
	  AV *av_matches;
	  SV **pvp;

	  if (SvTYPE(SvRV(pmatches)) != SVt_PVAV) {
	    warn("Gnu.xs:_rl_display_match_list: the 1st arguments must be a reference to an array\n");
	    return;
	  }
	  av_matches = (AV *)SvRV(ST(0));
	  /* index zero contains a possible match and is not counted */
	  if ((len = av_len(av_matches) + 1 - 1) == 0)
	    return;
	  matches = (char **)xmalloc (sizeof(char *) * (len + 2));
	  max = 0;
	  for (i = 0; i <= len; i++) {
	    pvp = av_fetch(av_matches, i, 0);
	    if (SvPOKp(*pvp)) {
	      matches[i] = dupstr(SvPV(*pvp, l));
	      if (l > max)
		max = l;
	    }
	  }
	  matches[len + 1] = NULL;

	  rl_display_match_list(matches,
				plen < 0 ? len : plen,
				pmax < 0 ? max : pmax);

	  for (i = 1; i <= len; i++)
	    xfree(matches[i]);
	  xfree(matches);
	}

 #
 #	2.4.11 Miscellaneous Functions
 #

 # rl_macro_bind() is documented by readline-4.2 but it has been implemented 
 # from 2.2.1.
 # It is equivalent with 
 # rl_generic_bind(ISMACR, keyseq, (char *)macro_keys, map).
int
_rl_macro_bind(keyseq, macro, map = rl_get_keymap())
	CONST char *	keyseq
	CONST char *	macro
	Keymap map
    PROTOTYPE: $$;$
    CODE:
	RETVAL = rl_macro_bind(keyseq, macro, map);
    OUTPUT:
	RETVAL

 # rl_macro_dumper is documented by Readline 4.2,
 # but have been implemented for 2.2.1.

void
rl_macro_dumper(readable = 0)
	int readable
    PROTOTYPE: ;$

 # rl_variable_bind() is documented by readline-4.2 but it has been implemented
 # from 2.2.1.

int
rl_variable_bind(name, value)
	CONST char *	name
	CONST char *	value
    PROTOTYPE: $$

 # rl_variable_dumper is documented by Readline 4.2,
 # but have been implemented for 2.2.1.

 # Do not free the string returned.
t_utf8
rl_variable_value(variable)
	CONST char *	variable
    PROTOTYPE: $

void
rl_variable_dumper(readable = 0)
	int readable
    PROTOTYPE: ;$

int
rl_set_paren_blink_timeout(usec)
	int usec
    PROTOTYPE: $

 # rl_get_termcap() is documented by readline-4.2 but it has been implemented 
 # from 2.2.1.

 # Do not free the string returned.
char *
rl_get_termcap(cap)
	CONST char *	cap
    PROTOTYPE: $

 #
 #	2.4.12 Alternate Interface
 #

void
rl_callback_handler_install(prompt, lhandler)
	const char *	prompt
	SV *		lhandler
    PROTOTYPE: $$
    CODE:
	{
	  static char *cb_prompt = NULL;
	  int len = strlen(prompt) + 1;

	  /* The value of prompt may be used after return from this routine. */
	  if (cb_prompt) {
	    Safefree(cb_prompt);
	  }
	  New(0, cb_prompt, len, char);
	  Copy(prompt, cb_prompt, len, char);

	  /*
	   * Don't remove braces. The definition of SvSetSV() of
	   * Perl 5.003 has a problem.
	   */
	  if (callback_handler_callback) {
	    SvSetSV(callback_handler_callback, lhandler);
	  } else {
	    callback_handler_callback = newSVsv(lhandler);
	  }

	  rl_callback_handler_install(cb_prompt, callback_handler_wrapper);
	}

void
rl_callback_read_char()
    PROTOTYPE:

void
rl_callback_sigcleanup()
    PROTOTYPE:

void
rl_callback_handler_remove()
    PROTOTYPE:

 #
 #	2.5 Readline Signal Handling
 #

int
rl_pending_signal()
    PROTOTYPE:

void
rl_cleanup_after_signal()
    PROTOTYPE:

void
rl_free_line_state()
    PROTOTYPE:

void
rl_reset_after_signal()
    PROTOTYPE:

void
rl_echo_signal_char(sig)
	int sig
    PROTOTYPE: $

void
rl_resize_terminal()
    PROTOTYPE:

void
rl_set_screen_size(rows, cols)
	int rows
	int cols
    PROTOTYPE: $$

void
rl_get_screen_size()
    PROTOTYPE:
    PPCODE:
	{
	  int rows, cols;
	  rl_get_screen_size(&rows, &cols);
	  EXTEND(sp, 2);
	  PUSHs(sv_2mortal(newSViv(rows)));
	  PUSHs(sv_2mortal(newSViv(cols)));
	}

void
rl_reset_screen_size()
    PROTOTYPE:

int
rl_set_signals()
    PROTOTYPE:

int
rl_clear_signals()
    PROTOTYPE:

 #
 #	2.6 Custom Completers
 #

int
rl_complete_internal(what_to_do = TAB)
	int what_to_do
    PROTOTYPE: ;$

int
_rl_completion_mode(function)
	rl_command_func_t *	function
    PROTOTYPE: $
    CODE:
	RETVAL = rl_completion_mode(function);
    OUTPUT:
	RETVAL

void
rl_completion_matches(text, fn = NULL)
	CONST char *	text
	SV *		fn
    PROTOTYPE: $;$
    PPCODE:
	{
	  char **matches;

	  if (SvTRUE(fn)) {
	    /* use completion_entry_function temporarily */
	    XFunction *rlfunc_save = *(fn_tbl[CMP_ENT].rlfuncp); /* ??? */
	    SV *callback_save = fn_tbl[CMP_ENT].callback;
	    fn_tbl[CMP_ENT].callback = newSVsv(fn);

	    matches = rl_completion_matches(text,
					    completion_entry_function_wrapper);

	    SvREFCNT_dec(fn_tbl[CMP_ENT].callback);
	    fn_tbl[CMP_ENT].callback = callback_save;
	    *(fn_tbl[CMP_ENT].rlfuncp) = rlfunc_save; /* ??? */
	  } else
	    matches = rl_completion_matches(text, NULL);

	  /*
	   * Without the next line the Perl internal stack is broken
	   * under some condition.  Perl bug or undocumented feature
	   * !!!?
	   */
	  SPAGAIN; sp -= 2;
	  
	  if (matches) {
	    int i, count;

	    /* count number of entries */
	    for (count = 0; matches[count]; count++)
	      ;

	    EXTEND(sp, count);
	    for (i = 0; i < count; i++) {
	      PUSHs(sv_2mortal_utf8(newSVpv(matches[i], 0)));
	      xfree(matches[i]);
	    }
	    xfree((char *)matches);
	  } else {
	    /* return null list */
	  }
	}

t_utf8_free
rl_filename_completion_function(text, state)
	const char *	text
	int state
    PROTOTYPE: $$

t_utf8_free
rl_username_completion_function(text, state)
	const char *	text
	int state
    PROTOTYPE: $$


 ########################################################################
 #
 #	Gnu History Library
 #
 ########################################################################

 #
 #	2.3.1 Initializing History and State Management
 #
void
using_history()
    PROTOTYPE:

HISTORY_STATE *
history_get_history_state()
    PROTOTYPE:

void
history_set_history_state(state)
	HISTORY_STATE *	state

MODULE = Term::ReadLine::Gnu	PACKAGE = HISTORY_STATEPtr	PREFIX = my_

void
my_DESTROY(state)
	HISTORY_STATE *	state
    CODE:
    {
      #warn("HISTORY_STATEPtr::DESTROY\n");
      xfree(state);
    }

MODULE = Term::ReadLine::Gnu	PACKAGE = Term::ReadLine::Gnu::XS

 #
 #	2.3.2 History List Management
 #

void
add_history(string)
	CONST char *	string
    PROTOTYPE: $

void
add_history_time(string)
	CONST char *	string
    PROTOTYPE: $

HIST_ENTRY *
remove_history(which)
	int which
    PROTOTYPE: $
    OUTPUT:
	RETVAL
    CLEANUP:
	if (RETVAL) {
	  xfree(RETVAL->line);
#if (RL_VERSION_MAJOR >= 5)
	  xfree(RETVAL->timestamp);
#endif /* (RL_VERSION_MAJOR >= 5) */
	  xfree(RETVAL->data);
	  xfree((char *)RETVAL);
	}

 # free_history_entry() is introduced by GNU Readline Library 5.0.
 # Since Term::ReadLine::Gnu does not support the member 'data' of HIST_ENTRY
 # structure, remove_history() covers it.

 # The 3rd parameter (histdata_t) is not supported. Does anyone use it?
HIST_ENTRY *
replace_history_entry(which, line)
	int which
	CONST char *	line
    PROTOTYPE: $$
    CODE:
	RETVAL = replace_history_entry(which, line, (char *)NULL);
    OUTPUT:
	RETVAL
    CLEANUP:
	if (RETVAL) {
	  xfree(RETVAL->line);
#if (RL_VERSION_MAJOR >= 5)
	  xfree(RETVAL->timestamp);
#endif /* (RL_VERSION_MAJOR >= 5) */
	  xfree(RETVAL->data);
	  xfree((char *)RETVAL);
	}

void
clear_history()
    PROTOTYPE:

int
stifle_history(i)
	SV *	i
    PROTOTYPE: $
    CODE:
	{
	  if (SvOK(i)) {
	    int max = SvIV(i);
	    stifle_history(max);
	    RETVAL = max;
	  } else {
	    RETVAL = unstifle_history();
	  }
	}
    OUTPUT:
	RETVAL

int
unstifle_history()
    PROTOTYPE:

int
history_is_stifled()
    PROTOTYPE:

 #
 #	2.3.3 Information about the History List
 #

 # history_list() is implemented as a perl function in Gnu.pm.

int
where_history()
    PROTOTYPE:

HIST_ENTRY *
current_history()
    PROTOTYPE:

HIST_ENTRY *
history_get(offset)
	int offset
    PROTOTYPE: $

 # To keep compatibility, I cannot make a function whose argument
 # is "HIST_ENTRY *".
time_t
history_get_time(offset)
	int offset
    PROTOTYPE: $
    CODE:
	{
	  HIST_ENTRY *he = history_get(offset);
	  if (he)
	    RETVAL = history_get_time(he);
	  else
	    RETVAL = 0;
	}
    OUTPUT:
	RETVAL

int
history_total_bytes()
    PROTOTYPE:

 #
 #	2.3.4 Moving Around the History List
 #
int
history_set_pos(pos)
	int pos
    PROTOTYPE: $

HIST_ENTRY *
previous_history()
    PROTOTYPE:

HIST_ENTRY *
next_history()
    PROTOTYPE:

 #
 #	2.3.5 Searching the History List
 #
int
history_search(string, direction = -1)
	CONST char *	string
	int direction
    PROTOTYPE: $;$

int
history_search_prefix(string, direction = -1)
	CONST char *	string
	int direction
    PROTOTYPE: $;$

int
history_search_pos(string, direction = -1, pos = where_history())
	CONST char *	string
	int direction
	int pos
    PROTOTYPE: $;$$

 #
 #	2.3.6 Managing the History File
 #
int
read_history_range(filename = NULL, from = 0, to = -1)
	CONST char *	filename
	int from
	int to
    PROTOTYPE: ;$$$

int
write_history(filename = NULL)
	CONST char *	filename
    PROTOTYPE: ;$

int
append_history(nelements, filename = NULL)
	int nelements
	CONST char *	filename
    PROTOTYPE: $;$

int
history_truncate_file(filename = NULL, nlines = 0)
	CONST char *	filename
	int nlines
    PROTOTYPE: ;$$

 #
 #	2.3.7 History Expansion
 #
void
history_expand(line)
	# should be defined as 'const char *'
	char *	line
    PROTOTYPE: $
    PPCODE:
	{
	  char *expansion;
	  int result;

	  result = history_expand(line, &expansion);
	  EXTEND(sp, 2);
	  PUSHs(sv_2mortal(newSViv(result)));
	  PUSHs(sv_2mortal_utf8(newSVpv(expansion, 0)));
	  xfree(expansion);
	}

void
_get_history_event(string, cindex, qchar = 0)
	CONST char *	string
	int cindex
	int qchar
    PROTOTYPE: $$;$
    PPCODE:
	{
	  char *text;

	  text = get_history_event(string, &cindex, qchar);
	  EXTEND(sp, 2);
	  if (text) {		/* don't free `text' */
	    PUSHs(sv_2mortal_utf8(newSVpv(text, 0)));
	  } else {
	    PUSHs(&PL_sv_undef);
	  }
	  PUSHs(sv_2mortal(newSViv(cindex)));
	}

void
history_tokenize(text)
	CONST char *	text
    PROTOTYPE: $
    PPCODE:
	{
	  char **tokens;

	  tokens = history_tokenize(text);
	  if (tokens) {
	    int i, count;

	    /* count number of entries */
	    for (count = 0; tokens[count]; count++)
	      ;

	    EXTEND(sp, count);
	    for (i = 0; i < count; i++) {
	      PUSHs(sv_2mortal_utf8(newSVpv(tokens[i], 0)));
	      xfree(tokens[i]);
	    }
	    xfree((char *)tokens);
	  } else {
	    /* return null list */
	  }
	}

#define DALLAR '$'		/* define for xsubpp bug */

t_utf8_free
_history_arg_extract(line, first = 0 , last = DALLAR)
	CONST char *	line
	int first
	int last
    PROTOTYPE: $;$$
    CODE:
	RETVAL = history_arg_extract(first, last, line);
    OUTPUT:
	RETVAL


 #
 #	GNU Readline/History Library Variable Access Routines
 #

MODULE = Term::ReadLine::Gnu		PACKAGE = Term::ReadLine::Gnu::Var

void
_rl_store_str(pstr, id)
	const char *	pstr
	int id
    PROTOTYPE: $$
    CODE:
	{
	  size_t len;

	  ST(0) = sv_newmortal();
	  if (id < 0 || id >= sizeof(str_tbl)/sizeof(struct str_vars)) {
	    warn("Gnu.xs:_rl_store_str: Illegal `id' value: `%d'", id);
	    XSRETURN_UNDEF;
	  }

	  if (str_tbl[id].read_only) {
	    warn("Gnu.xs:_rl_store_str: store to read only variable");
	    XSRETURN_UNDEF;
	  }

	  /*
	   * Use xmalloc() and xfree() instead of New() and Safefree(),
	   * because this block may be reallocated by the GNU Readline Library.
	   */
	  if (str_tbl[id].accessed && *str_tbl[id].var) {
	    /*
	     * First time a variable is used by this routine,
	     * it may be a static area.  So it cannot be freed.
	     */
	    xfree(*str_tbl[id].var);
	    *str_tbl[id].var = NULL;
	  }
	  str_tbl[id].accessed = 1;

	  /*printf("%d: %s\n", id, pstr);*/
	  len = strlen(pstr) + 1;
	  *str_tbl[id].var = xmalloc(len);
	  Copy(pstr, *str_tbl[id].var, len, char);

	  /* return variable value */
	  if (*str_tbl[id].var) {
	    sv_setpv(ST(0), *str_tbl[id].var);
	  }
	}

void
_rl_store_rl_line_buffer(pstr)
	const char *	pstr
    PROTOTYPE: $
    CODE:
	{
	  size_t len;

	  ST(0) = sv_newmortal();
	  if (pstr) {
	    len = strlen(pstr);

	    /*
	     * Old manual did not document this function, but can be
	     * used.
	     */
	    rl_extend_line_buffer(len + 1);

	    Copy(pstr, rl_line_buffer, len + 1, char);
	    /* rl_line_buffer is not NULL here */
	    sv_setpv(ST(0), rl_line_buffer);

	    /* fix rl_end and rl_point */
	    rl_end = len;
	    if (rl_point > len)
		    rl_point = len;
	  }
	}

void
_rl_fetch_str(id)
	int id
    PROTOTYPE: $
    CODE:
	{
	  ST(0) = sv_newmortal();
	  if (id < 0 || id >= sizeof(str_tbl)/sizeof(struct str_vars)) {
	    warn("Gnu.xs:_rl_fetch_str: Illegal `id' value: `%d'", id);
	  } else {
	    if (*(str_tbl[id].var)) {
	      sv_setpv(ST(0), *(str_tbl[id].var));
	      if (utf8_mode) {
		sv_utf8_decode(ST(0));
	      }
	    }
	  }
	}

void
_rl_store_int(pint, id)
	int pint
	int id
    PROTOTYPE: $$
    CODE:
	{
	  ST(0) = sv_newmortal();
	  if (id < 0 || id >= sizeof(int_tbl)/sizeof(struct int_vars)) {
	    warn("Gnu.xs:_rl_store_int: Illegal `id' value: `%d'", id);
	    XSRETURN_UNDEF;
	  }

	  if (int_tbl[id].read_only) {
	    warn("Gnu.xs:_rl_store_int: store to read only variable");
	    XSRETURN_UNDEF;
	  }

	  /* set C variable */
	  if (int_tbl[id].charp)
	    *((char *)(int_tbl[id].var)) = (char)pint;
	  else if (int_tbl[id].ulong)
	    *((unsigned long *)(int_tbl[id].var)) = (unsigned long)pint;
	  else
	    *(int_tbl[id].var) = pint;

	  /* return variable value */
	  sv_setiv(ST(0), pint);
	}

void
_rl_fetch_int(id)
	int id
    PROTOTYPE: $
    CODE:
	{
	  ST(0) = sv_newmortal();
	  if (id < 0 || id >= sizeof(int_tbl)/sizeof(struct int_vars)) {
	    warn("Gnu.xs:_rl_fetch_int: Illegal `id' value: `%d'", id);
	    /* return undef */
	  } else {
	      if (int_tbl[id].charp)
		  sv_setiv(ST(0),
			   (int)*((char *)(int_tbl[id].var)));
	      else if (int_tbl[id].ulong)
		  sv_setiv(ST(0),
			   (int)*((unsigned long *)(int_tbl[id].var)));
	      else
		  sv_setiv(ST(0),
			   *(int_tbl[id].var));
	  }
	}

#if 1	/* http://perldoc.perl.org/perlxs.html#Inserting-POD%2c-Comments-and-C-Preprocessor-Directives */

void
_rl_store_iostream(stream, id)
	FILE *stream
	int id
    PROTOTYPE: $$
    CODE:
	{
	  switch (id) {
	  case 0:
	    rl_instream = stream;
	    break;
	  case 1:
	    rl_outstream = stream;
#ifdef __CYGWIN__
	    {
	      /* Cygwin b20.1 library converts NL to CR-NL
		 automatically.  But it does not do it on a file
		 stream made by Perl.  Set terminal attribute
		 explicitly */
		struct termios tio;
		tcgetattr(fileno(rl_outstream), &tio);
		tio.c_iflag |= ICRNL;
		tio.c_oflag |= ONLCR;
		tcsetattr(fileno(rl_outstream), TCSADRAIN, &tio);
	    }
#endif /* __CYGWIN__ */
	    break;
	  default:
	    warn("Gnu.xs:_rl_store_iostream: Illegal `id' value: `%d'", id);
	    break;
	  }
	  PerlIO_debug("TRG:store_iostream id %d fd %d\n",
		       id, fileno(stream));
	}

#else /* 2016/06/07 worked but no advantage */

void
_rl_store_iostream(iop, id)
	PerlIO *iop
	int id
    PROTOTYPE: $$
    CODE:
	{
	  int fd = -1;
	  switch (id) {
	  case 0:
	    perlio_in = iop;
	    rl_instream = PerlIO_findFILE(iop);
	    fd = fileno(rl_instream);
	    break;
	  case 1:
	    perlio_out = iop;
	    rl_outstream = PerlIO_findFILE(iop);
	    fd = fileno(rl_outstream);
#ifdef __CYGWIN__
	    {
	      /* Cygwin b20.1 library converts NL to CR-NL
		 automatically.  But it does not do it on a file
		 stream made by Perl.  Set terminal attribute
		 explicitly */
		struct termios tio;
		tcgetattr(fd, &tio);
		tio.c_iflag |= ICRNL;
		tio.c_oflag |= ONLCR;
		tcsetattr(fd, TCSADRAIN, &tio);
	    }
#endif /* __CYGWIN__ */
	    break;
	  default:
	    warn("Gnu.xs:_rl_store_iostream: Illegal `id' value: `%d'", id);
	    break;
	  }
	  PerlIO_debug("TRG:store_iostream id %d fd %d\n",
		       id, fd);
	}

#endif

#if 0 /* not used since 1.26 */

PerlIO *
_rl_fetch_iostream(id)
	int id
    PROTOTYPE: $
    CODE:
	{
	  switch (id) {
	  case 0:
	    if (instreamPIO == NULL)
	      RETVAL = instreamPIO = PerlIO_importFILE(rl_instream, NULL);
	    else
	      RETVAL = instreamPIO;
	    break;
	  case 1:
	    if (outstreamPIO == NULL)
	      RETVAL = outstreamPIO = PerlIO_importFILE(rl_outstream, NULL);
	    else
	      RETVAL = outstreamPIO;
	    break;
	  default:
	    warn("Gnu.xs:_rl_fetch_iostream: Illegal `id' value: `%d'", id);
	    XSRETURN_UNDEF;
	    break;
	  }
	  PerlIO_debug("TRG:fetch_iostream id %d fd %d\n", 
		       id, PerlIO_fileno(RETVAL));
	}
    OUTPUT:
	RETVAL

#endif

Keymap
_rl_fetch_keymap(id)
	int id
    PROTOTYPE: $
    CODE:
	{
	  switch (id) {
	  case 0:
	    RETVAL = rl_executing_keymap;
	    break;
	  case 1:
	    RETVAL = rl_binding_keymap;
	    break;
	  default:
	    warn("Gnu.xs:_rl_fetch_keymap: Illegal `id' value: `%d'", id);
	    XSRETURN_UNDEF;
	    break;
	  }
	}
    OUTPUT:
	RETVAL

void
_rl_store_function(fn, id)
	SV *	fn
	int id
    PROTOTYPE: $$
    CODE:
	{
	  /*
	   * If "fn" is undef, default value of the GNU Readline
	   * Library is set.
	   */
	  ST(0) = sv_newmortal();
	  if (id < 0 || id >= sizeof(fn_tbl)/sizeof(struct fn_vars)) {
	    warn("Gnu.xs:_rl_store_function: Illegal `id' value: `%d'", id);
	    XSRETURN_UNDEF;
	  }
	  
	  if (SvTRUE(fn)) {
	    /*
	     * Don't remove braces. The definition of SvSetSV() of
	     * Perl 5.003 has a problem.
	     */
	    if (fn_tbl[id].callback) {
	      SvSetSV(fn_tbl[id].callback, fn);
	    } else {
	      fn_tbl[id].callback = newSVsv(fn);
	    }
	    *(fn_tbl[id].rlfuncp) = fn_tbl[id].wrapper;
	  } else {
	    if (fn_tbl[id].callback) {
	      SvSetSV(fn_tbl[id].callback, &PL_sv_undef);
	    }
	    *(fn_tbl[id].rlfuncp) = fn_tbl[id].defaultfn;
	  }

	  /* return variable value */
	  sv_setsv(ST(0), fn);
	}

void
_rl_fetch_function(id)
	int id
    PROTOTYPE: $
    CODE:
	{
	  ST(0) = sv_newmortal();
	  if (id < 0 || id >= sizeof(fn_tbl)/sizeof(struct fn_vars)) {
	    warn("Gnu.xs:_rl_fetch_function: Illegal `id' value: `%d'", id);
	    /* return undef */
	  } else if (fn_tbl[id].callback && SvTRUE(fn_tbl[id].callback)) {
	    sv_setsv(ST(0), fn_tbl[id].callback);
	  }
	}

rl_command_func_t *
_rl_fetch_last_func()
    PROTOTYPE:
    CODE:
	RETVAL = rl_last_func;
    OUTPUT:
	RETVAL

MODULE = Term::ReadLine::Gnu		PACKAGE = Term::ReadLine::Gnu::XS

void
tgetstr(id)
	const char *	id
    PROTOTYPE: $
    CODE:
	ST(0) = sv_newmortal();
	if (id) {
	  /*
	   * The magic number `2032' is derived from bash
	   * terminal.c:_rl_init_terminal_io().
	   */
	  char buffer[2032];
	  char *bp = buffer;
	  char *t;
	  t = tgetstr(id, &bp); /* don't free returned string */
	  if (t) {
	    char buf[2032];
	    /* call tputs() to apply padding information */
	    tputs_ptr = buf;
	    tputs(t, 1, tputs_char);
	    *tputs_ptr = '\0';
	    sv_setpv(ST(0), buf);
	  }
	}

 #
 # Local Variables:
 # c-default-style: "gnu"
 # End:
 #
