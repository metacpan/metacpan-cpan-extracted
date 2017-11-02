/* Nanar <nanardon@zarb.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. */

/* $Id$ */

/* PREPROSSEUR FLAGS
 * HHACK: if defined, activate some functions or behaviour for expert user who
 *        want hacking purpose in their perl code
 * HDLISTDEBUG: activate some debug code
 * HDRPMDEBUG:  activate rpm debug internals flags
 * HDRPMMEM:    print message about Free()/New on rpm
 * HDEBUG:      active all debug flags
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#undef Fflush
#undef Mkdir
#undef Stat

/* copy data into rpm or use the header */
#define O_SCAREMEM 0 /* If returning perl object */
#define SCAREMEM 0

/* Pre processor flags for debugging purpose */

#ifdef HDEBUG
    #undef HDLISTDEBUG
    #define HDLISTDEBUG
    #undef HDRPMDEBUG
    #define HDRPMDEBUG
    #undef HDRPMMEM
    #define HDRPMMEM
#endif

#ifdef HDRPMMEM
    #define PRINTF_FREE(o, a, r) fprintf(stderr, "HDEBUG FREE: %s[%p], %d at %s:%d\n", (o), (a), (r), CopFILE(PL_curcop), CopLINE(PL_curcop))
    #define PRINTF_NEW(o, a, r) fprintf(stderr, "HDEBUG NEW : %s[%p], %d at %s:%d\n", (o), (a), (r), CopFILE(PL_curcop), CopLINE(PL_curcop))
#endif

#ifdef HDLISTDEBUG
    #define PRINTF_CALL fprintf(stderr, "HDEBUG RUN: %s() at %s:%d\n", __FUNCTION__, CopFILE(PL_curcop), CopLINE(PL_curcop))
#endif

#if defined(HDRPMMEM) || defined(HDRPMDEBUG)
     #define _RPMDS_INTERNAL
     #define _RPMFI_INTERNAL
     #define _RPMTS_INTERNAL
     #define HD_HEADER_INTERNAL
#endif

#include "rpmversion.h"

#include <rpm/rpmspec.h>
#include <rpm/header.h>
#include <rpm/rpmio.h>
#include <rpm/rpmdb.h>
#include <rpm/rpmds.h>
#include <rpm/rpmts.h>
#include <rpm/rpmte.h>
#include <rpm/rpmps.h>
#include <rpm/rpmfi.h>
#include <rpm/rpmpgp.h>
#include <rpm/rpmbuild.h>
#include <rpm/rpmfileutil.h>
#include <rpm/rpmlib.h>
#include <rpm/rpmlog.h>
#include <rpm/rpmpgp.h>
#include <rpm/rpmtag.h>
#include <rpm/rpmcli.h>
#include <rpm/rpmsign.h>

#ifdef HAVE_RPMCONSTANT
#include <rpmconstant/rpmconstant.h>
#else
#include "rpmconstant.h"
#endif

#include "RPM4.h"

static unsigned char header_magic[8] = {
    0x8e, 0xad, 0xe8, 0x01, 0x00, 0x00, 0x00, 0x00
};

typedef struct Package_s * Package;

#define CHECK_RPMDS_IX(dep) if (rpmdsIx((dep)) < 0) croak("You call RPM4::Header::Dependencies method after lastest next() of before init()")

#define bless_rpmds "RPM4::Header::Dependencies"
#define bless_rpmps "RPM4::Db::_Problems"
#define bless_rpmts "RPM4::Transaction"
#define bless_header "RPM4::Header"
#define bless_rpmfi "RPM4::Header::Files"
#define bless_spec "RPM4::Spec"

/* The perl callback for output err messages */
SV * log_callback_function = NULL;

static int scalar2constant(SV * svconstant, const char * context, int * val) {
    int rc = 0;
    if (!svconstant || !SvOK(svconstant)) {
        warn("Use of an undefined value");
        return 0;
    } else if (SvIOK(svconstant)) {
        *val = SvIV(svconstant);
        rc = 1;
    } else if (SvPOK(svconstant)) {
        rc = rpmconstantFindName((char *)context, (void *) SvPV_nolen(svconstant), val, 0);
    } else {
    }
    return rc;
}

static int sv2constant(SV * svconstant, const char * context) {
    AV * avparam;
    int val = 0;
    SV **tmpsv;
    int i;
    if (svconstant == NULL) {
        return 0;
    } else if (!SvOK(svconstant)) {
        return 0;
    } else if (SvPOK(svconstant) || SvIOK(svconstant)) {
        if (!scalar2constant(svconstant, context, &val))
            warn("Unknow value '%s' in '%s'", SvPV_nolen(svconstant), context);
    } else if (SvTYPE(SvRV(svconstant)) == SVt_PVAV) {
        avparam = (AV*) SvRV(svconstant);
        for (i = 0; i <= av_len(avparam); i++) {
            tmpsv = av_fetch(avparam, i, 0);
            if (!scalar2constant(*tmpsv, context, &val))
                warn("Unknow value '%s' in '%s' from array", SvPV_nolen(*tmpsv), context);
        }
    } else {
    }
    return val;
}

/* Parse SV arg and return assossiated RPMLOG value */
#define sv2loglevel(sv) sv2constant((sv), "rpmlog")

#define sv2deptag(sv) sv2constant((sv), "rpmtag")

/* compatibility */
#define sv2sens(sv) sv2senseflags(sv)

#define sv2vsflags(sv) sv2constant((sv), "rpmvsflags")

#define sv2transflags(sv) sv2constant((sv), "rpmtransflags")

static rpmTag sv2dbquerytag(SV * sv_tag) {
    int val = 0;
    if (!scalar2constant(sv_tag, "rpmdbi", &val) && !scalar2constant(sv_tag, "rpmtag", &val))
        croak("unknown tag value '%s'", SvPV_nolen(sv_tag));
    return val;
}

#define sv2rpmbuildflags(sv) sv2constant((sv), "rpmbuildflags")

#define sv2fileattr(sv) sv2constant((sv), "rpmfileattrs")

#define sv2senseflags(sv) sv2constant((sv), "rpmsenseflags")

#define sv2tagtype(sv) sv2constant((sv), "rpmtagtype")

/*
 * From URPM.xs:
 */

static char *
get_name(Header header, int32_t tag) {
  struct rpmtd_s val;

  headerGet(header, tag, &val, HEADERGET_MINMEM);
  char *name = (char *) rpmtdGetString(&val);
  rpmtdFreeData(&val);
  return name ? name : "";
}

static char*
get_arch(Header header) {
     return headerIsEntry(header, RPMTAG_SOURCERPM) ? get_name(header, RPMTAG_ARCH) : "src";
}

/*
 * End of URPM import
 * */


/* This function replace the standard rpmShowProgress callback
 * during transaction to allow perl callback */

static void *
    transCallback(const void *h,
       const rpmCallbackType what,
       const rpm_loff_t amount,
       const rpm_loff_t total,
       fnpyKey pkgKey,
       rpmCallbackData data) {
    
    /* The call back is used to open/close file, so we fix value, run the perl callback
     * and let rpmShowProgress from rpm rpmlib doing its job.
     * This unsure we'll not have to follow rpm code at each change. */
    const char * filename = (const char *)pkgKey;
    const char * s_what = NULL;
    dSP;

#ifdef HDLISTDEBUG
    fprintf(stderr, "HDEBUG: RPM4: running Callback transCallback()");
#endif
    
    PUSHMARK(SP);
    
    switch (what) {
        case RPMCALLBACK_UNKNOWN:
            s_what = "UNKNOWN";
        break;
        case RPMCALLBACK_INST_OPEN_FILE:
            if (filename != NULL && filename[0] != '\0') {
                mXPUSHs(newSVpv("filename", 0));
                mXPUSHs(newSVpv(filename, 0));
            }
            s_what = "INST_OPEN_FILE";
        break;
        case RPMCALLBACK_INST_CLOSE_FILE:
            s_what = "INST_CLOSE_FILE";
        break;
        case RPMCALLBACK_INST_PROGRESS:
            s_what = "INST_PROGRESS";
        break;
        case RPMCALLBACK_INST_START:
            s_what = "INST_START";
            if (h) {
                mXPUSHs(newSVpv("header", 0));
                mXPUSHs(sv_setref_pv(newSVpvs(""), bless_header, headerLink(h)));
#ifdef HDRPMMEM
                PRINTF_NEW(bless_header, &h, -1);
#endif
            }
        break;
        case RPMCALLBACK_TRANS_PROGRESS:
            s_what = "TRANS_PROGRESS";
        break;
        case RPMCALLBACK_TRANS_START:
            s_what = "TRANS_START";
        break;
        case RPMCALLBACK_TRANS_STOP:
            s_what = "TRANS_STOP";
        break;
        case RPMCALLBACK_UNINST_PROGRESS:
            s_what = "UNINST_PROGRESS";
        break;
        case RPMCALLBACK_UNINST_START:
            s_what = "UNINST_START";
        break;
        case RPMCALLBACK_UNINST_STOP:
            s_what = "UNINST_STOP";
        break;
        case RPMCALLBACK_UNPACK_ERROR:
            s_what = "UNPACKAGE_ERROR";
        break;
        case RPMCALLBACK_CPIO_ERROR:
            s_what = "CPIO_ERROR";
        break;
        case RPMCALLBACK_SCRIPT_ERROR:
            s_what = "SCRIPT_ERROR";
        break;
    }
   
    mXPUSHs(newSVpv("what", 0));
    mXPUSHs(newSVpv(s_what, 0));
    mXPUSHs(newSVpv("amount", 0));
    mXPUSHs(newSViv(amount));
    mXPUSHs(newSVpv("total", 0));
    mXPUSHs(newSViv(total));
    PUTBACK;
    call_sv((SV *) data, G_DISCARD | G_SCALAR);
    SPAGAIN;
  
    /* Running rpmlib callback, returning its value */
    return rpmShowProgress(h,
            what, 
            amount, 
            total, 
            pkgKey, 
            (long *) INSTALL_NONE /* shut up */);
}

/* This function is called by rpm if a callback
 * is set for for the logging system.
 * If the callback is set, rpm does not print any message,
 * and let the callback to do it */
