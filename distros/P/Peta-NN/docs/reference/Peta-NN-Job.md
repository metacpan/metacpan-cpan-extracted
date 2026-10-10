# Peta::NN::Job

train a model until it meets given fidelity thresholds, at the smallest size that can

## Synopsis

```perl
use Peta::NN::Job;

my $job = Peta::NN::Job->new(
    model    => { kind => 'edit', side => 'both', window => 7 },
    pairs    => \@pairs,                          # [input, output, parameters...]
    group    => sub ($pair) { $lemma_of{ $pair->[0] } },
    always_train => sub ($pair) { $is_exception{ $pair->[0] } },
    subsets  => {
        exceptions    => { of => 'train', where => sub ($pair) { $is_exception{ $pair->[0] } } },
        'to positive' => { where => sub ($pair) { $pair->[2] eq 'positive' } },   # by a parameter
    },
    fidelity => { all => 0.96, exceptions => 1.00, 'to positive' => 0.85 },
    budget   => { ms => 1, seconds => 600 },
    search   => { scale => [8, 256], depth => [1, 2] },
);
my $model = $job->run;
print $job->report;
$model->export(...) if $job->result->{met};
```

## Description

`fidelity` names what must hold: `all` is the share of held-out pairs
answered exactly; any other name is a subset from `subsets`, measured on
the held-out part, or with `of => 'train'` on the training part (what
the model was shown and must retain).

A job trains one model until it meets them. Training watches the distance to
the thresholds and goes on for as long as the model gets closer. A model
that has stopped getting closer is first trained with more weight on what it
must retain and has not, and then given wider hidden layers, which changes
none of its answers, and trained on. It is not thrown away for a larger one.

`search` gives the `scale`, the smallest and the largest width; `start`,
the width to begin at, the smallest unless given; `grow`, the factor by
which a stuck model is widened (2); and the depths to try, the next one only
if the one before could not get there. `shape` turns the starting width
and a depth into a layer list; the default is an embedding and `depth`
hidden layers.

`train` is passed on to training. Its `epochs` is the most one stage trains
before the job looks at the model again, its `patience` the number of
epochs a model may go without getting closer before it counts as stuck.

`budget` limits the cost: `params`, `ms` (per item, timed on the inference
leg), `runs` (stages of training) and `seconds` (wall clock for the job).

`run` returns the model. If it met everything it is trained once more from
nothing on a second seed, at its size, to confirm; `result` says whether it
met and was confirmed, and carries the one measurement on the test part.

## Methods

### new

`model`, `pairs` and `fidelity` are required. `subsets`, `group`,
`always_train`, `split`, `shape`, `search`, `train`, `budget`, `seed`
and `backend` are optional.

### run

`run(progress => sub ($stage) { ... })`: trains, and returns the model:
the one that meets the thresholds, or the closest it got.

### result

What the run came to: `met`, `confirmed`, the model's size, cost and
fidelity, the fidelity on the test part, the number of stages and epochs and
the time.

### attempts

Every stage of training, in the order it was run: its name, the width, the
epochs it trained, the fidelity it reached, and how it ended.

### report

The stages and the outcome as text.

### part

`part('train')`, `part('validation')`, `part('test')`: the pairs of a
part of the split.

### contradictions

`[the pair, the output that was kept for its input]` for every pair that was
set aside because its input already had another answer.

### indistinct

`[pair, another answer, a pair that has it]` for every training pair the
model reads exactly as it reads a pair with a different answer. Such pairs
are not counted in what must be retained: no training can get them right
together, only a wider window.

## Functions

### default_shape

`default_shape($scale, $depth)`: the layers for a starting width and a
depth unless `shape` says otherwise.

---

From the POD of `lib/Peta/NN/Job.pm`; change it there.
