package Physics::Ballistics::External;
use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(ebc flight_simulator g1_drag muzzle_energy muzzle_velocity_from_energy);
our $VERSION = '1.03';

use Math::Trig qw(tan asin acos atan pi);
use Physics::Ballistics;

=head1 NAME

Physics::Ballistics::External -- External ballistics formulae.

=head1 ABSTRACT

External ballistics is the study of projectiles in flight, from the time they
leave the barrel (or hand, or trebuchet, or whatever), to the moment before
they strike their target.  This module implements mathematical formulae and
functions useful in the analysis and prediction of external ballistic behavior.

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

=head2 ebc (mass_grains, diameter_inches, [shape,] [form_factor])

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

=over 4

parameter: (float) mass of the projectile (in grains)

parameter: (float) diameter of the projectile (in inches)

parameter: (str) OPTIONAL: shape/composition of the projectile (see table below, default is "default")

parameter: (float) OPTIONAL: custom form-factor of the projectile, unnecessary if "shape" is provided.

returns: a list, containing the following values:

    * The estimated G1 ballistic coefficient,
    * The form factor (suitable for use as as form_factor parameter)
    * The "very short factor" (1.0 for most well-proportioned bullets)
    * The shape parameter used

=back

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

=cut

our %Bullet_Form_Factors_H = (
    '7n14'              => 111, # Very, very deep ogival shape and boat-tail with tight tolerances, used in military 7.62x54R specifically for sniping.
    '7n10'              => 118, # 7n6 with enhanced penetration and different weight distribution
    'scenar'            => 124, # Scenar, by Lapua
    'scenar_s'          => 124, # Scenar Silver, by Lapua, appears ballistically indistinguishable from Scenar
    '7n1'               => 125, # Russian boat-tail military bullet with very, very deep ogival shape
    '7n6'               => 125, # Russian boat-tail military bullet with very, very deep ogival shape
    '7n6m'              => 125, # Synonym for 7N6
    'amax'              => 127, # A-Max, by Hornady
    'boat_tail_og'      => 128, # Catch-all for many boat-tailed projectiles with long, pointed ogival nose shapes
    'hollowpoint_ct'    => 131, # CT variation of hollowpoint "match" projectiles, by Nosler
    'mk318'             => 133, # USMC 5.56x45mm Mk318 Mod 0 SOST open-tip/boattail 62gr half-lead/half-copper
    'bst'               => 135, # A type of flat-bottomed ogival, by Nosler
    'btsp'              => 137, # Boat-tailed spire-point from Hornady
    'spire_point'       => 138, # A type of flat-bottomed ogival, by Speer
    'boat_tail_nosler'  => 138, # Nosler's line of boat-tails perform more poorly than others for some reason
    'boat_tail_ct'      => 139, # Nosler's CT variation of boat-tail
    'spitzer'           => 139, # Another flat-bottomed ogival, by Speer
    'hollowpoint_match' => 140, # Catch-all for many hollowpoint "match" projectiles
    'accubond'          => 142, # An expansive line by Nosler
    'interbond'         => 142, # An expansive line by Hornady
    'tts'               => 143, # Tipped Triple Shock, another line of all-copper bullets from Barnes
    'vmax'              => 145, # A line of polymer-tipped bullets by Hornady optimized for terminal expansion / fragmentation
    'gold_match'        => 147, # A type of wadcutter, by Speer
    'tsx'               => 151, # Another line of all-copper hunting bullets from Barnes
    'partition'         => 152, # A crappy hunting bullet by Nosler
    'spbt'              => 152.5, # Soft-Point Boat-Tail
    'grand_slam'        => 159, # Another wadcutter, by Speer
    'barnes_xxx'        => 161, # Flat-bottomed all-copper hunting round, by Barnes
    'hollowpoint'       => 176, # Catch-all for many large-game hollowpoint projectiles
    'sp'                => 177, # Catch-all for many softpoint hunting projectiles without sharp points
    'default'           => 179, # Catch-all for unknown/unspecified shapes; derived via best-fit to ballistic table
    'fmj'               => 187, # Catch-all for military full metal jacket with boat-tail and short nose
    'mag_tip'           => 190, # Another wadcutter, by Speer
    'afss'              => 202,
    'tsx_fb'            => 205, 
    'plinker'           => 205, # Typical of short, underweight, round-nosed, non-streamlined projectiles,
    'rws_ks'            => 210,
    'semispitzer'       => 224, # A foreshortened, flat-bottomed projectile, by Speer
    'round_nose'        => 228, # Catch-all for many flat-bottomed, hemispherical-nosed projectiles
    'varminter'         => 232, # Catch-all for many light hollowpoints with very large expanding cavities, for varminting
    'fmj_2'             => 268, # Woodleigh's FMJ projectiles, which are shape-optimized for travel in big game meat and bone, instead of air.
    'flat_nose'         => 299  # Flat-nosed bullets for tubular magazines
    );

