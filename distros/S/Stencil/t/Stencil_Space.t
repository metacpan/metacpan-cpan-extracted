use 5.014;

use lib 't/lib';

BEGIN {
  use File::Temp 'tempdir';

  $ENV{STENCIL_HOME} = tempdir('cleanup', 1);
}

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Stencil::Space

=cut

=abstract

Represents a generator class

=cut

=includes

method: locate
method: source

=cut

=synopsis

  use Stencil::Space;

  my $space = Stencil::Space->new(name => 'test');

  # global: <Test>
  # local:  <Stencil::Source::Test>

  # $space->locate;

=cut

=libraries

Types::Standard

=cut

=attributes

name: ro, req, Str
local: ro, opt, Object
global: ro, opt, Object
repo: ro, opt, Object

=cut

=description

This package provides namespace class which represents a Stencil generator
class.

=cut

=method locate

The locate method attempts to return one of the L<Data::Object::Space> objects
in the C<local> and C<global> attributes.

=signature locate

locate() : Maybe[Object]

=example-1 locate

  # given: synopsis

  $space->locate;

=cut

=method source

The source method locates, loads, and validates the L<Stencil::Source> derived
source code generator.

=signature source

source() : InstanceOf["Stencil::Source"]

=example-1 source

  # given: synopsis

  $space->source;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'locate', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Space');
  is $result->package, 'Stencil::Source::Test';

  $result
});

$subs->example(-1, 'source', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Stencil::Source::Test');
  ok $result->isa('Stencil::Source');
  ok $result->template('spec');
  ok $result->template('class');
  ok $result->template('class-test');

  $result
});

ok 1 and done_testing;
