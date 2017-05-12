package QPopupMenu;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QGlobal;

require QMenuData;
require QPoint;
require QTableView;

@ISA = qw(DynaLoader QTableView QMenuData);

$VERSION = '0.02';
bootstrap QPopupMenu $VERSION;

1;
__END__

=head1 NAME

QPopupMenu - Interface to the Qt QPopupMenu class

=head1 SYNOPSIS

C<use QPopupMenu;>

Inherits QTableView and QMenuData.

Requires QPoint.

=head2 Member functions

new,
popup

=head1 DESCRIPTION

What you see is what you get.

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
