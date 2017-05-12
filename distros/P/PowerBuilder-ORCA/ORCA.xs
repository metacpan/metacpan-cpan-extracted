//*OEM*
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <windows.h>
#include <stdio.h>
#include "pborca.h"

#define MEMID 0
#define ADD_BUF_SIZE 10000

typedef struct pborca_exeinfo
{
LPTSTR         lpszCompanyName;
LPTSTR         lpszProductName;
LPTSTR         lpszDescription;
LPTSTR         lpszCopyright;
LPTSTR         lpszFileVersion;
LPTSTR         lpszFileVersionNum;
LPTSTR         lpszProductVersion;
LPTSTR         lpszProductVersionNum;
} PBORCA_EXEINFO;

static double constant(char *name,int arg)
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
    //типы объектов
	if (strEQ(name, "PBORCA_APPLICATION"))
	    return PBORCA_APPLICATION;
	if (strEQ(name, "PBORCA_DATAWINDOW"))
	    return PBORCA_DATAWINDOW;
	if (strEQ(name, "PBORCA_FUNCTION"))
	    return PBORCA_FUNCTION;
	if (strEQ(name, "PBORCA_MENU"))
	    return PBORCA_MENU;
	if (strEQ(name, "PBORCA_PIPELINE"))
	    return PBORCA_PIPELINE;
	if (strEQ(name, "PBORCA_PROJECT"))
	    return PBORCA_PROJECT;
	if (strEQ(name, "PBORCA_PROXYOBJECT"))
	    return PBORCA_PROXYOBJECT;
	if (strEQ(name, "PBORCA_QUERY"))
	    return PBORCA_QUERY;
	if (strEQ(name, "PBORCA_STRUCTURE"))
	    return PBORCA_STRUCTURE;
	if (strEQ(name, "PBORCA_USEROBJECT"))
	    return PBORCA_USEROBJECT;
	if (strEQ(name, "PBORCA_WINDOW"))
	    return PBORCA_WINDOW;
    //параметры генерации exe/dll
    if (strEQ(name, "PBORCA_P_CODE"))
        return PBORCA_P_CODE;
    if (strEQ(name, "PBORCA_MACHINE_CODE"))
        return PBORCA_MACHINE_CODE;
    if (strEQ(name, "PBORCA_MACHINE_CODE_NATIVE"))
        return PBORCA_MACHINE_CODE_NATIVE;
    if (strEQ(name, "PBORCA_MACHINE_CODE_16"))
        return PBORCA_MACHINE_CODE_16;
    if (strEQ(name, "PBORCA_P_CODE_16"))
        return PBORCA_P_CODE_16;
    if (strEQ(name, "PBORCA_OPEN_SERVER"))
        return PBORCA_OPEN_SERVER;
    if (strEQ(name, "PBORCA_TRACE_INFO"))
        return PBORCA_TRACE_INFO;
    if (strEQ(name, "PBORCA_ERROR_CONTEXT"))
        return PBORCA_ERROR_CONTEXT;
    if (strEQ(name, "PBORCA_MACHINE_CODE_OPT"))
        return PBORCA_MACHINE_CODE_OPT;
    if (strEQ(name, "PBORCA_MACHINE_CODE_OPT_SPEED"))
        return PBORCA_MACHINE_CODE_OPT_SPEED;
    if (strEQ(name, "PBORCA_MACHINE_CODE_OPT_SPACE"))
        return PBORCA_MACHINE_CODE_OPT_SPACE;
    if (strEQ(name, "PBORCA_MACHINE_CODE_OPT_NONE"))
        return PBORCA_MACHINE_CODE_OPT_NONE;
    if (strEQ(name, "PBORCA_FULL_REBUILD"))
        return PBORCA_FULL_REBUILD;
    if (strEQ(name, "PBORCA_INCREMENTAL_REBUILD"))
        return PBORCA_INCREMENTAL_REBUILD;
    if (strEQ(name, "PBORCA_MIGRATE"))
        return PBORCA_MIGRATE;
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
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

HPBORCA getSID(SV *self) {
    SV **svp;
    HPBORCA sid;

    if(!SvROK(self))
        croak("first parameter is not a reference");
    if(!sv_isobject(self))
        croak("first parameter is not an object");
    if(! (svp = hv_fetch((HV *)SvRV(self), "SID", 3, FALSE)) )
        croak("no SID key in hash");
    return (HPBORCA)SvIV(*svp);
}

