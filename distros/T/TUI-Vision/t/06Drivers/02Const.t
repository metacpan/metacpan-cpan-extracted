use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Drivers::Const', qw(
    eventQSize
    :evXXXX
    :mbXXXX
    :meXXXX
  );
}

is( eventQSize,    16,     'eventQSize is 16' );

is( evMouseDown,   0x0001, 'evMouseDown is 0x0001' );
is( evMouseUp,     0x0002, 'evMouseUp is 0x0002' );
is( evMouseMove,   0x0004, 'evMouseMove is 0x0004' );
is( evMouseAuto,   0x0008, 'evMouseAuto is 0x0008' );
is( evKeyDown,     0x0010, 'evKeyDown is 0x0010' );
is( evCommand,     0x0100, 'evCommand is 0x0100' );
is( evBroadcast,   0x0200, 'evBroadcast is 0x0200' );
is( evNothing,     0x0000, 'evNothing is 0x0000' );
is( evMouse,       0x000f, 'evMouse is 0x000f' );
is( evKeyboard,    0x0010, 'evKeyboard is 0x0010' );
is( evMessage,     0xFF00, 'evMessage is 0xFF00' );

is( mbLeftButton,  0x01,   'mbLeftButton is 0x01' );
is( mbRightButton, 0x02,   'mbRightButton is 0x02' );

is( meMouseMoved,  0x01,   'meMouseMoved is 0x01' );
is( meDoubleClick, 0x02,   'meDoubleClick is 0x02' );

done_testing();
