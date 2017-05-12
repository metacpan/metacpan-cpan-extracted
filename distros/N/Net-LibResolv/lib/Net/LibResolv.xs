/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2011 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/nameser.h>
#include <resolv.h>

static void setup_constants(void)
{
  HV *stash;
  AV *export;

  stash = gv_stashpvn("Net::LibResolv", 14, TRUE);
  export = get_av("Net::LibResolv::EXPORT", TRUE);

#define DO_CONSTANT(c) \
  newCONSTSUB(stash, #c, newSViv(c)); \
  av_push(export, newSVpv(#c, 0));

  DO_CONSTANT(HOST_NOT_FOUND)
  DO_CONSTANT(NO_ADDRESS)
  DO_CONSTANT(NO_DATA)
  DO_CONSTANT(NO_RECOVERY)
  DO_CONSTANT(TRY_AGAIN)
}

static void set_h_errno(void)
{
  SV *h_errno_sv = get_sv("Net::LibResolv::h_errno", GV_ADD);

  sv_setiv(h_errno_sv, h_errno);
  sv_setpv(h_errno_sv, hstrerror(h_errno));

  SvIOK_on(h_errno_sv);
  SvPOK_on(h_errno_sv);
}

MODULE = Net::LibResolv      PACKAGE = Net::LibResolv

BOOT:
  setup_constants();

SV *
res_query(dname, class, type)
  char *dname
  int   class
  int   type
  PREINIT:
    unsigned char answer[512];
    int len;
  CODE:
    len = res_query(dname, class, type, answer, sizeof answer);
    if(len == -1) {
      set_h_errno();
      XSRETURN_UNDEF;
    }
    RETVAL = newSVpvn(answer, len);
  OUTPUT:
    RETVAL

SV *
res_search(dname, class, type)
  char *dname
  int   class
  int   type
  PREINIT:
    unsigned char answer[512];
    int len;
  CODE:
    len = res_search(dname, class, type, answer, sizeof answer);
    if(len == -1) {
      set_h_errno();
      XSRETURN_UNDEF;
    }
    RETVAL = newSVpvn(answer, len);
  OUTPUT:
    RETVAL
