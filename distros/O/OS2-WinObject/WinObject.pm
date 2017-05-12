{		# Peacify some warnings
  package HOBJECT;
  package HWND;
  package HBITMAP;
  package HPOINTER;
}

package OS2::WinObject;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

require Exporter;
require DynaLoader;
#use AutoLoader;

@ISA = qw(Exporter DynaLoader);

@HOBJECT_or_error::ISA	 = 'HOBJECT';
@HWND_or_error::ISA	 = 'HWND';
@HBITMAP_or_error::ISA	 = 'HBITMAP';
@HPOINTER_or_error::ISA	 = 'HPOINTER';

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use OS2::WinObject ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	CO_FAILIFEXISTS
	CO_REPLACEIFEXISTS
	CO_UPDATEIFEXISTS
	OPEN_AUTO
	OPEN_BATTERY
	OPEN_CONTENTS
	OPEN_DEFAULT
	OPEN_DETAILS
	OPEN_HELP
	OPEN_PALETTE
	OPEN_PROMPTDLG
	OPEN_RUNNING
	OPEN_SETTINGS
	OPEN_STATUS
	OPEN_TREE
	OPEN_USER
	PMERR_INVALID_FLAG
	PMERR_INVALID_HPTR
	PMERR_INVALID_HWND
	PMERR_INV_HDC
	PMERR_PARAMETER_OUT_OF_RANGE
	PMERR_WPDSERVER_IS_ACTIVE
	PMERR_WPDSERVER_NOT_STARTED
	SWP_ACTIVATE
	SWP_DEACTIVATE
	SWP_EXTSTATECHANGE
	SWP_FOCUSACTIVATE
	SWP_FOCUSDEACTIVATE
	SWP_HIDE
	SWP_MAXIMIZE
	SWP_MINIMIZE
	SWP_MOVE
	SWP_NOADJUST
	SWP_NOAUTOCLOSE
	SWP_NOREDRAW
	SWP_RESTORE
	SWP_SHOW
	SWP_SIZE
	SWP_ZORDER
	CopyObject
	CreateObject
	DeregisterObjectClass
	DestroyObject
	EnumObjectClasses
	FreeFileIcon
	IsSOMDDReady
	IsWPDServerReady
	LoadFileIcon
	MoveObject
	OpenObject
	QueryActiveDesktopPathname
	QueryDesktopBkgnd
	QueryDesktopWindow
	QueryObject
	QueryObjectPath
	QueryObjectWindow
	QueryWindowPos
	RegisterObjectClass
	ReplaceObjectClass
	RestartSOMDD
	RestartWPDServer
	RestoreWindowPos
	SaveObject
	SaveWindowPos
	SetDesktopBkgnd
	SetFileIcon
	SetMultWindowPos
	SetObjectData
	SetWindowPos
	ShutdownSystem
	StoreWindowPos
	ActiveDesktopPathname
	ObjectClasses
	ObjectPath
	WindowPos
	QuerySysValue
	SetSysValue
	SysValue
	SysValue_set
	_hwnd
  ) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = (

);
$VERSION = '0.02';

eval join ' (); sub ', '', grep !/[a-z]/, @EXPORT_OK, '{}';	# Put protos

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    #$AutoLoader::AUTOLOAD = $AUTOLOAD;
	    #goto &AutoLoader::AUTOLOAD;
		croak "Unknown OS2::WinObject function $constname called";
	}
	else {
		croak "Your vendor has not defined OS2::WinObject macro $constname";
	}
    }
    {  no strict 'refs';
       # Next line doesn't help with older Perls; in newers: no such warnings
       # local $^W = 0;		# Prototype mismatch: sub XXX vs ()
       if ($] >= 5.00561) {	# Fixed between 5.005_53 and 5.005_61
	 *$AUTOLOAD = sub () { $val };
       } else {
	 *$AUTOLOAD = sub { $val };
       }
    }
    goto &$AUTOLOAD;
}

bootstrap OS2::WinObject $VERSION;

# Preloaded methods go here.

my %SV_constants;
my $init;

