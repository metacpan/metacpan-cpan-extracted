
#define Uses_TBackground
#define Uses_TView
#define Uses_TButton
#define Uses_TRect
#define Uses_TStatusLine
#define Uses_TStaticText
#define Uses_TLabel
#define Uses_TStatusDef
#define Uses_TStatusItem
#define Uses_TCheckBoxes
#define Uses_TColorSelector
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
#define Uses_THistory

#include <tvision/tv.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#undef select

#include "TVision.h"

extern TStatusLine *default_TStatusLine;
extern TMenuBar *default_TMenuBar;

MODULE=TVision::TVApp PACKAGE=TVision::TVApp

TVApp* new(TMenuBar *tmbr=0, TStatusLine *tsl=0)
    CODE:
        if (tmbr)
	    default_TMenuBar = tmbr;
	default_TStatusLine = tsl;
        RETVAL = new TVApp();
        // RETVAL = get_sv("TVision::TApplication::the_app", GV_ADD);
	//do_sv_dump(0, PerlIO_stderr(), RETVAL, 0, 10, 0,0);
    OUTPUT:
	RETVAL

MODULE=TVision::TApplication PACKAGE=TVision::TApplication

TDeskTop* deskTop(TVApp *tapp)
    CODE:
        RETVAL = tapp->deskTop;
    OUTPUT:
	RETVAL

MODULE=TVision::TBackground PACKAGE=TVision::TBackground
TBackground* new(TRect r, char aPattern)
    CODE:
        RETVAL = new TBackground( r,  aPattern);
    OUTPUT:
	RETVAL

MODULE=TVision::TDeskTop PACKAGE=TVision::TDeskTop
TDeskTop* new(TRect r)
    CODE:
        RETVAL = new TDeskTop( r);
    OUTPUT:
	RETVAL

MODULE=TVision::TScroller PACKAGE=TVision::TScroller
TScroller* new(TRect r, TScrollBar *aHScrollBar, TScrollBar *aVScrollBar)
    CODE:
        RETVAL = new TScroller( r, aHScrollBar, aVScrollBar);
    OUTPUT:
	RETVAL

MODULE=TVision::TLabel PACKAGE=TVision::TLabel
TLabel* new(TRect r, char * aText, TView *aLink)
    CODE:
        RETVAL = new TLabel( r,  aText, aLink);
    OUTPUT:
	RETVAL

MODULE=TVision::TButton PACKAGE=TVision::TButton
TButton* new(TRect r, char *title, int cmd, int flags)
    CODE:
        RETVAL = new TButton( r, title,  cmd,  flags);
    OUTPUT:
	RETVAL

MODULE=TVision::TScrollBar PACKAGE=TVision::TScrollBar
TScrollBar* new(TRect r)
    CODE:
        RETVAL = new TScrollBar( r);
    OUTPUT:
	RETVAL

MODULE=TVision::TColorSelector PACKAGE=TVision::TColorSelector
TColorSelector* new(TRect Bounds, int ASelType)
    CODE:
        RETVAL = new TColorSelector( Bounds,  TColorSelector::ColorSel(ASelType));
    OUTPUT:
	RETVAL

MODULE=TVision::TIndicator PACKAGE=TVision::TIndicator
TIndicator* new(TRect r)
    CODE:
        RETVAL = new TIndicator( r);
    OUTPUT:
	RETVAL

MODULE=TVision::TInputLine PACKAGE=TVision::TInputLine
TInputLine* new(TRect r, int limit)
    CODE:
        RETVAL = new TInputLine( r,  limit);
    OUTPUT:
	RETVAL

MODULE=TVision::TMenuBar PACKAGE=TVision::TMenuBar
TMenuBar* new(TRect r, TSubMenu* aMenu)
    CODE:
        RETVAL = new TMenuBar( r,  *aMenu);
    OUTPUT:
	RETVAL

MODULE=TVision::TMenuBar PACKAGE=TVision::TMenuBar
TMenuBar* new1(TRect r, TMenu *aMenu)
    CODE:
        RETVAL = new TMenuBar( r, aMenu);
    OUTPUT:
	RETVAL

MODULE=TVision::TMenu PACKAGE=TVision::TMenu
TMenu* new()
    CODE:
        RETVAL = new TMenu();
    OUTPUT:
	RETVAL

MODULE=TVision::TMenu PACKAGE=TVision::TMenu
TMenu* new1(TMenuItem* itemList)
    CODE:
        RETVAL = new TMenu(* itemList);
    OUTPUT:
	RETVAL

MODULE=TVision::TMenu PACKAGE=TVision::TMenu
TMenu* new2(TMenuItem* itemList, TMenuItem* TheDefault)
    CODE:
        RETVAL = new TMenu(* itemList, * TheDefault);
    OUTPUT:
	RETVAL

