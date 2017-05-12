
# line 8 "parse.y"
#include "rc.h"
#ifndef lint
#define lint		/* hush up gcc -Wall, leave out the dumb sccsid's. */
#endif
static Node *star, *nolist;
Node *parsetree;	/* not using yylval because bison declares it as an auto */

# line 28 "parse.y"
typedef union
#ifdef __cplusplus
	YYSTYPE
#endif
 {
	struct Node *node;
	struct Redir redir;
	struct Pipe pipe;
	struct Dup dup;
	struct Word word;
	char *keyword;
} YYSTYPE;
# define ANDAND 257
# define BACKBACK 258
# define BANG 259
# define CASE 260
# define COUNT 261
# define DUP 262
# define ELSE 263
# define END 264
# define FLAT 265
# define FN 266
# define FOR 267
# define IF 268
# define IN 269
# define OROR 270
# define PIPE 271
# define REDIR 272
# define SREDIR 273
# define SUB 274
# define SUBSHELL 275
# define SWITCH 276
# define TWIDDLE 277
# define WHILE 278
# define WORD 279
# define HUH 280

#ifdef __STDC__
#include <stdlib.h>
#include <string.h>
#else
#include <malloc.h>
#include <memory.h>
#endif

#include <values.h>

#ifdef __cplusplus

#ifndef yyerror
	void yyerror(const char *);
#endif

#ifndef yylex
#ifdef __EXTERN_C__
	extern "C" { int yylex(void); }
#else
	int yylex(void);
#endif
#endif
	int yyparse(void);

#endif
#define yyclearin yychar = -1
#define yyerrok yyerrflag = 0
extern int yychar;
extern int yyerrflag;
YYSTYPE yylval;
YYSTYPE yyval;
typedef int yytabelem;
#ifndef YYMAXDEPTH
#define YYMAXDEPTH 150
#endif
#if YYMAXDEPTH > 0
int yy_yys[YYMAXDEPTH], *yys = yy_yys;
YYSTYPE yy_yyv[YYMAXDEPTH], *yyv = yy_yyv;
#else	/* user does initial allocation */
int *yys;
YYSTYPE *yyv;
#endif
static int yymaxdepth = YYMAXDEPTH;
# define YYERRCODE 256

# line 168 "parse.y"


void initparse() {
	star = treecpy(mk(nVar,mk(nWord,"*",NULL)), ealloc);
	nolist = treecpy(mk(nVar,mk(nWord,"ifs",NULL)), ealloc);
}

yytabelem yyexca[] ={
-1, 0,
	257, 28,
	264, 28,
	270, 28,
	271, 28,
	10, 28,
	59, 28,
	38, 28,
	-2, 0,
-1, 1,
	0, -1,
	-2, 0,
	};
# define YYNPROD 86
# define YYLAST 688
yytabelem yyact[]={

   152,    24,    20,   130,    20,    29,   109,    37,    39,    33,
   125,    76,    59,    22,    59,    22,   141,   147,   106,    19,
    38,    39,   113,   127,    71,    13,    24,   116,    92,    66,
    29,    72,    42,    58,    57,   123,    74,    64,    61,     1,
    62,    75,     4,    60,   120,    77,     5,     4,    24,   151,
    65,     5,    29,   112,    63,    67,    68,     6,    88,    92,
    18,    27,    89,    92,    73,     2,    69,    70,    31,   143,
    24,    40,    34,    14,    29,    45,    92,     0,     0,     0,
     0,     7,     0,     0,    58,     0,    27,     0,    19,   116,
     0,     0,    24,    93,     0,     0,    29,     0,    95,     0,
     0,    90,    91,    79,     0,     0,     0,     0,    27,    86,
     0,   100,   101,   108,     0,    24,     0,     0,     0,    29,
     0,     0,     0,    94,   128,     0,    97,     0,     0,     0,
    27,   115,   117,   118,   129,     0,   121,    24,     0,   126,
   138,    29,   136,     0,     0,     0,     0,     0,    58,   131,
   144,     0,    27,   102,     0,   144,   144,     0,     0,    24,
   148,   149,    79,    29,   134,     0,     0,     0,     0,   110,
   150,     0,     0,     0,   137,    27,   122,   139,   107,    19,
   142,     0,   146,     0,     0,   142,   142,    24,   132,     0,
   133,    29,     0,   135,     0,     0,     0,    27,     0,   140,
     0,     0,    19,     0,     0,     0,    36,     0,     0,     0,
     0,     0,     0,     0,    36,     0,     0,     0,     0,    27,
     0,     0,     0,    28,    55,    53,    25,    35,    52,     0,
    26,    51,    46,    49,    47,    35,     0,    80,   124,     0,
    56,    50,    54,    48,    30,     0,     0,    27,    28,    55,
    53,    25,     0,    52,     0,    26,    51,    46,    49,    47,
    24,     0,    80,    32,    29,    56,    50,    54,    48,    30,
    28,    55,    53,    25,    19,    52,     0,    26,    51,    46,
    49,    47,     0,     0,    80,     0,     0,    56,    50,    54,
    48,    30,    28,    55,    53,    25,    20,    52,     0,    26,
    51,    46,    49,    47,     0,     0,    21,    22,     0,    56,
    50,    54,    48,    30,    28,    15,   145,    25,    20,     0,
    27,    26,    17,     9,     8,     0,     0,     0,    21,    22,
     0,    16,    11,    12,    10,    30,     0,    28,    15,     0,
    25,    20,     0,     0,    26,    17,     9,     8,     0,     0,
     0,    21,    22,     0,    16,    11,    12,    10,    30,    28,
    55,    53,    25,     0,    52,     0,    26,    51,    46,    49,
    47,    24,     0,    80,     0,    29,    56,    50,    54,    48,
    30,    28,    55,    53,    25,     0,    52,     0,    26,    51,
    46,    49,    47,    24,     0,    80,     0,    29,    56,    50,
    54,    48,    30,     0,     0,     0,     0,     0,     0,    28,
    55,    53,    25,     0,    52,     0,    26,    51,    46,    49,
    47,     0,     0,    80,     0,    37,    56,    50,    54,    48,
    30,    27,     0,    37,     0,    44,    23,     0,    38,    39,
     0,    23,     0,    43,     0,     0,    38,    39,     0,    23,
    23,     0,     0,    27,     0,    23,     0,     0,    19,     0,
     0,     0,     0,     0,     0,     0,     0,     0,    82,    83,
    84,    85,     0,     0,     0,     0,     0,     0,     0,     0,
    19,     0,    28,    55,    53,    25,     0,    52,     0,    26,
    51,    46,    49,    47,     0,     0,    80,    23,     0,    56,
    50,    54,    48,    30,     0,    23,    23,     0,     0,     0,
     0,     0,    23,     0,     0,     0,     0,   105,     0,     0,
     0,     0,     0,     0,     0,    23,    23,    23,     0,     0,
    23,   111,     0,    23,     0,     0,   119,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,    23,     0,
     0,    23,     0,     0,    23,     0,    23,     0,     0,    23,
    23,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     3,     0,    28,    15,     0,    25,    20,   103,     0,
    26,    17,     9,     8,     0,    41,     0,    21,    22,     0,
    16,    11,    12,    10,    30,    28,    15,     0,    25,    20,
    78,    81,    26,    17,     9,     8,     0,    87,     0,    21,
    22,     0,    16,    11,    12,    10,    30,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     0,    78,     0,
     0,    96,     0,    98,    99,     0,     0,     0,     0,     0,
     0,   104,     0,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     0,     0,     0,     0,     0,   114 };
