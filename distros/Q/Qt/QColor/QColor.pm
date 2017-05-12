package QColor;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;
require QGlobal;

@ISA = qw(Exporter DynaLoader Qt::Hash);
@EXPORT = qw($color0 $color1 $black $white $darkGray $gray $lightGray $red
	     $green $blue $cyan $magenta $yellow $darkRed $darkGreen $darkBlue
	     $darkCyan $darkMagenta $darkYellow

	     %Spec

	     &qBlue &qGray &qGreen &qRgb &qRed);

$VERSION = '0.02';
bootstrap QColor $VERSION;

1;
__END__

=head1 NAME

QColor - Interface to the Qt QColor class

=head1 SYNOPSIS

C<use QColor;>

=head2 Member functions

new,
alloc,
blue,
dark,
green,
hsv,
isDirty,
isValid,
light,
pixel,
red,
rgb,
setHsv,
setNamedColor,
setRgb

=head2 Static functions

cleanup,
currentAllocContext,
destroyAllocContext,
enterAllocContext,
initialize,
lazyAlloc,
leaveAllocContext,
maxColors,
numBitPlanes,
setLazyAlloc

=head2 Related functions

qBlue,
qGray,
qGreen,
qRed,
qRgb

=head1 DESCRIPTION

Every member of QColor, except the operators, has been interfaced
through this class.

=head1 EXPORTED

The following QColor objects are exported into the user's namespace:

$color0 $color1 $black $white $darkGray $gray $lightGray $red
$green $blue $cyan $magenta $yellow $darkRed $darkGreen $darkBlue
$darkCyan $darkMagenta $darkYellow

The following functions are exported into the user's namespace:

C<&qBlue>, C<&qGray>, C<&qGreen>, C<&qRed>, C<&qRgb>

=head1 SEE ALSO

QColor(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
