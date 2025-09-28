#define Uses_TView
#define Uses_TButton
#define Uses_TRect
#define Uses_TStatusLine
#define Uses_TStaticText
#define Uses_TLabel
#define Uses_TStatusDef
#define Uses_TStatusItem
#define Uses_TCheckBoxes
#define Uses_TRadioButtons
#define Uses_TScroller
#define Uses_TScrollBar
#define Uses_TIndicator
#define Uses_TInputLine
#define Uses_TEditor
#define Uses_TKeys
#define Uses_MsgBox
#define Uses_fpstream
#define Uses_TEvent
#define Uses_TDeskTop
#define Uses_TApplication
#define Uses_TWindow
#define Uses_TEditWindow
#define Uses_TDialog
#define Uses_TScreen
#define Uses_TSItem
#define Uses_TMenu
#define Uses_TMenuItem
#define Uses_TMenuBar
#define Uses_TSubMenu
#define Uses_TOutline

#include <tvision/tv.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "TVision.h"

extern "C" void boot_TVision_more();
extern "C" void boot_TVision_tkpack();
static int initialized = 0;
CV *cv_on_idle = 0;
CV *cv_handleEvent = 0;
CV *cv_onCommand = 0;

TStatusLine *default_TStatusLine=0;
TMenuBar *default_TMenuBar=0;

TVApp *tapp = NULL;
TVApp::TVApp() :
    TProgInit( &TVApp::initStatusLine,
               &TVApp::initMenuBar,
               &TVApp::initDeskTop )
{
}

void TVApp::idle() {
    TProgram::idle();
    if (cv_on_idle) {
	dSP;
	PUSHMARK(SP);
	PUTBACK;
	call_sv((SV*)cv_on_idle, G_DISCARD);
    }
}

void TVApp::handleEvent(TEvent& event) {
    TApplication::handleEvent(event);
    if (cv_handleEvent) {
	dSP;
	PUSHMARK(SP);
	PUTBACK;
	call_sv((SV*)cv_handleEvent, G_DISCARD);
    }
}

void TVApp::getEvent(TEvent &event) {
    TApplication::getEvent(event);
    switch (event.what) {
    case evCommand:
	if (cv_onCommand) {
	    dSP;
	    PUSHMARK(SP);
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(newSViv(event.message.command)));
            PUSHs(sv_2mortal(newSViv(event.message.infoLong)));
	    PUTBACK;
	    call_sv((SV*)cv_onCommand, G_DISCARD);
	}
	if (event.message.command == 1) { }
	else if (event.message.command == 2) { }
	break;
    case evMouseDown:
	if (event.mouse.buttons == mbRightButton)
	    event.what = evNothing;
	break;
    case evMouseUp:
	break;
    case evMouseMove:
	break;
    case evMouseAuto:
	break;
    case evMouseWheel:
	break;
    case evKeyDown:
	break;
    case evBroadcast:
	break;
    }
}

TStatusLine *TVApp::initStatusLine( TRect r ) {
    printf("TVApp::initStatusLine\n");
    r.a.y = r.b.y - 1;

    return (new TStatusLine( r,
      *new TStatusDef( 0, 50 ) +
        *new TStatusItem( "~F1~ Help", kbF1, cmHelp ) +
        *new TStatusItem( "~Alt-X~ Exit", kbAltX, cmQuit ) +
        *new TStatusItem( 0, kbShiftDel, cmCut ) +
        *new TStatusItem( 0, kbCtrlIns, cmCopy ) +
        *new TStatusItem( 0, kbShiftIns, cmPaste ) +
        *new TStatusItem( 0, kbAltF3, cmClose ) +
        *new TStatusItem( 0, kbF10, cmMenu ) +
        *new TStatusItem( 0, kbF5, cmZoom ) +
        *new TStatusItem( 0, kbCtrlF5, cmResize ) +
      *new TStatusDef( 50, 0xffff ) +
        *new TStatusItem( "Howdy", kbF1, cmHelp )
        )
    );
}

const int
  hcCancelBtn            = 35,
  hcFCChDirDBox          = 37,
  hcFChangeDir           = 15,
  hcFDosShell            = 16,
  hcFExit                = 17,
  hcFOFileOpenDBox       = 31,
  hcFOFiles              = 33,
  hcFOName               = 32,
  hcFOOpenBtn            = 34,
  hcFOpen                = 14,
  hcFile                 = 13,
  hcNocontext            = 0,
  hcOCColorsDBox         = 39,
  hcOColors              = 28,
  hcOMMouseDBox          = 38,
  hcOMouse               = 27,
  hcORestoreDesktop      = 30,
  hcOSaveDesktop         = 29,
  hcOpenBtn              = 36,
  hcOptions              = 26,
  hcPuzzle               = 3,
  hcSAbout               = 8,
  hcSAsciiTable          = 11,
  hcSystem               = 7,
  hcViewer               = 2,
  hcWCascade             = 22,
  hcWClose               = 25,
  hcWNext                = 23,
  hcWPrevious            = 24,
  hcWSizeMove            = 19,
  hcWTile                = 21,
  hcWZoom                = 20,
  hcWindows              = 18;

