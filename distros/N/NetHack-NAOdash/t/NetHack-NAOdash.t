#!/usr/bin/perl
use 5.014000;
use strict;
use warnings;

use Test::More tests => 4;

BEGIN { use_ok 'NetHack::NAOdash' }

open my $fh, '<', 't/xlogfile';
my @xlog = <$fh>;
close $fh;

is_deeply naodash_xlog (@xlog), {
	numbers => {
		ascensions => 15,
		games => 85,
		maxconducts => 4,
		maxhp => 422,
		maxpoints => 3429164,
		minrealtime => 43395,
		minturns => 36028,
		totalrealtime => 1483024,
	},

	checks => [qw/achieve_amulet achieve_ascended achieve_astral achieve_bell achieve_book achieve_candelabrum achieve_endgame achieve_gehennom achieve_invocation achieve_luckstone achieve_medusa achieve_sokoban combo_arc_dwa_law combo_bar_orc_cha combo_cav_gno_neu combo_hea_gno_neu combo_kni_hum_law combo_mon_hum_neu combo_pri_hum_law combo_pri_hum_neu combo_ran_elf_cha combo_rog_orc_cha combo_sam_hum_law combo_tou_hum_neu combo_val_dwa_law combo_wiz_elf_cha conduct_artiwishless conduct_atheist conduct_genocideless conduct_polypileless conduct_polyselfless conduct_vegetarian conduct_weaponless uconduct_boneless uconduct_survivor/]
}, 'naodash_xlog';

is_deeply naodash_xlog ({include_versions => ['3.6.0']}, @xlog), {
	numbers => {
		ascensions => 1,
		games => 3,
		maxconducts => 4,
		maxhp => 397,
		maxpoints => 2903014,
		minrealtime => 86482,
		minturns => 37729,
		totalrealtime => 114994,
	},

	checks => [qw/achieve_amulet achieve_ascended achieve_astral achieve_bell achieve_book achieve_candelabrum achieve_endgame achieve_gehennom achieve_invocation achieve_luckstone achieve_medusa achieve_sokoban combo_pri_hum_law conduct_atheist conduct_genocideless conduct_polypileless conduct_polyselfless uconduct_survivor/]
}, 'naodash_xlog';

is_deeply naodash_xlog ({exclude_versions => ['3.6.0']}, @xlog), {
	numbers => {
		ascensions => 14,
		games => 82,
		maxconducts => 4,
		maxhp => 422,
		maxpoints => 3429164,
		minrealtime => 43395,
		minturns => 36028,
		totalrealtime => 1368030,
	},

	checks => [qw/achieve_amulet achieve_ascended achieve_astral achieve_bell achieve_book achieve_candelabrum achieve_endgame achieve_gehennom achieve_invocation achieve_luckstone achieve_medusa achieve_sokoban combo_arc_dwa_law combo_bar_orc_cha combo_cav_gno_neu combo_hea_gno_neu combo_kni_hum_law combo_mon_hum_neu combo_pri_hum_neu combo_ran_elf_cha combo_rog_orc_cha combo_sam_hum_law combo_tou_hum_neu combo_val_dwa_law combo_wiz_elf_cha conduct_artiwishless conduct_genocideless conduct_polypileless conduct_polyselfless conduct_vegetarian conduct_weaponless uconduct_boneless uconduct_survivor/]
}, 'naodash_xlog';