yytabelem yypact[]={

   335,-10000000,    -1,    -1,   176,   357,    34,  -258,    -2,     0,
    -2,    -3,   -65,   357,   357,   -65,   -65,-10000000,   -30,   357,
-10000000,   151,   224,-10000000,   224,   224,   224,   151,   224,-10000000,
-10000000,-10000000,-10000000,-10000000,-10000000,-10000000,-10000000,-10000000,-10000000,-10000000,
-10000000,   -66,-10000000,-10000000,-10000000,-10000000,-10000000,-10000000,-10000000,-10000000,
-10000000,-10000000,-10000000,-10000000,-10000000,-10000000,-10000000,-10000000,  -258,   224,
-10000000,   357,   224,-10000000,   224,   224,-10000000,  -263,  -263,   357,
   357,   151,   224,   224,  -107,   168,   357,-10000000,   -66,-10000000,
  -104,   -66,  -268,-10000000,-10000000,-10000000,-10000000,   -35,    12,    79,
    79,    79,   224,-10000000,    79,    -6,   -31,    79,   -18,   -66,
  -263,  -263,-10000000,   -66,   -66,-10000000,-10000000,-10000000,-10000000,-10000000,
-10000000,-10000000,-10000000,-10000000,   -66,  -263,-10000000,  -263,-10000000,-10000000,
-10000000,  -250,  -260,-10000000,-10000000,-10000000,  -250,-10000000,   224,   123,
-10000000,   101,    79,    17,-10000000,    79,-10000000,  -250,    56,  -250,
    79,  -108,   168,    56,    56,-10000000,  -250,-10000000,-10000000,-10000000,
   -10,-10000000,-10000000 };
yytabelem yypgo[]={

     0,    75,    73,    36,    81,    69,    16,    41,    45,    11,
   435,    34,    60,    65,    58,    43,    25,   443,    57,    44,
   598,    24,    39,    68,    62,    50 };
yytabelem yyr1[]={

     0,    22,    22,    23,    23,     8,     8,    13,    13,     3,
     3,     9,     9,     4,    15,     2,    11,    11,    16,    16,
    16,     5,     5,     6,     6,     6,    19,    19,     7,     7,
     7,     7,     7,     7,     7,     7,     7,     7,     7,     7,
     7,     7,     7,     7,     7,     7,    25,    25,    18,    18,
    18,    12,    12,    17,    17,    20,    20,    10,    10,    10,
    10,    10,    10,    10,    10,    10,    10,    10,     1,     1,
     1,     1,     1,     1,     1,     1,     1,     1,     1,    21,
    21,    14,    14,    14,    24,    24 };
yytabelem yyr2[]={

     0,     5,     5,     3,     3,     4,     5,     2,     5,     2,
     5,     2,     5,     7,     7,     7,     1,     5,     3,     5,
     5,     7,     7,     3,     5,     5,     2,     9,     1,     2,
     5,     9,    17,    13,     9,    17,     9,     9,     9,     9,
     5,     5,     7,     7,     7,     5,     0,     2,     2,     5,
     5,     2,     7,     2,     3,     2,     7,     5,    11,     5,
     5,     5,     5,     7,     7,     7,     5,     3,     3,     3,
     3,     3,     3,     3,     3,     3,     3,     3,     3,     1,
     5,     1,     4,     5,     0,     4 };
