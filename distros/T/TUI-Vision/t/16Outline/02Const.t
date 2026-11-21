use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Outline::Const', qw( :ovXXXX :cmXXXX :cpXXXX );
}

is( ovExpanded, 0x01, 'ovExpanded is 0x01' );
is( ovChildren, 0x02, 'ovChildren is 0x02' );
is( ovLast,     0x04, 'ovLast is 0x04' );
is( cmOutlineItemSelected, 301, 'cmOutlineItemSelected is 301' );
is( cpOutlineViewer, "\x06\x07\x03\x08", 'cpOutlineViewer palette bytes' );

done_testing();
