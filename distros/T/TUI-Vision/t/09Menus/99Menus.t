use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Menus';
}

is( ord( cpMenuView ), 0x02, 'cpMenuView begins with "\x02"' );
isa_ok( TMenu->new(), TMenu );
isa_ok( new_TMenuItem( 'One', 1, 0x1234 ), TMenuItem );
isa_ok( new_TSubMenu( 'Two', 0x2345 ), TSubMenu );
isa_ok( new_TMenuView( TRect->new() ), TMenuView );
isa_ok( new_TMenuBar( TRect->new(), TMenu->new() ), TMenuBar );
isa_ok( new_TMenuBox( TRect->new(), undef, undef ), TMenuBox );
isa_ok( new_TStatusItem( 'One', 0x1234, 1 ), TStatusItem );
isa_ok( new_TStatusDef( 1, 2 ), TStatusDef );
isa_ok( new_TStatusLine( TRect->new(), undef ), TStatusLine );

done_testing();
