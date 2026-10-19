package Peta::Synth::Voice;
# ABSTRACT: a sounding note: partials, noise, envelope, pitch

# A sounding note: its partials and noise, made from a patch, and what it
# does over time (envelope, pitch, noise level). The synthesizer asks a
# voice, block by block, for its controls; an engine turns the controls and
# the partials into samples.
#
# What an engine reads, for a quantum of nb control blocks of B samples:
#
#   ratio amp decay attack     per partial: frequency ratio to the fundamental,
#                              amplitude, decay (1/s), fade-in time (s, 0: none)
#   phase                      per partial, in radians; the engine keeps it
#   t0                         the voice's time (s) at the quantum's first block
#   first                      the first block the voice sounds in (it starts there)
#   w[nb]                      the fundamental, radians per sample, per block
#                              (key, tuning, bend, vibrato, sweep, glide)
#   env[nb+1] gl gr gs         envelope and channel gains (left, right, reverb send)
#                              at the blocks' edges, to be interpolated across a block
#   noise                      how many bands of noise (0 .. 3)
#   bands                      each: g k mode poles (its filter: tan(pi fc / rate),
#                              1/q; 0 band-, 1 high-, 2 low-pass; 2 or 4: a second
#                              stage the same), state [ic1, ic2, table position, the
#                              second stage's jc1, jc2], env[nb+1] (its level at the
#                              edges, its grains in it)
#   rough, rstate              noise on the partials: [depth, a] (a one-pole
#                              low-pass's coefficient), [its state, table position]
#   string                     a plucked or struck string: level, g (the loop's gain),
#                              s1 (its low-pass: (1 - s1) x[n] + s1 x[n-1]), buf (its
#                              delay line), pos (where it writes next), prev (the
#                              low-pass's last input), ax ay (the fractional allpass's
#                              last input and output), stages (0 or 4) and a: the
#                              stiffness, first-order allpasses (a + z^-1) / (1 + a z^-1)
#                              after the fractional one, disp their last inputs and
#                              outputs [x1 .. x4, y1 .. y4]; the delay read is the
#                              period (2 pi / w) less off, the rest of the loop's delay;
#                              exc (a period of the pluck or blow), fed (how much of it
#                              has gone into the loop, added to what the loop puts out)
#   fm                         four operators: level, ratio[4] (to the fundamental),
#                              coef [a34 a24 a23 a14 a13 a12] (operator k modulated by
#                              a_km times m's output), carrier[4] (0, 1), fb (operator
#                              4's feedback, radians), lv[4][nb+1] (their levels at the
#                              edges), phase[4], hist (operator 4's last two outputs)
#   fmode, fx[nb+1] fq[nb+1]   the filter (0 none; 1 low-pass of 12, 2 of 24 dB
#                              an octave; 3, 4 high-pass; 5 band-pass), and at
#                              the edges the fundamental over the cutoff and the Q
#
# The partials' amplitude at time t is
#
#   amp * exp(-decay t) * (attack > 0 ? 1 - exp(-t / attack) : 1) * H(ratio fx, fq)
#
# at the blocks' edges, interpolated in between, times env and the gains;
# H is the filter's gain (see filter_gain), 1 without one.
#
# Modulation (a patch's filter, its routes): sources taken at the blocks'
# edges (velocity, key, the channel's controllers, the second envelope, two
# LFOs), each times a route's amount, summed into destinations (pitch,
# cutoff, resonance, level, pan, noise). A patch without either costs
# nothing of it.

use v5.36;
use Peta::Synth::Patch;
use Peta::Synth::Wavetable;

our $VERSION = '0.2610180';

use constant TWO_PI     => 6.283185307179586;
use constant PI         => 3.141592653589793;
use constant NOISE_SIZE => 1 << 16;
use constant SILENT     => 1e-4;    # -80 dB: a voice below this is done

# The filter's modes, as engines read them (fmode).
use constant {
    LOW_PASS_12  => 1,
    LOW_PASS_24  => 2,
    HIGH_PASS_12 => 3,
    HIGH_PASS_24 => 4,
    BAND_PASS    => 5,
};
my %FILTER = (off => 0, lp12 => LOW_PASS_12, lp24 => LOW_PASS_24, hp12 => HIGH_PASS_12, hp24 => HIGH_PASS_24, bp => BAND_PASS);

my %SHAPE      = (sine => 0, triangle => 1, square => 2, saw => 3, random => 4);
my %NOISE_MODE = (band => 0, high => 1, low => 2);

my @SOURCES      = @{ Peta::Synth::Patch::mod_sources() };
my @DESTINATIONS = @{ Peta::Synth::Patch::mod_destinations() };
my %SOURCE       = map { $SOURCES[$_] => $_ } 0 .. $#SOURCES;
my %DESTINATION  = map { $DESTINATIONS[$_] => $_ } 0 .. $#DESTINATIONS;

# The white noise every engine reads: the same on every perl.
my @NOISE;

sub noise_table () {
    return \@NOISE if @NOISE;

    my $state = 0x2545f491;
    for (1 .. NOISE_SIZE) {
        $state = ($state * 1103515245 + 12345) % 2147483648;
        push @NOISE, $state / 1073741824 - 1;
    }
    return \@NOISE;
}

