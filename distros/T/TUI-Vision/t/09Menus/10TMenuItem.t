use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Views::View';
  use_ok 'TUI::Menus::MenuItem';
}

# Test object creation with command
my $menu_item = new_TMenuItem( 'Item', 1, 0x1234, 0, 'param' );
isa_ok( $menu_item, TMenuItem, 'Object is of class TMenuItem' );

# Test object creation with submenu
my $submenu = new_TMenuItem( 'Sub', 0x5678, undef );
isa_ok( $submenu, TMenuItem, 'Object is of class TMenuItem' );

# Test object creation with hash
my $menu_hash = TMenuItem->new(
  name => 'Hash', keyCode => 0x9ABC, subMenu => undef
);
isa_ok( $menu_hash, TMenuItem, 'Object is of class TMenuItem' );

# Test append method
can_ok( $menu_item, 'append' );
$menu_item->append( $submenu );
is( $menu_item->{next}, $submenu, 'append sets next correctly' );

# Test newLine method
can_ok( TMenuItem, 'newLine' );
my $newline = newLine();
isa_ok( $newline, TMenuItem, 'newLine returns a TMenuItem object' );

# Test DEMOLISH method
can_ok( $menu_item, 'DEMOLISH' );
lives_ok { $menu_item->DEMOLISH(0) }
  'DEMOLISH works correctly';

done_testing();
