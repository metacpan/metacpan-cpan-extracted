use strict;
use warnings;

use Test::More;
use Test::Exception;
use Hash::Util;

BEGIN {
  require_ok 'UNIVERSAL::Object';
  use_ok 'TUI::Objects::Object';
}

BEGIN {
  package Derived;
  use TUI::toolkit;
  extends 'TUI::Objects::Object';
  has x => ( is => 'rw', default => sub { 0 } );
  has y => ( is => 'rw', default => sub { 0 } );
  $INC{"Derived.pm"} = 1;
}

# Test TObject function
is( TObject, 'TUI::Objects::Object', 'TObject returns correct package name' );

# Test new method
my $obj = TObject->new();
isa_ok( $obj, TObject, 'new() creates an object of correct class' );

# Test shutDown method
can_ok( TObject, 'shutDown' );

# Test shutDown method with exception
lives_ok { $obj->shutDown() } 'shutDown() does not throw an exception';

# Test destroy class method
$obj = TObject->new();
lives_ok {
  TObject->destroy( $obj )
} 'destroy() does not throw an exception';
ok( !defined $obj, 'destroy() sets the object to undefined' );

use_ok 'Derived';

$obj = Derived->new();
isa_ok( $obj, 'UNIVERSAL::Object' );

can_ok( $obj, 'x' );
lives_ok { $obj->x() } 'x works correctly';
lives_ok { $obj->y( 1 ) } 'y works correctly';

done_testing();
