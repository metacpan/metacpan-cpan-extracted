# Synthesis

Every sound is computed: no samples, no SoundFonts. A note is a *voice*,
made from a *patch* (an instrument's description) when the note begins,
and rendered by an engine (see [backends](backends.md)), which all compute
the same voice model. The code is in `Peta::Synth::Voice` (the model),
`Peta::Synth::Patch` (the fields and the General MIDI instruments) and
`Peta::Synth::Synth` (channels, the mix).

## A voice

A voice has up to five sources, under one envelope:

| Source | What it is | Made by |
|---|---|---|
| Partials | sine partials, each with its own frequency ratio, amplitude, decay and fade-in | additive synthesis |
| String | a delay line a period long, its loop damped (Karplus-Strong), plucked or struck | physical modelling |
| FM | four sine operators modulating each other | frequency modulation |
| Noise | up to three bands of white noise, each through its own filter | subtractive synthesis |
| Noise on the partials | low-passed noise moving the partials' amplitude | amplitude modulation |

A patch uses any of them: an organ only partials, a guitar a string alone
(`partials => []`), an electric piano FM, a flute partials with a band of
breath noise and noise on its partials.

### Partials

Either a harmonic spectrum, shaped by fields, or a list of partials of the
patch's own (`[ratio, amplitude, decay factor]` each: bells, mallets,
tines, drums). The spectrum:

