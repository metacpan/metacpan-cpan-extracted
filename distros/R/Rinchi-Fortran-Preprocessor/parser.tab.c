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
#define YYPURE 0

/* Using locations.  */
#define YYLSP_NEEDED 1

/* Substitute the variable and function names.  */
#define yyparse yypp_parse
#define yylex   yypp_lex
#define yyerror yypp_error
#define yylval  yypp_lval
#define yychar  yypp_char
#define yydebug yypp_debug
#define yynerrs yypp_nerrs
#define yylloc yypp_lloc

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     ECS_NULL = 258,
     ASC_SOH = 259,
     ASC_STX = 260,
     ASC_ETX = 261,
     ASC_EOT = 262,
     ASC_ENQ = 263,
     ASC_ACK = 264,
     ECS_ALERT = 265,
     ECS_BACKSPACE = 266,
     BCS_WHTSP_TAB = 267,
     BCS_WHTSP_NEWLINE = 268,
     BCS_WHTSP_VERTICAL_TAB = 269,
     BCS_WHTSP_FORMFEED = 270,
     ECS_CARRIAGE_RETURN = 271,
     ASC_SHIFT_OUT = 272,
     ASC_SHIFT_IN = 273,
     ASC_DLE = 274,
     ASC_DC1 = 275,
     ASC_DC2 = 276,
     ASC_DC3 = 277,
     ASC_DC4 = 278,
     ASC_NAK = 279,
     ASC_SYN = 280,
     ASC_ETB = 281,
     ASC_CAN = 282,
     ASC_EM = 283,
     ASC_SUB = 284,
     ASC_ESC = 285,
     ASC_IS4 = 286,
     ASC_IS3 = 287,
     ASC_IS2 = 288,
     ASC_IS1 = 289,
     BCS_WHTSP_SPACE = 290,
     BCS_PUNCT_EXCLAMATION = 291,
     BCS_PUNCT_QUOTE = 292,
     BCS_PUNCT_HASH = 293,
     ASC_DOLLAR_SIGN = 294,
     BCS_PUNCT_PERCENT = 295,
     BCS_PUNCT_AMPERSAND = 296,
     BCS_PUNCT_APOSTROPHE = 297,
     BCS_PUNCT_OPEN_PARENTHESIS = 298,
     BCS_PUNCT_CLOSE_PARENTHESIS = 299,
     BCS_PUNCT_ASTERISK = 300,
     BCS_PUNCT_PLUS = 301,
     BCS_PUNCT_COMMA = 302,
     BCS_PUNCT_MINUS = 303,
     BCS_PUNCT_PERIOD = 304,
     BCS_PUNCT_SLASH = 305,
     BCS_DIGIT_0 = 306,
     BCS_DIGIT_1 = 307,
     BCS_DIGIT_2 = 308,
     BCS_DIGIT_3 = 309,
     BCS_DIGIT_4 = 310,
     BCS_DIGIT_5 = 311,
     BCS_DIGIT_6 = 312,
     BCS_DIGIT_7 = 313,
     BCS_DIGIT_8 = 314,
     BCS_DIGIT_9 = 315,
     BCS_PUNCT_COLON = 316,
     BCS_PUNCT_SEMICOLON = 317,
     BCS_PUNCT_LESS_THAN = 318,
     BCS_PUNCT_EQUAL = 319,
     BCS_PUNCT_GREATER_THAN = 320,
     BCS_PUNCT_QUESTION = 321,
     ASC_AT_SIGN = 322,
     BCS_UPPER_A = 323,
     BCS_UPPER_B = 324,
     BCS_UPPER_C = 325,
     BCS_UPPER_D = 326,
     BCS_UPPER_E = 327,
     BCS_UPPER_F = 328,
     BCS_UPPER_G = 329,
     BCS_UPPER_H = 330,
     BCS_UPPER_I = 331,
     BCS_UPPER_J = 332,
     BCS_UPPER_K = 333,
     BCS_UPPER_L = 334,
     BCS_UPPER_M = 335,
     BCS_UPPER_N = 336,
     BCS_UPPER_O = 337,
     BCS_UPPER_P = 338,
     BCS_UPPER_Q = 339,
     BCS_UPPER_R = 340,
     BCS_UPPER_S = 341,
     BCS_UPPER_T = 342,
     BCS_UPPER_U = 343,
     BCS_UPPER_V = 344,
     BCS_UPPER_W = 345,
     BCS_UPPER_X = 346,
     BCS_UPPER_Y = 347,
     BCS_UPPER_Z = 348,
     BCS_PUNCT_OPEN_BRACKET = 349,
     BCS_PUNCT_BACKSLASH = 350,
     BCS_PUNCT_CLOSE_BRACKET = 351,
     BCS_PUNCT_CARET = 352,
     BCS_PUNCT_UNDERSCORE = 353,
     BCS_LOWER_A = 354,
     BCS_LOWER_B = 355,
     BCS_LOWER_C = 356,
     BCS_LOWER_D = 357,
     BCS_LOWER_E = 358,
     BCS_LOWER_F = 359,
     BCS_LOWER_G = 360,
     BCS_LOWER_H = 361,
     BCS_LOWER_I = 362,
     BCS_LOWER_J = 363,
     BCS_LOWER_K = 364,
     BCS_LOWER_L = 365,
     BCS_LOWER_M = 366,
     BCS_LOWER_N = 367,
     BCS_LOWER_O = 368,
     BCS_LOWER_P = 369,
     BCS_LOWER_Q = 370,
     BCS_LOWER_R = 371,
     BCS_LOWER_S = 372,
     BCS_LOWER_T = 373,
     BCS_LOWER_U = 374,
     BCS_LOWER_V = 375,
     BCS_LOWER_W = 376,
     BCS_LOWER_X = 377,
     BCS_LOWER_Y = 378,
     BCS_LOWER_Z = 379,
     BCS_PUNCT_OPEN_BRACE = 380,
     BCS_PUNCT_VERTICAL_BAR = 381,
     BCS_PUNCT_CLOSE_BRACE = 382,
     BCS_PUNCT_TILDE = 383,
     ASC_DEL = 384,
     ALT_PUNCT_OPEN_BRACE = 385,
     ALT_PUNCT_CLOSE_BRACE = 386,
     ALT_PUNCT_OPEN_BRACKET = 387,
     ALT_PUNCT_CLOSE_BRACKET = 388,
     ALT_PUNCT_HASH = 389,
     PUNC_DBL_COLON = 390,
     PUNC_ARROW = 391,
     KWD_ABSTRACT = 392,
     KWD_ABSTRACT_INTERFACE = 393,
     KWD_ACCESS = 394,
     KWD_ACTION = 395,
     KWD_ADVANCE = 396,
     KWD_ALLOCATABLE = 397,
     KWD_ALLOCATE = 398,
     KWD_ASSIGN = 399,
     KWD_ASSOCIATE = 400,
     KWD_ASYNCHRONOUS = 401,
     KWD_BACKSPACE = 402,
     KWD_BIND = 403,
     KWD_BLANK = 404,
     KWD_BLOCK = 405,
     KWD_BLOCK_DATA = 406,
     KWD_CALL = 407,
     KWD_CASE = 408,
     KWD_CHARACTER = 409,
     KWD_CLASS = 410,
     KWD_CLASS_DEFAULT = 411,
     KWD_CLASS_IS = 412,
     KWD_CLOSE = 413,
     KWD_COMMON = 414,
     KWD_COMPLEX = 415,
     KWD_CONTAINS = 416,
     KWD_CONTIGUOUS = 417,
     KWD_CONTINUE = 418,
     KWD_CYCLE = 419,
     KWD_DATA = 420,
     KWD_DEALLOCATE = 421,
     KWD_DEFAULT = 422,
     KWD_DEFERRED = 423,
     KWD_DIMENSION = 424,
     KWD_DIRECT = 425,
     KWD_DO = 426,
     KWD_DOUBLE = 427,
     KWD_DOUBLE_COMPLEX = 428,
     KWD_DOUBLE_PRECISION = 429,
     KWD_ELEMENTAL = 430,
     KWD_ELSE = 431,
     KWD_ELSE_IF = 432,
     KWD_ELSE_WHERE = 433,
     KWD_ENCODING = 434,
     KWD_END = 435,
     KWD_END_ASSOCIATE = 436,
     KWD_END_BLOCK = 437,
     KWD_END_BLOCK_DATA = 438,
     KWD_END_DO = 439,
     KWD_END_ENUM = 440,
     KWD_END_FILE = 441,
     KWD_END_FORALL = 442,
     KWD_END_FUNCTION = 443,
     KWD_END_IF = 444,
     KWD_END_INTERFACE = 445,
     KWD_END_MODULE = 446,
     KWD_END_PROCEDURE = 447,
     KWD_END_PROGRAM = 448,
     KWD_END_SELECT = 449,
     KWD_END_SUBMODULE = 450,
     KWD_END_SUBROUTINE = 451,
     KWD_END_TYPE = 452,
     KWD_END_WHERE = 453,
     KWD_ENTRY = 454,
     KWD_EOR = 455,
     KWD_EQUIVALENCE = 456,
     KWD_ERR = 457,
     KWD_ERRMSG = 458,
     KWD_EXIST = 459,
     KWD_EXIT = 460,
     KWD_EXTENDS = 461,
     KWD_EXTENSIBLE = 462,
     KWD_EXTERNAL = 463,
     KWD_FALSE = 464,
     KWD_FILE = 465,
     KWD_FINAL = 466,
     KWD_FLUSH = 467,
     KWD_FMT = 468,
     KWD_FORALL = 469,
     KWD_FORM = 470,
     KWD_FORMAT = 471,
     KWD_FORMATTED = 472,
     KWD_FUNCTION = 473,
     KWD_GENERIC = 474,
     KWD_GOTO = 475,
     KWD_IF = 476,
     KWD_IMPLICIT = 477,
     KWD_IMPLICIT_NONE = 478,
     KWD_IMPORT = 479,
     KWD_IMPURE = 480,
     KWD_IN = 481,
     KWD_IN_OUT = 482,
     KWD_INCLUDE = 483,
     KWD_INQUIRE = 484,
     KWD_INTEGER = 485,
     KWD_INTENT = 486,
     KWD_INTERFACE = 487,
     KWD_INTRINSIC = 488,
     KWD_IOSTAT = 489,
     KWD_IOMSG = 490,
     KWD_KIND = 491,
     KWD_LET = 492,
     KWD_LOGICAL = 493,
     KWD_MODULE = 494,
     KWD_MOLD = 495,
     KWD_NAME = 496,
     KWD_NAMED = 497,
     KWD_NAMELIST = 498,
     KWD_NEXTREC = 499,
     KWD_NON_INTRINSIC = 500,
     KWD_NON_OVERRIDABLE = 501,
     KWD_NONKIND = 502,
     KWD_NONE = 503,
     KWD_NOPASS = 504,
     KWD_NULLIFY = 505,
     KWD_NUMBER = 506,
     KWD_OPEN = 507,
     KWD_OPENED = 508,
     KWD_OPERATOR = 509,
     KWD_OPTIONAL = 510,
     KWD_OUT = 511,
     KWD_PAD = 512,
     KWD_PARAMETER = 513,
     KWD_PASS = 514,
     KWD_PAUSE = 515,
     KWD_PENDING = 516,
     KWD_POINTER = 517,
     KWD_POSITION = 518,
     KWD_PRECISION = 519,
     KWD_PRINT = 520,
     KWD_PRIVATE = 521,
     KWD_PROCEDURE = 522,
     KWD_PROGRAM = 523,
     KWD_PROTECTED = 524,
     KWD_PUBLIC = 525,
     KWD_PURE = 526,
     KWD_READ = 527,
     KWD_READ_FORMATTED = 528,
     KWD_READ_UNFORMATTED = 529,
     KWD_READWRITE = 530,
     KWD_REAL = 531,
     KWD_REC = 532,
     KWD_RECL = 533,
     KWD_RETURN = 534,
     KWD_REWIND = 535,
     KWD_ROUND = 536,
     KWD_SAVE = 537,
     KWD_SELECT_CASE = 538,
     KWD_SELECT_TYPE = 539,
     KWD_SEQUENCE = 540,
     KWD_SEQUENTIAL = 541,
     KWD_SIGN = 542,
     KWD_SIZE = 543,
     KWD_SOURCE = 544,
     KWD_STATUS = 545,
     KWD_STOP = 546,
     KWD_STREAM = 547,
     KWD_SUBMODULE = 548,
     KWD_SUBROUTINE = 549,
     KWD_TARGET = 550,
     KWD_THEN = 551,
     KWD_TRUE = 552,
     KWD_TYPE = 553,
     KWD_UNFORMATTED = 554,
     KWD_UNIT = 555,
     KWD_USE = 556,
     KWD_VALUE = 557,
     KWD_VOLATILE = 558,
     KWD_WHERE = 559,
     KWD_WRITE = 560,
     KWD_WRITE_FORMATTED = 561,
     KWD_WRITE_UNFORMATTED = 562,
     PPD_NULL = 563,
     PPD_DEFINE = 564,
     PPD_ELIF = 565,
     PPD_ELSE = 566,
     PPD_ENDIF = 567,
     PPD_ERROR = 568,
     PPD_WARNING = 569,
     PPD_IF = 570,
     PPD_IFDEF = 571,
     PPD_IFNDEF = 572,
     PPD_INCLUDE = 573,
     PPD_LINE = 574,
     PPD_PRAGMA = 575,
     PPD_UNDEF = 576,
     OP_LOGICAL_NOT = 577,
     OP_NE = 578,
     OP_STRINGIZE = 579,
     OP_TOKEN_SPLICE = 580,
     OP_MODULO = 581,
     ALT_OP_TOKEN_SPLICE = 582,
     OP_ASSIGN_MODULO = 583,
     OP_BIT_AND = 584,
     OP_ADDRESS = 585,
     OP_LOGICAL_AND = 586,
     OP_ASSIGN_BIT_AND = 587,
     OP_DEREFERENCE = 588,
     OP_MULTIPLY = 589,
     OP_ASSIGN_MULTIPLY = 590,
     OP_PLUS = 591,
     OP_INCREMENT = 592,
     OP_ASSIGN_PLUS = 593,
     OP_MINUS = 594,
     OP_DECREMENT = 595,
     OP_ASSIGN_MINUS = 596,
     OP_POINTER_MEMBER = 597,
     OP_POINTER_POINTER_TO_MEMBER = 598,
     OP_OBJECT_MEMBER = 599,
     OP_OBJECT_POINTER_TO_MEMBER = 600,
     OP_DIVIDE = 601,
     OP_ASSIGN_DIVIDE = 602,
     OP_ELSE = 603,
     OP_LT = 604,
     OP_SHIFT_LEFT = 605,
     OP_ASSIGN_SHIFT_LEFT = 606,
     OP_LE = 607,
     OP_ASSIGN = 608,
     OP_EQ = 609,
     OP_GT = 610,
     OP_GE = 611,
     OP_SHIFT_RIGHT = 612,
     OP_ASSIGN_SHIFT_RIGHT = 613,
     OP_CONDITIONAL = 614,
     OP_BIT_PLUS = 615,
     OP_ASSIGN_BIT_PLUS = 616,
     OP_BIT_OR = 617,
     OP_ASSIGN_BIT_OR = 618,
     OP_LOGICAL_OR = 619,
     OP_BIT_NOT = 620,
     OP_ALT_LOGICAL_AND = 621,
     OP_ALT_ASSIGN_BIT_AND = 622,
     OP_ALT_BIT_AND = 623,
     OP_ALT_BIT_OR = 624,
     OP_ALT_BIT_NOT = 625,
     OP_ALT_LOGICAL_NOT = 626,
     OP_ALT_NE = 627,
     OP_ALT_LOGICAL_OR = 628,
     OP_ALT_ASSIGN_BIT_OR = 629,
     OP_ALT_BIT_PLUS = 630,
     OP_ALT_ASSIGN_BIT_PLUS = 631,
     OPEN_PARENTHESIS_SLASH = 632,
     CLOSE_PARENTHESIS_SLASH = 633,
     INV_ALT_LOGICAL_AND = 634,
     INV_ALT_ASSIGN_BIT_AND = 635,
     INV_ALT_BIT_AND = 636,
     INV_ALT_BIT_OR = 637,
     INV_ALT_BIT_NOT = 638,
     INV_ALT_LOGICAL_NOT = 639,
     INV_ALT_NE = 640,
     INV_ALT_LOGICAL_OR = 641,
     INV_ALT_ASSIGN_BIT_OR = 642,
     INV_ALT_BIT_PLUS = 643,
     INV_ALT_ASSIGN_BIT_PLUS = 644,
     INV_MFI_LOGICAL_AND = 645,
     INV_MFI_ASSIGN_BIT_AND = 646,
     INV_MFI_BIT_AND = 647,
     INV_MFI_BIT_OR = 648,
     INV_MFI_BIT_NOT = 649,
     INV_MFI_LOGICAL_NOT = 650,
     INV_MFI_NE = 651,
     INV_MFI_LOGICAL_OR = 652,
     INV_MFI_ASSIGN_BIT_OR = 653,
     INV_MFI_BIT_PLUS = 654,
     INV_MFI_ASSIGN_BIT_PLUS = 655,
     DECL_REFERENCE = 656,
     DECL_POINTER = 657,
     DECL_VAR_ARGS = 658,
     WHITE_SPACE = 659,
     SYSTEM_HEADER_STRING = 660,
     HEADER_STRING = 661,
     IDENTIFIER = 662,
     NON_REPLACEABLE_IDENTIFIER = 663,
     MACRO_FUNCTION_IDENTIFIER = 664,
     MACRO_OBJECT_IDENTIFIER = 665,
     PP_NUMBER = 666,
     CHARACTER_LITERAL = 667,
     L_CHARACTER_LITERAL = 668,
     STRING_LITERAL = 669,
     L_STRING_LITERAL = 670,
     INTEGER_LITERAL = 671,
     OCTAL_LITERAL = 672,
     DECIMAL_LITERAL = 673,
     HEXADECIMAL_LITERAL = 674,
     FLOATING_LITERAL = 675,
     UNIVERSAL_CHARACTER_NAME = 676,
     USE_ON_CODE = 677,
     PUNC_INITIALIZE = 678,
     PUNC_SYNONYM = 679,
     DONT_CARE = 680,
     RESERVED_WORD = 681,
     ACCESS_SPECIFIER = 682,
     BOOLEAN_LITERAL = 683,
     CV_QUALIFIER = 684,
     INTRINSIC_TYPE = 685,
     FUNCTION_SPECIFIER = 686,
     STORAGE_CLASS_SPECIFIER = 687,
     USER_TOKEN = 688,
     SYMBOL = 689,
     COMMENT = 690,
     BLOCK_COMMENT = 691,
     END_OF_STATEMENT = 692,
     BLOCK_OPEN = 693,
     BLOCK_CLOSE = 694,
     LIST_OPEN = 695,
     LIST_SEPARATOR = 696,
     LIST_CLOSE = 697
   };
