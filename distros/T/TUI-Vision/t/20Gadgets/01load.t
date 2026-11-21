use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Gadgets::PrintConstants';
  use_ok 'TUI::Gadgets::EventViewer';
  use_ok 'TUI::Gadgets::HeapView';
  use_ok 'TUI::Gadgets::ClockView';
  use_ok 'TUI::Gadgets::ClickTester';
  use_ok 'TUI::Gadgets::MouseDialog';
  use_ok 'TUI::Gadgets::LineCollection';
  use_ok 'TUI::Gadgets::FileViewer';
  use_ok 'TUI::Gadgets::FileWindow';
  use_ok 'TUI::Gadgets::Table';
  use_ok 'TUI::Gadgets::Report';
  use_ok 'TUI::Gadgets::AsciiChart';
  use_ok 'TUI::Gadgets::CalcDisplay';
  use_ok 'TUI::Gadgets::Calculator';
  use_ok 'TUI::Gadgets::CalendarView';
  use_ok 'TUI::Gadgets::CalendarWindow';
  use_ok 'TUI::Gadgets::PuzzleView';
  use_ok 'TUI::Gadgets::PuzzleWindow';
}

isa_ok(
  TEventViewer->new( bounds => TRect->new(), bufSize => 0 ), TEventViewer()
);
isa_ok( THeapView->new( bounds => TRect->new() ), THeapView() );
isa_ok( TClockView->new( bounds => TRect->new() ), TClockView() );
isa_ok( TClickTester->new( bounds => TRect->new(), text => 'text' ), 
  TClickTester() );
isa_ok( TMouseDialog->new(), TMouseDialog() );
isa_ok( TLineCollection->new( limit => 10, delta => 5 ), TLineCollection() );
isa_ok( TFileViewer->new( bounds => TRect->new(), hScrollBar => undef, 
  vScrollBar => undef, fileName => $0 ), TFileViewer() );
isa_ok( TFileWindow->new( fileName => $0 ), TFileWindow() );
isa_ok( TTable->new( bounds => TRect->new() ), TTable() );
isa_ok( TReport->new( bounds => TRect->new() ), TReport() );
isa_ok( TAsciiChart->new(), TAsciiChart() );
isa_ok( TCalcDisplay->new( bounds => TRect->new() ), TCalcDisplay() );
isa_ok( TCalculator->new(), TCalculator() );
isa_ok( TCalendarView->new( bounds => TRect->new() ), TCalendarView() );
isa_ok( TCalendarWindow->new(), TCalendarWindow() );
isa_ok( TPuzzleView->new( bounds => TRect->new() ), TPuzzleView() );
isa_ok( TPuzzleWindow->new(), TPuzzleWindow() );

done_testing();
