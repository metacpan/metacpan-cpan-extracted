use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Dialogs::StrItem';
}

my ( $item1, $item2, $item3 );

subtest 'Object creation' => sub {
  $item3 = TSItem->new( value => 'third',  next => undef );
  $item2 = TSItem->new( value => 'second', next => $item3 );
  $item1 = TSItem->new( value => 'first',  next => $item2 );

  isa_ok( $item1, TSItem, 'item1 is a TSItem' );
  isa_ok( $item2, TSItem, 'item2 is a TSItem' );
  isa_ok( $item3, TSItem, 'item3 is a TSItem' );
};

subtest 'Value access' => sub {
  is( $item1->value, 'first',  'item1 has correct value' );
  is( $item2->value, 'second', 'item2 has correct value' );
  is( $item3->value, 'third',  'item3 has correct value' );
};

subtest 'Linking' => sub {
  is( $item1->next, $item2, 'item1->next is item2' );
  is( $item2->next, $item3, 'item2->next is item3' );
  ok( !defined $item3->next, 'item3->next is undef (end of list)' );
};

done_testing();
