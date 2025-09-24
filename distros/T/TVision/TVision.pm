package TVision;
our $VERSION="0.28";

use strict;

=encoding utf-8
=head1 NAME

TVision - Perl glue to the TurboVision library

=head1 SYNOPSIS

    use TVision;

    my $tapp = tnew 'TVApp';
    my $w = tnew 'TWindow', [1,1,120,15], 'моё окно, товарищи',5;
    my $b = tnew 'TButton', [1,1,30,3], 'кнопка', 125, 0;
    my $checkboxes = tnew 'TCheckBoxes', [3,3,81,9], ['a'..'s'];
    my $e = tnew TInputLine => ([3,11,81,13],100);
    $tapp->deskTop->insert($w);
    $w->insert($_) for ($checkboxes, $e, $b);
    $e->focus();
    $tapp->run;

=head1 DESCRIPTION

The TVision package is a perl glue to the TurboVision library
github.com/magiblot/tvision.

TVision namespace contains subpakages of 2 types:
* turbovision widgets (or 'controls') such as TButton, etc.
* and also some helper packages.

All the TVision::xxxx widgets are array refs, where first item at index 0
holds address of the underlying C++ object, 2nd ($obj->[1]) generated widget name,
3rd - its path.
4rd item - left to user, any scalar could be stored there, please see the methods
store_user_value/retrieve_user_value for this.

Some widgets (TButton) has 'num' key, which is usually small integer for the
onCommand event. If 0 - then next availlable is taken.

TRect is array ref of 4 integers, which isn't always blessed to TVision::TRect.
TPoint is array ref of 2 integers, which isn't always blessed to TVision::TPoint.
TKey is array ref of 2 integers or just integer.

=head1 Following classes and members are mapped to the underlying c++ TurboVision library:

=head2 Mapping of following constructors are implemented:

    TBackground(TRect r, char aPattern)
    TDeskTop(TRect r)
    TScroller(TRect r, TScrollBar *aHScrollBar, TScrollBar *aVScrollBar)
    TLabel(TRect r, TStringView aText, TView *aLink )
    TButton(TRect r, char *title, int cmd, int flags)
    TScrollBar(TRect r)
    TIndicator(TRect r)
    TInputLine(TRect r, int limit)
    TMenuBar(TRect r, TSubMenu* &aMenu)
    TMenuBar1(TRect r, TMenu *aMenu)
    TMenu()
    TMenu1( TMenuItem*& itemList )
    TMenu2( TMenuItem*& itemList, TMenuItem*& TheDefault)
    TMenuItem(TStringView aName, int aCommand, TKey aKey, int aHelpCtx=hcNoContext, TStringView p=0, TMenuItem *aNext=0)
    TMenuItem1(TStringView aName, TKey aKey, TMenu *aSubMenu, int aHelpCtx=hcNoContext, TMenuItem *aNext=0)
    TSubMenu( TStringView nm, TKey key, int helpCtx = hcNoContext )
    TEditor(TRect r, TScrollBar *sb1=0, TScrollBar *sb2=0, TIndicator *ind=0, int n=1000)
    TEditWindow(TRect r, char *title, int num)
    TWindow(TRect r, char *title, int num)
    TView(TRect r)
    TDialog(TRect r, char *title)
    TStaticText(TRect r, char *title)
    THistory( TRect bounds, TInputLine *aLink, int aHistoryId )
    TSItem( TStringView aValue, TSItem *aNext )

=head2 Mapping of following methods are implemented:

    TApplication:
	void cascade()
	void dosShell()
	void tile()
	void shutDown()
    TProgram:
	void run()
	void idle()
	void setScreenMode(int mode)
	TView *validView(TView *p)
    TView:
	void locate(TRect r)
	TRect getBounds()
	TRect getExtent()
	TRect getClipRect()
	int mouseInView( TPoint mouse )
	void growTo( short x, short y )
	void moveTo( short x, short y )
	void setBounds(TRect r)
	void hide()
	void show()
	void drawView()
	int exposed()
	int focus()
	void hideCursor()
	void drawHide( TView *lastView )
	void drawShow( TView *lastView )
	void drawUnderRect(TRect r, TView *lastView ) self->drawUnderRect( r, lastView);
	void drawUnderView( int doShadow, TView *lastView )
	void blockCursor()
	void normalCursor()
	void setCursor( int x, int y )
	void showCursor()
	void drawCursor()
	int eventAvail()
	int commandEnabled( int command )
	void disableCommand( int command )
	void enableCommand( int command )
	int getState( int aState )
	void select()
	TPoint makeGlobal( TPoint source )
	TPoint makeLocal( TPoint source )
	TView *nextView()
	TView *prevView()
	TView *prev()
	void makeFirst()
	void putInFrontOf( TView *Target )
	TView *TopView()
	int getHelpCtx()
	int valid( int command )
	void draw()
	int dataSize()
	void getData( void *rec )
	void setData( void *rec )
	void awaken()
	void resetCursor()
	void endModal( int command )
	int execute()
	void setState( int aState, int enable )
    TScrollBar:
	void setParams( int aValue, int aMin, int aMax, int aPgStep, int aArStep )
	void setRange( int aMin, int aMax )
	void setStep( int aPgStep, int aArStep )
	void setValue( int aValue )
	void drawPos( int pos )
	int getPos()
	int getSize()
    TScroller:
        void scrollTo( int x, int y )
        void setLimit( int x, int y )
        void checkDraw()
    TWindow:
        TFrame *initFrame( TRect r)
	TScrollBar *standardScrollBar( int aOptions )
	void zoom()
	void shutDown()
    TEditor:
	char bufChar( int a)
	int bufPtr( int a)
	int cursorVisible()
	void deleteSelect()
	int insertMultilineText( char *a, int b)
	int insertBuffer( char *c, int uint1, int uint2, int Boolean1, int Boolean2 )
	int insertEOL( int Boolean )
	int insertText( char *cv, int uint, int Boolean )
	void scrollTo( int x, int y)
	int search(char *c, int ushort )
	void setCmdState( int ushort, int Boolean )
	void setSelect( int a, int b, int Boolean)
	void trackCursor( int Boolean )
	void undo()
	int charPos( int uint1, int uint2 )
	int charPtr( int uint1, int a)
	int clipCopy()
	void clipCut()
	void clipPaste()
	void deleteRange( int uint1, int uint2, int Boolean )
	void doUpdate()
	void doSearchReplace()
	void drawLines( int a, int b, int uint )
	void find()
	unsigned_int getMousePtr( TPoint p)
	int hasSelection()
	void hideSelect()
	int isClipboard()
	int lineEnd( int uint )
	int lineMove( int uint, int i)
	int lineStart( int uint )
	int indentedLineStart( int uint )
	void lock()
	void newLine()
	int nextChar( int uint )
	int nextLine( int uint )
	int nextWord( int uint )
	int prevChar( int uint )
	int prevLine( int uint )
	int prevWord( int uint )
	void replace()
	void setBufLen( int uint )
	void setCurPtr( int uint, int uchar )
	void startSelect()
	void toggleEncoding()
	void toggleInsMode()
	void unlock()
	void update( int uchar )
	void detectEol()
    TMenuItem:
        void append(TMenuItem *aNext)
    TGroup:
        void xinsert(TWindow *what) self->insert(what);
	void insertView(TView *p, TView *Target)
        void remove( TView *p )
        void removeView( TView *p )
        void resetCurrent()
        void selectNext( int forwards )
        void redraw()
    TInputLine:
        void setData(char *data)
    TButton:
        void setTitle(char *title) delete self->title; self->title = new char[strlen(title)+1]; strcpy((char*)self->title,title); self->draw();

=head2 Mapping of following public class members are implemented:

    TEditor:
	TScrollBar *hScrollBar
	TScrollBar *vScrollBar
	TIndicator *indicator
	char *buffer
	int bufSize
	int bufLen
	int gapLen
	int selStart
	int selEnd
	int curPtr
	TPoint curPos
	TPoint delta
	TPoint limit
	int drawLine
	int drawPtr
	int delCount
	int insCount
	int isValid
	int canUndo
	int modified
	int selecting
	int overwrite
	int autoIndent
	int lockCount
	int updateFlags
	int keyState
    TEditWindow:
	TFileEditor *editor
    TWindow:
	int flags
	TRect zoomRect
	int number
	int palette
	TFrame *frame
    TView:
	TView *next
        TPoint size
        int options
        int eventMask
        int state
        TPoint origin
        TPoint cursor
        int growMode
        int dragMode
        int helpCtx
        int commandSetChanged
        TGroup *owner
        int showMarkers
        int errorAttr
    TScrollBar:
        int value
        int minVal
        int maxVal
        int pgStep
        int arStep
    TScroller:
        TPoint delta
    TProgram:
	TProgram *application
	TStatusLine *statusLine
	TMenuBar *menuBar
	TDeskTop *deskTop
	int appPalette
	int eventTimeoutMs
    TMenuItem:
	TMenuItem *next
	int command
	int disabled
	TKey keyCode
	int helpCtx

Getters and setters are named get_xxxx and set_xxxx respectively.

=head1 Functions

Most TVision functions are mapped into perl.

    $str = TVision::messageBox($str, $options);
    $str = TVision::messageBoxRect([$x0,$y0,$x1,$y1],$str, $options);
    $str = TVision::inputBox($title, $label, $default="", $imit=1000);
    $str = TVision::inputBoxRect([$x0,$y0,$x1,$y1],$title, $label, $default="", $imit=1000);
    TVision::spin_loop();

