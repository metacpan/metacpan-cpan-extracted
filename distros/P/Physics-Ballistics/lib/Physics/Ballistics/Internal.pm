package Physics::Ballistics::Internal;
use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(cartridge_capacity empty_brass gunfire powley recoil_mbt cup2psi cup2psi_linear ogival_volume recoil_mbt);
our $VERSION = '1.03';

use Physics::Ballistics;
use Math::Trig;

=head1 NAME

Physics::Ballistics::Internal -- Various internal ballistics formulae.

=cut

=head1 ABSTRACT

Internal ballistics is the study of what happens while a projectile is being
launched from a barrel, from the time the propellant ignites to the moment
after the projectile leaves the muzzle.

This module implements a variety of functions and mathematical formulae useful
in the analysis and prediction of internal ballistic effects.

It also branches out somewhat into the closely-related matters of bullet and
cartridge composition and characteristics.

=head1 REGARDING BULLET DIAMETERS

Some of these functions require the diameter of a projectile as a parameter.
Please note that bullet diameters are usually different from the names of
their calibers.  NATO 5.56mm bullets are actually 5.70mm in diameter, while
Russian 5.45mm bullets are actually 5.62mm.  .308 caliber bullets really are
0.308 inches in diameter (7.82mm), but .22 Long Rifle bullets are 0.222
inches across.

Making assumptions can hurt!  It's better to look it up before plugging it in.

=head1 ANNOTATIONS OF SOURCES

Regarding their source, these functions fall into three categories:  Some are
simple encodings of basic physics (like energy = 1/2 * mass * velocity**2),
and these will not be cited.  Others are from published works, such as books
or trade journals, and these will be cited when possible.  A few are products
of my own efforts, and will be thus annotated.

=head1 OOP INTERFACE

A more integrated, object-oriented interface for these functions is under
development.

=head1 CONSTANTS

=head2 %CASE_CAPACITY_GRAINS

This hash table maps the names of various cartridges to their volumes, in grains of water.

It is based on the table at: http://kwk.us/cases.html

Powder capacities will vary considerably depending on powder type, but multiplying water capacity by 0.85 comes pretty close for most powder types.

=cut

