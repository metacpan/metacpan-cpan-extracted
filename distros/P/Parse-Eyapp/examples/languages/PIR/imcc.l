LETTER          [a-zA-Z_@]
DIGIT           [0-9]
DIGITS          {DIGIT}+
HEX             0[xX][0-9A-Fa-f]+
OCT             0[oO][0-7]+
BIN             0[bB][01]+
DOT             [.]
SIGN            [-+]
BIGINT          {SIGN}?{DIGITS}"L"
FLOATNUM        {SIGN}?(({DIGITS}{DOT}{DIGIT}*|{DOT}{DIGITS})([eE]{SIGN}?{DIGITS})?|{DIGITS}[eE]{SIGN}?{DIGITS})
LETTERDIGIT     [a-zA-Z0-9_]
LABELLETTERDIGIT([a-zA-Z0-9_@])
ID              {LETTER}{LABELLETTERDIGIT}*
DQ_STRING       \"(\\.|[^"\\\n])*\"
ENCCHAR         {LETTER}|{DIGIT}|"-"
ENCCHARS        {ENCCHAR}*
ENC             {LETTER}{ENCCHARS}":"
UNICODE         {ENC}{ENC}?{DQ_STRING}
STRINGCONSTANT  {SQ_STRING}|{DQ_STRING}
SQ_STRING       \'[^'\n]*\'
RANKSPEC        \[[,]*\]
EOL        \r?\n
WS              [\t\f\r\x1a ]
SP              [ ]

%x emit
%x macro
%x pod
%x cmt1
%x cmt2
%x cmt3
%x cmt4
%x cmt5
%x heredoc1
%x heredoc2


%%
        /* for emacs "*/
        if (IMCC_INFO(interp)->expect_pasm == 1 && !IMCC_INFO(interp)->in_pod) {
            IMCC_INFO(interp)->expect_pasm = 2;
            BEGIN(emit);
        }

        if (IMCC_INFO(interp)->frames->s.pasm_file && YYSTATE == INITIAL &&
            !IMCC_INFO(interp)->in_pod)
        {
            if (IMCC_INFO(interp)->frames->s.pasm_file == 1) {
                BEGIN(emit);
                return EMIT;
            }

            return 0;
        }

<heredoc1>.*{EOL} {
            IMCC_INFO(interp)->frames->heredoc_rest = mem_sys_strdup(yytext);
            BEGIN(heredoc2);
    }

<heredoc2>{EOL} {
        /* heredocs have highest priority
         * arrange them before all wildcard state matches */

        /* Newline in the heredoc. Realloc and cat on. */
        IMCC_INFO(interp)->line++;
        IMCC_INFO(interp)->heredoc_content =
            (char*)mem_sys_realloc(IMCC_INFO(interp)->heredoc_content,
                            strlen(IMCC_INFO(interp)->heredoc_content) +
                            strlen(yytext) + 2);
        strcpy(IMCC_INFO(interp)->heredoc_content +
               strlen(IMCC_INFO(interp)->heredoc_content), yytext);
    }

<heredoc2>.* {
        /* Are we at the end of the heredoc? */
        if (STREQ(IMCC_INFO(interp)->heredoc_end, yytext)) {
            /* End of the heredoc. */
            yyguts_t * const yyg = (yyguts_t *)yyscanner;
            const int len        = strlen(IMCC_INFO(interp)->heredoc_content);

            /* delim */
            IMCC_INFO(interp)->heredoc_content[len] =
                IMCC_INFO(interp)->heredoc_content[0];

            IMCC_INFO(interp)->heredoc_content[len + 1] = 0;

            mem_sys_free(IMCC_INFO(interp)->heredoc_end);
            IMCC_INFO(interp)->heredoc_end = NULL;

            IMCC_INFO(interp)->frames->buffer = YY_CURRENT_BUFFER;
            valp->s                           =
                IMCC_INFO(interp)->heredoc_content;

            yy_pop_state(yyscanner);
            yy_scan_string(IMCC_INFO(interp)->frames->heredoc_rest, yyscanner);

            /* the EOF rule will increment the line number; decrement here */
            IMCC_INFO(interp)->line--;
            return STRINGC;
        }
        else {
            /* Part of the heredoc. Realloc and cat the line on. */
            IMCC_INFO(interp)->heredoc_content =
                (char *)mem_sys_realloc(IMCC_INFO(interp)->heredoc_content,
                                strlen(IMCC_INFO(interp)->heredoc_content) +
                                strlen(yytext) + 2);
            strcpy(IMCC_INFO(interp)->heredoc_content +
                   strlen(IMCC_INFO(interp)->heredoc_content), yytext);
        }
    }

