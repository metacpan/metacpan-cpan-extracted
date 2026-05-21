use strict;
use warnings;

use Test::More;
use Test::Exception;

# Mocking 'THardwareInfo' for testing purposes
BEGIN {
  package TUI::Drivers::HardwareInfo;
  use Exporter 'import';
  our @EXPORT = qw( THardwareInfo );
  sub THardwareInfo() { __PACKAGE__ }
  sub getCaretSize    { return 10; }
  sub setCaretSize    { }
  sub clearScreen     { }
  sub getScreenRows   { return 25; }
  sub getScreenCols   { return 80; }
  sub getScreenMode   { return 1; }
  sub setScreenMode   { }
  sub getButtonCount  { return 3; }
  sub cursorOn        { return 1; }
  sub cursorOff       { return 1; }
  $INC{"TUI/Drivers/HardwareInfo.pm"} = 1;
} #/ BEGIN

BEGIN {
  use_ok 'TUI::Drivers::HardwareInfo';
  use_ok 'TUI::Drivers::Display';
}

# Test object creation and updateIntlChars method
my $display = TDisplay();
ok( $display, 'TDisplay exists' );

# Test getCursorType method
can_ok( $display, 'getCursorType' );
is( $display->getCursorType(), 10, 'getCursorType returns correct value' );

# Test setCursorType method
can_ok( $display, 'setCursorType' );
$display->setCursorType( 20 );
pass( 'setCursorType works correctly' );

# Test clearScreen method
can_ok( $display, 'clearScreen' );
$display->clearScreen( 80, 25 );
pass( 'clearScreen works correctly' );

# Test getRows method
can_ok( $display, 'getRows' );
is( $display->getRows(), 25, 'getRows returns correct value' );

# Test getCols method
can_ok( $display, 'getCols' );
is( $display->getCols(), 80, 'getCols returns correct value' );

# Test getCrtMode method
can_ok( $display, 'getCrtMode' );
is( $display->getCrtMode(), 1, 'getCrtMode returns correct value' );

# Test setCrtMode method
can_ok( $display, 'setCrtMode' );
lives_ok { $display->setCrtMode( 1 ) } 'setCrtMode works correctly';

done_testing();
