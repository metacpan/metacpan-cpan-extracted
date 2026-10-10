# Sizing: which sizes, for which tasks, on which backend

What a model of a given size costs, and what that makes practical. The
figures of the first sections are of 2026-10-04 and of the building blocks
of that day; they are kept as measured. Later measurements are in
[the backends, measured](backends.md).

Status: the measurements are facts. The budget for "practical" was agreed on
2026-10-04 as a starting point, to be raised or lowered once the first real
models exist. The size classes are still a proposal.

## Baseline machine

Everything here is measured on one laptop, and that laptop is the baseline:
if a model is practical here, it is practical. A ten-year-old machine: 4
cores / 8 threads (Skylake), 15 GB RAM, NVIDIA Quadro M2000M, CPU governor
`powersave`, never fully idle (load average 1 to 3 during the runs).

Software: pperl `20018a8b09` (features `native-max,pdl,webgpu`), perl 5.42.2
with PDL 2.104.

## What a size costs

A network's parameter count fixes three things: how large the shipped model
file is, how long one decision takes, and how long training takes. A *decision*
is one forward pass: one word for a vocative, but one **character** for
diacritics restoration, so a 60-character sentence is 60 decisions.

Shipped size: about four bytes per parameter when a model file packs its
weights as 32-bit floats (the default), about one with `export(bits => 8)`:
signed bytes and one scale per weight array. What the coarser weights cost in
accuracy is measured per model; the exporter does not judge it.

### Inference: milliseconds per decision

`bench/infer.pl`, two hidden layers, two runs each (both shown where they
differ). "one" is a single call; "batch" is 256 inputs at once, per input.

| network          | parameters |       | plain, perl5 | plain, pperl | PDL, perl5  | PDL, pperl  | GPU, pperl  |
|------------------|------------|-------|--------------|--------------|-------------|-------------|-------------|
| 24-24-24-8       | 1,400      | one   | 0.17-0.20    | 0.035        | 0.06-0.07   | 0.05        | 0.26-0.28   |
|                  |            | batch | 0.16-0.17    | 0.019        | 0.004-0.005 | 0.004-0.005 | 0.003-0.004 |
| 64-128-128-16    | 26,900     | one   | 2.7-3.1      | 0.33-0.34    | 0.10        | 0.07-0.08   | 0.26-0.28   |
|                  |            | batch | 2.8-3.0      | 0.35-0.36    | 0.03        | 0.03        | 0.009       |
| 256-512-512-32   | 410,700    | one   | 40-45        | 4.9-5.3      | 0.43-0.50   | 0.46-0.57   | 0.54        |
|                  |            | batch | 41-47        | 5.2-5.3      | 0.34-0.36   | 0.35-0.40   | 0.05        |
| 512-1024-1024-64 | 1,640,500  | one   | 160-260      | 19-20        | 1.5-1.9     | 1.8-2.0     | 1.3-1.4     |
|                  |            | batch | 160-170      | 22           | 1.2-1.3     | 1.4         | 0.15-0.18   |

What the table says:

- **Plain Perl costs about 110 ns per parameter on perl5 and about 12 on
  pperl**, batch or not. That factor of nine is the JIT.
- **PDL is the same on both perls**, about 1 ns per parameter, less in a
  batch for small networks.
- **The GPU has a floor of about 0.26 ms per call**, whatever the size
  (dispatch and read-back). Called once per decision it never beats PDL
  below about a million parameters. In a batch it is the fastest at every
  size above nano.
- These figures are the training leg's backends. The inference leg has
  its own forward pass; see the next table.

### Inference of a shipped model

What ships is a model file read by `Peta::NN::Inference`, so this is the
table that decides what is practical for a user. The inference leg uses PDL
when the perl running it has PDL, and plain Perl loops otherwise
(`PETA_NN_ENGINE=plain` forces them). A single model has no GPU path; models
fused into one have, for batches: see [Fused models](../blocks/fused.md).
`bench/inference.pl`, one run each, milliseconds per decision, one string at
a time / 256 at once. The timings were taken on 2026-10-04 when this code
was still generated into each model's own module; the code is the same, and
the file sizes are those of today's model files:

