/* $Id: Newt.xs,v 1.5 1998/11/09 02:32:06 daniel Exp daniel $ */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <newt.h>

typedef struct _callbackInfo {
	newtComponent en;
	char * state;
} callbackInfo;

/* Suspend stuff */
static SV * suspend_cb = (SV*)NULL;

static void suspend() {
	
	/* Hardcoded.. ugh.
	 * Perl callback works, but doesn't want to return properly.
	 */

	newtSuspend();
	raise(SIGTSTP);
	newtResume();

	/* dSP;
	 * PUSHMARK(SP);
	 * perl_call_sv(suspend_cb, G_DISCARD); */
}

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
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
	if (strEQ(name, "H_NEWT"))
#ifdef H_NEWT
	    return H_NEWT;
#else
	    goto not_there;
#endif
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
	if (strEQ(name, "NEWT_ANCHOR_BOTTOM"))
#ifdef NEWT_ANCHOR_BOTTOM
	    return NEWT_ANCHOR_BOTTOM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_ANCHOR_LEFT"))
#ifdef NEWT_ANCHOR_LEFT
	    return NEWT_ANCHOR_LEFT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_ANCHOR_RIGHT"))
#ifdef NEWT_ANCHOR_RIGHT
	    return NEWT_ANCHOR_RIGHT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_ANCHOR_TOP"))
#ifdef NEWT_ANCHOR_TOP
	    return NEWT_ANCHOR_TOP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_ACTBUTTON"))
#ifdef NEWT_COLORSET_ACTBUTTON
	    return NEWT_COLORSET_ACTBUTTON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_ACTCHECKBOX"))
#ifdef NEWT_COLORSET_ACTCHECKBOX
	    return NEWT_COLORSET_ACTCHECKBOX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_ACTLISTBOX"))
#ifdef NEWT_COLORSET_ACTLISTBOX
	    return NEWT_COLORSET_ACTLISTBOX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_ACTSELLISTBOX"))
#ifdef NEWT_COLORSET_ACTSELLISTBOX
	    return NEWT_COLORSET_ACTSELLISTBOX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_ACTTEXTBOX"))
#ifdef NEWT_COLORSET_ACTTEXTBOX
	    return NEWT_COLORSET_ACTTEXTBOX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_BORDER"))
#ifdef NEWT_COLORSET_BORDER
	    return NEWT_COLORSET_BORDER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_BUTTON"))
#ifdef NEWT_COLORSET_BUTTON
	    return NEWT_COLORSET_BUTTON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_CHECKBOX"))
#ifdef NEWT_COLORSET_CHECKBOX
	    return NEWT_COLORSET_CHECKBOX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_COMPACTBUTTON"))
#ifdef NEWT_COLORSET_COMPACTBUTTON
	    return NEWT_COLORSET_COMPACTBUTTON;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_DISENTRY"))
#ifdef NEWT_COLORSET_DISENTRY
	    return NEWT_COLORSET_DISENTRY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_EMPTYSCALE"))
#ifdef NEWT_COLORSET_EMPTYSCALE
	    return NEWT_COLORSET_EMPTYSCALE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_ENTRY"))
#ifdef NEWT_COLORSET_ENTRY
	    return NEWT_COLORSET_ENTRY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_FULLSCALE"))
#ifdef NEWT_COLORSET_FULLSCALE
	    return NEWT_COLORSET_FULLSCALE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_HELPLINE"))
#ifdef NEWT_COLORSET_HELPLINE
	    return NEWT_COLORSET_HELPLINE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_LABEL"))
#ifdef NEWT_COLORSET_LABEL
	    return NEWT_COLORSET_LABEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_LISTBOX"))
#ifdef NEWT_COLORSET_LISTBOX
	    return NEWT_COLORSET_LISTBOX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_ROOT"))
#ifdef NEWT_COLORSET_ROOT
	    return NEWT_COLORSET_ROOT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_ROOTTEXT"))
#ifdef NEWT_COLORSET_ROOTTEXT
	    return NEWT_COLORSET_ROOTTEXT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_SELLISTBOX"))
