use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Views::DrawBuffer';
}

# Test object creation
my $buffer = TDrawBuffer->new();
isa_ok( $buffer, TDrawBuffer, 'Object is of class TDrawBuffer' );

# Test putAttribute method
can_ok( $buffer, 'putAttribute' );
$buffer->putAttribute( 0, 0x1f );
is( $buffer->[0], 0x1f00, 'putAttribute sets the attribute correctly' );

# Test putChar method
can_ok( $buffer, 'putChar' );
$buffer->putChar( 0, 'A' );
is( $buffer->[0], 0x1f41, 'putChar sets the character correctly' );

# Test moveBuf method
can_ok( $buffer, 'moveBuf' );
my $source = [ map { ord( 'A' ) } 0 .. 4 ];
$buffer->moveBuf( 0, $source, 0x1f, 5 );
is_deeply(
  [ @$buffer[ 0 .. 4 ] ], 
  [ map { 0x1f41 } 0 .. 4 ],
  'moveBuf moves the buffer correctly'
);

# Test moveChar method
can_ok( $buffer, 'moveChar' );
$buffer->moveChar( 0, 'B', 0x2f, 5 );
is_deeply(
  [ @$buffer[ 0 .. 4 ] ], 
  [ map { 0x2f42 } 0 .. 4 ],
  'moveChar moves the character correctly'
);

# Test moveCStr method
can_ok( $buffer, 'moveCStr' );
$buffer->moveCStr( 0, 'Hello~World', 0x1f2f );
is( $buffer->[0], 0x2f48, 'moveCStr moves the string correctly' );
is( $buffer->[5], 0x1f57, 'moveCStr toggles the attribute correctly' );

# Test moveStr method
can_ok( $buffer, 'moveStr' );
$buffer->moveStr( 0, 'Hello', 0x3f );
is_deeply(
  [ @$buffer[ 0 .. 4 ] ],
  [ map { 0x3f00 + ord( $_ ) } split //, 'Hello' ],
  'moveStr moves the string correctly'
);

done_testing();
