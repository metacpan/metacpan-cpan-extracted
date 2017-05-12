#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <nanomsg/nn.h>
#include <nanomsg/pair.h>

#ifndef XS_INTERNAL
#  define XS_INTERNAL(name) static XSPROTO(name)
#endif

#ifndef mg_findext
#  define mg_findext(sv, type, vtbl) S_mg_findext(aTHX_ sv, type, vtbl)
static MAGIC *
S_mg_findext(pTHX_ SV *sv, int type, const MGVTBL *vtbl)
{
  MAGIC *mg;

  if (sv) {
    for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
      if (mg->mg_type == type && mg->mg_virtual == vtbl)
        return mg;
    }
  }

  return NULL;
}
#endif

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
  PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
  (PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#if PERL_VERSION_GE(5,14,0)
#  define SIZETf "%zd"
#  define SIZETfARG(s) s
#else
#  define SIZETf "%lu"
#  define SIZETfARG(s) (unsigned long)s
#endif

#ifndef dVAR
#  define dVAR dNOOP
#endif

#ifndef croak_xs_usage
#  define croak_xs_usage(a,b)    S_croak_xs_usage(aTHX_ a,b)
static void S_croak_xs_usage(pTHX_ const CV *const cv, const char *const params);
#endif

SV *errno_sv;
HV *message_stash, *message_freed_stash;

#define PERL_NN_SET_ERRNO STMT_START { \
  sv_setpv(errno_sv, nn_strerror(errno)); \
  SvIV_set(errno_sv, errno); \
  SvIOK_on(errno_sv); \
} STMT_END

typedef int perl_nn_int;
typedef int perl_nn_int_bool;
typedef void * perl_nn_messagebuf;

struct perl_nn_message {
  void *buf;
  size_t len;
};

static int
perl_nn_message_mg_dup (pTHX_ MAGIC *mg, CLONE_PARAMS *param)
{
  struct perl_nn_message *dst;
  struct perl_nn_message *src = (struct perl_nn_message *)mg->mg_ptr;

  PERL_UNUSED_ARG(param);

  Newx(dst, 1, struct perl_nn_message);
  dst->len = src->len;
  dst->buf = nn_allocmsg(src->len, 0); /* FIXME: alloc type */
  memcpy(dst->buf, src->buf, src->len);

  mg->mg_ptr = (char *)dst;

  return 0;
}

static int
perl_nn_message_mg_free (pTHX_ SV *sv, MAGIC *mg)
{
  struct perl_nn_message *msg = (struct perl_nn_message *)mg->mg_ptr;
  PERL_UNUSED_ARG(sv);
  if (msg->buf)
    nn_freemsg(msg->buf);
  return 0;
}

static MGVTBL perl_nn_message_vtbl = {
  NULL, /* get */
  NULL, /* set */
  NULL, /* len */
  NULL, /* clear */
  perl_nn_message_mg_free, /* free */
  NULL, /* copy */
  perl_nn_message_mg_dup, /* dup */
  NULL /* local */
};

static struct perl_nn_message *
perl_nn_message_mg_find (pTHX_ SV *sv)
{
  MAGIC *mg = mg_findext(sv, PERL_MAGIC_ext, &perl_nn_message_vtbl);
  return (struct perl_nn_message *)mg->mg_ptr;
}

AV *symbol_names;

XS_INTERNAL(XS_NanoMsg__Raw_nn_constant);
XS_INTERNAL(XS_NanoMsg__Raw_nn_constant)
{
  dVAR;
  dXSARGS;
  IV ix = XSANY.any_iv;
  dXSTARG;
  if (items != 0)
    croak_xs_usage(cv,  "");
  XSprePUSH;
  PUSHi((IV)ix);
  XSRETURN(1);
}

