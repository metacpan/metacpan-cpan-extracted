package Peta::Synth::Patch;
# ABSTRACT: the General MIDI instruments, their variations, and the drum kits

# The instruments: what a note of each General MIDI program and each drum
# key is made of, in the one voice model every engine plays; and the
# variations of programs and the drum kits that GS, GM2 and XG select by
# bank and program.
#
# A voice is a bank of sine partials and up to three bands of noise:
#
#   partial k   frequency  f0 * ratio_k (times the pitch: bend, vibrato, sweep)
#               amplitude  amp_k * exp(-decay_k * t) * (1 - exp(-t / attack_k))
#   noise       white noise through a band-, high- or low-pass (centre Hz, q;
#               two poles or four), its level rising over noise_attack and
#               falling at noise_decay towards noise_sustain, steady or in
#               bursts at random moments (grains); noise2 and noise3 the same;
#               rough, noise moving the partials' amplitude
#   envelope    attack (linear), decay to sustain (exponential), release
#               after the note's end (exponential): over the whole voice
#
# A patch describes the partials either as a spectrum (harmonics shaped by
# a slope, odd/even balance, formants, a low-pass, a pluck position, an
# inharmonicity) or as a list of explicit [ratio, amplitude, decay factor]
# partials, for bells, mallets and drums. Each GM program is a family's
# template with its own changes; the fields are documented with %DEFAULT.

use v5.36;

our $VERSION = '0.2610180';

my %DEFAULT = (
    # the harmonic spectrum
    slope       => 1.0,      # amplitude of harmonic k: k ** -slope
    even        => 1.0,      # even harmonics times this (0.1: clarinet-like; 1.5: an octave reed besides)
    cutoff      => 8000,     # soft low-pass (Hz), 12 dB per octave above it
    rolloff     => 0,        # ... and 12 more an octave for each one here (a hammer's felt: steeper)
    track       => 0.5,      # the cutoff follows the key: (f0 / 261.6) ** track
    bright      => 1.0,      # velocity opens the cutoff: 2 ** (bright * (v - 0.75) * 2)
    pluck       => 0,        # pluck/strike position (0..0.5): harmonics with a node there are weak
    formants    => [],       # [centre Hz, gain, width in octaves], added to the spectrum
    stretch     => 0,        # inharmonicity B: harmonic k at k * sqrt(1 + B k^2)
    stretch_key => 0,        # B grows with the key: times 2 ** ((key - 60) / 12 * stretch_key)
    partials    => undef,    # explicit [ratio, amplitude, decay factor] instead of the harmonic spectrum
    max         => 256,      # harmonics at most

    # the partials over time
    decay       => 0,        # 1/s, of the fundamental
    decay_k     => 0,        # partial k decays (1 + decay_k (k - 1)) times faster
    decay_key   => 0,        # and 2 ** ((key - 60) / 12 * decay_key) times faster with pitch
    decay_k_key => 0,        # decay_k grows with the key: times 2 ** ((key - 60) / 12 * decay_k_key) (a piano's treble)
    attack_k    => 0,        # s: partial k fades in over attack_k * (k - 1) (brass speaks low first)

    # the whole voice
    attack      => 0.005,
    hold        => 0,        # s at full level before the decay
    fall        => 1.0,      # s: decay time constant towards sustain
    sustain     => 1.0,
    release     => 0.2,      # s: time constant after the note's end (30 dB in 3.45 of them)
    level       => 1.0,
    velocity    => 1.6,      # loudness: (velocity / 127) ** this

    # pitch
    transpose   => 0,        # semitones
    sweep       => 0,        # pitch starts sweep times higher (ratio - 1) ...
    sweep_time  => 0.05,     # ... and falls back with this time constant
    vibrato     => 0,        # cents
    vib_rate    => 5.5,
    vib_delay   => 0.3,
    tremolo     => 0,        # amplitude modulation depth (0..1)
    trem_rate   => 5,
    unison      => 1,        # copies of the partials, detuned
    detune      => 0,        # cents between the outermost copies
    unison_k    => 8,        # the copies carry this many partials
    unison_sync => 0,        # 1: the copies begin in phase (strings struck by one hammer)

    # noise
    noise         => 0,
    noise_center  => 3000,   # Hz; with noise_ratio, times f0 instead
    noise_ratio   => 0,
    noise_q       => 1.0,
    noise_attack  => 0.001,
    noise_decay   => 30,     # 1/s
    noise_sustain => 0,      # level that is left (breath)
    noise_mode    => 'band', # band, high or low (-pass)
    noise_poles   => 2,      # 2: 12 dB an octave (band-pass 6), 4: twice that
    noise_grains  => 0,      # bursts a second at random moments (applause, rain); 0: steady
    noise_grain_decay => 150,    # how fast a burst falls (1/s)
    # a second and a third band, the same fields
    _band_defaults('noise2'),
    _band_defaults('noise3'),
    # a plucked or struck string (Karplus-Strong): a delay line a period
    # long, its loop damped and decaying, started with a pluck or a
    # hammer's blow; beside the partials (give the patch partials => [] for
    # a string alone)
    string        => 0,      # its level
    string_decay  => 4,      # s it takes to fall 60 dB, at middle C
    string_key    => 0.5,    # higher keys decay faster: (261.6 / f0) ** this
    string_damp   => 0.3,    # the loop's low-pass (0: none; more: the highs die sooner)
    string_pick   => 0.13,   # where along the string it is plucked or struck (0 .. 0.5)
    string_bright => 0.5,    # how bright the pluck is (0 .. 1)
    string_vel    => 1,      # how much velocity brightens it
    string_noise  => 0.25,   # how much of the pluck is noise (the rest the string's shape)
    string_excite => 'pluck',  # pluck or strike (a hammer: string_bright its hardness)
    string_stiff  => 0,      # stiffness, as stretch: harmonic k at k * sqrt(1 + B k^2)

    # FM: four sine operators, each modulated by the sum of others' outputs
    # as the algorithm (1 .. 8, those of Yamaha's four-operator chips) says;
    # operator 4 also by itself (feedback). A carrier's level is its
    # amplitude, a modulator's the index it modulates with (radians). Beside
    # the partials, or alone (partials => []).
    fm     => 0,             # the FM's level
    fm_alg => 1,
    fm_fb  => 0,             # operator 4's feedback (0 .. 1: up to pi)
    (map { _operator_defaults($_) } 1 .. 4),

    # noise on the partials: their amplitude moved by noise low-passed at
    # rough_rate, rough its depth (breath, bow, growl)
    rough      => 0,
    rough_rate => 200,       # Hz

    # the filter that moves: over the partials, its cutoff and resonance
    # modulated while the note sounds (the spectrum's cutoff above is fixed
    # when the note begins)
    filter        => 'off',  # off lp12 lp24 hp12 hp24 bp
    filter_cutoff => 2000,   # Hz, at middle C
    filter_track  => 1,      # how much the cutoff follows the key
    filter_q      => 0.71,   # resonance
    filter_env    => 0,      # octaves the second envelope moves the cutoff, at its peak
    filter_vel    => 0,      # octaves velocity moves it (from 0.75 of the full velocity)

    # the second envelope (a source of modulation): attack (linear), decay
    # (time constant) to sustain, release (time constant)
    env2_attack  => 0.01,
    env2_decay   => 0.3,
    env2_sustain => 0,
    env2_release => 0.3,

    # two LFOs (sources of modulation), from the note's start
    lfo1_rate  => 5,         # Hz
    lfo1_shape => 'sine',    # sine triangle square saw random
    lfo1_delay => 0,         # s it fades in over
    lfo2_rate  => 0.5,
    lfo2_shape => 'triangle',
    lfo2_delay => 0,

    # routes: [source, destination, amount]; see mod_sources, mod_destinations
    mods => [],

    drum      => 0,
    fixed     => 0,          # Hz: a drum sounds at this pitch whatever the key
    length    => 0,          # s: a drum that ignores note off rings this long at most
);

# The defaults of a noise band's fields, $band its name.
sub _band_defaults ($band) {
    return (
        $band             => 0,
        "${band}_center"  => 3000,
        "${band}_ratio"   => 0,
        "${band}_q"       => 1.0,
        "${band}_attack"  => 0.001,
        "${band}_decay"   => 30,
        "${band}_sustain" => 0,
        "${band}_mode"    => 'band',
        "${band}_poles"   => 2,
        "${band}_grains"  => 0,
        "${band}_grain_decay" => 150,
    );
}

# The defaults of FM operator $o's fields: operators 1 and 2 sound, 3 and 4
# are silent.
sub _operator_defaults ($o) {
    return (
        "op${o}_ratio"   => 1,
        "op${o}_detune"  => 0,
        "op${o}_level"   => $o <= 2 ? 1 : 0,
        "op${o}_attack"  => 0.002,
        "op${o}_decay"   => 1,
        "op${o}_sustain" => 1,
        "op${o}_release" => 0.3,
        "op${o}_vel"     => 0.5,
        "op${o}_key"     => 0,
    );
}

# Modulation: its sources (with their ranges), its destinations (with what
# an amount of 1 does). Bipolar sources swing -1 .. 1, the others 0 .. 1.
my @MOD_SOURCES = (
    [ velocity => 'the note\'s velocity, 0 .. 1' ],
    [ key      => 'the key, in octaves from middle C' ],
    [ wheel    => 'the modulation wheel (CC1)' ],
    [ breath   => 'the breath controller (CC2)' ],
    [ foot     => 'the foot controller (CC4)' ],
    [ pressure => 'channel or key pressure, the greater' ],
    [ cc74     => 'brightness (CC74), -1 .. 1 around 64' ],
    [ cc71     => 'resonance (CC71), -1 .. 1 around 64' ],
    [ env2     => 'the second envelope, 0 .. 1' ],
    [ lfo1     => 'the first LFO, -1 .. 1' ],
    [ lfo2     => 'the second LFO, -1 .. 1' ],
);
my @MOD_DESTINATIONS = (
    [ pitch  => 'semitones' ],
    [ cutoff => 'octaves of the filter\'s cutoff' ],
    [ q      => 'octaves of the filter\'s resonance (Q times 2^amount)' ],
    [ level  => 'the level, times 1 + amount' ],
    [ pan    => 'the pan, -1 left .. 1 right' ],
    [ noise  => 'the noise\'s level, times 1 + amount' ],
    [ fm     => 'octaves of FM\'s modulation index (its modulators\' levels times 2^amount)' ],
);
sub mod_sources ()      { return [ map { $_->[0] } @MOD_SOURCES ] }
sub mod_destinations () { return [ map { $_->[0] } @MOD_DESTINATIONS ] }
sub mod_info () {
    return {
        sources      => [ map { { name => $_->[0], about => $_->[1] } } @MOD_SOURCES ],
        destinations => [ map { { name => $_->[0], about => $_->[1] } } @MOD_DESTINATIONS ],
    };
}

sub _make (%arg) {
    my %patch = (%DEFAULT, %arg);
    for my $key (keys %arg) { die "patch field '$key' is not known\n" unless exists $DEFAULT{$key} }
    return \%patch;
}

# Families: the templates the programs start from.

# The piano, measured against a recorded grand (FluidR3, with
# bin/peta-analyze): the fundamental strongest, the harmonics as 1/k up to
# some 4 kHz, falling 24 dB an octave above, whatever the key (the hammer's
# felt; less, and the highs ring on as a harpsichord's); the strings stiffer
# up the keyboard (B 0.0003 at middle C, twice that an octave up); a quick
# fall (fall, sustain) before the slow decay; the upper partials dying
# sooner, the more so up the keyboard (decay_k_key: at C6 the 5th some 40
# dB a second); the two strings of a note struck together (unison_sync),
# beating in the lower partials.
my %PIANO = (slope => 1.0, cutoff => 4000, rolloff => 1, track => 0, bright => 1.6, stretch => 0.0003, stretch_key => 1.1,
    decay => 0.5, decay_key => 0.5, decay_k => 0.1, decay_k_key => 1.25, attack => 0.002, fall => 0.45, sustain => 0.3,
    release => 0.14, unison => 2, detune => 1.5, unison_k => 8, unison_sync => 1,
    noise => 0.05, noise_center => 1800, noise_q => 0.8, noise_decay => 45, level => 0.9);
# The first pass's piano, which the electric grand, the harpsichord and the
# clavinet are made from.
my %KEYBOARD = (slope => 0.9, cutoff => 2600, track => 0.6, bright => 1.6, pluck => 0.12, stretch => 0.0004,
    decay => 0.45, decay_k => 0.35, decay_key => 0.9, attack => 0.002, sustain => 1, release => 0.14,
    unison => 2, detune => 1.2, unison_k => 10,
    noise => 0.05, noise_center => 1800, noise_q => 0.8, noise_decay => 45, level => 0.9);
