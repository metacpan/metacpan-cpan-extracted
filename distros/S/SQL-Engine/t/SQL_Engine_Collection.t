use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

SQL::Engine::Collection

=cut

=tagline

Generic Object Container

=cut

=abstract

Generic Object Container

=cut

=includes

method: clear
method: count
method: each
method: first
method: last
method: list
method: pop
method: pull
method: push

=cut

=synopsis

  use SQL::Engine::Collection;

  my $collection = SQL::Engine::Collection->new;

  # $collection->count;

  # 0

=cut

=libraries

Types::Standard

=cut

=attributes

items: ro, opt, ArrayRef[Object]

=cut

=description

This package provides a generic container for working with sets of objects.

=cut

=method clear

The clear method clears the collection and returns an empty list.

=signature clear

clear() : Bool

=example-1 clear

  # given: synopsis

  $collection->clear;

=cut

=method count

The count method counts and returns the number of items in the collection.

=signature count

count() : Int

=example-1 count

  # given: synopsis

  $collection->count;

=cut

=method each

The each method iterates through the collection executing the callback for each
item and returns the set of results.

=signature each

each(CodeRef $value) : ArrayRef[Any]

=example-1 each

  # given: synopsis

  $collection->each(sub {
    my ($item) = shift;

    $item
  });

=cut

=method first

The first method returns the first item in the collection.

=signature first

first() : Maybe[Object]

=example-1 first

  # given: synopsis

  $collection->first;

=cut

=method last

The last method returns the last item in the collection.

=signature last

last() : Maybe[Object]

=example-1 last

  # given: synopsis

  $collection->last;

=cut

=method list

The list method returns the collection as a list of items.

=signature list

list() : ArrayRef

=example-1 list

  # given: synopsis

  $collection->list;

=cut

=method pop

The pop method removes and returns an item from the tail of the collection.

=signature pop

pop() : Maybe[Object]

=example-1 pop

  # given: synopsis

  $collection->pop;

=cut

=method pull

The pull method removes and returns an item from the head of the collection.

=signature pull

pull() : Maybe[Object]

=example-1 pull

  # given: synopsis

  $collection->pull;

=cut

=method push

The push method inserts an item onto the tail of the collection and returns the
count.

=signature push

push(Object @values) : Int

=example-1 push

  # given: synopsis

  $collection->push(bless {});

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'clear', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'count', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'each', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'first', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'last', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'list', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'pop', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'pull', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'push', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
