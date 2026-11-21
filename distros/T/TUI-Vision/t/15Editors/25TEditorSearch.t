use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::Const', qw( cmCancel cmOK );
  use_ok 'TUI::Editors::Const', qw( :edXXXX :efXXXX );
  use_ok 'TUI::Editors::Editor';
}

sub new_editor {
  my ( $text ) = @_;
  my $e = TEditor->new(
    bounds     => TRect->new( ax => 0, ay => 0, bx => 20, by => 5 ),
    hScrollBar => undef,
    vScrollBar => undef,
    indicator  => undef,
    bufSize    => 0,
  );
  $e->insertText( $text, length( $text ), !!0 );
  return $e;
}

subtest 'search() selects the next match from the cursor' => sub {
  my $e = new_editor( 'one two one' );
  $e->setCurPtr( 0, 0 );
  ok( $e->search( 'one', 0 ), 'search() finds the first match' );
  is( $e->{selStart}, 0, 'match start is selected' );
  is( $e->{selEnd}, 3, 'match end is selected' );
  $e->setCurPtr( 3, 0 );
  ok( $e->search( 'one', 0 ), 'search() finds the next match' );
  is( $e->{selStart}, 8, 'second match is selected' );
};

subtest 'search() is case-insensitive unless efCaseSensitive is set' => sub {
  my $e = new_editor( 'Abc abc' );
  $e->setCurPtr( 0, 0 );
  ok( $e->search( 'abc', 0 ), 'case-insensitive search finds a match' );
  is( $e->{selStart}, 0, 'first match with different case is selected' );
  ok( $e->search( 'abc', efCaseSensitive ), 'case-sensitive search' );
  is( $e->{selStart}, 4, 'only the exact case match is selected' );
};

subtest 'search() with efWholeWordsOnly skips partial words' => sub {
  my $e = new_editor( 'cat concat cat' );
  $e->setCurPtr( 1, 0 );
  ok( $e->search( 'cat', efWholeWordsOnly ), 'whole word search succeeds' );
  is( $e->{selStart}, 11, '"cat" inside "concat" is skipped' );
};

subtest 'search() fails and keeps the selection without a match' => sub {
  my $e = new_editor( 'abc' );
  ok( !$e->search( 'xyz', 0 ), 'search() reports failure' );
  is( $e->{selStart}, $e->{selEnd}, 'no text is selected' );
};

subtest 'doSearchReplace() replaces all matches with efReplaceAll' => sub {
  my $e = new_editor( 'banana' );
  local $TUI::Editors::Editor::findStr    = 'a';
  local $TUI::Editors::Editor::replaceStr = 'XY';
  local $TUI::Editors::Editor::editorFlags =
    efReplaceAll | efDoReplace | efCaseSensitive;
  $e->setCurPtr( 0, 0 );
  $e->doSearchReplace();
  is( $e->{buffer}, 'bXYnXYnXY', 'every match is replaced' );
};

subtest 'doSearchReplace() reports edSearchFailed without replace-all' => sub {
  my $e = new_editor( 'abc' );
  my @messages;
  local $TUI::Editors::Editor::editorDialog = sub {
    push @messages, $_[0];
    return cmOK;
  };
  local $TUI::Editors::Editor::findStr    = 'xyz';
  local $TUI::Editors::Editor::editorFlags = 0;
  $e->doSearchReplace();
  is_deeply( \@messages, [ edSearchFailed ], 'edSearchFailed is reported' );
};

subtest 'find() takes the search text and options from the dialog' => sub {
  my $e = new_editor( 'one two' );
  local $TUI::Editors::Editor::editorDialog = sub {
    my ( $cmd, $rec ) = @_;
    return cmCancel unless $cmd == edFind;
    $rec->find( 'two' );
    $rec->options( efCaseSensitive | efDoReplace );
    return cmOK;
  };
  local $TUI::Editors::Editor::findStr    = '';
  local $TUI::Editors::Editor::editorFlags = 0;
  $e->setCurPtr( 0, 0 );
  $e->find();
  is( $TUI::Editors::Editor::findStr, 'two', 'search text is stored' );
  is( $TUI::Editors::Editor::editorFlags, efCaseSensitive,
    'efDoReplace is removed from the options' );
  is( $e->{selStart}, 4, 'the match is selected' );
};

subtest 'find() does nothing when the dialog is cancelled' => sub {
  my $e = new_editor( 'one two' );
  local $TUI::Editors::Editor::editorDialog = sub { cmCancel };
  local $TUI::Editors::Editor::findStr = 'two';
  $e->setCurPtr( 0, 0 );
  $e->find();
  is( $e->{selStart}, $e->{selEnd}, 'no text is selected' );
};

subtest 'replace() replaces all matches from the dialog values' => sub {
  my $e = new_editor( 'one one' );
  my @messages;
  local $TUI::Editors::Editor::editorDialog = sub {
    my ( $cmd, $rec ) = @_;
    push @messages, $cmd;
    return cmCancel unless $cmd == edReplace;
    $rec->find( 'one' );
    $rec->replace( 'two' );
    $rec->options( efReplaceAll | efCaseSensitive );
    return cmOK;
  };
  $e->setCurPtr( 0, 0 );
  $e->replace();
  is( $e->{buffer}, 'two two', 'all matches are replaced' );
  is_deeply( \@messages, [ edReplace ], 'no failed search is reported' );
};

done_testing();