sub init_SV_constants {
  return if $init++;
  %SV_constants = ( <<EOS =~ /\b(\w+)\s+(\d+)\b/g );
   SWAPBUTTON		0
   DBLCLKTIME		1
   CXDBLCLK		2
   CYDBLCLK		3
   CXSIZEBORDER		4
   CYSIZEBORDER		5
   ALARM		6
   CURSORRATE		9
   FIRSTSCROLLRATE	10
   SCROLLRATE		11
   NUMBEREDLISTS	12
   WARNINGFREQ		13
   NOTEFREQ		14
   ERRORFREQ		15
   WARNINGDURATION	16
   NOTEDURATION		17
   ERRORDURATION	18
   CXSCREEN		20
   CYSCREEN		21
   CXVSCROLL		22
   CYHSCROLL		23
   CYVSCROLLARROW	24
   CXHSCROLLARROW	25
   CXBORDER		26
   CYBORDER		27
   CXDLGFRAME		28
   CYDLGFRAME		29
   CYTITLEBAR		30
   CYVSLIDER		31
   CXHSLIDER		32
   CXMINMAXBUTTON	33
   CYMINMAXBUTTON	34
   CYMENU		35
   CXFULLSCREEN		36
   CYFULLSCREEN		37
   CXICON		38
   CYICON		39
   CXPOINTER		40
   CYPOINTER		41
   DEBUG		42
   CMOUSEBUTTONS	43
   CPOINTERBUTTONS	43
   POINTERLEVEL		44
   CURSORLEVEL		45
   TRACKRECTLEVEL	46
   CTIMERS		47
   MOUSEPRESENT		48
   CXBYTEALIGN		49
   CXALIGN		49
   CYBYTEALIGN		50
   CYALIGN		50
   DESKTOPWORKAREAYTOP	51
   DESKTOPWORKAREAYBOTTOM	52
   DESKTOPWORKAREAXRIGHT	53
   DESKTOPWORKAREAXLEFT		54
   NOTRESERVED		56
   EXTRAKEYBEEP		57
   SETLIGHTS		58
   INSERTMODE		59
   MENUROLLDOWNDELAY	64
   MENUROLLUPDELAY	65
   ALTMNEMONIC		66
   TASKLISTMOUSEACCESS	67
   CXICONTEXTWIDTH	68
   CICONTEXTLINES	69
   CHORDTIME		70
   CXCHORD		71
   CYCHORD		72
   CXMOTIONSTART	73
   CYMOTIONSTART	74
   BEGINDRAG		75
   ENDDRAG		76
   SINGLESELECT		77
   OPEN			78
   CONTEXTMENU		79
   CONTEXTHELP		80
   TEXTEDIT		81
   BEGINSELECT		82
   ENDSELECT		83
   BEGINDRAGKB		84
   ENDDRAGKB		85
   SELECTKB		86
   OPENKB		87
   CONTEXTMENUKB	88
   CONTEXTHELPKB	89
   TEXTEDITKB		90
   BEGINSELECTKB	91
   ENDSELECTKB		92
   ANIMATION		93
   ANIMATIONSPEED	94
   MONOICONS		95
   KBDALTERED		96
   PRINTSCREEN		97
   LOCKSTARTINPUT	98
   DYNAMICDRAG		99
   CSYSVALUES		100
EOS
}

sub SysValue ($;$) {
  init_SV_constants;
  my $v = $SV_constants{shift()};
  return QuerySysValue($v) unless @_;
  QuerySysValue($v,shift);
}

