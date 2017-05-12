package QPixmap;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;

require QBitmap;
require QColor;
require QImage;
require QPaintDevice;
require QWMatrix;

@ISA = qw(Exporter DynaLoader QPaintDevice);
@EXPORT = qw(%ColorMode);

$VERSION = '0.03';
bootstrap QPixmap $VERSION;

1;
__END__

=head1 NAME

QPixmap - Interface to the Qt QPixmap class

=head1 SYNOPSIS

C<use QPixmap;>

Inherits QPaintDevice.

Requires QBitmap, QColor, QImage, and QWMatrix.

=head2 Member functions

new,
defaultDepth,
depth,
detach,
fill,
height,
imageFormat,
isOptimized,
isQBitmap,
load,
loadFromData,
isGloballyOptimized,
isNull,
optimize,
optimizeGlobally,
rect,
resize,
save,
size,
trueMatrix,
width,
xForm

=head1 DESCRIPTION

Whatever has been interfaced is fully interfaced.

The loadFromData function does not take a 'len' argument. All the other
arguments are normal and in the original order.

=head1 EXPORTED

The C<%ColorMode> hash is exported into the user's namespace. The elements
of C<%ColorMode> contain all the constants in QPainter, which come from the
QPainter::ColorMode enum.

=head1 SEE ALSO

QPixmap(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
