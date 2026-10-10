# Composing

A chain is models put together into a model. This page shows the ways parts
can work together. The models here are tiny and learn invented rules, so
that the page runs in well under a minute.

```perl
use v5.36;
use utf8;
use open qw(:std :encoding(UTF-8));
use Peta::NN::Chain qw(chain pooled chosen);
use Peta::NN::Data;
use Peta::NN::Model;

# Invented words of two syllables, and what a teacher knows about each.
my @words = map { my $a = $_; map { my $b = $_; map { my $c = $_; map { "$a$b$c$_" } qw(ak el in os a o) } qw(b d m r st) } qw(a e i o u) } qw(b d g m p r st tr);
sub long_form ($word) { return $word =~ /[aeiou]\z/ ? $word . substr($word, -1) : $word . 'e' }      # the vowel doubled, or an e added
my $data = Peta::NN::Data->new(records => [ map { {
    word    => $_,
    ends    => /[aeiou]\z/ ? 'open' : 'closed',
    long    => long_form($_),
    doubled => $_ . substr($_, -1),
    plus    => $_ . 'e',
    which   => /[aeiou]\z/ ? 'a' : 'o',
} } @words ])->hold_out(0.2);

# What is marked, of a word or its long form: marked "a" or marked "o".
my $marks = Peta::NN::Data->new(records => [ map { my $word = $_; map { { word => $word, which => $_, marked => "$word-$_" } } qw(a o) } @words, map { long_form($_) } @words ])
    ->hold_out(0.2);

my %SMALL = (layers => [ [ embed => 6 ], [ dense => 24 ], 'relu' ]);
printf "%d words, for example %s\n", scalar @words, join ', ', @words[ 7, 400, 801 ];
```

## In series

```perl
my $long = Peta::NN::Model->new(kind => 'edit', from => 'word', to => 'long', reads => { end => 2 }, %SMALL)->train($data);
my $mark = Peta::NN::Model->new(kind => 'edit', from => 'word', to => 'marked', given => ['which'], reads => { end => 1 }, %SMALL)->train($marks);

my $both = chain(long => $long, mark => $mark);
print join(', ', $both->parts), ' / takes: ', join(', ', $both->given), "\n";
print scalar $both->predict('stabak', which => 'o'), "\n";
```

```text
long, mark / takes: which
stabake-o
```

Parts are named and in order. A part that rewrites hands its answer on as
the string the next part reads. What the parts are given, the chain takes,
by the same names; two parts given the same name share one argument.

## A chain is a model

```perl
my $plus   = Peta::NN::Model->new(kind => 'edit', from => 'word', to => 'plus', reads => { end => 1 }, %SMALL)->train($data);
my $longer = chain(plus => $plus, rest => $both);
print join(', ', $longer->parts), "\n";
print scalar $longer->predict('stabak', which => 'a'), "\n";
```

```text
plus, long, mark
stabakee-a
```

A chain put into a chain gives its parts to it. Nothing is trained again.

## A part that classifies

```perl
my $ends = Peta::NN::Model->new(kind => 'class', from => 'word', to => 'ends', reads => { end => 1 }, %SMALL)->train($data);

my $looked = chain(ends => $ends, long => $long);
my ($record) = @{ $looked->run(['stabo']) };
print "$record->{text}, which ends $record->{answers}{ends}\n";
```

```text
staboo, which ends open
```

A class model does not rewrite. Its answer is kept under the part's name
and the string passes on unchanged. `run` returns a record per string: the
`text` as the parts have rewritten it, the `confidence`, and the `answers`
of the parts that classify.

## An answer as what a later part is given

If a part is called what a later model is `given`, its answer is the value,
and the chain needs no argument for it:

```perl
my $pick = Peta::NN::Model->new(kind => 'class', from => 'word', to => 'which', reads => { end => 1 }, %SMALL)->train($data);

my $told = chain(which => $pick, mark => $mark);
print 'takes: ', (join(', ', $told->given) || 'nothing'), "\n";
print join(' ', $told->predict_all([qw(stabak stabo)])), "\n";
```

```text
takes: nothing
stabak-o stabo-a
```

## One model chooses which other model runs

```perl
my $double = Peta::NN::Model->new(kind => 'edit', from => 'word', to => 'doubled', reads => { end => 1 }, %SMALL)->train($data);

my $routed = chain(
    ends   => $ends,
    change => chosen(ends => { open => $double, '*' => $plus }),
);
print join(', ', $routed->models), "\n";
print join(' ', $routed->predict_all([qw(stabak stabo)])), "\n";
```

```text
ends, change-other, change-open
stabake staboo
```

`chosen(part => { answer => model })` runs, for each string, the model that
goes with what the earlier part answered; `'*'` stands for every answer not
listed. The models to choose from must be given the same things. This is
how `examples/wordclass.pl` has the language of a text choose the model that
tags its words.

## A whole text at once

```perl
my $text_wide = chain(ends => pooled($ends), long => $long);
my $texts = $text_wide->run_texts([ [qw(stabo bima trada stabak)], [qw(badak dumel stabak)] ]);
print join(' ', map { "$_->{text}/$_->{answers}{ends}" } @$_), "\n" for @$texts;
```

```text
staboo/open bimaa/open tradaa/open stabake/open
badake/closed dumele/closed stabake/closed
```

`pooled` makes a classifying model judge a text as a whole: every string of
the text is evidence, and all get the one answer the evidence points to.
`run_texts` takes texts as lists of strings. A single ambiguous word settles
nothing; ten words usually do.

## Measuring a chain, training its models

```perl
my $results = Peta::NN::Data->new(records => [ map { { word => $_, which => 'a', result => long_form($_) . '-a' } } @words ])->hold_out(0.3);
my $score   = $both->score($results, from => 'word', to => 'result');
printf "%.0f%% of unseen words, from word to result\n", 100 * $score->{unseen};
```

```text
100% of unseen words, from word to result
```

`score` runs the chain from one field to another. The models of a chain can
also be declared untrained and trained by the chain, side by side:
`chain(a => $model_a, b => $model_b)->train($data)`. See
`examples/nouns-deu.pl`.

Saving and loading are in [Shipping](shipping.md); running fused in
[Fusing](fusing.md). The methods are in the
[reference](../reference/Peta-NN-Chain.md).
