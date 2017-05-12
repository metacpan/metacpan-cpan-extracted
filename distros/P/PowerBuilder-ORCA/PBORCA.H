/*                                                                         */
/* *********************************************************************** */
/*                                                                         */
/*                 Copyright Powersoft Corporation 1991 - 1995             */
/*                                                                         */
/*       Powersoft Corporation ("Powersoft") claims copyright in this      */
/*     program and documentation as an unpublished work, versions of       */
/*     which were first licensed on the date indicated in the foregoing    */
/*     notice. Claim of copyright does not imply waiver of Powersoft's     */
/*     other rights. See Notice of Proprietary Rights.                     */
/*                                                                         */
/*                 NOTICE OF PROPRIETARY RIGHTS                            */
/*                                                                         */
/*       This program and documentation are confidential trade             */
/*     secrets and the property of Powersoft.  Use, examination,           */
/*     reproduction, copying, disassembly, decompilation, transfer         */
/*     and/or disclosure to others are strictly prohibited except by       */
/*     express written agreement with Powersoft.                           */
/*                                                                         */
/* ----------------------------------------------------------------------- */
/*                                                                         */
/*    Filename : pborca.h                                                  */
/*                                                                         */
/*    Purpose  : PowerBuilder Open Repository CASE API                     */
/*                DLL public header file.                                  */
/*                                                                         */
/*    Notes    : 1. This header file should be included after <windows.h>  */
/*               2. This file was editted with tab stops 4.                */
/*                                                                         */
/* *********************************************************************** */

#ifndef PB_ORCA                              /* First time defined?  */
#define PB_ORCA                              /* Yes, make sure of it */