int logcallback(rpmlogRec rec, rpmlogCallbackData data) {
    dSP;
    if (log_callback_function) {
        int logcode = rpmlogCode();
#ifdef HDLISTDEBUG
        fprintf(stderr, "HDEBUG: RPM4: running Callback logcallback()");
#endif

        PUSHMARK(SP);
        mXPUSHs(newSVpv("logcode", 0));
        mXPUSHs(newSViv(logcode));
        mXPUSHs(newSVpv("msg", 0));
        mXPUSHs(newSVpv((char *) rpmlogMessage(), 0));
        mXPUSHs(newSVpv("priority", 0));
        mXPUSHs(newSViv(RPMLOG_PRI(logcode)));
        PUTBACK;
        call_sv(log_callback_function, G_DISCARD | G_SCALAR);
        SPAGAIN;
    }
    return RPMLOG_DEFAULT;
}

/**************************************************
 * Real Function rpmts function with double call  *
 * Aka function(arg) or RPM4::Db->function(arg) *
 * This permit to reuse existing rpmts object     *
 **************************************************/

void _rpm2header(rpmts ts, char * filename, int checkmode) {
    FD_t fd;
    Header ret = NULL;
    rpmRC rc;
    dSP;
#ifdef HDLISTDEBUG
    PRINTF_CALL;
#endif
    if ((fd = Fopen(filename, "r"))) {
        rc = rpmReadPackageFile(ts, fd, filename, &ret);
	    if (checkmode) {
	        mXPUSHs(newSViv(rc));
		    ret = headerFree(ret); /* For checking the package, we don't keep the header */
        } else {
            if (rc == 0) {
        	    mXPUSHs(sv_setref_pv(newSVpvs(""), bless_header, (void *)ret));
#ifdef HDRPMMEM
                PRINTF_NEW(bless_header, ret, ret->nrefs);
#endif
            } else {
                mXPUSHs(&PL_sv_undef);
            }
	    }
        Fclose(fd);
    } else {
        mXPUSHs(&PL_sv_undef);
    }
        
    PUTBACK;
    return;
}

void _newdep(SV * sv_deptag, char * name, SV * sv_sense, SV * sv_evr) {
    rpmTag deptag = 0;
    rpmsenseFlags sense = RPMSENSE_ANY;
    rpmds Dep;
    char * evr = NULL;
    dSP;

    if (sv_deptag && SvOK(sv_deptag))
        deptag = sv2deptag(sv_deptag);
    if (sv_sense && SvOK(sv_sense))
        sense = sv2sens(sv_sense);
    if (sv_evr && SvOK(sv_evr))
        evr = SvPV_nolen(sv_evr);
    Dep = rpmdsSingle(deptag, name, evr ? evr : "", sense);
    if (Dep) {
        mXPUSHs(sv_setref_pv(newSVpvs(""), bless_rpmds, Dep));
    }
    PUTBACK;
}

/* Get a new specfile */
void _newspec(rpmts ts, char * filename, SV * svanyarch, SV * svforce) {
    rpmSpec spec = NULL;
    int anyarch = 0;
    int force = 0;
    dSP;

    if (svanyarch && SvOK(svanyarch))
	anyarch = SvIV(svanyarch);
    
    if (svforce && SvOK(svforce))
	force = SvIV(svforce);
    
    if (filename) {
        rpmSpecFlags flags = 0;
        if (anyarch)
             flags |= RPMSPEC_ANYARCH;
        if (force)
             flags |= RPMSPEC_FORCE;
        spec = rpmSpecParse(filename, flags, NULL);
#ifdef HHACK
    } else {
        spec = newSpec();
#endif
    }
    if (spec) {
        mXPUSHs(sv_setref_pv(newSVpvs(""), bless_spec, (void *)spec));
#ifdef HDRPMMEM
        PRINTF_NEW(bless_spec, spec, -1);
#endif
    } else
        mXPUSHs(&PL_sv_undef);
    PUTBACK;
    return;
}

/* Building a spec file */
int _specbuild(rpmts ts, rpmSpec spec, SV * sv_buildflags) {
    rpmBuildFlags buildflags = sv2rpmbuildflags(sv_buildflags);
    if (buildflags == RPMBUILD_NONE) croak("No action given for build");
    BTA_t flags = calloc(1, sizeof(*flags));
    flags->buildAmount = buildflags;
    return rpmSpecBuild(spec, flags);
}

void _installsrpms(rpmts ts, char * filename) {
    char * specfile = NULL;
    char * cookies = NULL;
    dSP;
    I32 gimme = GIMME_V;
    if (rpmInstallSource(
                ts,
                filename,
                &specfile,
                &cookies) == 0) { 
        mXPUSHs(newSVpv(specfile, 0));
        if (gimme == G_ARRAY)
        mXPUSHs(newSVpv(cookies, 0));
    }
    PUTBACK;
}

int _header_vs_dep(Header h, rpmds dep, int nopromote) {
    CHECK_RPMDS_IX(dep);
    return rpmdsAnyMatchesDep(h, dep, nopromote);
    /* return 1 if match */
}

int _headername_vs_dep(Header h, rpmds dep, int nopromote) {
    char *name;
    int rc = 0;
    CHECK_RPMDS_IX(dep);
    struct rpmtd_s val;

    headerGet(h, RPMTAG_NAME, &val, HEADERGET_MINMEM);
    name = (char *) rpmtdGetString(&val);
    if (strcmp(name, rpmdsN(dep)) != 0)
        rc = 0;
    else
        rc = rpmdsNVRMatchesDep(h, dep, nopromote);
    rpmtdFreeData(&val);
    return rc;
    /* return 1 if match */
}

/* Hight level function */
int rpmsign(char *passphrase, const char *rpm) {
#ifdef RPM4_12_90
    return rpmPkgSign(rpm, NULL);
#else
    return rpmPkgSign(rpm, NULL, passphrase);
#endif
}

MODULE = RPM4 PACKAGE = RPM4

BOOT:
if (rpmReadConfigFiles(NULL, NULL) != 0)
    croak("Can't read configuration");
#ifdef HDLISTDEBUG
rpmSetVerbosity(RPMLOG_DEBUG);
#else
rpmSetVerbosity(RPMLOG_NOTICE);
#endif
#ifdef HDRPMDEBUG
_rpmds_debug = -1;
_rpmdb_debug = -1;
_rpmts_debug = -1;
_rpmfi_debug = -1;
_rpmte_debug = -1;
#endif

int
isdebug()
    CODE:
#ifdef HDLISTDEBUG
    RETVAL = 1;
#else
    RETVAL = 0;
#endif
    OUTPUT:
    RETVAL

void
moduleinfo()
    PPCODE:
    mXPUSHs(newSVpv("Hack", 0));
#ifdef HHACK
    mXPUSHs(newSVpv("Yes", 0));
#else
    mXPUSHs(newSVpv("No", 0));
#endif
    
    mXPUSHs(newSVpv("RPMVERSION", 0));
    mXPUSHs(newSVpv(RPMVERSION, 0));
    
    mXPUSHs(newSVpv("RPM4VERSION", 0));
    mXPUSHs(newSVpv(VERSION, 0));
    
    mXPUSHs(newSVpv("RPMNAME", 0));
    mXPUSHs(newSVpv(rpmNAME, 0));
    
    mXPUSHs(newSVpv("RPMEVR", 0));
    mXPUSHs(newSVpv(rpmEVR, 0));

# Functions to control log/verbosity
    
void
setverbosity(svlevel)
    SV * svlevel
    CODE:
    rpmSetVerbosity(sv2loglevel(svlevel));

void
setlogcallback(function)
    SV * function
    CODE:
    if (function == NULL || !SvOK(function)) {
        rpmlogSetCallback(NULL, NULL);
    } else if (SvTYPE(SvRV(function)) == SVt_PVCV) {
        log_callback_function = newSVsv(function);
        rpmlogSetCallback(logcallback, NULL);
    } else
        croak("First arg is not a code reference");

void
lastlogmsg()
    PPCODE:
    mXPUSHs(newSViv(rpmlogCode()));
    mXPUSHs(newSVpv((char *) rpmlogMessage(), 0));

int
setlogfile(filename)
    char * filename
    PREINIT:
    FILE * ofp = NULL;
    FILE * fp = NULL;
    CODE:
    if (filename && *filename != 0) {
        if ((fp = fopen(filename, "a+")) == NULL) {
            XSprePUSH; PUSHi((IV)0);
            XSRETURN(1);
        }
    }
    if((ofp = rpmlogSetFile(fp)) != NULL)
        fclose(ofp);
    RETVAL=1;
    OUTPUT:
    RETVAL
    
int
readconfig(rcfile = NULL, target = NULL)
    char * rcfile
    char * target
    CODE:
    RETVAL = rpmReadConfigFiles(rcfile && rcfile[0] ? rcfile : NULL, target);
    OUTPUT:
    RETVAL

void
rpmlog(svcode, msg)
    SV * svcode
    char * msg
    CODE:
    rpmlog(sv2loglevel(svcode), "%s", msg);
    
# Return hash of know tag
# Name => internal key (if available)

void
querytag()
    PREINIT:
    CODE:

int
tagtypevalue(svtagtype)
    SV * svtagtype
    CODE:
    RETVAL = sv2tagtype(svtagtype);
    OUTPUT:
    RETVAL

int
tagValue(tagname)
    char * tagname
    CODE:
    RETVAL = rpmTagGetValue((const char *) tagname);
    OUTPUT:
    RETVAL

void
tagName(tag)
    int tag
    PREINIT:
    const char *r  = NULL;
    PPCODE:
    r = rpmTagGetName(tag);
    mXPUSHs(newSVpv(r, 0));

void
flagvalue(flagtype, sv_value)
    char * flagtype
    SV * sv_value
    PPCODE:
    if (strcmp(flagtype, "loglevel") == 0) {
        mXPUSHs(newSViv(sv2constant(sv_value, "rpmlog")));
    } else if (strcmp(flagtype, "deptag") == 0) { /* Who will use this ?? */
        mXPUSHs(newSViv(sv2deptag(sv_value)));
    } else if (strcmp(flagtype, "vsf") == 0) {
        mXPUSHs(newSViv(sv2constant(sv_value, "rpmverifyflags")));
    } else if (strcmp(flagtype, "trans") == 0) {
        mXPUSHs(newSViv(sv2transflags(sv_value)));
    } else if (strcmp(flagtype, "dbquery") == 0) {
        mXPUSHs(newSViv(sv2dbquerytag(sv_value)));
    } else if (strcmp(flagtype, "build") == 0) {
        mXPUSHs(newSViv(sv2rpmbuildflags(sv_value)));
    } else if (strcmp(flagtype, "fileattr") == 0) {
        mXPUSHs(newSViv(sv2fileattr(sv_value)));
    } else if (strcmp(flagtype, "sense") == 0) {
        mXPUSHs(newSViv(sv2senseflags(sv_value)));
    } else if (strcmp(flagtype, "tagtype") == 0) {
        mXPUSHs(newSViv(sv2tagtype(sv_value)));
    } else if (strcmp(flagtype, "list") == 0) {
        mXPUSHs(newSVpv("loglevel", 0));
        mXPUSHs(newSVpv("deptag",   0));
        mXPUSHs(newSVpv("vsf",      0));
        mXPUSHs(newSVpv("trans",    0));
        mXPUSHs(newSVpv("dbquery",  0));
        mXPUSHs(newSVpv("build",    0));
        mXPUSHs(newSVpv("fileattr", 0));
        mXPUSHs(newSVpv("tagtype",  0));
    }

