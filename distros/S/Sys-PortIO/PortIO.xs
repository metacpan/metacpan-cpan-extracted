/* ======================================================================
 * PortIO.xs - XS code which exposes direct port I/O calls to Perl
 * Andrew Ho (andrew@zeuscat.com)
 *
 * See PortIO.pm for API documentation.
 *
 * Copyright (C) 2005 by Andrew Ho.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself, either Perl version 5.6.0 or,
 * at your option, any later version of Perl 5 you may have available.
 *
 * $Id: PortIO.xs,v 1.1 2005/02/26 05:19:30 andrew Exp $
 * ====================================================================== */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* abstract architecture dependent port I/O calls using macros */
#if defined __OpenBSD__ || defined __NetBSD__

#include <machine/sysarch.h>
#include <machine/pio.h>

static struct i386_iopl_args iopls;

#define PORT_OPEN(p)    (iopls.iopl = 3, sysarch(I386_IOPL, (char *)&iopls))
#define READ_BYTE(p)    (inb(p))
#define WRITE_BYTE(p,v) (outb((p), (v)))
#define PORT_CLOSE(p)   (iopls.iopl = 0, sysarch(I386_IOPL, (char *)&iopls))

#elif defined __FreeBSD__

#include <machine/cpufunc.h>
#include <fcntl.h>

static int iofd = -1;

#define PORT_OPEN(x)    (iofd = open("/dev/io", O_RDONLY))
#define READ_BYTE(p)    (inb(p))
#define WRITE_BYTE(p,v) (outb((p), (v)))
#define PORT_CLOSE(x)   (close(iofd))

#else

#include <sys/io.h>

#define PORT_OPEN(p)    (ioperm((p), 3, 1))
#define READ_BYTE(p)    (inb(p))
#define WRITE_BYTE(p,v) (outb((v), (p)))
#define PORT_CLOSE(p)   (ioperm((p), 3, 0))

#endif


/* ---------------------------------------------------------------------- */

MODULE = Sys::PortIO    PACKAGE = Sys::PortIO    PREFIX = portio_

int
portio_port_open(p)
    int p;
  CODE:
    int retval = PORT_OPEN(p);
    if(retval != 0) {
        XSRETURN_UNDEF;
    } else {
        RETVAL = 1;
    }
  OUTPUT:
    RETVAL

int
portio_read_byte(p)
    int p;
  CODE:
    int retval = READ_BYTE(p);
    if(retval == 0xff) {
        XSRETURN_UNDEF;
    } else {
        RETVAL = retval;
    }
  OUTPUT:
    RETVAL

void
portio_write_byte(p, v)
    int p;
    int v;
  CODE:
    WRITE_BYTE(p, v);

int
portio_port_close(p)
    int p;
  CODE:
    int retval = PORT_CLOSE(p);
    if(retval != 0) {
        XSRETURN_UNDEF;
    } else {
        RETVAL = 1;
    }
  OUTPUT:
    RETVAL


# ======================================================================
