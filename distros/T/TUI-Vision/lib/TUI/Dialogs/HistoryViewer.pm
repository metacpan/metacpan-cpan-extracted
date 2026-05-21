package TUI::Dialogs::HistoryViewer;
# ABSTRACT: THistoryViewer displays and manages input history in dialog boxes

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  THistoryViewer
  new_THistoryViewer
);

use Carp ();
use List::Util qw( max );
use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::Const                            qw( EOS );
use TUI::Dialogs::Const                   qw( cpHistoryViewer );
use TUI::Dialogs::HistoryViewer::HistList qw(
  historyCount
  historyStr
);
use TUI::Drivers::Const qw(
  :evXXXX
  kbEnter
  kbEsc
  meDoubleClick
);
use TUI::Views::Const qw(
  cmCancel
  cmOK
);
use TUI::Views::ListViewer;
use TUI::Views::Palette;

sub THistoryViewer()   { __PACKAGE__ }
sub new_THistoryViewer { __PACKAGE__->from( @_ ) }

extends TListViewer;

# protected attributes
has historyId => ( is => 'ro', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named  => [
      bounds     => Object,
      hScrollBar => Object,            { alias => 'aHScrollBar' },
      vScrollBar => Object,            { alias => 'aVScrollBar' },
      historyId  => PositiveOrZeroInt, { alias => 'aHistoryId' },
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args2 = $class->SUPER::BUILDARGS(
    bounds     => $args1->{bounds},
    hScrollBar => $args1->{hScrollBar},
    vScrollBar => $args1->{vScrollBar},
    numCols    => 1,
  );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->setRange( historyCount( $self->{historyId} ) );
  $self->focusItem( 1 )
    if $self->{range} > 1;
  $self->{hScrollBar}->setRange(
    0,
    $self->historyWidth() - $self->{size}{x} + 3
  );
  return;
} #/ sub BUILD

sub from {    # $obj ($bounds, $aHScrollBar, $aVScrollBar, $aHistoryId)
  state $sig = signature(
    method => 1,
    pos    => [ Object, Object, Object, PositiveOrZeroInt ],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], hScrollBar => $args[1], 
    vScrollBar => $args[2], historyId  => $args[3] );
} #/ sub from

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpHistoryViewer,
    size => length( cpHistoryViewer ),
  );
  return $palette->clone();
} #/ sub getPalette

sub getText {    # void (\$dest, $item, $maxChars)
  state $sig = signature(
    method => Object,
    pos    => [ ScalarRef, Int, Int ],
  );
  my ( $self, $dest, $item, $maxChars ) = $sig->( @_ );
  my $str = historyStr( $self->{historyId}, $item );
  $$dest = $str ? substr( $str, 0, $maxChars ) : EOS;
  return;
} #/ sub getText

sub handleEvent {    # void ($event)
  no warnings 'uninitialized';
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  if (
    (
      $event->{what} == evMouseDown && ( $event->{mouse}{eventFlags} & meDoubleClick )
    )
    || ( $event->{what} == evKeyDown
      && $event->{keyDown}{keyCode} == kbEnter )
    )
  {
    $self->endModal( cmOK );
    $self->clearEvent( $event );
  } #/ if ( ( $event->{what} ...))
  elsif (
    ( $event->{what} == evKeyDown && $event->{keyDown}{keyCode} == kbEsc )
    || ( $event->{what} == evCommand
      && $event->{message}{command} == cmCancel )
    )
  {
    $self->endModal( cmCancel );
    $self->clearEvent( $event );
  }
  else {
    $self->SUPER::handleEvent( $event );
  }
  return;
} #/ sub handleEvent

sub historyWidth {    # $width ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $width    = 0;
  my $count    = historyCount( $self->{historyId} );
  for ( my $i = 0 ; $i < $count ; $i++ ) {
    my $T = length( historyStr( $self->{historyId}, $i ) );
    $width = max( $width, $T );
  }
  return $width;
} #/ sub historyWidth

1

__END__

=pod

=head1 NAME

TUI::Dialogs::HistoryViewer - list viewer for dialog input history

=head1 HIERARCHY

  TObject
    TView
      TListViewer
        THistoryViewer

=head1 SYNOPSIS

  use TUI::Dialogs;

  my $viewer = TUI::Dialogs::HistoryViewer->new(
    bounds     => $bounds,
    hScrollBar => $hBar,
    vScrollBar => $vBar,
    historyId  => 1
  );

=head1 DESCRIPTION

C<THistoryViewer> implements the list viewer used to display input history
entries managed by C<THistory>. It is responsible for presenting the stored
history values in a scrollable list and handling user interaction with that
list.

The history viewer is normally created indirectly by a C<THistory> object when
the history control is activated. Application code rarely needs to instantiate
or interact with C<THistoryViewer> directly.

The viewer displays the history entries associated with a specific history
identifier. Input fields that share the same history ID also share the same
history list.

=head1 ATTRIBUTES

The following attributes are managed internally and exposed as read-only
accessors.

=over

=item historyId

Numeric identifier selecting which history list is displayed
(I<PositiveOrZeroInt>).

=back

=head1 CONSTRUCTOR

=head2 new

  my $viewer = THistoryViewer->new(
    bounds     => $bounds,
    hScrollBar => $hScrollBar,
    vScrollBar => $vScrollBar,
    historyId  => $historyId
  );

Creates a new history viewer for displaying a specific history list.

=over

=item bounds

Bounding rectangle of the list viewer (I<TRect>).

=item hScrollBar

Horizontal scroll bar associated with the viewer (I<TScrollBar>).

=item vScrollBar

Vertical scroll bar associated with the viewer (I<TScrollBar>).

=item historyId

Numeric identifier of the history list to display.

=back

=head2 new_THistoryViewer

  my $viewer = new_THistoryViewer(
    $bounds,
    $hScrollBar,
    $vScrollBar,
    $historyId
  );

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with named parameters and is
provided for compatibility with traditional Turbo Vision construction patterns.

=head1 METHODS

=head2 getPalette

  my $palette = $viewer->getPalette();

Returns the color palette used to draw the history viewer.

=head2 getText

  $viewer->getText(\$dest, $item, $maxChars);

Retrieves the history entry at the specified index and writes it into C<$dest>.
The returned string is truncated to at most C<$maxChars> characters.

=head2 handleEvent

  $viewer->handleEvent($event);

Handles mouse and keyboard events directed at the history viewer.

=head2 historyWidth

  my $width = $viewer->historyWidth();

Returns the width of the longest entry in the history list.

=head1 SEE ALSO

L<TUI::Dialogs::History>,
L<TUI::Dialogs::InputLine>,
L<TUI::Views::ListViewer>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution). This documentation is provided under the same terms
as the Turbo Vision library itself.

=cut