MODULE=TVision::TMenuItem PACKAGE=TVision::TMenuItem
TMenuItem* new(char * aName, int aCommand, TKey aKey, int aHelpCtx=hcNoContext, char * p=0, TMenuItem *aNext=0)
    CODE:
        RETVAL = new TMenuItem( aName,  aCommand,  aKey,  aHelpCtx,  p, aNext);
    OUTPUT:
	RETVAL

MODULE=TVision::TMenuItem PACKAGE=TVision::TMenuItem
TMenuItem* new1(char * aName, TKey aKey, TMenu *aSubMenu, int aHelpCtx=hcNoContext, TMenuItem *aNext=0)
    CODE:
        RETVAL = new TMenuItem( aName,  aKey, aSubMenu,  aHelpCtx, aNext);
    OUTPUT:
	RETVAL

MODULE=TVision::TSubMenu PACKAGE=TVision::TSubMenu
TSubMenu* new(char * nm, TKey key, int helpCtx = hcNoContext)
    CODE:
        RETVAL = new TSubMenu( nm,  key,  helpCtx );
    OUTPUT:
	RETVAL

MODULE=TVision::TEditor PACKAGE=TVision::TEditor
TEditor* new(TRect r, TScrollBar *sb1=0, TScrollBar *sb2=0, TIndicator *ind=0, int n=1000)
    CODE:
        RETVAL = new TEditor( r, sb1, sb2, ind,  n);
    OUTPUT:
	RETVAL

MODULE=TVision::TWindow PACKAGE=TVision::TWindow
TWindow* new(TRect r, char *title, int num)
    CODE:
        RETVAL = new TWindow( r, title,  num);
    OUTPUT:
	RETVAL

MODULE=TVision::TView PACKAGE=TVision::TView
TView* new(TRect r)
    CODE:
        RETVAL = new TView( r);
    OUTPUT:
	RETVAL

MODULE=TVision::TDialog PACKAGE=TVision::TDialog
TDialog* new(TRect r, char *title)
    CODE:
        RETVAL = new TDialog( r, title);
    OUTPUT:
	RETVAL

MODULE=TVision::TStaticText PACKAGE=TVision::TStaticText
TStaticText* new(TRect r, char *title)
    CODE:
        RETVAL = new TStaticText( r, title);
    OUTPUT:
	RETVAL

MODULE=TVision::THistory PACKAGE=TVision::THistory
THistory* new(TRect bounds, TInputLine *aLink, int aHistoryId)
    CODE:
        RETVAL = new THistory( bounds, aLink,  aHistoryId);
    OUTPUT:
	RETVAL

MODULE=TVision::TSItem PACKAGE=TVision::TSItem
TSItem* new(char * aValue, TSItem *aNext)
    CODE:
        RETVAL = new TSItem( aValue, aNext);
    OUTPUT:
	RETVAL


MODULE=TVision::TApplication PACKAGE=TVision::TApplication
void cascade(TApplication *self)
    CODE:
        self->cascade();


void dosShell(TApplication *self)
    CODE:
        self->dosShell();


void tile(TApplication *self)
    CODE:
        self->tile();


void shutDown(TApplication *self)
    CODE:
        self->shutDown();

MODULE=TVision::TProgram PACKAGE=TVision::TProgram
void run(TProgram *self)
    CODE:
        self->run();


void idle(TProgram *self)
    CODE:
        self->idle();


void setScreenMode(TProgram *self,int mode)
    CODE:
        self->setScreenMode( mode);


TView *validView(TProgram *self,TView *p)
    CODE:
        RETVAL = self->validView(p);
    OUTPUT:
        RETVAL

MODULE=TVision::TView PACKAGE=TVision::TView
void locate(TView *self,TRect r)
    CODE:
        self->locate( r);


TRect getBounds(TView *self)
    CODE:
        RETVAL = self->getBounds();
    OUTPUT:
        RETVAL


TRect getExtent(TView *self)
    CODE:
        RETVAL = self->getExtent();
    OUTPUT:
        RETVAL


TRect getClipRect(TView *self)
    CODE:
        RETVAL = self->getClipRect();
    OUTPUT:
        RETVAL


int mouseInView(TView *self,TPoint mouse)
    CODE:
        RETVAL = self->mouseInView( mouse);
    OUTPUT:
        RETVAL


void growTo(TView *self,short x, short y)
    CODE:
        self->growTo( x,  y);


void moveTo(TView *self,short x, short y)
    CODE:
        self->moveTo( x,  y);


void setBounds(TView *self,TRect r)
    CODE:
        self->setBounds( r);


void hide(TView *self)
    CODE:
        self->hide();


void show(TView *self)
    CODE:
        self->show();


void drawView(TView *self)
    CODE:
        self->drawView();


int exposed(TView *self)
    CODE:
        RETVAL = self->exposed();
    OUTPUT:
        RETVAL


