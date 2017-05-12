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
     MAXPATHLEN SHUT_DELAY SHUT_QUICK */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'A':
    if (memEQ(name, "SHUT_DELAY", 10)) {
    /*                       ^        */
#ifdef SHUT_DELAY
      *iv_return = SHUT_DELAY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "SHUT_QUICK", 10)) {
    /*                       ^        */
#ifdef SHUT_QUICK
      *iv_return = SHUT_QUICK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "MAXPATHLEN", 10)) {
    /*                       ^        */
#ifdef MAXPATHLEN
      *iv_return = MAXPATHLEN;
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
     MGR_CMD_SET MGR_OBJ_JOB PBS_MAXDEST PBS_MAXGRPN PBS_MAXUSER PBS_USE_IFF */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'E':
    if (memEQ(name, "PBS_MAXDEST", 11)) {
    /*                       ^         */
#ifdef PBS_MAXDEST
      *iv_return = PBS_MAXDEST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "PBS_USE_IFF", 11)) {
    /*                       ^         */
#ifdef PBS_USE_IFF
      *iv_return = PBS_USE_IFF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'J':
    if (memEQ(name, "MGR_OBJ_JOB", 11)) {
    /*                       ^         */
#ifdef MGR_OBJ_JOB
      *iv_return = MGR_OBJ_JOB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "PBS_MAXGRPN", 11)) {
    /*                       ^         */
#ifdef PBS_MAXGRPN
      *iv_return = PBS_MAXGRPN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "MGR_CMD_SET", 11)) {
    /*                       ^         */
#ifdef MGR_CMD_SET
      *iv_return = MGR_CMD_SET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PBS_MAXUSER", 11)) {
    /*                       ^         */
#ifdef PBS_MAXUSER
      *iv_return = PBS_MAXUSER;
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
     MGR_CMD_LIST MGR_OBJ_NODE MGR_OBJ_NONE PBS_TERM_CCA */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'C':
    if (memEQ(name, "PBS_TERM_CCA", 12)) {
    /*                         ^        */
#ifdef PBS_TERM_CCA
      *iv_return = PBS_TERM_CCA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "MGR_OBJ_NODE", 12)) {
    /*                         ^        */
#ifdef MGR_OBJ_NODE
      *iv_return = MGR_OBJ_NODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "MGR_OBJ_NONE", 12)) {
    /*                         ^        */
#ifdef MGR_OBJ_NONE
      *iv_return = MGR_OBJ_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "MGR_CMD_LIST", 12)) {
    /*                         ^        */
#ifdef MGR_CMD_LIST
      *iv_return = MGR_CMD_LIST;
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
     MGR_CMD_PRINT MGR_CMD_UNSET MGR_OBJ_QUEUE PBS_MAXSEQNUM */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'N':
    if (memEQ(name, "MGR_CMD_UNSET", 13)) {
    /*                        ^          */
#ifdef MGR_CMD_UNSET
      *iv_return = MGR_CMD_UNSET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Q':
    if (memEQ(name, "PBS_MAXSEQNUM", 13)) {
    /*                        ^          */
#ifdef PBS_MAXSEQNUM
      *iv_return = PBS_MAXSEQNUM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "MGR_CMD_PRINT", 13)) {
    /*                        ^          */
#ifdef MGR_CMD_PRINT
      *iv_return = MGR_CMD_PRINT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "MGR_OBJ_QUEUE", 13)) {
    /*                        ^          */
#ifdef MGR_OBJ_QUEUE
      *iv_return = MGR_OBJ_QUEUE;
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
     MAX_ENCODE_BFR MGR_CMD_ACTIVE MGR_CMD_CREATE MGR_CMD_DELETE MGR_OBJ_SERVER
     PBS_MAXPORTNUM RESOURCE_T_ALL SHUT_IMMEDIATE */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'A':
    if (memEQ(name, "MGR_CMD_ACTIVE", 14)) {
    /*                       ^            */
#ifdef MGR_CMD_ACTIVE
      *iv_return = MGR_CMD_ACTIVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "MGR_CMD_CREATE", 14)) {
    /*                       ^            */
#ifdef MGR_CMD_CREATE
      *iv_return = MGR_CMD_CREATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "MAX_ENCODE_BFR", 14)) {
    /*                       ^            */
#ifdef MAX_ENCODE_BFR
      *iv_return = MAX_ENCODE_BFR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MGR_CMD_DELETE", 14)) {
    /*                       ^            */
#ifdef MGR_CMD_DELETE
      *iv_return = MGR_CMD_DELETE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "SHUT_IMMEDIATE", 14)) {
    /*                       ^            */
#ifdef SHUT_IMMEDIATE
      *iv_return = SHUT_IMMEDIATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "PBS_MAXPORTNUM", 14)) {
    /*                       ^            */
#ifdef PBS_MAXPORTNUM
      *iv_return = PBS_MAXPORTNUM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "MGR_OBJ_SERVER", 14)) {
    /*                       ^            */
#ifdef MGR_OBJ_SERVER
      *iv_return = MGR_OBJ_SERVER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "RESOURCE_T_ALL", 14)) {
    /*                       ^            */
#ifdef RESOURCE_T_ALL
      *iv_return = RESOURCE_T_ALL;
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
     PBS_INTERACTIVE PBS_MAXCLTJOBID PBS_MAXHOSTNAME PBS_MAXSVRJOBID
     PBS_TERM_BUF_SZ RESOURCE_T_NULL */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'I':
    if (memEQ(name, "PBS_MAXCLTJOBID", 15)) {
    /*                            ^        */
#ifdef PBS_MAXCLTJOBID
      *iv_return = PBS_MAXCLTJOBID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PBS_MAXSVRJOBID", 15)) {
    /*                            ^        */
#ifdef PBS_MAXSVRJOBID
      *iv_return = PBS_MAXSVRJOBID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "RESOURCE_T_NULL", 15)) {
    /*                            ^        */
#ifdef RESOURCE_T_NULL
      *iv_return = RESOURCE_T_NULL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "PBS_MAXHOSTNAME", 15)) {
    /*                            ^        */
#ifdef PBS_MAXHOSTNAME
      *iv_return = PBS_MAXHOSTNAME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "PBS_TERM_BUF_SZ", 15)) {
    /*                            ^        */
#ifdef PBS_TERM_BUF_SZ
      *iv_return = PBS_TERM_BUF_SZ;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "PBS_INTERACTIVE", 15)) {
    /*                            ^        */
#ifdef PBS_INTERACTIVE
      *iv_return = PBS_INTERACTIVE;
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

#!perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw( MAXNAMLEN MAXPATHLEN MAX_ENCODE_BFR MGR_CMD_ACTIVE
	       MGR_CMD_CREATE MGR_CMD_DELETE MGR_CMD_LIST MGR_CMD_PRINT
	       MGR_CMD_SET MGR_CMD_UNSET MGR_OBJ_JOB MGR_OBJ_NODE MGR_OBJ_NONE
	       MGR_OBJ_QUEUE MGR_OBJ_SERVER MSG_ERR MSG_OUT
	       PBS_BATCH_SERVICE_PORT PBS_BATCH_SERVICE_PORT_DIS
	       PBS_INTERACTIVE PBS_MANAGER_SERVICE_PORT PBS_MAXCLTJOBID
	       PBS_MAXDEST PBS_MAXGRPN PBS_MAXHOSTNAME PBS_MAXPORTNUM
	       PBS_MAXQUEUENAME PBS_MAXROUTEDEST PBS_MAXSEQNUM
	       PBS_MAXSERVERNAME PBS_MAXSVRJOBID PBS_MAXUSER
	       PBS_MOM_SERVICE_PORT PBS_SCHEDULER_SERVICE_PORT PBS_TERM_BUF_SZ
	       PBS_TERM_CCA PBS_USE_IFF RESOURCE_T_ALL RESOURCE_T_NULL
	       SHUT_DELAY SHUT_IMMEDIATE SHUT_QUICK SHUT_SIG));

