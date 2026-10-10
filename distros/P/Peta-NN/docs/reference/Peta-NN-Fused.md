# Peta::NN::Fused

micro models fused into one, as they are, the seams inside

## Synopsis

```perl
use Peta::NN::Fused;

# Apfel -> Äpfel -> Äpfeln, in one model. The steps are a pipeline's.
my $decline = Peta::NN::Fused->new(
    models => { map { $_ => "deu-noun/$_.model" } qw(umlaut ending case) },
    steps  => [
        { model => 'umlaut', params => [ \0 ] },
        { model => 'ending', params => [ \0 ] },
        { model => 'case',   params => [ \1 ] },
    ],
);
print scalar $decline->predict('apfel', 'masculine', 'dative');     # äpfeln

$decline->save('deu-noun-decline.fused');
my $on_the_card = Peta::NN::Fused->load('deu-noun-decline.fused', engine => 'gpu');
my @plurals     = $on_the_card->predict_all(\@nouns, 'neuter', 'nominative');

# a better part, the others untouched
my $improved = $decline->replace(ending => 'deu-noun/ending-2.model');

# One model names the language of a text, and that chooses the model
# that says what each of its words is.
my $tagger = Peta::NN::Fused->new(
    models => { language => 'language.model', map { $_ => "wordclass-$_.model" } qw(ces deu eng) },
    steps  => [
        { name => 'language', model => 'language', classify => 1, pool => 1 },
        { name => 'class', model => { language => { map { $_ => $_ } qw(ces deu eng) } }, classify => 1 },
    ],
);
for my $text (@{ $tagger->run_texts([ \@words_of_one_text, \@words_of_another ]) }) {
    printf "%s %s %s\n", @{ $_->{answers} }{qw(language class)}, $_->{text} for @$text;
}
```

## Description

Three ways to put micro models together:

**in a pipeline**

`N1 -> [Perl: the answer becomes the input] -> N2`. [Peta::NN::Pipeline](Peta-NN-Pipeline.md).

**fused**

`N3 = N1 -> N2`: both networks as they are, in one model, the seam
between them inside it. This module. No training; the fused model has the
weights of its parts and answers exactly what the pipeline answers.

**fused, consolidated**

`N4`: one model trained on what the chain does. Smaller and faster, and a
different function.

A fused model takes the steps a pipeline takes, written the same way. What a
pipeline does with a step's outputs is in here an operation without weights:
*route* takes an edit model's best label and carries its edit out on the
characters kept per string, which the next part then reads; *class* keeps a
class model's best label as the step's answer; *pool* does that for a whole
text, whose strings then all have the one answer. An answer can choose which
of several models a later step runs for a string, and can be a later model's
parameter. Where a step has several models to choose from, all of them are
computed, side by side, and each takes effect only on its own strings.

What is kept per string is its last `reach` and its first `front`
characters. A string of any length goes in as those and its length, and
comes out as one edit and its answers.

The parts stay separate, in the object and in its file. `replace` swaps one
for a better one; the seams are derived again from the labels.

### What fuses

Class models, and edit models that rewrite the end of a string
(`side => 'right'`). Edit models that rewrite the front or both ends,
and rewrite models, do not.

Where a pipeline would stop in the middle of a call, a fused model refuses
when it is built: an answer a routing table has no model for, or an answer
that is not a value of the parameter it is to be.

### Engines

`cpu` computes each part as [Peta::NN::Inference](Peta-NN-Inference.md) does, so the answers and
confidences are those of the pipeline to the last bit. `gpu` keeps a whole
batch on the graphics card from the first part to the last; it computes in
32-bit floats, so a confidence agrees to about six digits, and a decision
between two labels that close can fall the other way. It needs a pperl with
WebGPU and is the engine when `engine => 'gpu'` is given or
`PETA_NN_ENGINE=gpu` is set.

## Methods

### new

`Peta::NN::Fused->new(models => { name => model }, steps => [...])`,
optionally with `engine` and `meta`. A model is a model file's path, model
data, or an object that has it. The steps are those of
[Peta::NN::Pipeline, new](Peta-NN-Pipeline.md).

### load

`Peta::NN::Fused->load($file, engine => ...)`: a fused model from its
file.

### save

`save($file)`: writes the parts, each as it is, and the steps.

### replace

`replace(name => model, ...)`: a new fused model with those parts
replaced.

### predict

`predict($string, @arguments)`: the answer; in list context also its
confidence, the product of the parts'.

### predict_all

`predict_all(\@strings, @arguments)`: the answers, in order.

### answers

`answers(\@strings, @arguments)`: `[answer, confidence]` per string.

### run

`run(\@strings, @arguments)`: one record per string,
`{ text, confidence, answers }`, the answers being those of the steps
that classify, under the steps' names.

### run_texts

`run_texts(\@texts, @arguments)`: the same for texts, each a list of
strings; returns the records per text. A pooling step answers once per text.

### parts

The names of the parts, in the order the steps first use them.

### part

`part($name)`: that part, as a [Peta::NN::Inference](Peta-NN-Inference.md) model.

### names

The names of the steps that classify, in order.

### n_params

How many weights the fused model has: those of its parts.

### reach

How many characters of a string's end the fused model reads.

### front

How many characters of a string's front the fused model reads.

### arguments

How many arguments a call takes after the string.

### engine

`cpu` or `gpu`.

### info

What there is to know about the fused model, as a table.

---

From the POD of `lib/Peta/NN/Fused.pm`; change it there.