# The tine piano, after a recorded one (FluidR3): the fundamental sustains
# (some 2 dB a second), the 2nd and 3rd harmonics strong, the tine's clang short.
my %EPIANO = (partials => [ [1, 1, 1], [2, 0.6, 2], [3, 0.42, 2.8], [4, 0.07, 4], [5, 0.14, 5], [7.06, 0.06, 20] ],
    decay => 0.25, attack => 0.002, release => 0.18, bright => 1.2, tremolo => 0.15, trem_rate => 4.5, level => 0.9);
my %MALLET = (decay => 3.0, decay_key => 0.6, attack => 0.0015, release => 0.4, bright => 0.8);
my %ORGAN = (partials => [ [0.5, 0.6, 1], [1, 1, 1], [1.5, 0.45, 1], [2, 0.7, 1], [3, 0.4, 1], [4, 0.45, 1],
        [5, 0.15, 1], [6, 0.2, 1], [8, 0.25, 1] ],
    attack => 0.008, release => 0.025, vibrato => 6, vib_rate => 6.7, vib_delay => 0, velocity => 0.5,
    noise => 0.04, noise_center => 4000, noise_decay => 80, level => 0.6);
my %GUITAR = (slope => 1.0, cutoff => 3500, bright => 1.2, pluck => 0.14, stretch => 0.00003,
    decay => 0.9, decay_k => 0.55, decay_key => 0.6, attack => 0.002, release => 0.12,
    noise => 0.04, noise_center => 2500, noise_decay => 80, level => 0.9);
my %BASS = (slope => 1.2, cutoff => 1200, track => 0.3, bright => 1.2, pluck => 0.2,
    decay => 0.7, decay_k => 0.5, attack => 0.004, release => 0.08, max => 40, level => 1.1);
my %STRINGS = (slope => 1.0, cutoff => 3200, track => 0.4, bright => 0.8,
    formants => [ [280, 0.8, 0.6], [1100, 0.5, 0.7], [2600, 0.6, 0.5] ],
    attack => 0.09, fall => 1.5, sustain => 0.9, release => 0.06, vibrato => 12, vib_rate => 5.6, vib_delay => 0.25,
    noise => 0.015, noise_ratio => 3, noise_q => 2, noise_decay => 0, noise_sustain => 1, level => 0.8);
# The solo strings each have their body's resonances (measured against
# FluidR3 across their range, bin/peta-analyze --response): the harmonics
# below its lowest mode weak (the violin's G string's fundamental), peaks
# and dips fixed in Hz, the fall above them.
my %ENSEMBLE = (%STRINGS, attack => 0.25, release => 0.15, unison => 3, detune => 14, unison_k => 16, vibrato => 6,
    level => 0.7);
# The voices, after recorded ones (FluidR3): the vowel's first formant
# strongest, the second weaker, the singer's formant near 3 kHz; the
# fundamental of the low notes weak; the breath low-passed.
my %CHOIR = (slope => 1.3, cutoff => 3000, track => 0.2, bright => 0.4,
    formants => [ [130, -0.8, 0.5], [650, 4, 0.4], [1100, 1, 0.3], [2900, 1.5, 0.3] ],
    attack => 0.2, release => 0.2, vibrato => 10, vib_rate => 5, vib_delay => 0.3,
    unison => 3, detune => 10, unison_k => 24, noise => 0.02, noise_center => 2500, noise_mode => 'low', noise_decay => 0,
    noise_sustain => 1,
    level => 0.6);
my %BRASS = (slope => 0.75, cutoff => 1500, track => 0.5, bright => 2.4, attack => 0.035, attack_k => 0.006,
    fall => 0.6, sustain => 0.85, release => 0.035, vibrato => 6, vib_delay => 0.4,
    noise => 0.02, noise_center => 1500, noise_decay => 25, level => 0.75);
# The reeds (saxophones, double reeds, clarinet), after recorded ones
# (FluidR3, measured across their ranges with bin/peta-analyze --response):
# a source of harmonics 1/k through the bore and bell, its resonances fixed
# in Hz (the formants) and a steep fall above them; the breath low-passed.
my %REED = (slope => 1.0, cutoff => 3000, rolloff => 2, track => 0, bright => 1.0, attack => 0.03, release => 0.03,
    vibrato => 10, vib_rate => 5.2, vib_delay => 0.3,
    noise => 0.02, noise_ratio => 4, noise_mode => 'low', noise_decay => 0, noise_sustain => 1, level => 0.75);
# The free reeds (reed organ, accordion, harmonica), after recorded ones
# (FluidR3): the harmonics nearly level up to the 6th or 7th, falling
# steeply above, at every key (the low-pass follows it); steady, no vibrato.
my %FREE_REED = (slope => 0.3, cutoff => 2000, track => 1, rolloff => 1, bright => 0.5, attack => 0.03, release => 0.035,
    noise => 0.015, noise_ratio => 4, noise_q => 1.5, noise_decay => 0, noise_sustain => 1, level => 0.6);
# The flutes, after recorded ones (FluidR3): the 2nd harmonic near the
# fundamental, falling from some 1.5 kHz at middle C; a little breath, in a
# narrow band (a state-variable band falls only 6 dB an octave: wide or
# loud, it hisses up to the top).
my %PIPE = (slope => 1.0, cutoff => 1500, bright => 1.0, attack => 0.06, release => 0.04,
    vibrato => 8, vib_rate => 5, vib_delay => 0.35,
    noise => 0.03, noise_ratio => 2, noise_q => 2, noise_decay => 8, noise_sustain => 0.4, level => 0.8);
my %LEAD = (slope => 1.0, cutoff => 7000, track => 0.3, bright => 1.0, attack => 0.004, release => 0.032,
    vibrato => 8, vib_rate => 5.5, vib_delay => 0.4, level => 0.55);
my %PAD = (slope => 1.0, cutoff => 1400, track => 0.3, bright => 0.5, attack => 0.5, fall => 2, sustain => 0.9,
    release => 0.8, unison => 3, detune => 16, unison_k => 24, level => 0.55);
my %BELL = (decay => 0.7, decay_key => 0.4, attack => 0.001, release => 1.2, bright => 0.6);

