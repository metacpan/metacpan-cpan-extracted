%{
/*
 * UUID: db754b9e-f2fd-11dc-b899-00502c05c241
 * Author: Brian M. Ames, bames@apk.net
 * Copyright: Copyright (C) 2008 by Brian M. Ames
 */

#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <utime.h>
#include "parser.tab.h"
#include "tree.h"
#include "parser_routines.h"
#include "lexer.h"
#include "include_path.h"

int unused;
#define ECHO unused = fwrite( yypp_text, yypp_leng, 1, yypp_out )

char *filename;
char *include_file_name;

extern time_t max_st_atime;
extern time_t max_st_mtime;
extern char argz[];
extern size_t argz_len;

YY_BUFFER_STATE include_stack[MAX_INCLUDE_DEPTH];
int buffer_type[MAX_INCLUDE_DEPTH];
int include_stack_ptr = 0;

struct nodeFile *filenode[MAX_INCLUDE_DEPTH];
struct nodeFile *curfilenode;
int file_stack_ptr = 0;

static char *line_buf = NULL;
int line_buf_ptr = 0;

int paren_level;

char *repl_id[MAX_INCLUDE_DEPTH];
int repl_level = 0;

extern int yypp_debug;

short isHex;
short isDec;
short isOct;
short isFloat;
short f_suffix;
short l_suffix;
short u_suffix;
short periods;

%}
%option stack
%option never-interactive 
 //%option debug

%x X_LINE

%x X_INIT

%x X_COND

%x X_ID

%x X_COM

%x X_STR

%x X_CHR

%x X_PP_NUMBER

%x X_PPD_DEFINE

%x X_PPD_DEFINE_ID

%x X_MACRO_PARAMS

%x X_PARAM_ID

%x X_MACRO_REPL

%x X_MACRO_STRING

%x X_MACRO_INV

%x X_MACRO_ARGS

%x X_REPL_ID

%x X_PPD_STRING

%x X_PPD_ID

%x X_PPD_INCLUDE

%x X_PPD_IF

%x X_PPD_IF_DEFINED

%x X_PPD_IF_DEFINEDP

%x X_PPD_IF_ID

%x X_DONT_CARE

%x X_SKIP_WHITESPACE

%x X_UOC

  //[A-Za-z_][0-9A-Za-z_]*              { return copy_string(IDENTIFIER); }

idstart [A-Za-z_]|[\xC0-\xDF][\x80-\xBF]|[\xE0-\xEC\xEE-\xEF][\x80-\xBF]{2}|[\xF0-\xF3][\x80-\xBF]{3}

idcontn [0-9A-Za-z_]|[\xC0-\xDF][\x80-\xBF]|[\xE0-\xEC\xEE-\xEF][\x80-\xBF]{2}|[\xF0-\xF3][\x80-\xBF]{3}

%%


<INITIAL>{
.|\n                                { yyless(0); yy_push_state(X_INIT); yy_push_state(X_LINE);}
}

<X_LINE>{
"//{"                               { yy_push_state(X_UOC); }
\n                                  { end_of_line(); }
\r                                  { ; }
.                                   { if (line_buf_ptr < MAX_LINE_INDEX) line_buf[line_buf_ptr++] = yytext[0]; }
}