static struct perl_nn_message *
perl_nn_upgrade_to_message (pTHX_ SV *sv)
{
  MAGIC *mg;
  struct perl_nn_message *msg;
  SV *obj = newSV(0);

  /* There's no sane way to prepare an arbitrary SV to be a reference, so we'll
   * have to go out of our way a bit. Also, we're forced to free any PV, if
   * present, as PV and RV are stored in the same place within an SV. */
  if (SvROK(sv))
    SvREFCNT_dec(SvRV(sv));
  if (SvTYPE(sv) >= SVt_PV && SvPVX_const(sv) && SvLEN(sv)) {
    SvPV_free(sv);
    SvPV_set(sv, NULL);
    SvLEN_set(sv, 0);
  }

  SvUPGRADE(sv, SVt_RV);
  SvPOK_off(sv);
  SvRV_set(sv, obj);
  SvROK_on(sv);
  sv_upgrade(obj, SVt_PVMG);
  SvPOK_on(obj);
  SvCUR_set(obj, 0);
  SvLEN_set(obj, 0);
  sv_bless(sv, message_stash);
  SvREADONLY_on(obj);
  Newxz(msg, 1, struct perl_nn_message);
  mg = sv_magicext(obj, NULL, PERL_MAGIC_ext, &perl_nn_message_vtbl, (char *)msg, 0);
  mg->mg_flags |= MGf_DUP;
  return msg;
}

static struct perl_nn_message *
perl_nn_invalidate_message (pTHX_ SV *sv)
{
  MAGIC *mg, *prevmg, *moremg = NULL;
  struct perl_nn_message *msg = NULL;
  SV *obj = SvRV(sv);
  SvREADONLY_off(obj);
  SvPOK_off(obj);
  SvPVX(obj) = NULL;
  sv_bless(sv, message_freed_stash);

  for (prevmg = NULL, mg = SvMAGIC(obj); mg; prevmg = mg, mg = moremg) {
    moremg = mg->mg_moremagic;
    if (mg->mg_type == PERL_MAGIC_ext &&
        mg->mg_virtual == &perl_nn_message_vtbl) {
      if (prevmg)
        prevmg->mg_moremagic = moremg;
      else
        SvMAGIC_set(obj, moremg);

      mg->mg_moremagic = NULL;
      msg = (struct perl_nn_message *)mg->mg_ptr;
      Safefree(mg);

      mg = prevmg;
    }
  }

  assert(msg);
  return msg;
}

static bool
perl_nn_is_message (pTHX_ SV *sv)
{
  return sv_isobject(sv) && SvSTASH(SvRV(sv)) == message_stash;
}

MODULE=NanoMsg::Raw  PACKAGE=NanoMsg::Raw

PROTOTYPES: DISABLE

perl_nn_int
nn_socket (domain, protocol)
    int domain
    int protocol

perl_nn_int_bool
nn_close (s)
    int s

perl_nn_int_bool
nn_setsockopt (s, level, option, optval)
    int s
    int level
    int option
    SV *optval
  PREINIT:
    const void *c_optval;
    size_t c_optvallen;
    int a_int; /* needed at this scope so we can pass a pointer to it in the
                  generated CODE section */
  INIT:
    if (SvPOKp(optval)) {
      c_optval = SvPV_const(optval, c_optvallen);
    }
    else {
      a_int = (int)SvIV(optval);
      c_optval = &a_int;
      c_optvallen = sizeof(int);
    }
  C_ARGS:
    s, level, option, c_optval, c_optvallen

SV *
nn_getsockopt (s, level, option)
    int s
    int level
    int option
  PREINIT:
    size_t optvallen = 256; /* maxlen of the return value without trailing \0 */
    int ret;
  INIT:
    RETVAL = newSV(256 + 1);
    (void)SvPOK_only(RETVAL);
  CODE:
    ret = nn_getsockopt(s, level, option, SvPVX(RETVAL), &optvallen);
  POSTCALL:
    if (ret < 0) {
      PERL_NN_SET_ERRNO;
      XSRETURN_UNDEF;
    }
    SvCUR_set(RETVAL, optvallen);
    *SvEND(RETVAL) = '\0';
  OUTPUT:
    RETVAL

perl_nn_int
nn_bind (s, addr)
    int s
    const char *addr

