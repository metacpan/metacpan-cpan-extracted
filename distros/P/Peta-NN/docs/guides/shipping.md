# Shipping

What is saved, what is in the file, and what somebody needs who only uses it.

## One file

```perl
use v5.36;
use utf8;
use open qw(:std :encoding(UTF-8));
use Peta::NN::Chain qw(chain);
use Peta::NN::Data;
use Peta::NN::Model;

my $nouns  = Peta::NN::Data->read('examples/out/deu-noun/nouns.tsv', fields => [qw(singular gender plural listed)])->sample(4000)->hold_out(0.2);
my $plural = Peta::NN::Model->new(kind => 'edit', from => 'singular', to => 'plural', given => ['gender'], reads => { end => 6 }, train => { epochs => 5 })->train($nouns);

chain(plural => $plural)->save('plural.chain', name => 'German nouns: singular to plural', source => 'nouns.tsv, 4000 of its nouns');
printf "%d bytes\n", -s 'plural.chain';
```

```text
24441 bytes
```

What is trained is saved as a chain, even a single model. A chain's file
holds its models, each as it is, how they are put together, and what you say
about it (`name`, `description`, `source`, anything).

## Using it

```perl
my $model = Peta::NN::Chain->load('plural.chain');
print 'takes: ', join(', ', $model->given), "\n";
print scalar $model->predict('zeitung', gender => 'feminine'), "\n";
```

```text
takes: gender
zeitungen
```

That is all a program that uses a model needs: the file, and
`Peta::NN::Chain`. Nothing of the training side is loaded. A file is read as
plain data and checked in full before anything is computed from it: every
field of the right type, every layer of the size its neighbours need. A
malformed file is refused with the reason; it cannot make the library index
outside its weights. Nothing in a file is executed.

`peta-nn-info FILE` prints what a file is: its name, what it takes, its
parts, and for every model what it reads, how large it is and how its
weights are stored.

## Small files

A weight is stored with 32 bits, or with 8. Eight bits make a file a quarter
the size, and can change an answer here and there. So the library does not
guess: it is told what to judge by.

```perl
my $saved = chain(plural => $plural);
$saved->save('plural-small.chain', small => $nouns);
printf "stored with %d bits: %d bytes\n", $saved->stored->{plural}, -s 'plural-small.chain';
```

```text
stored with 32 bits: 24359 bytes
```

With `small => $data` each model that was trained here goes into the file
with 8-bit weights if, stored that way, it still answers every record of
that data as it does now; and with 32 bits if not, as happened here.
`stored` says what was done. A model that came from a file is saved as it came.

## What to say about a model

Whoever gets the file should be able to tell what it is for and how far to
trust it. Put into `save` at least a `name`, where the data came from, and
what was measured:

```perl
my $score = $plural->score($nouns);
chain(plural => $plural)->save('plural.chain',
    name     => 'German nouns: singular to plural',
    source   => 'the PetaMem lexica, 4000 nouns',
    measured => sprintf('%.1f%% of %d nouns not shown', 100 * $score->{unseen}, $nouns->held->count),
);
print Peta::NN::Chain->load('plural.chain')->info->{measured}, "\n";
```

```text
88.5% of 784 nouns not shown
```

## Files and versions

A file says which version wrote it and in which layout. A layout that this
version cannot read is refused by its number, with the advice to save it
again, rather than by some puzzling detail further in.

The older building blocks have files of their own, which still load: a
single model's file (`Peta::NN::Model->export`), which loads as a chain of
one part, and a fused model's file (`Peta::NN::Fused->save`).
