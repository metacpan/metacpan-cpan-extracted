package TUI::StdDlg::SortedListBox;
# ABSTRACT: TListBox subclass providing automatic item sorting

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';

our @EXPORT = qw(
  TSortedListBox
  new_TSortedListBox
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  :is
  :types
);

use TUI::Const qw( EOS );
use TUI::Dialogs::ListBox;
use TUI::Drivers::Const qw(
  :evXXXX
  kbBack
);
use TUI::Objects::SortedCollection;
use TUI::Views::Const qw( cmReleasedFocus );

sub TSortedListBox() { __PACKAGE__ }
sub name() { 'TSortedListBox' }
sub new_TSortedListBox { __PACKAGE__->from( @_ ) }

extends TListBox;

# protected attributes
has shiftState => ( is => 'ro', default =>  0 );

# private attributes
has searchPos => ( is => 'bare', default => -1 );

my $equal = sub {    # $bool ($s1, $s2, $count)
  my ( $s1, $s2, $count ) = @_;
  assert ( is_Str $s1 );
  assert ( is_Str $s2 );
  assert ( is_PositiveOrZeroInt $count );
  return lc( substr( $s1, 0, $count ) ) eq lc( substr( $s2, 0, $count ) );
};

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->showCursor();
  $self->setCursor( 1, 0 );
  return;
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );

  my ( $curString, $newString );
  my $k;
  my $value;
  my ( $oldPos, $oldValue );

  $oldValue = $self->{focused};
  $self->SUPER::handleEvent( $event );
  if ( $oldValue != $self->{focused}
    || ( $event->{what} == evBroadcast
      && $event->{message}{command} == cmReleasedFocus )
  ) {
    $self->{searchPos} = -1;
  }
  if ( $event->{what} == evKeyDown ) {
    if ( $event->{keyDown}{charScan}{charCode} ) {
      $value = $self->{focused};
      if ( $value < $self->{range} ) {
        $self->getText( \$curString, $value, 255 );
      }
      else {
        $curString = EOS;
      }
      $oldPos = $self->{searchPos};
      if ( $event->{keyDown}{keyCode} == kbBack ) {
        return
          if $self->{searchPos} == -1;
        $self->{searchPos}--;
        if ( $self->{searchPos} == -1 ) {
          $self->{shiftState} = $event->{keyDown}{controlKeyState};
        }
        substr( $curString, $self->{searchPos} + 1 ) = EOS;
      }
      elsif ( $event->{keyDown}{charScan}{charCode} == ord( '.' ) ) {
        my $loc = index( $curString, '.' );
        if ( $loc == -1 ) {
          $self->{searchPos} = -1;
        }
        else {
          $self->{searchPos} = $loc;
        }
      }
      else {
        $self->{searchPos}++;
        if ( $self->{searchPos} == 0 ) {
          $self->{shiftState} = $event->{keyDown}{controlKeyState};
        }
        substr( $curString, $self->{searchPos} ) = 
          chr( $event->{keyDown}{charScan}{charCode} );
      } #/ else [ if ( $event->{keyDown}...)]
      $k = $self->getKey( $curString );
      $self->list()->search( $k, \$value );
      if ( $value < $self->{range} ) {
        $self->getText( \$newString, $value, 255 );
        if ( &$equal( $curString, $newString, $self->{searchPos} + 1 ) ) {
          if ( $value != $oldValue ) {
            $self->focusItem( $value );
            $self->setCursor(
              $self->{cursor}{x} + $self->{searchPos} + 1,
              $self->{cursor}{y}
            );
          }
          else {
            $self->setCursor(
              $self->{cursor}{x} + ( $self->{searchPos} - $oldPos ),
              $self->{cursor}{y}
            );
          }
        } #/ if ( substr( $curString...))
        else {
          $self->{searchPos} = $oldPos;
        }
      } #/ if ( $value < $self->{...})
      else {
        $self->{searchPos} = $oldPos;
      }
      if ( $self->{searchPos} != $oldPos 
        || chr( $event->{keyDown}{charScan}{charCode} ) =~ /^[[:alpha:]]+$/
      ) {
        $self->clearEvent( $event );
      }
    } #/ if ( $charCode != 0 )
  } #/ if ( $event->{what} ==...)
  return;
} #/ sub handleEvent

sub getKey {    # $key ($s)
  state $sig = signature(
    method => Object,
    pos    => [Str],
  );
  my ( $self, $s ) = $sig->( @_ );
  return $s;
}

sub newList {    # void ($aList)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $aList ) = $sig->( @_ );
  $self->SUPER::newList( $aList );
  $self->{searchPos} = -1;
  return;
}

sub list {    # $sortedCollection ()
  goto &TUI::Dialogs::ListBox::list;
}

1

__END__

=pod

=head1 NAME

TUI::StdDlg::SortedListBox - list box with automatic item sorting

=head1 HIERARCHY

  TObject
    TView
      TGroup
        TListBox
          TSortedListBox
            TFileList

=head1 SYNOPSIS

  use TUI::StdDlg;

  my $list = new_TSortedListBox(
    $bounds,
    $scrollBar
  );

=head1 DESCRIPTION

C<TSortedListBox> is a subclass of C<TListBox> that adds automatic sorting
behavior for its items.

The list box maintains its contents in sorted order based on keys extracted
from the item text. It is designed as a reusable base class for list views that
require ordered presentation, such as file and directory lists.

This class does not define its own construction parameters and relies on the
standard C<TListBox> initialization.

=head1 ATTRIBUTES

=over

=item shiftState

Current keyboard shift state used during incremental search and navigation
(I<Int>).

=back

=head1 CONSTRUCTOR

=head2 new

  my $list = TSortedListBox->new(
    bounds     => $bounds,
    vScrollBar => $scrollBar | undef
  );

Creates a new sorted list box.

This constructor is inherited from C<TListBox> and initializes the view with
the specified bounds and optional vertical scroll bar.

=over

=item bounds

Bounding rectangle defining the position and size of the list box (I<TRect>).

=item vScrollBar

Optional vertical scroll bar associated with the list box (I<TScrollBar>).

=back

=head2 new_TSortedListBox

  my $list = new_TSortedListBox($bounds, $scrollBar | undef);

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 getKey

  my $key = $list->getKey($string);

Extracts and returns the sort key used for ordering items.

This method is used internally to determine the relative order of list items
and may be overridden by subclasses to customize sorting behavior.

=head2 handleEvent

  $list->handleEvent($event);

Processes keyboard and command events.

This method extends the inherited list box behavior to support incremental
search and navigation within the sorted list.

=head2 list

  my $collection = $list->list();

Returns the sorted collection backing the list box.

=head2 newList

  $list->newList($collection);

Assigns a new sorted collection to the list box and refreshes its contents.

=head1 SEE ALSO

L<TUI::Views::ListBox>,
L<TUI::StdDlg::FileList>

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
