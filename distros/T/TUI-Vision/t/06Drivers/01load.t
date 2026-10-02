use strict;
use warnings;

use Test::More;

BEGIN {
  if ( $^O ne 'MSWin32' ) { 
    plan skip_all => 'No TTY available'
      unless -t STDIN
          && -t STDOUT
          && defined( $ENV{TERM} )
          && $ENV{TERM} ne 'dumb';
  }
}

BEGIN {
  use_ok 'TUI::Drivers::Const', qw( eventQSize );
  use_ok 'TUI::Drivers::Util';
  use_ok 'TUI::Drivers::Colors';
  use_ok 'TUI::Drivers::HardwareInfo';
  use_ok 'TUI::Drivers::Display';
  use_ok 'TUI::Drivers::Screen';
  use_ok 'TUI::Drivers::SystemError';
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Drivers::HWMouse';
  use_ok 'TUI::Drivers::Mouse';
  use_ok 'TUI::Drivers::EventQueue';
  use_ok 'TUI::Drivers::ScreenCharacter';
  use_ok 'TUI::Drivers::Color';
  use_ok 'TUI::Drivers::ColorAttr';
  use_ok 'TUI::Drivers::AttrPair';
  use_ok 'TUI::Drivers::ScreenCell';
}

is( eventQSize, 16, 'eventQSize is 16' );
ok( THardwareInfo->getPlatform(),   'THardwareInfo is initiated' );
ok( TDisplay->getCrtMode(),         'TDisplay is initiated' );
ok( TScreen->getCrtMode(),          'TScreen is initiated' );
ok( TSystemError->can( 'suspend' ), 'TSystemError can suspend' );
ok( TEventQueue->can( 'suspend' ),  'TEventQueue can suspend' );

use_ok 'MouseEventType';
use_ok 'CharScanType';
use_ok 'KeyDownEvent';
use_ok 'MessageEvent';

isa_ok( CharScanType->new(),   'CharScanType' );
isa_ok( KeyDownEvent->new(),   'KeyDownEvent' );
isa_ok( MessageEvent->new(),   'MessageEvent' );
isa_ok( MouseEventType->new(), 'MouseEventType' );

isa_ok( TEvent->new(),      TEvent );
isa_ok( TScreenCharacter->new(),   TScreenCharacter );
isa_ok( TColor->new(),      TColor );
isa_ok( TColorAttr->new(),  TColorAttr );
isa_ok( TAttrPair->new(),   TAttrPair );
isa_ok( TScreenCell->new(), TScreenCell );

SKIP: {
  skip 'No mouse available', 2 unless THardwareInfo->getButtonCount();
  ok( THWMouse->present(), 'THWMouse is present' );
  ok( TMouse->present(),   'TMouse is present' );
}

done_testing();