#ifdef NEWT_COLORSET_SELLISTBOX
	    return NEWT_COLORSET_SELLISTBOX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_SHADOW"))
#ifdef NEWT_COLORSET_SHADOW
	    return NEWT_COLORSET_SHADOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_TEXTBOX"))
#ifdef NEWT_COLORSET_TEXTBOX
	    return NEWT_COLORSET_TEXTBOX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_TITLE"))
#ifdef NEWT_COLORSET_TITLE
	    return NEWT_COLORSET_TITLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_COLORSET_WINDOW"))
#ifdef NEWT_COLORSET_WINDOW
	    return NEWT_COLORSET_WINDOW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_ENTRY_DISABLED"))
#ifdef NEWT_ENTRY_DISABLED
	    return NEWT_ENTRY_DISABLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_ENTRY_HIDDEN"))
#ifdef NEWT_ENTRY_HIDDEN
	    return NEWT_ENTRY_HIDDEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_ENTRY_RETURNEXIT"))
#ifdef NEWT_ENTRY_RETURNEXIT
	    return NEWT_ENTRY_RETURNEXIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_ENTRY_SCROLL"))
#ifdef NEWT_ENTRY_SCROLL
	    return NEWT_ENTRY_SCROLL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_FD_READ"))
#ifdef NEWT_FD_READ
	    return NEWT_FD_READ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_FD_WRITE"))
#ifdef NEWT_FD_WRITE
	    return NEWT_FD_WRITE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_FLAG_DISABLED"))
#ifdef NEWT_FLAG_DISABLED
	    return NEWT_FLAG_DISABLED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_FLAG_DOBORDER"))
#ifdef NEWT_FLAG_DOBORDER
	    return NEWT_FLAG_DOBORDER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_FLAG_HIDDEN"))
#ifdef NEWT_FLAG_HIDDEN
	    return NEWT_FLAG_HIDDEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_FLAG_MULTIPLE"))
#ifdef NEWT_FLAG_MULTIPLE
	    return NEWT_FLAG_MULTIPLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_FLAG_NOF12"))
#ifdef NEWT_FLAG_NOF12
	    return NEWT_FLAG_NOF12;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_FLAG_NOSCROLL"))
#ifdef NEWT_FLAG_NOSCROLL
	    return NEWT_FLAG_NOSCROLL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_FLAG_RETURNEXIT"))
#ifdef NEWT_FLAG_RETURNEXIT
	    return NEWT_FLAG_RETURNEXIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_FLAG_SCROLL"))
#ifdef NEWT_FLAG_SCROLL
	    return NEWT_FLAG_SCROLL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_FLAG_SELECTED"))
#ifdef NEWT_FLAG_SELECTED
	    return NEWT_FLAG_SELECTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_FLAG_WRAP"))
#ifdef NEWT_FLAG_WRAP
	    return NEWT_FLAG_WRAP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_FORM_NOF12"))
#ifdef NEWT_FORM_NOF12
	    return NEWT_FORM_NOF12;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_GRID_FLAG_GROWX"))
#ifdef NEWT_GRID_FLAG_GROWX
	    return NEWT_GRID_FLAG_GROWX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_GRID_FLAG_GROWY"))
#ifdef NEWT_GRID_FLAG_GROWY
	    return NEWT_GRID_FLAG_GROWY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_BKSPC"))
#ifdef NEWT_KEY_BKSPC
	    return NEWT_KEY_BKSPC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_DELETE"))
#ifdef NEWT_KEY_DELETE
	    return NEWT_KEY_DELETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_DOWN"))
#ifdef NEWT_KEY_DOWN
	    return NEWT_KEY_DOWN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_END"))
#ifdef NEWT_KEY_END
	    return NEWT_KEY_END;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_ENTER"))
#ifdef NEWT_KEY_ENTER
	    return NEWT_KEY_ENTER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_EXTRA_BASE"))
#ifdef NEWT_KEY_EXTRA_BASE
	    return NEWT_KEY_EXTRA_BASE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_F1"))
#ifdef NEWT_KEY_F1
	    return NEWT_KEY_F1;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_F10"))
