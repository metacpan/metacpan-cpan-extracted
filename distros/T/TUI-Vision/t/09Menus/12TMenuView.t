use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  require_ok 'TUI::Drivers::Const';
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Views::Palette';
  use_ok 'TUI::Menus::Menu';
  use_ok 'TUI::Menus::MenuItem';
  use_ok 'TUI::Menus::MenuView';
}

BEGIN {
  package MyMenuView;
  use TUI::Drivers::Const qw( evKeyDown kbEsc );
  use TUI::toolkit;
  extends 'TUI::Menus::MenuView';
  sub getEvent {
    $_[1]->{what} = evKeyDown;
    $_[1]->{keyDown}{keyCode} = kbEsc;
  }
  $INC{"MyMenuView.pm"} = 1;
}

# Test object creation with menu and parent
my $menu = new_TMenu(
  new_TMenuItem( 'One', 1, 0x1234 ),
  new_TMenuItem( 'Two', 2, 0x5678 ) 
);
my $parent_menu = TMenuView->new( bounds => TRect->new(), menu => $menu );
my $menu_view = MyMenuView->new( bounds => TRect->new(), menu => $menu, 
  parentMenu => $parent_menu );
isa_ok( $menu_view, TMenuView, 'Object is of class TMenuView' );

# Test object creation without menu and parent
my $menu_view_no_menu = TMenuView->new( bounds => TRect->new() );
isa_ok( $menu_view_no_menu, TMenuView,
  'Object is of class TMenuView without menu and parent' );

# Test execute method
can_ok( $menu_view, 'execute' );
is( $menu_view->execute(), 0, 'execute returns correct value' );

# Test findItem method
can_ok( $menu_view, 'findItem' );
is( $menu_view->findItem( 'A' ), undef, 'findItem returns correct value' );

# Test getItemRect method
can_ok( $menu_view, 'getItemRect' );
is_deeply( $menu_view->getItemRect( new_TMenuItem( 'Three', 3, 0x9ABC ) ),
  TRect->new(), 'getItemRect returns correct value' );

# Test getHelpCtx method
can_ok( $menu_view, 'getHelpCtx' );
is( $menu_view->getHelpCtx(), 0, 'getHelpCtx returns correct value' );

# Test getPalette method
can_ok( $menu_view, 'getPalette' );
my $palette = $menu_view->getPalette();
isa_ok( $palette, TPalette, 'getPalette returns a TPalette object' );

# Test handleEvent method
can_ok( $menu_view, 'handleEvent' );
lives_ok { $menu_view->handleEvent( TEvent->new() ) }
  'handleEvent works correctly';

# Test hotKey method
can_ok( $menu_view, 'hotKey' );
is( $menu_view->hotKey( 0 ), undef, 'hotKey returns correct value' );

done_testing();