=head1 TVision::TApplication::onCommand($coderef) function

Registers callback for a function to be invoked in TApplication event loop. This function
takes 2 integers as its arguments - command ID and any user data.  Example:

    $tvapp->onCommand(sub {
        my ($cmd, $arg) = @_;
        if ($cmd == 123) { # e.g. - button pressed
            # do something on button press
        }
        elsif ($cmd == 125) {
            ...
        }
    });

Pass undef or 0 to reset such callback.

=head1 TVision::TApplication::on_idle($coderef) function

Registers callback for a function to be invoked after TProgram::idle().

Pass undef or 0 to reset such callback.

=head1 Geometry managers (not ready yet, pleae ignore this entire section)

Geometry manager tkpack stolen/hijacked from tcl/tk. In order for it to function
properly, each widget gets its name ("path")
TDesktop is '.', frame on it is .f, buttin on it could be named as .f.btn2, etc.
Ideally widget's name is either specified by user, or generated on the fly at
creation time.
However we don't know who is widget's parent until it is "inserted" by the
...->insert method.

We hold widget's path in widget object, which is array ref, at item 2.

Mapping of widget names to correspoiding objects is held in %TVision::names,
widget paths in %TVision::paths.

=cut

require DynaLoader;
require Exporter;
our @ISA = qw(Exporter DynaLoader);
__PACKAGE__->bootstrap;


my %widget_names_cnt;
sub tnew($@) {
    my $class = shift;
    my $sub = \&{"TVision::$class\::new"};
    my $w = $sub->(@_);
    $w->[1] = lc($class) . ++$widget_names_cnt{$class};
    $TVision::names{$w->[1]} = $w;
    return $w;
}

sub TRect {
    return [@_]; # could bless to proper package, but right now there is no actual need for that,
}

sub TPoint {
    ...;
    return [@_];
}

sub TVision::TObject::store_user_value {
    my $self = shift;
    $self->[4] = shift;
}
sub TVision::TObject::retrieve_user_value {
    my $self = shift;
    return $self->[4];
}

sub TVision::TGroup::insert($@) {
    my ($self, $obj) = @_;
    $self->xinsert($obj);
    $obj->[2] = ($self->[2] eq '.' ? '' : $self->[2]) . ".$obj->[1]";
    print "{$obj->[2]}";
    $TVision::paths{$obj->[2]} = $self;
}

package TVision::WidgetWithOnCommand;
# this isn't on classical turbovision, this package is the central place
# for widgets with onCommand capability

my %all_oncommands;
sub onCommand {
    my $self = shift;
    my $cb = shift; # now this should be CODE ref; could be sub name in future
    my $cmd_num = $self->num;
    if (exists $all_oncommands{$cmd_num}) {
	warn "duplicating onCommand item $cmd_num";
    }
    $all_oncommands{$cmd_num} = $cb;
}

package TVision::TVApp;
our @ISA = qw(TVision::TApplication);

package TVision::TApplication;
our @ISA = qw(TVision::TProgram);
#class TApplication : public virtual TSubsystemsInit, public TProgram {
#protected:
#    TApplication() noexcept;
#    virtual ~TApplication();
#public:
#    virtual void suspend();
#    virtual void resume();
#    void cascade();
#    void dosShell();
#    virtual TRect getTileRect();
#    virtual void handleEvent(TEvent &event);
#    void tile();
#    virtual void writeShellMsg();
#};

our $the_tapp;

sub init {
    $the_tapp->onCommand($TVision::TApplication::onCommand = sub {
	my ($cmd, $arg) = @_;
	if (exists $all_oncommands{$cmd}) {
	    $all_oncommands{$cmd}->(@_);
	} else {
	    print "command[@_] - not ours?\n";
	}
    });
}

package TVision::TProgInit;
#class TProgInit {
#public:
#    TProgInit(TStatusLine *(*cStatusLine)(TRect), TMenuBar *(*cMenuBar)(TRect), TDeskTop *(*cDeskTop )(TRect))
#protected:
#    TStatusLine *(*createStatusLine)( TRect );
#    TMenuBar *(*createMenuBar)( TRect );
#    TDeskTop *(*createDeskTop)( TRect );
#};

package TVision::TProgram;
our @ISA = qw(TVision::TGroup TVision::TProgInit);
#class TProgram : public TGroup, public virtual TProgInit {
#public:
#    TProgram() noexcept;
#    virtual ~TProgram();
#    virtual Boolean canMoveFocus();
#    virtual ushort executeDialog(TDialog*, void*data = 0);
#    virtual void getEvent(TEvent& event);
#    virtual TPalette& getPalette() const;
#    virtual void handleEvent(TEvent& event);
#    virtual void idle();
#    virtual void initScreen();
#    virtual void outOfMemory();
#    virtual void putEvent( TEvent& event );
#    virtual void run();
#    virtual TWindow* insertWindow(TWindow*);
#    void setScreenMode( ushort mode );
#    TView *validView( TView *p ) noexcept;
#    virtual void shutDown();
#    virtual TTimerId setTimer( uint timeoutMs, int periodMs = -1 );
#    virtual void killTimer( TTimerId id );
#    virtual void suspend() {}
#    virtual void resume() {}
#    static TStatusLine *initStatusLine( TRect );
#    static TMenuBar *initMenuBar( TRect );
#    static TDeskTop *initDeskTop( TRect );
#    static TProgram * _NEAR application;
#    static TStatusLine * _NEAR statusLine;
#    static TMenuBar * _NEAR menuBar;
#    static TDeskTop * _NEAR deskTop;
#    static int _NEAR appPalette;
#    static int _NEAR eventTimeoutMs;
#protected:
#    static TEvent _NEAR pending;
#private:
#    static int eventWaitTimeout();
#    static const char * _NEAR exitText;
#    static TTimerQueue _NEAR timerQueue;
#};

package TVision::MsgBox;
package TVision::TBackground;
#class TBackground : public TView {...}
our @ISA = qw(TVision::TView);
package TVision::TButton;
#class TButton : public TView {
#[x]    TButton( const TRect& bounds, TStringView aTitle, ushort aCommand, ushort aFlags) noexcept;
#[ ]    virtual void draw();
#[ ]    void drawState( Boolean down );
#[ ]    virtual TPalette& getPalette() const;
#[ ]    virtual void handleEvent( TEvent& event );
#[ ]    void makeDefault( Boolean enable );
#[ ]    virtual void press();
#[ ]    virtual void setState( ushort aState, Boolean enable );
#[ ]    const char *title;
#[ ]protected:
#[ ]    ushort command;
#[ ]    uchar flags;
#[ ]    Boolean amDefault;
#};
our @ISA = qw(TVision::TView);

package TVision::TChDirDialog;
package TVision::TCheckBoxes;
#class TCheckBoxes : public TCluster {
#public:
#    TCheckBoxes( const TRect& bounds, TSItem *aStrings) noexcept;
#    virtual void draw();
#    virtual Boolean mark( int item );
#    virtual void press( int item );
#    static const char * const _NEAR name;
#    static TStreamable *build();
#};

package TVision::TClipboard;
package TVision::TCluster;
package TVision::TCollection;
#class TCollection : public virtual TNSCollection, public TStreamable {
#public:
#    TCollection( ccIndex aLimit, ccIndex aDelta ) noexcept { delta = aDelta; setLimit( aLimit ); }
#    static const char * const _NEAR name;
#};
package TVision::TNSCollection;
#class TNSCollection : public TObject {
#public:
#    TNSCollection( ccIndex aLimit, ccIndex aDelta ) noexcept;
#    ~TNSCollection();
#    virtual void shutDown();
#    void *at( ccIndex index );
#    virtual ccIndex indexOf( void *item );
#    void atFree( ccIndex index );
#    void atRemove( ccIndex index );
#    void remove( void *item );
#    void removeAll();
#    void free( void *item );
#    void freeAll();
#    void atInsert( ccIndex index, void *item );
#    void atPut( ccIndex index, void *item );
#    virtual ccIndex insert( void *item );
#    virtual void error( ccIndex code, ccIndex info );
#    void *firstThat( ccTestFunc Test, void *arg );
#    void *lastThat( ccTestFunc Test, void *arg );
#    void forEach( ccAppFunc action, void *arg );
#    void pack();
#    virtual void setLimit( ccIndex aLimit );
#    ccIndex getCount() { return count; }
#protected:
#    TNSCollection() noexcept;
#    void **items;
#    ccIndex count;
#    ccIndex limit;
#    ccIndex delta;
#    Boolean shouldDelete;
#private:
#    virtual void freeItem( void *item );
#};
package TVision::TNSSortedCollection;

package TVision::TColorAttr;
package TVision::TColorDialog;
package TVision::TColorDisplay;
package TVision::TColorGroup;
#class TColorGroup {
#public:
#[ ]    TColorGroup( const char *nm, TColorItem *itm = 0, TColorGroup *nxt = 0 ) noexcept;
#[ ]    virtual ~TColorGroup();
#[ ]    const char *name;
#[ ]    uchar index;
#[ ]    TColorItem *items;
#[ ]    TColorGroup *next;
#[ ]    friend TColorGroup& operator + ( TColorGroup&, TColorItem& ) noexcept;
#[ ]    friend TColorGroup& operator + ( TColorGroup& g1, TColorGroup& g2 ) noexcept;
#};
package TVision::TColorGroupList;
our @ISA = qw(TVision::TListViewer);
#class TColorGroupList : public TListViewer {
#public:
#[ ]    TColorGroupList( const TRect& bounds, TScrollBar *aScrollBar, TColorGroup *aGroups) noexcept;
#[ ]    virtual ~TColorGroupList();
#[ ]    virtual void focusItem( short item );
#[ ]    virtual void getText( char *dest, short item, short maxLen );
#[ ]    virtual void handleEvent(TEvent&);
#[ ]    void setGroupIndex(uchar groupNum, uchar itemNum);
#[ ]    TColorGroup* getGroup(uchar groupNum);
#[ ]    uchar getGroupIndex(uchar groupNum);
#[ ]    uchar getNumGroups();
#[ ]    static const char * const _NEAR name;
#[ ]    static TStreamable *build();
#};