# Actual, measured case capacities, in grains of water, based on http://kwk.us/cases.html
# Powder capacities will vary considerably depending on powder type, but multiplying by 0.85 comes pretty close for most powder types.
our %CASE_CAPACITY_GRAINS = (
    '.14 Hornet' =>                12,
    '.17 Hornet' =>                14,
    '.17 Remington' =>             27,
    '.204 Ruger' =>                33,
    '.22 Hornet' =>                14,
    '.22 Hornet Impr' =>           16,
    '.218 Bee' =>                  18,
    '.22 Remington Jet' =>         18,
    '.221 Remington' =>            21,
    '.222 Remington' =>            27,
    '.223 Remington' =>            31,
    '5.56x45mm NATO' =>            31,
    '.222 Remington Magnum' =>     32,
    '5.6x50R' =>                   34,
    '.219 Zipper' =>               34,
    '.225 Winchester' =>           41,
    '.22-250 Remington' =>         43,
    '.220 Swift' =>                48,
    '.223 WSSM' =>                 53,
    '.22-06' =>                    65,
    '.22-15 Stevens' =>            17,
    '.22 Sav' =>                   35,
    '6x47' =>                      33,
    '6x52R Bret' =>                36,
    '6 BR' =>                      39,
    '6x70R' =>                     39,
    '.243 Winchester' =>           54,
    '.243 WSSM' =>                 54,
    '6 Remington' =>               55,
    '6 USN' =>                     51,
    '.240 Weatherby Magnum' =>     65,
    '6x62R' =>                     67,
    '.240 Fl NE' =>                58,
    '.25-20 WCF' =>                19,
    '.256 Winchester' =>           22,
    '.25-21 Stevens' =>            25,
    '.25-25 Stevens' =>            29,
    '.25-36 Marlin' =>             37,
    '.25-35 WCF' =>                37,
    '.25 Remington' =>             42,
    '.250 Sav' =>                  46,
    '.257 Roberts' =>              56,
    '.25-06 Remington' =>          66,
    '.257 Weatherby Magnum' =>     84,
    '6.5x70R' =>                   39,
    '6.5J' =>                      48,
    '6.5x52 Carcano' =>            49,
    '6.5x53R' =>                   49,
    '6.5x54 MS .256' =>            50,
    '.260 Remington' =>            53,
    '6.5x55' =>                    57,
    '6.5x57R' =>                   58,
    '6.5 Grendel' =>               35,
    '6.5 Remington Magnum' =>      68,
    '.264 Winchester Magnum' =>    82,
    '.270 REN' =>                  16,
    '.270 Winchester' =>           68,
    '.270 Weatherby' =>            83,
    '.28-30 Stevens' =>            37,
    '7-30 Waters' =>               45,
    '7x72R' =>                     54,
    '7-08 Remington' =>            56,
    '7x57R Mauser' =>              59,
    '.284 Winchester' =>           66,
    '.280 Remington' =>            67,
    '7x65R' =>                     68,
    '7 WSM' =>                     81,
    '7 Remington Magnum' =>        84,
    '.30 Carbine' =>               21,
    '.30-357 AeT' =>               25,
    '.30 Dasher' =>                43,
    '.30 Remington AR' =>          44,
    '.30-30' =>                    45,
    '.30 Remington' =>             46,
    '.303 Sav' =>                  48,
    '.300 Sav' =>                  52,
    '.307 Winchester' =>           54,
    '7.62x51mm NATO' =>            54,
    '.308 Winchester' =>           56,
    '.30 Fl.NE Purdey' =>          58,
    '.30-40 US' =>                 58,
    '.30-06 US' =>                 69,
    '.300 HH' =>                   86,
    '.300 Winchester Magnum' =>    89,
    '.30 Fl HH' =>                 90,
    '.300 Weatherby Magnum' =>     99,
    '.30-378' =>                  130,
    '7.62x39mm' =>                 35,
    '7.62x54R' =>                  64,
    '.303 Brit' =>                 57,
    '.375/303 WR' =>               62,
    '.32-20 WCF' =>                22,
    '7.65 Mauser' =>               58,
    '8x72R' =>                     59,
    '32-40 Ballard' =>             41,
    '8x50R Lebel' =>               66,
    '8x57R Mauser' =>              62,
    '8-06' =>                      70,
    '8 Remington Magnum' =>        98,
    '.318 WR' =>                   69,
    '.333 Jeffery' =>              86,
    '.33 WCF' =>                   63,
    '.338-06' =>                   70,
    '.338 Winchester Magnum' =>    86,
    '.340 Weatherby Magnum' =>     98,
    '.338 Laupa Magnum' =>        114,
    '.338-378' =>                 132,
    '.348 Winchester' =>           75,
    '9x57R Mauser' =>              62,
    '.357 Magnum' =>               27,
    '.357 Max' =>                  34,
    '.357/44 BD' =>                35,
    '.400/350 Rigby' =>            78,
    '.350 ME Guide 2' =>           49,
    '.35 Remington' =>             51,
    '.356 Winchester' =>           57,
    '.358 Winchester' =>           57,
    '.35 WCF' =>                   69,
    '.35 Whelen' =>                71,
    '.35 Greevy' =>                72,
    '.350 Remington Magnum' =>     73,
    '.358 Norma Magnum' =>         88,
    '.358 STA' =>                 105,
    '9.3x57 Mauser' =>             64,
    '9.3x54R Finn' =>              65,
    '9.3x72R' =>                   67,
    '9.3x62' =>                    77,
    '9.3x74R' =>                   82,
    '.360 No2 NE' =>              111,
    '.375 Winchester' =>           49,
    '.38-56 Winchester' =>         62,
    '.375 2.5 NE' =>               67,
    '.375-06' =>                   73,
    '.375 HH' =>                   95,
    '.375 Fl Magnum' =>            97,
    '.375 Ruger' =>               100,
    '.369 NE' =>                  102,
    '.378 Weatherby Magnum' =>    136,
    '.38-55 Ballard' =>            52,
    '.38-72 Winchester' =>         74,
    '.38-40 WCF' =>                39,
    '.400 Whelen' =>               75,
    '.405 Winchester' =>           78,
    '.400 Jeffery' =>             117,
    '.450/400 NE 3.25' =>         123,
    '.416 Taylor' =>               92,
    '.416 Remington Magnum' =>    107,
    '.416 Rigby' =>               130,
    '.416 Weatherby Magnum' =>    134,
    '.423 OKH' =>                  77,
    '.404 Jeffery' =>             113,
    '.44-40 WCF' =>                40,
    '.44 Spl' =>                   34,
    '.44 Remington Magnum' =>      39,
    '.444 Marlin' =>               69,
    '.45 Colt' =>                  42,
    '.454 Casull' =>               47,
    '.45-70 US' =>                 79,
    '.450 Marlin' =>               74,
    '.45-90 2.4"' =>               90,
    '.458 Winchester Magnum' =>    94,
    '.458 Lott' =>                108,
    '.450 3.25 NE' =>             129,
    '.460 Weatherby Magnum' =>    140,
    '.465 NE' =>                  144,
    '.470 NE' =>                  146,
    '.475 3.25 NE' =>             137,
    '.50-110' =>                  109,
    '.50 BMG' =>                  293,
    '12.7x99mm NATO' =>           293  # Same cartridge as '.50 BMG'
);

=head1 FUNCTIONS

=head2 cartridge_capacity (bullet_diameter_mm, base_diameter_mm, case_len_mm, psi, [want_powder_bool])

This function estimates the internal capacity (volume) of a rifle cartridge, assuming typical brass material construction.

It is not very accurate (+/- 6%) and actual volumes will vary between different manufacturers of the same cartridge anyway.

