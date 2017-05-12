/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2007 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/systeminfo.h>

MODULE = Solaris::SysInfo       PACKAGE = Solaris::SysInfo

SV *
sysinfo(command)
    int command

  CODE:
    long ret;
    char buffer[128];

    // printf("Making sysinfo() call to %d\n", command);

    ret = sysinfo(command, buffer, sizeof buffer);
    if(ret == -1) {
      XSRETURN_UNDEF;
    }

    if(ret <= sizeof buffer) {
      // printf("That succeeded entirely\n" );

      /* ret includes space for terminating null but newSVpvn() will +1 to it */
      RETVAL = newSVpv(buffer, ret-1);
    }
    else {
      // printf("That succeeded so far; need a buffer of %d bytes\n", ret);

      /* ret includes space for terminating null but newSVpvn() will +1 to it */
      RETVAL = newSVpvn("", ret-1);
      SvCUR_set(RETVAL, ret);

      ret = sysinfo(command, SvPV_nolen(RETVAL), ret);
      if(ret == -1) {
        XSRETURN_UNDEF;
      }

      // printf("That worked; sysinfo(%d) = %s\n", command, SvPV_nolen(RETVAL));
    }

  OUTPUT:
    RETVAL
