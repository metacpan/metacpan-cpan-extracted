# MIDI

What Peta::Synth understands of MIDI: General MIDI, and what files and
players made for GM2, Roland's GS and Yamaha's XG use. The code is in
`Peta::Synth::Synth` (what the messages do), `Peta::Synth::MIDI` (files and
single messages), `Peta::Synth::MIDI::Stream` (a device's byte stream) and
`Peta::Synth::Input` (MIDI as it is played).

## Where MIDI comes from

| From | How |
|---|---|
| Standard MIDI Files | formats 0, 1 and 2 (a format 2 file's sequences one after another); running status; the tempo map; SMPTE time division. System exclusive in a file takes effect; meta events (text, key, time signature) are read and kept, and do nothing |
| The web page | its keyboard and the computer's keys; MIDI devices through the browser's Web MIDI, every message passed on (system exclusive where the browser allows it) |
| As it is played | `peta-synth live`, and `peta-synth serve --in`: a client of the ALSA sequencer, or a raw MIDI device or pipe (see [backends](backends.md#midi-in)) |

What is set by hand (on the page, or by MIDI played live) is held against
the file's MIDI on that channel: the instrument (bank select and program
change), volume, pan, the reverb and chorus sends, portamento time, the
sound controllers (CC70 .. 79) and each arpeggiator setting. While one is
held, the file's events for it are kept aside, the last of each, and a
reset from the file (GM, GS, XG) keeps it; let go (the page's *H* button, or
a held arpeggiator setting's chip), the setting is as the file has it by
then. What is played is not held: notes, the wheels, expression, pedals. A
reset played live lets go of everything; another file forgets what was held.

## Channels and notes

- Sixteen channels. Channel 10 is drums; so is a channel given bank 120 or
  127 (CC0, as GM2 and XG have it); bank 121 makes a channel melodic again.
  A GS or XG system exclusive message makes any part a drum part or a
  normal one.
- Program change picks one of the 128 General MIDI instruments, or, with
  a bank selected before it, one of their variations: the 30 of GS's
  banks 8, 9 and 16 that FluidR3 has (Detuned EP 1 and 2, Coupled
  Harpsichord, Church Bell, the detuned organs, Church Organ 2, Italian
  Accordion, Ukulele, 12 String Guitar, Mandolin, Hawaiian, Funk and
  Feedback Guitar, Guitar Feedback, Synth Bass 3 and 4, Slow Violin,
  Orchestral Pad, Synth Strings 3, Brass 2, Synth Brass 3 and 4, Sine
  Wave, Taisho Koto, Castanets, Concert Bass Drum, Melo Tom 2, 808 Tom,
  Burst Noise), by GS's bank or by GM2's (bank 121, CC32 the variation)
  where GM2's is the same sound. Other variations, and XG's, play their
  GM program, as GS and XG do with what they do not have.
- On a drum channel a program change picks the kit: Standard (0), Room
  (8), Power (16), Electronic (24), TR-808 (25), Jazz (32), Brush (40),
  Orchestra (48), as GS, GM2 and XG number them; another program the kit
  its group of eight begins with, or the standard kit. A kit's drums are
  its own where FluidR3's kit has its own (the TR-808's kicks, toms and
  hi-hats, the orchestra kit's timpani on keys 41 to 53, ...), the
  standard kit's elsewhere.
- Velocity sets the loudness (the patch's `velocity`: loudness is
  (velocity / 127) to that power) and, as the patch says, the brightness
  (`bright`, `filter_vel`, the FM operators' `vel`, the string's
  `string_vel`).
- Note-off velocity sets the release: 64 as the patch has it, 127 about
  0.7 times as long, 1 about 1.4 times. 0, as many files write, says
  nothing.
- Key pressure and channel pressure deepen the vibrato as the modulation
  wheel does (unless a [controller destination](#controller-destinations)
  says what they do), and are sources of modulation (`pressure`: the
  greater of the two).
- Drums ring for their length whether the key is held or not. The drum
  keys GM puts in exclusive classes cut each other off: closed, pedal and
  open hi-hat (42, 44, 46); short and long whistle (71, 72); short and long
  guiro (73, 74); mute and open cuica (78, 79); mute and open triangle
  (80, 81).
- At most 256 voices sound (the page can change it); past that, voices
  already let go are ended first, oldest first, then the oldest of the
  rest, each within 5 ms.

## Controllers

| CC | | What it does |
|---|---|---|
| 0 | bank select | 120, 127: drums; 121: melodic (GM2); otherwise GS's bank of variations; the next program change picks the variation |
| 32 | bank select LSB | with bank 121, GM2's variation |
| 1 | modulation wheel | deepens the vibrato (by the modulation depth range, RPN 5: 50 cents at full); a source of modulation (`wheel`) |
| 2 | breath | a source of modulation (`breath`) |
| 4 | foot | a source of modulation (`foot`) |
| 5 | portamento time | 0: none; 64 about 0.15 s; 127 about 10 s |
| 6, 38 | data entry | the RPN or NRPN chosen: MSB (clears the LSB), LSB |
| 7 | volume | the channel's level, (value / 127)² |
| 10 | pan | constant power |
| 11 | expression | a second level, (value / 127)² |
| 64 | sustain pedal | |
| 65 | portamento | on: each note glides from the last key, in CC5's time |
| 66 | sostenuto pedal | holds the notes held when it went down |
| 67 | soft pedal | notes that begin while it is down: 0.7 of the level, darker |
| 68 | legato pedal | mono legato while it is down (as CC126) |
| 70 | sound variation | read, does nothing |
| 71 | resonance | 64 as the patch has it: a filter's Q, live; without a filter the spectrum's peak at its cutoff, for new notes (twice the Q every 24 steps) |
| 72 | release time | for new notes: halved or doubled every 16 steps from 64 |
| 73 | attack time | the same |
| 74 | brightness | a filter's cutoff, live; without a filter the spectrum's cutoff, for new notes (an octave every 16 steps) |
| 75 | decay time | for new notes, as 72 |
| 76, 77, 78 | vibrato rate, depth, delay | live, as factors on the patch's vibrato |
| 80 | general purpose 5 | the channel's arpeggiator on (64 and up) or off |
| 81 | general purpose 6 | its latch |
| 84 | portamento control | the next note glides from this key, once |
| 91 | reverb send | |
| 93 | chorus | detuned copies of the partials, up to 24 cents further apart |
| 96, 97 | data increment, decrement | one step of the RPN or NRPN chosen (a cent where it counts cents, else a whole step) |
| 98, 99 | NRPN LSB, MSB | |
| 100, 101 | RPN LSB, MSB | 127, 127: none (data entry sets nothing) |
| 120 | all sound off | the channel's voices end within 5 ms |
| 121 | reset all controllers | modulation, breath, foot, pressure, bend, expression, sustain, sostenuto, soft pedal, portamento, the RPN/NRPN chosen; not volume, pan, sends, the sound controllers (GM2's list) |
| 123 | all notes off | let go, as by their keys |
| 124, 125 | omni off, on | all notes off |
| 126, 127 | mono, poly | all notes off, then mono or poly mode |

Sound controllers 71-78 and the GS/XG NRPNs that set the same things share
their values. CC 8, 12-31, 69 (hold 2), 92 (tremolo depth), 94, 95, 122
(local control) and the undefined ones are read and do nothing.

## Pitch

- **Pitch bend**, by the bend range (RPN 0; 2 semitones until set).
- **Tuning**: a channel's (RPN 1 fine, ±100 cents; RPN 2 coarse, ±64
  semitones) and the master's (universal system exclusive, fine and
  coarse; GS's key shift). They move every note that sounds.
- **Portamento**: a glide in the time CC5 gives, straight in pitch.
- **Mono mode** (CC126, or the legato pedal): one voice a channel. A key
  pressed while another is held takes over legato: a new voice of its own
  key starts without an attack (gliding from the old key where portamento
  is on) while the old one fades in 5 ms. Let go, the key held before it
  sounds again (the last key wins).

## RPN and NRPN

| | Parameter | |
|---|---|---|
| RPN 0, 0 | bend range | MSB semitones, LSB cents |
| RPN 0, 1 | fine tuning | 14 bits, ±100 cents |
| RPN 0, 2 | coarse tuning | MSB - 64 semitones |
| RPN 0, 5 | modulation depth range | MSB semitones, LSB in 128ths of 100 cents (50 cents until set) |
| RPN 127, 127 | none | |
| NRPN 1, 8 / 9 / 10 | vibrato rate, depth, delay (GS, XG) | as CC76, 77, 78 |
| NRPN 1, 32 / 33 | filter cutoff, resonance | as CC74, 71 |
| NRPN 1, 99 / 100 / 102 | attack, decay, release | as CC73, 75, 72 |
| NRPN 24, key | a drum key's pitch | MSB - 64 semitones |
| NRPN 25, key | its fine pitch | MSB - 64 cents |
| NRPN 26, key | its level | (MSB / 127)² |
| NRPN 28, key | its pan | added to the channel's |
| NRPN 29, key | its reverb send | times the channel's |
| NRPN 30, key | its chorus | times the channel's |
| NRPN 125, 0 .. 7 | the arpeggiator's settings | see [Arpeggiator](#steering-it-from-midi) |

## System exclusive

| Message | Bytes after F0 | |
|---|---|---|
| GM System On, GM2 On, GM Off | 7E dd 09 01 / 03 / 02 | every channel and the master to their defaults, the sounding notes let go |
| GS reset | 41 dd 42 12 40 00 7F 00 sum | the same |
| XG System On | 43 1n 4C 00 00 7E 00 | the same |
| master volume | 7F dd 04 01 lsb msb | |
| master balance | 7F dd 04 02 lsb msb | |
| master fine tuning | 7F dd 04 03 lsb msb | ±100 cents |
| master coarse tuning | 7F dd 04 04 lsb msb | msb - 64 semitones |
| controller destination | 7F dd 09 01 / 02 0c pp rr ...; 7F dd 09 03 0c cc pp rr ... | channel pressure, key pressure, controller cc of channel c: below |
| GS master volume, key shift | 41 dd 42 12 40 00 04 / 05 v sum | |
| GS rhythm part | 41 dd 42 12 40 1p 15 v sum | part p a drum part (v not 0) or not |
| XG master volume | 43 1n 4C 00 00 04 v | |
| XG part mode | 43 1n 4C 08 pp 07 v | part pp a drum part (v not 0) or not |

`dd` is any device number. A reset leaves the page's mutes and the
patches as they were.

### Controller destinations

GM2's controller destination setting routes a channel's pressure, its key
pressure or one of its controllers (1-31, 64-95) to the sound, on top of
what the patch's routes do. Each `pp rr` pair sets a parameter's range, the
effect at 127, in proportion below it:

| pp | | rr | Until set |
|---|---|---|---|
| 0 | pitch | 40-88: -24 .. +24 semitones (64: none) | 64 |
| 1 | the filter's cutoff | 0-127: (rr - 64) x 150 cents, -9600 .. +9450 | 64 |
| 2 | amplitude | 0-127: rr / 64 times, 0 .. 1.98 | 64 |
| 3 | the LFO's depth on pitch | 0-127: 0 .. 600 cents | 0 |
| 4 | the LFO's depth on the cutoff | 0-127: 0 .. 2400 cents | 0 |
| 5 | the LFO's depth on amplitude | 0-127: 0 .. 100 % | 0 |

- The LFO is the vibrato's: its rate and delay are the patch's, moved by
  CC76 and 78.
- Several sources add up (amplitude: they multiply). Key pressure moves
  the voice of its key alone.
- A source given destinations does what they say and no longer its
  default: the modulation wheel and the pressure stop deepening the
  vibrato.
- The cutoff moves the patch's filter. A patch without one gets, for the
  notes that begin while a destination moves the cutoff, a low-pass of
  12 dB an octave at half the sample rate, which cuts nothing until it
  is moved down. Like every filter here it acts on the partials, not on
  the string, FM or the noise bands.
- A reset (GM, GS, XG) clears the destinations; CC121 does not.

## Arpeggiator

Each channel has one, off until it is turned on (on the page, or in a
bank's `master` → `arps`). While it is on, the channel's keys are not
played as they come: they go to it, and it plays them one after another,
a note a step, at its tempo and rate (a quarter to a thirty-second, and
triplets), from the first key pressed; each note as long as its gate (a
share of the step), every second step later by its swing. Over more
octaves the keys are repeated an octave up, and again.

| pattern | the keys C E G, from C |
|---|---|
| up, down | C E G, G E C |
| updown, downup | C E G E, G E C E |
| played | in the order pressed |
| random | any of them, each step |
| chord | all of them, each step |
| converge, diverge | C G E (outer to middle), E G C |
| pedal_up, pedal_down | C E C G (back to the lowest between), G E G C |
| pedal_updown | C E C G E G C |

The patterns are those of Music::MelodicDevice::Arpeggiation (the module
the perl.com article *Adventures in Real-Time MIDI* arpeggiates with),
and besides downup, played and chord. Latched, the keys go on after they
are let go, until another chord is pressed. A drum channel's keys are not
arpeggiated. The first step waits 10 ms for the rest of a chord, and the
notes of each step are those of the keys held when it comes; a new
pattern (or number of octaves) begins from its start.

### Using it

- On the page: the selected channel's *arpeggiator* panel (on, latch, the
  pattern, rate, tempo, octaves, gate, swing); play the page's keyboard,
  the computer's keys or a MIDI keyboard on that channel.
- In a bank file (as the page saves it with *Save bank*), so that
  `render`, `play` and `live` arpeggiate too:

  ```json
  { "master": { "arps": { "0": { "on": 1, "mode": "updown", "rate": "1/16", "tempo": 120,
                                 "octaves": 2, "gate": 0.5, "swing": 0, "latch": 0 } } } }
  ```

- From MIDI, below: a file or a controller turns it on and sets it. The
  demo `examples/midi/arpeggiator.mid` does, through every kind of
  setting, in six styles (a music box, Bach's harmony, swung jazz,
  synthwave with a second arpeggiator and latched chords, Latin, a finale
  that slows into its last chord), its tempo changes followed (written
  by `devbin/demo-pieces`):

  ```sh
  peta-synth render examples/midi/arpeggiator.mid arpeggiator.ogg
  ```

### Steering it from MIDI

General MIDI has no controls for an arpeggiator; NRPNs are MIDI's place
for what a device has of its own. Its NRPN is 0x7D (125): CC99 = 125,
CC98 = the setting, then data entry, CC6 (and CC38 for the tempo's low
seven bits).

| CC98 | setting | CC6 |
|---|---|---|
| 0 | on | 64 and up: on |
| 1 | pattern | 0 up, 1 down, 2 updown, 3 downup, 4 random, 5 played, 6 chord, 7 converge, 8 diverge, 9 pedal_up, 10 pedal_down, 11 pedal_updown |
| 2 | rate | 0 1/4, 1 1/8, 2 1/8T, 3 1/16, 4 1/16T, 5 1/32 |
| 3 | tempo | beats a minute, 14 bits: CC6 × 128 + CC38 (30 .. 300) |
| 4 | octaves | 1 .. 4 |
| 5 | gate | 0 .. 127 of a step |
| 6 | swing | 0 .. 127 of half a step |
| 7 | latch | 64 and up: on |

Two general-purpose controllers switch it as a controller's buttons can:
CC80 on (64 and up) or off, CC81 latch. A MIDI file's tempo is the
arpeggiators' tempo until something else sets it.

## Not there

- the variations FluidR3 does not have, XG's, XG's SFX voices (bank 64; their
  program plays its GM sound) and the SFX kit
- the effects of GS and XG but reverb and chorus: XG's variation effect
  (distortion, delay, ...: its type, the parts' dry level and CC94
  sends), the GS and XG reverb and chorus types
- a drum key's filter and envelope (XG's NRPN 20, 21, 22, 23)
- MIDI out from the synthesizer (for programs, Peta::MIDI::Device::Out
  sends it), MIDI clock and song position, MPE, MIDI 2.0
