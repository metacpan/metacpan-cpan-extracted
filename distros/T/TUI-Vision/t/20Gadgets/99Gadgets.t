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
isa_ok( new_TClickTester( TRect->new(), 'text' ), TClickTester() );
isa_ok( new_TMouseDialog(), TMouseDialog() );
isa_ok( new_TLineCollection( 5, 5 ), TLineCollection() );
isa_ok( new_TFileViewer( TRect->new(), undef, undef, $0 ), TFileViewer() );
isa_ok( new_TFileWindow( $0 ), TFileWindow() );
isa_ok( new_TTable( TRect->new() ), TTable() );
isa_ok( new_TReport( TRect->new() ), TReport() );
isa_ok( new_TAsciiChart(), TAsciiChart() );
isa_ok( new_TCalcDisplay( TRect->new() ), TCalcDisplay() );
isa_ok( new_TCalculator(), TCalculator() );
isa_ok( new_TCalendarView( TRect->new() ), TCalendarView() );
isa_ok( new_TCalendarWindow(), TCalendarWindow() );
isa_ok( new_TPuzzleView( TRect->new() ), TPuzzleView() );
isa_ok( new_TPuzzleWindow(), TPuzzleWindow() );

done_testing();
