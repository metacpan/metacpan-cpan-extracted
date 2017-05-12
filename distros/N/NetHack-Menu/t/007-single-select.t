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

my @items;
$menu->select(sub {
    push @items, shift;
    /./;
});

cmp_deeply(
    \@items,
    [
        methods(
            description          => "a blessed +1 quarterstaff (weapon in hands)",
            selector             => 'a',
            _originally_selected => 0,
            _original_quantity   => 0,
        ),
        methods(
            description          => "an uncursed +0 cloak of magic resistance (being worn)",
            selector             => 'X',
            _originally_selected => 0,
            _original_quantity   => 0,
        ),
        methods(
            description          => "a wand of enlightenment (0:12)",
            selector             => 'c',
            _originally_selected => 0,
            _original_quantity   => 0,
        ),
        methods(
            description          => "a magic marker (0:91)",
            selector             => 'n',
            _originally_selected => 0,
            _original_quantity   => 0,
        ),
    ],
);

is($menu->commit, '^a', "select the first thing on the first page, which exits the menu");

done_testing;
