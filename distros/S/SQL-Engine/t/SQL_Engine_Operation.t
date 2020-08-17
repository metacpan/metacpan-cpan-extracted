use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

SQL::Engine::Operation

=cut

=tagline

SQL Operation

=cut

=abstract

SQL Statement Operation

=cut

=includes

method: parameters

=cut

=synopsis

  use SQL::Engine::Operation;

  my $operation = SQL::Engine::Operation->new(
    statement => 'SELECT * FROM "tasks" WHERE "reporter" = ? AND "assigned" = ?',
    bindings => {
      0 => 'user_id',
      1 => 'user_id'
    }
  );

  # my @bindings = $operation->parameters({
  #   user_id => 123
  # });

=cut

=libraries

Types::Standard

=cut

=attributes

bindings: ro, req, HashRef
statement: ro, req, Str

=cut

=description

This package provides SQL Statement Operation.

=cut

=method parameters

The parameters method returns positional bind values for use with statement
handlers.

=signature parameters

parameters(Maybe[HashRef] $values) : ArrayRef

=example-1 parameters

  # given: synopsis

  my $bindings = $operation->parameters({
    user_id => 123
  });

  # [123, 123]

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'parameters', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
