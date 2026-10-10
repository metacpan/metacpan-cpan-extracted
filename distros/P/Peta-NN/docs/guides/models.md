# Models

A model answers one narrow question about a string. This page is about
declaring one, training it, and asking it.

## The three kinds

| Kind | What it answers | For example |
|---|---|---|
| `edit` | how to rewrite an end of the string: cut so many characters, add these | singular to plural, a name to its vocative |
| `class` | one of a fixed set of labels; the string stays as it is | the language of a word, its word classes |
| `rewrite` | for every character, what it becomes | restoring diacritics |

An edit model can only give an edit it has seen in training; a class model
only a label it has seen. That is what keeps them small: thousands of words
share a handful of answers.

## Declaring a model

```perl
use v5.36;
use utf8;
use open qw(:std :encoding(UTF-8));
use Peta::NN::Data;
use Peta::NN::Model;

my $model = Peta::NN::Model->new(
    kind  => 'edit',
    from  => 'singular',
    to    => 'plural',
    given => ['gender'],
    reads => { end => 6 },
);
```

| | |
|---|---|
| `from`, `to` | the field of the data it reads, and the one it answers |
| `given` | fields it is told beside the string; they become its named parameters |
| `reads` | how much of the string it looks at: `{ end => N }`, `{ front => N }`, `{ both => N }` (N characters of each end), or for a rewrite model `{ around => N }` |
| `goal` | what it has to reach; see below |
| `train`, `search`, `budget` | how training goes about it, if the defaults do not suit |

What a model is `given` it does not understand. `masculine` is a value that
goes with different answers than `feminine`; nothing more.

`reads` is the one thing to think about. A model that reads the last six
characters cannot tell apart two words that end alike, whatever it is
trained on; training reports such pairs. Reading more costs little.

## Training without a goal

```perl
my $nouns = Peta::NN::Data->read('examples/out/deu-noun/nouns.tsv', fields => [qw(singular gender plural listed)])
    ->sample(4000)
    ->hold_out(0.2);

$model->train($nouns, train => { epochs => 5 });
printf "%.1f%% of the nouns it was not shown\n", 100 * $model->score($nouns)->{unseen};
```

```text
88.5% of the nouns it was not shown
```

A model without a goal is fitted once: at most so many passes over the data,
stopping early when the held-out records are no longer answered better.

## Training to a goal

```perl
my $aimed = Peta::NN::Model->new(
    kind => 'edit', from => 'singular', to => 'plural', given => ['gender'], reads => { end => 6 },
    goal => { unseen => 0.88 },
);
$aimed->train($nouns);
print $aimed->report;
```

```text
4 training pairs the model cannot tell from a pair with a different answer; a wider window would (rabenmutter → rabenmütter as kordelmutter → kordelmuttern, kordelmutter → kordelmuttern as rabenmutter → rabenmütter, wettbewerbsdruck → wettbewerbsdrucke as codeausdruck → codeausdrücke, ...)
#   stage                    width  params epochs on         ms  all           outcome
    required                                                     >= 88.0%    
1   train                       64   13772      5 gpu     0.096  89.00%        met
2   second seed: train          64   13772      9 gpu     0.086  88.17%        confirmed

the model meets the thresholds: depth 1, width 64, 13772 parameters, 0.096 ms per item. Confirmed on a second seed. 2 stages, 5 epochs, 7 s (done).
on the test part, measured once: all 90.5%
```

A goal names shares that have to be answered exactly: `unseen` for records
the model was not shown, and any mark of the data ([Data](data.md)) for the
records of that group. `goal => { unseen => 0.98, core => 1 }` reads: 98% of
what it has not seen, and every record of the core.

Training to a goal is done by a job ([Jobs](../blocks/jobs.md)). It trains,
looks at how far the model is from its goal, trains on more gently, puts
weight on the marks that are short, and widens the model when that does not
help; when the goal is met it trains a second model from another start to
confirm. If the goal cannot be met the report says how close it got, and the
model is the closest one. A goal that is out of reach costs time, so set
`unseen` from what a first run without a goal shows.

## Asking

```perl
print scalar $aimed->predict('zeitung', gender => 'feminine'), "\n";

my ($answer, $confidence) = $aimed->predict('auto', gender => 'neuter');
printf "%s (%.2f)\n", $answer, $confidence;

print join(' ', $aimed->predict_all([qw(frau blume katze)], gender => 'feminine')), "\n";
```

```text
zeitungen
autos (0.94)
frauen blumen katzen
```

Parameters are named. A value the model was never trained with is refused,
with the values it knows; a model does not judge its input otherwise, and
answers something for nonsense.

## Measuring

```perl
my $score = $aimed->score($nouns);
printf "%s: %.1f%%\n", $_, 100 * $score->{$_} for sort keys %$score;
```

```text
unseen: 90.3%
```

`score` gives the share of records answered exactly: of the held-out ones as
`unseen`, and of each mark. Print what is wrong before believing the number.

A trained model becomes useful to others as a chain, even alone:
[Composing](composing.md) and [Shipping](shipping.md). The methods are in the
[reference](../reference/Peta-NN-Model.md).
