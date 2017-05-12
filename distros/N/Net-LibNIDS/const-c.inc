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
constant_10 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     NIDS_CLOSE NIDS_MAJOR NIDS_MINOR NIDS_RESET */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'J':
    if (memEQ(name, "NIDS_MAJOR", 10)) {
    /*                      ^         */
#ifdef NIDS_MAJOR
      *iv_return = NIDS_MAJOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "NIDS_MINOR", 10)) {
    /*                      ^         */
#ifdef NIDS_MINOR
      *iv_return = NIDS_MINOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "NIDS_CLOSE", 10)) {
    /*                      ^         */
#ifdef NIDS_CLOSE
      *iv_return = NIDS_CLOSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "NIDS_RESET", 10)) {
    /*                      ^         */
#ifdef NIDS_RESET
      *iv_return = NIDS_RESET;
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

#!/usr/bin/perl5.16.3 -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(NIDS_CLOSE NIDS_DATA NIDS_EXITING NIDS_JUST_EST NIDS_MAJOR
	       NIDS_MINOR NIDS_RESET NIDS_TIMED_OUT));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Lib::nids", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Lib::nids", $types);
__END__
   */

  switch (len) {
  case 9:
    if (memEQ(name, "NIDS_DATA", 9)) {
#ifdef NIDS_DATA
      *iv_return = NIDS_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 10:
    return constant_10 (aTHX_ name, iv_return);
    break;
  case 12:
    if (memEQ(name, "NIDS_EXITING", 12)) {
#ifdef NIDS_EXITING
      *iv_return = NIDS_EXITING;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 13:
    if (memEQ(name, "NIDS_JUST_EST", 13)) {
#ifdef NIDS_JUST_EST
      *iv_return = NIDS_JUST_EST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 14:
    if (memEQ(name, "NIDS_TIMED_OUT", 14)) {
#ifdef NIDS_TIMED_OUT
      *iv_return = NIDS_TIMED_OUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

