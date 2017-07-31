# perl-physics-ballistics
Internal, External, Terminal Ballistics Formulae, in Perl

Documentation follows for each of the three modules (Internal, External, Terminal), all appended together.  I'll figure out a nicer way to present this later.

# NAME

Physics::Ballistics::Internal -- Various internal ballistics formulae.

# ABSTRACT

Internal ballistics is the study of what happens while a projectile is being
launched from a barrel, from the time the propellant ignites to the moment
after the projectile leaves the muzzle.

This module implements a variety of functions and mathematical formulae useful
in the analysis and prediction of internal ballistic effects.

It also branches out somewhat into the closely-related matters of bullet and
cartridge composition and characteristics.

# REGARDING BULLET DIAMETERS

Some of these functions require the diameter of a projectile as a parameter.
Please note that bullet diameters are usually different from the names of
their calibers.  NATO 5.56mm bullets are actually 5.70mm in diameter, while
Russian 5.45mm bullets are actually 5.62mm.  .308 caliber bullets really are
0.308 inches in diameter (7.82mm), but .22 Long Rifle bullets are 0.222
inches across.

Making assumptions can hurt!  It's better to look it up before plugging it in.

# ANNOTATIONS OF SOURCES

Regarding their source, these functions fall into three categories:  Some are
simple encodings of basic physics (like energy = 1/2 \* mass \* velocity\*\*2),
and these will not be cited.  Others are from published works, such as books
or trade journals, and these will be cited when possible.  A few are products
of my own efforts, and will be thus annotated.

# OOP INTERFACE

A more integrated, object-oriented interface for these functions is under
development.

# CONSTANTS

## %CASE_CAPACITY_GRAINS

This hash table maps the names of various cartridges to their volumes, in grains of water.

It is based on the table at: http://kwk.us/cases.html

Powder capacities will vary considerably depending on powder type, but multiplying water capacity by 0.85 comes pretty close for most powder types.

# FUNCTIONS

## cartridge_capacity (bullet_diameter_mm, base_diameter_mm, case_len_mm, psi, \[want_powder_bool\])

This function estimates the internal capacity (volume) of a rifle cartridge, assuming typical brass material construction.

It is not very accurate (+/- 6%) and actual volumes will vary between different manufacturers of the same cartridge anyway.

Its main advantage over a Powley calculator is ease of use, as it requires fewer and easier-to-obtain parameters.

Unlike the Powley calculator, it is only valid for typically-tapered rifle casings for calibers in the range of about 5mm to 14mm.

This function is the original work of the author.

DISCLAIMER:  Do not use this as a guide for handloading!  Get a Speer Reloading Manual or similar.  If you must use this function, start at least 15% lower than the function indicates and work your way up slowly.  Author is not responsible for idiots blasting copper case-bits into their own faces.

> parameter: (float) bullet_diameter_mm is the width of the bullet (in mm)
>
> parameter: (float) base_diameter_mm is the width of the case at its base, NOT its rim (in mm)
>
> parameter: (float) case_len_mm is the overall length of the case, including rim and neck (in mm)
>
> parameter: (float) psi is the peak pressure tolerated by the cartridge (in psi)
>
> parameter: (boolean) OPTIONAL: set want_powder_bool to a True value to approximate powder capacity instead of water capacity.  This is intrinsically inaccurate, since different powders have different weights, but it does okay for typical powders.
>
> returns: (int) cartridge capacity (in grains)

## empty_brass (bullet_diameter_mm, base_diameter_mm, case_len_mm, psi)

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

> parameter: (float) bullet_diameter_mm is the width of the bullet (in mm)
>
> parameter: (float) base_diameter_mm is the width of the case at its base, NOT its rim (in mm)
>
> parameter: (float) case_len_mm is the overall length of the case, including rim and neck (in mm)
>
> parameter: (float) psi is the peak pressure tolerated by the cartridge (in psi)
>
> parameter: (boolean) OPTIONAL: set want_powder_bool to a True value to approximate powder capacity instead of water capacity.  This is intrinsically inaccurate, since different powders have different weights, but it does okay for typical powders.
>
> returns: (int) cartridge weight (in grains)

## gunfire (psi, bullet_diameter_mm, barrel_length_inches, cartridge_diameter_mm, cartridge_length_mm, bullet_mass_gr)

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

> parameter: (float) peak chamber pressure (in psi, NOT cup!)
>
> parameter: (float) bullet diameter (in mm)
>
> parameter: (float) barrel length (in inches)
>
> parameter: (float) cartridge base diameter (in mm)
>
> parameter: (float) cartridge overall length (in mm)
>
> parameter: (float) bullet mass (in grains)
>
> returns: a reference to a hash, with the following fields:
>
>     N*m: (int) muzzle energy (in joules)
>     f/s: (float) muzzle velocity (in feet per second)
>     m/s: (float) muzzle velocity (in meters per second)
>     r,m: (int) approx range achieved when fired at a 45 degree angle (in meters)
>     tm:  (float) time elapsed from ignition to bullet's egress from barrel (in seconds)

