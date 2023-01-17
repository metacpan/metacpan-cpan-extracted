/* -*- Mode: C++; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
 * This file is part of the LibreOffice project.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This file incorporates work covered by the following license notice:
 *
 *   Licensed to the Apache Software Foundation (ASF) under one or more
 *   contributor license agreements. See the NOTICE file distributed
 *   with this work for additional information regarding copyright
 *   ownership. The ASF licenses this file to you under the Apache
 *   License, Version 2.0 (the "License"); you may not use this file
 *   except in compliance with the License. You may obtain a copy of
 *   the License at http://www.apache.org/licenses/LICENSE-2.0 .
 */


/*  A Bison parser, made from grammar.y
    by GNU Bison version 1.28  */

#ifndef YYDEBUG
#define YYDEBUG 0
#endif
#ifndef YYMAXDEPTH
#define YYMAXDEPTH 0
#endif

#include <vector>
#include <stdlib.h>
#include <string.h>

#include "grammar.hxx"
#include "lexer.hxx"
#include "nodes.h"

extern "C" {
#include "grammar.h"
}

std::vector<std::unique_ptr<Node>> nodelist;

static void yyerror(const char *);

static Node *top=nullptr;

int Node::count = 0;

#ifdef PARSE_DEBUG
#define debug printf
#else
static int debug(const char *format, ...);
#endif

#include <stdio.h>

#define YYFINAL     102
#define YYFLAG      -32768
#define YYNTBASE    43

#define YYTRANSLATE(x) (static_cast<unsigned>(x) <= 285 ? yytranslate[x] : 66)

static const char yytranslate[] = {     0,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,    33,
    37,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,    36,
     2,    40,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
    34,     2,    38,    42,    41,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
     2,     2,    35,    32,    39,     2,     2,     2,     2,     2,
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
     2,     2,     2,     2,     2,     1,     3,     4,     5,     6,
     7,     8,     9,    10,    11,    12,    13,    14,    15,    16,
    17,    18,    19,    20,    21,    22,    23,    24,    25,    26,
    27,    28,    29,    30,    31
};

#if YYDEBUG != 0
static const short yyprhs[] = {     0,
     0,     2,     4,     6,     8,    10,    12,    14,    16,    18,
    20,    22,    24,    26,    28,    30,    32,    34,    36,    39,
    42,    45,    48,    51,    54,    58,    60,    63,    66,    69,
    72,    75,    79,    81,    85,    89,    92,    96,    99,   103,
   106,   110,   114,   120,   124,   130,   132,   135,   137,   140,
   143,   147,   150,   154,   157,   159,   161,   165,   167,   169,
   172,   174,   176,   178,   180,   182,   184,   186,   188,   190,
   192,   194
};

static const short yyrhs[] = {     4,
     0,     9,     0,    10,     0,     5,     0,    11,     0,    12,
     0,    20,     0,    21,     0,     7,     0,     6,     0,    23,
     0,    17,     0,    18,     0,     8,     0,    32,     0,    31,
     0,    22,     0,    43,     0,    44,    43,     0,    26,    33,
     0,    26,    34,     0,    26,    35,     0,    26,    36,     0,
    26,    32,     0,    26,    32,    32,     0,    29,     0,    27,
    37,     0,    27,    38,     0,    27,    39,     0,    27,    40,
     0,    27,    32,     0,    27,    32,    32,     0,    30,     0,
    45,    64,    46,     0,    33,    64,    37,     0,    33,    37,
     0,    35,    64,    39,     0,    35,    39,     0,    34,    64,
    38,     0,    34,    38,     0,    65,    41,    65,     0,    65,
    42,    65,     0,    65,    41,    49,    42,    49,     0,    14,
    49,    49,     0,    35,    64,    16,    64,    39,     0,     3,
     0,    54,    49,     0,    19,     0,    56,    49,     0,    13,
    49,     0,    13,    50,    49,     0,    24,    49,     0,    24,
    49,    49,     0,    25,    49,     0,    62,     0,    63,     0,
    62,    28,    63,     0,    64,     0,    65,     0,    64,    65,
     0,    49,     0,    48,     0,    47,     0,    51,     0,    52,
     0,    53,     0,    57,     0,    58,     0,    55,     0,    44,
     0,    59,     0,    60,     0
};

#endif

