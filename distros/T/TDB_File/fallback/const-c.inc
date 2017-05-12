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
     TDB_ERR_IO TDB_INSERT TDB_MODIFY TDB_NOLOCK TDB_NOMMAP */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'K':
    if (memEQ(name, "TDB_NOLOC", 9)) {
    /*                        K     */
#ifdef TDB_NOLOCK
      *iv_return = TDB_NOLOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "TDB_ERR_I", 9)) {
    /*                        O     */
      *iv_return = TDB_ERR_IO;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "TDB_NOMMA", 9)) {
    /*                        P     */
#ifdef TDB_NOMMAP
      *iv_return = TDB_NOMMAP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "TDB_INSER", 9)) {
    /*                        T     */
#ifdef TDB_INSERT
      *iv_return = TDB_INSERT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "TDB_MODIF", 9)) {
    /*                        Y     */
#ifdef TDB_MODIFY
      *iv_return = TDB_MODIFY;
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
     TDB_CONVERT TDB_DEFAULT TDB_ERR_OOM TDB_REPLACE TDB_SUCCESS */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'C':
    if (memEQ(name, "TDB_SUCCESS", 11)) {
    /*                     ^           */
      *iv_return = TDB_SUCCESS;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "TDB_DEFAULT", 11)) {
    /*                     ^           */
#ifdef TDB_DEFAULT
      *iv_return = TDB_DEFAULT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "TDB_CONVERT", 11)) {
    /*                     ^           */
#ifdef TDB_CONVERT
      *iv_return = TDB_CONVERT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "TDB_REPLACE", 11)) {
    /*                     ^           */
#ifdef TDB_REPLACE
      *iv_return = TDB_REPLACE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "TDB_ERR_OOM", 11)) {
    /*                     ^           */
      *iv_return = TDB_ERR_OOM;
      return PERL_constant_ISIV;
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
my @names = (qw(TDB_BIGENDIAN TDB_CLEAR_IF_FIRST TDB_CONVERT TDB_DEFAULT
	       TDB_INSERT TDB_INTERNAL TDB_MODIFY TDB_NOLOCK TDB_NOMMAP
	       TDB_REPLACE),
            {name=>"TDB_ERR_CORRUPT", type=>"IV", macro=>"1"},
            {name=>"TDB_ERR_EXISTS", type=>"IV", macro=>"1"},
            {name=>"TDB_ERR_IO", type=>"IV", macro=>"1"},
            {name=>"TDB_ERR_LOCK", type=>"IV", macro=>"1"},
            {name=>"TDB_ERR_LOCK_TIMEOUT", type=>"IV", macro=>"TDB_HAS_ERR_LOCK_TIMEOUT"},
            {name=>"TDB_ERR_NOEXIST", type=>"IV", macro=>"1"},
            {name=>"TDB_ERR_NOLOCK", type=>"IV", macro=>"1"},
            {name=>"TDB_ERR_OOM", type=>"IV", macro=>"1"},
            {name=>"TDB_SUCCESS", type=>"IV", macro=>"1"});

print constant_types(); # macro defs
foreach (C_constant ("TDB_File", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("TDB_File", $types);
__END__
   */

  switch (len) {
  case 10:
    return constant_10 (aTHX_ name, iv_return);
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return);
    break;
  case 12:
    /* Names all of length 12.  */
    /* TDB_ERR_LOCK TDB_INTERNAL */
    /* Offset 11 gives the best switch position.  */
    switch (name[11]) {
    case 'K':
      if (memEQ(name, "TDB_ERR_LOC", 11)) {
      /*                          K      */
        *iv_return = TDB_ERR_LOCK;
        return PERL_constant_ISIV;
      }
      break;
    case 'L':
      if (memEQ(name, "TDB_INTERNA", 11)) {
      /*                          L      */
#ifdef TDB_INTERNAL
        *iv_return = TDB_INTERNAL;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 13:
    if (memEQ(name, "TDB_BIGENDIAN", 13)) {
#ifdef TDB_BIGENDIAN
      *iv_return = TDB_BIGENDIAN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 14:
    /* Names all of length 14.  */
    /* TDB_ERR_EXISTS TDB_ERR_NOLOCK */
    /* Offset 10 gives the best switch position.  */
    switch (name[10]) {
    case 'I':
      if (memEQ(name, "TDB_ERR_EXISTS", 14)) {
      /*                         ^          */
        *iv_return = TDB_ERR_EXISTS;
        return PERL_constant_ISIV;
      }
      break;
    case 'L':
      if (memEQ(name, "TDB_ERR_NOLOCK", 14)) {
      /*                         ^          */
        *iv_return = TDB_ERR_NOLOCK;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 15:
    /* Names all of length 15.  */
    /* TDB_ERR_CORRUPT TDB_ERR_NOEXIST */
    /* Offset 13 gives the best switch position.  */
    switch (name[13]) {
    case 'P':
      if (memEQ(name, "TDB_ERR_CORRUPT", 15)) {
      /*                            ^        */
        *iv_return = TDB_ERR_CORRUPT;
        return PERL_constant_ISIV;
      }
      break;
    case 'S':
      if (memEQ(name, "TDB_ERR_NOEXIST", 15)) {
      /*                            ^        */
        *iv_return = TDB_ERR_NOEXIST;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 18:
    if (memEQ(name, "TDB_CLEAR_IF_FIRST", 18)) {
#ifdef TDB_CLEAR_IF_FIRST
      *iv_return = TDB_CLEAR_IF_FIRST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 20:
    if (memEQ(name, "TDB_ERR_LOCK_TIMEOUT", 20)) {
#ifdef TDB_HAS_ERR_LOCK_TIMEOUT
      *iv_return = TDB_ERR_LOCK_TIMEOUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

