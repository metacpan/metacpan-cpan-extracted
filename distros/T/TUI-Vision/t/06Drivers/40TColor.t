use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Drivers::Color';
}

subtest 'construction' => sub {
  my $def = TColor->new();
  isa_ok( $def, TColor, '$def' );

  my $bios = TColor->new( bios => 15 );
  isa_ok( $bios, TColor, '$bios' );

  my $rgb = TColor->new( rgb => 0x7F00BB );
  isa_ok( $rgb, TColor, '$rgb' );

  my $xterm = TColor->new( xterm => 196 );
  isa_ok( $xterm, TColor, '$xterm' );
};

subtest 'type predicates' => sub {
  ok(
    TColor->new()->isDefault,
    'TColor->new()->isDefault'
  );
  ok(
    TColor->new( bios => 0xF )->isBIOS,
    'TColor->new( bios => .. )->isBIOS'
  );
  ok(
    TColor->new( rgb => 0x7F00BB )->isRGB,
    'TColor->new( rgb => .. )->isRGB'
  );
  ok(
    TColor->new( xterm => 196 )->isXTerm,
    'TColor->new( xterm => .. )->isXTerm'
  );
};

subtest 'operators' => sub {
  my $a = TColor->new( rgb => 0x7F00BB );
  my $b = TColor->new( rgb => 0x7F00BB );
  my $c = TColor->new( rgb => 0x7F00BC );

  cmp_ok( $a, '==', $b, 'a == b' );
  cmp_ok( $a, '==', 0+ $b, 'a == 0+b' );
  cmp_ok( 0+ $a, '!=', $c, '0+a != c' );
};

subtest 'toBIOS' => sub {
  ok( 
    defined TColor->new( bios => 15 )->toBIOS( 1 ),
    'TColor->new( bios => .. )->toBIOS( 1 )'
  );
  ok(
    defined TColor->new( rgb => 0x7F00BB )->toBIOS( 1 ),
    'TColor->new( rgb => .. )->toBIOS( 1 )'
  );
  ok(
    defined TColor->new( xterm => 196 )->toBIOS( 1 ),
    'TColor->new( xterm => .. )->toBIOS( 1 )'
  );
};

done_testing;
