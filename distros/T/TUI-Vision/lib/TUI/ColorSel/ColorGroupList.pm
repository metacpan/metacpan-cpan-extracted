package TUI::ColorSel::ColorGroupList;
# ABSTRACT: A list viewer for color groups

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TColorGroupList
  new_TColorGroupList
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
  cmSaveColorIndex
);
use TUI::Views::ListViewer;
use TUI::Views::Util qw( message );

sub TColorGroupList() { __PACKAGE__ }
sub name() { 'TColorGroupList' }
sub new_TColorGroupList { __PACKAGE__->from( @_ ) }

extends TListViewer;

# protected attributes
has groups => ( is => 'ro', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds     => Object,
      scrollBar  => Maybe[Object], { alias => 'aScrollBar' },
      groups     => Maybe[Object], { alias => 'aGroups' },
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
  my $i = 0;
  my $aGroups = $self->{groups};
  while ( $aGroups ) {
    $aGroups = $aGroups->{next};
    $i++;
  }
  $self->setRange( $i );
  return;
}

sub from {    # $obj ($bounds, $aScrollBar|undef, $aGroups|undef)
  state $sig = signature(
    method => 1,
    pos    => [Object, Maybe[Object], Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], scrollBar => $args[1], 
    groups => $args[2] );
}

my $freeItems = sub {    # void ($curItem|undef)
  my ( $curItem ) = @_;
  assert ( !defined $curItem or is_Object $curItem );
  while ( $curItem ) {
    my $p = $curItem;
    $curItem = $curItem->{next};
    undef $p;
  }
  return;
};

my $freeGroups = sub {    # void ($curGroup|undef)
  my ( $curGroup ) = @_;
  assert ( !defined $curGroup or is_Object $curGroup );
  while ( $curGroup ) {
    my $p = $curGroup;
    $freeItems->( $curGroup->{items} );
    $curGroup = $curGroup->{next};
    undef $p;
  }
  return;
};

sub DEMOLISH {    # void ($in_global_destruction)
  my ( $self, $in_global_destruction ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $freeGroups->( $self->{groups} );
  return;
}

sub focusItem {    # void ($item)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $item ) = $sig->( @_ );
  $self->SUPER::focusItem( $item );
  my $curGroup = $self->{groups};
  $curGroup = $curGroup->{next}
    while $curGroup && $item-- > 0;
  message( $self->{owner}, evBroadcast, cmNewColorItem, $curGroup )
    if $curGroup;
  return;
}

sub getText {    # void (\$dest, $item, $maxChars)
  state $sig = signature(
    method => Object,
    pos    => [ScalarRef, Int, Int],
  );
  my ( $self, $dest, $item, $maxChars ) = $sig->( @_ );
  my $curGroup = $self->{groups};
  $curGroup = $curGroup->{next}
    while $curGroup && $item-- > 0;
  $$dest = substr( $curGroup->{name}, 0, $maxChars ) if $curGroup;
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
  if ( $event->{what} == evBroadcast 
    && $event->{message}{command} == cmSaveColorIndex
  ) {
    $self->setGroupIndex( $self->{focused}, $event->{message}{infoByte} );
  }
  return;
}

sub setGroupIndex { # void ($groupNum, $itemNum)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt, PositiveOrZeroInt],
  );
  my ( $self, $groupNum, $itemNum ) = $sig->( @_ );
  my $g = $self->getGroup( $groupNum );
  $g->{index} = $itemNum
    if $g;
  return;
}

sub getGroupIndex {    # $index ($groupNum)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $groupNum ) = $sig->( @_ );
  my $g = $self->getGroup( $groupNum );
  return $g ? $g->{index} : 0;
}

sub getGroup {    # $colorGroup ($groupNum)
  state $sig = signature(
    method => Object,
    pos    => [PositiveOrZeroInt],
  );
  my ( $self, $groupNum ) = $sig->( @_ );
  my $g = $self->{groups};
  $g = $g->{next}
    while $g && $groupNum--;
  return $g;
}

