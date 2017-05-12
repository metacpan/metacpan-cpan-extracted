/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton implementation for Bison's Yacc-like parsers in C

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

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output.  */
#define YYBISON 1

/* Bison version.  */
#define YYBISON_VERSION "2.3"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 1

/* Using locations.  */
#define YYLSP_NEEDED 0

/* Substitute the variable and function names.  */
#define yyparse sparql_parser_parse
#define yylex   sparql_parser_lex
#define yyerror sparql_parser_error
#define yylval  sparql_parser_lval
#define yychar  sparql_parser_char
#define yydebug sparql_parser_debug
#define yynerrs sparql_parser_nerrs


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




/* Copy the first part of user declarations.  */
#line 32 "./sparql_parser.y"

#ifdef HAVE_CONFIG_H
#include <rasqal_config.h>
#endif

#ifdef WIN32
#include <win32_rasqal_config.h>
#endif

#include <stdio.h>
#include <stdarg.h>

#include <rasqal.h>
#include <rasqal_internal.h>

#include <sparql_parser.h>

#define YY_DECL int sparql_lexer_lex (YYSTYPE *sparql_parser_lval, yyscan_t yyscanner)
#define YY_NO_UNISTD_H 1
#include <sparql_lexer.h>

#include <sparql_common.h>

/*
#undef RASQAL_DEBUG
#define RASQAL_DEBUG 2
*/

#define DEBUG_FH stdout

/* Make verbose error messages for syntax errors */
#define YYERROR_VERBOSE 1

/* Slow down the grammar operation and watch it work */
#if RASQAL_DEBUG > 2
#define YYDEBUG 1
#endif

/* the lexer does not seem to track this */
#undef RASQAL_SPARQL_USE_ERROR_COLUMNS

/* Missing sparql_lexer.c/h prototypes */
int sparql_lexer_get_column(yyscan_t yyscanner);
/* Not used here */
/* void sparql_lexer_set_column(int  column_no , yyscan_t yyscanner);*/


/* What the lexer wants */
extern int sparql_lexer_lex (YYSTYPE *sparql_parser_lval, yyscan_t scanner);
#define YYLEX_PARAM ((rasqal_sparql_query_engine*)(((rasqal_query*)rq)->context))->scanner

/* Pure parser argument (a void*) */
#define YYPARSE_PARAM rq

/* Make the yyerror below use the rdf_parser */
#undef yyerror
#define yyerror(message) sparql_query_error((rasqal_query*)rq, message)

/* Make lex/yacc interface as small as possible */
#undef yylex
#define yylex sparql_lexer_lex


static int sparql_parse(rasqal_query* rq, const unsigned char *string);
static void sparql_query_error(rasqal_query* rq, const char *message);
static void sparql_query_error_full(rasqal_query *rq, const char *message, ...) RASQAL_PRINTF_FORMAT(2, 3);
static int sparql_is_builtin_xsd_datatype(raptor_uri* uri);



/* Enabling traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif

/* Enabling verbose error messages.  */
#ifdef YYERROR_VERBOSE
# undef YYERROR_VERBOSE
# define YYERROR_VERBOSE 1
#else
# define YYERROR_VERBOSE 0
#endif

/* Enabling the token table.  */
#ifndef YYTOKEN_TABLE
# define YYTOKEN_TABLE 0
#endif

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
/* Line 193 of yacc.c.  */
#line 289 "sparql_parser.c"
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif



/* Copy the second part of user declarations.  */


/* Line 216 of yacc.c.  */
#line 302 "sparql_parser.c"

#ifdef short
# undef short
#endif

#ifdef YYTYPE_UINT8
typedef YYTYPE_UINT8 yytype_uint8;
#else
typedef unsigned char yytype_uint8;
#endif

#ifdef YYTYPE_INT8
typedef YYTYPE_INT8 yytype_int8;
#elif (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
typedef signed char yytype_int8;
#else
typedef short int yytype_int8;
#endif

#ifdef YYTYPE_UINT16
typedef YYTYPE_UINT16 yytype_uint16;
#else
typedef unsigned short int yytype_uint16;
#endif

#ifdef YYTYPE_INT16
typedef YYTYPE_INT16 yytype_int16;
#else
typedef short int yytype_int16;
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif ! defined YYSIZE_T && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned int
# endif
#endif

#define YYSIZE_MAXIMUM ((YYSIZE_T) -1)

#ifndef YY_
# if YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(msgid) dgettext ("bison-runtime", msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(msgid) msgid
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YYUSE(e) ((void) (e))
#else
# define YYUSE(e) /* empty */
#endif

/* Identity function, used to suppress warnings about constant conditions.  */
#ifndef lint
# define YYID(n) (n)
#else
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static int
YYID (int i)
#else
static int
YYID (i)
    int i;
#endif
{
  return i;
}
#endif