# TODO: Contact Geoffrey Kolbe (Inventor at Border Barrels Limited) and ask for permission to publish his splendid implementations:
#    * Bullet drag calculator - http://www.border-barrels.com/cgi-bin/drag_working.cgi
#    * Barrel weight calculator - http://www.border-barrels.com/cgi-bin/swamped_barrel_weight.cgi
#
# His drag calculator appears far superior to my own ebc function.

sub ebc { # estimate ballistic coefficient (G1) from mass, diameter, and shape or form factor
    # Form factor is based on shape (nose, tail, distance between them), and has inverse impact on BC (higher form factor == lower BC).
    # Form factor is subject to some modification:
    #    * adjusted for diameter (normalizing on .308 inch diameters)
    #    * adjusted upward at very small L/D (very short shapes)
    my ($mass_gr, $diam_in, $shape, $ff) = @_;
    die("bc, form-factor, very-small-factor, shape = ebc(mass_gr, diam_in[, shape[, form-factor]])") unless (defined($diam_in));
    my $vsf = 1; # "very small" factor -- a penalty incurred when length/diameter is too small.
    $shape = "default" unless (defined($shape));
    if (!defined($ff)) {
        # Form factors of various commercial shapes.  Higher ff implies more drag.
        my $vsthreshold = 4480; # determined empirically, looking at 45gr 0.224" spitzer, which looks to be just beyond the threshold, and 40gr 0.224" spire_point, which is significantly beyond it.
        my $LD  = $mass_gr / $diam_in**3;
        $vsf = ($vsthreshold / $LD) if ($LD < $vsthreshold);
        my $ff_base = undef;
        if (defined($Physics::Ballistics::External::Bullet_Form_Factors_H{$shape})) {
              $ff_base = $Physics::Ballistics::External::Bullet_Form_Factors_H{$shape};
        } else {
              $ff_base = $Physics::Ballistics::External::Bullet_Form_Factors_H{'default'};
              $ff_base = 179 unless (defined($ff_base));
              print STDERR "ebc: warning: unknown shape '$shape' and no form factor explicitly provided; assuming default (ff=$ff_base)\n";
        }
        my $diameter_factor = ($diam_in / .308)**0.541;
        $ff = $vsf * $ff_base * $diameter_factor;
    } # END of if !$ff
    my $bc = ($mass_gr**1.25 / (10*$diam_in)**2) / $ff;
    return {bc => $bc, ff => $ff, vsf => $vsf, shape => $shape};
}

############## BEGIN port of GNU-Ballistics gebc-1.07 lib/ballistics/ballistics.cpp
# TODO: Incorporate wobble estimation function (used by improved penetration estimator).
# TODO: Port bugfixes and enhancements to Inline::C.  The pure-perl performance is horrible.

my $GRAVITY        = -32.194;
my $BCOMP_MAXRANGE =    2000;

# Specialty angular conversion functions, straightforward PP port of GNU-Ballistics gebc-1.07 lib/ballistics/ballistics.cpp

sub DegtoMOA {
    my ($deg) = @_;
    return $deg*60;
}
sub DegtoRad {
    my ($deg) = @_;
    return $deg*pi/180;
}
sub MOAtoDeg {
    my ($moa) = @_;
    return $moa/60;
}
sub MOAtoRad { 
    my ($moa) = @_;
    return $moa/60*pi/180;
}
sub RadtoDeg { 
    my ($rad) = @_;
    return $rad*180/pi;
}
sub RadtoMOA {
    my ($rad) = @_;
    return $rad*60*180/pi;
}

# Functions for correcting for atmosphere, straightforward PP port of GNU-Ballistics gebc-1.07 lib/ballistics/ballistics.cpp

sub calcFR {
    my ($Temperature, $Pressure, $RelativeHumidity) = @_;
    my $VPw = (4e-6) * $Temperature**3 - 0.0004 * $Temperature**2 + 0.0234 * $Temperature - 0.2517;
    my $FRH = 0.995 * $Pressure / ($Pressure - 0.3783 * $RelativeHumidity * $VPw);
    return $FRH;
}

sub calcFP {
    my ($Pressure) = @_;
    my $Pstd = 29.53; # inches-hg
    my $FP = ($Pressure - $Pstd) / $Pstd;
    return $FP;
}

sub calcFT {
    my ($Temperature, $Altitude) = @_;
    my $Tstd = -0.0036 * $Altitude + 59;
    my $FT = ($Temperature - $Tstd) / (459.6 + $Tstd);
    return $FT;
}

sub calcFA {
    my ($Altitude) = @_;
    my $fa = (-4e-15) * $Altitude**3 + (4e-10) * $Altitude**2 - (3e-5) * $Altitude + 1;
    return 1/$fa;
}

