/* thiis include file is a "fake" replaccement of real "tkInt" file from tcl/tk */

#define Uses_TWindow
#include <tvision/tv.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


/* few shut-ups: */
#define Tcl_Interp PerlInterpreter
#define Tcl_Obj SV
#define ckalloc malloc

PerlInterpreter *my_perl=0;

/* few excerpts from tcl.h */
    typedef int Tcl_Size;
typedef void *ClientData;

#define TCL_MAJOR_VERSION 9

void Tcl_Panic(const char *, ...) {
    printf("Tcl_Panic\n");
}

#if 0
#undef  Tcl_FindHashEntry
#define Tcl_FindHashEntry(tablePtr, key) \
	(*((tablePtr)->findProc))(tablePtr, (const char *)(key))
#undef  Tcl_CreateHashEntry
#define Tcl_CreateHashEntry(tablePtr, key, newPtr) \
	(*((tablePtr)->createProc))(tablePtr, (const char *)(key), newPtr)
#endif


typedef struct Tcl_HashKeyType Tcl_HashKeyType;
typedef struct Tcl_HashTable Tcl_HashTable;
typedef struct Tcl_HashEntry Tcl_HashEntry;

/*
 * Structure definition for an entry in a hash table. No-one outside Tcl
 * should access any of these fields directly; use the macros defined below.
 */

struct Tcl_HashEntry {
    Tcl_HashEntry *nextPtr;	/* Pointer to next entry in this hash bucket,
				 * or NULL for end of chain. */
    Tcl_HashTable *tablePtr;	/* Pointer to table containing entry. */
    size_t hash;		/* Hash value. */
    void *clientData;		/* Application stores something here with
				 * Tcl_SetHashValue. */
    union {			/* Key has one of these forms: */
	char *oneWordValue;	/* One-word value for key. */
	Tcl_Obj *objPtr;	/* Tcl_Obj * key value. */
	int words[1];		/* Multiple integer words for key. The actual
				 * size will be as large as necessary for this
				 * table's keys. */
	char string[1];		/* String for key. The actual size will be as
				 * large as needed to hold the key. */
    } key;			/* MUST BE LAST FIELD IN RECORD!! */
};

/*
 * Flags used in Tcl_HashKeyType.
 *
 * TCL_HASH_KEY_RANDOMIZE_HASH -
 *				There are some things, pointers for example
 *				which don't hash well because they do not use
 *				the lower bits. If this flag is set then the
 *				hash table will attempt to rectify this by
 *				randomising the bits and then using the upper
 *				N bits as the index into the table.
 * TCL_HASH_KEY_SYSTEM_HASH -	If this flag is set then all memory internally
 *                              allocated for the hash table that is not for an
 *                              entry will use the system heap.
 * TCL_HASH_KEY_DIRECT_COMPARE -
 *	                        Allows fast comparison for hash keys directly
 *                              by compare of their key.oneWordValue values,
 *                              before call of compareKeysProc (much slower
 *                              than a direct compare, so it is speed-up only
 *                              flag). Don't use it if keys contain values rather
 *                              than pointers.
 */

#define TCL_HASH_KEY_RANDOMIZE_HASH 0x1
#define TCL_HASH_KEY_SYSTEM_HASH    0x2
#define TCL_HASH_KEY_DIRECT_COMPARE 0x4

/*
 * Structure definition for the methods associated with a hash table key type.
 */

