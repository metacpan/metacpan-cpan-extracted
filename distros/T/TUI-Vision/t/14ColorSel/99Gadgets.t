use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::ColorSel';
}

isa_ok( new_TColorDisplay( TRect->new(), 'Text' ), TColorDisplay() );
isa_ok( new_TColorItem( 'item', 0 ), TColorItem() );
isa_ok( new_TColorGroup( 'group' ), TColorGroup() );
isa_ok( new_TColorSelector( TRect->new(), csBackground ), TColorSelector() );
isa_ok( new_TMonoSelector( TRect->new() ), TMonoSelector() );
isa_ok( new_TColorGroupList( TRect->new(), undef, undef ), TColorGroupList() );
isa_ok( new_TColorItemList( TRect->new(), undef, undef ), TColorItemList() );

done_testing();
