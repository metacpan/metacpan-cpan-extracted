use 5.014;

use lib 't/lib';

BEGIN {
  use File::Temp 'tempdir';

  $ENV{STENCIL_HOME} = tempdir('cleanup', 1);
}

use strict;
use warnings;
use routines;

use File::Spec::Functions qw(catfile);

use Test::Auto;
use Test::More;

=name

Stencil::Repo

=cut

=abstract

Represents a Stencil workspace

=cut

=includes

method: store

=cut

=synopsis

  use Stencil::Repo;

  my $repo = Stencil::Repo->new;

=cut

=libraries

Types::Standard

=cut

=attributes

base: ro, opt, Str
path: ro, opt, Object

=cut

=description

This package provides a repo class which represents a Stencil workspace.

=cut

=method store

The store method returns a L<Path::Tiny> object representing a file or
directory in the stencil workspace.

=signature store

store(Str @parts) : InstanceOf["Path::Tiny"]

=example-1 store

  # given: synopsis

  $repo->store;

=example-2 store

  # given: synopsis

  $repo->store('logs');

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'store', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  $result->isa('Path::Tiny');
  my $home = quotemeta catfile($ENV{STENCIL_HOME}, '.stencil');
  like $result->stringify, qr/$home/;

  $result
});

$subs->example(-2, 'store', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  $result->isa('Path::Tiny');
  my $logs = quotemeta catfile($ENV{STENCIL_HOME}, '.stencil', 'logs');
  like $result->stringify, qr/$logs/;

  $result
});

ok 1 and done_testing;