#if ! defined yyoverflow || YYERROR_VERBOSE

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#     ifndef _STDLIB_H
#      define _STDLIB_H 1
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's `empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (YYID (0))
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined _STDLIB_H \
       && ! ((defined YYMALLOC || defined malloc) \
	     && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef _STDLIB_H
#    define _STDLIB_H 1
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
#   endif
#  endif
# endif
#endif /* ! defined yyoverflow || YYERROR_VERBOSE */


#if (! defined yyoverflow \
     && (! defined __cplusplus \
	 || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yytype_int16 yyss;
  YYSTYPE yyvs;
  };

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (sizeof (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (sizeof (yytype_int16) + sizeof (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

/* Copy COUNT objects from FROM to TO.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(To, From, Count) \
      __builtin_memcpy (To, From, (Count) * sizeof (*(From)))
#  else
#   define YYCOPY(To, From, Count)		\
      do					\
	{					\
	  YYSIZE_T yyi;				\
	  for (yyi = 0; yyi < (Count); yyi++)	\
	    (To)[yyi] = (From)[yyi];		\
	}					\
      while (YYID (0))
#  endif
# endif

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack)					\
    do									\
      {									\
	YYSIZE_T yynewbytes;						\
	YYCOPY (&yyptr->Stack, Stack, yysize);				\
	Stack = &yyptr->Stack;						\
	yynewbytes = yystacksize * sizeof (*Stack) + YYSTACK_GAP_MAXIMUM; \
	yyptr += yynewbytes / sizeof (*yyptr);				\
      }									\
    while (YYID (0))

#endif

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  6
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   424

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  76
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  68
/* YYNRULES -- Number of rules.  */
#define YYNRULES  161
/* YYNRULES -- Number of states.  */
#define YYNSTATES  257

/* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   314

#define YYTRANSLATE(YYX)						\
  ((unsigned int) (YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

/* YYTRANSLATE[YYLEX] -- Bison symbol number corresponding to YYLEX.  */
static const yytype_uint8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,    75,     2,     2,    41,     2,     2,     2,
      34,    35,    60,    58,    33,    59,    73,    61,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,    74,
       2,     2,     2,    40,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,    36,     2,    37,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,    38,     2,    39,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    42,    43,
      44,    45,    46,    47,    48,    49,    50,    51,    52,    53,
      54,    55,    56,    57,    62,    63,    64,    65,    66,    67,
      68,    69,    70,    71,    72
};

#if YYDEBUG
/* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
   YYRHS.  */
static const yytype_uint16 yyprhs[] =
{
       0,     0,     3,    11,    13,    15,    17,    19,    22,    25,
      26,    31,    32,    36,    40,    43,    46,    49,    53,    55,
      58,    61,    64,    68,    70,    73,    76,    78,    82,    86,
      87,    89,    92,    95,    97,    98,   102,   103,   106,   108,
     111,   114,   116,   118,   120,   123,   124,   127,   128,   132,
     134,   135,   140,   142,   147,   149,   152,   153,   156,   159,
     160,   162,   164,   166,   169,   173,   177,   179,   183,   185,
     188,   191,   194,   198,   202,   204,   205,   209,   213,   215,
     216,   219,   222,   224,   225,   229,   232,   233,   236,   239,
     240,   242,   244,   246,   248,   252,   256,   259,   261,   263,
     265,   267,   269,   271,   273,   275,   277,   279,   282,   285,
     287,   289,   291,   293,   295,   297,   299,   302,   304,   308,
     310,   314,   316,   320,   324,   328,   332,   336,   340,   342,
     346,   350,   352,   356,   360,   362,   365,   368,   371,   373,
     375,   377,   379,   381,   383,   387,   392,   397,   404,   409,
     414,   419,   424,   429,   431,   438,   447,   449,   451,   453,
     455,   457
};

/* YYRHS -- A `-1'-separated list of the rules' RHS.  */
static const yytype_int16 yyrhs[] =
{
      77,     0,    -1,    79,    78,    88,    91,    92,    95,    96,
      -1,    82,    -1,    86,    -1,    84,    -1,    87,    -1,    80,
      81,    -1,    14,    67,    -1,    -1,    81,    13,    72,    67,
      -1,    -1,     3,    10,    83,    -1,     3,    10,    60,    -1,
       3,    83,    -1,     3,    60,    -1,    83,   128,    -1,    83,
      33,   128,    -1,   128,    -1,     7,    85,    -1,     7,    60,
      -1,    85,   126,    -1,    85,    33,   126,    -1,   126,    -1,
       8,   111,    -1,     8,    60,    -1,     9,    -1,    88,     4,
      89,    -1,    88,     4,    90,    -1,    -1,   142,    -1,    17,
     142,    -1,     5,    97,    -1,    97,    -1,    -1,    20,    21,
      93,    -1,    -1,    93,    94,    -1,    94,    -1,    23,   138,
      -1,    24,   138,    -1,   109,    -1,   128,    -1,   138,    -1,
      11,    64,    -1,    -1,    19,    64,    -1,    -1,    38,    99,
      39,    -1,    73,    -1,    -1,   100,   103,    98,    99,    -1,
     100,    -1,   101,   108,    98,   100,    -1,   101,    -1,   113,
     102,    -1,    -1,   102,   113,    -1,   102,    73,    -1,    -1,
     104,    -1,   106,    -1,   105,    -1,     6,    97,    -1,    16,
     127,    97,    -1,    97,    12,   107,    -1,    97,    -1,   107,
      12,    97,    -1,    97,    -1,    18,   138,    -1,    18,   139,
      -1,    18,   109,    -1,   141,   110,    35,    -1,   110,    33,
     130,    -1,   130,    -1,    -1,    38,   112,    39,    -1,   113,
      73,   112,    -1,   113,    -1,    -1,   125,   115,    -1,   120,
     114,    -1,   115,    -1,    -1,   119,   117,   116,    -1,    74,
     114,    -1,    -1,   124,   118,    -1,    33,   117,    -1,    -1,
     127,    -1,    26,    -1,   122,    -1,   121,    -1,    36,   115,
      37,    -1,    34,   123,    35,    -1,   123,   124,    -1,   124,
      -1,   125,    -1,   120,    -1,   128,    -1,   129,    -1,   128,
      -1,   142,    -1,   128,    -1,   143,    -1,   142,    -1,    40,
      72,    -1,    41,    72,    -1,   142,    -1,    64,    -1,    62,
      -1,    66,    -1,    63,    -1,    65,    -1,   143,    -1,    34,
      35,    -1,   131,    -1,   131,    43,   132,    -1,   132,    -1,
     132,    45,   133,    -1,   133,    -1,   134,    47,   134,    -1,
     134,    49,   134,    -1,   134,    51,   134,    -1,   134,    53,
     134,    -1,   134,    55,   134,    -1,   134,    57,   134,    -1,
     134,    -1,   135,    58,   134,    -1,   135,    59,   134,    -1,
     135,    -1,   136,    60,   135,    -1,   136,    61,   135,    -1,
     136,    -1,    75,   137,    -1,    58,   137,    -1,    59,   137,
      -1,   137,    -1,   138,    -1,   139,    -1,   109,    -1,   129,
      -1,   128,    -1,    34,   130,    35,    -1,    27,    34,   130,
      35,    -1,    28,    34,   130,    35,    -1,    25,    34,   130,
      33,   130,    35,    -1,    29,    34,   130,    35,    -1,    15,
      34,   128,    35,    -1,    30,    34,   130,    35,    -1,    31,
      34,   130,    35,    -1,    32,    34,   130,    35,    -1,   140,
      -1,    22,    34,   130,    33,   130,    35,    -1,    22,    34,
     130,    33,   130,    33,   130,    35,    -1,    68,    -1,    70,
      -1,    67,    -1,    69,    -1,    71,    -1,    36,    37,    -1
};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const yytype_uint16 yyrline[] =
{
       0,   224,   224,   233,   238,   243,   248,   256,   264,   271,
     278,   299,   306,   311,   317,   321,   330,   335,   340,   350,
     354,   362,   367,   372,   381,   385,   394,   401,   402,   403,
     408,   420,   435,   439,   444,   451,   459,   464,   470,   480,
     484,   488,   493,   500,   509,   521,   526,   537,   542,   549,
     550,   555,   592,   624,   668,   707,   733,   743,   768,   773,
     780,   784,   788,   796,   816,   841,   852,   859,   865,   879,
     883,   887,   895,   917,   923,   930,   937,   945,   964,   976,
     983,  1023,  1067,  1072,  1079,  1149,  1154,  1161,  1204,  1209,
    1216,  1221,  1237,  1241,  1249,  1300,  1364,  1394,  1421,  1425,
    1433,  1438,  1446,  1450,  1458,  1462,  1466,  1473,  1477,  1486,
    1490,  1494,  1498,  1502,  1506,  1510,  1514,  1521,  1529,  1533,
    1541,  1546,  1555,  1559,  1563,  1567,  1571,  1575,  1579,  1588,
    1592,  1596,  1603,  1607,  1611,  1619,  1623,  1627,  1631,  1645,
    1649,  1653,  1662,  1666,  1675,  1683,  1687,  1691,  1695,  1699,
    1705,  1709,  1713,  1717,  1725,  1729,  1740,  1744,  1766,  1770,
    1786,  1789
};
#endif

#if YYDEBUG || YYERROR_VERBOSE || YYTOKEN_TABLE
/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "$end", "error", "$undefined", "SELECT", "FROM", "WHERE", "OPTIONAL",
  "DESCRIBE", "CONSTRUCT", "ASK", "DISTINCT", "LIMIT", "UNION", "PREFIX",
  "BASE", "BOUND", "GRAPH", "NAMED", "FILTER", "OFFSET", "ORDER", "BY",
  "REGEX", "ASC", "DESC", "LANGMATCHES", "\"a\"", "\"str\"", "\"lang\"",
  "\"datatype\"", "\"isUri\"", "\"isBlank\"", "\"isLiteral\"", "','",
  "'('", "')'", "'['", "']'", "'{'", "'}'", "'?'", "'$'", "\"||\"",
  "SC_OR", "\"&&\"", "SC_AND", "\"=\"", "EQ", "\"!=\"", "NEQ", "\"<\"",
  "LT", "\">\"", "GT", "\"<=\"", "LE", "\">=\"", "GE", "'+'", "'-'", "'*'",
  "'/'", "\"floating point literal\"", "\"string literal\"",
  "\"integer literal\"", "\"boolean literal\"", "\"decimal literal\"",
  "\"URI literal\"", "\"URI literal (\"", "\"QName literal\"",
  "\"QName literal (\"", "\"blank node literal\"", "\"identifier\"", "'.'",
  "';'", "'!'", "$accept", "Query", "ReportFormat", "Prolog",
  "BaseDeclOpt", "PrefixDeclOpt", "SelectQuery", "VarList",
  "DescribeQuery", "VarOrIRIrefList", "ConstructQuery", "AskQuery",
  "DatasetClauseOpt", "DefaultGraphClause", "NamedGraphClause",
  "WhereClauseOpt", "OrderClauseOpt", "OrderConditionList",
  "OrderCondition", "LimitClauseOpt", "OffsetClauseOpt",
  "GroupGraphPattern", "DotOptional", "GraphPattern",
  "FilteredBasicGraphPattern", "BlockOfTriplesOpt",
  "TriplesSameSubjectDotListOpt", "GraphPatternNotTriples",
  "OptionalGraphPattern", "GraphGraphPattern", "GroupOrUnionGraphPattern",
  "GroupOrUnionGraphPatternList", "Constraint", "FunctionCall", "ArgList",
  "ConstructTemplate", "ConstructTriplesOpt", "TriplesSameSubject",
  "PropertyList", "PropertyListNotEmpty", "PropertyListTailOpt",
  "ObjectList", "ObjectTail", "Verb", "TriplesNode",
  "BlankNodePropertyList", "Collection", "GraphNodeListNotEmpty",
  "GraphNode", "VarOrTerm", "VarOrIRIref", "VarOrBlankNodeOrIRIref", "Var",
  "GraphTerm", "Expression", "ConditionalOrExpression",
  "ConditionalAndExpression", "RelationalExpression", "AdditiveExpression",
  "MultiplicativeExpression", "UnaryExpression", "PrimaryExpression",
  "BrackettedExpression", "BuiltInCall", "RegexExpression", "IRIrefBrace",
  "IRIref", "BlankNode", 0
};
#endif

# ifdef YYPRINT
/* YYTOKNUM[YYLEX-NUM] -- Internal token number corresponding to
   token YYLEX-NUM.  */
static const yytype_uint16 yytoknum[] =
{
       0,   256,   257,   258,   259,   260,   261,   262,   263,   264,
     265,   266,   267,   268,   269,   270,   271,   272,   273,   274,
     275,   276,   277,   278,   279,   280,   281,   282,   283,   284,
     285,   286,   287,    44,    40,    41,    91,    93,   123,   125,
      63,    36,   288,   289,   290,   291,   292,   293,   294,   295,
     296,   297,   298,   299,   300,   301,   302,   303,    43,    45,
      42,    47,   304,   305,   306,   307,   308,   309,   310,   311,
     312,   313,   314,    46,    59,    33
};
# endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_uint8 yyr1[] =
{
       0,    76,    77,    78,    78,    78,    78,    79,    80,    80,
      81,    81,    82,    82,    82,    82,    83,    83,    83,    84,
      84,    85,    85,    85,    86,    86,    87,    88,    88,    88,
      89,    90,    91,    91,    91,    92,    92,    93,    93,    94,
      94,    94,    94,    94,    95,    95,    96,    96,    97,    98,
      98,    99,    99,   100,   100,   101,   101,   102,   102,   102,
     103,   103,   103,   104,   105,   106,   106,   107,   107,   108,
     108,   108,   109,   110,   110,   110,   111,   112,   112,   112,
     113,   113,   114,   114,   115,   116,   116,   117,   118,   118,
     119,   119,   120,   120,   121,   122,   123,   123,   124,   124,
     125,   125,   126,   126,   127,   127,   127,   128,   128,   129,
     129,   129,   129,   129,   129,   129,   129,   130,   131,   131,
     132,   132,   133,   133,   133,   133,   133,   133,   133,   134,
     134,   134,   135,   135,   135,   136,   136,   136,   136,   137,
     137,   137,   137,   137,   138,   139,   139,   139,   139,   139,
     139,   139,   139,   139,   140,   140,   141,   141,   142,   142,
     143,   143
};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
static const yytype_uint8 yyr2[] =
{
       0,     2,     7,     1,     1,     1,     1,     2,     2,     0,
       4,     0,     3,     3,     2,     2,     2,     3,     1,     2,
       2,     2,     3,     1,     2,     2,     1,     3,     3,     0,
       1,     2,     2,     1,     0,     3,     0,     2,     1,     2,
       2,     1,     1,     1,     2,     0,     2,     0,     3,     1,
       0,     4,     1,     4,     1,     2,     0,     2,     2,     0,
       1,     1,     1,     2,     3,     3,     1,     3,     1,     2,
       2,     2,     3,     3,     1,     0,     3,     3,     1,     0,
       2,     2,     1,     0,     3,     2,     0,     2,     2,     0,
       1,     1,     1,     1,     3,     3,     2,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     2,     2,     1,
       1,     1,     1,     1,     1,     1,     2,     1,     3,     1,
       3,     1,     3,     3,     3,     3,     3,     3,     1,     3,
       3,     1,     3,     3,     1,     2,     2,     2,     1,     1,
       1,     1,     1,     1,     3,     4,     4,     6,     4,     4,
       4,     4,     4,     1,     6,     8,     1,     1,     1,     1,
       1,     2
};

/* YYDEFACT[STATE-NAME] -- Default rule to reduce with in state
   STATE-NUM when YYTABLE doesn't specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
       9,     0,     0,     0,    11,     8,     1,     0,     0,     0,
      26,    29,     3,     5,     4,     6,     7,     0,     0,     0,
      15,    14,    18,    20,   158,   159,    19,    23,   102,   103,
      79,    25,    24,    34,     0,    13,    12,   107,   108,     0,
      16,     0,    21,     0,     0,   111,   113,   110,   114,   112,
     160,     0,    78,    83,    93,    92,     0,   100,   101,   109,
     115,     0,     0,    56,    36,    33,     0,    17,    22,   116,
      99,     0,    97,    98,    91,     0,   161,     0,     0,    90,
     104,   106,   105,    76,    79,    81,    82,    80,     0,    27,
      28,    30,    32,     0,    52,    54,    59,     0,    45,    10,
      95,    96,    94,    86,    89,    77,    31,    48,     0,     0,
      66,    50,    60,    62,    61,     0,    50,    55,     0,     0,
      47,    83,    84,     0,    87,    63,     0,     0,    49,    56,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     156,   157,    71,    69,    70,   153,    75,    56,    58,    57,
       0,     0,    35,    38,    41,    42,    43,    44,     0,     2,
      85,    88,    64,    68,    65,    51,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,   141,
     143,   142,     0,   117,   119,   121,   128,   131,   134,   138,
     139,   140,     0,    74,    53,    39,    40,    37,    46,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,   136,
     137,   135,   144,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    72,    67,   149,     0,
       0,   145,   146,   148,   150,   151,   152,   118,   120,   122,
     123,   124,   125,   126,   127,   129,   130,   132,   133,    73,
       0,     0,     0,   154,   147,     0,   155
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
      -1,     2,    11,     3,     4,    16,    12,    21,    13,    26,
      14,    15,    33,    89,    90,    64,    98,   152,   153,   120,
     159,    65,   129,    93,    94,    95,   117,   111,   112,   113,
     114,   164,   116,   179,   192,    32,    51,    96,    85,    86,
     122,   103,   124,    78,    53,    54,    55,    71,   104,    56,
      27,    79,   180,   181,   182,   183,   184,   185,   186,   187,
     188,   189,   190,   191,   145,   146,    59,    60
};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -107
static const yytype_int16 yypact[] =
{
       7,   -59,    68,   121,  -107,  -107,  -107,    10,   101,   -32,
    -107,  -107,  -107,  -107,  -107,  -107,    62,    26,    37,    51,
    -107,    79,  -107,  -107,  -107,  -107,    67,  -107,  -107,  -107,
     335,  -107,  -107,    38,    59,  -107,    79,  -107,  -107,    13,
    -107,   261,  -107,   315,   157,  -107,  -107,  -107,  -107,  -107,
    -107,    76,    48,   291,  -107,  -107,   291,  -107,  -107,  -107,
    -107,    -6,    99,   335,   119,  -107,    77,  -107,  -107,  -107,
    -107,   353,  -107,  -107,  -107,   106,  -107,   110,   335,  -107,
    -107,  -107,  -107,  -107,   335,  -107,  -107,  -107,   -51,  -107,
    -107,  -107,  -107,   118,    63,   140,  -107,   139,   155,  -107,
    -107,  -107,  -107,    93,   138,  -107,  -107,  -107,    99,   133,
     164,   114,  -107,  -107,  -107,   284,   114,   301,    65,   124,
     170,   291,  -107,   335,  -107,  -107,    99,    99,  -107,   335,
     158,   161,   162,   165,   167,   169,   171,   173,   189,   207,
    -107,  -107,  -107,  -107,  -107,  -107,   207,   335,  -107,  -107,
     193,   193,    65,  -107,  -107,  -107,  -107,  -107,   166,  -107,
    -107,  -107,  -107,  -107,   219,  -107,    13,   207,   207,   207,
     207,   207,   207,   207,   207,   150,   227,   227,   227,  -107,
    -107,  -107,   205,   201,   200,  -107,   356,    39,    43,  -107,
    -107,  -107,    -9,  -107,  -107,  -107,  -107,  -107,  -107,    99,
     211,   217,   218,   225,   229,   244,   245,   246,   248,  -107,
    -107,  -107,  -107,   207,   207,   207,   207,   207,   207,   207,
     207,   207,   207,   207,   207,   207,  -107,  -107,  -107,   207,
     207,  -107,  -107,  -107,  -107,  -107,  -107,   200,  -107,  -107,
    -107,  -107,  -107,  -107,  -107,  -107,  -107,  -107,  -107,  -107,
      49,   249,   207,  -107,  -107,   250,  -107
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -107,  -107,  -107,  -107,  -107,  -107,  -107,   236,  -107,  -107,
    -107,  -107,  -107,  -107,  -107,  -107,  -107,  -107,   134,  -107,
    -107,   -53,   146,   159,   153,  -107,  -107,  -107,  -107,  -107,
    -107,  -107,  -107,   -71,  -107,  -107,   203,   -26,   182,   -29,
    -107,   181,  -107,  -107,   -40,  -107,  -107,  -107,   -36,   -38,
     -24,   196,    -7,     9,   -19,  -107,    94,    96,   104,  -106,
    -107,   -14,   -56,   214,  -107,  -107,     4,   -31
};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If zero, do what YYDEFACT says.
   If YYTABLE_NINF, syntax error.  */
#define YYTABLE_NINF -1
static const yytype_uint16 yytable[] =
{
      22,    28,    42,    70,    52,    73,    30,    72,     5,    92,
      22,    88,    29,    82,    40,    77,    24,    68,    25,    28,
      17,     1,    82,    57,   225,    82,   226,    87,    31,    40,
      29,    70,    67,    73,    28,   101,    57,    80,    70,    58,
      73,   110,    61,    62,   142,    29,    80,   154,    81,    80,
      18,    19,    58,    18,    19,   125,    57,    81,    52,   143,
      81,    24,   156,    25,    57,    91,    18,    19,     6,   108,
      20,    57,    58,   162,   163,    34,    63,    57,    82,   109,
      58,   154,   252,    70,   253,    73,    35,    58,   150,   151,
      82,   149,   106,    58,   195,   196,   156,   221,   222,   139,
      41,    63,    80,   223,   224,    18,    19,    18,    19,    37,
      57,   155,    39,    81,    80,    83,    57,   247,   248,    18,
      19,    84,    57,    38,     7,    81,    58,   193,     8,     9,
      10,    66,    58,   140,    24,   141,    25,    63,    58,    97,
      57,    18,    19,    76,    99,   155,   227,   102,   201,   202,
     203,   204,   205,   206,   207,   208,    58,   107,   115,   200,
     118,    23,   209,   210,   211,   130,   119,   121,    24,    75,
      25,   123,   131,    18,    19,   132,   127,   133,   134,   135,
     136,   137,   138,    74,   175,    69,    75,   128,   157,   158,
      18,    19,   166,    75,    76,   167,   168,    18,    19,   169,
      24,   170,    25,   171,    50,   172,   249,   173,   176,   177,
     250,   251,    45,    46,    47,    48,    49,    24,   140,    25,
     141,    50,   130,   174,    24,   178,    25,   139,    50,   131,
     198,   199,   132,   255,   133,   134,   135,   136,   137,   138,
     212,   175,   130,    75,   213,   214,   228,    18,    19,   131,
     229,   230,   132,    36,   133,   134,   135,   136,   137,   138,
     231,   175,   147,    75,   232,   176,   177,    18,    19,    45,
      46,    47,    48,    49,    24,   140,    25,   141,    50,   233,
     234,   235,   178,   236,   254,   256,   197,   105,   165,    45,
      46,    47,    48,    49,    24,   140,    25,   141,    50,   130,
     194,    18,    19,   160,   161,   126,   131,   237,     0,   132,
     238,   133,   134,   135,   136,   137,   138,    74,   139,   239,
     240,   241,   242,   243,   244,   245,   246,    75,    24,   144,
      25,    18,    19,     0,     0,    43,     0,    44,     0,     0,
       0,    18,    19,     0,     0,     0,     0,     0,     0,    43,
      69,    44,   140,     0,   141,    18,    19,     0,    24,     0,
      25,     0,    50,    45,    46,    47,    48,    49,    24,    43,
      25,    44,    50,     0,   148,    18,    19,    45,    46,    47,
      48,    49,    24,     0,    25,     0,    50,    43,   100,    44,
       0,     0,     0,    18,    19,     0,     0,    45,    46,    47,
      48,    49,    24,   215,    25,   216,    50,   217,     0,   218,
       0,   219,     0,   220,     0,    45,    46,    47,    48,    49,
      24,     0,    25,     0,    50
};

static const yytype_int16 yycheck[] =
{
       7,     8,    26,    43,    30,    43,    38,    43,    67,    62,
      17,    17,     8,    44,    21,    44,    67,    41,    69,    26,
      10,    14,    53,    30,    33,    56,    35,    56,    60,    36,
      26,    71,    39,    71,    41,    71,    43,    44,    78,    30,
      78,    94,     4,     5,   115,    41,    53,   118,    44,    56,
      40,    41,    43,    40,    41,   108,    63,    53,    84,   115,
      56,    67,   118,    69,    71,    61,    40,    41,     0,     6,
      60,    78,    63,   126,   127,    13,    38,    84,   109,    16,
      71,   152,    33,   123,    35,   123,    60,    78,    23,    24,
     121,   117,    88,    84,   150,   151,   152,    58,    59,    34,
      33,    38,   109,    60,    61,    40,    41,    40,    41,    72,
     117,   118,    33,   109,   121,    39,   123,   223,   224,    40,
      41,    73,   129,    72,     3,   121,   117,   146,     7,     8,
       9,    72,   123,    68,    67,    70,    69,    38,   129,    20,
     147,    40,    41,    37,    67,   152,   199,    37,   167,   168,
     169,   170,   171,   172,   173,   174,   147,    39,    18,   166,
      21,    60,   176,   177,   178,    15,    11,    74,    67,    36,
      69,    33,    22,    40,    41,    25,    12,    27,    28,    29,
      30,    31,    32,    26,    34,    35,    36,    73,    64,    19,
      40,    41,    34,    36,    37,    34,    34,    40,    41,    34,
      67,    34,    69,    34,    71,    34,   225,    34,    58,    59,
     229,   230,    62,    63,    64,    65,    66,    67,    68,    69,
      70,    71,    15,    34,    67,    75,    69,    34,    71,    22,
      64,    12,    25,   252,    27,    28,    29,    30,    31,    32,
      35,    34,    15,    36,    43,    45,    35,    40,    41,    22,
      33,    33,    25,    17,    27,    28,    29,    30,    31,    32,
      35,    34,   116,    36,    35,    58,    59,    40,    41,    62,
      63,    64,    65,    66,    67,    68,    69,    70,    71,    35,
      35,    35,    75,    35,    35,    35,   152,    84,   129,    62,
      63,    64,    65,    66,    67,    68,    69,    70,    71,    15,
     147,    40,    41,   121,   123,   109,    22,   213,    -1,    25,
     214,    27,    28,    29,    30,    31,    32,    26,    34,   215,
     216,   217,   218,   219,   220,   221,   222,    36,    67,   115,
      69,    40,    41,    -1,    -1,    34,    -1,    36,    -1,    -1,
      -1,    40,    41,    -1,    -1,    -1,    -1,    -1,    -1,    34,
      35,    36,    68,    -1,    70,    40,    41,    -1,    67,    -1,
      69,    -1,    71,    62,    63,    64,    65,    66,    67,    34,
      69,    36,    71,    -1,    73,    40,    41,    62,    63,    64,
      65,    66,    67,    -1,    69,    -1,    71,    34,    35,    36,
      -1,    -1,    -1,    40,    41,    -1,    -1,    62,    63,    64,
      65,    66,    67,    47,    69,    49,    71,    51,    -1,    53,
      -1,    55,    -1,    57,    -1,    62,    63,    64,    65,    66,
      67,    -1,    69,    -1,    71
};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const yytype_uint8 yystos[] =
{
       0,    14,    77,    79,    80,    67,     0,     3,     7,     8,
       9,    78,    82,    84,    86,    87,    81,    10,    40,    41,
      60,    83,   128,    60,    67,    69,    85,   126,   128,   142,
      38,    60,   111,    88,    13,    60,    83,    72,    72,    33,
     128,    33,   126,    34,    36,    62,    63,    64,    65,    66,
      71,   112,   113,   120,   121,   122,   125,   128,   129,   142,
     143,     4,     5,    38,    91,    97,    72,   128,   126,    35,
     120,   123,   124,   125,    26,    36,    37,   115,   119,   127,
     128,   142,   143,    39,    73,   114,   115,   115,    17,    89,
      90,   142,    97,    99,   100,   101,   113,    20,    92,    67,
      35,   124,    37,   117,   124,   112,   142,    39,     6,    16,
      97,   103,   104,   105,   106,    18,   108,   102,    21,    11,
      95,    74,   116,    33,   118,    97,   127,    12,    73,    98,
      15,    22,    25,    27,    28,    29,    30,    31,    32,    34,
      68,    70,   109,   138,   139,   140,   141,    98,    73,   113,
      23,    24,    93,    94,   109,   128,   138,    64,    19,    96,
     114,   117,    97,    97,   107,    99,    34,    34,    34,    34,
      34,    34,    34,    34,    34,    34,    58,    59,    75,   109,
     128,   129,   130,   131,   132,   133,   134,   135,   136,   137,
     138,   139,   110,   130,   100,   138,   138,    94,    64,    12,
     128,   130,   130,   130,   130,   130,   130,   130,   130,   137,
     137,   137,    35,    43,    45,    47,    49,    51,    53,    55,
      57,    58,    59,    60,    61,    33,    35,    97,    35,    33,
      33,    35,    35,    35,    35,    35,    35,   132,   133,   134,
     134,   134,   134,   134,   134,   134,   134,   135,   135,   130,
     130,   130,    33,    35,    35,   130,    35
};

#define yyerrok		(yyerrstatus = 0)
#define yyclearin	(yychar = YYEMPTY)
#define YYEMPTY		(-2)
#define YYEOF		0

#define YYACCEPT	goto yyacceptlab
#define YYABORT		goto yyabortlab
#define YYERROR		goto yyerrorlab


/* Like YYERROR except do call yyerror.  This remains here temporarily
   to ease the transition to the new meaning of YYERROR, for GCC.
   Once GCC version 2 has supplanted version 1, this can go.  */

#define YYFAIL		goto yyerrlab

#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)					\
do								\
  if (yychar == YYEMPTY && yylen == 1)				\
    {								\
      yychar = (Token);						\
      yylval = (Value);						\
      yytoken = YYTRANSLATE (yychar);				\
      YYPOPSTACK (1);						\
      goto yybackup;						\
    }								\
  else								\
    {								\
      yyerror (YY_("syntax error: cannot back up")); \
      YYERROR;							\
    }								\
while (YYID (0))


#define YYTERROR	1
#define YYERRCODE	256


/* YYLLOC_DEFAULT -- Set CURRENT to span from RHS[1] to RHS[N].
   If N is 0, then set CURRENT to the empty location which ends
   the previous symbol: RHS[0] (always defined).  */

#define YYRHSLOC(Rhs, K) ((Rhs)[K])
#ifndef YYLLOC_DEFAULT
# define YYLLOC_DEFAULT(Current, Rhs, N)				\
    do									\
      if (YYID (N))                                                    \
	{								\
	  (Current).first_line   = YYRHSLOC (Rhs, 1).first_line;	\
	  (Current).first_column = YYRHSLOC (Rhs, 1).first_column;	\
	  (Current).last_line    = YYRHSLOC (Rhs, N).last_line;		\
	  (Current).last_column  = YYRHSLOC (Rhs, N).last_column;	\
	}								\
      else								\
	{								\
	  (Current).first_line   = (Current).last_line   =		\
	    YYRHSLOC (Rhs, 0).last_line;				\
	  (Current).first_column = (Current).last_column =		\
	    YYRHSLOC (Rhs, 0).last_column;				\
	}								\
    while (YYID (0))
#endif


/* YY_LOCATION_PRINT -- Print the location on the stream.
   This macro was not mandated originally: define only if we know
   we won't break user code: when these are the locations we know.  */

#ifndef YY_LOCATION_PRINT
# if YYLTYPE_IS_TRIVIAL
#  define YY_LOCATION_PRINT(File, Loc)			\
     fprintf (File, "%d.%d-%d.%d",			\
	      (Loc).first_line, (Loc).first_column,	\
	      (Loc).last_line,  (Loc).last_column)
# else
#  define YY_LOCATION_PRINT(File, Loc) ((void) 0)
# endif
#endif


/* YYLEX -- calling `yylex' with the right arguments.  */

#ifdef YYLEX_PARAM
# define YYLEX yylex (&yylval, YYLEX_PARAM)
#else
# define YYLEX yylex (&yylval)
#endif

/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)			\
do {						\
  if (yydebug)					\
    YYFPRINTF Args;				\
} while (YYID (0))

# define YY_SYMBOL_PRINT(Title, Type, Value, Location)			  \
do {									  \
  if (yydebug)								  \
    {									  \
      YYFPRINTF (stderr, "%s ", Title);					  \
      yy_symbol_print (stderr,						  \
		  Type, Value); \
      YYFPRINTF (stderr, "\n");						  \
    }									  \
} while (YYID (0))


/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

/*ARGSUSED*/
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_symbol_value_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep)
#else
static void
yy_symbol_value_print (yyoutput, yytype, yyvaluep)
    FILE *yyoutput;
    int yytype;
    YYSTYPE const * const yyvaluep;
#endif
{
  if (!yyvaluep)
    return;
# ifdef YYPRINT
  if (yytype < YYNTOKENS)
    YYPRINT (yyoutput, yytoknum[yytype], *yyvaluep);
# else
  YYUSE (yyoutput);
# endif
  switch (yytype)
    {
      default:
	break;
    }
}


/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_symbol_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep)
#else
static void
yy_symbol_print (yyoutput, yytype, yyvaluep)
    FILE *yyoutput;
    int yytype;
    YYSTYPE const * const yyvaluep;
