use warnings;
use strict;
use Test::More;

use Object::Deferred;

{
  my $resolved;
  my $rejected;

  my $promise_resolved;
  my $promise_rejected;

  my $deferred = Object::Deferred->new;

  $deferred->then( sub { $resolved = shift }, sub { $rejected = shift } );

  my $promise = $deferred->then(
    sub { $promise_resolved = 'promise ' . shift },
    sub { $promise_rejected = 'promise ' . shift }
  );

  ok( $deferred->is_unfulfilled );
  ok( !$deferred->is_resolved );
  ok( !$deferred->is_rejected );

  is_equal_state( $promise, $deferred,
    qw(is_unfulfilled is_resolved is_rejected) );

  $deferred->resolve('foo');
  is( $resolved, 'foo' );

  ok( !$deferred->is_rejected );
  ok( $deferred->is_resolved );
  ok( !$deferred->is_unfulfilled );

  is_equal_state( $promise, $deferred,
    qw(is_unfulfilled is_resolved is_rejected) );

  is( $deferred->resolution->[0], $resolved );

}

sub is_equal_state {
  my ( $obj1, $obj2, @meths ) = @_;
  foreach my $meth (@meths) {
    cmp_ok( $obj1->$meth, '==', $obj2->$meth );
  }
}

done_testing();
