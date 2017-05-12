#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "maplec.h"
#include "ppport.h"
#include <stdio.h>

static MKernelVector kv;
static char errinfo[2048];
static char warninfo[2048];
static char result[100000];
static int error = 0;

/* callback used for directing result output */
static void M_DECL textCallBack( void *data, int tag, char *output ) {
    if (tag == MAPLE_TEXT_STATUS) return;
    if (tag == MAPLE_TEXT_WARNING) {
        strncpy(warninfo, output, sizeof(warninfo));
        warninfo[sizeof(warninfo)-1] = '\0';
    } else {
        strncpy(result, output, sizeof(result));
        result[sizeof(result)-1] = '\0';
    }
}

void M_DECL errorCallBack( void *data, M_INT offset, char *msg ) {
    error = 1;
    strncpy(errinfo, msg, sizeof(errinfo));
    errinfo[sizeof(errinfo)-1] = '\0';
}

int maple_start() {
    char err[2048];
    MCallBackVectorDesc cb = {
                textCallBack,
                errorCallBack,
                0,   /* statusCallBack not used */
                0,   /* readLineCallBack not used */
                0,   /* redirectCallBack not used */
                0,   /* streamCallBack not used */
                0,   /* query interrupt */
                0    /* callBackCallBack not used */
                };
    errinfo[0] = '\0';
    warninfo[0] = '\0';
    result[0] = '\0';
    if( (kv=StartMaple(0,NULL,&cb,NULL,NULL,err)) == NULL )
        return 0;
    else
        return 1;
}

void maple_eval(char* expr) {
    error = 0;
    EvalMapleStatement(kv,expr);
}

char* maple_error() {
    return errinfo;
}

char* maple_warning() {
    return warninfo;
}

char* maple_result() {
    return result;
}

int maple_success() {
    return !error;
}


MODULE = PerlMaple  PACKAGE = PerlMaple

PROTOTYPES: DISABLE


int
maple_start ()

void
maple_eval (expr)
    char *  expr
    PREINIT:
    I32* temp;
    PPCODE:
    temp = PL_markstack_ptr++;
    warninfo[0] = '\0';
    result[0] = '\0';
    maple_eval(expr);
    if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
      PL_markstack_ptr = temp;
      XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
    return; /* assume stack size is correct */

char *
maple_error ()

char *
maple_warning ()

char *
maple_result ()

int
maple_success ()