Its main advantage over a Powley calculator is ease of use, as it requires fewer and easier-to-obtain parameters.

Unlike the Powley calculator, it is only valid for typically-tapered rifle casings for calibers in the range of about 5mm to 14mm.

This function is the original work of the author.

DISCLAIMER:  Do not use this as a guide for handloading!  Get a Speer Reloading Manual or similar.  If you must use this function, start at least 15% lower than the function indicates and work your way up slowly.  Author is not responsible for idiots blasting copper case-bits into their own faces.

=over 4

parameter: (float) bullet_diameter_mm is the width of the bullet (in mm)

parameter: (float) base_diameter_mm is the width of the case at its base, NOT its rim (in mm)

parameter: (float) case_len_mm is the overall length of the case, including rim and neck (in mm)

parameter: (float) psi is the peak pressure tolerated by the cartridge (in psi)

parameter: (boolean) OPTIONAL: set want_powder_bool to a True value to approximate powder capacity instead of water capacity.  This is intrinsically inaccurate, since different powders have different weights, but it does okay for typical powders.

returns: (int) cartridge capacity (in grains)

=back

=cut

# Estimate the internal capacity (volume) of a rifle cartridge, assuming brass material.
# NOTES:
#     Not very accurate (+/- 6%), will vary between manufacturers
#     Only valid for tapered rifle casings for calibers around 5mm to 14mm.
#
sub cartridge_capacity {
    my ($bullet_diameter_mm, $base_diameter_mm, $case_len_mm, $psi, $want_powder_bool) = @_;
    die("mass_grains = cartridge_capacity(bullet_diameter_mm, base_diameter_mm, case_len_mm, max_pressure_psi[, want_powder_not_water])") unless(defined($psi));
    my $ff = ($bullet_diameter_mm / 5.56)**0.0585;
    my $capacity = $base_diameter_mm**2 * $case_len_mm * $psi * $ff / 8240000; # capacity in water
    $capacity *= 0.85 if ($want_powder_bool); # converts to approx capacity in powder.  "safe" load is about 5% lower than this.
    return int($capacity + 0.5);
}

=head2 empty_brass (bullet_diameter_mm, base_diameter_mm, case_len_mm, psi)

This function estimates the weight of an empty rifle cartridge, assuming typical brass material construction.  This is just the weight of the case metal, without primer, bullet, or powder.

It is moderately accurate, with the occasional winger, but actual weights will vary between different manufacturers of the same cartridge anyway.

Its main advantage over a Powley calculator is ease of use, as it requires fewer and easier-to-obtain parameters.

Unlike the Powley calculator, it is only valid for reasonably-tapered rifle casings for calibers in the range of about 5mm to 14mm.

This function is the original work of the author.

Compare to known dimensions and weights:

   5.56x45mm:  95 gr, empty_brass predicts  95 = 1.000 actual, 0.0% error
   7.62x39mm: 100 gr, empty_brass predicts 105 = 1.050 actual, 5.0% error
   6.8mm SPC: 107 gr, empty_brass predicts 100 = 0.935 actual, 6.5% error
   7.62x51mm: 182 gr, empty_brass predicts 181 = 0.995 actual, 0.5% error
   12.7x99mm: 847 gr, empty_brass predicts 830 = 0.980 actual, 2.0% error

=over 4

parameter: (float) bullet_diameter_mm is the width of the bullet (in mm)

parameter: (float) base_diameter_mm is the width of the case at its base, NOT its rim (in mm)

parameter: (float) case_len_mm is the overall length of the case, including rim and neck (in mm)

parameter: (float) psi is the peak pressure tolerated by the cartridge (in psi)

parameter: (boolean) OPTIONAL: set want_powder_bool to a True value to approximate powder capacity instead of water capacity.  This is intrinsically inaccurate, since different powders have different weights, but it does okay for typical powders.

returns: (int) cartridge weight (in grains)

=back

=cut

# Estimate the weight of an empty rifle cartridge, assuming brass material.
# NOTES:
#    Not very accurate (+/- 3% most cases), will vary between manufacturers.
#    Only valid for tapered rifle casings for calibers around 5mm to 14mm.
#
# compare to known dimensions and weights:
#   5.56mm NATO:  5.70 mm bullet diam,  9.58 mm base diam, 44.70 mm case len, 62366 psi,  95 grains (predicts 95  = 1.000)
#      6mm PPC:   6.17 mm bullet diam, 11.20 mm base diam, 38.50 mm case len, 55000 psi,  ?? grains (predicts 99  = ?,???)
#    6.8mm SPC:   7.00 mm bullet diam, 10.70 mm base diam, 42.60 mm case len, 52000 psi, 107 grains (predicts 100 = 1.070)
# 6.5x47mm Lapua: 6.71 mm bullet diam, 11.95 mm base diam, 47.00 mm case len, 63090 psi, ??? grains (predicts 166 = ?.???)
#   7.62mm NATO:  7.82 mm bullet diam, 11.94 mm base diam, 51.18 mm case len, 60200 psi, 182 grains (predicts 181 = 0.995)
#     .243 WSSM:  6.20 mm bullet diam, 14.10 mm base diam, 42.40 mm case len, 65000 psi, 212 grains (predicts 207 = 0.976)
#   12.7mm NATO: 12.90 mm bullet diam  20.40 mm base diam, 99.30 mm case len, 54800 psi, 847 grains (predicts 830 = 0.980)
# 
sub empty_brass {
    my ($bullet_diameter_mm, $base_diameter_mm, $case_len_mm, $psi) = @_;
    die("mass_grains = empty_brass(bullet_diameter, base_diameter_mm, case_len_mm, max_pressure_psi)") unless(defined($psi));
    my $bltf = abs($bullet_diameter_mm - 7.82) * 2.2;
    my $cvol = $base_diameter_mm**2 * ($case_len_mm - $bltf);
    return int($cvol * $psi / 2420484 + 0.5);
}

