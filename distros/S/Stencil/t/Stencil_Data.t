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

Stencil::Data

=cut

=abstract

Represents the generator specification

=cut

=includes

method: read
method: write

=cut

=synopsis

  use Stencil::Repo;
  use Stencil::Data;

  my $repo = Stencil::Repo->new;

  $repo->store->mkpath;

  my $spec = Stencil::Data->new(name => 'foo', repo => $repo);

  # $spec->read;
  # $spec->write($data);

=cut

=libraries

Types::Standard

=cut

=attributes

name: ro, req, Str
repo: ro, req, Object
file: ro, opt, Object

=cut

=description

This package provides a spec class which represents the generator
specification.

=cut

=method read

The read method reads the generator specification (yaml) file and returns the
data.

=signature read

read() : HashRef

=example-1 read

  # given: synopsis

  $spec->read($spec->write({ name => 'gen' }));

=cut

=method write

The write method write the generator specification (yaml) file and returns the
file written.

=signature write

write(HashRef $data) : InstanceOf["Path::Tiny"]

=example-1 write

  # given: synopsis

  $spec->write($spec->read);

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'read', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'write', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