sub getNumGroups {    # $num ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $n;
  my $g = $self->{groups};
  for ( $n = 0 ; $g ; $n++ ) {
    $g = $g->{next};
  }
  return $n;
}

1

__END__

=pod

=head1 NAME

TUI::ColorSel::ColorGroupList - A list viewer for color groups

=head1 HIERARCHY

  TObject
    TView
      TListViewer
        TColorGroupList

=head1 SYNOPSIS

  use TUI::ColorSel::ColorGroupList;

  my $groupList = TColorGroupList->new(
    bounds    => $bounds,
    scrollBar => $scrollBar,
    groups    => $groups,
  );

  my $group = $groupList->getGroup( 0 );
  my $index = $groupList->getGroupIndex( 0 );

=head1 DESCRIPTION

C<TColorGroupList> displays the names of linked color groups in a
single-column list viewer.

The list is initialized from a linked sequence of color group objects.
Each group provides a C<name>, an C<index>, and a C<next> reference.
The number of groups determines the range of the list viewer.

When the focused group changes, the list broadcasts
C<cmNewColorItem> with the selected color group. It also handles
C<cmSaveColorIndex> broadcasts by storing the supplied item index in
the currently focused group.

=head1 ATTRIBUTES

=head2 groups

Contains the first color group in the linked list, or C<undef> when
the list is empty (I<TColorGroup> or C<undef>).

The attribute is read-only.

=head1 CONSTRUCTOR

=head2 new

  my $groupList = TColorGroupList->new(
    bounds    => $bounds,
    scrollBar => $scrollBar | undef,
    groups    => $groups    | undef,
  );

Creates a color group list.

The following named parameters are accepted:

=over

=item C<bounds>

The rectangular bounds of the list viewer (L<TRect|TUI::Objects::Rect>).

=item C<scrollBar>

The vertical scroll bar associated with the list viewer (I<TScrollBar> or 
C<undef>).

=item C<groups>

The first color group in the linked list (I<TColorGroup> or C<undef> for an
empty list).

=back

=head2 new_TColorGroupList

  my $groupList = new_TColorGroupList( 
    $bounds, 
    $scrollBar | undef, 
    $groups    | undef,
  );

Creates a color group list using positional arguments.

C<$scrollBar> and C<$groups> may be C<undef>.

=head1 METHODS

=head2 focusItem

  $groupList->focusItem( $item );

Focuses the color group at the zero-based index C<$item>.

After updating the focused list item, the method broadcasts
C<cmNewColorItem> with the corresponding color group.

=head2 getGroup

  my $group = $groupList->getGroup( $groupNum );

Returns the color group at the zero-based index C<$groupNum>.

Returns C<undef> when the index is beyond the end of the linked group
list.

=head2 getGroupIndex

  my $index = $groupList->getGroupIndex( $groupNum );

Returns the saved item index for the color group at the zero-based
index C<$groupNum>.

Returns zero when the requested group does not exist.

=head2 getNumGroups

  my $count = $groupList->getNumGroups();

Returns the number of color groups in the linked list.

=head2 getText

  $groupList->getText( \$text, $item, $maxChars );

Stores the name of the color group at the zero-based index C<$item>
in C<$text>.

The result is limited to at most C<$maxChars> characters.

=head2 handleEvent

  $groupList->handleEvent( $event );

Handles an event after passing it to the inherited event handler.

For an C<evBroadcast> event with the C<cmSaveColorIndex> command, the
method stores the event's C<infoByte> value as the item index of the
currently focused color group.

=head2 setGroupIndex

  $groupList->setGroupIndex( $groupNum, $itemNum );

Stores C<$itemNum> as the item index of the color group at the
zero-based index C<$groupNum>.

The method has no effect when the requested group does not exist.

=head1 SEE ALSO

L<TListViewer|TUI::Views::ListViewer>,
L<TColorDialog|TUI::ColorSel::TColorDialog>

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