print constant_types(); # macro defs
foreach (C_constant ("PBS", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("PBS", $types);
__END__
   */

  switch (len) {
  case 0:
    if (name[0] == '') {
#ifdef 
      *iv_return = ;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 7:
    /* Names all of length 7.  */
    /* MSG_ERR MSG_OUT */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'R':
      if (memEQ(name, "MSG_ER", 6)) {
      /*                     R     */
#ifdef MSG_ERR
        *iv_return = MSG_ERR;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "MSG_OU", 6)) {
      /*                     T     */
#ifdef MSG_OUT
        *iv_return = MSG_OUT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 8:
    if (memEQ(name, "SHUT_SIG", 8)) {
#ifdef SHUT_SIG
      *iv_return = SHUT_SIG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 9:
    if (memEQ(name, "MAXNAMLEN", 9)) {
#ifdef MAXNAMLEN
      *iv_return = MAXNAMLEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 10:
    return constant_10 (aTHX_ name, iv_return);
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
    /* Names all of length 16.  */
    /* PBS_MAXQUEUENAME PBS_MAXROUTEDEST */
    /* Offset 7 gives the best switch position.  */
    switch (name[7]) {
    case 'Q':
      if (memEQ(name, "PBS_MAXQUEUENAME", 16)) {
      /*                      ^               */
#ifdef PBS_MAXQUEUENAME
        *iv_return = PBS_MAXQUEUENAME;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'R':
      if (memEQ(name, "PBS_MAXROUTEDEST", 16)) {
      /*                      ^               */
#ifdef PBS_MAXROUTEDEST
        *iv_return = PBS_MAXROUTEDEST;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 17:
    if (memEQ(name, "PBS_MAXSERVERNAME", 17)) {
#ifdef PBS_MAXSERVERNAME
      *iv_return = PBS_MAXSERVERNAME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 20:
    if (memEQ(name, "PBS_MOM_SERVICE_PORT", 20)) {
#ifdef PBS_MOM_SERVICE_PORT
      *iv_return = PBS_MOM_SERVICE_PORT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 22:
    if (memEQ(name, "PBS_BATCH_SERVICE_PORT", 22)) {
#ifdef PBS_BATCH_SERVICE_PORT
      *iv_return = PBS_BATCH_SERVICE_PORT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 24:
    if (memEQ(name, "PBS_MANAGER_SERVICE_PORT", 24)) {
#ifdef PBS_MANAGER_SERVICE_PORT
      *iv_return = PBS_MANAGER_SERVICE_PORT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 26:
    /* Names all of length 26.  */
    /* PBS_BATCH_SERVICE_PORT_DIS PBS_SCHEDULER_SERVICE_PORT */
    /* Offset 25 gives the best switch position.  */
    switch (name[25]) {
    case 'S':
      if (memEQ(name, "PBS_BATCH_SERVICE_PORT_DI", 25)) {
      /*                                        S      */
#ifdef PBS_BATCH_SERVICE_PORT_DIS
        *iv_return = PBS_BATCH_SERVICE_PORT_DIS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "PBS_SCHEDULER_SERVICE_POR", 25)) {
      /*                                        T      */
#ifdef PBS_SCHEDULER_SERVICE_PORT
        *iv_return = PBS_SCHEDULER_SERVICE_PORT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