################### BEGIN functions used for gunfire()

# firespec2throw: trying to improve on spec2throw (qv) to account for 
# more physical factors.  Returns:
#   * the time taken to cross that distance in seconds,
#   * its velocity at that point in m/s, 
#   * its velocity in ft/s, 
#   * its kinetic energy in (kg*m**2)/(s**2).
# returns: ( $t, $vms, $vfs, $ke )
sub firespec2throw {
    my ($force, $brl_diam_mm, $brl_len_inches, $case_diam_mm, $case_len_mm, $mass_grains) = @_;
    # print ("firespec2throw:  force=$force  brl_diam_mm=$brl_diam_mm  brl_len_inches=$brl_len_inches case_diam_mm=$case_diam_mm  case_len_mm=$case_len_mm  mass_grains=$mass_grains\n");
    my $cdm_m = $case_diam_mm / 1000.0;
    my $cln_m = $case_len_mm  / 1000.0;
    my $bdm_m = $brl_diam_mm  / 1000.0;
    my $equiv_dist = (($case_diam_mm/$brl_diam_mm)**2) * $cln_m;
    my $mass_kg = $mass_grains / 15432.358;
    my $accel = $force / $mass_kg;
    # s = 1/2 at**2, so t = sqrt(2s/a)
    my $t = (2 * $equiv_dist / $accel)**0.5;
    # v = at
    my $vms = $accel * $t;
    # gain factor corrects observed error, which appears to be very nonlinearly proportional to bore diameter
    my $gain_factor = 0.866 * ($brl_diam_mm**0.093);
    $vms *= $gain_factor / ($case_len_mm / $brl_diam_mm)**0.5 * 2.77531;
    my $brl_diam_inches  = $brl_diam_mm  / 25.4;
    my $case_diam_inches = $case_diam_mm / 25.4;
    my $case_len_inches  = $case_len_mm  / 25.4;
    # this equation is normalized on l/d=55, so correct via powley():
    $vms *= powley ($brl_diam_inches, $case_diam_inches, $case_len_inches, $brl_diam_inches * 55, $brl_len_inches);
    # print ("firespec2throw: powley:   vms=$vms  brl_diam_inches=$brl_diam_inches  case_diam_inches=$case_diam_inches  case_len_inches=$case_len_inches  brl_diam_inches=$brl_diam_inches\n");
    # re-derive the time it would have taken to achieve this velocity:
    $t = $vms / $accel;
    my $vfs = $vms * 3.2808399;
    # energy = mass * velocity**2
    my $ke = 0.5 * $mass_kg * ($vms**2); # Joules
    # print ("firespec2throw: returning:   accel=$accel  t=$t  vms=$vms  vfs=$vfs  ke=$ke\n");
    return ($t, $vms, $vfs, $ke);
}

sub rndto { 
    my ( $x, $n ) = @_;
    my ( $ret );
    $ret = int(($x*(10**$n))+0.5) / (10**$n);
    if ( $n == 0 ) { return ( $ret ); }
    if ( $ret !~ /\./ ) { return ("$ret.".("0"x$n)); }
    while ( $ret !~ /\.../ ) { $ret .= '0'; }
    return ( $ret );
}

# spec2force(psi, diameter_mm)
# returns force generated when a cylinder of the given diameter is charged to
# the given pressure.
# Returns a float representing force in Newtons (ie, (kg*m)/(s**2)).  
sub spec2force {
    my ($psi, $diameter_mm) = @_;
    my ($area, $ret);
    # convert PSI to N/mm**2
    $psi /= 145;
    # calculate surface area from diameter
    $area = pi * (($diameter_mm / 2)**2);
    # calculate force
    $ret  = $psi * $area;
    return $ret;
}

