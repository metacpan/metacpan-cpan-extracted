# Backends

The arithmetic of training and of answering runs on one of three engines.

| Backend | What it is | Needs |
|---|---|---|
| `plain` | Perl arrays and loops; the reference the others are tested against | nothing |
| `pdl` | PDL ndarrays, in doubles | PDL |
| `gpu` | compute shaders on a graphics card, in 32-bit floats | pperl with WebGPU, and a card |

## You do not have to choose

Models trained through `train` choose for themselves. When a model is
trained, and only then, it is known how much work there is: the size of the
model, the batch, the number of records and passes. The model times a few
steps on the engine it stands on, and if the whole run would take two
seconds or more, on every other engine this perl and this machine have, and
goes on where a step is fastest.

Nothing is assumed about which that is, because it differs:

- Plain Perl is seven times faster under pperl's JIT than on perl5.
- PDL may not be installed. A graphics card may not be there.
- For a model of a few dozen weights plain Perl under the JIT is the fastest.
  For small models at small batches PDL is. For everything larger the card.

```perl
use v5.36;
use Peta::NN::Backend;
use Peta::NN::Data;
use Peta::NN::Model;

print 'here: ', join(', ', Peta::NN::Backend::available()), "\n";

my $nouns = Peta::NN::Data->read('examples/out/deu-noun/nouns.tsv', fields => [qw(singular gender plural listed)])->sample(4000)->hold_out(0.2);
my $model = Peta::NN::Model->new(kind => 'edit', from => 'singular', to => 'plural', given => ['gender'], reads => { end => 6 }, train => { epochs => 4 });
$model->train($nouns);

my $settled = $model->net->settled;
printf "trained on %s; a step took %s\n", $settled->{backend},
    join ', ', map { sprintf '%.2f ms on %s', 1000 * $settled->{seconds_per_step}{$_}, $_ } sort keys %{ $settled->{seconds_per_step} };
```

```text
here: gpu, pdl, plain
trained on pdl; a step took 0.67 ms on pdl
```

A job's report has a column `on` that says where each stage trained.

## Where the card overtakes the CPU

A training step on a card costs about a millisecond whatever is in it, so a
card does about a thousand steps a second at any size; what it trains per
second is that times the batch. PDL's rate falls with the size of the model
instead. On the machine these were measured on, the two meet

| at batches of | at about |
|---:|---|
| 16 | 20,000 weights |
| 64 | 4,000 to 10,000 weights |
| 128 | 2,000 weights |
| 512 | below 1,000 weights |

and above that line the card's lead grows quickly: 16 times at 19,000
weights and batches of 512, 46 times at 38,000. The tables are in
[the backends, measured](../measurements/backends.md). Large batches are
what a card is fast at; the word-class models of `examples/wordclass.pl`
train with batches of 512.

## Naming the backend

```perl
my $pinned = Peta::NN::Model->new(kind => 'edit', from => 'singular', to => 'plural', given => ['gender'], reads => { end => 6 }, train => { epochs => 1 });
$pinned->train($nouns, backend => 'plain');
print 'trained on ', $pinned->net->backend, "\n";
```

```text
trained on plain
```

`backend => 'plain'`, `'pdl'` or `'gpu'` in `train`, or `PETA_NN_BACKEND` in
the environment, names it. There is one reason to: the card computes in
32-bit floats and the others in 64-bit, so the same seed gives weights that
agree to about six digits, not to the last bit, depending on where a run
went. Whoever needs a run to be repeatable exactly names the backend. On the
`plain` backend the same seed gives bit-identical weights on perl5 and pperl.

## Answering

A single model answers on PDL where it is there and in plain Perl where not
(`PETA_NN_ENGINE=plain` forces the loops). A chain answers the same way, or
fused on the card after `on('gpu')`: see [Fusing](fusing.md).

## More than one core

Models that have nothing to do with each other are trained side by side, a
process each: `PETA_NN_WORKERS=4` says how many at a time. It needs
Parallel::ForkManager, and does nothing without it.
