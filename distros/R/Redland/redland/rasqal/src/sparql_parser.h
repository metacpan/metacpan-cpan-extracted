/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton interface for Bison's Yacc-like parsers in C

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     SELECT = 258,
     FROM = 259,
     WHERE = 260,
     OPTIONAL = 261,
     DESCRIBE = 262,
     CONSTRUCT = 263,
     ASK = 264,
     DISTINCT = 265,
     LIMIT = 266,
     UNION = 267,
     PREFIX = 268,
     BASE = 269,
     BOUND = 270,
     GRAPH = 271,
     NAMED = 272,
     FILTER = 273,
     OFFSET = 274,
     ORDER = 275,
     BY = 276,
     REGEX = 277,
     ASC = 278,
     DESC = 279,
     LANGMATCHES = 280,
     A = 281,
     STR = 282,
     LANG = 283,
     DATATYPE = 284,
     ISURI = 285,
     ISBLANK = 286,
     ISLITERAL = 287,
     SC_OR = 289,
     SC_AND = 291,
     EQ = 293,
     NEQ = 295,
     LT = 297,
     GT = 299,
     LE = 301,
     GE = 303,
     FLOATING_POINT_LITERAL = 304,
     STRING_LITERAL = 305,
     INTEGER_LITERAL = 306,
     BOOLEAN_LITERAL = 307,
     DECIMAL_LITERAL = 308,
     URI_LITERAL = 309,
     URI_LITERAL_BRACE = 310,
     QNAME_LITERAL = 311,
     QNAME_LITERAL_BRACE = 312,
     BLANK_LITERAL = 313,
     IDENTIFIER = 314
   };
#endif
/* Tokens.  */
#define SELECT 258
#define FROM 259
#define WHERE 260
#define OPTIONAL 261
#define DESCRIBE 262
#define CONSTRUCT 263
#define ASK 264
#define DISTINCT 265
#define LIMIT 266
#define UNION 267
#define PREFIX 268
#define BASE 269
#define BOUND 270
#define GRAPH 271
#define NAMED 272
#define FILTER 273
#define OFFSET 274
#define ORDER 275
#define BY 276
#define REGEX 277
#define ASC 278
#define DESC 279
#define LANGMATCHES 280
#define A 281
#define STR 282
#define LANG 283
#define DATATYPE 284
#define ISURI 285
#define ISBLANK 286
#define ISLITERAL 287
#define SC_OR 289
#define SC_AND 291
#define EQ 293
#define NEQ 295
#define LT 297
#define GT 299
#define LE 301
#define GE 303
#define FLOATING_POINT_LITERAL 304
#define STRING_LITERAL 305
#define INTEGER_LITERAL 306
#define BOOLEAN_LITERAL 307
#define DECIMAL_LITERAL 308
#define URI_LITERAL 309
#define URI_LITERAL_BRACE 310
#define QNAME_LITERAL 311
#define QNAME_LITERAL_BRACE 312
#define BLANK_LITERAL 313
#define IDENTIFIER 314




#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
#line 110 "./sparql_parser.y"
{
  raptor_sequence *seq;
  rasqal_variable *variable;
  rasqal_literal *literal;
  rasqal_triple *triple;
  rasqal_expression *expr;
  rasqal_graph_pattern *graph_pattern;
  double floating;
  raptor_uri *uri;
  unsigned char *name;
  rasqal_formula *formula;
}
/* Line 1529 of yacc.c.  */
#line 164 "sparql_parser.tab.h"
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif



