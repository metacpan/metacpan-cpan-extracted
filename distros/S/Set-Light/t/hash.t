#!/usr/bin/perl -w

# test the hash interface of Set::Light

use Test::More;
use strict;

BEGIN
  {
  chdir 't' if -d 't';		# for manual runs
  unshift @INC, '../lib';	# for manual runs
  plan tests => 29;
  use_ok ('Set::Light');
  }

#############################################################################
# new()

my $set = Set::Light->new();

is (ref($set), 'Set::Light', 'new did something');

#############################################################################
# has/contains/exists()

for my $method (qw/has exists contains/)
  {
  ok (!exists $set->{foo}, 'no foo');
  ok (!exists $set->{bar}, 'no bar');
  }

ok ($set->is_null(),  'set is empty');
ok ($set->is_empty(), 'set is empty');
is ($set->size(), 0, 'set is empty');

#############################################################################
# insert(), size()

is ($set->insert('foo'), 1, 'inserted one');
ok (exists $set->{foo}, 'was really inserted');
is ($set->insert('foo'), 0, 'inserted zero');
ok (exists $set->{foo}, 'was really inserted');

is ($set->insert('foo','bar'), 1, 'inserted bar');
ok (exists $set->{foo}, 'was really inserted');
ok (exists $set->{bar}, 'was really inserted');

is ($set->insert('foo','bar'), 0, 'inserted none');
ok (exists $set->{foo}, 'was really inserted');
ok (exists $set->{bar}, 'was really inserted');

is ($set->size(), 2, '2 elements');
ok (!$set->is_null(),  'set is not empty');
ok (!$set->is_empty(), 'set is not empty');

is ($set->insert( 'a' .. 'z'), 26, 'inserted 26');

ok (exists $set->{foo}, 'foo still there');

is ($set->size(), 28, '28 elements');
ok (!$set->is_null(),  'set is not empty');
ok (!$set->is_empty(), 'set is not empty');


