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
     KWD_ASM = 390,
     KWD_AUTO = 391,
     KWD_BOOL = 392,
     KWD_BREAK = 393,
     KWD_CASE = 394,
     KWD_CATCH = 395,
     KWD_CHAR = 396,
     KWD_CLASS = 397,
     KWD_CONST = 398,
     KWD_CONST_CAST = 399,
     KWD_CONTINUE = 400,
     KWD_DEFAULT = 401,
     KWD_DEFINED = 402,
     KWD_DELETE = 403,
     KWD_DO = 404,
     KWD_DOUBLE = 405,
     KWD_DYNAMIC_CAST = 406,
     KWD_ELSE = 407,
     KWD_ENUM = 408,
     KWD_EXPLICIT = 409,
     KWD_EXPORT = 410,
     KWD_EXTERN = 411,
     KWD_FALSE = 412,
     KWD_FLOAT = 413,
     KWD_FOR = 414,
     KWD_FRIEND = 415,
     KWD_GOTO = 416,
     KWD_IF = 417,
     KWD_INLINE = 418,
     KWD_INT = 419,
     KWD_LONG = 420,
     KWD_MUTABLE = 421,
     KWD_NAMESPACE = 422,
     KWD_NEW = 423,
     KWD_OPERATOR = 424,
     KWD_PRIVATE = 425,
     KWD_PROTECTED = 426,
     KWD_PUBLIC = 427,
     KWD_REGISTER = 428,
     KWD_REINTERPRET_CAST = 429,
     KWD_RETURN = 430,
     KWD_SHORT = 431,
     KWD_SIGNED = 432,
     KWD_SIZEOF = 433,
     KWD_STATIC = 434,
     KWD_STATIC_CAST = 435,
     KWD_STRUCT = 436,
     KWD_SWITCH = 437,
     KWD_TEMPLATE = 438,
     KWD_THIS = 439,
     KWD_THROW = 440,
     KWD_TRUE = 441,
     KWD_TRY = 442,
     KWD_TYPEDEF = 443,
     KWD_TYPENAME = 444,
     KWD_TYPEID = 445,
     KWD_UNION = 446,
     KWD_UNSIGNED = 447,
     KWD_USING = 448,
     KWD_VIRTUAL = 449,
     KWD_VOID = 450,
     KWD_VOLATILE = 451,
     KWD_WCHAR_T = 452,
     KWD_WHILE = 453,
     PPD_NULL = 454,
     PPD_DEFINE = 455,
     PPD_ELIF = 456,
     PPD_ELSE = 457,
     PPD_ENDIF = 458,
     PPD_ERROR = 459,
     PPD_IF = 460,
     PPD_IFDEF = 461,
     PPD_IFNDEF = 462,
     PPD_INCLUDE = 463,
     PPD_LINE = 464,
     PPD_PRAGMA = 465,
     PPD_UNDEF = 466,
     OP_LOGICAL_NOT = 467,
     OP_NE = 468,
     OP_STRINGIZE = 469,
     OP_TOKEN_SPLICE = 470,
     OP_MODULO = 471,
     ALT_OP_TOKEN_SPLICE = 472,
     OP_ASSIGN_MODULO = 473,
     OP_BIT_AND = 474,
     OP_ADDRESS = 475,
     OP_LOGICAL_AND = 476,
     OP_ASSIGN_BIT_AND = 477,
     OP_DEREFERENCE = 478,
     OP_MULTIPLY = 479,
     OP_ASSIGN_MULTIPLY = 480,
     OP_PLUS = 481,
     OP_INCREMENT = 482,
     OP_ASSIGN_PLUS = 483,
     OP_MINUS = 484,
     OP_DECREMENT = 485,
     OP_ASSIGN_MINUS = 486,
     OP_POINTER_MEMBER = 487,
     OP_POINTER_POINTER_TO_MEMBER = 488,
     OP_OBJECT_MEMBER = 489,
     OP_OBJECT_POINTER_TO_MEMBER = 490,
     OP_DIVIDE = 491,
     OP_ASSIGN_DIVIDE = 492,
     OP_ELSE = 493,
     OP_SCOPE_REF = 494,
     OP_LT = 495,
     OP_SHIFT_LEFT = 496,
     OP_ASSIGN_SHIFT_LEFT = 497,
     OP_LE = 498,
     OP_ASSIGN = 499,
     OP_EQ = 500,
     OP_GT = 501,
     OP_GE = 502,
     OP_SHIFT_RIGHT = 503,
     OP_ASSIGN_SHIFT_RIGHT = 504,
     OP_CONDITIONAL = 505,
     OP_BIT_PLUS = 506,
     OP_ASSIGN_BIT_PLUS = 507,
     OP_BIT_OR = 508,
     OP_ASSIGN_BIT_OR = 509,
     OP_LOGICAL_OR = 510,
     OP_BIT_NOT = 511,
     OP_ALT_LOGICAL_AND = 512,
     OP_ALT_ASSIGN_BIT_AND = 513,
     OP_ALT_BIT_AND = 514,
     OP_ALT_BIT_OR = 515,
     OP_ALT_BIT_NOT = 516,
     OP_ALT_LOGICAL_NOT = 517,
     OP_ALT_NE = 518,
     OP_ALT_LOGICAL_OR = 519,
     OP_ALT_ASSIGN_BIT_OR = 520,
     OP_ALT_BIT_PLUS = 521,
     OP_ALT_ASSIGN_BIT_PLUS = 522,
     INV_ALT_LOGICAL_AND = 523,
     INV_ALT_ASSIGN_BIT_AND = 524,
     INV_ALT_BIT_AND = 525,
     INV_ALT_BIT_OR = 526,
     INV_ALT_BIT_NOT = 527,
     INV_ALT_LOGICAL_NOT = 528,
     INV_ALT_NE = 529,
     INV_ALT_LOGICAL_OR = 530,
     INV_ALT_ASSIGN_BIT_OR = 531,
     INV_ALT_BIT_PLUS = 532,
     INV_ALT_ASSIGN_BIT_PLUS = 533,
     INV_MFI_LOGICAL_AND = 534,
     INV_MFI_ASSIGN_BIT_AND = 535,
     INV_MFI_BIT_AND = 536,
     INV_MFI_BIT_OR = 537,
     INV_MFI_BIT_NOT = 538,
     INV_MFI_LOGICAL_NOT = 539,
     INV_MFI_NE = 540,
     INV_MFI_LOGICAL_OR = 541,
     INV_MFI_ASSIGN_BIT_OR = 542,
     INV_MFI_BIT_PLUS = 543,
     INV_MFI_ASSIGN_BIT_PLUS = 544,
     DECL_REFERENCE = 545,
     DECL_POINTER = 546,
     DECL_VAR_ARGS = 547,
     SYSTEM_HEADER_STRING = 548,
     HEADER_STRING = 549,
     IDENTIFIER = 550,
     NON_REPLACEABLE_IDENTIFIER = 551,
     MACRO_FUNCTION_IDENTIFIER = 552,
     MACRO_OBJECT_IDENTIFIER = 553,
     REPLACED_IDENTIFIER = 554,
     PP_NUMBER = 555,
     CHARACTER_LITERAL = 556,
     L_CHARACTER_LITERAL = 557,
     STRING_LITERAL = 558,
     L_STRING_LITERAL = 559,
     INTEGER_LITERAL = 560,
     OCTAL_LITERAL = 561,
     DECIMAL_LITERAL = 562,
     HEXADECIMAL_LITERAL = 563,
     FLOATING_LITERAL = 564,
     UNIVERSAL_CHARACTER_NAME = 565,
     USE_ON_CODE = 566,
     PUNC_INITIALIZE = 567,
     PUNC_SYNONYM = 568,
     DONT_CARE = 569,
     RESERVED_WORD = 570,
     ACCESS_SPECIFIER = 571,
     BOOLEAN_LITERAL = 572,
     CV_QUALIFIER = 573,
     INTRINSIC_TYPE = 574,
     FUNCTION_SPECIFIER = 575,
     STORAGE_CLASS_SPECIFIER = 576,
     USER_TOKEN = 577,
     SYMBOL = 578,
     COMMENT = 579,
     BLOCK_COMMENT = 580,
     END_OF_STATEMENT = 581,
     BLOCK_OPEN = 582,
     BLOCK_CLOSE = 583,
     LIST_OPEN = 584,
     LIST_SEPARATOR = 585,
     LIST_CLOSE = 586
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
#define KWD_ASM 390
#define KWD_AUTO 391
#define KWD_BOOL 392
#define KWD_BREAK 393
#define KWD_CASE 394
#define KWD_CATCH 395
#define KWD_CHAR 396
#define KWD_CLASS 397
#define KWD_CONST 398
#define KWD_CONST_CAST 399
#define KWD_CONTINUE 400
#define KWD_DEFAULT 401
#define KWD_DEFINED 402
#define KWD_DELETE 403
#define KWD_DO 404
#define KWD_DOUBLE 405
#define KWD_DYNAMIC_CAST 406
#define KWD_ELSE 407
#define KWD_ENUM 408
#define KWD_EXPLICIT 409
#define KWD_EXPORT 410
#define KWD_EXTERN 411
#define KWD_FALSE 412
#define KWD_FLOAT 413
#define KWD_FOR 414
#define KWD_FRIEND 415
#define KWD_GOTO 416
#define KWD_IF 417
#define KWD_INLINE 418
#define KWD_INT 419
#define KWD_LONG 420
#define KWD_MUTABLE 421
#define KWD_NAMESPACE 422
#define KWD_NEW 423
#define KWD_OPERATOR 424
#define KWD_PRIVATE 425
#define KWD_PROTECTED 426
#define KWD_PUBLIC 427
#define KWD_REGISTER 428
#define KWD_REINTERPRET_CAST 429
#define KWD_RETURN 430
#define KWD_SHORT 431
#define KWD_SIGNED 432
#define KWD_SIZEOF 433
#define KWD_STATIC 434
#define KWD_STATIC_CAST 435
#define KWD_STRUCT 436
#define KWD_SWITCH 437
#define KWD_TEMPLATE 438
#define KWD_THIS 439
#define KWD_THROW 440
#define KWD_TRUE 441
#define KWD_TRY 442
#define KWD_TYPEDEF 443
#define KWD_TYPENAME 444
#define KWD_TYPEID 445
#define KWD_UNION 446
#define KWD_UNSIGNED 447
#define KWD_USING 448
#define KWD_VIRTUAL 449
#define KWD_VOID 450
#define KWD_VOLATILE 451
#define KWD_WCHAR_T 452
#define KWD_WHILE 453
#define PPD_NULL 454
#define PPD_DEFINE 455
#define PPD_ELIF 456
#define PPD_ELSE 457
#define PPD_ENDIF 458
#define PPD_ERROR 459
#define PPD_IF 460
#define PPD_IFDEF 461
#define PPD_IFNDEF 462
#define PPD_INCLUDE 463
#define PPD_LINE 464
#define PPD_PRAGMA 465
#define PPD_UNDEF 466
#define OP_LOGICAL_NOT 467
#define OP_NE 468
#define OP_STRINGIZE 469
#define OP_TOKEN_SPLICE 470
#define OP_MODULO 471
#define ALT_OP_TOKEN_SPLICE 472
#define OP_ASSIGN_MODULO 473
#define OP_BIT_AND 474
#define OP_ADDRESS 475
#define OP_LOGICAL_AND 476
#define OP_ASSIGN_BIT_AND 477
#define OP_DEREFERENCE 478
#define OP_MULTIPLY 479
#define OP_ASSIGN_MULTIPLY 480
#define OP_PLUS 481
#define OP_INCREMENT 482
#define OP_ASSIGN_PLUS 483
#define OP_MINUS 484
#define OP_DECREMENT 485
#define OP_ASSIGN_MINUS 486
#define OP_POINTER_MEMBER 487
#define OP_POINTER_POINTER_TO_MEMBER 488
#define OP_OBJECT_MEMBER 489
#define OP_OBJECT_POINTER_TO_MEMBER 490
#define OP_DIVIDE 491
#define OP_ASSIGN_DIVIDE 492
#define OP_ELSE 493
#define OP_SCOPE_REF 494
#define OP_LT 495
#define OP_SHIFT_LEFT 496
#define OP_ASSIGN_SHIFT_LEFT 497
#define OP_LE 498
#define OP_ASSIGN 499
#define OP_EQ 500
#define OP_GT 501
#define OP_GE 502
#define OP_SHIFT_RIGHT 503
#define OP_ASSIGN_SHIFT_RIGHT 504
#define OP_CONDITIONAL 505
#define OP_BIT_PLUS 506
#define OP_ASSIGN_BIT_PLUS 507
#define OP_BIT_OR 508
#define OP_ASSIGN_BIT_OR 509
#define OP_LOGICAL_OR 510
#define OP_BIT_NOT 511
#define OP_ALT_LOGICAL_AND 512
#define OP_ALT_ASSIGN_BIT_AND 513
#define OP_ALT_BIT_AND 514
#define OP_ALT_BIT_OR 515
#define OP_ALT_BIT_NOT 516
#define OP_ALT_LOGICAL_NOT 517
#define OP_ALT_NE 518
#define OP_ALT_LOGICAL_OR 519
#define OP_ALT_ASSIGN_BIT_OR 520
#define OP_ALT_BIT_PLUS 521
#define OP_ALT_ASSIGN_BIT_PLUS 522
#define INV_ALT_LOGICAL_AND 523
#define INV_ALT_ASSIGN_BIT_AND 524
#define INV_ALT_BIT_AND 525
#define INV_ALT_BIT_OR 526
#define INV_ALT_BIT_NOT 527
#define INV_ALT_LOGICAL_NOT 528
#define INV_ALT_NE 529
#define INV_ALT_LOGICAL_OR 530
#define INV_ALT_ASSIGN_BIT_OR 531
#define INV_ALT_BIT_PLUS 532
#define INV_ALT_ASSIGN_BIT_PLUS 533
#define INV_MFI_LOGICAL_AND 534
#define INV_MFI_ASSIGN_BIT_AND 535
#define INV_MFI_BIT_AND 536
#define INV_MFI_BIT_OR 537
#define INV_MFI_BIT_NOT 538
#define INV_MFI_LOGICAL_NOT 539
#define INV_MFI_NE 540
#define INV_MFI_LOGICAL_OR 541
#define INV_MFI_ASSIGN_BIT_OR 542
#define INV_MFI_BIT_PLUS 543
#define INV_MFI_ASSIGN_BIT_PLUS 544
#define DECL_REFERENCE 545
#define DECL_POINTER 546
#define DECL_VAR_ARGS 547
#define SYSTEM_HEADER_STRING 548
#define HEADER_STRING 549
#define IDENTIFIER 550
#define NON_REPLACEABLE_IDENTIFIER 551
#define MACRO_FUNCTION_IDENTIFIER 552
#define MACRO_OBJECT_IDENTIFIER 553
#define REPLACED_IDENTIFIER 554
#define PP_NUMBER 555
#define CHARACTER_LITERAL 556
#define L_CHARACTER_LITERAL 557
#define STRING_LITERAL 558
#define L_STRING_LITERAL 559
#define INTEGER_LITERAL 560
#define OCTAL_LITERAL 561
#define DECIMAL_LITERAL 562
#define HEXADECIMAL_LITERAL 563
#define FLOATING_LITERAL 564
#define UNIVERSAL_CHARACTER_NAME 565
#define USE_ON_CODE 566
#define PUNC_INITIALIZE 567
#define PUNC_SYNONYM 568
#define DONT_CARE 569
#define RESERVED_WORD 570
#define ACCESS_SPECIFIER 571
#define BOOLEAN_LITERAL 572
#define CV_QUALIFIER 573
#define INTRINSIC_TYPE 574
#define FUNCTION_SPECIFIER 575
#define STORAGE_CLASS_SPECIFIER 576
#define USER_TOKEN 577
#define SYMBOL 578
#define COMMENT 579
#define BLOCK_COMMENT 580
#define END_OF_STATEMENT 581
#define BLOCK_OPEN 582
#define BLOCK_CLOSE 583
#define LIST_OPEN 584
#define LIST_SEPARATOR 585
#define LIST_CLOSE 586




