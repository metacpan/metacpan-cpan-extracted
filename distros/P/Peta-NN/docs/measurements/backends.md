# The backends, measured

What the three engines are underneath, and what was measured with them.
How to use them, and that a model chooses for itself, is in
[Backends](../guides/backends.md).

A mini-batch goes through the network as one tensor. A backend owns the
tensors and implements about a dozen operations on whole batches (affine
map and its gradient, activations, embedding lookup, the two losses, the
two optimizer updates); `lib/Peta/NN/Backend.pm` lists them. Layers say
which operation, never how.

| backend | tensors are | notes |
|---|---|---|
| `plain` | flat Perl arrays | needs only perl; bit-identical on every perl; the reference the others are tested against |
| `pdl` | PDL ndarrays, double | the CPU workhorse; agrees with `plain` to rounding (1e-9 after 25 updates) |
| `gpu` | WebGPU storage buffers, 32-bit float | one compute shader per operation; agrees with `plain` to about six digits; pperl with the `webgpu` feature only |

The backend is chosen per network (`backend =>`), or with
`PETA_NN_BACKEND`. A saved network or model carries no backend and loads on
any.

**`auto` leaves the choice to the network**, which settles it when it is
trained, since only then is it known how much work there is: the size of the
model, the batch, the number of samples and epochs. It starts on `pdl` if
that loads, else on `plain`, and times a few steps there. If the whole run
would take two seconds or more, it times a few steps on every other backend
this perl and this machine have, and goes on where a step is fastest. Nothing
is assumed about which that is: plain Perl is seven times faster under
pperl's JIT than on perl5, PDL may not be installed, a graphics card may not
be there, and each of the three wins somewhere (a network of a few dozen
weights is fastest in plain Perl under the JIT; see "For a small model the
CPU is faster" below for PDL against the card). A backend that is hopeless
is not timed to the end: one small step shows it. A close second is timed
once more, because nothing is at its best the first time it runs: a JIT has
not compiled the loops yet, a card that sat idle is not up to speed. Without
PDL on pperl, the micro model of `bench/train.pl` (944 weights, batches of
16) stays in plain Perl, 0.42 ms a step under the JIT against 0.59 on the
card; with twice the weights, or with `--no-jit` (3.3 ms a step), it goes to
the card. What was timed leaves no
trace, the weights are put back; `$net->settled` says what was timed and
chosen, and a job's report says where each stage trained.

One thing `auto` costs: the card computes in 32-bit floats and the others in
64-bit, so the same seed gives weights that agree to about six digits, not
to the last bit, depending on where the run went. Whoever needs a run to be
repeatable exactly names the backend.

Training on PDL under pperl and under perl 5.42 gives the same models: with
the job as it was on 2026-10-06 the German noun example arrived at the same
three widths and the same fidelities to the last digit printed on both.

## The GPU

Measured 2026-10-06 on pperl 0.6.22 (a profile-guided build with the `webgpu`
feature), over Vulkan, on two machines. P50 is the baseline laptop
([Sizing](sizing.md)) with a Quadro M2000M; it was not idle; single runs.
P53 is a ThinkPad P53: Xeon E-2276M (6 cores / 12 threads), Quadro RTX 5000
with 16 GB (NVIDIA driver 610.43.02), a pperl built on that machine the same
day with PDL 2.104 in it, load about 1; two runs where a range is given.

Time per training step by network size, `bench/scale.pl` (two hidden layers):

| inputs-hidden-hidden-classes, batch | gpu, P50 | pdl, P50 | gpu, P53 | pdl, P53 |
|---|---|---|---|---|
| 24-24-24-8, 16 | 1.1 ms | 0.4 ms | 1.0 ms | 0.34-0.37 ms |
| 64-128-128-16, 64 | 1.5 ms | 4.4 ms | 1.0-1.2 ms | 3.4-3.7 ms |
| 256-512-512-32, 256 | 17 ms | 230 ms | 4.0-4.5 ms | 173-191 ms |
| 512-1024-1024-64, 512 | 130 ms | 1,930 ms | 31-38 ms | 1,450-1,510 ms |

A whole training run: the language identifier of `examples/langid.pl` with two
hidden layers, 96,000 words, four epochs:

| hidden width, batch | weights | gpu | pdl |
|---|---|---|---|
| 128, 64 | 36,500 | 13 s | 72 s |
| 512, 256 | 336,800 | 39 s | 456 s |
| 1024, 512 | 1,196,000 | 131 s | stopped after 21 minutes |

This is the P50 only: the lexica the example reads are not on the P53.

The GPU pays a fixed price per step, about a millisecond for its dozen
dispatches, and next to nothing per weight. So it loses on the smallest
models at small batches (944 weights, batch 16: 18,000 samples/s against
PDL's 40,000) and wins from a few ten thousand weights on, by a factor that
grows with the size: five at 36,500 weights, twelve at 336,800. `auto`
chooses it where a few timed steps say it is the faster.

The stronger card of the P53 takes the price per weight down by a factor of
four and leaves the fixed price where it is: a step of the smallest network
costs a millisecond on both machines, a step at 1.6 million weights 31-38 ms
against 130 ms. Against PDL on the same machine that is 43 times at 410,700
weights and 40 to 46 times at 1.6 million (P50: 14 and 15 times). The micro
model gains little: 22,300-24,200 samples/s (P50: 18,000) against PDL's
48,400-51,400.

**For a small model the CPU is faster, and where that turns.** A step on the
card costs about a millisecond whatever is in it (some twenty dispatches),
so the card does about a thousand steps a second at any size measured here;
what it trains per second is that times the batch. PDL's rate falls with the
size of the model instead. Training in steady state on the P53, an edit
model with one hidden layer on 20,000 words, samples per second:

| weights (hidden) | batch 16: PDL | GPU | batch 64: PDL | GPU | batch 128: PDL | GPU | batch 512: PDL | GPU |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 944 (24) | 56,000 | 17,200 | 123,300 | 65,400 | 160,400 | 123,400 | 229,900 | **306,000** |
| 2,168 (48) | 44,800 | 16,000 | 92,000 | 62,300 | 113,600 | **116,000** | 134,300 | **324,800** |
| 4,136 (96) | 35,900 | 15,700 | 48,200 | 39,500 | 54,500 | **86,300** | 60,500 | **226,600** |
| 9,736 (128) | 16,800 | 15,000 | 35,500 | **58,100** | 40,200 | **110,600** | 43,900 | **304,400** |
| 19,080 (256) | 14,800 | 14,500 | 20,700 | **57,200** | 22,800 | **104,700** | 24,400 | **386,300** |
| 37,768 (512) | 8,600 | **14,500** | 11,600 | **54,700** | 12,800 | **109,200** | 13,300 | **615,500** |

The card is ahead where its figure is bold. `auto` finds this line by timing, on the machine it runs on. The breaking
point moves with the batch: at batches of 16 the two meet at about 20,000 weights, at 64
between 4,000 and 10,000, at 128 at about 2,000, and at 512 the card is
ahead even for the smallest model. Below that line the card waits for its
orders most of the time, and PDL on one core is the faster engine: three
times at 944 weights and batches of 16. Above it the factor grows quickly:
16 times at 19,000 weights and batches of 512, 46 times at 38,000. (Small
batches are not a matter of taste for a small training set; a set of a few
thousand pairs wants many updates per epoch.)

The micro model's figure depends on whether the device is open when the
clock starts. `bench/train.pl` without arguments lists the backends first,
which opens it; that is how the figures here were taken. With the backend
named (`bench/train.pl gpu`) the device is opened inside the timed training,
and a run of half a second shows it: 11,100-14,900 samples/s on the P53,
10,800-11,100 on the P50. Opening loads the Vulkan driver and asks for an
adapter three times (two probes, then the device): 0.2 to 0.4 s on the P53,
0.8 s on the P50, once per process. With the device open and the pipelines
compiled, a second training in the same process runs at 23,000 samples/s on
the P53 and 16,500 on the P50, 0.69 and 0.97 ms a step.

For inference it has a floor of about a quarter of a millisecond per call
(`bench/infer.pl`: 0.24 ms for one decision at any size up to 27,000 weights,
PDL 0.05 to 0.07 ms). In batches of 256 it is ahead of PDL from 27,000
weights on (0.007 against 0.024 ms per decision) and seven times ahead at
1.6 million.

On the P53 the floor is the same, 0.23 ms a call, and it holds further up:
0.30 ms at 410,700 weights, where PDL takes as long, and 0.58 ms at 1.6
million against PDL's 1.1 ms. In batches of 256 the GPU is five times ahead
of PDL at 27,000 weights (0.004 against 0.020 ms per decision) and 28 times
at 1.6 million (0.036 against 1.0 ms).

The same pperl on the P53's integrated graphics (Intel UHD 630, Mesa) takes
2.4, 4.4, 40 and 306 ms for the four training steps of the table: behind PDL
up to 26,900 weights, four to five times ahead of it above. Its floor for one
decision is 0.7 ms.

### Training the German noun models, PDL against the GPU

Measured 2026-10-07 on the P53 (RTX 5000), pperl 0.6.22. One training run of
four epochs over 41,000 pairs, alone on the machine:

| hidden width | weights | pdl, batch 32 | gpu, batch 32 | pdl, batch 128 | gpu, batch 128 |
|---|---|---|---|---|---|
| 48 | 16,600 | 8.8 s | 6.1 s | 7.4 s | 2.5 s |
| 96 | 32,400 | 14.5 s | 6.0 s | 12.3 s | 2.4 s |
| 192 | 64,100 | 25.5 s | 5.9 s | 20.8 s | 2.4 s |
| 384 | 127,500 | 46.2 s | 5.8 s | 39.2 s | 2.5 s |

On the GPU the width costs nothing here and the batch size is the lever: a
step takes about 1.15 ms at 32 pairs and 1.9 ms at 128. Accuracy on unseen
nouns is the same either way, 96 to 97% after these four epochs.

Several such runs at once (width 96, batch 32), runs finished per minute:

| | alone | 2 at once | 4 at once | 6 at once |
|---|---|---|---|---|
| pdl | 4.1 | 7.5 | 13.3 | 18.9 |
| gpu | 10.0 | 13.3 | 14.1 | 15.0 |

PDL scales with the cores; the one card is far ahead alone, still ahead with
two processes, and saturates at about fifteen a minute.

The whole example, three jobs side by side with batches of 128, takes 4 min
52 s on PDL and 6 min 22 s on the GPU (the GPU run needed one stage more for
one model; a run of the same example the day before the teacher was mended
took 3 min 1 s on the GPU and 3 min 51 s on PDL). The card's advantage did
not show then, because a job spent most of an epoch not training but
checking: after every epoch it asked the model for some 15,000 answers
through the inference leg, on one core. That has changed since; see
[Keeping the card busy](#keeping-the-card-busy). With the code as it is now
the same example, four models side by side, takes two and a half minutes
on the card.

Neither CPU backend uses more than one core by itself; training runs can be
put on several cores as whole processes, see [Jobs](../blocks/jobs.md).

## Keeping the card busy

A card computes far faster than anything can be carried to it and back, so
what limits it is how often a training run crosses over. Training the
English class model of `examples/wordclass.pl` (102,000 words, 12 tokens
each, embedding 16, one hidden layer of 256, 106 labels), an epoch at first
looked like this: about a second of training on the card, then six seconds
of one CPU core checking the model through the inference leg, during which
the card did nothing. What changed that, in the order of what it brought:

- **The check of an epoch runs on the card.** A model that is trained there
  is measured there (`accuracy(..., where_trained => 1)`, which a job uses
  for watching), through a fused model of that one model: 18,000 words in
  0.45 s instead of 2.9 s. What a job records and decides by is still
  measured by the inference leg.
- **The samples stay on the card.** All token rows, classes and weights of a
  training run go up once, the order they are taken in once per epoch; a
  step picks its batch there, and the losses are read once per epoch. The
  weights that come out are the same to the last bit; an epoch takes 1.7
  times less (0.78 s to 0.45 s at batches of 512).
- **Batches the card has something of.** 512 instead of 128 halves an epoch
  and, at twice the learning rate, gets as far in the same number of epochs.
- **The shaders.** The weight gradient and the embedding gradient go through
  their inner loop four at a time (2 and 2 to 3 times faster), the forward
  product computes four outputs per invocation (1.2 times). Two things that
  looked right were slower: transposing first so that the inner loops read
  in a row, and gathering a whole row of the embedding table in one pass
  over the tokens, which is a sixteenth of the work and five times slower
  (a hundred long loops do not fill a card, sixteen hundred short ones do).

For comparison, an epoch of the same model on one core with PDL takes 18 s.
With all of this the four models of the example train in 4 minutes where
the first GPU run took 42.

What a step costs on the card at batches of 2,048, one operation at a time:
the three matrix products 0.4 to 1.3 ms each, the embedding gradient 1.0 ms,
handing a dispatch to the card 0.03 to 0.05 ms, making a buffer 0.03 ms.
Carrying a batch up took 1.4 ms and reading its loss 0.7 ms, which is what
keeping the samples on the card removes.

