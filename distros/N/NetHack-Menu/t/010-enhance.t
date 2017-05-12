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
 Pick a skill to advance:

 Fighting Skills
       bare handed combat [Unskilled]
       riding             [Unskilled]
 Weapon Skills
       dagger             [Unskilled]
       knife              [Unskilled]
       axe                [Unskilled]
       short sword        [Unskilled]
       club               [Unskilled]
       mace               [Unskilled]
 a -   quarterstaff       [Basic]
       polearms           [Unskilled]
       spear              [Unskilled]
       javelin            [Unskilled]
       trident            [Unskilled]
       sling              [Unskilled]
       dart               [Unskilled]
       shuriken           [Unskilled]
 Spellcasting Skills
       attack spells      [Basic]
       healing spells     [Unskilled]
 (1 of 2)
MENU

ok($menu->has_menu, "we has a menu");
$vt->checked_ok([0..24], "rows 0-23 checked for finding the end");

ok(!$menu->at_end, "it knows we're NOT at the end");
$vt->checked_ok([0..24, 0..23], "rows 0-5 checked for finding the end, 0-4 checked for items");
is($menu->next, '>', "next page");
like($vt->next_return_row, qr/^\s*\(1 of 2\)\s*$/, "last row to be returned is our 'end of menu indicator");
is($vt->next_return_row, undef, "no more rows left");

$vt->return_rows(split /\n/, (<< 'MENU') x 2);
       divination spells  [Unskilled]
       enchantment spells [Basic]
       clerical spells    [Unskilled]
       escape spells      [Unskilled]
       matter spells      [Unskilled]
 (2 of 2)
MENU

ok($menu->at_end, "NOW we're at the end");
$vt->checked_ok([0..6, 0..5], "rows 0-5 checked for finding the end, 0-4 checked for items");
ok(exception { $menu->next }, "next dies if menu->at_end");

my @items;
$menu->select(sub {
    push @items, shift;
    1;
});

cmp_deeply(
    \@items,
    [
        methods(
            description          => "  quarterstaff       [Basic]",
            selector             => 'a',
            selected             => 1,
            quantity             => 'all',
            _originally_selected => 0,
            _original_quantity   => 0,
        ),
    ],
);

is_deeply(
    [ $menu->extra_rows ],
    [
        '',
        ' Pick a skill to advance:',
        '',
        ' Fighting Skills',
        '       bare handed combat [Unskilled]',
        '       riding             [Unskilled]',
        ' Weapon Skills',
        '       dagger             [Unskilled]',
        '       knife              [Unskilled]',
        '       axe                [Unskilled]',
        '       short sword        [Unskilled]',
        '       club               [Unskilled]',
        '       mace               [Unskilled]',
        '       polearms           [Unskilled]',
        '       spear              [Unskilled]',
        '       javelin            [Unskilled]',
        '       trident            [Unskilled]',
        '       sling              [Unskilled]',
        '       dart               [Unskilled]',
        '       shuriken           [Unskilled]',
        ' Spellcasting Skills',
        '       attack spells      [Basic]',
        '       healing spells     [Unskilled]',
        '',
        '       divination spells  [Unskilled]',
        '       enchantment spells [Basic]',
        '       clerical spells    [Unskilled]',
        '       escape spells      [Unskilled]',
        '       matter spells      [Unskilled]',
    ],
);

is($menu->commit, '^a', "select the first thing on the first page, which exits the menu");

done_testing;