package TVision::TColorItem;
#class TColorItem {
#public:
#    TColorItem( const char *nm, uchar idx, TColorItem *nxt = 0 ) noexcept;
#    virtual ~TColorItem();
#    const char *name;
#    uchar index;
#    TColorItem *next;
#    friend TColorGroup& operator + ( TColorGroup&, TColorItem& ) noexcept;
#    friend TColorItem& operator + ( TColorItem& i1, TColorItem& i2 ) noexcept;
#};
#class TColorIndex {
#public:
#    uchar groupIndex;
#    uchar colorSize;
#    uchar colorIndex[256];
#};

package TVision::TColorItemList;
#class TColorItemList : public TListViewer {
#public:
#[ ]    TColorItemList( const TRect& bounds, TScrollBar *aScrollBar, TColorItem *aItems) noexcept;
#[ ]    virtual void focusItem( short item );
#[ ]    virtual void getText( char *dest, short item, short maxLen );
#[ ]    virtual void handleEvent( TEvent& event );
#[ ]    static const char * const _NEAR name;
#[ ]    static TStreamable *build();
#};

package TVision::TColorSelector;
our @ISA = qw(TVision::TView);
#class TColorSelector : public TView {
#[ ]public:
#[ ]    enum ColorSel { csBackground, csForeground };
#[ ]    TColorSelector( const TRect& Bounds, ColorSel ASelType ) noexcept;
#[ ]    virtual void draw();
#[ ]    virtual void handleEvent( TEvent& event );
#[ ]protected:
#[ ]    uchar color;
#[ ]    ColorSel selType;
#[ ]private:
#[ ]    void colorChanged();
#[ ]    static const char _NEAR icon;
#[ ]    virtual const char *streamableName() const { return name; }
#[ ]protected:
#[ ]    TColorSelector( StreamableInit ) noexcept;
#[ ]    virtual void write( opstream& );
#[ ]    virtual void *read( ipstream& );
#[ ]public:
#[ ]    static const char * const _NEAR name;
#[ ]    static TStreamable *build();
#};

package TVision::TCommandSet;
package TVision::TDeskTop;
our @ISA = qw(TVision::TGroup);
#class TDeskTop : public TGroup, public virtual TDeskInit {
#public:
#    TDeskTop( const TRect& ) noexcept;
#    void cascade( const TRect& );
#    virtual void handleEvent( TEvent& );
#    static TBackground *initBackground( TRect );
#    void tile( const TRect& );
#    virtual void tileError();
#    virtual void shutDown();
#    TBackground *background;
#};
package TVision::TDialog;
our @ISA = qw(TVision::TWindow);
package TVision::TDirCollection;
package TVision::TDirEntry;
package TVision::TDirListBox;
package TVision::TDrawBuffer;
package TVision::TDrawSurface;
package TVision::TEditWindow;
our @ISA = qw(TVision::TWindow);
#class TEditWindow : public TWindow {
#public:
#[ ]    TEditWindow( const TRect&, TStringView, int ) noexcept;
#[ ]    virtual void close();
#[ ]    virtual const char *getTitle( short );
#[ ]    virtual void handleEvent( TEvent& );
#[ ]    virtual void sizeLimits( TPoint& min, TPoint& max );
#[x]    TFileEditor *editor;
#[ ]    static const char * const _NEAR name;
#[ ]    static TStreamable *build();
#};

package TVision::TEditor;
our @ISA = qw(TVision::TView);
#class TEditor : public TView {
#public:
#[ ]    friend void genRefs();
#[ ]    TEditor( const TRect&, TScrollBar *, TScrollBar *, TIndicator *, uint ) noexcept;
#[ ]    virtual ~TEditor();
#[ ]    virtual void shutDown();
#[x]    char bufChar( uint );
#[x]    uint bufPtr( uint );
#[ ]    virtual void changeBounds( const TRect& );
#[ ]    virtual void convertEvent( TEvent& );
#[x]    Boolean cursorVisible();
#[x]    void deleteSelect();
#[ ]    virtual void doneBuffer();
#[ ]    virtual void draw();
#[ ]    virtual TPalette& getPalette() const;
#[ ]    virtual void handleEvent( TEvent& );
#[ ]    virtual void initBuffer();
#[ ]    virtual TMenuItem& initContextMenu( TPoint );
#[x]    uint insertMultilineText( const char *, uint );
#[x]    Boolean insertBuffer( const char *, uint, uint, Boolean, Boolean );
#[ ]    Boolean insertEOL( Boolean );
#[ ]    virtual Boolean insertFrom( TEditor * );
#[ ]    Boolean insertText( const void *, uint, Boolean );
#[ ]    void scrollTo( int, int );
#[ ]    Boolean search( const char *, ushort );
#[ ]    virtual Boolean setBufSize( uint );
#[ ]    void setCmdState( ushort, Boolean );
#[ ]    void setSelect( uint, uint, Boolean);
#[ ]    virtual void setState( ushort, Boolean );
#[ ]    void trackCursor( Boolean );
#[ ]    void undo();
#[ ]    virtual void updateCommands();
#[ ]    virtual Boolean valid( ushort );
#[ ]    int charPos( uint, uint );
#[ ]    uint charPtr( uint, int );
#[ ]    Boolean clipCopy();
#[ ]    void clipCut();
#[ ]    void clipPaste();
#[ ]    void deleteRange( uint, uint, Boolean );
#[ ]    void doUpdate();
#[ ]    void doSearchReplace();
#[ ]    void drawLines( int, int, uint );
#[ ]    void formatLine(TScreenCell *, uint, int, TAttrPair );
#[ ]    void find();
#[ ]    uint getMousePtr( TPoint );
#[ ]    Boolean hasSelection();
#[ ]    void hideSelect();
#[ ]    Boolean isClipboard();
#[ ]    uint lineEnd( uint );
#[ ]    uint lineMove( uint, int );
#[ ]    uint lineStart( uint );
#[ ]    uint indentedLineStart( uint );
#[ ]    void lock();
#[ ]    void newLine();
#[ ]    uint nextChar( uint );
#[ ]    uint nextLine( uint );
#[ ]    uint nextWord( uint );
#[ ]    uint prevChar( uint );
#[ ]    uint prevLine( uint );
#[ ]    uint prevWord( uint );
#[ ]    void replace();
#[ ]    void setBufLen( uint );
#[ ]    void setCurPtr( uint, uchar );
#[ ]    void startSelect();
#[ ]    void toggleEncoding();
#[ ]    void toggleInsMode();
#[ ]    void unlock();
#[ ]    void update( uchar );
#[ ]    void checkScrollBar( const TEvent&, TScrollBar *, int& );
#[ ]    void detectEol();
#[ ]    TScrollBar *hScrollBar;
#[ ]    TScrollBar *vScrollBar;
#[ ]    TIndicator *indicator;
#[ ]    char *buffer;
#[ ]    uint bufSize;
#[ ]    uint bufLen;
#[ ]    uint gapLen;
#[ ]    uint selStart;
#[ ]    uint selEnd;
#[ ]    uint curPtr;
#[ ]    TPoint curPos;
#[ ]    TPoint delta;
#[ ]    TPoint limit;
#[ ]    int drawLine;
#[ ]    uint drawPtr;
#[ ]    uint delCount;
#[ ]    uint insCount;
#[ ]    Boolean isValid;
#[ ]    Boolean canUndo;
#[ ]    Boolean modified;
#[ ]    Boolean selecting;
#[ ]    Boolean overwrite;
#[ ]    Boolean autoIndent;
#[ ]    enum EolType { eolCrLf, eolLf, eolCr } eolType;
#[ ]    enum Encoding { encDefault, encSingleByte } encoding;
#[ ]    void nextChar( TStringView, uint &P, uint &width );
#[ ]    Boolean formatCell( TSpan<TScreenCell>, uint&, TStringView, uint& , TColorAttr );
#[ ]    TStringView bufChars( uint );
#[ ]    TStringView prevBufChars( uint );
#[ ]    static TEditorDialog _NEAR editorDialog;
#[ ]    static ushort _NEAR editorFlags;
#[ ]    static char _NEAR findStr[maxFindStrLen];
#[ ]    static char _NEAR replaceStr[maxReplaceStrLen];
#[ ]    static TEditor * _NEAR clipboard;
#[ ]    uchar lockCount;
#[ ]    uchar updateFlags;
#[ ]    int keyState;
#[ ]    static const char * const _NEAR name;
#[ ]    static TStreamable *build();
#};
package TVision::TMemo;
#class TMemo : public TEditor {
#public:
#    TMemo( const TRect&, TScrollBar *, TScrollBar *, TIndicator *, ushort ) noexcept;
#    virtual void getData( void *rec );
#    virtual void setData( void *rec );
#    virtual ushort dataSize();
#    virtual TPalette& getPalette() const;
#    virtual void handleEvent( TEvent& );
#    static const char * const _NEAR name;
#    static TStreamable *build();
#};
package TVision::TFileEditor;
our @ISA = qw(TVision::TEditor);
#class TFileEditor : public TEditor {
#public:
#[ ]    char fileName[MAXPATH];
#[ ]    TFileEditor( const TRect&, TScrollBar *, TScrollBar *, TIndicator *, TStringView) noexcept;
#[ ]    virtual void doneBuffer();
#[ ]    virtual void handleEvent( TEvent& );
#[ ]    virtual void initBuffer();
#[ ]    Boolean loadFile() noexcept;
#[ ]    Boolean save() noexcept;
#[ ]    Boolean saveAs() noexcept;
#[ ]    Boolean saveFile() noexcept;
#[ ]    virtual Boolean setBufSize( uint );
#[ ]    virtual void shutDown();
#[ ]    virtual void updateCommands();
#[ ]    virtual Boolean valid( ushort );
#[ ]    static const char * const _NEAR name;
#[ ]    static TStreamable *build();
#};

