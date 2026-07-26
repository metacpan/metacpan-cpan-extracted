#!perl
use 5.008003;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Same::Boy;
use TestROM qw(minimal_rom);

plan tests => 6;

my $gb = Same::Boy->new(model => 'cgb', rom => \minimal_rom());

ok(!$gb->cheats_enabled, 'cheats disabled by default');

isa_ok($gb->set_cheats_enabled(1), 'Same::Boy', 'set_cheats_enabled chains');
ok($gb->cheats_enabled, 'cheats now enabled');

# GameShark code: 01DDAAAA (type 01, data DD, address AAAA).
ok($gb->import_cheat('0100C0DE', description => 'gameshark'),
    'import GameShark cheat');

# Game Genie code: AAA-BBB-CCC.
ok($gb->import_cheat('00A-17B-C49', description => 'gamegenie'),
    'import Game Genie cheat');

isa_ok($gb->remove_all_cheats, 'Same::Boy', 'remove_all_cheats chains');