yytabelem yychk[]={

-10000000,   -22,   -13,   256,    -7,    -8,   -18,    -4,   268,   267,
   278,   276,   277,   -16,    -2,   259,   275,   266,   -12,   123,
   262,   272,   273,   -10,    36,   261,   265,    96,   258,    40,
   279,   -23,   264,    10,   -23,    59,    38,   257,   270,   271,
   -13,   -20,   -16,   -17,   -10,    -1,   267,   269,   278,   268,
   276,   266,   263,   260,   277,   259,   275,   -11,   -16,   272,
   -15,    40,    40,   -15,    40,   -25,    94,    -7,    -7,   -25,
   -25,   -21,    61,    94,    -3,    -7,    -9,    -8,   -20,    -4,
   272,   -20,   -17,   -17,   -17,   -17,    -4,   -20,   -14,   -24,
   -24,   -24,    94,   -11,   -24,    -3,   -20,   -24,   -20,   -20,
    -7,    -7,    -4,   -20,   -20,   -17,   125,    10,    -3,   274,
    -4,   -17,    41,    10,   -20,    -7,    10,    -7,    -7,   -17,
   -19,    -7,    -4,    41,   269,    41,    -7,    41,   -21,   -21,
   263,   -21,   -24,   -24,    41,   -24,    41,    -7,   123,    -7,
   -24,    -6,    -7,    -5,    -9,   260,    -7,   125,    -6,    -6,
   -21,    59,    10 };
yytabelem yydef[]={

    -2,    -2,     0,     0,     7,    28,    29,    16,     0,     0,
     0,     0,    46,    28,    28,    46,    46,    79,    48,    28,
    18,     0,     0,    51,     0,     0,     0,     0,     0,    81,
    67,     1,     3,     4,     2,     5,     6,    84,    84,    84,
     8,    49,    50,    55,    53,    54,    68,    69,    70,    71,
    72,    73,    74,    75,    76,    77,    78,    30,    16,     0,
    84,    28,     0,    84,     0,     0,    47,    40,    41,    28,
    28,    45,     0,     0,     0,     9,    28,    11,    19,    66,
     0,    20,    57,    59,    60,    61,    62,     0,     0,    28,
    28,    28,     0,    17,    28,     0,     0,    28,     0,    79,
    42,    43,    44,    80,    15,    52,    13,    12,    10,    79,
    63,    64,    65,    82,    83,    37,    85,    38,    39,    56,
    31,    26,    16,    14,    79,    84,    34,    84,    36,     0,
    84,     0,    28,     0,    58,    28,    84,    33,    28,    27,
    28,     0,    23,    28,    28,    79,    32,    35,    24,    25,
     0,    21,    22 };
typedef struct
#ifdef __cplusplus
	yytoktype
#endif
{ char *t_name; int t_val; } yytoktype;
#ifndef YYDEBUG
#	define YYDEBUG	0	/* don't allow debugging */
#endif

#if YYDEBUG

yytoktype yytoks[] =
{
	"ANDAND",	257,
	"BACKBACK",	258,
	"BANG",	259,
	"CASE",	260,
	"COUNT",	261,
	"DUP",	262,
	"ELSE",	263,
	"END",	264,
	"FLAT",	265,
	"FN",	266,
	"FOR",	267,
	"IF",	268,
	"IN",	269,
	"OROR",	270,
	"PIPE",	271,
	"REDIR",	272,
	"SREDIR",	273,
	"SUB",	274,
	"SUBSHELL",	275,
	"SWITCH",	276,
	"TWIDDLE",	277,
	"WHILE",	278,
	"WORD",	279,
	"HUH",	280,
	")",	41,
	"\n",	10,
	"$",	36,
	"-unknown-",	-1	/* ends search */
};