## ogival_volume (length_mm, radius_mm, \[C,\] \[granularity_mm\])

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

> parameter: (float) the length of the ogive, from base to tip (in mm)
>
> parameter: (float) the radius of the cross-section of the ogive (in mm)
>
> parameter: (float) OPTIONAL: the sharpness factor of the ogive, higher values providing a more fat, blunt nose shape (in range 0..2/3, default=2/3)
>
> parameter: (float) OPTIONAL: the granularity at which the volume will be calculated, lower values providing more accuracy but requiring more processing time (in mm, default=1/10000, provides < 0.1% error)
>
> returns: (float) volume (in cc)

## powley (bore_diameter_inches, case_base_diameter_inches, case_length_inches, barrel_1_length_inches, barrel_2_length_inches)

This function implements Powley's formula for approximating the projectile velocity gained or lost from a change in barrel length.

Example of use:

    It is known that the muzzle velocity of a .223 Remington, 55gr bullet from a 24" barrel is 3240 ft/s.
    We want to know its muzzle velocity from a 16" barrel.

    powley (0.224, 0.378, 1.77, 24, 16) = 0.9205
    3240 ft/s * 0.9205 = 2982 ft/s

> parameter: (float) barrel's bore diameter (in inches)
>
> parameter: (float) cartridge's base case diameter (in inches)
>
> parameter: (float) cartridge's overall length (in inches)
>
> parameter: (float) the length of the barrel for which muzzle velocity is known (in inches)
>
> parameter: (float) the length of the barrel for which muzzle velocity is not known (in inches)
>
> returns: (float) the ratio of the muzzle velocities (unitless)

## cup2psi_linear (cup\[, want_range\[, fractional_deviation\]\])

Approximates peak chamber pressure, in psi, given peak chamber CUP (copper crush test).  Since there is a degree of error present in both kinds of pressure tests, this will often disagree with published measurements.  To offset this, a range may be requested by passing a non-false second parameter.  This will cause three values to be returned:  A low-end psi estimate, the median psi estimate (which is the same as the value returned when called without a want_range parameter), and a high-end psi estimate.  The degree of variation may be adjusted by passing a value between 0 and 1 as the third argument (default is 0.05).

Based on linear formula from Denton Bramwell's _Correlating PSI and CUP_, with curve-fitting enhancements by module author.

## cup2psi (cup\[, want_range\[, fractional_deviation\]\])

Approximates peak chamber pressure, in psi, given peak chamber CUP (copper crush test).  Since there is a degree of error present in both kinds of pressure tests, this will often disagree with published measurements.  To offset this, a range may be requested by passing a non-false second parameter.  This will cause three values to be returned:  A low-end psi estimate, the median psi estimate (which is the same as the value returned when called without a want_range parameter), and a high-end psi estimate.  The degree of variation may be adjusted by passing a value between 0 and 1 as the third argument (default is 0.04).

Based on exponential formula from http://kwk.us/pressures.html, with enhancements by module author.

## recoil_mbt (gun_mass_kg, projectile_mass_kg, projectile_velocity_mps, \[gas_mass_kg,\] \[gas_velocity_mps,\] \[recoil_distance_cm,\] \[english_or_metric_str\])

Approximates the recoil force of a battletank's large-bore main gun (or any other large-bore, high-velocity gun).

Based on formula from Ogorkiewicz's _Design and Development of Fighting Vehicles_, page 58.

As a rule of thumb, the recoil force of an MBT-proportioned vehicle's main gun should not exceed twice the vehicle's mass.

If combustion gas mass and velocity are absent, they will be estimated from the projectile mass and velocity.

The gun mass includes all of the parts moving against the vechicle's recoil mechanism (principally, the barrel and breech).

> parameter: (float) gun mass (in kg)
>
> parameter: (float) projectile mass (in kg)
>
> parameter: (float) projectile muzzle velocity (in meters per second)
>
> parameter: (float) OPTIONAL: combustion gas mass, equal to the propellant mass, usually between one and one half the projectile mass (in kg)
>
> parameter: (float) OPTIONAL: combustion gas velocity (in meters per second, usually 1450).
>
> parameter: (float) OPTIONAL: recoil distance (in cm, default=20)
>
> returns: (float) recoil force exerted on the vehicle (in tonnes)

# TODO

The accuracy of these estimating functions can be improved, and I intend to improve them.

In particular, empty_brass should be made to take a "parent case" option, because it tends to underestimate the weight of cartridges which are based on other cartridges which have been trimmed or necked down.


# NAME

Physics::Ballistics::External -- External ballistics formulae.

# ABSTRACT

External ballistics is the study of projectiles in flight, from the time they
leave the barrel (or hand, or trebuchet, or whatever), to the moment before
they strike their target.  This module implements mathematical formulae and
functions useful in the analysis and prediction of external ballistic behavior.

# ANNOTATIONS OF SOURCES

