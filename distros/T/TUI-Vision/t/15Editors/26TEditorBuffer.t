use strict;
use warnings;

use Test::More;
use English qw( $INPUT_RECORD_SEPARATOR );

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Editors::Editor';
}

sub new_editor {
  return TEditor->new( 
    bounds     => TRect->new( ax => 0, ay => 0, bx => 20, by => 5 ),
    hScrollBar => undef, 
    vScrollBar => undef, 
    indicator  => undef, 
    bufSize    => 0,
  );
}

subtest 'insertText() stores text and moves the cursor behind it' => sub {
  my $e = new_editor();
  $e->insertText( 'abc', 3, !!0 );
  is( $e->{buffer}, 'abc', 'buffer holds the inserted text' );
  is( $e->{curPtr}, 3, 'cursor pointer behind the text' );
  is( $e->{curPos}{x}, 3, 'cursor column behind the text' );
  is( $e->{curPos}{y}, 0, 'cursor stays on the first line' );
  ok( $e->{modified}, 'editor is marked as modified' );
};

subtest 'insertBuffer() inserts a slice of the given text' => sub {
  my $e = new_editor();
  $e->insertBuffer( 'xabcx', 1, 3, !!0, !!0 );
  is( $e->{buffer}, 'abc', 'only the slice starting at offset is inserted' );
  is( $e->{curPtr}, 3, 'cursor pointer behind the inserted slice' );
};

subtest 'setBufLen() resets cursor, selection and limits' => sub {
  my $e = new_editor();
  $e->insertText( "abc\ndef", 7, !!0 );
  $e->setBufLen( 0 );
  is( $e->{curPtr}, 0, 'cursor pointer reset' );
  is( $e->{curPos}{y}, 0, 'cursor line reset' );
  ok( !$e->{modified}, 'modified flag reset' );
  is( $e->{limit}{y}, 1, 'limit reset to one line' );
};

subtest 'shutDown() releases the buffer' => sub {
  my $e = new_editor();
  $e->insertText( 'abc', 3, !!0 );
  $e->shutDown();
  ok( !defined $e->{buffer}, 'buffer is undefined after shutDown()' );
};

subtest 'deleteSelect() removes the selected text' => sub {
  my $e = new_editor();
  $e->setBufLen( 0 );
  $e->insertText( 'abcdef', 6, !!0 );
  $e->setSelect( 1, 4, !!0 );
  $e->deleteSelect();
  is( $e->{buffer}, 'aef', 'selected text is removed' );
  is( $e->{curPtr}, 1, 'cursor moves to the start of the removed text' );
};

subtest 'deleteRange() removes the range around the cursor' => sub {
  my $e = new_editor();
  $e->setBufLen( 0 );
  $e->insertText( 'abcdef', 6, !!0 );
  $e->setCurPtr( 2, 0 );
  $e->deleteRange( 1, 3, !!0 );
  is( $e->{buffer}, 'adef', 'characters between the pointers are removed' );
};

subtest 'undo() removes the text inserted last' => sub {
  my $e = new_editor();
  $e->canUndo( !!0 );
  $e->insertText( 'abc', 3, !!0 );
  $e->canUndo( !!1 );
  $e->insertText( 'X', 1, !!0 );
  is( $e->{buffer}, 'abcX', 'text is inserted with undo recording' );
  $e->undo();
  is( $e->{buffer}, 'abc', 'undo removes the inserted text' );
};

subtest 'undo() restores text replaced by insertText()' => sub {
  my $e = new_editor();
  $e->canUndo( !!0 );
  $e->insertText( 'abc', 3, !!0 );
  $e->canUndo( !!1 );
  $e->setSelect( 0, 3, !!0 );
  $e->insertText( 'X', 1, !!0 );
  is( $e->{buffer}, 'X', 'selection is replaced' );
  $e->undo();
  is( $e->{buffer}, 'abc', 'undo restores the replaced text' );
};

subtest 'undo() after a cursor move does nothing' => sub {
  my $e = new_editor();
  $e->insertText( 'abc', 3, !!0 );
  $e->setCurPtr( 1, 0 );
  ok( eval { $e->undo(); 1 }, 'undo() survives the cursor move' );
  is( $e->{buffer}, 'abc', 'buffer is unchanged' );
};

subtest 'setBufSize() accepts any size without a capacity limit' => sub {
  my $e = new_editor();
  ok( $e->setBufSize( 100000 ), 'larger size is accepted' );
  $e->insertText( 'abc', 3, !!0 );
  is( $e->{buffer}, 'abc', 'buffer stays usable after setBufSize()' );
};

subtest 'newLine() keeps indentation with autoIndent' => sub {
  my $e = new_editor();
  $e->insertText( "  abc", 5, !!0 );
  $e->{autoIndent} = !!1;
  $e->newLine();
  is( 
    $e->{buffer}, 
    "  abc$INPUT_RECORD_SEPARATOR  ", 
    'indentation of the current line is copied'
  );
};

done_testing();
