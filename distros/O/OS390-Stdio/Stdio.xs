/*
 * OS390::Stdio - MVS extensions to stdio routines 
 *
 * Author:   Peter Prymmer  pvhp@pvhp.best.vwh.net
 * Version:  0.008
 * Revised:  06-Oct-2002
 * Revised:  30-Sep-2002
 * Version:  0.006
 * Revised:  25-May-2001
 * Version:  0.005
 * Revised:  17-May-2001
 * Version:  0.004
 * Revised:  14-Apr-2001
 * Version:  0.003
 * Revised:  10-Apr-1999
 * Version:  0.001
 * Revised:  31-Aug-1998
 *           (based on VMS::Stdio V. 2.1 by Charles Bailey)
 *
 * sync() is primarily POSIX, fsync() only takes an int fildes
 * hence OS390::Stdio::sync() cannot be implemented.
 *
 * stat() tends to deal only with POSIX file structures such as
 * struct stat in <sys/stat.h>, hence OS390::Stdio::stat() cannot be 
 * implemented (use sysdsnr() instead).
 *
 * both opendir() and __opendir2() seem to not like data sets.
 *
 */

/* 
 * We won't need to resort to this pragma if we set _EXT and compile with
 * c89 -DOEMVS -D_OE_SOCKETS -D_XOPEN_SOURCE_EXTENDED -D_ALL_SOURCE 
 * #pragma LANGLVL(EXTENDED)
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
/* allow POSIX extensions (?) */
#define _EXT 1
#include <sys/file.h>
/* O_* constants */
#include <fcntl.h>
#include <stdio.h>
/* dynit.h for __dyn_t, dyninit(), dynalloc(), and dynfree() */
#include <dynit.h>
/* for pds_mem() */
#include <string.h>
#include <stdlib.h>
/* errno.h for __errno2() as used by smf_record */
#include <errno.h>

/*
 *  Note that FILENAME_MAX is defined in stdio.h to be
 *  either 1000 or 64, but this appears to not be quite 
 *  what we want since:
 *
 *  //A2345678.B2345678.C2345678.GxxxxVyy
 *  //A2345678.B2345678.C2345678.D2345678(12345678)
 *  12345678901234567890123456789012345678901234567
 *           1         2         3         4
 *
 * So let us go with:
 *
 */

#define MAXOSFILENAME 100

/*
 * OS390_STDIO_SVC99_TEXT_UNITS is the upper limit on the number 
 * of text units to pass into svc99().
 * OS390_STDIO_SVC99_MASK is involved with an "end of text units" flag.
 */
#define OS390_STDIO_SVC99_TEXT_UNITS 25
#define OS390_STDIO_SVC99_MASK 0x80000000

static bool
constant(name, pval)
char *name;
IV *pval;
{

/*
 * This is where s/^_+// takes place.
 *
 *   while (*name == '_') { name++; }
 */

/*
 * The KEY_* and RBA_* constants are used with vsam type
 * functions such as flocate() et alia.
 * The definitions are "usually" found in /usr/include/stdio.h
 *
 */
    if (strEQ(name, "KEY_FIRST"))
#ifdef __KEY_FIRST
	{ *pval = __KEY_FIRST; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "KEY_LAST"))
#ifdef __KEY_LAST
	{ *pval = __KEY_LAST; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "KEY_EQ"))
#ifdef __KEY_EQ
	{ *pval = __KEY_EQ; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "KEY_EQ_BWD"))
#ifdef __KEY_EQ_BWD
	{ *pval = __KEY_EQ_BWD; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "KEY_GE"))
#ifdef __KEY_GE
	{ *pval = __KEY_GE; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "RBA_EQ"))
#ifdef __RBA_EQ
	{ *pval = __RBA_EQ; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "RBA_EQ_BWD"))
#ifdef __RBA_EQ_BWD
	{ *pval = __RBA_EQ_BWD; return TRUE; }
#else
	return FALSE;
#endif

/*
 * The O_ constants are typically used with open() rather than fopen()
 * (hence they may not be too useful here).
 * The definitions are "usually" found in /usr/include/fcntl.h
 *
 */
    if (strEQ(name, "O_APPEND"))
#ifdef O_APPEND
	{ *pval = O_APPEND; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "O_CREAT"))
#ifdef O_CREAT
	{ *pval = O_CREAT; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "O_EXCL"))
#ifdef O_EXCL
	{ *pval = O_EXCL; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "O_NDELAY"))
#ifdef O_NDELAY
	{ *pval = O_NDELAY; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "O_NOWAIT"))
#ifdef O_NOWAIT
	{ *pval = O_NOWAIT; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "O_RDONLY"))
#ifdef O_RDONLY
	{ *pval = O_RDONLY; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "O_RDWR"))
#ifdef O_RDWR
	{ *pval = O_RDWR; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "O_TRUNC"))
#ifdef O_TRUNC
	{ *pval = O_TRUNC; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "O_WRONLY"))
#ifdef O_WRONLY
	{ *pval = O_WRONLY; return TRUE; }
#else
	return FALSE;
#endif

/*
 * __dyn_t constants for use with dyninit()/dynalloc()/dynfree()
 * The definitions are "usually" found in /usr/include/dynit.h
 *
 */
    if (strEQ(name, "ALCUNIT_CYL"))    /* alcunit CYLINDER */
#ifdef __CYL
	{ *pval = __CYL; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "ALCUNIT_TRK"))    /* alcunit TRACK */
#ifdef __TRK
	{ *pval = __TRK; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "DISP_OLD"))       /* status STATUS=OLD */
#ifdef __DISP_OLD
	{ *pval = __DISP_OLD; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "DISP_MOD"))       /* status STATUS=MOD */
#ifdef __DISP_MOD
	{ *pval = __DISP_MOD; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "DISP_NEW"))       /* status STATUS=NEW */
#ifdef __DISP_NEW
	{ *pval = __DISP_NEW; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "DISP_SHR"))       /* status STATUS=SHR */
#ifdef __DISP_SHR
	{ *pval = __DISP_SHR; return TRUE; }
#else
	return FALSE;
#endif
/* normdisp, conddisp  */
    if (strEQ(name, "DISP_UNCATLG"))   /* normdisp, conddisp  DISP=UNCATALOG */
#ifdef __DISP_UNCATLG
        { *pval = __DISP_UNCATLG; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "DISP_CATLG"))     /* normdisp, conddisp  DISP=CATALOG */
#ifdef __DISP_CATLG
        { *pval = __DISP_CATLG; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "DISP_DELETE"))    /* normdisp, conddisp  DISP=DELETE */
#ifdef __DISP_DELETE
        { *pval = __DISP_DELETE; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "DISP_KEEP"))      /* normdisp, conddisp  DISP=KEEP */
#ifdef __DISP_KEEP
        { *pval = __DISP_KEEP; return TRUE; }
#else
        return FALSE;
#endif
/* dsorg  */
    if (strEQ(name, "DSORG_unknown"))  /* dsorg  DSORG=UNKNOWN */
#ifdef __DSORG_unknown
        { *pval = __DSORG_unknown; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "DSORG_VSAM"))     /* dsorg  DSORG=VSAM */
#ifdef __DSORG_VSAM
        { *pval = __DSORG_VSAM; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "DSORG_GS"))       /* dsorg  DSORG=GS */
#ifdef __DSORG_GS
        { *pval = __DSORG_GS; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "DSORG_PO"))       /* dsorg  DSORG=PO */