#if YYDEBUG != 0
static const short yyrline[] = { 0,
    59,    61,    62,    63,    64,    65,    66,    67,    68,    69,
    70,    71,    72,    73,    74,    75,    76,    79,    81,    84,
    86,    87,    88,    89,    90,    91,    94,    96,    97,    98,
    99,   100,   101,   104,   108,   110,   113,   115,   118,   120,
   123,   125,   126,   129,   133,   138,   142,   145,   149,   153,
   155,   158,   160,   163,   168,   172,   174,   177,   181,   183,
   186,   188,   189,   190,   191,   192,   193,   194,   195,   196,
   197,   198
};
#endif


#if YYDEBUG != 0 || defined (YYERROR_VERBOSE)

static const char * const yytname[] = {   "$","error","$undefined.","ACCENT",
"SMALL_GREEK","CAPITAL_GREEK","BINARY_OPERATOR","RELATION_OPERATOR","ARROW",
"GENERAL_IDEN","GENERAL_OPER","BIG_SYMBOL","FUNCTION","ROOT","FRACTION","SUBSUP",
"EQOVER","DELIMETER","LARGE_DELIM","DECORATION","SPACE_SYMBOL","CHARACTER","STRING",
"OPERATOR","EQBEGIN","EQEND","EQLEFT","EQRIGHT","NEWLINE","LEFT_DELIM","RIGHT_DELIM",
"DIGIT","'|'","'('","'['","'{'","'<'","')'","']'","'}'","'>'","'_'","'^'","Identifier",
"PrimaryExpr","EQLeft","EQRight","Fence","Parenth","Block","Bracket","SubSupExpr",
"FractionExpr","OverExpr","Accent","AccentExpr","Decoration","DecorationExpr",
"RootExpr","BeginExpr","EndExpr","MathML","Lines","Line","ExprList","Expr", NULL
};
#endif

static const short yyr1[] = {     0,
    43,    43,    43,    43,    43,    43,    43,    43,    43,    43,
    43,    43,    43,    43,    43,    43,    43,    44,    44,    45,
    45,    45,    45,    45,    45,    45,    46,    46,    46,    46,
    46,    46,    46,    47,    48,    48,    49,    49,    50,    50,
    51,    51,    51,    52,    53,    54,    55,    56,    57,    58,
    58,    59,    59,    60,    61,    62,    62,    63,    64,    64,
    65,    65,    65,    65,    65,    65,    65,    65,    65,    65,
    65,    65
};

static const short yyr2[] = {     0,
     1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
     1,     1,     1,     1,     1,     1,     1,     1,     2,     2,
     2,     2,     2,     2,     3,     1,     2,     2,     2,     2,
     2,     3,     1,     3,     3,     2,     3,     2,     3,     2,
     3,     3,     5,     3,     5,     1,     2,     1,     2,     2,
     3,     2,     3,     2,     1,     1,     3,     1,     1,     2,
     1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
     1,     1
};

static const short yydefact[] = {     0,
    46,     1,     4,    10,     9,    14,     2,     3,     5,     6,
     0,     0,    12,    13,    48,     7,     8,    17,    11,     0,
     0,     0,    26,    16,    15,     0,     0,    18,    70,     0,
    63,    62,    61,    64,    65,    66,     0,    69,     0,    67,
    68,    71,    72,    55,    56,    58,    59,     0,     0,    50,
     0,     0,    52,    54,    24,    20,    21,    22,    23,    36,
     0,    38,     0,    19,     0,    47,    49,     0,    60,     0,
     0,    40,     0,     0,    51,    44,    53,    25,    35,     0,
    37,     0,    33,    34,    57,    61,    41,    42,    39,     0,
    31,    27,    28,    29,    30,     0,    45,    32,    43,     0,
     0,     0
};

static const short yydefgoto[] = {    28,
    29,    30,    84,    31,    32,    33,    51,    34,    35,    36,
    37,    38,    39,    40,    41,    42,    43,   100,    44,    45,
    46,    47
};

static const short yypact[] = {   393,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,
   -30,   -19,-32768,-32768,-32768,-32768,-32768,-32768,-32768,   -19,
   -19,    -3,-32768,-32768,-32768,   290,   107,-32768,   425,   393,
-32768,-32768,-32768,-32768,-32768,-32768,   -19,-32768,   -19,-32768,
-32768,-32768,-32768,   -20,-32768,   393,   -21,   218,   107,-32768,
   -19,   -19,   -19,-32768,   -15,-32768,-32768,-32768,-32768,-32768,
   325,-32768,    70,-32768,   360,-32768,-32768,   393,   -21,   393,
   393,-32768,   254,   144,-32768,-32768,-32768,-32768,-32768,   393,
-32768,   -25,-32768,-32768,-32768,   -31,   -21,   -21,-32768,   181,
   -14,-32768,-32768,-32768,-32768,   -19,-32768,-32768,-32768,    22,
    23,-32768
};