sub fireglob {
    my ( $psi, $brl_diam_mm, $brl_len_inches, $case_diam_mm, $case_len_mm, $mass_gr ) = @_;
    my ( $t, $vms, $vfs, $ke ) = firespec2throw(spec2force($psi, $brl_diam_mm), $brl_diam_mm, $brl_len_inches, $case_diam_mm, $case_len_mm, $mass_gr );
    # print ("firespec2throw: t=$t vms=$vms vfs=$vfs ke=$ke\n");
    my $xvel = ($vms**2 / 2)**0.5;
    my $xt   = $xvel / 4.9;
    my $dis  = $vms * $xt;
    my $lob  = $dis;
    my $rng  = int ((($vms ** 1.5) / 2.5) + 0.5);
    $lob += $rng;
    $lob /= 2; # TODO: better formulation of $lob, taking sectional density into account
    $t   = rndto($t,6);
    $vms = rndto($vms,2);
    $vfs = rndto($vfs,2);
    $ke  = rndto($ke,0);
    $lob = rndto($lob,0);
    my $ret = {};
    $ret->{'tm'}  = $t;
    $ret->{'m/s'} = $vms;
    $ret->{'f/s'} = $vfs;
    $ret->{'N*m'} = $ke;
    $ret->{'r,m'} = $lob;
    return $ret;
}

=head2 gunfire (psi, bullet_diameter_mm, barrel_length_inches, cartridge_diameter_mm, cartridge_length_mm, bullet_mass_gr)

The gunfire function attempts to approximate the performance of a cartridge/bullet/barrel combination in terms of muzzle velocity (and some related attributes).

It does a tolerable job, despite grossly oversimplifying the problem.  Its principle charms are that it is easy to use, and there isn't much else available for solving this kind of problem.  Improving this function is on my to-do list.

This function is the original work of the author.

Compare to known cartridge/bullet/barrel performance:

    270 Winchester Short Magnum, 140gr, 24" barrel:
        actual velocity:     3250 ft/s
        gunfire() predicts:  3489 ft/s (7% error)

    .300 Lapua Magnum, 185gr, 27" barrel:
        actual velocity:     3300 ft/s
        gunfire() predicts:  3527 ft/s (6% error)

    .25-06 Remington, 120gr, 24" barrel:
        actual velocity:     2990 ft/s
        gunfire() predicts:  3056 ft/s (2% error)

    .308 Winchester, 150gr, 24" barrel:
        actual velocity:     2820 ft/s
        gunfire() predicts:  2840 ft/s (1% error)

    12.7x99mm NATO, 655gr, 45" barrel:
        actual velocity:     3029 ft/s
        gunfire() predicts:  3033 ft/s (0.1% error)

    .223 Remington, 55gr, 24" barrel:
        actual velocity:     3240 ft/s
        gunfire() predicts:  3170 ft/s (2% error)

    .30-06, 180gr, 24" barrel:
        actual velocity:     2700 ft/s
        gunfire() predicts:  2580 ft/s (5% error)

    .375 Ruger, 300gr, 23" barrel:
        actual velocity:     2660 ft/s
        gunfire() predicts:  2431 ft/s (9% error)

In particular, take the "r,m" output field with a huge grain of salt.  For a more accurate number, use Physics::Ballistics::External::flight_simulator().  The only advantage of "r,m" is that it is much much faster to derive (25 microseconds for gunfire(), vs an eighth of a second for flight_simulator() on my hardware).

=over 4

parameter: (float) peak chamber pressure (in psi, NOT cup!)

parameter: (float) bullet diameter (in mm)

parameter: (float) barrel length (in inches)

parameter: (float) cartridge base diameter (in mm)

parameter: (float) cartridge overall length (in mm)

parameter: (float) bullet mass (in grains)

returns: a reference to a hash, with the following fields:

    N*m: (int) muzzle energy (in joules)
    f/s: (float) muzzle velocity (in feet per second)
    m/s: (float) muzzle velocity (in meters per second)
    r,m: (int) approx range achieved when fired at a 45 degree angle (in meters)
    tm:  (float) time elapsed from ignition to bullet's egress from barrel (in seconds)

=back

=cut

sub gunfire {
    my ( $psi, $brl_diam_mm, $brl_len_inches, $cart_base_diam_mm, $cart_len_mm, $bullet_mass_gr, $minimize ) = @_;
    die("usage: psi, barrel diam mm, barrel len inches, cart diam mm, cart len mm, proj mass, [minimize]") unless (defined($bullet_mass_gr));
    my $res = fireglob($psi, $brl_diam_mm, $brl_len_inches, $cart_base_diam_mm, $cart_len_mm, $bullet_mass_gr);
    if (defined($minimize) && $minimize != 0) {
        delete ($res->{'N*m'});
        delete ($res->{'tm'} );
    }
    return $res;
}

################### END functions used for gunfire()

################### BEGIN functions used for ogival_volume

# Given a cone of a given base diameter and height, return its volume in cubic centimeters.
#
sub vcone {
    my ($base_mm, $ht_mm) = @_;
    my $base_cm   = $base_mm / 10;
    my $ht_cm     = $ht_mm   / 10;
    my $radius_cm = $base_cm / 2;
    my $volume    = pi * ($radius_cm**2) * $ht_cm / 3.0;
    return $volume;
}

