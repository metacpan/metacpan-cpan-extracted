# Peta::NN::Pipeline

models in series, and routed by a classifier

## Synopsis

```perl
use Peta::NN::Pipeline;

# In series: Apfel -> Äpfel -> Äpfeln. The case is the call's argument.
my $decline = Peta::NN::Pipeline->new(
    models => { number => 'deu-noun-number.model', case => 'deu-noun-case.model' },
    steps  => [
        { model => 'number', params => ['plural'] },
        { model => 'case',   params => [ \0 ] },
    ],
);
print scalar $decline->predict('Apfel', 'dative');          # Äpfeln

# Routed: a classifier names the word class, and that picks the model.
my $inflect = Peta::NN::Pipeline->new(
    models => { class => 'ces-wordclass.model', noun => 'ces-noun.model', adjective => 'ces-adjective.model' },
    steps  => [
        { name => 'class', model => 'class', classify => 1 },
        { model => { class => { noun => 'noun', adjective => 'adjective' } }, params => [ \0 ] },
    ],
);

my ($answer, $confidence) = $inflect->predict($word, 'genitive');
printf "%-10s %s -> %s (%.2f)\n", @$_[ 0, 2, 3, 4 ] for $inflect->trace($word, 'genitive');
```

## Description

A step's parameters are given as text (always that value), as `\N` (the
call's Nth argument, counting from 0), or as `{ answer => 'step' }`
(what an earlier, named step answered).

A step with `classify` only looks: its answer is kept under its name and
the string passes on unchanged. With `pool` as well it looks at a
whole text at once (`run_texts`) and gives all its strings one answer. A later step can use that answer as a
parameter, or to choose its model through a routing table; `'*'` in the
table stands for any answer not listed.

The confidence of a pipeline's answer is the product of its steps'. Errors
multiply along a chain, and so does doubt.

## Methods

### new

`Peta::NN::Pipeline->new(models => { name => model }, steps => [...])`.
A model is a model file's path or an object that answers. A step is a table
with `model` (a name, or a routing table `{ step => { answer => model } }`),
`params`, `name` and `classify`.

### predict

`predict($string, @arguments)`: the pipeline's answer; in list context also
its confidence.

### predict_all

`predict_all(\@strings, @arguments)`: the answers, in order.

### trace

`trace($string, @arguments)`: what each step did, as a list of
`[model name, parameters, input, output, confidence]`.

### run

`run(\@strings, @arguments)`: one record per string,
`{ text, confidence, answers, trace }`.

### run_texts

`run_texts(\@texts, @arguments)`: the same for texts, each a list of
strings (its words, say); returns the records per text. A step with `pool`
answers once per text: every string of the text is evidence, each gets the
one answer they point to together, and its confidence.

### arguments

How many arguments a call takes after the string.

### fuse

`fuse(%options)`: the same steps as one [Peta::NN::Fused](Peta-NN-Fused.md) model, which
answers what the pipeline answers without coming back to Perl between the
steps. Options are those of `Peta::NN::Fused->new`.

---

From the POD of `lib/Peta/NN/Pipeline.pm`; change it there.