my @GM = (
    # Piano
    # 0 Acoustic Grand
    { %PIANO },
    # 1 Bright Acoustic
    { %PIANO, cutoff => 5500, slope => 0.85 },
    # 2 Electric Grand
    { %KEYBOARD, cutoff => 3200, decay => 0.6, unison => 2, detune => 4 },
    # 3 Honky-tonk (out of tune, not wah-wah)
    { %PIANO, unison => 3, detune => 7, unison_sync => 0, cutoff => 3200 },
    # 4 Electric Piano 1 (tines)
    { %EPIANO },
    # 5 Electric Piano 2 (FM-ish)
    { %EPIANO, partials => [ [1, 1, 1], [2, 0.6, 1.5], [3, 0.45, 2], [4, 0.35, 2.5], [5, 0.25, 3], [6, 0.18, 3.5],
        [7, 0.1, 4], [8, 0.08, 4.5] ], decay => 0.3, tremolo => 0 },
    # 6 Harpsichord: the quill's bright pluck
    { %KEYBOARD, slope => 0.35, pluck => 0.08, cutoff => 9000, track => 0, bright => 0.6, stretch => 0.00005, unison => 2,
        detune => 3, decay => 0.8, decay_k => 0.12, level => 0.6 },
    # 7 Clavinet
    { %KEYBOARD, slope => 0.55, even => 0.5, cutoff => 4000, pluck => 0.1, unison => 1, decay => 1.2, level => 0.7 },

    # Chromatic percussion
    # 8 Celesta
    { %BELL, partials => [ [1, 1, 1], [3, 0.4, 2], [4.06, 0.2, 3], [6.98, 0.1, 4] ], decay => 0.9 },
    # 9 Glockenspiel
    { %BELL, partials => [ [1, 1, 1], [2.71, 0.35, 2.5], [5.15, 0.15, 4], [8.43, 0.06, 6] ],
        decay => 1.2, fall => 0.12, sustain => 0.15, bright => 0.4, transpose => 12 },
    # 10 Music Box
    { %BELL, partials => [ [1, 1, 1], [4.08, 0.3, 2], [10.2, 0.08, 3] ], decay => 1.6, release => 0.5 },
    # 11 Vibraphone
    { %MALLET, partials => [ [1, 1, 1], [4, 0.3, 1.8], [10.1, 0.08, 3] ], decay => 0.55, tremolo => 0.3,
        trem_rate => 5.5, release => 0.6 },
    # 12 Marimba
    { %MALLET, partials => [ [1, 1, 1], [3.99, 0.35, 2.5], [9.9, 0.1, 5] ], decay => 2.8 },
    # 13 Xylophone
    { %MALLET, partials => [ [1, 1, 1], [3, 0.4, 2], [6.0, 0.15, 3] ], decay => 4, transpose => 12 },
    # 14 Tubular Bells
    { %BELL, partials => [ [0.5, 0.2, 0.6], [1, 1, 1], [2.76, 0.6, 1.4], [5.4, 0.4, 2], [8.93, 0.25, 2.5],
        [13.34, 0.1, 3] ], decay => 0.4, noise => 0.03 },
    # 15 Dulcimer: hammered, its courses ringing on
    { %GUITAR, slope => 0.45, pluck => 0.1, cutoff => 7000, decay => 0.35, decay_k => 0.3, fall => 0.2, sustain => 0.12,
        unison => 3, detune => 4, unison_k => 16, release => 0.5 },

    # Organ
    # 16 Drawbar
    { %ORGAN },
    # 17 Percussive: the third falls
    { %ORGAN, noise => 0.08, decay => 5, partials => [ [1, 1, 0], [2, 0.6, 0], [3, 1.6, 1], [4, 0.3, 0], [6, 0.2, 0] ] },
    # 18 Rock
    { %ORGAN, partials => [ [0.5, 0.5, 1], [1, 1, 1], [1.5, 0.6, 1], [2, 0.8, 1], [3, 0.6, 1], [4, 0.6, 1],
        [5, 0.4, 1], [6, 0.4, 1], [8, 0.5, 1] ], vibrato => 14 },
    # 19 Church: a principal chorus, its pipes in tune
    { partials => [ [1, 1, 0], [2, 0.75, 0], [3, 0.45, 0], [4, 0.6, 0], [5, 0.15, 0], [6, 0.4, 0], [8, 0.5, 0],
        [10, 0.2, 0], [12, 0.35, 0], [16, 0.3, 0], [20, 0.12, 0], [24, 0.15, 0] ],
        attack => 0.07, release => 0.2, level => 0.55,
        noise => 0.05, noise_ratio => 2, noise_q => 2, noise_decay => 12, noise_sustain => 0.1 },
    # 20 Reed Organ
    { %FREE_REED, slope => 0.5, cutoff => 2400, attack => 0.05, release => 0.04, level => 0.6 },
    # 21 Accordion: musette, a reed in tune, one sharp, one flat
    { %FREE_REED, cutoff => 3000, attack_k => 0.008, unison => 3, detune => 36, unison_k => 12 },
    # 22 Harmonica
    { %FREE_REED, slope => 0.6, cutoff => 3200, vibrato => 12, vib_rate => 5.2, vib_delay => 0.3,
        noise => 0.03 },
    # 23 Tango Accordion: dry, reeds in octaves (the bandoneon)
    { %FREE_REED, slope => 0.85, even => 1.5, cutoff => 4000 },

    # Guitar
    # 24 Nylon
    { %GUITAR, slope => 1.3, cutoff => 2400 },
    # 25 Steel
    { %GUITAR },
    # 26 Jazz
    { %GUITAR, cutoff => 3000, decay => 0.5, decay_k => 0.4, pluck => 0.2, level => 0.85 },
    # 27 Clean
    { %GUITAR, cutoff => 4500, decay => 0.5, decay_k => 0.35, pluck => 0.1 },
    # 28 Muted
    { %GUITAR, cutoff => 2500, decay => 6, decay_k => 0.2, release => 0.04 },
    # 29 Overdriven
    { %GUITAR, slope => 0.6, cutoff => 2800, track => 0, decay => 0.15, decay_k => 0.1, sustain => 1,
        unison => 2, detune => 8, formants => [ [1200, 1.5, 0.8] ], level => 0.6 },
    # 30 Distortion
    { %GUITAR, slope => 0.5, cutoff => 3000, track => 0, decay => 0.1, decay_k => 0.08, sustain => 1,
        unison => 3, detune => 14, formants => [ [900, 2, 0.8], [2400, 1.5, 0.5] ], level => 0.55 },
    # 31 Harmonics
    { %BELL, partials => [ [1, 1, 1], [2, 0.6, 1.2], [3, 0.4, 1.4], [4, 0.3, 1.6] ], decay => 0.8,
        transpose => 12, level => 0.6 },

    # Bass
    # 32 Acoustic
    { %BASS, slope => 1.5, decay => 1.0, decay_k => 0.4, pluck => 0.15 },
    # 33 Finger
    { %BASS },
    # 34 Pick
    { %BASS, slope => 1.0, cutoff => 1800, pluck => 0.1, decay_k => 0.6 },
    # 35 Fretless
    { %BASS, slope => 1.6, cutoff => 900, vibrato => 6, vib_delay => 0.4 },
    # 36 Slap 1
    { %BASS, slope => 0.8, cutoff => 2500, pluck => 0.06, decay => 1.2, decay_k => 0.8 },
    # 37 Slap 2
    { %BASS, slope => 0.8, cutoff => 2800, pluck => 0.06, decay => 1.2, decay_k => 0.8 },
    # 38 Synth Bass 1
    { %BASS, slope => 1.0, cutoff => 900, pluck => 0, decay => 0.3, decay_k => 1.5, sustain => 1 },
    # 39 Synth Bass 2
    { %BASS, slope => 1.0, cutoff => 1300, pluck => 0, decay => 0.2, decay_k => 0.8, unison => 2, detune => 10 },

    # Strings
    # 40 Violin
    { %STRINGS, cutoff => 4000, track => 0, vib_rate => 6, attack => 0.08,
        formants => [ [210, -0.93, 0.6], [450, 0.6, 0.5], [1600, -0.3, 0.6] ] },
    # 41 Viola
    { %STRINGS, cutoff => 3800, track => 0, vib_rate => 5.6, attack => 0.09,
        formants => [ [130, -0.95, 0.45], [450, 0.25, 0.6], [900, -0.35, 0.3] ] },
    # 42 Cello
    { %STRINGS, cutoff => 2800, track => 0, vib_rate => 5.3, attack => 0.1,
        formants => [ [62, -0.8, 0.25], [80, -0.95, 0.4], [225, 0.35, 0.4], [400, -0.35, 0.25], [630, 0.6, 0.2],
            [1100, -0.55, 0.35] ] },
    # 43 Contrabass
    { %STRINGS, cutoff => 1600, track => 0, vib_rate => 4.8, attack => 0.13,
        formants => [ [40, -0.95, 0.3], [52, -0.97, 0.3], [150, -0.35, 0.4], [250, -0.8, 0.25], [700, -0.75, 1] ] },
    # 44 Tremolo
    { %ENSEMBLE, tremolo => 0.5, trem_rate => 11 },
    # 45 Pizzicato
    { %GUITAR, slope => 1.2, cutoff => 2000, decay => 5, pluck => 0.25, release => 0.1 },
    # 46 Harp
    { %GUITAR, slope => 1.4, cutoff => 3000, decay => 0.5, decay_k => 0.35, pluck => 0.18, release => 0.5 },
    # 47 Timpani
    { sweep => 0.15, sweep_time => 0.04, partials => [ [1, 1, 1], [1.5, 0.3, 2], [2.0, 0.25, 2], [2.8, 0.12, 3] ],
        decay => 1.0, attack => 0.002, release => 0.3, noise => 0.2, noise_center => 300, noise_decay => 15 },

    # Ensemble
    # 48 Strings
    { %ENSEMBLE },
    # 49 Slow Strings
    { %ENSEMBLE, attack => 0.5, cutoff => 2400 },
    # 50 Synth Strings 1
    { %PAD, slope => 0.9, cutoff => 2600, attack => 0.15, release => 0.4 },
    # 51 Synth Strings 2
    { %PAD, slope => 0.9, cutoff => 2000, attack => 0.3 },
    # 52 Choir Aahs
    { %CHOIR },
    # 53 Voice Oohs: near the fundamental alone
    { %CHOIR, slope => 2, formants => [ [300, 3, 0.35], [870, 0.8, 0.3], [2240, 0.3, 0.25] ], unison => 1,
        release => 0.1 },
    # 54 Synth Voice
    { %CHOIR, slope => 1.2, formants => [ [500, 2, 0.4], [1500, 1, 0.4] ], cutoff => 4000, attack => 0.08 },
    # 55 Orchestra Hit: a stab, the octave under it and the fifth
    { %ENSEMBLE, transpose => -12, even => 1.6, attack => 0.01, fall => 0.25, sustain => 0, release => 0.3 },

    # Brass
    # (Measured against FluidR3: the bell radiates the low harmonics weakly, a
    # dip fixed in Hz under each instrument's lowest notes.)
    # 56 Trumpet
    { %BRASS, cutoff => 2200, formants => [ [250, -0.7, 0.7] ] },
    # 57 Trombone
    { %BRASS, cutoff => 1400, formants => [ [110, -0.8, 0.5], [500, 1, 0.6] ] },
    # 58 Tuba: its first harmonics
    { %BRASS, cutoff => 400, track => 0, rolloff => 1 },
    # 59 Muted Trumpet: the harmon mute, bright and thin
    { %BRASS, slope => 0.75, cutoff => 6000, track => 0, bright => 1.2,
        formants => [ [350, -0.85, 0.8], [2500, 2, 0.8] ] },
    # 60 French Horn
    { %BRASS, slope => 1.3, cutoff => 1300, attack => 0.1, release => 0.05, formants => [ [110, -0.8, 0.5] ] },
    # 61 Brass Section: forte, bright
    { %BRASS, unison => 3, detune => 12, cutoff => 3500, attack => 0.08, release => 0.05, level => 0.6,
        formants => [ [150, -0.8, 0.6] ] },
    # 62 Synth Brass 1
    { %BRASS, unison => 2, detune => 10, slope => 0.9, attack => 0.01, attack_k => 0, vibrato => 0 },
    # 63 Synth Brass 2
    { %BRASS, unison => 2, detune => 14, slope => 1.0, cutoff => 1100, attack => 0.015, attack_k => 0, vibrato => 0 },

    # Reed
    # 64 Soprano Sax: rising to 2.5 kHz
    { %REED, cutoff => 3400, formants => [ [250, -0.65, 0.8] ] },
    # 65 Alto Sax
    { %REED, cutoff => 3200, formants => [ [130, -0.95, 0.4], [700, 1.5, 0.4], [1600, -0.6, 0.2], [2100, 1, 0.25] ] },
    # 66 Tenor Sax
    { %REED, cutoff => 3000, formants => [ [110, -0.9, 0.5], [630, 1.2, 0.25], [900, -0.3, 0.3], [1700, 1.2, 0.5] ] },
    # 67 Baritone Sax
    { %REED, cutoff => 3800, formants => [ [75, -0.95, 0.5], [1700, 0.8, 0.6] ] },
    # 68 Oboe: a peak at 1.25 kHz over a weak fundamental
    { %REED, attack => 0.08, formants => [ [1250, 4, 0.35], [2800, 1, 0.4] ] },
    # 69 English Horn: a narrow peak at 1 kHz
    { %REED, cutoff => 2500, rolloff => 0, attack => 0.08, formants => [ [200, -0.6, 0.6], [1000, 4, 0.2] ] },
    # 70 Bassoon: its formant at 480 Hz
    { %REED, cutoff => 1600, rolloff => 1, vibrato => 0,
        formants => [ [65, -0.9, 0.3], [150, -0.7, 0.7], [480, 6, 0.3], [1200, 0.6, 0.5] ] },
    # 71 Clarinet: odd harmonics, strongest at 2 kHz, none past 5
    { %REED, even => 0.02, cutoff => 4000, rolloff => 3, vibrato => 0, release => 0.02,
        formants => [ [2000, 2.5, 0.6] ] },

    # Pipe
    # 72 Piccolo
    { %PIPE, cutoff => 2000, transpose => 12 },
    # 73 Flute
    { %PIPE },
    # 74 Recorder: purer up the keyboard
    { %PIPE, slope => 1.4, even => 0.3, cutoff => 1800, rolloff => 1, track => 0 },
    # 75 Pan Flute
    { %PIPE, slope => 1.8, attack => 0.1, noise => 0.03, noise_ratio => 4, noise_mode => 'low', noise_sustain => 0.8 },
    # 76 Blown Bottle: the fundamental, breath under 1.5 kHz
    { %PIPE, slope => 4, even => 0.15, noise => 0.04, noise_ratio => 0, noise_center => 1500, noise_mode => 'low',
        noise_sustain => 1 },
    # 77 Shakuhachi
    { %PIPE, slope => 2.6, cutoff => 2500, noise => 0.1, noise_ratio => 4, noise_mode => 'low', attack => 0.08 },
    # 78 Whistle
    { slope => 9, attack => 0.05, release => 0.06, vibrato => 15, vib_rate => 6, vib_delay => 0.1, level => 0.8 },
    # 79 Ocarina: nearly odd harmonics only
    { %PIPE, slope => 2.0, even => 0.02, cutoff => 2000, noise => 0.02 },

    # Synth lead
    # 80 Square
    { %LEAD, even => 0.05 },
    # 81 Sawtooth
    { %LEAD },
    # 82 Calliope: a flute's, breathy, wavering
    { %LEAD, slope => 2.4, noise => 0.03, noise_ratio => 4, noise_mode => 'low', noise_decay => 0, noise_sustain => 1,
        vibrato => 20, vib_delay => 0.2 },
    # 83 Chiff
    { %LEAD, slope => 1.8, noise => 0.4, noise_decay => 40 },
    # 84 Charang
    { %GUITAR, %LEAD, decay => 0.2, decay_k => 0.2, cutoff => 6000, pluck => 0.1, unison => 2, detune => 8 },
    # 85 Voice
    { %CHOIR, slope => 1.4, formants => [ [400, 2, 0.4], [1200, 0.8, 0.4] ], unison => 1, attack => 0.15, release => 0.13,
        vibrato => 20, vib_delay => 0.15 },
    # 86 Fifths
    { %LEAD, partials => [ map { ([ $_, 1 / $_, 1 ], [ 1.5 * $_, 0.6 / $_, 1 ]) } 1 .. 16 ], level => 0.25 },
    # 87 Bass + Lead
    { %LEAD, unison => 2, detune => 8, cutoff => 5000, release => 0.01, level => 0.6 },

    # Synth pad
    # 88 New Age: struck, then the pad
    { %PAD, slope => 1.2, cutoff => 2200, attack => 0.02, fall => 1.2, sustain => 0.5, decay_k => 0.6, decay => 0.05 },
    # 89 Warm
    { %PAD },
    # 90 Polysynth
    { %PAD, cutoff => 3000, attack => 0.2, decay_k => 0.4, decay => 0.15, sustain => 0.9 },
    # 91 Choir
    { %CHOIR, slope => 1.2, attack => 0.1, release => 1.0 },
    # 92 Bowed
    { %PAD, slope => 1.5, cutoff => 4000, attack => 0.15, tremolo => 0.2, trem_rate => 3 },
    # 93 Metallic
    { %PAD, slope => 0.9, even => 0.4, cutoff => 2600, attack => 0.2 },
    # 94 Halo
    { %PAD, cutoff => 3500, attack => 0.4, formants => [ [600, 3, 0.4], [1200, 2, 0.4] ] },
    # 95 Sweep: a resonant low-pass opening and closing
    { %PAD, cutoff => 6000, attack => 0.8, filter => 'lp24', filter_cutoff => 400, filter_q => 2, filter_env => 4,
        env2_attack => 2, env2_decay => 3, env2_sustain => 0.3, env2_release => 1 },

    # Synth effects
    # 96 Rain
    { %BELL, partials => [ [1, 1, 1], [2.4, 0.4, 2], [5.3, 0.2, 3] ], decay => 0.6, noise => 0.04,
        noise_center => 6000, noise_q => 2, noise_decay => 5 },
    # 97 Soundtrack
    { %PAD, attack => 0.4, cutoff => 2800, unison => 3, detune => 22 },
    # 98 Crystal
    { %BELL, partials => [ [1, 1, 1], [2.76, 0.5, 1.3], [5.4, 0.35, 1.8], [8.9, 0.2, 2.2], [12.6, 0.15, 2.6] ],
        decay => 1.5 },
    # 99 Atmosphere
    { %PAD, %BELL, partials => undef, slope => 1.2, decay => 0.4, decay_k => 0.2, release => 1.5 },
    # 100 Brightness
    { %PAD, slope => 0.8, cutoff => 5000, attack => 0.1 },
    # 101 Goblins
    { %PAD, attack => 1.0, vibrato => 30, vib_rate => 1.5, vib_delay => 0 },
    # 102 Echoes: repeating
    { %BELL, decay => 0.3, partials => [ map { [ $_, 1 / $_, 1 + $_ / 4 ] } 1 .. 8 ], attack => 0.05, release => 1.5,
        tremolo => 0.4, trem_rate => 5 },
    # 103 Sci-Fi: a resonance closing
    { %PAD, slope => 0.9, cutoff => 6000, vibrato => 40, vib_rate => 0.5, vib_delay => 0, filter => 'lp24',
        filter_cutoff => 3000, filter_q => 6, filter_env => -3, env2_attack => 0.01, env2_decay => 1.5, env2_sustain => 0.3 },

    # Ethnic
    # 104 Sitar
    { %GUITAR, slope => 0.6, cutoff => 5000, pluck => 0.05, decay => 0.6, decay_k => 0.25, release => 1,
        formants => [ [2500, 3, 0.6] ], sweep => 0.01, sweep_time => 0.2 },
    # 105 Banjo: its head bright
    { %GUITAR, slope => 0.6, cutoff => 9000, decay => 2.5, decay_k => 0.2, pluck => 0.08, release => 1,
        formants => [ [1500, 2, 0.6], [3500, 1.5, 0.6] ] },
    # 106 Shamisen: thin, its fundamental weak
    { %GUITAR, slope => 0.8, cutoff => 4000, track => 0, decay => 1.2, pluck => 0.05, release => 0.2,
        formants => [ [250, -0.95, 0.6], [800, 2, 0.6] ] },
    # 107 Koto: plucked near the bridge
    { %GUITAR, slope => 0.7, cutoff => 7000, decay => 2, decay_k => 0.3, pluck => 0.1, release => 1 },
    # 108 Kalimba: the tine, its click
    { %MALLET, partials => [ [1, 1, 1], [2, 0.15, 1.2], [5.4, 0.35, 1.3], [8.9, 0.15, 1.5], [13.9, 0.1, 1.8] ], decay => 4,
        noise => 0.12, noise_center => 3000, noise_decay => 60 },
    # 109 Bagpipe
    { %REED, cutoff => 5000, rolloff => 0, attack => 0.1, vibrato => 0, release => 0.05, level => 0.6,
        formants => [ [1800, 2.5, 0.8] ] },
    # 110 Fiddle
    { %STRINGS, cutoff => 3600, vibrato => 18 },
    # 111 Shanai
    { %REED, rolloff => 1, formants => [ [250, -0.7, 0.6], [1400, 4, 0.55] ] },

    # Percussive
    # 112 Tinkle Bell
    { %BELL, partials => [ [1, 1, 1], [2.9, 0.5, 2], [5.6, 0.3, 3], [9.1, 0.2, 4] ], decay => 2.5,
        transpose => 12 },
    # 113 Agogo: a bell an octave up, struck
    { %BELL, partials => [ [1, 1, 1], [2.13, 0.3, 1.5], [4.3, 0.6, 2], [6.4, 0.3, 2.5] ], decay => 8, transpose => 12,
        noise => 0.2, noise_center => 5000, noise_decay => 50 },
    # 114 Steel Drums: tuned in the octave and the twelfth
    { %MALLET, partials => [ [1, 0.4, 1], [2, 1, 1.2], [3, 0.8, 1.5], [4, 0.3, 2], [5.4, 0.15, 2.5] ],
        decay => 3, noise => 0.08, noise_center => 2500, noise_decay => 60 },
    # 115 Woodblock
    { %MALLET, partials => [ [1, 1, 1], [2.6, 0.4, 2], [4.7, 0.2, 3] ], decay => 25, noise => 0.3,
        noise_center => 2500, noise_q => 0.7, noise_decay => 60, transpose => 24 },
    # 116 Taiko
    { sweep => 0.4, sweep_time => 0.03, partials => [ [1, 1, 1], [1.6, 0.4, 2] ], decay => 4, attack => 0.002,
        noise => 0.3, noise_center => 300, noise_mode => 'low', noise_decay => 20 },
    # 117 Melodic Tom: the head's modes, its strike
    { sweep => 0.3, sweep_time => 0.06, partials => [ [1, 1, 1], [1.6, 0.4, 2], [2.3, 0.2, 2.5], [2.9, 0.1, 3] ], decay => 5,
        attack => 0.002, noise => 0.5, noise_center => 1500, noise_q => 0.7, noise_decay => 15 },
    # 118 Synth Drum
    { sweep => 1.0, sweep_time => 0.12, partials => [ [1, 1, 1] ], decay => 6, attack => 0.002,
        noise => 0.35, noise_center => 2500, noise_q => 0.5, noise_decay => 25 },
    # 119 Reverse Cymbal
    { partials => [], noise => 0.8, noise_center => 5000, noise_q => 0.7, noise_attack => 1.2, noise_decay => 0,
        noise_sustain => 1, attack => 1.2, release => 0.05 },

    # Sound effects
    # 120 Guitar Fret Noise
    { partials => [], noise => 1.2, noise_center => 2000, noise_q => 4, noise_decay => 20, attack => 0.01 },
    # 121 Breath Noise: a breath, let out
    { partials => [], noise => 0.6, noise_center => 2500, noise_q => 2, noise_attack => 0.1, noise_decay => 3,
        noise_sustain => 0, release => 0.3 },
    # 122 Seashore
    { partials => [], noise => 0.3, noise_center => 2500, noise_mode => 'low', noise_attack => 0.5, noise_decay => 0,
        noise_sustain => 1, attack => 0.5, release => 2, tremolo => 0.6, trem_rate => 0.15 },
    # 123 Bird Tweet: chirps, high up
    { slope => 3, vibrato => 300, vib_rate => 14, vib_delay => 0, attack => 0.01, release => 0.05, decay => 1.5,
        tremolo => 0.8, trem_rate => 14, transpose => 36, level => 1.5 },
    # 124 Telephone Ring: a bell, struck and struck
    { %BELL, partials => [ [1, 1, 0], [2.76, 0.6, 0], [5.4, 0.5, 0], [8.9, 0.4, 0] ], release => 0.1,
        tremolo => 1, trem_rate => 18, transpose => 24, level => 1.2 },
    # 125 Helicopter: coming
    { partials => [], noise => 0.28, noise_center => 1200, noise_mode => 'low', noise_attack => 0.8, noise_decay => 0,
        noise_sustain => 1, attack => 0.8, tremolo => 0.9, trem_rate => 18, release => 0.5 },
    # 126 Applause: a crowd's claps at random moments, hands of two colours
    { partials => [], noise => 0.6, noise_center => 1200, noise_q => 0.8, noise_poles => 4, noise_grains => 300,
        noise_grain_decay => 90, noise_attack => 0.4, noise_decay => 0, noise_sustain => 1,
        noise2 => 0.4, noise2_center => 2600, noise2_q => 1.0, noise2_poles => 4, noise2_grains => 200,
        noise2_grain_decay => 120, noise2_attack => 0.4, noise2_decay => 0, noise2_sustain => 1, release => 1, level => 0.37 },
    # 127 Gunshot
    { partials => [], noise => 1, noise_center => 800, noise_mode => 'low', noise_decay => 12, sweep => 0,
        release => 0.3 },
);
die "the GM table has " . @GM . " programs\n" unless @GM == 128;

