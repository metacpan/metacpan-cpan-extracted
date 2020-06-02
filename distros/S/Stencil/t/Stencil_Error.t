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

Stencil::Error

=cut

=abstract

Represents a Stencil exception

=cut

=includes

function: on_space_locate
function: on_source_load
function: on_source_test
function: on_source_data
function: on_source_section

=cut

=synopsis

  use Stencil::Data;
  use Stencil::Error;
  use Stencil::Repo;
  use Stencil::Space;

  my $repo = Stencil::Repo->new;
  my $error = Stencil::Error->new;
  my $data = Stencil::Data->new(repo => $repo, name => 'foo');
  my $space = Stencil::Space->new(repo => $repo, name => 'test');

=cut

=libraries

Types::Standard

=cut

=inherits

Data::Object::Exception

=cut

=description

This package provides an error class which represents a Stencil exception.

=cut

=function on_space_locate

The on_space_locate method returns an exception object for unlocatable spaces.

=signature on_space_locate

on_space_locate(Str $class, Object $self) : Object

=example-1 on_space_locate

  # given: synopsis

  my $result = Stencil::Error->on_space_locate($space);

  # $result->id
  # $result->message
  # $result->context

=cut

=function on_source_load

The on_source_load method returns an exception object for unloadable sources.

=signature on_source_load

on_source_load(Str $class, Object $self, Object $match) : Object

=example-1 on_source_load

  # given: synopsis

  my $result = Stencil::Error->on_source_load($space, $space->locate);

  # $result->id
  # $result->message
  # $result->context

=cut

=function on_source_test

The on_source_test method returns an exception object for sources with broken
interfaces.

=signature on_source_test

on_source_test(Str $class, Object $self, Object $match) : Object

=example-1 on_source_test

  # given: synopsis

  my $result = Stencil::Error->on_source_test($space, $space->locate);

  # $result->id
  # $result->message
  # $result->context

=cut

=function on_source_data

The on_source_data method returns an exception object for sources without
C<__DATA__> sections.

=signature on_source_data

on_source_data(Str $class, Object $self, Object $match) : Object

=example-1 on_source_data

  # given: synopsis

  my $result = Stencil::Error->on_source_data($space, $space->locate);

  # $result->id
  # $result->message
  # $result->context

=cut

=function on_source_section

The on_source_section method returns an exception object for sources without a
requested template.

=signature on_source_section

on_source_section(Str $class, Object $self, Object $match, Str $ref) : Object

=example-1 on_source_section

  # given: synopsis

  my $result = Stencil::Error->on_source_section($space, $space->locate, 'setup');

  # $result->id
  # $result->message
  # $result->context

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'on_space_locate', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->id, 'on_space_locate';

  $result
});

$subs->example(-1, 'on_source_load', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->id, 'on_source_load';

  $result
});

$subs->example(-1, 'on_source_test', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->id, 'on_source_test';

  $result
});

$subs->example(-1, 'on_source_data', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->id, 'on_source_data';

  $result
});

$subs->example(-1, 'on_source_section', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->id, 'on_source_section';

  $result
});

ok 1 and done_testing;