#define TCL_HASH_KEY_TYPE_VERSION 1
struct Tcl_HashKeyType {
    int version;		/* Version of the table. If this structure is
				 * extended in future then the version can be
				 * used to distinguish between different
				 * structures. */
    int flags;			/* Flags, see above for details. */
    //Tcl_HashKeyProc *hashKeyProc;
				/* Calculates a hash value for the key. If
				 * this is NULL then the pointer itself is
				 * used as a hash value. */
    //Tcl_CompareHashKeysProc *compareKeysProc;
				/* Compares two keys and returns zero if they
				 * do not match, and non-zero if they do. If
				 * this is NULL then the pointers are
				 * compared. */
    //Tcl_AllocHashEntryProc *allocEntryProc;
				/* Called to allocate memory for a new entry,
				 * i.e. if the key is a string then this could
				 * allocate a single block which contains
				 * enough space for both the entry and the
				 * string. Only the key field of the allocated
				 * Tcl_HashEntry structure needs to be filled
				 * in. If something else needs to be done to
				 * the key, i.e. incrementing a reference
				 * count then that should be done by this
				 * function. If this is NULL then Tcl_Alloc is
				 * used to allocate enough space for a
				 * Tcl_HashEntry and the key pointer is
				 * assigned to key.oneWordValue. */
    //Tcl_FreeHashEntryProc *freeEntryProc;
				/* Called to free memory associated with an
				 * entry. If something else needs to be done
				 * to the key, i.e. decrementing a reference
				 * count then that should be done by this
				 * function. If this is NULL then Tcl_Free is
				 * used to free the Tcl_HashEntry. */
};

/*
 * Structure definition for a hash table.  Must be in tcl.h so clients can
 * allocate space for these structures, but clients should never access any
 * fields in this structure.
 */

#define TCL_SMALL_HASH_TABLE 4
struct Tcl_HashTable {
    HV *buckets;	/* Pointer to bucket array. Each element
			 * points to first entry in bucket's hash
			 * chain, or NULL. */
    Tcl_HashEntry *staticBuckets[TCL_SMALL_HASH_TABLE];
			/* Bucket array used for small tables (to
			 * avoid mallocs and frees). */
    Tcl_Size numBuckets;	/* Total number of buckets allocated at
				 * **bucketPtr. */
    Tcl_Size numEntries;	/* Total number of entries present in
				 * table. */
    Tcl_Size rebuildSize;	/* Enlarge table when numEntries gets to be
				 * this large. */
    int downShift;		/* Shift count used in hashing function.
				 * Designed to use high-order bits of
				 * randomized keys. */
    int mask;			/* Mask value used in hashing function. */
    int keyType; /* Type of keys used in this table. It's either TCL_CUSTOM_KEYS,
		    TCL_STRING_KEYS, TCL_ONE_WORD_KEYS, or an integer giving the
		    number of ints that is the size of the key. */
    Tcl_HashEntry *(*findProc) (Tcl_HashTable *tablePtr, const char *key);
    Tcl_HashEntry *(*createProc) (Tcl_HashTable *tablePtr, const char *key, int *newPtr);
    const Tcl_HashKeyType *typePtr; /* Type of the keys used in the Tcl_HashTable. */
};

typedef void (Tcl_FreeProc) (void *blockPtr);
typedef struct TkDisplay_s {
    int packInit;		/* 0 means table below needs initializing. */
    Tcl_HashTable packerHashTable;
	    /* Maps from Tk_Window tokens to corresponding Packer structures. */
} *Tk_Display;
typedef struct TkDisplay_s TkDisplay;

typedef struct Tk_Window_s {
    int r,l,t,b, rw, rh, mrw, mrh;
    TkDisplay *dispPtr;
    struct Tk_Window_s *maintainerPtr;
    struct Tk_Window_s *parentPtr;
    SV *tobject;
    char name[100];
} *Tk_Window;
typedef struct Tk_Window_s TkWindow;


#define TCL_INDEX_NONE  ((Tcl_Size)-1)
#define TCL_OK			0
#define TCL_ERROR		1
#define TCL_RETURN		2
#define TCL_BREAK		3
#define TCL_CONTINUE		4

#define TCL_ONE_WORD_KEYS	4


char *Tcl_GetString(SV *a) {
    char *s = SvPV_nolen(a);
    printf("gs(%s)\n", s);
    return s;
}