<X_INIT,X_PPD_DEFINE,X_PPD_INCLUDE,X_PPD_IF,X_COND,X_MACRO_PARAMS,X_MACRO_REPL>{
[/][/][^{][^\n]*                    { handle_comment(yytext+2); }
"//"                                { ; }
"\\"\n                              { yy_push_state(X_LINE); }
"/"[*]+\s*                          { yy_push_state(X_COM); handle_begin_comment(); }
}

<X_INIT,X_PPD_DEFINE,X_PPD_INCLUDE,X_PPD_IF>{
\x9B                                { ; }
\033                                { ; }
}

<X_INIT,X_PPD_IF>{
[L]?["]                             { yy_push_state(X_STR); }
[L]?[']                             { yy_push_state(X_CHR); }
}

<X_INIT,X_COND>{
^[ \t]*("#"|"??=")[ ]*"elif"[ \t]+   { yy_push_state(X_PPD_IF); return PPD_ELIF; }
^[ \t]*("#"|"??=")[ ]*"else"[ \t]+   { return PPD_ELSE; }
^[ \t]*("#"|"??=")[ ]*"endif"[ \t]+  { return PPD_ENDIF; }
^[ \t]*("#"|"??=")[ ]*"ifdef"[ \t]+  { yy_push_state(X_PPD_ID); return PPD_IFDEF; }
^[ \t]*("#"|"??=")[ ]*"ifndef"[ \t]+ { yy_push_state(X_PPD_ID); return PPD_IFNDEF; }
^[ \t]*("#"|"??=")[ ]*"if"[ \t]+     { yy_push_state(X_PPD_IF); return PPD_IF; }

^[ \t]*("#"|"??=")[ ]*"else"/\n      { return PPD_ELSE; }
^[ \t]*("#"|"??=")[ ]*"endif"/\n     { return PPD_ENDIF; }
\n                                   { yy_push_state(X_LINE); return BCS_WHTSP_NEWLINE; }
}

<X_COND>.                                    { ; }

<X_INIT>{
^[ \t]*"#"[ ]*"define"[ \t]+        { yy_push_state(X_PPD_DEFINE); return PPD_DEFINE; }
^[ \t]*"#"[ ]*"error"[ \t]+         { return PPD_ERROR; }
^[ \t]*"#"[ ]*"include"[ \t]+       { yy_push_state(X_PPD_INCLUDE); return PPD_INCLUDE; }
^[ \t]*"#"[ ]*"line"[ \t]+          { return PPD_LINE; }
^[ \t]*"#"[ ]*"pragma"[ \t]+        { return PPD_PRAGMA; }
^[ \t]*"#"[ ]*"undef"[ \t]+         { yy_push_state(X_PPD_ID); return PPD_UNDEF; }

^[ \t]*"??="[ ]*"define"[ \t]+      { yy_push_state(X_PPD_DEFINE); return PPD_DEFINE; }
^[ \t]*"??="[ ]*"error"[ \t]+       { return PPD_ERROR; }
^[ \t]*"??="[ ]*"include"[ \t]+     { yy_push_state(X_PPD_INCLUDE); return PPD_INCLUDE; }
^[ \t]*"??="[ ]*"line"[ \t]+        { return PPD_LINE; }
^[ \t]*"??="[ ]*"pragma"[ \t]+      { return PPD_PRAGMA; }
^[ \t]*"??="[ ]*"undef"[ \t]+       { yy_push_state(X_PPD_ID); return PPD_UNDEF; }

}

<X_INIT,X_PPD_IF>{
"asm"/[^a-z_]                       { return KWD_ASM; }
"auto"/[^a-z_]                      { return KWD_AUTO; }
"bool"/[^a-z_]                      { return KWD_BOOL; }
"break"/[^a-z_]                     { return KWD_BREAK; }
"case"/[^a-z_]                      { return KWD_CASE; }
"catch"/[^a-z_]                     { return KWD_CATCH; }
"char"/[^a-z_]                      { return KWD_CHAR; }
"class"/[^a-z_]                     { return KWD_CLASS; }
"const"/[^a-z_]                     { return KWD_CONST; }
"const_cast"/[^a-z_]                { return KWD_CONST_CAST; }
"continue"/[^a-z_]                  { return KWD_CONTINUE; }
"default"/[^a-z_]                   { return KWD_DEFAULT; }
"delete"/[^a-z_]                    { return KWD_DELETE; }
"do"/[^a-z_]                        { return KWD_DO; }
"double"/[^a-z_]                    { return KWD_DOUBLE; }
"dynamic_cast"/[^a-z_]              { return KWD_DYNAMIC_CAST; }
"else"/[^a-z_]                      { return KWD_ELSE; }
"enum"/[^a-z_]                      { return KWD_ENUM; }
"explicit"/[^a-z_]                  { return KWD_EXPLICIT; }
"export"/[^a-z_]                    { return KWD_EXPORT; }
"extern"/[^a-z_]                    { return KWD_EXTERN; }
"false"/[^a-z_]                     { return KWD_FALSE; }
"float"/[^a-z_]                     { return KWD_FLOAT; }
"for"/[^a-z_]                       { return KWD_FOR; }
"friend"/[^a-z_]                    { return KWD_FRIEND; }
"goto"/[^a-z_]                      { return KWD_GOTO; }
"if"/[^a-z_]                        { return KWD_IF; }
"inline"/[^a-z_]                    { return KWD_INLINE; }
"int"/[^a-z_]                       { return KWD_INT; }
"long"/[^a-z_]                      { return KWD_LONG; }
"mutable"/[^a-z_]                   { return KWD_MUTABLE; }
"namespace"/[^a-z_]                 { return KWD_NAMESPACE; }
"new"/[^a-z_]                       { return KWD_NEW; }
"operator"/[^a-z_]                  { return KWD_OPERATOR; }
"private"/[^a-z_]                   { return KWD_PRIVATE; }
"protected"/[^a-z_]                 { return KWD_PROTECTED; }
"public"/[^a-z_]                    { return KWD_PUBLIC; }
"register"/[^a-z_]                  { return KWD_REGISTER; }
"reinterpret_cast"/[^a-z_]          { return KWD_REINTERPRET_CAST; }
"return"/[^a-z_]                    { return KWD_RETURN; }
"short"/[^a-z_]                     { return KWD_SHORT; }
"signed"/[^a-z_]                    { return KWD_SIGNED; }
"sizeof"/[^a-z_]                    { return KWD_SIZEOF; }
"static"/[^a-z_]                    { return KWD_STATIC; }
"static_cast"/[^a-z_]               { return KWD_STATIC_CAST; }
"struct"/[^a-z_]                    { return KWD_STRUCT; }
"switch"/[^a-z_]                    { return KWD_SWITCH; }
"template"/[^a-z_]                  { return KWD_TEMPLATE; }
"this"/[^a-z_]                      { return KWD_THIS; }
"throw"/[^a-z_]                     { return KWD_THROW; }
"true"/[^a-z_]                      { return KWD_TRUE; }
"try"/[^a-z_]                       { return KWD_TRY; }
"typedef"/[^a-z_]                   { return KWD_TYPEDEF; }
"typename"/[^a-z_]                  { return KWD_TYPENAME; }
"typeid"/[^a-z_]                    { return KWD_TYPEID; }
"union"/[^a-z_]                     { return KWD_UNION; }
"unsigned"/[^a-z_]                  { return KWD_UNSIGNED; }
"using"/[^a-z_]                     { return KWD_USING; }
"virtual"/[^a-z_]                   { return KWD_VIRTUAL; }
"void"/[^a-z_]                      { return KWD_VOID; }
"volatile"/[^a-z_]                  { return KWD_VOLATILE; }
"wchar_t"/[^a-z_]                   { return KWD_WCHAR_T; }
"while"/[^a-z_]                     { return KWD_WHILE; }

"and"/[^a-z_]                       { return OP_ALT_LOGICAL_AND; }
"and_eq"/[^a-z_]                    { return OP_ALT_ASSIGN_BIT_AND; }
"bitand"/[^a-z_]                    { return OP_ALT_BIT_AND; }
"bitor"/[^a-z_]                     { return OP_ALT_BIT_OR; }
"compl"/[^a-z_]                     { return OP_ALT_BIT_NOT; }
"not"/[^a-z_]                       { return OP_ALT_LOGICAL_NOT; }
"not_eq"/[^a-z_]                    { return OP_ALT_NE; }
"or"/[^a-z_]                        { return OP_ALT_LOGICAL_OR; }
"or_eq"/[^a-z_]                     { return OP_ALT_ASSIGN_BIT_OR; }
"xor"/[^a-z_]                       { return OP_ALT_BIT_PLUS; }
"xor_eq"/[^a-z_]                    { return OP_ALT_ASSIGN_BIT_PLUS; }

[\\][U][0-9A-Fa-f]{8}               { yyless(0); yy_push_state(X_ID); }
[\\][u][0-9A-Fa-f]{4}               { yyless(0); yy_push_state(X_ID); }
{idstart}                           { yyless(0); yy_push_state(X_ID); }

[.]?[0-9][Xx]?                      { copy_string(yytext); pp_number_init(yytext[0],yytext[1]); yy_push_state(X_PP_NUMBER); }

"??="                               { return BCS_PUNCT_HASH; }
"??/"                               { return BCS_PUNCT_BACKSLASH; }
"??'"                               { return BCS_PUNCT_CARET; }
"??'="                              { return OP_ASSIGN_BIT_PLUS; }
"??("                               { return BCS_PUNCT_OPEN_BRACKET; }
"??)"                               { return BCS_PUNCT_CLOSE_BRACKET; }
"??!"                               { return BCS_PUNCT_VERTICAL_BAR; }
"??!="                              { return OP_ASSIGN_BIT_OR; }
"??!??!"                            { return OP_LOGICAL_OR; }
"??<"                               { return BCS_PUNCT_OPEN_BRACE; }
"??>"                               { return BCS_PUNCT_CLOSE_BRACE; }
"??-"                               { return BCS_PUNCT_TILDE; }

"<%"                                { return ALT_PUNCT_OPEN_BRACE; }
"%>"                                { return ALT_PUNCT_CLOSE_BRACE; }
"<:"                                { return ALT_PUNCT_OPEN_BRACKET; }
":>"                                { return ALT_PUNCT_CLOSE_BRACKET; }
"%:%:"                              { return ALT_OP_TOKEN_SPLICE; }
"%:"                                { return ALT_PUNCT_HASH; }

"!="                                { return OP_NE; }
"##"                                { return OP_TOKEN_SPLICE; }
"%="                                { return OP_ASSIGN_MODULO; }
"&&"                                { return OP_LOGICAL_AND; }
"&="                                { return OP_ASSIGN_BIT_AND; }
"*="                                { return OP_ASSIGN_MULTIPLY; }
"++"                                { return OP_INCREMENT; }
"+="                                { return OP_ASSIGN_PLUS; }
"--"                                { return OP_DECREMENT; }
"-="                                { return OP_ASSIGN_MINUS; }
"->*"                               { return OP_POINTER_POINTER_TO_MEMBER; }
"->"                                { return OP_POINTER_MEMBER; }
".*"                                { return OP_OBJECT_POINTER_TO_MEMBER; }
"..."                               { return DECL_VAR_ARGS; }
"/="                                { return OP_ASSIGN_DIVIDE; }
"::"                                { return OP_SCOPE_REF; }
"<<="                               { return OP_ASSIGN_SHIFT_LEFT; }
"<<"                                { return OP_SHIFT_LEFT; }
"<="                                { return OP_LE; }
"=="                                { return OP_EQ; }
">="                                { return OP_GE; }
">>="                               { return OP_ASSIGN_SHIFT_RIGHT; }
">>"                                { return OP_SHIFT_RIGHT; }
"^="                                { return OP_ASSIGN_BIT_PLUS; }
"|="                                { return OP_ASSIGN_BIT_OR; }
"||"                                { return OP_LOGICAL_OR; }

}

<X_PPD_IF>{

\n                                  { yyless(0); yy_pop_state();  }

}

<X_INIT,X_PPD_IF>{

[ \t]                               { ; }
[!]      { return BCS_PUNCT_EXCLAMATION; }

[#]      { return BCS_PUNCT_HASH; }
[%]      { return BCS_PUNCT_PERCENT; }
[&]      { return BCS_PUNCT_AMPERSAND; }

[(]      { return BCS_PUNCT_OPEN_PARENTHESIS; }
[)]      { return BCS_PUNCT_CLOSE_PARENTHESIS; }
[*]      { return BCS_PUNCT_ASTERISK; }
[+]      { return BCS_PUNCT_PLUS; }
[,]      { return BCS_PUNCT_COMMA; }
[-]      { return BCS_PUNCT_MINUS; }
[.]      { return BCS_PUNCT_PERIOD; }
[/]      { return BCS_PUNCT_SLASH; }
[:]      { return BCS_PUNCT_COLON; }
[;]      { return BCS_PUNCT_SEMICOLON; }
[<]      { return BCS_PUNCT_LESS_THAN; }
[=]      { return BCS_PUNCT_EQUAL; }
[>]      { return BCS_PUNCT_GREATER_THAN; }
[?]      { return OP_CONDITIONAL; }
[\[]     { return BCS_PUNCT_OPEN_BRACKET; }
[\\]     { return BCS_PUNCT_BACKSLASH; }
[\]]      { return BCS_PUNCT_CLOSE_BRACKET; }
[\^]      { return BCS_PUNCT_CARET; }
[{]      { return BCS_PUNCT_OPEN_BRACE; }
[|]      { return BCS_PUNCT_VERTICAL_BAR; }
[}]      { return BCS_PUNCT_CLOSE_BRACE; }
[~]      { return BCS_PUNCT_TILDE; }
.                                   { return ECS_NULL+yytext[0]; }

}

<X_PPD_IF>{
"defined"[ \t]*[(]                  { yy_push_state(X_PPD_IF_DEFINEDP); }
"defined"/[^a-z_]                   { yy_push_state(X_PPD_IF_DEFINED); }
}

<X_PPD_IF_DEFINEDP>[)]              { yy_pop_state(); }

<X_PPD_IF_DEFINED,X_PPD_IF_DEFINEDP>{
[ \t]+                              { ; }
[\\][U][0-9A-Fa-f]{8}               { yyless(0); yy_push_state(X_PPD_IF_ID); }
[\\][u][0-9A-Fa-f]{4}               { yyless(0); yy_push_state(X_PPD_IF_ID); }
{idstart}                           { yyless(0); yy_push_state(X_PPD_IF_ID); }
\n                                  { yyless(0); yy_pop_state(); }
.                                   { yyless(0); yy_pop_state(); }
}

<X_PPD_IF_ID>{
[\\][U][0-9A-Fa-f]{8}               { copy_string(yytext); }
[\\][u][0-9A-Fa-f]{4}               { copy_string(yytext); }
{idcontn}                           { copy_utf8((unsigned char *) yytext); }
.|\n                                { yyless(0); yy_pop_state(); yypp_lval.ival=test_identifier(); return BOOLEAN_LITERAL; }
}

<X_ID,X_PARAM_ID,X_REPL_ID,X_PPD_ID,X_PPD_DEFINE_ID>{
[\\][U][0-9A-Fa-f]{8}               { copy_string(yytext); }
[\\][u][0-9A-Fa-f]{4}               { copy_string(yytext); }
{idstart}                           { copy_utf8((unsigned char *) yytext); }
{idcontn}                           { copy_utf8((unsigned char *) yytext); }
}

<X_ID>{
\x9B                                { yy_pop_state(); return IDENTIFIER; }
\033                                { yy_pop_state(); if (not_an_object_macro()) return IDENTIFIER; }
.|\n                                { yyless(0); yy_pop_state(); if (not_a_macro()) return IDENTIFIER; else return REPLACED_IDENTIFIER; }
}

<X_PARAM_ID>{
.|\n                                { yyless(0); yy_pop_state(); return IDENTIFIER; }
}

<X_REPL_ID>{
.|\n                                { yyless(0); yy_pop_state(); if (is_param_id()) return IDENTIFIER; else if (is_macro_id()) return NON_REPLACEABLE_IDENTIFIER; else return STRING_LITERAL; }
}

<X_PPD_ID>{
.|\n                                { yyless(0); yy_pop_state(); return IDENTIFIER; }
}

<X_PPD_DEFINE_ID>{
.|\n                                { yyless(0); yy_pop_state(); }
}

<X_COM>{
^[ \t]*[*]/[^/]                     { ; }
"*/"                                { yy_pop_state(); handle_end_comment(); }
\n                                  { yy_push_state(X_LINE); handle_comment_char('\n'); }
.                                   { handle_comment_char(yytext[0]); }

}

<X_STR>{
"\\\\"                              { add_char(yytext[1]); }
"\\\""                              { add_char(yytext[1]); }
["]                                 { yy_pop_state(); return STRING_LITERAL; }
.                                   { add_char(yytext[0]); }
}

<X_CHR>{
"\\\\"                              { add_char(yytext[0]); add_char(yytext[1]); }
"\\\'"                              { add_char(yytext[0]); add_char(yytext[1]); }
[']                                 { yy_pop_state(); return CHARACTER_LITERAL; }
.                                   { add_char(yytext[0]); }
}

<X_PP_NUMBER>{
[\\][U][0-9A-Fa-f]{8}               { pp_not_a_literal(); copy_string(yytext); }
[\\][u][0-9A-Fa-f]{4}               { pp_not_a_literal(); copy_string(yytext); }
[\xC0-\xDF][\x80-\xBF]              { pp_not_a_literal(); copy_utf8((unsigned char *) yytext); }
[\xE0-\xEC\xEE-\xEF][\x80-\xBF]{2}  { pp_not_a_literal(); copy_utf8((unsigned char *) yytext); }
[\xF0-\xF3][\x80-\xBF]{3}           { pp_not_a_literal(); copy_utf8((unsigned char *) yytext); }
[Ee][-+0-9]                         { pp_exponent(yytext[1]); add_char(yytext[0]); add_char(yytext[1]); }
[0-7]                               { pp_octal_digit(); add_char(yytext[0]); }
[89]                                { pp_decimal_digit(); add_char(yytext[0]); }
[A-Ea-e]                            { pp_hexadecimal_digit(); add_char(yytext[0]); }
[Ff]                                { pp_f_suffix(); add_char(yytext[0]); }
[G-Kg-kM-Tm-tV-Zv-z_]               { pp_not_a_literal(); add_char(yytext[0]); }
[Ll]                                { pp_l_suffix(); add_char(yytext[0]); }
[Uu]                                { pp_u_suffix(); add_char(yytext[0]); }
[.]                                 { pp_period(); add_char(yytext[0]); }
.|\n                                { yyless(0); yy_pop_state(); return test_pp_number(); }
}

<X_PPD_INCLUDE>{
\n                                  { yy_pop_state(); handle_location(); yy_push_state(X_LINE); return BCS_WHTSP_NEWLINE; }
[<][ -=?-~]+[>]                     { copy_string_less(yytext); return SYSTEM_HEADER_STRING; }
["][ -!#-~]+["]                     { copy_string_less(yytext); return HEADER_STRING; }
.                                   { ; }
}

<X_PPD_DEFINE>{
"and"/[(]                           { yy_pop_state(); return INV_MFI_LOGICAL_AND; }
"and_eq"/[(]                        { yy_pop_state(); return INV_MFI_ASSIGN_BIT_AND; }
"bitand"/[(]                        { yy_pop_state(); return INV_MFI_BIT_AND; }
"bitor"/[(]                         { yy_pop_state(); return INV_MFI_BIT_OR; }
"compl"/[(]                         { yy_pop_state(); return INV_MFI_BIT_NOT; }
"not"/[(]                           { yy_pop_state(); return INV_MFI_LOGICAL_NOT; }
"not_eq"/[(]                        { yy_pop_state(); return INV_MFI_NE; }
"or"/[(]                            { yy_pop_state(); return INV_MFI_LOGICAL_OR; }
"or_eq"/[(]                         { yy_pop_state(); return INV_MFI_ASSIGN_BIT_OR; }
"xor"/[(]                           { yy_pop_state(); return INV_MFI_BIT_PLUS; }
"xor_eq"/[(]                        { yy_pop_state(); return INV_MFI_ASSIGN_BIT_PLUS; }
}

<X_PPD_DEFINE,X_PPD_ID>{
"and"/[^a-z_]                       { yy_pop_state(); return INV_ALT_LOGICAL_AND; }
"and_eq"/[^a-z_]                    { yy_pop_state(); return INV_ALT_ASSIGN_BIT_AND; }
"bitand"/[^a-z_]                    { yy_pop_state(); return INV_ALT_BIT_AND; }
"bitor"/[^a-z_]                     { yy_pop_state(); return INV_ALT_BIT_OR; }
"compl"/[^a-z_]                     { yy_pop_state(); return INV_ALT_BIT_NOT; }
"not"/[^a-z_]                       { yy_pop_state(); return INV_ALT_LOGICAL_NOT; }
"not_eq"/[^a-z_]                    { yy_pop_state(); return INV_ALT_NE; }
"or"/[^a-z_]                        { yy_pop_state(); return INV_ALT_LOGICAL_OR; }
"or_eq"/[^a-z_]                     { yy_pop_state(); return INV_ALT_ASSIGN_BIT_OR; }
"xor"/[^a-z_]                       { yy_pop_state(); return INV_ALT_BIT_PLUS; }
"xor_eq"/[^a-z_]                    { yy_pop_state(); return INV_ALT_ASSIGN_BIT_PLUS; }
}

<X_PPD_DEFINE>{
[\\][U][0-9A-Fa-f]{8}               { yyless(0); yy_push_state(X_PPD_DEFINE_ID); }
[\\][u][0-9A-Fa-f]{4}               { yyless(0); yy_push_state(X_PPD_DEFINE_ID); }
{idstart}                           { yyless(0); yy_push_state(X_PPD_DEFINE_ID); }
[(]                                 { yyless(0); yy_pop_state(); yy_push_state(X_MACRO_REPL); yy_push_state(X_MACRO_PARAMS); return MACRO_FUNCTION_IDENTIFIER; }
\n                                  { yyless(0); yy_pop_state(); return MACRO_OBJECT_IDENTIFIER; }
.                                   { yyless(0); yy_pop_state(); yy_push_state(X_MACRO_REPL); yy_push_state(X_SKIP_WHITESPACE); return MACRO_OBJECT_IDENTIFIER; }
}

<X_MACRO_PARAMS>{
[(]                                 { return BCS_PUNCT_OPEN_PARENTHESIS;}
[)]                                 { yy_pop_state(); yy_push_state(X_SKIP_WHITESPACE); return BCS_PUNCT_CLOSE_PARENTHESIS;}
[,]                                 { return BCS_PUNCT_COMMA;}
{idstart}                           { yyless(0); yy_push_state(X_PARAM_ID); }
.                                   { ; }
\n                                  { yyless(0); yy_pop_state(); }
}

<X_MACRO_REPL>{
[ \t]*[#][#][ \t]*                  { return OP_TOKEN_SPLICE;}
[#][ \t]*                           { return OP_STRINGIZE;}
{idstart}                           { yyless(0); yy_push_state(X_REPL_ID); }
\n                                  { yyless(0); yy_pop_state(); }
.                                   { copy_string(yytext); yy_push_state(X_MACRO_STRING); }
}

<X_MACRO_ARGS>{
[(]                                 { paren_level++; copy_string(yytext); }
[)]                                 { if(paren_level == 0) { yyless(0); yy_pop_state(); } else {paren_level--; copy_string(yytext);} }
[,]                                 { if(paren_level == 0) handle_macro_arg(); else copy_string(yytext); }
.                                   { copy_string(yytext); }
}

<X_MACRO_INV>{
[ \t]                               { ; }
\033                                { yy_pop_state(); }
[(]                                 { yy_push_state(X_MACRO_ARGS); }
[)]                                 { yy_pop_state(); handle_macro_arg(); do_replacement();}
}

<X_MACRO_STRING>{
\\[ \t]*\n                          { yy_push_state(X_LINE);}
\n                                  { yyless(0); yy_pop_state(); return STRING_LITERAL; }
[#]                                 { yyless(0); yy_pop_state(); return STRING_LITERAL; }
{idstart}                           { yyless(0); yy_pop_state(); return STRING_LITERAL; }
.                                   { copy_string(yytext); }
}

<X_PPD_STRING>{
\\[ \t]*\n                          { yy_push_state(X_LINE);}
\n                                  { yyless(0); yy_pop_state(); return STRING_LITERAL; }
[ \t]*"##"[ \t]                     { ; }
.                                   { copy_string(yytext); }
}

<X_SKIP_WHITESPACE>{
[ \t]+                              { ; }
\\[ \t]*\n                          { yy_push_state(X_LINE);}
\n                                  { yyless(0); yy_pop_state(); }
.                                   { yyless(0); yy_pop_state(); }
}

<X_UOC>{
[A-Za-z_][0-9A-Za-z_]*              { handle_use_on_code(strdup(yytext)); }
[}]                                 { yy_pop_state(); }
\n                                  { yyless(0); yy_pop_state(); }
.                                   { ; }
}

<*><<EOF>> {
  if (buffer_type[include_stack_ptr] == BUFFER_TYPE_RESCAN) {
    repl_level--;
  }
  if (include_stack_ptr <= 0) {
    yyterminate();
  } else {
    yy_delete_buffer( YY_CURRENT_BUFFER );
    if(buffer_type[include_stack_ptr] == BUFFER_TYPE_FILE) {
      handle_file_end(preprocessing_file_index);
      file_stack_ptr--;
      curfilenode = filenode[file_stack_ptr];
    }
    yy_switch_to_buffer( include_stack[--include_stack_ptr] );
  }
}

%%

/*
 *
 */
void initialize_lexer(char *filename) {
  struct stat st;
  int res;

  include_stack_ptr = 0;
  file_stack_ptr = 0;
  curfilenode = newNodeFile(preprocessing_file_index);
  filenode[file_stack_ptr] = curfilenode;
  curfilenode->lines = 1;
  curfilenode->path = strdup(filename);
  res = stat(filename, &st);
  if (res == 0) {
    curfilenode->atime = st.st_atime;
    if (st.st_atime > max_st_atime) {
      max_st_atime = st.st_atime;
    }
    curfilenode->mtime = st.st_mtime;
    if (st.st_mtime > max_st_mtime) {
      max_st_mtime = st.st_mtime;
    }
  }

  repl_id[0] = NULL;
  line_buf = (char *) malloc(MAX_LINE_LENGTH);
  memset(line_buf,0,MAX_LINE_LENGTH);
}

/*
 *
 */
void handle_include_file() {
  int i,j,len;
  char *path;
  char *filename;
  int result;

  if (yypp_debug != 0) {
    fprintf(stderr,"%s %s\n",__func__,include_file_name);
  }
//  filename = filenames[file_stack_ptr];
  filename = curfilenode->path;
  
  i = strlen(filename)-1;
  while (i >=0 && filename[i] != '/' && filename[i] != '\\') i--;
  i++;
  
  len=strlen(include_file_name)+i+1;
  if (yypp_debug != 0) {
    fprintf(stderr,"%s %s %d %d\n",filename,include_file_name,i,len);
  }
  path = (char *) malloc(len);
  for (j=i--; i >=0; i-- ) path[i] = filename[i];
  for (i=0; include_file_name[i] >0; i++, j++ ) path[j] = include_file_name[i];
  path[j] = 0;
  result = include_file(path);
  if (result != 0) {
    handle_file_begin(preprocessing_file_index);
  }
}

/*
 *
 */
FILE *open_include_file(char *path) {
  struct stat st;
  int res;
  FILE *file;

  if (yypp_debug != 0) {
    fprintf(stderr,"%s(%s) start\n",__func__,path);
  }
  file = fopen(path, "r" );
  if ( file ) {
    include_stack[include_stack_ptr++] = YY_CURRENT_BUFFER;
    yy_switch_to_buffer(yy_create_buffer( yyin, YY_BUF_SIZE ) );
    file_stack_ptr++;
    curfilenode = newNodeFile(preprocessing_file_index);
    filenode[file_stack_ptr] = curfilenode;
    curfilenode->lines = 1;
    curfilenode->path = strdup(path);

    buffer_type[include_stack_ptr] = BUFFER_TYPE_FILE;
    res = stat(path, &st);
    if (res == 0) {
      curfilenode->atime = st.st_atime;
      if (st.st_atime > max_st_atime) {
        max_st_atime = st.st_atime;
      }
      curfilenode->mtime = st.st_mtime;
      if (st.st_mtime > max_st_mtime) {
        max_st_mtime = st.st_mtime;
      }
    }
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(%s) end\n",__func__,path);
  }
  return file;
}

/*
 *
 */
int include_file(char *path) {
  static FILE *file;
  int result = 0;
  char *inc_path = 0;
  char buf[256];
  char *fnm;

  if (yypp_debug != 0) {
    fprintf(stderr,"%s(%s) start\n",__func__,path);
  }
  if ( include_stack_ptr >= MAX_INCLUDE_DEPTH ) {
    fprintf( stderr, "Includes nested too deeply %s\n",path );
    return 0;
  } else {

    file = open_include_file(path);
    if ( file ) {
      yyin = file;
      add_dependency(include_file_name);
      result = 1;
    } else {
      goto_incl_first();
      while ((inc_path = get_incl_path()) != NULL) {
        sprintf(buf,"%s/%s",inc_path,include_file_name);
        fnm = strdup(buf);
        file = open_include_file(fnm);
        if ( file ) {
          yyin = file;
          add_dependency(strdup(fnm));
          incl_path_used();
          return 1;
        }
        free(fnm);
        goto_incl_next();
      }
      fprintf( stderr, "Error: open failed for include file %s\n",path );
      add_dependency(include_file_name);
    }
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(%s) end\n",__func__,path);
  }
  return result;
}

/*
 *
 */
void include_string(const char *string, int bfr_type) {
  if (bfr_type == BUFFER_TYPE_RESCAN) {
    if(repl_level < 10) {
      repl_level++;
    } else {
      return;
    }
  }
  include_stack[include_stack_ptr++] = YY_CURRENT_BUFFER;
  buffer_type[include_stack_ptr] = bfr_type;
  yy_scan_string(string);
}

/*
 *
 */
int not_a_macro() {
  int result,tr;
  char *repl;
  result = 0;
  tr = test_identifier();
  switch (tr) {
  case 1:
//    include_string("",BUFFER_TYPE_RESCAN);
    break;
  case 2:
    repl = get_replacement_string();
//    repl = get_function_replacement_string();
    if (repl != NULL) {
      include_string(repl,BUFFER_TYPE_RESCAN);
    } else {
      result = 1;
    }
    break;
  case 3:
    break;
  case 4:
    paren_level = 0;
    yy_push_state(X_MACRO_INV);
    break;
  default:
    result = 1;
    break;
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"%s() = %d;\n",__func__,result);
  }

  return result;
}

/*
 *
 */
int not_an_object_macro() {
  int result,tr;
  char *repl;
  result = 0;
  tr = test_identifier();
  switch (tr) {
  case 1:
//    include_string("",BUFFER_TYPE_RESCAN);
    break;
  case 2:
    repl = get_replacement_string();
//    repl = get_function_replacement_string();
    if (repl != NULL) {
      include_string(repl,BUFFER_TYPE_RESCAN);
    } else {
      result = 1;
    }
    break;
  case 3:
  case 4:
  default:
    result = 1;
    break;
  }
  if (yypp_debug != 0) {
    fprintf(stderr,"%s() = %d;\n",__func__,result);
  }

  return result;
}

/*
 *
 */
void do_replacement() {
  char *repl;

  repl = get_replacement_string();
//  repl = get_function_replacement_string();
  if (repl != NULL) {
    include_string(repl,BUFFER_TYPE_RESCAN);
  }
}

/*
 *
 */
char *getCurrentFilename() {
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(%d);\n",__func__,file_stack_ptr);
  }
//  return filenames[file_stack_ptr];
  return curfilenode->path;
}

/*
 *
 */
int getCurrentLineNumber() {
  if (yypp_debug != 0) {
    fprintf(stderr,"%s(%d);\n",__func__,file_stack_ptr);
  }
//  return line_counts[file_stack_ptr];
  if(curfilenode != NULL) {
    return curfilenode->lines;
  }
  return -1;
}

/*
 *
 */
void pp_number_init(char first, char second) {

  switch (first) {
  case '0':
    if (second == 'X' || second == 'x') {
      isHex = 1; 
      isOct = 0;
    } else {
      isHex = 0; 
      isOct = 1;
    }
    isDec = 0;
    isFloat = 1;
    periods = 0;
    break;
  case '.':
    isHex = 0;
    isDec = 0;
    isOct = 0;
    isFloat = 1;
    periods = 1;
    break;
  default:
    isHex = 0;
    isDec = 1;
    isOct = 0;
    isFloat = 1;
    periods = 0;
    break;
  }
  f_suffix = 0;
  l_suffix = 0;
  u_suffix = 0;
}

/*
 *
 */
void pp_not_a_literal() {
//  fprintf(stderr,"pp_not_a_literal()\n");
  isHex = 0;
  isDec = 0;
  isOct = 0;
  isFloat = 0;
}

/*
 *
 */
void pp_octal_digit() {
  if(u_suffix != 0 || l_suffix != 0) {
    pp_not_a_literal();
  }
}

/*
 *
 */
void pp_decimal_digit() {
  if(u_suffix != 0 || l_suffix != 0) {
    pp_not_a_literal();
  }
  isOct = 0;
}

/*
 *
 */
void pp_hexadecimal_digit() {
  if(u_suffix != 0 || l_suffix != 0) {
    pp_not_a_literal();
  }
  isDec = 0;
  isOct = 0;
  isFloat = 0;
}

/*
 *
 */
void pp_l_suffix() {
  if(l_suffix != 0) {
    pp_not_a_literal();
  }
  if(f_suffix != 0) {
    isFloat = 0;
  }
  l_suffix = 1;
}

/*
 *
 */
void pp_f_suffix() {
  if(u_suffix != 0 || l_suffix != 0) {
    pp_not_a_literal();
  }
  isDec = 0;
  isOct = 0;
  f_suffix++;
}

/*
 *
 */
void pp_u_suffix() {
  if(u_suffix != 0) {
    pp_not_a_literal();
  }
  isFloat = 0;
  u_suffix = 1;
}

/*
 *
 */
void pp_exponent(char second) {
  if (second == '+' || second == '-') isHex =  0;
  isDec = 0;
  isOct = 0;
  periods = 0;
}

/*
 *
 */
void pp_period() {
  if(periods != 0) {
    pp_not_a_literal();
  }
  isHex = 0;
  isDec = 0;
  isOct = 0;
  periods = 1;
}

/*
 *
 */
int test_pp_number() {
  if (isOct) {
    yypp_lval.lval = get_value_octal();
    return OCTAL_LITERAL;
  }
  if (isDec) {
    yypp_lval.lval = get_value_decimal();
    return DECIMAL_LITERAL;
  }
  if (isHex) {
    yypp_lval.lval = get_value_hexadecimal();
    return HEXADECIMAL_LITERAL;
  }
  if(f_suffix > 1) {
    isFloat = 0;
  }
  if (isFloat) {
    return FLOATING_LITERAL;
  }
  return PP_NUMBER;
}

/*
 *
 */
void end_of_line() {
  static char *ln;
  int matched;

  matched = use_on_code_matched();
  if (yypp_debug != 0) {
    fprintf(stderr,"matched: %d, line %d %s: \"%s\"\n",matched,curfilenode->lines,curfilenode->path,line_buf);
  }
  line_buf[line_buf_ptr++] = '\n';
  if (matched != 0) {
    handle_location();
//    line_counts[file_stack_ptr]++;
    curfilenode->lines++;
    yy_pop_state();
    ln = strdup(line_buf);
    include_string(ln,BUFFER_TYPE_LINE);
  }
  line_buf_ptr=0;
  memset(line_buf,0,MAX_LINE_LENGTH);
}

/*
 *
 */
void enter_cond_state() {
  int start;

  start = YY_START;
  if(start == X_PPD_IF) {
    yy_push_state(X_COND);
  }
}

/*
 *
 */
void exit_cond_state() {
  int start;

  start = YY_START;
  if(start == X_COND) {
    yy_pop_state();
  }
}

/*
 * This exists only to prevent warnings during compilation.
 */
void dummy() {
  yyunput(0,0);
  if(yy_top_state == NULL);
}
