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
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DROP_RECV FIFO_MESS SAFE_MESS */
  /* Offset 3 gives the best switch position.  */
  switch (name[3]) {
  case 'E':
    if (memEQ(name, "SAFE_MESS", 9)) {
    /*                  ^           */
#ifdef SAFE_MESS
      *iv_return = SAFE_MESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "FIFO_MESS", 9)) {
    /*                  ^           */
#ifdef FIFO_MESS
      *iv_return = FIFO_MESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "DROP_RECV", 9)) {
    /*                  ^           */
#ifdef DROP_RECV
      *iv_return = DROP_RECV;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_11 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AGREED_MESS CAUSAL_MESS REJECT_AUTH REJECT_MESS */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'A':
    if (memEQ(name, "CAUSAL_MESS", 11)) {
    /*                   ^             */
#ifdef CAUSAL_MESS
      *iv_return = CAUSAL_MESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "REJECT_AUTH", 11)) {
    /*                   ^             */
#ifdef REJECT_AUTH
      *iv_return = REJECT_AUTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "REJECT_MESS", 11)) {
    /*                   ^             */
#ifdef REJECT_MESS
      *iv_return = REJECT_MESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "AGREED_MESS", 11)) {
    /*                   ^             */
#ifdef AGREED_MESS
      *iv_return = AGREED_MESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_12 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LOW_PRIORITY REGULAR_MESS REJECT_QUOTA SELF_DISCARD */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'A':
    if (memEQ(name, "SELF_DISCARD", 12)) {
    /*                        ^         */
#ifdef SELF_DISCARD
      *iv_return = SELF_DISCARD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "REGULAR_MESS", 12)) {
    /*                        ^         */
#ifdef REGULAR_MESS
      *iv_return = REGULAR_MESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "LOW_PRIORITY", 12)) {
    /*                        ^         */
#ifdef LOW_PRIORITY
      *iv_return = LOW_PRIORITY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "REJECT_QUOTA", 12)) {
    /*                        ^         */
#ifdef REJECT_QUOTA
      *iv_return = REJECT_QUOTA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     HIGH_PRIORITY ILLEGAL_GROUP MAX_PROC_NAME REG_MEMB_MESS RELIABLE_MESS */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'A':
    if (memEQ(name, "ILLEGAL_GROUP", 13)) {
    /*                    ^              */
#ifdef ILLEGAL_GROUP
      *iv_return = ILLEGAL_GROUP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "RELIABLE_MESS", 13)) {
    /*                    ^              */
#ifdef RELIABLE_MESS
      *iv_return = RELIABLE_MESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "REG_MEMB_MESS", 13)) {
    /*                    ^              */
#ifdef REG_MEMB_MESS
      *iv_return = REG_MEMB_MESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "HIGH_PRIORITY", 13)) {
    /*                    ^              */
#ifdef HIGH_PRIORITY
      *iv_return = HIGH_PRIORITY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "MAX_PROC_NAME", 13)) {
    /*                    ^              */
#ifdef MAX_PROC_NAME
      *iv_return = MAX_PROC_NAME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ACCEPT_SESSION CAUSED_BY_JOIN ILLEGAL_SPREAD MAX_GROUP_NAME REJECT_NO_NAME
     REJECT_VERSION SPREAD_VERSION */
  /* Offset 0 gives the best switch position.  */
  switch (*name++) {
  case 'A':
    if (memEQ(name, "CCEPT_SESSION", 13)) {
    /*                A                    */
#ifdef ACCEPT_SESSION
      *iv_return = ACCEPT_SESSION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "AUSED_BY_JOIN", 13)) {
    /*                C                    */
#ifdef CAUSED_BY_JOIN
      *iv_return = CAUSED_BY_JOIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "LLEGAL_SPREAD", 13)) {
    /*                I                    */
#ifdef ILLEGAL_SPREAD
      *iv_return = ILLEGAL_SPREAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "AX_GROUP_NAME", 13)) {
    /*                M                    */
#ifdef MAX_GROUP_NAME
      *iv_return = MAX_GROUP_NAME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "EJECT_NO_NAME", 13)) {
    /*                R                    */
#ifdef REJECT_NO_NAME
      *iv_return = REJECT_NO_NAME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EJECT_VERSION", 13)) {
    /*                R                    */
#ifdef REJECT_VERSION
      *iv_return = REJECT_VERSION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "PREAD_VERSION", 13)) {
    /*                S                    */
#ifdef SPREAD_VERSION
      *iv_return = SPREAD_VERSION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CAUSED_BY_LEAVE ENDIAN_RESERVED ILLEGAL_MESSAGE ILLEGAL_SERVICE
     ILLEGAL_SESSION MEDIUM_PRIORITY MEMBERSHIP_MESS TRANSITION_MESS
     UNRELIABLE_MESS */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'E':
    if (memEQ(name, "ENDIAN_RESERVED", 15)) {
    /*                       ^             */
#ifdef ENDIAN_RESERVED
      *iv_return = ENDIAN_RESERVED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "MEMBERSHIP_MESS", 15)) {
    /*                       ^             */
#ifdef MEMBERSHIP_MESS
      *iv_return = MEMBERSHIP_MESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "UNRELIABLE_MESS", 15)) {
    /*                       ^             */
#ifdef UNRELIABLE_MESS
      *iv_return = UNRELIABLE_MESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "ILLEGAL_MESSAGE", 15)) {
    /*                       ^             */
#ifdef ILLEGAL_MESSAGE
      *iv_return = ILLEGAL_MESSAGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "TRANSITION_MESS", 15)) {
    /*                       ^             */
#ifdef TRANSITION_MESS
      *iv_return = TRANSITION_MESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "MEDIUM_PRIORITY", 15)) {
    /*                       ^             */
#ifdef MEDIUM_PRIORITY
      *iv_return = MEDIUM_PRIORITY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "ILLEGAL_SERVICE", 15)) {
    /*                       ^             */
#ifdef ILLEGAL_SERVICE
      *iv_return = ILLEGAL_SERVICE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "ILLEGAL_SESSION", 15)) {
    /*                       ^             */
#ifdef ILLEGAL_SESSION
      *iv_return = ILLEGAL_SESSION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "CAUSED_BY_LEAVE", 15)) {
    /*                       ^             */
#ifdef CAUSED_BY_LEAVE
      *iv_return = CAUSED_BY_LEAVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BUFFER_TOO_SHORT GROUPS_TOO_SHORT MAX_PRIVATE_NAME MESSAGE_TOO_LONG */
  /* Offset 2 gives the best switch position.  */
  switch (name[2]) {
  case 'F':
    if (memEQ(name, "BUFFER_TOO_SHORT", 16)) {
    /*                 ^                    */
#ifdef BUFFER_TOO_SHORT
      *iv_return = BUFFER_TOO_SHORT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "GROUPS_TOO_SHORT", 16)) {
    /*                 ^                    */
#ifdef GROUPS_TOO_SHORT
      *iv_return = GROUPS_TOO_SHORT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "MESSAGE_TOO_LONG", 16)) {
    /*                 ^                    */
#ifdef MESSAGE_TOO_LONG
      *iv_return = MESSAGE_TOO_LONG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "MAX_PRIVATE_NAME", 16)) {
    /*                 ^                    */
#ifdef MAX_PRIVATE_NAME
      *iv_return = MAX_PRIVATE_NAME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CAUSED_BY_NETWORK CONNECTION_CLOSED COULD_NOT_CONNECT REJECT_NOT_UNIQUE */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'B':
    if (memEQ(name, "CAUSED_BY_NETWORK", 17)) {
    /*                      ^                */
#ifdef CAUSED_BY_NETWORK
      *iv_return = CAUSED_BY_NETWORK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CONNECTION_CLOSED", 17)) {
    /*                      ^                */
#ifdef CONNECTION_CLOSED
      *iv_return = CONNECTION_CLOSED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "REJECT_NOT_UNIQUE", 17)) {
    /*                      ^                */
#ifdef REJECT_NOT_UNIQUE
      *iv_return = REJECT_NOT_UNIQUE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "COULD_NOT_CONNECT", 17)) {
    /*                      ^                */
#ifdef COULD_NOT_CONNECT
      *iv_return = COULD_NOT_CONNECT;
      return PERL_constant_ISIV;
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

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(ACCEPT_SESSION AGREED_MESS BUFFER_TOO_SHORT CAUSAL_MESS
	       CAUSED_BY_DISCONNECT CAUSED_BY_JOIN CAUSED_BY_LEAVE
	       CAUSED_BY_NETWORK CONNECTION_CLOSED COULD_NOT_CONNECT
	       DEFAULT_SPREAD_PORT DROP_RECV ENDIAN_RESERVED FIFO_MESS
	       GROUPS_TOO_SHORT HIGH_PRIORITY ILLEGAL_GROUP ILLEGAL_MESSAGE
	       ILLEGAL_SERVICE ILLEGAL_SESSION ILLEGAL_SPREAD LOW_PRIORITY
	       MAX_CLIENT_SCATTER_ELEMENTS MAX_GROUP_NAME MAX_PRIVATE_NAME
	       MAX_PROC_NAME MEDIUM_PRIORITY MEMBERSHIP_MESS MESSAGE_TOO_LONG
	       NET_ERROR_ON_SESSION REGULAR_MESS REG_MEMB_MESS REJECT_AUTH
	       REJECT_ILLEGAL_NAME REJECT_MESS REJECT_NOT_UNIQUE REJECT_NO_NAME
	       REJECT_QUOTA REJECT_VERSION RELIABLE_MESS RESERVED SAFE_MESS
	       SELF_DISCARD SPREAD_VERSION TRANSITION_MESS UNRELIABLE_MESS
	       int16 int32));

