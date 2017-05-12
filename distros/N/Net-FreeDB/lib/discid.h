/* Modified by David Shultz for Net::FreeDB on 08/01/2001 */

/* Code to get discid for a cddb query.

  *** Linux Version ***

  $Id: discid.h,v 1.1 2001/08/08 18:22:12 arnuga Exp $

  Copyright (c) 1998-2000 Jeremy D. Zawodny <Jeremy@Zawodny.com>

  This software is covered by the GPL.

  Is is based on code found in:

    To: code-review@azure.humbug.org.au 
    Subject: CDDB database reader 
    From: Byron Ellacott <rodent@route-qn.uqnga.org.au> 
    Date: Fri, 5 Jun 1998 17:32:40 +1000 

*/

/* Stripped net code, 'cause I only care about the discid */

#include <stdio.h>
#include <stdlib.h>

#ifdef __linux__
#include <fcntl.h>
#include <stdarg.h>
#include <errno.h>
#include <netdb.h>
#include <unistd.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <linux/cdrom.h>
#include "linux.h"
#endif //__linux__

#if defined(__FreeBSD__) || defined(__FreeBSD_kernel__)
#include <sys/cdio.h>
#include "freebsd.h"
#endif // __FreeBSD__ || __FreeBSD_kernel__

#ifdef WIN32
#include "win32.h"
#endif //WIN32