# The variations of the programs, by GS's bank (bank select MSB on a
# melodic channel) and program: those FluidR3 has, each a name and its
# patch. Each is its program, changed as FluidR3's variation differs from
# FluidR3's program (devbin/audit-fluid --variations, against the program
# audited): its octave bands, envelope and vibrato, and its level balanced
# as the programs' is. Where FluidR3's measures as its program (the
# detuned ones), what the name says, mildly: two copies a few cents apart,
# beginning in phase.
my %VARIATION = (
    8 => {
        4   => [ 'Detuned EP 1'        => { %{ $GM[4] }, unison => 2, detune => 4, unison_sync => 1, level => 0.36 } ],
        5   => [ 'Detuned EP 2'        => { %{ $GM[5] }, unison => 2, detune => 4, unison_sync => 1, level => 0.32 } ],
        6   => [ 'Coupled Harpsichord' => { %{ $GM[6] }, even => 1.3, decay => 0.9, unison_sync => 1, level => 0.63 } ],
        14  => [ 'Church Bell'         => { %{ $GM[14] }, partials => [ [0.5, 0.35, 0.6], [1, 1, 1], [2.76, 0.5, 1.4],
            [5.4, 0.3, 2], [8.93, 0.18, 2.5], [13.34, 0.07, 3] ], decay => 1.0, level => 1.41 } ],
        16  => [ 'Detuned Organ 1'     => { %{ $GM[16] }, unison => 2, detune => 4, unison_sync => 1, level => 0.21 } ],
        17  => [ 'Detuned Organ 2'     => { %{ $GM[17] }, unison => 2, detune => 4, unison_sync => 1, level => 0.52 } ],
        19  => [ 'Church Organ 2'      => { %{ $GM[19] }, partials => [ [0.5, 0.25, 0], [1, 1, 0], [2, 0.75, 0], [3, 0.45, 0], [4, 0.55, 0],
            [5, 0.13, 0], [6, 0.32, 0], [8, 0.38, 0], [10, 0.14, 0], [12, 0.24, 0], [16, 0.2, 0], [20, 0.07, 0], [24, 0.08, 0] ],
            attack => 0.08, level => 1.07 } ],
        21  => [ 'Italian Accordion'   => { %{ $GM[21] }, detune => 44, level => 0.81 } ],
        24  => [ 'Ukulele'             => { %{ $GM[24] }, cutoff => 1900, decay => 1.0, release => 0.08, level => 1.04 } ],
        25  => [ '12 String Guitar'    => { %{ $GM[25] }, unison => 2, detune => 4, unison_sync => 1, even => 1.5, cutoff => 4500,
            level => 0.65 } ],
        26  => [ 'Hawaiian Guitar'     => { %{ $GM[26] }, cutoff => 1500, vibrato => 6, vib_rate => 5, vib_delay => 0.15,
            level => 2.01 } ],
        28  => [ 'Funk Guitar'         => { %{ $GM[27] }, cutoff => 5000, slope => 0.8, release => 0.03, level => 0.65 } ],
        30  => [ 'Feedback Guitar'     => { %{ $GM[30] }, decay => 0, level => 1.1 } ],
        31  => [ 'Guitar Feedback'     => { %LEAD, partials => [ [1, 1, 1], [2, 0.5, 1], [3, 0.35, 1], [4, 0.25, 1], [5, 0.15, 1],
            [6, 0.1, 1] ], attack => 1.2, release => 0.02, vibrato => 0, level => 0.69 } ],
        38  => [ 'Synth Bass 3'        => { %{ $GM[38] }, cutoff => 1300, decay => 0.15, release => 0.05, level => 1.08 } ],
        39  => [ 'Synth Bass 4'        => { %{ $GM[39] }, cutoff => 2500, decay => 1.0, release => 0.15, unison => 1, level => 1.13 } ],
        40  => [ 'Slow Violin'         => { %{ $GM[40] }, attack => 0.5, level => 0.75 } ],
        48  => [ 'Orchestral Pad'      => { %{ $GM[48] }, cutoff => 12000, slope => 0.5, attack => 0.12, fall => 3,
            formants => [ @{ $GM[48]{formants} }, [ 6000, 2, 1 ] ], level => 0.47 } ],
        50  => [ 'Synth Strings 3'     => { %{ $GM[50] }, cutoff => 4500, slope => 0.7, attack => 0.35, formants => [ [100, -0.9, 1] ],
            level => 0.8 } ],
        61  => [ 'Brass 2'             => { %{ $GM[61] }, cutoff => 4000, attack => 0.1, vibrato => 24, level => 0.47 } ],
        62  => [ 'Synth Brass 3'       => { %{ $GM[62] }, cutoff => 7000, slope => 0.7, attack => 0.005, fall => 1.5, level => 0.68 } ],
        63  => [ 'Synth Brass 4'       => { %{ $GM[63] }, detune => 20, unison_sync => 1, level => 0.76 } ],
        80  => [ 'Sine Wave'           => { %{ $GM[80] }, partials => [ [1, 1, 1] ], release => 0.02, vibrato => 0, level => 1.78 } ],
        107 => [ 'Taisho Koto'         => { %{ $GM[107] }, unison => 2, detune => 3, unison_sync => 1, cutoff => 10000, decay => 1.5,
            level => 0.56 } ],
        115 => [ 'Castanets'           => { %{ $GM[115] }, transpose => 31, decay => 60, noise => 0.5, noise_center => 5000,
            noise_decay => 120, level => 0.82 } ],
        116 => [ 'Concert Bass Drum'   => { %{ $GM[116] }, decay => 3.5, noise_center => 2500, noise_mode => 'band', noise_q => 0.5,
            level => 1.01 } ],
        117 => [ 'Melo Tom 2'          => { %{ $GM[117] }, noise => 0.5, noise_center => 2500, level => 1.17 } ],
        118 => [ '808 Tom'             => { %{ $GM[118] }, sweep => 0.3, noise => 0.02, decay => 8, level => 1.75 } ],
    },
    9 => {
        125 => [ 'Burst Noise'         => { partials => [], noise => 0.5, noise_center => 3000, noise_mode => 'low', noise_attack => 0.03,
            noise_decay => 0, noise_sustain => 1, release => 0.5, level => 0.61 } ],
    },
    16 => {
        25  => [ 'Mandolin'            => { %{ $GM[25] }, unison => 2, detune => 3, unison_sync => 1, cutoff => 3000, decay => 1.2,
            release => 0.08, level => 0.59 } ],
    },
);

