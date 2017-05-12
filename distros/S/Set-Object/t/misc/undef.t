#!/usr/bin/perl -w

use strict;
use Test::More qw(no_plan);
use Set::Object qw(set);

my $set = set();
$set->remove(undef);
pass("didn't segfault removing undef from an empty set");

$set->insert(undef);
is($set->size, 0, "set ignores undef as a member");

my $removed = $set->remove(undef);
is($removed, 0, "undef can never exist in a set");

is($set->includes(undef), '', "undef is never included in a set");
