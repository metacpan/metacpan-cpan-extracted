#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

evolution_ok "shuriken" => "shuriken";

evolution_not_ok "a +1 long sword" => "an uncursed carrot";
evolution_not_ok "a dagger" => "a short sword";
evolution_not_ok "a scroll of mail" => "a scroll of genocide";
evolution_not_ok "a sky blue potion" => "a purple-red potion";
evolution_not_ok "Excalibur" => "long sword";
evolution_not_ok "a wand of wishing (0:1)" => "a wand of wishing (0:2)";
evolution_not_ok "a wand of wishing (1:0)" => "a wand of wishing (0:3)";

done_testing;