# GM2's variations (bank select MSB 121, the LSB the variation) that are
# GS's above: by program, LSB => GS bank.
my %GM2 = (
    (map { $_ => { 1 => 8 } } 4, 5, 6, 14, 16, 17, 19, 21, 24, 26, 28, 30, 31, 39, 40, 48, 50, 61, 62, 63, 107, 115, 116, 117, 118),
    25  => { 1 => 8, 2 => 16 },
    38  => { 2 => 8 },
    80  => { 2 => 8 },
    125 => { 9 => 9 },
);

# The drum kit (GM keys 35 .. 81), measured against FluidR3's standard kit
# (devbin/audit-fluid --drums): each drum's pitch, how long it takes to fall
# 20 and 40 dB, its spectrum in octaves over the first quarter second, and
# its level, balanced as the programs are. A drum sounds at a fixed pitch,
# rings to its end whether the key is held or not, and is a sweep, partials
# and bands of noise.
my %KICK  = (sweep => 2.2, sweep_time => 0.025,
    noise => 0.12, noise_mode => 'low', noise_center => 3500, noise_q => 0.7, noise_decay => 50);
my %SNARE = (fixed => 185, sweep => 0.2, sweep_time => 0.02, partials => [ [1, 0.8, 1], [1.62, 0.5, 1.2], [2.3, 0.2, 1.4] ],
    noise_mode => 'low', noise_q => 0.7, noise_decay => 22);
# A drumhead's modes, for the toms and the hand drums.
my @MEMBRANE = ([1, 1, 1], [1.59, 0.5, 1.4], [2.14, 0.3, 1.8], [2.65, 0.2, 2.2], [3.16, 0.12, 2.6]);
my %TOM   = (partials => \@MEMBRANE, sweep => 0.35, sweep_time => 0.05,
    noise => 0.2, noise_mode => 'low', noise_center => 2000, noise_q => 0.7, noise_decay => 30);
# Bongos, congas and timbales: hardly a sweep, a little slap high up.
my %HAND  = (%TOM, sweep => 0.05, noise => 0.08, noise_center => 1200,
    noise2 => 0.015, noise2_center => 8000, noise2_q => 0.6, noise2_decay => 60);

# A hi-hat: six metallic partials, its sizzle around 10 kHz, and the stick
# (or, the pedal's, the chick) around 600 Hz.
sub _hat ($decay, $chick, $level) {
    return (fixed => 205.3 * 8, partials => [ map { [ $_ / 205.3, 0.15, 1 ] } 205.3, 304.4, 369.6, 522.7, 540.0, 800.0 ],
        decay => $decay, noise => 0.9, noise_center => 10000, noise_q => 0.6, noise_decay => $decay,
        noise2 => $chick, noise2_center => 600, noise2_q => 0.7, noise2_decay => 1.5 * $decay, level => $level);
}

# A cymbal: nine inharmonic partials, faint; noise in a broad band where it
# is loudest, and a second band lower down, the wash.
sub _cymbal ($fixed, $amplitude, $centre, $decay, $wash, $wash_centre, $level) {
    my @ratios = (1, 1.48, 1.93, 2.41, 2.93, 3.39, 4.12, 4.95, 5.71);
    return (fixed => $fixed, partials => [ map { [ $_, $amplitude / sqrt($_), 0.7 + 0.15 * $_ ] } @ratios ],
        decay => $decay, noise => 0.8, noise_center => $centre, noise_q => 0.7, noise_decay => $decay,
        noise2 => $wash, noise2_center => $wash_centre, noise2_q => 0.7, noise2_decay => $decay, level => $level);
}

my %DRUM = (
    35 => { %KICK, fixed => 50, partials => [ [0.7, 0.4, 1], [1, 1, 1], [2.3, 0.1, 3] ], decay => 18, level => 1.34 },
    36 => { %KICK, fixed => 62, partials => [ [0.6, 0.5, 1], [1, 1, 1], [2.3, 0.1, 3] ], decay => 22, level => 1.24 },
    # side stick
    37 => { fixed => 1300, partials => [ [1, 0.35, 1], [1.7, 0.15, 1.5], [1, 0.06, 0.3] ], decay => 25,
        noise => 1.0, noise_center => 4000, noise_q => 0.5, noise_decay => 60, level => 0.56 },
    38 => { %SNARE, decay => 30, noise => 0.45, noise_center => 6000, level => 1.58 },
    # hand clap
    39 => { partials => [], noise => 1.0, noise_center => 1300, noise_q => 1.2, noise_decay => 28, level => 1.05,
        tremolo => 0.8, trem_rate => 90 },
    40 => { %SNARE, fixed => 200, decay => 28, noise => 0.5, noise_center => 5000, level => 1.04 },
    41 => { %TOM, fixed => 54,  decay => 4.2, level => 1.06 },
    43 => { %TOM, fixed => 72,  decay => 6.5, level => 1.31 },
    45 => { %TOM, fixed => 82,  decay => 4.4, level => 0.84 },
    47 => { %TOM, fixed => 98,  decay => 4.8, level => 0.88 },
    48 => { %TOM, fixed => 106, decay => 5.1, level => 0.91 },
    50 => { %TOM, fixed => 118, decay => 6.0, level => 0.77 },
    # closed, pedal and open hi-hat
    42 => { _hat(23,  0.25, 0.16) },
    44 => { _hat(33,  0.6,  0.19) },
    46 => { _hat(2.6, 0.3,  0.12) },
    # crash 1 and 2, ride 1 and 2, china, splash
    49 => { _cymbal(420, 0.1,  4500, 1.6, 0.15, 600,  0.28) },
    57 => { _cymbal(460, 0.1,  5000, 1.8, 0.15, 600,  0.26) },
    51 => { _cymbal(500, 0.08, 8000, 4,   0.1,  600,  0.28), noise => 0.35 },
    59 => { _cymbal(560, 0.08, 9000, 4,   0.25, 600,  0.26), noise => 0.35 },
    52 => { _cymbal(900, 0.1,  4500, 4,   0.4,  1500, 0.25), noise2_q => 1.0 },
    55 => { _cymbal(900, 0.1,  7000, 4.5, 0.2,  1000, 0.27) },
    # ride bell
    53 => { fixed => 3500, partials => [ [0.42, 0.4, 0.8], [0.67, 0.6, 1], [1, 1, 1], [1.5, 0.3, 1.4] ], decay => 2.3,
        noise => 0.2, noise_center => 6000, noise_q => 0.7, noise_decay => 4,
        noise2 => 0.2, noise2_center => 800, noise2_q => 0.7, noise2_decay => 4, level => 0.25 },
    # tambourine
    54 => { fixed => 6800, partials => [ [1, 0.4, 1], [1.4, 0.3, 1] ], decay => 18, tremolo => 0.5, trem_rate => 40,
        noise => 0.9, noise_center => 9000, noise_q => 0.6, noise_decay => 18, level => 0.82 },
    # cowbell
    56 => { fixed => 480, partials => [ [1, 1, 1], [1.48, 0.15, 1.2], [4.2, 0.3, 1.4], [7.5, 0.1, 1.6] ], decay => 23,
        noise => 0.08, noise_center => 5000, noise_q => 0.5, level => 0.95 },
    # vibraslap
    58 => { fixed => 2400, partials => [ [1, 0.3, 1] ], decay => 3.5, tremolo => 0.9, trem_rate => 28,
        noise => 0.8, noise_center => 4000, noise_q => 0.5, noise_decay => 3.5, level => 0.5 },
    # hi and low bongo, mute hi, open hi and low conga, high and low timbale
    60 => { %HAND, fixed => 870, decay => 38, level => 1.44 },
    61 => { %HAND, fixed => 590, decay => 29, level => 1.55 },
    62 => { %HAND, fixed => 860, decay => 50, level => 1.14 },
    63 => { %HAND, fixed => 290, decay => 15, noise => 0.06, level => 0.95 },
    64 => { %HAND, fixed => 255, decay => 18, noise => 0.06, level => 1.42 },
    65 => { %HAND, fixed => 265, decay => 11,   noise => 0.3, noise_center => 3000, level => 0.92 },
    66 => { %HAND, fixed => 200, decay => 10.5, noise => 0.3, noise_center => 3000, level => 1.04 },
    # high and low agogo
    67 => { fixed => 1500, partials => [ [1, 1, 1], [2.13, 0.3, 1.4], [4.4, 0.4, 2], [5.9, 0.3, 2.5], [9.5, 0.25, 3] ],
        decay => 13.5, noise => 0.15, noise_center => 10000, noise_q => 0.6, noise_decay => 20, level => 0.58 },
    68 => { fixed => 1000, partials => [ [1, 1, 1], [2.13, 0.2, 1.4], [4.3, 0.6, 2], [7.5, 0.4, 2.5], [12, 0.2, 3] ],
        decay => 12, noise => 0.1, noise_center => 8000, noise_q => 0.6, noise_decay => 20, level => 0.57 },
    # cabasa, maracas
    69 => { partials => [], noise => 0.8, noise_center => 12000, noise_q => 0.6, noise_attack => 0.02, noise_decay => 90,
        level => 1.72 },
    70 => { partials => [], noise => 0.8, noise_center => 10000, noise_q => 0.7, noise_attack => 0.02, noise_decay => 75,
        level => 1.16 },
    # short and long whistle: as long as FluidR3's
    71 => { fixed => 3150, partials => [ [1, 1, 1], [2, 0.25, 1] ], sweep => -0.1, sweep_time => 0.2, attack => 0.005,
        decay => 2, length => 0.15, noise => 0.2, noise_center => 8000, noise_q => 0.7, noise_decay => 2, level => 0.76 },
    72 => { fixed => 2900, partials => [ [1, 1, 1], [2, 0.2, 1] ], sweep => -0.1, sweep_time => 0.4, attack => 0.008,
        decay => 1, length => 0.35, noise => 0.15, noise_center => 6000, noise_q => 0.7, noise_decay => 1, level => 0.92 },
    # short and long guiro
    73 => { partials => [], noise => 0.7, noise_center => 4000, noise_q => 1.2, noise_decay => 30, tremolo => 1,
        trem_rate => 30, length => 0.12, level => 1.4 },
    74 => { partials => [], noise => 0.7, noise_center => 4000, noise_q => 1.2, noise_decay => 2, tremolo => 1,
        trem_rate => 25, length => 0.42, level => 0.86 },
    # claves
    75 => { fixed => 2180, partials => [ [1, 1, 1], [2.1, 0.03, 2] ], decay => 90,
        noise => 0.05, noise_center => 8000, noise_q => 0.7, noise_decay => 150, level => 2.3 },
    # hi and low wood block: a click, and under it a quieter ring
    76 => { fixed => 670, partials => [ [1, 1, 1], [1, 0.15, 0.35], [2.7, 0.45, 1.5] ], decay => 80,
        noise => 0.2, noise_center => 2500, noise_decay => 100, level => 1.83 },
    77 => { fixed => 560, partials => [ [1, 1, 1], [1, 0.15, 0.35], [2.7, 0.3, 1.5] ], decay => 70,
        noise => 0.2, noise_center => 2000, noise_decay => 100, level => 1.74 },
    # mute and open cuica: the pitch rising
    78 => { fixed => 600, partials => [ [1, 1, 1], [2, 0.3, 1], [3, 0.15, 1.2] ], sweep => -0.15, sweep_time => 0.08,
        attack => 0.08, decay => 15, level => 4.61 },
    79 => { fixed => 330, partials => [ [1, 1, 1], [2, 0.3, 1], [3, 0.15, 1.2] ], sweep => -0.15, sweep_time => 0.15,
        attack => 0.012, decay => 6.2, level => 1.73 },
    # mute and open triangle
    80 => { fixed => 7800, partials => [ [0.27, 0.12, 1], [0.5, 0.1, 1], [1, 0.6, 1], [1.44, 1, 1.2], [2, 0.3, 1.4] ],
        decay => 28, level => 0.76 },
    81 => { fixed => 7800, partials => [ [0.27, 0.12, 1], [0.5, 0.1, 1], [1, 0.6, 1], [1.44, 1, 1.2], [2, 0.3, 1.4] ],
        decay => 5.5, level => 0.65 },
);
my $DRUM_FALLBACK = { partials => [], noise => 0.6, noise_center => 3000, noise_q => 0.7, noise_decay => 20, level => 0.4 };

