%{
#include "rtfparser.h"

int destination_mode = 0;
int bin_mode = 0;
long binlen = 0;
long binpos = 0;
long bracecount = 0;
long destbracecount = 0;
%}
%pointer
%x control
%x cparms
%x destination
%x destctl
%x binmode
%x hexmode
%option noyywrap
%option prefix="rtf_yy"
%%
                                   if(destination_mode){
                                     BEGIN destination;
                                     destination_mode = destbracecount = 0;
                                   }
<destctl>bin[0-9]+[ \t]?           {
                                     register int c;
                                     binlen = strtol(rtf_yytext+3, NULL, 10);
                                     for(binpos = 0; binpos < binlen; binpos++){
                                       c = input();
                                       if(c == EOF)
                                         return UNEOF;
                                     }
                                     BEGIN destination;
                                   }
<destctl>.|\n                      BEGIN destination;
<destination>\\                    BEGIN destctl;
<destination>\{                    destbracecount++;
<destination>\}                    { 
                                     destbracecount--; 
                                     if(destbracecount < 0){
                                       bracecount--;
                                       BEGIN INITIAL;
                                       return DESTN;
                                     }
                                   }
<destination>[^{}\\]
<control>[-~*\\:_{|}\r\n]          { BEGIN INITIAL; return CSYMB; }
<control>[A-Za-z]+                 {
                                     if(!strcmp(rtf_yytext, "bin"))
                                       bin_mode = 1;
                                     BEGIN cparms;
                                     return CWORD;
                                   }
<control>'                         { BEGIN hexmode; return CSYMB; }
<control>.                         { BEGIN INITIAL; return CUNDF; }
<cparms>-?[0-9]+                   {
                                     if(bin_mode){
                                       binlen = strtol(rtf_yytext, NULL, 10);
                                       binpos = 0;
                                     }
                                     return CPARM;
                                   }
<cparms>[ \t\r\n]                  { 
                                     if(bin_mode){
                                       BEGIN binmode;
                                     }else{
                                       BEGIN INITIAL;
                                     }
                                     return CNOPR;
                                   }
<cparms>.                          { 
                                     unput(rtf_yytext[0]);
                                     rtf_yyleng = 0;
                                     if(bin_mode){
                                       BEGIN binmode;
                                     }else{
                                       BEGIN INITIAL;
                                     }
                                     return CNOPR;
                                   }
<hexmode>[0-9A-Fa-f]{2}            { BEGIN INITIAL; return ENHEX; }
<hexmode>.|\n                      { BEGIN INITIAL; unput(rtf_yytext[0]); return WRHEX; }
<binmode>.|\n                      {
                                     binpos++;
                                     if(binpos >= binlen-1){
                                       bin_mode = 0;
                                       BEGIN INITIAL;
                                       return ENBIN;
                                     }
                                     return PTEXT;
                                   }
\\                                 BEGIN control;
\{                                 { 
                                     bracecount++;
                                     BEGIN INITIAL;
                                     return ENTER;
                                   }
\}                                 { 
                                     bracecount--;
                                     BEGIN INITIAL;
                                     if(bracecount < 0){
                                       bracecount = 0;
                                       return UNBRC;
                                     }else{
                                       return LEAVE;
                                     }
                                   }
[^\\{}\r\n]+                       { return PTEXT; }
\r
\n
<*><<EOF>>                         { return bracecount ? UNEOF : OKEOF; }
%%

void rtf_set_destination(void){
  destination_mode = 1;
}

void rtf_set_source(FILE *fh){
  destination_mode = bin_mode = 0;
  bracecount = destbracecount = binpos = binlen = 0;
  yyrestart(fh);
  BEGIN INITIAL;
}

