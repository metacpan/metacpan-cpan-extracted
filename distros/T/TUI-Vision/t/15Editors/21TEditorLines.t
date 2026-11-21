use strict;
use warnings;

use Test::More;

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

subtest 'insertText() counts CR, LF and CRLF as line breaks' => sub {
  my $e = new_editor();
  $e->insertText( "ab\r\ncd\nef\rgh", 12, !!0 );
  is( $e->{curPos}{y}, 3, 'three line breaks move the cursor to line 3' );
  is( $e->{curPos}{x}, 2, 'cursor column at the end of the last line' );
  is( $e->{limit}{y}, 4, 'limit counts the lines' );
};

subtest 'line helpers handle all line break styles' => sub {
  my $e = new_editor();
  $e->insertText( "ab\r\ncd\nef", 9, !!0 );
  is( $e->lineStart( 5 ), 4, 'lineStart after LF' );
  is( $e->lineStart( 2 ), 0, 'lineStart before CRLF' );
  is( $e->lineEnd( 0 ), 2, 'lineEnd stops before CRLF' );
  is( $e->nextLine( 0 ), 4, 'nextLine skips CRLF' );
  is( $e->prevLine( 7 ), 4, 'prevLine from the last line' );
};

done_testing();
