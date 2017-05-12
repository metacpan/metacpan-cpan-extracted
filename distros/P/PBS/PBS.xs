#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <pbs_ifl.h>

#include "const-c.inc"

static char *errstr;
extern int pbs_errno;

MODULE = PBS		PACKAGE = PBS		

INCLUDE: const-xs.inc

char *
pbs_default(CLASS)
    char *CLASS
CODE:
    RETVAL = pbs_default();
    if (RETVAL == NULL) {
        XSRETURN_UNDEF;
    } 
OUTPUT:
    RETVAL

char *
get_error(CLASS)
    char *CLASS
CODE:
    RETVAL = errstr;
OUTPUT:
    RETVAL

int 
_pbs_connect(CLASS, server)
    char *CLASS
    char *server
CODE:
    RETVAL = pbs_connect(server);
OUTPUT:
    RETVAL
       
int 
_pbs_disconnect(CLASS, conn)
    char *CLASS
    int  conn
CODE:
    RETVAL = pbs_disconnect(conn);
OUTPUT:
    RETVAL
       
SV*
_pbs_statnode(CLASS, conn, id)
    char         *CLASS
    int          conn
    char         *id
PREINIT:
    struct batch_status *p;
CODE:
    p = pbs_statnode(conn, id, NULL, NULL);
    if (p == NULL) {
        if (pbs_errno) {
            errstr = pbs_geterrmsg(conn);
        } else {
            errstr = "An Error Occurred";
        }
        XSRETURN_UNDEF;
    } else {
        RETVAL = newSV(0);
        RETVAL = newRV_noinc(RETVAL);
        RETVAL = sv_setref_pv(RETVAL, "PBS::Status", (void *)p);
    }
OUTPUT:
    RETVAL

SV*
_pbs_statque(CLASS, conn, id)
    char         *CLASS
    int          conn
    char         *id
PREINIT:
    struct batch_status *p;
CODE:
    p = pbs_statque(conn, id, NULL, NULL);
    if (p == NULL) {
        if (pbs_errno) {
            errstr = pbs_geterrmsg(conn);
        } else {
            errstr = "An Error Occurred";
        }
        XSRETURN_UNDEF;
    } else {
        RETVAL = newSV(0);
        RETVAL = newRV_noinc(RETVAL);
        RETVAL = sv_setref_pv(RETVAL, "PBS::Status", (void *)p);
    }
OUTPUT:
    RETVAL

SV*
_pbs_statjob(CLASS, conn, id)
    char         *CLASS
    int          conn
    char         *id
PREINIT:
    struct batch_status *p;
CODE:
    p = pbs_statjob(conn, id, NULL, NULL);
    if (p == NULL) {
        if (pbs_errno) {
            errstr = pbs_geterrmsg(conn);
        } else {
            errstr = "An Error Occurred";
        }
        XSRETURN_UNDEF;
    } else {
        RETVAL = newSV(0);
        RETVAL = newRV_noinc(RETVAL);
        RETVAL = sv_setref_pv(RETVAL, "PBS::Status", (void *)p);
    }
OUTPUT:
    RETVAL

SV*
_pbs_statserver(CLASS, conn)
    char         *CLASS
    int          conn
PREINIT:
    struct batch_status *p;
CODE:
    p = pbs_statserver(conn, NULL, NULL);
    if (p == NULL) {
        if (pbs_errno) {
            errstr = pbs_geterrmsg(conn);
        } else {
            errstr = "An Error Occurred";
        }
        XSRETURN_UNDEF;
    } else {
        RETVAL = newSV(0);
        RETVAL = newRV_noinc(RETVAL);
        RETVAL = sv_setref_pv(RETVAL, "PBS::Status", (void *)p);
    }
OUTPUT:
    RETVAL

