use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Objects::Point';
  use_ok 'TUI::Drivers::Const', qw(
    evKeyboard
    evMouseDown
    evNothing
    kbDown
    kbLeft
    kbRight
    kbUp
  );
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Gadgets::PuzzleView';
  use_ok 'TUI::Gadgets::PuzzleWindow';
  use_ok 'TUI::Views::Const', qw( ofSelectable sfSelected wfGrow wfZoom );
}

my $solved_board = 'ABCDEFGHIJKLMNO ';

sub key_event {
  my ( $code ) = @_;
  return TEvent->new(
    what    => evKeyboard,
    keyDown => { keyCode => $code },
  );
}

sub mouse_event {
  my ( $x, $y ) = @_;
  return TEvent->new(
    what  => evMouseDown,
    mouse => { where => TPoint->new( x => $x, y => $y ) },
  );
}

sub board_string {
  my ( $puzzle ) = @_;
  return join '', @{ $puzzle->{board} };
}

sub new_puzzle {
  my $puzzle = TPuzzleView->new(
    bounds => TRect->new( ax => 0, ay => 0, bx => 18, by => 4 )
  );
  $puzzle->{board} = [ split //, $solved_board ];
  $puzzle->{moves} = 0;
  $puzzle->{solved} = 0;
  return $puzzle;
}

subtest 'constructor scrambles the board' => sub {
  my $puzzle = TPuzzleView->new(
    bounds => TRect->new( ax => 0, ay => 0, bx => 18, by => 4 )
  );
  isa_ok( $puzzle, TPuzzleView );
  ok( $puzzle->{options} & ofSelectable, 'selectable' );
  is_deeply(
    [ sort split //, board_string( $puzzle ) ],
    [ sort split //, $solved_board ],
    'board still holds the 16 tiles'
  );
  is( $puzzle->{moves}, 0, 'move counter is reset' );
  is( $puzzle->{solved}, 0, 'not solved' );
};

subtest 'cursor key moves the tile next to the blank' => sub {
  my $puzzle = new_puzzle();

  $puzzle->moveKey( kbUp );
  is( board_string( $puzzle ), $solved_board, 'no tile below the blank' );
  is( $puzzle->{moves}, 0, 'no move counted' );

  $puzzle->moveKey( kbDown );
  is( board_string( $puzzle ), 'ABCDEFGHIJK MNOL',
    'tile above the blank moves down' );
  is( $puzzle->{moves}, 1, 'move counted' );

  $puzzle->moveKey( kbRight );
  is( board_string( $puzzle ), 'ABCDEFGHIJ KMNOL',
    'tile to the left of the blank moves right' );
};

subtest 'first click on an unfocused view only focuses it' => sub {
  my $puzzle = new_puzzle();

  $puzzle->handleEvent( mouse_event( 7, 3 ) );
  is( board_string( $puzzle ), $solved_board, 'board unchanged' );
  is( $puzzle->{moves}, 0, 'no move counted' );
};

subtest 'mouse click moves an adjacent tile' => sub {
  my $puzzle = new_puzzle();
  $puzzle->{state} |= sfSelected;

  $puzzle->handleEvent( mouse_event( 7, 3 ) );
  is( board_string( $puzzle ), 'ABCDEFGHIJKLMN O',
    'tile left of the blank moves into it' );
  is( $puzzle->{moves}, 1, 'move counted' );
};

subtest 'click on a tile that is not adjacent does nothing' => sub {
  my $puzzle = new_puzzle();
  $puzzle->{state} |= sfSelected;

  $puzzle->handleEvent( mouse_event( 1, 0 ) );
  is( board_string( $puzzle ), $solved_board, 'board unchanged' );
  is( $puzzle->{moves}, 0, 'no move counted' );
};

subtest 'winCheck detects the solved board' => sub {
  my $puzzle = new_puzzle();
  $puzzle->winCheck();
  is( $puzzle->{solved}, 1, 'solved board is detected' );

  $puzzle->{board} = [ split //, 'BACDEFGHIJKLMNO ' ];
  $puzzle->winCheck();
  is( $puzzle->{solved}, 0, 'unsolved board is not detected' );
};

subtest 'event after solving scrambles the board again' => sub {
  my $puzzle = new_puzzle();
  $puzzle->winCheck();

  my $event = key_event( kbDown );
  $puzzle->handleEvent( $event );
  is( $event->{what}, evNothing, 'event is cleared' );
  is( $puzzle->{solved}, 0, 'no longer solved' );
  is( $puzzle->{moves}, 0, 'move counter is reset' );
  isnt( board_string( $puzzle ), $solved_board, 'board is scrambled' );
};

subtest 'scramble keeps the tiles and resets the counters' => sub {
  my $puzzle = new_puzzle();
  $puzzle->{solved} = 1;
  $puzzle->scramble();
  is( $puzzle->{moves}, 0, 'move counter is reset' );
  is( $puzzle->{solved}, 0, 'not solved' );
  is_deeply(
    [ sort split //, board_string( $puzzle ) ],
    [ sort split //, $solved_board ],
    'board still holds the 16 tiles'
  );
};

subtest 'window contains a fixed-size puzzle view' => sub {
  my $window = TPuzzleWindow->new();
  isa_ok( $window, TPuzzleWindow );
  is( $window->{title}, 'Puzzle', 'title' );
  ok( !( $window->{flags} & ( wfZoom | wfGrow ) ), 'not zoomable or growable' );
  is( $window->{growMode}, 0, 'does not move with the desktop' );
};

done_testing();
