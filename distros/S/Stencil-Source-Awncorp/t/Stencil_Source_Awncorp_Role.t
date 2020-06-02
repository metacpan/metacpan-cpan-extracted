use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Stencil::Source::Awncorp::Role

=cut

=abstract

Stencil Generator for Roles

=cut

=synopsis

  use Stencil::Source::Awncorp::Role;

  my $s = Stencil::Source::Awncorp::Role->new;

=cut

=libraries

Types::Standard

=cut

=inherits

Stencil::Source

=cut

=description

This package provides a L<Stencil> generator for L<Data::Object::Role> based
roles and L<Test::Auto> tests. This generator produces the following specification:

  name: MyApp
  desc: Doing One Thing Very Well

  libraries:
  - MyApp::Types

  integrates:
  - MyApp::Role::Doable

  attributes:
  - is: ro
    name: name
    type: Str
    form: req

  operations:
  - from: role
    make: lib/MyApp.pm
  - from: role-test
    make: t/MyApp.t

  scenarios:
  - name: exports
    desc: exporting the following functions

  functions:
  - name: handle_a
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
