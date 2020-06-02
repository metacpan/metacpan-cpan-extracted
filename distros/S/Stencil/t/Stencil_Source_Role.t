use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Stencil::Source::Role

=cut

=abstract

Perl 5 role source code generator

=cut

=synopsis

  use Stencil::Source::Role;

  my $source = Stencil::Source::Role->new;

=cut

=libraries

Types::Standard

=cut

=description

This package provides a Perl 5 role source code generator, using this
specification.

  # package name
  name: MyApp

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
