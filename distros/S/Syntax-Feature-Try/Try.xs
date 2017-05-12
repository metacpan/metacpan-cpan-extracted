#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "try-catch-hints.h"

#include "try-catch-constants.c"
#include "try-catch-stack.c"
#include "try-catch-parser.c"
#include "try-catch-op.c"

/* setup keyword plugin */
static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static int my_keyword_plugin(pTHX_ char *keyword_ptr, STRLEN keyword_len,
                                OP **op_ptr)
{
    if (is_syntax_enabled()) {
        if ((keyword_len == 3) && strnEQ(keyword_ptr, "try", 3)) {
            *op_ptr = parse_try_statement();
            return KEYWORD_PLUGIN_STMT;
        }
        if ((keyword_len == 5) && strnEQ(keyword_ptr, "catch", 5)) {
            syntax_error("try/catch/finally sequence");
        }
        if ((keyword_len == 7) && strnEQ(keyword_ptr, "finally", 7)) {
            syntax_error("finally without try block");
        }
    }
    return next_keyword_plugin(aTHX_ keyword_ptr, keyword_len, op_ptr);
}

MODULE = Syntax::Feature::Try  PACKAGE = Syntax::Feature::Try

PROTOTYPES: DISABLED

BOOT:
{
    setup_constants();

    next_keyword_plugin = PL_keyword_plugin;
    PL_keyword_plugin = my_keyword_plugin;
}

SV*
run_block(HV* stm_handler, SV* coderef, int in_eval=0, SV* arg1=NULL)
    CODE:
        dSP;
        PERL_CONTEXT *upper_sub_cx;
        I32 gimme, ret_count, i;

        upper_sub_cx = get_sub_context(1);
        gimme = upper_sub_cx ? upper_sub_cx->blk_gimme : 0;

        ENTER;
        SAVETMPS;

        // Call arguments: (optional) arg1
        PUSHMARK(SP);
        if (SvTRUE(arg1)) {
            XPUSHs(arg1);
        }
        PUTBACK;
        ret_count = call_sv(coderef, gimme | (in_eval ? G_EVAL : 0));
        RETVAL = newSVsv(ERRSV);

        SPAGAIN;
        // TODO extract to function
        // if return called inside block:
        if (!SvTRUE(ERRSV) && !SvTRUE(get_sv("is_end_of_block", 0))) {
            AV* ret_av = newAV();
            av_extend(ret_av, ret_count-1);
            for (i=ret_count-1; i >= 0; i--) {
                SV *item = (SV*)POPs;
                if (!av_store(ret_av, i, SvREFCNT_inc(item))) {
                    SvREFCNT_dec(item);
                    croak(MAIN_PKG " internal error - push return values");
                }
            }
            hv_stores(stm_handler, "return", newRV_noinc((SV*)ret_av));
        }
        PUTBACK;

        FREETMPS;
        LEAVE;
    OUTPUT:
        RETVAL
