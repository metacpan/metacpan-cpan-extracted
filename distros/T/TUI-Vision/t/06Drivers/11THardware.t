use strict;
use warnings;

use Test::More;
use Test::Exception;

# Mocking 'Win32*' modules for testing purposes
BEGIN {
  no warnings 'redefine';
  package Win32;
  sub GetTickCount { 110 }
  $INC{"Win32.pm"} = 1;
}

BEGIN {
  package Win32::Console::PatchForRT33513;
  $INC{"Win32/Console/PatchForRT33513.pm"} = 1;
}

BEGIN {
  package Win32::Console;
  use Exporter 'import';
  our @EXPORT = qw(
    STD_INPUT_HANDLE
    STD_OUTPUT_HANDLE
    STD_ERROR_HANDLE
    ENABLE_PROCESSED_INPUT
    ENABLE_MOUSE_INPUT
    GENERIC_READ
    GENERIC_WRITE
    FILE_SHARE_READ
    FILE_SHARE_WRITE
  );
  sub RIGHT_ALT_PRESSED     (){ 0x0001 }
  sub LEFT_ALT_PRESSED      (){ 0x0002 }
  sub RIGHT_CTRL_PRESSED    (){ 0x0004 }
  sub LEFT_CTRL_PRESSED     (){ 0x0008 }
  sub SHIFT_PRESSED         (){ 0x0010 }
  sub NUMLOCK_ON            (){ 0x0020 }
  sub SCROLLLOCK_ON         (){ 0x0040 }
  sub CAPSLOCK_ON           (){ 0x0080 }
  sub ENHANCED_KEY          (){ 0x0100 }
  sub STD_INPUT_HANDLE      (){    -10 }
  sub STD_OUTPUT_HANDLE     (){    -11 }
  sub STD_ERROR_HANDLE      (){    -12 }
  sub ENABLE_PROCESSED_INPUT(){ 0x0001 }
  sub ENABLE_MOUSE_INPUT    (){ 0x0010 }
  sub GENERIC_READ          (){ 0x80000000 }
  sub GENERIC_WRITE         (){ 0x40000000 }
  sub FILE_SHARE_READ       (){ 0x00000001 }
  sub FILE_SHARE_WRITE      (){ 0x00000002 }
  
  sub new       { bless {}, shift }
  sub Mode      { 1 }
  sub Cursor    { ( 1,  1 ) }
  sub Size      { ( 80, 25 ) }
  sub Info      { ( 80, 25, 1, 1, 0, 0, 0, 79, 24 ) }
  sub Display   { }
  sub FillAttr  { }
  sub FillChar  { }
  sub MaxWindow { ( 80, 25 ) }
  sub Window    { }
  sub GetEvents { 1 }
  sub Input     { ( 1, 1, 1, 1, 1 ) }
  $INC{"Win32/Console.pm"} = 1;
}

BEGIN {
  package Win32API::File;
  sub OPEN_EXISTING () { 3 }
  sub createFile       { 1 }
  $INC{"Win32API/File.pm"} = 1;
}

BEGIN {
  use_ok 'TUI::Drivers::Const', qw( smCO80 );
  use_ok 'TUI::Drivers::HardwareInfo';
}

# Test object creation and INIT block
ok( THardwareInfo, 'THardwareInfo exists' );
ok( THardwareInfo->getPlatform(), 'THardwareInfo is initiated' );

# Test getTickCount method
can_ok( THardwareInfo, 'getTickCount' );
is( THardwareInfo->getTickCount(), 2,
  'getTickCount returns correct value' );

# Test getPlatform method
can_ok( THardwareInfo, 'getPlatform' );
is( THardwareInfo->getPlatform(), 'Windows',
  'getPlatform returns correct value' );

# Test setCaretSize and getCaretSize methods
can_ok( THardwareInfo, 'setCaretSize' );
can_ok( THardwareInfo, 'getCaretSize' );
THardwareInfo->setCaretSize( 10 );
is( THardwareInfo->getCaretSize(), 10,
  'setCaretSize and getCaretSize work correctly' );

# Test setCaretPosition method
can_ok( THardwareInfo, 'setCaretPosition' );
lives_ok { THardwareInfo->setCaretPosition( 10, 20 ) }
  'setCaretPosition works correctly';

# Test isCaretVisible method
can_ok( THardwareInfo, 'isCaretVisible' );
is( THardwareInfo->isCaretVisible(), 1,
  'isCaretVisible returns correct value' );

# Test getScreenRows and getScreenCols methods
can_ok( THardwareInfo, 'getScreenRows' );
can_ok( THardwareInfo, 'getScreenCols' );
is( THardwareInfo->getScreenRows(), 25,
  'getScreenRows returns correct value' );
is( THardwareInfo->getScreenCols(), 80,
  'getScreenCols returns correct value' );

# Test getScreenMode and setScreenMode methods
can_ok( THardwareInfo, 'getScreenMode' );
can_ok( THardwareInfo, 'setScreenMode' );
THardwareInfo->setScreenMode( smCO80 );
is( THardwareInfo->getScreenMode(), ( smCO80 ),
  'getScreenMode and setScreenMode work correctly' );

# Test clearScreen method
can_ok( THardwareInfo, 'clearScreen' );
lives_ok { THardwareInfo->clearScreen( 80, 25 ) } 
  'clearScreen works correctly';

# Test allocateScreenBuffer and freeScreenBuffer methods
can_ok( THardwareInfo, 'allocateScreenBuffer' );
can_ok( THardwareInfo, 'freeScreenBuffer' );
my $buffer = THardwareInfo->allocateScreenBuffer();
is( ref( $buffer ), 'ARRAY',
  'allocateScreenBuffer returns an array reference' );
THardwareInfo->freeScreenBuffer( $buffer );
is_deeply( $buffer, [], 'freeScreenBuffer works correctly' );

done_testing();
