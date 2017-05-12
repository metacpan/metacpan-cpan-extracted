package QMenuData;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QObject;
require QPixmap;
require QPopupMenu;

@ISA = qw(DynaLoader);

$VERSION = '0.02';
bootstrap QMenuData $VERSION;

1;
__END__

=head1 NAME

QMenuData - Interface to the Qt QMenuData class

=head1 SYNOPSIS

C<use QMenuData;>

Requires QObject, QPixmap and QPopupMenu.

=head2 Member functions

new,
accel,
changeItem,
clear,
connectItem,
count,
disconnectItem,
idAt,
indexOf,
insertItem,
insertSeparator,
isItemChecked,
isItemEnabled,
pixmap,
removeItem,
removeItemAt,
setAccel,
setId,
setItemChecked,
setItemEnabled,
text,
updateItem

=head1 DESCRIPTION

What you see is what you get.

=head1 NOTES

findItem() is not, and will not be, interfaced. The 'member' argument of
insertItem() should not have a SLOT() or SIGNAL() around it. That's a
PerlQt no-no. Be sure to see L<QObject(3)> for info.

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
