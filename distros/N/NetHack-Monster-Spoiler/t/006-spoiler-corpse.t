#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use NetHack::Monster::Spoiler;
use List::Util qw/sum/;

sub test_corpse {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($name, $expected_corpse) = @_;
    my $monster = NetHack::Monster::Spoiler->lookup($name, $name eq 'werewolf' ? (glyph => '@') : ());
    my $got_corpse = $monster->corpse;
    isa_ok($got_corpse, 'HASH');
    is_deeply($got_corpse, $expected_corpse, "correct corpse info for $name");
}

my %corpses = (
    kobold             => { poisonous         => 1 },
    newt               => { energy            => 1 },
    Death              => { die               => 1 },
    shopkeeper         => { cannibal          => 'Hum' },
    nurse              => { cannibal          => 'Hum',
                            heal              => 1 },
    raven              => { },
    tengu              => { poison_resistance => 1,
                            teleportitis      => 1,
                            teleport_control  => 1 },
    Medusa             => { petrify           => 1,
                            poisonous         => 1,
                            poison_resistance => 1 },
    'flesh golem'      => { fire_resistance   => 1,
                            cold_resistance   => 1,
                            sleep_resistance  => 1,
                            shock_resistance  => 1,
                            poison_resistance => 1 },
    'black pudding'    => { acidic            => 1,
                            cold_resistance   => 1,
                            shock_resistance  => 1,
                            poison_resistance => 1,
                            cure_stone        => 1 },
    abbot              => { cannibal          => 'Hum',
                            hallucination     => 200 },
    doppelganger       => { cannibal          => 'Hum',
                            polymorph         => 1 },
    'Lord Surtur'      => { strength          => 1,
                            fire_resistance   => 1 },
    'Chromatic Dragon' => { poisonous         => 1,
                            fire_resistance   => 1,
                            cold_resistance   => 1,
                            sleep_resistance  => 1,
                            shock_resistance  => 1,
                            poison_resistance => 1,
                            disintegration_resistance => 1 },
    cockatrice         => { petrify           => 1,
                            poison_resistance => 1 },
    Elvenking          => { cannibal          => 'Elf',
                            sleep_resistance  => 1 },
    'green slime'      => { slime             => 1,
                            poisonous         => 1,
                            acidic            => 1,
                            cure_stone        => 1 },
    leprechaun         => { teleportitis      => 1 },
    'mind flayer'      => { intelligence      => 1,
                            telepathy         => 1 },
    lizard             => { cure_stone        => 1,
                            less_confused     => 2,
                            less_stunned      => 2 },
    tengu              => { poison_resistance => 1,
                            teleportitis      => 1,
                            teleport_control  => 1 },
    'quantum mechanic' => { poisonous         => 1,
                            speed_toggle      => 1 },
    werewolf           => { cannibal          => 'Hum',
                            poisonous         => 1,
                            lycanthropy       => 1 },
    'Wizard of Yendor' => { cannibal          => 'Hum',
                            fire_resistance   => 1,
                            poison_resistance => 1,
                            teleportitis      => 1,
                            teleport_control  => 1 },
    woodchuck          => { },
);

Test::More::plan(tests => 2 * values %corpses);
test_corpse($_, $corpses{$_}) for keys %corpses;