sub AtmCorrect {
    my ($DragCoefficient, $Altitude, $Barometer, $Temperature, $RelativeHumidity) = @_;
    my $FA = calcFA($Altitude);
    my $FT = calcFT($Temperature, $Altitude);
    my $FR = calcFR($Temperature, $Barometer, $RelativeHumidity);
    my $FP = calcFP($Barometer);

    # Calculate the atmospheric correction factor
    my $CD = $FA * (1 + $FT - $FP) * $FR;
    return $DragCoefficient * $CD;
}

# Function for correcting for ballistic drag, straightforward PP port of GNU-Ballistics gebc-1.07 lib/ballistics/ballistics.cpp
sub velocity_loss {
    my ($DragFunction, $DragCoefficient, $Velocity) = @_;
    my $vp  = $Velocity;     
    my $val = -1;
    my $A   = -1;
    my $M   = -1;
    if ($DragFunction eq 'G1') {
        if    ($vp > 4230) { $A = 1.477404177730177e-04; $M = 1.9565; }
        elsif ($vp > 3680) { $A = 1.920339268755614e-04; $M = 1.925 ; }
        elsif ($vp > 3450) { $A = 2.894751026819746e-04; $M = 1.875 ; }
        elsif ($vp > 3295) { $A = 4.349905111115636e-04; $M = 1.825 ; }
        elsif ($vp > 3130) { $A = 6.520421871892662e-04; $M = 1.775 ; }
        elsif ($vp > 2960) { $A = 9.748073694078696e-04; $M = 1.725 ; }
        elsif ($vp > 2830) { $A = 1.453721560187286e-03; $M = 1.675 ; }
        elsif ($vp > 2680) { $A = 2.162887202930376e-03; $M = 1.625 ; }
        elsif ($vp > 2460) { $A = 3.209559783129881e-03; $M = 1.575 ; }
        elsif ($vp > 2225) { $A = 3.904368218691249e-03; $M = 1.55  ; }
        elsif ($vp > 2015) { $A = 3.222942271262336e-03; $M = 1.575 ; }
        elsif ($vp > 1890) { $A = 2.203329542297809e-03; $M = 1.625 ; }
        elsif ($vp > 1810) { $A = 1.511001028891904e-03; $M = 1.675 ; }
        elsif ($vp > 1730) { $A = 8.609957592468259e-04; $M = 1.75  ; }
        elsif ($vp > 1595) { $A = 4.086146797305117e-04; $M = 1.85  ; }
        elsif ($vp > 1520) { $A = 1.954473210037398e-04; $M = 1.95  ; }
        elsif ($vp > 1420) { $A = 5.431896266462351e-05; $M = 2.125 ; }
        elsif ($vp > 1360) { $A = 8.847742581674416e-06; $M = 2.375 ; }
        elsif ($vp > 1315) { $A = 1.456922328720298e-06; $M = 2.625 ; }
        elsif ($vp > 1280) { $A = 2.419485191895565e-07; $M = 2.875 ; }
        elsif ($vp > 1220) { $A = 1.657956321067612e-08; $M = 3.25  ; }
        elsif ($vp > 1185) { $A = 4.745469537157371e-10; $M = 3.75  ; }
        elsif ($vp > 1150) { $A = 1.379746590025088e-11; $M = 4.25  ; }
        elsif ($vp > 1100) { $A = 4.070157961147882e-13; $M = 4.75  ; }
        elsif ($vp > 1060) { $A = 2.938236954847331e-14; $M = 5.125 ; }
        elsif ($vp > 1025) { $A = 1.228597370774746e-14; $M = 5.25  ; }
        elsif ($vp >  980) { $A = 2.916938264100495e-14; $M = 5.125 ; }
        elsif ($vp >  945) { $A = 3.855099424807451e-13; $M = 4.75  ; }
        elsif ($vp >  905) { $A = 1.185097045689854e-11; $M = 4.25  ; }
        elsif ($vp >  860) { $A = 3.566129470974951e-10; $M = 3.75  ; }
        elsif ($vp >  810) { $A = 1.045513263966272e-08; $M = 3.25  ; }
        elsif ($vp >  780) { $A = 1.291159200846216e-07; $M = 2.875 ; }
        elsif ($vp >  750) { $A = 6.824429329105383e-07; $M = 2.625 ; }
        elsif ($vp >  700) { $A = 3.569169672385163e-06; $M = 2.375 ; }
        elsif ($vp >  640) { $A = 1.839015095899579e-05; $M = 2.125 ; }
        elsif ($vp >  600) { $A = 5.71117468873424e-05 ; $M = 1.950 ; }
        elsif ($vp >  550) { $A = 9.226557091973427e-05; $M = 1.875 ; }
        elsif ($vp >  250) { $A = 9.337991957131389e-05; $M = 1.875 ; }
        elsif ($vp >  100) { $A = 7.225247327590413e-05; $M = 1.925 ; }
        elsif ($vp >   65) { $A = 5.792684957074546e-05; $M = 1.975 ; }
        elsif ($vp >    0) { $A = 5.206214107320588e-05; $M = 2.000 ; }
    }
        
    elsif ($DragFunction eq 'G2') {
        if    ($vp > 1674 ) { $A = .0079470052136733   ;  $M = 1.36999902851493; }
        elsif ($vp > 1172 ) { $A = 1.00419763721974e-03;  $M = 1.65392237010294; }
        elsif ($vp > 1060 ) { $A = 7.15571228255369e-23;  $M = 7.91913562392361; }
        elsif ($vp >  949 ) { $A = 1.39589807205091e-10;  $M = 3.81439537623717; }
        elsif ($vp >  670 ) { $A = 2.34364342818625e-04;  $M = 1.71869536324748; }
        elsif ($vp >  335 ) { $A = 1.77962438921838e-04;  $M = 1.76877550388679; }
        elsif ($vp >    0 ) { $A = 5.18033561289704e-05;  $M = 1.98160270524632; }
    }
    
    elsif ($DragFunction eq 'G5') {
        if    ($vp > 1730 ){ $A = 7.24854775171929e-03; $M = 1.41538574492812; }
        elsif ($vp > 1228 ){ $A = 3.50563361516117e-05; $M = 2.13077307854948; }
        elsif ($vp > 1116 ){ $A = 1.84029481181151e-13; $M = 4.81927320350395; }
        elsif ($vp > 1004 ){ $A = 1.34713064017409e-22; $M = 7.8100555281422 ; }
        elsif ($vp >  837 ){ $A = 1.03965974081168e-07; $M = 2.84204791809926; }
        elsif ($vp >  335 ){ $A = 1.09301593869823e-04; $M = 1.81096361579504; }
        elsif ($vp >    0 ){ $A = 3.51963178524273e-05; $M = 2.00477856801111; }  
    }
    
    elsif ($DragFunction eq 'G6') {
        if    ($vp > 3236 ) { $A = 0.0455384883480781   ; $M = 1.15997674041274; }
        elsif ($vp > 2065 ) { $A = 7.167261849653769e-02; $M = 1.10704436538885; }
        elsif ($vp > 1311 ) { $A = 1.66676386084348e-03 ; $M = 1.60085100195952; }
        elsif ($vp > 1144 ) { $A = 1.01482730119215e-07 ; $M = 2.9569674731838 ; }
        elsif ($vp > 1004 ) { $A = 4.31542773103552e-18 ; $M = 6.34106317069757; }
        elsif ($vp >  670 ) { $A = 2.04835650496866e-05 ; $M = 2.11688446325998; }
        elsif ($vp >    0 ) { $A = 7.50912466084823e-05 ; $M = 1.92031057847052; }
    }
    
    elsif ($DragFunction eq 'G7') {
        if    ($vp > 4200 ) { $A = 1.29081656775919e-09; $M = 3.24121295355962; }
        elsif ($vp > 3000 ) { $A = 0.0171422231434847  ; $M = 1.27907168025204; }
        elsif ($vp > 1470 ) { $A = 2.33355948302505e-03; $M = 1.52693913274526; }
        elsif ($vp > 1260 ) { $A = 7.97592111627665e-04; $M = 1.67688974440324; }
        elsif ($vp > 1110 ) { $A = 5.71086414289273e-12; $M = 4.3212826264889 ; }
        elsif ($vp >  960 ) { $A = 3.02865108244904e-17; $M = 5.99074203776707; }
        elsif ($vp >  670 ) { $A = 7.52285155782535e-06; $M = 2.1738019851075 ; }
        elsif ($vp >  540 ) { $A = 1.31766281225189e-05; $M = 2.08774690257991; }
        elsif ($vp >    0 ) { $A = 1.34504843776525e-05; $M = 2.08702306738884; }
    }

    elsif ($DragFunction eq 'G8') {
        if    ($vp > 3571 ) { $A = .0112263766252305   ; $M = 1.33207346655961; }
        elsif ($vp > 1841 ) { $A = .0167252613732636   ; $M = 1.28662041261785; }
        elsif ($vp > 1120 ) { $A = 2.20172456619625e-03; $M = 1.55636358091189; }
        elsif ($vp > 1088 ) { $A = 2.0538037167098e-16 ; $M = 5.80410776994789; }
        elsif ($vp >  976 ) { $A = 5.92182174254121e-12; $M = 4.29275576134191; }
        elsif ($vp >    0 ) { $A = 4.3917343795117e-05 ; $M = 1.99978116283334; }
    }

    if ($A != -1 && $M != -1 && $vp > 0 && $vp < 10000 ) {
        $val = $A * $vp**$M / $DragCoefficient;
        return $val;
    }
    return -1;
}

