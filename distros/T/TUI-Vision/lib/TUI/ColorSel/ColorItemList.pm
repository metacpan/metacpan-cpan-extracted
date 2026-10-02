package TUI::ColorSel::ColorItemList;
# ABSTRACT: A list viewer for color items

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TColorItemList
  new_TColorItemList
);

use Carp ();
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  is_Object
  :types
);

use TUI::Drivers::Const qw( evBroadcast );
use TUI::ColorSel::Const qw( 
  cmNewColorItem
  cmNewColorIndex
  cmSaveColorIndex
);
use TUI::ColorSel::ColorGroup;
use TUI::Views::ListViewer;
use TUI::Views::Util qw( message );

sub TColorItemList() { __PACKAGE__ }
sub name() { 'TColorItemList' }
sub new_TColorItemList { __PACKAGE__->from( @_ ) }

extends TListViewer;

# protected attributes
has items => ( is => 'ro', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds    => Object,
      scrollBar => Maybe[Object], { alias => 'aScrollBar' },
      items     => Maybe[Object], { alias => 'aItems' },
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args2 = $class->SUPER::BUILDARGS(
    bounds     => $args1->{bounds},
    numCols    => 1,
    hScrollBar => undef,
    vScrollBar => delete $args1->{scrollBar},
  );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{eventMask} |= evBroadcast;
  my $i = 0;
  my $aItems = $self->{items};
  while ( $aItems ) {
    $aItems = $aItems->{next};
    $i++;
  }
  $self->setRange( $i );
  return;
}

sub from {    # $obj ($bounds, $aScrollBar|undef, $aItems|undef)
  state $sig = signature(
    method => 1,
    pos    => [Object, Maybe[Object], Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], scrollBar => $args[1], 
    items => $args[2] );
}

sub focusItem {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  $self->SUPER::focusItem( $item );
  message( $self->{owner}, evBroadcast, cmSaveColorIndex, $item );
  my $curItem = $self->{items};
  $curItem = $curItem->{next}
    while $curItem && $item-- > 0;
  message( $self->{owner}, evBroadcast, cmNewColorIndex, $curItem->{index} ) 
    if $curItem;
  return;
}

sub getText {    # void (\$dest, $item, $maxChars)
  state $sig = signature(
    method => Object,
    pos    => [ScalarRef, Int, Int],
  );
  my ( $self, $dest, $item, $maxChars ) = $sig->( @_ );
  my $curItem = $self->{items};
  $curItem = $curItem->{next}
    while $curItem && $item-- > 0;
  $$dest = substr( $curItem->{name}, 0, $maxChars ) if $curItem;
  return;
}

sub handleEvent {    # void ($event)
  no warnings 'uninitialized';
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );
  if ( $event->{what} == evBroadcast ) {
    my $g = $event->{message}{infoPtr};
    my $curItem;
    my $i = 0;
    SWITCH: for ( $event->{message}{command} ) {
      cmNewColorItem == $_ and do {
        assert ( is_Object $g );
        $curItem = $self->{items} = $g->{items};
        while ( $curItem ) {
          $curItem = $curItem->{next};
          $i++;
        }
        $self->setRange( $i );
        $self->focusItem( $g->{index} );
        $self->drawView();
        last;
      };
      DEFAULT: {
        last;
      }
    }
  }
  return;
}

1

__END__

=pod

=head1 NAME

TUI::ColorSel::ColorItemList - a list viewer for color items

=head1 HIERARCHY

  TObject
    TView
      TListViewer
        TColorItemList

=head1 SYNOPSIS

  use TUI::ColorSel::ColorItemList;

  my $itemList = TColorItemList->new(
    bounds    => $bounds,
    scrollBar => $scrollBar,
    items     => $items,
  );

  $itemList->focusItem( 0 );

=head1 DESCRIPTION

C<TColorItemList> displays the names of linked color items in a single-column 
list viewer.

The list is initialized from a linked sequence of
L<TColorItem|TUI::ColorSel::ColorItem> objects. Each item provides a C<name>, 
an C<index>, and a C<next> reference.

When the focused item changes, the list broadcasts both
C<cmSaveColorIndex> and C<cmNewColorItem> messages so that other
components of the color dialog may synchronize their state.

The list also reacts to C<cmNewColorItem> broadcasts containing a
L<TColorGroup|TUI::ColorSel::ColorGroup> and replaces its current item list 
with the group's item chain.

=head1 ATTRIBUTES

=head2 items

Contains the first color item in the linked list 
(L<TColorItem|TUI::ColorSel::ColorItem>), or C<undef> when the list is empty.

The attribute is read-only.

=head1 CONSTRUCTOR

=head2 new

  my $itemList = TColorItemList->new(
    bounds    => $bounds,
    scrollBar => $scrollBar | undef,
    items     => $items     | undef,
  );

Creates a color item list.

The following named parameters are accepted:

=over

=item C<bounds>

The rectangular bounds of the list viewer (L<TRect|TUI::Objects::Rect>).

=item C<scrollBar>

The vertical scroll bar associated with the list viewer (I<TScrollBar> 
or C<undef>).

=item C<items>

The first color item in the linked list (I<TColorItem> or C<undef> for an 
empty list).

=back

=head2 new_TColorItemList

  my $itemList = new_TColorItemList(
    $bounds,
    $scrollBar | undef,
    $items     | undef,
  );

Creates a color item list using positional arguments.

C<$scrollBar> and C<$items> may be C<undef>.

=head1 METHODS

=head2 focusItem

  $itemList->focusItem( $item );

Focuses the color item at the zero-based index C<$item>.

After updating the focused list item, the method broadcasts
C<cmSaveColorIndex> with the selected item number and C<cmNewColorItem> with 
the corresponding color index.

=head2 getText

  $itemList->getText( \$text, $item, $maxChars );

Stores the name of the color item at the zero-based index
C<$item> in C<$text>.

The result is limited to at most C<$maxChars> characters.

=head2 handleEvent

  $itemList->handleEvent( $event );

Handles an event after passing it to the inherited event handler.

For an C<evBroadcast> event with the C<cmNewColorItem> command, the method 
expects C<infoPtr> to reference a L<TColorGroup|TUI::ColorSel::ColorGroup> 
object.

The list is rebuilt from the group's item chain, the list range is updated, and 
the saved item index of the group becomes the newly focused item.

=head1 SEE ALSO

L<TListViewer|TUI::Views::ListViewer>,
L<TColorItem|TUI::ColorSel::ColorItem>,
L<TColorGroup|TUI::ColorSel::ColorGroup>

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