#endif
{
  if (yytype < YYNTOKENS)
    YYFPRINTF (yyoutput, "token %s (", yytname[yytype]);
  else
    YYFPRINTF (yyoutput, "nterm %s (", yytname[yytype]);

  yy_symbol_value_print (yyoutput, yytype, yyvaluep);
  YYFPRINTF (yyoutput, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_stack_print (yytype_int16 *bottom, yytype_int16 *top)
#else
static void
yy_stack_print (bottom, top)
    yytype_int16 *bottom;
    yytype_int16 *top;
#endif
{
  YYFPRINTF (stderr, "Stack now");
  for (; bottom <= top; ++bottom)
    YYFPRINTF (stderr, " %d", *bottom);
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)				\
do {								\
  if (yydebug)							\
    yy_stack_print ((Bottom), (Top));				\
} while (YYID (0))


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_reduce_print (YYSTYPE *yyvsp, int yyrule)
#else
static void
yy_reduce_print (yyvsp, yyrule)
    YYSTYPE *yyvsp;
    int yyrule;
#endif
{
  int yynrhs = yyr2[yyrule];
  int yyi;
  unsigned long int yylno = yyrline[yyrule];
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %lu):\n",
	     yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      fprintf (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr, yyrhs[yyprhs[yyrule] + yyi],
		       &(yyvsp[(yyi + 1) - (yynrhs)])
		       		       );
      fprintf (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)		\
do {					\
  if (yydebug)				\
    yy_reduce_print (yyvsp, Rule); \
} while (YYID (0))

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args)
# define YY_SYMBOL_PRINT(Title, Type, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef	YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif



#if YYERROR_VERBOSE

# ifndef yystrlen
#  if defined __GLIBC__ && defined _STRING_H
#   define yystrlen strlen
#  else
/* Return the length of YYSTR.  */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static YYSIZE_T
yystrlen (const char *yystr)
#else
static YYSIZE_T
yystrlen (yystr)
    const char *yystr;
#endif
{
  YYSIZE_T yylen;
  for (yylen = 0; yystr[yylen]; yylen++)
    continue;
  return yylen;
}
#  endif
# endif

# ifndef yystpcpy
#  if defined __GLIBC__ && defined _STRING_H && defined _GNU_SOURCE
#   define yystpcpy stpcpy
#  else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static char *
yystpcpy (char *yydest, const char *yysrc)
#else
static char *
yystpcpy (yydest, yysrc)
    char *yydest;
    const char *yysrc;
#endif
{
  char *yyd = yydest;
  const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
#  endif
# endif

# ifndef yytnamerr
/* Copy to YYRES the contents of YYSTR after stripping away unnecessary
   quotes and backslashes, so that it's suitable for yyerror.  The
   heuristic is that double-quoting is unnecessary unless the string
   contains an apostrophe, a comma, or backslash (other than
   backslash-backslash).  YYSTR is taken from yytname.  If YYRES is
   null, do not copy; instead, return the length of what the result
   would have been.  */
static YYSIZE_T
yytnamerr (char *yyres, const char *yystr)
{
  if (*yystr == '"')
    {
      YYSIZE_T yyn = 0;
      char const *yyp = yystr;

      for (;;)
	switch (*++yyp)
	  {
	  case '\'':
	  case ',':
	    goto do_not_strip_quotes;

	  case '\\':
	    if (*++yyp != '\\')
	      goto do_not_strip_quotes;
	    /* Fall through.  */
	  default:
	    if (yyres)
	      yyres[yyn] = *yyp;
	    yyn++;
	    break;

	  case '"':
	    if (yyres)
	      yyres[yyn] = '\0';
	    return yyn;
	  }
    do_not_strip_quotes: ;
    }

  if (! yyres)
    return yystrlen (yystr);

  return yystpcpy (yyres, yystr) - yyres;
}
# endif

/* Copy into YYRESULT an error message about the unexpected token
   YYCHAR while in state YYSTATE.  Return the number of bytes copied,
   including the terminating null byte.  If YYRESULT is null, do not
   copy anything; just return the number of bytes that would be
   copied.  As a special case, return 0 if an ordinary "syntax error"
   message will do.  Return YYSIZE_MAXIMUM if overflow occurs during
   size calculation.  */
static YYSIZE_T
yysyntax_error (char *yyresult, int yystate, int yychar)
{
  int yyn = yypact[yystate];

  if (! (YYPACT_NINF < yyn && yyn <= YYLAST))
    return 0;
  else
    {
      int yytype = YYTRANSLATE (yychar);
      YYSIZE_T yysize0 = yytnamerr (0, yytname[yytype]);
      YYSIZE_T yysize = yysize0;
      YYSIZE_T yysize1;
      int yysize_overflow = 0;
      enum { YYERROR_VERBOSE_ARGS_MAXIMUM = 5 };
      char const *yyarg[YYERROR_VERBOSE_ARGS_MAXIMUM];
      int yyx;

# if 0
      /* This is so xgettext sees the translatable formats that are
	 constructed on the fly.  */
      YY_("syntax error, unexpected %s");
      YY_("syntax error, unexpected %s, expecting %s");
      YY_("syntax error, unexpected %s, expecting %s or %s");
      YY_("syntax error, unexpected %s, expecting %s or %s or %s");
      YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s");
# endif
      char *yyfmt;
      char const *yyf;
      static char const yyunexpected[] = "syntax error, unexpected %s";
      static char const yyexpecting[] = ", expecting %s";
      static char const yyor[] = " or %s";
      char yyformat[sizeof yyunexpected
		    + sizeof yyexpecting - 1
		    + ((YYERROR_VERBOSE_ARGS_MAXIMUM - 2)
		       * (sizeof yyor - 1))];
      char const *yyprefix = yyexpecting;

      /* Start YYX at -YYN if negative to avoid negative indexes in
	 YYCHECK.  */
      int yyxbegin = yyn < 0 ? -yyn : 0;

      /* Stay within bounds of both yycheck and yytname.  */
      int yychecklim = YYLAST - yyn + 1;
      int yyxend = yychecklim < YYNTOKENS ? yychecklim : YYNTOKENS;
      int yycount = 1;

      yyarg[0] = yytname[yytype];
      yyfmt = yystpcpy (yyformat, yyunexpected);

      for (yyx = yyxbegin; yyx < yyxend; ++yyx)
	if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR)
	  {
	    if (yycount == YYERROR_VERBOSE_ARGS_MAXIMUM)
	      {
		yycount = 1;
		yysize = yysize0;
		yyformat[sizeof yyunexpected - 1] = '\0';
		break;
	      }
	    yyarg[yycount++] = yytname[yyx];
	    yysize1 = yysize + yytnamerr (0, yytname[yyx]);
	    yysize_overflow |= (yysize1 < yysize);
	    yysize = yysize1;
	    yyfmt = yystpcpy (yyfmt, yyprefix);
	    yyprefix = yyor;
	  }

      yyf = YY_(yyformat);
      yysize1 = yysize + yystrlen (yyf);
      yysize_overflow |= (yysize1 < yysize);
      yysize = yysize1;

      if (yysize_overflow)
	return YYSIZE_MAXIMUM;

      if (yyresult)
	{
	  /* Avoid sprintf, as that infringes on the user's name space.
	     Don't have undefined behavior even if the translation
	     produced a string with the wrong number of "%s"s.  */
	  char *yyp = yyresult;
	  int yyi = 0;
	  while ((*yyp = *yyf) != '\0')
	    {
	      if (*yyp == '%' && yyf[1] == 's' && yyi < yycount)
		{
		  yyp += yytnamerr (yyp, yyarg[yyi++]);
		  yyf += 2;
		}
	      else
		{
		  yyp++;
		  yyf++;
		}
	    }
	}
      return yysize;
    }
}
#endif /* YYERROR_VERBOSE */


/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

/*ARGSUSED*/
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yydestruct (const char *yymsg, int yytype, YYSTYPE *yyvaluep)
#else
static void
yydestruct (yymsg, yytype, yyvaluep)
    const char *yymsg;
    int yytype;
    YYSTYPE *yyvaluep;
#endif
{
  YYUSE (yyvaluep);

  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yytype, yyvaluep, yylocationp);

  switch (yytype)
    {
      case 62: /* "\"floating point literal\"" */
#line 212 "./sparql_parser.y"
	{ rasqal_free_literal((yyvaluep->literal)); };
#line 1500 "sparql_parser.c"
	break;
      case 63: /* "\"string literal\"" */
#line 212 "./sparql_parser.y"
	{ rasqal_free_literal((yyvaluep->literal)); };
#line 1505 "sparql_parser.c"
	break;
      case 64: /* "\"integer literal\"" */
#line 212 "./sparql_parser.y"
	{ rasqal_free_literal((yyvaluep->literal)); };
#line 1510 "sparql_parser.c"
	break;
      case 65: /* "\"boolean literal\"" */
#line 212 "./sparql_parser.y"
	{ rasqal_free_literal((yyvaluep->literal)); };
#line 1515 "sparql_parser.c"
	break;
      case 66: /* "\"decimal literal\"" */
#line 212 "./sparql_parser.y"
	{ rasqal_free_literal((yyvaluep->literal)); };
#line 1520 "sparql_parser.c"
	break;
      case 67: /* "\"URI literal\"" */
#line 213 "./sparql_parser.y"
	{ raptor_free_uri((yyvaluep->uri)); };
#line 1525 "sparql_parser.c"
	break;
      case 68: /* "\"URI literal (\"" */
#line 213 "./sparql_parser.y"
	{ raptor_free_uri((yyvaluep->uri)); };
#line 1530 "sparql_parser.c"
	break;
      case 69: /* "\"QName literal\"" */
#line 214 "./sparql_parser.y"
	{ RASQAL_FREE(cstring, (yyvaluep->name)); };
#line 1535 "sparql_parser.c"
	break;
      case 70: /* "\"QName literal (\"" */
#line 214 "./sparql_parser.y"
	{ RASQAL_FREE(cstring, (yyvaluep->name)); };
#line 1540 "sparql_parser.c"
	break;
      case 71: /* "\"blank node literal\"" */
#line 214 "./sparql_parser.y"
	{ RASQAL_FREE(cstring, (yyvaluep->name)); };
#line 1545 "sparql_parser.c"
	break;
      case 72: /* "\"identifier\"" */
#line 214 "./sparql_parser.y"
	{ RASQAL_FREE(cstring, (yyvaluep->name)); };
#line 1550 "sparql_parser.c"
	break;

      default:
	break;
    }
}


