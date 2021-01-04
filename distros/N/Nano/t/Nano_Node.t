use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Nano::Node

=cut

=tagline

Persistable Entity

=cut

=abstract

Persistable Entity Super Class

=cut

=includes

method: drop
method: load
method: save
method: serialize

=cut

=synopsis

  use Nano::Node;

  my $node = Nano::Node->new(
    id => '0000001',
  );

  # $node->save;

=cut

=libraries

Nano::Types

=cut

=attributes

id: ro, opt, Str
nano: ro, opt, Nano

=cut

=description

This package provides a persistable entity super class. It is meant to be
subclassed but can be used directly as well.

=cut

=method drop

The drop method removes the prior persisted object data.

=signature drop

drop() : Object

=example-1 drop

  # given: synopsis

  $node = $node->drop;

=cut

=method load

The load method reloads and returns an object from source.

=signature load

load() : Object

=example-1 load

  # given: synopsis

  $node->save;

  $node = $node->load;

=cut

=method save

The save method commits the object data to the storage backend.

=signature save

save() : Str

=example-1 save

  # given: synopsis

  my $term = $node->save;

=cut

=method serialize

The serialize method returns a persistence representaton of the invocant.
Circular dependencies can result in a deep recursion error, however, circular
dependencies can be persisted if modeled properly. B<Note:> blessed objects
which are neither L<Nano::Node> nor L<Nano::Nodes> will be ignored.

=signature serialize

serialize() : HashRef

=example-1 serialize

  # given: synopsis

  my $serial = $node->serialize;

=cut

package main;

BEGIN {
  $ENV{ZING_STORE} = 'Zing::Store::Hash';
}

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'drop', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'load', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Nano::Node');

  $result
});

$subs->example(-1, 'save', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'serialize', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->{'$name'};
  ok $result->{'$data'};
  ok $result->{'$type'};

  $result
});

ok 1 and done_testing;