/* Copy the first part of user declarations.  */


/*
 * UUID: db754b9f-f2fd-11dc-b899-00502c05c241
 * Author: Brian M. Ames, bames@apk.net
 * Copyright: Copyright (C) 2008 by Brian M. Ames
 */

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
#define YYLAST   846

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  332
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  224
/* YYNRULES -- Number of rules.  */
#define YYNRULES  458
/* YYNRULES -- Number of states.  */
#define YYNSTATES  526

/* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   586

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
     325,   326,   327,   328,   329,   330,   331
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
     164,   166,   168,   170,   171,   173,   175,   179,   181,   183,
     185,   187,   189,   191,   192,   194,   196,   199,   201,   203,
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
     485,   487,   489,   491,   495,   497,   503,   505,   509,   511,
     515,   517,   521,   523,   527,   529,   533,   535,   539,   543,
     545,   549,   553,   557,   561,   563,   567,   571,   573,   577,
     581,   583,   587,   591,   595,   598,   601,   604,   607,   610,
     612,   614,   618,   620,   622,   624,   626,   628,   630,   632,
     634,   636,   638,   640,   642,   644,   646,   648,   650,   652,
     654,   656,   658,   660,   662,   664,   666,   668,   670,   672,
     674,   676,   678,   680,   682,   684,   686,   688,   690,   692,
     694,   696,   698,   700,   702,   704,   706,   708,   710,   712,
     714,   716,   718,   720,   722,   724,   726,   728,   730,   732,
     734,   736,   738,   740,   742,   744,   746,   748,   750,   752,
     754,   756,   758,   760,   762,   764,   766,   768,   770,   772,
     774,   776,   778,   780,   782,   784,   786,   788,   790,   792,
     794,   796,   798,   800,   802,   804,   806,   808,   810,   812,
     814,   816,   818,   820,   822,   824,   826,   828,   830,   832,
     834,   836,   838,   840,   842,   844,   846,   848,   850,   852,
     854,   856,   858,   860,   862,   864,   866,   868,   870,   872,
     874,   876,   878,   880,   882,   884,   886,   888,   890,   892,
     894,   896,   898,   900,   902,   904,   906,   908,   910,   912,
     914,   916,   918,   920,   922,   924,   926,   928,   930,   932,
     934,   936,   938,   940,   942,   944,   946,   948,   950,   952,
     954,   956,   958,   960,   962,   964,   966,   968,   970,   972,
     974,   976,   978,   980,   982,   984,   986,   988,   990,   992,
     994,   996,   998,  1000,  1002,  1004,  1006,  1008,  1010
};

/* YYRHS -- A `-1'-separated list of the rules' RHS.  */
static const yytype_int16 yyrhs[] =
{
     333,     0,    -1,    -1,   334,   335,    -1,    -1,   336,    -1,
     337,    -1,   336,   337,    -1,    -1,   338,   362,   464,    -1,
     339,    -1,   355,    -1,   345,   346,   350,   354,    -1,   205,
     388,    -1,   205,   384,    -1,   206,    -1,   207,    -1,   295,
      -1,   295,    -1,   340,   464,   335,    -1,   341,   343,   464,
     335,    -1,   342,   344,   464,   335,    -1,   341,   471,   464,
     335,    -1,   342,   472,   464,   335,    -1,    -1,   347,    -1,
     349,    -1,   347,   349,    -1,   201,   388,    -1,   348,   464,
     335,    -1,    -1,   352,    -1,   202,    -1,   351,   464,   335,
      -1,   203,    -1,   353,   464,    -1,   208,   363,   464,    -1,
     200,   469,   360,   464,    -1,   200,   468,   359,   360,   464,
      -1,   211,   470,   464,    -1,    -1,   209,   356,   363,   464,
      -1,    -1,   204,   357,   362,   464,    -1,    -1,   210,   358,
     362,   464,    -1,   199,   464,    -1,    43,   366,    44,    -1,
      -1,   361,   362,    -1,    -1,   363,    -1,   364,    -1,   363,
     364,    -1,   365,    -1,   368,    -1,   374,    -1,   383,    -1,
     384,    -1,   387,    -1,    95,    -1,   293,    -1,   294,    -1,
      -1,   367,    -1,   368,    -1,   367,    47,   368,    -1,   295,
      -1,   296,    -1,   299,    -1,   373,    -1,   295,    -1,   296,
      -1,    -1,   371,    -1,   372,    -1,   371,   372,    -1,   299,
      -1,   403,    -1,   404,    -1,   405,    -1,   406,    -1,   407,
      -1,   408,    -1,   409,    -1,   410,    -1,   411,    -1,   412,
      -1,   413,    -1,   414,    -1,   416,    -1,   417,    -1,   418,
      -1,   419,    -1,   420,    -1,   421,    -1,   422,    -1,   423,
      -1,   424,    -1,   425,    -1,   426,    -1,   427,    -1,   428,
      -1,   429,    -1,   430,    -1,   431,    -1,   432,    -1,   433,
      -1,   435,    -1,   436,    -1,   437,    -1,   438,    -1,   439,
      -1,   440,    -1,   441,    -1,   442,    -1,   443,    -1,   445,
      -1,   446,    -1,   447,    -1,   448,    -1,   449,    -1,   450,
      -1,   451,    -1,   452,    -1,   453,    -1,   454,    -1,   455,
      -1,   456,    -1,   457,    -1,   458,    -1,   459,    -1,   460,
      -1,   461,    -1,   462,    -1,   463,    -1,   300,    -1,   375,
      -1,   385,    -1,   305,    -1,   376,    -1,   377,    -1,   378,
      -1,   306,    -1,   307,    -1,   308,    -1,   305,    -1,   380,
      -1,   381,    -1,   382,    -1,   306,    -1,   307,    -1,   308,
      -1,   301,    -1,   302,    -1,   303,    -1,   304,    -1,   309,
      -1,   157,    -1,   186,    -1,   317,    -1,   474,    -1,   465,
      -1,   466,    -1,   479,    -1,   483,    -1,   489,    -1,   490,
      -1,   491,    -1,   494,    -1,   499,    -1,   501,    -1,   508,
      -1,   511,    -1,   515,    -1,   518,    -1,   519,    -1,   526,
      -1,   529,    -1,   536,    -1,   539,    -1,   541,    -1,   540,
      -1,   545,    -1,   547,    -1,   546,    -1,   553,    -1,   477,
      -1,   467,    -1,   482,    -1,   486,    -1,   488,    -1,   493,
      -1,   497,    -1,   498,    -1,   504,    -1,   505,    -1,   506,
      -1,   507,    -1,   510,    -1,   514,    -1,   517,    -1,   521,
      -1,   523,    -1,   524,    -1,   527,    -1,   531,    -1,   533,
      -1,   535,    -1,   544,    -1,   550,    -1,   551,    -1,   509,
      -1,   434,    -1,   415,    -1,   484,    -1,   548,    -1,   554,
      -1,   475,    -1,   542,    -1,   444,    -1,   389,    -1,   390,
      -1,   389,   500,   390,    -1,   391,    -1,   391,   538,   389,
     516,   390,    -1,   392,    -1,   391,   552,   392,    -1,   393,
      -1,   392,   487,   393,    -1,   394,    -1,   393,   549,   394,
      -1,   395,    -1,   394,   543,   395,    -1,   396,    -1,   395,
     485,   396,    -1,   397,    -1,   396,   528,   397,    -1,   396,
     478,   397,    -1,   398,    -1,   397,   520,   398,    -1,   397,
     530,   398,    -1,   397,   525,   398,    -1,   397,   532,   398,
      -1,   399,    -1,   398,   522,   399,    -1,   398,   534,   399,
      -1,   400,    -1,   399,   495,   400,    -1,   399,   502,   400,
      -1,   401,    -1,   400,   492,   401,    -1,   400,   513,   401,
      -1,   400,   481,   401,    -1,   370,   402,    -1,   496,   401,
      -1,   503,   401,    -1,   476,   401,    -1,   555,   401,    -1,
     386,    -1,   379,    -1,    43,   389,    44,    -1,   369,    -1,
     135,    -1,   136,    -1,   137,    -1,   138,    -1,   139,    -1,
     140,    -1,   141,    -1,   142,    -1,   143,    -1,   144,    -1,
     145,    -1,   146,    -1,   148,    -1,   149,    -1,   150,    -1,
     151,    -1,   152,    -1,   153,    -1,   154,    -1,   155,    -1,
     156,    -1,   158,    -1,   159,    -1,   160,    -1,   161,    -1,
     162,    -1,   163,    -1,   164,    -1,   165,    -1,   166,    -1,
     167,    -1,   168,    -1,   169,    -1,   170,    -1,   171,    -1,
     172,    -1,   173,    -1,   174,    -1,   175,    -1,   176,    -1,
     177,    -1,   178,    -1,   179,    -1,   180,    -1,   181,    -1,
     182,    -1,   183,    -1,   184,    -1,   185,    -1,   187,    -1,
     188,    -1,   189,    -1,   190,    -1,   191,    -1,   192,    -1,
     193,    -1,   194,    -1,   195,    -1,   196,    -1,   197,    -1,
     198,    -1,    13,    -1,    38,    -1,   134,    -1,   214,    -1,
     215,    -1,   217,    -1,   297,    -1,   279,    -1,   280,    -1,
     281,    -1,   282,    -1,   283,    -1,   284,    -1,   285,    -1,
     286,    -1,   287,    -1,   288,    -1,   289,    -1,   298,    -1,
     473,    -1,   295,    -1,   473,    -1,   473,    -1,   473,    -1,
     268,    -1,   269,    -1,   270,    -1,   271,    -1,   272,    -1,
     273,    -1,   274,    -1,   275,    -1,   276,    -1,   277,    -1,
     278,    -1,    36,    -1,   262,    -1,    36,    -1,   262,    -1,
     213,    -1,   263,    -1,   213,    -1,   263,    -1,   480,    -1,
      40,    -1,    40,    -1,   218,    -1,    41,    -1,   259,    -1,
      41,    -1,   259,    -1,   221,    -1,   257,    -1,   221,    -1,
     257,    -1,   222,    -1,   258,    -1,    43,    -1,    44,    -1,
      45,    -1,    45,    -1,   225,    -1,    46,    -1,    46,    -1,
      46,    -1,   227,    -1,   228,    -1,    47,    -1,    47,    -1,
      48,    -1,    48,    -1,    48,    -1,   230,    -1,   231,    -1,
     232,    -1,   233,    -1,    49,    -1,   292,    -1,   235,    -1,
     512,    -1,    50,    -1,    50,    -1,   237,    -1,    61,    -1,
      61,    -1,   239,    -1,    62,    -1,    63,    -1,    63,    -1,
     241,    -1,   241,    -1,   242,    -1,   243,    -1,   243,    -1,
      64,    -1,   245,    -1,   245,    -1,    65,    -1,    65,    -1,
     247,    -1,   247,    -1,   248,    -1,   248,    -1,   249,    -1,
     537,    -1,   250,    -1,   250,    -1,    94,    -1,   132,    -1,
      96,    -1,   133,    -1,    97,    -1,   266,    -1,    97,    -1,
     266,    -1,   252,    -1,   267,    -1,   125,    -1,   130,    -1,
     127,    -1,   131,    -1,   126,    -1,   260,    -1,   126,    -1,
     260,    -1,   254,    -1,   265,    -1,   255,    -1,   264,    -1,
     255,    -1,   264,    -1,   128,    -1,   261,    -1,   128,    -1,
     261,    -1
};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const yytype_uint16 yyrline[] =
{
       0,   400,   400,   400,   403,   404,   407,   408,   411,   411,
     412,   413,   416,   419,   420,   423,   426,   429,   432,   435,
     436,   437,   438,   439,   442,   443,   446,   447,   450,   453,
     456,   457,   460,   463,   466,   469,   472,   473,   474,   475,
     476,   476,   477,   477,   478,   478,   479,   482,   485,   485,
     488,   489,   492,   493,   496,   497,   498,   499,   500,   501,
     502,   505,   506,   509,   510,   513,   514,   517,   518,   519,
     520,   523,   524,   527,   528,   531,   532,   535,   538,   539,
     540,   541,   542,   543,   544,   545,   546,   547,   548,   549,
     550,   551,   552,   553,   554,   555,   556,   557,   558,   559,
     560,   561,   562,   563,   564,   565,   566,   567,   568,   569,
     570,   571,   572,   573,   574,   575,   576,   577,   578,   579,
     580,   581,   582,   583,   584,   585,   586,   587,   588,   589,
     590,   591,   592,   593,   594,   595,   598,   599,   600,   603,
     604,   605,   606,   609,   612,   615,   618,   619,   620,   621,
     624,   627,   630,   633,   634,   637,   638,   641,   644,   645,
     646,   649,   650,   651,   652,   653,   654,   655,   656,   657,
     658,   659,   660,   661,   662,   663,   664,   665,   666,   667,
     668,   669,   670,   671,   672,   673,   674,   675,   676,   677,
     678,   679,   680,   681,   682,   683,   684,   685,   686,   687,
     688,   689,   690,   691,   692,   693,   694,   695,   696,   697,
     698,   699,   700,   701,   702,   703,   704,   705,   706,   707,
     708,   711,   714,   715,   718,   719,   722,   723,   726,   727,
     730,   731,   734,   735,   738,   739,   742,   743,   744,   747,
     748,   749,   750,   751,   754,   755,   756,   759,   760,   761,
     764,   765,   766,   767,   770,   771,   772,   773,   774,   777,
     778,   779,   780,   783,   786,   789,   792,   795,   798,   801,
     804,   807,   810,   813,   816,   819,   822,   825,   828,   831,
     834,   837,   840,   843,   846,   849,   852,   855,   858,   861,
     864,   867,   870,   873,   876,   879,   882,   885,   888,   891,
     894,   897,   900,   903,   906,   909,   912,   915,   918,   921,
     924,   927,   930,   933,   936,   939,   942,   945,   948,   951,
     954,   957,   960,   963,   966,   969,   970,   973,   976,   977,
     980,   981,   982,   983,   984,   985,   986,   987,   988,   989,
     990,   991,   994,   995,   998,   999,  1002,  1005,  1008,  1009,
    1010,  1011,  1012,  1013,  1014,  1015,  1016,  1017,  1018,  1021,
    1024,  1027,  1028,  1031,  1032,  1035,  1036,  1039,  1042,  1045,
    1048,  1051,  1054,  1057,  1058,  1061,  1062,  1065,  1066,  1069,
    1070,  1073,  1076,  1079,  1082,  1085,  1088,  1091,  1094,  1097,
    1100,  1103,  1106,  1109,  1112,  1115,  1118,  1121,  1124,  1127,
    1130,  1133,  1136,  1139,  1142,  1145,  1148,  1151,  1154,  1157,
    1160,  1163,  1166,  1169,  1172,  1175,  1178,  1181,  1184,  1187,
    1190,  1193,  1196,  1199,  1202,  1205,  1208,  1211,  1214,  1216,
    1219,  1222,  1223,  1226,  1227,  1230,  1233,  1236,  1237,  1240,
    1241,  1244,  1245,  1248,  1249,  1252,  1255,  1258,  1259,  1262,
    1263,  1266,  1267,  1270,  1271,  1274,  1277,  1280,  1281
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
  "KWD_ASM", "KWD_AUTO", "KWD_BOOL", "KWD_BREAK", "KWD_CASE", "KWD_CATCH",
  "KWD_CHAR", "KWD_CLASS", "KWD_CONST", "KWD_CONST_CAST", "KWD_CONTINUE",
  "KWD_DEFAULT", "KWD_DEFINED", "KWD_DELETE", "KWD_DO", "KWD_DOUBLE",
  "KWD_DYNAMIC_CAST", "KWD_ELSE", "KWD_ENUM", "KWD_EXPLICIT", "KWD_EXPORT",
  "KWD_EXTERN", "KWD_FALSE", "KWD_FLOAT", "KWD_FOR", "KWD_FRIEND",
  "KWD_GOTO", "KWD_IF", "KWD_INLINE", "KWD_INT", "KWD_LONG", "KWD_MUTABLE",
  "KWD_NAMESPACE", "KWD_NEW", "KWD_OPERATOR", "KWD_PRIVATE",
  "KWD_PROTECTED", "KWD_PUBLIC", "KWD_REGISTER", "KWD_REINTERPRET_CAST",
  "KWD_RETURN", "KWD_SHORT", "KWD_SIGNED", "KWD_SIZEOF", "KWD_STATIC",
  "KWD_STATIC_CAST", "KWD_STRUCT", "KWD_SWITCH", "KWD_TEMPLATE",
  "KWD_THIS", "KWD_THROW", "KWD_TRUE", "KWD_TRY", "KWD_TYPEDEF",
  "KWD_TYPENAME", "KWD_TYPEID", "KWD_UNION", "KWD_UNSIGNED", "KWD_USING",
  "KWD_VIRTUAL", "KWD_VOID", "KWD_VOLATILE", "KWD_WCHAR_T", "KWD_WHILE",
  "PPD_NULL", "PPD_DEFINE", "PPD_ELIF", "PPD_ELSE", "PPD_ENDIF",
  "PPD_ERROR", "PPD_IF", "PPD_IFDEF", "PPD_IFNDEF", "PPD_INCLUDE",
  "PPD_LINE", "PPD_PRAGMA", "PPD_UNDEF", "OP_LOGICAL_NOT", "OP_NE",
  "OP_STRINGIZE", "OP_TOKEN_SPLICE", "OP_MODULO", "ALT_OP_TOKEN_SPLICE",
  "OP_ASSIGN_MODULO", "OP_BIT_AND", "OP_ADDRESS", "OP_LOGICAL_AND",
  "OP_ASSIGN_BIT_AND", "OP_DEREFERENCE", "OP_MULTIPLY",
  "OP_ASSIGN_MULTIPLY", "OP_PLUS", "OP_INCREMENT", "OP_ASSIGN_PLUS",
  "OP_MINUS", "OP_DECREMENT", "OP_ASSIGN_MINUS", "OP_POINTER_MEMBER",
  "OP_POINTER_POINTER_TO_MEMBER", "OP_OBJECT_MEMBER",
  "OP_OBJECT_POINTER_TO_MEMBER", "OP_DIVIDE", "OP_ASSIGN_DIVIDE",
  "OP_ELSE", "OP_SCOPE_REF", "OP_LT", "OP_SHIFT_LEFT",
  "OP_ASSIGN_SHIFT_LEFT", "OP_LE", "OP_ASSIGN", "OP_EQ", "OP_GT", "OP_GE",
  "OP_SHIFT_RIGHT", "OP_ASSIGN_SHIFT_RIGHT", "OP_CONDITIONAL",
  "OP_BIT_PLUS", "OP_ASSIGN_BIT_PLUS", "OP_BIT_OR", "OP_ASSIGN_BIT_OR",
  "OP_LOGICAL_OR", "OP_BIT_NOT", "OP_ALT_LOGICAL_AND",
  "OP_ALT_ASSIGN_BIT_AND", "OP_ALT_BIT_AND", "OP_ALT_BIT_OR",
  "OP_ALT_BIT_NOT", "OP_ALT_LOGICAL_NOT", "OP_ALT_NE", "OP_ALT_LOGICAL_OR",
  "OP_ALT_ASSIGN_BIT_OR", "OP_ALT_BIT_PLUS", "OP_ALT_ASSIGN_BIT_PLUS",
  "INV_ALT_LOGICAL_AND", "INV_ALT_ASSIGN_BIT_AND", "INV_ALT_BIT_AND",
  "INV_ALT_BIT_OR", "INV_ALT_BIT_NOT", "INV_ALT_LOGICAL_NOT", "INV_ALT_NE",
  "INV_ALT_LOGICAL_OR", "INV_ALT_ASSIGN_BIT_OR", "INV_ALT_BIT_PLUS",
  "INV_ALT_ASSIGN_BIT_PLUS", "INV_MFI_LOGICAL_AND",
  "INV_MFI_ASSIGN_BIT_AND", "INV_MFI_BIT_AND", "INV_MFI_BIT_OR",
  "INV_MFI_BIT_NOT", "INV_MFI_LOGICAL_NOT", "INV_MFI_NE",
  "INV_MFI_LOGICAL_OR", "INV_MFI_ASSIGN_BIT_OR", "INV_MFI_BIT_PLUS",
  "INV_MFI_ASSIGN_BIT_PLUS", "DECL_REFERENCE", "DECL_POINTER",
  "DECL_VAR_ARGS", "SYSTEM_HEADER_STRING", "HEADER_STRING", "IDENTIFIER",
  "NON_REPLACEABLE_IDENTIFIER", "MACRO_FUNCTION_IDENTIFIER",
  "MACRO_OBJECT_IDENTIFIER", "REPLACED_IDENTIFIER", "PP_NUMBER",
  "CHARACTER_LITERAL", "L_CHARACTER_LITERAL", "STRING_LITERAL",
  "L_STRING_LITERAL", "INTEGER_LITERAL", "OCTAL_LITERAL",
  "DECIMAL_LITERAL", "HEXADECIMAL_LITERAL", "FLOATING_LITERAL",
  "UNIVERSAL_CHARACTER_NAME", "USE_ON_CODE", "PUNC_INITIALIZE",
  "PUNC_SYNONYM", "DONT_CARE", "RESERVED_WORD", "ACCESS_SPECIFIER",
  "BOOLEAN_LITERAL", "CV_QUALIFIER", "INTRINSIC_TYPE",
  "FUNCTION_SPECIFIER", "STORAGE_CLASS_SPECIFIER", "USER_TOKEN", "SYMBOL",
  "COMMENT", "BLOCK_COMMENT", "END_OF_STATEMENT", "BLOCK_OPEN",
  "BLOCK_CLOSE", "LIST_OPEN", "LIST_SEPARATOR", "LIST_CLOSE", "$accept",
  "preprocessing_file", "@1", "group_part_seq_opt", "group_part_seq",
  "group_part", "@2", "if_section", "if_open", "ifdef_open", "ifndef_open",
  "ifdef_identifier", "ifndef_identifier", "if_group",
  "elif_group_seq_opt", "elif_group_seq", "elif_group_open", "elif_group",
  "else_group_opt", "else_open", "else_group", "endif_open", "endif_line",
  "control_line", "@3", "@4", "@5", "mf_args", "replacement_list", "@6",
  "preprocessing_token_seq_opt", "preprocessing_token_seq",
  "preprocessing_token", "header_name", "clean_identifier_list_opt",
  "clean_identifier_list", "identifier", "pp_identifier",
  "pp_replaced_identifier_seq_opt", "pp_replaced_identifier_seq",
  "pp_replaced_identifier", "key_word", "pp_number", "integer_literal",
  "octal_literal", "decimal_literal", "hexadecimal_literal",
  "pp_integer_literal", "pp_octal_literal", "pp_decimal_literal",
  "pp_hexadecimal_literal", "character_literal", "string_literal",
  "floating_literal", "pp_boolean_literal", "preprocessing_op_or_punc",
  "pp_constant_expression", "pp_expression", "pp_conditional_expression",
  "pp_logical_or_expression", "pp_logical_and_expression",
  "pp_inclusive_or_expression", "pp_exclusive_or_expression",
  "pp_and_expression", "pp_equality_expression",
  "pp_relational_expression", "pp_shift_expression",
  "pp_additive_expression", "pp_multiplicative_expression",
  "pp_unary_expression", "pp_primary_expression", "kwd_asm", "kwd_auto",
  "kwd_bool", "kwd_break", "kwd_case", "kwd_catch", "kwd_char",
  "kwd_class", "kwd_const", "kwd_const_cast", "kwd_continue",
  "kwd_default", "kwd_delete", "kwd_do", "kwd_double", "kwd_dynamic_cast",
  "kwd_else", "kwd_enum", "kwd_explicit", "kwd_export", "kwd_extern",
  "kwd_float", "kwd_for", "kwd_friend", "kwd_goto", "kwd_if", "kwd_inline",
  "kwd_int", "kwd_long", "kwd_mutable", "kwd_namespace", "kwd_new",
  "kwd_operator", "kwd_private", "kwd_protected", "kwd_public",
  "kwd_register", "kwd_reinterpret_cast", "kwd_return", "kwd_short",
  "kwd_signed", "kwd_sizeof", "kwd_static", "kwd_static_cast",
  "kwd_struct", "kwd_switch", "kwd_template", "kwd_this", "kwd_throw",
  "kwd_try", "kwd_typedef", "kwd_typename", "kwd_typeid", "kwd_union",
  "kwd_unsigned", "kwd_using", "kwd_virtual", "kwd_void", "kwd_volatile",
  "kwd_wchar_t", "kwd_while", "new_line", "bcs_hash", "op_stringize",
  "token_splice", "mf_identifier", "mo_identifier", "mu_identifier",
  "invalid_ifdef_identifier", "invalid_ifndef_identifier",
  "invalid_macro_identifier", "bcs_exclamation", "alt_truth_not",
  "pp_truth_not", "ne", "pp_ne", "bcs_percent", "modulo", "pp_modulo",
  "assign_modulo", "bcs_ampersand", "alt_bit_and", "pp_bit_and",
  "truth_and", "pp_truth_and", "assign_bit_and", "bcs_open_parenthesis",
  "bcs_close_parenthesis", "bcs_asterisk", "pp_multiply",
  "assign_multiply", "bcs_plus", "pp_plus", "pp_unary_plus", "increment",
  "assign_plus", "bcs_comma", "pp_comma_op", "bcs_minus", "pp_minus",
  "pp_unary_minus", "decrement", "assign_minus", "pointer_member",
  "pointer_ptm", "bcs_period", "var_args", "object_ptm", "bcs_slash",
  "divide", "pp_divide", "assign_divide", "bcs_colon",
  "pp_conditional_separator", "scope_ref", "bcs_semicolon",
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
     585,   586
};
# endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_uint16 yyr1[] =
{
       0,   332,   334,   333,   335,   335,   336,   336,   338,   337,
     337,   337,   339,   340,   340,   341,   342,   343,   344,   345,
     345,   345,   345,   345,   346,   346,   347,   347,   348,   349,
     350,   350,   351,   352,   353,   354,   355,   355,   355,   355,
     356,   355,   357,   355,   358,   355,   355,   359,   361,   360,
     362,   362,   363,   363,   364,   364,   364,   364,   364,   364,
     364,   365,   365,   366,   366,   367,   367,   368,   368,   368,
     368,   369,   369,   370,   370,   371,   371,   372,   373,   373,
     373,   373,   373,   373,   373,   373,   373,   373,   373,   373,
     373,   373,   373,   373,   373,   373,   373,   373,   373,   373,
     373,   373,   373,   373,   373,   373,   373,   373,   373,   373,
     373,   373,   373,   373,   373,   373,   373,   373,   373,   373,
     373,   373,   373,   373,   373,   373,   373,   373,   373,   373,
     373,   373,   373,   373,   373,   373,   374,   374,   374,   375,
     375,   375,   375,   376,   377,   378,   379,   379,   379,   379,
     380,   381,   382,   383,   383,   384,   384,   385,   386,   386,
     386,   387,   387,   387,   387,   387,   387,   387,   387,   387,
     387,   387,   387,   387,   387,   387,   387,   387,   387,   387,
     387,   387,   387,   387,   387,   387,   387,   387,   387,   387,
     387,   387,   387,   387,   387,   387,   387,   387,   387,   387,
     387,   387,   387,   387,   387,   387,   387,   387,   387,   387,
     387,   387,   387,   387,   387,   387,   387,   387,   387,   387,
     387,   388,   389,   389,   390,   390,   391,   391,   392,   392,
     393,   393,   394,   394,   395,   395,   396,   396,   396,   397,
     397,   397,   397,   397,   398,   398,   398,   399,   399,   399,
     400,   400,   400,   400,   401,   401,   401,   401,   401,   402,
     402,   402,   402,   403,   404,   405,   406,   407,   408,   409,
     410,   411,   412,   413,   414,   415,   416,   417,   418,   419,
     420,   421,   422,   423,   424,   425,   426,   427,   428,   429,
     430,   431,   432,   433,   434,   435,   436,   437,   438,   439,
     440,   441,   442,   443,   444,   445,   446,   447,   448,   449,
     450,   451,   452,   453,   454,   455,   456,   457,   458,   459,
     460,   461,   462,   463,   464,   465,   465,   466,   467,   467,
     468,   468,   468,   468,   468,   468,   468,   468,   468,   468,
     468,   468,   469,   469,   470,   470,   471,   472,   473,   473,
     473,   473,   473,   473,   473,   473,   473,   473,   473,   474,
     475,   476,   476,   477,   477,   478,   478,   479,   480,   481,
     482,   483,   484,   485,   485,   486,   486,   487,   487,   488,
     488,   489,   490,   491,   492,   493,   494,   495,   496,   497,
     498,   499,   500,   501,   502,   503,   504,   505,   506,   507,
     508,   509,   510,   511,   512,   513,   514,   515,   516,   517,
     518,   519,   520,   521,   522,   523,   524,   525,   526,   527,
     528,   529,   530,   531,   532,   533,   534,   535,   536,   537,
     538,   539,   539,   540,   540,   541,   542,   543,   543,   544,
     544,   545,   545,   546,   546,   547,   548,   549,   549,   550,
     550,   551,   551,   552,   552,   553,   554,   555,   555
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
       1,     1,     1,     0,     1,     1,     3,     1,     1,     1,
       1,     1,     1,     0,     1,     1,     2,     1,     1,     1,
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
       1,     1,     1,     3,     1,     5,     1,     3,     1,     3,
       1,     3,     1,     3,     1,     3,     1,     3,     3,     1,
       3,     3,     3,     3,     1,     3,     3,     1,     3,     3,
       1,     3,     3,     3,     2,     2,     2,     2,     2,     1,
       1,     3,     1,     1,     1,     1,     1,     1,     1,     1,
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
       1,     1,     1,     1,     1,     1,     1,     1,     1
};