# Given a truncated cone with a base diameter, a top diameter, and a distance between the two, return its volume in cubic centimeters.
#
sub vcone_trunc {
    my ($base_mm, $top_mm, $ht_mm) = @_;
    my $base_cm    = $base_mm / 10;
    my $top_cm     = $top_mm  / 10;
    my $ht_cm      = $ht_mm   / 10;
    my $radius1_cm = $base_cm / 2;
    my $radius2_cm = $top_cm  / 2;
    my $delta_x_cm = $radius1_cm - $radius2_cm;
    my $ht2_cm     = $ht_cm * ($radius2_cm / $delta_x_cm);
    my $ht1_cm     = $ht2_cm + $ht_cm;
    my $vcone_1    = vcone($radius1_cm * 20, $ht1_cm * 10);
    my $vcone_2    = vcone($radius2_cm * 20, $ht2_cm * 10);
    return $vcone_1 - $vcone_2;
}

# Given a distance (in mm) from the tip of a haak ogival nose shape, its overall length (in mm), its radius at its base (in mm), and its bluntness factor, return the area of its cross-section at that distance in square centimeters.
# NOTE: $x=0 is the TIP of the ogive, and $x=$len is the BASE
# qv: http://en.wikipedia.org/wiki/Nose_cone_design#Haack_series
# From that article:  "when C = 0, the notation LD signifies minimum drag for the given length and diameter, 
# and when C = 1/3, LV indicates minimum drag for a given length and volume.  The Haack series nose cones are 
# not perfectly tangent to the body at their base except for case where C = 2/3.  However, the discontinuity 
# is usually so slight as to be imperceptible.  For C > 2/3, Haack nose cones bulge to a maximum diameter 
# greater than the base diameter.  Haack nose tips do not come to a sharp point, but are slightly rounded."
# NOTE: To make best use of this function to reverse-engineer ogival-nose projectiles, it would be very nice
# to have a function which derived a best-fit value for C given a set of sample diameters at various distances
# from the nose tip.  TODO.
#
sub haak_ogive {
    my ($x, $len, $radius, $C) = @_; # valid range for $C is 0..2/3, and larger C make more blunt ogival nose.
    $C = 2/3 unless (defined($C));  # 2/3 seems to fit M791
    my $theta = acos(1-(2*$x/$len));
    my $y = $radius * ($theta - sin(2*$theta)/2 + $C * sin($theta)**3)**0.5 / pi**0.5;
    return $y;
}

=head2 ogival_volume (length_mm, radius_mm, [C,] [granularity_mm])

This function calculates the volume of a Haak-series ogival nose shape, as often used for areodynamically
streamlined projectiles.  It is useful (for instance) for determining the mass of a nose, when nose 
composition (and therefore density) is known.

qv: http://en.wikipedia.org/wiki/Nose_cone_design#Haack_series

Quoting from that article:

  While the series is a continuous set of shapes determined by the value of
  C in the equations below, two values of C have particular significance:
  when C = 0, the notation LD signifies minimum drag for the given length
  and diameter, and when C = 1/3, LV indicates minimum drag for a given
  length and volume.  The Haack series nose cones are not perfectly tangent
  to the body at their base except for case where C = 2/3.  However, the
  discontinuity is usually so slight as to be imperceptible.  For C > 2/3,
  Haack nose cones bulge to a maximum diameter greater than the base diameter.
  Haack nose tips do not come to a sharp point, but are slightly rounded.

=over 4

parameter: (float) the length of the ogive, from base to tip (in mm)

parameter: (float) the radius of the cross-section of the ogive (in mm)

parameter: (float) OPTIONAL: the sharpness factor of the ogive, higher values providing a more fat, blunt nose shape (in range 0..2/3, default=2/3)

parameter: (float) OPTIONAL: the granularity at which the volume will be calculated, lower values providing more accuracy but requiring more processing time (in mm, default=1/10000, provides < 0.1% error)

returns: (float) volume (in cc)

=back

=cut

# Given length, base radius, and bluntness factor of an ogival nose shape, returns its internal volume in cubic centimeters.
# NOTE: valid range for $C is 0..2/3, and larger C make more blunt ogival nose.
#
sub ogival_volume {
    my ($len_mm, $radius_mm, $C, $k) = @_;
    $C = 2/3     unless (defined($C));
    $k = 1/10000 unless (defined($k));
    my $volume_total = 0;
    my $prev_y = $radius_mm;
    for (my $x_mm = $k; $x_mm < $len_mm; $x_mm += $k) {
        my $y_mm = haak_ogive($x_mm, $len_mm, $radius_mm, $C);
        $volume_total += vcone_trunc(2*$prev_y, 2*$y_mm, $k);
        $prev_y = $y_mm;
    }
    return $volume_total;
}

################### END functions used for ogival_volume

=head2 powley (bore_diameter_inches, case_base_diameter_inches, case_length_inches, barrel_1_length_inches, barrel_2_length_inches)

This function implements Powley's formula for approximating the projectile velocity gained or lost from a change in barrel length.

