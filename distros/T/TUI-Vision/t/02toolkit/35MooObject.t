use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  unless ( eval { require Moo } ) {
    plan skip_all => 'Test irrelevant without Moo';
  }
  else {
    plan tests => 8;
  }
  require_ok 'Moo';
  use_ok 'TUI::toolkit';
}

BEGIN {
  package MyObject;
  use TUI::toolkit;
  has x => ( is => 'rw' );
  has y => ( is => 'rw' );
  $INC{"MyObject.pm"} = 1;
}

use_ok 'MyObject';

# Test new method
my $obj = MyObject->new();
isa_ok( $obj, 'MyObject', 'new() creates an object of correct class' );
isa_ok( $obj, 'Moo::Object' );

# Test accessors
can_ok( $obj, qw( x y ) );
lives_ok { $obj->x() } 'x works correctly';
lives_ok { $obj->y( 1 ) } 'y works correctly';

done_testing();
