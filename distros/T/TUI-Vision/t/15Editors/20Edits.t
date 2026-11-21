use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;

my $builder = Test::More->builder;
binmode $builder->output,         ':encoding(UTF-8)';
binmode $builder->failure_output, ':encoding(UTF-8)';
binmode $builder->todo_output,    ':encoding(UTF-8)';

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::DrawBuffer';
  use_ok 'TUI::Editors::Editor';
  use_ok 'TUI::Editors::Editor::Edits';
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

subtest 'buffer access uses Perl character positions' => sub {
  my $e = new_editor();
  $e->insertText( "aä界b", 4, !!0 );

  is( $e->bufPtr( 2 ), 2, 'bufPtr preserves logical position' );
  is( $e->bufChar( 0 ), 'a', 'ASCII character' );
  is( $e->bufChar( 1 ), 'ä', 'Unicode character' );
  is( $e->bufChar( 2 ), '界', 'wide Unicode character' );
};

subtest 'character movement treats line endings as logical units' => sub {
  my $e = new_editor();
  $e->insertText( "a\r\nb\nc\rd", 8, !!0 );

  is( $e->nextChar( 0 ), 1, 'next character' );
  is( $e->nextChar( 1 ), 3, 'next skips CRLF' );
  is( $e->nextChar( 4 ), 5, 'next skips LF' );
  is( $e->nextChar( 6 ), 7, 'next skips CR' );

  is( $e->prevChar( 3 ), 1, 'previous skips CRLF' );
  is( $e->prevChar( 5 ), 4, 'previous skips LF' );
  is( $e->prevChar( 7 ), 6, 'previous skips CR' );

  is( $e->prevChar( 0 ), 0, 'previous stays at buffer start' );
  is( $e->nextChar( $e->bufLen ), $e->bufLen,
    'next stays at buffer end' );
};

subtest 'formatLine renders tabs, Unicode and selection' => sub {
  my $e = new_editor();
  my $b = TDrawBuffer->new();

  $e->insertText( "A\t界B", 4, !!0 );
  $e->{selStart} = 1;
  $e->{selEnd}   = 3;

  $e->formatLine( $b, 0, 12, 0x0201 );

  is( $b->[0]->character->getText, 'A', 'normal character' );
  is( 0 + $b->[0]->attribute, 0x01, 'normal attribute' );

  is( $b->[1]->character->getText, ' ', 'tab starts with space' );
  is( 0 + $b->[1]->attribute, 0x02, 'tab uses selected attribute' );

  is( $b->[$_]->character->getText, ' ', "tab cell $_" ) for 2 .. 7;

  is( $b->[8]->character->getText, '界', 'wide character' );
  is( 0 + $b->[8]->attribute, 0x02, 'wide character selected' );
  TODO: {
    local $TODO = 'Combining character rendering not implemented';
    ok(
      $b->[9] && $b->[9]->character->isWideCharTrail, 
      'wide character trail'
    );
  }

  is( $b->[10]->character->getText, 'B', 'character after wide character' );
  is( 0 + $b->[10]->attribute, 0x01, 'normal attribute restored' );

  is( $b->[11]->character->getText, ' ', 'remaining cell is padded' );
};

subtest 'formatLine keeps combining character at right edge' => sub {
  my $e = new_editor();
  my $b = TDrawBuffer->new();

  $e->insertText( "abcde\x{0301}X", 7, !!0 );
  $e->formatLine( $b, 0, 5, 0x0201 );

  is( $b->[0]->character->getText, 'a', 'first cell' );
  is( $b->[3]->character->getText, 'd', 'cell before final character' );
  TODO: {
    local $TODO = 'Wide character trail not implemented';
    is( $b->[4]->character->getText, "e\x{0301}",
      'combining character is attached at right edge' );
  }
};

done_testing();