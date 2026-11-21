package TUI::Gadgets::Table;
# ABSTRACT: ASCII table view displaying the 256 characters of the code page

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TTable
  new_TTable
);

use TUI::toolkit;
use TUI::toolkit::Types qw( :Object );

use TUI::Drivers::Const qw(
  :evXXXX
  kbDown
  kbEnd
  kbHome
  kbLeft
  kbRight
  kbUp
);
use TUI::Drivers::Event;
use TUI::Gadgets::Const qw(
  cmAsciiTableCmdBase
  cmCharFocused
);
use TUI::Views::DrawBuffer;
use TUI::Views::View;

sub TTable() { __PACKAGE__ }
sub name() { 'TTable' }
sub new_TTable { __PACKAGE__->from(@_) }

extends TView;

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{eventMask} |= evKeyboard;
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  my $color = $self->getColor( 6 );
  for my $y ( 0 .. $self->{size}{y} - 1 ) {
    my $buf = TDrawBuffer->new();
    $buf->moveChar( 0, ' ', $color, $self->{size}{x} );
    for my $x ( 0 .. $self->{size}{x} - 1 ) {
      $buf->moveChar( $x, chr( ( 32 * $y + $x ) & 0xFF ), $color, 1 );
    }
    $self->writeLine( 0, $y, $self->{size}{x}, 1, $buf );
  }
  $self->showCursor();
  return;
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );

  if ( $event->{what} == evMouseDown ) {
    do {
      if ( $self->mouseInView( $event->{mouse}{where} ) ) {
        my $spot = $self->makeLocal( $event->{mouse}{where} );
        $self->setCursor( $spot->{x}, $spot->{y} );
        $self->charFocused();
      }
    } while ( $self->mouseEvent( $event, evMouseMove ) );
    $self->clearEvent( $event );
  }
  elsif ( $event->{what} == evKeyboard ) {
    my $size   = $self->{size};
    my $cursor = $self->{cursor};
    SWITCH: for ( $event->{keyDown}{keyCode} ) {
      kbHome == $_ and do {
        $self->setCursor( 0, 0 );
        last;
      };
      kbEnd == $_ and do {
        $self->setCursor( $size->{x} - 1, $size->{y} - 1 );
        last;
      };
      kbUp == $_ and do {
        $self->setCursor( $cursor->{x}, $cursor->{y} - 1 ) 
          if $cursor->{y} > 0;
        last;
      };
      kbDown == $_ and do {
        $self->setCursor( $cursor->{x}, $cursor->{y} + 1 ) 
          if $cursor->{y} < $size->{y} - 1;
        last;
      };
      kbLeft == $_ and do {
        $self->setCursor( $cursor->{x} - 1, $cursor->{y} ) 
          if $cursor->{x} > 0;
        last;
      };
      kbRight == $_ and do {
        $self->setCursor( $cursor->{x} + 1, $cursor->{y} ) 
          if $cursor->{x} < $size->{x} - 1;
        last;
      };
      DEFAULT: {
        my $code = $event->{keyDown}{charScan}{charCode};
        $self->setCursor( $code % 32, int( $code / 32 ) );
      }
    } #/ SWITCH: for ( $event->{keyDown}...)
    $self->charFocused();
    $self->clearEvent( $event );
  }
  return;
}

sub charFocused {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  my $owner = $self->{owner}
    or return;
  my $event = TEvent->new(
    what    => evBroadcast,
    message => {
      command  => cmAsciiTableCmdBase + cmCharFocused,
      infoLong => $self->{cursor}{x} + 32 * $self->{cursor}{y},
    },
  );
  $owner->handleEvent( $event );
  return;
}

1

__END__

=pod

=head1 NAME

TUI::Gadgets::Table - ASCII table view for character selection

=head1 HIERARCHY

  TObject
    TView
      TTable

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Gadgets;

  my $table = TTable->new(
    bounds => TRect->new( ax => 1, ay => 1, bx => 33, by => 9 ),
  );
  $window->insert( $table );

=head1 DESCRIPTION

C<TTable> displays the 256 characters of the character set as a grid of
32 columns and 8 rows. The character at column C<x> and row C<y> has the
code C<x + 32 * y>.

The cursor can be moved with the cursor keys, C<Home> and C<End>. Typing a
character key moves the cursor to that character's position. A mouse click
moves the cursor to the clicked cell.

Each time the cursor moves, the view broadcasts a C<cmCharFocused> message
to its owner. The message command is C<cmAsciiTableCmdBase + cmCharFocused>
and the message C<infoPtr> is the code of the focused character. This
allows a companion view such as L<TReport|TUI::Gadgets::Report> to display
the selected character.

=head1 CONSTRUCTOR

=head2 new

  my $table = TTable->new( bounds => $bounds );

Creates a new ASCII table view.

=over

=item bounds

Bounding rectangle defining the position and size of the view
(L<TRect|TUI::Objects::Rect>). The view is designed for a size of 32 x 8.

=back

=head2 new_TTable

  my $table = new_TTable( $bounds );

Factory-style constructor using a positional bounds argument.

=head1 METHODS

=head2 draw

  $table->draw();

Draws all 256 characters of the grid and shows the cursor.

=head2 charFocused

  $table->charFocused();

Broadcasts the code of the currently focused character to the owner.

=head2 handleEvent

  $table->handleEvent( $event );

Processes mouse clicks and keyboard input for cursor movement and character
selection.

=head1 SEE ALSO

L<TAsciiChart|TUI::Gadgets::AsciiChart>,
L<TReport|TUI::Gadgets::Report>,
L<TView|TUI::Views::View>

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