#ifdef    __cplusplus
extern "C" {
#endif    /* __cplusplus */

#if defined(macintosh) || defined(__unix) 
#ifndef FAR
#define FAR
#endif
#define far
#ifndef _WINDEF_
typedef TCHAR FAR*       LPTSTR;
typedef unsigned int	UINT;
#endif
#ifndef _WINNT_
typedef void FAR*      	LPVOID;
#endif

#if !defined(macintosh)
#define PASCAL			pascal
#endif

#define LONG			long
#endif

#if defined(macintosh) || defined(__unix) // gmoison 
#ifndef CALLBACK
#define CALLBACK
#endif
#ifndef WINAPI
#define WINAPI
#endif 
#endif

#ifndef PBWINAPI_
#define PBWINAPI_(t) t WINAPI
#endif

#ifndef PBCALLBACK
#define PBCALLBACK(r,n) r ( CALLBACK n )
#endif

#ifndef CHAR                                 /* We have a CHAR definiton? */
#define TCHAR TCHAR                            /* No, then do it */
#endif

#ifndef VOID                                 /* We have a VOID definiton? */
#define VOID void                            /* No, then do it */
#endif

#if !defined(_WINDEF_) && !defined(_INC_WINDOWS)/* We have a INT definiton? */
// #define INT int                             /* No, then do it */
typedef int INT;
#endif

/* *********************************************************************** */
/* ORCA Interface assorted #defines                                        */
/* *********************************************************************** */

#define HPBORCA           LPVOID             /* ORCA session handle */
#define PBORCA_MSGBUFFER  256                /* Suggested msg buffer size */
#define PBORCA_MAXCOMMENT 255                /* Maximum comment size */


/* *********************************************************************** */
/* ORCA Interface result #defines                                          */
/* *********************************************************************** */
#define PBORCA_OK              0             /* Operation successful */
#define PBORCA_INVALIDPARMS   -1             /* Invalid parameter list */
#define PBORCA_DUPOPERATION   -2             /* Duplicate operation */    
#define PBORCA_OBJNOTFOUND    -3             /* Object not found */ 
#define PBORCA_BADLIBRARY     -4             /* Bad library name */
#define PBORCA_LIBLISTNOTSET  -5             /* Library list not set */
#define PBORCA_LIBNOTINLIST   -6             /* Library not in lib list */
#define PBORCA_LIBIOERROR     -7             /* Library I/O error */          
#define PBORCA_OBJEXISTS      -8             /* Object exists */          
#define PBORCA_INVALIDNAME    -9             /* Invalid name */          
#define PBORCA_BUFFERTOOSMALL -10            /* Buffer size is too small */          
#define PBORCA_COMPERROR      -11            /* Compile error */
#define PBORCA_LINKERROR      -12            /* Link error */
#define PBORCA_CURRAPPLNOTSET -13            /* Current appl not set */
#define PBORCA_OBJHASNOANCS   -14            /* Object has no ancestors */          
#define PBORCA_OBJHASNOREFS   -15            /* Object has no references */          
#define PBORCA_PBDCOUNTERROR  -16            /* Invalid # of PBD's */          
#define PBORCA_PBDCREATERROR  -17            /* PBD create error */
#define PBORCA_CHECKOUTERROR  -18            /* check out/in error */
/* *********************************************************************** */
/* ORCA Executable generation #defines for lFlags for
**	PBORCA_ExecutableCreate and PBORCA_DynamicLibraryCreate
**
** For p-code executables, value must be 0.
**
** Each option is specified by a separate bit:                             
**
**	0000 0000 0000 0000 0000 0000 0000 0000
**	^bit 31								  ^bit 0
**										  
**	bit 0:		0 = p-code, 1 = machine-code
**	bit 1:		0 = native, 1 = 16 bit
**	bit 2:		0 = no open server, 1 = open server
**	bit 3:		reserved
** 	bit 4:		0 = no trace info, 1 = trace info
**	bit 5:		0 = no runtime error context (routine & line numbers), 1 = error context
**	bits 6,7: 	reserved
**	bit 8:		0 = no optimization, 1 = optimization
**	bit 9:		0 = optimize for speed, 1 = optimize for space
**	bits 10-31:	reserved
** 
**	Example:
**		long	lFlagVariable = 0;	initialize to zero
**
**		or in desired options
**		lFlagVariable |= PBORCA_MACHINE_CODE;
**		lFlagVariable |= PBORCA_MACHINE_CODE_OPT;
**		lFlagVariable |= PBORCA_MACHINE_CODE_OPT_SPACE;
**  Will produce machine code exe optimized for space.
** *********************************************************************** */

#define PBORCA_P_CODE					0x00000000
#define PBORCA_MACHINE_CODE				0x00000001
// Native is the default (32 bit for NT/Win95)
#define PBORCA_MACHINE_CODE_NATIVE		0x00000001
#define PBORCA_MACHINE_CODE_16			0x00000002
#define PBORCA_P_CODE_16				0x00000002

// Open server is available for machine code only
#define PBORCA_OPEN_SERVER				0x00000004
#define PBORCA_TRACE_INFO				0x00000010
#define PBORCA_ERROR_CONTEXT			0x00000020
#define PBORCA_MACHINE_CODE_OPT			0x00000100
#define PBORCA_MACHINE_CODE_OPT_SPEED	0x00000100
#define PBORCA_MACHINE_CODE_OPT_SPACE	0x00000200
#define PBORCA_MACHINE_CODE_OPT_NONE	0x00000000

#define PBORCA_MACHINE_CODE_POWERMAC	0x00001000
#define PBORCA_MACHINE_CODE_68KMAC		0x00002000
#define PBORCA_MACHINE_CODE_FATMAC		0x00004000


// Common combinations

// wrl 12/3/96 -- NOCODEGEN test added to suppress C code generation on 
// platforms where that is not supported.  

#ifndef NOCODEGEN
#define PBORCA_MACHINE_DEFAULT (PBORCA_MACHINE_CODE | PBORCA_MACHINE_CODE_OPT_SPEED)
#else
#define PBORCA_MACHINE_DEFAULT (PBORCA_P_CODE)
#endif
																		
#define PBORCA_MACHINE_DEBUG (PBORCA_MACHINE_CODE | 					\
	PBORCA_TRACE_INFO | PBORCA_ERROR_CONTEXT)