void stub_no_init() {
    croak("The initialization is required");
}

void stub() {
    croak("Not implemented");
}
FARPROC fp_PBORCA_SessionOpen=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_SessionClose=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_SessionGetError=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_SessionSetLibraryList=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_SessionSetCurrentAppl=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_LibraryCommentModify=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_LibraryCreate=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_LibraryDelete=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_LibraryDirectory=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_EntryList=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_LibraryEntryCopy=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_LibraryEntryDelete=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_LibraryEntryMove=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_LibraryEntryExport=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_LibraryEntryInformation=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_CompileEntryImport=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_CompileEntryImportList=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_CompileEntryRegenerate=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_ObjectQueryHierarchy=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_ObjectQueryReference=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_ExecutableCreate=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_DynamicLibraryCreate=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_CheckOutEntry=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_CheckInEntry=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_ListCheckOutEntries=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_CallCheckOutEntries=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_PropertiesCopy=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_ConvertUnicode=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_ApplicationRebuild=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_BuildProject=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_BuildProjectEx=(FARPROC)&stub_no_init;
FARPROC fp_PBORCA_SetExeInfo=(FARPROC)&stub_no_init;

#define PBORCA_SessionOpen fp_PBORCA_SessionOpen
#define PBORCA_SessionClose fp_PBORCA_SessionClose
#define PBORCA_SessionGetError fp_PBORCA_SessionGetError
#define PBORCA_SessionSetLibraryList fp_PBORCA_SessionSetLibraryList
#define PBORCA_SessionSetCurrentAppl fp_PBORCA_SessionSetCurrentAppl
#define PBORCA_LibraryCommentModify fp_PBORCA_LibraryCommentModify
#define PBORCA_LibraryCreate fp_PBORCA_LibraryCreate
#define PBORCA_LibraryDelete fp_PBORCA_LibraryDelete
#define PBORCA_LibraryDirectory fp_PBORCA_LibraryDirectory
#define PBORCA_EntryList fp_PBORCA_EntryList
#define PBORCA_LibraryEntryCopy fp_PBORCA_LibraryEntryCopy
#define PBORCA_LibraryEntryDelete fp_PBORCA_LibraryEntryDelete
#define PBORCA_LibraryEntryMove fp_PBORCA_LibraryEntryMove
#define PBORCA_LibraryEntryExport fp_PBORCA_LibraryEntryExport
#define PBORCA_LibraryEntryInformation fp_PBORCA_LibraryEntryInformation
#define PBORCA_CompileEntryImport fp_PBORCA_CompileEntryImport
#define PBORCA_CompileEntryImportList fp_PBORCA_CompileEntryImportList
#define PBORCA_CompileEntryRegenerate fp_PBORCA_CompileEntryRegenerate
#define PBORCA_ObjectQueryHierarchy fp_PBORCA_ObjectQueryHierarchy
#define PBORCA_ObjectQueryReference fp_PBORCA_ObjectQueryReference
#define PBORCA_ExecutableCreate fp_PBORCA_ExecutableCreate
#define PBORCA_DynamicLibraryCreate fp_PBORCA_DynamicLibraryCreate
#define PBORCA_CheckOutEntry fp_PBORCA_CheckOutEntry
#define PBORCA_CheckInEntry fp_PBORCA_CheckInEntry
#define PBORCA_ListCheckOutEntries fp_PBORCA_ListCheckOutEntries
#define PBORCA_CallCheckOutEntries fp_PBORCA_CallCheckOutEntries
#define PBORCA_PropertiesCopy fp_PBORCA_PropertiesCopy
#define PBORCA_ConvertUnicode fp_PBORCA_ConvertUnicode
#define PBORCA_ApplicationRebuild fp_PBORCA_ApplicationRebuild
#define PBORCA_BuildProject fp_PBORCA_BuildProject
#define PBORCA_BuildProjectEx fp_PBORCA_BuildProjectEx
#define PBORCA_SetExeInfo fp_PBORCA_SetExeInfo

typedef struct {
	FARPROC *proc;
	char *name;
} ENTRY_INFO;