<cmt2>[^"]+ {
        yy_pop_state(yyscanner);
        yy_push_state(cmt3, yyscanner);

        IMCC_INFO(interp)->frames->s.file = mem_sys_strdup(yytext);
        IMCC_INFO(interp)->cur_unit->file = mem_sys_strdup(yytext);

        return FILECOMMENT;
    }

<cmt3>["] {
        yy_pop_state(yyscanner);
        yy_push_state(cmt4, yyscanner);
    }

<*>setfile{SP}+["] { yy_push_state(cmt2, yyscanner); }

<*>setline{SP}+ { yy_push_state(cmt1, yyscanner);  }

<cmt1>{DIGITS} {
        IMCC_INFO(interp)->line = atoi(yytext);
        yy_pop_state(yyscanner);
        yy_push_state(cmt4, yyscanner);
        return LINECOMMENT;
    }

<cmt4>.*{EOL} {
        yy_pop_state(yyscanner);
        IMCC_INFO(interp)->line++;
    }

<INITIAL,emit>{EOL} {
        if (IMCC_INFO(interp)->expect_pasm == 2)
            BEGIN(INITIAL);

        IMCC_INFO(interp)->expect_pasm = 0;
        IMCC_INFO(interp)->line++;

        return '\n';
    }

<INITIAL,emit># {
        yy_push_state(cmt5, yyscanner);
    }

<cmt5>.*{EOL} {
        if (IMCC_INFO(interp)->expect_pasm == 2)
            BEGIN(INITIAL);
        else
            yy_pop_state(yyscanner);

        IMCC_INFO(interp)->expect_pasm = 0;
        IMCC_INFO(interp)->line++;

        return '\n';
    }


<INITIAL,emit,macro>^"=cut"{EOL} {
    /* this is a stand-alone =cut, but we're not in POD mode, so ignore.  */
    IMCC_INFO(interp)->line++;
}

<INITIAL,emit,macro>^"=" {
        IMCC_INFO(interp)->in_pod = 1;
        yy_push_state(pod, yyscanner);
    }

<pod>^"=cut"{EOL} {
        IMCC_INFO(interp)->in_pod = 0;
        yy_pop_state(yyscanner);
        IMCC_INFO(interp)->line++;
    }

<pod>.*         { /*ignore*/ }

<pod>{EOL}      { IMCC_INFO(interp)->line++; }

<*>".line"               return TK_LINE;
<*>".file"               return TK_FILE;
<INITIAL,emit>".annotate" return ANNOTATE;
<INITIAL,emit>".lex"     return LEXICAL;
".set_arg"               return ARG;
".sub"                   return SUB;
".end"                   return ESUB;
".begin_call"            return PCC_BEGIN;
".end_call"              return PCC_END;
".call"                  return PCC_CALL;
".nci_call"              return NCI_CALL;
".meth_call"             return METH_CALL;
".invocant"              return INVOCANT;
<emit,INITIAL>".pcc_sub" return PCC_SUB;
".begin_return"          return PCC_BEGIN_RETURN;
".end_return"            return PCC_END_RETURN;
".begin_yield"           return PCC_BEGIN_YIELD;
".end_yield"             return PCC_END_YIELD;

<emit,INITIAL>":method"    return METHOD;
<emit,INITIAL>":multi"     return MULTI;
<emit,INITIAL>":main"      return MAIN;
<emit,INITIAL>":load"      return LOAD;
<emit,INITIAL>":init"      return INIT;
<emit,INITIAL>":immediate" return IMMEDIATE;
<emit,INITIAL>":postcomp"  return POSTCOMP;
<emit,INITIAL>":anon"      return ANON;
<emit,INITIAL>":outer"     return OUTER;
<emit,INITIAL>":lex"       return NEED_LEX;
<emit,INITIAL>":vtable"    return VTABLE_METHOD;
<emit,INITIAL>":nsentry"   return NS_ENTRY;
":unique_reg"              return UNIQUE_REG;
":instanceof"              return SUB_INSTANCE_OF;
":subid"                   return SUBID;

".get_result"                  return RESULT;
".get_results"             return GET_RESULTS;
".yield"                   return YIELDT;
".set_yield"               return SET_YIELD;
".return"                  return RETURN;
".set_return"              return SET_RETURN;
".tailcall"                return TAILCALL;
<emit,INITIAL>".loadlib"   return LOADLIB;