#define PBORCA_MACHINE_16_DEFAULT (PBORCA_MACHINE_CODE | PBORCA_MACHINE_CODE_16	|\
	PBORCA_MACHINE_CODE_OPT_SPEED)

#define PBORCA_MACHINE_OPEN_DEFAULT (PBORCA_MACHINE_CODE | PBORCA_OPEN_SERVER |\
	PBORCA_MACHINE_CODE_OPT_SPEED)

/* *********************************************************************** */
/* ORCA entry types                                                        */
/* *********************************************************************** */

typedef enum pborca_type
{
    PBORCA_APPLICATION,     
    PBORCA_DATAWINDOW,      
    PBORCA_FUNCTION,      
    PBORCA_MENU,      
    PBORCA_QUERY,      
    PBORCA_STRUCTURE,      
    PBORCA_USEROBJECT,      
    PBORCA_WINDOW,
    PBORCA_PIPELINE,
    PBORCA_PROJECT,
    PBORCA_PROXYOBJECT,
    PBORCA_BINARY

} PBORCA_TYPE, FAR *PPBORCA_TYPE;

typedef enum pborca_reftype
{
    PBORCA_REFTYPE_SIMPLE,  
    PBORCA_REFTYPE_OPEN  

} PBORCA_REFTYPE, FAR *PPBORCA_REFTYPE;

typedef enum pborca_rebuild_type
{
    PBORCA_FULL_REBUILD,  
    PBORCA_INCREMENTAL_REBUILD,
    PBORCA_MIGRATE

} PBORCA_REBLD_TYPE, FAR *PPBORCA_REBLD_TYPE;

/* *********************************************************************** */
/* Structure for PBORCA_CompileEntryImport callback function.              */
/* *********************************************************************** */
typedef struct pborca_comperr  
{
    INT     iLevel;                         /* Error level */
    LPTSTR   lpszMessageNumber;              /* Pointer to message number */ 
    LPTSTR   lpszMessageText;                /* Pointer to message text */ 
    UINT    iColumnNumber;                  /* Column number */
    UINT	iLineNumber;                    /* Line number */

} PBORCA_COMPERR, FAR *PPBORCA_COMPERR;

/* *********************************************************************** */
/* Prototype for PBORCA_CompileEntryImport callback function.              */
/* *********************************************************************** */
typedef PBCALLBACK(void, *PBORCA_ERRPROC) ( PPBORCA_COMPERR, LPVOID );

/* *********************************************************************** */
/* Structure for PBORCA_ExecutableCreate callback function.                */
/* *********************************************************************** */
typedef struct pborca_linkerr  
{
    LPTSTR   lpszMessageText;                /* Pointer to message text */ 

} PBORCA_LINKERR, FAR *PPBORCA_LINKERR;

/* *********************************************************************** */
/* Prototype for PBORCA_ExecutableCreate callback function.                */
/* *********************************************************************** */
typedef PBCALLBACK(void, *PBORCA_LNKPROC) ( PPBORCA_LINKERR, LPVOID );


/* *********************************************************************** */
/* Structure for PBORCA_LibraryDirectory callback function.                */
/* *********************************************************************** */
typedef struct pborca_direntry 
{
					                        /* Comments */
    TCHAR            szComments[PBORCA_MAXCOMMENT + 1];

    LONG            lCreateTime;            /* Time of entry create/mod */ 
    LONG            lEntrySize;             /* Size of entry */
    LPTSTR           lpszEntryName;          /* Pointer to entry name */
    PBORCA_TYPE     otEntryType;            /* Entry type */

} PBORCA_DIRENTRY, FAR *PPBORCA_DIRENTRY;


