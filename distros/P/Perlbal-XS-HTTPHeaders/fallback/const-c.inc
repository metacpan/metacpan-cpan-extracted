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
my @names = (qw(H_REQUEST H_RESPONSE M_DELETE M_GET M_HEAD M_OPTIONS M_POST
	       M_PUT));

print constant_types(); # macro defs
foreach (C_constant ("Perlbal::XS::HTTPHeaders", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Perlbal::XS::HTTPHeaders", $types);
__END__
   */

  switch (len) {
  case 5:
    /* Names all of length 5.  */
    /* M_GET M_PUT */
    /* Offset 2 gives the best switch position.  */
    switch (name[2]) {
    case 'G':
      if (memEQ(name, "M_GET", 5)) {
      /*                 ^        */
#ifdef M_GET
        *iv_return = M_GET;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "M_PUT", 5)) {
      /*                 ^        */
#ifdef M_PUT
        *iv_return = M_PUT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 6:
    /* Names all of length 6.  */
    /* M_HEAD M_POST */
    /* Offset 2 gives the best switch position.  */
    switch (name[2]) {
    case 'H':
      if (memEQ(name, "M_HEAD", 6)) {
      /*                 ^         */
#ifdef M_HEAD
        *iv_return = M_HEAD;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "M_POST", 6)) {
      /*                 ^         */
#ifdef M_POST
        *iv_return = M_POST;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 8:
    if (memEQ(name, "M_DELETE", 8)) {
#ifdef M_DELETE
      *iv_return = M_DELETE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 9:
    /* Names all of length 9.  */
    /* H_REQUEST M_OPTIONS */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'S':
      if (memEQ(name, "M_OPTION", 8)) {
      /*                       S     */
#ifdef M_OPTIONS
        *iv_return = M_OPTIONS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "H_REQUES", 8)) {
      /*                       T     */
#ifdef H_REQUEST
        *iv_return = H_REQUEST;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 10:
    if (memEQ(name, "H_RESPONSE", 10)) {
#ifdef H_RESPONSE
      *iv_return = H_RESPONSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

