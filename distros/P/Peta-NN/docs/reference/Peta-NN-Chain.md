# Peta::NN::Chain

models put together into a model

## Synopsis

```perl
use Peta::NN::Chain qw(chain pooled chosen);

# In series: apfel -> äpfel -> äpfeln
my $plural = chain(umlaut => $umlaut, ending => $ending);
print scalar $plural->predict('apfel', gender => 'masculine');          # äpfel

my $dative = chain(plural => $plural, case => $case);                   # a chain in a chain
print scalar $dative->predict('apfel', gender => 'masculine', case => 'dative');

$dative->save('deu-noun-dative.chain');
my $again = Peta::NN::Chain->load('deu-noun-dative.chain')->on('gpu');  # fused, on the card
my @forms = $again->predict_all(\@nouns, gender => 'neuter', case => 'dative');

# One model names the language of a text, and that chooses the model
# that says what each word is.
my $tagger = chain(
    language => pooled($language),
    class    => chosen(language => { ces => $czech, deu => $german, eng => $english }),
);
for my $word (@{ $tagger->run_texts([ \@words ])->[0] }) {
    print "$word->{text}: $word->{answers}{class} ($word->{answers}{language})\n";
}
```

## Description

A chain is a list of named parts, in order. A part is a model, a model
file, or another chain, whose parts become parts of this one. What a part
does follows from what it is: a model that rewrites hands its answer on as
the string the next part reads; a model that classifies has its answer kept
under the part's name, and the string passes on. `pooled` makes a
classifying model judge a whole text at once, and `chosen` names several
models of which an earlier part's answer chooses one per string.

Parameters go by name. If a part's model is given `gender` and an earlier
part of the chain is called `gender`, that part's answer is the value;
otherwise `gender` is an argument of the chain. Two parts that are given
the same name are given the same value. `given` lists a chain's arguments.

A chain is a model like any other: it is asked with `predict`, saved as one
file, loaded, and put into further chains. It answers through
[Peta::NN::Pipeline](Peta-NN-Pipeline.md), or, after `on('gpu')` or `on('cpu')`,
through the same parts fused ([Peta::NN::Fused](Peta-NN-Fused.md)), which is the same
function; not every model fuses, and `on` says why if these do not.

## Functions

Exported on request.

### chain

`chain(name => part, ...)`: a chain; the same as
`Peta::NN::Chain->new`.

### train_together

`train_together({ name => $model, ... }, $data, %options)`: trains
models that have nothing to do with each other side by side, as a chain's
`train` does. The models are trained in place; chains they are parts of can
answer afterwards.

### pooled

`pooled($model)`: a classifying model that answers once for a whole text
(`run_texts`).

### fixed

`fixed($model, name => value, ...)`: the model with some of what it is
given settled; the chain does not ask for those.

### chosen

`chosen($part => { answer => $model, ... })`: one of these models for
each string, chosen by what the earlier part called `$part` answered;
`'*'` stands for every answer not listed.

## Methods

### new

`Peta::NN::Chain->new(name => part, ...)`. A part is a
[Peta::NN::Model](Peta-NN-Model.md) (trained, or to be trained by the chain's `train`), a
[Peta::NN::Inference](Peta-NN-Inference.md), a model file's path, what `pooled` or `chosen`
give, or a chain.

### load

`Peta::NN::Chain->load($file)`: a chain from its file. A single model's
file loads as a chain of that one part.

### save

`save($file, name => ..., description => ...)`: writes the chain to one
file. A model that came from a file goes in as it is; one that was trained
here with 32-bit weights, or, with `small => $data`, with 8-bit weights
if it then still answers every record of that data as before.

### stored

With how many bits each model went into the file at the last `save`.

### train

`train($data, %options)`: trains the models of the chain that are not
trained yet on a [Peta::NN::Data](Peta-NN-Data.md), each as [Peta::NN::Model, train](Peta-NN-Model.md) does,
side by side. Where the models learn from different data, `$data` is a table
`{ model => data, '*' => data for the others }`. Until then such a chain has parts and arguments but cannot
answer. Returns the chain.

### report

What the jobs that trained the chain's models have to say, model by model.

### score

`score($data, from => $field, to => $field)`: the share of records for
which the chain turns the one field into the other, of the records that are
held out (`unseen`), and of each mark of the data, of its records that are
not held out; as a table. The chain's
arguments are the records' fields of the same names. With
`answer => $part` it is that classifying part's answer that is compared.

### predict

`predict($string, name => value, ...)`: the string as the parts have
rewritten it; in list context also its confidence, the product of the
parts'.

### predict_all

`predict_all(\@strings, name => value, ...)`: the answers, in order.

### run

`run(\@strings, name => value, ...)`: one record per string,
`{ text, confidence, answers }`, the answers being those of the parts
that classify, under the parts' names.

### run_texts

`run_texts(\@texts, name => value, ...)`: the same for texts, each a
list of strings; returns the records per text. A pooled part answers once
per text.

### on

`on($where)`: where the chain answers from now on: `'pipeline'` (as it
starts), or fused on `'cpu'` or `'gpu'`. Returns the chain.

### given

The names of the chain's arguments, in the order its parts first need them.

### parts

The names of the parts, in order.

### answers

The names of the parts that classify.

### models

The names of the chain's models, in the order of the parts. A part that
chooses has one per answer, called `part-answer`.

### model

`model($name)`: that model, as a [Peta::NN::Inference](Peta-NN-Inference.md).

### n_params

How many weights the chain has: those of its models.

### pipeline

The [Peta::NN::Pipeline](Peta-NN-Pipeline.md) that runs the chain.

### fused

`fused($engine)`: the same parts as a [Peta::NN::Fused](Peta-NN-Fused.md), on `'cpu'` (the
default) or `'gpu'`.

### info

What there is to know about the chain, as a table.

---

From the POD of `lib/Peta/NN/Chain.pm`; change it there.
