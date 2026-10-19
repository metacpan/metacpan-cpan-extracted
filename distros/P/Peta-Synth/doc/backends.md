# Backends

What renders the voices (engines), where the sound goes as it plays, where
MIDI comes from as it is played; and what each perl brings.

## Engines

An engine turns the voices of a quantum into samples: left, right and the
reverb's send. All three compute the same voice model (partials, filter,
noise bands, noise on the partials, strings plucked or struck, FM) and
give the same sound: PDL to rounding in double precision, the GPU to what
32-bit floats hold (the tests hold it within 2e-4 of the peak, -74 dB;
FM with feedback drifts most, the rest stays within 2e-5).

| Engine | How | Needs |
|---|---|---|
| `perl` | plain Perl; each partial a rotating phasor (four multiplications a sample, no `sin`); the loops written for pperl's JIT | any perl |
| `pdl` | PDL: the partials of a group of voices as whole-array operations; strings, FM and noise (recursions) as the Perl engine has them | PDL |
| `gpu` | WebGPU compute shaders through pperl's `Peta::WebGPU` (wgpu: Vulkan, Metal, DirectX): every partial of every voice of a quantum at once, the noise, strings and FM one invocation a voice, and the reverb on the card too | pperl, a graphics card |

`auto` (the default) measures the engines there are on a test chord (16
notes and 3 drums, 48 partials) when the synthesizer starts, and takes the
fastest; `peta-synth engines` shows the measurement. On a 12-core machine
with a Quadro RTX 5000, seconds of sound per second, 15 October 2026:

| | `perl` | `pdl` | `gpu` |
|---|---|---|---|
| perl 5.42 | 0.2 | 1.1 | |
| pperl | 1.6 | 2.1 | 11.5 |

A whole render is more than its engine: the events, each voice's controls
(its envelopes and modulation, block by block) and the mixing are Perl on
every engine, and the reverb is Perl on all but `gpu`; on a piece of a few
voices at a time they take as long as the voices. Strings and FM cost an
engine less than a voice of 48 partials; a filter costs the `perl` engine
half again. The `perl` and `pdl` engines read harmonic voices from wave
sequences, the `gpu` engine turns their partials
([wave sequences](synthesis.md#wave-sequences)): on a band piece of
169 s, under pperl, the `perl` engine renders in 186 s with them, 224 s
without.

The GPU engine runs every pass of a quantum in one batch: the partials'
amplitudes and phases at the blocks' edges (the filter's gain there), the
noise bands, the strings, FM, the voices' samples, the mix, the reverb.
The partials' phases are carried from quantum to quantum on the CPU in
double precision; the strings' delay lines go to the card and back each
quantum.

## Sound out

| Output | | Perl |
|---|---|---|
| `pipewire` | PipeWire through its own library (libpipewire-0.3, MIT licensed), called with pperl's `Peta::FFI`: a stream of 32-bit floats | pperl |
| `pulse` | the PulseAudio native protocol, spoken here over its socket (no library): PulseAudio, and PipeWire's pipewire-pulse | any perl |
| the browser | `serve`: the sound over a WebSocket, played by the page (an AudioWorklet); the browser's clock paces the rendering | any perl |
| files | WAV, FLAC, MP3, Ogg Vorbis written here, Opus through ffmpeg ([rendering](rendering.md#formats)) | any perl |

`--output auto` (the default) takes PipeWire where this perl can call
libpipewire, the PulseAudio protocol otherwise.

## MIDI in

| Input | | Perl |
|---|---|---|
| the ALSA sequencer | a client of the kernel's MIDI router, spoken to by `ioctl` and `read` on `/dev/snd/seq` (no library): one port, `MIDI in`, connected to every source and to those plugged in later (`--in all`), to sources by address or name (`--in 20:0`, `--in Keystation`, joined by commas), or to none (`--in none`: `aconnect` or a patchbay connects them). USB keyboards, MIDI interfaces, software keyboards and sequencers are its clients; PipeWire bridges its MIDI to it | any perl, Linux |
| raw devices, pipes | `--in /dev/snd/midiC1D0`, or a named pipe: the bytes read and parsed (running status, system exclusive, real-time bytes between) | any perl |
| Web MIDI | the page passes every message of the device chosen to the server; system exclusive where the browser allows it | any perl |
| files | Standard MIDI Files ([MIDI](midi.md)) | any perl |

`peta-synth inputs` lists the sequencer's sources and the raw devices.

The sequencer's client is `Peta::MIDI::ALSA`; on it, `Peta::MIDI::Device`
gives programs MIDI in and out as MIDI::RtMidi::FFI::Device does (ports by
number, name or pattern, virtual ports, messages as bytes or events,
callbacks in any AnyEvent loop, Coro's among them), with no library.

## What each perl brings

| | perl5 (5.36 or later) | pperl |
|---|---|---|
| rendering, every format, the web page, the PulseAudio protocol, the sequencer | yes | yes |
| the JIT (the `perl` engine some eight times faster) | | yes |
| the `pdl` engine | with PDL | with pperl's PDL |
| the `gpu` engine | | with a graphics card |
| PipeWire through libpipewire | | yes |

Besides Perl's core modules, only Mojolicious is needed (for the web page):
PDL is optional, ffmpeg only for Opus.

The script `bin/peta-synth` starts with `#!/usr/bin/env pperl`;
`perl bin/peta-synth ...` runs it on perl5. Installed, it runs on the perl
that installed it.

## Writing for pperl's JIT

The hot loops are written so that pperl compiles them (on the advice of
the pperl developers, and measured): arrays a loop stores into are filled
first with numbers of the type they will hold (`(0.0) x $n`), never grown
by the loop; each array holds one type; arrays are read by index; no
calls inside a hot loop (the `perl` engine's filter gains are written
out); no formatting, no bit operations, no list assignments inside them.
