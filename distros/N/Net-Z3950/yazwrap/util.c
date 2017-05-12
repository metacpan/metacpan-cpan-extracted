/* $Header: /home/cvsroot/NetZ3950/yazwrap/util.c,v 1.3 2003/01/21 16:46:41 mike Exp $ */

/*
 * yazwrap/util.c -- wrapper functions for Yaz's client API.
 *
 * This file provides utility functions for the wrapper library.
 */

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include "ywpriv.h"


void fatal(char *fmt, ...)
{
    va_list ap;

    fprintf(stderr, "FATAL (yazwrap): ");
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fprintf(stderr, "\n");
    abort();
}
