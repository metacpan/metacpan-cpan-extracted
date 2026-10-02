use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Drivers::ColorAttr';
  use_ok 'TUI::Drivers::AttrPair';
}

subtest 'default constructor' => sub {
  my $attrs = TAttrPair->new();
  isa_ok( $attrs, TAttrPair );

  isa_ok( $attrs->[0], TColorAttr, 'lo attribute' );
  isa_ok( $attrs->[1], TColorAttr, 'hi attribute' );
  ok( !$attrs->[0]->isBIOS, 'default lo is not BIOS compatible' );
  ok( !$attrs->[1]->isBIOS, 'default hi is not BIOS compatible' );
};

subtest 'bios constructor' => sub {
  my $attrs = TAttrPair->new( bios => 0x1e3d );
  isa_ok( $attrs, TAttrPair );

  is( $attrs->[0]->asBIOS, 0x3d, 'lo extracted' );
  is( $attrs->[1]->asBIOS, 0x1e, 'hi extracted' );
  is( $attrs->asBIOS, 0x1e3d, 'roundtrip BIOS value' );
};

subtest 'explicit lo/hi constructor' => sub {
  my $lo = TColorAttr->new( bios => 0x1f );
  my $hi = TColorAttr->new( bios => 0x70 );
  my $attrs = TAttrPair->new( lo => $lo, hi => $hi );
  isa_ok( $attrs, TAttrPair );

  ok( $attrs->[0] == $lo, 'lo stored' );
  ok( $attrs->[1] == $hi, 'hi stored' );
};

subtest 'default hi attribute' => sub {
  my $lo = TColorAttr->new( bios => 0x1f );
  my $attrs = TAttrPair->new( lo => $lo );
  isa_ok( $attrs, TAttrPair );

  is( $attrs->[1]->asBIOS, 0, 'hi defaults to zero' );
};

subtest 'array element access' => sub {
  my $attrs = TAttrPair->new();
  my $hi = TColorAttr->new( bios => 0x70 );
  $attrs->[1] = $hi;

  ok( $attrs->[1] == $hi, 'hi replaced directly' );
};

subtest 'numeric overload' => sub {
  my $attrs = TAttrPair->new( bios => 0x1e3d );
  is( 0+ $attrs, 0x1e3d, 'numeric conversion' );
};

subtest 'rshift' => sub {
  my $hi = TColorAttr->new( bios => 0x70 );
  my $attrs = TAttrPair->new( 
    lo => TColorAttr->new( bios => 0x1f ), 
    hi => $hi,
  );

  my $result = $attrs >> 8;
  isa_ok( $result, TAttrPair );
  ok( $result->[0] == $hi, 'shift by 8 extracts hi as new lo' );

  is( $attrs >> 4, $attrs->asBIOS >> 4, 'shift by other amounts is numeric' );
};

subtest 'setLo via |=' => sub {
  my $attrs = TAttrPair->new();
  my $lo = TColorAttr->new( bios => 0x1f );
  $attrs |= $lo;

  ok( $attrs->[0] == $lo, 'lo set' );
};

done_testing;
