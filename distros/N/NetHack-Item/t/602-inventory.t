#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $pool = NetHack::ItemPool->new;
my $inv = $pool->inventory;

ok(!$inv->has_items, "no items yet");

my $sword = $pool->new_item("j - a +1 long sword");
ok(!$inv->get('j'), "items are not automatically added to inventory");
$inv->update($sword);
is($inv->get('j'), $sword, "intuited the slot as j");

my $new_sword = $pool->new_item("a +2 long sword");
$inv->set(j => $new_sword);
is($inv->get('j'), $new_sword, "new item in the slot");
is($sword->enchantment, '+1', 'the sword is not updated because it was manually replaced with a new item');

$inv->update($pool->new_item("j - a +3 long sword"));
is($inv->get('j'), $new_sword, "previous item in the slot");
is($new_sword->enchantment, '+3');

my $k_sword = $pool->new_item("k - a +5 long sword");
$inv->update($k_sword);
is($inv->get('j'), $new_sword, "previous item in the slot");
is($inv->get('k'), $k_sword, "new item in the new slot");
is($new_sword->enchantment, '+3', "didn't update the enchantment of the old item");

my $k_dagger = $pool->new_item("k - a +1 dagger");
is($inv->get('k'), $k_sword, "still the old item");

my $warn = '';
{
    local $SIG{__WARN__} = sub { $warn .= $_ for @_ };
    $inv->update($k_dagger);
}
is($inv->get('k'), $k_dagger, "new item in the new slot");
is($k_sword->enchantment, "+5", "didn't update the long sword");
like($warn, qr/^Displacing \[k - a \+5 long sword\] in slot k with \[k - a \+1 dagger\]\./, "got a proper warning message");

my $l_daggers = $pool->new_item("l - 3 elven daggers");
$inv->update($l_daggers);
#simulate picking up 3 more elven daggers to the l slot
my $more_l_daggers = $pool->new_item("l - 3 elven daggers");
$inv->add($more_l_daggers);
is($inv->get('l')->quantity, 6, "we should now have 6 elven daggers");
my $yet_more_l_daggers = $pool->new_item("l - 3 daggers");
$warn = '';
{
    local $SIG{__WARN__} = sub { $warn .= $_ for @_ };
    $inv->add($yet_more_l_daggers);
}
is($inv->get('l')->quantity, 3, "if the item is different, the quantity should be replaced");
like($warn, qr/^Displacing \[l - 3 elven daggers\] in slot l with \[l - 3 daggers\]\./, "got a proper warning message");

my $m_quarterstaff = $pool->new_item("m - a +1 quarterstaff");
$inv->add($m_quarterstaff);
is($inv->get('m')->quantity, 1, "only a single quarterstaff");
my $m_other_quarterstaff = $pool->new_item("m - a +1 quarterstaff");
$inv->add($m_other_quarterstaff);
is($inv->get('m')->quantity, 1, "quarterstaves don't stack");

my $n_dart = $pool->new_item("n - a +2 dart");
$inv->add($n_dart);
is($inv->get('n')->quantity, 1, "we added only a single dart to our inventory");
done_testing;