#ifdef __DSORG_PO
        { *pval = __DSORG_PO; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "DSORG_POU"))      /* dsorg  DSORG=POU */
#ifdef __DSORG_POU
        { *pval = __DSORG_POU; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "DSORG_DA"))       /* dsorg  DSORG=DA */
#ifdef __DSORG_DA
        { *pval = __DSORG_DA; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "DSORG_DAU"))      /* dsorg  DSORG=DAU */
#ifdef __DSORG_DAU
        { *pval = __DSORG_DAU; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "DSORG_PS"))       /* dsorg  DSORG=PS */
#ifdef __DSORG_PS
        { *pval = __DSORG_PS; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "DSORG_PSU"))      /* dsorg  DSORG=PSU */
#ifdef __DSORG_PSU
        { *pval = __DSORG_PSU; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "DSORG_IS"))       /* dsorg  DSORG=IS */
#ifdef __DSORG_IS
        { *pval = __DSORG_IS; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "DSORG_ISU"))      /* dsorg  DSORG=ISU */
#ifdef __DSORG_ISU
        { *pval = __DSORG_ISU; return TRUE; }
#else
        return FALSE;
#endif
/* recfm */
    if (strEQ(name, "RECFM_M"))        /* recfm  M */
#ifdef _M_
	{ *pval = _M_; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "RECFM_A"))        /* recfm  A */
#ifdef _A_
	{ *pval = _A_; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "RECFM_S"))        /* recfm  S */
#ifdef _S_
	{ *pval = _S_; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "RECFM_B"))        /* recfm  B */
#ifdef _B_
	{ *pval = _B_; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "RECFM_D"))        /* recfm  D */
#ifdef _D_
	{ *pval = _D_; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "RECFM_V"))        /* recfm  V */
#ifdef _V_
	{ *pval = _V_; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "RECFM_F"))        /* recfm  FIXED */
#ifdef _F_
	{ *pval = _F_; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "RECFM_U"))        /* recfm  U */
#ifdef _U_
	{ *pval = _U_; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "RECFM_FB"))       /* recfm  FIXED BLOCK */
#ifdef _FB_
	{ *pval = _FB_; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "RECFM_VB"))       /* recfm  VB */
#ifdef _VB_
	{ *pval = _VB_; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "RECFM_FBS"))      /* recfm  FBS */
#ifdef _FBS_
	{ *pval = _FBS_; return TRUE; }
#else
	return FALSE;
#endif
    if (strEQ(name, "RECFM_VBS"))      /* recfm  VBS */
#ifdef _VBS_
	{ *pval = _VBS_; return TRUE; }
#else
	return FALSE;
#endif
/* miscflags  */
    if (strEQ(name, "MISCFL_CLOSE"))   /* miscflags  CLOSE */
#ifdef __CLOSE
        { *pval = __CLOSE; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "MISCFL_RELEASE")) /* miscflags  RELEASE */
#ifdef __RELEASE
        { *pval = __RELEASE; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "MISCFL_PERM"))    /* miscflags  PERM */
#ifdef __PERM
        { *pval = __PERM; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "MISCFL_CONTIG"))  /* miscflags  CONTIG */
#ifdef __CONTIG
        { *pval = __CONTIG; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "MISCFL_ROUND"))   /* miscflags  ROUND */
#ifdef __ROUND
        { *pval = __ROUND; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "MISCFL_TERM"))    /* miscflags  TERM */
#ifdef __TERM
        { *pval = __TERM; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "MISCFL_DUMMY_DSN")) /* miscflags  DUMMY_DSN */
#ifdef __DUMMY_DSN
        { *pval = __DUMMY_DSN; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "MISCFL_HOLDQ"))   /* miscflags  HOLDQ */
#ifdef __HOLDQ
        { *pval = __HOLDQ; return TRUE; }
#else
        return FALSE;
#endif
/* vsam record organization  */
    if (strEQ(name, "VSAM_KS"))        /* vsam record organization  KS */
#ifdef __KS
        { *pval = __KS; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "VSAM_ES"))        /* vsam record organization  ES */
#ifdef __ES
        { *pval = __ES; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "VSAM_RR"))        /* vsam record organization  RR */
#ifdef __RR
        { *pval = __RR; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "VSAM_LS"))        /* vsam record organization  LS */
#ifdef __LS
        { *pval = __LS; return TRUE; }
#else
        return FALSE;
#endif
/* pds type attributes  */
    if (strEQ(name, "DSNT_HFS"))       /* pds type attributes  DSNT_HFS */
#ifdef __DSNT_HFS
        { *pval = __DSNT_HFS; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "DSNT_PIPE"))      /* pds type attributes  DSNT_PIPE */
#ifdef __DSNT_PIPE
        { *pval = __DSNT_PIPE; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "DSNT_PDS"))       /* pds type attributes  DSNT_PDS */
#ifdef __DSNT_PDS
        { *pval = __DSNT_PDS; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "DSNT_LIBRARY"))   /* pds type attributes  DSNT_LIBRARY */
#ifdef __DSNT_LIBRARY
        { *pval = __DSNT_LIBRARY; return TRUE; }
#else
        return FALSE;
#endif
/* path options */
    if (strEQ(name, "PATH_OCREAT"))    /* path options  PATH_OCREAT */
