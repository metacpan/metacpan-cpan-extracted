use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Menus::StatusItem';
}

# Test object creation as list
my $status_item1 = new_TStatusItem( 'One', 0x1234, 1 );
isa_ok( $status_item1, TStatusItem, 'Object is of class TStatusItem' );

# Test object creation als hash with 'next'
my $status_item2 = TStatusItem->new( 
  text => 'Two', command => 2, keyCode => 0x5678, next => undef
);
isa_ok( $status_item2, TStatusItem, 'Object is of class TStatusItem' );

# Test DEMOLISH method
can_ok( $status_item1, 'DEMOLISH' );
lives_ok { $status_item1->DEMOLISH(0) }
  'DEMOLISH works correctly';

done_testing();
