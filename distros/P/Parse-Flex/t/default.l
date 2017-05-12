/*
 Copyright (C) 2003 Ioannis Tambouras <ioannis@earthlink.net> . All rights reserved.
 LICENSE:  Latest version of GPL. Read licensing terms at  http://www.fsf.org .
*/

%{ 
#define YY_DECL char* yylex(void)
%}

%pointer
%option yylineno noyywrap
 //%option debug perf-report


NUM   [0-9]+
WORD  [a-z][A-Za-z0-9_]+
EMAIL ({WORD}[.]?)+[@]({WORD}.)+[a-z]{2,3}

%%
    BEGIN(0);
{EMAIL}       return "EMAIL"  ;
{NUM}         return "NUM"    ;
{WORD}        return "WORD"   ;
[a-zA-Z]/\    return "CHAR"   ;
\n
[ ]
. 
<<EOF>>       return  ""      ;
%%

