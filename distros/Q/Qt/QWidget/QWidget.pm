package QWidget;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;
require QObject;
require QEvent;
require QFont;
require QPaintDevice;
require QPixmap;
require QPoint;
require QRect;
require QSize;

@ISA = qw(Exporter DynaLoader QObject QPaintDevice);
@EXPORT = qw(%FocusPolicy %WFlags);

$VERSION = '0.03';
bootstrap QWidget $VERSION;

1;
__END__

=head1 NAME

QWidget - Interface to the Qt QWidget class

=head1 SYNOPSIS

C<use QWidget;>

Inherits QObject and QPaintDevice.

Requires QEvent, QFont, QPixmap, QPoint, QRect, and QSize.

=head2 Member functions

new,
adjustSize,
backgroundColor,
backgroundPixmap,
caption,
childrenRect,
clearFocus,
close,
drawText,
erase,
focusPolicy,
font,
foregroundColor,
frameGeometry,
geometry,
grabKeyboard,
grabMouse,
hasFocus,
hasMouseTracking,
height,
hide,
icon,
iconText,
iconify,
isActiveWindow,
isDesktop,
isEnabled,
isFocusEnabled,
isModal,
isPopup,
isTopLevel,
isUpdatesEnabled,
isVisible,
keyboardGrabber,
lower,
mapFromGlobal,
mapFromParent,
mapToGlobal,
mapToParent,
maximumSize,
minimumSize,
mouseGrabber,
move,
pos,
raise,
recreate,
rect,
releaseKeyboard,
releaseMouse,
repaint,
resize,
scroll,
setActiveWindow,
setBackgroundColor,
setBackgroundPixmap,
setCaption,
setEnabled,
setFixedSize,
setFocus,
setFocusPolicy,
setFont,
setGeometry,
setIcon,
setIconText,
setMaximumSize,
setMinimumSize,
setMouseTracking,
setSizeIncrement,
setStyle,
setUpdatesEnabled,
show,
size,
sizeHint,
sizeIncrement,
style,
topLevelWidget,
update,
width,
winId,
x,
y

=head2 Virtual functions

mouseMoveEvent, mousePressEvent, mouseReleaseEvent, paintEvent, resizeEvent

=head1 DESCRIPTION

Every function made available to Perl is meant to be interfaced identically
to C++ Qt.

=head1 EXPORTED

The C<%FocusPolicy> and C<%WFlags> hashes are exported into the user's
namespace.

C<%FocusPolicy> contains all of the constants in QWidget that end in Focus.
That trailing I<Focus> is removed from the end of the keys for brevity.

The C<%WFlags> hash is much more involved. It contains all of the
C<WState_*>, C<WType_*>, and C<WStyle_*> flags, as well as quite a few
others that begin with W. You can get a full list of them from
F<qwindefs.h>.

But you won't find these constants exactly as they're spelled out in there.
I've stripped all the leading W's, for example. And all of the constants
which have an underscore in them have been split up into two components
based on the underscore. I think a few examples are in order.

    Was: WStyle_NormalBorder
    Now: $WFlags{Style}{NormalBorder}
    Was: WState_TrackMouse
    Now: $WFlags{State}{TrackMouse}
    Was: WPaintDesktop
    Now: $WFlags{PaintDesktop}

You can hopefully figure out the rest yourself.

=head1 SEE ALSO

QWidget(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
