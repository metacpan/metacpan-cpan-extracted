#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

extern char *rtf_yytext;
extern int rtf_yyleng;

extern int  rtf_yylex(void);
extern void rtf_set_destination(void);
extern void rtf_set_source(FILE*);

MODULE = RTF::Lexer  PACKAGE = RTF::Lexer

PROTOTYPES: DISABLE

int _get_token(self, val)
  void *self
  SV *val
CODE:
  int token;
  token = rtf_yylex();
  if(token){
     if(rtf_yyleng)
       sv_setpv(val, rtf_yytext);
     else
       sv_setpv(val, "");
  }
  RETVAL = token;
OUTPUT:
  RETVAL

void set_destination(self)
  void *self
CODE:
  rtf_set_destination();

void _set_source(self, fh)
  void *self
  FILE *fh
CODE:
  rtf_set_source(fh);