# Macros functions:

void
expand(name)
    char * name
    PPCODE:
    const char * value = rpmExpand(name, NULL);
    mXPUSHs(newSVpv(value, 0));
    free((char *) value);

void
expandnumeric(name)
    char *name
    PPCODE:
    int value = rpmExpandNumeric(name);
    mXPUSHs(newSViv(value));
    
void
addmacro(macro)
    char * macro
    CODE:
    rpmDefineMacro(NULL, macro, RMIL_DEFAULT);

void
delmacro(name)
    char * name
    CODE:
    delMacro(NULL, name);

void
loadmacrosfile(filename)
    char * filename
    PPCODE:
    rpmInitMacros(NULL, filename);

void
resetmacros()
    PPCODE:
    rpmFreeMacros(NULL);

void
resetrc()
    PPCODE:
    rpmFreeRpmrc();
    
void
getosname()
    PREINIT:
    const char *v = NULL;
    PPCODE:
    rpmGetOsInfo(&v, NULL);
    mXPUSHs(newSVpv(v, 0));

void
getarchname()
    PREINIT:
    const char *v = NULL;
    PPCODE:
    rpmGetArchInfo(&v, NULL);
    mXPUSHs(newSVpv(v, 0));

int
osscore(data, build = 0)
    char * data;
    int build;
    ALIAS:
        archscore = 1
    PREINIT:
    int machtable;
    CODE:
    if (ix == 0)
         machtable = build ? RPM_MACHTABLE_BUILDOS   : RPM_MACHTABLE_INSTOS;
    else
         machtable = build ? RPM_MACHTABLE_BUILDARCH : RPM_MACHTABLE_INSTARCH;
    RETVAL = rpmMachineScore(machtable, data);
    OUTPUT:
    RETVAL
    
void
buildhost()
    PREINIT:
    PPCODE:
    static char hostname[1024];
    static int oneshot = 0;
    struct hostent *hbn;
    
    if (! oneshot) {
        (void) gethostname(hostname, sizeof(hostname));
       hbn = gethostbyname(hostname);
       if (hbn)
           strcpy(hostname, hbn->h_name);
       else
           rpmlog(RPMLOG_WARNING,
                       _("Could not canonicalize hostname: %s\n"), hostname);
       oneshot = 1;
    }
    mXPUSHs(newSVpv(hostname,0));
    
# Dump to file functions:
void
dumprc(fp)
    FILE *fp
    CODE:
    rpmShowRC(fp);

void
dumpmacros(fp)
    FILE *fp
    CODE:
    rpmDumpMacroTable(NULL, fp);

int
rpmvercmp(one, two)
    char *one
    char *two

# create a new empty header
# Is this usefull

void
headernew()
    PREINIT:
    Header h = headerNew();
    PPCODE:
    mXPUSHs(sv_setref_pv(newSVpvs(""), bless_header, (void *)h));
#ifdef HDRPMMEM
    PRINTF_NEW(bless_header, h, h->nrefs);
#endif


# Read data from file pointer and return next header object
# Return undef if failed
# fedora use HEADER_MAGIC_NO, too bad, set no_header_magic make the function
# compatible
void
stream2header(fp, no_header_magic = 0, callback = NULL)
    FILE *fp
    int no_header_magic
    SV * callback
    PREINIT:
    FD_t fd;
    Header header;
    PPCODE:
    if (fp && (fd = fdDup(fileno(fp)))) {
#ifdef HDLISTDEBUG
        PRINTF_CALL;
#endif
        if (callback != NULL && SvROK(callback)) {
            while ((header = headerRead(fd, no_header_magic ? HEADER_MAGIC_NO : HEADER_MAGIC_YES))) {
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                mXPUSHs(sv_setref_pv(newSVpvs(""), bless_header, (void *)header));
#ifdef HDRPMMEM
                PRINTF_NEW(bless_header, header, header->nrefs);
#endif
                PUTBACK;
                call_sv(callback, G_DISCARD | G_SCALAR);
                SPAGAIN;
                FREETMPS;
                LEAVE;
            }
        } else {
            header = headerRead(fd, no_header_magic ? HEADER_MAGIC_NO : HEADER_MAGIC_YES);
            if (header) {
                mXPUSHs(sv_setref_pv(newSVpvs(""), bless_header, (void *)header));
#ifdef HDRPMMEM
                PRINTF_NEW(bless_header, header, header->nrefs);
#endif

            }
#ifdef HDLISTDEBUG
            else fprintf(stderr, "HDEBUG: No header found from fp: %d\n", fileno(fp));
#endif
        }
        Fclose(fd);
    }

# Read a rpm and return a Header
# Return undef if failed
void
rpm2header(filename, sv_vsflags = NULL)
    char * filename
    SV * sv_vsflags
    PREINIT:
    rpmts ts = rpmtsCreate();
    rpmVSFlags vsflags = RPMVSF_DEFAULT; 
    PPCODE:
    if (sv_vsflags == NULL) /* Nothing has been passed, default is no signature */
        vsflags |= _RPMVSF_NOSIGNATURES;
    else
        vsflags = sv2vsflags(sv_vsflags);
    rpmtsSetVSFlags(ts, vsflags);
    _rpm2header(ts, filename, 0);
    SPAGAIN;
    ts = rpmtsFree(ts);

int
rpmresign(passphrase, rpmfile)
    char * passphrase
    char * rpmfile
    CODE:
    RETVAL = rpmsign(passphrase, (const char *) rpmfile);
    OUTPUT:
    RETVAL
    
void
installsrpm(filename, sv_vsflags = NULL)
    char * filename
    SV * sv_vsflags
    PREINIT:
    rpmts ts = rpmtsCreate();
    rpmVSFlags vsflags = RPMVSF_DEFAULT;
    PPCODE:
    vsflags = sv2vsflags(sv_vsflags);
    rpmtsSetVSFlags(ts, vsflags);
    PUTBACK;
    _installsrpms(ts, filename);
    SPAGAIN;
    ts = rpmtsFree(ts);

MODULE = RPM4		PACKAGE = RPM4::Header	PREFIX = Header_

void
Header_DESTROY(h)
    Header h
    CODE:
#ifdef HDRPMMEM
    PRINTF_FREE(bless_header, h, h->nrefs);
#endif
    headerFree(h);

# Write rpm header into file pointer
# fedora use HEADER_MAGIC_NO, too bad, set no_header_magic make the function
# compatible
int
Header_write(h, fp, no_header_magic = 0)
    Header h
    FILE * fp
    int no_header_magic
    PREINIT:
    FD_t fd;
    CODE:
    RETVAL = 0;
#ifdef HDLISTDEBUG
    PRINTF_CALL;
#endif
    if (h) {
        if ((fd = fdDup(fileno(fp))) != NULL) {
            headerWrite(fd, h, no_header_magic ? HEADER_MAGIC_NO : HEADER_MAGIC_YES);
            Fclose(fd);
            RETVAL = 1;
        }
    }
    OUTPUT:
    RETVAL

void
Header_hsize(h, no_header_magic = 0)
    Header h
    int no_header_magic
    PPCODE:
    mXPUSHs(newSViv(headerSizeof(h, no_header_magic ? HEADER_MAGIC_NO : HEADER_MAGIC_YES)));
    
void
Header_copy(h)
    Header h
    PREINIT:
    Header hcopy;
    PPCODE:
    hcopy = headerCopy(h);
    mXPUSHs(sv_setref_pv(newSVpvs(""), bless_header, (void *)hcopy));
#ifdef HDRPMMEM
    PRINTF_NEW(bless_header, hcopy, hcopy->nrefs);
#endif

void
Header_string(h, no_header_magic = 0)
    Header h
    int no_header_magic
    PREINIT:
    char * string = NULL;
    char * ptr = NULL;
    int hsize = 0;
    PPCODE:
    hsize = headerSizeof(h, no_header_magic ? HEADER_MAGIC_NO : HEADER_MAGIC_YES);
    string = headerUnload(h);
    if (! no_header_magic) {
        ptr = malloc(hsize);
        memcpy(ptr, header_magic, 8);
        memcpy(ptr + 8, string, hsize - 8);
    }
    mXPUSHs(newSVpv(ptr ? ptr : string, hsize));
    free(string);
    free(ptr);

int
Header_removetag(h, sv_tag)
    Header h
    SV * sv_tag
    PREINIT:
    rpmTag tag = -1;
    CODE:
    if (SvIOK(sv_tag)) {
        tag = SvIV(sv_tag);
    } else if (SvPOK(sv_tag)) {
        tag = rpmTagGetValue(SvPV_nolen(sv_tag));
    }
    if (tag > 0)
        RETVAL = headerDel(h, tag);
    else
        RETVAL = 1;
    OUTPUT:
    RETVAL

int
Header_addtag(h, sv_tag, sv_tagtype, ...)
    Header h
    SV * sv_tag
    SV * sv_tagtype
    PREINIT:
    char * value;
    int ivalue;
    int i;
    rpmTag tag = -1;
    rpmTagType tagtype = RPM_NULL_TYPE;
    STRLEN len;
    CODE:
    if (SvIOK(sv_tag)) {
        tag = SvIV(sv_tag);
    } else if (SvPOK(sv_tag)) {
        tag = rpmTagGetValue(SvPV_nolen(sv_tag));
    }
    tagtype = sv2tagtype(sv_tagtype);
    if (tag > 0)
        RETVAL = 1;
    else
        RETVAL = 0;
    /* if (tag == RPMTAG_OLDFILENAMES)
        expandFilelist(h); */
    for (i = 3; (i < items) && RETVAL; i++) {
       struct rpmtd_s td = {
           .tag = tag,
           .type = tagtype,
           .data = (void *) &value,
           .count = 1,
        };
        switch (tagtype) {
            case RPM_CHAR_TYPE:
            case RPM_INT8_TYPE:
            case RPM_INT16_TYPE:
            case RPM_INT32_TYPE:
                ivalue = SvUV(ST(i));
                td.data = (void *) &ivalue;
                RETVAL = headerPut(h, &td, HEADERPUT_APPEND);
                break;
            case RPM_STRING_TYPE:
            case RPM_BIN_TYPE:
                value = (char *)SvPV(ST(i), len);
                RETVAL = headerPutString(h, tag, value);
                break;
            case RPM_STRING_ARRAY_TYPE:
                value = SvPV_nolen(ST(i));
                RETVAL = headerPut(h, &td, HEADERPUT_APPEND);
                break;
            default:
                value = SvPV_nolen(ST(i));
                RETVAL = headerPut(h, &td, HEADERPUT_APPEND);
                break;
        }
    }
    /* if (tag == RPMTAG_OLDFILENAMES) {
        compressFilelist(h); 
    } */
    OUTPUT:
    RETVAL
    