#endif
/* Tokens.  */
#define ECS_NULL 258
#define ASC_SOH 259
#define ASC_STX 260
#define ASC_ETX 261
#define ASC_EOT 262
#define ASC_ENQ 263
#define ASC_ACK 264
#define ECS_ALERT 265
#define ECS_BACKSPACE 266
#define BCS_WHTSP_TAB 267
#define BCS_WHTSP_NEWLINE 268
#define BCS_WHTSP_VERTICAL_TAB 269
#define BCS_WHTSP_FORMFEED 270
#define ECS_CARRIAGE_RETURN 271
#define ASC_SHIFT_OUT 272
#define ASC_SHIFT_IN 273
#define ASC_DLE 274
#define ASC_DC1 275
#define ASC_DC2 276
#define ASC_DC3 277
#define ASC_DC4 278
#define ASC_NAK 279
#define ASC_SYN 280
#define ASC_ETB 281
#define ASC_CAN 282
#define ASC_EM 283
#define ASC_SUB 284
#define ASC_ESC 285
#define ASC_IS4 286
#define ASC_IS3 287
#define ASC_IS2 288
#define ASC_IS1 289
#define BCS_WHTSP_SPACE 290
#define BCS_PUNCT_EXCLAMATION 291
#define BCS_PUNCT_QUOTE 292
#define BCS_PUNCT_HASH 293
#define ASC_DOLLAR_SIGN 294
#define BCS_PUNCT_PERCENT 295
#define BCS_PUNCT_AMPERSAND 296
#define BCS_PUNCT_APOSTROPHE 297
#define BCS_PUNCT_OPEN_PARENTHESIS 298
#define BCS_PUNCT_CLOSE_PARENTHESIS 299
#define BCS_PUNCT_ASTERISK 300
#define BCS_PUNCT_PLUS 301
#define BCS_PUNCT_COMMA 302
#define BCS_PUNCT_MINUS 303
#define BCS_PUNCT_PERIOD 304
#define BCS_PUNCT_SLASH 305
#define BCS_DIGIT_0 306
#define BCS_DIGIT_1 307
#define BCS_DIGIT_2 308
#define BCS_DIGIT_3 309
#define BCS_DIGIT_4 310
#define BCS_DIGIT_5 311
#define BCS_DIGIT_6 312
#define BCS_DIGIT_7 313
#define BCS_DIGIT_8 314
#define BCS_DIGIT_9 315
#define BCS_PUNCT_COLON 316
#define BCS_PUNCT_SEMICOLON 317
#define BCS_PUNCT_LESS_THAN 318
#define BCS_PUNCT_EQUAL 319
#define BCS_PUNCT_GREATER_THAN 320
#define BCS_PUNCT_QUESTION 321
#define ASC_AT_SIGN 322
#define BCS_UPPER_A 323
#define BCS_UPPER_B 324
#define BCS_UPPER_C 325
#define BCS_UPPER_D 326
#define BCS_UPPER_E 327
#define BCS_UPPER_F 328
#define BCS_UPPER_G 329
#define BCS_UPPER_H 330
#define BCS_UPPER_I 331
#define BCS_UPPER_J 332
#define BCS_UPPER_K 333
#define BCS_UPPER_L 334
#define BCS_UPPER_M 335
#define BCS_UPPER_N 336
#define BCS_UPPER_O 337
#define BCS_UPPER_P 338
#define BCS_UPPER_Q 339
#define BCS_UPPER_R 340
#define BCS_UPPER_S 341
#define BCS_UPPER_T 342
#define BCS_UPPER_U 343
#define BCS_UPPER_V 344
#define BCS_UPPER_W 345
#define BCS_UPPER_X 346
#define BCS_UPPER_Y 347
#define BCS_UPPER_Z 348
#define BCS_PUNCT_OPEN_BRACKET 349
#define BCS_PUNCT_BACKSLASH 350
#define BCS_PUNCT_CLOSE_BRACKET 351
#define BCS_PUNCT_CARET 352
#define BCS_PUNCT_UNDERSCORE 353
#define BCS_LOWER_A 354
#define BCS_LOWER_B 355
#define BCS_LOWER_C 356
#define BCS_LOWER_D 357
#define BCS_LOWER_E 358
#define BCS_LOWER_F 359
#define BCS_LOWER_G 360
#define BCS_LOWER_H 361
#define BCS_LOWER_I 362
#define BCS_LOWER_J 363
#define BCS_LOWER_K 364
#define BCS_LOWER_L 365
#define BCS_LOWER_M 366
#define BCS_LOWER_N 367
#define BCS_LOWER_O 368
#define BCS_LOWER_P 369
#define BCS_LOWER_Q 370
#define BCS_LOWER_R 371
#define BCS_LOWER_S 372
#define BCS_LOWER_T 373
#define BCS_LOWER_U 374
#define BCS_LOWER_V 375
#define BCS_LOWER_W 376
#define BCS_LOWER_X 377
#define BCS_LOWER_Y 378
#define BCS_LOWER_Z 379
#define BCS_PUNCT_OPEN_BRACE 380
#define BCS_PUNCT_VERTICAL_BAR 381
#define BCS_PUNCT_CLOSE_BRACE 382
#define BCS_PUNCT_TILDE 383
#define ASC_DEL 384
#define ALT_PUNCT_OPEN_BRACE 385
#define ALT_PUNCT_CLOSE_BRACE 386
#define ALT_PUNCT_OPEN_BRACKET 387
#define ALT_PUNCT_CLOSE_BRACKET 388
#define ALT_PUNCT_HASH 389
#define PUNC_DBL_COLON 390
#define PUNC_ARROW 391
#define KWD_ABSTRACT 392
#define KWD_ABSTRACT_INTERFACE 393
#define KWD_ACCESS 394
#define KWD_ACTION 395
#define KWD_ADVANCE 396
#define KWD_ALLOCATABLE 397
#define KWD_ALLOCATE 398
#define KWD_ASSIGN 399
#define KWD_ASSOCIATE 400
#define KWD_ASYNCHRONOUS 401
#define KWD_BACKSPACE 402
#define KWD_BIND 403
#define KWD_BLANK 404
#define KWD_BLOCK 405
#define KWD_BLOCK_DATA 406
#define KWD_CALL 407
#define KWD_CASE 408
#define KWD_CHARACTER 409
#define KWD_CLASS 410
#define KWD_CLASS_DEFAULT 411
#define KWD_CLASS_IS 412
#define KWD_CLOSE 413
#define KWD_COMMON 414
#define KWD_COMPLEX 415
#define KWD_CONTAINS 416
#define KWD_CONTIGUOUS 417
#define KWD_CONTINUE 418
#define KWD_CYCLE 419
#define KWD_DATA 420
#define KWD_DEALLOCATE 421
#define KWD_DEFAULT 422
#define KWD_DEFERRED 423
#define KWD_DIMENSION 424
#define KWD_DIRECT 425
#define KWD_DO 426
#define KWD_DOUBLE 427
#define KWD_DOUBLE_COMPLEX 428
#define KWD_DOUBLE_PRECISION 429
#define KWD_ELEMENTAL 430
#define KWD_ELSE 431
#define KWD_ELSE_IF 432
#define KWD_ELSE_WHERE 433
#define KWD_ENCODING 434
#define KWD_END 435
#define KWD_END_ASSOCIATE 436
#define KWD_END_BLOCK 437
#define KWD_END_BLOCK_DATA 438
#define KWD_END_DO 439
#define KWD_END_ENUM 440
#define KWD_END_FILE 441
#define KWD_END_FORALL 442
#define KWD_END_FUNCTION 443
#define KWD_END_IF 444
#define KWD_END_INTERFACE 445
#define KWD_END_MODULE 446
#define KWD_END_PROCEDURE 447
#define KWD_END_PROGRAM 448
#define KWD_END_SELECT 449
#define KWD_END_SUBMODULE 450
#define KWD_END_SUBROUTINE 451
#define KWD_END_TYPE 452
#define KWD_END_WHERE 453
#define KWD_ENTRY 454
#define KWD_EOR 455
#define KWD_EQUIVALENCE 456
#define KWD_ERR 457
#define KWD_ERRMSG 458
#define KWD_EXIST 459
#define KWD_EXIT 460
#define KWD_EXTENDS 461
#define KWD_EXTENSIBLE 462
#define KWD_EXTERNAL 463
#define KWD_FALSE 464
#define KWD_FILE 465
#define KWD_FINAL 466
#define KWD_FLUSH 467
#define KWD_FMT 468
#define KWD_FORALL 469
#define KWD_FORM 470
#define KWD_FORMAT 471
#define KWD_FORMATTED 472
#define KWD_FUNCTION 473
#define KWD_GENERIC 474
#define KWD_GOTO 475
#define KWD_IF 476
#define KWD_IMPLICIT 477
#define KWD_IMPLICIT_NONE 478
#define KWD_IMPORT 479
#define KWD_IMPURE 480
#define KWD_IN 481
#define KWD_IN_OUT 482
#define KWD_INCLUDE 483
#define KWD_INQUIRE 484
#define KWD_INTEGER 485
#define KWD_INTENT 486
#define KWD_INTERFACE 487
#define KWD_INTRINSIC 488
#define KWD_IOSTAT 489
#define KWD_IOMSG 490
#define KWD_KIND 491
#define KWD_LET 492
#define KWD_LOGICAL 493
#define KWD_MODULE 494
#define KWD_MOLD 495
#define KWD_NAME 496
#define KWD_NAMED 497
#define KWD_NAMELIST 498
#define KWD_NEXTREC 499
#define KWD_NON_INTRINSIC 500
#define KWD_NON_OVERRIDABLE 501
#define KWD_NONKIND 502
#define KWD_NONE 503
#define KWD_NOPASS 504
#define KWD_NULLIFY 505
#define KWD_NUMBER 506
#define KWD_OPEN 507
#define KWD_OPENED 508
#define KWD_OPERATOR 509
#define KWD_OPTIONAL 510
#define KWD_OUT 511
#define KWD_PAD 512
#define KWD_PARAMETER 513
#define KWD_PASS 514
#define KWD_PAUSE 515
#define KWD_PENDING 516
#define KWD_POINTER 517
#define KWD_POSITION 518
#define KWD_PRECISION 519
#define KWD_PRINT 520
#define KWD_PRIVATE 521
#define KWD_PROCEDURE 522
#define KWD_PROGRAM 523
#define KWD_PROTECTED 524
#define KWD_PUBLIC 525
#define KWD_PURE 526
#define KWD_READ 527
#define KWD_READ_FORMATTED 528
#define KWD_READ_UNFORMATTED 529
#define KWD_READWRITE 530
#define KWD_REAL 531
#define KWD_REC 532
#define KWD_RECL 533
#define KWD_RETURN 534
#define KWD_REWIND 535
#define KWD_ROUND 536
#define KWD_SAVE 537
#define KWD_SELECT_CASE 538
#define KWD_SELECT_TYPE 539
#define KWD_SEQUENCE 540
#define KWD_SEQUENTIAL 541
#define KWD_SIGN 542
#define KWD_SIZE 543
#define KWD_SOURCE 544
#define KWD_STATUS 545
#define KWD_STOP 546
#define KWD_STREAM 547
#define KWD_SUBMODULE 548
#define KWD_SUBROUTINE 549
#define KWD_TARGET 550
#define KWD_THEN 551
#define KWD_TRUE 552
#define KWD_TYPE 553
#define KWD_UNFORMATTED 554
#define KWD_UNIT 555
#define KWD_USE 556
#define KWD_VALUE 557
#define KWD_VOLATILE 558
#define KWD_WHERE 559
#define KWD_WRITE 560
#define KWD_WRITE_FORMATTED 561
#define KWD_WRITE_UNFORMATTED 562
#define PPD_NULL 563
#define PPD_DEFINE 564
#define PPD_ELIF 565
#define PPD_ELSE 566
#define PPD_ENDIF 567
#define PPD_ERROR 568
#define PPD_WARNING 569
#define PPD_IF 570
#define PPD_IFDEF 571
#define PPD_IFNDEF 572
#define PPD_INCLUDE 573
#define PPD_LINE 574
#define PPD_PRAGMA 575
#define PPD_UNDEF 576
#define OP_LOGICAL_NOT 577
#define OP_NE 578
#define OP_STRINGIZE 579
#define OP_TOKEN_SPLICE 580
#define OP_MODULO 581
#define ALT_OP_TOKEN_SPLICE 582
#define OP_ASSIGN_MODULO 583
#define OP_BIT_AND 584
#define OP_ADDRESS 585
#define OP_LOGICAL_AND 586
#define OP_ASSIGN_BIT_AND 587
#define OP_DEREFERENCE 588
#define OP_MULTIPLY 589
#define OP_ASSIGN_MULTIPLY 590
#define OP_PLUS 591
#define OP_INCREMENT 592
#define OP_ASSIGN_PLUS 593
#define OP_MINUS 594
#define OP_DECREMENT 595
#define OP_ASSIGN_MINUS 596
#define OP_POINTER_MEMBER 597
#define OP_POINTER_POINTER_TO_MEMBER 598
#define OP_OBJECT_MEMBER 599
#define OP_OBJECT_POINTER_TO_MEMBER 600
#define OP_DIVIDE 601
#define OP_ASSIGN_DIVIDE 602
#define OP_ELSE 603
#define OP_LT 604
#define OP_SHIFT_LEFT 605
#define OP_ASSIGN_SHIFT_LEFT 606
#define OP_LE 607
#define OP_ASSIGN 608
#define OP_EQ 609
#define OP_GT 610
#define OP_GE 611
#define OP_SHIFT_RIGHT 612
#define OP_ASSIGN_SHIFT_RIGHT 613
#define OP_CONDITIONAL 614
#define OP_BIT_PLUS 615
#define OP_ASSIGN_BIT_PLUS 616
#define OP_BIT_OR 617
#define OP_ASSIGN_BIT_OR 618
#define OP_LOGICAL_OR 619
#define OP_BIT_NOT 620
#define OP_ALT_LOGICAL_AND 621
#define OP_ALT_ASSIGN_BIT_AND 622
#define OP_ALT_BIT_AND 623
#define OP_ALT_BIT_OR 624
#define OP_ALT_BIT_NOT 625
#define OP_ALT_LOGICAL_NOT 626
#define OP_ALT_NE 627
#define OP_ALT_LOGICAL_OR 628
#define OP_ALT_ASSIGN_BIT_OR 629
#define OP_ALT_BIT_PLUS 630
#define OP_ALT_ASSIGN_BIT_PLUS 631
#define OPEN_PARENTHESIS_SLASH 632
#define CLOSE_PARENTHESIS_SLASH 633
#define INV_ALT_LOGICAL_AND 634
#define INV_ALT_ASSIGN_BIT_AND 635
#define INV_ALT_BIT_AND 636
#define INV_ALT_BIT_OR 637
#define INV_ALT_BIT_NOT 638
#define INV_ALT_LOGICAL_NOT 639
#define INV_ALT_NE 640
#define INV_ALT_LOGICAL_OR 641
#define INV_ALT_ASSIGN_BIT_OR 642
#define INV_ALT_BIT_PLUS 643
#define INV_ALT_ASSIGN_BIT_PLUS 644
#define INV_MFI_LOGICAL_AND 645
#define INV_MFI_ASSIGN_BIT_AND 646
#define INV_MFI_BIT_AND 647
#define INV_MFI_BIT_OR 648
#define INV_MFI_BIT_NOT 649
#define INV_MFI_LOGICAL_NOT 650
#define INV_MFI_NE 651
#define INV_MFI_LOGICAL_OR 652
#define INV_MFI_ASSIGN_BIT_OR 653
#define INV_MFI_BIT_PLUS 654
#define INV_MFI_ASSIGN_BIT_PLUS 655
#define DECL_REFERENCE 656
#define DECL_POINTER 657
#define DECL_VAR_ARGS 658
#define WHITE_SPACE 659
#define SYSTEM_HEADER_STRING 660
#define HEADER_STRING 661
#define IDENTIFIER 662
#define NON_REPLACEABLE_IDENTIFIER 663
#define MACRO_FUNCTION_IDENTIFIER 664
#define MACRO_OBJECT_IDENTIFIER 665
#define PP_NUMBER 666
#define CHARACTER_LITERAL 667
#define L_CHARACTER_LITERAL 668
#define STRING_LITERAL 669
#define L_STRING_LITERAL 670
#define INTEGER_LITERAL 671
#define OCTAL_LITERAL 672
#define DECIMAL_LITERAL 673
#define HEXADECIMAL_LITERAL 674
#define FLOATING_LITERAL 675
#define UNIVERSAL_CHARACTER_NAME 676
#define USE_ON_CODE 677
#define PUNC_INITIALIZE 678
#define PUNC_SYNONYM 679
#define DONT_CARE 680
#define RESERVED_WORD 681
#define ACCESS_SPECIFIER 682
#define BOOLEAN_LITERAL 683
#define CV_QUALIFIER 684
#define INTRINSIC_TYPE 685
#define FUNCTION_SPECIFIER 686
#define STORAGE_CLASS_SPECIFIER 687
#define USER_TOKEN 688
#define SYMBOL 689
#define COMMENT 690
#define BLOCK_COMMENT 691
#define END_OF_STATEMENT 692
#define BLOCK_OPEN 693
#define BLOCK_CLOSE 694
#define LIST_OPEN 695
#define LIST_SEPARATOR 696
#define LIST_CLOSE 697




/* Copy the first part of user declarations.  */


#include <stdio.h>
#include "parser_routines.h"
#include "tree.h"
#include "lexer.h"
#define YYDEBUG 1
#define YYERROR_VERBOSE 1
//define YYSTYPE int
char *getCurrentFilename();
void yyerror(char const *s);
int yypp_lex (void);



/* Enabling traces.  */
#ifndef YYDEBUG
# define YYDEBUG 1
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
# define YYTOKEN_TABLE 1
#endif

#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE

{
  float fval;
  char *sval;
  unsigned int uval;
  int ival;
  long lval;
}
/* Line 187 of yacc.c.  */

	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif

#if ! defined YYLTYPE && ! defined YYLTYPE_IS_DECLARED
typedef struct YYLTYPE
{
  int first_line;
  int first_column;
  int last_line;
  int last_column;
} YYLTYPE;
# define yyltype YYLTYPE /* obsolescent; will be withdrawn */
# define YYLTYPE_IS_DECLARED 1
# define YYLTYPE_IS_TRIVIAL 1
#endif


/* Copy the second part of user declarations.  */


/* Line 216 of yacc.c.  */


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
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* ! defined yyoverflow || YYERROR_VERBOSE */


