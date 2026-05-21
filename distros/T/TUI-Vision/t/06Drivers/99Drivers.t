use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Drivers';
}

is( eventQSize, 16, 'eventQSize is 16' );
ok( THardwareInfo->getPlatform(),   'THardwareInfo is initiated' );
ok( TDisplay->getCrtMode(),         'TDisplay is initiated' );
ok( TScreen->getCrtMode(),          'TScreen is initiated' );
ok( TSystemError->can( 'suspend' ), 'TSystemError can suspend' );
ok( TEventQueue->can( 'suspend' ),  'TEventQueue can suspend' );
ok( exists &cstrlen, 'cstrlen() exists' );

use_ok 'MouseEventType';
use_ok 'CharScanType';
use_ok 'KeyDownEvent';
use_ok 'MessageEvent';

isa_ok( CharScanType->new(),   'CharScanType' );
isa_ok( KeyDownEvent->new(),   'KeyDownEvent' );
isa_ok( MessageEvent->new(),   'MessageEvent' );
isa_ok( MouseEventType->new(), 'MouseEventType' );
isa_ok( new_TEvent(),           TEvent );

SKIP: {
  skip 'No mouse available', 2 unless THardwareInfo->getButtonCount();
  ok( THWMouse->present(), 'THWMouse is present' );
  ok( TMouse->present(),   'TMouse is present' );
}

done_testing();