void
Header_listtag(h)
    Header h
    PREINIT:
    HeaderIterator iterator;
    struct rpmtd_s td;
    PPCODE:
    iterator = headerInitIterator(h);
    while (headerNext(iterator, &td)) {
        mXPUSHs(newSViv(rpmtdTag(&td)));
        rpmtdFreeData(&td);
    }
    rpmtdFreeData(&td);
    headerFreeIterator(iterator);
    
int
Header_hastag(h, sv_tag)
    Header h
    SV * sv_tag
    PREINIT:
    rpmTag tag = -1;
    CODE:
    if (SvIOK(sv_tag)) {
        tag = SvIV(sv_tag);
    } else if (SvPOK(sv_tag)) {
        tag = rpmTagGetValue(SvPV_nolen(sv_tag));
    }    
    if (tag > 0)
        RETVAL = headerIsEntry(h, tag);
    else
        RETVAL = -1;
    OUTPUT:
    RETVAL
 
# Return the tag value in headers
void
Header_tag(h, sv_tag)
    Header h
    SV * sv_tag
    PREINIT:
    rpmTag tag = -1;
    PPCODE:
    if (SvIOK(sv_tag)) {
        tag = SvIV(sv_tag);
    } else if (SvPOK(sv_tag)) {
        tag = rpmTagGetValue(SvPV_nolen(sv_tag));
    }
    if (tag > 0) {
        struct rpmtd_s val;
        if (headerGet(h, tag, &val, HEADERGET_DEFAULT)) {
            int type = rpmtdType(&val);
            int n = rpmtdCount(&val);

            switch(type) {
                case RPM_STRING_ARRAY_TYPE:
                    {
                        int i;

                        EXTEND(SP, n);
                        rpmtdInit(&val);
        
                        for (i = 0; i < n; i++)
                            mPUSHs(newSVpv(rpmtdNextString(&val), 0));
                    }
                break;
                case RPM_STRING_TYPE:
                    mPUSHs(newSVpv(rpmtdGetString(&val), 0));
                break;
                case RPM_CHAR_TYPE:
                case RPM_INT8_TYPE:
                case RPM_INT16_TYPE:
                case RPM_INT32_TYPE:
                    {
                        int i;

                        EXTEND(SP, n);
                        rpmtdInit(&val);

                        for (i = 0; i < n; i++) {
                            rpmtdNext(&val);
                            mPUSHs(newSViv(rpmtdGetNumber(&val)));
                        }
                    }
                break;
                case RPM_BIN_TYPE:
                    /* XXX HACK ALERT: element field abused as no. bytes of binary data. */
                    mPUSHs(newSVpv((char *)val.data, val.count));
                break;
                default:
                    croak("unknown rpm tag type %d", type);
            }
            rpmtdFreeData(&val);
        }
    }

unsigned int
Header_tagtype(h, sv_tag)
    Header h
    SV * sv_tag
    PREINIT:
    rpmTag tag = -1;
    struct rpmtd_s td;
    CODE:
    if (SvIOK(sv_tag)) {
        tag = SvIV(sv_tag);
    } else if (SvPOK(sv_tag)) {
        tag = rpmTagGetValue(SvPV_nolen(sv_tag));
    }
    RETVAL = RPM_NULL_TYPE;
    if (tag > 0)
        if (headerGet(h, tag, &td, HEADERGET_DEFAULT))
            RETVAL = rpmtdType(&td);
    rpmtdFreeData(&td);
    OUTPUT:
    RETVAL
    
void
Header_queryformat(h, query)
    Header h
    char * query
    PREINIT:
    char *s = NULL;
    PPCODE:
    s = headerFormat(h, query,
            NULL);
    mXPUSHs(newSVpv(s, 0));
    free(s);

void
Header_fullname(h)
    Header h
    ALIAS:
       nevr= 1
    PREINIT:
    I32 gimme = GIMME_V;
    PPCODE:
    if (h) {
        if (gimme == G_SCALAR) {
          char *nvr = headerGetAsString(h, RPMTAG_NVR);
          if (ix == 1) {
            mXPUSHs(newSVpv(nvr, 0));
          } else {
            mXPUSHs(newSVpvf("%s.%s", nvr, get_arch(h)));
          }
          free(nvr);
        } else if (gimme == G_ARRAY) {
            EXTEND(SP, 4);
            mPUSHs(newSVpv(get_name(h, RPMTAG_NAME), 0));
            mPUSHs(newSVpv(get_name(h, RPMTAG_VERSION), 0));
            mPUSHs(newSVpv(get_name(h, RPMTAG_RELEASE), 0));
            mPUSHs(newSVpv(get_arch(h), 0));
        }
    }

int
Header_issrc(h)
    Header h
    CODE:
    RETVAL = !headerIsEntry(h, RPMTAG_SOURCERPM);
    OUTPUT:
    RETVAL

# Dependancies versions functions

int
Header_compare(h1, h2)
    Header h1
    Header h2
    CODE:
    RETVAL = rpmVersionCompare(h1, h2);
    OUTPUT:
    RETVAL
    
void
Header_dep(header, type, scaremem = O_SCAREMEM)
    Header header
    SV * type
    int scaremem
    PREINIT:
    rpmds ds;
    rpmTag tag;
    PPCODE:
    tag = sv2deptag(type);
    ds = rpmdsNew(header, tag, scaremem);
    ds = rpmdsInit(ds);
    if (ds != NULL)
        if (rpmdsNext(ds) >= 0) {
            mXPUSHs(sv_setref_pv(newSVpvs(""), bless_rpmds, ds));
#ifdef HDRPMMEM
            PRINTF_NEW(bless_rpmds, ds, ds->nrefs);
#endif

        }

void
Header_files(header, scaremem = O_SCAREMEM)
    Header header
    int scaremem
    PREINIT:
    rpmfi Files = NULL;
    rpmts ts = NULL;  /* NULL;  setting this to NULL skip path relocation
                       * maybe a good deal is Header::Files(header, Dep = NULL) */
    PPCODE:
#ifdef HDLISTDEBUG
    PRINTF_CALL;
#endif 
    Files = rpmfiNew(ts, header, RPMTAG_BASENAMES, scaremem);
    if (Files != NULL && (Files = rpmfiInit(Files, 0)) != NULL && rpmfiNext(Files) >= 0) {
        SPAGAIN;
        XPUSHs(sv_setref_pv(sv_newmortal(), bless_rpmfi, (void *)Files));
#ifdef HDRPMMEM
        PRINTF_NEW(bless_rpmfi, Files, Files->nrefs);
#endif
    }

void
Header_hchkdep(h1, h2, type)
    Header h1
    Header h2
    SV * type
    PREINIT:
    rpmds ds = NULL;
    rpmds pro = NULL;
    rpmTag tag;
    PPCODE:
    tag = sv2deptag(type);
    ds = rpmdsNew(h1, tag, SCAREMEM);
    pro = rpmdsNew(h2, RPMTAG_PROVIDENAME, SCAREMEM);
#ifdef HDLISTDEBUG
    fprintf(stderr, "HDEBUG: Header::hchkdep %d: %s vs %s %p\n", tag, hGetNEVR(h1, NULL), hGetNEVR(h2, NULL), ds);
#endif
    if (ds != NULL) {
        rpmdsInit(ds);
        while (rpmdsNext(ds) >= 0) {
            rpmdsInit(pro);
            while (rpmdsNext(pro) >= 0) {
                if (rpmdsCompare(ds,pro)) {
                mXPUSHs(newSVpv(rpmdsDNEVR(ds), 0));
#ifdef HDLISTDEBUG
                fprintf(stderr, "HDEBUG: Header::hchkdep match %s %s p in %s\n", rpmdsDNEVR(ds), rpmdsDNEVR(pro), hGetNEVR(h2, NULL));
#endif
                break;
                }
            }
        }
    }
    pro = rpmdsFree(pro);
    ds = rpmdsFree(ds);

int
Header_matchdep(header, Dep, sv_nopromote = NULL)
    Header header
    SV * sv_nopromote
    rpmds Dep
    PREINIT:
    int nopromote = 0;
    CODE:
    if (sv_nopromote != NULL)
        nopromote = SvIV(sv_nopromote);    
    RETVAL = _header_vs_dep(header, Dep, nopromote);
    OUTPUT:
    RETVAL

int
Header_namematchdep(header, Dep, sv_nopromote = NULL)
    Header header
    rpmds Dep
    SV * sv_nopromote
    PREINIT:
    int nopromote = 0;
    CODE:
    if (sv_nopromote != NULL)
        nopromote = SvIV(sv_nopromote);
    RETVAL = _headername_vs_dep(header, Dep, nopromote); /* return 1 if match */
    OUTPUT:
    RETVAL
    
# DB functions
MODULE = RPM4     PACKAGE = RPM4
    
int
rpmdbinit(rootdir = NULL)
    char * rootdir
    PREINIT:
    rpmts ts = rpmtsCreate();
    CODE:
    if (rootdir)
        rpmtsSetRootDir(ts, rootdir);
    /* rpm{db,ts}init is deprecated, we open a database with create flags
     *  and close it */
    /* 0 on success */
    RETVAL = rpmtsInitDB(ts, 0644);
    ts = rpmtsFree(ts);
    OUTPUT:
    RETVAL

int
rpmdbverify(rootdir = NULL)
    char * rootdir
    PREINIT:
    rpmts ts = rpmtsCreate();
    CODE:
    if (rootdir)
        rpmtsSetRootDir(ts, rootdir);
    /* 0 on success */
    RETVAL = rpmtsVerifyDB(ts);
    ts = rpmtsFree(ts);
    OUTPUT:
    RETVAL

