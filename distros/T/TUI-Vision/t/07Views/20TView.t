use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::View::Cursor';
  use_ok 'TUI::Views::View::Exposed';
  use_ok 'TUI::Views::View::Write';
  use_ok 'TUI::Views::View';
}

isa_ok( TView->new( bounds => TRect->new() ), TView );

done_testing();