perl_nn_int
nn_connect (s, addr)
    int s
    const char *addr

perl_nn_int_bool
nn_shutdown (s, how)
    int s
    int how

perl_nn_int
nn_send (s, buf, flags = 0)
    int s
    SV *buf
    int flags
  PREINIT:
    void *c_buf;
    size_t len;
  INIT:
    if (perl_nn_is_message(aTHX_ buf)) {
      c_buf = &perl_nn_message_mg_find(aTHX_ SvRV(buf))->buf;
      len = NN_MSG;
    }
    else {
      c_buf = SvPV(buf, len);
    }
  C_ARGS:
    s, c_buf, len, flags
  POSTCALL:
    if (len == NN_MSG)
      perl_nn_invalidate_message(aTHX_ buf);

int
nn_recv (s, buf, len = NN_MSG, flags = 0)
    int s
    SV *buf
    size_t len
    int flags
  PREINIT:
    void *c_buf;
    struct perl_nn_message *msg;
  INIT:
    if (len == NN_MSG) {
      msg = perl_nn_upgrade_to_message(aTHX_ buf);
      c_buf = &msg->buf;
    }
    else {
      if (!SvOK(buf))
        sv_setpvs(buf, "");
      SvPV_force_nolen(buf);
      c_buf = SvGROW(buf, len);
    }
  C_ARGS:
    s, c_buf, len, flags
  POSTCALL:
    if (RETVAL < 0) {
      PERL_NN_SET_ERRNO;
      XSRETURN_UNDEF;
    }
    if (len == NN_MSG) {
      SV *obj = SvRV(buf);
      msg->len = RETVAL;
      SvPVX(obj) = msg->buf;
      SvCUR_set(obj, RETVAL);
      SvPOK_on(obj);
    }
    else {
      SvCUR_set(buf, (int)len < RETVAL ? (int)len : RETVAL);
      (void)SvPOK_only(buf);
    }

# TODO: cmsg

perl_nn_int
nn_sendmsg (s, flags, ...)
    int s
    int flags
  PREINIT:
    struct nn_msghdr hdr;
    struct nn_iovec *iov;
    int iovlen, i;
  INIT:
    iovlen = items - 2;
    Newx(iov, iovlen, struct nn_iovec);
    for (i = 0; i < iovlen; i++) {
      SV *sv = ST(i + 2);
      if (perl_nn_is_message(aTHX_ sv)) {
        struct perl_nn_message *msg = perl_nn_message_mg_find(aTHX_ SvRV(sv));
        iov[i].iov_base = &msg->buf;
        iov[i].iov_len = NN_MSG;
      }
      else {
        iov[i].iov_base = SvPV(sv, iov[i].iov_len);
      }
    }
    memset(&hdr, 0, sizeof(hdr));
    hdr.msg_iov = iov;
    hdr.msg_iovlen = iovlen;
  C_ARGS:
    s, &hdr, flags
  POSTCALL:
    for (i = 0; i < iovlen; i++)
      if (iov[i].iov_len == NN_MSG)
        perl_nn_invalidate_message(aTHX_ ST(i + 2));
  CLEANUP:
    Safefree(iov);

