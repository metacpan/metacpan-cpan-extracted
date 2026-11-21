use strict;
use warnings;

use Test::More;
use Storable qw( freeze thaw );

BEGIN {
  use_ok 'TUI::Validate::Validator';
  use_ok 'TUI::Validate::PXPictureValidator';
  use_ok 'TUI::Validate::FilterValidator';
  use_ok 'TUI::Validate::RangeValidator';
  use_ok 'TUI::Objects::StringCollection';
  use_ok 'TUI::Validate::StringLookupValidator';
}

subtest 'TValidator Storable roundtrip' => sub {
  my $validator = TValidator->new();
  $validator->{status}  = 12;
  $validator->{options} = 9;

  my $restored = thaw( freeze( $validator ) );
  isa_ok( $restored, TValidator );
  is( $restored->{options}, 9, 'preserves options' );
  is( $restored->{status},  0, 'resets status' );
  is( $validator->{status}, 12, 'does not change original status' );
}; #/ 'TValidator Storable roundtrip' => sub

subtest 'TPXPictureValidator Storable roundtrip' => sub {
  my $validator = TPXPictureValidator->new(
    pic      => '##-??',
    autoFill => 0,
  );
  $validator->{status}  = 12;
  $validator->{options} = 9;
  $validator->{index}   = 3;
  $validator->{jndex}   = 2;

  my $restored = thaw( freeze( $validator ) );
  isa_ok( $restored, TPXPictureValidator );
  is( $restored->{pic},     '##-??', 'preserves picture' );
  is( $restored->{options}, 9,       'preserves options' );
  is( $restored->{status},  0,       'resets status' );
  is( $restored->{index},   0,       'resets parser index' );
  is( $restored->{jndex},   0,       'resets input index' );
  ok( $restored->isValid( '12-ab' ), 'restored picture validates input' );
}; #/ 'TPXPictureValidator Storable roundtrip' => sub

subtest 'TFilterValidator Storable roundtrip' => sub {
  my $validator = TFilterValidator->new( validChars => 'A-Za-z0-9' );
  $validator->{status}  = 12;
  $validator->{options} = 9;

  my $restored = thaw( freeze( $validator ) );
  isa_ok( $restored, TFilterValidator );
  is( $restored->{validChars}, 'A-Za-z0-9', 'preserves valid chars' );
  is( $restored->{options}, 9, 'preserves options' );
  is( $restored->{status},  0, 'resets status' );
  ok( $restored->isValid( 'Ab12' ), 'accepts chars in restored filter' );
  ok( !$restored->isValid( 'Ab!2' ), 'rejects chars outside restored filter' );
}; #/ 'TFilterValidator Storable roundtrip' => sub

subtest 'TRangeValidator Storable roundtrip' => sub {
  my $validator = TRangeValidator->new( min => -10, max => 10 );
  $validator->{status}  = 12;
  $validator->{options} = 9;

  my $restored = thaw( freeze( $validator ) );
  isa_ok( $restored, TRangeValidator );
  is( $restored->{min},        -10,             'preserves minimum' );
  is( $restored->{max},        10,              'preserves maximum' );
  is( $restored->{validChars}, '+-0123456789',  'preserves valid characters' );
  is( $restored->{options},    9,               'preserves options' );
  is( $restored->{status},     0,               'resets status' );
  ok( $restored->isValid( '-10' ), 'accepts lower boundary' );
  ok( $restored->isValid( '10' ),  'accepts upper boundary' );
  ok( !$restored->isValid( '11' ), 'rejects values above range' );
}; #/ 'TRangeValidator Storable roundtrip' => sub

subtest 'TStringLookupValidator Storable roundtrip' => sub {
  my $strings = TStringCollection->new( limit => 3, delta => 0 );
  $strings->insert( $_ ) for qw( foo bar baz );
  my $validator = TStringLookupValidator->new( strings => $strings );
  $validator->{status}  = 12;
  $validator->{options} = 9;

  my $restored = thaw( freeze( $validator ) );
  isa_ok( $restored, TStringLookupValidator );
  isa_ok( $restored->{strings}, TStringCollection );
  is( $restored->{options}, 9, 'preserves options' );
  is( $restored->{status},  0, 'resets status' );
  ok( $restored->lookup( 'bar' ), 'finds a restored string' );
  ok( !$restored->lookup( 'qux' ), 'rejects a string not in the restored list' );
}; #/ 'TStringLookupValidator Storable roundtrip' => sub

done_testing();