#ifdef NEWT_KEY_F10
	    return NEWT_KEY_F10;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_F11"))
#ifdef NEWT_KEY_F11
	    return NEWT_KEY_F11;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_F12"))
#ifdef NEWT_KEY_F12
	    return NEWT_KEY_F12;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_F2"))
#ifdef NEWT_KEY_F2
	    return NEWT_KEY_F2;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_F3"))
#ifdef NEWT_KEY_F3
	    return NEWT_KEY_F3;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_F4"))
#ifdef NEWT_KEY_F4
	    return NEWT_KEY_F4;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_F5"))
#ifdef NEWT_KEY_F5
	    return NEWT_KEY_F5;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_F6"))
#ifdef NEWT_KEY_F6
	    return NEWT_KEY_F6;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_F7"))
#ifdef NEWT_KEY_F7
	    return NEWT_KEY_F7;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_F8"))
#ifdef NEWT_KEY_F8
	    return NEWT_KEY_F8;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_F9"))
#ifdef NEWT_KEY_F9
	    return NEWT_KEY_F9;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_HOME"))
#ifdef NEWT_KEY_HOME
	    return NEWT_KEY_HOME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_LEFT"))
#ifdef NEWT_KEY_LEFT
	    return NEWT_KEY_LEFT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_PGDN"))
#ifdef NEWT_KEY_PGDN
	    return NEWT_KEY_PGDN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_PGUP"))
#ifdef NEWT_KEY_PGUP
	    return NEWT_KEY_PGUP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_RESIZE"))
#ifdef NEWT_KEY_RESIZE
	    return NEWT_KEY_RESIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_RETURN"))
#ifdef NEWT_KEY_RETURN
	    return NEWT_KEY_RETURN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_RIGHT"))
#ifdef NEWT_KEY_RIGHT
	    return NEWT_KEY_RIGHT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_SUSPEND"))
#ifdef NEWT_KEY_SUSPEND
	    return NEWT_KEY_SUSPEND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_TAB"))
#ifdef NEWT_KEY_TAB
	    return NEWT_KEY_TAB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_UNTAB"))
#ifdef NEWT_KEY_UNTAB
	    return NEWT_KEY_UNTAB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_KEY_UP"))
#ifdef NEWT_KEY_UP
	    return NEWT_KEY_UP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_LISTBOX_RETURNEXIT"))
#ifdef NEWT_LISTBOX_RETURNEXIT
	    return NEWT_LISTBOX_RETURNEXIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_TEXTBOX_SCROLL"))
#ifdef NEWT_TEXTBOX_SCROLL
	    return NEWT_TEXTBOX_SCROLL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "NEWT_TEXTBOX_WRAP"))
#ifdef NEWT_TEXTBOX_WRAP
	    return NEWT_TEXTBOX_WRAP;
#else
	    goto not_there;
#endif
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
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

MODULE = Term::Newt		PACKAGE = Term::Newt::XS

double
constant(name,arg)
	char *		name
	int		arg

void
DESTROY()
	CODE:
	{
		newtFinished();
	}

# Functions
int
newtInit()

int
newtFinished()

void
newtCls()

void
newtResizeScreen(redraw)
	int redraw;

void
newtWaitForKey()

void
newtClearKeyBuffer()

void
newtDelay(usecs)
	int usecs;

int
newtOpenWindow(left,top,width,height,title)
	int left;
	int top;
	int width;
	int height;
	const char * title;

int
newtCenteredWindow(width,height,title)
	int width;
	int height;
	const char * title;

void
newtPopWindow()

#void
#newtSetColors(colors)
#	newtColors colors;

void
newtRefresh()

void
newtSuspend()

void
newtSetSuspendCallback(perl_cb)
	SV * perl_cb;
	CODE:
	{
		if (suspend_cb == (SV*)NULL) {
			suspend_cb = newSVsv(perl_cb);
		} else {
			SvSetSV(suspend_cb, perl_cb);
		}

		newtSetSuspendCallback(suspend);
	}

void
newtResume()

void
newtPushHelpLine(text)
	const char * text;

void
newtRedrawHelpLine()

void
newtPopHelpLine()

