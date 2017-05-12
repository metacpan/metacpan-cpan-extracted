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
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     HWLOC_OBJ_CORE HWLOC_OBJ_MISC HWLOC_OBJ_NODE */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'C':
    if (memEQ(name, "HWLOC_OBJ_CORE", 14)) {
    /*                         ^          */
      *iv_return = HWLOC_OBJ_CORE;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "HWLOC_OBJ_MISC", 14)) {
    /*                         ^          */
      *iv_return = HWLOC_OBJ_MISC;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "HWLOC_OBJ_NODE", 14)) {
    /*                         ^          */
      *iv_return = HWLOC_OBJ_NODE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_20 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     HWLOC_CPUBIND_STRICT HWLOC_CPUBIND_THREAD HWLOC_TYPE_UNORDERED */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'R':
    if (memEQ(name, "HWLOC_TYPE_UNORDERED", 20)) {
    /*                             ^            */
      *iv_return = HWLOC_TYPE_UNORDERED;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "HWLOC_CPUBIND_STRICT", 20)) {
    /*                             ^            */
      *iv_return = HWLOC_CPUBIND_STRICT;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "HWLOC_CPUBIND_THREAD", 20)) {
    /*                             ^            */
      *iv_return = HWLOC_CPUBIND_THREAD;
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
my @names = (qw(),
            {name=>"HWLOC_CPUBIND_PROCESS", type=>"IV", macro=>"1"},
            {name=>"HWLOC_CPUBIND_STRICT", type=>"IV", macro=>"1"},
            {name=>"HWLOC_CPUBIND_THREAD", type=>"IV", macro=>"1"},
            {name=>"HWLOC_HAS_XML", type=>"IV", macro=>"1"},
            {name=>"HWLOC_OBJ_CACHE", type=>"IV", macro=>"1"},
            {name=>"HWLOC_OBJ_CORE", type=>"IV", macro=>"1"},
            {name=>"HWLOC_OBJ_GROUP", type=>"IV", macro=>"1"},
            {name=>"HWLOC_OBJ_MACHINE", type=>"IV", macro=>"1"},
            {name=>"HWLOC_OBJ_MISC", type=>"IV", macro=>"1"},
            {name=>"HWLOC_OBJ_NODE", type=>"IV", macro=>"1"},
            {name=>"HWLOC_OBJ_PU", type=>"IV", macro=>"1"},
            {name=>"HWLOC_OBJ_SOCKET", type=>"IV", macro=>"1"},
            {name=>"HWLOC_OBJ_SYSTEM", type=>"IV", macro=>"1"},
            {name=>"HWLOC_TOPOLOGY_FLAG_IS_THISSYSTEM", type=>"IV", macro=>"1"},
            {name=>"HWLOC_TOPOLOGY_FLAG_WHOLE_SYSTEM", type=>"IV", macro=>"1"},
            {name=>"HWLOC_TYPE_DEPTH_MULTIPLE", type=>"IV", macro=>"1"},
            {name=>"HWLOC_TYPE_DEPTH_UNKNOWN", type=>"IV", macro=>"1"},
            {name=>"HWLOC_TYPE_UNORDERED", type=>"IV", macro=>"1"});

print constant_types(); # macro defs
foreach (C_constant ("Sys::Hwloc", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Sys::Hwloc", $types);
__END__
   */

  switch (len) {
  case 12:
    if (memEQ(name, "HWLOC_OBJ_PU", 12)) {
      *iv_return = HWLOC_OBJ_PU;
      return PERL_constant_ISIV;
    }
    break;
  case 13:
    if (memEQ(name, "HWLOC_HAS_XML", 13)) {
      *iv_return = HWLOC_HAS_XML;
      return PERL_constant_ISIV;
    }
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    /* Names all of length 15.  */
    /* HWLOC_OBJ_CACHE HWLOC_OBJ_GROUP */
    /* Offset 10 gives the best switch position.  */
    switch (name[10]) {
    case 'C':
      if (memEQ(name, "HWLOC_OBJ_CACHE", 15)) {
      /*                         ^           */
        *iv_return = HWLOC_OBJ_CACHE;
        return PERL_constant_ISIV;
      }
      break;
    case 'G':
      if (memEQ(name, "HWLOC_OBJ_GROUP", 15)) {
      /*                         ^           */
        *iv_return = HWLOC_OBJ_GROUP;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 16:
    /* Names all of length 16.  */
    /* HWLOC_OBJ_SOCKET HWLOC_OBJ_SYSTEM */
    /* Offset 15 gives the best switch position.  */
    switch (name[15]) {
    case 'M':
      if (memEQ(name, "HWLOC_OBJ_SYSTE", 15)) {
      /*                              M      */
        *iv_return = HWLOC_OBJ_SYSTEM;
        return PERL_constant_ISIV;
      }
      break;
    case 'T':
      if (memEQ(name, "HWLOC_OBJ_SOCKE", 15)) {
      /*                              T      */
        *iv_return = HWLOC_OBJ_SOCKET;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 17:
    if (memEQ(name, "HWLOC_OBJ_MACHINE", 17)) {
      *iv_return = HWLOC_OBJ_MACHINE;
      return PERL_constant_ISIV;
    }
    break;
  case 20:
    return constant_20 (aTHX_ name, iv_return);
    break;
  case 21:
    if (memEQ(name, "HWLOC_CPUBIND_PROCESS", 21)) {
      *iv_return = HWLOC_CPUBIND_PROCESS;
      return PERL_constant_ISIV;
    }
    break;
  case 24:
    if (memEQ(name, "HWLOC_TYPE_DEPTH_UNKNOWN", 24)) {
      *iv_return = HWLOC_TYPE_DEPTH_UNKNOWN;
      return PERL_constant_ISIV;
    }
    break;
  case 25:
    if (memEQ(name, "HWLOC_TYPE_DEPTH_MULTIPLE", 25)) {
      *iv_return = HWLOC_TYPE_DEPTH_MULTIPLE;
      return PERL_constant_ISIV;
    }
    break;
  case 32:
    if (memEQ(name, "HWLOC_TOPOLOGY_FLAG_WHOLE_SYSTEM", 32)) {
      *iv_return = HWLOC_TOPOLOGY_FLAG_WHOLE_SYSTEM;
      return PERL_constant_ISIV;
    }
    break;
  case 33:
    if (memEQ(name, "HWLOC_TOPOLOGY_FLAG_IS_THISSYSTEM", 33)) {
      *iv_return = HWLOC_TOPOLOGY_FLAG_IS_THISSYSTEM;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

