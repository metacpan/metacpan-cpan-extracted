# Pipelines

The level under a chain. `chain(...)` ([Composing](../guides/composing.md))
works out a pipeline from its parts and their names and runs it; this page
is the pipeline itself, wired by hand, where a step's parameters are given
by position and each step says where its values come from.

Each model does one limited transformation. `Peta::NN::Pipeline` puts them in
series, where a step's answer is the next step's input, and routes, where a
classifying step's answer chooses the model of a later step. The models are
model files (`Peta::NN::Model->export`) or model objects; the names of the
files below are made up.

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
print scalar $decline->predict('Apfel', 'dative');

# Routed: a classifier names the word class, and that picks the model.
my $inflect = Peta::NN::Pipeline->new(
    models => { class => 'ces-wordclass.model', noun => 'ces-noun.model', adjective => 'ces-adjective.model' },
    steps  => [
        { name => 'class', model => 'class', classify => 1 },
        { model => { class => { noun => 'noun', adjective => 'adjective' } }, params => [ \0 ] },
    ],
);
```

A step's parameters are fixed text, `\N` for the call's Nth argument, or
`{ answer => 'step' }` for what an earlier, named step answered. A
classifying step with `pool` judges a whole text at once: `run_texts` takes
texts as lists of strings, and all strings of a text get the one answer they
point to together. `trace`
shows what every step did with a string. The confidence of a pipeline's
answer is the product of its steps': errors multiply along a chain, and so
does doubt. A pipeline is part of the inference leg and needs only the model
files; what a chain means is written in its steps, not in the models.

`$pipeline->fuse` gives the same steps as a [fused model](fused.md), and
`$chain->pipeline` the pipeline a chain runs.

