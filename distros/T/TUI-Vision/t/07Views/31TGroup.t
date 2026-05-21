use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::Objects::Rect';
  use_ok 'TUI::Views::Const', qw( cmCancel );
  use_ok 'TUI::Views::View';
  use_ok 'TUI::Views::Group';
}

# Mocking TGroup for testing purposes
BEGIN {
  package MyGroup;
  use TUI::toolkit;
  extends 'TUI::Views::Group';
  sub handleEvent { shift->{endState} = 100 }
  $INC{"MyGroup.pm"} = 1;
}

use_ok 'MyGroup';

my $bounds = TRect->new( ax => 0, ay => 0, bx => 10, by => 10 );
isa_ok( $bounds, TRect );

# Test object creation
my $group = TGroup->new( bounds => $bounds );
isa_ok( $group, TGroup, 'Object is of class TGroup' );

# Test DEMOLISH method
can_ok( $group, 'DEMOLISH' );
lives_ok { $group->DEMOLISH(0) }
  'DEMOLISH method works correctly';

# Test shutDown method
can_ok( $group, 'shutDown' );
lives_ok { $group->shutDown() }
  'shutDown method works correctly';

# Test execView method
can_ok( $group, 'execView' );
my $view = TView->new( bounds => $bounds );
is( $group->execView( $view ), cmCancel, 'execView returns correct value' );

# Test execute method
$group = MyGroup->new( bounds => $bounds );
can_ok( $group, 'execute' );
is( $group->execute(), 100, 'execute returns correct value' );

# Test awaken method
$group = TGroup->new( bounds => $bounds );
can_ok( $group, 'awaken' );
lives_ok { $group->awaken() }
  'awaken method works correctly';

done_testing();