const int cmAboutCmd    = 100;
const int cmOpenCmd     = 105;
const int cmChDirCmd    = 106;
const int cmMouseCmd    = 108;
const int cmSaveCmd     = 110;
const int cmRestoreCmd  = 111;
const int cmEventViewCmd= 112;


TMenuBar *TVApp::initMenuBar(TRect r) {
    printf("(%d,%d)-(%d,%d)\n",r.a.x, r.a.y,r.b.x,r.b.y);
    if (default_TMenuBar)
	return default_TMenuBar;
    TSubMenu& sub1 =
      *new TSubMenu( "~\xf0~", 0, hcSystem ) +
        *new TMenuItem( "~A~bout...", cmAboutCmd, kbNoKey, hcSAbout ) +
         newLine() +
        *new TMenuItem( "~E~vent Viewer", cmEventViewCmd, kbAlt0, hcNoContext, "Alt-0" );

    TSubMenu& sub2 =
      *new TSubMenu( "~F~ile", 0, hcFile ) +
        *new TMenuItem( "~O~pen...", cmOpenCmd, kbF3, hcFOpen, "F3" ) +
        *new TMenuItem( "~C~hange Dir...", cmChDirCmd, kbNoKey, hcFChangeDir ) +
         newLine() +
        *new TMenuItem( "~D~OS Shell", cmDosShell, kbNoKey, hcFDosShell ) +
        *new TMenuItem( "E~x~it", cmQuit, kbAltX, hcFExit, "Alt-X" );

    TSubMenu& sub3 =
      *new TSubMenu( "~W~indows", 0, hcWindows ) +
        *new TMenuItem( "~R~esize/move", cmResize, kbCtrlF5, hcWSizeMove, "Ctrl-F5" ) +
        *new TMenuItem( "~Z~oom", cmZoom, kbF5, hcWZoom, "F5" ) +
        *new TMenuItem( "~N~ext", cmNext, kbF6, hcWNext, "F6" ) +
        *new TMenuItem( "~C~lose", cmClose, kbAltF3, hcWClose, "Alt-F3" ) +
        *new TMenuItem( "~T~ile", cmTile, kbNoKey, hcWTile ) +
        *new TMenuItem( "C~a~scade", cmCascade, kbNoKey, hcWCascade );

    TSubMenu& sub4 =
      *new TSubMenu( "~O~ptions", 0, hcOptions ) +
        *new TMenuItem( "~M~ouse...", cmMouseCmd, kbNoKey, hcOMouse ) +
        (TMenuItem&) (
            *new TSubMenu( "~D~esktop", 0 ) +
            *new TMenuItem( "~S~ave desktop", cmSaveCmd, kbNoKey, hcOSaveDesktop ) +
            *new TMenuItem( "~R~etrieve desktop", cmRestoreCmd, kbNoKey, hcORestoreDesktop )
        );

    r.b.y =  r.a.y + 1;
    return (new TMenuBar( r, sub1 + sub2 + sub3 + sub4 ) );
}

ushort spin_loop() {
    ushort endState;
    do  {
        endState = 0;
        do  {
            TEvent e;
            tapp->getEvent( e );
            tapp->handleEvent( e );
            if( e.what != evNothing )
                tapp->eventError( e );
        } while( endState == 0 );
    } while( !tapp->valid(endState) );
    return endState;
}

MODULE=TVision PACKAGE=TVision

void spin_loop()
    CODE:
        if(!tapp)
            return;
        TEvent e;
        tapp->getEvent( e );
        tapp->handleEvent( e );
        if( e.what != evNothing )
            tapp->eventError( e );

MODULE=TVision::TApplication PACKAGE=TVision::TApplication

void on_idle(SV *self, CV *c = 0)
    CODE:
        if (cv_on_idle)
            SvREFCNT_dec(cv_on_idle);
        cv_on_idle = c;
        if (c)
            SvREFCNT_inc(c);

void handleEvent(SV *self, CV *c = 0)
    CODE:
        if (cv_handleEvent)
            SvREFCNT_dec(cv_handleEvent);
        cv_handleEvent = c;
        if (c)
            SvREFCNT_inc(c);

void onCommand(SV *self, CV *c = 0)
    CODE:
        if (cv_onCommand)
            SvREFCNT_dec(cv_onCommand);
        cv_onCommand = c;
        if (c)
            SvREFCNT_inc(c);

