use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Stencil::Source::Class

=cut

=abstract

Perl 5 class source code generator

=cut

=synopsis

  use Stencil::Source::Class;

  my $source = Stencil::Source::Class->new;

=cut

=libraries

Types::Standard

=cut

=inherits

Stencil::Source

=cut

=description

This package provides a Perl 5 class source code generator, using this
specification.

  # package name
  name: MyApp

  # package inheritence
  inherits:
  - MyApp::Parent

  # package roles
  integrates:
  - MyApp::Role::Doable

  # package attributes
  attributes:
  - is: ro
    name: name
    type: Str
    required: 1

  # generator operations
  operations:
  - from: class
    make: lib/MyApp.pm
  - from: class-test
    make: t/MyApp.t

  # package functions
  functions:
  - name: execute
    args: "(Str $key) : Any"
    desc: executes something which triggers something else

  # package methods
  methods:
  - name: execute
    args: "(Str $key) : Any"
    desc: executes something which triggers something else

  # package routines
  routines:
  - name: execute
    args: "(Str $key) : Any"
    desc: executes something which triggers something else

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Stencil::Source');

  $result
});

ok 1 and done_testing;