ENTRY_INFO api[]={
{&fp_PBORCA_SessionOpen,"PBORCA_SessionOpen"},
{&fp_PBORCA_SessionClose,"PBORCA_SessionClose"},
{&fp_PBORCA_SessionGetError,"PBORCA_SessionGetError"},
{&fp_PBORCA_SessionSetLibraryList,"PBORCA_SessionSetLibraryList"},
{&fp_PBORCA_SessionSetCurrentAppl,"PBORCA_SessionSetCurrentAppl"},
{&fp_PBORCA_LibraryCommentModify,"PBORCA_LibraryCommentModify"},
{&fp_PBORCA_LibraryCreate,"PBORCA_LibraryCreate"},
{&fp_PBORCA_LibraryDelete,"PBORCA_LibraryDelete"},
{&fp_PBORCA_LibraryDirectory,"PBORCA_LibraryDirectory"},
{&fp_PBORCA_EntryList,"PBORCA_EntryList"},
{&fp_PBORCA_LibraryEntryCopy,"PBORCA_LibraryEntryCopy"},
{&fp_PBORCA_LibraryEntryDelete,"PBORCA_LibraryEntryDelete"},
{&fp_PBORCA_LibraryEntryMove,"PBORCA_LibraryEntryMove"},
{&fp_PBORCA_LibraryEntryExport,"PBORCA_LibraryEntryExport"},
{&fp_PBORCA_LibraryEntryInformation,"PBORCA_LibraryEntryInformation"},
{&fp_PBORCA_CompileEntryImport,"PBORCA_CompileEntryImport"},
{&fp_PBORCA_CompileEntryImportList,"PBORCA_CompileEntryImportList"},
{&fp_PBORCA_CompileEntryRegenerate,"PBORCA_CompileEntryRegenerate"},
{&fp_PBORCA_ObjectQueryHierarchy,"PBORCA_ObjectQueryHierarchy"},
{&fp_PBORCA_ObjectQueryReference,"PBORCA_ObjectQueryReference"},
{&fp_PBORCA_ExecutableCreate,"PBORCA_ExecutableCreate"},
{&fp_PBORCA_DynamicLibraryCreate,"PBORCA_DynamicLibraryCreate"},
{&fp_PBORCA_CheckOutEntry,"PBORCA_CheckOutEntry"},
{&fp_PBORCA_CheckInEntry,"PBORCA_CheckInEntry"},
{&fp_PBORCA_ListCheckOutEntries,"PBORCA_ListCheckOutEntries"},
{&fp_PBORCA_CallCheckOutEntries,"PBORCA_CallCheckOutEntries"},
{&fp_PBORCA_PropertiesCopy,"PBORCA_PropertiesCopy"},
{&fp_PBORCA_ConvertUnicode,"PBORCA_ConvertUnicode"},
{&fp_PBORCA_ApplicationRebuild,"PBORCA_ApplicationRebuild"},
{&fp_PBORCA_BuildProject,"PBORCA_BuildProject"},
{&fp_PBORCA_BuildProjectEx,"PBORCA_BuildProjectEx"},
{&fp_PBORCA_SetExeInfo,"PBORCA_SetExeInfo"}
};

HINSTANCE h_api_dll=NULL;

void WINAPI CompErrProc(PBORCA_COMPERR *perr, SV *storage) {
    HV *entry;

    if ( SvTYPE(storage)==SVt_PVAV ) {
        entry=newHV();
        sv_2mortal((SV*)entry);
        sv_setiv(*hv_fetch(entry,"Level",5,1),perr->iLevel);
        sv_setpv(*hv_fetch(entry,"MessageNumber",13,1),perr->lpszMessageNumber);
        sv_setpv(*hv_fetch(entry,"MessageText",11,1),perr->lpszMessageText);
        sv_setiv(*hv_fetch(entry,"ColumnNumber",12,1),perr->iColumnNumber);
        sv_setiv(*hv_fetch(entry,"LineNumber",10,1),(int)perr->iLineNumber);
        av_push((AV*)storage,newRV_inc((SV*)entry));
    } else {
        sv_catpvf((SV *)storage,"%s\n",perr->lpszMessageText);
    }
    return;
}

void WINAPI LinkErrProc(PBORCA_LINKERR *perr, SV *buf) {
    sv_catpvf(buf,"%s\n",perr->lpszMessageText);
}

void WINAPI ListCountProc(PBORCA_DIRENTRY *pent, int *count) {
    (*count)++;
}

