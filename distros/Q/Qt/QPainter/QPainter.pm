package QPainter;

use strict;
use vars qw($VERSION @ISA @EXPORT);
use QGlobal qw(%Align $SingleLine $DontClip $ExpandTabs $ShowPrefix $WordBreak
	       $GrayText $DontPrint

	       %RasterOp);

require Exporter;
require DynaLoader;

require QColor;
require QBrush;
require QFont;
require QFontInfo;
require QFontMetrics;
require QPaintDevice;
require QPen;
require QPicture;
require QPixmap;
require QPoint;
require QPointArray;
require QRect;
require QRegion;
require QWMatrix;

@ISA = qw(Exporter DynaLoader Qt::Hash);
@EXPORT = qw(%Align $SingleLine $DontClip $ExpandTabs $ShowPrefix $WordBreak
	     $GrayText $DontPrint

	     %RasterOp %BGMode);

$VERSION = '0.03';
bootstrap QPainter $VERSION;

1;
__END__

=head1 NAME

QPainter - Interface to the Qt QPainter class

=head1 SYNOPSIS

C<use QPainter;>

Requires QColor, QBrush, QFont, QFontInfo, QFontMetrics, QPaintDevice,
QPen, QPicture, QPixmap, QPoint, QPointArray, QRect, QRegion, QWMatrix

=head2 Member functions

new,
backgroundColor,
backgroundMode,
begin,
boundingRect,
brushOrigin,
clipRegion,
device,
drawArc,
drawChord,
drawEllipse,
drawLine,
drawLineSegments,
drawPie,
drawPixmap,
drawPoint,
drawPolygon,
drawPolyline,
drawQuadBezier,
drawRect,
drawRoundRect,
drawText,
drawWinFocusRect,
end,
eraseRect,
fillRect,
font,
fontInfo,
fontMetrics,
hasClipping,
hasViewXForm,
hasWorldXForm,
isActive,
lineTo,
moveTo,
pen,
rasterOp,
resetXForm,
restore,
rotate,
save,
scale,
setBackgroundColor,
setBackgroundMode,
setBrush,
setBrushOrigin,
setClipping,
setClipRect,
setClipRegion,
setFont,
setPen,
setRasterOp,
setViewXForm,
setViewport,
setWindow,
setWorldMatrix,
setWorldXForm,
shear,
translate,
viewport,
window,
worldMatrix,
xForm,
xFormDev

=head1 DESCRIPTION

All functions listed have every prototype version supported, mostly.
Any internal arguments are unavailable to PerlQt programmers.

=head1 EXPORTED

The following variables are exported into the user's namespace on
behalf of C<QPainter::drawText()> from F<qwindefs.h>

%Align $SingleLine $DontClip $ExpandTabs $ShowPrefix $WordBreak
$GrayText $DontPrint

The C<%BGMode> and C<%RasterOp> hashes are also exported. C<%BGMode>
contains the values in the BGMode enum in F<qpainter.h> without the
trailing Mode, and C<%RasterOp> contains the values in the RasterOp
enum in F<qwindefs.h> without the trailing ROP.

=head1 SEE ALSO

qpainter(3qt), QColor(3), QBrush(3), QFont(3), QPen(3)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
