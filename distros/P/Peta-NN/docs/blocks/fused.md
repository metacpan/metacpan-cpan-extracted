# Fused models

Three ways to put micro models together, and three words for them:

| | | weights | answers |
|---|---|---|---|
| in a pipeline | `N1 -> [Perl: the answer becomes the input] -> N2` | those of the parts | |
| fused | `N3 = N1 -> N2`, both as they are, the seam inside the model | those of the parts | exactly the pipeline's |
| fused, consolidated | `N4`, one model trained on what the chain does | fewer | nearly the pipeline's |

`Peta::NN::Fused` makes the second. Nothing is trained and no weight
changes.

A chain runs fused after `$chain->on('cpu')` or `on('gpu')`; that is the way
to use this, and [Fusing](../guides/fusing.md) is the guide. This page is the
building block underneath, used by hand, and what was measured with it. A
fused model takes the steps a [pipeline](pipelines.md) takes, with
parameters by position; the model files named below are made up.

```perl
use Peta::NN::Fused;

my $decline = Peta::NN::Fused->new(
    models => { map { $_ => "$_.model" } qw(umlaut ending case) },
    steps  => [
        { model => 'umlaut', params => [ \0 ] },
        { model => 'ending', params => [ \0 ] },
        { model => 'case',   params => [ \1 ] },
    ],
);
print scalar $decline->predict('apfel', 'masculine', 'dative');     # äpfeln

$decline->save('decline.fused');                                    # one file, the parts in it as they are
my $on_the_card = Peta::NN::Fused->load('decline.fused', engine => 'gpu');
my $improved    = $decline->replace(ending => 'ending-2.model');    # one part exchanged, the others untouched
```

`$pipeline->fuse` gives the fused model of a pipeline.

**The seam.** Between two edit models a pipeline takes the first one's best
label, carries that edit out on the string, cuts the next model's window out
of the new string and looks its tokens up. Every label is one fixed edit, so
what the next model will read is known per label in advance. Inside a fused
model that is two operations without weights: *select* takes the best label
of a part's outputs, *route* carries that label's edit out on the characters
kept per string. What is kept per string is its last few characters: as far
back as any part can come to read once the parts before it have cut as deep
as they can (13 for the German chain: `ending` reads 7, and `umlaut` can cut
6). A string of any length goes in as that tail and its length, passes all
parts, and comes out as one edit.

**The parts stay parts.** The fused model and its file hold each model as it
was, under its name, 8-bit weights as 8-bit weights. A part can be trained
on, measured and replaced alone; the seams are derived from the labels when
the fused model is built, which costs nothing.

**Two engines.** `cpu` computes each part as the inference leg does and
agrees with the pipeline to the last bit. `gpu` puts a batch on the graphics
card once and takes it off once; every part and every seam between runs
there, in 32-bit floats.

Measured with `bench/fused.pl` on the German noun models of
`examples/nouns-deu.pl`, taken out of the chain file it saves (P53: Xeon
E-2276M, Quadro RTX 5000, pperl with WebGPU; 2026-10-09), all 45,218 nouns,
each with its gender:

| | singular to plural | and on to a case |
|---|---|---|
| parts | `umlaut -> ending` | `umlaut -> ending -> case` |
| weights | 18,761 + 10,002 = 28,763 | + 656 = 29,419 |
| fused on cpu against the pipeline | 0 answers differ, confidences identical | the same |
| fused on gpu against the pipeline | 0 answers differ, confidences within 3e-06 | the same |

Milliseconds per string, by how many strings go through at once:
(one run; on this laptop, with its CPU governor on `powersave` and other
programs running, the same code measured minutes apart differs by up to a
third, and one run of an afternoon came out 1.4 times slower throughout.
The ratios between the columns hold; a figure is good to its first digit.)

| at once | pipeline | fused, cpu | fused, gpu | | pipeline | fused, cpu | fused, gpu |
|---:|---:|---:|---:|---|---:|---:|---:|
| | *to plural* | | | | *to a case* | | |
| 1 | 0.151 | 0.140 | 1.92 | | 0.197 | 0.176 | 1.52 |
| 16 | 0.097 | 0.086 | 0.080 | | 0.124 | 0.111 | 0.061 |
| 256 | 0.114 | 0.110 | 0.010 | | 0.199 | 0.185 | 0.011 |
| 4,096 | 0.133 | 0.129 | 0.011 | | 0.219 | 0.199 | 0.016 |
| 32,768 | 0.113 | 0.103 | 0.012 | | 0.170 | 0.136 | 0.016 |

What that says:

- On the CPU fusing buys little, about 10%: the seam was never the
  expensive part there, the networks are.
- On the card a batch costs about a millisecond whatever is in it, so one
  string alone is ten times slower than on the CPU, and from a few hundred
  strings on the fused model is ten times faster than the pipeline. A third
  model in the chain adds a third to a half on the card.
- Of the 0.010 to 0.016 ms per string on the card, most is Perl: turning
  strings into numbers before and edits into strings after. The card's own
  share, measured apart at 32,768 strings, is under 0.002 ms per string for
  the two models and their seam.
- The fused, consolidated model of the same chain (one model, 21,865
  weights, trained for it in a trial) was right on 98.1% of unseen nouns
  where the pipeline is right on 98.4%. Consolidating buys size and costs
  training time and exactness; fusing costs neither.
  (That trial was of 2026-10-07, on the models of that day.)

**Not only in series.** A step that classifies keeps its answer, and the
answer chooses which of several models a later step runs for a string, or is
a later model's parameter. In a fused model all the models a step can choose
from are computed for the whole batch, side by side, and each takes effect
only on the strings that are its own; the payload passes through. A step
with `pool` classifies a whole text at once (`run_texts`): every word is
evidence, and all words of the text get the one answer. That gives the
shape *one model names the language of a text, and that chooses the model
that says what each word is*, which `examples/wordclass.pl` builds as a
chain (`pooled`, `chosen`). By hand:

```perl
my $tagger = Peta::NN::Fused->new(
    models => { language => 'language.model', map { $_ => "wordclass-$_.model" } qw(ces deu eng) },
    steps  => [
        { name => 'language', model => 'language', classify => 1, pool => 1 },
        { name => 'class', model => { language => { map { $_ => $_ } qw(ces deu eng) } }, classify => 1 },
    ],
);
my $texts = $tagger->run_texts([ \@words_of_one_text, \@words_of_another ]);    # per word: { text, confidence, answers }
```

The tests hold fused models of all these shapes against their pipelines, on
strings no model was trained on: on the CPU every answer and confidence is
the same to the last bit, on the card every answer.

On the chain of `examples/wordclass.pl` (four models, 454,593 weights, the
language of a text choosing among three class models) the fused chain
answers every one of 9,660 held-out words as the pipeline does, on the CPU
and on the card, and on the card about ten times faster: 0.04 ms per word
against 0.4. All three class models are computed for every word there, and
each takes effect on the texts of its language. What that example is and
what it reached is in [the examples](../examples.md).

**What fuses:** class models, and edit models that rewrite the end of a
string. Not yet: edit models that rewrite the front or both ends, and
rewrite models. Where a pipeline would stop in the middle of a call (an
answer the routing table has no model for, an answer that is no value of the
parameter it is to be), a fused model refuses when it is built.

