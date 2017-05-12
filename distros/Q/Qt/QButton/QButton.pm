package QButton;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QPixmap;
require QWidget;

@ISA = qw(DynaLoader QWidget);

$VERSION = '0.02';
bootstrap QButton $VERSION;

1;
__END__

=head1 NAME

QButton - Interface to the Qt QButton class

=head1 SYNOPSIS

C<use QButton;>

Inherits QWidget.

Requires QPixmap.

=head2 Member functions

new

=head1 DESCRIPTION

=over 4

=item $button = QButton->new(parent = undef, name = undef)

Direct interface.

=back

=head1 SEE ALSO

QButton(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
