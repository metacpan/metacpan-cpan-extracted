#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <stdio.h>
#include <string.h>
#include <readline/readline.h>
#include <readline/history.h>

static SV *startup_hook_sv = NULL;
static SV *pre_input_hook_sv = NULL;
static SV *getc_function_sv = NULL;
static SV *completion_matches_function_sv = NULL;
static SV *completion_entry_function_sv = NULL;
static SV *attempted_completion_function_sv = NULL;
static SV *completion_word_break_hook_sv = NULL;

typedef struct {
    SV *func_sv;
    rl_command_func_t *func_c;
} bind_key_func_t;

static int bind_key_func_wrapper (int index, int count, int key);

static int bind_key_func1 (int count, int key) {
    return bind_key_func_wrapper(0, count, key);
}

static int bind_key_func2 (int count, int key) {
    return bind_key_func_wrapper(1, count, key);
}

static int bind_key_func3 (int count, int key) {
    return bind_key_func_wrapper(2, count, key);
}

static int bind_key_func4 (int count, int key) {
    return bind_key_func_wrapper(3, count, key);
}

static bind_key_func_t bind_key_funcs[] = {
    {NULL, bind_key_func1},
    {NULL, bind_key_func2},
    {NULL, bind_key_func3},
    {NULL, bind_key_func4},
};

static int bind_key_func_wrapper (int index, int count, int key) {
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSViv(count)));
    PUSHs(sv_2mortal(newSViv(key)));
    PUTBACK;
    call_sv(bind_key_funcs[index].func_sv, G_SCALAR);
    SPAGAIN;
    SV *retval_sv = POPs;
    int retval = SvIOK(retval_sv) ? SvIV(retval_sv) : 0;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}

static int startup_hook_wrapper () {
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    int count = call_sv(startup_hook_sv, G_SCALAR);
    SPAGAIN;
    SV *retval_sv = POPs;
    int retval = SvIOK(retval_sv) ? SvIV(retval_sv) : 0;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}

static int pre_input_hook_wrapper () {
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    int count = call_sv(pre_input_hook_sv, G_SCALAR);
    SPAGAIN;
    SV *retval_sv = POPs;
    int retval = SvIOK(retval_sv) ? SvIV(retval_sv) : 0;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}

static int getc_function_wrapper () {
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    int count = call_sv(getc_function_sv, G_SCALAR);
    SPAGAIN;
    SV *retval_sv = POPs;
    int retval = SvIOK(retval_sv) ? SvIV(retval_sv) : 0;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}

static char *completion_matches_function_wrapper (const char *text, int state) {
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSVpv(text, 0)));
    PUSHs(sv_2mortal(newSViv(state)));
    PUTBACK;
    int count = call_sv(completion_matches_function_sv, G_SCALAR);
    SPAGAIN;
    SV *retval_sv = POPs;
    char *retval = NULL;
    if (SvOK(retval_sv)) {
        retval = strdup(SvPV_nolen(retval_sv));
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}

static char *completion_entry_function_wrapper (const char *text, int state) {
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSVpv(text, 0)));
    PUSHs(sv_2mortal(newSViv(state)));
    PUTBACK;
    int count = call_sv(completion_entry_function_sv, G_SCALAR);
    SPAGAIN;
    SV *retval_sv = POPs;
    char *retval = NULL;
    if (SvOK(retval_sv)) {
        retval = strdup(SvPV_nolen(retval_sv));
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}

static char **attempted_completion_function_wrapper (const char *text, int start, int end) {
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 3);
    PUSHs(sv_2mortal(newSVpv(text, 0)));
    PUSHs(sv_2mortal(newSViv(start)));
    PUSHs(sv_2mortal(newSViv(end)));
    PUTBACK;
    int count = call_sv(attempted_completion_function_sv, G_ARRAY);
    SPAGAIN;
    char **matches = NULL;
    if (count > 0) {
        int i, j;
        matches = malloc((count + 1) * sizeof(char *));
        matches[count] = NULL;
        for (i = 0; i < count; i++) {
            SV *sv = POPs;
            char *str = NULL;
            if (SvOK(sv)) {
                str = strdup(SvPV_nolen(sv));
            }
            matches[count - i - 1] = str;
        }
        for (i = 0, j = 0; i < count; i++) {
            if (matches[i]) {
                matches[j] = matches[i];
                j++;
            }
        }
        count = j;
        matches[count] = NULL;
        if (count == 0) {
            free(matches);
            matches = NULL;
        }
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return matches;
}