static const short yypgoto[] = {    -2,
-32768,-32768,-32768,-32768,-32768,   -11,-32768,-32768,-32768,-32768,
-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,   -33,
   -24,   -27
};


#define YYLAST      457


static const short yytable[] = {    50,
    52,    61,    63,    48,    49,    65,    91,    68,    53,    54,
    96,    92,    93,    94,    95,    49,    78,    98,    69,    70,
    71,   101,   102,    73,    74,    66,    64,    67,    55,    56,
    57,    58,    59,    69,    85,    69,     0,    69,     0,    75,
    76,    77,    87,    88,     0,    69,    69,     0,     0,     0,
     0,     0,     0,     0,     0,    90,     0,     0,    86,     0,
     0,     0,    69,     0,     0,     0,     0,     0,     0,     0,
     0,     0,     1,     2,     3,     4,     5,     6,     7,     8,
     9,    10,    11,    12,    99,    80,    13,    14,    15,    16,
    17,    18,    19,    20,    21,    22,     0,     0,    23,     0,
    24,    25,    26,     0,    27,     0,     0,     0,    81,     1,
     2,     3,     4,     5,     6,     7,     8,     9,    10,    11,
    12,     0,     0,    13,    14,    15,    16,    17,    18,    19,
    20,    21,    22,     0,     0,    23,     0,    24,    25,    26,
     0,    27,     0,     0,     0,    62,     1,     2,     3,     4,
     5,     6,     7,     8,     9,    10,    11,    12,     0,     0,
    13,    14,    15,    16,    17,    18,    19,    20,    21,    22,
     0,     0,    23,     0,    24,    25,    26,     0,    27,     0,
     0,     0,    81,     1,     2,     3,     4,     5,     6,     7,
     8,     9,    10,    11,    12,     0,     0,    13,    14,    15,
    16,    17,    18,    19,    20,    21,    22,     0,     0,    23,
     0,    24,    25,    26,     0,    27,     0,     0,     0,    97,
     1,     2,     3,     4,     5,     6,     7,     8,     9,    10,
    11,    12,     0,     0,    13,    14,    15,    16,    17,    18,
    19,    20,    21,    22,     0,     0,    23,     0,    24,    25,
    26,     0,    27,     0,     0,    72,     1,     2,     3,     4,
     5,     6,     7,     8,     9,    10,    11,    12,     0,     0,
    13,    14,    15,    16,    17,    18,    19,    20,    21,    22,
     0,     0,    23,     0,    24,    25,    26,     0,    27,     0,
     0,    89,     1,     2,     3,     4,     5,     6,     7,     8,
     9,    10,    11,    12,     0,     0,    13,    14,    15,    16,
    17,    18,    19,    20,    21,    22,     0,     0,    23,     0,
    24,    25,    26,     0,    27,     0,    60,     1,     2,     3,
     4,     5,     6,     7,     8,     9,    10,    11,    12,     0,
     0,    13,    14,    15,    16,    17,    18,    19,    20,    21,
    22,     0,     0,    23,     0,    24,    25,    26,     0,    27,
     0,    79,     1,     2,     3,     4,     5,     6,     7,     8,
     9,    10,    11,    12,     0,     0,    13,    14,    15,    16,
    17,    18,    19,    20,    21,    22,    82,     0,    23,    83,
    24,    25,    26,     0,    27,     1,     2,     3,     4,     5,
     6,     7,     8,     9,    10,    11,    12,     0,     0,    13,
    14,    15,    16,    17,    18,    19,    20,    21,    22,     0,
     0,    23,     0,    24,    25,    26,     0,    27,     2,     3,
     4,     5,     6,     7,     8,     9,    10,     0,     0,     0,
     0,    13,    14,     0,    16,    17,    18,    19,     0,     0,
     0,     0,     0,     0,     0,    24,    25
};