int focus(TView *self)
    CODE:
        RETVAL = self->focus();
    OUTPUT:
        RETVAL


void hideCursor(TView *self)
    CODE:
        self->hideCursor();


void drawHide(TView *self,TView *lastView)
    CODE:
        self->drawHide(lastView);


void drawShow(TView *self,TView *lastView)
    CODE:
        self->drawShow(lastView);


void drawUnderRect(TView *self,TRect r, TView *lastView)
    CODE:
        self->drawUnderRect( r, lastView);


void drawUnderView(TView *self,int doShadow, TView *lastView)
    CODE:
        self->drawUnderView( doShadow, lastView);


void blockCursor(TView *self)
    CODE:
        self->blockCursor();


void normalCursor(TView *self)
    CODE:
        self->normalCursor();


void setCursor(TView *self,int x, int y)
    CODE:
        self->setCursor( x,  y);


void showCursor(TView *self)
    CODE:
        self->showCursor();


void drawCursor(TView *self)
    CODE:
        self->drawCursor();


int eventAvail(TView *self)
    CODE:
        RETVAL = self->eventAvail();
    OUTPUT:
        RETVAL


int commandEnabled(TView *self,int command)
    CODE:
        RETVAL = self->commandEnabled( command);
    OUTPUT:
        RETVAL


void disableCommand(TView *self,int command)
    CODE:
        self->disableCommand( command);


void enableCommand(TView *self,int command)
    CODE:
        self->enableCommand( command);


int getState(TView *self,int aState)
    CODE:
        RETVAL = self->getState( aState);
    OUTPUT:
        RETVAL


void select(TView *self)
    CODE:
        self->select();


TPoint makeGlobal(TView *self,TPoint source)
    CODE:
        RETVAL = self->makeGlobal( source);
    OUTPUT:
        RETVAL


TPoint makeLocal(TView *self,TPoint source)
    CODE:
        RETVAL = self->makeLocal( source);
    OUTPUT:
        RETVAL


TView *nextView(TView *self)
    CODE:
        RETVAL = self->nextView();
    OUTPUT:
        RETVAL


TView *prevView(TView *self)
    CODE:
        RETVAL = self->prevView();
    OUTPUT:
        RETVAL


TView *prev(TView *self)
    CODE:
        RETVAL = self->prev();
    OUTPUT:
        RETVAL


void makeFirst(TView *self)
    CODE:
        self->makeFirst();


void putInFrontOf(TView *self,TView *Target)
    CODE:
        self->putInFrontOf(Target);


TView *TopView(TView *self)
    CODE:
        RETVAL = self->TopView();
    OUTPUT:
        RETVAL


int getHelpCtx(TView *self)
    CODE:
        RETVAL = self->getHelpCtx();
    OUTPUT:
        RETVAL


int valid(TView *self,int command)
    CODE:
        RETVAL = self->valid( command);
    OUTPUT:
        RETVAL


void draw(TView *self)
    CODE:
        self->draw();


int dataSize(TView *self)
    CODE:
        RETVAL = self->dataSize();
    OUTPUT:
        RETVAL


void getData(TView *self,void *rec)
    CODE:
        self->getData(rec);


void setData(TView *self,void *rec)
    CODE:
        self->setData(rec);


void awaken(TView *self)
    CODE:
        self->awaken();


void resetCursor(TView *self)
    CODE:
        self->resetCursor();


void endModal(TView *self,int command)
    CODE:
        self->endModal( command);


int execute(TView *self)
    CODE:
        RETVAL = self->execute();
    OUTPUT:
        RETVAL


void setState(TView *self,int aState, int enable)
    CODE:
        self->setState( aState,  enable);

MODULE=TVision::TScrollBar PACKAGE=TVision::TScrollBar
void setParams(TScrollBar *self,int aValue, int aMin, int aMax, int aPgStep, int aArStep)
    CODE:
        self->setParams( aValue,  aMin,  aMax,  aPgStep,  aArStep);


void setRange(TScrollBar *self,int aMin, int aMax)
    CODE:
        self->setRange( aMin,  aMax);


void setStep(TScrollBar *self,int aPgStep, int aArStep)
    CODE:
        self->setStep( aPgStep,  aArStep);


void setValue(TScrollBar *self,int aValue)
    CODE:
        self->setValue( aValue);


void drawPos(TScrollBar *self,int pos)
    CODE:
        self->drawPos( pos);


int getPos(TScrollBar *self)
    CODE:
        RETVAL = self->getPos();
    OUTPUT:
        RETVAL


int getSize(TScrollBar *self)
    CODE:
        RETVAL = self->getSize();
    OUTPUT:
        RETVAL

MODULE=TVision::TScroller PACKAGE=TVision::TScroller
void scrollTo(TScroller *self,int x, int y)
    CODE:
        self->scrollTo( x,  y);