#if (! defined yyoverflow \
     && (! defined __cplusplus \
	 || (defined YYLTYPE_IS_TRIVIAL && YYLTYPE_IS_TRIVIAL \
	     && defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yytype_int16 yyss;
  YYSTYPE yyvs;
    YYLTYPE yyls;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (sizeof (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (sizeof (yytype_int16) + sizeof (YYSTYPE) + sizeof (YYLTYPE)) \
      + 2 * YYSTACK_GAP_MAXIMUM)

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
#define YYFINAL  3
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   1367

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  443
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  330
/* YYNRULES -- Number of rules.  */
#define YYNRULES  670
/* YYNRULES -- Number of states.  */
#define YYNSTATES  737

/* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   697

#define YYTRANSLATE(YYX)						\
  ((unsigned int) (YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

/* YYTRANSLATE[YYLEX] -- Bison symbol number corresponding to YYLEX.  */
static const yytype_uint16 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
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
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,    63,    64,
      65,    66,    67,    68,    69,    70,    71,    72,    73,    74,
      75,    76,    77,    78,    79,    80,    81,    82,    83,    84,
      85,    86,    87,    88,    89,    90,    91,    92,    93,    94,
      95,    96,    97,    98,    99,   100,   101,   102,   103,   104,
     105,   106,   107,   108,   109,   110,   111,   112,   113,   114,
     115,   116,   117,   118,   119,   120,   121,   122,   123,   124,
     125,   126,   127,   128,   129,   130,   131,   132,   133,   134,
     135,   136,   137,   138,   139,   140,   141,   142,   143,   144,
     145,   146,   147,   148,   149,   150,   151,   152,   153,   154,
     155,   156,   157,   158,   159,   160,   161,   162,   163,   164,
     165,   166,   167,   168,   169,   170,   171,   172,   173,   174,
     175,   176,   177,   178,   179,   180,   181,   182,   183,   184,
     185,   186,   187,   188,   189,   190,   191,   192,   193,   194,
     195,   196,   197,   198,   199,   200,   201,   202,   203,   204,
     205,   206,   207,   208,   209,   210,   211,   212,   213,   214,
     215,   216,   217,   218,   219,   220,   221,   222,   223,   224,
     225,   226,   227,   228,   229,   230,   231,   232,   233,   234,
     235,   236,   237,   238,   239,   240,   241,   242,   243,   244,
     245,   246,   247,   248,   249,   250,   251,   252,   253,   254,
     255,   256,   257,   258,   259,   260,   261,   262,   263,   264,
     265,   266,   267,   268,   269,   270,   271,   272,   273,   274,
     275,   276,   277,   278,   279,   280,   281,   282,   283,   284,
     285,   286,   287,   288,   289,   290,   291,   292,   293,   294,
     295,   296,   297,   298,   299,   300,   301,   302,   303,   304,
     305,   306,   307,   308,   309,   310,   311,   312,   313,   314,
     315,   316,   317,   318,   319,   320,   321,   322,   323,   324,
     325,   326,   327,   328,   329,   330,   331,   332,   333,   334,
     335,   336,   337,   338,   339,   340,   341,   342,   343,   344,
     345,   346,   347,   348,   349,   350,   351,   352,   353,   354,
     355,   356,   357,   358,   359,   360,   361,   362,   363,   364,
     365,   366,   367,   368,   369,   370,   371,   372,   373,   374,
     375,   376,   377,   378,   379,   380,   381,   382,   383,   384,
     385,   386,   387,   388,   389,   390,   391,   392,   393,   394,
     395,   396,   397,   398,   399,   400,   401,   402,   403,   404,
     405,   406,   407,   408,   409,   410,   411,   412,   413,   414,
     415,   416,   417,   418,   419,   420,   421,   422,   423,   424,
     425,   426,   427,   428,   429,   430,   431,   432,   433,   434,
     435,   436,   437,   438,   439,   440,   441,   442
};

#if YYDEBUG
/* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
   YYRHS.  */
static const yytype_uint16 yyprhs[] =
{
       0,     0,     3,     4,     7,     8,    10,    12,    15,    16,
      20,    22,    24,    29,    32,    35,    37,    39,    41,    43,
      47,    52,    57,    62,    67,    68,    70,    72,    75,    78,
      82,    83,    85,    87,    91,    93,    96,   100,   105,   111,
     115,   116,   121,   122,   127,   128,   133,   136,   140,   141,
     144,   145,   147,   149,   152,   154,   156,   158,   160,   162,
     164,   166,   168,   170,   172,   173,   175,   177,   181,   183,
     185,   187,   189,   191,   193,   195,   197,   199,   201,   203,
     205,   207,   209,   211,   213,   215,   217,   219,   221,   223,
     225,   227,   229,   231,   233,   235,   237,   239,   241,   243,
     245,   247,   249,   251,   253,   255,   257,   259,   261,   263,
     265,   267,   269,   271,   273,   275,   277,   279,   281,   283,
     285,   287,   289,   291,   293,   295,   297,   299,   301,   303,
     305,   307,   309,   311,   313,   315,   317,   319,   321,   323,
     325,   327,   329,   331,   333,   335,   337,   339,   341,   343,
     345,   347,   349,   351,   353,   355,   357,   359,   361,   363,
     365,   367,   369,   371,   373,   375,   377,   379,   381,   383,
     385,   387,   389,   391,   393,   395,   397,   399,   401,   403,
     405,   407,   409,   411,   413,   415,   417,   419,   421,   423,
     425,   427,   429,   431,   433,   435,   437,   439,   441,   443,
     445,   447,   449,   451,   453,   455,   457,   459,   461,   463,
     465,   467,   469,   471,   473,   475,   477,   479,   481,   483,
     485,   487,   489,   491,   493,   495,   497,   499,   501,   503,
     505,   507,   509,   511,   513,   515,   517,   519,   521,   523,
     525,   527,   529,   531,   533,   535,   537,   539,   541,   543,
     545,   547,   549,   551,   553,   555,   557,   559,   561,   562,
     564,   566,   568,   570,   572,   574,   576,   578,   580,   582,
     584,   586,   588,   590,   592,   594,   596,   598,   600,   602,
     604,   606,   608,   610,   612,   614,   616,   618,   620,   622,
     624,   626,   628,   630,   632,   634,   636,   638,   640,   642,
     644,   646,   648,   650,   652,   654,   656,   658,   660,   662,
     664,   666,   668,   670,   672,   674,   676,   678,   680,   682,
     684,   686,   688,   690,   692,   694,   696,   698,   700,   704,
     706,   712,   714,   718,   720,   724,   726,   730,   732,   736,
     738,   742,   744,   748,   752,   754,   758,   762,   766,   770,
     772,   776,   780,   782,   786,   790,   792,   796,   800,   804,
     806,   809,   812,   815,   818,   820,   822,   826,   828,   830,
     832,   834,   836,   838,   840,   842,   844,   846,   848,   850,
     852,   854,   856,   858,   860,   862,   864,   866,   868,   870,
     872,   874,   876,   878,   880,   882,   884,   886,   888,   890,
     892,   894,   896,   898,   900,   902,   904,   906,   908,   910,
     912,   914,   916,   918,   920,   922,   924,   926,   928,   930,
     932,   934,   936,   938,   940,   942,   944,   946,   948,   950,
     952,   954,   956,   958,   960,   962,   964,   966,   968,   970,
     972,   974,   976,   978,   980,   982,   984,   986,   988,   990,
     992,   994,   996,   998,  1000,  1002,  1004,  1006,  1008,  1010,
    1012,  1014,  1016,  1018,  1020,  1022,  1024,  1026,  1028,  1030,
    1032,  1034,  1036,  1038,  1040,  1042,  1044,  1046,  1048,  1050,
    1052,  1054,  1056,  1058,  1060,  1062,  1064,  1066,  1068,  1070,
    1072,  1074,  1076,  1078,  1080,  1082,  1084,  1086,  1088,  1090,
    1092,  1094,  1096,  1098,  1100,  1102,  1104,  1106,  1108,  1110,
    1112,  1114,  1116,  1118,  1120,  1122,  1124,  1126,  1128,  1130,
    1132,  1134,  1136,  1138,  1140,  1142,  1144,  1146,  1148,  1150,
    1152,  1154,  1156,  1158,  1160,  1162,  1164,  1166,  1168,  1170,
    1172,  1174,  1176,  1178,  1180,  1182,  1184,  1186,  1188,  1190,
    1192,  1194,  1196,  1198,  1200,  1202,  1204,  1206,  1208,  1210,
    1212,  1214,  1216,  1218,  1220,  1222,  1224,  1226,  1228,  1230,
    1232,  1234,  1236,  1238,  1240,  1242,  1244,  1246,  1248,  1250,
    1252,  1254,  1256,  1258,  1260,  1262,  1264,  1266,  1268,  1270,
    1272,  1274,  1276,  1278,  1280,  1282,  1284,  1286,  1288,  1290,
    1292,  1294,  1296,  1298,  1300,  1302,  1304,  1306,  1308,  1310,
    1312,  1314,  1316,  1318,  1320,  1322,  1324,  1326,  1328,  1330,
    1332,  1334,  1336,  1338,  1340,  1342,  1344,  1346,  1348,  1350,
    1352,  1354,  1356,  1358,  1360,  1362,  1364,  1366,  1368,  1370,
    1372,  1374,  1376,  1378,  1380,  1382,  1384,  1386,  1388,  1390,
    1392,  1394,  1396,  1398,  1400,  1402,  1404,  1406,  1408,  1410,
    1412,  1414,  1416,  1418,  1420,  1422,  1424,  1426,  1428,  1430,
    1432
};

/* YYRHS -- A `-1'-separated list of the rules' RHS.  */
static const yytype_int16 yyrhs[] =
{
     444,     0,    -1,    -1,   445,   446,    -1,    -1,   447,    -1,
     448,    -1,   447,   448,    -1,    -1,   449,   473,   678,    -1,
     450,    -1,   466,    -1,   456,   457,   461,   465,    -1,   315,
     498,    -1,   315,   494,    -1,   316,    -1,   317,    -1,   407,
      -1,   407,    -1,   451,   678,   446,    -1,   452,   454,   678,
     446,    -1,   453,   455,   678,   446,    -1,   452,   685,   678,
     446,    -1,   453,   686,   678,   446,    -1,    -1,   458,    -1,
     460,    -1,   458,   460,    -1,   310,   498,    -1,   459,   678,
     446,    -1,    -1,   463,    -1,   311,    -1,   462,   678,   446,
      -1,   312,    -1,   464,   678,    -1,   318,   474,   678,    -1,
     309,   683,   493,   678,    -1,   309,   682,   470,   471,   678,
      -1,   321,   684,   678,    -1,    -1,   319,   467,   474,   678,
      -1,    -1,   313,   468,   473,   678,    -1,    -1,   320,   469,
     473,   678,    -1,   308,   678,    -1,    43,   477,    44,    -1,
      -1,   472,   473,    -1,    -1,   474,    -1,   475,    -1,   474,
     475,    -1,   482,    -1,   476,    -1,   479,    -1,   483,    -1,
     492,    -1,   494,    -1,   497,    -1,    95,    -1,   405,    -1,
     406,    -1,    -1,   478,    -1,   479,    -1,   478,    47,   479,
      -1,   407,    -1,   408,    -1,   481,    -1,   407,    -1,   408,
      -1,   513,    -1,   514,    -1,   515,    -1,   516,    -1,   517,
      -1,   518,    -1,   519,    -1,   520,    -1,   521,    -1,   522,
      -1,   523,    -1,   524,    -1,   525,    -1,   526,    -1,   527,
      -1,   528,    -1,   529,    -1,   530,    -1,   531,    -1,   532,
      -1,   533,    -1,   534,    -1,   535,    -1,   536,    -1,   537,
      -1,   538,    -1,   539,    -1,   540,    -1,   541,    -1,   542,
      -1,   543,    -1,   544,    -1,   545,    -1,   546,    -1,   547,
      -1,   548,    -1,   549,    -1,   550,    -1,   551,    -1,   552,
      -1,   553,    -1,   554,    -1,   555,    -1,   556,    -1,   557,
      -1,   558,    -1,   559,    -1,   560,    -1,   561,    -1,   562,
      -1,   563,    -1,   564,    -1,   565,    -1,   566,    -1,   567,
      -1,   568,    -1,   569,    -1,   570,    -1,   571,    -1,   572,
      -1,   573,    -1,   574,    -1,   575,    -1,   576,    -1,   577,
      -1,   578,    -1,   579,    -1,   580,    -1,   581,    -1,   582,
      -1,   583,    -1,   584,    -1,   585,    -1,   586,    -1,   587,
      -1,   588,    -1,   589,    -1,   590,    -1,   591,    -1,   592,
      -1,   593,    -1,   594,    -1,   595,    -1,   596,    -1,   597,
      -1,   598,    -1,   599,    -1,   600,    -1,   602,    -1,   603,
      -1,   604,    -1,   607,    -1,   601,    -1,   605,    -1,   606,
      -1,   608,    -1,   609,    -1,   610,    -1,   611,    -1,   612,
      -1,   613,    -1,   614,    -1,   615,    -1,   616,    -1,   617,
      -1,   618,    -1,   619,    -1,   620,    -1,   621,    -1,   622,
      -1,   623,    -1,   624,    -1,   625,    -1,   626,    -1,   627,
      -1,   628,    -1,   629,    -1,   630,    -1,   631,    -1,   632,
      -1,   633,    -1,   634,    -1,   635,    -1,   636,    -1,   637,
      -1,   638,    -1,   639,    -1,   640,    -1,   641,    -1,   642,
      -1,   643,    -1,   644,    -1,   645,    -1,   646,    -1,   647,
      -1,   648,    -1,   649,    -1,   650,    -1,   651,    -1,   652,
      -1,   653,    -1,   654,    -1,   655,    -1,   656,    -1,   657,
      -1,   658,    -1,   659,    -1,   660,    -1,   662,    -1,   663,
      -1,   661,    -1,   664,    -1,   665,    -1,   666,    -1,   667,
      -1,   668,    -1,   669,    -1,   670,    -1,   671,    -1,   672,
      -1,   673,    -1,   674,    -1,   675,    -1,   676,    -1,   677,
      -1,   404,    -1,   411,    -1,   484,    -1,   495,    -1,   416,
      -1,   485,    -1,   486,    -1,   487,    -1,   417,    -1,   418,
      -1,   419,    -1,   416,    -1,   489,    -1,   490,    -1,   491,
      -1,   417,    -1,   418,    -1,   419,    -1,   412,    -1,   413,
      -1,    -1,   494,    -1,   414,    -1,   415,    -1,   420,    -1,
     209,    -1,   297,    -1,   428,    -1,   688,    -1,   679,    -1,
     680,    -1,   693,    -1,   697,    -1,   703,    -1,   704,    -1,
     705,    -1,   706,    -1,   707,    -1,   710,    -1,   715,    -1,
     717,    -1,   724,    -1,   727,    -1,   731,    -1,   735,    -1,
     736,    -1,   743,    -1,   746,    -1,   753,    -1,   756,    -1,
     758,    -1,   757,    -1,   762,    -1,   764,    -1,   763,    -1,
     770,    -1,   691,    -1,   681,    -1,   696,    -1,   700,    -1,
     702,    -1,   709,    -1,   713,    -1,   714,    -1,   720,    -1,
     721,    -1,   722,    -1,   723,    -1,   726,    -1,   730,    -1,
     733,    -1,   734,    -1,   738,    -1,   740,    -1,   741,    -1,
     744,    -1,   748,    -1,   750,    -1,   752,    -1,   761,    -1,
     767,    -1,   768,    -1,   725,    -1,   698,    -1,   765,    -1,
     771,    -1,   689,    -1,   759,    -1,   499,    -1,   500,    -1,
     499,   716,   500,    -1,   501,    -1,   501,   755,   499,   732,
     500,    -1,   502,    -1,   501,   769,   502,    -1,   503,    -1,
     502,   701,   503,    -1,   504,    -1,   503,   766,   504,    -1,
     505,    -1,   504,   760,   505,    -1,   506,    -1,   505,   699,
     506,    -1,   507,    -1,   506,   745,   507,    -1,   506,   692,
     507,    -1,   508,    -1,   507,   737,   508,    -1,   507,   747,
     508,    -1,   507,   742,   508,    -1,   507,   749,   508,    -1,
     509,    -1,   508,   739,   509,    -1,   508,   751,   509,    -1,
     510,    -1,   509,   711,   510,    -1,   509,   718,   510,    -1,
     511,    -1,   510,   708,   511,    -1,   510,   729,   511,    -1,
     510,   695,   511,    -1,   512,    -1,   712,   511,    -1,   719,
     511,    -1,   690,   511,    -1,   772,   511,    -1,   496,    -1,
     488,    -1,    43,   499,    44,    -1,   480,    -1,   137,    -1,
     138,    -1,   139,    -1,   140,    -1,   141,    -1,   142,    -1,
     143,    -1,   144,    -1,   146,    -1,   147,    -1,   148,    -1,
     149,    -1,   150,    -1,   151,    -1,   152,    -1,   153,    -1,
     154,    -1,   155,    -1,   156,    -1,   157,    -1,   158,    -1,
     159,    -1,   160,    -1,   161,    -1,   162,    -1,   163,    -1,
     164,    -1,   165,    -1,   166,    -1,   167,    -1,   168,    -1,
     169,    -1,   170,    -1,   171,    -1,   172,    -1,   173,    -1,
     174,    -1,   175,    -1,   176,    -1,   177,    -1,   178,    -1,
     180,    -1,   181,    -1,   182,    -1,   183,    -1,   184,    -1,
     185,    -1,   186,    -1,   187,    -1,   188,    -1,   189,    -1,
     190,    -1,   191,    -1,   192,    -1,   193,    -1,   194,    -1,
     195,    -1,   196,    -1,   197,    -1,   198,    -1,   199,    -1,
     200,    -1,   201,    -1,   202,    -1,   203,    -1,   204,    -1,
     205,    -1,   206,    -1,   207,    -1,   208,    -1,   209,    -1,
     210,    -1,   211,    -1,   212,    -1,   213,    -1,   214,    -1,
     215,    -1,   216,    -1,   217,    -1,   218,    -1,   219,    -1,
     220,    -1,   221,    -1,   222,    -1,   223,    -1,   224,    -1,
     225,    -1,   226,    -1,   227,    -1,   228,    -1,   229,    -1,
     230,    -1,   231,    -1,   232,    -1,   233,    -1,   234,    -1,
     235,    -1,   236,    -1,   237,    -1,   238,    -1,   239,    -1,
     240,    -1,   241,    -1,   242,    -1,   243,    -1,   244,    -1,
     245,    -1,   246,    -1,   247,    -1,   248,    -1,   249,    -1,
     250,    -1,   251,    -1,   252,    -1,   253,    -1,   254,    -1,
     255,    -1,   256,    -1,   257,    -1,   258,    -1,   259,    -1,
     260,    -1,   262,    -1,   263,    -1,   264,    -1,   265,    -1,
     266,    -1,   267,    -1,   268,    -1,   269,    -1,   270,    -1,
     271,    -1,   272,    -1,   273,    -1,   274,    -1,   276,    -1,
     277,    -1,   278,    -1,   279,    -1,   280,    -1,   281,    -1,
     282,    -1,   283,    -1,   284,    -1,   285,    -1,   286,    -1,
     287,    -1,   288,    -1,   289,    -1,   290,    -1,   291,    -1,
     294,    -1,   295,    -1,   296,    -1,   297,    -1,   298,    -1,
     299,    -1,   300,    -1,   301,    -1,   302,    -1,   303,    -1,
     304,    -1,   305,    -1,   306,    -1,   307,    -1,    13,    -1,
      38,    -1,   134,    -1,   324,    -1,   325,    -1,   327,    -1,
     409,    -1,   390,    -1,   391,    -1,   392,    -1,   393,    -1,
     394,    -1,   395,    -1,   396,    -1,   397,    -1,   398,    -1,
     399,    -1,   400,    -1,   410,    -1,   687,    -1,   407,    -1,
     687,    -1,   687,    -1,   687,    -1,   379,    -1,   380,    -1,
     381,    -1,   382,    -1,   383,    -1,   384,    -1,   385,    -1,
     386,    -1,   387,    -1,   388,    -1,   389,    -1,    36,    -1,
     371,    -1,    36,    -1,   371,    -1,   323,    -1,   372,    -1,
     323,    -1,   372,    -1,   694,    -1,    40,    -1,    40,    -1,
     328,    -1,    41,    -1,   368,    -1,    41,    -1,   368,    -1,
     331,    -1,   366,    -1,   331,    -1,   366,    -1,   332,    -1,
     367,    -1,    43,    -1,    44,    -1,   377,    -1,   378,    -1,
      45,    -1,    45,    -1,   335,    -1,    46,    -1,    46,    -1,
      46,    -1,   337,    -1,   338,    -1,    47,    -1,    47,    -1,
      48,    -1,    48,    -1,    48,    -1,   340,    -1,   341,    -1,
     342,    -1,   343,    -1,    49,    -1,   403,    -1,   345,    -1,
     728,    -1,    50,    -1,    50,    -1,   347,    -1,    61,    -1,
      61,    -1,   135,    -1,   136,    -1,    62,    -1,    63,    -1,
      63,    -1,   350,    -1,   350,    -1,   351,    -1,   352,    -1,
     352,    -1,    64,    -1,   354,    -1,   354,    -1,    65,    -1,
      65,    -1,   356,    -1,   356,    -1,   357,    -1,   357,    -1,
     358,    -1,   754,    -1,   359,    -1,   359,    -1,    94,    -1,
     132,    -1,    96,    -1,   133,    -1,    97,    -1,   375,    -1,
      97,    -1,   375,    -1,   361,    -1,   376,    -1,   125,    -1,
     130,    -1,   127,    -1,   131,    -1,   126,    -1,   369,    -1,
     126,    -1,   369,    -1,   363,    -1,   374,    -1,   364,    -1,
     373,    -1,   364,    -1,   373,    -1,   128,    -1,   370,    -1,
     128,    -1,   370,    -1
};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const yytype_uint16 yyrline[] =
{
       0,   507,   507,   507,   510,   511,   514,   515,   518,   518,
     519,   520,   523,   526,   527,   530,   533,   536,   539,   542,
     543,   544,   545,   546,   549,   550,   553,   554,   557,   560,
     563,   564,   567,   570,   573,   576,   579,   580,   581,   582,
     583,   583,   584,   584,   585,   585,   586,   589,   592,   592,
     595,   596,   599,   600,   603,   604,   605,   606,   607,   608,
     609,   610,   613,   614,   617,   618,   621,   622,   625,   626,
     627,   630,   631,   633,   634,   635,   636,   637,   638,   639,
     640,   641,   642,   643,   644,   645,   646,   647,   648,   649,
     650,   651,   652,   653,   654,   655,   656,   657,   658,   659,
     660,   661,   662,   663,   664,   665,   666,   667,   668,   669,
     670,   671,   672,   673,   674,   675,   676,   677,   678,   679,
     680,   681,   682,   683,   684,   685,   686,   687,   688,   689,
     690,   691,   692,   693,   694,   695,   696,   697,   698,   699,
     700,   701,   702,   703,   704,   705,   706,   707,   708,   709,
     710,   711,   712,   713,   714,   715,   716,   717,   718,   719,
     720,   721,   722,   723,   724,   725,   726,   727,   728,   729,
     730,   731,   732,   733,   734,   735,   736,   737,   738,   739,
     740,   741,   742,   743,   744,   745,   746,   747,   748,   749,
     750,   751,   752,   753,   754,   755,   756,   757,   758,   759,
     760,   761,   762,   763,   764,   765,   766,   767,   768,   769,
     770,   771,   772,   773,   774,   775,   776,   777,   778,   779,
     780,   781,   782,   783,   784,   785,   786,   787,   788,   789,
     790,   791,   792,   793,   794,   795,   796,   797,   804,   807,
     808,   809,   812,   813,   814,   815,   818,   821,   824,   827,
     828,   829,   830,   833,   836,   839,   842,   843,   846,   847,
     850,   851,   854,   857,   858,   859,   862,   863,   864,   865,
     866,   867,   868,   869,   870,   871,   872,   873,   874,   875,
     876,   877,   878,   879,   880,   881,   882,   883,   884,   885,
     886,   887,   888,   889,   890,   891,   892,   893,   894,   895,
     896,   897,   898,   899,   900,   901,   902,   903,   904,   905,
     906,   907,   908,   909,   910,   911,   912,   913,   914,   915,
     916,   917,   918,   919,   920,   921,   924,   927,   928,   931,
     932,   935,   936,   939,   940,   943,   944,   947,   948,   951,
     952,   955,   956,   957,   960,   961,   962,   963,   964,   967,
     968,   969,   972,   973,   974,   977,   978,   979,   980,   983,
     984,   985,   986,   987,   990,   991,   992,   993,   996,   999,
    1002,  1005,  1008,  1011,  1014,  1017,  1020,  1023,  1026,  1029,
    1032,  1035,  1038,  1041,  1044,  1047,  1050,  1053,  1056,  1059,
    1062,  1065,  1068,  1071,  1074,  1077,  1080,  1083,  1086,  1089,
    1092,  1095,  1098,  1101,  1104,  1107,  1110,  1113,  1116,  1119,
    1122,  1125,  1128,  1131,  1134,  1137,  1140,  1143,  1146,  1149,
    1152,  1155,  1158,  1161,  1164,  1167,  1170,  1173,  1176,  1179,
    1182,  1185,  1188,  1191,  1194,  1197,  1200,  1203,  1206,  1209,
    1212,  1215,  1218,  1221,  1224,  1227,  1230,  1233,  1236,  1239,
    1242,  1245,  1248,  1251,  1254,  1257,  1260,  1263,  1266,  1269,
    1272,  1275,  1278,  1281,  1284,  1287,  1290,  1293,  1296,  1299,
    1302,  1305,  1308,  1311,  1314,  1317,  1320,  1323,  1326,  1329,
    1332,  1335,  1338,  1341,  1344,  1347,  1350,  1353,  1356,  1359,
    1362,  1365,  1368,  1371,  1374,  1377,  1380,  1383,  1386,  1389,
    1392,  1395,  1398,  1401,  1404,  1407,  1410,  1413,  1416,  1419,
    1422,  1425,  1428,  1431,  1434,  1437,  1440,  1443,  1446,  1449,
    1452,  1455,  1458,  1461,  1464,  1467,  1470,  1473,  1476,  1479,
    1482,  1485,  1488,  1491,  1494,  1495,  1498,  1501,  1502,  1505,
    1506,  1507,  1508,  1509,  1510,  1511,  1512,  1513,  1514,  1515,
    1516,  1519,  1520,  1523,  1524,  1527,  1530,  1533,  1534,  1535,
    1536,  1537,  1538,  1539,  1540,  1541,  1542,  1543,  1546,  1549,
    1552,  1553,  1556,  1557,  1560,  1561,  1564,  1567,  1570,  1573,
    1576,  1579,  1582,  1583,  1586,  1587,  1590,  1591,  1594,  1595,
    1598,  1601,  1604,  1607,  1610,  1613,  1616,  1619,  1622,  1625,
    1628,  1631,  1634,  1637,  1640,  1643,  1646,  1649,  1652,  1655,
    1658,  1661,  1664,  1667,  1670,  1673,  1676,  1679,  1682,  1685,
    1688,  1691,  1694,  1697,  1700,  1703,  1706,  1709,  1712,  1715,
    1718,  1721,  1724,  1727,  1730,  1733,  1736,  1739,  1742,  1745,
    1748,  1750,  1753,  1756,  1757,  1760,  1761,  1764,  1767,  1770,
    1771,  1774,  1775,  1778,  1779,  1782,  1783,  1786,  1789,  1792,
    1793,  1796,  1797,  1800,  1801,  1804,  1805,  1808,  1811,  1814,
    1815
};
#endif

#if YYDEBUG || YYERROR_VERBOSE || YYTOKEN_TABLE
/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "$end", "error", "$undefined", "ECS_NULL", "ASC_SOH", "ASC_STX",
  "ASC_ETX", "ASC_EOT", "ASC_ENQ", "ASC_ACK", "ECS_ALERT", "ECS_BACKSPACE",
  "BCS_WHTSP_TAB", "BCS_WHTSP_NEWLINE", "BCS_WHTSP_VERTICAL_TAB",
  "BCS_WHTSP_FORMFEED", "ECS_CARRIAGE_RETURN", "ASC_SHIFT_OUT",
  "ASC_SHIFT_IN", "ASC_DLE", "ASC_DC1", "ASC_DC2", "ASC_DC3", "ASC_DC4",
  "ASC_NAK", "ASC_SYN", "ASC_ETB", "ASC_CAN", "ASC_EM", "ASC_SUB",
  "ASC_ESC", "ASC_IS4", "ASC_IS3", "ASC_IS2", "ASC_IS1", "BCS_WHTSP_SPACE",
  "BCS_PUNCT_EXCLAMATION", "BCS_PUNCT_QUOTE", "BCS_PUNCT_HASH",
  "ASC_DOLLAR_SIGN", "BCS_PUNCT_PERCENT", "BCS_PUNCT_AMPERSAND",
  "BCS_PUNCT_APOSTROPHE", "BCS_PUNCT_OPEN_PARENTHESIS",
  "BCS_PUNCT_CLOSE_PARENTHESIS", "BCS_PUNCT_ASTERISK", "BCS_PUNCT_PLUS",
  "BCS_PUNCT_COMMA", "BCS_PUNCT_MINUS", "BCS_PUNCT_PERIOD",
  "BCS_PUNCT_SLASH", "BCS_DIGIT_0", "BCS_DIGIT_1", "BCS_DIGIT_2",
  "BCS_DIGIT_3", "BCS_DIGIT_4", "BCS_DIGIT_5", "BCS_DIGIT_6",
  "BCS_DIGIT_7", "BCS_DIGIT_8", "BCS_DIGIT_9", "BCS_PUNCT_COLON",
  "BCS_PUNCT_SEMICOLON", "BCS_PUNCT_LESS_THAN", "BCS_PUNCT_EQUAL",
  "BCS_PUNCT_GREATER_THAN", "BCS_PUNCT_QUESTION", "ASC_AT_SIGN",
  "BCS_UPPER_A", "BCS_UPPER_B", "BCS_UPPER_C", "BCS_UPPER_D",
  "BCS_UPPER_E", "BCS_UPPER_F", "BCS_UPPER_G", "BCS_UPPER_H",
  "BCS_UPPER_I", "BCS_UPPER_J", "BCS_UPPER_K", "BCS_UPPER_L",
  "BCS_UPPER_M", "BCS_UPPER_N", "BCS_UPPER_O", "BCS_UPPER_P",
  "BCS_UPPER_Q", "BCS_UPPER_R", "BCS_UPPER_S", "BCS_UPPER_T",
  "BCS_UPPER_U", "BCS_UPPER_V", "BCS_UPPER_W", "BCS_UPPER_X",
  "BCS_UPPER_Y", "BCS_UPPER_Z", "BCS_PUNCT_OPEN_BRACKET",
  "BCS_PUNCT_BACKSLASH", "BCS_PUNCT_CLOSE_BRACKET", "BCS_PUNCT_CARET",
  "BCS_PUNCT_UNDERSCORE", "BCS_LOWER_A", "BCS_LOWER_B", "BCS_LOWER_C",
  "BCS_LOWER_D", "BCS_LOWER_E", "BCS_LOWER_F", "BCS_LOWER_G",
  "BCS_LOWER_H", "BCS_LOWER_I", "BCS_LOWER_J", "BCS_LOWER_K",
  "BCS_LOWER_L", "BCS_LOWER_M", "BCS_LOWER_N", "BCS_LOWER_O",
  "BCS_LOWER_P", "BCS_LOWER_Q", "BCS_LOWER_R", "BCS_LOWER_S",
  "BCS_LOWER_T", "BCS_LOWER_U", "BCS_LOWER_V", "BCS_LOWER_W",
  "BCS_LOWER_X", "BCS_LOWER_Y", "BCS_LOWER_Z", "BCS_PUNCT_OPEN_BRACE",
  "BCS_PUNCT_VERTICAL_BAR", "BCS_PUNCT_CLOSE_BRACE", "BCS_PUNCT_TILDE",
  "ASC_DEL", "ALT_PUNCT_OPEN_BRACE", "ALT_PUNCT_CLOSE_BRACE",
  "ALT_PUNCT_OPEN_BRACKET", "ALT_PUNCT_CLOSE_BRACKET", "ALT_PUNCT_HASH",
  "PUNC_DBL_COLON", "PUNC_ARROW", "KWD_ABSTRACT", "KWD_ABSTRACT_INTERFACE",
  "KWD_ACCESS", "KWD_ACTION", "KWD_ADVANCE", "KWD_ALLOCATABLE",
  "KWD_ALLOCATE", "KWD_ASSIGN", "KWD_ASSOCIATE", "KWD_ASYNCHRONOUS",
  "KWD_BACKSPACE", "KWD_BIND", "KWD_BLANK", "KWD_BLOCK", "KWD_BLOCK_DATA",
  "KWD_CALL", "KWD_CASE", "KWD_CHARACTER", "KWD_CLASS",
  "KWD_CLASS_DEFAULT", "KWD_CLASS_IS", "KWD_CLOSE", "KWD_COMMON",
  "KWD_COMPLEX", "KWD_CONTAINS", "KWD_CONTIGUOUS", "KWD_CONTINUE",
  "KWD_CYCLE", "KWD_DATA", "KWD_DEALLOCATE", "KWD_DEFAULT", "KWD_DEFERRED",
  "KWD_DIMENSION", "KWD_DIRECT", "KWD_DO", "KWD_DOUBLE",
  "KWD_DOUBLE_COMPLEX", "KWD_DOUBLE_PRECISION", "KWD_ELEMENTAL",
  "KWD_ELSE", "KWD_ELSE_IF", "KWD_ELSE_WHERE", "KWD_ENCODING", "KWD_END",
  "KWD_END_ASSOCIATE", "KWD_END_BLOCK", "KWD_END_BLOCK_DATA", "KWD_END_DO",
  "KWD_END_ENUM", "KWD_END_FILE", "KWD_END_FORALL", "KWD_END_FUNCTION",
  "KWD_END_IF", "KWD_END_INTERFACE", "KWD_END_MODULE", "KWD_END_PROCEDURE",
  "KWD_END_PROGRAM", "KWD_END_SELECT", "KWD_END_SUBMODULE",
  "KWD_END_SUBROUTINE", "KWD_END_TYPE", "KWD_END_WHERE", "KWD_ENTRY",
  "KWD_EOR", "KWD_EQUIVALENCE", "KWD_ERR", "KWD_ERRMSG", "KWD_EXIST",
  "KWD_EXIT", "KWD_EXTENDS", "KWD_EXTENSIBLE", "KWD_EXTERNAL", "KWD_FALSE",
  "KWD_FILE", "KWD_FINAL", "KWD_FLUSH", "KWD_FMT", "KWD_FORALL",
  "KWD_FORM", "KWD_FORMAT", "KWD_FORMATTED", "KWD_FUNCTION", "KWD_GENERIC",
  "KWD_GOTO", "KWD_IF", "KWD_IMPLICIT", "KWD_IMPLICIT_NONE", "KWD_IMPORT",
  "KWD_IMPURE", "KWD_IN", "KWD_IN_OUT", "KWD_INCLUDE", "KWD_INQUIRE",
  "KWD_INTEGER", "KWD_INTENT", "KWD_INTERFACE", "KWD_INTRINSIC",
  "KWD_IOSTAT", "KWD_IOMSG", "KWD_KIND", "KWD_LET", "KWD_LOGICAL",
  "KWD_MODULE", "KWD_MOLD", "KWD_NAME", "KWD_NAMED", "KWD_NAMELIST",
  "KWD_NEXTREC", "KWD_NON_INTRINSIC", "KWD_NON_OVERRIDABLE", "KWD_NONKIND",
  "KWD_NONE", "KWD_NOPASS", "KWD_NULLIFY", "KWD_NUMBER", "KWD_OPEN",
  "KWD_OPENED", "KWD_OPERATOR", "KWD_OPTIONAL", "KWD_OUT", "KWD_PAD",
  "KWD_PARAMETER", "KWD_PASS", "KWD_PAUSE", "KWD_PENDING", "KWD_POINTER",
  "KWD_POSITION", "KWD_PRECISION", "KWD_PRINT", "KWD_PRIVATE",
  "KWD_PROCEDURE", "KWD_PROGRAM", "KWD_PROTECTED", "KWD_PUBLIC",
  "KWD_PURE", "KWD_READ", "KWD_READ_FORMATTED", "KWD_READ_UNFORMATTED",
  "KWD_READWRITE", "KWD_REAL", "KWD_REC", "KWD_RECL", "KWD_RETURN",
  "KWD_REWIND", "KWD_ROUND", "KWD_SAVE", "KWD_SELECT_CASE",
  "KWD_SELECT_TYPE", "KWD_SEQUENCE", "KWD_SEQUENTIAL", "KWD_SIGN",
  "KWD_SIZE", "KWD_SOURCE", "KWD_STATUS", "KWD_STOP", "KWD_STREAM",
  "KWD_SUBMODULE", "KWD_SUBROUTINE", "KWD_TARGET", "KWD_THEN", "KWD_TRUE",
  "KWD_TYPE", "KWD_UNFORMATTED", "KWD_UNIT", "KWD_USE", "KWD_VALUE",
  "KWD_VOLATILE", "KWD_WHERE", "KWD_WRITE", "KWD_WRITE_FORMATTED",
  "KWD_WRITE_UNFORMATTED", "PPD_NULL", "PPD_DEFINE", "PPD_ELIF",
  "PPD_ELSE", "PPD_ENDIF", "PPD_ERROR", "PPD_WARNING", "PPD_IF",
  "PPD_IFDEF", "PPD_IFNDEF", "PPD_INCLUDE", "PPD_LINE", "PPD_PRAGMA",
  "PPD_UNDEF", "OP_LOGICAL_NOT", "OP_NE", "OP_STRINGIZE",
  "OP_TOKEN_SPLICE", "OP_MODULO", "ALT_OP_TOKEN_SPLICE",
  "OP_ASSIGN_MODULO", "OP_BIT_AND", "OP_ADDRESS", "OP_LOGICAL_AND",
  "OP_ASSIGN_BIT_AND", "OP_DEREFERENCE", "OP_MULTIPLY",
  "OP_ASSIGN_MULTIPLY", "OP_PLUS", "OP_INCREMENT", "OP_ASSIGN_PLUS",
  "OP_MINUS", "OP_DECREMENT", "OP_ASSIGN_MINUS", "OP_POINTER_MEMBER",
  "OP_POINTER_POINTER_TO_MEMBER", "OP_OBJECT_MEMBER",
  "OP_OBJECT_POINTER_TO_MEMBER", "OP_DIVIDE", "OP_ASSIGN_DIVIDE",
  "OP_ELSE", "OP_LT", "OP_SHIFT_LEFT", "OP_ASSIGN_SHIFT_LEFT", "OP_LE",
  "OP_ASSIGN", "OP_EQ", "OP_GT", "OP_GE", "OP_SHIFT_RIGHT",
  "OP_ASSIGN_SHIFT_RIGHT", "OP_CONDITIONAL", "OP_BIT_PLUS",
  "OP_ASSIGN_BIT_PLUS", "OP_BIT_OR", "OP_ASSIGN_BIT_OR", "OP_LOGICAL_OR",
  "OP_BIT_NOT", "OP_ALT_LOGICAL_AND", "OP_ALT_ASSIGN_BIT_AND",
  "OP_ALT_BIT_AND", "OP_ALT_BIT_OR", "OP_ALT_BIT_NOT",
  "OP_ALT_LOGICAL_NOT", "OP_ALT_NE", "OP_ALT_LOGICAL_OR",
  "OP_ALT_ASSIGN_BIT_OR", "OP_ALT_BIT_PLUS", "OP_ALT_ASSIGN_BIT_PLUS",
  "OPEN_PARENTHESIS_SLASH", "CLOSE_PARENTHESIS_SLASH",
  "INV_ALT_LOGICAL_AND", "INV_ALT_ASSIGN_BIT_AND", "INV_ALT_BIT_AND",
  "INV_ALT_BIT_OR", "INV_ALT_BIT_NOT", "INV_ALT_LOGICAL_NOT", "INV_ALT_NE",
  "INV_ALT_LOGICAL_OR", "INV_ALT_ASSIGN_BIT_OR", "INV_ALT_BIT_PLUS",
  "INV_ALT_ASSIGN_BIT_PLUS", "INV_MFI_LOGICAL_AND",
  "INV_MFI_ASSIGN_BIT_AND", "INV_MFI_BIT_AND", "INV_MFI_BIT_OR",
  "INV_MFI_BIT_NOT", "INV_MFI_LOGICAL_NOT", "INV_MFI_NE",
  "INV_MFI_LOGICAL_OR", "INV_MFI_ASSIGN_BIT_OR", "INV_MFI_BIT_PLUS",
  "INV_MFI_ASSIGN_BIT_PLUS", "DECL_REFERENCE", "DECL_POINTER",
  "DECL_VAR_ARGS", "WHITE_SPACE", "SYSTEM_HEADER_STRING", "HEADER_STRING",
  "IDENTIFIER", "NON_REPLACEABLE_IDENTIFIER", "MACRO_FUNCTION_IDENTIFIER",
  "MACRO_OBJECT_IDENTIFIER", "PP_NUMBER", "CHARACTER_LITERAL",
  "L_CHARACTER_LITERAL", "STRING_LITERAL", "L_STRING_LITERAL",
  "INTEGER_LITERAL", "OCTAL_LITERAL", "DECIMAL_LITERAL",
  "HEXADECIMAL_LITERAL", "FLOATING_LITERAL", "UNIVERSAL_CHARACTER_NAME",
  "USE_ON_CODE", "PUNC_INITIALIZE", "PUNC_SYNONYM", "DONT_CARE",
  "RESERVED_WORD", "ACCESS_SPECIFIER", "BOOLEAN_LITERAL", "CV_QUALIFIER",
  "INTRINSIC_TYPE", "FUNCTION_SPECIFIER", "STORAGE_CLASS_SPECIFIER",
  "USER_TOKEN", "SYMBOL", "COMMENT", "BLOCK_COMMENT", "END_OF_STATEMENT",
  "BLOCK_OPEN", "BLOCK_CLOSE", "LIST_OPEN", "LIST_SEPARATOR", "LIST_CLOSE",
  "$accept", "preprocessing_file", "@1", "group_part_seq_opt",
  "group_part_seq", "group_part", "@2", "if_section", "if_open",
  "ifdef_open", "ifndef_open", "ifdef_identifier", "ifndef_identifier",
  "if_group", "elif_group_seq_opt", "elif_group_seq", "elif_group_open",
  "elif_group", "else_group_opt", "else_open", "else_group", "endif_open",
  "endif_line", "control_line", "@3", "@4", "@5", "mf_args",
  "replacement_list", "@6", "preprocessing_token_seq_opt",
  "preprocessing_token_seq", "preprocessing_token", "header_name",
  "clean_identifier_list_opt", "clean_identifier_list", "identifier",
  "pp_identifier", "key_word", "white_space", "pp_number",
  "integer_literal", "octal_literal", "decimal_literal",
  "hexadecimal_literal", "pp_integer_literal", "pp_octal_literal",
  "pp_decimal_literal", "pp_hexadecimal_literal", "character_literal",
  "string_literal_opt", "string_literal", "floating_literal",
  "pp_boolean_literal", "preprocessing_op_or_punc",
  "pp_constant_expression", "pp_expression", "pp_conditional_expression",
  "pp_logical_or_expression", "pp_logical_and_expression",
  "pp_inclusive_or_expression", "pp_exclusive_or_expression",
  "pp_and_expression", "pp_equality_expression",
  "pp_relational_expression", "pp_shift_expression",
  "pp_additive_expression", "pp_multiplicative_expression",
  "pp_unary_expression", "pp_primary_expression", "kwd_abstract",
  "kwd_abstract_interface", "kwd_access", "kwd_action", "kwd_advance",
  "kwd_allocatable", "kwd_allocate", "kwd_assign", "kwd_asynchronous",
  "kwd_backspace", "kwd_bind", "kwd_blank", "kwd_block", "kwd_block_data",
  "kwd_call", "kwd_case", "kwd_character", "kwd_class",
  "kwd_class_default", "kwd_class_is", "kwd_close", "kwd_common",
  "kwd_complex", "kwd_contains", "kwd_contiguous", "kwd_continue",
  "kwd_cycle", "kwd_data", "kwd_deallocate", "kwd_default", "kwd_deferred",
  "kwd_dimension", "kwd_direct", "kwd_do", "kwd_double",
  "kwd_double_complex", "kwd_double_precision", "kwd_elemental",
  "kwd_else", "kwd_else_if", "kwd_else_where", "kwd_end",
  "kwd_end_associate", "kwd_end_block", "kwd_end_block_data", "kwd_end_do",
  "kwd_end_enum", "kwd_end_file", "kwd_end_forall", "kwd_end_function",
  "kwd_end_if", "kwd_end_interface", "kwd_end_module", "kwd_end_procedure",
  "kwd_end_program", "kwd_end_select", "kwd_end_submodule",
  "kwd_end_subroutine", "kwd_end_type", "kwd_end_where", "kwd_entry",
  "kwd_eor", "kwd_equivalence", "kwd_err", "kwd_errmsg", "kwd_exist",
  "kwd_exit", "kwd_extends", "kwd_extensible", "kwd_external", "kwd_false",
  "kwd_file", "kwd_final", "kwd_flush", "kwd_fmt", "kwd_forall",
  "kwd_form", "kwd_format", "kwd_formatted", "kwd_function", "kwd_generic",
  "kwd_goto", "kwd_if", "kwd_implicit", "kwd_implicit_none", "kwd_import",
  "kwd_impure", "kwd_in", "kwd_in_out", "kwd_include", "kwd_inquire",
  "kwd_integer", "kwd_intent", "kwd_interface", "kwd_intrinsic",
  "kwd_iostat", "kwd_iomsg", "kwd_kind", "kwd_let", "kwd_logical",
  "kwd_module", "kwd_mold", "kwd_name", "kwd_named", "kwd_namelist",
  "kwd_nextrec", "kwd_non_intrinsic", "kwd_non_overridable", "kwd_nonkind",
  "kwd_none", "kwd_nopass", "kwd_nullify", "kwd_number", "kwd_open",
  "kwd_opened", "kwd_operator", "kwd_optional", "kwd_out", "kwd_pad",
  "kwd_parameter", "kwd_pass", "kwd_pause", "kwd_pointer", "kwd_position",
  "kwd_precision", "kwd_print", "kwd_private", "kwd_procedure",
  "kwd_program", "kwd_protected", "kwd_public", "kwd_pure", "kwd_read",
  "kwd_read_formatted", "kwd_read_unformatted", "kwd_real", "kwd_rec",
  "kwd_recl", "kwd_return", "kwd_rewind", "kwd_round", "kwd_save",
  "kwd_select_case", "kwd_select_type", "kwd_sequence", "kwd_sequential",
  "kwd_sign", "kwd_size", "kwd_source", "kwd_status", "kwd_stop",
  "kwd_subroutine", "kwd_target", "kwd_then", "kwd_true", "kwd_type",
  "kwd_unformatted", "kwd_unit", "kwd_use", "kwd_value", "kwd_volatile",
  "kwd_where", "kwd_write", "kwd_write_formatted", "kwd_write_unformatted",
  "new_line", "bcs_hash", "op_stringize", "token_splice", "mf_identifier",
  "mo_identifier", "mu_identifier", "invalid_ifdef_identifier",
  "invalid_ifndef_identifier", "invalid_macro_identifier",
  "bcs_exclamation", "alt_truth_not", "pp_truth_not", "ne", "pp_ne",
  "bcs_percent", "member", "pp_modulo", "assign_modulo", "bcs_ampersand",
  "alt_bit_and", "pp_bit_and", "truth_and", "pp_truth_and",
  "assign_bit_and", "bcs_open_parenthesis", "bcs_close_parenthesis",
  "open_parenthesis_slash", "close_parenthesis_slash", "bcs_asterisk",
  "pp_multiply", "assign_multiply", "bcs_plus", "pp_plus", "pp_unary_plus",
  "increment", "assign_plus", "bcs_comma", "pp_comma_op", "bcs_minus",
  "pp_minus", "pp_unary_minus", "decrement", "assign_minus",
  "pointer_member", "pointer_ptm", "bcs_period", "var_args", "object_ptm",
  "bcs_slash", "divide", "pp_divide", "assign_divide", "bcs_colon",
  "pp_conditional_separator", "dbl_colon", "arrow", "bcs_semicolon",
  "bcs_less_than", "pp_lt", "shift_left", "pp_shift_left",
  "assign_shift_left", "le", "pp_le", "bcs_equal", "eq", "pp_eq",
  "bcs_greater_than", "pp_gt", "ge", "pp_ge", "shift_right",
  "pp_shift_right", "assign_shift_right", "bcs_question",
  "conditional_operator", "pp_conditional_operator", "bcs_open_bracket",
  "bcs_close_bracket", "bcs_caret", "alt_bit_xor", "pp_bit_xor",
  "assign_bit_xor", "bcs_open_brace", "bcs_close_brace",
  "bcs_vertical_bar", "alt_bit_or", "pp_bit_or", "assign_bit_or",
  "truth_or", "pp_truth_or", "bcs_tilde", "alt_bit_not", "pp_bit_not", 0
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
     285,   286,   287,   288,   289,   290,   291,   292,   293,   294,
     295,   296,   297,   298,   299,   300,   301,   302,   303,   304,
     305,   306,   307,   308,   309,   310,   311,   312,   313,   314,
     315,   316,   317,   318,   319,   320,   321,   322,   323,   324,
     325,   326,   327,   328,   329,   330,   331,   332,   333,   334,
     335,   336,   337,   338,   339,   340,   341,   342,   343,   344,
     345,   346,   347,   348,   349,   350,   351,   352,   353,   354,
     355,   356,   357,   358,   359,   360,   361,   362,   363,   364,
     365,   366,   367,   368,   369,   370,   371,   372,   373,   374,
     375,   376,   377,   378,   379,   380,   381,   382,   383,   384,
     385,   386,   387,   388,   389,   390,   391,   392,   393,   394,
     395,   396,   397,   398,   399,   400,   401,   402,   403,   404,
     405,   406,   407,   408,   409,   410,   411,   412,   413,   414,
     415,   416,   417,   418,   419,   420,   421,   422,   423,   424,
     425,   426,   427,   428,   429,   430,   431,   432,   433,   434,
     435,   436,   437,   438,   439,   440,   441,   442,   443,   444,
     445,   446,   447,   448,   449,   450,   451,   452,   453,   454,
     455,   456,   457,   458,   459,   460,   461,   462,   463,   464,
     465,   466,   467,   468,   469,   470,   471,   472,   473,   474,
     475,   476,   477,   478,   479,   480,   481,   482,   483,   484,
     485,   486,   487,   488,   489,   490,   491,   492,   493,   494,
     495,   496,   497,   498,   499,   500,   501,   502,   503,   504,
     505,   506,   507,   508,   509,   510,   511,   512,   513,   514,
     515,   516,   517,   518,   519,   520,   521,   522,   523,   524,
     525,   526,   527,   528,   529,   530,   531,   532,   533,   534,
     535,   536,   537,   538,   539,   540,   541,   542,   543,   544,
     545,   546,   547,   548,   549,   550,   551,   552,   553,   554,
     555,   556,   557,   558,   559,   560,   561,   562,   563,   564,
     565,   566,   567,   568,   569,   570,   571,   572,   573,   574,
     575,   576,   577,   578,   579,   580,   581,   582,   583,   584,
     585,   586,   587,   588,   589,   590,   591,   592,   593,   594,
     595,   596,   597,   598,   599,   600,   601,   602,   603,   604,
     605,   606,   607,   608,   609,   610,   611,   612,   613,   614,
     615,   616,   617,   618,   619,   620,   621,   622,   623,   624,
     625,   626,   627,   628,   629,   630,   631,   632,   633,   634,
     635,   636,   637,   638,   639,   640,   641,   642,   643,   644,
     645,   646,   647,   648,   649,   650,   651,   652,   653,   654,
     655,   656,   657,   658,   659,   660,   661,   662,   663,   664,
     665,   666,   667,   668,   669,   670,   671,   672,   673,   674,
     675,   676,   677,   678,   679,   680,   681,   682,   683,   684,
     685,   686,   687,   688,   689,   690,   691,   692,   693,   694,
     695,   696,   697
};
# endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_uint16 yyr1[] =
{
       0,   443,   445,   444,   446,   446,   447,   447,   449,   448,
     448,   448,   450,   451,   451,   452,   453,   454,   455,   456,
     456,   456,   456,   456,   457,   457,   458,   458,   459,   460,
     461,   461,   462,   463,   464,   465,   466,   466,   466,   466,
     467,   466,   468,   466,   469,   466,   466,   470,   472,   471,
     473,   473,   474,   474,   475,   475,   475,   475,   475,   475,
     475,   475,   476,   476,   477,   477,   478,   478,   479,   479,
     479,   480,   480,   481,   481,   481,   481,   481,   481,   481,
     481,   481,   481,   481,   481,   481,   481,   481,   481,   481,
     481,   481,   481,   481,   481,   481,   481,   481,   481,   481,
     481,   481,   481,   481,   481,   481,   481,   481,   481,   481,
     481,   481,   481,   481,   481,   481,   481,   481,   481,   481,
     481,   481,   481,   481,   481,   481,   481,   481,   481,   481,
     481,   481,   481,   481,   481,   481,   481,   481,   481,   481,
     481,   481,   481,   481,   481,   481,   481,   481,   481,   481,
     481,   481,   481,   481,   481,   481,   481,   481,   481,   481,
     481,   481,   481,   481,   481,   481,   481,   481,   481,   481,
     481,   481,   481,   481,   481,   481,   481,   481,   481,   481,
     481,   481,   481,   481,   481,   481,   481,   481,   481,   481,
     481,   481,   481,   481,   481,   481,   481,   481,   481,   481,
     481,   481,   481,   481,   481,   481,   481,   481,   481,   481,
     481,   481,   481,   481,   481,   481,   481,   481,   481,   481,
     481,   481,   481,   481,   481,   481,   481,   481,   481,   481,
     481,   481,   481,   481,   481,   481,   481,   481,   482,   483,
     483,   483,   484,   484,   484,   484,   485,   486,   487,   488,
     488,   488,   488,   489,   490,   491,   492,   492,   493,   493,
     494,   494,   495,   496,   496,   496,   497,   497,   497,   497,
     497,   497,   497,   497,   497,   497,   497,   497,   497,   497,
     497,   497,   497,   497,   497,   497,   497,   497,   497,   497,
     497,   497,   497,   497,   497,   497,   497,   497,   497,   497,
     497,   497,   497,   497,   497,   497,   497,   497,   497,   497,
     497,   497,   497,   497,   497,   497,   497,   497,   497,   497,
     497,   497,   497,   497,   497,   497,   498,   499,   499,   500,
     500,   501,   501,   502,   502,   503,   503,   504,   504,   505,
     505,   506,   506,   506,   507,   507,   507,   507,   507,   508,
     508,   508,   509,   509,   509,   510,   510,   510,   510,   511,
     511,   511,   511,   511,   512,   512,   512,   512,   513,   514,
     515,   516,   517,   518,   519,   520,   521,   522,   523,   524,
     525,   526,   527,   528,   529,   530,   531,   532,   533,   534,
     535,   536,   537,   538,   539,   540,   541,   542,   543,   544,
     545,   546,   547,   548,   549,   550,   551,   552,   553,   554,
     555,   556,   557,   558,   559,   560,   561,   562,   563,   564,
     565,   566,   567,   568,   569,   570,   571,   572,   573,   574,
     575,   576,   577,   578,   579,   580,   581,   582,   583,   584,
     585,   586,   587,   588,   589,   590,   591,   592,   593,   594,
     595,   596,   597,   598,   599,   600,   601,   602,   603,   604,
     605,   606,   607,   608,   609,   610,   611,   612,   613,   614,
     615,   616,   617,   618,   619,   620,   621,   622,   623,   624,
     625,   626,   627,   628,   629,   630,   631,   632,   633,   634,
     635,   636,   637,   638,   639,   640,   641,   642,   643,   644,
     645,   646,   647,   648,   649,   650,   651,   652,   653,   654,
     655,   656,   657,   658,   659,   660,   661,   662,   663,   664,
     665,   666,   667,   668,   669,   670,   671,   672,   673,   674,
     675,   676,   677,   678,   679,   679,   680,   681,   681,   682,
     682,   682,   682,   682,   682,   682,   682,   682,   682,   682,
     682,   683,   683,   684,   684,   685,   686,   687,   687,   687,
     687,   687,   687,   687,   687,   687,   687,   687,   688,   689,
     690,   690,   691,   691,   692,   692,   693,   694,   695,   696,
     697,   698,   699,   699,   700,   700,   701,   701,   702,   702,
     703,   704,   705,   706,   707,   708,   709,   710,   711,   712,
     713,   714,   715,   716,   717,   718,   719,   720,   721,   722,
     723,   724,   725,   726,   727,   728,   729,   730,   731,   732,
     733,   734,   735,   736,   737,   738,   739,   740,   741,   742,
     743,   744,   745,   746,   747,   748,   749,   750,   751,   752,
     753,   754,   755,   756,   756,   757,   757,   758,   759,   760,
     760,   761,   761,   762,   762,   763,   763,   764,   765,   766,
     766,   767,   767,   768,   768,   769,   769,   770,   771,   772,
     772
};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
static const yytype_uint8 yyr2[] =
{
       0,     2,     0,     2,     0,     1,     1,     2,     0,     3,
       1,     1,     4,     2,     2,     1,     1,     1,     1,     3,
       4,     4,     4,     4,     0,     1,     1,     2,     2,     3,
       0,     1,     1,     3,     1,     2,     3,     4,     5,     3,
       0,     4,     0,     4,     0,     4,     2,     3,     0,     2,
       0,     1,     1,     2,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     0,     1,     1,     3,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     0,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     3,     1,
       5,     1,     3,     1,     3,     1,     3,     1,     3,     1,
       3,     1,     3,     3,     1,     3,     3,     3,     3,     1,
       3,     3,     1,     3,     3,     1,     3,     3,     3,     1,
       2,     2,     2,     2,     1,     1,     3,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1
};

/* YYDEFACT[STATE-NAME] -- Default rule to reduce with in state
   STATE-NUM when YYTABLE doesn't specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint16 yydefact[] =
{
       2,     0,     8,     1,     0,     0,    42,     0,    15,    16,
       0,    40,    44,     0,     3,     8,     6,    50,    10,     0,
       0,     0,    24,    11,   533,    46,   557,   558,   559,   560,
     561,   562,   563,   564,   565,   566,   567,   540,   541,   542,
     543,   544,   545,   546,   547,   548,   549,   550,   539,   551,
       0,   258,   552,    50,   570,     0,   599,   606,   669,   263,
     264,   670,   571,    71,    72,   260,   261,   249,   253,   254,
     255,   265,   367,   365,   250,   251,   252,    14,   364,    13,
     326,   327,   329,   331,   333,   335,   337,   339,   341,   344,
     349,   352,   355,   359,     0,     0,     0,     0,   568,   534,
     577,   580,   590,   591,   594,   597,   602,   604,   611,   615,
     618,   622,   623,   630,   633,   643,    61,   645,   647,   653,
     657,   655,   667,   654,   656,   644,   646,   535,   620,   621,
     368,   369,   370,   371,   372,   373,   374,   375,   376,   377,
     378,   379,   380,   381,   382,   383,   384,   385,   386,   387,
     388,   389,   390,   391,   392,   393,   394,   395,   396,   397,
     398,   399,   400,   401,   402,   403,   404,   405,   406,   407,
     408,   409,   410,   411,   412,   413,   414,   415,   416,   417,
     418,   419,   420,   421,   422,   423,   424,   425,   426,   427,
     428,   429,   430,   431,   432,   433,   434,   435,   436,   437,
     438,   439,   440,   441,   442,   443,   444,   445,   446,   447,
     448,   449,   450,   451,   452,   453,   454,   455,   456,   457,
     458,   459,   460,   461,   462,   463,   464,   465,   466,   467,
     468,   469,   470,   471,   472,   473,   474,   475,   476,   477,
     478,   479,   480,   481,   482,   483,   484,   485,   486,   487,
     488,   489,   490,   491,   492,   493,   494,   495,   496,   497,
     498,   499,   500,   501,   502,   503,   504,   505,   506,   507,
     508,   509,   510,   511,   512,   513,   514,   515,   516,   517,
     518,   519,   520,   521,   522,   523,   524,   525,   526,   527,
     528,   529,   530,   531,   532,   572,   536,   537,   538,   579,
     584,   588,   596,   600,   601,   607,   608,   609,   610,   613,
     617,   625,   627,   628,   631,   635,   637,   639,   641,   651,
     661,   663,   585,   589,   581,   658,   668,   569,   573,   664,
     662,   648,   652,   592,   593,   612,   238,    62,    63,    68,
      69,   239,   256,   257,   242,   246,   247,   248,   262,     0,
      52,    55,    56,    70,    54,    57,   240,   243,   244,   245,
      58,    59,   241,    60,    73,    74,    75,    76,    77,    78,
      79,    80,    81,    82,    83,    84,    85,    86,    87,    88,
      89,    90,    91,    92,    93,    94,    95,    96,    97,    98,
      99,   100,   101,   102,   103,   104,   105,   106,   107,   108,
     109,   110,   111,   112,   113,   114,   115,   116,   117,   118,
     119,   120,   121,   122,   123,   124,   125,   126,   127,   128,
     129,   130,   131,   132,   133,   134,   135,   136,   137,   138,
     139,   140,   141,   142,   143,   144,   145,   146,   147,   148,
     149,   150,   151,   152,   153,   154,   155,   156,   157,   158,
     159,   160,   165,   161,   162,   163,   166,   167,   164,   168,
     169,   170,   171,   172,   173,   174,   175,   176,   177,   178,
     179,   180,   181,   182,   183,   184,   185,   186,   187,   188,
     189,   190,   191,   192,   193,   194,   195,   196,   197,   198,
     199,   200,   201,   202,   203,   204,   205,   206,   207,   208,
     209,   210,   211,   212,   213,   214,   215,   216,   217,   218,
     219,   220,   223,   221,   222,   224,   225,   226,   227,   228,
     229,   230,   231,   232,   233,   234,   235,   236,   237,   267,
     268,   295,   266,   324,   294,   269,   576,   296,   270,   321,
     297,   298,   271,   272,   273,   274,   275,   299,   276,   300,
     301,   277,   278,   302,   303,   304,   305,   279,   320,   306,
     280,   614,   307,   281,   308,   309,   282,   283,   310,   311,
     312,   284,   313,   285,   314,   315,   316,   286,   640,   287,
     289,   288,   325,   317,   290,   292,   291,   322,   318,   319,
     293,   323,     0,    50,   553,     0,   554,     7,     0,    51,
       8,    17,     0,     0,   555,    18,     0,     0,   556,     0,
      30,    25,     0,    26,    64,    48,     0,   259,     0,     0,
     603,     0,   642,   665,   666,     0,     0,   586,   587,     0,
     659,   660,     0,   649,   650,     0,   582,   583,     0,   574,
     632,   575,     0,     0,   624,   634,   629,   636,     0,     0,
       0,     0,   626,   638,     0,     0,   598,   605,     0,     0,
     578,   595,   616,     0,     0,     0,   362,   360,   361,   363,
      53,    36,     0,     0,    39,     9,    19,     8,     8,     8,
       8,    28,    32,     0,     0,    31,    27,     8,     0,    65,
      66,     0,    50,    37,    43,   366,   328,     0,   332,   334,
     336,   338,   340,   343,   342,   345,   347,   346,   348,   350,
     351,   353,   354,   358,   356,   357,    41,    45,    20,    22,
      21,    23,    34,     0,    12,     8,    29,    47,     0,    38,
      49,   619,     0,    35,    33,    67,   330
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
      -1,     1,     2,    14,    15,    16,    17,    18,    19,    20,
      21,   602,   606,    22,   610,   611,   612,   613,   683,   684,
     685,   723,   724,    23,   592,    53,   593,   615,   691,   692,
     598,   599,   350,   351,   688,   689,   352,    72,   353,   354,
     355,   356,   357,   358,   359,    73,    74,    75,    76,   360,
     616,   361,   362,    78,   363,    79,    80,    81,    82,    83,
      84,    85,    86,    87,    88,    89,    90,    91,    92,    93,
     364,   365,   366,   367,   368,   369,   370,   371,   372,   373,
     374,   375,   376,   377,   378,   379,   380,   381,   382,   383,
     384,   385,   386,   387,   388,   389,   390,   391,   392,   393,
     394,   395,   396,   397,   398,   399,   400,   401,   402,   403,
     404,   405,   406,   407,   408,   409,   410,   411,   412,   413,
     414,   415,   416,   417,   418,   419,   420,   421,   422,   423,
     424,   425,   426,   427,   428,   429,   430,   431,   432,   433,
     434,   435,   436,   437,   438,   439,   440,   441,   442,   443,
     444,   445,   446,   447,   448,   449,   450,   451,   452,   453,
     454,   455,   456,   457,   458,   459,   460,   461,   462,   463,
     464,   465,   466,   467,   468,   469,   470,   471,   472,   473,
     474,   475,   476,   477,   478,   479,   480,   481,   482,   483,
     484,   485,   486,   487,   488,   489,   490,   491,   492,   493,
     494,   495,   496,   497,   498,   499,   500,   501,   502,   503,
     504,   505,   506,   507,   508,   509,   510,   511,   512,   513,
     514,   515,   516,   517,   518,   519,   520,   521,   522,   523,
     524,   525,   526,   527,   528,    25,   529,   530,   531,    50,
      51,   595,   603,   607,    52,   532,   533,    94,   534,   642,
     535,   536,   663,   537,   538,   539,   638,   540,   629,   541,
     542,   543,   544,   545,   546,   664,   547,   548,   658,    95,
     549,   550,   551,   621,   552,   659,    96,   553,   554,   555,
     556,   557,   558,   559,   560,   561,   665,   562,   563,   732,
     564,   565,   566,   567,   648,   568,   654,   569,   570,   649,
     571,   572,   643,   573,   650,   574,   651,   575,   655,   576,
     577,   578,   625,   579,   580,   581,   582,   635,   583,   584,
     585,   586,   587,   632,   588,   589,   626,   590,   591,    97
};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -600
static const yytype_int16 yypact[] =
{
    -600,    13,   125,  -600,     9,  -312,  -600,   268,  -600,  -600,
     675,  -600,  -600,    99,  -600,   109,  -600,   675,  -600,     9,
     110,   139,  -282,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
      -5,  -352,  -600,   675,  -600,   339,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
       6,  -600,  -344,  -319,  -112,   -87,   -33,  -306,   -47,  -326,
       8,   -15,  -600,  -600,   339,   339,   339,   339,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,    -4,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,   675,   675,  -600,     9,  -600,  -600,     9,   675,
    -205,  -600,     9,     9,  -600,  -600,     9,     9,  -600,   339,
    -246,  -282,     9,  -600,   959,  -600,     9,  -600,     9,   -21,
    -600,   339,  -600,  -600,  -600,   339,   339,  -600,  -600,   339,
    -600,  -600,   339,  -600,  -600,   339,  -600,  -600,   339,  -600,
    -600,  -600,   339,   339,  -600,  -600,  -600,  -600,   339,   339,
     339,   339,  -600,  -600,   339,   339,  -600,  -600,   339,   339,
    -600,  -600,  -600,   339,   339,   339,  -600,  -600,  -600,  -600,
    -600,  -600,    -4,     9,  -600,  -600,  -600,  -205,  -205,  -205,
    -205,  -600,  -600,  -223,     9,  -600,  -600,  -205,    75,    73,
    -600,     9,   675,  -600,  -600,  -600,  -600,   -28,  -319,  -112,
     -87,   -33,  -306,   -47,   -47,  -326,  -326,  -326,  -326,     8,
       8,   -15,   -15,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,     9,  -600,   153,  -600,  -600,   959,  -600,
    -600,  -600,   339,  -600,  -600,  -600,  -600
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -600,  -600,  -600,  -224,  -600,   274,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -305,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
     -52,    -7,  -328,  -600,  -600,  -600,  -587,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,     4,  -600,  -600,  -600,  -302,   -53,  -557,  -600,  -318,
    -317,  -322,  -320,  -325,  -547,  -599,  -555,  -541,   -90,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,   -19,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,    81,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,
    -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600,  -600
};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If zero, do what YYDEFACT says.
   If YYTABLE_NINF, syntax error.  */
#define YYTABLE_NINF -6
static const yytype_int16 yytable[] =
{
     600,   618,   619,   349,   666,   667,   668,   669,   636,    24,
     633,    77,   627,     3,   630,   622,   644,   639,   645,   620,
     623,   670,    24,   695,   652,   660,   620,   690,   609,   624,
     661,   653,    98,   731,    99,   662,   100,   101,   614,   102,
     103,   104,   105,   106,   107,   108,   109,   628,   640,   705,
     706,   707,   708,   620,   656,   617,   657,   110,   111,   112,
     113,   114,    65,    66,   696,   682,   641,    26,    27,    28,
      29,    30,    31,    32,    33,    34,    35,    36,    37,    38,
      39,    40,    41,    42,    43,    44,    45,    46,    47,   722,
     115,   116,   117,   118,   596,   703,   704,    48,    49,   709,
     710,   604,   608,     4,     5,    -4,    -4,    -4,     6,    -5,
       7,     8,     9,    10,    11,    12,    13,   711,   712,   727,
     728,   119,   120,   121,   122,    -4,   123,   124,   125,   126,
     127,   128,   129,   130,   131,   132,   133,   134,   135,   136,
     137,   735,   138,   139,   140,   141,   142,   143,   144,   145,
     146,   147,   148,   149,   150,   151,   152,   153,   154,   155,
     156,   157,   158,   159,   160,   161,   162,   163,   164,   165,
     166,   167,   168,   169,   170,   736,   171,   172,   173,   174,
     175,   176,   177,   178,   179,   180,   181,   182,   183,   184,
     185,   186,   187,   188,   189,   190,   191,   192,   193,   194,
     195,   196,   197,   198,   199,   200,   201,   202,   203,   204,
     205,   206,   207,   208,   209,   210,   211,   212,   213,   214,
     215,   216,   217,   218,   219,   220,   221,   222,   223,   224,
     225,   226,   227,   228,   229,   230,   231,   232,   233,   234,
     235,   236,   237,   238,   239,   240,   241,   242,   243,   244,
     245,   246,   247,   248,   249,   250,   251,   631,   252,   253,
     254,   255,   256,   257,   258,   259,   260,   261,   262,   263,
     264,   670,   265,   266,   267,   268,   269,   270,   271,   272,
     273,   274,   275,   276,   277,   278,   279,   280,   634,   597,
     281,   282,   283,   284,   285,   286,   287,   288,   289,   290,
     291,   292,   293,   294,    54,   646,   686,   681,   698,   647,
     700,    55,   699,   702,    56,   701,    57,     0,     0,   295,
     296,   297,     0,   298,   299,     0,     0,   300,   301,     0,
     671,   302,     0,   303,   304,   637,   305,   306,   307,   308,
       0,   309,     0,   310,   670,     0,   311,   312,   313,     0,
     314,     0,   315,   316,   317,   318,     0,   319,     0,   320,
     321,     0,   322,   323,   324,   325,   326,   327,   328,   329,
     330,   331,   332,   333,   334,    54,   676,     0,     0,     0,
       0,     0,    55,     0,     0,    56,     0,    57,     0,     0,
       0,     0,     0,     0,     0,     0,    58,     0,     0,   335,
     336,   337,   338,   339,   340,     0,     0,   341,   342,   343,
      65,    66,   344,   345,   346,   347,   348,     4,     5,    -5,
      -5,    -5,     6,     0,     7,     8,     9,    10,    11,    12,
      13,     0,     0,     4,     5,     0,     0,     0,     6,     0,
       7,     8,     9,    10,    11,    12,    13,     0,     0,     0,
       0,     0,     0,   718,   719,   720,   721,     0,     0,     0,
       0,     4,     5,   726,     0,    -4,     6,    58,     7,     8,
       9,    10,    11,    12,    13,     0,     0,    59,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    26,
      27,    28,    29,    30,    31,    32,    33,    34,    35,    36,
       0,   734,     0,     0,     0,     0,   594,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,   601,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   673,     0,     0,     0,     0,   605,     0,    59,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    60,     0,     0,     0,     0,
       0,     0,   697,   713,   714,   715,   674,     0,     0,   675,
       0,     0,     0,   677,   678,   672,     0,   679,   680,     0,
       0,     0,     0,   687,     0,     0,     0,   693,     0,   694,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    60,     0,    61,    62,
     730,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,   716,   717,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,   725,     0,     0,     0,     0,
       0,     0,   729,     0,     0,    63,    64,     0,     0,     0,
       0,     0,    65,    66,    67,    68,    69,    70,     0,     0,
       0,     0,     0,     0,     0,     0,    71,     0,     0,     0,
       0,     0,     0,     0,   733,     0,     0,     0,     0,    61,
      62,    98,     0,    99,     0,   100,   101,     0,   102,   103,
     104,   105,   106,   107,   108,   109,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,   110,   111,   112,   113,
     114,     0,     0,     0,     0,     0,    63,    64,     0,     0,
       0,     0,     0,     0,     0,    67,    68,    69,    70,     0,
       0,     0,     0,     0,     0,     0,     0,    71,     0,   115,
     116,   117,   118,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     119,   120,   121,   122,     0,   123,   124,   125,   126,   127,
     128,   129,   130,   131,   132,   133,   134,   135,   136,   137,
       0,   138,   139,   140,   141,   142,   143,   144,   145,   146,
     147,   148,   149,   150,   151,   152,   153,   154,   155,   156,
     157,   158,   159,   160,   161,   162,   163,   164,   165,   166,
     167,   168,   169,   170,     0,   171,   172,   173,   174,   175,
     176,   177,   178,   179,   180,   181,   182,   183,   184,   185,
     186,   187,   188,   189,   190,   191,   192,   193,   194,   195,
     196,   197,   198,   199,   200,   201,   202,   203,   204,   205,
     206,   207,   208,   209,   210,   211,   212,   213,   214,   215,
     216,   217,   218,   219,   220,   221,   222,   223,   224,   225,
     226,   227,   228,   229,   230,   231,   232,   233,   234,   235,
     236,   237,   238,   239,   240,   241,   242,   243,   244,   245,
     246,   247,   248,   249,   250,   251,     0,   252,   253,   254,
     255,   256,   257,   258,   259,   260,   261,   262,   263,   264,
       0,   265,   266,   267,   268,   269,   270,   271,   272,   273,
     274,   275,   276,   277,   278,   279,   280,     0,     0,   281,
     282,   283,   284,   285,   286,   287,   288,   289,   290,   291,
     292,   293,   294,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,   295,   296,
     297,     0,   298,   299,     0,     0,   300,   301,     0,     0,
     302,     0,   303,   304,     0,   305,   306,   307,   308,     0,
     309,     0,   310,     0,     0,   311,   312,   313,     0,   314,
       0,   315,   316,   317,   318,     0,   319,     0,   320,   321,
       0,   322,   323,   324,   325,   326,   327,   328,   329,   330,
     331,   332,   333,   334,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,   335,   336,
     337,   338,   339,   340,     0,     0,   341,   342,   343,    65,
      66,   344,   345,   346,   347,   348,   130,   131,   132,   133,
     134,   135,   136,   137,     0,   138,   139,   140,   141,   142,
     143,   144,   145,   146,   147,   148,   149,   150,   151,   152,
     153,   154,   155,   156,   157,   158,   159,   160,   161,   162,
     163,   164,   165,   166,   167,   168,   169,   170,     0,   171,
     172,   173,   174,   175,   176,   177,   178,   179,   180,   181,
     182,   183,   184,   185,   186,   187,   188,   189,   190,   191,
     192,   193,   194,   195,   196,   197,   198,   199,   200,   201,
     202,   203,   204,   205,   206,   207,   208,   209,   210,   211,
     212,   213,   214,   215,   216,   217,   218,   219,   220,   221,
     222,   223,   224,   225,   226,   227,   228,   229,   230,   231,
     232,   233,   234,   235,   236,   237,   238,   239,   240,   241,
     242,   243,   244,   245,   246,   247,   248,   249,   250,   251,
       0,   252,   253,   254,   255,   256,   257,   258,   259,   260,
     261,   262,   263,   264,     0,   265,   266,   267,   268,   269,
     270,   271,   272,   273,   274,   275,   276,   277,   278,   279,
     280,     0,     0,   281,   282,   283,   284,   285,   286,   287,
     288,   289,   290,   291,   292,   293,   294,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,   339,   340
};

static const yytype_int16 yycheck[] =
{
      19,    53,    55,    10,    94,    95,    96,    97,    41,    13,
      97,     7,   331,     0,   126,   359,    63,   323,    65,    47,
     364,   349,    13,    44,   350,    40,    47,   614,   310,   373,
      45,   357,    36,    61,    38,    50,    40,    41,    43,    43,
      44,    45,    46,    47,    48,    49,    50,   366,   354,   648,
     649,   650,   651,    47,    46,    51,    48,    61,    62,    63,
      64,    65,   414,   415,   621,   311,   372,   379,   380,   381,
     382,   383,   384,   385,   386,   387,   388,   389,   390,   391,
     392,   393,   394,   395,   396,   397,   398,   399,   400,   312,
      94,    95,    96,    97,    13,   642,   643,   409,   410,   654,
     655,    20,    21,   308,   309,   310,   311,   312,   313,     0,
     315,   316,   317,   318,   319,   320,   321,   658,   659,    44,
      47,   125,   126,   127,   128,     0,   130,   131,   132,   133,
     134,   135,   136,   137,   138,   139,   140,   141,   142,   143,
     144,   728,   146,   147,   148,   149,   150,   151,   152,   153,
     154,   155,   156,   157,   158,   159,   160,   161,   162,   163,
     164,   165,   166,   167,   168,   169,   170,   171,   172,   173,
     174,   175,   176,   177,   178,   732,   180,   181,   182,   183,
     184,   185,   186,   187,   188,   189,   190,   191,   192,   193,
     194,   195,   196,   197,   198,   199,   200,   201,   202,   203,
     204,   205,   206,   207,   208,   209,   210,   211,   212,   213,
     214,   215,   216,   217,   218,   219,   220,   221,   222,   223,
     224,   225,   226,   227,   228,   229,   230,   231,   232,   233,
     234,   235,   236,   237,   238,   239,   240,   241,   242,   243,
     244,   245,   246,   247,   248,   249,   250,   251,   252,   253,
     254,   255,   256,   257,   258,   259,   260,   369,   262,   263,
     264,   265,   266,   267,   268,   269,   270,   271,   272,   273,
     274,   599,   276,   277,   278,   279,   280,   281,   282,   283,
     284,   285,   286,   287,   288,   289,   290,   291,   375,    15,
     294,   295,   296,   297,   298,   299,   300,   301,   302,   303,
     304,   305,   306,   307,    36,   352,   611,   609,   626,   356,
     632,    43,   629,   638,    46,   635,    48,    -1,    -1,   323,
     324,   325,    -1,   327,   328,    -1,    -1,   331,   332,    -1,
     349,   335,    -1,   337,   338,   368,   340,   341,   342,   343,
      -1,   345,    -1,   347,   672,    -1,   350,   351,   352,    -1,
     354,    -1,   356,   357,   358,   359,    -1,   361,    -1,   363,
     364,    -1,   366,   367,   368,   369,   370,   371,   372,   373,
     374,   375,   376,   377,   378,    36,   600,    -1,    -1,    -1,
      -1,    -1,    43,    -1,    -1,    46,    -1,    48,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,   128,    -1,    -1,   403,
     404,   405,   406,   407,   408,    -1,    -1,   411,   412,   413,
     414,   415,   416,   417,   418,   419,   420,   308,   309,   310,
     311,   312,   313,    -1,   315,   316,   317,   318,   319,   320,
     321,    -1,    -1,   308,   309,    -1,    -1,    -1,   313,    -1,
     315,   316,   317,   318,   319,   320,   321,    -1,    -1,    -1,
      -1,    -1,    -1,   677,   678,   679,   680,    -1,    -1,    -1,
      -1,   308,   309,   687,    -1,   312,   313,   128,   315,   316,
     317,   318,   319,   320,   321,    -1,    -1,   209,   379,   380,
     381,   382,   383,   384,   385,   386,   387,   388,   389,   379,
     380,   381,   382,   383,   384,   385,   386,   387,   388,   389,
      -1,   725,    -1,    -1,    -1,    -1,   407,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,   407,   379,   380,
     381,   382,   383,   384,   385,   386,   387,   388,   389,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,   593,    -1,    -1,    -1,    -1,   407,    -1,   209,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,   297,    -1,    -1,    -1,    -1,
      -1,    -1,   625,   663,   664,   665,   595,    -1,    -1,   598,
      -1,    -1,    -1,   602,   603,   592,    -1,   606,   607,    -1,
      -1,    -1,    -1,   612,    -1,    -1,    -1,   616,    -1,   618,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,   297,    -1,   370,   371,
     692,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,   672,   673,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,   684,    -1,    -1,    -1,    -1,
      -1,    -1,   691,    -1,    -1,   407,   408,    -1,    -1,    -1,
      -1,    -1,   414,   415,   416,   417,   418,   419,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,   428,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,   723,    -1,    -1,    -1,    -1,   370,
     371,    36,    -1,    38,    -1,    40,    41,    -1,    43,    44,
      45,    46,    47,    48,    49,    50,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    61,    62,    63,    64,
      65,    -1,    -1,    -1,    -1,    -1,   407,   408,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,   416,   417,   418,   419,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,   428,    -1,    94,
      95,    96,    97,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
     125,   126,   127,   128,    -1,   130,   131,   132,   133,   134,
     135,   136,   137,   138,   139,   140,   141,   142,   143,   144,
      -1,   146,   147,   148,   149,   150,   151,   152,   153,   154,
     155,   156,   157,   158,   159,   160,   161,   162,   163,   164,
     165,   166,   167,   168,   169,   170,   171,   172,   173,   174,
     175,   176,   177,   178,    -1,   180,   181,   182,   183,   184,
     185,   186,   187,   188,   189,   190,   191,   192,   193,   194,
     195,   196,   197,   198,   199,   200,   201,   202,   203,   204,
     205,   206,   207,   208,   209,   210,   211,   212,   213,   214,
     215,   216,   217,   218,   219,   220,   221,   222,   223,   224,
     225,   226,   227,   228,   229,   230,   231,   232,   233,   234,
     235,   236,   237,   238,   239,   240,   241,   242,   243,   244,
     245,   246,   247,   248,   249,   250,   251,   252,   253,   254,
     255,   256,   257,   258,   259,   260,    -1,   262,   263,   264,
     265,   266,   267,   268,   269,   270,   271,   272,   273,   274,
      -1,   276,   277,   278,   279,   280,   281,   282,   283,   284,
     285,   286,   287,   288,   289,   290,   291,    -1,    -1,   294,
     295,   296,   297,   298,   299,   300,   301,   302,   303,   304,
     305,   306,   307,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   323,   324,
     325,    -1,   327,   328,    -1,    -1,   331,   332,    -1,    -1,
     335,    -1,   337,   338,    -1,   340,   341,   342,   343,    -1,
     345,    -1,   347,    -1,    -1,   350,   351,   352,    -1,   354,
      -1,   356,   357,   358,   359,    -1,   361,    -1,   363,   364,
      -1,   366,   367,   368,   369,   370,   371,   372,   373,   374,
     375,   376,   377,   378,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   403,   404,
     405,   406,   407,   408,    -1,    -1,   411,   412,   413,   414,
     415,   416,   417,   418,   419,   420,   137,   138,   139,   140,
     141,   142,   143,   144,    -1,   146,   147,   148,   149,   150,
     151,   152,   153,   154,   155,   156,   157,   158,   159,   160,
     161,   162,   163,   164,   165,   166,   167,   168,   169,   170,
     171,   172,   173,   174,   175,   176,   177,   178,    -1,   180,
     181,   182,   183,   184,   185,   186,   187,   188,   189,   190,
     191,   192,   193,   194,   195,   196,   197,   198,   199,   200,
     201,   202,   203,   204,   205,   206,   207,   208,   209,   210,
     211,   212,   213,   214,   215,   216,   217,   218,   219,   220,
     221,   222,   223,   224,   225,   226,   227,   228,   229,   230,
     231,   232,   233,   234,   235,   236,   237,   238,   239,   240,
     241,   242,   243,   244,   245,   246,   247,   248,   249,   250,
     251,   252,   253,   254,   255,   256,   257,   258,   259,   260,
      -1,   262,   263,   264,   265,   266,   267,   268,   269,   270,
     271,   272,   273,   274,    -1,   276,   277,   278,   279,   280,
     281,   282,   283,   284,   285,   286,   287,   288,   289,   290,
     291,    -1,    -1,   294,   295,   296,   297,   298,   299,   300,
     301,   302,   303,   304,   305,   306,   307,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,   407,   408
};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const yytype_uint16 yystos[] =
{
       0,   444,   445,     0,   308,   309,   313,   315,   316,   317,
     318,   319,   320,   321,   446,   447,   448,   449,   450,   451,
     452,   453,   456,   466,    13,   678,   379,   380,   381,   382,
     383,   384,   385,   386,   387,   388,   389,   390,   391,   392,
     393,   394,   395,   396,   397,   398,   399,   400,   409,   410,
     682,   683,   687,   468,    36,    43,    46,    48,   128,   209,
     297,   370,   371,   407,   408,   414,   415,   416,   417,   418,
     419,   428,   480,   488,   489,   490,   491,   494,   496,   498,
     499,   500,   501,   502,   503,   504,   505,   506,   507,   508,
     509,   510,   511,   512,   690,   712,   719,   772,    36,    38,
      40,    41,    43,    44,    45,    46,    47,    48,    49,    50,
      61,    62,    63,    64,    65,    94,    95,    96,    97,   125,
     126,   127,   128,   130,   131,   132,   133,   134,   135,   136,
     137,   138,   139,   140,   141,   142,   143,   144,   146,   147,
     148,   149,   150,   151,   152,   153,   154,   155,   156,   157,
     158,   159,   160,   161,   162,   163,   164,   165,   166,   167,
     168,   169,   170,   171,   172,   173,   174,   175,   176,   177,
     178,   180,   181,   182,   183,   184,   185,   186,   187,   188,
     189,   190,   191,   192,   193,   194,   195,   196,   197,   198,
     199,   200,   201,   202,   203,   204,   205,   206,   207,   208,
     209,   210,   211,   212,   213,   214,   215,   216,   217,   218,
     219,   220,   221,   222,   223,   224,   225,   226,   227,   228,
     229,   230,   231,   232,   233,   234,   235,   236,   237,   238,
     239,   240,   241,   242,   243,   244,   245,   246,   247,   248,
     249,   250,   251,   252,   253,   254,   255,   256,   257,   258,
     259,   260,   262,   263,   264,   265,   266,   267,   268,   269,
     270,   271,   272,   273,   274,   276,   277,   278,   279,   280,
     281,   282,   283,   284,   285,   286,   287,   288,   289,   290,
     291,   294,   295,   296,   297,   298,   299,   300,   301,   302,
     303,   304,   305,   306,   307,   323,   324,   325,   327,   328,
     331,   332,   335,   337,   338,   340,   341,   342,   343,   345,
     347,   350,   351,   352,   354,   356,   357,   358,   359,   361,
     363,   364,   366,   367,   368,   369,   370,   371,   372,   373,
     374,   375,   376,   377,   378,   403,   404,   405,   406,   407,
     408,   411,   412,   413,   416,   417,   418,   419,   420,   474,
     475,   476,   479,   481,   482,   483,   484,   485,   486,   487,
     492,   494,   495,   497,   513,   514,   515,   516,   517,   518,
     519,   520,   521,   522,   523,   524,   525,   526,   527,   528,
     529,   530,   531,   532,   533,   534,   535,   536,   537,   538,
     539,   540,   541,   542,   543,   544,   545,   546,   547,   548,
     549,   550,   551,   552,   553,   554,   555,   556,   557,   558,
     559,   560,   561,   562,   563,   564,   565,   566,   567,   568,
     569,   570,   571,   572,   573,   574,   575,   576,   577,   578,
     579,   580,   581,   582,   583,   584,   585,   586,   587,   588,
     589,   590,   591,   592,   593,   594,   595,   596,   597,   598,
     599,   600,   601,   602,   603,   604,   605,   606,   607,   608,
     609,   610,   611,   612,   613,   614,   615,   616,   617,   618,
     619,   620,   621,   622,   623,   624,   625,   626,   627,   628,
     629,   630,   631,   632,   633,   634,   635,   636,   637,   638,
     639,   640,   641,   642,   643,   644,   645,   646,   647,   648,
     649,   650,   651,   652,   653,   654,   655,   656,   657,   658,
     659,   660,   661,   662,   663,   664,   665,   666,   667,   668,
     669,   670,   671,   672,   673,   674,   675,   676,   677,   679,
     680,   681,   688,   689,   691,   693,   694,   696,   697,   698,
     700,   702,   703,   704,   705,   706,   707,   709,   710,   713,
     714,   715,   717,   720,   721,   722,   723,   724,   725,   726,
     727,   728,   730,   731,   733,   734,   735,   736,   738,   740,
     741,   743,   744,   746,   748,   750,   752,   753,   754,   756,
     757,   758,   759,   761,   762,   763,   764,   765,   767,   768,
     770,   771,   467,   469,   407,   684,   687,   448,   473,   474,
     678,   407,   454,   685,   687,   407,   455,   686,   687,   310,
     457,   458,   459,   460,    43,   470,   493,   494,   473,   499,
      47,   716,   359,   364,   373,   755,   769,   331,   366,   701,
     126,   369,   766,    97,   375,   760,    41,   368,   699,   323,
     354,   372,   692,   745,    63,    65,   352,   356,   737,   742,
     747,   749,   350,   357,   739,   751,    46,    48,   711,   718,
      40,    45,    50,   695,   708,   729,   511,   511,   511,   511,
     475,   678,   474,   473,   678,   678,   446,   678,   678,   678,
     678,   498,   311,   461,   462,   463,   460,   678,   477,   478,
     479,   471,   472,   678,   678,    44,   500,   499,   502,   503,
     504,   505,   506,   507,   507,   508,   508,   508,   508,   509,
     509,   510,   510,   511,   511,   511,   678,   678,   446,   446,
     446,   446,   312,   464,   465,   678,   446,    44,    47,   678,
     473,    61,   732,   678,   446,   479,   500
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
# define YYLEX yylex (YYLEX_PARAM)
#else
# define YYLEX yylex ()
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
		  Type, Value, Location); \
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
yy_symbol_value_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep, YYLTYPE const * const yylocationp)
#else
static void
yy_symbol_value_print (yyoutput, yytype, yyvaluep, yylocationp)
    FILE *yyoutput;
    int yytype;
    YYSTYPE const * const yyvaluep;
    YYLTYPE const * const yylocationp;
