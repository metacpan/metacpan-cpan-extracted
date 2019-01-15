/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2011 -- leonerd@leonerd.org.uk
 */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef G_METHOD_NAMED
#define G_METHOD_NAMED G_METHOD
#endif

#include <string.h>
#define streq(a,b) (strcmp((a),(b)) == 0)

enum {
  CTX_GET_CB,
  CTX_SET_CB,
  CTX_OBJ,
};

typedef SV *sentinel_ctx;

static int magic_get(pTHX_ SV *sv, MAGIC *mg)
{
  dSP;
  sentinel_ctx *ctx = (sentinel_ctx*)AvARRAY(mg->mg_obj);

  if(ctx[CTX_GET_CB]) {
    int count;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    if(ctx[CTX_OBJ]) {
      EXTEND(SP, 1);
      PUSHs(ctx[CTX_OBJ]);
    }
    PUTBACK;

    if(ctx[CTX_OBJ] && SvPOK(ctx[CTX_GET_CB]))
      // Calling method by name
      count = call_sv(ctx[CTX_GET_CB], G_SCALAR | G_METHOD_NAMED);
    else
      count = call_sv(ctx[CTX_GET_CB], G_SCALAR);
    assert(count == 1);

    SPAGAIN;
    sv_setsv_nomg(sv, POPs);

    PUTBACK;
    FREETMPS;
    LEAVE;
  }

  return 1;
}

static int magic_set(pTHX_ SV *sv, MAGIC *mg)
{
  dSP;
  sentinel_ctx *ctx = (sentinel_ctx*)AvARRAY(mg->mg_obj);

  if(ctx[CTX_SET_CB]) {
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    if(ctx[CTX_OBJ]) {
      EXTEND(SP, 2);
      PUSHs(ctx[CTX_OBJ]);
    }
    else {
      EXTEND(SP, 1);
    }
    PUSHs(sv);
    PUTBACK;

    if(ctx[CTX_OBJ] && SvPOK(ctx[CTX_SET_CB]))
      // Calling method by name
      call_sv(ctx[CTX_SET_CB], G_VOID | G_METHOD_NAMED);
    else
      call_sv(ctx[CTX_SET_CB], G_VOID);

    FREETMPS;
    LEAVE;
  }

  return 1;
}

static MGVTBL vtbl = {
  &magic_get,
  &magic_set,
};

MODULE = Sentinel    PACKAGE = Sentinel

SV *
sentinel(...)
  PREINIT:
    int i;
    SV *value = NULL;
    SV *get_cb = NULL;
    SV *set_cb = NULL;
    SV *obj = NULL;
    SV *retval;

  PPCODE:
    /* Parse name => value argument pairs */
    for(i = 0; i < items; i += 2) {
      char *argname  = SvPV_nolen(ST(i));
      SV   *argvalue = ST(i+1);

      if(streq(argname, "value")) {
        value = argvalue;
      }
      else if(streq(argname, "get")) {
        get_cb = argvalue;
      }
      else if(streq(argname, "set")) {
        set_cb = argvalue;
      }
      else if(streq(argname, "obj")) {
        obj = argvalue;
      }
      else {
        fprintf(stderr, "Argument %s at %p\n", argname, argvalue);
      }
    }

    retval = sv_newmortal();
/**
 * Perl 5.14 allows any TEMP scalar to be returned in LVALUE context provided
 * it is magical. Perl versions before this only accept magic for being a tied
 * array or hash element. Rather than try to hack this magic type, we'll just
 * pretend the SV isn't a TEMP
 * The following workaround is known to work on Perl 5.12.4.
 */
#if (PERL_REVISION == 5) && (PERL_VERSION < 14)
    SvFLAGS(retval) &= ~SVs_TEMP;
#endif

    if(value)
      sv_setsv(retval, value);

    if(get_cb || set_cb) {
      sentinel_ctx *ctx;
      AV* payload = newAV();
      av_extend(payload, 2);
      AvFILLp(payload) = 2;

      ctx = (sentinel_ctx*)AvARRAY(payload);

      ctx[CTX_GET_CB] = get_cb ? newSVsv(get_cb) : NULL;
      ctx[CTX_SET_CB] = set_cb ? newSVsv(set_cb) : NULL;
      ctx[CTX_OBJ] = obj ? newSVsv(obj) : NULL;

      sv_magicext(retval, (SV*)payload, PERL_MAGIC_ext, &vtbl, NULL, 0);
      SvREFCNT_dec(payload);
    }

    if (!items)
      EXTEND(SP, 1);
    PUSHs(retval);
    XSRETURN(1);

BOOT:
  CvLVALUE_on(get_cv("Sentinel::sentinel", 0));
