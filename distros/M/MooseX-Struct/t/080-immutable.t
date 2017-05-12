#!perl -T

package MyObject;
use Test::More tests => 1;

use MooseX::Struct;

immutable struct {
      bar => 'Scalar'
};

ok(!eval{has 'baz' => ( is => 'rw', isa => 'ArrayRef' );}, "Inable to extend immutable struct");

