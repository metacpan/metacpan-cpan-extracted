use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::Group';
}

isa_ok( TGroup->new( bounds => TRect->new() ), TGroup );

done_testing();
