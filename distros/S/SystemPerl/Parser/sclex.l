%option noyywrap align never-interactive prefix="sclex"
%{
/******************************************************************************
 * DESCRIPTION: SystemC lexer
 *
 * This file is part of SystemC-Perl.
 *
 * Author: Wilson Snyder <wsnyder@wsnyder.org>
 *
 * Code available from: http://www.veripool.org/systemperl
 *
 ******************************************************************************
 *
 * Copyright 2001-2014 by Wilson Snyder.  This program is free software;
 * you can redistribute it and/or modify it under the terms of either the GNU
 * Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 *****************************************************************************/

#include "scparse.h"
#include "scgrammer.h"

#define SCLEX_MAX_INCLUDE_DEPTH 20

// Flex 2.5.35 has compile warning in ECHO, so we'll default our own rule
#define ECHO yyerror("Missing sclex.l rule: ECHO rule invoked");

typedef struct {
    int lineno;
    const char *filename;
    YY_BUFFER_STATE buffer;
} ScLexInclude_t ;
ScLexInclude_t sclex_includes[SCLEX_MAX_INCLUDE_DEPTH];

int sclex_include_stack_ptr = 0;

YYSTYPE scgrammerlval;
#define yylval scgrammerlval

#define LINENO (scParserLex.lineno)
#define StashPrefix { scparser_PrefixCat (yytext, yyleng); }

extern void sclex_ppline (const char *line);

char *   str_bufp = NULL;
unsigned str_buf_size = 0;
const char *   sclex_include_from = NULL;

static void yyerror(const char* msg)
{
    scgrammererror (msg);
}
/**********************************************************************/
%}

%x AUTOMODE
%x CMTMODE
%x STRMODE