void
newtDrawRootText(row,col,text)
	int row;
	int col;
	const char * text;

void
newtBell()

#####################################
# Components
newtComponent
newtCompactButton(left,top,text)
	int left;
	int top;
	const char * text;

newtComponent
newtButton(left,top,text)
	int left;
	int top;
	const char * text;

newtComponent
newtCheckbox(left,top,text,defValue,seq,result)
	int left;
	int top;
	const char * text;
	char defValue;
	const char * seq;
	char * result;

char
newtCheckboxGetValue(co)
	newtComponent co;

newtComponent
newtRadiobutton(left,top,text,isDefault,prevButton)
	int left;
	int top;
	const char * text;
	int isDefault;
	newtComponent prevButton;
	CODE:
		if (prevButton == NULL) {
			prevButton = NULL;
		}
		RETVAL = newtRadiobutton(left,top,text,isDefault,prevButton);
	OUTPUT:
	RETVAL

newtComponent
newtRadioGetCurrent(setMember)
	newtComponent setMember;

newtComponent
newtListitem(left,top,text,isDefault,prevItem,data,flags)
	int left;
	int top;
	const char * text;
	int isDefault;
	newtComponent prevItem;
	const void * data;
	int flags;


void
newtListitemSet(co,text)
	newtComponent co;
	const char * text;

void *
newtListitemGetData(co)
	newtComponent co;

void
newtGetScreenSize(cols,rows)
	int * cols;
	int * rows;

newtComponent
newtLabel(left,top,text)
	int left;
	int top;
	const char * text;

void
newtLabelSetText(co,text)
	newtComponent co;
	const char * text;

newtComponent
newtVerticalScrollbar(left,top,height,normalColorset,thumbColorset)
	int left;
	int top;
	int height;
	int normalColorset;
	int thumbColorset;

void
newtScrollbarSet(co,where,total)
	newtComponent co;
	int where;
	int total;

newtComponent
newtListbox(left,top,height,flags)
	int left;
	int top;
	int height;
	int flags;

void *
newtListboxGetCurrent(co)
	newtComponent co;

void
newtListboxSetCurrent(co,num)
	newtComponent co;
	int num;

void
newtListboxSetCurrentByKey(co,key)
	newtComponent co;
	void * key;

void
newtListboxSetText(co,num,text)
	newtComponent co;
	int num;
	const char * text;

void
newtListboxSetEntry(co,num,text)
	newtComponent co;
	int num;
	const char * text;

void
newtListboxSetWidth(co,width)
	newtComponent co;
	int width;

# return the data passed to AddEntry 
void
newtListboxSetData(co,num,data)
	newtComponent co;
	int num;
	void * data;

int
newtListboxAddEntry(co,text,data)
	newtComponent co;
	const char * text;
	const void * data;

# Send the key to insert after, or NULL to insert at the top 
int
newtListboxInsertEntry(co,text,data,key)
	newtComponent co;
	const char * text;
	const void * data;
	void * key;

int
newtListboxDeleteEntry(co,data)
	newtComponent co;
	void * data;

# removes all entries from listbox
void
newtListboxClear(co)
	newtComponent co;

void
newtListboxGetEntry(co,num,text,data)
	newtComponent co;
	int num;
	char * text;
	void * data;
	PPCODE:
	{
		newtListboxGetEntry(co, num, &text, data);
	}

# Returns an array of data pointers from items, last element is NULL 
void *
newtListboxGetSelection(co,numitems)
	newtComponent co;
	int *numitems;

void
newtListboxClearSelection(co)
	newtComponent co;

void
newtListboxSelectItem(co,item,sense)
	newtComponent co;
	int item;
	enum newtFlagsSense sense;

newtComponent
newtTextboxReflowed(left,top,text,width,flexDown,flexUp,flags)
	int left;
	int top;
	char * text;
	int width;
	int flexDown;
	int flexUp;
	int flags;

newtComponent
newtTextbox(left,top,width,height,flags)
	int left;
	int top;
	int width;
	int height;
	int flags;

void
newtTextboxSetText(co,text)
	newtComponent co;
	const char * text;