sub Windage {
    my ($WindSpeed, $Vi, $xx, $t) = @_;
    my $Vw = $WindSpeed * 17.60; # Convert to inches per second.
    return $Vw * ($t - $xx / $Vi);
}

# Headwind is positive at WindAngle=0
sub HeadWind {
    my ($WindSpeed, $WindAngle) = @_;
    my $Wangle = DegtoRad($WindAngle);
    return cos($Wangle) * $WindSpeed;
}

# Positive is from Shooter's Right to Left (Wind from 90 degree)
sub CrossWind {
    my ($WindSpeed, $WindAngle) = @_;
    my $Wangle = DegtoRad($WindAngle);
    return sin($Wangle) * $WindSpeed;
}

# Equivalent to, but slightly faster than, calling HeadWind and CrossWind separately.
# Perl suffers from a couple thousand clock cycles of overhead per function call (about
# 1 microsecond of wallclock time on typical 2010's hardware), so consolidating similar
# functions is a performance win.
sub HeadAndCrossWind {
    my ($WindSpeed, $WindAngle) = @_;
    my $Wangle = DegtoRad($WindAngle);
    return (cos($Wangle) * $WindSpeed, sin($Wangle) * $WindSpeed);
}

# Straightforward PP port from GNU-Ballistics gebc-1.07 lib/ballistics/ballistics.cpp
sub ZeroAngle {
    my ($DragFunction, $DragCoefficient, $Vi, $SightHeight, $ZeroRange, $yIntercept) = @_;

    # Numerical Integration variables
    my $t  = 0;
    my $dt = 1/$Vi; # The solution accuracy generally doesn't suffer if its within a foot for each second of time.
    my $y  = -1 * $SightHeight / 12;
    my $x  = 0;
    my $da; # The change in the bore angle used to iterate in on the correct zero angle.

    # State variables for each integration loop.
    # velocity:
    my $v  = 0;
    my $vx = 0;
    my $vy = 0;
    # Last frame's velocity, used for computing average velocity:
    my $vx1 = 0;
    my $vy1 = 0;
    # acceleration:
    my $dv  = 0;
    my $dvx = 0;
    my $dvy = 0;
    # Gravitational acceleration:
    my $Gx = 0;
    my $Gy = 0;

    my $angle = 0; # The actual angle of the bore.

    my $quit = 0; # We know it's time to quit our successive approximation loop when this is 1.

    # Start with a very coarse angular change, to quickly solve even large launch angle problems.
    $da = DegtoRad(14);

    # The general idea here is to start at 0 degrees elevation, and increase the elevation by 14 degrees
    # until we are above the correct elevation.  Then reduce the angular change by half, and begin reducing
    # the angle.  Once we are again below the correct angle, reduce the angular change by half again, and go
    # back up.  This allows for a fast successive approximation of the correct elevation, usually within less
    # than 20 iterations.
    for ($angle = 0; $quit == 0; $angle = $angle + $da) {
        $vy = $Vi * sin($angle);
        $vx = $Vi * cos($angle);
        $Gx = $GRAVITY * sin($angle);
        $Gy = $GRAVITY * cos($angle);

        for (($t, $x, $y) = (0, 0, -1 * $SightHeight/12); $x <= $ZeroRange*3; $t += $dt) {
            $vy1 = $vy;
            $vx1 = $vx;
            $v   = ($vx**2 + $vy**2)**0.5;
            $dt  = 1/$v;
            
            $dv = velocity_loss ($DragFunction, $DragCoefficient, $v);
            $dvy = -1 * $dv * $vy / $v * $dt;
            $dvx = -1 * $dv * $vx / $v * $dt;

            $vx = $vx + $dvx;
            $vy = $vy + $dvy;
            $vy = $vy + $dt * $Gy;
            $vx = $vx + $dt * $Gx;
            
            $x += $dt * ($vx + $vx1) / 2;
            $y += $dt * ($vy + $vy1) / 2;
            # Break early to save CPU time if we won't find a solution.
            last if ($vy < 0 && $y < $yIntercept);
            last if ($vy>3 * $vx);
        }
    
        $da = -1 * $da / 2 if ($y > $yIntercept && $da > 0);
        $da = -1 * $da / 2 if ($y < $yIntercept && $da < 0);

        $quit = 1 if (abs($da) < MOAtoRad(0.01)); # If our accuracy is sufficient, we can stop approximating.
        $quit = 1 if ($angle   > DegtoRad(45));   # If we exceed the 45 degree launch $angle, then the projectile just won't get there, so we stop trying.
    }
    return RadtoDeg($angle); # Convert to degrees for return value.
}

