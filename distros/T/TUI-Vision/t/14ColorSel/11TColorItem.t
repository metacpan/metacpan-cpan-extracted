use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::ColorSel::ColorItem';
}

my ( $item1, $item2, $item3 );

subtest 'Object creation' => sub {
  $item3 = TColorItem->new(
    name  => 'third',
    index => 2,
    next  => undef,
  );
  $item2 = TColorItem->new(
    name  => 'second',
    index => 1,
    next  => $item3,
  );
  $item1 = TColorItem->new(
    name  => 'first',
    index => 0,
    next  => $item2,
  );
  isa_ok( $item1, TColorItem );
  isa_ok( $item2, TColorItem );
  isa_ok( $item3, TColorItem );
};

subtest 'Attribute access' => sub {
  is( $item1->name,  'first',  'item1 name' );
  is( $item2->name,  'second', 'item2 name' );
  is( $item3->name,  'third',  'item3 name' );

  is( $item1->index, 0, 'item1 index' );
  is( $item2->index, 1, 'item2 index' );
  is( $item3->index, 2, 'item3 index' );
};

subtest 'Linking' => sub {
  is( $item1->next, $item2, 'item1->next is item2' );
  is( $item2->next, $item3, 'item2->next is item3' );
  ok( !defined $item3->next, 'item3->next is undef' );
};

subtest 'from()' => sub {
  my $item = new_TColorItem( 'test', 7 );
  isa_ok( $item, TColorItem );
  is( $item->name,  'test', 'name set' );
  is( $item->index, 7,      'index set' );
  ok( !defined $item->next, 'next defaults to undef' );
};

subtest 'operator +' => sub {
  my $a = TColorItem->new( name  => 'a', index => 0 );
  my $b = TColorItem->new( name  => 'b', index => 1 );
  my $c = TColorItem->new( name  => 'c', index => 2 );

  my $list = $a + $b + $c;
  is( $list, $a, 'operator returns head element' );
  is( $a->next, $b, 'a linked to b' );
  is( $b->next, $c, 'b linked to c' );
  ok( !defined $c->next, 'c is last element' );
};

done_testing();
