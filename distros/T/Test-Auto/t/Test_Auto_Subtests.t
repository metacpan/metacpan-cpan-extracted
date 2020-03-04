use 5.014;

use lib 't/lib';

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Test::Auto::Subtests

=abstract

Testing Automation

=includes

method: attributes
method: document
method: evaluator
method: example
method: functions
method: inherits
method: libraries
method: methods
method: package
method: plugin
method: registry
method: routines
method: standard
method: synopsis
method: scenario
method: tryable

=synopsis

  package main;

  use Test::Auto;
  use Test::Auto::Parser;
  use Test::Auto::Subtests;

  my $test = Test::Auto->new(
    't/Test_Auto_Subtests.t'
  );

  my $parser = Test::Auto::Parser->new(
    source => $test
  );

  my $subtests = Test::Auto::Subtests->new(
    parser => $parser
  );

  # execute dynamic subtests

  # $subtests->standard

=description

This package use the L<Test::Auto::Parser> object to execute a set of dynamic
subtests.

=libraries

Test::Auto::Types

=attributes

parser: ro, req, Parser

=method attributes

This method registers and executes a subtest which tests the declared
attributes.

=signature attributes

attributes() : Any

=example-1 attributes

  # given: synopsis

  $subtests->attributes;

=method document

This method registers and executes a subtest which tests the test document
structure.

=signature document

document() : Any

=example-1 document

  # given: synopsis

  $subtests->document;

=method evaluator

This method evaluates (using C<eval>) the context given and returns the result
or raises an exception.

=signature evaluator

evaluator(Str $context) : Any

=example-1 evaluator

  # given: synopsis

  my $context = '1 + 1';

  $subtests->evaluator($context); # 2

=method example

This method finds and evaluates (using C<eval>) the documented example and
returns a L<Data::Object::Try> object. The C<try> object can be used to trap
exceptions using the C<catch> method, and/or execute the code and return the
result using the C<result> method.

=signature example

example(Num $number, Str $name, Str $type, CodeRef $callback) : Any

=example-1 example

  # given: synopsis

  $subtests->example(1, 'evaluator', 'method', sub {
    my ($tryable) = @_;

    ok my $result = $tryable->result, 'result ok';
    is $result, 2, 'meta evaluator test ok';

    $result;
  });

=method functions

This method registers and executes a subtest which tests the declared
functions.

=signature functions

functions() : Any

=example-1 functions

  # given: synopsis

  $subtests->functions;

=method inherits

This method registers and executes a subtest which tests the declared
inheritances.

=signature inherits

inherits() : Any

=example-1 inherits

  # given: synopsis

  $subtests->inherits;

=method libraries

This method registers and executes a subtest which tests the declared
type libraries.

=signature libraries

libraries() : Any

=example-1 libraries

  # given: synopsis

  $subtests->libraries;

=method methods

This method registers and executes a subtest which tests the declared
methods.

=signature methods

methods() : Any

=example-1 methods

  # given: synopsis

  $subtests->methods;

=method package

This method registers and executes a subtest which tests the declared
package.

=signature package

package() : Any

=example-1 package

  # given: synopsis

  $subtests->package;

=method plugin

This method builds, tests, and returns a plugin object based on the name
provided.

=signature plugin

plugin(Str $name) : Object

=example-1 plugin

  # given: synopsis

  $subtests->plugin('ShortDescription');

=method registry

This method returns a type registry object comprised of the types declare in
the declared type libraries.

=signature registry

registry() : InstanceOf["Type::Registry"]

=example-1 registry

  # given: synopsis

  my $registry = $subtests->registry;

=method routines

This method registers and executes a subtest which tests the declared
routines.

=signature routines

routines() : Any

=example-1 routines

  # given: synopsis

  $subtests->routines;

=method standard

This method is shorthand which registers and executes a series of other
standard subtests.

=signature standard

standard() : Subtests

=example-1 standard

  # given: synopsis

  # use:
  $subtests->standard;

  # instead of:
  # $self->package;
  # $self->document;
  # $self->libraries;
  # $self->inherits;
  # $self->attributes;
  # $self->methods;
  # $self->routines;
  # $self->functions;
  # $self->types;

=method scenario

This method finds and evaluates (using C<eval>) the documented scenario example
and returns a L<Data::Object::Try> object. The C<try> object can be used to
trap exceptions using the C<catch> method, and/or execute the code and return
the result using the C<result> method.

=signature scenario

scenario(Str $name, CodeRef $callback) : Any

=example-1 scenario

  package main;

  use Test::Auto;

  my $test = Test::Auto->new(
    't/Test_Auto.t'
  );

  my $subtests = $test->subtests;

  $subtests->scenario('exports', sub {
    my ($tryable) = @_;

    ok my $result = $tryable->result, 'result ok';

    $result;
  });

=method synopsis

This method evaluates (using C<eval>) the documented synopsis and
returns a L<Data::Object::Try> object. The C<try> object can be used to trap
exceptions using the C<catch> method, and/or execute the code and return the
result using the C<result> method.

=signature synopsis

synopsis(CodeRef $callback) : Any

=example-1 synopsis

  # given: synopsis

  $subtests->synopsis(sub {
    my ($tryable) = @_;
    ok my $result = $tryable->result, 'result ok';
    is ref($result), 'Test::Auto::Subtests', 'isa ok';

    $result;
  });

=method tryable

This method returns a tryable object which can be used to defer code execution
with a try/catch construct.

=signature tryable

tryable(Any @arguments) : InstanceOf["Data::Object::Try"]

=example-1 tryable

  # given: synopsis

  my $tryable = $subtests->tryable;

  $tryable->call(sub { $_[0] + 1 });

  # $tryable->result(1);
  #> 2

=example-2 tryable

  # given: synopsis

  my $tryable = $subtests->tryable(1);

  $tryable->call(sub { $_[0] + $_[1] });

  # $tryable->result(1);
  #> 2

=cut

package main;

my $subs = testauto(__FILE__);

$subs = $subs->standard;
$subs->plugin('ShortDescription')->tests;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is ref($result), 'Test::Auto::Subtests', 'isa ok';

  $result;
});

$subs->example(-1, 'attributes', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'document', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'evaluator', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'example', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'functions', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'inherits', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'libraries', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'methods', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'package', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'plugin', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'registry', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'routines', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'standard', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'scenario', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'synopsis', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'tryable', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-2, 'tryable', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

ok 1 and done_testing;
