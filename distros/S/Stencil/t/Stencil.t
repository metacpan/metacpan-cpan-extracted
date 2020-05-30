use 5.014;

use lib 't/lib';

BEGIN {
  $ENV{STENCIL_HOME} = 't/tmp';
}

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Stencil

=cut

=tagline

Code Generation

=cut

=abstract

Code Generation Tool for Perl 5

=cut

=includes

method: init
method: make
method: seed

=cut

=synopsis

  use Stencil;
  use Stencil::Repo;
  use Stencil::Space;
  use Stencil::Data;

  my $repo = Stencil::Repo->new;
  my $space = Stencil::Space->new(name => 'gen', repo => $repo);
  my $spec = Stencil::Data->new(name => 'foo', repo => $repo);
  my $stencil = Stencil->new(repo  => $repo, space => $space, spec  => $spec);

  # $stencil->init;
  # $stencil->seed;
  # $stencil->make;

=cut

=libraries

Types::Standard

=cut

=attributes

repo: ro, req, Object
space: ro, req, Maybe[Object]
spec: ro, req, Maybe[Object]

=cut

=description

This package provides a framework for generating source code, and methods for
rapidly generating one or more files from a single, human readable
specification. See the L<stencil> command-line tool for additional usage
details.

=cut

=method init

The init method initialize the stencil store and logs.

=signature init

init() : Object

=example-1 init

  # given: synopsis

  $stencil->init;

=cut

=method make

The make method generate source code from the generator specification (yaml) file.

=signature make

make() : ArrayRef[Object]

=example-1 make

  # given: synopsis

  $stencil->seed;
  $stencil->make;

=cut

=method seed

The seed method creates the generator specification (yaml) file.

=signature seed

seed() : Object

=example-1 seed

  # given: synopsis

  $stencil->seed;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'init', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'make', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'seed', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