#define Tcl_DictObjPut(a,b,c,d) printf("Tcl_DictObjPut\n")
#define Tcl_GetIndexFromObj(a,b,c,d,e,f) TCL_OK
     // Tcl_GetIndexFromObj, Tcl_GetIndexFromObjStruct - lookup string in table of keywords
     // Tcl_GetIndexFromObj(interp, objPtr, tablePtr, msg, flags, indexPtr)
     // Tcl_GetIndexFromObj(NULL, objv[1], optionStrings, "option", 0, &index) != TCL_OK
int Tcl_GetBooleanFromObj(Tcl_Interp *interp,Tcl_Obj *b, int *c) {
    printf("Tcl_GetBooleanFromObj\n");
    *c = SvIV(b); return TCL_OK;
}
// int Tcl_GetBooleanFromObj(interp, objPtr, boolPtr)
#define Tcl_NewBooleanObj(intValue) \
	Tcl_NewWideIntObj((intValue)!=0)
#define Tcl_NewObj() newSV(0)
#define Tcl_NewListObj(a,b)
#define Tcl_ListObjAppendElement(a,b,c)  printf("Tcl_ListObjAppendElement\n")
void Tcl_WrongNumArgs(Tcl_Interp *intp, int argc, Tcl_Obj *const b[], const char *c) {
    printf("Tcl_WrongNumArgs argc=%d c=%s\n", argc, c);
}
void Tcl_SetErrorCode(Tcl_Interp *interp, ...) {
    printf("Tcl_SetErrorCode\n");
}
Tcl_Obj * Tcl_ObjPrintf(const char *format, ...) {
    printf("Tcl_ObjPrintf(%s)\n",format);
    return 0;
}
void Tcl_SetObjResult(Tcl_Interp *interp, Tcl_Obj *resultObjPtr) {
    printf("Tcl_SetObjResult\n");
}
#define Tcl_DoWhenIdle(a,b) printf("Tcl_DoWhenIdle\n")
#define Tcl_Preserve(a) printf("Tcl_Preserve\n")
#define TCL_UNUSED(a)  a

int TkSetGeometryContainer(Tcl_Interp *interp, Tk_Window cont, char *c) {
    printf("TkSetGeometryContainer\n");
    return TCL_OK;
}
#define TkFreeGeometryContainer(a, b) TCL_OK
int TkFreeGeometryContainer2(Tcl_Interp *interp, Tk_Window cont) {
    printf("TkFreeGeometryContainer\n");
    return TCL_OK;
}

TkDisplay my_tkdisplay{packInit:0};

struct Tk_Window_s my_tkwindow{dispPtr:&my_tkdisplay};
int tkw_latest = -1;
struct Tk_Window_s my_tkwindows[100];

int TkGetWindowFromObj (Tcl_Interp *interp, Tk_Window tkwin, Tcl_Obj *objPtr, Tk_Window *windowPtr) {
    printf("TkGetWindowFromObj(%s), windowPtr=%08X\n", SvPV_nolen(objPtr), windowPtr);
    /* objPtr is a string containing widget path, we need to return tv object  */
    HV *hv = get_hv("TVision::paths",GV_ADD);
    STRLEN a;
    char *n = SvPV(objPtr, a);
    printf("n=%s a=%d\n",n,a);
    SV **sv = hv_fetch(hv, n, a, 0);
    if (sv) {
	//SV **sva = av_fetch(*sv,3,0 );
	for (int i=0; i<tkw_latest; i++) {
	    if (strcmp(my_tkwindows[i].name,n)) {
		*windowPtr = &my_tkwindows[i];
		return TCL_OK;
	    }
	}
	tkw_latest++;
	if (tkw_latest>=100)
	    return TCL_ERROR;
	*windowPtr = &my_tkwindows[tkw_latest];
	strcpy(my_tkwindows[tkw_latest].name,n);
	my_tkwindows[tkw_latest].dispPtr = &my_tkdisplay;
	my_tkwindows[tkw_latest].tobject = *sv;
	return TCL_OK;
    }
    //$TVision::names{$w->[1]} = $w;
    //$TVision::paths{$obj->[2]} = $self;
    return TCL_ERROR;
}
#define Tk_Parent(tkwin)	(((Tk_FakeWin *) (tkwin))->parentPtr)
// Tk_Parent returns Tk's token for the logical parent of tkwin. The parent is the token that was specified when tkwin was created, or NULL for main windows.
//Tcl_Obj *Tk_NewWindowObj(Tk_Window tkwin);
#define Tk_InternalBorderRight(a) a->r
#define Tk_InternalBorderLeft(a) a->l
#define Tk_InternalBorderTop(a) a->t
#define Tk_InternalBorderBottom(a) a->b
#define Tk_ReqHeight(a) a->rh
#define Tk_ReqWidth(a) a->rw
#define Tk_MinReqHeight(a) a->mrh
#define Tk_MinReqWidth(a) a->mrw