package TVision::EventCodes;
package TVision::TEvent;
# map it to [what, mouse1, mouse2, key1, key2, key3}
#struct TEvent {
#    ushort what;
#    union {
#        MouseEventType mouse;
#        KeyDownEvent keyDown;
#        MessageEvent message;
#    };
#    void getMouseEvent() noexcept;
#    void getKeyEvent() noexcept;
#};
#struct CharScanType {
#    uchar charCode;
#    uchar scanCode;
#};
#struct KeyDownEvent {
#    union {
#        ushort keyCode;
#        CharScanType charScan;
#    };
#    ushort controlKeyState;
#    char text[maxCharSize];     // NOT null-terminated.
#    uchar textLength;
#    TStringView getText() const;
#    operator TKey() const;
#};
# const int maxCharSize = 4; // A UTF-8-encoded character is up to 4 bytes long.
#inline TStringView KeyDownEvent::getText() const { return TStringView(text, textLength); }
#inline KeyDownEvent::operator TKey() const { return TKey(keyCode, controlKeyState); }
#struct MessageEvent {
#    ushort command;
#    union {
#        void *infoPtr;
#        int32_t infoLong;
#        ushort infoWord;
#        short infoInt;
#        uchar infoByte;
#        char infoChar;
#    };
#};

#/* Event codes */
#const int evMouseDown = 0x0001;
#const int evMouseUp   = 0x0002;
#const int evMouseMove = 0x0004;
#const int evMouseAuto = 0x0008;
#const int evMouseWheel= 0x0020;
#const int evKeyDown   = 0x0010;
#const int evCommand   = 0x0100;
#const int evBroadcast = 0x0200;
#/* Event masks */
#const int evNothing   = 0x0000;
#const int evMouse     = 0x002f;
#const int evKeyboard  = 0x0010;
#const int evMessage   = 0xFF00;
#/* Mouse button state masks */
#const int mbLeftButton  = 0x01;
#const int mbRightButton = 0x02;
#const int mbMiddleButton= 0x04;
#/* Mouse wheel state masks */
#const int mwUp      = 0x01;
#const int mwDown    = 0x02;
#const int mwLeft    = 0x04;
#const int mwRight   = 0x08;
#/* Mouse event flags */
#const int meMouseMoved = 0x01;
#const int meDoubleClick = 0x02;
#const int meTripleClick = 0x04;


package TVision::TEventQueue;
package TVision::TFileCollection;
package TVision::TFileDialog;
package TVision::TFileInfoPane;
package TVision::TFileInputLine;
package TVision::TInputLine;
our @ISA = qw(TVision::TView);
#class TInputLine : public TView {
#public:
#    TInputLine( const TRect& bounds, int limit, TValidator *aValid = 0, ushort limitMode = ilMaxBytes ) noexcept;
#    ~TInputLine();
#    virtual ushort dataSize();
#    virtual void draw();
#    virtual void getData( void *rec );
#    virtual TPalette& getPalette() const;
#    virtual void handleEvent( TEvent& event );
#    void selectAll( Boolean enable, Boolean scroll=True );
#    virtual void setData( void *rec );
#    virtual void setState( ushort aState, Boolean enable );
#    virtual Boolean valid( ushort cmd );
#    void setValidator( TValidator* aValid );
#    char* data;
#    int maxLen;
#    int maxWidth;
#    int maxChars;
#    int curPos;
#    int firstPos;
#    int selStart;
#    int selEnd;
#private:
#    Boolean canScroll( int delta );
#    int mouseDelta( TEvent& event );
#    int mousePos( TEvent& event );
#    int displayedPos( int pos );
#    void deleteSelect();
#    void deleteCurrent();
#    void adjustSelectBlock();
#    void saveState();
#    void restoreState();
#    Boolean checkValid(Boolean);
#    Boolean canUpdateCommands();
#    void setCmdState( ushort, Boolean );
#    void updateCommands();
#    static const char _NEAR rightArrow;
#    static const char _NEAR leftArrow;
#    virtual const char *streamableName() const { return name; }
#    TValidator* validator;
#    int anchor;
#    char* oldData;
#    int oldCurPos;
#    int oldFirstPos;
#    int oldSelStart;
#    int oldSelEnd;
#protected:
#    TInputLine( StreamableInit ) noexcept;
#    virtual void write( opstream& );
#    virtual void *read( ipstream& );
#public:
#    static const char * const _NEAR name;
#    static TStreamable *build();
#};


package TVision::TFileList;
package TVision::TFilterValidator;
package TVision::TFindDialogRec;
package TVision::TFrame;
our @ISA = qw(TVision::TView);
#class TFrame : public TView {
#public:
#    TFrame( const TRect& bounds ) noexcept;
#    virtual void draw();
#    virtual TPalette& getPalette() const;
#    virtual void handleEvent( TEvent& event );
#    virtual void setState( ushort aState, Boolean enable );
#private:
#    void frameLine( TDrawBuffer& frameBuf, short y, short n, TColorAttr color );
#    void dragWindow( TEvent& event, uchar dragMode );
#    friend class TDisplay;
#    static const char _NEAR initFrame[19];
#    static char _NEAR frameChars[33];
#    static const char * _NEAR closeIcon;
#    static const char * _NEAR zoomIcon;
#    static const char * _NEAR unZoomIcon;
#    static const char * _NEAR dragIcon;
#    static const char * _NEAR dragLeftIcon;
#    virtual const char *streamableName() const { return name; }
#protected:
#    TFrame( StreamableInit ) noexcept;
#public:
#    static const char * const _NEAR name;
#    static TStreamable *build();
#};
package TVision::TGroup;
our @ISA = qw(TVision::TView);
#class TGroup : public TView {
#public:
#[ ]    TGroup( const TRect& bounds ) noexcept;
#[ ]    ~TGroup();
#[ ]    virtual void shutDown();
#[ ]    ushort execView( TView *p ) noexcept;
#[ ]    virtual ushort execute();
#[ ]    virtual void awaken();
#[ ]    void insertView( TView *p, TView *Target ) noexcept;
#[ ]    void remove( TView *p );
#[ ]    void removeView( TView *p ) noexcept;
#[ ]    void resetCurrent();
#[ ]    void setCurrent( TView *p, selectMode mode );
#[ ]    void selectNext( Boolean forwards );
#[ ]    TView *firstThat( Boolean (*func)( TView *, void * ), void *args );
#[ ]    Boolean focusNext(Boolean forwards);
#[ ]    void forEach( void (*func)( TView *, void * ), void *args );
#[ ]    void insert( TView *p ) noexcept;
#[ ]    void insertBefore( TView *p, TView *Target );
#[ ]    TView *current;
#[ ]    TView *at( short index ) noexcept;
#[ ]    TView *firstMatch( ushort aState, ushort aOptions ) noexcept;
#[ ]    short indexOf( TView *p ) noexcept;
#[ ]    TView *first() noexcept;
#[ ]    virtual void setState( ushort aState, Boolean enable );
#[ ]    virtual void handleEvent( TEvent& event );
#[ ]    void drawSubViews( TView *p, TView *bottom ) noexcept;
#[ ]    virtual void changeBounds( const TRect& bounds );
#[ ]    virtual ushort dataSize();
#[ ]    virtual void getData( void *rec );
#[ ]    virtual void setData( void *rec );
#[ ]    virtual void draw();
#[x]    void redraw() noexcept;
#[ ]    void lock() noexcept;
#[ ]    void unlock() noexcept;
#[ ]    virtual void resetCursor();
#[ ]    virtual void endModal( ushort command );
#[ ]    virtual void eventError( TEvent& event );
#[ ]    virtual ushort getHelpCtx();
#[ ]    virtual Boolean valid( ushort command );
#[ ]    void freeBuffer() noexcept;
#[ ]    void getBuffer() noexcept;
#[ ]    TView *last;
#[ ]    TRect clip;
#[ ]    phaseType phase;
#[ ]    TScreenCell *buffer;
#[ ]    uchar lockFlag;
#[ ]    ushort endState;
#[ ]private:
#[ ]    void focusView( TView *p, Boolean enable );
#[ ]    void selectView( TView *p, Boolean enable );
#[ ]    TView* findNext(Boolean forwards) noexcept;
#[ ]    virtual const char *streamableName() const { return name; }
#[ ]protected:
#[ ]    TGroup( StreamableInit ) noexcept;
#[ ]    virtual void write( opstream& );
#[ ]    virtual void *read( ipstream& );
#[ ]public:
#[ ]    static const char * const _NEAR name;
#[ ]    static TStreamable *build();
#[ ]};

