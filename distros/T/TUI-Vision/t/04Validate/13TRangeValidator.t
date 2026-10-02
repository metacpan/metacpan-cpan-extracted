use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Validate::Const', qw(
    voTransfer vtGetData vtSetData
  );
  use_ok 'TUI::Validate::RangeValidator';
}

my ( $vPos, $vNeg );

subtest 'Object creation' => sub {
  lives_ok {
    $vPos = TUI::Validate::RangeValidator->new( min => 1, max => 10 );
  } 'Object created (positive range)';
  isa_ok( $vPos, TRangeValidator );

  lives_ok {
    $vNeg = new_TRangeValidator( -10, 10 );
  } 'Object created (range includes negative)';
  isa_ok( $vNeg, TRangeValidator );
};

subtest 'isValid' => sub {

  # Inside range
  ok( $vPos->isValid( '1' ),  'Lower bound accepted' );
  ok( $vPos->isValid( '10' ), 'Upper bound accepted' );
  ok( $vPos->isValid( '5' ),  'Middle value accepted' );

  # Outside range
  ok( !$vPos->isValid( '0' ),  'Below min rejected' );
  ok( !$vPos->isValid( '11' ), 'Above max rejected' );

  # Negative handling
  ok( $vNeg->isValid( '-10' ),  'Negative lower bound accepted' );
  ok( $vNeg->isValid( '10' ),   'Positive upper bound accepted' );
  ok( !$vNeg->isValid( '-11' ), 'Below negative min rejected' );

  # Invalid characters (should be rejected by parent validator)
  ok( !$vPos->isValid( '3x' ),  'Non-numeric rejected' );
  ok( !$vNeg->isValid( '--1' ), 'Invalid sign pattern rejected' );
}; #/ 'isValid' => sub

subtest 'transfer (options off)' => sub {
  my $s   = '5';
  my $buf = 0;

  # Ensure options are off
  $vPos->{options} = 0;

  is( $vPos->transfer( $s, $buf, vtGetData ), 0,
    'transfer returns 0 when voTransfer not enabled' );
  is( $buf, 0,   'buffer unchanged when transfer disabled' );
  is( $s,   '5', 'string unchanged when transfer disabled' );
};

subtest 'transfer (vtGetData / vtSetData)' => sub {

  # Enable transfer behavior
  $vPos->{options} = voTransfer;

  my $s1   = '7';
  my $buf1 = 0;
  is( $vPos->transfer( $s1, $buf1, vtGetData ), 1, 'vtGetData returns 1' );
  is( $buf1, 7,   'vtGetData writes int($s) into buffer' );
  is( $s1,   '7', 'vtGetData does not modify input string' );

  my $s2   = '0';
  my $buf2 = 42;
  is( $vPos->transfer( $s2, $buf2, vtSetData ), 1, 'vtSetData returns 1' );
  is( $s2,   '42', 'vtSetData writes formatted buffer into string' );
  is( $buf2, 42,   'vtSetData does not modify buffer' );
};

done_testing();