#define ckfree free

/* some stubs */
#define Tcl_NewStringObj(a,b) newSVpv(a,0)
SV * Tcl_NewWideIntObj(int a) {
    printf("Tcl_NewWideIntObj - newSViv\n");
    return newSViv(a);
}

void Tcl_Release(void *a) {
    printf("Tcl_Release\n");
}

/* few excerpts from tkInt.h */

/*
 * Each geometry manager (the packer, the placer, etc.) is represented by a
 * structure of the following form, which indicates procedures to invoke in
 * the geometry manager to carry out certain functions.
 */

#define Tk_GeomLostSlaveProc Tk_GeomLostContentProc
typedef void (Tk_GeomRequestProc) (void *clientData, Tk_Window tkwin);
typedef void (Tk_GeomLostContentProc) (void *clientData, Tk_Window tkwin);

typedef struct Tk_GeomMgr {
    const char *name; /* Name of the geometry manager (command used
      to invoke it, or name of widget class that allows embedded widgets). */
    Tk_GeomRequestProc *requestProc;
	  /* Procedure to invoke when a content's requested geometry changes. */
    Tk_GeomLostContentProc *lostContentProc;
	  /* Procedure to invoke when content is taken
	   away from one geometry manager by another.
	   NULL means geometry manager doesn't care when content lost. */
} Tk_GeomMgr;

/*
 * Enumerated type for describing a point by which to anchor something:
 */

typedef enum {
    TK_ANCHOR_NULL = -1,
    TK_ANCHOR_N, TK_ANCHOR_NE, TK_ANCHOR_E, TK_ANCHOR_SE,
    TK_ANCHOR_S, TK_ANCHOR_SW, TK_ANCHOR_W, TK_ANCHOR_NW,
    TK_ANCHOR_CENTER
} Tk_Anchor;


void Tk_GeometryRequest(Tk_Window w, int maxWidth, int maxHeight) {
    printf("Tk_GeometryRequest\n");
}
int Tk_Width(Tk_Window w) {
    printf("Tk_Width\n");
    return 2;
}
int Tk_Height(Tk_Window w) {
    printf("Tk_Height\n");
    return 2;
}
int Tk_X(Tk_Window w) {
    printf("Tk_X\n");
    return 3;
}
int Tk_Y(Tk_Window w) {
    printf("Tk_Y\n");
    return 4;
}
void Tk_MoveResizeWindow(Tk_Window w, int x, int y, int width, int height) {
    printf("Tk_MoveResizeWindow\n");
}
int Tk_IsMapped(Tk_Window w) {
    printf("Tk_IsMapped\n");
    return 0;
}
int Tk_MapWindow(Tk_Window w) {
    printf("Tk_MapWindow\n");
    return 0;
}
int Tk_UnmapWindow(Tk_Window w) {
    printf("Tk_UnmapWindow\n");
    return 0;
}
int Tk_GetAnchorFromObj(Tcl_Interp *interp, Tcl_Obj *objPtr, Tk_Anchor *anchorPtr) {
    printf("Tk_GetAnchorFromObj\n");
    return 0;
}
int Tk_GetPixelsFromObj(Tcl_Interp *interp, Tk_Window tkwin, Tcl_Obj *objPtr, int *intPtr) {
    printf("Tk_GetPixelsFromObj\n");
    return 0;
}
int TkParsePadAmount(Tcl_Interp *interp, Tk_Window tkwin, Tcl_Obj *objPtr, int *pad1Ptr, int *pad2Ptr) {
    printf("TkParsePadAmount\n");
    return 0;
}
void Tk_MaintainGeometry(Tk_Window slave, Tk_Window master, int x, int y, int width, int height) {
    printf("Tk_MaintainGeometry\n");
}