MODULE=TVision::TButton PACKAGE=TVision::TButton
SV* _new_h(int _ax, int ay, int bx, int by, char *title, int cmd, int flags)
    CODE:
	TButton *w = new TButton(TRect(_ax,ay,bx,by),title,cmd,flags);
        HV *self = newHV();
        hv_store(self, "num", 3, newSViv(cmd), 0);
        hv_store(self, "obj", 3, newSVpvn((const char *)&w, sizeof(w)), 0);
        RETVAL = newRV_inc((SV*) self);
        sv_bless(RETVAL, gv_stashpv("TVision::TButton", GV_ADD));
    OUTPUT:
	RETVAL

char *getData(TInputLine *til)
    CODE:
	char data[2048]; // OMG2
	til->getData(data);
	RETVAL=data;
    OUTPUT:
	RETVAL

MODULE=TVision::TMenuItem PACKAGE=TVision::TMenuItem

TMenuItem *newLine()
    CODE:
	RETVAL = &newLine();
    OUTPUT:
	RETVAL

TMenuItem *plus(TMenuItem *self, TMenuItem *what)
    CODE:
	TMenuItem sum = *self+*what;
        RETVAL = &sum;
    OUTPUT:
	RETVAL

MODULE=TVision::TSubMenu PACKAGE=TVision::TSubMenu

SV* plus(SV *submenu, SV *sm_or_mi)
    CODE:
       if (sv_isa(submenu, "TVision::TSubMenu")) {
           TSubMenu *sm = (TSubMenu*)sv2tv_a(submenu);
	   if (sv_isa(sm_or_mi, "TVision::TSubMenu")) {
	       TSubMenu *sm2 = (TSubMenu*)sv2tv_a(sm_or_mi);
	       *sm + *sm2;
	   } else if (sv_isa(sm_or_mi, "TVision::TMenuItem")) {
	       TMenuItem *mi = (TMenuItem*)sv2tv_a(sm_or_mi);
	       *sm + *mi;
	   } else {
	       croak("TSubmenu::plus arg should be of type TSubMenu or TMenuItem");
	   }
       } else {
           croak("TSubmenu::plus wrong inheritance");
       }
       /* according to RTFS, addition will return the same object, so do we */
       RETVAL = submenu;
    OUTPUT:
       RETVAL

TSubMenu *plus_obsoleted(TSubMenu *self, TMenuItem *what)
    CODE:
	TSubMenu sum = *self+*what;
        RETVAL = &sum;
    OUTPUT:
	RETVAL

TSubMenu *plus_sm(TSubMenu *self, TSubMenu *what)
    CODE:
	TSubMenu sum = *self+*what;
        RETVAL = &sum;
    OUTPUT:
	RETVAL

MODULE=TVision::TDeskTop PACKAGE=TVision::TDeskTop

void insert_obsoleted(SV *self, SV *what)
    CODE:
	TDeskTop* td = sv2tv_s(self,TDeskTop);
        SV *sv = SvRV(what);
        TWindow* w = *((TWindow**) SvPV_nolen(sv));
	td->insert(w);

MODULE=TVision::TView PACKAGE=TVision::TView

TRect getExtent(TView *self)
    CODE:
        RETVAL = self->getExtent();
    OUTPUT:
	RETVAL

void my_draw(TView *self, TRect r, char *text, int color)
    CODE:
        TDrawBuffer buf;
        char textAttr = self->getColor(color); // Obtain attribute for given index.
        buf.moveStr(0, text, textAttr);      // Write to buffer.
        self->writeLine(r.a.x, r.a.y, r.b.x, r.b.y, buf); // Write buffer to view.


MODULE=TVision PACKAGE=TVision

int messageBox(char *msg, int options)
    CODE:
        RETVAL = messageBox(msg, options);
    OUTPUT:
	RETVAL

int messageBoxRect(TRect r, char *msg, int options)
    CODE:
        RETVAL = messageBoxRect(r, msg, options);
    OUTPUT:
	RETVAL

char *inputBox(char *title, char *label, char *dflt="", int limit=1000)
    CODE:
        char buf[4096];
        strncpy(buf,dflt, 4096);
        int ret = inputBox(title, label, buf, limit>4096 ? 4096 : limit);
        RETVAL = buf;
    OUTPUT:
	RETVAL

char *inputBoxRect(TRect r, char *title, char *label, char *dflt="", int limit=1000)
    CODE:
        char buf[4096];
        strncpy(buf,dflt, 4096);
        int ret = inputBoxRect(r, title, label, buf, limit>4096 ? 4096 : limit);
        RETVAL = buf;
    OUTPUT:
	RETVAL


BOOT:
    TObject *tvnull = NULL;
    new_tv_a(tvnull, "TVision");
    sv_setsv(get_sv("TVision::NULL", GV_ADD), rself);
    boot_TVision_more(); /* for TVision-methods.xs */
    boot_TVision_tkpack(); /* for tkPack-cpp.xs */

