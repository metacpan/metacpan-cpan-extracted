/* Redefine some Perl defines to prevent a clash with the Notes defines
 *
 */
#define BLOCK Perl_BLOCK

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef  WORD
#define Perl_WORD WORD
#undef  WORD
#endif

#ifdef  LOCAL
#define Perl_LOCAL LOCAL
#undef  LOCAL
#endif

#undef BLOCK

#ifndef EXIT_SUCCESS
   #define EXIT_SUCCESS 0
#endif

#ifndef EXIT_FAILURE
   #define EXIT_FAILURE 1
#endif

////////////////////////////////////////////////////////////////////////

/* Lotus Notes Perl Objects typedefs */

typedef SV LN_Object;
typedef SV LN_Session;
typedef SV LN_Database;
typedef SV LN_View;
typedef SV LN_Replication;
typedef SV LN_Document;

typedef HV LN_Name;
typedef HV LN_ViewColumn;

/* Lotus Notes include files */

#include <global.h>
#include <dname.h>
#include <kfm.h>
#include <lookup.h>
#include <lapiplat.h>
#include <osmisc.h>
#include <osfile.h>
#include <osmem.h>
#include <osenv.h>
#include <nsfdb.h>
#include <nsfdata.h>
#include <nsfnote.h>
#include <acl.h>
#include <mail.h>
#include <misc.h>
#include <nsfsearc.h>

/* Lotus Notes Perl Database Object Structures
 *
 * Member names should be respected because several macros
 * rely on standard names across all structs
 */

typedef struct {
	DBHANDLE        ln_db_handle;   /* Handle to a Notes Database */
} NOTESDATABASE;

typedef struct {
	DBHANDLE        ln_db_handle;   /* Handle to a Notes Database */
	DBREPLICAINFO * ln_repl_info;   /* Pointer to the Database REPLICAINFO struct */
} NOTESREPLICATION;

typedef struct {
	DBHANDLE        ln_db_handle;   /* Handle to a Notes Database */
	HCOLLECTION     ln_view_coll;   /* View Collection Handle */
	NOTEID          ln_note_id;     /* Note ID of the View Design Note */
	DWORD           ln_note_ptr;    /* Pointer to current position in view */
} NOTESVIEW;

typedef struct {
	NOTEHANDLE      ln_note_handle; /* Handle to the Notes Document */
	NOTEID          ln_note_id;     /* Note ID of the Document Note */
} NOTESDOCUMENT;

//////////////////////////////////////////////////////////////////////

/* Utility macros definition */

#ifdef DEBUGXS
   #define DEBUG(x)  warn x
#else
   #define DEBUG(x)
#endif

/* The XSRETURN* defines need the standard XS-includes */

#define XSRETURN_OK XSRETURN_YES

#define XSRETURN_NOT_OK 									\
        if        ( GIMME_V == G_SCALAR ) { XSRETURN_UNDEF; \
        } else if ( GIMME_V == G_ARRAY  ) { XSRETURN_EMPTY; \
        } else if ( GIMME_V == G_VOID   ) { XSRETURN(0);    \
        } else                            { XSRETURN(0);  }

/* Notes C API includes for NOERROR and ERR_SERVER_ERR_MSG */

#include <globerr.h>
#include <miscerr.h>

/* Lotus API No error */

#define LN_OK		NOERROR

/* There is no "general all-purpose" error code in the Lotus API -
 * so I picked one that made sense
 */

#define LN_NOT_OK	ERR_SERVER_ERR_MSG

/* Variable declarations as needed for the macros below
 *
 * ln_obj:    Denotes the Perl object(blessed ref = ref to SvPVMG)
 *            for an object of our Perl Lotus Notes Interface
 *
 */

/* Used to define interface variables */

#define d_LN_XSVARS                     \
				 void * ln_data = NULL; \
                 SV   *	ln_obj  = NULL

/* Used to access an object (SvPVMG) and it's related IVX, NVX and PVX slots */

//#define LN_OBJ(ln_obj)			ln_obj

#define LN_IVX(ln_obj)			SvIVX(SvRV((SV*) ln_obj))

#define LN_SET_IVX(ln_obj, ivx) SvREADONLY_off(SvRV((SV*)ln_obj)); 	\
                                sv_setiv(SvRV((SV*) ln_obj), ivx); 	\
                                SvREADONLY_on(SvRV((SV*)ln_obj))

#define LN_NVX(ln_obj)		  	(long)SvNVX(SvRV((SV*) ln_obj))

#define LN_SET_NVX(ln_obj, nvx) SvREADONLY_off(SvRV((SV*)ln_obj)); 	\
								sv_setnv(SvRV((SV*) ln_obj), nvx);	\
								SvREADONLY_on(SvRV((SV*)ln_obj))

//#define LN_PVX_SLOT(ln_obj)		SvPVX(SvRV((SV*) ln_obj))
//#define LN_SET_PVX(ln_obj, val) LN_PVX_SLOT(ln_obj) = (char *)INT2PTR(char *, val)
//#define LN_PVX(ln_obj)          (long)PTR2IV(LN_PVX_SLOT( ln_obj ))