package TVision::THardwareInfo;
package TVision::THistory;
our @ISA = qw(TVision::TView);
#class THistory : public TView {
#public:
#    THistory( const TRect& bounds, TInputLine *aLink, ushort aHistoryId ) noexcept;
#    virtual void draw();
#    virtual TPalette& getPalette() const;
#    virtual void handleEvent( TEvent& event );
#    virtual THistoryWindow *initHistoryWindow( const TRect& bounds );
#    virtual void recordHistory(const char *s);
#    virtual void shutDown();
#protected:
#    TInputLine *link;
#    ushort historyId;
#private:
#    static const char * _NEAR icon;
#    virtual const char *streamableName() const
#protected:
#    THistory( StreamableInit ) noexcept;
#    virtual void write( opstream& );
#    virtual void *read( ipstream& );
#public:
#    static const char * const _NEAR name;
#    static TStreamable *build();
#};
package TVision::THistoryViewer;
our @ISA = qw(TVision::TListViewer);
#class THistoryViewer : public TListViewer {
#public:
#[ ]    THistoryViewer( const TRect& bounds, TScrollBar *aHScrollBar, TScrollBar *aVScrollBar, ushort aHistoryId)
#[ ]    virtual TPalette& getPalette() const;
#[ ]    virtual void getText( char *dest, short item, short maxLen );
#[ ]    virtual void handleEvent( TEvent& event );
#[ ]    int historyWidth() noexcept;
#};
package TVision::THistoryWindow;
package TVision::TIndicator;
#class TIndicator : public TView {
#public:
#    TIndicator( const TRect& ) noexcept;
#    virtual void draw();
#    virtual TPalette& getPalette() const;
#    virtual void setState( ushort, Boolean );
#    void setValue( const TPoint&, Boolean );
#    static const char * const _NEAR name;
#    static TStreamable *build();
#};
package TVision::TKey;
#class TKey {
#public:
#    constexpr TKey() noexcept;
#    TKey(ushort keyCode, ushort shiftState = 0) noexcept;
#    ushort code;
#    ushort mods;
#};

package TVision::TLabel;
our @ISA = qw(TVision::TStaticText);
#class TLabel : public TStaticText {
#[ ]public:
#[x]   TLabel( const TRect& bounds, TStringView aText, TView *aLink ) noexcept;
#[ ]    virtual void draw();
#[ ]    virtual TPalette& getPalette() const;
#[ ]    virtual void handleEvent( TEvent& event );
#[ ]    virtual void shutDown();
#[ ]    static const char * const _NEAR name;
#[ ]    static TStreamable *build();
#};

package TVision::TListBox;
our @ISA = qw(TVision::TListViewer);
#class TListBox : public TListViewer {
#public:
#[ ]    TListBox( const TRect& bounds, ushort aNumCols, TScrollBar *aScrollBar ) noexcept;
#[ ]    ~TListBox();
#[ ]    virtual ushort dataSize();
#[ ]    virtual void getData( void *rec );
#[ ]    virtual void getText( char *dest, short item, short maxLen );
#[ ]    virtual void newList( TCollection *aList );
#[ ]    virtual void setData( void *rec );
#[ ]    TCollection *list();
#[ ]    static const char * const _NEAR name;
#[ ]    static TStreamable *build();
#};

package TVision::TListViewer;
our @ISA = qw(TVision::TView);
#class TListViewer : public TView {
#    static const char * _NEAR emptyText;
#public:
#    TListViewer( const TRect& bounds, ushort aNumCols, TScrollBar *aHScrollBar, TScrollBar *aVScrollBar) noexcept;
#    virtual void changeBounds( const TRect& bounds );
#    virtual void draw();
#    virtual void focusItem( short item );
#    virtual TPalette& getPalette() const;
#    virtual void getText( char *dest, short item, short maxLen );
#    virtual Boolean isSelected( short item );
#    virtual void handleEvent( TEvent& event );
#    virtual void selectItem( short item );
#    void setRange( short aRange );
#    virtual void setState( ushort aState, Boolean enable );
#    virtual void focusItemNum( short item );
#    virtual void shutDown();
#    TScrollBar *hScrollBar;
#    TScrollBar *vScrollBar;
#    short numCols;
#    short topItem;
#    short focused;
#    short range;
#private:
#    virtual const char *streamableName() const { return name; }
#protected:
#    TListViewer( StreamableInit ) noexcept;
#    virtual void write( opstream& );
#    virtual void *read( ipstream& );
#public:
#    static const char * const _NEAR name;
#    static TStreamable *build();
#};
package TVision::TLookupValidator;

package TVision::TMenu;
#class TMenu {
#public:
#    TMenu() noexcept : items(0), deflt(0) {};
#    TMenu( TMenuItem& itemList ) noexcept { items = &itemList; deflt = &itemList; }
#    TMenu( TMenuItem& itemList, TMenuItem& TheDefault ) noexcept { items = &itemList; deflt = &TheDefault; }
#    ~TMenu();
#    TMenuItem *items;
#    TMenuItem *deflt;
#};
package TVision::TMenuBar;
our @ISA = qw(TVision::TMenuView);
#class TMenuBar : public TMenuView {
#public:
#    TMenuBar( const TRect& bounds, TMenu *aMenu ) noexcept;
#    TMenuBar( const TRect& bounds, TSubMenu &aMenu ) noexcept;
#    ~TMenuBar();
#    virtual void draw();
#    virtual TRect getItemRect( TMenuItem *item );
#    static const char * const _NEAR name;
#    static TStreamable *build();
#};

package TVision::TMenuBox;
#class TMenuBox : public TMenuView {
#public:
#    TMenuBox( const TRect& bounds, TMenu *aMenu, TMenuView *aParentMenu) noexcept;
#    virtual void draw();
#    virtual TRect getItemRect( TMenuItem *item );
#    static const char * const _NEAR name;
#    static TStreamable *build();
#};

package TVision::TMenuItem;
#class TMenuItem {
#public:
#[x]    TMenuItem( TStringView aName, ushort aCommand, TKey aKey, ushort aHelpCtx = hcNoContext, TStringView p = 0, TMenuItem *aNext = 0) noexcept;
#[x]    TMenuItem( TStringView aName, TKey aKey, TMenu *aSubMenu, ushort aHelpCtx = hcNoContext, TMenuItem *aNext = 0) noexcept;
#[ ]    ~TMenuItem();
#[x]    void append( TMenuItem *aNext ) noexcept;
#[x]    TMenuItem *next;
#[ ]    const char *name;
#[x]    ushort command;
#[x]    Boolean disabled;
#[x]    TKey keyCode;
#[x]    ushort helpCtx;
#[ ]    union {
#[ ]        const char *param;
#[ ]        TMenu *subMenu;
#[ ]    };
#};
package TVision::TMenuPopup;
#class TMenuPopup : public TMenuBox {
#public:
#    TMenuPopup(const TRect& bounds, TMenu *aMenu, TMenuView *aParent = 0) noexcept;
#    virtual ushort execute();
#    virtual void handleEvent(TEvent&);
#    static const char * const _NEAR name;
#    static TStreamable *build();
#};

package TVision::TMenuView;
our @ISA = qw(TVision::TView);
#class TMenuView : public Tiew {
#public:
#    TMenuView( const TRect& bounds, TMenu *aMenu, TMenuView *aParent = 0 ) noexcept;
#    TMenuView( const TRect& bounds ) noexcept;
#    virtual ushort execute();
#    TMenuItem *findItem( char ch );
#    virtual TRect getItemRect( TMenuItem *item );
#    virtual ushort getHelpCtx();
#    virtual TPalette& getPalette() const;
#    virtual void handleEvent( TEvent& event );
#    TMenuItem *hotKey( TKey key );
#    TMenuView *newSubView( const TRect& bounds, TMenu *aMenu, TMenuView *aParentMenu);
#    static const char * const _NEAR name;
#    static TStreamable *build();
#};
package TVision::TSubMenu;
our @ISA = qw(TVision::TMenuItem);
#class TSubMenu : public TMenuItem {
#public:
#    TSubMenu( TStringView nm, TKey key, ushort helpCtx = hcNoContext ) noexcept;
#};


package TVision::TMonoSelector;
package TVision::TMultiCheckBoxes;
package TVision::TObject;
package TVision::TOutline;
package TVision::TOutlineViewer;
package TVision::TPReadObjects;
package TVision::TPWrittenObjects;
package TVision::TPXPictureValidator;
package TVision::TPalette;
package TVision::TParamText;
package TVision::TRadioButtons;
#class TRadioButtons : public TCluster {
#public:
#    TRadioButtons( const TRect& bounds, TSItem *aStrings ) noexcept;
#    virtual void draw();
#    virtual Boolean mark( int item );
#    virtual void movedTo( int item );
#    virtual void press( int item );
#    virtual void setData( void *rec );
#    static const char * const _NEAR name;
#    static TStreamable *build();
#};

package TVision::TRangeValidator;
package TVision::TRect;
#class TRect { TPoint a, b; };
package TVision::TPoint;
#class TPoint { int x,y; };
package TVision::TKey;
#class TKey {
#    constexpr TKey() noexcept;
#    TKey(ushort keyCode, ushort shiftState = 0) noexcept;
#    ushort code;
#    ushort mods;
#};

