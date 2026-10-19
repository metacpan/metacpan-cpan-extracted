# Rendering and playing

`peta-synth` renders MIDI files into sound files, plays them as it renders,
plays what keyboards send, and serves the web page. `peta-synth` with no
command lists the options; what follows says what they do. In Perl the
same is `Peta::Synth->render_file`, `play_file` and `play_live`.

It runs on pperl (`#!/usr/bin/env pperl`), which has the JIT and the GPU
engine; on perl5 it is `perl bin/peta-synth ...` (see
[backends](backends.md)).

## Commands

| Command | |
|---|---|
| `render IN.mid OUT` | a sound file, its format by the name: `.wav`, `.flac`, `.mp3`, `.ogg` (`.oga`), `.opus` |
| `play IN.mid` | to the sound server as it renders (PipeWire, PulseAudio) |
| `live` | to the sound server, what MIDI comes in as it is played |
| `serve` | the synthesizer behind a web page (http://127.0.0.1:8360/) |
| `info IN.mid` | what a file holds: its format, length, tempo, notes and programs by channel |
| `profile IN.mid` | what rendering it will cost, step by step, before it is rendered ([below](#the-cost-of-a-piece)) |
| `inputs` | the MIDI sources there are |
| `engines` | what this perl and machine have: the JIT, PDL, a GPU, the engines' speeds, the formats |

### Options

| | Commands | |
|---|---|---|
| `--rate N` | all | sample rate (48000) |
| `--partials N` | all | the most partials a voice has: quality and cost (48) |
| `--fidelity F` | render, play, live, serve | `low`, `mid`, `high`: what may be left out that is hardly heard, voices ending sooner as they fade, low at most 48 at once (render high; play, live, serve mid) |
| `--engine NAME` | all | `perl`, `pdl`, `gpu`, or `auto`: the fastest here, measured (auto) |
| `--bank FILE` | all | instrument changes, as the web page saves them ([synthesis](synthesis.md#patches-and-banks)) |
| `--length S` | render, play | only the file's first S seconds |
| `--workers N` | render | processes the notes are shared among (1) |
| `--bits N` | render | 16, 24 or 32 (32: float WAV) (16) |
| `--normalize DB` | render | the peak scaled to this many dBFS (-1); `off`: as rendered |
| `--quality Q` | render | by format, below |
| `--ffmpeg-gapless` | render | MP3: the Info tag names the encoder LavfPeta, so that FFmpeg reads the delay and plays the file gapless |
| `--quiet` | render, play, live | no progress |
| `--latency S` | play, live | seconds the sound server holds ahead (play 0.15, live 0.03) |
| `--output NAME` | play, live | `pipewire`, `pulse`, or `auto` ([backends](backends.md#sound-out)) |
| `--fixed` | play, live | keep the partials; do not lower them when the machine lags |
| `--in WHAT` | live, serve | the MIDI to play: `all`, `none`, sources by address or name, a path ([MIDI](midi.md)) |
| `--quantum N` | live, serve | samples rendered at a time, a multiple of 64 (live 256: 5.3 ms at 48 kHz; serve 512) |
| `--port N`, `--host ADDR` | serve | where it listens (8360, 127.0.0.1: this machine only) |
| `--midi DIR` | serve | where MIDI files are played from and dropped into (`examples/midi` in a checkout, else .) |

## Formats

All but Opus are written here, in Perl, with nothing else installed.

| Format | Written by | `--quality` | Rates | Bits |
|---|---|---|---|---|
| WAV | here | | any | 16 (dithered), 24, 32 float |
| FLAC | here (`Peta::Synth::Output::FLAC`) | level 0-8 (5) | any | 16 (dithered), 24 |
| MP3 | here (`Peta::MP3::Encode`) | kbit/s, constant (192; 96 at 16-24 kHz), or `V0`-`V9`, variable | 32, 44.1, 48 kHz (MPEG-1); 16, 22.05, 24 kHz (MPEG-2) | |
| Ogg Vorbis | here (`Peta::Vorbis::Encode`) | 0-10, variable (6) | any | |
| Opus | `ffmpeg`, when it is installed (fed WAV through a pipe) | kbit/s (160) | as ffmpeg takes them | |

**WAV**: 16 bits with triangular dither of one step, from a fixed stream
(the same file every time); 24-bit integers; 32-bit floats.

**FLAC**: blocks of 4096 samples. Each channel predicted by the better of
the fixed polynomial predictors (orders 0 to 4) and a linear predictor of
up to order 12 (the block windowed, Levinson-Durbin, the order whose bits
are fewest as libFLAC estimates them, the coefficients quantized with the
error carried on); stereo coded as left/right, left/side, right/side or
mid/side, whichever is smallest; residuals Rice coded in partitions, each
its own parameter. The levels choose how many windows are tried (six at
level 8, as `flac -8`; all four stereo codings coded and the smallest
kept). Within 0.1 % of `flac -5` and 0.4 % of `flac -8`. The MD5 of the
samples is in STREAMINFO, so `flac -t` verifies a file.

**MP3**: MPEG-1 Layer III, and MPEG-2's at the lower rates.

- the polyphase filterbank and the MDCT (in Perl, or in PDL where it is
  installed)
- a psychoacoustic model on each granule's own lines: each band's energy
  spread over its neighbours (Schroeder's spreading on the Bark scale),
  the noise allowed below it by the band's tonality (its spectral
  flatness), never below the threshold in quiet
- short blocks around attacks, with start and stop windows
- the quantizer: a step per band within its allowed noise, scalefactors
  (with preflag and, between granules, scfsi), the global gain fitted to
  the bits, Huffman coding with the best region split
- the bit reservoir, joint stereo (mid/side where the channels are alike)
- constant bitrate, or variable as LAME's `-V`: each frame the smallest
  bitrate that holds it, the levels calibrated to come out near LAME's
  bitrates for the same `-V`; a Xing header with its seek table
- an Info tag with the LAME extension, for gapless playback: players
  that read it (mpg123, foobar2000, ...) give exactly the samples
  encoded; FFmpeg reads the delay only from encoders it knows by name
  (`--ffmpeg-gapless`)

**Ogg Vorbis**:

- blocks of 2048 samples, or 256 around attacks (so their noise does not
  spread before them), the MDCT in Perl or PDL
- floor 1 (straight lines in decibels between some 32 points, under what
  the model allows)
- the residue in partitions of 16 bins, each of a class by its largest
  value, cascades of books for large ones
- the two channels coupled by Vorbis' square polar mapping, without loss
- variable bitrate by quality: how far below the masking the noise goes,
  the masking judged by each band's tonality
- its own codebooks, their code lengths trained on the synthesizer's
  sound (`devbin/vorbis-train`)

The tests check the files with the reference decoders where they are
installed: `flac -t` finds every FLAC level sound (its CRCs and MD5);
mpg123 gives back exactly as many samples as an MP3 was made of (constant
and variable bitrate, MPEG-1 and MPEG-2); FFmpeg decodes the Ogg Vorbis files.

## A render

- The file's events are scheduled; the synthesizer renders quanta of 1024
  samples until the last event, then until the voices and the reverb's
  tail have died away (at most 30 s more).
- **Normalizing**: the peak is found and the whole scaled to -1 dBFS (or
  `--normalize DB`). A render has no limiter; with `--normalize off` it is
  written as it came out, at the master gain (0.3), clipped where it goes
  past full scale.
- **Workers** (`--workers N`): the notes are shared among N processes by
  their number, each renders its share with its own reverb into a file of
  floats, and the parts are added. The synthesizer is linear but for the
  limiter (which a render leaves out), so the sum is the whole. It helps
  most on perl5 and with the `perl` and `pdl` engines; GPU processes
  share one card.
- `--length S` cuts the file at S seconds: what still sounds there is let
  go and rings out.

## Playing as it renders

`play` first makes the wave sequences the file's notes read
([synthesis](synthesis.md#wave-sequences)), so that no note waits for
its. `play` and `live` render quantum after quantum and write each to the
sound server, which paces them: `play` 1024 samples at a time, 0.15 s ahead;
`live` 256 samples (`--quantum`), 0.03 s ahead, each quantum's MIDI applied
before it is rendered. The status line shows the voices, the partials and
the load: the time a quantum takes to render against the time it lasts.
When the load passes 75 %, new notes get fewer partials; under 35 %, more
again, up to `--partials` (`--fixed` keeps them). The fidelity (`mid` by
default) ends voices sooner as they fade: on the Perl engine the
petasynth demo's busiest stretch takes 90 % of real time at `high`, 77 % at
`mid`, 64 % at `low`; on the GPU engine, where a quantum costs more than a
voice, little less. The limiter looks a block (64 samples) ahead: what
plays comes that much later, and no sample goes over full scale.

## The cost of a piece

`profile` says, before a piece is rendered, what each stretch of it will
cost: the synthesizer runs the file's events as rendering does, without
rendering, and each voice says when it will fall silent (its envelope,
let go or held by the pedal, and its partials' decay). The engine's costs
are measured on the spot (a quantum, a voice, a partial; each program and
drum the piece plays), and from them the load of each step: the seconds of
rendering a second of sound takes, 1 being just real time.

```sh
peta-synth profile song.mid                     # every 5 s
peta-synth profile song.mid --step 10 --measure # and what rendering it took
```

On a band piece of 169 s (4143 voices, foreseen in 2.6 s on pperl)
the load foreseen was within some 10 % of the one measured, step by step,
and 7 % under it in all. It says where a piece will not keep up with real
time (there from about 1:00, at most twice real time), and which notes it
plays (139 different programs, keys and velocities; 47 of them sound for
80 % of the time): what is worth preparing before it plays.

## The web page

`serve` renders for the browser: the sound goes to the page over a
WebSocket and the page plays it (an AudioWorklet), its clock pacing the
rendering. What the page sets up is described in the
[README](../README.md#the-web-page); `--in` adds MIDI as it is played to
the page's own. The server is Mojolicious's, on EV where there is EV; it
renders a quantum (512 samples, `--quantum`) at a time, keeping each
listener 0.12 s ahead of what it has played.
