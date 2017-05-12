package QSize;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QPoint;

@ISA = qw(DynaLoader Qt::Hash);

$VERSION = '0.02';
bootstrap QSize $VERSION;

1;
__END__

=head1 NAME

QSize - Interface to the Qt QSize class

=head1 SYNOPSIS

Requires QPoint.

=head2 Member functions

new,
height,
isEmpty,
isNull,
isValid,
setHeight,
setWidth,
width

=head1 DESCRIPTION

Rumors about the lack of operators in PerlQt's QSize are true!

=head1 SEE ALSO

QSize(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