int
rpmdbrebuild(rootdir = NULL)
    char * rootdir
    PREINIT:
    rpmts ts = rpmtsCreate();
    CODE:
    if (!rootdir) rootdir="/";
    if (rootdir) {
        rpmtsSetRootDir(ts, rootdir);
    }
    /* 0 on success */
    RETVAL = rpmtsRebuildDB(ts);
    ts = rpmtsFree(ts);
    OUTPUT:
    RETVAL

#ifdef HHACK
void
emptydb()
    PREINIT:
    rpmts ts = rpmtsCreate();
    PPCODE:
    mXPUSHs(sv_setref_pv(newSVpvs(""), bless_rpmts, (void *)ts));
#ifdef HDRPMMEM
    PRINTF_NEW(bless_rpmts, ts, ts->nrefs);
#endif


#endif
    
void
newdb(write = 0, rootdir = NULL)
    int write
    char * rootdir
    PREINIT:
    rpmts ts = rpmtsCreate();
    PPCODE:
    if (rootdir)
        rpmtsSetRootDir(ts, rootdir);
    
    rpmtsSetVSFlags(ts, RPMTRANS_FLAG_NONE);
    /* is O_CREAT a good idea here ? */
    /* is the rpmtsOpenDB really need ? */
    if (rpmtsOpenDB(ts, write ? O_RDWR | O_CREAT : O_RDONLY) == 0) {
        mXPUSHs(sv_setref_pv(newSVpvs(""), bless_rpmts, (void *)ts));
#ifdef HDRPMMEM
        PRINTF_NEW(bless_rpmts, ts, ts->nrefs);
#endif
    } else {
        ts = rpmtsFree(ts);
    }

MODULE = RPM4     PACKAGE = RPM4::Transaction    PREFIX = Ts_

void
Ts_new(perlclass, rootdir = NULL)
    char * perlclass
    char * rootdir
    PREINIT:
    rpmts ts = rpmtsCreate();
    PPCODE:
    rpmtsSetRootDir(ts, rootdir);
    mXPUSHs(sv_setref_pv(newSVpvs(""), perlclass, (void *)ts));
 
void
Ts_DESTROY(ts)
    rpmts ts
    CODE:
#ifdef HDRPMMEM
    PRINTF_FREE(bless_rpmts, ts, ts->nrefs);
#endif
    ts = rpmtsFree(ts);

# Function to control RPM4::Transaction behaviour

int
Ts_vsflags(ts, sv_vsflags = NULL)
    rpmts ts
    SV * sv_vsflags
    PREINIT:
    rpmVSFlags vsflags; 
    CODE:
    if (sv_vsflags != NULL) {
        vsflags = sv2vsflags(sv_vsflags);
        RETVAL = rpmtsSetVSFlags(ts, vsflags);
    } else {
        RETVAL = rpmtsVSFlags(ts);
    }
    OUTPUT:
    RETVAL

int
Ts_transflag(ts, sv_transflag = NULL)
    rpmts ts
    SV * sv_transflag
    PREINIT:
    rpmtransFlags transflags;
    CODE:
    if (sv_transflag != NULL) {
        transflags = sv2transflags(sv_transflag);
        RETVAL = rpmtsSetFlags(ts, transflags);
    } else {
        RETVAL = rpmtsFlags(ts);
    }
    OUTPUT:
    RETVAL
    
int
Ts_traverse(ts, callback = NULL, sv_tagname = NULL, sv_tagvalue = NULL, keylen = 0, sv_exclude = NULL)
    rpmts ts
    SV * callback
    SV * sv_tagname
    SV * sv_tagvalue
    SV * sv_exclude
    int keylen
    PREINIT:
    rpmDbiTagVal tag;
    void * value = NULL;
    rpmdbMatchIterator mi;
    Header header;
    int rc = 1;
    int count = 0;
    int * exclude = NULL;
    AV * av_exclude;
    int i;
    CODE:
#ifdef HDLISTDEBUG
    PRINTF_CALL;
#endif
    ts = rpmtsLink(ts);
    if (sv_tagname == NULL || !SvOK(sv_tagname)) {
        tag = RPMDBI_PACKAGES; /* Assume search into installed packages */
    } else {
        tag = sv2dbquerytag(sv_tagname);
    }
    if (sv_tagvalue != NULL && SvOK(sv_tagvalue)) {
        if (tag == RPMDBI_PACKAGES) {
                i = SvIV(sv_tagvalue);
                value = &i;
                keylen = sizeof(i);
        } else {
                value = (void *) SvPV_nolen(sv_tagvalue);
        }
    }
    
    RETVAL = 0;
    if (tag >= 0) {
        mi = rpmtsInitIterator(ts, tag, value, keylen);
        if (sv_exclude != NULL && SvOK(sv_exclude) && SvTYPE(SvRV(sv_exclude)) == SVt_PVAV) {
            av_exclude = (AV*)SvRV(sv_exclude);
            exclude = malloc((av_len(av_exclude)+1) * sizeof(int));
            for (i = 0; i <= av_len(av_exclude); i++) {
                SV **isv = av_fetch(av_exclude, i, 0);
                exclude[i] = SvUV(*isv);
            }
            //FIXME: rpmtsPrunedIterator() is rpmlib internal only:
            //rpmtsPrunedIterator(ts, exclude, av_len(av_exclude) + 1);
        }
        while (rc && ((header = rpmdbNextIterator(mi)) != NULL)) {
            RETVAL++;
            if (callback != NULL && SvROK(callback)) {
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                mXPUSHs(sv_setref_pv(newSVpvs(""), bless_header, headerLink(header)));
#ifdef HDRPMMEM
                PRINTF_NEW(bless_header, header, header->nrefs);
#endif
                mXPUSHs(newSVuv(rpmdbGetIteratorOffset(mi)));
                PUTBACK;
                count = call_sv(callback, G_SCALAR);
                SPAGAIN;
                if (tag == RPMDBI_PACKAGES && value != NULL) {
                    rc = 0;
                } else if (count == 1) {
                    rc = POPi;
                }
                FREETMPS;
                LEAVE;
                
            }
        }
        if (exclude != NULL) free(exclude);
        rpmdbFreeIterator(mi);
    } else
        RETVAL = -1;
    ts = rpmtsFree(ts);
    OUTPUT:
    RETVAL

void
Ts_get_header(ts, off)
    rpmts ts
    int off
    PREINIT:
    rpmdbMatchIterator mi;
    Header header;
    PPCODE:
    mi = rpmtsInitIterator(ts, RPMDBI_PACKAGES, &off, sizeof(off));
    if ((header = rpmdbNextIterator(mi)) != NULL) {
        mXPUSHs(sv_setref_pv(newSVpvs(""), bless_header, headerLink(header)));
#ifdef HDRPMMEM
        PRINTF_NEW(bless_header, header, header->nrefs);
#endif
    }
    rpmdbFreeIterator(mi);    

int
Ts_transadd(ts, header, key = NULL, upgrade = 1, sv_relocation = NULL, force = 0)
    rpmts ts
    Header header
    char * key
    int upgrade
    SV * sv_relocation
    int force
    PREINIT:
    rpmRelocation * relocations = NULL;
    HV * hv_relocation;
    HE * he_relocation;
    int i = 0;
    I32 len;
    
    CODE:

    if (key != NULL)
        key = strdup(key);

    /* Relocation settings */
    if (sv_relocation && SvOK(sv_relocation) && !force) {
/*        if (! (headerGetEntry(eiu->h, RPMTAG_PREFIXES, &pft,
                       (void **) &paths, &c) && (c == 1))) { */
        if (! headerIsEntry(header, RPMTAG_PREFIXES)) {
            rpmlog(RPMLOG_ERR,
                   _("package %s is not relocatable\n"), "");
            XPUSHi((IV)1);
            XSRETURN(1);
        }
        if (SvTYPE(sv_relocation) == SVt_PV) {
            /* String value, assume a prefix */
            relocations = malloc(2 * sizeof(*relocations));
            relocations[0].oldPath = NULL;
            relocations[0].newPath = SvPV_nolen(sv_relocation);
            relocations[1].oldPath = relocations[1].newPath = NULL;
        } else if (SvTYPE(SvRV(sv_relocation)) == SVt_PVHV) {
            hv_relocation = (HV*)SvRV(sv_relocation);
            hv_iterinit(hv_relocation);
            while ((he_relocation = hv_iternext(hv_relocation)) != NULL) {
                relocations = realloc(relocations, sizeof(*relocations) * (++i));
                relocations[i-1].oldPath = NULL;
                relocations[i-1].newPath = NULL;
                relocations[i-1].oldPath = hv_iterkey(he_relocation, &len);
                relocations[i-1].newPath = SvPV_nolen(hv_iterval(hv_relocation, he_relocation));
            }
            /* latest relocation is identify by NULL setting */
            relocations = realloc(relocations, sizeof(*relocations) * (++i));
            relocations[i-1].oldPath = relocations[i-1].newPath = NULL;
        } else {
            croak("latest argument is set but is not an array ref or a string");
        }
    }
    
    /* TODO fnpyKey: another value can be use... */
    RETVAL = rpmtsAddInstallElement(ts, header, (fnpyKey) key, upgrade, relocations);
    OUTPUT:
    RETVAL
        
int
Ts_transremove(ts, recOffset, header = NULL)
    rpmts ts
    int recOffset
    Header header
    PREINIT:
    rpmdbMatchIterator mi;
    CODE:
    RETVAL = 0;
    if (header != NULL) { /* reprofit Db_traverse */
        rpmtsAddEraseElement(ts, header, recOffset);
    } else {
        mi = rpmtsInitIterator(ts, RPMDBI_PACKAGES, &recOffset, sizeof(recOffset));
        if ((header = rpmdbNextIterator(mi)) != NULL) {
#ifdef HDLISTDEBUG
            fprintf(stderr, "HDEBUG: Db::transremove(h, o) H: %p Off:%u\n", header, recOffset);
#endif
            rpmtsAddEraseElement(ts, header, recOffset);
            RETVAL = 1;
        }
        rpmdbFreeIterator(mi);
    }
    OUTPUT:
    RETVAL