void
newtTextboxSetHeight(co,height)
	newtComponent co;
	int height;

int
newtTextboxGetNumLines(co)
	newtComponent co;

char *
newtReflowText(text,width,flexDown,flexUp,actualWidth,actualHeight)
	char * text;
	int width;
	int flexDown;
	int flexUp;
	int * actualWidth;
	int * actualHeight;

newtComponent
newtForm(vertBar,help,flags)
	newtComponent vertBar;
	const char * help;
	int flags;

void
newtFormWatchFd(form,fd,fdFlags)
	newtComponent form;
	int fd;
	int fdFlags;

void
newtFormSetSize(co)
	newtComponent co;

newtComponent
newtFormGetCurrent(co)
	newtComponent co;

void
newtFormSetBackground(co,color)
	newtComponent co;
	int color;

void
newtFormSetCurrent(co,subco)
	newtComponent co;
	newtComponent subco;

void
newtFormAddComponent(form,co)
	newtComponent form;
	newtComponent co;

#void
#newtFormAddComponents(form, ...)
#	newtComponent form;
#	CODE:
#	{
#		int i;
#		for (i = 1; i < items; i++) {
#			newtFormAddComponent(form,ST(i));
#		}
#	}

void
newtFormSetHeight(co,height)
	newtComponent co;
	int height;

void
newtFormSetWidth(co,width)
	newtComponent co;
	int width;

newtComponent
newtRunForm(form)
	newtComponent form;

#void
#newtFormRun(co,es)
#	newtComponent co;
#	newtExitStruct es;
#	CODE:
#		newtFormRun(co, &es);

void
newtDrawForm(form)
	newtComponent form;

void
newtFormAddHotKey(co,key)
	newtComponent co;
	int key;

newtComponent
newtEntry(left,top,initialValue,width,resultPtr,flags)
	int left;
	int top;
	const char * initialValue;
	int width;
	SV * resultPtr;
	int flags;
	CODE:
	{
		/* This isn't quite right.. I need a pointer to a pointer. I
		 * think. */
		char *result;

		RETVAL = newtEntry(left,top,initialValue,width,&result,flags);
		sv_setpvn(SvRV(resultPtr), (char *)result, strlen(result));
	}
	OUTPUT:
	RETVAL

void
newtEntrySet(co,value,cursorAtEnd)
	newtComponent co;
	const char * value;
	int cursorAtEnd;

void
newtEntrySetFilter(co,filter,data)
	newtComponent co;
	newtEntryFilter filter;
	void * data;

char *
newtEntryGetValue(co)
	newtComponent co;

newtComponent
newtScale(left,top,width,fullValue)
	int left;
	int top;
	int width;
	long long fullValue;

void
newtScaleSet(co,amount)
	newtComponent co;
	unsigned long long amount;

###########################
# Callbacks

void
newtDisableCallback(co,data)
	newtComponent co;
	void * data;
	CODE:
	{
		callbackInfo *cbi = data;

		if (*cbi->state == ' ') {
			newtEntrySetFlags(cbi->en, NEWT_FLAG_DISABLED, NEWT_FLAGS_RESET);
		} else {
			newtEntrySetFlags(cbi->en, NEWT_FLAG_DISABLED, NEWT_FLAGS_SET);
		}

		newtRefresh();
	}

#callbackInfo
#newtNewCallback(co, state)
#	newtComponent co;
#	char * state;
#	CODE:
#	{
#		callbackInfo cbis[3];
#		cbis[0].state = state;
#		cbis[0].en = co;
#		RETVAL = cbis[0];
#	}
#	OUTPUT:
#	RETVAL

#void
#newtComponentAddCallback(co,f,data)
#	newtComponent co;
#	SV * f;
#	void * data;	
#
#	CODE:
#	{

#void newtComponentAddCallback(newtComponent co, newtCallback f, void * data) {
#	co->callback = f;
#    co->callbackData = data;
#
#		PUSHMARK(sp);
#		newtComponentAddCallback(co, perl_call_pv(f, G_DISCARD|G_NOARGS), data);
#	}

void
newtComponentTakesFocus(co,val)
	newtComponent co;
	int val;

