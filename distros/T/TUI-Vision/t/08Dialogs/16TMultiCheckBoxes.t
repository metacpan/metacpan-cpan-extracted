use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Dialogs::MultiCheckBoxes';
}

my ( $bounds, $mcb );

# Build a TSItem-style list: item1 -> item2 -> item3 -> undef
my $item3 = bless { value => 'Third',  next => undef }, 'TSItem';
my $item2 = bless { value => 'Second', next => $item3 }, 'TSItem';
my $item1 = bless { value => 'First',  next => $item2 }, 'TSItem';

# Test: constructor
subtest 'Object creation' => sub {
  $bounds = TRect->new( ax => 0, ay => 0, bx => 30, by => 5 );

  lives_ok {
    $mcb = new_TMultiCheckBoxes(
      $bounds,
      $item1,
      3,         # selRange
      0x0203,    # flags  -> low byte mask=0x03, high byte shift=0x02
      "-+="      # states -> 3-state cycle
    );
  } 'Constructor executed without error';

  isa_ok( $mcb, TMultiCheckBoxes, 'Object is correct class' );
}; #/ 'Object creation' => sub

# Test: initial state
subtest 'Initial state' => sub {
  ok( exists $mcb->{value},    'value attribute exists' );
  ok( exists $mcb->{selRange}, 'selRange attribute exists' );
  ok( exists $mcb->{flags},    'flags attribute exists' );
  ok( exists $mcb->{strings},  'strings attribute exists' );

  is( $mcb->{value}, 0, 'Initial value bitfield is zero' );

  is( $mcb->{strings}->getCount, 3, 'Three strings loaded from TSItem chain' );

  # all states should be zero initially
  is( $mcb->multiMark( 0 ), 0, 'Item 0 initial state is 0' );
  is( $mcb->multiMark( 1 ), 0, 'Item 1 initial state is 0' );
  is( $mcb->multiMark( 2 ), 0, 'Item 2 initial state is 0' );
}; #/ 'Initial state' => sub

# Test: press() cycles states correctly
subtest 'press cycles through states' => sub {

  # selRange = 3 -> states: 0 -> 2 -> 1 -> 0 -> ...
  # because curState-- and wrap logic in module

  lives_ok { $mcb->press( 0 ) } 'press(0) ok';
  is( $mcb->multiMark( 0 ), 2, 'Item 0 state cycles to 2' );

  lives_ok { $mcb->press( 0 ) } 'press(0) again ok';
  is( $mcb->multiMark( 0 ), 1, 'Item 0 state cycles to 1' );

  lives_ok { $mcb->press( 0 ) } 'press(0) a third time ok';
  is( $mcb->multiMark( 0 ), 0, 'Item 0 wraps back to 0' );
}; #/ 'press cycles through states' => sub

# Test: independent state changes
subtest 'multiple items maintain independent state' => sub {
  $mcb->{value} = 0;    # reset

  $mcb->press( 0 );     # -> 2
  $mcb->press( 1 );     # -> 2
  $mcb->press( 2 );     # -> 2

  is( $mcb->multiMark( 0 ), 2, 'Item 0 = state 2' );
  is( $mcb->multiMark( 1 ), 2, 'Item 1 = state 2' );
  is( $mcb->multiMark( 2 ), 2, 'Item 2 = state 2' );

  # Change item 1 further
  $mcb->press( 1 );     # -> 1
  is( $mcb->multiMark( 1 ), 1, 'Item 1 changed independently to state 1' );
}; #/ 'multiple items maintain independent state' => sub

# Test: setData/getData roundtrip
subtest 'setData and getData roundtrip' => sub {
  my @in  = ( 0x0005 );    # example bitfield
  my @out = ();

  lives_ok { $mcb->setData( \@in ) }
  'setData executed';

  is( $mcb->{value}, 0x0005, 'value updated from record' );

  lives_ok { $mcb->getData( \@out ) }
  'getData executed';

  is( $out[0], 0x0005, 'Roundtrip value matches' );
}; #/ 'setData and getData roundtrip' => sub

done_testing();