int
Ts_transremove_pkg(ts, N_evr)
    rpmts ts
    char * N_evr
    PREINIT:
    rpmdbMatchIterator mi;
    Header header;
    int recOffset;
    CODE:
    RETVAL = 0;
    /* N_evr is not NEVR but N(EVR), with RPMDBI_LABEL
    * I want to find another way to exactly match a header 
    * For more flexible function, check Db_traverse / Db_transremove */
    mi = rpmtsInitIterator(ts, RPMDBI_LABEL, N_evr, 0);
    while ((header = rpmdbNextIterator(mi))) {
        recOffset = rpmdbGetIteratorOffset(mi);
#ifdef HDLISTDEBUG
        fprintf(stderr, "HDEBUG: Db::transremove(Name) N: %s H: %p Off:%u\n", N_evr, header, recOffset);
#endif
        if (recOffset != 0) {
            rpmtsAddEraseElement(ts, header, recOffset);
            RETVAL ++;
        }
    }
    rpmdbFreeIterator(mi);
    OUTPUT:
    RETVAL

int
Ts_traverse_transaction(ts, callback, type = 0)
    rpmts ts
    SV * callback
    int type
    PREINIT:
    rpmtsi pi;
    rpmte  Te;
    CODE:
    ts = rpmtsLink(ts);
    pi = rpmtsiInit(ts);
    RETVAL = 0;
    while ((Te = rpmtsiNext(pi, type)) != NULL) {
        RETVAL++;
        if (callback != NULL && SvROK(callback)) {
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
#ifdef HDLISTDEBUG
            PRINTF_CALL;
#endif
            mXPUSHs(sv_setref_pv(newSVpvs(""), "RPM4::Db::Te", Te));
            PUTBACK;
            call_sv(callback, G_DISCARD | G_SCALAR);
            SPAGAIN;
            FREETMPS;
            LEAVE;
        }
    }
    pi = rpmtsiFree(pi);
    ts = rpmtsFree(ts);
    OUTPUT:
    RETVAL
        
int
Ts_transcheck(ts)
    rpmts ts
    CODE:
    RETVAL = rpmtsCheck(ts);
    OUTPUT:
    RETVAL

int
Ts_transorder(ts)
    rpmts ts
    CODE:
    RETVAL = rpmtsOrder(ts);
    OUTPUT:
    RETVAL

void
Ts_transclean(ts)
    rpmts ts
    PPCODE:
    rpmtsClean(ts);
        
int
Ts_transrun(ts, callback, ...)
    rpmts ts
    SV * callback
    PREINIT:
    int i;
    rpmprobFilterFlags probFilter = RPMPROB_FILTER_NONE;
    rpmInstallFlags install_flags = INSTALL_NONE;
    rpmps ps;
    CODE:
    ts = rpmtsLink(ts);
    if (!SvOK(callback)) { /* undef value */
        rpmtsSetNotifyCallback(ts,
                rpmShowProgress,
                (void *) ((long) INSTALL_LABEL | INSTALL_HASH | INSTALL_UPGRADE));
    } else if (SvTYPE(SvRV(callback)) == SVt_PVCV) { /* ref sub */
        rpmtsSetNotifyCallback(ts,
                transCallback, 
                (void *)
                    callback);
    } else if (SvTYPE(SvRV(callback)) == SVt_PVAV) { /* array ref */
        install_flags = sv2constant(callback, "rpminstallinterfaceflags");
        rpmtsSetNotifyCallback(ts,
                rpmShowProgress,
                (void *) ((long) install_flags));
    } else {
        croak("Wrong parameter given");
    }
    
    for (i = 2; i < items; i++)
        probFilter |= sv2constant(ST(i), "rpmprobfilterflags");

    ps = rpmtsProblems(ts);
    RETVAL = rpmtsRun(ts, ps, probFilter);
    ps = rpmpsFree(ps);
    ts = rpmtsFree(ts);
    OUTPUT:
    RETVAL

# get from transaction a problem set
void
Ts__transpbs(ts)
    rpmts ts
    PREINIT:
    rpmps ps;
    PPCODE:
    ps = rpmtsProblems(ts);
    if (ps && rpmpsNumProblems(ps)) /* if no problem, return undef */
        mXPUSHs(sv_setref_pv(newSVpvs(""), bless_rpmps, ps));
    
int
Ts_importpubkey(ts, filename)
    rpmts ts
    char * filename
    PREINIT:
    uint8_t *pkt = NULL;
    size_t pktlen = 0;
    int rc;
    CODE:
    rpmtsClean(ts);
    
    if ((rc = pgpReadPkts(filename, (uint8_t ** ) &pkt, &pktlen)) <= 0) {
        RETVAL = 1;
    } else if (rc != PGPARMOR_PUBKEY) {
        RETVAL = 1;
    } else if (rpmtsImportPubkey(ts, pkt, pktlen) != RPMRC_OK) {
        RETVAL = 1;
    } else {
        RETVAL = 0;
    }
    free(pkt);
    OUTPUT:
    RETVAL
   
void
Ts_checkrpm(ts, filename, sv_vsflags = NULL)
    rpmts ts
    char * filename
    SV * sv_vsflags
    PREINIT:
    rpmVSFlags vsflags = RPMVSF_DEFAULT;
    rpmVSFlags oldvsflags = RPMVSF_DEFAULT;
    PPCODE:
    oldvsflags = rpmtsVSFlags(ts); /* keep track of old settings */
    if (sv_vsflags != NULL) {
	    vsflags = sv2vsflags(sv_vsflags);
        rpmtsSetVSFlags(ts, vsflags);
    }
    PUTBACK;
    _rpm2header(ts, filename, 1); /* Rpmread header is not the most usefull, 
                                   * but no other function in rpmlib allow this :( */
    SPAGAIN;
    rpmtsSetVSFlags(ts, oldvsflags); /* resetting in case of change */
    
void
Ts_transreset(ts)
    rpmts ts
    PPCODE:
    rpmtsEmpty(ts);
    rpmtsSetRootDir(ts, "/");

# Remaping function:

# RPM4::rpm2header(filename); # Reusing existing RPM4::Db
void
Ts_rpm2header(ts, filename)
    rpmts ts
    char * filename
    PPCODE:
    _rpm2header(ts, filename, 0);
    SPAGAIN;

# RPM4::Spec::specbuild([ buildflags ]); Reusing existing RPM4::Db
int
Ts_specbuild(ts, spec, sv_buildflags)
    rpmts ts
    rpmSpec spec
    SV * sv_buildflags
    CODE:
    RETVAL = _specbuild(ts, spec, sv_buildflags);
    OUTPUT:
    RETVAL

void
Ts_installsrpm(ts, filename)
    rpmts ts
    char * filename
    PPCODE:
    PUTBACK;
    _installsrpms(ts, filename);
    SPAGAIN;

MODULE = RPM4 	PACKAGE = RPM4::Db::Te  PREFIX = Te_

void
Te_DESTROY(Te)
    rpmte Te
    CODE:
#ifdef HDRPMMEM
/*    PRINTF_FREE(RPM4::Db::Te, -1); */
#endif
    /* Don't do that !  *
    Te = rpmteFree(Te); */

int
Te_type(Te)
    rpmte Te
    CODE:
    RETVAL = rpmteType(Te);
    OUTPUT:
    RETVAL

void
Te_name(Te)
    rpmte Te
    PPCODE:
    mXPUSHs(newSVpv(rpmteN(Te), 0));

void
Te_version(Te)
    rpmte Te
    PPCODE:
    mXPUSHs(newSVpv(rpmteV(Te), 0));

void
Te_release(Te)
    rpmte Te
    PPCODE:
    mXPUSHs(newSVpv(rpmteR(Te), 0));

void
Te_epoch(Te)
    rpmte Te
    PPCODE:
    mXPUSHs(newSVpv(rpmteE(Te), 0));

void
Te_arch(Te)
    rpmte Te
    PPCODE:
    mXPUSHs(newSVpv(rpmteA(Te), 0));

void
Te_os(Te)
    rpmte Te
    PPCODE:
    mXPUSHs(newSVpv(rpmteO(Te), 0));

void
Te_fullname(Te)
    rpmte Te
    PREINIT:
    I32 gimme = GIMME_V;
    PPCODE:
    if (gimme == G_SCALAR) {
        mXPUSHs(newSVpvf("%s-%s-%s.%s",
            rpmteN(Te), rpmteV(Te), rpmteR(Te), rpmteA(Te)));
    } else {
        mXPUSHs(newSVpv(rpmteN(Te), 0));
        mXPUSHs(newSVpv(rpmteV(Te), 0));
        mXPUSHs(newSVpv(rpmteR(Te), 0));
        mXPUSHs(newSVpv(rpmteA(Te), 0));
    }

void
Te_size(Te)
    rpmte Te
    PPCODE:
    mXPUSHs(newSVuv(rpmtePkgFileSize(Te)));

void
Te_dep(Te, type)
    rpmte Te
    SV * type
    PREINIT:
    rpmds ds;
    rpmTag tag;
    PPCODE:
    tag = sv2deptag(type);
    ds = rpmteDS(Te, tag);
    if (ds != NULL)
        if (rpmdsNext(ds) >= 0) {
            mXPUSHs(sv_setref_pv(newSVpvs(""), bless_rpmds, ds));
#ifdef HDRPMMEM
            PRINTF_NEW(bless_rpmds, ds, ds->nrefs);
#endif
        }

void
Te_files(Te)
    rpmte Te
    PREINIT:
    rpmfi Files;
    PPCODE:
    Files = rpmteFI(Te);
    if ((Files = rpmfiInit(Files, 0)) != NULL && rpmfiNext(Files) >= 0) {
        mXPUSHs(sv_setref_pv(newSVpvs(""), bless_rpmfi, Files));
#ifdef HDRPMMEM
        PRINTF_NEW(bless_rpmfi, Files, Files->nrefs);
#endif
    }
    
MODULE = RPM4     PACKAGE = RPM4

# Return a new Dep object
void
newdep(sv_depTag, Name,  sv_sense = NULL, sv_evr = NULL)
    SV * sv_depTag
    char * Name
    SV * sv_evr
    SV * sv_sense
    PPCODE:
    PUTBACK;
    _newdep(sv_depTag, Name,  sv_sense, sv_evr);
    SPAGAIN;

void
rpmlibdep()
    PREINIT:
    rpmds Dep = NULL;
    PPCODE:
#if 0
    rpmds next;
    const char ** provNames;
    int * provFlags;
    const char ** provVersions;
    int num = 0;
    int i;
    num = rpmGetRpmlibProvides(&provNames, &provFlags, &provVersions);
    for (i = 0; i < num; i++) {
#ifdef HDLISTDEBUG
        fprintf(stderr, "HDEBUG: rpmlibdep %s %s %d\n", provNames[i], provVersions[i], provFlags[i]);
#endif
        next = rpmdsSingle(RPMTAG_PROVIDENAME, provNames[i], provVersions[i], provFlags[i]);
        rpmdsMerge(&Dep, next);
        next = rpmdsFree(next);
    }
    if (Dep != NULL) {
        Dep = rpmdsInit(Dep);
        if (rpmdsNext(Dep) >= 0) {
            mXPUSHs(sv_setref_pv(newSVpvs(""), bless_rpmds, Dep));
#ifdef HDRPMMEM
            PRINTF_NEW(bless_rpmds, Dep, Dep->nrefs);
#endif
        }
    }
