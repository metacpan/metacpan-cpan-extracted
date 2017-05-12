package QScrollBar;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;
require QGlobal;

require QRangeControl;
require QWidget;

@ISA = qw(Exporter DynaLoader QWidget QRangeControl);
@EXPORT = qw(%Orientation);

$VERSION = '0.02';
bootstrap QScrollBar $VERSION;

1;
__END__

=head1 NAME

QScrollBar - Interface to the Qt QScrollBar class

=head1 SYNOPSIS

C<use QScrollBar;>

Inherits QWidget and QRangeControl.

=head2 Member functions

new,
orientation,
setOrientation,
setRange,
setTracking,
setValue,
tracking

=head1 DESCRIPTION

Nothing unusual, everything listed is interfaced.

=head1 EXPORTED

The C<%Orientation> hash is exported into the user's namespace. The elements
of C<%Orientation> are C<Horizontal> and C<Vertical>, and they represent
the possible orientations of the scrollbar.

=head1 SEE ALSO

QScrollBar(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>