static const short yycheck[] = {    11,
    12,    26,    27,    34,    35,    30,    32,    28,    20,    21,
    42,    37,    38,    39,    40,    35,    32,    32,    46,    41,
    42,     0,     0,    48,    49,    37,    29,    39,    32,    33,
    34,    35,    36,    61,    68,    63,    -1,    65,    -1,    51,
    52,    53,    70,    71,    -1,    73,    74,    -1,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    80,    -1,    -1,    70,    -1,
    -1,    -1,    90,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
    -1,    -1,     3,     4,     5,     6,     7,     8,     9,    10,
    11,    12,    13,    14,    96,    16,    17,    18,    19,    20,
    21,    22,    23,    24,    25,    26,    -1,    -1,    29,    -1,
    31,    32,    33,    -1,    35,    -1,    -1,    -1,    39,     3,
     4,     5,     6,     7,     8,     9,    10,    11,    12,    13,
    14,    -1,    -1,    17,    18,    19,    20,    21,    22,    23,
    24,    25,    26,    -1,    -1,    29,    -1,    31,    32,    33,
    -1,    35,    -1,    -1,    -1,    39,     3,     4,     5,     6,
     7,     8,     9,    10,    11,    12,    13,    14,    -1,    -1,
    17,    18,    19,    20,    21,    22,    23,    24,    25,    26,
    -1,    -1,    29,    -1,    31,    32,    33,    -1,    35,    -1,
    -1,    -1,    39,     3,     4,     5,     6,     7,     8,     9,
    10,    11,    12,    13,    14,    -1,    -1,    17,    18,    19,
    20,    21,    22,    23,    24,    25,    26,    -1,    -1,    29,
    -1,    31,    32,    33,    -1,    35,    -1,    -1,    -1,    39,
     3,     4,     5,     6,     7,     8,     9,    10,    11,    12,
    13,    14,    -1,    -1,    17,    18,    19,    20,    21,    22,
    23,    24,    25,    26,    -1,    -1,    29,    -1,    31,    32,
    33,    -1,    35,    -1,    -1,    38,     3,     4,     5,     6,
     7,     8,     9,    10,    11,    12,    13,    14,    -1,    -1,
    17,    18,    19,    20,    21,    22,    23,    24,    25,    26,
    -1,    -1,    29,    -1,    31,    32,    33,    -1,    35,    -1,
    -1,    38,     3,     4,     5,     6,     7,     8,     9,    10,
    11,    12,    13,    14,    -1,    -1,    17,    18,    19,    20,
    21,    22,    23,    24,    25,    26,    -1,    -1,    29,    -1,
    31,    32,    33,    -1,    35,    -1,    37,     3,     4,     5,
     6,     7,     8,     9,    10,    11,    12,    13,    14,    -1,
    -1,    17,    18,    19,    20,    21,    22,    23,    24,    25,
    26,    -1,    -1,    29,    -1,    31,    32,    33,    -1,    35,
    -1,    37,     3,     4,     5,     6,     7,     8,     9,    10,
    11,    12,    13,    14,    -1,    -1,    17,    18,    19,    20,
    21,    22,    23,    24,    25,    26,    27,    -1,    29,    30,
    31,    32,    33,    -1,    35,     3,     4,     5,     6,     7,
     8,     9,    10,    11,    12,    13,    14,    -1,    -1,    17,
    18,    19,    20,    21,    22,    23,    24,    25,    26,    -1,
    -1,    29,    -1,    31,    32,    33,    -1,    35,     4,     5,
     6,     7,     8,     9,    10,    11,    12,    -1,    -1,    -1,
    -1,    17,    18,    -1,    20,    21,    22,    23,    -1,    -1,
    -1,    -1,    -1,    -1,    -1,    31,    32
};
/* This file comes from bison-1.28.  */

/* Skeleton output parser for bison,
   Copyright (C) 1984, 1989, 1990 Free Software Foundation, Inc.

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
   Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.  */

/* As a special exception, when this file is copied by Bison into a
   Bison output file, you may use that output file without restriction.
   This special exception was added by the Free Software Foundation
   in version 1.24 of Bison.  */

/* This is the parser code that is written into each bison parser
  when the %semantic_parser declaration is not specified in the grammar.
  It was written by Richard Stallman by simplifying the hairy parser
  used when %semantic_parser is specified.  */

/* Note: there must be only one dollar sign in this file.
   It is replaced by the list of actions, each action
   as one case of the switch.  */

#define YYEMPTY     -2
#define YYEOF       0
#define YYACCEPT    goto yyacceptlab
#define YYABORT     goto yyabortlab
