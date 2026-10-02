use strict;
use warnings;

use Test::More;
use Scalar::Util qw( refaddr );

BEGIN {
  use_ok 'TUI::Drivers::ColorAttr';
  use_ok 'TUI::Drivers::ScreenCell';
  use_ok 'TUI::Drivers::ScreenCharacter';
}

subtest 'default constructor' => sub {
  my $cell = TScreenCell->new();
  isa_ok( $cell, TScreenCell );

  isa_ok( $cell->attribute(), TColorAttr );
  isa_ok( $cell->character(), TScreenCharacter );
};

subtest 'bios constructor' => sub {
  my $cell = TScreenCell->new( bios => ( 0x1f << 8 ) | ord('A') );
  isa_ok( $cell, TScreenCell );

  isa_ok( $cell->attribute(), TColorAttr );
  isa_ok( $cell->character(), TScreenCharacter );

  ok( $cell->attribute->isBIOS, 'BIOS attribute preserved' );
  is( $cell->attribute->asBIOS, 0x1f, 'roundtrip BIOS attribute' );
};

subtest 'cell constructor' => sub {
  my $attr = TColorAttr->new( bios => 0x1f );
  my $cell = TScreenCell->new(
    ch   => 'A',
    attr => $attr,
  );

  is( $cell->character->getText, 'A', 'character stored');
  ok(
    refaddr( $cell->attribute() ) != refaddr( $attr ), 
    'attribute copied by value'
  );
  is( $cell->attribute->asBIOS, $attr->asBIOS, 'attribute value stored' );
};

subtest 'character with string' => sub {
  my $cell = TScreenCell->new();

  $cell->character( 'A' );
  isa_ok( $cell->character(), TScreenCharacter );
  is( $cell->character->getText, 'A', 'character stored' );
};

subtest 'character with TScreenCharacter' => sub {
  my $char = TScreenCharacter->new(
    text => "\x{754C}",    # 界
  );
  my $cell = TScreenCell->new();
  $cell->character( $char );

  ok(
    refaddr( $cell->character() ) != refaddr( $char ),
    'character copied by value'
  );
  is( $cell->character->getText, $char->getText, 'character value preserved' );
  ok( $cell->character->isWide, 'wide character detected' );
};

subtest 'attribute' => sub {
  my $attr = TColorAttr->new( bios => 0x1f );
  my $cell = TScreenCell->new();

  $cell->attribute( $attr );
  ok(
    refaddr( $cell->attribute() ) != refaddr( $attr ),
    'attribute copied by value'
  );
  is( $cell->attribute->asBIOS, $attr->asBIOS, 'attribute value preserved' );

  $cell->attribute(0x2E);
  is( $cell->attribute->asBIOS, 0x2E, 'numeric BIOS attribute preserved' );
};

subtest 'equals' => sub {
  my $a = TScreenCell->new( bios => 0x1f );
  my $b = TScreenCell->new( bios => 0x1f );

  ok( $a == $b, 'equal cells compare equal' );

  $b->character( 'A' );
  ok( !( $a == $b ), 'modified cell differs' );
};

subtest 'wide character trail' => sub {
  my $cell = TScreenCell->new();
  $cell->character( TScreenCharacter->new( text => "\0" ) );

  ok( $cell->character->isWideCharTrail, 'trail placeholder detected' );
};

done_testing();
