package QLCDNumber;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;
require QFrame;

@ISA = qw(Exporter DynaLoader QFrame);
@EXPORT = qw();

$VERSION = '0.02';
bootstrap QLCDNumber $VERSION;

1;
__END__

=head1 NAME

QLCDNumber - Interface to the Qt QLCDNumber class

=head1 SYNOPSIS

C<use QLCDNumber;>

Inherits QFrame.

=head2 Member functions

new,
checkOverflow,
display,
intValue,
mode,
numDigits,
setBinMode,
setDecMode,
setHexMode,
setMode,
setNumDigits,
setOctMode,
setSmallDecimalPoint,
smallDecimalPoint,
value

=head1 DESCRIPTION

What you see is what you get.

=head1 SEE ALSO

QLCDNumber(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
