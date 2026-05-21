use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  unless ( eval { require Moos } ) {
    plan skip_all => 'Test irrelevant without Moos';
  }
  else {
    plan tests => 10;
  }
  require_ok 'Moos';
  use_ok 'TUI::toolkit';
}

BEGIN {
  package MyObject;
  use TUI::toolkit;
  has x => ( is => 'rw' );
  has y => ( is => 'rw' );
  sub DEMOLISH { ::pass 'DEMOLISH was called from '. caller }
  $INC{"MyObject.pm"} = 1;
}

use_ok 'MyObject';

# Test new method
my $obj = MyObject->new();
isa_ok( $obj, 'MyObject', 'new() creates an object of correct class' );
isa_ok( $obj, 'Moos::Object' );

# Test accessors
can_ok( $obj, qw( x y ) );
lives_ok { $obj->x() } 'x works correctly';
lives_ok { $obj->y( 1 ) } 'y works correctly';

# Test DEMOLISHALL in DESTROY
lives_ok { undef $obj } 'cleanup is working properly';

done_testing();
