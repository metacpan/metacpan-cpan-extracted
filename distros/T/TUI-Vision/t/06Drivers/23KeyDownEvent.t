use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Drivers::Event';
}
use_ok 'KeyDownEvent';

my $keyDownEvent;
# Test the creation of a new KeyDownEvent object
subtest 'new object creation' => sub {
  plan tests => 5;
  $keyDownEvent = KeyDownEvent->new( 
    keyCode => 0x203, controlKeyState => 0x0004 
  );
  isa_ok( $keyDownEvent, 'KeyDownEvent' );
  is( $keyDownEvent->{controlKeyState}, 0x0004,
    "controlKeyState is set correctly" );
  is( $keyDownEvent->{keyCode}, 0x203,
    "controlKeyState is set correctly" );
  is( $keyDownEvent->{charScan}{scanCode}, 0x02,
    "scanCode is is set correctly" );
  is( $keyDownEvent->{charScan}{charCode}, 0x03,
    "charCode is is set correctly" );
};

# Test the STORE and FETCH methods
subtest 'store and fetch methods' => sub {
  plan tests => 2;
  $keyDownEvent->{controlKeyState} -= 1;
  is( $keyDownEvent->{controlKeyState}, 0x0003,
    "controlKeyState is stored and fetched correctly" );
  $keyDownEvent->{charScan}{scanCode} += 0x10;
  is( $keyDownEvent->{keyCode}, 0x1203,
    "keyCode is stored and fetched correctly" );
};

# Test the exception handling
subtest 'exception handling' => sub {
  plan tests => 2;
  throws_ok { %$keyDownEvent = () } qr/restricted/,
    'Exception thrown on clear method';
  ok( $keyDownEvent->{keyCode}, "KeyDownEvent is not cleared" );
};

done_testing();
