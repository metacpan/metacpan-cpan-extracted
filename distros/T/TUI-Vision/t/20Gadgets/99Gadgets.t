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

done_testing();