package TVision::TReplaceDialogRec;
package TVision::TResourceCollection;
package TVision::TResourceFile;
package TVision::TResourceItem;
package TVision::TSItem;
#class TSItem {
#public:
#    TSItem( TStringView aValue, TSItem *aNext ) noexcept { value = newStr(aValue); next = aNext; }
#    ~TSItem() { delete[] (char *) value; }
#    const char *value;
#    TSItem *next;
#};

package TVision::TScreen;
package TVision::TScreenCell;
# TODO
#  //// TScreenCell
#  //
#  // Stores the text and color attributes in a screen cell.
#  // Please use the functions in the TText namespace in order to fill screen cells
#  // with text.
#  //
#  // Considerations:
#  // * In order for a double-width character to be displayed entirely, its cell
#  //   must be followed by another containing a wide char trail. If it is not,
#  //   or if a wide char trail is not preceded by a double-width character,
#  //   we'll understand that a double-width character is being overlapped partially.
#
#  struct TScreenCell  {
#      TColorAttr attr;
#      TCellChar _ch;
#      TScreenCell() = default;
#      inline TScreenCell(ushort bios);
#      TV_TRIVIALLY_ASSIGNABLE(TScreenCell)
#      constexpr inline bool isWide() const;
#      inline bool operator==(const TScreenCell &other) const;
#      inline bool operator!=(const TScreenCell &other) const;
#  };
package TVision::TScrollBar;
#// TScrollBar part codes
#    sbLeftArrow     = 0,
#    sbRightArrow    = 1,
#    sbPageLeft      = 2,
#    sbPageRight     = 3,
#    sbUpArrow       = 4,
#    sbDownArrow     = 5,
#    sbPageUp        = 6,
#    sbPageDown      = 7,
#    sbIndicator     = 8,
#// TScrollBar options for TWindow.StandardScrollBar
#    sbHorizontal    = 0x000,
#    sbVertical      = 0x001,
#    sbHandleKeyboard = 0x002,
#// TScrollBar messages
#    cmScrollBarChanged  = 53,
#    cmScrollBarClicked  = 54,
#class TScrollBar : public TView {
#public:
#[x]    TScrollBar( const TRect& bounds ) noexcept;
#[ ]    virtual void draw();
#[ ]    virtual TPalette& getPalette() const;
#[ ]    virtual void handleEvent( TEvent& event );
#[ ]    virtual void scrollDraw();
#[ ]    virtual int scrollStep( int part );
#[x]    void setParams( int aValue, int aMin, int aMax, int aPgStep, int aArStep ) noexcept;
#[x]    void setRange( int aMin, int aMax ) noexcept;
#[x]    void setStep( int aPgStep, int aArStep ) noexcept;
#[x]    void setValue( int aValue ) noexcept;
#[x]    void drawPos( int pos ) noexcept;
#[x]    int getPos() noexcept;
#[x]    int getSize() noexcept;
#[x]    int value;
#[ ]    TScrollChars chars;
#[x]    int minVal;
#[x]    int maxVal;
#[x]    int pgStep;
#[x]    int arStep;
#[ ]    static const char * const _NEAR name;
#[ ]    static TStreamable *build();
#};
package TVision::TScroller;
our @ISA = qw(TVision::TView);
#class TScroller : public TView {
#[ ]public:
#[x]    TScroller( const TRect& bounds, TScrollBar *aHScrollBar, TScrollBar *aVScrollBar) noexcept;
#[ ]    virtual void changeBounds( const TRect& bounds );
#[ ]    virtual TPalette& getPalette() const;
#[ ]    virtual void handleEvent( TEvent& event );
#[ ]    virtual void scrollDraw();
#[x]    void scrollTo( int x, int y ) noexcept;
#[x]    void setLimit( int x, int y ) noexcept;
#[ ]    virtual void setState( ushort aState, Boolean enable );
#[x]    void checkDraw() noexcept;
#[ ]    virtual void shutDown();
#[x]    TPoint delta;
#[ ]protected:
#[ ]    uchar drawLock;
#[ ]    Boolean drawFlag;
#[ ]    TScrollBar *hScrollBar;
#[ ]    TScrollBar *vScrollBar;
#[ ]    TPoint limit;
#[ ]    TScroller( StreamableInit ) noexcept;
#[ ]    virtual void write( opstream& );
#[ ]    virtual void *read( ipstream& );
#[ ]private:
#[ ]    void showSBar( TScrollBar *sBar );
#[ ]    virtual const char *streamableName() const { return name; }
#[ ]public:
#[ ]    static const char * const _NEAR name;
#[ ]    static TStreamable *build();
#};
package TVision::TSearchRec;
package TVision::TSortedCollection;
package TVision::TSortedListBox;
package TVision::TStaticText;
our @ISA = qw(TVision::TView);
#class TStaticText : public TView {
#[ ]public:
#[x]    TStaticText( const TRect& bounds, TStringView aText ) noexcept;
#[ ]    ~TStaticText();
#[ ]    virtual void draw();
#[ ]    virtual TPalette& getPalette() const;
#[ ]    virtual void getText( char * );
#[ ]protected:
#[ ]    const char *text;
#[ ]private:
#[ ]    virtual const char *streamableName() const { return name; }
#[ ]protected:
#[ ]    TStaticText( StreamableInit ) noexcept;
#[ ]    virtual void write( opstream& );
#[ ]    virtual void *read( ipstream& );
#[ ]public:
#[ ]    static const char * const _NEAR name;
#[ ]    static TStreamable *build();
#};


package TVision::TStatusDef;
package TVision::TStatusItem;
#class TStatusItem {
#public:
#    TStatusItem( TStringView aText, TKey aKey, ushort cmd, TStatusItem *aNext = 0) noexcept;
#    ~TStatusItem();
#    TStatusItem *next;
#    char *text;
#    TKey keyCode;
#    ushort command;
#};

package TVision::TStatusLine;
package TVision::TStrIndexRec;
package TVision::TStrListMaker;
package TVision::TStreamable;
package TVision::TStreamableClass;
package TVision::TStreamableTypes;
package TVision::TStringCollection;
package TVision::TStringList;

package TVision::TStringLookupValidator;

#####IDK TODO
#class TStringView {
#    // This class exists only to compensate for the lack of std::string_view
#    // in Borland C++. Unless you are programming for that compiler, you should
#    // always use std::string_view.
#    // Unlike std::string_view, TStringView can be constructed from a null pointer,
#    // for backward compatibility.
#    // TStringView is intercompatible with std::string_view, std::string and
#    // TSpan<const char>.
#    const char _FAR *str;
#    size_t len;
#public:
#    constexpr TStringView();
#              TStringView(const char _FAR *str);
#    constexpr TStringView(const char _FAR *str, size_t len);
#    constexpr TStringView(TSpan<char> span);
#    constexpr TStringView(TSpan<const char> span);
#    TStringView(const std::string &text);
#    operator std::string() const;
#    constexpr operator TSpan<const char>() const;
#    constexpr const char _FAR * data() const;
#    constexpr size_t size() const;
#    constexpr Boolean empty() const;
#    constexpr const char _FAR & operator[](size_t pos) const;
#    constexpr const char _FAR & front() const;
#    constexpr const char _FAR & back() const;
#    constexpr TStringView substr(size_t pos) const;
#    constexpr TStringView substr(size_t pos, size_t n) const;
#    constexpr const char _FAR * begin() const;
#    constexpr const char _FAR * cbegin() const;
#    constexpr const char _FAR * end() const;
#    constexpr const char _FAR * cend() const;
#};


