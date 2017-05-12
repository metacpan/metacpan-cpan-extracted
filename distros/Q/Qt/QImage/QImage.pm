package QImage;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

@ISA = qw(DynaLoader Qt::Hash);

$VERSION = '0.02';
bootstrap QImage $VERSION;

1;
__END__

=head1 NAME

QImage - Interface to the Qt QImage class

=head1 SYNOPSIS

C<use QImage;>

=head2 Member functions

=head1 DESCRIPTION

What you see is what you get.

=head1 SEE ALSO

QImage(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
