package QPoint;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

@ISA = qw(DynaLoader Qt::Hash);

$VERSION = '0.02';
bootstrap QPoint $VERSION;

1;
__END__

=head1 NAME

QPoint - Interface to the Qt QPoint class

=head1 SYNOPSIS

C<use QPoint;>

=head2 Member functions

new, setX, setY, x, y

=head1 DESCRIPTION

Most of QPoint is operators, and I haven't interfaced the operators yet.
Everything else, what little there is of it, is interfaced.

=head1 RESTRICTIONS

The functions rx() and ry() will not be interfaced to PerlQt unless there
is sufficient demand for it, or lvalue Perl XSUBs become a reality.

=head1 SEE ALSO

QPoint(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
