#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <fam.h>
#include <string.h>
#include <errno.h>

static int
constant(name)
char *name;
{
    errno = 0;
    switch (*name) {
    case 'A':
	break;
    case 'B':
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	if (strEQ(name, "FAM_DEBUG_OFF"))
#ifdef FAM_DEBUG_OFF
	    return FAM_DEBUG_OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FAM_DEBUG_ON"))
#ifdef FAM_DEBUG_ON
	    return FAM_DEBUG_ON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FAM_DEBUG_VERBOSE"))
#ifdef FAM_DEBUG_VERBOSE
	    return FAM_DEBUG_VERBOSE;
#else
	    goto not_there;
#endif
	    /* enum FAMCodes--added by hand */
        if (strEQ(name, "FAMChanged")) {
          return FAMChanged;
        } else if (strEQ(name, "FAMDeleted")) {
          return FAMDeleted;
        } else if (strEQ(name, "FAMStartExecuting")) {
          return FAMStartExecuting;
        } else if (strEQ(name, "FAMStopExecuting")) {
          return FAMStopExecuting;
        } else if (strEQ(name, "FAMCreated")) {
          return FAMCreated;
        } else if (strEQ(name, "FAMMoved")) {
          return FAMMoved;
        } else if (strEQ(name, "FAMAcknowledge")) {
          return FAMAcknowledge;
        } else if (strEQ(name, "FAMExists")) {
          return FAMExists;
        } else if (strEQ(name, "FAMEndExist")) {
	  return FAMEndExist;
        }
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	break;
    case 'N':
	break;
    case 'O':
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	break;
    case 'T':
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    case '_':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static char *famerror() {
  return FAMErrno ? (char *) FamErrlist[FAMErrno] : "";
}

static void famwarn(code, what)
int code;
char *what;
{
  if (code==-1)
    warn("Sys::Gamin: %s: %s", what,
	 FAMErrno ? FamErrlist[FAMErrno] :
	 errno ? strerror(errno) :
	 "(unidentified)");
}


MODULE = Sys::Gamin		PACKAGE = Sys::Gamin

PROTOTYPES: ENABLE

int
constant(name)
	char *		name

char *
famerror()


MODULE = Sys::Gamin		PACKAGE = FAMConnectionPtr		PREFIX = FAM

PROTOTYPES: ENABLE

# int
# FAMOpen(fc)
# 	FAMConnection *	fc

int
FAMOpen2(fc, appName)
	FAMConnection *	fc
	char *	appName

int
FAMClose(fc)
	FAMConnection *	fc

# int
# FAMMonitorDirectory(fc, filename, fr, userData)
# 	FAMConnection *	fc
# 	char *	filename
# 	FAMRequest *	fr
# 	void *	userData
# 
# int
# FAMMonitorFile(fc, filename, fr, userData)
# 	FAMConnection *	fc
# 	char *	filename
# 	FAMRequest *	fr
# 	void *	userData

int
FAMMonitorCollection(fc, filename, fr, userData, depth, mask)
	FAMConnection *	fc
	char *	filename
	FAMRequest *	fr
	void *	userData
	int	depth
	char *	mask

int
FAMMonitorDirectory2(fc, filename, fr)
	FAMConnection *	fc
	char *	filename
	FAMRequest *	fr

int
FAMMonitorFile2(fc, filename, fr)
	FAMConnection *	fc
	char *	filename
	FAMRequest *	fr

int
FAMSuspendMonitor(fc, fr)
	FAMConnection *	fc
	FAMRequest *	fr

int
FAMResumeMonitor(fc, fr)
	FAMConnection *	fc
	FAMRequest *	fr

int
FAMCancelMonitor(fc, fr)
	FAMConnection *	fc
	FAMRequest *	fr

int
FAMNextEvent(fc, fe)
	FAMConnection *	fc
	FAMEvent *	fe

int
FAMPending(fc)
	FAMConnection *	fc

MODULE = Sys::Gamin		PACKAGE = FAMConnectionPtr		PREFIX = fc_

PROTOTYPES: ENABLE

void
fc_DESTROY(fc)
 FAMConnection * fc
 CODE:
# warn("Freeing FAMConnection %p\n", (void *)fc);
 famwarn(FAMClose(fc), "Closing connection");
 Safefree(fc);

FAMConnection *
fc_new(class)
 char * class
 CODE:
 New(0, RETVAL, 1, FAMConnection);
# warn("Created FAMConnection %p\n", (void *)RETVAL);
 OUTPUT:
 RETVAL

int
fc_fd(fc)
 FAMConnection * fc
 CODE:
 RETVAL=FAMCONNECTION_GETFD(fc);
 OUTPUT:
 RETVAL


MODULE = Sys::Gamin		PACKAGE = FAMRequestPtr			PREFIX = fr_

PROTOTYPES: ENABLE

void
fr_DESTROY(fr)
 FAMRequest * fr
 CODE:
# warn("Freeing FAMRequest %p\n", (void *)fr);
 Safefree(fr);

FAMRequest *
fr_new(class)
 char * class
 CODE:
 New(0, RETVAL, 1, FAMRequest);
# warn("Created FAMRequest %p\n", (void *)RETVAL);
 OUTPUT:
 RETVAL

int
fr_reqnum(fr)
 FAMRequest * fr
 CODE:
 RETVAL=FAMREQUEST_GETREQNUM(fr);
 OUTPUT:
 RETVAL

void
fr_setreqnum(fr, new)
 FAMRequest * fr
 int new
 CODE:
 FAMREQUEST_GETREQNUM(fr)=new;


MODULE = Sys::Gamin		PACKAGE = FAMEventPtr			PREFIX = fe_

PROTOTYPES: ENABLE

void
fe_DESTROY(fe)
 FAMEvent * fe
 CODE:
# warn("Freeing FAMEvent %p\n", (void *)fe);
 Safefree(fe);

FAMEvent *
fe_new(class)
 char * class
 CODE:
 New(0, RETVAL, 1, FAMEvent);
# warn("Created FAMEvent %p\n", (void *)RETVAL);
 OUTPUT:
 RETVAL

# /*
# Properly, these next two should inc. the REFCNT of ST(0), once I
# figure out how to do something like that, and return the original
# object. Until then, we do not want gratuitous freeing.
# */

FAMConnection *
fe_fc(fe)
 FAMEvent * fe
 CODE:
 New(0, RETVAL, 1, FAMConnection);
 *RETVAL=*(fe->fc);
 OUTPUT:
 RETVAL

FAMRequest *
fe_fr(fe)
 FAMEvent * fe
 CODE:
 New(0, RETVAL, 1, FAMRequest);
 *RETVAL=fe->fr;
 OUTPUT:
 RETVAL

char *
fe_hostname(fe)
 FAMEvent * fe
 CODE:
 RETVAL=fe->hostname;
 OUTPUT:
 RETVAL

char *
fe_filename(fe)
 FAMEvent * fe
 CODE:
 RETVAL=fe->filename;
 OUTPUT:
 RETVAL

FAMCodes
fe_code(fe)
 FAMEvent * fe
 CODE:
 RETVAL=fe->code;
 OUTPUT:
 RETVAL
