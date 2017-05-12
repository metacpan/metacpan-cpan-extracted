#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  chdir 't' if -d 't';		# for manual runs
  unshift @INC, '../lib';	# for manual runs
  plan tests => 46;
  use_ok ('Set::Light');
  }

can_ok ('Set::Light', qw/
  new
  insert
  delete remove
  has contains exists

  is_empty is_null
  size
  /);

#############################################################################
# new()

my $set = Set::Light->new();

is (ref($set), 'Set::Light', 'new did something');

#############################################################################
# has/contains/exists()

for my $method (qw/has exists contains/)
  {
  ok (!$set->$method("foo"), 'no foo');
  ok (!$set->$method("bar"), 'no foo');
  }

ok ($set->is_null(),  'set is empty');
ok ($set->is_empty(), 'set is empty');
is ($set->size(), 0, 'set is empty');

#############################################################################
# insert(), size()

is ($set->insert('foo'), 1, 'inserted one');
is ($set->has("foo"), 1, 'was really inserted');
is ($set->insert('foo'), 0, 'inserted zero');
is ($set->has("foo"), 1, 'was really inserted');

is ($set->insert('foo','bar'), 1, 'inserted bar');
is ($set->has("foo"), 1, 'was really inserted');
is ($set->has("bar"), 1, 'was really inserted');

is ($set->insert('foo','bar'), 0, 'inserted none');
is ($set->has("foo"), 1, 'foo is still there');
is ($set->has("bar"), 1, 'foo is still there');

is ($set->size(), 2, '2 elements');
ok (!$set->is_null(),  'set is not empty');
ok (!$set->is_empty(), 'set is not empty');

is ($set->insert( 'a' .. 'z'), 26, 'inserted 26');

is ($set->has("foo"), 1, 'foo is still there');

is ($set->size(), 28, '28 elements');
ok (!$set->is_null(),  'set is not empty');
ok (!$set->is_empty(), 'set is not empty');

#############################################################################
# delete()/remove()

is ($set->delete('bam'), 0, 'not found, none deleted');
is ($set->delete('foo'), 1, 'foo deleted');
is ($set->remove('foo'), 0, 'foo already deleted');

is ($set->size(), 27, '27 elements');
ok (!$set->is_null(),  'set is not empty');
ok (!$set->is_empty(), 'set is not empty');

is ($set->remove('a','a','b'), 2, 'a once, b once deleted');

#############################################################################
# new() with members

$set = Set::Light->new(qw/foo bar baz/);

is (ref($set), 'Set::Light', 'new did something');
is ($set->size(), 3, '3 elements');
ok (!$set->is_null(),  'set is not empty');

foreach my $key (qw/foo bar baz/)
  {
  is ($set->has($key), 1, "has $key");
  }

#############################################################################
# multiple insertions

is ($set->insert( 'a', 'a', 'a', 'a', 'a' ), 1, 'inserted once');

is ($set->size(), 4, '4 elements');
ok (!$set->is_null(),  'set is not empty');


