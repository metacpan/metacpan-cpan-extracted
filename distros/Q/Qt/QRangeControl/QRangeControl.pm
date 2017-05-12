package QRangeControl;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

@ISA = qw(DynaLoader Qt::Hash);

$VERSION = '0.03';
bootstrap QRangeControl $VERSION;

1;
__END__

=head1 NAME

QRangeControl - Interface to the Qt QRangeControl class

=head1 SYNOPSIS

C<use QRangeControl;>

=head2 Member functions

new,
addLine,
addPage,
lineStep,
maxValue,
minValue,
pageStep,
setRange,
setSteps,
setValue,
subtractLine,
subtractPage,
value

=head1 DESCRIPTION

What you see is what you get

=head1 SEE ALSO

qrangecontrol(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
