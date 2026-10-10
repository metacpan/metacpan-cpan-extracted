# Jobs

The level under a goal. A model declared with `goal => { unseen => 0.98, core
=> 1 }` and trained with `train` ([Models](../guides/models.md)) is trained
by a job: `unseen` becomes the threshold `all`, and each mark of the data a
subset of the training part that is always trained on and has to be
retained. This page is the job itself: what it does, and how it is used
directly, on pairs.

`Peta::NN::Job` takes fidelity thresholds and a cost budget and trains a
model until it meets them:

```perl
my $job = Peta::NN::Job->new(
    model    => { kind => 'edit', side => 'both', window => 7 },
    pairs    => \@pairs,
    subsets  => { exceptions => { of => 'train', where => \&is_exception } },
    fidelity => { all => 0.95, exceptions => 1.00 },
    budget   => { ms => 1, seconds => 900 },
    search   => { scale => [ 16, 192 ], depth => [1] },
);
my $model = $job->run;
print $job->report;
```

A job trains ONE model until it has got there. It does not run from a model
that falls short to another one.

- **Train until the thresholds are met**, for as long as the model keeps
  getting closer to them. What is watched is the distance to the thresholds,
  not the loss: a model that still has three of its exceptions to learn is
  not done because its loss has gone flat. The weights kept are those of the
  epoch that was closest.
- **Train on gently.** A model that is trained further gets a third of the
  learning rate. At the full rate it first unlearns: a model with 5 of 2,557
  head nouns wrong had 27 wrong three epochs later and needed fifteen to be
  back; at a third of the rate, and with weight on those nouns, it had none
  wrong after nine and stayed there.
- **More weight on what must be retained** and is not, when the model has
  stopped getting closer: thirty times, once per subset.
- **Wider, when it is stuck all the same.** `Peta::NN::Model`'s `widen` gives
  a trained model wider hidden layers without changing one of its answers (a
  new unit reads with random weights and is read with zeros), and the model
  trains on with what it knows. The job starts at the smallest width of its
  scale, or at `start`, and widens by `grow`.
- **What no training can reach is not asked for**, and is reported: pairs the
  model reads exactly as it reads another pair with a different answer,
  because they differ only outside its window (`indistinct`). For the German
  nouns these turned out to be faults of the teacher as often as limits of
  the model: `appartement` and `departement` had been given different plurals.
- **Three-way split** by group (all forms of a word together): thresholds
  are checked on the validation part, the test part is measured once.
- **Fidelity is a set of named thresholds** over named subsets, including
  subsets that exist only in training and must be retained.
- **Contradictory pairs** (one input, two answers) are set aside and listed.
- **A second seed has to get there too**, from nothing and from the size the
  first reached; cost is timed on the inference leg.

The thresholds are what "good" means, and the starting width matters. Started
at 16 hidden units, the German models met lax thresholds as small models that
had been pushed hard to learn their core nouns, and were right on 96.3% of
unseen nouns. Started at 64, each met stricter thresholds in one stage of 18
to 26 epochs, with no extra weight and no widening, and they are right on
98.4%.

The report has one line per stage: the width, the weights, the epochs, the
backend the stage trained `on`, the cost per answer, what was reached for
every threshold, and how the stage ended.

Jobs that have nothing to do with each other run side by side, a process
each (`Peta::NN::Parallel`, on Parallel::ForkManager; `PETA_NN_WORKERS` says
how many at a time): the models of the German example, the 108 models of
the Czech grammar (51 s four at a time and 113 s one at a time on the P50;
87 s four at a time on the P53 with the code as it is now).

Underneath, training has validation with early stopping (`validate`,
`patience`), weight decay (`weight_decay`) and per-pair weights, on every
backend. Not built yet: shrinking by pruning, and mining for words where
model and teacher disagree.

For Czech adjectives (`examples/adjectives-ces.pl`) the three jobs return a
recogniser of the degree with 883 weights and a converter of the genus with
528, each after two epochs, and a converter of the degree with 8,142 that has
every exception. Configured by hand, before there were jobs, the recogniser
and the degree converter had 4,371 and 29,459.