Regarding their source, these functions fall into three categories:  Some are
simple encodings of basic physics (like energy = 1/2 \* mass \* velocity\*\*2),
and these will not be cited.  Others are from published works, such as books
or trade journals, and these will be cited when possible.  A few are products
of my own efforts, and will be thus annotated.

# OOP INTERFACE

A more integrated, object-oriented interface for these functions is under
development.

# FUNCTIONS

## ebc (mass_grains, diameter_inches, \[shape,\] \[form_factor\])

Attempts to predict the G1 ballistic coefficient of a projectile, based on its
mass, width, and shape.  Useful for predicting the ballistic behavior of
hypothetical or new, untested projectiles.  When compared against the known G1
BC's of well-understood projectiles, its predictions usually come within 5% of
actual.

The "shape" parameter indicates that the hypothetical projectile is closest in
its shape, composition, and quality of manufacture to the named entity.  Some
shapes are very general ("hollowpoint", "fmj") while others are very specific
to product families manufactured by particular companies ("scenar", "amax").

The "shape" parameter maps to a numerical form base (see table below), which
gets tweaked a little by other factors to derive a form factor.  The form
factor has an inverse impact on ballistic coefficient (higher form factor
means a lower coefficient).  In lieu of depending on the "shape" parameter, a
form factor may be specified as a parameter (mostly useful for debugging or
deriving new entries in the shape table).

When no shape or form factor are provided, the "default" shape is used, which
has a form base chosen to minimize the error produced by this function when
its output is compared to entries in http://www.frfrogspad.com/g1bclist.xls
not already covered in the shape table.

A hashfile including all of the information from g1bclist.xls with "shape"
entries matching the names from the shape table below may be found here:
http://ciar.org/ttk/mbt/guns/table.bc.hash

This function is the original work of the module's author.

> parameter: (float) mass of the projectile (in grains)
>
> parameter: (float) diameter of the projectile (in inches)
>
> parameter: (str) OPTIONAL: shape/composition of the projectile (see table below, default is "default")
>
> parameter: (float) OPTIONAL: custom form-factor of the projectile, unnecessary if "shape" is provided.
>
> returns: a list, containing the following values:
>
>     * The estimated G1 ballistic coefficient,
>     * The form factor (suitable for use as as form_factor parameter)
>     * The "very short factor" (1.0 for most well-proportioned bullets)
>     * The shape parameter used

The shape table currently contains the following entities, with the given form bases:

    '7n14'              => 111, # Very deep ogival shape and boat-tail with tight tolerances, used in military 7.62x54R specifically for sniping.
    'scenar'            => 124, # Scenar, by Lapua
    'scenar_s'          => 124, # Scenar Silver, by Lapua, appears ballistically indistinguishable from Scenar
    '7n1'               => 125, # Very deep ogival shape and boat-tail, used in military 7.62x54R.  qv http://7.62x54r.net/MosinID/MosinAmmo007.htm
    '7n6'               => 125, # Very deep ogival shape and boat-tail, used in military 5.45x39mm  qv http://7.62x54r.net/MosinID/MosinAmmo007.htm
    '7n6m'              => 125, # Synonym for 7N6
    'amax'              => 127, # A-Max, by Hornady
    'boat_tail_og'      => 128, # Catch-all for many boat-tailed projectiles with long, pointed ogival nose shapes
    'hollowpoint_ct'    => 131, # CT variation of hollowpoint "match" projectiles, by Nosler
    'bst'               => 136, # A type of flat-bottomed ogival, by Nosler
    'spire_point'       => 138, # A type of flat-bottomed ogival, by Speer
    'boat_tail_nosler'  => 138, # Nosler's line of boat-tails perform more poorly than others for some reason
    'boat_tail_ct'      => 139, # Nosler's CT variation of boat-tail
    'spitzer'           => 139, # Another flat-bottomed ogival, by Speer.  Good fit to many military bullets.
    'hollowpoint_match' => 140, # Catch-all for many hollowpoint "match" projectiles
    'accubond'          => 142, # An expansive line by Nosler offering controlled terminal expansion
    'interbond'         => 142, # A line of polymer-tipped bullets by Hornady optimized for terminal cohesion
    'vmax'              => 145, # A line of polymer-tipped bullets by Hornady optimized for terminal expansion / fragmentation
    'gold_match'        => 147, # A type of wadcutter, by Speer
    'grand_slam'        => 159, # Another wadcutter, by Speer, with less streamlined nose shape for higher overall mass
    'hollowpoint'       => 176, # Catch-all for many large-game hollowpoint projectiles
    'default'           => 179, # Catch-all for unknown/unspecified shapes; derived via best-fit to ballistic table
    'fmj'               => 187, # Catch-all for military full metal jacket with boat-tail and short nose
    'mag_tip'           => 190, # Another wadcutter, by Speer
    'afss'              => 202,
    'tsx_fb'            => 205, 
    'plinker'           => 205, # Typical of short, underweight, round-nosed, non-streamlined projectiles,
    'semispitzer'       => 224, # A foreshortened, flat-bottomed projectile, by Speer
    'round_nose'        => 228, # Catch-all for many flat-bottomed, hemispherical-nosed projectiles
    'varminter'         => 232, # Catch-all for many light hollowpoints with very large expanding cavities, for varminting
    'fmj_2'             => 268  # Woodleigh's FMJ projectiles, which are shape-optimized for travel in big game meat and bone, instead of air.

