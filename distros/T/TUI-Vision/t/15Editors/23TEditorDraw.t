use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Editors::Editor';
  use_ok 'TUI::Objects::Rect';
}

{
  package MyEditor;
  use TUI::toolkit;
  extends 'TUI::Editors::Editor';
  our @lines;
  sub writeBuf {
    my ( $self, undef, $y, undef, undef, $b ) = @_;
    $lines[$y] = join '', map { $b->[$_]->character()->getText() } 0 .. $#$b;
  }
}

my $view;
subtest 'TEditor->new()' => sub {
  $view = MyEditor->new( 
    bounds     => TRect->new( ax => 0, ay => 0, bx => 8, by => 3 ),
    hScrollBar => undef, 
    vScrollBar => undef, 
    indicator  => undef, 
    bufSize    => 0 
  );
  isa_ok( $view, 'TUI::Editors::Editor' );
};

subtest 'draw() renders the visible lines' => sub {
  $view->insertText( "abc\r\ndef\r\nghi\r\njkl", 18, !!0 );
  @MyEditor::lines = ();
  $view->draw();
  is( $MyEditor::lines[0], 'abc     ', 'first line padded to the width' );
  is( $MyEditor::lines[1], 'def     ', 'second line' );
  is( $MyEditor::lines[2], 'ghi     ', 'third line' );
  is( scalar @MyEditor::lines, 3, 'only size.y lines are written' );
};

subtest 'draw() honours the horizontal scroll offset' => sub {
  $view->scrollTo( 1, 0 );
  @MyEditor::lines = ();
  $view->draw();
  is( $MyEditor::lines[0], 'bc      ', 'line starts at delta.x' );
};

done_testing();
