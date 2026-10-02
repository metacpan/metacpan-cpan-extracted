use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::ColorSel::Const', qw( csBackground );
  use_ok 'TUI::ColorSel::ColorDisplay';
  use_ok 'TUI::ColorSel::ColorItem';
  use_ok 'TUI::ColorSel::ColorGroup';
  use_ok 'TUI::ColorSel::ColorSelector';
  use_ok 'TUI::ColorSel::MonoSelector';
  use_ok 'TUI::ColorSel::ColorGroupList';
  use_ok 'TUI::ColorSel::ColorItemList';
  use_ok 'TUI::ColorSel::ColorDialog';
}

isa_ok( TColorDisplay->new( bounds => TRect->new(), aText => 'Text' ), 
  TColorDisplay() );
isa_ok( TColorItem->new( name => 'item', index => 0 ), TColorItem() );
isa_ok( TColorGroup->new( name => 'group' ), TColorGroup() );
isa_ok( TColorSelector->new( bounds => TRect->new(), selType => csBackground ), 
  TColorSelector() );
isa_ok( TMonoSelector->new( bounds => TRect->new() ), TMonoSelector() );
isa_ok( TColorGroupList->new( bounds => TRect->new(), scrollBar => undef, 
  groups => undef ), TColorGroupList() );
isa_ok( TColorItemList->new( bounds => TRect->new(), scrollBar => undef, 
  items => undef ), TColorItemList() );
isa_ok( TColorDialog->new( pal => undef, groups => undef ), TColorDialog() );

done_testing();