| network          | parameters | file   | plain, perl5 | plain, pperl | PDL, perl5   | PDL, pperl   |
|------------------|------------|--------|--------------|--------------|--------------|--------------|
| 24-24-24-8       | 1,600      | 7 kB   | 0.20 / 0.18  | 0.04 / 0.03  | 0.07 / 0.014 | 0.05 / 0.012 |
| 64-128-128-16    | 27,100     | 109 kB | 3.2 / 3.2    | 0.28 / 0.40  | 0.11 / 0.05  | 0.08 / 0.04  |
| 256-512-512-32   | 411,100    | 1.6 MB | 45 / 47      | 3.8 / 5.6    | 0.67 / 0.39  | 0.57 / 0.40  |
| 512-1024-1024-64 | 1,641,000  | 6.6 MB | 163 / 186    | 14 / 22      | 4.7 / 2.0    | 4.1 / 1.9    |

It tracks the backends closely, so the limits below hold for shipped models
as well.

### Training: milliseconds per step

`bench/scale.pl`, pperl `--no-jit` on the 02:34 build (before the JIT fix;
the plain column would now be several times faster and was not rerun):

| network, batch        | GPU     | PDL   | plain   |
|-----------------------|---------|-------|---------|
| 24-24-24-8, 16        | 0.9     | 0.4   | 5.3     |
| 64-128-128-16, 64     | 1.5-1.9 | 4.6   | not run |
| 256-512-512-32, 256   | 17      | 240   | not run |
| 512-1024-1024-64, 512 | 130     | 1,950 | not run |

## What is practical

"Practical" needs a budget. Agreed: **one decision in about a millisecond**,
so that a per-character task finishes a 60-character sentence in well under
a tenth of a second. Read off the inference table, the largest network that
stays within it on the baseline machine is roughly:

| engine                                    | practical up to (parameters)           |
|-------------------------------------------|----------------------------------------|
| plain Perl on perl5                       | 10,000                                 |
| plain Perl on pperl                       | 80,000                                 |
| PDL, either perl                          | 800,000                                |
| GPU, one call per decision (library only) | 1,200,000                              |
| GPU, batched (library only)               | beyond 1,600,000, the largest measured |

A task that makes one decision per input (vocative: one per name) can afford
a budget ten times looser, and limits ten times higher.

These limits are a snapshot. They move up with every optimisation below
them: a parallel matrix product in PDL, parallel loops in the JIT, a faster
inference leg.

## Proposal: size classes

| class | parameters          |
|-------|---------------------|
| nano  | under 10,000        |
| micro | 10,000 to 1,000,000 |
| small | 1 to 20 million     |

What each class is for (the tasks are judgement, not measured) and where its
inference is practical:

- **nano.** Ending-driven rules: vocative, plural, gender of a name.
  Practical everywhere, including plain perl5.
- **micro.** Diacritics restoration, full inflection paradigms,
  lemmatisation, language identification, part-of-speech tagging.
  Practical on plain pperl in the lower part of the range, and on PDL or
  GPU throughout.
- **small.** Character-by-character generation: number to words,
  transliteration. Practical on the GPU in batches, and on PDL for single
  decisions.

A 256-512-512-32 network (411,000 parameters, a 1.6 MB model file at 32
bits) is micro. Of the models trained so far only the language identifier of
`examples/langid.pl` is micro, at its lower end; all others are nano.

## Training budget

Agreed 2026-10-04: a training run of **about five minutes** on the baseline
machine is as acceptable as one of three seconds. Training time is therefore
not what limits model size; inference is.

What five minutes buys, from the per-step times above (one pass = one
training sample seen once; 20,000 pairs for 40 epochs are 800,000 passes):