/* YYDEFACT[STATE-NAME] -- Default rule to reduce with in state
   STATE-NUM when YYTABLE doesn't specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint16 yydefact[] =
{
       2,     0,     8,     1,     0,     0,    42,    73,    15,    16,
       0,    40,    44,     0,     3,     8,     6,    50,    10,     0,
       0,     0,    24,    11,   324,    46,   348,   349,   350,   351,
     352,   353,   354,   355,   356,   357,   358,   331,   332,   333,
     334,   335,   336,   337,   338,   339,   340,   341,   330,   342,
       0,    48,   343,    50,   361,   388,   395,   457,   458,   362,
      77,   155,   156,     0,    74,    75,    14,    13,   221,   222,
     224,   226,   228,   230,   232,   234,   236,   239,   244,   247,
     250,    73,    73,    73,    73,   359,   325,   368,   371,   381,
     382,   383,   386,   391,   393,   400,   404,   407,   410,   411,
     418,   421,   431,    60,   433,   435,   441,   445,   443,   455,
     442,   444,   432,   434,   326,   263,   264,   265,   266,   267,
     268,   269,   270,   271,   272,   273,   274,   275,   276,   277,
     278,   279,   280,   281,   282,   283,   284,   285,   286,   287,
     288,   289,   290,   291,   292,   293,   294,   295,   296,   297,
     298,   299,   300,   301,   302,   303,   304,   305,   306,   307,
     308,   309,   310,   311,   312,   313,   314,   315,   316,   317,
     318,   319,   320,   321,   322,   323,   363,   327,   328,   329,
     370,   375,   379,   385,   389,   390,   396,   397,   398,   399,
     402,   406,   409,   413,   415,   416,   419,   423,   425,   427,
     429,   439,   449,   451,   376,   380,   372,   446,   456,   360,
     364,   452,   450,   436,   440,   401,    61,    62,    67,    68,
      69,   136,   153,   154,   139,   143,   144,   145,   157,     0,
      52,    54,    55,    70,    56,   137,   140,   141,   142,    57,
      58,   138,    59,    78,    79,    80,    81,    82,    83,    84,
      85,    86,    87,    88,    89,   214,    90,    91,    92,    93,
      94,    95,    96,    97,    98,    99,   100,   101,   102,   103,
     104,   105,   106,   107,   213,   108,   109,   110,   111,   112,
     113,   114,   115,   116,   220,   117,   118,   119,   120,   121,
     122,   123,   124,   125,   126,   127,   128,   129,   130,   131,
     132,   133,   134,   135,   162,   163,   188,   161,   218,   187,
     164,   367,   189,   165,   215,   190,   191,   166,   167,   168,
     192,   169,   193,   194,   170,   171,   195,   196,   197,   198,
     172,   212,   199,   173,   403,   200,   174,   201,   175,   176,
     202,   203,   204,   177,   205,   178,   206,   207,   208,   179,
     428,   180,   182,   181,   219,   209,   183,   185,   184,   216,
     210,   211,   186,   217,     0,    50,   344,     0,   345,     7,
       0,    51,     8,    17,     0,     0,   346,    18,     0,     0,
     347,    73,    30,    25,     0,    26,    63,    48,     0,    50,
       0,    73,   158,   159,    71,    72,   146,   150,   151,   152,
     160,   262,   260,   147,   148,   149,   259,   254,    76,   392,
      73,   430,   453,   454,    73,    73,   377,   378,    73,   447,
     448,    73,   437,   438,    73,   373,   374,    73,   365,   420,
     366,    73,    73,   412,   422,   417,   424,    73,    73,    73,
      73,   414,   426,    73,    73,   387,   394,    73,    73,   369,
     384,   405,    73,    73,    73,   257,   255,   256,   258,    53,
      36,     0,     0,    39,     9,    19,     8,     8,     8,     8,
      28,    32,     0,     0,    31,    27,     8,     0,    64,    65,
       0,    37,    49,    43,     0,   223,     0,   227,   229,   231,
     233,   235,   238,   237,   240,   242,   241,   243,   245,   246,
     248,   249,   253,   251,   252,    41,    45,    20,    22,    21,
      23,    34,     0,    12,     8,    29,    47,     0,    38,   261,
     408,    73,    35,    33,    66,   225
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
      -1,     1,     2,    14,    15,    16,    17,    18,    19,    20,
      21,   374,   378,    22,   382,   383,   384,   385,   472,   473,
     474,   512,   513,    23,   364,    53,   365,   387,   388,   389,
     370,   371,   230,   231,   477,   478,   232,   401,    63,    64,
      65,   233,   234,   235,   236,   237,   238,   402,   403,   404,
     405,   239,   240,   241,   406,   242,    67,    68,    69,    70,
      71,    72,    73,    74,    75,    76,    77,    78,    79,    80,
     407,   243,   244,   245,   246,   247,   248,   249,   250,   251,
     252,   253,   254,   255,   256,   257,   258,   259,   260,   261,
     262,   263,   264,   265,   266,   267,   268,   269,   270,   271,
     272,   273,   274,   275,   276,   277,   278,   279,   280,   281,
     282,   283,   284,   285,   286,   287,   288,   289,   290,   291,
     292,   293,   294,   295,   296,   297,   298,   299,   300,   301,
     302,   303,    25,   304,   305,   306,    50,    51,   367,   375,
     379,    52,   307,   308,    81,   309,   431,   310,   311,   452,
     312,   313,   314,   427,   315,   418,   316,   317,   318,   319,
     453,   320,   321,   447,    82,   322,   323,   324,   410,   325,
     448,    83,   326,   327,   328,   329,   330,   331,   332,   333,
     334,   454,   335,   336,   521,   337,   338,   339,   437,   340,
     443,   341,   342,   438,   343,   344,   432,   345,   439,   346,
     440,   347,   444,   348,   349,   350,   414,   351,   352,   353,
     354,   424,   355,   356,   357,   358,   359,   421,   360,   361,
     415,   362,   363,    84
};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -403
static const yytype_int16 yypact[] =
{
    -403,    16,   184,  -403,    15,   478,  -403,   188,  -403,  -403,
     372,  -403,  -403,  -197,  -403,    67,  -403,   372,  -403,    15,
      50,   128,  -146,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
      14,  -403,  -403,   372,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,   157,  -241,  -403,  -403,  -403,    19,  -403,
    -240,  -208,   -58,   -65,   -32,  -193,   -44,  -223,   -13,   -23,
    -403,    69,    69,    69,    69,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,    -2,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,   372,   372,  -403,    15,  -403,  -403,
      15,   372,   373,  -403,    15,    15,  -403,  -403,    15,    15,
    -403,    69,  -133,  -146,    15,  -403,   547,  -403,    15,   372,
      15,    69,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
      69,  -403,  -403,  -403,    69,    69,  -403,  -403,    69,  -403,
    -403,    69,  -403,  -403,    69,  -403,  -403,    69,  -403,  -403,
    -403,    69,    69,  -403,  -403,  -403,  -403,    69,    69,    69,
      69,  -403,  -403,    69,    69,  -403,  -403,    69,    69,  -403,
    -403,  -403,    69,    69,    69,  -403,  -403,  -403,  -403,  -403,
    -403,    -2,    15,  -403,  -403,  -403,   373,   373,   373,   373,
    -403,  -403,  -117,    15,  -403,  -403,   373,    43,    41,  -403,
      15,  -403,  -403,  -403,    -7,  -403,   -35,  -208,   -58,   -65,
     -32,  -193,   -44,   -44,  -223,  -223,  -223,  -223,   -13,   -13,
     -23,   -23,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,    15,  -403,   -97,  -403,  -403,   547,  -403,  -403,
    -403,    69,  -403,  -403,  -403,  -403
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -403,  -403,  -403,  -134,  -403,    74,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -293,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -296,  -403,
     -48,    -3,  -173,  -403,  -403,  -403,  -372,  -403,  -403,  -403,
      32,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,    90,  -403,  -403,  -403,  -282,  -385,  -402,  -403,
    -315,  -317,  -305,  -320,  -309,  -381,  -355,  -390,  -383,   -80,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,   -19,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,    10,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,  -403,
    -403,  -403,  -403,  -403
};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If zero, do what YYDEFACT says.
   If YYTABLE_NINF, syntax error.  */
