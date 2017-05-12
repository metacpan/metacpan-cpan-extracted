#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CDP_CAP_REPEATER CDP_DISABLE_RECV CDP_DISABLE_SEND */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'C':
    if (memEQ(name, "CDP_DISABLE_RECV", 16)) {
    /*                             ^        */
#ifdef CDP_DISABLE_RECV
      *iv_return = (IV) CDP_DISABLE_RECV;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CDP_CAP_REPEATER", 16)) {
    /*                             ^        */
#ifdef CDP_CAP_REPEATER
      *iv_return = (IV) CDP_CAP_REPEATER;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "CDP_DISABLE_SEND", 16)) {
    /*                             ^        */
#ifdef CDP_DISABLE_SEND
      *iv_return = (IV) CDP_DISABLE_SEND;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_19 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CDP_ADDR_PROTO_CLNP CDP_ADDR_PROTO_IPV4 CDP_ADDR_PROTO_IPV6 */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case '4':
    if (memEQ(name, "CDP_ADDR_PROTO_IPV", 18)) {
    /*                                 4      */
#ifdef CDP_ADDR_PROTO_IPV4
      *iv_return = (IV) CDP_ADDR_PROTO_IPV4;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '6':
    if (memEQ(name, "CDP_ADDR_PROTO_IPV", 18)) {
    /*                                 6      */
#ifdef CDP_ADDR_PROTO_IPV6
      *iv_return = (IV) CDP_ADDR_PROTO_IPV6;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "CDP_ADDR_PROTO_CLN", 18)) {
    /*                                 P      */
#ifdef CDP_ADDR_PROTO_CLNP
      *iv_return = (IV) CDP_ADDR_PROTO_CLNP;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CDP_ADDR_PROTO_APOLLO CDP_ADDR_PROTO_DECNET CDP_CAP_SOURCE_BRIDGE */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'A':
    if (memEQ(name, "CDP_ADDR_PROTO_APOLLO", 21)) {
    /*                              ^            */
#ifdef CDP_ADDR_PROTO_APOLLO
      *iv_return = (IV) CDP_ADDR_PROTO_APOLLO;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "CDP_CAP_SOURCE_BRIDGE", 21)) {
    /*                              ^            */
#ifdef CDP_CAP_SOURCE_BRIDGE
      *iv_return = (IV) CDP_CAP_SOURCE_BRIDGE;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "CDP_ADDR_PROTO_DECNET", 21)) {
    /*                              ^            */
#ifdef CDP_ADDR_PROTO_DECNET
      *iv_return = (IV) CDP_ADDR_PROTO_DECNET;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/usr/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(UV)};
my @names = (qw(CDP_ADDR_PROTO_APOLLO CDP_ADDR_PROTO_APPLETALK
	       CDP_ADDR_PROTO_CLNP CDP_ADDR_PROTO_DECNET CDP_ADDR_PROTO_IPV4
	       CDP_ADDR_PROTO_IPV6 CDP_ADDR_PROTO_IPX CDP_ADDR_PROTO_VINES
	       CDP_ADDR_PROTO_XNS CDP_CAP_HOST CDP_CAP_IGMP CDP_CAP_REPEATER
	       CDP_CAP_ROUTER CDP_CAP_SOURCE_BRIDGE CDP_CAP_SWITCH
	       CDP_CAP_TRANSPARENT_BRIDGE CDP_DISABLE_RECV CDP_DISABLE_SEND
	       CDP_PROMISCUOUS CDP_RECV_DECODE_ERRORS CDP_RECV_NONBLOCK));

print constant_types(); # macro defs
foreach (C_constant ("Net::CDP::Constants", 'constant', 'UV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Net::CDP::Constants", $types);
__END__
   */

  switch (len) {
  case 12:
    /* Names all of length 12.  */
    /* CDP_CAP_HOST CDP_CAP_IGMP */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'H':
      if (memEQ(name, "CDP_CAP_HOST", 12)) {
      /*                       ^          */
#ifdef CDP_CAP_HOST
        *iv_return = (IV) CDP_CAP_HOST;
        return PERL_constant_ISUV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'I':
      if (memEQ(name, "CDP_CAP_IGMP", 12)) {
      /*                       ^          */
#ifdef CDP_CAP_IGMP
        *iv_return = (IV) CDP_CAP_IGMP;
        return PERL_constant_ISUV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 14:
    /* Names all of length 14.  */
    /* CDP_CAP_ROUTER CDP_CAP_SWITCH */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'R':
      if (memEQ(name, "CDP_CAP_ROUTER", 14)) {
      /*                       ^            */
#ifdef CDP_CAP_ROUTER
        *iv_return = (IV) CDP_CAP_ROUTER;
        return PERL_constant_ISUV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "CDP_CAP_SWITCH", 14)) {
      /*                       ^            */
#ifdef CDP_CAP_SWITCH
        *iv_return = (IV) CDP_CAP_SWITCH;
        return PERL_constant_ISUV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 15:
    if (memEQ(name, "CDP_PROMISCUOUS", 15)) {
#ifdef CDP_PROMISCUOUS
      *iv_return = (IV) CDP_PROMISCUOUS;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    if (memEQ(name, "CDP_RECV_NONBLOCK", 17)) {
#ifdef CDP_RECV_NONBLOCK
      *iv_return = (IV) CDP_RECV_NONBLOCK;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 18:
    /* Names all of length 18.  */
    /* CDP_ADDR_PROTO_IPX CDP_ADDR_PROTO_XNS */
    /* Offset 16 gives the best switch position.  */
    switch (name[16]) {
    case 'N':
      if (memEQ(name, "CDP_ADDR_PROTO_XNS", 18)) {
      /*                               ^        */
#ifdef CDP_ADDR_PROTO_XNS
        *iv_return = (IV) CDP_ADDR_PROTO_XNS;
        return PERL_constant_ISUV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "CDP_ADDR_PROTO_IPX", 18)) {
      /*                               ^        */
#ifdef CDP_ADDR_PROTO_IPX
        *iv_return = (IV) CDP_ADDR_PROTO_IPX;
        return PERL_constant_ISUV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 19:
    return constant_19 (aTHX_ name, iv_return);
    break;
  case 20:
    if (memEQ(name, "CDP_ADDR_PROTO_VINES", 20)) {
#ifdef CDP_ADDR_PROTO_VINES
      *iv_return = (IV) CDP_ADDR_PROTO_VINES;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  case 22:
    if (memEQ(name, "CDP_RECV_DECODE_ERRORS", 22)) {
#ifdef CDP_RECV_DECODE_ERRORS
      *iv_return = (IV) CDP_RECV_DECODE_ERRORS;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 24:
    if (memEQ(name, "CDP_ADDR_PROTO_APPLETALK", 24)) {
#ifdef CDP_ADDR_PROTO_APPLETALK
      *iv_return = (IV) CDP_ADDR_PROTO_APPLETALK;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 26:
    if (memEQ(name, "CDP_CAP_TRANSPARENT_BRIDGE", 26)) {
#ifdef CDP_CAP_TRANSPARENT_BRIDGE
      *iv_return = (IV) CDP_CAP_TRANSPARENT_BRIDGE;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

