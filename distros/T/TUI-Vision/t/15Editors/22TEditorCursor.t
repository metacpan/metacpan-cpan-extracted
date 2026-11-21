use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Point';
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::Const', qw( sfCursorIns );
  use_ok 'TUI::Editors::Const', qw( smExtend );
  use_ok 'TUI::Editors::Editor';
}

sub new_editor {
  my $e = TEditor->new(
    bounds     => TRect->new( ax => 0, ay => 0, bx => 10, by => 3 ),
    hScrollBar => undef, 
    vScrollBar => undef, 
    indicator  => undef, 
    bufSize    => 0
  );
  $e->insertText( "abcdefghijklmnop\r\nxyz\r\n12345", 28, !!0 );
  return $e;
}

subtest 'setCurPtr() moves the cursor to line and column' => sub {
  my $e = new_editor();
  $e->setCurPtr( 20, 0 );
  is( $e->{curPos}{y}, 1, 'cursor on line 2' );
  is( $e->{curPos}{x}, 2, 'cursor on the third character of line 2' );
  ok( !$e->hasSelection(), 'no selection without smExtend' );
};

subtest 'setCurPtr() with smExtend selects the range' => sub {
  my $e = new_editor();
  $e->setCurPtr( 0, 0 );
  $e->setCurPtr( 3, smExtend );
  ok( $e->hasSelection(), 'selection exists' );
  is( $e->{selStart}, 0, 'selection starts at the anchor' );
  is( $e->{selEnd}, 3, 'selection ends at the cursor' );
};

subtest 'scrollTo() clamps to the limits' => sub {
  my $e = new_editor();
  $e->scrollTo( 1000, 1000 );
  is( $e->{delta}{x}, $e->{limit}{x} - $e->{size}{x},
    'horizontal delta clamped' );
  is( $e->{delta}{y}, $e->{limit}{y} - $e->{size}{y}, 'vertical delta clamped' );
  $e->scrollTo( -5, -5 );
  is( $e->{delta}{x}, 0, 'negative x clamped to zero' );
  is( $e->{delta}{y}, 0, 'negative y clamped to zero' );
};

subtest 'changeBounds() clamps the scroll position to the new size' => sub {
  my $e = TEditor->new(
    bounds     => TRect->new( ax => 0, ay => 0, bx => 10, by => 3 ),
    hScrollBar => undef, vScrollBar => undef, indicator => undef, bufSize => 0
  );
  $e->insertText( 'abcdefghijklmnopqrstuvwxyz', 26, !!0 );
  $e->scrollTo( 20, 0 );
  ok( $e->{delta}{x} > 0, 'editor is scrolled before the resize' );
  $e->changeBounds( TRect->new( ax => 0, ay => 0, bx => 250, by => 3 ) );
  is( $e->{size}{x},  250, 'size follows the new bounds' );
  is( $e->{delta}{x}, 6,   'delta is clamped to maxLineLength - width' );
};

subtest 'trackCursor() keeps the cursor visible' => sub {
  my $e = new_editor();
  $e->setCurPtr( length( $e->{buffer} ), 0 );
  $e->trackCursor( !!0 );
  ok( $e->{curPos}{y} >= $e->{delta}{y}
    && $e->{curPos}{y} < $e->{delta}{y} + $e->{size}{y},
    'cursor line is inside the visible area' );
  ok( $e->cursorVisible(), 'cursorVisible() agrees' );
};

subtest 'startSelect() and hideSelect() manage the selection' => sub {
  my $e = new_editor();
  $e->setCurPtr( 2, 0 );
  $e->startSelect();
  ok( $e->{selecting}, 'startSelect() sets the selecting flag' );
  $e->setCurPtr( 5, smExtend );
  ok( $e->hasSelection(), 'extending the cursor selects text' );
  $e->hideSelect();
  ok( !$e->{selecting}, 'hideSelect() clears the selecting flag' );
  ok( !$e->hasSelection(), 'hideSelect() removes the selection' );
  is( $e->{curPtr}, 5, 'cursor stays where it was' );
};

subtest 'toggleInsMode() switches overwrite and the cursor shape' => sub {
  my $e = new_editor();
  my $before = !!$e->getState( sfCursorIns );
  $e->toggleInsMode();
  ok( $e->{overwrite}, 'overwrite mode enabled' );
  is( !!$e->getState( sfCursorIns ), !$before, 'cursor insert state flipped' );
  $e->toggleInsMode();
  ok( !$e->{overwrite}, 'insert mode restored' );
  is( !!$e->getState( sfCursorIns ), $before, 'cursor insert state restored' );
};

subtest 'charPos() and charPtr() translate pointers and columns' => sub {
  my $e = new_editor();
  $e->setBufLen( 0 );
  $e->insertText( "ab\tc\r\nxy", 8, !!0 );
  is( $e->charPos( 0, 3 ), 8, 'tab expands to the next tab stop' );
  is( $e->charPtr( 0, 8 ), 3, 'charPtr() finds the character at the column' );
  is( $e->charPtr( 0, 20 ), 4, 'charPtr() stops at the line break' );
};

subtest 'lineMove() keeps the column across lines' => sub {
  my $e = new_editor();
  is( $e->lineMove( 3, 1 ), 21, 'next line is clipped at its end' );
  is( $e->lineMove( 2, 2 ), 25, 'two lines down keeps the column' );
  is( $e->lineMove( 25, -1 ), 20, 'one line up keeps the column' );
};

subtest 'nextWord() and prevWord() jump over words' => sub {
  my $e = new_editor();
  $e->setBufLen( 0 );
  $e->insertText( 'foo bar baz', 11, !!0 );
  is( $e->nextWord( 0 ), 4, 'nextWord() skips the word and the blanks' );
  is( $e->prevWord( 8 ), 4, 'prevWord() moves to the start of the word' );
};

subtest 'getMousePtr() maps a view position to the buffer' => sub {
  my $e = new_editor();
  is( $e->getMousePtr( TPoint->new( x => 2, y => 1 ) ), 20,
    'column 2 on the second line' );
};

done_testing();
