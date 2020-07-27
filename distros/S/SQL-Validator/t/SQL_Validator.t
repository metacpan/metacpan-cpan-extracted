use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

SQL::Validator

=cut

=tagline

Validate JSON-SQL Schemas

=cut

=abstract

Validate JSON-SQL Schemas

=cut

=includes

method: error
method: validate

=cut

=synopsis

  use SQL::Validator;

  my $sql = SQL::Validator->new;

  # my $valid = $sql->validate({
  #   insert => {
  #     into => {
  #       table => 'users'
  #     },
  #     default => true
  #   }
  # });

  # i.e. INSERT INTO users DEFAULT VALUES;

  # $sql->error->report('insert')

=cut

=attributes

schema: ro, opt, Any
validator: ro, opt, InstanceOf["JSON::Validator"]
version: ro, opt, Str

=cut

=description

This package provides a
L<json-sql|https://github.com/iamalnewkirk/json-sql#readme> data structure
validation library based around L<json-schema|https://json-schema.org>.

=cut

=method error

The error method validates the JSON-SQL schema provided.

=signature error

error() : InstanceOf["SQL::Validator::Error"]

=example-1 error

  # given: synopsis

  $sql->validate({});

  my $error = $sql->error;

=example-2 error

  # given: synopsis

  $sql->validate({select => {}});

  my $error = $sql->error;

=cut

=method validate

The validate method validates the JSON-SQL schema provided.

=signature validate

validate(HashRef $schema) : Bool

=example-1 validate

  # given: synopsis

  my $valid = $sql->validate({
    insert => {
      into => {
        table => 'users'
      },
      default => 'true'
    }
  });

  # VALID

=example-2 validate

  # given: synopsis

  my $valid = $sql->validate({
    insert => {
      table => 'users',
      default => 'true'
    }
  });

  # INVALID

=example-3 validate

  # given: synopsis

  my $valid = $sql->validate({
    insert => {
      into => 'users',
      values => [1, 2, 3]
    }
  });

  # INVALID

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok !$result->error;
  is $result->version, '0.0';
  ok $result->schema;
  ok $result->validator;

  $result
});

$subs->example(-1, 'error', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('SQL::Validator::Error');

  $result
});

$subs->example(-2, 'error', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('SQL::Validator::Error');

  $result
});

$subs->example(-1, 'validate', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-2, 'validate', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-3, 'validate', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

ok 1 and done_testing;