/* *********************************************************************** */
/* Prototype for PBORCA_LibraryDirectory callback function.                */
/* *********************************************************************** */
typedef PBCALLBACK(void, *PBORCA_LISTPROC) ( PPBORCA_DIRENTRY, LPVOID );


/* *********************************************************************** */
/* Structure for PBORCA_LibraryEntryInformation callback function.         */
/* *********************************************************************** */
typedef struct pborca_entryinfo 
{
					     /* Comments */
  TCHAR           szComments[PBORCA_MAXCOMMENT + 1];

  LONG           lCreateTime;                /* Time of entry create/mod */ 
  LONG           lObjectSize;                /* Size of object */
  LONG           lSourceSize;                /* Size of source */

} PBORCA_ENTRYINFO, FAR *PPBORCA_ENTRYINFO;


/* *********************************************************************** */
/* Structure for PBORCA_ObjectQueryHierarchy callback function.            */
/* *********************************************************************** */
typedef struct pborca_hierarchy
{

  LPTSTR          lpszAncestorName;           /* Pointer to ancestor name */ 

} PBORCA_HIERARCHY, FAR *PPBORCA_HIERARCHY;

/* *********************************************************************** */
/* Prototype for PBORCA_ObjectQueryHierarchy callback function.            */
/* *********************************************************************** */
typedef PBCALLBACK(void, *PBORCA_HIERPROC) ( PPBORCA_HIERARCHY, LPVOID );


/* *********************************************************************** */
/* Structure for PBORCA_ObjectQueryReference callback function.            */
/* *********************************************************************** */
typedef struct pborca_reference
{

  LPTSTR          lpszLibraryName;            /* Pointer to library name */ 
  LPTSTR          lpszEntryName;              /* Pointer to entry name */
  PBORCA_TYPE    otEntryType;                /* Entry type */
  PBORCA_REFTYPE otEntryRefType;             /* Entry reference type */

} PBORCA_REFERENCE, FAR *PPBORCA_REFERENCE;

/* *********************************************************************** */
/* Prototype for PBORCA_ObjectQueryReference callback function.            */
/* *********************************************************************** */
typedef PBCALLBACK(void, *PBORCA_REFPROC) ( PPBORCA_REFERENCE, LPVOID );

/* *********************************************************************** */
/* Structure for PBORCA_ListCheckOutEntries callback function.            */
/* *********************************************************************** */
typedef struct pborca_checkout
{
	LPTSTR       lpszEntryName;              /* Pointer to entry name */
	LPTSTR       lpszLibraryName;            /* Pointer to library name */
	LPTSTR       lpszUserID;                 /* Pointer to UserID */
											/* Mode 's'ource, 'r'egister, */
	TCHAR        cMode;                      /*  or 'd'estination */

} PBORCA_CHECKOUT, FAR *PPBORCA_CHECKOUT;

/* *********************************************************************** */
/* Prototype for PBORCA_ListCheckOutEntries callback function.            */
/* *********************************************************************** */
typedef PBCALLBACK(void, *PBORCA_CHECKPROC) ( PPBORCA_CHECKOUT, LPVOID );


/* *********************************************************************** */
/* Macintohs specific function prototypes                                  */
/* *********************************************************************** */
#if defined(macintosh)

OSErr 	InitMacOrca( void );
OSErr 	ExitMacOrca( void );

#endif

/* *********************************************************************** */
/* Session function prototypes                                             */
/* *********************************************************************** */

PBWINAPI_(VOID) PBORCA_SessionClose          ( HPBORCA hORCASession );

PBWINAPI_(VOID) PBORCA_SessionGetError       ( HPBORCA hORCASession,
                                                  LPTSTR   lpszErrorBuffer,
                                                  INT     iErrorBufferSize );

PBWINAPI_(HPBORCA) PBORCA_SessionOpen           ( void );

PBWINAPI_(INT) PBORCA_SessionSetCurrentAppl ( HPBORCA hORCASession,
                                                  LPTSTR   lpszApplLibName,  
                                                  LPTSTR   lpszApplName );

