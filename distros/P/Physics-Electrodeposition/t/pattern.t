#!/usr/bin/env perl
#
# pattern.t - tests for Physics::Electrodeposition::Pattern and the patterned
#             (through-mask) behaviour of the main model.
#
use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Physics::Electrodeposition::GDSII;
use Physics::Electrodeposition::Pattern;
use Physics::Electrodeposition;

use constant F => 96485.33212;

# helper to synthesise a uniform square-pad field at a chosen density
sub uniform_field {
    my ($cd, $pitch, $nx, $ny) = @_;
    my @polys;
    for my $i (0 .. $nx - 1) {
        for my $k (0 .. $ny - 1) {
            my $x = $i * $pitch; my $y = $k * $pitch;
            push @polys, { layer => 1,
                pts => [[$x,$y],[$x+$cd,$y],[$x+$cd,$y+$cd],[$x,$y+$cd]] };
        }
    }
    return \@polys;
}

my $tmp = "$RealBin/_pattern_tmp.gds";

#--- pattern density: 20 um pads on 40 um pitch -> ~0.25 open fraction ---------
Physics::Electrodeposition::GDSII->write_boundaries($tmp,
    uniform_field(20, 40, 25, 25));
my $pat = Physics::Electrodeposition::Pattern->new(file => $tmp, layer => 1, grid => 8);
is($pat->feature_count, 625, '25x25 = 625 openings');
my ($cdmin,$cdmean,$cdmax) = $pat->cd_stats;
ok(abs($cdmean - 20) < 1e-6, 'mean CD = 20 um');
# open fraction ~ (20/40)^2 = 0.25 (slightly higher due to tight bbox)
ok($pat->open_fraction > 0.24 && $pat->open_fraction < 0.28,
   'open fraction near 0.25 (got '.sprintf('%.3f',$pat->open_fraction).')');

#--- open area equals sum of pad areas ----------------------------------------
ok(abs($pat->open_area_um2 - 625 * 20 * 20) < 1e-3, 'open area = N * cd^2');

#--- uniform field has ~zero loading non-uniformity ---------------------------
ok($pat->loading_nonuniformity < 1.0, 'uniform field -> negligible loading NU');
ok(abs($pat->isolated_to_dense_ratio - 1.0) < 0.05, 'uniform -> iso/dense ~ 1');

#--- dense + sparse field has strong loading non-uniformity -------------------
my @mixed;
# dense block: 20um pads/40um pitch, 10x20
for my $i (0..9)  { for my $k (0..19) {
    my ($x,$y)=($i*40,$k*40);
    push @mixed,{layer=>1,pts=>[[$x,$y],[$x+20,$y],[$x+20,$y+20],[$x,$y+20]]}; } }
# sparse block: 20um pads/120um pitch, shifted right
for my $i (0..3)  { for my $k (0..5)  {
    my ($x,$y)=(1000+$i*120,$k*120);
    push @mixed,{layer=>1,pts=>[[$x,$y],[$x+20,$y],[$x+20,$y+20],[$x,$y+20]]}; } }
Physics::Electrodeposition::GDSII->write_boundaries($tmp, \@mixed);
my $pm = Physics::Electrodeposition::Pattern->new(file => $tmp, layer => 1, grid => 12);
ok($pm->loading_nonuniformity > 10, 'dense+sparse -> large loading NU');
ok($pm->isolated_to_dense_ratio > 1.5, 'isolated features plate thicker');

#--- layer filtering ----------------------------------------------------------
my @twolayer = (
    { layer => 1, pts => [[0,0],[10,0],[10,10],[0,10]] },
    { layer => 1, pts => [[20,0],[30,0],[30,10],[20,10]] },
    { layer => 5, pts => [[0,0],[100,0],[100,100],[0,100]] },  # big, other layer
);
Physics::Electrodeposition::GDSII->write_boundaries($tmp, \@twolayer);
my $pl = Physics::Electrodeposition::Pattern->new(file => $tmp, layer => 1);
is($pl->feature_count, 2, 'layer filter keeps only layer-1 openings');

#=============================================================================
# Integration with the plating model
#=============================================================================

# 10% open field, active current density basis
Physics::Electrodeposition::GDSII->write_boundaries($tmp,
    uniform_field(20, 63.2456, 30, 30));   # (20/63.25)^2 ~ 0.10
my $m = Physics::Electrodeposition->new(
    gdsii => $tmp, pattern_layer => 1,
    current_density => 10, current_density_basis => 'active',
    target_thickness => 30, efficiency => 1.0,
    wafer_diameter => 300,
);
ok($m->has_pattern, 'model detects the pattern');

# active density is the input; applied = active * open_fraction
ok(abs($m->j_active_mA - 10) < 1e-9, 'active density = specified 10 mA/cm^2');
ok(abs($m->j_applied_mA - 10 * $m->open_fraction) < 1e-6,
   'applied density = active * open_fraction');

# total current = applied * wafer area = active * active area (consistency)
ok(abs($m->current - $m->j_active * $m->active_area) < 1e-9,
   'I = j_active * active_area');
ok(abs($m->current - $m->j_applied * $m->wafer_area) < 1e-9,
   'I = j_applied * wafer_area');

# feature thickness solves to target; blanket-equivalent = feature * open_frac
ok(abs($m->film_thickness_um - 30) < 1e-6, 'feature thickness hits 30 um target');
ok(abs($m->blanket_equivalent_thickness_um
       - 30 * $m->open_fraction) < 1e-6, 'blanket-equiv = feature * open frac');

# Faraday mass check still holds on the TOTAL charge
my $m_exp = $m->charge * 1.0 * 63.546 / (2 * F);
ok(abs($m->mass_deposited - $m_exp) < 1e-6, 'Faraday mass from total charge');

# deposited volume = active area * feature thickness (self-consistent)
my $vol_cm3 = $m->active_area * ($m->film_thickness_um * 1e-4);
my $mass_from_vol = 8.96 * $vol_cm3;
ok(abs($m->mass_deposited - $mass_from_vol) < 1e-4,
   'mass = density * active_area * feature_thickness');

#--- 'applied' basis: active = applied / open_fraction ------------------------
my $ma = Physics::Electrodeposition->new(
    gdsii => $tmp, pattern_layer => 1,
    current_density => 2, current_density_basis => 'applied',
    target_thickness => 5,
);
ok(abs($ma->j_active_mA - 2 / $ma->open_fraction) < 1e-6,
   "applied basis: active = applied / open fraction");

#--- report contains the pattern section --------------------------------------
my $rep = $m->report;
like($rep, qr/PHOTORESIST PATTERN/, 'report has pattern section');
like($rep, qr/Pattern density/,     'report shows pattern density');
like($rep, qr/Loading \(pattern\) WIDNU/, 'report shows loading non-uniformity');

#--- no-pattern model is unchanged (open fraction = 1) ------------------------
my $blanket = Physics::Electrodeposition->new(current_density => 20, target_thickness => 1);
ok(abs($blanket->open_fraction - 1.0) < 1e-12, 'no pattern -> open fraction 1');
ok(abs($blanket->j_active - $blanket->j_applied) < 1e-12,
   'no pattern -> active == applied');
unlike($blanket->report, qr/PHOTORESIST PATTERN/, 'blanket report has no pattern section');

unlink $tmp;
done_testing();
