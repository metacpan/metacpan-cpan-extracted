use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::App::Const', qw( cpBackground );
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::Palette';
  use_ok 'TUI::App::Background';
}

# Test object creation
my $background = TBackground->new( bounds => TRect->new(), pattern => '#' );
isa_ok( $background, TBackground, 'Object is of class TBackground' );

# Test draw method
can_ok( $background, 'draw' );
lives_ok { $background->draw() } 'draw works correctly';

# Test getPalette method
can_ok( $background, 'getPalette' );
my $palette = $background->getPalette();
isa_ok( $palette, TPalette, 'getPalette returns a TPalette object' );
is(
  substr($$palette, 1, length( cpBackground) ),
  cpBackground, 
  'getPalette returns correct content'
);

done_testing();
