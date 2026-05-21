use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Gadgets';
}

isa_ok( new_TEventViewer( TRect->new(), 0 ), TEventViewer() );
isa_ok( new_THeapView( TRect->new() ), THeapView() );
isa_ok( new_TClockView( TRect->new() ), TClockView() );

done_testing();
