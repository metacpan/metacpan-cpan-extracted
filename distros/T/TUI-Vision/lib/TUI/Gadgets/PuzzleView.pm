package TUI::Gadgets::PuzzleView;
# ABSTRACT: view of a sliding tile puzzle

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TPuzzleView
  new_TPuzzleView
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  :is
  :types
);

use TUI::Drivers::Const qw(
  :evXXXX
  kbDown
  kbLeft
  kbRight
  kbUp
);
use TUI::Drivers::Event;
use TUI::Gadgets::Const qw( cpPuzzlePalette );
use TUI::Objects::Rect;
use TUI::Objects::Point;
use TUI::Views::Const qw( ofSelectable );
use TUI::Views::DrawBuffer;
use TUI::Views::Palette;
use TUI::Views::View;

sub TPuzzleView() { __PACKAGE__ }
sub name() { 'TPuzzleView' }
sub new_TPuzzleView { __PACKAGE__->from(@_) }

extends TView;

my @boardStart = split //, 'ABCDEFGHIJKLMNO ';
my @solution   = split //, 'ABCDEFGHIJKLMNO ';
my @map        = ( 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1 );

# private attributes
has board => ( is => 'bare' );
has moves => ( is => 'bare' );
has solved => ( is => 'bare' );

# private methods (anonymous subs, as in TEventViewer)
my ( $blankIndex );

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );

  $self->{options} |= ofSelectable;
  $self->{board}    = [ @boardStart ];
  $self->{moves}    = 0;
  $self->{solved}   = 0;
  $self->scramble();
  return;
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpPuzzlePalette,
    size => length( cpPuzzlePalette ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );

  if ( $self->{solved} && ( $event->{what} & ( evKeyboard | evMouse ) ) ) {
    $self->scramble();
    $self->clearEvent( $event );
  }

  SWITCH: for ( $event->{what} ) {
    evMouseDown == $_ and do {
      $self->moveTile( $event->{mouse}{where} );
      $self->clearEvent( $event );
      $self->winCheck();
      last;
    };

    evKeyDown == $_ and do {
      $self->moveKey( $event->{keyDown}{keyCode} );
      $self->clearEvent( $event );
      $self->winCheck();
      last;
    };
  } #/ SWITCH: for ( $event->{what} )
  return;
}

sub draw {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  my $colorBack = $self->getColor( 1 );
  my @color     = ( $colorBack, $self->{solved} ? $colorBack : $self->getColor( 2 ) );
  my $buf       = TDrawBuffer->new();

  for my $i ( 0 .. 3 ) {
    $buf->moveChar( 0, ' ', $colorBack, 18 );
    $buf->moveStr( 13, 'Move', $colorBack ) if $i == 1;
    $buf->moveStr( 14, sprintf( '%d', $self->{moves} ), $colorBack ) if $i == 2;
    for my $j ( 0 .. 3 ) {
      my $tile = $self->{board}[ $i * 4 + $j ];
      my $attr = $tile eq ' '
        ? $color[0]
        : $color[ $map[ ord( $tile ) - ord( 'A' ) ] ];
      $buf->moveStr( $j * 3, " $tile ", $attr );
    }
    $self->writeLine( 0, $i, 18, 1, $buf );
  }
  return;
}

$blankIndex = sub {    # $index ()
  my ( $self ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $self );
  my $i = 0;
  $i++ while $i < 16 && $self->{board}[ $i ] ne ' ';
  return $i;
};

sub moveKey {    # void ($key)
  state $sig = signature(
    method => Object,
    pos    => [Int],
  );
  my ( $self, $key ) = $sig->( @_ );

  my $board = $self->{board};
  my $i     = $blankIndex->( $self );
  my $x     = $i % 4;
  my $y     = int( $i / 4 );

  SWITCH: for ( $key ) {
    kbDown == $_ and do {
      if ( $y > 0 ) {
        $board->[ $i ]     = $board->[ $i - 4 ];
        $board->[ $i - 4 ] = ' ';
        $self->{moves}++ if $self->{moves} < 1000;
      }
      last;
    };

    kbUp == $_ and do {
      if ( $y < 3 ) {
        $board->[ $i ]     = $board->[ $i + 4 ];
        $board->[ $i + 4 ] = ' ';
        $self->{moves}++ if $self->{moves} < 1000;
      }
      last;
    };

    kbRight == $_ and do {
      if ( $x > 0 ) {
        $board->[ $i ]     = $board->[ $i - 1 ];
        $board->[ $i - 1 ] = ' ';
        $self->{moves}++ if $self->{moves} < 1000;
      }
      last;
    };

    kbLeft == $_ and do {
      if ( $x < 3 ) {
        $board->[ $i ]     = $board->[ $i + 1 ];
        $board->[ $i + 1 ] = ' ';
        $self->{moves}++ if $self->{moves} < 1000;
      }
      last;
    };
  } #/ SWITCH: for ( $key )

  $self->drawView();
  return;
}

