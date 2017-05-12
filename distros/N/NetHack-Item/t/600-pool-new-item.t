#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $pool = NetHack::ItemPool->new;
my $sword = $pool->new_item("a +1 long sword");

is($sword->identity, "long sword");
is($sword->enchantment, "+1");
ok($sword->has_pool,  "the sword has a pool");
is($sword->pool, $pool, "the sword gets the origin pool");

my $dagger = NetHack::Item->new("a dagger");
ok(!$dagger->has_pool, "the dagger has no pool");

done_testing;
