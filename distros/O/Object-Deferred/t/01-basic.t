use warnings;
use strict;
use Test::More;
use Object::Deferred;

{
  my $resolved;
  my $rejected;

  my $deferred = Object::Deferred->new;

  $deferred->then( sub { $resolved = shift }, sub { $rejected = shift } );

  ok( $deferred->is_unfulfilled );
  ok( !$deferred->is_resolved );
  ok( !$deferred->is_rejected );

  $deferred->resolve('foo');
  is( $resolved, 'foo' );

  ok( !$deferred->is_unfulfilled );
  ok( !$deferred->is_rejected );
  ok( $deferred->is_resolved );

  is( $deferred->resolution->[0], $resolved );

  my $ran_resolved = 0;
  my $ran_rejected = 0;

  # execute subroutines immediately when object is resolved
  $deferred->then( sub { $ran_resolved = 1 }, sub { $ran_rejected = 1 } );

  ok($ran_resolved);
  ok( !$ran_rejected );
}

{
  my $resolved;
  my $rejected;
  my $deferred = Object::Deferred->new;

  $deferred->then( sub { $resolved = shift }, sub { $rejected = shift } );

  ok( $deferred->is_unfulfilled );
  ok( !$deferred->is_resolved );
  ok( !$deferred->is_rejected );

  $deferred->reject('bar');
  is( $rejected, 'bar' );

  ok( !$deferred->is_unfulfilled );
  ok( $deferred->is_rejected );
  ok( !$deferred->is_resolved );

  is( $deferred->rejection->[0], $rejected );

  my $ran_resolved = 0;
  my $ran_rejected = 0;

  # execute subroutines immediately when object is resolved
  $deferred->then( sub { $ran_resolved = 1 }, sub { $ran_rejected = 1 } );

  ok( !$ran_resolved );
  ok($ran_rejected);
}

## advanced example
{
  my $total;
  my $quantity = Object::Deferred->new;
  my $price    = Object::Deferred->new;

  my $valid_quantity = Object::Deferred->new;
  my $valid_price    = Object::Deferred->new;

  # get quantity before we know what to do with it
  $quantity->resolve(4);

  # get price before we know what to do with it
  $price->resolve(10.5);

  # declare what to do with a quantity once we get one
  $quantity->then(
    sub {
      my $value = shift;
      $valid_quantity->resolve($value), return if $value =~ /\d+/;
      $valid_quantity->reject(qq{$value isn't a valid quantity});
    }
  );

  # declare what to do with a price once we get one
  $price->then(
    sub {
      my $value = shift;
      $valid_price->resolve($value), return if $value =~ /\d+\.\d+/;
      $valid_price->reject(qq{$value isn't a valid price});
    }
  );

  # no total since we haven't declared how to build it yet
  ok( !defined $total );

  # declare what to do after we get a valid quantity and price
  $valid_quantity->then(
    sub {
      my $q = shift;
      $valid_price->then(
        sub {
          my $p = shift;
          $total = $q * $p;
          print $total, "\n";
        }
      );
    }
  );

  # could have been $valid_price->then(sub { $valid_quantity->then(etc...) })

  is( $total => 42 );
}

done_testing();
