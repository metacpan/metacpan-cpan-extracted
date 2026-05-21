use strict;
use warnings;

use Test::More;

# Mocking 'TUI::Drivers::HardwareInfo' for testing purposes
BEGIN {
  package TUI::Drivers::HardwareInfo;
  use Exporter 'import';
  our @EXPORT = qw( THardwareInfo );
  use TUI::Drivers::Const qw(
    evKeyDown
    kbAltShift
    kbDel
    kbCtrlShift
    kbIns
    kbShift
  );
  sub THardwareInfo (){__PACKAGE__ }
  my $hit;
  sub getKeyEvent {
    my ( $class, $ev ) = @_;
    $hit++;
    if ( $hit == 1 ) {
      $ev->{what}                     = evKeyDown;
      $ev->{keyDown}{keyCode}         = ord( ' ' );
      $ev->{keyDown}{controlKeyState} = kbAltShift;
      return 1;
    }
    elsif ( $hit == 2 ) {
      $ev->{what}                     = evKeyDown;
      $ev->{keyDown}{keyCode}         = kbDel;
      $ev->{keyDown}{controlKeyState} = kbCtrlShift;
      return 1;
    }
    elsif ( $hit == 3 ) {
      $ev->{what}                     = evKeyDown;
      $ev->{keyDown}{keyCode}         = kbIns;
      $ev->{keyDown}{controlKeyState} = kbShift;
      return 1;
    }
    return 0;
  } #/ sub getKeyEvent
  $INC{"TUI/Drivers/HardwareInfo.pm"} = 1;
}

BEGIN {
  use_ok 'TUI::Objects::Point';
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Drivers::Const', qw(
    :evXXXX
    kbAltSpace
    kbCtrlDel
    kbShiftDel
    kbCtrlIns
    kbShiftIns
  );
  use_ok 'TUI::Drivers::HardwareInfo';
}
use_ok 'CharScanType';
use_ok 'MouseEventType';
use_ok 'KeyDownEvent';
use_ok 'MessageEvent';

# Test object creation for mouse event
my $mouse_event = TEvent->new(
  what  => evMouse,
  mouse => {
    where           => [ 10, 20 ],
    eventFlags      => 1,
    controlKeyState => 2,
    buttons         => 3,
  }
);

isa_ok( $mouse_event, TEvent, 'Object is of class TEvent' );
is( $mouse_event->{what}, evMouse, 'Mouse event type is set correctly' );
is_deeply(
  $mouse_event->{mouse},
  my $me = MouseEventType->new(
    where => TPoint->new(
      x => 10,
      y => 20,
    ),
    eventFlags      => 1,
    controlKeyState => 2,
    buttons         => 3,
  ),
  'Mouse event data is set correctly'
);

# Test object creation for keyboard event
my $key_event = TEvent->new(
  what    => evKeyboard,
  keyDown => {
    charScan => CharScanType->new(
      charCode => 1,
      scanCode => 2,
    ),
    controlKeyState => 69,
  }
);

isa_ok( $key_event, TEvent, 'Object is of class TEvent' );
is( $key_event->{what}, evKeyboard, 'Keyboard event type is set correctly' );
is_deeply(
  $key_event->{keyDown},
  KeyDownEvent->new(
    keyCode         => 0x201,
    controlKeyState => 69
  ),
  'Keyboard event data is set correctly'
);

# Test object creation for message event
my $message_event = TEvent->new(
  what    => evMessage,
  message => {
    command  => 1,
    infoLong => 0x12345678,
  }
);

isa_ok( $message_event, TEvent, 'Object is of class TEvent' );
is( $message_event->{what}, evMessage, 'Message event type is set correctly' );
is_deeply(
  $message_event->{message},
  MessageEvent->new(
    command  => 1,
    infoLong => 0x12345678,
  ),
  'Message event data is set correctly'
);

# Test getKeyEvent method
subtest 'getKeyEvent method' => sub {
  plan tests => 5;
  my $key_event_test = TEvent->new( what => evKeyboard );
  is( ref($key_event_test->{keyDown}), 'KeyDownEvent',
    'Keyboard event data is set correctly' );

  $key_event_test->getKeyEvent();
  is( $key_event_test->{keyDown}{keyCode}, kbAltSpace,
    'getKeyEvent handles Alt-Space correctly' );

  $key_event_test->getKeyEvent();
  is( $key_event_test->{keyDown}{keyCode}, kbCtrlDel,
    'getKeyEvent handles Ctrl-Del correctly' );

  $key_event_test->getKeyEvent();
  is( $key_event_test->{keyDown}{keyCode}, kbShiftIns,
    'getKeyEvent handles Shift-Ins correctly' );

  $key_event_test->getKeyEvent();
  is( $key_event_test->{what}, evNothing,
    'getKeyEvent handles no event correctly' );
};

done_testing();
