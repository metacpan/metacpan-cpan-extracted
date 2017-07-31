package Physics::Ballistics::Terminal;
use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(anderson boxes heat_dop ke me2te me2ce me2cem odermatt pc pc_simple hits_score sigma average rndto r2d d2r poncelet te2me lethality hv2bhn bhn2hv hrc2bhn bhn2hrc psi2bhn bhn2psi);
our $VERSION = '1.03';

use Physics::Ballistics;
use Math::Trig;

=head1 NAME

Physics::Ballistics::Terminal -- Terminal ballistics formulae.

=cut

=head1 ABSTRACT

Terminal ballistics is the study of what happens when a projectile impacts
its target.  This module implements a variety of functions and mathematical
formulae useful in the analysis and prediction of terminal ballistic effects.

=head1 TWO DOMAINS OF VELOCITY

Some of these functions pertain to the "ballistic" domain, and others pertain
to the "hypervelocity" domain.  These refer to two different and somewhat
ill-defined ranges of velocity.  "Ballistic" velocity ranges from about 300
to 1100 meters per second, while "Hypervelocity" ranges from about 1100 meters
per second to several tens of thousands of meters per second.

Why does this matter?  Because successful models of ballistic interactions
are not accurate in the hypervelocity domain, and successful models of
hypervelocty interactions are not accurate in the ballistic domain.  Thus it
is crucial to use the model which is valid for the velocity of interaction
you are attempting to predict.

Functions which are only valid in one domain or the other will be thus marked.

=head1 REGARDING BULLET DIAMETERS

Some of these functions require the diameter of a projectile as a parameter.
Please note that bullet diameters are usually different from the names of
their calibers.  NATO 5.56mm bullets are actually 5.70mm in diameter, while
Russian 5.45mm bullets are actually 5.62mm.  .308 caliber bullets really are
0.308 inches in diameter (7.82mm), but .22 Long Rifle bullets are 0.222
inches across.  Please do not make assumptions; check before plugging it in!

=head1 DEFINITIONS

=head2 DU

DU is short for "Depleted Uranium".  This denotes any of a number of metallic
alloys containing a high fraction of Uranium, the most common of which is
99.25% Uranium and and 0.75% Titanium.  This material is extremely dense and
hard, and somewhat ductile, making it excellent for armor-piercing projectiles.
Contrary to popular myth, DU projectiles are not "nuclear" and do not explode,
though in the hypervelocity domain they can be pyrophoric.  Nor is DU highly
radioactive.  It is, however, a heavy metal (like lead, mercury, and arsenic)
and therefore toxic.

=head2 MILD STEEL

