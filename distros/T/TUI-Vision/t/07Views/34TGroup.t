use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Drivers::Event';
  use_ok 'TUI::Views::Const', qw(
    cmReleasedFocus
    hcNoContext
    sfExposed
  );
  use_ok 'TUI::Views::Group';
}

# Test object creations
my $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
isa_ok( $bounds, TRect, 'Object is of class TRect' );

my $event = TEvent->new();
isa_ok( $event, TEvent, 'Object is of class TEvent' );

my $group = TGroup->new( bounds => $bounds );
isa_ok( $group, TGroup, 'Object is of class TGroup' );

# Test draw method
can_ok( $group, 'draw' );
lives_ok { $group->draw() } 'draw works correctly';

# Test redraw method
can_ok( $group, 'redraw' );
lives_ok { $group->redraw() } 'redraw works correctly';

# Test getBuffer method
$group->{state} |= sfExposed;
$group->{size}{x} = $group->{size}{y} = 1;
can_ok( $group, 'getBuffer' );
lives_ok { $group->getBuffer() } 'getBuffer works correctly';

# Test lock and getBuffer method
can_ok( $group, 'lock' );
lives_ok { $group->lock() } 'lock works correctly';
ok( $group->{lockFlag}, 'lockFlag is not 0' );

# Test freeBuffer method
can_ok( $group, 'freeBuffer' );
lives_ok { $group->freeBuffer() } 'freeBuffer works correctly';

# Test unlock and drawView method
can_ok( $group, 'unlock' );
lives_ok { $group->unlock() } 'unlock works correctly';
ok( !$group->{lockFlag}, 'lockFlag is 0' );

# Test resetCursor method
can_ok( $group, 'resetCursor' );
lives_ok { $group->resetCursor() } 'resetCursor works correctly';

# Test endModal method
can_ok( $group, 'endModal' );
lives_ok { $group->endModal( 1 ) } 'endModal works correctly';

# Test eventError method
can_ok( $group, 'eventError' );
lives_ok { $group->eventError( $event ) } 'eventError works correctly';

# Test getHelpCtx method
can_ok( $group, 'getHelpCtx' );
is( $group->getHelpCtx(), hcNoContext, 'getHelpCtx returns correct value' );

# Test valid method
can_ok( $group, 'valid' );
is( $group->valid( cmReleasedFocus ), 1, 'valid returns correct value' );

done_testing();
