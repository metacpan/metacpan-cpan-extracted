package QAccel;

use strict;
use vars qw($VERSION @ISA @EXPORT);
use QGlobal qw(%Key $SHIFT $CTRL $ALT $ASCII_ACCEL);

require Exporter;
require DynaLoader;
require QObject;

@ISA = qw(Exporter DynaLoader QObject);
@EXPORT = qw(%Key $SHIFT $CTRL $ALT $ASCII_ACCEL);

$VERSION = '0.03';
bootstrap QAccel $VERSION;

1;
__END__

=head1 NAME

QAccel - Interface to the Qt QAccel class

=head1 SYNOPSIS

C<use QAccel;>

Inherits QObject.

=head2 Member functions

new,
clear,
connectItem,
count,
disconnectItem,
findKey,
insertItem,
isEnabled,
isItemEnabled,
key,
removeItem,
setEnabled,
setItemEnabled

=head1 DESCRIPTION

The complete class is implemented. Do not try to use SIGNAL() or SLOT().

=head1 EXPORTED

The C<%Key> hash is exported into the caller's namespace, the elements
represent the values of the Key_* macros in C++ Qt. For example, the
C<Key_Space> value in C++ would be accessible as C<$Key{Space}> in Perl,
the C<Key_Q> value would be accessible with C<$Key{Q}>, and so on.

The scalar values $SHIFT, $CTRL, $ALT, and $ASCII_ACCEL are also exported,
and have the same value and function as their C++ counterparts.

=head1 SEE ALSO

QAccel(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
