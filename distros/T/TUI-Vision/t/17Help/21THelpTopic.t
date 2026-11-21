use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Help::HelpTopic';
  use_ok 'TUI::Objects::Point';
}

subtest 'paragraphs and displayed lines' => sub {
  my $topic = new_THelpTopic();
  is( $topic->numLines, 0, 'empty topic has no lines' );
  $topic->setWidth( 5 );
  $topic->addParagraph(
    TParagraph->new( text => 'alpha beta', size => 10, wrap => 1 ),
  );
  $topic->addParagraph(
    TParagraph->new( text => "one\r\ntwo", size => 8, wrap => 0 ),
  );
  is( $topic->numLines, 4, 'counts wrapped and explicit lines across paragraphs' );
  my $buffer = '';
  for my $request (
    [ 1, 'alpha ' ], [ 2, 'beta' ], [ 3, 'one' ], [ 4, 'two' ],
    [ 1, 'alpha ' ],
  ) {
    is( $topic->getLine( $request->[0], \$buffer, 80 ), $request->[1],
      'reads sequentially and can restart from the beginning' );
    is( $buffer, $request->[1], 'updates the output buffer' );
  }
  is( $topic->getLine( 1, \$buffer, 3 ), 'alp', 'limits the output length' );
  is( $topic->getLine( 2, \$buffer, 80 ), 'beta',
    'truncating output still advances past the complete line' );
  is( $topic->getLine( 5, \$buffer, 80 ), '', 'missing line returns empty text' );
};

subtest 'cross-reference values and locations' => sub {
  my $topic = new_THelpTopic();
  $topic->setWidth( 5 );
  $topic->addParagraph(
    TParagraph->new( text => 'alpha beta', size => 10, wrap => 1 ),
  );
  $topic->addParagraph(
    TParagraph->new( text => 'tail', size => 4, wrap => 0 ),
  );
  my $ref = TCrossRef->new( ref => 100, offset => 7, length => 4 );
  $topic->addCrossRef( $ref );
  $ref->ref( 200 );
  my $loc = TPoint->new();
  my ( $length, $context ) = ( 0, 0 );
  $topic->getCrossRef( 0, $loc, \$length, \$context );
  is_deeply( [ $loc->x, $loc->y, $length, $context ], [ 0, 2, 4, 100 ],
    'stores a value copy and locates a reference on a wrapped line' );

  $topic->setNumCrossRefs( 2 );
  is( $topic->getNumCrossRefs, 2, 'grows the reference array' );
  $ref->offset( 11 );
  $topic->setCrossRef( 1, $ref );
  $ref->ref( 300 );
  $topic->setNumCrossRefs( 3 );
  $topic->setNumCrossRefs( 2 );
  $topic->getCrossRef( 1, $loc, \$length, \$context );
  is_deeply( [ $loc->x, $loc->y, $length, $context ], [ 0, 3, 4, 200 ],
    'setCrossRef copies values and resizing preserves the retained records' );
  $topic->setNumCrossRefs( 0 );
  is( $topic->getNumCrossRefs, 0, 'can clear all cross-references' );
};

subtest 'wrapText' => sub {
  for my $case (
    [
      'line endings', "one\r\ntwo\n", 80, 0, 80,
      [ 'one', 5 ],   [ 'two', 9 ]
    ],
    [
      'word wrapping', 'alpha beta', 5, 1, 80,
      [ 'alpha ', 6 ], [ 'beta', 10 ]
    ],
    [
      'long word',        'abcdefgh end', 4, 1, 80,
      [ 'abcdefgh ', 9 ], [ 'end', 12 ]
    ],
    [
      'buffer limit', 'abcdef', 80, 0, 3,
      [ 'abc', 3 ],   [ 'def', 6 ]
    ],
    [
      'no scan limit', 'x' x 300, 80, 0, 400,
      [ 'x' x 300, 300 ]
    ],
    [ 'empty text', '', 80, 0, 80, [ '', 0 ] ],
    )
  {
    my ( $name, $text, $width, $wrap, $buflen, @lines ) = @$case;
    subtest $name => sub {
      my $topic = new_THelpTopic();
      $topic->setWidth( $width );
      my $offset = 0;
      my $buffer = '';
      for my $expected ( @lines ) {
        my $line = $topic->_wrapText(
          $text, length( $text ), \$offset, $wrap, \$buffer, $buflen,
        );
        is_deeply(
          [ $line, $buffer, $offset ],
          [ $expected->[0], @$expected ],
          'returns the line, updates the buffer and advances the offset'
        );
      }
      is( $wrap, $case->[3], 'does not modify the wrapping flag' );
    };
  } #/ for my $case ( [ 'line endings'...])
}; #/ 'wrapText' => sub

done_testing();