print constant_types(); # macro defs
foreach (C_constant ("Spread::Client::Constant", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Spread::Client::Constant", $types);
__END__
   */

  switch (len) {
  case 5:
    /* Names all of length 5.  */
    /* int16 int32 */
    /* Offset 3 gives the best switch position.  */
    switch (name[3]) {
    case '1':
      if (memEQ(name, "int16", 5)) {
      /*                  ^       */
#ifdef int16
        *iv_return = int16;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case '3':
      if (memEQ(name, "int32", 5)) {
      /*                  ^       */
#ifdef int32
        *iv_return = int32;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 8:
    if (memEQ(name, "RESERVED", 8)) {
#ifdef RESERVED
      *iv_return = RESERVED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return);
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 19:
    /* Names all of length 19.  */
    /* DEFAULT_SPREAD_PORT REJECT_ILLEGAL_NAME */
    /* Offset 11 gives the best switch position.  */
    switch (name[11]) {
    case 'E':
      if (memEQ(name, "DEFAULT_SPREAD_PORT", 19)) {
      /*                          ^              */
#ifdef DEFAULT_SPREAD_PORT
        *iv_return = DEFAULT_SPREAD_PORT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'G':
      if (memEQ(name, "REJECT_ILLEGAL_NAME", 19)) {
      /*                          ^              */
#ifdef REJECT_ILLEGAL_NAME
        *iv_return = REJECT_ILLEGAL_NAME;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 20:
    /* Names all of length 20.  */
    /* CAUSED_BY_DISCONNECT NET_ERROR_ON_SESSION */
    /* Offset 2 gives the best switch position.  */
    switch (name[2]) {
    case 'T':
      if (memEQ(name, "NET_ERROR_ON_SESSION", 20)) {
      /*                 ^                        */
#ifdef NET_ERROR_ON_SESSION
        *iv_return = NET_ERROR_ON_SESSION;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'U':
      if (memEQ(name, "CAUSED_BY_DISCONNECT", 20)) {
      /*                 ^                        */
#ifdef CAUSED_BY_DISCONNECT
        *iv_return = CAUSED_BY_DISCONNECT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 27:
    if (memEQ(name, "MAX_CLIENT_SCATTER_ELEMENTS", 27)) {
#ifdef MAX_CLIENT_SCATTER_ELEMENTS
      *iv_return = MAX_CLIENT_SCATTER_ELEMENTS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

