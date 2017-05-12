#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $bot = NetHack::Item->new("a bag of tricks (0:1)");

is($bot->chance_to_recharge, 100, "Chance to recharge new bag of tricks");

# use it once..
is($bot->spend_charge, 0, "Spent a charge");

# recharge a few times
ok($bot->recharge, "Can recharge bag of tricks");
$bot->recharge;
$bot->recharge;

# now check chance to rechage again
is($bot->chance_to_recharge, 100, "Can always recharge bag of tricks");

my $wow = NetHack::Item->new("a wand of wishing (0:2)");

is($wow->chance_to_recharge, 100, "Can recharge /oW first time..");

ok($wow->spend_charge, "Make a wish!");
$wow->spend_charge;

ok($wow->recharge, "Recharging /oW first time");

is($wow->chance_to_recharge, 0, "Cannot recharge a second time");
done_testing;
