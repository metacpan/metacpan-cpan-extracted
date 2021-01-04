use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Nano::Search

=cut

=tagline

Persisted Index Search

=cut

=abstract

Persisted Index Search

=cut

=includes

method: all
method: count
method: fetch
method: first
method: last
method: next
method: order
method: prev
method: reset
method: scope

=cut

=synopsis

  use Nano::Nodes;
  use Nano::Search;

  my $nodes = Nano::Nodes->new(
    type => 'Nano::Node',
  );

  my $search = Nano::Search->new(
    nodes => $nodes,
  );

  # $search->count;

=cut

=libraries

Nano::Types

=cut

=attributes

nodes: ro, req, Nodes
orders: ro, opt, ArrayRef[CodeRef]
scopes: ro, opt, ArrayRef[CodeRef]
table: ro, opt, Table

=cut

=description

This package provides a mechanism for searching a prior persisted index.

=cut

=method all

The all method returns all objects (qualified via scopes, when present) from
the index.

=signature all

all() : ArrayRef[Object]

=example-1 all

  # given: synopsis

  my $result = $search->all;

=example-2 all

  # given: synopsis

  use Nano::Node;

  $search->nodes->set(Nano::Node->new);
  $search->nodes->set(Nano::Node->new);

  my $result = $search->all;

=cut

=method count

The count method returns the count of objects (qualified via scopes, when
present) in the index.

=signature count

count() : Int

=example-1 count

  # given: synopsis

  my $count = $search->count;

=example-2 count

  # given: synopsis

  use Nano::Node;

  $search->nodes->set(Nano::Node->new);
  $search->nodes->set(Nano::Node->new);

  my $count = $search->count;

=cut

=method fetch

The fetch method returns a variable number of objects (qualified via scopes,
when present) from the index.

=signature fetch

fetch(Int $size = 1) : ArrayRef[Object]

=example-1 fetch

  # given: synopsis

  my $result = $search->fetch;

=example-2 fetch

  # given: synopsis

  use Nano::Node;

  $search->nodes->set(Nano::Node->new);
  $search->nodes->set(Nano::Node->new);

  my $result = $search->fetch;

=example-3 fetch

  # given: synopsis

  use Nano::Node;

  $search->nodes->set(Nano::Node->new);
  $search->nodes->set(Nano::Node->new);
  $search->nodes->set(Nano::Node->new);

  my $result = $search->fetch(2);

=cut

=method first

The first method returns the first object (qualified via scopes, when present)
from the index.

=signature first

first() : Maybe[Object]

=example-1 first

  # given: synopsis

  my $first = $search->first;

=example-2 first

  # given: synopsis

  use Nano::Node;

  $search->nodes->set(Nano::Node->new(id => '1st'));
  $search->nodes->set(Nano::Node->new(id => '2nd'));
  $search->nodes->set(Nano::Node->new(id => '3rd'));

  my $first = $search->first;

=cut

=method last

The last method returns the last object (qualified via scopes, when present)
from the index.

=signature last

last() : Maybe[Object]

=example-1 last

  # given: synopsis

  my $last = $search->last;

=example-2 last

  # given: synopsis

  use Nano::Node;

  $search->nodes->set(Nano::Node->new(id => '1st'));
  $search->nodes->set(Nano::Node->new(id => '2nd'));
  $search->nodes->set(Nano::Node->new(id => '3rd'));

  my $last = $search->last;

=cut

=method next

The next method returns the next object based on the currently held cursor
(qualified via scopes, when present) from the index.

=signature next

next() : Maybe[Object]

=example-1 next

  # given: synopsis

  my $next = $search->next;

=example-2 next

  # given: synopsis

  use Nano::Node;

  $search->nodes->set(Nano::Node->new(id => '1st'));
  $search->nodes->set(Nano::Node->new(id => '2nd'));
  $search->nodes->set(Nano::Node->new(id => '3rd'));

  my $next = $search->next;

=example-3 next

  # given: synopsis

  use Nano::Node;

  $search->nodes->set(Nano::Node->new(id => '1st'));
  $search->nodes->set(Nano::Node->new(id => '2nd'));
  $search->nodes->set(Nano::Node->new(id => '3rd'));

  my $next;

  $next = $search->next;
  $next = $search->next;

=cut

=method order

The order method determines the sort order of the array of objects provided
based on the registered ordering routines.

=signature order

order(ArrayRef[Object] $results) : ArrayRef[Object]

=example-1 order

  # given: synopsis

  use Nano::Node;

  my $results = [
    Nano::Node->new(id => '1st'),
    Nano::Node->new(id => '2nd'),
    Nano::Node->new(id => '3rd'),
  ];

  $search = Nano::Search->new(
    nodes => $nodes,
    orders => [sub {
      my ($a, $b) = @_;
      $a->id cmp $b->id
    }],
  );

  $results = $search->order($results);