void WINAPI ListProc(PBORCA_DIRENTRY *pent, AV *storage) {
    HV *entry;

    //printf("%s\n",pent->lpszEntryName);
    entry=newHV();
    sv_2mortal((SV*)entry);
    sv_setpv(*hv_fetch(entry,"Name",4,1),pent->lpszEntryName);
    sv_setpv(*hv_fetch(entry,"Comment",7,1),pent->szComments);
    sv_setiv(*hv_fetch(entry,"CreateTime",10,1),pent->lCreateTime);
    sv_setiv(*hv_fetch(entry,"Size",4,1),pent->lEntrySize);
    sv_setiv(*hv_fetch(entry,"Type",4,1),(int)pent->otEntryType);
    av_push(storage,newRV_inc((SV*)entry));
    return;
}

void WINAPI ListCheckProc(PBORCA_CHECKOUT *pent, AV *storage) {
    HV *entry;

    entry=newHV();
    sv_2mortal((SV*)entry);
    sv_setpv(*hv_fetch(entry,"Name",4,1),pent->lpszEntryName);
    sv_setpv(*hv_fetch(entry,"LibName",7,1),pent->lpszLibraryName);
    sv_setpv(*hv_fetch(entry,"UserID",6,1),pent->lpszUserID);
    sv_setpvn(*hv_fetch(entry,"Mode",4,1),&(pent->cMode),1);
    av_push(storage,newRV_inc((SV*)entry));
    return;
}

void WINAPI HierProc(PBORCA_HIERARCHY *pent, AV *storage) {
    SV *entry;

    entry=newSVpv(pent->lpszAncestorName,0);
    av_push(storage,entry);
    return;
}

void WINAPI RefProc(PBORCA_REFERENCE *pent, AV *storage) {
    HV *entry;

    entry=newHV();
    sv_2mortal((SV*)entry);
    sv_setpv(*hv_fetch(entry,"Name",4,1),pent->lpszEntryName);
    sv_setpv(*hv_fetch(entry,"LibName",7,1),pent->lpszLibraryName);
    sv_setiv(*hv_fetch(entry,"Type",4,1),(int)pent->otEntryType);
    sv_setpv(*hv_fetch(entry,"RefType",7,1),pent->otEntryRefType==PBORCA_REFTYPE_OPEN?"o":"s");
    av_push(storage,newRV_inc((SV*)entry));
    return;
}

MODULE = PowerBuilder::ORCA     PACKAGE = PowerBuilder::ORCA


void
ORCA_Init(dll)
    char * dll
    CODE:
    int i;
	if (h_api_dll!=NULL) {
		FreeLibrary(h_api_dll);
	}

	h_api_dll=LoadLibrary(dll);
	if ( h_api_dll==NULL ) {
		croak("LoadLibrary failed");
	}
	for (i=0; i<sizeof(api)/sizeof(ENTRY_INFO); i++) {
		*(api[i].proc)=GetProcAddress(h_api_dll,api[i].name);
		if ( *(api[i].proc)==NULL ) {
			*(api[i].proc)=(FARPROC)&stub;
		}
	}


double
constant(name,arg)
	char *		name
	int		arg

void *
SesOpen()
    CODE:
    RETVAL=(void *)PBORCA_SessionOpen();
    OUTPUT:
    RETVAL

void
Close(self)
    SV *self
    CODE:
    PBORCA_SessionClose(getSID(self));

int
Export(self,pbl,obj,type,buf)
    SV *self
    SV *pbl
    SV *obj
    SV *type
    SV *buf
    CODE:
    SV *tmp;

    PBORCA_ENTRYINFO info;
    char *ptmp;

    RETVAL=PBORCA_LibraryEntryInformation(getSID(self),SvPV(pbl,PL_na),SvPV(obj,PL_na),(enum pborca_type)SvIV(type),&info);
    //printf("=====>%ld/%ld/%ld\n",RETVAL,info.lSourceSize,info.lObjectSize);
    if ( RETVAL==0 ) {
        Newz(0,ptmp,info.lSourceSize+ADD_BUF_SIZE,char);
        RETVAL=PBORCA_LibraryEntryExport(getSID(self),SvPV(pbl,PL_na),SvPV(obj,PL_na),(enum pborca_type)SvIV(type),ptmp,info.lSourceSize+ADD_BUF_SIZE);
        //printf("=====>%ld\n",RETVAL);
        //printf("=====>%s\n",ptmp);
        if ( RETVAL==0 ) {
            //sv_setsv(buf,tmp);
            sv_setpv(buf,ptmp);
        }
        Safefree(ptmp);
    }
    OUTPUT:
    RETVAL