PBWINAPI_(INT) PBORCA_SessionSetLibraryList ( HPBORCA    hORCASession,
                                                  LPTSTR FAR *pLibNames, 
                                                  INT        iNumberOfLibs );


/* *********************************************************************** */
/* Library management function prototypes                                  */
/* *********************************************************************** */

PBWINAPI_(INT) PBORCA_LibraryCommentModify ( HPBORCA hORCASession,
                                             LPTSTR   lpszLibName,  
                                             LPTSTR   lpszLibComments );

PBWINAPI_(INT) PBORCA_LibraryCreate    ( HPBORCA hORCASession,
                                         LPTSTR   lpszLibName,  
                                         LPTSTR   lpszLibComments );

PBWINAPI_(INT) PBORCA_LibraryDelete    ( HPBORCA hORCASession,
                                         LPTSTR   lpszLibName );   

PBWINAPI_(INT) PBORCA_LibraryDirectory ( HPBORCA         hORCASession,
                                         LPTSTR           lpszLibName,       
                                         LPTSTR           lpszLibComments,  
                                         INT             iCmntsBuffSize, 
                                         PBORCA_LISTPROC pListProc, 
                                         LPVOID          pUserData );

PBWINAPI_(INT) PBORCA_LibraryEntryCopy ( HPBORCA     hORCASession,
                                         LPTSTR       lpszSourceLibName,  
                                         LPTSTR       lpszDestLibName,  
                                         LPTSTR       lpszEntryName, 
                                         PBORCA_TYPE otEntryType );

PBWINAPI_(INT) PBORCA_LibraryEntryDelete ( HPBORCA     hORCASession,
                                           LPTSTR       lpszLibName,  
                                           LPTSTR       lpszEntryName, 
                                           PBORCA_TYPE otEntryType );

PBWINAPI_(INT) PBORCA_LibraryEntryExport ( HPBORCA     hORCASession,
                                           LPTSTR       lpszLibName,  
                                           LPTSTR       lpszEntryName, 
                                           PBORCA_TYPE otEntryType,    
                                           LPTSTR       lpszExportBuffer, 
                                           LONG        lExportBufferSize );

PBWINAPI_(INT) PBORCA_LibraryEntryInformation ( HPBORCA           hORCASession,
                                                LPTSTR             lpszLibName,  
                                                LPTSTR             lpszEntryName, 
                                                PBORCA_TYPE       otEntryType,    
                                                PPBORCA_ENTRYINFO pEntryInfo );

PBWINAPI_(INT) PBORCA_LibraryEntryMove ( HPBORCA     hORCASession,
                                         LPTSTR       lpszSourceLibName,  
                                         LPTSTR       lpszDestLibName,  
                                         LPTSTR       lpszEntryName, 
                                         PBORCA_TYPE otEntryType );

/* *********************************************************************** */
/* Source management function prototypes                                   */
/* *********************************************************************** */

PBWINAPI_(INT) PBORCA_CheckOutEntry (	HPBORCA     hORCASession,
	  									LPTSTR       lpszEntryName,
	  									LPTSTR       lpszSourceLibName,
	  									LPTSTR       lpszDestLibName,
	  									LPTSTR       lpszUserID,
                                    	PBORCA_TYPE otEntryType,
                                    	INT 		bMakeCopy);

PBWINAPI_(INT) PBORCA_CheckInEntry (	HPBORCA     hORCASession,
	  									LPTSTR       lpszEntryName,
	  									LPTSTR       lpszSourceLibName,
	  									LPTSTR       lpszDestLibName,
	  									LPTSTR       lpszUserID,
                                    	PBORCA_TYPE otEntryType,
                                    	INT 		bMoveEntry);

