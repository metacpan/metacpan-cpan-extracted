use 5.014;

use lib 't/lib';

use Do;
use Test::Auto;
use Test::More;

=name

Test::Auto::Plugin

=abstract

Test-Auto Plugin Class

=includes

method: tests

=synopsis

  package Test::Auto::Plugin::Example;

  use Test::More;

  use parent 'Test::Auto::Plugin';

  sub tests {
    my ($self, @args) = @_;

    subtest "testing example plugin", fun () {

      ok 1;
    };

    return $self;
  }

  1;

=description

This package provides an abstract base class for creating L<Test::Auto>
plugins.

=libraries

Data::Object::Library

=attributes

subtests: ro, req, InstanceOf["Test::Auto::Subtests"]

=method tests

This method is meant to be overridden by the superclass, and should perform
specialized subtests. While not required, ideally this method should return its
invocant.

=signature tests

tests(Any @args) : Object

=example-1 tests

  package main;

  use Test::Auto;
  use Test::Auto::Parser;
  use Test::Auto::Subtests;

  my $test = Test::Auto->new(
    't/Test_Auto_Plugin.t'
  );

  my $parser = Test::Auto::Parser->new(
    source => $test
  );

  my $subtests = Test::Auto::Subtests->new(
    parser => $parser
  );

  # Test::Auto::Plugin::ShortDescription
  my $example = $subtests->plugin('ShortDescription');

  $example->tests(length => 200);

=cut

package main;

my $subs = testauto(__FILE__);

$subs = $subs->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'tests', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  ok $result->isa('Test::Auto::Plugin::ShortDescription');
  ok $result->isa('Test::Auto::Plugin');

  $result;
});

ok 1 and done_testing;