package TVision::TSurfaceView;
package TVision::TSystemError;
package TVision::TTerminal;
package TVision::TText;
package TVision::TTextDevice;
package TVision::TTimerQueue;
package TVision::TVMemMgr;
package TVision::TValidator;
package TVision::TView;
our @ISA = qw(TVision::TObject);
#class TView : public TObject, public TStreamable {
#[ ]public:
#[ ]    friend void genRefs();
#[ ]    enum phaseType { phFocused, phPreProcess, phPostProcess };
#[ ]    enum selectMode{ normalSelect, enterSelect, leaveSelect };
#[x]    TView( const TRect& bounds ) noexcept;
#[ ]    ~TView();
#[ ]    virtual void sizeLimits( TPoint& min, TPoint& max );
#[x]    TRect getBounds() const noexcept;
#[x]    TRect getExtent() const noexcept;
#[x]    TRect getClipRect() const noexcept;
#[x]    Boolean mouseInView( TPoint mouse ) noexcept;
#[ ]    Boolean containsMouse( TEvent& event ) noexcept;
#[x]    void locate( TRect& bounds );
#[ ]    virtual void dragView( TEvent& event, uchar mode, TRect& limits, TPoint minSize, TPoint maxSize ); // temporary fix for Miller's stuff
#[ ]    virtual void calcBounds( TRect& bounds, TPoint delta );
#[ ]    virtual void changeBounds( const TRect& bounds );
#[x]    void growTo( short x, short y );
#[x]    void moveTo( short x, short y );
#[ ]    void setBounds( const TRect& bounds ) noexcept;
#[ ]    virtual ushort getHelpCtx();
#[ ]    virtual Boolean valid( ushort command );
#[x]    void hide();
#[x]    void show();
#[ ]    virtual void draw();
#[x]    void drawView() noexcept;
#[x]    Boolean exposed() noexcept;
#[x]    Boolean focus();
#[x]    void hideCursor();
#[x]    void drawHide( TView *lastView );
#[x]    void drawShow( TView *lastView );
#[x]    void drawUnderRect( TRect& r, TView *lastView );
#[x]    void drawUnderView( Boolean doShadow, TView *lastView );
#[ ]    virtual ushort dataSize();
#[ ]    virtual void getData( void *rec );
#[ ]    virtual void setData( void *rec );
#[ ]    virtual void awaken();
#[x]    void blockCursor();
#[x]    void normalCursor();
#[x]    virtual void resetCursor();
#[x]    void setCursor( int x, int y ) noexcept;
#[x]    void showCursor();
#[x]    void drawCursor() noexcept;
#[ ]    void clearEvent( TEvent& event ) noexcept;
#[ ]    Boolean eventAvail();
#[ ]    virtual void getEvent( TEvent& event );
#[ ]    virtual void handleEvent( TEvent& event );
#[ ]    virtual void putEvent( TEvent& event );
#[x]    static Boolean commandEnabled( ushort command ) noexcept;
#[ ]    static void disableCommands( TCommandSet& commands ) noexcept;
#[ ]    static void enableCommands( TCommandSet& commands ) noexcept;
#[x]    static void disableCommand( ushort command ) noexcept;
#[x]    static void enableCommand( ushort command ) noexcept;
#[ ]    static void getCommands( TCommandSet& commands ) noexcept;
#[ ]    static void setCommands( TCommandSet& commands ) noexcept;
#[ ]    static void setCmdState( TCommandSet& commands, Boolean enable ) noexcept;
#[x]    virtual void endModal( ushort command );
#[x]    virtual ushort execute();
#[ ]    TAttrPair getColor( ushort color ) noexcept;
#[ ]    virtual TPalette& getPalette() const;
#[ ]    virtual TColorAttr mapColor( uchar ) noexcept;
#[x]    Boolean getState( ushort aState ) const noexcept;
#[x]    void select();
#[ ]    virtual void setState( ushort aState, Boolean enable );
#[ ]    void getEvent( TEvent& event, int timeoutMs );
#[ ]    void keyEvent( TEvent& event );
#[ ]    Boolean mouseEvent( TEvent& event, ushort mask );
#[ ]    Boolean textEvent( TEvent &event, TSpan<char> dest, size_t &length );
#[ ]    virtual TTimerId setTimer( uint timeoutMs, int periodMs = -1 );
#[ ]    virtual void killTimer( TTimerId id );
#[x]    TPoint makeGlobal( TPoint source ) noexcept;
#[x]    TPoint makeLocal( TPoint source ) noexcept;
#[x]    TView *nextView() noexcept;
#[x]    TView *prevView() noexcept;
#[x]    TView *prev() noexcept;
#[x]    TView *next;
#[x]    void makeFirst();
#[x]    void putInFrontOf( TView *Target );
#[x]    TView *TopView() noexcept;
#[ ]    void writeBuf(  short x, short y, short w, short h, const void _FAR* b ) noexcept;
#[ ]    void writeBuf(  short x, short y, short w, short h, const TDrawBuffer& b ) noexcept;
#[ ]    void writeChar( short x, short y, char c, uchar color, short count ) noexcept;
#[ ]    void writeLine( short x, short y, short w, short h, const TDrawBuffer& b ) noexcept;
#[ ]    void writeLine( short x, short y, short w, short h, const void _FAR *b ) noexcept;
#[ ]    void writeStr( short x, short y, const char *str, uchar color ) noexcept;
#[x]    TPoint size;
#[x]    ushort options;
#[x]    ushort eventMask;
#[x]    ushort state;
#[x]    TPoint origin;
#[x]    TPoint cursor;
#[x]    uchar growMode;
#[x]    uchar dragMode;
#[x]    ushort helpCtx;
#[x]    static Boolean _NEAR commandSetChanged;
#[x]    TGroup *owner;
#[x]    static Boolean _NEAR showMarkers;
#[x]    static uchar _NEAR errorAttr;
#[ ]    virtual void shutDown();
#private:
#    void moveGrow( TPoint p, TPoint s, TRect& limits, TPoint minSize, TPoint maxSize, uchar mode);
#    void change( uchar, TPoint delta, TPoint& p, TPoint& s, ushort ctrlState ) noexcept;
#    static void writeView( write_args );
#    void writeView( short x, short y, short count, const void _FAR* b ) noexcept;
#    TPoint resizeBalance;
#    virtual const char *streamableName() const { return name; }
#protected:
#    TView( StreamableInit ) noexcept;
#public:
#    static const char * const _NEAR name;
#    static TStreamable *build();
#protected:
#    virtual void write( opstream& );
#    virtual void *read( ipstream& );
#};

package TVision::TWindow;
our @ISA = qw(TVision::TGroup);
#class TWindow: public TGroup, public virtual TWindowInit {
#public:
#[x]    TWindow( const TRect& bounds, TStringView aTitle, short aNumber) noexcept;
#[ ]    ~TWindow();
#[ ]    virtual void close();
#[ ]    virtual TPalette& getPalette() const;
#[ ]    virtual const char *getTitle( short maxSize );
#[ ]    virtual void handleEvent( TEvent& event );
#[x]    static TFrame *initFrame( TRect );
#[ ]    virtual void setState( ushort aState, Boolean enable );
#[ ]    virtual void sizeLimits( TPoint& min, TPoint& max );
#[x]    TScrollBar *standardScrollBar( ushort aOptions ) noexcept;
#[x]    virtual void zoom();
#[x]    virtual void shutDown();
#[x]    uchar flags;
#[x]    TRect zoomRect;
#[x]    short number;
#[x]    short palette;
#[x]    TFrame *frame;
#[ ]    const char *title;
#[ ]    static const char * const _NEAR name;
#[ ]    static TStreamable *build();
#};
package TVision::fpbase;
package TVision::fpstream;
package TVision::ifpstream;
package TVision::iopstream;
package TVision::ipstream;
package TVision::ofpstream;
package TVision::opstream;
package TVision::pstream;

package TVision;

my ($keys, $commands, $msgbox);

