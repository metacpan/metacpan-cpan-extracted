# Fusing

A chain runs in one of two ways, and they are the same function.

| | What happens between two parts | Where |
|---|---|---|
| as a pipeline | Perl takes the first model's answer, builds the new string, and hands it to the second | the CPU |
| fused | the same models, as they are, in one model, with the hand-over inside it | the CPU, or the whole batch on a graphics card |

There is a third thing, which is not the same function: a *fused,
consolidated* model is one model trained on what the chain does. It is
smaller and has to be trained and checked again. This page is about the
second.

## Running a chain fused

```perl
use v5.36;
use utf8;
use open qw(:std :encoding(UTF-8));
use Peta::NN::Chain qw(chain);
use Peta::NN::Data;
use Peta::NN::Model;

my $nouns = Peta::NN::Data->read('examples/out/deu-noun/nouns.tsv', fields => [qw(singular gender plural listed)])->sample(4000)->hold_out(0.2);
my $forms = Peta::NN::Data->new(records => [ map { my $noun = $_; map { {
    plural => $noun->{plural}, case => $_, form => $_ eq 'dative' && $noun->{plural} !~ /[ns]\z/ ? "$noun->{plural}n" : $noun->{plural},
} } qw(nominative dative) } $nouns->records ])->hold_out(0.2, by => 'plural');

my $dative = chain(
    plural => Peta::NN::Model->new(kind => 'edit', from => 'singular', to => 'plural', given => ['gender'], reads => { end => 6 }, train => { epochs => 5 }),
    case   => Peta::NN::Model->new(kind => 'edit', from => 'plural', to => 'form', given => ['case'], reads => { end => 3 }, train => { epochs => 5 }),
)->train({ plural => $nouns, case => $forms });

my @words = map { $_->{singular} } $nouns->where(sub ($noun) { $noun->{gender} eq 'feminine' })->records;
my @by_pipeline = $dative->predict_all(\@words, gender => 'feminine', case => 'dative');
my @fused       = $dative->on('cpu')->predict_all(\@words, gender => 'feminine', case => 'dative');
printf "%d words, %d answered differently\n", scalar @words, scalar grep { $fused[$_] ne $by_pipeline[$_] } 0 .. $#words;
```

```text
1820 words, 0 answered differently
```

`on('cpu')` and `on('gpu')` make the chain answer fused from then on;
`on('pipeline')` goes back. Nothing is trained and no weight changes. On the
CPU the fused chain agrees with the pipeline to the last bit, confidences
included. On the card it computes in 32-bit floats: confidences agree to
about six digits, and a decision between two labels that are that close can
fall the other way. On the 45,218 German nouns none did.

## What is inside

Between two edit models a pipeline takes the first one's best label, carries
that edit out on the string, cuts the next model's window out of the new
string and looks its characters up. Every label is one fixed edit, so what
the next model will read is known per label in advance. Fused, that is two
operations without weights: *select* the best label, and *route*: carry its
edit out on the characters kept for each string.

What is kept per string is its last few characters and its first few: as
far as any part reads, after the parts before it have cut as deep as they
can. A string of any length goes in as those and its length, passes all
parts, and comes out as one edit and the answers of the parts that classify.

```mermaid
flowchart LR
    s([the last 9 characters<br>and the length]) --> m1[plural] --> r1{{select, route}} --> m2[case] --> r2{{select, route}} --> e([one edit])
```

A part that classifies keeps its answer; a part that is `chosen` computes
all its models for the whole batch, and each takes effect only on the
strings that are its own; a `pooled` part gathers the evidence of a text on
the card. The parts stay parts: the fused chain has exactly the weights of
its models, and a model can be replaced without touching the others.

## When it pays

On the CPU, hardly: fusing saves a few percent, because the networks are the
cost there, not the hand-over.

On a graphics card a batch costs about a millisecond whatever is in it. One
word alone is therefore about ten times slower than on the CPU, and from a
few hundred words on the fused chain is about ten times faster than the
pipeline. The measured numbers are with
[the fused models](../blocks/fused.md).

```perl
if (eval { $dative->on('gpu') }) {
    my @on_card = $dative->predict_all(\@words, gender => 'feminine', case => 'dative');
    printf "on the card: %d of %d answered differently\n", scalar(grep { $on_card[$_] ne $by_pipeline[$_] } 0 .. $#words), scalar @words;
}
else { print "no graphics card here: $@" }
```

```text
on the card: 0 of 1820 answered differently
```

## What does not fuse

Class models fuse, and edit models that rewrite the end of a string. Edit
models that rewrite the front or both ends, and rewrite models, do not yet.
A chain with such a part runs as a pipeline, saves and loads like any other,
and says why when asked to run fused.