void setLimit(TScroller *self,int x, int y)
    CODE:
        self->setLimit( x,  y);


void checkDraw(TScroller *self)
    CODE:
        self->checkDraw();

MODULE=TVision::TWindow PACKAGE=TVision::TWindow
TFrame *initFrame(TWindow *self,TRect r)
    CODE:
        RETVAL = self->initFrame( r);
    OUTPUT:
        RETVAL


TScrollBar *standardScrollBar(TWindow *self,int aOptions)
    CODE:
        RETVAL = self->standardScrollBar( aOptions);
    OUTPUT:
        RETVAL


void zoom(TWindow *self)
    CODE:
        self->zoom();


void shutDown(TWindow *self)
    CODE:
        self->shutDown();

MODULE=TVision::TEditor PACKAGE=TVision::TEditor
char bufChar(TEditor *self,int a)
    CODE:
        RETVAL = self->bufChar( a);
    OUTPUT:
        RETVAL


int bufPtr(TEditor *self,int a)
    CODE:
        RETVAL = self->bufPtr( a);
    OUTPUT:
        RETVAL


int cursorVisible(TEditor *self)
    CODE:
        RETVAL = self->cursorVisible();
    OUTPUT:
        RETVAL


void deleteSelect(TEditor *self)
    CODE:
        self->deleteSelect();


int insertMultilineText(TEditor *self,char *a, int b)
    CODE:
        RETVAL = self->insertMultilineText(a,  b);
    OUTPUT:
        RETVAL


int insertEOL(TEditor *self,int Boolean)
    CODE:
        RETVAL = self->insertEOL( Boolean);
    OUTPUT:
        RETVAL


void scrollTo(TEditor *self,int x, int y)
    CODE:
        self->scrollTo( x,  y);


void setCmdState(TEditor *self,int ushort, int Boolean)
    CODE:
        self->setCmdState( ushort,  Boolean);


void setSelect(TEditor *self,int a, int b, int Boolean)
    CODE:
        self->setSelect( a,  b,  Boolean);


void trackCursor(TEditor *self,int Boolean)
    CODE:
        self->trackCursor( Boolean);


void undo(TEditor *self)
    CODE:
        self->undo();


int charPos(TEditor *self,int uint1, int uint2)
    CODE:
        RETVAL = self->charPos( uint1,  uint2);
    OUTPUT:
        RETVAL


int charPtr(TEditor *self,int uint1, int a)
    CODE:
        RETVAL = self->charPtr( uint1,  a);
    OUTPUT:
        RETVAL


int clipCopy(TEditor *self)
    CODE:
        RETVAL = self->clipCopy();
    OUTPUT:
        RETVAL


void clipCut(TEditor *self)
    CODE:
        self->clipCut();


void clipPaste(TEditor *self)
    CODE:
        self->clipPaste();


void deleteRange(TEditor *self,int uint1, int uint2, int Boolean)
    CODE:
        self->deleteRange( uint1,  uint2,  Boolean);


void doUpdate(TEditor *self)
    CODE:
        self->doUpdate();


void doSearchReplace(TEditor *self)
    CODE:
        self->doSearchReplace();


void drawLines(TEditor *self,int a, int b, int uint)
    CODE:
        self->drawLines( a,  b,  uint);


void find(TEditor *self)
    CODE:
        self->find();


unsigned int getMousePtr(TEditor *self,TPoint p)
    CODE:
        RETVAL = self->getMousePtr( p);
    OUTPUT:
        RETVAL


int hasSelection(TEditor *self)
    CODE:
        RETVAL = self->hasSelection();
    OUTPUT:
        RETVAL


void hideSelect(TEditor *self)
    CODE:
        self->hideSelect();


int isClipboard(TEditor *self)
    CODE:
        RETVAL = self->isClipboard();
    OUTPUT:
        RETVAL


int lineEnd(TEditor *self,int uint)
    CODE:
        RETVAL = self->lineEnd( uint);
    OUTPUT:
        RETVAL


int lineMove(TEditor *self,int uint, int i)
    CODE:
        RETVAL = self->lineMove( uint,  i);
    OUTPUT:
        RETVAL


int lineStart(TEditor *self,int uint)
    CODE:
        RETVAL = self->lineStart( uint);
    OUTPUT:
        RETVAL


int indentedLineStart(TEditor *self,int uint)
    CODE:
        RETVAL = self->indentedLineStart( uint);
    OUTPUT:
        RETVAL


void lock(TEditor *self)
    CODE:
        self->lock();


void newLine(TEditor *self)
    CODE:
        self->newLine();


int nextChar(TEditor *self,int uint)
    CODE:
        RETVAL = self->nextChar( uint);
    OUTPUT:
        RETVAL


int nextLine(TEditor *self,int uint)
    CODE:
        RETVAL = self->nextLine( uint);
    OUTPUT:
        RETVAL