Example of use:

    It is known that the muzzle velocity of a .223 Remington, 55gr bullet from a 24" barrel is 3240 ft/s.
    We want to know its muzzle velocity from a 16" barrel.

    powley (0.224, 0.378, 1.77, 24, 16) = 0.9205
    3240 ft/s * 0.9205 = 2982 ft/s

=over 4

parameter: (float) barrel's bore diameter (in inches)

parameter: (float) cartridge's base case diameter (in inches)

parameter: (float) cartridge's overall length (in inches)

parameter: (float) the length of the barrel for which muzzle velocity is known (in inches)

parameter: (float) the length of the barrel for which muzzle velocity is not known (in inches)

returns: (float) the ratio of the muzzle velocities (unitless)

=back

=cut

# $vms *= powley ($brl_diam_inches, $case_diam_inches, $case_len_inches, $brl_diam_inches * 55, $brl_len_inches);
sub powley {
    my ($barrel_diam_inches, $case_diam_inches, $case_len_inches, $blen1, $blen2) = @_;  # blen1 = original length, blen2 = new length
    die('powley(bore diam (inches), cart diam (inches), cart len (inches), brl len orig (inches), brl len new (inches))') unless (defined($blen2));
    # print ("powley: called:  barrel_diam_inches=$barrel_diam_inches  case_diam_inches=$case_diam_inches  case_len_inches=$case_len_inches  blen1=$blen1  blen2=$blen2\n");
    my $b_rad  = $barrel_diam_inches / 2;
    my $c_rad  = $case_diam_inches   / 2;
    my $c_vol  = ($c_rad**2) * $case_len_inches;
    my $b_vol  = ($b_rad**2) * $blen1;
    my $r1     = ($c_vol + $b_vol) / $c_vol;
       $b_vol  = ($b_rad**2) * $blen2;
    my $r2     = ($c_vol + $b_vol) / $c_vol;
    my $factor = ((1 - ($r2**(-0.25))) / (1-($r1**(-0.25)))) ** 0.5;
    # print ("powley: returning:  factor=$factor  b_rad=$b_rad  c_vol=$c_vol  b_vol=$b_vol  r1=$r1  r2=$r2\n");
    return $factor;
}

=head2 cup2psi_linear (cup[, want_range[, fractional_deviation]])

Approximates peak chamber pressure, in psi, given peak chamber CUP (copper crush test).  Since there is a degree of error present in both kinds of pressure tests, this will often disagree with published measurements.  To offset this, a range may be requested by passing a non-false second parameter.  This will cause three values to be returned:  A low-end psi estimate, the median psi estimate (which is the same as the value returned when called without a want_range parameter), and a high-end psi estimate.  The degree of variation may be adjusted by passing a value between 0 and 1 as the third argument (default is 0.05).

Based on linear formula from Denton Bramwell's _Correlating PSI and CUP_, with curve-fitting enhancements by module author.

=cut

sub cup2psi_linear {
    my ($cup, $want_range, $range_wobble) = @_;
    die("usage:\npeak_pressure_psi = cup2psi_linear(peak_pressure_cup)\n(low_peak_psi, median_peak_psi, high_peak_psi) = cup2psi_linear(peak_cup, 1[, fraction_variation])") unless (defined($cup));
    $want_range   = 0    unless (defined($want_range));
    $range_wobble = 0.05 unless (defined($range_wobble));
    my $median_psi = 1.51586 * $cup - 17902.0;
    return int($median_psi) unless ($want_range);
    my $low_wob  = 1.0 - $range_wobble;
    my $high_wob = 1.0 + $range_wobble;
    my $low_psi  = 1.51586 * ($low_wob  * $cup) - (17902.0 * $high_wob);
    my $high_psi = 1.51586 * ($high_wob * $cup) - (17902.0 * $low_wob);
    return (int($low_psi), int($median_psi), int($high_psi));
}

=head2 cup2psi (cup[, want_range[, fractional_deviation]])

Approximates peak chamber pressure, in psi, given peak chamber CUP (copper crush test).  Since there is a degree of error present in both kinds of pressure tests, this will often disagree with published measurements.  To offset this, a range may be requested by passing a non-false second parameter.  This will cause three values to be returned:  A low-end psi estimate, the median psi estimate (which is the same as the value returned when called without a want_range parameter), and a high-end psi estimate.  The degree of variation may be adjusted by passing a value between 0 and 1 as the third argument (default is 0.04).

Based on exponential formula from http://kwk.us/pressures.html, with enhancements by module author.

=cut

