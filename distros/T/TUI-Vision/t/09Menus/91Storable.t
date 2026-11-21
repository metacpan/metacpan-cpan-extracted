use strict;
use warnings;

use Test::More;
use Storable qw( freeze thaw );

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Menus::Menu';
  use_ok 'TUI::Menus::MenuItem';
  use_ok 'TUI::Menus::MenuView';
  use_ok 'TUI::Menus::MenuBar';
  use_ok 'TUI::Menus::MenuBox';
  use_ok 'TUI::Menus::MenuPopup';
  use_ok 'TUI::Menus::StatusLine';
  use_ok 'TUI::Menus::StatusDef';
  use_ok 'TUI::Menus::StatusItem';
}

subtest 'TMenuView Storable roundtrip' => sub {
  my $subItem = TMenuItem->new(
    name    => 'Recent file',
    command => 73,
    keyCode => 0x4321,
    helpCtx => 21,
    param   => 'latest.txt',
  );
  my $subMenu = TMenu->new( items => $subItem );
  my $separator = newLine();
  my $openItem = TMenuItem->new(
    name    => '~O~pen',
    command => 42,
    keyCode => 0x1234,
    helpCtx => 8,
    param   => 'Ctrl+O',
    next    => $separator,
  );
  $openItem->{disabled} = 1;
  my $menuItem = TMenuItem->new(
    name    => '~F~ile',
    command => 0,
    keyCode => 0,
    helpCtx => 7,
    subMenu => $subMenu,
    next    => $openItem,
  );
  my $menu = TMenu->new( items => $menuItem, default => $openItem );
  my $menuView = TMenuView->new(
    bounds => TRect->new( ax => 3, ay => 4, bx => 23, by => 5 ),
    menu   => $menu,
  );
  $menuView->current( $openItem );

  my $restored = thaw( freeze( $menuView ) );
  isa_ok( $restored, TMenuView );
  is_deeply( $restored->{origin}, { x => 3,  y => 4 }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 1 }, 'preserves size' );
  isa_ok( $restored->{menu}, TMenu );

  my $restoredMenuItem = $restored->{menu}{items};
  is( $restoredMenuItem->{name}, '~F~ile', 'preserves submenu item' );
  isa_ok( $restoredMenuItem->{subMenu}, TMenu );

  my $restoredSubItem = $restoredMenuItem->{subMenu}{items};
  is( $restoredSubItem->{name}, 'Recent file', 'preserves nested item' );
  is( $restoredSubItem->{command}, 73, 'preserves nested command' );
  is( $restoredSubItem->{param}, 'latest.txt', 'preserves nested parameter' );

  my $restoredOpenItem = $restoredMenuItem->{next};
  is( $restoredOpenItem->{name}, '~O~pen', 'preserves command item' );
  is( $restoredOpenItem->{command}, 42, 'preserves command' );
  is( $restoredOpenItem->{keyCode}, 0x1234, 'preserves key code' );
  is( $restoredOpenItem->{helpCtx}, 8, 'preserves help context' );
  is( $restoredOpenItem->{param}, 'Ctrl+O', 'preserves parameter' );
  ok( $restoredOpenItem->{disabled}, 'preserves disabled state' );
  is( $restoredOpenItem->{next}{name}, '', 'preserves separator' );
  is(
    $restored->{menu}->deflt, 
    $restoredMenuItem,
    'sets default to first item when reading'
  );
  is( $restored->current, undef, 'resets current item' );
  is( $restored->parentMenu, undef, 'clears parent menu' );
}; #/ 'TMenuView Storable roundtrip' => sub

subtest 'TMenuBar Storable roundtrip' => sub {
  my $item = TMenuItem->new(
    name    => '~F~ile',
    command => 42,
    keyCode => 0x1234,
    helpCtx => 8,
    param   => 'Ctrl+F',
  );
  my $menuBar = TMenuBar->new(
    bounds => TRect->new( ax => 3, ay => 0, bx => 23, by => 1 ),
    menu   => TMenu->new( items => $item ),
  );

  my $restored = thaw( freeze( $menuBar ) );
  isa_ok( $restored, TMenuBar );
  is_deeply( $restored->{origin}, { x => 3, y => 0 }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 1 }, 'preserves size' );
  isa_ok( $restored->{menu}, TMenu );
  is( $restored->{menu}{items}{name}, '~F~ile', 'restores menu item' );
  is( $restored->{menu}{items}{command}, 42, 'restores menu command' );
}; #/ 'TMenuBar Storable roundtrip' => sub

