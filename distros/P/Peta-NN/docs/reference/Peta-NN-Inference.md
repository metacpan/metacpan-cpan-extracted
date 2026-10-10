# Peta::NN::Inference

load a trained model and get answers from it

## Synopsis

```perl
use Peta::NN::Inference;

my $degree = Peta::NN::Inference->load('ces-adjective-degree.model');
print scalar $degree->predict('chytřejší');                 # comparative

my $convert = Peta::NN::Inference->load('ces-adjective-convert.model');
print scalar $convert->predict('chytrý', 'superlative');    # nejchytřejší
my @all = $convert->predict_all(\@adjectives, 'comparative');

my ($answer, $confidence) = $degree->predict('nejistý');

# every answer the model considers, most probable first
printf "%-12s %.3f\n", @$_ for @{ $degree->distribution('lepší') };

# one verdict for several strings together
my $language = $identify->pooled([ split ' ', $sentence ]);
```

## Description

This is the inference leg of Peta::NN. A model file is written by the
training leg (`Peta::NN::Model->export`); reading and using it needs
only this module and [Peta::NN::Codec](Peta-NN-Codec.md).

### Parameters

A model may take parameters after the string: as many as it was trained
with, each one of the values it was trained with. A model whose parameters
have names takes them by name, `predict($noun, gender => 'neuter')`;
`given` lists the names. (`answers`, which pipelines and fused models
call, takes the values in their order.) They are opaque: the model
has learned what to do for `'dative'`, not what a dative is. `parameters`
lists the known values per position. The wrong number of parameters, or a
value the model never saw, is an error; nonsense that is well-formed is
answered like anything else.

### Certainty

`predict` gives the best answer and, in list context, its probability.
`distribution` gives every answer with its probability. `pooled` combines
the distributions of several strings into one, for class models.

### Engine

`engine` says what the arithmetic runs on: `pdl` when this perl has PDL,
`plain` otherwise or when `PETA_NN_ENGINE=plain` is set.

### Files

A model file is read as plain data (nothing in it is turned into an object,
so reading runs no code from the file) and checked in full before use: the
format marker, every field's type, that each layer fits its neighbours and
the labels, and that every weight is a finite number. A file that fails is
refused with the reason. By convention model files end in `.model`.

Weights are stored with 32 bits each, or 8 (signed bytes and a scale per
array), as the exporter chose; in memory they are ordinary numbers either
way. `info` returns what the file says of itself and what follows from its
contents.

## Methods

### load

`Peta::NN::Inference->load($file)`: the model of a model file. The file
is checked in full first.

### new

`Peta::NN::Inference->new($data)`: a model from model data, which is
checked first.

### predict

`predict($string, @parameters)`: the answer; in list context also its
confidence.

### predict_all

`predict_all(\@strings, @parameters)`: the answers, in order.

### answers

`answers(\@strings, @parameters)`: `[answer, confidence]` for each string.

### probabilities

`probabilities(\@windows)`: for each window of token indices the probability
of every label, in the order of `labels`.

### pool

`pool(\@probabilities)`: what `pooled` answers, from the probabilities of
the strings themselves.

### decisions

`decisions(\@windows)`: `[index of the best label, its probability]` for
each window of token indices. For callers that build the windows themselves,
as [Peta::NN::Fused](Peta-NN-Fused.md) does.

### distribution

`distribution($string, @parameters)`: every answer the model considers, as
a list of `[answer, probability]`, most probable first. For a rewrite
model, one such list per character.

### pooled

`pooled(\@strings, @parameters)`: one distribution for several strings
together, for a class model.

### data

The model data the object was made from, with the weights as they were
stored.

### kind

`class`, `edit` or `rewrite`.

### labels

The answers the model can give.

### given

The names of the parameters, in their order. Empty for a model without
parameters, and for one whose parameters were given no names.

### values_from

`values_from(@arguments)`: what a caller gave after the string, as the
parameters' values in their order: taken by name where the parameters have
names, as they come where they have none.

### pooled_for

`pooled_for(\@strings, @values)`: `pooled` with the parameters' values in
their order.

### parameters

The values the model knows for each of its parameters: one sorted list per
position.

### n_params

The number of weights.

### info

What there is to know about the model, for a human: what the file says of
itself and what follows from its contents.

## Functions

### engine

`pdl` or `plain`: what the arithmetic runs on.

### end_window

`end_window($config, \@chars, @tokens)`: the window of the whole-string
kinds. Used by the training leg to read a string as the inference leg does.

### char_window

`char_window($config, \@chars, $position, @tokens)`: the window around one
character, for rewrite.

### param_tokens

`param_tokens($params, @values)`: the tokens of a call's parameters.

### pack_weights

`pack_weights(\@weights, $bits)`: a weight array as a model file stores it.

### read_file

`read_file($file, $format)`: a Storable file as plain data, refused unless
it carries the format marker.

---

From the POD of `lib/Peta/NN/Inference.pm`; change it there.