#else
    if (!rpmdsRpmlib(&Dep, NULL))
        mXPUSHs(sv_setref_pv(newSVpvs(""), bless_rpmds, Dep));
#endif

MODULE = RPM4 	PACKAGE = RPM4::Header::Dependencies  PREFIX = Dep_

void
Dep_newsingle(perlclass, sv_tag, name, sv_sense = NULL, sv_evr = NULL)
    char * perlclass
    SV * sv_tag
    char * name
    SV * sv_sense
    SV * sv_evr
    PPCODE:
    PUTBACK;
    _newdep(sv_tag, name, sv_sense, sv_evr);
    SPAGAIN;

void
Dep_DESTROY(Dep)
    rpmds Dep
    CODE:
#ifdef HDRPMMEM
    PRINTF_FREE(bless_rpmds, Dep, Dep->nrefs);
#endif
    Dep = rpmdsFree(Dep);

int 
Dep_count(Dep)
    rpmds Dep
    CODE:
    RETVAL = rpmdsCount(Dep);
    OUTPUT:
    RETVAL

int
Dep_move(Dep, index = 0)
    rpmds Dep
    int index
    CODE:
    if (index == -1) /* -1 do nothing and give actual index */
        RETVAL = rpmdsIx(Dep);
    else
        RETVAL = rpmdsSetIx(Dep, index);
    OUTPUT:
    RETVAL

void
Dep_init(Dep)
    rpmds Dep
    CODE:
#ifdef HDLISTDEBUG
    PRINTF_CALL;
#endif
    rpmdsInit(Dep);
        
int
Dep_next(Dep)
    rpmds Dep
    CODE:
#ifdef HDLISTDEBUG
    PRINTF_CALL;
#endif
	RETVAL = rpmdsNext(Dep);
    OUTPUT:
    RETVAL

int
Dep_hasnext(Dep)
    rpmds Dep
    CODE:
    RETVAL = rpmdsNext(Dep) > -1;
    OUTPUT:
    RETVAL
        
int
Dep_color(Dep)
    rpmds Dep
    CODE:
    RETVAL = rpmdsColor(Dep);
    OUTPUT:
    RETVAL
        
int
Dep_find(Dep, depb)
    rpmds Dep
    rpmds depb
    CODE:
    RETVAL = rpmdsFind(Dep, depb);
    OUTPUT:
    RETVAL

int
Dep_merge(Dep, depb)
    rpmds Dep
    rpmds depb
    CODE:
    RETVAL = rpmdsMerge(&Dep, depb);
    OUTPUT:
    RETVAL
        
int
Dep_overlap(Dep1, Dep2)
    rpmds Dep1
    rpmds Dep2
    CODE:
    CHECK_RPMDS_IX(Dep1);
    CHECK_RPMDS_IX(Dep2);
    RETVAL = rpmdsCompare(Dep1, Dep2);
    OUTPUT:
    RETVAL

void
Dep_info(Dep)
    rpmds Dep
    PREINIT:
    rpmsenseFlags flag;
    I32 gimme = GIMME_V;
    PPCODE:
#ifdef HDLISTDEBUG
    PRINTF_CALL;
#endif
    CHECK_RPMDS_IX(Dep);
    if (gimme == G_SCALAR) {
        mXPUSHs(newSVpv(rpmdsDNEVR(Dep), 0));
    } else {
        switch (rpmdsTagN(Dep)) {
            case RPMTAG_PROVIDENAME:
                mXPUSHs(newSVpv("P", 0));
            break;
            case RPMTAG_REQUIRENAME:
                mXPUSHs(newSVpv("R", 0));
            break;
            case RPMTAG_CONFLICTNAME:
                mXPUSHs(newSVpv("C", 0));
            break;
            case RPMTAG_OBSOLETENAME:
                mXPUSHs(newSVpv("O", 0));
            break;
            case RPMTAG_TRIGGERNAME:
                mXPUSHs(newSVpv("T", 0));
            break;
            default:
            break;
        }
        mXPUSHs(newSVpv(rpmdsN(Dep), 0));
        flag = rpmdsFlags(Dep);
        mXPUSHs(newSVpvf("%s%s%s",
                        flag & RPMSENSE_LESS ? "<" : "",
                        flag & RPMSENSE_GREATER ? ">" : "",
                        flag & RPMSENSE_EQUAL ? "=" : ""));
        mXPUSHs(newSVpv(rpmdsEVR(Dep), 0));
    }

void
Dep_tag(Dep)
    rpmds Dep
    PPCODE:
    mXPUSHs(newSViv(rpmdsTagN(Dep)));
    
void
Dep_name(Dep)
    rpmds Dep
    PPCODE:
#ifdef HDLISTDEBUG
    PRINTF_CALL;
#endif
    CHECK_RPMDS_IX(Dep);
    mXPUSHs(newSVpv(rpmdsN(Dep), 0));

void
Dep_flags(Dep)
    rpmds Dep
    PPCODE:
    CHECK_RPMDS_IX(Dep);
    mXPUSHs(newSViv(rpmdsFlags(Dep)));

void
Dep_evr(Dep)
    rpmds Dep
    PPCODE:
    CHECK_RPMDS_IX(Dep);
    mXPUSHs(newSVpv(rpmdsEVR(Dep), 0));

int
Dep_nopromote(Dep, sv_nopromote = NULL)
    rpmds Dep
    SV * sv_nopromote
    CODE:
    if (sv_nopromote == NULL) {
        RETVAL = rpmdsNoPromote(Dep);
    } else {
        RETVAL = rpmdsSetNoPromote(Dep, SvIV(sv_nopromote));
    }
    OUTPUT:
    RETVAL
    
    
int
Dep_add(Dep, name,  sv_sense = NULL, sv_evr = NULL)
    rpmds Dep
    char * name
    SV * sv_evr
    SV * sv_sense
    PREINIT:
    rpmsenseFlags sense = RPMSENSE_ANY;
    rpmds Deptoadd;
    char * evr = NULL;
    CODE:
    RETVAL = 0;
    if (sv_sense && SvOK(sv_sense))
        sense = sv2sens(sv_sense);
    if (sv_evr && SvOK(sv_evr))
        evr = SvPV_nolen(sv_evr);
    Deptoadd = rpmdsSingle(rpmdsTagN(Dep), name, evr ? evr : "", sense);
    if (Deptoadd) {
        rpmdsMerge(&Dep, Deptoadd);
        Deptoadd = rpmdsFree(Deptoadd);
        RETVAL = 1;
    }
    OUTPUT:
    RETVAL
        
int
Dep_matchheader(Dep, header, sv_nopromote = NULL)
    Header header
    SV * sv_nopromote
    rpmds Dep
    PREINIT:
    int nopromote = 0;
    CODE:
    if (sv_nopromote != NULL)
        nopromote = SvIV(sv_nopromote);    
    RETVAL = _header_vs_dep(header, Dep, nopromote);
    OUTPUT:
    RETVAL

int
Dep_matchheadername(Dep, header, sv_nopromote = NULL)
    rpmds Dep
    Header header
    SV * sv_nopromote
    PREINIT:
    int nopromote = 0;
    CODE:
    if (sv_nopromote != NULL)
        nopromote = SvIV(sv_nopromote);
    RETVAL = _headername_vs_dep(header, Dep, nopromote);
    OUTPUT:
    RETVAL
        
MODULE = RPM4 	PACKAGE = RPM4::Header::Files  PREFIX = Files_

void
Files_DESTROY(Files)
    rpmfi Files
    PPCODE:
#ifdef HDRPMMEM
    PRINTF_FREE(bless_rpmfi, Files, Files->nrefs);
#endif
    Files = rpmfiFree(Files);

int
Files_compare(Files, Fb)
    rpmfi Files
    rpmfi Fb
    CODE:
    RETVAL = rpmfiCompare(Files, Fb);
    OUTPUT:
    RETVAL

int
Files_move(Files, index = 0)
    rpmfi Files;
    int index
    PREINIT:
    int i;
    CODE:
    index ++; /* keeping same behaviour than Header::Dep */
    rpmfiInit(Files, 0);
    RETVAL = 0;
    for (i=-1; i < index && (RETVAL = rpmfiNext(Files)) >= 0; i++) {}
    if (RETVAL == -1) {
        rpmfiInit(Files, 0);
        rpmfiNext(Files);
    }
    OUTPUT:
    RETVAL

int
Files_count(Files)
    rpmfi Files
    CODE:
    RETVAL = rpmfiFC(Files);
    OUTPUT:
    RETVAL

int
Files_countdir(Files)
    rpmfi Files
    CODE:
    RETVAL = rpmfiDC(Files);
    OUTPUT:
    RETVAL

void
Files_init(Files)
    rpmfi Files
    CODE:
#ifdef HDLISTDEBUG
    PRINTF_CALL;
#endif
    rpmfiInit(Files, 0);
        
void
Files_initdir(Files)
    rpmfi Files
    CODE:
#ifdef HDLISTDEBUG
    PRINTF_CALL;
#endif
    rpmfiInitD(Files, 0);

int
Files_next(Files)
    rpmfi Files
    CODE:
#ifdef HDLISTDEBUG
    PRINTF_CALL;
#endif
    RETVAL = rpmfiNext(Files);
    OUTPUT:
    RETVAL

int
Files_hasnext(Files)
    rpmfi Files
    CODE:
    RETVAL = rpmfiNext(Files) > -1;
    OUTPUT:
    RETVAL
        
int
Files_nextdir(Files)
    rpmfi Files
    CODE:
#ifdef HDLISTDEBUG
    PRINTF_CALL;
#endif
    RETVAL = rpmfiNextD(Files);
    OUTPUT:
    RETVAL

void
Files_filename(Files)
    rpmfi Files
    PPCODE:
#ifdef HDLISTDEBUG
    PRINTF_CALL;
    fprintf(stderr, "File %s", rpmfiFN(Files));
#endif
    mXPUSHs(newSVpv(rpmfiFN(Files), 0));

void
Files_dirname(Files)
    rpmfi Files
    PPCODE:
    mXPUSHs(newSVpv(rpmfiDN(Files), 0));

