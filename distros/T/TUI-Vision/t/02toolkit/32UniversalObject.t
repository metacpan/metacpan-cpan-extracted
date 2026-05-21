use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  unless ( eval { require UNIVERSAL::Object } ) {
  use Test::More;
    plan skip_all => 'Test irrelevant without Universal::Object';
  }
  else {
    plan tests => 9;
  }
  require_ok 'UNIVERSAL::Object';
  use_ok 'TUI::toolkit';
}

ok( TUI::toolkit::is_UNIVERSAL(), 'is UNIVERSAL::Object toolkit' );

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
isa_ok( $obj, 'UNIVERSAL::Object' );

# Test accessors
can_ok( $obj, qw( x y ) );
lives_ok { $obj->x() } 'x works correctly';
lives_ok { $obj->y( 1 ) } 'y works correctly';

done_testing();
