use strict;
use warnings;
use lib 't/lib';
use MockVT;

use Test::More;
use Test::Fatal;
use Test::Deep;

my $vt = MockVT->new;
my $menu = NetHack::Menu->new(vt => $vt);

$vt->return_rows((' ' x 80));
ok(!$menu->has_menu, "has_menu reports no menu");
like(exception { $menu->at_end }, qr/Unable to parse a menu/);

$vt->return_rows('(end) or is it?');
ok(!$menu->has_menu, "has_menu reports no menu");
like(exception { $menu->at_end }, qr/Unable to parse a menu/);

$vt->return_rows('(1 of 1) but we make sure to check for \s*$');
ok(!$menu->has_menu, "has_menu reports no menu");
like(exception { $menu->at_end }, qr/Unable to parse a menu/);

$vt->return_rows('            (-1 of 1)   ');
ok(!$menu->has_menu, "has_menu reports no menu");
like(exception { $menu->at_end }, qr/Unable to parse a menu/);

$vt->return_rows('            (0 of 1)');
ok(!$menu->has_menu, "has_menu reports no menu");
like(exception { $menu->at_end }, qr/Unable to parse a menu/);

$vt->return_rows('            (1 of 0)');
ok(!$menu->has_menu, "has_menu reports no menu");
like(exception { $menu->at_end }, qr/Unable to parse a menu/);

done_testing;