int
SetLibList(...)
    CODE:
    int i;
    char **lib_list;

    if ( items>0 ) {
        New(MEMID,lib_list,items-1,char *);
        SAVEFREEPV(lib_list);
        for ( i=1; i<items; i++ ) {
            lib_list[i-1]=SvPV(ST(i),PL_na);
            //printf("=>%d %s\n",items-1,lib_list[i-1]);
        }
        RETVAL=PBORCA_SessionSetLibraryList(getSID(ST(0)),lib_list,items-1);
    }
    OUTPUT:
    RETVAL

int
SetAppl(self,pbl,appl)
    SV *self
    char *pbl
    char *appl
    CODE:
    RETVAL=PBORCA_SessionSetCurrentAppl(getSID(self),pbl,appl);
    OUTPUT:
    RETVAL

char *
GetError(self)
    SV *self
    CODE:
    char buf[PBORCA_MSGBUFFER];

    PBORCA_SessionGetError(getSID(self),buf,PBORCA_MSGBUFFER);
    RETVAL=buf;
    OUTPUT:
    RETVAL

int
EntryInfo(self,pbl,obj,type,hbuf)
    SV *self
    char *pbl
    char *obj
    int type
    SV *hbuf
    CODE:
    PBORCA_ENTRYINFO info;
    SV **psv;


    if ( !SvROK(hbuf) || SvTYPE(SvRV(hbuf))!=SVt_PVHV ) {
        croak("parameter 4 is not a hash reference");
    }
    RETVAL=PBORCA_LibraryEntryInformation(getSID(self),pbl,obj,(enum pborca_type)type,&info);
    if ( RETVAL==0 ) {
        hv_clear((HV *)SvRV(hbuf));
        psv=hv_fetch((HV *)SvRV(hbuf),"Comments",7,1);
        if ( psv!=NULL ) {sv_setpv(*psv,info.szComments);}
        psv=hv_fetch((HV *)SvRV(hbuf),"CreateTime",10,1);
        if ( psv!=NULL ) {sv_setiv(*psv,info.lCreateTime);}
        psv=hv_fetch((HV *)SvRV(hbuf),"ObjectSize",10,1);
        if ( psv!=NULL ) {sv_setiv(*psv,info.lObjectSize);}
        psv=hv_fetch((HV *)SvRV(hbuf),"SourceSize",10,1);
        if ( psv!=NULL ) {sv_setiv(*psv,info.lSourceSize);}
    }
    OUTPUT:
    RETVAL

int
Import(self,pbl,obj,type,comment,syntax,errors)
    SV *self
    char *pbl
    char *obj
    int type
    char *comment
    SV *syntax
    SV *errors
    CODE:

    if ( !SvROK(errors) ) {
        croak("parameter 6 is not a reference");
    }

    if ( SvTYPE(SvRV(errors))==SVt_PVAV ) {
        av_clear((AV*)SvRV(errors));
    } else {
        sv_setpv(SvRV(errors), "");
    }

    RETVAL=PBORCA_CompileEntryImport(getSID(self),
        pbl,
        obj,
        (enum pborca_type)type,
        comment,
        SvPV(syntax,PL_na),
        SvCUR(syntax),
        (PBORCA_ERRPROC)CompErrProc,
        (void *)SvRV(errors));
    OUTPUT:
    RETVAL

int
Regenerate(self,pbl,obj,type,storage)
    SV *self
    char *pbl
    char *obj
    int type
    SV *storage
    CODE:

    if ( !SvROK(storage) ) {
        croak("parameter 4 is not a reference");
    }

    if ( SvTYPE(SvRV(storage))==SVt_PVAV ) {
        av_clear((AV*)SvRV(storage));
    } else {
        sv_setpv(SvRV(storage), "");
    }

    RETVAL=PBORCA_CompileEntryRegenerate(getSID(self),
        pbl,
        obj,
        (enum pborca_type)type,
        (PBORCA_ERRPROC)CompErrProc,
        (void *)SvRV(storage));
    OUTPUT:
    RETVAL