sub SysValue_set ($$;$) {
  init_SV_constants;
  my $v = $SV_constants{shift()};
  return SetSysValue($v, shift) unless @_ > 1;
  SetSysValue($v,shift, shift);
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

OS2::WinObject - Perl extension for access the subset of C<Win*> API
for dealing with WPS objects.

=head1 SYNOPSIS

  use OS2::WinObject ':all';

  $desktop = QueryObject '<WP_DESKTOP>';
  OpenObject $desktop, OPEN_SETTINGS, 1
    or die "Can't open DESKTOP settings notebook: $!";
  $w = SysValue 'CXSCREEN';
  ($x,$y,$w,$h,$fl,$b,$s) = WindowPos QueryDesktopWindow;
  $p = ActiveDesktopPathname;
  $p = ObjectPath $desktop;

=head1 DESCRIPTION

Most reasonable things to do with WPS objects require access via the SOM/DSOM
subsystem.  However, C<Win*> API contains some (very primitive) means to deal
with objects via their I<handles>, delegating the actual work to WPS.

When choosing these functions, the principal target was completeness; many of
these function are useless except in extremely bizzare circumstances.

=head2 EXPORT

None by default.

=head2 Exportable constants

  CO_FAILIFEXISTS
  CO_REPLACEIFEXISTS
  CO_UPDATEIFEXISTS
  OPEN_AUTO
  OPEN_BATTERY
  OPEN_CONTENTS
  OPEN_DEFAULT
  OPEN_DETAILS
  OPEN_HELP
  OPEN_PALETTE
  OPEN_PROMPTDLG
  OPEN_RUNNING
  OPEN_SETTINGS
  OPEN_STATUS
  OPEN_TREE
  OPEN_USER
  PMERR_INVALID_FLAG
  PMERR_INVALID_HPTR
  PMERR_INVALID_HWND
  PMERR_INV_HDC
  PMERR_PARAMETER_OUT_OF_RANGE
  PMERR_WPDSERVER_IS_ACTIVE
  PMERR_WPDSERVER_NOT_STARTED
  SWP_ACTIVATE
  SWP_DEACTIVATE
  SWP_EXTSTATECHANGE
  SWP_FOCUSACTIVATE
  SWP_FOCUSDEACTIVATE
  SWP_HIDE
  SWP_MAXIMIZE
  SWP_MINIMIZE
  SWP_MOVE
  SWP_NOADJUST
  SWP_NOAUTOCLOSE
  SWP_NOREDRAW
  SWP_RESTORE
  SWP_SHOW
  SWP_SIZE
  SWP_ZORDER

=head2 Exportable functions (similar to C)

When accessing the following functions from Perl, prefix C<Win> should be removed.

  HOBJECT WinCopyObject (HOBJECT hObjectofObject, HOBJECT hObjectofDest,
    ULONG ulReserved {SANE DEFAULT})
  HOBJECT WinCreateObject (PCSZ pszClassName, PCSZ pszTitle, PCSZ pszSetupString,
    PCSZ pszLocation, ULONG ulFlags)
  BOOL WinDeregisterObjectClass (PCSZ pszClassName)
  BOOL WinDestroyObject (HOBJECT hObject)
  BOOL WinEnumObjectClasses (POBJCLASS pObjClass, PULONG pulSize)
  BOOL WinFreeFileIcon (HPOINTER hptr)
  BOOL WinIsSOMDDReady (void )
  BOOL WinIsWPDServerReady (void )
  HPOINTER WinLoadFileIcon (PCSZ pszFileName, BOOL fPrivate)
  HOBJECT WinMoveObject (HOBJECT hObjectofObject, HOBJECT hObjectofDest,
    ULONG ulReserved {SANE DEFAULT})
  BOOL WinOpenObject (HOBJECT hObject, ULONG ulView, BOOL fFlag)
  BOOL WinQueryActiveDesktopPathname (PSZ pszPathName, ULONG ulSize)
  BOOL WinQueryDesktopBkgnd (HWND hwndDesktop, PDESKTOP pdsk)
  HWND WinQueryDesktopWindow (HAB hab {SANE DEFAULT}, HDC hdc {SANE DEFAULT})
  HOBJECT WinQueryObject (PCSZ pszObjectID)
  BOOL WinQueryObjectPath (HOBJECT hobject, PSZ pszPathName, ULONG ulSize)
  HWND WinQueryObjectWindow (HWND hwndDesktop {SANE DEFAULT})
  LONG WinQuerySysValue(LONG iSysValue, HWND hwndDesktop {SANE DEFAULT})
  BOOL WinQueryWindowPos (HWND hwnd, PSWP pswp)
  BOOL WinRegisterObjectClass (PCSZ pszClassName, PCSZ pszModName)
  BOOL WinReplaceObjectClass (PCSZ pszOldClassName, PCSZ pszNewClassName,
    BOOL fReplace)
  ULONG WinRestartSOMDD (BOOL fState)
  ULONG WinRestartWPDServer (BOOL fState)
  BOOL WinRestoreWindowPos (PCSZ pszAppName, PCSZ pszKeyName, HWND hwnd)
  BOOL WinSaveObject (HOBJECT hObject, BOOL fAsync)
  BOOL WinSaveWindowPos (HSAVEWP hsvwp, PSWP pswp, ULONG cswp)
  HBITMAP WinSetDesktopBkgnd (HWND hwndDesktop, __const__ DESKTOP *pdskNew)
  BOOL WinSetFileIcon (PCSZ pszFileName, __const__ ICONINFO *pIconInfo)
  BOOL WinSetMultWindowPos (HAB hab, __const__ SWP *pswp, ULONG cswp)
  BOOL WinSetObjectData (HOBJECT hObject, PCSZ pszSetupString)
  BOOL WinSetSysValue (LONG iSysValue, LONG lValue, HWND hwndDesktop);
  BOOL WinSetWindowPos (HWND hwnd, HWND hwndInsertBehind, LONG x, LONG y,
    LONG cx, LONG cy, ULONG fl)
  BOOL WinShutdownSystem (HAB hab {SANE DEFAULT}, HMQ hmq {SANE DEFAULT})
  BOOL WinStoreWindowPos (PCSZ pszAppName, PCSZ pszKeyName, HWND hwnd)

=head2 Exportable functions (shortcuts)

The functions

  BOOL WinEnumObjectClasses (POBJCLASS pObjClass, PULONG pulSize)
  BOOL WinQueryActiveDesktopPathname (PSZ pszPathName, ULONG ulSize)
  BOOL WinQueryObjectPath (HOBJECT hobject, PSZ pszPathName, ULONG ulSize)
  BOOL WinQueryWindowPos (HWND hwnd, PSWP pswp)

have easier-to-use counterparts:

  %classDLL = ObjectClasses;
  $path = ActiveDesktopPathname;
  $path = ObjectPath($hobject);
  ($x,$y,$w,$h,$flags,$hwndBehindOf,$hwndMy,$reserved1,$reserved2)
     = WindowPos($hwnd) or die "Failure of WindowPos()";

ObjectClasses() returns a hash C<class =E<gt> DLLname>; $flags is a
combination of C<SWP_*> constants.

Note that the functions

  LONG WinQuerySysValue(LONG iSysValue, HWND hwndDesktop {SANE DEFAULT})
  BOOL WinSetSysValue (LONG iSysValue, LONG lValue, HWND hwndDesktop)

has the desktop argument at the last position, while the C counterparts
have it as the first argument (to enable the default value for the desktop).
The easier-to-use counterparts of these functions are

  $value = SysValue($string);
  SysValue_set($string, $value) or die "Cannot set: $^E";

here $string is one of

 SWAPBUTTON DBLCLKTIME CXDBLCLK CYDBLCLK CXSIZEBORDER CYSIZEBORDER ALARM
 CURSORRATE FIRSTSCROLLRATE SCROLLRATE NUMBEREDLISTS WARNINGFREQ NOTEFREQ
 ERRORFREQ WARNINGDURATION NOTEDURATION ERRORDURATION CXSCREEN CYSCREEN
 CXVSCROLL CYHSCROLL CYVSCROLLARROW CXHSCROLLARROW CXBORDER CYBORDER
 CXDLGFRAME CYDLGFRAME CYTITLEBAR CYVSLIDER CXHSLIDER CXMINMAXBUTTON
 CYMINMAXBUTTON CYMENU CXFULLSCREEN CYFULLSCREEN CXICON CYICON CXPOINTER
 CYPOINTER DEBUG CMOUSEBUTTONS CPOINTERBUTTONS POINTERLEVEL CURSORLEVEL
 TRACKRECTLEVEL CTIMERS MOUSEPRESENT CXBYTEALIGN CXALIGN CYBYTEALIGN
 CYALIGN DESKTOPWORKAREAYTOP DESKTOPWORKAREAYBOTTOM DESKTOPWORKAREAXRIGHT
 DESKTOPWORKAREAXLEFT NOTRESERVED EXTRAKEYBEEP SETLIGHTS INSERTMODE
 MENUROLLDOWNDELAY MENUROLLUPDELAY ALTMNEMONIC TASKLISTMOUSEACCESS
 CXICONTEXTWIDTH CICONTEXTLINES CHORDTIME CXCHORD CYCHORD CXMOTIONSTART
 CYMOTIONSTART BEGINDRAG ENDDRAG SINGLESELECT OPEN CONTEXTMENU CONTEXTHELP
 TEXTEDIT BEGINSELECT ENDSELECT BEGINDRAGKB ENDDRAGKB SELECTKB OPENKB
 CONTEXTMENUKB CONTEXTHELPKB TEXTEDITKB BEGINSELECTKB ENDSELECTKB
 ANIMATION ANIMATIONSPEED MONOICONS KBDALTERED PRINTSCREEN LOCKSTARTINPUT
 DYNAMICDRAG CSYSVALUES    

(For the documentation of these values see L<Arguments to SysValue>.

=head2 Exportable functions (convenience)

_hwnd($integer) creates a suitable object given the integer window
handle.

=head2 Export tag

All the mentioned functions are exportable with the tag C<:all>.

=head2 Arguments to SysValue

The meaning of the argument to SysValue() is explained in the following
excerpt from the OS/2 Toolkit. Not all system values can be set with
WinSetSysValue; those that can be set are marked with an asterisk (*).
The actual string given to SysValue() should be stripped of the leading
C<SV_>.

=over 12  

=item C<SV_ALARM>

(*) TRUE if the alarm sound generated by WinAlarm is enabled; FALSE if the alarm sound is disabled. 

=item C<SV_ALTMNEMONIC>

(*) TRUE if the mnemonic is made up of KATAKANA characters; FALSE if the mnemonic is made up of ROMAN characters. 

=item C<SV_ANIMATION>

(*) TRUE when animation is set on. FALSE when animation is set off. 

=item C<SV_BEGINDRAG>

(*) Mouse begin drag (low word=mouse message id (WM_*), high word=keyboard control code (KC_*)). 

=item C<SV_BEGINDRAGKB>

(*) Keyboard begin drag (low word=virtual key code (VK_*), high word=keyboard control code (KC_*)). 

=item C<SV_BEGINSELECT>

(*) Mouse begin swipe select (low word=mouse message id (WM_*), high word=keyboard control code (KC_*)). 

=item C<SV_BEGINSELECTKB>

(*) Keyboard begin swipe select (low word=virtual key code (VK_*), high word=keyboard control code (KC_*)). 

=item C<SV_CICONTEXTLINES>

(*) Maximum number of lines that the icon text may occupy for a minimized window. 

=item C<SV_CONTEXTHELP>

(*) Mouse control for pop-up menu (low word=mouse message id (WM_*), high word=keyboard control code (KC_*)). 

=item C<SV_CONTEXTHELPKB>

(*) Keyboard control for pop-up menu (low word=virtual key code (VK_*), high word=keyboard control code (KC_*)). 

=item C<SV_CONTEXTMENU>

(*) Mouse request pop-up menu (low word=mouse message id (WM_*), high word=keyboard control code (KC_*)). 

=item C<SV_CONTEXTMENUKB>

(*) Keyboard request pop-up menu (low word=virtual key code (VK_*), high word=keyboard control code (KC_*)). 

=item C<SV_CMOUSEBUTTONS>

The number of buttons on the pointing device  (zero if no pointing device is installed). 

=item C<SV_CTIMERS>

Count of available timers. 

=item C<SV_CURSORLEVEL>

The cursor hide level. 

=item C<SV_CURSORRATE>

(*) Cursor blink rate, in milliseconds. 

=item C<SV_CXBORDER>

Width of the nominal-width border. 

=item C<SV_CXBYTEALIGN>

Horizontal count of pels for alignment. 

=item C<SV_CXDBLCLK>

(*) Width of the pointing device double-click sensitive area. The default is the system-font character width. 

=item C<SV_CXDLGFRAME>

Width of the dialog-frame border. 

=item C<SV_CXFULLSCREEN>

Width of the client area when the window is full screen. 

=item C<SV_CXHSCROLLARROW>

Width of the horizontal scroll-bar arrow bit maps. 

=item C<SV_CXHSLIDER>

Width of the horizontal scroll-bar thumb. 

=item C<SV_CXICON>

Icon width. 

=item C<SV_CXICONTEXTWIDTH>

(*) Maximum number of characters per line allowed in the icon text for a minimized window. 

=item C<SV_CXMINMAXBUTTON>

Width of the minimize/maximize buttons. 

=item C<SV_CXMOTIONSTART>

(*) The number of pels that a pointing device must be moved in the horizontal direction, while the button is depressed, before a WM_BUTTONxMOTIONSTR 
message is sent. 

=item C<SV_CXPOINTER>

Pointer width. 

=item C<SV_CXSCREEN>

Width of the screen. 

=item C<SV_CXSIZEBORDER>

(*) Width of the sizing border. 

=item C<SV_CXVSCROLL>

Width of the vertical scroll-bar. 

=item C<SV_CYBORDER>

Height of the nominal-width border. 

=item C<SV_CYBYTEALIGN>

Vertical count of pels for alignment. 

=item C<SV_CYDBLCLK>

(*) Height of the pointing device double-click sensitive area. The default is half the height of the system font character height. 

=item C<SV_CYDLGFRAME>

Height of the dialog-frame border. 

=item C<SV_CYFULLSCREEN>

Height of the client area when the window is full screen (excluding menu height). 

=item C<SV_CYHSCROLL>

Height of the horizontal scroll-bar. 

=item C<SV_CYICON>

Icon height. 

=item C<SV_CYMENU>

Height of the single-line menu height. 

=item C<SV_CYMINMAXBUTTON>

Height of the minimize/maximize buttons. 

=item C<SV_CYMOTIONSTART>

(*) The number of pels that a pointing device must be moved in the vertical direction, while the button is depressed, before a WM_BUTTONxMOTIONSTR 
message is sent. 

=item C<SV_CYPOINTER>

Pointer height. 

=item C<SV_CYSCREEN>

Height of the screen. 

=item C<SV_CYSIZEBORDER>

(*) Height of the sizing border. 

=item C<SV_CYTITLEBAR>

Height of the caption. 

=item C<SV_CYVSCROLLARROW>

Height of the vertical scroll-bar arrow bit maps. 

=item C<SV_CYVSLIDER>

Height of the vertical scroll-bar thumb. 

=item C<SV_DBLCLKTIME>

(*) Pointing device double-click time, in milliseconds. 

=item C<SV_DEBUG>

FALSE indicates this is not a debug system. 

=item C<SV_ENDDRAG>

(*) Mouse end drag (low word=mouse message id (WM_*), high word=keyboard control code (KC_*)). 

=item C<SV_ENDDRAGKB>

(*) Keyboard end drag (low word=virtual key code (VK_*), high word=keyboard control code (KC_*)). 

=item C<SV_ENDSELECT>

(*) Mouse select or end swipe select (low word=mouse message id (WM_*), high word=keyboard control code (KC_*)). 

=item C<SV_ENDSELECTKB>

(*) Keybaord select or end swipe select (low word=virtual key code (VK_*), high word=keyboard control code (KC_*)). 

=item C<SV_ERRORDURATION>

(*) Duration for error alarms generated by WinAlarm. 

=item C<SV_ERRORFREQ>

(*) Frequency for error alarms generated by WinAlarm. 

=item C<SV_EXTRAKEYBEEP>

(*) When TRUE, the press of a key that does not exist on the Enhanced keyboard causes the system to generate a beep. 

=item C<SV_FIRSTSCROLLRATE>

(*) The delay (in milliseconds) before autoscrolling starts, when using a scroll bar. 

=item C<SV_INSERTMODE>

(*) TRUE if the system is in insert mode (for edit and multi-line edit controls); FALSE if in overtype mode. 
This system value is toggled by the system when the insert key is toggled, regardless of which window has the focus at the time. 

=item C<SV_KBDALTERED>

(*) Hardware ID of the newly attached keyboard. 

Note:  The OS/2 National Language Support is only loaded once per system IPL. The OS/2 NLS translation is based partially on the type of keyboard device 
attached to the system. There are two main keyboard device types: PC AT styled and Enhanced styled. Hot Plugging between these two types of devices may 
result in typing anomalies due to a mismatch in the NLS device tables loaded and that of the attached device. It is strongly recommended that keyboard hot 
plugging be limited to the device type that the system was IPL'd with. In addition, OS/2 support will default to the 101/102 key Enhanced keyboard if no 
keyboard or a NetServer Mode password was in use during system IPL. (See Category 4, IOCtls 77h and 7Ah for more information on keyboard devices and 
types.) 

=item C<SV_LOCKSTARTINPUT>

(*) TRUE when the type ahead function is enabled; FALSE when the type ahead function is disabled. 

=item C<SV_MENUROLLDOWNDELAY>

(*) The delay in milliseconds before displaying a pull down referred to from a submenu item, when the button is already down as the pointer moves onto the 
submenu item. 

=item C<SV_MENUROLLUPDELAY>

(*) The delay in milliseconds before hiding a pull down referred to from a submenu item, when the button is already down as the pointer moves off the 
submenu item. 

=item C<SV_MONOICONS>

(*) When TRUE preference is given to black and white icons when selecting which icon resource definition to use on the screen. Black and white icons may 
have more clarity than color icons on LCD and Plasma display screens. 

=item C<SV_MOUSEPRESENT>

When TRUE a mouse pointing device is attached to the system. 

=item C<SV_NOTEDURATION>

(*) Duration for note alarms generated by WinAlarm. 

=item C<SV_NOTEFREQ>

(*) Frequency for note alarms generated by WinAlarm. 

=item C<SV_OPEN>

(*) Mouse open (low word=mouse message id (WM_*), high word=keyboard control code (KC_*)). 

=item C<SV_OPENKB>

(*) Keyboard open (low word=virtual key code (VK_*), high word=keyboard control code (KC_*)). 

=item C<SV_POINTERLEVEL>

Pointer hide level. If the pointer level is zero, the pointer is visible. If it is greater than zero, the pointer is not visible. The WinShowPointer call is 
invoked to increment and decrement the SV_POINTERLEVEL, but its value cannot become negative. 

=item C<SV_PRINTSCREEN>

(*) TRUE when the Print Screen function is enabled; FALSE when the Print Screen function is disabled. 

=item C<SV_SCROLLRATE>

(*) The delay (in milliseconds) between scroll operations, when using a scroll bar. 

=item C<SV_SETLIGHTS>

(*) When TRUE, the appropriate light is set when the keyboard state table is set. 

=item C<SV_SINGLESELECT>

(*) Mouse select (low word=mouse message id (WM_*), high word=keyboard control code (KC_*)). 

=item C<SV_TASKLISTMOUSEACCESS>

(*) Determines whether the task list is displayed when mouse buttons 1 and 2 are pressed simultaneously, or when mouse button 2 is pressed by itself, or 
for no mouse gesture. 

=item C<SV_TEXTEDIT>

(*) Mouse begin direct name edit (low word=mouse message id (WM_*), high word=keyboard control code (KC_*)). 

=item C<SV_TEXTEDITKB>

(*) Keyboard begin direct name edit (low word=virtual key code (VK_*), high word=keyboard control code (KC_*)). 

=item C<SV_TRACKRECTLEVEL>

The hide level of the tracking rectangle (zero if visible, greater than zero if not). 

=item C<SV_SWAPBUTTON>

(*) TRUE if pointing device buttons are swapped. Normally, the pointing device buttons are set for right-handed use. Setting this value changes them for 
left-handed use. 
If TRUE, WM_LBUTTON* messages are returned when the user presses the right button, and WM_RBUTTON* messages are returned when the left button is 
pressed. Modifying this value affects the entire system. Applications should not normally read or set this value; users update this value by means of the user 
interface shell to suit their requirements. 

=item C<SV_WARNINGDURATION>

(*) Duration for warning alarms generated by WinAlarm. 

=item C<SV_WARNINGFREQ>

(*) Frequency for warning alarms generated by WinAlarm. 

=back

=head1 AUTHOR

Ilya Zakhrevich L<ilya@math.ohio-state.edu>.

=head1 SEE ALSO

perl(1), L<SOM>.

=cut