/* Used to access an object's parent */
//#define LN_PARENT_OBJ(ln_obj)           SvRV(SvRV((SV*) ln_obj))
//#define LN_PARENT_IVX(ln_obj)           LN_IVX(LN_PARENT_OBJ( ln_obj ))
//#define LN_PARENT_NVX(ln_obj)           LN_NVX(LN_PARENT_OBJ( ln_obj ))
//#define LN_PARENT_PVX(ln_obj)          LN_PVX(LN_PARENT_OBJ( ln_obj ))
//#define LN_SET_PARENT_IVX(ln_obj, ivx)  LN_SET_IVX(LN_PARENT_OBJ( ln_obj ), ivx)
//#define LN_SET_PARENT_NVX(ln_obj, nvx)  LN_SET_NVX(LN_PARENT_OBJ( ln_obj ), nvx)
//#define LN_SET_PARENT_PVX(ln_obj, pvx) LN_SET_PVX(LN_PARENT_OBJ( ln_obj ), pvx)

#define LN_INIT_OBJ_STRUCT(type,ln_obj) \
		Newz(1, ln_data, 1, type); \
		DEBUG(("INIT: ln_data is: %ld\n", (long)ln_data)); \
        LN_SET_NVX(ln_obj, (long)ln_data);

#define LN_FREE_OBJ_STRUCT(type,ln_obj) \
        DEBUG(("FREE: ln_data is: %ld\n", LN_NVX(ln_obj))); \
        Safefree(INT2PTR(type *, LN_NVX(ln_obj)))

#define LN_DB_HANDLE(type,ln_obj)            (DBHANDLE)(INT2PTR(type *, LN_NVX(ln_obj)))->ln_db_handle
#define LN_SET_DB_HANDLE(type,ln_obj,val)    LN_DB_HANDLE(type,ln_obj) = (DBHANDLE)val

#define LN_DB_REPL_INFO(type,ln_obj)         (DBREPLICAINFO *)(INT2PTR(type *, LN_NVX(ln_obj)))->ln_repl_info
#define LN_SET_DB_REPL_INFO(type,ln_obj,val) LN_DB_REPL_INFO(type,ln_obj) = (DBREPLICAINFO *)val

#define LN_HCOLLECTION(type,ln_obj)          (HCOLLECTION)(INT2PTR(type *, LN_NVX(ln_obj)))->ln_view_coll
#define LN_SET_HCOLLECTION(type,ln_obj,val)  LN_HCOLLECTION(type,ln_obj) = (HCOLLECTION)val

#define LN_NOTE_ID(type,ln_obj)              (NOTEID)(INT2PTR(type *, LN_NVX(ln_obj)))->ln_note_id
#define LN_SET_NOTE_ID(type,ln_obj,val)      LN_NOTE_ID(type,ln_obj) = (NOTEID)val

#define LN_NOTE_HANDLE(type,ln_obj)          (NOTEHANDLE)(INT2PTR(type *, LN_NVX(ln_obj)))->ln_note_handle
#define LN_SET_NOTE_HANDLE(type,ln_obj,val)  LN_NOTE_HANDLE(type,ln_obj) = (NOTEHANDLE)val

#define LN_NOTE_PTR(type,ln_obj)             (DWORD)(INT2PTR(type *, LN_NVX(ln_obj)))->ln_note_ptr
#define LN_SET_NOTE_PTR(type,ln_obj,val)     LN_NOTE_PTR(type,ln_obj) = (DWORD)val

/* Used to push a new Perl "object" on the stack and bless it.
 */
#define LN_PUSH_NEW_OBJ(CLASS, ln_parent_obj)    					\
        ln_obj = sv_2mortal(newRV_noinc(newRV_inc(ln_parent_obj))); \
        ln_obj = sv_bless(ln_obj, gv_stashpv(CLASS, TRUE)); 		\
        SvNOK_on	 (SvRV(ln_obj)); 								\
        SvNOKp_on	 (SvRV(ln_obj)); 								\
        SvIOK_on	 (SvRV(ln_obj)); 								\
        SvREADONLY_on(SvRV(ln_obj)); 								\
        XPUSHs		 (ln_obj)

/* Used to push a new Perl Hash "object" on the stack and bless it.
 */
#define LN_PUSH_NEW_HASH_OBJ(CLASS, ln_parent_obj)					\
        ln_obj = sv_2mortal(newRV_inc((SV *)ln_hash));            \
        ln_obj = sv_bless(ln_obj, gv_stashpv(CLASS, TRUE)); 		\
        SvREADONLY_on(SvRV(ln_obj)); 								\
        XPUSHs		 (ln_obj)

/* Used for easier handling of the Notes C API error/status codes */
#define LN_IS_OK(ln_obj)		(LN_IVX(ln_obj) == LN_OK)
#define LN_SET_OK(ln_obj)  	    LN_SET_IVX(ln_obj, LN_OK)

#define LN_IS_NOT_OK(ln_obj)	(LN_IVX(ln_obj) != LN_OK)
#define LN_SET_NOT_OK(ln_obj)	LN_SET_IVX(ln_obj,LN_NOT_OK)