# this also destroys all of the components (including other forms) on the form
void
newtFormDestroy(form)
	newtComponent form;

#########################
# Grid

newtGrid
newtCreateGrid(cols,rows)
	int cols;
	int rows;


newtGrid
newtGridVStacked(type,what, ...)
	enum newtGridElement type;
	void * what;

newtGrid
newtGridVCloseStacked(type,what, ...)
	enum newtGridElement type;
	void * what;

newtGrid
newtGridHStacked(type1,what1, ...)
	enum newtGridElement type1;
	void * what1;

newtGrid
newtGridHCloseStacked(type1,what1, ...)
	enum newtGridElement type1;
	void * what1;


newtGrid
newtGridBasicWindow(text,middle,buttons)
	newtComponent text;
	newtGrid middle;
	newtGrid buttons;

newtGrid
newtGridSimpleWindow(text,middle,buttons)
	newtComponent text;
	newtComponent middle;
	newtGrid buttons;

void
newtGridSetField(grid,col,row,type,val,padLeft,padTop,padRight,padBottom,anchor,flags)
	newtGrid grid;
	int col;
	int row;
	enum newtGridElement type;
	void * val;
	int padLeft;
	int padTop;
	int padRight;
	int padBottom;
	int anchor;
	int flags;

void
newtGridPlace(grid,left,top)
	newtGrid grid
	int left;
	int top;

void
newtGridFree(grid,recurse)
	newtGrid grid;
	int recurse;

void
newtGridGetSize(grid,width,height)
	newtGrid grid;
	int * width;
	int * height;

void
newtGridWrappedWindow(grid,title)
	newtGrid grid;
	char * title;
	
void
newtGridWrappedWindowAt(grid,title,left,top)
	newtGrid grid;
	char * title;
	int left;
	int top;

void
newtGridAddComponentsToForm(grid,form,recurse)
	newtGrid grid;
	newtComponent form;
	int recurse;

# convienve 
newtGrid
newtButtonBarv(button1,b1comp,args)
	char * button1;
	newtComponent * b1comp;
	va_list args;

newtGrid
newtButtonBar(button1,b1comp, ...)
	char * button1;
	newtComponent * b1comp;

# automatically centered and shrink wrapped
void
newtWinMessage(title,buttonText,text, ...)
	char * title;
	char * buttonText;
	char * text;

void
newtWinMessagev(title,buttonText,text,argv)
	char * title;
	char * buttonText;
	char * text;
	va_list argv;

# having separate calls for these two seems silly, but having two separate
# variable length-arg lists seems like a bad idea as well

# Returns 0 if F12 was pressed, 1 for button1, 2 for button2
int
newtWinChoice(title,button1,button2,text, ...)
	char * title;
	char * button1;
	char * button2;
	char * text;

int
newtWinTernary(title,button1,button2,button3,message, ...)
	char * title;
	char * button1;
	char * button2;
	char * button3;
	char * message;

int
newtWinMenu(title,text,suggestedWidth,flexDown,flexUp,maxListHeight,nitems,listItem,button1, ...)
	char * title;
	char * text;
	int suggestedWidth;
	int flexDown;
	int flexUp;
	int maxListHeight;
	char * nitems;
	int * listItem;
	char * button1;
	CODE:
	{
		RETVAL = newtWinMenu(title,text,suggestedWidth,
			flexDown,flexUp,maxListHeight,&nitems,listItem,button1);
	}
	OUTPUT:
	RETVAL

# Returns the button number pressed, 0 on F12. The final values are
# dynamically allocated, and need to be freed.
#int
#newtWinEntries(title,text,suggestedWidth,flexDown,flexUp,dataWidth,nitems,button1,...)
#	char * title;
#	char * text;
#	int suggestedWidth;
#	int flexDown;
#	int flexUp;
#	int dataWidth;
#	newtWinEntry * nitems;
#	char * button1;
#	CODE:
#	{
#		RETVAL = newtWinEntries(title,text,suggestedWidth,
#			flexDown,flexUp,dataWidth,&nitems,button1);
#
#	}
#	OUTPUT:
#	RETVAL
