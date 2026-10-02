use strict;
use warnings;
use utf8;

use Test::More;

BEGIN {
  use_ok 'TUI::Drivers::ScreenCharacter';
}

subtest 'default constructor' => sub {
  my $ch = TScreenCharacter->new();
  isa_ok( $ch, TScreenCharacter );

  is( length( $$ch ), 0, 'length of default text is zero' );
  is( $ch->getText, "\0", 'default text' );

  ok( !$ch->isWide, 'default cell is not wide' );
};

subtest 'text constructor' => sub {
  my $ch = TScreenCharacter->new( text => 'A' );
  isa_ok( $ch, TScreenCharacter );

  is( $ch->getText, 'A', 'stored text' );
  ok( !$ch->isWide, 'ASCII character is not wide' );
  ok( !$ch->isWideCharTrail, 'ASCII character is not a trail' );
};

subtest 'wide char trail' => sub {
  my $trail = TScreenCharacter->new( text => "\0" );
  isa_ok( $trail, TScreenCharacter );

  ok( $trail->isWideCharTrail, 'trail placeholder detected');
};

subtest 'invalid constructor' => sub {
  ok(
    !defined( TScreenCharacter->new( txt => 'A' ) ),
    'unknown constructor argument'
  );
};

subtest 'byte length semantics' => sub {
  my $ascii = TScreenCharacter->new( text => 'A' );
  isa_ok( $ascii, TScreenCharacter );

  my $nul = TScreenCharacter->new( text => "\0" );
  isa_ok( $nul, TScreenCharacter );
};

subtest 'wide character detection' => sub {
  my $ascii = TScreenCharacter->new( text => 'A' );
  isa_ok( $ascii, TScreenCharacter );
  ok( !$ascii->isWide, 'ASCII character is not wide' );

  my $wide = TScreenCharacter->new(
    text => "\x{754C}",    # 界
  );
  isa_ok( $wide, TScreenCharacter );
  ok( $wide->isWide, 'wide character detected' );
  ok( !$wide->isWideCharTrail, 'wide character is not a trail' );

  my $egc = TScreenCharacter->new( text => "e\x{301}" );
  isa_ok( $egc, TScreenCharacter );
  ok( !$egc->isWide, 'EGC occupies one screen column' );

  my $emoji = TScreenCharacter->new(
    text => "\x{1F600}",    # 😀
  );
  isa_ok( $emoji, TScreenCharacter );
  ok( $emoji->isWide, 'emoji is wide' );
};

subtest 'appendZeroWidthChar' => sub {
  my $ch = TScreenCharacter->new( text => 'e' );

  $ch->appendZeroWidthChar(
    "\x{301}",    # COMBINING ACUTE ACCENT
  );

  is( $ch->getText, "e\x{301}", 'zero-width character appended' );
  ok( !$ch->isWide, 'resulting EGC occupies one column' );
};

done_testing();