int
ImportList(self,errors,...)
    SV *self
    SV *errors
    CODE:
    char **a_pbl,**a_obj,**a_comment,**a_syntax;
    long *a_syntax_len;
    PBORCA_TYPE *a_type;
    int n_obj,i;

    //проверка корректности параметров
    if ( !SvROK(errors) ) {
        croak("parameter 1 is not a reference");
    }
    if ( SvTYPE(SvRV(errors))==SVt_PVAV ) {
        av_clear((AV*)SvRV(errors));
    } else {
        sv_setpv(SvRV(errors), "");
    }
    if ( items<3 ) {
        croak("no enought arguments");
    }
    n_obj=items-2;

    //выделяем память под массивы параметров
    New(MEMID,a_pbl,n_obj,char *);      SAVEFREEPV(a_pbl);
    New(MEMID,a_obj,n_obj,char *);      SAVEFREEPV(a_obj);
    New(MEMID,a_type,n_obj,PBORCA_TYPE);SAVEFREEPV(a_type);
    New(MEMID,a_comment,n_obj,char *);  SAVEFREEPV(a_comment);
    New(MEMID,a_syntax,n_obj,char *);   SAVEFREEPV(a_syntax);
    New(MEMID,a_syntax_len,n_obj,long); SAVEFREEPV(a_syntax_len);

    //заполняем массивы
    for ( i=0; i<n_obj; i++ ) {
        if ( !hv_exists((HV *)SvRV(ST(i+2)),"Library",7) ) croak("no Library key in hash");
        a_pbl[i]=SvPV(*hv_fetch((HV *)SvRV(ST(i+2)),"Library",7,1),PL_na);
        if ( !hv_exists((HV *)SvRV(ST(i+2)),"Name",4) ) croak("no Name key in hash");
        a_obj[i]=SvPV(*hv_fetch((HV *)SvRV(ST(i+2)),"Name",4,1),PL_na);
        if ( !hv_exists((HV *)SvRV(ST(i+2)),"Type",4) ) croak("no Type key in hash");
        a_type[i]=(PBORCA_TYPE)SvIV(*hv_fetch((HV *)SvRV(ST(i+2)),"Type",4,1));
        if ( !hv_exists((HV *)SvRV(ST(i+2)),"Comment",7) ) croak("no Comment key in hash");
        a_comment[i]=SvPV(*hv_fetch((HV *)SvRV(ST(i+2)),"Comment",7,1),PL_na);
        if ( !hv_exists((HV *)SvRV(ST(i+2)),"Syntax",6) ) croak("no Syntax key in hash");
        a_syntax[i]=SvPV(*hv_fetch((HV *)SvRV(ST(i+2)),"Syntax",6,1),PL_na);
        a_syntax_len[i]=SvCUR(*hv_fetch((HV *)SvRV(ST(i+2)),"Syntax",6,1));
        //printf("--->%d\n",a_syntax_len[i]);
    }

    RETVAL=PBORCA_CompileEntryImportList(getSID(self),
        a_pbl,
        a_obj,
        a_type,
        a_comment,
        a_syntax,
        a_syntax_len,
        n_obj,
        (PBORCA_ERRPROC)CompErrProc,
        (void *)SvRV(errors));
    OUTPUT:
    RETVAL

int
LibInfo(self,pbl,comment,n_obj)
    SV *self
    char *pbl
    SV *comment
    SV *n_obj
    CODE:
    int count;

    char comment_buf[PBORCA_MAXCOMMENT+1];

    if ( !SvROK(comment) ) {
        croak("comment is not a reference");
    }
    if ( !SvROK(n_obj) ) {
        croak("n_obj is not a reference");
    }

    count=0;
    RETVAL=PBORCA_LibraryDirectory(getSID(self),
        pbl,
        comment_buf,
        PBORCA_MAXCOMMENT+1,
        (PBORCA_LISTPROC)ListCountProc,
        &count);
    if ( RETVAL==0 ) {
        sv_setpv(SvRV(comment),comment_buf);
        sv_setiv(SvRV(n_obj),count);
    }
    OUTPUT:
    RETVAL

int
LibDir(self,pbl,storage)
    SV *self
    char *pbl
    SV *storage
    CODE:
    char comment_buf[PBORCA_MAXCOMMENT+1];

    if ( !SvROK(storage) || !(SvTYPE(SvRV(storage))==SVt_PVAV) ) {
        croak("storage is not an array reference");
    }

    av_clear((AV*)SvRV(storage));
    RETVAL=PBORCA_LibraryDirectory(getSID(self),
        pbl,
        comment_buf,
        PBORCA_MAXCOMMENT+1,
        (PBORCA_LISTPROC)ListProc,
        SvRV(storage));
    OUTPUT:
    RETVAL

