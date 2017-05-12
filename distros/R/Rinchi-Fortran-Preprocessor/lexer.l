%{
/*
 * UUID: 0d6ccd78-f62a-11dc-82ec-00502c05c241
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
[!][^\n]*                           { handle_comment(yytext+2); }
^[C][^\n]*                          { handle_comment(yytext+2); }
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
^[ \t]*"#"[ ]*"warning"[ \t]+       { return PPD_WARNING; }
^[ \t]*"#"[ ]*"include"[ \t]+       { yy_push_state(X_PPD_INCLUDE); return PPD_INCLUDE; }
^[ \t]*"#"[ ]*"line"[ \t]+          { return PPD_LINE; }
^[ \t]*"#"[ ]*"pragma"[ \t]+        { return PPD_PRAGMA; }
^[ \t]*"#"[ ]*"undef"[ \t]+         { yy_push_state(X_PPD_ID); return PPD_UNDEF; }

^[ \t]*"??="[ ]*"define"[ \t]+      { yy_push_state(X_PPD_DEFINE); return PPD_DEFINE; }
^[ \t]*"??="[ ]*"error"[ \t]+       { return PPD_ERROR; }
^[ \t]*"??="[ ]*"warning"[ \t]+     { return PPD_WARNING; }
^[ \t]*"??="[ ]*"include"[ \t]+     { yy_push_state(X_PPD_INCLUDE); return PPD_INCLUDE; }
^[ \t]*"??="[ ]*"line"[ \t]+        { return PPD_LINE; }
^[ \t]*"??="[ ]*"pragma"[ \t]+      { return PPD_PRAGMA; }
^[ \t]*"??="[ ]*"undef"[ \t]+       { yy_push_state(X_PPD_ID); return PPD_UNDEF; }

}

<X_INIT,X_PPD_IF>{

"abstract"/[^a-z_]                  { return KWD_ABSTRACT;           }
"abstract"[ \t]+"interface"/[^a-z_] { return KWD_ABSTRACT_INTERFACE; }
"access"/[^a-z_]                    { return KWD_ACCESS;             }
"action"/[^a-z_]                    { return KWD_ACTION;             }
"advance"/[^a-z_]                   { return KWD_ADVANCE;            }
"allocatable"/[^a-z_]               { return KWD_ALLOCATABLE;        }
"allocate"/[^a-z_]                  { return KWD_ALLOCATE;           }
"assign"/[^a-z_]                    { return KWD_ASSIGN;             }
"associate"/[^a-z_]                 { return KWD_ASSOCIATE;          }
"asynchronous"/[^a-z_]              { return KWD_ASYNCHRONOUS;       }
"backspace"/[^a-z_]                 { return KWD_BACKSPACE;          }
"bind"/[^a-z_]                      { return KWD_BIND;               }
"blank"/[^a-z_]                     { return KWD_BLANK;              }
"block"/[^a-z_]                     { return KWD_BLOCK;              }
"block"[ \t]*"data"/[^a-z_]         { return KWD_BLOCK_DATA;         }
"call"/[^a-z_]                      { return KWD_CALL;               }
"case"/[^a-z_]                      { return KWD_CASE;               }
"character"/[^a-z_]                 { return KWD_CHARACTER;          }
"class"/[^a-z_]                     { return KWD_CLASS;              }
"class"[ \t]+"default"/[^a-z_]      { return KWD_CLASS_DEFAULT;      }
"class"[ \t]+"is"/[^a-z_]           { return KWD_CLASS_IS;           }
"close"/[^a-z_]                     { return KWD_CLOSE;              }
"common"/[^a-z_]                    { return KWD_COMMON;             }
"complex"/[^a-z_]                   { return KWD_COMPLEX;            }
"contains"/[^a-z_]                  { return KWD_CONTAINS;           }
"contiguous"/[^a-z_]                { return KWD_CONTIGUOUS;         }
"continue"/[^a-z_]                  { return KWD_CONTINUE;           }
"cycle"/[^a-z_]                     { return KWD_CYCLE;              }
"data"/[^a-z_]                      { return KWD_DATA;               }
"deallocate"/[^a-z_]                { return KWD_DEALLOCATE;         }
"default"/[^a-z_]                   { return KWD_DEFAULT;            }
"deferred"/[^a-z_]                  { return KWD_DEFERRED;           }
"dimension"/[^a-z_]                 { return KWD_DIMENSION;          }
"direct"/[^a-z_]                    { return KWD_DIRECT;             }
"do"/[^a-z_]                        { return KWD_DO;                 }
"double"/[^a-z_]                    { return KWD_DOUBLE;             }
"double_complex"/[^a-z_]            { return KWD_DOUBLE_COMPLEX;     }
"double"[ \t]+"precision"/[^a-z_]   { return KWD_DOUBLE_PRECISION;   }
"elemental"/[^a-z_]                 { return KWD_ELEMENTAL;          }
"else"/[^a-z_]                      { return KWD_ELSE;               }
"else"[ \t]*"if"/[^a-z_]            { return KWD_ELSE_IF;            }
"else"[ \t]*"where"/[^a-z_]         { return KWD_ELSE_WHERE;         }
"encoding"/[^a-z_]                  { return KWD_ENCODING;           }
"end"/[^a-z_]                       { return KWD_END;                }
"end"[ \t]*"associate"/[^a-z_]      { return KWD_END_ASSOCIATE;      }
^[ \t]*"end"[ \t]*"block"[ \t]*"data"/[^a-z_]            { return KWD_END_BLOCK_DATA; }
"end"[ \t]*"block"/[^a-z_]          { return KWD_END_BLOCK;          }
"end"[ \t]*"do"/[^a-z_]             { return KWD_END_DO;             }
"end"[ \t]*"enum"/[^a-z_]           { return KWD_END_ENUM;           }
"end"[ \t]*"file"/[^a-z_]           { return KWD_END_FILE;           }
"end"[ \t]*"forall"/[^a-z_]         { return KWD_END_FORALL;         }
"end"[ \t]*"function"/[^a-z_]       { return KWD_END_FUNCTION;       }
"end"[ \t]*"if"/[^a-z_]             { return KWD_END_IF;             }
"end"[ \t]*"interface"/[^a-z_]      { return KWD_END_INTERFACE;      }
"end"[ \t]*"module"/[^a-z_]         { return KWD_END_MODULE;         }
"end"[ \t]+"procedure"/[^a-z_]      { return KWD_END_PROCEDURE;      }
"end"[ \t]*"program"/[^a-z_]        { return KWD_END_PROGRAM;        }
"end"[ \t]*"select"/[^a-z_]         { return KWD_END_SELECT;         }
"end"[ \t]+"submodule"/[^a-z_]      { return KWD_END_SUBMODULE;      }
"end"[ \t]*"subroutine"/[^a-z_]     { return KWD_END_SUBROUTINE;     }
"end"[ \t]*"type"/[^a-z_]           { return KWD_END_TYPE;           }
"end"[ \t]*"where"/[^a-z_]          { return KWD_END_WHERE;          }
"entry"/[^a-z_]                     { return KWD_ENTRY;              }
"eor"/[^a-z_]                       { return KWD_EOR;                }
"equivalence"/[^a-z_]               { return KWD_EQUIVALENCE;        }
"err"/[^a-z_]                       { return KWD_ERR;                }
"errmsg"/[^a-z_]                    { return KWD_ERRMSG;             }
"exist"/[^a-z_]                     { return KWD_EXIST;              }
"exit"/[^a-z_]                      { return KWD_EXIT;               }
"extends"/[^a-z_]                   { return KWD_EXTENDS;            }
"extensible"/[^a-z_]                { return KWD_EXTENSIBLE;         }
"external"/[^a-z_]                  { return KWD_EXTERNAL;           }
"false"/[^a-z_]                     { return KWD_FALSE;              }
"file"/[^a-z_]                      { return KWD_FILE;               }
"final"/[^a-z_]                     { return KWD_FINAL;              }
"flush"/[^a-z_]                     { return KWD_FLUSH;              }
"fmt"/[^a-z_]                       { return KWD_FMT;                }
"forall"/[^a-z_]                    { return KWD_FORALL;             }
"form"/[^a-z_]                      { return KWD_FORM;               }
"format"/[^a-z_]                    { return KWD_FORMAT;             }
"formatted"/[^a-z_]                 { return KWD_FORMATTED;          }
"function"/[^a-z_]                  { return KWD_FUNCTION;           }
"generic"/[^a-z_]                   { return KWD_GENERIC;            }
"go"[ \t]*"to"/[^a-z_]              { return KWD_GOTO;               }
"if"/[^a-z_]                        { return KWD_IF;                 }
"implicit"[ \t]+"none"/[^a-z_]      { return KWD_IMPLICIT_NONE;      }
"implicit"/[^a-z_]                  { return KWD_IMPLICIT;           }
"import"/[^a-z_]                    { return KWD_IMPORT;             }
"impure"/[^a-z_]                    { return KWD_IMPURE;             }
"in"/[^a-z_]                        { return KWD_IN;                 }
"in"[ \t]*"out"/[^a-z_]             { return KWD_IN_OUT;             }
^[ \t]*"include"/[^a-z_]            { return KWD_INCLUDE;            }
"inquire"/[^a-z_]                   { return KWD_INQUIRE;            }
"integer"/[^a-z_]                   { return KWD_INTEGER;            }
"intent"/[^a-z_]                    { return KWD_INTENT;             }
"interface"/[^a-z_]                 { return KWD_INTERFACE;          }
"intrinsic"/[^a-z_]                 { return KWD_INTRINSIC;          }
"iostat"/[^a-z_]                    { return KWD_IOSTAT;             }
"iomsg"/[^a-z_]                     { return KWD_IOMSG;              }
"kind"/[^a-z_]                      { return KWD_KIND;               }
"let"/[^a-z_]                       { return KWD_LET;                }
"logical"/[^a-z_]                   { return KWD_LOGICAL;            }
"module"/[^a-z_]                    { return KWD_MODULE;             }
"mold"/[^a-z_]                      { return KWD_MOLD;               }
"name"/[^a-z_]                      { return KWD_NAME;               }
"named"/[^a-z_]                     { return KWD_NAMED;              }
"namelist"/[^a-z_]                  { return KWD_NAMELIST;           }
"nextrec"/[^a-z_]                   { return KWD_NEXTREC;            }
"non"[ \t]+"intrinsic"/[^a-z_]      { return KWD_NON_INTRINSIC;      }
"non"[ \t]+"overridable"/[^a-z_]    { return KWD_NON_OVERRIDABLE;    }
"nonkind"/[^a-z_]                   { return KWD_NONKIND;            }
"none"/[^a-z_]                      { return KWD_NONE;               }
"nopass"/[^a-z_]                    { return KWD_NOPASS;             }
"nullify"/[^a-z_]                   { return KWD_NULLIFY;            }
"number"/[^a-z_]                    { return KWD_NUMBER;             }
"open"/[^a-z_]                      { return KWD_OPEN;               }
"opened"/[^a-z_]                    { return KWD_OPENED;             }
"operator"/[^a-z_]                  { return KWD_OPERATOR;           }
"optional"/[^a-z_]                  { return KWD_OPTIONAL;           }
"out"/[^a-z_]                       { return KWD_OUT;                }
"pad"/[^a-z_]                       { return KWD_PAD;                }
"parameter"/[^a-z_]                 { return KWD_PARAMETER;          }
"pass"/[^a-z_]                      { return KWD_PASS;               }
"pause"/[^a-z_]                     { return KWD_PAUSE;              }
"pending"/[^a-z_]                   { return KWD_PENDING;            }
"pointer"/[^a-z_]                   { return KWD_POINTER;            }
"position"/[^a-z_]                  { return KWD_POSITION;           }
"precision"/[^a-z_]                 { return KWD_PRECISION;          }
"print"/[^a-z_]                     { return KWD_PRINT;              }
"private"/[^a-z_]                   { return KWD_PRIVATE;            }
"procedure"/[^a-z_]                 { return KWD_PROCEDURE;          }
"program"/[^a-z_]                   { return KWD_PROGRAM;            }
"protected"/[^a-z_]                 { return KWD_PROTECTED;          }
"public"/[^a-z_]                    { return KWD_PUBLIC;             }
"pure"/[^a-z_]                      { return KWD_PURE;               }
"read"/[^a-z_]                      { return KWD_READ;               }
"read"[ \t]+"formatted"/[^a-z_]     { return KWD_READ_FORMATTED;     }
"read"[ \t]+"unformatted"/[^a-z_]   { return KWD_READ_UNFORMATTED;   }
"readwrite"/[^a-z_]                 { return KWD_READWRITE;          }
"real"/[^a-z_]                      { return KWD_REAL;               }
"rec"/[^a-z_]                       { return KWD_REC;                }
"recl"/[^a-z_]                      { return KWD_RECL;               }
"return"/[^a-z_]                    { return KWD_RETURN;             }
"rewind"/[^a-z_]                    { return KWD_REWIND;             }
"round"/[^a-z_]                     { return KWD_ROUND;              }
"save"/[^a-z_]                      { return KWD_SAVE;               }
"select"[ \t]*"case"/[^a-z_]        { return KWD_SELECT_CASE;        }
"select"[ \t]*"type"/[^a-z_]        { return KWD_SELECT_TYPE;        }
"sequence"/[^a-z_]                  { return KWD_SEQUENCE;           }
"sequential"/[^a-z_]                { return KWD_SEQUENTIAL;         }
"sign"/[^a-z_]                      { return KWD_SIGN;               }
"size"/[^a-z_]                      { return KWD_SIZE;               }
"source"/[^a-z_]                    { return KWD_SOURCE;             }
"status"/[^a-z_]                    { return KWD_STATUS;             }
"stop"/[^a-z_]                      { return KWD_STOP;               }
"stream"/[^a-z_]                    { return KWD_STREAM;             }
"submodule"/[^a-z_]                 { return KWD_SUBMODULE;          }
"subroutine"/[^a-z_]                { return KWD_SUBROUTINE;         }
"target"/[^a-z_]                    { return KWD_TARGET;             }
"then"/[^a-z_]                      { return KWD_THEN;               }
"true"/[^a-z_]                      { return KWD_TRUE;               }
"type"/[^a-z_]                      { return KWD_TYPE;               }
"unformatted"/[^a-z_]               { return KWD_UNFORMATTED;        }
"unit"/[^a-z_]                      { return KWD_UNIT;               }
"use"/[^a-z_]                       { return KWD_USE;                }
"value"/[^a-z_]                     { return KWD_VALUE;              }
"volatile"/[^a-z_]                  { return KWD_VOLATILE;           }
"where"/[^a-z_]                     { return KWD_WHERE;              }
"write"/[^a-z_]                     { return KWD_WRITE;              }
"write"[ \t]+"formatted"/[^a-z_]    { return KWD_WRITE_FORMATTED;    }
"write"[ \t]+"unformated"/[^a-z_]   { return KWD_WRITE_UNFORMATTED;  }

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

  /* "!="                                { return OP_NE; } */
"/="                                { return OP_NE; }
".ne."                              { return OP_NE; }
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
  /* "/="                                { return OP_ASSIGN_DIVIDE; } */
"::"                                { return PUNC_DBL_COLON; }
"<<="                               { return OP_ASSIGN_SHIFT_LEFT; }
"<<"                                { return OP_SHIFT_LEFT; }
"<="                                { return OP_LE; }
".le."                              { return OP_LE; }
"=="                                { return OP_EQ; }
".eq."                              { return OP_EQ; }
"=>"                                { return PUNC_ARROW; }
">="                                { return OP_GE; }
".ge."                              { return OP_GE; }
">>="                               { return OP_ASSIGN_SHIFT_RIGHT; }
">>"                                { return OP_SHIFT_RIGHT; }
"^="                                { return OP_ASSIGN_BIT_PLUS; }
"|="                                { return OP_ASSIGN_BIT_OR; }
"||"                                { return OP_LOGICAL_OR; }
".lt."                              { return OP_LT; }
".gt."                              { return OP_GT; }

}

<X_PPD_IF>{

\n                                  { yyless(0); yy_pop_state();  }

}

<X_INIT>{
[ \t]*                              { copy_string(yytext); return WHITE_SPACE; }
}

<X_PPD_IF>{
[ \t]                              { ; }
}

<X_INIT,X_PPD_IF>{

  /* [!]      { return BCS_PUNCT_EXCLAMATION; } */

[#]      { return BCS_PUNCT_HASH; }
[%]      { return BCS_PUNCT_PERCENT; }
[&]      { return BCS_PUNCT_AMPERSAND; }

"(/"     { return OPEN_PARENTHESIS_SLASH; }
"/)"     { return CLOSE_PARENTHESIS_SLASH; }
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
.|\n                                { yyless(0); yy_pop_state(); if (not_a_macro()) return IDENTIFIER; }
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
.                                   { yyless(0); yy_pop_state(); yy_push_state(X_PPD_STRING); yy_push_state(X_SKIP_WHITESPACE); return MACRO_OBJECT_IDENTIFIER; }
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

#include "lexer_routines.inc"

