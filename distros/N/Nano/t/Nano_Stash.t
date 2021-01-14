use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Nano::Stash

=cut

=tagline

Stashable Role

=cut

=abstract

Stashable Entity Role

=cut

=includes

method: get
method: set
method: stash

=cut

=synopsis

  package Example;

  use Moo;

  extends 'Nano::Node';

  with 'Nano::Stash';

  sub bestie {
    my ($self, @args) = @_;
    return $self->stash('bestie', @args);
  }

  package main;

  my $example = Example->new;

  # $example->bestie($example);

=cut

=libraries

Nano::Types

=cut

=attributes

stashed: ro, opt, HashRef

=cut

=description

This package provides an entity-stashing role, useful for the ad-hoc persisting
of L<Nano::Node> entities. This role also makes it possible to save/load
circularly dependent entities.

=cut

=method get

The get method finds and loads a previously stashed L<Nano::Node> entity.

=signature get

get(Str $name) : Maybe[Node]

=example-1 get

  my $example = Example->new;

  my $bestie = $example->get('bestie');

=example-2 get

  my $example = Example->new;

  $example->bestie($example);
  $example->save;

  my $bestie = $example->get('bestie');

=cut

=method set

The set method stashes the L<Nano::Node> entity provided by name. This does not
save the subject or invocant.

=signature set

set(Str $name, Node $node) : Node

=example-1 set

  my $example = Example->new;

  my $bestie = $example->set('bestie', $example);

=cut

=method stash

The stash method will L</get> or L</set> a stashed L<Nano::Node> entity based
on the arguments provided.

=signature stash

stash(Str $name, Maybe[Node] $node) : Maybe[Node]

=example-1 stash

  my $example = Example->new;

  my $bestie = $example->stash('bestie');

=example-2 stash

  my $example = Example->new;

  $example->bestie($example);
  $example->save;

  my $bestie = $example->stash('bestie');

=example-3 stash

  my $example = Example->new;

  my $bestie = $example->stash('bestie', $example);

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

$subs->example(-1, 'get', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'get', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Nano::Node');
  ok $result->isa('Example');

  $result
});

$subs->example(-1, 'set', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Nano::Node');
  ok $result->isa('Example');

  $result
});

$subs->example(-1, 'stash', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'stash', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Nano::Node');
  ok $result->isa('Example');

  $result
});

$subs->example(-3, 'stash', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Nano::Node');
  ok $result->isa('Example');

  $result
});

ok 1 and done_testing;
