package QWMatrix;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QPoint;
require QPointArray;
require QRect;

@ISA = qw(DynaLoader Qt::Hash);

$VERSION = '0.02';
bootstrap QWMatrix $VERSION;

1;
__END__

=head1 NAME

QWMatrix - Interface to the Qt QWMatrix class

=head1 SYNOPSIS

C<use QWMatrix;>

Requires QPoint, QPointArray, and QRect.

=head2 Member functions

new,
dx,
dy,
invert,
m11,
m12,
m21,
m22,
map,
reset,
rotate,
scale,
shear,
setMatrix,
translate

=head1 DESCRIPTION

Except for the operators, fully interfaced.

=head1 SEE ALSO

QWMatrix(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>

