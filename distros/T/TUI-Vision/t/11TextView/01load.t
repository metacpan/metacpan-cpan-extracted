use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::ScrollBar';
  use_ok 'TUI::TextView::TextDevice';
  use_ok 'TUI::TextView::Terminal';
}

isa_ok(
  TTextDevice->new(
    bounds      => TRect->new(), 
    hScrollBar => TScrollBar->new( bounds => TRect->new() ), 
    vScrollBar => TScrollBar->new( bounds => TRect->new() ),
  ), TTextDevice()
);

isa_ok(
  TTerminal->new(
    bounds      => TRect->new(), 
    hScrollBar => TScrollBar->new( bounds => TRect->new() ), 
    vScrollBar => TScrollBar->new( bounds => TRect->new() ),
    bufSize    => 0,
  ), TTerminal()
);

done_testing();