# The drum kits a program change on a drum channel picks (GS, GM2 and XG
# number them alike): each a name, and the keys that sound otherwise than
# the standard kit's, where FluidR3's kit does. Each such drum is the
# standard one changed as FluidR3's differs from its standard drum (pitch,
# fall, brightness), its level balanced as the kit's (devbin/audit-fluid
# --drums --kit N); or, where the kit has another instrument there, that.
# The other keys are the standard kit's.
#
#   Room        kicks darker, ringing in the room
#   Power       kicks with a hard beater; snares and toms longer, higher
#   Electronic  kicks and toms with a bright attack, the toms diving an
#               octave from where they are struck
#   TR-808      sine kicks, toms and congas; thin snares; hi-hats and
#               cymbal of faint metal and noise; no vibraslap, no timbales
#   Jazz        a low, soft kick; the snare a little darker
#   Brush       the jazz kicks; brushed snare, slap and swirl
#   Orchestra   concert bass drums and snares, timpani F to F (keys 41 to
#               53), concert cymbals

# The TR-808's hi-hats and cymbal: the hi-hat's metal, faint.
my @HAT_808 = map { [ $_->[0], 0.03, 1 ] } @{ $DRUM{42}{partials} };

# The jazz kit's kicks, the brush kit's too.
my %JAZZ_KICKS = (
    35 => { %{ $DRUM{35} }, decay => 16.5, fixed => 40, noise_center => 1700, noise_decay => 65.6, level => 2.3 },
    36 => { %{ $DRUM{36} }, decay => 22, fixed => 33.6, noise_center => 1290, noise_decay => 55.6, level => 2.51 },
);

my %KIT = (
    0  => [ Standard   => {} ],
    8  => [ Room       => {
        35 => { %{ $DRUM{35} }, decay => 24, noise_center => 1490, noise_decay => 68.5, level => 2.37 },
        36 => { %{ $DRUM{36} }, decay => 20.5, fixed => 58.5, noise_center => 1530, noise_decay => 58.1,
            level => 2.01 },
    } ],
    16 => [ Power      => {
        35 => { %{ $DRUM{35} }, decay => 11.7, noise_center => 6000, noise_decay => 32.5, level => 1.76 },
        36 => { %{ $DRUM{36} }, decay => 9.4, noise_center => 10000, noise_decay => 21.4, level => 1.67 },
        38 => { %{ $DRUM{38} }, decay => 13.4, fixed => 292, noise_center => 7790, noise_decay => 9.8, level => 1.18 },
        40 => { %{ $DRUM{40} }, decay => 15.9, fixed => 221, noise_decay => 12.5, level => 1.15 },
        41 => { %{ $DRUM{41} }, decay => 7.08, fixed => 70.2, noise => 0.35, noise_center => 1630,
            noise_decay => 50.6, level => 1.22 },
        43 => { %{ $DRUM{43} }, decay => 5.18, noise => 0.35, noise_center => 2580, noise_decay => 23.9,
            level => 1.18 },
        45 => { %{ $DRUM{45} }, decay => 6.25, fixed => 98.9, noise => 0.35, noise_center => 2560,
            noise_decay => 42.6, level => 1.42 },
        47 => { %{ $DRUM{47} }, decay => 6.76, fixed => 116, noise => 0.35, noise_center => 2900,
            noise_decay => 42.3, level => 1.38 },
        48 => { %{ $DRUM{48} }, decay => 7.98, fixed => 131, noise => 0.35, noise_center => 2970, noise_decay => 47,
            level => 1.27 },
        50 => { %{ $DRUM{50} }, decay => 9.07, fixed => 157, noise => 0.35, noise_center => 3650,
            noise_decay => 45.4, level => 1.34 },
    } ],
    24 => [ Electronic => {
        35 => { %{ $DRUM{35} }, decay => 12.2, noise => 0.25, noise_center => 3500, noise_decay => 33.9,
            noise_mode => 'band', noise_q => 0.5, level => 1.8 },
        36 => { %{ $DRUM{36} }, decay => 16.9, noise => 0.25, noise_center => 3500, noise_decay => 38.5,
            noise_mode => 'band', noise_q => 0.5, level => 1.72 },
        38 => { %{ $DRUM{38} }, decay => 12.8, fixed => 119, noise_center => 5000, noise_decay => 9.4, level => 1.14 },
        40 => { %{ $DRUM{40} }, decay => 15, fixed => 162, noise_decay => 11.8, level => 1.11 },
        41 => { %{ $DRUM{41} }, attack => 0.01, decay => 4.74, fixed => 82.3, noise => 0.4, noise_center => 4000,
            noise_decay => 33.8, noise_mode => 'band', noise_q => 0.5, sweep => 1, sweep_time => 0.15, level => 1.3 },
        43 => { %{ $DRUM{43} }, attack => 0.01, decay => 5.02, fixed => 92.5, noise => 0.4, noise_center => 4000,
            noise_decay => 23.2, noise_mode => 'band', noise_q => 0.5, sweep => 1, sweep_time => 0.15, level => 1.41 },
        45 => { %{ $DRUM{45} }, attack => 0.01, decay => 5.72, fixed => 102, noise => 0.4, noise_center => 4000,
            noise_decay => 39, noise_mode => 'band', noise_q => 0.5, sweep => 1, sweep_time => 0.15, level => 1.43 },
        47 => { %{ $DRUM{47} }, attack => 0.01, decay => 6.46, fixed => 113, noise => 0.4, noise_center => 4000,
            noise_decay => 40.4, noise_mode => 'band', noise_q => 0.5, sweep => 1, sweep_time => 0.15, level => 1.46 },
        48 => { %{ $DRUM{48} }, attack => 0.01, decay => 8.51, fixed => 142, noise => 0.4, noise_center => 4000,
            noise_decay => 50.1, noise_mode => 'band', noise_q => 0.5, sweep => 1, sweep_time => 0.15, level => 1.35 },
        50 => { %{ $DRUM{50} }, attack => 0.01, decay => 11.3, fixed => 167, noise => 0.4, noise_center => 4000,
            noise_decay => 56.5, noise_mode => 'band', noise_q => 0.5, sweep => 1, sweep_time => 0.15, level => 1.26 },
    } ],
    25 => [ 'TR-808'   => {
        35 => { %{ $DRUM{35} }, decay => 27.7, noise => 0.01, noise_center => 875, noise_decay => 76.8,
            partials => [ [ 1, 1, 1 ] ], sweep => 0.6, sweep_time => 0.03, level => 4.22 },
        36 => { %{ $DRUM{36} }, fixed => 41.3, noise => 0.01, noise_center => 875, partials => [ [ 1, 1, 1 ] ],
            sweep => 0.6, sweep_time => 0.03, level => 3.95 },
        38 => { %{ $DRUM{38} }, fixed => 155, noise_center => 4500, noise_mode => 'band', level => 2.14 },
        39 => { %{ $DRUM{39} }, noise2 => 0.15, noise2_center => 1300, noise2_decay => 8, noise2_q => 1.2,
            noise_center => 900, noise_decay => 23.7, level => 1.73 },
        40 => { %{ $DRUM{40} }, decay => 47.7, fixed => 155, noise_center => 4000, noise_decay => 37.5,
            noise_mode => 'band', level => 2.02 },
        41 => { %{ $DRUM{41} }, decay => 11.5, fixed => 85.5, noise => 0.015, noise_center => 500,
            noise_decay => 81.9, partials => [ [ 1, 1, 1 ], [ 2, 0.05, 2 ] ], sweep => 0.25, level => 3.62 },
        42 => { %{ $DRUM{42} }, decay => 47.8, fixed => 2480, noise2 => 0, noise_center => 8000, noise_decay => 47.8,
            partials => \@HAT_808, level => 1.55 },
        43 => { %{ $DRUM{43} }, decay => 14.4, fixed => 102, noise => 0.015, noise_center => 500,
            noise_decay => 66.5, partials => [ [ 1, 1, 1 ], [ 2, 0.05, 2 ] ], sweep => 0.25, level => 3.45 },
        44 => { %{ $DRUM{44} }, decay => 13, noise2 => 0, noise_center => 8000, noise_decay => 13,
            partials => \@HAT_808, level => 1.36 },
        45 => { %{ $DRUM{45} }, decay => 18.8, fixed => 128, noise => 0.015, noise_center => 500, noise_decay => 128,
            partials => [ [ 1, 1, 1 ], [ 2, 0.05, 2 ] ], sweep => 0.25, level => 3.73 },
        46 => { %{ $DRUM{46} }, decay => 6.88, noise2 => 0, noise_center => 8000, noise_decay => 6.88,
            partials => \@HAT_808, level => 1.31 },
        47 => { %{ $DRUM{47} }, decay => 12.3, fixed => 155, noise => 0.015, noise_center => 500,
            noise_decay => 76.9, partials => [ [ 1, 1, 1 ], [ 2, 0.05, 2 ] ], sweep => 0.25, level => 3.68 },
        48 => { %{ $DRUM{48} }, decay => 13.5, fixed => 191, noise => 0.015, noise_center => 500,
            noise_decay => 79.2, partials => [ [ 1, 1, 1 ], [ 2, 0.05, 2 ] ], sweep => 0.25, level => 3.63 },
        50 => { %{ $DRUM{50} }, decay => 23.5, fixed => 232, noise => 0.015, noise_center => 520, noise_decay => 118,
            partials => [ [ 1, 1, 1 ], [ 2, 0.05, 2 ] ], sweep => 0.25, level => 3.86 },
        51 => { %{ $DRUM{46} }, decay => 7.73, noise2 => 0, noise_center => 8000, noise_decay => 7.73,
            partials => \@HAT_808, level => 1.4 },
        56 => { %{ $DRUM{56} }, decay => 18.3, fixed => 540, noise => 0.02, noise_center => 2720,
            noise_decay => 23.9, partials => [ [ 1, 0.7, 1 ], [ 1.48, 1, 1 ] ], level => 2.79 },
        58 => { partials => [], level => 0 },
        62 => { %{ $DRUM{62} }, decay => 26.9, fixed => 404, noise => 0, noise2 => 0,
            partials => [ [ 1, 1, 1 ], [ 2, 0.05, 2 ] ], sweep => 0.05, level => 2.85 },
        63 => { %{ $DRUM{63} }, decay => 24.8, fixed => 263, noise => 0, noise2 => 0,
            partials => [ [ 1, 1, 1 ], [ 2, 0.05, 2 ] ], sweep => 0.05, level => 2.88 },
        64 => { %{ $DRUM{64} }, fixed => 186, noise => 0, noise2 => 0, partials => [ [ 1, 1, 1 ], [ 2, 0.05, 2 ] ],
            sweep => 0.05, level => 2.97 },
        65 => { partials => [], level => 0 },
        66 => { partials => [], level => 0 },
        75 => { %{ $DRUM{75} }, noise => 0.01, noise_center => 6550, level => 4.92 },
    } ],
    32 => [ Jazz       => {
        %JAZZ_KICKS,
        38 => { %{ $DRUM{38} }, fixed => 199, noise_center => 4800, level => 1.16 },
    } ],
    40 => [ Brush      => {
        %JAZZ_KICKS,
        38 => { %{ $DRUM{38} }, decay => 37.3, fixed => 276, noise_decay => 27.3, level => 0.679 },
        39 => { %{ $DRUM{39} }, decay => 30, fixed => 165, noise_center => 929, noise_decay => 32.1,
            partials => [ [ 1, 0.3, 1 ] ], level => 0.707 },
        40 => { %{ $DRUM{40} }, decay => 10.7, fixed => 127, noise_attack => 0.05, noise_decay => 8.43,
            level => 0.291 },
    } ],
    48 => [ Orchestra  => {
        35 => { %{ $DRUM{35} }, decay => 4.31, fixed => 133, noise => 0.08, noise_center => 2000, noise_decay => 12,
            sweep => 0.3, level => 1.01 },
        36 => { %{ $DRUM{36} }, decay => 4.53, fixed => 141, noise => 0.08, noise_center => 2000,
            noise_decay => 10.3, sweep => 0.3, level => 1.09 },
        38 => { %{ $DRUM{38} }, decay => 18.6, fixed => 214, noise_center => 7740, noise_decay => 13.7,
            level => 0.723 },
        40 => { %{ $DRUM{40} }, decay => 19.2, fixed => 214, noise_center => 6610, noise_decay => 15.1,
            level => 0.701 },
        41 => { %{ $GM[47] }, decay => 4, fixed => 87.3, level => 0.731 },
        42 => { %{ $GM[47] }, decay => 4, fixed => 92.5, level => 0.718 },
        43 => { %{ $GM[47] }, decay => 4, fixed => 98, level => 0.536 },
        44 => { %{ $GM[47] }, decay => 4, fixed => 104, level => 0.558 },
        45 => { %{ $GM[47] }, decay => 4, fixed => 110, level => 0.547 },
        46 => { %{ $GM[47] }, decay => 4, fixed => 117, level => 0.525 },
        47 => { %{ $GM[47] }, decay => 4, fixed => 123, level => 0.534 },
        48 => { %{ $GM[47] }, decay => 4, fixed => 131, level => 0.533 },
        49 => { %{ $GM[47] }, decay => 4, fixed => 139, level => 0.497 },
        50 => { %{ $GM[47] }, decay => 4, fixed => 147, level => 0.525 },
        51 => { %{ $GM[47] }, decay => 4, fixed => 156, level => 0.516 },
        52 => { %{ $GM[47] }, decay => 4, fixed => 165, level => 0.519 },
        53 => { %{ $GM[47] }, decay => 4, fixed => 175, level => 0.537 },
        57 => { %{ $DRUM{57} }, decay => 2.45, fixed => 594, noise2_decay => 2.45, noise_center => 7360,
            noise_decay => 2.45, level => 0.393 },
        59 => { %{ $DRUM{59} }, decay => 5, noise_center => 12000, level => 0.596 },
    } ],
);