/* Prevent warnings from -Wmissing-prototypes.  */

#ifdef YYPARSE_PARAM
#if defined __STDC__ || defined __cplusplus
int yyparse (void *YYPARSE_PARAM);
#else
int yyparse ();
#endif
#else /* ! YYPARSE_PARAM */
#if defined __STDC__ || defined __cplusplus
int yyparse (void);
#else
int yyparse ();
#endif
#endif /* ! YYPARSE_PARAM */






/*----------.
| yyparse.  |
`----------*/

#ifdef YYPARSE_PARAM
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
int
yyparse (void *YYPARSE_PARAM)
#else
int
yyparse (YYPARSE_PARAM)
    void *YYPARSE_PARAM;
#endif
#else /* ! YYPARSE_PARAM */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
int
yyparse (void)
#else
int
yyparse ()

#endif
#endif
{
  /* The look-ahead symbol.  */
int yychar;

/* The semantic value of the look-ahead symbol.  */
YYSTYPE yylval;

/* Number of syntax errors so far.  */
int yynerrs;

  int yystate;
  int yyn;
  int yyresult;
  /* Number of tokens to shift before error messages enabled.  */
  int yyerrstatus;
  /* Look-ahead token as an internal (translated) token number.  */
  int yytoken = 0;
#if YYERROR_VERBOSE
  /* Buffer for error messages, and its allocated size.  */
  char yymsgbuf[128];
  char *yymsg = yymsgbuf;
  YYSIZE_T yymsg_alloc = sizeof yymsgbuf;
#endif

  /* Three stacks and their tools:
     `yyss': related to states,
     `yyvs': related to semantic values,
     `yyls': related to locations.

     Refer to the stacks thru separate pointers, to allow yyoverflow
     to reallocate them elsewhere.  */

  /* The state stack.  */
  yytype_int16 yyssa[YYINITDEPTH];
  yytype_int16 *yyss = yyssa;
  yytype_int16 *yyssp;

  /* The semantic value stack.  */
  YYSTYPE yyvsa[YYINITDEPTH];
  YYSTYPE *yyvs = yyvsa;
  YYSTYPE *yyvsp;



#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  YYSIZE_T yystacksize = YYINITDEPTH;

  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;


  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yystate = 0;
  yyerrstatus = 0;
  yynerrs = 0;
  yychar = YYEMPTY;		/* Cause a token to be read.  */

  /* Initialize stack pointers.
     Waste one element of value and location stack
     so that they stay on the same level as the state stack.
     The wasted elements are never initialized.  */

  yyssp = yyss;
  yyvsp = yyvs;

  goto yysetstate;

/*------------------------------------------------------------.
| yynewstate -- Push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
 yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;

 yysetstate:
  *yyssp = yystate;

  if (yyss + yystacksize - 1 <= yyssp)
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYSIZE_T yysize = yyssp - yyss + 1;

#ifdef yyoverflow
      {
	/* Give user a chance to reallocate the stack.  Use copies of
	   these so that the &'s don't force the real ones into
	   memory.  */
	YYSTYPE *yyvs1 = yyvs;
	yytype_int16 *yyss1 = yyss;


	/* Each stack pointer address is followed by the size of the
	   data in use in that stack, in bytes.  This used to be a
	   conditional around just the two extra args, but that might
	   be undefined if yyoverflow is a macro.  */
	yyoverflow (YY_("memory exhausted"),
		    &yyss1, yysize * sizeof (*yyssp),
		    &yyvs1, yysize * sizeof (*yyvsp),

		    &yystacksize);

	yyss = yyss1;
	yyvs = yyvs1;
      }
#else /* no yyoverflow */
# ifndef YYSTACK_RELOCATE
      goto yyexhaustedlab;
# else
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
	goto yyexhaustedlab;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
	yystacksize = YYMAXDEPTH;

      {
	yytype_int16 *yyss1 = yyss;
	union yyalloc *yyptr =
	  (union yyalloc *) YYSTACK_ALLOC (YYSTACK_BYTES (yystacksize));
	if (! yyptr)
	  goto yyexhaustedlab;
	YYSTACK_RELOCATE (yyss);
	YYSTACK_RELOCATE (yyvs);

#  undef YYSTACK_RELOCATE
	if (yyss1 != yyssa)
	  YYSTACK_FREE (yyss1);
      }
# endif
#endif /* no yyoverflow */

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;


      YYDPRINTF ((stderr, "Stack size increased to %lu\n",
		  (unsigned long int) yystacksize));

      if (yyss + yystacksize - 1 <= yyssp)
	YYABORT;
    }

  YYDPRINTF ((stderr, "Entering state %d\n", yystate));

  goto yybackup;