int
nn_recvmsg (s, flags, ...)
    int s
    int flags
  PREINIT:
    struct nn_msghdr hdr;
    struct nn_iovec *iov;
    int iovlen, i;
    size_t nbytes;
    struct perl_nn_message *msg;
  INIT:
    iovlen = (items - 2) / 2;
    Newx(iov, iovlen, struct nn_iovec);
    for (i = 0; i < iovlen; i++) {
      SV *svbuf = ST(i*2 + 2);
      UV len = SvUV(ST(i*2 + 3));
      iov[i].iov_len = len;
      if (len == NN_MSG) {
        msg = perl_nn_upgrade_to_message(aTHX_ svbuf);
        iov[i].iov_base = &msg->buf;
      }
      else {
        if (!SvOK(svbuf))
          sv_setpvs(svbuf, "");
        SvPV_force_nolen(svbuf);
        SvGROW(svbuf, len);
        iov[i].iov_base = SvPVX(svbuf);
      }
    }
    memset (&hdr, 0, sizeof (hdr));
    hdr.msg_iov = iov;
    hdr.msg_iovlen = iovlen;
  C_ARGS:
    s, &hdr, flags
  POSTCALL:
    if (RETVAL < 0) {
      PERL_NN_SET_ERRNO;
      XSRETURN_UNDEF;
    }
    nbytes = RETVAL;
    if (iovlen == 1 && iov[0].iov_len == NN_MSG) {
      SV *obj = SvRV(ST(2));
      msg->len = RETVAL;
      SvPVX(obj) = msg->buf;
      SvCUR_set(obj, RETVAL);
      SvPOK_on(obj);
    }
    else {
      for (i = 0; i < iovlen; i++) {
        size_t max = iov[i].iov_len < nbytes ? iov[i].iov_len : nbytes;
        SvCUR_set(ST(i*2 + 2), max);
        if (nbytes > 0)
          nbytes -= max;
      }
    }
  CLEANUP:
    Safefree(iov);

perl_nn_messagebuf
nn_allocmsg (size, type)
    size_t size
    int type

const char *
nn_strerror (errnum)
    int errnum

SV *
nn_errno ()
  CODE:
    RETVAL = SvREFCNT_inc(errno_sv);
  OUTPUT:
    RETVAL

perl_nn_int_bool
nn_device (s1, s2)
    int s1
    int s2
  INIT:
    if (ST(0) == &PL_sv_undef)
      s1 = -1;
    if (ST(1) == &PL_sv_undef)
      s2 = -1;

void
nn_term ()

void
_symbols ()
  PREINIT:
    int i;
  PPCODE:
    for (i = 0; i <= av_len(symbol_names); i++)
      mXPUSHs(SvREFCNT_inc(*av_fetch(symbol_names, i, 0)));

BOOT:
  symbol_names = newAV();
  errno_sv = newSV(0);
  sv_upgrade(errno_sv, SVt_PVIV);
  message_stash = gv_stashpvs("NanoMsg::Raw::Message", 0);
  message_freed_stash = gv_stashpvs("NanoMsg::Raw::Message::Freed", GV_ADD);
  {
    CV *cv;
    const char *sym;
    int val, i = 0;
    char name[4096] = "NanoMsg::Raw::";
    size_t prefixlen = sizeof("NanoMsg::Raw::") - 1;
    while ((sym = nn_symbol(i++, &val)) != NULL) {
      size_t symlen = strlen(sym);
      if (strncmp(sym, "EFAULT", sizeof("EFAULT")-1) == 0)
        continue;
      av_push(symbol_names, newSVpv(sym, symlen));
      memcpy(name + prefixlen, sym, symlen+1);
      cv = newXS(name, XS_NanoMsg__Raw_nn_constant, file);
      XSANY.any_iv = val;
    }

    memcpy(name + prefixlen, "NN_MSG", sizeof("NN_MSG"));
    cv = newXS(name, XS_NanoMsg__Raw_nn_constant, file);
    XSANY.any_iv = NN_MSG;
  }

MODULE=NanoMsg::Raw  PACKAGE=NanoMsg::Raw::Message

void
copy (sv, src)
    SV *sv
    SV *src
  PREINIT:
    const void *buf;
    STRLEN len;
    SV *obj;
    struct perl_nn_message *msg;
  INIT:
    obj = SvRV(sv);
    buf = SvPV(src, len);
    msg = perl_nn_message_mg_find(aTHX_ obj);
    if (len > msg->len)
      croak("Trying to copy "SIZETf" bytes into a message buffer of size "SIZETf,
            SIZETfARG(len), SIZETfARG(msg->len));
  CODE:
    memcpy(msg->buf, buf, len);
    SvPVX(obj) = msg->buf;
    SvCUR_set(obj, len);
    SvPOK_on(obj);
