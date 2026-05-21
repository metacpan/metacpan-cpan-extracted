use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::Const';
  use_ok 'TUI::Views::CommandSet';
  use_ok 'TUI::Views::DrawBuffer';
  use_ok 'TUI::Views::Palette';
  use_ok 'TUI::Views::View::Cursor';
  use_ok 'TUI::Views::View::Exposed';
  use_ok 'TUI::Views::View::Write';
  use_ok 'TUI::Views::View';
  use_ok 'TUI::Views::Group';
  use_ok 'TUI::Views::Frame::Line';
  use_ok 'TUI::Views::Frame';
  use_ok 'TUI::Views::ScrollBar';
  use_ok 'TUI::Views::Scroller';
  use_ok 'TUI::Views::WindowInit';
  use_ok 'TUI::Views::Window';
  use_ok 'TUI::Views::ListViewer';
}

isa_ok( TCommandSet->new(), TCommandSet );
isa_ok( TPalette->new(), TPalette );
isa_ok( TView->new( bounds => TRect->new() ), TView );
isa_ok( TGroup->new( bounds => TRect->new() ), TGroup );
isa_ok( TFrame->new( bounds => TRect->new() ), TFrame );
isa_ok( TScrollBar->new( bounds => TRect->new() ), TScrollBar );
isa_ok(
  TScroller->new(
    bounds     => TRect->new(), 
    hScrollBar => TScrollBar->new( bounds => TRect->new() ), 
    vScrollBar => TScrollBar->new( bounds => TRect->new() ),
  ), TScroller
);
isa_ok( TWindowInit->new( cFrame => sub { } ), TWindowInit );
isa_ok(
  TWindow->new( bounds => TRect->new(), title => 'title', number => 1 ),
  TWindow
);
isa_ok( TListViewer->new( bounds => TRect->new(), numCols => 0, 
  hScrollBar => undef, vScrollBar => undef ), TListViewer );

done_testing();
