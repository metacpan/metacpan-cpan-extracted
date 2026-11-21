use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Outline';
}

is( ovChildren, 0x02, 'ovChildren successfully imported' );
is( cmOutlineItemSelected, 301, 'cmOutlineItemSelected successfully imported' );

isa_ok( new_TNode( '', undef, undef, 1 ), TNode() );
isa_ok( new_TOutlineViewer( TRect->new(), undef, undef ), TOutlineViewer() );
isa_ok( new_TOutline( TRect->new(), undef, undef, new_TNode( 'Root' ) ),
  TOutline() );

done_testing();