void Tk_UnmaintainGeometry(Tk_Window slave, Tk_Window master) {
    printf("Tk_UnmaintainGeometry\n");
}

void Tk_ManageGeometry(Tk_Window tkwin, const Tk_GeomMgr *mgrPtr, void *clientData) {
    printf("Tk_ManageGeometry\n");
}

void Tk_SendVirtualEvent(Tk_Window tkwin, const char *eventName, Tcl_Obj *detail) {
    printf("Tk_SendVirtualEvent\n");
}


typedef void (Tcl_IdleProc) (void *clientData);
void Tcl_CancelIdleCall (Tcl_IdleProc *idleProc, void *clientData) { /* 80 */
    printf("Tcl_CancelIdleCall\n");
}


typedef struct {
    int x, y;
    int width, height;
    int border_width;
    //???? Window sibling;
    int stack_mode;
} XWindowChanges;

XWindowChanges c;
XWindowChanges * Tk_Changes(Tk_Window tkwin) {
    printf("Tk_Changes\n");
    return &c;
}

#define NoEventMask			0L
#define KeyPressMask			(1L<<0)
#define KeyReleaseMask			(1L<<1)
#define ButtonPressMask			(1L<<2)
#define ButtonReleaseMask		(1L<<3)
#define EnterWindowMask			(1L<<4)
#define LeaveWindowMask			(1L<<5)
#define PointerMotionMask		(1L<<6)
#define PointerMotionHintMask		(1L<<7)
#define Button1MotionMask		(1L<<8)
#define Button2MotionMask		(1L<<9)
#define Button3MotionMask		(1L<<10)
#define Button4MotionMask		(1L<<11)
#define Button5MotionMask		(1L<<12)
#define ButtonMotionMask		(1L<<13)
#define KeymapStateMask			(1L<<14)
#define ExposureMask			(1L<<15)
#define VisibilityChangeMask		(1L<<16)
#define StructureNotifyMask		(1L<<17)
#define ResizeRedirectMask		(1L<<18)
#define SubstructureNotifyMask		(1L<<19)
#define SubstructureRedirectMask	(1L<<20)
#define FocusChangeMask			(1L<<21)
#define PropertyChangeMask		(1L<<22)
#define ColormapChangeMask		(1L<<23)
#define OwnerGrabButtonMask		(1L<<24)

#define KeyPress		2
#define KeyRelease		3
#define ButtonPress		4
#define ButtonRelease		5
#define MotionNotify		6
#define EnterNotify		7
#define LeaveNotify		8
#define FocusIn			9
#define FocusOut		10
#define KeymapNotify		11
#define Expose			12
#define GraphicsExpose		13
#define NoExpose		14
#define VisibilityNotify	15
#define CreateNotify		16
#define DestroyNotify		17
#define UnmapNotify		18
#define MapNotify		19
#define MapRequest		20
#define ReparentNotify		21
#define ConfigureNotify		22
#define ConfigureRequest	23
#define GravityNotify		24
#define ResizeRequest		25
#define CirculateNotify		26
#define CirculateRequest	27
#define PropertyNotify		28
#define SelectionClear		29
#define SelectionRequest	30
#define SelectionNotify		31
#define ColormapNotify		32
#define ClientMessage		33
#define MappingNotify		34
#define GenericEvent		35

