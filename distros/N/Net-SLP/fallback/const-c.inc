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
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SLP_HANDLE_IN_USE SLP_NETWORK_ERROR SLP_PARAMETER_BAD */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'L':
    if (memEQ(name, "SLP_HANDLE_IN_USE", 17)) {
    /*                       ^               */
#ifdef SLP_HANDLE_IN_USE
      *iv_return = SLP_HANDLE_IN_USE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "SLP_PARAMETER_BAD", 17)) {
    /*                       ^               */
#ifdef SLP_PARAMETER_BAD
      *iv_return = SLP_PARAMETER_BAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "SLP_NETWORK_ERROR", 17)) {
    /*                       ^               */
#ifdef SLP_NETWORK_ERROR
      *iv_return = SLP_NETWORK_ERROR;
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
constant_20 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SLP_LIFETIME_DEFAULT SLP_LIFETIME_MAXIMUM SLP_REFRESH_REJECTED */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'A':
    if (memEQ(name, "SLP_LIFETIME_DEFAULT", 20)) {
    /*                               ^          */
#ifdef SLP_LIFETIME_DEFAULT
      *iv_return = SLP_LIFETIME_DEFAULT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "SLP_REFRESH_REJECTED", 20)) {
    /*                               ^          */
#ifdef SLP_REFRESH_REJECTED
      *iv_return = SLP_REFRESH_REJECTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "SLP_LIFETIME_MAXIMUM", 20)) {
    /*                               ^          */
#ifdef SLP_LIFETIME_MAXIMUM
      *iv_return = SLP_LIFETIME_MAXIMUM;
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
constant_23 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SLP_MEMORY_ALLOC_FAILED SLP_NETWORK_INIT_FAILED SLP_SCOPE_NOT_SUPPORTED */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'M':
    if (memEQ(name, "SLP_MEMORY_ALLOC_FAILED", 23)) {
    /*                   ^                         */
#ifdef SLP_MEMORY_ALLOC_FAILED
      *iv_return = SLP_MEMORY_ALLOC_FAILED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "SLP_NETWORK_INIT_FAILED", 23)) {
    /*                   ^                         */
#ifdef SLP_NETWORK_INIT_FAILED
      *iv_return = SLP_NETWORK_INIT_FAILED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "SLP_SCOPE_NOT_SUPPORTED", 23)) {
    /*                   ^                         */
#ifdef SLP_SCOPE_NOT_SUPPORTED
      *iv_return = SLP_SCOPE_NOT_SUPPORTED;
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
constant_25 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SLP_AUTHENTICATION_ABSENT SLP_AUTHENTICATION_FAILED
     SLP_INTERNAL_SYSTEM_ERROR */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case 'A':
    if (memEQ(name, "SLP_AUTHENTICATION_FAILED", 25)) {
    /*                                   ^           */
#ifdef SLP_AUTHENTICATION_FAILED
      *iv_return = SLP_AUTHENTICATION_FAILED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "SLP_AUTHENTICATION_ABSENT", 25)) {
    /*                                   ^           */
#ifdef SLP_AUTHENTICATION_ABSENT
      *iv_return = SLP_AUTHENTICATION_ABSENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "SLP_INTERNAL_SYSTEM_ERROR", 25)) {
    /*                                   ^           */
#ifdef SLP_INTERNAL_SYSTEM_ERROR
      *iv_return = SLP_INTERNAL_SYSTEM_ERROR;
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

#!/usr/bin/perl5.8.3 -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(SLP_AUTHENTICATION_ABSENT SLP_AUTHENTICATION_FAILED
	       SLP_BUFFER_OVERFLOW SLP_FALSE SLP_HANDLE_IN_USE
	       SLP_INTERNAL_SYSTEM_ERROR SLP_INVALID_REGISTRATION
	       SLP_INVALID_UPDATE SLP_LANGUAGE_NOT_SUPPORTED SLP_LAST_CALL
	       SLP_LIFETIME_DEFAULT SLP_LIFETIME_MAXIMUM
	       SLP_MEMORY_ALLOC_FAILED SLP_NETWORK_ERROR
	       SLP_NETWORK_INIT_FAILED SLP_NETWORK_TIMED_OUT
	       SLP_NOT_IMPLEMENTED SLP_OK SLP_PARAMETER_BAD SLP_PARSE_ERROR
	       SLP_REFRESH_REJECTED SLP_SCOPE_NOT_SUPPORTED SLP_TRUE
	       SLP_TYPE_ERROR));

print constant_types(); # macro defs
foreach (C_constant ("Net::SLP", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Net::SLP", $types);
__END__
   */

  switch (len) {
  case 6:
    if (memEQ(name, "SLP_OK", 6)) {
#ifdef SLP_OK
      *iv_return = SLP_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 8:
    if (memEQ(name, "SLP_TRUE", 8)) {
#ifdef SLP_TRUE
      *iv_return = SLP_TRUE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 9:
    if (memEQ(name, "SLP_FALSE", 9)) {
#ifdef SLP_FALSE
      *iv_return = SLP_FALSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 13:
    if (memEQ(name, "SLP_LAST_CALL", 13)) {
#ifdef SLP_LAST_CALL
      *iv_return = SLP_LAST_CALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 14:
    if (memEQ(name, "SLP_TYPE_ERROR", 14)) {
#ifdef SLP_TYPE_ERROR
      *iv_return = SLP_TYPE_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 15:
    if (memEQ(name, "SLP_PARSE_ERROR", 15)) {
#ifdef SLP_PARSE_ERROR
      *iv_return = SLP_PARSE_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    if (memEQ(name, "SLP_INVALID_UPDATE", 18)) {
#ifdef SLP_INVALID_UPDATE
      *iv_return = SLP_INVALID_UPDATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 19:
    /* Names all of length 19.  */
    /* SLP_BUFFER_OVERFLOW SLP_NOT_IMPLEMENTED */
    /* Offset 11 gives the best switch position.  */
    switch (name[11]) {
    case 'L':
      if (memEQ(name, "SLP_NOT_IMPLEMENTED", 19)) {
      /*                          ^              */
#ifdef SLP_NOT_IMPLEMENTED
        *iv_return = SLP_NOT_IMPLEMENTED;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'O':
      if (memEQ(name, "SLP_BUFFER_OVERFLOW", 19)) {
      /*                          ^              */
#ifdef SLP_BUFFER_OVERFLOW
        *iv_return = SLP_BUFFER_OVERFLOW;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 20:
    return constant_20 (aTHX_ name, iv_return);
    break;
  case 21:
    if (memEQ(name, "SLP_NETWORK_TIMED_OUT", 21)) {
#ifdef SLP_NETWORK_TIMED_OUT
      *iv_return = SLP_NETWORK_TIMED_OUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 23:
    return constant_23 (aTHX_ name, iv_return);
    break;
  case 24:
    if (memEQ(name, "SLP_INVALID_REGISTRATION", 24)) {
#ifdef SLP_INVALID_REGISTRATION
      *iv_return = SLP_INVALID_REGISTRATION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 25:
    return constant_25 (aTHX_ name, iv_return);
    break;
  case 26:
    if (memEQ(name, "SLP_LANGUAGE_NOT_SUPPORTED", 26)) {
#ifdef SLP_LANGUAGE_NOT_SUPPORTED
      *iv_return = SLP_LANGUAGE_NOT_SUPPORTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