=head2 flight_simulator (drag_function, ballistic_coefficient, muzzle_velocity_fps, sight_height_inches, shot_angle_deg, [bore_to_sight_angle_deg,] zero_range_yards, wind_speed_fps, wind_angle_deg, [max_range_yards])

Attempts to predict the flight characteristics of a projectile in flight, providing a data point for every yard of progress it makes downrange.

This is a pure-perl port of the "SolveAll" function from GNU-Ballistics gebc-1.07 lib/ballistics/ballistics.cpp, and as slow as one might expect from a pure-perl port of an arithmetic-intensive algorithm.

On my system it takes about an eighth of a second to simulate a 1200-yard flight.  This may be supplemented at some point with an Inline::C equivalent.

Note that most manufacturers report G1 ballistic coefficients.  Using the wrong drag function for a given ballistic coefficient will produce ludicrously incorrect results.

To ascertain the correct bore elevation to hit a target at a specific distance, change the shot_angle_deg parameter on successive calls to flight_simulator(), and converge on drop_inches == 0.0 at the given range via binary search.  I should get around to providing a function for that at some point (GNU-Ballistics has such a function, I just didn't port it).

=over 4

parameter: (str) drag_function is exactly one of: 'G1', 'G2', 'G5', 'G6', 'G7', 'G8'.

parameter: (float) ballistic_coefficient, qv: http://en.wikipedia.org/wiki/Ballistic_coefficient

parameter: (float) muzzle_velocity_fps is the velocity of the projectile at time=0 (feet per second)

parameter: (float) sight_height_inches is the distance from the center of the sight to the center of the bore (inches)

parameter: (float) shot_angle_deg is the bore elevation (degrees, 0 = horizontal, 90 = vertical)

parameter: (float) OPTIONAL: bore_to_sight_angle_deg is the difference in angle between the bore elevation and the sight elevation.  Set to undef or -1 to have flight_simulator() calculate it for you from the zero_range_yards parameter (degrees)

parameter: (float) wind_speed_fps is the velocity of the wind (feet per second)

parameter: (float) wind_angle_deg is the direction the wind is blowing (degrees, 0 = shooting directly into wind, 90 = wind is blowing from the right, perpendicular to flight path, -90 = wind is blowing from the left, perpendicular to flight path)

parameter: (float) OPTIONAL: max_range_yards is the maximum range to which the flight will be simulated (yards, default is 2000)

returns: a reference to an array of hash references, one per yard, denoting the projectile's disposition when it reaches that range.  All data fields are floating-point numbers:

    range_yards     How far downrange the projectile has travelled, in yards.
    drop_inches     How far below the horizontal plane intersecting the muzzle the projectile has travelled, in inches.
    correction_moa  The angle from the muzzle to the projectile in the vertical plane, relative to the path from the muzzle to the target, in minutes.
    time_seconds    How much time has elapsed since leaving the muzzle, in seconds.
    windage_inches  How far in the horizontal plane the projectile has moved due to wind, in inches.
    windage_moa     The angle from the muzzle to the projectile in the horzontal plane, relative to the path from the muzzle to the target, in minutes.
    vel_fps         The velocity of the projectile, in feet per second.
    vel_horiz_fps   The horizontal component of the velocity of the projectile, in feet per second.
    vel_vert_fps    The vertical component of the velocity of the projectile, in feet per second.

=back

=cut

# The solve-all solution.
# PP port of "SolveAll" from GNU-Ballistics gebc-1.07 lib/ballistics/ballistics.cpp
# $DragFunction is one of 'G1', 'G2', 'G5', 'G6', 'G7', 'G8'
# $DragCoefficient is the ballistic coefficient
# $Vi is the muzzle velocity of the projectile, feet per second
# $SightHeight is the height of the scope in inches
# $ShootingAngle is the bore elevation (angle)
# $ZAngle is the bore-to-sight angle, or -1 to calculate from $ZRange
# $ZRange is the range, in yards, to which the rifle is sighted-in.
# $WindSpeed is the speed of the wind, in feet per second
# $WindAngle is the angle of the wind relative to the shooter -- coming from the right is positive, coming from the left is negative.
# $MaxRange is the maximum range, in yards, to simulate (defaults to $BCOMP_MAXRANGE if -1 or undef)
sub flight_simulator {
    my ($DragFunction, $DragCoefficient, $Vi, $SightHeight, $ShootingAngle, $ZAngle, $ZRange, $WindSpeed, $WindAngle, $MaxRange) = @_;
    my $ptr = {};

    die("usage: ar = flight_simulator(DragFunction, DragCoefficient, Vel_fps, SightHeight_inches, ShootingAngle_deg, ZAngle_deg, ZRange_yards, WindSpeed_fps, WindAngle_deg, MaxRange_yards)\n") unless(defined($DragCoefficient));

    my $t   = 0;
    my $dt  = 0.5 / $Vi;
    my $v   = 0;
    my $vx  = 0;  # horizontal velocity, feet per second, at beginning of quantum
    my $vx1 = 0;  # horizontal velocity, feet per second, at end of quantum
    my $vy  = 0;
    my $vy1 = 0;
    my $dv  = 0;
    my $dvx = 0;
    my $dvy = 0;
    my $x   = 0;
    my $y   = 0;

    # print ("fs: 0010 ShootingAngle=$ShootingAngle  ZAngle=$ZAngle\n");

    $ZAngle = ZeroAngle($DragFunction, $DragCoefficient, $Vi, $SightHeight, $ZRange, 0) if ($ZAngle == -1 || !defined($ZAngle));
    $MaxRange = $BCOMP_MAXRANGE unless (defined($MaxRange) && $MaxRange >= 0);
    $MaxRange *= 3; # Convert yards to feet.
    
    # print ("fs: 0020 ShootingAngle=$ShootingAngle  ZAngle=$ZAngle  MaxRange=$MaxRange\n");

    my ($headwind, $crosswind) = HeadAndCrossWind($WindSpeed, $WindAngle);
    my $Radians = DegtoRad($ShootingAngle + $ZAngle);
    my $CosRadians = cos($Radians);
    my $SinRadians = sin($Radians);
    my $Gy = $GRAVITY * $CosRadians;
    my $Gx = $GRAVITY * $SinRadians;

    # $vx = $Vi * cos(DegtoRad($ZAngle));
    # $vy = $Vi * sin(DegtoRad($ZAngle));
    $vx   = $Vi * $CosRadians;
    $vy   = $Vi * $SinRadians;

    # print ("fs: 0030 vx=$vx vy=$vy\n");

    $y = -1 * $SightHeight / 12;

    my $yards_downrange = 0;
    my $rv = [];
    for ($t = 0; 1; $t += $dt) {
        $vx1 = $vx;
        $vy1 = $vy;
        $v  = ($vx**2 + $vy**2)**0.5;
        $dt = 0.5 / $v;

        # print ("fs: 0040 vx=$vx vy=$vy\n");
    
        # Compute acceleration using the drag function retardation     
        $dv = velocity_loss($DragFunction, $DragCoefficient, $v + $headwind);
        $dvx = -1 * ($vx / $v) * $dv;
        $dvy = -1 * ($vy / $v) * $dv;

        # Compute velocity, including the resolved gravity vectors.    
        $vx = $vx + $dt * $dvx + $dt * $Gx;
        $vy = $vy + $dt * $dvy + $dt * $Gy;

        if ($x/3 >= $yards_downrange) {
            my $hr = {};
            $hr->{range_yards}    = $x / 3;
            $hr->{drop_inches}    = $y * -12;
            $hr->{correction_moa} = 0;
            $hr->{correction_moa} = -1 * RadtoMOA(atan($y / $x)) if ($x > 0);
            $hr->{time_seconds}   = $t + $dt;
            $hr->{windage_inches} = 0;
            $hr->{windage_inches} = Windage($crosswind, $Vi, $x, $t + $dt) if ($x > 0);
            $hr->{windage_moa}    = 0;
            $hr->{windage_moa}    = RadtoMOA(atan(($hr->{windage_inches} / 12) / (($hr->{range_yards} * 3) || 0.1))) if ($crosswind > 0);
            $hr->{vel_fps}        = $v;
            $hr->{vel_horiz_fps}  = $vx;
            $hr->{vel_vert_fps}   = $vy;
            push (@{$rv}, $hr);
            $yards_downrange++;
        }       
        
        # Compute position based on average velocity.
        $x += $dt * ($vx + $vx1) / 2;
        $y += $dt * ($vy + $vy1) / 2;
        
        # last if (abs($vy) > abs(3 * $vx));
        last if ($t > 3600);
        last if ($x >= $MaxRange+1.0);
    }
    return $rv;
}

################# no functions ported from GNU-Ballistics gebc-1.07 lib/ballistics/ballistics.cpp after this line ##################

=head2 g1_drag (velocity_fps)

The canonical function for computing instantaneous velocity drop at a given velocity, per the G1 drag model.

=over 4

parameter: (float) velocity_fps is the velocity of the projectile (in feet per second)

returns: (float) the deceleration of the projectile from drag (in feet per second per second)

=back

=cut

# PP implementation of G1 drag model.
# Multiply by G1 ballistic coefficient to get instantaneous velocity drop.
sub g1_drag {
    my ($fps) = @_;
    if    ($fps > 4230) { return (1.477404177730177E-04) * ($fps**1.9565); }
    elsif ($fps > 3680) { return (1.920339268755614E-04) * ($fps**1.925); }
    elsif ($fps > 3450) { return (2.894751026819746E-04) * ($fps**1.875); }
    elsif ($fps > 3295) { return (4.349905111115636E-04) * ($fps**1.825); }
    elsif ($fps > 3130) { return (6.520421871892662E-04) * ($fps**1.775); }
    elsif ($fps > 2960) { return (9.748073694078696E-04) * ($fps**1.725); }
    elsif ($fps > 2830) { return (1.453721560187286E-03) * ($fps**1.675); }
    elsif ($fps > 2680) { return (2.162887202930376E-03) * ($fps**1.625); }
    elsif ($fps > 2460) { return (3.209559783129881E-03) * ($fps**1.575); }
    elsif ($fps > 2225) { return (3.904368218691249E-03) * ($fps**1.550); }
    elsif ($fps > 2015) { return (3.222942271262336E-03) * ($fps**1.575); }
    elsif ($fps > 1890) { return (2.203329542297809E-03) * ($fps**1.625); }
    elsif ($fps > 1810) { return (1.511001028891904E-03) * ($fps**1.675); }
    elsif ($fps > 1730) { return (8.609957592468259E-04) * ($fps**1.750); }
    elsif ($fps > 1595) { return (4.086146797305117E-04) * ($fps**1.850); }
    elsif ($fps > 1520) { return (1.954473210037398E-04) * ($fps**1.950); }
    elsif ($fps > 1420) { return (5.431896266462351E-05) * ($fps**2.125); }
    elsif ($fps > 1360) { return (8.847742581674416E-06) * ($fps**2.375); }
    elsif ($fps > 1315) { return (1.456922328720298E-06) * ($fps**2.625); }
    elsif ($fps > 1280) { return (2.419485191895565E-07) * ($fps**2.875); }
    elsif ($fps > 1220) { return (1.657956321067612E-08) * ($fps**3.250); }
    elsif ($fps > 1185) { return (4.745469537157371E-10) * ($fps**3.750); }
    elsif ($fps > 1150) { return (1.379746590025088E-11) * ($fps**4.250); }
    elsif ($fps > 1100) { return (4.070157961147882E-13) * ($fps**4.750); }
    elsif ($fps > 1060) { return (2.938236954847331E-14) * ($fps**5.125); }
    elsif ($fps > 1025) { return (1.228597370774746E-14) * ($fps**5.250); }
    elsif ($fps >  980) { return (2.916938264100495E-14) * ($fps**5.125); }
    elsif ($fps >  945) { return (3.855099424807451E-13) * ($fps**4.750); }
    elsif ($fps >  905) { return (1.185097045689854E-11) * ($fps**4.250); }
    elsif ($fps >  860) { return (3.566129470974951E-10) * ($fps**3.750); }
    elsif ($fps >  810) { return (1.045513263966272E-08) * ($fps**3.250); }
    elsif ($fps >  780) { return (1.291159200846216E-07) * ($fps**2.875); }
    elsif ($fps >  750) { return (6.824429329105383E-07) * ($fps**2.625); }
    elsif ($fps >  700) { return (3.569169672385163E-06) * ($fps**2.375); }
    elsif ($fps >  640) { return (1.839015095899579E-05) * ($fps**2.125); }
    elsif ($fps >  600) { return (5.711174688734240E-05) * ($fps**1.950); }
    elsif ($fps >  550) { return (9.226557091973427E-05) * ($fps**1.875); }
    elsif ($fps >  250) { return (9.337991957131389E-05) * ($fps**1.875); }
    elsif ($fps >  100) { return (7.225247327590413E-05) * ($fps**1.925); }
    elsif ($fps >   65) { return (5.792684957074546E-05) * ($fps**1.975); }
    elsif ($fps >    0) { return (5.206214107320588E-05) * ($fps**2.000); }
    return 0.0;
}

=head2 muzzle_energy (mass_grains, velocity_fps, [want_joules_bool])

A convenience function for computing kinetic energy from mass and velocity.
Despite its name, it is useful for computing the kinetic energy of a projectile
at any point during its flight.

=over 4

parameter: (float) mass_grains is the mass of the projectile (in grains)

parameter: (float) velocity_fps is the velocity of the projectile (in feet per second)

parameter: (boolean) OPTIONAL: set want_joules_bool to a True value to get Joules instead of foot-pounds (boolean, default=False)

returns: (float) the kinetic energy of the projectile (in foot-pounds or Joules)

=back

=cut

sub muzzle_energy {
    my ($grains, $fps, $wantJ) = @_;
    die("footpounds = muzzle_energy(grains, fps[, want_Joules])") unless(defined($fps));
    my $nrg = 0.5 * $grains * $fps * $fps / 225312.839; # footpounds
       $nrg *= 1.3558 if ($wantJ);
    return int(100 * $nrg + 0.5) / 100;
}

=head2 muzzle_velocity_from_energy (mass_grains, energy_ftlbs)

A convenience function for computing velocity from mass and kinetic energy.
Despite its name, it is useful for computing the velocity of a projectile
at any point during its flight.

If all you have is Joules, divide by 1.3558179 to get foot-pounds.

=over 4

parameter: (float) mass_grains is the mass of the projectile (in grains)

parameter: (float) energy_ftlbs is the kinetic energy of the projectile (in foot-pounds)

returns: (float) the velocity of the projectile (in feet per second)

=back

=cut

sub muzzle_velocity_from_energy {
    my ($grains, $footpounds) = @_;
    die("feet/second = muzzle_velocity_from_energy(grains, footpounds)") unless(defined($footpounds));
    my $fps = (450625.678 * $footpounds / $grains) ** 0.5;
    return int(100 * $fps + 0.5) / 100;
}

1;

=head1 TODO

Contact Geoffrey Kolbe (Inventor at Border Barrels Limited) and ask for permission to publish his splendid implementations:

 * Bullet drag calculator - http://www.border-barrels.com/cgi-bin/drag_working.cgi

 * Barrel weight calculator - http://www.border-barrels.com/cgi-bin/swamped_barrel_weight.cgi

His drag calculator seems better than my own ebc function.

=cut