char * yyreds[] =
{
	"-no such reduction-",
	"rc : line end",
	"rc : error end",
	"end : END",
	"end : '\n'",
	"cmdsa : cmd ';'",
	"cmdsa : cmd '&'",
	"line : cmd",
	"line : cmdsa line",
	"body : cmd",
	"body : cmdsan body",
	"cmdsan : cmdsa",
	"cmdsan : cmd '\n'",
	"brace : '{' body '}'",
	"paren : '(' body ')'",
	"assign : first '=' word",
	"epilog : /* empty */",
	"epilog : redir epilog",
	"redir : DUP",
	"redir : REDIR word",
	"redir : SREDIR word",
	"case : CASE words ';'",
	"case : CASE words '\n'",
	"cbody : cmd",
	"cbody : case cbody",
	"cbody : cmdsan cbody",
	"iftail : cmd",
	"iftail : brace ELSE optnl cmd",
	"cmd : /* empty */",
	"cmd : simple",
	"cmd : brace epilog",
	"cmd : IF paren optnl iftail",
	"cmd : FOR '(' word IN words ')' optnl cmd",
	"cmd : FOR '(' word ')' optnl cmd",
	"cmd : WHILE paren optnl cmd",
	"cmd : SWITCH '(' word ')' optnl '{' cbody '}'",
	"cmd : TWIDDLE optcaret word words",
	"cmd : cmd ANDAND optnl cmd",
	"cmd : cmd OROR optnl cmd",
	"cmd : cmd PIPE optnl cmd",
	"cmd : redir cmd",
	"cmd : assign cmd",
	"cmd : BANG optcaret cmd",
	"cmd : SUBSHELL optcaret cmd",
	"cmd : FN words brace",
	"cmd : FN words",
	"optcaret : /* empty */",
	"optcaret : '^'",
	"simple : first",
	"simple : simple word",
	"simple : simple redir",
	"first : comword",
	"first : first '^' sword",
	"sword : comword",
	"sword : keyword",
	"word : sword",
	"word : word '^' sword",
	"comword : '$' sword",
	"comword : '$' sword SUB words ')'",
	"comword : COUNT sword",
	"comword : FLAT sword",
	"comword : '`' sword",
	"comword : '`' brace",
	"comword : BACKBACK word brace",
	"comword : BACKBACK word sword",
	"comword : '(' nlwords ')'",
	"comword : REDIR brace",
	"comword : WORD",
	"keyword : FOR",
	"keyword : IN",
	"keyword : WHILE",
	"keyword : IF",
	"keyword : SWITCH",
	"keyword : FN",
	"keyword : ELSE",
	"keyword : CASE",
	"keyword : TWIDDLE",
	"keyword : BANG",
	"keyword : SUBSHELL",
	"words : /* empty */",
	"words : words word",
	"nlwords : /* empty */",
	"nlwords : nlwords '\n'",
	"nlwords : nlwords word",
	"optnl : /* empty */",
	"optnl : optnl '\n'",
};
#endif /* YYDEBUG */
# line	1 "/usr/ccs/bin/yaccpar"
/*
 * Copyright (c) 1993 by Sun Microsystems, Inc.
 */

#pragma ident	"@(#)yaccpar	6.12	93/06/07 SMI"

/*
** Skeleton parser driver for yacc output
*/

/*
** yacc user known macros and defines
*/
#define YYERROR		goto yyerrlab
#define YYACCEPT	return(0)
#define YYABORT		return(1)
#define YYBACKUP( newtoken, newvalue )\
{\
	if ( yychar >= 0 || ( yyr2[ yytmp ] >> 1 ) != 1 )\
	{\
		yyerror( "syntax error - cannot backup" );\
		goto yyerrlab;\
	}\
	yychar = newtoken;\
	yystate = *yyps;\
	yylval = newvalue;\
	goto yynewstate;\
}
#define YYRECOVERING()	(!!yyerrflag)
#define YYNEW(type)	malloc(sizeof(type) * yynewmax)
#define YYCOPY(to, from, type) \
	(type *) memcpy(to, (char *) from, yynewmax * sizeof(type))
#define YYENLARGE( from, type) \
	(type *) realloc((char *) from, yynewmax * sizeof(type))
#ifndef YYDEBUG
#	define YYDEBUG	1	/* make debugging available */
#endif

/*
** user known globals
*/
int yydebug;			/* set to 1 to get debugging */

/*
** driver internal defines
*/
#define YYFLAG		(-10000000)

/*
** global variables used by the parser
*/
YYSTYPE *yypv;			/* top of value stack */
int *yyps;			/* top of state stack */

int yystate;			/* current state */
int yytmp;			/* extra var (lasts between blocks) */

int yynerrs;			/* number of errors */
int yyerrflag;			/* error recovery flag */
int yychar;			/* current input token number */



#ifdef YYNMBCHARS
#define YYLEX()		yycvtok(yylex())
/*
** yycvtok - return a token if i is a wchar_t value that exceeds 255.
**	If i<255, i itself is the token.  If i>255 but the neither 
**	of the 30th or 31st bit is on, i is already a token.
*/
#if defined(__STDC__) || defined(__cplusplus)
int yycvtok(int i)
#else
int yycvtok(i) int i;
#endif
{
	int first = 0;
	int last = YYNMBCHARS - 1;
	int mid;
	wchar_t j;

	if(i&0x60000000){/*Must convert to a token. */
		if( yymbchars[last].character < i ){
			return i;/*Giving up*/
		}
		while ((last>=first)&&(first>=0)) {/*Binary search loop*/
			mid = (first+last)/2;
			j = yymbchars[mid].character;
			if( j==i ){/*Found*/ 
				return yymbchars[mid].tvalue;
			}else if( j<i ){
				first = mid + 1;
			}else{
				last = mid -1;
			}
		}
		/*No entry in the table.*/
		return i;/* Giving up.*/
	}else{/* i is already a token. */
		return i;
	}
}
#else/*!YYNMBCHARS*/
#define YYLEX()		yylex()
#endif/*!YYNMBCHARS*/

