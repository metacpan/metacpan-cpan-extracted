package TUI::Dialogs::ListBox;
# ABSTRACT: Provides a list box dialog with selection handling

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT = qw(
  TListBox
  new_TListBox
);

use Class::Struct;
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  is_Object
  :types
);

use TUI::Const qw( EOS );
use TUI::Objects::NSCollection;
use TUI::Views::ListViewer;

struct TListBoxRec => [
  items     => TNSCollection,
  selection => '$',
];

sub TListBox() { __PACKAGE__ }
sub name() { 'TListBox' }
sub new_TListBox { __PACKAGE__->from( @_ ) }

extends TListViewer;

# protected attributes
has items => ( is => 'ro' );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds     => Object,
      numCols    => PositiveOrZeroInt, { alias => 'aNumCols' },
      vScrollBar => Maybe[Object],     { alias => 'aScrollBar' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->setRange( 0 );
  return;
}

sub from {    # $obj ($bounds, $aNumCols, $aVScrollBar|undef)
  state $sig = signature(
    method => 1,
    pos    => [Object, PositiveOrZeroInt, Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], numCols => $args[1], 
    vScrollBar => $args[2] );
}

sub list {    # $collection ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  return $self->{items};
}

sub dataSize {    # $size ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  $sig->( @_ );
  state $size = @{ TListBoxRec->new() };
  return $size;
}

sub getData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  my $p = TListBoxRec->new(
    items     => $self->{items},
    selection => $self->{focused},
  );
  @$rec[ 0 .. $#$p ] = @$p;
  return;
} #/ sub getData

sub getText {    # void (\$dest, $item, $maxChars)
  state $sig = signature(
    method => Object,
    pos    => [ScalarRef, Int, Int],
  );
  my ( $self, $dest, $item, $maxChars ) = $sig->( @_ );
  if ( $self->{items} ) {
    my $src = $self->{items}->at( $item );
    $src = '' unless defined $src;
    $$dest = substr( $src, 0, $maxChars );
  }
  else {
    $$dest = EOS;
  }
  return;
}

sub newList {    # void ($aList)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $aList ) = $sig->( @_ );
  $self->destroy( $self->{items} );
  $self->{items} = $aList;
  if ( $aList ) {
    $self->setRange( $aList->getCount() );
  }
  else {
    $self->setRange( 0 );
  }
  if ( $self->{range} > 0 ) {
    $self->focusItem( 0 );
  }
  $self->drawView();
  return;
} #/ sub newList

sub setData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  my $p = TListBoxRec->new();
  @$p = @$rec[ 0 .. $#$p ];
  $self->newList( $p->items );
  $self->focusItem( $p->selection );
  $self->drawView();
  return;
} #/ sub setData

1

__END__

=pod

=head1 NAME

TUI::Dialogs::ListBox - list box control for displaying collections in dialogs

=head1 HIERARCHY

  TObject
    TView
      TListViewer
        TListBox

=head1 SYNOPSIS

  use TUI::Dialogs;
  use TUI::Objects;
  use TUI::Views;

  my $bounds = TRect->new( ax => 1, ay => 1, bx => 41, by => 12 );
  my $vbar = TScrollBar->new(
    bounds => TRect->new( ax => 41, ay => 1, bx => 42, by => 12 ),
  );

  my $items = TStringCollection->new( limit => 10, delta => 5 );
  $items->atInsert( 0, 'README.pod' );
  $items->atInsert( 1, 'lib/' );
  $items->atInsert( 2, 't/' );

  my $listBox = TListBox->new(
    bounds     => $bounds,
    numCols    => 1,
    vScrollBar => $vbar,
  );
  $listBox->newList( $items );

  my $text;
  $listBox->getText( \$text, 0, 20 );   # 'README.pod'

=head1 DESCRIPTION

C<TListBox> implements a list box control for displaying and selecting items
from a collection. It is typically used in dialog boxes to present lists of
strings, such as filenames or other selectable entries.

The list box manages the data collection internally and displays its contents
using the inherited drawing logic from C<TListViewer>. While it is designed
primarily for string data, subclasses may override C<getText> to display other
data types.

Unlike C<TListViewer>, C<TListBox> does not support a horizontal scroll bar.
Scrolling is performed vertically using an optional vertical scroll bar.

=head2 Commonly Used Features

In normal dialog code, you construct the control and then immediately attach a
collection through C<newList>. That call sets the visible range from the
collection size and refreshes the view, so replacing the collection is the
usual way to repopulate the box. If your rows are not plain strings, override
C<getText> to format each row for display.

=head1 STRUCTURES

=head2 TListBoxRec

Represents the state record used for transferring list box data.

This structure is used by list box views to exchange the current item list
and selection state, typically via C<getData> and C<setData>.

The structure contains the following fields:

=over

=item items

Reference to the collection backing the list box (C<TNSCollection>).

=item selection

Index of the currently selected item (I<Int>).

=back

=head1 ATTRIBUTES

The following attributes are exposed as read-only accessors and are managed
internally by the list box implementation.

=over

=item items

Reference to the collection of items displayed by the list box
(I<TCollection>, e.g. C<TStringCollection>). The collection typically contains 
string objects.

=back

=head1 CONSTRUCTOR

=head2 new

  my $listBox = TListBox->new(
    bounds     => $bounds,
    numCols    => $numCols,
    vScrollBar => $vScrollBar
  );

Creates a new list box control.

=over

=item bounds

Bounding rectangle of the list box (I<TRect>).

=item numCols

Number of columns used to display the list items
(I<PositiveOrZeroInt>).

=item vScrollBar

Optional vertical scroll bar associated with the list box
(I<TScrollBar>). This parameter may be omitted.

=back

=head2 new_TListBox

  my $listBox = new_TListBox($bounds, $numCols, | $vScrollBar);

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with named parameters and is
provided for compatibility with traditional Turbo Vision construction patterns.

=head1 METHODS

=head2 dataSize

  my $size = $listBox->dataSize();

Returns the number of data elements required to transfer the state of the list
box using C<getData> and C<setData>.

=head2 getData

  $listBox->getData(\@record);

Copies the list box state into the supplied record.

=head2 getText

  $listBox->getText(\$dest, $item, $maxChars);

Retrieves the text representation of the item at index C<$item> and writes it
into C<$dest>, truncated to at most C<$maxChars> characters.

=head2 list

  my $collection = $listBox->list();

Returns the collection currently associated with the list box.

=head2 newList

  $listBox->newList($collection);

Associates a new collection with the list box.

If a collection was already present, it is released before the new collection
is installed.

=head2 setData

  $listBox->setData(\@record);

Restores the list box state from the supplied record.

=head1 SEE ALSO

L<TUI::Dialogs::ListViewer>,
L<TUI::Dialogs::Dialog>,
L<TUI::Views::View>

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
