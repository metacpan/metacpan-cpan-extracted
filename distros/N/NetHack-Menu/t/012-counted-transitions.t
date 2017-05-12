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
                     Weapons
                     a - 1A
                     b + 1B
                     c # 1C
                     d - 2A
                     e + 2B
                     f # 2C
                     g - 3A
                     h + 3B
                     i # 3C
                     j - 4A
                     k + 4B
                     l # 4C
                     (end)
MENU

ok($menu->has_menu, "we has a menu");

ok($menu->at_end, "it knows we're at the end here");

$menu->select_quantity(sub {
    /1[ABC]/ ? undef : /2[ABC]/ ? 0 : /3[ABC]/ ? 5 : 'all';
});

is($menu->commit, 'ef5g5h5ijll ', "menu commit handles all combinations");

done_testing;