- harmonic *k* at *k* times the note (stretched sharp by `stretch`, as a
  piano string's are, and more up the keyboard by `stretch_key`), its
  amplitude *k*^-`slope`
- the even harmonics times `even` (low: hollow, like a clarinet; above 1,
  as an octave reed or pipe of the same spectrum sounding besides)
- a two-pole low-pass at `cutoff`, following the key (`track`) and opened
  by velocity (`bright`), its resonance raised by CC71; steeper by 12 dB
  an octave for each `rolloff` (a hammer's felt)
- a pluck or strike position (`pluck`): the harmonics with a node there
  weak
- formants: peaks or dips around frequencies (`[centre Hz, gain, width in
  octaves]`), as voices and resonating bodies have

Over time each partial decays (`decay`, the upper ones faster by
`decay_k`, and more so in higher keys by `decay_k_key`; the higher keys
faster by `decay_key`) and may come in late (`attack_k`: brass speaks
low first). The strongest partials are kept, at most the quality's
number (48 by default, `--partials`); unison copies (`unison`, `detune`,
`unison_k`) and the channel's chorus share that budget; the copies begin
each at its own phase, or in phase (`unison_sync`: strings struck by one
hammer, which then beat). Partials near the Nyquist frequency fade out,
so a bend cannot alias them.

### The string

Karplus-Strong, as Jaffe and Smith extend it: a delay line a period long,
read a whole number of samples back and the rest through a first-order
allpass (which delays without damping, so the decay is what is asked at
every pitch); its loop a two-tap low-pass (`string_damp`: the highs die
sooner) and a gain that makes it fall 60 dB in `string_decay` seconds at
middle C (`string_key`: higher keys sooner). The pitch follows bend,
vibrato and glide. Tuned to 2 cents from E2 to E6.

It starts with a period of the string's velocity, fed into the loop as it
runs (`string_excite`):

- **pluck**: as the pick lets the string go, two levels that change at the
  pick position (`string_pick`); its harmonics fall as sin(*k* π pick) /
  *k*, none with a node at the pick
- **strike**: a hammer's blow at that position, a pulse less its copy a
  pick's length round the period; its harmonics as sin(*k* π pick), not
  falling but for the hammer's felt

Either with a share of noise (`string_noise`), low-passed by how bright
the pluck is or how hard the hammer (`string_bright`, opened by velocity
by `string_vel`).

**Stiffness** (`string_stiff`, as `stretch` for the partials): harmonic *k*
at *k* √(1 + B *k*²) times the note, as a piano string's are. Four
first-order allpasses in the loop, their coefficient fitted when a note
begins so that the eighth harmonic is where it should be and the
fundamental in tune: up to the tenth harmonic within some 3 cents at B =
0.0004 (25 cents at the most, 0.002); those above are stretched less than
they should be.

### FM

Four sine operators. Each is a sine of its phase plus what modulates it;
a carrier's level is its amplitude, a modulator's level the modulation
index (radians). Operator 4 also modulates itself (`fm_fb`, feedback: from
a sine towards a sawtooth). The algorithm (`fm_alg`) says who modulates
whom, as the eight of Yamaha's four-operator chips:

| | | Carriers |
|---|---|---|
| 1 | 4 → 3 → 2 → 1 | 1 |
| 2 | (4 + 3) → 2 → 1 | 1 |
| 3 | (4 + (3 → 2)) → 1 | 1 |
| 4 | ((4 → 3) + 2) → 1 | 1 |
| 5 | 4 → 3, 2 → 1 | 1, 3 |
| 6 | 4 → 3, 2, 1 | 1, 2, 3 |
| 7 | 4 → 3; 2; 1 | 1, 2, 3 |
| 8 | 4; 3; 2; 1 | all four |

Each operator has a frequency ratio and detune, a level, an envelope
(attack, decay, sustain, release), velocity sensitivity and key scaling.
The index can be modulated (the destination `fm`). The sidebands come out
as Bessel's functions say (checked to 1 %).

### Noise

Up to three bands (`noise`, `noise2`, `noise3`), each white noise through
a state-variable filter, band-, high- or low-pass, at a centre in Hz or as
a multiple of the note, of a Q; each with its own level, attack, decay and
sustain. A band's level does not depend on how wide it is. And noise on
the partials (`rough`, `rough_rate`): white noise through a one-pole
low-pass moving the partials' amplitude, for breath, bow and growl.

### The envelope and the pitch

The voice's envelope: attack (linear), hold, decay (a time constant) to
sustain, release (a time constant) after the key; its level, and how
velocity sets it. A tremolo on it (`tremolo`, `trem_rate`).

The pitch: the key, `transpose`, or a fixed pitch (`fixed`, for drums);
the channel's bend and tunings; a vibrato (`vibrato` cents, `vib_rate`,
fading in after `vib_delay`), deepened by the modulation wheel and
pressure; a sweep from above at the start (`sweep`, `sweep_time`: a drum's
thump); portamento and legato glides (see [MIDI](midi.md#pitch)).

### The filter that moves

Besides the spectrum's cutoff, fixed when a note begins, a patch may have
a filter that moves while it sounds (`filter`): low-pass of 12 or 24 dB an
octave, high-pass of 12 or 24, or band-pass, with a resonance
(`filter_q`). Its cutoff (`filter_cutoff` at middle C) follows the key
(`filter_track`) and velocity (`filter_vel`), the second envelope
(`filter_env` octaves at its peak), brightness (CC74) and resonance
(CC71), and whatever routes modulate it. It acts on the partials: each
partial's amplitude, at every block of 64 samples, times the filter's
response at its frequency, so a sweep is smooth and costs a few
operations per partial and block.

### Modulation

Sources, each times an amount, summed into destinations, taken at every
block of 64 samples. A patch's routes are a list of `[source, destination,
amount]`.

| Source | |
|---|---|
| `velocity` | the note's velocity, 0 .. 1 |
| `key` | the key, in octaves from middle C |
| `wheel`, `breath`, `foot` | CC1, CC2, CC4, 0 .. 1 |
| `pressure` | channel or key pressure, the greater |
| `cc74`, `cc71` | brightness and resonance, -1 .. 1 around 64 |
| `env2` | the second envelope, 0 .. 1 |
| `lfo1`, `lfo2` | two LFOs, -1 .. 1: sine, triangle, square, sawtooth or random (held for a period); a rate, a fade-in; from the note's start |

| Destination | An amount of 1 |
|---|---|
| `pitch` | a semitone |
| `cutoff` | an octave of the filter's cutoff |
| `q` | the filter's Q doubled |
| `level` | the level times 2 (times 1 + amount) |
| `pan` | all the way right (-1 .. 1) |
| `noise` | the noise's level times 2 (times 1 + amount) |
| `fm` | FM's index doubled (an octave) |

A patch with neither a filter nor routes costs nothing of this.

## The mix

After the voices, per channel and on the master:

- **Channel**: volume and expression (each squared), pan (constant
  power), a reverb send, chorus (detuned copies of the partials, up to 24
  cents further apart); an equalizer per channel (the same four bands as
  the master's), applied as gains on its voices' partials, the levels of
  their noise bands and strings, heard at once
- **Reverb**: a feedback delay network of eight lines (Hadamard mixing,
  damped, mutually prime lengths); time, size, damping, level, predelay
- **Master**: a four-band equalizer (low shelf, two peaking bands, high
  shelf; biquads, ±12 dB), the gain (and MIDI's master volume and
  balance), a limiter that looks a block (64 samples, 1.3 ms) ahead, so
  that its gain is down before a peak comes (no sample over 0.98), and
  lets go over a quarter of a second

The reverb and the equalizers are linear and time-invariant, so a render
may split its notes among processes, each with its own reverb, and add
what they make (see [rendering](rendering.md#a-render)); a render has no
limiter, it is normalized instead.

## Patches and banks

The 128 General MIDI programs are built from some fifteen family templates
(piano, electric piano, mallet, organ, guitar, bass, strings, ensemble,
choir, brass, reed, pipe, lead, pad, bell), each program the template with
its own changes. The drum kit is GM's keys 35 to 81, each its own patch:
kicks and toms a pitch sweep and a drumhead's partials, snares and hand
drums those with noise, hi-hats and cymbals faint inharmonic partials over
bands of noise; other keys get a short noise hit. The kit is measured
against FluidR3's standard kit (`devbin/audit-fluid --drums`: pitch, how
fast each drum falls, its octave bands, its level). The other kits (Room,
Power, Electronic, TR-808, Jazz, Brush, Orchestra) have their own drums
where FluidR3's do, each the standard drum changed as FluidR3's differs
from its standard one, or the instrument the kit has there (the
orchestra kit's timpani); the program variations are their programs,
changed as FluidR3's differ from its programs (see `Peta::Synth::Patch`).

Every field can be changed while notes sound, in the web page or in code
(`program_patch`, `drum_patch`); the changes are a *bank*, a JSON file the
renderer, the player and the page read (`--bank`):

```json
{
  "programs": { "4": { "partials": [], "fm": 1, "fm_alg": 5, "op4_ratio": 14 } },
  "drums":    { "38": { "noise": 0.6 } },
  "master":   { "reverb": { "time": 3 }, "eq": { "high": { "gain": -2 } },
                "channels": { "2": { "low": { "gain": 4 } } } }
}
```

Only what differs from the defaults is in it. `examples/new-synthesis-bank.json`
is one, played by `examples/midi/new-synthesis.mid`.

## Quality and cost

The number of partials a voice may have (`--partials`, 48 by default) is
the main measure of quality and cost; the strongest are kept. Playing as
it renders, the synthesizer gives new notes fewer partials when the
machine cannot keep up, and more again when it can (`--fixed` turns that
off). Strings and FM cost less than 48 partials; a filter costs the Perl
engine half again what the partials do, the PDL engine some 15 %, the GPU
some 35 %.

### Wave sequences

A voice whose partials are harmonics (each copy of its unison harmonics of
its own fundamental) sounds the same read from tables of one period each
as from its partials turned one by one: a table wherever some partial has
moved 3 dB (its decay, its fade-in), crossfaded from one to the next, the
last held. Two tables read cost the same whatever the number of partials:
on the `perl` engine under pperl a voice of 48 partials in three copies
costs a third, on perl5 a fifth. A sequence is made once for what its
partials are (the patch, key, velocity, channel and budget made them) and
kept; every voice with those partials reads it, each from its own place in
the period, so that two alike are not one, louder. Measured against the
partials turned (`bin/peta-analyze`), every partial within 0.15 dB.

Not read so: stiff strings (`stretch`: their partials are no harmonics),
partials of a patch's own that are not harmonics (bells, mallets, tines),
and voices under a filter that moves (its gain changes partial by
partial). Strings, FM and noise are what they are either way.

The `perl` and `pdl` engines read wave sequences by default, the `gpu`
engine turns the partials (on the card they cost next to nothing; a
sequence's controls are worked out in Perl): `--waves`, `--no-waves`.
`play` makes the sequences a file needs before it plays (its notes
foreseen, see [rendering](rendering.md#the-cost-of-a-piece)), so that no
note waits for its; on a band piece of 169 s some 65, within the 2.2 s
the foreseeing takes.

## The fields

Every field of a patch, its range and its default (a patch of the
template's family changes some). Besides these: `partials` and `formants`
(lists, above), `mods` (the routes), and `drum` (set on the drum kit's
patches).

<!-- fields: made by devbin/doc-fields from Peta::Synth::Patch; not edited by hand -->

#### Spectrum

| field | range | default | |
|---|---|---|---|
| `slope` | 0 .. 10 | 1 | how fast the harmonics fall: amplitude k^-slope |
| `even` | 0 .. 2 | 1 | level of the even harmonics (low: hollow, clarinet-like; high: an octave reed or pipe) |
| `cutoff` | 100 .. 16000 (log) | 8000 | soft low-pass on the harmonics (Hz) |
| `rolloff` | 0 .. 3 (whole) | 0 | the low-pass steeper: 12 dB an octave more for each |
| `track` | 0 .. 1 | 0.5 | how much the cutoff follows the key |
| `bright` | 0 .. 3 | 1 | how much velocity opens the cutoff |
| `pluck` | 0 .. 0.5 | 0 | pluck or strike position: harmonics with a node there are weak |
| `stretch` | 0 .. 0.002 | 0 | inharmonicity: upper partials stretched sharp (piano strings) |
| `stretch_key` | 0 .. 3 | 0 | the stiffness grows with the key: B doubles every 12 / stretch_key semitones up |
| `max` | 1 .. 256 (log) | 256 | harmonics at most |

#### Partials over time

| field | range | default | |
|---|---|---|---|
| `decay` | 0 .. 100 (log) | 0 | decay of the fundamental (1/s); 0 sustains |
| `decay_k` | 0 .. 2 | 0 | upper partials decay this much faster, per partial |
| `decay_key` | 0 .. 2 | 0 | higher keys decay faster |
| `decay_k_key` | 0 .. 3 | 0 | decay_k grows with the key: the upper partials die sooner in the treble |
| `attack_k` | 0 .. 0.05 | 0 | upper partials come in later (s per partial) |

#### Envelope

| field | range | default | |
|---|---|---|---|
| `attack` | 0.0005 .. 4 (log) | 0.005 | attack time (s) |
| `hold` | 0 .. 2 | 0 | time at full level (s) |
| `fall` | 0.01 .. 10 (log) | 1 | decay time constant towards sustain (s) |
| `sustain` | 0 .. 1 | 1 | sustain level |
| `release` | 0.005 .. 5 (log) | 0.2 | release time constant (s) |
| `level` | 0 .. 5 | 1 | level |
| `velocity` | 0 .. 3 | 1.6 | velocity sensitivity: loudness (velocity/127)^this |

#### Pitch and modulation

| field | range | default | |
|---|---|---|---|
| `transpose` | -48 .. 48 (whole) | 0 | semitones |
| `fixed` | 0 .. 8000 | 0 | a fixed pitch in Hz, whatever the key (0: off) |
| `sweep` | -1 .. 4 | 0 | the pitch starts this much higher (ratio - 1) ... |
| `sweep_time` | 0.001 .. 1 (log) | 0.05 | ... and falls back with this time constant (s) |
| `vibrato` | 0 .. 400 (log) | 0 | vibrato depth (cents) |
| `vib_rate` | 0.1 .. 20 (log) | 5.5 | vibrato rate (Hz) |
| `vib_delay` | 0 .. 2 | 0.3 | vibrato fades in after (s) |
| `tremolo` | 0 .. 1 | 0 | tremolo depth |
| `trem_rate` | 0.1 .. 100 (log) | 5 | tremolo rate (Hz) |
| `length` | 0 .. 10 | 0 | a drum rings this long at most (s) |

#### Unison

| field | range | default | |
|---|---|---|---|
| `unison` | 1 .. 5 (whole) | 1 | detuned copies of the partials |
| `detune` | 0 .. 50 | 0 | cents between the outermost copies |
| `unison_k` | 1 .. 64 (whole) | 8 | partials each copy carries |
| `unison_sync` | 0 .. 1 (whole) | 0 | 1: the copies begin in phase, as strings struck by one hammer (0: each its own) |

#### Noise

| field | range | default | |
|---|---|---|---|
| `noise` | 0 .. 2 | 0 | noise level |
| `noise_center` | 20 .. 20000 (log) | 3000 | noise band centre (Hz) |
| `noise_ratio` | 0 .. 16 | 0 | noise band centre as a multiple of the pitch (0: use Hz) |
| `noise_q` | 0.1 .. 10 (log) | 1 | noise band narrowness (Q) |
| `noise_attack` | 0.0005 .. 4 (log) | 0.001 | noise attack (s) |
| `noise_decay` | 0 .. 200 | 30 | noise decay (1/s) |
| `noise_sustain` | 0 .. 1 | 0 | noise level left after the decay |
| `noise_mode` | band, high, low | band | band-, high- or low-pass |
| `noise_poles` | 2, 4 | 2 | the filter: 2 poles, or 4 for twice as steep |
| `noise_grains` | 0 .. 2000 (log) | 0 | bursts a second at random moments (applause, rain); 0: steady |
| `noise_grain_decay` | 10 .. 1000 (log) | 150 | how fast a burst falls (1/s) |
| `rough` | 0 .. 1 | 0 | noise on the partials: how much it moves their amplitude |
| `rough_rate` | 5 .. 5000 (log) | 200 | noise on the partials: how fast it moves (Hz) |

#### Noise, second band

| field | range | default | |
|---|---|---|---|
| `noise2` | 0 .. 2 | 0 | band 2: level |
| `noise2_center` | 20 .. 20000 (log) | 3000 | band 2: centre (Hz) |
| `noise2_ratio` | 0 .. 16 | 0 | band 2: centre as a multiple of the pitch (0: use Hz) |
| `noise2_q` | 0.1 .. 10 (log) | 1 | band 2: narrowness (Q) |
| `noise2_attack` | 0.0005 .. 4 (log) | 0.001 | band 2: attack (s) |
| `noise2_decay` | 0 .. 200 | 30 | band 2: decay (1/s) |
| `noise2_sustain` | 0 .. 1 | 0 | band 2: level left after the decay |
| `noise2_mode` | band, high, low | band | band 2: band-, high- or low-pass |
| `noise2_poles` | 2, 4 | 2 | band 2: the filter's poles |
| `noise2_grains` | 0 .. 2000 (log) | 0 | band 2: bursts a second; 0: steady |
| `noise2_grain_decay` | 10 .. 1000 (log) | 150 | band 2: how fast a burst falls (1/s) |

#### Noise, third band

| field | range | default | |
|---|---|---|---|
| `noise3` | 0 .. 2 | 0 | band 3: level |
| `noise3_center` | 20 .. 20000 (log) | 3000 | band 3: centre (Hz) |
| `noise3_ratio` | 0 .. 16 | 0 | band 3: centre as a multiple of the pitch (0: use Hz) |
| `noise3_q` | 0.1 .. 10 (log) | 1 | band 3: narrowness (Q) |
| `noise3_attack` | 0.0005 .. 4 (log) | 0.001 | band 3: attack (s) |
| `noise3_decay` | 0 .. 200 | 30 | band 3: decay (1/s) |
| `noise3_sustain` | 0 .. 1 | 0 | band 3: level left after the decay |
| `noise3_mode` | band, high, low | band | band 3: band-, high- or low-pass |
| `noise3_poles` | 2, 4 | 2 | band 3: the filter's poles |
| `noise3_grains` | 0 .. 2000 (log) | 0 | band 3: bursts a second; 0: steady |
| `noise3_grain_decay` | 10 .. 1000 (log) | 150 | band 3: how fast a burst falls (1/s) |

#### String (plucked or struck)

| field | range | default | |
|---|---|---|---|
| `string` | 0 .. 2 | 0 | a string (Karplus-Strong), plucked or struck: its level |
| `string_decay` | 0.05 .. 30 (log) | 4 | seconds it falls 60 dB in, at middle C |
| `string_key` | 0 .. 2 | 0.5 | higher keys decay faster |
| `string_damp` | 0 .. 0.95 | 0.3 | damping in the loop: the highs die sooner |
| `string_pick` | 0 .. 0.5 | 0.13 | where along the string it is plucked or struck |
| `string_bright` | 0.01 .. 1 (log) | 0.5 | how bright the pluck is (struck: how hard the hammer is) |
| `string_vel` | 0 .. 3 | 1 | how much velocity brightens the pluck |
| `string_noise` | 0 .. 1 | 0.25 | how much of the pluck is noise (the rest the plucked string's shape) |
| `string_excite` | pluck, strike | pluck | plucked, or struck by a hammer (string_bright: how hard it is) |
| `string_stiff` | 0 .. 0.002 | 0 | stiffness: upper harmonics sharp, as stretch has the partials (piano strings) |

#### FM

| field | range | default | |
|---|---|---|---|
| `fm` | 0 .. 2 | 0 | FM (four operators): its level |
| `fm_alg` | 1 .. 8 (whole) | 1 | the algorithm: 1 4>3>2>1; 2 (4+3)>2>1; 3 (4+(3>2))>1; 4 ((4>3)+2)>1; 5 4>3, 2>1; 6 4>3,2,1; 7 4>3, 2, 1; 8 all four |
| `fm_fb` | 0 .. 1 | 0 | operator 4 modulating itself (feedback) |

#### FM operator 1

| field | range | default | |
|---|---|---|---|
| `op1_ratio` | 0.25 .. 32 (log) | 1 | operator 1: frequency, times the note's |
| `op1_detune` | -50 .. 50 | 0 | operator 1: detune (cents) |
| `op1_level` | 0 .. 10 | 1 | operator 1: amplitude as a carrier, index (radians) as a modulator |
| `op1_attack` | 0.0005 .. 4 (log) | 0.002 | operator 1: attack (s) |
| `op1_decay` | 0.005 .. 20 (log) | 1 | operator 1: decay time constant (s) |
| `op1_sustain` | 0 .. 1 | 1 | operator 1: sustain level |
| `op1_release` | 0.005 .. 10 (log) | 0.3 | operator 1: release time constant (s) |
| `op1_vel` | 0 .. 1 | 0.5 | operator 1: how much velocity moves its level |
| `op1_key` | -2 .. 2 | 0 | operator 1: higher keys, lower level (this power of the pitch) |

#### FM operator 2

| field | range | default | |
|---|---|---|---|
| `op2_ratio` | 0.25 .. 32 (log) | 1 | operator 2: frequency, times the note's |
| `op2_detune` | -50 .. 50 | 0 | operator 2: detune (cents) |
| `op2_level` | 0 .. 10 | 1 | operator 2: amplitude as a carrier, index (radians) as a modulator |
| `op2_attack` | 0.0005 .. 4 (log) | 0.002 | operator 2: attack (s) |
| `op2_decay` | 0.005 .. 20 (log) | 1 | operator 2: decay time constant (s) |
| `op2_sustain` | 0 .. 1 | 1 | operator 2: sustain level |
| `op2_release` | 0.005 .. 10 (log) | 0.3 | operator 2: release time constant (s) |
| `op2_vel` | 0 .. 1 | 0.5 | operator 2: how much velocity moves its level |
| `op2_key` | -2 .. 2 | 0 | operator 2: higher keys, lower level (this power of the pitch) |

#### FM operator 3

| field | range | default | |
|---|---|---|---|
| `op3_ratio` | 0.25 .. 32 (log) | 1 | operator 3: frequency, times the note's |
| `op3_detune` | -50 .. 50 | 0 | operator 3: detune (cents) |
| `op3_level` | 0 .. 10 | 0 | operator 3: amplitude as a carrier, index (radians) as a modulator |
| `op3_attack` | 0.0005 .. 4 (log) | 0.002 | operator 3: attack (s) |
| `op3_decay` | 0.005 .. 20 (log) | 1 | operator 3: decay time constant (s) |
| `op3_sustain` | 0 .. 1 | 1 | operator 3: sustain level |
| `op3_release` | 0.005 .. 10 (log) | 0.3 | operator 3: release time constant (s) |
| `op3_vel` | 0 .. 1 | 0.5 | operator 3: how much velocity moves its level |
| `op3_key` | -2 .. 2 | 0 | operator 3: higher keys, lower level (this power of the pitch) |

#### FM operator 4

| field | range | default | |
|---|---|---|---|
| `op4_ratio` | 0.25 .. 32 (log) | 1 | operator 4: frequency, times the note's |
| `op4_detune` | -50 .. 50 | 0 | operator 4: detune (cents) |
| `op4_level` | 0 .. 10 | 0 | operator 4: amplitude as a carrier, index (radians) as a modulator |
| `op4_attack` | 0.0005 .. 4 (log) | 0.002 | operator 4: attack (s) |
| `op4_decay` | 0.005 .. 20 (log) | 1 | operator 4: decay time constant (s) |
| `op4_sustain` | 0 .. 1 | 1 | operator 4: sustain level |
| `op4_release` | 0.005 .. 10 (log) | 0.3 | operator 4: release time constant (s) |
| `op4_vel` | 0 .. 1 | 0.5 | operator 4: how much velocity moves its level |
| `op4_key` | -2 .. 2 | 0 | operator 4: higher keys, lower level (this power of the pitch) |

#### Filter

| field | range | default | |
|---|---|---|---|
| `filter` | off, lp12, lp24, hp12, hp24, bp | off | the filter: low-pass of 12 or 24 dB an octave, high-pass, band-pass |
| `filter_cutoff` | 20 .. 20000 (log) | 2000 | cutoff at middle C (Hz) |
| `filter_track` | 0 .. 1 | 1 | how much the cutoff follows the key |
| `filter_q` | 0.5 .. 20 (log) | 0.71 | resonance (Q) |
| `filter_env` | -8 .. 8 | 0 | octaves the second envelope moves the cutoff |
| `filter_vel` | -4 .. 4 | 0 | octaves velocity moves the cutoff |

#### Second envelope

| field | range | default | |
|---|---|---|---|
| `env2_attack` | 0.0005 .. 4 (log) | 0.01 | attack (s) |
| `env2_decay` | 0.005 .. 10 (log) | 0.3 | decay time constant (s) |
| `env2_sustain` | 0 .. 1 | 0 | sustain level |
| `env2_release` | 0.005 .. 10 (log) | 0.3 | release time constant (s) |

#### LFOs

| field | range | default | |
|---|---|---|---|
| `lfo1_rate` | 0.01 .. 50 (log) | 5 | first LFO: rate (Hz) |
| `lfo1_shape` | sine, triangle, square, saw, random | sine | first LFO: shape |
| `lfo1_delay` | 0 .. 5 | 0 | first LFO: fades in over (s) |
| `lfo2_rate` | 0.01 .. 50 (log) | 0.5 | second LFO: rate (Hz) |
| `lfo2_shape` | sine, triangle, square, saw, random | triangle | second LFO: shape |
| `lfo2_delay` | 0 .. 5 | 0 | second LFO: fades in over (s) |

<!-- end of fields -->
