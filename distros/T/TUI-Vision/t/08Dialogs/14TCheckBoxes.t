use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Dialogs::CheckBoxes';
}

my ( $bounds, $cb );

# Build a TSItem-style linked list: item1 -> item2 -> item3 -> undef
my $item3 = bless { value => 'Third',  next => undef }, 'TSItem';
my $item2 = bless { value => 'Second', next => $item3 }, 'TSItem';
my $item1 = bless { value => 'First',  next => $item2 }, 'TSItem';

# Test case: constructor
subtest 'Object creation' => sub {
  $bounds = TRect->new( ax => 0, ay => 0, bx => 20, by => 3 );

  lives_ok { $cb = new_TCheckBoxes( $bounds, $item1 ) }
  'Constructor executed without errors';

  ok( $cb, 'Object was created' );
  isa_ok( $cb, TCheckBoxes, 'Correct object class' );
};

# Test: initial state
subtest 'Initial state' => sub {
  ok( exists $cb->{value},   'value attribute exists' );
  ok( exists $cb->{strings}, 'strings attribute exists' );

  is( $cb->{value}, 0, 'Initial value mask is zero' );

  my $count = $cb->{strings}->getCount;
  is( $count, 3, 'Checkbox group contains 3 items' );

  # none should be marked initially
  ok( !$cb->mark( 0 ), 'Item 0 not marked initially' );
  ok( !$cb->mark( 1 ), 'Item 1 not marked initially' );
  ok( !$cb->mark( 2 ), 'Item 2 not marked initially' );
}; #/ 'Initial state' => sub

# Test: press() toggles bits
subtest 'press toggles bitmask' => sub {
  lives_ok { $cb->press( 1 ) }
  'press(1) executed without error';

  ok( $cb->mark( 1 ), 'Item 1 is now marked' );

  lives_ok { $cb->press( 1 ) }
  'press(1) again toggles off';

  ok( !$cb->mark( 1 ), 'Item 1 is unmarked again' );
}; #/ 'press toggles bitmask' => sub

# Test: multiple selections
subtest 'multiple selections via press' => sub {
  $cb->{value} = 0;    # clear mask

  $cb->press( 0 );     # toggle item 0 on
  $cb->press( 2 );     # toggle item 2 on

  ok( $cb->mark( 0 ),  'Item 0 marked' );
  ok( !$cb->mark( 1 ), 'Item 1 unmarked' );
  ok( $cb->mark( 2 ),  'Item 2 marked' );

  # mask should now contain bits 0 and 2 => 0b101 = 5
  is( $cb->{value}, 5, 'value mask matches expected bit pattern' );
}; #/ 'multiple selections via press' => sub

# Test: bitmask roundtrip setData/getData
subtest 'setData and getData roundtrip' => sub {
  my @rec_in  = ( 6 );    # 0b110 -> items 1 + 2
  my @rec_out = ();

  lives_ok { $cb->setData( \@rec_in ) }
  'setData([6]) executed';

  is( $cb->{value}, 6, 'value updated from record' );

  ok( !$cb->mark( 0 ), 'Item 0 unmarked' );
  ok( $cb->mark( 1 ),  'Item 1 marked' );
  ok( $cb->mark( 2 ),  'Item 2 marked' );

  lives_ok { $cb->getData( \@rec_out ) }
  'getData executed';

  is( $rec_out[0], 6, 'Roundtrip record matches' );
}; #/ 'setData and getData roundtrip' => sub

done_testing();
