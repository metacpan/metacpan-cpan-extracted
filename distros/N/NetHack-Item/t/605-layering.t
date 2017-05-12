#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $pool = NetHack::ItemPool->new;
my $inv = $pool->inventory;

my $sword  = $pool->new_item("m - a +1 long sword (weapon in hand)");
my $amul   = $pool->new_item("k - an amulet of unchanging (being worn)");
my $gloves = $pool->new_item("x - a cursed +0 pair of leather gloves (being worn)");
my $lring  = $pool->new_item("l - a ring of regeneration (on left hand)");
my $comr   = $pool->new_item("g - a +3 cloak of magic resistance (being worn)");

for ($sword, $amul, $gloves, $lring, $comr) {
    $inv->update($_);
}

is_deeply([$inv->blockers('weapon')], [], "Nothing blocks a sword swap");
is_deeply([$inv->blockers('amulet')], [amulet => $amul],
    "Need to remove the amulet to wear a new one");
is_deeply([$inv->blockers('left_ring')], [left_ring => $lring],
    "We don't need to remove gloves to swap rings");
is_deeply([$inv->blockers('bodyarmor')], [cloak => $comr],
    "You can't wear armour without first removing the cloak");

ok($inv->under_cursed('left_ring'), "The left ring is blocked by cursed gloves");
ok($inv->under_cursed('gloves'), "We can't swap gloves with the cursed ones");
ok(!$inv->under_cursed('shirt'), "Nothing cursed stops us from wearing a shirt");

my $bigaxe = $pool->new_item("z - the cursed +7 Cleaver (weapon in hands)");
$inv->update($bigaxe);

is_deeply([$inv->blockers('shield')], [weapon => $bigaxe],
    "Need to remove 2hander to wear a shield");
is_deeply([$inv->blockers('bodyarmor')], [cloak => $comr],
    "We could wear armor without unwielding");

ok($inv->under_cursed('bodyarmor'), "but the curse stops us");
ok(!$inv->under_cursed('helmet'), "twohander doesn't stop helmet swaps");

my $order_met = 1;
my %slot_indexes = ();
my @slots = $inv->equipment->slots_inside_out;

for my $ix (0 .. $#slots) {
    $slot_indexes{$slots[$ix]} = $ix;
}

for my $slot (@slots) {
    my @block = $inv->blockers($slot);

    while (@block) {
        my ($bslot, $bitem) = splice @block, 0, 2;

        $order_met = 0 if $slot_indexes{$bslot} < $slot_indexes{$slot};
    }
}

ok($order_met, "Ordering rules for slots_inside_out are met");
done_testing;