int
Copy(self,src,dst,obj,type)
    SV *self
    char *src
    char *dst
    char *obj
    int type
    CODE:
    RETVAL=PBORCA_LibraryEntryCopy(getSID(self),
        src,
        dst,
        obj,
        (PBORCA_TYPE)type);
    OUTPUT:
    RETVAL

int
Move(self,src,dst,obj,type)
    SV *self
    char *src
    char *dst
    char *obj
    int type
    CODE:
    RETVAL=PBORCA_LibraryEntryMove(getSID(self),
        src,
        dst,
        obj,
        (PBORCA_TYPE)type);
    OUTPUT:
    RETVAL

int
Del(self,pbl,obj,type)
    SV *self
    char *pbl
    char *obj
    int type
    CODE:
    RETVAL=PBORCA_LibraryEntryDelete(getSID(self),
        pbl,
        obj,
        (PBORCA_TYPE)type);
    OUTPUT:
    RETVAL

int
LibDel(self,pbl)
    SV *self
    char *pbl
    CODE:
    RETVAL=PBORCA_LibraryDelete(getSID(self),
        pbl);
    OUTPUT:
    RETVAL

int
LibCreate(self,pbl,comment)
    SV *self
    char *pbl
    char *comment
    CODE:
    RETVAL=PBORCA_LibraryCreate(getSID(self),
        pbl,comment);
    OUTPUT:
    RETVAL

int
LibCommentModify(self,pbl,comment)
    SV *self
    char *pbl
    char *comment
    CODE:
    RETVAL=PBORCA_LibraryCommentModify(getSID(self),
        pbl,comment);
    OUTPUT:
    RETVAL

int
CheckIn(self,obj,type,master_pbl,work_pbl,user_id,move)
    SV *self
    char *obj
    int type
    char *master_pbl
    char *work_pbl
    char *user_id
    int move
    CODE:
    RETVAL=PBORCA_CheckInEntry(getSID(self),
        obj,
        master_pbl,
        work_pbl,
        user_id,
        (PBORCA_TYPE)type,
        move);
    OUTPUT:
    RETVAL

int
CheckOut(self,obj,type,master_pbl,work_pbl,user_id,move)
    SV *self
    char *obj
    int type
    char *master_pbl
    char *work_pbl
    char *user_id
    int move
    CODE:
    RETVAL=PBORCA_CheckOutEntry(getSID(self),
        obj,
        master_pbl,
        work_pbl,
        user_id,
        (PBORCA_TYPE)type,
        move);
    OUTPUT:
    RETVAL

int
ListCheckOutEntries(self,pbl,storage)
    SV *self
    char *pbl
    SV *storage
    CODE:
    if ( !SvROK(storage) || !(SvTYPE(SvRV(storage))==SVt_PVAV) ) {
        croak("storage is not an array reference");
    }

    RETVAL=PBORCA_ListCheckOutEntries(getSID(self),
        pbl,
        (PBORCA_CHECKPROC)ListCheckProc,
        SvRV(storage));
    OUTPUT:
    RETVAL

int
ObjectQueryHierarchy(self,pbl,obj,type,storage)
    SV *self
    char *pbl
    char *obj
    int type
    SV *storage
    CODE:
    if ( !SvROK(storage) || !(SvTYPE(SvRV(storage))==SVt_PVAV) ) {
        croak("storage is not an array reference");
    }

    av_clear((AV *)SvRV(storage));
    RETVAL=PBORCA_ObjectQueryHierarchy(getSID(self),
        pbl,
        obj,
        (PBORCA_TYPE)type,
        (PBORCA_HIERPROC)HierProc,
        SvRV(storage));
    OUTPUT:
    RETVAL

int
ObjectQueryReference(self,pbl,obj,type,storage)
    SV *self
    char *pbl
    char *obj
    int type
    SV *storage
    CODE:
    if ( !SvROK(storage) || !(SvTYPE(SvRV(storage))==SVt_PVAV) ) {
        croak("storage is not an array reference");
    }

    av_clear((AV *)SvRV(storage));
    RETVAL=PBORCA_ObjectQueryReference(getSID(self),
        pbl,
        obj,
        (PBORCA_TYPE)type,
        (PBORCA_REFPROC)RefProc,
        SvRV(storage));
    OUTPUT:
    RETVAL

int
DllCreate(self,pbl,pbr,flags)
    SV *self
    char *pbl
    char *pbr
    long flags
    CODE:
    RETVAL=PBORCA_DynamicLibraryCreate(getSID(self),
        pbl,
        *pbr=='\0'?0:pbr,
        flags);
    OUTPUT:
    RETVAL

