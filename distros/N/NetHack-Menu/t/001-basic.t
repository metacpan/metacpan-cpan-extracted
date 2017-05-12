use strict;
use warnings;
use lib 't/lib';
use MockVT;

use Test::More;
use Test::Fatal;
use Test::Deep;

my $vt = MockVT->new;
my $menu = NetHack::Menu->new(vt => $vt);

is($vt->checked_rows, 0, "No rows checked yet.");
$vt->return_rows(split /\n/, (<< 'MENU') x 3);
                     Weapons
                     a - a blessed +1 quarterstaff (weapon in hands)
                     Armor
                     X - an uncursed +0 cloak of magic resistance (being worn)
                     (end)
MENU

ok($menu->has_menu, "we has a menu");
$vt->checked_ok([0, 1, 2, 3, 4, 5], "rows 0-5 checked for finding the end");

ok($menu->at_end, "it knows we're at the end here");
$vt->checked_ok([0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4], "rows 0-5 checked for finding the end, 0-4 checked for items");

ok(exception { $menu->next }, "next dies if menu->at_end");
$vt->checked_ok([], "no rows checked");

my @items;
$menu->select(sub {
    push @items, shift;
    /quarterstaff/;
});

cmp_deeply(
    \@items,
    [
        methods(
            description          => "a blessed +1 quarterstaff (weapon in hands)",
            selector             => 'a',
            selected             => 1,
            quantity             => 'all',
            _originally_selected => 0,
            _original_quantity   => 0,
        ),
        methods(
            description          => "an uncursed +0 cloak of magic resistance (being worn)",
            selector             => 'X',
            selected             => 0,
            quantity             => 0,
            _originally_selected => 0,
            _original_quantity   => 0,
        ),
    ],
);

is($menu->commit, 'a ', "first page, selected the quarterstaff, ended the menu");

done_testing;