#endif
{
  if (!yyvaluep)
    return;
  YYUSE (yylocationp);
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
yy_symbol_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep, YYLTYPE const * const yylocationp)
#else
static void
yy_symbol_print (yyoutput, yytype, yyvaluep, yylocationp)
    FILE *yyoutput;
    int yytype;
    YYSTYPE const * const yyvaluep;
    YYLTYPE const * const yylocationp;
#endif
{
  if (yytype < YYNTOKENS)
    YYFPRINTF (yyoutput, "token %s (", yytname[yytype]);
  else
    YYFPRINTF (yyoutput, "nterm %s (", yytname[yytype]);

  YY_LOCATION_PRINT (yyoutput, *yylocationp);
  YYFPRINTF (yyoutput, ": ");
  yy_symbol_value_print (yyoutput, yytype, yyvaluep, yylocationp);
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
yy_reduce_print (YYSTYPE *yyvsp, YYLTYPE *yylsp, int yyrule)
#else
static void
yy_reduce_print (yyvsp, yylsp, yyrule)
    YYSTYPE *yyvsp;
    YYLTYPE *yylsp;
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
		       , &(yylsp[(yyi + 1) - (yynrhs)])		       );
      fprintf (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)		\
do {					\
  if (yydebug)				\
    yy_reduce_print (yyvsp, yylsp, Rule); \
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
yydestruct (const char *yymsg, int yytype, YYSTYPE *yyvaluep, YYLTYPE *yylocationp)
#else
static void
yydestruct (yymsg, yytype, yyvaluep, yylocationp)
    const char *yymsg;
    int yytype;
    YYSTYPE *yyvaluep;
    YYLTYPE *yylocationp;
#endif
{
  YYUSE (yyvaluep);
  YYUSE (yylocationp);

  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yytype, yyvaluep, yylocationp);

  switch (yytype)
    {

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



/* The look-ahead symbol.  */
int yychar;

/* The semantic value of the look-ahead symbol.  */
YYSTYPE yylval;

/* Number of syntax errors so far.  */
int yynerrs;
/* Location data for the look-ahead symbol.  */
YYLTYPE yylloc;



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

  /* The location stack.  */
  YYLTYPE yylsa[YYINITDEPTH];
  YYLTYPE *yyls = yylsa;
  YYLTYPE *yylsp;
  /* The locations where the error started and ended.  */
  YYLTYPE yyerror_range[2];

#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N), yylsp -= (N))

  YYSIZE_T yystacksize = YYINITDEPTH;

  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;
  YYLTYPE yyloc;

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
  yylsp = yyls;
#if YYLTYPE_IS_TRIVIAL
  /* Initialize the default location before parsing starts.  */
  yylloc.first_line   = yylloc.last_line   = 1;
  yylloc.first_column = yylloc.last_column = 0;
#endif

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
	YYLTYPE *yyls1 = yyls;

	/* Each stack pointer address is followed by the size of the
	   data in use in that stack, in bytes.  This used to be a
	   conditional around just the two extra args, but that might
	   be undefined if yyoverflow is a macro.  */
	yyoverflow (YY_("memory exhausted"),
		    &yyss1, yysize * sizeof (*yyssp),
		    &yyvs1, yysize * sizeof (*yyvsp),
		    &yyls1, yysize * sizeof (*yylsp),
		    &yystacksize);
	yyls = yyls1;
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
	YYSTACK_RELOCATE (yyls);
#  undef YYSTACK_RELOCATE
	if (yyss1 != yyssa)
	  YYSTACK_FREE (yyss1);
      }
# endif
#endif /* no yyoverflow */

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;
      yylsp = yyls + yysize - 1;

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
  *++yylsp = yylloc;
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

  /* Default location.  */
  YYLLOC_DEFAULT (yyloc, (yylsp - yylen), yylen);
  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
        case 2:

    { handle_file_begin(preprocessing_file_index); ;}
    break;

  case 3:

    {handle_file_end(preprocessing_file_index); ;}
    break;

  case 8:

    { /* handle_token(group_part_index); */ ;}
    break;

  case 13:

    { handle_if_open(PPD_IF_INDEX, (yyvsp[(2) - (2)].lval)); ;}
    break;

  case 14:

    { handle_if_open(PPD_IF_INDEX, 0); ;}
    break;

  case 17:

    { handle_ifdef_open(PPD_IFDEF_INDEX); ;}
    break;

  case 18:

    { handle_ifndef_open(PPD_IFNDEF_INDEX); ;}
    break;

  case 28:

    { handle_elif_open(PPD_ELIF_INDEX, (yyvsp[(2) - (2)].lval)); ;}
    break;

  case 29:

    { handle_elif_close(PPD_ELIF_INDEX); ;}
    break;

  case 32:

    { handle_else_open(PPD_ELSE_INDEX); ;}
    break;

  case 34:

    { handle_endif(PPD_ENDIF_INDEX); ;}
    break;

  case 36:

    { handle_include(PPD_INCLUDE_INDEX); ;}
    break;

  case 37:

    { handle_macro_close (object_macro_index); ;}
    break;

  case 38:

    { handle_macro_close (function_macro_index); ;}
    break;

  case 40:

    { handle_token_open (PPD_LINE_INDEX); ;}
    break;

  case 41:

    { handle_token_close (PPD_LINE_INDEX); ;}
    break;

  case 42:

    { handle_token_open (PPD_ERROR_INDEX); ;}
    break;

  case 43:

    { handle_token_close (PPD_ERROR_INDEX); ;}
    break;

  case 44:

    { handle_token_open (PPD_PRAGMA_INDEX); ;}
    break;

  case 45:

    { handle_token_close (PPD_PRAGMA_INDEX); ;}
    break;

  case 48:

    { handle_replacement_open (replacement_list_index); ;}
    break;

  case 49:

    { handle_replacement_close (replacement_list_index); ;}
    break;

  case 61:

    { handle_token(BCS_PUNCT_BACKSLASH_INDEX); ;}
    break;

  case 62:

    { handle_header_name(SYSTEM_HEADER_STRING_INDEX); ;}
    break;

  case 63:

    { handle_header_name(HEADER_STRING_INDEX); ;}
    break;

  case 68:

    { handle_identifier(IDENTIFIER_INDEX); ;}
    break;

  case 69:

    { handle_nonrepl_identifier(IDENTIFIER_INDEX); ;}
    break;

  case 238:

    { handle_string_token(WHITE_SPACE_INDEX); ;}
    break;

  case 239:

    { handle_pp_number(); ;}
    break;

  case 242:

    { handle_string_token(INTEGER_LITERAL_INDEX); ;}
    break;

  case 246:

    { handle_string_token(OCTAL_LITERAL_INDEX); ;}
    break;

  case 247:

    { handle_string_token(DECIMAL_LITERAL_INDEX); ;}
    break;

  case 248:

    { handle_string_token(HEXADECIMAL_LITERAL_INDEX); ;}
    break;

  case 249:

    { (yyval.lval) = (yyvsp[(1) - (1)].lval); ;}
    break;

  case 250:

    { (yyval.lval) = (yyvsp[(1) - (1)].lval); ;}
    break;

  case 251:

    { (yyval.lval) = (yyvsp[(1) - (1)].lval); ;}
    break;

  case 252:

    { (yyval.lval) = (yyvsp[(1) - (1)].lval); ;}
    break;

  case 253:

    { (yyval.lval) = (yyvsp[(1) - (1)].lval); ;}
    break;

  case 254:

    { (yyval.lval) = (yyvsp[(1) - (1)].lval); ;}
    break;

  case 255:

    { (yyval.lval) = (yyvsp[(1) - (1)].lval); ;}
    break;

  case 256:

    { handle_string_token(CHARACTER_LITERAL_INDEX); ;}
    break;

  case 257:

    { handle_string_token(L_CHARACTER_LITERAL_INDEX); ;}
    break;

  case 260:

    { handle_string_token(STRING_LITERAL_INDEX); ;}
    break;

  case 261:

    { handle_string_token(L_STRING_LITERAL_INDEX); ;}
    break;

  case 262:

    { handle_string_token(FLOATING_LITERAL_INDEX); ;}
    break;

  case 263:

    { (yyval.lval) = 0; ;}
    break;

  case 264:

    { (yyval.lval) = 1; ;}
    break;

  case 265:

    { (yyval.lval) = (yyvsp[(1) - (1)].ival); ;}
    break;

  case 326:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 327:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 328:

    {(yyval.lval) = (yyvsp[(3) - (3)].lval);;}
    break;

  case 329:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 330:

    {(yyval.lval) = ((yyvsp[(1) - (5)].lval)) ? (yyvsp[(3) - (5)].lval) : (yyvsp[(5) - (5)].lval);;}
    break;

  case 331:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 332:

    {(yyval.lval) = (yyvsp[(1) - (3)].lval) || (yyvsp[(3) - (3)].lval);;}
    break;

  case 333:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 334:

    {(yyval.lval) = (yyvsp[(1) - (3)].lval) && (yyvsp[(3) - (3)].lval);;}
    break;

  case 335:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 336:

    {(yyval.lval) = (yyvsp[(1) - (3)].lval) | (yyvsp[(3) - (3)].lval);;}
    break;

  case 337:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 338:

    {(yyval.lval) = (yyvsp[(1) - (3)].lval) ^ (yyvsp[(3) - (3)].lval);;}
    break;

  case 339:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 340:

    {(yyval.lval) = (yyvsp[(1) - (3)].lval) & (yyvsp[(3) - (3)].lval);;}
    break;

  case 341:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 342:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) == (yyvsp[(3) - (3)].lval));;}
    break;

  case 343:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) != (yyvsp[(3) - (3)].lval));;}
    break;

  case 344:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 345:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) < (yyvsp[(3) - (3)].lval));;}
    break;

  case 346:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) > (yyvsp[(3) - (3)].lval));;}
    break;

  case 347:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) <= (yyvsp[(3) - (3)].lval));;}
    break;

  case 348:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) >= (yyvsp[(3) - (3)].lval));;}
    break;

  case 349:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 350:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) << (yyvsp[(3) - (3)].lval));;}
    break;

  case 351:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) >> (yyvsp[(3) - (3)].lval));;}
    break;

  case 352:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 353:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) + (yyvsp[(3) - (3)].lval));;}
    break;

  case 354:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) - (yyvsp[(3) - (3)].lval));;}
    break;

  case 355:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 356:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) * (yyvsp[(3) - (3)].lval));;}
    break;

  case 357:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) / (yyvsp[(3) - (3)].lval));;}
    break;

  case 358:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) % (yyvsp[(3) - (3)].lval));;}
    break;

  case 359:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 360:

    {(yyval.lval) = (yyvsp[(2) - (2)].lval);;}
    break;

  case 361:

    {(yyval.lval) = -(yyvsp[(2) - (2)].lval);;}
    break;

  case 362:

    {(yyval.lval) = !(yyvsp[(2) - (2)].lval);;}
    break;

  case 363:

    {(yyval.lval) = ~(yyvsp[(2) - (2)].lval);;}
    break;

  case 364:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 365:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 366:

    {(yyval.lval) = (yyvsp[(2) - (3)].lval);;}
    break;

  case 367:

    {(yyval.lval) = 0;;}
    break;

  case 368:

    { handle_token(KWD_ABSTRACT_INDEX); ;}
    break;

  case 369:

    { handle_token(KWD_ABSTRACT_INTERFACE_INDEX); ;}
    break;

  case 370:

    { handle_token(KWD_ACCESS_INDEX); ;}
    break;

  case 371:

    { handle_token(KWD_ACTION_INDEX); ;}
    break;

  case 372:

    { handle_token(KWD_ADVANCE_INDEX); ;}
    break;

  case 373:

    { handle_token(KWD_ALLOCATABLE_INDEX); ;}
    break;

  case 374:

    { handle_token(KWD_ALLOCATE_INDEX); ;}
    break;

  case 375:

    { handle_token(KWD_ASSIGN_INDEX); ;}
    break;

  case 376:

    { handle_token(KWD_ASYNCHRONOUS_INDEX); ;}
    break;

  case 377:

    { handle_token(KWD_BACKSPACE_INDEX); ;}
    break;

  case 378:

    { handle_token(KWD_BIND_INDEX); ;}
    break;

  case 379:

    { handle_token(KWD_BLANK_INDEX); ;}
    break;

  case 380:

    { handle_token(KWD_BLOCK_INDEX); ;}
    break;

  case 381:

    { handle_token(KWD_BLOCK_DATA_INDEX); ;}
    break;

  case 382:

    { handle_token(KWD_CALL_INDEX); ;}
    break;

  case 383:

    { handle_token(KWD_CASE_INDEX); ;}
    break;

  case 384:

    { handle_token(KWD_CHARACTER_INDEX); ;}
    break;

  case 385:

    { handle_token(KWD_CLASS_INDEX); ;}
    break;

  case 386:

    { handle_token(KWD_CLASS_DEFAULT_INDEX); ;}
    break;

  case 387:

    { handle_token(KWD_CLASS_IS_INDEX); ;}
    break;

  case 388:

    { handle_token(KWD_CLOSE_INDEX); ;}
    break;

  case 389:

    { handle_token(KWD_COMMON_INDEX); ;}
    break;

  case 390:

    { handle_token(KWD_COMPLEX_INDEX); ;}
    break;

  case 391:

    { handle_token(KWD_CONTAINS_INDEX); ;}
    break;

  case 392:

    { handle_token(KWD_CONTIGUOUS_INDEX); ;}
    break;

  case 393:

    { handle_token(KWD_CONTINUE_INDEX); ;}
    break;

  case 394:

    { handle_token(KWD_CYCLE_INDEX); ;}
    break;

  case 395:

    { handle_token(KWD_DATA_INDEX); ;}
    break;

  case 396:

    { handle_token(KWD_DEALLOCATE_INDEX); ;}
    break;

  case 397:

    { handle_token(KWD_DEFAULT_INDEX); ;}
    break;

  case 398:

    { handle_token(KWD_DEFERRED_INDEX); ;}
    break;

  case 399:

    { handle_token(KWD_DIMENSION_INDEX); ;}
    break;

  case 400:

    { handle_token(KWD_DIRECT_INDEX); ;}
    break;

  case 401:

    { handle_token(KWD_DO_INDEX); ;}
    break;

  case 402:

    { handle_token(KWD_DOUBLE_INDEX); ;}
    break;

  case 403:

    { handle_token(KWD_DOUBLE_COMPLEX_INDEX); ;}
    break;

  case 404:

    { handle_token(KWD_DOUBLE_PRECISION_INDEX); ;}
    break;

  case 405:

    { handle_token(KWD_ELEMENTAL_INDEX); ;}
    break;

  case 406:

    { handle_token(KWD_ELSE_INDEX); ;}
    break;

  case 407:

    { handle_token(KWD_ELSE_IF_INDEX); ;}
    break;

  case 408:

    { handle_token(KWD_ELSE_WHERE_INDEX); ;}
    break;

  case 409:

    { handle_token(KWD_END_INDEX); ;}
    break;

  case 410:

    { handle_token(KWD_END_ASSOCIATE_INDEX); ;}
    break;

  case 411:

    { handle_token(KWD_END_BLOCK_INDEX); ;}
    break;

  case 412:

    { handle_token(KWD_END_BLOCK_DATA_INDEX); ;}
    break;

  case 413:

    { handle_token(KWD_END_DO_INDEX); ;}
    break;

  case 414:

    { handle_token(KWD_END_ENUM_INDEX); ;}
    break;

  case 415:

    { handle_token(KWD_END_FILE_INDEX); ;}
    break;

  case 416:

    { handle_token(KWD_END_FORALL_INDEX); ;}
    break;

  case 417:

    { handle_token(KWD_END_FUNCTION_INDEX); ;}
    break;

  case 418:

    { handle_token(KWD_END_IF_INDEX); ;}
    break;

  case 419:

    { handle_token(KWD_END_INTERFACE_INDEX); ;}
    break;

  case 420:

    { handle_token(KWD_END_MODULE_INDEX); ;}
    break;

  case 421:

    { handle_token(KWD_END_PROCEDURE_INDEX); ;}
    break;

  case 422:

    { handle_token(KWD_END_PROGRAM_INDEX); ;}
    break;

  case 423:

    { handle_token(KWD_END_SELECT_INDEX); ;}
    break;

  case 424:

    { handle_token(KWD_END_SUBMODULE_INDEX); ;}
    break;

  case 425:

    { handle_token(KWD_END_SUBROUTINE_INDEX); ;}
    break;

  case 426:

    { handle_token(KWD_END_TYPE_INDEX); ;}
    break;

  case 427:

    { handle_token(KWD_END_WHERE_INDEX); ;}
    break;

  case 428:

    { handle_token(KWD_ENTRY_INDEX); ;}
    break;

  case 429:

    { handle_token(KWD_EOR_INDEX); ;}
    break;

  case 430:

    { handle_token(KWD_EQUIVALENCE_INDEX); ;}
    break;

  case 431:

    { handle_token(KWD_ERR_INDEX); ;}
    break;

  case 432:

    { handle_token(KWD_ERRMSG_INDEX); ;}
    break;

  case 433:

    { handle_token(KWD_EXIST_INDEX); ;}
    break;

  case 434:

    { handle_token(KWD_EXIT_INDEX); ;}
    break;

  case 435:

    { handle_token(KWD_EXTENDS_INDEX); ;}
    break;

  case 436:

    { handle_token(KWD_EXTENSIBLE_INDEX); ;}
    break;

  case 437:

    { handle_token(KWD_EXTERNAL_INDEX); ;}
    break;

  case 438:

    { handle_token(KWD_FALSE_INDEX); ;}
    break;

  case 439:

    { handle_token(KWD_FILE_INDEX); ;}
    break;

  case 440:

    { handle_token(KWD_FINAL_INDEX); ;}
    break;

  case 441:

    { handle_token(KWD_FLUSH_INDEX); ;}
    break;

  case 442:

    { handle_token(KWD_FMT_INDEX); ;}
    break;

  case 443:

    { handle_token(KWD_FORALL_INDEX); ;}
    break;

  case 444:

    { handle_token(KWD_FORM_INDEX); ;}
    break;

  case 445:

    { handle_token(KWD_FORMAT_INDEX); ;}
    break;

  case 446:

    { handle_token(KWD_FORMATTED_INDEX); ;}
    break;

  case 447:

    { handle_token(KWD_FUNCTION_INDEX); ;}
    break;

  case 448:

    { handle_token(KWD_GENERIC_INDEX); ;}
    break;

  case 449:

    { handle_token(KWD_GOTO_INDEX); ;}
    break;

  case 450:

    { handle_token(KWD_IF_INDEX); ;}
    break;

  case 451:

    { handle_token(KWD_IMPLICIT_INDEX); ;}
    break;

  case 452:

    { handle_token(KWD_IMPLICIT_NONE_INDEX); ;}
    break;

  case 453:

    { handle_token(KWD_IMPORT_INDEX); ;}
    break;

  case 454:

    { handle_token(KWD_IMPURE_INDEX); ;}
    break;

  case 455:

    { handle_token(KWD_IN_INDEX); ;}
    break;

  case 456:

    { handle_token(KWD_IN_OUT_INDEX); ;}
    break;

  case 457:

    { handle_token(KWD_INCLUDE_INDEX); ;}
    break;

  case 458:

    { handle_token(KWD_INQUIRE_INDEX); ;}
    break;

  case 459:

    { handle_token(KWD_INTEGER_INDEX); ;}
    break;

  case 460:

    { handle_token(KWD_INTENT_INDEX); ;}
    break;

  case 461:

    { handle_token(KWD_INTERFACE_INDEX); ;}
    break;

  case 462:

    { handle_token(KWD_INTRINSIC_INDEX); ;}
    break;

  case 463:

    { handle_token(KWD_IOSTAT_INDEX); ;}
    break;

  case 464:

    { handle_token(KWD_IOMSG_INDEX); ;}
    break;

  case 465:

    { handle_token(KWD_KIND_INDEX); ;}
    break;

  case 466:

    { handle_token(KWD_LET_INDEX); ;}
    break;

  case 467:

    { handle_token(KWD_LOGICAL_INDEX); ;}
    break;

  case 468:

    { handle_token(KWD_MODULE_INDEX); ;}
    break;

  case 469:

    { handle_token(KWD_MOLD_INDEX); ;}
    break;

  case 470:

    { handle_token(KWD_NAME_INDEX); ;}
    break;

  case 471:

    { handle_token(KWD_NAMED_INDEX); ;}
    break;

  case 472:

    { handle_token(KWD_NAMELIST_INDEX); ;}
    break;

  case 473:

    { handle_token(KWD_NEXTREC_INDEX); ;}
    break;

  case 474:

    { handle_token(KWD_NON_INTRINSIC_INDEX); ;}
    break;

  case 475:

    { handle_token(KWD_NON_OVERRIDABLE_INDEX); ;}
    break;

  case 476:

    { handle_token(KWD_NONKIND_INDEX); ;}
    break;

  case 477:

    { handle_token(KWD_NONE_INDEX); ;}
    break;

  case 478:

    { handle_token(KWD_NOPASS_INDEX); ;}
    break;

  case 479:

    { handle_token(KWD_NULLIFY_INDEX); ;}
    break;

  case 480:

    { handle_token(KWD_NUMBER_INDEX); ;}
    break;

  case 481:

    { handle_token(KWD_OPEN_INDEX); ;}
    break;

  case 482:

    { handle_token(KWD_OPENED_INDEX); ;}
    break;

  case 483:

    { handle_token(KWD_OPERATOR_INDEX); ;}
    break;

  case 484:

    { handle_token(KWD_OPTIONAL_INDEX); ;}
    break;

  case 485:

    { handle_token(KWD_OUT_INDEX); ;}
    break;

  case 486:

    { handle_token(KWD_PAD_INDEX); ;}
    break;

  case 487:

    { handle_token(KWD_PARAMETER_INDEX); ;}
    break;

  case 488:

    { handle_token(KWD_PASS_INDEX); ;}
    break;

  case 489:

    { handle_token(KWD_PAUSE_INDEX); ;}
    break;

  case 490:

    { handle_token(KWD_POINTER_INDEX); ;}
    break;

  case 491:

    { handle_token(KWD_POSITION_INDEX); ;}
    break;

  case 492:

    { handle_token(KWD_PRECISION_INDEX); ;}
    break;

  case 493:

    { handle_token(KWD_PRINT_INDEX); ;}
    break;

  case 494:

    { handle_token(KWD_PRIVATE_INDEX); ;}
    break;

  case 495:

    { handle_token(KWD_PROCEDURE_INDEX); ;}
    break;

  case 496:

    { handle_token(KWD_PROGRAM_INDEX); ;}
    break;

  case 497:

    { handle_token(KWD_PROTECTED_INDEX); ;}
    break;

  case 498:

    { handle_token(KWD_PUBLIC_INDEX); ;}
    break;

  case 499:

    { handle_token(KWD_PURE_INDEX); ;}
    break;

  case 500:

    { handle_token(KWD_READ_INDEX); ;}
    break;

  case 501:

    { handle_token(KWD_READ_FORMATTED_INDEX); ;}
    break;

  case 502:

    { handle_token(KWD_READ_UNFORMATTED_INDEX); ;}
    break;

  case 503:

    { handle_token(KWD_REAL_INDEX); ;}
    break;

  case 504:

    { handle_token(KWD_REC_INDEX); ;}
    break;

  case 505:

    { handle_token(KWD_RECL_INDEX); ;}
    break;

  case 506:

    { handle_token(KWD_RETURN_INDEX); ;}
    break;

  case 507:

    { handle_token(KWD_REWIND_INDEX); ;}
    break;

  case 508:

    { handle_token(KWD_ROUND_INDEX); ;}
    break;

  case 509:

    { handle_token(KWD_SAVE_INDEX); ;}
    break;

  case 510:

    { handle_token(KWD_SELECT_CASE_INDEX); ;}
    break;

  case 511:

    { handle_token(KWD_SELECT_TYPE_INDEX); ;}
    break;

  case 512:

    { handle_token(KWD_SEQUENCE_INDEX); ;}
    break;

  case 513:

    { handle_token(KWD_SEQUENTIAL_INDEX); ;}
    break;

  case 514:

    { handle_token(KWD_SIGN_INDEX); ;}
    break;

  case 515:

    { handle_token(KWD_SIZE_INDEX); ;}
    break;

  case 516:

    { handle_token(KWD_SOURCE_INDEX); ;}
    break;

  case 517:

    { handle_token(KWD_STATUS_INDEX); ;}
    break;

  case 518:

    { handle_token(KWD_STOP_INDEX); ;}
    break;

  case 519:

    { handle_token(KWD_SUBROUTINE_INDEX); ;}
    break;

  case 520:

    { handle_token(KWD_TARGET_INDEX); ;}
    break;

  case 521:

    { handle_token(KWD_THEN_INDEX); ;}
    break;

  case 522:

    { handle_token(KWD_TRUE_INDEX); ;}
    break;

  case 523:

    { handle_token(KWD_TYPE_INDEX); ;}
    break;

  case 524:

    { handle_token(KWD_UNFORMATTED_INDEX); ;}
    break;

  case 525:

    { handle_token(KWD_UNIT_INDEX); ;}
    break;

  case 526:

    { handle_token(KWD_USE_INDEX); ;}
    break;

  case 527:

    { handle_token(KWD_VALUE_INDEX); ;}
    break;

  case 528:

    { handle_token(KWD_VOLATILE_INDEX); ;}
    break;

  case 529:

    { handle_token(KWD_WHERE_INDEX); ;}
    break;

  case 530:

    { handle_token(KWD_WRITE_INDEX); ;}
    break;

  case 531:

    { handle_token(KWD_WRITE_FORMATTED_INDEX); ;}
    break;

  case 532:

    { handle_token(KWD_WRITE_UNFORMATTED_INDEX); ;}
    break;

  case 534:

    { handle_token(BCS_PUNCT_HASH_INDEX); ;}
    break;

  case 535:

    { handle_token(ALT_PUNCT_HASH_INDEX); ;}
    break;

  case 536:

    { handle_token(OP_STRINGIZE_INDEX); ;}
    break;

  case 537:

    { handle_token(OP_TOKEN_SPLICE_INDEX); ;}
    break;

  case 538:

    { handle_token(ALT_OP_TOKEN_SPLICE_INDEX); ;}
    break;

  case 539:

    { handle_macro_open(function_macro_index /*MACRO_FUNCTION_IDENTIFIER_INDEX*/); ;}
    break;

  case 540:

    { handle_invalid_macro_id(OP_ALT_LOGICAL_AND_INDEX); ;}
    break;

  case 541:

    { handle_invalid_macro_id(OP_ALT_ASSIGN_BIT_AND_INDEX); ;}
    break;

  case 542:

    { handle_invalid_macro_id(OP_ALT_BIT_AND_INDEX); ;}
    break;

  case 543:

    { handle_invalid_macro_id(OP_ALT_BIT_OR_INDEX); ;}
    break;

  case 544:

    { handle_invalid_macro_id(OP_ALT_BIT_NOT_INDEX); ;}
    break;

  case 545:

    { handle_invalid_macro_id(OP_ALT_LOGICAL_NOT_INDEX); ;}
    break;

  case 546:

    { handle_invalid_macro_id(OP_ALT_NE_INDEX); ;}
    break;

  case 547:

    { handle_invalid_macro_id(OP_ALT_LOGICAL_OR_INDEX); ;}
    break;

  case 548:

    { handle_invalid_macro_id(OP_ALT_ASSIGN_BIT_OR_INDEX); ;}
    break;

  case 549:

    { handle_invalid_macro_id(OP_ALT_BIT_PLUS_INDEX); ;}
    break;

  case 550:

    { handle_invalid_macro_id(OP_ALT_ASSIGN_BIT_PLUS_INDEX); ;}
    break;

  case 551:

    { handle_macro_open(object_macro_index/*MACRO_OBJECT_IDENTIFIER_INDEX*/); ;}
    break;

  case 553:

    { handle_macro_undef(PPD_UNDEF_INDEX); ;}
    break;

  case 554:

    { pop(); ;}
    break;

  case 557:

    { handle_invalid_macro_id(OP_ALT_LOGICAL_AND_INDEX); ;}
    break;

  case 558:

    { handle_invalid_macro_id(OP_ALT_ASSIGN_BIT_AND_INDEX); ;}
    break;

  case 559:

    { handle_invalid_macro_id(OP_ALT_BIT_AND_INDEX); ;}
    break;

  case 560:

    { handle_invalid_macro_id(OP_ALT_BIT_OR_INDEX); ;}
    break;

  case 561:

    { handle_invalid_macro_id(OP_ALT_BIT_NOT_INDEX); ;}
    break;

  case 562:

    { handle_invalid_macro_id(OP_ALT_LOGICAL_NOT_INDEX); ;}
    break;

  case 563:

    { handle_invalid_macro_id(OP_ALT_NE_INDEX); ;}
    break;

  case 564:

    { handle_invalid_macro_id(OP_ALT_LOGICAL_OR_INDEX); ;}
    break;

  case 565:

    { handle_invalid_macro_id(OP_ALT_ASSIGN_BIT_OR_INDEX); ;}
    break;

  case 566:

    { handle_invalid_macro_id(OP_ALT_BIT_PLUS_INDEX); ;}
    break;

  case 567:

    { handle_invalid_macro_id(OP_ALT_ASSIGN_BIT_PLUS_INDEX); ;}
    break;

  case 568:

    { handle_token(OP_LOGICAL_NOT_INDEX); ;}
    break;

  case 569:

    { handle_token(OP_ALT_LOGICAL_NOT_INDEX); ;}
    break;

  case 572:

    { handle_token(OP_NE_INDEX); ;}
    break;

  case 573:

    { handle_token(OP_ALT_NE_INDEX); ;}
    break;

  case 577:

    { handle_token(OP_MEMBER_INDEX); ;}
    break;

  case 579:

    { handle_token(OP_ASSIGN_MODULO_INDEX); ;}
    break;

  case 580:

    { handle_token(BCS_PUNCT_AMPERSAND_INDEX); ;}
    break;

  case 581:

    { handle_token(OP_ALT_BIT_AND_INDEX); ;}
    break;

  case 584:

    { handle_token(OP_LOGICAL_AND_INDEX); ;}
    break;

  case 585:

    { handle_token(OP_ALT_LOGICAL_AND_INDEX); ;}
    break;

  case 588:

    { handle_token(OP_ASSIGN_BIT_AND_INDEX); ;}
    break;

  case 589:

    { handle_token(OP_ALT_ASSIGN_BIT_AND_INDEX); ;}
    break;

  case 590:

    { handle_token_open(BCS_PUNCT_OPEN_PARENTHESIS_INDEX); ;}
    break;

  case 591:

    { handle_token_close(BCS_PUNCT_CLOSE_PARENTHESIS_INDEX); ;}
    break;

  case 592:

    { handle_token_open(OPEN_PARENTHESIS_SLASH_INDEX); ;}
    break;

  case 593:

    { handle_token_close(CLOSE_PARENTHESIS_SLASH_INDEX); ;}
    break;

  case 594:

    { handle_token(BCS_PUNCT_ASTERISK_INDEX); ;}
    break;

  case 596:

    { handle_token(OP_ASSIGN_MULTIPLY_INDEX); ;}
    break;

  case 597:

    { handle_token(BCS_PUNCT_PLUS_INDEX); ;}
    break;

  case 600:

    { handle_token(OP_INCREMENT_INDEX); ;}
    break;

  case 601:

    { handle_token(OP_ASSIGN_PLUS_INDEX); ;}
    break;

  case 602:

    { handle_token(BCS_PUNCT_COMMA_INDEX); ;}
    break;

  case 604:

    { handle_token(BCS_PUNCT_MINUS_INDEX); ;}
    break;

  case 607:

    { handle_token(OP_DECREMENT_INDEX); ;}
    break;

  case 608:

    { handle_token(OP_ASSIGN_MINUS_INDEX); ;}
    break;

  case 609:

    { handle_token(OP_POINTER_MEMBER_INDEX); ;}
    break;

  case 610:

    { handle_token(OP_POINTER_POINTER_TO_MEMBER_INDEX); ;}
    break;

  case 611:

    { handle_token(BCS_PUNCT_PERIOD_INDEX); ;}
    break;

  case 612:

    { handle_token(DECL_VAR_ARGS_INDEX); ;}
    break;

  case 613:

    { handle_token(OP_OBJECT_POINTER_TO_MEMBER_INDEX); ;}
    break;

  case 615:

    { handle_token(OP_DIVIDE_INDEX); ;}
    break;

  case 617:

    { handle_token(OP_ASSIGN_DIVIDE_INDEX); ;}
    break;

  case 618:

    { handle_token(BCS_PUNCT_COLON_INDEX); ;}
    break;

  case 620:

    { handle_token(PUNC_DBL_COLON_INDEX); ;}
    break;

  case 621:

    { handle_token(PUNC_ARROW_INDEX); ;}
    break;

  case 622:

    { handle_token(BCS_PUNCT_SEMICOLON_INDEX); ;}
    break;

  case 623:

    { handle_token(BCS_PUNCT_LESS_THAN_INDEX); ;}
    break;

  case 625:

    { handle_token(OP_SHIFT_LEFT_INDEX); ;}
    break;

  case 627:

    { handle_token(OP_ASSIGN_SHIFT_LEFT_INDEX); ;}
    break;

  case 628:

    { handle_token(OP_LE_INDEX); ;}
    break;

  case 630:

    { handle_token(BCS_PUNCT_EQUAL_INDEX); ;}
    break;

  case 631:

    { handle_token(OP_EQ_INDEX); ;}
    break;

  case 633:

    { handle_token(BCS_PUNCT_GREATER_THAN_INDEX); ;}
    break;

  case 635:

    { handle_token(OP_GE_INDEX); ;}
    break;

  case 637:

    { handle_token(OP_SHIFT_RIGHT_INDEX); ;}
    break;

  case 638:

    { handle_token(OP_SHIFT_RIGHT_INDEX); ;}
    break;

  case 639:

    { handle_token(OP_ASSIGN_SHIFT_RIGHT_INDEX); ;}
    break;

  case 641:

    { handle_token(OP_CONDITIONAL_INDEX); ;}
    break;

  case 643:

    { handle_token_open(BCS_PUNCT_OPEN_BRACKET_INDEX); ;}
    break;

  case 644:

    { handle_token_open(ALT_PUNCT_OPEN_BRACKET_INDEX); ;}
    break;

  case 645:

    { handle_token_close(BCS_PUNCT_CLOSE_BRACKET_INDEX); ;}
    break;

  case 646:

    { handle_token_close(ALT_PUNCT_CLOSE_BRACKET_INDEX); ;}
    break;

  case 647:

    { handle_token(OP_BIT_PLUS_INDEX); ;}
    break;

  case 648:

    { handle_token(OP_ALT_BIT_PLUS_INDEX); ;}
    break;

  case 651:

    { handle_token(OP_ASSIGN_BIT_PLUS_INDEX); ;}
    break;

  case 652:

    { handle_token(OP_ALT_ASSIGN_BIT_PLUS_INDEX); ;}
    break;

  case 653:

    { handle_token_open(BCS_PUNCT_OPEN_BRACE_INDEX); ;}
    break;

  case 654:

    { handle_token_open(ALT_PUNCT_OPEN_BRACE_INDEX); ;}
    break;

  case 655:

    { handle_token_close(BCS_PUNCT_CLOSE_BRACE_INDEX); ;}
    break;

  case 656:

    { handle_token_close(ALT_PUNCT_CLOSE_BRACE_INDEX); ;}
    break;

  case 657:

    { handle_token(OP_BIT_OR_INDEX); ;}
    break;

  case 658:

    { handle_token(OP_BIT_OR_INDEX); ;}
    break;

  case 661:

    { handle_token(OP_ASSIGN_BIT_OR_INDEX); ;}
    break;

  case 662:

    { handle_token(OP_ALT_ASSIGN_BIT_OR_INDEX); ;}
    break;

  case 663:

    { handle_token(OP_LOGICAL_OR_INDEX); ;}
    break;

  case 664:

    { handle_token(OP_ALT_LOGICAL_OR_INDEX); ;}
    break;

  case 667:

    { handle_token(OP_BIT_NOT_INDEX); ;}
    break;

  case 668:

    { handle_token(OP_ALT_BIT_NOT_INDEX); ;}
    break;


