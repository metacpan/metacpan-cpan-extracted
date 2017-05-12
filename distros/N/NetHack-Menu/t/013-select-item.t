use strict;
use warnings;
use lib 't/lib';
use MockVT;

use Test::More;
use Test::Fatal;
use Test::Deep;

my $vt = MockVT->new;
my $menu = NetHack::Menu->new(vt => $vt, select_count => 'single');

$vt->return_rows(split /\n/, (<< 'MENU') x 3);
                     Weapons
                     a - a blessed +1 quarterstaff (weapon in hands)
                     Armor
                     X - an uncursed +0 cloak of magic resistance (being worn)
                     (1 of 2)
MENU

ok($menu->has_menu, "we has a menu");
$vt->checked_ok([0, 1, 2, 3, 4, 5], "rows 0-5 checked for finding the end");

ok(!$menu->at_end, "it knows we're NOT at the end");
$vt->checked_ok([0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4], "rows 0-5 checked for finding the end, 0-4 checked for items");
is($menu->next, '>', "next page");
like($vt->next_return_row, qr/^\s*\(1 of 2\)\s*$/, "last row to be returned is our 'end of menu indicator");
is($vt->next_return_row, undef, "no more rows left");

$vt->return_rows(split /\n/, (<< 'MENU') x 2);
                     Wands
                     c - a wand of enlightenment (0:12)
                     Tools
                     n - a magic marker (0:91)
                     (2 of 2)
MENU

ok($menu->at_end, "NOW we're at the end");
$vt->checked_ok([0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4], "rows 0-5 checked for finding the end, 0-4 checked for items");
ok(exception { $menu->next }, "next dies if menu->at_end");

for my $item ($menu->all_items) {
    if ($item->description =~ /marker/) {
        $item->selected(1);
    }
}

is($menu->commit, '^>n', "select the last thing on the last page, which exits the menu");

done_testing;