# new($patch, %note): key, velocity (1..127), channel, rate, seed, partials
# (the most this voice may have), and the time it starts (start, in samples).
# What the channel makes of the note:
#
#   shape    factors on the patch: attack, decay, release (times), bright
#            (the cutoff), q (the cutoff's resonance), level
#   tune     semitones the note is moved by (a drum key's pitch)
#   glide    [semitones, seconds]: the pitch starts that far off and comes
#            to the note's in that time (portamento)
#   legato   it takes over from a note that sounds: no attack
#   pan      a pan of its own, added to the channel's (-1 .. 1; a drum key's)
#   send     the channel's reverb send times this
#   cutoff_control
#            a controller moves the cutoff (GM2's destinations): a patch
#            without a filter gets a low-pass of 12 dB, at half the rate
#   waves    a store of wave sequences (Peta::Synth::Wavetable) to read from
sub new ($class, $patch, %arg) {
    my $rate  = $arg{rate};
    my $key   = $arg{key};
    my $vel   = $arg{velocity} / 127;
    my $shape = { attack => 1, decay => 1, release => 1, bright => 1, q => 1, level => 1, %{ $arg{shape} // {} } };
    my $pitch = $patch->{fixed} || 440 * 2**(($key + $patch->{transpose} - 69) / 12);
    my $f0    = $pitch * 2**(($arg{tune} // 0) / 12);
    my $seed  = (($arg{seed} // 1) * 2654435761 + 1) % 4294967296 || 1;

    my $self = bless {
        patch          => $patch,
        key            => $key,
        channel        => $arg{channel} // 0,
        velocity       => $arg{velocity},
        f0             => $f0,
        rate           => $rate,
        start          => $arg{start} // 0,
        released       => undef,      # the sample the key was let go at
        seed           => $seed,      # of the voice's own random numbers
        shape          => $shape,
        level          => $patch->{level} * $vel**$patch->{velocity} * $shape->{level},
        id             => $arg{id} // 0,
        chorus         => $arg{chorus} // 0,
        legato         => $arg{legato} ? 1 : 0,
        rfactor        => 1,          # the note-off velocity's factor on the release
        pressure       => 0,          # key pressure, 0 .. 1
        cutoff_control => $arg{cutoff_control} ? 1 : 0,
    }, $class;
    $self->{glide} = [ $arg{glide}[0], 0, 0, $arg{glide}[1] ] if $arg{glide} && $arg{glide}[0];
    $self->{pan}   = $arg{pan}  if $arg{pan};
    $self->{send}  = $arg{send} if defined $arg{send} && $arg{send} != 1;

    $self->_partials($vel, $arg{partials} // 64);
    $self->_noise;
    $self->_string($vel);
    $self->_fm($vel);
    $self->_modulation($vel);
    $self->_waves($arg{waves}) if $arg{waves};

    return $self;
}

sub partials ($self) { return scalar @{ $self->{ratio} } }

sub _random ($self) {
    $self->{seed} = ($self->{seed} * 1103515245 + 12345) % 2147483648;
    return $self->{seed} / 2147483648;
}

# The partials: the patch's spectrum at this key and velocity, the strongest
# that fit under the budget, detuned copies for unison, normalized to unit
# RMS before the voice's level.
sub _partials ($self, $vel, $budget) {
    my $p    = $self->{patch};
    my $f0   = $self->{f0};
    my $rate = $self->{rate};
    my $top  = 0.45 * $rate;

    my @set = grep { $_->[0] * $f0 <= $top && $_->[1] > 0 } $self->_spectrum($vel);

    # The strongest within the budget; unison copies share it. The channel's
    # chorus (0 .. 1) makes at least three copies, and spreads them up to 24
    # cents further.
    my $copies = $p->{unison} > 1 ? $p->{unison} : 1;
    my $detune = $p->{detune};
    if (my $chorus = $self->{chorus}) {
        $copies = 3 if $copies < 3;
        $detune += 24 * $chorus;
    }
    $self->{copies} = $copies;

    my $keep  = $budget;                              # partials of the first copy
    my $extra = $copies > 1 ? $p->{unison_k} : 0;     # and of each of the others
    if ($copies > 1) {
        $keep  = int($budget / (1 + ($copies - 1) * 0.5)) || 1;
        $extra = $budget - $keep >= $copies - 1 ? int(($budget - $keep) / ($copies - 1)) : 0;
        $extra = $p->{unison_k} if $extra > $p->{unison_k};
    }
    my @strong = sort { $b->[1] <=> $a->[1] } @set;
    splice @strong, $keep if @strong > $keep;
    my $peak = @strong ? $strong[0][1] : 0;
    @strong = grep { $_->[1] >= $peak * 1e-3 } @strong;

    # Each partial its phase; with unison_sync its copies the same one.
    my (@all, @phase);
    if ($copies > 1 && $extra) {
        my @detuned = @strong > $extra ? @strong[ 0 .. $extra - 1 ] : @strong;
        my @own     = $p->{unison_sync} ? map { TWO_PI * $self->_random } @strong : ();
        for my $copy (0 .. $copies - 1) {
            my $cents = $detune * ($copy / ($copies - 1) - 0.5);
            my $shift = 2**($cents / 1200);
            my @these = $copy == 0 ? @strong : @detuned;
            push @all, map { [ $_->[0] * $shift, @$_[ 1 .. 3 ] ] } @these;
            push @phase, $p->{unison_sync} ? @own[ 0 .. $#these ] : map { TWO_PI * $self->_random } @these;
        }
    }
    else {
        @all   = @strong;
        @phase = map { TWO_PI * $self->_random } @all;
    }

    # An RMS of 0.5 before the level; partials near Nyquist fade out, so that
    # a bend cannot alias them in.
    my $sum = 0;
    $sum += $_->[1]**2 for @all;
    my $norm = $sum > 0 ? 0.5 / sqrt($sum / 2) : 0;
    for my $partial (@all) {
        my $f    = $partial->[0] * $f0;
        my $fade = (0.48 * $rate - $f) / (0.03 * $rate);
        $fade = 1 if $fade > 1;
        $fade = 0 if $fade < 0;
        $partial->[1] *= $norm * $fade;
    }

    $self->{ratio}  = [ map { $_->[0] } @all ];
    $self->{amp}    = [ map { $_->[1] } @all ];
    $self->{decay}  = [ map { $_->[2] } @all ];
    $self->{attack} = [ map { $self->{legato} ? 0 : $_->[3] } @all ];
    $self->{phase}  = \@phase;
    return;
}

# The patch's partials at this key and velocity, as [ ratio, amplitude,
# decay, attack ]: its explicit ones, or its harmonic spectrum.
sub _spectrum ($self, $vel) {
    my $p         = $self->{patch};
    my $f0        = $self->{f0};
    my $top       = 0.45 * $self->{rate};
    my $keyfactor = 2**(($self->{key} - 60) / 12 * $p->{decay_key});
    my $decay_k   = $p->{decay_k} * 2**(($self->{key} - 60) / 12 * $p->{decay_k_key});

    if ($p->{partials}) {
        my @set;
        my $i = 0;
        for my $partial (@{ $p->{partials} }) {
            my ($ratio, $amp, $factor) = @$partial;
            push @set, [ $ratio, $amp, $p->{decay} * ($factor // 1) * $keyfactor, $p->{attack_k} * $i++ ];
        }
        return @set;
    }

    my $cutoff = $p->{cutoff} * ($f0 / 261.6)**$p->{track} * 2**($p->{bright} * ($vel - 0.75) * 2) * $self->{shape}{bright};
    my $q      = 0.7071067811865476 * $self->{shape}{q};    # two poles; at the patches' own q, without a peak
    my $B      = $p->{stretch} * 2**(($self->{key} - 60) / 12 * $p->{stretch_key});

    my @set;
    for my $k (1 .. $p->{max}) {
        my $ratio = $k * sqrt(1 + $B * $k * $k);
        my $f     = $ratio * $f0;
        last if $f > $top;

        my $x   = $f / $cutoff;
        my $amp = $k**-$p->{slope} / sqrt((1 - $x * $x)**2 + ($x / $q)**2)**(1 + $p->{rolloff});
        $amp *= $p->{even} if $k % 2 == 0;
        $amp *= abs(sin(PI * $k * $p->{pluck})) if $p->{pluck};
        for my $formant (@{ $p->{formants} }) {
            my ($centre, $gain, $width) = @$formant;
            $amp *= 1 + $gain * exp(-(log($f / $centre) / log(2) / $width)**2);
        }
        push @set, [ $ratio, $amp, $p->{decay} * (1 + $decay_k * ($k - 1)) * $keyfactor, $p->{attack_k} * ($k - 1) ];
    }
    return @set;
}

# The noise: up to three bands, white noise each through its filter (band-,
# high- or low-pass) under its own level, attack and decay; and noise on
# the partials, low-passed white noise moving their amplitude.
sub _noise ($self) {
    my $p    = $self->{patch};
    my $rate = $self->{rate};

    my @bands;
    for my $name ('noise', 'noise2', 'noise3') {
        next if $p->{$name} <= 0;

        my $centre = $p->{"${name}_ratio"} ? $p->{"${name}_ratio"} * $self->{f0} : $p->{"${name}_center"};
        $centre = 0.45 * $rate if $centre > 0.45 * $rate;
        $centre = 20 if $centre < 20;
        my $mode  = $NOISE_MODE{ $p->{"${name}_mode"} } // die "no noise mode '" . $p->{"${name}_mode"} . "'\n";
        my $q     = $p->{"${name}_q"} > 0.1 ? $p->{"${name}_q"} : 0.1;
        my $poles = $p->{"${name}_poles"} == 4 ? 4 : 2;
        my $share = _noise_share($mode, $centre, $q, $rate);
        $share /= 2 if $poles == 4 && $mode == 0;    # a band-pass squared lets half the noise through

        my %band = (
            level   => $p->{$name} * 0.7 / (0.577 * sqrt($share)),
            centre  => $centre,
            mode    => $mode,
            poles   => $poles,
            k       => 1 / $q,
            g       => sin(PI * $centre / $rate) / cos(PI * $centre / $rate),
            attack  => $p->{"${name}_attack"},
            decay   => $p->{"${name}_decay"},
            sustain => $p->{"${name}_sustain"},
            state   => [ 0, 0, int($self->_random * NOISE_SIZE), 0, 0 ],    # the filter's two, the table's position, the second stage's
        );
        if ((my $grains = $p->{"${name}_grains"}) > 0) {
            # A grain's loudness has mean 3/4 and mean square 7/12: the sum's
            # mean and variance as Campbell's theorem has them, made 1.
            my $decay    = $p->{"${name}_grain_decay"};
            my $mean     = $grains * 0.75 / $decay;
            my $variance = $grains * 7 / 12 / (2 * $decay);
            $band{grains}      = $grains;
            $band{grain_decay} = $decay;
            $band{grain_scale} = 1 / sqrt($mean * $mean + $variance);
            $band{grain}       = [ 0, 0, $self->_wait($grains) ];    # time, sum, the next grain's time
        }
        push @bands, \%band;
    }
    $self->{bands} = \@bands;
    $self->{noise} = scalar @bands;

    if ($p->{rough} > 0) {
        # White noise of the table (RMS 1/sqrt 3) through a one-pole low-pass
        # has an RMS of sqrt(a / (2 - a) / 3): made 1, times the depth.
        my $a = 1 - exp(-TWO_PI * $p->{rough_rate} / $rate);
        $self->{rough}  = [ $p->{rough} * sqrt(3 * (2 - $a) / $a), $a ];
        $self->{rstate} = [ 0, int($self->_random * NOISE_SIZE) ];
    }
    return;
}

# Seconds to the next of $rate events a second that come at random moments.
sub _wait ($self, $rate) { return -log(1 - $self->_random) / $rate }

# A band's grains at time $t: bursts at random moments, grains a second,
# each of a loudness between half and whole that falls at grain_decay; their
# sum, of mean square 1 (whatever the rate). Asked for in time order; the
# same time twice (a quantum's last edge and the next's first), the same.
sub _grains ($self, $band, $t) {
    my ($last, $sum, $next) = @{ $band->{grain} };
    if ($t > $last) {
        my ($rate, $decay) = @$band{qw(grains grain_decay)};
        $sum *= exp(-$decay * ($t - $last));
        while ($next <= $t) {
            $sum  += (0.5 + 0.5 * $self->_random) * exp(-$decay * ($t - $next));
            $next += $self->_wait($rate);
        }
        $band->{grain} = [ $t, $sum, $next ];
    }
    return $sum * $band->{grain_scale};
}

# A band's share of the spectrum, which sets how much white noise it lets
# through: its level is made independent of the band's width.
sub _noise_share ($mode, $centre, $q, $rate) {
    my $nyquist = 0.5 * $rate;
    my $share   = $mode == 1 ? ($nyquist - $centre) / $nyquist    # high-pass
                : $mode == 2 ? $centre / $nyquist                  # low-pass
                :              ($centre / $q) / $nyquist;          # band-pass
    return 1     if $share > 1;
    return 0.002 if $share < 0.002;
    return $share;
}

# The string (Karplus-Strong, as Jaffe and Smith extend it): a delay line
# of a period, its loop a two-tap low-pass and a gain that makes it fall
# 60 dB in the patch's time, whatever the pitch. It starts with a period
# of the string's velocity, fed into the loop as it runs (so that the loop
# repeats it whole, its filters' delay as much part of the period as the
# line's): plucked, as the pick lets it go, two levels that change where it
# is plucked (its harmonics fall as sin(k pi pick) / k, none with a node at
# the pick); struck, the hammer's blow, a pulse less its copy a pick's
# length round (harmonics as sin(k pi pick), not falling); and a share of
# noise taken less its copy (the same nodes). Low-passed by how bright the
# pluck is (a hammer's felt: how hard it is); at unit RMS. A stiff string
# has four allpasses in its loop (see _dispersion). The line is long enough
# for the pitch to fall two octaves.
sub _string ($self, $vel) {
    my $p = $self->{patch};
    return if $p->{string} <= 0;

    my $excite = $p->{string_excite};
    die "no string excitation '$excite'\n" if $excite ne 'pluck' && $excite ne 'strike';

    my $rate   = $self->{rate};
    my $period = $rate / $self->{f0};
    my $size   = 64;
    $size *= 2 while $size < 4 * $period + 8;
    my $t60    = $p->{string_decay} * (261.6 / $self->{f0})**$p->{string_key};
    my $bright = $p->{string_bright} * 2**($p->{string_vel} * ($vel - 0.75) * 2);
    $bright = 1     if $bright > 1;
    $bright = 0.005 if $bright < 0.005;

    # Where along the period the pick is.
    my $length = int($period + 0.5) || 1;
    my $at     = int($p->{string_pick} * $period + 0.5);
    $at = 1 if $at < 1;
    $at = $length - 1 if $at > $length - 1 && $length > 1;

    my @shape = $excite eq 'pluck'
        ? _unit(map { $_ < $at ? 1.0 : 0.0 } 0 .. $length - 1)
        : _unit(map { $_ == 0 ? 1.0 : $_ == $at ? -1.0 : 0.0 } 0 .. $length - 1);

    # The noise, less its copy taken round the period, as the loop repeats it.
    my $table = noise_table();
    my $index = int($self->_random * NOISE_SIZE);
    my @noise = map { $table->[ ($index + $_) % NOISE_SIZE ] } 0 .. $length - 1;
    @noise = _unit(map { $noise[$_] - $noise[ ($_ - $at) % $length ] } 0 .. $length - 1);

    my $mix   = $p->{string_noise};
    my @pluck = map { (1 - $mix) * $shape[$_] + $mix * $noise[$_] } 0 .. $length - 1;

    # Low-passed, round the period too (twice through, the second kept).
    my $y = 0;
    for my $pass (1, 2) {
        for my $i (0 .. $length - 1) {
            $y += $bright * ($pluck[$i] - $y);
            $pluck[$i] = $y if $pass == 2;
        }
    }

    my $s1 = $p->{string_damp};
    my ($stages, $a) = $p->{string_stiff} > 0 ? _dispersion($rate, $self->{f0}, $s1, $p->{string_stiff}) : (0, 0.0);
    my $w0 = TWO_PI * $self->{f0} / $rate;

    $self->{string} = {
        level  => $p->{string} * 0.5,
        g      => 10**(-3 * $period / ($t60 * $rate)),    # the loop's gain
        s1     => $s1,
        off    => (_lp_lag($s1, $w0) + $stages * _ap_lag($a, $w0)) / $w0,
        stages => $stages,
        a      => $a,
        buf    => [ (0.0) x $size ],
        pos    => 0,
        prev   => 0.0,
        ax     => 0.0,
        ay     => 0.0,
        disp   => [ (0.0) x 8 ],
        exc    => [ _unit(@pluck) ],
        fed    => 0,
        t60    => $t60,
    };
    return;
}

# Values less their mean, at unit RMS.
sub _unit (@x) {
    my $mean = 0;
    $mean += $_ for @x;
    $mean /= @x;

    my $sum = 0;
    $sum += ($_ - $mean)**2 for @x;
    my $norm = $sum > 0 ? 1 / sqrt($sum / @x) : 0;

    return map { ($_ - $mean) * $norm } @x;
}

# Phase lags (radians) at w (radians a sample): of a first-order allpass
# (a + z^-1) / (1 + a z^-1); of the string's low-pass (1 - s1) + s1 z^-1.
sub _ap_lag ($a, $w)  { return atan2(sin $w, $a + cos $w) - atan2($a * sin $w, 1 + $a * cos $w) }
sub _lp_lag ($s1, $w) { return atan2($s1 * sin $w, 1 - $s1 + $s1 * cos $w) }

# A stiff string's harmonics sharp, as stretch has the partials: harmonic
# k at k sqrt(1 + B k^2) / sqrt(1 + B) times the fundamental. Four
# first-order allpasses in the loop, all of one coefficient (negative: a
# delay that falls with frequency), fitted so that the loop as the engines
# run it (the line, the fractional allpass, the low-pass and the four)
# rings harmonic K there, K = 8 or the highest below 0.45 of the rate:
# the harmonics up to the tenth within some 3 cents at B = 0.0004 (25 at
# 0.002), those above less sharp than they should be. Bisection on the
# coefficient, a resonance found by bisection too; remembered by note.
my %DISPERSION;

sub _dispersion ($rate, $f0, $s1, $B) {
    my $K = int(0.45 * $rate / $f0);
    $K = 8 if $K > 8;
    return (0, 0.0) if $K < 2;

    my $note = "$rate $f0 $s1 $B";
    return @{ $DISPERSION{$note} } if $DISPERSION{$note};

    my $w0     = TWO_PI * $f0 / $rate;
    my $target = $w0 * $K * sqrt((1 + $B * $K * $K) / (1 + $B));
    my ($lo, $hi) = (-0.98, 0.5);
    for (1 .. 40) {
        my $a = 0.5 * ($lo + $hi);
        my $d = TWO_PI / $w0 - (_lp_lag($s1, $w0) + 4 * _ap_lag($a, $w0)) / $w0;
        if ($d < 2) { $lo = $a; next }    # more delay than the period has

        my $whole = int($d - 0.1);
        my $frac  = $d - $whole;
        my $eta   = (1 - $frac) / (1 + $frac);

        # Where the loop rings harmonic K, at this coefficient.
        my ($wl, $wh) = (0.5 * $target, $target * 1.5 > 3.14 ? 3.14 : $target * 1.5);
        for (1 .. 50) {
            my $w   = 0.5 * ($wl + $wh);
            my $lag = $w * $whole + _ap_lag($eta, $w) + _lp_lag($s1, $w) + 4 * _ap_lag($a, $w);
            if ($lag < TWO_PI * $K) { $wl = $w } else { $wh = $w }
        }
        if (0.5 * ($wl + $wh) < $target) { $hi = $a } else { $lo = $a }    # flat: more dispersion
    }

    $DISPERSION{$note} = [ 4, 0.5 * ($lo + $hi) ];
    return @{ $DISPERSION{$note} };
}

# FM's algorithms: [a34 a24 a23 a14 a13 a12] (who modulates whom), and which
# operators are carriers [1 2 3 4]. Modulation flows from higher operators
# to lower, so they are computed 4, 3, 2, 1.
my %ALGORITHM = (
    1 => [ [ 1, 0, 1, 0, 0, 1 ], [ 1, 0, 0, 0 ] ],    # 4 > 3 > 2 > 1
    2 => [ [ 0, 1, 1, 0, 0, 1 ], [ 1, 0, 0, 0 ] ],    # (4 + 3) > 2 > 1
    3 => [ [ 0, 0, 1, 1, 0, 1 ], [ 1, 0, 0, 0 ] ],    # (4 + (3 > 2)) > 1
    4 => [ [ 1, 0, 0, 0, 1, 1 ], [ 1, 0, 0, 0 ] ],    # ((4 > 3) + 2) > 1
    5 => [ [ 1, 0, 0, 0, 0, 1 ], [ 1, 0, 1, 0 ] ],    # 4 > 3, 2 > 1
    6 => [ [ 1, 1, 0, 1, 0, 0 ], [ 1, 1, 1, 0 ] ],    # 4 > 3, 2, 1
    7 => [ [ 1, 0, 0, 0, 0, 0 ], [ 1, 1, 1, 0 ] ],    # 4 > 3; 2; 1
    8 => [ [ 0, 0, 0, 0, 0, 0 ], [ 1, 1, 1, 1 ] ],    # 4; 3; 2; 1
);

# FM made ready: each operator's frequency to the fundamental, its level
# (velocity and key scaled), the algorithm as coefficients.
sub _fm ($self, $vel) {
    my $p = $self->{patch};
    return if $p->{fm} <= 0;

    my $algorithm = $ALGORITHM{ int $p->{fm_alg} } // die "no FM algorithm '$p->{fm_alg}'\n";
    my (@ratio, @base);
    for my $o (1 .. 4) {
        push @ratio, $p->{"op${o}_ratio"} * 2**($p->{"op${o}_detune"} / 1200);
        my $sens = $p->{"op${o}_vel"};
        push @base, $p->{"op${o}_level"} * (1 - $sens + $sens * $vel) * ($self->{f0} / 261.6)**(-$p->{"op${o}_key"});
    }

    $self->{fm} = {
        level   => $p->{fm} * 0.5,
        ratio   => \@ratio,
        base    => \@base,
        coef    => $algorithm->[0],
        carrier => $algorithm->[1],
        fb      => $p->{fm_fb} * PI,
        phase   => [ 0, 0, 0, 0 ],
        hist    => [ 0, 0 ],    # operator 4's last two outputs
    };
    return;
}

# The patch's filter and routes, made ready: [source, destination, amount]
# by number; with a filter, brightness (CC74) and resonance (CC71) move it
# (as the sound controllers would the spectrum) and so do the second
# envelope and velocity as the patch says. Without one, where a controller
# moves the cutoff, a low-pass of 12 dB at half the rate (as good as none
# until it is moved).
sub _modulation ($self, $vel) {
    my $p    = $self->{patch};
    my $mode = $FILTER{ $p->{filter} } // die "no filter '$p->{filter}'\n";

    my @routes;
    for my $route (@{ $p->{mods} // [] }) {
        my ($from, $to, $amount) = @$route;
        my $source      = $SOURCE{$from}    // die "no modulation source '$from'\n";
        my $destination = $DESTINATION{$to} // die "no modulation destination '$to'\n";
        push @routes, [ $source, $destination, $amount ];
    }
    if ($mode) {
        push @routes, [ $SOURCE{cc74}, $DESTINATION{cutoff}, 4 ], [ $SOURCE{cc71}, $DESTINATION{q}, 64 / 24 ];
        push @routes, [ $SOURCE{env2}, $DESTINATION{cutoff}, $p->{filter_env} ] if $p->{filter_env};
    }

    my $implied = !$mode && $self->{cutoff_control};
    return if !$mode && !$implied && !@routes;

    my $cutoff = $implied
        ? 0.5 * $self->{rate}
        : $p->{filter_cutoff} * ($self->{f0} / 261.6)**$p->{filter_track} * 2**($p->{filter_vel} * ($vel - 0.75) * 2);
    $self->{fmode} = $implied ? LOW_PASS_12 : $mode;
    $self->{mod}   = {
        routes => \@routes,
        used   => { map { $_->[0] => 1 } @routes },    # the sources that are read
        to     => { map { $_->[1] => 1 } @routes },    # the destinations that are written
        cutoff => $cutoff,
        q      => $implied ? 0.7071 : $p->{filter_q},
        lfo    => [ map { _lfo_spec($p, $_) } 1, 2 ],
    };
    return;
}

# LFO $n of a patch: [ rate, shape, delay ].
sub _lfo_spec ($p, $n) {
    my $shape = $p->{"lfo${n}_shape"};
    return [ $p->{"lfo${n}_rate"}, $SHAPE{$shape} // die("no LFO shape '$shape'\n"), $p->{"lfo${n}_delay"} ];
}

# An LFO ([rate, shape, delay]) at a time: -1 .. 1, faded in over its delay.
sub _lfo ($self, $lfo, $t, $n) {
    my ($rate, $shape, $delay) = @$lfo;
    return 0 if $t <= 0;

    my $phase = $rate * $t;
    my $frac  = $phase - int $phase;
    my $v;
    if ($shape == 0) {
        $v = sin(TWO_PI * $phase);
    }
    elsif ($shape == 1) {
        my $f = $frac + 0.25;
        $f -= 1 if $f >= 1;
        $v = 1 - 4 * abs($f - 0.5);
    }
    elsif ($shape == 2) {
        $v = $frac < 0.5 ? 1 : -1;
    }
    elsif ($shape == 3) {
        $v = 2 * $frac - 1;
    }
    else {
        # Random, held for a period: the period's number and the voice's seed hashed.
        my $h = ((int($phase) + 1) * 2654435761 + $self->{seed} * 40503 + $n * 977) % 4294967296;
        $h = ($h * 1103515245 + 12345) % 2147483648;
        $v = $h / 1073741824 - 1;
    }
    return $delay > 0 && $t < $delay ? $v * $t / $delay : $v;
}

# The second envelope at a time (s since the voice started).
sub _env2 ($self, $t) {
    my $p = $self->{patch};
    return $self->_adsr($t, @$p{qw(env2_attack env2_decay env2_sustain env2_release)});
}

# An envelope of attack (linear), decay (a time constant) to sustain, and
# release (a time constant, from where the key was let go) at a time; a
# legato note has no attack.
sub _adsr ($self, $t, $attack, $decay, $sustain, $release) {
    $attack = 0 if $self->{legato};
    $decay ||= 1e-3;

    my $held = sub ($t) {
        return 0 if $t <= 0;
        return $t / $attack if $t < $attack;
        return $sustain + (1 - $sustain) * exp(-($t - $attack) / $decay);
    };
    return $held->($t) if !defined $self->{released};

    my $released = ($self->{released} - $self->{start}) / $self->{rate};
    return $held->($t) if $t <= $released;
    return $held->($released) * exp(-($t - $released) / ($release || 1e-3));
}

# The destinations at the edges of a quantum's blocks: [pitch, cutoff, q,
# level, pan, noise, fm], each an array of $nb + 1 (undef where nothing routes).
sub _destinations ($self, $first, $nb, $t0, $dt, $channel) {
    my $m = $self->{mod};
    my ($used, $routes) = @$m{qw(used routes)};

    my @out   = map { $m->{to}{$_} ? [ (0.0) x ($nb + 1) ] : undef } 0 .. $#DESTINATIONS;
    my @value = (0) x @SOURCES;
    my @live  = grep { $used->{$_} } 0 .. $#SOURCES;
    for my $j ($first .. $nb) {
        my $t = $t0 + $j * $dt;

        # Each source read at this edge.
        for my $s (@live) {
            my $name = $SOURCES[$s];
            if    ($name eq 'velocity') { $value[$s] = $self->{velocity} / 127 }
            elsif ($name eq 'key')      { $value[$s] = ($self->{key} - 60) / 12 }
            elsif ($name eq 'env2')     { $value[$s] = $self->_env2($t) }
            elsif ($name eq 'lfo1')     { $value[$s] = $self->_lfo($m->{lfo}[0], $t, 1) }
            elsif ($name eq 'lfo2')     { $value[$s] = $self->_lfo($m->{lfo}[1], $t, 2) }
            elsif ($name eq 'pressure') {
                my $channel_pressure = $channel->{chp}[$j];
                $value[$s] = $self->{pressure} > $channel_pressure ? $self->{pressure} : $channel_pressure;
            }
            else { $value[$s] = $channel->{$name}[$j] }
        }

        $out[ $_->[1] ][$j] += $_->[2] * $value[ $_->[0] ] for @$routes;
    }
    return \@out;
}

# A filter's gain at x (a frequency over the cutoff) and Q, by mode (see
# the top): what every engine computes, for the edges of each partial.
sub filter_gain ($x, $q, $mode) {
    return 1 if !$mode;

    my $x2 = $x * $x;
    my $d  = sqrt((1 - $x2) * (1 - $x2) + $x2 / ($q * $q));
    return 1 / $d                                  if $mode == LOW_PASS_12;
    return 1 / ($d * sqrt(1 + $x2 * $x2))          if $mode == LOW_PASS_24;
    return $x2 / $d                                if $mode == HIGH_PASS_12;
    return $x2 * $x2 / ($d * sqrt(1 + $x2 * $x2))  if $mode == HIGH_PASS_24;
    return $x / $q / $d;
}

# A channel's equalizer on the voice: each partial's amplitude, and the
# noise's and the string's levels, times the equalizer's gain at its
# frequency (a band of noise's at its centre, the string's at its pitch).
# From the levels the voice was made with, so it can be applied again as
# the equalizer changes. Nothing is done where nothing would change: a flat
# equalizer on a voice never equalized, or a change that leaves every gain
# as it was (a band at 0 dB moved).
sub equalize ($self, $eq) {
    return $self if !$eq->active && !$self->{amp0};

    $self->{amp0} //= [ @{ $self->{amp} } ];
    $_->{level0}  //= $_->{level} for @{ $self->{bands} };
    my $string = $self->{string};
    $string->{level0} //= $string->{level} if $string;

    my $f0     = $self->{f0};
    my $ratio  = $self->{ratio};
    my $amp0   = $self->{amp0};
    my @amp    = map { $amp0->[$_] * 10**($eq->response($f0 * $ratio->[$_]) / 20) } 0 .. $#$amp0;
    my @levels = map { $_->{level0} * 10**($eq->response($_->{centre}) / 20) } @{ $self->{bands} };
    push @levels, $string->{level0} * 10**($eq->response($f0) / 20) if $string;
    my @now = (map({ $_->{level} } @{ $self->{bands} }), $string ? $string->{level} : ());
    return $self if !_differ(\@amp, $self->{amp}) && !_differ(\@levels, \@now);

    $self->{amp} = \@amp;
    $_->{level} = shift @levels for @{ $self->{bands} };
    $string->{level} = shift @levels if $string;
    delete $self->{gpu_parts};    # what an engine keeps of the partials
    $self->_waves($self->{waves}) if $self->{wave};
    return $self;
}

# Whether two lists of numbers differ.
sub _differ ($x, $y) {
    return 1 if @$x != @$y;
    for my $i (0 .. $#$x) {
        return 1 if $x->[$i] != $y->[$i];
    }
    return 0;
}

# The partials as wave sequences (Peta::Synth::Wavetable), where they are
# harmonics and no filter moves over them: for each copy of the unison its
# shift (its fundamental over the voice's), its sequence, its place in the
# period (radians; the copies one place with unison_sync) and its table.
# An engine reads those and leaves the partials be. Made again, the places
# kept, when the partials change (an equalizer).
sub _waves ($self, $store) {
    my $was = delete $self->{wave};
    return if $self->{fmode} || !@{ $self->{ratio} };

    my $copies = Peta::Synth::Wavetable::harmonics(@$self{qw(ratio amp decay attack)}, $self->{copies}) or return;
    $self->{waves} = $store;

    my $place = $was ? undef : TWO_PI * $self->_random;
    my @wave;
    for my $c (0 .. $#$copies) {
        my ($shift, $partials) = @{ $copies->[$c] };
        my ($at, $table);
        if ($was) {
            ($at, $table) = @{ $was->[$c] }[ 2, 3 ];
        }
        else {
            $at    = $self->{patch}{unison_sync} || $c == 0 ? $place : TWO_PI * $self->_random;
            $table = 0;
        }
        push @wave, [ $shift, $store->sequence($partials), $at, $table ];
    }
    $self->{wave} = \@wave;
    return;
}

# The key was let go at sample $at, with a note-off velocity (64: as the
# patch says; faster lets go faster; 0, as many files write, says nothing).
sub release ($self, $at, $velocity = undef) {
    $self->off_velocity($velocity);
    $self->{released} //= $at if !$self->{patch}{drum};
    delete $self->{envelope_state};
    return;
}

# A note-off velocity, for a release to come (a pedal may hold the note):
# its release time 1.41 times as long at 1, as the patch says at 64, 0.71
# times at 127.
sub off_velocity ($self, $velocity) {
    $self->{rfactor} = 2**((64 - $velocity) / 128) if $velocity;
    delete $self->{envelope_state};
    return;
}

# Ends the voice quickly (voice stealing, all sound off): a release of 5 ms.
sub kill ($self, $at) {
    $self->{killed} //= $at;
    delete $self->{envelope_state};
    return;
}

# The envelope's attack, hold, fall and sustain: the patch's, as the channel
# shaped them; a legato note has no attack.
sub _envelope ($self) {
    my ($p, $shape) = @$self{qw(patch shape)};
    my $attack = $self->{legato} ? 0 : $p->{attack} * $shape->{attack};
    my $fall   = ($p->{fall} || 1e-3) * $shape->{decay};
    return ($attack, $p->{hold}, $fall, $p->{sustain});
}

# The envelope before any release, at a time (s since the voice started).
sub _held ($self, $t) {
    my ($attack, $hold, $fall, $sustain) = $self->_envelope;
    return 0 if $t < 0;
    return $t / $attack if $t < $attack;

    $t -= $attack + $hold;
    return 1 if $t <= 0;
    return $sustain + (1 - $sustain) * exp(-$t / $fall);
}

# What the envelope is made of as things stand: [ attack, hold, fall,
# sustain; the time the key was let go (-1: not), the level then and the
# release's time constant; the time the voice was killed (-1: not); a
# drum's length (-1: none) ], times in seconds since the voice started.
# Kept until the voice is let go, killed or given a note-off velocity.
sub _envelope_state ($self) {
    return $self->{envelope_state} //= $self->_make_envelope_state;
}

sub _make_envelope_state ($self) {
    my $p    = $self->{patch};
    my $rate = $self->{rate};

    my $released = defined $self->{released} ? ($self->{released} - $self->{start}) / $rate : -1;
    my $from     = $released >= 0 ? $self->_held($released) : 0;
    my $release  = ($p->{release} || 1e-3) * $self->{shape}{release} * $self->{rfactor};
    my $killed   = defined $self->{killed} ? ($self->{killed} - $self->{start}) / $rate : -1;
    my $length   = $p->{drum} ? $p->{length} : -1;

    return [ $self->_envelope, $released, $from, $release, $killed, $length ];
}

# The envelope at time $t (raw: before the level and the tremolo): attack,
# hold, fall to sustain; release after the key; 5 ms after a kill; a drum
# fades past its length.
sub _envelope_value ($state, $t) {
    my ($attack, $hold, $fall, $sustain, $released, $from, $release, $killed, $length) = @$state;

    my $e = $t <= 0                ? 0
          : $t < $attack           ? $t / $attack
          : $t <= $attack + $hold  ? 1
          :                          $sustain + (1 - $sustain) * exp(-($t - $attack - $hold) / $fall);

    $e = $from * exp(-($t - $released) / $release) if $released >= 0 && $t > $released;
    $e *= exp(-($t - $killed) / 0.005)             if $killed >= 0 && $t > $killed;
    $e *= exp(-($t - $length) / 0.01)              if $length >= 0 && $t > $length;
    return $e;
}

# The envelope at a time (s since the voice started) as controls works it
# out (raw: before the level and the tremolo), the key let go or not as it
# stands now.
sub envelope_at ($self, $t) { return _envelope_value($self->_envelope_state, $t) }

# The pitch's offset from the note (semitones) at a time, from its glide:
# [from, to, the time it starts, how long it takes].
sub _glide ($self, $t) {
    my $g = $self->{glide} or return 0;
    my ($from, $to, $start, $length) = @$g;
    return $to   if $t >= $start + $length;
    return $from if $t <= $start;
    return $from + ($to - $from) * ($t - $start) / $length;
}

# The voice's controls for a quantum that starts at sample $now: $nb blocks
# of $B samples, the channel's gains, bend (semitones) and modulation at the
# blocks' edges in $channel (and its vibrato's rate, depth and delay as
# factors, its modulation range in cents). Fills t0, w, env, the bands' env,
# gl, gr, gs, the operators' levels, the filter's edges and boost (see the
# top). The parts every voice has are written out here, as this runs for
# every voice and quantum; the parts few have are subs of their own.
sub controls ($self, $now, $nb, $B, $channel) {
    my $p     = $self->{patch};
    my $rate  = $self->{rate};
    my $first = $self->{first};
    my $dt    = $B / $rate;
    my $t0    = ($now - $self->{start}) / $rate;
    my @edges = ($first, $nb, $t0, $dt);
    $self->{t0} = $t0;

    # The envelope at the edges (as _envelope_value has it), times the
    # tremolo and the voice's level.
    my $state = $self->{envelope_state} //= $self->_make_envelope_state;
    my ($attack, $hold, $fall, $sustain, $released, $from, $release, $killed, $length) = @$state;
    my ($trem, $trem_rate) = @$p{qw(tremolo trem_rate)};
    my $level = $self->{level};
    my @env   = (0.0) x ($nb + 1);
    my $raw   = 0;
    for my $j ($first .. $nb) {
        my $t = $t0 + $j * $dt;
        my $e = $t <= 0               ? 0
              : $t < $attack          ? $t / $attack
              : $t <= $attack + $hold ? 1
              :                         $sustain + (1 - $sustain) * exp(-($t - $attack - $hold) / $fall);
        $e = $from * exp(-($t - $released) / $release) if $released >= 0 && $t > $released;
        $e *= exp(-($t - $killed) / 0.005)             if $killed >= 0 && $t > $killed;
        $e *= exp(-($t - $length) / 0.01)              if $length >= 0 && $t > $length;

        $raw = $e;
        $env[$j] = $e * $level * ($trem ? 1 - $trem * (0.5 - 0.5 * cos(TWO_PI * $trem_rate * $t)) : 1);
    }
    $self->{raw_env} = $raw;    # at the quantum's end

    # What few voices have: noise bands, modulation, FM, GM2's controller
    # destinations.
    $self->_noise_edges(@edges) if @{ $self->{bands} };

    my $dest = $self->{mod} ? $self->_destinations(@edges, $channel) : [];
    my ($m_pitch, $m_cutoff, $m_q, $m_level, $m_pan, $m_noise, $m_fm) = @$dest;
    $self->_fm_levels(@edges, $m_fm) if $self->{fm};
    _scale_edges(\@env, $m_level, $first, $nb) if $m_level;
    _scale_edges($_->{env}, $m_noise, $first, $nb) for $m_noise ? @{ $self->{bands} } : ();

    my $gm  = $channel->{dest} || $channel->{kp} ? $self->_gm_destinations(\@env, @edges, $channel) : undef;
    my $gml = $gm ? $gm->{levels} : undef;

    # The fundamental at each block's middle, in radians a sample: key, bend
    # and tuning, vibrato (the modulation wheel and the pressure deepen it),
    # sweep, glide.
    my $f0        = $self->{f0};
    my ($sweep, $sweep_time) = @$p{qw(sweep sweep_time)};
    my $vibrato   = $p->{vibrato}   * ($channel->{vdepth} // 1);
    my $vib_rate  = $p->{vib_rate}  * ($channel->{vrate}  // 1);
    my $vib_delay = $p->{vib_delay} * ($channel->{vdelay} // 1);
    my $pressure  = $channel->{kp} ? 0 : $self->{pressure} * ($channel->{modrange} // 50);
    my ($bend, $mod) = @$channel{qw(bend mod)};
    my $glide = $self->{glide};
    my $scale = TWO_PI / $rate;
    my @w     = (0.0) x $nb;
    for my $j ($first .. $nb - 1) {
        my $t     = $t0 + ($j + 0.5) * $dt;
        my $semis = $bend->[$j];
        $semis += $self->_glide($t) if $glide;
        $semis += 0.5 * ($m_pitch->[$j] + $m_pitch->[$j + 1]) if $m_pitch;
        $semis += 0.5 * ($gml->[0][$j] + $gml->[0][$j + 1]) if $gml;

        my $depth = $vibrato + $mod->[$j] + $pressure + ($gml ? $gml->[3][$j] : 0);
        if ($depth > 0) {
            my $ramp = ($t - $vib_delay) / 0.3;
            $ramp = $ramp < 0 ? 0 : $ramp > 1 ? 1 : $ramp;
            $semis += $depth / 100 * $ramp * sin(TWO_PI * $vib_rate * $t);
        }

        my $f = $f0 * 2**($semis / 12);
        $f *= 1 + $sweep * exp(-$t / $sweep_time) if $sweep;
        $w[$j] = $scale * $f;
    }

    $self->{env}   = \@env;
    $self->{w}     = \@w;
    $self->{boost} = 1;
    $self->_filter_edges(@edges, \@w, $m_cutoff, $m_q, $gm) if $self->{fmode};

    # How far modulation can lift the voice above its envelope.
    $self->{boost} *= _most_of(1, map { 1 + $_ } @$m_level) if $m_level;
    $self->{boost} *= _most_of(1, @{ $gml->[2] }) if $gml;

    # The channel's gains (left, right, reverb send) at the edges; with a pan
    # of the voice's own, or one modulated, the channel's level at the
    # channel's pan and the voice's.
    @$self{qw(gl gr gs)} = @$channel{qw(gl gr gs)};
    if ($self->{pan} || $m_pan) {
        my ($lv, $pn) = @$channel{qw(lv pn)};
        my $pan = $self->{pan} // 0;
        my (@gl, @gr);
        for my $j (0 .. $nb) {
            my ($l, $r) = pan_law($pn->[$j] + $pan + ($m_pan ? $m_pan->[$j] : 0));
            push @gl, $lv->[$j] * $l;
            push @gr, $lv->[$j] * $r;
        }
        @$self{qw(gl gr)} = (\@gl, \@gr);
    }
    $self->{gs} = [ map { $_ * $self->{send} } @{ $self->{gs} } ] if defined $self->{send};

    return $self;
}

# Each band of noise's level at the edges: its attack, its decay to what it
# sustains, its grains.
sub _noise_edges ($self, $first, $nb, $t0, $dt) {
    for my $band (@{ $self->{bands} }) {
        my ($level, $attack, $decay, $sustain) = @$band{qw(level attack decay sustain)};
        my @nenv = (0.0) x ($nb + 1);
        for my $j ($first .. $nb) {
            my $t = $t0 + $j * $dt;
            my $n = $t <= 0       ? 0
                  : $t < $attack  ? $t / $attack
                  :                 $sustain + (1 - $sustain) * exp(-$decay * ($t - $attack));
            $n *= $self->_grains($band, $t) if $band->{grains} && $t > 0;
            $nenv[$j] = $n * $level;
        }
        $band->{env} = \@nenv;
    }
    return;
}

# Each FM operator's level at the edges: its envelope; a modulator's (its
# index) moved by modulation's fm, in octaves.
sub _fm_levels ($self, $first, $nb, $t0, $dt, $m_fm) {
    my $p  = $self->{patch};
    my $fm = $self->{fm};

    my @lv;
    for my $o (0 .. 3) {
        my $q       = $o + 1;
        my @adsr    = @$p{ "op${q}_attack", "op${q}_decay", "op${q}_sustain", "op${q}_release" };
        my $base    = $fm->{base}[$o];
        my $carrier = $fm->{carrier}[$o];
        my @l = (0.0) x ($nb + 1);
        for my $j ($first .. $nb) {
            $l[$j] = $base * $self->_adsr($t0 + $j * $dt, @adsr) * ($m_fm && !$carrier ? 2**$m_fm->[$j] : 1);
        }
        push @lv, \@l;
    }
    $fm->{lv} = \@lv;
    return;
}

# Levels at the edges times 1 + modulation, never below 0.
sub _scale_edges ($levels, $modulation, $first, $nb) {
    for my $j ($first .. $nb) {
        my $g = 1 + $modulation->[$j];
        $levels->[$j] *= $g > 0 ? $g : 0;
    }
    return;
}

# GM2's controller destinations (pitch, cutoff, amplitude, the LFO's depth
# on each): the channel's at the edges, key pressure's (this voice's own)
# on top; the amplitude applied to the envelope here. The LFO is the
# vibrato's: at the edges, its ramp in after its delay and its sine, for the
# cutoff and the amplitude.
sub _gm_destinations ($self, $env, $first, $nb, $t0, $dt, $channel) {
    my ($dest, $kp) = @$channel{qw(dest kp)};
    my $pressure = $self->{pressure};
    my @levels;
    for my $i (0 .. 5) {
        my $k    = $kp ? $kp->[$i] * $pressure : 0;
        my $from = $dest ? $dest->[$i] : [ ($i == 2 ? 1.0 : 0.0) x ($nb + 1) ];
        $levels[$i] = $i == 2 ? [ map { $_ * (1 + $k) } @$from ] : [ map { $_ + $k } @$from ];
    }

    my $vib_rate  = $self->{patch}{vib_rate} * ($channel->{vrate} // 1);
    my $vib_delay = $self->{patch}{vib_delay} * ($channel->{vdelay} // 1);
    my (@ramp, @sine);
    for my $j (0 .. $nb) {
        my $t = $t0 + $j * $dt;
        my $r = ($t - $vib_delay) / 0.3;
        push @ramp, $r < 0 ? 0 : $r > 1 ? 1 : $r;
        push @sine, sin(TWO_PI * $vib_rate * $t);
    }

    for my $j ($first .. $nb) {
        $env->[$j] *= $levels[2][$j] * (1 - $levels[5][$j] * $ramp[$j] * (1 - $sine[$j]) / 2);
    }
    return { levels => \@levels, ramp => \@ramp, sine => \@sine };
}

# The filter at the edges: the fundamental (as the block's pitch has it)
# over the cutoff, and the Q, held to what stays finite. A resonance lifts
# a partial by up to its Q: the boost.
sub _filter_edges ($self, $first, $nb, $t0, $dt, $w, $m_cutoff, $m_q, $gm) {
    my $rate  = $self->{rate};
    my $scale = TWO_PI / $rate;
    my ($cutoff, $q) = @{ $self->{mod} }{qw(cutoff q)};

    my (@fx, @fq);
    my $peak = 1;
    for my $j (0 .. $nb) {
        my $b = $j < $first ? $first : $j < $nb ? $j : $nb - 1;    # the block whose pitch counts
        my $f = ($w->[$b] // 0) / $scale;

        my $octaves = $m_cutoff ? $m_cutoff->[$j] : 0;
        $octaves += $gm->{levels}[1][$j] + $gm->{levels}[4][$j] / 1200 * $gm->{ramp}[$j] * $gm->{sine}[$j] if $gm;
        my $fc = $cutoff * 2**$octaves;
        $fc = 10 if $fc < 10;
        $fc = 0.5 * $rate if $fc > 0.5 * $rate;

        my $qq = $q * 2**($m_q ? $m_q->[$j] : 0);
        $qq = 0.1 if $qq < 0.1;
        $qq = 50  if $qq > 50;

        push @fx, $f / $fc;
        push @fq, $qq;
        $peak = $qq if $qq > $peak;
    }
    @$self{qw(fx fq)} = (\@fx, \@fq);
    $self->{boost} = $peak;
    return;
}

sub _most_of (@values) {
    my $most = shift @values;
    for (@values) { $most = $_ if $_ > $most }
    return $most;
}

# Left and right gains of a pan (-1 left .. 1 right; beyond it, held there):
# constant power, both 1 in the middle.
sub pan_law ($pan) {
    $pan = -1 if $pan < -1;
    $pan = 1  if $pan > 1;
    my $angle = ($pan + 1) * 0.7853981633974483;
    return (cos($angle) * 1.4142135623730951, sin($angle) * 1.4142135623730951);
}

# Whether the voice has fallen under $level (of its full level) for good, at
# time t: past its attack and hold, its envelope as the last quantum ended
# times the loudest it can still get (see bound).
sub under ($self, $t, $level) {
    my ($attack, $hold) = $self->_envelope;
    return $t > $attack + $hold && ($self->{raw_env} // 1) * $self->bound($t) < $level;
}

# The loudest the voice can still get from time t on, for deciding it is done.
sub bound ($self, $t) {
    my ($amp, $decay) = @$self{qw(amp decay)};
    my $peak = 0;
    for my $k (0 .. $#$amp) {
        my $a = $amp->[$k] * exp(-$decay->[$k] * $t);
        $peak = $a if $a > $peak;
    }

    my $noise = 0;
    for my $band (@{ $self->{bands} }) {
        my $now = $t < $band->{attack} ? 1 : $band->{sustain} + (1 - $band->{sustain}) * exp(-$band->{decay} * ($t - $band->{attack}));
        $noise += $band->{level} * $now;
    }

    # Noise on the partials: its peaks some three times its RMS.
    my $rough = 1 + 3 * $self->{patch}{rough};

    # The string: its pluck's peaks some four times its RMS, falling 60 dB in
    # t60. FM: its carriers at their full levels (their envelopes are not
    # followed here).
    my $string = $self->{string} ? 4 * $self->{string}{level} * 10**(-3 * $t / $self->{string}{t60}) : 0;
    if (my $fm = $self->{fm}) {
        $string += $fm->{level} * $fm->{carrier}[$_] * $fm->{base}[$_] for 0 .. 3;
    }

    return (($peak * 1.5 * ($self->{boost} // 1) + $string) * $rough + $noise) * $self->{level};
}

# Whether the voice can only fall from time $t on: let go, killed, a drum,
# or a patch that does not sustain past its attack.
sub _ending ($self, $t) {
    my $p = $self->{patch};
    return defined $self->{released} || defined $self->{killed} || $p->{drum}
        || ($p->{sustain} == 0 && $t > $p->{attack} + $p->{hold});
}

# Whether the voice is silent for good at time $t, the end of the quantum its
# controls were last computed for.
sub done ($self, $t) {
    return 0 if !$self->_ending($t) && $self->bound($t) >= SILENT;
    return ($self->{raw_env} // 1) * $self->bound($t) < SILENT;
}

# When the voice will be silent for good (s since it started; 'inf' if it
# never will), as things stand: let go or held, killed or not. done's test,
# searched from the envelope's peak on, where the envelope and the bound
# only fall: by doubling steps, then halving the last, to some 5 ms. Kept
# until the voice is let go or killed.
sub ends ($self) {
    my $state = join ',', map { $_ // '' } @$self{qw(released killed rfactor)};
    return $self->{ends}[1] if $self->{ends} && $self->{ends}[0] eq $state;

    my $silent = sub ($t) {
        my $bound = $self->bound($t);
        return ($self->_ending($t) || $bound < SILENT) && $self->envelope_at($t) * $bound < SILENT;
    };

    my ($attack, $hold) = $self->_envelope;
    my ($low, $step) = ($attack + $hold, 0.05);
    my $end;
    if ($silent->($low)) {
        $end = $low;
    }
    else {
        while (!$silent->($low + $step)) {
            $low  += $step;
            $step *= 2;
            last if $low > 3600;
        }
        $end = $low > 3600 ? 'inf' : _bisect($silent, $low, $low + $step);
    }

    $self->{ends} = [ $state, $end ];
    return $end;
}

# Where $test turns true between $low (false) and $high (true), to 5 ms.
sub _bisect ($test, $low, $high) {
    while ($high - $low > 0.005) {
        my $mid = ($low + $high) / 2;
        if ($test->($mid)) { $high = $mid } else { $low = $mid }
    }
    return $high;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::Voice - a sounding note: partials, noise, envelope, pitch

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $voice = Peta::Synth::Voice->new(Peta::Synth::Patch::program(0),
        key => 60, velocity => 100, rate => 48000, partials => 48, start => 0);

=head1 DESCRIPTION

The voice model: sine partials, a plucked string (Karplus-Strong), four FM
operators, up to three bands of white noise and noise on the partials,
under an envelope; a filter that moves over the partials; routes of
modulation from velocity, key, the channel's controllers, a second
envelope and two LFOs. Made from a L<Peta::Synth::Patch>; the distribution's
F<doc/synthesis.md> tells it whole. The synthesizer
(L<Peta::Synth::Synth>) asks a voice for its controls block by block and
hands the voices to an engine, which turns them into samples; the fields
an engine reads are listed at the top of the source.

=head1 METHODS

=head2 new

C<< new($patch, key => ..., velocity => ..., rate => ..., partials => ..., start => ..., seed => ...) >>.
C<partials> is the most partials the voice may have (the quality); the
strongest of the patch's spectrum are kept.

=head2 release, kill

C<release($sample, $velocity)>: the key was let go at that sample (drums
ignore it); the note-off velocity, where given, shortens (above 64) or
lengthens the release.
C<kill($sample)>: end within a few milliseconds.

=head2 controls

C<controls($now, $nb, $B, $channel)>: the voice's envelope, noise level,
pitch and gains for a quantum of C<$nb> blocks of C<$B> samples starting at
sample C<$now>; C<$channel> holds the channel's gains, bend and modulation
at the blocks' edges (C<gl gr gs bend mod lv pn>, arrays of C<$nb + 1>;
bend in semitones, mod in cents of vibrato, lv the level, pn the pan) and
as single values C<vrate vdepth vdelay> (factors on the patch's vibrato)
and C<modrange> (cents of vibrato at full pressure). Where GM2's controller
destinations are set: C<dest>, six arrays of C<$nb + 1> (pitch in
semitones, cutoff in octaves, amplitude as a factor, the LFO's depth on
pitch and cutoff in cents and on amplitude from 0 to 1), and C<kp>, the
same six at full key pressure (amplitude less 1), for the voice's own
pressure.

=head2 pan_law

C<pan_law($pan)>: the left and right gains of a pan from -1 to 1.

=head2 bound, done, under, ends, envelope_at

C<bound($t)>: the loudest the voice can still get from a time on (seconds
since it started); C<done($t)>: whether it is silent for good;
C<under($t, $level)>: whether it has fallen under C<$level> of its full
level for good (past its attack); C<ends>: when it will be silent for
good (C<inf>: never), as things stand; C<envelope_at($t)>: its envelope
then (before the level and tremolo).

=head2 equalize

C<equalize($eq)>: a channel's equalizer (L<Peta::Synth::EQ>) on the voice:
each partial's level times the equalizer's gain at its frequency (a
band of noise's at its centre, the string's at its pitch), from the
levels it was made with, so that it can be applied again as the
equalizer changes. Nothing is done where nothing would change.

=head2 off_velocity

C<off_velocity($velocity)>: a note-off velocity for a release to come:
the release 1.41 times as long at 1, as the patch says at 64, 0.71 times
at 127.

=head2 partials

How many partials the voice has.

=head1 FUNCTIONS

=head2 noise_table

The table of white noise every engine reads, the same on every perl.

=head2 filter_gain

C<filter_gain($x, $q, $mode)>: a filter's gain at C<$x> (a frequency
over the cutoff) and Q, by mode: what every engine computes for the edges
of each partial.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
