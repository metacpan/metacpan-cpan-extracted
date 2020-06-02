use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Stencil::Source::Awncorp::Class

=cut

=abstract

Stencil Generator for Classes

=cut

=synopsis

  use Stencil::Source::Awncorp::Class;

  my $s = Stencil::Source::Awncorp::Class->new;

=cut

=libraries

Types::Standard

=cut

=inherits

Stencil::Source

=cut

=description

This package provides a L<Stencil> generator for L<Data::Object::Class> based
roles and L<Test::Auto> tests. This generator produces the following specification:

  name: MyApp
  desc: Doing One Thing Very Well

  libraries:
  - MyApp::Types

  inherits:
  - MyApp::Parent

  integrates:
  - MyApp::Role::Doable

  attributes:
  - is: ro
    name: name
    type: Str
    form: req

  operations:
  - from: class
    make: lib/MyApp.pm
  - from: class-test
    make: t/MyApp.t

  scenarios:
  - name: exports
    desc: exporting the following functions

  functions:
  - name: handler_a
    args: "(Str $key) : Any"
    desc: executes something which triggers something else

  methods:
  - name: handle_b
    args: "(Str $key) : Any"
    desc: executes something which triggers something else

  routines:
  - name: handle_c
    args: "(Str $key) : Any"
    desc: executes something which triggers something else

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