typedef union _XEvent {
        int type;		/* must not be changed; first element */
	// XAnyEvent xany;
	// XKeyEvent xkey;
	// XButtonEvent xbutton;
	// XMotionEvent xmotion;
	// XCrossingEvent xcrossing;
	// XFocusChangeEvent xfocus;
	// XExposeEvent xexpose;
	// XGraphicsExposeEvent xgraphicsexpose;
	// XNoExposeEvent xnoexpose;
	// XVisibilityEvent xvisibility;
	// XCreateWindowEvent xcreatewindow;
	// XDestroyWindowEvent xdestroywindow;
	// XUnmapEvent xunmap;
	// XMapEvent xmap;
	// XMapRequestEvent xmaprequest;
	// XReparentEvent xreparent;
	// XConfigureEvent xconfigure;
	// XGravityEvent xgravity;
	// XResizeRequestEvent xresizerequest;
	// XConfigureRequestEvent xconfigurerequest;
	// XCirculateEvent xcirculate;
	// XCirculateRequestEvent xcirculaterequest;
	// XPropertyEvent xproperty;
	// XSelectionClearEvent xselectionclear;
	// XSelectionRequestEvent xselectionrequest;
	// XSelectionEvent xselection;
	// XColormapEvent xcolormap;
	// XClientMessageEvent xclient;
	// XMappingEvent xmapping;
	// XErrorEvent xerror;
	// XKeymapEvent xkeymap;
	// XGenericEvent xgeneric;
	// XGenericEventCookie xcookie;
	// XID pad[24];
} XEvent;

typedef void (Tk_EventProc) (void *clientData, XEvent *eventPtr);

// we simulate Tcl_HashTable * with HV*, which we hold in 'buckets'

void Tcl_InitHashTable(Tcl_HashTable *tablePtr, int keyType) {
    printf("Tcl_InitHashTable keyType=%d\n", keyType);
    tablePtr->buckets = newHV();
}
Tcl_HashEntry *Tcl_FindHashEntry(Tcl_HashTable *tablePtr, void *key) {
    printf("Tcl_FindHashEntry\n");
    return 0;
}
Tcl_HashEntry *Tcl_CreateHashEntry(Tcl_HashTable *tablePtr, void *key, int *newPtr) {
    printf("Tcl_CreateHashEntry");
    // seek if we have this entrty in tablePtr->buckets
        //SV**  hv_store(HV*, const char* key, U32 klen, SV* val, U32 hash);
        //SV**  hv_fetch(HV*, const char* key, U32 klen, I32 lval);
    Tcl_HashEntry *the;
    *newPtr = 1;
    printf("1");
    SV **sv = hv_fetch(tablePtr->buckets, (char*)&key, sizeof(void*), 0);
    printf("2");
    if (sv && SvOK(*sv)) {
    printf("3");
	*newPtr = 0;
	the = (Tcl_HashEntry*)SvPV_nolen(*sv);
    printf("4");
    } else {
    printf("5");
	SV *sv0 = newSVpv((char*)&key, sizeof(void*));
    printf("6");
	the = new Tcl_HashEntry {
	    tablePtr:    tablePtr,
	    clientData:  sv0
	};
    printf("7");
	hv_store(tablePtr->buckets, (char*)key, sizeof(void*), sv0, 0);
    printf("8");
    }
    printf(",the=%08X\n",the);
    return the;
}
void Tcl_DeleteHashEntry(Tcl_HashEntry *entryPtr) {
    printf("Tcl_DeleteHashEntry\n");
    delete entryPtr;
}
ClientData Tcl_GetHashValue(Tcl_HashEntry *entryPtr) {
    printf("Tcl_GetHashValue\n");
    return entryPtr->clientData;
}
void Tcl_SetHashValue(Tcl_HashEntry *entryPtr, ClientData a) {
    printf("Tcl_SetHashValue\n");
    //Tcl_HashTable *tablePtr = entryPtr->tablePtr;
    entryPtr->clientData = a;
}
void Tcl_EventuallyFree(void *clientData, Tcl_FreeProc *freeProc) {
    printf("Tcl_EventuallyFree\n");
}