/*-----------.
| yybackup.  |
`-----------*/
yybackup:

  /* Do appropriate processing given the current state.  Read a
     look-ahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to look-ahead token.  */
  yyn = yypact[yystate];
  if (yyn == YYPACT_NINF)
    goto yydefault;

  /* Not known => get a look-ahead token if don't already have one.  */

  /* YYCHAR is either YYEMPTY or YYEOF or a valid look-ahead symbol.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token: "));
      yychar = YYLEX;
    }

  if (yychar <= YYEOF)
    {
      yychar = yytoken = YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yyn == 0 || yyn == YYTABLE_NINF)
	goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  if (yyn == YYFINAL)
    YYACCEPT;

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the look-ahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);

  /* Discard the shifted token unless it is eof.  */
  if (yychar != YYEOF)
    yychar = YYEMPTY;

  yystate = yyn;
  *++yyvsp = yylval;

  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- Do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     `$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
        case 2:
#line 227 "./sparql_parser.y"
    {
}
    break;

  case 3:
#line 234 "./sparql_parser.y"
    {
  ((rasqal_query*)rq)->selects=(yyvsp[(1) - (1)].seq);
  ((rasqal_query*)rq)->verb=RASQAL_QUERY_VERB_SELECT;
}
    break;

  case 4:
#line 239 "./sparql_parser.y"
    {
  ((rasqal_query*)rq)->constructs=(yyvsp[(1) - (1)].seq);
  ((rasqal_query*)rq)->verb=RASQAL_QUERY_VERB_CONSTRUCT;
}
    break;

  case 5:
#line 244 "./sparql_parser.y"
    {
  ((rasqal_query*)rq)->describes=(yyvsp[(1) - (1)].seq);
  ((rasqal_query*)rq)->verb=RASQAL_QUERY_VERB_DESCRIBE;
}
    break;

  case 6:
#line 249 "./sparql_parser.y"
    {
  ((rasqal_query*)rq)->verb=RASQAL_QUERY_VERB_ASK;
}
    break;

  case 7:
#line 257 "./sparql_parser.y"
    {
  /* nothing to do */
}
    break;

  case 8:
#line 265 "./sparql_parser.y"
    {
  if(((rasqal_query*)rq)->base_uri)
    raptor_free_uri(((rasqal_query*)rq)->base_uri);
  ((rasqal_query*)rq)->base_uri=(yyvsp[(2) - (2)].uri);
}
    break;

  case 9:
#line 271 "./sparql_parser.y"
    {
  /* nothing to do */
}
    break;

  case 10:
#line 279 "./sparql_parser.y"
    {
  raptor_sequence *seq=((rasqal_query*)rq)->prefixes;
  unsigned const char* prefix_string=(yyvsp[(3) - (4)].name);
  size_t l=0;

  if(prefix_string)
    l=strlen((const char*)prefix_string);
  
  if(raptor_namespaces_find_namespace(((rasqal_query*)rq)->namespaces, prefix_string, l)) {
    /* A prefix may be defined only once */
    sparql_syntax_warning(((rasqal_query*)rq), 
                          "PREFIX %s can be defined only once.",
                          prefix_string ? (const char*)prefix_string : ":");
  } else {
    rasqal_prefix *p=rasqal_new_prefix(prefix_string, (yyvsp[(4) - (4)].uri));
    raptor_sequence_push(seq, p);
    rasqal_query_declare_prefix(((rasqal_query*)rq), p);
  }
}
    break;

  case 11:
#line 299 "./sparql_parser.y"
    {
  /* nothing to do, rq->prefixes already initialised */
}
    break;

  case 12:
#line 307 "./sparql_parser.y"
    {
  (yyval.seq)=(yyvsp[(3) - (3)].seq);
  ((rasqal_query*)rq)->distinct=1;
}
    break;

  case 13:
#line 312 "./sparql_parser.y"
    {
  (yyval.seq)=NULL;
  ((rasqal_query*)rq)->wildcard=1;
  ((rasqal_query*)rq)->distinct=1;
}
    break;

  case 14:
#line 318 "./sparql_parser.y"
    {
  (yyval.seq)=(yyvsp[(2) - (2)].seq);
}
    break;

  case 15:
#line 322 "./sparql_parser.y"
    {
  (yyval.seq)=NULL;
  ((rasqal_query*)rq)->wildcard=1;
}
    break;

  case 16:
#line 331 "./sparql_parser.y"
    {
  (yyval.seq)=(yyvsp[(1) - (2)].seq);
  raptor_sequence_push((yyval.seq), (yyvsp[(2) - (2)].variable));
}
    break;

  case 17:
#line 336 "./sparql_parser.y"
    {
  (yyval.seq)=(yyvsp[(1) - (3)].seq);
  raptor_sequence_push((yyval.seq), (yyvsp[(3) - (3)].variable));
}
    break;

  case 18:
#line 341 "./sparql_parser.y"
    {
  /* The variables are freed from the raptor_query field variables */
  (yyval.seq)=raptor_new_sequence(NULL, (raptor_sequence_print_handler*)rasqal_variable_print);
  raptor_sequence_push((yyval.seq), (yyvsp[(1) - (1)].variable));
}
    break;

  case 19:
#line 351 "./sparql_parser.y"
    {
  (yyval.seq)=(yyvsp[(2) - (2)].seq);
}
    break;

  case 20:
#line 355 "./sparql_parser.y"
    {
  (yyval.seq)=NULL;
}
    break;

  case 21:
#line 363 "./sparql_parser.y"
    {
  (yyval.seq)=(yyvsp[(1) - (2)].seq);
  raptor_sequence_push((yyval.seq), (yyvsp[(2) - (2)].literal));
}
    break;

  case 22:
#line 368 "./sparql_parser.y"
    {
  (yyval.seq)=(yyvsp[(1) - (3)].seq);
  raptor_sequence_push((yyval.seq), (yyvsp[(3) - (3)].literal));
}
    break;

  case 23:
#line 373 "./sparql_parser.y"
    {
  (yyval.seq)=raptor_new_sequence(NULL, (raptor_sequence_print_handler*)rasqal_literal_print);
  raptor_sequence_push((yyval.seq), (yyvsp[(1) - (1)].literal));
}
    break;

  case 24:
#line 382 "./sparql_parser.y"
    {
  (yyval.seq)=(yyvsp[(2) - (2)].seq);
}
    break;

  case 25:
#line 386 "./sparql_parser.y"
    {
  (yyval.seq)=NULL;
  ((rasqal_query*)rq)->wildcard=1;
}
    break;

  case 26:
#line 395 "./sparql_parser.y"
    {
  /* nothing to do */
}
    break;

  case 30:
#line 409 "./sparql_parser.y"
    {
  if((yyvsp[(1) - (1)].literal)) {
    raptor_uri* uri=rasqal_literal_as_uri((yyvsp[(1) - (1)].literal));
    rasqal_query_add_data_graph((rasqal_query*)rq, uri, uri, RASQAL_DATA_GRAPH_BACKGROUND);
    rasqal_free_literal((yyvsp[(1) - (1)].literal));
  }
}
    break;

  case 31:
#line 421 "./sparql_parser.y"
    {
  if((yyvsp[(2) - (2)].literal)) {
    raptor_uri* uri=rasqal_literal_as_uri((yyvsp[(2) - (2)].literal));
    rasqal_query_add_data_graph((rasqal_query*)rq, uri, uri, RASQAL_DATA_GRAPH_NAMED);
    rasqal_free_literal((yyvsp[(2) - (2)].literal));
  }
}
    break;

  case 32:
#line 436 "./sparql_parser.y"
    {
  ((rasqal_query*)rq)->query_graph_pattern=(yyvsp[(2) - (2)].graph_pattern);
}
    break;

  case 33:
#line 440 "./sparql_parser.y"
    {
  sparql_syntax_warning(((rasqal_query*)rq), "WHERE omitted");
  ((rasqal_query*)rq)->query_graph_pattern=(yyvsp[(1) - (1)].graph_pattern);
}
    break;

  case 35:
#line 452 "./sparql_parser.y"
    {
  if(((rasqal_query*)rq)->verb == RASQAL_QUERY_VERB_ASK) {
    sparql_query_error((rasqal_query*)rq, "ORDER BY cannot be used with ASK");
  } else {
    ((rasqal_query*)rq)->order_conditions_sequence=(yyvsp[(3) - (3)].seq);
  }
}
    break;

  case 37:
#line 465 "./sparql_parser.y"
    {
  (yyval.seq)=(yyvsp[(1) - (2)].seq);
  if((yyvsp[(2) - (2)].expr))
    raptor_sequence_push((yyval.seq), (yyvsp[(2) - (2)].expr));
}
    break;

  case 38:
#line 471 "./sparql_parser.y"
    {
  (yyval.seq)=raptor_new_sequence((raptor_sequence_free_handler*)rasqal_free_expression, (raptor_sequence_print_handler*)rasqal_expression_print);
  if((yyvsp[(1) - (1)].expr))
    raptor_sequence_push((yyval.seq), (yyvsp[(1) - (1)].expr));
}
    break;

  case 39:
#line 481 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_1op_expression(RASQAL_EXPR_ORDER_COND_ASC, (yyvsp[(2) - (2)].expr));
}
    break;

  case 40:
#line 485 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_1op_expression(RASQAL_EXPR_ORDER_COND_DESC, (yyvsp[(2) - (2)].expr));
}
    break;

  case 41:
#line 489 "./sparql_parser.y"
    {
  /* The direction of ordering is ascending by default */
  (yyval.expr)=rasqal_new_1op_expression(RASQAL_EXPR_ORDER_COND_ASC, (yyvsp[(1) - (1)].expr));
}
    break;

  case 42:
#line 494 "./sparql_parser.y"
    {
  rasqal_literal* l=rasqal_new_variable_literal((yyvsp[(1) - (1)].variable));
  rasqal_expression *e=rasqal_new_literal_expression(l);
  /* The direction of ordering is ascending by default */
  (yyval.expr)=rasqal_new_1op_expression(RASQAL_EXPR_ORDER_COND_ASC, e);
}
    break;

  case 43:
#line 501 "./sparql_parser.y"
    {
  /* The direction of ordering is ascending by default */
  (yyval.expr)=rasqal_new_1op_expression(RASQAL_EXPR_ORDER_COND_ASC, (yyvsp[(1) - (1)].expr));
}
    break;

  case 44:
#line 510 "./sparql_parser.y"
    {
  if(((rasqal_query*)rq)->verb == RASQAL_QUERY_VERB_ASK) {
    sparql_query_error((rasqal_query*)rq, "LIMIT cannot be used with ASK");
  } else {
    if((yyvsp[(2) - (2)].literal) != NULL) {
      ((rasqal_query*)rq)->limit=(yyvsp[(2) - (2)].literal)->value.integer;
      rasqal_free_literal((yyvsp[(2) - (2)].literal));
    }
  }
  
}
    break;

  case 46:
#line 527 "./sparql_parser.y"
    {
  if(((rasqal_query*)rq)->verb == RASQAL_QUERY_VERB_ASK) {
    sparql_query_error((rasqal_query*)rq, "LIMIT cannot be used with ASK");
  } else {
    if((yyvsp[(2) - (2)].literal) != NULL) {
      ((rasqal_query*)rq)->offset=(yyvsp[(2) - (2)].literal)->value.integer;
      rasqal_free_literal((yyvsp[(2) - (2)].literal));
    }
  }
}
    break;

  case 48:
#line 543 "./sparql_parser.y"
    {
  (yyval.graph_pattern)=(yyvsp[(2) - (3)].graph_pattern);
}
    break;

  case 51:
#line 556 "./sparql_parser.y"
    {
#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "GraphPattern 1\n  FilteredBasicGraphPattern=");
  if((yyvsp[(1) - (4)].graph_pattern))
    rasqal_graph_pattern_print((yyvsp[(1) - (4)].graph_pattern), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fprintf(DEBUG_FH, ", GraphPatternNotTriples=");
  if((yyvsp[(2) - (4)].graph_pattern))
    rasqal_graph_pattern_print((yyvsp[(2) - (4)].graph_pattern), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fprintf(DEBUG_FH, ", GraphPattern=");
  if((yyvsp[(4) - (4)].graph_pattern))
    rasqal_graph_pattern_print((yyvsp[(4) - (4)].graph_pattern), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fputs("\n", DEBUG_FH);
#endif

  (yyval.graph_pattern)=(yyvsp[(4) - (4)].graph_pattern);
  /* push ($1,$2) to start of $4 graph sequence */
  if((yyvsp[(2) - (4)].graph_pattern))
    raptor_sequence_shift((yyval.graph_pattern)->graph_patterns, (yyvsp[(2) - (4)].graph_pattern));
  if((yyvsp[(1) - (4)].graph_pattern))
    raptor_sequence_shift((yyval.graph_pattern)->graph_patterns, (yyvsp[(1) - (4)].graph_pattern));

#if RASQAL_DEBUG > 1
  fprintf(DEBUG_FH, "  after grouping graph pattern=");
  if((yyval.graph_pattern))
    rasqal_graph_pattern_print((yyval.graph_pattern), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fprintf(DEBUG_FH, "\n\n");
#endif
}
    break;

  case 52:
#line 593 "./sparql_parser.y"
    {
  raptor_sequence *seq;

#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "GraphPattern 2\n  FilteredBasicGraphPattern=");
  if((yyvsp[(1) - (1)].graph_pattern))
    rasqal_graph_pattern_print((yyvsp[(1) - (1)].graph_pattern), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fputs("\n", DEBUG_FH);
#endif

  seq=raptor_new_sequence((raptor_sequence_free_handler*)rasqal_free_graph_pattern, (raptor_sequence_print_handler*)rasqal_graph_pattern_print);
  if((yyvsp[(1) - (1)].graph_pattern))
    raptor_sequence_push(seq, (yyvsp[(1) - (1)].graph_pattern));

  (yyval.graph_pattern)=rasqal_new_graph_pattern_from_sequence((rasqal_query*)rq, seq,
                                            RASQAL_GRAPH_PATTERN_OPERATOR_GROUP);
#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "  after grouping graph pattern=");
  if((yyval.graph_pattern))
    rasqal_graph_pattern_print((yyval.graph_pattern), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fprintf(DEBUG_FH, "\n\n");
#endif
}
    break;

  case 53:
#line 625 "./sparql_parser.y"
    {
#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "FilteredBasicGraphPattern 1\n  BlockOfTriplesOpt=");
  if((yyvsp[(1) - (4)].formula))
    rasqal_formula_print((yyvsp[(1) - (4)].formula), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fprintf(DEBUG_FH, ", Constraint=");
  if((yyvsp[(2) - (4)].expr))
    rasqal_expression_print((yyvsp[(2) - (4)].expr), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fprintf(DEBUG_FH, ", FilteredBasicGraphPattern=");
  if((yyvsp[(4) - (4)].graph_pattern))
    rasqal_graph_pattern_print((yyvsp[(4) - (4)].graph_pattern), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fputs("\n", DEBUG_FH);
#endif

  (yyval.graph_pattern)=(yyvsp[(4) - (4)].graph_pattern);
  /* push $1 to start of $4 graph sequence */
  if((yyvsp[(1) - (4)].formula)) {
    rasqal_graph_pattern *gp;
    
    gp=rasqal_engine_new_graph_pattern_from_formula((rasqal_query*)rq, (yyvsp[(1) - (4)].formula),
                                                    RASQAL_GRAPH_PATTERN_OPERATOR_BASIC);

    raptor_sequence_shift((yyval.graph_pattern)->graph_patterns, gp);
  }
  
  if((yyvsp[(2) - (4)].expr))
    rasqal_graph_pattern_add_constraint((yyval.graph_pattern), (yyvsp[(2) - (4)].expr));
  
#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "  after grouping graph pattern=");
  if((yyval.graph_pattern))
    rasqal_graph_pattern_print((yyval.graph_pattern), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fprintf(DEBUG_FH, "\n\n");
#endif
}
    break;

  case 54:
#line 669 "./sparql_parser.y"
    {
  rasqal_graph_pattern *formula_gp=NULL;
  raptor_sequence *seq;

#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "FilteredBasicGraphPattern 2\n  BlockOfTriplesOpt=");
  if((yyvsp[(1) - (1)].formula))
    rasqal_formula_print((yyvsp[(1) - (1)].formula), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fputs("\n", DEBUG_FH);
#endif

  if((yyvsp[(1) - (1)].formula))
    formula_gp=rasqal_engine_new_graph_pattern_from_formula((rasqal_query*)rq, (yyvsp[(1) - (1)].formula),
                                                            RASQAL_GRAPH_PATTERN_OPERATOR_BASIC);
  
  seq=raptor_new_sequence((raptor_sequence_free_handler*)rasqal_free_graph_pattern, (raptor_sequence_print_handler*)rasqal_graph_pattern_print);
  if(formula_gp)
    raptor_sequence_push(seq, formula_gp);

  (yyval.graph_pattern)=rasqal_new_graph_pattern_from_sequence((rasqal_query*)rq,
                                            seq,
                                            RASQAL_GRAPH_PATTERN_OPERATOR_GROUP);

#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "  after, group graph pattern=");
  if((yyval.graph_pattern))
    rasqal_graph_pattern_print((yyval.graph_pattern), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fprintf(DEBUG_FH, "\n\n");
#endif
}
    break;

  case 55:
#line 708 "./sparql_parser.y"
    {
#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "BlockOfTriplesOpt\n  TriplesSameSubject=");
  if((yyvsp[(1) - (2)].formula))
    rasqal_formula_print((yyvsp[(1) - (2)].formula), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fputs("  TriplesSameSubjectDotListOpt=", DEBUG_FH);
  if((yyvsp[(2) - (2)].formula))
    rasqal_formula_print((yyvsp[(2) - (2)].formula), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fputs("\n", DEBUG_FH);
#endif


  /* $1 and $2 are freed as necessary */
  (yyval.formula)=rasqal_formula_join((yyvsp[(1) - (2)].formula), (yyvsp[(2) - (2)].formula));
#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "  after joining formula=");
  rasqal_formula_print((yyval.formula), DEBUG_FH);
  fprintf(DEBUG_FH, "\n\n");
#endif
}
    break;

  case 56:
#line 733 "./sparql_parser.y"
    {
  (yyval.formula)=NULL;
}
    break;

  case 57:
#line 744 "./sparql_parser.y"
    {
#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "TriplesSameSubjectDotTriplesOpt\n  TriplesSameSubjectDotListOpt=");
  if((yyvsp[(1) - (2)].formula))
    rasqal_formula_print((yyvsp[(1) - (2)].formula), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fputs("  TriplesSameSubject=", DEBUG_FH);
  if((yyvsp[(2) - (2)].formula))
    rasqal_formula_print((yyvsp[(2) - (2)].formula), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fputs("\n", DEBUG_FH);
#endif

  /* $1 and $2 are freed as necessary */
  (yyval.formula)=rasqal_formula_join((yyvsp[(1) - (2)].formula), (yyvsp[(2) - (2)].formula));

#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "  after joining formula=");
  rasqal_formula_print((yyval.formula), DEBUG_FH);
  fprintf(DEBUG_FH, "\n\n");
#endif
}
    break;

  case 58:
#line 769 "./sparql_parser.y"
    {
  (yyval.formula)=(yyvsp[(1) - (2)].formula);
}
    break;

  case 59:
#line 773 "./sparql_parser.y"
    {
  (yyval.formula)=NULL;
}
    break;

  case 60:
#line 781 "./sparql_parser.y"
    {
  (yyval.graph_pattern)=(yyvsp[(1) - (1)].graph_pattern);
}
    break;

  case 61:
#line 785 "./sparql_parser.y"
    {
  (yyval.graph_pattern)=(yyvsp[(1) - (1)].graph_pattern);
}
    break;

  case 62:
#line 789 "./sparql_parser.y"
    {
  (yyval.graph_pattern)=(yyvsp[(1) - (1)].graph_pattern);
}
    break;

  case 63:
#line 797 "./sparql_parser.y"
    {
#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "PatternElementForms 4\n  graphpattern=");
  if((yyvsp[(2) - (2)].graph_pattern))
    rasqal_graph_pattern_print((yyvsp[(2) - (2)].graph_pattern), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fputs("\n\n", DEBUG_FH);
#endif

  if((yyvsp[(2) - (2)].graph_pattern))
    (yyvsp[(2) - (2)].graph_pattern)->op = RASQAL_GRAPH_PATTERN_OPERATOR_OPTIONAL;

  (yyval.graph_pattern)=(yyvsp[(2) - (2)].graph_pattern);
}
    break;

  case 64:
#line 817 "./sparql_parser.y"
    {
#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "GraphGraphPattern 2\n  varoruri=");
  rasqal_literal_print((yyvsp[(2) - (3)].literal), DEBUG_FH);
  fprintf(DEBUG_FH, ", graphpattern=");
  if((yyvsp[(3) - (3)].graph_pattern))
    rasqal_graph_pattern_print((yyvsp[(3) - (3)].graph_pattern), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fputs("\n\n", DEBUG_FH);
#endif

  if((yyvsp[(3) - (3)].graph_pattern)) {
    rasqal_graph_pattern_set_origin((yyvsp[(3) - (3)].graph_pattern), (yyvsp[(2) - (3)].literal));
    (yyvsp[(3) - (3)].graph_pattern)->op = RASQAL_GRAPH_PATTERN_OPERATOR_GRAPH;
  }

  rasqal_free_literal((yyvsp[(2) - (3)].literal));
  (yyval.graph_pattern)=(yyvsp[(3) - (3)].graph_pattern);
}
    break;

  case 65:
#line 842 "./sparql_parser.y"
    {
  (yyval.graph_pattern)=(yyvsp[(3) - (3)].graph_pattern);
  raptor_sequence_push((yyval.graph_pattern)->graph_patterns, (yyvsp[(1) - (3)].graph_pattern));

#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "UnionGraphPattern\n  graphpattern=");
  rasqal_graph_pattern_print((yyval.graph_pattern), DEBUG_FH);
  fputs("\n\n", DEBUG_FH);
#endif
}
    break;

  case 66:
#line 853 "./sparql_parser.y"
    {
  (yyval.graph_pattern)=(yyvsp[(1) - (1)].graph_pattern);
}
    break;

  case 67:
#line 860 "./sparql_parser.y"
    {
  (yyval.graph_pattern)=(yyvsp[(1) - (3)].graph_pattern);
  if((yyvsp[(3) - (3)].graph_pattern))
    raptor_sequence_push((yyval.graph_pattern)->graph_patterns, (yyvsp[(3) - (3)].graph_pattern));
}
    break;

  case 68:
#line 866 "./sparql_parser.y"
    {
  raptor_sequence *seq;
  seq=raptor_new_sequence((raptor_sequence_free_handler*)rasqal_free_graph_pattern, (raptor_sequence_print_handler*)rasqal_graph_pattern_print);
  if((yyvsp[(1) - (1)].graph_pattern))
    raptor_sequence_push(seq, (yyvsp[(1) - (1)].graph_pattern));
  (yyval.graph_pattern)=rasqal_new_graph_pattern_from_sequence((rasqal_query*)rq,
                                            seq,
                                            RASQAL_GRAPH_PATTERN_OPERATOR_UNION);
}
    break;

  case 69:
#line 880 "./sparql_parser.y"
    {
  (yyval.expr)=(yyvsp[(2) - (2)].expr);
}
    break;

  case 70:
#line 884 "./sparql_parser.y"
    {
  (yyval.expr)=(yyvsp[(2) - (2)].expr);
}
    break;

  case 71:
#line 888 "./sparql_parser.y"
    {
  (yyval.expr)=(yyvsp[(2) - (2)].expr);
}
    break;

  case 72:
#line 896 "./sparql_parser.y"
    {
  raptor_uri* uri=rasqal_literal_as_uri((yyvsp[(1) - (3)].literal));
  
  uri=raptor_uri_copy(uri);

  if(!(yyvsp[(2) - (3)].seq))
    (yyvsp[(2) - (3)].seq)=raptor_new_sequence((raptor_sequence_free_handler*)rasqal_free_expression, (raptor_sequence_print_handler*)rasqal_expression_print);

  if(raptor_sequence_size((yyvsp[(2) - (3)].seq)) == 1 &&
     sparql_is_builtin_xsd_datatype(uri)) {
    rasqal_expression* e=(rasqal_expression*)raptor_sequence_pop((yyvsp[(2) - (3)].seq));
    (yyval.expr)=rasqal_new_cast_expression(uri, e);
    raptor_free_sequence((yyvsp[(2) - (3)].seq));
  } else
    (yyval.expr)=rasqal_new_function_expression(uri, (yyvsp[(2) - (3)].seq));
  rasqal_free_literal((yyvsp[(1) - (3)].literal));
}
    break;

  case 73:
#line 918 "./sparql_parser.y"
    {
  (yyval.seq)=(yyvsp[(1) - (3)].seq);
  if((yyvsp[(3) - (3)].expr))
    raptor_sequence_push((yyval.seq), (yyvsp[(3) - (3)].expr));
}
    break;

  case 74:
#line 924 "./sparql_parser.y"
    {
  (yyval.seq)=raptor_new_sequence((raptor_sequence_free_handler*)rasqal_free_expression, (raptor_sequence_print_handler*)rasqal_expression_print);
  if((yyvsp[(1) - (1)].expr))
    raptor_sequence_push((yyval.seq), (yyvsp[(1) - (1)].expr));
}
    break;

  case 75:
#line 930 "./sparql_parser.y"
    {
  (yyval.seq)=NULL;
}
    break;

  case 76:
#line 938 "./sparql_parser.y"
    {
  (yyval.seq)=(yyvsp[(2) - (3)].seq);
}
    break;

  case 77:
#line 946 "./sparql_parser.y"
    {
  (yyval.seq)=NULL;
 
  if((yyvsp[(1) - (3)].formula)) {
    (yyval.seq)=(yyvsp[(1) - (3)].formula)->triples;
    (yyvsp[(1) - (3)].formula)->triples=NULL;
    rasqal_free_formula((yyvsp[(1) - (3)].formula));
  }
  
  if((yyvsp[(3) - (3)].seq)) {
    if(!(yyval.seq))
      (yyval.seq)=raptor_new_sequence((raptor_sequence_free_handler*)rasqal_free_triple, (raptor_sequence_print_handler*)rasqal_triple_print);

    raptor_sequence_join((yyval.seq), (yyvsp[(3) - (3)].seq));
    raptor_free_sequence((yyvsp[(3) - (3)].seq));
  }

 }
    break;

  case 78:
#line 965 "./sparql_parser.y"
    {
  (yyval.seq)=NULL;
  
  if((yyvsp[(1) - (1)].formula)) {
    (yyval.seq)=(yyvsp[(1) - (1)].formula)->triples;
    (yyvsp[(1) - (1)].formula)->triples=NULL;
    rasqal_free_formula((yyvsp[(1) - (1)].formula));
  }
  
}
    break;

  case 79:
#line 976 "./sparql_parser.y"
    {
  (yyval.seq)=NULL;
}
    break;

  case 80:
#line 984 "./sparql_parser.y"
    {
  int i;

#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "TriplesSameSubject 1\n subject=");
  rasqal_formula_print((yyvsp[(1) - (2)].formula), DEBUG_FH);
  if((yyvsp[(2) - (2)].formula)) {
    fprintf(DEBUG_FH, "\n propertyList=");
    rasqal_formula_print((yyvsp[(2) - (2)].formula), DEBUG_FH);
    fprintf(DEBUG_FH, "\n");
  } else     
    fprintf(DEBUG_FH, "\n and empty propertyList\n");
#endif

  if((yyvsp[(2) - (2)].formula)) {
    raptor_sequence *seq=(yyvsp[(2) - (2)].formula)->triples;
    rasqal_literal *subject=(yyvsp[(1) - (2)].formula)->value;
    
    /* non-empty property list, handle it  */
    for(i=0; i < raptor_sequence_size(seq); i++) {
      rasqal_triple* t2=(rasqal_triple*)raptor_sequence_get_at(seq, i);
      if(t2->subject)
        continue;
      t2->subject=rasqal_new_literal_from_literal(subject);
    }
#if RASQAL_DEBUG > 1  
    fprintf(DEBUG_FH, "  after substitution propertyList=");
    rasqal_formula_print((yyvsp[(2) - (2)].formula), DEBUG_FH);
    fprintf(DEBUG_FH, "\n");
#endif
  }

  (yyval.formula)=rasqal_formula_join((yyvsp[(1) - (2)].formula), (yyvsp[(2) - (2)].formula));
#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "  after joining formula=");
  rasqal_formula_print((yyval.formula), DEBUG_FH);
  fprintf(DEBUG_FH, "\n\n");
#endif
}
    break;

  case 81:
#line 1024 "./sparql_parser.y"
    {
  int i;

#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "TriplesSameSubject 2\n subject=");
  rasqal_formula_print((yyvsp[(1) - (2)].formula), DEBUG_FH);
  if((yyvsp[(2) - (2)].formula)) {
    fprintf(DEBUG_FH, "\n propertyList=");
    rasqal_formula_print((yyvsp[(2) - (2)].formula), DEBUG_FH);
    fprintf(DEBUG_FH, "\n");
  } else     
    fprintf(DEBUG_FH, "\n and empty propertyList\n");
#endif

  if((yyvsp[(2) - (2)].formula)) {
    raptor_sequence *seq=(yyvsp[(2) - (2)].formula)->triples;
    rasqal_literal *subject=(yyvsp[(1) - (2)].formula)->value;
    
    /* non-empty property list, handle it  */
    for(i=0; i < raptor_sequence_size(seq); i++) {
      rasqal_triple* t2=(rasqal_triple*)raptor_sequence_get_at(seq, i);
      if(t2->subject)
        continue;
      t2->subject=rasqal_new_literal_from_literal(subject);
    }
#if RASQAL_DEBUG > 1  
    fprintf(DEBUG_FH, "  after substitution propertyList=");
    rasqal_formula_print((yyvsp[(2) - (2)].formula), DEBUG_FH);
    fprintf(DEBUG_FH, "\n");
#endif
  }

  (yyval.formula)=rasqal_formula_join((yyvsp[(1) - (2)].formula), (yyvsp[(2) - (2)].formula));
#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "  after joining formula=");
  rasqal_formula_print((yyval.formula), DEBUG_FH);
  fprintf(DEBUG_FH, "\n\n");
#endif
}
    break;

  case 82:
#line 1068 "./sparql_parser.y"
    {
  (yyval.formula)=(yyvsp[(1) - (1)].formula);
}
    break;

  case 83:
#line 1072 "./sparql_parser.y"
    {
  (yyval.formula)=NULL;
}
    break;

  case 84:
#line 1080 "./sparql_parser.y"
    {
  int i;
  
#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "PropertyList 1\n Verb=");
  rasqal_formula_print((yyvsp[(1) - (3)].formula), DEBUG_FH);
  fprintf(DEBUG_FH, "\n ObjectList=");
  rasqal_formula_print((yyvsp[(2) - (3)].formula), DEBUG_FH);
  fprintf(DEBUG_FH, "\n PropertyListTail=");
  if((yyvsp[(3) - (3)].formula) != NULL)
    rasqal_formula_print((yyvsp[(3) - (3)].formula), DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fprintf(DEBUG_FH, "\n");
#endif
  
  if((yyvsp[(2) - (3)].formula) == NULL) {
#if RASQAL_DEBUG > 1  
    fprintf(DEBUG_FH, " empty ObjectList not processed\n");
#endif
  } else if((yyvsp[(1) - (3)].formula) && (yyvsp[(2) - (3)].formula)) {
    raptor_sequence *seq=(yyvsp[(2) - (3)].formula)->triples;
    rasqal_literal *predicate=(yyvsp[(1) - (3)].formula)->value;
    rasqal_formula *formula;

    /* non-empty property list, handle it  */
    for(i=0; i<raptor_sequence_size(seq); i++) {
      rasqal_triple* t2=(rasqal_triple*)raptor_sequence_get_at(seq, i);
      if(!t2->predicate)
        t2->predicate=(rasqal_literal*)rasqal_new_literal_from_literal(predicate);
    }
  
#if RASQAL_DEBUG > 1  
    fprintf(DEBUG_FH, "  after substitution ObjectList=");
    raptor_sequence_print(seq, DEBUG_FH);
    fprintf(DEBUG_FH, "\n");
#endif

    formula=rasqal_new_formula();
    formula->triples=raptor_new_sequence((raptor_sequence_free_handler*)rasqal_free_triple, (raptor_sequence_print_handler*)rasqal_triple_print);

    for(i=0; i < raptor_sequence_size(seq); i++) {
      rasqal_triple* t2=(rasqal_triple*)raptor_sequence_get_at(seq, i);
      raptor_sequence_push(formula->triples, t2);
    }

    while(raptor_sequence_size(seq))
      raptor_sequence_pop(seq);

    (yyvsp[(3) - (3)].formula)=rasqal_formula_join(formula, (yyvsp[(3) - (3)].formula));

#if RASQAL_DEBUG > 1  
    fprintf(DEBUG_FH, "  after appending ObjectList=");
    rasqal_formula_print((yyvsp[(3) - (3)].formula), DEBUG_FH);
    fprintf(DEBUG_FH, "\n\n");
#endif

    rasqal_free_formula((yyvsp[(2) - (3)].formula));
  }

  if((yyvsp[(1) - (3)].formula))
    rasqal_free_formula((yyvsp[(1) - (3)].formula));

  (yyval.formula)=(yyvsp[(3) - (3)].formula);
}
    break;

  case 85:
#line 1150 "./sparql_parser.y"
    {
  (yyval.formula)=(yyvsp[(2) - (2)].formula);
}
    break;

  case 86:
#line 1154 "./sparql_parser.y"
    {
  (yyval.formula)=NULL;
}
    break;

  case 87:
#line 1162 "./sparql_parser.y"
    {
  rasqal_formula *formula=NULL;
  rasqal_triple *triple;

#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "ObjectList 1\n");
  fprintf(DEBUG_FH, " GraphNode=\n");
  rasqal_formula_print((yyvsp[(1) - (2)].formula), DEBUG_FH);
  fprintf(DEBUG_FH, "\n");
  if((yyvsp[(2) - (2)].formula)) {
    fprintf(DEBUG_FH, " ObjectTail=");
    rasqal_formula_print((yyvsp[(2) - (2)].formula), DEBUG_FH);
    fprintf(DEBUG_FH, "\n");
  } else
    fprintf(DEBUG_FH, " and empty ObjectTail\n");
#endif

  formula=rasqal_new_formula();
  
  triple=rasqal_new_triple(NULL, NULL, (yyvsp[(1) - (2)].formula)->value);
  (yyvsp[(1) - (2)].formula)->value=NULL;

  formula->triples=raptor_new_sequence((raptor_sequence_free_handler*)rasqal_free_triple, (raptor_sequence_print_handler*)rasqal_triple_print);

  raptor_sequence_push(formula->triples, triple);

  (yyval.formula)=rasqal_formula_join(formula, (yyvsp[(1) - (2)].formula));
  (yyval.formula)=rasqal_formula_join(formula, (yyvsp[(2) - (2)].formula));

#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, " objectList is now ");
  if((yyval.formula))
    raptor_sequence_print((yyval.formula)->triples, DEBUG_FH);
  else
    fputs("NULL", DEBUG_FH);
  fprintf(DEBUG_FH, "\n\n");
#endif
}
    break;

  case 88:
#line 1205 "./sparql_parser.y"
    {
  (yyval.formula)=(yyvsp[(2) - (2)].formula);
}
    break;

  case 89:
#line 1209 "./sparql_parser.y"
    {
  (yyval.formula)=NULL;
}
    break;

  case 90:
#line 1217 "./sparql_parser.y"
    {
  (yyval.formula)=rasqal_new_formula();
  (yyval.formula)->value=(yyvsp[(1) - (1)].literal);
}
    break;

  case 91:
#line 1222 "./sparql_parser.y"
    {
  raptor_uri *uri;

#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "verb Verb=rdf:type (a)\n");
#endif

  uri=raptor_new_uri_for_rdf_concept("type");
  (yyval.formula)=rasqal_new_formula();
  (yyval.formula)->value=rasqal_new_uri_literal(uri);
}
    break;

  case 92:
#line 1238 "./sparql_parser.y"
    {
  (yyval.formula)=(yyvsp[(1) - (1)].formula);
}
    break;

  case 93:
#line 1242 "./sparql_parser.y"
    {
  (yyval.formula)=(yyvsp[(1) - (1)].formula);
}
    break;

  case 94:
#line 1250 "./sparql_parser.y"
    {
  int i;
  const unsigned char *id=rasqal_query_generate_bnodeid((rasqal_query*)rq, NULL);
  
  if((yyvsp[(2) - (3)].formula) == NULL)
    (yyval.formula)=rasqal_new_formula();
  else {
    (yyval.formula)=(yyvsp[(2) - (3)].formula);
    if((yyval.formula)->value)
      rasqal_free_literal((yyval.formula)->value);
  }
  
  (yyval.formula)->value=rasqal_new_simple_literal(RASQAL_LITERAL_BLANK, id);

  if((yyvsp[(2) - (3)].formula) == NULL) {
#if RASQAL_DEBUG > 1  
    fprintf(DEBUG_FH, "TriplesNode\n PropertyList=");
    rasqal_formula_print((yyval.formula), DEBUG_FH);
    fprintf(DEBUG_FH, "\n");
#endif
  } else {
    raptor_sequence *seq=(yyvsp[(2) - (3)].formula)->triples;

    /* non-empty property list, handle it  */
#if RASQAL_DEBUG > 1  
    fprintf(DEBUG_FH, "TriplesNode\n PropertyList=");
    raptor_sequence_print(seq, DEBUG_FH);
    fprintf(DEBUG_FH, "\n");
#endif

    for(i=0; i<raptor_sequence_size(seq); i++) {
      rasqal_triple* t2=(rasqal_triple*)raptor_sequence_get_at(seq, i);
      if(t2->subject)
        continue;
      
      t2->subject=(rasqal_literal*)rasqal_new_literal_from_literal((yyval.formula)->value);
    }

#if RASQAL_DEBUG > 1
    fprintf(DEBUG_FH, "  after substitution formula=");
    rasqal_formula_print((yyval.formula), DEBUG_FH);
    fprintf(DEBUG_FH, "\n\n");
#endif
  }
  
}
    break;

  case 95:
#line 1301 "./sparql_parser.y"
    {
  int i;
  rasqal_query* rdf_query=(rasqal_query*)rq;
  rasqal_literal* first_identifier;
  rasqal_literal* rest_identifier;
  rasqal_literal* object;

#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "Collection\n GraphNodeListNotEmpty=");
  raptor_sequence_print((yyvsp[(2) - (3)].seq), DEBUG_FH);
  fprintf(DEBUG_FH, "\n");
#endif

  first_identifier=rasqal_new_uri_literal(raptor_uri_copy(rasqal_rdf_first_uri));
  rest_identifier=rasqal_new_uri_literal(raptor_uri_copy(rasqal_rdf_rest_uri));
  
  object=rasqal_new_uri_literal(raptor_uri_copy(rasqal_rdf_nil_uri));

  (yyval.formula)=rasqal_new_formula();
  (yyval.formula)->triples=raptor_new_sequence((raptor_sequence_free_handler*)rasqal_free_triple, (raptor_sequence_print_handler*)rasqal_triple_print);

  for(i=raptor_sequence_size((yyvsp[(2) - (3)].seq))-1; i>=0; i--) {
    rasqal_formula* f=(rasqal_formula*)raptor_sequence_get_at((yyvsp[(2) - (3)].seq), i);
    const unsigned char *blank_id=rasqal_query_generate_bnodeid(rdf_query, NULL);
    rasqal_literal* blank=rasqal_new_simple_literal(RASQAL_LITERAL_BLANK, blank_id);
    rasqal_triple *t2;

    /* Move existing formula triples */
    if(f->triples)
      raptor_sequence_join((yyval.formula)->triples, f->triples);

    /* add new triples we needed */
    t2=rasqal_new_triple(rasqal_new_literal_from_literal(blank),
                         rasqal_new_literal_from_literal(first_identifier),
                         rasqal_new_literal_from_literal(f->value));
    raptor_sequence_push((yyval.formula)->triples, t2);

    t2=rasqal_new_triple(rasqal_new_literal_from_literal(blank),
                         rasqal_new_literal_from_literal(rest_identifier),
                         rasqal_new_literal_from_literal(object));
    raptor_sequence_push((yyval.formula)->triples, t2);

    rasqal_free_literal(object);

    object=blank;
  }

  (yyval.formula)->value=object;
  
#if RASQAL_DEBUG > 1
  fprintf(DEBUG_FH, "  after substitution collection=");
  rasqal_formula_print((yyval.formula), DEBUG_FH);
  fprintf(DEBUG_FH, "\n\n");
#endif

  rasqal_free_literal(first_identifier);
  rasqal_free_literal(rest_identifier);
}
    break;

  case 96:
#line 1365 "./sparql_parser.y"
    {
#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "GraphNodeListNotEmpty 1\n");
  if((yyvsp[(2) - (2)].formula)) {
    fprintf(DEBUG_FH, " GraphNode=");
    rasqal_formula_print((yyvsp[(2) - (2)].formula), DEBUG_FH);
    fprintf(DEBUG_FH, "\n");
  } else  
    fprintf(DEBUG_FH, " and empty GraphNode\n");
  if((yyvsp[(1) - (2)].seq)) {
    fprintf(DEBUG_FH, " GraphNodeListNotEmpty=");
    raptor_sequence_print((yyvsp[(1) - (2)].seq), DEBUG_FH);
    fprintf(DEBUG_FH, "\n");
  } else
    fprintf(DEBUG_FH, " and empty GraphNodeListNotEmpty\n");
#endif

  if(!(yyvsp[(2) - (2)].formula))
    (yyval.seq)=NULL;
  else {
    raptor_sequence_push((yyval.seq), (yyvsp[(2) - (2)].formula));
#if RASQAL_DEBUG > 1  
    fprintf(DEBUG_FH, " itemList is now ");
    raptor_sequence_print((yyval.seq), DEBUG_FH);
    fprintf(DEBUG_FH, "\n\n");
#endif
  }

}
    break;

  case 97:
#line 1395 "./sparql_parser.y"
    {
#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, "GraphNodeListNotEmpty 2\n");
  if((yyvsp[(1) - (1)].formula)) {
    fprintf(DEBUG_FH, " GraphNode=");
    rasqal_formula_print((yyvsp[(1) - (1)].formula), DEBUG_FH);
    fprintf(DEBUG_FH, "\n");
  } else  
    fprintf(DEBUG_FH, " and empty GraphNode\n");
#endif

  (yyval.seq)=NULL;
  if((yyvsp[(1) - (1)].formula))
    (yyval.seq)=raptor_new_sequence((raptor_sequence_free_handler*)rasqal_free_formula, (raptor_sequence_print_handler*)rasqal_formula_print);

  raptor_sequence_push((yyval.seq), (yyvsp[(1) - (1)].formula));
#if RASQAL_DEBUG > 1  
  fprintf(DEBUG_FH, " GraphNodeListNotEmpty is now ");
  raptor_sequence_print((yyval.seq), DEBUG_FH);
  fprintf(DEBUG_FH, "\n\n");
#endif
}
    break;

  case 98:
#line 1422 "./sparql_parser.y"
    {
  (yyval.formula)=(yyvsp[(1) - (1)].formula);
}
    break;

  case 99:
#line 1426 "./sparql_parser.y"
    {
  (yyval.formula)=(yyvsp[(1) - (1)].formula);
}
    break;

  case 100:
#line 1434 "./sparql_parser.y"
    {
  (yyval.formula)=rasqal_new_formula();
  (yyval.formula)->value=rasqal_new_variable_literal((yyvsp[(1) - (1)].variable));
}
    break;

  case 101:
#line 1439 "./sparql_parser.y"
    {
  (yyval.formula)=rasqal_new_formula();
  (yyval.formula)->value=(yyvsp[(1) - (1)].literal);
}
    break;

  case 102:
#line 1447 "./sparql_parser.y"
    {
  (yyval.literal)=rasqal_new_variable_literal((yyvsp[(1) - (1)].variable));
}
    break;

  case 103:
#line 1451 "./sparql_parser.y"
    {
  (yyval.literal)=(yyvsp[(1) - (1)].literal);
}
    break;

  case 104:
#line 1459 "./sparql_parser.y"
    {
  (yyval.literal)=rasqal_new_variable_literal((yyvsp[(1) - (1)].variable));
}
    break;

  case 105:
#line 1463 "./sparql_parser.y"
    {
  (yyval.literal)=(yyvsp[(1) - (1)].literal);
}
    break;

  case 106:
#line 1467 "./sparql_parser.y"
    {
  (yyval.literal)=(yyvsp[(1) - (1)].literal);
}
    break;

  case 107:
#line 1474 "./sparql_parser.y"
    {
  (yyval.variable)=rasqal_new_variable((rasqal_query*)rq, (yyvsp[(2) - (2)].name), NULL);
}
    break;

  case 108:
#line 1478 "./sparql_parser.y"
    {
  (yyval.variable)=rasqal_new_variable((rasqal_query*)rq, (yyvsp[(2) - (2)].name), NULL);
}
    break;

  case 109:
#line 1487 "./sparql_parser.y"
    {
  (yyval.literal)=(yyvsp[(1) - (1)].literal);
}
    break;

  case 110:
#line 1491 "./sparql_parser.y"
    {
  (yyval.literal)=(yyvsp[(1) - (1)].literal);
}
    break;

  case 111:
#line 1495 "./sparql_parser.y"
    {
  (yyval.literal)=(yyvsp[(1) - (1)].literal);
}
    break;

  case 112:
#line 1499 "./sparql_parser.y"
    {
  (yyval.literal)=(yyvsp[(1) - (1)].literal);
}
    break;

  case 113:
#line 1503 "./sparql_parser.y"
    {
  (yyval.literal)=(yyvsp[(1) - (1)].literal);
}
    break;

  case 114:
#line 1507 "./sparql_parser.y"
    {
  (yyval.literal)=(yyvsp[(1) - (1)].literal);
}
    break;

  case 115:
#line 1511 "./sparql_parser.y"
    {
  (yyval.literal)=(yyvsp[(1) - (1)].literal);
}
    break;

  case 116:
#line 1515 "./sparql_parser.y"
    {
  (yyval.literal)=rasqal_new_uri_literal(raptor_uri_copy(rasqal_rdf_nil_uri));
}
    break;

  case 117:
#line 1522 "./sparql_parser.y"
    {
  (yyval.expr)=(yyvsp[(1) - (1)].expr);
}
    break;

  case 118:
#line 1530 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_2op_expression(RASQAL_EXPR_OR, (yyvsp[(1) - (3)].expr), (yyvsp[(3) - (3)].expr));
}
    break;

  case 119:
#line 1534 "./sparql_parser.y"
    {
  (yyval.expr)=(yyvsp[(1) - (1)].expr);
}
    break;

  case 120:
#line 1542 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_2op_expression(RASQAL_EXPR_AND, (yyvsp[(1) - (3)].expr), (yyvsp[(3) - (3)].expr));
;
}
    break;

  case 121:
#line 1547 "./sparql_parser.y"
    {
  (yyval.expr)=(yyvsp[(1) - (1)].expr);
}
    break;

  case 122:
#line 1556 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_2op_expression(RASQAL_EXPR_EQ, (yyvsp[(1) - (3)].expr), (yyvsp[(3) - (3)].expr));
}
    break;

  case 123:
#line 1560 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_2op_expression(RASQAL_EXPR_NEQ, (yyvsp[(1) - (3)].expr), (yyvsp[(3) - (3)].expr));
}
    break;

  case 124:
#line 1564 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_2op_expression(RASQAL_EXPR_LT, (yyvsp[(1) - (3)].expr), (yyvsp[(3) - (3)].expr));
}
    break;

  case 125:
#line 1568 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_2op_expression(RASQAL_EXPR_GT, (yyvsp[(1) - (3)].expr), (yyvsp[(3) - (3)].expr));
}
    break;

  case 126:
#line 1572 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_2op_expression(RASQAL_EXPR_LE, (yyvsp[(1) - (3)].expr), (yyvsp[(3) - (3)].expr));
}
    break;

  case 127:
#line 1576 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_2op_expression(RASQAL_EXPR_GE, (yyvsp[(1) - (3)].expr), (yyvsp[(3) - (3)].expr));
}
    break;

  case 128:
#line 1580 "./sparql_parser.y"
    {
  (yyval.expr)=(yyvsp[(1) - (1)].expr);
}
    break;

  case 129:
#line 1589 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_2op_expression(RASQAL_EXPR_PLUS, (yyvsp[(1) - (3)].expr), (yyvsp[(3) - (3)].expr));
}
    break;

  case 130:
#line 1593 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_2op_expression(RASQAL_EXPR_MINUS, (yyvsp[(1) - (3)].expr), (yyvsp[(3) - (3)].expr));
}
    break;

  case 131:
#line 1597 "./sparql_parser.y"
    {
  (yyval.expr)=(yyvsp[(1) - (1)].expr);
}
    break;

  case 132:
#line 1604 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_2op_expression(RASQAL_EXPR_STAR, (yyvsp[(1) - (3)].expr), (yyvsp[(3) - (3)].expr));
}
    break;

  case 133:
#line 1608 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_2op_expression(RASQAL_EXPR_SLASH, (yyvsp[(1) - (3)].expr), (yyvsp[(3) - (3)].expr));
}
    break;

  case 134:
#line 1612 "./sparql_parser.y"
    {
  (yyval.expr)=(yyvsp[(1) - (1)].expr);
}
    break;

  case 135:
#line 1620 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_1op_expression(RASQAL_EXPR_BANG, (yyvsp[(2) - (2)].expr));
}
    break;

  case 136:
#line 1624 "./sparql_parser.y"
    {
  (yyval.expr)=(yyvsp[(2) - (2)].expr);
}
    break;

  case 137:
#line 1628 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_1op_expression(RASQAL_EXPR_UMINUS, (yyvsp[(2) - (2)].expr));
}
    break;

  case 138:
#line 1632 "./sparql_parser.y"
    {
  (yyval.expr)=(yyvsp[(1) - (1)].expr);
}
    break;

  case 139:
#line 1646 "./sparql_parser.y"
    {
  (yyval.expr)=(yyvsp[(1) - (1)].expr);
}
    break;

  case 140:
#line 1650 "./sparql_parser.y"
    {
  (yyval.expr)=(yyvsp[(1) - (1)].expr);
}
    break;

  case 141:
#line 1654 "./sparql_parser.y"
    {
  /* Grammar has IRIrefOrFunction here which is "IRIref ArgList?"
   * and essentially shorthand for FunctionCall | IRIref.  The Rasqal
   * SPARQL lexer distinguishes these for us with IRIrefBrace.
   * IRIref is covered below by GraphTerm.
   */
  (yyval.expr)=(yyvsp[(1) - (1)].expr);
}
    break;

  case 142:
#line 1663 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_literal_expression((yyvsp[(1) - (1)].literal));
}
    break;

  case 143:
#line 1667 "./sparql_parser.y"
    {
  rasqal_literal *l=rasqal_new_variable_literal((yyvsp[(1) - (1)].variable));
  (yyval.expr)=rasqal_new_literal_expression(l);
}
    break;

  case 144:
#line 1676 "./sparql_parser.y"
    {
  (yyval.expr)=(yyvsp[(2) - (3)].expr);
}
    break;

  case 145:
#line 1684 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_1op_expression(RASQAL_EXPR_STR, (yyvsp[(3) - (4)].expr));
}
    break;

  case 146:
#line 1688 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_1op_expression(RASQAL_EXPR_LANG, (yyvsp[(3) - (4)].expr));
}
    break;

  case 147:
#line 1692 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_2op_expression(RASQAL_EXPR_LANGMATCHES, (yyvsp[(3) - (6)].expr), (yyvsp[(5) - (6)].expr));
}
    break;

  case 148:
#line 1696 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_1op_expression(RASQAL_EXPR_DATATYPE, (yyvsp[(3) - (4)].expr));
}
    break;

  case 149:
#line 1700 "./sparql_parser.y"
    {
  rasqal_literal *l=rasqal_new_variable_literal((yyvsp[(3) - (4)].variable));
  rasqal_expression *e=rasqal_new_literal_expression(l);
  (yyval.expr)=rasqal_new_1op_expression(RASQAL_EXPR_BOUND, e);
}
    break;

  case 150:
#line 1706 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_1op_expression(RASQAL_EXPR_ISURI, (yyvsp[(3) - (4)].expr));
}
    break;

  case 151:
#line 1710 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_1op_expression(RASQAL_EXPR_ISBLANK, (yyvsp[(3) - (4)].expr));
}
    break;

  case 152:
#line 1714 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_1op_expression(RASQAL_EXPR_ISLITERAL, (yyvsp[(3) - (4)].expr));
}
    break;

  case 153:
#line 1718 "./sparql_parser.y"
    {
  (yyval.expr)=(yyvsp[(1) - (1)].expr);
}
    break;

  case 154:
#line 1726 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_3op_expression(RASQAL_EXPR_REGEX, (yyvsp[(3) - (6)].expr), (yyvsp[(5) - (6)].expr), NULL);
}
    break;

  case 155:
#line 1730 "./sparql_parser.y"
    {
  (yyval.expr)=rasqal_new_3op_expression(RASQAL_EXPR_REGEX, (yyvsp[(3) - (8)].expr), (yyvsp[(5) - (8)].expr), (yyvsp[(7) - (8)].expr));
}
    break;

  case 156:
#line 1741 "./sparql_parser.y"
    {
  (yyval.literal)=rasqal_new_uri_literal((yyvsp[(1) - (1)].uri));
}
    break;

  case 157:
#line 1745 "./sparql_parser.y"
    {
  (yyval.literal)=rasqal_new_simple_literal(RASQAL_LITERAL_QNAME, (yyvsp[(1) - (1)].name));
  if(rasqal_literal_expand_qname((rasqal_query*)rq, (yyval.literal))) {
    sparql_query_error_full((rasqal_query*)rq,
                            "QName %s cannot be expanded", (yyvsp[(1) - (1)].name));
    rasqal_free_literal((yyval.literal));
    (yyval.literal)=NULL;
  }
}
    break;

  case 158:
#line 1767 "./sparql_parser.y"
    {
  (yyval.literal)=rasqal_new_uri_literal((yyvsp[(1) - (1)].uri));
}
    break;

  case 159:
#line 1771 "./sparql_parser.y"
    {
  (yyval.literal)=rasqal_new_simple_literal(RASQAL_LITERAL_QNAME, (yyvsp[(1) - (1)].name));
  if(rasqal_literal_expand_qname((rasqal_query*)rq, (yyval.literal))) {
    sparql_query_error_full((rasqal_query*)rq,
                            "QName %s cannot be expanded", (yyvsp[(1) - (1)].name));
    rasqal_free_literal((yyval.literal));
    (yyval.literal)=NULL;
  }
}
    break;

  case 160:
#line 1787 "./sparql_parser.y"
    {
  (yyval.literal)=rasqal_new_simple_literal(RASQAL_LITERAL_BLANK, (yyvsp[(1) - (1)].name));
}
    break;

  case 161:
#line 1790 "./sparql_parser.y"
    {
  const unsigned char *id=rasqal_query_generate_bnodeid((rasqal_query*)rq, NULL);
  (yyval.literal)=rasqal_new_simple_literal(RASQAL_LITERAL_BLANK, id);
}
    break;


/* Line 1267 of yacc.c.  */
#line 3585 "sparql_parser.c"
      default: break;
    }
  YY_SYMBOL_PRINT ("-> $$ =", yyr1[yyn], &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);

  *++yyvsp = yyval;


  /* Now `shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */

  yyn = yyr1[yyn];

  yystate = yypgoto[yyn - YYNTOKENS] + *yyssp;
  if (0 <= yystate && yystate <= YYLAST && yycheck[yystate] == *yyssp)
    yystate = yytable[yystate];
  else
    yystate = yydefgoto[yyn - YYNTOKENS];

  goto yynewstate;


