package TUI::Dialogs::RadioButtons;
# ABSTRACT: Radio button cluster control based on TCluster

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT = qw(
  TRadioButtons
  new_TRadioButtons
);

use TUI::toolkit;
use TUI::toolkit::Types qw( :types );

use TUI::Dialogs::Cluster;

sub TRadioButtons() { __PACKAGE__ }
sub name() { 'TRadioButtons' }
sub new_TRadioButtons { __PACKAGE__->from( @_ ) }

extends TCluster;

# declare global variables
our $button = " ( ) ";

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->drawMultiBox( $button, " \x7" );
  return;
}

sub mark {    # $bool ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  return $item == $self->{value};
}

sub press {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  $self->{value} = $item;
  return;
}

sub movedTo {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  $self->{value} = $item;
  return;
}

sub setData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  $self->SUPER::setData($rec);
  $self->{sel} = $self->{value};
  return;
} #/ sub setData

1

__END__

=pod

=head1 NAME

TUI::Dialogs::RadioButtons - radio button cluster control

=head1 HIERARCHY

  TObject
    TView
      TCluster
        TRadioButtons

=head1 SYNOPSIS

  use TUI::Dialogs;
  use TUI::Objects;

  my $bounds = TRect->new( ax => 3, ay => 2, bx => 20, by => 5 );

  my $items =  TSItem->new( value => '25 lines',
      next  => TSItem->new( value => '43/50 lines',
      next  => undef,
    ),
  );

  my $rb = TRadioButtons->new( bounds => $bounds, strings => $items );
  $dialog->insert( $rb );

=head1 DESCRIPTION

C<TRadioButtons> implements a classic radio button group where exactly one item
is selected at any time. It inherits navigation, event handling, and drawing
behavior from C<TCluster>.

Selecting a radio button automatically deselects the previously selected one.
The control updates its internal value whenever the selection changes or an item
is pressed.

=head2 Commonly Used Features

Typical usage is to create the C<TSItem> chain, construct C<TRadioButtons>
with C<new_TRadioButtons>, and insert the control into a dialog. In normal
code you usually interact with the selected value through dialog data transfer
rather than calling C<press> or C<movedTo> directly; those methods are mostly
used by event handling and tests.

=head1 VARIABLES

The following global variable affects the visual rendering of C<TRadioButtons>.

=head2 $button

Defines the character pattern used to display a single radio button item,
for example C< ( ) >.

=head1 CONSTRUCTOR

=head2 new

  my $rb = TRadioButtons->new(
    bounds  => $bounds,
    strings => $items
  );

Creates a new radio button cluster.

=over

=item bounds

Bounding rectangle defining the position and size of the radio button group
(I<TRect>).

=item strings

Linked list of item descriptors used to populate the radio button labels
(I<TSItem>).

=back

=head2 new_TRadioButtons

  my $rb = new_TRadioButtons($bounds, $items);

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 draw

  $rb->draw();

Draws the radio button group using a radio-style selection marker.

=head2 mark

  my $bool = $rb->mark($item);

Returns true if the specified item is currently selected.

=head2 movedTo

  $rb->movedTo($item);

Updates the internal value when the selection cursor moves to a new item.

=head2 press

  $rb->press($item);

Selects the specified item and deselects all others.

=head2 setData

  $rb->setData(\@record);

Sets the stored value from an external record and synchronizes the selection
state accordingly.

=head1 SEE ALSO

L<TUI::Dialogs::CheckBoxes>,
L<TUI::Dialogs::Dialog>,
L<TUI::Dialogs::Label>,
L<TUI::Views::Cluster>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
