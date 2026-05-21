use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Dialogs::RadioButtons';
}

my ( $bounds, $rb );

# Build a TSItem-style linked list with 3 entries
# item1 -> item2 -> item3 -> undef
my $item3 = bless { value => 'Third',  next => undef }, 'TSItem';
my $item2 = bless { value => 'Second', next => $item3 }, 'TSItem';
my $item1 = bless { value => 'First',  next => $item2 }, 'TSItem';

# Test case for the constructor
subtest 'Object creation' => sub {
  $bounds = TRect->new( ax => 0, ay => 0, bx => 20, by => 3 );
  lives_ok { $rb = new_TRadioButtons( $bounds, $item1 ) }
    'Constructor executed without error';
  ok( $rb, 'Object created' );
  isa_ok( $rb, TRadioButtons, 'Created object is correct class' );
};

# Test case for initial state
subtest 'Initial state' => sub {
  ok( exists $rb->{value}, 'Attribute value exists' );
  ok( exists $rb->{sel},   'Attribute sel exists' );
  is( $rb->{value}, 0, 'Initial value should be 0' );
  is( $rb->{sel},   0, 'Initial sel should be 0' );

  ok( $rb->mark( 0 ),  'Item 0 is marked initially' );
  ok( !$rb->mark( 1 ), 'Item 1 is not marked initially' );
  ok( !$rb->mark( 2 ), 'Item 2 is not marked initially' );
}; #/ 'Initial state' => sub

# Test case for press() behavior
subtest 'press selects item and updates value' => sub {
  lives_ok { $rb->press( 1 ) }
  'press(1) executed without error';

  is( $rb->{value}, 1, 'value is updated to pressed index' );
  ok( !$rb->mark( 0 ), 'Item 0 is not marked after press(1)' );
  ok( $rb->mark( 1 ),  'Item 1 is marked after press(1)' );
  ok( !$rb->mark( 2 ), 'Item 2 is not marked after press(1)' );
};

# Test case for movedTo() behavior
subtest 'movedTo updates value on selection change' => sub {
  lives_ok { $rb->movedTo( 2 ) }
  'movedTo(2) executed without error';

  is( $rb->{value}, 2, 'value is updated to moved-to index' );
  ok( !$rb->mark( 0 ), 'Item 0 is not marked after movedTo(2)' );
  ok( !$rb->mark( 1 ), 'Item 1 is not marked after movedTo(2)' );
  ok( $rb->mark( 2 ),  'Item 2 is marked after movedTo(2)' );
};

# Test case for setData() integration with TCluster
subtest 'setData synchronizes value and selection' => sub {
  my @rec = ( 1 );

  lives_ok { $rb->setData( \@rec ) }
  'setData executed without error';

  is( $rb->{value}, 1, 'value is set from record' );
  is( $rb->{sel},   1, 'sel is synchronized with value after setData' );
  ok( !$rb->mark( 0 ), 'Item 0 is not marked after setData([1])' );
  ok( $rb->mark( 1 ),  'Item 1 is marked after setData([1])' );
  ok( !$rb->mark( 2 ), 'Item 2 is not marked after setData([1])' );
}; #/ 'setData synchronizes value and selection' => sub

done_testing();
