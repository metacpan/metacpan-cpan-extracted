/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2010 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/socket.h>
#include <linux/netlink.h>

static void setup_constants(void)
{
  HV *stash;
  AV *export;

  stash = gv_stashpvn("Socket::Netlink", 15, TRUE);
  export = get_av("Socket::Netlink::EXPORT", TRUE);

#define DO_CONSTANT(c) \
  newCONSTSUB(stash, #c, newSViv(c)); \
  av_push(export, newSVpv(#c, 0));


  DO_CONSTANT(PF_NETLINK)
  DO_CONSTANT(AF_NETLINK)

  DO_CONSTANT(NLMSG_NOOP)
  DO_CONSTANT(NLMSG_ERROR)
  DO_CONSTANT(NLMSG_DONE)

  DO_CONSTANT(NLM_F_REQUEST)
  DO_CONSTANT(NLM_F_MULTI)
  DO_CONSTANT(NLM_F_ACK)
  DO_CONSTANT(NLM_F_ECHO)

  DO_CONSTANT(NLM_F_ROOT)
  DO_CONSTANT(NLM_F_MATCH)
  DO_CONSTANT(NLM_F_ATOMIC)
  DO_CONSTANT(NLM_F_DUMP)

  DO_CONSTANT(NLM_F_REPLACE)
  DO_CONSTANT(NLM_F_EXCL)
  DO_CONSTANT(NLM_F_CREATE)
  DO_CONSTANT(NLM_F_APPEND)
}

MODULE = Socket::Netlink      PACKAGE = Socket::Netlink

BOOT:
  setup_constants();

SV*
pack_sockaddr_nl(pid, groups)
    unsigned long pid
    unsigned long groups

  PREINIT:
    struct sockaddr_nl snl;

  CODE:
    Zero(&snl, sizeof snl, char);

    snl.nl_family = AF_NETLINK;
    snl.nl_pid    = pid;
    snl.nl_groups = groups;
    RETVAL = newSVpvn((char*)&snl, sizeof snl);
  OUTPUT:
    RETVAL

void
unpack_sockaddr_nl(addr)
    SV *addr

  PREINIT:
    struct sockaddr_nl snl;

  PPCODE:
    if(SvCUR(addr) != sizeof snl)
      croak("Expected %d byte address", sizeof snl);

    Copy(SvPVbyte_nolen(addr), &snl, sizeof snl, char);

    if(snl.nl_family != AF_NETLINK)
      croak("Expected AF_NETLINK");

    EXTEND(SP, 2);
    mPUSHi(snl.nl_pid);
    mPUSHi(snl.nl_groups);

SV*
pack_nlmsghdr(type, flags, seq, pid, body)
    unsigned short type
    unsigned short flags
    unsigned long  seq
    unsigned long  pid
    SV            *body

  PREINIT:
    struct nlmsghdr nlmsghdr;
    STRLEN          bodylen;

  CODE:
    if(!SvPOK(body))
      croak("Expected a string body");

    nlmsghdr.nlmsg_type  = type;
    nlmsghdr.nlmsg_flags = flags;
    nlmsghdr.nlmsg_seq   = seq;
    nlmsghdr.nlmsg_pid   = pid;

    bodylen = SvCUR(body);

    nlmsghdr.nlmsg_len = NLMSG_LENGTH(bodylen);

    RETVAL = newSV(nlmsghdr.nlmsg_len);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, nlmsghdr.nlmsg_len);

    Zero(SvPVbyte_nolen(RETVAL), nlmsghdr.nlmsg_len, char);

    Copy(&nlmsghdr, SvPVbyte_nolen(RETVAL), sizeof(nlmsghdr), char);
    Copy(SvPVbyte_nolen(body), SvPVbyte_nolen(RETVAL) + sizeof(nlmsghdr), bodylen, char);

  OUTPUT:
    RETVAL

void
unpack_nlmsghdr(msg)
    SV *msg

  PREINIT:
    struct nlmsghdr nlmsghdr;
    STRLEN msglen;

  PPCODE:
    if(!SvPOK(msg))
      croak("Expected a string message");

    msglen = SvCUR(msg);

    Copy(SvPVbyte_nolen(msg), &nlmsghdr, sizeof(nlmsghdr), char);

    EXTEND(SP, 6);
    PUSHs(sv_2mortal(newSViv(nlmsghdr.nlmsg_type)));
    PUSHs(sv_2mortal(newSViv(nlmsghdr.nlmsg_flags)));
    PUSHs(sv_2mortal(newSViv(nlmsghdr.nlmsg_seq)));
    PUSHs(sv_2mortal(newSViv(nlmsghdr.nlmsg_pid)));
    PUSHs(sv_2mortal(newSVpvn(SvPVbyte_nolen(msg) + sizeof(nlmsghdr), nlmsghdr.nlmsg_len - sizeof(nlmsghdr))));

    if(msglen > nlmsghdr.nlmsg_len) {
      // We have another message behind this
      PUSHs(sv_2mortal(newSVpvn(SvPVbyte_nolen(msg) + nlmsghdr.nlmsg_len, msglen - nlmsghdr.nlmsg_len)));
    }

SV*
pack_nlmsgerr(error, msg)
    unsigned int  error
    SV           *msg

  PREINIT:
    struct nlmsgerr nlmsgerr;
    STRLEN          msglen;

  CODE:
    if(!SvPOK(msg))
      croak("Expected a string body");

    nlmsgerr.error = -error; /* kernel wants this negative */

    msglen = SvCUR(msg);
    if(msglen > sizeof(nlmsgerr.msg))
      msglen = sizeof(nlmsgerr.msg);

    Zero(&nlmsgerr.msg, sizeof(nlmsgerr.msg), char);
    Copy(SvPVbyte_nolen(msg), &nlmsgerr.msg, sizeof(nlmsgerr.msg), char);

    RETVAL = newSVpvn((char*)&nlmsgerr, sizeof(nlmsgerr));

  OUTPUT:
    RETVAL

void
unpack_nlmsgerr(msg)
    SV *msg

  PREINIT:
    struct nlmsgerr nlmsgerr;

  PPCODE:
    if(!SvPOK(msg))
      croak("Expected a string message");
    if(SvCUR(msg) != sizeof(nlmsgerr))
      croak("Expected %d bytes of message", sizeof(nlmsgerr));

    Copy(SvPVbyte_nolen(msg), &nlmsgerr, sizeof(nlmsgerr), char);

    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSViv(-nlmsgerr.error))); /* kernel sends this negative */
    PUSHs(sv_2mortal(newSVpvn((char*)&nlmsgerr.msg, sizeof(nlmsgerr.msg))));