sub cup2psi {
    my ($cup, $want_range, $range_wobble) = @_;
    die("usage:\npeak_pressure_psi = cup2psi(peak_pressure_cup)\n(low_peak_psi, median_peak_psi, high_peak_psi) = cup2psi(peak_cup, 1[, fraction_variation])") unless (defined($cup));
    $want_range    = 0    unless (defined($want_range));
    $range_wobble  = 0.04 unless (defined($range_wobble));
    $cup /= 1000 unless ($cup < 100);  # Assuming user is providing CUP/1000, which is a common convention.
    my $median_psi = $cup * (1 + $cup**2.2 / 31000);  # NOTE: Original formula used 30000 here.  Adjusted it to be more accurate for common military cartridges.
    if ($cup > 60000) {
        $median_psi = $cup + ($cup - 20)**2.3 / 210;
    }
    return int($median_psi * 1000) unless ($want_range);
    my $low_wob  = 1.0 - $range_wobble;
    my $high_wob = 1.0 + $range_wobble;
    my $low_psi  = $cup * $low_wob  * (1 + ($cup * $low_wob )**2.2 / 31000);
    my $high_psi = $cup * $high_wob * (1 + ($cup * $high_wob)**2.2 / 31000);
    if ($cup > 60000) {
        $low_psi  = $cup * $low_wob  + (($cup - 20) * $low_wob )**2.3 / 210;
        $high_psi = $cup * $high_wob + (($cup - 20) * $high_wob)**2.3 / 210;
    }
    return (int($low_psi * 1000), int($median_psi * 1000), int($high_psi * 1000));
}

=head2 recoil_mbt (gun_mass_kg, projectile_mass_kg, projectile_velocity_mps, [gas_mass_kg,] [gas_velocity_mps,] [recoil_distance_cm,] [english_or_metric_str])

Approximates the recoil force of a battletank's large-bore main gun (or any other large-bore, high-velocity gun).

Based on formula from Ogorkiewicz's _Design and Development of Fighting Vehicles_, page 58.

As a rule of thumb, the recoil force of an MBT-proportioned vehicle's main gun should not exceed twice the vehicle's mass.

If combustion gas mass and velocity are absent, they will be estimated from the projectile mass and velocity.

The gun mass includes all of the parts moving against the vechicle's recoil mechanism (principally, the barrel and breech).

=over 4

parameter: (float) gun mass (in kg)

parameter: (float) projectile mass (in kg)

parameter: (float) projectile muzzle velocity (in meters per second)

parameter: (float) OPTIONAL: combustion gas mass, equal to the propellant mass, usually between one and one half the projectile mass (in kg)

parameter: (float) OPTIONAL: combustion gas velocity (in meters per second, usually 1450).

parameter: (float) OPTIONAL: recoil distance (in cm, default=20)

returns: (float) recoil force exerted on the vehicle (in tonnes)

=back

=cut

# Main gun recoil forces, lifted from Ogorkiewicz's _Design and Development of Fighting Vehicles_, page 58
# This should not exceed twice the vehicle's mass, or it might roll over when firing.
# Propellant mass and velocity will be estimated relative to projectile mass if not actually specified (TODO: factor in projectile velocity), but this will likely be somewhat inaccurate.
sub recoil_mbt
  {
    my ($w_g, $w_p, $v_p, $w_e, $v_e, $rl, $engmet) = @_;
    die ("usage: recoil (gun_mass, proj_mass, proj_vel, [gas_mass], [gas_vel], [recoil|{20 cm}], [units:{e,m}]") unless (defined ($v_p));
    $rl //= 20;
    $engmet //= 'm';
    my $gees = 32.1740486; # gravity in feet/second**2
    $rl   *= 0.032808399;  # converting cm to feet
    $w_p  *= 2.2046226;    # converting kg to pounds
    $v_p  *= 3.2808399;    # converting meters/second to feet/second
    $w_g  *= 2.2046226;    # converting kg to pounds
    if (defined($w_e)) {
        $w_e *= 2.2046226; # converting kg to pounds
    }
    else {
        $w_e = $w_p / 2.0;
    }
    if (defined($v_e)) {
        $v_e *= 3.2808399; # converting meters/second to feet/second
    }
    else {
        my $vp_1 = $v_p * 1.5;
        my $vp_2 = 3280.84;  # 1000 meters per second, in feet per second
        $v_e = $vp_1;
        $v_e = $vp_2 if ($vp_2 > $vp_1);
    }
#   print (" ((($w_p*$v_p)+($w_e*$v_e))**2) / (2*$gees*$w_g*$rl);\n");
    my $force = ((($w_p*$v_p)+($w_e*$v_e))**2) / (2*$gees*$w_g*$rl); # force, pounds
    if    ($engmet eq 'e') { $force /= 2000.0000; } # english measure: tons
    else                   { $force /= 2204.6226; } # metric measure: tonnes
    if    ($force <  10) { $force = int ($force * 100 + 0.5) / 100; }
    elsif ($force < 100) { $force = int ($force *  10 + 0.5) /  10; }
    else                 { $force = int ($force *   1 + 0.5) /   1; }
    return $force; # returns tons or tonnes
}

1;

=head1 TODO

The accuracy of these estimating functions can be improved, and I intend to improve them.

In particular, empty_brass should be made to take a "parent case" option, because it tends to underestimate the weight of cartridges which are based on other cartridges which have been trimmed or necked down.

=cut