int nextWord(TEditor *self,int uint)
    CODE:
        RETVAL = self->nextWord( uint);
    OUTPUT:
        RETVAL


int prevChar(TEditor *self,int uint)
    CODE:
        RETVAL = self->prevChar( uint);
    OUTPUT:
        RETVAL


int prevLine(TEditor *self,int uint)
    CODE:
        RETVAL = self->prevLine( uint);
    OUTPUT:
        RETVAL


int prevWord(TEditor *self,int uint)
    CODE:
        RETVAL = self->prevWord( uint);
    OUTPUT:
        RETVAL


void replace(TEditor *self)
    CODE:
        self->replace();


void setBufLen(TEditor *self,int uint)
    CODE:
        self->setBufLen( uint);


void setCurPtr(TEditor *self,int uint, int uchar)
    CODE:
        self->setCurPtr( uint,  uchar);


void startSelect(TEditor *self)
    CODE:
        self->startSelect();


void toggleEncoding(TEditor *self)
    CODE:
        self->toggleEncoding();


void toggleInsMode(TEditor *self)
    CODE:
        self->toggleInsMode();


void unlock(TEditor *self)
    CODE:
        self->unlock();


void update(TEditor *self,int uchar)
    CODE:
        self->update( uchar);


void detectEol(TEditor *self)
    CODE:
        self->detectEol();

MODULE=TVision::TMenuItem PACKAGE=TVision::TMenuItem
void append(TMenuItem *self,TMenuItem *aNext)
    CODE:
        self->append(aNext);

MODULE=TVision::TGroup PACKAGE=TVision::TGroup
void insert(TGroup *self,TWindow *what)
    CODE:
        self->insert(what);


void insertView(TGroup *self,TView *p, TView *Target)
    CODE:
        self->insertView(p, Target);


void remove(TGroup *self,TView *p)
    CODE:
        self->remove(p);


void removeView(TGroup *self,TView *p)
    CODE:
        self->removeView(p);


void resetCurrent(TGroup *self)
    CODE:
        self->resetCurrent();


void selectNext(TGroup *self,int forwards)
    CODE:
        self->selectNext( forwards);


void redraw(TGroup *self)
    CODE:
        self->redraw();

MODULE=TVision::TInputLine PACKAGE=TVision::TInputLine
void setData(TInputLine *self,char *data)
    CODE:
        self->setData(data);

MODULE=TVision::TButton PACKAGE=TVision::TButton
void setTitle(TButton *self,char *title)
    CODE:
        delete self->title; self->title = new char[strlen(title)+1]; strcpy((char*)self->title,title); self->draw();


MODULE=TVision::TEditor PACKAGE=TVision::TEditor
TScrollBar* get_hScrollBar(TEditor *self)
    CODE:
        RETVAL = self->hScrollBar;
    OUTPUT:
        RETVAL

void set_hScrollBar(TEditor *self, TScrollBar* val)
    CODE:
        self->hScrollBar = val;


TScrollBar* get_vScrollBar(TEditor *self)
    CODE:
        RETVAL = self->vScrollBar;
    OUTPUT:
        RETVAL

void set_vScrollBar(TEditor *self, TScrollBar* val)
    CODE:
        self->vScrollBar = val;


TIndicator* get_indicator(TEditor *self)
    CODE:
        RETVAL = self->indicator;
    OUTPUT:
        RETVAL

void set_indicator(TEditor *self, TIndicator* val)
    CODE:
        self->indicator = val;


int get_bufSize(TEditor *self)
    CODE:
        RETVAL = self->bufSize;
    OUTPUT:
        RETVAL

void set_bufSize(TEditor *self, int val)
    CODE:
        self->bufSize = val;


int get_bufLen(TEditor *self)
    CODE:
        RETVAL = self->bufLen;
    OUTPUT:
        RETVAL

void set_bufLen(TEditor *self, int val)
    CODE:
        self->bufLen = val;


int get_gapLen(TEditor *self)
    CODE:
        RETVAL = self->gapLen;
    OUTPUT:
        RETVAL

void set_gapLen(TEditor *self, int val)
    CODE:
        self->gapLen = val;


int get_selStart(TEditor *self)
    CODE:
        RETVAL = self->selStart;
    OUTPUT:
        RETVAL

void set_selStart(TEditor *self, int val)
    CODE:
        self->selStart = val;


int get_selEnd(TEditor *self)
    CODE:
        RETVAL = self->selEnd;
    OUTPUT:
        RETVAL

void set_selEnd(TEditor *self, int val)
    CODE:
        self->selEnd = val;


int get_curPtr(TEditor *self)
    CODE:
        RETVAL = self->curPtr;
    OUTPUT:
        RETVAL

void set_curPtr(TEditor *self, int val)
    CODE:
        self->curPtr = val;


