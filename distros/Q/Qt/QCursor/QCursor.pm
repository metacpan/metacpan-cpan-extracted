package QCursor;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;
require QGlobal;

require QBitmap;
require QPoint;

@ISA = qw(Exporter DynaLoader Qt::Hash);
@EXPORT = qw(%Cursor);

$VERSION = '0.02';
bootstrap QCursor $VERSION;

1;
__END__

=head1 NAME

QCursor - Interface to the Qt QCursor class

=head1 SYNOPSIS

C<use QCursor;>

Require QBitmap and QPoint.

=head2 Member functions

new,
bitmap,
hotSpot,
mask,
pos,
setPos

=head1 DESCRIPTION

What you see is what you get

=head1 EXPORTED

The C<%Cursor> hash is exported into the user's namespace. It contains
all of the global cursors (C<arrowCursor>, C<crossCursor>, etc..) without
the Cursor suffix (C<$Cursor{arrow}>, C<$Cursor{cross}>, etc...)

=head1 SEE ALSO

QCursor(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
