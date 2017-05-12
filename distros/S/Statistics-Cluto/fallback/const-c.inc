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
     CLUTO_CLFUN_E1 CLUTO_CLFUN_G1 CLUTO_CLFUN_H1 CLUTO_CLFUN_H2 CLUTO_CLFUN_I1
     CLUTO_CLFUN_I2 CLUTO_TREE_TOP */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'E':
    if (memEQ(name, "CLUTO_CLFUN_E1", 14)) {
    /*                           ^        */
#ifdef CLUTO_CLFUN_E1
      *iv_return = CLUTO_CLFUN_E1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "CLUTO_CLFUN_G1", 14)) {
    /*                           ^        */
#ifdef CLUTO_CLFUN_G1
      *iv_return = CLUTO_CLFUN_G1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "CLUTO_CLFUN_H1", 14)) {
    /*                           ^        */
#ifdef CLUTO_CLFUN_H1
      *iv_return = CLUTO_CLFUN_H1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CLUTO_CLFUN_H2", 14)) {
    /*                           ^        */
#ifdef CLUTO_CLFUN_H2
      *iv_return = CLUTO_CLFUN_H2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CLUTO_CLFUN_I1", 14)) {
    /*                           ^        */
#ifdef CLUTO_CLFUN_I1
      *iv_return = CLUTO_CLFUN_I1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CLUTO_CLFUN_I2", 14)) {
    /*                           ^        */
#ifdef CLUTO_CLFUN_I2
      *iv_return = CLUTO_CLFUN_I2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CLUTO_TREE_TOP", 14)) {
    /*                           ^        */
#ifdef CLUTO_TREE_TOP
      *iv_return = CLUTO_TREE_TOP;
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
     CLUTO_CLFUN_CUT CLUTO_CLFUN_G1P CLUTO_MEM_REUSE CLUTO_TREE_FULL
     CLUTO_VER_MAJOR CLUTO_VER_MINOR */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'E':
    if (memEQ(name, "CLUTO_MEM_REUS", 14)) {
    /*                             E      */
#ifdef CLUTO_MEM_REUSE
      *iv_return = CLUTO_MEM_REUSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CLUTO_TREE_FUL", 14)) {
    /*                             L      */
#ifdef CLUTO_TREE_FULL
      *iv_return = CLUTO_TREE_FULL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "CLUTO_CLFUN_G1", 14)) {
    /*                             P      */
#ifdef CLUTO_CLFUN_G1P
      *iv_return = CLUTO_CLFUN_G1P;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CLUTO_VER_MAJO", 14)) {
    /*                             R      */
#ifdef CLUTO_VER_MAJOR
      *iv_return = CLUTO_VER_MAJOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CLUTO_VER_MINO", 14)) {
    /*                             R      */
#ifdef CLUTO_VER_MINOR
      *iv_return = CLUTO_VER_MINOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "CLUTO_CLFUN_CU", 14)) {
    /*                             T      */
#ifdef CLUTO_CLFUN_CUT
      *iv_return = CLUTO_CLFUN_CUT;
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
     CLUTO_CLFUN_NCUT CLUTO_CLFUN_RCUT CLUTO_SIM_COSINE */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'N':
    if (memEQ(name, "CLUTO_CLFUN_NCUT", 16)) {
    /*                           ^          */
#ifdef CLUTO_CLFUN_NCUT
      *iv_return = CLUTO_CLFUN_NCUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CLUTO_CLFUN_RCUT", 16)) {
    /*                           ^          */
#ifdef CLUTO_CLFUN_RCUT
      *iv_return = CLUTO_CLFUN_RCUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CLUTO_SIM_COSINE", 16)) {
    /*                           ^          */
#ifdef CLUTO_SIM_COSINE
      *iv_return = CLUTO_SIM_COSINE;
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
     CLUTO_CLFUN_CLINK CLUTO_CLFUN_MMCUT CLUTO_CLFUN_SLINK CLUTO_CLFUN_UPGMA
     CLUTO_MEM_NOREUSE CLUTO_MTYPE_HEDGE CLUTO_MTYPE_HSTAR */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'C':
    if (memEQ(name, "CLUTO_CLFUN_CLINK", 17)) {
    /*                           ^           */
#ifdef CLUTO_CLFUN_CLINK
      *iv_return = CLUTO_CLFUN_CLINK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "CLUTO_MTYPE_HEDGE", 17)) {
    /*                           ^           */
#ifdef CLUTO_MTYPE_HEDGE
      *iv_return = CLUTO_MTYPE_HEDGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CLUTO_MTYPE_HSTAR", 17)) {
    /*                           ^           */
#ifdef CLUTO_MTYPE_HSTAR
      *iv_return = CLUTO_MTYPE_HSTAR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "CLUTO_CLFUN_MMCUT", 17)) {
    /*                           ^           */
#ifdef CLUTO_CLFUN_MMCUT
      *iv_return = CLUTO_CLFUN_MMCUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CLUTO_MEM_NOREUSE", 17)) {
    /*                           ^           */
#ifdef CLUTO_MEM_NOREUSE
      *iv_return = CLUTO_MEM_NOREUSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "CLUTO_CLFUN_SLINK", 17)) {
    /*                           ^           */
#ifdef CLUTO_CLFUN_SLINK
      *iv_return = CLUTO_CLFUN_SLINK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "CLUTO_CLFUN_UPGMA", 17)) {
    /*                           ^           */
#ifdef CLUTO_CLFUN_UPGMA
      *iv_return = CLUTO_CLFUN_UPGMA;
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
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CLUTO_COLMODEL_IDF CLUTO_DBG_CCMPSTAT CLUTO_DBG_PROGRESS
     CLUTO_GRMODEL_NONE CLUTO_MTYPE_HSTAR2 CLUTO_ROWMODEL_LOG
     CLUTO_SIM_CORRCOEF CLUTO_SIM_EJACCARD CLUTO_VER_SUBMINOR */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'A':
    if (memEQ(name, "CLUTO_SIM_EJACCARD", 18)) {
    /*                           ^            */
#ifdef CLUTO_SIM_EJACCARD
      *iv_return = CLUTO_SIM_EJACCARD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "CLUTO_VER_SUBMINOR", 18)) {
    /*                           ^            */
#ifdef CLUTO_VER_SUBMINOR
      *iv_return = CLUTO_VER_SUBMINOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CLUTO_COLMODEL_IDF", 18)) {
    /*                           ^            */
#ifdef CLUTO_COLMODEL_IDF
      *iv_return = CLUTO_COLMODEL_IDF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CLUTO_ROWMODEL_LOG", 18)) {
    /*                           ^            */
#ifdef CLUTO_ROWMODEL_LOG
      *iv_return = CLUTO_ROWMODEL_LOG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "CLUTO_MTYPE_HSTAR2", 18)) {
    /*                           ^            */
#ifdef CLUTO_MTYPE_HSTAR2
      *iv_return = CLUTO_MTYPE_HSTAR2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CLUTO_GRMODEL_NONE", 18)) {
    /*                           ^            */
#ifdef CLUTO_GRMODEL_NONE
      *iv_return = CLUTO_GRMODEL_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "CLUTO_DBG_CCMPSTAT", 18)) {
    /*                           ^            */
#ifdef CLUTO_DBG_CCMPSTAT
      *iv_return = CLUTO_DBG_CCMPSTAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CLUTO_DBG_PROGRESS", 18)) {
    /*                           ^            */
#ifdef CLUTO_DBG_PROGRESS
      *iv_return = CLUTO_DBG_PROGRESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CLUTO_SIM_CORRCOEF", 18)) {
    /*                           ^            */
#ifdef CLUTO_SIM_CORRCOEF
      *iv_return = CLUTO_SIM_CORRCOEF;
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
constant_19 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CLUTO_CLFUN_CLINK_W CLUTO_CLFUN_SLINK_W CLUTO_CLFUN_UPGMA_W
     CLUTO_COLMODEL_NONE CLUTO_DBG_APROGRESS CLUTO_DBG_CPROGRESS
     CLUTO_DBG_MPROGRESS CLUTO_DBG_RPROGRESS CLUTO_ROWMODEL_NONE
     CLUTO_ROWMODEL_SQRT CLUTO_SIM_EDISTANCE */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'A':
    if (memEQ(name, "CLUTO_DBG_APROGRESS", 19)) {
    /*                         ^               */
#ifdef CLUTO_DBG_APROGRESS
      *iv_return = CLUTO_DBG_APROGRESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "CLUTO_DBG_CPROGRESS", 19)) {
    /*                         ^               */
#ifdef CLUTO_DBG_CPROGRESS
      *iv_return = CLUTO_DBG_CPROGRESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "CLUTO_SIM_EDISTANCE", 19)) {
    /*                         ^               */
#ifdef CLUTO_SIM_EDISTANCE
      *iv_return = CLUTO_SIM_EDISTANCE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "CLUTO_DBG_MPROGRESS", 19)) {
    /*                         ^               */
#ifdef CLUTO_DBG_MPROGRESS
      *iv_return = CLUTO_DBG_MPROGRESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "CLUTO_CLFUN_CLINK_W", 19)) {
    /*                         ^               */
#ifdef CLUTO_CLFUN_CLINK_W
      *iv_return = CLUTO_CLFUN_CLINK_W;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CLUTO_CLFUN_SLINK_W", 19)) {
    /*                         ^               */
#ifdef CLUTO_CLFUN_SLINK_W
      *iv_return = CLUTO_CLFUN_SLINK_W;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CLUTO_CLFUN_UPGMA_W", 19)) {
    /*                         ^               */
#ifdef CLUTO_CLFUN_UPGMA_W
      *iv_return = CLUTO_CLFUN_UPGMA_W;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CLUTO_COLMODEL_NONE", 19)) {
    /*                         ^               */
#ifdef CLUTO_COLMODEL_NONE
      *iv_return = CLUTO_COLMODEL_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CLUTO_ROWMODEL_NONE", 19)) {
    /*                         ^               */
#ifdef CLUTO_ROWMODEL_NONE
      *iv_return = CLUTO_ROWMODEL_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "CLUTO_ROWMODEL_SQRT", 19)) {
    /*                         ^               */
#ifdef CLUTO_ROWMODEL_SQRT
      *iv_return = CLUTO_ROWMODEL_SQRT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CLUTO_DBG_RPROGRESS", 19)) {
    /*                         ^               */
#ifdef CLUTO_DBG_RPROGRESS
      *iv_return = CLUTO_DBG_RPROGRESS;
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
my @names = (qw(CLUTO_CLFUN_CLINK CLUTO_CLFUN_CLINK_W CLUTO_CLFUN_CUT
	       CLUTO_CLFUN_E1 CLUTO_CLFUN_G1 CLUTO_CLFUN_G1P CLUTO_CLFUN_H1
	       CLUTO_CLFUN_H2 CLUTO_CLFUN_I1 CLUTO_CLFUN_I2 CLUTO_CLFUN_MMCUT
	       CLUTO_CLFUN_NCUT CLUTO_CLFUN_RCUT CLUTO_CLFUN_SLINK
	       CLUTO_CLFUN_SLINK_W CLUTO_CLFUN_UPGMA CLUTO_CLFUN_UPGMA_W
	       CLUTO_COLMODEL_IDF CLUTO_COLMODEL_NONE CLUTO_CSTYPE_BESTFIRST
	       CLUTO_CSTYPE_LARGEFIRST CLUTO_CSTYPE_LARGESUBSPACEFIRST
	       CLUTO_DBG_APROGRESS CLUTO_DBG_CCMPSTAT CLUTO_DBG_CPROGRESS
	       CLUTO_DBG_MPROGRESS CLUTO_DBG_PROGRESS CLUTO_DBG_RPROGRESS
	       CLUTO_GRMODEL_ASYMETRIC_DIRECT CLUTO_GRMODEL_ASYMETRIC_LINKS
	       CLUTO_GRMODEL_EXACT_ASYMETRIC_DIRECT
	       CLUTO_GRMODEL_EXACT_ASYMETRIC_LINKS
	       CLUTO_GRMODEL_EXACT_SYMETRIC_DIRECT
	       CLUTO_GRMODEL_EXACT_SYMETRIC_LINKS
	       CLUTO_GRMODEL_INEXACT_ASYMETRIC_DIRECT
	       CLUTO_GRMODEL_INEXACT_ASYMETRIC_LINKS
	       CLUTO_GRMODEL_INEXACT_SYMETRIC_DIRECT
	       CLUTO_GRMODEL_INEXACT_SYMETRIC_LINKS CLUTO_GRMODEL_NONE
	       CLUTO_GRMODEL_SYMETRIC_DIRECT CLUTO_GRMODEL_SYMETRIC_LINKS
	       CLUTO_MEM_NOREUSE CLUTO_MEM_REUSE CLUTO_MTYPE_HEDGE
	       CLUTO_MTYPE_HSTAR CLUTO_MTYPE_HSTAR2 CLUTO_OPTIMIZER_MULTILEVEL
	       CLUTO_OPTIMIZER_SINGLELEVEL CLUTO_ROWMODEL_LOG
	       CLUTO_ROWMODEL_MAXTF CLUTO_ROWMODEL_NONE CLUTO_ROWMODEL_SQRT
	       CLUTO_SIM_CORRCOEF CLUTO_SIM_COSINE CLUTO_SIM_EDISTANCE
	       CLUTO_SIM_EJACCARD CLUTO_SUMMTYPE_MAXCLIQUES
	       CLUTO_SUMMTYPE_MAXITEMSETS CLUTO_TREE_FULL CLUTO_TREE_TOP
	       CLUTO_VER_MAJOR CLUTO_VER_MINOR CLUTO_VER_SUBMINOR));

print constant_types(); # macro defs
foreach (C_constant ("Statistics::Cluto", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Statistics::Cluto", $types);
__END__
   */

  switch (len) {
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
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    return constant_19 (aTHX_ name, iv_return);
    break;
  case 20:
    if (memEQ(name, "CLUTO_ROWMODEL_MAXTF", 20)) {
#ifdef CLUTO_ROWMODEL_MAXTF
      *iv_return = CLUTO_ROWMODEL_MAXTF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 22:
    if (memEQ(name, "CLUTO_CSTYPE_BESTFIRST", 22)) {
#ifdef CLUTO_CSTYPE_BESTFIRST
      *iv_return = CLUTO_CSTYPE_BESTFIRST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 23:
    if (memEQ(name, "CLUTO_CSTYPE_LARGEFIRST", 23)) {
#ifdef CLUTO_CSTYPE_LARGEFIRST
      *iv_return = CLUTO_CSTYPE_LARGEFIRST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 25:
    if (memEQ(name, "CLUTO_SUMMTYPE_MAXCLIQUES", 25)) {
#ifdef CLUTO_SUMMTYPE_MAXCLIQUES
      *iv_return = CLUTO_SUMMTYPE_MAXCLIQUES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 26:
    /* Names all of length 26.  */
    /* CLUTO_OPTIMIZER_MULTILEVEL CLUTO_SUMMTYPE_MAXITEMSETS */
    /* Offset 21 gives the best switch position.  */
    switch (name[21]) {
    case 'L':
      if (memEQ(name, "CLUTO_OPTIMIZER_MULTILEVEL", 26)) {
      /*                                    ^           */
#ifdef CLUTO_OPTIMIZER_MULTILEVEL
        *iv_return = CLUTO_OPTIMIZER_MULTILEVEL;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'M':
      if (memEQ(name, "CLUTO_SUMMTYPE_MAXITEMSETS", 26)) {
      /*                                    ^           */
#ifdef CLUTO_SUMMTYPE_MAXITEMSETS
        *iv_return = CLUTO_SUMMTYPE_MAXITEMSETS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 27:
    if (memEQ(name, "CLUTO_OPTIMIZER_SINGLELEVEL", 27)) {
#ifdef CLUTO_OPTIMIZER_SINGLELEVEL
      *iv_return = CLUTO_OPTIMIZER_SINGLELEVEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 28:
    if (memEQ(name, "CLUTO_GRMODEL_SYMETRIC_LINKS", 28)) {
#ifdef CLUTO_GRMODEL_SYMETRIC_LINKS
      *iv_return = CLUTO_GRMODEL_SYMETRIC_LINKS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 29:
    /* Names all of length 29.  */
    /* CLUTO_GRMODEL_ASYMETRIC_LINKS CLUTO_GRMODEL_SYMETRIC_DIRECT */
    /* Offset 28 gives the best switch position.  */
    switch (name[28]) {
    case 'S':
      if (memEQ(name, "CLUTO_GRMODEL_ASYMETRIC_LINK", 28)) {
      /*                                           S      */
#ifdef CLUTO_GRMODEL_ASYMETRIC_LINKS
        *iv_return = CLUTO_GRMODEL_ASYMETRIC_LINKS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "CLUTO_GRMODEL_SYMETRIC_DIREC", 28)) {
      /*                                           T      */
#ifdef CLUTO_GRMODEL_SYMETRIC_DIRECT
        *iv_return = CLUTO_GRMODEL_SYMETRIC_DIRECT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 30:
    if (memEQ(name, "CLUTO_GRMODEL_ASYMETRIC_DIRECT", 30)) {
#ifdef CLUTO_GRMODEL_ASYMETRIC_DIRECT
      *iv_return = CLUTO_GRMODEL_ASYMETRIC_DIRECT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 31:
    if (memEQ(name, "CLUTO_CSTYPE_LARGESUBSPACEFIRST", 31)) {
#ifdef CLUTO_CSTYPE_LARGESUBSPACEFIRST
      *iv_return = CLUTO_CSTYPE_LARGESUBSPACEFIRST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 34:
    if (memEQ(name, "CLUTO_GRMODEL_EXACT_SYMETRIC_LINKS", 34)) {
#ifdef CLUTO_GRMODEL_EXACT_SYMETRIC_LINKS
      *iv_return = CLUTO_GRMODEL_EXACT_SYMETRIC_LINKS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 35:
    /* Names all of length 35.  */
    /* CLUTO_GRMODEL_EXACT_ASYMETRIC_LINKS CLUTO_GRMODEL_EXACT_SYMETRIC_DIRECT
       */
    /* Offset 34 gives the best switch position.  */
    switch (name[34]) {
    case 'S':
      if (memEQ(name, "CLUTO_GRMODEL_EXACT_ASYMETRIC_LINK", 34)) {
      /*                                                 S      */
#ifdef CLUTO_GRMODEL_EXACT_ASYMETRIC_LINKS
        *iv_return = CLUTO_GRMODEL_EXACT_ASYMETRIC_LINKS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "CLUTO_GRMODEL_EXACT_SYMETRIC_DIREC", 34)) {
      /*                                                 T      */
#ifdef CLUTO_GRMODEL_EXACT_SYMETRIC_DIRECT
        *iv_return = CLUTO_GRMODEL_EXACT_SYMETRIC_DIRECT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 36:
    /* Names all of length 36.  */
    /* CLUTO_GRMODEL_EXACT_ASYMETRIC_DIRECT
       CLUTO_GRMODEL_INEXACT_SYMETRIC_LINKS */
    /* Offset 35 gives the best switch position.  */
    switch (name[35]) {
    case 'S':
      if (memEQ(name, "CLUTO_GRMODEL_INEXACT_SYMETRIC_LINK", 35)) {
      /*                                                  S      */
#ifdef CLUTO_GRMODEL_INEXACT_SYMETRIC_LINKS
        *iv_return = CLUTO_GRMODEL_INEXACT_SYMETRIC_LINKS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "CLUTO_GRMODEL_EXACT_ASYMETRIC_DIREC", 35)) {
      /*                                                  T      */
#ifdef CLUTO_GRMODEL_EXACT_ASYMETRIC_DIRECT
        *iv_return = CLUTO_GRMODEL_EXACT_ASYMETRIC_DIRECT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 37:
    /* Names all of length 37.  */
    /* CLUTO_GRMODEL_INEXACT_ASYMETRIC_LINKS
       CLUTO_GRMODEL_INEXACT_SYMETRIC_DIRECT */
    /* Offset 36 gives the best switch position.  */
    switch (name[36]) {
    case 'S':
      if (memEQ(name, "CLUTO_GRMODEL_INEXACT_ASYMETRIC_LINK", 36)) {
      /*                                                   S      */
#ifdef CLUTO_GRMODEL_INEXACT_ASYMETRIC_LINKS
        *iv_return = CLUTO_GRMODEL_INEXACT_ASYMETRIC_LINKS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "CLUTO_GRMODEL_INEXACT_SYMETRIC_DIREC", 36)) {
      /*                                                   T      */
#ifdef CLUTO_GRMODEL_INEXACT_SYMETRIC_DIRECT
        *iv_return = CLUTO_GRMODEL_INEXACT_SYMETRIC_DIRECT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 38:
    if (memEQ(name, "CLUTO_GRMODEL_INEXACT_ASYMETRIC_DIRECT", 38)) {
#ifdef CLUTO_GRMODEL_INEXACT_ASYMETRIC_DIRECT
      *iv_return = CLUTO_GRMODEL_INEXACT_ASYMETRIC_DIRECT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

