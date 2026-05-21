use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Dialogs::Cluster';
}

my ( $bounds, $cluster );

# Build a TSItem-style linked list with 3 entries
# item1 -> item2 -> item3 -> undef
my $item3 = bless { value => 'Third',  next => undef }, 'TSItem';
my $item2 = bless { value => 'Second', next => $item3 }, 'TSItem';
my $item1 = bless { value => 'First',  next => $item2 }, 'TSItem';

# Test case for the constructor
subtest 'Object creation' => sub {
  $bounds = TRect->new( ax => 0, ay => 0, bx => 20, by => 3 );

  lives_ok { $cluster = new_TCluster( $bounds, $item1 ) }
  'Constructor executed without error';

  ok( $cluster, 'Object created' );
  isa_ok( $cluster, TCluster, 'Created object is correct class' );
};

# Test case for initial state
subtest 'Initial state' => sub {
  ok( exists $cluster->{value},   'Attribute value exists' );
  ok( exists $cluster->{sel},     'Attribute sel exists' );
  ok( exists $cluster->{strings}, 'Attribute strings exists' );

  is( $cluster->dataSize, 1, 'dataSize() returns 1' );
  is( $cluster->{value},  0, 'Initial value should be 0' );
  is( $cluster->{sel},    0, 'Initial sel should be 0' );

  my $count = $cluster->{strings}->getCount;
  is( $count, 3, 'Cluster contains 3 strings from TSItem list' );

  ok( $cluster->buttonState( 0 ), 'buttonState(0) is true initially' );
  ok( $cluster->buttonState( 1 ), 'buttonState(1) is true initially' );
  ok( $cluster->buttonState( 2 ), 'buttonState(2) is true initially' );
  ok(
    $cluster->buttonState( 3 ), 
    'buttonState(3) is true because enableMask defaults to all bits set'
  );
}; #/ 'Initial state' => sub

# Test case for setButtonState behavior
subtest 'setButtonState enables and disables items' => sub {
  my $mask_item1 = 1 << 1;    # bit for item index 1

  lives_ok { $cluster->setButtonState( $mask_item1, 0 ) }
  'setButtonState(mask for item 1, 0) executed without error';

  ok( $cluster->buttonState( 0 ),  'Item 0 remains enabled' );
  ok( !$cluster->buttonState( 1 ), 'Item 1 is disabled by mask' );
  ok( $cluster->buttonState( 2 ),  'Item 2 remains enabled' );

  lives_ok { $cluster->setButtonState( $mask_item1, 1 ) }
  'setButtonState(mask for item 1, 1) executed without error';

  ok( $cluster->buttonState( 1 ), 'Item 1 is enabled again' );
}; #/ 'setButtonState enables and disables items' => sub

# Test case for setData/getData integration
subtest 'setData and getData roundtrip' => sub {
  my @rec_in  = ( 2 );
  my @rec_out = ();

  lives_ok { $cluster->setData( \@rec_in ) }
  'setData([2]) executed without error';

  is( $cluster->{value}, 2, 'value is set to 2 via setData' );

  lives_ok { $cluster->getData( \@rec_out ) }
  'getData executed without error';

  is( $rec_out[0], 2, 'getData returns the same value that was set' );
}; #/ 'setData and getData roundtrip' => sub

done_testing();