my (%PROGRAM_PATCH, %DRUM_PATCH);

# The patch of a program, or of a variation of it (by its GS bank).
sub program ($number, $bank = 0) {
    return $PROGRAM_PATCH{"$bank:$number"} //= do {
        my $variation = $bank && ($VARIATION{$bank}{$number} // die "no variation $bank of program $number\n");
        _make(%{ $variation ? $variation->[1] : $GM[$number] // die "no GM program $number\n" });
    };
}

# The patch of a drum key in a kit: the kit's own, or the standard kit's.
sub drum ($key, $kit = 0) {
    $kit = kit_key($kit, $key);
    return $DRUM_PATCH{"$kit:$key"} //= _make(
        attack => 0.0005, release => 0.05, sustain => 1, velocity => 1.4, length => 4,
        %{ $kit ? $KIT{$kit}[1]{$key} : $DRUM{$key} // $DRUM_FALLBACK }, drum => 1,
    );
}

# The GS bank of the variation a bank select picks for a program: GS's own
# (the MSB) where there is that variation, GM2's (MSB 121, the LSB the
# variation) where it is one of these; else 0, the program itself, as GS
# and XG play what they do not have (XG's variations are not here).
sub variation ($msb, $lsb, $program) {
    return $GM2{$program}{$lsb} // 0 if $msb == 121;
    return $VARIATION{$msb} && $VARIATION{$msb}{$program} ? $msb : 0;
}

# The kit a program change on a drum channel picks: its own, or the kit
# its group of eight begins with (GS's Room 2 and Jazz 3 are Room and Jazz
# here), or the standard kit.
sub kit ($program) {
    return $program if $KIT{$program};
    my $group = $program - $program % 8;
    return $KIT{$group} ? $group : 0;
}

# The kit whose patch a key of a kit plays: the kit, where it has the key
# as its own, or the standard kit.
sub kit_key ($kit, $key) {
    return $KIT{$kit} && $KIT{$kit}[1]{$key} ? $kit : 0;
}

sub fields () { return sort keys %DEFAULT }

# Every field's default, as a patch made of nothing has it (a copy).
sub defaults () { return { map { $_ => ref $DEFAULT{$_} ? [ @{ $DEFAULT{$_} } ] : $DEFAULT{$_} } keys %DEFAULT } }

# What an editor needs to know of the fields: the group they belong to, their
# range, whether the range is better walked in steps of equal ratio (log),
# and what they do. Fields not listed (partials, formants, drum) are edited
# otherwise or not at all.
my @FIELD_INFO = (
    [ spectrum => slope     => 0,     10,    'lin', 'how fast the harmonics fall: amplitude k^-slope' ],
    [ spectrum => even      => 0,     2,     'lin', 'level of the even harmonics (low: hollow, clarinet-like; high: an octave reed or pipe)' ],
    [ spectrum => cutoff    => 100,   16000, 'log', 'soft low-pass on the harmonics (Hz)' ],
    [ spectrum => rolloff   => 0,     3,     'int', 'the low-pass steeper: 12 dB an octave more for each' ],
    [ spectrum => track     => 0,     1,     'lin', 'how much the cutoff follows the key' ],
    [ spectrum => bright    => 0,     3,     'lin', 'how much velocity opens the cutoff' ],
    [ spectrum => pluck     => 0,     0.5,   'lin', 'pluck or strike position: harmonics with a node there are weak' ],
    [ spectrum => stretch   => 0,     0.002, 'lin', 'inharmonicity: upper partials stretched sharp (piano strings)' ],
    [ spectrum => stretch_key => 0,   3,     'lin', 'the stiffness grows with the key: B doubles every 12 / stretch_key semitones up' ],
    [ spectrum => max       => 1,     256,   'log', 'harmonics at most' ],
    [ partials => decay     => 0,     100,   'log', 'decay of the fundamental (1/s); 0 sustains' ],
    [ partials => decay_k   => 0,     2,     'lin', 'upper partials decay this much faster, per partial' ],
    [ partials => decay_key => 0,     2,     'lin', 'higher keys decay faster' ],
    [ partials => decay_k_key => 0,   3,     'lin', 'decay_k grows with the key: the upper partials die sooner in the treble' ],
    [ partials => attack_k  => 0,     0.05,  'lin', 'upper partials come in later (s per partial)' ],
    [ envelope => attack    => 0.0005, 4,    'log', 'attack time (s)' ],
    [ envelope => hold      => 0,     2,     'lin', 'time at full level (s)' ],
    [ envelope => fall      => 0.01,  10,    'log', 'decay time constant towards sustain (s)' ],
    [ envelope => sustain   => 0,     1,     'lin', 'sustain level' ],
    [ envelope => release   => 0.005, 5,     'log', 'release time constant (s)' ],
    [ envelope => level     => 0,     5,     'lin', 'level' ],
    [ envelope => velocity  => 0,     3,     'lin', 'velocity sensitivity: loudness (velocity/127)^this' ],
    [ pitch    => transpose => -48,   48,    'int', 'semitones' ],
    [ pitch    => fixed     => 0,     8000,  'lin', 'a fixed pitch in Hz, whatever the key (0: off)' ],
    [ pitch    => sweep     => -1,    4,     'lin', 'the pitch starts this much higher (ratio - 1) ...' ],
    [ pitch    => sweep_time => 0.001, 1,    'log', '... and falls back with this time constant (s)' ],
    [ pitch    => vibrato   => 0,     400,   'log', 'vibrato depth (cents)' ],
    [ pitch    => vib_rate  => 0.1,   20,    'log', 'vibrato rate (Hz)' ],
    [ pitch    => vib_delay => 0,     2,     'lin', 'vibrato fades in after (s)' ],
    [ pitch    => tremolo   => 0,     1,     'lin', 'tremolo depth' ],
    [ pitch    => trem_rate => 0.1,   100,   'log', 'tremolo rate (Hz)' ],
    [ unison   => unison    => 1,     5,     'int', 'detuned copies of the partials' ],
    [ unison   => detune    => 0,     50,    'lin', 'cents between the outermost copies' ],
    [ unison   => unison_k  => 1,     64,    'int', 'partials each copy carries' ],
    [ unison   => unison_sync => 0,   1,     'int', '1: the copies begin in phase, as strings struck by one hammer (0: each its own)' ],
    [ noise    => noise         => 0,   2,     'lin', 'noise level' ],
    [ noise    => noise_center  => 20,  20000, 'log', 'noise band centre (Hz)' ],
    [ noise    => noise_ratio   => 0,   16,    'lin', 'noise band centre as a multiple of the pitch (0: use Hz)' ],
    [ noise    => noise_q       => 0.1, 10,    'log', 'noise band narrowness (Q)' ],
    [ noise    => noise_attack  => 0.0005, 4,  'log', 'noise attack (s)' ],
    [ noise    => noise_decay   => 0,   200,   'lin', 'noise decay (1/s)' ],
    [ noise    => noise_sustain => 0,   1,     'lin', 'noise level left after the decay' ],
    [ noise    => noise_mode    => 'band', 'low', 'choice', 'band-, high- or low-pass', [qw(band high low)] ],
    [ noise    => noise_poles   => 2,   4,     'choice', 'the filter: 2 poles, or 4 for twice as steep', [ 2, 4 ] ],
    [ noise    => noise_grains  => 0,   2000,  'log', 'bursts a second at random moments (applause, rain); 0: steady' ],
    [ noise    => noise_grain_decay => 10, 1000, 'log', 'how fast a burst falls (1/s)' ],
    (map {
        my ($b, $n) = @$_;
        [ $b => $b             => 0,   2,     'lin', "band $n: level" ],
        [ $b => "${b}_center"  => 20,  20000, 'log', "band $n: centre (Hz)" ],
        [ $b => "${b}_ratio"   => 0,   16,    'lin', "band $n: centre as a multiple of the pitch (0: use Hz)" ],
        [ $b => "${b}_q"       => 0.1, 10,    'log', "band $n: narrowness (Q)" ],
        [ $b => "${b}_attack"  => 0.0005, 4,  'log', "band $n: attack (s)" ],
        [ $b => "${b}_decay"   => 0,   200,   'lin', "band $n: decay (1/s)" ],
        [ $b => "${b}_sustain" => 0,   1,     'lin', "band $n: level left after the decay" ],
        [ $b => "${b}_mode"    => 'band', 'low', 'choice', "band $n: band-, high- or low-pass", [qw(band high low)] ],
        [ $b => "${b}_poles"   => 2,   4,     'choice', "band $n: the filter's poles", [ 2, 4 ] ],
        [ $b => "${b}_grains"  => 0,   2000,  'log', "band $n: bursts a second; 0: steady" ],
        [ $b => "${b}_grain_decay" => 10, 1000, 'log', "band $n: how fast a burst falls (1/s)" ],
    } [ noise2 => 2 ], [ noise3 => 3 ]),
    [ string   => string        => 0,     2,    'lin', 'a string (Karplus-Strong), plucked or struck: its level' ],
    [ string   => string_decay  => 0.05,  30,   'log', 'seconds it falls 60 dB in, at middle C' ],
    [ string   => string_key    => 0,     2,    'lin', 'higher keys decay faster' ],
    [ string   => string_damp   => 0,     0.95, 'lin', 'damping in the loop: the highs die sooner' ],
    [ string   => string_pick   => 0,     0.5,  'lin', 'where along the string it is plucked or struck' ],
    [ string   => string_bright => 0.01,  1,    'log', 'how bright the pluck is (struck: how hard the hammer is)' ],
    [ string   => string_vel    => 0,     3,    'lin', 'how much velocity brightens the pluck' ],
    [ string   => string_noise  => 0,     1,    'lin', 'how much of the pluck is noise (the rest the plucked string\'s shape)' ],
    [ string   => string_excite => 'pluck', 'strike', 'choice', 'plucked, or struck by a hammer (string_bright: how hard it is)' ],
    [ string   => string_stiff  => 0,     0.002, 'lin', 'stiffness: upper harmonics sharp, as stretch has the partials (piano strings)' ],
    [ fm       => fm            => 0,     2,    'lin', 'FM (four operators): its level' ],
    [ fm       => fm_alg        => 1,     8,    'int', 'the algorithm: 1 4>3>2>1; 2 (4+3)>2>1; 3 (4+(3>2))>1; 4 ((4>3)+2)>1; 5 4>3, 2>1; 6 4>3,2,1; 7 4>3, 2, 1; 8 all four' ],
    [ fm       => fm_fb         => 0,     1,    'lin', 'operator 4 modulating itself (feedback)' ],
    (map {
        my $o = $_;
        my $g = "op$o";
        [ $g => "${g}_ratio"   => 0.25, 32,   'log', "operator $o: frequency, times the note's" ],
        [ $g => "${g}_detune"  => -50,  50,   'lin', "operator $o: detune (cents)" ],
        [ $g => "${g}_level"   => 0,    10,   'lin', "operator $o: amplitude as a carrier, index (radians) as a modulator" ],
        [ $g => "${g}_attack"  => 0.0005, 4,  'log', "operator $o: attack (s)" ],
        [ $g => "${g}_decay"   => 0.005, 20,  'log', "operator $o: decay time constant (s)" ],
        [ $g => "${g}_sustain" => 0,    1,    'lin', "operator $o: sustain level" ],
        [ $g => "${g}_release" => 0.005, 10,  'log', "operator $o: release time constant (s)" ],
        [ $g => "${g}_vel"     => 0,    1,    'lin', "operator $o: how much velocity moves its level" ],
        [ $g => "${g}_key"     => -2,   2,    'lin', "operator $o: higher keys, lower level (this power of the pitch)" ],
    } 1 .. 4),
    [ noise    => rough         => 0,   1,     'lin', 'noise on the partials: how much it moves their amplitude' ],
    [ noise    => rough_rate    => 5,   5000,  'log', 'noise on the partials: how fast it moves (Hz)' ],
    [ filter   => filter        => 'off', 'bp', 'choice', 'the filter: low-pass of 12 or 24 dB an octave, high-pass, band-pass', [qw(off lp12 lp24 hp12 hp24 bp)] ],
    [ filter   => filter_cutoff => 20,    20000, 'log', 'cutoff at middle C (Hz)' ],
    [ filter   => filter_track  => 0,     1,     'lin', 'how much the cutoff follows the key' ],
    [ filter   => filter_q      => 0.5,   20,    'log', 'resonance (Q)' ],
    [ filter   => filter_env    => -8,    8,     'lin', 'octaves the second envelope moves the cutoff' ],
    [ filter   => filter_vel    => -4,    4,     'lin', 'octaves velocity moves the cutoff' ],
    [ env2     => env2_attack   => 0.0005, 4,    'log', 'attack (s)' ],
    [ env2     => env2_decay    => 0.005, 10,    'log', 'decay time constant (s)' ],
    [ env2     => env2_sustain  => 0,     1,     'lin', 'sustain level' ],
    [ env2     => env2_release  => 0.005, 10,    'log', 'release time constant (s)' ],
    [ lfo      => lfo1_rate     => 0.01,  50,    'log', 'first LFO: rate (Hz)' ],
    [ lfo      => lfo1_shape    => 'sine', 'random', 'choice', 'first LFO: shape', [qw(sine triangle square saw random)] ],
    [ lfo      => lfo1_delay    => 0,     5,     'lin', 'first LFO: fades in over (s)' ],
    [ lfo      => lfo2_rate     => 0.01,  50,    'log', 'second LFO: rate (Hz)' ],
    [ lfo      => lfo2_shape    => 'sine', 'random', 'choice', 'second LFO: shape', [qw(sine triangle square saw random)] ],
    [ lfo      => lfo2_delay    => 0,     5,     'lin', 'second LFO: fades in over (s)' ],
    [ pitch    => length    => 0,     10,    'lin', 'a drum rings this long at most (s)' ],
);

# The fields as an editor shows them: name, group, min, max, scale, what it
# does; a choice's options (its first and last are min and max).
sub field_info () {
    my @info;
    for my $field (@FIELD_INFO) {
        my ($group, $name, $min, $max, $scale, $about, $choices) = @$field;
        push @info, {
            group => $group,
            name  => $name,
            min   => $min,
            max   => $max,
            scale => $scale,
            about => $about,
            $scale eq 'choice' ? (choices => $choices // [ $min, $max ]) : (),
        };
    }
    return \@info;
}

my @PROGRAM_NAMES = (
    'Acoustic Grand Piano', 'Bright Acoustic Piano', 'Electric Grand Piano', 'Honky-tonk Piano', 'Electric Piano 1',
    'Electric Piano 2', 'Harpsichord', 'Clavinet', 'Celesta', 'Glockenspiel', 'Music Box', 'Vibraphone', 'Marimba',
    'Xylophone', 'Tubular Bells', 'Dulcimer', 'Drawbar Organ', 'Percussive Organ', 'Rock Organ', 'Church Organ',
    'Reed Organ', 'Accordion', 'Harmonica', 'Tango Accordion', 'Acoustic Guitar (nylon)', 'Acoustic Guitar (steel)',
    'Electric Guitar (jazz)', 'Electric Guitar (clean)', 'Electric Guitar (muted)', 'Overdriven Guitar',
    'Distortion Guitar', 'Guitar Harmonics', 'Acoustic Bass', 'Electric Bass (finger)', 'Electric Bass (pick)',
    'Fretless Bass', 'Slap Bass 1', 'Slap Bass 2', 'Synth Bass 1', 'Synth Bass 2', 'Violin', 'Viola', 'Cello',
    'Contrabass', 'Tremolo Strings', 'Pizzicato Strings', 'Orchestral Harp', 'Timpani', 'String Ensemble 1',
    'String Ensemble 2', 'Synth Strings 1', 'Synth Strings 2', 'Choir Aahs', 'Voice Oohs', 'Synth Voice',
    'Orchestra Hit', 'Trumpet', 'Trombone', 'Tuba', 'Muted Trumpet', 'French Horn', 'Brass Section', 'Synth Brass 1',
    'Synth Brass 2', 'Soprano Sax', 'Alto Sax', 'Tenor Sax', 'Baritone Sax', 'Oboe', 'English Horn', 'Bassoon',
    'Clarinet', 'Piccolo', 'Flute', 'Recorder', 'Pan Flute', 'Blown Bottle', 'Shakuhachi', 'Whistle', 'Ocarina',
    'Lead 1 (square)', 'Lead 2 (sawtooth)', 'Lead 3 (calliope)', 'Lead 4 (chiff)', 'Lead 5 (charang)',
    'Lead 6 (voice)', 'Lead 7 (fifths)', 'Lead 8 (bass + lead)', 'Pad 1 (new age)', 'Pad 2 (warm)',
    'Pad 3 (polysynth)', 'Pad 4 (choir)', 'Pad 5 (bowed)', 'Pad 6 (metallic)', 'Pad 7 (halo)', 'Pad 8 (sweep)',
    'FX 1 (rain)', 'FX 2 (soundtrack)', 'FX 3 (crystal)', 'FX 4 (atmosphere)', 'FX 5 (brightness)', 'FX 6 (goblins)',
    'FX 7 (echoes)', 'FX 8 (sci-fi)', 'Sitar', 'Banjo', 'Shamisen', 'Koto', 'Kalimba', 'Bagpipe', 'Fiddle', 'Shanai',
    'Tinkle Bell', 'Agogo', 'Steel Drums', 'Woodblock', 'Taiko Drum', 'Melodic Tom', 'Synth Drum', 'Reverse Cymbal',
    'Guitar Fret Noise', 'Breath Noise', 'Seashore', 'Bird Tweet', 'Telephone Ring', 'Helicopter', 'Applause',
    'Gunshot',
);

my %DRUM_NAMES = (
    35 => 'Acoustic Bass Drum', 36 => 'Bass Drum 1', 37 => 'Side Stick', 38 => 'Acoustic Snare', 39 => 'Hand Clap',
    40 => 'Electric Snare', 41 => 'Low Floor Tom', 42 => 'Closed Hi-Hat', 43 => 'High Floor Tom', 44 => 'Pedal Hi-Hat',
    45 => 'Low Tom', 46 => 'Open Hi-Hat', 47 => 'Low-Mid Tom', 48 => 'Hi-Mid Tom', 49 => 'Crash Cymbal 1',
    50 => 'High Tom', 51 => 'Ride Cymbal 1', 52 => 'Chinese Cymbal', 53 => 'Ride Bell', 54 => 'Tambourine',
    55 => 'Splash Cymbal', 56 => 'Cowbell', 57 => 'Crash Cymbal 2', 58 => 'Vibraslap', 59 => 'Ride Cymbal 2',
    60 => 'Hi Bongo', 61 => 'Low Bongo', 62 => 'Mute Hi Conga', 63 => 'Open Hi Conga', 64 => 'Low Conga',
    65 => 'High Timbale', 66 => 'Low Timbale', 67 => 'High Agogo', 68 => 'Low Agogo', 69 => 'Cabasa', 70 => 'Maracas',
    71 => 'Short Whistle', 72 => 'Long Whistle', 73 => 'Short Guiro', 74 => 'Long Guiro', 75 => 'Claves',
    76 => 'Hi Wood Block', 77 => 'Low Wood Block', 78 => 'Mute Cuica', 79 => 'Open Cuica', 80 => 'Mute Triangle',
    81 => 'Open Triangle',
);

sub program_name ($number, $bank = 0) {
    return $VARIATION{$bank}{$number}[0] if $bank && $VARIATION{$bank} && $VARIATION{$bank}{$number};
    return $PROGRAM_NAMES[$number] // "Program $number";
}
sub drum_name ($key)       { return $DRUM_NAMES{$key} // "Drum $key" }
sub kit_name ($kit)        { return $KIT{$kit} ? $KIT{$kit}[0] : "Kit $kit" }
sub program_names ()       { return [@PROGRAM_NAMES] }
sub drum_names ()          { return {%DRUM_NAMES} }

# The kits: { number => { name, keys (its own, the others the standard kit's) } }.
sub kits () {
    return { map { $_ => { name => $KIT{$_}[0], keys => [ sort { $a <=> $b } keys %{ $KIT{$_}[1] } ] } } keys %KIT };
}

# The variations: [ GS bank, program, name ], in the order of the programs.
sub variations () {
    my @all;
    for my $bank (keys %VARIATION) {
        push @all, map { [ 0 + $bank, 0 + $_, $VARIATION{$bank}{$_}[0] ] } keys %{ $VARIATION{$bank} };
    }
    return [ sort { $a->[1] <=> $b->[1] || $a->[0] <=> $b->[0] } @all ];
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::Patch - the General MIDI instruments, their variations, and the drum kits

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $piano   = Peta::Synth::Patch::program(0);
    my $detuned = Peta::Synth::Patch::program(4, 8);     # Detuned EP 1, GS bank 8
    my $snare   = Peta::Synth::Patch::drum(38);
    my $brush   = Peta::Synth::Patch::drum(38, 40);      # the brush kit's

=head1 DESCRIPTION

Every instrument is synthesized: a bank of sine partials and up to three
bands of noise, under an envelope, with no samples. A patch is a hash of the fields
listed (with their meaning and defaults) at the top of the source; the 128
General MIDI programs are built from family templates, and the drum keys 35
to 81 each have their own patch. Peta::Synth::Voice turns a patch and a
note into the partials and envelope that the engines play.

A patch may have a string beside its partials, or instead of them
(C<< partials => [] >>): a Karplus-Strong delay line, plucked or struck,
its decay, damping, stiffness, pick position and pluck as the C<string>
fields say. So with FM: four
sine operators in one of the eight algorithms of Yamaha's four-operator
chips, operator 4 with feedback, each with its ratio, detune, level,
envelope, velocity and key scaling (the C<fm> and C<op> fields).

Besides the spectrum, fixed when a note begins, a patch may have a filter
that moves while the note sounds (low-pass of 12 or 24 dB an octave,
high-pass, band-pass; its cutoff following the key, velocity and a second
envelope, and brightness and resonance from CC74 and CC71), and routes of
modulation: sources (velocity, key, the wheel, breath, foot, pressure,
CC74, CC71, the second envelope, two LFOs) times an amount into
destinations (pitch, cutoff, resonance, level, pan, noise).

=head1 FUNCTIONS

=head2 program

C<program($number, $bank)>: the patch of a GM program, 0 .. 127, or of its
variation in GS's bank C<$bank> (one of C<variations>, below; dies otherwise).

=head2 drum

C<drum($key, $kit)>: the patch of a drum key in a kit (the standard kit,
0, unless told): the kit's own, or the standard kit's where the kit does
not have the key as its own. Keys outside the GM kit get a short noise hit.

=head2 variation, kit, kit_key

C<variation($msb, $lsb, $program)>: the GS bank of the variation a bank
select (MSB and LSB) picks for a program, 0 for the program itself: GS's
banks as they are, GM2's (MSB 121) by their LSB where GM2's variation is
one of GS's here; what is not here plays the program, as GS and XG do.
C<kit($program)>: the kit a program change on a drum channel picks: the
program's own, the first of its group of eight, or the standard kit, 0.
C<kit_key($kit, $key)>: the kit whose patch the key plays in C<$kit>.

The variations are those FluidR3 has (GS banks 8, 9 and 16), the kits
Standard (0), Room (8), Power (16), Electronic (24), TR-808 (25), Jazz
(32), Brush (40) and Orchestra (48).

=head2 fields, defaults

The names of a patch's fields; every field's default, as a hash.

=head2 field_info

The fields as an editor shows them: a list of hashes with C<name>, C<group>,
C<min>, C<max>, C<scale> (C<lin>, C<log>, C<int> or C<choice>, with its
C<choices>) and C<about>.

=head2 mod_sources, mod_destinations, mod_info

The names of modulation's sources and destinations, and both with what
they are.

=head2 program_name, drum_name, kit_name, program_names, drum_names, variations, kits

The names of the programs (C<program_name($number, $bank)>: a variation's
with a bank), of the drum keys and of the kits; C<variations>: every
variation, as C<[ bank, program, name ]>; C<kits>: every kit, as C<<
{ number => { name, keys } } >>, C<keys> those it has as its own.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