#define YYTABLE_NINF -6
static const yytype_int16 yytable[] =
{
     372,   455,   456,   457,   458,   390,   484,   229,   485,   425,
     411,    24,   409,   416,   479,   412,     3,   449,   441,   433,
     428,   434,   450,   368,   413,   442,   520,   451,    24,   486,
     376,   380,   422,   445,    85,   446,    86,   519,    87,    88,
     409,    89,    90,    91,    92,    93,    94,    95,    96,   417,
     492,   493,   429,   498,   499,   381,   459,   386,    60,    97,
      98,    99,   100,   101,   500,   501,   409,    -5,   419,   471,
     430,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,   494,   495,   496,   497,   511,   516,   517,   369,
     475,   480,   102,   103,   104,   105,   408,    66,   366,   470,
     487,   488,     4,     5,   490,    54,    -4,     6,     7,     8,
       9,    10,    11,    12,    13,    55,   489,    56,   491,   525,
       0,     0,     0,   106,   107,   108,   109,     0,   110,   111,
     112,   113,   114,   115,   116,   117,   118,   119,   120,   121,
     122,   123,   124,   125,   126,   524,   127,   128,   129,   130,
     131,   132,   133,   134,   135,     0,   136,   137,   138,   139,
     140,   141,   142,   143,   144,   145,   146,   147,   148,   149,
     150,   151,   152,   153,   154,   155,   156,   157,   158,   159,
     160,   161,   162,   163,    -4,   164,   165,   166,   167,   168,
     169,   170,   171,   172,   173,   174,   175,    57,   459,   435,
     391,   423,   420,   436,     0,     0,     0,     0,     0,     0,
     460,   176,   177,   178,     0,   179,   180,     0,     0,   181,
     182,     0,     0,   183,    54,   184,   185,   426,   186,   187,
     188,   189,     0,   190,    55,   191,    56,   192,   465,   193,
     194,   195,     0,   196,     0,   197,   198,   199,   200,     0,
     201,     0,   202,   203,     0,   204,   205,   206,   207,   208,
     209,   210,   211,   212,   213,   214,     4,     5,    -5,    -5,
      -5,     6,     7,     8,     9,    10,    11,    12,    13,     0,
       0,     0,     0,     0,     0,     0,     0,     0,   459,     0,
     215,   216,   217,   218,   219,     0,     0,   220,   221,   222,
     223,    61,    62,   224,   225,   226,   227,   228,     0,     0,
       0,     0,     0,     0,   392,     0,    57,   462,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,     0,
      58,    59,   507,   508,   509,   510,     0,     0,     0,     0,
       0,   482,   515,   393,     0,   373,     0,     0,   463,     0,
       0,   464,     0,     0,     0,   466,   467,     0,     0,   468,
     469,   461,     0,     0,     0,   476,     0,     0,    60,   481,
       0,   483,   502,   503,   504,     0,     0,     0,     0,     0,
     523,     0,     0,     4,     5,     0,     0,     0,     6,     7,
       8,     9,    10,    11,    12,    13,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,     0,    85,     0,
      86,     0,    87,    88,     0,    89,    90,    91,    92,    93,
      94,    95,    96,   377,     0,     0,     0,     0,     0,     0,
       0,     0,     0,    97,    98,    99,   100,   101,     0,     0,
       0,     0,   505,   506,     0,     0,     0,     0,     0,    58,
      59,     0,   394,   395,   514,     0,     0,     0,     0,     0,
       0,   518,   396,   397,   398,   399,   102,   103,   104,   105,
       0,     0,     0,     0,   400,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,    60,     0,     0,
       0,    61,    62,   522,     0,     0,     0,   106,   107,   108,
     109,     0,   110,   111,   112,   113,   114,   115,   116,   117,
     118,   119,   120,   121,   122,   123,   124,   125,   126,     0,
     127,   128,   129,   130,   131,   132,   133,   134,   135,     0,
     136,   137,   138,   139,   140,   141,   142,   143,   144,   145,
     146,   147,   148,   149,   150,   151,   152,   153,   154,   155,
     156,   157,   158,   159,   160,   161,   162,   163,     0,   164,
     165,   166,   167,   168,   169,   170,   171,   172,   173,   174,
     175,     0,     4,     5,    -4,    -4,    -4,     6,     7,     8,
       9,    10,    11,    12,    13,   176,   177,   178,     0,   179,
     180,     0,     0,   181,   182,     0,     0,   183,     0,   184,
     185,     0,   186,   187,   188,   189,     0,   190,     0,   191,
       0,   192,     0,   193,   194,   195,     0,   196,     0,   197,
     198,   199,   200,     0,   201,     0,   202,   203,     0,   204,
     205,   206,   207,   208,   209,   210,   211,   212,   213,   214,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,   215,   216,   217,   218,   219,     0,
       0,   220,   221,   222,   223,    61,    62,   224,   225,   226,
     227,   228,   115,   116,   117,   118,   119,   120,   121,   122,
     123,   124,   125,   126,     0,     0,   128,   129,   130,   131,
     132,   133,   134,   135,     0,   136,   137,   138,   139,   140,
     141,   142,   143,   144,   145,     0,   147,   148,   149,   150,
     151,   152,   153,   154,   155,     0,   157,   158,   159,   160,
     161,   162,   163,     0,   164,   165,   166,   167,   168,   169,
     170,   171,   172,   173,   174,   175,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,    38,    39,
      40,    41,    42,    43,    44,    45,    46,    47,     0,     0,
       0,     0,     0,     0,     0,    48,    49,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,   218,   219,     0,     0,   220
};

