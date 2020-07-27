use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

SQL::Validator::Error

=cut

=tagline

JSON-SQL Schema Validation Error

=cut

=abstract

JSON-SQL Schema Validation Error

=cut

=includes

method: match
method: report

=cut

=synopsis

  use SQL::Validator::Error;
  use JSON::Validator::Error;

  my $error = SQL::Validator::Error->new(
    issues => [
      JSON::Validator::Error->new('/root', 'not okay'),
      JSON::Validator::Error->new('/node/0', 'not okay'),
      JSON::Validator::Error->new('/node/1', 'not okay')
    ]
  );

=cut

=inherits

Data::Object::Exception

=cut

=attributes

issues: ro, req, ArrayRef[InstanceOf["JSON::Validator::Error"]]

=cut

=description

This package provides a class representation of a error resulting from the
validation of JSON-SQL schemas.

=cut

=method match

The match method returns the matching issues as an error string.

=signature match

match(Str $key = '/') : ArrayRef[Object]

=example-1 match

  # given: synopsis

  my $root = $error->match('root');

=example-2 match

  # given: synopsis

  my $nodes = $error->match('node');

=cut

=method report

The report method returns the reporting issues as an error string.

=signature report

report(Str $key = '/') : Str

=example-1 report

  # given: synopsis

  my $report = $error->report('root');

=example-2 report

  # given: synopsis

  my $report = $error->report('node');

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'match', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @$result, 1;

  $result
});

$subs->example(-2, 'match', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @$result, 2;

  $result
});

$subs->example(-1, 'report', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/root: not okay/;

  $result
});

$subs->example(-2, 'report', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  like $result, qr/node\/0: not okay/;
  like $result, qr/node\/1: not okay/;

  $result
});

ok 1 and done_testing;
