/******************************************************************************
 * DESCRIPTION: SystemC parser header file
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

#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>

/* Can't include perl... It's lexer will conflict */

/* Utilities */
#define DENULL(s) ((s)?(s):"NULL")

/* Common state between lex/yacc/scparser */
/* State only scparser needs is in ScParserState */
typedef struct {
    int lineno;
    const char *filename;
    int stripAutos;
    char *enumname;
} ScParserLex_t ;
extern ScParserLex_t scParserLex;

/* Lexer */
extern FILE *sclexin;
extern int sclexlex();
extern char *sclextext;
#ifdef SCPARSE_C
ScParserLex_t scParserLex;
#endif
extern int sclex_open  (const char* filename);
extern void sclex_include (const char* filename);
extern void sclex_include_switch (void);

/* Yacc */
extern void scgrammererror(const char *s);
extern int scgrammerlex(void);
extern int scgrammerparse(void);

/* Parser.xs */
extern int scparse (const char *filename);
extern void scparser_PrefixCat (char *text, int len);
extern void scparser_EmitPrefix (void);
extern void scparser_call (int params, const char *method, ...);
extern void scparser_symbol (const char *symbol);
extern void scparse_set_filename (const char *filename, int lineno);
