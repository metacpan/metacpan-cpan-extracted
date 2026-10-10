# Perls compared

Measured 2026-10-06 on the baseline laptop of [Sizing](sizing.md), a
ThinkPad P50, which was not idle; ratios below 1.3 are noise. pperl is 0.6.22, a profile-guided
build; perl 5.42.2 is the system perl, built with threads and with PDL
2.103; perl 5.44.0 is a perlbrew build without threads and without PDL, so
it has the plain backend only.

Each table is followed by the same measurement on the P53 (the machine of
[the backends, measured](backends.md#the-gpu)), taken the same day with the
pperl built there. On that machine perl
5.42.2 is the system perl with threads and PDL 2.106, perl 5.44.0 the same
kind of perlbrew build as on the P50, and the GPU is the Quadro RTX 5000.

Training a micro model, `bench/train.pl` (2000 words, 4 epochs, batch 16,
944 weights), samples per second, three runs each:

| | plain | pdl | gpu |
|---|---|---|---|
| pperl | 25,100-26,100 | 36,100-41,200 | 17,600-18,000 |
| pperl `--no-jit` | 4,560-4,690 | 36,300-41,700 | 17,600-18,900 |
| perl 5.44 | 4,530-4,590 | not installed | none |
| perl 5.42 | 3,450-3,770 | 30,700-32,100 | none |

| P53 | plain | pdl | gpu |
|---|---|---|---|
| pperl | 31,400-32,000 | 48,400-51,400 | 22,300-24,200 |
| pperl `--no-jit` | 5,730-5,840 | 49,400-51,700 | 22,400-24,400 |
| perl 5.44 | 5,230-5,430 | not installed | none |
| perl 5.42 | 4,420-4,570 | 38,600-40,100 | none |

The P53 table is of 2026-10-08, with pperl 0.6.22 (`618fdde5c8`) and the GPU
backend as it is now; the P50 table above it is older and has not been taken
again. PDL is ahead of the card here because this is the smallest model at
the smallest batch: see "For a small model the CPU is faster" in
[the backends, measured](backends.md#the-gpu).

Inference in plain Perl, `bench/infer.pl`, milliseconds per decision for one
input at a time, by network size (two hidden layers):

| weights | pperl | pperl `--no-jit` | perl 5.44 | perl 5.42 | PDL, pperl | PDL, perl 5.42 |
|---|---|---|---|---|---|---|
| 1,400 | 0.028 | 0.13 | 0.13 | 0.18 | 0.042 | 0.060 |
| 26,900 | 0.30 | 2.0 | 2.0 | 2.8 | 0.066 | 0.096 |
| 410,700 | 4.0 | 29 | 30 | 44 | 0.39 | 0.41 |
| 1,640,500 | 17 | 116 | 120 | 162 | 1.4 | 1.5 |

| weights, P53 | pperl | pperl `--no-jit` | perl 5.44 | perl 5.42 | PDL, pperl | PDL, perl 5.42 |
|---|---|---|---|---|---|---|
| 1,400 | 0.025 | 0.11 | 0.11 | 0.14 | 0.036 | 0.047 |
| 26,900 | 0.25 | 1.7 | 1.7 | 2.2 | 0.056 | 0.070 |
| 410,700 | 3.7 | 25 | 26 | 33 | 0.30 | 0.34 |
| 1,640,500 | 14 | 100 | 99 | 133 | 1.1 | 1.1 |

The test suite of the distribution, and the German noun example as it was on
2026-10-06, before its jobs were rebuilt, with four workers (both train on PDL
where the perl has it):

| | test suite | tests run | German nouns, 4 workers |
|---|---|---|---|
| pperl | 41 s | 436 | 356 s |
| pperl `--no-jit` | 89 s | 436 | not run |
| perl 5.42 | 99 s | 404 | 410 s |
| perl 5.44 | 105 s | 359 | not run: no PDL |

| P53 | test suite | tests run | German nouns, 4 workers |
|---|---|---|---|
| pperl | 36 s | 436 | 219 s |
| pperl `--no-jit` | 74 s | 436 | not run |
| perl 5.42 | 83 s | 404 | 237 s |
| perl 5.44 | 93 s | 359 | not run: no PDL |

The suites are not the same work: pperl also tests the GPU backend, and the
perl without PDL and Parallel::ForkManager skips what needs them.

What the tables say:

- **In plain Perl the JIT is worth a factor of five to seven**: pperl against
  its own interpreter, and against perl 5.44. The interpreter alone is level
  with perl 5.44.
- **perl 5.44 here is a quarter faster than perl 5.42**, but the two are
  different builds (threads cost), so this is not a comparison of versions.
- **On PDL the perl hardly matters**: the arithmetic is PDL's. pperl is ahead
  by what its faster Perl saves around it, about a fifth on a micro model and
  an eighth on the German example.
- **Plain pperl is the fastest way to run a nano model once**: 0.028 ms a
  decision at 1,400 weights, ahead of PDL on either perl.
- **The P53 changes the numbers, not the picture**: on the CPU it is 1.1 to
  1.4 times the P50 for every perl and backend, the German example with four
  workers 1.6 to 1.7 times, and the JIT is worth a factor of four to seven
  there too.

