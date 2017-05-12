#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 134;

use NetHack::Monster::Spoiler;

sub mon {
    my $m = shift;

    $m =~ s/_/ /g;

    NetHack::Monster::Spoiler->lookup(name => $m, #hack to avoid ambiguity
           ($m eq 'werewolf' ? (glyph => '@') : ())) ||
        die "Cannot lookup $m";  # Should this count as a test?
}

sub test_pred {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($pred, $will, $wont) = @_;

    for my $m (@$will) {
        ok(mon($m)->$pred(), "$m satisfies $pred");
    }

    for my $m (@$wont) {
        ok(!mon($m)->$pred(), "$m does not satisfy $pred");
    }
}

# A couple of simple flags

test_pred poisonous_corpse => ['kobold'], ['floating eye'];

test_pred lacks_eyes => ['acid blob'], ['gnome king'];

# Things subject to the propagator

test_pred wants_candelabrum => [qw/Wizard_of_Yendor Vlad_the_Impaler/],
    [qw/Dark_One/];

test_pred can_eat_rock => [qw/rock_mole/], [qw/dwarf gnome/];

test_pred is_amphibious => [qw/xorn crocodile/], [qw/human/];

test_pred hides_on_ceiling => [qw/lurker_above/], [qw/small_mimic warhorse/];

test_pred is_carnivorous => [qw/dwarf kitten/], [qw/abbot/];

# Compound predicates

test_pred is_rider => [qw/Death Pestilence Famine/], [qw/kitten/];

test_pred ignores_elbereth => [qw/Grey-elf Archon minotaur Death/],
    [qw/water_moccasin/];

test_pred is_spellcaster => [qw/Master_Kaen apprentice/], [qw/minotaur/];

test_pred can_float => [qw/gas_spore/], [qw/bat/];

test_pred is_noncorporeal => [qw/shade ghost/], [qw/xorn/];

test_pred is_whirly => [qw/fire_vortex air_elemental/], [qw/water_elemental/];

test_pred is_flaming => [qw/fire_vortex fire_elemental flaming_sphere/,
    qw/salamander/], [qw/red_dragon/];

test_pred is_telepathic => [qw/floating_eye mind_flayer master_mind_flayer/],
    [qw/orc/];

test_pred uses_weapons => [qw/gnome barrow_wight/], [qw/wraith/];

test_pred is_unicorn => [qw/white_unicorn black_unicorn gray_unicorn/],
    [qw/pony Cyclops/];

test_pred is_bat => [qw/bat giant_bat vampire_bat/], [qw/vampire raven/];

test_pred is_golem => [qw/iron_golem/], [qw/skeleton/];

test_pred is_verysmall => [qw/sewer_rat/], [qw/human/];

test_pred is_bigmonst => [qw/black_dragon/], [qw/Oracle/];

test_pred could_wield => [qw/arch-lich captain/], [qw/wolf/];

test_pred could_wear_armor => [qw/master_mind_flayer elf/],
    [qw/silver_dragon/];

test_pred can_dualwield => [qw/marilith/], [qw/gnome/];

test_pred is_normal_demon => [qw/succubus/], [qw/Baalzebub orc/];

test_pred is_demon_lord => [qw/Juiblex Yeenoghu/], [qw/Orcus orc/];

test_pred is_demon_prince => [qw/Orcus/], [qw/Juiblex orc/];

test_pred makes_webs => [qw/giant_spider cave_spider/], [qw/Scorpius/];

test_pred can_breathe => [qw/red_naga/], [qw/baby_gray_dragon/];

test_pred is_player_monster => [qw/priest priestess caveman wizard/],
    [qw/aligned_priest elf/];

test_pred resists_blinding => [qw/Archon yellow_light fog_cloud/], [qw/raven/];

test_pred is_vulnerable_to_silver => [qw/werewolf vampire nalfeshnee/],
    [qw/human wraith lich/];

test_pred ignores_bars => [qw/xorn acid_blob air_elemental sewer_rat
    pit_viper/], [qw/red_naga human/];

test_pred would_slip_armor => [qw/fog_cloud ghost sewer_rat/], [qw/human/];

test_pred would_break_armor => [qw/python winged_gargoyle marilith troll/],
    [qw/human fog_cloud/];

test_pred can_stick => [qw/owlbear electric_eel giant_mimic/], [qw/ghoul/];

test_pred has_horns => [qw/horned_devil minotaur Asmodeus balrog ki-rin
    white_unicorn/], [qw/human/];

