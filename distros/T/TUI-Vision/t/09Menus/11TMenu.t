use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Menus::Menu';
}

# Mocking TMenuItem for testing purposes
{
  package TUI::Menus::MenuItem;
  sub main::TMenuItem (){ __PACKAGE__ }
  sub new { bless { next => undef }, shift }
}

# Test object creation with default constructor
my $menu = TMenu->new();
isa_ok( $menu, TMenu, 'Object is of class TMenu' );

# Test object creation with itemList
my $menu_item1      = TMenuItem->new();
my $menu_with_items = new_TMenu( $menu_item1 );
isa_ok( $menu_with_items, TMenu, 'Object is of class TMenu with items' );

# Test object creation with itemList and TheDefault
my $menu_item2        = TMenuItem->new();
my $menu_with_default = new_TMenu( $menu_item1, $menu_item2 );
isa_ok( $menu_with_default, TMenu,
  'Object is of class TMenu with items and default' );

# Test object creation with hash
my $menu_with_hash = TMenu->new( items => $menu_item1, default => $menu_item2 );
isa_ok( $menu_with_hash, TMenu,
  'Object is of class TMenu with hash' );

# Test DEMOLISH method
can_ok( $menu_with_items, 'DEMOLISH' );
lives_ok { $menu_with_items->DEMOLISH(0) }
  'DEMOLISH works correctly';

done_testing();