This hash table is exported as %Physics::Ballistics::External::Bullet_Form_Factors_H,
so that users and modules may easily modify/add its content without resorting
to editing sources.

## flight_simulator (drag_function, ballistic_coefficient, muzzle_velocity_fps, sight_height_inches, shot_angle_deg, \[bore_to_sight_angle_deg,\] zero_range_yards, wind_speed_fps, wind_angle_deg, \[max_range_yards\])

Attempts to predict the flight characteristics of a projectile in flight, providing a data point for every yard of progress it makes downrange.

This is a pure-perl port of the "SolveAll" function from GNU-Ballistics gebc-1.07 lib/ballistics/ballistics.cpp, and as slow as one might expect from a pure-perl port of an arithmetic-intensive algorithm.

On my system it takes about an eighth of a second to simulate a 1200-yard flight.  This may be supplemented at some point with an Inline::C equivalent.

Note that most manufacturers report G1 ballistic coefficients.  Using the wrong drag function for a given ballistic coefficient will produce ludicrously incorrect results.

To ascertain the correct bore elevation to hit a target at a specific distance, change the shot_angle_deg parameter on successive calls to flight_simulator(), and converge on drop_inches == 0.0 at the given range via binary search.  I should get around to providing a function for that at some point (GNU-Ballistics has such a function, I just didn't port it).

> parameter: (str) drag_function is exactly one of: 'G1', 'G2', 'G5', 'G6', 'G7', 'G8'.
>
> parameter: (float) ballistic_coefficient, qv: http://en.wikipedia.org/wiki/Ballistic_coefficient
>
> parameter: (float) muzzle_velocity_fps is the velocity of the projectile at time=0 (feet per second)
>
> parameter: (float) sight_height_inches is the distance from the center of the sight to the center of the bore (inches)
>
> parameter: (float) shot_angle_deg is the bore elevation (degrees, 0 = horizontal, 90 = vertical)
>
> parameter: (float) OPTIONAL: bore_to_sight_angle_deg is the difference in angle between the bore elevation and the sight elevation.  Set to undef or -1 to have flight_simulator() calculate it for you from the zero_range_yards parameter (degrees)
>
> parameter: (float) wind_speed_fps is the velocity of the wind (feet per second)
>
> parameter: (float) wind_angle_deg is the direction the wind is blowing (degrees, 0 = shooting directly into wind, 90 = wind is blowing from the right, perpendicular to flight path, -90 = wind is blowing from the left, perpendicular to flight path)
>
> parameter: (float) OPTIONAL: max_range_yards is the maximum range to which the flight will be simulated (yards, default is 2000)
>
> returns: a reference to an array of hash references, one per yard, denoting the projectile's disposition when it reaches that range.  All data fields are floating-point numbers:
>
>     range_yards     How far downrange the projectile has travelled, in yards.
>     drop_inches     How far below the horizontal plane intersecting the muzzle the projectile has travelled, in inches.
>     correction_moa  The angle from the muzzle to the projectile in the vertical plane, relative to the path from the muzzle to the target, in minutes.
>     time_seconds    How much time has elapsed since leaving the muzzle, in seconds.
>     windage_inches  How far in the horizontal plane the projectile has moved due to wind, in inches.
>     windage_moa     The angle from the muzzle to the projectile in the horzontal plane, relative to the path from the muzzle to the target, in minutes.
>     vel_fps         The velocity of the projectile, in feet per second.
>     vel_horiz_fps   The horizontal component of the velocity of the projectile, in feet per second.
>     vel_vert_fps    The vertical component of the velocity of the projectile, in feet per second.

## g1_drag (velocity_fps)

The canonical function for computing instantaneous velocity drop at a given velocity, per the G1 drag model.

> parameter: (float) velocity_fps is the velocity of the projectile (in feet per second)
>
> returns: (float) the deceleration of the projectile from drag (in feet per second per second)

## muzzle_energy (mass_grains, velocity_fps, \[want_joules_bool\])

A convenience function for computing kinetic energy from mass and velocity.
Despite its name, it is useful for computing the kinetic energy of a projectile
at any point during its flight.

> parameter: (float) mass_grains is the mass of the projectile (in grains)
>
> parameter: (float) velocity_fps is the velocity of the projectile (in feet per second)
>
> parameter: (boolean) OPTIONAL: set want_joules_bool to a True value to get Joules instead of foot-pounds (boolean, default=False)
>
> returns: (float) the kinetic energy of the projectile (in foot-pounds or Joules)

## muzzle_velocity_from_energy (mass_grains, energy_ftlbs)

A convenience function for computing velocity from mass and kinetic energy.
Despite its name, it is useful for computing the velocity of a projectile
at any point during its flight.

If all you have is Joules, divide by 1.3558179 to get foot-pounds.

> parameter: (float) mass_grains is the mass of the projectile (in grains)
>
> parameter: (float) energy_ftlbs is the kinetic energy of the projectile (in foot-pounds)
>
> returns: (float) the velocity of the projectile (in feet per second)

# TODO

Contact Geoffrey Kolbe (Inventor at Border Barrels Limited) and ask for permission to publish his splendid implementations:

    * Bullet drag calculator - http://www.border-barrels.com/cgi-bin/drag_working.cgi

    * Barrel weight calculator - http://www.border-barrels.com/cgi-bin/swamped_barrel_weight.cgi

His drag calculator seems better than my own ebc function.


# NAME

Physics::Ballistics::Terminal -- Terminal ballistics formulae.

# ABSTRACT

Terminal ballistics is the study of what happens when a projectile impacts
its target.  This module implements a variety of functions and mathematical
formulae useful in the analysis and prediction of terminal ballistic effects.

# TWO DOMAINS OF VELOCITY

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

# REGARDING BULLET DIAMETERS

Some of these functions require the diameter of a projectile as a parameter.
Please note that bullet diameters are usually different from the names of
their calibers.  NATO 5.56mm bullets are actually 5.70mm in diameter, while
Russian 5.45mm bullets are actually 5.62mm.  .308 caliber bullets really are
0.308 inches in diameter (7.82mm), but .22 Long Rifle bullets are 0.222
inches across.  Please do not make assumptions; check before plugging it in!

# DEFINITIONS

## DU

DU is short for "Depleted Uranium".  This denotes any of a number of metallic
alloys containing a high fraction of Uranium, the most common of which is
99.25% Uranium and and 0.75% Titanium.  This material is extremely dense and
hard, and somewhat ductile, making it excellent for armor-piercing projectiles.
Contrary to popular myth, DU projectiles are not "nuclear" and do not explode,
though in the hypervelocity domain they can be pyrophoric.  Nor is DU highly
radioactive.  It is, however, a heavy metal (like lead, mercury, and arsenic)
and therefore toxic.

## MILD STEEL

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

## RHA

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

## WC

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

## WHA

WHA is short for "Tungsten-Heavy Alloy".  This denotes any of several metallic
alloys containing a high fraction of Tungsten.  Some formulations offer high
density, hardness and resilience (such as 90% W / 7% Ni / 3% Fe) making them
excellent materials for armor-piercing projectiles.  Unlike WC, appropriate WHA
formulations are not brittle, and are unlikely to break from passing through
composite armor systems.

# ANNOTATIONS OF SOURCES

Regarding their source, these functions fall into three categories:  Some are
simple encodings of basic physics (like energy = 1/2 \* mass \* velocity\*\*2),
and these will not be cited.  Others are from published works, such as books
or trade journals, and these will be cited when possible.  A few are products
of my own efforts, and will be thus annotated.

# OOP INTERFACE

A more integrated, object-oriented interface for these functions is under
development.

# FUNCTIONS

## anderson (length_cm, diam_cm, vel_kps, \[penetrator_material,\] \[deg_angle,\] \[scaling_factor\])

Attempts to estimate how deeply a long-rod projectile will penetrate into RHA (semi-infinite penetration).

This function is based on Anderson's _Accuracy of Perforation Equations_, less 11% correction per that paper's conclusions, and including adjustments from Lakowski for scale, material, and backsurface effects.
qv: http://208.84.116.223/forums/index.php?showtopic=10482&st=110

ONLY VALID IN HYPERVELOCITY DOMAIN.

> parameter: (float) penetrator length (in cm)
>
> parameter: (float) penetrator diameter (in cm)
>
> parameter: (float) penetrator velocity (in kilometers per second)
>
> parameter: (float or string) OPTIONAL: penetrator material or material multiplier.  (defaults to 1.0)  Valid values are:
>
> > \* an integer, for custom material factors
> >
> > \* "steel": Hardened steel == 0.50
> >
> > \* "wha": Tungsten-heavy alloy (NOT tungsten carbide) == 1.00
> >
> > \* "wc": Tungsten Carbide == 0.72
> >
> > \* "du":  Depleted uranium alloy == 1.13
>
> parameter: (float) OPTIONAL: angle of impact, 0 == perpendicular to target surface (in degrees, defaults to 0)
>
> parameter: (float) OPTIONAL: scaling effect, relative to M829A2 dimensions (unitless, defaults to 1.0)
>
> returns: (float) Depth of penetration (in cm)

## boxes (length, width, height, front thickness, back thickness, side thickness, top thickness, underside thickness, density)

Calculates the volumes, mass, and volume-to-mass ratio of a hollow box of rectangular cross-sections.

> parameter: (float) interior distance from front to back (in cm)
>
> parameter: (float) interior distance from left to right (in cm)
>
> parameter: (float) interior distance from top to bottom (in cm)
>
> parameter: (float) thickness of front wall (in cm)
>
> parameter: (float) thickness of back wall (in cm)
>
> parameter: (float) thickness of side walls (in cm)
>
> parameter: (float) thickness of bottom wall (in cm)
>
> parameter: (float) specific density of wall material (g/cc)
>
> returns:
>
> > \* (float) interior volume (in cc)
> >
> > \* (float) exterior volume (in cc)
> >
> > \* (float) total wall mass (in grams)
> >
> > \* (float) ratio of interior volume to mass (cc/g)

## heat_dop(diameter_mm, standoff_distance, \[target_density,\] \[precision_bool\], \[target_hardness_bhn\])

Attempts to predict the depth of penetration of a copper-lined conical shaped charge into steel.

Based on Ogorkiewicz's book, _Design and Development of Fighting Vehicles_, and
modified as per _Journal of Battlefield Technology_ Vol 1-1 pp 1.  A copy of 
the JBT chart may be found at:

http://ciar.org/ttk/mbt/news/news.smm.ww2-armor-plate.de5bf54f.0110271532.871cbf@posting.google.com.txt

The author has modified this formula slightly to account for errors observed in
Ogorkiewicz's results, relative to empirically derived results.

For better understanding of shaped charge penetration, please review:

http://www.globalsecurity.org/military/systems/munitions/bullets2-shaped-charge.htm

> parameter: (float) cone diameter (in mm)
>
> parameter: (float or str) standoff distance (multiple of cone diameter if float, else in mm, for instance "80.5mm")
>
> parameter: (float) OPTIONAL: density of target material (in g/cc, default is 7.86, the density of RHA)
>
> parameter: (boolean) OPTIONAL: assume precision shaped charge (default is False)
>
> parameter: (float) OPTIONAL: hardness of target material (in BHN, default is 300, low in the range of RHA hardnesses)
>
> returns: (int) depth of penetration (in mm)

## me2te (mass_efficiency, density)

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

> parameter: (float) armor material mass efficiency (unitless, factor relative to RHA)
>
> parameter: (float) armor material density (g/cc)
>
> returns: (float) armor material thickness efficiency (unitless, factor relative to RHA)

## me2ce (mass_efficiency, cost_usd_per_pound)

Given the mass efficiency of a material, returns its cost efficiency.

See the description of me2te() for more explanation.

This actually returns the cost efficiency relative to AISI 4340 steel, which is
often used as a close approximation to RHA.  The costs of actual MIL-A-12560
compliant steel are dominated by political factors, which are beyond the scope
of this module.

> parameter: (float) armor material mass efficiency (unitless, factor relative to RHA)
>
> parameter: (float) armor material cost (USA dollars / pound)
>
> returns: (float) armor material cost efficiency (unitless, factor relative to RHA)

## me2cem (mass_efficiency, cost_usd_per_pound)

Given the mass efficiency of a material, returns its cost efficiency relative to mild steel.

See the description of me2ce() for more explanation.

> parameter: (float) armor material mass efficiency (unitless, factor relative to RHA)
>
> parameter: (float) armor material cost (USA dollars / pound)
>
> returns: (float) armor material cost efficiency (unitless, factor relative to mild steel)

## odermatt (length_cm, diam_cm, vel_mps, target_density, target_uts_kpsi, rod_density, deg_angle, kps_drop_per_km, range_km, target_thickness_cm, \[tip_length_cm, kA1, kA2\])

Attempts to estimate perforation limit for a long-rod projectile penetrating RHA.  Produces more accurate results than Anderson, but also requires more hard-to-get information, and doesn't exactly measure the same thing (perforation limit, vs depth into semi-infinite target).

This function is based on Lanz and Odermatt's paper _Post Perforation Length & Velocity of KE Projectiles with single Oblique Targets_, published in the 15th International Symposium of Ballistics.

ONLY VALID IN HYPERVELOCITY DOMAIN.

Only valid for penetrator length/diameter ratios of 10.0 or higher, unless kA1 and kA2 are provided (which afaik can only be derived empirically, so good luck).

> parameter: (float) penetrator length (in cm)
>
> parameter: (float) penetrator diameter (in cm)
>
> parameter: (float) penetrator velocity (in meters per second)
>
> parameter: (float) target density (in g/cc)
>
> parameter: (float) target ultimate tensile strength (in kpsi)
>
> parameter: (float) penetrator density (in g/cc)
>
> parameter: (float) angle of impact (in degrees, 0 == perpendicular to target surface)
>
> parameter: (float) target thickness (in cm)
>
> parameter: (float) OPTIONAL: penetrator tip length (in cm, defaults to three times penetrator diameter)
>
> parameter: (float) OPTIONAL: kA1 empirically discovered constant (only required for L/D < 10.0)
>
> parameter: (float) OPTIONAL: kA2 empirically discovered constant (only required for L/D < 10.0)
>
> returns: (float) Target's perforation limit (in cm)

## pc (mass_grains, velocity_fps, distance_feet, diameter_inches, bullet_shape_str, \[target_material\])

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

> parameter: (float) penetrator mass (in grains)
>
> parameter: (float) penetrator velocity (in feet per second)
>
> parameter: (float) distance between muzzle and target (in feet)
>
> parameter: (float) penetrator diameter (in inches)
>
> parameter: (string) penetrator type, describing very approximately the general shape and composition of the projectile.  Valid values are:
>
> > \* "hp":  Hollowpoint, composed of thin brass lining over lead core.
> >
> > \* "sp":  Softpoint (exposed lead tip), composed of thin brass lining over lead core.
> >
> > \* "bp":  FMJ "ball", composed of thin brass lining over lead core.
> >
> > \* "ms":  Mild steel core, with ogival nose shape.
> >
> > \* "sc":  Hard steel core, with truncated-cone nose shape.
> >
> > \* "hc":  Synonym for "sc".
> >
> > \* "tc":  Tungsten-carbide core (not WHA), with truncated-cone nose shape.
> >
> > \* "wc":  Synonym for "tc".
> >
> > \* "wha": Tungsten heavy alloy core (eg, 90% W / 7% Ni / 3% Fe), with truncated-cone nose shape.
> >
> > \* "du":  Depleted uranium alloy core (99.25% U / 0.75% Ti), with truncated-cone nose shape.
> >
> > The hash table mapping these type strings to their numeric penetration factors is available as %Physics::Ballistics::Terminal::Penetrator_Types_H, for ease of reference and modification.
>
> parameter: (OPTIONAL) (string) target material.  Valid target materials are:
>
> > \* "pine":  Soft, green pine wood.
> >
> > \* "sand":  Loose-packed, dry sand.
> >
> > \* "brick":  Typical firebrick, as often used in residential exterior wall construction.
> >
> > \* "cinder":  Cinderblock, as often used in inexpensive non-residential exterior wall construction.
> >
> > \* "concrete":  Reinforced concrete, poured-in-place.
> >
> > \* "mild":  Mild steel, as often used in civilian construction or automotive body manufacture.
> >
> > \* "hard":  Hardened steel of at least 250BHN, akin to RHA.
>
> returns: (float) estimated depth of penetration (in mm), rounded to the nearest tenth of a mm.

## pc_simple (mass_grains, velocity_fps, diameter_inches, shape_str)

Simple penetration calculator.  Attempts to estimate how deeply a small-arms projectile
will penetrate into RHA.  Optimized for projectiles near 7.5mm in diameter, works okay
for projectiles as small as 5mm or as large as 14mm.

This function is the original work of the author.

ONLY VALID IN BALLISTIC DOMAIN.

Not recommended for masses outside 55..450 grains range,

Not recommended for velocities outside 1200..3500 fps range,

Not recommended for unjacketed lead projectiles.

> parameter: (float) penetrator mass (in grains)
>
> parameter: (float) penetrator velocity (in feet per second)
>
> parameter: (float) penetrator diameter (in inches)
>
> parameter: (string) penetrator type, describing very approximately the general shape and composition of the projectile.  Valid values are:
>
> > \* "hp":  Hollowpoint, composed of thin brass lining over lead core.
> >
> > \* "sp":  Softpoint (exposed lead tip), composed of thin brass lining over lead core.
> >
> > \* "bp":  FMJ "ball", composed of thin brass lining over lead core.
> >
> > \* "ms":  Mild steel core, with ogival nose shape.
> >
> > \* "sc":  Hard steel core, with truncated-cone nose shape.
> >
> > \* "hc":  Synonym for "sc".
> >
> > \* "tc":  Tungsten-carbide core (not WHA), with truncated-cone nose shape.
> >
> > \* "wc":  Synonym for "tc".
> >
> > \* "wha": Tungsten heavy alloy core (eg, 90% W / 7% Ni / 3% Fe), with truncated-cone nose shape.
> >
> > \* "du":  Depleted uranium alloy core (99.25% U / 0.75% Ti), with truncated-cone nose shape.
> >
> > The hash table mapping these type strings to their numeric penetration factors is available as %Physics::Ballistics::Terminal::Penetrator_Types_H, for ease of reference and modification.
>
> parameter: (OPTIONAL) (string or float) thickness efficiency of target material (as ratio to RHA).  Defaults to 1.0 (target is RHA).
>
> returns: (float) estimated depth of penetration into RHA (in mm), rounded over to the nearest tenth of a mm.

## hits_score (mass_grains, velocity_fps, diameter_inches)

Computes a projectile's Hornady Index of Terminal Standards (H.I.T.S.) score, an 
approximation of its lethality.

Personally I think H.I.T.S. severely over-emphasizes bullet mass (the score is 
proportional to the SQUARE of the bullet mass, times velocity, divided by bullet 
sectional area).  It is included here anyway because there are no really good 
lethality models, and many big-game hunters like H.I.T.S. (and it is possible 
that bullet mass really is that important when taking down very large animals).

See also:

http://www.hornady.com/hits

http://www.hornady.com/hits/calculator

> parameter: (float) projectile mass (in grains)
>
> parameter: (float) projectile velocity (in feet per second)
>
> parameter: (float) projectile diameter (in inches)
>
> returns: (integer) lethality (HITS score, qv table in http://www.hornady.com/hits)

## poncelet(diameter_mm, mass_grains, velocity_fps, target_shear_strength_psi, target_density)

Jean-Victor Poncelet was one of the first to attempt mathematical models of
depth of penetration.  His formula, developed in the 19th century, attempts
to predict the penetration of bullets into flesh-like materials.  It is not
very good, failing to take into account such factors as bullet nose shape,
bullet tumbling within the target, and impacts with bone, horn, or cartilage.

ONLY VALID IN BALLISTIC DOMAIN.

> parameter: (float) penetrator diameter (in mm)
>
> parameter: (float) penetrator mass (in grains)
>
> parameter: (float) penetrator velocity (in feet per second)
>
> parameter: (float) target material shearing strength (in PSI)
>
> parameter: (float) target density (in g/cc)
>
> returns: (int) depth of penetration (in mm)

## te2me (thickness_efficiency, density)

Given the mass efficiency of a material, returns its thickness efficiency.

See the description of me2te() for more explanation.

> parameter: (float) armor material thickness efficiency (unitless, factor relative to RHA)
>
> parameter: (float) armor material density (g/cc)
>
> returns: (float) armor material mass efficiency (unitless, factor relative to RHA)

## lethality (grains, velocity_fps)

Approximates the lethality of a projectile impacting a living creature.

`THIS FUNCTION IS A WORK IN PROGRESS` and currently extremely simple.

Its parameters and output are likely to change in incompatible ways in future releases.

> parameter: (integer) projectile weight (in grains)
>
> parameter: (integer) projectile velocity (in feet/second)
>
> returns: (float) lethality relative to 5.56x45mm at point blank range.

## hv2bhn (hardness_vickers)

Given a Vickers hardness rating, approximates the equivalent Brinell Hardness Number (via 10/3000 WC method).

Vickers can be converted to other hardness ratings by first converting to BHN, and then converting from BHN to the desired hardness rating.

> parameter: (integer) Vickers Hardness rating
>
> returns: (float) Brinell Hardness Number (BHN)

## bhn2hv (brinell_hardness_number)

Given a Brinell Hardness Number hardness rating (via 10/3000 WC method), approximates the equivalent Vickers Hardness rating.

> parameter: (integer) Brinell Hardness Number (BHN)
>
> returns: (float) Vickers Hardness rating

## hrc2bhn (rockwell_hardness_C)

Given a Rockwell Hardness C rating, approximates the equivalent Brinell Hardness Number (via 10/3000 WC method).

HRC can be converted to other hardness ratings by first converting to BHN, and then converting from BHN to the desired hardness rating.

> parameter: (integer) Rockwell Hardness C, valid ONLY in the range 15..65.
>
> returns: (float) Brinell Hardness Number (BHN)

## bhn2hrc (brinell_hardness_number)

Given a Brinell Hardness Number hardness rating (via 10/3000 WC method), approximates the equivalent Rockwell Hardness C rating.

Approximation is accurate to within 5% near the low end, 2% everywhere else.

> parameter: (integer) Brinell Hardness Number (BHN), valid ONLY in the range 200..770
>
> returns: (float) Rockwell Hardness C rating

## psi2bhn (pounds_per_square_inch)

Given the ultimate tensile strength of a steel formulation in PSI, approximates the equivalent Brinell Hardness Number (via 10/3000 WC method).

Steel UTS PSI can be converted to other hardness ratings by first converting to BHN, and then converting from BHN to the desired hardness rating.

Approximation is accurate to within 2%.

> parameter: (integer) Pounds per square inch
>
> returns: (float) Brinell Hardness Number (BHN)

## bhn2psi (brinell_hardness_number)

Given a Brinell Hardness Number hardness rating (via 10/3000 WC method), approximates the equivalent steel ultimate tensile strength in pounds per square inch.

Approximation is accurate to within 2%.

> parameter: (integer) Brinell Hardness Number (BHN)
>
> returns: (float) Steel ultimate tensile strength (psi)

# TODO

The pc function needs a lot of improvement.

Need a pc function for larger penetrators (for the ballistic domain, as anderson and odermatt suffices for hypervelocity domain).

The stabilization_distance_meters function should take projectile composition into account.

To be really useful the lethality function needs to take wobble, fragmentation and permanent wound cavity volume into account (per Fackler).

The hardness unit conversion functions should be based on Vickers, not Brinell, as Vickers has the wider valid range.