TPoint get_curPos(TEditor *self)
    CODE:
        RETVAL = self->curPos;
    OUTPUT:
        RETVAL

void set_curPos(TEditor *self, TPoint val)
    CODE:
        self->curPos = val;


TPoint get_delta(TEditor *self)
    CODE:
        RETVAL = self->delta;
    OUTPUT:
        RETVAL

void set_delta(TEditor *self, TPoint val)
    CODE:
        self->delta = val;


TPoint get_limit(TEditor *self)
    CODE:
        RETVAL = self->limit;
    OUTPUT:
        RETVAL

void set_limit(TEditor *self, TPoint val)
    CODE:
        self->limit = val;


int get_drawLine(TEditor *self)
    CODE:
        RETVAL = self->drawLine;
    OUTPUT:
        RETVAL

void set_drawLine(TEditor *self, int val)
    CODE:
        self->drawLine = val;


int get_drawPtr(TEditor *self)
    CODE:
        RETVAL = self->drawPtr;
    OUTPUT:
        RETVAL

void set_drawPtr(TEditor *self, int val)
    CODE:
        self->drawPtr = val;


int get_delCount(TEditor *self)
    CODE:
        RETVAL = self->delCount;
    OUTPUT:
        RETVAL

void set_delCount(TEditor *self, int val)
    CODE:
        self->delCount = val;


int get_insCount(TEditor *self)
    CODE:
        RETVAL = self->insCount;
    OUTPUT:
        RETVAL

void set_insCount(TEditor *self, int val)
    CODE:
        self->insCount = val;


int get_isValid(TEditor *self)
    CODE:
        RETVAL = self->isValid;
    OUTPUT:
        RETVAL

void set_isValid(TEditor *self, int val)
    CODE:
        self->isValid = val;


int get_canUndo(TEditor *self)
    CODE:
        RETVAL = self->canUndo;
    OUTPUT:
        RETVAL

void set_canUndo(TEditor *self, int val)
    CODE:
        self->canUndo = val;


int get_modified(TEditor *self)
    CODE:
        RETVAL = self->modified;
    OUTPUT:
        RETVAL

void set_modified(TEditor *self, int val)
    CODE:
        self->modified = val;


int get_selecting(TEditor *self)
    CODE:
        RETVAL = self->selecting;
    OUTPUT:
        RETVAL

void set_selecting(TEditor *self, int val)
    CODE:
        self->selecting = val;


int get_overwrite(TEditor *self)
    CODE:
        RETVAL = self->overwrite;
    OUTPUT:
        RETVAL

void set_overwrite(TEditor *self, int val)
    CODE:
        self->overwrite = val;


int get_autoIndent(TEditor *self)
    CODE:
        RETVAL = self->autoIndent;
    OUTPUT:
        RETVAL

void set_autoIndent(TEditor *self, int val)
    CODE:
        self->autoIndent = val;


int get_lockCount(TEditor *self)
    CODE:
        RETVAL = self->lockCount;
    OUTPUT:
        RETVAL

void set_lockCount(TEditor *self, int val)
    CODE:
        self->lockCount = val;


int get_updateFlags(TEditor *self)
    CODE:
        RETVAL = self->updateFlags;
    OUTPUT:
        RETVAL

void set_updateFlags(TEditor *self, int val)
    CODE:
        self->updateFlags = val;


int get_keyState(TEditor *self)
    CODE:
        RETVAL = self->keyState;
    OUTPUT:
        RETVAL

void set_keyState(TEditor *self, int val)
    CODE:
        self->keyState = val;

MODULE=TVision::TWindow PACKAGE=TVision::TWindow
int get_flags(TWindow *self)
    CODE:
        RETVAL = self->flags;
    OUTPUT:
        RETVAL

void set_flags(TWindow *self, int val)
    CODE:
        self->flags = val;


TRect get_zoomRect(TWindow *self)
    CODE:
        RETVAL = self->zoomRect;
    OUTPUT:
        RETVAL

void set_zoomRect(TWindow *self, TRect val)
    CODE:
        self->zoomRect = val;


int get_number(TWindow *self)
    CODE:
        RETVAL = self->number;
    OUTPUT:
        RETVAL

void set_number(TWindow *self, int val)
    CODE:
        self->number = val;


int get_palette(TWindow *self)
    CODE:
        RETVAL = self->palette;
    OUTPUT:
        RETVAL

void set_palette(TWindow *self, int val)
    CODE:
        self->palette = val;


TFrame* get_frame(TWindow *self)
    CODE:
        RETVAL = self->frame;
    OUTPUT:
        RETVAL

void set_frame(TWindow *self, TFrame* val)
    CODE:
        self->frame = val;

MODULE=TVision::TView PACKAGE=TVision::TView
TView* get_next(TView *self)
    CODE:
        RETVAL = self->next;
    OUTPUT:
        RETVAL