/* Line 1267 of yacc.c.  */

      default: break;
    }
  YY_SYMBOL_PRINT ("-> $$ =", yyr1[yyn], &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);

  *++yyvsp = yyval;
  *++yylsp = yyloc;

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

  yyerror_range[0] = yylloc;

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
		      yytoken, &yylval, &yylloc);
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

  yyerror_range[0] = yylsp[1-yylen];
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

      yyerror_range[0] = *yylsp;
      yydestruct ("Error: popping",
		  yystos[yystate], yyvsp, yylsp);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  if (yyn == YYFINAL)
    YYACCEPT;

  *++yyvsp = yylval;

  yyerror_range[1] = yylloc;
  /* Using YYLLOC is tempting, but would change the location of
     the look-ahead.  YYLOC is available though.  */
  YYLLOC_DEFAULT (yyloc, (yyerror_range - 1), 2);
  *++yylsp = yyloc;

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
		 yytoken, &yylval, &yylloc);
  /* Do not reclaim the symbols of the rule which action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
		  yystos[*yyssp], yyvsp, yylsp);
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





const char *get_yytname(int token) {
  return yytname[yytranslate[token]];
}
void yyerror(char const *s) {
  extern int error_count;
  extern int yychar;
  fprintf(stderr, "%s\n", s);
    if (yychar > 126) {
      fprintf(stderr, "File %s; line %d: yychar = %s(%d)\n",getCurrentFilename(), getCurrentLineNumber(), get_yytname(yychar), yychar);
    } else {
      fprintf(stderr, "File %s; line %d: yychar = %c\n",getCurrentFilename(),getCurrentLineNumber(), yychar);
    }
  error_count++;
}