sub moveTile {    # void ($point)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $point ) = $sig->( @_ );

  my $p = $self->makeLocal( $point );
  my $i = $blankIndex->( $self );
  my $x = int( $p->{x} / 3 );
  my $y = $p->{y};

  SWITCH: for ( $y * 4 + $x - $i ) {
    -4 == $_ and do {    # piece moves down
      $self->moveKey( kbDown );
      last;
    };

    -1 == $_ and do {    # piece moves right
      $self->moveKey( kbRight );
      last;
    };

    1 == $_ and do {     # piece moves left
      $self->moveKey( kbLeft );
      last;
    };

    4 == $_ and do {     # piece moves up
      $self->moveKey( kbUp );
      last;
    };
  } #/ SWITCH: for ( $y * 4 + $x - $i )

  $self->drawView();
  return;
}

sub scramble {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  $self->{moves}  = 0;
  $self->{solved} = 0;
  do {
    SWITCH: for ( int( rand 4 ) ) {
      0 == $_ and do { $self->moveKey( kbUp );    last; };
      1 == $_ and do { $self->moveKey( kbDown );  last; };
      2 == $_ and do { $self->moveKey( kbRight ); last; };
      3 == $_ and do { $self->moveKey( kbLeft );  last; };
    }
  } while ( $self->{moves}++ <= 500 );

  $self->{moves} = 0;
  $self->drawView();
  return;
}

sub winCheck {    # void ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );

  my $solved = 1;
  for my $i ( 0 .. 15 ) {
    if ( $self->{board}[ $i ] ne $solution[ $i ] ) {
      $solved = 0;
      last;
    }
  }
  $self->{solved} = $solved;
  $self->drawView();
  return;
}

sub write :method {    # void ($os)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $os ) = $sig->( @_ );
  $self->SUPER::write( $os );
  $os->put(
    join( '', @{ $self->{board} } ),
    $self->{moves},
    $self->{solved},
  );
  return;
}

sub read :method {    # $self ($is)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $is ) = $sig->( @_ );
  $self->SUPER::read( $is );
  $self->{board}  = [ split //, $is->get() ];
  $self->{moves}  = $is->get();
  $self->{solved} = $is->get();
  return $self;
}

1

__END__

=pod

=head1 NAME

TUI::Gadgets::PuzzleView - view of a sliding tile puzzle

=head1 HIERARCHY

  TObject
    TView
      TPuzzleView

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Gadgets;

  my $puzzle = TPuzzleView->new(
    bounds => TRect->new( ax => 1, ay => 1, bx => 19, by => 5 )
  );
  $window->insert( $puzzle );

=head1 DESCRIPTION

C<TPuzzleView> shows a 4x4 sliding tile puzzle with the tiles C<A> to C<O> and
one blank. The view starts with a scrambled board. The number of moves is
shown next to the label C<Move>.

The view is selectable. A tile is moved into the blank by clicking it with the
mouse or by pressing a cursor key, which moves the blank in the opposite
direction. Once the tiles are in order, the view is marked as solved, and the
next key press or mouse click scrambles the board again.

=head1 CONSTRUCTOR

=head2 new

  my $puzzle = TPuzzleView->new( bounds => $bounds );

Creates the puzzle view and scrambles the board.

=head2 new_TPuzzleView

  my $puzzle = new_TPuzzleView( $bounds );

Factory-style constructor using a positional bounds argument.

=head1 METHODS

=head2 draw

  $puzzle->draw();

Draws the board, the label C<Move> and the number of moves.

=head2 getPalette

  my $palette = $puzzle->getPalette();

Returns the palette of the view.

=head2 handleEvent

  $puzzle->handleEvent( $event );

Handles mouse clicks on tiles and cursor keys to move the tiles, and starts a
new game after the puzzle has been solved.

=head2 moveKey

  $puzzle->moveKey( $key );

Moves the tile next to the blank into the blank. The key selects the direction
in which the blank moves: C<kbDown>, C<kbUp>, C<kbRight> or C<kbLeft>.

=head2 moveTile

  $puzzle->moveTile( $point );

Moves the tile at the given point, in view coordinates, into the blank if it is
adjacent to it.

=head2 scramble

  $puzzle->scramble();

Resets the move counter and shuffles the board with random moves.

=head2 winCheck

  $puzzle->winCheck();

Marks the puzzle as solved if the tiles are in order.

=head1 SEE ALSO

L<TPuzzleWindow|TUI::Gadgets::PuzzleWindow>,
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