/*------------------------------------.
| yyerrlab -- here on detecting error |
`------------------------------------*/
yyerrlab:
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
#if ! YYERROR_VERBOSE
      yyerror (YY_("syntax error"));
#else
      {
	YYSIZE_T yysize = yysyntax_error (0, yystate, yychar);
	if (yymsg_alloc < yysize && yymsg_alloc < YYSTACK_ALLOC_MAXIMUM)
	  {
	    YYSIZE_T yyalloc = 2 * yysize;
	    if (! (yysize <= yyalloc && yyalloc <= YYSTACK_ALLOC_MAXIMUM))
	      yyalloc = YYSTACK_ALLOC_MAXIMUM;
	    if (yymsg != yymsgbuf)
	      YYSTACK_FREE (yymsg);
	    yymsg = (char *) YYSTACK_ALLOC (yyalloc);
	    if (yymsg)
	      yymsg_alloc = yyalloc;
	    else
	      {
		yymsg = yymsgbuf;
		yymsg_alloc = sizeof yymsgbuf;
	      }
	  }

	if (0 < yysize && yysize <= yymsg_alloc)
	  {
	    (void) yysyntax_error (yymsg, yystate, yychar);
	    yyerror (yymsg);
	  }
	else
	  {
	    yyerror (YY_("syntax error"));
	    if (yysize != 0)
	      goto yyexhaustedlab;
	  }
      }
