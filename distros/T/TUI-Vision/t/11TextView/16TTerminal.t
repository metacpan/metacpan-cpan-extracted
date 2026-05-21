use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::TextView::TextDevice';
  use_ok 'TUI::TextView::Terminal';
  use_ok 'TUI::Views::ScrollBar';
}

# Create object
my $term;
subtest 'Object creation' => sub {
  lives_ok {
    my $bounds = TRect->new( ax => 0, ay => 0, bx => 20, by => 10 );
    my $hBar = TScrollBar->new(
      bounds => TRect->new( ax => 0, ay => 0, bx => 10, by => 1 ) );
    my $vBar = TScrollBar->new(
      bounds => TRect->new( ax => 0, ay => 0, bx => 1, by => 10 ) );
    $term = TTerminal->from( $bounds, $hBar, $vBar, 12 );
  } 'TTerminal object created';
  isa_ok( $term, TTerminal );
};

# Test bufInc and bufDec
subtest 'bufInc and bufDec' => sub {
  my $pos = 0;
  $term->bufInc( \$pos );
  is( $pos, 1, 'bufInc increments position' );
  $pos = 0;
  $term->bufDec( \$pos );
  is( $pos, 11, 'bufDec wraps around correctly' );
};

# Test canInsert
subtest 'canInsert' => sub {
  $term->{queFront} = 2;
  $term->{queBack}  = 0;
  ok( $term->canInsert( 1 ), 'canInsert returns true when space available' );
};

# Test nextLine
subtest 'nextLine' => sub {
  $term->{buffer}   = "abc\ndef";
  $term->{queFront} = 6;
  my $pos = 0;
  $pos = $term->nextLine( $pos );
  is( $pos, 4, 'nextLine moves to next newline' );
};

# Test prevLines
subtest 'prevLines' => sub {
  $term->{buffer}   = "abc\ndef\nghi";
  $term->{queBack}  = 0;
  $term->{queFront} = 11;
  my $pos = 11;
  $pos = $term->prevLines( $pos, 1 );
  is( $pos, 8, 'prevLines returns a position' );
};

# Test do_sputn
subtest 'do_sputn' => sub {
  $term->{buffer}   = ' ' x 10;
  $term->{queFront} = 0;
  $term->{queBack}  = 0;
  my $count = $term->do_sputn( "abc\n", 4 );
  is( $count, 4, 'do_sputn returns correct count' );
  like( $term->{buffer}, qr/abc\n/, 'buffer contains written data' );
};

# Test queEmpty
subtest 'queEmpty' => sub {
  $term->{queFront} = $term->{queBack};
  ok( $term->queEmpty, 'queEmpty returns true when empty' );
};

done_testing();
