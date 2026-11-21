use strict;
use warnings;

use Test::More;
use Storable qw( freeze thaw );

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::ColorSel::Const', qw( csBackground csForeground );
  use_ok 'TUI::ColorSel::ColorSelector';
  use_ok 'TUI::ColorSel::MonoSelector';
  use_ok 'TUI::ColorSel::ColorDisplay';
  use_ok 'TUI::ColorSel::ColorGroupList';
  use_ok 'TUI::ColorSel::ColorItemList';
  use_ok 'TUI::ColorSel::ColorGroup';
  use_ok 'TUI::ColorSel::ColorItem';
  use_ok 'TUI::ColorSel::ColorDialog';
  use_ok 'TUI::Views::Palette';
}

subtest 'TColorSelector foreground Storable roundtrip' => sub {
  my $selector = TColorSelector->new(
    bounds  => TRect->new( ax => 3, ay => 4, bx => 15, by => 8 ),
    selType => csForeground,
  );
  $selector->{color} = 12;

  my $restored = thaw( freeze( $selector ) );
  isa_ok( $restored, TColorSelector );
  is_deeply( $restored->{origin}, { x => 3, y => 4 }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 12, y => 4 }, 'preserves size' );
  is( $restored->{color}, 12, 'preserves color' );
  is( $restored->{selType}, csForeground, 'preserves foreground mode' );
}; #/ 'TColorSelector foreground Storable roundtrip' => sub

subtest 'TColorSelector background Storable roundtrip' => sub {
  my $selector = TColorSelector->new(
    bounds  => TRect->new( ax => 1, ay => 2, bx => 13, by => 6 ),
    selType => csBackground,
  );
  $selector->{color} = 7;

  my $restored = thaw( freeze( $selector ) );
  isa_ok( $restored, TColorSelector );
  is( $restored->{color}, 7, 'preserves background color' );
  is( $restored->{selType}, csBackground, 'preserves background mode' );
}; #/ 'TColorSelector background Storable roundtrip' => sub

subtest 'TMonoSelector Storable roundtrip' => sub {
  my $selector = TMonoSelector->new(
    bounds => TRect->new( ax => 3, ay => 4, bx => 15, by => 9 ),
  );
  $selector->{value} = 0x70;
  $selector->{sel}   = 3;

  my $restored = thaw( freeze( $selector ) );
  isa_ok( $restored, TMonoSelector );
  is_deeply( $restored->{origin}, { x => 3, y => 4 }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 12, y => 5 }, 'preserves size' );
  is( $restored->{value}, 0x70, 'preserves inherited value' );
  is( $restored->{sel}, 3, 'preserves inherited selection' );
  is( $restored->{strings}->getCount(), 4, 'restores monochrome options' );
  ok( $restored->mark( 3 ), 'restores selected monochrome option' );
}; #/ 'TMonoSelector Storable roundtrip' => sub

subtest 'TColorDisplay Storable roundtrip' => sub {
  my $display = TColorDisplay->new(
    bounds => TRect->new( ax => 3, ay => 4, bx => 23, by => 5 ),
    text   => 'Preview ',
  );
  my $color = 0x4f;
  $display->{color} = \$color;

  my $restored = thaw( freeze( $display ) );
  isa_ok( $restored, TColorDisplay );
  is_deeply( $restored->{origin}, { x => 3, y => 4 }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 1 }, 'preserves size' );
  is( $restored->{text}, 'Preview ', 'preserves preview text' );
  is( ref( $restored->{color} ), 'SCALAR', 'resets color to a scalar reference' );
  is( ${ $restored->{color} }, 0, 'resets referenced color to zero' );
}; #/ 'TColorDisplay Storable roundtrip' => sub

subtest 'TColorGroupList Storable roundtrip' => sub {
  my $group2 = TColorGroup->new(
    name  => 'Secondary',
    items => TColorItem->new( name => 'Gray', index => 8 ),
  );
  my $group1 = TColorGroup->new(
    name  => 'Primary',
    items => TColorItem->new(
      name  => 'Red',
      index => 4,
      next  => TColorItem->new( name => 'Green', index => 2 ),
    ),
    next => $group2,
  );
  my $groupList = TColorGroupList->new(
    bounds   => TRect->new( ax => 3, ay => 4, bx => 23, by => 9 ),
    scrollBar => undef,
    groups   => $group1,
  );

  my $restored = thaw( freeze( $groupList ) );
  isa_ok( $restored, TColorGroupList );
  is_deeply( $restored->{origin}, { x => 3, y => 4 }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 5 }, 'preserves size' );
  is( $restored->{range}, 2, 'preserves group range' );
  is( $restored->getNumGroups(), 2, 'restores group count' );
  my $restoredGroup = $restored->getGroup( 0 );
  is( $restoredGroup->{name}, 'Primary', 'restores first group' );
  is( $restoredGroup->{items}{name}, 'Red', 'restores first color item' );
  is( $restoredGroup->{items}{index}, 4, 'restores first color index' );
  is( $restoredGroup->{items}{next}{name}, 'Green',
    'restores color item chain' );
  is( $restored->getGroup( 1 )->{name}, 'Secondary', 'restores second group' );
  is( $restored->getGroup( 1 )->{items}{index}, 8,
    'restores second group color index' );
}; #/ 'TColorGroupList Storable roundtrip' => sub

subtest 'TColorItemList Storable roundtrip' => sub {
  my $itemList = TColorItemList->new(
    bounds    => TRect->new( ax => 3, ay => 4, bx => 23, by => 9 ),
    scrollBar => undef,
    items     => undef,
  );

  my $restored = thaw( freeze( $itemList ) );
  isa_ok( $restored, TColorItemList );
  is_deeply( $restored->{origin}, { x => 3, y => 4 }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 5 }, 'preserves size' );
  is( $restored->{numCols}, 1, 'build preserves one column' );
  is( $restored->{range}, 0, 'preserves empty item range' );
  is( $restored->{items}, undef, 'restores an empty item list' );
}; #/ 'TColorItemList Storable roundtrip' => sub

subtest 'TColorDialog Storable roundtrip' => sub {
  my $groups = TColorGroup->new(
    name  => 'Preview',
    items => TColorItem->new( name => 'Sample', index => 0 ),
  );
  my $dialog = TColorDialog->new( pal => undef, groups => $groups );
  $dialog->{pal} = TPalette->new( data => "\x07", size => 1 );

  my $restored = thaw( freeze( $dialog ) );
  isa_ok( $restored, TColorDialog );
  ok( !defined $restored->{pal}, 'resets palette pointer after reading' );
  isa_ok( $restored->{groups}, TColorGroupList );
  is( $restored->{groups}->getNumGroups(), 1, 'restores color groups' );
  is( $restored->{groups}->getGroup( 0 )->{name}, 'Preview',
    'restores group name' );
  isa_ok( $restored->{display}, TColorDisplay );
  isa_ok( $restored->{forSel}, TColorSelector );
  isa_ok( $restored->{bakSel}, TColorSelector );
  isa_ok( $restored->{monoSel}, TMonoSelector );
}; #/ 'TColorDialog Storable roundtrip' => sub

done_testing();