There are many thousands of steel formulations and treatments, resulting in
myriad different strengths and hardnesses.  "Mild Steel" is a general term
for any of a number of inexpensive steels of moderate to low strength and
hardness.  The steels used in rebar, trench plates, automotive bodies, and
other commodity and construction applications tend to be of this type.  Mild
steels are an inferior material for armor, providing only about 80% of the
protection as an equivalent thickness of RHA.  Mild steel is often used in
military projectile cores (as in America's 7.62mm M80 "Ball") because it is
cheap and much more ductile than hardened steels.  This ductility makes it
less likely to fracture while penetrating its target (whether the target is
made of flesh or harder stuff).

=head2 RHA

RHA is short for "Rolled Homogenous Armor".  It is a commonly-used term for
hardened steel armor material in general, or for armor steel which complies
with the military specification MIL-A-12560.  RHA is also a common standard
material for normalizing depth of penetration.  It is roughly equivalent to
AISI 4340 steel in character, and AISI 4340 is often used in lieu of "real"
RHA in laboratory experiments.

Unless otherwise noted, return values representing a depth of penetration
should be understood to represent depth of penetration into an RHA target.
It is common for armor systems to represent their resistance to penetration
in terms of RHA thickness.

=head2 WC

WC is short for "Tungsten Carbide".  This is a technical ceramic of tungsten
and carbon, a dense and hard material of relatively low expense.  WC has seen 
prolific use in armor-piercing projectiles because high density and hardness 
are both desirable qualities in that role.  Being a ceramic, however, it is 
also brittle, and thus vulnerable to modern composite armors, which use
synergistic effects to break up projectiles and thus degrade their penetration
capabilities.  Thus, WC penetrators are less capable of penetrating composite
armor systems than indicated by their RHA equivalence ratings (since their
brittleness plays less of a role in limiting their penetration into monolithic
steel targets).

=head2 WHA

WHA is short for "Tungsten-Heavy Alloy".  This denotes any of several metallic
alloys containing a high fraction of Tungsten.  Some formulations offer high
density, hardness and resilience (such as 90% W / 7% Ni / 3% Fe) making them
excellent materials for armor-piercing projectiles.  Unlike WC, appropriate WHA
formulations are not brittle, and are unlikely to break from passing through
composite armor systems.

=head1 ANNOTATIONS OF SOURCES

Regarding their source, these functions fall into three categories:  Some are
simple encodings of basic physics (like energy = 1/2 * mass * velocity**2),
and these will not be cited.  Others are from published works, such as books
or trade journals, and these will be cited when possible.  A few are products
of my own efforts, and will be thus annotated.

=head1 OOP INTERFACE

A more integrated, object-oriented interface for these functions is under
development.

=head1 FUNCTIONS

=head2 anderson (length_cm, diam_cm, vel_kps, [penetrator_material,] [deg_angle,] [scaling_factor])

Attempts to estimate how deeply a long-rod projectile will penetrate into RHA (semi-infinite penetration).

This function is based on Anderson's _Accuracy of Perforation Equations_, less 11% correction per that paper's conclusions, and including adjustments from Lakowski for scale, material, and backsurface effects.
qv: L<http://www.tank-net.com/forums/index.php?showtopic=10482&&page=7>

ONLY VALID IN HYPERVELOCITY DOMAIN.

=over 4

parameter: (float) penetrator length (in cm)

parameter: (float) penetrator diameter (in cm)

parameter: (float) penetrator velocity (in kilometers per second)

parameter: (float or string) OPTIONAL: penetrator material or material multiplier.  (defaults to 1.0)  Valid values are:

=over 4

* an integer, for custom material factors

* "steel": Hardened steel == 0.50

* "wha": Tungsten-heavy alloy (NOT tungsten carbide) == 1.00

* "wc": Tungsten Carbide == 0.72

* "du":  Depleted uranium alloy == 1.13

=back

parameter: (float) OPTIONAL: angle of impact, 0 == perpendicular to target surface (in degrees, defaults to 0)

parameter: (float) OPTIONAL: scaling effect, relative to M829A2 dimensions (unitless, defaults to 1.0)

returns: (float) Depth of penetration (in cm)

=back

=cut

# Given attributes of a hypervelocity-domain long-rod penetrator, returns penetration into RHA, in cm.
# Based on Anderson TN, from _Accuracy of Perforation Equations_, less 11% correction per that paper's conclusions, and including adjustments from Lakowski for scale, material, and backsurface effects, qv: http://tank-net.com/forums/index.php?showtopic=8332&pid=156211&mode=threaded&show=&st=& and http://63.99.108.76/forums/index.php?showtopic=10482&st=100
# NOTE: only valid in hypervelocity domain, above 1100 meters/second.
sub anderson {
    my ($len, $diam, $vel, $material, $deg_angle, $scaling) = @_;
    die("usage: pen_cm = anderson(length_cm, diam_cm, vel_kps, material, [ deg_angle ]") unless (defined($len) && defined($vel));
    $scaling  = 1.0 unless (defined($scaling));
    $material = 1.0 unless (defined($material));   # 1.00 = WHA
    $material = lc($material);
    $material = 1.00 if ($material eq 'wha');  # Tungsten Heavy Alloy
    $material = 1.13 if ($material eq 'du');   # Depleted Uranium / Titanium Alloy
    $material = 1.20 if ($material eq 'duv');  # Depleted Uranium / Vanadium Alloy
    $material = 0.72 if ($material eq 'wc');   # Tungsten Carbide
    $material = 0.50 if ($material eq 'steel');
    $material = 0.50 if ($material =~ /[^\d\.]/);
    $deg_angle = 0 unless (defined($deg_angle));
    my $angle        = pi * $deg_angle / 180;    # convert degrees to radians
    my $log1         = log($len / $diam);
    my $baseline     = (1.044 * $vel) - (0.194 * log($len / $diam)) - 0.212;
    my $scale_effect = 1 + ($diam / (13 * $scaling));
    my $backsurface  = $diam / cos($angle);
    my $base_pen     = $baseline * $scale_effect * $len;
    my $penetration  = $base_pen * $material;
    $penetration = $penetration + $backsurface;
    $penetration = $penetration * .89;           # less 11% -- Anderson's own analysis concluded that this formula overpredicts penetration by about this much
    $penetration = int($penetration * 10 + 0.5) / 10;
    return $penetration;
}

=head2 boxes (length, width, height, front thickness, back thickness, side thickness, top thickness, underside thickness, density)

Calculates the volumes, mass, and volume-to-mass ratio of a hollow box of rectangular cross-sections.

=over 4

parameter: (float) interior distance from front to back (in cm)

parameter: (float) interior distance from left to right (in cm)

parameter: (float) interior distance from top to bottom (in cm)

parameter: (float) thickness of front wall (in cm)

parameter: (float) thickness of back wall (in cm)

parameter: (float) thickness of side walls (in cm)

parameter: (float) thickness of bottom wall (in cm)

parameter: (float) specific density of wall material (g/cc)

returns:

=over 4

* (float) interior volume (in cc)

* (float) exterior volume (in cc)

* (float) total wall mass (in grams)

* (float) ratio of interior volume to mass (cc/g)

=back

=back

=cut

sub boxes { # params: length, width, height, thick / front, back, side, top, bottom, den
    my ($inx, $iny, $inz, $tf, $tb, $ts, $tt, $tu, $den) = @_;
    die("usage: boxes ( interior_x_cm, int_y, int_z, thickness_front_cm, thick_back, thick_side, thick_top, density ) = string") unless ( defined($inx) );
    my ($inv, $ouv, $vdiff, $mass, $retval, $lbs, $rat);
    $inv     = $inx * $iny * $inz;
    $ouv     = ($inx + $tf + $tb) * ($iny + 2 * $ts) * ($inz + $tt + $tu);
    $vdiff   = $ouv - $inv;
    $mass    = $vdiff * $den;
    $rat     = int($inv * 100 / $mass) / 100;
    # returns: interior volume in cc, exterior volume, difference between interior and exterior volumes,
    # mass in grams, mass in pounds, and ratio of interior volume to mass (cc/g)
    return ($inv, $ouv, $mass, $rat);
}

=head2 heat_dop(diameter_mm, standoff_distance, [target_density,] [precision_bool], [target_hardness_bhn])

Attempts to predict the depth of penetration of a copper-lined conical shaped charge into steel.

Based on Ogorkiewicz's book, _Design and Development of Fighting Vehicles_, and
modified as per _Journal of Battlefield Technology_ Vol 1-1 pp 1.  A copy of 
the JBT chart may be found at:

L<http://ciar.org/ttk/mbt/news/news.smm.ww2-armor-plate.de5bf54f.0110271532.871cbf@posting.google.com.txt>

The author has modified this formula slightly to account for errors observed in
Ogorkiewicz's results, relative to empirically derived results.

For better understanding of shaped charge penetration, please review:

L<http://www.globalsecurity.org/military/systems/munitions/bullets2-shaped-charge.htm>

=over 4

parameter: (float) cone diameter (in mm)

parameter: (float or str) standoff distance (multiple of cone diameter if float, else in mm, for instance "80.5mm")

parameter: (float) OPTIONAL: density of target material (in g/cc, default is 7.86, the density of RHA)

parameter: (boolean) OPTIONAL: assume precision shaped charge (default is False)

parameter: (float) OPTIONAL: hardness of target material (in BHN, default is 300, low in the range of RHA hardnesses)

returns: (int) depth of penetration (in mm)

=back

=cut

# Copper-lined shaped charge depth of penetration, lifted from Ogorkiewicz's _Design and Development of Fighting Vehicles_, and modified as per _Journal of Battlefield Technology_ Vol 1-1 pp 1, copy of chart from that article can be found at: http://ciar.org/ttk/mbt/news/news.smm.ww2-armor-plate.de5bf54f.0110271532.871cbf@posting.google.com.txt
# NOTE: does not take into account any advanced effects from composited targets.
# NOTE: removed jet density parameter from argument list because liner ductility effects eclipse liner density in practice, and I don't want to factor liner ductility into this code right now. (eg: according to Ogorkiewicz, a steel liner would increase penetration, but in practice steel liners reduce penetration due to their relatively low ductility.)
# NOTE: Ogorkiewicz's curve for nonprecision charges was a little low at optimal standoff and high elsewhere relative to the _JoBT_ article chart, so I split the difference.  I suspect his precision charge curve is similarly a bit optimistic in favor of higher penetration, so take it with a grain of salt.
sub heat_dop {
    my ($diam, $soff, $aden, $prec, $hard) = @_;
    my $jden;
    my $pen = 0;
    die("usage: heat_dop (diameter_mm, standoff[mm], [targ-den], [precision], [hard])\nDiameter units is mm\nstandoff assumed cd's unless 'mm' is specified\ntarget density default is 7.86 (RHA)\nprecision default is 0 (non-precision), 1 for high precision\nhardness is BHN, default is 300 (ignore if not steel)\nReturns depth of penetration in mm") unless (defined ($soff));
    $aden //= 7.86;
    $jden //= 8.96;
    $prec //= 0;
    $hard //= 300;
    # print ("  aden=$aden jden=$jden prec=$prec hard=$hard\n");
    my $MIN_DENSITY = 0.00000000001;
    $aden = $MIN_DENSITY if ($aden < $MIN_DENSITY); # avoid divide-by-zero error
    if ($soff =~ /(\d+)mm/) { $soff = $1 / $diam; } # normalize to factor of cone diameters
    # $soff *= ($hard / 300)**0.5; # I'm guessing here -- target hardness does appear to shift optimal standoff, but effects of nonoptimal standoff not quite proportional to this relation. -- zzapp, figure this out.
    if ($prec) {
        # precision shaped charge DoP curve looks something like this:
        if    ($soff <=  1) { $pen = 3.0 + 1.500 * ($soff - 0); }
        elsif ($soff <=  3) { $pen = 4.5 + 0.350 * ($soff - 1); }
        elsif ($soff <=  6) { $pen = 5.2 + 0.100 * ($soff - 3); }
        elsif ($soff <=  9) { $pen = 5.5 - 0.033 * ($soff - 6); }
        else                { $pen = 5.4 - (($soff - 9) / 4.117); }
    }
    else {
        # nonprecision shaped charge DoP curve looks something like this:
        if    ($soff <=  1) { $pen = 3.00 + 1.200 * ($soff - 0); }
        elsif ($soff <=  2) { $pen = 4.20 + 0.150 * ($soff - 1); }
        elsif ($soff <=  3) { $pen = 4.35 - 0.150 * ($soff - 2); }
        elsif ($soff <=  4) { $pen = 4.20 - 0.400 * ($soff - 3); }
        elsif ($soff <=  7) { $pen = 4.00 - 0.550 * ($soff - 4); }
        elsif ($soff <= 10) { $pen = 2.35 - 0.170 * ($soff - 7); }
        else                { $pen = 1.84 - (($soff - 10) / 7.95); }
    }
    $pen *= (($jden / $aden) / (8.96 / 7.86))**0.5;
    $pen *= $diam;
    # round off, this is *not* any kind of precise estimate!
    $pen = int($pen + 0.5);
    return $pen; # returns millimeters
}

# ke: removed: use P::B::E::muzzle_energy() instead

=head2 me2te (mass_efficiency, density)

Given the mass efficiency of a material, returns its thickness efficiency.

This function is used when comparing armor materials on the basis of their RHA
equivalence.  Mass efficiency is a factor of how much armor mass than RHA mass 
provides the same resistance to penetration.  Conversely, thickness efficiency
is a factor of how much less armor thickness than RHA thickness provides the
same resistance to penetration.

For instance, if an armor material has a mass efficiency of 4.0, then only a
quarter as much mass is needed to provide a given protection level compared to
RHA of equivalent protection.  A pound of the armor material provides the same 
protection as four pounds of RHA.

Similarly, if an armor material has a thickness efficiency of 3.0, then only a
third as much thickness is needed to provide a given protection level compared
to RHA of equivalent protection.  An inch of the armor material provides the
same protection as three inches of RHA.

If the density of the armor material is known, me2te() and te2me() may be used
to convert back and forth between mass efficiency or thickness efficiency,
depending on which is known.

=over 4

parameter: (float) armor material mass efficiency (unitless, factor relative to RHA)

parameter: (float) armor material density (g/cc)

returns: (float) armor material thickness efficiency (unitless, factor relative to RHA)

=back

=cut

sub me2te { # given mass efficiency and density, returns thickness efficiency
    my ($me, $den) = @_;
    return $me * $den / 7.86;
}

=head2 me2ce (mass_efficiency, cost_usd_per_pound)

Given the mass efficiency of a material, returns its cost efficiency.

See the description of me2te() for more explanation.

This actually returns the cost efficiency relative to AISI 4340 steel, which is
often used as a close approximation to RHA.  The costs of actual MIL-A-12560
compliant steel are dominated by political factors, which are beyond the scope
of this module.

=over 4

parameter: (float) armor material mass efficiency (unitless, factor relative to RHA)

parameter: (float) armor material cost (USA dollars / pound)

returns: (float) armor material cost efficiency (unitless, factor relative to RHA)

=back

=cut

sub me2ce { # given mass efficiency and cost per pound, returns cost efficiency relative to AISI 4340 steel (which closely approximates characteristics of RHA).
    my ($me, $cost) = @_;
    # AISI 4340 steel is about $3.80/lb; qv https://www.metalsupermarkets.com/CART.ASPX?PRODUCTID=MR4340/9
    return $me * 3.80 / $cost;
}

=head2 me2cem (mass_efficiency, cost_usd_per_pound)

Given the mass efficiency of a material, returns its cost efficiency relative to mild steel.

See the description of me2ce() for more explanation.

=over 4

parameter: (float) armor material mass efficiency (unitless, factor relative to RHA)

parameter: (float) armor material cost (USA dollars / pound)

returns: (float) armor material cost efficiency (unitless, factor relative to mild steel)

=back

=cut

sub me2cem { # given mass efficiency and cost per pound, returns cost efficiency relative to mild steel
  my ($me, $cost) = @_;
  my $mild_steel_cost = 0.40; # Mild Steel 1" Plate is about $0.40/lb
  my $mild_steel_me   = 0.81; # Mild Steel 1" Plate has mass efficiency of about 0.81
  return ($me * $mild_steel_cost) / ($cost * $mild_steel_me);
  }

=head2 odermatt (length_cm, diam_cm, vel_mps, target_density, target_uts_kpsi, rod_density, deg_angle, kps_drop_per_km, range_km, target_thickness_cm, [tip_length_cm, kA1, kA2])

Attempts to estimate perforation limit for a long-rod projectile penetrating RHA.  Produces more accurate results than Anderson, but also requires more hard-to-get information, and doesn't exactly measure the same thing (perforation limit, vs depth into semi-infinite target).

This function is based on Lanz and Odermatt's paper _Post Perforation Length & Velocity of KE Projectiles with single Oblique Targets_, published in the 15th International Symposium of Ballistics.

ONLY VALID IN HYPERVELOCITY DOMAIN.

Only valid for penetrator length/diameter ratios of 10.0 or higher, unless kA1 and kA2 are provided (which afaik can only be derived empirically, so good luck).

=over 4

parameter: (float) penetrator length (in cm)

parameter: (float) penetrator diameter (in cm)

parameter: (float) penetrator velocity (in meters per second)

parameter: (float) target density (in g/cc)

parameter: (float) target ultimate tensile strength (in kpsi)

parameter: (float) penetrator density (in g/cc)

parameter: (float) angle of impact (in degrees, 0 == perpendicular to target surface)

parameter: (float) target thickness (in cm)

parameter: (float) OPTIONAL: penetrator tip length (in cm, defaults to three times penetrator diameter)

parameter: (float) OPTIONAL: kA1 empirically discovered constant (only required for L/D < 10.0)

parameter: (float) OPTIONAL: kA2 empirically discovered constant (only required for L/D < 10.0)

returns: (float) Target's perforation limit (in cm)

=back

=cut

# Given attributes of a hypervelocity-domain long-rod penetrator and its target, returns limit of perforation depth, in cm.
# Based on Odermatt's Perforation Limit Equation for long rod penetrators, valid for L:D of 10 or over.
# 15th international symposium of ballistics - "Post Perforation Length & Velocity of KE Projectiles with Single Oblique Targets".
# NOTE: only works for L:D of 10 or greater, unless kA1 and kA2 are defined.  For smaller penetrators, use anderson or pc.
# NOTE: only valid in hypervelocity domain, above 1100 meters/second.
sub odermatt {
    my ($len, $diam, $vel, $pen_mat, $targ_mat, 
        $penden, $deg_angle, $targthick, $tip_len, $targden, $targ_kpsi, $kA1, $kA2) = @_;
    die("Error: L:D of $len:$diam is outside this formula's domain\n") unless (($len / $diam >= 10) || (defined($kA1) && defined($kA2)));
    my %mat_to_den   = ('du' =>   18800, 'wha' =>  17000, 'steel' =>  7860);
    my %mat_to_a     = ('du' =>   0.825, 'wha' =>  0.994, 'steel' => 1.104);
    my %mat_to_c0    = ('du' =>    90.0, 'wha' =>  134.5, 'steel' =>  9874); # term 5 differs for steel, so const c given instead of c0
    my %mat_to_c1    = ('du' => -0.0849, 'wha' => -0.148, 'steel' =>     0);
    die("Error: Unsupported target material.  Use one of: du wha steel\n") unless(defined($mat_to_a{$targ_mat}));
    die("Error: Unsupported penetrator material.  Use one of: du wha steel\n") unless(defined($mat_to_c0{$pen_mat}));
    my $const_a      = $mat_to_a{$targ_mat};
    my $const_b0     = 0.283;
    my $const_b1     = 0.0656;
    my $const_c0     = $mat_to_c0{$pen_mat};
    my $const_c1     = $mat_to_c1{$pen_mat};
    # zzzappp
    my $targ_mpa     = $targ_kpsi * 6.895; # converting kpsi to MPa
    my $targ_den_gm3 = $targden * 1000;    # converting g/cc to kg/m3
    my $pen_den_gm3  = $penden * 1000;     # converting g/cc to kg/m3
    my $diam_mm      = $diam * 10;         # cm to mm
    my $len_mm       = $len * 10;          # cm to mm
    my $targ_mm      = $targthick * 10;    # cm to mm
    $kA1     = $kA1     || 3.94;
    $kA2     = $kA2     || 11.20;
    $tip_len = $tip_len || $diam * 3;      # if no tip length given, assume three diameters long
    $tip_len = $tip_len * 10;              # cm to mm

    # length to diameter ratio influence (valid for Lw/D of at least 10 -- if Lw/D is lower, use anderson):
    my $Lw = $len_mm - 2 * $tip_len / 3 - 1.5 * $diam_mm;  # approximation of length of penetrator after replacing conical tip with cylinder of equal mass and diameter and reducing remaining length by 1.5 diameters
    # print "Lw= len_mm=$len_mm - 2 * tip_len=$tip_len / 3 - 1.5 * diam_mm=$diam_mm = $Lw\n";
    my $LDtanh = Math::Trig::tanh(($Lw / $diam_mm) - 10);
    my $facA = 1 + $kA1 * $diam_mm / ($Lw * (1 - $LDtanh / $kA2));
    # print "facA = 1 + kA1=$kA1 * diam_mm=$diam_mm / (Lw=$Lw * (1 - LDtanh=$LDtanh / kA2=$kA2)) = $facA\n";

    # target obliquity:
    my $rad_angle = pi * $deg_angle / 180; # convert degrees to radians
    my $facB      = 0;                     # target obliquity
    $facB = cos($rad_angle)**-0.225;
    # print "facB = cos(rad_angle=$rad_angle)**-0.225 = $facB\n";

    # density ratio of penetrator to target
    my $facC = ($pen_den_gm3 / $targ_den_gm3)**0.5;
    # print "facC = (pen_den_gm3=$pen_den_gm3 / targ_den_gm3=$targ_den_gm3)**0.5 = $facC\n";

    # material properties and impact velocity
    my $targMatFac = 22.1 + 0.01274 * $targ_mpa - 0.00000947 * $targ_mpa**2;
    # print "pen_den_gm3 = $pen_den_gm3  vel=$vel\n";
    my $facD_N = -1 * $targMatFac * $targ_mpa;
    # print "facD_N = -1 * targMatFac=$targMatFac * targ_mpa=$targ_mpa = $facD_N\n";
    my $facD_D = $pen_den_gm3 * $vel**2;
    # print "facD_D = pen_den_gm3=$pen_den_gm3 * vel=$vel**2 = $facD_D\n";
    my $facD = exp($facD_N / $facD_D);
    # print "facD = exp(facD_N=$facD_N / facD_D=$facD_D) = $facD\n";

    # print "len_mm=$len_mm facA(diam,len)=$facA facB(angle)=$facB facC(pden,tden)=$facC facD(targ_mpa,pden,vel)=$facD\n";
    my $penetration_mm = $len_mm * $facA * $facB * $facC * $facD;
    my $penetration_cm = int($penetration_mm + 0.5) / 10;  # rounding to nearest mm, then converting to cm
    return $penetration_cm;
}

# This formula implementation is horribly broken; still trying to figure it out.
# Given attributes of a hypervelocity-domain long-rod penetrator and its target, returns penetration into RHA, in cm.
# based on Lanz/Odermatt depth of penetration equation for long rod penetrators, valid for L:D of 10 or over.
# 15th international symposium of ballistics - "Post Perforation Length & Velocity of KE Projectiles with Single Oblique Targets".
# NOTE: only works for L:D of 10 or greater, unless kA1 and kA2 are defined.  For smaller penetrators, use anderson or pc.
# NOTE: only valid in hypervelocity domain, above 1100 meters/second.
sub lanz_odermatt_BROKEN {
    my ($len, $diam, $vel, $targden, $targ_kpsi, $penden, $deg_angle, $targthick, $tip_len, $kA1, $kA2) = @_;
    die("usage: pen_cm = odermatt (length_cm, diam_cm, vel_mps, target_den, target_uts_kpsi, pen_density, deg_angle, target_thick, [tip_length_cm, kA1, kA2 ]") unless (defined($len) && defined($targthick));
    die("error, L:D of $len:$diam is outside this formula's domain\n") unless (($len / $diam >= 10) || (defined($kA1) && defined($kA2)));
    # print "len=$len, diam=$diam, vel=$vel, targden=$targden, targ_kpsi=$targ_kpsi, penden=$penden, deg_angle=$deg_angle, targthick=$targthick, tip_len=$tip_len\n";
    my $targ_mpa     = $targ_kpsi * 6.895; # converting kpsi to MPa
    my $targ_den_gm3 = $targden * 1000;    # converting g/cc to kg/m3
    my $pen_den_gm3  = $penden * 1000;     # converting g/cc to kg/m3
    my $diam_mm      = $diam * 10;         # cm to mm
    my $len_mm       = $len * 10;          # cm to mm
    my $targ_mm      = $targthick * 10;    # cm to mm
    $kA1     = $kA1     || 3.94;
    $kA2     = $kA2     || 11.20;
    $tip_len = $tip_len || $diam * 3;      # if no tip length given, assume three diameters long
    $tip_len = $tip_len * 10;              # cm to mm

    # length to diameter ratio influence (valid for Lw/D of at least 10 -- if Lw/D is lower, use anderson):
    my $Lw = $len_mm - 2 * $tip_len / 3 - 1.5 * $diam_mm;  # approximation of length of penetrator after replacing conical tip with cylinder of equal mass and diameter and reducing remaining length by 1.5 diameters
    print "Lw= len_mm=$len_mm - 2 * tip_len=$tip_len / 3 - 1.5 * diam_mm=$diam_mm = $Lw\n";
    my $LDtanh = Math::Trig::tanh(($Lw / $diam_mm) - 10);
    my $facA = 1 + $kA1 * $diam_mm / ($Lw * (1 - $LDtanh / $kA2));
    print "facA = 1 + kA1=$kA1 * diam_mm=$diam_mm / (Lw=$Lw * (1 - LDtanh=$LDtanh / kA2=$kA2)) = $facA\n";

    # target obliquity:
    my $rad_angle = pi * $deg_angle / 180; # convert degrees to radians
    my $facB      = 0;                     # target obliquity
    $facB = cos($rad_angle)**-0.225;
    print "facB = cos(rad_angle=$rad_angle)**-0.225 = $facB\n";

    # density ratio of penetrator to target
    my $facC = ($pen_den_gm3 / $targ_den_gm3)**0.5;
    print "facC = (pen_den_gm3=$pen_den_gm3 / targ_den_gm3=$targ_den_gm3)**0.5 = $facC\n";

    # material properties and impact velocity
    my $targMatFac = 22.1 + 0.01274 * $targ_mpa - 0.00000947 * $targ_mpa**2;
    print "pen_den_gm3 = $pen_den_gm3  vel=$vel\n";
    my $facD_N = -1 * $targMatFac * $targ_mpa;
    print "facD_N = -1 * targMatFac=$targMatFac * targ_mpa=$targ_mpa = $facD_N\n";
    my $facD_D = $pen_den_gm3 * $vel**2;
    print "facD_D = pen_den_gm3=$pen_den_gm3 * vel=$vel**2 = $facD_D\n";
    my $facD = exp($facD_N / $facD_D);
    print "facD = exp(facD_N=$facD_N / facD_D=$facD_D) = $facD\n";

    print "len_mm=$len_mm facA(diam,len)=$facA facB(angle)=$facB facC(pden,tden)=$facC facD(targ_mpa,pden,vel)=$facD\n";
    my $penetration_mm = $len_mm * $facA * $facB * $facC * $facD;
    my $penetration_cm = int($penetration_mm + 0.5) / 10;  # rounding to nearest mm, then converting to cm
    return $penetration_cm;
}

=head2 pc (mass_grains, velocity_fps, distance_feet, diameter_inches, bullet_shape_str, [target_material])

Attempts to estimate how deeply a small-arms projectile will penetrate into a target.

Optimized for projectiles near 7.5mm in diameter, works okay for projectiles as small as 5mm or as large as 14mm.

This function attempts to account for effects of projectile wobble (yaw instability) and the different effects 
wobble has on different target materials.  The bullet is assumed to stabilize eventually, the stabilization distance 
depending on projectile mass.  This feature is a work-in-progress, and should be taken with generous salt.

This function is the original work of the author.

ONLY VALID IN BALLISTIC DOMAIN.

Not recommended for masses outside 55..450 grains range,

Not recommended for velocities outside 1200..3500 feet per second.

Not recommended for unjacketed lead projectiles.

=over 4

parameter: (float) penetrator mass (in grains)

parameter: (float) penetrator velocity (in feet per second)

parameter: (float) distance between muzzle and target (in feet)

parameter: (float) penetrator diameter (in inches)

parameter: (string) penetrator type, describing very approximately the general shape and composition of the projectile.  Valid values are:

=over 4

* "hp":  Hollowpoint, composed of thin brass lining over lead core.

* "sp":  Softpoint (exposed lead tip), composed of thin brass lining over lead core.

* "bp":  FMJ "ball", composed of thin brass lining over lead core.

* "ms":  Mild steel core, with ogival nose shape.

* "sc":  Hard steel core, with truncated-cone nose shape.

* "hc":  Synonym for "sc".

* "tc":  Tungsten-carbide core (not WHA), with truncated-cone nose shape.

* "wc":  Synonym for "tc".

* "wha": Tungsten heavy alloy core (eg, 90% W / 7% Ni / 3% Fe), with truncated-cone nose shape.

* "du":  Depleted uranium alloy core (99.25% U / 0.75% Ti), with truncated-cone nose shape.

The hash table mapping these type strings to their numeric penetration factors is available as %Physics::Ballistics::Terminal::Penetrator_Types_H, for ease of reference and modification.

=back

parameter: (OPTIONAL) (string) target material.  Valid target materials are:

=over 4

* "pine":  Soft, green pine wood.

* "sand":  Loose-packed, dry sand.

* "brick":  Typical firebrick, as often used in residential exterior wall construction.

* "cinder":  Cinderblock, as often used in inexpensive non-residential exterior wall construction.

* "concrete":  Reinforced concrete, poured-in-place.

* "mild":  Mild steel, as often used in civilian construction or automotive body manufacture.

* "hard":  Hardened steel of at least 250BHN, akin to RHA.

=back

returns: (float) estimated depth of penetration (in mm), rounded to the nearest tenth of a mm.

=back

=cut

my $pc_exponents_hr = {
  sand  => 2.0,
  pine  => 2.2,
  conc  => 0.8,
  brick => 0.55,
  cind  => 0.32,
  mild  => 0.30
};

my $pc_k_hr = {
  sand  => 650**$pc_exponents_hr->{'sand'},
  pine  => 650**$pc_exponents_hr->{'pine'},
  conc  => 650**$pc_exponents_hr->{'conc'},
  brick => 650**$pc_exponents_hr->{'brick'},
  cind  => 650**$pc_exponents_hr->{'cind'},
  mild  => 650**$pc_exponents_hr->{'mild'}
};

sub stabilization_distance_meters {
  my ($grain) = @_;
  return int(($grain**0.333) * 37.8);
}

sub penetration_curve_sand {
  my ($dist_ft, $pen_typ, $grain) = @_;
  my $dist_stable = stabilization_distance_meters($grain);
  my $resistance_factor = 60;
  return $resistance_factor if ($dist_ft >= $dist_stable);
  my $e_sand = 2.7;
  my $dist_limit = $dist_stable ** $e_sand;
  my $wobble_penalty = 0.50 * (($dist_limit - $dist_ft**$e_sand)/$dist_limit)**0.75;
  return $resistance_factor * (1-$wobble_penalty);
}

sub penetration_curve_pine {
  my ($dist_ft, $pen_typ, $grain) = @_;
  my $dist_stable = stabilization_distance_meters($grain);
  my $resistance_factor = 305;  # was 803 -- TTK 2015-04-02
  return $resistance_factor if ($dist_ft >= $dist_stable);
  my $e_pine = 2.6;
  my $dist_limit = $dist_stable ** $e_pine;
  my $wobble_penalty = 0.75 * (($dist_limit - $dist_ft**$e_pine)/$dist_limit)**0.75;
  return $resistance_factor * (1-$wobble_penalty);
}

sub penetration_curve_concrete {
  my ($dist_ft, $pen_typ, $grain) = @_;
  my $dist_stable = stabilization_distance_meters($grain);
  my $resistance_factor = 40;
  return $resistance_factor if ($dist_ft >= $dist_stable);
  my $e_concrete = 0.80;
  my $dist_limit = $dist_stable ** $e_concrete;
  my $wobble_penalty = 0.75 * (($dist_limit - $dist_ft**$e_concrete)/$dist_limit);
  return $resistance_factor * (1-$wobble_penalty);
}

sub penetration_curve_brick {
  my ($dist_ft, $pen_typ, $grain) = @_;
  my $dist_stable = stabilization_distance_meters($grain);
  my $resistance_factor = 42;
  return $resistance_factor if ($dist_ft >= $dist_stable);
  my $e_brick = 0.55;
  my $dist_limit = $dist_stable ** $e_brick;
  my $wobble_penalty = 0.30 * (($dist_limit - $dist_ft**$e_brick)/$dist_limit);
  return $resistance_factor * (1-$wobble_penalty);
}

sub penetration_curve_cinder {
  my ($dist_ft, $pen_typ, $grain) = @_;
  my $dist_stable = stabilization_distance_meters($grain);
  my $resistance_factor = 55; # was 157 -- TTK 2015-04-02
  return $resistance_factor if ($dist_ft >= $dist_stable);
  my $e_cinder = 0.55;
  my $dist_limit = $dist_stable ** $e_cinder;
  my $wobble_penalty = 0.25 * (($dist_limit - $dist_ft**$e_cinder)/$dist_limit);
  return $resistance_factor * (1-$wobble_penalty);
}

sub penetration_curve_mild_steel {
  my ($dist_ft, $pen_typ, $grain) = @_;
  my $dist_stable = stabilization_distance_meters($grain);
  my $resistance_factor = 1.25;
  return $resistance_factor if ($dist_ft >= $dist_stable);
  my $e_mild = 0.82;
  my $dist_limit = $dist_stable ** $e_mild;
  my $wobble_penalty = 0.65 * (($dist_limit - $dist_ft**$e_mild)/$dist_limit);
  return $resistance_factor * (1-$wobble_penalty);
}

sub penetration_curve_hard_steel {
  my ($dist_ft, $pen_typ, $grain) = @_;
  my $dist_stable = stabilization_distance_meters($grain);
  my $resistance_factor = 1.0;
  return $resistance_factor if ($dist_ft >= $dist_stable);
  my $e_hard = 0.91;
  my $dist_limit = $dist_stable ** $e_hard;
  my $wobble_penalty = 0.65 * (($dist_limit - $dist_ft**$e_hard)/$dist_limit);
  return $resistance_factor * (1-$wobble_penalty);
}

sub pc {
    my ($grain, $vel_fps, $dist_ft, $diam, $pen_typ, $target_material, $te) = @_;
    die("mm = pc(grains, velocity_fps, distance_feet, diam_inches, [{hp,sp,bp,ms,hs,sc,wc,tc,wha,du},] [{pine, sand, brick, cinder, concrete, mild, hard},] [, Te])") unless (defined ($diam));
    $te = 1 unless (defined ($te)); # thickness efficiency of target material, relative to normal case (eg, RHA)
    my %curve_h = (
        "pine"     => \&penetration_curve_pine,
        "sand"     => \&penetration_curve_sand,
        "brick"    => \&penetration_curve_brick,
        "cinder"   => \&penetration_curve_cinder,
        "concrete" => \&penetration_curve_concrete,
        "mild"     => \&penetration_curve_mild_steel,
        "hard"     => \&penetration_curve_hard_steel,
        "rha"      => \&penetration_curve_hard_steel
    );
    my $curve_cr = $curve_h{"hard"};
       $curve_cr = $curve_h{$target_material} if (defined($curve_h{$target_material}));
    my $KED = ($grain ** 1.29) * (($vel_fps/1000) ** 1.51) / ($diam ** 1.05);   # energy density, sorta (fits empirical data)
    my $pf  = undef;
    # $KED *= $pf if (defined($pf = $Physics::Ballistics::Terminal::Penetrator_Types_H{$pen_typ}));
    my $material_independent_constant = 1750; # was 2785 -- TTK 2015-04-02
    my $penetration_depth_mm  = $KED *= $curve_cr->($dist_ft, $pen_typ, $grain) / $material_independent_constant;
       $penetration_depth_mm *= $pf if (defined($pf = $Physics::Ballistics::Terminal::Penetrator_Types_H{$pen_typ}));
       $penetration_depth_mm /= $te; # target material specific adjustment
       $penetration_depth_mm = int (($penetration_depth_mm * 10) + 0.5) / 10; # this still gives more precision than it deserves
    return $penetration_depth_mm;
}

our %Penetrator_Types_H = (
    'hp'  => 0.775,  # hollowpoint lead with gliding material jacket
    'sp'  => 0.850,  # softpoint lead with gliding material jacket
    'bp'  => 1.050,  # ballpoint lead with gliding material jacket
    'ms'  => 1.500,  # mild steel core AP
    'hs'  => 1.800,  # hard steel core AP
    'sc'  => 1.800,  # hard steel core AP
    'wc'  => 2.700,  # tungsten-carbide core AP (not WHA)
    'tc'  => 2.700,  # tungsten-carbide core AP (not WHA)
    'wha' => 2.900,  # tungsten heavy alloy (WHA) core AP, guesstimate
    'du'  => 3.500   # uranium/titanium alloy core AP
);

=head2 pc_simple (mass_grains, velocity_fps, diameter_inches, shape_str)

Simple penetration calculator.  Attempts to estimate how deeply a small-arms projectile
will penetrate into RHA.  Optimized for projectiles near 7.5mm in diameter, works okay
for projectiles as small as 5mm or as large as 14mm.

This function is the original work of the author.

ONLY VALID IN BALLISTIC DOMAIN.

Not recommended for masses outside 55..450 grains range,

Not recommended for velocities outside 1200..3500 fps range,

Not recommended for unjacketed lead projectiles.

=over 4

parameter: (float) penetrator mass (in grains)

parameter: (float) penetrator velocity (in feet per second)

parameter: (float) penetrator diameter (in inches)

parameter: (string) penetrator type, describing very approximately the general shape and composition of the projectile.  Valid values are:

=over 4

* "hp":  Hollowpoint, composed of thin brass lining over lead core.

* "sp":  Softpoint (exposed lead tip), composed of thin brass lining over lead core.

* "bp":  FMJ "ball", composed of thin brass lining over lead core.

* "ms":  Mild steel core, with ogival nose shape.

* "sc":  Hard steel core, with truncated-cone nose shape.

* "hc":  Synonym for "sc".

* "tc":  Tungsten-carbide core (not WHA), with truncated-cone nose shape.

* "wc":  Synonym for "tc".

* "wha": Tungsten heavy alloy core (eg, 90% W / 7% Ni / 3% Fe), with truncated-cone nose shape.

* "du":  Depleted uranium alloy core (99.25% U / 0.75% Ti), with truncated-cone nose shape.

The hash table mapping these type strings to their numeric penetration factors is available as %Physics::Ballistics::Terminal::Penetrator_Types_H, for ease of reference and modification.

=back

parameter: (OPTIONAL) (string or float) thickness efficiency of target material (as ratio to RHA).  Defaults to 1.0 (target is RHA).

returns: (float) estimated depth of penetration into RHA (in mm), rounded over to the nearest tenth of a mm.

=back

=cut

sub pc_simple {
    my ($grain, $fps, $diam, $typ, $te) = @_;
    die("mm = pc(grains, velocity_fps, diam_inches, {hp,sp,bp,ms,hs,sc,wc,tc,wha,du} [, Te])") unless (defined ($diam));
    $te = 1 unless (defined ($te)); # thickness efficiency of target material, relative to RHA
    $fps /= 1000;
    my $KED = ($grain ** 1.29) * ($fps ** 1.51) / ($diam ** 1.05);   # energy density, sorta (fits empirical data)
    my $pf  = undef;
    $KED *= $pf if (defined($pf = $Physics::Ballistics::Terminal::Penetrator_Types_H{$typ}));
    my $RHA = $KED / 2785; # estimated depth of penetration of RHA, in mm
    $RHA /= $te; # target material specific adjustment
    $RHA = int (($RHA * 10) + 0.5) / 10; # this still gives more precision than it deserves
    return $RHA;
}


=head2 hits_score (mass_grains, velocity_fps, diameter_inches)

Computes a projectile's Hornady Index of Terminal Standards (H.I.T.S.) score, an 
approximation of its lethality.

Personally I think H.I.T.S. severely over-emphasizes bullet mass (the score is 
proportional to the SQUARE of the bullet mass, times velocity, divided by bullet 
sectional area).  It is included here anyway because there are no really good 
lethality models, and many big-game hunters like H.I.T.S. (and it is possible 
that bullet mass really is that important when taking down very large animals).

See also:

L<http://www.hornady.com/hits>

L<http://www.hornady.com/hits/calculator>

L<http://www.rathcoombe.net/sci-tech/ballistics/myths.html>

=over 4

parameter: (float) projectile mass (in grains)

parameter: (float) projectile velocity (in feet per second)

parameter: (float) projectile diameter (in inches)

returns: (integer) lethality (HITS score, qv table in L<http://www.hornady.com/hits>)

=back

=cut

# HITS - Hornady Index of Terminal Standards formula:
# (Bullet weight grains)^2*(Bullet velocity fps)/(700000*Bullet diameter inches^2)
sub hits_score {
    my ($mass_grains, $vel_fps, $diameter_inches) = @_;
    die("index = hits_score(bullet_grains, bullet_fps, bullet_diameter_inches)") unless (defined($diameter_inches));
    return int(($mass_grains**2) * $vel_fps / 700000 / ($diameter_inches**2) + 0.5)
}


# v = sigma(n1, n2, ...);
# Returns the standard deviation of its inputs.  qv: http://en.wikipedia.org/wiki/Standard_deviation#Identities_and_mathematical_properties
sub sigma {
    my $n   = scalar(@_);
    my $tot = 0;
    my $sqs = 0;
    my ($avg, $sig);
    foreach my $term (@_) { $tot += $term; }
    $avg = $tot / $n;
    foreach my $term (@_) {
        my $dif = abs($term - $avg);
        $sqs += $dif**2;
    }
    $sig = ($sqs / $n)**0.5;
    return $sig;
}

# v = average(n1, n2, ...);
# Returns the simple arithmetic average of its inputs.  qv: http://en.wikipedia.org/wiki/Arithmetic_mean
sub average {
    my $n = scalar(@_);
    return 0 if ($n < 1);
    my $sum = 0;
    foreach my $x (@_) { $sum += $x; }
    return $sum / $n;
}

# v = rndto(x, n);
# Round x over to n digits, appending sigfigs to the right of the decimal point as necessary when n < 0.
# rndto(1234.567,  2) == 1200
# rndto(1234.567,  1) == 1230
# rndto(1234.567, -1) == 1234.6
# rndto(1234.567, -2) == 1234.57
# rndto(1234,     -2) == 1234.00
sub rndto {
    my ($x, $n) = @_;
    my ($ret);
    $ret = int(($x / (10**$n)) + 0.5) * (10**$n);
    return $ret unless ($n < 0);
    $n *= -1;
    return  $ret   . ("0" x ($n - length($1))) if ($ret =~ /\.(\d+)/);
    return "$ret." . ("0" x  $n);
}

sub r2d {  # Convert radians to degrees
    return 360 * $_[0] / (2 * pi);
}

sub d2r {  # Convert degrees to radians
    return $_[0] * 2 * pi / 360;
}

=head2 poncelet(diameter_mm, mass_grains, velocity_fps, target_shear_strength_psi, target_density)

Jean-Victor Poncelet was one of the first to attempt mathematical models of
depth of penetration.  His formula, developed in the 19th century, attempts
to predict the penetration of bullets into flesh-like materials.  It is not
very good, failing to take into account such factors as bullet nose shape,
bullet tumbling within the target, and impacts with bone, horn, or cartilage.

ONLY VALID IN BALLISTIC DOMAIN.

=over 4

parameter: (float) penetrator diameter (in mm)

parameter: (float) penetrator mass (in grains)

parameter: (float) penetrator velocity (in feet per second)

parameter: (float) target material shearing strength (in PSI)

parameter: (float) target density (in g/cc)

returns: (int) depth of penetration (in mm)

=back

=cut

# Old, not very useful formula by Poncelet for predicting depth of penetration into flesh.
sub poncelet {
    my ($cal, $mass, $vel, $c0, $c1, $debug) = @_;
    die('usage: ponce (cal_mm, mass_grain, vel_fps, targ_shear_psi, targ_density) = pen_cm') unless(defined($c1));
    # c0 = Shearing strength
    # c1 = Specific density (water = 1 = 1 g/cc)
    $mass /=   15.43; # converting grains to grams
    $vel  /=    3.28; # converting ft/s to m/s
    $c0   /=  145.04; # converting psi to MPa
    if ($debug) {
        print "# poncelet: mass g  = $mass\n";
        print "# poncelet: vel m/s = $vel\n";
        print "# poncelet: shr MPa = $c0\n";
    }
    my $term1_1 = 2 * 3.141592 * $c1;
    my $term1_2 = $cal**2 / 4;
    my $term1   = $mass / ($term1_1 * $term1_2);
    my $term2_1 = ($c1 * $vel**2 + $c0) / $c0;
    my $term2   = log($term2_1);
    my $depth_cm = $term1 * $term2;
    # my $depth_cm = ($mass / (2 * $c1 * 3.141592 * $cal**2 / 4)) * log(($c1 * $vel**2 + $c0) / $c0);
    if ($debug) {
        print "# poncelet: term1_1  = 2 * 3.141592 * den $c1 = $term1_1\n";
        print "# poncelet: term1_2  = cal^2 $cal**2 / 4 = $term1_2\n";
        print "# poncelet: term1    = mass g $mass / (term1_1 * term1_2) = $term1\n";
        print "# poncelet: term2_1  = den $c1 * vel^2 $vel**2 + shear $c0) / shear $c0 = $term2_1\n";
        print "# poncelet: term2    = log(term2_1) = $term2\n";
        print "# poncelet: depth_cm = term1 * term2 = $depth_cm\n";
    }
    return int($depth_cm * 10 + 0.5); # converting cm to nearest mm, which is still way more precision than this deserves.
}

=head2 te2me (thickness_efficiency, density)

Given the mass efficiency of a material, returns its thickness efficiency.

See the description of me2te() for more explanation.

=over 4

parameter: (float) armor material thickness efficiency (unitless, factor relative to RHA)

parameter: (float) armor material density (g/cc)

returns: (float) armor material mass efficiency (unitless, factor relative to RHA)

=back

=cut

sub te2me { # given thickness efficiency and density, returns mass efficiency
    my ($te, $den) = @_;
    return $te * 7.86 / $den;
}

=head2 lethality (grains, velocity_fps)

Approximates the lethality of a projectile impacting a living creature.

C<THIS FUNCTION IS A WORK IN PROGRESS> and currently extremely simple.

Its parameters and output are likely to change in incompatible ways in future releases.

Note the caveats enumerated at L<http://www.rathcoombe.net/sci-tech/ballistics/myths.html>

This function assumes nontrivial tissue penetration occurs.  For the moment it is based on observations of a very rough correlation between velocity and mass and permanent tissue cavity volume.

See also Fackler: L<http://www.ciar.org/ttk/mbt/papers/misc/paper.x.small-arms.wounding-ballistics.patterns_of_military_rifle_bullets.fackler.unk.html>

=over 4

parameter: (integer) projectile weight (in grains)

parameter: (integer) projectile velocity (in feet/second)

returns: (float) lethality relative to 5.56x45mm at point blank range.

=back

=cut

sub lethality { # given grains and fps, estimate lethality relative to 5.56x45mm by momentum method (simplest).
  # TODO: improve on this to take length, width, tumble rate, and fragmentation into effect (permanent cavity volume method).
  my ($grains, $fps) = @_;
  die("m = lethality(grains, feet_per_second)") unless(defined($grains) && defined($fps));
  my $baseline_momentum = 63 * 3100;
  my $posed_momentum = $grains * $fps;
  my $relative_momentum = $posed_momentum / $baseline_momentum;
  return int($relative_momentum * 100 + 0.5) / 100;
}

=head2 hv2bhn (hardness_vickers)

Given a Vickers hardness rating, approximates the equivalent Brinell Hardness Number (via 10/3000 WC method).

Vickers can be converted to other hardness ratings by first converting to BHN, and then converting from BHN to the desired hardness rating.

=over 4

parameter: (integer) Vickers Hardness rating

returns: (float) Brinell Hardness Number (BHN)

=back

=cut

sub hv2bhn {    # very approximately converts hardness vickers to brinell hardness number (10/3000 WC method)
    my ($hv) = @_;
    return undef if ($hv !~ /^(-?[0-9\.]+)/);
    $hv = $1;
    return ($hv * 0.92857)       if ($hv < 701);
    return ($hv * 0.70588 + 156) if ($hv < 826);
    return ($hv * 0.56770 + 270) if ($hv < 851);
    return ($hv * 0.34417 + 460) if ($hv < 1001);
    return ($hv * 0.17210 + 632) if ($hv < 1201);
    return ($hv * 0.08605 + 735);
}

=head2 bhn2hv (brinell_hardness_number)

Given a Brinell Hardness Number hardness rating (via 10/3000 WC method), approximates the equivalent Vickers Hardness rating.

=over 4

parameter: (integer) Brinell Hardness Number (BHN)

returns: (float) Vickers Hardness rating

=back

=cut

sub bhn2hv {    # very approximately converts brinell hardness number (10/3000 WC method) to hardness vickers
    my ($bhn) = @_;
    return undef if ($bhn !~ /^(-?[0-9\.]+)/);
    $bhn = $1;
    return (($bhn - 735) / 0.08605) if ($bhn > 838);
    return (($bhn - 632) / 0.17210) if ($bhn > 804);
    return (($bhn - 460) / 0.34417) if ($bhn > 752);
    return (($bhn - 270) / 0.56770) if ($bhn > 738);
    return (($bhn - 156) / 0.70588) if ($bhn > 650);
    return ($bhn / 0.92857);
}

=head2 hrc2bhn (rockwell_hardness_C)

Given a Rockwell Hardness C rating, approximates the equivalent Brinell Hardness Number (via 10/3000 WC method).

HRC can be converted to other hardness ratings by first converting to BHN, and then converting from BHN to the desired hardness rating.

=over 4

parameter: (integer) Rockwell Hardness C, valid ONLY in the range 15..65.

returns: (float) Brinell Hardness Number (BHN)

=back

=cut

sub hrc2bhn { # very approximately converts rockwell hardness C to BHN (10/3000 WC)
              # zzapp -- FIXME:  Segment this curve to improve accuracy
              #      actual calculated    absolute
              # HRC  BHN    BHN           error
              #  20  228    228.833       0.833
              #  30  286    288.475       2.475
              #  40  371    366.717      -4.283
              #  50  482    482.458       0.458
              #  60  657    654.6        -2.400
    my ($hrc) = @_;
    return undef if ($hrc > 65);  # error condition -- invalid range
    return undef if ($hrc < 15);  # error condition -- invalid range
    my $bhn = 89.75 + (28.5125 * $hrc / 3) - (0.1905 * ($hrc**2)) + (0.00315 * ($hrc**3));
    return int(0.5 + $bhn);       # eliminating illusion of accuracy
}

=head2 bhn2hrc (brinell_hardness_number)

Given a Brinell Hardness Number hardness rating (via 10/3000 WC method), approximates the equivalent Rockwell Hardness C rating.

Approximation is accurate to within 5% near the low end, 2% everywhere else.

=over 4

parameter: (integer) Brinell Hardness Number (BHN), valid ONLY in the range 200..770

returns: (float) Rockwell Hardness C rating

=back

=cut

sub bhn2hrc { # very approximately converts BHN (10/3000 WC) to rockwell hardness C
    # reasonably pleased with the accuracy of this -- error is up to 5% near the low end, but less than 2% otherwise.
    my ($bhn) = @_;
    return undef if ($bhn < 200); # out of bounds
    return undef if ($bhn > 770); # out of bounds
    my $hrc = -3 + ($bhn / 14) + ($bhn / 74)**2 - ($bhn / 168)**3;
    $hrc -= 1 if ($bhn <= 215);
    $hrc += 2 if ($bhn <= 436 && $bhn >= 254);
    $hrc += 1 if ($bhn <= 402 && $bhn >= 279);
    $hrc -= 2 if ($bhn <= 710 && $bhn >= 553);
    return int($hrc);
}

=head2 psi2bhn (pounds_per_square_inch)

Given the ultimate tensile strength of a steel formulation in PSI, approximates the equivalent Brinell Hardness Number (via 10/3000 WC method).

Steel UTS PSI can be converted to other hardness ratings by first converting to BHN, and then converting from BHN to the desired hardness rating.

Approximation is accurate to within 2%.

See also:

L<http://www.monachos.gr/en/resources/hardness_conversion.asp>

L<http://mdmetric.com/tech/hardness.htm>

=over 4

parameter: (integer) Pounds per square inch

returns: (float) Brinell Hardness Number (BHN)

=back

=cut

sub psi2bhn { # very approximately converts steel uts psi to brinell hardness number
              # source: http://www.monachos.gr/en/resources/hardness_conversion.asp
              # qv alt: http://mdmetric.com/tech/hardness.htm
              # this table provides approx 2% error in conversion
    my ($psi) = @_;
    return undef unless ($psi =~ /^(-?[0-9\.]+)/);
    $psi = $1;
    $psi /= 1000;
    return ($psi / 0.500) if ($psi < 127);
    return ($psi / 0.497) if ($psi < 140);
    return ($psi / 0.487) if ($psi < 153);
    return ($psi / 0.485) if ($psi < 166);
    return ($psi / 0.486) if ($psi < 179);
    return ($psi / 0.484) if ($psi < 192);
    return ($psi / 0.483) if ($psi < 205);
    return ($psi / 0.484) if ($psi < 218);
    return ($psi / 0.489) if ($psi < 231);
    return ($psi / 0.493) if ($psi < 257);
    return ($psi / 0.494) if ($psi < 270);
    return ($psi / 0.495) if ($psi < 283);
    return ($psi / 0.497) if ($psi < 296);
    return ($psi / 0.498) if ($psi < 322);
    return ($psi / 0.499) if ($psi < 335);
    return ($psi / 0.500) if ($psi < 348);
    return ($psi / 0.501) if ($psi < 374);
    return ($psi / 0.503) if ($psi < 387);
    return ($psi / 0.504) if ($psi < 400);
    return ($psi / 0.506) if ($psi < 426);
    return ($psi / 0.507) if ($psi < 439);
    return ($psi / 0.510) if ($psi < 452);
    return ($psi / 0.509) if ($psi < 478);
    return ($psi / 0.511) if ($psi < 491);
    return ($psi / 0.512) if ($psi < 504);
    return ($psi / 0.513) if ($psi < 530);
    return ($psi / 0.514) if ($psi < 595);
    return ($psi / 0.515) if ($psi < 621);
    return ($psi / 0.516) if ($psi < 634);
    return ($psi / 0.517);
}

=head2 bhn2psi (brinell_hardness_number)

Given a Brinell Hardness Number hardness rating (via 10/3000 WC method), approximates the equivalent steel ultimate tensile strength in pounds per square inch.

Approximation is accurate to within 2%.

See also:

L<http://www.monachos.gr/en/resources/hardness_conversion.asp>

L<http://mdmetric.com/tech/hardness.htm>

=over 4

parameter: (integer) Brinell Hardness Number (BHN)

returns: (float) Steel ultimate tensile strength (psi)

=back

=cut

sub bhn2psi { # very approximately converts brinell hardness number to steel uts psi
              # source: http://www.monachos.gr/en/resources/hardness_conversion.asp
              # qv alt: http://mdmetric.com/tech/hardness.htm
              # this table provides 2% or less error in conversion
    my ($bhn) = @_;
    return undef unless ($bhn =~ /^(-?[0-9\.]+)/);
    $bhn = $1;
    return ($bhn * 500) if ($bhn < 127);
    return ($bhn * 496) if ($bhn < 131);
    return ($bhn * 489) if ($bhn < 138);
    return ($bhn * 497) if ($bhn < 144);
    return ($bhn * 490) if ($bhn < 150);
    return ($bhn * 487) if ($bhn < 157);
    return ($bhn * 485) if ($bhn < 168);
    return ($bhn * 488) if ($bhn < 171);
    return ($bhn * 489) if ($bhn < 175);
    return ($bhn * 486) if ($bhn < 184);
    return ($bhn * 481) if ($bhn < 188);
    return ($bhn * 484) if ($bhn < 193);
    return ($bhn * 482) if ($bhn < 198);
    return ($bhn * 488) if ($bhn < 202);
    return ($bhn * 483) if ($bhn < 208);
    return ($bhn * 481) if ($bhn < 213);
    return ($bhn * 484) if ($bhn < 218);
    return ($bhn * 485) if ($bhn < 230);
    return ($bhn * 489) if ($bhn < 236);
    return ($bhn * 490) if ($bhn < 242);
    return ($bhn * 492) if ($bhn < 249);
    return ($bhn * 494) if ($bhn < 256);
    return ($bhn * 492) if ($bhn < 263);
    return ($bhn * 494) if ($bhn < 270);
    return ($bhn * 495) if ($bhn < 294);
    return ($bhn * 497) if ($bhn < 303);
    return ($bhn * 498) if ($bhn < 322);
    return ($bhn * 501) if ($bhn < 332);
    return ($bhn * 499) if ($bhn < 342);
    return ($bhn * 500) if ($bhn < 353);
    return ($bhn * 501) if ($bhn < 376);
    return ($bhn * 503) if ($bhn < 389);
    return ($bhn * 504) if ($bhn < 402);
    return ($bhn * 506) if ($bhn < 430);
    return ($bhn * 507) if ($bhn < 445);
    return ($bhn * 510) if ($bhn < 462);
    return ($bhn * 509) if ($bhn < 478);
    return ($bhn * 511) if ($bhn < 496);
    return ($bhn * 512) if ($bhn < 515);
    return ($bhn * 513) if ($bhn < 535);
    return ($bhn * 514) if ($bhn < 602);
    return ($bhn * 515) if ($bhn < 628);
    return ($bhn * 514) if ($bhn < 631);
    return ($bhn * 516) if ($bhn < 639);
    return ($bhn * 517);
}

1;

=head1 TODO

The pc function needs a lot of improvement.

Need a pc function for larger penetrators (for the ballistic domain, as anderson and odermatt suffices for hypervelocity domain).

The stabilization_distance_meters function should take projectile composition into account.

To be really useful the lethality function needs to take wobble, fragmentation and permanent wound cavity volume into account (per Fackler).

The hardness unit conversion functions should be based on Vickers, not Brinell, as Vickers has the wider valid range.

=cut
