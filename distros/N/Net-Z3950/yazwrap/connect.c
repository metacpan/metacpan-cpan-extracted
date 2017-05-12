/* $Header: /home/cvsroot/NetZ3950/yazwrap/connect.c,v 1.5 2005/01/04 20:33:25 mike Exp $ */

/*
 * yazwrap/connect.c -- wrapper functions for Yaz's client API.
 *
 * Provide a simple Perl-level interface to Yaz's COMSTACK API.  We
 * need to use this because of its mystical ability to read only whole
 * APDUs off the network stream.
 */

#include <yaz/tcpip.h>
#include "ywpriv.h"


/*
 * We're setting up the connection in non-blocking mode, which is what
 * we want.  However, this means that the connect() (as well as
 * subsequent read()s) will be non-blocking, so that we'll need to
 * catch and service the "connection complete" callback in "receive.c"
 */
COMSTACK yaz_connect(char *addr)
{
    COMSTACK conn;
    void *inaddr;

    /* Second argument is `blocking', false => no immediate errors */
    if ((conn = cs_create_host(addr, 0, &inaddr)) == 0) {
	/* mostly likely `errno' will be ENOMEM or something useful */
        return 0;
    }

    switch (cs_connect(conn, inaddr)) {
    case -1:			/* can't connect */
	/* I think this never happens due to blocking=0 */
/*printf("cs_connect() failed\n");*/
        cs_close(conn);
        return 0;
    case 0:			/* success */
	/* I think this never happens due to blocking=0 */
/*printf("cs_connect() succeeded\n");*/
        break;
    case 1:			/* non-blocking -- "not yet" */
/*printf("cs_connect() not yet\n");*/
	break;
    }

    return conn;
}


/* Need a Real Function for Perl to call, as cs_fileno() is a macro */
int yaz_socket(COMSTACK cs)
{
    return cs_fileno(cs);
}

/* just a wrapper for now, but who knows - perhaps it may do more later */

int yaz_close(COMSTACK cs)
{
    return cs_close(cs);
}