BEGIN {
    $keys =  {
    # Control keys
        kbCtrlA     => 0x0001,   kbCtrlB     => 0x0002,   kbCtrlC     => 0x0003,
        kbCtrlD     => 0x0004,   kbCtrlE     => 0x0005,   kbCtrlF     => 0x0006,
        kbCtrlG     => 0x0007,   kbCtrlH     => 0x0008,   kbCtrlI     => 0x0009,
        kbCtrlJ     => 0x000a,   kbCtrlK     => 0x000b,   kbCtrlL     => 0x000c,
        kbCtrlM     => 0x000d,   kbCtrlN     => 0x000e,   kbCtrlO     => 0x000f,
        kbCtrlP     => 0x0010,   kbCtrlQ     => 0x0011,   kbCtrlR     => 0x0012,
        kbCtrlS     => 0x0013,   kbCtrlT     => 0x0014,   kbCtrlU     => 0x0015,
        kbCtrlV     => 0x0016,   kbCtrlW     => 0x0017,   kbCtrlX     => 0x0018,
        kbCtrlY     => 0x0019,   kbCtrlZ     => 0x001a,
    # Extended key codes
        kbEsc       => 0x011b,   kbAltSpace  => 0x0200,   kbCtrlIns   => 0x0400,
        kbShiftIns  => 0x0500,   kbCtrlDel   => 0x0600,   kbShiftDel  => 0x0700,
        kbBack      => 0x0e08,   kbCtrlBack  => 0x0e7f,   kbShiftTab  => 0x0f00,
        kbTab       => 0x0f09,   kbAltQ      => 0x1000,   kbAltW      => 0x1100,
        kbAltE      => 0x1200,   kbAltR      => 0x1300,   kbAltT      => 0x1400,
        kbAltY      => 0x1500,   kbAltU      => 0x1600,   kbAltI      => 0x1700,
        kbAltO      => 0x1800,   kbAltP      => 0x1900,   kbCtrlEnter => 0x1c0a,
        kbEnter     => 0x1c0d,   kbAltA      => 0x1e00,   kbAltS      => 0x1f00,
        kbAltD      => 0x2000,   kbAltF      => 0x2100,   kbAltG      => 0x2200,
        kbAltH      => 0x2300,   kbAltJ      => 0x2400,   kbAltK      => 0x2500,
        kbAltL      => 0x2600,   kbAltZ      => 0x2c00,   kbAltX      => 0x2d00,
        kbAltC      => 0x2e00,   kbAltV      => 0x2f00,   kbAltB      => 0x3000,
        kbAltN      => 0x3100,   kbAltM      => 0x3200,   kbF1        => 0x3b00,
        kbF2        => 0x3c00,   kbF3        => 0x3d00,   kbF4        => 0x3e00,
        kbF5        => 0x3f00,   kbF6        => 0x4000,   kbF7        => 0x4100,
        kbF8        => 0x4200,   kbF9        => 0x4300,   kbF10       => 0x4400,
        kbHome      => 0x4700,   kbUp        => 0x4800,   kbPgUp      => 0x4900,
        kbGrayMinus => 0x4a2d,   kbLeft      => 0x4b00,   kbRight     => 0x4d00,
        kbGrayPlus  => 0x4e2b,   kbEnd       => 0x4f00,   kbDown      => 0x5000,
        kbPgDn      => 0x5100,   kbIns       => 0x5200,   kbDel       => 0x5300,
        kbShiftF1   => 0x5400,   kbShiftF2   => 0x5500,   kbShiftF3   => 0x5600,
        kbShiftF4   => 0x5700,   kbShiftF5   => 0x5800,   kbShiftF6   => 0x5900,
        kbShiftF7   => 0x5a00,   kbShiftF8   => 0x5b00,   kbShiftF9   => 0x5c00,
        kbShiftF10  => 0x5d00,   kbCtrlF1    => 0x5e00,   kbCtrlF2    => 0x5f00,
        kbCtrlF3    => 0x6000,   kbCtrlF4    => 0x6100,   kbCtrlF5    => 0x6200,
        kbCtrlF6    => 0x6300,   kbCtrlF7    => 0x6400,   kbCtrlF8    => 0x6500,
        kbCtrlF9    => 0x6600,   kbCtrlF10   => 0x6700,   kbAltF1     => 0x6800,
        kbAltF2     => 0x6900,   kbAltF3     => 0x6a00,   kbAltF4     => 0x6b00,
        kbAltF5     => 0x6c00,   kbAltF6     => 0x6d00,   kbAltF7     => 0x6e00,
        kbAltF8     => 0x6f00,   kbAltF9     => 0x7000,   kbAltF10    => 0x7100,
        kbCtrlPrtSc => 0x7200,   kbCtrlLeft  => 0x7300,   kbCtrlRight => 0x7400,
        kbCtrlEnd   => 0x7500,   kbCtrlPgDn  => 0x7600,   kbCtrlHome  => 0x7700,
        kbAlt1      => 0x7800,   kbAlt2      => 0x7900,   kbAlt3      => 0x7a00,
        kbAlt4      => 0x7b00,   kbAlt5      => 0x7c00,   kbAlt6      => 0x7d00,
        kbAlt7      => 0x7e00,   kbAlt8      => 0x7f00,   kbAlt9      => 0x8000,
        kbAlt0      => 0x8100,   kbAltMinus  => 0x8200,   kbAltEqual  => 0x8300,
        kbCtrlPgUp  => 0x8400,   kbNoKey     => 0x0000,
    # Additional extended key codes
        kbAltEsc    => 0x0100,   kbAltBack   => 0x0e00,   kbF11       => 0x8500,
        kbF12       => 0x8600,   kbShiftF11  => 0x8700,   kbShiftF12  => 0x8800,
        kbCtrlF11   => 0x8900,   kbCtrlF12   => 0x8a00,   kbAltF11    => 0x8b00,
        kbAltF12    => 0x8c00,   kbCtrlUp    => 0x8d00,   kbCtrlDown  => 0x9100,
        kbCtrlTab   => 0x9400,   kbAltHome   => 0x9700,   kbAltUp     => 0x9800,
        kbAltPgUp   => 0x9900,   kbAltLeft   => 0x9b00,   kbAltRight  => 0x9d00,
        kbAltEnd    => 0x9f00,   kbAltDown   => 0xa000,   kbAltPgDn   => 0xa100,
        kbAltIns    => 0xa200,   kbAltDel    => 0xa300,   kbAltTab    => 0xa500,
        kbAltEnter  => 0xa600
    };

    $commands = {
    # Standard command codes
        cmValid         => 0,
        cmQuit          => 1,
        cmError         => 2,
        cmMenu          => 3,
        cmClose         => 4,
        cmZoom          => 5,
        cmResize        => 6,
        cmNext          => 7,
        cmPrev          => 8,
        cmHelp          => 9,
    # TDialog standard commands
        cmOK            => 10,
        cmCancel        => 11,
        cmYes           => 12,
        cmNo            => 13,
        cmDefault       => 14,
    # Standard application commands
        cmNew           => 30,
        cmOpen          => 31,
        cmSave          => 32,
        cmSaveAs        => 33,
        cmSaveAll       => 34,
        cmChDir         => 35,
        cmDosShell      => 36,
        cmCloseAll      => 37,
    # some more
        cmAboutCmd             => 100,
        cmOpenCmd              => 105,
        cmChDirCmd             => 106,
        cmMouseCmd             => 108,
        cmSaveCmd              => 110,
        cmRestoreCmd           => 111,
        cmEventViewCmd         => 112,
        #? cmResize => 120,
        #? cmZoom => 120,
        #? cmNext => 120,
        #? cmClose => 120,
        #? cmTile => 120,
        #? cmCascade => 120,

    # TView State masks
        sfVisible       => 0x001,
        sfCursorVis     => 0x002,
        sfCursorIns     => 0x004,
        sfShadow        => 0x008,
        sfActive        => 0x010,
        sfSelected      => 0x020,
        sfFocused       => 0x040,
        sfDragging      => 0x080,
        sfDisabled      => 0x100,
        sfModal         => 0x200,
        sfDefault       => 0x400,
        sfExposed       => 0x800,
    # TView Option masks
        ofSelectable    => 0x001,
        ofTopSelect     => 0x002,
        ofFirstClick    => 0x004,
        ofFramed        => 0x008,
        ofPreProcess    => 0x010,
        ofPostProcess   => 0x020,
        ofBuffered      => 0x040,
        ofTileable      => 0x080,
        ofCenterX       => 0x100,
        ofCenterY       => 0x200,
        ofCentered      => 0x300,
        ofValidate      => 0x400,
    # TView GrowMode masks
        gfGrowLoX       => 0x01,
        gfGrowLoY       => 0x02,
        gfGrowHiX       => 0x04,
        gfGrowHiY       => 0x08,
        gfGrowAll       => 0x0f,
        gfGrowRel       => 0x10,
        gfFixed         => 0x20,
    # TView DragMode masks
        dmDragMove      => 0x01,
        dmDragGrow      => 0x02,
        dmDragGrowLeft  => 0x04,
        dmLimitLoX      => 0x10,
        dmLimitLoY      => 0x20,
        dmLimitHiX      => 0x40,
        dmLimitHiY      => 0x80,
        #TODO dmLimitAll      => dmLimitLoX | dmLimitLoY | dmLimitHiX | dmLimitHiY,
    # TView Help context codes
        hcNoContext     => 0,
        hcDragging      => 1,
    # TScrollBar part codes
        sbLeftArrow     => 0,
        sbRightArrow    => 1,
        sbPageLeft      => 2,
        sbPageRight     => 3,
        sbUpArrow       => 4,
        sbDownArrow     => 5,
        sbPageUp        => 6,
        sbPageDown      => 7,
        sbIndicator     => 8,
    # TScrollBar options for TWindow.StandardScrollBar
        sbHorizontal    => 0x000,
        sbVertical      => 0x001,
        sbHandleKeyboard => 0x002,
    # TWindow Flags masks
        wfMove          => 0x01,
        wfGrow          => 0x02,
        wfClose         => 0x04,
        wfZoom          => 0x08,
    # TView inhibit flags
        noMenuBar       => 0x0001,
        noDeskTop       => 0x0002,
        noStatusLine    => 0x0004,
        noBackground    => 0x0008,
        noFrame         => 0x0010,
        noViewer        => 0x0020,
        noHistory       => 0x0040,
    # TWindow number constants
        wnNoNumber      => 0,
    # TWindow palette entries
        wpBlueWindow    => 0,
        wpCyanWindow    => 1,
        wpGrayWindow    => 2,
    #  Application command codes
        cmCut           => 20,
        cmCopy          => 21,
        cmPaste         => 22,
        cmUndo          => 23,
        cmClear         => 24,
        cmTile          => 25,
        cmCascade       => 26,
        cmRedo          => 27,
    # Standard messages
        cmReceivedFocus     => 50,
        cmReleasedFocus     => 51,
        cmCommandSetChanged => 52,
        cmTimerExpired      => 58,
    # TScrollBar messages
        cmScrollBarChanged  => 53,
        cmScrollBarClicked  => 54,
    # TWindow select messages
        cmSelectWindowNum   => 55,
    # TListViewer messages
        cmListItemSelected  => 56,
    # TProgram messages
        cmScreenChanged     => 57,
    # Event masks
        #TODO positionalEvents    => evMouse & ~evMouseWheel,
        #TODO focusedEvents       => evKeyboard | evCommand;
    # BUTTON_TYPE
        bfNormal    => 0x00,
        bfDefault   => 0x01,
        bfLeftJust  => 0x02,
        bfBroadcast => 0x04,
        bfGrabFocus => 0x08,
        cmRecordHistory => 60,
    };

    $msgbox = {
    #  Message box classes
        mfWarning      => 0x0000,       # Display a Warning box
        mfError        => 0x0001,       # Dispaly a Error box
        mfInformation  => 0x0002,       # Display an Information Box
        mfConfirmation => 0x0003,       # Display a Confirmation Box
    # Message box button flags
        mfYesButton    => 0x0100,       # Put a Yes button into the dialog
        mfNoButton     => 0x0200,       # Put a No button into the dialog
        mfOKButton     => 0x0400,       # Put an OK button into the dialog
        mfCancelButton => 0x0800,       # Put a Cancel button into the dialog
    };

    # Standard Yes, No, Cancel dialog
    $msgbox->{mfYesNoCancel}  = $msgbox->{mfYesButton} + $msgbox->{mfNoButton} + $msgbox->{mfCancelButton};
    # Standard OK, Cancel dialog
    $msgbox->{mfOKCancel}     = $msgbox->{mfOKButton} + $msgbox->{mfCancelButton};

}

our @EXPORT = ('tnew', 'TRect');
our %EXPORT_TAGS=(
    keys     => [ keys %$keys ],
    commands => [ keys %$commands ],
    msgbox   => [ keys %$msgbox ],
);
our @EXPORT_OK = ((keys %$keys), (keys %$commands), (keys %$msgbox));

use constant $keys;
use constant $commands;
use constant $msgbox;

1;