":flat"         return ADV_FLAT;
":slurpy"       return ADV_SLURPY;
":optional"     return ADV_OPTIONAL;
":opt_flag"     return ADV_OPT_FLAG;
":named"        return ADV_NAMED;
"=>"            return ADV_ARROW;
":invocant"     return ADV_INVOCANT;
":call_sig"     return ADV_CALL_SIG;

<emit,INITIAL>".namespace"    return NAMESPACE;
<emit,INITIAL>".HLL"          return HLL;

".local"                      return LOCAL;
<emit,INITIAL>".const"        return CONST;
".globalconst"                return GLOBAL_CONST;
".param"                      return PARAM;
"goto"                        return GOTO;
"if"                          return IF;
"unless"                      return UNLESS;
"null"                        return PNULL;
"int"                         return INTV;
"num"                         return FLOATV;

"pmc"                         return PMCV;
"string"                      return STRINGV;
"<<"                          return SHIFT_LEFT;
">>"                          return SHIFT_RIGHT;
">>>"                         return SHIFT_RIGHT_U;
"&&"                          return LOG_AND;
"||"                          return LOG_OR;
"~~"                          return LOG_XOR;
"<"                           return RELOP_LT;
"<="                          return RELOP_LTE;
">"                           return RELOP_GT;
">="                          return RELOP_GTE;
"=="                          return RELOP_EQ;
"!="                          return RELOP_NE;
"**"                          return POW;

{WS}+"."{WS}+          return CONCAT;
"."                    return DOT;

"+="                   return PLUS_ASSIGN;
"-="                   return MINUS_ASSIGN;
"*="                   return MUL_ASSIGN;
"/="                   return DIV_ASSIGN;
"%="                   return MOD_ASSIGN;
"//"                   return FDIV;
"//="                  return FDIV_ASSIGN;
"&="                   return BAND_ASSIGN;
"|="                   return BOR_ASSIGN;
"~="                   return BXOR_ASSIGN;
">>="                  return SHR_ASSIGN;
"<<="                  return SHL_ASSIGN;
">>>="                 return SHR_U_ASSIGN;
".="                   return CONCAT_ASSIGN;

<emit,INITIAL>".macro_const" {
        char *macro_name   = NULL;
        int   start_cond   = YY_START;
        int   macro_exists = 0;
        int   c;
        int   start_line;

        BEGIN(macro);
        c = yylex_skip(valp, interp, " ", yyscanner);

        if (c != IDENTIFIER)
            IMCC_fataly(interp, EXCEPTION_SYNTAX_ERROR,
               "Constant names must be identifiers");

        IMCC_INFO(interp)->cur_macro_name = macro_name = valp->s;
        start_line                        = IMCC_INFO(interp)->line;

        c = yylex_skip(valp, interp, " ", yyscanner);

        if (c != INTC && c != FLOATC && c != STRINGC && c != REG)
            IMCC_fataly(interp, EXCEPTION_SYNTAX_ERROR,
                "Constant '%s' value must be a number, "
                "stringliteral or register", macro_name);

        /* macro_name becomes a hash key
         * the first one needs to remain; destroying the hash frees it
         * subsequent macro_names need destruction here to avoid leaks */
        if (find_macro(interp, macro_name))
            macro_exists = 1;

        define_macro(interp, macro_name, NULL, valp->s, start_line);
        mem_sys_free(valp->s);

        /* don't leak these */
        if (macro_exists)
            mem_sys_free(macro_name);

        IMCC_INFO(interp)->cur_macro_name = NULL;

        BEGIN(start_cond);
        return MACRO;
    }

<emit,INITIAL>".macro" {
        return read_macro(valp, interp, yyscanner);
    }

<emit,INITIAL>".include" {
        const int c = yylex(valp, yyscanner, interp);

        if (c != STRINGC)
            return c;

        /* STRINGCs have a mem_sys_strdup()ed valp->s */
        mem_sys_free(valp->s);
        YYCHOP();
        include_file(interp, yytext + 1, yyscanner);
    }

<emit,INITIAL>{ID}"$:" {
        if (valp) {
            char *label;
            size_t len;

            YYCHOP();
            YYCHOP();

            if (!IMCC_INFO(interp)->frames || !IMCC_INFO(interp)->frames->label)
                    IMCC_fataly(interp, EXCEPTION_SYNTAX_ERROR, "missing space?");

            len = yyleng + 10;
            label = (char *)mem_sys_allocate(len);
            snprintf(label, len, "%s%d", yytext, IMCC_INFO(interp)->frames->label);

            /* XXX: free valp->s if it exists? */
            valp->s = label;
        }

        return LABEL;
    }

