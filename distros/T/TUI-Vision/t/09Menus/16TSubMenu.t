use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Menus::Menu';
  use_ok 'TUI::Menus::MenuItem';
  use_ok 'TUI::Menus::SubMenu';
}

my $add_sub_menu = sub { goto &TUI::Menus::SubMenu::_add_sub_menu };
my $add_menu_item = sub { goto &TUI::Menus::SubMenu::_add_menu_item };

# Test object creation
my $submenu1 = new_TSubMenu( 'One', 0x1234, 0 );
isa_ok( $submenu1, TSubMenu, 'Object is of class TSubMenu' );

my $submenu2 = new_TSubMenu( 'Two', 0x5678, 0 );
isa_ok( $submenu2, TSubMenu, 'Object is of class TSubMenu' );

my $submenu3 = TSubMenu->new( name => 'Three', keyCode => 0x5678 );
isa_ok( $submenu3, TSubMenu, 'Object is of class TSubMenu' );

# Test &$add_menu_item method
can_ok( $submenu1, '_add_menu_item' );
my $menu_item = new_TMenuItem( 'Open', 2, 0x2345, 0, 'param', undef );
isa_ok( $menu_item, TMenuItem, 'Object is of class TMenuItem' );
$submenu1->$add_menu_item( $menu_item );
is( $submenu1->{subMenu}{items}, $menu_item,
  '&$add_menu_item adds menu item correctly' );

# Test &$add_sub_menu method
can_ok( $submenu1, '_add_sub_menu' );
$submenu1->$add_sub_menu( $submenu2 );
is( $submenu1->{next}, $submenu2, '&$add_sub_menu adds submenu correctly' );

my $submenu;
lives_ok {
  $submenu =
    new_TSubMenu( "Hello", 0x0000 ) +
      new_TMenuItem( "One", 1, 0x1000 ) +
      newLine() +
      new_TMenuItem( "~T~wo", 2, 0x2000, 0, "Alt-T" );
} 'operator "+" adds menu item and submenu correctly';
isa_ok( $submenu, TSubMenu, 'Object is of class TSubMenu' );

done_testing();