PBWINAPI_(INT) PBORCA_ListCheckOutEntries (	HPBORCA     		hORCASession,
	  										LPTSTR       		lpszLibraryName,
	  										PBORCA_CHECKPROC	lpCallbackFunction,
	  										LPVOID      		pUserData);

/* *********************************************************************** */
/* Compilation function prototypes                                         */
/* *********************************************************************** */

PBWINAPI_(INT) PBORCA_CompileEntryImport ( HPBORCA        hORCASession,
                                           LPTSTR          lpszLibraryName,  
                                           LPTSTR          lpszEntryName, 
                                           PBORCA_TYPE    otEntryType, 
                                           LPTSTR          lpszComments,  
                                           LPTSTR          lpszEntrySyntax,
                                           LONG           lEntrySyntaxBuffSize, 
                                           PBORCA_ERRPROC pCompErrProc, 
                                           LPVOID         pUserData );

PBWINAPI_(INT) PBORCA_CompileEntryImportList ( HPBORCA          hORCASession,
                                               LPTSTR far       *pLibraryNames,  
                                               LPTSTR far       *pEntryNames, 
                                               PBORCA_TYPE far *otEntryType, 
                                               LPTSTR far       *pComments,  
                                               LPTSTR far       *pEntrySyntaxBuffers,
                                               LONG far        *pEntrySyntaxBuffSizes, 
                                               INT              iNumberOfEntries, 
                                               PBORCA_ERRPROC   pCompErrProc, 
                                               LPVOID           pUserData );

PBWINAPI_(INT) PBORCA_CompileEntryRegenerate ( HPBORCA        hORCASession,
                                               LPTSTR          lpszLibraryName,  
                                               LPTSTR          lpszEntryName, 
                                               PBORCA_TYPE    otEntryType, 
                                               PBORCA_ERRPROC pCompErrProc, 
                                               LPVOID         pUserData );

PBWINAPI_(INT) PBORCA_ApplicationRebuild ( 	HPBORCA        		hORCASession,
                                           	PBORCA_REBLD_TYPE	eRebldType,  
                                           	PBORCA_ERRPROC 		pCompErrProc, 
                                            LPVOID         		pUserData );

/* *********************************************************************** */
/* Executable construction function prototypes                             */
/* *********************************************************************** */
PBWINAPI_(INT) PBORCA_ExecutableCreate     ( HPBORCA        hORCASession,
                                             LPTSTR          lpszExeName,  
                                             LPTSTR          lpszIconName,        
                                             LPTSTR          lpszPBRName,        
	                                         PBORCA_LNKPROC pLinkErrProc,           
	                                         LPVOID         pUserData,              
                                             INT FAR       *iPBDFlags,  
                                             INT            iNumberOfPBDFlags,       
                                             LONG           lFlags );

PBWINAPI_(INT) PBORCA_DynamicLibraryCreate ( HPBORCA        hORCASession,           
                                             LPTSTR          lpszLibraryName,        
                                             LPTSTR          lpszPBRName,            
                                             LONG           lFlags );
                                                              
/* *********************************************************************** */
/* Object query function prototypes                                        */
/* *********************************************************************** */

PBWINAPI_(INT) PBORCA_ObjectQueryHierarchy ( HPBORCA         hORCASession,
                                             LPTSTR           lpszLibraryName,  
                                             LPTSTR           lpszEntryName, 
                                             PBORCA_TYPE     otEntryType, 
                                             PBORCA_HIERPROC pHierarchyProc, 
                                             LPVOID          pUserData );

PBWINAPI_(INT) PBORCA_ObjectQueryReference ( HPBORCA         hORCASession,
                                             LPTSTR           lpszLibraryName,  
                                             LPTSTR           lpszEntryName, 
                                             PBORCA_TYPE     otEntryType, 
                                             PBORCA_REFPROC  pReferenceProc, 
                                             LPVOID          pUserData );

#ifdef __cplusplus
}                       /* End of extern "C" { */
#endif	/* __cplusplus */

#endif    /* PB_ORCA */