<emit,INITIAL>{ID}"$" {

        if (valp) {
            char *label;
            size_t len;
            YYCHOP();

            if (!IMCC_INFO(interp)->frames || !IMCC_INFO(interp)->frames->label)
                IMCC_fataly(interp, EXCEPTION_SYNTAX_ERROR, "missing space?");

            len = yyleng + 10;
            label = (char *)mem_sys_allocate(len);
            snprintf(label, len, "%s%d", yytext, IMCC_INFO(interp)->frames->label);

            /* XXX: free valp->s if it exists? */
            valp->s = label;
        }

        return IDENTIFIER;
     }

<emit,INITIAL>","             return COMMA;

<emit,INITIAL>{ID}":" {
        /* trim last ':' */
        YYCHOP();

        if (valp)
            valp->s = mem_sys_strdup(yytext);

        return LABEL;
    }

<emit,INITIAL>{DOT}{LETTER}{LETTERDIGIT}* {
        char   * const macro_name = mem_sys_strdup(yytext + 1);
        int failed = expand_macro(interp, macro_name, yyscanner);
        mem_sys_free(macro_name);
        if (!failed) {
            yyless(1);
            return DOT;
        }
    }



<*>{FLOATNUM}         DUP_AND_RET(valp, FLOATC);
<*>{SIGN}?{DIGIT}+    DUP_AND_RET(valp, INTC);
<*>{HEX}              DUP_AND_RET(valp, INTC);
<*>{BIN}              DUP_AND_RET(valp, INTC);
<*>{OCT}              DUP_AND_RET(valp, INTC);

<*>{BIGINT} {
        valp->s = mem_sys_strdup(yytext);

        /* trailing 'L' */
        valp->s[strlen(valp->s) - 1] = '\0';

        /* no BIGINT native format yet */
        return STRINGC;
    }

<*>{STRINGCONSTANT} {
        valp->s = mem_sys_strdup(yytext);

        return STRINGC;
    }

<*>"<<"{STRINGCONSTANT} {
        macro_frame_t *frame;

        /* Save the string we want to mark the end of the heredoc and snip
           off newline and quote. */
        if (IMCC_INFO(interp)->frames->heredoc_rest)
            IMCC_fataly(interp, EXCEPTION_SYNTAX_ERROR, "nested heredoc not supported");
        IMCC_INFO(interp)->heredoc_end = mem_sys_strdup(yytext + 3);
        IMCC_INFO(interp)->heredoc_end[strlen(IMCC_INFO(interp)->heredoc_end) - 1] = 0;

        if (!strlen(IMCC_INFO(interp)->heredoc_end))
            IMCC_fataly(interp, EXCEPTION_SYNTAX_ERROR, "empty heredoc delimiter");

        frame                     = new_frame(interp);
        frame->s.next             = (parser_state_t *)IMCC_INFO(interp)->frames;
        IMCC_INFO(interp)->frames = frame;

        /* Start slurping up the heredoc. */
        IMCC_INFO(interp)->heredoc_content    = (char *)mem_sys_allocate(2);

        /* preserve delim */
        IMCC_INFO(interp)->heredoc_content[0] = yytext[2];

        /* eos */
        IMCC_INFO(interp)->heredoc_content[1] = 0;
        yy_push_state(heredoc1, yyscanner);
    }

<*>{UNICODE} {
        /* charset:"..." */
        valp->s = mem_sys_strdup(yytext);

        /* this is actually not unicode but a string with a charset */
        return USTRINGC;
    }

<emit,INITIAL>\$I[0-9]+ {
        if (valp) (valp)->s = yytext;
        if (IMCC_INFO(interp)->state->pasm_file)
                IMCC_fataly(interp, EXCEPTION_SYNTAX_ERROR,
                    "'%s' is not a valid register name in pasm mode", yytext);
        return IREG;
    }

<emit,INITIAL>\$N[0-9]+ {
        if (valp) (valp)->s = yytext;
        if (IMCC_INFO(interp)->state->pasm_file)
                IMCC_fataly(interp, EXCEPTION_SYNTAX_ERROR,
                    "'%s' is not a valid register name in pasm mode", yytext);
        return NREG;
    }

<emit,INITIAL>\$S[0-9]+ {
        if (valp) (valp)->s = yytext;
        if (IMCC_INFO(interp)->state->pasm_file)
                IMCC_fataly(interp, EXCEPTION_SYNTAX_ERROR,
                    "'%s' is not a valid register name in pasm mode", yytext);
        return SREG;
    }

