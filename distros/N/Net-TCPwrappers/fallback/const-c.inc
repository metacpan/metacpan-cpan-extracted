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
constant_7 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AC_DENY RQ_FILE RQ_USER */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'E':
    if (memEQ(name, "RQ_USER", 7)) {
    /*                    ^       */
#ifdef RQ_USER
      *iv_return = RQ_USER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "RQ_FILE", 7)) {
    /*                    ^       */
#ifdef RQ_FILE
      *iv_return = RQ_FILE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "AC_DENY", 7)) {
    /*                    ^       */
#ifdef AC_DENY
      *iv_return = AC_DENY;
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
     RQ_CLIENT_ADDR RQ_CLIENT_NAME RQ_SERVER_ADDR RQ_SERVER_NAME */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'R':
    if (memEQ(name, "RQ_SERVER_ADDR", 14)) {
    /*                       ^            */
#ifdef RQ_SERVER_ADDR
      *iv_return = RQ_SERVER_ADDR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "RQ_SERVER_NAME", 14)) {
    /*                       ^            */
#ifdef RQ_SERVER_NAME
      *iv_return = RQ_SERVER_NAME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "RQ_CLIENT_ADDR", 14)) {
    /*                       ^            */
#ifdef RQ_CLIENT_ADDR
      *iv_return = RQ_CLIENT_ADDR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "RQ_CLIENT_NAME", 14)) {
    /*                       ^            */
#ifdef RQ_CLIENT_NAME
      *iv_return = RQ_CLIENT_NAME;
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

#!/usr/local/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(AC_DENY AC_ERROR AC_PERMIT RQ_CLIENT_ADDR RQ_CLIENT_NAME
	       RQ_CLIENT_SIN RQ_DAEMON RQ_FILE RQ_SERVER_ADDR RQ_SERVER_NAME
	       RQ_SERVER_SIN RQ_USER));

print constant_types(); # macro defs
foreach (C_constant ("Net::TCPwrappers", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Net::TCPwrappers", $types);
__END__
   */

  switch (len) {
  case 7:
    return constant_7 (aTHX_ name, iv_return);
    break;
  case 8:
    if (memEQ(name, "AC_ERROR", 8)) {
#ifdef AC_ERROR
      *iv_return = AC_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 9:
    /* Names all of length 9.  */
    /* AC_PERMIT RQ_DAEMON */
    /* Offset 4 gives the best switch position.  */
    switch (name[4]) {
    case 'A':
      if (memEQ(name, "RQ_DAEMON", 9)) {
      /*                   ^          */
#ifdef RQ_DAEMON
        *iv_return = RQ_DAEMON;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'E':
      if (memEQ(name, "AC_PERMIT", 9)) {
      /*                   ^          */
#ifdef AC_PERMIT
        *iv_return = AC_PERMIT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 13:
    /* Names all of length 13.  */
    /* RQ_CLIENT_SIN RQ_SERVER_SIN */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'R':
      if (memEQ(name, "RQ_SERVER_SIN", 13)) {
      /*                       ^           */
#ifdef RQ_SERVER_SIN
        *iv_return = RQ_SERVER_SIN;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "RQ_CLIENT_SIN", 13)) {
      /*                       ^           */
#ifdef RQ_CLIENT_SIN
        *iv_return = RQ_CLIENT_SIN;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  }
  return PERL_constant_NOTFOUND;
}