| network          | parameters | GPU, passes in 5 min | PDL, passes in 5 min |
|------------------|------------|----------------------|----------------------|
| 64-128-128-16    | 26,900     | 11 million           | 4 million            |
| 256-512-512-32   | 410,700    | 4.5 million          | 320,000              |
| 512-1024-1024-64 | 1,640,500  | 1.2 million          | 79,000               |

So on the baseline GPU every micro model trains within the budget on tens
of thousands of pairs. On PDL alone the budget is comfortable up to about
100,000 parameters and tight at 400,000. The inference budget of a
millisecond per decision caps a shipped model at about 800,000 parameters
(PDL) well before training becomes the constraint.

For scale: the Czech adjective converter (29,500 parameters, 22,000 pairs,
40 epochs) trains in 110 s on PDL.

On the P53 (Quadro RTX 5000), with the samples of a training run kept on the
card and the model measured there after each epoch
([Keeping the card busy](backends.md#keeping-the-card-busy)), a class model of 174,000 parameters on 102,000 words takes
0.45 s per epoch on the GPU and 18 s on PDL; the three such models of
`examples/wordclass.pl` train side by side in about five minutes, each to
its thresholds and confirmed on a second seed.

## Open points

1. A ceiling for the size of a shipped model file. With 8-bit export the
   largest practical PDL model (800,000 parameters) is under a megabyte.

## A second machine: ThinkPad P53

Measured 2026-10-04 for comparison; the baseline above stays the baseline.
Xeon E-2276M (6 cores / 12 threads), 62 GB, Quadro RTX 5000 16 GB, governor
`powersave`, idle (load 0.1 to 1.0). Same pperl binary (`20018a8b09`), run
on a private copy of glibc 2.44 because the host has 2.43; perl 5.42.2
without PDL, so perl5 has only the plain column. Single runs unless a range
is given.

Inference, milliseconds per decision, one call / in a batch of 256
(`bench/infer.pl`):

| network          | parameters | plain, perl5 | plain, pperl  | PDL, pperl    | GPU, pperl   |
|------------------|------------|--------------|---------------|---------------|--------------|
| 24-24-24-8       | 1,400      | 0.13 / 0.12  | 0.026 / 0.013 | 0.030 / 0.003 | 0.27 / 0.002 |
| 64-128-128-16    | 26,900     | 2.0 / 2.0    | 0.24 / 0.23   | 0.05 / 0.02   | 0.28 / 0.004 |
| 256-512-512-32   | 410,700    | 30 / 30      | 3.2 / 3.5     | 0.30 / 0.26   | 0.75 / 0.021 |
| 512-1024-1024-64 | 1,640,500  | 118 / 117    | 13 / 15       | 1.2 / 1.1     | 2.6 / 0.085  |

The inference leg (then `bench/exported.pl`, now `bench/inference.pl`) gives the same picture: at 411,000
parameters 0.35 / 0.27 ms on PDL, 2.5 / 3.7 ms plain on pperl, 30 / 29 ms
plain on perl5.

Training, milliseconds per step (`bench/scale.pl`, pperl with the JIT):

| network, batch        | GPU | PDL   |
|-----------------------|-----|-------|
| 24-24-24-8, 16        | 1.0 | 0.33  |
| 64-128-128-16, 64     | 1.3 | 4.1   |
| 256-512-512-32, 256   | 4.3 | 181   |
| 512-1024-1024-64, 512 | 34  | 1,405 |

Micro-model training (`bench/train.pl`, 944 parameters, samples per second):
PDL 51,000-56,000; plain pperl 33,500-34,400; plain pperl `--no-jit` 5,700;
plain perl5 4,600; GPU 18,400-22,700.

Against the baseline laptop: the CPU paths are 1.3 to 1.6 times faster, the
GPU in batches 2 to 4 times. The GPU's per-call floor does not move (0.27 ms
on both), so single decisions gain nothing from the better card.
