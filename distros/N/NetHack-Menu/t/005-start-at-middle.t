use strict;
use warnings;
use lib 't/lib';
use MockVT;

use Test::More;
use Test::Fatal;
use Test::Deep;

my $vt = MockVT->new;
my $menu = NetHack::Menu->new(vt => $vt);

$vt->return_rows(split /\n/, (<< 'MENU') x 3);
                     a - page 1
                     (3 of 4)
MENU

ok($menu->has_menu, "we has a menu");
$vt->checked_ok([0, 1, 2], "correct rows checked");

ok(!$menu->at_end, "it knows we're NOT at the end");
$vt->checked_ok([0, 1, 2, 0, 1], "rows 0-2 checked for finding the end, 0-1 checked for items");
is($menu->next, '>', "next page");
like($vt->next_return_row, qr/^\s*\(3 of 4\)\s*$/, "last row to be returned is our 'end of menu indicator");
is($vt->next_return_row, undef, "no more rows left");

$vt->return_rows(split /\n/, (<< 'MENU') x 2);
                     b - page 2
                     (4 of 4)
MENU

ok(!$menu->at_end, "it knows we're NOT at the end");
$vt->checked_ok([0, 1, 2, 0, 1], "rows 0-2 checked for finding the end, 0-1 checked for items");
is($menu->next, '^', "back to first page");
like($vt->next_return_row, qr/^\s*\(4 of 4\)\s*$/, "last row to be returned is our 'end of menu indicator");
is($vt->next_return_row, undef, "no more rows left");

$vt->return_rows(split /\n/, (<< 'MENU') x 2);
                     c - page 3
                     (1 of 4)
MENU

ok(!$menu->at_end, "it knows we're NOT at the end");
$vt->checked_ok([0, 1, 2, 0, 1], "rows 0-2 checked for finding the end, 0-1 checked for items");
is($menu->next, '>', "back to first page");
like($vt->next_return_row, qr/^\s*\(1 of 4\)\s*$/, "last row to be returned is our 'end of menu indicator");
is($vt->next_return_row, undef, "no more rows left");

$vt->return_rows(split /\n/, (<< 'MENU') x 2);
                     d - page 4
                     (2 of 4)
MENU

ok($menu->at_end, "NOW we're at the end");
$vt->checked_ok([0, 1, 2, 0, 1], "rows 0-2 checked for finding the end, 0-1 checked for items");
ok(exception { $menu->next }, "next dies if menu->at_end");

my @items;
$menu->select(sub {
    push @items, shift;
    /[23]/;
});

cmp_deeply(
    \@items,
    [
        methods(
            description          => "page 3",
            selector             => 'c',
            selected             => 1,
            quantity             => 'all',
            _originally_selected => 0,
            _original_quantity   => 0,
        ),
        methods(
            description          => "page 4",
            selector             => 'd',
            selected             => 0,
            quantity             => 0,
            _originally_selected => 0,
            _original_quantity   => 0,
        ),
        methods(
            description          => "page 1",
            selector             => 'a',
            selected             => 0,
            quantity             => 0,
            _originally_selected => 0,
            _original_quantity   => 0,
        ),
        methods(
            description          => "page 2",
            selector             => 'b',
            selected             => 1,
            quantity             => 'all',
            _originally_selected => 0,
            _original_quantity   => 0,
        ),
    ],
);


is($menu->commit, '^c>>>b ', "first page, select 1, fourth page, select 4, done");

done_testing;
