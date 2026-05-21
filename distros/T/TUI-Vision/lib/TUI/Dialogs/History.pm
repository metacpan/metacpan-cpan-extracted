package TUI::Dialogs::History;
# ABSTRACT: A TWindow-based history browser for TVision input controls

use 5.010;
use strict;
use warnings;
use utf8;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  THistory
  new_THistory
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::Dialogs::Const qw( 
  cmRecordHistory
  cpHistory
);
use TUI::Dialogs::HistoryViewer::HistList qw( historyAdd );
use TUI::Dialogs::HistoryWindow;
use TUI::Dialogs::InputLine;
use TUI::Drivers::Const qw(
  :evXXXX
  kbDown
);
use TUI::Drivers::Util qw( ctrlToArrow );
use TUI::Objects::Rect;
use TUI::Views::Const qw(
  cmOK
  cmReleasedFocus
  ofPostProcess
  sfFocused
);
use TUI::Views::DrawBuffer;
use TUI::Views::Palette;
use TUI::Views::View;

sub THistory() { __PACKAGE__ }
sub name() { 'THistory' }
sub new_THistory { __PACKAGE__->from(@_) }

extends TView;

# declare global variables
our $icon = "\xDE~\x19~\xDD";    # cp437: "▐~↓~▌"

# protected attributes
has link      => ( is => 'ro', default => sub { die 'required' } );
has historyId => ( is => 'ro', default => sub { die 'required' } );

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds    => Object,
      link      => Object,            { alias => 'aLink' },
      historyId => PositiveOrZeroInt, { alias => 'aHistoryId' },
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
  $self->{options}   |= ofPostProcess;
  $self->{eventMask} |= evBroadcast;
  return;
}

sub from {    # $obj ($bounds, $aLink, $aHistoryId)
  state $sig = signature(
    method => 1,
    pos    => [Object, Object, PositiveOrZeroInt],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], link => $args[1], 
    historyId => $args[2] );
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  my $b = TDrawBuffer->new();
  $b->moveCStr( 0, $icon, $self->getColor( 0x0102 ) );
  $self->writeLine( 0, 0, $self->{size}{x}, $self->{size}{y}, $b );
  return;
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpHistory,
    size => length( cpHistory ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
 
  my $historyWindow;
  my ( $r, $p );
  my $c;

  $self->SUPER::handleEvent( $event );
  if ( $event->{what} == evMouseDown
    || ( $event->{what} == evKeyDown
      && ctrlToArrow( $event->{keyDown}{keyCode} ) == kbDown
      && ( $self->{link}{state} & sfFocused ) )
  ) {
    if ( !$self->{link}->focus() ) {
      $self->clearEvent( $event );
      return;
    }
    $self->recordHistory( $self->{link}{data} );
    $r = $self->{link}->getBounds();
    $r->{a}{x}--;
    $r->{b}{x}++;
    $r->{b}{y} += 7;
    $r->{a}{y}--;
    $p = $self->{owner}->getExtent();
    $r->intersect( $p );
    $r->{b}{y}--;
    $historyWindow = $self->initHistoryWindow( $r );

    if ( $historyWindow != 0 ) {
      $c = $self->{owner}->execView( $historyWindow );
      if ( $c == cmOK ) {
        my $rslt;
        $historyWindow->getSelection( \$rslt );
        $self->{link}{data} = substr( $rslt, 0, $self->{link}{maxLen} );
        $self->{link}->selectAll( true );
        $self->{link}->drawView();
      }
      $self->destroy( $historyWindow );
    } #/ if ( $historyWindow !=...)
    $self->clearEvent( $event );
  }
  else {
    if ( $event->{what} == evBroadcast ) {
      no warnings 'uninitialized';
      if ( ( $event->{message}{command} == cmReleasedFocus
          && $event->{message}{infoPtr} == $self->{link} )
        || $event->{message}{command} == cmRecordHistory
      ) {
        $self->recordHistory( $self->{link}{data} );
      } #/ if ( ( $event->{message...}))
    } #/ if ( $event->{what} ==...)
  }
  return;
}

sub initHistoryWindow {    # $historyWindow ($bounds)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $bounds ) = $sig->( @_ );
  my $p = THistoryWindow->new(
    bounds    => $bounds,
    historyId => $self->{historyId},
  );
  $p->{helpCtx} = $self->{link}{helpCtx};
  return $p;
}

sub recordHistory {    # void ($s)
  state $sig = signature(
    method => Object,
    pos    => [Str],
  );
  my ( $self, $s ) = $sig->( @_ );
  historyAdd( $self->{historyId}, $s );
  return;
}

sub shutDown {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  $self->{link} = undef;
  $self->SUPER::shutDown();
  return;
}

1

__END__

=head1 NAME

TUI::Dialogs::History - history browser for dialog input fields

=head1 HIERARCHY

  TObject
    TView
      THistory

=head1 SYNOPSIS

  use TUI::Dialogs;

  my $history = TUI::Dialogs::History->new(
    bounds    => $bounds,
    link      => $inputLine,
    historyId => 1
  );

=head1 DESCRIPTION

C<THistory> implements a history browser for dialog input controls. It is
typically displayed as a small down-arrow icon next to an input field and
allows users to recall previously entered values.

Each history object is linked to a specific input field and identified by a
numeric history ID. Input fields that share the same history ID also share the
same history list, allowing multiple controls to reuse stored values.

Whenever a new value is entered into a linked input field, the previous value
is recorded automatically. When the history control is activated, a list of
stored entries is displayed for selection.

C<THistory> is designed to be used as part of a dialog and is rarely
instantiated or manipulated outside that context.

=head1 VARIABLES

The following global variable affects the visual rendering of C<THistory>.

=head2 $icon

Defines the character sequence used to display the history indicator icon.
The default value uses CP437 characters to render a framed arrow symbol.

=head1 ATTRIBUTES

The following attributes are managed internally and exposed as read-only
accessors.

=over

=item link

Reference to the associated input line control (I<TInputLine>).

=item historyId

Numeric identifier for the history list (I<PositiveOrZeroInt>).  
Input fields using the same identifier share the same history.

=back

=head1 CONSTRUCTOR

=head2 new

  my $history = THistory->new(
    bounds    => $bounds,
    link      => $link,
    historyId => $historyId
  );

Creates a new history control linked to an input field.

=over

=item bounds

Bounding rectangle of the history control (I<TRect>).

=item link

Input field associated with this history control (I<TInputLine>).

=item historyId

Numeric identifier used to group history entries.

=back

=head2 new_THistory

  my $history = new_THistory($bounds, $link, $historyId);

Factory-style constructor using positional arguments.

This constructor is equivalent to calling C<new> with named parameters and is
provided for compatibility with traditional Turbo Vision construction patterns.

=head1 METHODS

=head2 draw

  $history->draw();

Draws the history icon at the location defined by the bounding rectangle.

=head2 getPalette

  my $palette = $history->getPalette();

Returns the color palette used to draw the history control.

=head2 handleEvent

  $history->handleEvent($event);

Handles mouse and keyboard events directed at the history control.

=head2 initHistoryWindow

  my $window = $history->initHistoryWindow($bounds);

Creates and initializes the history list window used to display stored entries.

=head2 name

  my $name = $history->name();

Returns the class name.

=head2 recordHistory

  $history->recordHistory($string);

Records a new entry in the history list.

=head2 shutDown

  $history->shutDown();

Shuts down the history control and releases associated resources.

=head1 SEE ALSO

L<TUI::Dialogs::Dialog>, L<TUI::Dialogs::InputLine>, L<TUI::Views::View>

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
