use strict;
use warnings;

use Test::More;
use Test::Exception;

use Devel::StrictMode;
use List::Util qw( max );

BEGIN {
  use_ok 'TUI::Views::Const', qw( maxViewWidth );
  use_ok 'TUI::Views::DrawBuffer';
}

sub asBios {
  my ( $cell ) = @_;
  return ( $cell->attribute()->asBIOS() << 8 ) 
    | ord( $cell->character()->getText() );
}

subtest 'constructor' => sub {
  my $buffer = TDrawBuffer->new();
  isa_ok( $buffer, TDrawBuffer );
};

subtest 'putAttribute' => sub {
  my $buffer = TDrawBuffer->new();
  $buffer->putAttribute( 0, 0x1f );
  is( asBios( $buffer->[0] ), 0x1f00, 'stores attribute' );
};

subtest 'putChar' => sub {
  my $buffer = TDrawBuffer->new();
  $buffer->putAttribute( 0, 0x1f );
  $buffer->putChar( 0, 'A' );
  is( asBios( $buffer->[0] ), 0x1f41, 'stores character' );
};

subtest 'moveBuf' => sub {
  my $buffer = TDrawBuffer->new();
  my $source = [ map { ord 'A' } 0 .. 4 ];
  $buffer->moveBuf( 0, $source, 0x1f, 5 );
  is_deeply(
    [ map { asBios( $_ ) } @$buffer[ 0 .. 4 ] ],
    [ map { 0x1f41 } 0 .. 4 ],
    'moves data correctly'
  );
};

subtest 'moveChar' => sub {
  my $buffer = TDrawBuffer->new();
  $buffer->moveChar( 0, 'B', 0x2f, 5 );
  is_deeply(
    [ map { asBios( $_ ) } @$buffer[ 0 .. 4 ] ],
    [ map { 0x2f42 } 0 .. 4 ],
    'moves data correctly'
  );
};

subtest 'moveCStr' => sub {
  my $buffer = TDrawBuffer->new();
  $buffer->moveCStr( 0, 'Hello~World', 0x1f2f );
  is( asBios( $buffer->[0] ), 0x2f48, 'uses first attribute' );
  is( asBios( $buffer->[5] ), 0x1f57, 'toggles attribute' );
};

subtest 'moveStr' => sub {
  my $buffer = TDrawBuffer->new();
  $buffer->moveStr( 0, 'Hello', 0x3f );
  is_deeply(
    [ map { asBios( $_ ) } @$buffer[ 0 .. 4 ] ],
    [ map { 0x3f00 + ord $_ } split //, 'Hello' ],
    'moves data correctly'
  );
};

subtest 'allocates cells on first write' => sub {
  my $buffer = TDrawBuffer->new();
  is( scalar @$buffer, 0, 'constructor does not allocate cells' );

  $buffer->putChar( 3, 'X' );
  ok( !defined $buffer->[0], 'prefix remains unallocated' );
  ok(  defined $buffer->[3], 'written cell allocated' );
  is( $buffer->[3]->character()->getText(), 'X', 'character stored' );
};

subtest 'putAttribute allocates cell' => sub {
  my $buffer = TDrawBuffer->new();
  ok( !defined $buffer->[5], 'cell initially missing' );
  $buffer->putAttribute( 5, 7 );
  ok( defined $buffer->[5], 'cell allocated' );
};

subtest 'reuses existing cells' => sub {
  my $buffer = TDrawBuffer->new();
  $buffer->putChar( 0, 'A' );
  my $cell = $buffer->[0];
  $buffer->putAttribute( 0, 7 );
  is( $buffer->[0], $cell, 'existing cell reused' );
};

subtest 'moveStr allocates written range' => sub {
  my $buffer = TDrawBuffer->new();
  is( $buffer->moveStr( 2, 'abc', 7 ), 3, 'returns written length' );
  ok( !defined $buffer->[0], 'unwritten prefix remains unallocated' );
  ok(  defined $buffer->[2], 'first written cell allocated' );
  ok(  defined $buffer->[4], 'last written cell allocated' );
};

subtest 'moveChar allocates target range only' => sub {
  my $buffer = TDrawBuffer->new();
  $buffer->moveChar( 2, 'X', 7, 3 );
  ok( !defined $buffer->[1], 'prefix not allocated' );
  ok(  defined $buffer->[2], 'first cell allocated' );
  ok(  defined $buffer->[4], 'last cell allocated' );
  ok( !defined $buffer->[5], 'suffix not allocated' );
};

SKIP: {
  skip 'Set EXTENDED_TESTING=1 to run boundary tests', 4
    unless STRICT;

  subtest 'putChar rejects out-of-bounds writes' => sub {
    my $buffer = TDrawBuffer->new();
    dies_ok { $buffer->putChar( 100_000, 'X' ) } 
      'putChar dies on out-of-bounds write';
  };

  subtest 'moveChar rejects range exceeding buffer size' => sub {
    my $buffer = TDrawBuffer->new();
    dies_ok { $buffer->moveChar( 100_000, 'X', 7, 10 ) }
      'moveChar dies when destination range exceeds buffer';
  };

  subtest 'moveStr rejects strings exceeding buffer size' => sub {
    my $buffer = TDrawBuffer->new();
    dies_ok { $buffer->moveStr( 100_000, 'abcdefghijklmnopqrstuvwxyz', 7 ) }
      'moveStr dies when write exceeds buffer';
  };

  subtest 'highest valid index remains writable' => sub {
    my $buffer = TDrawBuffer->new();
    no warnings 'once';
    my $maxLen = max(
      8 + max(
        $TUI::Drivers::Screen::screenWidth,
        $TUI::Drivers::Screen::screenHeight,
      ),
      maxViewWidth,
    );
    lives_ok { $buffer->putChar( $maxLen - 1, 'X' ) }
      'last valid index is writable';
    is(
      $buffer->[ $maxLen - 1 ]->character()->getText(),
      'X',
      'character stored at last valid position'
    );
  }; 
}

done_testing();
