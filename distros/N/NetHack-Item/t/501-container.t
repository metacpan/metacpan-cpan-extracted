#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $bag = NetHack::Item->new("a bag");
is($bag->type, 'tool', "bags are tools");
is($bag->subtype, undef, "plain bags are not necessarily containers; could be tricks");

my $sack = NetHack::Item->new("a sack");
is($sack->type, 'tool', "sacks are tools");
is($sack->subtype, 'container', "sacks are containers");
is_deeply($sack->contents, [], "no known contents yet");
ok(!$sack->contents_known, "we don't know what's in the sack yet");

is($bag->container, undef, "no container yet");

$sack->add_item($bag);
is_deeply($sack->contents, [$bag], "what contents we know so far");
ok(!$sack->contents_known, "even if we add an item, we don't know the contents yet");

is($bag->container, $sack, "the bag is in the sack");

$sack->add_item($bag);
is_deeply($sack->contents, [$bag], "the bag is already in the sack");

$sack->remove_item($bag);
is_deeply($sack->contents, [], "the bag was removed from the bag");
is($bag->container, undef, "no container for the bag any more");

my $holy_water = NetHack::Item->new("50 potions of holy water");
$sack->add_item($holy_water);

is_deeply($sack->contents, [$holy_water], "we have holy water in the sack");
is($holy_water->container, $sack, "holy water is still in the sack");

my $tenner = $sack->remove_quantity($holy_water, 10);
is($tenner->quantity, 10);
is($holy_water->quantity, 40);

is_deeply($sack->contents, [$holy_water], "we still have holy water in the sack");
is($holy_water->container, $sack, "holy water is still in the sack");
is($tenner->container, undef, "the forked quantity is not in the sack");

my $forty = $sack->remove_quantity($holy_water, 40);
is($tenner->quantity, 10);
is($forty, $holy_water);

is_deeply($sack->contents, [], "nothing left in the sack");
is($holy_water->container, undef, "holy water is not in the sack");
is($tenner->container, undef, "the forked quantity is not in the sack");

done_testing;
