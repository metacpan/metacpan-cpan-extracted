package QBitmap;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QPixmap;
require QSize;
require QWMatrix;

@ISA = qw(DynaLoader QPixmap);

$VERSION = '0.03';
bootstrap QBitmap $VERSION;

1;
__END__

=head1 NAME

QBitmap - Interface to the Qt QBitmap class

=head1 SYNOPSIS

C<use QBitmap;>

Inherits QPixmap.

Requires QSize and QWMatrix.

=head2 Member functions

new, xForm

=head1 DESCRIPTION

What you see is what you get.

=head1 SEE ALSO

QBitmap(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
