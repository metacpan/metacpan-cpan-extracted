use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Drivers::Event';
}
INIT {
  use_ok 'CharScanType';
}

# Test the creation of a new CharScanType object
subtest 'new object creation' => sub {
  plan tests => 3;
  my $obj = CharScanType->new( charCode => 0x12, scanCode => 0x34 );
  isa_ok( $obj, 'CharScanType' );
  is( $obj->{charCode}, 0x12, 'charCode is set correctly' );
  is( $obj->{scanCode}, 0x34, 'scanCode is set correctly' );
};

# Test the STORE and FETCH methods
subtest 'store and fetch methods' => sub {
  plan tests => 2;
  my $obj = CharScanType->new();
  $obj->{charCode} = 0x56;
  $obj->{scanCode} = 0x78;
  is( $obj->{charCode}, 0x56, 'charCode is stored and fetched correctly' );
  is( $obj->{scanCode}, 0x78, 'scanCode is stored and fetched correctly' );
};

# Test the EXISTS method
subtest 'exists method' => sub {
  plan tests => 3;
  my $obj = CharScanType->new( charCode => 0x12, scanCode => 0x34 );
  ok( exists $obj->{charCode},     'charCode exists' );
  ok( exists $obj->{scanCode},     'scanCode exists' );
  ok( !exists $obj->{nonexistent}, 'nonexistent field does not exist' );
};

# Test the SCALAR method
subtest 'scalar method' => sub {
  plan tests => 1;
  my $obj = CharScanType->new();
  is( scalar %$obj, 2, 'scalar works correctly' );
};

# Test the exception handling
subtest 'exception handling' => sub {
  plan tests => 3;
  my $obj = CharScanType->new();
  throws_ok { delete $obj->{charCode} } qr/restricted/,
    'Exception, when deleting a read-only entry';
  throws_ok { %$obj = () } qr/restricted/,
    'Exception, when clearing a read-only hash';
  throws_ok { $obj->{invalidField} = 0x99 } qr/restricted/,
    'Exception thrown for invalid field';
};

done_testing();