<emit,INITIAL>\$P[0-9]+ {
        if (valp) (valp)->s = yytext;
        if (IMCC_INFO(interp)->state->pasm_file)
                IMCC_fataly(interp, EXCEPTION_SYNTAX_ERROR,
                    "'%s' is not a valid register name in pasm mode", yytext);
        return PREG;
    }

<emit,INITIAL>\$[a-zA-Z0-9]+ {
        IMCC_fataly(interp, EXCEPTION_SYNTAX_ERROR,
            "'%s' is not a valid register name", yytext);
    }

<emit,INITIAL>[ISNP]{DIGIT}{DIGIT}? {
        if (IMCC_INFO(interp)->state->pasm_file == 0)
            IMCC_fataly(interp, EXCEPTION_SYNTAX_ERROR,
            "'%s' is only a valid register name in PASM mode", yytext);

        if (valp)
            valp->s = mem_sys_strdup(yytext);

        return REG;
    }

<emit,INITIAL>{ID} {
        if (!IMCC_INFO(interp)->is_def) {
            SymReg *r = find_sym(interp, yytext);

            if (r && (r->type & (VTIDENTIFIER|VT_CONSTP))) {
                valp->sr = r;
                return VAR;
            }

            if (IMCC_INFO(interp)->cur_unit
            &&  IMCC_INFO(interp)->cur_unit->instructions
            && (r = IMCC_INFO(interp)->cur_unit->instructions->symregs[0])
            &&  r->pcc_sub)
            {
                if (((r->pcc_sub->pragma & P_METHOD)
                ||   (IMCC_INFO(interp)->cur_unit->is_vtable_method))
                &&   !strcmp(yytext, "self")) {
                    valp->sr = mk_ident(interp, "self", 'P');
                    IMCC_INFO(interp)->cur_unit->type |= IMC_HAS_SELF;
                    return VAR;
                }
            }
        }

        valp->s = mem_sys_strdup(yytext);
        return (!IMCC_INFO(interp)->is_def && is_op(interp, valp->s) ? PARROT_OP : IDENTIFIER);
    }


<emit,INITIAL>{WS}+ /* skip */;

<emit,cmt1,cmt2,cmt3,cmt4,cmt5,INITIAL>. {
        /* catch all except for state macro */
        return yytext[0];
    }

<emit><<EOF>> {
        BEGIN(INITIAL);

        if (IMCC_INFO(interp)->frames->s.pasm_file) {
            IMCC_INFO(interp)->frames->s.pasm_file = 2;
            return EOM;
        }

        return 0;
    }

<INITIAL><<EOF>> yyterminate();

<macro>".endm"         DUP_AND_RET(valp, ENDM);

<macro>{WS}*{EOL} {
        IMCC_INFO(interp)->line++;
        DUP_AND_RET(valp, '\n');
    }

<macro>"$"{ID}":"  return LABEL;

<macro>".label"{WS}+ {

        if (yylex(valp, yyscanner, interp) != LABEL)
                IMCC_fataly(interp, EXCEPTION_SYNTAX_ERROR, "LABEL expected");

        if (valp) {
            char *label;
            size_t len;
            YYCHOP();

            len = strlen(IMCC_INFO(interp)->cur_macro_name) + yyleng + 15;
            label = (char *)mem_sys_allocate(len);

            snprintf(label, len, "local__%s__%s__$:",
                IMCC_INFO(interp)->cur_macro_name, yytext+1);

            if (valp->s)
                mem_sys_free(valp->s);
            valp->s = label;
        }

        return LABEL;
    }

<macro>".$"{ID} {
        if (valp) {
            const size_t len = strlen(IMCC_INFO(interp)->cur_macro_name) + yyleng + 12;
            char * const label = (char *)mem_sys_allocate(len);

            snprintf(label, len, "local__%s__%s__$",
                IMCC_INFO(interp)->cur_macro_name, yytext+2);

            if (valp->s)
                mem_sys_free(valp->s);
            valp->s = label;
        }

        return IDENTIFIER;
    }

<macro>^{WS}+                       /* skip leading ws */;
<macro>{WS}+                        DUP_AND_RET(valp, ' ');
<macro>[SNIP]{DIGITS}               DUP_AND_RET(valp, REG);
<macro>"$"[SNIP]{DIGITS}            DUP_AND_RET(valp, REG);
<macro>{ID}                         DUP_AND_RET(valp, IDENTIFIER);
<macro>{DOT}{ID}                    DUP_AND_RET(valp, MACRO);
<macro>.                            DUP_AND_RET(valp, yytext[0]);
<macro><<EOF>>                      yyterminate();

%%