subtest 'TMenuBox Storable roundtrip' => sub {
  my $item = TMenuItem->new(
    name    => 'Open',
    command => 42,
    keyCode => 0x1234,
    param   => 'Ctrl+O',
    next    => newLine(),
  );
  my $menuBox = TMenuBox->new(
    bounds => TRect->new( ax => 2, ay => 3, bx => 42, by => 15 ),
    menu   => TMenu->new( items => $item ),
    parentMenu => undef,
  );

  my $restored = thaw( freeze( $menuBox ) );
  isa_ok( $restored, TMenuBox );
  is_deeply( $restored->{origin}, { x => 2, y => 3 }, 'preserves origin' );
  is_deeply( $restored->{size}, $menuBox->{size}, 'preserves menu bounds' );
  isa_ok( $restored->{menu}, TMenu );
  is( $restored->{menu}{items}{name}, 'Open', 'restores menu item' );
  is( $restored->{menu}{items}{command}, 42, 'restores menu command' );
  is( $restored->{menu}{items}{param}, 'Ctrl+O', 'restores menu parameter' );
  is( $restored->{menu}{items}{next}{name}, '', 'restores menu separator' );
  is( $restored->parentMenu, undef, 'clears parent menu' );
  is( $restored->current, undef, 'resets current item' );
}; #/ 'TMenuBox Storable roundtrip' => sub

subtest 'TMenuPopup Storable roundtrip' => sub {
  my $item = TMenuItem->new(
    name    => '~Q~uit',
    command => 42,
    keyCode => 0x1234,
    param   => 'Alt+Q',
  );
  my $popup = TMenuPopup->new(
    bounds => TRect->new( ax => 4, ay => 3, bx => 44, by => 15 ),
    menu   => TMenu->new( items => $item ),
  );

  my $restored = thaw( freeze( $popup ) );
  isa_ok( $restored, TMenuPopup );
  is_deeply( $restored->{origin}, $popup->{origin}, 'preserves origin' );
  is_deeply( $restored->{size}, $popup->{size}, 'preserves menu bounds' );
  is( $restored->{menu}{items}{name}, '~Q~uit', 'restores popup item' );
  is( $restored->{menu}{items}{command}, 42, 'restores popup command' );
  is( $restored->{menu}{items}{param}, 'Alt+Q', 'restores popup parameter' );
  is( $restored->parentMenu, undef, 'clears parent menu' );
  is( $restored->current, undef, 'resets current item' );
}; #/ 'TMenuPopup Storable roundtrip' => sub

subtest 'TStatusLine Storable roundtrip' => sub {
  my $items1 = TStatusItem->new(
    text => 'Help', keyCode => 59, command => 10 );
  my $items2 = TStatusItem->new(
    text => 'Open', keyCode => 15, command => 20,
    next => TStatusItem->new( text => 'Save', keyCode => 31, command => 21 ),
  );
  my $defs = TStatusDef->new(
    min   => 0,
    max   => 9,
    items => $items1,
    next  => TStatusDef->new( min => 10, max => 20, items => $items2 ),
  );
  my $statusLine = TStatusLine->new(
    bounds => TRect->new( ax => 3, ay => 23, bx => 23, by => 24 ),
    defs   => $defs,
  );
  $statusLine->{helpCtx} = 12;

  my $restored = thaw( freeze( $statusLine ) );
  isa_ok( $restored, TStatusLine );
  is_deeply( $restored->{origin}, { x => 3, y => 23 }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 1 }, 'preserves size' );

  my $restoredDefs = $restored->{defs};
  is( $restoredDefs->{min},         0,      'preserves first minimum' );
  is( $restoredDefs->{max},         9,      'preserves first maximum' );
  is( $restoredDefs->{next}{min},   10,     'preserves second minimum' );
  is( $restoredDefs->{next}{max},   20,     'preserves second maximum' );
  is( $restoredDefs->{items}{text}, 'Help', 'preserves first status item' );
  is( 
    $restoredDefs->{next}{items}{text}, 
    'Open',
    'preserves second definition item'
  );
  is(
    $restoredDefs->{next}{items}{next}{text}, 
    'Save',
    'preserves status item chain'
  );

  my $restoredItems = $restored->{items};
  is(
    $restoredItems->{text},
    'Open',
    'selects items for restored help context'
  );
  is(
    $restoredItems->{next}{text},
    'Save',
    'restores active item chain'
  );
}; #/ 'TStatusLine Storable roundtrip' => sub

done_testing();