int
ExeCreate(self,pbl,ico,pbr,pbd_flags,flags,errors)
    SV *self
    char *pbl
    char *ico
    char *pbr
    SV *pbd_flags
    long flags
    SV *errors
    CODE:
    int *a_pbd_flags=NULL;
    int n_pbd,i;

    //проверка параметров
    if ( !SvROK(pbd_flags) || !(SvTYPE(SvRV(pbd_flags))==SVt_PVAV) ) {
        croak("pbd_flags is not a reference");
    }
    if ( !SvROK(errors) ) {
        croak("errors is not a reference");
    }

    //заполнение массива
    n_pbd=av_len((AV*)SvRV(pbd_flags))+1;
    if ( n_pbd ) {
        New(MEMID,a_pbd_flags,n_pbd,int);
        SAVEFREEPV(a_pbd_flags);
        for ( i=0; i<n_pbd; i++ ) {
            if ( SvTRUE(*av_fetch((AV*)SvRV(pbd_flags),i,0)) ) {
                a_pbd_flags[i]=1;
            } else {
                a_pbd_flags[i]=0;
            }
        }
    }
    RETVAL=PBORCA_ExecutableCreate(getSID(self),
        pbl,
        ico,
        *pbr=='\0'?0:pbr,
        (PBORCA_LNKPROC)LinkErrProc,
        SvRV(errors),
        a_pbd_flags,
        n_pbd,
        flags);
    OUTPUT:
    RETVAL

int
ApplicationRebuild(self,type,errors)
    SV *self
	long type
    SV *errors
    CODE:

    if ( !SvROK(errors) ) {
        croak("errors is not a reference");
    }

    RETVAL=PBORCA_ApplicationRebuild(getSID(self),
        type,
        (PBORCA_LNKPROC)LinkErrProc,
        SvRV(errors)
	);
    OUTPUT:
    RETVAL

int
SetExeInfo(self,exe_info)
	SV *self
	SV *exe_info
	CODE:
	PBORCA_EXEINFO ExeInfo;

    if ( !SvROK(exe_info) ) {
        croak("exe_info is not a reference");
    }
	memset(&ExeInfo, 0x00, sizeof(PBORCA_EXEINFO));

	if ( hv_exists((HV *)SvRV(exe_info),"CompanyName",11) ) {
		ExeInfo.lpszCompanyName=SvPV(*hv_fetch((HV *)SvRV(exe_info),"CompanyName",11,1),PL_na);
	}
    if ( hv_exists((HV *)SvRV(exe_info),"ProductName",11) ) {
		ExeInfo.lpszProductName=SvPV(*hv_fetch((HV *)SvRV(exe_info),"ProductName",11,1),PL_na);
	}
    if ( hv_exists((HV *)SvRV(exe_info),"Description",11) ) {
		ExeInfo.lpszDescription=SvPV(*hv_fetch((HV *)SvRV(exe_info),"Description",11,1),PL_na);
	}
    if ( hv_exists((HV *)SvRV(exe_info),"Copyright",9) ) {
		ExeInfo.lpszCopyright=SvPV(*hv_fetch((HV *)SvRV(exe_info),"Copyright",9,1),PL_na);
	}
    if ( hv_exists((HV *)SvRV(exe_info),"FileVersion",11) ) {
		ExeInfo.lpszFileVersion=SvPV(*hv_fetch((HV *)SvRV(exe_info),"FileVersion",11,1),PL_na);
	}
    if ( hv_exists((HV *)SvRV(exe_info),"FileVersionNum",14) ) {
		ExeInfo.lpszFileVersionNum=SvPV(*hv_fetch((HV *)SvRV(exe_info),"FileVersionNum",14,1),PL_na);
	}
    if ( hv_exists((HV *)SvRV(exe_info),"ProductVersion",14) ) {
		ExeInfo.lpszProductVersion=SvPV(*hv_fetch((HV *)SvRV(exe_info),"ProductVersion",14,1),PL_na);
	}
    if ( hv_exists((HV *)SvRV(exe_info),"ProductVersionNum",17) ) {
		ExeInfo.lpszProductVersionNum=SvPV(*hv_fetch((HV *)SvRV(exe_info),"ProductVersionNum",17,1),PL_na);
	}

    RETVAL=PBORCA_SetExeInfo(getSID(self),
        &ExeInfo
	);

    OUTPUT:
    RETVAL
