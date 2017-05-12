#define INCL_DOSERRORS
#define INCL_WINERRORS

/* To include PMERR_* we use... */
#define  SOM2VERSION
#include "os2.h"

#include <somcls.h>
#include <somobj.h>
#include <somd.h>
#include <wpclsmgr.h>

/* In SOM 'any' is struct */
#define any Perlish_any

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "common_init.h"

/* We use xsubpp from 5.005_64, and it puts some unexpected macros */
#ifdef CUSTOM_XSUBPP
#  define aTHX_
#endif

#undef any

/* Why needed??? */
#define SOMClassManager WPClassManager
#define ClassManager WPClassManager

static int rc;

#define pSOMClassMgrObject()	(SOMClassMgrObject)
#define pSOMD_ObjectMgr()	(SOMD_ObjectMgr)

#define Env_DESTROY(ev)		SOM_DestroyLocalEnvironment(ev)
#define Env_major(ev)		((ev)->_major)

#define pSYSTEM_EXCEPTION()	SYSTEM_EXCEPTION
#define pUSER_EXCEPTION()	USER_EXCEPTION
#define pNO_EXCEPTION()		NO_EXCEPTION
#define pPMERR_WPDSERVER_IS_ACTIVE()	PMERR_WPDSERVER_IS_ACTIVE
#define pPMERR_SOMDD_IS_ACTIVE()	PMERR_SOMDD_IS_ACTIVE
#define pPMERR_WPDSERVER_NOT_STARTED()	PMERR_WPDSERVER_NOT_STARTED
#define pPMERR_SOMDD_NOT_STARTED()	PMERR_SOMDD_NOT_STARTED

#define ccWinRestartSOMDD(start)	(!CheckOSError(WinRestartSOMDD(start)))
#define ccWinRestartWPDServer(start) (!CheckOSError(WinRestartWPDServer(start)))

static bool
cWinRestartSOMDD(start)
    bool start;
{
   perl_hmq_GET(0);
   start = ccWinRestartSOMDD(start);
/*   perl_hmq_UNSET(0);	*/
   return start;
}

static bool
cWinRestartWPDServer(start)
    bool start;
{
   perl_hmq_GET(0);
   start = ccWinRestartWPDServer(start);
/*   perl_hmq_UNSET(0);	*/
   return start;
}

static char *
Env_id(Environment *ev)
{
    if (ev->_major == SYSTEM_EXCEPTION)
	return somExceptionId(ev);
    if (ev->_major == USER_EXCEPTION)
	return "USER EXCEPTION";
    return "NO EXCEPTION";
}

static void
Env_Clear(Environment *ev)
{
    if (ev->_major == SYSTEM_EXCEPTION)
	somExceptionFree(ev);
}

static int
Env_minor(Environment *ev)
{
    StExcep *params;

    if (ev->_major != SYSTEM_EXCEPTION)
	return 0;
    params = somExceptionValue(ev);
    return params->minor;
}

static SV *
Env_completed(Environment *ev)
{
    StExcep *params;

    if (ev->_major != SYSTEM_EXCEPTION)
	return &sv_undef;
    params = somExceptionValue(ev);
    return (params->completed == YES 
	    ? &sv_yes : (params->completed == NO 
			  ? &sv_no : &sv_undef));
}

static void
Init_WP_Classes()
{
  WPObjectNewClass( 1, 1 );
  WPTransientNewClass( 1, 1 );
  WPAbstractNewClass( 1, 1 );
  WPFileSystemNewClass( 1, 1 );
  WPDataFileNewClass( 1, 1 );
  WPFolderNewClass( 1, 1 );
  WPMetNewClass( 1, 1 );
  WPDesktopNewClass( 1, 1 );
}

MODULE = DSOM		PACKAGE = SOM	PREFIX = PSOM_

PROTOTYPES: ENABLE

void
Init_WP_Classes()

MODULE = DSOM		PACKAGE = SOM		PREFIX = Win

bool
WinIsSOMDDReady()

bool
WinIsWPDServerReady()

MODULE = DSOM		PACKAGE = SOM		PREFIX = cWin

bool
cWinRestartSOMDD(start)
    bool start

bool
cWinRestartWPDServer(start)
    bool start

MODULE = DSOM		PACKAGE = SOM		PREFIX = SOM_

Environment *
SOM_CreateLocalEnvironment()

void
SOM_DestroyLocalEnvironment(ev)
    Environment *ev

MODULE = DSOM		PACKAGE = EnvironmentPtr	PREFIX = Env_

void
Env_DESTROY(ev)
    Environment *ev;

int
Env_major(ev)
    Environment *ev;

void
Env_Clear(ev)
    Environment *ev;

char *
Env_id(ev)
    Environment *ev

int
Env_minor(ev)
    Environment *ev

SV *
Env_completed(ev)
    Environment *ev

MODULE = DSOM		PACKAGE = SOM	PREFIX = p

int
pSYSTEM_EXCEPTION()

int
pUSER_EXCEPTION()

int
pNO_EXCEPTION()

IV
pPMERR_WPDSERVER_IS_ACTIVE()

IV
pPMERR_SOMDD_IS_ACTIVE()

IV
pPMERR_WPDSERVER_NOT_STARTED()

IV
pPMERR_SOMDD_NOT_STARTED()

MODULE = DSOM		PACKAGE = SOM::SOMDeamon	PREFIX = SOMD_

void
SOMD_Init(ev)
    Environment *ev

void
SOMD_Uninit(ev)
    Environment *ev

SOMClassManager *
WPClassManagerNew()

MODULE = DSOM		PACKAGE = SOM::SOMDeamon	PREFIX = pSOMD_

SOMDObjectMgr *
pSOMD_ObjectMgr()

MODULE = DSOM		PACKAGE = SOM::SOMDeamon	PREFIX = pSOM

SOMClassManager *
pSOMClassMgrObject()

MODULE = DSOM		PACKAGE = SOMClassManagerPtr	PREFIX = _som

void
_somMergeInto(receiver, target)
    SOMClassManager *receiver;
    SOMClassManager *target;

MODULE = DSOM		PACKAGE = SOMDObjectMgrPtr	PREFIX = _somd

SOMDServer   *
_somdFindServerByName(manager, ev, name)
    SOMDObjectMgr *manager;
    Environment *ev;
    char *name;

MODULE = DSOM		PACKAGE = SOMDServerPtr		PREFIX = _somd

SOMClass *
_somdGetClassObj(Server, ev, name)
    SOMDServer   *Server;
    Environment *ev;
    char *name

MODULE = DSOM		PACKAGE = ObjectMgrPtr		PREFIX = _somd

void
_somdReleaseObject(manager, ev, obj)
    ObjectMgr *manager;
    Environment *ev;
    SOMObject *obj;