static char *completion_word_break_hook_wrapper () {
    dTHX;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    int count = call_sv(completion_word_break_hook_sv, G_SCALAR);
    SPAGAIN;
    SV *retval_sv = POPs;
    char *retval = NULL;
    if (SvOK(retval_sv)) {
        retval = strdup(SvPV_nolen(retval_sv));
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}

MODULE = RL PACKAGE = RL

# Main Interface

char *
readline (prompt)
    const char *prompt
CODE:
    RETVAL = readline(prompt);
OUTPUT:
    RETVAL
CLEANUP:
    free(RETVAL);

# Variables

char *
line_buffer (...)
CODE:
    RETVAL = rl_line_buffer;
    if (items) {
        rl_line_buffer = SvPV_nolen(ST(0));
    }
OUTPUT:
    RETVAL

int
point (...)
CODE:
    RETVAL = rl_point;
    if (items) {
        rl_point = SvIV(ST(0));
    }
OUTPUT:
    RETVAL

int
end (...)
CODE:
    RETVAL = rl_end;
    if (items) {
        rl_end = SvIV(ST(0));
    }
OUTPUT:
    RETVAL

char *
prompt ()
CODE:
    RETVAL = rl_prompt;
OUTPUT:
    RETVAL

int
already_prompted (...)
CODE:
    RETVAL = rl_already_prompted;
    if (items) {
        rl_already_prompted = SvIV(ST(0));
    }
OUTPUT:
    RETVAL

const char *
library_version ()
CODE:
    RETVAL = rl_library_version;
OUTPUT:
    RETVAL

int
readline_version ()
CODE:
    RETVAL = rl_readline_version;
OUTPUT:
    RETVAL

const char *
terminal_name (...)
CODE:
    RETVAL = rl_terminal_name;
    if (items) {
        rl_terminal_name = SvPV_nolen(ST(0));
    }
OUTPUT:
    RETVAL

const char *
readline_name (...)
CODE:
    RETVAL = rl_readline_name;
    if (items) {
        rl_readline_name = SvPV_nolen(ST(0));
    }
OUTPUT:
    RETVAL

FILE *
instream (...)
CODE:
    RETVAL = rl_instream;
    if (items) {
        rl_instream = PerlIO_findFILE(IoIFP(sv_2io(ST(0))));
    }
OUTPUT:
    RETVAL

FILE *
outstream (...)
CODE:
    RETVAL = rl_outstream;
    if (items) {
        rl_outstream = PerlIO_findFILE(IoOFP(sv_2io(ST(0))));
    }
OUTPUT:
    RETVAL

void
startup_hook (func_sv)
    SV *func_sv;
CODE:
    if (startup_hook_sv) {
        SvSetSV(startup_hook_sv, func_sv);
    }
    else {
        startup_hook_sv = newSVsv(func_sv);
    }
    if (SvOK(func_sv)) {
        rl_startup_hook = startup_hook_wrapper;
    }
    else {
        rl_startup_hook = NULL;
    }

void
pre_input_hook (func_sv)
    SV *func_sv;
CODE:
    if (pre_input_hook_sv) {
        SvSetSV(pre_input_hook_sv, func_sv);
    }
    else {
        pre_input_hook_sv = newSVsv(func_sv);
    }
    if (SvOK(func_sv)) {
        rl_pre_input_hook = pre_input_hook_wrapper;
    }
    else {
        rl_pre_input_hook = NULL;
    }

void
getc_function (func_sv)
    SV *func_sv;
CODE:
    if (getc_function_sv) {
        SvSetSV(getc_function_sv, func_sv);
    }
    else {
        getc_function_sv = newSVsv(func_sv);
    }
    if (SvOK(func_sv)) {
        rl_getc_function = getc_function_wrapper;
    }
    else {
        rl_getc_function = NULL;
    }

# Binding Keys

int
bind_key (key, func_sv)
    int key;
    SV *func_sv;
CODE:
    int n = sizeof(bind_key_funcs) / sizeof(bind_key_funcs[0]);
    int i;
    for (i = 0; i < n; i++) {
        if (!bind_key_funcs[i].func_sv) {
            break;
        }
    }
    if (i >= n) {
        warn("No free bind key slots.\n");
    }
    bind_key_funcs[i].func_sv = newSVsv(func_sv);
    RETVAL = rl_bind_key(key, bind_key_funcs[i].func_c);
OUTPUT:
    RETVAL

int
parse_and_bind (line)
    char *line;
CODE:
    RETVAL = rl_parse_and_bind(line);
OUTPUT:
    RETVAL

int
read_init_file (filename)
    const char *filename;
CODE:
    RETVAL = rl_read_init_file(filename);
OUTPUT:
    RETVAL

# Redisplay

void
redisplay ()
CODE:
    rl_redisplay();

void
forced_update_display ()
CODE:
    rl_forced_update_display();

int
on_new_line ()
CODE:
    RETVAL = rl_on_new_line();
OUTPUT:
    RETVAL

int
set_prompt (prompt)
    const char *prompt;
CODE:
    RETVAL = rl_set_prompt(prompt);
OUTPUT:
    RETVAL

# Modifying Text

int
insert_text (text)
    const char *text;
CODE:
    RETVAL = rl_insert_text(text);
OUTPUT:
    RETVAL

# Character Input

int
read_key ()
CODE:
    RETVAL = rl_read_key();
OUTPUT:
    RETVAL

void
stuff_char (c)
    int c;
CODE:
    rl_stuff_char(c);

# Utility Functions

int
initialize ()
CODE:
    RETVAL = rl_initialize();
OUTPUT:
    RETVAL

# Completion Functions

int
complete (count, key)
    int count;
    int key;
CODE:
    RETVAL = rl_complete(count, key);
OUTPUT:
    RETVAL

void
completion_matches (text, func_sv)
    const char *text;
    SV *func_sv;
PPCODE:
    if (completion_matches_function_sv) {
        SvSetSV(completion_matches_function_sv, func_sv);
    }
    else {
        completion_matches_function_sv = newSVsv(func_sv);
    }
    char **matches = rl_completion_matches(text, completion_matches_function_wrapper);
    if (!matches) {
        XSRETURN_EMPTY;
    }
    int i;
    for (i = 0; matches[i]; i++)
        ;
    int n = i;
    EXTEND(SP, n);
    for (i = 0; i < n; i++) {
        PUSHs(sv_2mortal(newSVpv(matches[i], 0)));
        free(matches[i]);
    }
    free(matches);

char *
filename_completion_function (text, state)
    const char *text;
    int state;
CODE:
    RETVAL = rl_filename_completion_function(text, state);
OUTPUT:
    RETVAL

char *
username_completion_function (text, state)
    const char *text;
    int state;
CODE:
    RETVAL = username_completion_function(text, state);
OUTPUT:
    RETVAL

# Completion Variables

void
completion_entry_function (func_sv)
    SV *func_sv;
CODE:
    if (completion_entry_function_sv) {
        SvSetSV(completion_entry_function_sv, func_sv);
    }
    else {
        completion_entry_function_sv = newSVsv(func_sv);
    }
    if (SvOK(func_sv)) {
        rl_completion_entry_function = (void *) completion_entry_function_wrapper;
    }
    else {
        rl_completion_entry_function = NULL;
    }

void
attempted_completion_function (func_sv)
    SV *func_sv;
CODE:
    if (attempted_completion_function_sv) {
        SvSetSV(attempted_completion_function_sv, func_sv);
    }
    else {
        attempted_completion_function_sv = newSVsv(func_sv);
    }
    if (SvOK(func_sv)) {
        rl_attempted_completion_function = attempted_completion_function_wrapper;
    }
    else {
        rl_attempted_completion_function = NULL;
    }

char *
basic_word_break_characters (...)
CODE:
    RETVAL = rl_basic_word_break_characters;
    if (items) {
        rl_basic_word_break_characters = SvPV_nolen(ST(0));
    }
OUTPUT:
    RETVAL

char *
completer_word_break_characters (...)
CODE:
    RETVAL = rl_completer_word_break_characters;
    if (items) {
        rl_completer_word_break_characters = SvPV_nolen(ST(0));
    }
OUTPUT:
    RETVAL

void
completion_word_break_hook (func_sv)
    SV *func_sv;
CODE:
    if (completion_word_break_hook_sv) {
        SvSetSV(completion_word_break_hook_sv, func_sv);
    }
    else {
        completion_word_break_hook_sv = newSVsv(func_sv);
    }
    if (SvOK(func_sv)) {
        rl_completion_word_break_hook = completion_word_break_hook_wrapper;
    }
    else {
        rl_completion_word_break_hook = NULL;
    }

char *
completer_quote_characters (...)
CODE:
    RETVAL = rl_completer_quote_characters;
    if (items) {
        rl_completer_quote_characters = SvPV_nolen(ST(0));
    }
OUTPUT:
    RETVAL

char *
special_prefixes (...)
CODE:
    RETVAL = rl_special_prefixes;
    if (items) {
        rl_special_prefixes = SvPV_nolen(ST(0));
    }
OUTPUT:
    RETVAL

int
completion_query_items (...)
CODE:
    RETVAL = rl_completion_query_items;
    if (items) {
        rl_completion_query_items = SvIV(ST(0));
    }
OUTPUT:
    RETVAL

int
completion_append_character (...)
CODE:
    RETVAL = rl_completion_append_character;
    if (items) {
        rl_completion_append_character = SvIV(ST(0));
    }
OUTPUT:
    RETVAL

int
ignore_completion_duplicates (...)
CODE:
    RETVAL = rl_ignore_completion_duplicates;
    if (items) {
        rl_ignore_completion_duplicates = SvIV(ST(0));
    }
OUTPUT:
    RETVAL

int
filename_completion_desired (...)
CODE:
    RETVAL = rl_filename_completion_desired;
    if (items) {
        rl_filename_completion_desired = SvIV(ST(0));
    }
OUTPUT:
    RETVAL

int
attempted_completion_over (...)
CODE:
    RETVAL = rl_attempted_completion_over;
    if (items) {
        rl_attempted_completion_over = SvIV(ST(0));
    }
OUTPUT:
    RETVAL

int
completion_type (...)
CODE:
    RETVAL = rl_completion_type;
    if (items) {
        rl_completion_type = SvIV(ST(0));
    }
OUTPUT:
    RETVAL

int
inhibit_completion (...)
CODE:
    RETVAL = rl_inhibit_completion;
    if (items) {
        rl_inhibit_completion = SvIV(ST(0));
    }
OUTPUT:
    RETVAL

# Initializing History

void
using_history ()
CODE:
    using_history();

# History List Management

void
add_history (string)
    const char *string
CODE:
    add_history(string);

void
clear_history ()
CODE:
    clear_history();

# Information About The History List

int
where_history ()
CODE:
    RETVAL = where_history();
OUTPUT:
    RETVAL

const char *
current_history ()
CODE:
    HIST_ENTRY *he = current_history();
    RETVAL = NULL;
    if (he) {
        RETVAL = he->line;
    }
OUTPUT:
    RETVAL

const char *
history_get (offset)
    int offset;
CODE:
    HIST_ENTRY *he = history_get(offset);
    RETVAL = NULL;
    if (he) {
        RETVAL = he->line;
    }
OUTPUT:
    RETVAL

int
history_total_bytes ()
CODE:
    RETVAL = history_total_bytes();
OUTPUT:
    RETVAL

int
history_set_pos (pos)
    int pos;
CODE:
    RETVAL = history_set_pos(pos);
OUTPUT:
    RETVAL

# Managing The History File

int
read_history (filename)
    const char *filename;
CODE:
    RETVAL = read_history(filename);
OUTPUT:
    RETVAL

int
write_history (filename)
    const char *filename;
CODE:
    RETVAL = write_history(filename);
OUTPUT:
    RETVAL

int
history_truncate_file (filename, nlines)
    const char *filename;
    int nlines;
CODE:
    RETVAL = history_truncate_file(filename, nlines);
OUTPUT:
    RETVAL

# History Expansion

char *
history_expand (string)
    char *string;
CODE:
    int retval = history_expand(string, &RETVAL);
OUTPUT:
    RETVAL

# History Variables

int
history_base ()
CODE:
    RETVAL = history_base;
OUTPUT:
    RETVAL

int
history_length ()
CODE:
    RETVAL = history_length;
OUTPUT:
    RETVAL