WHITESPACE	[ \t\r\f]
NEWLINE		[\n]
QUOTE		['"]
SYMBOL		[a-zA-Z_][a-zA-Z0-9_$]*
Z9		[0-9]*
DECNUM		[0-9]+U?L?L?
BASENUM		0x[0-9a-fA-F_]+U?L?L?
FLOATNUM	[0-9]+"."*[0-9]*[eE]-?[0-9]+

	/**************************************************************/
%%

"#line".*\n	{ scparser_EmitPrefix(); sclex_ppline(yytext); }
"#"{WHITESPACE}*"include"	{ return(PP); }
"#"{WHITESPACE}*"sp".*\n	{ LINENO++; return(SP); }

	/* Special macros we recognize */
"VL_MODULE"	{ return(SC_MODULE); }
"SC_MODULE"	{ return(SC_MODULE); }
"SP_MODULE_CONTINUED"	{ return(SP_MODULE_CONTINUED); }
"SP_CLASS"		{ return(SC_MODULE); }
[S][PC]"_CELL"		{ return(SP_CELL); }
[S][PC]"_CELL_FORM"	{ return(SP_CELL); }
[S][PC]"_CELL_DECL"	{ return(SP_CELL_DECL); }
[S][PC]"_PIN"		{ return(SP_PIN); }
[S][PC]"_TRACED"	{ return(SP_TRACED); }
[S][PC]"_COVERGROUP"	{ return(SP_COVERGROUP); }
[S][PC]"_COVER_SAMPLE"	{ return(SP_COVER_SAMPLE); }
"SP_TEMPLATE"	{ return(SP_TEMPLATE); }
"SC_CTOR"	{ return(SC_CTOR); }
"VL_CTOR"	{ return(SC_CTOR); }
"VL_CELL"	{ return(SP_CELL); }
"VL_SIG"{Z9}	{ return(VL_SIG); }
"VL_SIGW"	{ return(VL_SIGW); }
"VL_INOUT"{Z9}	{ return(VL_INOUT); }
"VL_INOUTW"	{ return(VL_INOUTW); }
"VL_IN"{Z9}	{ return(VL_IN); }
"VL_INW"	{ return(VL_INW); }
"VL_OUT"{Z9}	{ return(VL_OUT); }
"VL_OUTW"	{ return(VL_OUTW); }
"VL_PIN_NOP"	{ return(SP_PIN); }

"coverpoint"	{ return(COVERPOINT); }
"default"	{ return(CG_DEFAULT); }
"description"   { return(CG_DESCRIPTION); }
"page"		{ return(CG_PAGE); }
"option" 	{ return(CG_OPTION); }
"bins"          { return(CG_BINS); }
"illegal_bins"  { return(CG_ILLEGAL_BINS); }
"illegal_bins_func" { return(CG_ILLEGAL_BINS_FUNC); }
"ignore_bins"   { return(CG_IGNORE_BINS); }
"ignore_bins_func" { return(CG_IGNORE_BINS_FUNC); }
"limit_func"    { return(CG_LIMIT_FUNC); }
"auto_enum_bins" { return(CG_AUTO_ENUM_BINS); }
"cross"         { return(CG_CROSS); }
"rows"          { return(CG_ROWS); }
"cols"          { return(CG_COLS); }
"table"         { return(CG_TABLE); }
"window"        { return(CG_WINDOW); }

"class"		{ return(CLASS); }
"const"		{ return(CONST); }
"enum"		{ return(ENUM); }
"private"	{ return(PRIVATE); }
"protected"	{ return(PROTECTED); }
"public"	{ return(PUBLIC); }
"sc_main"	{ return(SC_MAIN); }
"sp_ui"		{ return(SP_UI); }
"struct"	{ return(CLASS); }
"virtual"	{ return(VIRTUAL); }

"::"		{ return(COLONCOLON); }

"ncsc_foreign_module"		{ return(NCSC_MODULE); }

"sc_signal"	|
"sc_in"		|
"sc_out"	|
"sc_inout"	{ yylval.string = strdup(yytext); return(SC_SIGNAL); }

"sc_in_clk"	|
"sc_out_clk"	|
"sc_inout_clk"	{ yylval.string = strdup(yytext); return(SC_INOUT_CLK); }

"sc_clock"	{ yylval.string = strdup(yytext); return(SC_CLOCK); }

	/* Automatic comments */
{WHITESPACE}*"// Beginning of SystemPerl automatic".*\n	{
	if (scParserLex.stripAutos) {BEGIN(AUTOMODE); scparser_EmitPrefix();}
	else { StashPrefix; }
	LINENO++;}
{WHITESPACE}*"/*AUTO"[^*\n]+"*/"	{ return(AUTO); }
{WHITESPACE}*"SP_AUTO_"[^;\n]+";"	{ return(AUTO); }
<INITIAL><<EOF>>	{
#ifdef FLEX_DEBUG
    fprintf(stderr,"EOF %s\n",scParserLex.filename);
#endif
    if (--sclex_include_stack_ptr<0) {
	yyleng=0; yyterminate(); /* Else NUL added to EOF*/
    } else {
	YY_BUFFER_STATE oldbuffer = YY_CURRENT_BUFFER;
	yy_switch_to_buffer (sclex_includes[sclex_include_stack_ptr].buffer);
	yy_delete_buffer (oldbuffer);
	scparse_set_filename (sclex_includes[sclex_include_stack_ptr].filename,
			      sclex_includes[sclex_include_stack_ptr].lineno);
    }
}

	/* Generics */
{NEWLINE}      	{ StashPrefix; LINENO++; }
{WHITESPACE}+	{ StashPrefix; }
"//".*[\n]     	{ StashPrefix; LINENO++; }
	/* This handles strings AND character constants. */
{QUOTE}		{ StashPrefix;
		  /* Room for trailing '\"' or '\'', and '\0' */
		  str_buf_size = yyleng + 2;
		  str_bufp = (char*)malloc(str_buf_size);
		  strcpy(str_bufp, yytext);
		  BEGIN(STRMODE); }

"/*"	       	{ BEGIN(CMTMODE); StashPrefix; }

{SYMBOL}      		{ yylval.string = strdup(yytext); return(SYMBOL); }
{DECNUM}|{BASENUM}|{FLOATNUM}  	{ yylval.string = strdup(yytext); return(NUMBER); }
.	       		{ return(yytext[yyleng-1]); }

	/************/
	/* Comment */
<CMTMODE>"*"+[^*/\n]* 	{ StashPrefix; }
<CMTMODE>\n		{ StashPrefix; LINENO++; }
<CMTMODE>"*"+"/"	{ StashPrefix; BEGIN(INITIAL); }
<CMTMODE>. 		{ StashPrefix; }
<CMTMODE><<EOF>>	{ yyerror("EOF in '/* ... */' block comment");
			  yyleng = 0; yyterminate(); }

	/************/
	/* Strings */
<STRMODE>\n		{ StashPrefix; LINENO++;
			  yyerror((str_bufp[0] == '\'')
				  ? "Unterminated character-constant"
				  : "Unterminated string");
			  BEGIN(INITIAL); }
<STRMODE><<EOF>>	{ yyerror("EOF in string or character-constant");
			  yyleng = 0; yyterminate(); }
<STRMODE>\\[0-7][0-7]?[0-7]? |
<STRMODE>\\x[0-9A-Fa-f][0-9A-Fa-f]+ |
<STRMODE>\\(.|\n)	|
<STRMODE>[^\n\'\"\\]+	{ StashPrefix;
			  if (strcmp(yytext, "\\\n")==0) LINENO++;
			  str_buf_size += yyleng;
			  str_bufp = realloc(str_bufp, str_buf_size + 1);
			  strcat(str_bufp, yytext); }
<STRMODE>{QUOTE}	{ StashPrefix;
			  if (yytext[0] != str_bufp[0]) {
			    str_buf_size += yyleng;
			    str_bufp = realloc(str_bufp, str_buf_size + 1);
			    strcat(str_bufp, yytext);
			  } else {
			    BEGIN(INITIAL);
			    assert(strlen(str_bufp) + yyleng < str_buf_size);
			    strcat(str_bufp, yytext);
			    yylval.string = str_bufp;
			    str_bufp = NULL;
			    str_buf_size = 0;
			    yyleng = 0;
			    return STRING;
			  }
			}

	/************/
	/* In Automatic */
<AUTOMODE>\n		{ LINENO++; yymore(); }
<AUTOMODE>"// End of SystemPerl automatic".*\n	{ LINENO++; BEGIN(INITIAL); }
<AUTOMODE>.	 	{ yymore(); }
<AUTOMODE><<EOF>>	{ yyerror("EOF before '// End of SystemPerl automatic'");
			  yyleng = 0; yyterminate(); }

	/**************************************************************/
%%

#ifndef yy_new_buffer	// Flex 2.5.31 Experimental release is broken...
# define yy_new_buffer sclex_create_buffer
#endif

void sclex_ppline (const char* line) {
    /* Passed string which looks like #line {##} "{filename}" */
    if (0==strncmp ("#line",line,5)) { line += 5; }
    while (*line && isspace((int)*line)) line++;

    if (isdigit ((int)*line)) {
	scParserLex.lineno = atoi(line);
	while (*line && isdigit((int)*line)) line++;
	while (*line && isspace((int)*line)) line++;
	if (*line == '"') {
	    char *cp;
	    line++;
	    free((void*)scParserLex.filename);
	    scParserLex.filename = strdup(line);
	    if (NULL!=(cp=strchr(scParserLex.filename, '"'))) *cp = '\0';
	}
    }
}

int sclex_open  (const char* filename)
{
    FILE* newin;
    newin = fopen (filename, "r");
    if (!newin) {
	/* Presume user does -r before calling us */
	return 0;
    }
    scparse_set_filename(filename,1);
    yy_switch_to_buffer( yy_new_buffer( newin, YY_BUF_SIZE ) );
    if (0) {
	char c='x';
	unput(c);  /* Prevent unused function warning on Suse 9.1 */
    }
    return 1;
}

void sclex_include (const char* filename) {
    if (sclex_include_stack_ptr >= SCLEX_MAX_INCLUDE_DEPTH ) {
	yyerror("Includes nested too deeply");
	return;
    }

    if (sclex_include_from) {
	yyerror("Two includes specified before parser restarted");
	return;
    }
    sclex_include_from = strdup(filename);
}

void sclex_include_switch () {
    FILE* newin;
    if (sclex_include_from) {
	const char* filename = sclex_include_from;
	sclex_include_from = NULL;

	sclex_includes[sclex_include_stack_ptr].buffer = YY_CURRENT_BUFFER;
	sclex_includes[sclex_include_stack_ptr].lineno = scParserLex.lineno;
	sclex_includes[sclex_include_stack_ptr].filename = scParserLex.filename;

	newin = fopen (filename, "r");
	if (!newin) {
	    yyerror("Cannot open include file");
	    return;
	}

	sclex_include_stack_ptr++;
	scparse_set_filename (filename, 1);
	yy_switch_to_buffer( yy_new_buffer( newin, YY_BUF_SIZE ) );
    }
}

/*###################################################################
 * Local Variables:
 * mode: C
 * End:
 */
