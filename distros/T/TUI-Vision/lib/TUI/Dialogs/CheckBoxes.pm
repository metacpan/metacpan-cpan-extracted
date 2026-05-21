package TUI::Dialogs::CheckBoxes;
# ABSTRACT: Multi-item checkbox cluster control based on TCluster

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT = qw(
  TCheckBoxes
  new_TCheckBoxes
);

use TUI::toolkit;
use TUI::toolkit::Types qw( Object Int );

use TUI::Dialogs::Cluster;

sub TCheckBoxes() { __PACKAGE__ }
sub name() { 'TCheckBoxes' }
sub new_TCheckBoxes { __PACKAGE__->from( @_ ) }

extends TCluster;

# declare global variables
our $button = " [ ] ";

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->drawMultiBox( $button, " X" );
  return;
}

sub mark {    # $bool ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  return ( $self->{value} & ( 1 << $item ) ) != 0;
}

sub press {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  $self->{value} = $self->{value} ^ ( 1 << $item );
  return;
}

1

__END__

=pod

=head1 NAME

TUI::Dialogs::CheckBoxes - multi-item checkbox cluster control

=head1 HIERARCHY

  TObject
    TView
      TCluster
        TCheckBoxes

=head1 SYNOPSIS

  use TUI::Dialogs;
  use TUI::Objects;

  my $bounds = TRect->new( ax => 3, ay => 5, bx => 35, by => 7 );

  my $items = TSItem->new( value => '~C~ase sensitive',
      next => TSItem->new( value => '~W~hole words only',
      next => undef,
  ));

  my $cb = TCheckBoxes->new( bounds => $bounds, strings => $items );
  $dialog->insert( $cb );

=head1 DESCRIPTION

C<TCheckBoxes> implements a multi-selection checkbox group where each item can
be toggled independently. Each checkbox corresponds to a bit in an internal
value mask, allowing multiple items to be selected at the same time.

The control inherits navigation, drawing, and event handling behavior from
C<TCluster>. Only the marking and toggle logic are specialized to support
multi-state selection.

=head2 Commonly Used Features

Typical code creates a short C<TSItem> chain, constructs C<TCheckBoxes>, and
inserts it into a dialog. The selected state is stored as a bitmask, so each
checkbox corresponds to one bit in C<value>. In practice you usually read and
write that value through dialog data transfer, while C<mark> and C<press> are
mainly useful when implementing or testing custom event behavior.

=head1 VARIABLES

The following global variable affects the visual rendering of C<TCheckBoxes>.

=head2 $button

Defines the character pattern used to display a single checkbox item,
for example C< [ ] >.

=head1 CONSTRUCTOR

=head2 new

  my $cb = TCheckBoxes->new(
    bounds  => $bounds,
    strings => $items
  );

Creates a new checkbox cluster.

=over

=item bounds

Bounding rectangle defining the position and size of the checkbox group
(I<TRect>).

=item strings

Linked list of item descriptors used to populate the checkbox labels
(I<TSItem>).

=back

=head2 new_TCheckBoxes

  my $cb = new_TCheckBoxes($bounds, $items);

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 draw

  $cb->draw();

Draws the checkbox cluster using a checkbox-style marker.

=head2 mark

  my $bool = $cb->mark($item);

Returns true if the bit corresponding to the specified item index is currently
set.

=head2 press

  $cb->press($item);

Toggles the bit assigned to the given item index in the internal value mask.

=head1 SEE ALSO

L<TUI::Dialogs::RadioButtons>,
L<TUI::Dialogs::Dialog>,
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
