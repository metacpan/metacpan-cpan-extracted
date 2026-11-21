use strict;
use warnings;

use Test::More;
use Storable qw( freeze thaw );

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::App::Background';
  use_ok 'TUI::App::DeskTop';
}

subtest 'TBackground Storable roundtrip' => sub {
  my $background = TBackground->new(
    bounds  => TRect->new( ax => 3, ay => 4, bx => 23, by => 14 ),
    pattern => '#',
  );

  my $restored = thaw( freeze( $background ) );
  isa_ok( $restored, TBackground );
  is_deeply( $restored->{origin}, { x => 3,  y => 4  }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 10 }, 'preserves size' );
  is( $restored->{pattern}, '#', 'preserves pattern' );
}; #/ 'TBackground Storable roundtrip' => sub

subtest 'TDeskTop Storable roundtrip' => sub {
  my $desktop = TDeskTop->new(
    bounds => TRect->new( ax => 3, ay => 4, bx => 23, by => 14 ),
  );

  my $restored = thaw( freeze( $desktop ) );
  isa_ok( $restored, TDeskTop );
  is_deeply( $restored->{origin}, { x => 3,  y => 4  }, 'preserves origin' );
  is_deeply( $restored->{size},   { x => 20, y => 10 }, 'preserves size' );
  isa_ok( $restored->first, TBackground );
  is( $restored->first->{pattern}, $desktop->first->{pattern},
    'restores inherited background view' );
}; #/ 'TDeskTop Storable roundtrip' => sub

done_testing();