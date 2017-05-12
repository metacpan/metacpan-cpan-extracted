#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 20;

use NetHack::Monster::Spoiler;

my $archon = NetHack::Monster::Spoiler->lookup
    (glyph => 'A', color => 'magenta');

isa_ok($archon, 'NetHack::Monster::Spoiler', "Got an Archon spoiler");

is($archon->name, "Archon", "String property is set");

is($archon->wants_amulet, 0, "Archons do not want the Amulet");

is($archon->is_minion, 1, "but they are minions");


my $kobolds = NetHack::Monster::Spoiler->lookup(glyph => 'k');

ok(!defined($kobolds), "Scalar context k query fails (ambiguity)");

my $things = NetHack::Monster::Spoiler->lookup(glyph => '6');

ok(!defined($things), "Scalar context 6 query fails (nonexistance)");


my @kobolds = NetHack::Monster::Spoiler->lookup(glyph => 'k');

ok(@kobolds == 4, "Got 4 results from list context k query");

for my $k (0 .. 3) {
    isa_ok($kobolds[$k], 'NetHack::Monster::Spoiler',
        "And they're all spoilers");
    like($kobolds[$k]->name, qr/kobold/, "With kobold in the name");
    is($kobolds[$k]->glyph, 'k', "And k as a symbol");
}

@kobolds = sort { $a->name cmp $b->name } @kobolds;

is($kobolds[2]->color, "bright_blue", "Kobold shamans are bright blue");