#ifdef __PATH_OCREAT
        { *pval = __PATH_OCREAT; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_OEXCL"))     /* path options  PATH_OEXCL */
#ifdef __PATH_OEXCL
        { *pval = __PATH_OEXCL; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_ONOCTTY"))   /* path options  PATH_ONOCTTY */
#ifdef __PATH_ONOCTTY
        { *pval = __PATH_ONOCTTY; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_OTRUNC"))    /* path options  PATH_OTRUNC */
#ifdef __PATH_OTRUNC
        { *pval = __PATH_OTRUNC; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_OAPPEND"))   /* path options  PATH_OAPPEND */
#ifdef __PATH_OAPPEND
        { *pval = __PATH_OAPPEND; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_ONONBLOCK")) /* path options  PATH_ONONBLOCK */
#ifdef __PATH_ONONBLOCK
        { *pval = __PATH_ONONBLOCK; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_ORDWR"))     /* path options  PATH_ORDWR */
#ifdef __PATH_ORDWR
        { *pval = __PATH_ORDWR; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_ORDONLY"))   /* path options  PATH_ORDONLY */
#ifdef __PATH_ORDONLY
        { *pval = __PATH_ORDONLY; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_OWRONLY"))   /* path options  PATH_OWRONLY */
#ifdef __PATH_OWRONLY
        { *pval = __PATH_OWRONLY; return TRUE; }
#else
        return FALSE;
#endif
/* path attributes  */
    if (strEQ(name, "PATH_SISUID"))    /* path attributes  PATH_SISUID */
#ifdef __PATH_SISUID
        { *pval = __PATH_SISUID; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_SISGID"))    /* path attributes  PATH_SISGID */
#ifdef __PATH_SISGID
        { *pval = __PATH_SISGID; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_SIRUSR"))    /* path attributes  PATH_SIRUSR */
#ifdef __PATH_SIRUSR
        { *pval = __PATH_SIRUSR; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_SIWUSR"))    /* path attributes  PATH_SIWUSR */
#ifdef __PATH_SIWUSR
        { *pval = __PATH_SIWUSR; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_SIXUSR"))    /* path attributes  PATH_SIXUSR */
#ifdef __PATH_SIXUSR
        { *pval = __PATH_SIXUSR; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_SIRWXU"))    /* path attributes  PATH_SIRWXU */
#ifdef __PATH_SIRWXU
        { *pval = __PATH_SIRWXU; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_SIRGRP"))    /* path attributes  PATH_SIRGRP */
#ifdef __PATH_SIRGRP
        { *pval = __PATH_SIRGRP; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_SIWGRP"))    /* path attributes  PATH_SIWGRP */
#ifdef __PATH_SIWGRP
        { *pval = __PATH_SIWGRP; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_SIXGRP"))    /* path attributes  PATH_SIXGRP */
#ifdef __PATH_SIXGRP
        { *pval = __PATH_SIXGRP; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_SIRWXG"))    /* path attributes  PATH_SIRWXG */
#ifdef __PATH_SIRWXG
        { *pval = __PATH_SIRWXG; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_SIROTH"))    /* path attributes  PATH_SIROTH */
#ifdef __PATH_SIROTH
        { *pval = __PATH_SIROTH; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_SIWOTH"))    /* path attributes  PATH_SIWOTH */
#ifdef __PATH_SIWOTH
        { *pval = __PATH_SIWOTH; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_SIXOTH"))    /* path attributes  PATH_SIXOTH */
#ifdef __PATH_SIXOTH
        { *pval = __PATH_SIXOTH; return TRUE; }
#else
        return FALSE;
#endif
    if (strEQ(name, "PATH_SIRWXO"))    /* path attributes  PATH_SIRWXO */
#ifdef __PATH_SIRWXO
        { *pval = __PATH_SIRWXO; return TRUE; }
#else
        return FALSE;
#endif

/*
 * default fall through is FALSE
 */
    return FALSE;
}


#ifdef USE_PERLIO
static SV *
newFH(PerlIO *fp, char type) {
#else
static SV *
newFH(FILE *fp, char type) {
#endif
    SV *rv;
    GV **stashp, *gv = (GV *)NEWSV(0,0);
    HV *stash;
    IO *io;

    /* dTHR; */
    /* Find stash for VMS::Stdio.  We don't do this once at boot
     * to allow for possibility of threaded Perl with per-thread
     * symbol tables.  This code (through io = ...) is really
     * equivalent to gv_fetchpv("VMS::Stdio::__FH__",TRUE,SVt_PVIO),
     * with a little less overhead, and good exercise for me. :-) 
     */
    /*
     ** Well thanks Chuck :-) , er, s/VMS/OS390/g 8-)
     */
    stashp = (GV **)hv_fetch(PL_defstash,"OS390::",7,TRUE);
    if (!stashp || *stashp == (GV *)&PL_sv_undef) return Nullsv;
    if (!(stash = GvHV(*stashp))) stash = GvHV(*stashp) = newHV();
    stashp = (GV **)hv_fetch(GvHV(*stashp),"Stdio::",7,TRUE);
    if (!stashp || *stashp == (GV *)&PL_sv_undef) return Nullsv;
    if (!(stash = GvHV(*stashp))) stash = GvHV(*stashp) = newHV();

    /* Set up GV to point to IO, and then take reference */
    gv_init(gv,stash,"__FH__",6,0);
    io = GvIOp(gv) = newIO();
    IoIFP(io) = fp;
    if (type != '<') IoOFP(io) = fp;
    IoTYPE(io) = type;
    rv = newRV((SV *)gv);
    SvREFCNT_dec(gv);
    return sv_bless(rv,stash);
}

int 
#ifdef _EXT
h2dyn_t(__dyn_t *ip, HV *hip, int free_flag) {
#else
h2dyn_t(struct __dyn_t *ip, HV *hip, int free_flag) {
#endif
    /*
     * __dyn_t structure Table 16, pp 218-220 C/C++ MVS Library Reference
     */
    HE * entry;
    I32 retlen;
    SV * hval;
    STRLEN len;
    char * key;
    int got_free = 0;
    int got_any  = 0;
    int i = 0;

    /* Iterate over hip setting *ip elements. */
        /* Strictly this "miscitems" is not char ** but char * instead. */
    (void)hv_iterinit(hip);
    while ((entry = hv_iternext(hip)))  {
        key = hv_iterkey(entry, &retlen); 
        while (*key == '_') { key++; }   /* This is where s/^_+// takes place. */
        hval  = hv_iterval(hip, entry);
             if (strEQ(key,"ddname"))     { ip -> __ddname = SvPV(hval,len);       got_any++; got_free++; }
        else if (strEQ(key,"dsname"))     { ip -> __dsname = SvPV(hval,len);       got_any++; got_free++; }
        else if (strEQ(key,"sysout") )    { ip -> __sysout = (char)SvIV(hval);     got_any++; }
        else if (strEQ(key,"sysoutname")) { ip -> __sysoutname = SvPV(hval,len);   got_any++; }
        else if (strEQ(key,"member"))     { ip -> __member = SvPV(hval,len);       got_any++; got_free++; }
        else if (strEQ(key,"status"))     { ip -> __status = (char)SvIV(hval);     got_any++; }
        else if (strEQ(key,"normdisp"))   { ip -> __normdisp = (char)SvIV(hval);   got_any++; got_free++; }
        else if (strEQ(key,"conddisp"))   { ip -> __conddisp = (char)SvIV(hval);   got_any++; }
        else if (strEQ(key,"unit"))       { ip -> __unit = SvPV(hval,len);         got_any++; }
        else if (strEQ(key,"volser"))     { ip -> __volser = SvPV(hval,len);       got_any++; }
        else if (strEQ(key,"dsorg"))      { ip -> __dsorg = (short)SvIV(hval);     got_any++; } 
        else if (strEQ(key,"alcunit"))    { ip -> __alcunit = (char)SvIV(hval);    got_any++; }
        else if (strEQ(key,"primary"))    { ip -> __primary = SvIV(hval);          got_any++; }
        else if (strEQ(key,"secondary"))  { ip -> __secondary = SvIV(hval);        got_any++; }
        else if (strEQ(key,"dirblk"))     { ip -> __dirblk = SvIV(hval);           got_any++; }
        else if (strEQ(key,"avgblk"))     { ip -> __avgblk = SvIV(hval);           got_any++; }
        else if (strEQ(key,"recfm"))      { ip -> __recfm  = (short)SvIV(hval);    got_any++; }
        else if (strEQ(key,"blksize"))    { ip -> __blksize = (short)SvIV(hval);   got_any++; }
        else if (strEQ(key,"lrecl"))      { ip -> __lrecl = (unsigned short)SvIV(hval); got_any++; }
        else if (strEQ(key,"volrefds"))   { ip -> __volrefds = SvPV(hval,len);     got_any++; }
        else if (strEQ(key,"dcbrefds"))   { ip -> __dcbrefds = SvPV(hval,len);     got_any++; }
        else if (strEQ(key,"dcbrefdd"))   { ip -> __dcbrefdd = SvPV(hval,len);     got_any++; }
        else if (strEQ(key,"misc_flags")) { ip -> __misc_flags = (unsigned char)SvIV(hval); got_any++; }
        else if (strEQ(key,"password"))   { ip -> __password = SvPV(hval,len);     got_any++; }
        else if (strEQ(key,"miscitems"))  { ip -> __miscitems = (char **)SvPV(hval,len);  got_any++; got_free++; }
        else if (strEQ(key,"infocode"))   { ip -> __infocode = (short)SvIV(hval);  got_any++; }
        else if (strEQ(key,"errcode"))    { ip -> __errcode = (short)SvIV(hval);   got_any++; }
        else if (strEQ(key,"storclass"))  { ip -> __storclass = SvPV(hval,len);    got_any++; }
        else if (strEQ(key,"mgntclass"))  { ip -> __mgntclass = SvPV(hval,len);    got_any++; }
        else if (strEQ(key,"dataclass"))  { ip -> __dataclass = SvPV(hval,len);    got_any++; }
        else if (strEQ(key,"recorg"))     { ip -> __recorg = (char)SvIV(hval);     got_any++; }
        else if (strEQ(key,"keyoffset"))  { ip -> __keyoffset = (short)SvIV(hval); got_any++; }
        else if (strEQ(key,"keylength"))  { ip -> __keylength = (short)SvIV(hval); got_any++; }
        else if (strEQ(key,"refdd"))      { ip -> __refdd = SvPV(hval,len);        got_any++; }
        else if (strEQ(key,"like"))       { ip -> __like = SvPV(hval,len);         got_any++; }
        else if (strEQ(key,"dsntype"))    { ip -> __dsntype = (char)SvIV(hval);    got_any++; }
        else if (strEQ(key,"pathname"))   { ip -> __pathname = SvPV(hval,len);     got_any++; got_free++; }
        else if (strEQ(key,"pathopts"))   { ip -> __pathopts = SvIV(hval);         got_any++; }
        else if (strEQ(key,"pathmode"))   { ip -> __pathmode = SvIV(hval);         got_any++; }
        else if (strEQ(key,"pathndisp"))  { ip -> __pathndisp = (char)SvIV(hval);  got_any++; got_free++; }
        else if (strEQ(key,"pathcdisp"))  { ip -> __pathcdisp = (char)SvIV(hval);  got_any++; }
        i++;
#ifdef WARN_DYN_T_KEY
        if (!free_flag && got_any != i) { 
            warn("h2dyn_t warning key '%s' not recognized.\n",key);
            got_any = i; /* avoid war-ning for more than one unrecognized key */
        }
#endif    /* WARN_DYN_T_KEY */
    }
    return(i);
}

/***************/
/*
 *******************************************************************
 ********* begin code borrowed from IBM's            ***************
 ********* B<C/C++ MVS Programming Guide>            ***************
 ********* Document number SCO9-2164-00              ***************
 ********* copyright 1995 IBM                        ***************
 ********* APPENDIX 1.8 Appendix H.                  ***************
 ********* which comes with a note that reads:       ***************
 ********* "This information is included to aid you  ***************
 *********  in such a task and is B<not> programming ***************
 *********  interface information."                  ***************
 ********* Among other possible problems it does not ***************
 ********* return ALIAS members (sigh).              ***************
 *********  - caveat scriptor.                       ***************
 *******************************************************************
 */

/*
 * NODE: a pointer to this structure is returned from the call to _pds_mem().
 * It is a linked list of character arrays - each array contains a member
 * name. Each next pointer points * to the next member, except the last
 * next member which points to NULL.
 */
#define NAMELEN 8      /* Length of an MVS member name */
typedef struct node {
                      struct node *next;
                      char name[NAMELEN+1];
                    } NODE, *NODE_PTR;

/*
 * NODE_PTR _pds_mem(const char *pds, int *member_number, int alias_flag):
 *
 * pds must be a fully qualified pds name, for example,
 * ID.PDS.DATASET * returns a * pointer to a linked list of
 * nodes.  Each node contains a member of the * pds and a
 * pointer to the next node.  If no members exist, or the
 * pds is the name of a sequential file, the pointer
 * is NULL.
 *
 * Note:  Warnings will apear on STDERR if pds is the name 
 * of a sequential file.
 */
/*
 * RECORD:
 * each record of a pds will be read into one of these structures.
 * The first 2 bytes is the record length, which is put into 'count',
 * the remaining 254 bytes are put into rest.
 * Hence, each record is 256 bytes long.
 */
#define RECLEN  254
typedef struct {
    unsigned short int count;
    char rest[RECLEN];
} RECORD;

/*
 * static int gen_node(NODE_PTR *node, RECORD *rec, NODE_PTR *last_ptr, int * count, int want_alias);
 */
static char *pm_add_name(NODE_PTR *node, char *name, NODE_PTR *last_ptr);

/* the heart of the beast */
NODE_PTR _pds_mem(const char *pds, int *member_number, int alias_flag) {
    FILE *fp;
    int bytes;
    NODE_PTR node, last_ptr;
    RECORD rec;
    int list_end;
    int member_count = -1;
    char *qual_pds;
    char filename[MAXOSFILENAME+1];
    fldata_t fileinfo;
    int rc;
    /*
     * initialize the linked list
     */
    node = NULL;
    last_ptr = NULL;
/*
 * Open the pds in binary read mode. The PDS directory will be read one
 * record at a time until either the end of the directory or end-of-file
 * is detected. Call up gen_node() with every record read, to add member
 * names to the linked list
 */
    fp = fopen(pds,"rb");
    if (fp == NULL) {
        warn("fopen(%s,\"rb\") returned NULL.\n",pds);
        return((NODE_PTR)(-1));
    }
    rc = fldata(fp, filename, &fileinfo);
    if (rc != 0) {
        warn("fldata() failed on %s.\n",pds);
        return((NODE_PTR)(-1));
    }
    if (fileinfo.__dsorgPO != 1) {
#ifndef NO_WARN_IF_NOT_PDS
        warn("Data set %s [filename %s] does not appear to be a PDS.\n",
                pds,filename);
#endif
        return((NODE_PTR)(-1));
    }
    if (fileinfo.__dsorgPDSdir != 1) {
#ifndef NO_WARN_IF_NOT_PDS
        warn("Data set %s [filename %s] does not appear to be a PDS directory.\n",
                pds, filename);
#endif
        return((NODE_PTR)(-1));
    }
    member_count = 0;
    do {
        bytes = fread(&rec, 1, sizeof(rec), fp);
        if ((bytes != sizeof(rec)) && !feof(fp)) {
            warn("fread(): failed in %s, line %d\nExpected to read %d bytes but read %d bytes\n",
                __FILE__,__LINE__,sizeof(rec), bytes);
#ifdef H_PERL
            croak("EFREAD\n");
#endif
            return((NODE_PTR)(-1));
        }
 /*       list_end = gen_node(&node, &rec, &last_ptr, &member_count, 0); */
        list_end = gen_node(&node, &rec, &last_ptr, &member_count, alias_flag);
    } while (!feof(fp) && !list_end);
    fclose(fp);
    *member_number = member_count;
    return(node);
}
/*
 * GEN_NODE() processes the record passed. The main loop scans through the
 * record until it has read at least rec->count bytes, or a directory end
 * marker is detected.
 *
 * Each record has the form:
 *
 * +------------+------+------+------+------+----------------+
 * + # of bytes _Member_Member_......_Member_  Unused        +
 * + in record  _  1   _  2   _      _  n   _                +
 * +------------+------+------+------+------+----------------+
 *  _--count---__-----------------rest-----------------------_
 *  (Note that the number stored in count includes its own
 *   two bytes)
 *
 * And, each member has the form:
 *
 * +--------+-------+----+-----------------------------------+
 * + Member _TTR    _info_                                   +
 * + Name   _       _byte_  User Data TTRN's (halfwords)     +
 * + 8 bytes_3 bytes_    _                                   +
 * +--------+-------+----+-----------------------------------+
 */
#define TTRLEN 3      /* The TTR's are 3 bytes long */
/*
 * bit 0 of the info-byte is '1' if the member is an alias,
 * 0 otherwise. ALIAS_MASK is used to extract this information
 */
#define ALIAS_MASK ((unsigned int) 0x80)
/*
 * The number of user data half-words is in bits 3-7 of the info byte.
 * SKIP_MASK is used to extract this information.  Since this number is
 * in half-words, it needs to be double to obtain the number of bytes.
 */
#define SKIP_MASK ((unsigned int) 0x1F)

static int gen_node(NODE_PTR *node, RECORD *rec, NODE_PTR *last_ptr, int *member_count, int want_alias) {
    char *ptr, *name;
    int skip, count = 2;
    int member_number;
    unsigned int info_byte, alias, ttrn;
    char ttr[TTRLEN];
    int list_end = 0;
    member_number = *member_count;
    ptr = rec->rest;
    while(count < rec->count) {
        /*
         * 8 hex FF's mark the end of the directory
         */
        if (!memcmp(ptr,"\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF",NAMELEN)) {
            list_end = 1;
            break;
        }
        /* member name */
        name = ptr;
        ptr += NAMELEN;
        /* ttr */
        memcpy(ttr,ptr,TTRLEN);
        ptr += TTRLEN;
        /* info_byte */
        info_byte = (unsigned int) (*ptr);
        alias = info_byte & ALIAS_MASK;
        switch (want_alias) {
	case 0:
            if (!alias) {
                 pm_add_name(node,name,last_ptr);
                 member_number++;
            }
            break;
	case 1:
            if (alias) {
                 pm_add_name(node,name,last_ptr);
                 member_number++;
            }
            break;
	case 2:
            pm_add_name(node,name,last_ptr);
            member_number++;
            break;
        }
        skip = (info_byte & SKIP_MASK) * 2 + 1;
        ptr += skip;
        count += (TTRLEN + NAMELEN + skip);
    }
    *member_count = member_number;
    return(list_end);
}
/*
 * ADD_NAME: Add a new member name to the linked node. The new member is
 * added to the end so that the original ordering is maintained.
 */
static char *pm_add_name(NODE_PTR *node, char *name, NODE_PTR *last_ptr) {
    NODE_PTR newnode;
    /*
     * malloc space for the new node
     */
    newnode = (NODE_PTR)malloc(sizeof(NODE));
    if (newnode == NULL) {
        warn("malloc failed for %d bytes\n",sizeof(NODE));
#ifdef H_PERL
        croak("ENONMEM\n");
#endif
        return(NULL);
    }
    /* copy the name into the node and NULL terminate it */
    memcpy(newnode->name,name,NAMELEN);
    newnode->name[NAMELEN] = '\0';
    newnode->next = NULL;
    /*
     * add the new node to the linked list
     */
    if (*last_ptr != NULL) {
        (*last_ptr)->next = newnode;
        *last_ptr = newnode;
    }
    else {
        *node = newnode;
        *last_ptr = newnode;
    }
    return(newnode->name);
}

/*
 *******************************************************************
 ********* end code borrowed from IBM's              ***************
 ********* B<C/C++ MVS Programming Guide>            ***************
 *******************************************************************
 */
/***************/

MODULE = OS390::Stdio  PACKAGE = OS390::Stdio

void
constant(name)
	char * name
	PROTOTYPE: $
	CODE:
	IV i;
	if (constant(name, &i))
	    ST(0) = sv_2mortal(newSViv(i));
	else
	    ST(0) = &PL_sv_undef;

void
dsname_level(fp)
	FILE * fp
	PROTOTYPE: $
	CODE:
	    char vmsdef[8], es[8], sep;
	    unsigned long int retsts;
	    /* catalogs and VTOCS are tough :-} */
	    croak("dsname_level() not yet implemented.\n");
	    if (fsync(fileno(fp))) { ST(0) = &PL_sv_undef; }
	    else                   { clearerr(fp); ST(0) = &PL_sv_yes; }

SV *
dynalloc(dyn_t_hash_ref)
	SV * dyn_t_hash_ref
	PROTOTYPE: $
	INIT:
	    HV * myhash;
	    __dyn_t dip;
	    int rc;
	    if ( dyn_t_hash_ref != &PL_sv_undef) {
		/* valid hash ref? */
		if ( SvROK(dyn_t_hash_ref) ) {
		    if ( SvTYPE(SvRV(dyn_t_hash_ref)) != SVt_PVHV ) {
		        /* it is not a hashref */
		        warn("dynalloc() requires a hash reference");
	                XSRETURN_UNDEF;
		    }
		}
		else {
		    warn("dynalloc() requires a hash reference");
	            XSRETURN_UNDEF;
		}
	    } 
	    else {
	        warn("dynalloc() called with undefined value.\n");
	        XSRETURN_UNDEF;
	    }
	CODE:
	    dyninit( &dip );
	    myhash = (HV *)SvRV(dyn_t_hash_ref);
	    rc = h2dyn_t( &dip, myhash, 0 );
	    ST(0) = sv_newmortal();
	    if ( rc ) {
	        if (dynalloc(&dip) == 0) { 
	            ST(0) = &PL_sv_yes;
	        }
	        else { 
	            warn("dynalloc() failed with error code %hX, info code %hX",
                          dip.__errcode, dip.__infocode);
	            ST(0) = &PL_sv_undef;
	        }
	    }
	    else {
	        warn("dynalloc() unable to initialize struct __dyn_t");
	        ST(0) = &PL_sv_undef;
	    }

SV *
dynfree(dyn_t_hash_ref)
	SV * dyn_t_hash_ref
	PROTOTYPE: $
	INIT:
	    HV * myhash;
	    __dyn_t dip;
	    int rc;
	    if ( dyn_t_hash_ref != &PL_sv_undef) {
		/* valid hash ref? */
		if ( SvROK(dyn_t_hash_ref) ) {
		    if ( SvTYPE(SvRV(dyn_t_hash_ref)) != SVt_PVHV ) {
		        /* it is not a hashref */
		        warn("dynfree() requires a hash reference");
	                XSRETURN_UNDEF;
		    }
		}
		else {
		    warn("dynfree() requires a hash reference");
	            XSRETURN_UNDEF;
		}
	    } 
	    else {
	        warn("dynfree() called with undefined value.\n");
	        XSRETURN_UNDEF;
	    }
	CODE:
	    dyninit( &dip );
	    myhash = (HV *)SvRV(dyn_t_hash_ref);
	    rc = h2dyn_t( &dip, myhash, 1 );
	    ST(0) = sv_newmortal();
	    if ( rc ) {
	        if (dynfree(&dip) == 0) { 
	            ST(0) = &PL_sv_yes;
	        }
	        else { 
	            warn("dynfree() failed with error code %hX, info code %hX",
                          dip.__errcode, dip.__infocode);
	            ST(0) = &PL_sv_undef;
	        }
	    }
	    else {
	        warn("dynfree() unable to initialize struct __dyn_t");
	        ST(0) = &PL_sv_undef;
	    }

void
flush(fp)
	FILE * fp
	PROTOTYPE: $
	CODE:
	    if (fflush(fp)) { ST(0) = &PL_sv_undef; }
	    else            { clearerr(fp); ST(0) = &PL_sv_yes; }

void
forward(fp)
	FILE * fp
	PROTOTYPE: $
	CODE:
	    ST(0) = fseek(fp, 0L, SEEK_END) ? &PL_sv_undef : &PL_sv_yes;

char *
get_dcb(sv)
 	SV * sv
	PROTOTYPE: $
	INIT:
	    /*
	     * distillation of the fldata_t structure 
	     * Table 17, pg 310 C/C++ MVS Library Reference
	     */
	    char recfm[12] = ""; /* "F","V","U","S","Blk","ASA","M" */
	    char dsorg[42] = ""; /* "PO", "PDSmem","PDSdir","PS",  "Concat",
                                      "Mem","Hiper", "Temp",  "VSAM","HFS" */
	    char openmode[17] = ""; /* "TEXT","BINARY","RECORD" */
	    char modeflag[22] = ""; /* "APPEND","READ","UPDATE","WRITE" 
                                       + combos */
	    /* unsigned int reserve2; */
	    char device[11] = ""; /* "DISK","TERMINAL","PRINTER","TAPE",
	                             "TDQ", "DUMMY",   "OTHER",  "MEMORY",
                                     "MSGFILE","HFS", "HIPERSPACE" */
	    char vsamtype[10] = ""; /* "NOTVSAM","ESDS","KSDS","RRDS",
	                               "ESDS_PATH","KSDS_PATH" */
	    /* unsigned long reserve4; */
	    int i;
	    char filename[MAXOSFILENAME+1];
	    fldata_t fileinfo;
	    FILE *	fp;
	    STRLEN len;
	    int needs_closing = 0;
	    if ( sv != &PL_sv_undef) {
		if ( SvROK(sv) ) { /* a reference */
		    if ( SvTYPE(SvRV(sv)) == SVt_PVGV ) { /* valid filehandle ref? */
#ifdef USE_PERLIO
	                fp = PerlIO_findFILE(IoIFP(sv_2io(ST(0))));
#else
	                fp = IoIFP(sv_2io(ST(0)));
#endif
	            }
                    else {
	                XSRETURN_UNDEF;
                    }
	        }
 	        else {
	            if (SvTYPE(sv) == SVt_PV) { /* if a plain scalar then try to fopen() */
	                fp = fopen(SvPV(sv,len),"r");
	                if (fp != Nullfp) {
	                    needs_closing = 1;
                        }
                        else {
	                    XSRETURN_UNDEF;
                        }
                    }
                    else {
	                XSRETURN_UNDEF;
                    }
	        }
	    }
	    else {
	        XSRETURN_UNDEF;
	    }
	CODE:
	    for (i=0; i<24; i++) {
	        ST(i) = sv_newmortal();
	    }
	    if ((fldata(fp,filename,&fileinfo)) == 0) {
                sv_setpv(ST(0),"filename");
                sv_setpv(ST(1),filename);
	        /* "F","V","U","S","Blk","ASA","M" */
	        if (fileinfo.__recfmF)
	            strcat(recfm,"F");
	        if (fileinfo.__recfmS)
	            strcat(recfm,"S");
	        if (fileinfo.__recfmU)
	            strcat(recfm,"U");
	        if (fileinfo.__recfmBlk)
	            strcat(recfm,"Blk");
	        if (fileinfo.__recfmASA)
	            strcat(recfm,"ASA");
                sv_setpv(ST(2),"recfm");
                sv_setpv(ST(3),recfm);
	        /* "PO", "PDSmem","PDSdir","PS",  "Concat",
                   "Mem","Hiper", "Temp",  "VSAM","HFS" */
	        if (fileinfo.__dsorgPO)
	            strcat(dsorg,"PO");
	        if (fileinfo.__dsorgPDSmem)
	            strcat(dsorg,"PDSmem");
	        if (fileinfo.__dsorgPDSdir)
	            strcat(dsorg,"PDSdir");
	        if (fileinfo.__dsorgPS)
	            strcat(dsorg,"PS");
	        if (fileinfo.__dsorgConcat)
	            strcat(dsorg,"Concat");
	        if (fileinfo.__dsorgMem)
	            strcat(dsorg,"Mem");
	        if (fileinfo.__dsorgHiper)
	            strcat(dsorg,"Hiper");
	        if (fileinfo.__dsorgTemp)
	            strcat(dsorg,"Temp");
	        if (fileinfo.__dsorgVSAM)
	            strcat(dsorg,"VSAM");
	        if (fileinfo.__dsorgHFS)
	            strcat(dsorg,"HFS");
                sv_setpv(ST(4),"dsorg");
                sv_setpv(ST(5),dsorg);
	        /* "TEXT","BINARY","RECORD" */
	        if (fileinfo.__openmode == __TEXT)
	            strcat(openmode,"TEXT");
	        if (fileinfo.__openmode == __BINARY)
	            strcat(openmode,"BINARY");
	        if (fileinfo.__openmode == __RECORD)
	            strcat(openmode,"RECORD");
                sv_setpv(ST(6),"openmode");
                sv_setpv(ST(7),openmode);
	        /* "APPEND","READ","UPDATE","WRITE" + combos */
	        if ((fileinfo.__modeflag & __APPEND) == __APPEND)
	            strcat(modeflag,"APPEND");
	        if ((fileinfo.__modeflag & __READ) == __READ)
	            strcat(modeflag,"READ");
	        if ((fileinfo.__modeflag & __UPDATE) == __UPDATE)
	            strcat(modeflag,"UPDATE");
	        if ((fileinfo.__modeflag & __WRITE) == __WRITE)
	            strcat(modeflag,"WRITE");
                sv_setpv(ST(8),"modeflag");
                sv_setpv(ST(9),modeflag);
	        /* "DISK","TERMINAL","PRINTER","TAPE",
	           "TDQ", "DUMMY",   "OTHER",  "MEMORY",
                   "MSGFILE","HFS", "HIPERSPACE" */
	        if (fileinfo.__device == __DISK)
	            strcat(device,"DISK");
	        if (fileinfo.__device == __TERMINAL)
	            strcat(device,"TERMINAL");
	        if (fileinfo.__device == __PRINTER)
	            strcat(device,"PRINTER");
	        if (fileinfo.__device == __TAPE)
	            strcat(device,"TAPE");
	        if (fileinfo.__device == __TDQ)
	            strcat(device,"TDQ");
	        if (fileinfo.__device == __DUMMY)
	            strcat(device,"DUMMY");
	        if (fileinfo.__device == __OTHER)
	            strcat(device,"OTHER");
	        if (fileinfo.__device == __MEMORY)
	            strcat(device,"MEMORY");
                sv_setpv(ST(10),"device");
                sv_setpv(ST(11),device);
	        /* unsigned long */
                sv_setpv(ST(12),"blksize");
                sv_setiv(ST(13),fileinfo.__blksize);
	        /* unsigned long */
                sv_setpv(ST(14),"maxreclen");
                sv_setiv(ST(15),fileinfo.__maxreclen);
	        /* "NOTVSAM","ESDS","KSDS","RRDS",
	           "ESDS_PATH","KSDS_PATH" */
	        if (fileinfo.__vsamtype == __NOTVSAM)
	            strcat(vsamtype,"NOTVSAM");
	        if (fileinfo.__vsamtype == __ESDS)
	            strcat(vsamtype,"ESDS");
	        if (fileinfo.__vsamtype == __KSDS)
	            strcat(vsamtype,"KSDS");
	        if (fileinfo.__vsamtype == __RRDS)
	            strcat(vsamtype,"RRDS");
	        if (fileinfo.__vsamtype == __ESDS_PATH)
	            strcat(vsamtype,"ESDS_PATH");
	        if (fileinfo.__vsamtype == __KSDS_PATH)
	            strcat(vsamtype,"KSDS_PATH");
                sv_setpv(ST(16),"vsamtype");
                sv_setpv(ST(17),vsamtype);
	        /* unsigned long */
                sv_setpv(ST(18),"vsamkeylen");
                sv_setiv(ST(19),fileinfo.__vsamkeylen);
	        /* unsigned long */
                sv_setpv(ST(20),"vsamRKP");
                sv_setiv(ST(21),fileinfo.__vsamRKP);
                sv_setpv(ST(22),"dsname");
                sv_setpv(ST(23),fileinfo.__dsname);
	        if (needs_closing)
	            fclose(fp);
	        XSRETURN(24);
            }
            else {
	        ST(0) = &PL_sv_undef;
            }

char *
getname(sv)
 	SV * sv
	PROTOTYPE: $
	INIT:
	    int needs_closing = 0;
	    FILE * fp;
	    char filename[MAXOSFILENAME+10];
	    fldata_t fileinfo;
	    STRLEN len;
	    if ( sv != &PL_sv_undef) {
		if ( SvROK(sv) ) { /* a reference */
		    if ( SvTYPE(SvRV(sv)) == SVt_PVGV ) { /* valid filehandle ref? */
#ifdef USE_PERLIO
	                fp = PerlIO_findFILE(IoIFP(sv_2io(ST(0))));
#else
	                fp = IoIFP(sv_2io(ST(0)));
#endif
	            }
                    else {
	                XSRETURN_UNDEF;
                    }
	        }
 	        else {
	            if (SvTYPE(sv) == SVt_PV) { /* if a plain scalar then try to fopen() */
	                fp = fopen(SvPV(sv,len),"r");
	                if (fp != Nullfp) {
	                    needs_closing = 1;
                        }
                        else {
	                    XSRETURN_UNDEF;
                        }
                    }
                    else {
	                XSRETURN_UNDEF;
                    }
	        }
	    }
	    else {
	        XSRETURN_UNDEF;
	    }
	CODE:
	    ST(0) = sv_newmortal();
	    if ((fldata(fp,filename,&fileinfo)) == 0) {
                sv_setpv(ST(0),filename);
            }
            else {
	        ST(0) = &PL_sv_undef;
            }
	    if (needs_closing)
	        fclose(fp);

void
mvsopen(name,mode)
	char * name
	char * mode
	PROTOTYPE: @
	CODE:
	    FILE * fp;
#ifdef USE_PERLIO
	    PerlIO * pio_fp;
              SV *fh;
#endif

	    fp = fopen(name,mode);
#ifdef USE_PERLIO
	    if (fp != Null(FILE *)) {
              pio_fp = PerlIO_importFILE(fp,mode);
              fh = newFH(pio_fp,(mode[1] ? '+' : (mode[0] == 'r' ? '<' : (mode[0] == 'a' ? 'a' : '>'))));
	      ST(0) = (fh ? sv_2mortal(fh) : &PL_sv_undef);
	    }
	    else { ST(0) = &PL_sv_undef; }
#else
	    if (fp != Nullfp) {
	      SV *fh = newFH(fp,(mode[1] ? '+' : (mode[0] == 'r' ? '<' : (mode[0] == 'a' ? 'a' : '>'))));
	      ST(0) = (fh ? sv_2mortal(fh) : &PL_sv_undef);
	    }
	    else { ST(0) = &PL_sv_undef; }
#endif

int
mvswrite(fp,buffer,count)
	FILE * fp
	char * buffer
	unsigned int count
	PROTOTYPE: @
	CODE:
	    /* use sizeof(char) til we get wchar_t's here && buffer */
	    RETVAL = fwrite((void *)buffer, sizeof(char), count, fp);
	OUTPUT:
	    RETVAL

char * 
pds_mem(pds,...)
	char * pds
	PROTOTYPE: @
	CODE:
	    NODE_PTR my_mem;
	    NODE_PTR next_mem;
	    char * member_name;
	    char * blank;
	    int i = 0;
	    int alias_flag;
	    if (items > 2) croak("too many args");
	    if (items == 2) {
	        if (!SvIOK(ST(1))) croak("alias flag must be an integer");
	        alias_flag = SvIV(ST(1));
	    }
	    if (alias_flag < 0) 
	        alias_flag = 0;
	    if (alias_flag > 2)
	        alias_flag = 0;
	    my_mem = _pds_mem(pds,&i,alias_flag);
	    next_mem = my_mem;
	    if (next_mem == (NODE_PTR)(-1)) {
	        ST(0) = sv_newmortal();
	        ST(0) = &PL_sv_undef;
	    }
	    else if (next_mem == NULL) {
	        ST(0) = sv_newmortal();
	        sv_setpv(ST(0),"");
	        XSRETURN(1);  
	    }
	    else {
                /* extend perl return ST-ack by an appropriate amount */
                if (i >= 0)
		    EXTEND(sp,i+2);
                /*
                 * put linked list names onto ST array, sans blank characters.
                 * free the mallocs too.
                 */
	        while (next_mem != NULL) {
		    member_name = my_mem->name;
		    blank = strchr(member_name,' ');
                    if (blank != NULL)
		        *blank = '\0';
                    PUSHs(sv_2mortal(newSVpvn(member_name,strlen(member_name))));
	            next_mem = my_mem->next;
	            free(my_mem);
	            my_mem = next_mem;
	        }
	        XSRETURN(i+2);
	    }

void
remove(name)
	char *name
	PROTOTYPE: $
	CODE:
	    ST(0) = remove(name) ? &PL_sv_undef : &PL_sv_yes;

void
resetpos(fp)
	FILE* fp
	PROTOTYPE: $
	CODE:
	    ST(0) = fseek(fp, 0L, SEEK_CUR) ? &PL_sv_undef : &PL_sv_yes;

void
rewind(fp)
	FILE* fp
	PROTOTYPE: $
	CODE:
	    /*
	     *  Unfortunately rewind() does not appear 
             *  to work on OE R2.5.  errno indicates only:
	     **  "EDC5129I No such file or directory."
	     * rewind(fp);
	     **   if (errno) printf("%s\n",strerror(errno));
	     * ST(0) = errno ? &PL_sv_undef : &PL_sv_yes;
	     *  hence we use fseek() instead.
             */
	    ST(0) = fseek(fp, 0L, SEEK_SET) ? &PL_sv_undef : &PL_sv_yes;

int
smf_record(smf_record_type,smf_record_subtype,smf_record)
	int smf_record_type
	int smf_record_subtype
	char * smf_record
	PROTOTYPE: @
	INIT:
	    int smf_record_length,rc;
	CODE:
            smf_record_length = strlen(smf_record);
	    ST(0) = sv_newmortal();
	    rc = __smf_record(smf_record_type,smf_record_subtype,smf_record_length,smf_record);
	    switch (rc) {
	        case 0:
		    ST(0) = &PL_sv_yes;
		    break;
		case EINVAL:
		    warn("smf_record() value specified of length '%d' was incorrect",smf_record_length);
	            ST(0) = &PL_sv_undef;
		    break;
		case ENOMEM:
		    warn("smf_record() not enough storage to complete __smf_record() call");
	            ST(0) = &PL_sv_undef;
		    break;
		case EPERM:
		    warn("smf_record() The calling process is not permitted access to the BPX.SMF facility class");
	            ST(0) = &PL_sv_undef;
		    break;
		case EMVSERR:
		    warn("smf_record() The SMF service returned '%d', __errno2 = %08x",rc,__errno2());
	            ST(0) = &PL_sv_undef;
		    break;
		default:
		    warn("smf_record() The SMF service returned '%d'",rc);
	            ST(0) = &PL_sv_undef;
		    break;
	    }

SV *
svc99(S99struc_hash_ref)
	SV * S99struc_hash_ref
	PROTOTYPE: $
	INIT:
	    HV * my99hash;
	    __S99parms parmstring;
	    HE * entry;
	    I32 retlen;
	    SV * hval;
	    STRLEN len;
	    char * key;
	    int got_any = 0;
	    int warnings = 0;
	    int i = 0;
	    int j = 0;
	    I32 num_tu = 0;
	    char *tu[OS390_STDIO_SVC99_TEXT_UNITS] = { 
	    	"", "", "", "", "", "", "", "", "", "", "", "",
	    	"", "", "", "", "", "", "", "", "", "", "", ""
	                                             };
	    if ( S99struc_hash_ref != &PL_sv_undef) {
		/* valid hash ref? */
		if ( SvROK(S99struc_hash_ref) ) {
		    if ( SvTYPE(SvRV(S99struc_hash_ref)) != SVt_PVHV ) {
		        /* it is not a hashref */
		        warn("svc99() requires a hash reference");
	                XSRETURN_UNDEF;
		    }
		}
		else {
		    warn("svc99() requires a hash reference");
	            XSRETURN_UNDEF;
		}
	    } 
	    else {
	        warn("svc99() called with undefined value.\n");
	        XSRETURN_UNDEF;
	    }
	CODE:
	    my99hash = (HV *)SvRV(S99struc_hash_ref);
	    /* Initialize parmstring to '0'. */
	    memset(&parmstring,0,sizeof(parmstring)); 
	    /* Iterate over my99hash setting *parmstring elements. */
	    (void)hv_iterinit(my99hash);
	    while ((entry = hv_iternext(my99hash)))  {
	        /* This is where s/^_+// takes place. */
	        key = hv_iterkey(entry, &retlen); 
	        while (*key == '_') { key++; }
	        hval  = hv_iterval(my99hash, entry);
	        if (strEQ(key,"S99VERB"))    { parmstring.__S99VERB = (unsigned char)SvIV(hval);        got_any++; }
	   else if (strEQ(key,"S99FLAG1"))   { parmstring.__S99FLAG1 = (unsigned short)SvIV(hval);      got_any++; }
	   /* note that FLAG2
	    * "can only be filled in by APF authorized programs" */
	   else if (strEQ(key,"S99FLAG2"))   { parmstring.__S99FLAG2 = (unsigned short)SvIV(hval);      got_any++; }
	   else if (strEQ(key,"S99RBLN"))    { parmstring.__S99RBLN = (unsigned char)SvIV(hval);        got_any++; }
	   else if (strEQ(key,"S99S99X"))    { parmstring.__S99S99X = (void * )SvPV(hval,len);          got_any++; }
	    /* Treat "S99INFO" and "S99ERROR" as read only for now, 
	     * do not even attempt to assign. */
	    /* "S99TXTPP" should be an array ref and we ought to loop 
	     * through an AV: */
	   else if (strEQ(key,"S99TXTPP"))   {
	       if ((!SvROK(hval))) {
	           warn("value of S99TXTPP was not a reference.");
	           warnings++;
	           XSRETURN_UNDEF;
	       }
	       else if ( (SvTYPE(SvRV(hval)) != SVt_PVAV) ) {
	           warn("value of S99TXTPP was not an array reference.");
	           warnings++;
	           XSRETURN_UNDEF;
	       }
	       num_tu = av_len((AV *)SvRV(hval));
	       /* Arrary too large?  Is there a clever way not to do this? */
	       if (  num_tu >= (OS390_STDIO_SVC99_TEXT_UNITS - 1) ) {
	           warn("array reference passed into S99TXTPP too large, %d elements.",(num_tu+1));
	           warnings++;
	           XSRETURN_UNDEF;
	       }
	       for ( j=0; j<=num_tu; j++ ) {
	           tu[j] = (char *)SvPV(*av_fetch((AV *)SvRV(hval), j, 0),len);
	       }
	       /* signal end */
	       tu[num_tu] = (char *)((long unsigned) ( tu[num_tu] ) | OS390_STDIO_SVC99_MASK );
	       parmstring.__S99TXTPP = (void * )tu; 
	       got_any++;
	   }
	   /* rbx identifier           */
/*        else if (strEQ(key,"S99EID"))    { rbxstring -> __S99EID = (char * )SvPV(hval,len);          got_any++; }
 *      __S99EVER;  __S99EOPTS; __S99ESUBP; __S99EKEY; __S99EMGSV; __S99ENMSG; __S99ECPPL; __reserved;
 *      __S99ERES; __S99ERCO; __S99ERCF; __S99EWRC; __S99EMSGP; __S99EERR; __S99EINFO; __reserv2;
 */
	   i++;
	   if (got_any != i) {
	       warn("svc99() warning key '%s' not recognized.\n",key);
	       XSRETURN_UNDEF;
	       warnings++;
	       got_any = i; /* avoid war-ning for more than one unrecognized key */
	   }
	    }
	    ST(0) = sv_newmortal();
	    if ( !warnings ) {
	        if (svc99(&parmstring) == 0) { 
	            ST(0) = &PL_sv_yes;
	        }
	        else { 
	            warn("svc99() failed with error code %hX, info code %hX", 
                          parmstring.__S99ERROR, parmstring.__S99INFO);
	            ST(0) = &PL_sv_undef;
	        }
	    }
	    else {
	        warn("svc99() unable to initialize struct __S99parms");
	        ST(0) = &PL_sv_undef;
	    }

char *
sysdsnr(name)
	char *	name
	PROTOTYPE: $
	CODE:
	    FILE * fp;
	    fp = fopen(name,"r");
	    if (fp != Nullfp && (fclose(fp) == 0)) { ST(0) = &PL_sv_yes; }
	    else { ST(0) = &PL_sv_undef; }

char *
tmpnam()
	PROTOTYPE:
	CODE:
	    char fname[L_tmpnam];
	    ST(0) = sv_newmortal();
	    if (tmpnam(fname) != NULL) sv_setpv(ST(0),fname);

char *
vol_ser(fp)
	FILE *	fp
	PROTOTYPE: $
	CODE:
	    /* catalogs and VTOCS are tough :-} */
	    croak("vol_ser() not yet implemented.\n");
	    ST(0) = sv_newmortal();
	    ST(0) = &PL_sv_undef;

void
vsamdelrec(fp)
	FILE *	fp
	PROTOTYPE: $
	CODE:
	    int rc = fdelrec(fp);
	    ST(0) = rc ? &PL_sv_undef : &PL_sv_yes;

void
vsamlocate(fp, key, key_len, options)
	FILE *	fp
	void* key
	unsigned int key_len
	int options
	PROTOTYPE: @
	CODE:
	    int rc = flocate(fp, key, key_len, options);
	    ST(0) = rc ? &PL_sv_undef : &PL_sv_yes;

int
vsamupdate(fp,buffer,size)
	FILE *	fp
	void* buffer
	size_t size
	PROTOTYPE: @
	CODE:
	    RETVAL = fupdate(buffer, size, fp);
	OUTPUT:
	    RETVAL

