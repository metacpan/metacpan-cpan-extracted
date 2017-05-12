#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $spoiler = "NetHack::Item::Spoiler";
is($spoiler->pluralize("scroll of mail"), "scrolls of mail");
is($spoiler->singularize("scrolls of mail"), "scroll of mail");

is_deeply($spoiler->possibilities_for_appearance("scroll of mail"), ["scroll of mail"]);
is_deeply($spoiler->possibilities_for_appearance("scrolls of mail"), [], "need to singularize");

is_deeply([sort @{ $spoiler->possibilities_for_appearance("bag") }], [ sort("sack", "oilskin sack", "bag of holding", "bag of tricks")], "many identity -> one appearance");

is($spoiler->name_to_type("scroll of mail"), "scroll");
is($spoiler->name_to_type("stamped scroll"), "scroll");
is($spoiler->name_to_type("scroll of charging"), "scroll");
is($spoiler->name_to_type("scroll labeled KIRJE"), "scroll");
is($spoiler->name_to_type("scrolls of mail"), "scroll");

is($spoiler->name_to_type("cloak of magic resistance"), "armor");
is($spoiler->name_to_type("opera cloak"), "armor");
is($spoiler->name_to_type("opera cloaks"), undef);

is($spoiler->name_to_type("bag of holding"), "tool");
is($spoiler->name_to_type("bag"), "tool");

my $heart = $spoiler->spoiler_for("Heart of Ahriman");
ok($heart, "Heart spoiler");
ok($heart->{artifact}, "Heart is an artifact");
is($heart->{base}, "luckstone", "Heart's base item is a luckstone");

done_testing;