void set_next(TView *self, TView* val)
    CODE:
        self->next = val;


TPoint get_size(TView *self)
    CODE:
        RETVAL = self->size;
    OUTPUT:
        RETVAL

void set_size(TView *self, TPoint val)
    CODE:
        self->size = val;


int get_options(TView *self)
    CODE:
        RETVAL = self->options;
    OUTPUT:
        RETVAL

void set_options(TView *self, int val)
    CODE:
        self->options = val;


int get_eventMask(TView *self)
    CODE:
        RETVAL = self->eventMask;
    OUTPUT:
        RETVAL

void set_eventMask(TView *self, int val)
    CODE:
        self->eventMask = val;


int get_state(TView *self)
    CODE:
        RETVAL = self->state;
    OUTPUT:
        RETVAL

void set_state(TView *self, int val)
    CODE:
        self->state = val;


TPoint get_origin(TView *self)
    CODE:
        RETVAL = self->origin;
    OUTPUT:
        RETVAL

void set_origin(TView *self, TPoint val)
    CODE:
        self->origin = val;


TPoint get_cursor(TView *self)
    CODE:
        RETVAL = self->cursor;
    OUTPUT:
        RETVAL

void set_cursor(TView *self, TPoint val)
    CODE:
        self->cursor = val;


int get_growMode(TView *self)
    CODE:
        RETVAL = self->growMode;
    OUTPUT:
        RETVAL

void set_growMode(TView *self, int val)
    CODE:
        self->growMode = val;


int get_dragMode(TView *self)
    CODE:
        RETVAL = self->dragMode;
    OUTPUT:
        RETVAL

void set_dragMode(TView *self, int val)
    CODE:
        self->dragMode = val;


int get_helpCtx(TView *self)
    CODE:
        RETVAL = self->helpCtx;
    OUTPUT:
        RETVAL

void set_helpCtx(TView *self, int val)
    CODE:
        self->helpCtx = val;


int get_commandSetChanged(TView *self)
    CODE:
        RETVAL = self->commandSetChanged;
    OUTPUT:
        RETVAL

void set_commandSetChanged(TView *self, int val)
    CODE:
        self->commandSetChanged = val;


TGroup* get_owner(TView *self)
    CODE:
        RETVAL = self->owner;
    OUTPUT:
        RETVAL

void set_owner(TView *self, TGroup* val)
    CODE:
        self->owner = val;


int get_showMarkers(TView *self)
    CODE:
        RETVAL = self->showMarkers;
    OUTPUT:
        RETVAL

void set_showMarkers(TView *self, int val)
    CODE:
        self->showMarkers = val;


int get_errorAttr(TView *self)
    CODE:
        RETVAL = self->errorAttr;
    OUTPUT:
        RETVAL

void set_errorAttr(TView *self, int val)
    CODE:
        self->errorAttr = val;

MODULE=TVision::TScrollBar PACKAGE=TVision::TScrollBar
int get_value(TScrollBar *self)
    CODE:
        RETVAL = self->value;
    OUTPUT:
        RETVAL

void set_value(TScrollBar *self, int val)
    CODE:
        self->value = val;


int get_minVal(TScrollBar *self)
    CODE:
        RETVAL = self->minVal;
    OUTPUT:
        RETVAL

void set_minVal(TScrollBar *self, int val)
    CODE:
        self->minVal = val;


int get_maxVal(TScrollBar *self)
    CODE:
        RETVAL = self->maxVal;
    OUTPUT:
        RETVAL

void set_maxVal(TScrollBar *self, int val)
    CODE:
        self->maxVal = val;


int get_pgStep(TScrollBar *self)
    CODE:
        RETVAL = self->pgStep;
    OUTPUT:
        RETVAL

void set_pgStep(TScrollBar *self, int val)
    CODE:
        self->pgStep = val;


int get_arStep(TScrollBar *self)
    CODE:
        RETVAL = self->arStep;
    OUTPUT:
        RETVAL

void set_arStep(TScrollBar *self, int val)
    CODE:
        self->arStep = val;

MODULE=TVision::TScroller PACKAGE=TVision::TScroller
TPoint get_delta(TScroller *self)
    CODE:
        RETVAL = self->delta;
    OUTPUT:
        RETVAL

void set_delta(TScroller *self, TPoint val)
    CODE:
        self->delta = val;

MODULE=TVision::TProgram PACKAGE=TVision::TProgram
TProgram* get_application(TProgram *self)
    CODE:
        RETVAL = self->application;
    OUTPUT:
        RETVAL

void set_application(TProgram *self, TProgram* val)
    CODE:
        self->application = val;


TStatusLine* get_statusLine(TProgram *self)
    CODE:
        RETVAL = self->statusLine;
    OUTPUT:
        RETVAL