static const yytype_int16 yycheck[] =
{
      19,    81,    82,    83,    84,    53,   391,    10,   410,    41,
     250,    13,    47,   221,   386,   255,     0,    40,   241,    63,
     213,    65,    45,    13,   264,   248,    61,    50,    13,   414,
      20,    21,    97,    46,    36,    48,    38,    44,    40,    41,
      47,    43,    44,    45,    46,    47,    48,    49,    50,   257,
     431,   432,   245,   443,   444,   201,   229,    43,   299,    61,
      62,    63,    64,    65,   447,   448,    47,     0,   126,   202,
     263,   268,   269,   270,   271,   272,   273,   274,   275,   276,
     277,   278,   437,   438,   439,   440,   203,    44,    47,    15,
     383,   387,    94,    95,    96,    97,    64,     7,   295,   381,
     415,   418,   199,   200,   424,    36,   203,   204,   205,   206,
     207,   208,   209,   210,   211,    46,   421,    48,   427,   521,
      -1,    -1,    -1,   125,   126,   127,   128,    -1,   130,   131,
     132,   133,   134,   135,   136,   137,   138,   139,   140,   141,
     142,   143,   144,   145,   146,   517,   148,   149,   150,   151,
     152,   153,   154,   155,   156,    -1,   158,   159,   160,   161,
     162,   163,   164,   165,   166,   167,   168,   169,   170,   171,
     172,   173,   174,   175,   176,   177,   178,   179,   180,   181,
     182,   183,   184,   185,     0,   187,   188,   189,   190,   191,
     192,   193,   194,   195,   196,   197,   198,   128,   371,   243,
      43,   266,   260,   247,    -1,    -1,    -1,    -1,    -1,    -1,
     229,   213,   214,   215,    -1,   217,   218,    -1,    -1,   221,
     222,    -1,    -1,   225,    36,   227,   228,   259,   230,   231,
     232,   233,    -1,   235,    46,   237,    48,   239,   372,   241,
     242,   243,    -1,   245,    -1,   247,   248,   249,   250,    -1,
     252,    -1,   254,   255,    -1,   257,   258,   259,   260,   261,
     262,   263,   264,   265,   266,   267,   199,   200,   201,   202,
     203,   204,   205,   206,   207,   208,   209,   210,   211,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   461,    -1,
     292,   293,   294,   295,   296,    -1,    -1,   299,   300,   301,
     302,   303,   304,   305,   306,   307,   308,   309,    -1,    -1,
      -1,    -1,    -1,    -1,   157,    -1,   128,   365,   268,   269,
     270,   271,   272,   273,   274,   275,   276,   277,   278,    -1,
     261,   262,   466,   467,   468,   469,    -1,    -1,    -1,    -1,
      -1,   389,   476,   186,    -1,   295,    -1,    -1,   367,    -1,
      -1,   370,    -1,    -1,    -1,   374,   375,    -1,    -1,   378,
     379,   364,    -1,    -1,    -1,   384,    -1,    -1,   299,   388,
      -1,   390,   452,   453,   454,    -1,    -1,    -1,    -1,    -1,
     514,    -1,    -1,   199,   200,    -1,    -1,    -1,   204,   205,
     206,   207,   208,   209,   210,   211,   268,   269,   270,   271,
     272,   273,   274,   275,   276,   277,   278,    -1,    36,    -1,
      38,    -1,    40,    41,    -1,    43,    44,    45,    46,    47,
      48,    49,    50,   295,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    61,    62,    63,    64,    65,    -1,    -1,
      -1,    -1,   461,   462,    -1,    -1,    -1,    -1,    -1,   261,
     262,    -1,   295,   296,   473,    -1,    -1,    -1,    -1,    -1,
      -1,   480,   305,   306,   307,   308,    94,    95,    96,    97,
      -1,    -1,    -1,    -1,   317,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,   299,    -1,    -1,
      -1,   303,   304,   512,    -1,    -1,    -1,   125,   126,   127,
     128,    -1,   130,   131,   132,   133,   134,   135,   136,   137,
     138,   139,   140,   141,   142,   143,   144,   145,   146,    -1,
     148,   149,   150,   151,   152,   153,   154,   155,   156,    -1,
     158,   159,   160,   161,   162,   163,   164,   165,   166,   167,
     168,   169,   170,   171,   172,   173,   174,   175,   176,   177,
     178,   179,   180,   181,   182,   183,   184,   185,    -1,   187,
     188,   189,   190,   191,   192,   193,   194,   195,   196,   197,
     198,    -1,   199,   200,   201,   202,   203,   204,   205,   206,
     207,   208,   209,   210,   211,   213,   214,   215,    -1,   217,
     218,    -1,    -1,   221,   222,    -1,    -1,   225,    -1,   227,
     228,    -1,   230,   231,   232,   233,    -1,   235,    -1,   237,
      -1,   239,    -1,   241,   242,   243,    -1,   245,    -1,   247,
     248,   249,   250,    -1,   252,    -1,   254,   255,    -1,   257,
     258,   259,   260,   261,   262,   263,   264,   265,   266,   267,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,   292,   293,   294,   295,   296,    -1,
      -1,   299,   300,   301,   302,   303,   304,   305,   306,   307,
     308,   309,   135,   136,   137,   138,   139,   140,   141,   142,
     143,   144,   145,   146,    -1,    -1,   149,   150,   151,   152,
     153,   154,   155,   156,    -1,   158,   159,   160,   161,   162,
     163,   164,   165,   166,   167,    -1,   169,   170,   171,   172,
     173,   174,   175,   176,   177,    -1,   179,   180,   181,   182,
     183,   184,   185,    -1,   187,   188,   189,   190,   191,   192,
     193,   194,   195,   196,   197,   198,   268,   269,   270,   271,
     272,   273,   274,   275,   276,   277,   278,   279,   280,   281,
     282,   283,   284,   285,   286,   287,   288,   289,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,   297,   298,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,   295,   296,    -1,    -1,   299
};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const yytype_uint16 yystos[] =
{
       0,   333,   334,     0,   199,   200,   204,   205,   206,   207,
     208,   209,   210,   211,   335,   336,   337,   338,   339,   340,
     341,   342,   345,   355,    13,   464,   268,   269,   270,   271,
     272,   273,   274,   275,   276,   277,   278,   279,   280,   281,
     282,   283,   284,   285,   286,   287,   288,   289,   297,   298,
     468,   469,   473,   357,    36,    46,    48,   128,   261,   262,
     299,   303,   304,   370,   371,   372,   384,   388,   389,   390,
     391,   392,   393,   394,   395,   396,   397,   398,   399,   400,
     401,   476,   496,   503,   555,    36,    38,    40,    41,    43,
      44,    45,    46,    47,    48,    49,    50,    61,    62,    63,
      64,    65,    94,    95,    96,    97,   125,   126,   127,   128,
     130,   131,   132,   133,   134,   135,   136,   137,   138,   139,
     140,   141,   142,   143,   144,   145,   146,   148,   149,   150,
     151,   152,   153,   154,   155,   156,   158,   159,   160,   161,
     162,   163,   164,   165,   166,   167,   168,   169,   170,   171,
     172,   173,   174,   175,   176,   177,   178,   179,   180,   181,
     182,   183,   184,   185,   187,   188,   189,   190,   191,   192,
     193,   194,   195,   196,   197,   198,   213,   214,   215,   217,
     218,   221,   222,   225,   227,   228,   230,   231,   232,   233,
     235,   237,   239,   241,   242,   243,   245,   247,   248,   249,
     250,   252,   254,   255,   257,   258,   259,   260,   261,   262,
     263,   264,   265,   266,   267,   292,   293,   294,   295,   296,
     299,   300,   301,   302,   305,   306,   307,   308,   309,   363,
     364,   365,   368,   373,   374,   375,   376,   377,   378,   383,
     384,   385,   387,   403,   404,   405,   406,   407,   408,   409,
     410,   411,   412,   413,   414,   415,   416,   417,   418,   419,
     420,   421,   422,   423,   424,   425,   426,   427,   428,   429,
     430,   431,   432,   433,   434,   435,   436,   437,   438,   439,
     440,   441,   442,   443,   444,   445,   446,   447,   448,   449,
     450,   451,   452,   453,   454,   455,   456,   457,   458,   459,
     460,   461,   462,   463,   465,   466,   467,   474,   475,   477,
     479,   480,   482,   483,   484,   486,   488,   489,   490,   491,
     493,   494,   497,   498,   499,   501,   504,   505,   506,   507,
     508,   509,   510,   511,   512,   514,   515,   517,   518,   519,
     521,   523,   524,   526,   527,   529,   531,   533,   535,   536,
     537,   539,   540,   541,   542,   544,   545,   546,   547,   548,
     550,   551,   553,   554,   356,   358,   295,   470,   473,   337,
     362,   363,   464,   295,   343,   471,   473,   295,   344,   472,
     473,   201,   346,   347,   348,   349,    43,   359,   360,   361,
     362,    43,   157,   186,   295,   296,   305,   306,   307,   308,
     317,   369,   379,   380,   381,   382,   386,   402,   372,    47,
     500,   250,   255,   264,   538,   552,   221,   257,   487,   126,
     260,   549,    97,   266,   543,    41,   259,   485,   213,   245,
     263,   478,   528,    63,    65,   243,   247,   520,   525,   530,
     532,   241,   248,   522,   534,    46,    48,   495,   502,    40,
      45,    50,   481,   492,   513,   401,   401,   401,   401,   364,
     464,   363,   362,   464,   464,   335,   464,   464,   464,   464,
     388,   202,   350,   351,   352,   349,   464,   366,   367,   368,
     360,   464,   362,   464,   389,   390,   389,   392,   393,   394,
     395,   396,   397,   397,   398,   398,   398,   398,   399,   399,
     400,   400,   401,   401,   401,   464,   464,   335,   335,   335,
     335,   203,   353,   354,   464,   335,    44,    47,   464,    44,
      61,   516,   464,   335,   368,   390
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

  case 60:

    { handle_token(BCS_PUNCT_BACKSLASH_INDEX); ;}
    break;

  case 61:

    { handle_header_name(SYSTEM_HEADER_STRING_INDEX); ;}
    break;

  case 62:

    { handle_header_name(HEADER_STRING_INDEX); ;}
    break;

  case 67:

    { handle_identifier(IDENTIFIER_INDEX); ;}
    break;

  case 68:

    { handle_nonrepl_identifier(IDENTIFIER_INDEX); ;}
    break;

  case 69:

    { handle_identifier(REPLACED_IDENTIFIER_INDEX); ;}
    break;

  case 136:

    { handle_pp_number(); ;}
    break;

  case 139:

    { handle_string_token(INTEGER_LITERAL_INDEX); ;}
    break;

  case 143:

    { handle_string_token(OCTAL_LITERAL_INDEX); ;}
    break;

  case 144:

    { handle_string_token(DECIMAL_LITERAL_INDEX); ;}
    break;

  case 145:

    { handle_string_token(HEXADECIMAL_LITERAL_INDEX); ;}
    break;

  case 146:

    { (yyval.lval) = (yyvsp[(1) - (1)].lval); ;}
    break;

  case 147:

    { (yyval.lval) = (yyvsp[(1) - (1)].lval); ;}
    break;

  case 148:

    { (yyval.lval) = (yyvsp[(1) - (1)].lval); ;}
    break;

  case 149:

    { (yyval.lval) = (yyvsp[(1) - (1)].lval); ;}
    break;

  case 150:

    { (yyval.lval) = (yyvsp[(1) - (1)].lval); ;}
    break;

  case 151:

    { (yyval.lval) = (yyvsp[(1) - (1)].lval); ;}
    break;

  case 152:

    { (yyval.lval) = (yyvsp[(1) - (1)].lval); ;}
    break;

  case 153:

    { handle_string_token(CHARACTER_LITERAL_INDEX); ;}
    break;

  case 154:

    { handle_string_token(L_CHARACTER_LITERAL_INDEX); ;}
    break;

  case 155:

    { handle_string_token(STRING_LITERAL_INDEX); ;}
    break;

  case 156:

    { handle_string_token(L_STRING_LITERAL_INDEX); ;}
    break;

  case 157:

    { handle_string_token(FLOATING_LITERAL_INDEX); ;}
    break;

  case 158:

    { (yyval.lval) = 0; ;}
    break;

  case 159:

    { (yyval.lval) = 1; ;}
    break;

  case 160:

    { (yyval.lval) = (yyvsp[(1) - (1)].ival); ;}
    break;

  case 221:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 222:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 223:

    {(yyval.lval) = (yyvsp[(3) - (3)].lval);;}
    break;

  case 224:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 225:

    {(yyval.lval) = ((yyvsp[(1) - (5)].lval)) ? (yyvsp[(3) - (5)].lval) : (yyvsp[(5) - (5)].lval);;}
    break;

  case 226:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 227:

    {(yyval.lval) = (yyvsp[(1) - (3)].lval) || (yyvsp[(3) - (3)].lval);;}
    break;

  case 228:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 229:

    {(yyval.lval) = (yyvsp[(1) - (3)].lval) && (yyvsp[(3) - (3)].lval);;}
    break;

  case 230:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 231:

    {(yyval.lval) = (yyvsp[(1) - (3)].lval) | (yyvsp[(3) - (3)].lval);;}
    break;

  case 232:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 233:

    {(yyval.lval) = (yyvsp[(1) - (3)].lval) ^ (yyvsp[(3) - (3)].lval);;}
    break;

  case 234:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 235:

    {(yyval.lval) = (yyvsp[(1) - (3)].lval) & (yyvsp[(3) - (3)].lval);;}
    break;

  case 236:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 237:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) == (yyvsp[(3) - (3)].lval));;}
    break;

  case 238:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) != (yyvsp[(3) - (3)].lval));;}
    break;

  case 239:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 240:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) < (yyvsp[(3) - (3)].lval));;}
    break;

  case 241:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) > (yyvsp[(3) - (3)].lval));;}
    break;

  case 242:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) <= (yyvsp[(3) - (3)].lval));;}
    break;

  case 243:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) >= (yyvsp[(3) - (3)].lval));;}
    break;

  case 244:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 245:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) << (yyvsp[(3) - (3)].lval));;}
    break;

  case 246:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) >> (yyvsp[(3) - (3)].lval));;}
    break;

  case 247:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 248:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) + (yyvsp[(3) - (3)].lval));;}
    break;

  case 249:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) - (yyvsp[(3) - (3)].lval));;}
    break;

  case 250:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 251:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) * (yyvsp[(3) - (3)].lval));;}
    break;

  case 252:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) / (yyvsp[(3) - (3)].lval));;}
    break;

  case 253:

    {(yyval.lval) = ((yyvsp[(1) - (3)].lval) % (yyvsp[(3) - (3)].lval));;}
    break;

  case 254:

    {(yyval.lval) = (yyvsp[(2) - (2)].lval);;}
    break;

  case 255:

    {(yyval.lval) = (yyvsp[(2) - (2)].lval);;}
    break;

  case 256:

    {(yyval.lval) = -(yyvsp[(2) - (2)].lval);;}
    break;

  case 257:

    {(yyval.lval) = !(yyvsp[(2) - (2)].lval);;}
    break;

  case 258:

    {(yyval.lval) = ~(yyvsp[(2) - (2)].lval);;}
    break;

  case 259:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 260:

    {(yyval.lval) = (yyvsp[(1) - (1)].lval);;}
    break;

  case 261:

    {(yyval.lval) = (yyvsp[(2) - (3)].lval);;}
    break;

  case 262:

    {(yyval.lval) = 0;;}
    break;

  case 263:

    { handle_token(KWD_ASM_INDEX); ;}
    break;

  case 264:

    { handle_token(KWD_AUTO_INDEX); ;}
    break;

  case 265:

    { handle_token(KWD_BOOL_INDEX); ;}
    break;

  case 266:

    { handle_token(KWD_BREAK_INDEX); ;}
    break;

  case 267:

    { handle_token(KWD_CASE_INDEX); ;}
    break;

  case 268:

    { handle_token(KWD_CATCH_INDEX); ;}
    break;

  case 269:

    { handle_token(KWD_CHAR_INDEX); ;}
    break;

  case 270:

    { handle_token(KWD_CLASS_INDEX); ;}
    break;

  case 271:

    { handle_token(KWD_CONST_INDEX); ;}
    break;

  case 272:

    { handle_token(KWD_CONST_CAST_INDEX); ;}
    break;

  case 273:

    { handle_token(KWD_CONTINUE_INDEX); ;}
    break;

  case 274:

    { handle_token(KWD_DEFAULT_INDEX); ;}
    break;

  case 275:

    { handle_token(KWD_DELETE_INDEX); ;}
    break;

  case 276:

    { handle_token(KWD_DO_INDEX); ;}
    break;

  case 277:

    { handle_token(KWD_DOUBLE_INDEX); ;}
    break;

  case 278:

    { handle_token(KWD_DYNAMIC_CAST_INDEX); ;}
    break;

  case 279:

    { handle_token(KWD_ELSE_INDEX); ;}
    break;

  case 280:

    { handle_token(KWD_ENUM_INDEX); ;}
    break;

  case 281:

    { handle_token(KWD_EXPLICIT_INDEX); ;}
    break;

  case 282:

    { handle_token(KWD_EXPORT_INDEX); ;}
    break;

  case 283:

    { handle_token(KWD_EXTERN_INDEX); ;}
    break;

  case 284:

    { handle_token(KWD_FLOAT_INDEX); ;}
    break;

  case 285:

    { handle_token(KWD_FOR_INDEX); ;}
    break;

  case 286:

    { handle_token(KWD_FRIEND_INDEX); ;}
    break;

  case 287:

    { handle_token(KWD_GOTO_INDEX); ;}
    break;

  case 288:

    { handle_token(KWD_IF_INDEX); ;}
    break;

  case 289:

    { handle_token(KWD_INLINE_INDEX); ;}
    break;

  case 290:

    { handle_token(KWD_INT_INDEX); ;}
    break;

  case 291:

    { handle_token(KWD_LONG_INDEX); ;}
    break;

  case 292:

    { handle_token(KWD_MUTABLE_INDEX); ;}
    break;

  case 293:

    { handle_token(KWD_NAMESPACE_INDEX); ;}
    break;

  case 294:

    { handle_token(KWD_NEW_INDEX); ;}
    break;

  case 295:

    { handle_token(KWD_OPERATOR_INDEX); ;}
    break;

  case 296:

    { handle_token(KWD_PRIVATE_INDEX); ;}
    break;

  case 297:

    { handle_token(KWD_PROTECTED_INDEX); ;}
    break;

  case 298:

    { handle_token(KWD_PUBLIC_INDEX); ;}
    break;

  case 299:

    { handle_token(KWD_REGISTER_INDEX); ;}
    break;

  case 300:

    { handle_token(KWD_REINTERPRET_CAST_INDEX); ;}
    break;

  case 301:

    { handle_token(KWD_RETURN_INDEX); ;}
    break;

  case 302:

    { handle_token(KWD_SHORT_INDEX); ;}
    break;

  case 303:

    { handle_token(KWD_SIGNED_INDEX); ;}
    break;

  case 304:

    { handle_token(KWD_SIZEOF_INDEX); ;}
    break;

  case 305:

    { handle_token(KWD_STATIC_INDEX); ;}
    break;

  case 306:

    { handle_token(KWD_STATIC_CAST_INDEX); ;}
    break;

  case 307:

    { handle_token(KWD_STRUCT_INDEX); ;}
    break;

  case 308:

    { handle_token(KWD_SWITCH_INDEX); ;}
    break;

  case 309:

    { handle_token(KWD_TEMPLATE_INDEX); ;}
    break;

  case 310:

    { handle_token(KWD_THIS_INDEX); ;}
    break;

  case 311:

    { handle_token(KWD_THROW_INDEX); ;}
    break;

  case 312:

    { handle_token(KWD_TRY_INDEX); ;}
    break;

  case 313:

    { handle_token(KWD_TYPEDEF_INDEX); ;}
    break;

  case 314:

    { handle_token(KWD_TYPENAME_INDEX); ;}
    break;

  case 315:

    { handle_token(KWD_TYPEID_INDEX); ;}
    break;

  case 316:

    { handle_token(KWD_UNION_INDEX); ;}
    break;

  case 317:

    { handle_token(KWD_UNSIGNED_INDEX); ;}
    break;

  case 318:

    { handle_token(KWD_USING_INDEX); ;}
    break;

  case 319:

    { handle_token(KWD_VIRTUAL_INDEX); ;}
    break;

  case 320:

    { handle_token(KWD_VOID_INDEX); ;}
    break;

  case 321:

    { handle_token(KWD_VOLATILE_INDEX); ;}
    break;

  case 322:

    { handle_token(KWD_WCHAR_T_INDEX); ;}
    break;

  case 323:

    { handle_token(KWD_WHILE_INDEX); ;}
    break;

  case 325:

    { handle_token(BCS_PUNCT_HASH_INDEX); ;}
    break;

  case 326:

    { handle_token(ALT_PUNCT_HASH_INDEX); ;}
    break;

  case 327:

    { handle_token(OP_STRINGIZE_INDEX); ;}
    break;

  case 328:

    { handle_token(OP_TOKEN_SPLICE_INDEX); ;}
    break;

  case 329:

    { handle_token(ALT_OP_TOKEN_SPLICE_INDEX); ;}
    break;

  case 330:

    { handle_macro_open(function_macro_index /*MACRO_FUNCTION_IDENTIFIER_INDEX*/); ;}
    break;

  case 331:

    { handle_invalid_macro_id(OP_ALT_LOGICAL_AND_INDEX); ;}
    break;

  case 332:

    { handle_invalid_macro_id(OP_ALT_ASSIGN_BIT_AND_INDEX); ;}
    break;

  case 333:

    { handle_invalid_macro_id(OP_ALT_BIT_AND_INDEX); ;}
    break;

  case 334:

    { handle_invalid_macro_id(OP_ALT_BIT_OR_INDEX); ;}
    break;

  case 335:

    { handle_invalid_macro_id(OP_ALT_BIT_NOT_INDEX); ;}
    break;

  case 336:

    { handle_invalid_macro_id(OP_ALT_LOGICAL_NOT_INDEX); ;}
    break;

  case 337:

    { handle_invalid_macro_id(OP_ALT_NE_INDEX); ;}
    break;

  case 338:

    { handle_invalid_macro_id(OP_ALT_LOGICAL_OR_INDEX); ;}
    break;

  case 339:

    { handle_invalid_macro_id(OP_ALT_ASSIGN_BIT_OR_INDEX); ;}
    break;

  case 340:

    { handle_invalid_macro_id(OP_ALT_BIT_PLUS_INDEX); ;}
    break;

  case 341:

    { handle_invalid_macro_id(OP_ALT_ASSIGN_BIT_PLUS_INDEX); ;}
    break;

  case 342:

    { handle_macro_open(object_macro_index/*MACRO_OBJECT_IDENTIFIER_INDEX*/); ;}
    break;

  case 344:

    { handle_macro_undef(PPD_UNDEF_INDEX); ;}
    break;

  case 345:

    { pop(); ;}
    break;

  case 348:

    { handle_invalid_macro_id(OP_ALT_LOGICAL_AND_INDEX); ;}
    break;

  case 349:

    { handle_invalid_macro_id(OP_ALT_ASSIGN_BIT_AND_INDEX); ;}
    break;

  case 350:

    { handle_invalid_macro_id(OP_ALT_BIT_AND_INDEX); ;}
    break;

  case 351:

    { handle_invalid_macro_id(OP_ALT_BIT_OR_INDEX); ;}
    break;

  case 352:

    { handle_invalid_macro_id(OP_ALT_BIT_NOT_INDEX); ;}
    break;

  case 353:

    { handle_invalid_macro_id(OP_ALT_LOGICAL_NOT_INDEX); ;}
    break;

  case 354:

    { handle_invalid_macro_id(OP_ALT_NE_INDEX); ;}
    break;

  case 355:

    { handle_invalid_macro_id(OP_ALT_LOGICAL_OR_INDEX); ;}
    break;

  case 356:

    { handle_invalid_macro_id(OP_ALT_ASSIGN_BIT_OR_INDEX); ;}
    break;

  case 357:

    { handle_invalid_macro_id(OP_ALT_BIT_PLUS_INDEX); ;}
    break;

  case 358:

    { handle_invalid_macro_id(OP_ALT_ASSIGN_BIT_PLUS_INDEX); ;}
    break;

  case 359:

    { handle_token(OP_LOGICAL_NOT_INDEX); ;}
    break;

  case 360:

    { handle_token(OP_ALT_LOGICAL_NOT_INDEX); ;}
    break;

  case 363:

    { handle_token(OP_NE_INDEX); ;}
    break;

  case 364:

    { handle_token(OP_ALT_NE_INDEX); ;}
    break;

  case 368:

    { handle_token(OP_MODULO_INDEX); ;}
    break;

  case 370:

    { handle_token(OP_ASSIGN_MODULO_INDEX); ;}
    break;

  case 371:

    { handle_token(BCS_PUNCT_AMPERSAND_INDEX); ;}
    break;

  case 372:

    { handle_token(OP_ALT_BIT_AND_INDEX); ;}
    break;

  case 375:

    { handle_token(OP_LOGICAL_AND_INDEX); ;}
    break;

  case 376:

    { handle_token(OP_ALT_LOGICAL_AND_INDEX); ;}
    break;

  case 379:

    { handle_token(OP_ASSIGN_BIT_AND_INDEX); ;}
    break;

  case 380:

    { handle_token(OP_ALT_ASSIGN_BIT_AND_INDEX); ;}
    break;

  case 381:

    { handle_token_open(BCS_PUNCT_OPEN_PARENTHESIS_INDEX); ;}
    break;

  case 382:

    { handle_token_close(BCS_PUNCT_CLOSE_PARENTHESIS_INDEX); ;}
    break;

  case 383:

    { handle_token(BCS_PUNCT_ASTERISK_INDEX); ;}
    break;

  case 385:

    { handle_token(OP_ASSIGN_MULTIPLY_INDEX); ;}
    break;

  case 386:

    { handle_token(BCS_PUNCT_PLUS_INDEX); ;}
    break;

  case 389:

    { handle_token(OP_INCREMENT_INDEX); ;}
    break;

  case 390:

    { handle_token(OP_ASSIGN_PLUS_INDEX); ;}
    break;

  case 391:

    { handle_token(BCS_PUNCT_COMMA_INDEX); ;}
    break;

  case 393:

    { handle_token(BCS_PUNCT_MINUS_INDEX); ;}
    break;

  case 396:

    { handle_token(OP_DECREMENT_INDEX); ;}
    break;

  case 397:

    { handle_token(OP_ASSIGN_MINUS_INDEX); ;}
    break;

  case 398:

    { handle_token(OP_POINTER_MEMBER_INDEX); ;}
    break;

  case 399:

    { handle_token(OP_POINTER_POINTER_TO_MEMBER_INDEX); ;}
    break;

  case 400:

    { handle_token(BCS_PUNCT_PERIOD_INDEX); ;}
    break;

  case 401:

    { handle_token(DECL_VAR_ARGS_INDEX); ;}
    break;

  case 402:

    { handle_token(OP_OBJECT_POINTER_TO_MEMBER_INDEX); ;}
    break;

  case 404:

    { handle_token(OP_DIVIDE_INDEX); ;}
    break;

  case 406:

    { handle_token(OP_ASSIGN_DIVIDE_INDEX); ;}
    break;

  case 407:

    { handle_token(BCS_PUNCT_COLON_INDEX); ;}
    break;

  case 409:

    { handle_token(OP_SCOPE_REF_INDEX); ;}
    break;

  case 410:

    { handle_token(BCS_PUNCT_SEMICOLON_INDEX); ;}
    break;

  case 411:

    { handle_token(BCS_PUNCT_LESS_THAN_INDEX); ;}
    break;

  case 413:

    { handle_token(OP_SHIFT_LEFT_INDEX); ;}
    break;

  case 415:

    { handle_token(OP_ASSIGN_SHIFT_LEFT_INDEX); ;}
    break;

  case 416:

    { handle_token(OP_LE_INDEX); ;}
    break;

  case 418:

    { handle_token(BCS_PUNCT_EQUAL_INDEX); ;}
    break;

  case 419:

    { handle_token(OP_EQ_INDEX); ;}
    break;

  case 421:

    { handle_token(BCS_PUNCT_GREATER_THAN_INDEX); ;}
    break;

  case 423:

    { handle_token(OP_GE_INDEX); ;}
    break;

  case 425:

    { handle_token(OP_SHIFT_RIGHT_INDEX); ;}
    break;

  case 426:

    { handle_token(OP_SHIFT_RIGHT_INDEX); ;}
    break;

  case 427:

    { handle_token(OP_ASSIGN_SHIFT_RIGHT_INDEX); ;}
    break;

  case 429:

    { handle_token(OP_CONDITIONAL_INDEX); ;}
    break;

  case 431:

    { handle_token_open(BCS_PUNCT_OPEN_BRACKET_INDEX); ;}
    break;

  case 432:

    { handle_token_open(ALT_PUNCT_OPEN_BRACKET_INDEX); ;}
    break;

  case 433:

    { handle_token_close(BCS_PUNCT_CLOSE_BRACKET_INDEX); ;}
    break;

  case 434:

    { handle_token_close(ALT_PUNCT_CLOSE_BRACKET_INDEX); ;}
    break;

  case 435:

    { handle_token(OP_BIT_PLUS_INDEX); ;}
    break;

  case 436:

    { handle_token(OP_ALT_BIT_PLUS_INDEX); ;}
    break;

  case 439:

    { handle_token(OP_ASSIGN_BIT_PLUS_INDEX); ;}
    break;

  case 440:

    { handle_token(OP_ALT_ASSIGN_BIT_PLUS_INDEX); ;}
    break;

  case 441:

    { handle_token_open(BCS_PUNCT_OPEN_BRACE_INDEX); ;}
    break;

  case 442:

    { handle_token_open(ALT_PUNCT_OPEN_BRACE_INDEX); ;}
    break;

  case 443:

    { handle_token_close(BCS_PUNCT_CLOSE_BRACE_INDEX); ;}
    break;

  case 444:

    { handle_token_close(ALT_PUNCT_CLOSE_BRACE_INDEX); ;}
    break;

  case 445:

    { handle_token(OP_BIT_OR_INDEX); ;}
    break;

  case 446:

    { handle_token(OP_BIT_OR_INDEX); ;}
    break;

  case 449:

    { handle_token(OP_ASSIGN_BIT_OR_INDEX); ;}
    break;

  case 450:

    { handle_token(OP_ALT_ASSIGN_BIT_OR_INDEX); ;}
    break;

  case 451:

    { handle_token(OP_LOGICAL_OR_INDEX); ;}
    break;

  case 452:

    { handle_token(OP_ALT_LOGICAL_OR_INDEX); ;}
    break;

  case 455:

    { handle_token(OP_BIT_NOT_INDEX); ;}
    break;

  case 456:

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





/*
 *
 */
const char *get_yytname(int token) {
  return yytname[yytranslate[token]];
}

/*
 *
 */
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


