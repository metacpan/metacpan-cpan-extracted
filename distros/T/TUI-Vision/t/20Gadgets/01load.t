use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Gadgets::Const';
  use_ok 'TUI::Gadgets::PrintConstants';
  use_ok 'TUI::Gadgets::EventViewer';
  use_ok 'TUI::Gadgets::HeapView';
  use_ok 'TUI::Gadgets::ClockView';
}

isa_ok(
  TEventViewer->new( bounds => TRect->new(), bufSize => 0 ), TEventViewer()
);
isa_ok( THeapView->new( bounds => TRect->new() ), THeapView() );
isa_ok( TClockView->new( bounds => TRect->new() ), TClockView() );

done_testing();