/*
** yyparse - return 0 if worked, 1 if syntax error not recovered from
*/
#if defined(__STDC__) || defined(__cplusplus)
int yyparse(void)
#else
int yyparse()
#endif
{
	register YYSTYPE *yypvt;	/* top of value stack for $vars */

#if defined(__cplusplus) || defined(lint)
/*
	hacks to please C++ and lint - goto's inside switch should never be
	executed; yypvt is set to 0 to avoid "used before set" warning.
*/
	static int __yaccpar_lint_hack__ = 0;
	switch (__yaccpar_lint_hack__)
	{
		case 1: goto yyerrlab;
		case 2: goto yynewstate;
	}
	yypvt = 0;
#endif

	/*
	** Initialize externals - yyparse may be called more than once
	*/
	yypv = &yyv[-1];
	yyps = &yys[-1];
	yystate = 0;
	yytmp = 0;
	yynerrs = 0;
	yyerrflag = 0;
	yychar = -1;

#if YYMAXDEPTH <= 0
	if (yymaxdepth <= 0)
	{
		if ((yymaxdepth = YYEXPAND(0)) <= 0)
		{
			yyerror("yacc initialization error");
			YYABORT;
		}
	}
#endif

	{
		register YYSTYPE *yy_pv;	/* top of value stack */
		register int *yy_ps;		/* top of state stack */
		register int yy_state;		/* current state */
		register int  yy_n;		/* internal state number info */
	goto yystack;	/* moved from 6 lines above to here to please C++ */

		/*
		** get globals into registers.
		** branch to here only if YYBACKUP was called.
		*/
	yynewstate:
		yy_pv = yypv;
		yy_ps = yyps;
		yy_state = yystate;
		goto yy_newstate;

		/*
		** get globals into registers.
		** either we just started, or we just finished a reduction
		*/
	yystack:
		yy_pv = yypv;
		yy_ps = yyps;
		yy_state = yystate;

		/*
		** top of for (;;) loop while no reductions done
		*/
	yy_stack:
		/*
		** put a state and value onto the stacks
		*/
#if YYDEBUG
		/*
		** if debugging, look up token value in list of value vs.
		** name pairs.  0 and negative (-1) are special values.
		** Note: linear search is used since time is not a real
		** consideration while debugging.
		*/
		if ( yydebug )
		{
			register int yy_i;

			printf( "State %d, token ", yy_state );
			if ( yychar == 0 )
				printf( "end-of-file\n" );
			else if ( yychar < 0 )
				printf( "-none-\n" );
			else
			{
				for ( yy_i = 0; yytoks[yy_i].t_val >= 0;
					yy_i++ )
				{
					if ( yytoks[yy_i].t_val == yychar )
						break;
				}
				printf( "%s\n", yytoks[yy_i].t_name );
			}
		}
#endif /* YYDEBUG */
		if ( ++yy_ps >= &yys[ yymaxdepth ] )	/* room on stack? */
		{
			/*
			** reallocate and recover.  Note that pointers
			** have to be reset, or bad things will happen
			*/
			int yyps_index = (yy_ps - yys);
			int yypv_index = (yy_pv - yyv);
			int yypvt_index = (yypvt - yyv);
			int yynewmax;
#ifdef YYEXPAND
			yynewmax = YYEXPAND(yymaxdepth);
#else
			yynewmax = 2 * yymaxdepth;	/* double table size */
			if (yymaxdepth == YYMAXDEPTH)	/* first time growth */
			{
				char *newyys = (char *)YYNEW(int);
				char *newyyv = (char *)YYNEW(YYSTYPE);
				if (newyys != 0 && newyyv != 0)
				{
					yys = YYCOPY(newyys, yys, int);
					yyv = YYCOPY(newyyv, yyv, YYSTYPE);
				}
				else
					yynewmax = 0;	/* failed */
			}
			else				/* not first time */
			{
				yys = YYENLARGE(yys, int);
				yyv = YYENLARGE(yyv, YYSTYPE);
				if (yys == 0 || yyv == 0)
					yynewmax = 0;	/* failed */
			}
#endif
			if (yynewmax <= yymaxdepth)	/* tables not expanded */
			{
				yyerror( "yacc stack overflow" );
				YYABORT;
			}
			yymaxdepth = yynewmax;

			yy_ps = yys + yyps_index;
			yy_pv = yyv + yypv_index;
			yypvt = yyv + yypvt_index;
		}
		*yy_ps = yy_state;
		*++yy_pv = yyval;

		/*
		** we have a new state - find out what to do
		*/
	yy_newstate:
		if ( ( yy_n = yypact[ yy_state ] ) <= YYFLAG )
			goto yydefault;		/* simple state */
#if YYDEBUG
		/*
		** if debugging, need to mark whether new token grabbed
		*/
		yytmp = yychar < 0;
#endif
		if ( ( yychar < 0 ) && ( ( yychar = YYLEX() ) < 0 ) )
			yychar = 0;		/* reached EOF */
#if YYDEBUG
		if ( yydebug && yytmp )
		{
			register int yy_i;

			printf( "Received token " );
			if ( yychar == 0 )
				printf( "end-of-file\n" );
			else if ( yychar < 0 )
				printf( "-none-\n" );
			else
			{
				for ( yy_i = 0; yytoks[yy_i].t_val >= 0;
					yy_i++ )
				{
					if ( yytoks[yy_i].t_val == yychar )
						break;
				}
				printf( "%s\n", yytoks[yy_i].t_name );
			}
		}
#endif /* YYDEBUG */
		if ( ( ( yy_n += yychar ) < 0 ) || ( yy_n >= YYLAST ) )
			goto yydefault;
		if ( yychk[ yy_n = yyact[ yy_n ] ] == yychar )	/*valid shift*/
		{
			yychar = -1;
			yyval = yylval;
			yy_state = yy_n;
			if ( yyerrflag > 0 )
				yyerrflag--;
			goto yy_stack;
		}

	yydefault:
		if ( ( yy_n = yydef[ yy_state ] ) == -2 )
		{
#if YYDEBUG
			yytmp = yychar < 0;
#endif
			if ( ( yychar < 0 ) && ( ( yychar = YYLEX() ) < 0 ) )
				yychar = 0;		/* reached EOF */
#if YYDEBUG
			if ( yydebug && yytmp )
			{
				register int yy_i;

				printf( "Received token " );
				if ( yychar == 0 )
					printf( "end-of-file\n" );
				else if ( yychar < 0 )
					printf( "-none-\n" );
				else
				{
					for ( yy_i = 0;
						yytoks[yy_i].t_val >= 0;
						yy_i++ )
					{
						if ( yytoks[yy_i].t_val
							== yychar )
						{
							break;
						}
					}
					printf( "%s\n", yytoks[yy_i].t_name );
				}
			}
#endif /* YYDEBUG */
			/*
			** look through exception table
			*/
			{
				register int *yyxi = yyexca;

				while ( ( *yyxi != -1 ) ||
					( yyxi[1] != yy_state ) )
				{
					yyxi += 2;
				}
				while ( ( *(yyxi += 2) >= 0 ) &&
					( *yyxi != yychar ) )
					;
				if ( ( yy_n = yyxi[1] ) < 0 )
					YYACCEPT;
			}
		}

		/*
		** check for syntax error
		*/
		if ( yy_n == 0 )	/* have an error */
		{
			/* no worry about speed here! */
			switch ( yyerrflag )
			{
			case 0:		/* new error */
				yyerror( "syntax error" );
				goto skip_init;
			yyerrlab:
				/*
				** get globals into registers.
				** we have a user generated syntax type error
				*/
				yy_pv = yypv;
				yy_ps = yyps;
				yy_state = yystate;
			skip_init:
				yynerrs++;
				/* FALLTHRU */
			case 1:
			case 2:		/* incompletely recovered error */
					/* try again... */
				yyerrflag = 3;
				/*
				** find state where "error" is a legal
				** shift action
				*/
				while ( yy_ps >= yys )
				{
					yy_n = yypact[ *yy_ps ] + YYERRCODE;
					if ( yy_n >= 0 && yy_n < YYLAST &&
						yychk[yyact[yy_n]] == YYERRCODE)					{
						/*
						** simulate shift of "error"
						*/
						yy_state = yyact[ yy_n ];
						goto yy_stack;
					}
					/*
					** current state has no shift on
					** "error", pop stack
					*/
#if YYDEBUG
#	define _POP_ "Error recovery pops state %d, uncovers state %d\n"
					if ( yydebug )
						printf( _POP_, *yy_ps,
							yy_ps[-1] );
#	undef _POP_
#endif
					yy_ps--;
					yy_pv--;
				}
				/*
				** there is no state on stack with "error" as
				** a valid shift.  give up.
				*/
				YYABORT;
			case 3:		/* no shift yet; eat a token */
#if YYDEBUG
				/*
				** if debugging, look up token in list of
				** pairs.  0 and negative shouldn't occur,
				** but since timing doesn't matter when
				** debugging, it doesn't hurt to leave the
				** tests here.
				*/
				if ( yydebug )
				{
					register int yy_i;

					printf( "Error recovery discards " );
					if ( yychar == 0 )
						printf( "token end-of-file\n" );
					else if ( yychar < 0 )
						printf( "token -none-\n" );
					else
					{
						for ( yy_i = 0;
							yytoks[yy_i].t_val >= 0;
							yy_i++ )
						{
							if ( yytoks[yy_i].t_val
								== yychar )
							{
								break;
							}
						}
						printf( "token %s\n",
							yytoks[yy_i].t_name );
					}
				}
#endif /* YYDEBUG */
				if ( yychar == 0 )	/* reached EOF. quit */
					YYABORT;
				yychar = -1;
				goto yy_newstate;
			}
		}/* end if ( yy_n == 0 ) */
		/*
		** reduction by production yy_n
		** put stack tops, etc. so things right after switch
		*/
#if YYDEBUG
		/*
		** if debugging, print the string that is the user's
		** specification of the reduction which is just about
		** to be done.
		*/
		if ( yydebug )
			printf( "Reduce by (%d) \"%s\"\n",
				yy_n, yyreds[ yy_n ] );
#endif
		yytmp = yy_n;			/* value to switch over */
		yypvt = yy_pv;			/* $vars top of value stack */
		/*
		** Look in goto table for next state
		** Sorry about using yy_state here as temporary
		** register variable, but why not, if it works...
		** If yyr2[ yy_n ] doesn't have the low order bit
		** set, then there is no action to be done for
		** this reduction.  So, no saving & unsaving of
		** registers done.  The only difference between the
		** code just after the if and the body of the if is
		** the goto yy_stack in the body.  This way the test
		** can be made before the choice of what to do is needed.
		*/
		{
			/* length of production doubled with extra bit */
			register int yy_len = yyr2[ yy_n ];

			if ( !( yy_len & 01 ) )
			{
				yy_len >>= 1;
				yyval = ( yy_pv -= yy_len )[1];	/* $$ = $1 */
				yy_state = yypgo[ yy_n = yyr1[ yy_n ] ] +
					*( yy_ps -= yy_len ) + 1;
				if ( yy_state >= YYLAST ||
					yychk[ yy_state =
					yyact[ yy_state ] ] != -yy_n )
				{
					yy_state = yyact[ yypgo[ yy_n ] ];
				}
				goto yy_stack;
			}
			yy_len >>= 1;
			yyval = ( yy_pv -= yy_len )[1];	/* $$ = $1 */
			yy_state = yypgo[ yy_n = yyr1[ yy_n ] ] +
				*( yy_ps -= yy_len ) + 1;
			if ( yy_state >= YYLAST ||
				yychk[ yy_state = yyact[ yy_state ] ] != -yy_n )
			{
				yy_state = yyact[ yypgo[ yy_n ] ];
			}
		}
					/* save until reenter driver code */
		yystate = yy_state;
		yyps = yy_ps;
		yypv = yy_pv;
	}
	/*
	** code supplied by user is placed in this switch
	*/
	switch( yytmp )
	{
		
case 1:
# line 49 "parse.y"
{ parsetree = yypvt[-1].node; YYACCEPT; } break;
case 2:
# line 50 "parse.y"
{ yyerrok; parsetree = NULL; YYABORT; } break;
case 3:
# line 53 "parse.y"
{ if (!heredoc(1)) YYABORT; } break;
case 4:
# line 54 "parse.y"
{ if (!heredoc(0)) YYABORT; } break;
case 6:
# line 58 "parse.y"
{ yyval.node = (yypvt[-1].node != NULL ? mk(nNowait,yypvt[-1].node) : yypvt[-1].node); } break;
case 8:
# line 62 "parse.y"
{ yyval.node = (yypvt[-1].node != NULL ? mk(nBody,yypvt[-1].node,yypvt[-0].node) : yypvt[-0].node); } break;
case 10:
# line 66 "parse.y"
{ yyval.node = (yypvt[-1].node == NULL ? yypvt[-0].node : yypvt[-0].node == NULL ? yypvt[-1].node : mk(nBody,yypvt[-1].node,yypvt[-0].node)); } break;
case 12:
# line 69 "parse.y"
{ yyval.node = yypvt[-1].node; if (!heredoc(0)) YYABORT; } break;
case 13:
# line 71 "parse.y"
{ yyval.node = yypvt[-1].node; } break;
case 14:
# line 73 "parse.y"
{ yyval.node = yypvt[-1].node; } break;
case 15:
# line 75 "parse.y"
{ yyval.node = mk(nAssign,yypvt[-2].node,yypvt[-0].node); } break;
case 16:
# line 77 "parse.y"
{ yyval.node = NULL; } break;
case 17:
# line 78 "parse.y"
{ yyval.node = (yypvt[-0].node? mk(nEpilog,yypvt[-1].node,yypvt[-0].node) : yypvt[-1].node); } break;
case 18:
# line 81 "parse.y"
{ yyval.node = mk(nDup,yypvt[-0].dup.type,yypvt[-0].dup.left,yypvt[-0].dup.right); } break;
case 19:
# line 82 "parse.y"
{ yyval.node = mk(nRedir,yypvt[-1].redir.type,yypvt[-1].redir.fd,yypvt[-0].node);
				  if (yypvt[-1].redir.type == rHeredoc && !qdoc(yypvt[-0].node, yyval.node)) YYABORT; /* queue heredocs up */
				} break;
case 20:
# line 85 "parse.y"
{ yyval.node = mk(nRedir,yypvt[-1].redir.type,yypvt[-1].redir.fd,yypvt[-0].node);
				  if (yypvt[-1].redir.type == rHeredoc && !qdoc(yypvt[-0].node, yyval.node)) YYABORT; /* queue heredocs up */
				} break;
case 21:
# line 89 "parse.y"
{ yyval.node = mk(nCase, yypvt[-1].node); } break;
case 22:
# line 90 "parse.y"
{ yyval.node = mk(nCase, yypvt[-1].node); } break;
case 23:
# line 92 "parse.y"
{ yyval.node = mk(nCbody, yypvt[-0].node, NULL); } break;
case 24:
# line 93 "parse.y"
{ yyval.node = mk(nCbody, yypvt[-1].node, yypvt[-0].node); } break;
case 25:
# line 94 "parse.y"
{ yyval.node = mk(nCbody, yypvt[-1].node, yypvt[-0].node); } break;
case 27:
# line 97 "parse.y"
{ yyval.node = mk(nElse,yypvt[-3].node,yypvt[-0].node); } break;
case 28:
# line 99 "parse.y"
{ yyval.node = NULL; } break;
case 30:
# line 101 "parse.y"
{ yyval.node = mk(nBrace,yypvt[-1].node,yypvt[-0].node); } break;
case 31:
# line 102 "parse.y"
{ yyval.node = mk(nIf,yypvt[-2].node,yypvt[-0].node); } break;
case 32:
# line 103 "parse.y"
{ yyval.node = mk(nForin,yypvt[-5].node,yypvt[-3].node,yypvt[-0].node); } break;
case 33:
# line 104 "parse.y"
{ yyval.node = mk(nForin,yypvt[-3].node,star,yypvt[-0].node); } break;
case 34:
# line 105 "parse.y"
{ yyval.node = mk(nWhile,yypvt[-2].node,yypvt[-0].node); } break;
case 35:
# line 106 "parse.y"
{ yyval.node = mk(nSwitch,yypvt[-5].node,yypvt[-1].node); } break;
case 36:
# line 107 "parse.y"
{ yyval.node = mk(nMatch,yypvt[-1].node,yypvt[-0].node); } break;
case 37:
# line 108 "parse.y"
{ yyval.node = mk(nAndalso,yypvt[-3].node,yypvt[-0].node); } break;
case 38:
# line 109 "parse.y"
{ yyval.node = mk(nOrelse,yypvt[-3].node,yypvt[-0].node); } break;
case 39:
# line 110 "parse.y"
{ yyval.node = mk(nPipe,yypvt[-2].pipe.left,yypvt[-2].pipe.right,yypvt[-3].node,yypvt[-0].node); } break;
case 40:
# line 111 "parse.y"
{ yyval.node = (yypvt[-0].node != NULL ? mk(nPre,yypvt[-1].node,yypvt[-0].node) : yypvt[-1].node); } break;
case 41:
# line 112 "parse.y"
{ yyval.node = (yypvt[-0].node != NULL ? mk(nPre,yypvt[-1].node,yypvt[-0].node) : yypvt[-1].node); } break;
case 42:
# line 113 "parse.y"
{ yyval.node = mk(nBang,yypvt[-0].node); } break;
case 43:
# line 114 "parse.y"
{ yyval.node = mk(nSubshell,yypvt[-0].node); } break;
case 44:
# line 115 "parse.y"
{ yyval.node = mk(nNewfn,yypvt[-1].node,yypvt[-0].node); } break;
case 45:
# line 116 "parse.y"
{ yyval.node = mk(nRmfn,yypvt[-0].node); } break;
case 49:
# line 122 "parse.y"
{ yyval.node = (yypvt[-0].node != NULL ? mk(nArgs,yypvt[-1].node,yypvt[-0].node) : yypvt[-1].node); } break;
case 50:
# line 123 "parse.y"
{ yyval.node = mk(nArgs,yypvt[-1].node,yypvt[-0].node); } break;
case 52:
# line 126 "parse.y"
{ yyval.node = mk(nConcat,yypvt[-2].node,yypvt[-0].node); } break;
case 54:
# line 129 "parse.y"
{ yyval.node = mk(nWord,yypvt[-0].keyword, NULL); } break;
case 56:
# line 132 "parse.y"
{ yyval.node = mk(nConcat,yypvt[-2].node,yypvt[-0].node); } break;
case 57:
# line 134 "parse.y"
{ yyval.node = mk(nVar,yypvt[-0].node); } break;
case 58:
# line 135 "parse.y"
{ yyval.node = mk(nVarsub,yypvt[-3].node,yypvt[-1].node); } break;
case 59:
# line 136 "parse.y"
{ yyval.node = mk(nCount,yypvt[-0].node); } break;
case 60:
# line 137 "parse.y"
{ yyval.node = mk(nFlat, yypvt[-0].node); } break;
case 61:
# line 138 "parse.y"
{ yyval.node = mk(nBackq,nolist,yypvt[-0].node); } break;
case 62:
# line 139 "parse.y"
{ yyval.node = mk(nBackq,nolist,yypvt[-0].node); } break;
case 63:
# line 140 "parse.y"
{ yyval.node = mk(nBackq,yypvt[-1].node,yypvt[-0].node); } break;
case 64:
# line 141 "parse.y"
{ yyval.node = mk(nBackq,yypvt[-1].node,yypvt[-0].node); } break;
case 65:
# line 142 "parse.y"
{ yyval.node = yypvt[-1].node; } break;
case 66:
# line 143 "parse.y"
{ yyval.node = mk(nNmpipe,yypvt[-1].redir.type,yypvt[-1].redir.fd,yypvt[-0].node); } break;
case 67:
# line 144 "parse.y"
{ yyval.node = (yypvt[-0].word.w[0] == '\'') ? mk(nQword, yypvt[-0].word.w+1, NULL) : mk(nWord,yypvt[-0].word.w, yypvt[-0].word.m); } break;
case 68:
# line 146 "parse.y"
{ yyval.keyword = "for"; } break;
case 69:
# line 147 "parse.y"
{ yyval.keyword = "in"; } break;
case 70:
# line 148 "parse.y"
{ yyval.keyword = "while"; } break;
case 71:
# line 149 "parse.y"
{ yyval.keyword = "if"; } break;
case 72:
# line 150 "parse.y"
{ yyval.keyword = "switch"; } break;
case 73:
# line 151 "parse.y"
{ yyval.keyword = "fn"; } break;
case 74:
# line 152 "parse.y"
{ yyval.keyword = "else"; } break;
case 75:
# line 153 "parse.y"
{ yyval.keyword = "case"; } break;
case 76:
# line 154 "parse.y"
{ yyval.keyword = "~"; } break;
case 77:
# line 155 "parse.y"
{ yyval.keyword = "!"; } break;
case 78:
# line 156 "parse.y"
{ yyval.keyword = "@"; } break;
case 79:
# line 158 "parse.y"
{ yyval.node = NULL; } break;
case 80:
# line 159 "parse.y"
{ yyval.node = (yypvt[-1].node != NULL ? (yypvt[-0].node != NULL ? mk(nLappend,yypvt[-1].node,yypvt[-0].node) : yypvt[-1].node) : yypvt[-0].node); } break;
case 81:
# line 161 "parse.y"
{ yyval.node = NULL; } break;
case 83:
# line 163 "parse.y"
{ yyval.node = (yypvt[-1].node != NULL ? (yypvt[-0].node != NULL ? mk(nLappend,yypvt[-1].node,yypvt[-0].node) : yypvt[-1].node) : yypvt[-0].node); } break;
# line	532 "/usr/ccs/bin/yaccpar"
	}
	goto yystack;		/* reset registers in driver code */
}