#endif
    }



  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse look-ahead token after an
	 error, discard it.  */

      if (yychar <= YYEOF)
	{
	  /* Return failure if at end of input.  */
	  if (yychar == YYEOF)
	    YYABORT;
	}
      else
	{
	  yydestruct ("Error: discarding",
		      yytoken, &yylval);
	  yychar = YYEMPTY;
	}
    }

  /* Else will try to reuse look-ahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:

  /* Pacify compilers like GCC when the user code never invokes
     YYERROR and the label yyerrorlab therefore never appears in user
     code.  */
  if (/*CONSTCOND*/ 0)
     goto yyerrorlab;

  /* Do not reclaim the symbols of the rule which action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;	/* Each real token shifted decrements this.  */

  for (;;)
    {
      yyn = yypact[yystate];
      if (yyn != YYPACT_NINF)
	{
	  yyn += YYTERROR;
	  if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYTERROR)
	    {
	      yyn = yytable[yyn];
	      if (0 < yyn)
		break;
	    }
	}

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
	YYABORT;


      yydestruct ("Error: popping",
		  yystos[yystate], yyvsp);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  if (yyn == YYFINAL)
    YYACCEPT;

  *++yyvsp = yylval;


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", yystos[yyn], yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturn;

/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturn;

#ifndef yyoverflow
/*-------------------------------------------------.
| yyexhaustedlab -- memory exhaustion comes here.  |
`-------------------------------------------------*/
yyexhaustedlab:
  yyerror (YY_("memory exhausted"));
  yyresult = 2;
  /* Fall through.  */