=example-2 order

  # given: synopsis

  use Nano::Node;

  my $results = [
    Nano::Node->new(id => '1st'),
    Nano::Node->new(id => '2nd'),
    Nano::Node->new(id => '3rd'),
  ];

  $search = Nano::Search->new(
    nodes => $nodes,
    orders => [sub {
      my ($a, $b) = @_;
      $b->id cmp $a->id
    }],
  );

  $results = $search->order($results);

=cut

=method prev

The prev method returns the previous object based on the currently held cursor
(qualified via scopes, when present) from the index.

=signature prev

prev() : Maybe[Object]

=example-1 prev

  # given: synopsis

  my $prev = $search->prev;

=example-2 prev

  # given: synopsis

  use Nano::Node;

  $search->table->position(3);

  $search->nodes->set(Nano::Node->new(id => '1st'));
  $search->nodes->set(Nano::Node->new(id => '2nd'));
  $search->nodes->set(Nano::Node->new(id => '3rd'));

  my $prev = $search->prev;

=example-3 prev

  # given: synopsis

  use Nano::Node;

  $search->table->position(3);

  $search->nodes->set(Nano::Node->new(id => '1st'));
  $search->nodes->set(Nano::Node->new(id => '2nd'));
  $search->nodes->set(Nano::Node->new(id => '3rd'));

  my $prev;

  $prev = $search->prev;
  $prev = $search->prev;

=cut

=method reset

The reset method resets the position on the currently held cursor.

=signature reset

reset() : Object

=example-1 reset

  # given: synopsis

  $search = $search->reset;

=cut

=method scope

The scope method determines whether the object provided passes-through the
registered scopes and if-so returns the object provided.

=signature scope

scope(Object $object) : Maybe[Object]

=example-1 scope

  # given: synopsis

  use Nano::Node;

  my $node = Nano::Node->new(id => '0000003');

  my $result = $search->scope($node);

=example-2 scope

  # given: synopsis

  use Nano::Node;

  $search = Nano::Search->new(
    nodes => $nodes,
    scopes => [sub {
      my ($node) = @_;
      $node->id ne '0000003'
    }],
  );

  my $node = Nano::Node->new(id => '0000003');

  my $result = $search->scope($node);

=example-3 scope

  # given: synopsis

  use Nano::Node;

  $search = Nano::Search->new(
    nodes => $nodes,
    scopes => [sub {
      my ($node) = @_;
      $node->id ne '0000003'
    }],
  );

  my $node = Nano::Node->new(id => '0000004');

  my $result = $search->scope($node);

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

$subs->example(-1, 'all', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

$subs->example(-2, 'all', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->[0]->isa('Nano::Node');
  ok $result->[1]->isa('Nano::Node');

  $result
});

$subs->example(-1, 'count', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, 0;

  $result
});

$subs->example(-2, 'count', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 2;

  $result
});

$subs->example(-1, 'fetch', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

$subs->example(-2, 'fetch', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @{$result}, 1;
  ok $result->[0]->isa('Nano::Node');

  $result
});

$subs->example(-3, 'fetch', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @{$result}, 2;
  ok $result->[0]->isa('Nano::Node');
  ok $result->[1]->isa('Nano::Node');

  $result
});

$subs->example(-1, 'first', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'first', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Nano::Node');
  is $result->id, '1st';

  $result
});

$subs->example(-1, 'last', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'last', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Nano::Node');
  is $result->id, '3rd';

  $result
});

$subs->example(-1, 'next', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'next', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Nano::Node');
  is $result->id, '1st';

  $result
});

$subs->example(-3, 'next', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Nano::Node');
  is $result->id, '2nd';

  $result
});

$subs->example(-1, 'order', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @$result, 3;
  ok $result->[0]->isa('Nano::Node');
  is $result->[0]->id, '1st';
  ok $result->[1]->isa('Nano::Node');
  is $result->[1]->id, '2nd';
  ok $result->[2]->isa('Nano::Node');
  is $result->[2]->id, '3rd';

  $result
});

$subs->example(-2, 'order', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is @$result, 3;
  ok $result->[0]->isa('Nano::Node');
  is $result->[0]->id, '3rd';
  ok $result->[1]->isa('Nano::Node');
  is $result->[1]->id, '2nd';
  ok $result->[2]->isa('Nano::Node');
  is $result->[2]->id, '1st';

  $result
});

$subs->example(-1, 'prev', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'prev', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Nano::Node');
  is $result->id, '3rd';

  $result
});

$subs->example(-3, 'prev', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Nano::Node');
  is $result->id, '2nd';

  $result
});

$subs->example(-1, 'reset', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'scope', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Nano::Node');
  is $result->id, '0000003';

  $result
});

$subs->example(-2, 'scope', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-3, 'scope', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Nano::Node');
  is $result->id, '0000004';

  $result
});

ok 1 and done_testing;
