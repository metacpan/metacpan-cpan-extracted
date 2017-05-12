/*
 * UUID: bb188d3b-e320-11dc-8b9d-00502c05c241
 * Author: Brian M. Ames, bames@apk.net
 * Copyright: Copyright (C) 2008 by Brian M. Ames
 */

#ifndef _bb188d3b_e320_11dc_8b9d_00502c05c241_
#define _bb188d3b_e320_11dc_8b9d_00502c05c241_

#include "tree.h"

#define MAX_COMMENT_STRING 2048
#define COMMENT_BUFFER_SIZE MAX_COMMENT_STRING+1
#define CHAR_BUF_SIZE 512
#define CONDITION_DEPTH 128

int parser_routines_init();
int predefined_macro_init();
int idncmp(const void *idn1, const void *idn2);
int idcmp(const void *id1, const void *id2);
int depcmp(const void *idn1, const void *idn2);
int add_dependency(char *dep_path);

void add_char(int ch);
void copy_string(char *chars);
void copy_string_less(char *chars);
void copy_utf8(unsigned char *chars);
long get_value_octal();
long get_value_decimal();
long get_value_hexadecimal();

void handle_comment(char *tokenString);
void handle_begin_comment();
void handle_comment_char(int);
void handle_end_comment();
void handle_file_begin(enum tokenIndex ti);
void handle_file_end(enum tokenIndex token);
void handle_location();
void handle_token(enum tokenIndex ti);
void handle_string_token(enum tokenIndex ti);
void handle_token_open(enum tokenIndex ti);
void handle_token_close(enum tokenIndex ti);
int test_identifier();
void doNothing(void *nodep);
void repl_destroy();
char *get_replacement_string();
char *get_function_replacement_string();
void handle_identifier(enum tokenIndex ti);
void handle_nonrepl_identifier(enum tokenIndex ti);
void handle_identifier_open(enum tokenIndex ti);
void handle_include(enum tokenIndex ti);
void handle_command_line_define(char *arg);
void handle_define(const char *identifier);
void handle_replacement_open(enum tokenIndex ti);
void handle_replacement_close(enum tokenIndex token);
int get_param_index(char *identifier);
int skip_line();
int dont_care();
int is_param_id();
int is_macro_id();
void handle_macro_arg();
void handle_macro_open(enum tokenIndex ti);
void handle_macro_close(enum tokenIndex ti);
void handle_macro_undef(enum tokenIndex ti);
void handle_if_open(enum tokenIndex ti, int value);
void handle_ifdef_open(enum tokenIndex ti);
void handle_ifndef_open(enum tokenIndex ti);
void handle_else_open(enum tokenIndex ti);
void handle_elif_open(enum tokenIndex ti, int value);
void handle_elif_close(enum tokenIndex ti);
void handle_endif(enum tokenIndex ti);
void handle_header_name(enum tokenIndex ti);
void handle_pp_number();
void handle_invalid_macro_id(enum tokenIndex ti);

void define_use_on_code(const char *use_on_code);
void handle_use_on_code(const char *use_on_code);
int use_on_code_matched();
void define_include_directory(char *directory);

#endif // ifndef _bb188d3b_e320_11dc_8b9d_00502c05c241_

