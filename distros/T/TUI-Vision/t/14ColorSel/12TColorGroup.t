use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::ColorSel::ColorItem';
  use_ok 'TUI::ColorSel::ColorGroup';
}

my ( $group1, $group2, $group3 );
my ( $item1, $item2, $item3 );

subtest 'Object creation' => sub {
  $group3 = TColorGroup->new( name => 'Group 3' );
  $group2 = TColorGroup->new( name => 'Group 2', next => $group3 );
  $group1 = TColorGroup->new( name => 'Group 1', next => $group2 );

  isa_ok( $group1, TColorGroup );
  isa_ok( $group2, TColorGroup );
  isa_ok( $group3, TColorGroup );

  my $group = new_TColorGroup( 'Colors' );
  isa_ok( $group, TColorGroup );
  is( $group->name, 'Colors', 'name initialized' );
  ok( !defined $group->items, 'items defaults to undef' );
  ok( !defined $group->next,  'next defaults to undef' );
};

subtest 'Attribute access' => sub {
  is( $group1->name, 'Group 1', 'group1 name' );
  is( $group2->name, 'Group 2', 'group2 name' );
  is( $group3->name, 'Group 3', 'group3 name' );
};

subtest 'Group linking' => sub {
  is( $group1->next, $group2, 'group1->next is group2' );
  is( $group2->next, $group3, 'group2->next is group3' );
  ok( !defined $group3->next, 'group3->next is undef'  );
};

subtest 'ColorItem creation' => sub {
  $item3 = TColorItem->new( name  => 'Item 3', index => 2 );
  $item2 = TColorItem->new( name  => 'Item 2', index => 1 );
  $item1 = TColorItem->new( name  => 'Item 1', index => 0 );

  isa_ok( $item1, TColorItem );
  isa_ok( $item2, TColorItem );
  isa_ok( $item3, TColorItem );
};

subtest 'operator + appends items' => sub {
  my $group = TColorGroup->new( name => 'Items' );

  my $list = $group + $item1 + $item2 + $item3;
  is( $list, $group, 'returns group head' );

  is( $group->items, $item1, 'first item attached' );
  is( $item1->next, $item2,  'second item linked' );
  is( $item2->next, $item3,  'third item linked' );
  ok( !defined $item3->next, 'last item terminates chain' );
};

subtest 'operator + appends groups' => sub {
  my $g1 = TColorGroup->new( name => 'Group A' );
  my $g2 = TColorGroup->new( name => 'Group B' );
  my $g3 = TColorGroup->new( name => 'Group C' );

  my $list = $g1 + $g2 + $g3;
  is( $list, $g1, 'returns group head' );

  is( $g1->next, $g2, 'g2 appended' );
  is( $g2->next, $g3, 'g3 appended' );
  ok( !defined $g3->next, 'g3 is last group' );
};

subtest 'operator + preserves existing item chain' => sub {
  my $group = TColorGroup->new( name => 'Append' );
  my $i1 = TColorItem->new( name  => 'A', index => 0 );
  my $i2 = TColorItem->new( name  => 'B', index => 1 );
  my $i3 = TColorItem->new( name  => 'C', index => 2 );

  $group += $i1;
  $group += $i2;
  $group += $i3;

  is( $group->items, $i1, 'head unchanged' );
  is( $i1->next, $i2, 'second appended' );
  is( $i2->next, $i3, 'third appended' );
};

done_testing();