void set_statusLine(TProgram *self, TStatusLine* val)
    CODE:
        self->statusLine = val;


TMenuBar* get_menuBar(TProgram *self)
    CODE:
        RETVAL = self->menuBar;
    OUTPUT:
        RETVAL

void set_menuBar(TProgram *self, TMenuBar* val)
    CODE:
        self->menuBar = val;


TDeskTop* get_deskTop(TProgram *self)
    CODE:
        RETVAL = self->deskTop;
    OUTPUT:
        RETVAL

void set_deskTop(TProgram *self, TDeskTop* val)
    CODE:
        self->deskTop = val;


int get_appPalette(TProgram *self)
    CODE:
        RETVAL = self->appPalette;
    OUTPUT:
        RETVAL

void set_appPalette(TProgram *self, int val)
    CODE:
        self->appPalette = val;


int get_eventTimeoutMs(TProgram *self)
    CODE:
        RETVAL = self->eventTimeoutMs;
    OUTPUT:
        RETVAL

void set_eventTimeoutMs(TProgram *self, int val)
    CODE:
        self->eventTimeoutMs = val;

MODULE=TVision::TMenuItem PACKAGE=TVision::TMenuItem
TMenuItem* get_next(TMenuItem *self)
    CODE:
        RETVAL = self->next;
    OUTPUT:
        RETVAL

void set_next(TMenuItem *self, TMenuItem* val)
    CODE:
        self->next = val;


int get_command(TMenuItem *self)
    CODE:
        RETVAL = self->command;
    OUTPUT:
        RETVAL

void set_command(TMenuItem *self, int val)
    CODE:
        self->command = val;


int get_disabled(TMenuItem *self)
    CODE:
        RETVAL = self->disabled;
    OUTPUT:
        RETVAL

void set_disabled(TMenuItem *self, int val)
    CODE:
        self->disabled = val;


TKey get_keyCode(TMenuItem *self)
    CODE:
        RETVAL = self->keyCode;
    OUTPUT:
        RETVAL

void set_keyCode(TMenuItem *self, TKey val)
    CODE:
        self->keyCode = val;


int get_helpCtx(TMenuItem *self)
    CODE:
        RETVAL = self->helpCtx;
    OUTPUT:
        RETVAL

void set_helpCtx(TMenuItem *self, int val)
    CODE:
        self->helpCtx = val;



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

MODULE=TVision::TInputLine PACKAGE=TVision::TInputLine

char *getData(TInputLine *til)
    CODE:
	char data[2048]; // OMG2
	til->getData(data);
	RETVAL=data;
    OUTPUT:
	RETVAL

MODULE=TVision::TCheckBoxes PACKAGE=TVision::TCheckBoxes

TCheckBoxes* new(TRect r,  AV *_items)
    CODE:
        int cnt = av_count(_items);
	//printf("items=%d\n",cnt);
        TSItem *tsit = 0;
	for (int i=cnt-1; i>=0; i--) {
	    SV **sv = av_fetch(_items, i, 0);
	    //printf("i=%d s=%s\n", i, SvPV_nolen(*sv));
	    TSItem *n = new TSItem(SvPV_nolen(*sv), tsit);
	    tsit = n;
	}
        RETVAL = new TCheckBoxes(r, tsit);
    OUTPUT:
	RETVAL

MODULE=TVision::TRadioButtons PACKAGE=TVision::TRadioButtons

TRadioButtons* new(TRect r, AV *_items)
    CODE:
        int cnt = av_count(_items);
	//printf("items=%d\n",cnt);
        TSItem *tsit = 0;
	for (int i=cnt-1; i>=0; i--) {
	    SV **sv = av_fetch(_items, i, 0);
	    //printf("i=%d s=%s\n", i, SvPV_nolen(*sv));
	    TSItem *n = new TSItem(SvPV_nolen(*sv), tsit);
	    tsit = n;
	}
        RETVAL = new TRadioButtons(r, tsit);
    OUTPUT:
	RETVAL

MODULE=TVision::TEditor PACKAGE=TVision::TEditor

TEditor* new_obsoleted(int _ax, int ay, int bx, int by, TScrollBar *sb1, TScrollBar *sb2, TIndicator *ind, int n)
    CODE:
	if (sb1==NULL){printf("ok got NULL\n");}
        RETVAL = new TEditor(TRect(_ax,ay,bx,by),sb1,sb2,ind, n);
    OUTPUT:
	RETVAL

MODULE=TVision::TDeskTop PACKAGE=TVision::TDeskTop

void insert_obsoleted(SV *self, SV *what)
    CODE:
	TDeskTop* td = sv2tv_s(self,TDeskTop);
        SV *sv = SvRV(what);
        TWindow* w = *((TWindow**) SvPV_nolen(sv));
	td->insert(w);

MODULE=TVision_more PACKAGE=TVision

