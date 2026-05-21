package TUI::Dialogs::MultiCheckBoxes;
# ABSTRACT: Multi-state checkbox cluster control based on TCluster

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT = qw(
  TMultiCheckBoxes
  new_TMultiCheckBoxes
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  is_Object
  :types
);

use TUI::Dialogs::Cluster;

sub TMultiCheckBoxes() { __PACKAGE__ }
sub name() { 'TMultiCheckBoxes' }
sub new_TMultiCheckBoxes { __PACKAGE__->from( @_ ) }

extends TCluster;

# private attributes
has selRange => ( is => 'bare', default => sub { die 'required' } );
has flags    => ( is => 'bare', default => sub { die 'required' } );
has states   => ( is => 'bare', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds   => Object,
      strings  => Maybe[HashLike], { alias => 'aStrings' },
      selRange => Int,
      flags    => PositiveOrZeroInt,
      states   => Str,
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
} #/ sub BUILDARGS

sub from {    # $obj ($bounds, $aStrings|undef, $aSelRange, $aFlags, $aStates)
  state $sig = signature(
    method => 1,
    pos    => [Object, Maybe[HashLike], Int, PositiveOrZeroInt, Str],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new(
    bounds => $args[0], strings => $args[1], selRange => $args[2],
    flags  => $args[3], states  => $args[4]
  );
}

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{states} = undef;
  return;
}

sub dataSize {    # $size ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  $sig->( @_ );
  return 1;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->drawMultiBox( " [ ] ", $self->{states} );
  return;
}

sub getData {    # void (\@p)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $p ) = $sig->( @_ );
  $p->[0] = $self->{value};
  $self->drawView();
  return;
} #/ sub getData

sub multiMark {    # $int ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  return ( 
    $self->{value} &
    ( ( $self->{flags} & 0xff ) << ( $item * ( $self->{flags} >> 8 ) ) ) 
  ) >> ( $item * ( $self->{flags} >> 8 ) );
}

sub press {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  my $flo = $self->{flags} & 0xff;
  my $fhi = $self->{flags} >> 8;

  my $curState =
    ( $self->{value} & ( $flo << ( $item * $fhi ) ) ) >> ( $item * $fhi );

  $curState--;
  if ( $curState >= $self->{selRange} || $curState < 0 ) {
    $curState = $self->{selRange} - 1;
  }

  $self->{value} = ( $self->{value} & ~( $flo << ( $item * $fhi ) ) ) |
    ( $curState << ( $item * $fhi ) );
  return;
} #/ sub press

sub setData {    # void (\@p)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $p ) = $sig->( @_ );
  $self->{value} = 0+ $p->[0];
  $self->drawView();
  return;
} #/ sub setData

1

__END__

=pod

=head1 NAME

TUI::Dialogs::MultiCheckBoxes - multi-state checkbox cluster control

=head1 HIERARCHY

  TObject
    TView
      TCluster
        TMultiCheckBoxes

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Dialogs;

  my $bounds = TRect->new(
    ax => 0, ay => 0,
    bx => 30, by => 5
  );

  my $items = {
    value => 'Low', next => {
    value => 'Med', next => {
    value => 'High', next => undef
  }}};

  my $mcb = new_TMultiCheckBoxes(
    $bounds,
    $items,
    3,        # selRange   (number of states per item)
    0x0201,   # flags      (low byte = mask, high byte = shift per item)
    ' -+'     # states     (characters representing each possible state)
  );

=head1 DESCRIPTION

C<TMultiCheckBoxes> implements a multi-state checkbox cluster where each item
cycles through a configurable number of states instead of a simple on/off
selection.

The control stores its state in a packed bitfield. Each item occupies a fixed
number of bits, determined by the supplied mask and shift values. This allows
multiple stateful items to be encoded efficiently in a single scalar value.

C<TMultiCheckBoxes> inherits navigation, layout, and focus handling from
C<TCluster>, while extending the marking and activation logic to support
multi-state cycling.

=head1 CONSTRUCTOR

=head2 new

  my $mcb = TMultiCheckBoxes->new(
    bounds   => $bounds,
    strings  => $items,
    selRange => $range,
    flags    => $flags,
    states   => $states
  );

Creates a new multi-state checkbox cluster.

=over

=item bounds

Bounding rectangle defining the position and size of the cluster (I<TRect>).

=item strings

Linked list of item descriptors providing the labels (I<TSItem>).

=item selRange

Number of distinct states each item cycles through (I<Int>).

=item flags

Packed integer describing the bit mask and bit shift used for encoding item
states.

The low byte defines the state mask, the high byte defines the bit shift per
item.

=item states

String containing one character per possible state, used for visual
representation (I<Str>).

=back

=head2 new_TMultiCheckBoxes

  my $mcb = new_TMultiCheckBoxes(
    $bounds,
    $items,
    $range,
    $flags,
    $states
  );

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 dataSize

  my $size = $mcb->dataSize();

Returns the number of scalar values transferred via C<getData> and C<setData>.

For multi-state clusters, this value is always C<1>.

=head2 draw

  $mcb->draw();

Renders the multi-state checkbox cluster using the supplied state marker table.

=head2 getData

  $mcb->getData(\@record);

Writes the packed state bitfield into the output record.

=head2 multiMark

  my $state = $mcb->multiMark($item);

Returns the current state index for the specified item, extracted from the
packed bitfield.

=head2 press

  $mcb->press($item);

Advances the state of the specified item and wraps around according to
C<selRange>.

=head2 setData

  $mcb->setData(\@record);

Updates the internal packed state bitfield from external input.

=head1 USAGE NOTES

C<TMultiCheckBoxes> is particularly useful for representing configuration
options with more than two possible values while maintaining a compact visual
and data representation.

The packed bitfield design allows seamless integration with dialog data
exchange mechanisms.

=head1 IMPLEMENTATION NOTES

C<TMultiCheckBoxes> stores its internal state using a packed bitfield
representation.

The following values are provided at construction time and used internally
by the control:

=over

=item *

The number of states per item (selection range)

=item *

A packed flags value defining the bit mask and bit shift used for encoding
item states

=item *

A string defining the visual marker for each possible state

=back

These values are considered internal implementation details and are not exposed
as public attributes. Application code should not rely on direct access to
these values after construction.

=head1 SEE ALSO

L<TUI::Dialogs::CheckBoxes>,
L<TUI::Dialogs::RadioButtons>,
L<TUI::Dialogs::Cluster>,
L<TUI::Dialogs::Dialog>

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