void Tk_CreateEventHandler(Tk_Window tkwin, int mask, Tk_EventProc *proc, ClientData a) {
    printf("Tk_CreateEventHandler\n");
}

#define TkGetContainer(tkwin) (Tk_TopWinHierarchy((TkWindow *)tkwin) ? NULL : \
	(((TkWindow *)tkwin)->maintainerPtr != NULL ? \
	 ((TkWindow *)tkwin)->maintainerPtr : ((TkWindow *)tkwin)->parentPtr))
#define Tk_TopWinHierarchy(tkwin) \
    (((Tk_FakeWin *) (tkwin))->flags & TK_TOP_HIERARCHY)

typedef struct Tk_FakeWin {
//    Display *display;
//    char *dummy1;		/* dispPtr */
//    int screenNum;
//    Visual *visual;
//    int depth;
//    Window window;
//    char *dummy2;		/* childList */
//    char *dummy3;		/* lastChildPtr */
      Tk_Window parentPtr;	/* parentPtr */
//    char *dummy4;		/* nextPtr */
//    char *dummy5;		/* mainPtr */
//    char *pathName;
//    Tk_Uid nameUid;
//    Tk_Uid classUid;
//    XWindowChanges changes;
//    unsigned int dummy6;	/* dirtyChanges */
//    XSetWindowAttributes atts;
//    unsigned long dummy7;	/* dirtyAtts */
    unsigned int flags;
//    char *dummy8;		/* handlerList */
//#if defined(TK_USE_INPUT_METHODS) || (TCL_MAJOR_VERSION > 8)
//    XIC dummy9;			/* inputContext */
//#endif /* TK_USE_INPUT_METHODS */
//    void **dummy10;	/* tagPtr */
//    Tcl_Size dummy11;		/* numTags */
//    Tcl_Size dummy12;		/* optionLevel */
//    char *dummy13;		/* selHandlerList */
//    char *dummy14;		/* geomMgrPtr */
//    void *dummy15;		/* geomData */
//    int reqWidth, reqHeight;
//    int internalBorderLeft;
//    char *dummy16;		/* wmInfoPtr */
//    char *dummy17;		/* classProcPtr */
//    void *dummy18;		/* instanceData */
//    char *dummy19;		/* privatePtr */
//    int internalBorderRight;
//    int internalBorderTop;
//    int internalBorderBottom;
//    int minReqWidth;
//    int minReqHeight;
//#if defined(TK_USE_INPUT_METHODS) || (TCL_MAJOR_VERSION > 8)
//    int dummy20;
//#endif /* TK_USE_INPUT_METHODS */
//    char *dummy21;		/* geomMgrName */
//    Tk_Window dummy22;		/* maintainerPtr */
//#if !defined(TK_USE_INPUT_METHODS) && (TCL_MAJOR_VERSION < 9)
//    XIC dummy9;			/* inputContext */
//    int dummy20;
//#endif /* TK_USE_INPUT_METHODS */
} Tk_FakeWin;

// this is "correct" way
//#define Tk_PathName(tkwin) 	(((Tk_FakeWin *) (tkwin))->pathName)
SV *Tk_PathName(Tk_Window tkwin) {
    printf("Tk_PathName\n");
    return 0;
}


#define TK_TOP_HIERARCHY	0x20000

#if 0
int main1() {
    printf("main\n");
    Tcl_Interp *intp = 0;
    // call geometry manager
    // pack .b -side left
    char *c[] = {".b", "-side", "left"};
    Tcl_Obj *objv[2] = {newSV(0),newSV(0)};
    void *mw=0;
    //Tk_PackObjCmd(mw, intp, 3, objv);
    return 0;
}
#endif