#endif

yyreturn:
  if (yychar != YYEOF && yychar != YYEMPTY)
     yydestruct ("Cleanup: discarding lookahead",
		 yytoken, &yylval);
  /* Do not reclaim the symbols of the rule which action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
		  yystos[*yyssp], yyvsp);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
#if YYERROR_VERBOSE
  if (yymsg != yymsgbuf)
    YYSTACK_FREE (yymsg);
#endif
  /* Make sure YYID is used.  */
  return YYID (yyresult);
}


#line 1803 "./sparql_parser.y"



/* Support functions */


/* This is declared in sparql_lexer.h but never used, so we always get
 * a warning unless this dummy code is here.  Used once below in an error case.
 */
static int yy_init_globals (yyscan_t yyscanner ) { return 0; };


static int
sparql_is_builtin_xsd_datatype(raptor_uri* uri) 
{
  return (raptor_uri_equals(uri, rasqal_xsd_boolean_uri) ||
          raptor_uri_equals(uri, rasqal_xsd_string_uri) ||
          raptor_uri_equals(uri, rasqal_xsd_double_uri) ||
          raptor_uri_equals(uri, rasqal_xsd_float_uri) ||
          raptor_uri_equals(uri, rasqal_xsd_decimal_uri) ||
          raptor_uri_equals(uri, rasqal_xsd_integer_uri) ||
          raptor_uri_equals(uri, rasqal_xsd_datetime_uri)
          );
}


/**
 * rasqal_sparql_query_engine_init - Initialise the SPARQL query engine
 *
 * Return value: non 0 on failure
 **/
static int
rasqal_sparql_query_engine_init(rasqal_query* rdf_query, const char *name) {
  /* rasqal_sparql_query_engine* sparql=(rasqal_sparql_query_engine*)rdf_query->context; */

  rdf_query->compare_flags = RASQAL_COMPARE_XQUERY;
  return 0;
}


/**
 * rasqal_sparql_query_engine_terminate - Free the SPARQL query engine
 *
 * Return value: non 0 on failure
 **/
static void
rasqal_sparql_query_engine_terminate(rasqal_query* rdf_query) {
  rasqal_sparql_query_engine* sparql=(rasqal_sparql_query_engine*)rdf_query->context;

  if(sparql->scanner_set) {
    sparql_lexer_lex_destroy(sparql->scanner);
    sparql->scanner_set=0;
  }

}


static int
rasqal_sparql_query_engine_prepare(rasqal_query* rdf_query) {
  /* rasqal_sparql_query_engine* sparql=(rasqal_sparql_query_engine*)rdf_query->context; */
  int rc;
  
  if(!rdf_query->query_string)
    return 1;
  
  rc=sparql_parse(rdf_query, rdf_query->query_string);
  if(rc)
    return rc;

  /* FIXME - should check remaining query parts  */
  if(rasqal_engine_sequence_has_qname(rdf_query->triples) ||
     rasqal_engine_sequence_has_qname(rdf_query->constructs) ||
     rasqal_engine_query_constraints_has_qname(rdf_query)) {
    sparql_query_error(rdf_query, "SPARQL query has unexpanded QNames");
    return 1;
  }

  return rasqal_engine_prepare(rdf_query);
}


static int
rasqal_sparql_query_engine_execute(rasqal_query* rdf_query,
                                   rasqal_query_results *results) 
{
  /* rasqal_sparql_query_engine* sparql=(rasqal_sparql_query_engine*)rdf_query->context; */
  
  /* nothing needed here */
  return 0;
}


static int
sparql_parse(rasqal_query* rq, const unsigned char *string) {
  rasqal_sparql_query_engine* rqe=(rasqal_sparql_query_engine*)rq->context;
  raptor_locator *locator=&rq->locator;
  char *buf=NULL;
  size_t len;
  void *buffer;

  if(!string || !*string)
    return yy_init_globals(NULL); /* 0 but a way to use yy_init_globals */

  locator->line=1;
  locator->column= -1; /* No column info */
  locator->byte= -1; /* No bytes info */

#if RASQAL_DEBUG > 2
  sparql_parser_debug=1;
#endif

  rqe->lineno=1;

  sparql_lexer_lex_init(&rqe->scanner);
  rqe->scanner_set=1;

  sparql_lexer_set_extra(((rasqal_query*)rq), rqe->scanner);

  /* This
   *   buffer= sparql_lexer__scan_string((const char*)string, rqe->scanner);
   * is replaced by the code below.  
   * 
   * The extra space appended to the buffer is the least-pain
   * workaround to the lexer crashing by reading EOF twice in
   * sparql_copy_regex_token; at least as far as I can diagnose.  The
   * fix here costs little to add as the above function does
   * something very similar to this anyway.
   */
  len= strlen((const char*)string);
  buf= (char *)RASQAL_MALLOC(cstring, len+3);
  strncpy(buf, (const char*)string, len);
  buf[len]= ' ';
  buf[len+1]= buf[len+2]='\0'; /* YY_END_OF_BUFFER_CHAR; */
  buffer= sparql_lexer__scan_buffer(buf, len+3, rqe->scanner);

  sparql_parser_parse(rq);

  if(buf)
    RASQAL_FREE(cstring, buf);

  sparql_lexer_lex_destroy(rqe->scanner);
  rqe->scanner_set=0;

  /* Parsing failed */
  if(rq->failed)
    return 1;
  
  return 0;
}


static void
sparql_query_error(rasqal_query *rq, const char *msg) {
  rasqal_sparql_query_engine* rqe=(rasqal_sparql_query_engine*)rq->context;

  rq->locator.line=rqe->lineno;
#ifdef RASQAL_SPARQL_USE_ERROR_COLUMNS
  /*  rq->locator.column=sparql_lexer_get_column(yyscanner);*/
#endif

  rasqal_query_error(rq, "%s", msg);
}


static void
sparql_query_error_full(rasqal_query *rq, const char *message, ...) {
  va_list arguments;
  rasqal_sparql_query_engine* rqe=(rasqal_sparql_query_engine*)rq->context;

  rq->locator.line=rqe->lineno;
#ifdef RASQAL_SPARQL_USE_ERROR_COLUMNS
  /*  rq->locator.column=sparql_lexer_get_column(yyscanner);*/
#endif

  va_start(arguments, message);

  rasqal_query_error_varargs(rq, message, arguments);

  va_end(arguments);
}


int
sparql_syntax_error(rasqal_query *rq, const char *message, ...)
{
  rasqal_sparql_query_engine *rqe=(rasqal_sparql_query_engine*)rq->context;
  va_list arguments;

  rq->locator.line=rqe->lineno;
#ifdef RASQAL_SPARQL_USE_ERROR_COLUMNS
  /*  rp->locator.column=sparql_lexer_get_column(yyscanner);*/
#endif

  va_start(arguments, message);
  rasqal_query_error_varargs(rq, message, arguments);
  va_end(arguments);

   return (0);
}


int
sparql_syntax_warning(rasqal_query *rq, const char *message, ...)
{
  rasqal_sparql_query_engine *rqe=(rasqal_sparql_query_engine*)rq->context;
  va_list arguments;

  rq->locator.line=rqe->lineno;
#ifdef RASQAL_SPARQL_USE_ERROR_COLUMNS
  /*  rq->locator.column=sparql_lexer_get_column(yyscanner);*/
#endif

  va_start(arguments, message);
  rasqal_query_warning_varargs(rq, message, arguments);
  va_end(arguments);

   return (0);
}


static int
rasqal_sparql_query_engine_iostream_write_escaped_counted_string(rasqal_query* query,
                                                                 raptor_iostream* iostr,
                                                                 const unsigned char* string,
                                                                 size_t len)
{
  const char delim='"';
  
  raptor_iostream_write_byte(iostr, delim);
  if(raptor_iostream_write_string_ntriples(iostr, string, len, delim))
    return 1;
  
  raptor_iostream_write_byte(iostr, delim);

  return 0;
}


static void
rasqal_sparql_query_engine_register_factory(rasqal_query_engine_factory *factory)
{
  factory->context_length = sizeof(rasqal_sparql_query_engine);

  factory->init      = rasqal_sparql_query_engine_init;
  factory->terminate = rasqal_sparql_query_engine_terminate;
  factory->prepare   = rasqal_sparql_query_engine_prepare;
  factory->execute   = rasqal_sparql_query_engine_execute;
  factory->iostream_write_escaped_counted_string = rasqal_sparql_query_engine_iostream_write_escaped_counted_string;
}


void
rasqal_init_query_engine_sparql(void) {
  rasqal_query_engine_register_factory("sparql", 
                                       "SPARQL W3C DAWG RDF Query Language",
                                       NULL,
                                       (const unsigned char*)"http://www.w3.org/TR/rdf-sparql-query/",
                                       &rasqal_sparql_query_engine_register_factory);
}



#ifdef STANDALONE
#include <stdio.h>
#include <locale.h>

#define SPARQL_FILE_BUF_SIZE 2048

int
main(int argc, char *argv[]) 
{
  const char *program=rasqal_basename(argv[0]);
  char query_string[SPARQL_FILE_BUF_SIZE];
  rasqal_query *query;
  FILE *fh;
  int rc;
  const char *filename=NULL;
  raptor_uri* base_uri=NULL;
  unsigned char *uri_string;

#if RASQAL_DEBUG > 2
  sparql_parser_debug=1;
#endif

  if(argc > 1) {
    filename=argv[1];
    fh = fopen(argv[1], "r");
    if(!fh) {
      fprintf(stderr, "%s: Cannot open file %s - %s\n", program, filename,
              strerror(errno));
      exit(1);
    }
  } else {
    filename="<stdin>";
    fh = stdin;
  }

  memset(query_string, 0, SPARQL_FILE_BUF_SIZE);
  rc=fread(query_string, SPARQL_FILE_BUF_SIZE, 1, fh);
  if(rc < SPARQL_FILE_BUF_SIZE) {
    if(ferror(fh)) {
      fprintf(stderr, "%s: file '%s' read failed - %s\n",
              program, filename, strerror(errno));
      fclose(fh);
      return(1);
    }
  }
  
  if(argc>1)
    fclose(fh);

  rasqal_init();

  query=rasqal_new_query("sparql", NULL);

  uri_string=raptor_uri_filename_to_uri_string(filename);
  base_uri=raptor_new_uri(uri_string);

  rc=rasqal_query_prepare(query, (const unsigned char*)query_string, base_uri);

  rasqal_query_print(query, DEBUG_FH);

  rasqal_free_query(query);

  raptor_free_uri(base_uri);

  raptor_free_memory(uri_string);

  rasqal_finish();

  return rc;
}
#endif