void
Files_basename(Files)
    rpmfi Files
    PPCODE:
    mXPUSHs(newSVpv(rpmfiBN(Files), 0));

void
Files_fflags(Files)
    rpmfi Files
    PPCODE:
    mXPUSHs(newSViv(rpmfiFFlags(Files)));

void
Files_mode(Files)
    rpmfi Files
    PPCODE:
    mXPUSHs(newSVuv(rpmfiFMode(Files)));

void
Files_md5(Files)
    rpmfi Files
    PREINIT:
    const char * md5;
    PPCODE:
    if ((md5 = 
        rpmfiFDigestHex(Files, NULL)
            ) != NULL && *md5 != 0 /* return undef if empty */) {
        mXPUSHs(newSVpv(md5, 0));
    }

void
Files_link(Files)
    rpmfi Files
    PREINIT:
    const char * link;
    PPCODE:
    if ((link = rpmfiFLink(Files)) != NULL && *link != 0 /* return undef if empty */) {
        mXPUSHs(newSVpv(link, 0));
    }

void
Files_user(Files)
    rpmfi Files
    PPCODE:
    mXPUSHs(newSVpv(rpmfiFUser(Files), 0));

void
Files_group(Files)
    rpmfi Files
    PPCODE:
    mXPUSHs(newSVpv(rpmfiFGroup(Files), 0));

void
Files_inode(Files)
    rpmfi Files
    PPCODE:
    mXPUSHs(newSViv(rpmfiFInode(Files)));
    
void
Files_size(Files)
    rpmfi Files
    PPCODE:
    mXPUSHs(newSViv(rpmfiFSize(Files)));

void
Files_dev(Files)
    rpmfi Files
    PPCODE:
    mXPUSHs(newSViv(rpmfiFRdev(Files)));

void
Files_color(Files)
    rpmfi Files
    PPCODE:
    mXPUSHs(newSViv(rpmfiFColor(Files)));

void
Files_class(Files)
    rpmfi Files
    PREINIT:
    const char * class;
    PPCODE:
    if ((class = rpmfiFClass(Files)) != NULL)
        mXPUSHs(newSVpv(rpmfiFClass(Files), 0));

void
Files_mtime(Files)
    rpmfi Files
    PPCODE:
    mXPUSHs(newSViv(rpmfiFMtime(Files)));

void
Files_nlink(Files)
    rpmfi Files
    PPCODE:
    mXPUSHs(newSViv(rpmfiFNlink(Files)));

MODULE = RPM4     PACKAGE = RPM4

void
newspec(filename = NULL, anyarch = NULL, force = NULL)
    char * filename 
    SV * anyarch
    SV * force
    PREINIT:
    rpmts ts = rpmtsCreate();
    PPCODE:
    PUTBACK;
    _newspec(ts, filename, anyarch, force);
    ts = rpmtsFree(ts);
    SPAGAIN;

MODULE = RPM4 	PACKAGE = RPM4::Spec  PREFIX = Spec_

void
Spec_new(perlclass, specfile = NULL, ...)
    char * perlclass
    char * specfile
    PREINIT:
    rpmts ts = NULL;
    SV * anyarch = 0;
    SV * force = 0;
    int i;
    PPCODE:
    for(i=2; i < items; i++) {
        if(strcmp(SvPV_nolen(ST(i)), "transaction") == 0) {
            i++;
            if (sv_isobject(ST(i)) && (SvTYPE(SvRV(ST(i))) == SVt_PVMG)) {
                ts = (rpmts)SvIV((SV*)SvRV(ST(i)));
                ts = rpmtsLink(ts);  
            } else {
                croak( "transaction is not a blessed SV reference" );
                XSRETURN_UNDEF;
            } 
        } else if (strcmp(SvPV_nolen(ST(i)), "force") == 0) {
            i++;
            force = ST(i);
        } else if (strcmp(SvPV_nolen(ST(i)), "anyarch") == 0) {
            i++;
            anyarch = ST(i);
        } else {
            warn("Unknown value in " bless_spec "->new, ignored");
            i++;
        }
    }
    if (!ts)
        ts = rpmtsCreate();
    PUTBACK;
    _newspec(ts, specfile, anyarch, force);
    SPAGAIN;
    ts = rpmtsFree(ts);
    
void
Spec_DESTROY(spec)
    rpmSpec spec
    CODE:
#ifdef HDRPMMEM
    PRINTF_FREE(bless_spec, spec, -1);
#endif
    rpmSpecFree(spec);

void
Spec_srcheader(spec)
    rpmSpec spec
    PPCODE:
    Header header = rpmSpecSourceHeader(spec);
    mXPUSHs(sv_setref_pv(newSVpvs(""), bless_header, (void *)headerLink(header)));

void
Spec_binheader(spec)
    rpmSpec spec
    PREINIT:
    Package pkg;
    PPCODE:
    rpmSpecPkgIter iter = rpmSpecPkgIterInit(spec);
    while ((pkg = rpmSpecPkgIterNext(iter)) != NULL)
        mXPUSHs(sv_setref_pv(newSVpvs(""), bless_header, (void *)headerLink(rpmSpecPkgHeader(pkg))));
 
void
Spec_srcrpm(spec)
    rpmSpec spec
    PREINIT:
    Header header = NULL;
    PPCODE:
    header = rpmSpecSourceHeader(spec);
    struct rpmtd_s td;
    int no_src = headerGet(header, RPMTAG_NOSOURCE, &td, HEADERGET_MINMEM);
    char *nvr = headerGetAsString(header, RPMTAG_NVR);
    mXPUSHs(newSVpvf("%s/%s.%ssrc.rpm",
        rpmGetPath("%{_srcrpmdir}", NULL),
        nvr, no_src ? "no" : ""));

void
Spec_binrpm(spec)
    rpmSpec spec
    PREINIT:
    Package pkg;
    char * binFormat;
    char * binRpm;
    char * path;
    Header header;
    PPCODE:
    rpmSpecPkgIter iter = rpmSpecPkgIterInit(spec);
    while ((pkg = rpmSpecPkgIterNext(iter)) != NULL) {
        /* headerCopyTags(h, pkg->header, copyTags); */
        binFormat = rpmGetPath("%{_rpmfilename}", NULL);
        header = rpmSpecSourceHeader(spec);
        binRpm = headerFormat(header, binFormat, NULL);
        free(binFormat);
        path = rpmGetPath("%{_rpmdir}/", binRpm, NULL);
        mXPUSHs(newSVpv(path, 0));
        free(path);
        free(binRpm);
    }

void
Spec_check(spec, ts = NULL)
    rpmSpec spec
    PREINIT:
    rpmts ts = rpmtsCreate();
    rpmps ps;
    PPCODE:
    PUTBACK;
    if (ts)
        ts = rpmtsLink(ts);
    else
        ts = rpmtsCreate();
    Header header = rpmSpecSourceHeader(spec);
    if (!headerIsEntry(header, RPMTAG_REQUIRENAME)
     && !headerIsEntry(header, RPMTAG_CONFLICTNAME))
        /* XSRETURN_UNDEF; */
        return;

    (void) rpmtsAddInstallElement(ts, header, NULL, 0, NULL);

    if(rpmtsCheck(ts))
        croak("Can't check rpmts"); /* any better idea ? */

    ps = rpmtsProblems(ts);
    if (ps && rpmpsNumProblems(ps)) /* if no problem, return undef */
        mXPUSHs(sv_setref_pv(newSVpvs(""), bless_rpmps, ps));
    ts = rpmtsFree(ts);
    SPAGAIN;
    
    
int
Spec_build(spec, sv_buildflags)
    rpmSpec spec
    SV * sv_buildflags
    PREINIT:
    rpmts ts = rpmtsCreate();
    CODE:
    RETVAL = _specbuild(ts, spec, sv_buildflags);
    ts = rpmtsFree(ts);
    OUTPUT:
    RETVAL

void
Spec_sources(spec, is = 0)
    rpmSpec spec
    int is
    PREINIT:
    rpmSpecSrc srcPtr;
    PPCODE:
    rpmSpecSrcIter iter = rpmSpecSrcIterInit(spec);
    while ((srcPtr = rpmSpecSrcIterNext(iter)) != NULL) {
        if (is && !(rpmSpecSrcFlags(srcPtr) & is))
            continue;
        mXPUSHs(newSVpv(rpmSpecSrcFilename(srcPtr, 0), 0));
    }

void
Spec_sources_url(spec, is = 0)
    rpmSpec spec
    int is
    PREINIT:
    rpmSpecSrc srcPtr;
    PPCODE:
    rpmSpecSrcIter iter = rpmSpecSrcIterInit(spec);
    while ((srcPtr = rpmSpecSrcIterNext(iter)) != NULL) {
        if (is && !(rpmSpecSrcFlags(srcPtr) & is))
            continue;
        mXPUSHs(newSVpv(rpmSpecSrcFilename(srcPtr, 1), 0));
    }

MODULE = RPM4		PACKAGE = RPM4::Db::_Problems	PREFIX = ps_

void
ps_new(perlclass, ts)
    char * perlclass    
    rpmts ts
    PREINIT:
    rpmps ps;
    PPCODE:
    ps = rpmtsProblems(ts);
    if (ps && rpmpsNumProblems(ps)) /* if no problem, return undef */
        mXPUSHs(sv_setref_pv(newSVpvs(""), bless_rpmps, ps));
 
void
ps_DESTROY(ps)
    rpmps ps
    PPCODE:
    ps = rpmpsFree(ps);

int
ps_count(ps)
    rpmps ps
    CODE:
    RETVAL = rpmpsNumProblems(ps);
    OUTPUT:
    RETVAL

void
ps_print(ps, fp)
    rpmps ps    
    FILE *fp
    PPCODE:
    rpmpsPrint(fp, ps);

int
ps_isignore(ps, numpb)
    rpmps ps
    int numpb
    PREINIT:
    CODE:
    RETVAL = 0; /* ignoreProblem is obsolete and always false */
    OUTPUT:
    RETVAL

const char *
ps_fmtpb(ps, numpb)
    rpmps ps
    int numpb
    PREINIT:
    rpmProblem p;
    int i;
    CODE:
    rpmpsi psi = rpmpsInitIterator(ps);
    for (i = 0; i <= numpb; i++)
      if (rpmpsNextIterator(psi) < 0) break;

    p = rpmpsGetProblem(psi);
    if (p)
        RETVAL = rpmProblemString(p);
    else {
        RETVAL = NULL;
    }
    OUTPUT:
    RETVAL