SV *
pack_nlattrs(...)
  PREINIT:
    STRLEN  bufflen = 0;
    int     i;
    char   *buffer;

  CODE:
    if(items % 2)
      croak("Expected even number of elements");

    for(i = 0; i < items; i+=2) {
      SV *value;

      value = ST(i+1);
      if(!value || !SvPOK(value))
        croak("Expected string at parameter %d\n", i+1);

      bufflen += NLA_HDRLEN + NLA_ALIGN(SvCUR(value));
    }

    if(items == 0) {
      /* newSV(0) doesn't behave right; special-case it */
      RETVAL = newSVpvn("", 0);
    }
    else {
      RETVAL = newSV(bufflen);
      SvPOK_on(RETVAL);
      SvCUR_set(RETVAL, bufflen);
    }

    buffer = SvPVbyte_nolen(RETVAL);

    for(i = 0; i < items; i+=2) {
      struct nlattr attrhdr;
      SV *value = ST(i+1);
      STRLEN valuelen = SvCUR(value);

      attrhdr.nla_len  = NLA_HDRLEN + valuelen;
      attrhdr.nla_type = SvIV(ST(i));

      Copy((char*)&attrhdr, buffer, NLA_HDRLEN, char);
      Copy(SvPVbyte_nolen(value), buffer + NLA_HDRLEN, valuelen, char);
      Zero(buffer + NLA_HDRLEN + valuelen, NLA_ALIGN(valuelen) - valuelen, char);

      buffer += NLA_ALIGN(attrhdr.nla_len);
    }

  OUTPUT:
    RETVAL

void
unpack_nlattrs(body)
    SV *body

  INIT:
    STRLEN  bufflen;
    char   *buffer;

  PPCODE:
    if(!SvPOK(body))
      croak("Expected a string body");

    buffer = SvPVbyte(body, bufflen);

    while(bufflen > 0) {
      struct nlattr attrhdr;

      if(bufflen < NLA_HDRLEN)
        croak("Ran out of bytes for nlattr header");

      Copy(buffer, (char*)&attrhdr, NLA_HDRLEN, char);

      if(bufflen < attrhdr.nla_len)
        croak("Ran out of bytes for nlattr body of %d bytes", attrhdr.nla_len);

      XPUSHs(sv_2mortal(newSViv(attrhdr.nla_type)));
      XPUSHs(sv_2mortal(newSVpvn(buffer + NLA_HDRLEN, attrhdr.nla_len - NLA_HDRLEN)));

      bufflen -= NLA_ALIGN(attrhdr.nla_len);
      buffer  += NLA_ALIGN(attrhdr.nla_len);
    }
